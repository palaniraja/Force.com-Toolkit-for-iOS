//
//  ZKSforceClient+Private.m
//  SVNTest
//
//  Created by Rick Fillion on 8/18/10.
//  Copyright 2010 Centrix.ca. All rights reserved.
//

#import "ZKSforceClient+Private.h"
#import "ZKParser.h"
#import "ZKQueryResult.h"
#import "ZKEnvelope.h"
#import "ZKPartnerEnvelope.h"
#import "ZKSaveResult.h"
#import "ZKLoginResult.h"
#import "ZKDescribeGlobalSObject.h"
#import "ZKDescribeSObject.h"

static const int MAX_SESSION_AGE = 25 * 60; // 25 minutes
static const int SAVE_BATCH_SIZE = 25;

@implementation ZKSforceClient (Private)

- (ZKQueryResult *)queryImpl:(NSString *)value operation:(NSString *)operation name:(NSString *)elemName 
{
	if(!sessionId) 
        return nil;
	[self checkSession];
	
	ZKEnvelope *env = [[ZKPartnerEnvelope alloc] initWithSessionHeader:sessionId clientId:clientId];
	[env startElement:operation];
	[env addElement:elemName elemValue:value];
	[env endElement:operation];
	[env endElement:@"s:Body"];
	
	ZKElement *qr = [self sendRequest:[env end]];
	
	ZKQueryResult *result = [[ZKQueryResult alloc] initFromXmlNode:[[qr childElements] objectAtIndex:0]];
	[env release];
	return [result autorelease];
}

/**
 TODO - Figure out how to make this work async
 **/
- (NSArray *)sobjectsImpl:(NSArray *)objects name:(NSString *)elemName {
	
	if(!sessionId) 
        return nil;
	[self checkSession];
	
	// if more than we can do in one go, break it up.
	if ([objects count] > SAVE_BATCH_SIZE) {
		NSMutableArray *allResults = [NSMutableArray arrayWithCapacity:[objects count]];
		NSRange rng = {0, MIN(SAVE_BATCH_SIZE, [objects count])};
		while (rng.location < [objects count]) {
			[allResults addObjectsFromArray:[self sobjectsImpl:[objects subarrayWithRange:rng] name:elemName]];
			rng.location += rng.length;
			rng.length = MIN(SAVE_BATCH_SIZE, [objects count] - rng.location);
		}
		return allResults;
	}
	ZKEnvelope *env = [[ZKPartnerEnvelope alloc] initWithSessionAndMruHeaders:sessionId mru:updateMru clientId:clientId];
	[env startElement:elemName];
	NSEnumerator *e = [objects objectEnumerator];
	ZKSObject *o;
	while (o = [e nextObject])
		[env addElement:@"sobject" elemValue:o];
	[env endElement:elemName];
	[env endElement:@"s:Body"];
	
	ZKElement *cr = [self sendRequest:[env end]];
	NSArray *resultsArr = [cr childElements:@"result"];
	NSMutableArray *results = [NSMutableArray arrayWithCapacity:[resultsArr count]];
	for (ZKElement *cr in resultsArr) {
		ZKSaveResult * sr = [[ZKSaveResult alloc] initWithXmlElement:cr];
		[results addObject:sr];
		[sr release];
	}
	[env release];
	return results;
}

- (void)checkSession 
{
	if ([sessionExpiresAt timeIntervalSinceNow] < 0)
		[self startNewSession];
}

- (ZKLoginResult *)startNewSession 
{
	[sessionExpiresAt release];
	sessionExpiresAt = [[NSDate dateWithTimeIntervalSinceNow:MAX_SESSION_AGE] retain];
	[sessionId release];
	[endpointUrl release];
	endpointUrl = [authEndpointUrl copy];
	
	ZKEnvelope *env = [[ZKPartnerEnvelope alloc] initWithSessionHeader:nil clientId:clientId];
	[env startElement:@"login"];
	[env addElement:@"username" elemValue:username];
	[env addElement:@"password" elemValue:password];
	[env endElement:@"login"];
	[env endElement:@"s:Body"];
	NSString *xml = [env end];
	[env release];
	
	ZKElement *body = [self sendRequest:xml];
	ZKLoginResult *lr = [self parseLogin:body withConnection:nil];
	return lr;
	
}

- (void)startNewSessionAsync:(id)delegate 
{
	[sessionExpiresAt release];
	sessionExpiresAt = [[NSDate dateWithTimeIntervalSinceNow:MAX_SESSION_AGE] retain];
	[sessionId release];
	[endpointUrl release];
	endpointUrl = [authEndpointUrl copy];
	
	ZKEnvelope *env = [[ZKPartnerEnvelope alloc] initWithSessionHeader:nil clientId:clientId];
	[env startElement:@"login"];
	[env addElement:@"username" elemValue:username];
	[env addElement:@"password" elemValue:password]; 
	[env endElement:@"login"];
	[env endElement:@"s:Body"];
	NSString *xml = [env end];
	
	[self sendRequestAsync:xml 
	  withResponseDelegate:self 
	   andResponseSelector:@"parseLogin:withConnection:" withOperationName:@"login" withObjectName:nil withDelegate:delegate];
	[env release];
	
}

- (ZKLoginResult *) parseLogin:(ZKElement *)body withConnection:(ZKURLConnection *)conn 
{
	NSLog(@"Ok, we can parse this now.");
	
	ZKElement *result = [[body childElements:@"result"] objectAtIndex:0];
	ZKLoginResult *lr = [[[ZKLoginResult alloc] initWithXmlElement:result] autorelease];
	
	[endpointUrl release];
	endpointUrl = [[lr serverUrl] copy];
	sessionId = [[lr sessionId] copy];
	
	userInfo = [[lr userInfo] retain];
	
	if (self.useKeyChain) {
		[self saveLoginInKeychain];
	}
	if (conn.clientDelegate != nil) {
		if ([conn.clientDelegate conformsToProtocol:@protocol(ForceClientDelegate)]) {
			[conn.clientDelegate loginSucceeded:lr];
		}
	} 
	return lr;
}

- (void)saveLoginInKeychain 
{
	@try {
		[usernameItem setObject:username forKey:(id)kSecAttrAccount];
		[passwordItem setObject:password forKey:(id)kSecValueData];
	} @catch (id theException) {
		
	} 
}


- (NSMutableArray *)parseDelete:(ZKElement *)cr withConnection:(ZKURLConnection *) conn 
{
	NSArray *resArr = [cr childElements:@"result"];
	NSMutableArray *results = [NSMutableArray arrayWithCapacity:[resArr count]];
	for (ZKElement *cr in resArr) {
		ZKSaveResult *sr = [[ZKSaveResult alloc] initWithXmlElement:cr];
		[results addObject:sr];
		[sr release];
	} 
	
	if (conn.clientDelegate != nil && [conn.clientDelegate conformsToProtocol:@protocol(ForceClientDelegate)]) {
		[conn.clientDelegate deleteResultsReady:results];
	}
	return results;
}

- (NSArray *)parseDescribeGlobal:(ZKElement *)rr withConnection:(ZKURLConnection *)conn 
{	
	NSMutableArray *types = [NSMutableArray array]; 
	NSArray *results = [[rr childElement:@"result"] childElements:@"sobjects"];
	NSEnumerator * e = [results objectEnumerator];
	while (rr = [e nextObject]) 
    {
		ZKDescribeGlobalSObject * d = [[ZKDescribeGlobalSObject alloc] initWithXmlElement:rr];
		[types addObject:d];
		[d release];
	}
	if (cacheDescribes) 
    {
		[describes setObject:types forKey:@"describe__global"];			
	}
	
	if (conn.clientDelegate != nil && [conn.clientDelegate conformsToProtocol:@protocol(ForceClientDelegate)]) 
    {
		[conn.clientDelegate globalDescribesReady:types];
	}
	return types;
}

- (ZKDescribeSObject *)parseDescribeSObject:(ZKElement *)dr withConnection:(ZKURLConnection *)conn 
{
	ZKElement *descResult = [dr childElement:@"result"];
	ZKDescribeSObject *desc = [[[ZKDescribeSObject alloc] initWithXmlElement:descResult] autorelease];
	if (cacheDescribes) {
		[describes setObject:desc forKey:[[desc name] lowercaseString]];
	}
	if (conn.clientDelegate != nil && [conn.clientDelegate conformsToProtocol:@protocol(ForceClientDelegate)]) {
		[conn.clientDelegate describeSObjectReady:desc];
	}
	return desc;
}

- (NSDictionary *)parseRetrieve:(ZKElement *)rr withConnection:(ZKURLConnection *)conn 
{
	NSMutableDictionary *sobjects = [NSMutableDictionary dictionary]; 
	NSArray *results = [rr childElements:@"result"];
	for (ZKElement *res in results) {
		ZKSObject *o = [[ZKSObject alloc] initFromXmlNode:res];
		[sobjects setObject:o forKey:[o fieldValue:@"Id"]];
		[o release];
	}
	if (conn.clientDelegate != nil && [conn.clientDelegate conformsToProtocol:@protocol(ForceClientDelegate)]) {
		[conn.clientDelegate retrieveResultsReady:sobjects];
	}
	return sobjects;
}

- (NSArray *)parseSaveResults:(ZKElement *)cr withConnection:(ZKURLConnection *)conn 
{
	
	NSArray *resultsArr = [cr childElements:@"result"];
	NSMutableArray *results = [NSMutableArray arrayWithCapacity:[resultsArr count]];
	
	for (ZKElement *cr in resultsArr) {
		ZKSaveResult * sr = [[ZKSaveResult alloc] initWithXmlElement:cr];
		[results addObject:sr];
		[sr release];
	}
	
	if (conn.clientDelegate != nil && [conn.clientDelegate conformsToProtocol:@protocol(ForceClientDelegate)]) {
		[conn.clientDelegate saveResultsReady:results];
	}
	return results;
}

- (NSArray *) parseSearch:(ZKElement *)sr withConnection:(ZKURLConnection *)conn 
{
	ZKElement *searchResult = [sr childElement:@"result"];
	NSArray *records = [[searchResult childElement:@"searchRecords"] childElements:@"record"];
	NSMutableArray *sobjects = [NSMutableArray array];
	for (ZKElement *soNode in records) {
		[sobjects addObject:[ZKSObject fromXmlNode:soNode]];
	}
	if (conn.clientDelegate != nil && [conn.clientDelegate conformsToProtocol:@protocol(ForceClientDelegate)]) {
		[conn.clientDelegate searchResultsReady:sobjects];
	}
	return sobjects;
}

- (NSString *)parseServerTimeStamp:(ZKElement *)res withConnection:(ZKURLConnection *)conn 
{
	ZKElement *timestamp = [res childElement:@"result"];
	
	if (conn.clientDelegate != nil != [conn.clientDelegate conformsToProtocol:@protocol(ForceClientDelegate)]) {
		[conn.clientDelegate serverTimestampReady:[timestamp stringValue]];
	}
	return [timestamp stringValue];	
}

- (void)prepareQueryResult:(ZKElement *)queryResult withConnection:(ZKURLConnection *)conn 
{
	ZKQueryResult *result = [[ZKQueryResult alloc] initFromXmlNode:[[queryResult childElements] objectAtIndex:0]];
	
	if ([conn.clientDelegate conformsToProtocol:@protocol(ForceClientDelegate)]) {
		[conn.clientDelegate queryReady:result];
	}
	[result release];
}


@end

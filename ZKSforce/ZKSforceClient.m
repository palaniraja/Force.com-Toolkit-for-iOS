// Copyright (c) 2006 Simon Fell
//
// Permission is hereby granted, free of charge, to any person obtaining a 
// copy of this software and associated documentation files (the "Software"), 
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense, 
// and/or sell copies of the Software, and to permit persons to whom the 
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included 
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
// THE SOFTWARE.
//


#import "ZKSforceClient.h"
#import "ZKPartnerEnvelope.h"
#import "ZKQueryResult.h"
#import "ZKSaveResult.h"
#import "ZKSObject.h"
#import "ZKSoapException.h"
#import "ZKUserInfo.h"
#import "ZKDescribeSObject.h"
#import "ZKLoginResult.h"
#import "ZKDescribeGlobalSObject.h"
#import "ZKDescribeLayoutResult.h"
#import "ZKParser.h"

static const int MAX_SESSION_AGE = 25 * 60; // 25 minutes
static const int SAVE_BATCH_SIZE = 25;

@interface ZKSforceClient (Private)

- (ZKQueryResult *)queryImpl:(NSString *)value operation:(NSString *)op name:(NSString *)elemName;
- (void)queryImpl:(NSString *)value operation:(NSString *)op name:(NSString *)elemName withDelegate:(id)delegate;
- (NSArray *)sobjectsImpl:(NSArray *)objects name:(NSString *)elemName;
- (void)checkSession;
- (ZKLoginResult *)startNewSession;

- (void)startNewSessionAsync:(id)delegate;
- (ZKLoginResult *) parseLogin:(ZKElement *)body withConnection:(ZKURLConnection *)conn;
- (NSMutableArray *)parseDelete:(ZKElement *)cr withConnection:(ZKURLConnection *)conn;
- (NSArray *)parseDescribeGlobal:(ZKElement *)rr withConnection:(ZKURLConnection *)conn;
- (ZKDescribeSObject *)parseDescribeSObject:(ZKElement *)dr withConnection:(ZKURLConnection *)conn;
- (NSDictionary *)parseRetrieve:(ZKElement *)rr withConnection:(ZKURLConnection *)conn;
- (NSArray *)parseSaveResults:(ZKElement *)cr withConnection:(ZKURLConnection *)conn;
- (NSArray *) parseSearch:(ZKElement *)sr withConnection:(ZKURLConnection *)conn;
- (void)parseServerTimeStamp:(ZKElement *)res withCallBackData:(CallBackData *) conn;
- (void)prepareQueryResult:(ZKElement *)queryResult withConnection:(ZKURLConnection *)conn;
@end

@implementation ZKSforceClient;

@synthesize usernameItem, passwordItem, username, password, useKeyChain;

- (void)connectionDidFinishLoading:(ZKURLConnection *)conn 
{
	
	NSLog(@"connectionDidFinishLoading");
	
	id inflightDelegate;
	
	NSError *err = nil;
	
	@try {
		ZKElement *resp = [self processResponse:conn.receivedData response:self.httpResponse error:&err];
		
		SEL mycallback;
		mycallback = NSSelectorFromString(conn.responseSelector);
		
		inflightDelegate = conn.responseDelegate;
		
		if ([inflightDelegate respondsToSelector:mycallback]) 
        {
			NSLog(@"We can respond to the selector.");
			// This is an intermediate callback to the sforceClient
			[inflightDelegate performSelector:mycallback withObject:resp withObject:conn];
		} else {
			NSLog(@"We could not locate the selector.");
		}
		[resp retain];
		
	}
	@catch (ZKSoapException *e) {
		NSLog(@"%@", e);
		if ([conn.clientDelegate conformsToProtocol:@protocol(ForceClientDelegate)]) {
			[conn.clientDelegate receivedErrorFromAPICall:[NSString stringWithFormat:@"%@", e]];
		}
	}
	@finally {
		[self _stopReceiveWithStatus:nil withConnection:conn];
	}
	
}

- (void)connection:(ZKURLConnection *)conn didFailWithError:(NSError *)error
// A delegate method called by the NSURLConnection if the connection fails. 
// We shut down the connection and display the failure.  Production quality code 
// would either display or log the actual error.
{
#pragma unused(error)
	
	NSLog(@"didFailWithError %@", error);
	if ([conn.clientDelegate conformsToProtocol:@protocol(ForceClientDelegate)]) {
		[conn.clientDelegate receivedErrorFromAPICall:[error description]];
	}
	[self _stopReceiveWithStatus:@"Connection failed" withConnection:conn];
}

		 
- (id)init {
	if (self = [super init])
    {
        preferedApiVersion = 19;
        
        KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"password" accessGroup:nil];
        self.passwordItem = wrapper;
        [wrapper release];
        
        wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"username" accessGroup:nil];
        self.usernameItem = wrapper;
        [wrapper release];
        
        self.username = [self.usernameItem objectForKey:(id)kSecAttrAccount];
        self.password = [self.passwordItem objectForKey:(id)kSecValueData];
        
        [self setLoginProtocolAndHost:@"https://www.salesforce.com"];
        updateMru = NO;
        cacheDescribes = NO;
    }

	return self;
}

- (void)dealloc {
	[authEndpointUrl release];
	[username release];
	[password release];
	[clientId release];
	[sessionId release];
	[sessionExpiresAt release];
	[userInfo release];
	[describes release];
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
	ZKSforceClient *rhs = [[ZKSforceClient alloc] init];
	[rhs->authEndpointUrl release];
	rhs->authEndpointUrl = [authEndpointUrl copy];
	rhs->endpointUrl = [endpointUrl copy];
	rhs->sessionId = [sessionId copy];
	rhs->username = [username copy];
	rhs->password = [password copy];
	rhs->clientId = [clientId copy];
	rhs->sessionExpiresAt = [sessionExpiresAt copy];
	rhs->userInfo = [userInfo retain];
	[rhs setCacheDescribes:cacheDescribes];
	[rhs setUpdateMru:updateMru];
	return rhs;
}

- (BOOL)updateMru 
{
	return updateMru;
}

- (void)setUpdateMru:(BOOL)aValue 
{
	updateMru = aValue;
}

- (BOOL)cacheDescribes 
{
	return cacheDescribes;
}

- (void)setCacheDescribes:(BOOL)newCacheDescribes 
{
	if (cacheDescribes == newCacheDescribes) return;
	cacheDescribes = newCacheDescribes;
	[self flushCachedDescribes];
}

- (void)flushCachedDescribes 
{
	[describes release];
	describes = nil;
	if (cacheDescribes)
		describes = [[NSMutableDictionary alloc] init];
}

- (void)setLoginProtocolAndHost:(NSString *)protocolAndHost 
{
	[self setLoginProtocolAndHost:protocolAndHost andVersion:18];
}

- (void)setLoginProtocolAndHost:(NSString *)protocolAndHost andVersion:(int)version 
{
	[authEndpointUrl release];
	authEndpointUrl = [[NSString stringWithFormat:@"%@/services/Soap/u/%d.0", protocolAndHost, version] retain];
}

- (NSURL *)authEndpointUrl 
{
	return [NSURL URLWithString:authEndpointUrl];
}

#pragma mark Async implementation
-(void) loginAsync:(NSString *)un password:(NSString *)pwd withDelegate:(id)delegate 
{
	[userInfo release];
	userInfo = nil;
	[password release];
	[username release];
	username = [un retain];
	password = [pwd retain];
	[self startNewSessionAsync:delegate];	
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

- (void)queryAsync:(NSString *)soql withDelegate:(id)delegate 
{
	[self queryImplAsync:soql operation:@"query" name:@"queryString" withDelegate:delegate];
}

- (void)queryImplAsync:(NSString *)value operation:(NSString *)operation name:(NSString *)elemName withDelegate:(id)delegate
{
	if(!sessionId) 
        return;
	
	[self checkSession];
	
	ZKEnvelope *env = [[ZKPartnerEnvelope alloc] initWithSessionHeader:sessionId clientId:clientId];
	[env startElement:operation];
	[env addElement:elemName elemValue:value];
	[env endElement:operation];
	[env endElement:@"s:Body"]; 
	
	[self sendRequestAsync:[env end] withResponseDelegate:self andResponseSelector:@"prepareQueryResult:withConnection:" withOperationName:@"query" withObjectName:nil withDelegate:delegate];
	[env release];
}

- (void)prepareQueryResult:(ZKElement *)queryResult withConnection:(ZKURLConnection *)conn 
{
	ZKQueryResult *result = [[ZKQueryResult alloc] initFromXmlNode:[[queryResult childElements] objectAtIndex:0]];
	
	if ([conn.clientDelegate conformsToProtocol:@protocol(ForceClientDelegate)]) {
		[conn.clientDelegate queryReady:result];
	}
	[result release];
}

- (void)describeGlobalAsync:(id)delegate 
{
	if(!sessionId) 
        return;
	
	[self checkSession];
	if (cacheDescribes) {
		NSArray *dg = [describes objectForKey:@"describe__global"];	// won't be an sfdc object ever called this.
		if (dg != nil) {
			if ([delegate conformsToProtocol:@protocol(ForceClientDelegate)]) {
				[delegate globalDescribesReady:dg];
			}
		}
	} else {
		
		ZKEnvelope * env = [[ZKPartnerEnvelope alloc] initWithSessionHeader:sessionId clientId:clientId];
		[env startElement:@"describeGlobal"];
		[env endElement:@"describeGlobal"];
		[env endElement:@"s:Body"];
		
		[self sendRequestAsync:[env end] withResponseDelegate:self andResponseSelector:@"parseDescribeGlobal:withConnection" withOperationName:@"describeGlobal" withObjectName:nil withDelegate:delegate];
		[env release];
	}
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

- (void)describeSObjectAsync:(NSString *)sobjectName withDelegate:(id)delegate 
{
	if (sessionId) 
    {
		[self checkSession];
		ZKDescribeSObject * desc;
		if (cacheDescribes) 
        {
			desc = [describes objectForKey:[sobjectName lowercaseString]];
			if (desc != nil) 
            {
				if ([delegate conformsToProtocol:@protocol(ForceClientDelegate)]) 
                {
					[delegate describeSObjectReady:desc];
					return;
				}
			}
		} 
		
		ZKEnvelope * env = [[ZKPartnerEnvelope alloc] initWithSessionHeader:sessionId clientId:clientId];
		[env startElement:@"describeSObject"];
		[env addElement:@"SobjectType" elemValue:sobjectName];
		[env endElement:@"describeSObject"];
		[env endElement:@"s:Body"];
		[self sendRequestAsync:[env end] withResponseDelegate:self andResponseSelector:@"parseDescribeSObject:withConnection:" withOperationName:@"describeSObject" withObjectName:sobjectName	withDelegate:delegate];
		[env release];
	}
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

- (void)searchAsync:(NSString *)sosl withDelegate:(id)delegate
{
	if (sessionId) 
    {
		[self checkSession];
		ZKEnvelope *env = [[ZKPartnerEnvelope alloc] initWithSessionHeader:sessionId clientId:clientId];
		[env startElement:@"search"];
		[env addElement:@"searchString" elemValue:sosl];
		[env endElement:@"search"];
		[env endElement:@"s:Body"];
		[self sendRequestAsync:[env end] withResponseDelegate:self andResponseSelector:@"parseSearch:withConnection" withOperationName:@"search" withObjectName:nil withDelegate:delegate];
		[env release];
	}
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

- (void)queryAllAsync:(NSString *)soql withDelegate:(id)delegate 
{
	
}

- (void)queryMoreAsync:(NSString *)queryLocator withDelegate:(id)delegate 
{
	
}

- (void)retrieveAsync:(NSString *)fields sobject:(NSString *)sobjectType ids:(NSArray *)ids withDelegate:(id)delegate 
{
	if(!sessionId) 
        return;
	
	[self checkSession];
	
	ZKEnvelope * env = [[ZKPartnerEnvelope alloc] initWithSessionHeader:sessionId clientId:clientId];
	[env startElement:@"retrieve"];
	[env addElement:@"fieldList" elemValue:fields];
	[env addElement:@"sObjectType" elemValue:sobjectType];
	[env addElementArray:@"ids" elemValue:ids];
	[env endElement:@"retrieve"];
	[env endElement:@"s:Body"];
	[self sendRequestAsync:[env end] withResponseDelegate:self andResponseSelector:@"parseRetrieve:withConnection:" withOperationName:@"retrieve" withObjectName:sobjectType withDelegate:delegate];
	[env release];
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

- (void)createAsync:(NSArray *)objects withDelegate:(id)delegate 
{
	return [self sobjectsImplAsync:objects name:@"create" withDelegate:delegate];	
}

- (void)updateAsync:(NSArray *)objects withDelegate:(id)delegate 
{
	return [self sobjectsImplAsync:objects name:@"update" withDelegate:delegate];
}

- (void)deleteAsync:(NSArray *)ids withDelegate:delegate 
{
	if(!sessionId) 
        return;
	
	[self checkSession];
	
	ZKEnvelope *env = [[ZKPartnerEnvelope alloc] initWithSessionAndMruHeaders:sessionId mru:updateMru clientId:clientId];
	[env startElement:@"delete"];
	[env addElement:@"ids" elemValue:ids];
	[env endElement:@"delete"];
	[env endElement:@"s:Body"];
	
	[self sendRequestAsync:[env end] withResponseDelegate:self andResponseSelector:@"parseDelete:withConnection:" withOperationName:@"delete" withObjectName:nil withDelegate:delegate];
	[env release];
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

- (void)serverTimestampAsync:(id)delegate 
{
	if (!sessionId) 
        return;
	[self checkSession];
	
	ZKEnvelope *env = [[ZKPartnerEnvelope alloc] initWithSessionHeader:sessionId clientId:clientId];
	[env startElement:@"getServerTimestamp"];
	[env endElement:@"getServerTimestamp"];
	[env endElement:@"s:Body"];
	
	[self sendRequestAsync:[env end] withResponseDelegate:self andResponseSelector:@"parseServerTimestamp:withConnection:" withOperationName:@"serverTimestamp" withObjectName:nil withDelegate:delegate];
	[env release];
}

- (NSString *)parseServerTimeStamp:(ZKElement *)res withConnection:(ZKURLConnection *)conn 
{
	ZKElement *timestamp = [res childElement:@"result"];
	
	if (conn.clientDelegate != nil != [conn.clientDelegate conformsToProtocol:@protocol(ForceClientDelegate)]) {
		[conn.clientDelegate serverTimestampReady:[timestamp stringValue]];
	}
	return [timestamp stringValue];	
}

- (void)setPasswordAsync:(NSString *)newPassword forUserId:(NSString *)userId withDelegate:(id)delegate 
{
	if(!sessionId) 
        return;
	[self checkSession];
	
	ZKEnvelope * env = [[ZKPartnerEnvelope alloc] initWithSessionHeader:sessionId clientId:clientId];
	[env startElement:@"setPassword"];
	[env addElement:@"userId" elemValue:userId];
	[env addElement:@"password" elemValue:newPassword];
	[env endElement:@"setPassword"];
	[env endElement:@"s:Body"];
	
	[self sendRequestAsync:[env end] withResponseDelegate:self andResponseSelector:@"parseSetPassword:withConnection:" withOperationName:@"setPassword" withObjectName:nil withDelegate:delegate];
	[env release];
	
}

- (void)sobjectsImplAsync:(NSArray *)objects name:(NSString *)elemName withDelegate:(id)delegate 
{
	if(!sessionId) {
		[self checkSession];
	} 
	
	// if more than we can do in one go, break it up. DC - Ignoring this case.
	ZKEnvelope *env = [[ZKPartnerEnvelope alloc] initWithSessionAndMruHeaders:sessionId mru:updateMru clientId:clientId];
	[env startElement:elemName];
	
	NSEnumerator *e = [objects objectEnumerator];
	ZKSObject *o;
	
	while (o = [e nextObject]) {
		[env addElement:@"sobject" elemValue:o];
	}
	[env endElement:elemName];
	[env endElement:@"s:Body"];
	
	[self sendRequestAsync:[env end] withResponseDelegate:self andResponseSelector:@"parseSaveResults:withConnection:" withOperationName:elemName withObjectName:nil withDelegate:delegate];
	[env release];
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

#pragma mark synch implementation

- (ZKLoginResult *)login:(NSString *)un password:(NSString *)pwd 
{
	[userInfo release];
	userInfo = nil;
	[password release];
	[username release];
	username = [un retain];
	password = [pwd retain];
	return [self startNewSession];
}

- (void)saveLoginInKeychain 
{
	@try {
		[usernameItem setObject:username forKey:(id)kSecAttrAccount];
		[passwordItem setObject:password forKey:(id)kSecValueData];
	} @catch (id theException) {
		
	} 
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

- (BOOL)loggedIn 
{
	return [sessionId length] > 0;
}

- (void)checkSession 
{
	if ([sessionExpiresAt timeIntervalSinceNow] < 0)
		[self startNewSession];
}

- (ZKUserInfo *)currentUserInfo 
{
	return userInfo;
}

- (NSString *)serverUrl 
{
	return endpointUrl;
}

- (NSString *)sessionId 
{
	[self checkSession];
	return sessionId;
}

- (NSString *)clientId 
{
	return clientId;
}

- (void)setClientId:(NSString *)aClientId 
{
	aClientId = [aClientId copy];
	[clientId release];
	clientId = aClientId;
}

- (void)setPassword:(NSString *)newPassword forUserId:(NSString *)userId 
{
	if(!sessionId) 
        return;
	[self checkSession];
	
	ZKEnvelope * env = [[ZKPartnerEnvelope alloc] initWithSessionHeader:sessionId clientId:clientId];
	[env startElement:@"setPassword"];
	[env addElement:@"userId" elemValue:userId];
	[env addElement:@"password" elemValue:newPassword];
	[env endElement:@"setPassword"];
	[env endElement:@"s:Body"];
	
	[self sendRequest:[env end]];
	[env release];
}

- (NSArray *)describeGlobal 
{
	if(!sessionId) 
        return nil;
	[self checkSession];
	if (cacheDescribes) {
		NSArray *dg = [describes objectForKey:@"describe__global"];	// won't be an sfdc object ever called this.
		if (dg != nil) 
            return dg;
	}
	
	ZKEnvelope * env = [[ZKPartnerEnvelope alloc] initWithSessionHeader:sessionId clientId:clientId];
	[env startElement:@"describeGlobal"];
	[env endElement:@"describeGlobal"];
	[env endElement:@"s:Body"];
	
	ZKElement * rr = [self sendRequest:[env end]];
	[env release];
	return [self parseDescribeGlobal:rr withConnection:nil];
	/*	NSMutableArray *types = [NSMutableArray array]; 
	 NSArray *results = [[rr childElement:@"result"] childElements:@"sobjects"];
	 NSEnumerator * e = [results objectEnumerator];
	 while (rr = [e nextObject]) {
	 ZKDescribeGlobalSObject * d = [[ZKDescribeGlobalSObject alloc] initWithXmlElement:rr];
	 [types addObject:d];
	 [d release];
	 }
	 [env release];
	 if (cacheDescribes)
	 [describes setObject:types forKey:@"describe__global"];
	 return types;*/
}

- (ZKDescribeSObject *)describeSObject:(NSString *)sobjectName 
{
	if (!sessionId) 
        return nil;
	if (cacheDescribes) {
		ZKDescribeSObject * desc = [describes objectForKey:[sobjectName lowercaseString]];
		if (desc != nil) 
            return desc;
	}
	[self checkSession];
	
	ZKEnvelope * env = [[ZKPartnerEnvelope alloc] initWithSessionHeader:sessionId clientId:clientId];
	[env startElement:@"describeSObject"];
	[env addElement:@"SobjectType" elemValue:sobjectName];
	[env endElement:@"describeSObject"];
	[env endElement:@"s:Body"];
	
	ZKElement *dr = [self sendRequest:[env end]];
	[env release];
	return [self parseDescribeSObject:dr withConnection:nil];
}

-(void)describeLayoutAsync:(NSString *)sobjectName withDelegate:(id)delegate 
{
	if (!sessionId) 
        return;
	NSString *cacheKey = [[sobjectName stringByAppendingString:@"layout" ] lowercaseString];
	if (cacheDescribes) {
		ZKDescribeLayoutResult * desc = [describes objectForKey:cacheKey];
		if (desc != nil) {
			if ([delegate conformsToProtocol:@protocol(ForceClientDelegate)]) {
				[delegate describeLayoutResultsReady:desc];
			}
		}
	}
	[self checkSession];
	
	ZKEnvelope * env = [[ZKPartnerEnvelope alloc] initWithSessionHeader:sessionId clientId:clientId];
	[env startElement:@"describeLayout"];
	[env addElement:@"SobjectType" elemValue:sobjectName];
	[env endElement:@"describeLayout"];
	[env endElement:@"s:Body"];
	
	[self sendRequestAsync:[env end] withResponseDelegate:self andResponseSelector:@"parseDescribeLayout:withConnection:" withOperationName:@"describeLayout" withObjectName:sobjectName withDelegate:delegate];
	[env release];
}

-(ZKDescribeLayoutResult *) parseDescribeLayout:(ZKElement *)dr withConnection:(ZKURLConnection *)conn 
{
	ZKElement *descResult = [dr childElement:@"result"];
	ZKDescribeLayoutResult *desc = [[[ZKDescribeLayoutResult alloc] initWithXmlElement:descResult] autorelease];
	NSString *cacheKey = [[conn.layoutObjectName stringByAppendingString:@"layout" ] lowercaseString];
	
	if (cacheDescribes) 
		[describes setObject:desc forKey:cacheKey];
	if (conn.responseDelegate != nil && [conn.clientDelegate conformsToProtocol:@protocol(ForceClientDelegate)]) {
		[conn.clientDelegate describeLayoutResultsReady:desc];
	}
	return desc;	
}

- (ZKDescribeLayoutResult *)describeLayout:(NSString *)sobjectName 
{
	if (!sessionId) 
        return nil;
	NSString *cacheKey = [[sobjectName stringByAppendingString:@"layout" ] lowercaseString];
	if (cacheDescribes) {
		ZKDescribeLayoutResult * desc = [describes objectForKey:cacheKey];
		if (desc != nil) 
            return desc;
	}
	[self checkSession];
	
	ZKEnvelope * env = [[ZKPartnerEnvelope alloc] initWithSessionHeader:sessionId clientId:clientId];
	[env startElement:@"describeLayout"];
	[env addElement:@"SobjectType" elemValue:sobjectName];
	[env endElement:@"describeLayout"];
	[env endElement:@"s:Body"];
	
	ZKElement *dr = [self sendRequest:[env end]];
	[env release];
	ZKURLConnection *conn = [[ZKURLConnection alloc] init];
	conn.layoutObjectName = sobjectName;
	return [self parseDescribeLayout:dr withConnection:conn];
	/*
	 ZKElement *descResult = [dr childElement:@"result"];
	 ZKDescribeLayoutResult *desc = [[[ZKDescribeLayoutResult alloc] initWithXmlElement:descResult] autorelease];
	 [env release];
	 
	 if (cacheDescribes) 
	 [describes setObject:desc forKey:cacheKey];
	 return desc;*/
}

- (NSArray *)search:(NSString *)sosl 
{
	if (!sessionId) 
        return nil;
	[self checkSession];
	ZKEnvelope *env = [[ZKPartnerEnvelope alloc] initWithSessionHeader:sessionId clientId:clientId];
	[env startElement:@"search"];
	[env addElement:@"searchString" elemValue:sosl];
	[env endElement:@"search"];
	[env endElement:@"s:Body"];
	
	ZKElement *sr = [self sendRequest:[env end]];
	[env release];
	return [self parseSearch:sr withConnection:nil];
}

- (NSString *)serverTimestamp 
{
	if (!sessionId) 
        return nil;
	[self checkSession];
	ZKEnvelope *env = [[ZKPartnerEnvelope alloc] initWithSessionHeader:sessionId clientId:clientId];
	[env startElement:@"getServerTimestamp"];
	[env endElement:@"getServerTimestamp"];
	[env endElement:@"s:Body"];
	
	ZKElement *res = [self sendRequest:[env end]];
	ZKElement *timestamp = [res childElement:@"result"];
	[env release];
	return [timestamp stringValue];
}

- (ZKQueryResult *)query:(NSString *) soql 
{
	return [self queryImpl:soql operation:@"query" name:@"queryString"];
}

- (ZKQueryResult *)queryAll:(NSString *) soql 
{
	return [self queryImpl:soql operation:@"queryAll" name:@"queryString"];
}

- (ZKQueryResult *)queryMore:(NSString *)queryLocator 
{
	return [self queryImpl:queryLocator operation:@"queryMore" name:@"queryLocator"];
}

- (NSArray *)create:(NSArray *)objects 
{
	return [self sobjectsImpl:objects name:@"create"];
}

- (NSArray *)update:(NSArray *)objects 
{
	return [self sobjectsImpl:objects name:@"update"];
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

- (NSDictionary *)retrieve:(NSString *)fields sobject:(NSString *)sobjectType ids:(NSArray *)ids 
{
	if(!sessionId) 
        return nil;
	[self checkSession];
	
	ZKEnvelope * env = [[ZKPartnerEnvelope alloc] initWithSessionHeader:sessionId clientId:clientId];
	[env startElement:@"retrieve"];
	[env addElement:@"fieldList" elemValue:fields];
	[env addElement:@"sObjectType" elemValue:sobjectType];
	[env addElementArray:@"ids" elemValue:ids];
	[env endElement:@"retrieve"];
	[env endElement:@"s:Body"];
	
	ZKElement *rr = [self sendRequest:[env end]];
	[env release];
	return [self parseRetrieve:rr withConnection:nil];
}

- (NSArray *)delete:(NSArray *)ids
{
	if(!sessionId) 
        return nil;
	[self checkSession];
	
	ZKEnvelope *env = [[ZKPartnerEnvelope alloc] initWithSessionAndMruHeaders:sessionId mru:updateMru clientId:clientId];
	[env startElement:@"delete"];
	[env addElement:@"ids" elemValue:ids];
	[env endElement:@"delete"];
	[env endElement:@"s:Body"];
	
	ZKElement *cr = [self sendRequest:[env end]];
	[env release];
	return [self parseDelete:cr withConnection:nil];
	
	/*NSArray *resArr = [cr childElements:@"result"];
	 NSMutableArray *results = [NSMutableArray arrayWithCapacity:[resArr count]];
	 for (ZKElement *cr in resArr) {
	 ZKSaveResult *sr = [[ZKSaveResult alloc] initWithXmlElement:cr];
	 [results addObject:sr];
	 [sr release];
	 }
	 return results;*/
}

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


@end

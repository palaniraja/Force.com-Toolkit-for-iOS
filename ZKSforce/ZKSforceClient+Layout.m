//
//  ZKSforceClient+Layout.m
//  SVNTest
//
//  Created by Rick Fillion on 8/18/10.
//  Copyright 2010 Centrix.ca. All rights reserved.
//

#import "ZKSforceClient+Layout.h"
#import "ZKSforceClient+Private.h"
#import "ZKDescribeLayoutResult.h"
#import "ZKParser.h"
#import "ZKURLConnection.h"
#import "ZKEnvelope.h"
#import "ZKPartnerEnvelope.h"

@interface ZKSforceClient (LayoutPrivate)

-(ZKDescribeLayoutResult *) parseDescribeLayout:(ZKElement *)dr withConnection:(ZKURLConnection *)conn;

@end


@implementation ZKSforceClient (Layout)



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

#pragma mark Private

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

@end

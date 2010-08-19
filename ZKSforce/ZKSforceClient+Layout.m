// Copyright (c) 2010 Rick Fillion
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
	
	[self sendRequestAsync:[env end] withResponseDelegate:self andResponseSelector:@selector(parseDescribeLayout:withConnection:) withOperationName:@"describeLayout" withObjectName:sobjectName withDelegate:delegate];
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

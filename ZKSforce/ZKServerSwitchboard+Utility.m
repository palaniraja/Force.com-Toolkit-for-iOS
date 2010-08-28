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

#import "ZKServerSwitchboard+Utility.h"
#import "ZKServerSwitchboard+Private.h"
#import "ZKParser.h"
#import "ZKEnvelope.h"
#import "ZKPartnerEnvelope.h"
#import "ZKSoapException.h"
#import "NSObject+Additions.h"
#import "NSDate+Additions.h"
#import "ZKSaveResult.h"
#import "ZKEmailMessage.h"

@interface ZKServerSwitchboard (UtilityWrappers)

- (NSNumber *)_processSetPasswordResponse:(ZKElement *)setPasswordResponseElement error:(NSError *)error context:(NSDictionary *)context;
- (NSDate *)_processGetServerTimestampResponse:(ZKElement *)getServerTimestampResponseElement error:(NSError *)error context:(NSDictionary *)context;
- (NSArray *)_processEmptyRecycleBinResponse:(ZKElement *)emptyRecycleBinResponseElement error:(NSError *)error context:(NSDictionary *)context;
- (NSNumber *)_processSendEmailResponse:(ZKElement *)sendEmailResponseElement error:(NSError *)error context:(NSDictionary *)context;
@end


@implementation ZKServerSwitchboard (Utility)

- (void)emptyRecycleBin:(NSArray *)objectIDs target:(id)target selector:(SEL)selector context:(id)context
{
    [self _checkSession];
    
    ZKEnvelope *env = [[[ZKPartnerEnvelope alloc] initWithSessionId:sessionId updateMru:self.updatesMostRecentlyUsed clientId:clientId] autorelease];
	[env startElement:@"emptyRecycleBin"];
	[env addElement:@"ids" elemValue:objectIDs];
	[env endElement:@"emptyRecycleBin"];
	[env endElement:@"s:Body"];
    NSString *xml = [env end];
	
    NSDictionary *wrapperContext = [self _contextWrapperDictionaryForTarget:target selector:selector context:context];
    [self _sendRequestWithData:xml target:self selector:@selector(_processEmptyRecycleBinResponse:error:context:) context: wrapperContext];
}

- (void)getServerTimestampWithTarget:(id)target selector:(SEL)selector context:(id)context
{
    [self _checkSession];
    
    ZKEnvelope *env = [[[ZKPartnerEnvelope alloc] initWithSessionHeader:self.sessionId clientId:self.clientId] autorelease];
	[env startElement:@"getServerTimestamp"];
	[env endElement:@"getServerTimestamp"];
	[env endElement:@"s:Body"];
    NSString *xml = [env end];
    
    NSDictionary *wrapperContext = [self _contextWrapperDictionaryForTarget:target selector:selector context:context];
    [self _sendRequestWithData:xml target:self selector:@selector(_processGetServerTimestampResponse:error:context:) context: wrapperContext];
}

- (void)resetPasswordForUserId:(NSString *)userId triggerUserEmail:(BOOL)triggerUserEmail target:(id)target selector:(SEL)selector context:(id)context
{
    NSLog(@"resetPasswordForUserId not implemented yet");
}

- (void)sendEmail:(NSArray *)emails target:(id)target selector:(SEL)selector context:(id)context
{
    NSLog(@"Warning sendEmail doesn't seem to work just yet.");
    [self _checkSession];
    
	ZKEnvelope *env = [[[ZKPartnerEnvelope alloc] initWithSessionId:sessionId updateMru:self.updatesMostRecentlyUsed clientId:clientId] autorelease];
    NSDictionary *messageElementParameters = [NSDictionary dictionaryWithObject:@"urn:SingleEmailMessage" forKey:@"type"];
	[env startElement:@"sendEmail"];
	for (ZKSObject *message in emails)
    {
        [env startElement:@"messages" withParameters:messageElementParameters];
        [env addSObjectFields: message];
        [env endElement:@"messages"];
    }
	[env endElement:@"sendEmail"];
	[env endElement:@"s:Body"];
    NSString *xml = [env end];
    
    NSDictionary *wrapperContext = [self _contextWrapperDictionaryForTarget:target selector:selector context:context];
    [self _sendRequestWithData:xml target:self selector:@selector(_processSendEmailResponse:error:context:) context: wrapperContext];
}

- (void)setPassword:(NSString *)password forUserId:(NSString *)userId target:(id)target selector:(SEL)selector context:(id)context
{
    [self _checkSession];
    
    ZKEnvelope *env = [[[ZKPartnerEnvelope alloc] initWithSessionHeader:self.sessionId clientId:self.clientId] autorelease];
	[env startElement:@"setPassword"];
	[env addElement:@"userId" elemValue:userId];
	[env addElement:@"password" elemValue:password];
	[env endElement:@"setPassword"];
	[env endElement:@"s:Body"];
    NSString *xml = [env end];
    
    NSDictionary *wrapperContext = [self _contextWrapperDictionaryForTarget:target selector:selector context:context];
    [self _sendRequestWithData:xml target:self selector:@selector(_processSearchResponse:error:context:) context: wrapperContext];
}


@end


@implementation ZKServerSwitchboard (UtilityWrappers)

- (NSNumber *)_processSetPasswordResponse:(ZKElement *)setPasswordResponseElement error:(NSError *)error context:(NSDictionary *)context
{
    // A fault would happen (and an error prepped) if it wasn't successful.
    NSNumber *response = [NSNumber numberWithBool: (error ? NO : YES)];
    [self _unwrapContext:context andCallSelectorWithResponse:response error:error];
	return response;
}

- (NSDate *)_processGetServerTimestampResponse:(ZKElement *)getServerTimestampResponseElement error:(NSError *)error context:(NSDictionary *)context
{
	ZKElement *result = [getServerTimestampResponseElement childElement:@"result"];
    ZKElement *timestampElement = [result childElement:@"timestamp"];
    NSString *timestampString = [timestampElement stringValue];
    NSDate *timestamp = [NSDate dateWithLongFormatString:timestampString];
    [self _unwrapContext:context andCallSelectorWithResponse:timestamp error:error];
	return timestamp;
}

- (NSArray *)_processEmptyRecycleBinResponse:(ZKElement *)emptyRecycleBinResponseElement error:(NSError *)error context:(NSDictionary *)context
{
    NSArray *resArr = [emptyRecycleBinResponseElement childElements:@"result"];
	NSMutableArray *results = [NSMutableArray arrayWithCapacity:[resArr count]];
	for (ZKElement *saveResultElement in resArr) {
		ZKSaveResult *sr = [[[ZKSaveResult alloc] initWithXmlElement:saveResultElement] autorelease];
		[results addObject:sr];
	} 
    [self _unwrapContext:context andCallSelectorWithResponse:results error:error];
	return results;
}

- (NSNumber *)_processSendEmailResponse:(ZKElement *)sendEmailResponseElement error:(NSError *)error context:(NSDictionary *)context
{
    // A fault would happen (and an error prepped) if it wasn't successful.
    NSNumber *response = [NSNumber numberWithBool: (error ? NO : YES)];
    [self _unwrapContext:context andCallSelectorWithResponse:response error:error];
	return response;
}

@end


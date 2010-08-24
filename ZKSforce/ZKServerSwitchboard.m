// Copyright (c) 2010 Rick Fillion
// Code based on Chris Farber's CRServerSwitchboard
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

#import "ZKServerSwitchboard.h"
#import "ZKParser.h"
#import "ZKEnvelope.h"
#import "ZKPartnerEnvelope.h"
#import "ZKSoapException.h"
#import "ZKLoginResult.h"
#import "NSObject+Additions.h"
#import "ZKSaveResult.h"

static const int MAX_SESSION_AGE = 25 * 60; // 25 minutes
static NSString *SOAP_NS = @"http://schemas.xmlsoap.org/soap/envelope/";
static ZKServerSwitchboard * sharedSwitchboard =  nil;

@interface ZKServerSwitchboard (Private)


- (void)_sendRequestWithData:(NSString *)payload
                      target:(id)target
                    selector:(SEL)sel;
- (void)_sendRequestWithData:(NSString *)payload
                      target:(id)target
                    selector:(SEL)sel
                     context:(id)context;
- (void)_sendRequest:(NSURLRequest *)aRequest
              target:(id)target
            selector:(SEL)sel
             context:(id)context;
- (NSDictionary *)_contextWrapperDictionaryForTarget:(id)target selector:(SEL)selector context:(id)context;
- (void)_unwrapContext:(NSDictionary *)wrapperContext andCallSelectorWithResponse:(id)response error:(NSError *)error;
- (void)_returnResponseForConnection:(NSURLConnection *)connection;
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection; 
-(ZKElement *)_processHttpResponse:(NSHTTPURLResponse *)resp data:(NSData *)responseData;
// Wrappers
- (ZKLoginResult *)_processLoginResponse:(ZKElement *)loginResponseElement error:(NSError *)error context:(NSDictionary *)context;
- (ZKQueryResult *)_processQueryResponse:(ZKElement *)queryResponseElement error:(NSError *)error context:(NSDictionary *)context;
- (NSArray *)_processSaveResponse:(ZKElement *)saveResponseElement error:(NSError *)error context:(NSDictionary *)context;
- (NSArray *)_processDeleteResponse:(ZKElement *)saveResponseElement error:(NSError *)error context:(NSDictionary *)context;

@end

@implementation ZKServerSwitchboard

@synthesize apiUrl;
@synthesize clientId;
@synthesize sessionId;
@synthesize userInfo;
//@synthesize savesUsernameAndPasswordInKeychain;
@synthesize updatesMostRecentlyUsed;
@synthesize logXMLInOut;

+ (ZKServerSwitchboard *)switchboard
{
    if (sharedSwitchboard == nil)
    {
        sharedSwitchboard = [[super allocWithZone:NULL] init];
    }
    
    return sharedSwitchboard;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [[self switchboard] retain];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    // Denotes an object that cannot be released
    return NSUIntegerMax;
}

- (void)release
{
    // Do nothing
}

- (id)autorelease
{
    return self;
}

- init
{
    if (!(self = [super init])) 
        return nil;
    
    connections = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks,
                                            &kCFTypeDictionaryValueCallBacks);
    connectionsData = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks,
                                                &kCFTypeDictionaryValueCallBacks);
    preferredApiVersion = 19;

    self.logXMLInOut = NO;
    
    return self;
}

- (void)dealloc
{
    CFRelease(connections);
    connections = NULL;
    
    CFRelease(connectionsData);
    connectionsData = NULL;
    
    [super dealloc];
}

+ (NSString *)baseURL
{
    return @"https://www.salesforce.com";
}

#pragma mark Properties

- (NSString *)apiUrl
{
    if (apiUrl)
        return apiUrl;
    return [self authenticationUrl];
}

#pragma mark Methods

- (NSString *)authenticationUrl
{
    NSString *url = [NSString stringWithFormat:@"%@/services/Soap/u/%d.0", [[self class] baseURL] , preferredApiVersion];
    return url;
}

- (void)authenticateWithUsername:(NSString *)username password:(NSString *)password target:(id)target selector:(SEL)selector
{
    [sessionExpiry release];
	sessionExpiry = [[NSDate dateWithTimeIntervalSinceNow:MAX_SESSION_AGE] retain];
	[sessionId release];
	
	ZKEnvelope *env = [[[ZKPartnerEnvelope alloc] initWithSessionHeader:nil clientId:clientId] autorelease];
	[env startElement:@"login"];
	[env addElement:@"username" elemValue:username];
	[env addElement:@"password" elemValue:password]; 
	[env endElement:@"login"];
	[env endElement:@"s:Body"];
	NSString *xml = [env end];
	
    NSDictionary *wrapperContext = [self _contextWrapperDictionaryForTarget:target selector:selector context:nil];
    [self _sendRequestWithData:xml target:self selector:@selector(_processLoginResponse:error:context:) context: wrapperContext];
}

- (void)query:(NSString *)soqlQuery target:(id)target selector:(SEL)selector context:(id)context
{
    ZKEnvelope *env = [[[ZKPartnerEnvelope alloc] initWithSessionHeader:self.sessionId clientId:self.clientId] autorelease];
	[env startElement:@"query"];
	[env addElement:@"queryString" elemValue:soqlQuery];
	[env endElement:@"query"];
	[env endElement:@"s:Body"]; 
    NSString *xml = [env end];

    NSDictionary *wrapperContext = [self _contextWrapperDictionaryForTarget:target selector:selector context:context];
    [self _sendRequestWithData:xml target:self selector:@selector(_processQueryResponse:error:context:) context: wrapperContext];
}

- (void)create:(NSArray *)objects target:(id)target selector:(SEL)selector context:(id)context
{
    // if more than we can do in one go, break it up. DC - Ignoring this case.
	ZKEnvelope *env = [[[ZKPartnerEnvelope alloc] initWithSessionId:sessionId updateMru:self.updatesMostRecentlyUsed clientId:clientId] autorelease];
	[env startElement:@"create"];
	for (ZKSObject *object in objects)
    {
        [env addElement:@"sobject" elemValue:object];
    }
	[env endElement:@"create"];
	[env endElement:@"s:Body"];
    NSString *xml = [env end];
    
    NSDictionary *wrapperContext = [self _contextWrapperDictionaryForTarget:target selector:selector context:context];
    [self _sendRequestWithData:xml target:self selector:@selector(_processSaveResponse:error:context:) context: wrapperContext];
}

- (void)update:(NSArray *)objects target:(id)target selector:(SEL)selector context:(id)context
{
	// if more than we can do in one go, break it up. DC - Ignoring this case.
	ZKEnvelope *env = [[[ZKPartnerEnvelope alloc] initWithSessionId:sessionId updateMru:self.updatesMostRecentlyUsed clientId:clientId] autorelease];
	[env startElement:@"update"];
	for (ZKSObject *object in objects)
    {
        [env addElement:@"sobject" elemValue:object];
    }
	[env endElement:@"update"];
	[env endElement:@"s:Body"];
    NSString *xml = [env end];
    
    NSDictionary *wrapperContext = [self _contextWrapperDictionaryForTarget:target selector:selector context:context];
    [self _sendRequestWithData:xml target:self selector:@selector(_processSaveResponse:error:context:) context: wrapperContext];
}

- (void)delete:(NSArray *)objectIDs target:(id)target selector:(SEL)selector context:(id)context
{
    ZKEnvelope *env = [[[ZKPartnerEnvelope alloc] initWithSessionId:sessionId updateMru:self.updatesMostRecentlyUsed clientId:clientId] autorelease];
	[env startElement:@"delete"];
	[env addElement:@"ids" elemValue:objectIDs];
	[env endElement:@"delete"];
	[env endElement:@"s:Body"];
    NSString *xml = [env end];
	
    NSDictionary *wrapperContext = [self _contextWrapperDictionaryForTarget:target selector:selector context:context];
    [self _sendRequestWithData:xml target:self selector:@selector(_processDeleteResponse:error:context:) context: wrapperContext];
}



@end

@implementation ZKServerSwitchboard (Private)

- (void)_sendRequestWithData:(NSString *)payload
                      target:(id)target
                    selector:(SEL)sel
{
    [self _sendRequestWithData:payload
                        target:target
                      selector:sel
                       context:nil];
}

- (void)_sendRequestWithData:(NSString *)payload
              target:(id)target
            selector:(SEL)sel
             context:(id)context
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[self apiUrl]]];
	[request setHTTPMethod:@"POST"];
	[request addValue:@"text/xml; charset=UTF-8" forHTTPHeaderField:@"content-type"];	
	[request addValue:@"\"\"" forHTTPHeaderField:@"SOAPAction"];
	NSData *data = [payload dataUsingEncoding:NSUTF8StringEncoding];
	[request setHTTPBody:data];

	if(self.logXMLInOut) {
		NSLog(@"OutputHeaders:\n%@", [request allHTTPHeaderFields]);
		NSLog(@"OutputBody:\n%@", payload);
	}
    
    [self _sendRequest:request target:target selector:sel context:context];
}

- (void)_sendRequest:(NSURLRequest *)aRequest
              target:(id)target
            selector:(SEL)sel
             context:(id)context
{
    NSURL *requestURL = [aRequest URL];
    NSURLConnection *connection = [[[NSURLConnection alloc] initWithRequest:aRequest delegate:self] autorelease];
    if (!connection)
    {
        NSError *error = [NSError errorWithDomain:@"ZKSwitchboardError"
                                             code:1
                                         userInfo:nil];
        [target performSelector:sel withObject:nil withObject:error];
        return;
    }
    
    CFDictionarySetValue(connectionsData, connection, [NSMutableData data]);
    
    NSValue *selector = [NSValue value: &sel withObjCType: @encode(SEL)];
    NSMutableDictionary *targetInfo =
    [NSMutableDictionary dictionaryWithObjectsAndKeys:
     selector, @"selector",
     target, @"target",
     context ? context: [NSNull null], @"context",
     nil];
    
    if (requestURL)
    {
        [targetInfo setObject:requestURL forKey:@"requestURL"];
    }
    
    CFDictionarySetValue(connections, connection, targetInfo);
}

- (void) connection: (NSURLConnection *)connection didReceiveResponse: (NSHTTPURLResponse *)response
{
    NSMutableDictionary * targetInfo = (id)CFDictionaryGetValue(connections, connection);

    if(self.logXMLInOut) {
		NSLog(@"ResponseStatus: %u\n", [response statusCode]);
		NSLog(@"ResponseHeaders:\n%@", [response allHeaderFields]);
	}

    [targetInfo setValue: response forKey: @"response"];
}

- (void) connection: (NSURLConnection *)connection didReceiveData: (NSData *)data
{
    NSMutableData * connectionData = (id)CFDictionaryGetValue(connectionsData, connection);
    [connectionData appendData: data];
}

- (void) connection: (NSURLConnection *)connection didFailWithError: (NSError *)error
{
	if (self.logXMLInOut) {
		NSLog(@"ResponseError:\n%@", error);
	}

    NSMutableDictionary * targetInfo = (id)CFDictionaryGetValue(connections, connection);
    [targetInfo setValue: error forKey: @"error"];
    [self _returnResponseForConnection: connection];
}

- (void) connectionDidFinishLoading: (NSURLConnection *)connection
{
    NSMutableDictionary *targetInfo =
    (id)CFDictionaryGetValue(connections, connection);
    
    // Determine what type of request is being dealt with
    NSURL *requestURL = nil;
    id object = [targetInfo objectForKey:@"requestURL"];
    if (object != nil && [object isKindOfClass:[NSURL class]])
    {
        requestURL = (NSURL *)object;
    }

    
    [self _returnResponseForConnection: connection];
}



- (void) _returnResponseForConnection: (NSURLConnection *)connection {
	NSMutableDictionary * targetInfo = (id)CFDictionaryGetValue(connections, connection);
	
	NSMutableData * data = (id)CFDictionaryGetValue(connectionsData, connection);
	
	if (self.logXMLInOut) {
		NSLog(@"ResponseBody:\n%@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
	}
	
	id target = [targetInfo valueForKey: @"target"];
	SEL selector;
	[[targetInfo valueForKey: @"selector"] getValue: &selector];
    
	NSError *error = nil;
	NSHTTPURLResponse * response = nil;
	id errorObject = [targetInfo valueForKey: @"error"];
	if (errorObject != [NSNull null] && [errorObject isKindOfClass:[NSError class]])
	{
		response = [targetInfo valueForKey: @"response"];
		NSInteger status = [response statusCode];
		if (status != 200) error = [NSError errorWithDomain: @"APIError" code: status userInfo: nil];
	}
    
	ZKElement *responseElement = nil;
	if ([data length] && [error code] != 401) {
		responseElement = [self _processHttpResponse:response data:data];
	}
	
		// In this case, a valid status code is returned meaning that the request was
		// received and processed.  But, the result of the processing may be a SOAP
		// Fault as defined by the service.  So we need to check every call to make sure
		// that a fault wasn't returned, and if one was, to throw the error passing the 
		// fault code and fault string
		// Checking for SOAP Fault here now?
	if ([responseElement childElement:@"faultcode"] != nil) {
		NSDictionary *errorDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:[[responseElement childElement:@"faultcode"] stringValue],@"faultcode", [[responseElement childElement:@"faultstring"] stringValue], @"faultstring", nil];
		error = [NSError errorWithDomain:@"APIError" code:0 userInfo:errorDictionary];
	}
	
	id context = [targetInfo valueForKey:@"context"];
	if ([context isEqual: [NSNull null]])
		context = nil;
	
	[target performSelector:selector withObject:responseElement withObject:error withObject:context];
    
	CFDictionaryRemoveValue(connections, connection);
	CFDictionaryRemoveValue(connectionsData, connection);
}



-(ZKElement *)_processHttpResponse:(NSHTTPURLResponse *)resp data:(NSData *)responseData
{
	ZKElement *root = [ZKParser parseData:responseData];
	if (root == nil)	
		@throw [NSException exceptionWithName:@"Xml error" reason:@"Unable to parse XML returned by server" userInfo:nil];
	if (![[root name] isEqualToString:@"Envelope"])
		@throw [NSException exceptionWithName:@"Xml error" reason:[NSString stringWithFormat:@"response XML not valid SOAP, root element should be Envelope, but was %@", [root name]] userInfo:nil];
	if (![[root namespace] isEqualToString:SOAP_NS])
		@throw [NSException exceptionWithName:@"Xml error" reason:[NSString stringWithFormat:@"response XML not valid SOAP, root namespace should be %@ but was %@", SOAP_NS, [root namespace]] userInfo:nil];
	ZKElement *body = [root childElement:@"Body" ns:SOAP_NS];
	if (500 == resp.statusCode) {
		// I don't believe this will work.  With our API we occaisionally return
		// a 500, but not for operational errors such as bad username/password.  The 
		// body of the response is generally a web page (HTML) not soap
		ZKElement *fault = [body childElement:@"Fault" ns:SOAP_NS];
		if (fault == nil)
			@throw [NSException exceptionWithName:@"Xml error" reason:@"Fault status code returned, but unable to find soap:Fault element" userInfo:nil];
		NSString *fc = [[fault childElement:@"faultcode"] stringValue];
		NSString *fm = [[fault childElement:@"faultstring"] stringValue];
		@throw [ZKSoapException exceptionWithFaultCode:fc faultString:fm];
	} 

	return [[body childElements] objectAtIndex:0];
}

- (NSDictionary *)_contextWrapperDictionaryForTarget:(id)target selector:(SEL)selector context:(id)context
{
    NSValue *selectorValue = [NSValue value: &selector withObjCType: @encode(SEL)];
    return [NSDictionary dictionaryWithObjectsAndKeys:
            selectorValue, @"selector",
            target, @"target",
            context ? context: [NSNull null], @"context",
            nil];
}

- (void)_unwrapContext:(NSDictionary *)wrapperContext andCallSelectorWithResponse:(id)response error:(NSError *)error
{
    SEL selector;
    [[wrapperContext valueForKey: @"selector"] getValue: &selector];
    id target = [wrapperContext valueForKey:@"target"];
    id context = [wrapperContext valueForKey:@"context"];
    if (context == [NSNull null])
        context = nil;
    [target performSelector:selector withObject:response withObject:error withObject: context];
}


#pragma mark Wrappers

- (ZKLoginResult *)_processLoginResponse:(ZKElement *)loginResponseElement error:(NSError *)error context:(NSDictionary *)context
{
    ZKLoginResult *loginResult = nil;
    if (!error)
    {
        ZKElement *result = [[loginResponseElement childElements:@"result"] objectAtIndex:0];
        loginResult = [[[ZKLoginResult alloc] initWithXmlElement:result] autorelease];
        self.apiUrl = [loginResult serverUrl];
        self.sessionId = [loginResult sessionId];
        self.userInfo = [loginResult userInfo];
        // TODO: save to keychain.
        /*if (self.savesUsernameAndPasswordInKeychain)
        {
            
        }*/
    }
    [self _unwrapContext:context andCallSelectorWithResponse:loginResult error:error];
    return loginResult;
}

- (ZKQueryResult *)_processQueryResponse:(ZKElement *)queryResponseElement error:(NSError *)error context:(NSDictionary *)context
{
    ZKQueryResult *result = nil;
    if (!error)
    {
        result = [[[ZKQueryResult alloc] initFromXmlNode:[[queryResponseElement childElements] objectAtIndex:0]] autorelease];
    }
    [self _unwrapContext:context andCallSelectorWithResponse:result error:error];
    return result;
}

- (NSArray *)_processSaveResponse:(ZKElement *)saveResponseElement error:(NSError *)error context:(NSDictionary *)context
{
	NSArray *resultsArr = [saveResponseElement childElements:@"result"];
	NSMutableArray *results = [NSMutableArray arrayWithCapacity:[resultsArr count]];
	
	for (ZKElement *result in resultsArr) {
		ZKSaveResult * saveResult = [[[ZKSaveResult alloc] initWithXmlElement:result] autorelease];
		[results addObject:saveResult];
	}
    [self _unwrapContext:context andCallSelectorWithResponse:results error:error];
    return results;
}

- (NSArray *)_processDeleteResponse:(ZKElement *)saveResponseElement error:(NSError *)error context:(NSDictionary *)context
{
    NSArray *resArr = [saveResponseElement childElements:@"result"];
	NSMutableArray *results = [NSMutableArray arrayWithCapacity:[resArr count]];
	for (ZKElement *saveResultElement in resArr) {
		ZKSaveResult *sr = [[[ZKSaveResult alloc] initWithXmlElement:saveResultElement] autorelease];
		[results addObject:sr];
	} 
    [self _unwrapContext:context andCallSelectorWithResponse:results error:error];
	return results;
}


@end

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


#import "FDCServerSwitchboard+MyWebService.h"


// We put the process method in a private category.  The consumer doesn't need to know about this implementation detail.
// It keeps the main header cleaner.

@interface FDCServerSwitchboard (MyWebServicePrivate)

- (void)_processMakeContactResponse:(ZKElement *)makeContactResponseElement error:(NSError *)error context:(NSDictionary *)context;
- (void)_processNameTestResponse:(ZKElement *)nameTestResponseElement error:(NSError *)error context:(NSDictionary *)context;

@end


@implementation FDCServerSwitchboard (MyWebService)


- (void)apexMyWebServiceMakeContactWithLastName:(NSString *)lastName account:(ZKSObject *)account target:(id)target selector:(SEL)selector context:(id)context
{
    
    // Create an envelope and assign its primaryNamespaceUri to your constant.
    FDCMessageEnvelope *envelope = [FDCMessageEnvelope envelopeWithSessionId:self.sessionId clientId:self.clientId];
    envelope.primaryNamespaceUri = kApexMyWebServiceNamespace;
    
    // Create the SOAP body.  The top level element will be the name of the method.  Each child is a parameter.
    FDCMessageElement *makeContactElement = [FDCMessageElement elementWithName:@"makeContact" value:nil];
    [makeContactElement addChildElement:[FDCMessageElement elementWithName:@"lastName" value:lastName]];
    [makeContactElement addChildElement:[FDCMessageElement elementWithName:@"account" value:account]];
    [envelope addBodyElement:makeContactElement];
    
    // Get the XML representation of that SOAP body
    NSString *xml = [envelope stringRepresentation]; 
    
    // To simplify things we create a wrapper around the target/selector/context trio
    NSDictionary *wrapperContext = [self contextWrapperDictionaryForTarget:target selector:selector context:context];

    // Send out the HTTP call to the right URL.  
    [self sendApexRequestToURL:kApexMyWebServiceLocation
                      withData:xml
                        target:self 
                      selector:@selector(_processMakeContactResponse:error:context:) 
                       context:wrapperContext];
}

- (void)apexMyWebServiceNameTest:(NSString *)name target:(id)target selector:(SEL)selector context:(id)context
{
    FDCMessageEnvelope *envelope = [FDCMessageEnvelope envelopeWithSessionId:self.sessionId clientId:self.clientId];
    envelope.primaryNamespaceUri = kApexMyWebServiceNamespace;
    
    FDCMessageElement *makeContactElement = [FDCMessageElement elementWithName:@"nameTest" value:nil];
    [makeContactElement addChildElement:[FDCMessageElement elementWithName:@"name" value:name]];
    [envelope addBodyElement:makeContactElement];
    
    NSString *xml = [envelope stringRepresentation]; 
    
    NSDictionary *wrapperContext = [self contextWrapperDictionaryForTarget:target selector:selector context:context];
    
    [self sendApexRequestToURL:kApexMyWebServiceLocation
                      withData:xml
                        target:self 
                      selector:@selector(_processNameTestResponse:error:context:) 
                       context:wrapperContext];
}

#pragma mark -
#pragma mark MyWebServicePrivate

- (void)_processMakeContactResponse:(ZKElement *)makeContactResponseElement error:(NSError *)error context:(NSDictionary *)context
{
    // Get the result.  ZKElement can be treated as XML.
    ZKElement *result = [makeContactResponseElement childElement:@"result"];
    NSString *contactId = [result stringValue];
    
    // Call the unwrap method and provide it the final parameter.  It'll take care of unwrapping the original
    // target/selector/context trio and doing the final call.
    [self unwrapContext:context andCallSelectorWithResponse:contactId error:error];
}

- (void)_processNameTestResponse:(ZKElement *)nameTestResponseElement error:(NSError *)error context:(NSDictionary *)context
{
    ZKElement *result = [nameTestResponseElement childElement:@"result"];
    NSString *name = [result stringValue];
    [self unwrapContext:context andCallSelectorWithResponse:name error:error];
}


@end

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


#import "ZKServerSwitchboard+SampleApexWebSvc.h"
#import "ZKSampleAccountInfo.h"
#import "ZKSampleContactInfo.h"

// We put the process method in a private category.  The consumer doesn't need to know about this implementation detail.
// It keeps the main header cleaner.

@interface ZKServerSwitchboard (SampleApexWebSvcPrivate)

- (void)_processSampleCreateAccountResponse:(ZKElement *)createAccountResponseElement error:(NSError *)error context:(NSDictionary *)context;
- (void)_processSampleCreateContactResponse:(ZKElement *)createContactResponseElement error:(NSError *)error context:(NSDictionary *)context;
- (void)_processSampleUpdateAccountsResponse:(ZKElement *)updateAccountsResponseElement error:(NSError *)error context:(NSDictionary *)context;
- (void)_processSampleGetAccountByNameResponse:(ZKElement *)getAccountByNameResponseElement error:(NSError *)error context:(NSDictionary *)context;

@end


@implementation ZKServerSwitchboard (SampleApexWebSvc)

- (void)apexSampleApexWebSvcCreateAccount:(ZKSampleAccountInfo *)accountInfo target:(id)target selector:(SEL)selector context:(id)context
{
    ZKMessageEnvelope *envelope = [ZKMessageEnvelope envelopeWithSessionId:self.sessionId clientId:self.clientId];
    envelope.primaryNamespaceUri = kApexSampleApexWebSvcNamespace;
    
    ZKMessageElement *createAccountElement = [ZKMessageElement elementWithName:@"createAccount" value:nil];
    ZKMessageElement *argumentElement = [accountInfo messageElementWithName:@"info"];
    [createAccountElement addChildElement:argumentElement];
    [envelope addBodyElement:createAccountElement];
    
    NSString *xml = [envelope stringRepresentation]; 
    
    NSDictionary *wrapperContext = [self contextWrapperDictionaryForTarget:target selector:selector context:context];
    
    [self sendApexRequestToURL:kApexSampleApexWebSvcLocation
                      withData:xml
                        target:self 
                      selector:@selector(_processSampleCreateAccountResponse:error:context:) 
                       context:wrapperContext];
}

- (void)apexSampleApexWebSvcCreateContact:(ZKSampleContactInfo *)contactInfo target:(id)target selector:(SEL)selector context:(id)context
{
    ZKMessageEnvelope *envelope = [ZKMessageEnvelope envelopeWithSessionId:self.sessionId clientId:self.clientId];
    envelope.primaryNamespaceUri = kApexSampleApexWebSvcNamespace;
    
    ZKMessageElement *createAccountElement = [ZKMessageElement elementWithName:@"createContact" value:nil];
    ZKMessageElement *argumentElement = [contactInfo messageElementWithName:@"c"];
    [createAccountElement addChildElement:argumentElement];
    [envelope addBodyElement:createAccountElement];
    
    NSString *xml = [envelope stringRepresentation]; 
    
    NSDictionary *wrapperContext = [self contextWrapperDictionaryForTarget:target selector:selector context:context];
    
    [self sendApexRequestToURL:kApexSampleApexWebSvcLocation
                      withData:xml
                        target:self 
                      selector:@selector(_processSampleCreateContactResponse:error:context:) 
                       context:wrapperContext];
}

- (void)apexSampleApexWebSvcUpdateAccounts:(NSArray *)accounts target:(id)target selector:(SEL)selector context:(id)context
{
    ZKMessageEnvelope *envelope = [ZKMessageEnvelope envelopeWithSessionId:self.sessionId clientId:self.clientId];
    envelope.primaryNamespaceUri = kApexSampleApexWebSvcNamespace;
    
    ZKMessageElement *updateAccountsElement = [ZKMessageElement elementWithName:@"updateAccounts" value:nil];
    ZKMessageElement *accts = [ZKMessageElement elementWithName:@"accts" value:accounts];
    [accts setType:ZKMessageElementTypeApex];       // When sending SObjects to an Apex method, you must set this otherwise the server will bark.
    [updateAccountsElement addChildElement:accts];
    [envelope addBodyElement:updateAccountsElement];
    
    NSString *xml = [envelope stringRepresentation]; 
    
    NSDictionary *wrapperContext = [self contextWrapperDictionaryForTarget:target selector:selector context:context];
    
    [self sendApexRequestToURL:kApexSampleApexWebSvcLocation
                      withData:xml
                        target:self 
                      selector:@selector(_processSampleUpdateAccountsResponse:error:context:) 
                       context:wrapperContext];
}

- (void)apexSampleApexWebSvcGetAccountByName:(NSString *)accountName target:(id)target selector:(SEL)selector context:(id)context
{
    ZKMessageEnvelope *envelope = [ZKMessageEnvelope envelopeWithSessionId:self.sessionId clientId:self.clientId];
    envelope.primaryNamespaceUri = kApexSampleApexWebSvcNamespace;
    
    ZKMessageElement *getAccountByNameElement = [ZKMessageElement elementWithName:@"getAccountByName" value:nil];
    [getAccountByNameElement addChildElement:[ZKMessageElement elementWithName:@"acctName" value:accountName]];
    [envelope addBodyElement:getAccountByNameElement];
    
    NSString *xml = [envelope stringRepresentation]; 
    
    NSDictionary *wrapperContext = [self contextWrapperDictionaryForTarget:target selector:selector context:context];
    
    [self sendApexRequestToURL:kApexSampleApexWebSvcLocation
                      withData:xml
                        target:self 
                      selector:@selector(_processSampleGetAccountByNameResponse:error:context:) 
                       context:wrapperContext];
}

#pragma mark -
#pragma mark Private

- (void)_processSampleCreateAccountResponse:(ZKElement *)createAccountResponseElement error:(NSError *)error context:(NSDictionary *)context
{
    ZKSObject *account = nil;
    if (!error)
    {
        account = [[[ZKSObject alloc] initFromXmlNode:[[createAccountResponseElement childElements] objectAtIndex:0]] autorelease];
    }
    [self unwrapContext:context andCallSelectorWithResponse:account error:error];
}

- (void)_processSampleCreateContactResponse:(ZKElement *)createContactResponseElement error:(NSError *)error context:(NSDictionary *)context
{
    ZKSObject *contact = nil;
    if (!error)
    {
        contact = [[[ZKSObject alloc] initFromXmlNode:[[createContactResponseElement childElements] objectAtIndex:0]] autorelease];
    }
    [self unwrapContext:context andCallSelectorWithResponse:contact error:error];
}

- (void)_processSampleUpdateAccountsResponse:(ZKElement *)updateAccountsResponseElement error:(NSError *)error context:(NSDictionary *)context
{
    [self unwrapContext:context andCallSelectorWithResponse:nil error:error];
}

- (void)_processSampleGetAccountByNameResponse:(ZKElement *)getAccountByNameResponseElement error:(NSError *)error context:(NSDictionary *)context
{
    ZKSObject *account = nil;
    if (!error)
    {
        account = [[[ZKSObject alloc] initFromXmlNode:[[getAccountByNameResponseElement childElements] objectAtIndex:0]] autorelease];
    }
    [self unwrapContext:context andCallSelectorWithResponse:account error:error];
}


@end

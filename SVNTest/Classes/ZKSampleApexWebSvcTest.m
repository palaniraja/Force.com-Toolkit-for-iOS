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

#import "ZKSampleApexWebSvcTest.h"
#import "ZKSforce.h"
#import "ZKServerSwitchboard+SampleApexWebSvc.h"
#import "ZKSampleContactInfo.h"
#import "ZKSampleAccountInfo.h"

#define kAccountSampleName @"Sample Account Name"

@implementation ZKSampleApexWebSvcTest

@synthesize createdAccount;

- (void)dealloc
{
    [createdAccount release];
    [super dealloc];
}

- (void)runAllTests
{
    // Run the tests asynchronously, with delays to make them easier to see.
    [self performSelector:@selector(testCreateAccount) withObject:nil afterDelay:0.0];
    [self performSelector:@selector(testCreateContact) withObject:nil afterDelay:2.0];
    [self performSelector:@selector(testUpdateAccounts) withObject:nil afterDelay:4.0];
    [self performSelector:@selector(testGetAccountByName) withObject:nil afterDelay:6.0];
}

- (void)testCreateAccount
{
    NSLog(@"Testing SampleApexWebSvc.createAccount");
    ZKSampleAccountInfo *accountInfo = [[[ZKSampleAccountInfo alloc] init] autorelease];
    accountInfo.accountName = kAccountSampleName;
    accountInfo.accountNumber = [NSNumber numberWithInt:42];
    
    [[ZKServerSwitchboard switchboard] apexSampleApexWebSvcCreateAccount:accountInfo target:self selector:@selector(createAccountResult:error:context:) context:nil];
}

- (void)testCreateContact
{
    NSLog(@"Testing SampleApexWebSvc.createContact");
    if (!self.createdAccount)
    {
        NSLog(@"Bailing on test because createAccount failed.");
        return;
    }
    
    ZKSampleContactInfo *contactInfo = [[[ZKSampleContactInfo alloc] init] autorelease];
    contactInfo.accountId = [self.createdAccount Id];
    contactInfo.lastName = @"Fillion";
    contactInfo.firstName = @"Rick";
    
    [[ZKServerSwitchboard switchboard] apexSampleApexWebSvcCreateContact:contactInfo target:self selector:@selector(createContactResult:error:context:) context:nil];
}

- (void)testUpdateAccounts
{
    NSLog(@"Testing SampleApexWebSvc.updateAccounts");
    if (!self.createdAccount)
    {
        NSLog(@"Bailing on test because createAccount failed.");
        return;
    }
    [[ZKServerSwitchboard switchboard] apexSampleApexWebSvcUpdateAccounts:[NSArray arrayWithObject:self.createdAccount] target:self selector:@selector(updateAccountsResult:error:context:) context:nil];
}

- (void)testGetAccountByName
{
    NSLog(@"Testing SampleApexWebSvc.getAccountByName -- incomplete");
    [[ZKServerSwitchboard switchboard] apexSampleApexWebSvcGetAccountByName:kAccountSampleName target:self selector:@selector(getAccountByNameResult:error:context:) context:nil];
}

#pragma mark -
#pragma mark Results

- (void)createAccountResult:(ZKSObject *)account error:(NSError *)error context:(id)context
{
    if (account && !error)
    {
        NSLog(@"SampleApexWebSvc.createAccount successfully returned: %@", account);
        NSLog(@"Saving returned account for use in subsequent tests.");
        self.createdAccount = account;
    }
    else if (error)
    {
        NSLog(@"Error in SampleApexWebSvc.createAccount: %@", error);
    }
}

- (void)createContactResult:(ZKSObject *)contact error:(NSError *)error context:(id)context
{
    if (contact && !error)
    {
        NSLog(@"SampleApexWebSvc.createContact successfully returned: %@", contact);
    }
    else if (error)
    {
        NSLog(@"Error in SampleApexWebSvc.createContact: %@", error);
    }
}

- (void)updateAccountsResult:(id)result error:(NSError *)error context:(id)context
{
    if (!error)
    {
        NSLog(@"SampleApexWebSvc.updateAccounts successfully returned");
    }
    else if (error)
    {
        NSLog(@"Error in SampleApexWebSvc.updateAccounts: %@", error);
    }
}

- (void)getAccountByNameResult:(ZKSObject *)account error:(NSError *)error context:(id)context
{
    if (account && !error)
    {
        NSLog(@"SampleApexWebSvc.getAccountByName successfully returned: %@", account);
    }
    else if (error)
    {
        NSLog(@"Error in SampleApexWebSvc.getAccountByName: %@", error);
    }
}

@end

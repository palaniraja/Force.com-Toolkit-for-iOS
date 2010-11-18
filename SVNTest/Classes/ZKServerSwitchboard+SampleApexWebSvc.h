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


#import <Foundation/Foundation.h>
#import "ZKSforce.h"

/*
 This category on ZKServerSwitchboard provides an example of how you would interact with Apex classes
 that have been designed in the Salesforce Developer portal.
 
 In this case, the Apex class looks like this:
 global class SampleApexWebSvc {
     global class AccountInfo {
         WebService String AcctName;
         WebService Integer AcctNumber;
     }
     
     global class ContactInfo {
         WebService Id AcctId;
         WebService String lastName;
         WebService String firstName;
     }
     
     WebService static Account createAccount(AccountInfo info) {
         Account acct = new Account();
         acct.Name = info.AcctName;
         acct.AccountNumber = String.valueOf(info.AcctNumber);
         insert acct;
         return acct;
     }
     
     WebService static Contact createContact(ContactInfo c) {
         Contact cont = new Contact(AccountId = c.AcctId,
         lastName = c.lastName,
         firstName = c.firstName);
         insert cont;
         return cont;
     }
     
     WebService static void updateAccounts(List<Account> accts) {
         update accts;
     }
     
     WebService static Account getAccountByName( String acctName) {
         Account a = [select id, name from Account where name = :acctName limit 1];
         return a;
     }
 }
 
 */

// Rename and fill in the Location and Namespace constants based on your WSDL
#define kApexSampleApexWebSvcLocation @"https://na7-api.salesforce.com/services/Soap/class/SampleApexWebSvc"
#define kApexSampleApexWebSvcNamespace @"http://soap.sforce.com/schemas/class/SampleApexWebSvc"


// The classes defined in the webservice can be found in other files.
@class ZKSampleAccountInfo;
@class ZKSampleContactInfo;


// Create a category with a unique name (probably the name of your global class)
@interface ZKServerSwitchboard (SampleApexWebSvc)

// Prefix the method with some unique identifier to avoid collisions with other possible methods
- (void)apexSampleApexWebSvcCreateAccount:(ZKSampleAccountInfo *)accountInfo target:(id)target selector:(SEL)selector context:(id)context;
- (void)apexSampleApexWebSvcCreateContact:(ZKSampleContactInfo *)contactInfo target:(id)target selector:(SEL)selector context:(id)context;
- (void)apexSampleApexWebSvcUpdateAccounts:(NSArray *)accounts target:(id)target selector:(SEL)selector context:(id)context;
- (void)apexSampleApexWebSvcGetAccountByName:(NSString *)accountName target:(id)target selector:(SEL)selector context:(id)context;

@end

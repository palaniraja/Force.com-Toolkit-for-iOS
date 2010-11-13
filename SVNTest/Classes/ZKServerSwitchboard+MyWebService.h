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
 global class MyWebService {
     webService static Id makeContact(String lastName, Account a) {
         Contact c = new Contact(lastName = 'Weissman', AccountId = a.Id);
         insert c;
         return c.id;
     }
     
     webService static String nameTest(String name) {
         return name;
     }
 }
 
 */

// Rename and fill in the Location and Namespace constants based on your WSDL
#define kApexMyWebServiceLocation @"https://na7-api.salesforce.com/services/Soap/class/MyWebService"
#define kApexMyWebServiceNamespace @"http://soap.sforce.com/schemas/class/MyWebService"


// Create a category with a unique name (probably the name of your global class)
@interface ZKServerSwitchboard (MyWebService)

// Prefix the method with some unique identifier to avoid collisions with other possible methods
- (void)apexMyWebServiceMakeContactWithLastName:(NSString *)lastName account:(ZKSObject *)account target:(id)target selector:(SEL)selector context:(id)context;
- (void)apexMyWebServiceNameTest:(NSString *)name target:(id)target selector:(SEL)selector context:(id)context;

@end

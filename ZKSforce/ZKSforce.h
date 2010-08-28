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


// this just imports everything else that's you'll need access to, to make
// it easy to pull in everything you might need. you can use this, or just
// import the bits you care about.

#import "ZKSforceClient.h"
#import "ZKUserInfo.h"
#import "ZKSObject.h"
#import "ZKSoapException.h"
#import "ZKSaveResult.h"
#import "ZKQueryResult.h"
#import "ZKDescribeSObject.h"
#import "ZKDescribeField.h"
#import "ZKServerSwitchboard.h"
#import "ZKServerSwitchboard+Utility.h"
#import "ZKServerSwitchboard+Describe.h"
#import "ZKGetDeletedResult.h"
#import "ZKDeletedObject.h"
#import "ZKEmailMessage.h"
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
#import "ZKSforceClient.h"

@class ZKQueryResult;
@class ZKLoginResult;
@class ZKElement;
@class ZKDescribeSObject;
@class ZKURLConnection;
@class CallBackData;

@interface ZKSforceClient (Private)

- (ZKQueryResult *)queryImpl:(NSString *)value operation:(NSString *)op name:(NSString *)elemName;
//- (void)queryImpl:(NSString *)value operation:(NSString *)op name:(NSString *)elemName withDelegate:(id)delegate;  // Doesn't exist?
- (NSArray *)sobjectsImpl:(NSArray *)objects name:(NSString *)elemName;
- (void)checkSession;
- (ZKLoginResult *)startNewSession;

- (void)startNewSessionAsync:(id)delegate;
- (ZKLoginResult *) parseLogin:(ZKElement *)body withConnection:(ZKURLConnection *)conn;
- (void)saveLoginInKeychain;
- (NSMutableArray *)parseDelete:(ZKElement *)cr withConnection:(ZKURLConnection *)conn;
- (NSArray *)parseDescribeGlobal:(ZKElement *)rr withConnection:(ZKURLConnection *)conn;
- (ZKDescribeSObject *)parseDescribeSObject:(ZKElement *)dr withConnection:(ZKURLConnection *)conn;
- (NSDictionary *)parseRetrieve:(ZKElement *)rr withConnection:(ZKURLConnection *)conn;
- (NSArray *)parseSaveResults:(ZKElement *)cr withConnection:(ZKURLConnection *)conn;
- (NSArray *) parseSearch:(ZKElement *)sr withConnection:(ZKURLConnection *)conn;
- (NSString *)parseServerTimeStamp:(ZKElement *)res withConnection:(ZKURLConnection *)conn;
- (void)prepareQueryResult:(ZKElement *)queryResult withConnection:(ZKURLConnection *)conn;

@end

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


#import "ZKBaseClient.h"
#import "KeychainItemWrapper.h"

@class ZKUserInfo;
@class ZKDescribeSObject;
@class ZKQueryResult;
@class ZKLoginResult; 
@class ZKSaveResult;
@class ZKDescribeGlobalSObject;
@class CallBackData;
@class ZKDescribeLayoutResult;

@protocol ForceClientDelegate<NSObject>
@optional
-(void)queryReady:(ZKQueryResult *)	results;
-(void)loginSucceeded:(ZKLoginResult *)results;
-(void)globalDescribesReady:(NSArray *)results;
-(void)describeSObjectReady:(ZKDescribeSObject *)results;
-(void)searchResultsReady:(NSArray *)results;
-(void)retrieveResultsReady:(NSDictionary *)results;
-(void)saveResultsReady:(NSArray *)results;
-(void)deleteResultsReady:(NSMutableArray *)results;
-(void)serverTimestampReady:(NSString *)results;
-(void)describeLayoutResultsReady:(ZKDescribeLayoutResult *)results;
-(void)receivedErrorFromAPICall:(NSString *)results;
@end

@interface ZKSforceClient : ZKBaseClient <NSCopying> {
	NSString	*authEndpointUrl;
	NSString	*username;
	NSString	*password;
	NSString	*clientId;	
	NSString	*sessionId;
	NSDate		*sessionExpiresAt;
	BOOL		updateMru;
	ZKUserInfo	*userInfo;
	BOOL		cacheDescribes;
	NSMutableDictionary	*describes;
	int			preferedApiVersion;
	
	KeychainItemWrapper *passwordItem;
	KeychainItemWrapper *usernameItem;
	BOOL useKeyChain;
}

@property (nonatomic, retain) KeychainItemWrapper *passwordItem;
@property (nonatomic, retain) KeychainItemWrapper *usernameItem;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;
@property (nonatomic) BOOL useKeyChain;

// delegated methods
//- (void)parseLogin:(ZKElement *)body withCallBackData:(CallBackData *)cbd;

// configuration
- (void)setLoginProtocolAndHost:(NSString *)protocolAndHost;
- (void)setLoginProtocolAndHost:(NSString *)protocolAndHost andVersion:(int)version;
- (NSURL *)authEndpointUrl;

// all map directly to Sforce API calls
- (ZKLoginResult *)login:(NSString *)username password:(NSString *)password;
- (NSArray *)describeGlobal;
- (ZKDescribeSObject *)describeSObject:(NSString *)sobjectName;
- (ZKDescribeLayoutResult *)describeLayout:(NSString *)sobjectName;
- (NSArray *)search:(NSString *)sosl;
- (ZKQueryResult *)query:(NSString *)soql;
//- (ZKQueryResult *)query:(NSString *)soql withContext:(id)context;
- (ZKQueryResult *)queryAll:(NSString *)soql;
- (ZKQueryResult *)queryMore:(NSString *)queryLocator;
- (NSDictionary *)retrieve:(NSString *)fields sobject:(NSString *)sobjectType ids:(NSArray *)ids;
- (NSArray *)create:(NSArray *)objects;
- (NSArray *)update:(NSArray *)objects;
- (NSArray *)delete:(NSArray *)ids;
- (NSString *)serverTimestamp;
- (void)setPassword:(NSString *)newPassword forUserId:(NSString *)userId;

// Async Calls
-(void) loginAsync:(NSString *)un password:(NSString *)pwd withDelegate:(id)delegate;

- (void)describeGlobalAsync:(id)delegate;

- (void)describeSObjectAsync:(NSString *)sobjectName withDelegate:(id)delegate;

//- (void)describeLayout:(NSString *)sobjectName withDelegate:(id)delegate withSelector:(NSString *)selector withErrorDelegate:(id)errorDelegate withErrorSelector:(NSString *)errorSelector;

- (void)searchAsync:(NSString *)sosl withDelegate:(id)delegate;

- (void)queryAsync:(NSString *)soql withDelegate:(id)delegate;

- (void)queryAllAsync:(NSString *)soql withDelegate:(id)delegate;

- (void)queryMoreAsync:(NSString *)queryLocator withDelegate:(id)delegate;;

- (void)retrieveAsync:(NSString *)fields sobject:(NSString *)sobjectType ids:(NSArray *)ids withDelegate:(id)delegate;

- (void)createAsync:(NSArray *)objects withDelegate:(id)delegate;

- (void)updateAsync:(NSArray *)objects withDelegate:(id)delegate;

- (void)deleteAsync:(NSArray *)ids withDelegate:(id)delegate;

- (void)serverTimestampAsync:(id)delegate;

- (void)setPasswordAsync:(NSString *)newPassword forUserId:(NSString *)userId withDelegate:(id)delegate;

- (void)queryImplAsync:(NSString *)value operation:(NSString *)operation name:(NSString *)elemName withDelegate:(id)delegate;

- (void)sobjectsImplAsync:(NSArray *)objects name:(NSString *)elemName withDelegate:(id)delegate;

- (void)describeLayoutAsync:(NSString *)sobjectName withDelegate:(id)delegate;

// status info
- (BOOL)loggedIn;
- (ZKUserInfo *)currentUserInfo;
- (NSString *)serverUrl;
- (NSString *)sessionId;

// headers
- (BOOL)updateMru;
- (void)setUpdateMru:(BOOL)aValue;
- (NSString *)clientId;
- (void)setClientId:(NSString *)aClientId;


// describe caching
- (BOOL)cacheDescribes;
- (void)setCacheDescribes:(BOOL)newCacheDescribes;
- (void)flushCachedDescribes;


@end


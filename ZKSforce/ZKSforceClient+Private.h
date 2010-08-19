//
//  ZKSforceClient+Private.h
//  SVNTest
//
//  Created by Rick Fillion on 8/18/10.
//  Copyright 2010 Centrix.ca. All rights reserved.
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

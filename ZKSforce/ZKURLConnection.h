//
//  ZKURLConnection.h
//  SplitForce
//
//  Created by Dave Carroll on 8/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//



@interface ZKURLConnection : NSURLConnection {
	id responseDelegate;
	NSString * responseSelector;
	NSString *operationName;
	NSString *layoutObjectName;
	id clientDelegate;
	NSMutableData *receivedData;
}
@property (retain, nonatomic) id responseDelegate;
@property (retain, nonatomic) NSString * responseSelector;
@property (retain, nonatomic) NSString *operationName;
@property (retain, nonatomic) NSString *layoutObjectName;
@property (retain, nonatomic) id clientDelegate;
@property (retain, nonatomic) NSMutableData *receivedData;

-(id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate 
withResponseDelegate:(id)responseDelegate 
withResponseSelector:(NSString *)responseSelector
  withClientDelegate:(id)clientDelegate 
withLayoutObjectName:(NSString *)layoutObjectName 
   withOperationName:(NSString *)operationName;
@end

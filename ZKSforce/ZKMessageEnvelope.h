//
//  ZKMessageEnvelope.h
//  SVNTest
//
//  Created by Rick Fillion on 8/30/10.
//  Copyright 2010 Centrix.ca. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZKMessageElement;

@interface ZKMessageEnvelope : NSObject {
    NSString *primaryNamespaceUri;
    NSMutableArray *headerElements;
    NSMutableArray *bodyElements;
}

@property (nonatomic, copy) NSString *primaryNamespaceUri;
@property (nonatomic, readonly) NSArray *headerElements;
@property (nonatomic, readonly) NSArray *bodyElements;

+ (ZKMessageEnvelope *)envelopeWithSessionId:(NSString *)sessionId clientId:(NSString *)clientId;

- (void)addHeaderElement:(ZKMessageElement *)element;
- (void)addBodyElement:(ZKMessageElement *)element;
- (void)addBodyElementNamed:(NSString *)elementName withChildNamed:(NSString *)childElementName value:(id)childValue;

- (void)addUpdatesMostRecentlyUsedHeader;

- (NSString *)stringRepresentation;

@end

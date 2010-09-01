//
//  ZKMessageElement.h
//  SVNTest
//
//  Created by Rick Fillion on 8/30/10.
//  Copyright 2010 Centrix.ca. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ZKMessageElement : NSObject {
    NSString *name;
    id value;
    NSMutableDictionary *attributes;
    NSMutableArray *childElements;
}

@property (nonatomic, copy) NSString *name;
@property (nonatomic, retain) id value;
@property (nonatomic, readonly) NSArray *childElements;

+ (ZKMessageElement *)elementWithName:(NSString *)aName value:(id)aValue;

- (id)initWithName:(NSString *)aName value:(id)aValue;

- (void)addAttribute:(NSString *)attributeName value:(NSString *)aValue;
- (void)addChildElement:(ZKMessageElement *)element;

- (NSString *)stringRepresentation;

@end

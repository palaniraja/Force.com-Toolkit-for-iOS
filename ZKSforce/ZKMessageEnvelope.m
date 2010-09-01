//
//  ZKMessageEnvelope.m
//  SVNTest
//
//  Created by Rick Fillion on 8/30/10.
//  Copyright 2010 Centrix.ca. All rights reserved.
//

#import "ZKMessageEnvelope.h"
#import "ZKMessageElement.h"

#define DEFAULT_NAMESPACE_URI @"urn:partner.soap.sforce.com"

@implementation ZKMessageEnvelope

@synthesize primaryNamespaceUri;

+ (ZKMessageEnvelope *)envelopeWithSessionId:(NSString *)sessionId clientId:(NSString *)clientId;
{
    ZKMessageEnvelope *envelope = [[[ZKMessageEnvelope alloc] init] autorelease];
    if (sessionId)
    {
        ZKMessageElement *sessionHeaderElement = [ZKMessageElement elementWithName:@"SessionHeader" value:nil];
        [sessionHeaderElement addChildElement:[ZKMessageElement elementWithName:@"sessionId" value:sessionId]];
        [envelope addHeaderElement:sessionHeaderElement];
    }
    if (clientId)
    {
        ZKMessageElement *sessionHeaderElement = [ZKMessageElement elementWithName:@"CallOptions" value:nil];
        [sessionHeaderElement addChildElement:[ZKMessageElement elementWithName:@"client" value:clientId]];
        [envelope addHeaderElement:sessionHeaderElement];
    }
         
    return envelope;
}

- (id)initWithPrimaryNamespaceUri:(NSString *)uri
{
    if (self = [self init])
    {
        self.primaryNamespaceUri = uri;
    }
    return self;
}

- (id)init
{
    if (self = [super init])
    {
        headerElements = [[NSMutableArray array] retain];
        bodyElements = [[NSMutableArray array] retain];
        self.primaryNamespaceUri = DEFAULT_NAMESPACE_URI;
    }
    return self;
}

- (void)dealloc
{
    [headerElements release];
    [bodyElements release];
    [super dealloc];
}

#pragma mark Properties

- (NSArray *)headerElements
{
    return [NSArray arrayWithArray:headerElements];
}

- (NSArray *)bodyElements
{
    return [NSArray arrayWithArray:bodyElements];
}

#pragma mark  Methods

- (void)addHeaderElement:(ZKMessageElement *)element
{
    [headerElements addObject:element];
}

- (void)addBodyElement:(ZKMessageElement *)element
{
    [bodyElements addObject:element];
}

- (void)addBodyElementNamed:(NSString *)elementName withChildNamed:(NSString *)childElementName value:(id)childValue
{
    ZKMessageElement *childElement = [ZKMessageElement elementWithName:childElementName value:childValue];
    ZKMessageElement *bodyElement = [ZKMessageElement elementWithName:elementName value:nil];
    [bodyElement addChildElement:childElement];
    [self addBodyElement:bodyElement];
}

- (void)addUpdatesMostRecentlyUsedHeader
{
    ZKMessageElement *sessionMruHeaderElement = [ZKMessageElement elementWithName:@"MruHeader" value:nil];
    [sessionMruHeaderElement addChildElement:[ZKMessageElement elementWithName:@"updateMru" value:@"true"]];
    [self addHeaderElement:sessionMruHeaderElement];
}

- (NSString *)stringRepresentation
{
    NSMutableString *finalString = [NSMutableString stringWithCapacity:100];
    [finalString appendFormat:@"<s:Envelope xmlns:s='http://schemas.xmlsoap.org/soap/envelope/' xmlns='%@'>\n", self.primaryNamespaceUri];
    
    // Let's get the headers in here.
    [finalString appendFormat:@"\t<s:Header>\n"];
    for (ZKMessageElement *element in headerElements)
    {
        [finalString appendFormat:@"\t%@\n", [element stringRepresentation]];
    }
    [finalString appendFormat:@"\t</s:Header>\n"];
    
    // Time for some body action.
    [finalString appendFormat:@"\t<s:Body>\n"];
    for (ZKMessageElement *element in bodyElements)
    {
        [finalString appendFormat:@"\t%@\n", [element stringRepresentation]];
    }
    [finalString appendFormat:@"\t</s:Body>\n"];
    
    [finalString appendFormat:@"</s:Envelope>\n"];
    
    return finalString;
}




@end

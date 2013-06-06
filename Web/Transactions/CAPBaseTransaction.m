//
//  CAPBaseTransaction.m
//  Bussiajad
//
//  Created by tõnis on 3/19/13.
//  Copyright (c) 2013 Cannedapps. All rights reserved.
//

#import "CAPBaseTransaction.h"

@implementation CAPBaseTransaction

- (NSURL *)url
{
    return nil;
}

- (id)responseDataForFinishedConnectionWithResponse:(NSHTTPURLResponse *)response data:(NSData *)data
{
    return nil;
}

- (void)addPayload:(id)payLoad
{
    
}

- (void)addHeadersToHeaders:(NSDictionary *)headers
{

}

- (NSString *)body
{
    return nil;
}

- (NSString *)method
{
    return @"GET";
}

@end

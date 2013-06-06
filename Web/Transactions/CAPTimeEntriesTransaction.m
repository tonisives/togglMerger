//
//  CAPAuthTransaction.m
//  toggl
//
//  Created by tõnis on 5/29/13.
//  Copyright (c) 2013 Cannedapps. All rights reserved.
//

#import "CAPTimeEntriesTransaction.h"
#import "NSString+Additions.h"

NSString *const timeEntriesURL = @"time_entries?start_date=%@&end_date=%@";

@interface CAPTimeEntriesTransaction() {
    NSDictionary *_payLoad;
}

@end

@implementation CAPTimeEntriesTransaction

- (void)addPayload:(id)payLoad
{
    _payLoad = payLoad;
}

- (NSURL *)url
{
    NSString *url = [NSString stringWithFormat:timeEntriesURL, _payLoad[@"start"] , _payLoad[@"end"]];
    return [NSURL URLWithString:url relativeToURL:baseURI];
}

- (void)addHeadersToHeaders:(NSDictionary *)headers
{
    NSData *data = nil;
    NSString *authorization = nil;
    NSString *authorizationEncoded = nil;
    
    authorization = [NSString stringWithFormat:@"%@:%@", _payLoad[@"user"], _payLoad[@"pass"]];
    data = [authorization dataUsingEncoding:NSUTF8StringEncoding];
    authorizationEncoded = [NSString stringWithFormat:@"Basic %@", [NSString base64ForData:data]];
    
    [headers setValue:@"application/json" forKey:@"Content-type"];
    [headers setValue:authorizationEncoded forKey:@"Authorization"];
}

@end

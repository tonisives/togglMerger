//
//  CAPWebService.m
//  Bussiajad
//
//  Created by tõnis on 3/19/13.
//  Copyright (c) 2013 Cannedapps. All rights reserved.
//

#import "CAPWebServiceRequest.h"

const BOOL kLoggingEnabled = NO;

@interface CAPWebService () {
    NSMutableArray *_requests;
}

@end

@implementation CAPWebService

+ (CAPWebService *)sharedWebService
{
    __strong static CAPWebService *sharedWebService = nil;
    static dispatch_once_t loaded = 0;
    
    dispatch_once(&loaded, ^{
        sharedWebService = [[self alloc] init];
    });
    
    return sharedWebService;
}

- (id)init
{
    self = [super init];
    
    if (self) {
        [CAPWebServiceRequest setManager:self];
        _requests = [NSMutableArray array];
    }
    
    return self;
}

- (void)makeRequestForTarget:(id)target
                 requestType:(CAPRequestType)requestType
                 withPayLoad:(id)payLoad
                  usingBlock:(CAPWebServiceBlock)block
{
    CAPWebServiceRequest *request = [[CAPWebServiceRequest alloc] initForRequestType:requestType payLoad:payLoad target:target usingBlock:block];
    [self startRequest:request];
}

#pragma mark -

- (void)startRequest:(CAPWebServiceRequest *)request
{
    [_requests addObject:request];
    [request start];
}

- (void)requestComplete:(CAPWebServiceRequest *)request
{
    [_requests removeObjectIdenticalTo:request];
}

- (void)cancelRequestsForTarget:(id)target
{
    NSMutableSet *requestsToRemove = nil;
    
    for (CAPWebServiceRequest *request in _requests) {
        if (request.target == target) {
            if (!requestsToRemove) {
                requestsToRemove = [NSMutableSet set];
            }
            [requestsToRemove addObject:request];
        }
    }
    
    for (CAPWebServiceRequest *request in requestsToRemove) {
        [request stop];
        [_requests removeObjectIdenticalTo:request];
    }
}

- (void)cancelAllRequests
{
    for (CAPWebServiceRequest *request in _requests) {
        [request stop];
    }
    
    [_requests removeAllObjects];
}

- (void)dealloc
{
    [self cancelAllRequests];
}

@end

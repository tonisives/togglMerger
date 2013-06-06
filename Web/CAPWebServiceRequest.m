//
//  CAPWebServiceRequest.m
//  Bussiajad
//
//  Created by tõnis on 3/19/13.
//  Copyright (c) 2013 Cannedapps. All rights reserved.
//

#import "CAPWebServiceRequest.h"
#import "CAPTimeEntriesTransaction.h"
#import "CAPProjectTransaction.h"
#import "CAPUtils.h"

static __unsafe_unretained id _manager;

@interface CAPWebServiceRequest () <NSURLConnectionDelegate> {
    BOOL _cancelled;
    NSURLConnection *_connection;
    NSString *_method;
    NSString *_body;
    
    NSMutableData *_data;
    NSMutableDictionary *_headers;
    NSHTTPURLResponse *_response;
    
    NSURL *_url;
    NSURL *_secureUrl;
    
    id <CAPWebServiceTransaction> _transaction;
}

@end

@implementation CAPWebServiceRequest

- (id)initForRequestType:(CAPRequestType)requestType
                 payLoad:(id)payload
                  target:(id)target
              usingBlock:(CAPWebServiceBlock)block
{
    self = [super init];
    
    if (self) {
        _block = block;
        _target = target;
        _headers = [NSMutableDictionary dictionary];
        
        _transaction = [self transactionForRequestType:requestType];
        
        [_transaction addPayload:payload]; //first set request payload for use in query/body
        _url = [_transaction url];
        [_transaction addHeadersToHeaders:_headers];
    }
    
    return self;
}

+ (void)setManager:(id)manager
{
    _manager = manager;
}

- (void)start
{
    if (!_connection) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            if (![CAPUtils isConnectionAvailable]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSError *error = [NSError errorWithDomain:@"noCOnn" code:0 userInfo:@{}]; //TODO: return better error
                    [self connection:_connection didFailWithError:error];
                    return;
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_url];
                    [request setHTTPMethod:[_transaction method]];
                    
                    NSString *body = [_transaction body];
                    if (body) {
                        [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
                    }
                    
                    if (_headers) {
                        for (NSString *key in _headers.allKeys) {
                            [request setValue:[_headers valueForKey:key] forHTTPHeaderField:key];
                        }
                    }
                    
                    if (kLoggingEnabled) {
                        NSLog(@"\nURL: %@\nheader: %@\nbody: %@", _url.absoluteString, _headers, _body);
                    }
                    
                    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
                    
                });
            }
        });
    }
}

- (void)stop
{
    _cancelled = YES;
    
    if (_connection) {
        [_connection cancel];
        _connection = nil;
        _data = nil;
    }
}

- (void)dealloc
{
    if (_block) {
        Block_release((__bridge void *)_block);
        _block = NULL;
    }
}

#pragma mark - Private methods

- (id <CAPWebServiceTransaction>)transactionForRequestType:(CAPRequestType)requestType
{
    id <CAPWebServiceTransaction> transaction;
    
    switch (requestType) {
        case kCAPRequestTypeTimeEntries:
            transaction = [[CAPTimeEntriesTransaction alloc] init];
            break;
        case kCAPRequestTypeProjectDetails:
            transaction = [[CAPProjectTransaction alloc] init];
            break;
        default:
            break;
    }
    
    return transaction;
}

#pragma mark NSURLConnectionDelegate

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (kLoggingEnabled) {
            NSLog(@"\n%@ : %ld\n%@\n", [_transaction url].absoluteString, _response.statusCode, [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding]);
        }
        
        id responseData;
        
        if (_response.statusCode == 200) {
            responseData = [NSJSONSerialization JSONObjectWithData:_data options:0 error:nil];
        }
        else {
            responseData = [[NSError alloc] initWithDomain:@"wrong data" code:1 userInfo:nil];
        }
        
        _connection = nil;
        _data = nil;
        
        dispatch_async (dispatch_get_main_queue (), ^{
            if (!_cancelled) {
                if (![responseData isKindOfClass:[NSError class]]) {
                    _block(responseData, nil);
                }
                else {
                    _block(nil, responseData);
                }
                
                if ([_manager respondsToSelector:@selector(requestComplete:)]) {
                    [_manager performSelector:@selector(requestComplete:) withObject:self];
                }
            }
        });
    });
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    _response  = (NSHTTPURLResponse *) response;
    _data.length = 0;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (!_data) {
        _data = [NSMutableData data];
    }
    
    [_data appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    _connection = nil;
    _data = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _block(nil, error);
        
        if (_cancelled) {
            [_manager performSelector:@selector(requestComplete:) withObject:self];
        }
        else {
            [_connection cancel];
            [_manager performSelector:@selector(requestComplete:) withObject:self];
        }
    });
}


@end

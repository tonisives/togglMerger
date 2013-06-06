//
//  CAPWebServiceRequest.h
//  Bussiajad
//
//  Created by tõnis on 3/19/13.
//  Copyright (c) 2013 Cannedapps. All rights reserved.
//

#import "CAPWebService.h"

@protocol CAPWebServiceTransaction

@optional
/**
 return the requests full URL
 */
- (NSURL *)url;
/**
 this method should return either error or parsed data ready for block invocation
 */
- (id)responseDataForFinishedConnectionWithResponse:(NSHTTPURLResponse *)response data:(NSData *)data;
/**
 add payload to transaction, for later use in query/body parameters
 */
- (void)addPayload:(id)payLoad;
/**
 add headers for the already available headers dictionary
 */
- (void)addHeadersToHeaders:(NSDictionary *)headers;
/**
 return the body of the post request
 */
- (NSString *)body;
/**
 return request method GET/POST
 */
- (NSString *)method;

@end

@interface CAPWebServiceRequest : NSObject

- (id)initForRequestType:(CAPRequestType)requestType
                 payLoad:(id)payload
                  target:(id)target
              usingBlock:(CAPWebServiceBlock)block;

+ (void)setManager:(id)manager;

- (void)start;
- (void)stop;

@property (nonatomic, strong) id target;
@property (nonatomic, readonly) CAPWebServiceBlock block;

@end

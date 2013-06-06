//
//  CAPWebService.h
//  Bussiajad
//
//  Created by tõnis on 3/19/13.
//  Copyright (c) 2013 Cannedapps. All rights reserved.
//

extern const BOOL kLoggingEnabled;

typedef NS_ENUM(NSInteger, CAPRequestType) {
    kCAPRequestTypeNone = 0,
    kCAPRequestTypeTimeEntries,
    kCAPRequestTypeProjectDetails
};

typedef void (^CAPWebServiceBlock) (id responseData, NSError *error);

@interface CAPWebService : NSObject

+ (CAPWebService *)sharedWebService;

- (void)makeRequestForTarget:(id)target
                 requestType:(CAPRequestType)requestType
                 withPayLoad:(id)payLoad
                  usingBlock:(CAPWebServiceBlock)block;

- (void)cancelRequestsForTarget:(id)target;
- (void)cancelAllRequests;

@end

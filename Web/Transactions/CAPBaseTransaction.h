//
//  CAPBaseTransaction.h
//  Bussiajad
//
//  Created by tõnis on 3/19/13.
//  Copyright (c) 2013 Cannedapps. All rights reserved.
//

#import "CAPWebServiceRequest.h"

#define baseURI             [NSURL URLWithString:@"https://www.toggl.com/api/v8/"]

@interface CAPBaseTransaction : NSObject <CAPWebServiceTransaction>

@end

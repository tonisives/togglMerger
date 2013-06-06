//
//  CAUtils.m
//  Bussiajad
//
//  Created by Tõnis Tiganik on 10/9/12.
//
//

#import "CAPUtils.h"
#import <SystemConfiguration/SystemConfiguration.h>

@implementation CAPUtils


+ (BOOL)isConnectionAvailable
{
	SCNetworkReachabilityFlags flags;
    BOOL receivedFlags;
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(CFAllocatorGetDefault(), [@"dipinkrishna.com" UTF8String]);
    receivedFlags = SCNetworkReachabilityGetFlags(reachability, &flags);
    CFRelease(reachability);
    
    if (!receivedFlags || (flags == 0) ) {
        return FALSE;
    } else {
		return TRUE;
	}
}

@end

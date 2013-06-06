//
//  NSString+WC_Additions.h
//  Wireless Car
//
//  Created by Mikk Rätsep on 5/30/12.
//  Copyright (c) 2012 Cannedapps. All rights reserved.
//

@interface NSString (Additions)

+ (NSString *)base64ForData:(NSData *)theData;

- (NSString *)stringFromMD5;
- (NSString *)urlEncode;

@end

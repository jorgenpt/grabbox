//
//  NSData+Base64.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 11/21/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSData (Base64)

+ (NSData *) dataWithBase64EncodedString:(NSString *)string;
- (id) initWithBase64EncodedString:(NSString *)string;

- (NSString *) base64Encoding;
- (NSString *) base64EncodingWithLineLength:(NSUInteger) lineLength;

@end
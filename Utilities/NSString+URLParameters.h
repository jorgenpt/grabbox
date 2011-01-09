//
//  NSString+URLParameters.h
//  PublishBox
//
//  Created by Jørgen P. Tjernø on 12/6/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSString (URLParameters)

+ (id) stringWithKey:(NSString *)key
               value:(NSString *)value;

@end
//
//  NSString+URLParameters.m
//  PublishBox
//
//  Created by Jørgen P. Tjernø on 12/6/10.
//  Copyright (C) 2014 Jørgen P. Tjernø. Licensed under GPLv2, see LICENSE in the project root for more info.
//

#import "NSString+URLParameters.h"


@implementation NSString (URLParameters)

- (NSString *) stringByAddingPercentEscapesAndEscapeCharactersInString:(NSString *)escape
{
    NSString *result = NSMakeCollectable(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                 (CFStringRef)self,
                                                                                 NULL,
                                                                                 (CFStringRef)escape,
                                                                                 kCFStringEncodingUTF8));
    return [result autorelease];
}

- (NSString *) stringByAddingPercentEscapesForQuery
{
    return [self stringByAddingPercentEscapesAndEscapeCharactersInString:@":/?#[]@!$&’()*+,;="];
}

+ (id) stringWithKey:(NSString *)key
               value:(NSString *)value
{
    key = [key stringByAddingPercentEscapesForQuery];
    value = [value stringByAddingPercentEscapesForQuery];
    return [NSString stringWithFormat:@"%@=%@", key, value];
}

@end

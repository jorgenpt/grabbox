//
//  NSString+URLParameters.m
//  PublishBox
//
//  Created by Jørgen P. Tjernø on 12/6/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "NSString+URLParameters.h"


@implementation NSString (URLParameters)

- (NSString *) stringByAddingPercentEscapesAndEscapeCharactersInString:(NSString *)escape
{
    NSString *result = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                             (CFStringRef)self,
                                                                                             NULL,
                                                                                             (CFStringRef)escape,
                                                                                             kCFStringEncodingUTF8);
    return result;
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

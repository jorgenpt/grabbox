//
//  NSString+URLParameters.m
//  PublishBox
//
//  Created by Jørgen P. Tjernø on 12/6/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "NSString+URLParameters.h"


@implementation NSString (URLParameters)

+ (id) stringWithKey:(NSString *)key
               value:(NSString *)value
{
    key = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    value = [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [NSString stringWithFormat:@"%@=%@", key, value];
}

@end
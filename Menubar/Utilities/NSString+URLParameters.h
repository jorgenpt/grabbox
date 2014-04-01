//
//  NSString+URLParameters.h
//  PublishBox
//
//  Created by Jørgen P. Tjernø on 12/6/10.
//  Copyright (C) 2014 Jørgen P. Tjernø. Licensed under GPLv2, see LICENSE in the project root for more info.
//

#import <Cocoa/Cocoa.h>

@interface NSString (URLParameters)

- (NSString *) stringByAddingPercentEscapesAndEscapeCharactersInString:(NSString *)escape;
- (NSString *) stringByAddingPercentEscapesForQuery;

+ (id) stringWithKey:(NSString *)key
               value:(NSString *)value;

@end

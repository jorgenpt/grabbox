//
//  URLShortener.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 10/1/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
    SHORTENER_NONE = 0,
    SHORTENER_BITLY = 2,
    SHORTENER_GOOGL = 3,
    SHORTENER_ISGD = 4,
} Shortener;

@interface URLShortener : NSObject

+ (NSString *) urlForPath:(NSString *)path;

@end

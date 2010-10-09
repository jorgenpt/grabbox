//
//  URLShortener.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 10/1/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface URLShortener : NSObject

+ (NSString*) shortenURLForFile:(NSString*)file;

@end

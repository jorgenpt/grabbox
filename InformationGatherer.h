//
//  InformationGatherer.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/10/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface InformationGatherer : NSObject {
    NSString* screenshotPath;
    NSString* uploadPath;
    NSString* publicPath;
    NSString* localizedScreenshotPattern;
    SInt32 osVersion;
    NSSet* dirContents;
}

+ (id) defaultGatherer;

- (id) init;
- (id) copyWithZone:(NSZone *)zone;
- (id) retain;
- (NSUInteger) retainCount;
- (void) release;
- (id) autorelease;

- (NSString *)screenshotPath;
- (NSString *)publicPath;
- (NSString *)uploadPath;
- (NSString *)localizedScreenshotPattern;
- (NSSet *)createdFiles;
- (NSSet *)files;

+ (NSDictionary *)getStringsTable:(NSString *)table
                       fromBundle:(NSBundle *)bundle
                  forLocalization:(NSString *)localization;

@end

//
//  InformationGatherer.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/10/10.
//  Copyright (C) 2014 Jørgen P. Tjernø. Licensed under GPLv2, see LICENSE in the project root for more info.
//

#import <Cocoa/Cocoa.h>

@interface InformationGatherer : NSObject {
    NSString* screenshotPath;
    NSString* localizedScreenshotPattern;
    NSString* workQueuePath;
    SInt32 osVersion;
    NSSet* dirContents;
}

+ (id) defaultGatherer;

- (NSString *)screenshotPath;
- (NSString *)localizedScreenshotPattern;
- (NSString *)workQueuePath;
- (NSSet *)createdFiles;
- (NSSet *)filesInDirectory:(NSString *)path;
- (NSSet *)files;

@end

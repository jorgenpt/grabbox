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
    NSString* localizedScreenshotPattern;
    NSString* workQueuePath;
    BOOL isSnowLeopardOrNewer;
    NSSet* dirContents;
}

+ (id) defaultGatherer;

- (NSString *)screenshotPath;
- (NSString *)localizedScreenshotPattern;
- (NSString *)workQueuePath;
- (NSSet *)createdFiles;
- (NSSet *)files;
- (BOOL)isSnowLeopardOrNewer;

@end

//
//  UploadInitiator.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlerDelegate.h"
#import "DropboxDetector.h"

#define MAX_NAME_LENGTH 32

@interface UploadInitiator : NSObject <GrowlerDelegate, DropboxDetectorDelegate> {
    NSString *srcFile;
    NSString *srcPath;
    NSString *destPath;
    NSMutableArray *detectors;
    int dropboxId;
}

@property (nonatomic, retain) NSString* srcFile;
@property (nonatomic, retain) NSString* srcPath;
@property (nonatomic, retain) NSString* destPath;
@property (nonatomic, retain) NSMutableArray* detectors;
@property int dropboxId;

+ (id) uploadFile:(NSString *)file
           atPath:(NSString *)source
           toPath:(NSString *)destination
           withId:(int)dropId;
+ (void) copyURL:(NSString *)url basedOnFile:(NSString *)path;

- (id) initForFile:(NSString *)file
            atPath:(NSString *)source
            toPath:(NSString *)destination
            withId:(int)dropId;
- (void) dealloc;

- (void) assertDropboxRunningAndUpload;
- (void) upload;
- (void) growlClickedWithData:(id)data;
- (void) growlTimedOutWithData:(id)data;
- (NSString *) getNextFilenameWithExtension:(NSString *)ext;
- (void) dropboxIsRunning:(BOOL)running
             fromDetector:(DropboxDetector *)detector;
@end

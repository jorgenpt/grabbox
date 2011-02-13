//
//  UploadInitiator.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlerDelegate.h"

#define MAX_NAME_LENGTH 32

@interface UploadInitiator : NSObject {
    NSString *srcFile;
    NSString *srcPath;
    NSString *destPath;
    NSMutableArray *detectors;
}

@property (nonatomic, retain) NSString* srcFile;
@property (nonatomic, retain) NSString* srcPath;
@property (nonatomic, retain) NSString* destPath;
@property (nonatomic, retain) NSMutableArray* detectors;

+ (id) uploadFile:(NSString *)file
           atPath:(NSString *)source
           toPath:(NSString *)destination;
+ (void) copyURL:(NSString *)url
     basedOnFile:(NSString *)path
      wasRenamed:(BOOL)renamed;

- (id) initForFile:(NSString *)file
            atPath:(NSString *)source
            toPath:(NSString *)destination;
- (void) dealloc;

- (void) assertDropboxRunningAndUpload;
- (void) uploadWithRetries:(int)retries;
- (NSString *) getNextFilenameWithExtension:(NSString *)ext;
/*- (void) dropboxIsRunning:(BOOL)running
             fromDetector:(DropboxDetector *)detector;*/
@end

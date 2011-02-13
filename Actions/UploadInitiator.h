//
//  UploadInitiator.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define MAX_NAME_LENGTH 32

@interface UploadInitiator : NSObject < DBRestClientDelegate> {
    DBRestClient *restClient;
    int retries;
    NSString *srcFile;
    NSString *srcPath;
    NSString *destFile;
    NSString *destPath;
}

@property (nonatomic, retain) DBRestClient *restClient;
@property (nonatomic, assign) int retries;
@property (nonatomic, retain) NSString* srcFile;
@property (nonatomic, retain) NSString* srcPath;
@property (nonatomic, retain) NSString* destFile;
@property (nonatomic, retain) NSString* destPath;

+ (void) copyURL:(NSString *)url
     basedOnFile:(NSString *)path
      wasRenamed:(BOOL)renamed;
+ (id) uploadFile:(NSString *)file
           atPath:(NSString *)source
           toPath:(NSString *)destination;

- (id) initForFile:(NSString *)file
            atPath:(NSString *)source
            toPath:(NSString *)destination;
- (void) dealloc;

- (void) upload;
- (NSString *) getNextFilenameWithExtension:(NSString *)ext;

@end

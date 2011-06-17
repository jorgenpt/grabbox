//
//  UploadInitiator.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSObject (UploadInitiatorDelegateInformalProtocol)
- (void) upload:(id)uploader;
- (void) scheduleUpload:(id)uploader;
- (void) uploaderDone:(id)uploader;
@end

@interface UploadInitiator : NSObject <DBRestClientDelegate> {
    id delegate;

    int retries;

    DBRestClient *restClient;
    NSString *srcFile;
    NSString *srcPath;
    NSString *destFile;
    NSString *destPath;
}

@property (assign) id delegate;

+ (void) pasteboardURLForPath:(NSString *)path
                  basedOnFile:(NSString *)file;

+ (id) uploadInitiatorForFile:(NSString *)file
                       atPath:(NSString *)source
                       toPath:(NSString *)destination;

- (id) initForFile:(NSString *)file
            atPath:(NSString *)source
            toPath:(NSString *)destination;

- (void) moveToWorkQueue;
- (void) upload;

- (NSString *) srcPath;

@end

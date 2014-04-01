//
//  Uploader.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright (C) 2014 Jørgen P. Tjernø. Licensed under GPLv2, see LICENSE in the project root for more info.
//

#import <Cocoa/Cocoa.h>


extern NSString * const kUploadStartingNotification;
extern NSString * const kUploadFinishingNotification;

@interface NSObject (UploaderDelegateInformalProtocol)
- (void) upload:(id)uploader;
- (void) scheduleUpload:(id)uploader;
- (void) uploaderDone:(id)uploader;
@end

@interface Uploader : NSObject {
    id delegate;
    int retries;
    NSString *srcFile;
    NSString *srcPath;
}

@property (assign) id delegate;
@property (nonatomic, assign) int retries;
@property (nonatomic, retain) NSString* srcFile;
@property (nonatomic, retain) NSString* srcPath;

+ (BOOL) pasteboardURL:(NSString *)url;

+ (NSString *) randomStringOfLength:(int)length;

- (id) initForFile:(NSString *)file
       inDirectory:(NSString *)source;

- (void) moveToWorkQueue;
- (void) upload;

- (void) uploadDone;

- (NSString *) srcPath;

@end

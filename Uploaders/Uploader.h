//
//  Uploader.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 devSoft. All rights reserved.
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
    id __unsafe_unretained delegate;
    int retries;
    NSString *srcFile;
    NSString *srcPath;
}

@property (unsafe_unretained) id delegate;
@property (nonatomic, assign) int retries;
@property (nonatomic, strong) NSString* srcFile;
@property (nonatomic, strong) NSString* srcPath;

+ (BOOL) pasteboardURL:(NSString *)url;

+ (NSString *) randomStringOfLength:(int)length;

- (id) initForFile:(NSString *)file
       inDirectory:(NSString *)source;

- (void) moveToWorkQueue;
- (void) upload;

- (void) uploadDone;

- (NSString *) srcPath;

@end

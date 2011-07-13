//
//  Uploader.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

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

+ (BOOL) pasteboardURLForPath:(NSString *)path;

+ (NSString *) randomStringOfLength:(int)length;

+ (id) uploaderForFile:(NSString *)file
           inDirectory:(NSString *)source;

- (id) initForFile:(NSString *)file
       inDirectory:(NSString *)source;

- (void) moveToWorkQueue;
- (void) upload;

- (NSString *) srcPath;

@end

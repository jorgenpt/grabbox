//
//  UploaderFactory.h
//  GrabBox2
//
//  Created by Jørgen Tjernø on 7/17/11.
//  Copyright 2011 Lookout, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Uploader.h"

extern NSString * const GBUploaderUnavailableNotification;
extern NSString * const GBUploaderAvailableNotification;

@protocol NSWindowViewContentController <NSObject>
@optional
- (NSString *)windowTitle;
@end

enum {
    HostImgur = 1,
    HostDropbox = 2,
} Host;

@interface UploaderFactory : NSObject <DBSessionDelegate, DBRestClientDelegate> {
    Class uploaderClass;

    DBRestClient *restClient;
    DBAccountInfo *account;

    NSWindow *hostSelecter;
    NSMatrix *radioGroup;
    NSButton *advanceButton;
    NSViewController<NSWindowViewContentController> *currentVC;

    BOOL ignoreUpdates;
}

@property (nonatomic, retain) DBAccountInfo *account;

@property (assign) IBOutlet NSWindow *hostSelecter;
@property (assign) IBOutlet NSMatrix *radioGroup;
@property (assign) IBOutlet NSButton *advanceButton;

+ (id) defaultFactory;

- (Uploader *) uploaderForFile:(NSString *)file
                   inDirectory:(NSString *)source;
- (void) loadSettings;

- (IBAction) advanceSelecter:(id)sender;

@end

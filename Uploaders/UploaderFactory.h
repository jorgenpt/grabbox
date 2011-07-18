//
//  UploaderFactory.h
//  GrabBox2
//
//  Created by Jørgen Tjernø on 7/17/11.
//  Copyright 2011 Lookout, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Uploader.h"
#import <Dropbox/Dropbox.h>

extern NSString * const GBUploaderUnavailableNotification;
extern NSString * const GBUploaderAvailableNotification;

@interface UploaderFactory : NSObject <DBSessionDelegate, DBCommonControllerDelegate, DBRestClientDelegate> {
    Class uploaderClass;

    DBRestClient *restClient;
    DBAccountInfo *account;
    DBLoginController *loginController;

    NSWindow *hostSelecter;
    NSMatrix *radioGroup;
    NSButton *advanceButton;

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

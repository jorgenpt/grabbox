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
extern NSString * const GBGainedFocusNotification;

@interface UploaderFactory : NSObject <DBSessionDelegate, DBRestClientDelegate> {
    DBRestClient *restClient;

    BOOL ignoreUpdates;
}

@property (nonatomic, retain) DBAccountInfo *account;

+ (id) defaultFactory;

- (Uploader *) uploaderForFile:(NSString *)file
                   inDirectory:(NSString *)source;
- (void) loadSettings;
- (void) logout;

@end

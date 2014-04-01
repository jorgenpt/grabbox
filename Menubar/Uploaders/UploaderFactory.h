//
//  UploaderFactory.h
//  GrabBox2
//
//  Created by Jørgen Tjernø on 7/17/11.
//  Copyright (C) 2014 Jørgen P. Tjernø. Licensed under GPLv2, see LICENSE in the project root for more info.
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

//
//  UploadManager.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 6/13/11.
//  Copyright (C) 2014 Jørgen P. Tjernø. Licensed under GPLv2, see LICENSE in the project root for more info.
//

#import <Foundation/Foundation.h>

#import "Uploader.h"
#import "NetworkReachabilityNotifier.h"

@interface UploadManager : NSObject {
@private
    dispatch_queue_t queue;
    BOOL queueIsSuspended;
    NetworkReachabilityNotifier *notifier;
    NSMutableDictionary *uploads;
}

- (void) scheduleUpload:(Uploader *)uploader;
- (void) upload:(Uploader *)uploader;
- (void) uploaderDone:(id)uploader;

@end

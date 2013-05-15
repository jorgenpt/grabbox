//
//  UploadManager.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 6/13/11.
//  Copyright 2011 devSoft. All rights reserved.
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

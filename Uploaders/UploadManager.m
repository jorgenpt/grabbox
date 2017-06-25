//
//  UploadManager.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 6/13/11.
//  Copyright 2011 devSoft. All rights reserved.
//

#import "UploadManager.h"

@interface UploadManager ()
@property (strong) NSMutableDictionary *uploads;
@property (assign) BOOL queueIsSuspended;
@property (strong) dispatch_queue_t queue;
@end

@implementation UploadManager

@synthesize uploads;
@synthesize queueIsSuspended;
@synthesize queue;

static NSString * const kDropboxHost = @"www.dropbox.com";

- (id)init
{
    self = [super init];
    if (self) {
        [self setUploads:[NSMutableDictionary dictionary]];
        queue = dispatch_queue_create("com.bitspatter.grabbox2.UploaderQueue", NULL);
        dispatch_set_target_queue(queue, dispatch_get_main_queue());

        [self setQueueIsSuspended:NO];

        __weak UploadManager* weakSelf = self;
        notifier = [[NetworkReachabilityNotifier alloc] initWithName:kDropboxHost];
        [notifier setCallback:^(SCNetworkReachabilityFlags flags) {
            __strong UploadManager* strongSelf = weakSelf;
            if (!strongSelf)
            {
                return;
            }

            BOOL reachable = YES;
            if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
                reachable = NO;
            else if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) != 0)
                reachable = NO;
            else if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0)
                reachable = NO;

            if (reachable)
            {
                DLog(@"Reachable, queueIsSuspended: %i", [strongSelf queueIsSuspended]);
                if ([strongSelf queueIsSuspended])
                    dispatch_resume(strongSelf.queue);
                [strongSelf setQueueIsSuspended:NO];
            }
            else
            {
                DLog(@"Unreachable, queueIsSuspended: %i", [strongSelf queueIsSuspended]);
                if (![strongSelf queueIsSuspended])
                    dispatch_suspend(strongSelf.queue);
                [strongSelf setQueueIsSuspended:YES];
            }
        }];

        DLog(@"Polling notifier.");
        [notifier poll];
        DLog(@"Scheduling notifier.");
        [notifier schedule];
    }

    return self;
}

- (void)dealloc
{
    queue = nil;
    
}

- (void) scheduleUpload:(Uploader *)uploader
{
    [uploads setObject:uploader
                forKey:[uploader srcPath]];
    [uploader setDelegate:self];
    dispatch_async(queue, ^{ [uploader upload]; });
}

- (void) upload:(Uploader *)uploader
{
    [uploads setObject:uploader
                forKey:[uploader srcPath]];
    [uploader setDelegate:self];
    [uploader upload];
}

- (void) uploaderDone:(id)uploader
{
    [uploader setDelegate:nil];
    [uploads removeObjectForKey:[uploader srcPath]];
}
@end

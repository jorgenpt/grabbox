//
//  UploadManager.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 6/13/11.
//  Copyright 2011 devSoft. All rights reserved.
//

#import "UploadManager.h"

@interface UploadManager ()
@property (retain) NSMutableDictionary *uploads;
@property (assign) BOOL queueIsSuspended;
@end

@implementation UploadManager

@synthesize uploads;
@synthesize queueIsSuspended;

- (id)init
{
    self = [super init];
    if (self) {
        [self setUploads:[NSMutableDictionary dictionary]];
        queue = dispatch_queue_create("no.devSoft.GrabBox2.uploaderQueue", NULL);
        dispatch_set_target_queue(queue, dispatch_get_main_queue());
        
        [self setQueueIsSuspended:NO];

        __block id manager = self;
        notifier = [[NetworkReachabilityNotifier alloc] initWithName:kDBDropboxAPIHost];
        [notifier setCallback:^(SCNetworkReachabilityFlags flags) {
            BOOL reachable = YES;
            if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
                reachable = NO;
            else if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) != 0)
                reachable = NO;
            else if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0)
                reachable = NO;
            
            if (reachable)
            {
                DLog(@"Reachable, queueIsSuspended: %i", [manager queueIsSuspended]);
                if ([manager queueIsSuspended])
                    dispatch_resume(queue);
                [manager setQueueIsSuspended:NO];
            }
            else
            {
                DLog(@"Unreachable, queueIsSuspended: %i", [manager queueIsSuspended]);
                if (![manager queueIsSuspended])
                    dispatch_suspend(queue);
                [manager setQueueIsSuspended:YES];
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
    [self setUploads:nil];
    [notifier release];
    dispatch_release(queue);

    [super dealloc];
}


- (void) scheduleUpload:(UploadInitiator *)uploader
{
    [uploads setObject:uploader
                forKey:[uploader srcPath]];
    [uploader setDelegate:self];
    dispatch_async(queue, ^{ [uploader upload]; });
}

- (void) upload:(UploadInitiator *)uploader
{
    [uploads setObject:uploader
                forKey:[uploader srcPath]];
    [uploader setDelegate:self];
    [uploader upload];
}

- (void) uploaderDone:(id)uploader
{
    [uploader setDelegate:nil];
    [[uploader retain] autorelease];
    [uploads removeObjectForKey:[uploader srcPath]];
}
@end

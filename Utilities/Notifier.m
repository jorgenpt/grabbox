//
//  Notifier.m
//  fs-notifier
//
//  Created by Peter Hosey on 2009-05-26.
//  Copyright 2009 Peter Hosey. All rights reserved.
//

#import "Notifier.h"

static void translateEvent(ConstFSEventStreamRef stream,
                           void *clientCallBackInfo,
                           size_t numEvents,
                           void *eventPathsVoidPointer,
                           const FSEventStreamEventFlags eventFlags[],
                           const FSEventStreamEventId eventIds[]
                           ) {
    NSArray *paths = (__bridge NSArray*)eventPathsVoidPointer;
    [(__bridge id<NotifierDelegate>)clientCallBackInfo eventForPaths:paths
                                                               flags:eventFlags
                                                                 ids:eventIds];
}

@interface Notifier ()
@property (weak) id<NotifierDelegate> delegate;
@end

@implementation Notifier

+ (id) notifierWithDelegate:(id<NotifierDelegate>)newDelegate
                       path:(NSString *)newPath{
    return [[self alloc] initWithDelegate:newDelegate
                                     path:newPath];
}

- (id) initWithDelegate:(id<NotifierDelegate>)newDelegate
                   path:(NSString *)newPath
{
    self = [super init];
    if (self)
    {
        self.delegate = newDelegate;
        isRunning = NO;
        watchedPaths = [NSArray arrayWithObject:newPath];
        context.version = 0L;
        context.info = (__bridge void *)self;
        context.retain = NULL;
        context.release = NULL;
        context.copyDescription = (CFAllocatorCopyDescriptionCallBack)CFCopyDescription;

        stream = FSEventStreamCreate(kCFAllocatorDefault, translateEvent, &context, (__bridge CFArrayRef)watchedPaths, kFSEventStreamEventIdSinceNow, /*latency*/ 1.0, kFSEventStreamCreateFlagUseCFTypes);
        if (!stream)
        {
            NSLog(@"Could not create event stream for path %@", newPath);
            return nil;
        }

        FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
    return self;
}

- (void) dealloc
{
    [self stop];
    FSEventStreamUnscheduleFromRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    CFRelease(stream);
}

- (void) eventForPaths:(NSArray *)paths
                 flags:(const FSEventStreamEventFlags[])flags
                   ids:(const FSEventStreamEventId[]) ids;
{
    [self.delegate eventForPaths:paths
                           flags:flags
                             ids:ids];
}

- (void) start
{
    if (!isRunning)
    {
        FSEventStreamStart(stream);
        isRunning = YES;
    }
}

- (void) stop
{
    if (isRunning)
    {
        FSEventStreamStop(stream);
        isRunning = NO;
    }
}

@end

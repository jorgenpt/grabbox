//
//  Notifier.m
//  fs-notifier
//
//  Created by Peter Hosey on 2009-05-26.
//  Copyright 2009 Peter Hosey. All rights reserved.
//

#import "Notifier.h"

@implementation Notifier

+ (id) notifierWithCallback:(FSEventStreamCallback)newCallback path:(NSString *)newPath callbackArgument:(void *)info; {
    return [[[self alloc] initWithCallback:newCallback path:newPath callbackArgument:info] autorelease];
}

- (id) initWithCallback:(FSEventStreamCallback)newCallback path:(NSString *)newPath callbackArgument:(void *)info {
    if((self = [super init])) {
        paths = [[NSArray arrayWithObject:newPath] retain];
        context.version = 0L;
        context.info = info;
        context.retain = (CFAllocatorRetainCallBack)CFRetain;
        context.release = (CFAllocatorReleaseCallBack)CFRelease;
        context.copyDescription = (CFAllocatorCopyDescriptionCallBack)CFCopyDescription;

        stream = FSEventStreamCreate(kCFAllocatorDefault, newCallback, &context, (CFArrayRef)paths, kFSEventStreamEventIdSinceNow, /*latency*/ 1.0, kFSEventStreamCreateFlagUseCFTypes);
        if (!stream) {
            NSLog(@"Could not create event stream for path %@", newPath);
            [self release];
            return nil;
        }

        FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
    return self;
}

- (void) dealloc {
    [self stop];
    FSEventStreamUnscheduleFromRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    CFRelease(stream);
    [super dealloc];
}

- (void) start {
    DLog(@"Starting notifier.");
    FSEventStreamStart(stream);
}
- (void) stop {
    DLog(@"Stopping notifier.");
    FSEventStreamStop(stream);
}

@end

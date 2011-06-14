//
//  NetworkReachabilityNotifier.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 6/13/11.
//  Copyright 2011 devSoft. All rights reserved.
//

#import "NetworkReachabilityNotifier.h"

void NetworkReachabilityChangedCallbackWrapper(
                                   SCNetworkReachabilityRef target,
                                   SCNetworkReachabilityFlags flags,
                                   void *info
                                   )
{
    NetworkReachabilityNotifier *notifier = (NetworkReachabilityNotifier *)info;
    if (notifier)
    {
        if ([notifier callback])
            [notifier callback](flags);
        else
            DLog(@"nil callback");
    }
    else
        DLog(@"NULL notifier");
}

@interface NetworkReachabilityNotifier ()
@property (nonatomic) SCNetworkReachabilityRef reachability;
@end

@implementation NetworkReachabilityNotifier

@synthesize callback;
@synthesize reachability;

- (id)init
{
    self = [super init];
    if (self) 
    {
        [self setReachability:NULL];
        [self setCallback:nil];
    }
    
    return self;
}

- (id)initWithName:(NSString *)name
{
    self = [self init];
    if (self)
    {
        const char *nodeName = [name cStringUsingEncoding:NSASCIIStringEncoding];
        SCNetworkReachabilityRef ref = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, nodeName);
        
        SCNetworkReachabilityContext context = {
            .version = 0,
            .info = self,
            .retain = NULL,
            .release = NULL,
            .copyDescription = CFCopyDescription
        };

        SCNetworkReachabilitySetCallback(ref, NetworkReachabilityChangedCallbackWrapper, &context);

        [self setReachability:ref];
        CFRelease(ref);
    }

    return self;
}

- (void)dealloc
{
    [self setReachability:NULL];

    [super dealloc];
}

- (void)setReachability:(SCNetworkReachabilityRef)newReachability
{
    if (newReachability)
        CFRetain(newReachability);

    if (reachability)
    {
        [self unschedule];
        CFRelease(reachability);
    }

    reachability = newReachability;
}

- (BOOL)schedule
{
    return SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
}

- (BOOL)unschedule
{
    return SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
}

- (void)poll
{
    SCNetworkReachabilityFlags flags;
    SCNetworkReachabilityGetFlags(reachability, &flags);
    callback(flags);
}

@end

//
//  Notifier.h
//  fs-notifier
//
//  Created by Peter Hosey on 2009-05-26.
//  Copyright 2009 Peter Hosey. All rights reserved.
//

@protocol NotifierDelegate
- (void) eventForPaths:(NSArray *)paths
                 flags:(const FSEventStreamEventFlags[])flags
                   ids:(const FSEventStreamEventId[]) ids;
@end

@interface Notifier : NSObject<NotifierDelegate> {
    NSArray *watchedPaths; // Actually just one.
    FSEventStreamRef stream;
    struct FSEventStreamContext context;
    BOOL isRunning;
}

+ (id) notifierWithDelegate:(id<NotifierDelegate>)newDelegate
                       path:(NSString *)newPath;
- (id) initWithDelegate:(id<NotifierDelegate>)newDelegate
                   path:(NSString *)newPath;

- (void) start;
- (void) stop;

@end

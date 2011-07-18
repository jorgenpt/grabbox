//
//  Notifier.h
//  fs-notifier
//
//  Created by Peter Hosey on 2009-05-26.
//  Copyright 2009 Peter Hosey. All rights reserved.
//

@interface Notifier : NSObject {
    NSArray *paths; // Actually just one.
    FSEventStreamRef stream;
    struct FSEventStreamContext context;
    BOOL isRunning;
}

+ (id) notifierWithCallback:(FSEventStreamCallback)newCallback
                       path:(NSString *)newPath
           callbackArgument:(void *)info;
- (id) initWithCallback:(FSEventStreamCallback)newCallback
                   path:(NSString *)newPath
       callbackArgument:(void *)info;

- (void) start;
- (void) stop;

@end

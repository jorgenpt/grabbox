//
//  Notifier.h
//  fs-notifier
//
//  Created by Peter Hosey on 2009-05-26.
//  Copyright 2009 Peter Hosey. All rights reserved.
//

@interface Notifier : NSObject {
	NSArray *paths; //Actually just one.
	FSEventStreamRef stream;
	struct FSEventStreamContext context;
}

+ (id) notifierWithCallback:(FSEventStreamCallback)newCallback path:(NSString *)newPath;
- (id) initWithCallback:(FSEventStreamCallback)newCallback path:(NSString *)newPath;

- (void) start;
- (void) stop;

@end

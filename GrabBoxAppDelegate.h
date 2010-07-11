//
//  GrabBoxAppDelegate.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Notifier.h"
#import "InformationGatherer.h"

@interface GrabBoxAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow* window;
	NSWindow* initialStartupWindow;
	InformationGatherer* info;
	Notifier* notifier;
}

- (id) init;
- (void) dealloc;

- (void) eventForStream:(ConstFSEventStreamRef)stream
				  paths:(NSArray *)paths
				  flags:(const FSEventStreamEventFlags[])flags
					ids:(const FSEventStreamEventId[]) ids;
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;

@property (assign) IBOutlet NSWindow* window;
@property (assign) IBOutlet NSWindow* initialStartupWindow;

@end

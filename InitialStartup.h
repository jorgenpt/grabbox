//
//  InitialStartup.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrabBoxAppDelegate.h"

@interface InitialStartup : NSObject {
	NSWindow *window;
	NSTextField *dropboxId;
	GrabBoxAppDelegate *appDelegate;
	NSTimer *timer;
	int lastIdFromUrl;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *dropboxId;
@property (assign) IBOutlet GrabBoxAppDelegate *appDelegate;

- (id) init;
- (void) dealloc;

- (void) close;

- (IBAction)okClicked: (id) sender;
- (IBAction)cancelClicked: (id) sender;

- (void) windowDidBecomeKey: (NSNotification *) aNotification;

- (void) checkClipboard: (NSTimer *) timer;

@end

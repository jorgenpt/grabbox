//
//  InitialStartup.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface InitialStartup : NSObject {
	NSWindow *window;
	NSTextField *dropboxId;
	NSTimer *timer;
	int lastIdFromUrl;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *dropboxId;

- (id) init;
- (void) dealloc;

- (IBAction)okClicked: (id) sender;
- (void) windowDidBecomeKey: (NSNotification *) aNotification;

- (void) checkClipboard: (NSTimer *) timer;

@end

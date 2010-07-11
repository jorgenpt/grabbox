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
	NSTimer *timer;
}

@property (assign) IBOutlet NSWindow *window;

- (void) checkClipboard: (NSTimer *) timer;
- (void) startClipboardTimer;

@end

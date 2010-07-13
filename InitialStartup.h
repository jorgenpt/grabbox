//
//  InitialStartup.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/10/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrabBoxAppDelegate.h"

@interface InitialStartup : NSObject {
    NSWindow *window;
    NSTextField *dropboxId;
    NSMenuItem* preferences;
    NSButton* autoLaunch;
    GrabBoxAppDelegate *appDelegate;
    NSTimer *timer;
    int lastIdFromUrl;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *dropboxId;
@property (assign) IBOutlet GrabBoxAppDelegate *appDelegate;
@property (assign) IBOutlet NSMenuItem *preferences;
@property (assign) IBOutlet NSButton *autoLaunch;

- (void) awakeFromNib;
- (void) dealloc;

- (BOOL)windowShouldClose:(id)sender;
- (void) windowDidBecomeKey: (NSNotification *) aNotification;

- (void) checkClipboard: (NSTimer *) timer;

@end

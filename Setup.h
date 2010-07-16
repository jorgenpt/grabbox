//
//  Setup.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/10/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrabBoxAppDelegate.h"

@interface Setup : NSObject {
    NSWindow *window;
    NSMenuItem *preferences;
    NSButton *linkOk;
    NSButton *autoLaunch;
    GrabBoxAppDelegate *appDelegate;
    int dropboxId;
    NSTimer *timer;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSMenuItem *preferences;
@property (assign) IBOutlet NSButton *linkOk;
@property (assign) IBOutlet NSButton *autoLaunch;
@property (assign) IBOutlet GrabBoxAppDelegate *appDelegate;
@property (nonatomic, assign) int dropboxId;

- (void) awakeFromNib;
- (void) dealloc;

- (IBAction) pressedOk:(id) sender;
- (IBAction) pressedCancel:(id) sender;
- (IBAction) openPublicFolder:(id) sender;

- (void) windowDidBecomeKey:(NSNotification *) aNotification;

- (void) checkClipboard:(NSTimer *) timer;

@end
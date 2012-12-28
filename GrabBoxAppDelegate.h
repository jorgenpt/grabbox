//
//  GrabBoxAppDelegate.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/8/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Sparkle/Sparkle.h>

#import "Notifier.h"
#import "InformationGatherer.h"
#import "Menubar.h"
#import "UploadManager.h"

@interface GrabBoxAppDelegate : NSObject

@property (assign) IBOutlet NSWindow* betaExpiredWindow;
@property (assign) IBOutlet NSMenuItem *checkForUpdatesMenuItem;
@property (assign) IBOutlet NSMenuItem *checkForUpdatesMenubarItem;
@property (assign) IBOutlet Menubar* menubar;

@property (assign) BOOL canInteract;

- (IBAction) uploadFromPasteboard:(id)sender;

#ifndef MAC_APP_STORE
- (IBAction) checkForUpdates:(id)sender;
#endif

@end

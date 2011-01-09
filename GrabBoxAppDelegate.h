//
//  GrabBoxAppDelegate.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/8/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#define CONFIG(name) (@#name)
#define BUNDLE_IDENTIFIER @"no.devsoft.GrabBox"

#import <Cocoa/Cocoa.h>
#import <Sparkle/Sparkle.h>

#import "Notifier.h"
#import "InformationGatherer.h"
#import "DropboxDetector.h"
#import "Menubar.h"

@interface GrabBoxAppDelegate : NSObject <DropboxDetectorDelegate> {
    NSWindow* setupWindow;
    NSWindow* restartWindow;
    NSWindow* nagWindow;
    Menubar* menubar;
    InformationGatherer* info;
    Notifier* notifier;
    NSMutableArray* detectors;
}

@property (assign) IBOutlet NSWindow* setupWindow;
@property (assign) IBOutlet NSWindow* restartWindow;
@property (assign) IBOutlet NSWindow* nagWindow;
@property (assign) IBOutlet Menubar* menubar;


- (void) awakeFromNib;
- (void) dealloc;

- (void) setDropboxId:(int)toId;
- (int) dropboxId;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context;

- (void) startMonitoring;
- (void) eventForStream:(ConstFSEventStreamRef)stream
                  paths:(NSArray *)paths
                  flags:(const FSEventStreamEventFlags[])flags
                    ids:(const FSEventStreamEventId[]) ids;
- (NSArray *)feedParametersForUpdater:(SUUpdater *)updater
                 sendingSystemProfile:(BOOL)sendingProfile;
- (void) applicationWillFinishLaunching:(NSNotification *)aNotification;
- (void) applicationDidFinishLaunching:(NSNotification *)aNotification;
- (void) dropboxIsRunning:(BOOL)running
             fromDetector:(DropboxDetector *)detector;

- (IBAction) browseUploadedScreenshots:(id)sender;
- (IBAction) uploadFromPasteboard:(id)sender;
- (IBAction) openFeedback:(id)sender;
- (IBAction) openDonatePref:(id)sender;
- (IBAction) openDonateNag:(id)sender;
- (IBAction) restartLater:(id)sender;
- (IBAction) restartApplication:(id)sender;

@end

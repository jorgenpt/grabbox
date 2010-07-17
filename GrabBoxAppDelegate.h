//
//  GrabBoxAppDelegate.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/8/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Notifier.h"
#import "InformationGatherer.h"
#import "DropboxDetector.h"
#import "Sparkle/SUUpdater.h"

@interface GrabBoxAppDelegate : NSObject <NSApplicationDelegate, DropboxDetectorDelegate> {
    NSWindow* setupWindow;
    InformationGatherer* info;
    Notifier* notifier;
    NSMutableArray* detectors;
}

@property (assign) IBOutlet NSWindow* setupWindow;

- (void) awakeFromNib;
- (void) dealloc;

- (void) setDropboxId:(int)toId;
- (int) dropboxId;

- (void) startMonitoring;
- (void) eventForStream:(ConstFSEventStreamRef)stream
                  paths:(NSArray *)paths
                  flags:(const FSEventStreamEventFlags[])flags
                    ids:(const FSEventStreamEventId[]) ids;
- (NSArray *)feedParametersForUpdater:(SUUpdater *)updater
                 sendingSystemProfile:(BOOL)sendingProfile;
- (void) applicationDidFinishLaunching:(NSNotification *)aNotification;
- (void) dropboxIsRunning:(BOOL)running
             fromDetector:(DropboxDetector *)detector;
@end

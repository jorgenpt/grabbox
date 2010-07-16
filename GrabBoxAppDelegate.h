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

@interface GrabBoxAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow* setupWindow;
    InformationGatherer* info;
    Notifier* notifier;
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
- (void) applicationDidFinishLaunching:(NSNotification *)aNotification;

@end

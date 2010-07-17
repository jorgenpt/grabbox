//
//  DropboxDetector.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/15/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DropboxDetector;

@protocol DropboxDetectorDelegate
- (void) dropboxIsRunning:(BOOL)runState
             fromDetector:(DropboxDetector *)detector;
@end

@interface DropboxDetector : NSObject {
    NSWindow* notRunning;
    NSWindow* notInstalled;
    id <DropboxDetectorDelegate> delegate;
}

@property (assign) IBOutlet NSWindow* notRunning;
@property (assign) IBOutlet NSWindow* notInstalled;
@property (nonatomic, retain) id <DropboxDetectorDelegate> delegate;

+ (id) dropboxDetectorWithDelegate:(id <DropboxDetectorDelegate>) notifiedDelegate;

- (id) initWithDelegate:(id <DropboxDetectorDelegate>) notifiedDelegate;
- (void) dealloc;

- (void) awakeFromNib;
- (void) checkIfRunning;
- (IBAction) startDropbox:(id) sender;
- (IBAction) doNotStartDropbox:(id) sender;
- (IBAction) openDropboxSite:(id) sender;

@end

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

@interface GrabBoxAppDelegate : NSObject <DBSessionDelegate, DBCommonControllerDelegate, DBRestClientDelegate> {
    NSWindow* setupWindow;
    NSWindow* restartWindow;
    NSWindow* nagWindow;
    Menubar* menubar;
    InformationGatherer* info;
    Notifier* notifier;

    DBRestClient *restClient;
    DBAccountInfo *account;
    DBLoginController *loginController;
    BOOL canInteract;
}

@property (assign) IBOutlet NSWindow* setupWindow;
@property (assign) IBOutlet NSWindow* restartWindow;
@property (assign) IBOutlet NSWindow* nagWindow;
@property (assign) IBOutlet Menubar* menubar;

@property (nonatomic, retain) DBAccountInfo *account;

- (IBAction) browseUploadedScreenshots:(id)sender;
- (IBAction) uploadFromPasteboard:(id)sender;
- (IBAction) openFeedback:(id)sender;
- (IBAction) openDonatePref:(id)sender;
- (IBAction) openDonateNag:(id)sender;
- (IBAction) restartLater:(id)sender;
- (IBAction) restartApplication:(id)sender;

@end

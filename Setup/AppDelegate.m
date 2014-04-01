//
//  AppDelegate.m
//  GrabBox
//
//  Created by Jørgen Tjernø on 5/15/13.
//  Copyright (c) 2013 bitSpatter. All rights reserved.
//

#import "AppDelegate.h"

#import <DropboxOSX/DropboxOSX.h>

@implementation AppDelegate

static NSString * const dropboxConsumerKey = @"<INSERT DROPBOX CONSUMER KEY>";
static NSString * const dropboxConsumerSecret = @"<INSERT DROPBOX CONSUMER SECRET>";

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    DBSession *session = [[DBSession alloc] initWithAppKey:dropboxConsumerKey
                                                 appSecret:dropboxConsumerSecret
                                                      root:kDBRootAppFolder];
    [DBSession setSharedSession:session];
    
    self.step = 0;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(authHelperStateChangedNotification:)
                                                 name:DBAuthHelperOSXStateChangedNotification
                                               object:[DBAuthHelperOSX sharedHelper]];
    [self updateLinkButton];
    
    NSAppleEventManager *em = [NSAppleEventManager sharedAppleEventManager];
    [em setEventHandler:self
            andSelector:@selector(getUrl:withReplyEvent:)
          forEventClass:kInternetEventClass
             andEventID:kAEGetURL];

    [self advanceToAppropriateStepAndSkipTutorial:YES];
}

- (void)advanceToAppropriateStepAndSkipTutorial:(BOOL)skipTutorial
{
    if (self.step == 0 && ![[DBSession sharedSession] isLinked])
    {
        return;
    }
    else if (true) // TODO: Check for sandbox access to screenshot location.
    {
        if (self.step != 1)
        {
            self.step = 1;
            self.step2.image = [NSImage imageNamed:@"progressbutton_active"];
        }
    }
    else if (!skipTutorial)
    {
        if (self.step != 2)
        {
            self.step = 2;
            self.step2.image = [NSImage imageNamed:@"progressbutton_active"];
            self.step3.image = [NSImage imageNamed:@"progressbutton_active"];
            self.contentBox.contentView = /* TODO: VIEW. */ nil;
        }
    }
    else
    {
        // TODO: Launch app.
    }
}

- (IBAction)didPressLinkDropbox:(id)sender {
    if ([[DBSession sharedSession] isLinked]) {
        // The link button turns into an unlink button when you're linked
        [[DBSession sharedSession] unlinkAll];
        [self updateLinkButton];
    } else {
        [[DBAuthHelperOSX sharedHelper] authenticate];
        [self updateLinkButton];        
    }
}

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    // This gets called when the user clicks Show "App name". You don't need to do anything for Dropbox here
}

- (void)authHelperStateChangedNotification:(NSNotification *)notification {
	[self updateLinkButton];
    [self advanceToAppropriateStepAndSkipTutorial:NO];
}

- (void)updateLinkButton
{
	if (![[DBSession sharedSession] isLinked])
    {
        if ([[DBAuthHelperOSX sharedHelper] isLoading])
        {
            self.linkButton.enabled = NO;
            [self.progressIndicator startAnimation:self];
        }
        else
        {
            self.linkButton.enabled = YES;
            [self.progressIndicator stopAnimation:self];
        }
	}
    else
    {
        self.linkButton.enabled = NO;
        [self.progressIndicator stopAnimation:self];
    }
}

@end

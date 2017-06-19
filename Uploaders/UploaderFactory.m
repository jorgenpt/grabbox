//
//  UploaderFactory.m
//  GrabBox2
//
//  Created by Jørgen Tjernø on 7/17/11.
//  Copyright 2011 Lookout, Inc. All rights reserved.
//

#import "UploaderFactory.h"

#import "GrabBoxAppDelegate.h"
#import "WelcomeWindowController.h"

#import "DropboxUploader.h"

// If this fails, then you need to copy DropboxAPIKey_Private.inl.dist to DropboxAPIKey_Private.inl, and edit it.
#import "../Common/DropboxAPIKey_Private.inl"

NSString * const GBUploaderUnavailableNotification = @"GBUploaderUnavailableNotification";
NSString * const GBUploaderAvailableNotification = @"GBUploaderAvailableNotification";
NSString * const GBGainedFocusNotification = @"GBGainedFocusNotification";

static UploaderFactory *defaultFactory = nil;

@interface UploaderFactory ()

@property (assign) Class uploaderClass;
@property (retain) WelcomeWindowController *welcomeWindow;

- (void)setAvailable:(BOOL)availability;

@end

@implementation UploaderFactory

+ (void) initialize
{
    if (defaultFactory == nil)
    {
        defaultFactory = [[UploaderFactory alloc] init];
    }
}

+ (id) defaultFactory
{
    return defaultFactory;
}

- (id) init
{
    self = [super init];
    if (self)
    {
        isAvailable = NO;
        [self setUploaderClass:[DropboxUploader class]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(gainedFocus:)
                                                     name:NSApplicationDidBecomeActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(gainedFocus:)
                                                     name:GBGainedFocusNotification
                                                   object:nil];
    }

    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setWelcomeWindow:nil];

    [super dealloc];
}

- (void)setAvailable:(BOOL)availability
{
    if (isAvailable == availability)
    {
        return;
    }

    isAvailable = availability;

    if (isAvailable)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:GBUploaderAvailableNotification
                                                            object:nil];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:GBUploaderUnavailableNotification
                                                            object:nil];
    }
}

- (Uploader *) uploaderForFile:(NSString *)file
                   inDirectory:(NSString *)source
{
    return [[[self.uploaderClass alloc] initForFile:file inDirectory:source] autorelease];
}

- (void) applicationWillFinishLaunching
{
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                       andSelector:@selector(handleAppleEvent:withReplyEvent:)
                                                     forEventClass:kInternetEventClass
                                                        andEventID:kAEGetURL];
}

- (void)handleAppleEvent:(NSAppleEventDescriptor *)event
          withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSURL *url = [NSURL URLWithString:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];
    DBOAuthResult *authResult = [DBClientsManager handleRedirectURL:url];
    if (authResult != nil) {
        if ([authResult isSuccess]) {
            DLog(@"Got account info, starting FS monitoring and enabling interaction!");
            [self setAvailable:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:GBUploaderAvailableNotification
                                                                object:nil];
            [self.welcomeWindow loggedIn];
        } else if ([authResult isCancel]) {
            DLog(@"Authorization flow was manually canceled by user!");
        } else if ([authResult isError]) {
            NSLog(@"Received authorization failure, disabling app then prompt for link!");
            [self setUploaderClass:nil];
            [DBClientsManager unlinkAndResetClients];
        }
    }

    [self.welcomeWindow.window makeKeyAndOrderFront:self];
    [[NSRunningApplication currentApplication]
     activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
}

- (void) loadSettings
{
    [self setupDropbox];
}

- (void) logout
{
    [DBClientsManager unlinkAndResetClients];
    [self setAvailable:NO];
    [self showWelcomeWindow];
}

- (void) setupDropbox
{
    if (![DBClientsManager appKey])
    {
         [DBClientsManager setupWithAppKeyDesktop:dropboxConsumerKey];
    }

    if ([DBClientsManager.authorizedClient isAuthorized])
    {
        [self setAvailable:YES];
    }
    else
    {
        [self showWelcomeWindow];
    }
}

- (void) showWelcomeWindow
{
    if (!self.welcomeWindow) {
        self.welcomeWindow = [[[WelcomeWindowController alloc] initWithWindowNibName:@"WelcomeWindow"] autorelease];
    }

    [self.welcomeWindow.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)gainedFocus:(NSNotification *)aNotification
{
    if ([DBClientsManager.authorizedClient isAuthorized])
    {
        [self setAvailable:YES];
    }
}


@end

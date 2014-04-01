//
//  UploaderFactory.m
//  GrabBox2
//
//  Created by Jørgen Tjernø on 7/17/11.
//  Copyright (C) 2014 Jørgen P. Tjernø. Licensed under GPLv2, see LICENSE in the project root for more info.
//

#import "UploaderFactory.h"

#import "GrabBoxAppDelegate.h"
#import "WelcomeWindowController.h"

#import "DropboxUploader.h"

// If this fails, then you need to copy DropboxAPIKey_Private.inl.dist to DropboxAPIKey_Private.inl, and edit it.
#import "../../Common/DropboxAPIKey_Private.inl"

NSString * const GBUploaderUnavailableNotification = @"GBUploaderUnavailableNotification";
NSString * const GBUploaderAvailableNotification = @"GBUploaderAvailableNotification";
NSString * const GBGainedFocusNotification = @"GBGainedFocusNotification";

static UploaderFactory *defaultFactory = nil;

@interface UploaderFactory ()

@property (assign) Class uploaderClass;
@property (retain) WelcomeWindowController *welcomeWindow;

- (DBRestClient *)restClient;

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
    [restClient setDelegate:nil];
    [restClient release];
    [self setAccount:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}

- (Uploader *) uploaderForFile:(NSString *)file
                   inDirectory:(NSString *)source
{
    return [[[self.uploaderClass alloc] initForFile:file inDirectory:source] autorelease];
}

- (void) loadSettings
{
    [[NSNotificationCenter defaultCenter] postNotificationName:GBUploaderUnavailableNotification object:nil];

    [self setAccount:nil];
    [self setupDropbox];
}

- (void) logout
{
    [[DBSession sharedSession] unlinkAll];
    [self loadSettings];
}

- (DBSession *) dropboxSession
{
    return [[[DBSession alloc] initWithAppKey:dropboxConsumerKey
                                    appSecret:dropboxConsumerSecret
                                         root:kDBRootAppFolder] autorelease];
}

- (void) setupDropbox
{
    DBSession *session = [self dropboxSession];
    [session setDelegate:self];
    [DBSession setSharedSession:session];

    if ([session isLinked])
    {
        [[self restClient] setDelegate:self];
        [[self restClient] loadAccountInfo];
    }
    else
    {
        [self showWelcomeWindow];
    }
}


- (void)gainedFocus:(NSNotification *)aNotification {
    if ([DBSession sharedSession])
    {
        if ([[self restClient] requestTokenLoaded]) {
            [[self restClient] loadAccessToken];
        }
    }
}

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    // This gets called when the user clicks Show "App name". You don't need to do anything for Dropbox here
    // TODO: GH-2: Show a dialog to confirm
}

- (void) showWelcomeWindow
{
    [[DMTracker defaultTracker] trackEvent:@"Welcome Window"];

    if (!self.welcomeWindow) {
        self.welcomeWindow = [[[WelcomeWindowController alloc] initWithWindowNibName:@"WelcomeWindow"] autorelease];
    }

    [self.welcomeWindow.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}


#pragma mark DBSession delegate methods

- (void) sessionDidReceiveAuthorizationFailure:(DBSession *)session
                                        userId:(NSString *)userId
{
    [[DMTracker defaultTracker] trackEvent:@"Authorization Failure"];
    NSLog(@"Received authorization failure, disabling app then prompt for link!");
    [self setAccount:nil];
    [self setUploaderClass:nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:GBUploaderUnavailableNotification object:nil];

    [session unlinkUserId:userId];
    [self showWelcomeWindow];
}

#pragma mark DBRestClientOSXDelegate delegate methods

- (void)restClientLoadedRequestToken:(DBRestClient *)restClient
{
    NSURL *url = [[self restClient] authorizeURL];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (void)restClient:(DBRestClient *)restClient loadRequestTokenFailedWithError:(NSError *)error {
    DLog(@"loadRequestTokenFailedWithError: %@", error);
}

- (void)restClientLoadedAccessToken:(DBRestClient *)restClient {
    [[self restClient] loadAccountInfo];
}

- (void)restClient:(DBRestClient *)restClient loadAccessTokenFailedWithError:(NSError *)error {
    DLog(@"loadAccessTokenFailedWithError: %@", error);
}

#pragma mark DBRestClient delegate methods

- (void)restClient:(DBRestClient*)client
 loadedAccountInfo:(DBAccountInfo*)accountInfo
{
    DLog(@"Got account info, starting FS monitoring and enabling interaction!");
    [self setAccount:accountInfo];

    [[NSNotificationCenter defaultCenter] postNotificationName:GBUploaderAvailableNotification object:nil];
}

- (void)restClient:(DBRestClient*)client loadAccountInfoFailedWithError:(NSError*)error
{
    // Error codes described here: https://www.dropbox.com/developers/reference/api
    if (error.code == 401)
        // "Bad or expired token. This can happen if the user or Dropbox revoked or expired an access token.
        // To fix, you should re-authenticate the user."
    {
        if (self.account)
        {
            // TODO: GH-1: Show error dialog & ask to re-auth.
            // For now we just force a re-auth.
            DLog(@"401 from Dropbox when loading account info.");

            [[NSUserDefaults standardUserDefaults] removeObjectForKey:CONFIG(Host)];
        }
        else
        {
            [[DMTracker defaultTracker] trackEvent:@"Bad token on first-run"];
            DLog(@"401 from Dropbox when loading initial account info.");

            [[NSUserDefaults standardUserDefaults] removeObjectForKey:CONFIG(Host)];
        }
    }
    else
    {
        // TODO: GH-3: Open an error dialog!
        ErrorLog(@"Failed retrieving account info: %ld", error.code);
        [NSApp terminate:self];
    }
}

- (DBRestClient *)restClient {
    if (!restClient) {
        restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient.delegate = self;
    }
    return restClient;
}

@end

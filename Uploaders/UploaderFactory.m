//
//  UploaderFactory.m
//  GrabBox2
//
//  Created by Jørgen Tjernø on 7/17/11.
//  Copyright 2011 Lookout, Inc. All rights reserved.
//

#import "UploaderFactory.h"

#import "GrabBoxAppDelegate.h"

#import "ImgurUploader.h"
#import "DropboxUploader.h"

NSString * const GBUploaderUnavailableNotification = @"GBUploaderUnavailableNotification";
NSString * const GBUploaderAvailableNotification = @"GBUploaderAvailableNotification";

static NSString * const dropboxConsumerKey = @"<INSERT DROPBOX CONSUMER KEY>";
static NSString * const dropboxConsumerSecret = @"<INSERT DROPBOX CONSUMER SECRET>";

static UploaderFactory *defaultFactory = nil;
enum {
    HostImgur = 1,
    HostDropbox = 2,
} Host;

@interface UploaderFactory ()

@property (assign) Class uploaderClass;

@property (nonatomic, retain) DBRestClient *restClient;
@property (nonatomic, retain) DBLoginController *loginController;

- (void) promptForHost;
- (void) promptForDropboxLink;

- (void) setupHost:(int)host;
- (void) setupDropbox;
- (void) setupImgur;

@end

@implementation UploaderFactory

@synthesize uploaderClass;

@synthesize restClient;
@synthesize account;
@synthesize loginController;

@synthesize hostSelecter;
@synthesize radioGroup;
@synthesize advanceButton;

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
        ignoreUpdates = NO;
        [self setUploaderClass:[ImgurUploader class]];
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                                  forKeyPath:[@"values." stringByAppendingString:CONFIG(Host)]
                                                                     options:0
                                                                     context:NULL];
    }

    return self;
}

- (void) dealloc
{
    [self setRestClient:nil];
    [self setLoginController:nil];
    [self setAccount:nil];

    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self
                                                                 forKeyPath:[@"values." stringByAppendingString:CONFIG(Host)]];

    [super dealloc];
}

- (void) awakeFromNib
{
    int host = [[NSUserDefaults standardUserDefaults] integerForKey:CONFIG(Host)];
    if (!host)
        host = HostImgur;

    [radioGroup selectCellWithTag:host];

    [hostSelecter makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction) advanceSelecter:(id)sender
{
    NSInteger selectedTag = [radioGroup selectedTag];
    switch (selectedTag)
    {
        case HostDropbox:
        case HostImgur:
            [hostSelecter close];
            [[NSUserDefaults standardUserDefaults] setInteger:selectedTag forKey:CONFIG(Host)];
            break;

        default:
            // TODO: Handle this better?
            ErrorLog(@"Invalid selected tag: %ld!", selectedTag);
            [NSApp terminate:self];
            break;
    }
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                         change:(NSDictionary *)change context:(void *)context
{
    if (ignoreUpdates)
        return;

    if ([keyPath isEqualToString:[@"values." stringByAppendingString:CONFIG(Host)]])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadSettings];
        });
    }
}

- (Uploader *) uploaderForFile:(NSString *)file
                   inDirectory:(NSString *)source
{
    return [[[uploaderClass alloc] initForFile:file inDirectory:source] autorelease];
}

- (void) loadSettings
{
    int host = [[NSUserDefaults standardUserDefaults] integerForKey:CONFIG(Host)];
    [[NSNotificationCenter defaultCenter] postNotificationName:GBUploaderUnavailableNotification object:nil];

    [self setRestClient:nil];
    [self setAccount:nil];
    [self setUploaderClass:nil];

    [self setupHost:host];
}

- (DBSession *) dropboxSession
{
    return [[[DBSession alloc] initWithConsumerKey:dropboxConsumerKey
                                    consumerSecret:dropboxConsumerSecret] autorelease];
}

- (void) setupHost:(int)host
{
    switch (host)
    {
        case HostDropbox:
            [self setupDropbox];
            break;

        case HostImgur:
            [self setupImgur];
            break;

        default:
        {
            DBSession *session = [self dropboxSession];
            if ([session isLinked])
                [session unlink];
            [self promptForHost];
            break;
        }
    }
}

- (void) setupDropbox
{
    DBSession *session = [self dropboxSession];
    [session setDelegate:self];
    [DBSession setSharedSession:session];

    [self setRestClient:[DBRestClient restClientWithSharedSession]];
    [restClient setDelegate:self];

    if ([session isLinked])
    {
        [restClient loadAccountInfo];
    }
    else
    {
        [self promptForDropboxLink];
    }
}

- (void) setupImgur
{
    [self setUploaderClass:[ImgurUploader class]];
    [[NSNotificationCenter defaultCenter] postNotificationName:GBUploaderAvailableNotification object:nil];
}

- (void) promptForHost
{
    [NSBundle loadNibNamed:@"HostSetup" owner:self];
}

- (void) promptForDropboxLink
{
    [[DMTracker defaultTracker] trackEventInCategory:@"Usage"
                                            withName:@"Account Link Prompt"];
    [self setLoginController:[[[DBLoginController alloc] init] autorelease]];
    [loginController setDelegate:self];
    [loginController presentFrom:self];
    [NSApp activateIgnoringOtherApps:YES];
}

#pragma mark DBSession delegate methods

- (void) sessionDidReceiveAuthorizationFailure:(DBSession *)session
{
    [[DMTracker defaultTracker] trackEventInCategory:@"Oddities"
                                            withName:@"Authorization Failure"];
    NSLog(@"Received authorization failure, disabling app then prompt for link!");
    [self setAccount:nil];
    [self setUploaderClass:nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:GBUploaderUnavailableNotification object:nil];
    [self promptForDropboxLink];
}

#pragma mark DBLoginController delegate methods

- (void) controllerDidComplete:(DBLoginController *)window
{
    DLog(@"Account linked, trying to load account info.");
    [self setLoginController:nil];
    [restClient loadAccountInfo];
}

- (void) controllerDidCancel:(DBLoginController *)window
{
    [[DMTracker defaultTracker] trackEventInCategory:@"Usage"
                                            withName:@"Account Link Cancelled"];
    DLog(@"Cancelled account link window, terminating.");

    ignoreUpdates = YES;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CONFIG(Host)];
    [NSApp terminate:self];
}

#pragma mark DBRestClient delegate methods

- (void)restClient:(DBRestClient*)client
 loadedAccountInfo:(DBAccountInfo*)accountInfo
{
    DLog(@"Got account info, starting FS monitoring and enabling interaction!");
    [self setAccount:accountInfo];
    [self setUploaderClass:[DropboxUploader class]];
    [[NSNotificationCenter defaultCenter] postNotificationName:GBUploaderAvailableNotification object:nil];
}

- (void)restClient:(DBRestClient*)client loadAccountInfoFailedWithError:(NSError*)error
{
    ErrorLog(@"Failed retrieving account info: %ld", error.code);
    [NSApp terminate:self];
}

@end

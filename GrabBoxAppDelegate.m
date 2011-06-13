//
//  GrabBoxAppDelegate.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/8/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "GrabBoxAppDelegate.h"
#import "FSRefConversions.h"

#import "Growler.h"
#import "UploadInitiator.h"

@interface GrabBoxAppDelegate ()

@property (nonatomic, assign) InformationGatherer* info;
@property (nonatomic, retain) Notifier* notifier;
@property (nonatomic, retain) DBRestClient *restClient;
@property (assign) BOOL canInteract;
@property (nonatomic, retain) DBLoginController *loginController;

- (void) startMonitoring;
- (void) stopMonitoring;

- (void) promptForLink;

- (void) eventForStream:(ConstFSEventStreamRef)stream
                  paths:(NSArray *)paths
                  flags:(const FSEventStreamEventFlags[])flags
                    ids:(const FSEventStreamEventId[]) ids;
- (void) uploadScreenshot:(NSString *)file;
- (NSString *) workQueueFilenameForClipboardData;

@end

@implementation GrabBoxAppDelegate

@synthesize setupWindow;
@synthesize restartWindow;
@synthesize nagWindow;
@synthesize menubar;

@synthesize info;
@synthesize notifier;

@synthesize restClient;
@synthesize account;
@synthesize loginController;
@synthesize canInteract;

static void translateEvent(ConstFSEventStreamRef stream,
                           void *clientCallBackInfo,
                           size_t numEvents,
                           void *eventPathsVoidPointer,
                           const FSEventStreamEventFlags eventFlags[],
                           const FSEventStreamEventId eventIds[]
                           ) {
    NSArray *paths = (NSArray*)eventPathsVoidPointer;
    [(GrabBoxAppDelegate *)clientCallBackInfo eventForStream:stream
                                                       paths:paths
                                                       flags:eventFlags
                                                         ids:eventIds];
}

- (void) awakeFromNib
{
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.ShowInDock"
                                                                 options:0
                                                                 context:NULL];

    [self setInfo:[InformationGatherer defaultGatherer]];
    [self setNotifier:[Notifier notifierWithCallback:translateEvent
                                                path:[info screenshotPath]
                                    callbackArgument:self]];

    BOOL showInDock = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowInDock"];
    if (!showInDock)
    {
        [[self menubar] show];
    }
}

- (void) dealloc
{
    [self setInfo:nil];
    [self setNotifier:nil];
    [self setLoginController:nil];

    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"values.ShowInDock"])
    {
        BOOL shouldShowInDock = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowInDock"];
        if (shouldShowInDock)
        {

            ProcessSerialNumber psn = { 0, kCurrentProcess };
            OSStatus returnCode = TransformProcessType(&psn, kProcessTransformToForegroundApplication);
            if (returnCode != 0)
            {
                NSLog(@"ERROR: Could not bring the application to front. Error %d. Leaving in menubar.", returnCode);
            }
            else
            {
                [[self menubar] hide];
            }
        }
        else
        {
            [NSApp activateIgnoringOtherApps:YES];
            [NSApp runModalForWindow:restartWindow];
        }
    }
}

- (NSArray *)feedParametersForUpdater:(SUUpdater *)updater sendingSystemProfile:(BOOL)sendingProfile
{
    NSString* appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSDictionary* versionParam = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"currentversion", @"key",
                                  appVersion, @"value",
                                  @"Current Version", @"displayKey",
                                  appVersion, @"displayValue",
                                  nil];
    return [NSArray arrayWithObject:versionParam];
}

- (void) applicationWillFinishLaunching:(NSNotification *)aNotification
{
    BOOL showInDock = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowInDock"];
    if (showInDock)
    {
        ProcessSerialNumber psn = { 0, kCurrentProcess };
        OSStatus returnCode = TransformProcessType(&psn, kProcessTransformToForegroundApplication);
        if (returnCode != 0)
        {
            NSLog(@"Could not bring the application to front. Error %d. Using menubar.", returnCode);
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ShowInDock"];
        }
    }

    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"SUSendProfileInfo"];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSString *consumerKey = @"<INSERT DROPBOX CONSUMER KEY>";
	NSString *consumerSecret = @"<INSERT DROPBOX CONSUMER SECRET>";

    [[SUUpdater sharedUpdater] setDelegate:self];

	DBSession *session =  [[[DBSession alloc] initWithConsumerKey:consumerKey
                                                  consumerSecret:consumerSecret] autorelease];
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
        [self promptForLink];
        [self setCanInteract:NO];
    }
}

- (void) startMonitoring
{
    [notifier start];
    BOOL hasBeenNagged = [[NSUserDefaults standardUserDefaults] boolForKey:@"HasBeenNagged"];
    int numberOfScreenshots = [[NSUserDefaults standardUserDefaults] integerForKey:@"NumberOfScreenshotsUploaded"];

    if (!hasBeenNagged && numberOfScreenshots >= 15)
    {
        [[self nagWindow] makeKeyAndOrderFront:self];
        [NSApp activateIgnoringOtherApps:YES];
        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:@"HasBeenNagged"];
    }
}

- (void) stopMonitoring
{
    [notifier stop];
}

- (void) promptForLink
{
    [self setLoginController:[[[DBLoginController alloc] init] autorelease]];
    [loginController setDelegate:self];
    [loginController presentFrom:self];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void) eventForStream:(ConstFSEventStreamRef)stream
                  paths:(NSArray *)paths
                  flags:(const FSEventStreamEventFlags[])flags
                    ids:(const FSEventStreamEventId[]) ids
{
    NSString* screenshotPath = [info screenshotPath];
    FSRef screenshotPathRef;
    if (![screenshotPath fsRef:&screenshotPathRef])
    {
        GrowlerGrowl *errorGrowl = [GrowlerGrowl growlErrorWithTitle:@"GrabBox could not get Screen Grab path!"
                                                         description:@"Could not find directory to monitor for screenshots."];
        [Growler growl:errorGrowl];
        NSLog(@"ERROR: Failed getting FSRef for screenshotPath '%@'", screenshotPath);
        return;
    }

    BOOL screenshotDirChanged = NO;

    for (NSString* path in paths)
    {
        FSRef pathRef;
        if (![path fsRef:&pathRef])
        {
            NSLog(@"ERROR: Failed getting FSRef for path '%@'", path);
            continue;
        }

        OSErr comparison = FSCompareFSRefs(&screenshotPathRef, &pathRef);
        if (comparison == diffVolErr || comparison == errFSRefsDifferent)
        {
            continue;
        }

        if (comparison != noErr)
        {
            NSLog(@"ERROR: Failed comparing FSRef for path (%@) and screenshotPath (%@): %i", path, screenshotPath, comparison);
            continue;
        }

        screenshotDirChanged = YES;
        break;
    }

    if (!screenshotDirChanged)
        return;

    NSSet* newEntries = [info createdFiles];
    NSString* pattern = [[info localizedScreenshotPattern] decomposedStringWithCanonicalMapping];
    for (NSString* entry in newEntries) {
        if (![[entry decomposedStringWithCanonicalMapping] isLike:pattern])
        {
            DLog(@"Found file '%@', but does not match '%@'", entry, pattern);
            continue;
        }

        [self uploadScreenshot:entry];
    }
}

- (void) uploadScreenshot:(NSString *)file
{
    UploadInitiator* up = [UploadInitiator uploadFile:file
                                               atPath:[info screenshotPath]
                                               toPath:@"/Public/Screenshots"];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"PromptBeforeUploading"])
    {
        GrowlerGrowl *prompt = [GrowlerGrowl growlWithName:@"Upload Screenshot?"
                                                     title:@"Should we upload the screenshot?"
                                               description:@"If you'd like the screenshot you just took to be uploaded and a link put in your clipboard, click here."];
        prompt.sticky = YES;

        [Growler growl:prompt
             withBlock:^(GrowlerGrowlAction action) {
                 if (action == GrowlerGrowlClicked)
                 {
                     [up moveToWorkQueue];
                     [up upload];
                 }
             }];
    }
    else
    {
        [up moveToWorkQueue];
        [up upload];
    }
}

- (IBAction) browseUploadedScreenshots:(id)sender
{
    // TODO: Support this?
    // https://www.dropbox.com/browse_plain/Public/Screenshots
//    [[NSWorkspace sharedWorkspace] openFile:[info uploadPath]];
}

- (IBAction) uploadFromPasteboard:(id)sender
{
    NSImage* image = [[[NSImage alloc] initWithPasteboard:[NSPasteboard generalPasteboard]] autorelease];
    if (!image)
    {
        GrowlerGrowl *errorGrowl = [GrowlerGrowl growlErrorWithTitle:@"GrabBox could not upload from clipboard!"
                                                         description:@"No image found in the clipboard."];
        [Growler growl:errorGrowl];
        NSLog(@"ERROR: No image found in the clipboard.");
        return;
    }

    NSArray* representations = [image representations];
    NSBitmapImageRep *bits = nil;
    for (NSImageRep* rep in representations)
    {
        if ([rep isKindOfClass:[NSBitmapImageRep class]])
        {
            bits = (NSBitmapImageRep*)rep;
            break;
        }
    }
    
    if (!bits)
    {
        GrowlerGrowl *errorGrowl = [GrowlerGrowl growlErrorWithTitle:@"GrabBox could not upload from clipboard!"
                                                         description:@"No compatible image found in the clipboard."];
        [Growler growl:errorGrowl];
        NSLog(@"ERROR: No compatible image found in the clipboard.");
        return;
    }

    NSData *data = [bits representationUsingType:NSPNGFileType
                                      properties:nil];

    NSError *error;
    NSString *filename = [self workQueueFilenameForClipboardData];
    if (![data writeToFile:filename options:0 error:&error])
    {
        UploadInitiator* up = [UploadInitiator uploadFile:[filename lastPathComponent]
                                                   atPath:[filename stringByDeletingLastPathComponent]
                                                   toPath:@"/Public/Screenshots"];
        [up upload];
    }
    else
    {
        GrowlerGrowl *errorGrowl = [GrowlerGrowl growlErrorWithTitle:@"GrabBox could not write clipboard to disk!"
                                                         description:[error localizedDescription]];
        [Growler growl:errorGrowl];
        NSLog(@"ERROR: %@ (%ld)", [error localizedDescription], [error code]);
    }
}

- (NSString *) workQueueFilenameForClipboardData
{
    NSString *template = [NSString stringWithFormat:@"%@/GrabBoxClipboard.XXXXXX.png", [info workQueuePath]];
    NSUInteger numberOfBytes = [template lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    char *templateBytes = (char *)malloc(numberOfBytes);
    memcpy(templateBytes, [template UTF8String], numberOfBytes);

    mkstemps(templateBytes, strlen(".png"));
    NSString *filename = [NSString stringWithCString:templateBytes
                                            encoding:NSUTF8StringEncoding];
    free(templateBytes);

    return filename;
}

- (IBAction) openFeedback:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://grabbox.devsoft.no/contact/?src=nag"]];
}

- (IBAction) openDonatePref:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://grabbox.devsoft.no/donate/?src=pref"]];
}

- (IBAction) openDonateNag:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://grabbox.devsoft.no/donate/?src=nag"]];
}

- (IBAction) restartLater:(id)sender
{
    [NSApp stopModal];
    [[self restartWindow] performClose:self];
}

- (IBAction) restartApplication:(id)sender
{
    NSString *launcherSource = [[NSBundle bundleForClass:[SUUpdater class]]  pathForResource:@"relaunch" ofType:@""];
    NSString *launcherTarget = [NSTemporaryDirectory() stringByAppendingPathComponent:[launcherSource lastPathComponent]];
    NSString *appPath = [[NSBundle mainBundle] bundlePath];
    NSString *processID = [NSString stringWithFormat:@"%d", [[NSProcessInfo processInfo] processIdentifier]];

    [[NSFileManager defaultManager] removeItemAtPath:launcherTarget error:NULL];
    [[NSFileManager defaultManager] copyItemAtPath:launcherSource toPath:launcherTarget error:NULL];

    [NSTask launchedTaskWithLaunchPath:launcherTarget arguments:[NSArray arrayWithObjects:appPath, processID, nil]];
    [NSApp terminate:sender];
}

#pragma mark DBSession delegate methods

- (void) sessionDidReceiveAuthorizationFailure:(DBSession *)session
{
    NSLog(@"Received authorization failure, disabling app then prompt for link!");
    [self setAccount:nil];
    [self stopMonitoring];
    [self setCanInteract:NO];
    
    [self promptForLink];
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
    DLog(@"Cancelled account link window, terminating.");
    [NSApp terminate:self];
}

#pragma mark DBRestClient delegate methods

- (void)restClient:(DBRestClient*)client
 loadedAccountInfo:(DBAccountInfo*)accountInfo
{
    DLog(@"Got account info, starting FS monitoring and enabling interaction!");
    [self setAccount:accountInfo];
    [self startMonitoring];
    [self setCanInteract:YES];
}

- (void)restClient:(DBRestClient*)client loadAccountInfoFailedWithError:(NSError*)error
{
    NSLog(@"ERROR: Failed retrieving account info: %ld", error.code);
    [NSApp terminate:self];
}

@end

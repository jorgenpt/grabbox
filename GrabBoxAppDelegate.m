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
#import "DropboxDetector.h"

@interface GrabBoxAppDelegate ()
@property (nonatomic, assign) InformationGatherer* info;
@property (nonatomic, retain) Notifier* notifier;
@property (nonatomic, retain) NSMutableArray* detectors;
@end


@implementation GrabBoxAppDelegate

@synthesize setupWindow;
@synthesize restartWindow;
@synthesize nagWindow;
@synthesize menubar;
@synthesize info;
@synthesize notifier;
@synthesize detectors;

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
    [self setDetectors:[NSMutableArray array]];

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
    [self setDetectors:nil];

    [super dealloc];
}

- (int) dropboxId
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"DropboxId"];
}

- (void) setDropboxId:(int) toId
{
    [[NSUserDefaults standardUserDefaults] setInteger:toId forKey:@"DropboxId"];
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
            [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"ShowInDock"];
        }
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[SUUpdater sharedUpdater] setDelegate:self];

    if ([self dropboxId] == 0)
    {
        DropboxDetector* detector = [DropboxDetector dropboxDetectorWithDelegate:self];
        [[self detectors] addObject:detector];
        [detector checkIfRunning];
    }
    else
        [self startMonitoring];
}

- (void) dropboxIsRunning:(BOOL)running
             fromDetector:(DropboxDetector *)detector;
{
    if (running)
    {
        if ([self dropboxId] == 0)
        {
            [NSApp activateIgnoringOtherApps:YES];
            [NSApp runModalForWindow:setupWindow];
        }
        else
        {
            [self startMonitoring];
        }
    }
    else
    {
        [NSApp terminate:self];
    }
    [[self detectors] removeObject:detector];
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
        [[NSUserDefaults standardUserDefaults] setBool:TRUE
                                                forKey:@"HasBeenNagged"];
    }
}

- (void) eventForStream:(ConstFSEventStreamRef)stream
                  paths:(NSArray *)paths
                  flags:(const FSEventStreamEventFlags[])flags
                    ids:(const FSEventStreamEventId[]) ids
{
    NSString* screenshotPath = [info screenshotPath];
    FSRef screenshotPathRef;
    if (![screenshotPath getFSRef:&screenshotPathRef])
    {
        [Growler errorWithTitle:@"GrabBox could not get Screen Grab path!"
                    description:@"Could not find directory to monitor for screenshots."];
        NSLog(@"ERROR: Failed getting FSRef for screenshotPath '%@'", screenshotPath);
        return;
    }

    BOOL screenshotDirChanged = NO;

    for (NSString* path in paths)
    {
        FSRef pathRef;
        if (![path getFSRef:&pathRef])
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
    NSError* error;
    NSFileManager* fm = [NSFileManager defaultManager];
    BOOL mkdirOk = [fm createDirectoryAtPath:[info uploadPath]
                 withIntermediateDirectories:YES
                                  attributes:nil
                                       error:&error];
    if (!mkdirOk)
    {
        [Growler errorWithTitle:@"GrabBox could not copy file!"
                    description:[error localizedDescription]];
        NSLog(@"ERROR: %@ (%i)", [error localizedDescription], [error code]);
        return;
    }

    NSString* pattern = [[info localizedScreenshotPattern] decomposedStringWithCanonicalMapping];
    for (NSString* entry in newEntries) {
        if (![[entry decomposedStringWithCanonicalMapping] isLike:pattern])
        {
            DLog(@"Found file '%@', but does not match '%@'", entry, pattern);
            continue;
        }

        UploadInitiator* up = [UploadInitiator uploadFile:entry
                                                   atPath:screenshotPath
                                                   toPath:[info uploadPath]];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"PromptBeforeUploading"])
        {
            [Growler messageWithTitle:@"Should we upload the screenshot?"
                          description:@"If you'd like the screenshot you just took to be uploaded and a link put in your clipboard, click here."
                                 name:@"Upload Screenshot?"
                      delegateContext:[GrowlerDelegateContext contextWithDelegate:up data:nil]
                               sticky:YES];
        }
        else
        {
            [up assertDropboxRunningAndUpload];
        }

    }
}

- (IBAction) browseUploadedScreenshots:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:[info uploadPath]];
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

@end

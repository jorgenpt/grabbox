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
    [self setInfo:[InformationGatherer defaultGatherer]];
    [self setNotifier:[Notifier notifierWithCallback:translateEvent
                                                path:[info screenshotPath]
                                    callbackArgument:self]];
    [self setDetectors:[NSMutableArray array]];
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

    for (NSString* entry in newEntries) {
        if (![entry hasPrefix:[info localizedScreenshotPrefix]])
            continue;

        UploadInitiator* up = [UploadInitiator uploadFile:entry
                                                   atPath:screenshotPath
                                                   toPath:[info uploadPath]
                                                   withId:[self dropboxId]];
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

@end

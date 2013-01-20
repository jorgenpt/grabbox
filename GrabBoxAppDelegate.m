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
#import "UploaderFactory.h"

#ifndef MAC_APP_STORE
#import <Sparkle/SUUpdater.h>
#endif

static NSString * const kPausedKey = @"Paused";

@interface GrabBoxAppDelegate ()

@property (nonatomic, assign) InformationGatherer* info;
@property (nonatomic, retain) Notifier* notifier;
@property (nonatomic, retain) UploadManager *manager;

- (BOOL) isPaused;

- (void) startMonitoring;
- (void) stopMonitoring;

- (void) eventForStream:(ConstFSEventStreamRef)stream
                  paths:(NSArray *)paths
                  flags:(const FSEventStreamEventFlags[])flags
                    ids:(const FSEventStreamEventId[]) ids;

- (void) uploadScreenshot:(NSString *)file;
- (NSString *) workQueueFilenameForClipboardData;

@end

@implementation GrabBoxAppDelegate

static void translateEvent(ConstFSEventStreamRef stream,
                           void *clientCallBackInfo,
                           size_t numEvents,
                           void *eventPathsVoidPointer,
                           const FSEventStreamEventFlags eventFlags[],
                           const FSEventStreamEventId eventIds[]
                           ) {
    NSArray *paths = (NSArray*)eventPathsVoidPointer;
    [(id)clientCallBackInfo eventForStream:stream
                                     paths:paths
                                     flags:eventFlags
                                       ids:eventIds];
}

- (void) awakeFromNib
{
#ifdef MAC_APP_STORE
    [[self.checkForUpdatesMenuItem menu] removeItem:self.checkForUpdatesMenuItem];
    [[self.checkForUpdatesMenubarItem menu] removeItem:self.checkForUpdatesMenubarItem];
#else
    [[SUUpdater alloc] init];
    [[SUUpdater sharedUpdater] setDelegate:self];
#endif

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(uploaderAvailable:)
                                                 name:GBUploaderAvailableNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(uploaderUnavailable:)
                                                 name:GBUploaderUnavailableNotification
                                               object:nil];

    [self setInfo:[InformationGatherer defaultGatherer]];
    [self setNotifier:[Notifier notifierWithCallback:translateEvent
                                                path:[self.info screenshotPath]
                                    callbackArgument:self]];
    [self setManager:[[[UploadManager alloc] init] autorelease]];

    [[self menubar] show];
}

- (IBAction)checkForUpdates:(id)sender
{
#ifndef MAC_APP_STORE
    [[SUUpdater sharedUpdater] checkForUpdates:sender];
#endif
}

- (void) dealloc
{
    [self setInfo:nil];
    [self setNotifier:nil];

    [super dealloc];
}

#ifndef MAC_APP_STORE
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
#endif

- (void) applicationWillFinishLaunching:(NSNotification *)aNotification
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

	NSString *defaultsPath = [[NSBundle mainBundle] pathForResource:@"Defaults"
                                                          ofType:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:defaultsPath];
    if (defaults)
        [userDefaults registerDefaults:defaults];

#if !defined(MAC_APP_STORE)
    [userDefaults setBool:YES forKey:@"SUSendProfileInfo"];
#endif

#if defined(DEBUG)
    [[DMTracker defaultTracker] disable];
#endif

    [[DMTracker defaultTracker] startWithApplicationId:@"916d325cf9e94b76b6d9f85cbc8b733f"];

    NSString* value = (NSString*)CFPreferencesCopyValue(CFSTR("type"), CFSTR("com.apple.screencapture"),
                                                        kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    [value autorelease];

    if (value == nil || ![value isKindOfClass:[NSString class]])
        value = @"Not set / invalid value";

    [[DMTracker defaultTracker] trackEvent:@"Screencapture type"
                            withProperties:@{@"Type": value}];
}

- (void) uploaderUnavailable:(NSNotification *)aNotification
{
    [self stopMonitoring];
    [self setCanInteract:NO];
}

- (void) uploaderAvailable:(NSNotification *)aNotification
{
    [self startMonitoring];
    [self setCanInteract:YES];
    for (NSString *entry in [self.info filesInDirectory:[self.info workQueuePath]])
    {
        if ([entry hasPrefix:@"."])
            continue;
        
        Uploader* up = [[UploaderFactory defaultFactory] uploaderForFile:entry
                                                             inDirectory:[self.info workQueuePath]];
        [self.manager scheduleUpload:up];
    }
}

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self uploaderUnavailable:nil];

    if (expired())
    {
        [self.betaExpiredWindow makeKeyAndOrderFront:self];
        [NSApp activateIgnoringOtherApps:YES];
    }
    else
    {
        [[UploaderFactory defaultFactory] loadSettings];
    }
}

- (BOOL) isPaused
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kPausedKey];
}

- (void) startMonitoring
{
    [self.notifier start];
}

- (void) stopMonitoring
{
    [self.notifier stop];
}

- (void) eventForStream:(ConstFSEventStreamRef)stream
                  paths:(NSArray *)paths
                  flags:(const FSEventStreamEventFlags[])flags
                    ids:(const FSEventStreamEventId[]) ids
{
    if ([self isPaused]) {
        // We call this to update our idea of what the dir contents is,
        // so that we ignore any files that appear while being paused.
        [self.info createdFiles];
        DLog(@"App paused, ignoring FS event.");
        return;
    }

    NSString* screenshotPath = [self.info screenshotPath];
    FSRef screenshotPathRef;
    if (![screenshotPath fsRef:&screenshotPathRef])
    {
        GrowlerGrowl *errorGrowl = [GrowlerGrowl growlErrorWithTitle:@"GrabBox could not get Screen Grab path!"
                                                         description:@"Could not find directory to monitor for screenshots."];
        [Growler growl:errorGrowl];
        ErrorLog(@"Failed getting FSRef for screenshotPath '%@'", screenshotPath);
        return;
    }

    BOOL screenshotDirChanged = NO;

    for (NSString* path in paths)
    {
        FSRef pathRef;
        if (![path fsRef:&pathRef])
        {
            ErrorLog(@"Failed getting FSRef for path '%@'", path);
            continue;
        }

        OSErr comparison = FSCompareFSRefs(&screenshotPathRef, &pathRef);
        if (comparison == diffVolErr || comparison == errFSRefsDifferent)
        {
            continue;
        }

        if (comparison != noErr)
        {
            ErrorLog(@"Failed comparing FSRef for path (%@) and screenshotPath (%@): %i", path, screenshotPath, comparison);
            continue;
        }

        screenshotDirChanged = YES;
        break;
    }

    if (!screenshotDirChanged)
        return;

    NSSet* newEntries = [self.info createdFiles];
    NSString* pattern = [[self.info localizedScreenshotPattern] decomposedStringWithCanonicalMapping];
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
    Uploader* up = [[UploaderFactory defaultFactory] uploaderForFile:file
                                                         inDirectory:[self.info screenshotPath]];
    [up moveToWorkQueue];
    [self.manager scheduleUpload:up];
}

- (IBAction) uploadFromPasteboard:(id)sender
{
    [[DMTracker defaultTracker] trackEvent:@"Clipboard Upload"];
    NSImage* image = [[[NSImage alloc] initWithPasteboard:[NSPasteboard generalPasteboard]] autorelease];
    if (!image)
    {
        GrowlerGrowl *errorGrowl = [GrowlerGrowl growlErrorWithTitle:@"GrabBox could not upload from clipboard!"
                                                         description:@"No image found in the clipboard."];
        [Growler growl:errorGrowl];
        ErrorLog(@"No image found in the clipboard.");
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
        ErrorLog(@"No compatible image found in the clipboard.");
        return;
    }

    NSData *data = [bits representationUsingType:NSPNGFileType
                                      properties:nil];

    NSError *error;
    NSString *filename = [self workQueueFilenameForClipboardData];
    if (![data writeToFile:filename options:0 error:&error])
    {
        Uploader* up = [[UploaderFactory defaultFactory] uploaderForFile:[filename lastPathComponent]
                                                             inDirectory:[filename stringByDeletingLastPathComponent]];
        [self.manager scheduleUpload:up];
    }
    else
    {
        GrowlerGrowl *errorGrowl = [GrowlerGrowl growlErrorWithTitle:@"GrabBox could not write clipboard to disk!"
                                                         description:[error localizedDescription]];
        [Growler growl:errorGrowl];
        ErrorLog(@"%@ (%ld)", [error localizedDescription], [error code]);
    }
}

- (IBAction) logout:(id)sender
{
    [[UploaderFactory defaultFactory] logout];
}

- (NSString *) workQueueFilenameForClipboardData
{
    NSString *template = [NSString stringWithFormat:@"%@/GrabBoxClipboard.XXXXXX.png", [self.info workQueuePath]];
    NSUInteger numberOfBytes = [template lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    char *templateBytes = (char *)malloc(numberOfBytes);
    memcpy(templateBytes, [template UTF8String], numberOfBytes);

    mkstemps(templateBytes, strlen(".png"));
    NSString *filename = [NSString stringWithCString:templateBytes
                                            encoding:NSUTF8StringEncoding];
    free(templateBytes);

    return filename;
}

- (void)windowWillClose:(NSNotification *)notification
{
    if ([notification object] == self.betaExpiredWindow)
    {
        [NSApp terminate:self];
    }
}

@end

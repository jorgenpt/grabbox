//
//  GrabBoxAppDelegate.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/8/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "GrabBoxAppDelegate.h"

#if !defined(MAC_APP_STORE)
# import <Fabric/Fabric.h>
# import <Crashlytics/Crashlytics.h>
# import <Sparkle/SUUpdater.h>
#endif // !defined(MAC_APP_STORE)

#import "Growler.h"
#import "UploaderFactory.h"

static NSString * const kPausedKey = @"Paused";

@interface GrabBoxAppDelegate () <NotifierDelegate>

@property (nonatomic, weak) InformationGatherer* info;
@property (nonatomic, strong) Notifier* notifier;
@property (nonatomic, strong) UploadManager *manager;

- (BOOL) isPaused;

- (void) startMonitoring;
- (void) stopMonitoring;

- (void) uploadScreenshot:(NSString *)file;
- (NSString *) workQueueFilenameForClipboardData;

@end

@implementation GrabBoxAppDelegate

- (void) awakeFromNib
{
#if !defined(MAC_APP_STORE)
    [[self.checkForUpdatesMenuItem menu] removeItem:self.checkForUpdatesMenuItem];
    [[self.checkForUpdatesMenubarItem menu] removeItem:self.checkForUpdatesMenubarItem];
#endif // !defined(MAC_APP_STORE)

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(uploaderAvailable:)
                                                 name:GBUploaderAvailableNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(uploaderUnavailable:)
                                                 name:GBUploaderUnavailableNotification
                                               object:nil];

    [self setInfo:[InformationGatherer defaultGatherer]];
    [self setNotifier:[Notifier notifierWithDelegate:self
                                                path:[self.info screenshotPath]]];
    [self setManager:[[UploadManager alloc] init]];

    [[self menubar] show];
}

- (IBAction)checkForUpdates:(id)sender
{
#if !defined(MAC_APP_STORE)
    [[SUUpdater sharedUpdater] checkForUpdates:sender];
#endif // !defined(MAC_APP_STORE)
}

- (void) dealloc
{
    [self setInfo:nil];

}

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
#endif // !defined(MAC_APP_STORE)

    [[UploaderFactory defaultFactory] applicationWillFinishLaunching];
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
#if !defined(MAC_APP_STORE)
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"NSApplicationCrashOnExceptions": @YES }];

    NSURL* resourceURL = [[NSBundle mainBundle] URLForResource:@"fabric"
                                                 withExtension:@"apikey"];
    NSString* fabricAPIKey = [NSString stringWithContentsOfURL:resourceURL
                                                  usedEncoding:NULL
                                                         error:NULL];

    // The string that results from reading the bundle resource contains a trailing
    // newline character, which we must remove now because Fabric/Crashlytics
    // can't handle extraneous whitespace.
    NSString* fabricAPIKeyTrimmed = [fabricAPIKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    // Crashlytics calls [Fabric with:...] behind the scenes
    [Crashlytics startWithAPIKey:fabricAPIKeyTrimmed];
#endif // !defined(MAC_APP_STORE)

    [self uploaderUnavailable:nil];

    [[UploaderFactory defaultFactory] loadSettings];
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

- (void) eventForPaths:(NSArray *)paths
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

    NSURL* screenshotPath = [[NSURL fileURLWithPath:[self.info screenshotPath]] URLByResolvingSymlinksInPath];

    BOOL screenshotDirChanged = NO;
    for (NSString* changedPath in paths)
    {
        NSURL *pathURL = [[NSURL fileURLWithPath:changedPath] URLByResolvingSymlinksInPath];
        if (![screenshotPath isEqual:pathURL])
        {
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
    NSImage* image = [[NSImage alloc] initWithPasteboard:[NSPasteboard generalPasteboard]];
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
                                      properties:@{}];

    NSError *error;
    NSString *filename = [self workQueueFilenameForClipboardData];
    if ([data writeToFile:filename options:0 error:&error])
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
    NSUInteger numberOfBytes = [template lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 1;
    char *templateBytes = (char *)malloc(numberOfBytes);
    memcpy(templateBytes, [template UTF8String], numberOfBytes);

    mkstemps(templateBytes, strlen(".png"));
    NSString *filename = [NSString stringWithCString:templateBytes
                                            encoding:NSUTF8StringEncoding];
    free(templateBytes);

    return filename;
}

@end

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
@end


@implementation GrabBoxAppDelegate

@synthesize setupWindow;
@synthesize info;
@synthesize notifier;

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
}

- (void) dealloc
{
    [self setInfo:nil];
    [self setNotifier:nil];
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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSUserDefaults* u = [NSUserDefaults standardUserDefaults];
    if (![u integerForKey:@"DropboxId"])
        [u setInteger:[u integerForKey:@"dropboxId"] forKey:@"DropboxId"];
    [u removeObjectForKey:@"dropboxId"];
    if (![u boolForKey:@"PromptBeforeUploading"])
        [u setBool:[u boolForKey:@"promptBeforeUploading"] forKey:@"PromptBeforeUploading"];
    [u removeObjectForKey:@"promptBeforeUploading"];
    if (![u boolForKey:@"UseDirectLink"])
        [u setBool:[u boolForKey:@"useDirectLink"] forKey:@"UseDirectLink"];
    [u removeObjectForKey:@"useDirectLink"];

    if ([self dropboxId] == 0)
        [DropboxDetector assertDropboxRunningWithDelegate:self];
    else
        [self startMonitoring];
}

- (void) dropboxIsRunning:(BOOL) running
{
    if (running)
    {
        if ([self dropboxId] == 0)
        {
            [setupWindow makeKeyAndOrderFront:self];
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
        [Growler errorWithTitle:@"Could not get Screen Grab path!"
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
        [Growler errorWithTitle:@"Could not copy file!"
                    description:[error localizedDescription]];
        NSLog(@"ERROR: %@ (%i)", [error localizedDescription], [error code]);
        return;
    }

    for (NSString* entry in newEntries) {
        if (![entry hasPrefix:@"Screen shot "])
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
            [DropboxDetector assertDropboxRunningWithDelegate:up];
        }

    }
}

@end

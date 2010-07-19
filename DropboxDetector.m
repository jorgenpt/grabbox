//
//  DropboxDetector.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/15/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "DropboxDetector.h"
#import "ProcessIsRunningWithBundleID.h"

@implementation DropboxDetector

@synthesize notRunning;
@synthesize notInstalled;
@synthesize delegate;

+ (id)dropboxDetectorWithDelegate:(id <DropboxDetectorDelegate>) notifiedDelegate
{
    return [[[self alloc] initWithDelegate:notifiedDelegate] autorelease];
}

- (id)initWithDelegate:(id <DropboxDetectorDelegate>) notifiedDelegate
{
    if (self = [super init])
    {
        [self setDelegate:notifiedDelegate];
    }
    
    return self;
}

- (void) dealloc
{
    [self setDelegate:nil];
    
    [super dealloc];
}

- (void) awakeFromNib
{
#if (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5)
    if (!ProcessIsRunningWithBundleID(CFSTR("com.getdropbox.dropbox"), NULL))
#else
    NSArray* apps = [NSRunningApplication
                     runningApplicationsWithBundleIdentifier:@"com.getdropbox.dropbox"];
    if ([apps count] < 1)
#endif
    {
        NSString *path = [[NSWorkspace sharedWorkspace]
                          absolutePathForAppBundleWithIdentifier:@"com.getdropbox.dropbox"];
        if (path)
        {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"AutostartDropboxIfNeeded"])
                [self startDropbox:self];
            else
            {
                [NSApp activateIgnoringOtherApps:YES];
                [NSApp runModalForWindow:[self notRunning]];
            }
        }
        else
        {
            [NSApp activateIgnoringOtherApps:YES];
            [NSApp runModalForWindow:[self notInstalled]];
        }
    }
    else
        [[self delegate] dropboxIsRunning:YES fromDetector:self];
    [[self notRunning] close];
    [[self notInstalled] close];
}

- (void) checkIfRunning
{
    [NSBundle loadNibNamed:@"DropboxDetector" owner:self];
}

- (IBAction) startDropbox:(id) sender
{
    if ([[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.getdropbox.dropbox"
                                                             options:0
                                      additionalEventParamDescriptor:[NSAppleEventDescriptor nullDescriptor]
                                                    launchIdentifier:NULL])
    { 
        [[self delegate] dropboxIsRunning:YES fromDetector:self];
    }
    else
        [[self delegate] dropboxIsRunning:NO fromDetector:self];
    [NSApp stopModal];
}

- (IBAction) doNotStartDropbox:(id) sender
{
    [[self delegate] dropboxIsRunning:NO fromDetector:self];
    [NSApp stopModal];
}

- (IBAction) openDropboxSite:(id) sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.dropbox.com"]];
}

@end

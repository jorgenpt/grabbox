//
//  DropboxDetector.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/15/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "DropboxDetector.h"


@implementation DropboxDetector

@synthesize notRunning;
@synthesize notInstalled;
@synthesize delegate;

+ (void)assertDropboxRunningWithDelegate:(id <DropboxDetectorDelegate>) notifiedDelegate
{
    [[[self dropboxDetectorWithDelegate:notifiedDelegate] retain] checkIfRunning];
}

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
    NSArray* apps = [NSRunningApplication
                     runningApplicationsWithBundleIdentifier:@"com.getdropbox.dropbox"];
    if ([apps count] < 1)
    {
        NSString *path = [[NSWorkspace sharedWorkspace]
                          absolutePathForAppBundleWithIdentifier:@"com.getdropbox.dropbox"];
        if (path)
        {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"AutostartDropboxIfNeeded"])
                [self startDropbox:self];
            else
                [NSApp runModalForWindow:[self notRunning]];
        }
        else
                [NSApp runModalForWindow:[self notInstalled]];
    }
    else
        [[self delegate] dropboxIsRunning:YES];
    [[self notRunning] close];
    [[self notInstalled] close];
    [self autorelease];
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
        [[self delegate] dropboxIsRunning:YES];
    }
    else
        [[self delegate] dropboxIsRunning:NO];
    [NSApp stopModal];
}

- (IBAction) doNotStartDropbox:(id) sender
{
    [[self delegate] dropboxIsRunning:NO];
    [NSApp stopModal];
}

- (IBAction) openDropboxSite:(id) sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.dropbox.com"]];
}

@end

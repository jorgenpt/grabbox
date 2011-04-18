//
//  Setup.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/10/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "Setup.h"

@interface Setup ()
@property (nonatomic, retain) NSTimer *timer;
@end

@implementation Setup

@synthesize window;
@synthesize linkOk;
@synthesize autoLaunch;
@synthesize appDelegate;
@synthesize dropboxId;
@synthesize timer;

- (void) awakeFromNib
{
    [self setTimer:nil];
    [self setDropboxId:0];
}

- (void) dealloc
{
    [[self timer] invalidate];
    [self setTimer:nil];
    [super dealloc];
}

- (IBAction) pressedOk:(id) sender
{
    if (![self dropboxId] && autoLaunch)
    {
        NSAlert* alert = [NSAlert alertWithMessageText:nil
                                         defaultButton:nil
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"You must copy a Dropbox Public link to continue!"];
        [alert setIcon:[NSImage imageNamed:NSImageNameCaution]];
        [alert beginSheetModalForWindow:window
                          modalDelegate:nil
                         didEndSelector:nil
                            contextInfo:nil];
    }
    else
    {
        [appDelegate setDropboxId:[self dropboxId]];

        if (autoLaunch)
            [appDelegate startMonitoring];

        [[self timer] invalidate];
        [self setTimer:nil];
        [self setDropboxId:0];

        [window close];
        [NSApp stopModal];
    }
}

- (IBAction) pressedCancel:(id) sender
{
    [[self timer] invalidate];
    [self setTimer:nil];
    [self setDropboxId:0];

    if (autoLaunch)
        [[NSApplication sharedApplication] terminate:self];
    else
        [window close];
    [NSApp stopModal];
}

- (IBAction) openPublicFolder:(id) sender
{
    [[NSWorkspace sharedWorkspace] openFile:[[InformationGatherer defaultGatherer] publicPath]];
}

- (void) windowDidBecomeKey:(NSNotification *) aNotification
{
    if (!timer)
    {
        [linkOk setState:NSOffState];
        timer = [[NSTimer scheduledTimerWithTimeInterval: 0.5
                                                  target: self
                                                selector: @selector(checkClipboard:)
                                                userInfo: nil
                                                 repeats: YES] retain];

        if (autoLaunch)
        {
            if ([autoLaunch state] != NSOnState)
                [autoLaunch performClick:self];
            [[NSRunLoop currentRunLoop] addTimer:timer
                                         forMode:NSModalPanelRunLoopMode];
        }

    }
}


- (void) checkClipboard:(NSTimer *) timer
{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSString *urlString = nil;
    DLog(@"Checking clipboard for updates.");

#if (MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_5)
    urlString = [pasteboard stringForType:NSStringPboardType];
#else
    NSArray *classes = [NSArray arrayWithObjects:[NSString class], nil];
    NSDictionary *options = [NSDictionary dictionary];
    NSArray *copiedItems = [pasteboard readObjectsForClasses:classes options:options];
    if (copiedItems && [copiedItems count] > 0)
        urlString = [copiedItems objectAtIndex:0];
#endif

    if (!urlString)
    {
        DLog(@"No urlString.");
        return;
    }

    NSURL *url = [NSURL URLWithString:urlString];
    if (!url)
    {
        DLog(@"urlString '%@' is not valid.", urlString);
        return;
    }

    if ([[url host] hasSuffix:@".dropbox.com"])
    {
#if (MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_5)
        NSArray* components = [[url path] pathComponents];
#else
        NSArray* components = [url pathComponents];
#endif
        NSString* dirComponent = [components objectAtIndex:1];
        if (![dirComponent isEqualToString:@"u"])
            return;

        NSString* idComponent = [components objectAtIndex:2];
        int idFromUrl = [idComponent intValue];
        if (idFromUrl)
        {
            [self setDropboxId:idFromUrl];
            [linkOk setState:NSOnState];
        }
        else
        {
            [linkOk setState:NSOffState];
        }
    }
    else
    {
        DLog(@"urlString '%@' is not under host *.dropbox.com.", urlString);
    }
}

@end

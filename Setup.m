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
    int oldDropId = [appDelegate dropboxId];
    if (![self dropboxId] && !oldDropId)
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

        if (!oldDropId)
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

    if (![appDelegate dropboxId])
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

        if (![appDelegate dropboxId])
        {
            if ([autoLaunch state] != NSOnState)
                [autoLaunch performClick:self];
        }

        timer = [[NSTimer scheduledTimerWithTimeInterval: 0.5
                                                  target: self
                                                selector: @selector(checkClipboard:)
                                                userInfo: nil
                                                 repeats: YES] retain];
        [[NSRunLoop currentRunLoop] addTimer:timer
                                     forMode:NSModalPanelRunLoopMode];

    }
}


- (void) checkClipboard:(NSTimer *) timer
{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSArray *classes = [NSArray arrayWithObjects:[NSString class], nil];
    NSDictionary *options = [NSDictionary dictionary];
    NSArray *copiedItems = [pasteboard readObjectsForClasses:classes options:options];
    if (!copiedItems)
        return;

    NSURL *url = [NSURL URLWithString:[copiedItems objectAtIndex:0]];
    if (!url)
        return;

    if ([[url host] hasSuffix:@".dropbox.com"])
    {
        NSArray* components = [url pathComponents];
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
}

@end

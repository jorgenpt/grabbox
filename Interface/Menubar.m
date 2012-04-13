//
//  Menubar.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 10/1/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "Menubar.h"

#import "UploaderFactory.h"


@implementation Menubar

@synthesize item;
@synthesize menu;
@synthesize preferencesWindow;

- (void) dealloc
{
    [self setItem:nil];

    [super dealloc];
}

- (void) show
{
    [self setItem:[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength]];
    [[self item] setMenu:[self menu]];
    [[self item] setTarget:self];
    [[self item] setHighlightMode:YES];
    [[self item] setEnabled:YES];
    [[self item] setImage:[NSImage imageNamed:@"menuicon.png"]];
    [[self item] setAlternateImage:[NSImage imageNamed:@"menuiconInverted.png"]];

}

- (void) hide
{
    [[NSStatusBar systemStatusBar] removeStatusItem:[self item]];
    [self setItem:nil];
}

- (IBAction) showAbout:(id)sender
{
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp orderFrontStandardAboutPanel:sender];
}

- (IBAction) showPreferences:(id)sender;
{
    [NSApp activateIgnoringOtherApps:YES];
    [[self preferencesWindow] makeKeyAndOrderFront:sender];
}

- (void)menuWillOpen:(NSMenu *)menu
{
    [[NSNotificationCenter defaultCenter] postNotificationName:GBGainedFocusNotification
                                                        object:self];
}

@end

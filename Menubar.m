//
//  Menubar.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 10/1/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "Menubar.h"


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
    [[self item] setTitle:@"GB"];
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

@end

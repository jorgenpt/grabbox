//
//  Preferences.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "Preferences.h"

#import "UploaderFactory.h"
#import "GrabBoxAppDelegate.h"

@implementation Preferences

@synthesize preferences;

- (void) awakeFromNib
{
    [(GrabBoxAppDelegate *)[NSApp delegate] addObserver:self
                                             forKeyPath:@"canInteract"
                                                options:0
                                                context:NULL];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                         change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"canInteract"])
    {
        BOOL canInteract = [(GrabBoxAppDelegate *)[NSApp delegate] canInteract];
        if (!canInteract && [preferences isVisible])
            [preferences orderOut:self];
    }
}

- (BOOL) willLaunchAtLogin
{
    NSString* appPath = [[NSBundle mainBundle] bundlePath];
    NSArray* autoLaunch = (NSArray*)CFPreferencesCopyAppValue(CFSTR("AutoLaunchedApplicationDictionary"),
                                                              CFSTR("loginwindow"));
    [autoLaunch autorelease];
    for (NSDictionary* dict in autoLaunch)
    {
        NSString* path = [dict objectForKey:@"Path"];
        if ([path isEqual:appPath])
            return YES;
    }
    return NO;
}

- (void) setWillLaunchAtLogin:(BOOL)state
{
    NSString* appPath = [[NSBundle mainBundle] bundlePath];
    NSArray* autoLaunch = (NSArray*)CFPreferencesCopyAppValue(CFSTR("AutoLaunchedApplicationDictionary"),
                                                              CFSTR("loginwindow"));
    [autoLaunch autorelease];
    NSMutableArray* autoLaunchMutable;

    if (state)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:0], @"Hide",
                              appPath, @"Path",
                              nil];

        autoLaunchMutable = [[autoLaunch mutableCopy] autorelease];
        [autoLaunchMutable addObject:info];
    }
    else
    {
        NSString* appName = [appPath lastPathComponent];
        autoLaunchMutable = [NSMutableArray arrayWithCapacity:[autoLaunch count]];
        for (NSDictionary* dict in autoLaunch)
        {
            NSString* path = [dict objectForKey:@"Path"];
            if (![[path lastPathComponent] isEqual:appName])
                [autoLaunchMutable addObject:dict];
        }
    }
    CFPreferencesSetAppValue(CFSTR("AutoLaunchedApplicationDictionary"), autoLaunchMutable, CFSTR("loginwindow"));
    CFPreferencesAppSynchronize(CFSTR("loginwindow"));
}

- (IBAction) changeUploadService:(id)sender
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CONFIG(Host)];
}


@end

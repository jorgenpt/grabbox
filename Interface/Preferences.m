//
//  Preferences.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "Preferences.h"

@implementation Preferences

@synthesize preferences;

- (BOOL) usingCompressedScreenshots
{
    NSString* value = (NSString*)CFPreferencesCopyValue(CFSTR("type"), CFSTR("com.apple.screencapture"),
                                                        kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    [value autorelease];

    return (value != nil
            && [value isKindOfClass:[NSString class]]
            && [(NSString *)value isEqualToString:@"jpg"]);
}

- (void) setUsingCompressedScreenshots:(BOOL)state
{
    if (state)
    {
        CFPreferencesSetValue(CFSTR("type"), CFSTR("jpg"), CFSTR("com.apple.screencapture"),
                              kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        DLog(@"Enabling jpg");
    }
    else
    {
        CFPreferencesSetValue(CFSTR("type"), NULL, CFSTR("com.apple.screencapture"),
                              kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        DLog(@"Disabling jpg");
    }

    if (!CFPreferencesSynchronize(CFSTR("com.apple.screencapture"),
                                  kCFPreferencesCurrentUser,
                                  kCFPreferencesAnyHost))
    {
        NSLog(@"Prefernce sync of com.apple.screencapture failed (for compression)");
    }

    NSAlert* alert = [NSAlert alertWithMessageText:@"Logout required"
                                     defaultButton:nil
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@"Changing OS X to use JPEG requires that you log out and in again before it takes effect."];
    [alert beginSheetModalForWindow:[self preferences]
                      modalDelegate:nil
                     didEndSelector:nil
                        contextInfo:nil];
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


@end

//
//  Preferences.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "Preferences.h"

@implementation Preferences

- (BOOL) willLaunchAtLogin
{
    NSString* appPath = [[NSBundle mainBundle] bundlePath];
    NSArray* autoLaunch = (NSArray*)CFPreferencesCopyAppValue(CFSTR("AutoLaunchedApplicationDictionary"),
                                                              CFSTR("loginwindow"));
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
    NSMutableArray* autoLaunchMutable;

    if (state)
    {
        NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:0], @"Hide",
                              appPath, @"Path",
                              nil];

        autoLaunchMutable = [autoLaunch mutableCopy];
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

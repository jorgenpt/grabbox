//
//  AppDelegate.m
//  GrabBoxHelper
//
//  Created by Jørgen Tjernø on 12/1/12.
//  Copyright (c) 2012 bitSpatter. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Check if main app is already running; if yes, do nothing and terminate helper app
    BOOL alreadyRunning = NO;
    NSArray *running = [[NSWorkspace sharedWorkspace] runningApplications];
    for (NSRunningApplication *app in running) {
        NSString *identifier = [app bundleIdentifier];
        NSLog(@"Identifier: %@", identifier);
        alreadyRunning = [identifier isEqualToString:@"com.bitspatter.grabbox2"];
        alreadyRunning = alreadyRunning || [identifier isEqualToString:@"com.bitspatter.mac.grabbox2"];
        if (alreadyRunning) {
            break;
        }
    }

    if (!alreadyRunning) {
        NSString *path = [[NSBundle mainBundle] bundlePath];
        NSArray *p = [path pathComponents];
        NSMutableArray *pathComponents = [NSMutableArray arrayWithArray:p];
        [pathComponents removeLastObject];
        [pathComponents removeLastObject];
        [pathComponents removeLastObject];
        [pathComponents addObject:@"MacOS"];
        [pathComponents addObject:@"GrabBox"];
        NSString *newPath = [NSString pathWithComponents:pathComponents];
        NSLog(@"Launching main GrabBox app: %@", newPath);
        [[NSWorkspace sharedWorkspace] launchApplication:newPath];
    }
    
    [NSApp terminate:nil];
}

@end

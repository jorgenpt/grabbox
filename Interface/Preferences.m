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

#import <ServiceManagement/ServiceManagement.h>

static NSString * const kHelperAppIdentifier = @"com.bitspatter.GrabBoxHelper";

@implementation Preferences

- (BOOL) willLaunchAtLogin
{
    // > As of WWDC 2017, Apple engineers have stated that [SMCopyAllJobDictionaries] is still the preferred API to use.
    //  - https://github.com/alexzielenski/StartAtLoginController/issues/12#issuecomment-307525807
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CFArrayRef cfJobDicts = SMCopyAllJobDictionaries(kSMDomainUserLaunchd);
#pragma pop
    NSArray* jobDicts = CFBridgingRelease(cfJobDicts);

    if (jobDicts && [jobDicts count] > 0) {
        for (NSDictionary* job in jobDicts) {
            if ([kHelperAppIdentifier isEqualToString:[job objectForKey:@"Label"]]) {
                return [[job objectForKey:@"OnDemand"] boolValue];
            }
        }
    }

    return NO;
}

- (void) setWillLaunchAtLogin:(BOOL)state
{
    NSString *baseDirectory = [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent];
    if (state && ![baseDirectory hasSuffix:@"/Applications"]) {
        // TODO: Show an error to the user?
        NSLog(@"Can't enable autostart! Application needs to live in /Applications or ~/Application, lives in %@", baseDirectory);
        [self.autostartItem setState:NSOffState];
        return;
    }

    if (!SMLoginItemSetEnabled((__bridge CFStringRef)kHelperAppIdentifier, state)) {
        [self.autostartItem setState:(state ? NSOffState : NSOnState)];
        NSLog(@"Could not set launch at login state %i, app lives in %@", state, baseDirectory);
    }
}

@end

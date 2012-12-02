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
    CFArrayRef cfJobDicts = SMCopyAllJobDictionaries(kSMDomainUserLaunchd);
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
        NSLog(@"Can't enable autostart! Application needs to live in /Applications or ~/Application, lives in %@", baseDirectory);
        return;
    }

    if (!SMLoginItemSetEnabled((CFStringRef)kHelperAppIdentifier, state)) {
        NSLog(@"Could not set launch at login state %i, app lives in %@", state, baseDirectory);
    }
}

- (IBAction) changeUploadService:(id)sender
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:CONFIG(Host)];
}


@end

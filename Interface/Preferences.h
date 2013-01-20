//
//  Preferences.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Preferences : NSObject

@property (assign) IBOutlet NSMenuItem *autostartItem;

- (BOOL) willLaunchAtLogin;
- (void) setWillLaunchAtLogin:(BOOL)state;

@end

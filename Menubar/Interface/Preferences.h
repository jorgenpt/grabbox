//
//  Preferences.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright (C) 2014 Jørgen P. Tjernø. Licensed under GPLv2, see LICENSE in the project root for more info.
//

#import <Cocoa/Cocoa.h>

@interface Preferences : NSObject

@property (assign) IBOutlet NSMenuItem *autostartItem;

- (BOOL) willLaunchAtLogin;
- (void) setWillLaunchAtLogin:(BOOL)state;

@end

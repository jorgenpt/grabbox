//
//  Preferences.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Preferences : NSObject {
    NSWindow* window;
}

@property (assign) IBOutlet NSWindow *window;

- (void) awakeFromNib;

- (BOOL) willLaunchAtLogin;
- (void) setWillLaunchAtLogin:(BOOL)state;

@end

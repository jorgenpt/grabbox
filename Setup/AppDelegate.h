//
//  AppDelegate.h
//  GrabBox
//
//  Created by Jørgen Tjernø on 5/15/13.
//  Copyright (C) 2014 Jørgen P. Tjernø. Licensed under GPLv2, see LICENSE in the project root for more info.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) NSInteger step;

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSBox *contentBox;
@property (assign) IBOutlet NSButton *linkButton;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (assign) IBOutlet NSImageView *step2, *step3;

@end

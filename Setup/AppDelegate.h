//
//  AppDelegate.h
//  GrabBox
//
//  Created by Jørgen Tjernø on 5/15/13.
//  Copyright (c) 2013 bitSpatter. All rights reserved.
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

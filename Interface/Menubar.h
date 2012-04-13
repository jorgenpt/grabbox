//
//  Menubar.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 10/1/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Menubar : NSObject<NSMenuDelegate> {
    NSStatusItem* item;
    NSMenu* menu;
    NSWindow* preferencesWindow;
}

@property (nonatomic, retain) IBOutlet NSStatusItem* item;
@property (assign) IBOutlet NSMenu* menu;
@property (assign) IBOutlet NSWindow* preferencesWindow;

- (void) dealloc;

- (void) show;
- (void) hide;

- (IBAction) showAbout:(id)sender;
- (IBAction) showPreferences:(id)sender;

@end

//
//  Menubar.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 10/1/10.
//  Copyright (C) 2014 Jørgen P. Tjernø. Licensed under GPLv2, see LICENSE in the project root for more info.
//

#import <Cocoa/Cocoa.h>


@interface Menubar : NSObject<NSMenuDelegate>

@property (assign) NSUInteger activityCount;
@property (nonatomic, retain) IBOutlet NSStatusItem* item;
@property (assign) IBOutlet NSMenu* menu;

- (id) init;
- (void) dealloc;

- (void) show;
- (void) startActivity;
- (void) stopActivity;
- (void) hide;

- (IBAction) showAbout:(id)sender;

@end

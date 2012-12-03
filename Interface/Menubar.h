//
//  Menubar.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 10/1/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Menubar : NSObject<NSMenuDelegate>

@property (assign) NSUInteger activityCount;
@property (nonatomic, retain) IBOutlet NSStatusItem* item;
@property (assign) IBOutlet NSMenu* menu;

- (void) dealloc;

- (void) show;
- (void) startActivity;
- (void) stopActivity;
- (void) hide;

- (IBAction) showAbout:(id)sender;

@end

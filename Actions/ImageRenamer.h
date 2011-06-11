//
//  ImageRenamer.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/13/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ImageRenamer : NSObject {
    NSWindow *window;
    NSImageView *imageView;
    NSTextField *name;
    NSImage *image;
    NSString *path;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSImageView *imageView;
@property (assign) IBOutlet NSTextField *name;
@property (nonatomic, retain) NSImage *image;
@property (nonatomic, retain) NSString *path;

+ (id) renamerForFile:(NSString *)path;

- (id) initForFile:(NSString *)path;
- (void) dealloc;

- (void) awakeFromNib;
- (BOOL) windowShouldClose;

- (void) showRenamer;
- (IBAction) clickedOk:(id)sender;

@end

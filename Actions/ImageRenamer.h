//
//  ImageRenamer.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/13/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ImageRenamer : NSObject <DBRestClientDelegate, NSWindowDelegate> {
    DBRestClient *restClient;

    NSImage *image;
    NSString *path;

    NSWindow *window;
    NSButton *renameButton;
    NSProgressIndicator *spinner;
    NSImageView *imageView;
    NSTextField *name;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSButton *renameButton;
@property (assign) IBOutlet NSProgressIndicator *spinner;
@property (assign) IBOutlet NSImageView *imageView;
@property (assign) IBOutlet NSTextField *name;

+ (id) renamerForPath:(NSString *)path withFile:(NSString *)filePath;

- (id) initForPath:(NSString *)path withFile:(NSString *)filePath;

- (void) showRenamer;
- (IBAction) clickedOk:(id)sender;

@end

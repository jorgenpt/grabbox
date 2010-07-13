//
//  FileRenamer.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/13/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlerDelegate.h"

@interface FileRenamer : NSObject <GrowlerDelegate> {
    NSImageView *imageView;
    NSTextField *name;
    NSImage *image;
    NSString *path;
    NSString *url;
}

@property (assign) IBOutlet NSImageView *imageView;
@property (assign) IBOutlet NSTextField *name;
@property (nonatomic, retain) NSImage *image;
@property (nonatomic, retain) NSString *path;
@property (nonatomic, retain) NSString *url;

+ (id) renamerForFile:(NSString *)path
                atURL:(NSString *)url;

- (id) initForFile:(NSString *)path
             atURL:(NSString *)url;
- (void) dealloc;

- (void) showRenamer;
- (void) awakeFromNib;
- (void) growlClickedWithData:(id)data;
- (void) growlTimedOutWithData:(id)data;
- (IBAction) clickedOk:(id)sender;

@end

//
//  Menubar.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 10/1/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "Menubar.h"

#import "UploaderFactory.h"

const NSInteger numAnimationFrames = 8;
NSString * const animationFrameFormat = @"menuicon-animation-%i";

@interface Menubar ()
@property (assign) NSInteger currentFrame;

@property (strong) dispatch_group_t animationLoading;
@property (strong) NSArray *animationFrames;
@property (strong) NSImage *defaultImage, *uploadedImage;
@end

@implementation Menubar

- (id) init
{
    self = [super init];
    if (self) {
        NSMutableArray *animationFrames = [NSMutableArray arrayWithCapacity:numAnimationFrames];
        self.animationLoading = dispatch_group_create();
        self.animationFrames = animationFrames;
        self.uploadedImage = self.defaultImage = [NSImage imageNamed:@"menuicon"];
        self.defaultImage.template = YES;

        dispatch_group_async(self.animationLoading, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            for (int i = 1; i <= numAnimationFrames; ++i) {
                NSString *frameName = [NSString stringWithFormat:animationFrameFormat, i];
                [animationFrames addObject:[NSImage imageNamed:frameName]];
            }
            self.uploadedImage = [NSImage imageNamed:@"menuiconUploaded"];
        });
    }

    return self;
}


- (void) show
{
    [self setItem:[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength]];
    [[self item] setMenu:[self menu]];
    [[self item] setTarget:self];
    [[self item] setHighlightMode:YES];
    [[self item] setEnabled:YES];
    [[self item] setImage:self.defaultImage];
    //[[self item] setAlternateImage:[NSImage imageNamed:@"menuiconInverted"]];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(uploadStarted:)
                                                 name:kUploadStartingNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(uploadFinished:)
                                                 name:kUploadFinishingNotification
                                               object:nil];
}

- (void) uploadStarted:(NSNotification*)aNotification
{
    [self startActivity];
}

- (void) uploadFinished:(NSNotification*)aNotification
{
    [self stopActivity];
}

- (void) hide
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.activityCount = 0;

    [[NSStatusBar systemStatusBar] removeStatusItem:[self item]];
    [self setItem:nil];
}

- (void) startActivity
{
    if (!self.item)
        return;

    @synchronized(self) {
        self.activityCount++;
        if (self.activityCount == 1) {
            self.currentFrame = 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateFrame];
            });
        }
    }
}

- (void) stopActivity
{
    if (!self.item)
        return;

    @synchronized(self) { self.activityCount--; }
}

- (IBAction) showAbout:(id)sender
{
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp orderFrontStandardAboutPanel:sender];
}

- (void)menuWillOpen:(NSMenu *)menu
{
    [[NSNotificationCenter defaultCenter] postNotificationName:GBGainedFocusNotification
                                                        object:self];
}

- (void) updateFrame
{
    if (self.activityCount > 0) {
        if (dispatch_group_wait(self.animationLoading, DISPATCH_TIME_NOW) == 0) {
            NSImage *icon = [self.animationFrames objectAtIndex:self.currentFrame];
            [self.item setImage:icon];

            self.currentFrame = (self.currentFrame + 1) % [self.animationFrames count];
        }

        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.4 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^{
            [self updateFrame];
        });
    } else {
        // TODO: Sound?
        [self.item setImage:self.uploadedImage];
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self.item setImage:self.defaultImage];
        });
    }
}

@end

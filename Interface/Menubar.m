//
//  Menubar.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 10/1/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "Menubar.h"

#import "UploaderFactory.h"


@implementation Menubar

- (void) dealloc
{
    [self setItem:nil];

    [super dealloc];
}

- (void) show
{
    [self setItem:[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength]];
    [[self item] setMenu:[self menu]];
    [[self item] setTarget:self];
    [[self item] setHighlightMode:YES];
    [[self item] setEnabled:YES];
    [[self item] setImage:[NSImage imageNamed:@"menuicon.png"]];
    [[self item] setAlternateImage:[NSImage imageNamed:@"menuiconInverted.png"]];

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
            [self updateFrame];
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
    // TODO: This is slow and hacky.
    static CGFloat angle = 0.0;

    if (self.activityCount <= 0) {
        [[self item] setImage:[NSImage imageNamed:@"menuicon.png"]];
        angle = 0.0f;
        return;
    }

    NSImage *mainIcon = [[[NSImage imageNamed:@"menuicon.png"] copy] autorelease];
    NSImage *overlayIcon = [NSImage imageNamed:@"arrow_rotate.png"];

    [mainIcon lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];

    NSSize overlaySize = [overlayIcon size];
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:overlaySize.width/2.0 yBy:overlaySize.height/2.0];
    [transform rotateByDegrees:angle];
    [transform translateXBy:-overlaySize.width/2.0 yBy:-overlaySize.height/2.0];
    [transform concat];

    NSRect rect = NSMakeRect(0.0, 0.0,
                             overlaySize.width, overlaySize.height);
    [overlayIcon drawInRect:rect
                   fromRect:NSZeroRect
                  operation:NSCompositeSourceOver
                   fraction:1.0];

    [transform invert];
    [transform concat];
    [mainIcon unlockFocus];

    [[self item] setImage:mainIcon];

    angle += 10.0f;
    if (angle >= 360.0f) {
        angle -= 360.0f;
    }

    double delayInSeconds = 0.05;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        [self updateFrame];
    });
}

@end

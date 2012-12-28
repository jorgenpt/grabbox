//
//  Uploader.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "Uploader.h"
#import "Growler.h"
#import "InformationGatherer.h"

#import "ImgurUploader.h"
#import "UploadManager.h"

NSString * const kUploadStartingNotification = @"UploadStarting";
NSString * const kUploadFinishingNotification = @"UploadFinishing";

@implementation Uploader

@synthesize delegate;

@synthesize retries;

@synthesize srcFile;
@synthesize srcPath;

NSString *urlCharacters = @"0123456789abcdefghijklmnopqrstuvwxyz-_";

+ (BOOL) pasteboardURL:(NSString *)url
{
    NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];

    if (![pasteboard setString:url forType:NSStringPboardType])
    {
        NSString *errorDescription = [NSString stringWithFormat:@"Could not put URL '%@' into the clipboard", url];
        GrowlerGrowl *copyError = [GrowlerGrowl growlErrorWithTitle:@"Could not update pasteboard!"
                                                        description:errorDescription];
        copyError.sticky = YES;
        [Growler growl:copyError];

        ErrorLog(@"Couldn't put url '%@' into pasteboard.", url);
        return NO;
    }

    return YES;
}

+ (NSString *) randomStringOfLength:(int)length
{
    NSMutableString* output = [NSMutableString string];

    for (int i = 0; i < length; ++i)
    {
        int character = drand48() * [urlCharacters length];
        [output appendString:[urlCharacters substringWithRange:NSMakeRange(character, 1)]];
    }

    return output;
}

+ (BOOL)hasRetina
{
    for (NSScreen *screen in [NSScreen screens]) {
        if ([screen backingScaleFactor] >= 2.0) {
            return YES;
        }
    }

    return NO;
}

+ (id) uploaderForFile:(NSString *)file
           inDirectory:(NSString *)source
{
    return [[[ImgurUploader alloc] initForFile:file inDirectory:source] autorelease];
}

- (id) init
{
    self = [super init];
    if (self)
    {
        [self setRetries:5];
        [self setSrcFile:nil];
        [self setSrcPath:nil];
    }

    return self;
}

- (id) initForFile:(NSString *)file
            inDirectory:(NSString *)source
{
    self = [self init];
    if (self)
    {
        [self setSrcFile:file];
        [self setSrcPath:[NSString pathWithComponents:[NSArray arrayWithObjects: source, file, nil]]];
    }
    return self;
}

- (void) dealloc
{
    [self setSrcFile:nil];
    [self setSrcPath:nil];

    [super dealloc];
}

- (void) moveToWorkQueue
{
    NSString* newPath = [[[InformationGatherer defaultGatherer] workQueuePath] stringByAppendingPathComponent:srcFile];
    NSError *error;
    BOOL moveOk;

    DLog(@"Trying to move %@ -> %@", srcPath, newPath);
    moveOk = [[NSFileManager defaultManager] moveItemAtPath:srcPath
                                                     toPath:newPath
                                                      error:&error];

    if (moveOk)
    {
        [self setSrcPath:newPath];
    }
    else
    {
        NSLog(@"Could not move file '%@' to workqueue location '%@', trying to upload from current location: %@ (%ld)",
              srcPath, newPath, [error localizedDescription], [error code]);
    }
    
    if ([[self class] hasRetina]) {
        [self downsizeRetinaSource];
    }
}

- (void)downsizeRetinaSource
{
    NSImage *image = [[[NSImage alloc] initWithContentsOfFile:srcPath] autorelease];
    NSBitmapImageRep *imageRep = [[image representations] objectAtIndex:0];
    CGFloat displayScale = [imageRep pixelsWide] / [imageRep size].width;
    NSLog(@"Image displayScale: %f", displayScale);
    if (displayScale >= 1.95)
    {
        NSRect resizedBounds = NSMakeRect(0, 0, [imageRep size].width/displayScale, [imageRep size].height/displayScale);
        NSImage* resizedImage = [[[NSImage alloc] initWithSize:resizedBounds.size] autorelease];

        [resizedImage lockFocus];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationLow];
        [image drawInRect:resizedBounds
                 fromRect:NSZeroRect
                operation:NSCompositeCopy
                 fraction:1.0];
        [resizedImage unlockFocus];

        NSImageRep *rep = [[resizedImage representations] objectAtIndex:0];
        CGImageRef img = [rep CGImageForProposedRect:NULL
                                             context:NULL
                                               hints:nil];
        NSBitmapImageRep* bitmapImageRep = [[NSBitmapImageRep alloc] initWithCGImage:img];
        NSData *imageData = [bitmapImageRep representationUsingType:NSPNGFileType
                                                         properties:nil];
        [imageData writeToFile:srcPath
                    atomically:YES];
    }
}

- (void) upload
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kUploadStartingNotification
                                                        object:self];

    [[DMTracker defaultTracker] trackEventInCategory:@"Usage"
                                            withName:@"Upload"
                                               value:[self className]];
}

- (void) uploadDone
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kUploadFinishingNotification
                                                        object:self];

    if ([delegate respondsToSelector:@selector(uploaderDone:)])
        [delegate uploaderDone:self];
}

@end

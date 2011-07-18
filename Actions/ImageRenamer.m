//
//  ImageRenamer.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/13/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "ImageRenamer.h"
#import "Growler.h"
#import "UploaderFactory.h"
#import "DropboxUploader.h"
#import "URLShortener.h"

@interface ImageRenamer ()
@property (nonatomic, retain) DBRestClient *restClient;
@property (nonatomic, retain) NSImage *image;
@property (nonatomic, retain) NSString *path;
@end

@implementation ImageRenamer

@synthesize restClient;

@synthesize image;
@synthesize path;

@synthesize window;
@synthesize renameButton;
@synthesize spinner;
@synthesize imageView;
@synthesize name;

+ (id) renamerForPath:(NSString *)remotePath withFile:(NSString *)localPath
{
    return [[[self alloc] initForPath:remotePath withFile:localPath] autorelease];
}

- (id) init
{
    self = [super init];
    if (self)
    {
        [self setRestClient:[DBRestClient restClientWithSharedSession]];
        if (!restClient)
        {
            [self release];
            return nil;
        }

        [restClient setDelegate:self];
        [self setPath:nil];
        [self setImage:nil];
    }

    return self;
}

- (id) initForPath:(NSString *)remotePath withFile:(NSString *)localPath
{
    self = [self init];
    if (self)
    {
        [self setPath:remotePath];
        [self setImage:[[[NSImage alloc] initWithContentsOfFile:localPath] autorelease]];
    }
    return self;
}


- (void) dealloc
{
    [restClient setDelegate:nil];
    [self setRestClient:nil];
    [self setImage:nil];
    [self setPath:nil];

    [super dealloc];
}

- (void) awakeFromNib
{
    NSRect windowRect = [[self window] frame];

    NSSize maxSize = [[NSScreen mainScreen] visibleFrame].size;
    NSSize minSize = [[self window] minSize];

    NSSize windowSize = windowRect.size;
    NSSize viewSize = [[self imageView] frame].size;
    NSSize imageSize = [[self image] size];
    NSSize newSize;
    
    float paddingWidth = windowSize.width - viewSize.width;
    float paddingHeight = windowSize.height - viewSize.height;
    
    // + 20 to get the border of the NSImageView. Wonder if there's a better way. :)
    newSize.width = imageSize.width + paddingWidth + 20;
    newSize.height = imageSize.height + paddingHeight + 20;
    
    if (newSize.width > maxSize.width - 20)
    {
        newSize.width = maxSize.width - 20;
        newSize.height = (newSize.width - paddingWidth) * imageSize.height / imageSize.width + paddingHeight;
    }
    
    if (newSize.height > maxSize.height - 20)
    {
        newSize.height = maxSize.height - 20 ;
        newSize.width = (newSize.height - paddingHeight) * imageSize.width / imageSize.height + paddingWidth;
    }

    if (newSize.width < minSize.width)
        newSize.width = minSize.width;
    if (newSize.height < minSize.height)
        newSize.height = minSize.height;

    windowRect.size = newSize;
    [[self window] setFrame:windowRect display:YES];
    [imageView setImage:[self image]];
    
    [[self window] makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}

- (BOOL) windowShouldClose:(id)sender
{
    [self autorelease];
    return YES;
}

- (void) showRenamer
{
    [[DMTracker defaultTracker] trackEventInCategory:@"Usage"
                                            withName:@"Rename"];

    [NSBundle loadNibNamed:@"ImageRenamer" owner:[self retain]];
}

- (IBAction) clickedOk:(id)sender
{
    NSString* inputFilename = [[name stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([inputFilename length] > 0)
    {
        NSString* originalFilename = [[self path] lastPathComponent];
        NSString* extension = [originalFilename pathExtension];
        NSString* filename = [inputFilename stringByAppendingPathExtension:extension];
        NSString* newPath = [[[self path] stringByDeletingLastPathComponent] stringByAppendingPathComponent:filename];

        [spinner startAnimation:self];
        [renameButton setHidden:YES];

        [restClient loadMetadata:newPath];
    } else {
        [[DMTracker defaultTracker] trackEventInCategory:@"Usage"
                                                withName:@"Rename Cancelled"];
        [[self window] performClose:self];
    }
}

#pragma mark DBRestClientDelegate callbacks

- (void)restClient:(DBRestClient*)client
    loadedMetadata:(DBMetadata*)metadata
{
    [[DMTracker defaultTracker] trackEventInCategory:@"Usage"
                                            withName:@"Rename File Exists"];

    [renameButton setHidden:NO];
    [spinner stopAnimation:self];
    NSAlert* alert = [NSAlert alertWithMessageText:nil
                                     defaultButton:nil
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@"The filename is in use, please choose another name."];
    [alert setIcon:[NSImage imageNamed:NSImageNameCaution]];
    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:nil
                     didEndSelector:nil
                        contextInfo:nil];
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error
{
    NSString *newPath = [error.userInfo objectForKey:@"path"];
    if (error.code == 404 && newPath)
    {
        DLog(@"Destination file did not exist, so going ahead with move.");
        [client moveFrom:path
                  toPath:newPath];
    }
    else
    {
        GrowlerGrowl *errorGrowl = [GrowlerGrowl growlErrorWithTitle:@"GrabBox could not rename file!"
                                                         description:[error localizedDescription]];
        [Growler growl:errorGrowl];
        ErrorLog(@"%@ %@ (%ld)", newPath, [error localizedDescription], [error code]);
        [[self window] performClose:self];
    }
}

- (void)restClient:(DBRestClient*)client
         movedPath:(NSString *)path
            toPath:(NSString *)newPath
{
    [self setPath:newPath];
    if ([Uploader pasteboardURL:[DropboxUploader urlForPath:newPath]])
    {
        GrowlerGrowl *success = [GrowlerGrowl growlWithName:@"Screenshot Renamed"
                                                      title:@"Screenshot renamed!"
                                                description:@"The screenshot has been renamed and an updated link put in your clipboard."];
        [Growler growl:success];
    }
    [[self window] performClose:self];
}

- (void)restClient:(DBRestClient*)client movePathFailedWithError:(NSError*)error
{
    GrowlerGrowl *errorGrowl = [GrowlerGrowl growlErrorWithTitle:@"GrabBox could not rename file!"
                                                     description:[error localizedDescription]];
    [Growler growl:errorGrowl];
    ErrorLog(@"%@ (%ld)", [error localizedDescription], [error code]);
    [[self window] performClose:self];
}

@end
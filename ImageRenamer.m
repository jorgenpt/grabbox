//
//  ImageRenamer.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/13/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "ImageRenamer.h"
#import "Growler.h"
#import "UploadInitiator.h"

@implementation ImageRenamer

@synthesize window;
@synthesize imageView;
@synthesize image;
@synthesize path;
@synthesize url;
@synthesize name;

+ (id) renamerForFile:(NSString *)path
                atURL:(NSString *)url
{
    return [[[self alloc] initForFile:path atURL:url] autorelease];
}

- (id) initForFile:(NSString *)filePath
             atURL:(NSString *)remoteUrl
{
    if (self = [super init])
    {
        [self setPath:filePath];
        [self setUrl:remoteUrl];
    }
    return self;
}

- (void) dealloc
{
    [self setImage:nil];
    [self setPath:nil];
    [self setUrl:nil];

    [super dealloc];
}

- (void) awakeFromNib
{
    [self setImage:[[[NSImage alloc] initWithContentsOfFile:path] autorelease]];

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
    
    if (newSize.width > maxSize.width)
    {
        newSize.width = maxSize.width;
        newSize.height = (newSize.width - paddingWidth) * imageSize.height / imageSize.width + paddingHeight;
    }
    
    if (newSize.height > maxSize.height)
    {
        newSize.height = maxSize.height;
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

- (BOOL) windowShouldClose
{
    [self autorelease];
    return YES;
}

- (void) growlClickedWithData:(id)data
{
    [[self retain] showRenamer];
}

- (void) growlTimedOutWithData:(id)data
{
}

- (void) showRenamer
{
    [NSBundle loadNibNamed:@"ImageRenamer" owner:self];
}

- (IBAction) clickedOk:(id)sender
{
    NSString* inputFilename = [[name stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([inputFilename length] > 0)
    {
        NSString* originalFilename = [[self path] lastPathComponent];
        NSString* extension = [originalFilename pathExtension];
        NSString* filename = [inputFilename stringByAppendingPathExtension:extension];
        NSRange replaceRange = NSMakeRange([[self url] length] - [originalFilename length],
                                           [originalFilename length]);
        NSString* newPath = [[[self path] stringByDeletingLastPathComponent] stringByAppendingPathComponent:filename];
        NSString* newUrl = [[self url] stringByReplacingCharactersInRange:replaceRange
                                                               withString:filename];
        NSFileManager* fm = [NSFileManager defaultManager];
        NSError* error;
        BOOL moveOk = [fm moveItemAtPath:[self path]
                                  toPath:newPath
                                   error:&error];
        if (moveOk)
        {
            [UploadInitiator copyURL:newUrl
                         basedOnFile:newPath
                           wasRenamed:YES];
        }
        else
        {
            if ([fm fileExistsAtPath:newPath])
            {
                NSAlert* alert = [NSAlert alertWithMessageText:nil
                                                 defaultButton:nil
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:@"The filename '%@' is in use, please choose another name.", inputFilename];
                [alert setIcon:[NSImage imageNamed:NSImageNameCaution]];
                [alert beginSheetModalForWindow:[self window]
                                  modalDelegate:nil
                                 didEndSelector:nil
                                    contextInfo:nil];
                return;
            }
            else
            {
                [Growler errorWithTitle:@"GrabBox could not rename file!"
                            description:[error localizedDescription]];
            }
        }
    }
    
    [[self window] performClose:self];
}

@end
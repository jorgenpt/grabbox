//
//  FileRenamer.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/13/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "FileRenamer.h"


@implementation FileRenamer

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

- (void) showRenamer
{
    [NSBundle loadNibNamed:@"ImageRenamer" owner:self];
}

- (void) awakeFromNib
{
    [self setImage:[[[NSImage alloc] initWithContentsOfFile:path] autorelease]];
    [imageView setImage:[self image]];
}

- (void) growlClickedWithData:(id)data
{
    [self showRenamer];
}

- (void) growlTimedOutWithData:(id)data
{
}

- (IBAction) clickedOk:(id)sender
{
    NSString* filename = [[name stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([filename length] > 0)
    {
    }
    
    [sender performClose:self];
}

@end
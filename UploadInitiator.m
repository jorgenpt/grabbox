//
//  UploadInitiator.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "UploadInitiator.h"
#import "Growler.h"
#import "InformationGatherer.h"

@implementation UploadInitiator

@synthesize srcFile;
@synthesize srcPath;
@synthesize destPath;
@synthesize dropboxId;

+ (id) uploadFile:(NSString *)file
           atPath:(NSString *)source
           toPath:(NSString *)destination
           withId:(int)dropId
{
    return [[self alloc] initForFile:file atPath:source toPath:destination withId:dropId];
}

- (id) initForFile:(NSString *)file
            atPath:(NSString *)source
            toPath:(NSString *)destination
            withId:(int)dropId
{
    if (self = [super init])
    {
        [self setSrcFile:file];
        [self setSrcPath:source];
        [self setDestPath:destination];
        [self setDropboxId:dropId];
    }
    return self;
}

- (void) dealloc
{
    [self setSrcFile:nil];
    [self setSrcPath:nil];
    [self setDestPath:nil];

    [super dealloc];
}

- (void) upload
{
    NSError* error;
    NSString* shortName = [self getNextFilenameWithExtension:[[self srcFile] pathExtension]];
    if (!shortName)
        shortName = [self srcFile];

    NSString* sourcePath = [NSString pathWithComponents:[NSArray arrayWithObjects: [self srcPath], [self srcFile], nil]];
    NSString* destination = [NSString pathWithComponents:[NSArray arrayWithObjects: [self destPath], shortName, nil]];
    BOOL moveOk = [[NSFileManager defaultManager] moveItemAtPath:sourcePath
                                                          toPath:destination
                                                           error:&error];
    if (!moveOk)
    {
        [Growler errorWithTitle:@"Could not upload file!"
                    description:[error localizedDescription]];
        NSLog(@"ERROR: %@ (%i)", [error localizedDescription], [error code]);
    }
    else
    {
        NSString *dropboxUrl = [[InformationGatherer defaultGatherer] getURLForFile:shortName
                                                                             withId:[self dropboxId]];
        [self copyURL:dropboxUrl basedOnFile:destination];
    }
}

- (void) copyURL:(NSString *)url basedOnFile:(NSString *)path
{
    NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];

    if (![pasteboard setString:url forType:NSStringPboardType])
    {
        NSString *errorDescription = [NSString stringWithFormat:@"Could not put URL '%@' into the clipboard, click here to try this operation again.", url];
        GrowlerDelegateContext *context = [GrowlerDelegateContext contextWithDelegate:self
                                                                                 data:url];
        [Growler messageWithTitle:@"Could not update pasteboard!"
                      description:errorDescription
                             name:@"Error"
                  delegateContext:context
                           sticky:YES];
        NSLog(@"ERROR: Couldn't put url into pasteboard.");
    }
    else {
        [Growler messageWithTitle:@"Screenshot uploaded!"
                      description:@"The screenshot has been uploaded and a link put in your clipboard. Click here to give the file a more descriptive name!"
         //Click here to give it a better name, or press Cmd-Opt-N."
                             name:@"URL Copied"
                  delegateContext:nil
                           sticky:NO];
    }
}

- (void) growlClickedWithData:(id)data
{
    [self upload];
}

- (void) growlTimedOutWithData:(id)data
{
}


- (NSString *) getNextFilenameWithExtension:(NSString *)ext
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* characters = @"0123456789abcdefghijklmnopqrstuvwxyz";

    NSMutableArray* prefixes = [NSMutableArray arrayWithObject:@""];

    for (int c = 0; c < [prefixes count]; ++c)
    {
        NSString* prefix = [prefixes objectAtIndex:c];
        if ([prefix length] > MAX_NAME_LENGTH)
            return nil;

        for (int i = 0; i < [characters length]; i++)
        {
            NSString* filename = [prefix stringByAppendingString:[characters substringWithRange:NSMakeRange(i, 1)]];
            [prefixes addObject:filename];
            filename = [filename stringByAppendingFormat:@".%@", ext];

            NSString* path = [NSString pathWithComponents:[NSArray arrayWithObjects:[self destPath], filename, nil]];
            if (![fm fileExistsAtPath:path])
                return filename;
        }
    }

    return nil;
}

@end

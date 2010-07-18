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
#import "ImageRenamer.h"

@implementation UploadInitiator

@synthesize srcFile;
@synthesize srcPath;
@synthesize destPath;
@synthesize dropboxId;
@synthesize detectors;

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
        [self setDetectors:[NSMutableArray array]];
        [self setDropboxId:dropId];
    }
    return self;
}

- (void) dealloc
{
    [self setSrcFile:nil];
    [self setSrcPath:nil];
    [self setDestPath:nil];
    [self setDetectors:nil];

    [super dealloc];
}

- (void) assertDropboxRunningAndUpload
{
    DropboxDetector* detector = [DropboxDetector dropboxDetectorWithDelegate:self];
    [[self detectors] addObject:detector];
    [detector checkIfRunning];
}
- (void) uploadWithRetries:(int)retries
{
    NSError* error;
    NSString* shortName = [self getNextFilenameWithExtension:[[self srcFile] pathExtension]];
    if (!shortName)
        shortName = [self srcFile];

    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* sourcePath = [NSString pathWithComponents:[NSArray arrayWithObjects: [self srcPath], [self srcFile], nil]];
    NSString* destination = [NSString pathWithComponents:[NSArray arrayWithObjects: [self destPath], shortName, nil]];
    BOOL moveOk = [fm moveItemAtPath:sourcePath
                              toPath:destination
                               error:&error];
    if (!moveOk)
    {
        if (retries > 0 && [fm fileExistsAtPath:destination])
        {
            [self uploadWithRetries:(retries - 1)];
        }
        else
        {
            [Growler errorWithTitle:@"Could not upload file!"
                        description:[error localizedDescription]];
            NSLog(@"ERROR: %@ (%i)", [error localizedDescription], [error code]);
        }
    }
    else
    {
        NSString *dropboxUrl = [[InformationGatherer defaultGatherer] getURLForFile:shortName
                                                                             withId:[self dropboxId]];
        [UploadInitiator copyURL:dropboxUrl
                     basedOnFile:destination
                      wasRenamed:NO];
    }
}

+ (void) copyURL:(NSString *)url
     basedOnFile:(NSString *)path
      wasRenamed:(BOOL)renamed
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
    else
    {
        if (renamed)
        {
            [Growler messageWithTitle:@"Screenshot renamed!"
                          description:@"The screenshot has been renamed and an updated link put in your clipboard."
                                 name:@"Screenshot Renamed"
                      delegateContext:nil
                               sticky:NO];
        }
        else
        {
            ImageRenamer* renamer = [ImageRenamer renamerForFile:path atURL:url];
            GrowlerDelegateContext* context = [GrowlerDelegateContext contextWithDelegate:renamer data:nil];
            [Growler messageWithTitle:@"Screenshot uploaded!"
                          description:@"The screenshot has been uploaded and a link put in your clipboard. Click here to give the file a more descriptive name!"
                                 name:@"URL Copied"
                      delegateContext:context
                               sticky:NO];
        }
    }
}

- (void) growlClickedWithData:(id)data
{
    [self uploadWithRetries:3];
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

- (void) dropboxIsRunning:(BOOL)running
             fromDetector:(DropboxDetector *)detector;
{
    if (running)
        [self uploadWithRetries:3];
    [[self detectors] removeObject:detector];
}
@end

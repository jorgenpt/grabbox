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
#import "ImageRenamer.h"
#import "URLShortener.h"

#import "ImgurUploader.h"
#import "UploadManager.h"

@implementation Uploader

@synthesize delegate;

@synthesize retries;

@synthesize srcFile;
@synthesize srcPath;

NSString *urlCharacters = @"0123456789abcdefghijklmnopqrstuvwxyz-_~";

+ (BOOL) pasteboardURL:(NSString *)url
{
    NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];

    NSString *shortURL = [URLShortener shortURLForURL:url];
    if (![pasteboard setString:shortURL forType:NSStringPboardType])
    {
        NSString *errorDescription = [NSString stringWithFormat:@"Could not put URL '%@' into the clipboard", shortURL];
        GrowlerGrowl *copyError = [GrowlerGrowl growlErrorWithTitle:@"Could not update pasteboard!"
                                                        description:errorDescription];
        copyError.sticky = YES;
        [Growler growl:copyError];

        ErrorLog(@"Couldn't put url '%@' into pasteboard.", shortURL);
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

    BOOL shouldLeaveIntact = [[NSUserDefaults standardUserDefaults] boolForKey:@"DoNotDeleteScreenshot"];
    if (shouldLeaveIntact)
    {
        DLog(@"Trying to copy %@ -> %@", srcPath, newPath);
        moveOk = [[NSFileManager defaultManager] copyItemAtPath:srcPath
                                                         toPath:newPath
                                                          error:&error];
    }
    else
    {
        DLog(@"Trying to move %@ -> %@", srcPath, newPath);
        moveOk = [[NSFileManager defaultManager] moveItemAtPath:srcPath
                                                         toPath:newPath
                                                          error:&error];
    }

    if (moveOk)
    {
        [self setSrcPath:newPath];
    }
    else
    {
        NSLog(@"Could not move file '%@' to workqueue location '%@', trying to upload from current location: %@ (%ld)",
              srcPath, newPath, [error localizedDescription], [error code]);
    }
}

- (void) upload
{
    [[DMTracker defaultTracker] trackEventInCategory:@"Usage"
                                            withName:@"Upload"
                                               value:[self className]];
}

@end

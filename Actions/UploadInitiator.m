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
#import "URLShortener.h"

#import "UploadManager.h"

@interface UploadInitiator ()

@property (nonatomic, assign) int retries;

@property (nonatomic, retain) DBRestClient *restClient;
@property (nonatomic, retain) NSString* srcFile;
@property (nonatomic, retain) NSString* srcPath;
@property (nonatomic, retain) NSString* destFile;
@property (nonatomic, retain) NSString* destPath;

- (NSString *) nextFilenameWithExtension:(NSString *)ext;
- (NSString *) randomStringOfLength:(int)length;
- (void) upload;
@end

@implementation UploadInitiator

@synthesize delegate;

@synthesize retries;

@synthesize restClient;
@synthesize srcFile;
@synthesize srcPath;
@synthesize destFile;
@synthesize destPath;

NSString *urlCharacters = @"0123456789abcdefghijklmnopqrstuvwxyz-_~";

+ (void) copyURL:(NSString *)url
     basedOnFile:(NSString *)path
      wasRenamed:(BOOL)renamed
{
    NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    
    if (![pasteboard setString:url forType:NSStringPboardType])
    {
        NSString *errorDescription = [NSString stringWithFormat:@"Could not put URL '%@' into the clipboard, click here to try this operation again.", url];
        GrowlerGrowl *copyError = [GrowlerGrowl growlErrorWithTitle:@"Could not update pasteboard!"
                                                        description:errorDescription];
        copyError.sticky = YES;
        [Growler growl:copyError
             withBlock:^(GrowlerGrowlAction action) {
                 if (action == GrowlerGrowlClicked)
                     [self copyURL:url basedOnFile:path wasRenamed:renamed];
             }];
        NSLog(@"ERROR: Couldn't put url into pasteboard.");
    }
    else
    {
        if (renamed)
        {
            GrowlerGrowl *success = [GrowlerGrowl growlWithName:@"Screenshot Renamed"
                                                          title:@"Screenshot renamed!"
                                                    description:@"The screenshot has been renamed and an updated link put in your clipboard."];
            [Growler growl:success];
        }
        else
        {
            GrowlerGrowl *prompt = [GrowlerGrowl growlWithName:@"URL Copied"
                                                         title:@"Screenshot uploaded!"
                                                   description:@"The screenshot has been uploaded and a link put in your clipboard. Click here to give the file a more descriptive name!"];
            [Growler growl:prompt
                 withBlock:^(GrowlerGrowlAction action) {
                     if (action == GrowlerGrowlClicked)
                     {
                         ImageRenamer* renamer = [ImageRenamer renamerForFile:path];
                         [[renamer retain] showRenamer];
                     }
                 }];
        }
    }
}

+ (id) uploadInitiatorForFile:(NSString *)file
                       atPath:(NSString *)source
                       toPath:(NSString *)destination

{
    return [[[self alloc] initForFile:file atPath:source toPath:destination] autorelease];
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
        [self setRetries:5];
        [self setSrcFile:nil];
        [self setSrcPath:nil];
        [self setDestFile:nil];
        [self setDestPath:nil];
    }
    
    return self;
}

- (id) initForFile:(NSString *)file
            atPath:(NSString *)source
            toPath:(NSString *)destination
{
    self = [self init];
    if (self)
    {
        [self setSrcFile:file];
        [self setSrcPath:[NSString pathWithComponents:[NSArray arrayWithObjects: source, file, nil]]];
        [self setDestPath:destination];
    }
    return self;
}

- (void) dealloc
{
    DLog(@"Deallocating uploader for %@ -> %@", srcPath, destPath);

    [self setRestClient:nil];
    [self setSrcFile:nil];
    [self setSrcPath:nil];
    [self setDestFile:nil];
    [self setDestPath:nil];

    [super dealloc];
}

- (void) moveToWorkQueue
{
    NSString* newPath = [[[InformationGatherer defaultGatherer] workQueuePath] stringByAppendingPathComponent:srcFile];
    DLog(@"Trying to move %@ -> %@", srcPath, newPath);
    NSError *error;
    BOOL moveOk;

    BOOL shouldLeaveIntact = [[NSUserDefaults standardUserDefaults] boolForKey:@"DoNotDeleteScreenshot"];
    if (shouldLeaveIntact)
    {
        moveOk = [[NSFileManager defaultManager] copyItemAtPath:srcPath
                                                         toPath:newPath
                                                          error:&error];
    }
    else
    {
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
    NSString* shortName = [self nextFilenameWithExtension:[[self srcFile] pathExtension]];
    if (!shortName)
        shortName = [self srcFile];

    [self setDestFile:shortName];
    NSString* destination = [NSString pathWithComponents:[NSArray arrayWithObjects: [self destPath], shortName, nil]];

    DLog(@"Trying upload of '%@', destination '%@'", srcPath, destination);
    [restClient loadMetadata:destination];
}

#pragma mark DBRestClientDelegate callbacks

- (void)restClient:(DBRestClient*)client
    loadedMetadata:(DBMetadata*)metadata
{
    [self setRetries:retries - 1];
    DLog(@"Suggested filename exists, retries left: %d", retries);

    if (retries > 0)
    {
        [self upload];
    }
    else
    {
        GrowlerGrowl *errorGrowl = [GrowlerGrowl growlErrorWithTitle:@"GrabBox could not upload file!"
                                                         description:@"Could not find a unique filename"];
        [Growler growl:errorGrowl];

        NSLog(@"ERROR: Could not find a unique filename!");

        if ([delegate respondsToSelector:@selector(uploaderDone:)])
            [delegate uploaderDone:self];
    }
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error
{
    if (error.code == 404)
    {
        DLog(@"Destination file did not exist, so going ahead with upload.");
        [restClient uploadFile:destFile
                        toPath:destPath
                      fromPath:srcPath];
    }
    else
    {
        [self setRetries:retries - 1];
        DLog(@"Metadata request failed, retries left: %d", retries);
        if (retries > 0)
        {
            if ([delegate respondsToSelector:@selector(scheduleUpload:)])
                [delegate scheduleUpload:self];
            else
                NSLog(@"Delegate %@ does not respond to scheduleUpload!", delegate);
        }
        else
        {
            GrowlerGrowl *errorGrowl = [GrowlerGrowl growlErrorWithTitle:@"GrabBox could not upload file!"
                                                             description:[NSString stringWithFormat:@"Received status code %d", [error code]]];
            [Growler growl:errorGrowl];
            NSLog(@"ERROR: %@ (%ld)", [error localizedDescription], [error code]);
            if ([delegate respondsToSelector:@selector(uploaderDone:)])
                [delegate uploaderDone:self];
        }
    }

}
- (void)restClient:(DBRestClient*)client
      uploadedFile:(NSString*)uploadedPath
              from:(NSString*)source
{
    DLog(@"Upload complete, %@ -> %@", source, uploadedPath);
    int numberOfScreenshots = [[NSUserDefaults standardUserDefaults] integerForKey:@"NumberOfScreenshotsUploaded"];
    [[NSUserDefaults standardUserDefaults] setInteger:(numberOfScreenshots + 1)
                                               forKey:@"NumberOfScreenshotsUploaded"];
    NSString *dropboxUrl = [URLShortener shortenURLForFile:[self destFile]];
    [UploadInitiator copyURL:dropboxUrl
                 basedOnFile:uploadedPath
                  wasRenamed:NO];    
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress 
           forFile:(NSString*)dest from:(NSString*)source
{
    DLog(@"%@ -> %@: %.1f", source, dest, progress*100.0);
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error
{
    [self setRetries:retries - 1];
    DLog(@"Upload request failed, retries left: %d", retries);    
    if (retries > 0)
    {
        if ([delegate respondsToSelector:@selector(scheduleUpload:)])
            [delegate scheduleUpload:self];
        else
            NSLog(@"Delegate %@ does not respond to scheduleUpload!", delegate);
    }
    else
    {
        GrowlerGrowl *errorGrowl = [GrowlerGrowl growlErrorWithTitle:@"GrabBox could not upload file!"
                                                         description:[NSString stringWithFormat:@"Received status code %d", [error code]]];
        [Growler growl:errorGrowl];
        NSLog(@"ERROR: %@ (%ld)", [error localizedDescription], [error code]);
        if ([delegate respondsToSelector:@selector(uploaderDone:)])
            [delegate uploaderDone:self];
    }    
}

- (NSString *) randomStringOfLength:(int)length
{
    NSMutableString* output = [NSMutableString string];
    
    for (int i = 0; i < length; ++i)
    {
        int character = drand48() * [urlCharacters length]; 
        [output appendString:[urlCharacters substringWithRange:NSMakeRange(character, 1)]];
    }
    
    return output;
}

- (NSString *) nextFilenameWithExtension:(NSString *)ext
{
    NSString *output;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"UseLongRandomFilename"])
        output = [self randomStringOfLength:12];
    else 
        output = [self randomStringOfLength:6];
    return [output stringByAppendingFormat:@".%@", ext];
}

@end

//
//  DropboxUploader.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright (C) 2014 Jørgen P. Tjernø. Licensed under GPLv2, see LICENSE in the project root for more info.
//

#import "DropboxUploader.h"
#import "Growler.h"
#import "InformationGatherer.h"

#import "UploadManager.h"
#import "UploaderFactory.h"

#import "DBAccountInfo+PublicAppURL.h"
#import "NSString+URLParameters.h"

@interface DropboxUploader ()

@property (nonatomic, retain) NSString* destFilename;
- (DBRestClient *)restClient;

@end

@implementation DropboxUploader

@synthesize destFilename;

+ (NSString *) urlForPath:(NSString *)path
{
    NSString *prefix = [[[UploaderFactory defaultFactory] account] publicAppURL];

    // Ensure it has a leading slash etc.
    path = [[@"/" stringByAppendingString:path] stringByStandardizingPath];

    return [prefix stringByAppendingString:path];
}

- (id) init
{
    self = [super init];
    if (self)
    {
        [self setDestFilename:nil];
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
    [restClient setDelegate:nil];
    [restClient release];
    [self setDestFilename:nil];

    [super dealloc];
}

- (void) upload
{
    [super upload];

    NSString* shortName = [NSString stringWithFormat:@"%@.%@",
                           [Uploader randomStringOfLength:8], [srcFile pathExtension]];

    [self setDestFilename:shortName];

    DLog(@"Trying upload of '%@', destination '%@'", srcPath, shortName);
    [[self restClient] loadMetadata:[@"/" stringByAppendingString:shortName]];
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
        GrowlerGrowl *errorGrowl = [GrowlerGrowl growlErrorWithTitle:@"GrabBox could not upload file to Dropbox!"
                                                         description:@"Could not find a unique filename"];
        [Growler growl:errorGrowl];

        ErrorLog(@"Could not find a unique filename!");

        [self uploadDone];
    }
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error
{
    if (error.code == 404)
    {
        DLog(@"Destination file did not exist, so going ahead with upload.");
        [client uploadFile:destFilename
                    toPath:@"/"
             withParentRev:nil
                  fromPath:srcPath];
    }
    else if (error.code == 401)
    {
        // TODO: GH-1: Show error dialog & ask to re-auth.
        // For now we just force a re-auth.
        DLog(@"401 from Dropbox when loading metadata.");

        [[NSUserDefaults standardUserDefaults] removeObjectForKey:CONFIG(Host)];
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
            GrowlerGrowl *errorGrowl = [GrowlerGrowl growlErrorWithTitle:@"GrabBox could not upload file to Dropbox!"
                                                             description:[NSString stringWithFormat:@"Received status code %ld", (long)[error code]]];
            [Growler growl:errorGrowl];
            ErrorLog(@"%@ (%ld)", [error localizedDescription], [error code]);
            [self uploadDone];
        }
    }
}

- (void)restClient:(DBRestClient*)client
      uploadedFile:(NSString*)uploadedPath
              from:(NSString*)source
{
    DLog(@"Upload complete, %@ -> %@", source, uploadedPath);
    NSInteger numberOfScreenshots = [[NSUserDefaults standardUserDefaults] integerForKey:@"NumberOfScreenshotsUploaded"];
    [[NSUserDefaults standardUserDefaults] setInteger:(numberOfScreenshots + 1)
                                               forKey:@"NumberOfScreenshotsUploaded"];
    if ([Uploader pasteboardURL:[DropboxUploader urlForPath:uploadedPath]])
    {
        GrowlerGrowl *prompt = [GrowlerGrowl growlWithName:@"URL Copied"
                                                     title:@"Screenshot uploaded!"
                                               description:@"The screenshot has been uploaded and a link put in your clipboard."];
        [Growler growl:prompt];
    }

    NSError *error;
    BOOL deletedOk = [[NSFileManager defaultManager] removeItemAtPath:source
                                                                error:&error];
    if (!deletedOk)
        ErrorLog(@"%@ (%ld)", [error localizedDescription], [error code]);

    [self uploadDone];
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress
           forFile:(NSString*)dest from:(NSString*)source
{
    DLog(@"%@ -> %@: %.1f", source, dest, progress*100.0);
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error
{
    if (error.code == 401)
    {
        [self uploadDone];

        // TODO: GH-1: Show error dialog & ask to re-auth.
        // For now we just force a re-auth.
        DLog(@"401 from Dropbox when uploading file.");

        [[NSUserDefaults standardUserDefaults] removeObjectForKey:CONFIG(Host)];
    }
    else
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
            GrowlerGrowl *errorGrowl = [GrowlerGrowl growlErrorWithTitle:@"GrabBox could not upload file to Dropbox!"
                                                             description:[NSString stringWithFormat:@"Received status code %ld", (long)[error code]]];
            [Growler growl:errorGrowl];
            ErrorLog(@"%@ (%ld)", [error localizedDescription], [error code]);
            [self uploadDone];
        }
    }
}

- (DBRestClient *)restClient {
    if (!restClient) {
        restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient.delegate = self;
    }
    return restClient;
}

@end

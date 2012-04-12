//
//  DropboxUploader.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "DropboxUploader.h"
#import "Growler.h"
#import "InformationGatherer.h"
#import "ImageRenamer.h"
#import "URLShortener.h"

#import "UploadManager.h"
#import "UploaderFactory.h"

#import "NSString+URLParameters.h"

static NSString * const dropboxPath = @"/Public/Screenshots";
static NSString * const dropboxPublicPrefix = @"/Public/";

@interface DropboxUploader ()

@property (nonatomic, retain) NSString* destFilename;
- (DBRestClient *)restClient;

@end

@implementation DropboxUploader

@synthesize destFilename;

+ (NSString *) urlForPath:(NSString *)path
{
    NSString *dropboxId = [[[UploaderFactory defaultFactory] account] userId];
    
    // TODO: Handle non-prefixed URLs with yet-to-come API?
    if ([path hasPrefix:dropboxPublicPrefix])
        path = [path substringFromIndex:[dropboxPublicPrefix length]];

    return [NSString stringWithFormat:@"http://dl.dropbox.com/u/%@/%@", dropboxId, path];

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

    NSString* shortName = srcFile;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"UseRandomFilename"])
    {
        shortName = [NSString stringWithFormat:@"%@.%@",
                     [Uploader randomStringOfLength:8], [srcFile pathExtension]];
    }

    [self setDestFilename:shortName];
    NSString* destination = [NSString pathWithComponents:[NSArray arrayWithObjects:dropboxPath, shortName, nil]];

    DLog(@"Trying upload of '%@', destination '%@'", srcPath, destination);
    [[self restClient] loadMetadata:destination];
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

        if ([delegate respondsToSelector:@selector(uploaderDone:)])
            [delegate uploaderDone:self];
    }
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error
{
    if (error.code == 404)
    {
        DLog(@"Destination file did not exist, so going ahead with upload.");
        [client uploadFile:destFilename
                    toPath:dropboxPath
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
            GrowlerGrowl *errorGrowl = [GrowlerGrowl growlErrorWithTitle:@"GrabBox could not upload file to Dropbox!"
                                                             description:[NSString stringWithFormat:@"Received status code %d", [error code]]];
            [Growler growl:errorGrowl];
            ErrorLog(@"%@ (%ld)", [error localizedDescription], [error code]);
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
    NSInteger numberOfScreenshots = [[NSUserDefaults standardUserDefaults] integerForKey:@"NumberOfScreenshotsUploaded"];
    [[NSUserDefaults standardUserDefaults] setInteger:(numberOfScreenshots + 1)
                                               forKey:@"NumberOfScreenshotsUploaded"];
    if ([Uploader pasteboardURL:[DropboxUploader urlForPath:uploadedPath]])
    {
        GrowlerGrowl *prompt = [GrowlerGrowl growlWithName:@"URL Copied"
                                                     title:@"Screenshot uploaded!"
                                               description:@"The screenshot has been uploaded and a link put in your clipboard. Click here to give the file a more descriptive name!"];
        ImageRenamer* renamer = [ImageRenamer renamerForPath:uploadedPath withFile:source];
        [Growler growl:prompt
             withBlock:^(GrowlerGrowlAction action) {
                 if (action == GrowlerGrowlClicked)
                     [renamer showRenamer];
             }];
    }

    NSError *error;
    BOOL deletedOk = [[NSFileManager defaultManager] removeItemAtPath:source
                                                                error:&error];
    if (!deletedOk)
        ErrorLog(@"%@ (%ld)", [error localizedDescription], [error code]);

    if ([delegate respondsToSelector:@selector(uploaderDone:)])
        [delegate uploaderDone:self];
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
        GrowlerGrowl *errorGrowl = [GrowlerGrowl growlErrorWithTitle:@"GrabBox could not upload file to Dropbox!"
                                                         description:[NSString stringWithFormat:@"Received status code %d", [error code]]];
        [Growler growl:errorGrowl];
        ErrorLog(@"%@ (%ld)", [error localizedDescription], [error code]);
        if ([delegate respondsToSelector:@selector(uploaderDone:)])
            [delegate uploaderDone:self];
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

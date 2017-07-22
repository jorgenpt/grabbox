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

#import "UploadManager.h"
#import "UploaderFactory.h"

#import "NSString+URLParameters.h"

#import <Crashlytics/Crashlytics.h>

@interface DropboxUploader ()

@property (nonatomic, strong) NSString* destFilename;

@end

@implementation DropboxUploader

@synthesize destFilename;

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


- (void) upload
{
    [super upload];

    NSString* shortName = [NSString stringWithFormat:@"/%@.%@",
                           [Uploader randomStringOfLength:8], [srcFile pathExtension]];

    [self setDestFilename:shortName];

    DLog(@"Trying upload of '%@', destination '%@'", srcPath, shortName);
    DBFILESWriteMode *mode = [[DBFILESWriteMode alloc] initWithAdd];

    DBUploadTask<DBFILESFileMetadata *, DBFILESUploadError *>* task = nil;
    @try{
        task = [DBClientsManager.authorizedClient.filesRoutes
                uploadUrl:destFilename
                mode:mode
                autorename:@(YES)
                clientModified:nil
                mute:@(YES)
                inputUrl:srcPath];
    } @catch (NSException* exception) {
        ErrorLog(@"uploadUrl exception: %@, reason: %@", exception.name, exception.reason);
        GrowlerGrowl *errorGrowl = nil;
        if ([exception.name isEqualToString:NSInvalidArgumentException])
        {
            errorGrowl = [GrowlerGrowl growlErrorWithTitle:@"GrabBox could not upload screenshot to Dropbox!"
                                               description:@"Could not read file"];
        }
        else
        {
            errorGrowl = [GrowlerGrowl growlErrorWithTitle:@"GrabBox could not upload screenshot to Dropbox!"
                                               description:exception.reason];
        }
        [Growler growl:errorGrowl];
        [self uploadDone];
        return;
    }

    [task setResponseBlock:^(DBFILESFileMetadata *result,
                             DBFILESUploadError *routeError,
                             DBRequestError *networkError)
    {
        if (result)
        {
            DLog(@"Upload complete, %@ -> %@", self.srcPath, result.pathDisplay);
            NSInteger numberOfScreenshots = [[NSUserDefaults standardUserDefaults] integerForKey:@"NumberOfScreenshotsUploaded"];
            [[NSUserDefaults standardUserDefaults] setInteger:(numberOfScreenshots + 1)
                                                       forKey:@"NumberOfScreenshotsUploaded"];
            [Answers logCustomEventWithName:@"Dropbox Screenshot Uploaded"
                           customAttributes:@{@"NumberOfScreenshots": @(numberOfScreenshots + 1)}];

            [[DBClientsManager.authorizedClient.sharingRoutes
             createSharedLinkWithSettings:result.pathLower]
             setResponseBlock:^(DBSHARINGSharedLinkMetadata *result,
                                DBSHARINGCreateSharedLinkWithSettingsError *routeError,
                                DBRequestError *networkError)
             {
                 if (result)
                 {
                     NSURLComponents* urlComponents = [[NSURLComponents alloc] initWithString:result.url];
                     [urlComponents setQuery:@"raw=1"];
                     if ([Uploader pasteboardURL:[urlComponents string]])
                     {
                         GrowlerGrowl *prompt = [GrowlerGrowl growlWithName:@"URL Copied"
                                                                      title:@"Screenshot uploaded!"
                                                                description:@"The screenshot has been uploaded and a link put in your clipboard."];
                         [Growler growl:prompt];
                     }

                     NSError *error;
                     BOOL deletedOk = [[NSFileManager defaultManager] removeItemAtPath:self.srcPath
                                                                                 error:&error];
                     if (!deletedOk)
                         ErrorLog(@"%@ (%ld)", [error localizedDescription], [error code]);
                 }
                 else
                 {
                     GrowlerGrowl *errorGrowl = [GrowlerGrowl growlErrorWithTitle:@"GrabBox could not upload file to Dropbox!"
                                                                      description:@"Failed to share link"];
                     [Growler growl:errorGrowl];
                 }

                 [self uploadDone];

             }];
        }
        else
        {
            [self setRetries:retries - 1];
            DLog(@"Suggested filename exists, retries left: %d", retries);

            if (retries > 0)
            {
                [self upload];
            }
            else if (routeError)
            {
                GrowlerGrowl *errorGrowl = [GrowlerGrowl growlErrorWithTitle:@"GrabBox could not upload file to Dropbox!"
                                                                 description:@"Received error from Dropbox"];
                [Growler growl:errorGrowl];
                ErrorLog(@"Upload error: %@", routeError);
                [self uploadDone];
            }
            else if (networkError)
            {
                if ([networkError isAuthError])
                {
                    DLog(@"401 from Dropbox when uploading file.");

                    [[UploaderFactory defaultFactory] logout];
                }
                else
                {
                    GrowlerGrowl *errorGrowl = [GrowlerGrowl growlErrorWithTitle:@"GrabBox could not upload file to Dropbox!"
                                                                     description:@"Encountered error accessing service"];
                    [Growler growl:errorGrowl];
                    ErrorLog(@"Upload error: %@", networkError);
                }

                [self uploadDone];
            }
            else
            {
                GrowlerGrowl *errorGrowl = [GrowlerGrowl growlErrorWithTitle:@"GrabBox could not upload file to Dropbox!"
                                                                 description:@"Unknown error"];
                [Growler growl:errorGrowl];
                ErrorLog(@"Unknown upload error");
                [self uploadDone];
            }
        }
    }];
}

@end

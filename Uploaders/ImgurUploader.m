//
//  ImgurUploader.m
//  GrabBox2
//
//  Created by Jørgen P. Tjernø on 7/3/11.
//  Copyright 2011 devSoft. All rights reserved.
//

#import "ImgurUploader.h"

#import <SBJson/SBJson.h>
#import "Growler.h"

static NSString * const ImgurAPIURL = @"http://api.imgur.com/2/%@",
                * const ImgurAPIKey = @"568fcea194ed217fc88321929ca436b5";

@implementation ImgurUploader

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
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:ImgurAPIURL, @"upload.json"]];

    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:ImgurAPIKey
                   forKey:@"key"];
    [request setPostValue:@"file" 
                   forKey:@"type"];
    [request setPostValue:[srcFile stringByDeletingPathExtension] 
                   forKey:@"title"];
    [request setFile:srcPath 
              forKey:@"image"];

    DLog(@"Trying upload of '%@' via %@", srcPath, url);
    [request setDelegate:self];
    [request startAsynchronous];
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    // Use when fetching text data
    NSString *responseString = [request responseString];
    SBJsonParser *jsonParser = [[SBJsonParser new] autorelease];
    NSDictionary *dict = (NSDictionary *)[jsonParser objectWithString:responseString];

    if ([request responseStatusCode] >= 200 && [request responseStatusCode] < 300)
    {
        NSDictionary *upload = [dict objectForKey:@"upload"];
        NSDictionary *links = [upload objectForKey:@"links"];
        if ([Uploader pasteboardURL:[links objectForKey:@"original"]])
        {
            GrowlerGrowl *prompt = [GrowlerGrowl growlWithName:@"URL Copied"
                                                         title:@"Screenshot uploaded!"
                                                   description:@"The screenshot has been uploaded and a link put in your clipboard. Click here to give the file a more descriptive name!"];
            [Growler growl:prompt];
        }
        
        NSError *error;
        BOOL deletedOk = [[NSFileManager defaultManager] removeItemAtPath:srcPath
                                                                    error:&error];
        if (!deletedOk)
            ErrorLog(@"%@ (%ld)", [error localizedDescription], [error code]);
    }
    else
    {
        ErrorLog(@"Could not upload using imgur (%d): %@", [request responseStatusCode], responseString);
        GrowlerGrowl *errorGrowl = [GrowlerGrowl growlErrorWithTitle:@"GrabBox could not upload file to imgur!"
                                                         description:[NSString stringWithFormat:@"Received status code %d", [request responseStatusCode]]];
        [Growler growl:errorGrowl];
    }

    if ([delegate respondsToSelector:@selector(uploaderDone:)])
        [delegate uploaderDone:self];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSError *error = [request error];
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
        GrowlerGrowl *errorGrowl = [GrowlerGrowl growlErrorWithTitle:@"GrabBox could not upload file to imgur!"
                                                         description:[NSString stringWithFormat:@"Received status code %d", [error code]]];
        [Growler growl:errorGrowl];
        ErrorLog(@"%@ (%ld)", [error localizedDescription], [error code]);
        if ([delegate respondsToSelector:@selector(uploaderDone:)])
            [delegate uploaderDone:self];
    }
}

@end
//
//  ImgurUploader.m
//  GrabBox2
//
//  Created by Jørgen P. Tjernø on 7/3/11.
//  Copyright 2011 devSoft. All rights reserved.
//

#import "ImgurUploader.h"

@interface ImgurUploader ()
@property (retain) ASIFormDataRequest *request;
@end

@implementation ImgurUploader

@synthesize request;

- (id) init
{
    self = [super init];
    if (self)
    {
        [self setRequest:nil];
/*        [self setRestClient:[DBRestClient restClientWithSharedSession]];
        if (!restClient)
        {
            [self release];
            return nil;
        }
        
        [restClient setDelegate:self];
        [self setDestFilename:nil];*/
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

- (void)dealloc
{
    [self setRequest:nil];
    [super dealloc];
}

@end
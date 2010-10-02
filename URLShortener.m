//
//  URLShortener.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 10/1/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "URLShortener.h"
#import "MKBitlyHelper.h"

@implementation URLShortener

+ (NSString*) shortenURLForFile:(NSString*)file withId:(int)dropboxId
{
    int service = [[NSUserDefaults standardUserDefaults] integerForKey:@"URLShortener"];
    NSString *escapedFile = [file stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    NSString *directURL = [NSString stringWithFormat:@"http://dl.dropbox.com/u/%d/Screenshots/%@", dropboxId, escapedFile];

    DLog(@"Shortening with service %i.", service);
    switch (service)
    {
        case 1:
            return [NSString stringWithFormat:@"http://o7.no/%d/%@", dropboxId, escapedFile];
        case 2:
        {
            MKBitlyHelper *bitlyHelper = [[[MKBitlyHelper alloc] initWithLoginName:@"jorgenpt"
                                                                         andAPIKey:@"R_3a2a07cb1af817ab7de18d17e7f0f57f"] autorelease];
            NSString *shortURL = [bitlyHelper shortenURL:directURL];
            if (!shortURL)
                return directURL;
            else
                return shortURL;
        }
        default:
            return directURL;
    }

    return directURL;
}

@end

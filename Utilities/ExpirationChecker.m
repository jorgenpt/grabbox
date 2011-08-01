//
//  ExpirationChecker.m
//  GrabBox2
//
//  Created by Jørgen Tjernø on 7/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef MAC_APP_STORE
#define EXPIRATION_DAYS 30
#endif

BOOL expired()
{
#ifdef EXPIRATION_DAYS
    static BOOL expired = NO;
    static dispatch_once_t initOnce;

    dispatch_once(&initOnce, ^{
        NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
        NSLocale *dateLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
        [formatter setLocale:dateLocale];
        [formatter setDateFormat:@"MMM d yyyy"];

        NSDate *buildDate = [formatter dateFromString:[NSString stringWithUTF8String:__DATE__]];
        NSDate *expirationDate = [buildDate dateByAddingTimeInterval:60 * 60 * 24 * EXPIRATION_DAYS];
        NSDate *currentDate = [NSDate date];

        DLog(@"Built: %@ Expires: %@ Current: %@", buildDate, expirationDate, currentDate);
        expired = [[currentDate laterDate:expirationDate] isEqualToDate:currentDate];
    });

    return expired;
#else
    return NO;
#endif
}

//
//  BitlyHelper.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 10/1/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "BitlyHelper.h"
#import "JSON.h"

@implementation BitlyHelper

@synthesize loginName;
@synthesize apiKey;

static NSString *BITLYAPIURL = @"http://api.bit.ly/v3/%@?login=%@&apiKey=%@&";

+ (id) helperWithLogin:(NSString*)login
             andAPIKey:(NSString*)key
{
    return [[[self alloc] initWithLogin:login andAPIKey:key] autorelease];
}

- (id) initWithLogin:(NSString*)login
           andAPIKey:(NSString*)key
{
    if (self = [super init])
    {
        [self setLoginName:login];
        [self setApiKey:key];
    }

    return self;
}

- (void) dealloc
{
    [self setLoginName:nil];
    [self setApiKey:nil];
    
    [super dealloc];
}

- (NSString*) shortenURL:(NSString*)url
{
    NSString *urlWithoutParams = [NSString stringWithFormat:BITLYAPIURL, @"shorten", loginName, apiKey];
    NSString *parameters = [NSString stringWithFormat:@"longUrl=%@", [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURL *requestUrl = [NSURL URLWithString:[urlWithoutParams stringByAppendingString:parameters]];

    DLog(@"Shortening with url: %@", url);

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:requestUrl];

    NSHTTPURLResponse *urlResponse = nil;  
    NSError *error = [[[NSError alloc] init] autorelease];  

    NSData *data = [NSURLConnection sendSynchronousRequest:req
                                         returningResponse:&urlResponse
                                                     error:&error];

    if ([urlResponse statusCode] >= 200 && [urlResponse statusCode] < 300)
    {
        SBJsonParser *jsonParser = [[SBJsonParser new] autorelease];
        NSString *jsonString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        NSDictionary *dict = (NSDictionary*)[jsonParser objectWithString:jsonString];
        NSNumber *statusCode = [dict objectForKey:@"status_code"];

        if ([statusCode intValue] == 200)
        {
            NSString *shortURL = [[dict objectForKey:@"data"] objectForKey:@"url"];
            DLog(@"Got OK! ShortURL: %@", shortURL);
            return shortURL;
        }
        else
        {
            NSLog(@"Could not shorten using bit.ly: %@ %@", statusCode, [dict objectForKey:@"status_txt"]);
            return nil;
        }
    }
    else
    {
        NSLog(@"Could not shorten using bit.ly: %@", urlResponse);
        return nil;
    }
}

@end

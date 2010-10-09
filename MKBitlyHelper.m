//
//  MKBitlyHelper.m
//  BitlyDemo
//
//  Created by Mugunth Kumar on 25-Jul-09.
//  Copyright 2009 Mugunth Kumar. All rights reserved.
//  http://mugunthkumar.com
//

#import "MKBitlyHelper.h"
#import "JSON.h"

@implementation MKBitlyHelper

static NSString *BITLYAPIURL = @"http://api.bit.ly/v3/%@?login=%@&apiKey=%@&";

-(MKBitlyHelper*) initWithLoginName: (NSString*) f_loginName andAPIKey: (NSString*) f_apiKey {

	loginName = [f_loginName copy];
	apiKey = [f_apiKey copy];

	return self;
}

- (NSString*) shortenURL: (NSString*) f_longURL
{
	NSString *urlWithoutParams = [NSString stringWithFormat:BITLYAPIURL, @"shorten", loginName, apiKey];	
	NSString *parameters = [NSString stringWithFormat:@"longUrl=%@", [f_longURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	NSURL *url = [NSURL URLWithString:[urlWithoutParams stringByAppendingString:parameters]];
	
    DLog(@"Shortening with url: %@", url);

	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];

	NSHTTPURLResponse* urlResponse = nil;  
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
		
		if([statusCode intValue] == 200)
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
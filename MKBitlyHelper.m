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

static NSString *BITLYAPIURL = @"http://api.bit.ly/%@?version=2.0.1&login=%@&apiKey=%@&";

-(MKBitlyHelper*) initWithLoginName: (NSString*) f_loginName andAPIKey: (NSString*) f_apiKey {

	loginName = [f_loginName copy];
	apiKey = [f_apiKey copy];
	
	return self;
}

- (NSString*) shortenURL: (NSString*) f_longURL
{
	NSString *urlWithoutParams = [NSString stringWithFormat:BITLYAPIURL, @"shorten", loginName, apiKey];	
	NSString *parameters = [NSString stringWithFormat:@"longUrl=%@", [f_longURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	NSString *finalURL = [urlWithoutParams stringByAppendingString:parameters];
	
	NSURL *url = [NSURL URLWithString:finalURL];
	
	NSMutableURLRequest *req = [[[NSMutableURLRequest alloc] initWithURL:url] autorelease];
	
	NSHTTPURLResponse* urlResponse = nil;  
	NSError *error = [[[NSError alloc] init] autorelease];  
	
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&urlResponse error:&error];	
		
	if ([urlResponse statusCode] >= 200 && [urlResponse statusCode] < 300)
	{
		SBJsonParser *jsonParser = [SBJsonParser new];
		NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		NSDictionary *dict = (NSDictionary*)[jsonParser objectWithString:jsonString];
		[jsonString release];
		[jsonParser release];
		
		NSString *statusCode = [dict objectForKey:@"statusCode"];
		
		if([statusCode isEqualToString:@"OK"])
		{
			// retrieve shortURL from results
			//NSLog([dict description]);
			NSString *shortURL = [[[dict objectForKey:@"results"] 
								   objectForKey:f_longURL] 
								  objectForKey:@"shortUrl"];
			return shortURL;
		}
		else return nil;

	}
	else
		return nil;
}

@end
//
//  URLShortener.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 10/1/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "URLShortener.h"

#import "GrabBoxAppDelegate.h"
#import "NSString+URLParameters.h"
#import "JSON.h"

NSString *const dropboxPublicPrefix = @"/Public/";

@interface URLShortener ()

+ (NSString *) bitlyShorten:(NSString *)url;
+ (NSString *) googlShorten:(NSString *)url;
+ (NSString *) isgdShorten:(NSString *)url;
+ (NSString *) tinyurlShorten:(NSString *)url;

@end

@implementation URLShortener

static NSString * const BitlyAPIURL = @"http://api.bit.ly/v3/%@?login=%@&apiKey=%@&",
                * const BitlyAPIKey = @"R_3a2a07cb1af817ab7de18d17e7f0f57f",
                * const BitlyLogin  = @"jorgenpt";


static NSString * const GooglAPIURL  = @"https://www.googleapis.com/urlshortener/v1/url?key=%@",
                * const GoogleAPIKey = @"AIzaSyBUiAwd0JJaKz3iSSfZAGv4Vk69Mw2ubGk";

static NSString * const IsgdAPIURL = @"http://is.gd/create.php?format=json&url=%@";

static NSString * const TinyurlApiURL = @"http://tinyurl.com/api-create.php?url=%@";

+ (NSString *) urlForPath:(NSString *)path
{
    NSString *dropboxId = [[(GrabBoxAppDelegate*)[NSApp delegate] account] userId];
    int service = [[NSUserDefaults standardUserDefaults] integerForKey:CONFIG(URLShortener)];
    if ([path hasPrefix:dropboxPublicPrefix])
        path = [path substringFromIndex:[dropboxPublicPrefix length]];
    // TODO: Handle non-prefixed URLs with yet-to-come API?

    NSString *escapedPath = [path stringByAddingPercentEscapesAndEscapeCharactersInString:@":?#[]@!$&’()*+,;="];
    NSString *directURL = [NSString stringWithFormat:@"http://dl.dropbox.com/u/%@/%@", dropboxId, escapedPath];
    NSString *shortURL = nil;

    DLog(@"Shortening with service %i (%@).", service, directURL);
    switch (service)
    {
        case SHORTENER_BITLY:
            shortURL = [self bitlyShorten:directURL];
            [[DMTracker defaultTracker] trackEventInCategory:@"Features"
                                                    withName:@"URL Shortener"
                                                       value:@"bit.ly"];
            break;
        case SHORTENER_GOOGL:
            shortURL = [self googlShorten:directURL];
            [[DMTracker defaultTracker] trackEventInCategory:@"Features"
                                                    withName:@"URL Shortener"
                                                       value:@"goo.gl"];
            break;
        case SHORTENER_ISGD:
            shortURL = [self isgdShorten:directURL];
            [[DMTracker defaultTracker] trackEventInCategory:@"Features"
                                                    withName:@"URL Shortener"
                                                       value:@"is.gd"];
            break;
        case SHORTENER_TINYURL:
            shortURL = [self tinyurlShorten:directURL];
            [[DMTracker defaultTracker] trackEventInCategory:@"Features"
                                                    withName:@"URL Shortener"
                                                       value:@"tinyurl.com"];
            break;
        case SHORTENER_NONE:
            [[DMTracker defaultTracker] trackEventInCategory:@"Features"
                                                    withName:@"URL Shortener"
                                                       value:@"None"];
            break;
        default:
            [[DMTracker defaultTracker] trackEventInCategory:@"Features"
                                                    withName:@"URL Shortener"
                                                       value:@"Invalid"];
            break;
    }

    if (shortURL)
        return shortURL;
    else
        return directURL;
}

+ (NSString *) bitlyShorten:(NSString *)url
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *urlWithoutParams = [NSString stringWithFormat:BitlyAPIURL, @"shorten", BitlyLogin, BitlyAPIKey];
    NSMutableArray *parameters = [NSMutableArray array];
    [parameters addObject:[NSString stringWithKey:@"longUrl" value:url]];

    NSString *xLogin = [defaults stringForKey:CONFIG(BitlyLogin)],
             *xApiKey = [defaults stringForKey:CONFIG(BitlyApiKey)];
    if ([xLogin length] && [xApiKey length])
    {
        [parameters addObject:[NSString stringWithKey:@"x_login" value:xLogin]];
        [parameters addObject:[NSString stringWithKey:@"x_apiKey" value:xApiKey]];
    }

    NSString *urlWithParams = [urlWithoutParams stringByAppendingString:[parameters componentsJoinedByString:@"&"]];
    NSURL *requestUrl = [NSURL URLWithString:urlWithParams];

    DLog(@"Shortening with url: %@", requestUrl);

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:requestUrl];

    NSHTTPURLResponse *urlResponse = nil;
    NSError *error = nil;

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
            ErrorLog(@"Could not shorten using bit.ly: %@ %@", statusCode, [dict objectForKey:@"status_txt"]);
            return nil;
        }
    }
    else
    {
        ErrorLog(@"Could not shorten using bit.ly: %@", urlResponse);
        return nil;
    }
}

+ (NSString *) googlShorten:(NSString *)url
{
    // TODO: ClientLogin? http://code.google.com/apis/urlshortener/v1/authentication.html#token
    NSURL *requestUrl = [NSURL URLWithString:[NSString stringWithFormat:GooglAPIURL, GoogleAPIKey]];
    NSDictionary *arguments = [NSDictionary dictionaryWithObject:url forKey:@"longUrl"];
    DLog(@"Shortening with url: %@ arguments: %@", requestUrl, arguments);

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:requestUrl];
    [req setHTTPMethod:@"POST"];
    [req setHTTPBody:[[arguments JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSHTTPURLResponse *urlResponse = nil;
    NSError *error = nil;

    NSData *data = [NSURLConnection sendSynchronousRequest:req
                                         returningResponse:&urlResponse
                                                     error:&error];

    if ([urlResponse statusCode] >= 200 && [urlResponse statusCode] < 300)
    {
        SBJsonParser *jsonParser = [[SBJsonParser new] autorelease];
        NSString *jsonString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        NSDictionary *dict = (NSDictionary*)[jsonParser objectWithString:jsonString];
        DLog(@"Got OK! Response: %@", dict);
        return [dict objectForKey:@"id"];
    }
    else
    {
        ErrorLog(@"Could not shorten using goo.gl: %@", urlResponse);
        return nil;
    }
}

+ (NSString *) isgdShorten:(NSString *)url
{
    NSString *encodedUrl = [url stringByAddingPercentEscapesForQuery];
    NSURL *requestUrl = [NSURL URLWithString:[NSString stringWithFormat:IsgdAPIURL, encodedUrl]];
    DLog(@"Shortening with url: %@", requestUrl);

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:requestUrl];

    NSHTTPURLResponse *urlResponse = nil;
    NSError *error = nil;

    NSData *data = [NSURLConnection sendSynchronousRequest:req
                                         returningResponse:&urlResponse
                                                     error:&error];

    if ([urlResponse statusCode] >= 200 && [urlResponse statusCode] < 300)
    {
        SBJsonParser *jsonParser = [[SBJsonParser new] autorelease];
        NSString *jsonString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        NSDictionary *dict = (NSDictionary*)[jsonParser objectWithString:jsonString];
        NSNumber *errorCode = [dict objectForKey:@"errorcode"];

        if (!errorCode)
        {
            NSString *shortURL = [dict objectForKey:@"shorturl"];
            DLog(@"Got OK! ShortURL: %@", shortURL);
            return shortURL;
        }
        else
        {
            ErrorLog(@"Could not shorten using is.gd: %@ %@", errorCode, [dict objectForKey:@"errormessage"]);
            return nil;
        }
    }
    else
    {
        ErrorLog(@"Could not shorten using is.gd: %@", urlResponse);
        return nil;
    }
}

+ (NSString *) tinyurlShorten:(NSString *)url
{
    NSURL *requestUrl = [NSURL URLWithString:[NSString stringWithFormat:TinyurlApiURL, url]];
    DLog(@"Shortening with url: %@", requestUrl);

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:requestUrl];

    NSHTTPURLResponse *urlResponse = nil;
    NSError *error = nil;

    NSData *data = [NSURLConnection sendSynchronousRequest:req
                                         returningResponse:&urlResponse
                                                     error:&error];

    if ([urlResponse statusCode] >= 200 && [urlResponse statusCode] < 300)
    {
        NSString *shortURL = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];

        if ([shortURL hasPrefix:@"http://"])
        {
            DLog(@"Got OK! ShortURL: %@", shortURL);
            return shortURL;
        }
        else
        {
            ErrorLog(@"Could not shorten using tinyurl.com: %@", shortURL);
            return nil;
        }
    }
    else
    {
        ErrorLog(@"Could not shorten using tinyurl.com: %@", urlResponse);
        return nil;
    }
}

@end

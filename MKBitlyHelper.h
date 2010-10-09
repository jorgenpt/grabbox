//
//  MKBitlyHelper.h
//  BitlyDemo
//
//  Created by Mugunth Kumar on 25-Jul-09.
//  Copyright 2009 MK Inc. All rights reserved.
//  http://mugunthkumar.com
//

#import <Foundation/Foundation.h>


@interface MKBitlyHelper : NSObject {

	NSString *loginName;
	NSString *apiKey;
}

-(MKBitlyHelper*) initWithLoginName: (NSString*) f_loginName andAPIKey: (NSString*) f_apiKey;
- (NSString*) shortenURL: (NSString*) f_longURL;

@end

//
//  BitlyHelper.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 10/1/10.
//  Copyright 2010 devSoft. All rights reserved.
//

@interface BitlyHelper : NSObject {
    NSString *loginName;
    NSString *apiKey;
}

@property (nonatomic, copy) NSString *loginName;
@property (nonatomic, copy) NSString *apiKey;

+ (id) helperWithLogin:(NSString*)login
             andAPIKey:(NSString*)key;

- (id) initWithLogin:(NSString*)login
           andAPIKey:(NSString*)key;
- (void) dealloc;

- (NSString*) shortenURL:(NSString*)url;

@end

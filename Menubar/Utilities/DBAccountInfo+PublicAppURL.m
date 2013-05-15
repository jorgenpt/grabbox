//
//  DBAccountInfo+PublicAppURL.m
//  GrabBox2
//
//  Created by Jørgen Tjernø on 12/12/12.
//
//

#import "DBAccountInfo+PublicAppURL.h"

@implementation DBAccountInfo (PublicAppURL)

- (NSString*)publicAppURL
{
    return [original objectForKey:@"public_app_url"];
}

@end

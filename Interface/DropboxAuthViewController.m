//
//  DropboxAuthViewController.m
//  GrabBox2
//
//  Created by Jørgen Tjernø on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DropboxAuthViewController.h"

#import "UploaderFactory.h"

@implementation DropboxAuthViewController

- (id)init
{
    return [super initWithNibName:@"DropboxAuthView" bundle:nil];
}

- (NSString *)windowTitle
{
    return @"Authorize GrabBox";
}

- (IBAction)open:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setInteger:HostDropbox forKey:CONFIG(Host)];
}

@end

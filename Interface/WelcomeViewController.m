//
//  WelcomeViewController.m
//  GrabBox2
//
//  Created by Jørgen Tjernø on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WelcomeViewController.h"

@implementation WelcomeViewController

- (id)init
{
    return [super initWithNibName:@"WelcomeView" bundle:nil];
}

- (NSString *)windowTitle
{
    return @"Welcome to GrabBox";
}

- (IBAction)finish:(id)sender
{
    [[[self view] window] close];
}

@end

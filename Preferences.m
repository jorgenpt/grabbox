//
//  Preferences.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "Preferences.h"

@implementation Preferences
@synthesize window;

- (void) awakeFromNib
{
    [window setReleasedWhenClosed:NO];
}

@end

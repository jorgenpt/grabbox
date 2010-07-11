//
//  InitialStartup.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "InitialStartup.h"


@implementation InitialStartup

@synthesize window;

- (void) checkClipboard: (NSTimer *) timer
{
}

- (void) startClipboardTimer
{
	[timer release];
	timer = [NSTimer scheduledTimerWithTimeInterval: 0.5
											 target: self
										   selector: @selector(checkClipboard:)
										   userInfo: nil
											repeats: YES];
	[timer retain];
}

@end

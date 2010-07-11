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
@synthesize dropboxId;

- (id) init
{
	if (self = [super init])
	{
		timer = nil;
		lastIdFromUrl = 0;
	}
	return self;
}
- (void) dealloc
{
	[timer release];
	[super dealloc];
}

- (IBAction) okClicked:(id)sender
{
}

- (void) windowDidBecomeKey:(NSNotification *)aNotification
{
	if (!timer)
	{
		timer = [[NSTimer scheduledTimerWithTimeInterval: 0.5
												  target: self
												selector: @selector(checkClipboard:)
												userInfo: nil
												 repeats: YES] retain];
	}
}

- (void) checkClipboard: (NSTimer *) timer
{
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	NSArray *classes = [NSArray arrayWithObjects:[NSString class], nil];
	NSDictionary *options = [NSDictionary dictionary];
	NSArray *copiedItems = [pasteboard readObjectsForClasses:classes options:options];
	if (!copiedItems)
		return;

	NSURL *url = [NSURL URLWithString:[copiedItems objectAtIndex:0]];
	if (!url)
		return;

	if ([[url host] hasSuffix:@".dropbox.com"])
	{
		NSArray* components = [url pathComponents];
		NSString* dirComponent = [components objectAtIndex:1];
		if (![dirComponent isEqualToString:@"u"])
			return;

		NSString* idComponent = [components objectAtIndex:2];
		int idFromUrl = [idComponent intValue];
		if (idFromUrl && idFromUrl != lastIdFromUrl)
		{
			lastIdFromUrl = idFromUrl;
			[dropboxId setIntValue:idFromUrl];
		}
	}
}

@end

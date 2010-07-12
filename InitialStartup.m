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
@synthesize appDelegate;

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

- (void) close
{
	[timer invalidate];
	[timer release];
	timer = nil;
	lastIdFromUrl = 0;
	
	[window orderOut:self];
}

- (IBAction) okClicked:(id)sender
{
	NSString* enteredValue = [dropboxId stringValue];
	int intValue = [enteredValue integerValue];
	NSString* stringRepresentation = [NSString stringWithFormat:@"%d", intValue];
	NSAlert* alert = nil;
	
	if (!intValue)
	{
		alert = [NSAlert alertWithMessageText:nil
								defaultButton:nil
							  alternateButton:nil
								  otherButton:nil
					informativeTextWithFormat:@"You must enter a valid Dropbox ID to continue!"];
	}
	else if (![enteredValue isEqualToString:stringRepresentation])
	{
		alert = [NSAlert alertWithMessageText:nil
								defaultButton:nil
							  alternateButton:nil
								  otherButton:nil
					informativeTextWithFormat:@"The entered Dropbox ID contains invalid characters!"];

	}
	
	if (!alert)
	{
		[self close];
		[appDelegate setDropboxId:intValue];
		[appDelegate startMonitoring];
	}
	else
	{
		[alert beginSheetModalForWindow:window
						  modalDelegate:nil
						 didEndSelector:nil
							contextInfo:nil];
	}

}

- (IBAction)cancelClicked: (id) sender
{
	if ([appDelegate dropboxId])
	{
		[self close];
	}
	else {
		[[NSApplication sharedApplication] terminate:self];
	}

}

- (void) windowDidBecomeKey:(NSNotification *)aNotification
{
	if (!timer)
	{
		[dropboxId setIntValue:[appDelegate dropboxId]];
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

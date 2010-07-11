//
//  InformationGatherer.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "InformationGatherer.h"


@implementation InformationGatherer

- (id) init
{
	if (self = [super init])
	{
		dirContents = [self files];
		if (!dirContents)
			return nil;
		screenshotPath = nil;
		uploadPath = nil;
	}

	return self;
}

- (void) dealloc
{
	[dirContents release];
	[screenshotPath release];
	[uploadPath release];
	[super dealloc];
}

- (NSSet *)newFiles
{
	NSSet *newContents = [[self files] retain];
	if (!newContents)
		return nil;
	
	NSSet* newEntries = [newContents objectsPassingTest:^ BOOL (id obj, BOOL* stop) {
		return [dirContents member:obj] == nil;
	}];

	[dirContents release];
	dirContents = newContents;
	return newEntries;
}

- (NSSet *)files
{
	NSError* error;
	NSFileManager* fm = [NSFileManager defaultManager];
	NSArray* dirList = [fm contentsOfDirectoryAtPath:[self screenshotPath]
											   error:&error];
	if (!dirList)
	{
		NSLog(@"Failed getting dirlist: %@", [error localizedDescription]);
		return nil;
	}
	
	return [NSSet setWithArray:dirList];
}
- (NSString *)screenshotPath
{
	if (screenshotPath)
		return screenshotPath;
	
	// Look up ScreenCapture location, or use ~/Desktop as default.
	NSDictionary*  dict = [[NSUserDefaults standardUserDefaults]
						   persistentDomainForName:@"com.apple.screencapture"];
	NSString* foundPath = [dict objectForKey:@"location"];
	if (!foundPath)
		foundPath = @"~/Desktop";

	screenshotPath = [[foundPath stringByStandardizingPath] retain];

	return screenshotPath;
}

- (NSString *)uploadPath
{
	if (uploadPath)
		return uploadPath;

	uploadPath = [[@"~/Dropbox/Public/Screenshots" stringByStandardizingPath] retain];
	return uploadPath;
}

@end

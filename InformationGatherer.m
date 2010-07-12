//
//  InformationGatherer.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "InformationGatherer.h"

#include "sqlite3.h"

@implementation InformationGatherer

- (id) init
{
	if (self = [super init])
	{
		dirContents = [[self files] retain];
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

	NSString *result = @"~/Dropbox";
	NSString* path = [@"~/.dropbox/dropbox.db" stringByStandardizingPath];
	NSString* sqlStatement = @"select value from config where key = 'dropbox_path'";
	
	sqlite3 *db;
	sqlite3_stmt *statement;

	if (sqlite3_open_v2([path UTF8String], &db, SQLITE_OPEN_READONLY, NULL) == SQLITE_OK)
	{
		if (sqlite3_prepare_v2(db, [sqlStatement UTF8String], -1, &statement, 0) == SQLITE_OK)
		{
			if (sqlite3_step(statement) == SQLITE_ROW)
			{
				result = [NSString stringWithUTF8String:(char*)sqlite3_column_text(statement, 0)];
			}
			sqlite3_finalize(statement);
		}
		sqlite3_close(db);
	}

	NSArray* pathComponents = [NSArray arrayWithObjects:result, "Public", "Screenshots", nil];
	uploadPath = [[[NSString pathWithComponents:pathComponents] stringByStandardizingPath] retain];
	return uploadPath;
}

- (NSSet *)createdFiles
{
	NSSet *newContents = [self files];
	if (!newContents)
		return nil;
	
	NSSet* newEntries = [newContents objectsPassingTest:^ BOOL (id obj, BOOL* stop) {
		return [dirContents member:obj] == nil;
	}];
	
	[dirContents release];
	dirContents = [newContents retain];
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

- (NSString *)getURLForFile:(NSString *)file withId:(int)dropboxId
{
	NSString *escapedFile = [file stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
	// "http://dl.dropbox.com/u/%d/Screenshots/%@"
	return  [NSString stringWithFormat:@"http://o7.no/%d/%@", dropboxId, escapedFile];
}
@end

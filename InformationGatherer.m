//
//  InformationGatherer.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "InformationGatherer.h"

#include "sqlite3.h"

@interface InformationGatherer ()
@property (nonatomic, retain) NSString* screenshotPath;
@property (nonatomic, retain) NSString* uploadPath;
@property (nonatomic, retain) NSSet* dirContents;
@end

@implementation InformationGatherer

@synthesize screenshotPath;
@synthesize uploadPath;
@synthesize dirContents;

- (id) init
{
	if (self = [super init])
	{
		[self setDirContents:[self files]];
		if (!dirContents)
			return nil;
		screenshotPath = nil;
		uploadPath = nil;
	}

	return self;
}

- (void) dealloc
{
	[self setDirContents:nil];
	[self setScreenshotPath:nil];
	[self setUploadPath:nil];
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

	[self setScreenshotPath:[foundPath stringByStandardizingPath]];

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
	[self setUploadPath:[[NSString pathWithComponents:pathComponents] stringByStandardizingPath]];
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
	
	[self setDirContents:newContents];
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

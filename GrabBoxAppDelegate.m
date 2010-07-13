//
//  GrabBoxAppDelegate.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GrabBoxAppDelegate.h"
#import "FSRefConversions.h"

#import "Growler.h"
#import "Pasteboarder.h"

@interface GrabBoxAppDelegate ()
@property (nonatomic, assign) InformationGatherer* info;
@property (nonatomic, retain) Notifier* notifier;
@end


@implementation GrabBoxAppDelegate

@synthesize window;
@synthesize initialStartupWindow;
@synthesize info;
@synthesize notifier;

static void translateEvent(ConstFSEventStreamRef stream, 
						   void *clientCallBackInfo, 
						   size_t numEvents, 
						   void *eventPathsVoidPointer, 
						   const FSEventStreamEventFlags eventFlags[], 
						   const FSEventStreamEventId eventIds[]
						   ) {
	NSArray *paths = (NSArray*)eventPathsVoidPointer;	
	[(GrabBoxAppDelegate *)clientCallBackInfo eventForStream:stream
													   paths:paths
													   flags:eventFlags
														 ids:eventIds];
}

- (void) awakeFromNib
{
	[self setInfo:[[InformationGatherer alloc] init]];
	[self setNotifier:[Notifier notifierWithCallback:translateEvent
												path:[info screenshotPath]
									callbackArgument:self]];
}

- (void) dealloc
{
	[self setInfo:nil];
	[self setNotifier:nil];
	[super dealloc];
}

- (int) dropboxId
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:@"dropbox_id"];
}

- (void) setDropboxId:(int) toId
{
	[[NSUserDefaults standardUserDefaults] setInteger:toId forKey:@"dropbox_id"];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	if ([self dropboxId] == 0)
	{
		[initialStartupWindow makeKeyAndOrderFront:self];
	}
	else
	{
		[self startMonitoring];
	}
}


- (void) startMonitoring
{
	[notifier start];
}

- (NSString *) getNextFilenameWithExtension:(NSString *)ext
									   from:(NSString *)dir
{
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* characters = @"0123456789abcdefghijklmnopqrstuvwxyz";
	
	NSMutableArray* prefixes = [NSMutableArray arrayWithObject:@""];

	for (int c = 0; c < [prefixes count]; ++c)
	{
		NSString* prefix = [prefixes objectAtIndex:c];
		if ([prefix length] > MAX_NAME_LENGTH)
			return nil;

		for (int i = 0; i < [characters length]; i++)
		{
			NSString* filename = [prefix stringByAppendingString:[characters substringWithRange:NSMakeRange(i, 1)]];
			[prefixes addObject:filename];
			filename = [filename stringByAppendingFormat:@".%@", ext];

			NSString* path = [NSString pathWithComponents:[NSArray arrayWithObjects:dir, filename, nil]];
			if (![fm fileExistsAtPath:path])
				return filename;	
		}
	}

	return nil;
}

- (void) eventForStream:(ConstFSEventStreamRef)stream
				  paths:(NSArray *)paths
				  flags:(const FSEventStreamEventFlags[])flags
					ids:(const FSEventStreamEventId[]) ids
{
	NSString* screenshotPath = [info screenshotPath];
	FSRef screenshotPathRef;
	if (![screenshotPath getFSRef:&screenshotPathRef])
	{
		[Growler errorWithTitle:@"Could not get Screen Grab path!"
					description:@"Could not find directory to monitor for screenshots."];
		NSLog(@"ERROR: Failed getting FSRef for screenshotPath '%@'", screenshotPath);
		return;
	}
	
	BOOL screenshotDirChanged = NO;
	
	for (NSString* path in paths)
	{
		FSRef pathRef;
		if (![path getFSRef:&pathRef])
		{
			NSLog(@"ERROR: Failed getting FSRef for path '%@'", path);
			continue;
		}
		
		OSErr comparison = FSCompareFSRefs(&screenshotPathRef, &pathRef);
		if (comparison == diffVolErr || comparison == errFSRefsDifferent)
		{
			continue;
		}
		
		if (comparison != noErr)
		{
			NSLog(@"ERROR: Failed comparing FSRef for path (%@) and screenshotPath (%@): %i", path, screenshotPath, comparison);
			continue;
		}
		
		screenshotDirChanged = YES;
		break;
	}
	
	if (!screenshotDirChanged)
		return;
	
	NSSet* newEntries = [info createdFiles];
	NSError* error;
	NSString* uploadPath = [info uploadPath];
	NSFileManager* fm = [NSFileManager defaultManager];
	BOOL mkdirOk = [fm createDirectoryAtPath:uploadPath
				 withIntermediateDirectories:YES
								  attributes:nil
									   error:&error];
	if (!mkdirOk)
	{
		[Growler errorWithTitle:@"Could not copy file!"
					description:[error localizedDescription]];
		NSLog(@"ERROR: %@ (%i)", [error localizedDescription], [error code]);
		return;
	}
	
	for (NSString* entry in newEntries) {
		if (![entry hasPrefix:@"Screen shot "])
			continue;
		
		NSString* shortName = [self getNextFilenameWithExtension:[entry pathExtension]
															from:uploadPath];
		if (!shortName)
			shortName = entry;

		NSString* sourcePath = [NSString pathWithComponents:[NSArray arrayWithObjects: screenshotPath, entry, nil]];
		NSString* destPath = [NSString pathWithComponents:[NSArray arrayWithObjects: uploadPath, shortName, nil]];
		BOOL moveOk = [fm moveItemAtPath:sourcePath
								  toPath:destPath
								   error:&error];
		if (!moveOk)
		{
			[Growler errorWithTitle:@"Could not upload file!"
						description:[error localizedDescription]];
			NSLog(@"ERROR: %@ (%i)", [error localizedDescription], [error code]);
		}
		else
		{
			NSString *dropboxUrl = [info getURLForFile:shortName withId:[self dropboxId]];
			[[Pasteboarder pasteboarder] copy:dropboxUrl];
		}
	}
}

@end

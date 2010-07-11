//
//  GrabBoxAppDelegate.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GrabBoxAppDelegate.h"
#import "FSRefConversions.h"

@implementation GrabBoxAppDelegate

@synthesize window;
@synthesize initialStartupWindow;

static void translateEvent(ConstFSEventStreamRef stream, 
						   void *clientCallBackInfo, 
						   size_t numEvents, 
						   void *eventPathsVoidPointer, 
						   const FSEventStreamEventFlags eventFlags[], 
						   const FSEventStreamEventId eventIds[]
						   ) {
	NSMutableArray *paths = [NSMutableArray arrayWithCapacity:numEvents];
	char **eventPaths = eventPathsVoidPointer;
	for (size_t event = 0; event < numEvents; ++event)
		[paths addObject:[NSString stringWithUTF8String:eventPaths[event]]];
	
	[(GrabBoxAppDelegate *)clientCallBackInfo eventForStream:stream
													   paths:paths
													   flags:eventFlags
														 ids:eventIds];
}

- (id) init
{
	if (self = [super init])
	{
		info = [[InformationGatherer alloc] init];
		notifier = [[Notifier notifierWithCallback:translateEvent path:[info screenshotPath] callbackArgument:self] retain];
	}
	return self;
}

- (void) dealloc
{
	[info release];
	[notifier release];
	[super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSLog(@"App started!");
	
	[notifier start];
	NSUserDefaults* u = [NSUserDefaults standardUserDefaults];
	if ([u integerForKey:@"dropbox_id"] == 0)
	{
		[initialStartupWindow makeKeyAndOrderFront:self];
	}
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
			return;
		}
		
		OSErr comparison = FSCompareFSRefs(&screenshotPathRef, &pathRef);
		if (comparison == diffVolErr || comparison == errFSRefsDifferent)
		{
			continue;
		}
		
		if (comparison != noErr)
		{
			NSLog(@"ERROR: Failed comparing FSRef for path (%@) and screenshotPath (%@): %i", path, screenshotPath, comparison);
			// TODO: Should we continue; instead?
			return;
		}
		
		screenshotDirChanged = YES;
		break;
	}
	
	if (!screenshotDirChanged)
		return;
	
	NSSet* newEntries = [info newFiles];
	NSError* error;
	NSString* uploadPath = [info uploadPath];
	NSFileManager* fm = [NSFileManager defaultManager];
	BOOL mkdirOk = [fm createDirectoryAtPath:uploadPath
				 withIntermediateDirectories:YES
								  attributes:nil
									   error:&error];
	if (!mkdirOk)
	{
		NSLog(@"Error: %@ (%i)", [error localizedDescription], [error code]);
		return;
	}
	
	for (NSString* entry in newEntries) {
		if (![entry hasPrefix:@"Screen shot "])
			continue;
		
		NSString* sourcePath = [NSString pathWithComponents:[NSArray arrayWithObjects: screenshotPath, entry, nil]];
		NSString* destPath = [NSString pathWithComponents:[NSArray arrayWithObjects: uploadPath, entry, nil]];
		BOOL moveOk = [fm moveItemAtPath:sourcePath
								  toPath:destPath
								   error:&error];
		if (!moveOk)
		{
			NSLog(@"Error: %@ (%i)", [error localizedDescription], [error code]);
		}
		else
		{
			NSLog(@"Move of %@ succeeded!", entry);
		}
	}
}

@end

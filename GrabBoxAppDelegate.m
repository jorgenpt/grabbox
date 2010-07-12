//
//  GrabBoxAppDelegate.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GrabBoxAppDelegate.h"
#import "FSRefConversions.h"

@interface GrabBoxAppDelegate ()
@property (nonatomic) InformationGatherer* info;
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
			NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
			[pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
			
			NSString *dropboxUrl = [info getURLForFile:entry withId:[self dropboxId]];
			if (![pasteboard setString:dropboxUrl forType:NSStringPboardType])
			{
				// TODO: Growl this?
				NSLog(@"Error: Couldn't put url into pasteboard.");
			}
			
			// TODO: Growl success.
		}
	}
}

@end

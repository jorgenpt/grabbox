//
//  main.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Notifier.h"
#import "FSRefConversions.h"

#include <sys/types.h>
#include <dirent.h>

static NSString* screenshotPath;
static NSSet *dirContents;

static void gotEvent(ConstFSEventStreamRef streamRef, 
					 void *clientCallBackInfo, 
					 size_t numEvents, 
					 void *eventPaths, 
					 const FSEventStreamEventFlags eventFlags[], 
					 const FSEventStreamEventId eventIds[]);

int main(int argc, const char *argv[])
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	// Look up ScreenCapture location, or use ~/Desktop as default.
	NSDictionary*  dict = [[NSUserDefaults standardUserDefaults]
						   persistentDomainForName:@"com.apple.screencapture"];
	screenshotPath = [dict objectForKey:@"location"];
	if (!screenshotPath)
		screenshotPath = @"~/Desktop";
	screenshotPath = [screenshotPath stringByStandardizingPath];	

	Notifier* notifier = [Notifier notifierWithCallback:gotEvent path:screenshotPath];
	[notifier start];

	NSError* error;
	dirContents = [NSSet setWithArray:[[NSFileManager defaultManager]
									   contentsOfDirectoryAtPath:screenshotPath error:&error]];

	int returnValue = NSApplicationMain(argc,  argv);

	[pool drain];

	return returnValue;
}

static void gotEvent(ConstFSEventStreamRef stream, 
					 void *clientCallBackInfo, 
					 size_t numEvents, 
					 void *eventPathsVoidPointer, 
					 const FSEventStreamEventFlags eventFlags[], 
					 const FSEventStreamEventId eventIds[]
					 ) {
	FSRef screenshotPathRef;
	if (![screenshotPath getFSRef:&screenshotPathRef])
	{
		NSLog(@"ERROR: Failed getting FSRef for screenshotPath '%@'", screenshotPath);
		return;
	}

	BOOL screenshotDirChanged = NO;
	
	NSArray* eventPaths = eventPathsVoidPointer;
	for (size_t event = 0; event < numEvents; ++event)
	{
		NSString *eventPath = [eventPaths objectAtIndex:event];
		FSRef eventPathRef;
		if (![eventPath getFSRef:&eventPathRef])
		{
			NSLog(@"ERROR: Failed getting FSRef for eventPath '%@'", eventPath);
			return;
		}

		OSErr comparison = FSCompareFSRefs(&screenshotPathRef, &eventPathRef);
		if (comparison == diffVolErr || comparison == errFSRefsDifferent)
		{
			continue;
		}
		
		if (comparison != noErr)
		{
			NSLog(@"ERROR: Failed comparing FSRef for eventPath (%@) and screenshotPath (%@): %i", eventPath, screenshotPath, comparison);
			// TODO: Should we continue; instead?
			return;
		}
		
		screenshotDirChanged = YES;
		break;
	}
	
	if (!screenshotDirChanged)
		return;
	
	NSError* error;
	NSFileManager* fm = [NSFileManager defaultManager];
	NSSet* newContents = [NSSet setWithArray: [fm
											   contentsOfDirectoryAtPath:screenshotPath
											   error:&error]];
	// TODO: Check error
	NSSet* newEntries = [newContents objectsPassingTest:^ BOOL (id obj, BOOL* stop) {
		return [dirContents member:obj] == nil;
	}];
	dirContents = newContents;

	NSString* uploadPath = [@"~/Dropbox/Public/Screenshots" stringByStandardizingPath];
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

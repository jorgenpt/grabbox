#import "Notifier.h"

static void gotEvent(ConstFSEventStreamRef streamRef, 
					 void *clientCallBackInfo, 
					 size_t numEvents, 
					 void *eventPaths, 
					 const FSEventStreamEventFlags eventFlags[], 
					 const FSEventStreamEventId eventIds[]);

int main (int argc, char **argv) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSArray *paths = [[NSProcessInfo processInfo] arguments];

	NSMutableArray *streams = [NSMutableArray arrayWithCapacity:[paths count]];
	for (NSString *path in paths) {
		[streams addObject:[Notifier notifierWithCallback:gotEvent path:path]];
	}

	[streams makeObjectsPerformSelector:@selector(start)];
	CFRunLoopRun();

	[pool drain];
	return EXIT_SUCCESS;
}

static void gotEvent(ConstFSEventStreamRef stream, 
					 void *clientCallBackInfo, 
					 size_t numEvents, 
					 void *eventPathsVoidPointer, 
					 const FSEventStreamEventFlags eventFlags[], 
					 const FSEventStreamEventId eventIds[]
) {
	NSArray *eventPaths = eventPathsVoidPointer;
	NSString *streamName = clientCallBackInfo;
        for (size_t event = 0; event < numEvents; ++event)
        {
            NSString *eventPath = [eventPaths objectAtIndex:event];
            NSString *fileName = [eventPath lastPathComponent];
            NSLog(@"%@: %@ (%@)", streamName, eventPath, fileName);
        }
}

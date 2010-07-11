//
//  InformationGatherer.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface InformationGatherer : NSObject {
	NSString* screenshotPath;
	NSString* uploadPath;
	NSSet* dirContents;
}

- (id)init;
- (void) dealloc;

- (NSSet *)newFiles;
- (NSSet *)files;

- (NSString *)screenshotPath;
- (NSString *)uploadPath;

@end

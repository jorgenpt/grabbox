//
//  FSRefConversions.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/9/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "FSRefConversions.h"

@implementation NSString (FSRefConversions)

+ (NSString *) stringWithFSRef:(const FSRef *)aFSRef
{
    CFURLRef theURL = CFURLCreateFromFSRef(kCFAllocatorDefault, aFSRef);
    NSString* thePath = [(NSURL *)theURL path];
    CFRelease(theURL);
    return thePath;
}

- (BOOL) fsRef:(FSRef *)aFSRef
{
    return FSPathMakeRef((const UInt8 *)[self fileSystemRepresentation], aFSRef, NULL) == noErr;
}

@end

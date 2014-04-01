//
//  FSRefConversions.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/9/10.
//  Copyright (C) 2014 Jørgen P. Tjernø. Licensed under GPLv2, see LICENSE in the project root for more info.
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

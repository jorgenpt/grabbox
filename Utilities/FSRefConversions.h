//
//  FSRefConversions.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/9/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSString (FSRefConversions)
+ (NSString *)stringWithFSRef:(const FSRef *)aFSRef;
- (BOOL)getFSRef:(FSRef *)aFSRef;
@end

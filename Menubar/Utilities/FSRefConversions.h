//
//  FSRefConversions.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/9/10.
//  Copyright (C) 2014 Jørgen P. Tjernø. Licensed under GPLv2, see LICENSE in the project root for more info.
//

#import <Cocoa/Cocoa.h>

@interface NSString (FSRefConversions)

+ (NSString *) stringWithFSRef:(const FSRef *)aFSRef;
- (BOOL) fsRef:(FSRef *)aFSRef;

@end

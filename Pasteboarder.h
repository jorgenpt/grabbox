//
//  Pasteboarder.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlerDelegate.h"

@interface Pasteboarder : NSObject <GrowlerDelegate> {

}

+ (id) pasteboarder;
- (void) copy:(NSString *)url;
- (void) growlClickedWithData:(id)data;
- (void) growlTimedOutWithData:(id)data;

@end

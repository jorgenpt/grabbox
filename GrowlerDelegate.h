//
//  GrowlerDelegate.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol GrowlerDelegate
- (void) growlClickedWithData:(id)data;
- (void) growlTimedOutWithData:(id)data;
@end

@interface GrowlerDelegateContext : NSObject {
	id <GrowlerDelegate> delegate;
	id data;
}

@property (nonatomic, retain) id <GrowlerDelegate> delegate;
@property (nonatomic, retain) id data;

+ (id) contextWithDelegate:(id <GrowlerDelegate>)delegate data:(id)data;
- (id) initWithDelegate:(id <GrowlerDelegate>)delegate data:(id)data;
- (void) dealloc;

@end

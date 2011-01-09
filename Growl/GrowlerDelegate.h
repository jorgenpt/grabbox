//
//  GrowlerDelegate.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol GrowlerDelegate
- (void) growlClickedWithData:(id)data;
- (void) growlTimedOutWithData:(id)data;
@end

@interface GrowlerDelegateContext : NSObject {
    id <NSObject> target;
    SEL clickedSelector, timedOutSelector;
    id data;
}

@property (nonatomic, retain) id <NSObject> target;
@property (nonatomic, retain) id data;
@property (assign) SEL clickedSelector, timedOutSelector;

+ (id) contextWithDelegate:(id <GrowlerDelegate>)delegate data:(id)data;
+ (id) contextWithTarget:(id)theTarget
         clickedSelector:(SEL)clicked
        timedOutSelector:(SEL)timedOut
                    data:(id)userData;

- (id) initWithDelegate:(id <GrowlerDelegate>)delegate
                   data:(id)userData;
- (id) initWithTarget:(id)theTarget
      clickedSelector:(SEL)clicked
     timedOutSelector:(SEL)timedOut
                 data:(id)userData;

- (void) dealloc;

@end

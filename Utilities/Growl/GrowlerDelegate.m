//
//  GrowlerDelegate.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "GrowlerDelegate.h"

@implementation GrowlerDelegateContext

@synthesize target;
@synthesize data;
@synthesize clickedSelector;
@synthesize timedOutSelector;

+ (id) contextWithDelegate:(id <GrowlerDelegate>)delegate
                      data:(id)data
{
    return [[[self alloc] initWithDelegate:delegate data:data] autorelease];
}

+ (id) contextWithTarget:(id)theTarget
         clickedSelector:(SEL)clicked
        timedOutSelector:(SEL)timedOut
                    data:(id)userData
{
    return [[[self alloc] initWithTarget:theTarget
                         clickedSelector:clicked
                        timedOutSelector:timedOut
                                    data:userData] autorelease];
}

- (id) initWithDelegate:(id <GrowlerDelegate>)delegate
                   data:(id)userData
{
    return [self initWithTarget:delegate
                clickedSelector:@selector(growlClickedWithData:)
               timedOutSelector:@selector(growlTimedOutWithData:)
                           data:userData];
}

- (id) initWithTarget:(id)theTarget
      clickedSelector:(SEL)clicked
     timedOutSelector:(SEL)timedOut
                 data:(id)userData
{
    if (self = [super init])
    {
        [self setTarget:theTarget];
        [self setClickedSelector:clicked];
        [self setTimedOutSelector:timedOut];
        [self setData:userData];
    }
    
    return self;
}

- (void) dealloc
{
    [self setTarget:nil];
    [self setData:nil];

    [super dealloc];
}

@end

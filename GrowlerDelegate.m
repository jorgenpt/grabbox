//
//  GrowlerDelegate.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GrowlerDelegate.h"

@implementation GrowlerDelegateContext
@synthesize delegate;
@synthesize data;

+ (id) contextWithDelegate:(id <GrowlerDelegate>)delegate
					  data:(id)data
{
	return [[[GrowlerDelegateContext alloc] initWithDelegate:delegate data:data] autorelease];
}
- (id) initWithDelegate:(id <GrowlerDelegate>)initialDelegate
				   data:(id)initialData
{
	if (self = [super init])
	{
		[self setDelegate:initialDelegate];
		[self setData:initialData];
	}
	
	return self;
}
- (void) dealloc
{
	[self setDelegate:nil];
	[self setData:nil];
	
	[super dealloc];
}

@end

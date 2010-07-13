//
//  Growler.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Growler.h"

@implementation Growler

- (void)awakeFromNib
{
	[GrowlApplicationBridge setGrowlDelegate:self];
}

+ (void) errorWithTitle:(NSString *)title
			description:(NSString *)description
{
	[GrowlApplicationBridge notifyWithTitle:title
								description:description
						   notificationName:@"Error"
								   iconData:nil
								   priority:2 // EMERGENCY!
								   isSticky:NO
							   clickContext:nil];
}

+ (void) messageWithTitle:(NSString *)title
			  description:(NSString *)description
					 name:(NSString *)notificationName
				 delegateContext:(GrowlerDelegateContext *)context
{
	[Growler messageWithTitle:title
				  description:description
						 name:notificationName
			  delegateContext:context
					   sticky:NO];
}

+ (void) messageWithTitle:(NSString *)title
			  description:(NSString *)description
					 name:(NSString *)notificationName
		  delegateContext:(GrowlerDelegateContext *)context
				   sticky:(BOOL)stickiness
{
	[GrowlApplicationBridge notifyWithTitle:title
								description:description
						   notificationName:notificationName
								   iconData:nil
								   priority:0
								   isSticky:stickiness
							   clickContext:context];
}


- (void) growlNotificationWasClicked:(id)context
{
	[[context delegate] growlClickedWithData:[context data]];
}

- (void) growlNotificationTimedOut:(id)context
{
	[[context delegate] growlTimedOutWithData:[context data]];
}

- (void) growlIsReady
{
	NSLog(@"Growl is ready!");
}
@end

//
//  Growler.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Growl-WithInstaller/GrowlApplicationBridge.h"

#import "GrowlerDelegate.h"

@interface Growler : NSObject <GrowlApplicationBridgeDelegate> {

}

+ (void) errorWithTitle:(NSString *)title
			description:(NSString *)description;
+ (void) messageWithTitle:(NSString *)title
			  description:(NSString *)description
					 name:(NSString *)notificationName
		  delegateContext:(GrowlerDelegateContext *)context;
+ (void) messageWithTitle:(NSString *)title
			  description:(NSString *)description
					 name:(NSString *)notificationName
		  delegateContext:(GrowlerDelegateContext *)context
				   sticky:(BOOL)stickiness;

- (void) awakeFromNib;
- (void) growlNotificationWasClicked:(id)context;
- (void) growlNotificationTimedOut:(id)context;

- (void) growlIsReady;

@end

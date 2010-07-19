//
//  Growler.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>

#import "GrowlerDelegate.h"

@interface Growler : NSObject <GrowlApplicationBridgeDelegate> {
    NSMutableDictionary* contexts;
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

- (NSNumber*) addContext:(id)context;
- (GrowlerDelegateContext*) retrieveContextByKey:(id) contextKey;

- (void) awakeFromNib;
- (void) growlNotificationWasClicked:(id)context;
- (void) growlNotificationTimedOut:(id)context;

@end

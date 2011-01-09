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

@property (nonatomic, retain) NSMutableDictionary* contexts;

#pragma mark
#pragma mark Singleton management code
#pragma mark -

+ (id) sharedInstance;

- (id) init;
- (id) copyWithZone:(NSZone *)zone;
- (id) retain;
- (NSUInteger) retainCount;
- (void) release;
- (id) autorelease;

#pragma mark
#pragma mark -
#pragma mark Messaging

- (void) errorWithTitle:(NSString *)title
            description:(NSString *)description;
- (void) messageWithTitle:(NSString *)title
              description:(NSString *)description
                     name:(NSString *)notificationName
          delegateContext:(GrowlerDelegateContext *)context;
- (void) messageWithTitle:(NSString *)title
              description:(NSString *)description
                     name:(NSString *)notificationName
          delegateContext:(GrowlerDelegateContext *)context
                   sticky:(BOOL)stickiness;

#pragma mark
#pragma mark -
#pragma mark Context management

- (NSNumber *) addContext:(id)context;
- (GrowlerDelegateContext *) retrieveContextByKey:(id)contextKey;

#pragma mark
#pragma mark -
#pragma mark Growl callbacks

- (NSDictionary *) registrationDictionaryForGrowl;

- (void) growlNotificationWasClicked:(id)context;
- (void) growlNotificationTimedOut:(id)context;

@end

//
//  Growler.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "Growler.h"

@implementation Growler

- (void)awakeFromNib
{
    [GrowlApplicationBridge setGrowlDelegate:self];
    contexts = [[NSMutableDictionary alloc] init];
}

+ (void) errorWithTitle:(NSString *)title
            description:(NSString *)description
{
    NSImage* icon = [NSImage imageNamed:NSImageNameCaution];
    [GrowlApplicationBridge notifyWithTitle:title
                                description:description
                           notificationName:@"Error"
                                   iconData:[icon TIFFRepresentation]
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
    NSNumber* contextKey;
    if (context)
        contextKey = [(Growler*)[GrowlApplicationBridge growlDelegate] addContext:context];

    [GrowlApplicationBridge notifyWithTitle:title
                                description:description
                           notificationName:notificationName
                                   iconData:nil
                                   priority:0
                                   isSticky:stickiness
                               clickContext:contextKey];
}

- (NSNumber*) addContext:(id) context
{
    NSNumber* hash = [NSNumber numberWithInt:[context hash]];
    [contexts setObject:context forKey:hash];
    return hash;
}

- (GrowlerDelegateContext*) retrieveContextByKey:(id) contextKey
{
    GrowlerDelegateContext* context = [[contexts objectForKey:contextKey] retain];
    [contexts removeObjectForKey:contextKey];
    return [context autorelease];
}

- (void) growlNotificationWasClicked:(id)contextKey
{
    GrowlerDelegateContext* context = [self retrieveContextByKey:contextKey];
    [[context delegate] growlClickedWithData:[context data]];
}

- (void) growlNotificationTimedOut:(id)contextKey
{
    GrowlerDelegateContext* context = [self retrieveContextByKey:contextKey];
    [[context delegate] growlTimedOutWithData:[context data]];
}

@end

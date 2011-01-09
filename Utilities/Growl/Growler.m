//
//  Growler.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "Growler.h"

@implementation Growler

@synthesize contexts;
static Growler* sharedInstance = nil;

#pragma mark
#pragma mark Singleton management code
#pragma mark -

+ (id) sharedInstance
{
    @synchronized(self)
    {
        if (sharedInstance == nil)
            [[self alloc] init];
    }
    return sharedInstance;

}

+ (id) allocWithZone:(NSZone *)zone
{
    /* Make sure we're not allocated more than once. */
    @synchronized(self) {
        if (sharedInstance == nil) {
            return [super allocWithZone:zone];
        }
    }
    return sharedInstance;
}

- (id) init
{
    Class myClass = [self class];
    @synchronized(myClass) {
        if (sharedInstance == nil) {
            if (sharedInstance = [super init])
            {
                [GrowlApplicationBridge setGrowlDelegate:sharedInstance];
                [sharedInstance setContexts:[NSMutableDictionary dictionary]];
            }
        }
    }

    return sharedInstance;
}

/* Make sure there is always one instance, and make sure it's never free'd. */
- (id) copyWithZone:(NSZone *)zone { return self; }
- (id) retain { return self; }
- (NSUInteger) retainCount { return UINT_MAX; }
- (void) release {}
- (id) autorelease { return self; }

#pragma mark
#pragma mark -
#pragma mark Messaging

- (void) errorWithTitle:(NSString *)title
            description:(NSString *)description
{
    DLog(@"Growling error '%@' with title '%@'", description, title);
    NSImage* icon = [NSImage imageNamed:NSImageNameCaution];
    [GrowlApplicationBridge notifyWithTitle:title
                                description:description
                           notificationName:@"Error"
                                   iconData:[icon TIFFRepresentation]
                                   priority:2 // EMERGENCY!
                                   isSticky:NO
                               clickContext:nil];
}

- (void) messageWithTitle:(NSString *)title
              description:(NSString *)description
                     name:(NSString *)notificationName
          delegateContext:(GrowlerDelegateContext *)context
{
    [self messageWithTitle:title
               description:description
                      name:notificationName
           delegateContext:context
                    sticky:NO];
}

- (void) messageWithTitle:(NSString *)title
              description:(NSString *)description
                     name:(NSString *)notificationName
          delegateContext:(GrowlerDelegateContext *)context
                   sticky:(BOOL)stickiness
{
    DLog(@"Growling '%@' with title '%@' (%@)", description, title, notificationName);
    NSNumber* contextKey = nil;
    if (context)
        contextKey = [self addContext:context];

    [GrowlApplicationBridge notifyWithTitle:title
                                description:description
                           notificationName:notificationName
                                   iconData:nil
                                   priority:0
                                   isSticky:stickiness
                               clickContext:contextKey];
}

#pragma mark
#pragma mark -
#pragma mark Context management

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

#pragma mark
#pragma mark -
#pragma mark Growl callbacks

- (NSDictionary *) registrationDictionaryForGrowl
{
    /*
     * We do this so that the .bundle can be completely independent.
     * Normally, this data is just put into "Growl Registration Ticket.growlRegDict" in the resources of the
     * main app bundle, but that means that the bundle we're building has to be "invasive". Using this approach,
     * if you load and use the bundle, it'll use its own resources' "Growl Registration Ticket.growlRegDict" and
     * return that to the Growl app bridge.
     */

    NSBundle *bundle = [NSBundle bundleWithIdentifier:BUNDLE_IDENTIFIER];
    if (!bundle)
    {
        NSLog(@"Could not locate bundle for PublishBox!");
        return nil;
    }

    NSString *path = [bundle pathForResource:@"Growl Registration Ticket"
                                      ofType:@"growlRegDict"];
    if (!path)
    {
        NSLog(@"Could not locate Growl registration ticket bundle for PublishBox!");
        return nil;
    }

    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data)
    {
        NSLog(@"Could not read Growl registration ticket from %@", path);
        return nil;
    }

    NSString *errorDescription;
    NSDictionary *dictionary = [NSPropertyListSerialization propertyListFromData:data
                                                                mutabilityOption:0
                                                                          format:NULL
                                                                errorDescription:&errorDescription];
    if (errorDescription)
    {
        NSLog(@"Could not parse the Growl registration ticket from %@: %@", path, errorDescription);
        [errorDescription release];
        return nil;
    }

    DLog(@"RegistrationDictionary: %@", dictionary);
    return dictionary;
}

- (void) growlNotificationWasClicked:(id)contextKey
{
    GrowlerDelegateContext* context = [self retrieveContextByKey:contextKey];
    [[context target] performSelector:[context clickedSelector]
                           withObject:[context data]];
}

- (void) growlNotificationTimedOut:(id)contextKey
{
    GrowlerDelegateContext* context = [self retrieveContextByKey:contextKey];
    [[context target] performSelector:[context timedOutSelector]
                           withObject:[context data]];
}

@end

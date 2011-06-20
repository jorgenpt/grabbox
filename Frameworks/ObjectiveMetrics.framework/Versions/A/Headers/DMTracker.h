//
//  DMTracker.h
//  ObjectiveMetrics
//
//  Created by Jørgen P. Tjernø on 3/22/11.
//  Copyright 2011 devSoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DMTrackingQueueProtocol

- (NSUInteger)count;
- (NSDictionary *)eventAtIndex:(NSUInteger)index;

- (void)add:(NSDictionary *)event;
- (void)send:(NSDictionary *)event;

- (void)flush;
- (BOOL)blockingFlush;

@end

/**
  A class representing an ongoing application session for tracking purposes.
 */
@interface DMTracker : NSObject {
@private
    id<DMTrackingQueueProtocol> queue;
    NSString *session;
    int flow;
}

/**
  Returns the singleton instance of the DMTracker.
 */
+ (id) defaultTracker;

/**
  Initialize the tracker for a new session with your app.
 */
- (void)startApp;

/**
  Discard all requests to the tracker.
 */
- (void)disable;

/**
  Finalize the current app session. Only valid a single time after a call to
  startApp.
  It is implicitly called when the app sends a
  NSApplicationWillTerminateNotification or
  UIApplicationWillTerminateNotification.  Finalizing the app session will
  attempt to send all queued messages. If it fails, they will be attempted sent
  at the next app startup.

  @see NSApplicationWillTerminateNotification
  @see UIApplicationWillTerminateNotification
 */
- (void)stopApp;

#pragma mark -

/**
  Track an event.
  This is a batched event that will be sent when the app exits.

  @param theCategory The category of the event.
  @param theName The name of the event.
 */
- (void)trackEventInCategory:(NSString *)theCategory
                    withName:(NSString *)theName;

/**
  Track an event.
  This is a batched event that will be sent when the app exits.

  @param theCategory The category of the event.
  @param theName The name of the event.
  @param theValue The event value
 */
- (void)trackEventInCategory:(NSString *)theCategory
                    withName:(NSString *)theName
                       value:(NSString *)theValue;

/**
  Track an event related to a timed operation.
  This is a batched event that will be sent when the app exits.

  @param theCategory The category of the event.
  @param theName The name of the event.
  @param theSeconds The number of seconds the operation took to complete.
  @param wasCompleted Whether or not the operation completed successfully.
 */
- (void)trackEventInCategory:(NSString *)theCategory
                    withName:(NSString *)theName
                secondsSpent:(int)theSeconds
                   completed:(BOOL)wasCompleted;

/**
  Track a log entry.
  This is a batched event that will be sent when the app exits.

  @param format The message you want to log.
  @param ... Format-specific arguments.
 */
- (void)trackLog:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);

/**
  Track a custom data entry.

  @param theName The name of the data you're logging.
  @param theValue The value of this entry.
 */
- (void)trackCustomDataWithName:(NSString *)theName
                          value:(NSString *)theValue;

/**
 Track a custom data entry in realtime.
 This is a real-time event that is attempted sent immediately. It will be cached
 for delayed sending if there's no internet connection or another error occurs.

 @param theName The name of the data you're logging.
 @param theValue The value of this entry.
 */
- (void)trackCustomDataRealtimeWithName:(NSString *)theName
                                  value:(NSString *)theValue;

/**
 Track an exception.
 This is a real-time event that is attempted sent immediately. It will be cached
 for delayed sending if there's no internet connection or another error occurs.

 @param theException The exception you're logging.
 */
 - (void)trackException:(NSException *)theException;

@end

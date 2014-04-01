//
//  NetworkReachabilityNotifier.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 6/13/11.
//  Copyright (C) 2014 Jørgen P. Tjernø. Licensed under GPLv2, see LICENSE in the project root for more info.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SCNetworkReachability.h>

typedef void (^NetworkReachabilityChangedCallback)(SCNetworkReachabilityFlags flags);

@interface NetworkReachabilityNotifier : NSObject {
@private
    SCNetworkReachabilityRef reachability;
    NetworkReachabilityChangedCallback callback;
}

@property (copy) NetworkReachabilityChangedCallback callback;

- (id)initWithName:(NSString *)name;

- (BOOL)schedule;
- (BOOL)unschedule;
- (void)poll;

@end

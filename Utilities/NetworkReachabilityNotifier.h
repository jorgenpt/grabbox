//
//  NetworkReachabilityNotifier.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 6/13/11.
//  Copyright 2011 devSoft. All rights reserved.
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

- (BOOL)schedule;
- (BOOL)unschedule;
- (void)poll;

@end

//
//  GrabBoxAppDelegate.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GrabBoxAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end

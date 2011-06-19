//
//  DBCommonController.h
//  DropboxFramework
//
//  Created by Jørgen P. Tjernø on 1/16/11.
//  Copyright 2011 devSoft. All rights reserved.
//

#import "DBRestClient.h"

@protocol DBCommonControllerDelegate;

@interface DBCommonController : NSObject <DBRestClientDelegate> {
    DBRestClient *restClient;
    id<DBCommonControllerDelegate> delegate;
    NSWindow *window;
}

@property (nonatomic, retain) DBRestClient *restClient;
@property (nonatomic, assign) id<DBCommonControllerDelegate> delegate;
@property (nonatomic, assign) IBOutlet NSWindow *window;

- (void) presentFrom:(id)sender;
- (void) errorWithTitle:(NSString *)title
                message:(NSString *)message;

@end

@protocol DBCommonControllerDelegate

- (void) controllerDidComplete:(DBCommonController *)window;
- (void) controllerDidCancel:(DBCommonController *)window;

@end

//
//  DBAccountCreationController.h
//  DropboxFramework
//
//  Created by Jørgen P. Tjernø on 1/16/11.
//  Copyright 2011 devSoft. All rights reserved.
//

#import "DBCommonController.h"
#import "DBRestClient.h"

@protocol DBAccountCreationControllerDelegate;

@interface DBAccountCreationController : DBCommonController <NSWindowDelegate> {
    NSTextField *firstname, *lastname;
    NSTextField *email;
    NSTextField *password, *passwordVerify;
    
    BOOL creating;
}

@property (nonatomic, assign) IBOutlet NSTextField *firstname;
@property (nonatomic, assign) IBOutlet NSTextField *lastname;
@property (nonatomic, assign) IBOutlet NSTextField *email;
@property (nonatomic, assign) IBOutlet NSTextField *password;
@property (nonatomic, assign) IBOutlet NSTextField *passwordVerify;

- (id) init;

- (IBAction) createAccount:(id)sender;

@end



@protocol DBAccountCreationControllerDelegate

- (void) accountCreationControllerDidCreate:(DBAccountCreationController *)window;
- (void) accountCreationControllerDidCancel:(DBAccountCreationController *)window;

@end

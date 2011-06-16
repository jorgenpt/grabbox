//
//  DBLoginController.h
//  DropboxFramework
//
//  Created by Jørgen P. Tjernø on 1/16/11.
//  Copyright 2011 devSoft. All rights reserved.
//

#import "DBCommonController.h"
#import "DBAccountCreationController.h"


@interface DBLoginController : DBCommonController <NSWindowDelegate, DBCommonControllerDelegate> {
    NSTextField *username, *password;

    BOOL loggingIn;
    DBAccountCreationController *accountCreation;
}

@property (nonatomic, assign) IBOutlet NSTextField *username;
@property (nonatomic, assign) IBOutlet NSTextField *password;

@property (nonatomic, retain) DBAccountCreationController *accountCreation;

- (id) init;

- (IBAction) createAccount:(id)sender;
- (IBAction) linkAccount:(id)sender;

@end

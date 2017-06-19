#import "DropboxAuthViewController.h"

@implementation DropboxAuthViewController

- (NSString*)windowTitle
{
    return @"Set up GrabBox";
}

- (IBAction)open:(id)sender
{
    [DBClientsManager authorizeFromControllerDesktop:[NSWorkspace sharedWorkspace]
                                          controller:self
                                             openURL:^(NSURL *url){ [[NSWorkspace sharedWorkspace] openURL:url]; }];
}

@end

#import "WelcomeViewController.h"

@implementation WelcomeViewController

- (id)init
{
    return [super initWithNibName:@"WelcomeView" bundle:nil];
}

- (NSString *)windowTitle
{
    return @"Welcome to GrabBox";
}

- (IBAction)finish:(id)sender
{
    [[[self view] window] close];
}

@end

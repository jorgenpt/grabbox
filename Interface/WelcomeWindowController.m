#import "WelcomeWindowController.h"

#import "UploaderFactory.h"
#import "DropboxAuthViewController.h"
#import "WelcomeViewController.h"

@interface WelcomeWindowController ()

@property (retain) NSViewController<WindowContentDelegate> *currentVC;

@end

@implementation WelcomeWindowController

- (void) dealloc
{
    [self setCurrentVC:nil];

    [super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    [self presentVC:[[[DropboxAuthViewController alloc] initWithNibName:@"DropboxAuthView"
                                                                 bundle:nil] autorelease]];
}

- (void)presentVC:(NSViewController<WindowContentDelegate> *)vc
{
    self.currentVC = vc;
    self.window.title = vc.windowTitle;
    self.window.contentView = vc.view;
}

- (void)loggedIn
{
    [self presentVC:[[[WelcomeViewController alloc] initWithNibName:@"WelcomeView"
                                                             bundle:nil] autorelease]];
}
@end

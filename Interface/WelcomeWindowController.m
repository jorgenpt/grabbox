#import "WelcomeWindowController.h"

#import "UploaderFactory.h"
#import "DropboxAuthViewController.h"
#import "WelcomeViewController.h"

@interface WelcomeWindowController ()

@property (retain) NSViewController<WindowContentDelegate> *currentVC;

@end

@implementation WelcomeWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }

    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    NSAppleEventManager *em = [NSAppleEventManager sharedAppleEventManager];
    [em setEventHandler:self
            andSelector:@selector(getUrl:withReplyEvent:)
          forEventClass:kInternetEventClass
             andEventID:kAEGetURL];

    [self presentVC:[[[DropboxAuthViewController alloc] initWithNibName:@"DropboxAuthView"
                                                                 bundle:nil] autorelease]];
}

- (void)presentVC:(NSViewController<WindowContentDelegate> *)vc
{
    self.currentVC = vc;
    self.window.title = vc.windowTitle;
    self.window.contentView = vc.view;
}


- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    [[NSNotificationCenter defaultCenter] postNotificationName:GBGainedFocusNotification
                                                        object:self];

    [self presentVC:[[[WelcomeViewController alloc] initWithNibName:@"WelcomeView"
                                                             bundle:nil] autorelease]];
}
@end

#import <Cocoa/Cocoa.h>

@protocol WindowContentDelegate <NSObject>
- (NSString *)windowTitle;
@end

@interface WelcomeWindowController : NSWindowController

- (void)loggedIn;

@end

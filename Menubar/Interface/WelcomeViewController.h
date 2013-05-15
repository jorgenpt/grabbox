#import <Cocoa/Cocoa.h>

#import "WelcomeWindowController.h"

@interface WelcomeViewController : NSViewController <WindowContentDelegate>

- (IBAction)finish:(id)sender;
- (NSString *)windowTitle;

@end

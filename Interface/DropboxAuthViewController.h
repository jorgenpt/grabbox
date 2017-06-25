#import <Cocoa/Cocoa.h>

#import "WelcomeWindowController.h"

@interface DropboxAuthViewController : NSViewController <WindowContentDelegate>

@property (weak) IBOutlet NSButton *openButton;

- (IBAction)open:(id)sender;

@end

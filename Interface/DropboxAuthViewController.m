#import "DropboxAuthViewController.h"

@interface DropboxAuthViewController () <DBRestClientDelegate>
@property (retain) DBRestClient *restClient;
@end

@implementation DropboxAuthViewController

- (NSString*)windowTitle
{
    return @"Set up GrabBox";
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.restClient = [[[DBRestClient alloc] initWithSession:[DBSession sharedSession]] autorelease];
    self.restClient.delegate = self;

    [self.restClient loadRequestToken];
}

- (IBAction)open:(id)sender
{
    NSURL *url = [self.restClient authorizeURL];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

#pragma mark - DBRestClientDelegate

- (void)restClientLoadedRequestToken:(DBRestClient *)restClient
{
    [self.openButton setEnabled:YES];
}

- (void)restClientLoadedAccessToken:(DBRestClient *)restClient
{
    [self.restClient loadAccountInfo];
}

@end

//
//  Pasteboarder.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "Pasteboarder.h"
#import "Growler.h"

@implementation Pasteboarder

+ (id) pasteboarder
{
    return [[[Pasteboarder alloc] init] autorelease];
}

- (void) growlClickedWithData:(id)data
{
    [self copy:data];
}
- (void) copy:(NSString *)url
{
    NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];

    if (![pasteboard setString:url forType:NSStringPboardType])
    {
        NSString *errorDescription = [NSString stringWithFormat:@"Could not put URL '%@' into the clipboard, click here to try this operation again.", url];
        GrowlerDelegateContext *context = [GrowlerDelegateContext contextWithDelegate:self
                                                                                 data:url];
        [Growler messageWithTitle:@"Could not update pasteboard!"
                      description:errorDescription
                             name:@"Error"
                  delegateContext:context
                           sticky:YES];
        NSLog(@"ERROR: Couldn't put url into pasteboard.");
    }
    else {
        [Growler messageWithTitle:@"Screenshot uploaded!"
                      description:@"The screenshot has been uploaded and a link put in your clipboard."
         //Click here to give it a better name, or press Cmd-Opt-N."
                             name:@"URL Copied"
                  delegateContext:nil
                           sticky:NO];
    }

}

- (void) growlTimedOutWithData:(id)data
{
}

@end

//
//  InformationGatherer.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/10/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "InformationGatherer.h"

#import "NSData+Base64.h"

static InformationGatherer* defaultInstance = nil;

@interface InformationGatherer ()

@property (nonatomic, strong) NSString* screenshotPath;
@property (nonatomic, strong) NSString* localizedScreenshotPattern;
@property (nonatomic, strong) NSString* workQueuePath;
@property (nonatomic, strong) NSSet* dirContents;

@end

@implementation InformationGatherer

@synthesize screenshotPath;
@synthesize workQueuePath;
@synthesize localizedScreenshotPattern;
@synthesize dirContents;

#pragma mark -
#pragma mark Singleton management code

/* "The runtime sends initialize to each class in a program exactly one time
 * just before the class, or any class that inherits from it, is sent its first
 * message from within the program. (Thus the method may never be invoked if the
 * class is not used.) The runtime sends the initialize message to classes in a
 * thread-safe manner. Superclasses receive this message before their
 * subclasses."
 */
+ (void)initialize
{
    if (defaultInstance == nil)
        defaultInstance = [[self alloc] init];
}

+ (id) defaultGatherer
{
    return defaultInstance;
}

- (id) init
{
    if (defaultInstance == nil)
    {
        self = [super init];
        if (self)
        {
            [self setScreenshotPath:nil];
            [self setDirContents:[self files]];
        }
        return self;
    }

    return defaultInstance;
}


#pragma mark -
#pragma mark Information gathering

- (void) updateScreenshotPath
{
    if (screenshotPath)
        return;

    // Look up ScreenCapture location, or use ~/Desktop as default.
    NSDictionary*  dict = [[NSUserDefaults standardUserDefaults]
                           persistentDomainForName:@"com.apple.screencapture"];
    NSString* foundPath = [dict objectForKey:@"location"];
    if (!foundPath)
        foundPath = [@"~/Desktop" stringByStandardizingPath];
    else
    {
        BOOL isDir = FALSE;
        foundPath = [foundPath stringByStandardizingPath];
        if (![[NSFileManager defaultManager] fileExistsAtPath:foundPath
                                                  isDirectory:&isDir] || !isDir)
        {
            NSLog(@"Path specified in com.apple.screencapture location does not exist. Falling back to ~/Desktop.");
            foundPath = [@"~/Desktop" stringByStandardizingPath];
        }
    }

    DLog(@"screenshotPath: %@", foundPath);
    [self setScreenshotPath:foundPath];
}

- (NSString *) screenshotPath
{
    if (!screenshotPath)
    {
        @synchronized(self) { [self updateScreenshotPath]; }
    }

    return screenshotPath;
}

+ (NSDictionary *)stringsForTable:(NSString *)tableName
                       fromBundle:(NSBundle *)bundle
                  forLocalization:(NSString *)localization
{
    NSString *tablePath = [bundle pathForResource:tableName
                                           ofType:@"strings"
                                      inDirectory:@""
                                  forLocalization:localization];
    if (!tablePath)
    {
        NSLog(@"%@ doesn't have %@.strings.", localization, tableName);
        return nil;
    }

    NSInputStream* tableStream = [NSInputStream inputStreamWithFileAtPath:tablePath];
    [tableStream open];
    if ([tableStream streamStatus] == NSStreamStatusError)
    {
        ErrorLog(@"Couldn't load %@.lproj/%@.strings: %@", localization, tableName, [tableStream streamError]);
        return nil;
    }

    NSError *error = nil;
    NSDictionary* table = [NSPropertyListSerialization propertyListWithStream:tableStream
                                                                      options:NSPropertyListImmutable
                                                                       format:nil
                                                                        error:&error];
    if (error)
    {
        ErrorLog(@"Couldn't parse %@.lproj/%@.strings: %@", localization, tableName, error);
        return nil;
    }

    return table;
}

- (NSString *)localizedString:(NSString *)string
                   fromBundle:(NSBundle *)bundle
                        table:(NSString *)tableName
{
    for (NSString* language in [bundle preferredLocalizations])
    {
        /* Table of localized strings */
        NSDictionary *table = [InformationGatherer stringsForTable:tableName
                                                        fromBundle:bundle
                                                   forLocalization:language];
        if (!table)
        {
            ErrorLog(@"Lookup failed, trying next language.");
            continue;
        }

        /* If we find it - great! Return it. Otherwise, try next. */
        NSString* localizedString = [table objectForKey:string];
        if (localizedString)
        {
            return localizedString;
        }

        NSLog(@"No value for '%@' in %@, trying next preferred language (this isn't necessarily bad).", string, language);
    }

    ErrorLog(@"Could not look up a localization for %@ in table %@!", string, tableName);
    return string;
}

- (void) updateLocalizedScreenshotPattern
{
    if (localizedScreenshotPattern)
        return;

    /* These are the keys we look up for localization. */
    NSString *name = @"Screen Shot";
    NSString *format = @"%@ %@ at %@";
    NSString *formatTable = @"ScreenCapture";
    NSString* screenshotPattern = nil;

    /* Look up the SystemUIServer bundle - we'll be reading its localization strings. */
    NSBundle* systemUIServer = [NSBundle bundleWithPath:@"/System/Library/CoreServices/SystemUIServer.app"];
    if (systemUIServer)
    {
        NSDictionary*  dict = [[NSUserDefaults standardUserDefaults]
                               persistentDomainForName:@"com.apple.screencapture"];
        NSString* nameOverride = [dict objectForKey:@"name"];
        if (nameOverride)
            name = nameOverride;
        else
            name = [self localizedString:name fromBundle:systemUIServer table:@"ScreenCapture"];

        format = [self localizedString:format fromBundle:systemUIServer table:formatTable];
    }
    else
    {
        /* If we can't load the bundle stuff, something is severely wrong. We default to something sane, but log it. */
        ErrorLog(@"Could not load bundle for /System/Library/CoreServices/SystemUIServer.app");
    }

    screenshotPattern = [[NSString stringWithFormat:format, name, @"*", @"*"] stringByAppendingString:@".*"];
    DLog(@"Pattern is %@", screenshotPattern);

    [self setLocalizedScreenshotPattern:screenshotPattern];
}

- (NSString *) localizedScreenshotPattern
{
    if (!localizedScreenshotPattern)
    {
        @synchronized(self) { [self updateLocalizedScreenshotPattern]; }
    }

    return localizedScreenshotPattern;
}

- (void) updateWorkQueuePath
{
    if (workQueuePath)
        return;

    NSString *base = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    if ([paths count])
    {
        NSString *bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
        base = [[paths objectAtIndex:0] stringByAppendingPathComponent:bundleName];
    }
    else
    {
        base = NSTemporaryDirectory();
    }

    if (base)
    {
        NSError *error;
        [self setWorkQueuePath:[base stringByAppendingPathComponent:@"WorkQueue"]];
        if (![[NSFileManager defaultManager] createDirectoryAtPath:workQueuePath
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&error])
        {
            ErrorLog(@"%@ (%ld)", [error localizedDescription], [error code]);
            [self setWorkQueuePath:nil];
        }
    }
}

- (NSString *) workQueuePath
{
    if (!workQueuePath)
    {
        @synchronized(self) { [self updateWorkQueuePath]; }
    }

    return workQueuePath;
}

- (NSSet *)createdFiles
{
    NSSet *newContents = [self files];
    if (!newContents)
        return nil;

#if (MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_5)
    NSMutableSet* newEntries = [NSMutableSet set];
    for (id obj in newContents)
    {
        if ([dirContents member:obj] == nil)
        {
            [newEntries addObject:obj];
        }
    }
#else
    NSSet* newEntries = [newContents objectsPassingTest:^ BOOL (id obj, BOOL* stop) {
        return [dirContents member:obj] == nil;
    }];
#endif

    [self setDirContents:newContents];
    return newEntries;
}

- (NSSet *)filesInDirectory:(NSString *)path
{
    NSError* error;
    NSFileManager* fm = [NSFileManager defaultManager];
    NSArray* dirList = [fm contentsOfDirectoryAtPath:path
                                               error:&error];
    if (!dirList)
    {
        ErrorLog(@"Failed getting dirlist: %@", [error localizedDescription]);
        return [NSSet set];
    }

    return [NSSet setWithArray:dirList];
}

- (NSSet *)files
{
    return [self filesInDirectory:[self screenshotPath]];
}

@end

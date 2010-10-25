//
//  InformationGatherer.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/10/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "InformationGatherer.h"

#import "NSDataAdditions.h"

#include <sqlite3.h>

static InformationGatherer* defaultInstance = nil;

@interface InformationGatherer ()
@property (nonatomic, retain) NSString* screenshotPath;
@property (nonatomic, retain) NSString* uploadPath;
@property (nonatomic, retain) NSString* publicPath;
@property (nonatomic, retain) NSString* localizedScreenshotPattern;
@property (nonatomic, assign) BOOL isSnowLeopardOrNewer;
@property (nonatomic, retain) NSSet* dirContents;

@end

@implementation InformationGatherer

@synthesize screenshotPath;
@synthesize uploadPath;
@synthesize publicPath;
@synthesize localizedScreenshotPattern;
@synthesize isSnowLeopardOrNewer;
@synthesize dirContents;

+ (id) defaultGatherer
{
    @synchronized(self)
    {
        if (defaultInstance == nil)
            [[self alloc] init];
    }
    return defaultInstance;

}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (defaultInstance == nil) {
            return [super allocWithZone:zone];
        }
    }
    return defaultInstance;
}

- (id)init
{
    Class myClass = [self class];
    @synchronized(myClass) {
        if (defaultInstance == nil) {
            if (self = [super init]) {
                [self setDirContents:[self files]];
                [self setScreenshotPath:nil];
                [self setUploadPath:nil];
                [self setPublicPath:nil];

                SInt32 MacVersion;
                if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr && MacVersion < 0x1060)
                    [self setIsSnowLeopardOrNewer:NO];
                else
                    [self setIsSnowLeopardOrNewer:YES];

                defaultInstance = self;
            }
        }
    }
    return defaultInstance;
}

- (id) copyWithZone:(NSZone *)zone { return self; }
- (id) retain { return self; }
- (NSUInteger) retainCount { return UINT_MAX; }
- (void) release {}
- (id) autorelease { return self; }

- (NSString *)screenshotPath
{
    if (screenshotPath)
        return screenshotPath;

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

    return [self screenshotPath];
}

- (NSString *)uploadPath
{
    if (uploadPath)
        return uploadPath;

    NSString* path = [[[self publicPath] stringByAppendingPathComponent:@"Screenshots"] stringByStandardizingPath];

    DLog(@"uploadPath: %@", path);
    [self setUploadPath:path];
    return [self uploadPath];

}

- (NSString *)publicPath
{
    if (publicPath)
        return publicPath;
    NSString* result = [@"~/Dropbox" stringByStandardizingPath];
    NSString* path = [@"~/.dropbox/dropbox.db" stringByStandardizingPath];
    NSString* sqlStatement = @"select value from config where key = 'dropbox_path'";

    sqlite3 *db;
    sqlite3_stmt *statement;
#if (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5)
    if (sqlite3_open([path UTF8String], &db) == SQLITE_OK)
#else
    if (sqlite3_open_v2([path UTF8String], &db, SQLITE_OPEN_READONLY, NULL) == SQLITE_OK)
#endif

    {
        DLog(@"Found Dropbox DB, checking for config.");
        if (sqlite3_prepare_v2(db, [sqlStatement UTF8String], -1, &statement, 0) == SQLITE_OK)
        {
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                result = [NSString stringWithUTF8String:(char*)sqlite3_column_text(statement, 0)];
                DLog(@"Found dropbox_path row, %@.", result);

                /* Convert from Pickle
                 * XXX: THIS IS NOT SAFE! Pickle formats are internal and change without warning!
                 * (Though I don't think it does very often)
                 */
                NSData* data = [NSData dataWithBase64EncodedString:result];
                result = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
                result = [[[result componentsSeparatedByString:@"\n"] objectAtIndex:0] substringFromIndex:1];
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(db);
    }

    result = [[result stringByAppendingPathComponent:@"Public"] stringByStandardizingPath];
    DLog(@"publicPath: %@", result);
    [self setPublicPath:result];
    return [self publicPath];
}

+ (NSDictionary *)stringsForTable:(NSString *)tableName
                       fromBundle:(NSBundle *)bundle
                  forLocalization:(NSString *)localization
{
    NSString *error;
    NSString *tablePath = [bundle pathForResource:tableName
                                           ofType:@"strings"
                                      inDirectory:@""
                                  forLocalization:localization];
    if (!tablePath)
    {
        NSLog(@"%@ doesn't have %@.strings.", localization, tableName);
        return nil;
    }

    NSData* data = [NSData dataWithContentsOfFile:tablePath];
    if (!data)
    {
        NSLog(@"Couldn't load %@.lproj/%@.strings.", localization, tableName);
        return nil;
    }

    NSDictionary* table = [NSPropertyListSerialization propertyListFromData:data
                                                           mutabilityOption:NSPropertyListImmutable
                                                                     format:NULL
                                                           errorDescription:&error];
    if (!table)
    {
        NSLog(@"Couldn't parse %@.lproj/%@.strings: %@", localization, tableName, error);
        return nil;
    }

    return table;
}

- (NSString *)localizedString:(NSString *)string
                   fromBundle:(NSBundle *)bundle
                        table:(NSString *)tableName
{
    /* Dictionary so we can do lookup for preferred locale -> localizations of the bundle. */
    NSMutableDictionary* bundleLanguages = [NSMutableDictionary dictionary];
    for (NSString* locale in [bundle localizations])
    {
        [bundleLanguages setObject:locale
                            forKey:[NSLocale canonicalLocaleIdentifierFromString:locale]];
    }

    /* Go through each preferred language in order of preference. */
    NSArray* languages = [NSLocale preferredLanguages];
    for (NSString* language in languages)
    {
        DLog(@"Trying language (before canonicalization): %@", language);
        language = [NSLocale canonicalLocaleIdentifierFromString:language];
        DLog(@"Trying language (after canonicalization):  %@", language);

        /* If we can't look it up, it means its not in the bundle. Try next preferred. */
        NSString* lproj = [bundleLanguages objectForKey:language];
        if (!lproj)
        {
            DLog(@"No lproj for %@, trying next preferred language (this isn't necessarily bad).", language);
            continue;
        }

        /* Table of localized strings */
        NSDictionary *table = [InformationGatherer stringsForTable:tableName
                                                        fromBundle:bundle
                                                   forLocalization:lproj];
        if (!table)
        {
            NSLog(@"Lookup failed, trying next language (this isn't necessarily bad).");
            continue;
        }

        /* If we find it - great! Return it. Otherwise, try next. */
        NSString* localizedString = [table objectForKey:string];
        if (localizedString)
        {
            return localizedString;
        }

        NSLog(@"No value for '%@' in %@, trying next preferred language (this isn't necessarily bad).", string, lproj);
    }

    NSLog(@"Could not look up a localization for %@ in table %@!", string, tableName);
    return string;
}

- (NSString *)localizedScreenshotPattern
{
    if (localizedScreenshotPattern)
        return localizedScreenshotPattern;

    NSString *name, *format, *formatTable;
    NSString* screenshotPattern = nil;

    /* These are the keys we look up for localization. */
    if ([self isSnowLeopardOrNewer])
    {
        formatTable = @"Localizable";
        name = @"Screen shot";
        format = @"%@ %@ at %@";
    }
    else
    {
        formatTable = @"ScreenCapture";
        name = @"Picture";
        format = @"%@ %@";
    }

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
        NSLog(@"ERROR: Could not load bundle for /System/Library/CoreServices/SystemUIServer.app");
    }

    screenshotPattern = [[NSString stringWithFormat:format, name, @"*", @"*"] stringByAppendingString:@".*"];
    DLog(@"Pattern is %@", screenshotPattern);

    [self setLocalizedScreenshotPattern:screenshotPattern];
    return [self localizedScreenshotPattern];
}

- (NSSet *)createdFiles
{
    NSSet *newContents = [self files];
    if (!newContents)
        return nil;

#if (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5)
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

- (NSSet *)files
{
    NSError* error;
    NSFileManager* fm = [NSFileManager defaultManager];
    NSArray* dirList = [fm contentsOfDirectoryAtPath:[self screenshotPath]
                                               error:&error];
    if (!dirList)
    {
        NSLog(@"Failed getting dirlist: %@", [error localizedDescription]);
        return [NSSet set];
    }

    return [NSSet setWithArray:dirList];
}

@end

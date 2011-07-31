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

#if (MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_5)
# define SQLITE_OPEN_BEST(path, db) sqlite3_open((path), (db))
#else
# define SQLITE_OPEN_BEST(path, db) sqlite3_open_v2((path), (db), SQLITE_OPEN_READONLY, NULL)
#endif

static InformationGatherer* defaultInstance = nil;

@interface InformationGatherer ()
@property (nonatomic, retain) NSString* screenshotPath;
@property (nonatomic, retain) NSString* uploadPath;
@property (nonatomic, retain) NSString* publicPath;
@property (nonatomic, retain) NSString* localizedScreenshotPattern;
@property (nonatomic, assign) SInt32 osVersion;
@property (nonatomic, retain) NSSet* dirContents;

@end

@implementation InformationGatherer

@synthesize screenshotPath;
@synthesize uploadPath;
@synthesize publicPath;
@synthesize localizedScreenshotPattern;
@synthesize osVersion;
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
                if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr)
                    [self setOsVersion:MacVersion];
                else
                    NSLog(@"ERROR: Could not query OS version.");

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

- (NSString *)dropboxPathFromConfig
{
    NSString * const configPath = [@"~/.dropbox/config.db" stringByStandardizingPath];
    NSString * const alternateConfigPath = [@"~/.dropbox/dropbox.db" stringByStandardizingPath];
    NSString * const sqlStatement = @"select value from config where key = 'dropbox_path'";
    NSString * result = nil;
    BOOL oldConfig = NO;

    sqlite3 *db;
    sqlite3_stmt *statement;
    int openResult = SQLITE_OPEN_BEST([configPath UTF8String], &db);
    if (openResult != SQLITE_OK)
    {
        DLog(@"Could not open %@, trying %@ instead.", configPath, alternateConfigPath);
        openResult = SQLITE_OPEN_BEST([alternateConfigPath UTF8String], &db);
        oldConfig = YES;
    }

    if (openResult == SQLITE_OK)
    {
        DLog(@"Found Dropbox DB, checking for config.");
        if (sqlite3_prepare_v2(db, [sqlStatement UTF8String], -1, &statement, 0) == SQLITE_OK)
        {
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                result = [NSString stringWithUTF8String:(char*)sqlite3_column_text(statement, 0)];
                DLog(@"Found dropbox_path row, %@.", result);

                if (oldConfig)
                {
                    /* Convert from Pickle
                     * XXX: THIS IS NOT SAFE! Pickle formats are internal and change without warning!
                     * (Though I don't think it does very often)
                     */
                    NSData* data = [NSData dataWithBase64EncodedString:result];
                    result = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
                    result = [[[result componentsSeparatedByString:@"\n"] objectAtIndex:0] substringFromIndex:1];
                }
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(db);
    }

    return result;
}

- (NSString *)dropboxPathFromHost
{
    NSString * const hostPath = [@"~/.dropbox/host.db" stringByStandardizingPath];

    if ([[NSFileManager defaultManager] fileExistsAtPath:hostPath])
    {
        NSError *error = nil;
        NSString *hostData = [NSString stringWithContentsOfFile:hostPath
                                                       encoding:NSUTF8StringEncoding
                                                          error:&error];
        if (!error)
        {
            NSArray *lines = [hostData componentsSeparatedByString:@"\n"];
            if ([lines count] >= 2)
            {
                NSData* data = [NSData dataWithBase64EncodedString:[lines objectAtIndex:1]];
                NSString *path = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
                DLog(@"Dropbox path from %@: %@", hostPath, path);
                return path;
            }
            else
            {
                NSLog(@"File %@ has too few lines (%@)", hostPath, hostData);
            }
        }
        else
        {
            NSLog(@"Couldn't read %@: %@", hostPath, error);
        }
    }
    else
    {
        NSLog(@"Couldn't read %@: File does not exist", hostPath);
    }

    return nil;
}

- (NSString *)publicPath
{
    if (publicPath)
        return publicPath;

    NSString * result = [self dropboxPathFromHost];
    if (!result)
        result = [self dropboxPathFromConfig];
    if (!result)
    {
        result = [@"~/Dropbox" stringByStandardizingPath];
        NSLog(@"Could not get Dropbox path, resorting to default: %@", result);
    }

    result = [[result stringByAppendingPathComponent:@"Public"] stringByStandardizingPath];
    DLog(@"publicPath: %@", result);
    [self setPublicPath:result];
    return [self publicPath];
}

+ (NSDictionary *)getStringsTable:(NSString *)table
                       fromBundle:(NSBundle *)bundle
                  forLocalization:(NSString *)localization
{
    NSString *error;
    NSString *tablePath = [bundle pathForResource:table
                                           ofType:@"strings"
                                      inDirectory:@""
                                  forLocalization:localization];
    if (!tablePath)
    {
        NSLog(@"%@ doesn't have %@.strings.", localization, table);
        return nil;
    }

    NSData* data = [NSData dataWithContentsOfFile:tablePath];
    if (!data)
    {
        NSLog(@"Couldn't load %@.lproj/%@.strings.", localization, table);
        return nil;
    }

    NSDictionary* strings = [NSPropertyListSerialization propertyListFromData:data
                                                             mutabilityOption:NSPropertyListImmutable
                                                                       format:NULL
                                                             errorDescription:&error];
    if (!strings)
    {
        NSLog(@"Couldn't parse %@.lproj/%@.strings: %@", localization, table, error);
        return nil;
    }

    return strings;
}

- (NSString *)localizedScreenshotPattern
{
    if (localizedScreenshotPattern)
        return localizedScreenshotPattern;

    NSString* stringKeyName;
    NSString* stringKeyFormat = @"%@ %@ at %@";;
    NSString *formatTable = @"ScreenCapture";
    NSString* screenshotPattern = nil;

    NSDictionary*  dict = [[NSUserDefaults standardUserDefaults]
                           persistentDomainForName:@"com.apple.screencapture"];
    NSString* nameOverride = [dict objectForKey:@"name"];
    DLog(@"nameOverride: %@", nameOverride);

    /* These are the keys we look up for localization. */
    if (osVersion >= 0x1070)
    {
        stringKeyName = @"Screen Shot";
    }
    else if (osVersion >= 0x1060)
    {
        stringKeyName = @"Screen shot";
        formatTable = @"Localizable";
    }
    else
    {
        stringKeyName = @"Picture";
        stringKeyFormat = @"%@ %@";
    }

    /* Look up the SystemUIServer bundle - we'll be reading its localization strings. */
    NSBundle* systemUIServer = [NSBundle bundleWithPath:@"/System/Library/CoreServices/SystemUIServer.app"];
    if (!systemUIServer)
    {
        /* If we can't load the bundle stuff, something is severely wrong. Default to something sane, but log it. */
        NSLog(@"ERROR: Could not load bundle for /System/Library/CoreServices/SystemUIServer.app");
        if (nameOverride)
            stringKeyName = nameOverride;
        screenshotPattern = [NSString stringWithFormat:stringKeyFormat, stringKeyName, @"*", @"*"];
        screenshotPattern = [screenshotPattern stringByAppendingString:@".*"];
        [self setLocalizedScreenshotPattern:screenshotPattern];
        return [self localizedScreenshotPattern];
    }

    /* Dictionary so we can do lookup for preferred locale -> localizations of SystemUIServer. */
    NSMutableDictionary* bundleLanguages = [NSMutableDictionary dictionary];
    for (NSString* locale in [systemUIServer localizations])
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

        /* If we can't look it up, it means its not in SystemUIServer. Try next preferred. */
        NSString* lproj = [bundleLanguages objectForKey:language];
        if (!lproj)
        {
            NSLog(@"No lproj for %@, trying next preferred language (this isn't necessarily bad).", language);
            continue;
        }

        /* Table of localized strings (ScreenCapture) */
        NSDictionary *tableSC = [InformationGatherer getStringsTable:@"ScreenCapture"
                                                          fromBundle:systemUIServer
                                                     forLocalization:lproj];
        if (!tableSC)
        {
            NSLog(@"Lookup failed, trying next language (this isn't necessarily bad).");
            continue;
        }

        /* This is "Picture" or "Screen shot" in your native tongue. */
        NSString* localizedName = [tableSC objectForKey:stringKeyName];
        if (!localizedName && !nameOverride)
        {
            NSLog(@"No value for '%@' in %@, trying next preferred language (this isn't necessarily bad).", stringKeyName, lproj);
            continue;
        }

        /* This is the format string used to combine either a number with the name (10.5)
         * or a date with the name (10.6).
         */
        NSDictionary *tableLoc = [InformationGatherer getStringsTable:formatTable
                                                           fromBundle:systemUIServer
                                                      forLocalization:lproj];
        if (!tableLoc)
        {
            NSLog(@"Lookup failed, trying next language (this isn't necessarily bad).");
            continue;
        }

        NSString* localizedFormat = [tableLoc objectForKey:stringKeyFormat];

        /* If all went well, produce the final pattern to match against. */
        if (localizedFormat)
        {
            if (nameOverride)
                localizedName = nameOverride;
            screenshotPattern = [NSString stringWithFormat:localizedFormat, localizedName, @"*", @"*"];
            break;
        }
        else
        {
            NSLog(@"No value for '%@' in %@, trying next preferred language (this isn't necessarily bad).", stringKeyFormat, lproj);
        }
    }

    /* If we can't find one, default to something sane. */
    if (!screenshotPattern)
    {
        NSLog(@"ERROR: screenshotPattern not found, defaulting.");

        if (nameOverride)
            stringKeyName = nameOverride;
        screenshotPattern = [NSString stringWithFormat:stringKeyFormat, stringKeyName, @"*", @"*"];
    }

    screenshotPattern = [screenshotPattern stringByAppendingString:@".*"];

    DLog(@"Pattern is %@", screenshotPattern);

    [self setLocalizedScreenshotPattern:screenshotPattern];
    return [self localizedScreenshotPattern];
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

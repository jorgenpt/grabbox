//
//  InformationGatherer.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/10/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import "InformationGatherer.h"

#include <sqlite3.h>

static InformationGatherer* defaultInstance = nil;

@interface InformationGatherer ()
@property (nonatomic, retain) NSString* screenshotPath;
@property (nonatomic, retain) NSString* uploadPath;
@property (nonatomic, retain) NSString* publicPath;
@property (nonatomic, retain) NSString* localizedScreenshotPrefix;
@property (nonatomic, assign) BOOL isSnowLeopardOrNewer;
@property (nonatomic, retain) NSSet* dirContents;

@end

@implementation InformationGatherer

@synthesize screenshotPath;
@synthesize uploadPath;
@synthesize publicPath;
@synthesize localizedScreenshotPrefix;
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
                if (!dirContents)
                    return nil;
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
        foundPath = @"~/Desktop";

    [self setScreenshotPath:[foundPath stringByStandardizingPath]];

    return screenshotPath;
}

- (NSString *)uploadPath
{
    if (uploadPath)
        return uploadPath;
    
    NSString* path = [[[self publicPath] stringByAppendingPathComponent:@"Screenshots"] stringByStandardizingPath];
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
        if (sqlite3_prepare_v2(db, [sqlStatement UTF8String], -1, &statement, 0) == SQLITE_OK)
        {
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                result = [NSString stringWithUTF8String:(char*)sqlite3_column_text(statement, 0)];
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(db);
    }

    result = [[result stringByAppendingPathComponent:@"Public"] stringByStandardizingPath];
    [self setPublicPath:result];
    return [self publicPath];
}

- (NSString *)localizedScreenshotPrefix
{
    if (localizedScreenshotPrefix)
        return localizedScreenshotPrefix;

    NSBundle* systemUIServer = [NSBundle bundleWithPath:@"/System/Library/CoreServices/SystemUIServer.app"];
    NSString* stringKey = @"Screen shot";

    if (![self isSnowLeopardOrNewer])
    {
        stringKey = @"Picture";
    }

    NSString* screenshotName;
    NSMutableDictionary* bundleLanguages = [NSMutableDictionary dictionary];
    for (NSString* locale in [systemUIServer localizations])
    {
        [bundleLanguages setObject:locale
                            forKey:[NSLocale canonicalLocaleIdentifierFromString:locale]];
    }

    NSArray* languages = [NSLocale preferredLanguages];
    for (NSString* language in languages)
    {
        language = [NSLocale canonicalLocaleIdentifierFromString:language];
        NSString* lproj = [bundleLanguages objectForKey:language];
        if (!lproj)
        {
            NSLog(@"No lproj for %@, trying next preferred language.", language);
            continue;
        }

        NSString *table = [systemUIServer pathForResource:@"ScreenCapture"
                                                   ofType:@"strings"
                                              inDirectory:@""
                                          forLocalization:lproj];
        if (!table)
        {
            NSLog(@"No ScreenCapture.strings in %@, trying next preferred language.", lproj);
            continue;
        }

        NSData* data = [NSData dataWithContentsOfFile:table];
        NSString* error;
        NSDictionary* strings = [NSPropertyListSerialization propertyListFromData:data
                                                                 mutabilityOption:NSPropertyListImmutable
                                                                           format:NULL
                                                                 errorDescription:&error];
        if (!strings)
        {
            NSLog(@"Couldn't load %@ (%@), trying next preferred language: %@", lproj, table, error);
            continue;
        }

        NSString* localized = [strings objectForKey:stringKey];
        if (localized)
        {
            screenshotName = localized;
            break;
        }
        else
        {
            NSLog(@"No value for '%@' in %@ (%@), trying next preferred language.", stringKey, lproj, table);
        }
    }

    if (!screenshotName)
    {
        NSLog(@"screenshotName is nil-string.");
        screenshotName = @"NO NAME FOUND";
    }
    
    [self setLocalizedScreenshotPrefix:[screenshotName stringByAppendingString:@" "]];
    return [self localizedScreenshotPrefix];
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
        return nil;
    }

    return [NSSet setWithArray:dirList];
}

- (NSString *)getURLForFile:(NSString *)file withId:(int)dropboxId
{
    NSString *escapedFile = [file stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"UseDirectLink"])
    {
        return  [NSString stringWithFormat:@"http://dl.dropbox.com/u/%d/Screenshots/%@", dropboxId, escapedFile];
    }
    else
    {
        return  [NSString stringWithFormat:@"http://o7.no/%d/%@", dropboxId, escapedFile];
    }
}
@end

//
//  DropboxUploader.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright 2010 devSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Uploader.h"

@interface DropboxUploader : Uploader <DBRestClientDelegate> {
    DBRestClient *restClient;
    NSString *destFilename;
}

+ (NSString *) urlForPath:(NSString *)path;

@end

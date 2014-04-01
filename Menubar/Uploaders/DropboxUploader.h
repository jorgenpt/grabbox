//
//  DropboxUploader.h
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/12/10.
//  Copyright (C) 2014 Jørgen P. Tjernø. Licensed under GPLv2, see LICENSE in the project root for more info.
//

#import <Cocoa/Cocoa.h>

#import "Uploader.h"

@interface DropboxUploader : Uploader <DBRestClientDelegate> {
    DBRestClient *restClient;
    NSString *destFilename;
}

+ (NSString *) urlForPath:(NSString *)path;

@end

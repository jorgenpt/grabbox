//
//  ImgurUploader.h
//  GrabBox2
//
//  Created by Jørgen P. Tjernø on 7/3/11.
//  Copyright 2011 devSoft. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Uploader.h"
#import "ASIFormDataRequest.h"

@interface ImgurUploader : Uploader {
    ASIFormDataRequest *request;
}

@end

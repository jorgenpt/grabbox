//
//  main.m
//  GrabBox
//
//  Created by Jørgen P. Tjernø on 7/8/10.
//  Copyright (C) 2014 Jørgen P. Tjernø. Licensed under GPLv2, see LICENSE in the project root for more info.
//

#import <Cocoa/Cocoa.h>
NSString *const NSImageNameCaution = @"NSCaution";

int main(int argc, const char *argv[])
{
    srand48(time(NULL));
    return NSApplicationMain(argc,  argv);
}

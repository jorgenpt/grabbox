/*
 *  ProcessIsRunningWithBundleID.h
 *
 *  Created by Gregory Weston on 7/28/05.
 *  Copyright 2005 Gregory Weston. All rights reserved.
 *
 */

#ifndef PROCESSISRUNNINGWITHBUNDLEID_H
#define PROCESSISRUNNINGWITHBUNDLEID_H

#include <IOKit/IOCFBundle.h>

int ProcessIsRunningWithBundleID(CFStringRef inBundleID, 
                                 ProcessSerialNumber* outPSN);

#endif
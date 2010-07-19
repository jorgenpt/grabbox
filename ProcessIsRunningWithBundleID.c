/*
 *  ProcessIsRunningWithBundleID.c
 *
 *  Created by Gregory Weston on 7/28/05.
 *  Copyright 2005 Gregory Weston. All rights reserved.
 *
 */

#include "ProcessIsRunningWithBundleID.h"
#include <Carbon/Carbon.h>

int ProcessIsRunningWithBundleID(CFStringRef inBundleID, 
                                 ProcessSerialNumber* outPSN)
{
    int theResult = 0;
    
    ProcessSerialNumber thePSN = {0, kNoProcess};
    OSErr theError = noErr;
    do {
        theError = GetNextProcess(&thePSN);
        if(theError == noErr)
        {
            CFDictionaryRef theInfo = NULL;
            theInfo = ProcessInformationCopyDictionary(&thePSN,
                                                       kProcessDictionaryIncludeAllInformationMask);
            if(theInfo)
            {
                CFStringRef theBundleID = CFDictionaryGetValue(theInfo,
                                                               kIOBundleIdentifierKey);
                if(theBundleID)
                {
                    if(CFStringCompare(theBundleID, inBundleID, 0) == 
                       kCFCompareEqualTo)
                    {
                        theResult = 1;
                    }
                }
                CFRelease(theInfo);
            }
        }
    } while((theError != procNotFound) && (theResult == 0));
    
    if(theResult && outPSN)
    {
        *outPSN = thePSN;
    }
    
    return theResult;
}
// Copyright (C) 2008-2011 JWmicro. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//  * Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//  * Neither the name of the JWmicro nor the names of its contributors may
//    be used to endorse or promote products derived from this software
//    without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

/// @file egwUIDeviceExt.m
/// @ingroup geWizES_hwd_uideviceext
/// iPhone UI Device Extension Implementation.

#if defined(EGW_BUILDMODE_IPHONE)

#import <sys/types.h>
#import <sys/sysctl.h>
#import "egwUIDeviceExt.h"


EGWuint egwDeviceIdentifier() {
    EGWuint retVal = EGW_APPL_DEVICE_UNKNOWN;
    
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char* device = (char*)malloc(size);
    sysctlbyname("hw.machine", device, &size, NULL, 0);
    
    if(strstr(device, "iPod")) {
        if(strcmp(device, "iPod1,1") == 0)
            retVal = EGW_APPL_DEVICE_IPOD_1G;
        else if(strcmp(device,"iPod2,1") == 0)
            retVal = EGW_APPL_DEVICE_IPOD_2G;
        else if(strcmp(device,"iPod3,1") == 0)
            retVal = EGW_APPL_DEVICE_IPOD_3G;
        else if(strcmp(device,"iPod4,1") == 0)
            retVal = EGW_APPL_DEVICE_IPOD_4G;
        else
            retVal = EGW_APPL_DEVICE_IPOD_UNK;
    } else if(strstr(device, "iPhone")) {
        if(strcmp(device, "iPhone1,1") == 0)
            retVal = EGW_APPL_DEVICE_IPHONE_2G;
        else if(strcmp(device,"iPhone1,2") == 0)
            retVal = EGW_APPL_DEVICE_IPHONE_3G;
        else if(strcmp(device,"iPhone2,1") == 0)
            retVal = EGW_APPL_DEVICE_IPHONE_3GS;
        else if(strcmp(device,"iPhone3,1") == 0)
            retVal = EGW_APPL_DEVICE_IPHONE_4G;
        else
            retVal = EGW_APPL_DEVICE_IPHONE_UNK;
    } else if(strstr(device, "iPad")) {
        if(strcmp(device, "iPad1,1") == 0)
            retVal = EGW_APPL_DEVICE_IPAD_1G;
        else if(strcmp(device,"iPad2,1") == 0)
            retVal = EGW_APPL_DEVICE_IPAD_2G;
        else
            retVal = EGW_APPL_DEVICE_IPAD_UNK;
    } else {
        if(strcmp(device, "i386") == 0)
            retVal = EGW_APPL_DEVICE_SIMULATOR;
        else
            retVal = EGW_APPL_DEVICE_UNKNOWN;
    }
    
    free(device);
    
    return retVal;
}

NSString* egwDeviceIdentifierString() {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char* device = (char*)malloc(size);
    sysctlbyname("hw.machine", device, &size, NULL, 0);
    
    NSString* deviceStr = [NSString stringWithUTF8String:device];
    free(device);
    
    return deviceStr;
}

#endif

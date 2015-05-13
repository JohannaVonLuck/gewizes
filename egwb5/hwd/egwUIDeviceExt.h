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

/// @defgroup geWizES_hwd_uideviceext egwUIDeviceExt
/// @ingroup geWizES_hwd
/// iPhone UI Device Extension.
/// @{

/// @file egwUIDeviceExt.h
/// iPhone UI Device Extension Interface.

#if defined(EGW_BUILDMODE_IPHONE)

#import <UIKit/UIKit.h>
#import "egwHwdTypes.h"


#define EGW_APPL_DEVICE_IPOD_1G     0x0101  ///< iPod 1G device.
#define EGW_APPL_DEVICE_IPOD_2G     0x0102  ///< iPod 2G device.
#define EGW_APPL_DEVICE_IPOD_3G     0x0104  ///< iPod 3G device.
#define EGW_APPL_DEVICE_IPOD_4G     0x0108  ///< iPod 4G device.
#define EGW_APPL_DEVICE_IPOD_UNK    0x0180  ///< iPod like unknown device.
#define EGW_APPL_DEVICE_IPHONE_2G   0x0201  ///< iPhone 2G device.
#define EGW_APPL_DEVICE_IPHONE_3G   0x0202  ///< iPhone 3G device.
#define EGW_APPL_DEVICE_IPHONE_3GS  0x0204  ///< iPhone 3GS device.
#define EGW_APPL_DEVICE_IPHONE_4G   0x0208  ///< iPhone 4G device.
#define EGW_APPL_DEVICE_IPHONE_UNK  0x0280  ///< iPhone like unknown device.
#define EGW_APPL_DEVICE_IPAD_1G     0x0401  ///< iPad 1G device.
#define EGW_APPL_DEVICE_IPAD_2G     0x0402  ///< iPad 2G device.
#define EGW_APPL_DEVICE_IPAD_UNK    0x0480  ///< iPad like unknown device.
#define EGW_APPL_DEVICE_SIMULATOR   0x8001  ///< Simulator device.
#define EGW_APPL_DEVICE_UNKNOWN     0x8080  ///< Other unknown device.
#define EGW_APPL_DEVICE_EXIPOD      0x0100  ///< Used to extract iPod type.
#define EGW_APPL_DEVICE_EXIPHONE    0x0200  ///< Used to extract iPhone type.
#define EGW_APPL_DEVICE_EXIPAD      0x0400  ///< Used to extract iPad type.
#define EGW_APPL_DEVICE_EXOTHER     0x8000  ///< Used to extract other type.

/// Device Identifier Accessor.
/// Returns the device identifier (EGW_APPL_DEVICE_*).
/// @return Device identifier.
EGWuint egwDeviceIdentifier();

/// Device Identifier String Accessor.
/// Returns the explicit device string.
/// @return Device identfier string.
NSString* egwDeviceIdentifierString();

#endif

/// @}

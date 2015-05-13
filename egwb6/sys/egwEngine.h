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

/// @defgroup geWizES_sys_engine egwEngine
/// @ingroup geWizES_sys
/// Base Engine.
/// @{

/// @file egwEngine.h
/// Base Engine Interface.

#import "egwSysTypes.h"
#import "../inf/egwPSingleton.h"
#import "../gfx/egwGfxTypes.h"


#define EGW_ENGINE_GFXAPI_SOFTWARE   0x0001 ///< Use software for graphics rendering (NOT SUPPORTED).
#define EGW_ENGINE_GFXAPI_OPENGLES11 0x0002 ///< Use EAGL OpenGLES 1.1 for graphics rendering.
#define EGW_ENGINE_GFXAPI_OPENGL2    0x0003 ///< Use NS OpenGL 2.0 for graphics rendering.
#define EGW_ENGINE_GFXAPI_DIRECTX    0x0004 ///< Use DirectX 9.0 (DirectDraw) for graphics rendering (NOT SUPPORTED).
#define EGW_ENGINE_GFXAPI_INVALID    0x000F ///< Invalid graphics rendering API.
#define EGW_ENGINE_PHYAPI_SOFTWARE   0x0010 ///< Use software for physical actuating.
#define EGW_ENGINE_PHYAPI_AEGIAPHYSX 0x0020 ///< Use Ageia PhysX for physical actuating (NOT SUPPORTED).
#define EGW_ENGINE_PHYAPI_INVALID    0x00F0 ///< Invalid physical actuating API.
#define EGW_ENGINE_SNDAPI_SOFTWARE   0x0100 ///< Use software for sound mixing (NOT SUPPORTED).
#define EGW_ENGINE_SNDAPI_OPENAL     0x0200 ///< Use OpenAL for sound mixing.
#define EGW_ENGINE_SNDAPI_DIRECTX    0x0300 ///< Use DirectX 9.0 (DirectSound) for sound mixing (NOT SUPPORTED).
#define EGW_ENGINE_SNDAPI_INVALID    0x0F00 ///< Invalid sound mixing API.
#define EGW_ENGINE_EXGFXAPI          0x000F ///< Used to extract graphics API usage from bitfield.
#define EGW_ENGINE_EXPHYAPI          0x00F0 ///< Used to extract physics API usage from bitfield.
#define EGW_ENGINE_EXSNDAPI          0x0F00 ///< Used to extract sound API usage from bitfield.
/// Simplicity define for iPhone/UIKit hardware.
#define EGW_ENGINE_APIS_IPHONE       (EGW_ENGINE_GFXAPI_OPENGLES11 | EGW_ENGINE_PHYAPI_SOFTWARE | EGW_ENGINE_SNDAPI_OPENAL)
/// Simplicity defined for Mac OSX/Cocoa hardware.
#define EGW_ENGINE_APIS_MACOSX       (EGW_ENGINE_GFXAPI_OPENGL2 | EGW_ENGINE_PHYAPI_SOFTWARE | EGW_ENGINE_SNDAPI_OPENAL)
/// Simplicity defined for Linux/GNUstep hardware.
#define EGW_ENGINE_APIS_LINUX        (EGW_ENGINE_GFXAPI_OPENGL2 | EGW_ENGINE_PHYAPI_SOFTWARE | EGW_ENGINE_SNDAPI_OPENAL)
/// Simplicity defined for Mingw/GNUstep hardware.
#define EGW_ENGINE_APIS_MINGW        (EGW_ENGINE_GFXAPI_OPENGL2 | EGW_ENGINE_PHYAPI_SOFTWARE | EGW_ENGINE_SNDAPI_OPENAL)


extern NSThread* (*egwSFPNSThreadCurrentThread)(id, SEL);        ///< NSThread's currentThread IMP function pointer (to reduce dynamic lookup).
extern BOOL (*egwSFPNSThreadSetThreadPriority)(id, SEL, double); ///< NSThread's setThreadPriority IMP function pointer (to reduce dynamic lookup).


/// Engine Interface.
/// Basic engine interface that controls and manages all engine component
/// managers and interactors. Must be instantiated prior to any engine calls.
@interface egwEngine : NSObject <egwPSingleton> {
    EGWint _apis;                           ///< API usage settings.
    
    NSMutableArray* _gfxContexts;           ///< Collection of allocated graphics contexts.
    NSMutableArray* _phyContexts;           ///< Collection of allocated physics contexts.
    NSMutableArray* _sndContexts;           ///< Collection of allocated sound contexts.
    
    egwMaterialStack* _dfltMtrlStack;       ///< Default material stack.
    
    BOOL _isLittleEndian;                   ///< Endianness tracking.
}

/// Designated Initializer.
/// Initializes the base engine with provided settings.
/// @param [in] apis Bit-wise API identifier.
/// @return Self upon success, otherwise nil.
- (id)initWithAPIs:(EGWint)apis;


/// Graphics Context Creation Method.
/// Creates a new graphics context from engine initialization settings.
/// @note This is the preferred method for creating contexts, as context is automatically released upon exit.
/// @param [in] params Graphics initialization parameters structure.
/// @return New context creation.
- (id<egwPGfxContext>)createGfxContext:(void*)params;

/// Physics Context Creation Method.
/// Creates a new physics context from engine initialization settings.
/// @note This is the preferred method for creating contexts, as context is automatically released upon exit.
/// @param [in] params Physics initialization parameters structure.
/// @return New context creation.
- (id<egwPPhyContext>)createPhyContext:(void*)params;

/// Sound Context Creation Method.
/// Creates a new sound context from engine initialization settings.
/// @note This is the preferred method for creating contexts, as context is automatically released upon exit.
/// @param [in] params Sound initialization parameters structure.
/// @return New context creation.
- (id<egwPSndContext>)createSndContext:(void*)params;


/// Default Material Stack Accessor.
/// Returns a massively shared default material stack object.
/// @return Default material stack.
- (egwMaterialStack*)defaultMaterialStack;

/// Version Accessor.
/// Returns the uniquely identifiable version string for this implementation.
/// @return Version string.
- (NSString*)version;


/// IsLittleEndian Poller.
/// Polls the system to determine status.
/// @return YES if the system is little-endian based, otherwise NO.
- (BOOL)isLittleEndian;

/// IsBigEndian Poller.
/// Polls the system to determine status.
/// @return YES if the system is big-endian based, otherwise NO.
- (BOOL)isBigEndian;

@end


/// Global current singleton egwEngine instance (weak).
extern egwEngine* egwSIEngine;

/// @}

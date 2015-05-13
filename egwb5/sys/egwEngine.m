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

/// @file egwEngine.m
/// @ingroup geWizES_sys_engine
/// Base Engine Implementation.

#import "egwEngine.h"
#import "../sys/egwAssetManager.h"
#import "../sys/egwScreenManager.h"
#import "../sys/egwTaskManager.h"
#import "../sys/egwGfxContext.h"
#import "../sys/egwGfxContextNSGL.h"
#import "../sys/egwGfxContextEAGLES.h"
#import "../sys/egwPhyContext.h"
#import "../sys/egwPhyContextSW.h"
#import "../sys/egwSndContext.h"
#import "../sys/egwSndContextAL.h"
#import "../sys/egwGfxRenderer.h"
#import "../sys/egwPhyActuator.h"
#import "../sys/egwSndMixer.h"
#import "../gfx/egwGraphics.h"
#import "../gfx/egwBindingStacks.h"
#import "../gfx/egwCameras.h"
#import "../gfx/egwMaterials.h"
#import "../misc/egwValidater.h"


egwEngine* egwSIEngine = nil;


// !!!: ***** egwEngine *****

@implementation egwEngine

static egwEngine* _singleton = nil;

+ (id)alloc {
    @synchronized(self) {
        if(!_singleton)
            egwSIEngine = _singleton = [super alloc];
    }
    return _singleton;
}

+ (void)dealloc {
    @synchronized(self) {
        [_singleton release];
        egwSIEngine = _singleton = nil;
    }
    if(0) [super dealloc];
}

+ (id)sharedSingleton {
    return _singleton;
}

- (id)copy {
    return _singleton;
}

- (id)mutableCopy {
    return _singleton;
}

+ (BOOL)isAllocated {
    return (_singleton ? YES : NO);
}

- (id)init {
    #if defined(EGW_BUILDMODE_IPHONE)
        return [self initWithAPIs:EGW_ENGINE_APIS_IPHONE];
    #elif defined(EGW_BUILDMODE_MACOSX)
        return [self initWithAPIs:EGW_ENGINE_APIS_MACOSX];
    #elif defined(EGW_BUILDMODE_LINUX)
        return [self initWithAPIs:EGW_ENGINE_APIS_LINUX];
    #elif defined(EGW_BUILDMODE_MINGW)
        return [self initWithAPIs:EGW_ENGINE_APIS_MINGW];
    #else
        NSLog(@"egwEngine: init: Cannot determine system configuration for initialization. YOU'RE DOING IT WRONG!");
        [egwEngine dealloc]; return nil;
    #endif
}

- (id)initWithAPIs:(EGWint)apis {
    if(![super init]) { [self release]; return (self = nil); }
    
    srand(time(0));
    
    if(EGW_ENGINE_MANAGERS_STARTUPMSGS) NSLog(@"egwEngine: initWithAPIs: Engine is STARTING UP.");
    
    {   EGWuint32 endianTest = 1;
        if(*(EGWuint8*)&endianTest == 1)
            _isLittleEndian = YES;
        else _isLittleEndian = NO;
        
        if(!_isLittleEndian)
            NSLog(@"egwEngine: initWithAPIs: Engine not being ran on a little-endian machine. Issues with functionality may be experienced.");
    }
    
    _apis = apis;
    
    if(!(_gfxContexts = [[NSMutableArray alloc] init])) { [self release]; return (self = nil); }
    if(!(_phyContexts = [[NSMutableArray alloc] init])) { [self release]; return (self = nil); }
    if(!(_sndContexts = [[NSMutableArray alloc] init])) { [self release]; return (self = nil); }
    
    if(!([[egwAssetManager alloc] init])) { NSLog(@"egwEngine: initWithAPIs: Failure creating egwAssetManager."); [self release]; return (self = nil); }
    if(!([[egwScreenManager alloc] init])) { NSLog(@"egwEngine: initWithAPIs: Failure creating egwScreenManager."); [self release]; return (self = nil); }
    if(!([[egwTaskManager alloc] init])) { NSLog(@"egwEngine: initWithAPIs: Failure creating egwTaskManager."); [self release]; return (self = nil); }
    
    // Set up light stack shared FPs
    {   egwLightStack* stack = [egwLightStack alloc];
        egwSFPLghtStckPushAndBindLights = (void(*)(id,SEL))[stack methodForSelector:@selector(pushAndBindLights)];
        egwSFPLghtStckPopLights = (void(*)(id,SEL))[stack methodForSelector:@selector(popLights)];
        [stack release]; stack = nil;
    }
    
    // Set up material stack shared FPs
    {   _dfltMtrlStack = [[egwMaterialStack alloc] initWithMaterials:[[egwMaterial alloc] initWithIdentity:@"defaultMaterial" surfacingMaterial:&egwSIMtrlDefault4f],0];
        egwSFPMtrlStckPushAndBindMaterials = (void(*)(id,SEL))[_dfltMtrlStack methodForSelector:@selector(pushAndBindMaterials)];
        egwSFPMtrlStckPopMaterials = (void(*)(id,SEL))[_dfltMtrlStack methodForSelector:@selector(popMaterials)];
    }
    
    // Set up texture stack shared FPs
    {   egwTextureStack* stack = [egwTextureStack alloc];
        egwSFPTxtrStckPushAndBindTextures = (void(*)(id,SEL))[stack methodForSelector:@selector(pushAndBindTextures)];
        egwSFPTxtrStckPopTextures = (void(*)(id,SEL))[stack methodForSelector:@selector(popTextures)];
        [stack release]; stack = nil;
    }
    
    // Set up validater shared FPs
    {   egwValidater* validater = [egwValidater alloc];
        egwSFPVldtrValidate = (void(*)(id,SEL))[validater methodForSelector:@selector(validate)];
        egwSFPVldtrInvalidate = (void(*)(id,SEL))[validater methodForSelector:@selector(invalidate)];
        egwSFPVldtrIsValidated = (BOOL(*)(id,SEL))[validater methodForSelector:@selector(isValidated)];
        egwSFPVldtrIsInvalidated = (BOOL(*)(id,SEL))[validater methodForSelector:@selector(isInvalidated)];
        [validater release]; validater = nil;
    }
    
    if(EGW_ENGINE_MANAGERS_STARTUPMSGS) NSLog(@"egwEngine: initWithAPIs: Engine is UP & RUNNING.");
    
    return self;
}

- (void)dealloc {
    if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwEngine: dealloc: Engine is SHUTTING DOWN.");
    
    // NOTE: Screens are moved into unload and have TIMETOWAIT time to deallocate/release before forced release. -jw
    [egwSIScrnMngr shutDownScreenManagement];
    
    [egwSIAsstMngr unloadAllAssets];
    [_dfltMtrlStack release]; _dfltMtrlStack = nil;
    
    // NOTE: Other tasks that are attached to contexts also receive a shutDownTask message from these calls. -jw
    [_gfxContexts makeObjectsPerformSelector:@selector(shutDownContext)];
    [_phyContexts makeObjectsPerformSelector:@selector(shutDownContext)];
    [_sndContexts makeObjectsPerformSelector:@selector(shutDownContext)];
    
    // NOTE: Task manager is not responsible for shutting down tasks. -jw
    [egwSIAsstMngr shutDownStreamDecoders];
    [egwSITaskMngr shutDownTaskThreads];
    
    [egwScreenManager dealloc];
    [egwAssetManager dealloc];
    [egwTaskManager dealloc];
    
    [_gfxContexts release]; _gfxContexts = nil;
    [_phyContexts release]; _phyContexts = nil;
    [_sndContexts release]; _sndContexts = nil;
    
    if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwEngine: dealloc: Engine has been SHUT DOWN.");
    
    [super dealloc];
}

- (id<egwPGfxContext>)createGfxContext:(void*)params {
    id<egwPGfxContext> context = nil;
    
    switch(_apis & EGW_ENGINE_EXGFXAPI) {
        case EGW_ENGINE_GFXAPI_OPENGLES11: {
            context = [[egwGfxContextEAGLES alloc] initWithParams:params];
        } break;
    }
    
    if(!context) {
        NSLog(@"egwEngine: createGfxContext: Failure creating graphics context.");
    } else {
        [_gfxContexts addObject:context];
        [context release];
    }
    
    return context;
}

- (id<egwPPhyContext>)createPhyContext:(void*)params {
    id<egwPPhyContext> context = nil;
    
    switch(_apis & EGW_ENGINE_EXPHYAPI) {
        case EGW_ENGINE_PHYAPI_SOFTWARE: {
            context = [[egwPhyContextSW alloc] initWithParams:params];
        } break;
    }
    
    if(!context) {
        NSLog(@"egwEngine: createPhyContext: Failure creating physics context.");
    } else {
        [_phyContexts addObject:context];
        [context release];
    }
    
    return context;
}

- (id<egwPSndContext>)createSndContext:(void*)params {
    id<egwPSndContext> context = nil;
    
    switch(_apis & EGW_ENGINE_EXSNDAPI) {
        case EGW_ENGINE_SNDAPI_OPENAL: {
            context = [[egwSndContextAL alloc] initWithParams:params];
        } break;
    }
    
    if(!context) {
        NSLog(@"egwEngine: createSndContext: Failure creating sound context.");
    } else {
        [_sndContexts addObject:context];
        [context release];
    }
    
    return context;
}

- (egwMaterialStack*)defaultMaterialStack {
    return _dfltMtrlStack;
}

- (NSString*)version {
    return @"geWizES_v0.88_B5";
}

- (BOOL)isLittleEndian {
    return _isLittleEndian;
}

- (BOOL)isBigEndian {
    return !_isLittleEndian;
}

@end

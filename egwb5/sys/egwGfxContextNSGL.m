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

/// @file egwGfxContextNSGL.m
/// @ingroup geWizES_sys_gfxcontextnsgl
/// NS OpenGL Graphics Context Implementation.

#import <pthread.h>
#import "egwGfxContextNSGL.h"
#import "../sys/egwEngine.h"
#import "../sys/egwGfxContextEAGLES.h"
#import "../sys/egwGfxRenderer.h"
#import "../math/egwMath.h"
#import "../gfx/egwGraphics.h"
#import "../gfx/egwLights.h"
#import "../gfx/egwTexture.h"
#import "../geo/egwGeometry.h"
#import "../misc/egwValidater.h"


egwGfxContextNSGL* egwAIGfxCntxNSGL = nil;


#if defined(EGW_BUILDMODE_COCOA) || defined(EGW_BUILDMODE_GNUSTEP)

@implementation egwGfxContextNSGL

static EGWint _apiRefCnt_NSGL = 0;
static pthread_mutex_t _apiLock_NSGL = PTHREAD_MUTEX_INITIALIZER;

- (id)init {
    return [self initWithParams:nil];
}

- (id)initWithParams:(void*)params {
    NSString* errorString = nil;
    egwGfxCntxParams* gfxParams = (egwGfxCntxParams*)params;
    egwGfxContext* oldContext = nil;
    //NSMutableArray* availExtensions = nil;
    //const unsigned char* exts = NULL;
    //GLenum bindingStatus = GL_FALSE;
    
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    // Handle params and set up any particulars
    if(!gfxParams) {
        NSLog(@"egwGfxContextNSGL: initWithParams: Failure creating graphics context: Parameter's structure is NULL.");
        [self release]; return (self = nil);
    } else if(gfxParams->fbWidth <= 0 || gfxParams->fbHeight <= 0) {
        NSLog(@"egwGfxContextNSGL: initWithParams: Failure creating graphics context: Width and height not specified.");
        [self release]; return (self = nil);
    } else if(!gfxParams->contextData) {
        NSLog(@"egwGfxContextNSGL: initWithParams: Failure creating graphics context: Context data (associated NSOpenGLContext) not specified.");
        [self release]; return (self = nil);
    }
    _delegate = (gfxParams->delegate ? [gfxParams->delegate retain] : nil);
    _width = gfxParams->fbWidth;
    _height = gfxParams->fbHeight;
    
    // Lock API
    pthread_mutex_lock(&_apiLock_NSGL);
    
    // Create context
    /*if(!(_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1])) {
        egwIsGLError(&errorString);
        NSLog(@"egwGfxContextNSGL: initWithParams: Failure creating context. GLError: %@", (errorString ? errorString : @"GL_NO_ERROR."));
        ++_apiRefCnt_NSGL; goto ErrorCleanup;    // cleanup will refcnt-1, invalidate that
    }
    
    // Increase reference count now that context was created - if error occurs
    // later then this gets decremented correctly and lock dealloc'ed if 0.
    ++_apiRefCnt_NSGL;
    
    // Bind context (store old one for later)
    oldContext = egwAIGfxCntx;
    if(!([EAGLContext setCurrentContext:_context])) {
        egwIsGLError(&errorString);
        NSLog(@"egwGfxContextNSGL: initWithParams: Failure making created context current. GLError: %@", (errorString ? errorString : @"GL_NO_ERROR."));
        goto ErrorCleanup;
    } else {
        _thread = [NSThread currentThread];
        egwAIGfxCntx = self;
        egwAIGfxCntxAGL = self;
        egwAIGfxCntxNSGL = self;
        egwAIGfxCntxEAGLES = nil;
    }
    
    // Determine extensions
    if(!(availExtensions = [[NSMutableArray alloc] init])) {
        NSLog(@"egwGfxContextNSGL: initWithParams: Failure allocating available extensions array.");
        goto ErrorCleanup;
    }
     
     etc etc
     
     */
    
    // If there is a delegate defined, call its willFinish method
    if(_delegate && ![_delegate willFinishInitializingGfxContext:self]) {
        NSLog(@"egwGfxContextNSGL: initWithParams: Failure in user initialization code.");
        goto ErrorCleanup;
    }
	
    // If there was an old context, revert back to it, otherwise keep this one enabled.
    pthread_mutex_unlock(&_apiLock_NSGL);
    if(oldContext) [oldContext makeActive];
    
    [_delegate didFinishInitializingGfxContext:self];
    
    if(EGW_ENGINE_MANAGERS_STARTUPMSGS) NSLog(@"egwGfxContextNSGL: initWithParams: Graphics context has been initialized.");
    
    return self;
    
ErrorCleanup:
    --_apiRefCnt_NSGL;
    _thread = nil;
    pthread_mutex_unlock(&_apiLock_NSGL);
    [oldContext makeActive];
    [self release]; return (self = nil);
}

- (void)dealloc {
    // Forced shutdown - delegates should not be able to cancel
    {   id<egwDGfxContextEvent> delegate = _delegate;
        _delegate = nil;
        [self shutDownContext];
        _delegate = delegate;
        [_delegate didShutDownGfxContext:self];
    }
    
    if(_apiRefCnt_NSGL == 0) {
        @synchronized(self) {
            if(_apiRefCnt_NSGL == 0) {
                pthread_mutex_destroy(&_apiLock_NSGL);
            }
        }
    }
    
    [super dealloc];
}

- (BOOL)makeActive {
    pthread_mutex_lock(&_apiLock_NSGL);
    
    if(!_inPass) {
        if(_context) {
            //[EAGLContext setCurrentContext:_context]; // NOTICE: If this gets called too often, sound will start crackling/popping. -jw
            egwAIGfxCntx = self;
            egwAIGfxCntxAGL = self;
            egwAIGfxCntxNSGL = self;
            egwAIGfxCntxEAGLES = nil;
            _thread = [NSThread currentThread];
            
            egwAFPGfxCntxPushLight = (void(*)(id, SEL, id<egwPLight>))[self methodForSelector:@selector(pushLight:)];
            egwAFPGfxCntxPopLights = (void(*)(id, SEL, EGWuint))[self methodForSelector:@selector(popLights:)];
            egwAFPGfxCntxBindLights = (void(*)(id, SEL))[self methodForSelector:@selector(bindLights)];
            egwAFPGfxCntxUnbindLights = (void(*)(id, SEL))[self methodForSelector:@selector(unbindLights)];
            egwAFPGfxCntxPushMaterial = (void(*)(id, SEL, id<egwPMaterial))[self methodForSelector:@selector(pushMaterial:)];
            egwAFPGfxCntxPopMaterials = (void(*)(id, SEL, EGWuint))[self methodForSelector:@selector(popMaterials:)];
            egwAFPGfxCntxBindMaterials = (void(*)(id, SEL))[self methodForSelector:@selector(bindMaterials)];
            egwAFPGfxCntxUnbindMaterials = (void(*)(id, SEL))[self methodForSelector:@selector(unbindMaterials)];
            egwAFPGfxCntxPushTexture = (void(*)(id, SEL, id<egwPTexture>))[self methodForSelector:@selector(pushTexture:)];
            egwAFPGfxCntxPopTextures = (void(*)(id, SEL, EGWuint))[self methodForSelector:@selector(popTextures:)];
            egwAFPGfxCntxBindTextures = (void(*)(id, SEL))[self methodForSelector:@selector(bindTextures)];
            egwAFPGfxCntxUnbindTextures = (void(*)(id, SEL))[self methodForSelector:@selector(unbindTextures)];
            
            pthread_mutex_unlock(&_apiLock_NSGL);
            return YES;
        } else {
            NSLog(@"egwGfxContextNSGL: makeActive: Failure making active. Context is not valid.");
        }
    } else {
        NSLog(@"egwGfxContextNSGL: makeActive: Failure making active. Already in rendering pass.");
    }
    
    pthread_mutex_unlock(&_apiLock_NSGL);
    return NO;
}

- (BOOL)makeActiveAndLocked {
    if(!_inPass) {
        if(_context) {
            pthread_mutex_lock(&_apiLock_NSGL);
            
            if(!_inPass) {
                if(_context) {
                    //[EAGLContext setCurrentContext:_context]; // NOTICE: If this gets called too often, sound will start crackling/popping. -jw
                    egwAIGfxCntx = self;
                    egwAIGfxCntxAGL = self;
                    egwAIGfxCntxNSGL = self;
                    egwAIGfxCntxEAGLES = nil;
                    _thread = [NSThread currentThread];
                    
                    egwAFPGfxCntxPushLight = (void(*)(id, SEL, id<egwPLight>))[self methodForSelector:@selector(pushLight:)];
                    egwAFPGfxCntxPopLights = (void(*)(id, SEL, EGWuint))[self methodForSelector:@selector(popLights:)];
                    egwAFPGfxCntxBindLights = (void(*)(id, SEL))[self methodForSelector:@selector(bindLights)];
                    egwAFPGfxCntxUnbindLights = (void(*)(id, SEL))[self methodForSelector:@selector(unbindLights)];
                    egwAFPGfxCntxPushMaterial = (void(*)(id, SEL, id<egwPMaterial))[self methodForSelector:@selector(pushMaterial:)];
                    egwAFPGfxCntxPopMaterials = (void(*)(id, SEL, EGWuint))[self methodForSelector:@selector(popMaterials:)];
                    egwAFPGfxCntxBindMaterials = (void(*)(id, SEL))[self methodForSelector:@selector(bindMaterials)];
                    egwAFPGfxCntxUnbindMaterials = (void(*)(id, SEL))[self methodForSelector:@selector(unbindMaterials)];
                    egwAFPGfxCntxPushTexture = (void(*)(id, SEL, id<egwPTexture>))[self methodForSelector:@selector(pushTexture:)];
                    egwAFPGfxCntxPopTextures = (void(*)(id, SEL, EGWuint))[self methodForSelector:@selector(popTextures:)];
                    egwAFPGfxCntxBindTextures = (void(*)(id, SEL))[self methodForSelector:@selector(bindTextures)];
                    egwAFPGfxCntxUnbindTextures = (void(*)(id, SEL))[self methodForSelector:@selector(unbindTextures)];
                    
                    return YES;
                } else {
                    NSLog(@"egwGfxContextNSGL: makeActiveAndLocked: Failure making active. Context is not valid.");
                    pthread_mutex_unlock(&_apiLock_NSGL);
                }
            } else {
                NSLog(@"egwGfxContextNSGL: makeActiveAndLocked: Failure making active. Already in rendering pass.");
                pthread_mutex_unlock(&_apiLock_NSGL);
            }
        } else {
            NSLog(@"egwGfxContextNSGL: makeActiveAndLocked: Failure making active. Context is not valid.");
        }
    } else {
        NSLog(@"egwGfxContextNSGL: makeActiveAndLocked: Failure making active. Already in rendering pass.");
    }
    
    return NO;
}

- (BOOL)resizeBufferWidth:(EGWuint16)width bufferHeight:(EGWuint16)height {
    if(width != _width || height != _height) {
        NSLog(@"egwGfxContextNSGL: resizeBufferWidth:bufferHeight: Error: This method is not yet implemented.");
        return NO;
    }
    
    return YES;
}

- (void)shutDownContext {
    if(!_doShutdown) {
        @synchronized(self) {
            if(!_doShutdown) {
                // Allow delegate to cancel shutDownContext, else proceed
                if(_delegate && ![_delegate willShutDownSndContext:self]) return;
                _doShutdown = YES;
                
                if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwGfxContextNSGL: shutDownContext: Shutting down graphics context.");
                
                // Wait for renderer status to deactivate
                if(_inPass) {
                    NSDate* waitTill = [[NSDate alloc] initWithTimeIntervalSinceNow:(NSTimeInterval)EGW_ENGINE_MANAGERS_TIMETOWAIT];
                    while(_inPass) {
                        if([waitTill timeIntervalSinceNow] < (NSTimeInterval)0.0) {
                            NSLog(@"egwGfxContextNSGL: shutDownContext: Failure waiting for renderer running status to deactivate.");
                            break;
                        }
                        
                        [NSThread sleepForTimeInterval:EGW_ENGINE_MANAGERS_TIMETOSLEEP];
                    }
                    [waitTill release];
                }
                
                if(_context && ![self isActive]) [self makeActive];
                pthread_mutex_lock(&_apiLock_NSGL);
                
                [super shutDownContext];
                
                // Destroy context
                if(_context) {
                    --_apiRefCnt_NSGL;
                    if(egwAIGfxCntx == self) {
                        //[EAGLContext setCurrentContext:nil];
                        egwAIGfxCntx = nil;
                        egwAIGfxCntxAGL = nil;
                        egwAIGfxCntxNSGL = nil;
                        egwAIGfxCntxEAGLES = nil;
                        _inPass = NO;
                        
                        egwAFPGfxCntxPushLight = (void(*)(id, SEL, id<egwPLight>))NULL;
                        egwAFPGfxCntxPopLights = (void(*)(id, SEL, EGWuint))NULL;
                        egwAFPGfxCntxBindLights = (void(*)(id, SEL))NULL;
                        egwAFPGfxCntxUnbindLights = (void(*)(id, SEL))NULL;
                        egwAFPGfxCntxPushMaterial = (void(*)(id, SEL, id<egwPMaterial))NULL;
                        egwAFPGfxCntxPopMaterials = (void(*)(id, SEL, EGWuint))NULL;
                        egwAFPGfxCntxBindMaterials = (void(*)(id, SEL))NULL;
                        egwAFPGfxCntxUnbindMaterials = (void(*)(id, SEL))NULL;
                        egwAFPGfxCntxPushTexture = (void(*)(id, SEL, id<egwPTexture>))NULL;
                        egwAFPGfxCntxPopTextures = (void(*)(id, SEL, EGWuint))NULL;
                        egwAFPGfxCntxBindTextures = (void(*)(id, SEL))NULL;
                        egwAFPGfxCntxUnbindTextures = (void(*)(id, SEL))NULL;
                    }
                    _thread = nil;
                    [_context release]; _context = nil;
                }
                
                pthread_mutex_unlock(&_apiLock_NSGL);
                [_delegate didShutDownGfxContext:self];
                
                if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwGfxContextNSGL: shutDownContext: Graphics context shut down.");
            }
        }
    }
}

+ (EGWint)apiIdent {
    return EGW_ENGINE_GFXAPI_OPENGL2;
}

+ (pthread_mutex_t*)apiMutex {
    return &_apiLock_NSGL;
}

@end


#else

@implementation egwGfxContextNSGL

- (id)init {
    NSLog(@"egwGfxContextNSGL: init: Cannot initialize object due to build mode settings. YOU'RE DOING IT WRONG!");
    
    [self release]; return (self = nil);
}

- (id)initWithParams:(void*)params {
    NSLog(@"egwGfxContextNSGL: initWithParams: Cannot initialize object due to build mode settings. YOU'RE DOING IT WRONG!");
    
    [self release]; return (self = nil);
}

@end

#endif

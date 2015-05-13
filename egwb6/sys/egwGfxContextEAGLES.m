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

/// @file egwGfxContextEAGLES.m
/// @ingroup geWizES_sys_gfxcontexteagles
/// iPhone OpenGLES Graphics Context Implementation.

#import <pthread.h>
#import "egwGfxContextEAGLES.h"
#import "../sys/egwEngine.h"
#import "../sys/egwGfxContextNSGL.h"
#import "../sys/egwGfxRenderer.h"
#import "../math/egwMath.h"
#import "../gfx/egwGraphics.h"
#import "../gfx/egwLights.h"
#import "../gfx/egwTexture.h"
#import "../geo/egwGeometry.h"
#import "../misc/egwValidater.h"


egwGfxContextEAGLES* egwAIGfxCntxEAGLES = nil;


#if defined(EGW_BUILDMODE_IPHONE)

@implementation egwGfxContextEAGLES

static EGWint _apiRefCnt_EAGLES = 0;
static pthread_mutex_t _apiLock_EAGLES = PTHREAD_MUTEX_INITIALIZER;

- (id)init {
    return [self initWithParams:nil];
}

- (id)initWithParams:(void*)params {
    NSString* errorString = nil;
    egwGfxCntxParams* gfxParams = (egwGfxCntxParams*)params;
    egwGfxContext* oldContext = nil;
    NSMutableArray* availExtensions = nil;
    const unsigned char* exts = NULL;
    GLenum bindingStatus = GL_FALSE;
    GLint glIntTemp;
    
    _colorBuffer = _depthBuffer = _stencilBuffer = _frameBuffer = (GLuint)NSNotFound;
    
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    // Handle params and set up any particulars
    if(!gfxParams) {
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure creating graphics context: Parameter's structure is NULL.");
        [self release]; return (self = nil);
    } else if(gfxParams->fbWidth <= 0 || gfxParams->fbHeight <= 0) {
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure creating graphics context: Width and height not specified.");
        [self release]; return (self = nil);
    } else if(!gfxParams->contextData) {
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure creating graphics context: Context data (associated EAGLLayer) not specified.");
        [self release]; return (self = nil);
    }
    _delegate = (gfxParams->delegate ? [gfxParams->delegate retain] : nil);
    _width = gfxParams->fbWidth;
    _height = gfxParams->fbHeight;
    
    // Lock API
    pthread_mutex_lock(&_apiLock_EAGLES);
    
    // Create context
    if(!(_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1])) {
        egwIsGLError(&errorString);
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure creating context. GLError: %@", (errorString ? errorString : @"GL_NO_ERROR."));
        ++_apiRefCnt_EAGLES; goto ErrorCleanup;    // cleanup will refcnt-1, invalidate that
    } else {
        _fpPresentRB = (BOOL(*)(id,SEL,NSUInteger))[(NSObject*)_context methodForSelector:@selector(presentRenderbuffer:)];
        _fpSetCurrCntx = (BOOL(*)(id,SEL,EAGLContext*))[EAGLContext methodForSelector:@selector(setCurrentContext:)];
    }
    
    // Increase reference count now that context was created - if error occurs
    // later then this gets decremented correctly and lock dealloc'ed if 0.
    ++_apiRefCnt_EAGLES;
    
    // Bind context (store old one for later)
    oldContext = egwAIGfxCntx;
    if(!([EAGLContext setCurrentContext:_context])) {
        egwIsGLError(&errorString);
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure making created context current. GLError: %@", (errorString ? errorString : @"GL_NO_ERROR."));
        goto ErrorCleanup;
    } else {
        egwAIGfxCntx = self;
        egwAIGfxCntxAGL = self;
        egwAIGfxCntxNSGL = nil;
        egwAIGfxCntxEAGLES = self;
        _thread = egwSFPNSThreadCurrentThread(nil, @selector(currentThread));
        
        egwAFPGfxCntxPushLight = (void(*)(id, SEL, id<egwPLight>, const egwLightJumpTable*))[self methodForSelector:@selector(pushLight:withLightJumpTable:)];
        egwAFPGfxCntxPopLights = (void(*)(id, SEL, EGWuint))[self methodForSelector:@selector(popLights:)];
        egwAFPGfxCntxBindLights = (void(*)(id, SEL))[self methodForSelector:@selector(bindLights)];
        egwAFPGfxCntxUnbindLights = (void(*)(id, SEL))[self methodForSelector:@selector(unbindLights)];
        egwAFPGfxCntxPushMaterial = (void(*)(id, SEL, id<egwPMaterial>, const egwMaterialJumpTable*))[self methodForSelector:@selector(pushMaterial:withMaterialJumpTable:)];
        egwAFPGfxCntxPopMaterials = (void(*)(id, SEL, EGWuint))[self methodForSelector:@selector(popMaterials:)];
        egwAFPGfxCntxBindMaterials = (void(*)(id, SEL))[self methodForSelector:@selector(bindMaterials)];
        egwAFPGfxCntxUnbindMaterials = (void(*)(id, SEL))[self methodForSelector:@selector(unbindMaterials)];
        egwAFPGfxCntxPushShader = (void(*)(id, SEL, id<egwPShader>, const egwShaderJumpTable*))[self methodForSelector:@selector(pushShader:withShaderJumpTable:)];
        egwAFPGfxCntxPopShaders = (void(*)(id, SEL, EGWuint))[self methodForSelector:@selector(popShaders:)];
        egwAFPGfxCntxBindShaders = (void(*)(id, SEL))[self methodForSelector:@selector(bindShaders)];
        egwAFPGfxCntxUnbindShaders = (void(*)(id, SEL))[self methodForSelector:@selector(unbindShaders)];
        egwAFPGfxCntxPushTexture = (void(*)(id, SEL, id<egwPTexture>, const egwTextureJumpTable*))[self methodForSelector:@selector(pushTexture:withTextureJumpTable:)];
        egwAFPGfxCntxPopTextures = (void(*)(id, SEL, EGWuint))[self methodForSelector:@selector(popTextures:)];
        egwAFPGfxCntxBindTextures = (void(*)(id, SEL))[self methodForSelector:@selector(bindTextures)];
        egwAFPGfxCntxUnbindTextures = (void(*)(id, SEL))[self methodForSelector:@selector(unbindTextures)];
        egwAFPGfxCntxIlluminationFrame = (EGWuint16(*)(id, SEL))[self methodForSelector:@selector(illuminationFrame)];
        egwAFPGfxCntxRenderingFrame = (EGWuint16(*)(id, SEL))[self methodForSelector:@selector(renderingFrame)];
        egwAFPGfxCntxAdvanceIlluminationFrame = (void(*)(id, SEL))[self methodForSelector:@selector(advanceIlluminationFrame)];
        egwAFPGfxCntxAdvanceRenderingFrame = (void(*)(id, SEL))[self methodForSelector:@selector(advanceRenderingFrame)];
        egwAFPGfxCntxBeginRender = (BOOL(*)(id, SEL))[self methodForSelector:@selector(beginRender)];
        egwAFPGfxCntxInterruptRender = (BOOL(*)(id, SEL))[self methodForSelector:@selector(interruptRender)];
        egwAFPGfxCntxEndRender = (BOOL(*)(id, SEL))[self methodForSelector:@selector(endRender)];
        egwAFPGfxCntxMakeActive = (BOOL(*)(id, SEL))[self methodForSelector:@selector(makeActive)];
        egwAFPGfxCntxActive = (BOOL(*)(id, SEL))[self methodForSelector:@selector(isActive)];
        egwAFPGfxCntxPerformSubTasks = (void(*)(id, SEL))[self methodForSelector:@selector(performSubTasks)];
        egwAFPGfxCntxActiveCamera = (id<egwPCamera>(*)(id, SEL))[self methodForSelector:@selector(activeCamera)];
        egwAFPGfxCntxActiveCameraViewingFrame = (EGWuint16(*)(id, SEL))[self methodForSelector:@selector(activeCameraViewingFrame)];
        egwAFPGfxCntxSetActiveCamera = (void(*)(id, SEL, id<egwPCamera>))[self methodForSelector:@selector(setActiveCamera:)];
    }
    
    // Determine extensions
    if(!(availExtensions = [[NSMutableArray alloc] init])) {
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure allocating available extensions array.");
        goto ErrorCleanup;
    }
    
    exts = glGetString(GL_EXTENSIONS);
    if(!egwIsGLError(&errorString) && exts) {
        if(*exts != '\0') {
            const unsigned char* scan = exts;
            do {
                if(*(++scan) == ' ' || *scan == '\0') {
                    NSString* extString = [[NSString alloc] initWithCString:(const char*)exts length:(EGWuint)(scan-exts)];
                    [availExtensions addObject:extString];
                    [extString release];
                    exts = (*scan == ' ' ? scan + 1 : scan);
                }
            } while (*exts != '\0');
        }
    } else {
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure querying GL extensions. GLError: %@", (errorString ? errorString : @"GL_NO_ERROR."));
        [availExtensions release]; availExtensions = nil;
        goto ErrorCleanup;
    }
    
    if(!(_extensions = [[NSArray alloc] initWithArray:availExtensions])) {
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure allocating object.");
        [availExtensions release]; availExtensions = nil;
        goto ErrorCleanup;
    } else {
        [availExtensions release]; availExtensions = nil;
    }
    
    // Query for max lights
    _actvLights = 0;
    glGetIntegerv(GL_MAX_LIGHTS, (GLint*)&glIntTemp); _maxLights = (EGWuint16)glIntTemp;
    if(_maxLights > 127) _maxLights = 127;
    if(egwIsGLError(&errorString)) {
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure querying max lights. GLError: %@", errorString);
        goto ErrorCleanup;
    }
    
    // Create light holders
    if(!(_lightStages = (egwLightStageAGL*)malloc(_maxLights * sizeof(egwLightStageAGL)))) {
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure allocating object.");
        goto ErrorCleanup;
    } else {
        for(EGWint lightStage = 0; lightStage < _maxLights; ++lightStage) {
            _lightStages[lightStage].stack.exstStage = -1;
            _lightStages[lightStage].stack.nextStage = -1;
            _lightStages[lightStage].lru.stage = (EGWint8)lightStage;
            _lightStages[lightStage].stage.nextStack = -1;
            _lightStages[lightStage].stage.exstBind = nil;
            _lightStages[lightStage].stage.exstJmpT = NULL;
            _lightStages[lightStage].stage.nextBind = nil;
            _lightStages[lightStage].stage.nextJmpT = NULL;
            _lightStages[lightStage].stage.flags = EGW_STGFLGS_NONE;
            glDisable(GL_LIGHT0 + (GLenum)lightStage);
        }
    }
    
    // Query for max materials
    _actvMaterials = 0;
    //glGetIntegerv(GL_MAX_MATERIAL_UNITS, (GLint*)&glIntTemp); _maxMaterials = (EGWuint16)glIntTemp;
    _maxMaterials = 1; // NOTE: This is hard coded since GL spec is a single-material model. -jw
    //if(egwIsGLError(&errorString)) {
    //    NSLog(@"egwGfxContextEAGLES: initWithParams: Failure querying max material units. GLError: %@", errorString);
    //    goto ErrorCleanup;
    //}
    
    // Create material holders
    if(!(_materialStages = (egwMaterialStageAGL*)malloc(_maxMaterials * sizeof(egwMaterialStageAGL)))) {
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure allocating object.");
        goto ErrorCleanup;
    } else {
        for(EGWint materialStage = 0; materialStage < _maxMaterials; ++materialStage) {
            _materialStages[materialStage].exstBind = nil;
            _materialStages[materialStage].exstJmpT = NULL;
            _materialStages[materialStage].nextBind = nil;
            _materialStages[materialStage].nextJmpT = NULL;
            _materialStages[materialStage].flags = EGW_STGFLGS_NONE;
        }
    }
    
    // Query for max textures
    _actvTextures = 0;
    glGetIntegerv(GL_MAX_TEXTURE_UNITS, (GLint*)&glIntTemp); _maxTextures = (EGWuint16)glIntTemp;
    if(egwIsGLError(&errorString)) {
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure querying max texture units. GLError: %@", errorString);
        goto ErrorCleanup;
    }
    
    // Create texture holders
    if(!(_textureStages = (egwTextureStageAGL*)malloc(_maxTextures * sizeof(egwTextureStageAGL)))) {
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure allocating object.");
        goto ErrorCleanup;
    } else {
        for(EGWint textureStage = 0; textureStage < _maxTextures; ++textureStage) {
            _textureStages[textureStage].exstBind = nil;
            _textureStages[textureStage].exstJmpT = NULL;
            _textureStages[textureStage].nextBind = nil;
            _textureStages[textureStage].nextJmpT = NULL;
            _textureStages[textureStage].flags = EGW_STGFLGS_NONE;
        }
    }
    
    // Query for max texture size
    glGetIntegerv(GL_MAX_TEXTURE_SIZE, (GLint*)&glIntTemp); _maxTexSize.span.width = _maxTexSize.span.height = (EGWuint16)glIntTemp;
    if(egwIsGLError(&errorString)) {
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure querying max texture size. GLError: %@", errorString);
        goto ErrorCleanup;
    }
    
    if(!(_availTexIDs = [[NSMutableIndexSet alloc] init])) {
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure allocating object.");
        goto ErrorCleanup;
    }
    if(!(_usedTexIDs = [[NSMutableIndexSet alloc] init])) {
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure allocating object.");
        goto ErrorCleanup;
    }
    if(!(_dstryTexIDs = [[NSMutableIndexSet alloc] init])) {
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure allocating object.");
        goto ErrorCleanup;
    }
    
    if(!(_availBufIDs = [[NSMutableIndexSet alloc] init])) {
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure allocating object.");
        goto ErrorCleanup;
    }
    if(!(_usedBufIDs = [[NSMutableIndexSet alloc] init])) {
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure allocating object.");
        goto ErrorCleanup;
    }
    if(!(_dstryBufIDs = [[NSMutableIndexSet alloc] init])) {
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure allocating object.");
        goto ErrorCleanup;
    }
    
    // Create renderbuffer and framebuffer targets.
    
    // Generate color buffer
	glGenRenderbuffersOES(1, &_colorBuffer);
    if(egwIsGLError(&errorString)) {
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure generating color buffer. GLError: %@", errorString);
        goto ErrorCleanup;
    }
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, _colorBuffer);
    if(egwIsGLError(&errorString)) {
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure binding color buffer. GLError: %@", errorString);
        goto ErrorCleanup;
    }
    
	if(![_context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(id<EAGLDrawable>)(gfxParams->contextData)]) {
        egwIsGLError(&errorString);
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure setting up color buffer. GLError: %@", (errorString ? errorString : @"GL_NO_ERROR."));
        goto ErrorCleanup;
    } else if(egwIsGLError(&errorString)) {
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure setting up color buffer. GLError: %@", errorString);
        goto ErrorCleanup;
    }
    
    // After renderbuffer init, the width and height may be changed from content scaling, regrab actual width/height here
    {   GLint width, height;
        glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &width);
        glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &height);
        _width = (EGWuint16)width;
        _height = (EGWuint16)height;
    }
    
    // Generate depth buffer
    if(gfxParams->zbDepth != -1) {
        glGenRenderbuffersOES(1, &_depthBuffer);
        if(egwIsGLError(&errorString)) {
            NSLog(@"egwGfxContextEAGLES: initWithParams: Failure generating depth buffer. GLError: %@", errorString);
            goto ErrorCleanup;
        }
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, _depthBuffer);
        if(egwIsGLError(&errorString)) {
            NSLog(@"egwGfxContextEAGLES: initWithParams: Failure binding depth buffer. GLError: %@", errorString);
            goto ErrorCleanup;
        }
        if(gfxParams->zbDepth == 16 || gfxParams->zbDepth == 0)
            glRenderbufferStorageOES(GL_RENDERBUFFER_OES, 0x81A5, _width, _height);
        else if(gfxParams->zbDepth == 24 && [_extensions containsObject:@"GL_OES_depth24"])
            glRenderbufferStorageOES(GL_RENDERBUFFER_OES, 0x81A6, _width, _height);
        else if(gfxParams->zbDepth == 32 && [_extensions containsObject:@"GL_OES_depth32"])
            glRenderbufferStorageOES(GL_RENDERBUFFER_OES, 0x81A7, _width, _height);
        else {
            NSLog(@"egwGfxContextEAGLES: initWithParams: Failure setting up depth buffer. Bit depth %d not supported.", gfxParams->zbDepth);
            goto ErrorCleanup;
        }
        if(egwIsGLError(&errorString)) {
            NSLog(@"egwGfxContextEAGLES: initWithParams: Failure setting up depth buffer. GLError: %@", errorString);
            goto ErrorCleanup;
        }
    }
    
    // Generate stencil buffer
    if(gfxParams->sbDepth != -1 && gfxParams->sbDepth != 0) {
        glGenRenderbuffersOES(1, &_stencilBuffer);
        if(egwIsGLError(&errorString)) {
            NSLog(@"egwGfxContextEAGLES: initWithParams: Failure generating stencil buffer. GLError: %@", errorString);
            goto ErrorCleanup;
        }
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, _stencilBuffer);
        if(egwIsGLError(&errorString)) {
            NSLog(@"egwGfxContextEAGLES: initWithParams: Failure binding stencil buffer. GLError: %@", errorString);
            goto ErrorCleanup;
        }
        if(gfxParams->sbDepth == 1 && [_extensions containsObject:@"GL_OES_stencil1"])
            glRenderbufferStorageOES(GL_RENDERBUFFER_OES, 0x8D46, _width, _height);
        else if(gfxParams->sbDepth == 4 && [_extensions containsObject:@"GL_OES_stencil4"])
            glRenderbufferStorageOES(GL_RENDERBUFFER_OES, 0x8D47, _width, _height);
        else if(gfxParams->sbDepth == 8 && [_extensions containsObject:@"GL_OES_stencil8"])
            glRenderbufferStorageOES(GL_RENDERBUFFER_OES, 0x8D48, _width, _height);
        else {
            NSLog(@"egwGfxContextEAGLES: initWithParams: Failure setting up stencil buffer. Bit depth %d not supported.", gfxParams->sbDepth);
            goto ErrorCleanup;
        }
        if(egwIsGLError(&errorString)) {
            NSLog(@"egwGfxContextEAGLES: initWithParams: Failure setting up stencil buffer. GLError: %@", errorString);
            goto ErrorCleanup;
        }
    }
    
    // Generate frame buffer and wrap
	glGenFramebuffersOES(1, &_frameBuffer);
    if(egwIsGLError(&errorString)) {
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure generating frame buffer. GLError: %@", errorString);
        goto ErrorCleanup;
    }
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, _frameBuffer);
    if(egwIsGLError(&errorString)) {
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure binding frame buffer. GLError: %@", errorString);
        goto ErrorCleanup;
    }
    if(_colorBuffer != NSNotFound) {
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, _colorBuffer);
        if(egwIsGLError(&errorString)) {
            NSLog(@"egwGfxContextEAGLES: initWithParams: Failure attaching color buffer to frame buffer. GLError: %@", errorString);
            goto ErrorCleanup;
        }
    }
    if(_depthBuffer != NSNotFound) {
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, _depthBuffer);
        if(egwIsGLError(&errorString)) {
            NSLog(@"egwGfxContextEAGLES: initWithParams: Failure attaching depth buffer to frame buffer. GLError: %@", errorString);
            goto ErrorCleanup;
        }
    }
    if(_stencilBuffer != NSNotFound) {
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_STENCIL_ATTACHMENT_OES, GL_RENDERBUFFER_OES, _stencilBuffer);
        if(egwIsGLError(&errorString)) {
            NSLog(@"egwGfxContextEAGLES: initWithParams: Failure attaching stencil buffer to frame buffer. GLError: %@", errorString);
            goto ErrorCleanup;
        }
    }
    
    // Do a quick buffer clear, helps prevent the annoying "what was left over from last run" artifact
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    glFlush();
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, _colorBuffer);
    _fpPresentRB(_context, @selector(presentRenderbuffer:), GL_RENDERBUFFER_OES);
    
    // Check binding status to ensure that it worked
    bindingStatus = glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES);
    switch(bindingStatus) {
        case 0x8CD5: { // GL_FRAMEBUFFER_COMPLETE_OES
            // Yay!
        } break;
        case 0x8CD6: { // GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT_OES
            NSLog(@"egwGfxContextEAGLES: initWithParams: Failure setting up frame buffer. GLError: GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT_OES.");
            goto ErrorCleanup;
        } break;
        case 0x8CD7: { // GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT_OES
            NSLog(@"egwGfxContextEAGLES: initWithParams: Failure setting up frame buffer. GLError: GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT_OES.");
            goto ErrorCleanup;
        } break;
        case 0x8CD9: { // GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS_OES
            NSLog(@"egwGfxContextEAGLES: initWithParams: Failure setting up frame buffer. GLError: GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS_OES.");
            goto ErrorCleanup;
        } break;
        case 0x8CDA: { // GL_FRAMEBUFFER_INCOMPLETE_FORMATS_OES
            NSLog(@"egwGfxContextEAGLES: initWithParams: Failure setting up frame buffer. GLError: GL_FRAMEBUFFER_INCOMPLETE_FORMATS_OES.");
            goto ErrorCleanup;
        } break;
        case 0x8CDD: { // GL_FRAMEBUFFER_UNSUPPORTED_OES
            NSLog(@"egwGfxContextEAGLES: initWithParams: Failure setting up frame buffer. GLError: GL_FRAMEBUFFER_UNSUPPORTED_OES.");
            goto ErrorCleanup;
        } break;
        default: {
            NSLog(@"egwGfxContextEAGLES: initWithParams: Failure setting up frame buffer. GLError: %p.", (void*)(EGWuintptr)bindingStatus);
            goto ErrorCleanup;
        } break;
    }
    
    // Set up the initial viewport and scissor test to width and height
    glViewport(0, 0, (GLsizei)_width, (GLsizei)_height);
	glScissor(0, 0, (GLsizei)_width, (GLsizei)_height);
    
    // Setup framebuffer clearing
    if(gfxParams->fbClear == 0) {
        _clears |= GL_COLOR_BUFFER_BIT;
        glClearColor((GLclampf)0.5f, (GLclampf)0.5f, (GLclampf)0.5f, (GLclampf)1.0f);
    } else if(gfxParams->fbClear == 1) {
        _clears |= GL_COLOR_BUFFER_BIT;
        glClearColor((GLclampf)egwClamp01f(gfxParams->fbClearColor.channel.r), (GLclampf)egwClamp01f(gfxParams->fbClearColor.channel.g), (GLclampf)egwClamp01f(gfxParams->fbClearColor.channel.b), (GLclampf)egwClamp01f(gfxParams->fbClearColor.channel.a));
    } else if(gfxParams->fbClear == -1) {
        glClearColor((GLclampf)egwClamp01f(gfxParams->fbClearColor.channel.r), (GLclampf)egwClamp01f(gfxParams->fbClearColor.channel.g), (GLclampf)egwClamp01f(gfxParams->fbClearColor.channel.b), (GLclampf)egwClamp01f(gfxParams->fbClearColor.channel.a));
    }
    
    // Setup alpha testing
    if(gfxParams->fbAlphaTest == 0) {
        if(_frameBuffer != NSNotFound) glEnable(GL_ALPHA_TEST);
        else glDisable(GL_ALPHA_TEST);
        glAlphaFunc(GL_GEQUAL, (GLclampf)(_aCutoff = 0.25f));
    } else if(gfxParams->fbAlphaTest == 1) {
        if(_frameBuffer != NSNotFound) glEnable(GL_ALPHA_TEST);
        else glDisable(GL_ALPHA_TEST);
        glAlphaFunc(GL_GEQUAL, (GLclampf)(_aCutoff = egwClamp01f(gfxParams->fbAlphaCutoff)));
    } else if(gfxParams->fbAlphaTest == 2) {
        if(_frameBuffer != NSNotFound) glEnable(GL_ALPHA_TEST);
        else glDisable(GL_ALPHA_TEST);
        glAlphaFunc(GL_GREATER, (GLclampf)-(_aCutoff = -egwClamp01f(gfxParams->fbAlphaCutoff)));
    } else if(gfxParams->fbAlphaTest == -1) {
        glDisable(GL_ALPHA_TEST);
        glAlphaFunc(GL_GEQUAL, (GLclampf)(_aCutoff = egwClamp01f(gfxParams->fbAlphaCutoff)));
    }
    
    // Setup depth clearing
    if(gfxParams->zbClear == 0) {
        _clears |= GL_DEPTH_BUFFER_BIT;
        glClearDepthf((GLclampf)1.0f);
    } else if(gfxParams->zbClear == 1) {
        _clears |= GL_DEPTH_BUFFER_BIT;
        glClearDepthf((GLclampf)1.0f - egwClamp01f(gfxParams->zbClearColor.channel.l));
    } else if(gfxParams->zbClear == -1) {
        glClearDepthf((GLclampf)1.0f);
    }
    
    // Setup depth testing
    if(gfxParams->zbDepthTest == 0) {
        if(_depthBuffer != NSNotFound) glEnable(GL_DEPTH_TEST);
        else glDisable(GL_DEPTH_TEST);
        glDepthFunc(GL_LESS);
    } else if(gfxParams->zbDepthTest == 1) {
        if(_depthBuffer != NSNotFound) glEnable(GL_DEPTH_TEST);
        else glDisable(GL_DEPTH_TEST);
        glDepthFunc(GL_LESS);
    } else if(gfxParams->zbDepthTest == 2) {
        if(_depthBuffer != NSNotFound) glEnable(GL_DEPTH_TEST);
        else glDisable(GL_DEPTH_TEST);
        glDepthFunc(GL_LEQUAL);
    } else if(gfxParams->zbDepthTest == -1) {
        glDisable(GL_DEPTH_TEST);
        glDepthFunc(GL_LESS);
    }
    
    // Setup stencil clearing
    if(gfxParams->sbClear == 0 || gfxParams->sbClear == -1) {
        glClearStencil((GLint)egwClampi((EGWint)gfxParams->sbClearColor.channel.l, 0, 255));
    } else if(gfxParams->sbClear == 1) {
        _clears |= GL_STENCIL_BUFFER_BIT;
        glClearStencil((GLint)gfxParams->sbClearColor.channel.l);
    }
    
    // Enable all other standard stuff
    glDisable(GL_LIGHTING); _lightsEnabled = NO;
    glEnable(GL_COLOR_MATERIAL); _materialsEnabled = NO;
    glDisable(GL_TEXTURE_2D); _texturesEnabled = NO;
    glEnableClientState(GL_NORMAL_ARRAY);
    glEnableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glLightModelf(GL_LIGHT_MODEL_TWO_SIDE, 0.0f);
    glShadeModel(GL_SMOOTH);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    // If there is a delegate defined, call its willFinish method
    if(_delegate && ![_delegate willFinishInitializingGfxContext:self]) {
        NSLog(@"egwGfxContextEAGLES: initWithParams: Failure in user initialization code.");
        goto ErrorCleanup;
    }
	
    // If there was an old context, revert back to it, otherwise keep this one enabled.
    pthread_mutex_unlock(&_apiLock_EAGLES);
    if(oldContext) [oldContext makeActive];
    
    [_delegate didFinishInitializingGfxContext:self];
    
    if(EGW_ENGINE_MANAGERS_STARTUPMSGS) NSLog(@"egwGfxContextEAGLES: initWithParams: Graphics context has been initialized.");
    
    return self;
    
ErrorCleanup:
    --_apiRefCnt_EAGLES;
    _thread = nil;
    pthread_mutex_unlock(&_apiLock_EAGLES);
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
    
    if(_apiRefCnt_EAGLES == 0) {
        @synchronized(self) {
            if(_apiRefCnt_EAGLES == 0) {
                pthread_mutex_destroy(&_apiLock_EAGLES);
            }
        }
    }
    
    [super dealloc];
}

- (BOOL)beginRender {
    //@synchronized(self) {
        if(!_inPass && egwAIGfxCntx == self && _thread == egwSFPNSThreadCurrentThread(nil, @selector(currentThread))) {
            _inPass = YES;
            //egwIsGLError(NULL);
            glBindFramebufferOES(GL_FRAMEBUFFER_OES, _frameBuffer);
            glBindRenderbufferOES(GL_RENDERBUFFER_OES, _colorBuffer);
            
            egwAFPGfxCntxAGLCheckBindings(self, @selector(checkBindings));
            
            if(_clears) glClear((GLbitfield)_clears);
            
            glDisableClientState(GL_COLOR_ARRAY);
            
            // Resync lighting and texturing booleans, just to be on safe side
            _lightsEnabled = (glIsEnabled(GL_LIGHTING) ? YES : NO);
            _texturesEnabled = (glIsEnabled(GL_TEXTURE_2D) ? YES : NO);
            
            if(!_fTime && _delegate)
                _fTime = [[NSDate alloc] initWithTimeIntervalSinceNow:(NSTimeInterval)EGW_GFXCONTEXT_FPSMEASURES];
            
            return YES;// (!egwIsGLError(NULL) ? YES : NO);
        } else {
            NSLog(@"egwGfxContextEAGLES: beginRender: Failure beginning render. Already in rendering pass or context not active [on this thread].");
        }
    //}
    
    return NO;
}

- (BOOL)interruptRender {
    //@synchronized(self) {
        if(_inPass && egwAIGfxCntx == self && _thread == egwSFPNSThreadCurrentThread(nil, @selector(currentThread))) {
            _inPass = NO;
            //egwIsGLError(NULL);
            return YES;
        } else {
            NSLog(@"egwGfxContextEAGLES: interruptRender: Failure interrupting render. Not in rendering pass or context not active [on this thread].");
        }
    //}
    
    return NO;
}

- (BOOL)endRender {
    //@synchronized(self) {
        if(_inPass && egwAIGfxCntx == self && _thread == egwSFPNSThreadCurrentThread(nil, @selector(currentThread))) {
            //egwIsGLError(NULL);
            //glFinish();
            glFlush();
            glBindRenderbufferOES(GL_RENDERBUFFER_OES, _colorBuffer);
            _fpPresentRB(_context, @selector(presentRenderbuffer:), GL_RENDERBUFFER_OES);
            
            if(_fTime) {
                ++_fCount;
                
                if([_fTime timeIntervalSinceNow] < 0.0) {
                    _fpsAvg = (EGWsingle)_fCount / (EGWsingle)((NSTimeInterval)EGW_GFXCONTEXT_FPSMEASURES - [_fTime timeIntervalSinceNow]);
                    if(_delegate)
                        [_delegate didUpdateContext:self framesPerSecond:_fpsAvg];
                    [_fTime release]; _fTime = nil; _fCount = 0;
                }
            }
            
            _inPass = NO;
            
            return YES; //(!egwIsGLError(NULL) ? YES : NO);
        } else {
            NSLog(@"egwGfxContextEAGLES: endRender: Failure ending render. Not in rendering pass or context not active [on this thread].");
        }
    //}
    
    return NO;
}

- (BOOL)makeActive {
    pthread_mutex_lock(&_apiLock_EAGLES);
    
    if(!_inPass) {
        if(_context) {
            _fpSetCurrCntx(nil, @selector(setCurrentContext:), _context); // NOTICE: If this gets called too often, sound will start crackling/popping. -jw
            egwAIGfxCntx = self;
            egwAIGfxCntxAGL = self;
            egwAIGfxCntxNSGL = nil;
            egwAIGfxCntxEAGLES = self;
            _thread = egwSFPNSThreadCurrentThread(nil, @selector(currentThread));
            
            egwAFPGfxCntxPushLight = (void(*)(id, SEL, id<egwPLight>, const egwLightJumpTable*))[self methodForSelector:@selector(pushLight:withLightJumpTable:)];
            egwAFPGfxCntxPopLights = (void(*)(id, SEL, EGWuint))[self methodForSelector:@selector(popLights:)];
            egwAFPGfxCntxBindLights = (void(*)(id, SEL))[self methodForSelector:@selector(bindLights)];
            egwAFPGfxCntxUnbindLights = (void(*)(id, SEL))[self methodForSelector:@selector(unbindLights)];
            egwAFPGfxCntxPushMaterial = (void(*)(id, SEL, id<egwPMaterial>, const egwMaterialJumpTable*))[self methodForSelector:@selector(pushMaterial:withMaterialJumpTable:)];
            egwAFPGfxCntxPopMaterials = (void(*)(id, SEL, EGWuint))[self methodForSelector:@selector(popMaterials:)];
            egwAFPGfxCntxBindMaterials = (void(*)(id, SEL))[self methodForSelector:@selector(bindMaterials)];
            egwAFPGfxCntxUnbindMaterials = (void(*)(id, SEL))[self methodForSelector:@selector(unbindMaterials)];
            egwAFPGfxCntxPushShader = (void(*)(id, SEL, id<egwPShader>, const egwShaderJumpTable*))[self methodForSelector:@selector(pushShader:withShaderJumpTable:)];
            egwAFPGfxCntxPopShaders = (void(*)(id, SEL, EGWuint))[self methodForSelector:@selector(popShaders:)];
            egwAFPGfxCntxBindShaders = (void(*)(id, SEL))[self methodForSelector:@selector(bindShaders)];
            egwAFPGfxCntxUnbindShaders = (void(*)(id, SEL))[self methodForSelector:@selector(unbindShaders)];
            egwAFPGfxCntxPushTexture = (void(*)(id, SEL, id<egwPTexture>, const egwTextureJumpTable*))[self methodForSelector:@selector(pushTexture:withTextureJumpTable:)];
            egwAFPGfxCntxPopTextures = (void(*)(id, SEL, EGWuint))[self methodForSelector:@selector(popTextures:)];
            egwAFPGfxCntxBindTextures = (void(*)(id, SEL))[self methodForSelector:@selector(bindTextures)];
            egwAFPGfxCntxUnbindTextures = (void(*)(id, SEL))[self methodForSelector:@selector(unbindTextures)];
            egwAFPGfxCntxIlluminationFrame = (EGWuint16(*)(id, SEL))[self methodForSelector:@selector(illuminationFrame)];
            egwAFPGfxCntxRenderingFrame = (EGWuint16(*)(id, SEL))[self methodForSelector:@selector(renderingFrame)];
            egwAFPGfxCntxAdvanceIlluminationFrame = (void(*)(id, SEL))[self methodForSelector:@selector(advanceIlluminationFrame)];
            egwAFPGfxCntxAdvanceRenderingFrame = (void(*)(id, SEL))[self methodForSelector:@selector(advanceRenderingFrame)];
            egwAFPGfxCntxBeginRender = (BOOL(*)(id, SEL))[self methodForSelector:@selector(beginRender)];
            egwAFPGfxCntxInterruptRender = (BOOL(*)(id, SEL))[self methodForSelector:@selector(interruptRender)];
            egwAFPGfxCntxEndRender = (BOOL(*)(id, SEL))[self methodForSelector:@selector(endRender)];
            egwAFPGfxCntxMakeActive = (BOOL(*)(id, SEL))[self methodForSelector:@selector(makeActive)];
            egwAFPGfxCntxActive = (BOOL(*)(id, SEL))[self methodForSelector:@selector(isActive)];
            egwAFPGfxCntxPerformSubTasks = (void(*)(id, SEL))[self methodForSelector:@selector(performSubTasks)];
            egwAFPGfxCntxActiveCamera = (id<egwPCamera>(*)(id, SEL))[self methodForSelector:@selector(activeCamera)];
            egwAFPGfxCntxActiveCameraViewingFrame = (EGWuint16(*)(id, SEL))[self methodForSelector:@selector(activeCameraViewingFrame)];
            egwAFPGfxCntxSetActiveCamera = (void(*)(id, SEL, id<egwPCamera>))[self methodForSelector:@selector(setActiveCamera:)];
            
            pthread_mutex_unlock(&_apiLock_EAGLES);
            return YES;
        } else {
            NSLog(@"egwGfxContextEAGLES: makeActive: Failure making active. Context is not valid.");
        }
    } else {
        NSLog(@"egwGfxContextEAGLES: makeActive: Failure making active. Already in rendering pass.");
    }
    
    pthread_mutex_unlock(&_apiLock_EAGLES);
    return NO;
}

- (BOOL)makeActiveAndLocked {
    if(!_inPass) {
        if(_context) {
            pthread_mutex_lock(&_apiLock_EAGLES);
            
            if(!_inPass) {
                if(_context) {
                    _fpSetCurrCntx(nil, @selector(setCurrentContext:), _context); // NOTICE: If this gets called too often, sound will start crackling/popping. -jw
                    egwAIGfxCntx = self;
                    egwAIGfxCntxAGL = self;
                    egwAIGfxCntxNSGL = nil;
                    egwAIGfxCntxEAGLES = self;
                    _thread = egwSFPNSThreadCurrentThread(nil, @selector(currentThread));
                    
                    egwAFPGfxCntxPushLight = (void(*)(id, SEL, id<egwPLight>, const egwLightJumpTable*))[self methodForSelector:@selector(pushLight:withLightJumpTable:)];
                    egwAFPGfxCntxPopLights = (void(*)(id, SEL, EGWuint))[self methodForSelector:@selector(popLights:)];
                    egwAFPGfxCntxBindLights = (void(*)(id, SEL))[self methodForSelector:@selector(bindLights)];
                    egwAFPGfxCntxUnbindLights = (void(*)(id, SEL))[self methodForSelector:@selector(unbindLights)];
                    egwAFPGfxCntxPushMaterial = (void(*)(id, SEL, id<egwPMaterial>, const egwMaterialJumpTable*))[self methodForSelector:@selector(pushMaterial:withMaterialJumpTable:)];
                    egwAFPGfxCntxPopMaterials = (void(*)(id, SEL, EGWuint))[self methodForSelector:@selector(popMaterials:)];
                    egwAFPGfxCntxBindMaterials = (void(*)(id, SEL))[self methodForSelector:@selector(bindMaterials)];
                    egwAFPGfxCntxUnbindMaterials = (void(*)(id, SEL))[self methodForSelector:@selector(unbindMaterials)];
                    egwAFPGfxCntxPushShader = (void(*)(id, SEL, id<egwPShader>, const egwShaderJumpTable*))[self methodForSelector:@selector(pushShader:withShaderJumpTable:)];
                    egwAFPGfxCntxPopShaders = (void(*)(id, SEL, EGWuint))[self methodForSelector:@selector(popShaders:)];
                    egwAFPGfxCntxBindShaders = (void(*)(id, SEL))[self methodForSelector:@selector(bindShaders)];
                    egwAFPGfxCntxUnbindShaders = (void(*)(id, SEL))[self methodForSelector:@selector(unbindShaders)];
                    egwAFPGfxCntxPushTexture = (void(*)(id, SEL, id<egwPTexture>, const egwTextureJumpTable*))[self methodForSelector:@selector(pushTexture:withTextureJumpTable:)];
                    egwAFPGfxCntxPopTextures = (void(*)(id, SEL, EGWuint))[self methodForSelector:@selector(popTextures:)];
                    egwAFPGfxCntxBindTextures = (void(*)(id, SEL))[self methodForSelector:@selector(bindTextures)];
                    egwAFPGfxCntxUnbindTextures = (void(*)(id, SEL))[self methodForSelector:@selector(unbindTextures)];
                    egwAFPGfxCntxIlluminationFrame = (EGWuint16(*)(id, SEL))[self methodForSelector:@selector(illuminationFrame)];
                    egwAFPGfxCntxRenderingFrame = (EGWuint16(*)(id, SEL))[self methodForSelector:@selector(renderingFrame)];
                    egwAFPGfxCntxAdvanceIlluminationFrame = (void(*)(id, SEL))[self methodForSelector:@selector(advanceIlluminationFrame)];
                    egwAFPGfxCntxAdvanceRenderingFrame = (void(*)(id, SEL))[self methodForSelector:@selector(advanceRenderingFrame)];
                    egwAFPGfxCntxBeginRender = (BOOL(*)(id, SEL))[self methodForSelector:@selector(beginRender)];
                    egwAFPGfxCntxInterruptRender = (BOOL(*)(id, SEL))[self methodForSelector:@selector(interruptRender)];
                    egwAFPGfxCntxEndRender = (BOOL(*)(id, SEL))[self methodForSelector:@selector(endRender)];
                    egwAFPGfxCntxMakeActive = (BOOL(*)(id, SEL))[self methodForSelector:@selector(makeActive)];
                    egwAFPGfxCntxActive = (BOOL(*)(id, SEL))[self methodForSelector:@selector(isActive)];
                    egwAFPGfxCntxPerformSubTasks = (void(*)(id, SEL))[self methodForSelector:@selector(performSubTasks)];
                    egwAFPGfxCntxActiveCamera = (id<egwPCamera>(*)(id, SEL))[self methodForSelector:@selector(activeCamera)];
                    egwAFPGfxCntxActiveCameraViewingFrame = (EGWuint16(*)(id, SEL))[self methodForSelector:@selector(activeCameraViewingFrame)];
                    egwAFPGfxCntxSetActiveCamera = (void(*)(id, SEL, id<egwPCamera>))[self methodForSelector:@selector(setActiveCamera:)];
                    
                    return YES;
                } else {
                    NSLog(@"egwGfxContextEAGLES: makeActiveAndLocked: Failure making active. Context is not valid.");
                    pthread_mutex_unlock(&_apiLock_EAGLES);
                }
            } else {
                NSLog(@"egwGfxContextEAGLES: makeActiveAndLocked: Failure making active. Already in rendering pass.");
                pthread_mutex_unlock(&_apiLock_EAGLES);
            }
        } else {
            NSLog(@"egwGfxContextEAGLES: makeActiveAndLocked: Failure making active. Context is not valid.");
        }
    } else {
        NSLog(@"egwGfxContextEAGLES: makeActiveAndLocked: Failure making active. Already in rendering pass.");
    }
    
    return NO;
}

- (BOOL)resizeBufferWidth:(EGWuint16)width bufferHeight:(EGWuint16)height {
    if(width != _width || height != _height) {
        NSLog(@"egwGfxContextEAGLES: resizeBufferWidth:bufferHeight: Error: This method is not yet implemented.");
        return NO;
    }
    
    return YES;
}

- (void)shutDownContext {
    if(!_doShutdown) {
        @synchronized(self) {
            if(!_doShutdown) {
                // Allow delegate to cancel shutDownContext, else proceed
                if(_delegate && ![_delegate willShutDownGfxContext:self]) return;
                _doShutdown = YES;
                
                if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwGfxContextEAGLES: shutDownContext: Shutting down graphics context.");
                
                // Wait for renderer status to deactivate
                if(_inPass) {
                    NSDate* waitTill = [[NSDate alloc] initWithTimeIntervalSinceNow:(NSTimeInterval)EGW_ENGINE_MANAGERS_TIMETOWAIT];
                    while(_inPass) {
                        if([waitTill timeIntervalSinceNow] < (NSTimeInterval)0.0) {
                            NSLog(@"egwGfxContextEAGLES: shutDownContext: Failure waiting for renderer running status to deactivate.");
                            break;
                        }
                        
                        [NSThread sleepForTimeInterval:EGW_ENGINE_MANAGERS_TIMETOSLEEP];
                    }
                    [waitTill release];
                }
                
                if(_context && ![self isActive]) [self makeActive];
                pthread_mutex_lock(&_apiLock_EAGLES);
                
                [super shutDownContext];
                
                // Destroy render buffers
                if(_stencilBuffer != NSNotFound) {
                    glDeleteRenderbuffersOES(1, &_stencilBuffer);
                    _stencilBuffer = NSNotFound;
                }
                if(_depthBuffer != NSNotFound) {
                    glDeleteRenderbuffersOES(1, &_depthBuffer);
                    _depthBuffer = NSNotFound;
                }
                if(_colorBuffer != NSNotFound) {
                    glDeleteRenderbuffersOES(1, &_colorBuffer);
                    _colorBuffer = NSNotFound;
                }
                
                // Destroy framebuffer
                if(_frameBuffer != NSNotFound) {
                    glDeleteFramebuffersOES(1, &_frameBuffer);
                    _frameBuffer = NSNotFound;
                }
                
                // Destroy context
                if(_context) {
                    --_apiRefCnt_EAGLES;
                    if(egwAIGfxCntx == self) {
                        [EAGLContext setCurrentContext:nil];
                        egwAIGfxCntx = nil;
                        egwAIGfxCntxAGL = nil;
                        egwAIGfxCntxNSGL = nil;
                        egwAIGfxCntxEAGLES = nil;
                        _inPass = NO;
                        
                        egwAFPGfxCntxPushLight = (void(*)(id, SEL, id<egwPLight>, const egwLightJumpTable*))NULL;
                        egwAFPGfxCntxPopLights = (void(*)(id, SEL, EGWuint))NULL;
                        egwAFPGfxCntxBindLights = (void(*)(id, SEL))NULL;
                        egwAFPGfxCntxUnbindLights = (void(*)(id, SEL))NULL;
                        egwAFPGfxCntxPushMaterial = (void(*)(id, SEL, id<egwPMaterial>, const egwMaterialJumpTable*))NULL;
                        egwAFPGfxCntxPopMaterials = (void(*)(id, SEL, EGWuint))NULL;
                        egwAFPGfxCntxBindMaterials = (void(*)(id, SEL))NULL;
                        egwAFPGfxCntxUnbindMaterials = (void(*)(id, SEL))NULL;
                        egwAFPGfxCntxPushShader = (void(*)(id, SEL, id<egwPShader>, const egwShaderJumpTable*))NULL;
                        egwAFPGfxCntxPopShaders = (void(*)(id, SEL, EGWuint))NULL;
                        egwAFPGfxCntxBindShaders = (void(*)(id, SEL))NULL;
                        egwAFPGfxCntxUnbindShaders = (void(*)(id, SEL))NULL;
                        egwAFPGfxCntxPushTexture = (void(*)(id, SEL, id<egwPTexture>, const egwTextureJumpTable*))NULL;
                        egwAFPGfxCntxPopTextures = (void(*)(id, SEL, EGWuint))NULL;
                        egwAFPGfxCntxBindTextures = (void(*)(id, SEL))NULL;
                        egwAFPGfxCntxUnbindTextures = (void(*)(id, SEL))NULL;
                        egwAFPGfxCntxIlluminationFrame = (EGWuint16(*)(id, SEL))NULL;
                        egwAFPGfxCntxRenderingFrame = (EGWuint16(*)(id, SEL))NULL;
                        egwAFPGfxCntxAdvanceIlluminationFrame = (void(*)(id, SEL))NULL;
                        egwAFPGfxCntxAdvanceRenderingFrame = (void(*)(id, SEL))NULL;
                        egwAFPGfxCntxBeginRender = (BOOL(*)(id, SEL))NULL;
                        egwAFPGfxCntxInterruptRender = (BOOL(*)(id, SEL))NULL;
                        egwAFPGfxCntxEndRender = (BOOL(*)(id, SEL))NULL;
                        egwAFPGfxCntxMakeActive = (BOOL(*)(id, SEL))NULL;
                        egwAFPGfxCntxActive = (BOOL(*)(id, SEL))NULL;
                        egwAFPGfxCntxPerformSubTasks = (void(*)(id, SEL))NULL;
                        egwAFPGfxCntxActiveCamera = (id<egwPCamera>(*)(id, SEL))NULL;
                        egwAFPGfxCntxActiveCameraViewingFrame = (EGWuint16(*)(id, SEL))NULL;
                        egwAFPGfxCntxSetActiveCamera = (void(*)(id, SEL, id<egwPCamera>))NULL;
                    }
                    _thread = nil;
                    [_context release]; _context = nil;
                }
                
                pthread_mutex_unlock(&_apiLock_EAGLES);
                [_delegate didShutDownGfxContext:self];
                
                if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwGfxContextEAGLES: shutDownContext: Graphics context shut down.");
            }
        }
    }
}

+ (EGWint)apiIdent {
    return EGW_ENGINE_GFXAPI_OPENGLES11;
}

+ (pthread_mutex_t*)apiMutex {
    return &_apiLock_EAGLES;
}

@end


#else

@implementation egwGfxContextEAGLES

- (id)init {
    NSLog(@"egwGfxContextEAGLES: init: Cannot initialize object due to build mode settings. YOU'RE DOING IT WRONG!");
    
    [self release]; return (self = nil);
}

- (id)initWithParams:(void*)params {
    NSLog(@"egwGfxContextEAGLES: initWithParams: Cannot initialize object due to build mode settings. YOU'RE DOING IT WRONG!");
    
    [self release]; return (self = nil);
}

@end

#endif

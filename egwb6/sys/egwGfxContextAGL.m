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

/// @file egwGfxContextAGL.m
/// @ingroup geWizES_sys_gfxcontextagl
/// Abstract OpenGL Graphics Context Implementation.

#import <pthread.h>
#import "egwGfxContextAGL.h"
#import "egwGfxContextNSGL.h"
#import "egwGfxContextEAGLES.h"
#import "../sys/egwEngine.h"
#import "../sys/egwGfxRenderer.h"
#import "../math/egwMath.h"
#import "../math/egwVector.h"
#import "../gfx/egwGraphics.h"
#import "../gfx/egwLights.h"
#import "../gfx/egwTexture.h"
#import "../geo/egwGeometry.h"
#import "../misc/egwValidater.h"


void (*egwAFPGfxCntxAGLCheckBindings)(id, SEL) = NULL;
egwGfxContextAGL* egwAIGfxCntxAGL = nil;
static EGWuint _glActClTex = (EGWuint)NSNotFound;
static EGWuint _glTexBinds[32] = { (EGWuint)NSNotFound };
static EGWuint _glEnvBind = (EGWuint)NSNotFound;
static EGWuint _glBufBinds[2] = { (EGWuint)0 }; // Must be 0 since 0 is "turn off" state

#if defined(EGW_BUILDMODE_DESKTOP) || defined(EGW_BUILDMODE_IPHONE)

EGWint egwIsGLError(NSString** errorString) {
    GLenum errorEnum = glGetError();
    switch(errorEnum) {
        case GL_NO_ERROR: {
            if(errorString) *errorString = nil;
        } return 0;
        case GL_INVALID_ENUM: {
            if(errorString) *errorString = [NSString stringWithString:@"GL_INVALID_ENUM: Invalid enumeration."];
        } return 1;
        case GL_INVALID_VALUE: {
            if(errorString) *errorString = [NSString stringWithString:@"GL_INVALID_VALUE: Invalid parameter."];
        } return 1;
        case GL_INVALID_OPERATION: {
            if(errorString) *errorString = [NSString stringWithString:@"GL_INVALID_OPERATION: Invalid operation."];
        } return 1;
        case GL_STACK_OVERFLOW: {
            if(errorString) *errorString = [NSString stringWithString:@"GL_STACK_OVERFLOW: Stack overflow."];
        } return 1;
        case GL_STACK_UNDERFLOW: {
            if(errorString) *errorString = [NSString stringWithString:@"GL_STACK_UNDERFLOW: Stack underflow."];
        } return 1;
        case GL_OUT_OF_MEMORY: {
            if(errorString) *errorString = [NSString stringWithString:@"GL_OUT_OF_MEMORY: Out of memory."];
        } return 1;
    }
    
    return 0;
}

BOOL egw_glClientActiveTexture(EGWuint texture) {
    if(_glActClTex != texture) {
        _glActClTex = texture;
        
        glClientActiveTexture((GLenum)texture);
        
        return YES;
    }
    
    return NO;
}

BOOL egw_glBindTexture(EGWuint texture, EGWuint target, EGWuint identifier) {
    if(_glTexBinds[texture - (EGWuint)GL_TEXTURE0] != identifier) {
        _glTexBinds[texture - (EGWuint)GL_TEXTURE0] = identifier;
        
        glBindTexture((GLenum)target, (GLuint)identifier);
        
        return YES;
    }
    
    return NO;
}

BOOL egw_glBindBuffer(EGWuint target, EGWuint buffer) {
    switch(target) {
        case GL_ARRAY_BUFFER: {
            if(_glBufBinds[0] != buffer) {
                _glBufBinds[0] = buffer;
                
                glBindBuffer((GLenum)target, (GLuint)buffer);
                
                return YES;
            }
        } break;
        
        case GL_ELEMENT_ARRAY_BUFFER: {
            if(_glBufBinds[1] != buffer) {
                _glBufBinds[1] = buffer;
                
                glBindBuffer((GLenum)target, (GLuint)buffer);
                
                return YES;
            }
        } break;
        
        default: {
            glBindBuffer((GLenum)target, (GLuint)buffer);
            
            return YES;
        }
    }
    
    return NO;
}

BOOL egw_glBindEnvironment(EGWuint environment) {
    if(_glEnvBind != environment) {
        _glEnvBind = environment;
        
        switch(environment) {
            default:
            case EGW_TEXTURE_FENV_MODULATE: {
                glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
                
                glTexEnvf(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_MODULATE);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC0_RGB, GL_PREVIOUS);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND0_RGB, GL_SRC_COLOR);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC1_RGB, GL_TEXTURE);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND1_RGB, GL_SRC_COLOR);
                glTexEnvf(GL_TEXTURE_ENV, GL_RGB_SCALE, 1.0f);
                
                glTexEnvf(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_MODULATE);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC0_ALPHA, GL_PREVIOUS);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND0_ALPHA, GL_SRC_ALPHA);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC1_ALPHA, GL_TEXTURE);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND1_ALPHA, GL_SRC_ALPHA);
                glTexEnvf(GL_TEXTURE_ENV, GL_ALPHA_SCALE, 1.0f);
            } break;
                
            case EGW_TEXTURE_FENV_MODULATEX2: {
                glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
                
                glTexEnvf(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_MODULATE);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC0_RGB, GL_PREVIOUS);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND0_RGB, GL_SRC_COLOR);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC1_RGB, GL_TEXTURE);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND1_RGB, GL_SRC_COLOR);
                glTexEnvf(GL_TEXTURE_ENV, GL_RGB_SCALE, 2.0f);
                
                glTexEnvf(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_MODULATE);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC0_ALPHA, GL_PREVIOUS);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND0_ALPHA, GL_SRC_ALPHA);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC1_ALPHA, GL_TEXTURE);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND1_ALPHA, GL_SRC_ALPHA);
                glTexEnvf(GL_TEXTURE_ENV, GL_ALPHA_SCALE, 1.0f);
            } break;
                
            case EGW_TEXTURE_FENV_MODULATEX4: {
                glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
                
                glTexEnvf(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_MODULATE);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC0_RGB, GL_PREVIOUS);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND0_RGB, GL_SRC_COLOR);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC1_RGB, GL_TEXTURE);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND1_RGB, GL_SRC_COLOR);
                glTexEnvf(GL_TEXTURE_ENV, GL_RGB_SCALE, 4.0f);
                
                glTexEnvf(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_MODULATE);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC0_ALPHA, GL_PREVIOUS);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND0_ALPHA, GL_SRC_ALPHA);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC1_ALPHA, GL_TEXTURE);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND1_ALPHA, GL_SRC_ALPHA);
                glTexEnvf(GL_TEXTURE_ENV, GL_ALPHA_SCALE, 1.0f);
            } break;
                
            case EGW_TEXTURE_FENV_DOT3: {
                // Only way to do this
                glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
                
                glTexEnvf(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_DOT3_RGB);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC0_RGB, GL_TEXTURE);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND0_RGB, GL_SRC_COLOR);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC1_RGB, GL_PREVIOUS);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND1_RGB, GL_SRC_COLOR);
                glTexEnvf(GL_TEXTURE_ENV, GL_RGB_SCALE, 1.0f);
                
                glTexEnvf(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_REPLACE);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC0_ALPHA, GL_PREVIOUS);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND0_ALPHA, GL_SRC_ALPHA);
                glTexEnvf(GL_TEXTURE_ENV, GL_ALPHA_SCALE, 1.0f);
            } break;
                
            case EGW_TEXTURE_FENV_ADD: {
                glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
                
                glTexEnvf(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_ADD);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC0_RGB, GL_PREVIOUS);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND0_RGB, GL_SRC_COLOR);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC1_RGB, GL_TEXTURE);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND1_RGB, GL_SRC_COLOR);
                glTexEnvf(GL_TEXTURE_ENV, GL_RGB_SCALE, 1.0f);
                
                glTexEnvf(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_MODULATE);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC0_ALPHA, GL_PREVIOUS);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND0_ALPHA, GL_SRC_ALPHA);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC1_ALPHA, GL_TEXTURE);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND1_ALPHA, GL_SRC_ALPHA);
                glTexEnvf(GL_TEXTURE_ENV, GL_ALPHA_SCALE, 1.0f);
            } break;
                
            case EGW_TEXTURE_FENV_ADDSIGNED: {
                // Only way to do this
                glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
                
                glTexEnvf(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_ADD_SIGNED);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC0_RGB, GL_PREVIOUS);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND0_RGB, GL_SRC_COLOR);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC1_RGB, GL_TEXTURE);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND1_RGB, GL_SRC_COLOR);
                glTexEnvf(GL_TEXTURE_ENV, GL_RGB_SCALE, 1.0f);
                
                glTexEnvf(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_MODULATE);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC0_ALPHA, GL_PREVIOUS);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND0_ALPHA, GL_SRC_ALPHA);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC1_ALPHA, GL_TEXTURE);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND1_ALPHA, GL_SRC_ALPHA);
                glTexEnvf(GL_TEXTURE_ENV, GL_ALPHA_SCALE, 1.0f);
            } break;
                
            case EGW_TEXTURE_FENV_BLEND: {
                // Only way to do this
                glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_BLEND);
                glTexEnvf(GL_TEXTURE_ENV, GL_RGB_SCALE, 1.0f);
            } break;
                
            case EGW_TEXTURE_FENV_DECAL: {
                // Only way to do this
                glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);
                glTexEnvf(GL_TEXTURE_ENV, GL_RGB_SCALE, 1.0f);
            } break;
                
            case EGW_TEXTURE_FENV_REPLACE: {
                glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
                
                glTexEnvf(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_REPLACE);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC0_RGB, GL_TEXTURE);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND0_RGB, GL_SRC_COLOR);
                glTexEnvf(GL_TEXTURE_ENV, GL_RGB_SCALE, 1.0f);
                
                glTexEnvf(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_REPLACE);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC0_ALPHA, GL_TEXTURE);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND0_ALPHA, GL_SRC_ALPHA);
                glTexEnvf(GL_TEXTURE_ENV, GL_ALPHA_SCALE, 1.0f);
            } break;
                
            case EGW_TEXTURE_FENV_SUBTRACT: {
                // Only way to do this
                glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
                
                glTexEnvf(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_SUBTRACT);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC0_RGB, GL_PREVIOUS);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND0_RGB, GL_SRC_COLOR);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC1_RGB, GL_TEXTURE);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND1_RGB, GL_SRC_COLOR);
                glTexEnvf(GL_TEXTURE_ENV, GL_RGB_SCALE, 1.0f);
                
                glTexEnvf(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_MODULATE);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC0_ALPHA, GL_PREVIOUS);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND0_ALPHA, GL_SRC_ALPHA);
                glTexEnvf(GL_TEXTURE_ENV, GL_SRC1_ALPHA, GL_TEXTURE);
                glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND1_ALPHA, GL_SRC_ALPHA);
                glTexEnvf(GL_TEXTURE_ENV, GL_ALPHA_SCALE, 1.0f);
            } break;
        }
        
        return YES;
    }
    
    return NO;
}


@implementation egwGfxContextAGL

- (id)init {
    if(![[self class] isSubclassOfClass:[egwGfxContextAGL class]]) {
        NSLog(@"egwGfxContextAGL: init: Error: This method must only be called from derived classes. YOU'RE DOING IT WRONG!");
        [self release]; return (self = nil);
    }
    
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    // Create index lock
    if(pthread_mutex_init(&_iLock, NULL)) { [self release]; return (self = nil); }
    
    // Set default mipping filter for texture loader.
    _dfltFilter = EGW_TEXTURE_FLTR_LINEAR | EGW_TEXTURE_FLTR_BILINEAR;
    
    egwAFPGfxCntxAGLCheckBindings = (void(*)(id,SEL))[(NSObject*)self methodForSelector:@selector(checkBindings)];
    
    return self;
}

- (id)initWithParams:(void*)params {
    NSLog(@"egwGfxContextAGL: initWithParams: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
    [self release]; return (self = nil);
}

- (void)dealloc {
    [_extensions release]; _extensions = nil;
    
    pthread_mutex_destroy(&_iLock);
    
    [super dealloc];
}

- (void)checkBindings {
    egwValidater* validater;
    
    // Look for any lights that have been invalidated and flag them as invalidated
    for(EGWint illumStage = 0; illumStage < _maxLights; ++illumStage) {
        if(_lightStages[illumStage].stage.exstBind && !(_lightStages[illumStage].stage.flags & EGW_STGFLGS_ISINVALIDATED)) {
            validater = _lightStages[illumStage].stage.exstJmpT->fpISync(_lightStages[illumStage].stage.exstBind, @selector(illuminationSync));
            if(validater && egwSFPVldtrIsInvalidated(validater, @selector(isInvalidated)))
                _lightStages[illumStage].stage.flags |= EGW_STGFLGS_ISINVALIDATED;
        }
    }
    
    // Look for any materials that have been invalidated and flag them as invalidated
    for(EGWint surfacingStage = 0; surfacingStage < _maxMaterials; ++surfacingStage) {
        if(_materialStages[surfacingStage].exstBind && !(_materialStages[surfacingStage].flags & EGW_STGFLGS_ISINVALIDATED)) {
            validater = _materialStages[surfacingStage].exstJmpT->fpSSync(_materialStages[surfacingStage].exstBind, @selector(surfacingSync));
            if(validater && egwSFPVldtrIsInvalidated(validater, @selector(isInvalidated)))
                _materialStages[surfacingStage].flags |= EGW_STGFLGS_ISINVALIDATED;
        }
    }
    
    // Look for any shaders that have been invalidated and flag them as invalidated
    for(EGWint shadingStage = 0; shadingStage < _maxShaders; ++shadingStage) {
        if(_shaderStages[shadingStage].exstBind && !(_shaderStages[shadingStage].flags & EGW_STGFLGS_ISINVALIDATED)) {
            validater = _shaderStages[shadingStage].exstJmpT->fpSSync(_shaderStages[shadingStage].exstBind, @selector(shadingSync));
            if(validater && egwSFPVldtrIsInvalidated(validater, @selector(isInvalidated)))
                _shaderStages[shadingStage].flags |= EGW_STGFLGS_ISINVALIDATED;
        }
    }
    
    // Look for any textures that have been invalidated and flag them as invalidated
    for(EGWint texturingStage = 0; texturingStage < _maxTextures; ++texturingStage) {
        if(_textureStages[texturingStage].exstBind && !(_textureStages[texturingStage].flags & EGW_STGFLGS_ISINVALIDATED)) {
            validater = _textureStages[texturingStage].exstJmpT->fpTSync(_textureStages[texturingStage].exstBind, @selector(texturingSync));
            if(validater && egwSFPVldtrIsInvalidated(validater, @selector(isInvalidated)))
                _textureStages[texturingStage].flags |= EGW_STGFLGS_ISINVALIDATED;
        }
    }
}

- (void)performSubTasks {
    if(_sTasks.eCount || [_dstryTexIDs count] || [_dstryBufIDs count]) {
        [super performSubTasks];
        
        if([_dstryTexIDs count]) {
            if(_actvTextures) {
                [self unbindTextures];
            }
            
            pthread_mutex_lock(&_iLock);
            
            while([_dstryTexIDs count]) {
                NSString* errorString = nil;
                EGWuint texID = (EGWuint)[_dstryTexIDs firstIndex];
                
                glGetError(); // Clear background errors
                
                if(glIsTexture((GLuint)texID)) {
                    glDeleteTextures((GLsizei)1, (const GLuint*)&texID);
                    //glFinish();
                }
                
                if(!egwIsGLError(&errorString))
                    [_dstryTexIDs removeIndex:(NSUInteger)texID];
                else {
                    NSLog(@"egwGfxContextAGL: performSubTasks: Failure deleting texture ID %d, buffering 1x1 placeholder and moving to zombie set. GLError: %@", texID, (errorString ? errorString : @"GL_NONE"));
                    [_dstryTexIDs removeIndex:(NSUInteger)texID];
                    
                    // NOTE: To ensure that we're using as minimal of memory as possible, reflash texture with 1x1 to ensure as limited of memory as possible being wasted
                    pthread_mutex_lock([[self class] apiMutex]);
                    glEnable(GL_TEXTURE_2D);
                    glActiveTexture(GL_TEXTURE0);
                    egw_glClientActiveTexture(GL_TEXTURE0);
                    egw_glBindTexture(GL_TEXTURE0, GL_TEXTURE_2D, (GLuint)texID);
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                    glTexImage2D(GL_TEXTURE_2D,                         // Target
                                 (GLint)0,                              // Mip level
                                 (GLint)GL_LUMINANCE,                   // Internal format
                                 (GLsizei)1,                            // Width (pixels)
                                 (GLsizei)1,                            // Height (pixels)
                                 (GLint)0,                              // Border (pixels) (always 0)
                                 GL_LUMINANCE,                          // Pixel format
                                 GL_UNSIGNED_BYTE,                      // Channel type
                                 (const GLvoid*)&egwSIVecZero4f);       // Raw data buffer
                    egw_glBindTexture(GL_TEXTURE0, GL_TEXTURE_2D, (GLuint)NSNotFound);
                    glDisable(GL_TEXTURE_2D);
                    pthread_mutex_unlock([[self class] apiMutex]);
                    
                    if(egwIsGLError(&errorString))
                        NSLog(@"egwGfxContextAGL: performSubTasks: Failure buffering 1x1 placeholder into texture ID %d, texture memory is now being wasted. GLError: %@", texID, (errorString ? errorString : @"GL_NONE"));
                }
            }
            
            while([_dstryBufIDs count]) {
                NSString* errorString = nil;
                EGWuint bufID = (EGWuint)[_dstryBufIDs firstIndex];
                
                glGetError(); // Clear background errors
                
                if(glIsBuffer((GLuint)bufID)) {
                    glDeleteBuffers((GLsizei)1, (const GLuint*)&bufID);
                    //glFinish();
                }
                
                if(!egwIsGLError(&errorString))
                    [_dstryBufIDs removeIndex:(NSUInteger)bufID];
                else {
                    NSLog(@"egwGfxContextAGL: performSubTasks: Failure deleting buffer ID %d, buffering 1 byte placeholder and moving to zombie set. GLError: %@", bufID, (errorString ? errorString : @"GL_NONE"));
                    [_dstryBufIDs removeIndex:(NSUInteger)bufID];
                    
                    // NOTE: To ensure that we're using as minimal of memory as possible, reflash texture with 1x1 to ensure as limited of memory as possible being wasted
                    pthread_mutex_lock([[self class] apiMutex]);
                    // NOTE: It is safe to dirty bind buffer identifiers at this point because sub task is performed before render loop and only same last base tracking makes calls to egw_glbind not occur. -jw
                    egw_glBindBuffer(GL_ARRAY_BUFFER, (GLuint)bufID);
                    glBufferData(GL_ARRAY_BUFFER, 1, (const GLvoid*)&egwSIVecZero4f, GL_STATIC_DRAW);
                    egw_glBindBuffer(GL_ARRAY_BUFFER, (GLuint)0);
                    egw_glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, (GLuint)bufID);
                    glBufferData(GL_ELEMENT_ARRAY_BUFFER, 1, (const GLvoid*)&egwSIVecZero4f, GL_STATIC_DRAW);
                    egw_glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, (GLuint)0);
                    pthread_mutex_unlock([[self class] apiMutex]);
                    
                    if(egwIsGLError(&errorString))
                        NSLog(@"egwGfxContextAGL: performSubTasks: Failure buffering 1 byte placeholder into buffer ID %d, buffer memory is now being wasted. GLError: %@", bufID, (errorString ? errorString : @"GL_NONE"));
                }
            }
            
            pthread_mutex_unlock(&_iLock);
        }
    }
}

- (void)pushLight:(id<egwPLight>)light withLightJumpTable:(const egwLightJumpTable*)lightJmpT {
    if(_actvLights < _maxLights) {
        if(lightJmpT) {
            EGWuint illumStage = lightJmpT->fpILBStage(light, @selector(lastIlluminationBindingStage));
            BOOL usedHeadLRU = NO;
            
            //NSLog(@"Pushing light %@", [light identity]);
            
            // Try the last binding index first
            if(illumStage != NSNotFound && _lightStages[illumStage].stage.exstBind == light && _lightStages[illumStage].stage.nextBind != light) {
                //NSLog(@"  Last bind index (%d) should be used", [light lastIlluminationBindingStage]);
                
                if(_lightStages[illumStage].stage.nextBind) {
                    // Last spot is taken, better to relist this guy then keep at this spot
                    EGWint relistStage = (EGWint)_lightStages[0].lru.stage; usedHeadLRU = YES;
                    
                    //NSLog(@"  Oops, that spot is already taken, relisting (%d)", relistStage);
                    
                    // Go back to stack and change stage lookup indexing
                    _lightStages[_lightStages[illumStage].stage.nextStack].stack.nextStage = relistStage;
                    _lightStages[relistStage].stage.nextStack = _lightStages[illumStage].stage.nextStack;
                    _lightStages[relistStage].stage.nextBind = _lightStages[illumStage].stage.nextBind; // Already retained
                    _lightStages[relistStage].stage.nextJmpT = _lightStages[illumStage].stage.nextJmpT;
                    
                    illumStage = relistStage;
                }
                // Else last used spot is free (common case)
            } else {
                // Use least recently used index
                illumStage = (EGWuint)_lightStages[0].lru.stage; usedHeadLRU = YES;
                
                //NSLog(@"  Last bind index not used, using LRU (%d)", illumStage);
            }
            
            // Add stage/stack entry
            _lightStages[illumStage].stage.nextStack = _actvLights;
            _lightStages[illumStage].stage.nextBind = lightJmpT->fpRetain(light, @selector(retain));
            _lightStages[illumStage].stage.nextJmpT = lightJmpT;
            _lightStages[_actvLights++].stack.nextStage = illumStage;
            
            // Resort LRU
            if(usedHeadLRU) {
                EGWint headStage = (EGWint)_lightStages[0].lru.stage;
                for(EGWint lruIndex = 0; lruIndex < (_maxLights-1); ++lruIndex)
                    _lightStages[lruIndex].lru.stage = _lightStages[lruIndex+1].lru.stage;
                _lightStages[_maxLights-1].lru.stage = (EGWint8)headStage;
            } else {
                for(EGWint lruIndex = (_maxLights-1); lruIndex >= 0; --lruIndex)
                    if(_lightStages[lruIndex].lru.stage == illumStage) {
                        for(; lruIndex < (_maxLights-1); ++lruIndex)
                            _lightStages[lruIndex].lru.stage = _lightStages[lruIndex+1].lru.stage;
                        _lightStages[_maxLights-1].lru.stage = (EGWint8)illumStage;
                        break;
                    }
            }
            
            /*(NSLog(@"  New light table:");
            for(EGWint lIndex = 0; lIndex < _maxLights; ++lIndex) {
                NSLog(@"  [%d] =", lIndex);
                NSLog(@"    stage:  nextStack(%d), exstBind(%@), nextBind(%@)", _lightStages[lIndex].stage.nextStack, [_lightStages[lIndex].stage.exstBind identity], [_lightStages[lIndex].stage.nextBind identity]);
                NSLog(@"    lru  :  stage(%d)", _lightStages[lIndex].lru.stage);
                NSLog(@"    stack:  exstStage(%d), nextStage(%d)\n", _lightStages[lIndex].stack.exstStage, _lightStages[lIndex].stack.nextStage);
            }*/
        } else {
            NSLog(@"egwGfxContextAGL:withLightJumpTable: pushLight: Failure getting jump table for light '%@'.", light);
        }
    }
}

- (void)popLights:(EGWuint)count {
    //NSLog(@"\n!!popping %d lights!!\n", count);
    
    while(_actvLights && count--) {
        EGWuint illumStage = (EGWuint)_lightStages[--_actvLights].stack.nextStage;
        _lightStages[illumStage].stage.nextStack = -1;
        _lightStages[illumStage].stage.nextJmpT->fpRelease(_lightStages[illumStage].stage.nextBind, @selector(release)); _lightStages[illumStage].stage.nextBind = nil;
        _lightStages[illumStage].stage.nextJmpT = NULL;
        _lightStages[_actvLights].stack.nextStage = -1;
    }
}

- (void)bindLights {
    if(_inPass) {
        if(_actvLights) {
            EGWuint illumStage, flags;
            
            //NSLog(@"\n!!binding lights!!\n");
            
            if(!_lightsEnabled) {
                glEnable(GL_LIGHTING);
                _lightsEnabled = YES;
            }
            
            // NOTE: Go along existing stack first, looking for unbindings that need to occur. This is done
            // separately from doing them both together since the old stack and the new stack have different
            // track lineages, that just tends to lead to more confidence this all works when done separately. -jw
            
            for(EGWuint lightIndex = 0; lightIndex < _maxLights && _lightStages[lightIndex].stack.exstStage != -1; ++lightIndex) {
                illumStage = (EGWuint)_lightStages[lightIndex].stack.exstStage;
                
                // NOTE: If the next bind is nothing, the existing bind sits around with the ISUNBOUND flag
                // set. This is done purposely so that if said light binding comes back, and still has its
                // spot on the light stack, it doesn't need a toggle. This isn't the case if there is next
                // binding (that is still different), which will then require a full release, but no toggle. -jw
                
                if(_lightStages[illumStage].stage.exstBind != _lightStages[illumStage].stage.nextBind) { // If next bind will be different
                    if(_lightStages[illumStage].stage.nextBind) { // There is a next bind, unbind (w/o toggle) and release
                        if(_lightStages[illumStage].stage.exstBind && !(_lightStages[illumStage].stage.flags & EGW_STGFLGS_ISUNBOUND)) // Don't unbind if already unbound
                            _lightStages[illumStage].stage.exstJmpT->fpIUnbind(_lightStages[illumStage].stage.exstBind, @selector(unbindIlluminationWithFlags:), EGW_BNDOBJ_BINDFLG_DFLT);
                        
                        // Make a determination if the next binding is going to have the same base (remember next bind is different), before full release
                        _lightStages[illumStage].stage.flags = EGW_STGFLGS_NONE;
                        if(_lightStages[illumStage].stage.exstBind &&
                           _lightStages[illumStage].stage.exstJmpT->fpLBase(_lightStages[illumStage].stage.exstBind, @selector(lightBase)) ==
                           _lightStages[illumStage].stage.nextJmpT->fpLBase(_lightStages[illumStage].stage.nextBind, @selector(lightBase)))
                            _lightStages[illumStage].stage.flags |= EGW_STGFLGS_SAMELASTBASE;
                        
                        _lightStages[illumStage].stage.exstJmpT->fpRelease(_lightStages[illumStage].stage.exstBind, @selector(release)); _lightStages[illumStage].stage.exstBind = nil;
                    } else { // No next bind, unbind (/w toggle) and keep around
                        _lightStages[illumStage].stage.exstJmpT->fpIUnbind(_lightStages[illumStage].stage.exstBind, @selector(unbindIlluminationWithFlags:), (EGW_BNDOBJ_BINDFLG_DFLT | EGW_BNDOBJ_BINDFLG_TOGGLE));
                        _lightStages[illumStage].stage.flags |= EGW_STGFLGS_ISUNBOUND;
                    }
                } else if(_lightStages[illumStage].stage.exstBind) { // same bind
                    _lightStages[illumStage].stage.flags |= EGW_STGFLGS_SAMELASTBASE;
                }
                
                _lightStages[lightIndex].stack.exstStage = -1; // Clear the stack connection
            }
            
            // NOTE: At this point, the only existant binds that are going to be present are those that
            // don't have a next binding, or those that have the same exact next binding. -jw
            
            for(EGWuint lightIndex = 0; lightIndex < _maxLights && _lightStages[lightIndex].stack.nextStage != -1; ++lightIndex) {
                illumStage = (EGWuint)_lightStages[lightIndex].stack.nextStage;
                
                if(!_lightStages[illumStage].stage.exstBind || (_lightStages[illumStage].stage.flags & (EGW_STGFLGS_ISUNBOUND | EGW_STGFLGS_ISINVALIDATED))) { // If not existant bind or existant bind is unbound or invalidated
                    // Determine bind flags
                    flags = EGW_BNDOBJ_BINDFLG_DFLT;
                    
                    if(_lightStages[illumStage].stage.flags & EGW_STGFLGS_SAMELASTBASE) { // Look for that flag that was set above
                        flags |= EGW_BNDOBJ_BINDFLG_SAMELASTBASE;
                        _lightStages[illumStage].stage.flags &= ~EGW_STGFLGS_SAMELASTBASE;
                    }
                    if(!_lightStages[illumStage].stage.exstBind)
                        flags |= EGW_BNDOBJ_BINDFLG_TOGGLE;
                    else if(_lightStages[illumStage].stage.flags & EGW_STGFLGS_ISINVALIDATED)
                        flags |= EGW_BNDOBJ_BINDFLG_APISYNCINVLD;
                    
                    // Bind with flags
                    _lightStages[illumStage].stage.nextJmpT->fpIBind(_lightStages[illumStage].stage.nextBind, @selector(bindForIlluminationStage:withFlags:), illumStage, flags);
                }
                
                // Reset stage flags
                _lightStages[illumStage].stage.flags = EGW_STGFLGS_NONE;
                
                // Advance next track to existing
                _lightStages[lightIndex].stack.exstStage = _lightStages[lightIndex].stack.nextStage;
                if(!_lightStages[illumStage].stage.exstBind) { // Remember, only nil or exst==next is here, only need a retain on exst if nil
                    if(_lightStages[illumStage].stage.nextBind)
                        _lightStages[illumStage].stage.exstBind = _lightStages[illumStage].stage.nextJmpT->fpRetain(_lightStages[illumStage].stage.nextBind, @selector(retain));
                    else
                        _lightStages[illumStage].stage.exstBind = NULL;
                }
                _lightStages[illumStage].stage.exstJmpT = _lightStages[illumStage].stage.nextJmpT;
            }
        } else {
            if(_lightsEnabled) {
                glDisable(GL_LIGHTING);
                _lightsEnabled = NO;
            }
        }
    }
}

- (void)unbindLights {
    if(_inPass) {
        EGWuint illumStage;
        
        // NOTE: This function does not remove any existing binds, but simply unbinds them
        // for whatever reason. Logic to do switching is only ever handled in binding. -jw
        
        for(EGWint lightIndex = 0; lightIndex < _maxLights && _lightStages[lightIndex].stack.exstStage != -1; ++lightIndex) {
            illumStage = (EGWuint)_lightStages[lightIndex].stack.exstStage;
            
            if(!(_lightStages[illumStage].stage.flags & EGW_STGFLGS_ISUNBOUND)) { // If not unbound, unbind (/w toggle), but leave hanging
                _lightStages[illumStage].stage.exstJmpT->fpIUnbind(_lightStages[illumStage].stage.exstBind, @selector(unbindIlluminationWithFlags:), (EGW_BNDOBJ_BINDFLG_DFLT | EGW_BNDOBJ_BINDFLG_TOGGLE));
                _lightStages[illumStage].stage.flags |= EGW_STGFLGS_ISUNBOUND;
            }
            
            _lightStages[lightIndex].stack.exstStage = -1; // Clear the stack connection
        }
        
        glDisable(GL_LIGHTING);
        _lightsEnabled = NO;
    }
}

- (void)pushMaterial:(id<egwPMaterial>)material withMaterialJumpTable:(const egwMaterialJumpTable*)matJmpT {
    if(_actvMaterials < _maxMaterials) {
        if(matJmpT) {
            _materialStages[_actvMaterials].nextBind = matJmpT->fpRetain(material, @selector(retain));
            _materialStages[_actvMaterials++].nextJmpT = matJmpT;
        } else {
            NSLog(@"egwGfxContextAGL: pushMaterial:withMaterialJumpTable: Failure getting jump table for material '%@'.", material);
        }
    }
}

- (void)popMaterials:(EGWuint)count {
    while(_actvMaterials && count--) {
        --_actvMaterials;
        
        _materialStages[_actvMaterials].nextJmpT->fpRelease(_materialStages[_actvMaterials].nextBind, @selector(release)); _materialStages[_actvMaterials].nextBind = nil;
        _materialStages[_actvMaterials].nextJmpT = NULL;
    }
}

- (void)bindMaterials {
    if(_inPass) {
        if(_actvMaterials) {
            EGWuint flags;
            
            if(!_materialsEnabled) {
                glDisable(GL_COLOR_MATERIAL);
                _materialsEnabled = YES;
            }
            
            for(EGWuint surfacingStage = 0; surfacingStage < _maxMaterials; ++surfacingStage) {
                if(_materialStages[surfacingStage].exstBind || _materialStages[surfacingStage].nextBind) {
                    // Unbind and bind next if different
                    if(_materialStages[surfacingStage].exstBind != _materialStages[surfacingStage].nextBind) { // different binds
                        if(_materialStages[surfacingStage].exstBind)
                            _materialStages[surfacingStage].exstJmpT->fpSUnbind(_materialStages[surfacingStage].exstBind, @selector(unbindSurfacingWithFlags:), (EGW_BNDOBJ_BINDFLG_DFLT | (_materialStages[surfacingStage].nextBind ? 0 : EGW_BNDOBJ_BINDFLG_TOGGLE)));
                        
                        if(_materialStages[surfacingStage].nextBind) {
                            // Determine bind flags
                            flags = EGW_BNDOBJ_BINDFLG_DFLT;
                            
                            if(_materialStages[surfacingStage].exstBind) {
                                if(_materialStages[surfacingStage].exstJmpT->fpMBase(_materialStages[surfacingStage].exstBind, @selector(materialBase)) ==
                                   _materialStages[surfacingStage].nextJmpT->fpMBase(_materialStages[surfacingStage].nextBind, @selector(materialBase)))
                                    flags |= EGW_BNDOBJ_BINDFLG_SAMELASTBASE;
                            } else
                                flags |= EGW_BNDOBJ_BINDFLG_TOGGLE;
                            
                            _materialStages[surfacingStage].nextJmpT->fpSBind(_materialStages[surfacingStage].nextBind, @selector(bindForSurfacingStage:withFlags:), surfacingStage, flags);
                        }
                    } else if(_materialStages[surfacingStage].exstBind) { // same bind as last
                        if(_materialStages[surfacingStage].flags & EGW_STGFLGS_ISINVALIDATED)
                            _materialStages[surfacingStage].exstJmpT->fpSBind(_materialStages[surfacingStage].exstBind, @selector(bindForSurfacingStage:withFlags:), surfacingStage, (EGW_BNDOBJ_BINDFLG_DFLT | EGW_BNDOBJ_BINDFLG_SAMELASTBASE | EGW_BNDOBJ_BINDFLG_APISYNCINVLD));
                    }
                    
                    // Advance next to the existing
                    _materialStages[surfacingStage].flags = EGW_STGFLGS_NONE;
                    if(_materialStages[surfacingStage].exstBind)
                        _materialStages[surfacingStage].exstJmpT->fpRelease(_materialStages[surfacingStage].exstBind, @selector(release));
                    if(_materialStages[surfacingStage].nextBind)
                        _materialStages[surfacingStage].exstBind = _materialStages[surfacingStage].nextJmpT->fpRetain(_materialStages[surfacingStage].nextBind, @selector(retain));
                    else
                        _materialStages[surfacingStage].exstBind = NULL;
                    _materialStages[surfacingStage].exstJmpT = _materialStages[surfacingStage].nextJmpT;
                } else break;
            }
        } else {
            if(_materialsEnabled) {
                glEnable(GL_COLOR_MATERIAL);
                _materialsEnabled = NO;
            }
        }
    }
}

- (void)unbindMaterials {
    if(_inPass) {
        for(EGWint surfacingStage = 0; surfacingStage < _maxMaterials; ++surfacingStage) {
            // Unbind remaining
            if(_materialStages[surfacingStage].exstBind) {
                [_materialStages[surfacingStage].exstBind unbindSurfacingWithFlags:(EGW_BNDOBJ_BINDFLG_DFLT | EGW_BNDOBJ_BINDFLG_TOGGLE)];
                _materialStages[surfacingStage].exstJmpT->fpRelease(_materialStages[surfacingStage].exstBind, @selector(release)); _materialStages[surfacingStage].exstBind = nil;
                _materialStages[surfacingStage].exstJmpT = NULL;
            }
        }
        
        glEnable(GL_COLOR_MATERIAL);
        _materialsEnabled = NO;
    }
}

- (void)pushShader:(id<egwPShader>)shader withShaderJumpTable:(const egwShaderJumpTable*)shdrJmpT {
    // TODO: me.
}

- (void)popShaders:(EGWuint)count {
    // TODO: me.
}

- (void)bindShaders {
    // TODO: me.
}

- (void)unbindShaders {
    // TODO: me.
}

- (void)pushTexture:(id<egwPTexture>)texture withTextureJumpTable:(const egwTextureJumpTable*)txtrJmpT {
    if(_actvTextures < _maxTextures) {
        if(txtrJmpT) {
            _textureStages[_actvTextures].nextBind = txtrJmpT->fpRetain(texture, @selector(retain));
            _textureStages[_actvTextures++].nextJmpT = txtrJmpT;
        } else {
            NSLog(@"egwGfxContextAGL: pushTexture: Failure getting jump table for texture '%@'.", texture);
        }
    }
}

- (void)popTextures:(EGWuint)count {
    while(_actvTextures && count--) {
        --_actvTextures;
        
        _textureStages[_actvTextures].nextJmpT->fpRelease(_textureStages[_actvTextures].nextBind, @selector(release)); _textureStages[_actvTextures].nextBind = nil;
        _textureStages[_actvTextures].nextJmpT = NULL;
    }
}

- (void)bindTextures {
    if(_inPass) {
        if(_actvTextures) {
            EGWuint flags;
            
            if(!_texturesEnabled) {
                glEnable(GL_TEXTURE_2D);
                glEnableClientState(GL_TEXTURE_COORD_ARRAY);
                _texturesEnabled = YES;
            }
            
            for(EGWuint texturingStage = 0; texturingStage < _maxTextures; ++texturingStage) {
                if(_textureStages[texturingStage].exstBind || _textureStages[texturingStage].nextBind) {
                    // Unbind and bind next if different
                    if(_textureStages[texturingStage].exstBind != _textureStages[texturingStage].nextBind) { // different binds
                        if(_textureStages[texturingStage].exstBind)
                            _textureStages[texturingStage].exstJmpT->fpTUnbind(_textureStages[texturingStage].exstBind, @selector(unbindTexturingWithFlags:), (EGW_BNDOBJ_BINDFLG_DFLT | (_textureStages[texturingStage].nextBind ? 0 : EGW_BNDOBJ_BINDFLG_TOGGLE)));
                        
                        if(_textureStages[texturingStage].nextBind) {
                            // Determine bind flags
                            flags = EGW_BNDOBJ_BINDFLG_DFLT;
                            
                            if(_textureStages[texturingStage].exstBind) {
                                if(_textureStages[texturingStage].exstJmpT->fpTBase(_textureStages[texturingStage].exstBind, @selector(textureBase)) ==
                                   _textureStages[texturingStage].nextJmpT->fpTBase(_textureStages[texturingStage].nextBind, @selector(textureBase)))
                                    flags |= EGW_BNDOBJ_BINDFLG_SAMELASTBASE;
                            } else
                                flags |= EGW_BNDOBJ_BINDFLG_TOGGLE;
                            
                            _textureStages[texturingStage].nextJmpT->fpTBind(_textureStages[texturingStage].nextBind, @selector(bindForTexturingStage:withFlags:), texturingStage, flags);
                        }
                    } else if(_textureStages[texturingStage].exstBind) { // same bind as last
                        if(_textureStages[texturingStage].flags & EGW_STGFLGS_ISINVALIDATED)
                            _textureStages[texturingStage].exstJmpT->fpTBind(_textureStages[texturingStage].exstBind, @selector(bindForTexturingStage:withFlags:), texturingStage, (EGW_BNDOBJ_BINDFLG_DFLT | EGW_BNDOBJ_BINDFLG_SAMELASTBASE | EGW_BNDOBJ_BINDFLG_APISYNCINVLD));
                    }
                    
                    // Advance next to the existing
                    _textureStages[texturingStage].flags = EGW_STGFLGS_NONE;
                    if(_textureStages[texturingStage].exstBind)
                        _textureStages[texturingStage].exstJmpT->fpRelease(_textureStages[texturingStage].exstBind, @selector(release));
                    if(_textureStages[texturingStage].nextBind)
                        _textureStages[texturingStage].exstBind = _textureStages[texturingStage].nextJmpT->fpRetain(_textureStages[texturingStage].nextBind, @selector(retain));
                    else
                        _textureStages[texturingStage].exstBind = NULL;
                    _textureStages[texturingStage].exstJmpT = _textureStages[texturingStage].nextJmpT;
                } else break;
            }
        } else {
            if(_texturesEnabled) {
                glDisable(GL_TEXTURE_2D);
                glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                _texturesEnabled = NO;
            }
        }
    }
}

- (void)unbindTextures {
    if(_inPass) {
        for(EGWint texturingStage = 0; texturingStage < _maxTextures; ++texturingStage) {
            // Unbind remaining
            if(_textureStages[texturingStage].exstBind) {
                [_textureStages[texturingStage].exstBind unbindTexturingWithFlags:(EGW_BNDOBJ_BINDFLG_DFLT | EGW_BNDOBJ_BINDFLG_TOGGLE)];
                _textureStages[texturingStage].exstJmpT->fpRelease(_textureStages[texturingStage].exstBind, @selector(release)); _textureStages[texturingStage].exstBind = nil;
                _textureStages[texturingStage].exstJmpT = NULL;
            }
        }
        
        glDisable(GL_TEXTURE_2D);
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        _texturesEnabled = NO;
    }
}

- (void)reportDirtyLightBindForIlluminationStage:(EGWuint)illumStage {
    if(_lightStages[illumStage].stage.exstBind)
        _lightStages[illumStage].stage.flags |= EGW_STGFLGS_ISINVALIDATED;
}

- (void)reportDirtyMaterialBindForSurfacingStage:(EGWuint)srfcgStage {
    if(_materialStages[srfcgStage].exstBind)
        _materialStages[srfcgStage].flags |= EGW_STGFLGS_ISINVALIDATED;
}

- (void)reportDirtyShaderBindForShadingStage:(EGWuint)shdngStage {
    if(_shaderStages[shdngStage].exstBind)
        _shaderStages[shdngStage].flags |= EGW_STGFLGS_ISINVALIDATED;
}

- (void)reportDirtyTextureBindForTexturingStage:(EGWuint)txtrStage {
    if(_textureStages[txtrStage].exstBind)
        _textureStages[txtrStage].flags |= EGW_STGFLGS_ISINVALIDATED;
}

- (EGWuint)requestFreeTextureID {
    EGWuint textureID = NSNotFound;
    
    @synchronized(self) {
        if([_availTexIDs count]) {
            textureID = [_availTexIDs lastIndex];
            [_availTexIDs removeIndex:textureID];
            [_usedTexIDs addIndex:textureID];
        } else {
            if([self isActive]) {
                NSString* errorString = nil;
                GLuint textureIDs[EGW_GFXCONTEXT_TXTRGENCNT];
                
                glGetError(); // Clear background errors
                
                glGenTextures(EGW_GFXCONTEXT_TXTRGENCNT, &textureIDs[0]);
                
                if(!egwIsGLError(&errorString)) {
                    // Can't be certain here that the textureIDs are consecutive
                    for(EGWint i = EGW_GFXCONTEXT_TXTRGENCNT - 1; i > 0; --i)
                        [_availTexIDs addIndex:(EGWuint)textureIDs[i]];
                    textureID = (EGWuint)textureIDs[0];
                    [_usedTexIDs addIndex:textureID];
                } else {
                    NSLog(@"egwGfxContextAGL: requestFreeTextureID: Failure generating new textures. GLError: %@", errorString);
                }
            } else {
                NSLog(@"egwGfxContextAGL: requestFreeTextureID: Failure generating new textures. Context is not active [on this thread].");
            }
        }
    }
    
    return textureID;
}

- (EGWuint)returnUsedTextureID:(EGWuint)textureID {
    @synchronized(self) {
        if(textureID && textureID != NSNotFound) {  // Textures should be deleted rather than re-used
            // Move to destroy list for delayed removal
            [_usedTexIDs removeIndex:(NSUInteger)textureID];
            
            pthread_mutex_lock(&_iLock);
            [_dstryTexIDs addIndex:(NSUInteger)textureID];
            pthread_mutex_unlock(&_iLock);
        }
    }
    
    return NSNotFound;
}

- (EGWuint)requestFreeBufferID {
    EGWuint bufferID = 0;
    
    @synchronized(self) {
        if([_availBufIDs count]) {
            bufferID = [_availBufIDs lastIndex];
            [_availBufIDs removeIndex:bufferID];
            [_usedBufIDs addIndex:bufferID];
        } else {
            if([self isActive]) {
                NSString* errorString = nil;
                GLuint bufferIDs[EGW_GFXCONTEXT_BFFRGENCNT];
                
                glGetError(); // Clear background errors
                
                glGenBuffers(EGW_GFXCONTEXT_BFFRGENCNT, &bufferIDs[0]);
                
                if(!egwIsGLError(&errorString)) {
                    // Can't be certain here that the bufferIDs are consecutive
                    for(EGWint i = EGW_GFXCONTEXT_BFFRGENCNT - 1; i > 0; --i)
                        [_availBufIDs addIndex:(EGWuint)bufferIDs[i]];
                    bufferID = (EGWuint)bufferIDs[0];
                    [_usedBufIDs addIndex:bufferID];
                } else {
                    NSLog(@"egwGfxContextAGL: requestFreeBufferID: Failure generating new buffers. GLError: %@", errorString);
                }
            } else {
                NSLog(@"egwGfxContextAGL: requestFreeBufferID: Failure generating new buffers. Context is not active [on this thread].");
            }
        }
    }
    
    return bufferID;
}

- (EGWuint)returnUsedBufferID:(EGWuint)bufferID {
    @synchronized(self) {
        if(bufferID) {  // Buffers should be deleted rather than re-used
            // Move to destroy list for delayed removal
            [_usedBufIDs removeIndex:(NSUInteger)bufferID];
            
            pthread_mutex_lock(&_iLock);
            [_dstryBufIDs addIndex:(NSUInteger)bufferID];
            pthread_mutex_unlock(&_iLock);
        }
    }
    
    return NSNotFound;
}

- (void)shutDownContext { // Entrant from derived classes only, already locked
    [super shutDownContext];
    
    // Destroy lights
    if(_lightStages) {
        for(EGWint illumStage = 0; illumStage < _maxLights; ++illumStage) {
            if(_lightStages[illumStage].stage.exstBind && [_lightStages[illumStage].stage.exstBind isBoundForIllumination])
                [_lightStages[illumStage].stage.exstBind unbindIlluminationWithFlags:(EGW_BNDOBJ_BINDFLG_DFLT | EGW_BNDOBJ_BINDFLG_TOGGLE)];
            if(_lightStages[illumStage].stage.exstBind) {
                _lightStages[illumStage].stage.exstJmpT->fpRelease(_lightStages[illumStage].stage.exstBind, @selector(release)); _lightStages[illumStage].stage.exstBind = nil;
            }
            if(_lightStages[illumStage].stage.nextBind) {
                _lightStages[illumStage].stage.nextJmpT->fpRelease(_lightStages[illumStage].stage.nextBind, @selector(release)); _lightStages[illumStage].stage.nextBind = nil;
            }
        }
        free((void*)_lightStages); _lightStages = NULL;
    }
    
    // Destroy materials
    if(_materialStages) {
        for(EGWint surfacingStage = 0; surfacingStage < _maxMaterials; ++surfacingStage) {
            if(_materialStages[surfacingStage].exstBind && [_materialStages[surfacingStage].exstBind isBoundForSurfacing])
                [_materialStages[surfacingStage].exstBind unbindSurfacingWithFlags:(EGW_BNDOBJ_BINDFLG_DFLT | EGW_BNDOBJ_BINDFLG_TOGGLE)];
            if(_materialStages[surfacingStage].exstBind) {
                _materialStages[surfacingStage].exstJmpT->fpRelease(_materialStages[surfacingStage].exstBind, @selector(release)); _materialStages[surfacingStage].exstBind = nil;
            }
            if(_materialStages[surfacingStage].nextBind) {
                _materialStages[surfacingStage].nextJmpT->fpRelease(_materialStages[surfacingStage].nextBind, @selector(release)); _materialStages[surfacingStage].nextBind = nil;
            }
        }
        free((void*)_materialStages); _materialStages = NULL;
    }
    
    // Destroy shaders
    if(_shaderStages) {
        for(EGWint shadingStage = 0; shadingStage < _maxShaders; ++shadingStage) {
            if(_shaderStages[shadingStage].exstBind && [_shaderStages[shadingStage].exstBind isBoundForShading])
                [_shaderStages[shadingStage].exstBind unbindShadingWithFlags:(EGW_BNDOBJ_BINDFLG_DFLT | EGW_BNDOBJ_BINDFLG_TOGGLE)];
            if(_shaderStages[shadingStage].exstBind) {
                _shaderStages[shadingStage].exstJmpT->fpRelease(_shaderStages[shadingStage].exstBind, @selector(release)); _shaderStages[shadingStage].exstBind = nil;
            }
            if(_shaderStages[shadingStage].nextBind) {
                _shaderStages[shadingStage].nextJmpT->fpRelease(_shaderStages[shadingStage].nextBind, @selector(release)); _shaderStages[shadingStage].nextBind = nil;
            }
        }
        free((void*)_textureStages); _textureStages = NULL;
    }
    
    // Destroy textures
    if(_textureStages) {
        for(EGWint texturingStage = 0; texturingStage < _maxTextures; ++texturingStage) {
            if(_textureStages[texturingStage].exstBind && [_textureStages[texturingStage].exstBind isBoundForTexturing])
                [_textureStages[texturingStage].exstBind unbindTexturingWithFlags:(EGW_BNDOBJ_BINDFLG_DFLT | EGW_BNDOBJ_BINDFLG_TOGGLE)];
            if(_textureStages[texturingStage].exstBind) {
                _textureStages[texturingStage].exstJmpT->fpRelease(_textureStages[texturingStage].exstBind, @selector(release)); _textureStages[texturingStage].exstBind = nil;
            }
            if(_textureStages[texturingStage].nextBind) {
                _textureStages[texturingStage].nextJmpT->fpRelease(_textureStages[texturingStage].nextBind, @selector(release)); _textureStages[texturingStage].nextBind = nil;
            }
        }
        free((void*)_textureStages); _textureStages = NULL;
    }
    if(_dstryTexIDs) {
        EGWuint texturesCount = [_dstryTexIDs count];
        if(texturesCount) {
            EGWuint* textureIDs = (EGWuint*)malloc(texturesCount * sizeof(EGWuint));
            texturesCount = [_dstryTexIDs getIndexes:textureIDs maxCount:texturesCount inIndexRange: nil];
            glDeleteTextures((GLsizei)texturesCount, (const GLuint*)textureIDs);
            free((void*)textureIDs);
        }
        [_dstryTexIDs release]; _dstryTexIDs = nil;
    }
    if(_usedTexIDs) {
        EGWuint texturesCount = [_usedTexIDs count];
        if(texturesCount) {
            EGWuint* textureIDs = (EGWuint*)malloc(texturesCount * sizeof(EGWuint));
            texturesCount = [_usedTexIDs getIndexes:textureIDs maxCount:texturesCount inIndexRange: nil];
            glDeleteTextures((GLsizei)texturesCount, (const GLuint*)textureIDs);
            free((void*)textureIDs);
        }
        [_usedTexIDs release]; _usedTexIDs = nil;
    }
    if(_availTexIDs) {
        EGWuint texturesCount = [_availTexIDs count];
        if(texturesCount) {
            EGWuint* textureIDs = (EGWuint*)malloc(texturesCount * sizeof(EGWuint));
            texturesCount = [_availTexIDs getIndexes:textureIDs maxCount:texturesCount inIndexRange: nil];
            glDeleteTextures((GLsizei)texturesCount, (const GLuint*)textureIDs);
            free((void*)textureIDs);
        }
        [_availTexIDs release]; _availTexIDs = nil;
    }
    
    // Destroy buffers
    if(_dstryBufIDs) {
        EGWuint buffersCount = [_dstryBufIDs count];
        if(buffersCount) {
            EGWuint* bufferIDs = (EGWuint*)malloc(buffersCount * sizeof(EGWuint));
            buffersCount = [_dstryBufIDs getIndexes:bufferIDs maxCount:buffersCount inIndexRange: nil];
            glDeleteBuffers((GLsizei)buffersCount, (const GLuint*)bufferIDs);
            free((void*)bufferIDs);
        }
        [_dstryBufIDs release]; _dstryBufIDs = nil;
    }
    if(_usedBufIDs) {
        EGWuint buffersCount = [_usedBufIDs count];
        if(buffersCount) {
            EGWuint* bufferIDs = (EGWuint*)malloc(buffersCount * sizeof(EGWuint));
            buffersCount = [_usedBufIDs getIndexes:bufferIDs maxCount:buffersCount inIndexRange: nil];
            glDeleteBuffers((GLsizei)buffersCount, (const GLuint*)bufferIDs);
            free((void*)bufferIDs);
        }
        [_usedBufIDs release]; _usedBufIDs = nil;
    }
    if(_availBufIDs) {
        EGWuint buffersCount = [_availBufIDs count];
        if(buffersCount) {
            EGWuint* bufferIDs = (EGWuint*)malloc(buffersCount * sizeof(EGWuint));
            buffersCount = [_availBufIDs getIndexes:bufferIDs maxCount:buffersCount inIndexRange: nil];
            glDeleteBuffers((GLsizei)buffersCount, (const GLuint*)bufferIDs);
            free((void*)bufferIDs);
        }
        [_availBufIDs release]; _availBufIDs = nil;
    }
}

- (BOOL)isActive {
    return ((egwAIGfxCntx == self && _thread == egwSFPNSThreadCurrentThread(nil, @selector(currentThread))) ? YES : NO);
}

- (BOOL)isExtAvailable:(NSString*)extName {
    if([_extensions containsObject:extName])
        return YES;
    return NO;
}

@end


@implementation egwGfxContextAGL (TextureLoading)

- (BOOL)loadTextureID:(EGWuint*)textureID withSurface:(egwSurface*)surface texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter texturingSWrap:(EGWuint16)sWrap texturingTWrap:(EGWuint16)tWrap {
    NSString* errorString = nil;
    BOOL apiLocked = NO;
    BOOL genID = NO;
    EGWuint oldTextureID = NSNotFound;
    GLenum format, type;
    EGWbyte aMask;
    EGWint aMult, aOff, Bpp, mSize;
    
    glGetError(); // Clear background errors
    
    if(!textureID || !surface || !surface->data) {
        NSLog(@"egwGfxContextAGL: loadTextureID:withSurface:texturingTransforms:texturingFilter:texturingSWrap:texturingTWrap: Invalid arguments passed to method.");
        goto ErrorCleanup;
    }
    
    if(surface->format & EGW_SURFACE_FRMT_EXCMPRSD) {
        if((surface->format & EGW_SURFACE_FRMT_EXPVRTC) && ![self isExtAvailable:@"GL_IMG_texture_compression_pvrtc"]) {
            NSLog(@"egwGfxContextAGL: loadTextureID:withSurface:texturingTransforms:texturingFilter:texturingSWrap:texturingTWrap: PVRTC texture compression not supported.");
            goto ErrorCleanup;
        }
        
        if((filter & EGW_TEXTURE_FLTR_EXMIPPED) && !(surface->format & EGW_SURFACE_FRMT_PGENMIPS)) {
            NSLog(@"egwGfxContextAGL: loadTextureID:withSurface:texturingTransforms:texturingFilter:texturingSWrap:texturingTWrap: Cannot generate MIPs on-the-fly for compressed textures.");
            goto ErrorCleanup;
        }
    }
    
    if(![self makeActiveAndLocked]) {
        NSLog(@"egwGfxContextAGL: loadTextureID:withSurface:texturingTransforms:texturingFilter:texturingSWrap:texturingTWrap: Failure making graphics context active [on this thread] to buffer in texture data.");
        goto ErrorCleanup;
    }
    
    apiLocked = YES;
    
    if(!_texturesEnabled) {
        glEnable(GL_TEXTURE_2D);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        _texturesEnabled = YES;
    }
    
    if(*textureID == 0 || *textureID == NSNotFound) {
        if((*textureID = [self requestFreeTextureID]) == NSNotFound) {
            NSLog(@"egwGfxContextAGL: loadTextureID:withSurface:texturingTransforms:texturingFilter:texturingSWrap:texturingTWrap: Failure requesting free texture ID.");
            goto ErrorCleanup;
        }
        
        genID = YES;
    }
    
    glActiveTexture(GL_TEXTURE0);
    egw_glClientActiveTexture(GL_TEXTURE0);
    glGetIntegerv(GL_TEXTURE_BINDING_2D, (GLint*)&oldTextureID);
    egw_glBindTexture(GL_TEXTURE0, GL_TEXTURE_2D, (GLuint)*textureID);
    //glFinish();
    if(egwIsGLError(&errorString)) {
        NSLog(@"egwGfxContextAGL: loadTextureID:withSurface:texturingTransforms:texturingFilter:texturingSWrap:texturingTWrap: Failure binding texture data buffer. GLError: %@", errorString);
        goto ErrorCleanup;
    }
    
    if(filter & EGW_TEXTURE_FLTR_DFLTNMIP)
        filter = (_dfltFilter & EGW_TEXTURE_FLTR_EXNMIPPED);
    else if(filter & EGW_TEXTURE_FLTR_DFLTMIP)
        filter = (_dfltFilter & EGW_TEXTURE_FLTR_EXMIPPED);
    
    switch(filter) {
        default:
        case EGW_TEXTURE_FLTR_NEAREST: {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        } break;
        case EGW_TEXTURE_FLTR_LINEAR: {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        } break;
        case EGW_TEXTURE_FLTR_UNILINEAR: {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        } break;
        case EGW_TEXTURE_FLTR_BILINEAR:
        case EGW_TEXTURE_FLTR_BLHANSTRPC:
        case EGW_TEXTURE_FLTR_BLFANSTRPC: {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        } break;
        case EGW_TEXTURE_FLTR_TRILINEAR:
        case EGW_TEXTURE_FLTR_TLHANSTRPC:
        case EGW_TEXTURE_FLTR_TLFANSTRPC: {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        } break;
    }
    if(egwIsGLError(&errorString)) {
        NSLog(@"egwGfxContextAGL: loadTextureID:withSurface:texturingTransforms:texturingFilter:texturingSWrap:texturingTWrap: Failure setting up filtering for texture data buffer. GLError: %@", errorString);
        goto ErrorCleanup;
    }
    
    // Handle anisotropic options
    if(filter & EGW_TEXTURE_FLTR_EXANSTRPC) {
        switch(filter) {
            default: {
            } break;
                
            case EGW_TEXTURE_FLTR_BLHANSTRPC:
            case EGW_TEXTURE_FLTR_TLHANSTRPC: {
                if([self isExtAvailable:@"GL_EXT_texture_filter_anisotropic"]) {
                    GLfloat value = 0.0f;
                    glGetFloatv(0x84FF, &value); // GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT
                    if(egwIsGLError(&errorString)) {
                        NSLog(@"egwGfxContextAGL: loadTextureID:withSurface:texturingTransforms:texturingFilter:texturingSWrap:texturingTWrap: Failure retrieving max anistropic filtering amount. GLError: %@", errorString);
                        goto ErrorCleanup;
                    } else value *= 0.5f;
                    glTexParameterf(GL_TEXTURE_2D, 0x84FE, value); // GL_TEXTURE_MAX_ANISOTROPY_EXT
                    if(egwIsGLError(&errorString)) {
                        NSLog(@"egwGfxContextAGL: loadTextureID:withSurface:texturingTransforms:texturingFilter:texturingSWrap:texturingTWrap: Failure setting up anisotropic (%f) filtering for texture data buffer. GLError: %@", value, errorString);
                        goto ErrorCleanup;
                    }
                } else {
                    NSLog(@"egwGfxContextAGL: loadTextureID:withSurface:texturingTransforms:texturingFilter:texturingSWrap:texturingTWrap: Failure setting up filtering for texture data buffer. GL_EXT_texture_filter_anisotropic not supported.");
                    goto ErrorCleanup;
                }
            } break;
                
            case EGW_TEXTURE_FLTR_BLFANSTRPC:
            case EGW_TEXTURE_FLTR_TLFANSTRPC: {
                if([self isExtAvailable:@"GL_EXT_texture_filter_anisotropic"]) {
                    GLfloat value = 0.0f;
                    glGetFloatv(0x84FF, &value); // GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT
                    if(egwIsGLError(&errorString)) {
                        NSLog(@"egwGfxContextAGL: loadTextureID:withSurface:texturingTransforms:texturingFilter:texturingSWrap:texturingTWrap: Failure retrieving max anistropic filtering amount. GLError: %@", errorString);
                        goto ErrorCleanup;
                    }
                    glTexParameterf(GL_TEXTURE_2D, 0x84FE, value); // GL_TEXTURE_MAX_ANISOTROPY_EXT
                    if(egwIsGLError(&errorString)) {
                        NSLog(@"egwGfxContextAGL: loadTextureID:withSurface:texturingTransforms:texturingFilter:texturingSWrap:texturingTWrap: Failure setting up anisotropic (%f) filtering for texture data buffer. GLError: %@", value, errorString);
                        goto ErrorCleanup;
                    }
                } else {
                    NSLog(@"egwGfxContextAGL: loadTextureID:withSurface:texturingTransforms:texturingFilter:texturingSWrap:texturingTWrap: Failure setting up filtering for texture data buffer. GL_EXT_texture_filter_anisotropic not supported.");
                    goto ErrorCleanup;
                }
            } break;
        }
    }
    
    switch(sWrap) {
        default:
        case EGW_TEXTURE_WRAP_CLAMP: {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        } break;
        case EGW_TEXTURE_WRAP_REPEAT: {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
        } break;
        case EGW_TEXTURE_WRAP_MRRDREPEAT: {
            if([self isExtAvailable:@"GL_OES_texture_mirrored_repeat"]) {
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, 0x8370); // GL_MIRRORED_REPEAT_OES
            } else {
                NSLog(@"egwGfxContextAGL: loadTextureID:withSurface:texturingTransforms:texturingFilter:texturingSWrap:texturingTWrap: Failure setting up s-wrapping for texture data buffer. GL_OES_texture_mirrored_repeat not supported.");
                goto ErrorCleanup;
            }
        } break;
    }
    if(egwIsGLError(&errorString)) {
        NSLog(@"egwGfxContextAGL: loadTextureID:withSurface:texturingTransforms:texturingFilter:texturingSWrap:texturingTWrap: Failure setting up s-wrapping for texture data buffer. GLError: %@", errorString);
        goto ErrorCleanup;
    }
    
    switch(tWrap) {
        default:
        case EGW_TEXTURE_WRAP_CLAMP: {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        } break;
        case EGW_TEXTURE_WRAP_REPEAT: {
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        } break;
        case EGW_TEXTURE_WRAP_MRRDREPEAT: {
            if([self isExtAvailable:@"GL_OES_texture_mirrored_repeat"]) {
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, 0x8370); // GL_MIRRORED_REPEAT_OES
            } else {
                NSLog(@"egwGfxContextAGL: loadTextureID:withSurface:texturingTransforms:texturingFilter:texturingSWrap:texturingTWrap: Failure setting up t-wrapping for texture data buffer. GL_OES_texture_mirrored_repeat not supported.");
                goto ErrorCleanup;
            }
        } break;
    }
    if(egwIsGLError(&errorString)) {
        NSLog(@"egwGfxContextAGL: loadTextureID:withSurface:texturingTransforms:texturingFilter:texturingSWrap:texturingTWrap: Failure setting up t-wrapping for texture data buffer. GLError: %@", errorString);
        goto ErrorCleanup;
    }
    
    {   EGWint packingB = egwSrfcPacking(surface);
        glPixelStorei(GL_UNPACK_ALIGNMENT, (GLint)packingB);
        if(egwIsGLError(&errorString)) {
            NSLog(@"egwGfxContextAGL: loadTextureID:withSurface:texturingTransforms:texturingFilter:texturingSWrap:texturingTWrap: Failure setting up unpack alignment (%d) for texture data buffer. GLError: %@", packingB, errorString);
            goto ErrorCleanup;
        }
    }
    
    switch(surface->format & EGW_SURFACE_FRMT_EXKIND) {
        // NOTE: All surface interactions must work flawlessly with these surface types.
        case EGW_SURFACE_FRMT_GS8: { format = GL_LUMINANCE; type = GL_UNSIGNED_BYTE; aMask = 0x00; aMult = 0; aOff = 0; Bpp = 1; mSize = 0; } break;
        case EGW_SURFACE_FRMT_GS8A8: { format = GL_LUMINANCE_ALPHA; type = GL_UNSIGNED_BYTE; aMask = 0xff; aMult = 1; aOff = 1; Bpp = 2; mSize = 0; } break;
        case EGW_SURFACE_FRMT_R5G6B5: { format = GL_RGB; type = GL_UNSIGNED_SHORT_5_6_5; aMask = 0x00; aMult = 0; aOff = 0; Bpp = 2; mSize = 0; } break;
        case EGW_SURFACE_FRMT_R5G5B5A1: { format = GL_RGBA; type = GL_UNSIGNED_SHORT_5_5_5_1; aMask = 0x01; aMult = 255; aOff = 0; Bpp = 2; mSize = 0; } break;
        case EGW_SURFACE_FRMT_R4G4B4A4: { format = GL_RGBA; type = GL_UNSIGNED_SHORT_4_4_4_4; aMask = 0x0f; aMult = 17; aOff = 0; Bpp = 2; mSize = 0; } break;
        case EGW_SURFACE_FRMT_R8G8B8: { format = GL_RGB; type = GL_UNSIGNED_BYTE; aMask = 0x00; aMult = 0; aOff = 0; Bpp = 3; mSize = 0; } break;
        case EGW_SURFACE_FRMT_R8G8B8A8: { format = GL_RGBA; type = GL_UNSIGNED_BYTE; aMask = 0xff; aMult = 1; aOff = 3; Bpp = 4; mSize = 0; } break;
        case EGW_SURFACE_FRMT_PVRTCRGB2: { format = 0x8C01; aMask = 0x00; aMult = 0; aOff = 0; Bpp = 0; mSize = 32; } break; // GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG
        case EGW_SURFACE_FRMT_PVRTCRGBA2: { format = 0x8C03; aMask = 0x00; aMult = 0; aOff = 0; Bpp = 0; mSize = 32; } break; // GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG
        case EGW_SURFACE_FRMT_PVRTCRGB4: { format = 0x8C00; aMask = 0x00; aMult = 0; aOff = 0; Bpp = 0; mSize = 32; } break; // GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG
        case EGW_SURFACE_FRMT_PVRTCRGBA4: { format = 0x8C02; aMask = 0x00; aMult = 0; aOff = 0; Bpp = 0; mSize = 32; } break; // GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG
        default: {
            NSLog(@"egwGfxContextAGL: loadTextureID:withSurface:texturingTransforms:texturingFilter:texturingSWrap:texturingTWrap: Unrecognized or unsupported surface format.");
            goto ErrorCleanup;
        } break;
    }
    
    // Buffering data & mip creation switch
    if(filter == 0 ||
       !(filter & EGW_TEXTURE_FLTR_EXMIPPED)) {
        
        if((surface->format & EGW_SURFACE_FRMT_EXCMPRSD)) {
            glCompressedTexImage2D(GL_TEXTURE_2D,                           // Target
                                   (GLint)0,                                // Mip level
                                   (GLint)format,                           // Internal format
                                   (GLsizei)(surface->size.span.width),     // Width (pixels)
                                   (GLsizei)(surface->size.span.height),    // Height (pixels)
                                   (GLint)0,                                // Border (pixels) (always 0)
                                   (GLsizei)egwMax2i(mSize, (EGWint)(surface->pitch) * (EGWint)(surface->size.span.height)), // Image size
                                   (const GLvoid*)(surface->data));         // Raw data buffer
        } else {
            glTexImage2D(GL_TEXTURE_2D,                         // Target
                         (GLint)0,                              // Mip level
                         (GLint)format,                         // Internal format
                         (GLsizei)(surface->size.span.width),   // Width (pixels)
                         (GLsizei)(surface->size.span.height),  // Height (pixels)
                         (GLint)0,                              // Border (pixels) (always 0)
                         format,                                // Pixel format
                         type,                                  // Channel type
                         (const GLvoid*)(surface->data));       // Raw data buffer
        }
        
        if(egwIsGLError(&errorString)) {
            NSLog(@"egwGfxContextAGL: loadTextureID:withSurface:texturingTransforms:texturingFilter:texturingSWrap:texturingTWrap: Failure buffering surface data into hardware buffer. GLError: %@", errorString);
            goto ErrorCleanup;
        }
    } else {
        EGWuint row, col;
        EGWbyte* cAdr = NULL;
        EGWbyte* lAdr = NULL;
        EGWint dirCount = 0;
        EGWuintptr cScanline = 0, lScanline = 0, trfmOffset = 0;
        EGWuint16 lWidth = surface->size.span.width, lHeight = surface->size.span.height, lPitch = surface->pitch;
        GLint level = 0;
        
        do {
            if((surface->format & EGW_SURFACE_FRMT_EXCMPRSD)) {
                glCompressedTexImage2D(GL_TEXTURE_2D,                           // Target
                                       level,                                   // Mip level
                                       (GLint)format,                           // Internal format
                                       (GLsizei)(surface->size.span.width),     // Width (pixels)
                                       (GLsizei)(surface->size.span.height),    // Height (pixels)
                                       (GLint)0,                                // Border (pixels) (always 0)
                                       (GLsizei)egwMax2i(mSize, (EGWint)(surface->pitch) * (EGWint)(surface->size.span.height)), // Image size
                                       (const GLvoid*)((EGWuintptr)(surface->data) + trfmOffset)); // Raw data buffer (offset by post-ops)
            } else {
                glTexImage2D(GL_TEXTURE_2D,                         // Target
                             level,                                 // Mip level
                             (GLint)format,                         // Internal format
                             (GLsizei)(surface->size.span.width),   // Width (pixels)
                             (GLsizei)(surface->size.span.height),  // Height (pixels)
                             (GLint)0,                              // Border (pixels) (always 0)
                             format,                                // Pixel format
                             type,                                  // Channel type
                             (const GLvoid*)((EGWuintptr)(surface->data) + trfmOffset)); // Raw data buffer (offset by post-ops)
            }
            
            if(egwIsGLError(&errorString)) {
                NSLog(@"egwGfxContextAGL: loadTextureID:withSurface:texturingTransforms:texturingFilter:texturingSWrap:texturingTWrap: Failure buffering texture data mip level %d (%dx%d) into hardware buffer. GLError: %@", level, surface->size.span.width, surface->size.span.height, errorString);
                goto ErrorCleanup;
            }
            
            // Resize by half
            lWidth = surface->size.span.width; surface->size.span.width >>= 1;
            if(surface->size.span.width < 1)
                surface->size.span.width = 1;
            else {
                lPitch = surface->pitch; surface->pitch >>= 1;
            }
            
            lHeight = surface->size.span.height; surface->size.span.height >>= 1;
            if(surface->size.span.height < 1)
                surface->size.span.height = 1;
            
            if((surface->format & EGW_SURFACE_FRMT_PGENMIPS)) {
                // Mips prior generated
                trfmOffset += (EGWuintptr)egwMax2i(mSize, (EGWint)lPitch * (EGWint)lHeight);
            } else {
                // Generate mip
                if(lWidth > 1 || lHeight > 1) {
                    dirCount = (1 + (lWidth > 1 ? 1 : 0) + (lHeight > 1 ? 1 : 0) + (lWidth > 1 && lHeight > 1 ? 1 : 0));
                    cScanline = lScanline = (EGWuintptr)(surface->data);
                    
                    switch(surface->format & EGW_SURFACE_FRMT_EXKIND) {
                        case EGW_SURFACE_FRMT_GS8: {
                            egwColorGS cColor; EGWint iColor[1];
                            
                            for(row = 0; row < (EGWuint)(surface->size.span.height); ++row) {
                                cAdr = (EGWbyte*)cScanline;
                                lAdr = (EGWbyte*)lScanline;
                                
                                for(col = 0; col < (EGWuint)(surface->size.span.width); ++col) {
                                    egwPxlReadGSb(surface->format, (EGWbyte*)((EGWuintptr)lAdr), &cColor);
                                    iColor[0] = (EGWint)cColor.channel.l;
                                    if(lWidth > 1) {
                                        egwPxlReadGSb(surface->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)Bpp), &cColor);
                                        iColor[0] += (EGWint)cColor.channel.l;
                                    }
                                    if(lHeight > 1) {
                                        egwPxlReadGSb(surface->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)lPitch), &cColor);
                                        iColor[0] += (EGWint)cColor.channel.l;
                                    }
                                    if(lWidth > 1 && lHeight > 1) {
                                        egwPxlReadGSb(surface->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)lPitch + (EGWuintptr)Bpp), &cColor);
                                        iColor[0] += (EGWint)cColor.channel.l;
                                    }
                                    
                                    cColor.channel.l = (EGWbyte)egwClamp0255i(iColor[0] / dirCount);
                                    egwPxlWriteGSb(surface->format, &cColor, (EGWbyte*)cAdr);
                                    
                                    cAdr = (EGWbyte*)((EGWuintptr)cAdr + (EGWuintptr)Bpp);
                                    lAdr = (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)(Bpp << 1));
                                }
                                
                                cScanline += (EGWuintptr)surface->pitch;
                                lScanline += ((EGWuintptr)lPitch + (EGWuintptr)lPitch);
                            }
                        } break;
                            
                        case EGW_SURFACE_FRMT_GS8A8: {
                            egwColorGSA cColor; EGWint iColor[2];
                            
                            for(row = 0; row < (EGWuint)(surface->size.span.height); ++row) {
                                cAdr = (EGWbyte*)cScanline;
                                lAdr = (EGWbyte*)lScanline;
                                
                                for(col = 0; col < (EGWuint)(surface->size.span.width); ++col) {
                                    egwPxlReadGSAb(surface->format, (EGWbyte*)((EGWuintptr)lAdr), &cColor);
                                    iColor[0] = ((EGWint)cColor.channel.l * (EGWint)cColor.channel.a);
                                    iColor[1] = (EGWint)cColor.channel.a;
                                    if(lWidth > 1) {
                                        egwPxlReadGSAb(surface->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)Bpp), &cColor);
                                        iColor[0] += ((EGWint)cColor.channel.l * (EGWint)cColor.channel.a);
                                        iColor[1] += (EGWint)cColor.channel.a;
                                    }
                                    if(lHeight > 1) {
                                        egwPxlReadGSAb(surface->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)lPitch), &cColor);
                                        iColor[0] += ((EGWint)cColor.channel.l * (EGWint)cColor.channel.a);
                                        iColor[1] += (EGWint)cColor.channel.a;
                                    }
                                    if(lWidth > 1 && lHeight > 1) {
                                        egwPxlReadGSAb(surface->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)lPitch + (EGWuintptr)Bpp), &cColor);
                                        iColor[0] += ((EGWint)cColor.channel.l * (EGWint)cColor.channel.a);
                                        iColor[1] += (EGWint)cColor.channel.a;
                                    }
                                    
                                    cColor.channel.l = (EGWbyte)(iColor[1] ? egwClamp0255i(iColor[0] / iColor[1]) : 0);
                                    cColor.channel.a = (EGWbyte)egwClamp0255i(iColor[1] / dirCount);
                                    egwPxlWriteGSAb(surface->format, &cColor, (EGWbyte*)cAdr);
                                    
                                    cAdr = (EGWbyte*)((EGWuintptr)cAdr + (EGWuintptr)Bpp);
                                    lAdr = (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)(Bpp << 1));
                                }
                                
                                cScanline += (EGWuintptr)surface->pitch;
                                lScanline += ((EGWuintptr)lPitch + (EGWuintptr)lPitch);
                            }
                        } break;
                            
                        case EGW_SURFACE_FRMT_R5G6B5:
                        case EGW_SURFACE_FRMT_R8G8B8: {
                            egwColorRGB cColor; EGWint iColor[3];
                            
                            for(row = 0; row < (EGWuint)(surface->size.span.height); ++row) {
                                cAdr = (EGWbyte*)cScanline;
                                lAdr = (EGWbyte*)lScanline;
                                
                                for(col = 0; col < (EGWuint)(surface->size.span.width); ++col) {
                                    egwPxlReadRGBb(surface->format, (EGWbyte*)((EGWuintptr)lAdr), &cColor);
                                    iColor[0] = (EGWint)cColor.channel.r;
                                    iColor[1] = (EGWint)cColor.channel.g;
                                    iColor[2] = (EGWint)cColor.channel.b;
                                    if(lWidth > 1) {
                                        egwPxlReadRGBb(surface->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)Bpp), &cColor);
                                        iColor[0] += (EGWint)cColor.channel.r;
                                        iColor[1] += (EGWint)cColor.channel.g;
                                        iColor[2] += (EGWint)cColor.channel.b;
                                    }
                                    if(lHeight > 1) {
                                        egwPxlReadRGBb(surface->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)lPitch), &cColor);
                                        iColor[0] += (EGWint)cColor.channel.r;
                                        iColor[1] += (EGWint)cColor.channel.g;
                                        iColor[2] += (EGWint)cColor.channel.b;
                                    }
                                    if(lWidth > 1 && lHeight > 1) {
                                        egwPxlReadRGBb(surface->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)lPitch + (EGWuintptr)Bpp), &cColor);
                                        iColor[0] += (EGWint)cColor.channel.r;
                                        iColor[1] += (EGWint)cColor.channel.g;
                                        iColor[2] += (EGWint)cColor.channel.b;
                                    }
                                    
                                    cColor.channel.r = (EGWbyte)egwClamp0255i(iColor[0] / dirCount);
                                    cColor.channel.g = (EGWbyte)egwClamp0255i(iColor[1] / dirCount);
                                    cColor.channel.b = (EGWbyte)egwClamp0255i(iColor[2] / dirCount);
                                    egwPxlWriteRGBb(surface->format, &cColor, (EGWbyte*)cAdr);
                                    
                                    cAdr = (EGWbyte*)((EGWuintptr)cAdr + (EGWuintptr)Bpp);
                                    lAdr = (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)(Bpp << 1));
                                }
                                
                                cScanline += (EGWuintptr)surface->pitch;
                                lScanline += ((EGWuintptr)lPitch + (EGWuintptr)lPitch);
                            }
                        } break;
                            
                        case EGW_SURFACE_FRMT_R5G5B5A1:
                        case EGW_SURFACE_FRMT_R4G4B4A4:
                        case EGW_SURFACE_FRMT_R8G8B8A8: {
                            egwColorRGBA cColor; EGWint iColor[4];
                            
                            for(row = 0; row < (EGWuint)(surface->size.span.height); ++row) {
                                cAdr = (EGWbyte*)cScanline;
                                lAdr = (EGWbyte*)lScanline;
                                
                                for(col = 0; col < (EGWuint)(surface->size.span.width); ++col) {
                                    egwPxlReadRGBAb(surface->format, (EGWbyte*)((EGWuintptr)lAdr), &cColor);
                                    iColor[0] = ((EGWint)cColor.channel.r * (EGWint)cColor.channel.a);
                                    iColor[1] = ((EGWint)cColor.channel.g * (EGWint)cColor.channel.a);
                                    iColor[2] = ((EGWint)cColor.channel.b * (EGWint)cColor.channel.a);
                                    iColor[3] = (EGWint)cColor.channel.a;
                                    if(lWidth > 1) {
                                        egwPxlReadRGBAb(surface->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)Bpp), &cColor);
                                        iColor[0] += ((EGWint)cColor.channel.r * (EGWint)cColor.channel.a);
                                        iColor[1] += ((EGWint)cColor.channel.g * (EGWint)cColor.channel.a);
                                        iColor[2] += ((EGWint)cColor.channel.b * (EGWint)cColor.channel.a);
                                        iColor[3] += (EGWint)cColor.channel.a;
                                    }
                                    if(lHeight > 1) {
                                        egwPxlReadRGBAb(surface->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)lPitch), &cColor);
                                        iColor[0] += ((EGWint)cColor.channel.r * (EGWint)cColor.channel.a);
                                        iColor[1] += ((EGWint)cColor.channel.g * (EGWint)cColor.channel.a);
                                        iColor[2] += ((EGWint)cColor.channel.b * (EGWint)cColor.channel.a);
                                        iColor[3] += (EGWint)cColor.channel.a;
                                    }
                                    if(lWidth > 1 && lHeight > 1) {
                                        egwPxlReadRGBAb(surface->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)lPitch + (EGWuintptr)Bpp), &cColor);
                                        iColor[0] += ((EGWint)cColor.channel.r * (EGWint)cColor.channel.a);
                                        iColor[1] += ((EGWint)cColor.channel.g * (EGWint)cColor.channel.a);
                                        iColor[2] += ((EGWint)cColor.channel.b * (EGWint)cColor.channel.a);
                                        iColor[3] += (EGWint)cColor.channel.a;
                                    }
                                    
                                    cColor.channel.r = (EGWbyte)(iColor[3] ? egwClamp0255i(iColor[0] / iColor[3]) : 0);
                                    cColor.channel.g = (EGWbyte)(iColor[3] ? egwClamp0255i(iColor[1] / iColor[3]) : 0);
                                    cColor.channel.b = (EGWbyte)(iColor[3] ? egwClamp0255i(iColor[2] / iColor[3]) : 0);
                                    cColor.channel.a = (EGWbyte)egwClamp0255i(iColor[3] / dirCount);
                                    egwPxlWriteRGBAb(surface->format, &cColor, (EGWbyte*)cAdr);
                                    
                                    cAdr = (EGWbyte*)((EGWuintptr)cAdr + (EGWuintptr)Bpp);
                                    lAdr = (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)(Bpp << 1));
                                }
                                
                                cScanline += (EGWuintptr)surface->pitch;
                                lScanline += ((EGWuintptr)lPitch + (EGWuintptr)lPitch);
                            }
                        } break;
                    }
                    
                    // Sharpen post-op
                    if(transforms & EGW_TEXTURE_TRFM_EXSHARPEN) {
                        // EGW_TEXTURE_TRFM_SHARPEN [0 -1  0, -1  5 -1,  0 -1  0]
                        EGWint factor = 255, invFactor = 0;
                        lScanline = (EGWuintptr)(surface->data);
                        cScanline = ((EGWuintptr)(surface->data) + ((EGWuintptr)(surface->pitch) * (EGWuintptr)(surface->size.span.height)));
                        trfmOffset = cScanline - lScanline;
                        
                        switch(transforms & EGW_TEXTURE_TRFM_EXSHARPEN) {
                            case EGW_TEXTURE_TRFM_SHARPEN25: { factor = 64; } break;
                            case EGW_TEXTURE_TRFM_SHARPEN33: { factor = 84; } break;
                            case EGW_TEXTURE_TRFM_SHARPEN50: { factor = 128; } break;
                            case EGW_TEXTURE_TRFM_SHARPEN66: { factor = 168; } break;
                            case EGW_TEXTURE_TRFM_SHARPEN75: { factor = 191; } break;
                        }
                        invFactor = 255 - factor;
                        
                        switch(surface->format & EGW_SURFACE_FRMT_EXKIND) {
                            case EGW_SURFACE_FRMT_GS8:
                            case EGW_SURFACE_FRMT_GS8A8: {
                                egwColorGSA cColor; EGWint iColor[1];
                                
                                for(row = 0; row < (EGWint)(surface->size.span.height); ++row) {
                                    cAdr = (EGWbyte*)cScanline;
                                    lAdr = (EGWbyte*)lScanline;
                                    
                                    for(col = 0; col < (EGWint)(surface->size.span.width); ++col) {
                                        dirCount = 0; iColor[0] = 0;
                                        
                                        if(col > 0) {
                                            egwPxlReadGSb(surface->format, (EGWbyte*)((EGWuintptr)lAdr - (EGWuintptr)Bpp), (egwColorGS*)&cColor);
                                            iColor[0] -= (EGWint)cColor.channel.l;
                                            ++dirCount;
                                        }
                                        if(col < (EGWuint)(surface->size.span.width)-1) {
                                            egwPxlReadGSb(surface->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)Bpp), (egwColorGS*)&cColor);
                                            iColor[0] -= (EGWint)cColor.channel.l;
                                            ++dirCount;
                                        }
                                        if(row > 0) {
                                            egwPxlReadGSb(surface->format, (EGWbyte*)((EGWuintptr)lAdr - (EGWuintptr)surface->pitch), (egwColorGS*)&cColor);
                                            iColor[0] -= (EGWint)cColor.channel.l;
                                            ++dirCount;
                                        }
                                        if(row < (EGWuint)(surface->size.span.height)-1) {
                                            egwPxlReadGSb(surface->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)surface->pitch), (egwColorGS*)&cColor);
                                            iColor[0] -= (EGWint)cColor.channel.l;
                                            ++dirCount;
                                        }
                                        egwPxlReadGSAb(surface->format, (EGWbyte*)lAdr, &cColor);
                                        iColor[0] += ++dirCount * (EGWint)cColor.channel.l;
                                        
                                        cColor.channel.l = (EGWbyte)egwClamp0255i(((egwClamp0255i(iColor[0]) * factor) + ((EGWint)cColor.channel.l * invFactor)) / 255);
                                        egwPxlWriteGSAb(surface->format, &cColor, (EGWbyte*)cAdr);
                                        
                                        cAdr = (EGWbyte*)((EGWuintptr)cAdr + (EGWuintptr)Bpp);
                                        lAdr = (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)Bpp);
                                    }
                                    
                                    cScanline += (EGWuintptr)surface->pitch;
                                    lScanline += (EGWuintptr)surface->pitch;
                                }
                            } break;
                                
                            case EGW_SURFACE_FRMT_R5G6B5:
                            case EGW_SURFACE_FRMT_R8G8B8:
                            case EGW_SURFACE_FRMT_R5G5B5A1:
                            case EGW_SURFACE_FRMT_R4G4B4A4:
                            case EGW_SURFACE_FRMT_R8G8B8A8: {
                                egwColorRGBA cColor; EGWint iColor[3];
                                
                                for(row = 0; row < (EGWint)(surface->size.span.height); ++row) {
                                    cAdr = (EGWbyte*)cScanline;
                                    lAdr = (EGWbyte*)lScanline;
                                    
                                    for(col = 0; col < (EGWint)(surface->size.span.width); ++col) {
                                        dirCount = 0; iColor[0] = iColor[1] = iColor[2] = 0;
                                        
                                        if(col > 0) {
                                            egwPxlReadRGBb(surface->format, (EGWbyte*)((EGWuintptr)lAdr - (EGWuintptr)Bpp), (egwColorRGB*)&cColor);
                                            iColor[0] -= (EGWint)cColor.channel.r;
                                            iColor[1] -= (EGWint)cColor.channel.g;
                                            iColor[2] -= (EGWint)cColor.channel.b;
                                            ++dirCount;
                                        }
                                        if(col < (EGWuint)(surface->size.span.width)-1) {
                                            egwPxlReadRGBb(surface->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)Bpp), (egwColorRGB*)&cColor);
                                            iColor[0] -= (EGWint)cColor.channel.r;
                                            iColor[1] -= (EGWint)cColor.channel.g;
                                            iColor[2] -= (EGWint)cColor.channel.b;
                                            ++dirCount;
                                        }
                                        if(row > 0) {
                                            egwPxlReadRGBb(surface->format, (EGWbyte*)((EGWuintptr)lAdr - (EGWuintptr)surface->pitch), (egwColorRGB*)&cColor);
                                            iColor[0] -= (EGWint)cColor.channel.r;
                                            iColor[1] -= (EGWint)cColor.channel.g;
                                            iColor[2] -= (EGWint)cColor.channel.b;
                                            ++dirCount;
                                        }
                                        if(row < (EGWuint)(surface->size.span.height)-1) {
                                            egwPxlReadRGBb(surface->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)surface->pitch), (egwColorRGB*)&cColor);
                                            iColor[0] -= (EGWint)cColor.channel.r;
                                            iColor[1] -= (EGWint)cColor.channel.g;
                                            iColor[2] -= (EGWint)cColor.channel.b;
                                            ++dirCount;
                                        }
                                        egwPxlReadRGBAb(surface->format, (EGWbyte*)lAdr, &cColor);
                                        iColor[0] += ++dirCount * (EGWint)cColor.channel.r;
                                        iColor[1] += dirCount * (EGWint)cColor.channel.g;
                                        iColor[2] += dirCount * (EGWint)cColor.channel.b;
                                        
                                        cColor.channel.r = (EGWbyte)egwClamp0255i(((egwClamp0255i(iColor[0]) * factor) + ((EGWint)cColor.channel.r * invFactor)) / 255);
                                        cColor.channel.g = (EGWbyte)egwClamp0255i(((egwClamp0255i(iColor[1]) * factor) + ((EGWint)cColor.channel.g * invFactor)) / 255);
                                        cColor.channel.b = (EGWbyte)egwClamp0255i(((egwClamp0255i(iColor[2]) * factor) + ((EGWint)cColor.channel.b * invFactor)) / 255);
                                        egwPxlWriteRGBAb(surface->format, &cColor, (EGWbyte*)cAdr);
                                        
                                        cAdr = (EGWbyte*)((EGWuintptr)cAdr + (EGWuintptr)Bpp);
                                        lAdr = (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)Bpp);
                                    }
                                    
                                    cScanline += (EGWuintptr)surface->pitch;
                                    lScanline += (EGWuintptr)surface->pitch;
                                }
                            } break;
                        }
                    }
                }
            }
            
            ++level;
        } while(lWidth > 1 || lHeight > 1);
    }
    
    // Transfer complete, close it up.
    
    if(apiLocked) {
        if(oldTextureID != NSNotFound) {
            egw_glBindTexture(GL_TEXTURE0, GL_TEXTURE_2D, (GLuint)oldTextureID); oldTextureID = NSNotFound;
            //glFinish();
        }
        
        if(!_actvTextures && _texturesEnabled) {
            glDisable(GL_TEXTURE_2D);
            glDisableClientState(GL_TEXTURE_COORD_ARRAY);
            _texturesEnabled = NO;
        }
        
        apiLocked = NO;
        pthread_mutex_unlock([[self class] apiMutex]);
    }
    
    return YES;
    
ErrorCleanup:
    if(apiLocked) {
        if(oldTextureID != NSNotFound) {
            egw_glBindTexture(GL_TEXTURE0, GL_TEXTURE_2D, (GLuint)oldTextureID); oldTextureID = NSNotFound;
            //glFinish();
        }
        
        if(genID)
            *textureID = [self returnUsedTextureID:*textureID];
        
        if(!_actvTextures && _texturesEnabled) {
            glDisable(GL_TEXTURE_2D);
            glDisableClientState(GL_TEXTURE_COORD_ARRAY);
            _texturesEnabled = NO;
        }
        
        apiLocked = NO;
        pthread_mutex_unlock([[self class] apiMutex]);
    }
    
    return NO;
}

- (void)setDefaultTexturingFilter:(EGWuint)filter {
    if(filter & EGW_TEXTURE_FLTR_EXNMIPPED)
        _dfltFilter = (_dfltFilter & ~EGW_TEXTURE_FLTR_EXNMIPPED) | (filter & EGW_TEXTURE_FLTR_EXNMIPPED);
    if(filter & EGW_TEXTURE_FLTR_EXMIPPED)
        _dfltFilter = (_dfltFilter & ~EGW_TEXTURE_FLTR_EXMIPPED) | (filter & EGW_TEXTURE_FLTR_EXMIPPED);
}

@end


@implementation egwGfxContextAGL (BufferLoading)

- (BOOL)loadBufferArraysID:(EGWuint*)arraysBufID withSTVAMesh:(const egwSTVAMeshf*)mesh geometryStorage:(EGWuint)storage {
    BOOL success = NO;
    BOOL apiLocked = NO;
    BOOL isAllocatingArrays = NO;
    
    glGetError(); // Clear background errors
    
    if(!arraysBufID || !mesh || !mesh->vCoords || !mesh->nCoords) {
        NSLog(@"egwGfxContextAGL: loadBufferArraysID:withSTVAMesh:geometryStorage: Invalid arguments passed to method.");
        goto ErrorCleanup;
    }
    
    if([egwAIGfxCntxAGL isActive] || [egwAIGfxCntxAGL makeActive]) {
        NSString* errorString = nil;
        GLenum usage = 0;
        
        // NOTE: It is safe to dirty bind buffer identifiers at this point because sub task is performed before render loop and only same last base tracking makes calls to egw_glbind not occur. -jw
        
        switch(storage & EGW_GEOMETRY_STRG_EXVBO) {
            case EGW_GEOMETRY_STRG_VBOSTATIC: { usage = GL_STATIC_DRAW; } break;
            case EGW_GEOMETRY_STRG_VBODYNAMIC: { usage = GL_DYNAMIC_DRAW; } break;
            default: {
                NSLog(@"egwGfxContextAGL: loadBufferArraysID:withSTVAMesh:geometryStorage: Invalid geometry VBO storage setting '%p'.", storage);
                goto ErrorCleanup;
            }
        }
        
        pthread_mutex_lock([[egwAIGfxCntxAGL class] apiMutex]); apiLocked = YES;
        
        if(!(*arraysBufID)) {
            isAllocatingArrays = YES;
            *arraysBufID = [egwAIGfxCntxAGL requestFreeBufferID];
            if(!(*arraysBufID)) {
                NSLog(@"egwGfxContextAGL: loadBufferArraysID:withSTVAMesh:geometryStorage: Failure getting new buffer ID for arrays buffer.");
                goto ErrorCleanup;
            }
        }
        
        egw_glBindBuffer(GL_ARRAY_BUFFER, *arraysBufID);
        if(isAllocatingArrays)
            glBufferData(GL_ARRAY_BUFFER, (GLsizeiptr)((mesh->vCoords ? (EGWuint)sizeof(egwVector3f) * (EGWuint)mesh->vCount : (EGWuint)0) +
                                                       (mesh->nCoords ? (EGWuint)sizeof(egwVector3f) * (EGWuint)mesh->vCount : (EGWuint)0) +
                                                       (mesh->tCoords ? (EGWuint)sizeof(egwVector2f) * (EGWuint)mesh->vCount : (EGWuint)0)), NULL, usage);
        
        EGWuintptr offset = 0;
        if(mesh->vCoords) {
            glBufferSubData(GL_ARRAY_BUFFER, (GLintptr)offset, (GLsizeiptr)((EGWuint)sizeof(egwVector3f) * (EGWuint)mesh->vCount), (const GLvoid*)mesh->vCoords);
            offset += (EGWuintptr)((EGWuint)sizeof(egwVector3f) * (EGWuint)mesh->vCount);
        }
        if(mesh->nCoords) {
            glBufferSubData(GL_ARRAY_BUFFER, (GLintptr)offset, (GLsizeiptr)((EGWuint)sizeof(egwVector3f) * (EGWuint)mesh->vCount), (const GLvoid*)mesh->nCoords);
            offset += (EGWuintptr)((EGWuint)sizeof(egwVector3f) * (EGWuint)mesh->vCount);
        }
        if(mesh->tCoords) {
            glBufferSubData(GL_ARRAY_BUFFER, (GLintptr)offset, (GLsizeiptr)((EGWuint)sizeof(egwVector2f) * (EGWuint)mesh->vCount), (const GLvoid*)mesh->tCoords);
            //offset += (EGWuintptr)((EGWuint)sizeof(egwVector2f) * (EGWuint)mesh->vCount);
        }
        
        if(egwIsGLError(&errorString)) {
            NSLog(@"egwGfxContextAGL: loadBufferArraysID:withSTVAMesh:geometryStorage: Failure buffering mesh data into buffer ID %d. GLError: %@", *arraysBufID, (errorString ? errorString : @"GL_NONE"));
            goto ErrorCleanup;
        }
        
        success = YES;
        goto Cleanup;
    } else {
        NSLog(@"egwGfxContextAGL: loadBufferArraysID:withSTVAMesh:geometryStorage: Failure making context active on this thread.");
    }
    
ErrorCleanup:
    if(*arraysBufID)
        *arraysBufID = [egwAIGfxCntxAGL returnUsedBufferID:*arraysBufID];
Cleanup:
    if(apiLocked) {
        pthread_mutex_unlock([[egwAIGfxCntxAGL class] apiMutex]); apiLocked = NO;
    }
    
    return success;
}

- (BOOL)loadBufferArraysID:(EGWuint*)arraysBufID bufferElementsID:(EGWuint*)elementsBufID withSJITVAMesh:(const egwSJITVAMeshf*)mesh geometryStorage:(EGWuint)storage {
    BOOL success = NO;
    BOOL apiLocked = NO;
    BOOL isAllocatingArrays = NO;
    BOOL isAllocatingElements = NO;
    
    glGetError(); // Clear background errors
    
    if(!arraysBufID || !elementsBufID || !mesh || !mesh->vCoords || !mesh->nCoords || !mesh->fIndicies) {
        NSLog(@"egwGfxContextAGL: loadBufferArraysID:bufferElementsID:withSJITVAMesh:geometryStorage: Invalid arguments passed to method.");
        goto ErrorCleanup;
    }
    
    if([egwAIGfxCntxAGL isActive] || [egwAIGfxCntxAGL makeActive]) {
        NSString* errorString = nil;
        GLenum usage = 0;
        
        // NOTE: It is safe to dirty bind buffer identifiers at this point because sub task is performed before render loop and only same last base tracking makes calls to egw_glbind not occur. -jw
        
        switch(storage & EGW_GEOMETRY_STRG_EXVBO) {
            case EGW_GEOMETRY_STRG_VBOSTATIC: { usage = GL_STATIC_DRAW; } break;
            case EGW_GEOMETRY_STRG_VBODYNAMIC: { usage = GL_DYNAMIC_DRAW; } break;
            default: {
                NSLog(@"egwGfxContextAGL: loadBufferArraysID:bufferElementsID:withSJITVAMesh:geometryStorage: Invalid geometry VBO storage setting '%p'.", storage);
                goto ErrorCleanup;
            }
        }
        
        pthread_mutex_lock([[egwAIGfxCntxAGL class] apiMutex]); apiLocked = YES;
        
        if(!(*arraysBufID)) {
            isAllocatingArrays = YES;
            *arraysBufID = [egwAIGfxCntxAGL requestFreeBufferID];
            if(!(*arraysBufID)) {
                NSLog(@"egwGfxContextAGL: loadBufferArraysID:bufferElementsID:withSJITVAMesh:geometryStorage: Failure getting new buffer ID for arrays buffer.");
                goto ErrorCleanup;
            }
        }
        if(!(*elementsBufID)) {
            isAllocatingElements = YES;
            *elementsBufID = [egwAIGfxCntxAGL requestFreeBufferID];
            if(!(*elementsBufID)) {
                NSLog(@"egwGfxContextAGL: loadBufferArraysID:bufferElementsID:withSJITVAMesh:geometryStorage: Failure getting new buffer ID for array elements buffer.");
                goto ErrorCleanup;
            }
        }
        
        egw_glBindBuffer(GL_ARRAY_BUFFER, *arraysBufID);
        if(isAllocatingArrays)
            glBufferData(GL_ARRAY_BUFFER, (GLsizeiptr)((mesh->vCoords ? (EGWuint)sizeof(egwVector3f) * (EGWuint)mesh->vCount : (EGWuint)0) +
                                                       (mesh->nCoords ? (EGWuint)sizeof(egwVector3f) * (EGWuint)mesh->vCount : (EGWuint)0) +
                                                       (mesh->tCoords ? (EGWuint)sizeof(egwVector2f) * (EGWuint)mesh->vCount : (EGWuint)0)), NULL, usage);
        
        EGWuintptr offset = 0;
        if(mesh->vCoords) {
            glBufferSubData(GL_ARRAY_BUFFER, (GLintptr)offset, (GLsizeiptr)((EGWuint)sizeof(egwVector3f) * (EGWuint)mesh->vCount), (const GLvoid*)mesh->vCoords);
            offset += (EGWuintptr)((EGWuint)sizeof(egwVector3f) * (EGWuint)mesh->vCount);
        }
        if(mesh->nCoords) {
            glBufferSubData(GL_ARRAY_BUFFER, (GLintptr)offset, (GLsizeiptr)((EGWuint)sizeof(egwVector3f) * (EGWuint)mesh->vCount), (const GLvoid*)mesh->nCoords);
            offset += (EGWuintptr)((EGWuint)sizeof(egwVector3f) * (EGWuint)mesh->vCount);
        }
        if(mesh->tCoords) {
            glBufferSubData(GL_ARRAY_BUFFER, (GLintptr)offset, (GLsizeiptr)((EGWuint)sizeof(egwVector2f) * (EGWuint)mesh->vCount), (const GLvoid*)mesh->tCoords);
            //offset += (EGWuintptr)((EGWuint)sizeof(egwVector2f) * (EGWuint)mesh->vCount);
        }
        
        egw_glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, *elementsBufID);
        if(isAllocatingElements)
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, (GLsizeiptr)((EGWuint)sizeof(egwJITFace) * (EGWuint)mesh->fCount), (const GLvoid*)mesh->fIndicies, usage);
        
        if(egwIsGLError(&errorString)) {
            NSLog(@"egwGfxContextAGL: loadBufferArraysID:bufferElementsID:withSJITVAMesh:geometryStorage: Failure buffering mesh data into buffer ID %d/%d. GLError: %@", *arraysBufID, *elementsBufID, (errorString ? errorString : @"GL_NONE"));
            goto ErrorCleanup;
        }
        
        success = YES;
        goto Cleanup;
    } else {
        NSLog(@"egwGfxContextAGL: loadBufferArraysID:bufferElementsID:withSJITVAMesh:geometryStorage: Failure making context active on this thread.");
    }
    
ErrorCleanup:
    if(*arraysBufID)
        *arraysBufID = [egwAIGfxCntxAGL returnUsedBufferID:*arraysBufID];
    if(*elementsBufID)
        *elementsBufID = [egwAIGfxCntxAGL returnUsedBufferID:*elementsBufID];
Cleanup:
    if(apiLocked) {
        pthread_mutex_unlock([[egwAIGfxCntxAGL class] apiMutex]); apiLocked = NO;
    }
    
    return success;
}

- (BOOL)loadBufferArraysID:(EGWuint*)arraysBufID withSQVAMesh:(const egwSQVAMesh4f*)mesh geometryStorage:(EGWuint)storage {
    BOOL success = NO;
    BOOL apiLocked = NO;
    BOOL isAllocatingArrays = NO;
    
    glGetError(); // Clear background errors
    
    if(!arraysBufID || !mesh) {
        NSLog(@"egwGfxContextAGL: loadBufferArraysID:withSQVAMesh:geometryStorage: Invalid arguments passed to method.");
        goto ErrorCleanup;
    }
    
    if([egwAIGfxCntxAGL isActive] || [egwAIGfxCntxAGL makeActive]) {
        NSString* errorString = nil;
        GLenum usage = 0;
        
        // NOTE: It is safe to dirty bind buffer identifiers at this point because sub task is performed before render loop and only same last base tracking makes calls to egw_glbind not occur. -jw
        
        switch(storage & EGW_GEOMETRY_STRG_EXVBO) {
            case EGW_GEOMETRY_STRG_VBOSTATIC: { usage = GL_STATIC_DRAW; } break;
            case EGW_GEOMETRY_STRG_VBODYNAMIC: { usage = GL_DYNAMIC_DRAW; } break;
            default: {
                NSLog(@"egwGfxContextAGL: loadBufferArraysID:withSQVAMesh:geometryStorage: Invalid geometry VBO storage setting '%p'.", storage);
                goto ErrorCleanup;
            }
        }
        
        pthread_mutex_lock([[egwAIGfxCntxAGL class] apiMutex]); apiLocked = YES;
        
        if(!(*arraysBufID)) {
            isAllocatingArrays = YES;
            *arraysBufID = [egwAIGfxCntxAGL requestFreeBufferID];
            if(!(*arraysBufID)) {
                NSLog(@"egwGfxContextAGL: loadBufferArraysID:withSQVAMesh:geometryStorage: Failure getting new buffer ID for arrays buffer.");
                goto ErrorCleanup;
            }
        }
        
        egw_glBindBuffer(GL_ARRAY_BUFFER, *arraysBufID);
        if(isAllocatingArrays)
            glBufferData(GL_ARRAY_BUFFER, (GLsizeiptr)sizeof(egwSQVAMesh4f), NULL, usage);
        
        EGWuintptr offset = 0;
        
        glBufferSubData(GL_ARRAY_BUFFER, (GLintptr)offset, (GLsizeiptr)((EGWuint)sizeof(egwVector3f) * 4), (const GLvoid*)&mesh->vCoords[0]);
        offset += (EGWuintptr)((EGWuint)sizeof(egwVector3f) * 4);
        
        glBufferSubData(GL_ARRAY_BUFFER, (GLintptr)offset, (GLsizeiptr)((EGWuint)sizeof(egwVector3f) * 4), (const GLvoid*)&mesh->nCoords[0]);
        offset += (EGWuintptr)((EGWuint)sizeof(egwVector3f) * 4);
        
        glBufferSubData(GL_ARRAY_BUFFER, (GLintptr)offset, (GLsizeiptr)((EGWuint)sizeof(egwVector2f) * 4), (const GLvoid*)&mesh->tCoords[0]);
        //offset += (EGWuintptr)((EGWuint)sizeof(egwVector2f) * 4);
        
        if(egwIsGLError(&errorString)) {
            NSLog(@"egwGfxContextAGL: loadBufferArraysID:withSQVAMesh:geometryStorage: Failure buffering mesh data into buffer ID %d. GLError: %@", *arraysBufID, (errorString ? errorString : @"GL_NONE"));
            goto ErrorCleanup;
        }
        
        success = YES;
        goto Cleanup;
    } else {
        NSLog(@"egwGfxContextAGL: loadBufferArraysID:withSQVAMesh:geometryStorage: Failure making context active on this thread.");
    }
    
ErrorCleanup:
    if(*arraysBufID)
        *arraysBufID = [egwAIGfxCntxAGL returnUsedBufferID:*arraysBufID];
Cleanup:
    if(apiLocked) {
        pthread_mutex_unlock([[egwAIGfxCntxAGL class] apiMutex]); apiLocked = NO;
    }
    
    return success;
}

- (BOOL)loadBufferArraysID:(EGWuint*)arraysBufID withRawData:(const EGWbyte*)rawData dataSize:(EGWuint)dataSize geometryStorage:(EGWuint)storage {
    BOOL success = NO;
    BOOL apiLocked = NO;
    BOOL isAllocatingArrays = NO;
    
    glGetError(); // Clear background errors
    
    if(!arraysBufID || !rawData) {
        NSLog(@"egwGfxContextAGL: loadBufferArraysID:withRawData:dataSize:geometryStorage: Invalid arguments passed to method.");
        goto ErrorCleanup;
    }
    
    if([egwAIGfxCntxAGL isActive] || [egwAIGfxCntxAGL makeActive]) {
        NSString* errorString = nil;
        GLenum usage = 0;
        
        // NOTE: It is safe to dirty bind buffer identifiers at this point because sub task is performed before render loop and only same last base tracking makes calls to egw_glbind not occur. -jw
        
        switch(storage & EGW_GEOMETRY_STRG_EXVBO) {
            case EGW_GEOMETRY_STRG_VBOSTATIC: { usage = GL_STATIC_DRAW; } break;
            case EGW_GEOMETRY_STRG_VBODYNAMIC: { usage = GL_DYNAMIC_DRAW; } break;
            default: {
                NSLog(@"egwGfxContextAGL: loadBufferArraysID:withRawData:dataSize:geometryStorage: Invalid geometry VBO storage setting '%p'.", storage);
                goto ErrorCleanup;
            }
        }
        
        pthread_mutex_lock([[egwAIGfxCntxAGL class] apiMutex]); apiLocked = YES;
        
        if(!(*arraysBufID)) {
            isAllocatingArrays = YES;
            *arraysBufID = [egwAIGfxCntxAGL requestFreeBufferID];
            if(!(*arraysBufID)) {
                NSLog(@"egwGfxContextAGL: loadBufferArraysID:withRawData:dataSize:geometryStorage: Failure getting new buffer ID for arrays buffer.");
                goto ErrorCleanup;
            }
        }
        
        egw_glBindBuffer(GL_ARRAY_BUFFER, *arraysBufID);
        if(isAllocatingArrays)
            glBufferData(GL_ARRAY_BUFFER, (GLsizeiptr)dataSize, NULL, usage);
        
        glBufferSubData(GL_ARRAY_BUFFER, (GLintptr)0, (GLsizeiptr)dataSize, (const GLvoid*)rawData);
        
        if(egwIsGLError(&errorString)) {
            NSLog(@"egwGfxContextAGL: loadBufferArraysID:withRawData:dataSize:geometryStorage: Failure buffering raw data into buffer ID %d. GLError: %@", *arraysBufID, (errorString ? errorString : @"GL_NONE"));
            goto ErrorCleanup;
        }
        
        success = YES;
        goto Cleanup;
    } else {
        NSLog(@"egwGfxContextAGL: loadBufferArraysID:withRawData:dataSize:geometryStorage: Failure making context active on this thread.");
    }
    
ErrorCleanup:
    if(*arraysBufID)
        *arraysBufID = [egwAIGfxCntxAGL returnUsedBufferID:*arraysBufID];
Cleanup:
    if(apiLocked) {
        pthread_mutex_unlock([[egwAIGfxCntxAGL class] apiMutex]); apiLocked = NO;
    }
    
    return success;
}

@end


#else

@implementation egwGfxContextAGL

- (id)init {
    NSLog(@"egwGfxContextAGL: init: Cannot initialize object due to build mode settings. YOU'RE DOING IT WRONG!");
    
    [self release]; return (self = nil);
}

- (id)initWithParams:(void*)params {
    NSLog(@"egwGfxContextAGL: initWithParams: Cannot initialize object due to build mode settings. YOU'RE DOING IT WRONG!");
    
    [self release]; return (self = nil);
}

@end

#endif

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

/// @file egwGfxContext.m
/// @ingroup geWizES_sys_gfxcontext
/// Abstract Graphics Context Implementation.

#import <pthread.h>
#import "egwGfxContext.h"
#import "../sys/egwEngine.h"
#import "../sys/egwTaskManager.h"
#import "../sys/egwGfxRenderer.h"
#import "../math/egwMath.h"
#import "../gfx/egwGraphics.h"
#import "../gfx/egwLights.h"
#import "../gfx/egwTexture.h"
#import "../geo/egwGeometry.h"
#import "../misc/egwValidater.h"


void (*egwAFPGfxCntxPushLight)(id, SEL, id<egwPLight>) = NULL;
void (*egwAFPGfxCntxPopLights)(id, SEL, EGWuint) = NULL;
void (*egwAFPGfxCntxBindLights)(id, SEL) = NULL;
void (*egwAFPGfxCntxUnbindLights)(id, SEL) = NULL;
void (*egwAFPGfxCntxPushMaterial)(id, SEL, id<egwPMaterial>) = NULL;
void (*egwAFPGfxCntxPopMaterials)(id, SEL, EGWuint) = NULL;
void (*egwAFPGfxCntxBindMaterials)(id, SEL) = NULL;
void (*egwAFPGfxCntxUnbindMaterials)(id, SEL) = NULL;
void (*egwAFPGfxCntxPushTexture)(id, SEL, id<egwPTexture>) = NULL;
void (*egwAFPGfxCntxPopTextures)(id, SEL, EGWuint) = NULL;
void (*egwAFPGfxCntxBindTextures)(id, SEL) = NULL;
void (*egwAFPGfxCntxUnbindTextures)(id, SEL) = NULL;
egwGfxContext* egwAIGfxCntx = nil;


// Sub Task Work Item Structure.
typedef struct {
    id<egwPSubTask> sTask;                  // Subtask object (retained).
    egwValidater* vSync;                    // Validater sync (strong).
} egwContextSubTaskWorkItem;


@implementation egwGfxContext

- (id)init {
    if(![[self class] isSubclassOfClass:[egwGfxContext class]]) {
        NSLog(@"egwGfxContext: init: Error: This method must only be called from derived classes. YOU'RE DOING IT WRONG!");
        [self release]; return (self = nil);
    }
    
    if(!(self = [super init])) { return (self = nil); }
    
    // Create task array
    if(!(_tasks = [[NSMutableArray alloc] init])) { [self release]; return (self = nil); }
    
    // Create sub task array and lock
    if(pthread_mutex_init(&_stLock, NULL)) { [self release]; return (self = nil); }
    if(!egwSLListInit(&_sTasks, NULL, sizeof(egwContextSubTaskWorkItem), EGW_LIST_FLG_RETAIN)) { [self release]; return (self = nil); }
    
    // Start frame checking at always pass (0) until incremented
    _lFrame = _rFrame = EGW_FRAME_ALWAYSPASS;
    
    return self;
}

- (id)initWithParams:(void*)params {
    NSLog(@"egwGfxContext: initWithParams: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
    [self release]; return (self = nil);
}

- (void)dealloc {
    [_delegate release]; _delegate = nil;
    
    [_actvCamera release]; _actvCamera = nil;
    
    [_fTime release]; _fTime = nil; _fCount = 0;
    
    pthread_mutex_destroy(&_stLock);
    egwSLListFree(&_sTasks);
    
    // Wait for tasks to de-associate themselves gracefully, otherwise continue
    {   NSDate* waitTill = [[NSDate alloc] initWithTimeIntervalSinceNow:(NSTimeInterval)EGW_ENGINE_MANAGERS_TIMETOWAIT];
        while([_tasks count]) {
            if([waitTill timeIntervalSinceNow] < (NSTimeInterval)0.0) {
                NSLog(@"egwGfxContext: dealloc: Failure waiting for %d task(s) to de-associate.", [_tasks count]);
                break;
            }
            
            [NSThread sleepForTimeInterval:EGW_ENGINE_MANAGERS_TIMETOSLEEP];
        }
        [waitTill release];
        [_tasks removeAllObjects];
        [_tasks release]; _tasks = nil;
    }
    
    [super dealloc];
}

- (void)advanceIlluminationFrame {
    if(++_lFrame == EGW_FRAME_ALWAYSFAIL) _lFrame = 1;
}

- (void)advanceRenderingFrame {
    if(++_rFrame == EGW_FRAME_ALWAYSFAIL) _rFrame = 1;
}

- (BOOL)associateTask:(id<egwPTask>)task; {
    if(task && ![_tasks containsObject:(id)task]) {
        [_tasks addObject:(id)task];
        
        return YES;
    }
    
    return NO;
}

- (BOOL)deassociateTask:(id<egwPTask>)task {
    if(task && [_tasks containsObject:(id)task]) {
        [_tasks removeObject:(id)task];
        
        return YES;
    }
    
    return NO;
}

- (void)addSubTask:(id<egwPSubTask>)sTask forSync:(egwValidater*)vSync {
    if(sTask) {
        pthread_mutex_lock(&_stLock);
        
        egwContextSubTaskWorkItem workItem;
        workItem.sTask = sTask;
        workItem.vSync = vSync;
        egwSLListAddTail(&_sTasks, (const EGWbyte*)&workItem);
        
        pthread_mutex_unlock(&_stLock);
    }
}

- (void)performSubTasks {
    if(_sTasks.eCount) {
        pthread_mutex_lock(&_stLock);
        
        egwSinglyLinkedListIter iter;
        
        if(egwSLListEnumerateStart(&_sTasks, EGW_ITERATE_MODE_LINHTT, &iter)) {
            egwContextSubTaskWorkItem* workItem;
            egwSinglyLinkedListNode* prev = NULL;
            
            while(workItem = (egwContextSubTaskWorkItem*)egwSLListEnumerateNextPtr(&iter)) {
                if([workItem->sTask performSubTaskForComponent:self forSync:workItem->vSync])
                    egwSLListRemoveAfter(&_sTasks, prev);
                else
                    prev = (prev ? prev->next : _sTasks.lHead);
            }
        }
        
        pthread_mutex_unlock(&_stLock);
    }
}

- (void)removeSubTask:(id<egwPSubTask>)sTask {
    if(sTask && _sTasks.eCount) {
        pthread_mutex_lock(&_stLock);
        
        egwSinglyLinkedListIter iter;
        
        if(egwSLListEnumerateStart(&_sTasks, EGW_ITERATE_MODE_LINHTT, &iter)) {
            egwContextSubTaskWorkItem* workItem;
            egwSinglyLinkedListNode* prev = NULL;
            
            while(workItem = (egwContextSubTaskWorkItem*)egwSLListEnumerateNextPtr(&iter)) {
                if(workItem->sTask == sTask)
                    egwSLListRemoveAfter(&_sTasks, prev);
                else
                    prev = (prev ? prev->next : _sTasks.lHead);
            }
        }
        
        pthread_mutex_unlock(&_stLock);
    }
}

- (BOOL)beginRender {
    NSLog(@"egwGfxContext: beginRender: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
    return NO;
}

- (BOOL)interruptRender {
    NSLog(@"egwGfxContext: interruptRender: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
    return NO;
}

- (BOOL)endRender {
    NSLog(@"egwGfxContext: endRender: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
    return NO;
}

- (BOOL)determineOpacity:(const EGWsingle)alpha {
    if(_aCutoff >= 0.0f)
        return (alpha >= 1.0f - _aCutoff ? YES : NO);
    return (alpha > 1.0f - (-_aCutoff) ? YES : NO);
}

- (BOOL)makeActive {
    NSLog(@"egwGfxContext: makeActive: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
    return NO;
}

- (BOOL)makeActiveAndLocked {
    NSLog(@"egwGfxContext: makeActiveAndLocked: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
    return NO;
}

- (void)pushLight:(id<egwPLight>)light {
    NSLog(@"egwGfxContext: pushLight: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
}

- (void)popLights:(EGWuint)count {
    NSLog(@"egwGfxContext: popLights: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
}

- (void)bindLights {
    NSLog(@"egwGfxContext: bindLights: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
}

- (void)unbindLights {
    NSLog(@"egwGfxContext: unbindLights: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
}

- (void)pushMaterial:(id<egwPMaterial>)material {
    NSLog(@"egwGfxContext: pushMaterial: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
}

- (void)popMaterials:(EGWuint)count {
    NSLog(@"egwGfxContext: popMaterials: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
}

- (void)bindMaterials {
    NSLog(@"egwGfxContext: bindMaterials: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
}

- (void)unbindMaterials {
    NSLog(@"egwGfxContext: unbindMaterials: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
}

- (void)pushTexture:(id<egwPTexture>)texture {
    NSLog(@"egwGfxContext: pushTexture: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
}

- (void)popTextures:(EGWuint)count {
    NSLog(@"egwGfxContext: popTextures: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
}

- (void)bindTextures {
    NSLog(@"egwGfxContext: bindTextures: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
}

- (void)unbindTextures {
    NSLog(@"egwGfxContext: unbindTextures: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
}

- (void)reportDirtyLightBindForIlluminationStage:(EGWuint)illumStage {
    NSLog(@"egwGfxContext: reportDirtyLightBindForIlluminationStage: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
}

- (void)reportDirtyMaterialBindForSurfacingStage:(EGWuint)srfcgStage {
    NSLog(@"egwGfxContext: reportDirtyMaterialBindForSurfacingStage: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
}

- (void)reportDirtyTextureBindForTexturingStage:(EGWuint)txtrStage {
    NSLog(@"egwGfxContext: reportDirtyTextureBindForTexturingStage: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
}

- (void)shutDownContext { // Entrant from derived classes only, already locked
    if(_tasks) {
        [_tasks makeObjectsPerformSelector:@selector(shutDownTask)];
    }
    
    if(_sTasks.eCount) {
        pthread_mutex_lock(&_stLock);
        egwSLListRemoveAll(&_sTasks);
        pthread_mutex_unlock(&_stLock);
    }
    
    [_actvCamera release]; _actvCamera = nil;
    [_fTime release]; _fTime = nil; _fCount = 0;
}

- (BOOL)resizeBufferWidth:(EGWuint16)width bufferHeight:(EGWuint16)height {
    NSLog(@"egwGfxContext: resizeBufferWidth:bufferHeight: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
    return NO;
}

- (id<egwPCamera>)activeCamera {
    return _actvCamera;
}

+ (EGWint)apiIdent {
    NSLog(@"egwGfxContext: apiIdent: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
    return EGW_ENGINE_GFXAPI_INVALID;
}

+ (pthread_mutex_t*)apiMutex {
    NSLog(@"egwGfxContext: apiMutex: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
    return NULL;
}

- (NSArray*)associatedTasks {
    return _tasks;
}

- (EGWuint16)bufferWidth {
    return _width;
}

- (EGWuint16)bufferHeight {
    return _height;
}

- (EGWsingle)framesPerSecond {
    return _fpsAvg;
}

- (EGWuint16)illuminationFrame {
    return _lFrame;
}

- (EGWuint16)maxActiveLights {
    return _maxLights;
}

- (EGWuint16)maxActiveMaterials {
    return _maxMaterials;
}

- (EGWuint16)maxActiveTextures {
    return _maxTextures;
}

- (const egwSize2i*)maxTextureSize {
    return &_maxTexSize;
}

- (EGWuint16)renderingFrame {
    return _rFrame;
}

- (void)setActiveCamera:(id<egwPCamera>)camera {
    if(camera != _actvCamera) {
        [camera retain];
        egwSFPVldtrInvalidate([camera renderingSync], @selector(invalidate));
        [_actvCamera release];
        _actvCamera = camera;
    }
}

- (BOOL)isActive {
    NSLog(@"egwGfxContext: isActive: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
    return NO;
}

- (BOOL)isContextThread {
    return (_thread == [NSThread currentThread] ? YES : NO);
}

- (BOOL)isExtAvailable:(NSString*)extName {
    NSLog(@"egwGfxContext: isExtAvailable: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
    return NO;
}

- (BOOL)isContextShutDown {
    return _doShutdown;
}

@end

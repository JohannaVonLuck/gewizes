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

/// @file egwGfxRenderer.m
/// @ingroup geWizES_sys_gfxrenderer
/// Graphics Renderer Implementation.

#import <pthread.h>
#import "egwGfxRenderer.h"
#import "../sys/egwEngine.h"
#import "../sys/egwTaskManager.h"
#import "../sys/egwGfxContext.h"
#import "../math/egwMath.h"
#import "../math/egwVector.h"
#import "../data/egwArray.h"
#import "../data/egwRedBlackTree.h"
#import "../gfx/egwBindingStacks.h"
#import "../gfx/egwCameras.h"
#import "../misc/egwValidater.h"


egwGfxRenderer* egwSIGfxRdr = nil;


// !!!: ***** egwRenderingWorkItem *****

#define EGW_RDRWRKITM_SORTDESCLEN   14      // Sort description max length
#define EGW_RDRWRKITMFLG_NONE       0x00    // No flags
#define EGW_RDRWRKITMFLG_RANPASS    0x01    // Render pass already ran
#define EGW_RDRWRKITMFLG_ATPMASK    0xf0    // Render item adds to pending list mask
#define EGW_RDRWRKITMFLG_DELETE     0x10    // Render item needs deleted
#define EGW_RDRWRKITMFLG_RESORT     0x20    // Render item needs resorted / validated

typedef struct {
    id<egwPRenderable> object;              // Ref to graphics object (retained, from flag).
	EGWuint16 flags;                        // Flags for insertion or removal.
    const egwRenderableJumpTable* rJmpT;    // Ref to renderable jump table.
} egwRenderingWorkReq;

typedef struct {
    EGWuint isOpaque;                       // IsOpaque identifier.
    union {
        struct {
            EGWuint32 lghtStkHash;          // Light stack hash.
            EGWuint32 mtrlStkHash;          // Material stack hash.
            EGWuint32 shdrStkHash;          // Shader stack hash.
            EGWuint32 txtrStkHash;          // Texutre stack hash.
        } opaque;
        struct {
            EGWdouble distFromCam;          // Distance from camera.
        } trans;
    } data;
} egwRenderingWorkItemSortDescriptor;

typedef struct {
    egwRenderingWorkItemSortDescriptor sortDesc;// Task item sort descriptor.
    EGWuint16 tFrame;                       // Task item frame.
    EGWuint8 tFlags;                        // Task item flags.
    EGWuint8 qIndex;                        // Source queue of item, for insert/resort/remove.
    id<egwPRenderable> object;              // Ref to graphics object (retained).
    egwValidater* sync;                     // Ref to validation sync (strong).
    const egwRenderableJumpTable* rJmpT;    // Ref to renderable jump table.
} egwRenderingWorkItem;

EGWint egwRWICompare(egwRenderingWorkItem* item1, egwRenderingWorkItem* item2, size_t size) {
    if(item1->sortDesc.isOpaque == 1 && item2->sortDesc.isOpaque == 1) {
        if(item1->sortDesc.data.opaque.shdrStkHash == item2->sortDesc.data.opaque.shdrStkHash) {
            if(item1->sortDesc.data.opaque.txtrStkHash == item2->sortDesc.data.opaque.txtrStkHash) {
                if(item1->sortDesc.data.opaque.mtrlStkHash == item2->sortDesc.data.opaque.mtrlStkHash) {
                    if(item1->sortDesc.data.opaque.lghtStkHash == item2->sortDesc.data.opaque.lghtStkHash) {
                        return 0;
                    } else
                        return (item1->sortDesc.data.opaque.lghtStkHash < item2->sortDesc.data.opaque.lghtStkHash ? -1 : 1);
                } else
                    return (item1->sortDesc.data.opaque.mtrlStkHash < item2->sortDesc.data.opaque.mtrlStkHash ? -1 : 1);
            } else
                return (item1->sortDesc.data.opaque.txtrStkHash < item2->sortDesc.data.opaque.txtrStkHash ? -1 : 1);
        } else
            return (item1->sortDesc.data.opaque.shdrStkHash < item2->sortDesc.data.opaque.shdrStkHash ? -1 : 1);
    } else if(item1->sortDesc.isOpaque == 0 && item2->sortDesc.isOpaque == 0) {
        return (item1->sortDesc.data.trans.distFromCam <= item2->sortDesc.data.trans.distFromCam + EGW_DFLT_EPSILON ? -1 : 1);
    } else
        return (item1->sortDesc.isOpaque ? -1 : 1);
}

void egwRWIAdd(egwRenderingWorkItem* item) {
    item->rJmpT->fpRetain(item->object, @selector(retain));
    //[item->sync retain];
}

void egwRWIRemove(egwRenderingWorkItem* item) {
    item->rJmpT->fpRelease(item->object, @selector(release)); item->object = nil;
    //[item->sync release];
    item->sync = nil;
}

EGWint egwRWIUpdate(egwRenderingWorkItem* item, egwTaskCameraData* rCamera) {
    {   EGWuint isOpaque = item->rJmpT->fpOpaque(item->object, @selector(isOpaque));
        if(item->sortDesc.isOpaque != isOpaque) {
            item->sortDesc.isOpaque = isOpaque;
            if(item->sortDesc.isOpaque) {
                item->sortDesc.data.opaque.lghtStkHash = egwSFPLghtStckStackHash((id)item->rJmpT->fpLStack(item->object, @selector(lightStack)), @selector(stackHash));
                item->sortDesc.data.opaque.mtrlStkHash = egwSFPMtrlStckStackHash((id)item->rJmpT->fpMStack(item->object, @selector(materialStack)), @selector(stackHash));
                item->sortDesc.data.opaque.shdrStkHash = egwSFPShdrStckStackHash((id)item->rJmpT->fpSStack(item->object, @selector(shaderStack)), @selector(stackHash));
                item->sortDesc.data.opaque.txtrStkHash = egwSFPTxtrStckStackHash((id)item->rJmpT->fpTStack(item->object, @selector(textureStack)), @selector(stackHash));
            } else {
                if(!rCamera->isOrtho) {
                    const egwVector4f* itemSource = item->rJmpT->fpRSource(item->object, @selector(renderingSource));
                    
                    item->sortDesc.data.trans.distFromCam = 
                        egwSqrdd((EGWdouble)rCamera->source->axis.x - (EGWdouble)itemSource->axis.x) +
                        egwSqrdd((EGWdouble)rCamera->source->axis.y - (EGWdouble)itemSource->axis.y) +
                        egwSqrdd((EGWdouble)rCamera->source->axis.z - (EGWdouble)itemSource->axis.z);
                } else {
                    item->sortDesc.data.trans.distFromCam = (EGWdouble)item->rJmpT->fpRSource(item->object, @selector(renderingSource))->axis.z;
                }
            }
            return 1;
        }
    }
    
    if(item->sortDesc.isOpaque) {
        {   EGWuint32 lghtStkHash = egwSFPLghtStckStackHash((id)item->rJmpT->fpLStack(item->object, @selector(lightStack)), @selector(stackHash));
            if(item->sortDesc.data.opaque.lghtStkHash != lghtStkHash) {
                item->sortDesc.data.opaque.lghtStkHash = lghtStkHash;
                item->sortDesc.data.opaque.mtrlStkHash = egwSFPMtrlStckStackHash((id)item->rJmpT->fpMStack(item->object, @selector(materialStack)), @selector(stackHash));
                item->sortDesc.data.opaque.shdrStkHash = egwSFPShdrStckStackHash((id)item->rJmpT->fpSStack(item->object, @selector(shaderStack)), @selector(stackHash));
                item->sortDesc.data.opaque.txtrStkHash = egwSFPTxtrStckStackHash((id)item->rJmpT->fpTStack(item->object, @selector(textureStack)), @selector(stackHash));
                return 1;
            }
        }
        
        {   EGWuint32 mtrlStkHash = egwSFPMtrlStckStackHash((id)item->rJmpT->fpMStack(item->object, @selector(materialStack)), @selector(stackHash));
            if(item->sortDesc.data.opaque.mtrlStkHash != mtrlStkHash) {
                item->sortDesc.data.opaque.mtrlStkHash = mtrlStkHash;
                item->sortDesc.data.opaque.shdrStkHash = egwSFPShdrStckStackHash((id)item->rJmpT->fpSStack(item->object, @selector(shaderStack)), @selector(stackHash));
                item->sortDesc.data.opaque.txtrStkHash = egwSFPTxtrStckStackHash((id)item->rJmpT->fpTStack(item->object, @selector(textureStack)), @selector(stackHash));
                return 1;
            }
        }
        
        {   EGWuint32 shdrStkHash = egwSFPShdrStckStackHash((id)item->rJmpT->fpSStack(item->object, @selector(shaderStack)), @selector(stackHash));
            if(item->sortDesc.data.opaque.shdrStkHash != shdrStkHash) {
                item->sortDesc.data.opaque.shdrStkHash = shdrStkHash;
                item->sortDesc.data.opaque.txtrStkHash = egwSFPTxtrStckStackHash((id)item->rJmpT->fpTStack(item->object, @selector(textureStack)), @selector(stackHash));
                return 1;
            }
        }
        
        {   EGWuint32 txtrStkHash = egwSFPTxtrStckStackHash((id)item->rJmpT->fpTStack(item->object, @selector(textureStack)), @selector(stackHash));
            if(item->sortDesc.data.opaque.txtrStkHash != txtrStkHash) {
                item->sortDesc.data.opaque.txtrStkHash = txtrStkHash;
                return 1;
            }
        }
    } else {
        if(!rCamera->isOrtho) {
            const egwVector4f* itemSource = item->rJmpT->fpRSource(item->object, @selector(renderingSource));
            EGWdouble distFromCam = 
                egwSqrdd((EGWdouble)rCamera->source->axis.x - (EGWdouble)itemSource->axis.x) +
                egwSqrdd((EGWdouble)rCamera->source->axis.y - (EGWdouble)itemSource->axis.y) +
                egwSqrdd((EGWdouble)rCamera->source->axis.z - (EGWdouble)itemSource->axis.z);
            if(!egwIsEquald(item->sortDesc.data.trans.distFromCam, distFromCam)) {
                item->sortDesc.data.trans.distFromCam = distFromCam;
                return 1;
            }
        } else {
            EGWdouble distFromCam = (EGWdouble)item->rJmpT->fpRSource(item->object, @selector(renderingSource))->axis.z;
            if(!egwIsEquald(item->sortDesc.data.trans.distFromCam, distFromCam)) {
                item->sortDesc.data.trans.distFromCam = distFromCam;
                return 1;
            }
        }
    }
    
    return 0;
}


// !!!: ***** egwGfxRenderer *****

@implementation egwGfxRenderer

static egwGfxRenderer* _singleton = nil;

+ (id)alloc {
    @synchronized(self) {
        if(!_singleton)
            egwSIGfxRdr = _singleton = [super alloc];
    }
    return _singleton;
}

+ (void)dealloc {
    @synchronized(self) {
        [_singleton release];
        egwSIGfxRdr = _singleton = nil;
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
    return [self initWithParams:NULL];
}

- (id)initWithParams:(egwGfxRdrParams*)params {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(egwAIGfxCntx)) {
        NSLog(@"egwGfxRenderer: initWithParams: Error: Must have an active graphics context up and running. YOU'RE DOING IT WRONG!");
        [self release]; return (self = nil);
    }
    
    if(params) memcpy((void*)&_params, (const void*)params, sizeof(egwGfxRdrParams));
    if(_params.mode == 0) _params.mode = EGW_GFXRNDRR_RNDRMODE_DFLT;
    if(_params.priority == 0.0) _params.priority = EGW_GFXRNDRR_DFLTPRIORITY;
    
    _tFrame = 1;
    _amRunning = _doShutdown = NO;
    _doPreprocessing = YES; _doPostprocessing = NO;
    _alphaMods[0] = _alphaMods[1] = _alphaMods[2] = _alphaMods[3] =
        _alphaMods[4] = _alphaMods[5] = _alphaMods[6] = _alphaMods[7] =
        _shadeMods[0] = _shadeMods[1] = _shadeMods[2] = _shadeMods[3] = 
        _shadeMods[4] = _shadeMods[5] = _shadeMods[6] = _shadeMods[7] = 100;
    
    // Allocate queues
    egwDataFuncs callbacks; memset((void*)&callbacks, 0, sizeof(egwDataFuncs));
    callbacks.fpCompare = (EGWcomparefp)&egwRWICompare;
    callbacks.fpAdd = (EGWelementfp)&egwRWIAdd;
    callbacks.fpRemove = (EGWelementfp)&egwRWIRemove;
    if(!(egwRBTreeInit(&_rQueues[0], &callbacks, sizeof(egwRenderingWorkItem), EGW_TREE_FLG_DFLT))) { [self release]; return (self = nil); }
    if(!(egwRBTreeInit(&_rQueues[1], &callbacks, sizeof(egwRenderingWorkItem), EGW_TREE_FLG_DFLT))) { [self release]; return (self = nil); }
    if(!(egwRBTreeInit(&_rQueues[2], &callbacks, sizeof(egwRenderingWorkItem), EGW_TREE_FLG_DFLT))) { [self release]; return (self = nil); }
    if(!(egwRBTreeInit(&_rQueues[3], &callbacks, sizeof(egwRenderingWorkItem), EGW_TREE_FLG_DFLT))) { [self release]; return (self = nil); }
    if(!(egwRBTreeInit(&_rQueues[4], &callbacks, sizeof(egwRenderingWorkItem), EGW_TREE_FLG_DFLT))) { [self release]; return (self = nil); }
    if(!(egwRBTreeInit(&_rQueues[5], &callbacks, sizeof(egwRenderingWorkItem), EGW_TREE_FLG_DFLT))) { [self release]; return (self = nil); }
    if(!(egwRBTreeInit(&_rQueues[6], &callbacks, sizeof(egwRenderingWorkItem), EGW_TREE_FLG_DFLT))) { [self release]; return (self = nil); }
    if(!(egwRBTreeInit(&_rQueues[7], &callbacks, sizeof(egwRenderingWorkItem), EGW_TREE_FLG_DFLT))) { [self release]; return (self = nil); }
    if(!(egwArrayInit(&_pendingList, NULL, sizeof(void*), 10, (EGW_ARRAY_FLG_GROWBY25 | EGW_ARRAY_FLG_GRWCND100 | EGW_ARRAY_FLG_SHRNKBY2X)))) { [self release]; return (self = nil); }
    if(!(egwArrayInit(&_requestList, NULL, sizeof(egwRenderingWorkReq), 10, (EGW_ARRAY_FLG_GROWBY10 | EGW_ARRAY_FLG_GRWCND100 | EGW_ARRAY_FLG_SHRNKBY2X | EGW_ARRAY_FLG_RETAIN)))) { [self release]; return (self = nil); }
    _rReplies[0] = EGW_GFXOBJ_RPLYFLY_DORENDERPASS | (EGW_GFXOBJ_RPLYFLG_RENDERPASSMASK & (EGWuint)1);
    _rReplies[1] = EGW_GFXOBJ_RPLYFLY_DORENDERPASS | (EGW_GFXOBJ_RPLYFLG_RENDERPASSMASK & (EGWuint)2);
    _rReplies[2] = EGW_GFXOBJ_RPLYFLY_DORENDERPASS | (EGW_GFXOBJ_RPLYFLG_RENDERPASSMASK & (EGWuint)3);
    _rReplies[3] = EGW_GFXOBJ_RPLYFLY_DORENDERPASS | (EGW_GFXOBJ_RPLYFLG_RENDERPASSMASK & (EGWuint)4);
    _rReplies[4] = EGW_GFXOBJ_RPLYFLY_DORENDERPASS | (EGW_GFXOBJ_RPLYFLG_RENDERPASSMASK & (EGWuint)5);
    _rReplies[5] = EGW_GFXOBJ_RPLYFLY_DORENDERPASS | (EGW_GFXOBJ_RPLYFLG_RENDERPASSMASK & (EGWuint)6);
    _rReplies[6] = EGW_GFXOBJ_RPLYFLY_DORENDERPASS | (EGW_GFXOBJ_RPLYFLG_RENDERPASSMASK & (EGWuint)7);
    _rReplies[7] = EGW_GFXOBJ_RPLYFLY_DORENDERPASS | (EGW_GFXOBJ_RPLYFLG_RENDERPASSMASK & (EGWuint)8);
    
    // Allocate mutex lock
    if(pthread_mutex_init(&_qLock, NULL)) { [self release]; return (self = nil); }
    if(pthread_mutex_init(&_rLock, NULL)) { [self release]; return (self = nil); }
    
    // Associated instance with active context
    if(!(egwAIGfxCntx && [egwAIGfxCntx associateTask:self])) { [self release]; return (self = nil); }
    
    if(EGW_ENGINE_MANAGERS_STARTUPMSGS) NSLog(@"egwGfxRenderer: initWithParams: Graphics renderer has been initialized.");
    
    return self;
}

- (void)dealloc {
    [self shutDownTask];
    
    [_lBase release]; _lBase = nil;
    egwArrayFree(&_pendingList);
    egwArrayFree(&_requestList);
    [_rCameras[0].camera release]; _rCameras[0].camera = nil;
    [_rCameras[1].camera release]; _rCameras[1].camera = nil;
    [_rCameras[2].camera release]; _rCameras[2].camera = nil;
    [_rCameras[3].camera release]; _rCameras[3].camera = nil;
    [_rCameras[4].camera release]; _rCameras[4].camera = nil;
    [_rCameras[5].camera release]; _rCameras[5].camera = nil;
    [_rCameras[6].camera release]; _rCameras[6].camera = nil;
    [_rCameras[7].camera release]; _rCameras[7].camera = nil;
    [_rCameras[0].sync release]; _rCameras[0].sync = nil;
    [_rCameras[1].sync release]; _rCameras[1].sync = nil;
    [_rCameras[2].sync release]; _rCameras[2].sync = nil;
    [_rCameras[3].sync release]; _rCameras[3].sync = nil;
    [_rCameras[4].sync release]; _rCameras[4].sync = nil;
    [_rCameras[5].sync release]; _rCameras[5].sync = nil;
    [_rCameras[6].sync release]; _rCameras[6].sync = nil;
    [_rCameras[7].sync release]; _rCameras[7].sync = nil;
    _rCameras[0].source = _rCameras[1].source = _rCameras[2].source =
        _rCameras[3].source = _rCameras[4].source = _rCameras[5].source =
        _rCameras[6].source = _rCameras[7].source = NULL;
    _rCameras[0].fpBind = _rCameras[1].fpBind = _rCameras[2].fpBind =
        _rCameras[3].fpBind = _rCameras[4].fpBind = _rCameras[5].fpBind =
        _rCameras[6].fpBind = _rCameras[7].fpBind = (BOOL(*)(id, SEL, EGWuint))NULL;
    _rCameras[0].fpFlags = _rCameras[1].fpFlags = _rCameras[2].fpFlags =
        _rCameras[3].fpFlags = _rCameras[4].fpFlags = _rCameras[5].fpFlags =
        _rCameras[6].fpFlags = _rCameras[7].fpFlags = (EGWuint(*)(id, SEL))NULL;
    _rCameras[0].isOrtho = _rCameras[1].isOrtho = _rCameras[2].isOrtho =
        _rCameras[3].isOrtho = _rCameras[4].isOrtho = _rCameras[5].isOrtho =
        _rCameras[6].isOrtho = _rCameras[7].isOrtho = NO;
    egwRBTreeFree(&_rQueues[0]);
    egwRBTreeFree(&_rQueues[1]);
    egwRBTreeFree(&_rQueues[2]);
    egwRBTreeFree(&_rQueues[3]);
    egwRBTreeFree(&_rQueues[4]);
    egwRBTreeFree(&_rQueues[5]);
    egwRBTreeFree(&_rQueues[6]);
    egwRBTreeFree(&_rQueues[7]);
    pthread_mutex_destroy(&_qLock);
    pthread_mutex_destroy(&_rLock);
    
    [super dealloc];
}

- (void)renderObject:(id<egwPRenderable>)renderableObject {
    if(renderableObject) {
        egwRenderingWorkReq workItemReq;
        workItemReq.rJmpT = [renderableObject renderableJumpTable];
        
        EGWuint32 rFlags = workItemReq.rJmpT->fpRFlags(renderableObject, @selector(renderingFlags));
        if(!(rFlags & EGW_GFXRNDRR_RNDRQUEUE_ALL)) // idiot proofing
            rFlags |= EGW_GFXRNDRR_RNDRQUEUE_FIRSTPASS;
        
        if(_params.mode & EGW_GFXRNDRR_RNDRMODE_FRAMECHECK)
            workItemReq.rJmpT->fpSetRFrame(renderableObject, @selector(setRenderingFrame:), egwAFPGfxCntxRenderingFrame(egwAIGfxCntx, @selector(renderingFrame)));
        
        workItemReq.object = renderableObject; // weak, retained on add
        workItemReq.flags = EGW_GFXRNDRR_RNDRQUEUE_INSERT | (rFlags & EGW_GFXRNDRR_RNDRQUEUE_ALL);
        
        // Lock mutex and add to request queue
        pthread_mutex_lock(&_rLock);
        egwArrayAddTail(&_requestList, (const EGWbyte*)&workItemReq);
        pthread_mutex_unlock(&_rLock);
    }
}

- (void)renderFinish {
    _doPostprocessing = YES;
}

- (void)pauseObject:(id<egwPRenderable>)renderableObject {
    if(renderableObject) {
        egwRenderingWorkReq workItemReq;
        workItemReq.rJmpT = [renderableObject renderableJumpTable];
        
        workItemReq.object = renderableObject; // weak, retained on add
        workItemReq.flags = EGW_GFXRNDRR_RNDRQUEUE_PAUSE;
        
        // Lock mutex and add to request queue
        pthread_mutex_lock(&_rLock);
        egwArrayAddTail(&_requestList, (const EGWbyte*)&workItemReq);
        pthread_mutex_unlock(&_rLock);
    }
}

- (void)removeObject:(id<egwPRenderable>)renderableObject {
    if(renderableObject) {
        egwRenderingWorkReq workItemReq;
        workItemReq.rJmpT = [renderableObject renderableJumpTable];
        
        workItemReq.object = renderableObject; // weak, retained on add
        workItemReq.flags = EGW_GFXRNDRR_RNDRQUEUE_REMOVE;
        
        // Lock mutex and add to request queue
        pthread_mutex_lock(&_rLock);
        egwArrayAddTail(&_requestList, (const EGWbyte*)&workItemReq);
        pthread_mutex_unlock(&_rLock);
    }
}

- (void)shutDownTask {
    if(!_doShutdown) {
        @synchronized(self) {
            if(!_doShutdown) {
                _doShutdown = YES;
                
                if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwGfxRenderer: shutDownTask: Shutting down graphics renderer.");
                
                [egwSITaskMngr unregisterAllTasksUsing:self];
                
                // Wait for running status to deactivate
                if(_amRunning) {
                    NSDate* waitTill = [[NSDate alloc] initWithTimeIntervalSinceNow:(NSTimeInterval)EGW_ENGINE_MANAGERS_TIMETOWAIT];
                    while(_amRunning) {
                        if([waitTill timeIntervalSinceNow] < (NSTimeInterval)0.0) {
                            NSLog(@"egwGfxRenderer: shutDownTask: Failure waiting for running status to deactivate.");
                            break;
                        }
                        
                        [NSThread sleepForTimeInterval:EGW_ENGINE_MANAGERS_TIMETOSLEEP];
                    }
                    [waitTill release];
                }
                
                [_lBase release]; _lBase = nil;
                egwArrayFree(&_pendingList);
                egwArrayFree(&_requestList);
                [_rCameras[0].camera release]; _rCameras[0].camera = nil;
                [_rCameras[1].camera release]; _rCameras[1].camera = nil;
                [_rCameras[2].camera release]; _rCameras[2].camera = nil;
                [_rCameras[3].camera release]; _rCameras[3].camera = nil;
                [_rCameras[4].camera release]; _rCameras[4].camera = nil;
                [_rCameras[5].camera release]; _rCameras[5].camera = nil;
                [_rCameras[6].camera release]; _rCameras[6].camera = nil;
                [_rCameras[7].camera release]; _rCameras[7].camera = nil;
                [_rCameras[0].sync release]; _rCameras[0].sync = nil;
                [_rCameras[1].sync release]; _rCameras[1].sync = nil;
                [_rCameras[2].sync release]; _rCameras[2].sync = nil;
                [_rCameras[3].sync release]; _rCameras[3].sync = nil;
                [_rCameras[4].sync release]; _rCameras[4].sync = nil;
                [_rCameras[5].sync release]; _rCameras[5].sync = nil;
                [_rCameras[6].sync release]; _rCameras[6].sync = nil;
                [_rCameras[7].sync release]; _rCameras[7].sync = nil;
                _rCameras[0].source = _rCameras[1].source = _rCameras[2].source =
                    _rCameras[3].source = _rCameras[4].source = _rCameras[5].source =
                    _rCameras[6].source = _rCameras[7].source = NULL;
                _rCameras[0].fpBind = _rCameras[1].fpBind = _rCameras[2].fpBind =
                    _rCameras[3].fpBind = _rCameras[4].fpBind = _rCameras[5].fpBind =
                    _rCameras[6].fpBind = _rCameras[7].fpBind = (BOOL(*)(id, SEL, EGWuint))NULL;
                _rCameras[0].fpFlags = _rCameras[1].fpFlags = _rCameras[2].fpFlags =
                    _rCameras[3].fpFlags = _rCameras[4].fpFlags = _rCameras[5].fpFlags =
                    _rCameras[6].fpFlags = _rCameras[7].fpFlags = (EGWuint(*)(id, SEL))NULL;
                _rCameras[0].isOrtho = _rCameras[1].isOrtho = _rCameras[2].isOrtho =
                    _rCameras[3].isOrtho = _rCameras[4].isOrtho = _rCameras[5].isOrtho =
                    _rCameras[6].isOrtho = _rCameras[7].isOrtho = NO;
                egwRBTreeFree(&_rQueues[0]);
                egwRBTreeFree(&_rQueues[1]);
                egwRBTreeFree(&_rQueues[2]);
                egwRBTreeFree(&_rQueues[3]);
                egwRBTreeFree(&_rQueues[4]);
                egwRBTreeFree(&_rQueues[5]);
                egwRBTreeFree(&_rQueues[6]);
                egwRBTreeFree(&_rQueues[7]);
                
                // Done last due to potential to have self dealloc'ed immediately afterwords
                [egwAIGfxCntx deassociateTask:self];
                
                if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwGfxRenderer: shutDownTask: Graphics renderer shut down.");
            }
        }
    }
}

- (id<egwPCamera>)renderingCameraForQueue:(EGWuint)queueIdent {
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_FIRSTPASS)
        return _rCameras[0].camera;
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_SECONDPASS)
        return _rCameras[1].camera;
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_THIRDPASS)
        return _rCameras[2].camera;
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_FOURTHPASS)
        return _rCameras[3].camera;
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_FIFTHPASS)
        return _rCameras[4].camera;
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_SIXTHPASS)
        return _rCameras[5].camera;
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_SEVENTHPASS)
        return _rCameras[6].camera;
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_EIGHTHPASS)
        return _rCameras[7].camera;
    
    return nil;
}

- (double)taskPriority {
    return _params.priority;
}

- (void)setRenderingCamera:(id<egwPCamera>)camera forQueue:(EGWuint)queueIdent {
    pthread_mutex_lock(&_qLock);
    
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_FIRSTPASS) {
        [camera retain];
        [_rCameras[0].camera release];
        _rCameras[0].camera = camera;
        [_rCameras[0].sync release];
        _rCameras[0].sync = [[camera renderingSync] retain];
        _rCameras[0].source = [camera viewingSource];
        _rCameras[0].fpBind = (BOOL(*)(id, SEL, EGWuint))[(NSObject*)camera methodForSelector:@selector(bindForRenderingWithFlags:)];
        _rCameras[0].fpFlags = (EGWuint(*)(id, SEL))[(NSObject*)camera methodForSelector:@selector(viewingFlags)];
        _rCameras[0].isOrtho = [camera isKindOfClass:[egwOrthogonalCamera class]];
    }
    
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_SECONDPASS) {
        [camera retain];
        [_rCameras[1].camera release];
        _rCameras[1].camera = camera;
        [_rCameras[1].sync release];
        _rCameras[1].sync = [[camera renderingSync] retain];
        _rCameras[1].source = [camera viewingSource];
        _rCameras[1].fpBind = (BOOL(*)(id, SEL, EGWuint))[(NSObject*)camera methodForSelector:@selector(bindForRenderingWithFlags:)];
        _rCameras[1].fpFlags = (EGWuint(*)(id, SEL))[(NSObject*)camera methodForSelector:@selector(viewingFlags)];
        _rCameras[1].isOrtho = [camera isKindOfClass:[egwOrthogonalCamera class]];
    }
    
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_THIRDPASS) {
        [camera retain];
        [_rCameras[2].camera release];
        _rCameras[2].camera = camera;
        [_rCameras[2].sync release];
        _rCameras[2].sync = [[camera renderingSync] retain];
        _rCameras[2].source = [camera viewingSource];
        _rCameras[2].fpBind = (BOOL(*)(id, SEL, EGWuint))[(NSObject*)camera methodForSelector:@selector(bindForRenderingWithFlags:)];
        _rCameras[2].fpFlags = (EGWuint(*)(id, SEL))[(NSObject*)camera methodForSelector:@selector(viewingFlags)];
        _rCameras[2].isOrtho = [camera isKindOfClass:[egwOrthogonalCamera class]];
    }
    
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_FOURTHPASS) {
        [camera retain];
        [_rCameras[3].camera release];
        _rCameras[3].camera = camera;
        [_rCameras[3].sync release];
        _rCameras[3].sync = [[camera renderingSync] retain];
        _rCameras[3].source = [camera viewingSource];
        _rCameras[3].fpBind = (BOOL(*)(id, SEL, EGWuint))[(NSObject*)camera methodForSelector:@selector(bindForRenderingWithFlags:)];
        _rCameras[3].fpFlags = (EGWuint(*)(id, SEL))[(NSObject*)camera methodForSelector:@selector(viewingFlags)];
        _rCameras[3].isOrtho = [camera isKindOfClass:[egwOrthogonalCamera class]];
    }
    
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_FIFTHPASS) {
        [camera retain];
        [_rCameras[4].camera release];
        _rCameras[4].camera = camera;
        [_rCameras[4].sync release];
        _rCameras[4].sync = [[camera renderingSync] retain];
        _rCameras[4].source = [camera viewingSource];
        _rCameras[4].fpBind = (BOOL(*)(id, SEL, EGWuint))[(NSObject*)camera methodForSelector:@selector(bindForRenderingWithFlags:)];
        _rCameras[4].fpFlags = (EGWuint(*)(id, SEL))[(NSObject*)camera methodForSelector:@selector(viewingFlags)];
        _rCameras[4].isOrtho = [camera isKindOfClass:[egwOrthogonalCamera class]];
    }
    
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_SIXTHPASS) {
        [camera retain];
        [_rCameras[5].camera release];
        _rCameras[5].camera = camera;
        [_rCameras[5].sync release];
        _rCameras[5].sync = [[camera renderingSync] retain];
        _rCameras[5].source = [camera viewingSource];
        _rCameras[5].fpBind = (BOOL(*)(id, SEL, EGWuint))[(NSObject*)camera methodForSelector:@selector(bindForRenderingWithFlags:)];
        _rCameras[5].fpFlags = (EGWuint(*)(id, SEL))[(NSObject*)camera methodForSelector:@selector(viewingFlags)];
        _rCameras[5].isOrtho = [camera isKindOfClass:[egwOrthogonalCamera class]];
    }
    
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_SEVENTHPASS) {
        [camera retain];
        [_rCameras[6].camera release];
        _rCameras[6].camera = camera;
        [_rCameras[6].sync release];
        _rCameras[6].sync = [[camera renderingSync] retain];
        _rCameras[6].source = [camera viewingSource];
        _rCameras[6].fpBind = (BOOL(*)(id, SEL, EGWuint))[(NSObject*)camera methodForSelector:@selector(bindForRenderingWithFlags:)];
        _rCameras[6].fpFlags = (EGWuint(*)(id, SEL))[(NSObject*)camera methodForSelector:@selector(viewingFlags)];
        _rCameras[6].isOrtho = [camera isKindOfClass:[egwOrthogonalCamera class]];
    }
    
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_EIGHTHPASS) {
        [camera retain];
        [_rCameras[7].camera release];
        _rCameras[7].camera = camera;
        [_rCameras[7].sync release];
        _rCameras[7].sync = [[camera renderingSync] retain];
        _rCameras[7].source = [camera viewingSource];
        _rCameras[7].fpBind = (BOOL(*)(id, SEL, EGWuint))[(NSObject*)camera methodForSelector:@selector(bindForRenderingWithFlags:)];
        _rCameras[7].fpFlags = (EGWuint(*)(id, SEL))[(NSObject*)camera methodForSelector:@selector(viewingFlags)];
        _rCameras[7].isOrtho = [camera isKindOfClass:[egwOrthogonalCamera class]];
    }
    
    pthread_mutex_unlock(&_qLock);
}

- (void)setAlphaModifier:(EGWuint8)alphaMod forQueue:(EGWuint)queueIdent {
    pthread_mutex_lock(&_qLock);
    
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_FIRSTPASS)
        _alphaMods[0] = alphaMod;
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_SECONDPASS)
        _alphaMods[1] = alphaMod;
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_THIRDPASS)
        _alphaMods[2] = alphaMod;
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_FOURTHPASS)
        _alphaMods[3] = alphaMod;
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_FIFTHPASS)
        _alphaMods[4] = alphaMod;
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_SIXTHPASS)
        _alphaMods[5] = alphaMod;
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_SEVENTHPASS)
        _alphaMods[6] = alphaMod;
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_EIGHTHPASS)
        _alphaMods[7] = alphaMod;
    
    _modChange = YES;
    
    pthread_mutex_unlock(&_qLock);
}

- (void)setShadeModifier:(EGWuint8)shadeMod forQueue:(EGWuint)queueIdent {
    pthread_mutex_lock(&_qLock);
    
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_FIRSTPASS)
        _shadeMods[0] = shadeMod;
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_SECONDPASS)
        _shadeMods[1] = shadeMod;
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_THIRDPASS)
        _shadeMods[2] = shadeMod;
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_FOURTHPASS)
        _shadeMods[3] = shadeMod;
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_FIFTHPASS)
        _shadeMods[4] = shadeMod;
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_SIXTHPASS)
        _shadeMods[5] = shadeMod;
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_SEVENTHPASS)
        _shadeMods[6] = shadeMod;
    if(queueIdent & EGW_GFXRNDRR_RNDRQUEUE_EIGHTHPASS)
        _shadeMods[7] = shadeMod;
    
    _modChange = YES;
    
    pthread_mutex_unlock(&_qLock);
}

- (BOOL)isTaskPerforming {
    return _amRunning;
}

- (BOOL)isTaskShutDown {
    return _doShutdown;
}

- (BOOL)isThreadOwner {
    return YES;
}

- (void)performTask {
    egwRenderingWorkReq* workReq = nil;
    egwRenderingWorkItem* workItem = nil;
    egwRedBlackTreeIter workItmIter;
    egwArrayIter workReqIter;
    id<egwPRenderable> workObject = nil;
    EGWint qIndex;
	EGWuint16 wItmRFrame;
    
    if(_doShutdown) goto TaskBreak;
    pthread_mutex_lock(&_qLock);
    _amRunning = YES;
    
    // Start rendering frame runthrough, do pre-processing
    if(_doPreprocessing) {
        _doPreprocessing = NO;
        
        if(++_tFrame == EGW_FRAME_ALWAYSFAIL) _tFrame = 1;
        
        // Once in rendering pass, context change is disabled, so only
        // need to ensure active context here once
        if(!egwAFPGfxCntxActive(egwAIGfxCntx, @selector(isActive)))
            egwAFPGfxCntxMakeActive(egwAIGfxCntx, @selector(makeActive));
        
        egwAFPGfxCntxPerformSubTasks(egwAIGfxCntx, @selector(performSubTasks));
        
        egwAFPGfxCntxBeginRender(egwAIGfxCntx, @selector(beginRender));
        
        if(_modChange) { // Mod changes go into reply flags per immediate loop
            _rReplies[0] |= EGW_GFXOBJ_RPLYFLG_APISYNCINVLD;
            _rReplies[1] |= EGW_GFXOBJ_RPLYFLG_APISYNCINVLD;
            _rReplies[2] |= EGW_GFXOBJ_RPLYFLG_APISYNCINVLD;
            _rReplies[3] |= EGW_GFXOBJ_RPLYFLG_APISYNCINVLD;
            _rReplies[4] |= EGW_GFXOBJ_RPLYFLG_APISYNCINVLD;
            _rReplies[5] |= EGW_GFXOBJ_RPLYFLG_APISYNCINVLD;
            _rReplies[6] |= EGW_GFXOBJ_RPLYFLG_APISYNCINVLD;
            _rReplies[7] |= EGW_GFXOBJ_RPLYFLG_APISYNCINVLD;
        }
        
        if(_params.mode & EGW_GFXRNDRR_RNDRMODE_DEFERRED)
            _doPostprocessing = YES;
        else {
            egwAFPGfxCntxSetActiveCamera(egwAIGfxCntx, @selector(setActiveCamera:), _rCameras[0].camera);
            
            if(egwSFPVldtrIsInvalidated(_rCameras[0].sync, @selector(isInvalidated)))
                _rCameras[0].fpBind(_rCameras[0].camera, @selector(bindForRenderingWithFlags:), (_rCameras[0].fpFlags(_rCameras[0].camera, @selector(viewingFlags)) | EGW_BNDOBJ_BINDFLG_DFLT));
        }
    }
    
    // Move items from outer queue into internal queue system
    if(_requestList.eCount > 0) {
        if(pthread_mutex_trylock(&_rLock) == 0) {
            if(_requestList.eCount > 0) {
                if(egwArrayEnumerateStart(&_requestList, EGW_ITERATE_MODE_DFLT, &workReqIter)) {
                    while((workReq = (egwRenderingWorkReq*)egwArrayEnumerateNextPtr(&workReqIter))) {
                        if(workReq->flags & EGW_GFXRNDRR_RNDRQUEUE_INSERT) { // Insert into the queues
                            if(!workReq->rJmpT->fpRendering(workReq->object, @selector(isRendering))) {
                                workReq->rJmpT->fpRender(workReq->object, @selector(renderWithFlags:), EGW_GFXOBJ_RPLYFLG_DORENDERSTART);
                                egwValidater* rSync = workReq->rJmpT->fpRSync(workReq->object, @selector(renderingSync));; // weak! (rbAdd CB will do retain)
                                
                                // NOTE: New sort descriptor validates sync, will possibly cause ObjTree entrance, but is fine to do now since this is an initial call-through. -jw 
                                // NOTE: Validation will spark an orientation update, if pending, this must happen before the sort descriptor is built -jw 
                                egwSFPVldtrValidate(rSync, @selector(validate));
                                
                                for(qIndex = 0; qIndex < 8; ++qIndex) {
                                    if(workReq->flags & (EGW_GFXRNDRR_RNDRQUEUE_FIRSTPASS << qIndex)) {
                                        egwRenderingWorkItem newWorkItem; memset((void*)&newWorkItem, 0, sizeof(egwRenderingWorkItem)); 
                                        newWorkItem.object = workReq->object; // weak! (rbAdd CB will do retain)
                                        newWorkItem.sync = rSync; // weak! (rbAdd CB will do retain)
                                        newWorkItem.qIndex = qIndex;
                                        newWorkItem.rJmpT = workReq->rJmpT;
                                        
                                        egwRWIUpdate(&newWorkItem, &_rCameras[qIndex]); // sort descriptor must be set before insert into rbTree
                                        
                                        egwRBTreeAdd(&_rQueues[qIndex], (const EGWbyte*)&newWorkItem); // contents copy-over (+ retain due to CB)
                                    }
                                }
                            } else { // Send start message (restart trick), but skip enque
                                workReq->rJmpT->fpRender(workReq->object, @selector(renderWithFlags:), EGW_GFXOBJ_RPLYFLG_DORENDERSTART);
                            }
                        } else if(workReq->flags & EGW_GFXRNDRR_RNDRQUEUE_REMOVE) { // Remove from the queues
                            // NOTE: Resync invalidation below (pre frame check) will remove this object instead since removing it now would require O(n) for a full item lookup. -jw
                            if(workReq->rJmpT->fpRendering(workReq->object, @selector(isRendering)))
                                workReq->rJmpT->fpSetRFrame(workReq->object, @selector(setRenderingFrame:), EGW_FRAME_ALWAYSFAIL);
                        } else if(workReq->flags & EGW_GFXRNDRR_RNDRQUEUE_PAUSE) { // Pause/resume in the queues
                            if(workReq->rJmpT->fpRendering(workReq->object, @selector(isRendering)))
                                workReq->rJmpT->fpRender(workReq->object, @selector(renderWithFlags:), EGW_GFXOBJ_RPLYFLG_DORENDERPAUSE);
                        }
                    }
                    
                    egwArrayRemoveAll(&_requestList);
                }
            }
            
            pthread_mutex_unlock(&_rLock);
        }
    }
    
    // First pass: Perform PRE frame check, resync objects.
    
    {   BOOL updateSortDescWithViewingCameraOverride = NO;
        EGWuint16 rFrame;
        
        if(_params.mode & EGW_GFXRNDRR_RNDRMODE_FRAMECHECK)
            rFrame = egwAFPGfxCntxRenderingFrame(egwAIGfxCntx, @selector(renderingFrame));
        else rFrame = EGW_FRAME_ALWAYSPASS;
        
        for(qIndex = 0; qIndex < 8; ++qIndex) {
            // If the camera for the pass invalidates, then nothing is considered sorted anymore
            if(_params.mode & EGW_GFXRNDRR_RNDRMODE_DEFERRED && _rCameras[qIndex].camera && egwSFPVldtrIsInvalidated(_rCameras[qIndex].sync, @selector(isInvalidated)))
                updateSortDescWithViewingCameraOverride = YES;
            
            if(egwRBTreeEnumerateStart(&_rQueues[qIndex], EGW_ITERATE_MODE_BSTLSR, &workItmIter)) {
                while((workItem = (egwRenderingWorkItem*)egwRBTreeEnumerateNextPtr(&workItmIter))) {
                    if(workItem->tFrame != _tFrame) {
                        workObject = workItem->object;
                        
                        workItem->tFlags = EGW_RDRWRKITMFLG_NONE;
                        
                        // Remove out-of-date objects from queue
                        wItmRFrame = workItem->rJmpT->fpRFrame(workObject, @selector(renderingFrame));
						if(((rFrame != EGW_FRAME_ALWAYSPASS && wItmRFrame != EGW_FRAME_ALWAYSPASS && wItmRFrame != rFrame) ||
                            wItmRFrame == EGW_FRAME_ALWAYSFAIL || rFrame == EGW_FRAME_ALWAYSFAIL) ||
                           !workItem->rJmpT->fpRendering(workObject, @selector(isRendering))) {
                            workItem->rJmpT->fpRender(workObject, @selector(renderWithFlags:), EGW_GFXOBJ_RPLYFLG_DORENDERSTOP);
                            
                            workItem->tFlags |= EGW_RDRWRKITMFLG_DELETE; 
                            if(!((workItem->tFlags & ~EGW_RDRWRKITMFLG_DELETE) & EGW_RDRWRKITMFLG_ATPMASK)) 
                                egwArrayAddTail(&_pendingList, (const EGWbyte*)&workItem); // save for remove, pointer copy-over
                            
                            continue;
                        }
                        
                        // Validate & set sort descriptor for deferred mode
                        if(updateSortDescWithViewingCameraOverride || egwSFPVldtrIsInvalidated(workItem->sync, @selector(isInvalidated))) {
                            // NOTE: Validation here could mess up other queues -> saved for later to catch all invalidations. -jw
                            // NOTE: If updateSortDescOverride is high, then yes, we do a lot of array copies. -jw
                            
                            workItem->tFlags |= EGW_RDRWRKITMFLG_RESORT;
                            if(!((workItem->tFlags & ~EGW_RDRWRKITMFLG_RESORT) & EGW_RDRWRKITMFLG_ATPMASK))
                                egwArrayAddTail(&_pendingList, (const EGWbyte*)&workItem); // save for resort / validation, pointer copy-over
                        }
                        
                        workItem->tFrame = _tFrame;
                    }
                }
            }
            
            updateSortDescWithViewingCameraOverride = NO;
        }
        
        // Tree needs to be modified before second pass to reflect removes, sort desc updates, etc
        // NOTE: This is done outside of the inner loop iteration since tree contents cannot be modified while being walked. -jw
        while(_pendingList.eCount) {
            --_pendingList.eCount;
            egwRenderingWorkItem* workItem = ((egwRenderingWorkItem**)(_pendingList.rData))[_pendingList.eCount];
            
            if(workItem->tFlags & EGW_RDRWRKITMFLG_DELETE)
                egwRBTreeRemove(&_rQueues[workItem->qIndex], egwRBTreeNodePtr((const EGWbyte*)workItem));
            else {
                if(workItem->tFlags & EGW_RDRWRKITMFLG_RESORT) {
                    // NOTE: Validation will spark an orientation update, if pending, this must happen before the sort descriptor is built -jw
                    egwSFPVldtrValidate(workItem->sync, @selector(validate)); // NOTE: This may be a redundent call if on several queues -jw
                    
                    if(egwRWIUpdate(workItem, &_rCameras[qIndex]))
                        egwRBTreeResortElement(&_rQueues[workItem->qIndex], egwRBTreeNodePtr((const EGWbyte*)workItem));
                    
                    workItem->tFlags &= ~EGW_RDRWRKITMFLG_RESORT;
                }
            }
        }
    }
    
    // Handle cancellation
    if(_doShutdown) goto TaskBreak;
    
    // Second pass: Perform render passes.
    
    {   BOOL sameLastBase = NO;
        EGWuint32 replyFlags;
        
        for(qIndex = 0; qIndex < 8; ++qIndex) {
            replyFlags = _rReplies[qIndex]
                         | (((EGWuint)_alphaMods[qIndex] << EGW_GFXOBJ_RPLYFLG_ALPHAMODSHFT) & EGW_GFXOBJ_RPLYFLG_ALPHAMODMASK)
                         | (((EGWuint)_shadeMods[qIndex] << EGW_GFXOBJ_RPLYFLG_SHADEMODSHFT) & EGW_GFXOBJ_RPLYFLG_SHADEMODMASK);
            
            if(egwRBTreeEnumerateStart(&_rQueues[qIndex], EGW_ITERATE_MODE_BSTLSR, &workItmIter)) {
                if(_rCameras[qIndex].camera) {
                    egwAFPGfxCntxSetActiveCamera(egwAIGfxCntx, @selector(setActiveCamera:), _rCameras[qIndex].camera);
                    if(egwSFPVldtrIsInvalidated(_rCameras[qIndex].sync, @selector(isInvalidated)))
                        _rCameras[qIndex].fpBind(_rCameras[qIndex].camera, @selector(bindForRenderingWithFlags:), (_rCameras[qIndex].fpFlags(_rCameras[qIndex].camera, @selector(viewingFlags)) | EGW_BNDOBJ_BINDFLG_DFLT));
                } else continue; // no camera, no pass
                
                while((workItem = (egwRenderingWorkItem*)egwRBTreeEnumerateNextPtr(&workItmIter))) {
                    workObject = workItem->object;
                    
                    // Handle sameLastBase/_lBase tracking
                    sameLastBase = (_lBase && _lBase == workItem->rJmpT->fpRBase(workObject, @selector(renderingBase))) ? YES : NO;
                    if(_lBase == nil || !sameLastBase) {
                        [_lBase release];
                        _lBase = [workItem->rJmpT->fpRBase(workObject, @selector(renderingBase)) retain];
                    }
                    
                    // Render renderable object
                    workItem->tFlags |= EGW_RDRWRKITMFLG_RANPASS;
                    workItem->rJmpT->fpRender(workObject, @selector(renderWithFlags), replyFlags | (sameLastBase ? EGW_GFXOBJ_RPLYFLG_SAMELASTBASE : 0));
                }
            }
            
            if(_params.mode & EGW_GFXRNDRR_RNDRMODE_IMMEDIATE)
                break;
        }
    }
    
    // Handle cancellation
    if(_doShutdown) goto TaskBreak;
    
    // Done with runthrough, do post-processing
    if(_doPostprocessing) {
        _doPostprocessing = NO;
        
        [_lBase release]; _lBase = nil;
        
        egwAFPGfxCntxEndRender(egwAIGfxCntx, @selector(endRender));
        
        if(_modChange && (_rReplies[0] & EGW_GFXOBJ_RPLYFLG_APISYNCINVLD)) {
            _rReplies[0] &= ~EGW_GFXOBJ_RPLYFLG_APISYNCINVLD;
            _rReplies[1] &= ~EGW_GFXOBJ_RPLYFLG_APISYNCINVLD;
            _rReplies[2] &= ~EGW_GFXOBJ_RPLYFLG_APISYNCINVLD;
            _rReplies[3] &= ~EGW_GFXOBJ_RPLYFLG_APISYNCINVLD;
            _rReplies[4] &= ~EGW_GFXOBJ_RPLYFLG_APISYNCINVLD;
            _rReplies[5] &= ~EGW_GFXOBJ_RPLYFLG_APISYNCINVLD;
            _rReplies[6] &= ~EGW_GFXOBJ_RPLYFLG_APISYNCINVLD;
            _rReplies[7] &= ~EGW_GFXOBJ_RPLYFLG_APISYNCINVLD;
            _modChange = NO;
        }
        
        if(!(_params.mode & EGW_GFXRNDRR_RNDRMODE_PERSISTENT)) {
            egwRBTreeRemoveAll(&_rQueues[0]);
            egwRBTreeRemoveAll(&_rQueues[1]);
            egwRBTreeRemoveAll(&_rQueues[2]);
            egwRBTreeRemoveAll(&_rQueues[3]);
            egwRBTreeRemoveAll(&_rQueues[4]);
            egwRBTreeRemoveAll(&_rQueues[5]);
            egwRBTreeRemoveAll(&_rQueues[6]);
            egwRBTreeRemoveAll(&_rQueues[7]);
        }
        
        // Set up for next run
        _doPreprocessing = YES;
    }
    
TaskBreak:
    // Ensurances (break due to cancellation, etc.)
    if(_amRunning) {
        _amRunning = NO;
        pthread_mutex_unlock(&_qLock);
    }
    
    if(_doShutdown) {
        if(!_doPreprocessing || _doPostprocessing)
            egwAFPGfxCntxInterruptRender(egwAIGfxCntx, @selector(interruptRender));
    }
}

@end

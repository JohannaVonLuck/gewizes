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

/// @file egwSndMixer.m
/// @ingroup geWizES_sys_sndmixer
/// Sound Mixer Implementation.

#import <pthread.h>
#import "egwSndMixer.h"
#import "../sys/egwEngine.h"
#import "../sys/egwTaskManager.h"
#import "../sys/egwSndContext.h"
#import "egwSndContextAL.h" // NOTE: Below code has a dependence on AL.
#import "../math/egwMath.h"
#import "../math/egwVector.h"
#import "../data/egwArray.h"
#import "../data/egwRedBlackTree.h"
#import "../gfx/egwCameras.h"
#import "../misc/egwValidater.h"


egwSndMixer* egwSISndMxr = nil;

// !!!: ***** egwPlaybackWorkItem *****

#define EGW_PBKWRKITM_SORTDESCLEN   14      // Sort description max length
#define EGW_PBWRKITMFLG_NONE        0x00    // No flags
#define EGW_PBWRKITMFLG_DOPLAY      0x01    // Marked item as to do play
#define EGW_PBWRKITMFLG_DOPAUSE     0x02    // Marked item as to do pause
#define EGW_PBWRKITMFLG_DOSTOP      0x04    // Marked item as to do stop & remove
#define EGW_PBWRKITMFLG_DOMASK      0x0f    // Marked item to do mask
#define EGW_PBWRKITMFLG_ATPMASK     0xf0    // Playback item adds to pending list mask
#define EGW_PBWRKITMFLG_DELETE      0x10    // Playback item needs deleted
#define EGW_PBWRKITMFLG_RESORT      0x20    // Playback item needs resorted / validated

typedef struct {
	id<egwPPlayable> object;				// Ref to sound object (retained, from flag).
	EGWuint16 flags;                        // Flags for insertion or removal.
    const egwPlayableJumpTable* pJmpT;      // Ref to playable jump table.
} egwPlaybackWorkReq;

typedef struct {
    EGWdouble distFromCam;                  // Distance from camera.
} egwPlaybackWorkItemSortDescriptor;

typedef struct {
    egwPlaybackWorkItemSortDescriptor sortDesc;// Task item sort descriptor.
    EGWuint16 tFrame;                       // Task item frame.
    EGWuint8 tFlags;                        // Task item flags.
	EGWuint8 qIndex;                        // Source queue of item, for insert/resort/remove.
	id<egwPPlayable> object;				// Ref to sound object (retained).
    egwValidater* sync;                     // Ref to validation sync (strong).
    const egwPlayableJumpTable* pJmpT;      // Ref to playable jump table.
} egwPlaybackWorkItem;

EGWint egwPWICompare(egwPlaybackWorkItem* item1, egwPlaybackWorkItem* item2, size_t size) {
    return (item1->sortDesc.distFromCam <= item2->sortDesc.distFromCam + EGW_DFLT_EPSILON ? -1 : 1);
}

void egwPWIAdd(egwPlaybackWorkItem* item) {
    item->pJmpT->fpRetain(item->object, @selector(retain));
    //[item->sync retain];
}

void egwPWIRemove(egwPlaybackWorkItem* item) {
    item->pJmpT->fpRelease(item->object, @selector(release)); item->object = nil;
    //[item->sync release];
    item->sync = nil;
}

EGWint egwPWIUpdate(egwPlaybackWorkItem* item, egwTaskCameraData* lCamera) {
    if(!lCamera->isOrtho) {
        const egwVector4f* itemSource = item->pJmpT->fpPSource(item->object, @selector(playbackSource));
        EGWdouble distFromCam = 
            egwSqrdd((EGWdouble)lCamera->source->axis.x - (EGWdouble)itemSource->axis.x) +
            egwSqrdd((EGWdouble)lCamera->source->axis.y - (EGWdouble)itemSource->axis.y) +
            egwSqrdd((EGWdouble)lCamera->source->axis.z - (EGWdouble)itemSource->axis.z);
        if(!egwIsEquald(item->sortDesc.distFromCam, distFromCam)) {
            item->sortDesc.distFromCam = distFromCam;
            return 1;
        }
    } else {
        EGWdouble distFromCam = (EGWdouble)item->pJmpT->fpPSource(item->object, @selector(playbackSource))->axis.z;
        if(!egwIsEquald(item->sortDesc.distFromCam, distFromCam)) {
            item->sortDesc.distFromCam = distFromCam;
            return 1;
        }
    }
    
    return 0;
}


// !!!: ***** egwSndMixer *****

@implementation egwSndMixer

static egwSndMixer* _singleton = nil;

+ (id)alloc {
    @synchronized(self) {
        if(!_singleton)
            egwSISndMxr = _singleton = [super alloc];
    }
    return _singleton;
}

+ (void)dealloc {
    @synchronized(self) {
        [_singleton release];
        egwSISndMxr = _singleton = nil;
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

- (id)initWithParams:(egwSndMxrParams*)params {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(egwAISndCntx)) {
        NSLog(@"egwSndMixer: initWithParams: Error: Must have an active sound context up and running. YOU'RE DOING IT WRONG!");
        [self release]; return (self = nil);
    }
    
    if(params) memcpy((void*)&_params, (const void*)params, sizeof(egwSndMxrParams));
    if(_params.mode == 0) _params.mode = EGW_SNDMIXER_MIXRMODE_DFLT;
    if(_params.priority == 0.0) _params.priority = EGW_SNDMIXER_DFLTPRIORITY;
    
    _tFrame = 1;
    _amRunning = _doShutdown = NO;
    _gainMods[0] = _gainMods[1] = _gainMods[2] = _gainMods[3] =
        _pitchMods[0] = _pitchMods[1] = _pitchMods[2] = _pitchMods[3] = 100;
    
    // Determine reserved queue slots based on active context's max sound count and mixer mode flag
    { EGWuint maxSources = [egwAISndCntx maxActiveSources];
        if(_params.mode & EGW_SNDMIXER_MIXRMODE_1_50_35_15) {
            _rPBSlots[3] = 1;
            _rPBSlots[2] = (maxSources - 1) / 2; // L0.5
            _rPBSlots[1] = (maxSources - 1) * 7 / 20; // L0.35
            _rPBSlots[0] = maxSources - (_rPBSlots[3] + _rPBSlots[2] + _rPBSlots[1]); // ~0.15
        } else if(_params.mode & EGW_SNDMIXER_MIXRMODE_1_33_33_33) {
            _rPBSlots[3] = 1;
            _rPBSlots[2] = _rPBSlots[1] = (maxSources - 1) / 3; // L0.33
            _rPBSlots[0] = maxSources - (_rPBSlots[3] + _rPBSlots[2] + _rPBSlots[1]); // ~0.33
        } else if(_params.mode & EGW_SNDMIXER_MIXRMODE_2_50_35_15) {
            _rPBSlots[3] = 2;
            _rPBSlots[2] = (maxSources - 2) / 2; // L0.5
            _rPBSlots[1] = (maxSources - 2) * 7 / 20; // L0.35
            _rPBSlots[0] = maxSources - (_rPBSlots[3] + _rPBSlots[2] + _rPBSlots[1]); // ~0.15
        } else if(_params.mode & EGW_SNDMIXER_MIXRMODE_2_33_33_33) {
            _rPBSlots[3] = 2;
            _rPBSlots[2] = _rPBSlots[1] = (maxSources - 2) / 3; // L0.33
            _rPBSlots[0] = maxSources - (_rPBSlots[3] + _rPBSlots[2] + _rPBSlots[1]); // ~0.33
        } else { [self release]; return (self = nil); }
    }
    
    // Allocate queues
	egwDataFuncs callbacks; memset((void*)&callbacks, 0, sizeof(egwDataFuncs));
    callbacks.fpCompare = (EGWcomparefp)&egwPWICompare;
    callbacks.fpAdd = (EGWelementfp)&egwPWIAdd;
    callbacks.fpRemove = (EGWelementfp)&egwPWIRemove;
    if(!(egwRBTreeInit(&_pQueues[0], &callbacks, sizeof(egwPlaybackWorkItem), EGW_TREE_FLG_DFLT))) { [self release]; return (self = nil); }
    if(!(egwRBTreeInit(&_pQueues[1], &callbacks, sizeof(egwPlaybackWorkItem), EGW_TREE_FLG_DFLT))) { [self release]; return (self = nil); }
    if(!(egwRBTreeInit(&_pQueues[2], &callbacks, sizeof(egwPlaybackWorkItem), EGW_TREE_FLG_DFLT))) { [self release]; return (self = nil); }
    if(!(egwRBTreeInit(&_pQueues[3], &callbacks, sizeof(egwPlaybackWorkItem), EGW_TREE_FLG_DFLT))) { [self release]; return (self = nil); }
    if(!(egwArrayInit(&_pendingList, NULL, sizeof(void*), 10, (EGW_ARRAY_FLG_GROWBY10 | EGW_ARRAY_FLG_GRWCND100 | EGW_ARRAY_FLG_SHRNKBY2X)))) { [self release]; return (self = nil); }
    if(!(egwArrayInit(&_requestList, NULL, sizeof(egwPlaybackWorkReq), 10, (EGW_ARRAY_FLG_GROWBY10 | EGW_ARRAY_FLG_GRWCND100 | EGW_ARRAY_FLG_SHRNKBY2X | EGW_ARRAY_FLG_RETAIN)))) { [self release]; return (self = nil); }
    
    // Allocate mutex lock
    if(pthread_mutex_init(&_qLock, NULL)) { [self release]; return (self = nil); }
    if(pthread_mutex_init(&_rLock, NULL)) { [self release]; return (self = nil); }
    
    // Associated instance with active context
    if(!(egwAISndCntx && [egwAISndCntx associateTask:self])) { [self release]; return (self = nil); }
    
    if(EGW_ENGINE_MANAGERS_STARTUPMSGS) NSLog(@"egwSndMixer: initWithParams: Sound mixer has been initialized.");
    
    return self;
}

- (void)dealloc {
    [self shutDownTask];
    
    [_lBase release]; _lBase = nil;
    egwArrayFree(&_pendingList);
    egwArrayFree(&_requestList);
    [_lCamera.camera release]; _lCamera.camera = nil;
    [_lCamera.sync release]; _lCamera.sync = nil;
    _lCamera.source = NULL;
    _lCamera.fpBind = (BOOL(*)(id, SEL, EGWuint))NULL;
    _lCamera.fpFlags = (EGWuint(*)(id, SEL))NULL;
    _lCamera.isOrtho = NO;
    egwRBTreeFree(&_pQueues[3]);
    egwRBTreeFree(&_pQueues[2]);
    egwRBTreeFree(&_pQueues[1]);
	egwRBTreeFree(&_pQueues[0]);
    pthread_mutex_destroy(&_qLock);
    pthread_mutex_destroy(&_rLock);
    
    [super dealloc];
}

- (void)playObject:(id<egwPPlayable>)playableObject {
    if(playableObject) {
        egwPlaybackWorkReq workItemReq;
        workItemReq.pJmpT = [playableObject playableJumpTable];
        
        EGWuint32 pFlags = workItemReq.pJmpT->fpPFlags(playableObject, @selector(playbackFlags));
        
        // Special case: music sounds can always wait
        if((pFlags & EGW_SNDOBJ_PLAYFLG_MUSIC) && !(pFlags & EGW_SNDOBJ_PLAYFLG_CANWAIT))
            [playableObject setPlaybackFlags:(pFlags |= EGW_SNDOBJ_PLAYFLG_CANWAIT)];
        
        if(!(pFlags & EGW_SNDMIXER_MIXRQUEUE_ALL)) // idiot proofing
            pFlags |= EGW_SNDMIXER_MIXRQUEUE_MEDPRI;
        
        if(_params.mode & EGW_SNDMIXER_MIXRMODE_FRAMECHECK)
            workItemReq.pJmpT->fpSetPFrame(playableObject, @selector(setPlaybackFrame:), egwAFPSndCntxPlaybackFrame(egwAISndCntx, @selector(playbackFrame)));
        
        workItemReq.object = playableObject; // weak, retained on add
        workItemReq.flags = EGW_SNDMIXER_MIXRQUEUE_INSERT;
        
        // NOTE: This code is only valid for mixer, where sounds are delegated to JUST one queue (no multi-queue). -jw
        if(pFlags & EGW_SNDOBJ_PLAYFLG_MUSIC)
            workItemReq.flags |= EGW_SNDMIXER_MIXRQUEUE_MUSIC;
        else if(pFlags & EGW_SNDOBJ_PLAYFLG_HIGHPRI)
            workItemReq.flags |= EGW_SNDMIXER_MIXRQUEUE_HIGHPRI;
        else if(pFlags & EGW_SNDOBJ_PLAYFLG_MEDPRI)
            workItemReq.flags |= EGW_SNDMIXER_MIXRQUEUE_MEDPRI;
        else if(pFlags & EGW_SNDOBJ_PLAYFLG_LOWPRI)
            workItemReq.flags |= EGW_SNDMIXER_MIXRQUEUE_LOWPRI;
        
        // Lock mutex and add to request queue
        pthread_mutex_lock(&_rLock);
        egwArrayAddTail(&_requestList, (const EGWbyte*)&workItemReq);
        pthread_mutex_unlock(&_rLock);
    }
}

- (void)pauseObject:(id<egwPPlayable>)playableObject {
    if(playableObject) {
        egwPlaybackWorkReq workItemReq;
        workItemReq.pJmpT = [playableObject playableJumpTable];
        
        workItemReq.object = playableObject; // weak, retained on add
        workItemReq.flags = EGW_SNDMIXER_MIXRQUEUE_PAUSE;
        
        // Lock mutex and add to request queue
        pthread_mutex_lock(&_rLock);
        egwArrayAddTail(&_requestList, (const EGWbyte*)&workItemReq);
        pthread_mutex_unlock(&_rLock);
    }
}

- (void)removeObject:(id<egwPPlayable>)playableObject {
    if(playableObject) {
        egwPlaybackWorkReq workItemReq;
        workItemReq.pJmpT = [playableObject playableJumpTable];
        
        workItemReq.object = playableObject; // weak, retained on add
        workItemReq.flags = EGW_SNDMIXER_MIXRQUEUE_REMOVE;
        
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
                
                if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwSndMixer: shutDownTask: Shutting down sound mixer.");
                
                [egwSITaskMngr unregisterAllTasksUsing:self];
                
                // Wait for running status to deactivate
                if(_amRunning) {
                    NSDate* waitTill = [[NSDate alloc] initWithTimeIntervalSinceNow:(NSTimeInterval)EGW_ENGINE_MANAGERS_TIMETOWAIT];
                    while(_amRunning) {
                        if([waitTill timeIntervalSinceNow] < (NSTimeInterval)0.0) {
                            NSLog(@"egwSndMixer: shutDownTask: Failure waiting for running status to deactivate.");
                            break;
                        }
                        
                        [NSThread sleepForTimeInterval:EGW_ENGINE_MANAGERS_TIMETOSLEEP];
                    }
                    [waitTill release];
                }
                
                [_lBase release]; _lBase = nil;
                egwArrayFree(&_pendingList);
                egwArrayFree(&_requestList);
                [_lCamera.camera release]; _lCamera.camera = nil;
                [_lCamera.sync release]; _lCamera.sync = nil;
                _lCamera.source = NULL;
                _lCamera.fpBind = (BOOL(*)(id, SEL, EGWuint))NULL;
                _lCamera.fpFlags = (EGWuint(*)(id, SEL))NULL;
                _lCamera.isOrtho = NO;
                egwRBTreeFree(&_pQueues[3]);
                egwRBTreeFree(&_pQueues[2]);
                egwRBTreeFree(&_pQueues[1]);
                egwRBTreeFree(&_pQueues[0]);
                
                // Done last due to potential to have self dealloc'ed immediately afterwords
                [egwAISndCntx deassociateTask:self];
                
                if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwSndMixer: shutDownTask: Sound mixer shut down.");
            }
        }
    }
}

- (id<egwPCamera>)listenerCamera {
    return _lCamera.camera;
}

- (double)taskPriority {
    return _params.priority;
}

- (void)setListenerCamera:(id<egwPCamera>)camera {
    [camera retain];
    [_lCamera.camera release];
    _lCamera.camera = camera;
    [_lCamera.sync release];
    _lCamera.sync = [[camera playbackSync] retain];
    _lCamera.source = [camera viewingSource];
    _lCamera.fpBind = (BOOL(*)(id, SEL, EGWuint))[(NSObject*)camera methodForSelector:@selector(bindForPlaybackWithFlags:)];
    _lCamera.fpFlags = (EGWuint(*)(id, SEL))[(NSObject*)camera methodForSelector:@selector(viewingFlags)];
    _lCamera.isOrtho = [camera isKindOfClass:[egwOrthogonalCamera class]];
}

- (void)setGainModifier:(EGWuint8)gainMod forQueue:(EGWuint)queueIdent {
    pthread_mutex_lock(&_qLock);
    
    if(queueIdent & EGW_SNDMIXER_MIXRQUEUE_MUSIC)
        _gainMods[3] = gainMod;
    if(queueIdent & EGW_SNDMIXER_MIXRQUEUE_HIGHPRI)
        _gainMods[2] = gainMod;
    if(queueIdent & EGW_SNDMIXER_MIXRQUEUE_MEDPRI)
        _gainMods[1] = gainMod;
    if(queueIdent & EGW_SNDMIXER_MIXRQUEUE_LOWPRI)
        _gainMods[0] = gainMod;
    
    _modChange = YES;
    
    pthread_mutex_unlock(&_qLock);
}

- (void)setPitchModifier:(EGWuint8)pitchMod forQueue:(EGWuint)queueIdent {
    pthread_mutex_lock(&_qLock);
    
    if(queueIdent & EGW_SNDMIXER_MIXRQUEUE_MUSIC)
        _pitchMods[3] = pitchMod;
    if(queueIdent & EGW_SNDMIXER_MIXRQUEUE_HIGHPRI)
        _pitchMods[2] = pitchMod;
    if(queueIdent & EGW_SNDMIXER_MIXRQUEUE_MEDPRI)
        _pitchMods[1] = pitchMod;
    if(queueIdent & EGW_SNDMIXER_MIXRQUEUE_LOWPRI)
        _pitchMods[0] = pitchMod;
    
    _modChange = YES;
    
    pthread_mutex_unlock(&_qLock);
}

- (void)setMute:(BOOL)status {
	pthread_mutex_lock(&_qLock);
	
    _isMuted = status;
    
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
    return NO;
}

- (void)performTask {
    egwPlaybackWorkItem* workItem = nil;
    egwPlaybackWorkReq* workReq = nil;
	egwRedBlackTreeIter workItmIter;
    id<egwPPlayable> workObject = nil;
    BOOL updateSortDescOverride = NO;
    EGWuint16 pFrame = EGW_FRAME_ALWAYSPASS;
    EGWuint availPBSlots, rsrvdPBSlots[4] = { 0, 0, 0, 0 };
    egwRedBlackTreeIter startLOSIndex[4]; memset((void*)&startLOSIndex, 0, sizeof(egwRedBlackTreeIter) * 4);
	EGWint qIndex;
    EGWuint16 wItmPFrame;
    EGWuint32 wItmPFlags;
    
    if(_doShutdown) goto TaskBreak;
    pthread_mutex_lock(&_qLock);
    _amRunning = YES;
    
    if(++_tFrame == EGW_FRAME_ALWAYSFAIL) _tFrame = 1;
    
    // Start playback frame runthrough, do pre-processing
    if(!egwAFPSndCntxActive(egwAISndCntx, @selector(isActive)))
        egwAFPSndCntxMakeActive(egwAISndCntx, @selector(makeActive));
    
    egwAFPSndCntxPerformSubTasks(egwAISndCntx, @selector(performSubTasks));
    
    rsrvdPBSlots[3] = _rPBSlots[3]; // music
    rsrvdPBSlots[2] = _rPBSlots[2]; // high
    rsrvdPBSlots[1] = _rPBSlots[1]; // med
    rsrvdPBSlots[0] = _rPBSlots[0]; // low
    
    // Move items from outer queue into internal queue system
    if(_requestList.eCount > 0) {
        if(pthread_mutex_trylock(&_rLock) == 0) {
            if(_requestList.eCount > 0) {
                egwArrayIter workReqIter;
                
                if(egwArrayEnumerateStart(&_requestList, EGW_ITERATE_MODE_DFLT, &workReqIter)) {
                    while((workReq = (egwPlaybackWorkReq*)egwArrayEnumerateNextPtr(&workReqIter))) {
                        if(workReq->flags & EGW_SNDMIXER_MIXRQUEUE_INSERT) { // Insert into the queues
                            if(!workReq->pJmpT->fpPlaying(workReq->object, @selector(isPlaying))) {
                                workReq->pJmpT->fpPlay(workReq->object, @selector(playWithFlags:), EGW_SNDOBJ_RPLYFLG_DOPLYBCKSTART);
                                egwValidater* pSync = workReq->pJmpT->fpPSync(workReq->object, @selector(playbackSync));; // weak! (rbAdd CB will do retain)
                                
                                // NOTE: New sort descriptor validates sync, will possibly cause ObjTree entrance, but is fine to do now since this is an initial call-through. -jw 
                                // NOTE: Validation will spark an orientation update, if pending, this must happen before the sort descriptor is built -jw 
                                egwSFPVldtrValidate(pSync, @selector(validate));
                                
                                for(qIndex = 3; qIndex >= 0; --qIndex) {
                                    if(workReq->flags & (EGW_SNDMIXER_MIXRQUEUE_LOWPRI << qIndex)) {
                                        egwPlaybackWorkItem newWorkItem; memset((void*)&newWorkItem, 0, sizeof(egwPlaybackWorkItem));
                                        newWorkItem.object = workReq->object; // weak! (rbAdd CB will do retain)
                                        newWorkItem.sync = pSync; // weak! (rbAdd CB will do retain)
                                        newWorkItem.qIndex = qIndex;
                                        newWorkItem.pJmpT = workReq->pJmpT;
                                        
                                        egwPWIUpdate(&newWorkItem, &_lCamera); // sort descriptor must be set before insert into rbTree
                                        
                                        egwRBTreeAdd(&_pQueues[qIndex], (const EGWbyte*)&newWorkItem); // contents copy-over (+ retain due to CB)
                                    }
                                }
                            } else { // Send start message (restart trick), but skip enque
                                workReq->pJmpT->fpPlay(workReq->object, @selector(playWithFlags:), EGW_SNDOBJ_RPLYFLG_DOPLYBCKSTART);
                            }
                        } else if(workReq->flags & EGW_SNDMIXER_MIXRQUEUE_REMOVE) { // Remove from the queues
                            // NOTE: Resync invalidation below (pre frame check) will remove this object instead since removing it now would require O(n) for a full item lookup. -jw
                            if(workReq->pJmpT->fpPlaying(workReq->object, @selector(isPlaying)))
                                workReq->pJmpT->fpSetPFrame(workReq->object, @selector(setPlaybackFrame:), EGW_FRAME_ALWAYSFAIL);
                        } else if(workReq->flags & EGW_SNDMIXER_MIXRQUEUE_PAUSE) { // Pause/resume in the queues
                            if(workReq->pJmpT->fpPlaying(workReq->object, @selector(isPlaying)))
                                workReq->pJmpT->fpPlay(workReq->object, @selector(playWithFlags:), EGW_SNDOBJ_RPLYFLG_DOPLYBCKPAUSE);
                        }
                    }
                    
                    egwArrayRemoveAll(&_requestList);
                }
            }
            
            pthread_mutex_unlock(&_rLock);
        }
    }
        
    // First pass: Perform PRE frame check, update playback, remove finished, resync objects.
    
    // If the camera for the pass invalidates, then nothing is considered sorted anymore
    if((_params.mode & EGW_SNDMIXER_MIXRMODE_DEFERRED) && (_lCamera.camera && egwSFPVldtrIsInvalidated([_lCamera.camera playbackSync], @selector(isInvalidated))))
        updateSortDescOverride = YES;
    
    // Update the listener
    egwAFPSndCntxSetActiveCamera(egwAISndCntx, @selector(setActiveCamera:), _lCamera.camera); // May invalidate listener cam
    if(_lCamera.camera && egwSFPVldtrIsInvalidated(_lCamera.sync, @selector(isInvalidated)))
        _lCamera.fpBind(_lCamera.camera, @selector(bindForPlaybackWithFlags:), (_lCamera.fpFlags(_lCamera.camera, @selector(viewingFlags)) | EGW_BNDOBJ_BINDFLG_DFLT));
    
    if(_params.mode & EGW_SNDMIXER_MIXRMODE_FRAMECHECK)
        pFrame = egwAFPSndCntxPlaybackFrame(egwAISndCntx, @selector(playbackFrame));
    else pFrame = EGW_FRAME_ALWAYSPASS;
    
	for(qIndex = 3; qIndex >= 0; --qIndex) {
		if(egwRBTreeEnumerateStart(&_pQueues[qIndex], EGW_ITERATE_MODE_BSTLSR, &workItmIter)) {
			while((workItem = (egwPlaybackWorkItem*)egwRBTreeEnumerateNextPtr(&workItmIter))) {
                if(workItem->tFrame != _tFrame) {
                    workObject = workItem->object;
                    
                    workItem->tFlags = EGW_PBWRKITMFLG_NONE;
                    
                    // Remove out-of-date objects from queue
                    wItmPFrame = workItem->pJmpT->fpPFrame(workObject, @selector(playbackFrame));
                    if(((pFrame != EGW_FRAME_ALWAYSPASS && wItmPFrame != EGW_FRAME_ALWAYSPASS && wItmPFrame != pFrame) ||
                        wItmPFrame == EGW_FRAME_ALWAYSFAIL || pFrame == EGW_FRAME_ALWAYSFAIL) ||
                       !workItem->pJmpT->fpPlaying(workObject, @selector(isPlaying)) ||
                       workItem->pJmpT->fpFinished(workObject, @selector(isFinished))) { // NOTE: Loopers never signal their isFinished flag, so this is a safe op. -jw
                        workItem->pJmpT->fpPlay(workObject, @selector(playWithFlags:), EGW_SNDOBJ_RPLYFLG_DOPLYBCKSTOP); // ensures source release
                        
                        workItem->tFlags |= EGW_PBWRKITMFLG_DELETE;
                        if(!((workItem->tFlags & ~EGW_PBWRKITMFLG_DELETE) & EGW_PBWRKITMFLG_ATPMASK))
                            egwArrayAddTail(&_pendingList, (const EGWbyte*)&workItem); // save for remove, pointer copy-over
                        
                        continue;
                    }
                    
                    // Validate & set sort descriptor for deferred mode
                    if(updateSortDescOverride || egwSFPVldtrIsInvalidated(workItem->sync, @selector(isInvalidated))) {
                        // NOTE: Validation here could mess up other queues -> saved for later to catch all invalidations. -jw
                        // NOTE: If updateSortDescOverride is high, then yes, we do a lot of array copies. -jw
                        
                        workItem->tFlags |= EGW_PBWRKITMFLG_RESORT;
                        if(!((workItem->tFlags & ~EGW_PBWRKITMFLG_RESORT) & EGW_PBWRKITMFLG_ATPMASK))
                            egwArrayAddTail(&_pendingList, (const EGWbyte*)&workItem); // save for resort / validation, pointer copy-over
                    }
                    
                    workItem->tFrame = _tFrame;
                }
			}
		}
	}
	updateSortDescOverride = NO;
    
	// Tree needs to be modified before second pass to reflect removes, sort desc updates, etc
    // NOTE: This is done outside of the inner loop iteration since tree contents cannot be modified while being walked. -jw
	while(_pendingList.eCount) {
		--_pendingList.eCount;
        egwPlaybackWorkItem* workItem = ((egwPlaybackWorkItem**)(_pendingList.rData))[_pendingList.eCount];
        
        if(workItem->tFlags & EGW_PBWRKITMFLG_DELETE)
			egwRBTreeRemove(&_pQueues[workItem->qIndex], egwRBTreeNodePtr((const EGWbyte*)workItem));
        else {
            if(workItem->tFlags & EGW_PBWRKITMFLG_RESORT) {
                // NOTE: Validation will spark an orientation update, if pending, this must happen before the sort descriptor is built -jw
                egwSFPVldtrValidate(workItem->sync, @selector(validate)); // NOTE: This may be a redundent call if on several queues -jw
                
                if(egwPWIUpdate(workItem, &_lCamera))
                    egwRBTreeResortElement(&_pQueues[workItem->qIndex], egwRBTreeNodePtr((const EGWbyte*)workItem));
                
                workItem->tFlags &= ~EGW_PBWRKITMFLG_RESORT;
            }
        }
	}
    
    // Handle cancellation
    if(_doShutdown) goto TaskBreak;
    
	// Second pass: Enqueue sounds while there are reserved slots available for them
    
	for(qIndex = 3; qIndex >= 0; --qIndex) {
		if(egwRBTreeEnumerateStart(&_pQueues[qIndex], EGW_ITERATE_MODE_BSTLSR, &workItmIter)) {
			while(rsrvdPBSlots[qIndex] && (workItem = (egwPlaybackWorkItem*)egwRBTreeEnumerateNextPtr(&workItmIter))) {
				workObject = workItem->object;
				
                // Mark item as do-play
				workItem->tFlags |= EGW_PBWRKITMFLG_DOPLAY;
                
				--rsrvdPBSlots[qIndex];
			}
			
			// Keep track of left over start iterator for later
			memcpy((void*)&startLOSIndex[qIndex], (const void*)&workItmIter, sizeof(egwRedBlackTreeIter));
			
			// Special case: Pause/stop any extra sounds playing in _pQueues[3]
			if(&_pQueues[qIndex] == &_pQueues[3]) {
				while((workItem = (egwPlaybackWorkItem*)egwRBTreeEnumerateNextPtr(&workItmIter))) {
					workObject = workItem->object;
					
					if(workItem->pJmpT->fpSourced(workObject, @selector(isSourced))) { // If not sourced, it can just hang out on the queue (since all musics are can-waits)
                        wItmPFlags = workItem->pJmpT->fpPFlags(workObject, @selector(playbackFlags));
                        
						if(wItmPFlags & EGW_SNDOBJ_PLAYFLG_AUTOPAUSE)
                            workItem->tFlags |= EGW_PBWRKITMFLG_DOPAUSE;
                        else
                            workItem->tFlags |= EGW_PBWRKITMFLG_DOSTOP;
					}
				}
			}
		}
	}
    
	// Handle cancellation
    if(_doShutdown) goto TaskBreak;
    
    // Third pass: Enqueue sounds that are can't-waits (taking priority over can-waits) while we have leftover slots available otherwise remove (excluding _pQueues[3])
    
    // NOTE: From this point onwards, only available PB slots need to be cared for
    availPBSlots = rsrvdPBSlots[0] + rsrvdPBSlots[1] + rsrvdPBSlots[2] + rsrvdPBSlots[3];
    
	for(qIndex = 2; qIndex >= 0; --qIndex) {
		memcpy((void*)&workItmIter, (const void*)&startLOSIndex[qIndex], sizeof(egwRedBlackTreeIter)); // pickup from left off spot in second pass
        
		while((workItem = (egwPlaybackWorkItem*)egwRBTreeEnumerateNextPtr(&workItmIter))) {
			workObject = workItem->object;
			wItmPFlags = workItem->pJmpT->fpPFlags(workObject, @selector(playbackFlags));
			
            if(workItem->pJmpT->fpSourced(workObject, @selector(isSourced))) {
				if(availPBSlots && !(wItmPFlags & EGW_SNDOBJ_PLAYFLG_STRICT)) { // strict sounds won't steal
					// Sound playing + leftover slots available = steal the slot
                    workItem->tFlags |= EGW_PBWRKITMFLG_DOPLAY;
                    
					--availPBSlots;
                } else {
					// Sound playing + no more leftover slots = stop/pause
                    
                    if(wItmPFlags & EGW_SNDOBJ_PLAYFLG_AUTOPAUSE)
                        workItem->tFlags |= EGW_PBWRKITMFLG_DOPAUSE;
                    else
                        workItem->tFlags |= EGW_PBWRKITMFLG_DOSTOP;
				}
			} else {
				if(!(wItmPFlags & EGW_SNDOBJ_PLAYFLG_CANWAIT)) // only worry about can't waits atm
				{
					if(availPBSlots && !(wItmPFlags & EGW_SNDOBJ_PLAYFLG_STRICT)) { // strict sounds won't steal
						// Sound not playing + can't-wait + leftover slots available = steal the slot, enqueue
                        workItem->tFlags |= EGW_PBWRKITMFLG_DOPLAY;
						--availPBSlots;
					} else {
						// Sound not playing + can't-wait + no more leftover slots = stop
						workItem->tFlags |= EGW_PBWRKITMFLG_DOSTOP;
					}
				} 
				// else sound is a can-wait, handled in fourth pass, separate pass to allow remaining can't-waits priority over can waits
			}
		}
	}
    
	// Handle cancellation
    if(_doShutdown) goto TaskBreak;
    
    // Fourth pass: Enqueue sounds that are can waits while we have leftover slots available otherwise remove (excluding _pQueues[3])
    
    for(qIndex = 2; availPBSlots && qIndex >= 0; --qIndex) {
		memcpy((void*)&workItmIter, (const void*)&startLOSIndex[qIndex], sizeof(egwRedBlackTreeIter)); // pickup from left off spot in second pass
        
		while(availPBSlots && (workItem = (egwPlaybackWorkItem*)egwRBTreeEnumerateNextPtr(&workItmIter))) {
            if(!(workItem->tFlags & EGW_PBWRKITMFLG_DOMASK)) { // don't worry about work items already assigned tasks
                workObject = workItem->object;
                wItmPFlags = workItem->pJmpT->fpPFlags(workObject, @selector(playbackFlags));
                
                // NOTE: All sourced (all) and all unsourced (cant-waits only) were all handled in third pass, so the remaining should be only unsourced can waits. -jw
                
                if(!(wItmPFlags & EGW_SNDOBJ_PLAYFLG_STRICT)) { // strict sounds won't steal
                    // Sound not playing + can-wait + leftover slots available = steal the slot, enqueue
                    workItem->tFlags |= EGW_PBWRKITMFLG_DOPLAY;
                    --availPBSlots;
                } // else Sound not playing + can-wait + no more leftover slots = ignore
            }
		} 
	}
    
    // Handle cancellation
    if(_doShutdown) goto TaskBreak;
    
    // Fifth pass: Pause and stop sounds that are marked as do-pause and do-stops, so to releave sources for sixth pass
    
    for(qIndex = 3; qIndex >= 0; --qIndex) {
        if(egwRBTreeEnumerateStart(&_pQueues[qIndex], EGW_ITERATE_MODE_BSTLSR, &workItmIter)) {
			while((workItem = (egwPlaybackWorkItem*)egwRBTreeEnumerateNextPtr(&workItmIter))) {
                workObject = workItem->object;
                
                if(workItem->tFlags & EGW_PBWRKITMFLG_DOSTOP) {
                    workItem->pJmpT->fpPlay(workObject, @selector(playWithFlags:), EGW_SNDOBJ_RPLYFLG_DOPLYBCKSTOP); // releases source
                    
                    workItem->tFlags |= EGW_PBWRKITMFLG_DELETE;
                    if(!((workItem->tFlags & ~EGW_PBWRKITMFLG_DELETE) & EGW_PBWRKITMFLG_ATPMASK))
                        egwArrayAddTail(&_pendingList, (const EGWbyte*)&workItem); // save for remove, pointer copy-over
                } else if(workItem->tFlags & EGW_PBWRKITMFLG_DOPAUSE) {
                    workItem->pJmpT->fpPlay(workObject, @selector(playWithFlags:), EGW_SNDOBJ_RPLYFLG_DOPLYBCKPAUSE); // releases source
                }
            }
        }
    }
    
    // We can now remove elements from the tree manually -jm
	while(_pendingList.eCount) {
		--_pendingList.eCount;
        egwPlaybackWorkItem* workItem = ((egwPlaybackWorkItem**)(_pendingList.rData))[_pendingList.eCount];
        
        if(workItem->tFlags & EGW_PBWRKITMFLG_DELETE)
			egwRBTreeRemove(&_pQueues[workItem->qIndex], egwRBTreeNodePtr((const EGWbyte*)workItem));
    }
    
    // Handle cancellation
    if(_doShutdown) goto TaskBreak;
    
    // Sixth pass: Perform pass on sounds marked as do-plays, can be ran safely now since pauses/stops have released sources
    
    for(qIndex = 3; qIndex >= 0; --qIndex) {
        EGWuint32 replyFlags = EGW_SNDOBJ_RPLYFLY_DOPLYBCKPASS
                               | (_modChange ? EGW_SNDOBJ_RPLYFLG_APISYNCINVLD : 0)
                               | (((EGWuint)(!_isMuted ? _gainMods[qIndex] : 0) << EGW_SNDOBJ_RPLYFLG_GAINMODSHFT) & EGW_SNDOBJ_RPLYFLG_GAINMODMASK)
                               | (((EGWuint)_pitchMods[qIndex] << EGW_SNDOBJ_RPLYFLG_PITCHMODSHFT) & EGW_SNDOBJ_RPLYFLG_PITCHMODMASK);
        
        if(egwRBTreeEnumerateStart(&_pQueues[qIndex], EGW_ITERATE_MODE_BSTLSR, &workItmIter)) {
			while((workItem = (egwPlaybackWorkItem*)egwRBTreeEnumerateNextPtr(&workItmIter))) {
                workObject = workItem->object;
                
                if(workItem->tFlags & EGW_PBWRKITMFLG_DOPLAY) {
                    workItem->pJmpT->fpPlay(workObject, @selector(playWithFlags:), replyFlags); // auto-acquires source
                }
            }
        }
    }
    
TaskBreak:
    // Ensurances (break due to cancellation, etc.)
    if(_modChange)
        _modChange = NO;
    
    if(_amRunning) {
        _amRunning = NO;
        pthread_mutex_unlock(&_qLock);
    }
}

@end

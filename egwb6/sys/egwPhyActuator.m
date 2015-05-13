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

/// @file egwPhyActuator.m
/// @ingroup geWizES_sys_phyactuator
/// Physical Actuator Implementation.

#import <pthread.h>
#import <time.h>
#import "egwPhyActuator.h"
#import "../sys/egwEngine.h"
#import "../sys/egwTaskManager.h"
#import "../sys/egwPhyContext.h"
#import "../data/egwArray.h"
#import "../misc/egwValidater.h"


egwPhyActuator* egwSIPhyAct = nil;


// !!!: ***** egwInteractionWorkItem *****

#define EGW_ITCWRKITM_SORTDESCLEN   14      // Sort description max length
#define EGW_ITCWRKITMFLG_NONE       0x00    // No flags

typedef struct {
	id<NSObject> object;                    // Ref to physics object (retained, from flag).
	EGWuint16 flags;                        // Flags for insertion or removal.
    union {
        const egwInteractableJumpTable* iJmpT;// Ref to interactable jump table.
        const egwActuatorJumpTable* aJmpT;  // Ref to actuator jump table.
    } jmpTbls;
} egwInteractionWorkItemReq;

typedef struct {
    BOOL isAwake;
} egwInteractionWorkItemSortDescriptor;

typedef struct {
    egwInteractionWorkItemSortDescriptor sortDesc;// Task item sort descriptor.
    EGWuint16 tFrame;                       // Task item frame.
    EGWuint8 tFlags;                        // Task item flags.
    EGWuint8 qIndex;                        // Source queue of item, for insert/resort/remove.
    id<NSObject> object;                    // Ref to physical object (retained).
    egwValidater* sync;                     // Ref to validation sync (strong).
    union {
        const egwInteractableJumpTable* iJmpT;  // Ref to interactable jump table.
        const egwActuatorJumpTable* aJmpT;      // Ref to actuator jump table.
    } jmpTbls;
} egwInteractionWorkItem;

EGWint egwIWICompare(egwInteractionWorkItem* item1, egwInteractionWorkItem* item2, size_t size) {
    return (item1->sortDesc.isAwake ? -1 : 1);
}

EGWint egwAWICompare(egwInteractionWorkItem* item1, egwInteractionWorkItem* item2, size_t size) {
    return 0;
}

void egwIWIAdd(egwInteractionWorkItem* item) {
    item->jmpTbls.iJmpT->fpRetain(item->object, @selector(retain));
    //[item->sync retain];
}

void egwIWIRemove(egwInteractionWorkItem* item) {
    item->jmpTbls.iJmpT->fpRelease(item->object, @selector(release)); item->object = nil;
    //[item->sync release];
    item->sync = nil;
}

void egwAWIAdd(egwInteractionWorkItem* item) {
    item->jmpTbls.aJmpT->fpRetain(item->object, @selector(retain));
    //[item->sync retain];
}

void egwAWIRemove(egwInteractionWorkItem* item) {
    item->jmpTbls.aJmpT->fpRelease(item->object, @selector(release)); item->object = nil;
    //[item->sync release];
    item->sync = nil;
}

EGWint egwIWIUpdate(egwInteractionWorkItem* item) {
    {   BOOL isAwake = item->jmpTbls.iJmpT->fpAwake(item->object, @selector(isAwake));
        if(item->sortDesc.isAwake != isAwake) {
            item->sortDesc.isAwake = isAwake;
            return 1;
        }
    }
    
    return 0;
}

EGWint egwAWIUpdate(egwInteractionWorkItem* item) {
    item->sortDesc.isAwake = YES;
    return 0;
}


// !!!: ***** egwPhyActuator *****

@implementation egwPhyActuator

static egwPhyActuator* _singleton = nil;

+ (id)alloc {
    @synchronized(self) {
        if(!_singleton)
            egwSIPhyAct = _singleton = [super alloc];
    }
    return _singleton;
}

+ (void)dealloc {
    @synchronized(self) {
        [_singleton release];
        egwSIPhyAct = _singleton = nil;
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

- (id)initWithParams:(egwPhyActParams*)params {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(egwAIPhyCntx)) {
        NSLog(@"egwPhyActuator: initWithParams: Error: Must have an active physics context up and running. YOU'RE DOING IT WRONG!");
        [self release]; return (self = nil);
    }
    
    if(params) memcpy((void*)&_params, (const void*)params, sizeof(egwPhyActParams));
    if(_params.mode == 0) _params.mode = EGW_PHYACTR_ACTRMODE_DFLT;
    if(_params.priority == 0.0) _params.priority = EGW_PHYACTR_DFLTPRIORITY;
    
    _tFrame = 1;
    _amRunning = _doShutdown = NO;
    _doPreprocessing = YES; _doPostprocessing = NO;
    _deltaT = (EGWtime)0.0;
    _mThrottle = (EGWtime)1.0;
    
    // Allocate queues
    egwDataFuncs callbacks; memset((void*)&callbacks, 0, sizeof(egwDataFuncs));
    callbacks.fpCompare = (EGWcomparefp)&egwIWICompare;
    callbacks.fpAdd = (EGWelementfp)&egwIWIAdd;
    callbacks.fpRemove = (EGWelementfp)&egwIWIRemove;
    if(!(egwSLListInit(&_iQueues[0], &callbacks, sizeof(egwInteractionWorkItem), EGW_LIST_FLG_DFLT))) { [self release]; return (self = nil); }
    if(!(egwSLListInit(&_iQueues[2], &callbacks, sizeof(egwInteractionWorkItem), EGW_LIST_FLG_DFLT))) { [self release]; return (self = nil); }
    callbacks.fpCompare = (EGWcomparefp)&egwAWICompare; // Seperate compare for actuator queue
    callbacks.fpAdd = (EGWelementfp)&egwAWIAdd; // Seperate add for actuator queue
    callbacks.fpRemove = (EGWelementfp)&egwAWIRemove; // Seperate remove for actuator queue
    if(!(egwSLListInit(&_iQueues[1], &callbacks, sizeof(egwInteractionWorkItem), EGW_LIST_FLG_DFLT))) { [self release]; return (self = nil); }
    if(!(egwArrayInit(&_requestList, NULL, sizeof(egwInteractionWorkItemReq), 10, (EGW_ARRAY_FLG_GROWBY10 | EGW_ARRAY_FLG_GRWCND100 | EGW_ARRAY_FLG_SHRNKBY2X | EGW_ARRAY_FLG_RETAIN)))) { [self release]; return (self = nil); }
    _iReplies[0] = EGW_PHYOBJ_RPLYFLG_DOINTRCTPASS | (EGW_PHYOBJ_RPLYFLG_INTRCTPASSMASK & (EGWuint)1);
    _iReplies[1] = EGW_ACTOBJ_RPLYFLG_DOUPDATEPASS;
    _iReplies[2] = EGW_PHYOBJ_RPLYFLG_DOINTRCTPASS | (EGW_PHYOBJ_RPLYFLG_INTRCTPASSMASK & (EGWuint)2);
    
    // Allocate mutex lock
    if(pthread_mutex_init(&_qLock, NULL)) { [self release]; return (self = nil); }
    if(pthread_mutex_init(&_rLock, NULL)) { [self release]; return (self = nil); }
    
    // Associated instance with active context
    if(!(egwAIPhyCntx && [egwAIPhyCntx associateTask:self])) { [self release]; return (self = nil); }
    
    if(EGW_ENGINE_MANAGERS_STARTUPMSGS) NSLog(@"egwPhyActuator: initWithParams: Physical actuator has been initialized.");
    
    return self;
}

- (void)dealloc {
    [self shutDownTask];
    
    [_lBase release]; _lBase = nil;
    #ifndef EGW_PHYACTR_USENSDATE
        _lTime = 0;
    #else
        [_lTime release]; _lTime = nil;
    #endif
    egwArrayFree(&_requestList);
    egwSLListFree(&_iQueues[0]);
    egwSLListFree(&_iQueues[1]);
    egwSLListFree(&_iQueues[2]);
    pthread_mutex_destroy(&_qLock);
    pthread_mutex_destroy(&_rLock);
    
    [super dealloc];
}

- (void)actuateObject:(id<egwPActuator>)actuatorObject {    
    if(actuatorObject) {
        egwInteractionWorkItemReq workItemReq;
        workItemReq.jmpTbls.aJmpT = [actuatorObject actuatorJumpTable];
        
        workItemReq.object = actuatorObject; // weak, retained on add
        workItemReq.flags = EGW_PHYACTR_ACTRQUEUE_INSERT | EGW_PHYACTR_ACTRQUEUE_ACTUATOR;
        
        pthread_mutex_lock(&_rLock);
        egwArrayAddTail(&_requestList, (const EGWbyte*)&workItemReq);
        pthread_mutex_unlock(&_rLock);
    }
}

- (void)interactObject:(id<egwPInteractable>)interactableObject {
    if(interactableObject) {
        egwInteractionWorkItemReq workItemReq;
        workItemReq.jmpTbls.iJmpT = [interactableObject interactableJumpTable];
        
        EGWuint32 uFlags = workItemReq.jmpTbls.iJmpT->fpIFlags(interactableObject, @selector(interactionFlags));
        if(!((uFlags & EGW_PHYACTR_ACTRQUEUE_ALL) & ~EGW_PHYACTR_ACTRQUEUE_ACTUATOR)) // idiot proofing
            uFlags |= EGW_PHYACTR_ACTRQUEUE_MAINPASS;
        
        if(_params.mode & EGW_PHYACTR_ACTRMODE_FRAMECHECK)
            workItemReq.jmpTbls.iJmpT->fpSetIFrame(interactableObject, @selector(setInteractionFrame:), egwAFPPhyCntxInteractionFrame(egwAIPhyCntx, @selector(interactionFrame)));
        
        workItemReq.object = interactableObject; // weak, retained on add
        workItemReq.flags = EGW_PHYACTR_ACTRQUEUE_INSERT | ((uFlags & EGW_PHYACTR_ACTRQUEUE_ALL) & ~EGW_PHYACTR_ACTRQUEUE_ACTUATOR);
        
        pthread_mutex_lock(&_rLock);
        egwArrayAddTail(&_requestList, (const EGWbyte*)&workItemReq);
        pthread_mutex_unlock(&_rLock);
    }
}

- (void)pauseObject:(id<NSObject>)object {
    if(object) {
        egwInteractionWorkItemReq workItemReq;
        
        workItemReq.object = object; // weak, retained on add
        workItemReq.flags = EGW_PHYACTR_ACTRQUEUE_PAUSE;
        
        if([object conformsToProtocol:@protocol(egwPInteractable)]) {
            workItemReq.jmpTbls.iJmpT = [(id<egwPInteractable>)object interactableJumpTable];
            workItemReq.flags |= (EGW_PHYACTR_ACTRQUEUE_ALL & ~EGW_PHYACTR_ACTRQUEUE_ACTUATOR);
        } else {
            workItemReq.jmpTbls.aJmpT = [(id<egwPActuator>)object actuatorJumpTable];
            workItemReq.flags |= EGW_PHYACTR_ACTRQUEUE_ACTUATOR;
        }
        
        pthread_mutex_lock(&_rLock);
        egwArrayAddTail(&_requestList, (const EGWbyte*)&workItemReq);
        pthread_mutex_unlock(&_rLock);
    }
}

- (void)removeObject:(id<NSObject>)object {
    if(object) {
        egwInteractionWorkItemReq workItemReq;
        
        workItemReq.object = object; // weak, retained on add
        workItemReq.flags = EGW_PHYACTR_ACTRQUEUE_REMOVE;
        
        if([object conformsToProtocol:@protocol(egwPInteractable)]) {
            workItemReq.jmpTbls.iJmpT = [(id<egwPInteractable>)object interactableJumpTable];
            workItemReq.flags |= (EGW_PHYACTR_ACTRQUEUE_ALL & ~EGW_PHYACTR_ACTRQUEUE_ACTUATOR);
        } else {
            workItemReq.jmpTbls.aJmpT = [(id<egwPActuator>)object actuatorJumpTable];
            workItemReq.flags |= EGW_PHYACTR_ACTRQUEUE_ACTUATOR;
        }
        
        pthread_mutex_lock(&_rLock);
        egwArrayAddTail(&_requestList, (const EGWbyte*)&workItemReq);
        pthread_mutex_unlock(&_rLock);
    }
}

- (void)setMasterThrottle:(EGWtime)throttle {
    pthread_mutex_lock(&_qLock);
    
    _mThrottle = throttle;
    
    pthread_mutex_unlock(&_qLock);
}

- (void)shutDownTask {
    if(!_doShutdown) {
        @synchronized(self) {
            if(!_doShutdown) {
                _doShutdown = YES;
                
                if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwPhyActuator: shutDownTask: Shutting down physcial actuator.");
                
                [egwSITaskMngr unregisterAllTasksUsing:self];
                
                // Wait for running status to deactivate
                if(_amRunning) {
                    NSDate* waitTill = [[NSDate alloc] initWithTimeIntervalSinceNow:(NSTimeInterval)EGW_ENGINE_MANAGERS_TIMETOWAIT];
                    while(_amRunning) {
                        if([waitTill timeIntervalSinceNow] < (NSTimeInterval)0.0) {
                            NSLog(@"egwPhyActuator: shutDownTask: Failure waiting for running status to deactivate.");
                            break;
                        }
                        
                        [NSThread sleepForTimeInterval:EGW_ENGINE_MANAGERS_TIMETOSLEEP];
                    }
                    [waitTill release];
                }
                
                [_lBase release]; _lBase = nil;
                #ifndef EGW_PHYACTR_USENSDATE
                    _lTime = 0;
                #else
                    [_lTime release]; _lTime = nil;
                #endif
                egwArrayFree(&_requestList);
                egwSLListFree(&_iQueues[0]);
                egwSLListFree(&_iQueues[1]);
                egwSLListFree(&_iQueues[2]);
                
                // Done last due to potential to have self dealloc'ed immediately afterwords
                [egwAIPhyCntx deassociateTask:self];
                
                if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwPhyActuator: shutDownTask: Physcial actuator shut down.");
            }
        }
    }
}

- (void)updateFinish {
    _doPostprocessing = YES;
}

- (double)taskPriority {
    return _params.priority;
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
    egwInteractionWorkItem* workItem = nil;
    egwInteractionWorkItem* prevWorkItem = nil;
    egwInteractionWorkItemReq* workReq = nil;
    egwSinglyLinkedListIter workItmIter;
    egwArrayIter workReqIter;
    EGWint qIndex;
    EGWuint16 wItmIFrame;
    
    if(_doShutdown) goto TaskBreak;
    pthread_mutex_lock(&_qLock);
    _amRunning = YES;
    
    // Start interaction frame runthrough, do pre-processing
    if(_doPreprocessing) {
        _doPreprocessing = NO;
        
        if(++_tFrame == EGW_FRAME_ALWAYSFAIL) _tFrame = 1;
        
        // Once in interaction pass, context change is disabled, so only
        // need to ensure active context here once
        if(!egwAFPPhyCntxActive(egwAIPhyCntx, @selector(isActive)))
            egwAFPPhyCntxMakeActive(egwAIPhyCntx, @selector(makeActive));
        
        egwAFPPhyCntxPerformSubTasks(egwAIPhyCntx, @selector(performSubTasks));
        
        #ifndef EGW_PHYACTR_USENSDATE
            if(_lTime) {
                clock_t nTime = clock();
                if(nTime >= _lTime) _deltaT = (EGWtime)(nTime - _lTime) / (EGWtime)CLOCKS_PER_SEC;
                else _deltaT = (EGWtime)((ULONG_MAX - _lTime) + nTime) / (EGWtime)CLOCKS_PER_SEC;
                _lTime = nTime;
            } else {
                _lTime = clock();
                _deltaT = (EGWtime)0.0;
            }
        #else
            if(_lTime) {
                EGWtime now = -[_lTime timeIntervalSinceNow];
                _deltaT = now - _lTimeOffset;
                _lTimeOffset = now;
                
                if(_lTimeOffset >= EGW_PHYACTR_NSDATEMAX - EGW_TIME_EPSILON) {
                    _lTimeOffset = 0.0;
                    [_lTime release]; _lTime = [[NSDate alloc] init];
                }
            } else {
                _deltaT = (EGWtime)0.0;
                _lTimeOffset = 0.0;
                _lTime = [[NSDate alloc] init];
            }
        #endif
        
        _deltaT *= _mThrottle;
        
        if(_deltaT >= (EGWtime)EGW_PHYACTR_MAXDELTAT - EGW_TIME_EPSILON)
            _deltaT = (EGWtime)EGW_PHYACTR_MAXDELTAT;
        else if(_deltaT <= (EGWtime)EGW_PHYACTR_MINDELTAT + EGW_TIME_EPSILON)
            _deltaT = (EGWtime)EGW_PHYACTR_MINDELTAT;
        
        if(_params.mode & EGW_PHYACTR_ACTRMODE_DEFERRED)
            _doPostprocessing = YES;
    }
    
    // Move items from outer queue into internal queue system
    if(_requestList.eCount > 0) {
        if(pthread_mutex_trylock(&_rLock) == 0) {
            if(_requestList.eCount > 0) {
                if(egwArrayEnumerateStart(&_requestList, EGW_ITERATE_MODE_DFLT, &workReqIter)) {
                    while((workReq = (egwInteractionWorkItemReq*)egwArrayEnumerateNextPtr(&workReqIter))) {
                        if(workReq->flags & EGW_PHYACTR_ACTRQUEUE_INSERT) { // Insert into the queues
                            if(!(workReq->flags & EGW_PHYACTR_ACTRQUEUE_ACTUATOR)) {
                                if(!workReq->jmpTbls.iJmpT->fpInteracting(workReq->object, @selector(isInteracting))) {
                                    workReq->jmpTbls.iJmpT->fpUpdate(workReq->object, @selector(update:withFlags:), (EGWtime)0.0, EGW_PHYOBJ_RPLYFLG_DOINTRCTSTART);
                                } else {
                                    // Send start message (restart trick), but skip enque
                                    workReq->jmpTbls.iJmpT->fpUpdate(workReq->object, @selector(update:withFlags:), (EGWtime)0.0, EGW_PHYOBJ_RPLYFLG_DOINTRCTSTART);
                                    continue;
                                }
                            } else {
                                if(!workReq->jmpTbls.aJmpT->fpActuating(workReq->object, @selector(isActuating))) {
                                    workReq->jmpTbls.aJmpT->fpUpdate(workReq->object, @selector(update:withFlags:), (EGWtime)0.0, EGW_ACTOBJ_RPLYFLG_DOUPDATESTART);
                                } else {
                                    // Send start message (restart trick), but skip enque
                                    workReq->jmpTbls.aJmpT->fpUpdate(workReq->object, @selector(update:withFlags:), (EGWtime)0.0, EGW_ACTOBJ_RPLYFLG_DOUPDATESTART);
                                    continue;
                                }
                            }
                            
                            egwValidater* iSync = NULL;
                            if(!(workReq->flags & EGW_PHYACTR_ACTRQUEUE_ACTUATOR)) {
                                iSync = workReq->jmpTbls.iJmpT->fpISync(workReq->object, @selector(interactionSync));
                                
                                // NOTE: New sort descriptor validates sync, will possibly cause ObjTree entrance, but is fine to do now since this is an initial call-through. -jw 
                                // NOTE: Validation will spark an orientation update, if pending, this must happen before the sort descriptor is built -jw 
                                egwSFPVldtrValidate(iSync, @selector(validate));
                            }
                            
                            for(qIndex = 0; qIndex < 3; ++qIndex) {
                                if(workReq->flags & (EGW_PHYACTR_ACTRQUEUE_PREPASS << qIndex)) {
                                    egwInteractionWorkItem newWorkItem; memset((void*)&newWorkItem, 0, sizeof(egwInteractionWorkItem));
                                    newWorkItem.object = workReq->object; // weak! (rbAdd CB will do retain)
                                    if(!(EGW_PHYACTR_ACTRQUEUE_ACTUATOR & (EGW_PHYACTR_ACTRQUEUE_PREPASS << qIndex))) {
                                        newWorkItem.sync = iSync; // weak! (rbAdd CB will do retain)
                                        newWorkItem.qIndex = qIndex;
                                        newWorkItem.jmpTbls.iJmpT = workReq->jmpTbls.iJmpT;
                                        
                                        egwIWIUpdate(&newWorkItem); // sort descriptor must be set before insert into slList
                                    } else {
                                        newWorkItem.qIndex = qIndex;
                                        newWorkItem.jmpTbls.aJmpT = workReq->jmpTbls.aJmpT;
                                        
                                        egwAWIUpdate(&newWorkItem); // sort descriptor must be set before insert into slList
                                    }
                                    
                                    egwSLListAddTail(&_iQueues[qIndex], (const EGWbyte*)&newWorkItem);
                                }
                            }
                        } else if(workReq->flags & EGW_PHYACTR_ACTRQUEUE_REMOVE) { // Remove from the queues
                            // NOTE: Resync invalidation below (pre frame check) will remove this object instead since removing it now would require O(n) for a full item lookup. -jw
                            if(!(workReq->flags & EGW_PHYACTR_ACTRQUEUE_ACTUATOR)) {
                                if(workReq->jmpTbls.iJmpT->fpInteracting(workReq->object, @selector(isInteracting)))
                                    workReq->jmpTbls.iJmpT->fpSetIFrame(workReq->object, @selector(setInteractionFrame:), EGW_FRAME_ALWAYSFAIL);
                            } else {
                                if(workReq->jmpTbls.aJmpT->fpActuating(workReq->object, @selector(isActuating))) {
                                    // NOTE: Full lookup and removal of object is required in order to remove. Cannot set a frame check to always fail. -jw
                                    for(qIndex = 0; qIndex < 3; ++qIndex) {
                                        if(workReq->flags & (EGW_PHYACTR_ACTRQUEUE_PREPASS << qIndex)) {
                                            if(egwSLListEnumerateStart(&_iQueues[qIndex], EGW_ITERATE_MODE_DFLT, &workItmIter)) {
                                                prevWorkItem = nil;
                                                while((workItem = (egwInteractionWorkItem*)egwSLListEnumerateNextPtr(&workItmIter))) {
                                                    if(workItem->object == workReq->object) {
                                                        egwSLListRemoveAfter(&_iQueues[qIndex], (prevWorkItem ? egwSLListNodePtr((EGWbyte*)prevWorkItem) : NULL));
                                                        break; // object only appears once per queue
                                                    } else prevWorkItem = workItem;
                                                }
                                            }
                                        }
                                    }
                                    
                                    workReq->jmpTbls.aJmpT->fpUpdate(workReq->object, @selector(update:withFlags:), (EGWtime)0.0, EGW_ACTOBJ_RPLYFLG_DOUPDATESTOP);
                                }
                            }
                        } else if(workReq->flags & EGW_PHYACTR_ACTRQUEUE_PAUSE) { // Pause/resume in the queues
                            if(!(workReq->flags & EGW_PHYACTR_ACTRQUEUE_ACTUATOR)) {
                                if(workReq->jmpTbls.iJmpT->fpInteracting(workReq->object, @selector(isInteracting)))
                                    workReq->jmpTbls.iJmpT->fpUpdate(workReq->object, @selector(update:withFlags:), (EGWtime)0.0, EGW_PHYOBJ_RPLYFLG_DOINTRCTPAUSE);
                            } else {
                                if(workReq->jmpTbls.aJmpT->fpActuating(workReq->object, @selector(isActuating)))
                                    workReq->jmpTbls.aJmpT->fpUpdate(workReq->object, @selector(update:withFlags:), (EGWtime)0.0, EGW_ACTOBJ_RPLYFLG_DOUPDATEPAUSE);
                            }
                        }
                    }
                }
                
                egwArrayRemoveAll(&_requestList);
            }
        }
        
        pthread_mutex_unlock(&_rLock);
    }
    
    // First pass: Perform PRE frame check, resync objects.
    
    {   EGWuint16 iFrame;
        
        if(_params.mode & EGW_PHYACTR_ACTRMODE_FRAMECHECK)
            iFrame = egwAFPPhyCntxInteractionFrame(egwAIPhyCntx, @selector(interactionFrame));
        else iFrame = EGW_FRAME_ALWAYSPASS;
        
        for(qIndex = 0; qIndex < 3; ++qIndex) {
            if(egwSLListEnumerateStart(&_iQueues[qIndex], EGW_ITERATE_MODE_DFLT, &workItmIter)) {
                prevWorkItem = nil;
                
                if(!(EGW_PHYACTR_ACTRQUEUE_ACTUATOR & (EGW_PHYACTR_ACTRQUEUE_PREPASS << qIndex))) {
                    while((workItem = (egwInteractionWorkItem*)egwSLListEnumerateNextPtr(&workItmIter))) {
                        if(workItem->tFrame != _tFrame) {
                            id<egwPInteractable> workObject = (id<egwPInteractable>)workItem->object;
                            
                            workItem->tFlags = EGW_ITCWRKITMFLG_NONE;
                            
                            // Remove out-of-date objects from queue
                            wItmIFrame = workItem->jmpTbls.iJmpT->fpIFrame(workObject, @selector(interactionFrame));
                            if(((iFrame != EGW_FRAME_ALWAYSPASS && wItmIFrame != EGW_FRAME_ALWAYSPASS && wItmIFrame != iFrame) ||
                                wItmIFrame == EGW_FRAME_ALWAYSFAIL || iFrame == EGW_FRAME_ALWAYSFAIL) ||
                               !workItem->jmpTbls.iJmpT->fpAwake(workObject, @selector(isAwake)) ||
                               !workItem->jmpTbls.iJmpT->fpInteracting(workObject, @selector(isInteracting))) {
                                workItem->jmpTbls.iJmpT->fpUpdate(workObject, @selector(update:withFlags:), 0.0, EGW_PHYOBJ_RPLYFLG_DOINTRCTSTOP);
                                egwSLListRemoveAfter(&_iQueues[qIndex], (prevWorkItem ? egwSLListNodePtr((EGWbyte*)prevWorkItem) : NULL));
                            } else {
                                prevWorkItem = workItem;
                                
                                // Validate
                                // FIXME: In ZMB we were using the interactionSyncs to control whenever objects needed to be updated in the quadtree. Right here is not the right place to be doing a sync validation.-jw
                                //if(egwSFPVldtrIsInvalidated(workItem->sync, @selector(isInvalidated)))
                                //    egwSFPVldtrValidate(workItem->sync, @selector(validate));
                                
                                workItem->tFrame = _tFrame;
                            }
                        }
                    }
                } else {
                    while((workItem = (egwInteractionWorkItem*)egwSLListEnumerateNextPtr(&workItmIter))) {
                        if(workItem->tFrame != _tFrame) {
                            id<egwPActuator> workObject = (id<egwPActuator>)workItem->object;
                            
                            if(workItem->jmpTbls.aJmpT->fpFinished(workObject, @selector(isFinished))) {
                                workItem->jmpTbls.aJmpT->fpUpdate(workObject, @selector(update:withFlags:), 0.0, EGW_ACTOBJ_RPLYFLG_DOUPDATESTOP);
                                egwSLListRemoveAfter(&_iQueues[qIndex], (prevWorkItem ? egwSLListNodePtr((EGWbyte*)prevWorkItem) : NULL));
                            } else prevWorkItem = workItem;
                        }
                    }
                }
            }
        }
    }
    
    // Handle cancellation
    if(_doShutdown) goto TaskBreak;
    
    // Second pass: Perform update passes, perform POST frame check.
    
    {   BOOL sameLastBase = NO;
        EGWuint32 replyFlags;
        
        for(qIndex = 0; qIndex < 3; ++qIndex) {
            replyFlags = _iReplies[qIndex];
            
            if(egwSLListEnumerateStart(&_iQueues[qIndex], EGW_ITERATE_MODE_DFLT, &workItmIter)) {
                if(!(EGW_PHYACTR_ACTRQUEUE_ACTUATOR & (EGW_PHYACTR_ACTRQUEUE_PREPASS << qIndex))) {
                    while((workItem = (egwInteractionWorkItem*)egwSLListEnumerateNextPtr(&workItmIter))) {
                        id<egwPInteractable> workObject = (id<egwPInteractable>)workItem->object;
                        
                        // Handle sameLastBase/_lBase tracking
                        sameLastBase = (_lBase && _lBase == workItem->jmpTbls.iJmpT->fpIBase(workObject, @selector(interactionBase))) ? YES : NO;
                        if(_lBase == nil || !sameLastBase) {
                            [_lBase release];
                            _lBase = [workItem->jmpTbls.iJmpT->fpIBase(workObject, @selector(interactionBase)) retain];
                        }
                        
                        // Update interactable object
                        workItem->jmpTbls.iJmpT->fpUpdate(workObject, @selector(update:withFlags:), _deltaT, (replyFlags | (sameLastBase ? EGW_PHYOBJ_RPLYFLG_SAMELASTBASE : 0)));
                    }
                } else {
                    while((workItem = (egwInteractionWorkItem*)egwSLListEnumerateNextPtr(&workItmIter))) {
                        id<egwPActuator> workObject = (id<egwPActuator>)workItem->object;
                        
                        // Handle sameLastBase/_lBase tracking
                        if(workItem->jmpTbls.aJmpT->fpABase) {
                            sameLastBase = (_lBase && _lBase == workItem->jmpTbls.aJmpT->fpABase(workObject, @selector(assetBase))) ? YES : NO;
                            if(_lBase == nil || !sameLastBase) {
                                [_lBase release];
                                _lBase = [workItem->jmpTbls.aJmpT->fpABase(workObject, @selector(assetBase)) retain];
                            }
                        } else {
                            sameLastBase = NO;
                            [_lBase release]; _lBase = nil;
                        }
                        
                        // Update actuator object
                        workItem->jmpTbls.aJmpT->fpUpdate(workObject, @selector(update:withFlags:), _deltaT, (replyFlags | (sameLastBase ? EGW_ACTOBJ_RPLYFLG_SAMELASTBASE : 0)));
                    }
                }
            }
        }
    }
    
    // Handle cancellation
    if(_doShutdown) goto TaskBreak;
    
    // Done with runthrough, do post-processing
    if(_doPostprocessing) {
        _doPostprocessing = NO;
        
        [_lBase release]; _lBase = nil;
        
        if(!(_params.mode & EGW_PHYACTR_ACTRMODE_PERSISTENT))
            for(qIndex = 0; qIndex < 3; ++qIndex)
                egwSLListRemoveAll(&_iQueues[qIndex]);
        
        // Set up for next run
        _doPreprocessing = YES;
    }
    
TaskBreak:
    // Ensurances (break due to cancellation, etc.)
    if(_amRunning) {
        _amRunning = NO;
        pthread_mutex_unlock(&_qLock);
    }
}

@end

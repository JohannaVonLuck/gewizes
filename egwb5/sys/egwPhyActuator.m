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

typedef struct {
	id<NSObject> object;                    // Ref to physics object (retained, from flag).
	EGWuint16 flags;                        // Flags for insertion or removal.
} egwInteractionWorkItemReq;

typedef struct {
    //EGWchar sortDesc[EGW_ITCWRKITM_SORTDESCLEN]; // Sort descriptor.
    id<NSObject> object;                         // Ref to physics object (retained).
} egwInteractionWorkItem;

EGWint egwIWICompare(egwInteractionWorkItem* item1, egwInteractionWorkItem* item2, size_t size) {
    return 0;
    //return strncmp((const char*)&(item1->sortDesc[0]), (const char*)&(item2->sortDesc[0]), EGW_ITCWRKITM_SORTDESCLEN);
}

void egwIWIAdd(egwInteractionWorkItem* item) {
    [item->object retain];
    //[item->sync retain];
}

void egwIWIRemove(egwInteractionWorkItem* item) {
    [item->object release]; item->object = nil;
    //[item->sync release]; item->sync = nil;
}

EGWint egwIWIUpdate(egwInteractionWorkItem* item) {
    // (Re)creates the sort desc string (used to sort in deferred interaction), change this to affect layering sort
    /*- (void)updateSortDesc {
        [_sortDesc release]; _sortDesc = nil;
        _sortDesc = [[NSString alloc] initWithFormat:@"%c_%@",
                     ([_object performSelector:@selector(isColliding)] ? 'C' : 'F'),
                     [[_object performSelector:@selector(interactionBase)] performSelector:@selector(identity)]];
    }*/
    
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
    
    _amRunning = _doShutdown = NO;
    _doPreprocessing = YES; _doPostprocessing = NO;
    #ifndef EGW_PHYACTR_USENSDATE
        _lTime = 0;
    #else
        _lTime = nil;
    #endif
    _deltaT = (EGWtime)0.0;
    _mThrottle = (EGWtime)1.0;
    
    // Allocate queues
    egwDataFuncs callbacks; memset((void*)&callbacks, 0, sizeof(egwDataFuncs));
    callbacks.fpCompare = (EGWcomparefp)&egwIWICompare;
    callbacks.fpAdd = (EGWelementfp)&egwIWIAdd;
    callbacks.fpRemove = (EGWelementfp)&egwIWIRemove;
    if(!(egwSLListInit(&_uQueues[0], &callbacks, sizeof(egwInteractionWorkItem), EGW_LIST_FLG_DFLT))) { [self release]; return (self = nil); }
    if(!(egwSLListInit(&_uQueues[1], &callbacks, sizeof(egwInteractionWorkItem), EGW_LIST_FLG_DFLT))) { [self release]; return (self = nil); }
    if(!(egwSLListInit(&_uQueues[2], &callbacks, sizeof(egwInteractionWorkItem), EGW_LIST_FLG_DFLT))) { [self release]; return (self = nil); }
    if(!(egwArrayInit(&_requestList, NULL, sizeof(egwInteractionWorkItemReq), 10, (EGW_ARRAY_FLG_GROWBY10 | EGW_ARRAY_FLG_GRWCND100 | EGW_ARRAY_FLG_SHRNKBY2X | EGW_ARRAY_FLG_RETAIN)))) { [self release]; return (self = nil); }
    _uReplies[0] = EGW_PHYOBJ_RPLYFLG_DOINTRCTPASS | (EGW_PHYOBJ_RPLYFLG_INTRCTPASSMASK & (EGWuint)1);
    _uReplies[1] = EGW_ACTOBJ_RPLYFLG_DOUPDATEPASS;
    _uReplies[2] = EGW_PHYOBJ_RPLYFLG_DOINTRCTPASS | (EGW_PHYOBJ_RPLYFLG_INTRCTPASSMASK & (EGWuint)2);
    
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
    egwSLListFree(&_uQueues[0]);
    egwSLListFree(&_uQueues[1]);
    egwSLListFree(&_uQueues[2]);
    pthread_mutex_destroy(&_qLock);
    pthread_mutex_destroy(&_rLock);
    
    [super dealloc];
}

- (void)actuateObject:(id<egwPActuator>)actuatorObject {    
    if(actuatorObject) {
        egwInteractionWorkItemReq workItemReq;
        
        //if(_params.mode & EGW_PHYACTR_ACTRMODE_FRAMECHECK)
        //    [actuatorObject setInteractionFrame:[egwAIPhyCntx playbackFrame]];
        
        workItemReq.object = actuatorObject; // weak, retained on add
        workItemReq.flags = EGW_PHYACTR_ACTRQUEUE_INSERT | EGW_PHYACTR_ACTRQUEUE_ACTUATOR;
        
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
        
        if([object conformsToProtocol:@protocol(egwPInteractable)])
            workItemReq.flags |= (EGW_PHYACTR_ACTRQUEUE_ALL & ~EGW_PHYACTR_ACTRQUEUE_ACTUATOR);
        else
            workItemReq.flags |= EGW_PHYACTR_ACTRQUEUE_ACTUATOR;
        
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
        
        if([object conformsToProtocol:@protocol(egwPInteractable)])
            workItemReq.flags |= (EGW_PHYACTR_ACTRQUEUE_ALL & ~EGW_PHYACTR_ACTRQUEUE_ACTUATOR);
        else
            workItemReq.flags |= EGW_PHYACTR_ACTRQUEUE_ACTUATOR;
        
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
                
                [egwSITaskMngr unregisterAllTasksUsing:self];
                
                [_lBase release]; _lBase = nil;
                #ifndef EGW_PHYACTR_USENSDATE
                    _lTime = 0;
                #else
                    [_lTime release]; _lTime = nil;
                #endif
                egwArrayFree(&_requestList);
                egwSLListFree(&_uQueues[0]);
                egwSLListFree(&_uQueues[1]);
                egwSLListFree(&_uQueues[2]);
                
                // Done last due to potential to have self dealloc'ed immediately afterwords
                [egwAIPhyCntx deassociateTask:self];
                
                if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwPhyActuator: shutDownTask: Physcial actuator shut down.");
            }
        }
    }
}

- (void)updateObject:(id<egwPInteractable>)interactableObject {
    if(interactableObject) {
        egwInteractionWorkItemReq workItemReq;
        EGWuint32 uFlags = [interactableObject interactionFlags];
        if(!((uFlags & EGW_PHYACTR_ACTRQUEUE_ALL) & ~EGW_PHYACTR_ACTRQUEUE_ACTUATOR)) // idiot proofing
            uFlags |= EGW_PHYACTR_ACTRQUEUE_MAINPASS;
        
        //if(_params.mode & EGW_GFXRNDRR_RNDRMODE_FRAMECHECK)
        //    [renderableObject setRenderingFrame:[_gfxContext renderingFrame]];
        
        workItemReq.object = interactableObject; // weak, retained on add
        workItemReq.flags = EGW_PHYACTR_ACTRQUEUE_INSERT | ((uFlags & EGW_PHYACTR_ACTRQUEUE_ALL) & ~EGW_PHYACTR_ACTRQUEUE_ACTUATOR);
        
        pthread_mutex_lock(&_rLock);
        egwArrayAddTail(&_requestList, (const EGWbyte*)&workItemReq);
        pthread_mutex_unlock(&_rLock);
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
    //BOOL resortDeferredQueue = NO;
    EGWuint16 uFrame = EGW_FRAME_ALWAYSPASS;
    BOOL sameLastBase = NO;
    EGWint qIndex;
    
    if(_doShutdown) goto TaskBreak;
    pthread_mutex_lock(&_qLock);
    _amRunning = YES;
    
    // Start interaction frame runthrough, do pre-processing
    if(_doPreprocessing) {
        _doPreprocessing = NO;
        
        // Once in interaction pass, context change is disabled, so only
        // need to ensure active context here once
        if(![egwAIPhyCntx isActive]) [egwAIPhyCntx makeActive];
        
        [egwAIPhyCntx performSubTasks];
        
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
                _deltaT = (EGWtime)-[_lTime timeIntervalSinceNow];
                [_lTime release]; _lTime = [[NSDate alloc] init];
            } else {
                _deltaT = (EGWtime)0.0;
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
                                if(![(id<egwPInteractable>)workReq->object isInteracting]) {
                                    [(id<egwPInteractable>)workReq->object update:(EGWtime)0.0 withFlags:EGW_PHYOBJ_RPLYFLG_DOINTRCTSTART];
                                } else {
                                    // Send start message (restart trick), but skip enque
                                    [(id<egwPInteractable>)workReq->object update:(EGWtime)0.0 withFlags:EGW_PHYOBJ_RPLYFLG_DOINTRCTSTART];
                                    continue;
                                }
                            } else {
                                if(![(id<egwPActuator>)workReq->object isActuating]) {
                                    [(id<egwPActuator>)workReq->object update:(EGWtime)0.0 withFlags:EGW_ACTOBJ_RPLYFLG_DOUPDATESTART];
                                } else {
                                    // Send start message (restart trick), but skip enque
                                    [(id<egwPActuator>)workReq->object update:(EGWtime)0.0 withFlags:EGW_ACTOBJ_RPLYFLG_DOUPDATESTART];
                                    continue;
                                }
                            }
                            
                            if(!(workReq->flags & EGW_PHYACTR_ACTRQUEUE_ACTUATOR))
                                // NOTE: New sort descriptor validates sync, will possibly cause ObjTree entrance, but is fine to do now since this is an initial call-through. -jw 
                                // NOTE: Validation will spark an orientation update, if pending, this must happen before the sort descriptor is built -jw 
                                egwSFPVldtrValidate([(id<egwPInteractable>)workReq->object interactionSync], @selector(validate));
                            
                            for(qIndex = 0; qIndex < 3; ++qIndex) {
                                if(workReq->flags & (EGW_PHYACTR_ACTRQUEUE_PREPASS << qIndex)) {
                                    egwInteractionWorkItem newWorkItem; memset((void*)&newWorkItem, 0, sizeof(egwInteractionWorkItem));
                                    newWorkItem.object = workReq->object; // weak! (rbAdd CB will do retain)
                                    
                                    egwSLListAddTail(&_uQueues[qIndex], (const EGWbyte*)&newWorkItem);
                                }
                            }
                        } else if(workReq->flags & EGW_PHYACTR_ACTRQUEUE_REMOVE) { // Remove from the queues
                            if(!(workReq->flags & EGW_PHYACTR_ACTRQUEUE_ACTUATOR)) {
                                if(![(id<egwPInteractable>)workReq->object isInteracting]) {
                                    continue;
                                }
                            } else {
                                if(![(id<egwPActuator>)workReq->object isActuating]) {
                                    continue;
                                }
                            }
                            
                            // FIXME: This full lookup will be avoided in the future by auto-maintaining a list of stored locations. -jw
                            for(qIndex = 0; qIndex < 3; ++qIndex) {
                                if(workReq->flags & (EGW_PHYACTR_ACTRQUEUE_PREPASS << qIndex)) {
                                    if(egwSLListEnumerateStart(&_uQueues[qIndex], EGW_ITERATE_MODE_DFLT, &workItmIter)) {
                                        prevWorkItem = nil;
                                        while((workItem = (egwInteractionWorkItem*)egwSLListEnumerateNextPtr(&workItmIter))) {
                                            if(workItem->object == workReq->object) {
                                                egwSLListRemoveAfter(&_uQueues[qIndex], (prevWorkItem ? egwSLListNodePtr((EGWbyte*)prevWorkItem) : NULL));
                                                break; // object only appears once per queue
                                            } else prevWorkItem = workItem;
                                        }
                                    }
                                }
                            }
                            
                            if(!(workReq->flags & EGW_PHYACTR_ACTRQUEUE_ACTUATOR))
                                [(id<egwPInteractable>)workReq->object update:(EGWtime)0.0 withFlags:EGW_PHYOBJ_RPLYFLG_DOINTRCTSTOP];
                            else
                                [(id<egwPActuator>)workReq->object update:(EGWtime)0.0 withFlags:EGW_ACTOBJ_RPLYFLG_DOUPDATESTOP];
                        } else if(workReq->flags & EGW_PHYACTR_ACTRQUEUE_PAUSE) { // Pause/resume in the queues
                            if(!(workReq->flags & EGW_PHYACTR_ACTRQUEUE_ACTUATOR)) {
                                if([(id<egwPInteractable>)workReq->object isInteracting]) {
                                    [(id<egwPInteractable>)workReq->object update:(EGWtime)0.0 withFlags:EGW_PHYOBJ_RPLYFLG_DOINTRCTPAUSE];
                                }
                            } else {
                                if([(id<egwPActuator>)workReq->object isActuating]) {
                                    [(id<egwPActuator>)workReq->object update:(EGWtime)0.0 withFlags:EGW_ACTOBJ_RPLYFLG_DOUPDATEPAUSE];
                                }
                            }
                        }
                    }
                }
                
                egwArrayRemoveAll(&_requestList);
            }
        }
        
        pthread_mutex_unlock(&_rLock);
    }
    
    // First pass: Resync objects.
    
    /*if(_params.mode & EGW_PHYACTR_ACTRMODE_DEFERRED) {
        for(qIndex = 0; qIndex < 3; ++qIndex) {
            if(egwSLListEnumerateStart(&_uQueues[qIndex], EGW_ITERATE_MODE_DFLT, &workItmIter)) {
                while((workItem = (egwInteractionWorkItem*)egwSLListEnumerateNextPtr(&workItmIter))) {
                    if(&_uQueues[qIndex] != &_uQueues[1]) {
                        // Set sort descriptor for deferred mode
                        if([[(id<egwPInteractable>)workItem->object interactionSync] isInvalidated]) {
                            // NOTE: Validation will spark an orientation update, if pending, this must happen before the sort descriptor is built -jw
                            [[(id<egwPInteractable>)workItem->object interactionSync] validate];
                            
                            //[workItem updateSortDesc];
                            //resortDeferredQueue = YES;
                        }
                        
                        // Sort queue if in deferred mode
                        //if(resortDeferredQueue && [q count] > 1)
                        //[q sortUsingSelector:@selector(compare:)];
                        //resortDeferredQueue = NO;
                    }
                }
            }
        }
    }*/
    
    // Handle cancellation
    if(_doShutdown) goto TaskBreak;
    
    // Second pass: Perform update passes, perform POST frame check.
    
    if(_params.mode & EGW_PHYACTR_ACTRMODE_FRAMECHECK)
        uFrame = [egwAIPhyCntx interactionFrame];
    else uFrame = EGW_FRAME_ALWAYSPASS;

    for(qIndex = 0; qIndex < 3; ++qIndex) {
        if(egwSLListEnumerateStart(&_uQueues[qIndex], EGW_ITERATE_MODE_DFLT, &workItmIter)) {
            prevWorkItem = nil;
            while((workItem = (egwInteractionWorkItem*)egwSLListEnumerateNextPtr(&workItmIter))) {
                if(&_uQueues[qIndex] != &_uQueues[1]) {
                    // Handle sameLastBase/_lBase tracking
                    sameLastBase = (_lBase && _lBase == [workItem->object performSelector:@selector(interactionBase)]) ? YES : NO;
                    if(_lBase == nil || !sameLastBase) {
                        [_lBase release];
                        _lBase = [[workItem->object performSelector:@selector(interactionBase)] retain];
                    }
                    
                    // Update interactable object
                    [(id<egwPInteractable>)workItem->object update:_deltaT withFlags:(_uReplies[qIndex]
                                                                                | (sameLastBase ? EGW_PHYOBJ_RPLYFLG_SAMELASTBASE : 0))];
                    
                    // Remove out of date objects for frame check or awake test
                    if((uFrame != EGW_FRAME_ALWAYSPASS && [(id<egwPInteractable>)workItem->object interactionFrame] != EGW_FRAME_ALWAYSPASS && [(id<egwPInteractable>)workItem->object interactionFrame] != uFrame) ||
                       ![(id<egwPInteractable>)workItem->object isAwake] || [(id<egwPInteractable>)workItem->object interactionFrame] == EGW_FRAME_ALWAYSFAIL || uFrame == EGW_FRAME_ALWAYSFAIL) {
                        [(id<egwPInteractable>)workItem->object update:0.0f withFlags:EGW_PHYOBJ_RPLYFLG_DOINTRCTSTOP];
                        egwSLListRemoveAfter(&_uQueues[qIndex], (prevWorkItem ? egwSLListNodePtr((EGWbyte*)prevWorkItem) : NULL));
                    } else prevWorkItem = workItem;
                } else {
                    // Handle sameLastBase/_lBase tracking
                    if([workItem->object respondsToSelector:@selector(assetBase)]) {
                        sameLastBase = (_lBase && _lBase == [workItem->object performSelector:@selector(assetBase)]) ? YES : NO;
                        if(_lBase == nil || !sameLastBase) {
                            [_lBase release];
                            _lBase = [[workItem->object performSelector:@selector(assetBase)] retain];
                        }
                    } else {
                        sameLastBase = NO;
                        [_lBase release]; _lBase = nil;
                    }
                    
                    // Update actuator object
                    [(id<egwPActuator>)workItem->object update:_deltaT withFlags:(_uReplies[qIndex]
                                                                            | (sameLastBase ? EGW_ACTOBJ_RPLYFLG_SAMELASTBASE : 0))];
                    
                    // Remove out of date objects for finish test
                    if([(id<egwPActuator>)workItem->object isFinished]) {
                        [(id<egwPActuator>)workItem->object update:0.0f withFlags:EGW_ACTOBJ_RPLYFLG_DOUPDATESTOP];
                        egwSLListRemoveAfter(&_uQueues[qIndex], (prevWorkItem ? egwSLListNodePtr((EGWbyte*)prevWorkItem) : NULL));
                    } else prevWorkItem = workItem;
                }
            }
        }
    }
    
    // Done with runthrough, do post-processing
    if(_doPostprocessing) {
        _doPostprocessing = NO;
        
        [_lBase release]; _lBase = nil;
        
        if(!(_params.mode & EGW_PHYACTR_ACTRMODE_PERSISTENT))
            for(qIndex = 0; qIndex < 3; ++qIndex)
                egwSLListRemoveAll(&_uQueues[qIndex]);
        
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

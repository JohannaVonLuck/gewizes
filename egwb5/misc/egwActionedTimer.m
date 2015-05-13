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

/// @file egwActionedTimer.m
/// @ingroup geWizES_misc_actionedtimer
/// Actioned Timer Asset Implementation.

#import <pthread.h>
#import "egwActionedTimer.h"
#import "../sys/egwSysTypes.h"
#import "../sys/egwAssetManager.h"
#import "../sys/egwPhyContext.h"
#import "../sys/egwPhyActuator.h"
#import "../data/egwCyclicArray.h"
#import "../data/egwSinglyLinkedList.h"
#import "../math/egwMath.h"
#import "../misc/egwValidater.h"


typedef struct {
    id<egwPTimed> tObj;                     // Target object (weak).
    id (*fpEval)(id, SEL, EGWtime);         // IMP to evaluateToTime:.
} egwActionedTimerTarget;

typedef struct {                            // NOTE: I know it only has one value. This is done on purpose for future considerations. -jw
    EGWuint16 actIndex;                     // Action index.
} egwActionedTimerQueueItem;


@implementation egwActionedTimer

- (id)init {
    if([self isMemberOfClass:[egwActionedTimer class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent actionsSet:(egwAbsTimedActions*)actions {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwActionedTimerBase alloc] initWithIdentity:assetIdent actionsSet:actions])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    if(!egwSLListInit(&_tOutputs, NULL, sizeof(egwActionedTimerTarget), EGW_LIST_FLG_NONE)) { [self release]; return (self = nil); } // Owners are never retained
    if(pthread_mutex_init(&_oLock, NULL)) { [self release]; return (self = nil); }
    
    _aFlags = EGW_ACTOBJ_ACTRFLG_DFLT;
    
    _tIndex = _otBounds.tBegin = _otBounds.tEnd = EGW_TIME_NAN;
    
    if(!egwCycArrayInit(&_aQueue, NULL, sizeof(egwActionedTimerQueueItem), 10, EGW_ARRAY_FLG_GROWBY10 | EGW_ARRAY_FLG_GRWCND100 | EGW_ARRAY_FLG_SHRNKBY10)) { [self release]; return (self = nil); }
    if(pthread_mutex_init(&_aLock, NULL)) { [self release]; return (self = nil); }
    
    _actions = [_base actionsSet];
    _caIndex = _actions->daIndex;
    _caOffset = 0;
    
    return self;
}

- (id)initBlankWithIdentity:(NSString*)assetIdent actionCount:(EGWuint16)actsCount defaultAction:(EGWuint16)dfltActIndex {
    egwAbsTimedActions actions; memset((void*)&actions, 0, sizeof(egwAbsTimedActions));
    
    if(actsCount < 1 || dfltActIndex >= actsCount || !(self = [super init])) { [self release]; return (self = nil); }
    
    actions.aCount = actsCount;
    actions.daIndex = dfltActIndex;
    
    if(!(actions.tBounds = (egwAbsTimeBound*)malloc((size_t)actions.aCount * sizeof(EGWtime) * 2))) { [self release]; self = nil; goto ErrorCleanup; }
    
    if(!(self = [self initWithIdentity:assetIdent actionsSet:&actions])) { [self release]; self = nil; goto ErrorCleanup; }
    
    return self;
    
ErrorCleanup:
    if(actions.tBounds) { free((void*)(actions.tBounds)); actions.tBounds = NULL; }
    return nil;
}

- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent {
    if(!([asset isKindOfClass:[self class]]) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = (egwActionedTimerBase*)[[asset assetBase] retain])) { [self release]; return (self = nil); }
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    if(!egwSLListInit(&_tOutputs, NULL, sizeof(egwActionedTimerTarget), EGW_LIST_FLG_NONE)) { [self release]; return (self = nil); } // Owners are never retained
    if(pthread_mutex_init(&_oLock, NULL)) { [self release]; return (self = nil); }
    
    _aFlags = [(egwActionedTimer*)asset actuatorFlags];
    
    _tIndex = _otBounds.tBegin = _otBounds.tEnd = EGW_TIME_NAN;
    
    if(!egwCycArrayInit(&_aQueue, NULL, sizeof(egwActionedTimerQueueItem), 10, EGW_ARRAY_FLG_GROWBY10 | EGW_ARRAY_FLG_GRWCND100 | EGW_ARRAY_FLG_SHRNKBY10)) { [self release]; return (self = nil); }
    if(pthread_mutex_init(&_aLock, NULL)) { [self release]; return (self = nil); }
    
    _actions = [_base actionsSet];
    _caIndex = _actions->daIndex;
    _caOffset = [(egwActionedTimer*)asset actionIndexOffset];
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwActionedTimer* copy = nil;
    NSString* copyIdent = nil;
    
    if([_ident hasSuffix:@"_default"])
        copyIdent = [[NSString alloc] initWithFormat:@"%@_%d", [_base identity], [_base nextInstanceIndex]];
    else copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwActionedTimer allocWithZone:zone] initCopyOf:self
                                                     withIdentity:copyIdent])) {
        NSLog(@"egwActionedTimer: copyWithZone: Failure initializing new actioned timer from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    return copy;
}

- (void)dealloc {
    _actions = NULL;
    
    pthread_mutex_destroy(&_aLock);
    egwCycArrayFree(&_aQueue);
    
    pthread_mutex_destroy(&_oLock);
    egwSLListFree(&_tOutputs);
    
    [_delegate release]; _delegate = nil;
    [_ident release]; _ident = nil;
    [_base release]; _base = nil;
    
    [super dealloc];
}

- (void)addOwner:(id<egwPTimed>)owner {
    pthread_mutex_lock(&_oLock);
    
    egwActionedTimerTarget targetItem;
    targetItem.tObj = owner;
    targetItem.fpEval = (id(*)(id, SEL, EGWtime))[((NSObject*)targetItem.tObj) methodForSelector:@selector(evaluateToTime:)];
    
    egwSLListAddTail(&_tOutputs, (const EGWbyte*)&targetItem);
    
    EGWtime eBegin = [targetItem.tObj evaluationBoundsBegin];
    EGWtime eEnd = [targetItem.tObj evaluationBoundsEnd];
    
    // Auto-expand beginning boundary
    if(_tOutputs.eCount == 1 || isnan(eBegin) || (!isnan(_otBounds.tBegin) && eBegin < _otBounds.tBegin)) {
        _otBounds.tBegin = eBegin;
    }
    
    // Auto-expand ending boundary
    if(_tOutputs.eCount == 1 || isnan(eEnd) || (!isnan(_otBounds.tEnd) && eEnd > _otBounds.tEnd)) {
        _otBounds.tEnd = eEnd;
    }
    
    pthread_mutex_unlock(&_oLock);
}

- (void)removeOwner:(id<egwPTimed>)owner {
    pthread_mutex_lock(&_oLock);
    
    egwSinglyLinkedListIter iter;
    if(egwSLListEnumerateStart(&_tOutputs, EGW_ITERATE_MODE_DFLT, &iter)) {
        egwActionedTimerTarget* targetItem;
        egwSinglyLinkedListNode* prev = NULL;
        EGWtime eBegin, nBegin = EGW_TIME_MAX;
        EGWtime eEnd, nEnd = -EGW_TIME_MAX;
        
        while(targetItem = (egwActionedTimerTarget*)egwSLListEnumerateNextPtr(&iter)) {
            if(targetItem->tObj != owner) { // Not the droid you're looking for
                // Auto-contract start & finish boundaries (requires full rebuild)
                eBegin = [targetItem->tObj evaluationBoundsBegin];
                eEnd = [targetItem->tObj evaluationBoundsEnd];
                
                if(isnan(eBegin) || (!isnan(nBegin) && eBegin < nBegin))
                    nBegin = eBegin;
                if(isnan(eEnd) || (!isnan(nEnd) && eEnd > nEnd))
                    nEnd = eEnd;
                
                prev = egwSLListNodePtr((const EGWbyte*)targetItem);
            } else { // Remove target item
                egwSLListRemoveAfter(&_tOutputs, prev);
            }
        }
        
        if(_tOutputs.eCount != 0) {
            _otBounds.tBegin = nBegin;
            _otBounds.tEnd = nEnd;
        } else {
            _otBounds.tBegin = _otBounds.tEnd = EGW_TIME_NAN;
        }
    }
    
    pthread_mutex_unlock(&_oLock);
}

- (void)enqueAction:(EGWuint16)actIndex {
    pthread_mutex_lock(&_aLock);
    
    egwActionedTimerQueueItem actionItem; //memset((void*)&actionItem, 0, sizeof(egwActionedTimerQueueItem));
    actionItem.actIndex = actIndex + _caOffset;
    
    egwCycArrayAddTail(&_aQueue, (const EGWbyte*)&actionItem);
    
    pthread_mutex_unlock(&_aLock);
}

- (void)dequeueAllActions {
    pthread_mutex_lock(&_aLock);
    
    egwCycArrayRemoveAll(&_aQueue);
    
    pthread_mutex_unlock(&_aLock);
}

- (void)dequeueLastAction {
    pthread_mutex_lock(&_aLock);
    
    egwCycArrayRemoveTail(&_aQueue);
    
    pthread_mutex_unlock(&_aLock);
}

- (void)breakAndJumpToAction:(EGWuint16)actIndex {
    pthread_mutex_lock(&_aLock);
    
    _baIndex = actIndex + _caOffset;
    _isBreaking = YES;
    
    pthread_mutex_unlock(&_aLock);
}

- (void)evaluateTimer {
    EGWtime tIndex = _tIndex;
    
    if(isnan(tIndex)) {
        pthread_mutex_lock(&_aLock);
        
        if(!(_aFlags & EGW_ACTOBJ_ACTRFLG_REVERSE)) {
            if(!isnan(_actions->tBounds[_caIndex].tBegin))
                tIndex = _actions->tBounds[_caIndex].tBegin;
            else if(!isnan(_actions->tBounds[_caIndex].tEnd) && _actions->tBounds[_caIndex].tEnd < (EGWtime)0.0)
                tIndex = _actions->tBounds[_caIndex].tEnd;
            else
                tIndex = (EGWtime)0.0;
        } else {
            if(!isnan(_actions->tBounds[_caIndex].tEnd))
                tIndex = _actions->tBounds[_caIndex].tEnd;
            else if(!isnan(_actions->tBounds[_caIndex].tBegin) && _actions->tBounds[_caIndex].tBegin > (EGWtime)0.0)
                tIndex = _actions->tBounds[_caIndex].tBegin;
            else
                tIndex = (EGWtime)0.0;
        }
        
        pthread_mutex_unlock(&_aLock);
    }
    
    pthread_mutex_lock(&_oLock);
    
    // Target invocations
    egwSinglyLinkedListIter iter;
    if(egwSLListEnumerateStart(&_tOutputs, EGW_ITERATE_MODE_DFLT, &iter)) {
        egwActionedTimerTarget* targetItem;
        
        while(targetItem = (egwActionedTimerTarget*)egwSLListEnumerateNextPtr(&iter))
            targetItem->fpEval(targetItem->tObj, @selector(evaluateToTime:), tIndex);
    }
    
    pthread_mutex_unlock(&_oLock);
}

- (void)evaluateTimerAt:(EGWtime)time {
    pthread_mutex_lock(&_oLock);
    
    // Target invocations
    egwSinglyLinkedListIter iter;
    if(egwSLListEnumerateStart(&_tOutputs, EGW_ITERATE_MODE_DFLT, &iter)) {
        egwActionedTimerTarget* targetItem;
        
        while(targetItem = (egwActionedTimerTarget*)egwSLListEnumerateNextPtr(&iter))
            targetItem->fpEval(targetItem->tObj, @selector(evaluateToTime:), time);
    }
    
    pthread_mutex_unlock(&_oLock);
}

- (void)startActuating {
    [egwSIPhyAct actuateObject:self];
}

- (void)stopActuating {
    [egwSIPhyAct removeObject:self];
}

- (void)update:(EGWtime)deltaT withFlags:(EGWuint)flags {
    if(flags & EGW_ACTOBJ_RPLYFLG_DOUPDATEPASS) {
        if(!_isActuating || _isPaused) return;
        
        // deltaT modification
        switch(_aFlags & EGW_ACTOBJ_ACTRFLG_EXTHROTTLE) {
            case EGW_ACTOBJ_ACTRFLG_THROTTLE20:  deltaT *= (EGWtime)0.20; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE25:  deltaT *= (EGWtime)0.25; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE33:  deltaT *= (EGWtime)0.33; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE50:  deltaT *= (EGWtime)0.50; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE66:  deltaT *= (EGWtime)0.66; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE75:  deltaT *= (EGWtime)0.75; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE88:  deltaT *= (EGWtime)0.88; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE125: deltaT *= (EGWtime)1.25; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE150: deltaT *= (EGWtime)1.50; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE200: deltaT *= (EGWtime)2.00; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE250: deltaT *= (EGWtime)2.50; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE300: deltaT *= (EGWtime)3.00; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE400: deltaT *= (EGWtime)4.00; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE500: deltaT *= (EGWtime)5.00; break;
            default: break;
        }
        
        EGWtime overflow = (EGWtime)0.0;
        
        pthread_mutex_lock(&_aLock);
        
        if(!(_aFlags & EGW_ACTOBJ_ACTRFLG_REVERSE)) { // Forward timer
            _tIndex += deltaT;
            
            ForwardBoundsCheck:
            
            if(!isnan(_actions->tBounds[_caIndex].tEnd) && _tIndex >= _actions->tBounds[_caIndex].tEnd - EGW_TIME_EPSILON || _isBreaking) { // Hit end
                overflow = _tIndex - _actions->tBounds[_caIndex].tEnd;
                if(overflow <= EGW_TIME_EPSILON) overflow = (EGWtime)0.0;
                
                _tIndex = _actions->tBounds[_caIndex].tEnd;
                
                if(_delegate) {
                    pthread_mutex_unlock(&_aLock);
                    [_delegate actionedTimer:self action:_caIndex did:(!_isBreaking ? EGW_ACTION_FINISH : EGW_ACTION_STOP)];
                    pthread_mutex_lock(&_aLock);
                }
                
                if(!(_aFlags & EGW_ACTOBJ_ACTRFLG_REVERSE))
                    goto ForwardToNextAction;
                else
                    goto ReverseToNextAction;
                
                ForwardToNextAction:
                
                if(_aQueue.eCount || _isBreaking) { // Dequeue next action
                    if(!_isBreaking) {
                        _caIndex = ((egwActionedTimerQueueItem*)egwCycArrayElementPtrHead(&_aQueue))->actIndex;
                        egwCycArrayRemoveHead(&_aQueue);
                    } else {
                        overflow = (EGWtime)0.0;
                        _caIndex = _baIndex;
                        _isBreaking = NO;
                    }
                    
                    if(!isnan(_actions->tBounds[_caIndex].tBegin))
                        _tIndex = _actions->tBounds[_caIndex].tBegin;
                    else if(!isnan(_actions->tBounds[_caIndex].tEnd) && _actions->tBounds[_caIndex].tEnd < (EGWtime)0.0)
                        _tIndex = _actions->tBounds[_caIndex].tEnd;
                    else
                        _tIndex = (EGWtime)0.0;
                    
                    if(_delegate) {
                        pthread_mutex_unlock(&_aLock);
                        [_delegate actionedTimer:self action:_caIndex did:EGW_ACTION_START];
                        pthread_mutex_lock(&_aLock);
                    }
                    
                    if(!(_aFlags & EGW_ACTOBJ_ACTRFLG_REVERSE)) {
                        _tIndex += overflow;
                        goto ForwardBoundsCheck;
                    } else {
                        _tIndex -= overflow;
                        goto ReverseBoundsCheck;
                    }
                } else {
                    if(_caIndex != _actions->daIndex && (_aFlags & EGW_ACTOBJ_ACTRFLG_AUTOENQDS)) { // Specialty, dequeue to default action
                        _caIndex = _actions->daIndex;
                        
                        if(!isnan(_actions->tBounds[_caIndex].tBegin))
                            _tIndex = _actions->tBounds[_caIndex].tBegin;
                        else if(!isnan(_actions->tBounds[_caIndex].tEnd) && _actions->tBounds[_caIndex].tEnd < (EGWtime)0.0)
                            _tIndex = _actions->tBounds[_caIndex].tEnd;
                        else
                            _tIndex = (EGWtime)0.0;
                        
                        if(_delegate) {
                            pthread_mutex_unlock(&_aLock);
                            [_delegate actionedTimer:self action:_caIndex did:EGW_ACTION_START];
                            pthread_mutex_lock(&_aLock);
                        }
                        
                        if(!(_aFlags & EGW_ACTOBJ_ACTRFLG_REVERSE)) {
                            _tIndex += overflow;
                            goto ForwardBoundsCheck;
                        } else {
                            _tIndex -= overflow;
                            goto ReverseBoundsCheck;
                        }
                    } else { // No more next-actions, do last-state looping
                        if(_aFlags & EGW_ACTOBJ_ACTRFLG_LOOPING) { // Looping
                            if(!isnan(_actions->tBounds[_caIndex].tBegin))
                                _tIndex = _actions->tBounds[_caIndex].tBegin;
                            else if(!isnan(_actions->tBounds[_caIndex].tEnd) && _actions->tBounds[_caIndex].tEnd < (EGWtime)0.0)
                                _tIndex = _actions->tBounds[_caIndex].tEnd;
                            else
                                _tIndex = (EGWtime)0.0;
                            
                            if(_delegate) {
                                pthread_mutex_unlock(&_aLock);
                                [_delegate actionedTimer:self action:_caIndex did:(EGW_ACTION_START | EGW_ACTION_LOOPED)];
                                pthread_mutex_lock(&_aLock);
                            }
                            
                            if(!(_aFlags & EGW_ACTOBJ_ACTRFLG_REVERSE)) {
                                _tIndex += overflow;
                                goto ForwardBoundsCheck;
                            } else {
                                _tIndex -= overflow;
                                goto ReverseBoundsCheck;
                            }
                        } else { // Not looping
                            _isFinished = YES;
                        }
                    }
                }
            }
        } else { // Reverse timer
            _tIndex -= deltaT;
            
            ReverseBoundsCheck:
            
            if(!isnan(_actions->tBounds[_caIndex].tBegin) && _tIndex <= _actions->tBounds[_caIndex].tBegin + EGW_TIME_EPSILON || _isBreaking) { // Hit begin
                overflow = _actions->tBounds[_caIndex].tBegin - _tIndex;
                if(overflow <= EGW_TIME_EPSILON) overflow = (EGWtime)0.0;
                
                _tIndex = _actions->tBounds[_caIndex].tBegin;
                
                if(_delegate) {
                    pthread_mutex_unlock(&_aLock);
                    [_delegate actionedTimer:self action:_caIndex did:(!_isBreaking ? EGW_ACTION_FINISH : EGW_ACTION_STOP)];
                    pthread_mutex_lock(&_aLock);
                }
                
                if(_aFlags & EGW_ACTOBJ_ACTRFLG_REVERSE)
                    goto ReverseToNextAction;
                else
                    goto ForwardToNextAction;
                
                ReverseToNextAction:
                
                if(_aQueue.eCount || _isBreaking) { // Dequeue next action
                    if(!_isBreaking) {
                        _caIndex = ((egwActionedTimerQueueItem*)egwCycArrayElementPtrHead(&_aQueue))->actIndex;
                        egwCycArrayRemoveHead(&_aQueue);
                    } else {
                        overflow = (EGWtime)0.0;
                        _caIndex = _baIndex;
                        _isBreaking = NO;
                    }
                    
                    if(!isnan(_actions->tBounds[_caIndex].tEnd))
                        _tIndex = _actions->tBounds[_caIndex].tEnd;
                    else if(!isnan(_actions->tBounds[_caIndex].tBegin) && _actions->tBounds[_caIndex].tBegin > (EGWtime)0.0)
                        _tIndex = _actions->tBounds[_caIndex].tBegin;
                    else
                        _tIndex = (EGWtime)0.0;
                    
                    if(_delegate) {
                        pthread_mutex_unlock(&_aLock);
                        [_delegate actionedTimer:self action:_caIndex did:EGW_ACTION_START];
                        pthread_mutex_lock(&_aLock);
                    }
                    
                    if(_aFlags & EGW_ACTOBJ_ACTRFLG_REVERSE) {
                        _tIndex -= overflow;
                        goto ReverseBoundsCheck;
                    } else {
                        _tIndex += overflow;
                        goto ForwardBoundsCheck;
                    }
                } else {
                    if(_caIndex != _actions->daIndex && (_aFlags & EGW_ACTOBJ_ACTRFLG_AUTOENQDS)) { // Specialty, dequeue to default action
                        _caIndex = _actions->daIndex;
                        
                        if(!isnan(_actions->tBounds[_caIndex].tEnd))
                            _tIndex = _actions->tBounds[_caIndex].tEnd;
                        else if(!isnan(_actions->tBounds[_caIndex].tBegin) && _actions->tBounds[_caIndex].tBegin > (EGWtime)0.0)
                            _tIndex = _actions->tBounds[_caIndex].tBegin;
                        else
                            _tIndex = (EGWtime)0.0;
                        
                        if(_delegate) {
                            pthread_mutex_unlock(&_aLock);
                            [_delegate actionedTimer:self action:_caIndex did:EGW_ACTION_START];
                            pthread_mutex_lock(&_aLock);
                        }
                        
                        if(_aFlags & EGW_ACTOBJ_ACTRFLG_REVERSE) {
                            _tIndex -= overflow;
                            goto ReverseBoundsCheck;
                        } else {
                            _tIndex += overflow;
                            goto ForwardBoundsCheck;
                        }
                    } else { // No more next-actions, do last-state looping
                        if(_aFlags & EGW_ACTOBJ_ACTRFLG_LOOPING) { // Looping
                            if(!isnan(_actions->tBounds[_caIndex].tEnd))
                                _tIndex = _actions->tBounds[_caIndex].tEnd;
                            else if(!isnan(_actions->tBounds[_caIndex].tBegin) && _actions->tBounds[_caIndex].tBegin > (EGWtime)0.0)
                                _tIndex = _actions->tBounds[_caIndex].tBegin;
                            else
                                _tIndex = (EGWtime)0.0;
                            
                            if(_delegate) {
                                pthread_mutex_unlock(&_aLock);
                                [_delegate actionedTimer:self action:_caIndex did:(EGW_ACTION_START | EGW_ACTION_LOOPED)];
                                pthread_mutex_lock(&_aLock);
                            }
                            
                            if(_aFlags & EGW_ACTOBJ_ACTRFLG_REVERSE) {
                                _tIndex -= overflow;
                                goto ReverseBoundsCheck;
                            } else {
                                _tIndex += overflow;
                                goto ForwardBoundsCheck;
                            }
                        } else { // Not looping
                            _isFinished = YES;
                        }
                    }
                }
            }
        }
        
        pthread_mutex_unlock(&_aLock);
        
        pthread_mutex_lock(&_oLock);
        
        // Target invocations
        egwSinglyLinkedListIter iter;
        if(egwSLListEnumerateStart(&_tOutputs, EGW_ITERATE_MODE_DFLT, &iter)) {
            egwActionedTimerTarget* targetItem;
            
            while(targetItem = (egwActionedTimerTarget*)egwSLListEnumerateNextPtr(&iter))
                targetItem->fpEval(targetItem->tObj, @selector(evaluateToTime:), _tIndex);
        }
        
        pthread_mutex_unlock(&_oLock);
        
        if(_isFinished && _delegate)
            [_delegate timer:self did:EGW_ACTION_FINISH];
    } else if(flags & EGW_ACTOBJ_RPLYFLG_DOUPDATESTART) {
        if(!_isActuating) {
            if(isnan(_tIndex)) {
                pthread_mutex_lock(&_aLock);
                
                if(!(_aFlags & EGW_ACTOBJ_ACTRFLG_REVERSE)) {
                    if(!isnan(_actions->tBounds[_caIndex].tBegin))
                        _tIndex = _actions->tBounds[_caIndex].tBegin;
                    else if(!isnan(_actions->tBounds[_caIndex].tEnd) && _actions->tBounds[_caIndex].tEnd < (EGWtime)0.0)
                        _tIndex = _actions->tBounds[_caIndex].tEnd;
                    else
                        _tIndex = (EGWtime)0.0;
                } else {
                    if(!isnan(_actions->tBounds[_caIndex].tEnd))
                        _tIndex = _actions->tBounds[_caIndex].tEnd;
                    else if(!isnan(_actions->tBounds[_caIndex].tBegin) && _actions->tBounds[_caIndex].tBegin > (EGWtime)0.0)
                        _tIndex = _actions->tBounds[_caIndex].tBegin;
                    else
                        _tIndex = (EGWtime)0.0;
                }
                
                pthread_mutex_unlock(&_aLock);
            }
            
            _isFinished = NO;
            _isPaused = NO;
            _isActuating = YES;
            
            if(_delegate)
                [_delegate timer:self did:EGW_ACTION_START];
        } else { // If already actuating, then restart
            if(!(_aFlags & EGW_ACTOBJ_ACTRFLG_LOOPING)) {
                pthread_mutex_lock(&_aLock);
                
                if(!(_aFlags & EGW_ACTOBJ_ACTRFLG_REVERSE)) {
                    if(!isnan(_actions->tBounds[_caIndex].tBegin))
                        _tIndex = _actions->tBounds[_caIndex].tBegin;
                    else if(!isnan(_actions->tBounds[_caIndex].tEnd) && _actions->tBounds[_caIndex].tEnd < (EGWtime)0.0)
                        _tIndex = _actions->tBounds[_caIndex].tEnd;
                    else
                        _tIndex = (EGWtime)0.0;
                } else {
                    if(!isnan(_actions->tBounds[_caIndex].tEnd))
                        _tIndex = _actions->tBounds[_caIndex].tEnd;
                    else if(!isnan(_actions->tBounds[_caIndex].tBegin) && _actions->tBounds[_caIndex].tBegin > (EGWtime)0.0)
                        _tIndex = _actions->tBounds[_caIndex].tBegin;
                    else
                        _tIndex = (EGWtime)0.0;
                }
                
                pthread_mutex_unlock(&_aLock);
            }
            
            _isFinished = NO;
            _isPaused = NO;
            _isActuating = YES;
            
            if(_delegate)
                [_delegate timer:self did:EGW_ACTION_RESTART];
        }
    } else if(flags & EGW_ACTOBJ_RPLYFLG_DOUPDATEPAUSE) {
        if(_isActuating) {
            if(!_isPaused) {
                _isPaused = YES;
            } else {
                _isPaused = NO;
            }
            
            if(_delegate)
                [_delegate timer:self did:(_isPaused ? EGW_ACTION_PAUSE : EGW_ACTION_UNPAUSE)];
        }
    } else if(flags & EGW_ACTOBJ_RPLYFLG_DOUPDATESTOP) {
        if(_isActuating) {
            _tIndex = EGW_TIME_NAN;
            
            _isActuating = NO;
            _isPaused = NO;
            
            if(_delegate)
                [_delegate timer:self did:EGW_ACTION_STOP];
        }
    }
}

- (EGWtime)actionBoundsBegin:(EGWuint16)actIndex {
    return _actions->tBounds[actIndex].tBegin;
}

- (EGWtime)actionBoundsEnd:(EGWuint16)actIndex {
    return _actions->tBounds[actIndex].tEnd;
}

- (EGWint16)actionIndexOffset {
    EGWint16 retVal;
    
    pthread_mutex_lock(&_aLock);
    
    retVal = _caOffset;
    
    pthread_mutex_unlock(&_aLock);
    
    return retVal;
}

- (EGWuint16)actuatorFlags {
    return _aFlags;
}

- (id<egwPAssetBase>)assetBase {
    return _base;
}

- (EGWuint)coreObjectTypes {
    return (EGW_COREOBJ_TYPE_ACTUATOR | EGW_COREOBJ_TYPE_TIMER);
}

- (EGWuint16)currentAction {
    EGWuint16 retVal;
    
    pthread_mutex_lock(&_aLock);
    
    retVal = _caIndex;
    
    pthread_mutex_unlock(&_aLock);
    
    return retVal;
}

- (EGWuint16)defaultAction {
    return _actions->daIndex;
}

- (NSString*)identity {
    return _ident;
}

- (EGWtime)timeIndex {
    EGWtime retVal;
    
    pthread_mutex_lock(&_aLock);
    
    if(!isnan(_tIndex)) {
        if(_tIndex < _actions->tBounds[_caIndex].tBegin)
            retVal = _actions->tBounds[_caIndex].tBegin;
        if(_tIndex > _actions->tBounds[_caIndex].tEnd)
            retVal = _actions->tBounds[_caIndex].tEnd;
    } else
        retVal = _tIndex;
    
    pthread_mutex_unlock(&_aLock);
    
    return retVal;
}

- (EGWtime)timerBoundsBegin {
    return _otBounds.tBegin;
}

- (EGWtime)timerBoundsEnd {
    return _otBounds.tEnd;
}

- (EGWuint16)availableActionsCount {
    return _actions->aCount;
}

- (EGWuint16)queuedActionsCount {
    EGWuint16 retVal;
    
    pthread_mutex_lock(&_aLock);
    
    retVal = _aQueue.eCount;
    
    pthread_mutex_unlock(&_aLock);
    
    return retVal;
}

- (void)setAction:(EGWuint16)actIndex timeBoundsBegin:(EGWtime)begin andEnd:(EGWtime)end {
    _actions->tBounds[actIndex].tBegin = begin;
    _actions->tBounds[actIndex].tEnd = end;
}

- (void)setActionIndexOffset:(EGWint16)offset {
    pthread_mutex_lock(&_aLock);
    
    if(_caOffset != offset) {
        EGWint16 diffOffset = offset - _caOffset;
        
        egwCyclicArrayIter iter;
        if(egwCycArrayEnumerateStart(&_aQueue, EGW_ITERATE_MODE_DFLT, &iter)) {
            egwActionedTimerQueueItem* actionItem;
            
            while(actionItem = (egwActionedTimerQueueItem*)egwCycArrayEnumerateNextPtr(&iter))
                actionItem->actIndex += diffOffset;
        }
        
        _baIndex += diffOffset;
        
        if(!isnan(_tIndex)) {
            EGWtime currBegIndex;
            if(!isnan(_actions->tBounds[_caIndex].tBegin))
                currBegIndex = _actions->tBounds[_caIndex].tBegin;
            else if(!isnan(_actions->tBounds[_caIndex].tEnd) && _actions->tBounds[_caIndex].tEnd < (EGWtime)0.0)
                currBegIndex = _actions->tBounds[_caIndex].tEnd;
            else
                currBegIndex = (EGWtime)0.0;
            
            EGWtime currEndIndex;
            if(!isnan(_actions->tBounds[_caIndex].tEnd))
                currEndIndex = _actions->tBounds[_caIndex].tEnd;
            else if(!isnan(_actions->tBounds[_caIndex].tBegin) && _actions->tBounds[_caIndex].tBegin > (EGWtime)0.0)
                currEndIndex = _actions->tBounds[_caIndex].tBegin;
            else
                currEndIndex = (EGWtime)0.0;
            
            EGWtime nextBegIndex;
            if(!isnan(_actions->tBounds[_caIndex+diffOffset].tBegin))
                nextBegIndex = _actions->tBounds[_caIndex+diffOffset].tBegin;
            else if(!isnan(_actions->tBounds[_caIndex+diffOffset].tEnd) && _actions->tBounds[_caIndex+diffOffset].tEnd < (EGWtime)0.0)
                nextBegIndex = _actions->tBounds[_caIndex+diffOffset].tEnd;
            else
                nextBegIndex = (EGWtime)0.0;
            
            EGWtime nextEndIndex;
            if(!isnan(_actions->tBounds[_caIndex+diffOffset].tEnd))
                nextEndIndex = _actions->tBounds[_caIndex+diffOffset].tEnd;
            else if(!isnan(_actions->tBounds[_caIndex+diffOffset].tBegin) && _actions->tBounds[_caIndex+diffOffset].tBegin > (EGWtime)0.0)
                nextEndIndex = _actions->tBounds[_caIndex+diffOffset].tBegin;
            else
                nextEndIndex = (EGWtime)0.0;
            
            _tIndex = nextBegIndex + (((_tIndex - currBegIndex) / (currEndIndex - currBegIndex)) * (nextEndIndex - nextBegIndex));
        }
        
        _caIndex += diffOffset;
        _caOffset = offset;
    }
    
    pthread_mutex_unlock(&_aLock);
}

- (void)setActuatorFlags:(EGWuint16)flags {
    _aFlags = flags;
}

- (void)setDelegate:(id<egwDActionedTimerEvent>)delegate {
    [delegate retain];
    [_delegate release];
    _delegate = delegate;
}

- (void)setTimeIndex:(EGWtime)time {
    if(!isnan(time)) {
        if(!isnan(_actions->tBounds[_caIndex].tBegin) && time < _actions->tBounds[_caIndex].tBegin)
            time = _actions->tBounds[_caIndex].tBegin;
        if(!isnan(_actions->tBounds[_caIndex].tEnd) && time > _actions->tBounds[_caIndex].tEnd)
            time = _actions->tBounds[_caIndex].tEnd;
        _tIndex = time;
    }
}

- (BOOL)isAnOwner:(id<egwPTimed>)owner {
    pthread_mutex_lock(&_oLock);
    
    egwSinglyLinkedListIter iter;
    if(egwSLListEnumerateStart(&_tOutputs, EGW_ITERATE_MODE_DFLT, &iter)) {
        egwActionedTimerTarget* targetItem;
        
        while(targetItem = (egwActionedTimerTarget*)egwSLListEnumerateNextPtr(&iter))
            if(targetItem->tObj == owner) {
                pthread_mutex_unlock(&_oLock);
                return YES;
            }
    }
    
    pthread_mutex_unlock(&_oLock);
    
    return NO;
}

- (BOOL)isActuating {
    return _isActuating;
}

- (BOOL)isFinished {
    return _isFinished;
}

- (BOOL)isPaused {
    return _isPaused;
}

@end


@implementation egwActionedTimerBase

+ (id)allocWithZone:(NSZone*)zone {
    id alloc = [super allocWithZone:zone];
    if(alloc) [egwAssetManager incBaseRef];
    if(EGW_ENGINE_ASSETS_CREATIONMSGS) NSLog(@"egwActionedTimerBase: allocWithZone: Creating new actioned timer base asset (%p).", alloc);
    return alloc;
}

- (id)init {
    if([self isMemberOfClass:[egwActionedTimerBase class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent actionsSet:(egwAbsTimedActions*)actions {
    if(!(actions && actions->tBounds && (self = [super init]))) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    if(!(_actions = (egwAbsTimedActions*)malloc(sizeof(egwAbsTimedActions)))) { [self release]; return (self = nil); }
    memcpy((void*)_actions, (const void*)actions, sizeof(egwAbsTimedActions));
    memset((void*)actions, 0, sizeof(egwAbsTimedActions));
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    return nil;
}

- (id)mutableCopyWithZone:(NSZone*)zone {
    return nil;
}

- (void)dealloc {
    _instCounter = NSNotFound;
    
    if(_actions) {
        if(_actions->tBounds) {
            free((void*)_actions->tBounds); _actions->tBounds = NULL;
        }
        if(_actions->aNames) {
            for(EGWint actIndex = 0; actIndex < _actions->aCount; ++actIndex)
                if(_actions->aNames[actIndex]) {
                    free((void*)_actions->aNames[actIndex]); _actions->aNames[actIndex] = NULL;
                }
            free((void*)_actions->aNames); _actions->aNames = NULL;
        }
        free((void*)_actions); _actions = NULL;
    }
    
    if(EGW_ENGINE_ASSETS_DESTROYMSGS) NSLog(@"egwActionedTimerBase: dealloc: Destroying actioned timer base asset '%@' (%p).", _ident, self);
    [_ident release]; _ident = nil;
    [egwAssetManager decBaseRef];
    [super dealloc];
}

- (egwAbsTimedActions*)actionsSet {
    return _actions;
}

- (NSString*)identity {
    return _ident;
}

- (EGWuint)nextInstanceIndex {
    return ++_instCounter;
}

@end

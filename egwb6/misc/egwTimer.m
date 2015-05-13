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

/// @file egwTimer.m
/// @ingroup geWizES_misc_timer
/// Timer Asset Implementation.

#import <pthread.h>
#import "egwTimer.h"
#import "../sys/egwPhyContext.h"
#import "../sys/egwPhyActuator.h"
#import "../data/egwSinglyLinkedList.h"
#import "../math/egwMath.h"
#import "../misc/egwValidater.h"


typedef struct {
    id<egwPTimed> tObj;                     // Target object (weak).
    id (*fpEval)(id, SEL, EGWtime);         // IMP to evaluateToTime:.
} egwTimerTarget;


@implementation egwTimer

static egwActuatorJumpTable _egwAJT = { NULL };

+ (id)allocWithZone:(NSZone*)zone {
    NSObject* inst = (NSObject*)[super allocWithZone:zone];
    
    if(!_egwAJT.fpRetain && [inst isMemberOfClass:[egwTimer class]]) {
        _egwAJT.fpRetain = (id(*)(id, SEL))[inst methodForSelector:@selector(retain)];
        _egwAJT.fpRelease = (void(*)(id, SEL))[inst methodForSelector:@selector(release)];
        _egwAJT.fpUpdate = (void(*)(id, SEL, EGWtime, EGWuint))[inst methodForSelector:@selector(update:withFlags:)];
        _egwAJT.fpABase = (id<NSObject>(*)(id, SEL))[inst methodForSelector:@selector(assetBase)];
        _egwAJT.fpAFlags = (EGWuint32(*)(id, SEL))[inst methodForSelector:@selector(actuatorFlags)];
        _egwAJT.fpActuating = (BOOL(*)(id, SEL))[inst methodForSelector:@selector(isActuating)];
        _egwAJT.fpFinished = (BOOL(*)(id, SEL))[inst methodForSelector:@selector(isFinished)];
    }
    
    return (id)inst;
}

- (id)init {
    if([self isMemberOfClass:[egwTimer class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    if(!egwSLListInit(&_tOutputs, NULL, sizeof(egwTimerTarget), EGW_LIST_FLG_NONE)) { [self release]; return (self = nil); } // Owners are never retained
    if(pthread_mutex_init(&_oLock, NULL)) { [self release]; return (self = nil); }
    
    _aFlags = EGW_ACTOBJ_ACTRFLG_DFLT;
    
    _tIndex = _otBounds.tBegin = _otBounds.tEnd = EGW_TIME_NAN;
    
    return self;
}

- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent {
    if(!([asset isKindOfClass:[self class]]) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    if(!egwSLListInit(&_tOutputs, NULL, sizeof(egwTimerTarget), EGW_LIST_FLG_NONE)) { [self release]; return (self = nil); } // Owners are never retained
    if(pthread_mutex_init(&_oLock, NULL)) { [self release]; return (self = nil); }
    
    _aFlags = [(egwTimer*)asset actuatorFlags];
    
    _tIndex = _otBounds.tBegin = _otBounds.tEnd = EGW_TIME_NAN;
    
    _isExplicitBound = [(egwTimer*)asset isExplicitlyBounded];
    if(_isExplicitBound) {
        _otBounds.tBegin = [(egwTimer*)asset timerBoundsBegin];
        _otBounds.tEnd = [(egwTimer*)asset timerBoundsEnd];
    }
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwTimer* copy = nil;
    NSString* copyIdent = nil;
    
    copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwTimer allocWithZone:zone] initCopyOf:self
                                             withIdentity:copyIdent])) {
        NSLog(@"egwTimer: copyWithZone: Failure initializing new timer from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    return copy;
}

- (void)dealloc {
    egwSLListFree(&_tOutputs);
    pthread_mutex_destroy(&_oLock);
    
    [_delegate release]; _delegate = nil;
    [_ident release]; _ident = nil;
    
    [super dealloc];
}

- (void)addOwner:(id<egwPTimed>)owner {
    pthread_mutex_lock(&_oLock);
    
    egwTimerTarget targetItem;
    targetItem.tObj = owner;
    targetItem.fpEval = (id(*)(id, SEL, EGWtime))[((NSObject*)targetItem.tObj) methodForSelector:@selector(evaluateToTime:)];
    
    egwSLListAddTail(&_tOutputs, (const EGWbyte*)&targetItem);
    
    if(!_isExplicitBound) {
        EGWtime eBegin = [targetItem.tObj evaluationBoundsBegin];
        EGWtime eEnd = [targetItem.tObj evaluationBoundsEnd];
        
        // Auto-expand beginning boundary
        if(_tOutputs.eCount == 1 || isnan(eBegin) || (!isnan(_otBounds.tBegin) && eBegin < _otBounds.tBegin)) {
            _otBounds.tBegin = eBegin;
            if(!isnan(_otBounds.tBegin) && !isnan(_tIndex) && _tIndex < _otBounds.tBegin)
                _tIndex = _otBounds.tBegin;
        }
        
        // Auto-expand ending boundary
        if(_tOutputs.eCount == 1 || isnan(eEnd) || (!isnan(_otBounds.tEnd) && eEnd > _otBounds.tEnd)) {
            _otBounds.tEnd = eEnd;
            if(!isnan(_otBounds.tEnd) && !isnan(_tIndex) && _tIndex > _otBounds.tEnd)
                _tIndex = _otBounds.tEnd;
        }
    }
    
    pthread_mutex_unlock(&_oLock);
}

- (void)removeOwner:(id<egwPTimed>)owner {
    pthread_mutex_lock(&_oLock);
    
    egwSinglyLinkedListIter iter;
    if(egwSLListEnumerateStart(&_tOutputs, EGW_ITERATE_MODE_DFLT, &iter)) {
        egwTimerTarget* targetItem;
        egwSinglyLinkedListNode* prev = NULL;
        EGWtime eBegin, nBegin = EGW_TIME_MAX;
        EGWtime eEnd, nEnd = -EGW_TIME_MAX;
        
        while(targetItem = (egwTimerTarget*)egwSLListEnumerateNextPtr(&iter)) {
            if(targetItem->tObj != owner) { // Not the droid you're looking for
                if(!_isExplicitBound) {
                    // Auto-contract start & finish boundaries (requires full rebuild)
                    eBegin = [targetItem->tObj evaluationBoundsBegin];
                    eEnd = [targetItem->tObj evaluationBoundsEnd];
                    
                    if(isnan(eBegin) || (!isnan(nBegin) && eBegin < nBegin))
                        nBegin = eBegin;
                    if(isnan(eEnd) || (!isnan(nEnd) && eEnd > nEnd))
                        nEnd = eEnd;
                    
                    prev = egwSLListNodePtr((const EGWbyte*)targetItem);
                }
            } else { // Remove target item
                egwSLListRemoveAfter(&_tOutputs, prev);
            }
        }
        
        if(!_isExplicitBound) {
            if(_tOutputs.eCount != 0) {
                _otBounds.tBegin = nBegin;
                _otBounds.tEnd = nEnd;
            } else {
                _otBounds.tBegin = _otBounds.tEnd = EGW_TIME_NAN;
            }
            
            if(!isnan(_otBounds.tBegin) && !isnan(_tIndex) && _tIndex < _otBounds.tBegin)
                _tIndex = _otBounds.tBegin;
            if(!isnan(_otBounds.tEnd) && !isnan(_tIndex) && _tIndex > _otBounds.tEnd)
                _tIndex = _otBounds.tEnd;
        }
    }
    
    pthread_mutex_unlock(&_oLock);
}

- (void)evaluateTimer {
    EGWtime tIndex = _tIndex;
    
    if(isnan(tIndex)) {
        if(!(_aFlags & EGW_ACTOBJ_ACTRFLG_REVERSE)) {
            if(!isnan(_otBounds.tBegin))
                tIndex = _otBounds.tBegin;
            else if(!isnan(_otBounds.tEnd) && _otBounds.tEnd < (EGWtime)0.0)
                tIndex = _otBounds.tEnd;
            else
                tIndex = (EGWtime)0.0;
        } else {
            if(!isnan(_otBounds.tEnd))
                tIndex = _otBounds.tEnd;
            else if(!isnan(_otBounds.tBegin) && _otBounds.tBegin > (EGWtime)0.0)
                tIndex = _otBounds.tBegin;
            else
                tIndex = (EGWtime)0.0;
        }
    }
    
    pthread_mutex_lock(&_oLock);
    
    // Target invocations
    egwSinglyLinkedListIter iter;
    if(egwSLListEnumerateStart(&_tOutputs, EGW_ITERATE_MODE_DFLT, &iter)) {
        egwTimerTarget* targetItem;
        
        while(targetItem = (egwTimerTarget*)egwSLListEnumerateNextPtr(&iter))
            targetItem->fpEval(targetItem->tObj, @selector(evaluateToTime:), tIndex);
    }
    
    pthread_mutex_unlock(&_oLock);
}

- (void)evaluateTimerAt:(EGWtime)time {
    pthread_mutex_lock(&_oLock);
    
    // Target invocations
    egwSinglyLinkedListIter iter;
    if(egwSLListEnumerateStart(&_tOutputs, EGW_ITERATE_MODE_DFLT, &iter)) {
        egwTimerTarget* targetItem;
        
        while(targetItem = (egwTimerTarget*)egwSLListEnumerateNextPtr(&iter))
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
        
        if(!(_aFlags & EGW_ACTOBJ_ACTRFLG_REVERSE)) { // Forward timer
            _tIndex += deltaT;
            
            ForwardBoundsCheck:
            
            if(!isnan(_otBounds.tEnd) && _tIndex >= _otBounds.tEnd - EGW_TIME_EPSILON) { // Hit end
                EGWtime overflow = _tIndex - _otBounds.tEnd;
                if(overflow <= EGW_TIME_EPSILON) overflow = (EGWtime)0.0;
                
                _tIndex = _otBounds.tEnd;
                
                if(_aFlags & EGW_ACTOBJ_ACTRFLG_LOOPING) { // Looping
                    if(!isnan(_otBounds.tBegin))
                        _tIndex = _otBounds.tBegin;
                    else if(!isnan(_otBounds.tEnd) && _otBounds.tEnd < (EGWtime)0.0)
                        _tIndex = _otBounds.tEnd;
                    else
                        _tIndex = (EGWtime)0.0;
                    
                    if(_delegate)
                        [_delegate timer:self did:EGW_ACTION_LOOPED];
                    
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
        } else { // Reverse timer
            _tIndex -= deltaT;
            
            ReverseBoundsCheck:
            
            if(!isnan(_otBounds.tBegin) && _tIndex <= _otBounds.tBegin + EGW_TIME_EPSILON) { // Hit begin
                EGWtime overflow = _otBounds.tBegin - _tIndex;
                if(overflow <= EGW_TIME_EPSILON) overflow = (EGWtime)0.0;
                
                _tIndex = _otBounds.tBegin;
                
                if(_aFlags & EGW_ACTOBJ_ACTRFLG_LOOPING) { // Looping
                    if(!isnan(_otBounds.tEnd))
                        _tIndex = _otBounds.tEnd;
                    else if(!isnan(_otBounds.tBegin) && _otBounds.tBegin > (EGWtime)0.0)
                        _tIndex = _otBounds.tBegin;
                    else
                        _tIndex = (EGWtime)0.0;
                    
                    if(_delegate)
                        [_delegate timer:self did:EGW_ACTION_LOOPED];
                    
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
        
        pthread_mutex_lock(&_oLock);
        
        // Target invocations
        egwSinglyLinkedListIter iter;
        if(egwSLListEnumerateStart(&_tOutputs, EGW_ITERATE_MODE_DFLT, &iter)) {
            egwTimerTarget* targetItem;
            
            while(targetItem = (egwTimerTarget*)egwSLListEnumerateNextPtr(&iter))
                targetItem->fpEval(targetItem->tObj, @selector(evaluateToTime:), _tIndex);
        }
        
        pthread_mutex_unlock(&_oLock);
        
        if(_isFinished && _delegate)
            [_delegate timer:self did:EGW_ACTION_FINISH];
    } else if(flags & EGW_ACTOBJ_RPLYFLG_DOUPDATESTART) {
        if(!_isActuating) {
            if(isnan(_tIndex)) {
                if(!(_aFlags & EGW_ACTOBJ_ACTRFLG_REVERSE)) {
                    if(!isnan(_otBounds.tBegin))
                        _tIndex = _otBounds.tBegin;
                    else if(!isnan(_otBounds.tEnd) && _otBounds.tEnd < (EGWtime)0.0)
                        _tIndex = _otBounds.tEnd;
                    else
                        _tIndex = (EGWtime)0.0;
                } else {
                    if(!isnan(_otBounds.tEnd))
                        _tIndex = _otBounds.tEnd;
                    else if(!isnan(_otBounds.tBegin) && _otBounds.tBegin > (EGWtime)0.0)
                        _tIndex = _otBounds.tBegin;
                    else
                        _tIndex = (EGWtime)0.0;
                }
            }
            
            _isFinished = NO;
            _isPaused = NO;
            _isActuating = YES;
            
            if(_delegate)
                [_delegate timer:self did:EGW_ACTION_START];
        } else { // If already actuating, then restart
            if(!(_aFlags & EGW_ACTOBJ_ACTRFLG_LOOPING)) {
                if(!(_aFlags & EGW_ACTOBJ_ACTRFLG_REVERSE)) {
                    if(!isnan(_otBounds.tBegin))
                        _tIndex = _otBounds.tBegin;
                    else if(!isnan(_otBounds.tEnd) && _otBounds.tEnd < (EGWtime)0.0)
                        _tIndex = _otBounds.tEnd;
                    else
                        _tIndex = (EGWtime)0.0;
                } else {
                    if(!isnan(_otBounds.tEnd))
                        _tIndex = _otBounds.tEnd;
                    else if(!isnan(_otBounds.tBegin) && _otBounds.tBegin > (EGWtime)0.0)
                        _tIndex = _otBounds.tBegin;
                    else
                        _tIndex = (EGWtime)0.0;
                }
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

- (EGWuint16)actuatorFlags {
    return _aFlags;
}

- (const egwActuatorJumpTable*)actuatorJumpTable {
    return &_egwAJT;
}

- (id<egwPAssetBase>)assetBase {
    return nil;
}

- (NSString*)identity {
    return _ident;
}

- (EGWuint)coreObjectTypes {
    return (EGW_COREOBJ_TYPE_ACTUATOR | EGW_COREOBJ_TYPE_TIMER);
}

- (EGWtime)timeIndex {
    if(!isnan(_tIndex)) {
        if(!isnan(_otBounds.tBegin) && _tIndex < _otBounds.tBegin)
            return _otBounds.tBegin;
        if(!isnan(_otBounds.tEnd) && _tIndex > _otBounds.tEnd)
            return _otBounds.tEnd;
    }
    return _tIndex;
}

- (EGWtime)timerBoundsBegin {
    return _otBounds.tBegin;
}

- (EGWtime)timerBoundsEnd {
    return _otBounds.tEnd;
}

- (void)setActuatorFlags:(EGWuint16)flags {
    _aFlags = flags;
}

- (void)setDelegate:(id<egwDTimerEvent>)delegate {
    [delegate retain];
    [_delegate release];
    _delegate = delegate;
}

- (void)setExplicitBoundsBegin:(EGWtime)begin andEnd:(EGWtime)end {
    _isExplicitBound = YES;
    _otBounds.tBegin = begin;
    _otBounds.tEnd = end;
}

- (void)setTimeIndex:(EGWtime)time {
    if(!isnan(time)) {
        if(!isnan(_otBounds.tBegin) && time < _otBounds.tBegin)
            time = _otBounds.tBegin;
        if(!isnan(_otBounds.tEnd) && time > _otBounds.tEnd)
            time = _otBounds.tEnd;
        _tIndex = time;
    }
}

- (BOOL)isAnOwner:(id<egwPTimed>)owner {
    pthread_mutex_lock(&_oLock);
    
    egwSinglyLinkedListIter iter;
    if(egwSLListEnumerateStart(&_tOutputs, EGW_ITERATE_MODE_DFLT, &iter)) {
        egwTimerTarget* targetItem;
        
        while(targetItem = (egwTimerTarget*)egwSLListEnumerateNextPtr(&iter))
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

- (BOOL)isExplicitlyBounded {
    return _isExplicitBound;
}

- (BOOL)isPaused {
    return _isPaused;
}

@end

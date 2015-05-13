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

/// @file egwInterpolators.m
/// @ingroup geWizES_phy_interpolators
/// Interpolator Assets Implementations.

#import <pthread.h>
#import "egwInterpolators.h"
#import "../sys/egwSysTypes.h"
#import "../sys/egwAssetManager.h"
#import "../data/egwSinglyLinkedList.h"
#import "../math/egwMath.h"
#import "../math/egwMatrix.h"
#import "../math/egwQuaternion.h"
#import "../math/egwVector.h"
#import "../phy/egwPhysics.h"
#import "../misc/egwValidater.h"


static void egwIpoAddTarget(egwMultiTargetOutput* element) {
    if(element->oType == 1 && element->oFlags == 1) // address sync retain
        [element->write.address.vSync retain];
    else if(element->oType == 2 && element->oFlags == 1) // message obj retain
        [element->write.message.oObj retain];
}

static void egwIpoRemoveTarget(egwMultiTargetOutput* element) {
    if(element->oType == 1 && element->oFlags == 1) // address sync retain
        [element->write.address.vSync release];
    else if(element->oType == 2 && element->oFlags == 1) // message obj retain
        [element->write.message.oObj release];
}


@implementation egwValueInterpolator

- (id)init {
    if([self isMemberOfClass:[egwValueInterpolator class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent keyFrames:(egwKeyFrame*)frames polationMode:(EGWuint32)polationMode {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwInterpolatorBase alloc] initVIBWithIdentity:assetIdent keyFrames:frames])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _track.pMode = EGW_POLATION_NONE;
    _eAbsT = EGW_TIME_NAN;
    _track.kIndex = -1;
    
    {   egwDataFuncs funcs; memset((void*)&funcs, 0, sizeof(egwDataFuncs));
        funcs.fpAdd = (EGWelementfp)&egwIpoAddTarget;
        funcs.fpRemove = (EGWelementfp)&egwIpoRemoveTarget;
        if(!egwSLListInit(&_tOutputs, &funcs, sizeof(egwMultiTargetOutput), EGW_LIST_FLG_DFLT)) { [self release]; return (self = nil); } // Target objects retain us, but we retain syncs
        if(pthread_mutex_init(&_tLock, NULL)) { [self release]; return (self = nil); }
    }
    
    if(!(_kFrames = [_base keyFrames])) { [self release]; return (self = nil); }
    
    _track.line.chnCount = _kFrames->kcCount;
    _track.line.cmpCount = _kFrames->cCount;
    _track.line.cdPitch = (_kFrames->kcFormat & EGW_KEYCHANNEL_FRMT_EXBPC) * _kFrames->kcCount;
    _track.line.fdPitch = _track.line.cdPitch * _kFrames->cCount;
    
    if(!(_tvOutput = (EGWbyte*)malloc((size_t)_track.line.fdPitch))) { [self release]; return (self = nil); }
    memset((void*)_tvOutput, 0, (size_t)_track.line.fdPitch);
    
    [self setPolationMode:polationMode];
    
    return self;
}

- (id)initBlankWithIdentity:(NSString*)assetIdent channelFormat:(EGWuint16)chnFormat channelCount:(EGWuint16)chnCount componentCount:(EGWuint16)cmpCount frameCount:(EGWuint16)frmCount polationMode:(EGWuint32)polationMode {
    egwKeyFrame frames; memset((void*)&frames, 0, sizeof(egwKeyFrame));
    
    if(!(egwKeyFrmAlloc(&frames, chnFormat, chnCount, cmpCount, frmCount))) { [self release]; return (self = nil); }
    
    _track.line.chnCount = frames.kcCount;
    _track.line.cmpCount = frames.cCount;
    _track.line.cdPitch = (frames.kcFormat & EGW_KEYCHANNEL_FRMT_EXBPC) * frames.kcCount;
    _track.line.fdPitch = _track.line.cdPitch * frames.cCount;
    _track.line.ecdPitch = (EGWuint16)egwIpoExtFrmDatCmpPitch(frames.kcFormat, frames.kcCount, polationMode);
    _track.line.efdPitch = (EGWuint16)egwIpoExtFrmDatFrmPitch(frames.kcFormat, frames.kcCount, frames.cCount, polationMode);
    
    if((polationMode & EGW_POLATION_EXREQEXTDATA) && (!_track.line.efdPitch || !(frames.kfExtraDat = (EGWbyte*)malloc((size_t)frames.fCount * (size_t)_track.line.efdPitch)))) { [self release]; self = nil; goto ErrorCleanup; }
    
    if(!(self = [self initWithIdentity:assetIdent keyFrames:&frames polationMode:polationMode])) { [self release]; self = nil; goto ErrorCleanup; }
    
    return self;
    
ErrorCleanup:
    egwKeyFrmFree(&frames);
    return nil;
}

- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent {
    if(!([asset isKindOfClass:[self class]]) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = (egwInterpolatorBase*)[[asset assetBase] retain])) { [self release]; return (self = nil); }
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _track.pMode = EGW_POLATION_NONE;
    _eAbsT = EGW_TIME_NAN;
    _track.kIndex = -1;
    
    {   egwDataFuncs funcs; memset((void*)&funcs, 0, sizeof(egwDataFuncs));
        funcs.fpAdd = (EGWelementfp)&egwIpoAddTarget;
        funcs.fpRemove = (EGWelementfp)&egwIpoRemoveTarget;
        if(!egwSLListInit(&_tOutputs, &funcs, sizeof(egwMultiTargetOutput), EGW_LIST_FLG_DFLT)) { [self release]; return (self = nil); } // Target objects retain us, but we retain syncs
        if(pthread_mutex_init(&_tLock, NULL)) { [self release]; return (self = nil); }
    }
    
    if(!(_kFrames = [_base keyFrames])) { [self release]; return (self = nil); }
    
    _track.line.chnCount = _kFrames->kcCount;
    _track.line.cmpCount = _kFrames->cCount;
    _track.line.cdPitch = (_kFrames->kcFormat & EGW_KEYCHANNEL_FRMT_EXBPC) * _kFrames->kcCount;
    _track.line.fdPitch = _track.line.cdPitch * _kFrames->cCount;
    
    if(!(_tvOutput = (EGWbyte*)malloc((size_t)_track.line.fdPitch))) { [self release]; return (self = nil); }
    memset((void*)_tvOutput, 0, (size_t)_track.line.fdPitch);
    
    [self setPolationMode:[(egwValueInterpolator*)asset polationMode]];
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwValueInterpolator* copy = nil;
    NSString* copyIdent = nil;
    
    if([_ident hasSuffix:@"_default"])
        copyIdent = [[NSString alloc] initWithFormat:@"%@_%d", [_base identity], [_base nextInstanceIndex]];
    else copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwValueInterpolator allocWithZone:zone] initCopyOf:self
                                                         withIdentity:copyIdent])) {
        NSLog(@"egwValueInterpolator: copyWithZone: Failure initializing new interpolator from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    return copy;
}

- (void)dealloc {
    if(_eTimer) [self setEvaluationTimer:nil];
    
    _kFrames = NULL;
    
    if(_tvOutput) { free((void*)_tvOutput); _tvOutput = NULL; }
    
    egwSLListFree(&_tOutputs);
    pthread_mutex_destroy(&_tLock);
    
    memset((void*)&_track, 0, sizeof(egwKnotTrack));
    
    [_ident release]; _ident = nil;
    [_base release]; _base = nil;
    
    [super dealloc];
}

- (void)addTargetWithObject:(id<NSObject>)target method:(SEL)method {
    pthread_mutex_lock(&_tLock);
    
    if(target && [target respondsToSelector:method]) {
        egwMultiTargetOutput targetItem; //memset((void*)&targetItem, 0, sizeof(egwMultiTargetOutput));
        targetItem.oType = 2; // message
        targetItem.oFlags = 0; // non-retained
        targetItem.write.message.oObj = target; // weak, add does retain
        targetItem.write.message.oMethod = method;
        targetItem.write.message.oRoutine = [(NSObject*)target methodForSelector:method];
        
        egwSLListAddTail(&_tOutputs, (const EGWbyte*)&targetItem);
        
        _eAbsT = EGW_TIME_NAN; // Adding new target invalidates last evalution time
    }
    
    pthread_mutex_unlock(&_tLock);
}

- (void)addTargetWithRetainedObject:(id<NSObject>)target method:(SEL)method {
    pthread_mutex_lock(&_tLock);
    
    if(target && [target respondsToSelector:method]) {
        egwMultiTargetOutput targetItem; //memset((void*)&targetItem, 0, sizeof(egwMultiTargetOutput));
        targetItem.oType = 2; // message
        targetItem.oFlags = 1; // retained
        targetItem.write.message.oObj = target; // weak, add does retain
        targetItem.write.message.oMethod = method;
        targetItem.write.message.oRoutine = [(NSObject*)target methodForSelector:method];
        
        egwSLListAddTail(&_tOutputs, (const EGWbyte*)&targetItem);
        
        _eAbsT = EGW_TIME_NAN; // Adding new target invalidates last evalution time
    }
    
    pthread_mutex_unlock(&_tLock);
}

- (void)removeTargetWithObject:(id<NSObject>)target {
    pthread_mutex_lock(&_tLock);
    
    egwSinglyLinkedListIter iter;
    if(egwSLListEnumerateStart(&_tOutputs, EGW_ITERATE_MODE_DFLT, &iter)) {
        egwMultiTargetOutput* targetItem;
        egwSinglyLinkedListNode* prev = NULL;
        
        while(targetItem = (egwMultiTargetOutput*)egwSLListEnumerateNextPtr(&iter)) {
            if(!(targetItem->oType == 2 && targetItem->write.message.oObj == target))
                prev = egwSLListNodePtr((const EGWbyte*)targetItem);
            else
                egwSLListRemoveAfter(&_tOutputs, prev);
        }
    }
    
    pthread_mutex_unlock(&_tLock);
}

- (void)addTargetWithAddress:(void*)address sync:(egwValidater*)sync {
    pthread_mutex_lock(&_tLock);
    
    if(address) {
        egwMultiTargetOutput targetItem; //memset((void*)&targetItem, 0, sizeof(egwMultiTargetOutput));
        targetItem.oType = 1; // address
        targetItem.oFlags = 0; // non-retained
        targetItem.write.address.vSync = sync; // weak, add does retain
        targetItem.write.address.oAddress = address;
        targetItem.write.address.oSize = _track.line.fdPitch;
        
        egwSLListAddTail(&_tOutputs, (const EGWbyte*)&targetItem);
        
        _eAbsT = EGW_TIME_NAN; // Adding new target invalidates last evalution time
    }
    
    pthread_mutex_unlock(&_tLock);
}

- (void)addTargetWithAddress:(void*)address retainedSync:(egwValidater*)sync {
    pthread_mutex_lock(&_tLock);
    
    if(address) {
        egwMultiTargetOutput targetItem; //memset((void*)&targetItem, 0, sizeof(egwMultiTargetOutput));
        targetItem.oType = 1; // address
        targetItem.oFlags = 1; // retained
        targetItem.write.address.vSync = sync; // weak, add does retain
        targetItem.write.address.oAddress = address;
        targetItem.write.address.oSize = _track.line.fdPitch;
        
        egwSLListAddTail(&_tOutputs, (const EGWbyte*)&targetItem);
        
        _eAbsT = EGW_TIME_NAN; // Adding new target invalidates last evalution time
    }
    
    pthread_mutex_unlock(&_tLock);
}

- (void)removeTargetWithAddress:(void*)address {
    pthread_mutex_lock(&_tLock);
    
    egwSinglyLinkedListIter iter;
    if(egwSLListEnumerateStart(&_tOutputs, EGW_ITERATE_MODE_DFLT, &iter)) {
        egwMultiTargetOutput* targetItem;
        egwSinglyLinkedListNode* prev = NULL;
        
        while(targetItem = (egwMultiTargetOutput*)egwSLListEnumerateNextPtr(&iter)) {
            if(!(targetItem->oType == 1 && targetItem->write.address.oAddress == address))
                prev = egwSLListNodePtr((const EGWbyte*)targetItem);
            else
                egwSLListRemoveAfter(&_tOutputs, prev);
        }
    }
    
    pthread_mutex_unlock(&_tLock);
}

- (void)removeAllTargets {
    pthread_mutex_lock(&_tLock);
    
    egwSLListRemoveAll(&_tOutputs);
    
    pthread_mutex_unlock(&_tLock);
}

- (void)evaluateToTime:(EGWtime)absT {
    EGWtime oldEAbsT = (!isnan(_eAbsT) ? _eAbsT : absT);
    _eAbsT = absT;
    BOOL lookForward = (_eAbsT >= oldEAbsT - EGW_TIME_EPSILON ? YES : NO);
    
    if(_kFrames->tIndicies) {
        EGWtime viAbsT = _eAbsT;
    
    HandleCyclic: // !!!: VI: handle cyclic knot.
        
        if((_track.pMode & EGW_POLATION_EXEXTRA) & EGW_POLATION_EXCYCLIC)
            viAbsT = egwClampm(egwModm(viAbsT - _kFrames->tIndicies[0], _kFrames->tIndicies[_kFrames->fCount-1] - _kFrames->tIndicies[0]) + _kFrames->tIndicies[0], _kFrames->tIndicies[0], _kFrames->tIndicies[_kFrames->fCount-1]);
        
    FindIndex: // !!!: VI: find index.
        
        if(_track.kIndex == -1) { // Binsearch the frame index up
            if(viAbsT >= _kFrames->tIndicies[0] - EGW_TIME_EPSILON) {
                if(viAbsT <= _kFrames->tIndicies[_kFrames->fCount-1] + EGW_TIME_EPSILON) {
                    EGWint16 flIndex = 0;
                    EGWint16 fhIndex = _kFrames->fCount - 1;
                    EGWint16 fmIndex = fhIndex / 2;
                    do {
                        if(_kFrames->tIndicies[fmIndex] < viAbsT - EGW_TIME_EPSILON)
                            flIndex = fmIndex + 1;  // if stored < insert, go to higher half
                        else
                            fhIndex = fmIndex - 1; // if stored >= insert, go to lower half
                        fmIndex = (flIndex + fhIndex) / 2;
                    } while(flIndex <= fhIndex);
                    _track.kIndex = fmIndex + 1;
                } else _track.kIndex = _kFrames->fCount;
            } else _track.kIndex = 0;
            _track.line.okFrame = NULL;
        }
        
    VerifyIndex: // !!!: VI: verify index.
        
        if(lookForward) { // Look forward
            if(_kFrames->fCount > 1 && (
                (_track.kIndex >= 1 && _track.kIndex < _kFrames->fCount && !(viAbsT <= _kFrames->tIndicies[_track.kIndex] + EGW_TIME_EPSILON && viAbsT >= _kFrames->tIndicies[_track.kIndex-1] - EGW_TIME_EPSILON)) || // Past current knot end
                (_track.kIndex == 0 && viAbsT >= _kFrames->tIndicies[0] - EGW_TIME_EPSILON) || // At start, not equal
                (_track.kIndex == _kFrames->fCount && viAbsT <= _kFrames->tIndicies[_kFrames->fCount-1] + EGW_TIME_EPSILON))) { // At end, not equal
                // Forward seek 2 knots else binsearch
                if(_track.kIndex+1 < _kFrames->fCount && ((viAbsT >= _kFrames->tIndicies[_track.kIndex+1-1] - EGW_TIME_EPSILON) && (viAbsT <= _kFrames->tIndicies[_track.kIndex+1] + EGW_TIME_EPSILON))) {
                    _track.kIndex += 1;
                    _track.line.okFrame = NULL;
                } else if (_track.kIndex+2 < _kFrames->fCount && ((viAbsT >= _kFrames->tIndicies[_track.kIndex+2-1] - EGW_TIME_EPSILON) && (viAbsT <= _kFrames->tIndicies[_track.kIndex+2] + EGW_TIME_EPSILON))) {
                    _track.kIndex += 2;
                    _track.line.okFrame = NULL;
                } else {
                    _track.kIndex = -1;
                    goto FindIndex;
                }
            }
        } else { // Look backward
            if(_kFrames->fCount > 1 && (
                (_track.kIndex >= 1 && _track.kIndex < _kFrames->fCount && !(viAbsT >= _kFrames->tIndicies[_track.kIndex-1] - EGW_TIME_EPSILON && viAbsT <= _kFrames->tIndicies[_track.kIndex] + EGW_TIME_EPSILON)) || // Past current knot start
                (_track.kIndex == 0 && viAbsT >= _kFrames->tIndicies[0] - EGW_TIME_EPSILON) || // At start, not equal
                (_track.kIndex == _kFrames->fCount && viAbsT <= _kFrames->tIndicies[_kFrames->fCount-1] + EGW_TIME_EPSILON))) { // At end, not equal
                // Reverse seek 2 knots else binsearch
                if(_track.kIndex-1 >= 1 && ((viAbsT >= _kFrames->tIndicies[_track.kIndex-1-1] - EGW_TIME_EPSILON) && (viAbsT <= _kFrames->tIndicies[_track.kIndex-1] + EGW_TIME_EPSILON))) {
                    _track.kIndex -= 1;
                    _track.line.okFrame = NULL;
                } else if (_track.kIndex-2 >= 1 && ((viAbsT >= _kFrames->tIndicies[_track.kIndex-2-1] - EGW_TIME_EPSILON) && (viAbsT <= _kFrames->tIndicies[_track.kIndex-2] + EGW_TIME_EPSILON))) {
                    _track.kIndex -= 2;
                    _track.line.okFrame = NULL;
                } else {
                    _track.kIndex = -1;
                    goto FindIndex;
                }
            }
        }
        
    FindOffsets: // !!!: VI: find frame offsets.
        
        if(!_track.line.okFrame) { // Acts as a sentinel to force update when NULL
            if(_kFrames->fCount > 1 && _track.kIndex >= 1 && _track.kIndex < _kFrames->fCount) { // Interpolate required
                EGWint indexOffset = (((_track.pMode & EGW_POLATION_EXINTER) & EGW_POLATION_EXKNTPSHBKX1) ? 1 : 0) +
                                     (((_track.pMode & EGW_POLATION_EXINTER) & EGW_POLATION_EXKNTPSHBKX2) ? 2 : 0);
                
                if(((EGWint)_track.kIndex - indexOffset) > 1) {
                    EGWint mptCnt = (EGWint)((_track.pMode & EGW_POLATION_EXINTER) & EGW_POLATION_EXMNPTCNT);
                    
                    if((EGWint)_track.kIndex - (indexOffset + 1) + (mptCnt - 1) < ((EGWint)_kFrames->fCount - 1)) // center bounds
                        indexOffset = (EGWint)_track.kIndex - (indexOffset + 1);
                    else // right bounding
                        indexOffset = (EGWint)_kFrames->fCount - mptCnt;
                    
                    _track.line.okFrame = (EGWbyte*)((EGWuintptr)_kFrames->fKeys + (_track.line.fdPitch * (EGWuintptr)indexOffset));
                    _track.line.okfExtraDat = (_kFrames->kfExtraDat ? (EGWbyte*)((EGWuintptr)_kFrames->kfExtraDat + (_track.line.efdPitch * (EGWuintptr)indexOffset)) : (EGWbyte*)NULL);
                    _track.line.otIndicie = &_kFrames->tIndicies[indexOffset];
                } else { // left bounding
                    _track.line.okFrame = _kFrames->fKeys;
                    _track.line.okfExtraDat = _kFrames->kfExtraDat;
                    _track.line.otIndicie = _kFrames->tIndicies;
                }
            } else { // Extrapolate required
                if(_track.kIndex != 0) { // beyond end
                    EGWint indexOffset = (EGWint)_kFrames->fCount - (EGWint)(((_track.pMode & EGW_POLATION_EXEXTRA) & EGW_POLATION_EXMNPTCNT) >> 16);
                    
                    _track.line.okFrame = (EGWbyte*)((EGWuintptr)_kFrames->fKeys + (_track.line.fdPitch * (EGWuintptr)indexOffset));
                    _track.line.okfExtraDat = (_kFrames->kfExtraDat ? (EGWbyte*)((EGWuintptr)_kFrames->kfExtraDat + (_track.line.efdPitch * (EGWuintptr)indexOffset)) : (EGWbyte*)NULL);
                    _track.line.otIndicie = &_kFrames->tIndicies[indexOffset];
                } else { // beyond start
                    _track.line.okFrame = _kFrames->fKeys;
                    _track.line.okfExtraDat = _kFrames->kfExtraDat;
                    _track.line.otIndicie = _kFrames->tIndicies;
                }
            }
        }
        
    WriteValue: // !!!: VI: write value.
        
        if(_track.line.okFrame) {
            if(_track.kIndex >= 1 && _track.kIndex < _kFrames->fCount) // Interpolate required
                _track.fpIpoFunc(&_track.line, viAbsT, _tvOutput);
            else // Extrapolate required
                _track.fpEpoFunc(&_track.line, viAbsT, _tvOutput);
        }
    }
    
    pthread_mutex_lock(&_tLock);
    
    // Target invocations
    egwSinglyLinkedListIter iter;
    if(egwSLListEnumerateStart(&_tOutputs, EGW_ITERATE_MODE_DFLT, &iter)) {
        egwMultiTargetOutput* targetItem;
        
        while(targetItem = (egwMultiTargetOutput*)egwSLListEnumerateNextPtr(&iter)) {
            switch(targetItem->oType) {
                case 1: { // Address
                    memcpy((void*)targetItem->write.address.oAddress, (const void*)_tvOutput, (size_t)targetItem->write.address.oSize);
                    
                    if(targetItem->write.address.vSync)
                        egwSFPVldtrInvalidate(targetItem->write.address.vSync, @selector(invalidate));
                } break;
                
                case 2: { // Message
                    targetItem->write.message.oRoutine(targetItem->write.message.oObj, targetItem->write.message.oMethod, _tvOutput);
                } break;
            }
        }
    }
    
    pthread_mutex_unlock(&_tLock);
}

- (id<egwPAssetBase>)assetBase {
    return _base;
}

- (EGWuint16)channelFormat {
    return _kFrames->kcFormat;
}

- (EGWuint16)channelCount {
    return _kFrames->kcCount;
}

- (EGWuint16)componentCount {
    return _kFrames->cCount;
}

- (EGWuint16)frameCount {
    return _kFrames->fCount;
}

- (EGWuint)coreObjectTypes {
    return EGW_COREOBJ_TYPE_INTERPOLATOR;
}

- (EGWtime)evaluatedAtTime {
    return _eAbsT;
}

- (EGWtime)evaluationBoundsBegin {
    return _kFrames->tIndicies[0];
}

- (EGWtime)evaluationBoundsEnd {
    return _kFrames->tIndicies[_kFrames->fCount-1];
}

- (id<egwPTimer>)evaluationTimer {
    return _eTimer;
}

- (NSString*)identity {
    return _ident;
}

- (const EGWbyte*)lastOutput {
    return _tvOutput;
}

- (EGWuint32)polationMode {
    return _track.pMode;
}

- (void)setEvaluationTimer:(id<egwPTimer>)timer {
    [timer retain];
    [_eTimer removeOwner:self];
    [_eTimer release];
    _eTimer = timer;
    [_eTimer addOwner:self];
}

- (void)setKeyFrame:(EGWuint16)frameIndex keyData:(EGWbyte*)data {
    memcpy((void*)((EGWuintptr)(_kFrames->fKeys) + (_track.line.fdPitch * (EGWuintptr)frameIndex)), (const void*)data, (size_t)_track.line.fdPitch);
}

- (void)setKeyFrame:(EGWuint16)frameIndex extraKeyData:(EGWbyte*)data {
    memcpy((void*)((EGWuintptr)(_kFrames->kfExtraDat) + (_track.line.efdPitch * (EGWuintptr)frameIndex)), (const void*)data, (size_t)_track.line.efdPitch);
}

- (void)setKeyFrame:(EGWuint16)frameIndex timeIndex:(EGWtime)time {
    _kFrames->tIndicies[frameIndex] = time;
}

- (void)setPolationMode:(EGWuint32)polationMode {
    EGWuint32 ipoMode = (polationMode & EGW_POLATION_EXINTER);
    EGWuint32 epoMode = (polationMode & EGW_POLATION_EXEXTRA);
    
    if(ipoMode &&
       (_kFrames->fCount >= (ipoMode & EGW_POLATION_EXMNPTCNT)) &&
       (!(ipoMode & EGW_POLATION_EXREQEXTDATA) || _kFrames->kfExtraDat) && // Extra data cannot be created on-the-fly (needs to be pre-filled/computed)
       (_track.fpIpoFunc = egwIpoRoutine(_kFrames->kcFormat, ipoMode)))
        _track.pMode = (_track.pMode & ~EGW_POLATION_EXINTER) | ipoMode;
    else {
        _track.pMode = (_track.pMode & ~EGW_POLATION_EXINTER) | EGW_POLATION_IPO_CONST;
        _track.fpIpoFunc = egwIpoRoutine(_kFrames->kcFormat, _track.pMode);
    }
    
    if(epoMode &&
       (_kFrames->fCount >= ((epoMode & EGW_POLATION_EXMNPTCNT) >> 16)) &&
       (!(epoMode & EGW_POLATION_EXREQEXTDATA) || _kFrames->kfExtraDat) && // Extra data cannot be created on-the-fly (needs to be pre-filled/computed)
       (_track.fpEpoFunc = egwEpoRoutine(_kFrames->kcFormat, epoMode)))
        _track.pMode = (_track.pMode & ~EGW_POLATION_EXEXTRA) | epoMode;
    else {
        _track.pMode = (_track.pMode & ~EGW_POLATION_EXEXTRA) | EGW_POLATION_EPO_CONST;
        _track.fpEpoFunc = egwEpoRoutine(_kFrames->kcFormat, _track.pMode);
    }
    
    _track.line.okFrame = NULL; // Changing polation mode potentially changes offseted track line
    _track.line.ecdPitch = (EGWuint16)egwIpoExtFrmDatCmpPitch(_kFrames->kcFormat, _kFrames->kcCount, _track.pMode);
    _track.line.efdPitch = (EGWuint16)egwIpoExtFrmDatFrmPitch(_kFrames->kcFormat, _kFrames->kcCount, _kFrames->cCount, _track.pMode);
}

@end


@implementation egwOrientationInterpolator

- (id)init {
    if([self isMemberOfClass:[egwOrientationInterpolator class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent keyFrames:(egwOrientKeyFrame4f*)frames positionPolationMode:(EGWuint32)posPolationMode rotationPolationMode:(EGWuint32)rotPolationMode scalePolationMode:(EGWuint32)sclPolationMode {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwInterpolatorBase alloc] initOIBWithIdentity:assetIdent orientKeyFrames:frames])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _pTrack.pMode = _rTrack.pMode = _sTrack.pMode = EGW_POLATION_NONE;
    _eAbsT = EGW_TIME_NAN;
    _pTrack.kIndex = _rTrack.kIndex = _sTrack.kIndex = -1;
    
    {   egwDataFuncs funcs; memset((void*)&funcs, 0, sizeof(egwDataFuncs));
        funcs.fpAdd = (EGWelementfp)&egwIpoAddTarget;
        funcs.fpRemove = (EGWelementfp)&egwIpoRemoveTarget;
        if(!egwSLListInit(&_tOutputs, &funcs, sizeof(egwMultiTargetOutput), EGW_LIST_FLG_DFLT)) { [self release]; return (self = nil); } // Target objects retain us, but we retain syncs
        if(pthread_mutex_init(&_tLock, NULL)) { [self release]; return (self = nil); }
    }
    egwMatCopy44f(&egwSIMatIdentity44f, &_tmOutput);
    
    if(!(_kFrames = [_base orientKeyFrames])) { [self release]; return (self = nil); }
    
    _pTrack.line.chnCount = 3;
    _pTrack.line.cmpCount = 1;
    _pTrack.line.cdPitch = _pTrack.line.fdPitch = (EGWuint16)sizeof(egwVector3f);
    _rTrack.line.chnCount = 4;
    _rTrack.line.cmpCount = 1;
    _rTrack.line.cdPitch = _rTrack.line.fdPitch = (EGWuint16)sizeof(egwQuaternion4f);
    _sTrack.line.chnCount = 3;
    _sTrack.line.cmpCount = 1;
    _sTrack.line.cdPitch = _sTrack.line.fdPitch = (EGWuint16)sizeof(egwVector3f);
    
    [self setPositionPolationMode:posPolationMode];
    [self setRotationPolationMode:rotPolationMode];
    [self setScalePolationMode:sclPolationMode];
    
    return self;
}

- (id)initBlankWithIdentity:(NSString*)assetIdent positionFrameCount:(EGWuint16)posFrmCount positionPolationMode:(EGWuint32)posPolationMode rotationFrameCount:(EGWuint16)rotFrmCount rotationPolationMode:(EGWuint32)rotPolationMode scaleFrameCount:(EGWuint16)sclFrmCount scalePolationMode:(EGWuint32)sclPolationMode {
    egwOrientKeyFrame4f frames; memset((void*)&frames, 0, sizeof(egwOrientKeyFrame4f));
    
    if(!(egwOrtKeyFrmAllocf(&frames, posFrmCount, rotFrmCount, sclFrmCount))) { [self release]; return (self = nil); }
    
    if(frames.pfCount) {
        _pTrack.line.chnCount = 3;
        _pTrack.line.cmpCount = 1;
        _pTrack.line.cdPitch = _pTrack.line.fdPitch = (EGWuint16)sizeof(egwVector3f);
        _pTrack.line.ecdPitch = (EGWuint16)egwIpoExtFrmDatCmpPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 3, posPolationMode);
        _pTrack.line.efdPitch = (EGWuint16)egwIpoExtFrmDatFrmPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 3, 1, posPolationMode);
        
        if((posPolationMode & EGW_POLATION_EXREQEXTDATA) && (!_pTrack.line.efdPitch || !(frames.pkfExtraDat = (EGWbyte*)malloc((size_t)frames.pfCount * (size_t)_pTrack.line.efdPitch)))) { [self release]; self = nil; goto ErrorCleanup; }
    }
    
    if(frames.rfCount) {
        _rTrack.line.chnCount = 4;
        _rTrack.line.cmpCount = 1;
        _rTrack.line.cdPitch = _rTrack.line.fdPitch = (EGWuint16)sizeof(egwQuaternion4f);
        _rTrack.line.ecdPitch = (EGWuint16)egwIpoExtFrmDatCmpPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 4, rotPolationMode);
        _rTrack.line.efdPitch = (EGWuint16)egwIpoExtFrmDatFrmPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 4, 1, rotPolationMode);
        
        if((rotPolationMode & EGW_POLATION_EXREQEXTDATA) && (!_rTrack.line.efdPitch || !(frames.rkfExtraDat = (EGWbyte*)malloc((size_t)frames.rfCount * (size_t)_rTrack.line.efdPitch)))) { [self release]; self = nil; goto ErrorCleanup; }
    }
    
    if(frames.sfCount) {
        _sTrack.line.chnCount = 3;
        _sTrack.line.cmpCount = 1;
        _sTrack.line.cdPitch = _sTrack.line.fdPitch = (EGWuint16)sizeof(egwVector3f);
        _sTrack.line.ecdPitch = (EGWuint16)egwIpoExtFrmDatCmpPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 3, sclPolationMode);
        _sTrack.line.efdPitch = (EGWuint16)egwIpoExtFrmDatFrmPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 3, 1, sclPolationMode);
        
        if((sclPolationMode & EGW_POLATION_EXREQEXTDATA) && (!_sTrack.line.efdPitch || !(frames.skfExtraDat = (EGWbyte*)malloc((size_t)frames.sfCount * (size_t)_sTrack.line.efdPitch)))) { [self release]; self = nil; goto ErrorCleanup; }
    }
    
    if(!(self = [self initWithIdentity:assetIdent keyFrames:&frames positionPolationMode:posPolationMode rotationPolationMode:rotPolationMode scalePolationMode:sclPolationMode]))  { [self release]; self = nil; goto ErrorCleanup; }
    
    return self;
    
ErrorCleanup:
    egwOrtKeyFrmFree(&frames);
    return nil;
}

- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent {
    if(!([asset isKindOfClass:[self class]]) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = (egwInterpolatorBase*)[[asset assetBase] retain])) { [self release]; return (self = nil); }
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _pTrack.pMode = _rTrack.pMode = _sTrack.pMode = EGW_POLATION_NONE;
    _eAbsT = EGW_TIME_NAN;
    _pTrack.kIndex = _rTrack.kIndex = _sTrack.kIndex = -1;
    
    {   egwDataFuncs funcs; memset((void*)&funcs, 0, sizeof(egwDataFuncs));
        funcs.fpAdd = (EGWelementfp)&egwIpoAddTarget;
        funcs.fpRemove = (EGWelementfp)&egwIpoRemoveTarget;
        if(!egwSLListInit(&_tOutputs, &funcs, sizeof(egwMultiTargetOutput), EGW_LIST_FLG_DFLT)) { [self release]; return (self = nil); } // Target objects retain us, but we retain syncs
        if(pthread_mutex_init(&_tLock, NULL)) { [self release]; return (self = nil); }
    }
    egwMatCopy44f([(egwOrientationInterpolator*)asset lastOutput], &_tmOutput);
    
    if(!(_kFrames = [_base orientKeyFrames])) { [self release]; return (self = nil); }
    
    _pTrack.line.chnCount = 3;
    _pTrack.line.cmpCount = 1;
    _pTrack.line.cdPitch = _pTrack.line.fdPitch = (EGWuint16)sizeof(egwVector3f);
    _rTrack.line.chnCount = 4;
    _rTrack.line.cmpCount = 1;
    _rTrack.line.cdPitch = _rTrack.line.fdPitch = (EGWuint16)sizeof(egwQuaternion4f);
    _sTrack.line.chnCount = 3;
    _sTrack.line.cmpCount = 1;
    _sTrack.line.cdPitch = _sTrack.line.fdPitch = (EGWuint16)sizeof(egwVector3f);
    
    [self setPositionPolationMode:[(egwOrientationInterpolator*)asset positionPolationMode]];
    [self setRotationPolationMode:[(egwOrientationInterpolator*)asset rotationPolationMode]];
    [self setScalePolationMode:[(egwOrientationInterpolator*)asset scalePolationMode]];
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwOrientationInterpolator* copy = nil;
    NSString* copyIdent = nil;
    
    if([_ident hasSuffix:@"_default"])
        copyIdent = [[NSString alloc] initWithFormat:@"%@_%d", [_base identity], [_base nextInstanceIndex]];
    else copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwOrientationInterpolator allocWithZone:zone] initCopyOf:self
                                                               withIdentity:copyIdent])) {
        NSLog(@"egwOrientationInterpolator: copyWithZone: Failure initializing new orientation interpolator from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    return copy;
}

- (void)dealloc {
    if(_eTimer) [self setEvaluationTimer:nil];
    
    _kFrames = NULL;
    
    egwSLListFree(&_tOutputs);
    pthread_mutex_destroy(&_tLock);
    
    memset((void*)&_pTrack, 0, sizeof(egwKnotTrack));
    memset((void*)&_rTrack, 0, sizeof(egwKnotTrack));
    memset((void*)&_sTrack, 0, sizeof(egwKnotTrack));
    
    [_ident release]; _ident = nil;
    [_base release]; _base = nil;
    
    [super dealloc];
}

- (void)addTargetWithObject:(id<NSObject>)target method:(SEL)method {
    pthread_mutex_lock(&_tLock);
    
    if(target && [target respondsToSelector:method]) {
        egwMultiTargetOutput targetItem; //memset((void*)&targetItem, 0, sizeof(egwMultiTargetOutput));
        targetItem.oType = 2; // message
        targetItem.oFlags = 0; // non-retained
        targetItem.write.message.oObj = target; // weak, add does retain
        targetItem.write.message.oMethod = method;
        targetItem.write.message.oRoutine = [(NSObject*)target methodForSelector:method];
        
        egwSLListAddTail(&_tOutputs, (const EGWbyte*)&targetItem);
        
        _eAbsT = EGW_TIME_NAN; // Adding new target invalidates last evalution time
    }
    
    pthread_mutex_unlock(&_tLock);
}

- (void)addTargetWithRetainedObject:(id<NSObject>)target method:(SEL)method {
    pthread_mutex_lock(&_tLock);
    
    if(target && [target respondsToSelector:method]) {
        egwMultiTargetOutput targetItem; //memset((void*)&targetItem, 0, sizeof(egwMultiTargetOutput));
        targetItem.oType = 2; // message
        targetItem.oFlags = 1; // retained
        targetItem.write.message.oObj = target; // weak, add does retain
        targetItem.write.message.oMethod = method;
        targetItem.write.message.oRoutine = [(NSObject*)target methodForSelector:method];
        
        egwSLListAddTail(&_tOutputs, (const EGWbyte*)&targetItem);
        
        _eAbsT = EGW_TIME_NAN; // Adding new target invalidates last evalution time
    }
    
    pthread_mutex_unlock(&_tLock);
}

- (void)removeTargetWithObject:(id<NSObject>)target {
    pthread_mutex_lock(&_tLock);
    
    egwSinglyLinkedListIter iter;
    if(egwSLListEnumerateStart(&_tOutputs, EGW_ITERATE_MODE_DFLT, &iter)) {
        egwMultiTargetOutput* targetItem;
        egwSinglyLinkedListNode* prev = NULL;
        
        while(targetItem = (egwMultiTargetOutput*)egwSLListEnumerateNextPtr(&iter)) {
            if(!(targetItem->oType == 2 && targetItem->write.message.oObj == target))
                prev = egwSLListNodePtr((const EGWbyte*)targetItem);
            else
                egwSLListRemoveAfter(&_tOutputs, prev);
        }
    }
    
    pthread_mutex_unlock(&_tLock);
}

- (void)addTargetWithAddress:(void*)address sync:(egwValidater*)sync {
    pthread_mutex_lock(&_tLock);
    
    if(address) {
        egwMultiTargetOutput targetItem; //memset((void*)&targetItem, 0, sizeof(egwMultiTargetOutput));
        targetItem.oType = 1; // address
        targetItem.oFlags = 0; // non-retained
        targetItem.write.address.vSync = sync; // weak, add does retain
        targetItem.write.address.oAddress = address;
        targetItem.write.address.oSize = sizeof(egwMatrix44f);
        
        egwSLListAddTail(&_tOutputs, (const EGWbyte*)&targetItem);
        
        _eAbsT = EGW_TIME_NAN; // Adding new target invalidates last evalution time
    }
    
    pthread_mutex_unlock(&_tLock);
}

- (void)addTargetWithAddress:(void*)address retainedSync:(egwValidater*)sync {
    pthread_mutex_lock(&_tLock);
    
    if(address) {
        egwMultiTargetOutput targetItem; //memset((void*)&targetItem, 0, sizeof(egwMultiTargetOutput));
        targetItem.oType = 1; // address
        targetItem.oFlags = 1; // retained
        targetItem.write.address.vSync = sync; // weak, add does retain
        targetItem.write.address.oAddress = address;
        targetItem.write.address.oSize = sizeof(egwMatrix44f);
        
        egwSLListAddTail(&_tOutputs, (const EGWbyte*)&targetItem);
        
        _eAbsT = EGW_TIME_NAN; // Adding new target invalidates last evalution time
    }
    
    pthread_mutex_unlock(&_tLock);
}

- (void)removeTargetWithAddress:(void*)address {
    pthread_mutex_lock(&_tLock);
    
    egwSinglyLinkedListIter iter;
    if(egwSLListEnumerateStart(&_tOutputs, EGW_ITERATE_MODE_DFLT, &iter)) {
        egwMultiTargetOutput* targetItem;
        egwSinglyLinkedListNode* prev = NULL;
        
        while(targetItem = (egwMultiTargetOutput*)egwSLListEnumerateNextPtr(&iter)) {
            if(!(targetItem->oType == 1 && targetItem->write.address.oAddress == address))
                prev = egwSLListNodePtr((const EGWbyte*)targetItem);
            else
                egwSLListRemoveAfter(&_tOutputs, prev);
        }
    }
    
    pthread_mutex_unlock(&_tLock);
}

- (void)removeAllTargets {
    pthread_mutex_lock(&_tLock);
    
    egwSLListRemoveAll(&_tOutputs);
    
    pthread_mutex_unlock(&_tLock);
}

- (void)evaluateToTime:(EGWtime)absT {
    EGWtime oldEAbsT = (!isnan(_eAbsT) ? _eAbsT : absT);
    _eAbsT = absT;
    BOOL lookForward = (_eAbsT >= oldEAbsT - EGW_TIME_EPSILON ? YES : NO);
    
    // NOTE: Although the form is P->R->S, P is a copy-over to translation component. R is most expensive, so done first w/o mat mult for init. -jw
    
    if(_kFrames->rtIndicies) {
        EGWtime rotAbsT = _eAbsT;
        
    HandleRCyclic: // !!!: OI: handle cyclic r-knot.
        
        if((_rTrack.pMode & EGW_POLATION_EXEXTRA) & EGW_POLATION_EXCYCLIC)
            rotAbsT = egwClampm(egwModm(rotAbsT - _kFrames->rtIndicies[0], _kFrames->rtIndicies[_kFrames->rfCount-1] - _kFrames->rtIndicies[0]) + _kFrames->rtIndicies[0], _kFrames->rtIndicies[0], _kFrames->rtIndicies[_kFrames->rfCount-1]);
        
    FindRIndex: // !!!: OI: find r-index.
        
        if(_rTrack.kIndex == -1) { // Binsearch the frame index up
            if(rotAbsT >= _kFrames->rtIndicies[0] - EGW_TIME_EPSILON) {
                if(rotAbsT <= _kFrames->rtIndicies[_kFrames->rfCount-1] + EGW_TIME_EPSILON) {
                    EGWint16 flIndex = 0;
                    EGWint16 fhIndex = _kFrames->rfCount - 1;
                    EGWint16 fmIndex = fhIndex / 2;
                    do {
                        if(_kFrames->rtIndicies[fmIndex] < rotAbsT - EGW_TIME_EPSILON)
                            flIndex = fmIndex + 1;  // if stored < insert, go to higher half
                        else
                            fhIndex = fmIndex - 1; // if stored >= insert, go to lower half
                        fmIndex = (flIndex + fhIndex) / 2;    
                    } while(flIndex <= fhIndex);
                    _rTrack.kIndex = fmIndex + 1;
                } else _rTrack.kIndex = _kFrames->rfCount;
            } else _rTrack.kIndex = 0;
            _rTrack.line.okFrame = NULL;
        }
        
    VerifyRIndex: // !!!: OI: verify r-index.
        
        if(lookForward) { // Look forward
            if(_kFrames->rfCount > 1 && (
                (_rTrack.kIndex >= 1 && _rTrack.kIndex < _kFrames->rfCount && !(rotAbsT <= _kFrames->rtIndicies[_rTrack.kIndex] + EGW_TIME_EPSILON && rotAbsT >= _kFrames->rtIndicies[_rTrack.kIndex-1] - EGW_TIME_EPSILON)) || // Past current knot end
                (_rTrack.kIndex == 0 && rotAbsT >= _kFrames->rtIndicies[0] - EGW_TIME_EPSILON) || // At start, not equal
                (_rTrack.kIndex == _kFrames->rfCount && rotAbsT <= _kFrames->rtIndicies[_kFrames->rfCount-1] + EGW_TIME_EPSILON))) { // At end, not equal
                // Forward seek 2 knots else binsearch
                if(_rTrack.kIndex+1 < _kFrames->rfCount && ((rotAbsT >= _kFrames->rtIndicies[_rTrack.kIndex+1-1] - EGW_TIME_EPSILON) && (rotAbsT <= _kFrames->rtIndicies[_rTrack.kIndex+1] + EGW_TIME_EPSILON))) {
                    _rTrack.kIndex += 1;
                    _rTrack.line.okFrame = NULL;
                } else if (_rTrack.kIndex+2 < _kFrames->rfCount && ((rotAbsT >= _kFrames->rtIndicies[_rTrack.kIndex+2-1] - EGW_TIME_EPSILON) && (rotAbsT <= _kFrames->rtIndicies[_rTrack.kIndex+2] + EGW_TIME_EPSILON))) {
                    _rTrack.kIndex += 2;
                    _rTrack.line.okFrame = NULL;
                } else {
                    _rTrack.kIndex = -1;
                    goto FindRIndex;
                }
            }
        } else { // Look backward
            if(_kFrames->rfCount > 1 && (
                (_rTrack.kIndex >= 1 && _rTrack.kIndex < _kFrames->rfCount && !(rotAbsT >= _kFrames->rtIndicies[_rTrack.kIndex-1] - EGW_TIME_EPSILON && rotAbsT <= _kFrames->rtIndicies[_rTrack.kIndex] + EGW_TIME_EPSILON)) || // Past current knot start
                (_rTrack.kIndex == 0 && rotAbsT >= _kFrames->rtIndicies[0] - EGW_TIME_EPSILON) || // At start, not equal
                (_rTrack.kIndex == _kFrames->rfCount && rotAbsT <= _kFrames->rtIndicies[_kFrames->rfCount-1] + EGW_TIME_EPSILON))) { // At end, not equal
                // Reverse seek 2 knots else binsearch
                if(_rTrack.kIndex-1 >= 1 && ((rotAbsT >= _kFrames->rtIndicies[_rTrack.kIndex-1-1] - EGW_TIME_EPSILON) && (rotAbsT <= _kFrames->rtIndicies[_rTrack.kIndex-1] + EGW_TIME_EPSILON))) {
                    _rTrack.kIndex -= 1;
                    _rTrack.line.okFrame = NULL;
                } else if (_rTrack.kIndex-2 >= 1 && ((rotAbsT >= _kFrames->rtIndicies[_rTrack.kIndex-2-1] - EGW_TIME_EPSILON) && (rotAbsT <= _kFrames->rtIndicies[_rTrack.kIndex-2] + EGW_TIME_EPSILON))) {
                    _rTrack.kIndex -= 2;
                    _rTrack.line.okFrame = NULL;
                } else {
                    _rTrack.kIndex = -1;
                    goto FindRIndex;
                }
            }
        }
        
    FindROffsets: // !!!: OI: find r-frame offsets.
        
        if(!_rTrack.line.okFrame) { // Acts as a sentinel to force update when NULL
            if(_kFrames->rfCount > 1 && _rTrack.kIndex >= 1 && _rTrack.kIndex < _kFrames->rfCount) { // Interpolate required
                EGWint indexOffset = (((_rTrack.pMode & EGW_POLATION_EXINTER) & EGW_POLATION_EXKNTPSHBKX1) ? 1 : 0) +
                                     (((_rTrack.pMode & EGW_POLATION_EXINTER) & EGW_POLATION_EXKNTPSHBKX2) ? 2 : 0);
                
                if(((EGWint)_rTrack.kIndex - indexOffset) > 1) {
                    EGWint mptCnt = (EGWint)((_rTrack.pMode & EGW_POLATION_EXINTER) & EGW_POLATION_EXMNPTCNT);
                    
                    if((EGWint)_rTrack.kIndex - (indexOffset + 1) + (mptCnt - 1) < ((EGWint)_kFrames->rfCount - 1)) // center bounds
                        indexOffset = (EGWint)_rTrack.kIndex - (indexOffset + 1);
                    else // right bounding
                        indexOffset = (EGWint)_kFrames->rfCount - mptCnt;
                    
                    _rTrack.line.okFrame = (EGWbyte*)((EGWuintptr)_kFrames->rfKeys + (_rTrack.line.fdPitch * (EGWuintptr)indexOffset));
                    _rTrack.line.okfExtraDat = (_kFrames->rkfExtraDat ? (EGWbyte*)((EGWuintptr)_kFrames->rkfExtraDat + (_rTrack.line.efdPitch * (EGWuintptr)indexOffset)) : (EGWbyte*)NULL);
                    _rTrack.line.otIndicie = &_kFrames->rtIndicies[indexOffset];
                } else { // left bounding
                    _rTrack.line.okFrame = (EGWbyte*)_kFrames->rfKeys;
                    _rTrack.line.okfExtraDat = (EGWbyte*)_kFrames->rkfExtraDat;
                    _rTrack.line.otIndicie = _kFrames->rtIndicies;
                }
            } else { // Extrapolate required
                if(_rTrack.kIndex != 0) { // beyond end
                    EGWint indexOffset = (EGWint)_kFrames->rfCount - (EGWint)(((_rTrack.pMode & EGW_POLATION_EXEXTRA) & EGW_POLATION_EXMNPTCNT) >> 16);
                    
                    _rTrack.line.okFrame = (EGWbyte*)((EGWuintptr)_kFrames->rfKeys + (_rTrack.line.fdPitch * (EGWuintptr)indexOffset));
                    _rTrack.line.okfExtraDat = (_kFrames->rkfExtraDat ? (EGWbyte*)((EGWuintptr)_kFrames->rkfExtraDat + (_rTrack.line.efdPitch * (EGWuintptr)indexOffset)) : (EGWbyte*)NULL);
                    _rTrack.line.otIndicie = &_kFrames->rtIndicies[indexOffset];
                } else { // beyond start
                    _rTrack.line.okFrame = (EGWbyte*)_kFrames->rfKeys;
                    _rTrack.line.okfExtraDat = (EGWbyte*)_kFrames->rkfExtraDat;
                    _rTrack.line.otIndicie = _kFrames->rtIndicies;
                }
            }
        }
        
    WriteRMatrix: // !!!: OI: write r-matrix.
        
        if(_rTrack.line.okFrame) {
            egwQuaternion4f rot;
            
            if(_rTrack.kIndex >= 1 && _rTrack.kIndex < _kFrames->rfCount) // Interpolate required
                _rTrack.fpIpoFunc(&_rTrack.line, rotAbsT, (EGWbyte*)&rot);
            else // Extrapolate required
                _rTrack.fpEpoFunc(&_rTrack.line, rotAbsT, (EGWbyte*)&rot);
            
            if(_isNormQuatRot) // FIXME: Technically, this setting should be made in the IPO def itself, not as a part of the actuator flags from timer. -jw
                egwQuatFastNormalize4f(&rot, &rot); // FIXME: Would be better to check for mach schnell status somehow here (tls?). -jw
            
            egwMatRotateQuaternion44f(NULL, &rot, &_tmOutput); // Init made here always
        }
    }
    
    if(_kFrames->ptIndicies) {
        EGWtime posAbsT = _eAbsT;
    
    HandlePCyclic: // !!!: OI: handle cyclic p-knot.
        
        if((_pTrack.pMode & EGW_POLATION_EXEXTRA) & EGW_POLATION_EXCYCLIC)
            posAbsT = egwClampm(egwModm(posAbsT - _kFrames->ptIndicies[0], _kFrames->ptIndicies[_kFrames->pfCount-1] - _kFrames->ptIndicies[0]) + _kFrames->ptIndicies[0], _kFrames->ptIndicies[0], _kFrames->ptIndicies[_kFrames->pfCount-1]);
        
    FindPIndex: // !!!: OI: find p-index.
        
        if(_kFrames->ptIndicies == _kFrames->rtIndicies) { // Frame index overlap special case
            if(_pTrack.kIndex != _rTrack.kIndex) {
                _pTrack.kIndex = _rTrack.kIndex;
                _pTrack.line.okFrame = NULL;
            }
            goto FindPOffsets;
        }
        
        if(_pTrack.kIndex == -1) { // Binsearch the frame index up
            if(posAbsT >= _kFrames->ptIndicies[0] - EGW_TIME_EPSILON) {
                if(posAbsT <= _kFrames->ptIndicies[_kFrames->pfCount-1] + EGW_TIME_EPSILON) {
                    EGWint16 flIndex = 0;
                    EGWint16 fhIndex = _kFrames->pfCount - 1;
                    EGWint16 fmIndex = fhIndex / 2;
                    do {
                        if(_kFrames->ptIndicies[fmIndex] < posAbsT - EGW_TIME_EPSILON)
                            flIndex = fmIndex + 1;  // if stored < insert, go to higher half
                        else
                            fhIndex = fmIndex - 1; // if stored >= insert, go to lower half
                        fmIndex = (flIndex + fhIndex) / 2;    
                    } while(flIndex <= fhIndex);
                    _pTrack.kIndex = fmIndex + 1;
                } else _pTrack.kIndex = _kFrames->pfCount;
            } else _pTrack.kIndex = 0;
            _pTrack.line.okFrame = NULL;
        }
        
    VerifyPIndex: // !!!: OI: verify p-index.
        
        if(lookForward) { // Look forward
            if(_kFrames->pfCount > 1 && (
                (_pTrack.kIndex >= 1 && _pTrack.kIndex < _kFrames->pfCount && !(posAbsT <= _kFrames->ptIndicies[_pTrack.kIndex] + EGW_TIME_EPSILON && posAbsT >= _kFrames->ptIndicies[_pTrack.kIndex-1] - EGW_TIME_EPSILON)) || // Past current knot end
                (_pTrack.kIndex == 0 && posAbsT >= _kFrames->ptIndicies[0] - EGW_TIME_EPSILON) || // At start, not equal
                (_pTrack.kIndex == _kFrames->pfCount && posAbsT <= _kFrames->ptIndicies[_kFrames->pfCount-1] + EGW_TIME_EPSILON))) { // At end, not equal
                // Forward seek 2 knots else binsearch
                if(_pTrack.kIndex+1 < _kFrames->pfCount && ((posAbsT >= _kFrames->ptIndicies[_pTrack.kIndex+1-1] - EGW_TIME_EPSILON) && (posAbsT <= _kFrames->ptIndicies[_pTrack.kIndex+1] + EGW_TIME_EPSILON))) {
                    _pTrack.kIndex += 1;
                    _pTrack.line.okFrame = NULL;
                } else if (_pTrack.kIndex+2 < _kFrames->pfCount && ((posAbsT >= _kFrames->ptIndicies[_pTrack.kIndex+2-1] - EGW_TIME_EPSILON) && (posAbsT <= _kFrames->ptIndicies[_pTrack.kIndex+2] + EGW_TIME_EPSILON))) {
                    _pTrack.kIndex += 2;
                    _pTrack.line.okFrame = NULL;
                } else {
                    _pTrack.kIndex = -1;
                    goto FindPIndex;
                }
            }
        } else { // Look backward
            if(_kFrames->pfCount > 1 && (
                (_pTrack.kIndex >= 1 && _pTrack.kIndex < _kFrames->pfCount && !(posAbsT >= _kFrames->ptIndicies[_pTrack.kIndex-1] - EGW_TIME_EPSILON && posAbsT <= _kFrames->ptIndicies[_pTrack.kIndex] + EGW_TIME_EPSILON)) || // Past current knot start
                (_pTrack.kIndex == 0 && posAbsT >= _kFrames->ptIndicies[0] - EGW_TIME_EPSILON) || // At start, not equal
                (_pTrack.kIndex == _kFrames->pfCount && posAbsT <= _kFrames->ptIndicies[_kFrames->pfCount-1] + EGW_TIME_EPSILON))) { // At end, not equal
                // Reverse seek 2 knots else binsearch
                if(_pTrack.kIndex-1 >= 1 && ((posAbsT >= _kFrames->ptIndicies[_pTrack.kIndex-1-1] - EGW_TIME_EPSILON) && (posAbsT <= _kFrames->ptIndicies[_pTrack.kIndex-1] + EGW_TIME_EPSILON))) {
                    _pTrack.kIndex -= 1;
                    _pTrack.line.okFrame = NULL;
                } else if (_pTrack.kIndex-2 >= 1 && ((posAbsT >= _kFrames->ptIndicies[_pTrack.kIndex-2-1] - EGW_TIME_EPSILON) && (posAbsT <= _kFrames->ptIndicies[_pTrack.kIndex-2] + EGW_TIME_EPSILON))) {
                    _pTrack.kIndex -= 2;
                    _pTrack.line.okFrame = NULL;
                } else {
                    _pTrack.kIndex = -1;
                    goto FindPIndex;
                }
            }
        }
        
    FindPOffsets: // !!!: OI: find p-frame offsets.
        
        if(!_pTrack.line.okFrame) { // Acts as a sentinel to force update when NULL
            if(_kFrames->pfCount > 1 && _pTrack.kIndex >= 1 && _pTrack.kIndex < _kFrames->pfCount) { // Interpolate required
                EGWint indexOffset = (((_pTrack.pMode & EGW_POLATION_EXINTER) & EGW_POLATION_EXKNTPSHBKX1) ? 1 : 0) +
                                     (((_pTrack.pMode & EGW_POLATION_EXINTER) & EGW_POLATION_EXKNTPSHBKX2) ? 2 : 0);
                
                if(((EGWint)_pTrack.kIndex - indexOffset) > 1) {
                    EGWint mptCnt = (EGWint)((_pTrack.pMode & EGW_POLATION_EXINTER) & EGW_POLATION_EXMNPTCNT);
                    
                    if((EGWint)_pTrack.kIndex - (indexOffset + 1) + (mptCnt - 1) < ((EGWint)_kFrames->pfCount - 1)) // center bounds
                        indexOffset = (EGWint)_pTrack.kIndex - (indexOffset + 1);
                    else // right bounding
                        indexOffset = (EGWint)_kFrames->pfCount - mptCnt;
                    
                    _pTrack.line.okFrame = (EGWbyte*)((EGWuintptr)_kFrames->pfKeys + (_pTrack.line.fdPitch * (EGWuintptr)indexOffset));
                    _pTrack.line.okfExtraDat = (_kFrames->pkfExtraDat ? (EGWbyte*)((EGWuintptr)_kFrames->pkfExtraDat + (_pTrack.line.efdPitch * (EGWuintptr)indexOffset)) : (EGWbyte*)NULL);
                    _pTrack.line.otIndicie = &_kFrames->ptIndicies[indexOffset];
                } else { // left bounding
                    _pTrack.line.okFrame = (EGWbyte*)_kFrames->pfKeys;
                    _pTrack.line.okfExtraDat = (EGWbyte*)_kFrames->pkfExtraDat;
                    _pTrack.line.otIndicie = _kFrames->ptIndicies;
                }
            } else { // Extrapolate required
                if(_pTrack.kIndex != 0) { // beyond end
                    EGWint indexOffset = (EGWint)_kFrames->pfCount - (EGWint)(((_pTrack.pMode & EGW_POLATION_EXEXTRA) & EGW_POLATION_EXMNPTCNT) >> 16);
                    
                    _pTrack.line.okFrame = (EGWbyte*)((EGWuintptr)_kFrames->pfKeys + (_pTrack.line.fdPitch * (EGWuintptr)indexOffset));
                    _pTrack.line.okfExtraDat = (_kFrames->pkfExtraDat ? (EGWbyte*)((EGWuintptr)_kFrames->pkfExtraDat + (_pTrack.line.efdPitch * (EGWuintptr)indexOffset)) : (EGWbyte*)NULL);
                    _pTrack.line.otIndicie = &_kFrames->ptIndicies[indexOffset];
                } else { // beyond start
                    _pTrack.line.okFrame = (EGWbyte*)_kFrames->pfKeys;
                    _pTrack.line.okfExtraDat = (EGWbyte*)_kFrames->pkfExtraDat;
                    _pTrack.line.otIndicie = _kFrames->ptIndicies;
                }
            }
        }
        
    WritePMatrix: // !!!: OI: write p-matrix.
        
        if(_pTrack.line.okFrame) {
            if(!_rTrack.line.okFrame) // Init made if no rot
                egwMatCopy44f(&egwSIMatIdentity44f, &_tmOutput);
            
            if(_pTrack.kIndex >= 1 && _pTrack.kIndex < _kFrames->pfCount) // Interpolate required
                _pTrack.fpIpoFunc(&_pTrack.line, posAbsT, (EGWbyte*)&(_tmOutput.column[3])); // Direct write to pos c3
            else // Extrapolate required
                _pTrack.fpEpoFunc(&_pTrack.line, posAbsT, (EGWbyte*)&(_tmOutput.column[3]));
        }
    }
    
    if(_kFrames->stIndicies) {
        EGWtime sclAbsT = _eAbsT;
        
    HandleSCyclic: // !!!: OI: handle cyclic s-knot.
        
        if((_sTrack.pMode & EGW_POLATION_EXEXTRA) & EGW_POLATION_EXCYCLIC)
            sclAbsT = egwClampm(egwModm(sclAbsT - _kFrames->stIndicies[0], _kFrames->stIndicies[_kFrames->sfCount-1] - _kFrames->stIndicies[0]) + _kFrames->stIndicies[0], _kFrames->stIndicies[0], _kFrames->stIndicies[_kFrames->sfCount-1]);
        
    FindSIndex: // !!!: OI: find s-index.
        
        if(_kFrames->stIndicies == _kFrames->rtIndicies) { // Frame index overlap special case
            if(_sTrack.kIndex != _rTrack.kIndex) {
                _sTrack.kIndex = _rTrack.kIndex;
                _sTrack.line.okFrame = NULL;
            }
            goto FindSOffsets;
        } else if(_kFrames->stIndicies == _kFrames->ptIndicies) { // Frame index overlap special case
            if(_sTrack.kIndex != _pTrack.kIndex) {
                _sTrack.kIndex = _pTrack.kIndex;
                _sTrack.line.okFrame = NULL;
            }
            goto FindSOffsets;
        }
        
        if(_sTrack.kIndex == -1) { // Binsearch the frame index up
            if(sclAbsT >= _kFrames->stIndicies[0] - EGW_TIME_EPSILON) {
                if(sclAbsT <= _kFrames->stIndicies[_kFrames->sfCount-1] + EGW_TIME_EPSILON) {
                    EGWint16 flIndex = 0;
                    EGWint16 fhIndex = _kFrames->sfCount - 1;
                    EGWint16 fmIndex = fhIndex / 2;
                    do {
                        if(_kFrames->stIndicies[fmIndex] < sclAbsT - EGW_TIME_EPSILON)
                            flIndex = fmIndex + 1;  // if stored < insert, go to higher half
                        else
                            fhIndex = fmIndex - 1; // if stored >= insert, go to lower half
                        fmIndex = (flIndex + fhIndex) / 2;    
                    } while(flIndex <= fhIndex);
                    _sTrack.kIndex = fmIndex + 1;
                } else _sTrack.kIndex = _kFrames->sfCount;
            } else _sTrack.kIndex = 0;
            _sTrack.line.okFrame = NULL;
        }
        
    VerifySIndex: // !!!: OI: verify s-index.
        
        if(lookForward) { // Look forward
            if(_kFrames->sfCount > 1 && (
                (_sTrack.kIndex >= 1 && _sTrack.kIndex < _kFrames->sfCount && !(sclAbsT <= _kFrames->stIndicies[_sTrack.kIndex] + EGW_TIME_EPSILON && sclAbsT >= _kFrames->stIndicies[_sTrack.kIndex-1] - EGW_TIME_EPSILON)) || // Past current knot end
                (_sTrack.kIndex == 0 && sclAbsT >= _kFrames->stIndicies[0] - EGW_TIME_EPSILON) || // At start, not equal
                (_sTrack.kIndex == _kFrames->sfCount && sclAbsT <= _kFrames->stIndicies[_kFrames->sfCount-1] + EGW_TIME_EPSILON))) { // At end, not equal
                // Forward seek 2 knots else binsearch
                if(_sTrack.kIndex+1 < _kFrames->sfCount && ((sclAbsT >= _kFrames->stIndicies[_sTrack.kIndex+1-1] - EGW_TIME_EPSILON) && (sclAbsT <= _kFrames->stIndicies[_sTrack.kIndex+1] + EGW_TIME_EPSILON))) {
                    _sTrack.kIndex += 1;
                    _sTrack.line.okFrame = NULL;
                } else if (_sTrack.kIndex+2 < _kFrames->sfCount && ((sclAbsT >= _kFrames->stIndicies[_sTrack.kIndex+2-1] - EGW_TIME_EPSILON) && (sclAbsT <= _kFrames->stIndicies[_sTrack.kIndex+2] + EGW_TIME_EPSILON))) {
                    _sTrack.kIndex += 2;
                    _sTrack.line.okFrame = NULL;
                } else {
                    _sTrack.kIndex = -1;
                    goto FindSIndex;
                }
            }
        } else { // Look backward
            if(_kFrames->sfCount > 1 && (
                (_sTrack.kIndex >= 1 && _sTrack.kIndex < _kFrames->sfCount && !(sclAbsT >= _kFrames->stIndicies[_sTrack.kIndex-1] - EGW_TIME_EPSILON && sclAbsT <= _kFrames->stIndicies[_sTrack.kIndex] + EGW_TIME_EPSILON)) || // Past current knot start
                (_sTrack.kIndex == 0 && sclAbsT >= _kFrames->stIndicies[0] - EGW_TIME_EPSILON) || // At start, not equal
                (_sTrack.kIndex == _kFrames->sfCount && sclAbsT <= _kFrames->stIndicies[_kFrames->sfCount-1] + EGW_TIME_EPSILON))) { // At end, not equal
                // Reverse seek 2 knots else binsearch
                if(_sTrack.kIndex-1 >= 1 && ((sclAbsT >= _kFrames->stIndicies[_sTrack.kIndex-1-1] - EGW_TIME_EPSILON) && (sclAbsT <= _kFrames->stIndicies[_sTrack.kIndex-1] + EGW_TIME_EPSILON))) {
                    _sTrack.kIndex -= 1;
                    _sTrack.line.okFrame = NULL;
                } else if (_sTrack.kIndex-2 >= 1 && ((sclAbsT >= _kFrames->stIndicies[_sTrack.kIndex-2-1] - EGW_TIME_EPSILON) && (sclAbsT <= _kFrames->stIndicies[_sTrack.kIndex-2] + EGW_TIME_EPSILON))) {
                    _sTrack.kIndex -= 2;
                    _sTrack.line.okFrame = NULL;
                } else {
                    _sTrack.kIndex = -1;
                    goto FindSIndex;
                }
            }
        }
        
    FindSOffsets: // !!!: OI: find s-frame offsets.
        
        if(!_sTrack.line.okFrame) { // Acts as a sentinel to force update when NULL
            if(_kFrames->sfCount > 1 && _sTrack.kIndex >= 1 && _sTrack.kIndex < _kFrames->sfCount) { // Interpolate required
                EGWint indexOffset = (((_sTrack.pMode & EGW_POLATION_EXINTER) & EGW_POLATION_EXKNTPSHBKX1) ? 1 : 0) +
                                     (((_sTrack.pMode & EGW_POLATION_EXINTER) & EGW_POLATION_EXKNTPSHBKX2) ? 2 : 0);
                
                if(((EGWint)_sTrack.kIndex - indexOffset) > 1) {
                    EGWint mptCnt = (EGWint)((_sTrack.pMode & EGW_POLATION_EXINTER) & EGW_POLATION_EXMNPTCNT);
                    
                    if((EGWint)_sTrack.kIndex - (indexOffset + 1) + (mptCnt - 1) < ((EGWint)_kFrames->sfCount - 1)) // center bounds
                        indexOffset = (EGWint)_sTrack.kIndex - (indexOffset + 1);
                    else // right bounding
                        indexOffset = (EGWint)_kFrames->sfCount - mptCnt;
                    
                    _sTrack.line.okFrame = (EGWbyte*)((EGWuintptr)_kFrames->sfKeys + (_sTrack.line.fdPitch * (EGWuintptr)indexOffset));
                    _sTrack.line.okfExtraDat = (_kFrames->skfExtraDat ? (EGWbyte*)((EGWuintptr)_kFrames->skfExtraDat + (_sTrack.line.efdPitch * (EGWuintptr)indexOffset)) : (EGWbyte*)NULL);
                    _sTrack.line.otIndicie = &_kFrames->stIndicies[indexOffset];
                } else { // left bounding
                    _sTrack.line.okFrame = (EGWbyte*)_kFrames->sfKeys;
                    _sTrack.line.okfExtraDat = (EGWbyte*)_kFrames->skfExtraDat;
                    _sTrack.line.otIndicie = _kFrames->stIndicies;
                }
            } else { // Extrapolate required
                if(_sTrack.kIndex != 0) { // beyond end
                    EGWint indexOffset = (EGWint)_kFrames->sfCount - (EGWint)(((_sTrack.pMode & EGW_POLATION_EXEXTRA) & EGW_POLATION_EXMNPTCNT) >> 16);
                    
                    _sTrack.line.okFrame = (EGWbyte*)((EGWuintptr)_kFrames->sfKeys + (_sTrack.line.fdPitch * (EGWuintptr)indexOffset));
                    _sTrack.line.okfExtraDat = (_kFrames->skfExtraDat ? (EGWbyte*)((EGWuintptr)_kFrames->skfExtraDat + (_sTrack.line.efdPitch * (EGWuintptr)indexOffset)) : (EGWbyte*)NULL);
                    _sTrack.line.otIndicie = &_kFrames->stIndicies[indexOffset];
                } else { // beyond start
                    _sTrack.line.okFrame = (EGWbyte*)_kFrames->sfKeys;
                    _sTrack.line.okfExtraDat = (EGWbyte*)_kFrames->skfExtraDat;
                    _sTrack.line.otIndicie = _kFrames->stIndicies;
                }
            }
        }
        
    WriteSMatrix: // !!!: OI: write s-matrix.
        
        if(_sTrack.line.okFrame) {
            egwVector3f scl;
            
            if(_sTrack.kIndex >= 1 && _sTrack.kIndex < _kFrames->sfCount) // Interpolate required
                _sTrack.fpIpoFunc(&_sTrack.line, sclAbsT, (EGWbyte*)&scl);
            else // Extrapolate required
                _sTrack.fpEpoFunc(&_sTrack.line, sclAbsT, (EGWbyte*)&scl);
            
            egwMatScale44f((_rTrack.line.okFrame || _pTrack.line.okFrame ? &_tmOutput : NULL), &scl, &_tmOutput); // Init made if no rot or pos
        }
    }
    
    pthread_mutex_lock(&_tLock);
    
    // Target invocations
    egwSinglyLinkedListIter iter;
    if(egwSLListEnumerateStart(&_tOutputs, EGW_ITERATE_MODE_DFLT, &iter)) {
        egwMultiTargetOutput* targetItem;
        
        while(targetItem = (egwMultiTargetOutput*)egwSLListEnumerateNextPtr(&iter)) {
            switch(targetItem->oType) {
                case 1: { // Address
                    memcpy((void*)targetItem->write.address.oAddress, (const void*)&_tmOutput, (size_t)targetItem->write.address.oSize);
                    
                    if(targetItem->write.address.vSync)
                        egwSFPVldtrInvalidate(targetItem->write.address.vSync, @selector(invalidate));
                } break;
                
                case 2: { // Message
                    targetItem->write.message.oRoutine(targetItem->write.message.oObj, targetItem->write.message.oMethod, &_tmOutput);
                } break;
            }
        }
    }
    
    pthread_mutex_unlock(&_tLock);
}

- (id<egwPAssetBase>)assetBase {
    return _base;
}

- (EGWuint)coreObjectTypes {
    return EGW_COREOBJ_TYPE_INTERPOLATOR;
}

- (EGWtime)evaluatedAtTime {
    return _eAbsT;
}

- (EGWtime)evaluationBoundsBegin {
    if(_kFrames->ptIndicies) { // p??
        if(_kFrames->rtIndicies) { // pr?
            if(_kFrames->stIndicies) { // prs
                return (_kFrames->ptIndicies[0] <= _kFrames->rtIndicies[0] ?
                        (_kFrames->ptIndicies[0] <= _kFrames->stIndicies[0] ? _kFrames->ptIndicies[0] : _kFrames->stIndicies[0]) :
                        (_kFrames->rtIndicies[0] <= _kFrames->stIndicies[0] ? _kFrames->rtIndicies[0] : _kFrames->stIndicies[0]));
            } else { // prx
                return (_kFrames->ptIndicies[0] <= _kFrames->rtIndicies[0] ? _kFrames->ptIndicies[0] : _kFrames->rtIndicies[0]);
            }
        } else if(_kFrames->stIndicies) { // pxs
            return (_kFrames->ptIndicies[0] <= _kFrames->stIndicies[0] ? _kFrames->ptIndicies[0] : _kFrames->stIndicies[0]);
        } else { // pxx
            return _kFrames->ptIndicies[0];
        }
    } else if(_kFrames->rtIndicies) { // xr?
        if(_kFrames->stIndicies) { // xrs
            return (_kFrames->rtIndicies[0] <= _kFrames->stIndicies[0] ? _kFrames->rtIndicies[0] : _kFrames->stIndicies[0]);
        } else { //xrx
            return _kFrames->rtIndicies[0];
        }
    } else if(_kFrames->stIndicies) { // xxs
        return _kFrames->stIndicies[0];
    }
    
    return EGW_TIME_NAN;
}

- (EGWtime)evaluationBoundsEnd {
    if(_kFrames->ptIndicies) { // p??
        if(_kFrames->rtIndicies) { // pr?
            if(_kFrames->stIndicies) { // prs
                return (_kFrames->ptIndicies[_kFrames->pfCount-1] >= _kFrames->rtIndicies[_kFrames->rfCount-1] ?
                        (_kFrames->ptIndicies[_kFrames->pfCount-1] >= _kFrames->stIndicies[_kFrames->sfCount-1] ? _kFrames->ptIndicies[_kFrames->pfCount-1] : _kFrames->stIndicies[_kFrames->sfCount-1]) :
                        (_kFrames->rtIndicies[_kFrames->rfCount-1] >= _kFrames->stIndicies[_kFrames->sfCount-1] ? _kFrames->rtIndicies[_kFrames->rfCount-1] : _kFrames->stIndicies[_kFrames->sfCount-1]));
            } else { // prx
                return (_kFrames->ptIndicies[_kFrames->pfCount-1] >= _kFrames->rtIndicies[_kFrames->rfCount-1] ? _kFrames->ptIndicies[_kFrames->pfCount-1] : _kFrames->rtIndicies[_kFrames->rfCount-1]);
            }
        } else if(_kFrames->stIndicies) { // pxs
            return (_kFrames->ptIndicies[_kFrames->pfCount-1] >= _kFrames->stIndicies[_kFrames->sfCount-1] ? _kFrames->ptIndicies[_kFrames->pfCount-1] : _kFrames->stIndicies[_kFrames->sfCount-1]);
        } else { // pxx
            return _kFrames->ptIndicies[_kFrames->pfCount-1];
        }
    } else if(_kFrames->rtIndicies) { // xr?
        if(_kFrames->stIndicies) { // xrs
            return (_kFrames->rtIndicies[_kFrames->rfCount-1] >= _kFrames->stIndicies[_kFrames->sfCount-1] ? _kFrames->rtIndicies[_kFrames->rfCount-1] : _kFrames->stIndicies[_kFrames->sfCount-1]);
        } else { //xrx
            return _kFrames->rtIndicies[_kFrames->rfCount-1];
        }
    } else if(_kFrames->stIndicies) { // xxs
        return _kFrames->stIndicies[_kFrames->sfCount-1];
    }
    
    return EGW_TIME_NAN;
}

- (id<egwPTimer>)evaluationTimer {
    return _eTimer;
}

- (NSString*)identity {
    return _ident;
}

- (const egwMatrix44f*)lastOutput {
    return &_tmOutput;
}

- (EGWuint16)positionFrameCount {
    return _kFrames->pfCount;
}

- (EGWuint32)positionPolationMode {
    return _pTrack.pMode;
}

- (EGWuint16)rotationFrameCount {
    return _kFrames->rfCount;
}

- (EGWuint32)rotationPolationMode {
    return _rTrack.pMode;
}

- (EGWuint16)scaleFrameCount {
    return _kFrames->sfCount;
}

- (EGWuint32)scalePolationMode {
    return _sTrack.pMode;
}

- (void)setEvaluationTimer:(id<egwPTimer>)timer {
    [timer retain];
    [_eTimer removeOwner:self];
    [_eTimer release];
    _eTimer = timer;
    [_eTimer addOwner:self];
    
    _isNormQuatRot = ([_eTimer actuatorFlags] & EGW_ACTOBJ_ACTRFLG_NRMLZVECS ? YES : NO);
}

- (void)setPositionKeyFrame:(EGWuint16)frameIndex keyData:(egwVector3f*)data {
    if(data) {
        _kFrames->pfKeys[frameIndex].axis.x = data->axis.x;
        _kFrames->pfKeys[frameIndex].axis.y = data->axis.y;
        _kFrames->pfKeys[frameIndex].axis.z = data->axis.z;
    } else {
        _kFrames->pfKeys[frameIndex].axis.x =
            _kFrames->pfKeys[frameIndex].axis.y =
            _kFrames->pfKeys[frameIndex].axis.z = 0.0f;
    }
}

- (void)setPositionKeyFrame:(EGWuint16)frameIndex extraKeyData:(EGWbyte*)data {
    memcpy((void*)((EGWuintptr)(_kFrames->pkfExtraDat) + (_pTrack.line.efdPitch * (EGWuintptr)frameIndex)), (const void*)data, (size_t)_pTrack.line.efdPitch);
}

- (void)setPositionKeyFrame:(EGWuint16)frameIndex timeIndex:(EGWtime)time {
    _kFrames->ptIndicies[frameIndex] = time;
}

- (void)setPositionPolationMode:(EGWuint32)posPolationMode {
    EGWuint32 ipoMode = (posPolationMode & EGW_POLATION_EXINTER);
    EGWuint32 epoMode = (posPolationMode & EGW_POLATION_EXEXTRA);
    
    if(ipoMode &&
       (_kFrames->pfCount >= (ipoMode & EGW_POLATION_EXMNPTCNT)) &&
       (!(ipoMode & EGW_POLATION_EXREQEXTDATA) || _kFrames->pkfExtraDat) && // Extra data cannot be created on-the-fly (needs to be pre-filled/computed)
       (_pTrack.fpIpoFunc = egwIpoRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, ipoMode)))
        _pTrack.pMode = (_pTrack.pMode & ~EGW_POLATION_EXINTER) | ipoMode;
    else {
        _pTrack.pMode = (_pTrack.pMode & ~EGW_POLATION_EXINTER) | EGW_POLATION_IPO_CONST;
        _pTrack.fpIpoFunc = egwIpoRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, _pTrack.pMode);
    }
    
    if(epoMode &&
       (_kFrames->pfCount >= ((epoMode & EGW_POLATION_EXMNPTCNT) >> 16)) &&
       (!(epoMode & EGW_POLATION_EXREQEXTDATA) || _kFrames->pkfExtraDat) && // Extra data cannot be created on-the-fly (needs to be pre-filled/computed)
       (_pTrack.fpEpoFunc = egwEpoRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, epoMode)))
        _pTrack.pMode = (_pTrack.pMode & ~EGW_POLATION_EXEXTRA) | epoMode;
    else {
        _pTrack.pMode = (_pTrack.pMode & ~EGW_POLATION_EXEXTRA) | EGW_POLATION_EPO_CONST;
        _pTrack.fpEpoFunc = egwEpoRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, _pTrack.pMode);
    }
    
    _pTrack.line.okFrame = NULL; // Changing polation mode potentially changes offseted track line
    _pTrack.line.ecdPitch = (EGWuint16)egwIpoExtFrmDatCmpPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 3, _pTrack.pMode);
    _pTrack.line.efdPitch = (EGWuint16)egwIpoExtFrmDatFrmPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 3, 1, _pTrack.pMode);
}

- (void)setRotationKeyFrame:(EGWuint16)frameIndex keyData:(egwQuaternion4f*)data {
    if(data) {
        _kFrames->rfKeys[frameIndex].axis.x = data->axis.x;
        _kFrames->rfKeys[frameIndex].axis.y = data->axis.y;
        _kFrames->rfKeys[frameIndex].axis.z = data->axis.z;
        _kFrames->rfKeys[frameIndex].axis.w = data->axis.w;
    } else {
        _kFrames->rfKeys[frameIndex].axis.x = 1.0f;
        _kFrames->rfKeys[frameIndex].axis.y =
            _kFrames->rfKeys[frameIndex].axis.z =
            _kFrames->rfKeys[frameIndex].axis.w = 0.0f;
    }
}

- (void)setRotationKeyFrame:(EGWuint16)frameIndex extraKeyData:(EGWbyte*)data {
    memcpy((void*)((EGWuintptr)(_kFrames->rkfExtraDat) + (_rTrack.line.efdPitch * (EGWuintptr)frameIndex)), (const void*)data, (size_t)_rTrack.line.efdPitch);
}

- (void)setRotationKeyFrame:(EGWuint16)frameIndex timeIndex:(EGWtime)time {
    _kFrames->rtIndicies[frameIndex] = time;
}

- (void)setRotationPolationMode:(EGWuint32)rotPolationMode {
    EGWuint32 ipoMode = (rotPolationMode & EGW_POLATION_EXINTER);
    EGWuint32 epoMode = (rotPolationMode & EGW_POLATION_EXEXTRA);
    
    if(ipoMode &&
       (_kFrames->rfCount >= (ipoMode & EGW_POLATION_EXMNPTCNT)) &&
       (!(ipoMode & EGW_POLATION_EXREQEXTDATA) || _kFrames->rkfExtraDat) && // Extra data cannot be created on-the-fly (needs to be pre-filled/computed)
       (_rTrack.fpIpoFunc = egwIpoRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, ipoMode)))
        _rTrack.pMode = (_rTrack.pMode & ~EGW_POLATION_EXINTER) | ipoMode;
    else {
        _rTrack.pMode = (_rTrack.pMode & ~EGW_POLATION_EXINTER) | EGW_POLATION_IPO_CONST;
        _rTrack.fpIpoFunc = egwIpoRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, _rTrack.pMode);
    }
    
    if(epoMode &&
       (_kFrames->rfCount >= ((epoMode & EGW_POLATION_EXMNPTCNT) >> 16)) &&
       (!(epoMode & EGW_POLATION_EXREQEXTDATA) || _kFrames->rkfExtraDat) && // Extra data cannot be created on-the-fly (needs to be pre-filled/computed)
       (_rTrack.fpEpoFunc = egwEpoRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, epoMode)))
        _rTrack.pMode = (_rTrack.pMode & ~EGW_POLATION_EXEXTRA) | epoMode;
    else {
        _rTrack.pMode = (_rTrack.pMode & ~EGW_POLATION_EXEXTRA) | EGW_POLATION_EPO_CONST;
        _rTrack.fpEpoFunc = egwEpoRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, _rTrack.pMode);
    }
    
    _rTrack.line.okFrame = NULL; // Changing polation mode potentially changes offseted track line
    _rTrack.line.ecdPitch = (EGWuint16)egwIpoExtFrmDatCmpPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 4, _rTrack.pMode);
    _rTrack.line.efdPitch = (EGWuint16)egwIpoExtFrmDatFrmPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 4, 1, _rTrack.pMode);
}

- (void)setScaleKeyFrame:(EGWuint16)frameIndex keyData:(egwVector3f*)data {
    if(data) {
        _kFrames->sfKeys[frameIndex].axis.x = data->axis.x;
        _kFrames->sfKeys[frameIndex].axis.y = data->axis.y;
        _kFrames->sfKeys[frameIndex].axis.z = data->axis.z;
    } else {
        _kFrames->sfKeys[frameIndex].axis.x =
            _kFrames->sfKeys[frameIndex].axis.y =
            _kFrames->sfKeys[frameIndex].axis.z = 1.0f;
    }
}

- (void)setScaleKeyFrame:(EGWuint16)frameIndex extraKeyData:(EGWbyte*)data {
    memcpy((void*)((EGWuintptr)(_kFrames->skfExtraDat) + (_sTrack.line.efdPitch * (EGWuintptr)frameIndex)), (const void*)data, (size_t)_sTrack.line.efdPitch);
}

- (void)setScaleKeyFrame:(EGWuint16)frameIndex timeIndex:(EGWtime)time {
    _kFrames->stIndicies[frameIndex] = time;
}

- (void)setScalePolationMode:(EGWuint32)sclPolationMode {
    EGWuint32 ipoMode = (sclPolationMode & EGW_POLATION_EXINTER);
    EGWuint32 epoMode = (sclPolationMode & EGW_POLATION_EXEXTRA);
    
    if(ipoMode &&
       (_kFrames->sfCount >= (ipoMode & EGW_POLATION_EXMNPTCNT)) &&
       (!(ipoMode & EGW_POLATION_EXREQEXTDATA) || _kFrames->skfExtraDat) && // Extra data cannot be created on-the-fly (needs to be pre-filled/computed)
       (_sTrack.fpIpoFunc = egwIpoRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, ipoMode)))
        _sTrack.pMode = (_sTrack.pMode & ~EGW_POLATION_EXINTER) | ipoMode;
    else {
        _sTrack.pMode = (_sTrack.pMode & ~EGW_POLATION_EXINTER) | EGW_POLATION_IPO_CONST;
        _sTrack.fpIpoFunc = egwIpoRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, _sTrack.pMode);
    }
    
    if(epoMode &&
       (_kFrames->sfCount >= ((epoMode & EGW_POLATION_EXMNPTCNT) >> 16)) &&
       (!(epoMode & EGW_POLATION_EXREQEXTDATA) || _kFrames->skfExtraDat) && // Extra data cannot be created on-the-fly (needs to be pre-filled/computed)
       (_sTrack.fpEpoFunc = egwEpoRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, epoMode)))
        _sTrack.pMode = (_sTrack.pMode & ~EGW_POLATION_EXEXTRA) | epoMode;
    else {
        _sTrack.pMode = (_sTrack.pMode & ~EGW_POLATION_EXEXTRA) | EGW_POLATION_EPO_CONST;
        _sTrack.fpEpoFunc = egwEpoRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, _sTrack.pMode);
    }
    
    _sTrack.line.okFrame = NULL; // Changing polation mode potentially changes offseted track line
    _sTrack.line.ecdPitch = (EGWuint16)egwIpoExtFrmDatCmpPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 3, _sTrack.pMode);
    _sTrack.line.efdPitch = (EGWuint16)egwIpoExtFrmDatFrmPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 3, 1, _sTrack.pMode);
}

@end


@implementation egwInterpolatorBase

+ (id)allocWithZone:(NSZone*)zone {
    id alloc = [super allocWithZone:zone];
    if(alloc) [egwAssetManager incBaseRef];
    if(EGW_ENGINE_ASSETS_CREATIONMSGS) NSLog(@"egwInterpolatorBase: allocWithZone: Creating new interpolator base asset (%p).", alloc);
    return alloc;
}

- (id)init {
    if([self isMemberOfClass:[egwInterpolatorBase class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initVIBWithIdentity:(NSString*)assetIdent keyFrames:(egwKeyFrame*)frames {
    if(!(frames && frames->fKeys && frames->fCount >= 1 && (self = [super init]))) { [self release]; return (self = nil); }
    else _kfType = 1;
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    if(!(_kFrames.iFrames = (egwKeyFrame*)malloc(sizeof(egwKeyFrame)))) { [self release]; return (self = nil); }
    memcpy((void*)_kFrames.iFrames, (const void*)frames, sizeof(egwKeyFrame));
    memset((void*)frames, 0, sizeof(egwKeyFrame));
    
    return self;
}

- (id)initOIBWithIdentity:(NSString*)assetIdent orientKeyFrames:(egwOrientKeyFrame4f*)frames {
    if(!(frames && (frames->pfKeys || frames->rfKeys || frames->sfKeys) &&
         (frames->pfCount >= 1 || frames->rfCount >= 1 || frames->sfCount >= 1) &&
         (self = [super init]))) { [self release]; return (self = nil); }
    else _kfType = 2;
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    if(!(_kFrames.oFrames = (egwOrientKeyFrame4f*)malloc(sizeof(egwOrientKeyFrame4f)))) { [self release]; return (self = nil); }
    memcpy((void*)_kFrames.oFrames, (const void*)frames, sizeof(egwOrientKeyFrame4f));
    memset((void*)frames, 0, sizeof(egwOrientKeyFrame4f));
    
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
    
    if(_kFrames.iFrames || _kFrames.oFrames) {
        if(_kfType == 1) {
            egwKeyFrmFree(_kFrames.iFrames);
            free((void*)_kFrames.iFrames); _kFrames.iFrames = NULL;
        } else if (_kfType == 2) {
            egwOrtKeyFrmFree(_kFrames.oFrames);
            free((void*)_kFrames.oFrames); _kFrames.oFrames = NULL;
        }
        _kfType = 0;
    }
    
    if(EGW_ENGINE_ASSETS_DESTROYMSGS) NSLog(@"egwInterpolatorBase: dealloc: Destroying interpolator base asset '%@' (%p).", _ident, self);
    [_ident release]; _ident = nil;
    [egwAssetManager decBaseRef];
    [super dealloc];
}

- (NSString*)identity {
    return _ident;
}

- (EGWuint)keysType {
    return _kfType;
}

- (egwKeyFrame*)keyFrames {
    if(_kfType == 1)
        return _kFrames.iFrames;
    return NULL;
}

- (EGWuint)nextInstanceIndex {
    return ++_instCounter;
}

- (egwOrientKeyFrame4f*)orientKeyFrames {
    if(_kfType == 2)
        return _kFrames.oFrames;
    return NULL;
}

@end

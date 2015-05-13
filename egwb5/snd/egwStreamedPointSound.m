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

/// @file egwStreamedPointSound.m
/// @ingroup geWizES_snd_streamedpointsound
/// Streamed Point Sound Asset Implementation.

#import <pthread.h>
#import <vorbis/ogg.h>
#import <vorbis/ivorbiscodec.h>
#import <vorbis/ivorbisfile.h>
#import "egwStreamedPointSound.h"
#import "../sys/egwSysTypes.h"
#import "../sys/egwAssetManager.h"
#import "../sys/egwSndContext.h"
#import "../sys/egwSndContextAL.h"  // NOTE: Below code has a dependence on AL.
#import "../sys/egwSndMixer.h"
#import "../math/egwMath.h"
#import "../math/egwMatrix.h"
#import "../math/egwVector.h"
#import "../phy/egwInterpolators.h"
#import "../snd/egwSound.h"
#import "../misc/egwValidater.h"


@implementation egwStreamedPointSound

- (id)init {
    if([self isMemberOfClass:[egwStreamedPointSound class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent soundAudio:(egwAudio*)audio soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms resonationEffects:(egwAudioEffects2f*)effects resonationRolloff:(EGWsingle)rolloff {
    NSLog(@"egwStreamedPointSound: initWithIdentity:soundAudio:soundRadius:resonationTransforms:resonationEffects:resonationRolloff: This method is unused for this instance (%p).", self);
    [self release]; return (self = nil);
}

- (id)initWithIdentity:(NSString*)assetIdent decoderStream:(void**)stream totalBuffers:(EGWuint16)bfrCount bufferSize:(EGWuint16)bfrSize soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms resonationEffects:(egwAudioEffects2f*)effects resonationRolloff:(EGWsingle)rolloff {
    EGWint bufferIndex;
    
    if(!bfrCount) bfrCount = EGW_STRMSOUND_NUMBUFFERS;
    if(!bfrSize) bfrSize = EGW_STRMSOUND_BUFFERSIZE;
    
    if(!(bfrCount >= EGW_STRMSOUND_NUMBFNTPLY && bfrSize >= 32 && bfrSize % (EGWuint16)sizeof(EGWuint16) == 0 && (self = [super init]))) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwPointSoundBase alloc] initSWithIdentity:assetIdent decoderStream:stream soundRadius:radius resonationTransforms:transforms])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _pFlags = EGW_SNDOBJ_PLAYFLG_DFLT;
    _pFrame = EGW_FRAME_ALWAYSPASS;
    if(!(_pSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_AUDIO])) { [self release]; return (self = nil); }
    
    if(effects) memcpy((void*)&_effects, (const void*)effects, sizeof(egwAudioEffects2f));
    else memcpy((void*)&_effects, (const void*)&egwSIVecOne2f, sizeof(egwAudioEffects2f));
    _rolloff = rolloff;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_AUDIO])) { [self release]; return (self = nil); }
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    egwVecCopy4f(&egwSIVecZero4f, &_wcsVelocity);
    if(!(_wcsPBVol = [(NSObject*)[_base playbackBounding] copy])) { [self release]; return (self = nil); }
    
    _srcID = NSNotFound;
    
    if(pthread_mutex_init(&_cLock, NULL)) { [self release]; return (self = nil); }
    
    _bCount = bfrCount;
    _bSize = bfrSize;
    
    _stream = [_base streamDecoder];
    
    {   OggVorbis_File* oggData = *(OggVorbis_File**)_stream;
        _sCount = (EGWuint32)((((EGWuint64)ov_pcm_total(oggData, -1) * (EGWuint64)ov_info(oggData, -1)->channels *
                                (EGWuint64)sizeof(EGWuint16)) + (EGWuint64)(_bSize - 1)) / (EGWuint64)_bSize);
    }
    
    if(!(_bDatas = (EGWbyte**)malloc((size_t)_bCount * sizeof(EGWbyte*)))) { [self release]; return (self = nil); }
    else {
        memset((void*)_bDatas, 0, (size_t)_bCount * sizeof(EGWbyte*));
        if(egw_alBufferData != &alBufferData) {
            for(bufferIndex = 0; bufferIndex < _bCount; ++bufferIndex) {
                _bDatas[bufferIndex] = [egwAISndCntx requestFreeBufferDataWithSize:_bSize];
                if(!_bDatas[bufferIndex]) { [self release]; return (self = nil); }
            }
        }
    }
    
    if(!(_bufIDs = (EGWuint*)malloc((size_t)_bCount * sizeof(EGWuint)))) { [self release]; return (self = nil); }
    else {
        memset((void*)_bufIDs, 0, (size_t)_bCount * sizeof(EGWuint));
        for(bufferIndex = 0; bufferIndex < _bCount; ++bufferIndex) {
            _bufIDs[bufferIndex] = [egwAISndCntxAL requestFreeBufferID];
            if(!_bufIDs[bufferIndex] || _bufIDs[bufferIndex] == NSNotFound) { [self release]; return (self = nil); }
        }
    }
    
    // Start some initial buffering work, so updatePlayback doesn't have to wait till called
    pthread_mutex_lock(&_cLock);
    for(bufferIndex = 0; bufferIndex < _bCount && bufferIndex < _sCount; ++bufferIndex) {
        if([egwSIAsstMngr addDecodingWorkForSoundAsset:self
                                     withStreamDecoder:(void*)*_stream
                                             segmentID:(EGWuint)bufferIndex
                                              bufferID:_bufIDs[bufferIndex]
                                            bufferData:_bDatas[bufferIndex]
                                            bufferSize:_bSize])
            ++_obsWork;
    }
    pthread_mutex_unlock(&_cLock);
    
    return self;
}

- (id)initBlankWithIdentity:(NSString*)assetIdent audioFormat:(EGWuint32)format soundRate:(EGWuint)rate soundSamples:(EGWuint)count soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms resonationEffects:(egwAudioEffects2f*)effects resonationRolloff:(EGWsingle)rolloff {
    NSLog(@"egwStreamedPointSound: initBlankWithIdentity:audioFormat:soundRate:soundSamples:soundRadius:resonationTransforms:resonationEffects:resonationRolloff: This method is unused for this instance (%p).", self);
    [self release]; return (self = nil);
}

- (id)initPreallocatedWithIdentity:(NSString*)assetIdent bufferID:(EGWuint*)bufferID soundAudio:(egwAudio*)audio soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms resonationEffects:(egwAudioEffects2f*)effects resonationRolloff:(EGWsingle)rolloff {
    NSLog(@"egwStreamedPointSound: initPreallocatedWithIdentity:bufferID:soundAudio:soundRadius:resonationTransforms:resonationEffects:resonationRolloff: This method is unused for this instance (%p).", self);
    [self release]; return (self = nil);
}

- (id)initPreallocatedWithIdentity:(NSString*)assetIdent decoderStream:(void**)stream bufferIDs:(EGWuint**)bufferIDs bufferDatas:(EGWbyte***)bufferDatas totalBuffers:(EGWuint16)bfrCount bufferSize:(EGWuint16)bfrSize soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms resonationEffects:(egwAudioEffects2f*)effects resonationRolloff:(EGWsingle)rolloff {
    EGWint bufferIndex;
    
    if(!(stream && *stream && bufferIDs && *bufferIDs && bufferDatas && *bufferDatas && bfrCount >= EGW_STRMSOUND_NUMBFNTPLY && bfrSize >= 32 && bfrSize % (EGWuint16)sizeof(EGWuint16) == 0 && (self = [super init]))) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwPointSoundBase alloc] initSWithIdentity:assetIdent decoderStream:stream soundRadius:radius resonationTransforms:transforms])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _pFlags = EGW_SNDOBJ_PLAYFLG_DFLT;
    _pFrame = EGW_FRAME_ALWAYSPASS;
    if(!(_pSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_AUDIO])) { [self release]; return (self = nil); }
    
    if(effects) memcpy((void*)&_effects, (const void*)effects, sizeof(egwAudioEffects2f));
    else memcpy((void*)&_effects, (const void*)&egwSIVecOne2f, sizeof(egwAudioEffects2f));
    _rolloff = rolloff;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_AUDIO])) { [self release]; return (self = nil); }
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    egwVecCopy4f(&egwSIVecZero4f, &_wcsVelocity);
    if(!(_wcsPBVol = [(NSObject*)[_base playbackBounding] copy])) { [self release]; return (self = nil); }
    
    _srcID = NSNotFound;
    
    if(pthread_mutex_init(&_cLock, NULL)) { [self release]; return (self = nil); }
    
    _bCount = bfrCount;
    _bSize = bfrSize;
    
    _stream = [_base streamDecoder];
    
    {   OggVorbis_File* oggData = *(OggVorbis_File**)_stream;
        _sCount = (EGWuint32)((((EGWuint64)ov_pcm_total(oggData, -1) * (EGWuint64)ov_info(oggData, -1)->channels *
                                (EGWuint64)sizeof(EGWuint16)) + (EGWuint64)(_bSize - 1)) / (EGWuint64)_bSize);
    }
    
    _bufIDs = *bufferIDs; *bufferIDs = NULL;
    _bDatas = *bufferDatas; *bufferDatas = NULL;
    
    // Start some initial buffering work, so updatePlayback doesn't have to wait till called
    pthread_mutex_lock(&_cLock);
    for(bufferIndex = 0; bufferIndex < _bCount && bufferIndex < _sCount; ++bufferIndex) {
        if([egwSIAsstMngr addDecodingWorkForSoundAsset:self
                                     withStreamDecoder:(void*)*_stream
                                             segmentID:(EGWuint)bufferIndex
                                              bufferID:_bufIDs[bufferIndex]
                                            bufferData:_bDatas[bufferIndex]
                                            bufferSize:_bSize])
            ++_obsWork;
    }
    pthread_mutex_unlock(&_cLock);
    
    return self;
}

- (id)initLoadedFromResourceFile:(NSString*)resourceFile withIdentity:(NSString*)assetIdent soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms resonationEffects:(egwAudioEffects2f*)effects resonationRolloff:(EGWsingle)rolloff {
    return (self = [self initLoadedFromResourceFile:resourceFile withIdentity:assetIdent totalBuffers:0 bufferSize:0 soundRadius:radius resonationTransforms:transforms resonationEffects:effects resonationRolloff:rolloff]);
}

- (id)initLoadedFromResourceFile:(NSString*)resourceFile withIdentity:(NSString*)assetIdent totalBuffers:(EGWuint16)bfrCount bufferSize:(EGWuint16)bfrSize soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms resonationEffects:(egwAudioEffects2f*)effects resonationRolloff:(EGWsingle)rolloff {
    void* stream = NULL;
    
    if(!([egwSIAsstMngr loadAudioStream:&stream fromFile:resourceFile withTransforms:transforms])) {
        if(stream) ov_clear((OggVorbis_File*)stream); stream = NULL;
        [self release]; return (self = nil);
    }
    
    if(!(self = [self initWithIdentity:assetIdent decoderStream:&stream totalBuffers:bfrCount bufferSize:bfrSize soundRadius:radius resonationTransforms:transforms resonationEffects:effects resonationRolloff:rolloff])) {
        if(stream) ov_clear((OggVorbis_File*)stream); stream = NULL;
        return nil;
    }
    
    return self;
}

- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent {
    return (self = [self initCopyOf:asset withIdentity:assetIdent totalBuffers:0 bufferSize:0]);
}

- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent totalBuffers:(EGWuint16)bfrCount bufferSize:(EGWuint16)bfrSize {
    EGWint bufferIndex;
    
    if(!([asset isKindOfClass:[self class]]) || !(self = [super initCopyOf:asset withIdentity:assetIdent])) { [self release]; return (self = nil); }
    
    if(!bfrCount) bfrCount = [(egwStreamedPointSound*)asset bufferCount];
    if(!bfrSize) bfrSize = [(egwStreamedPointSound*)asset bufferSize];
    
    if(!(bfrCount >= EGW_STRMSOUND_NUMBFNTPLY && bfrSize >= 32 && bfrSize % (EGWuint16)sizeof(EGWuint16) == 0 && (self = [super initCopyOf:asset withIdentity:assetIdent]))) { [self release]; return (self = nil); }
    
    _bCount = bfrCount;
    _bSize = bfrSize;
    
    _stream = [_base streamDecoder];
    
    {   OggVorbis_File* oggData = *(OggVorbis_File**)_stream;
        _sCount = (EGWuint32)((((EGWuint64)ov_pcm_total(oggData, -1) * (EGWuint64)ov_info(oggData, -1)->channels *
                                (EGWuint64)sizeof(EGWuint16)) + (EGWuint64)(_bSize - 1)) / (EGWuint64)_bSize);
    }
    
    if(!(_bDatas = (EGWbyte**)malloc((size_t)_bCount * sizeof(EGWbyte*)))) { [self release]; return (self = nil); }
    else {
        memset((void*)_bufIDs, 0, (size_t)_bCount * sizeof(EGWbyte*));
        if(egw_alBufferData != &alBufferData) {
            for(bufferIndex = 0; bufferIndex < _bCount; ++bufferIndex) {
                _bDatas[bufferIndex] = [egwAISndCntx requestFreeBufferDataWithSize:_bSize];
                if(!_bDatas[bufferIndex]) { [self release]; return (self = nil); }
            }
        }
    }
    
    if(!(_bufIDs = (EGWuint*)malloc((size_t)_bCount * sizeof(EGWuint)))) { [self release]; return (self = nil); }
    else {
        memset((void*)_bufIDs, 0, (size_t)_bCount * sizeof(EGWuint));
        for(bufferIndex = 0; bufferIndex < _bCount; ++bufferIndex) {
            _bufIDs[bufferIndex] = [egwAISndCntxAL requestFreeBufferID];
            if(!_bufIDs[bufferIndex] || _bufIDs[bufferIndex] == NSNotFound) { [self release]; return (self = nil); }
        }
    }
    
    // Start some initial buffering work, so updatePlayback doesn't have to wait till called
    pthread_mutex_lock(&_cLock);
    for(bufferIndex = 0; bufferIndex < _bCount && bufferIndex < _sCount; ++bufferIndex) {
        if([egwSIAsstMngr addDecodingWorkForSoundAsset:self
                                     withStreamDecoder:(void*)*_stream
                                             segmentID:(EGWuint)bufferIndex
                                              bufferID:_bufIDs[bufferIndex]
                                            bufferData:_bDatas[bufferIndex]
                                            bufferSize:_bSize])
            ++_obsWork;
    }
    pthread_mutex_unlock(&_cLock);
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwStreamedPointSound* copy = nil;
    NSString* copyIdent = nil;
    
    if([_ident hasSuffix:@"_default"])
        copyIdent = [[NSString alloc] initWithFormat:@"%@_%d", [_base identity], [_base nextInstanceIndex]];
    else copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwStreamedPointSound allocWithZone:zone] initCopyOf:self
                                                          withIdentity:copyIdent])) {
        NSLog(@"egwStreamedPointSound: copyWithZone: Failure initializing new sound from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    return copy;
}

- (void)dealloc {
    if(_srcID && _srcID != NSNotFound) {
        NSLog(@"egwPointSound: dealloc: Warning: Sound asset '%@' (%p) still has its source retained.", _ident, self);
        alSourceStop(_srcID);
        alSourcei((ALuint)_srcID, AL_BUFFER, (ALint)NULL);
        _srcID = [egwAISndCntxAL returnUsedSourceID:_srcID];
    }
    
    if(_obsWork != 0) {
        pthread_mutex_lock(&_cLock);
        _obsWork -= [egwSIAsstMngr removeAllDecodingWorkForSoundAsset:self];
        
        if(_obsWork != 0) { // The reason we wait here is because outboundWork should always refer to future queues, never past, otherwise we get negatives
            NSDate* waitTill = [[NSDate alloc] initWithTimeIntervalSinceNow:(NSTimeInterval)EGW_ENGINE_MANAGERS_TIMETOWAIT];
            
            while(_obsWork != 0) {
                if([waitTill timeIntervalSinceNow] < (NSTimeInterval)0.0) {
                    NSLog(@"egwStreamedPointSound: dealloc: Failure waiting for %d outbound work item(s) to report back.", _obsWork);
                    break;
                }
                
                pthread_mutex_unlock(&_cLock);  // Have to temporarily unlock to allow decoder thread to edit the value (otherwise deadlock)
                [NSThread sleepForTimeInterval:EGW_ENGINE_MANAGERS_TIMETOSLEEP];
                pthread_mutex_lock(&_cLock);
            }
            
            [waitTill release];
        }
        
        pthread_mutex_unlock(&_cLock);
        _obsWork = 0;
    }
    
    _sCurr = _sQueued = _sUnqueued = 0;
    
    pthread_mutex_destroy(&_cLock);
    
    if(_bufIDs) {
        for(EGWint bufferIndex = 0; bufferIndex < _bCount; ++bufferIndex)
            if(_bufIDs[bufferIndex] && _bufIDs[bufferIndex] != NSNotFound)
                _bufIDs[bufferIndex] = [egwAISndCntxAL returnUsedBufferID:_bufIDs[bufferIndex]];
        free((void*)_bufIDs); _bufIDs = NULL;
    }
    
    if(_bDatas) {
        for(EGWint bufferIndex = 0; bufferIndex < _bCount; ++bufferIndex)
            if(_bDatas[bufferIndex])
                [egwAISndCntxAL returnUsedBufferData:&_bDatas[bufferIndex]];
        free((void*)_bDatas); _bDatas = NULL;
    }
    
    _stream = NULL;
    
    [super dealloc];
}

- (void)playWithFlags:(EGWuint32)flags {
    if(flags & EGW_SNDOBJ_RPLYFLY_DOPLYBCKPASS) {
        _isPaused = NO; // always unpauses
        
        // Auto-acquire source
        if(!(_srcID && _srcID != NSNotFound)) {
            _srcID = [egwAISndCntxAL requestFreeSourceID];
            
            if(_srcID && _srcID != NSNotFound) {
                // This resets the source<->buffer connection
                alSourceStop((ALuint)_srcID);
                alSourcei((ALuint)_srcID, AL_BUFFER, (ALint)NULL);
                
                // We will control looping manually ourselves
                alSourcei((ALuint)_srcID, AL_LOOPING, (ALint)AL_FALSE);
                alSourcei((ALuint)_srcID, AL_SAMPLE_OFFSET, (ALfloat)_smpOffset);
                alSourcei((ALuint)_srcID, AL_SOURCE_RELATIVE, (ALint)0);
                
                alSourcefv((ALuint)_srcID, AL_POSITION, (ALfloat*)[_wcsPBVol boundingOrigin]);
                alSource3f((ALuint)_srcID, AL_DIRECTION, 0.0f, 0.0f, 0.0f);
                alSourcefv((ALuint)_srcID, AL_VELOCITY, (ALfloat*)&_wcsVelocity);
                
                ALfloat gainMod = (ALfloat)((ALfloat)((flags & EGW_SNDOBJ_RPLYFLG_GAINMODMASK) >> EGW_SNDOBJ_RPLYFLG_GAINMODSHFT) / 100.0f);
                ALfloat pitchMod = (ALfloat)((ALfloat)((flags & EGW_SNDOBJ_RPLYFLG_PITCHMODMASK) >> EGW_SNDOBJ_RPLYFLG_PITCHMODSHFT) / 100.0f);
                alSourcef((ALuint)_srcID, AL_GAIN, (ALfloat)_effects.gain * gainMod);
                alSourcef((ALuint)_srcID, AL_PITCH, (ALfloat)_effects.pitch * pitchMod);
                alSourcef((ALuint)_srcID, AL_ROLLOFF_FACTOR, (ALfloat)_rolloff);
                
                _stopHandled = YES; // initial stopped status is handled
                egwSFPVldtrValidate(_rSync, @selector(validate));
                flags &= ~EGW_SNDOBJ_RPLYFLG_APISYNCINVLD;
            } else
                NSLog(@"egwStreamedPointSound: playWithFlags: Error: Sound %@ told to play but a sourceID could not be acquired.", _ident);
        }
        
        // Handle streamed playback
        if(_srcID && _srcID != NSNotFound) {
            ALenum state;
            EGWint segmentIndex, bufferIndex;
            
            pthread_mutex_lock(&_cLock);
            
            if(_isRestarting) {
                // NOTE: This code fakes the buffer underrun handler to handle restarting the sound from beginning. -jw
                _stopHandled = YES;
                alSourceStop(_srcID); // so more AL calls see it's stopped
                
                // We may have work being done that is behind us, get rid of it
                if(_obsWork != 0) {
                    _obsWork -= [egwSIAsstMngr removeAllDecodingWorkForSoundAsset:self];
                    
                    if(_obsWork != 0) { // The reason we wait here is because outboundWork should always refer to future queues, never past, otherwise we get negatives
                        NSDate* waitTill = [[NSDate alloc] initWithTimeIntervalSinceNow:(NSTimeInterval)EGW_ENGINE_MANAGERS_TIMETOWAIT];
                        
                        while(_obsWork != 0) {
                            if([waitTill timeIntervalSinceNow] < (NSTimeInterval)0.0) {
                                NSLog(@"egwStreamedPointSound: playWithFlags: Failure waiting for %d outbound work item(s) to report back.", _obsWork);
                                break;
                            }
                            
                            pthread_mutex_unlock(&_cLock);  // Have to temporarily unlock to allow decoder thread to edit the value (otherwise deadlock)
                            [NSThread sleepForTimeInterval:EGW_ENGINE_MANAGERS_TIMETOSLEEP];
                            pthread_mutex_lock(&_cLock);
                        }
                        
                        [waitTill release];
                    }
                    
                    _obsWork = 0;
                }
                
                // This resets the source<->buffer connection
                // NOTE: This must be done _after_ cleaning up outbound work, otherwise we get failures on buffer data. -jw
                alSourcei((ALuint)_srcID, AL_BUFFER, (ALint)NULL);
                
                // Reset segment queue trackers to beginning
                _sUnqueued = _sQueued = _sCurr = _smpOffset = 0;
                
                // Enqueue some new work
                for(segmentIndex = 0; _sCurr + segmentIndex < _sCount &&
                    segmentIndex < _bCount; ++segmentIndex) {
                    bufferIndex = (_sCurr + segmentIndex) % _bCount;
                    if([egwSIAsstMngr addDecodingWorkForSoundAsset:self
                                                 withStreamDecoder:(void*)*_stream
                                                         segmentID:(EGWuint)((_sCurr + segmentIndex) % _sCount)
                                                          bufferID:_bufIDs[bufferIndex]
                                                        bufferData:_bDatas[bufferIndex]
                                                        bufferSize:_bSize])
                        ++_obsWork;
                }
                
                _isRestarting = NO;
            }
            
            // Determine how we've moved since our last encounter
            EGWuint wasOnSegment = _sCurr;
            alGetSourcei((ALuint)_srcID, AL_SOURCE_TYPE, &state);
            if(state == AL_STREAMING)
                alGetSourcei((ALuint)_srcID, AL_BUFFERS_PROCESSED, (ALint*)&_sCurr);
            else { // NOTE: OpenAL fix, sometimes when state isn't streaming it likes to say 1 buffer has been processed. -jw
                _sCurr = 0;
                
                if(state != AL_UNDETERMINED) // Shouldn't be true, but done for safety
                    // This resets the source<->buffer connection
                    alSourcei((ALuint)_srcID, AL_BUFFER, (ALint)NULL);
            }
            alGetSourcei((ALuint)_srcID, AL_SOURCE_STATE, &state);
            
            // Keep track of samples offset
            //if(state == AL_PLAYING)
            //alGetSourcei((ALuint)_srcID, AL_SAMPLE_OFFSET, (ALint*)&_smpOffset);
            
            // Handle stop state and underruns
            if(state == AL_STOPPED && !_stopHandled) {
                _stopHandled = YES;
                
                if(!(_pFlags & EGW_SNDOBJ_PLAYFLG_LOOPING) && _sQueued >= (_sCount - wasOnSegment)) // Hit end
                    _sCurr += _sUnqueued;  // Offset from relative to absolute (should be _sCount in this case)
                else {
                    // In the case of an underrun, the only way to find out where we were is
                    // to query AL for the queue size that it has and add the unqueued offset
                    alGetSourcei((ALuint)_srcID, AL_SOURCE_TYPE, &state);
                    if(state == AL_STREAMING)
                        alGetSourcei((ALuint)_srcID, AL_BUFFERS_QUEUED, (ALint*)&_sCurr);
                    else
                        _sCurr = 0;
                    alGetSourcei((ALuint)_srcID, AL_SOURCE_STATE, &state);
                    _sCurr += _sUnqueued; // Offset from relative to absolute
                    
                    NSLog(@"egwStreamedPointSound: playWithFlags: Buffer underrun detected for audio asset %@ segment %d.", _ident, _sCurr);
                    
                    // We may have work being done that is behind us, get rid of it
                    if(_obsWork != 0) {
                        _obsWork -= [egwSIAsstMngr removeAllDecodingWorkForSoundAsset:self];
                        
                        if(_obsWork != 0) { // The reason we wait here is because outboundWork should always refer to future queues, never past, otherwise we get negatives
                            NSDate* waitTill = [[NSDate alloc] initWithTimeIntervalSinceNow:(NSTimeInterval)EGW_ENGINE_MANAGERS_TIMETOWAIT];
                            
                            while(_obsWork != 0) {
                                if([waitTill timeIntervalSinceNow] < (NSTimeInterval)0.0) {
                                    NSLog(@"egwStreamedPointSound: playWithFlags: Failure waiting for %d outbound work item(s) to report back.", _obsWork);
                                    break;
                                }
                                
                                pthread_mutex_unlock(&_cLock);  // Have to temporarily unlock to allow decoder thread to edit the value (otherwise deadlock)
                                [NSThread sleepForTimeInterval:EGW_ENGINE_MANAGERS_TIMETOSLEEP];
                                pthread_mutex_lock(&_cLock);
                            }
                            
                            [waitTill release];
                        }
                        
                        _obsWork = 0;
                    }
                    
                    // This resets the source<->buffer connection
                    // NOTE: This must be done after cleaning up outbound work, otherwise we get failures on buffer data. -jw
                    alSourcei((ALuint)_srcID, AL_BUFFER, (ALint)NULL);
                    
                    // Reset segment queue trackers
                    wasOnSegment = _sUnqueued = _sCurr;
                    _sQueued = 0;
                    
                    // Enqueue some new work
                    for(segmentIndex = 0; _sCurr + segmentIndex < _sCount &&
                        segmentIndex < _bCount; ++segmentIndex) {
                        bufferIndex = (_sCurr + segmentIndex) % _bCount;
                        if([egwSIAsstMngr addDecodingWorkForSoundAsset:self
                                                     withStreamDecoder:(void*)*_stream
                                                             segmentID:(EGWuint)((_sCurr + segmentIndex) % _sCount)
                                                              bufferID:_bufIDs[bufferIndex]
                                                            bufferData:_bDatas[bufferIndex]
                                                            bufferSize:_bSize])
                            ++_obsWork;
                    }
                    
                    // We're now fresh to do some relevant work
                    NSLog(@"egwStreamedPointSound: playWithFlags: Buffer underrun corrected for audio asset %@ segment %d.", _ident, _sCurr);
                }
            } else
                _sCurr += _sUnqueued; // Offset from relative to absolute
            
            // Streaming interaction
            
            // Determine the number of segments that we've buffered up to (not-inclusive)
            EGWuint segmentBufferedUpTo = ((_pFlags & EGW_SNDOBJ_PLAYFLG_LOOPING) ? wasOnSegment + (_bCount - _obsWork) : egwMin2i(wasOnSegment + (_bCount - _obsWork), _sCount));
            
            // While we're streaming along...
            
            // Unenqueue used buffers
            if(_sCurr > wasOnSegment) {
                // Unenqueue old buffers
                EGWint segmentsToUnqueue = _sCurr - wasOnSegment;
                
                if((wasOnSegment % _bCount) + segmentsToUnqueue <= _bCount)
                    alSourceUnqueueBuffers((ALuint)_srcID, (ALsizei)segmentsToUnqueue, (ALuint*)&(_bufIDs[wasOnSegment % _bCount]));
                else {
                    alSourceUnqueueBuffers((ALuint)_srcID, (ALsizei)(_bCount - (wasOnSegment % _bCount)), (ALuint*)&(_bufIDs[wasOnSegment % _bCount]));
                    alSourceUnqueueBuffers((ALuint)_srcID, (ALsizei)((wasOnSegment + segmentsToUnqueue) % _bCount), (ALuint*)&(_bufIDs[0]));
                }
                
                _sUnqueued += segmentsToUnqueue;
                _sQueued -= segmentsToUnqueue;
                
                // Keep the segments queued positive
                if(_sQueued < 0) {
                    _sQueued = 0;
                    NSLog(@"egwStreamedPointSound: playWithFlags: Queued segments count fell under zero for audio asset %@ segment %d. Potential streaming bug.", _ident, _sCurr);
                }
            }
            
            // Enqueue filled buffers
            if(_sCurr + _sQueued < segmentBufferedUpTo) {
                EGWint segmentsToQueue = segmentBufferedUpTo - (_sCurr + _sQueued);
                
                if(((_sCurr + _sQueued) % _bCount) + segmentsToQueue <= _bCount)
                    alSourceQueueBuffers((ALuint)_srcID, (ALsizei)segmentsToQueue, (ALuint*)&(_bufIDs[(_sCurr + _sQueued) % _bCount]));
                else {
                    alSourceQueueBuffers((ALuint)_srcID, (ALsizei)(_bCount - ((_sCurr + _sQueued) % _bCount)), (ALuint*)&(_bufIDs[(_sCurr + _sQueued) % _bCount]));
                    alSourceQueueBuffers((ALuint)_srcID, (ALsizei)(((_sCurr + _sQueued) + segmentsToQueue) % _bCount), (ALuint*)&(_bufIDs[0]));
                }
                
                // Offset the segment queue trackers
                _sQueued += segmentsToQueue;
            }
            
            // Add work items for decoder for however many segments needed
            while((segmentBufferedUpTo - _sCurr) + _obsWork < _bCount &&
                  ((_pFlags & EGW_SNDOBJ_PLAYFLG_LOOPING) || (segmentBufferedUpTo + _obsWork < _sCount))) {
                bufferIndex = (segmentBufferedUpTo + _obsWork) % _bCount;
                
                if([egwSIAsstMngr addDecodingWorkForSoundAsset:self
                                             withStreamDecoder:(void*)*_stream
                                                     segmentID:(EGWuint)((segmentBufferedUpTo + _obsWork) % _sCount)
                                                      bufferID:_bufIDs[bufferIndex]
                                                    bufferData:_bDatas[bufferIndex]
                                                    bufferSize:_bSize])
                    ++_obsWork;
            }
            
            // Keep track of samples offset
            if(_bufIDs[0]) {
                // NOTE: We're fudging this value because it's harder to keep track of the exact sample offset with a streaming instance -jw
                //alGetSourcei((ALuint)_srcID, AL_SAMPLE_OFFSET, (ALint*)&_smpOffset);
                ALint bits, chns;
                alGetBufferiv(_bufIDs[0], AL_BITS, (ALint*)&bits);
                alGetBufferiv(_bufIDs[0], AL_CHANNELS, (ALint*)&chns);
                if(bits && chns) // Sometimes this returns 0, when data isn't yet buffered in
                    _smpOffset = (_sUnqueued * _bSize) / (EGWuint)((bits >> 3) * chns);
            }
            
            // Handle stopped state
            if(state == AL_STOPPED) {
                if(!(_pFlags & EGW_SNDOBJ_PLAYFLG_LOOPING) && _sCurr == _sCount) {
                    // Hit the end
                    _isFinished = YES;
                    _stopHandled = YES;
                }
            }
            
            // Handle synchronization update
            if((_isPlaying && !_isFinished && egwSFPVldtrIsInvalidated(_rSync, @selector(isInvalidated))) || (flags & EGW_GFXOBJ_RPLYFLG_APISYNCINVLD)) {
                alSourcefv((ALuint)_srcID, AL_POSITION, (ALfloat*)[_wcsPBVol boundingOrigin]);
                alSource3f((ALuint)_srcID, AL_DIRECTION, 0.0f, 0.0f, 0.0f);
                alSourcefv((ALuint)_srcID, AL_VELOCITY, (ALfloat*)&_wcsVelocity);
                
                ALfloat gainMod = (ALfloat)((ALfloat)((flags & EGW_SNDOBJ_RPLYFLG_GAINMODMASK) >> EGW_SNDOBJ_RPLYFLG_GAINMODSHFT) / 100.0f);
                ALfloat pitchMod = (ALfloat)((ALfloat)((flags & EGW_SNDOBJ_RPLYFLG_PITCHMODMASK) >> EGW_SNDOBJ_RPLYFLG_PITCHMODSHFT) / 100.0f);
                alSourcef((ALuint)_srcID, AL_GAIN, (ALfloat)_effects.gain * gainMod);
                alSourcef((ALuint)_srcID, AL_PITCH, (ALfloat)_effects.pitch * pitchMod);
                alSourcef((ALuint)_srcID, AL_ROLLOFF_FACTOR, (ALfloat)_rolloff);
                
                egwSFPVldtrValidate(_rSync, @selector(validate));
                flags &= ~EGW_SNDOBJ_RPLYFLG_APISYNCINVLD;
            }
            
            // Handle kickoff of source play (the only one)
            if(_isPlaying && !_isFinished && state != AL_PLAYING && (_sQueued >= EGW_STRMSOUND_NUMBFNTPLY || (!(_pFlags & EGW_SNDOBJ_PLAYFLG_LOOPING) && segmentBufferedUpTo == _sCount))) {
                //alSourcei((ALuint)_srcID, AL_SAMPLE_OFFSET, (ALint)_smpOffset);
                alSourcePlay((ALuint)_srcID);
                _stopHandled = NO;
            }
            
            pthread_mutex_unlock(&_cLock);
            
            if(_isFinished && _delegate)
                [_delegate sound:self did:EGW_ACTION_FINISH];
        }
    } else if(flags & EGW_SNDOBJ_RPLYFLG_DOPLYBCKSTART) {
        [super playWithFlags:flags];
    } else if(flags & (EGW_SNDOBJ_RPLYFLG_DOPLYBCKPAUSE | EGW_SNDOBJ_RPLYFLG_DOPLYBCKSTOP)) { // Pause and stop, special source relinquish
        if(_srcID && _srcID != NSNotFound) {
            pthread_mutex_lock(&_cLock);
            _sQueued = _sUnqueued = _sCurr = 0;
            if(_obsWork != 0) {
                _obsWork -= [egwSIAsstMngr removeAllDecodingWorkForSoundAsset:self];
                
                if(_obsWork != 0) { // The reason we wait here is because outboundWork should always refer to future queues, never past, otherwise we get negatives
                    NSDate* waitTill = [[NSDate alloc] initWithTimeIntervalSinceNow:(NSTimeInterval)EGW_ENGINE_MANAGERS_TIMETOWAIT];
                    
                    while(_obsWork != 0) {
                        if([waitTill timeIntervalSinceNow] < (NSTimeInterval)0.0) {
                            NSLog(@"egwStreamedPointSound: playWithFlags: Failure waiting for %d outbound work item(s) to report back.", _obsWork);
                            break;
                        }
                        
                        pthread_mutex_unlock(&_cLock);  // Have to temporarily unlock to allow decoder thread to edit the value (otherwise deadlock)
                        [NSThread sleepForTimeInterval:EGW_ENGINE_MANAGERS_TIMETOSLEEP];
                        pthread_mutex_lock(&_cLock);
                    }
                    
                    [waitTill release];
                }
                
                _obsWork = 0;
            }
            pthread_mutex_unlock(&_cLock);
        }
        
        [super playWithFlags:flags]; // source is relinquished in super
    } else if(flags & EGW_SNDOBJ_RPLYFLG_BUFFERLOADED) {
        pthread_mutex_lock(&_cLock);
        --_obsWork;
        
        if(_obsWork < 0)
            NSLog(@"egwStreamedPointSound: playWithFlags: Negative work return (%d) detected for sound asset '%@' (%p) buffer %d.", _obsWork, _ident, self, flags >> 16);
        
        pthread_mutex_unlock(&_cLock);
        // NOTE: Even though our outbound work will get returned - wait until update
    }
}

- (EGWuint)bufferCount {
    return _bCount;
}

- (EGWuint)bufferSize {
    return _bSize;
}

- (const EGWuint*)bufferIDs {
    return _bufIDs;
}

- (EGWbyte const * const *)bufferDatas {
    return (EGWbyte const * const *)_bDatas;
}

- (EGWuint)segmentCount {
    return _sCount;
}

- (EGWuint)segmentCurrent {
    return _sCurr;
}

@end

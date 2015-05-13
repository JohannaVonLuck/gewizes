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

/// @file egwPointSound.m
/// @ingroup geWizES_snd_pointsound
/// Point Sound Asset Implementation.

#import "egwPointSound.h"
#import "../sys/egwSysTypes.h"
#import "../sys/egwAssetManager.h"
#import "../sys/egwSndContext.h"
#import "../sys/egwSndContextAL.h"  // NOTE: Below code has a dependence on AL.
#import "../sys/egwSndMixer.h"
#import "../math/egwMath.h"
#import "../math/egwMatrix.h"
#import "../math/egwVector.h"
#import "../gfx/egwBoundings.h"
#import "../obj/egwObjectBranch.h"
#import "../phy/egwInterpolators.h"
#import "../snd/egwSound.h"
#import "../misc/egwValidater.h"


// !!!: ***** egwPointSound *****

@implementation egwPointSound

static egwPlayableJumpTable _egwPJT = { NULL };

+ (id)allocWithZone:(NSZone*)zone {
    NSObject* inst = (NSObject*)[super allocWithZone:zone];
    
    if(!_egwPJT.fpRetain && [inst isMemberOfClass:[egwPointSound class]]) {
        _egwPJT.fpRetain = (id(*)(id, SEL))[inst methodForSelector:@selector(retain)];
        _egwPJT.fpRelease = (void(*)(id, SEL))[inst methodForSelector:@selector(release)];
        _egwPJT.fpPlay = (void(*)(id, SEL, EGWuint))[inst methodForSelector:@selector(playWithFlags:)];
        _egwPJT.fpPBase = (id<NSObject>(*)(id, SEL))[inst methodForSelector:@selector(playbackBase)];
        _egwPJT.fpPFlags = (EGWuint32(*)(id, SEL))[inst methodForSelector:@selector(playbackFlags)];
        _egwPJT.fpPFrame = (EGWuint16(*)(id, SEL))[inst methodForSelector:@selector(playbackFrame)];
        _egwPJT.fpPSource = (const egwVector4f*(*)(id, SEL))[inst methodForSelector:@selector(playbackSource)];
        _egwPJT.fpPSync = (egwValidater*(*)(id, SEL))[inst methodForSelector:@selector(playbackSync)];
        _egwPJT.fpSetPFrame = (void(*)(id, SEL, EGWuint16))[inst methodForSelector:@selector(setPlaybackFrame:)];
        _egwPJT.fpFinished = (BOOL(*)(id, SEL))[inst methodForSelector:@selector(isFinished)];
        _egwPJT.fpPlaying = (BOOL(*)(id, SEL))[inst methodForSelector:@selector(isPlaying)];
        _egwPJT.fpSourced = (BOOL(*)(id, SEL))[inst methodForSelector:@selector(isSourced)];
    }
    
    return (id)inst;
}

- (id)init {
    if([self isMemberOfClass:[egwPointSound class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent soundAudio:(egwAudio*)audio soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms resonationEffects:(egwAudioEffects2f*)effects resonationRolloff:(EGWsingle)rolloff {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwPointSoundBase alloc] initNSWithIdentity:assetIdent soundAudio:audio soundRadius:radius resonationTransforms:transforms])) { [self release]; return (self = nil); }
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
    
    return self;
}

- (id)initBlankWithIdentity:(NSString*)assetIdent audioFormat:(EGWuint32)format soundRate:(EGWuint)rate soundSamples:(EGWuint)count soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms resonationEffects:(egwAudioEffects2f*)effects resonationRolloff:(EGWsingle)rolloff {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwPointSoundBase alloc] initNSBlankWithIdentity:assetIdent audioFormat:format soundRate:rate soundSamples:count soundRadius:radius resonationTransforms:transforms])) { [self release]; return (self = nil); }
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
    
    return self;
}

- (id)initPreallocatedWithIdentity:(NSString*)assetIdent bufferID:(EGWuint*)bufferID soundAudio:(egwAudio*)audio soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms resonationEffects:(egwAudioEffects2f*)effects resonationRolloff:(EGWsingle)rolloff {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwPointSoundBase alloc] initNSPreallocatedWithIdentity:assetIdent bufferID:bufferID soundAudio:audio soundRadius:radius resonationTransforms:transforms])) { [self release]; return (self = nil); }
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
    
    return self;
}

- (id)initLoadedFromResourceFile:(NSString*)resourceFile withIdentity:(NSString*)assetIdent soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms resonationEffects:(egwAudioEffects2f*)effects resonationRolloff:(EGWsingle)rolloff {
    egwAudio audio; memset((void*)&audio, 0, sizeof(egwAudio));
    
    if(!([egwSIAsstMngr loadAudio:&audio fromFile:resourceFile withTransforms:transforms])) {
        if(audio.data) egwAudioFree(&audio);
        [self release]; return (self = nil);
    }
    
    if(!(self = [self initWithIdentity:assetIdent soundAudio:&audio soundRadius:radius resonationTransforms:transforms resonationEffects:effects resonationRolloff:rolloff])) {
        if(audio.data) egwAudioFree(&audio);
        return nil;
    }
    
    return self;
}

- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent {
    if(!([asset isKindOfClass:[self class]]) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = (egwPointSoundBase*)[[asset assetBase] retain])) { [self release]; return (self = nil); }
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _pFlags = [(egwPointSound*)asset playbackFlags];
    _pFrame = EGW_FRAME_ALWAYSPASS;
    if(!(_pSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_AUDIO])) { [self release]; return (self = nil); }
    
    memcpy((void*)&_effects, (const void*)[(egwPointSound*)asset resonationEffects], sizeof(egwAudioEffects2f));
    _rolloff = [(egwPointSound*)asset resonationRolloff];
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_AUDIO])) { [self release]; return (self = nil); }
    
    egwMatCopy44f([(egwPointSound*)asset wcsTransform], &_wcsTrans);
    egwMatCopy44f([(egwPointSound*)asset lcsTransform], &_lcsTrans);
    egwVecCopy3f((egwVector3f*)[(egwPointSound*)asset resonationVelocity], (egwVector3f*)&_wcsVelocity); _wcsVelocity.axis.w = 0.0f;
    if(!(_wcsPBVol = [(NSObject*)[(egwPointSound*)asset playbackBounding] copy])) { [self release]; return (self = nil); }
    if([(id<egwPOrientated>)asset offsetDriver] && ![self trySetOffsetDriver:[(id<egwPOrientated>)asset offsetDriver]]) { [self release]; return (self = nil); }
    if([(id<egwPOrientated>)asset orientateDriver] && ![self trySetOrientateDriver:[(id<egwPOrientated>)asset orientateDriver]]) { [self release]; return (self = nil); }
    if([(id<egwPSound>)asset resonationEffectsDriver] && ![self trySetResonationEffectsDriver:[(id<egwPSound>)asset resonationEffectsDriver]]) { [self release]; return (self = nil); }
    
    _srcID = NSNotFound;
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwPointSound* copy = nil;
    NSString* copyIdent = nil;
    
    if([_ident hasSuffix:@"_default"])
        copyIdent = [[NSString alloc] initWithFormat:@"%@_%d", [_base identity], [_base nextInstanceIndex]];
    else copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwPointSound allocWithZone:zone] initCopyOf:self
                                                  withIdentity:copyIdent])) {
        NSLog(@"egwPointSound: copyWithZone: Failure initializing new sound from instance asset '%@' (%p). Failure creating copy.", _ident, self);
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
    
    [_rSync release]; _rSync = nil;
    [_pSync release]; _pSync = nil;
    
    [_wcsPBVol release]; _wcsPBVol = nil;
    
    if(_effectsIpo) { [_effectsIpo removeTargetWithObject:self]; [_effectsIpo release]; _effectsIpo = nil; }
    if(_lcsIpo) { [_lcsIpo removeTargetWithObject:self]; [_lcsIpo release]; _lcsIpo = nil; }
    if(_wcsIpo) { [_wcsIpo removeTargetWithObject:self]; [_wcsIpo release]; _wcsIpo = nil; }
    
    if(_parent) [self setParent:nil];
    [_delegate release]; _delegate = nil;
    [_ident release]; _ident = nil;
    [_base release]; _base = nil;
    
    [super dealloc];
}

- (void)applyOrientation {
    if(_ortPending && !_invkParent) {
        _invkParent = YES;
        
        [(id<egwPOrientated>)_parent applyOrientation]; // NOTE: Because the parent contains self, it will always be an orientated branch line, also parents never call a child's applyOrientation method -jw
        
        egwMatrix44f twcsTrans;
        if(!(_pFlags & EGW_OBJEXTEND_FLG_ALWAYSOTGHMG))
            egwMatMultiply44f(&_wcsTrans, &_lcsTrans, &twcsTrans);
        else
            egwMatMultiplyHmg44f(&_wcsTrans, &_lcsTrans, &twcsTrans);
        
        [_wcsPBVol orientateByTransform:&twcsTrans fromVolume:[_base playbackBounding]];
        
        _ortPending = NO;
        
        if((EGW_NODECMPMRG_AUDIO & (EGW_CORECMP_TYPE_BVOLS | EGW_CORECMP_TYPE_SOURCES | EGW_CORECMP_TYPE_SYNCS)) &&
           _parent && ![_parent isInvokingChild]) {
            EGWuint cmpntTypes = (((_pFlags & EGW_OBJTREE_FLG_NOUMRGBVOLS) || [_wcsPBVol class] == [egwZeroBounding class]) ? 0 : EGW_CORECMP_TYPE_BVOLS & EGW_NODECMPMRG_AUDIO) |
            (_pFlags & EGW_OBJTREE_FLG_NOUMRGSYNCS ? 0 : EGW_CORECMP_TYPE_SOURCES & EGW_NODECMPMRG_AUDIO) |
            (_pFlags & EGW_OBJTREE_FLG_NOUMRGSOURCES ? 0 : EGW_CORECMP_TYPE_SYNCS & EGW_NODECMPMRG_AUDIO);
            if(cmpntTypes)
                [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        }
        
        _invkParent = NO;
    }
}

- (void)offsetByTransform:(const egwMatrix44f*)lcsTransform {
    egwMatCopy44f(lcsTransform, &_lcsTrans);
    
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_pSync, @selector(invalidate));
    egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (void)orientateByTransform:(const egwMatrix44f*)wcsTransform {
    egwMatCopy44f(wcsTransform, &_wcsTrans);
    
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_pSync, @selector(invalidate));
    egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (void)orientateByImpending {
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_pSync, @selector(invalidate));
    egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (void)startPlayback {
    [egwSISndMxr playObject:self]; // TODO: Replace with call to world scene.
}

- (void)stopPlayback {
    [egwSISndMxr removeObject:self]; // TODO: Replace with call to world scene.
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
                
                alSourcei((ALuint)_srcID, AL_BUFFER, (ALint)*[_base bufferID]);
                alSourcei((ALuint)_srcID, AL_LOOPING, (ALint)(_pFlags & EGW_SNDOBJ_PLAYFLG_LOOPING ? AL_TRUE : AL_FALSE));
                alSourcei((ALuint)_srcID, AL_SAMPLE_OFFSET, (ALfloat)_smpOffset);
                alSourcei((ALuint)_srcID, AL_SOURCE_RELATIVE, (ALint)0);
                
                alSourcefv((ALuint)_srcID, AL_POSITION, (ALfloat*)[_wcsPBVol boundingOrigin]);
                alSource3f((ALuint)_srcID, AL_DIRECTION, 0.0f, 0.0f, 0.0f);
                alSourcefv((ALuint)_srcID, AL_VELOCITY, (ALfloat*)&_wcsVelocity);
                
                {   ALfloat gainMod = (ALfloat)((ALfloat)((flags & EGW_SNDOBJ_RPLYFLG_GAINMODMASK) >> EGW_SNDOBJ_RPLYFLG_GAINMODSHFT) / 100.0f);
                    ALfloat pitchMod = (ALfloat)((ALfloat)((flags & EGW_SNDOBJ_RPLYFLG_PITCHMODMASK) >> EGW_SNDOBJ_RPLYFLG_PITCHMODSHFT) / 100.0f);
                    alSourcef((ALuint)_srcID, AL_GAIN, (ALfloat)_effects.gain * gainMod);
                    alSourcef((ALuint)_srcID, AL_PITCH, (ALfloat)_effects.pitch * pitchMod);
                    alSourcef((ALuint)_srcID, AL_ROLLOFF_FACTOR, (ALfloat)_rolloff);
                }
                
                _stopHandled = YES; // initial stopped status is handled
                egwSFPVldtrValidate(_rSync, @selector(validate));
                flags &= ~EGW_SNDOBJ_RPLYFLG_APISYNCINVLD;
            } else
                NSLog(@"egwPointSound: playWithFlags: Error: Sound asset '%@' (%p) told to play but a sourceID could not be acquired.", _ident. self);
        }
        
        // Handle playback
        if(_srcID && _srcID != NSNotFound) {
            ALenum state;
            
            if(_isRestarting) {
                // NOTE: This code fake forces a play to occur later while also not disturbing too much of the existing code. -jw
                _smpOffset = 0;
                _stopHandled = YES;
                state = AL_STOPPED;
                
                _isRestarting = NO;
            } else
                // Determine how we've moved since our last encounter
                alGetSourcei(_srcID, AL_SOURCE_STATE, &state);
            
            // Handle stop state
            if(state == AL_STOPPED && !_stopHandled) {
                _isFinished = YES;
                _stopHandled = YES;
            }
            
            // Keep track of samples offset
            if(state == AL_PLAYING)
                alGetSourcei((ALuint)_srcID, AL_SAMPLE_OFFSET, (ALint*)&_smpOffset);
            
            // Handle synchronization update
            if((_isPlaying && !_isFinished && egwSFPVldtrIsInvalidated(_rSync, @selector(isInvalidated))) || (flags & EGW_SNDOBJ_RPLYFLG_APISYNCINVLD)) {
                alSourcefv((ALuint)_srcID, AL_POSITION, (ALfloat*)[_wcsPBVol boundingOrigin]);
                alSource3f((ALuint)_srcID, AL_DIRECTION, 0.0f, 0.0f, 0.0f);
                alSourcefv((ALuint)_srcID, AL_VELOCITY, (ALfloat*)&_wcsVelocity);
                
                {   ALfloat gainMod = (ALfloat)((ALfloat)((flags & EGW_SNDOBJ_RPLYFLG_GAINMODMASK) >> EGW_SNDOBJ_RPLYFLG_GAINMODSHFT) / 100.0f);
                    ALfloat pitchMod = (ALfloat)((ALfloat)((flags & EGW_SNDOBJ_RPLYFLG_PITCHMODMASK) >> EGW_SNDOBJ_RPLYFLG_PITCHMODSHFT) / 100.0f);
                    alSourcef((ALuint)_srcID, AL_GAIN, (ALfloat)_effects.gain * gainMod);
                    alSourcef((ALuint)_srcID, AL_PITCH, (ALfloat)_effects.pitch * pitchMod);
                    alSourcef((ALuint)_srcID, AL_ROLLOFF_FACTOR, (ALfloat)_rolloff);
                }
                
                egwSFPVldtrValidate(_rSync, @selector(validate));
                flags &= ~EGW_SNDOBJ_RPLYFLG_APISYNCINVLD;
            }
            
            // Handle kickoff of source play (the only one)
            if(_isPlaying && !_isFinished && state != AL_PLAYING) {
                alSourcei((ALuint)_srcID, AL_SAMPLE_OFFSET, (ALint)_smpOffset);
                alSourcePlay((ALuint)_srcID);
                _stopHandled = NO;
            }
            
            if(_isFinished && _delegate)
                [_delegate sound:self did:EGW_ACTION_FINISH];
        }
    } else if(flags & EGW_SNDOBJ_RPLYFLG_DOPLYBCKSTART) {
        if(_isPlaying) // If already playing, then this is a restart trick
            _isRestarting = YES;
        _isFinished = NO;
        _isPlaying = YES;
        _isPaused = NO;
        
        if(_delegate)
            [_delegate sound:self did:(!_isRestarting ? EGW_ACTION_START : EGW_ACTION_RESTART)];
    } else if(flags & EGW_SNDOBJ_RPLYFLG_DOPLYBCKPAUSE) {
        if(_isPlaying) {
            if(!_isPaused) {
                _isPaused = YES;
                _isRestarting = NO;
                
                // Auto-relinquish source
                if(_srcID && _srcID != NSNotFound) {
                    alSourceStop((ALuint)_srcID);
                    alSourcei((ALuint)_srcID, AL_BUFFER, (ALint)NULL);
                    _srcID = [egwAISndCntxAL returnUsedSourceID:_srcID];
                }
                
                _stopHandled = YES;
                egwSFPVldtrInvalidate(_pSync, @selector(invalidate));
                egwSFPVldtrInvalidate(_rSync, @selector(invalidate)); // Source relinquished = out of sync
            } else {
                /// ???: Not sure if this is correct. Has not been tested! -jw
                _isPaused = NO;
            }
            
            if(_delegate)
                [_delegate sound:self did:(_isPaused ? EGW_ACTION_PAUSE : EGW_ACTION_UNPAUSE)];
        }
    } else if(flags & EGW_SNDOBJ_RPLYFLG_DOPLYBCKSTOP) {
        _isPlaying = NO;
        _isRestarting = NO;
        
        _smpOffset = 0;
        
        // Auto-relinquish source
        if(_srcID && _srcID != NSNotFound) {
            alSourceStop((ALuint)_srcID);
            alSourcei((ALuint)_srcID, AL_BUFFER, (ALint)NULL);
            _srcID = [egwAISndCntxAL returnUsedSourceID:_srcID];
        }
        
        _stopHandled = NO;
        egwSFPVldtrInvalidate(_pSync, @selector(invalidate));
        egwSFPVldtrInvalidate(_rSync, @selector(invalidate)); // Source relinquished = out of sync
        
        if(_delegate)
            [_delegate sound:self did:EGW_ACTION_STOP];
    }
}

- (id<egwPAssetBase>)assetBase {
    return _base;
}

- (EGWuint)coreObjectTypes {
    return (EGW_COREOBJ_TYPE_AUDIO | EGW_COREOBJ_TYPE_ORIENTABLE);
}

- (NSString*)identity {
    return _ident;
}

- (const egwMatrix44f*)lcsTransform {
    return &_lcsTrans;
}

- (const egwMatrix44f*)wcsTransform {
    return &_wcsTrans;
}

- (id<egwPInterpolator>)offsetDriver {
    return _lcsIpo;
}

- (id<egwPInterpolator>)orientateDriver {
    return _wcsIpo;
}

- (id<egwPObjectBranch>)parent {
    return _parent;
}

- (id<egwPObjectBranch>)root {
    return (_parent ? [_parent root] : nil);
}

- (const egwPlayableJumpTable*)playableJumpTable {
    return &_egwPJT;
}

- (id<NSObject>)playbackBase {
    return _base;
}

- (id<egwPBounding>)playbackBounding {
    return _wcsPBVol;
}

- (EGWuint32)playbackFlags {
    return _pFlags;
}

- (EGWuint16)playbackFrame {
    return _pFrame;
}

- (const egwVector4f*)playbackSource {
    return [_wcsPBVol boundingOrigin];
}

- (egwValidater*)playbackSync {
    return _pSync;
}

- (const egwAudioEffects2f*)resonationEffects {
    return &_effects;
}

- (id<egwPInterpolator>)resonationEffectsDriver {
    return _effectsIpo;
}

- (EGWsingle)resonationRolloff {
    return _rolloff;
}

- (egwValidater*)resonationSync {
    return _rSync;
}

- (EGWuint)resonationTransforms {
    return [_base resonationTransforms];
}

- (const egwVector4f*)resonationVelocity {
    return &_wcsVelocity;
}

- (EGWuint)sampleOffset {
    return _smpOffset;
}

- (EGWuint)sourceID {
    return _srcID;
}

- (egwValidater*)soundBufferSync {
    return [_base soundBufferSync];
}

- (void)setDelegate:(id<egwDSoundEvent>)delegate {
    [delegate retain];
    [_delegate release];
    _delegate = delegate;
}

- (void)setParent:(id<egwPObjectBranch>)parent {
    if(_parent != parent && (id)_parent != (id)self && !_invkParent) {
        [self retain];
        
        if(_parent && ![_parent isInvokingChild]) {
            _invkParent = YES;
            [_parent removeChild:self];
            [_parent performSelector:@selector(decrementCoreObjectTypes:countBy:) withObject:(id)[self coreObjectTypes] withObject:(id)1 inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_CORECMP_TYPE_ALL withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            _invkParent = NO;
        }
        
        if(parent && _wcsIpo) {
            NSLog(@"egwPointSound: setParent: Warning: Object system is overriding WCS interpolator driver for instance asset '%@' (%p).", _ident, self);
            [self trySetOrientateDriver:nil];
        }
        
        _parent = parent; // NOTE: Weak reference, do not retain! -jw
        
        if(_parent && ![_parent isInvokingChild]) {
            _invkParent = YES;
            [_parent addChild:self];
            [_parent performSelector:@selector(incrementCoreObjectTypes:countBy:) withObject:(id)[self coreObjectTypes] withObject:(id)1 inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_CORECMP_TYPE_ALL withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            _invkParent = NO;
        }
        
        [self release];
    }
}

- (void)setGain:(EGWsingle*)gain {
    if(gain) _effects.gain = egwClamp01f(*gain);
    else _effects.gain = 1.0f;
    
    egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (void)setPitch:(EGWsingle*)pitch {
    if(pitch) _effects.pitch = egwClamp01f(*pitch);
    else _effects.pitch = 1.0f;
    
    egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (void)setPlaybackFlags:(EGWuint)flags {
    _pFlags = flags;
    
    if((EGW_NODECMPMRG_AUDIO & EGW_CORECMP_TYPE_FLAGS) &&
       _parent && !_invkParent && ![_parent isInvokingChild]) {
        _invkParent = YES;
        EGWuint cmpntTypes = (_pFlags & EGW_OBJTREE_FLG_NOUMRGFLAGS ? 0 : EGW_CORECMP_TYPE_FLAGS & EGW_NODECMPMRG_AUDIO);
        if(cmpntTypes)
            [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        _invkParent = NO;
    }
}

- (void)setPlaybackFrame:(EGWint)frmNumber {
    _pFrame = frmNumber;
    
    if((EGW_NODECMPMRG_AUDIO & EGW_CORECMP_TYPE_FRAMES) &&
       _parent && !_invkParent && ![_parent isInvokingChild]) {
        _invkParent = YES;
        EGWuint cmpntTypes = (_pFlags & EGW_OBJTREE_FLG_NOUMRGFRAMES ? 0 : EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_AUDIO);
        if(cmpntTypes)
            [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        _invkParent = NO;
    }
}

- (void)setResonationEffects:(egwAudioEffects2f*)effects {
    _effects.gain = egwClamp01f(egwAbsf(effects->gain));
    _effects.pitch = egwClamp01f(egwAbsf(effects->pitch));
    
    egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (void)setResonationVelocity:(egwVector3f*)velocity {
    egwVecCopy3f(velocity, (egwVector3f*)&_wcsVelocity);
    
    egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (BOOL)trySetOffsetDriver:(id<egwPInterpolator>)lcsIpo {
    if(lcsIpo) {
        if(([lcsIpo isKindOfClass:[egwOrientationInterpolator class]]) ||
           ([lcsIpo isKindOfClass:[egwValueInterpolator class]] && [(egwValueInterpolator*)lcsIpo channelCount] == 16 && [(egwValueInterpolator*)lcsIpo channelFormat] == EGW_KEYCHANNEL_FRMT_SINGLE)) {
            [_lcsIpo removeTargetWithObject:self];
            [lcsIpo retain];
            [_lcsIpo release];
            _lcsIpo = lcsIpo;
            [_lcsIpo addTargetWithObject:self method:@selector(offsetByTransform:)];
            
            return YES;
        }
    } else {
        [_lcsIpo removeTargetWithObject:self];
        [_lcsIpo release]; _lcsIpo = nil;
        
        return YES;
    }
    
    return NO;
}

- (BOOL)trySetOrientateDriver:(id<egwPInterpolator>)wcsIpo {
    if(wcsIpo) {
        if(!_parent &&
           (([wcsIpo isKindOfClass:[egwOrientationInterpolator class]]) ||
            ([wcsIpo isKindOfClass:[egwValueInterpolator class]] && [(egwValueInterpolator*)wcsIpo channelCount] == 16 && [(egwValueInterpolator*)wcsIpo channelFormat] == EGW_KEYCHANNEL_FRMT_SINGLE))) {
            [_wcsIpo removeTargetWithObject:self];
            [wcsIpo retain];
            [_wcsIpo release];
            _wcsIpo = wcsIpo;
            [_wcsIpo addTargetWithObject:self method:@selector(orientateByTransform:)];
            
            return YES;
        }
    } else {
        [_wcsIpo removeTargetWithObject:self];
        [_wcsIpo release]; _wcsIpo = nil;
        
        return YES;
    }
    
    return NO;
}

- (BOOL)trySetResonationEffectsDriver:(id<egwPInterpolator>)effectsIpo {
    if(effectsIpo) {
        if([effectsIpo isKindOfClass:[egwValueInterpolator class]] && [(egwValueInterpolator*)effectsIpo channelCount] == 2 && [(egwValueInterpolator*)effectsIpo channelFormat] == EGW_KEYCHANNEL_FRMT_SINGLE) {
            [_effectsIpo removeTargetWithObject:self];
            [effectsIpo retain];
            [_effectsIpo release];
            _effectsIpo = effectsIpo;
            [_effectsIpo addTargetWithObject:self method:@selector(setResonationEffects:)];
            
            return YES;
        }
    } else {
        [_effectsIpo removeTargetWithObject:self];
        [_effectsIpo release]; _effectsIpo = nil;
        
        return YES;
    }
    
    return NO;
}

- (BOOL)trySetSoundDataPersistence:(BOOL)persist {
    return [_base trySetSoundDataPersistence:persist];
}

- (BOOL)isChildOf:(id<egwPObjectBranch>)parent {
    return (_parent == parent ? YES : NO);
}

- (BOOL)isInvokingParent {
    return _invkParent;
}

- (BOOL)isLeaf {
    return YES;
}

- (BOOL)isOrientationPending {
    return _ortPending;
}

- (BOOL)isFinished {
    return _isFinished;
}

- (BOOL)isPaused {
    return _isPaused;
}

- (BOOL)isPlaying {
    return _isPlaying;
}

- (BOOL)isSourced {
    return (_srcID && _srcID != NSNotFound ? YES : NO);
}

- (BOOL)isSoundDataPersistent {
    return [_base isSoundDataPersistent];
}

- (void)validaterDidValidate:(egwValidater*)validater {
    if(_ortPending) [self applyOrientation];
    
    if(_pSync == validater &&
       (EGW_NODECMPMRG_AUDIO & EGW_CORECMP_TYPE_SYNCS) &&
       _parent && !_invkParent && ![_parent isInvokingChild]) {
        _invkParent = YES;
        EGWuint cmpntTypes = (_pFlags & EGW_OBJTREE_FLG_NOUMRGSYNCS ? 0 : EGW_OBJTREE_FLG_NOUMRGSYNCS & EGW_NODECMPMRG_AUDIO);
        if(cmpntTypes)
            [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[validater coreObjects] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        _invkParent = NO;
    }
}

- (void)validaterDidInvalidate:(egwValidater*)validater {
    if(_pSync == validater &&
       (EGW_NODECMPMRG_AUDIO & EGW_CORECMP_TYPE_SYNCS) &&
       _parent && !_invkParent && ![_parent isInvokingChild]) {
        _invkParent = YES;
        EGWuint cmpntTypes = (_pFlags & EGW_OBJTREE_FLG_NOUMRGSYNCS ? 0 : EGW_OBJTREE_FLG_NOUMRGSYNCS & EGW_NODECMPMRG_AUDIO);
        if(cmpntTypes)
            [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[validater coreObjects] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        _invkParent = NO;
    }
}

@end


// !!!: ***** egwPointSoundBase *****

@implementation egwPointSoundBase

+ (id)allocWithZone:(NSZone*)zone {
    id alloc = [super allocWithZone:zone];
    if(alloc) [egwAssetManager incBaseRef];
    if(EGW_ENGINE_ASSETS_CREATIONMSGS) NSLog(@"egwPointSoundBase: allocWithZone: Creating new sound base asset (%p).", alloc);
    return alloc;
}

- (id)init {
    if([self isMemberOfClass:[egwPointSoundBase class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initNSWithIdentity:(NSString*)assetIdent soundAudio:(egwAudio*)audio soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms {
    if(!(audio && audio->data && (self = [super init]))) { [self release]; return (self = nil); }
    else _bfType = 1;
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    if(!(_sbSync = [[egwValidater alloc] initWithOwner:self validation:NO coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    memcpy((void*)&_bfData.ns.sAudio, (const void*)audio, sizeof(egwAudio));
    memset((void*)audio, 0, sizeof(egwAudio));
    _bfData.ns.bufID = NSNotFound;
    _rsnTrans = transforms;
    
    if(radius == EGW_SFLT_MAX) {
        if(!(_mmcsPBVol = [[egwInfiniteBounding alloc] initWithBoundingOrigin:&egwSIVecZero3f])) { [self release]; return (self = nil); }
    } else if(egwIsZerof(radius)) {
        if(!(_mmcsPBVol = [[egwZeroBounding alloc] initWithBoundingOrigin:&egwSIVecZero3f])) { [self release]; return (self = nil); }
    } else {
        if(!(_mmcsPBVol = [[egwBoundingSphere alloc] initWithBoundingOrigin:&egwSIVecZero3f boundingRadius:egwAbsf(radius)])) { [self release]; return (self = nil); }
    }
    
    if(!([egwAISndCntxAL isActive] && [self performSubTaskForComponent:egwAISndCntxAL forSync:_sbSync])) // Attempt to load, if context active on this thread
        [egwAISndCntx addSubTask:self forSync:_sbSync]; // Delayed load for context sub task to handle
    
    return self;
}

- (id)initNSBlankWithIdentity:(NSString*)assetIdent audioFormat:(EGWuint32)format soundRate:(EGWuint)rate soundSamples:(EGWuint)count soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms {
    if(!(rate && count >= 2 && (self = [super init]))) { [self release]; return (self = nil); }
    else _bfType = 1;
    if(!format) format = EGW_AUDIO_FRMT_MONOS16;
    format = egwFormatFromAudioTrfm(transforms, format);
    if(!(format == EGW_AUDIO_FRMT_MONOU8 || format == EGW_AUDIO_FRMT_MONOS16 || format == EGW_AUDIO_FRMT_STEREOU8 || format == EGW_AUDIO_FRMT_STEREOS16)) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    if(!(_sbSync = [[egwValidater alloc] initWithOwner:self validation:YES coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    _bfData.ns.bufID = NSNotFound;
    _rsnTrans = transforms;
    
    if(radius == EGW_SFLT_MAX) {
        if(!(_mmcsPBVol = [[egwInfiniteBounding alloc] initWithBoundingOrigin:&egwSIVecZero3f])) { [self release]; return (self = nil); }
    } else if(egwIsZerof(radius)) {
        if(!(_mmcsPBVol = [[egwZeroBounding alloc] initWithBoundingOrigin:&egwSIVecZero3f])) { [self release]; return (self = nil); }
    } else {
        if(!(_mmcsPBVol = [[egwBoundingSphere alloc] initWithBoundingOrigin:&egwSIVecZero3f boundingRadius:egwAbsf(radius)])) { [self release]; return (self = nil); }
    }
    
    // NOTE: Delayed load will occur on buffer sync invalidation. -jw
    
    return self;
}

- (id)initNSPreallocatedWithIdentity:(NSString*)assetIdent bufferID:(EGWuint*)bufferID soundAudio:(egwAudio*)audio soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms {
    if(!(bufferID && *bufferID && *bufferID != NSNotFound && audio && (self = [super init]))) { [self release]; return (self = nil); }
    else _bfType = 1;
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    if(!(_sbSync = [[egwValidater alloc] initWithOwner:self validation:YES coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    memcpy((void*)&_bfData.ns.sAudio, (const void*)audio, sizeof(egwAudio));
    memset((void*)audio, 0, sizeof(egwAudio));
    _bfData.ns.bufID = *bufferID; *bufferID = NSNotFound;
    _rsnTrans = transforms;
    
    if(radius == EGW_SFLT_MAX) {
        if(!(_mmcsPBVol = [[egwInfiniteBounding alloc] initWithBoundingOrigin:&egwSIVecZero3f])) { [self release]; return (self = nil); }
    } else if(egwIsZerof(radius)) {
        if(!(_mmcsPBVol = [[egwZeroBounding alloc] initWithBoundingOrigin:&egwSIVecZero3f])) { [self release]; return (self = nil); }
    } else {
        if(!(_mmcsPBVol = [[egwBoundingSphere alloc] initWithBoundingOrigin:&egwSIVecZero3f boundingRadius:egwAbsf(radius)])) { [self release]; return (self = nil); }
    }
    
    return self;
}

- (id)initSWithIdentity:(NSString*)assetIdent decoderStream:(void**)stream soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms {
    if(!(stream && *stream && (self = [super init]))) { [self release]; return (self = nil); }
    else _bfType = 2;
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _sbSync = nil; // Sound buffer sync not used on streamed instances
    _bfData.s.dStream = *stream; *stream = NULL;
    
    if(radius == EGW_SFLT_MAX) {
        if(!(_mmcsPBVol = [[egwInfiniteBounding alloc] initWithBoundingOrigin:&egwSIVecZero3f])) { [self release]; return (self = nil); }
    } else if(egwIsZerof(radius)) {
        if(!(_mmcsPBVol = [[egwZeroBounding alloc] initWithBoundingOrigin:&egwSIVecZero3f])) { [self release]; return (self = nil); }
    } else {
        if(!(_mmcsPBVol = [[egwBoundingSphere alloc] initWithBoundingOrigin:&egwSIVecZero3f boundingRadius:egwAbsf(radius)])) { [self release]; return (self = nil); }
    }
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    return nil;
}

- (id)mutableCopyWithZone:(NSZone*)zone {
    return nil;
}

- (void)dealloc {
    if(_bfType == 1) {
        if(_bfData.ns.bufID && _bfData.ns.bufID != NSNotFound)
            _bfData.ns.bufID = [egwAISndCntxAL returnUsedBufferID:_bfData.ns.bufID];
        
        if(_bfData.ns.sAudio.data)
            [egwAISndCntx returnUsedBufferData:&_bfData.ns.sAudio.data];
        
        egwAudioFree(&_bfData.ns.sAudio);
    } else if(_bfType == 2) {
        if(_bfData.s.dStream) {
            [egwSIAsstMngr addDecodingWorkForSoundAsset:nil withStreamDecoder:_bfData.s.dStream segmentID:NSNotFound bufferID:NSNotFound bufferData:NULL bufferSize:0];
            _bfData.s.dStream = NULL;
        }
    }
    
    [_sbSync release]; _sbSync = nil;
    
    [_mmcsPBVol release]; _mmcsPBVol = nil;
    
    if(EGW_ENGINE_ASSETS_DESTROYMSGS) NSLog(@"egwPointSoundBase: dealloc: Destroying sound base asset '%@' (%p).", _ident, self);
    [_ident release]; _ident = nil;
    [egwAssetManager decBaseRef];
    [super dealloc];
}

- (void)baseOffsetByTransform:(const egwMatrix44f*)transform {
    [_mmcsPBVol baseOffsetByTransform:transform];
}

- (BOOL)performSubTaskForComponent:(id<NSObject>)component forSync:(egwValidater*)sync {
    if(_bfType == 1 && (id)component == (id)egwAISndCntxAL) {
        if(_bfData.ns.sAudio.data) {
            egwAudio usageAudio; memcpy((void*)&usageAudio, (const void*)&_bfData.ns.sAudio, sizeof(egwAudio));
            
            // TODO: When sound filters are implemented, uncomment this. -jw
            /*if(_isSDPersist && (_rsnFltr & EGW_SOUND_FLTR_EXDSTRYP)) {
                // Use temporary space for sound filters that destroy audio if persistence needs to be maintained
                if(!(usageAudio.data = (EGWbyte*)malloc(((size_t)usageAudio.pitch * (size_t)usageAudio.count)))) {
                    NSLog(@"egwPointSoundBase: performSubTaskForComponent:forSync: Failure allocating %d bytes for temporary sound audio. Failure buffering sound buffer for asset '%@' (%p).", ((size_t)usageAudio.pitch * (size_t)usageAudio.count), _ident, self);
                    return NO;
                } else
                    memcpy((void*)usageAudio.data, (const void*)_bfData.ns.sAudio.data, ((size_t)usageAudio.pitch * (size_t)usageAudio.count));
            }*/
            
            if([egwAISndCntxAL loadBufferID:&_bfData.ns.bufID withAudio:&usageAudio resonationTransforms:_rsnTrans]) {
                if(usageAudio.data && usageAudio.data != _bfData.ns.sAudio.data) {
                    free((void*)usageAudio.data); usageAudio.data = NULL;
                }
                
                egwSFPVldtrValidate(_sbSync, @selector(validate)); // Event delegate will dealloc if not persistent
                
                return YES; // Done with this item, no other work left
            } else
                NSLog(@"egwPointSoundBase: performSubTaskForComponent:forSync: Failure buffering sound buffer for asset '%@' (%p).", _ident, self);
            
            if(usageAudio.data && usageAudio.data != _bfData.ns.sAudio.data) {
                free((void*)(usageAudio.data)); usageAudio.data = NULL;
            }
            
            return NO; // Failure to load, try again next time
        }
    }
    
    return YES; // Nothing to do
}

- (const EGWuint*)bufferID {
    if(_bfType == 1)
        return &_bfData.ns.bufID;
    return NULL;
}

- (EGWuint)bufferType {
    return _bfType;
}

- (NSString*)identity {
    return _ident;
}

- (EGWuint)nextInstanceIndex {
    return ++_instCounter;
}

- (id<egwPBounding>)playbackBounding {
    return _mmcsPBVol;
}

- (EGWuint)resonationTransforms {
    return _rsnTrans;
}

- (const egwAudio*)soundAudio {
    if(_bfType == 1)
        return &_bfData.ns.sAudio;
    return NULL;
}

- (egwValidater*)soundBufferSync {
    return _sbSync;
}

- (EGWsingle)soundRadius {
    if([_mmcsPBVol isMemberOfClass:[egwInfiniteBounding class]]) return EGW_SFLT_MAX;
    else if([_mmcsPBVol isMemberOfClass:[egwBoundingSphere class]]) return [(egwBoundingSphere*)_mmcsPBVol boundingRadius];
    return 0.0f;
}

- (void const * const *)streamDecoder {
    if(_bfType == 2)
        return (void const * const *)&_bfData.s.dStream;
    return NULL;
}

- (BOOL)trySetSoundDataPersistence:(BOOL)persist {
    if(_bfType == 1) {
        #ifdef EGW_BUILDMODE_SND_AL
            if(egw_alBufferData == &alBufferData) {
                _isSDPersist = persist;
                
                if(!_isSDPersist && egwSFPVldtrIsValidated(_sbSync, @selector(isValidated))) {
                    if(_bfData.ns.sAudio.data) {
                        free((void*)_bfData.ns.sAudio.data); _bfData.ns.sAudio.data = NULL;
                    }
                }
                
                return YES;
            } else { // Can only set persistent to yes in case of static buffer
                if(persist)
                    _isSDPersist = persist;
                return persist;
            }
        #else
            _isSDPersist = persist;
            
            if(!_isSDPersist && egwSFPVldtrIsValidated(_sbSync, @selector(isValidated))) {
                if(_bfData.ns.sAudio.data) {
                    free((void*)_bfData.ns.sAudio.data); _bfData.ns.sAudio.data = NULL;
                }
            }
            
            return YES;
        #endif
    } else // Cannot set persistence on stream
        return NO;
}

- (BOOL)isSoundDataPersistent {
    return _isSDPersist;
}

- (void)validaterDidValidate:(egwValidater*)validater {
    #ifdef EGW_BUILDMODE_SND_AL
        if(_bfType == 1 && _sbSync == validater) {
            if(egw_alBufferData == &alBufferData) {
                if(!_isSDPersist && _bfData.ns.sAudio.data) { // Persistence check & dealloc
                    // NOTE: The sound audio is still used even after audio data is deleted - do not free the audio! -jw
                    free((void*)_bfData.ns.sAudio.data); _bfData.ns.sAudio.data = NULL;
                }
            } // don't delete buffer in case of static buffer
        }
    #else
        if(_bfType == 1 && _sbSync == validater) {
            if(!_isSDPersist && _bfData.ns.sAudio.data) { // Persistence check & dealloc
                // NOTE: The sound audio is still used even after audio data is deleted - do not free the audio! -jw
                free((void*)_bfData.ns.sAudio.data); _bfData.ns.sAudio.data = NULL;
            }
        }
    #endif
}

- (void)validaterDidInvalidate:(egwValidater*)validater {
    if(_bfType == 1 && _sbSync == validater) {
        if(_bfData.ns.sAudio.data) // Buffer audio data up through context
            [egwAISndCntx addSubTask:self forSync:_sbSync];
        else
            egwSFPVldtrValidate(_sbSync, @selector(validate));
    }
}

@end

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

/// @defgroup geWizES_inf_psound egwPSound
/// @ingroup geWizES_inf
/// Sound Protocol.
/// @{

/// @file egwPSound.h
/// Sound Protocol.

#import "egwTypes.h"
#import "../inf/egwPAsset.h"
#import "../inf/egwPPlayable.h"
#import "../inf/egwPInterpolator.h"
#import "../math/egwMathTypes.h"


/// Sound Protocol.
/// Defines interactions for sounds.
@protocol egwPSound <egwPOrientated, egwPPlayable>

/// Sound Buffer Syncronization Validater Accessor.
/// Returns the validater that manages component synchronization with a hardware buffer.
/// @return Sound buffer validater, otherwise nil (if unused).
- (egwValidater*)soundBufferSync;

/// Resonation Effects Accessor.
/// Returns the sound's audio effects settings.
/// @return Sound audio effect settings.
- (const egwAudioEffects2f*)resonationEffects;

/// Resonation Effects Driver Accessor.
/// Returns the resonation effects driver interpolator.
/// @return Resonation effects driver.
- (id<egwPInterpolator>)resonationEffectsDriver;

/// Resonation Rolloff Accessor.
/// Returns the sound's audio attenuation rolloff factor.
/// @return Sound attenuation rolloff factor.
- (EGWsingle)resonationRolloff;

/// Resonation Syncronization Validater Accessor.
/// Returns the validater that manages component synchronization with an API interface.
/// @return Sound validater, otherwise nil (if unused).
- (egwValidater*)resonationSync;

/// Resonation Transforms Accessor.
/// Returns the sound transforms settings.
/// @return Resonation transforms (EGW_SOUND_TRFM_*).
- (EGWuint)resonationTransforms;

/// Resonation Velocity Accessor.
/// Returns the sound's WCS linear velocity vector.
/// @return Linear velocity vector (WCS).
- (const egwVector4f*)resonationVelocity;


/// Resonation Effects Mutator.
/// Sets the sound's audio effects settings to provided @a effects settings.
/// @param [in] effects Audio effects settings. May be NULL (for default).
- (void)setResonationEffects:(egwAudioEffects2f*)effects;

/// Resonation Velocity Mutator.
/// Sets the sound's WCS linear velocity vector to provided @a velocity vector.
/// @param [in] velocity Linear velocity vector (WCS).
- (void)setResonationVelocity:(egwVector3f*)velocity;


/// Sound Buffer Data Persistence Tryer.
/// Attempts to set the persistence of local data for the sound buffer to @a persist.
/// @param [in] persist Persistence setting of local buffer data.
/// @return YES if setting was successfully changed, otherwise NO.
- (BOOL)trySetSoundDataPersistence:(BOOL)persist;

/// Resonation Effects Driver Tryer.
/// Attempts to set the sound's audio effects driver to @a effectsIpo.
/// @param [in] effectsIpo Audio effects driver (retained).
/// @return YES if interpolator driver is accepted, otherwise NO.
- (BOOL)trySetResonationEffectsDriver:(id<egwPInterpolator>)effectsIpo;


/// IsSoundDataPersistent Poller.
/// Polls the object to determine status.
/// @return YES if sound buffer is persistent, otherwise NO.
- (BOOL)isSoundDataPersistent;

@end

/// @}

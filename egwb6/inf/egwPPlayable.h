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

/// @defgroup geWizES_inf_pplayable egwPPlayable
/// @ingroup geWizES_inf
/// Playable Protocol.
/// @{

/// @file egwPPlayable.h
/// Playable Protocol.

#import "egwTypes.h"
#import "../inf/egwPCoreObject.h"
#import "../math/egwMathTypes.h"
#import "../misc/egwMiscTypes.h"


/// Playable Jump Table.
/// Contains function pointers to class methods for faster invocation in low tier sections.
typedef struct {
    id (*fpRetain)(id, SEL);                    ///< FP to retain.
    void (*fpRelease)(id, SEL);                 ///< FP to release.
    void (*fpPlay)(id, SEL, EGWuint);           ///< FP to playWithFlags:.
    id<NSObject> (*fpPBase)(id, SEL);           ///< FP to playbackingBase.
    EGWuint32 (*fpPFlags)(id, SEL);             ///< FP to playbackingFlags.
    EGWuint16 (*fpPFrame)(id, SEL);             ///< FP to playbackingFrame.
    const egwVector4f* (*fpPSource)(id, SEL);   ///< FP to playbackingSource.
    egwValidater* (*fpPSync)(id, SEL);          ///< FP to playbackingSync.
    void (*fpSetPFrame)(id, SEL, EGWuint16);    ///< FP to setPlaybackFrame:.
    BOOL (*fpFinished)(id, SEL);                ///< FP to isFinished.
    BOOL (*fpPlaying)(id, SEL);                 ///< FP to isPlaying.
    BOOL (*fpSourced)(id, SEL);                 ///< FP to isSourced.
} egwPlayableJumpTable;


/// Playable Protocol.
/// Defines interactions for playable components (i.e. objects that make noise).
/// @note The methods isPlaying and isFinished are not opposites of each other. isPlaying should return YES only while the sound is actually in a playing state while isFinished should only return YES while not enqueued to play and not playing.
@protocol egwPPlayable <egwPCoreObject>

/// Start Playback Method.
/// Starts playback of object by adding itself into the world scene.
- (void)startPlayback;

/// Stop Playback Method.
/// Stops playback of object by removing itself from the world scene.
- (void)stopPlayback;

/// Play With Flags Method.
/// Plays object with provided playback reply @a flags.
/// @note Do not call this method directly - this method is called automatically by the system.
/// @param [in] flags Bit-wise reply flag settings.
- (void)playWithFlags:(EGWuint32)flags;


/// Playable Jump Table.
/// Returns the playable object's jump table for subsequent low tier calls.
/// @return Playable jump table.
- (const egwPlayableJumpTable*)playableJumpTable;

/// Playback Base Object Accessor.
/// Returns the corresponding base instance object.
/// @return Base instance object, otherwise self (if unused).
- (id<NSObject>)playbackBase;

/// Playback Bounding Volume Accessor.
/// Returns the object's WCS playback bounding volume.
/// @return Playback bounding volume (WCS).
- (id<egwPBounding>)playbackBounding;

/// Playback Flags Accessor.
/// Returns the object's playback flags for subsequent play calls.
/// @return Bit-wise flag settings.
- (EGWuint32)playbackFlags;

/// Playback Frame Accessor.
/// Returns the current playback frame number that this object is set to be played on,
/// @return Current playback frame number.
- (EGWuint16)playbackFrame;

/// Playback Source Accessor.
/// Returns the object's WCS playback source position (i.e. audio source).
/// @return Playback source position (WCS).
- (const egwVector4f*)playbackSource;

/// Playback Syncronization Validater Accessor.
/// Returns the validater that manages component synchronization with a sound mixer.
/// @return Playback validater, otherwise nil (if unused).
- (egwValidater*)playbackSync;


/// Playback Flags Mutator.
/// Sets the object's playback @a flags for subsequent play calls.
/// @param [in] flags Bit-wise flag settings.
- (void)setPlaybackFlags:(EGWuint)flags;

/// Playback Frame Mutator.
/// Sets the next playback frame @a frameNumber for this object to be played on.
/// @param [in] frmNumber Next frame number to play on.
- (void)setPlaybackFrame:(EGWint)frmNumber;


/// IsFinished Poller.
/// Polls the object to determine status.
/// @return YES if object is finished from playing, otherwise NO.
- (BOOL)isFinished;

/// IsPaused Poller.
/// Polls the object to determine status.
/// @return YES if object is paused from playing, otherwise NO.
- (BOOL)isPaused;

/// IsPlaying Poller.
/// Polls the object to determine status.
/// @return YES if object is playing, otherwise NO.
- (BOOL)isPlaying;

/// IsSourced Poller.
/// Polls the object to determine status.
/// @return YES if object is sourced, otherwise NO.
- (BOOL)isSourced;

@end

/// @}

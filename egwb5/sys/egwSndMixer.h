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

/// @defgroup geWizES_sys_sndmixer egwSndMixer
/// @ingroup geWizES_sys
/// Sound Mixer.
/// @{

/// @file egwSndMixer.h
/// Sound Mixer Interface.

#import "egwSysTypes.h"
#import "../inf/egwPSingleton.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPSndContext.h"
#import "../inf/egwPTask.h"
#import "../inf/egwPPlayable.h"
#import "../sys/egwEngine.h"
#import "../data/egwDataTypes.h"


#define EGW_SNDMIXER_MIXRMODE_DFLT          0x0312  ///< Default mixer mode.
#define EGW_SNDMIXER_MIXRMODE_IMMEDIATE     0x0001  ///< Use immediate mixing mode.
#define EGW_SNDMIXER_MIXRMODE_DEFERRED      0x0002  ///< Use deferred (sorted) mixing mode.
#define EGW_SNDMIXER_MIXRMODE_1_50_35_15    0x0010  ///< Queues reserve 1 music, 50% high priority, 35% medium priority, and 15% low priority.
#define EGW_SNDMIXER_MIXRMODE_1_33_33_33    0x0020  ///< Queues reserve 1 music, and even split between high, medium, and low priority.
#define EGW_SNDMIXER_MIXRMODE_2_50_35_15    0x0040  ///< Queues reserve 2 music, 50% high priority, 35% medium priority, and 15% low priority.
#define EGW_SNDMIXER_MIXRMODE_2_33_33_33    0x0080  ///< Queues reserve 2 music, and even split between high, medium, and low priority.
#define EGW_SNDMIXER_MIXRMODE_PERSISTENT    0x0100  ///< Use a persistent object list (i.e. manual removal). Note: If unused, all objects are removed after each frame and must be re-enqueued.
#define EGW_SNDMIXER_MIXRMODE_FRAMECHECK    0x0200  ///< Use delayed object removal (i.e. frame number check).

#define EGW_SNDMIXER_MIXRQUEUE_ALL          0x00ff  ///< All playback queues.
#define EGW_SNDMIXER_MIXRQUEUE_LOWPRI       0x0001  ///< Low priority (ambient) sounds playback queue.
#define EGW_SNDMIXER_MIXRQUEUE_MEDPRI       0x0002  ///< Medium priority sounds playback queue.
#define EGW_SNDMIXER_MIXRQUEUE_HIGHPRI      0x0004  ///< High priority sounds playback queue.
#define EGW_SNDMIXER_MIXRQUEUE_MUSIC        0x0008  ///< Music playback queue.

#define EGW_SNDMIXER_MIXRQUEUE_INSERT       0x0100  ///< Insert object into queue tree structure.
#define EGW_SNDMIXER_MIXRQUEUE_REMOVE       0x0200  ///< Remove object from queue tree structure.
#define EGW_SNDMIXER_MIXRQUEUE_PAUSE        0x0400  ///< Pause/resume object in queue list structure.

#define EGW_SNDMIXER_DFLTPRIORITY   0.5     ///< Default sound mixer priority.


/// Sound Mixer.
/// Task that manages and executes playable object instances.
@interface egwSndMixer : NSObject <egwPSingleton, egwPTask> {
    egwSndMxrParams _params;                ///< Mixer parameters (copy).
    
    pthread_mutex_t _qLock;                 ///< Playback queue mutex lock.
    pthread_mutex_t _rLock;                 ///< Request queue mutex lock.
    
    egwRedBlackTree _pQueues[4];            ///< Playback queues array (alias).
    id<egwPCamera> _listenerCam;            ///< Listening camera (retained).
    
    EGWuint8 _rPBSlots[4];                  ///< Reserved playback slots per queue.
    EGWuint8 _gainMods[4];                  ///< Gain modifiers per queue.
    EGWuint8 _pitchMods[4];                 ///< Pitch modifiers per queue.
    
    egwArray _pendingList;                  ///< Queue work item pending list for remove/resort (weak).
    egwArray _requestList;                  ///< Queue work request list for insertion/removal.
    
    id<NSObject> _lBase;                    ///< Last base tracker (retained).
    EGWuint16 _tFrame;                      ///< Playback task frame.
    
    BOOL _amRunning;                        ///< Tracks run status.
    BOOL _doShutdown;                       ///< Tracks to-shutdown status.
    BOOL _modChange;                        ///< Tracks modifier change status.
	BOOL _isMuted;                          ///< Tracks mute status.
}

/// Designated Initializer.
/// Initializes the task with provided settings.
/// @param [in] params Parameters option structure. May be NULL for default.
/// @return Self upon success, otherwise nil.
- (id)initWithParams:(egwSndMxrParams*)params;


/// Play Object Method.
/// Enqueue provided @a playableObject for playback on the next frames.
/// @note An object may only be enqueued once, but multiple enqueues will still signal start playback reply messages (restart trick).
/// @param [in] playableObject Playable object instance.
- (void)playObject:(id<egwPPlayable>)playableObject;

/// Pause Object Method.
/// Pauses or resumes provided @a playableObject from/to playback on the next frames.
/// @param [in] playableObject Playable object instance.
- (void)pauseObject:(id<egwPPlayable>)playableObject;

/// Remove Object (fromQueue) Method.
/// Releases any retained @a playableObject instances currently queued.
/// @param [in] playableObject Playable object instance.
- (void)removeObject:(id<egwPPlayable>)playableObject;


/// Listener Camera Accessor.
/// Returns the camera object used as the main audio listening source.
/// @return Listening camera object.
- (id<egwPCamera>)listenerCamera;


/// Listener Camera Mutator.
/// Sets the @a camera object used as the main audio listening source.
/// @param [in] camera Listening camera object (retained).
- (void)setListenerCamera:(id<egwPCamera>)camera;

/// Gain Modifier (forQueue) Mutator.
/// Sets the @a gainMod modifier for queue @a queueIdent.
/// @param [in] gainMod Gain modifier [0,256] (x100).
/// @param [in] queueIdent Bit-wise queue identifier.
- (void)setGainModifier:(EGWuint8)gainMod forQueue:(EGWuint)queueIdent;

/// Pitch Modifier (forQueue) Mutator.
/// Sets the @a pitchMod modifier for queue @a queueIdent.
/// @param [in] pitchMod Pitch modifier [0,256] (x100).
/// @param [in] queueIdent Bit-wise queue identifier.
- (void)setPitchModifier:(EGWuint8)pitchMod forQueue:(EGWuint)queueIdent;


/// Mute Status Mutator.
/// Set the mixer's muted status to @a status.
- (void)setMute:(BOOL)status;

@end


/// Global current singleton egwSndMixer instance (weak).
extern egwSndMixer* egwSISndMxr;

/// @}

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

/// @defgroup geWizES_inf_psndcontext egwPSndContext
/// @ingroup geWizES_inf
/// Sound API Context Protcol.
/// @{

/// @file egwPSndContext.h
/// Sound API Context Protcol.

#import "egwTypes.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPCamera.h"


/// Sound Context Event Delegate.
/// Contains event methods that a delegate object can handle.
/// TODO: Move this to sys. -jw
@protocol egwDSndContextEvent <NSObject>
- (BOOL)willFinishInitializingSndContext:(id<egwPSndContext>)context;   ///< @brief Further setup calls should go here. Return NO if failure.
- (void)didFinishInitializingSndContext:(id<egwPSndContext>)context;    ///< @brief Notification of completed initialization.
- (BOOL)willShutDownSndContext:(id<egwPSndContext>)context;             ///< @brief Determination of should shut down should go here. Return NO if cancel.
- (void)didShutDownSndContext:(id<egwPSndContext>)context;              ///< @brief Notification of completed shut down.
@end


/// Sound API Context Protocol.
/// Defines interactions for sound API contexts (e.g. ones that manage sound API interactivity).
@protocol egwPSndContext <egwPContext>

/// Active Camera Accessor.
/// Returns the currently activate listening camera.
/// @return Listening camera.
- (id<egwPCamera>)activeCamera;

/// Playback Frame Accessor.
/// Returns the current playback frame number.
/// @return Playback frame number.
- (EGWuint16)playbackFrame;

/// Max Sounds Accessor.
/// Returns the max supported number of consecutively active/playing sounds.
/// @return Maximum active sounds.
- (EGWuint16)maxActiveSources;

/// System Volume Accessor.
/// Returns the current volume level of the sound system.
/// @return System volume [0,100].
- (EGWuint)systemVolume;


/// Active Camera Mutator.
/// Sets the currently active listener camera.
/// @param [in] camera Listening camera object (retained).
- (void)setActiveCamera:(id<egwPCamera>)camera;

/// System Volume Mutator.
/// Sets the current volume level of the sound system.
/// @param [in] volume Volume level [0,100].
- (void)setSystemVolume:(EGWuint)volume;

@end

/// @}

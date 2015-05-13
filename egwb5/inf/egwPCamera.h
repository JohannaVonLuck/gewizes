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

/// @defgroup geWizES_inf_pcamera egwPCamera
/// @ingroup geWizES_inf
/// Camera Protocol.
/// @{

/// @file egwPCamera.h
/// Camera Protocol.

#import "egwTypes.h"
#import "../inf/egwPCoreObject.h"
#import "../inf/egwPAsset.h"
#import "../inf/egwPOrientated.h"
#import "../inf/egwPBounding.h"
#import "../math/egwMathTypes.h"
#import "../gfx/egwGfxTypes.h"
#import "../misc/egwMiscTypes.h"


/// Camera Protocol.
/// Defines interactions for cameras.
@protocol egwPCamera <egwPCoreObject, egwPOrientated>

/// Bind (forPlaybackWithFlags) Method.
/// Binds camera for next sound playback pass with provided @a flags.
/// @note Do not call this method directly - this method is called automatically by the system.
/// @param [in] flags Binding flags.
/// @return YES if bind was successful, otherwise NO.
- (BOOL)bindForPlaybackWithFlags:(EGWuint)flags;

/// Bind (forRenderingWithFlags) Method.
/// Binds camera for next object rendering pass with provided @a flags.
/// @note Do not call this method directly - this method is called automatically by the system.
/// @param [in] flags Binding flags.
/// @return YES if bind was successful, otherwise NO.
- (BOOL)bindForRenderingWithFlags:(EGWuint)flags;

/// Orientate (byLookingAtWithCameraAt) Method.
/// Orients the camera into the WCS with the provided parameters for subsequent render/playback passes.
/// @param [in] lookPos WCS 3-D look-at position point.
/// @param [in] camPos WCS 3-D camera position point.
- (void)orientateByLookingAt:(const egwVector3f*)lookPos withCameraAt:(const egwVector3f*)camPos;

/// Picking Ray From Point Method.
/// Creates a picking ray @a pickRay from @a scrnPoint.
/// @param [out] pickRay Picking ray (WCS).
/// @param [in] scrnPoint Point on view surface (SCS).
- (void)pickingRay:(egwRay4f*)pickRay fromPoint:(const egwPoint2i*)scrnPoint;


/// Linear Velocity Accessor.
/// Returns the camera's WCS linear velocity vector.
/// @return Linear velocity vector (WCS).
- (const egwVector4f*)linearVelocity;

/// Playback Syncronization Validater Accessor.
/// Returns the validater that manages component synchronization.
/// @return Playback validater, otherwise nil (if unused).
- (egwValidater*)playbackSync;

/// Rendering Syncronization Validater Accessor.
/// Returns the validater that manages component synchronization.
/// @return Rendering validater, otherwise nil (if unused).
- (egwValidater*)renderingSync;

/// Coarse Viewing Bounding Volume Accessor.
/// Returns the camera's WCS coarse viewing bounding volume.
/// @return Coarse viewing volume (WCS).
- (id<egwPBounding>)viewingBounding;

/// Fine Viewing Bounding Volume Accessor.
/// Returns the camera's WCS fine viewing bounding volume.
/// @return Fine viewing volume (WCS).
- (id<egwPBounding>)cameraBounding;

/// Viewing Flags Accessor.
/// Returns the camera's viewing flags for subsequent viewing calls.
/// @return Bit-wise flag settings.
- (EGWuint)viewingFlags;

/// Viewing Frame Accessor.
/// Returns the camera's current viewing frame number.
/// @return Current viewing frame number.
- (EGWuint16)viewingFrame;

/// Viewing Source Accessor.
/// Returns the camera's WCS viewing source position.
/// @return WCS viewing source position.
- (const egwVector4f*)viewingSource;

/// Rendering Syncronization Validater Accessor.
/// Returns the validater that manages component synchronization.
/// @return Viewing validater, otherwise nil (if unused).
- (egwValidater*)viewingSync;


/// Linear Velocity Mutator.
/// Sets the camera's WCS linear velocity vector to provided @a velocity vector.
/// @param [in] velocity Linear velocity vector (WCS).
- (void)setLinearVelocity:(egwVector3f*)velocity;

/// Viewing Flags Mutator.
/// Sets the camera's viewing @a flags for subsequent viewing calls.
/// @param [in] flags Bit-wise flag settings.
- (void)setViewingFlags:(EGWuint)flags;

@end

/// @}

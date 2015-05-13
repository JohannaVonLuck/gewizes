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

/// @defgroup geWizES_inf_pinteractable egwPInteractable
/// @ingroup geWizES_inf
/// Interactable Protocol.
/// @{

/// @file egwPInteractable.h
/// Interactable Protocol.

#import "egwTypes.h"
#import "../inf/egwPCoreObject.h"
#import "../math/egwMathTypes.h"
#import "../misc/egwMiscTypes.h"


/// Interactable Protocol.
/// Defines interactions for interactable components (i.e. objects that physically react and rely on a deltaT update).
@protocol egwPInteractable <egwPCoreObject>

/// Collision With Object Method.
/// Alerts object to a possible collision with @a object, pending either finer testing, redirection, and/or collision response.
/// @note This method is called usually upon collision on high level bounding objects only.
/// @note @a object is not required to be another interactable object (e.g. scenery collision),
/// @param [in] object Object collided with.
- (void)collisionWithObject:(id<NSObject>)object;

/// Start Ineracting Method.
/// Starts interacting and updating object by adding itself into the world scene.
- (void)startInteracting;

/// Stop Updating Method.
/// Stops interacting and updating object by removing itself from the world scene.
- (void)stopInteracting;

/// Update With Flags Method.
/// Updates object over the provided @a deltaT time slice with provided interaction reply @a flags.
/// @note Do not call this method directly - this method is called automatically by the system.
/// @param [in] deltaT Delta time slice (seconds).
/// @param [in] flags Bit-wise reply flag settings.
- (void)update:(EGWtime)deltaT withFlags:(EGWuint)flags;


/// Interaction Base Object Accessor.
/// Returns the corresponding base instance object.
/// @return Base instance object, otherwise self (if unused).
- (id<NSObject>)interactionBase;

/// Interaction Bounding Volume Accessor.
/// Returns the object's WCS interaction bounding volume.
/// @return Interaction bounding volume (WCS).
- (id<egwPBounding>)interactionBounding;

/// Interaction Flags Accessor.
/// Returns the object's interaction flags for subsequent update calls.
/// @return Bit-wise flag settings.
- (EGWuint32)interactionFlags;

/// Interaction Frame Accessor.
/// Returns the current interaction frame number that this object is set to be updated on,
/// @return Current interaction frame number.
- (EGWuint16)interactionFrame;

/// Interaction Source Accessor.
/// Returns the object's WCS interaction source position (i.e. center of mass).
/// @return Interaction source position (WCS).
- (const egwVector4f*)interactionSource;

/// Interaction Syncronization Validater Accessor.
/// Returns the validater that manages component synchronization with a physical actuator.
/// @return Interaction validater, otherwise nil (if unused).
- (egwValidater*)interactionSync;


/// Interaction Flags Mutator.
/// Sets the object's interaction @a flags for subsequent update calls.
/// @param [in] flags Bit-wise flag settings.
- (void)setInteractionFlags:(EGWuint)flags;

/// Interaction Frame Mutator.
/// Sets the next interaction frame @a frameNumber for this object to be updated on.
/// @param [in] frmNumber Next frame number to update on.
- (void)setInteractionFrame:(EGWint)frmNumber;


/// IsAwake Poller.
/// Polls the object to determine status.
/// @return YES if awake, otherwise NO.
- (BOOL)isAwake;

/// IsColliding Poller.
/// Polls the object to determine status.
/// @return YES if colliding, otherwise NO.
- (BOOL)isColliding;

/// IsInteracting Poller.
/// Polls the object to determine status.
/// @return YES if object is interacting, otherwise NO.
- (BOOL)isInteracting;

@end

/// @}

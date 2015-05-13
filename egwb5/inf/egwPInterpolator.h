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

/// @defgroup geWizES_inf_pinterpolator egwPInterpolator
/// @ingroup geWizES_inf
/// Interpolator Protocol.
/// @{

/// @file egwPInterpolator.h
/// Interpolator Protocol.

#import "egwTypes.h"
#import "../inf/egwPTimed.h"
#import "../misc/egwMiscTypes.h"


/// Interpolator Protocol.
/// Defines interactions for timed interpolation components.
@protocol egwPInterpolator <egwPTimed>

/// Add Object Target.
/// Adds target pointing to @a target on @a method to the invocation list.
/// @note Do not call this method directly - this method is called automatically by the system.
/// @param [in] target Target object (weak).
/// @param [in] method Method selector.
- (void)addTargetWithObject:(id<NSObject>)target method:(SEL)method;

/// Add Retained Object Target.
/// Adds target pointing to retained @a target on @a method to the invocation list.
/// @param [in] target Target object (retained).
/// @param [in] method Method selector.
- (void)addTargetWithRetainedObject:(id<NSObject>)target method:(SEL)method;

/// Remove Object Target.
/// Removes any targets pointing to @a target from the invocation list.
/// @note Do not call this method directly - this method is called automatically by the system.
/// @param [in] target Target object.
- (void)removeTargetWithObject:(id<NSObject>)target;

/// Add Address/Sync Target.
/// Adds target pointing to @a address with optional @a sync to the invocation list.
/// @param [in] address Target address (contents overwrite).
/// @param [in] sync Validater sync (optional, may be nil, weak).
- (void)addTargetWithAddress:(void*)address sync:(egwValidater*)sync;

/// Add Address/Retained Sync Target.
/// Adds target pointing to @a address with optional retained @a sync to the invocation list.
/// @param [in] address Target address (contents overwrite).
/// @param [in] sync Validater sync (optional, may be nil, retained).
- (void)addTargetWithAddress:(void*)address retainedSync:(egwValidater*)sync;

/// Remove Address Target.
/// Removes any targets pointing to @a address from the invocation list.
/// @param [in] address Target address.
- (void)removeTargetWithAddress:(void*)address;

/// Remove All Targets.
/// Removes all targets from the invocation list.
- (void)removeAllTargets;

@end

/// @}

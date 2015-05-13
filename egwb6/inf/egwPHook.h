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

/// @defgroup geWizES_inf_phook egwPHook
/// @ingroup geWizES_inf
/// Hook Protocol.
/// @{

/// @file egwPHook.h
/// Hook Protocol.

#import "egwTypes.h"
#import "../math/egwMathTypes.h"
#import "../inf/egwPRenderable.h"


/// Hook Protocol.
/// Defines interactions for components that have a hook to latch onto.
@protocol egwPHook <egwPRenderable>

/// Unhook Method.
/// Tells object to unhook itself.
- (void)unhook;

/// Hook Updater Method.
/// Updates a hook with provided picking @a ray.
/// @param [in] ray Picking ray (WCS).
- (void)updateHookWithPickingRay:(egwRay4f*)ray;


/// Hooking Tryer.
/// Trys to hook object with provided picking @a ray.
/// @param [in] ray Picking ray (WCS).
/// @return YES if request to hook object is accepted, otherwise NO.
- (BOOL)tryHookingWithPickingRay:(egwRay4f*)ray;


/// IsHooked Poller.
/// Polls the object to determine status.
/// @return YES if hooked, otherwise NO.
- (BOOL)isHooked;

@end

/// @}

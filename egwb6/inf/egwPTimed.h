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

/// @defgroup geWizES_inf_ptimed egwPTimed
/// @ingroup geWizES_inf
/// Timed Protocol.
/// @{

/// @file egwPTimed.h
/// Timed Protocol.

#import "egwTypes.h"
#import "../inf/egwPTimer.h"


/// Animated Protocol.
/// Defines interactions for timed/animated timer-controlled components.
@protocol egwPTimed <NSObject>

/// Time Evaluation Method.
/// Evaluates and potentially updates an animation to time index @a absT.
/// @note No garauntees can be made that this method will always trigger an evaluation (e.g. sprites, stepped ipos, etc.).
/// @param [in] absT Absolute animation time index (seconds).
- (void)evaluateToTime:(EGWtime)absT;


/// Evaluated Time Accessor.
/// Returns the current evaluated time of an animation.
/// @note EGW_TIME_NAN may be returned in case where an evaluation is indeterminable (e.g. at initialization time).
/// @note No garauntees can be made that this accessor will always return the value as given to evaluateToTime: (e.g. sprites, stepped ipos, etc.).
/// @return Absolute evaluated animation time (seconds).
- (EGWtime)evaluatedAtTime;

/// Evaluation Time Starting Bounds Accessor.
/// Returns the starting time for animation time evaluations.
/// @note EGW_TIME_NAN may be returned in case where there is no beginning evaluation time bounds.
/// @return Absolute animation evaluation time bounds beginning (seconds).
- (EGWtime)evaluationBoundsBegin;

/// Evaluation Time Finishing Bounds Accessor.
/// Returns the finishing time for animation time evaluations.
/// @note EGW_TIME_NAN may be returned in case where there is no ending evaluation time bounds.
/// @return Absolute animation evaluation time bounds ending (seconds).
- (EGWtime)evaluationBoundsEnd;

/// Evaluation Timer Accessor.
/// Returns the current evaluation timer object driving this animation's time evaluations.
/// @return Evaluation timer object (retained).
- (id<egwPTimer>)evaluationTimer;


/// Evaluation Timer Mutator.
/// Sets the evaluation timer object driving this animation's time evaluations to @a timer.
/// @param [in] timer Evaluation timer object (retained).
- (void)setEvaluationTimer:(id<egwPTimer>)timer;

@end

/// @}

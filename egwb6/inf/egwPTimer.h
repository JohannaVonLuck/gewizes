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

/// @defgroup geWizES_inf_ptimer egwPTimer
/// @ingroup geWizES_inf
/// Timer Protocol.
/// @{

/// @file egwPTimer.h
/// Timer Protocol.

#import "egwTypes.h"
#import "../inf/egwPActuator.h"


/// Timer Protocol.
/// Defines interactions for timers.
@protocol egwPTimer <egwPActuator>

/// Add Owner Method.
/// Adds the owner @a owner to the timer's target invocation list.
/// @note Do not call this method directly - this method is called automatically by the system.
/// @param [in] owner Owner object (weak).
- (void)addOwner:(id<egwPTimed>)owner;

/// Remove Owner Method.
/// Removes the owner @a owner from the timer's target invocation list.
/// @note Do not call this method directly - this method is called automatically by the system.
/// @param [in] owner Owner object (weak).
- (void)removeOwner:(id<egwPTimed>)owner;

/// Timer Evaluation Method.
/// Forces a(n) (re-)evaluation to occur on any timed owner(s).
- (void)evaluateTimer;

/// Explicit Timer Evaluation Method.
/// Forces an evaluation to occur on any timed owner(s) at @a time.
/// @note This method does not set the stored time index, but simply overrides it.
/// @param [in] time Absolute timer time index (seconds).
- (void)evaluateTimerAt:(EGWtime)time;


/// Time Index Accessor.
/// Returns the current time index of the timer.
/// @return Absolute timer time index (seconds).
/// @note EGW_TIME_NAN may be returned in case where the time is indeterminable (e.g. at initialization time).
- (EGWtime)timeIndex;

/// Timer Starting Bounds Accessor.
/// Returns the starting time for the timer.
/// @return Absolute timer time bounds beginning (seconds).
/// @note EGW_TIME_NAN may be returned in case where there is no beginning time bounds.
- (EGWtime)timerBoundsBegin;

/// Timer Finishing Bounds Accessor.
/// Returns the finishing time for the timer.
/// @return Absolute timer time bounds ending (seconds).
/// @note EGW_TIME_NAN may be returned in case where there is no ending time bounds.
- (EGWtime)timerBoundsEnd;


/// Time Index Mutator.
/// Sets the timer's absolute time index to @a time, or to closest boundary.
/// @param [in] time Absolute timer time index (seconds). 
- (void)setTimeIndex:(EGWtime)time;


/// IsAnOwner Poller.
/// Polls the object to determine status.
/// @param [in] owner Owner object (weak).
/// @return YES if @a owner is an owner, otherwise NO.
- (BOOL)isAnOwner:(id<egwPTimed>)owner;

@end

/// @}

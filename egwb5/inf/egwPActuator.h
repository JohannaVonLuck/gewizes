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

/// @defgroup geWizES_inf_pactuator egwPActuator
/// @ingroup geWizES_inf
/// Actuator Protocol.
/// @{

/// @file egwPActuator.h
/// Actuator Protocol.

#import "egwTypes.h"
#import "../inf/egwPCoreObject.h"
#import "../math/egwMathTypes.h"


/// Actuator Protocol.
/// Defines interactions for physical actuators.
@protocol egwPActuator <NSObject>

/// Start Actuating Method.
/// Starts actuating object by adding itself into the currently active physical actuator.
- (void)startActuating;

/// Stop Actuating Method.
/// Stops actuating object by removing itself from the currently active physical actuator.
- (void)stopActuating;

/// Actuate With Flags Method.
/// Updates actuator over the provided @a deltaT time slice with provided actuator @a flags.
/// @note Do not call this method directly - this method is called automatically by the system.
/// @param [in] deltaT Delta time slice (seconds).
/// @param [in] flags Bit-wise flag settings.
- (void)update:(EGWtime)deltaT withFlags:(EGWuint)flags;


/// Actuator Flags Accessor.
/// Returns the actuator flags for subsequent update calls.
/// @return Bit-wise flag settings.
- (EGWuint16)actuatorFlags;


/// Actuator Flags Mutator.
/// Sets the actuator interaction @a flags for subsequent update calls.
/// @param [in] flags Bit-wise flag settings.
- (void)setActuatorFlags:(EGWuint16)flags;


/// IsActuating Poller.
/// Polls the object to determine status.
/// @return YES if actuator is actuating, otherwise NO.
- (BOOL)isActuating;

/// IsFinished Poller.
/// Polls the object to determine status.
/// @return YES if actuator is finished from actuating, otherwise NO.
- (BOOL)isFinished;

/// IsPaused Poller.
/// Polls the object to determine status.
/// @return YES if actuator is paused from actuating, otherwise NO.
- (BOOL)isPaused;

@end

/// @}

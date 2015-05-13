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

/// @defgroup geWizES_inf_ptask egwPTask
/// @ingroup geWizES_inf
/// Task Protcol.
/// @{

/// @file egwPTask.h
/// Task Protcol.

#import "egwTypes.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPGfxContext.h"
#import "../inf/egwPPhyContext.h"
#import "../inf/egwPSndContext.h"


/// Task Protocol.
/// Defines interactions for executable tasks.
@protocol egwPTask <NSObject>

/// Perform Task Method.
/// Performs a round of execution relevant to the task.
/// @note Do not call this method directly - this method is called automatically by the system.
- (void)performTask;

/// Shut Down Task Method.
/// Performs any related task shut down tasks.
- (void)shutDownTask;


/// Task Priority Accessor.
/// Returns the task's requested thread priority.
/// @return Task thread priority [0l,1h].
- (double)taskPriority;


/// IsTaskPerforming Poller.
/// Polls the object to determine status.
/// @return YES if task is currently in a round of execution, otherwise NO.
- (BOOL)isTaskPerforming;

/// IsTaskShutDown Poller.
/// Polls the object to determine status.
/// @return YES if task is shut down, otherwise NO.
- (BOOL)isTaskShutDown;

/// IsThreadOwner Poller.
/// Polls the object to determine status.
/// @note For tasks that take a long time to complete it is advisable to set this return to YES to avoid blocking other thread owners.
/// @return YES if task should continually run on the first thread it starts on, otherwise NO.
- (BOOL)isThreadOwner;

@end

/// @}

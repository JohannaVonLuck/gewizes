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

/// @defgroup geWizES_inf_pactioned egwPActioned
/// @ingroup geWizES_inf
/// Actioned Protocol.
/// @{

/// @file egwPActioned.h
/// Actioned Protocol.

#import "egwTypes.h"


/// Actioned Protocol.
/// Defines interactions for actioned components.
@protocol egwPActioned <NSObject>

/// Enqueue Action Method.
/// Enqueues the action at @a actIndex to the actions queue.
/// @param [in] actIndex Action state index.
- (void)enqueAction:(EGWuint16)actIndex;

/// Dequeue All Actions Method.
/// Dequeues all further actions, excluding the current action.
- (void)dequeueAllActions;

/// Dequeue Last Action Method.
/// Dequeues the last trailing action, excluding the current action.
- (void)dequeueLastAction;

/// Break And Jump To Action Methiod.
/// Breaks the current action, and jumps to the action at @a actIndex.
/// @param [in] actIndex Action state index.
- (void)breakAndJumpToAction:(EGWuint16)actIndex;


/// Current Action Accessor.
/// Returns the current action index.
/// @return Current action index.
- (EGWuint16)currentAction;

/// Default Action Accessor.
/// Returns the default action index.
/// @return Default action index.
- (EGWuint16)defaultAction;

/// Available Actions Count Accessor.
/// Returns the total available number of actions.
/// @return Total number of actions.
- (EGWuint16)availableActionsCount;

/// Queued Actions Count Accessor.
/// Returns the number of queued actions, excluding the current.
/// @return Number of queued actions.
- (EGWuint16)queuedActionsCount;

@end

/// @}

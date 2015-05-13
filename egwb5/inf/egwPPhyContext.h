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

/// @defgroup geWizES_inf_pphycontext egwPPhyContext
/// @ingroup geWizES_inf
/// Physics API Context Protcol.
/// @{

/// @file egwPPhyContext.h
/// Physics API Context Protcol.

#import "egwTypes.h"
#import "../inf/egwPContext.h"


/// Physics Context Event Delegate.
/// Contains event methods that a delegate object can handle.
// TODO: Move this to sys. -jw
@protocol egwDPhyContextEvent <NSObject>
- (BOOL)willFinishInitializingPhyContext:(id<egwPPhyContext>)context;   ///< @brief Further setup calls should go here. Return NO if failure.
- (void)didFinishInitializingPhyContext:(id<egwPPhyContext>)context;    ///< @brief Notification of completed initialization.
- (BOOL)willShutDownPhyContext:(id<egwPPhyContext>)context;             ///< @brief Determination of should shut down should go here. Return NO if cancel.
- (void)didShutDownPhyContext:(id<egwPPhyContext>)context;              ///< @brief Notification of completed shut down.
@end


/// Physics API Context Protocol.
/// Defines interactions for physical API contexts (e.g. ones that manage physical API interactivity).
@protocol egwPPhyContext <egwPContext>

/// Interaction Frame Accessor.
/// Returns the current interaction frame number.
/// @return Interaction frame number.
- (EGWuint16)interactionFrame;

@end

/// @}

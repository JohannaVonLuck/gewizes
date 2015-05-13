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

/// @defgroup geWizES_inf_psubtask egwPSubTask
/// @ingroup geWizES_inf
/// Sub Task Protcol.
/// @{

/// @file egwPSubTask.h
/// Sub Task Protcol.

#import "egwTypes.h"
#import "../inf/egwPContext.h"


/// Sub Task Protocol.
/// Defines interactions for component sub tasks.
@protocol egwPSubTask <NSObject>

/// Perform Sub Task For Component Method.
/// Performs related sub task work for provided @a component.
/// @note Do not call this method directly - this method is called automatically by the system.
/// @param [in] component Component reference (weak).
/// @param [in] vSync Validator sync reference (strong).
/// @return YES if sub task has finished (and thus should be removed from sub task queue), otherwise NO.
- (BOOL)performSubTaskForComponent:(id<NSObject>)component forSync:(egwValidater*)vSync;

@end

/// @}

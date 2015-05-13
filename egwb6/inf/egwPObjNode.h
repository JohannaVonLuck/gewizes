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

/// @defgroup geWizES_inf_pobjnode egwPObjectNode
/// @ingroup geWizES_inf
/// Object Node Protocol.
/// @{

/// @file egwPObjNode.h
/// Object Node Protocol.

#import "egwTypes.h"
#import "../inf/egwPCoreObject.h"
#import "../obj/egwObjTypes.h"
#import "../misc/egwMiscTypes.h"


/// Object Node Protocol.
/// Defines interactions for object node components.
@protocol egwPObjectNode <NSCopying, egwPCoreObject, egwDValidationEvent>

/// Parent Accessor.
/// Returns parent branch container.
/// @return Parent branch container.
- (id<egwPObjectBranch>)parent;

/// Root Accessor.
/// Returns the top-most parent branch container.
/// @return Root branch container.
- (id<egwPObjectBranch>)root;


/// Parent Mutator.
/// Detaches self from current parent and sets parent to provided @a node.
/// @note When changing parent to a node inheriting from egwSwitchBranch, behavior is to add as child to all sets.
/// @param [in] parent Parent branch container (retained).
- (void)setParent:(id<egwPObjectBranch>)parent;


/// IsLeaf Poller.
/// Polls the object to determine status.
/// @return YES if object should be treated as a leaf node, otherwise NO.
- (BOOL)isLeaf;

/// IsChildOf Poller.
/// Polls the object to determine status.
/// @param [in] parent Parent branch container.
/// @return YES if self's immediate parent is @a node, otherwise NO.
- (BOOL)isChildOf:(id<egwPObjectBranch>)parent;

/// IsInvokingParent Poller.
/// Polls the object to determine status.
/// @return YES if node is invoking a parent's method, otherwise NO.
- (BOOL)isInvokingParent;

@end

/// @}

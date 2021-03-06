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

/// @defgroup geWizES_obj_switchbranch egwSwitchBranch
/// @ingroup geWizES_obj
/// Switch Branch Node Asset.
/// @{

/// @file egwSwitchBranch.h
/// Switch Branch Node Asset Interface.

#import "egwObjTypes.h"
#import "../inf/egwPAsset.h"
#import "../inf/egwPObjNode.h"
#import "../inf/egwPObjBranch.h"
#import "../inf/egwPBounding.h"
#import "../obj/egwObjectBranch.h"
#import "../misc/egwMiscTypes.h"


/// Switch Branch Node Asset.
/// Acts as an abstract multi-container for object nodes arranged in a hierarchy capable of being switched between at runtime.
/// @note INTENDED AS AN ABSTRACT CLASS ONLY!
@interface egwSwitchBranch : egwObjectBranch {
    EGWuint16 _sActive;                     ///< Active child set collection [0,n-1].
    EGWuint16 _sCount;                      ///< Child set collections count.
    NSMutableArray** _sChildren;            ///< Children set collections.
}

/// Designated Initializer.
/// Initializes the switch node asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] parent Parent container node (retained).
/// @param [in] nodes Children node instances array (contents retained).
/// @param [in] bndClass Default bounding class. May be nil (for egwBoundingSphere).
/// @param [in] sets Total child set collections.
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent parentNode:(id<egwPObjectBranch>)parent childNodes:(NSArray*)nodes defaultBounding:(Class)bndClass totalSets:(EGWuint16)sets;


/// Add Child (toSetByIndex) Method.
/// Adds child @a node instance to branch's child set collection indexed by @a setIndex.
/// @note This is a fast method; set uniqueness check not performed.
/// @param [in] node Child node instance (retained).
/// @param [in] setIndex Child set collection index [0,n-1].
- (void)addChild:(id<egwPObjectNode>)node toSetByIndex:(EGWuint)setIndex;

/// Add All Children (toSetByIndex) Method.
/// Adds all nodes in @a nodes to branch's child set collection indexed by @a setIndex.
/// @note This is a fast method; set uniqueness check not performed.
/// @param [in] nodes Children node instances array (contents retained).
/// @param [in] setIndex Child set collection index [0,n-1].
- (void)addAllChildren:(NSArray*)nodes toSetByIndex:(EGWuint)setIndex;

/// Contains Child (inSetByIndex) Method.
/// Determines if @a node is contained in branch's child set collection indexed by @a setIndex.
/// @param [in] node Child node instance.
/// @param [in] setIndex Child set collection index [0,n-1].
/// @return YES if @a node is contained by self, otherwise NO.
- (BOOL)containsChild:(id<egwPObjectNode>)node inSetByIndex:(EGWuint)setIndex;

/// Remove Child (fromSetByIndex) Method.
/// Removes all instances of child @a node from branch's child set collection indexed by @a setIndex.
/// @param [in] node Child node instance.
/// @param [in] setIndex Child set collection index [0,n-1].
- (void)removeChild:(id<egwPObjectNode>)node fromSetByIndex:(EGWuint)setIndex;

/// Remove All Children (fromSetByIndex) Method.
/// Removes all node instances from branch's child collection indexed by @a setIndex.
/// @param [in] setIndex Child set collection index [0,n-1].
- (void)removeAllChildrenFromSetByIndex:(EGWuint)setIndex;


/// Active Set Accessor.
/// Returns active child set collection.
/// @return Active child set collection.
- (NSArray*)activeSet;

/// Active Set Index Accessor.
/// Returns the active child set collection index.
/// @return Active child set collection index.
- (EGWuint16)activeSetIndex;

/// Set (byIndex) Accessor.
/// Returns the child set collection indexed by @a setIndex.
/// @param [in] setIndex Child set collection index [0,n-1].
/// @return Child set collection.
- (NSArray*)setByIndex:(EGWuint16)setIndex;

/// Total Sets Accessor.
/// Returns the total number of child set collections.
/// @return Total child set collections.
- (EGWuint16)totalSets;


/// Active Set (byIndex) Mutator.
/// Sets the currently active set to the child set collection indexed by @a setIndex.
/// @param [in] setIndex Child set collection index [0,n-1].
- (void)setActiveSetByIndex:(EGWuint16)setIndex;

@end

/// @}

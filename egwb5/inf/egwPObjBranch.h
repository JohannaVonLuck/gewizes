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

/// @defgroup geWizES_inf_pobjbranch egwPObjectBranch
/// @ingroup geWizES_inf
/// Object Branch Protocol.
/// @{

/// @file egwPObjBranch.h
/// Object Branch Protocol.

#import "egwTypes.h"
#import "../obj/egwObjTypes.h"
#import "../misc/egwMiscTypes.h"


/// Object Branch Protocol.
/// Defines interactions for object branch components.
@protocol egwPObjectBranch <egwPObjectNode>

/// Add Child Method.
/// Adds @a node to branch's child collection.
/// @note This is a fast method; set uniqueness check not performed.
/// @note In branches inheriting from egwSwitchBranch, this method applies to all sets.
/// @param [in] node Child node instance (retained).
- (void)addChild:(id<egwPObjectNode>)node;

/// Add All Children Method.
/// Adds all @a nodes to branch's child collection.
/// @note This is a fast method; set uniqueness check not performed.
/// @note In branches inheriting from egwSwitchBranch, this method applies to all sets.
/// @param [in] nodes Children node instances array (contents retained).
- (void)addAllChildren:(NSArray*)nodes;

/// Contains Child Method.
/// Determines if @a node is contained in branch's child collection.
/// @note In branches inheriting from egwSwitchBranch, this method applies to all sets.
/// @param [in] node Child node instance.
/// @return YES if @a node is contained by self, otherwise NO.
- (BOOL)containsChild:(id<egwPObjectNode>)node;

/// Remove Child Method.
/// Removes all instances of @a node from branch's child collection.
/// @note In branches inheriting from egwSwitchBranch, this method applies to all sets.
/// @param [in] node Child node instance.
- (void)removeChild:(id<egwPObjectNode>)node;

/// Remove All Children Method.
/// Removes all node instances from branch's child collection.
/// @note In branches inheriting from egwSwitchBranch, this method applies to all sets.
- (void)removeAllChildren;

/// Conforms To Protocol (Directed) Method.
/// Determines if object branch conforms to @a protocol in message @a direction.
/// @note In branches inheriting from egwSwitchBranch, this method applies to all sets.
/// @param [in] protocol Protocol class.
/// @param [in] direction Message invocation direction (EGW_NODEMSG_DIR_*).
/// @return YES if @a branch conforms to @a protocol in @a direction, otherwise NO.
- (BOOL)conformsToProtocol:(Protocol*)protocol inDirection:(EGWuint)direction;

/// Responds To Selector (Directed) Method.
/// Determines if object branch responds to @a selector in message @a direction.
/// @note In branches inheriting from egwSwitchBranch, this method applies to all sets.
/// @param [in] selector Method selector.
/// @param [in] direction Message invocation direction (EGW_NODEMSG_DIR_*).
/// @return YES if @a branch responds to @a selector in @a direction, otherwise NO.
- (BOOL)respondsToSelector:(SEL)selector inDirection:(EGWuint)direction;

/// Perform Selector (Directed) Method.
/// Performs @a selector method on object branch in message @a direction.
/// @note @a selector should not return anything important from child/parent branches nor modify child/parent set.
/// @note In branches inheriting from egwSwitchBranch, this method applies to all sets.
/// @param [in] selector Method selector.
/// @param [in] direction Message invocation direction (EGW_NODEMSG_DIR_*).
/// @return Result from performing @a selector only on this branch (if self invocating) or root (if full broadcasting), otherwise nil.
- (id)performSelector:(SEL)selector inDirection:(EGWuint)direction;

/// Perform Selector (withObjectDirected) Method.
/// Performs @a selector method with @a object argument on object branch in message @a direction.
/// @note @a selector should not return anything important from child/parent branches nor modify child/parent set.
/// @note In branches inheriting from egwSwitchBranch, this method applies to all sets.
/// @param [in] selector Method selector.
/// @param [in] object Method argument.
/// @param [in] direction Message invocation direction (EGW_NODEMSG_DIR_*).
/// @return Result from performing @a selector only on this branch (if self invocating) or root (if full broadcasting), otherwise nil.
- (id)performSelector:(SEL)selector withObject:(id)object inDirection:(EGWuint)direction;

/// Perform Selector (withObjectWithObjectDirected) Method.
/// Performs @a selector method with @a object1 and @a object2 arguments on object branch in message @a direction.
/// @note @a selector should not return anything important from child/parent branches nor modify child/parent set.
/// @note In branches inheriting from egwSwitchBranch, this method applies to all sets.
/// @param [in] selector Method selector.
/// @param [in] object1 Method argument.
/// @param [in] object2 Method argument.
/// @param [in] direction Message invocation direction (EGW_NODEMSG_DIR_*).
/// @return Result from performing @a selector only on this branch (if self invocating) or root (if full broadcasting), otherwise nil.
- (id)performSelector:(SEL)selector withObject:(id)object1 withObject:(id)object2 inDirection:(EGWuint)direction;

/// Count Core Object Types Method.
/// Returns the number of core object set types in branch's child collection.
/// @note In branches inheriting from egwSwitchBranch, this method applies to all sets.
/// @return Core type object count.
- (EGWuint)countCoreObjectTypes:(EGWuint)coreObjects;

/// Increment Core Object Types Count Method.
/// Increments the number of core object set types in branch's child collection.
/// @note In branches inheriting from egwSwitchBranch, this method applies to all sets.
/// @note This method should only be used when invoking a branch change in which count modification is the responsibility of self.
/// @param [in] coreObjects Bit-wise core object set types (EGW_COREOBJ_TYPE_*).
/// @param [in] count Incrementation count.
- (void)incrementCoreObjectTypes:(EGWuint)coreObjects countBy:(EGWuint)count;

/// Decrement Core Object Types Count Method.
/// Decrements the number of core object set types in branch's child collection.
/// @note In branches inheriting from egwSwitchBranch, this method applies to all sets.
/// @note This method should only be used when invoking a branch change in which count modification is the responsibility of self.
/// @param [in] coreObjects Bit-wise core object set types (EGW_COREOBJ_TYPE_*).
/// @param [in] count Decrementation count.
- (void)decrementCoreObjectTypes:(EGWuint)coreObjects countBy:(EGWuint)count;

/// Merge Core Component Types For Core Object Types Method.
/// Merges branch's core component types @a coreCmpnts for core types @a coreObjects.
/// @note In branches inheriting from egwSwitchBranch, this method applies to all sets.
/// @param [in] coreCmpnts Bit-wise core component set types (EGW_CORECMP_TYPE_*).
/// @param [in] coreObjects Bit-wise core object set types (EGW_COREOBJ_TYPE_*).
- (void)mergeCoreComponentTypes:(EGWuint)coreCmpnts forCoreObjectTypes:(EGWuint)coreObjects;

/// Rebound Class For Core Object Types Method.
/// Rebinds the core type's @a coreObjects bounding volume with provided @a bndClass class.
/// @param [in] bndClass Associated bounding class. May be nil (for egwBoundingSphere).
/// @param [in] coreObjects Bit-wise core object set types (EGW_COREOBJ_TYPE_*).
- (void)reboundWithClass:(Class)bndClass forCoreObjectTypes:(EGWuint)coreObjects;


/// Base Core Object Type Accessor.
/// Returns the object branch's base core object type.
/// @return Bit-wise base core object type.
- (EGWuint)baseCoreObjectType;

/// Children Accessor.
/// Returns child collection.
/// @note In branches inheriting from egwSwitchBranch, this represents the active set.
/// @return Child collection.
- (NSArray*)children;

/// Leafs For Core Objects Getter.
/// Gets all leaf assets for core object types @a coreObjects.
/// @note In branches inheriting from egwSwitchBranch, this method applies only to the active set.
/// @param [in,out] leafs Leaf children array.
/// @param [in] coreObjects Bit-wise core object set types (EGW_COREOBJ_TYPE_*).
/// @return Number of leaf assets placed into @a assets.
- (EGWuint)getLeafs:(NSMutableArray*)leafs forCoreObjectTypes:(EGWuint)coreObjects;


/// Parent Mutator.
/// Detaches self from current parent and sets parent to provided @a branch.
/// @note When changing parent to a branch inheriting from egwSwitchBranch, behavior is to add as child to all sets.
/// @param [in] parent Parent branch container (retained).
- (void)setParent:(id<egwPObjectBranch>)parent;


/// IsParentOf Poller.
/// Polls the object to determine status.
/// @param [in] node Child node instance.
/// @return YES if @a branch's immediate parent is self, otherwise NO.
- (BOOL)isParentOf:(id<egwPObjectNode>)node;

/// IsInvokingChild Poller.
/// Polls the object to determine status.
/// @return YES if branch is invoking a child's method, otherwise NO.
- (BOOL)isInvokingChild;

/// IsInvokingSelf Poller.
/// Polls the object to determine status.
/// @return YES if branch is invoking self's method, otherwise NO.
- (BOOL)isInvokingSelf;

/// IsChildOrParentInvokingSelf Poller.
/// Polls the object to determine status.
/// @return YES if parent or any child is invocating self, otherwise NO.
- (BOOL)isChildOrParentInvokingSelf;

/// IsAnybodyInvoking Poller.
/// Polls the object to determine status.
/// @return YES if self, parent, or any child is invocating self, otherwise NO.
- (BOOL)isAnybodyInvoking;

@end

/// @}

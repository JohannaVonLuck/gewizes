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

/// @defgroup geWizES_data_avltree egwAVLTree
/// @ingroup geWizES_data
/// Height-Balanced AVL Tree.
/// @{

/// @file egwAVLTree.h
/// Height-Balanced AVL Tree Interface.

#import "egwDataTypes.h"


// !!!: ***** Initialization *****

/// AVL Tree Initialization Routine.
/// Initializes AVL tree with provided parameters.
/// @note Elements are tightly packed without padding after the link pointer data section.
/// @param [out] tree_out AVL tree output of initialization.
/// @param [in] funcs_in Data routine functions (contents copy-over, may be NULL for default routines).
/// @param [in] elmSize_in Element size (bytes).
/// @param [in] flags_in Tree attribute flags (EGW_TREE_FLG_*).
/// @return @a tree_out (for nesting), otherwise NULL if failure initializing.
egwAVLTree* egwAVLTreeInit(egwAVLTree* tree_out, egwDataFuncs* funcs_in, EGWuint elmSize_in, EGWuint flags_in);

/// AVL Tree Copy Routine.
/// Initializes AVL tree from deep copy of another.
/// @param [in] tree_in AVL tree input structure.
/// @param [out] tree_out AVL tree output of copy.
/// @return @a tree_out (for nesting), otherwise NULL if failure copying.
egwAVLTree* egwAVLTreeCopy(const egwAVLTree* tree_in, egwAVLTree* tree_out);

/// AVL Tree Free Routine.
/// Frees the contents of the AVL tree.
/// @param [in,out] tree_inout AVL tree input/output structure.
/// @return @a tree_inout (for nesting), otherwise NULL if failure free'ing.
egwAVLTree* egwAVLTreeFree(egwAVLTree* tree_inout);


// !!!: ***** Addition *****

/// AVL Tree Add Routine.
/// Adds an element into the tree at its sorted postion at O(log n) insertion cost.
/// @param [in,out] tree_inout AVL tree input/output structure.
/// @param [in] data_in Element data input buffer (contents copy-over, may be NULL for zero'ed data segment).
/// @return 1 if element was successfully added, otherwise 0.
EGWint egwAVLTreeAdd(egwAVLTree* tree_inout, const EGWbyte* data_in);


// !!!: ***** Removal *****

/// AVL Tree Remove Routine.
/// Removes an element node from the AVL tree at O(log n) deletion cost.
/// @param [in,out] tree_inout AVL tree input/output structure.
/// @param [in,out] node_inout Tree node element that should be removed.
/// @return 1 if element was successfully removed, otherwise 0.
EGWint egwAVLTreeRemove(egwAVLTree* tree_inout, egwAVLTreeNode* node_inout);

/// AVL Tree Remove Any Routine.
/// Removes any matching element from the AVL tree at O(n log n) transversal cost and O(log n) deletion cost.
/// @param [in,out] tree_inout AVL tree input/output structure.
/// @param [in] data_in Element data input buffer to match against.
/// @return Number of elements removed.
EGWuint egwAVLTreeRemoveAny(egwAVLTree* tree_inout, const EGWbyte* data_in);

/// AVL Tree Remove All Routine.
/// Removes all elements from the AVL tree at O(n) transversal cost (if needed) and O(1) deletion cost.
/// @param [in,out] tree_inout AVL tree input/output structure.
/// @return 1 if all elements were successfully removed, otherwise 0.
EGWint egwAVLTreeRemoveAll(egwAVLTree* tree_inout);


// !!!: ***** Fetching *****

/// AVL Tree Get Element Routine.
/// Copies the element contents from the AVL tree at the specified node into the output buffer at O(1) copy cost.
/// @note This routine does a simple memory copy-over - ownership issues fall to the responsibility of the code using this routine.
/// @param [in] tree_in AVL tree input structure.
/// @param [in] node_in Tree node to which element data should be copied from.
/// @param [out] data_out Element data output buffer (contents copy-over).
void egwAVLTreeGetElement(const egwAVLTree* tree_in, const egwAVLTreeNode* node_in, EGWbyte* data_out);

/// AVL Tree Element Pointer Routine.
/// Returns the element data buffer pointer from the AVL tree at the specified tree node.
/// @param [in] node_in Tree node to which element data pointer should be given from.
/// @return Element data buffer pointer.
EGWbyte* egwAVLTreeElementPtr(const egwAVLTreeNode* node_in);

/// AVL Tree Node Pointer Routine.
/// Returns the tree node pointer from the AVL tree given the specified element data buffer pointer.
/// @param [in] data_in Element data input buffer to which tree node pointer should be given from.
/// @return Tree node pointer.
egwAVLTreeNode* egwAVLTreeNodePtr(const EGWbyte* data_in);


// !!!: ***** Searching *****

/// AVL Tree Find Routine.
/// Attempts to find the tree node pointer of an element in the AVL tree given the provided parameters at O(log n) transversal cost.
/// @param [in] tree_in AVL tree input structure.
/// @param [in] data_in Element data input buffer to match against.
/// @return Element index if search successful, -1 otherwise.
egwAVLTreeNode* egwAVLTreeFind(const egwAVLTree* tree_in, const EGWbyte* data_in);

/// AVL Tree Contains Routine.
/// Attempts to find the existence of an element in the AVL tree given the provided parameters at O(log n) transversal cost.
/// @param [in] tree_in AVL tree input structure.
/// @param [in] data_in Element data input buffer to match against.
/// @return 1 if search successful, otherwise 0.
EGWint egwAVLTreeContains(const egwAVLTree* tree_in, const EGWbyte* data_in);

/// AVL Tree Occurances Routine.
/// Attempts to find the number of occurances of an element in the AVL tree given the provided parameters at O(log n) transversal cost.
/// @param [in] tree_in AVL tree input structure.
/// @param [in] data_in Element data input buffer to match against.
/// @return Number of element occurances.
EGWuint egwAVLTreeOccurances(const egwAVLTree* tree_in, const EGWbyte* data_in);


// !!!: ***** Sorting *****

/// AVL Tree Resort Routine.
/// Attempts to resort the element of the AVL tree at the specified tree node at O(n) time cost.
/// @param [in,out] tree_inout AVL tree input/output structure.
/// @param [in,out] node_inout Tree node to which to resort at.
/// @return 1 if any swaps were performed, otherwise 0.
EGWint egwAVLTreeResortElement(egwAVLTree* tree_inout, egwAVLTreeNode* node_inout);


// !!!: ***** Enumerating *****

/// AVL Tree Enumerate Start Routine.
/// Attempts to start an enumeration of the AVL tree given the provided iteration mode.
/// @note No mechanism is provided to ensure the data contents are not modified while being enumerated - it is left up to the user to determine what effects should result, if any.
/// @note Level-order iteration mode allocates a temporary storage array in the iterator structure that must be manually free'd if iteration is not allowed to finished.
/// @param [in] tree_in AVL tree input structure.
/// @param [in] iterMode_in Iteration mode (EGW_ITERATE_MODE_*).
/// @param [out] iter_out Iterator output structure.
/// @return 1 if enumeration start successful, otherwise 0 if empty or invalid iteration mode.
EGWint egwAVLTreeEnumerateStart(const egwAVLTree* tree_in, EGWuint iterMode_in, egwAVLTreeIter* iter_out);

/// AVL Tree Enumeration Get Next Routine.
/// Copies the next enumerated element's contents from the AVL tree into the output buffer at O(1) transversal cost and O(1) copy cost.
/// @note This routine does a simple memory copy-over - ownership issues fall to the responsibility of the code using this routine.
/// @param [in,out] iter_inout Iterator input/output structure.
/// @param [out] data_out Element data output buffer (contents copy-over).
/// @return 1 if enumeration of next element successful, otherwise 0 if at end of enumeration.
EGWint egwAVLTreeEnumerateGetNext(egwAVLTreeIter* iter_inout, EGWbyte* data_out);

/// AVL Tree Enumeration Next Pointer Routine.
/// Returns the next enumerated element's data buffer pointer from the AVL tree at O(1) transversal cost.
/// @param [in,out] iter_inout Iterator input/output structure.
/// @return Element data buffer pointer to the next enumerated element, otherwise NULL if at end of enumeration.
EGWbyte* egwAVLTreeEnumerateNextPtr(egwAVLTreeIter* iter_inout);

/// @}

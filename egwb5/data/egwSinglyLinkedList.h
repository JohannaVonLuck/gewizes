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

/// @defgroup geWizES_data_singlylinkedlist egwSinglyLinkedList
/// @ingroup geWizES_data
/// Singly-Linked List.
/// @{

/// @file egwSinglyLinkedList.h
/// Singly-Linked List Interface.

#import "egwDataTypes.h"


// !!!: ***** Initialization *****

/// Singly Linked List Initialization Routine.
/// Initializes singly linked list with provided parameters.
/// @note Elements are tightly packed without padding after the link pointer data section.
/// @param [out] list_out Singly linked list output of initialization.
/// @param [in] funcs_in Data routine functions (contents copy-over, may be NULL for default routines).
/// @param [in] elmSize_in Element size (bytes).
/// @param [in] flags_in List attribute flags (EGW_LIST_FLG_*).
/// @return @a list_out (for nesting), otherwise NULL if failure initializing.
egwSinglyLinkedList* egwSLListInit(egwSinglyLinkedList* list_out, egwDataFuncs* funcs_in, EGWuint elmSize_in, EGWuint flags_in);

// Singly Linked List Copy Routine.
// Initializes singly linked list from deep copy of another.
// @param [in] list_in Singly linked list input structure.
// @param [out] list_out Singly linked list output of copy.
// @return @a list_out (for nesting), otherwise NULL if failure copying.
//egwSinglyLinkedList* egwSLListCopy(const egwSinglyLinkedList* list_in, egwSinglyLinkedList* list_out);

/// Singly Linked List Free Routine.
/// Frees the contents of the singly linked list.
/// @param [in,out] list_inout Singly linked list input/output structure.
/// @return @a list_inout (for nesting), otherwise NULL if failure free'ing.
egwSinglyLinkedList* egwSLListFree(egwSinglyLinkedList* list_inout);


// !!!: ***** Addition *****

// Singly Linked List Add At Routine.
// Adds an element into the singly linked list at the specified index at O(n) transversal cost and O(1) insertion cost.
// @param [in,out] list_inout Singly linked list input/output structure.
// @param [in] index_in Element index to insert at (zero based starting at head).
// @param [in] data_in Element data input buffer (contents copy-over, may be NULL for zero'ed data segment).
// @return 1 if element was successfully added, otherwise 0.
//EGWint egwSLListAddAt(egwSinglyLinkedList* list_inout, EGWuint index_in, const EGWbyte* data_in);

/// Singly Linked List Add Head Routine.
/// Adds an element into the singly linked list at the head at O(1) insertion cost.
/// @param [in,out] list_inout Singly linked list input/output structure.
/// @param [in] data_in Element data input buffer (contents copy-over, may be NULL for zero'ed data segment).
/// @return 1 if element was successfully added, otherwise 0.
EGWint egwSLListAddHead(egwSinglyLinkedList* list_inout, const EGWbyte* data_in);

/// Singly Linked List Add Tail Routine.
/// Adds an element into the singly linked list at the tail at O(1) insertion cost.
/// @param [in,out] list_inout Singly linked list input/output structure.
/// @param [in] data_in Element data input buffer (contents copy-over, may be NULL for zero'ed data segment).
/// @return 1 if element was successfully added, otherwise 0.
EGWint egwSLListAddTail(egwSinglyLinkedList* list_inout, const EGWbyte* data_in);

// Singly Linked List Add Sorted Routine.
// Adds an element into the singly linked list maintaining sort ordering at O(n) transversal cost and O(1) insertion cost.
// @note This routine assume the list contents are already in sorted order.
// @param [in,out] list_inout Singly linked list input/output structure.
// @param [in] data_in Element data input buffer (contents copy-over, may be NULL for zero'ed data segment).
// @param [in] findMode_in Element search mode (EGW_FIND_MODE_*).
// @return 1 if element was successfully added, otherwise 0.
//EGWint egwSLListAddSorted(egwSinglyLinkedList* list_inout, const EGWbyte* data_in, EGWuint findMode_in);

/// Singly Linked List Add After Routine.
/// Adds an element into the singly linked list after the given list node at O(1) insertion cost.
/// @param [in,out] list_inout Singly linked list input/output structure.
/// @param [in,out] node_inout List node to which element should be added after (may be NULL for add at head).
/// @param [in] data_in Element data input buffer (contents copy-over, may be NULL for zero'ed data segment).
/// @return 1 if element was successfully added, otherwise 0.
EGWint egwSLListAddAfter(egwSinglyLinkedList* list_inout, egwSinglyLinkedListNode* node_inout, const EGWbyte* data_in);

/// Singly Linked List Add Before Routine.
/// Adds an element into the singly linked list before the given list node at O(n) insertion cost.
/// @param [in,out] list_inout Singly linked list input/output structure.
/// @param [in,out] node_inout List node to which element should be added before (may be NULL for add at tail).
/// @param [in] data_in Element data input buffer (contents copy-over, may be NULL for zero'ed data segment).
/// @return 1 if element was successfully added, otherwise 0.
EGWint egwSLListAddBefore(egwSinglyLinkedList* list_inout, egwSinglyLinkedListNode* node_inout, const EGWbyte* data_in);


// !!!: ***** Removal *****

/// Singly Linked List Remove Routine.
/// Removes an element node from the singly linked list at O(n) deletion cost.
/// @param [in,out] list_inout Singly linked list input/output structure.
/// @param [in,out] node_inout List node element that should be removed.
/// @return 1 if element was successfully removed, otherwise 0.
EGWint egwSLListRemove(egwSinglyLinkedList* list_inout, egwSinglyLinkedListNode* node_inout);

// Singly Linked List Remove At Routine.
// Removes an element from the singly linked list at the specified index at O(n) deletion cost.
// @param [in,out] list_inout Singly linked list input/output structure.
// @param [in] index_in Element index to remove at (zero based starting at head).
// @return 1 if element was successfully removed, otherwise 0.
//EGWint egwSLListRemoveAt(egwSinglyLinkedList* list_inout, EGWuint index_in);

/// Singly Linked List Remove Head Routine.
/// Removes the head element from the singly linked list at O(1) deletion cost.
/// @param [in,out] list_inout Singly linked list input/output structure.
/// @return 1 if element was successfully removed, otherwise 0.
EGWint egwSLListRemoveHead(egwSinglyLinkedList* list_inout);

/// Singly Linked List Remove Tail Routine.
/// Removes the tail element from the singly linked list at O(1) deletion cost.
/// @param [in,out] list_inout Singly linked list input/output structure.
/// @return 1 if element was successfully removed, otherwise 0.
EGWint egwSLListRemoveTail(egwSinglyLinkedList* list_inout);

/// Singly Linked List Remove After Routine.
/// Removes an element from the singly linked list after the given list node at O(1) deletion cost.
/// @param [in,out] list_inout Singly linked list input/output structure.
/// @param [in,out] node_inout List node to which element should be removed after (may be NULL for remove head).
/// @return 1 if element was successfully removed, otherwise 0.
EGWint egwSLListRemoveAfter(egwSinglyLinkedList* list_inout, egwSinglyLinkedListNode* node_inout);

/// Singly Linked List Remove Before Routine.
/// Removes an element from the singly linked list before the given list node at O(n) deletion cost.
/// @param [in,out] list_inout Singly linked list input/output structure.
/// @param [in,out] node_inout List node to which element should be removed before (may be NULL for remove tail).
/// @return 1 if element was successfully removed, otherwise 0.
EGWint egwSLListRemoveBefore(egwSinglyLinkedList* list_inout, egwSinglyLinkedListNode* node_inout);

/// Singly Linked List Remove Any Routine.
/// Removes any matching element from the singly linked list at O(n) transversal cost and O(1) deletion cost.
/// @param [in,out] list_inout Singly linked list input/output structure.
/// @param [in] data_in Element data input buffer to match against.
/// @return Number of elements removed.
EGWuint egwSLListRemoveAny(egwSinglyLinkedList* list_inout, const EGWbyte* data_in);

/// Singly Linked List Remove All Routine.
/// Removes all elements from the singly linked list at O(n) transversal cost (if needed) and O(n) deletion cost.
/// @param [in,out] list_inout Singly linked list input/output structure.
/// @return 1 if all elements were successfully removed, otherwise 0.
EGWint egwSLListRemoveAll(egwSinglyLinkedList* list_inout);


// !!!: ***** Promotion *****

/// Singly Linked List Head Node Promotion Routine.
/// Promotes the list node to the head of the singly linked list at O(n) transversal cost and O(1) deletion and insertion cost.
/// @param [in,out] list_inout Singly linked list input/output structure.
/// @param [in,out] node_inout List node to which element should be promoted to head.
/// @return 1 if node was successfully moved, otherwise 0.
EGWint egwSLListPromoteToHead(egwSinglyLinkedList* list_inout, egwSinglyLinkedListNode* node_inout);

/// Singly Linked List Head Node Promotion After Routine.
/// Promotes the list node after the given list node to the head of the singly linked list at O(1) deletion and insertion cost.
/// @param [in,out] list_inout Singly linked list input/output structure.
/// @param [in,out] node_inout List node to which the element after should be promoted to head.
/// @return 1 if node was successfully moved, otherwise 0.
EGWint egwSLListPromoteToHeadAfter(egwSinglyLinkedList* list_inout, egwSinglyLinkedListNode* node_inout);

/// Singly Linked List Tail Node Promotion Routine.
/// Promotes the list node to the tail of the singly linked list at O(n) transversal cost and O(1) deletion and insertion cost.
/// @param [in,out] list_inout Singly linked list input/output structure.
/// @param [in,out] node_inout List node to which element should be promoted to tail.
/// @return 1 if node was successfully moved, otherwise 0.
EGWint egwSLListPromoteToTail(egwSinglyLinkedList* list_inout, egwSinglyLinkedListNode* node_inout);

/// Singly Linked List Tail Node Promotion After Routine.
/// Promotes the list node after the given list node to the tail of the singly linked list at O(1) deletion and insertion cost.
/// @param [in,out] list_inout Singly linked list input/output structure.
/// @param [in,out] node_inout List node to which the element after should be promoted to tail.
/// @return 1 if node was successfully moved, otherwise 0.
EGWint egwSLListPromoteToTailAfter(egwSinglyLinkedList* list_inout, egwSinglyLinkedListNode* node_inout);


// !!!: ***** Fetching *****

/// Singly Linked List Get Element Routine.
/// Copies the element contents from the singly linked list at the specified node into the output buffer at O(1) copy cost.
/// @note This routine does a simple memory copy-over - ownership issues fall to the responsibility of the code using this routine.
/// @param [in] list_in Singly linked list input structure.
/// @param [in] node_in List node to which element data should be copied from.
/// @param [out] data_out Element data output buffer (contents copy-over).
void egwSLListGetElement(const egwSinglyLinkedList* list_in, const egwSinglyLinkedListNode* node_in, EGWbyte* data_out);

/// Singly Linked List Get Element At Routine.
/// Copies the element contents from the singly linked list at the specified index into the output buffer at O(n) transversal cost and O(1) copy cost.
/// @note This routine does a simple memory copy-over - ownership issues fall to the responsibility of the code using this routine.
/// @param [in] list_in Singly linked list input structure.
/// @param [in] index_in Element index to grab at (zero based starting at head).
/// @param [out] data_out Element data output buffer (contents copy-over).
void egwSLListGetElementAt(const egwSinglyLinkedList* list_in, EGWuint index_in, EGWbyte* data_out);

/// Singly Linked List Get Element Head Routine.
/// Copies the head element contents from the singly linked list into the output buffer at O(1) transversal cost and O(1) copy cost.
/// @note This routine does a simple memory copy-over - ownership issues fall to the responsibility of the code using this routine.
/// @param [in] list_in Singly linked list input structure.
/// @param [out] data_out Element data output buffer (contents copy-over).
void egwSLListGetElementHead(const egwSinglyLinkedList* list_in, EGWbyte* data_out);

/// Singly Linked List Get Element Tail Routine.
/// Copies the tail element contents from the singly linked list into the output buffer at O(1) transversal cost and O(1) copy cost.
/// @note This routine does a simple memory copy-over - ownership issues fall to the responsibility of the code using this routine.
/// @param [in] list_in Singly linked list input structure.
/// @param [out] data_out Element data output buffer (contents copy-over).
void egwSLListGetElementTail(const egwSinglyLinkedList* list_in, EGWbyte* data_out);

/// Singly Linked List Element Pointer Routine.
/// Returns the element data buffer pointer from the singly linked list at the specified list node.
/// @param [in] node_in List node to which element data pointer should be given from.
/// @return Element data buffer pointer.
EGWbyte* egwSLListElementPtr(const egwSinglyLinkedListNode* node_in);

/// Singly Linked List Element Pointer At Routine.
/// Returns the element data buffer pointer from the singly linked list at the specified index at O(n) transversal cost.
/// @param [in] list_in Singly linked list input structure.
/// @param [in] index_in Element index to transverse to (zero based starting at head).
/// @return Element data buffer pointer at the specified index, otherwise NULL if bad index.
EGWbyte* egwSLListElementPtrAt(const egwSinglyLinkedList* list_in, EGWuint index_in);

/// Singly Linked List Head Element Pointer Routine.
/// Returns the head element data buffer pointer from the singly linked list at O(1) transversal cost.
/// @param [in] list_in Singly linked list input structure.
/// @return Head element data buffer pointer, otherwise NULL if empty.
EGWbyte* egwSLListElementPtrHead(const egwSinglyLinkedList* list_in);

/// Singly Linked List Element Tail Pointer Routine.
/// Returns the tail element data buffer pointer from the singly linked list at O(1) transversal cost.
/// @param [in] list_in Singly linked list input structure.
/// @return Tail element data buffer pointer, otherwise NULL if empty.
EGWbyte* egwSLListElementPtrTail(const egwSinglyLinkedList* list_in);

/// Singly Linked List Node Pointer Routine.
/// Returns the list node pointer from the singly linked list given the specified element data buffer pointer.
/// @param [in] data_in Element data input buffer to which tree node pointer should be given from.
/// @return List node pointer.
egwSinglyLinkedListNode* egwSLListNodePtr(const EGWbyte* data_in);


// !!!: ***** Searching *****

/// Singly Linked List Find Routine.
/// Attempts to find the list node pointer of an element in the singly linked list given the provided parameters at O(n) transversal cost (forward search only).
/// @param [in] list_in Singly linked list input structure.
/// @param [in] data_in Element data input buffer to match against.
/// @param [in] findMode_in Element search mode (EGW_FIND_MODE_*).
/// @return Element index if search successful, -1 otherwise.
egwSinglyLinkedListNode* egwSLListFind(const egwSinglyLinkedList* list_in, const EGWbyte* data_in, EGWuint findMode_in);

/// Singly Linked List Contains Routine.
/// Attempts to find the existence of an element in the singly linked list given the provided parameters at O(n) transversal cost (forward search only).
/// @param [in] list_in Singly linked list input structure.
/// @param [in] data_in Element data input buffer to match against.
/// @param [in] findMode_in Element search mode (EGW_FIND_MODE_*).
/// @return 1 if search successful, otherwise 0.
EGWint egwSLListContains(const egwSinglyLinkedList* list_in, const EGWbyte* data_in, EGWuint findMode_in);

/// Singly Linked List Occurances Routine.
/// Attempts to find the number of occurances of an element in the singly linked list given the provided parameters at O(n) transversal cost (forward search only).
/// @param [in] list_in Singly linked list input structure.
/// @param [in] data_in Element data input buffer to match against.
/// @param [in] findMode_in Element search mode (EGW_FIND_MODE_*).
/// @return Number of element occurances.
EGWuint egwSLListOccurances(const egwSinglyLinkedList* list_in, const EGWbyte* data_in, EGWuint findMode_in);


// !!!: ***** Sorting *****

/// Singly Linked List Sort Routine.
/// Sorts the contents of the singly linked list using the merge sort algorithm at O(n log n) time cost.
/// @note A temporary indexing array is created and used to avoid element swap overhead, rebuilding the list afterwords.
/// @param [in,out] list_inout Singly linked list input/output structure.
void egwSLListSort(egwSinglyLinkedList* list_inout);

// Singly Linked List Resort Routine.
// Attempts to resort the element of the singly linked list at the specified list node at O(n) transversal cost and O(n) time cost.
// @param [in,out] list_inout Singly linked list input/output structure.
// @param [in,out] node_inout List node to which to resort at.
// @param [in] findMode_in Element search mode for re-insertion (EGW_FIND_MODE_*).
// @return 1 if resorting successful, otherwise 0.
//EGWint egwSLListResortElement(egwSinglyLinkedList* list_inout, egwSinglyLinkedListNode* node_inout, EGWuint findMode_in);

// Singly Linked List Resort After Routine.
// Attempts to resort the element of the singly linked list at the list node after specified list node at O(1) transversal cost and O(n) time cost.
// @param [in,out] list_inout Singly linked list input/output structure.
// @param [in,out] node_inout List node to which the element after is to resort at.
// @param [in] findMode_in Element search mode for re-insertion (EGW_FIND_MODE_*).
// @return 1 if resorting successful, otherwise 0.
//EGWint egwSLListResortElementAfter(egwSinglyLinkedList* list_inout, egwSinglyLinkedListNode* node_inout, EGWuint findMode_in);


// !!!: ***** Enumerating *****

/// Singly Linked List Enumerate Start Routine.
/// Attempts to start an enumeration of the singly linked list given the provided iteration mode.
/// @note No mechanism is provided to ensure the data contents are not modified while being enumerated - it is left up to the user to determine what effects should result, if any.
/// @param [in] list_in Singly linked list input structure.
/// @param [in] iterMode_in Iteration mode (EGW_ITERATE_MODE_*).
/// @param [out] iter_out Iterator output structure.
/// @return 1 if enumeration start successful, otherwise 0 if empty or invalid iteration mode.
EGWint egwSLListEnumerateStart(const egwSinglyLinkedList* list_in, EGWuint iterMode_in, egwSinglyLinkedListIter* iter_out);

/// Singly Linked List Enumeration Get Next Routine.
/// Copies the next enumerated element's contents from the singly linked list into the output buffer at O(1) transversal cost and O(1) copy cost.
/// @note This routine does a simple memory copy-over - ownership issues fall to the responsibility of the code using this routine.
/// @param [in,out] iter_inout Iterator input/output structure.
/// @param [out] data_out Element data output buffer (contents copy-over).
/// @return 1 if enumeration of next element successful, otherwise 0 if at end of enumeration.
EGWint egwSLListEnumerateGetNext(egwSinglyLinkedListIter* iter_inout, EGWbyte* data_out);

/// Singly Linked List Enumeration Next Pointer Routine.
/// Returns the next enumerated element's data buffer pointer from the singly linked list at O(1) transversal cost.
/// @param [in,out] iter_inout Iterator input/output structure.
/// @return Element data buffer pointer to the next enumerated element, otherwise NULL if at end of enumeration.
EGWbyte* egwSLListEnumerateNextPtr(egwSinglyLinkedListIter* iter_inout);

/// @}

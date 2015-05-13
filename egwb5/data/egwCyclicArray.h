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

/// @defgroup geWizES_data_cyclicarray egwCyclicArray
/// @ingroup geWizES_data
/// Cyclic Array.
/// @{

/// @file egwCyclicArray.h
/// Cyclic Array Interface.

#import "egwDataTypes.h"


// !!!: ***** Initialization *****

/// Cyclic Array Initialization Routine.
/// Initializes cyclic array with provided parameters.
/// @note Elements are tightly packed without padding.
/// @param [out] array_out Cyclic array output of initialization.
/// @param [in] funcs_in Data routine functions (contents copy-over, may be NULL for default routines).
/// @param [in] elmSize_in Element size (bytes).
/// @param [in] intCap_in Initial capacity (>0).
/// @param [in] flags_in Array attribute flags (EGW_ARRAY_FLG_*).
/// @return @a array_out (for nesting), otherwise NULL if failure initializing.
egwCyclicArray* egwCycArrayInit(egwCyclicArray* array_out, egwDataFuncs* funcs_in, EGWuint elmSize_in, EGWuint intCap_in, EGWuint flags_in);

/// Cyclic Array Copy Routine.
/// Initializes cyclic array from deep copy of another.
/// @param [in] array_in Cyclic array input structure.
/// @param [out] array_out Cyclic array output of copy.
/// @return @a array_out (for nesting), otherwise NULL if failure copying.
egwCyclicArray* egwCycArrayCopy(const egwCyclicArray* array_in, egwCyclicArray* array_out);

/// Cyclic Array Free Routine.
/// Frees the contents of the cyclic array.
/// @param [in,out] array_inout Cyclic array input/output structure.
/// @return @a array_inout (for nesting), otherwise NULL if failure free'ing.
egwCyclicArray* egwCycArrayFree(egwCyclicArray* array_inout);


// !!!: ***** Addition *****

/// Cyclic Array Add At Routine.
/// Adds an element into the cyclic array at the specified index at O(1) insertion cost, moving remaining elements at O(n) swap cost.
/// @note This routine may invoke an array resize if conditions are met for such.
/// @param [in,out] array_inout Cyclic array input/output structure.
/// @param [in] index_in Element index to insert at (zero based starting at head).
/// @param [in] data_in Element data input buffer (contents copy-over, may be NULL for zero'ed data segment).
/// @return 1 if element was successfully added, otherwise 0.
EGWint egwCycArrayAddAt(egwCyclicArray* array_inout, EGWuint index_in, const EGWbyte* data_in);

/// Cyclic Array Add Head Routine.
/// Adds an element into the cyclic array at the head at O(1) insertion cost.
/// @note This routine may invoke an array resize if conditions are met for such.
/// @param [in,out] array_inout Cyclic array input/output structure.
/// @param [in] data_in Element data input buffer (contents copy-over, may be NULL for zero'ed data segment).
/// @return 1 if element was successfully added, otherwise 0.
EGWint egwCycArrayAddHead(egwCyclicArray* array_inout, const EGWbyte* data_in);

/// Cyclic Array Add Tail Routine.
/// Adds an element into the cyclic array at the tail at O(1) insertion cost.
/// @note This routine may invoke an array resize if conditions are met for such.
/// @param [in,out] array_inout Cyclic array input/output structure.
/// @param [in] data_in Element data input buffer (contents copy-over, may be NULL for zero'ed data segment).
/// @return 1 if element was successfully added, otherwise 0.
EGWint egwCycArrayAddTail(egwCyclicArray* array_inout, const EGWbyte* data_in);

// Cyclic Array Add Sorted Routine.
// Adds an element into the cyclic array maintaining sort ordering at O(n) or O(log n) transversal cost and O(1) insertion cost, moving remaining elements at O(n) swap cost.
// @note This routine assume the array contents are already in sorted order.
// @param [in,out] array_inout Cyclic array input/output structure.
// @param [in] data_in Element data input buffer (contents copy-over, may be NULL for zero'ed data segment).
// @param [in] findMode_in Element search mode (EGW_FIND_MODE_*).
// @return 1 if element was successfully added, otherwise 0.
//EGWint egwCycArrayAddSorted(egwCyclicArray* array_inout, const EGWbyte* data_in, EGWuint findMode_in);


// !!!: ***** Removal *****

/// Cyclic Array Remove At Routine.
/// Removes an element from the cyclic array at the specified index at O(1) deletion cost, moving remaining elements at O(n) swap cost.
/// @note This routine may invoke an array resize if conditions are met for such.
/// @param [in,out] array_inout Cyclic array input/output structure.
/// @param [in] index_in Element index to remove at (zero based starting at head).
/// @return 1 if element was successfully removed, otherwise 0.
EGWint egwCycArrayRemoveAt(egwCyclicArray* array_inout, EGWuint index_in);

/// Array Remove Head Routine.
/// Removes the head element from the cyclic array at O(1) deletion cost.
/// @note This routine may invoke an array resize if conditions are met for such.
/// @param [in,out] array_inout Cyclic array input/output structure.
/// @return 1 if element was successfully removed, otherwise 0.
EGWint egwCycArrayRemoveHead(egwCyclicArray* array_inout);

/// Array Remove Tail Routine.
/// Removes the tail element from the cyclic array at O(1) deletion cost.
/// @note This routine may invoke an array resize if conditions are met for such.
/// @param [in,out] array_inout Cyclic array input/output structure.
/// @return 1 if element was successfully removed, otherwise 0.
EGWint egwCycArrayRemoveTail(egwCyclicArray* array_inout);

// Cyclic Array Remove Any Routine.
// Removes any matching element from the cyclic array at O(n) transversal cost and O(1) deletion cost, moving remaining elements at O(n) swap cost.
// @note This routine may invoke an array resize if conditions are met for such.
// @param [in,out] array_inout Cyclic array input/output structure.
// @param [in] data_in Element data input buffer to match against.
// @return Number of elements removed.
//EGWuint egwCycArrayRemoveAny(egwCyclicArray* array_inout, const EGWbyte* data_in);

/// Cyclic Array Remove All Routine.
/// Removes all elements from the cyclic array at O(n) transversal cost (if needed) and O(1) deletion cost.
/// @note This routine may invoke an array resize if conditions are met for such.
/// @param [in,out] array_inout Cyclic array input/output structure.
/// @return 1 if all elements were successfully removed, otherwise 0.
EGWint egwCycArrayRemoveAll(egwCyclicArray* array_inout);


// !!!: ***** Fetching *****

/// Cyclic Array Get Element At Routine.
/// Copies the element contents from the cyclic array at the specified index into the output buffer at O(1) transversal cost and O(1) copy cost.
/// @note This routine does a simple memory copy-over - ownership issues fall to the responsibility of the code using this routine.
/// @param [in] array_in Cyclic array input structure.
/// @param [in] index_in Element index to grab at (zero based starting at head).
/// @param [out] data_out Element data output buffer (contents copy-over).
void egwCycArrayGetElementAt(const egwCyclicArray* array_in, EGWuint index_in, EGWbyte* data_out);

/// Cyclic Array Get Element Head Routine.
/// Copies the head element contents from the cyclic array into the output buffer at O(1) transversal cost and O(1) copy cost.
/// @note This routine does a simple memory copy-over - ownership issues fall to the responsibility of the code using this routine.
/// @param [in] array_in Cyclic array input structure.
/// @param [out] data_out Element data output buffer (contents copy-over).
void egwCycArrayGetElementHead(const egwCyclicArray* array_in, EGWbyte* data_out);

/// Cyclic Array Get Element Tail Routine.
/// Copies the tail element contents from the cyclic array into the output buffer at O(1) transversal cost and O(1) copy cost.
/// @note This routine does a simple memory copy-over - ownership issues fall to the responsibility of the code using this routine.
/// @param [in] array_in Cyclic array input structure.
/// @param [out] data_out Element data output buffer (contents copy-over).
void egwCycArrayGetElementTail(const egwCyclicArray* array_in, EGWbyte* data_out);

/// Cyclic Array Element Pointer At Routine.
/// Returns the element data buffer pointer from the cyclic array at the specified index at O(1) transversal cost.
/// @param [in] array_in Cyclic array input structure.
/// @param [in] index_in Element index to transverse to (zero based starting at head).
/// @return Element data buffer pointer at the specified index, otherwise NULL if bad index.
EGWbyte* egwCycArrayElementPtrAt(const egwCyclicArray* array_in, EGWuint index_in);

/// Cyclic Array Element Head Pointer Routine.
/// Returns the head element data buffer pointer from the cyclic array at O(1) transversal cost.
/// @param [in] array_in Cyclic array input structure.
/// @return Head element data buffer pointer, otherwise NULL if empty.
EGWbyte* egwCycArrayElementPtrHead(const egwCyclicArray* array_in);

/// Cyclic Array Element Tail Pointer Routine.
/// Returns the tail element data buffer pointer from the cyclic array at O(1) transversal cost.
/// @param [in] array_in Cyclic array input structure.
/// @return Tail element data buffer pointer, otherwise NULL if empty.
EGWbyte* egwCycArrayElementPtrTail(const egwCyclicArray* array_in);


// !!!: ***** Searching *****

/// Cyclic Array Find Routine.
/// Attempts to find the index offset of an element in the cyclic array given the provided parameters at O(n) or O(log n) transversal cost.
/// @param [in] array_in Cyclic array input structure.
/// @param [in] data_in Element data input buffer to match against.
/// @param [in] findMode_in Element search mode (EGW_FIND_MODE_*).
/// @return Element index if search successful, -1 otherwise.
EGWint egwCycArrayFind(const egwCyclicArray* array_in, const EGWbyte* data_in, EGWuint findMode_in);

/// Cyclic Array Contains Routine.
/// Attempts to find the existence of an element in the cyclic array given the provided parameters at O(n) or O(log n) transversal cost.
/// @param [in] array_in Cyclic array input structure.
/// @param [in] data_in Element data input buffer to match against.
/// @param [in] findMode_in Element search mode (EGW_FIND_MODE_*).
/// @return 1 if search successful, otherwise 0.
EGWint egwCycArrayContains(const egwCyclicArray* array_in, const EGWbyte* data_in, EGWuint findMode_in);

/// Cyclic Array Occurances Routine.
/// Attempts to find the number of occurances of an element in the cyclic array given the provided parameters at O(n) transversal cost.
/// @param [in] array_in Cyclic array input structure.
/// @param [in] data_in Element data input buffer to match against.
/// @param [in] findMode_in Element search mode (EGW_FIND_MODE_*).
/// @return Number of element occurances.
EGWuint egwCycArrayOccurances(const egwCyclicArray* array_in, const EGWbyte* data_in, EGWuint findMode_in);


// !!!: ***** Resizing *****

/// Cyclic Array Resize Routine.
/// Attempts to resize the cyclic array to the new capacity, copying over existing elements into new data partition.
/// @param [in,out] array_inout Cyclic array input/output structure.
/// @param [in] newCap_in New element capacity.
/// @return 1 if resize successful, otherwise 0.
EGWint egwCycArrayResize(egwCyclicArray* array_inout, EGWuint newCap_in);

/// Cyclic Array Grow Check Routine.
/// Checks to see if the current element count of the cyclic array warrants growth of the maximum array size in accordance to the cyclic array's attribute flags.
/// @param [in] array_in Cyclic array input structure.
/// @return 1 if size should be grown, otherwise 0.
EGWint egwCycArrayGrowChk(const egwCyclicArray* array_in);

/// Cyclic Array Shrink Check Routine.
/// Checks to see if the current element count of the cyclic array warrants shrinkage of the maximum array size in accordance to the cyclic array's attribute flags.
/// @param [in] array_in Cyclic array input structure.
/// @return 1 if size should be shrunk, otherwise 0.
EGWint egwCycArrayShrinkChk(const egwCyclicArray* array_in);

/// Cyclic Array Grow Routine.
/// Wraps the cyclic array resize routine to grow the cyclic array in accordance to the cyclic array's attribute flags.
/// @param [in,out] array_inout Cyclic array input/output structure.
/// @return 1 if resize successful, otherwise 0.
EGWint egwCycArrayGrow(egwCyclicArray* array_inout);

/// Cyclic Array Shrink Routine.
/// Wraps the cyclic array resize routine to shrink the cyclic array in accordance to the cyclic array's attribute flags.
/// @param [in,out] array_inout Cyclic array input/output structure.
/// @return 1 if resize successful, otherwise 0.
EGWint egwCycArrayShrink(egwCyclicArray* array_inout);


// !!!: ***** Sorting *****

/// Cyclic Array Sort Routine.
/// Sorts the contents of the cyclic array using the quick sort algorithm at O(n log n) swap cost.
/// @param [in,out] array_inout Cyclic array input/output structure.
/// @return 1 if sorting successful, otherwise 0 (if temporary storage did not allocate).
EGWint egwCycArraySort(egwCyclicArray* array_inout);

// Cyclic Array Resort Routine.
// Attempts to resort the element of the array at the specified index using a binary search at O(log n) time cost, moving remaining elements at O(n) swap cost.
// @param [in,out] array_inout Cyclic array input/output structure.
// @param [in] index_in Element index to resort at (zero based starting at head).
// @return 1 if resorting successful, otherwise 0.
//EGWint egwCycArrayResortElementAt(egwCyclicArray* array_inout, EGWint index_in);


// !!!: ***** Enumerating *****

/// Cyclic Array Enumerate Start Routine.
/// Attempts to start an enumeration of the cyclic array given the provided iteration mode.
/// @note No mechanism is provided to ensure the data contents are not modified while being enumerated - it is left up to the user to determine what effects should result, if any.
/// @param [in] array_in Cyclic array input structure.
/// @param [in] iterMode_in Iteration mode (EGW_ITERATE_MODE_*).
/// @param [out] iter_out Iterator output structure.
/// @return 1 if enumeration start successful, otherwise 0 if empty or invalid iteration mode.
EGWint egwCycArrayEnumerateStart(const egwCyclicArray* array_in, EGWuint iterMode_in, egwCyclicArrayIter* iter_out);

/// Cyclic Array Enumeration Get Next Routine.
/// Copies the next enumerated element's contents from the cyclic array into the output buffer at O(1) transversal cost and O(1) copy cost.
/// @note This routine does a simple memory copy-over - ownership issues fall to the responsibility of the code using this routine.
/// @param [in,out] iter_inout Iterator input/output structure.
/// @param [out] data_out Element data output buffer (contents copy-over).
/// @return 1 if enumeration of next element successful, otherwise 0 if at end of enumeration.
EGWint egwCycArrayEnumerateGetNext(egwCyclicArrayIter* iter_inout, EGWbyte* data_out);

/// Cyclic Array Enumeration Next Pointer Routine.
/// Returns the next enumerated element's data buffer pointer from the cyclic array at O(1) transversal cost.
/// @param [in,out] iter_inout Iterator input/output structure.
/// @return Element data buffer pointer to the next enumerated element, otherwise NULL if at end of enumeration.
EGWbyte* egwCycArrayEnumerateNextPtr(egwCyclicArrayIter* iter_inout);

/// @}

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

/// @defgroup geWizES_data_types egwDataTypes
/// @ingroup geWizES_data
/// Data Types.
/// @{

/// @file egwDataTypes.h
/// Data Types.

#import "../inf/egwTypes.h"


// !!!: ***** Defines *****

#define EGW_ARRAY_FLG_NONE          0x0000  ///< No array flags.
#define EGW_ARRAY_FLG_DFLT        0x420481  ///< Default array flags.
#define EGW_ARRAY_FLG_GROWBY2X      0x0001  ///< Grow array by 2x when grow condition met.
#define EGW_ARRAY_FLG_GROWBY3X      0x0002  ///< Grow array by 3x when grow condition met.
#define EGW_ARRAY_FLG_GROWBY10      0x0004  ///< Grow array by 10 when grow condition met.
#define EGW_ARRAY_FLG_GROWBY25      0x0008  ///< Grow array by 25 when grow condition met.
#define EGW_ARRAY_FLG_GROWBYSQRD    0x0010  ///< Grow array by x^2 when grow condition met.
#define EGW_ARRAY_FLG_GRWCND100     0x0020  ///< Grow array if array is full (before add).
#define EGW_ARRAY_FLG_GRWCND90      0x0040  ///< Grow array if array is 9/10 full (before add).
#define EGW_ARRAY_FLG_GRWCND75      0x0080  ///< Grow array if array is 3/4 full (before add).
#define EGW_ARRAY_FLG_GRWCND66      0x0100  ///< Grow array if array is 2/3 full (before add).
#define EGW_ARRAY_FLG_GRWCND50      0x0200  ///< Grow array if array is 1/2 full (before add).
#define EGW_ARRAY_FLG_SHRNKBY2X     0x0400  ///< Shrink array by 1/2x when shrink conditions met.
#define EGW_ARRAY_FLG_SHRNKBY3X     0x0800  ///< Shrink array by 1/3x when shrink conditions met.
#define EGW_ARRAY_FLG_SHRNKBY10     0x1000  ///< Shrink array by 10 when shrink conditions met.
#define EGW_ARRAY_FLG_SHRNKBY25     0x2000  ///< Shrink array by 25 when shrink conditions met.
#define EGW_ARRAY_FLG_SHRNKBYSQRT   0x4000  ///< Shrink array by x^-2 when shrink conditions met.
#define EGW_ARRAY_FLG_SHRKCND00     0x8000  ///< Shrink array if array is empty (after remove).
#define EGW_ARRAY_FLG_SHRKCND10    0x10000  ///< Shrink array if array is 1/10 full (after remove).
#define EGW_ARRAY_FLG_SHRKCND25    0x20000  ///< Shrink array if array is 1/4 full (after remove).
#define EGW_ARRAY_FLG_SHRKCND33    0x40000  ///< Shrink array if array is 1/3 full (after remove).
#define EGW_ARRAY_FLG_SHRKCND50    0x80000  ///< Shrink array if array is 1/2 full (after remove).
#define EGW_ARRAY_FLG_RETAIN      0x100000  ///< Treat data element as pointer and auto-retain/auto-release on add/remove, via [ptr retain/release]. Note this only affects the first sizeof(void*) bytes.
#define EGW_ARRAY_FLG_FREE        0x200000  ///< Treat data element as pointer and auto-free on remove, via free(ptr) (not dFuncs->fpFree). Note this only affects the first sizeof(void*) bytes.
#define EGW_ARRAY_FLG_USEMIN      0x400000  ///< Do not allow array to shrink beyond the minimum size.
#define EGW_ARRAY_FLG_EXGROWBY      0x001f  ///< Used to extract grow by usage from bitfield.
#define EGW_ARRAY_FLG_EXGROWCND     0x03e0  ///< Used to extract grow condition from bitfield.
#define EGW_ARRAY_FLG_EXSHRNKBY     0x7c00  ///< Used to extract shrink by usage from bitfield.
#define EGW_ARRAY_FLG_EXSHRNKCND   0xf8000  ///< Used to extract shrink condition from bitfield.

#define EGW_LIST_FLG_NONE           0x0000  ///< No list flags.
#define EGW_LIST_FLG_DFLT           0x0000  ///< Default list flags.
#define EGW_LIST_FLG_RETAIN         0x4000  ///< Treat data element as pointer and auto-retain/auto-release on add/remove, via [ptr retain/release]. Note this only affects the first sizeof(void*) bytes.
#define EGW_LIST_FLG_FREE           0x8000  ///< Treat data element as pointer and auto-free on remove, via free(ptr) (not dFuncs->fpFree). Note this only affects the first sizeof(void*) bytes.

#define EGW_TREE_FLG_NONE           0x0000  ///< No tree flags.
#define EGW_TREE_FLG_DFLT           0x0000  ///< Default tree flags.
#define EGW_TREE_FLG_RETAIN         0x4000  ///< Treat data element as pointer and auto-retain/auto-release on add/remove, via [ptr retain/release]. Note this only affects the first sizeof(void*) bytes.
#define EGW_TREE_FLG_FREE           0x8000  ///< Treat data element as pointer and auto-free on remove, via free(ptr) (not dFuncs->fpFree). Note this only affects the first sizeof(void*) bytes.

#define EGW_FIND_MODE_DFLT          0x0001  ///< Default find mode flags.
#define EGW_FIND_MODE_LINHTT        0x0001  ///< Head-to-tail (i.e. left-to-right) linear search (arrays, lists only).
#define EGW_FIND_MODE_LINTTH        0x0002  ///< Tail-to-head (i.e. right-to-left) linear search (arrays, lists only).
#define EGW_FIND_MODE_BINARY        0x0014  ///< Binary search (sorted arrays only).
#define EGW_FIND_MODE_ISSORTED      0x0010  ///< Treat element data as sorted (invokes early kick-out).
#define EGW_FIND_MODE_EXMETHOD      0x000f  ///< Used to extract method usage from bitfield.

#define EGW_ITERATE_MODE_DFLT       0x0005  ///< Default iterate mode flags.
#define EGW_ITERATE_MODE_LINHTT     0x0001  ///< Head-to-tail (i.e. left-to-right) linear transversal (arrays, lists only).
#define EGW_ITERATE_MODE_LINTTH     0x0002  ///< Tail-to-head (i.e. right-to-left) linear transversal (arrays, lists only).
#define EGW_ITERATE_MODE_BSTLSR     0x0004  ///< Left-self-right (i.e. in-order) BST transversal (binary trees only).
#define EGW_ITERATE_MODE_BSTLRS     0x0008  ///< Left-right-self (i.e. post-order) BST transversal (binary trees only).
#define EGW_ITERATE_MODE_BSTSLR     0x0010  ///< Self-left-right (i.e. pre-order) BST transversal (binary trees only).
#define EGW_ITERATE_MODE_BSTSRL     0x0020  ///< Self-right-left (i.e. reversed pre-order) BST transversal (binary trees only).
#define EGW_ITERATE_MODE_BSTRLS     0x0040  ///< Right-left-self (i.e. reversed post-order) BST transversal (binary trees only).
#define EGW_ITERATE_MODE_BSTRSL     0x0080  ///< Right-self-left (i.e. reversed in-order) BST transversal (binary trees only).
#define EGW_ITERATE_MODE_BSTLO      0x0100  ///< Level-order BST transversal (binary trees only). Note that level-order iteration mode allocates a temporary storage array in the iterator structure that must be manually free'd if iteration is not allowed to finished.
#define EGW_ITERATE_MODE_EXLIN      0x0003  ///< Used to extract linear transversal usage from bitfield.
#define EGW_ITERATE_MODE_EXBST      0x01fc  ///< Used to extract BST transversal usage from bitfield.


// !!!: ***** Data Structures *****

/// Comparator function pointer typedef.
/// @note Should return 0 if equal, positive if first arg is considered before/lesser-than second arg, or negative if first arg is considered after/greater-than second arg.
typedef EGWint (*EGWcomparefp)(const EGWbyte*,  const EGWbyte*, size_t size);

/// Element operator function pointer typedef.
typedef void (*EGWelementfp)(EGWbyte*);

/// Memory allocation function pointer typedef.
typedef void* (*EGWmallocfp)(size_t);

/// Memory deallocation function pointer typedef.
typedef void (*EGWfreefp)(void*);

/// Data Functions.
/// Collection of data function pointers.
typedef struct {
    EGWmallocfp  fpMalloc;                  ///< Memory allocation function. If NULL defaults to malloc().
    EGWfreefp    fpFree;                    ///< Memory deallocation function. If NULL defaults to free(). Note that pointer passed is pointer to node header, if such exists.
    EGWcomparefp fpCompare;                 ///< Compare element function. If NULL defaults to memcmp().
    EGWelementfp fpAdd;                     ///< Post-add element function. Default is NULL.
    EGWelementfp fpRemove;                  ///< Pre-remove element function. Default is NULL.
} egwDataFuncs;

/// 1-D Array.
/// One dimensional array structure.
typedef struct {
    EGWbyte* rData;                         ///< Raw array data (owned).
    egwDataFuncs* dFuncs;                   ///< Data functions (owned).
    EGWuint32 aFlags;                       ///< Array flags.
    EGWuint16 eSize;                        ///< Element size (bytes).
    EGWuint16 eCount;                       ///< Current element count.
    EGWuint16 eMinCount;                    ///< Minimum element count.
    EGWuint16 eMaxCount;                    ///< Maximum element count.
} egwArray;

/// 1-D Array Iterator.
/// Iterator container structure.
typedef struct {
    const egwArray* pArray;                 ///< Parent array (weak).
    EGWbyte* nPos;                          ///< Next position pointer.
    EGWuint16 iMode;                        ///< Iterator mode.
    EGWuint16 eIndex;                       ///< Current element index. Note that this represents the index based upon the iteration mode, not of the underlying structure.
} egwArrayIter;

/// 1-D Cyclic Array.
/// One dimensional cyclic array structure.
typedef struct {
    EGWbyte* rData;                         ///< Raw array data (owned).
    egwDataFuncs* dFuncs;                   ///< Data functions (owned).
    EGWuint32 aFlags;                       ///< Array flags.
    EGWuint16 eSize;                        ///< Element size (bytes).
    EGWuint16 eCount;                       ///< Current element count.
    EGWuint16 eMinCount;                    ///< Minimum element count.
    EGWuint16 eMaxCount;                    ///< Maximum element count.
    EGWuint16 pOffset;                      ///< Head offset position.
} egwCyclicArray;

/// 1-D Cyclic Array Iterator.
/// Iterator container structure.
typedef struct {
    const egwCyclicArray* pArray;           ///< Parent array (weak).
    EGWbyte* nPos;                          ///< Next position pointer.
    EGWuint16 iMode;                        ///< Iterator mode.
    EGWuint16 eIndex;                       ///< Current element index. Note that this represents the index based upon the iteration mode, not of the underlying structure.
} egwCyclicArrayIter;

/// Singly-Linked List Node.
/// Singly-linked list node header structure.
/// @note This header is included automatically when allocating nodes (sizeof() is explicitly appended by eSize), and is what is pointed to by node linkage, deallocations, etc..
typedef struct egwSinglyLinkedListNode {
    struct egwSinglyLinkedListNode* next;   ///< Next element pointer (strong).
} egwSinglyLinkedListNode;

/// Singly-Linked List.
/// One dimensional singly-linked list structure.
typedef struct {
    egwSinglyLinkedListNode* lHead;         ///< List head node (owned).
    egwSinglyLinkedListNode* lTail;         ///< List tail node (owned).
    egwDataFuncs* dFuncs;                   ///< Data functions (owned).
    EGWuint32 lFlags;                       ///< List flags.
    EGWuint16 eSize;                        ///< Element size (bytes).
    EGWuint16 eCount;                       ///< Current element count.
} egwSinglyLinkedList;

/// Singly-Linked List Iterator.
/// Iterator container structure.
typedef struct {
    const egwSinglyLinkedList* pList;       ///< Parent list (weak).
    egwSinglyLinkedListNode* nPos;          ///< Next position pointer.
    EGWuint16 iMode;                        ///< Iterator mode.
    EGWuint16 eIndex;                       ///< Current element index. Note that this represents the index based upon the iteration mode, not of the underlying structure.
} egwSinglyLinkedListIter;

/// Doubly-Linked List Node.
/// Doubly-linked list node header structure.
/// @note This header is included automatically when allocating nodes (sizeof() is explicitly appended by eSize), and is what is pointed to by node linkage, deallocations, etc..
typedef struct egwDoublyLinkedListNode {
    struct egwDoublyLinkedListNode* prev;   ///< Previous element pointer (strong).
    struct egwDoublyLinkedListNode* next;   ///< Next element pointer (strong).
} egwDoublyLinkedListNode;

/// Doubly-Linked List.
/// One dimensional singly-linked list structure.
typedef struct {
    egwDoublyLinkedListNode* lHead;         ///< List head node (owned).
    egwDoublyLinkedListNode* lTail;         ///< List tail node (owned).
    egwDataFuncs* dFuncs;                   ///< Data functions (owned).
    EGWuint32 lFlags;                       ///< List flags.
    EGWuint16 eSize;                        ///< Element size (bytes).
    EGWuint16 eCount;                       ///< Current element count.
} egwDoublyLinkedList;

/// Doubly-Linked List Iterator.
/// Iterator container structure.
typedef struct {
    const egwDoublyLinkedList* pList;       ///< Parent list (weak).
    egwDoublyLinkedListNode* nPos;          ///< Next position pointer.
    EGWuint16 iMode;                        ///< Iterator mode.
    EGWuint16 eIndex;                       ///< Current element index. Note that this represents the index based upon the iteration mode, not of the underlying structure.
} egwDoublyLinkedListIter;

/// AVL Tree Node.
/// AVL tree node header structure.
/// @note This header is included automatically when allocating nodes (sizeof() is explicitly appended by eSize), and is what is pointed to by node linkage, deallocations, etc..
typedef struct egwAVLTreeNode {
    struct egwAVLTreeNode* parent;          ///< Parent element node (strong).
    struct egwAVLTreeNode* left;            ///< Left element child node (strong).
    struct egwAVLTreeNode* right;           ///< Right element child node (strong).
    EGWint16 nBalance;                      ///< Node balance.
    EGWint16 stHeight;                      ///< Subtree height.
} egwAVLTreeNode;

/// AVL Tree.
/// AVL tree structure.
typedef struct {
    egwAVLTreeNode* tRoot;                  ///< Tree root node (owned).
    egwDataFuncs* dFuncs;                   ///< Data functions (owned).
    EGWuint32 tFlags;                       ///< Tree flags.
    EGWuint16 eSize;                        ///< Element size (bytes).
    EGWuint16 eCount;                       ///< Current element count.
} egwAVLTree;

/// AVL Tree Iterator.
/// Iterator container structure.
typedef struct {
    const egwAVLTree* pTree;                ///< Parent tree (weak).
    egwAVLTreeNode* nPos;                   ///< Next position pointer.
    EGWuint16 iMode;                        ///< Iterator mode.
    EGWuint16 eIndex;                       ///< Current element index. Note that this represents the index based upon the iteration mode, not of the underlying structure.
    egwCyclicArray* lotElms;                ///< Level-order transversal element array (owned). Note that level-order iteration mode allocates this as a temporary storage array that must be manually free'd if iteration is not allowed to finished.
} egwAVLTreeIter;

/// Red-Black Tree Node.
/// Red-black tree node header structure.
/// @note This header is included automatically when allocating nodes (sizeof() is explicitly appended by eSize), and is what is pointed to by node linkage, deallocations, etc..
typedef struct egwRedBlackTreeNode {
    struct egwRedBlackTreeNode* parent;     ///< Parent element node (strong).
    struct egwRedBlackTreeNode* left;       ///< Left element child node (strong).
    struct egwRedBlackTreeNode* right;      ///< Right element child node (strong).
    EGWuint nFlags;                         ///< Node flags.
} egwRedBlackTreeNode;

/// Red-Black Tree.
/// Red-black tree structure.
typedef struct {
    egwRedBlackTreeNode* tRoot;             ///< Tree root node (owned).
    egwDataFuncs* dFuncs;                   ///< Data functions (owned).
    EGWuint32 tFlags;                       ///< Tree flags.
    EGWuint16 eSize;                        ///< Element size (bytes).
    EGWuint16 eCount;                       ///< Current element count.
} egwRedBlackTree;

/// Red-Black Tree Iterator.
/// Iterator container structure.
typedef struct {
    const egwRedBlackTree* pTree;           ///< Parent tree (weak).
    egwRedBlackTreeNode* nPos;              ///< Next position pointer.
    EGWuint16 iMode;                        ///< Iterator mode.
    EGWuint16 eIndex;                       ///< Current element index. Note that this represents the index based upon the iteration mode, not of the underlying structure.
    egwCyclicArray* lotElms;                ///< Level-order transversal element array (owned). Note that level-order iteration mode allocates this as a temporary storage array that must be manually free'd if iteration is not allowed to finished.
} egwRedBlackTreeIter;

/// @}

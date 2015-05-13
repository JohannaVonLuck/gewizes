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
#define EGW_ARRAY_FLG_DFLT          0x10a1  ///< Default array flags.
#define EGW_ARRAY_FLG_GROWBY2X      0x0001  ///< Grow array by 2x when grow condition met.
#define EGW_ARRAY_FLG_GROWBY3X      0x0002  ///< Grow array by 3x when grow condition met.
#define EGW_ARRAY_FLG_GROWBY10      0x0004  ///< Grow array by 10 when grow condition met.
#define EGW_ARRAY_FLG_GROWBY25      0x0008  ///< Grow array by 25 when grow condition met.
#define EGW_ARRAY_FLG_GRWCND100     0x0010  ///< Grow array if array is full (before add).
#define EGW_ARRAY_FLG_GRWCND75      0x0020  ///< Grow array if array is 3/4 full (before add).
#define EGW_ARRAY_FLG_GRWCND66      0x0040  ///< Grow array if array is 2/3 full (before add).
#define EGW_ARRAY_FLG_SHRNKBY2X     0x0080  ///< Shrink array by 1/2x when shrink conditions met.
#define EGW_ARRAY_FLG_SHRNKBY3X     0x0100  ///< Shrink array by 1/3x when shrink conditions met.
#define EGW_ARRAY_FLG_SHRNKBY10     0x0200  ///< Shrink array by 10 when shrink conditions met.
#define EGW_ARRAY_FLG_SHRNKBY25     0x0400  ///< Shrink array by 25 when shrink conditions met.
#define EGW_ARRAY_FLG_SHRKCND00     0x0800  ///< Shrink array if array is empty (after remove).
#define EGW_ARRAY_FLG_SHRKCND25     0x1000  ///< Shrink array if array is 1/4 full (after remove).
#define EGW_ARRAY_FLG_SHRKCND33     0x2000  ///< Shrink array if array is 1/3 full (after remove).
#define EGW_ARRAY_FLG_RETAIN        0x4000  ///< Treat data element as pointer and auto-retain/auto-release on add/remove, via [ptr retain/release]. Note this only affects the first sizeof(void*) bytes.
#define EGW_ARRAY_FLG_FREE          0x8000  ///< Treat data element as pointer and auto-free on remove, via free(ptr) (not dFuncs->fpFree). Note this only affects the first sizeof(void*) bytes.
#define EGW_ARRAY_FLG_EXGROWBY      0x000f  ///< Used to extract grow by usage from bitfield.
#define EGW_ARRAY_FLG_EXGROWCND     0x0070  ///< Used to extract grow condition from bitfield.
#define EGW_ARRAY_FLG_EXSHRNKBY     0x0780  ///< Used to extract shrink by usage from bitfield.
#define EGW_ARRAY_FLG_EXSHRNKCND    0x3800  ///< Used to extract shrink condition from bitfield.

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
#define EGW_ITERATE_MODE_BSTLSR     0x0004  ///< Left-self-right (i.e. inorder) BST transversal (binary trees only).
#define EGW_ITERATE_MODE_BSTLRS     0x0008  ///< Left-right-self (i.e. postorder) BST transversal (binary trees only).
#define EGW_ITERATE_MODE_BSTSLR     0x0010  ///< Self-left-right (i.e. preorder) BST transversal (binary trees only).
#define EGW_ITERATE_MODE_BSTSRL     0x0020  ///< Self-right-left (i.e. reversed preorder) BST transversal (binary trees only).
#define EGW_ITERATE_MODE_BSTRLS     0x0040  ///< Right-left-self (i.e. reversed postorder) BST transversal (binary trees only).
#define EGW_ITERATE_MODE_BSTRSL     0x0080  ///< Right-self-left (i.e. reversed inorder) BST transversal (binary trees only).
#define EGW_ITERATE_MODE_EXLIN      0x0003  ///< Used to extract linear transversal usage from bitfield.
#define EGW_ITERATE_MODE_EXBST      0x00fc  ///< Used to extract BST transversal usage from bitfield.


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
    EGWuint32 tFlags;                       ///< Tree flags.
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
    EGWuint32 tFlags;                       ///< Tree flags.
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

/// Binary Tree Node.
/// Binary tree node header structure.
/// @note This header is included automatically when allocating nodes (sizeof() is explicitly appended by eSize), and is what is pointed to by node linkage, deallocations, etc..
typedef struct egwBinaryTreeNode {
    struct egwBinaryTreeNode* parent;       ///< Parent element node (strong).
    struct egwBinaryTreeNode* left;         ///< Left element child node (strong).
    struct egwBinaryTreeNode* right;        ///< Right element child node (strong).
} egwBinaryTreeNode;

/// Binary Tree.
/// Binary tree structure.
typedef struct {
    egwBinaryTreeNode* tRoot;               ///< Tree root node (owned).
    egwDataFuncs* dFuncs;                   ///< Data functions (owned).
    EGWuint32 tFlags;                       ///< Tree flags.
    EGWuint16 eSize;                        ///< Element size (bytes).
    EGWuint16 eCount;                       ///< Current element count.
} egwBinaryTree;

/// Binary Tree Iterator.
/// Iterator container structure.
typedef struct {
    const egwBinaryTree* pTree;             ///< Parent tree (weak).
    egwBinaryTreeNode* nPos;                ///< Next position pointer.
    EGWuint16 iMode;                        ///< Iterator mode.
    EGWuint16 eIndex;                       ///< Current element index. Note that this represents the index based upon the iteration mode, not of the underlying structure.
} egwBinaryTreeIter;

/// AVL Tree Node.
/// AVL tree node header structure.
/// @note This header is included automatically when allocating nodes (sizeof() is explicitly appended by eSize), and is what is pointed to by node linkage, deallocations, etc..
typedef struct egwAVLTreeNode {
    struct egwAVLTreeNode* parent;          ///< Parent element node (strong).
    struct egwAVLTreeNode* left;            ///< Left element child node (strong).
    struct egwAVLTreeNode* right;           ///< Right element child node (strong).
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
} egwRedBlackTreeIter;

/// @}

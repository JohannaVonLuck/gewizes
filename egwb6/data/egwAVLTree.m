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

/// @file egwAVLTree.m
/// @ingroup geWizES_data_avltree
/// Height-Blanaced AVL Tree Implementation.

#import <string.h>
#import "egwAVLTree.h"
#import "../data/egwCyclicArray.h"
#import "../math/egwMath.h"

static void egwAVLTreeCopyRecurse(egwAVLTree* tree_inout, EGWmallocfp mallocFunc, EGWelementfp addFunc, egwAVLTreeNode* nodeSrc_inout, egwAVLTreeNode* nodeDst_inout) {
    if(tree_inout->tRoot && nodeSrc_inout->left) {
        egwAVLTreeNode* newNode = NULL;
        EGWuintptr data = 0;
        
        if(!(newNode = (egwAVLTreeNode*)mallocFunc(((size_t)tree_inout->eSize + (size_t)sizeof(egwAVLTreeNode))))) { egwAVLTreeFree(tree_inout); return; }
        memset((void*)newNode, 0, ((size_t)tree_inout->eSize + (size_t)sizeof(egwAVLTreeNode)));
        
        ++tree_inout->eCount;
        
        nodeDst_inout->left = newNode;
        newNode->parent = nodeDst_inout;
        newNode->nBalance = nodeSrc_inout->left->nBalance;
        newNode->stHeight = nodeSrc_inout->left->stHeight;
        data = (EGWuintptr)newNode + (EGWuintptr)sizeof(egwAVLTreeNode);
        memcpy((void*)data, (const void*)((EGWuintptr)nodeSrc_inout->left + (EGWuintptr)sizeof(egwAVLTreeNode)), (size_t)tree_inout->eSize);
        
        if(tree_inout->tFlags & EGW_TREE_FLG_RETAIN)
            [(id<NSObject>)*(void**)data retain];
        
        if(addFunc)
            addFunc((EGWbyte*)data);
        
        egwAVLTreeCopyRecurse(tree_inout, mallocFunc, addFunc, nodeSrc_inout->left, nodeDst_inout->left);
    }
    
    if(tree_inout->tRoot && nodeSrc_inout->right) {
        egwAVLTreeNode* newNode = NULL;
        EGWuintptr data = 0;
        
        if(!(newNode = (egwAVLTreeNode*)mallocFunc(((size_t)tree_inout->eSize + (size_t)sizeof(egwAVLTreeNode))))) { egwAVLTreeFree(tree_inout); return; }
        memset((void*)newNode, 0, ((size_t)tree_inout->eSize + (size_t)sizeof(egwAVLTreeNode)));
        
        ++tree_inout->eCount;
        
        nodeDst_inout->right = newNode;
        newNode->parent = nodeDst_inout;
        newNode->nBalance = nodeSrc_inout->right->nBalance;
        newNode->stHeight = nodeSrc_inout->right->stHeight;
        data = (EGWuintptr)newNode + (EGWuintptr)sizeof(egwAVLTreeNode);
        memcpy((void*)data, (const void*)((EGWuintptr)nodeSrc_inout->right + (EGWuintptr)sizeof(egwAVLTreeNode)), (size_t)tree_inout->eSize);
        
        if(tree_inout->tFlags & EGW_TREE_FLG_RETAIN)
            [(id<NSObject>)*(void**)data retain];
        
        if(addFunc)
            addFunc((EGWbyte*)data);
        
        egwAVLTreeCopyRecurse(tree_inout, mallocFunc, addFunc, nodeSrc_inout->right, nodeDst_inout->right);
    }
}

static void egwAVLTreeFreeRecurse(egwAVLTree* tree_inout, EGWfreefp freeFunc, egwAVLTreeNode* node_inout) {
    if(node_inout) {
        egwAVLTreeFreeRecurse(tree_inout, freeFunc, node_inout->left);
        egwAVLTreeFreeRecurse(tree_inout, freeFunc, node_inout->right);
        
        if(tree_inout->dFuncs && tree_inout->dFuncs->fpRemove)
            tree_inout->dFuncs->fpRemove((EGWbyte*)((EGWuintptr)node_inout + (EGWuintptr)sizeof(egwAVLTreeNode)));
        if(tree_inout->tFlags & EGW_TREE_FLG_RETAIN)
            [(id<NSObject>)*(void**)((EGWuintptr)node_inout + (EGWuintptr)sizeof(egwAVLTreeNode)) release];
        if(tree_inout->tFlags & EGW_TREE_FLG_FREE)
            free((void*)*(void**)((EGWuintptr)node_inout + (EGWuintptr)sizeof(egwAVLTreeNode)));
        
        freeFunc(node_inout);
    }
}

static void egwAVLTreeSwapNodeInPlace(egwAVLTree* tree_inout, egwAVLTreeNode* nodeA_inout, egwAVLTreeNode* nodeB_inout) {
    if(nodeA_inout->left == nodeB_inout) { // Special case, B is A's left node
        if(nodeA_inout->parent)
            *(nodeA_inout->parent->left == nodeA_inout ? &nodeA_inout->parent->left : &nodeA_inout->parent->right) = nodeB_inout;
        if(nodeA_inout->right) nodeA_inout->right->parent = nodeB_inout;
        if(nodeB_inout->right) nodeB_inout->right->parent = nodeA_inout;
        if(nodeB_inout->left) nodeB_inout->left->parent = nodeA_inout;
        {   register egwAVLTreeNode* tempNode;
            tempNode = nodeB_inout->right;
            nodeB_inout->right = nodeA_inout->right;
            nodeA_inout->right = tempNode;
            tempNode = nodeB_inout->left;
            nodeB_inout->left = nodeA_inout;
            nodeA_inout->left = tempNode;
        }
        nodeB_inout->parent = nodeA_inout->parent;
        nodeA_inout->parent = nodeB_inout;
        
        {   register EGWint16 tempVal;
            tempVal = nodeA_inout->nBalance; nodeA_inout->nBalance = nodeB_inout->nBalance; nodeB_inout->nBalance = tempVal;
            tempVal = nodeA_inout->stHeight; nodeA_inout->stHeight = nodeB_inout->stHeight; nodeB_inout->stHeight = tempVal;
        }
        
        if(!nodeA_inout->parent)
            tree_inout->tRoot = nodeA_inout;
        else if(!nodeB_inout->parent)
            tree_inout->tRoot = nodeB_inout;
    } else if(nodeA_inout->right == nodeB_inout) { // Special case, B is A's right node
        if(nodeA_inout->parent)
            *(nodeA_inout->parent->left == nodeA_inout ? &nodeA_inout->parent->left : &nodeA_inout->parent->right) = nodeB_inout;
        if(nodeA_inout->left) nodeA_inout->left->parent = nodeB_inout;
        if(nodeB_inout->left) nodeB_inout->left->parent = nodeA_inout;
        if(nodeB_inout->right) nodeB_inout->right->parent = nodeA_inout;
        {   register egwAVLTreeNode* tempNode;
            tempNode = nodeB_inout->left;
            nodeB_inout->left = nodeA_inout->left;
            nodeA_inout->left = tempNode;
            tempNode = nodeB_inout->right;
            nodeB_inout->right = nodeA_inout;
            nodeA_inout->right = tempNode;
        }
        nodeB_inout->parent = nodeA_inout->parent;
        nodeA_inout->parent = nodeB_inout;
        
        {   register EGWint16 tempVal;
            tempVal = nodeA_inout->nBalance; nodeA_inout->nBalance = nodeB_inout->nBalance; nodeB_inout->nBalance = tempVal;
            tempVal = nodeA_inout->stHeight; nodeA_inout->stHeight = nodeB_inout->stHeight; nodeB_inout->stHeight = tempVal;
        }
        
        if(!nodeA_inout->parent)
            tree_inout->tRoot = nodeA_inout;
        else if(!nodeB_inout->parent)
            tree_inout->tRoot = nodeB_inout;
    } else if(nodeB_inout->left == nodeA_inout) { // Special case, A is B's left node
        egwAVLTreeSwapNodeInPlace(tree_inout, nodeB_inout, nodeA_inout); // swap to re-use existing imp (less to test/verify)
    } else if(nodeB_inout->right == nodeA_inout) { // Special case, A is B's right node
        egwAVLTreeSwapNodeInPlace(tree_inout, nodeB_inout, nodeA_inout); // swap to re-use existing imp (less to test/verify)
    } else if(nodeA_inout->parent && nodeA_inout->parent == nodeB_inout->parent) { // Special case, A and B are siblings of same parent
        if(nodeA_inout->parent->left == nodeA_inout) {
            nodeB_inout->parent->left = nodeB_inout;
            nodeA_inout->parent->right = nodeA_inout;
            if(nodeA_inout->left) nodeA_inout->left->parent = nodeB_inout;
            if(nodeA_inout->right) nodeA_inout->right->parent = nodeB_inout;
            if(nodeB_inout->left) nodeB_inout->left->parent = nodeA_inout;
            if(nodeB_inout->right) nodeB_inout->right->parent = nodeA_inout;
            {   register egwAVLTreeNode* tempNode;
                tempNode = nodeA_inout->left;
                nodeA_inout->left = nodeB_inout->left;
                nodeB_inout->left = tempNode;
                tempNode = nodeA_inout->right;
                nodeA_inout->right = nodeB_inout->right;
                nodeB_inout->right = tempNode;
            }
            
            {   register EGWint16 tempVal;
                tempVal = nodeA_inout->nBalance; nodeA_inout->nBalance = nodeB_inout->nBalance; nodeB_inout->nBalance = tempVal;
                tempVal = nodeA_inout->stHeight; nodeA_inout->stHeight = nodeB_inout->stHeight; nodeB_inout->stHeight = tempVal;
            }
        } else {
            egwAVLTreeSwapNodeInPlace(tree_inout, nodeB_inout, nodeA_inout); // swap to re-use existing imp (less to test/verify)
        }
    } else { // A and B are not neighbors, safe to do direct swap
        if(nodeA_inout->parent)
            *(nodeA_inout->parent->left == nodeA_inout ? &nodeA_inout->parent->left : &nodeA_inout->parent->right) = nodeB_inout;
        if(nodeA_inout->left) nodeA_inout->left->parent = nodeB_inout;
        if(nodeA_inout->right) nodeA_inout->right->parent = nodeB_inout;
        
        if(nodeB_inout->parent)
            *(nodeB_inout->parent->left == nodeB_inout ? &nodeB_inout->parent->left : &nodeB_inout->parent->right) = nodeA_inout;
        if(nodeB_inout->left) nodeB_inout->left->parent = nodeA_inout;
        if(nodeB_inout->right) nodeB_inout->right->parent = nodeA_inout;
        
        {   register egwAVLTreeNode* tempNode;
            tempNode = nodeA_inout->parent; nodeA_inout->parent = nodeB_inout->parent; nodeB_inout->parent = tempNode;
            tempNode = nodeA_inout->left; nodeA_inout->left = nodeB_inout->left; nodeB_inout->left = tempNode;
            tempNode = nodeA_inout->right; nodeA_inout->right = nodeB_inout->right; nodeB_inout->right = tempNode;
        }
        
        {   register EGWint16 tempVal;
            tempVal = nodeA_inout->nBalance; nodeA_inout->nBalance = nodeB_inout->nBalance; nodeB_inout->nBalance = tempVal;
            tempVal = nodeA_inout->stHeight; nodeA_inout->stHeight = nodeB_inout->stHeight; nodeB_inout->stHeight = tempVal;
        }
        
        if(!nodeA_inout->parent)
            tree_inout->tRoot = nodeA_inout;
        else if(!nodeB_inout->parent)
            tree_inout->tRoot = nodeB_inout;
    }
}

static const egwAVLTreeNode* egwAVLTreeInorderPredecessor(const egwAVLTreeNode* node_in) {
    if(node_in->left) {
        node_in = node_in->left;
        
        while(node_in->right)
            node_in = node_in->right;
    } else {
        const egwAVLTreeNode* node;
        
        do {
            node = node_in;
            node_in = node_in->parent;
        } while(node_in && node_in->right != node);
    }
    
    return node_in;
}

static const egwAVLTreeNode* egwAVLTreeInorderSuccessor(const egwAVLTreeNode* node_in) {
    if(node_in->right) {
        node_in = node_in->right;
        
        while(node_in->left)
            node_in = node_in->left;
    } else {
        const egwAVLTreeNode* node;
        
        do {
            node = node_in;
            node_in = node_in->parent;
        } while(node_in && node_in->left != node);
    }
    
    return node_in;
}

static void egwAVLTreeRotateLeft(egwAVLTree* tree_inout, egwAVLTreeNode* node_inout) {
    register egwAVLTreeNode* rightNode = node_inout->right;
    
    if(rightNode) {
        {   register egwAVLTreeNode* parentNode = node_inout->parent;
            
            if(parentNode) {
                if(node_inout == parentNode->left)
                    parentNode->left = rightNode;
                else
                    parentNode->right = rightNode;
            } else
                tree_inout->tRoot = rightNode;
            rightNode->parent = parentNode;
        }
        
        node_inout->right = rightNode->left;
        if(rightNode->left)
            rightNode->left->parent = node_inout;
        rightNode->left = node_inout;
        node_inout->parent = rightNode;
    }
}

static void egwAVLTreeRotateRight(egwAVLTree* tree_inout, egwAVLTreeNode* node_inout) {
    register egwAVLTreeNode* leftNode = node_inout->left;
    
    if(leftNode) {
        {   register egwAVLTreeNode* parentNode = node_inout->parent;
            
            if(parentNode) {
                if(node_inout == parentNode->left)
                    parentNode->left = leftNode;
                else
                    parentNode->right = leftNode;
            } else
                tree_inout->tRoot = leftNode;
            leftNode->parent = parentNode;
        }
        
        node_inout->left = leftNode->right;
        if(leftNode->right)
            leftNode->right->parent = node_inout;
        leftNode->right = node_inout;
        node_inout->parent = leftNode;
    }
}

static inline void egwAVLTreeRecalcBalances(egwAVLTreeNode* node_inout) {
    node_inout->stHeight = egwMax2i16((node_inout->left ? node_inout->left->stHeight : -1), (node_inout->right ? node_inout->right->stHeight : -1)) + 1;
    node_inout->nBalance = (node_inout->left ? node_inout->left->stHeight : -1) - (node_inout->right ? node_inout->right->stHeight : -1);
}

static void egwAVLTreeFixUp(egwAVLTree* tree_inout, egwAVLTreeNode* node_inout) {
    while(node_inout) {
        egwAVLTreeRecalcBalances(node_inout);
        
        if(node_inout->nBalance <= -2) {
            register egwAVLTreeNode* rightNode = node_inout->right;
            
            if(rightNode->nBalance <= -1) {
                egwAVLTreeRotateLeft(tree_inout, rightNode);
                
                egwAVLTreeRecalcBalances(node_inout);
            } else if(rightNode->nBalance >= 1) {
                egwAVLTreeRotateRight(tree_inout, rightNode);
                egwAVLTreeRotateLeft(tree_inout, node_inout);
                
                egwAVLTreeRecalcBalances(node_inout);
                egwAVLTreeRecalcBalances(rightNode);
            }
        } else if(node_inout->nBalance >= 2) {
            register egwAVLTreeNode* leftNode = node_inout->left;
            
            if(leftNode->nBalance >= 1) {
                egwAVLTreeRotateRight(tree_inout, leftNode);
                
                egwAVLTreeRecalcBalances(node_inout);
            } else if(leftNode->nBalance <= -1) {
                egwAVLTreeRotateLeft(tree_inout, leftNode);
                egwAVLTreeRotateRight(tree_inout, node_inout);
                
                egwAVLTreeRecalcBalances(node_inout);
                egwAVLTreeRecalcBalances(leftNode);
            }
        }
        
        node_inout = node_inout->parent;
    }
}

static EGWuint egwAVLTreeOccurancesRecurse(const egwAVLTree* tree_in, egwAVLTreeNode* node_in, const EGWbyte* data_in) {
    if(node_in) {
        EGWint cmpValue;
        {   EGWcomparefp compareFunc = (tree_in->dFuncs && tree_in->dFuncs->fpCompare ? (EGWcomparefp)(tree_in->dFuncs->fpCompare) : (EGWcomparefp)&memcmp);
            cmpValue = compareFunc((EGWbyte*)((EGWuintptr)node_in + (EGWuintptr)sizeof(egwAVLTreeNode)), data_in, tree_in->eSize);
        }
        
        return (0 == cmpValue ? 1 : 0) +
        (cmpValue >= 0 ? egwAVLTreeOccurancesRecurse(tree_in, node_in->left, data_in) : 0) +
        (cmpValue <= 0 ? egwAVLTreeOccurancesRecurse(tree_in, node_in->right, data_in) : 0);
    }
    
    return 0;
}

egwAVLTree* egwAVLTreeInit(egwAVLTree* tree_out, egwDataFuncs* funcs_in, EGWuint elmSize_in, EGWuint flags_in) {
    memset((void*)tree_out, 0, sizeof(egwAVLTree));
    
    tree_out->tFlags = (EGWuint16)flags_in;
    tree_out->eSize = (EGWuint16)elmSize_in;
    
    if(funcs_in) {
        if(!(tree_out->dFuncs = (egwDataFuncs*)malloc(sizeof(egwDataFuncs)))) { egwAVLTreeFree(tree_out); return NULL; }
        memcpy((void*)tree_out->dFuncs, (const void*)funcs_in, sizeof(egwDataFuncs));
    }
    
    return tree_out;
}

egwAVLTree* egwAVLTreeCopy(const egwAVLTree* tree_in, egwAVLTree* tree_out) {
    memset((void*)tree_out, 0, sizeof(egwAVLTree));
    
    tree_out->tFlags = tree_in->tFlags;
    tree_out->eSize = tree_in->eSize;
    
    if(tree_in->dFuncs) {
        if(!(tree_out->dFuncs = (egwDataFuncs*)malloc(sizeof(egwDataFuncs)))) { egwAVLTreeFree(tree_out); return NULL; }
        memcpy((void*)tree_out->dFuncs, (const void*)tree_in->dFuncs, sizeof(egwDataFuncs));
    }
    
    if(tree_in->eCount) {
        // Have to create the root node first before the recursive call to copy
        EGWmallocfp mallocFunc = (tree_out->dFuncs && tree_out->dFuncs->fpMalloc ? (EGWmallocfp)tree_out->dFuncs->fpMalloc : (EGWmallocfp)&malloc);
        EGWelementfp addFunc = (tree_out->dFuncs && tree_out->dFuncs->fpAdd ? (EGWelementfp)tree_out->dFuncs->fpAdd : (EGWelementfp)NULL);
        egwAVLTreeNode* newNode = NULL;
        EGWuintptr data = 0;
        
        if(!(newNode = (egwAVLTreeNode*)mallocFunc(((size_t)tree_out->eSize + (size_t)sizeof(egwAVLTreeNode))))) { egwAVLTreeFree(tree_out); return NULL; }
        memset((void*)newNode, 0, ((size_t)tree_out->eSize + (size_t)sizeof(egwAVLTreeNode)));
        
        ++tree_out->eCount;
        
        tree_out->tRoot = newNode;
        newNode->nBalance = tree_in->tRoot->nBalance;
        newNode->stHeight = tree_in->tRoot->stHeight;
        data = (EGWuintptr)newNode + (EGWuintptr)sizeof(egwAVLTreeNode);
        memcpy((void*)data, (const void*)((EGWuintptr)tree_in->tRoot + (EGWuintptr)sizeof(egwAVLTreeNode)), (size_t)tree_out->eSize);
        
        if(tree_out->tFlags & EGW_TREE_FLG_RETAIN)
            [(id<NSObject>)*(void**)data retain];
        
        if(addFunc)
            addFunc((EGWbyte*)data);
        
        egwAVLTreeCopyRecurse(tree_out, mallocFunc, addFunc, tree_in->tRoot, tree_out->tRoot);
        
        if(!tree_out->tRoot)
            return NULL;
    }
    
    return tree_out;
}

egwAVLTree* egwAVLTreeFree(egwAVLTree* tree_inout) {
    EGWfreefp freeFunc = (tree_inout->dFuncs && tree_inout->dFuncs->fpFree ? (EGWfreefp)tree_inout->dFuncs->fpFree : (EGWfreefp)&free);
    
    egwAVLTreeFreeRecurse(tree_inout, freeFunc, tree_inout->tRoot);
    
    if(tree_inout->dFuncs)
        free((void*)(tree_inout->dFuncs));
    
    memset((void*)tree_inout, 0, sizeof(egwAVLTree));
    
    return tree_inout;
}

EGWint egwAVLTreeAdd(egwAVLTree* tree_inout, const EGWbyte* data_in) {
    egwAVLTreeNode* newNode = NULL;
    EGWcomparefp compareFunc = (tree_inout->dFuncs && tree_inout->dFuncs->fpCompare ? (EGWcomparefp)tree_inout->dFuncs->fpCompare : (EGWcomparefp)&memcmp);
    
    {   EGWmallocfp mallocFunc = (tree_inout->dFuncs && tree_inout->dFuncs->fpMalloc ? (EGWmallocfp)tree_inout->dFuncs->fpMalloc : (EGWmallocfp)&malloc);
        if(!(newNode = (egwAVLTreeNode*)mallocFunc(((size_t)tree_inout->eSize + (size_t)sizeof(egwAVLTreeNode))))) { return 0; }
        memset((void*)newNode, 0, ((size_t)tree_inout->eSize + (size_t)sizeof(egwAVLTreeNode)));
    }
    
    ++tree_inout->eCount;
    
    newNode->nBalance = 0;
    newNode->stHeight = -1;
    memcpy((void*)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwAVLTreeNode)), (const void*)data_in, (size_t)tree_inout->eSize);
    
    if(tree_inout->tFlags & EGW_TREE_FLG_RETAIN)
        [(id<NSObject>)*(void**)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwAVLTreeNode)) retain];
    
    if(tree_inout->tRoot) {
        register egwAVLTreeNode* node = tree_inout->tRoot;
        
        while(1) {
            if(0 <= compareFunc(data_in, (EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwAVLTreeNode)), tree_inout->eSize)) {
                if(NULL == node->right) {
                    node->right = newNode;
                    break;
                } else
                    node = node->right;
            } else {
                if(NULL == node->left) {
                    node->left = newNode;
                    break;
                } else
                    node = node->left;
            }
        }
        
        newNode->parent = node;
    } else
        tree_inout->tRoot = newNode;
    
    egwAVLTreeFixUp(tree_inout, newNode);
    
    if(tree_inout->dFuncs && tree_inout->dFuncs->fpAdd)
        tree_inout->dFuncs->fpAdd((EGWbyte*)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwAVLTreeNode)));
    
    return 1;
}

EGWint egwAVLTreeRemove(egwAVLTree* tree_inout, egwAVLTreeNode* node_inout) {
    if(tree_inout->dFuncs && tree_inout->dFuncs->fpRemove)
        tree_inout->dFuncs->fpRemove((EGWbyte*)((EGWuintptr)node_inout + (EGWuintptr)sizeof(egwAVLTreeNode)));
    if(tree_inout->tFlags & EGW_TREE_FLG_RETAIN)
        [(id<NSObject>)*(void**)((EGWuintptr)node_inout + (EGWuintptr)sizeof(egwAVLTreeNode)) release];
    if(tree_inout->tFlags & EGW_TREE_FLG_FREE)
        free((void*)*(void**)((EGWuintptr)node_inout + (EGWuintptr)sizeof(egwAVLTreeNode)));
    
    if(node_inout->left && node_inout->right) {
        // Delete predecessor instead of high tree node, rewire pointers
        register egwAVLTreeNode* swapNode = node_inout;
        
        swapNode = swapNode->left;
        while(swapNode->right)
            swapNode = swapNode->right;
        
        // NOTE: Node contents cannot change since outer pointers may be pointing into tree structure - must do a more costly node rewire. -jw
        egwAVLTreeSwapNodeInPlace(tree_inout, node_inout, swapNode);
    }
    
    {   register egwAVLTreeNode* child = (node_inout->left ? node_inout->left : node_inout->right);
        register egwAVLTreeNode* parentNode = node_inout->parent;
        
        if(parentNode) {
            if(parentNode->left == node_inout)
                parentNode->left = child;
            else
                parentNode->right = child;
        } else
            tree_inout->tRoot = child;
        if(child)
            child->parent = parentNode;
        
        egwAVLTreeFixUp(tree_inout, parentNode);
    }
    
    {   EGWfreefp freeFunc = (tree_inout->dFuncs && tree_inout->dFuncs->fpFree ? (EGWfreefp)(tree_inout->dFuncs->fpFree) : (EGWfreefp)&free);
        freeFunc((void*)node_inout);
    }
    
    --tree_inout->eCount;
    
    return 1;
}

EGWuint egwAVLTreeRemoveAny(egwAVLTree* tree_inout, const EGWbyte* data_in) {
    EGWuint retVal = 0;
    
    egwAVLTreeNode* node;
    while((node = egwAVLTreeFind(tree_inout, data_in))) {
        if(egwAVLTreeRemove(tree_inout, node))
            ++retVal;
    }
    
    return retVal;
}

EGWint egwAVLTreeRemoveAll(egwAVLTree* tree_inout) {
    EGWfreefp freeFunc = (tree_inout->dFuncs && tree_inout->dFuncs->fpFree ? (EGWfreefp)(tree_inout->dFuncs->fpFree) : (EGWfreefp)&free);
    
    egwAVLTreeFreeRecurse(tree_inout, freeFunc, tree_inout->tRoot);
    
    tree_inout->eCount = 0;
    tree_inout->tRoot = NULL;
    
    return 1;
}

void egwAVLTreeGetElement(const egwAVLTree* tree_in, const egwAVLTreeNode* node_in, EGWbyte* data_out) {
    memcpy((void*)data_out, (void*)((EGWuintptr)node_in + (EGWuintptr)sizeof(egwAVLTreeNode)), (size_t)(tree_in->eSize));
}

EGWbyte* egwAVLTreeElementPtr(const egwAVLTreeNode* node_in) {
    return (EGWbyte*)((EGWuintptr)node_in + (EGWuintptr)sizeof(egwAVLTreeNode));
}

egwAVLTreeNode* egwAVLTreeNodePtr(const EGWbyte* data_in) {
    return (egwAVLTreeNode*)((EGWuintptr)data_in - (EGWuintptr)sizeof(egwAVLTreeNode));
}

egwAVLTreeNode* egwAVLTreeFind(const egwAVLTree* tree_in, const EGWbyte* data_in) {
    EGWcomparefp compareFunc = (tree_in->dFuncs && tree_in->dFuncs->fpCompare ? (EGWcomparefp)(tree_in->dFuncs->fpCompare) : (EGWcomparefp)&memcmp);
    register egwAVLTreeNode* node = tree_in->tRoot;
    
    while(node) {
        EGWint cmpValue = compareFunc((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwAVLTreeNode)), data_in, tree_in->eSize);
        
        if(0 == cmpValue)
            return node;
        else if(0 < cmpValue)
            node = node->left;
        else
            node = node->right;
    }
    
    return NULL;
}

EGWint egwAVLTreeContains(const egwAVLTree* tree_in, const EGWbyte* data_in) {
    return (egwAVLTreeFind(tree_in, data_in) ? 1 : 0);
}

EGWuint egwAVLTreeOccurances(const egwAVLTree* tree_in, const EGWbyte* data_in) {
    return egwAVLTreeOccurancesRecurse(tree_in, tree_in->tRoot, data_in);
}

EGWint egwAVLTreeResortElement(egwAVLTree* tree_inout, egwAVLTreeNode* node_inout) {
    EGWcomparefp compareFunc = (tree_inout->dFuncs && tree_inout->dFuncs->fpCompare ? (EGWcomparefp)(tree_inout->dFuncs->fpCompare) : (EGWcomparefp)&memcmp);
    egwAVLTreeNode* cmpNode;
    EGWint retVal = 0;
    
    while((cmpNode = (egwAVLTreeNode*)egwAVLTreeInorderPredecessor(node_inout))) {
        if(0 < compareFunc((EGWbyte*)((EGWuintptr)cmpNode + (EGWuintptr)sizeof(egwAVLTreeNode)),
                           (EGWbyte*)((EGWuintptr)node_inout + (EGWuintptr)sizeof(egwAVLTreeNode)), tree_inout->eSize)) {
            egwAVLTreeSwapNodeInPlace(tree_inout, cmpNode, node_inout);
            retVal = 1;
        } else break;
    }
    
    while((cmpNode = (egwAVLTreeNode*)egwAVLTreeInorderSuccessor(node_inout))) {
        if(0 < compareFunc((EGWbyte*)((EGWuintptr)node_inout + (EGWuintptr)sizeof(egwAVLTreeNode)),
                           (EGWbyte*)((EGWuintptr)cmpNode + (EGWuintptr)sizeof(egwAVLTreeNode)), tree_inout->eSize)) {
            egwAVLTreeSwapNodeInPlace(tree_inout, node_inout, cmpNode);
            retVal = 1;
        } else break;
    }
    
    return retVal;
}

EGWint egwAVLTreeEnumerateStart(const egwAVLTree* tree_in, EGWuint iterMode_in, egwAVLTreeIter* iter_out) {
    if(tree_in->eCount && tree_in->tRoot != NULL) {
        iter_out->pTree = tree_in;
        iter_out->nPos = tree_in->tRoot;
        iter_out->iMode = iterMode_in & EGW_ITERATE_MODE_EXBST;
        iter_out->eIndex = -1;
        iter_out->lotElms = NULL;
        
        switch(iter_out->iMode) {
            case EGW_ITERATE_MODE_BSTLSR: {
                while(iter_out->nPos->left)
                    iter_out->nPos = iter_out->nPos->left;
            } break;
                
            case EGW_ITERATE_MODE_BSTLRS: {
                while(iter_out->nPos->left != iter_out->nPos->right) {
                    while(iter_out->nPos->left)
                        iter_out->nPos = iter_out->nPos->left;
                    
                    if(iter_out->nPos->right)
                        iter_out->nPos = iter_out->nPos->right;
                }
            } break;
                
            case EGW_ITERATE_MODE_BSTRLS: {
                while(iter_out->nPos->right != iter_out->nPos->left) {
                    while(iter_out->nPos->right)
                        iter_out->nPos = iter_out->nPos->right;
                    
                    if(iter_out->nPos->left)
                        iter_out->nPos = iter_out->nPos->left;
                }
            } break;
                
            case EGW_ITERATE_MODE_BSTRSL: {
                while(iter_out->nPos->right)
                    iter_out->nPos = iter_out->nPos->right;
            } break;
            
            case EGW_ITERATE_MODE_BSTLO: {
                if(tree_in->eCount > 1) {
                    if(!(iter_out->lotElms = (egwCyclicArray*)malloc(sizeof(egwCyclicArray))) ||
                       !egwCycArrayInit(iter_out->lotElms, NULL, sizeof(egwAVLTreeNode*), (tree_in->eCount + 1) >> 1, EGW_ARRAY_FLG_DFLT)) {
                        if(iter_out->lotElms) {
                            egwCycArrayFree(iter_out->lotElms);
                            free((void*)iter_out->lotElms);
                            iter_out->lotElms = NULL;
                        }
                        
                        return 0;
                    }
                    
                    if(iter_out->nPos->left)
                        egwCycArrayAddTail(iter_out->lotElms, (const EGWbyte*)&iter_out->nPos->left);
                    if(iter_out->nPos->right)
                        egwCycArrayAddTail(iter_out->lotElms, (const EGWbyte*)&iter_out->nPos->right);
                }
            } break;
        }
        
        return 1;
    } else
        return 0;
}

EGWint egwAVLTreeEnumerateGetNext(egwAVLTreeIter* iter_inout, EGWbyte* data_out) {
    EGWbyte* data = egwAVLTreeEnumerateNextPtr(iter_inout);
    
    if(data) {
        memcpy((void*)data_out, (const void*)data, (size_t)(iter_inout->pTree->eSize));
        return 1;
    } else
        return 0;
}

EGWbyte* egwAVLTreeEnumerateNextPtr(egwAVLTreeIter* iter_inout) {
    if(iter_inout->nPos) {
        EGWbyte* retVal = (EGWbyte*)((EGWuintptr)(iter_inout->nPos) + (EGWuintptr)sizeof(egwAVLTreeNode));
        register egwAVLTreeNode* node;
        
        switch(iter_inout->iMode & EGW_ITERATE_MODE_EXBST) {
            case EGW_ITERATE_MODE_BSTLSR: {
                if(iter_inout->nPos->right) {
                    iter_inout->nPos = iter_inout->nPos->right;
                    
                    while(iter_inout->nPos->left)
                        iter_inout->nPos = iter_inout->nPos->left;
                } else {
                    do {
                        node = iter_inout->nPos;
                        iter_inout->nPos = iter_inout->nPos->parent;
                    } while(iter_inout->nPos && iter_inout->nPos->left != node);
                }
                
                ++iter_inout->eIndex;
            } break;
                
            case EGW_ITERATE_MODE_BSTLRS: {
                node = iter_inout->nPos;
                iter_inout->nPos = iter_inout->nPos->parent;
                
                if(iter_inout->nPos->right != node)
                    while(iter_inout->nPos->right) {
                        iter_inout->nPos = iter_inout->nPos->right;
                        
                        while(iter_inout->nPos->left)
                            iter_inout->nPos = iter_inout->nPos->left;
                    }
                
                ++iter_inout->eIndex;
            } break;
                
            case EGW_ITERATE_MODE_BSTSLR: {
                if(iter_inout->nPos->left)
                    iter_inout->nPos = iter_inout->nPos->left;
                else if(iter_inout->nPos->right)
                    iter_inout->nPos = iter_inout->nPos->right;
                else {
                    do {
                        node = iter_inout->nPos;
                        iter_inout->nPos = iter_inout->nPos->parent;
                        
                        if(iter_inout->nPos && iter_inout->nPos->right && iter_inout->nPos->left == node) {
                            iter_inout->nPos = iter_inout->nPos->right;
                            break;
                        }
                    } while(iter_inout->nPos);
                }
                
                ++iter_inout->eIndex;
            } break;
                
            case EGW_ITERATE_MODE_BSTSRL: {
                if(iter_inout->nPos->right)
                    iter_inout->nPos = iter_inout->nPos->right;
                else if(iter_inout->nPos->left)
                    iter_inout->nPos = iter_inout->nPos->left;
                else {
                    do {
                        node = iter_inout->nPos;
                        iter_inout->nPos = iter_inout->nPos->parent;
                        
                        if(iter_inout->nPos && iter_inout->nPos->left && iter_inout->nPos->right == node) {
                            iter_inout->nPos = iter_inout->nPos->left;
                            break;
                        }
                    } while(iter_inout->nPos);
                }
                
                ++iter_inout->eIndex;
            } break;
                
            case EGW_ITERATE_MODE_BSTRLS: {
                node = iter_inout->nPos;
                iter_inout->nPos = iter_inout->nPos->parent;
                
                if(iter_inout->nPos->left != node)
                    while(iter_inout->nPos->left) {
                        iter_inout->nPos = iter_inout->nPos->left;
                        
                        while(iter_inout->nPos->right)
                            iter_inout->nPos = iter_inout->nPos->right;
                    }
                
                ++iter_inout->eIndex;
            } break;
                
            case EGW_ITERATE_MODE_BSTRSL: {
                if(iter_inout->nPos->left) {
                    iter_inout->nPos = iter_inout->nPos->left;
                    
                    while(iter_inout->nPos->right)
                        iter_inout->nPos = iter_inout->nPos->right;
                } else {
                    do {
                        node = iter_inout->nPos;
                        iter_inout->nPos = iter_inout->nPos->parent;
                    } while(iter_inout->nPos && iter_inout->nPos->right != node);
                }
                
                ++iter_inout->eIndex;
            } break;
            
            case EGW_ITERATE_MODE_BSTLO: {
                if(iter_inout->lotElms && iter_inout->lotElms->eCount) {
                    iter_inout->nPos = *(egwAVLTreeNode**)egwCycArrayElementPtrHead(iter_inout->lotElms);
                    egwCycArrayRemoveHead(iter_inout->lotElms);
                    
                    if(iter_inout->nPos->left)
                        egwCycArrayAddTail(iter_inout->lotElms, (const EGWbyte*)&iter_inout->nPos->left);
                    if(iter_inout->nPos->right)
                        egwCycArrayAddTail(iter_inout->lotElms, (const EGWbyte*)&iter_inout->nPos->right);
                } else {
                    iter_inout->nPos = NULL;
                    
                    if(iter_inout->lotElms) {
                        egwCycArrayFree(iter_inout->lotElms);
                        free((void*)iter_inout->lotElms);
                        iter_inout->lotElms = NULL;
                    }
                }
                
                ++iter_inout->eIndex;
            } break;
        }
        
        return retVal;
    }
    
    if(iter_inout->lotElms) {
        egwCycArrayFree(iter_inout->lotElms);
        free((void*)iter_inout->lotElms);
        iter_inout->lotElms = NULL;
    }
    
    return NULL;
}

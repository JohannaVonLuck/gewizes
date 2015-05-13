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

/// @file egwSinglyLinkedList.m
/// @ingroup geWizES_data_singlylinkedlist
/// Singly-Linked List Implementation.

#import <string.h>
#import "egwSinglyLinkedList.h"


static egwSinglyLinkedListNode* egwSLListSortMerge(egwSinglyLinkedList* list_inout, egwSinglyLinkedListNode* nodeL_in, egwSinglyLinkedListNode* nodeR_in) {
    if(!nodeL_in)
        return nodeR_in;
    else if(!nodeR_in)
        return nodeL_in;
    else {
        EGWcomparefp compareFunc = (list_inout->dFuncs && list_inout->dFuncs->fpCompare ? (EGWcomparefp)(list_inout->dFuncs->fpCompare) : (EGWcomparefp)&memcmp);
        
        if(compareFunc((EGWbyte*)((EGWuintptr)nodeL_in + (EGWuintptr)sizeof(egwSinglyLinkedListNode)),
                       (EGWbyte*)((EGWuintptr)nodeR_in + (EGWuintptr)sizeof(egwSinglyLinkedListNode)), list_inout->eSize) < 0) {
            nodeL_in->next = egwSLListSortMerge(list_inout, nodeL_in->next, nodeR_in);
            return nodeL_in;
        } else {
            nodeR_in->next = egwSLListSortMerge(list_inout, nodeL_in, nodeR_in->next);
            return nodeR_in;
        }
    }
}

static egwSinglyLinkedListNode* egwSLListSortSplit(egwSinglyLinkedListNode* nodeL_in) {
    if(nodeL_in && nodeL_in->next) {
        egwSinglyLinkedListNode* nodeR = nodeL_in->next;
        nodeL_in->next = nodeR->next;
        nodeR->next = egwSLListSortSplit(nodeR->next);
        return nodeR;
    }
    
    return NULL;
}

static egwSinglyLinkedListNode* egwSLListSortRecurse(egwSinglyLinkedList* list_inout, egwSinglyLinkedListNode* nodeL_in) {
    if(nodeL_in && nodeL_in->next) {
        egwSinglyLinkedListNode* nodeR = egwSLListSortSplit(nodeL_in);
        nodeL_in = egwSLListSortRecurse(list_inout, nodeL_in);
        nodeR = egwSLListSortRecurse(list_inout, nodeR);
        return egwSLListSortMerge(list_inout, nodeL_in, nodeR);
    }
    
    return nodeL_in;
}

egwSinglyLinkedList* egwSLListInit(egwSinglyLinkedList* list_out, egwDataFuncs* funcs_in, EGWuint elmSize_in, EGWuint flags_in) {
    memset((void*)list_out, 0, sizeof(egwSinglyLinkedList));
    
    list_out->tFlags = (EGWuint16)flags_in;
    list_out->eSize = (EGWuint16)elmSize_in;
    
    if(funcs_in) {
        if(!(list_out->dFuncs = (egwDataFuncs*)malloc(sizeof(egwDataFuncs)))) { egwSLListFree(list_out); return NULL; }
        memcpy((void*)list_out->dFuncs, (const void*)funcs_in, sizeof(egwDataFuncs));
    }
    
    return list_out;
}

egwSinglyLinkedList* egwSLListFree(egwSinglyLinkedList* list_inout) {
    EGWfreefp freeFunc = (list_inout->dFuncs && list_inout->dFuncs->fpFree ? (EGWfreefp)(list_inout->dFuncs->fpFree) : (EGWfreefp)&free);
    
    while(list_inout->lHead) {
        egwSinglyLinkedListNode* node = list_inout->lHead;
        
        if(list_inout->dFuncs && list_inout->dFuncs->fpRemove)
            list_inout->dFuncs->fpRemove((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwSinglyLinkedListNode)));
        if(list_inout->tFlags & EGW_LIST_FLG_RETAIN)
            [(id<NSObject>)*(void**)((EGWuintptr)node + (EGWuintptr)sizeof(egwSinglyLinkedListNode)) release];
        if(list_inout->tFlags & EGW_LIST_FLG_FREE)
            free((void*)*(void**)((EGWuintptr)node + (EGWuintptr)sizeof(egwSinglyLinkedListNode)));
        
        list_inout->lHead = list_inout->lHead->next;
        freeFunc(node);
    }
    
    if(list_inout->dFuncs)
        free((void*)(list_inout->dFuncs));
    
    memset((void*)list_inout, 0, sizeof(egwSinglyLinkedList));
    
    return list_inout;
}

EGWint egwSLListAddHead(egwSinglyLinkedList* list_inout, const EGWbyte* data_in) {
    egwSinglyLinkedListNode* newNode = NULL;
    
    {   EGWmallocfp mallocFunc = (list_inout->dFuncs && list_inout->dFuncs->fpMalloc ? (EGWmallocfp)(list_inout->dFuncs->fpMalloc) : (EGWmallocfp)&malloc);
        if(!(newNode = (egwSinglyLinkedListNode*)mallocFunc(((size_t)(list_inout->eSize) + (size_t)sizeof(egwSinglyLinkedListNode))))) { return 0; }
        memset((void*)newNode, 0, ((size_t)(list_inout->eSize) + (size_t)sizeof(egwSinglyLinkedListNode)));
    }
    
    ++(list_inout->eCount);
    
    if(data_in)
        memcpy((void*)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwSinglyLinkedListNode)), (const void*)data_in, (size_t)(list_inout->eSize));
    
    if(list_inout->lHead) {
        newNode->next = list_inout->lHead;
        list_inout->lHead = newNode;
    } else
        list_inout->lHead = list_inout->lTail = newNode;
    
    if(data_in && list_inout->tFlags & EGW_LIST_FLG_RETAIN)
        [(id<NSObject>)*(void**)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwSinglyLinkedListNode)) retain];
    if(list_inout->dFuncs && list_inout->dFuncs->fpAdd)
        list_inout->dFuncs->fpAdd((EGWbyte*)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwSinglyLinkedListNode)));
    
    return 1;
}

EGWint egwSLListAddTail(egwSinglyLinkedList* list_inout, const EGWbyte* data_in) {
    egwSinglyLinkedListNode* newNode = NULL;
    
    {   EGWmallocfp mallocFunc = (list_inout->dFuncs && list_inout->dFuncs->fpMalloc ? (EGWmallocfp)(list_inout->dFuncs->fpMalloc) : (EGWmallocfp)&malloc);
        if(!(newNode = (egwSinglyLinkedListNode*)mallocFunc(((size_t)(list_inout->eSize) + (size_t)sizeof(egwSinglyLinkedListNode))))) { return 0; }
        memset((void*)newNode, 0, ((size_t)(list_inout->eSize) + (size_t)sizeof(egwSinglyLinkedListNode)));
    }
    
    ++(list_inout->eCount);
    
    if(data_in)
        memcpy((void*)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwSinglyLinkedListNode)), (const void*)data_in, (size_t)(list_inout->eSize));
    
    if(list_inout->lTail) {
        list_inout->lTail->next = newNode;
        list_inout->lTail = newNode;
    } else
        list_inout->lHead = list_inout->lTail = newNode;
    
    if(data_in && list_inout->tFlags & EGW_LIST_FLG_RETAIN)
        [(id<NSObject>)*(void**)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwSinglyLinkedListNode)) retain];
    if(list_inout->dFuncs && list_inout->dFuncs->fpAdd)
        list_inout->dFuncs->fpAdd((EGWbyte*)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwSinglyLinkedListNode)));
    
    return 1;
}

EGWint egwSLListAddAfter(egwSinglyLinkedList* list_inout, egwSinglyLinkedListNode* node_inout, const EGWbyte* data_in) {
    if(node_inout) {
        if(list_inout->lTail != node_inout) {
            egwSinglyLinkedListNode* newNode = NULL;
            
            {   EGWmallocfp mallocFunc = (list_inout->dFuncs && list_inout->dFuncs->fpMalloc ? (EGWmallocfp)(list_inout->dFuncs->fpMalloc) : (EGWmallocfp)&malloc);
                if(!(newNode = (egwSinglyLinkedListNode*)mallocFunc(((size_t)(list_inout->eSize) + (size_t)sizeof(egwSinglyLinkedListNode))))) { return 0; }
                memset((void*)newNode, 0, ((size_t)(list_inout->eSize) + (size_t)sizeof(egwSinglyLinkedListNode)));
            }
            
            ++(list_inout->eCount);
            
            if(data_in)
                memcpy((void*)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwSinglyLinkedListNode)), (const void*)data_in, (size_t)(list_inout->eSize));
            
            newNode->next = node_inout->next;
            node_inout->next = newNode;
            
            if(data_in && list_inout->tFlags & EGW_LIST_FLG_RETAIN)
                [(id<NSObject>)*(void**)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwSinglyLinkedListNode)) retain];
            if(list_inout->dFuncs && list_inout->dFuncs->fpAdd)
                list_inout->dFuncs->fpAdd((EGWbyte*)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwSinglyLinkedListNode)));
            
            return 1;
        } else
            return egwSLListAddTail(list_inout, data_in);
    } else
        return egwSLListAddHead(list_inout, data_in);
}

EGWint egwSLListAddBefore(egwSinglyLinkedList* list_inout, egwSinglyLinkedListNode* node_inout, const EGWbyte* data_in) {
    if(node_inout) {
        if(list_inout->lHead != node_inout) {
            egwSinglyLinkedListNode* newNode = NULL;
            
            {   EGWmallocfp mallocFunc = (list_inout->dFuncs && list_inout->dFuncs->fpMalloc ? (EGWmallocfp)(list_inout->dFuncs->fpMalloc) : (EGWmallocfp)&malloc);
                if(!(newNode = (egwSinglyLinkedListNode*)mallocFunc(((size_t)(list_inout->eSize) + (size_t)sizeof(egwSinglyLinkedListNode))))) { return 0; }
                memset((void*)newNode, 0, ((size_t)(list_inout->eSize) + (size_t)sizeof(egwSinglyLinkedListNode)));
            }
            
            ++(list_inout->eCount);
            
            if(data_in)
                memcpy((void*)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwSinglyLinkedListNode)), (const void*)data_in, (size_t)(list_inout->eSize));
            
            {   register egwSinglyLinkedListNode* node = list_inout->lHead;
                
                while(node->next != node_inout)
                    node = node->next;
                
                node->next = newNode;
                newNode->next = node_inout;
            }
            
            if(data_in && list_inout->tFlags & EGW_LIST_FLG_RETAIN)
                [(id<NSObject>)*(void**)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwSinglyLinkedListNode)) retain];
            if(list_inout->dFuncs && list_inout->dFuncs->fpAdd)
                list_inout->dFuncs->fpAdd((EGWbyte*)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwSinglyLinkedListNode)));
            
            return 1;
        } else
            return egwSLListAddHead(list_inout, data_in);
    } else
        return egwSLListAddTail(list_inout, data_in);
}

EGWint egwSLListRemove(egwSinglyLinkedList* list_inout, egwSinglyLinkedListNode* node_inout) {
    if(node_inout) {
        if(list_inout->lHead != node_inout) {
            if(list_inout->dFuncs && list_inout->dFuncs->fpRemove)
                list_inout->dFuncs->fpRemove((EGWbyte*)((EGWuintptr)node_inout + (EGWuintptr)sizeof(egwSinglyLinkedListNode)));
            if(list_inout->tFlags & EGW_LIST_FLG_RETAIN)
                [(id<NSObject>)*(void**)((EGWuintptr)node_inout + (EGWuintptr)sizeof(egwSinglyLinkedListNode)) release];
            if(list_inout->tFlags & EGW_LIST_FLG_FREE)
                free((void*)*(void**)((EGWuintptr)node_inout + (EGWuintptr)sizeof(egwSinglyLinkedListNode)));
            
            {   register egwSinglyLinkedListNode* node = list_inout->lHead;
                
                while(node->next != node_inout)
                    node = node->next;
                
                if(list_inout->lTail == node_inout)
                    list_inout->lTail = node;
                
                node->next = node_inout->next;
            }
            
            {   EGWfreefp freeFunc = (list_inout->dFuncs && list_inout->dFuncs->fpFree ? (EGWfreefp)(list_inout->dFuncs->fpFree) : (EGWfreefp)&free);
                freeFunc((void*)node_inout);
            }
            
            --(list_inout->eCount);
            
            return 1;
        } else
            return egwSLListRemoveHead(list_inout);
    } else
        return 0;
}

EGWint egwSLListRemoveHead(egwSinglyLinkedList* list_inout) {
    egwSinglyLinkedListNode* node = list_inout->lHead;
    
    if(node) {
        if(list_inout->dFuncs && list_inout->dFuncs->fpRemove)
            list_inout->dFuncs->fpRemove((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwSinglyLinkedListNode)));
        if(list_inout->tFlags & EGW_LIST_FLG_RETAIN)
            [(id<NSObject>)*(void**)((EGWuintptr)node + (EGWuintptr)sizeof(egwSinglyLinkedListNode)) release];
        if(list_inout->tFlags & EGW_LIST_FLG_FREE)
            free((void*)*(void**)((EGWuintptr)node + (EGWuintptr)sizeof(egwSinglyLinkedListNode)));
        
        list_inout->lHead = list_inout->lHead->next;
        
        if(!list_inout->lHead)
            list_inout->lTail = NULL;
        
        {   EGWfreefp freeFunc = (list_inout->dFuncs && list_inout->dFuncs->fpFree ? (EGWfreefp)(list_inout->dFuncs->fpFree) : (EGWfreefp)&free);
            freeFunc((void*)node);
        }
        
        --(list_inout->eCount);
        
        return 1;
    } else
        return 0;
}

EGWint egwSLListRemoveTail(egwSinglyLinkedList* list_inout) {
    return egwSLListRemove(list_inout, list_inout->lTail);
}

EGWint egwSLListRemoveAfter(egwSinglyLinkedList* list_inout, egwSinglyLinkedListNode* node_inout) {
    if(node_inout) {
        if(list_inout->lTail != node_inout) {
            register egwSinglyLinkedListNode* node = node_inout->next;
            
            if(list_inout->dFuncs && list_inout->dFuncs->fpRemove)
                list_inout->dFuncs->fpRemove((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwSinglyLinkedListNode)));
            if(list_inout->tFlags & EGW_LIST_FLG_RETAIN)
                [(id<NSObject>)*(void**)((EGWuintptr)node + (EGWuintptr)sizeof(egwSinglyLinkedListNode)) release];
            if(list_inout->tFlags & EGW_LIST_FLG_FREE)
                free((void*)*(void**)((EGWuintptr)node + (EGWuintptr)sizeof(egwSinglyLinkedListNode)));
            
            if(list_inout->lTail == node)
                list_inout->lTail = node_inout;
            
            node_inout->next = node->next;
            
            {   EGWfreefp freeFunc = (list_inout->dFuncs && list_inout->dFuncs->fpFree ? (EGWfreefp)(list_inout->dFuncs->fpFree) : (EGWfreefp)&free);
                freeFunc((void*)node);
            }
            
            --(list_inout->eCount);
            
            return 1;
        } else
            return 0;
    } else
        return egwSLListRemoveHead(list_inout);
}

EGWint egwSLListRemoveBefore(egwSinglyLinkedList* list_inout, egwSinglyLinkedListNode* node_inout) {
    if(node_inout) {
        if(list_inout->lHead != node_inout) {
            register egwSinglyLinkedListNode* node = list_inout->lHead;
            register egwSinglyLinkedListNode* prev = NULL;
            
            while(node->next != node_inout) {
                prev = node;
                node = node->next;
            }
            
            if(list_inout->dFuncs && list_inout->dFuncs->fpRemove)
                list_inout->dFuncs->fpRemove((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwSinglyLinkedListNode)));
            if(list_inout->tFlags & EGW_LIST_FLG_RETAIN)
                [(id<NSObject>)*(void**)((EGWuintptr)node + (EGWuintptr)sizeof(egwSinglyLinkedListNode)) release];
            if(list_inout->tFlags & EGW_LIST_FLG_FREE)
                free((void*)*(void**)((EGWuintptr)node + (EGWuintptr)sizeof(egwSinglyLinkedListNode)));
            
            if(list_inout->lHead == node) // prev is null
                list_inout->lHead = node_inout;
            else
                prev->next = node->next;
            
            {   EGWfreefp freeFunc = (list_inout->dFuncs && list_inout->dFuncs->fpFree ? (EGWfreefp)(list_inout->dFuncs->fpFree) : (EGWfreefp)&free);
                freeFunc((void*)node);
            }
            
            --(list_inout->eCount);
            
            return 1;
        } else
            return 0;
    } else
        return egwSLListRemoveTail(list_inout);
}

EGWuint egwSLListRemoveAny(egwSinglyLinkedList* list_inout, const EGWbyte* data_in) {
    EGWcomparefp compareFunc = (list_inout->dFuncs && list_inout->dFuncs->fpCompare ? (EGWcomparefp)(list_inout->dFuncs->fpCompare) : (EGWcomparefp)&memcmp);
    
    EGWuint acc = 0;
    register egwSinglyLinkedListNode* prev = NULL;
    register egwSinglyLinkedListNode* node = list_inout->lHead;
    
    while(node) {
        if(0 != compareFunc(data_in, (EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwSinglyLinkedListNode)), list_inout->eSize)) {
            prev = node;
            node = node->next;
        } else {
            node = node->next;
            egwSLListRemoveAfter(list_inout, prev);
            ++acc;
        }
    }
    
    return acc;
}

EGWint egwSLListRemoveAll(egwSinglyLinkedList* list_inout) {
    EGWfreefp freeFunc = (list_inout->dFuncs && list_inout->dFuncs->fpFree ? (EGWfreefp)(list_inout->dFuncs->fpFree) : (EGWfreefp)&free);
    
    while(list_inout->lHead) {
        egwSinglyLinkedListNode* node = list_inout->lHead;
        
        if(list_inout->dFuncs && list_inout->dFuncs->fpRemove)
            list_inout->dFuncs->fpRemove((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwSinglyLinkedListNode)));
        if(list_inout->tFlags & EGW_LIST_FLG_RETAIN)
            [(id<NSObject>)*(void**)((EGWuintptr)node + (EGWuintptr)sizeof(egwSinglyLinkedListNode)) release];
        if(list_inout->tFlags & EGW_LIST_FLG_FREE)
            free((void*)*(void**)((EGWuintptr)node + (EGWuintptr)sizeof(egwSinglyLinkedListNode)));
        
        list_inout->lHead = list_inout->lHead->next;
        freeFunc(node);
    }
    
    list_inout->eCount = 0;
    list_inout->lHead = list_inout->lTail = NULL;
    
    return 1;
}

EGWint egwSLListPromoteToHead(egwSinglyLinkedList* list_inout, egwSinglyLinkedListNode* node_inout) {
    if(list_inout->lHead != node_inout) { // check for already head
        egwSinglyLinkedListNode* prev = list_inout->lHead; // skip head node
        
        if(prev) {
            while(prev->next) {
                if(prev->next == node_inout)
                    return egwSLListPromoteToHeadAfter(list_inout, prev);
                prev = prev->next;
            }
        }
    }
    
    return 0;
}

EGWint egwSLListPromoteToHeadAfter(egwSinglyLinkedList* list_inout, egwSinglyLinkedListNode* node_inout) {
    if(node_inout) { // if null then already head
        egwSinglyLinkedListNode* node = node_inout->next;
        
        if(node->next) { // if not null then not tail
            node_inout->next = node->next;
            node->next = list_inout->lHead;
            list_inout->lHead = node;
        } else { // special case for tail
            list_inout->lTail = node_inout;
            node_inout->next = NULL;
            node->next = list_inout->lHead;
            list_inout->lHead = node;
        }
        
        return 1;
    } else
        return 0;
}

EGWint egwSLListPromoteToTail(egwSinglyLinkedList* list_inout, egwSinglyLinkedListNode* node_inout) {
    if(list_inout->lTail != node_inout) { // check for already tail
        if(list_inout->lHead != node_inout) { // check for head special case
            egwSinglyLinkedListNode* prev = list_inout->lHead; // skip head node
            
            if(prev) {
                while(prev->next) {
                    if(prev->next == node_inout)
                        return egwSLListPromoteToTailAfter(list_inout, prev);
                    prev = prev->next;
                }
            }
        } else
            return egwSLListPromoteToTailAfter(list_inout, NULL);
    }
    
    return 0;
}

EGWint egwSLListPromoteToTailAfter(egwSinglyLinkedList* list_inout, egwSinglyLinkedListNode* node_inout) {
    if(node_inout) { // if not null then not head
        egwSinglyLinkedListNode* node = node_inout->next;
        
        if(node->next) { // if null then already tail
            node_inout->next = node->next;
            list_inout->lTail->next = node;
            list_inout->lTail = node;
        } else
            return 0;
    } else { // special case for head
        egwSinglyLinkedListNode* node = list_inout->lHead;
        
        if(node->next) { // if null then already tail
            list_inout->lHead = node->next;
            node->next = NULL;
            list_inout->lTail->next = node;
            list_inout->lTail = node;
        } else
            return 0;
    }
    
    return 1;
}

void egwSLListGetElement(const egwSinglyLinkedList* list_in, const egwSinglyLinkedListNode* node_in, EGWbyte* data_out) {
    memcpy((void*)data_out, (void*)((EGWuintptr)node_in + (EGWuintptr)sizeof(egwSinglyLinkedListNode)), (size_t)(list_in->eSize));
}

void egwSLListGetElementAt(const egwSinglyLinkedList* list_in, EGWuint index_in, EGWbyte* data_out) {
    if(index_in < list_in->eCount) {
        egwSinglyLinkedListNode* node = list_in->lHead;
        
        while(index_in--)
            node = node->next;
        
        memcpy((void*)data_out, (void*)((EGWuintptr)node + (EGWuintptr)sizeof(egwSinglyLinkedListNode)), (size_t)(list_in->eSize));
    }
}

void egwSLListGetElementHead(const egwSinglyLinkedList* list_in, EGWbyte* data_out) {
    memcpy((void*)data_out, (void*)((EGWuintptr)(list_in->lHead) + (EGWuintptr)sizeof(egwSinglyLinkedListNode)), (size_t)(list_in->eSize));
}

void egwSLListGetElementTail(const egwSinglyLinkedList* list_in, EGWbyte* data_out) {
    memcpy((void*)data_out, (void*)((EGWuintptr)(list_in->lTail) + (EGWuintptr)sizeof(egwSinglyLinkedListNode)), (size_t)(list_in->eSize));
}

EGWbyte* egwSLListElementPtr(const egwSinglyLinkedListNode* node_in) {
    return (EGWbyte*)((EGWuintptr)node_in + (EGWuintptr)sizeof(egwSinglyLinkedListNode));
}

EGWbyte* egwSLListElementPtrAt(const egwSinglyLinkedList* list_in, EGWuint index_in) {
    if(index_in < list_in->eCount) {
        egwSinglyLinkedListNode* node = list_in->lHead;
        
        while(index_in--)
            node = node->next;
        
        return (EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwSinglyLinkedListNode));
    } else
        return 0;
}

EGWbyte* egwSLListElementPtrHead(const egwSinglyLinkedList* list_in) {
    return (EGWbyte*)((EGWuintptr)(list_in->lHead) + (EGWuintptr)sizeof(egwSinglyLinkedListNode));
}

EGWbyte* egwSLListElementPtrTail(const egwSinglyLinkedList* list_in) {
    return (EGWbyte*)((EGWuintptr)(list_in->lTail) + (EGWuintptr)sizeof(egwSinglyLinkedListNode));
}

egwSinglyLinkedListNode* egwSLListNodePtr(const EGWbyte* data_in) {
    return (egwSinglyLinkedListNode*)((EGWuintptr)data_in - (EGWuintptr)sizeof(egwSinglyLinkedListNode));
}

egwSinglyLinkedListNode* egwSLListFind(const egwSinglyLinkedList* list_in, const EGWbyte* data_in, EGWuint findMode_in) {
    EGWcomparefp compareFunc = (list_in->dFuncs && list_in->dFuncs->fpCompare ? (EGWcomparefp)(list_in->dFuncs->fpCompare) : (EGWcomparefp)&memcmp);
    register egwSinglyLinkedListNode* node = list_in->lHead;
    
    if(!(findMode_in & EGW_FIND_MODE_ISSORTED)) {
        while(node) {
            if(0 != compareFunc(data_in, (EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwSinglyLinkedListNode)), list_in->eSize))
                node = node->next;
            else
                return node;
        }
    } else {
        while(node) {
            EGWint cmpValue = compareFunc((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwSinglyLinkedListNode)), data_in, list_in->eSize);
            if(0 != cmpValue) {
                if(cmpValue > 0)
                    return NULL;
                node = node->next;
            }
            else
                return node;
        }
    }
    
    return 0;
}

EGWint egwSLListContains(const egwSinglyLinkedList* list_in, const EGWbyte* data_in, EGWuint findMode_in) {
    return (egwSLListFind(list_in, data_in, findMode_in) ? 1 : 0);
}

EGWuint egwSLListOccurances(const egwSinglyLinkedList* list_in, const EGWbyte* data_in, EGWuint findMode_in) {
    EGWuint retVal = 0;
    EGWcomparefp compareFunc = (list_in->dFuncs && list_in->dFuncs->fpCompare ? (EGWcomparefp)(list_in->dFuncs->fpCompare) : (EGWcomparefp)&memcmp);
    register egwSinglyLinkedListNode* node = list_in->lHead;
    
    if(!(findMode_in & EGW_FIND_MODE_ISSORTED)) {
        while(node) {
            if(0 == compareFunc((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwSinglyLinkedListNode)), data_in, list_in->eSize))
                ++retVal;
            node = node->next;
        }
    } else {
        while(node) {
            EGWint cmpValue = compareFunc((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwSinglyLinkedListNode)), data_in, list_in->eSize);
            if(0 == cmpValue)
                ++retVal;
            else if(cmpValue > 0)
                break;
            node = node->next;
        }
    }
    
    return retVal;
}

void egwSLListSort(egwSinglyLinkedList* list_inout) {
    if(list_inout->eCount > 1) {
        list_inout->lHead = egwSLListSortRecurse(list_inout, list_inout->lHead);
        
        // Figure out new tail pointer location
        list_inout->lTail = list_inout->lHead;
        if(list_inout->lTail)
            while(list_inout->lTail->next)
                list_inout->lTail = list_inout->lTail->next;
    }
}

EGWint egwSLListEnumerateStart(const egwSinglyLinkedList* list_in, EGWuint iterMode_in, egwSinglyLinkedListIter* iter_out) {
    if(list_in->eCount) {
        iter_out->pList = list_in;
        iter_out->nPos = NULL;
        iter_out->iMode = iterMode_in;
        iter_out->eIndex = -1;
        
        switch(iter_out->iMode & EGW_ITERATE_MODE_EXLIN) {
            case EGW_ITERATE_MODE_LINHTT: {
                iter_out->nPos = list_in->lHead;
            } break;
                
            case EGW_ITERATE_MODE_LINTTH: {
                iter_out->nPos = list_in->lTail;
            } break;
        }
        
        return 1;
    } else
        return 0;
}

EGWint egwSLListEnumerateGetNext(egwSinglyLinkedListIter* iter_inout, EGWbyte* data_out) {
    EGWbyte* data = egwSLListEnumerateNextPtr(iter_inout);
    
    if(data) {
        memcpy((void*)data_out, (const void*)data, (size_t)(iter_inout->pList->eSize));
        return 1;
    } else
        return 0;
}

EGWbyte* egwSLListEnumerateNextPtr(egwSinglyLinkedListIter* iter_inout) {
    if(iter_inout->nPos) {
        EGWbyte* retVal = (EGWbyte*)((EGWuintptr)(iter_inout->nPos) + (EGWuintptr)sizeof(egwSinglyLinkedListNode));
        
        if(++(iter_inout->eIndex) < iter_inout->pList->eCount - 1) {
            switch(iter_inout->iMode & EGW_ITERATE_MODE_EXLIN) {
                case EGW_ITERATE_MODE_LINHTT: {
                    iter_inout->nPos = iter_inout->nPos->next;
                } break;
                
                case EGW_ITERATE_MODE_LINTTH: {
                    register egwSinglyLinkedListNode* node = iter_inout->pList->lHead;
                    
                    while(node->next != iter_inout->nPos)
                        node = node->next;
                    
                    iter_inout->nPos = node;
                } break;
            }
        } else
            iter_inout->nPos = NULL;
        
        return retVal;
    }
    
    return NULL;
}

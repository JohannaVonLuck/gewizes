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

/// @file egwDoublyLinkedList.m
/// @ingroup geWizES_data_doublylinkedlist
/// Doubly-Linked List Implementation.

#import "egwDoublyLinkedList.h"


static egwDoublyLinkedListNode* egwDLListSortMerge(egwDoublyLinkedList* list_inout, egwDoublyLinkedListNode* nodeL_in, egwDoublyLinkedListNode* nodeR_in) {
    if(!nodeL_in)
        return nodeR_in;
    else if(!nodeR_in)
        return nodeL_in;
    else {
        EGWcomparefp compareFunc = (list_inout->dFuncs && list_inout->dFuncs->fpCompare ? (EGWcomparefp)list_inout->dFuncs->fpCompare : (EGWcomparefp)&memcmp);
        
        if(compareFunc((EGWbyte*)((EGWuintptr)nodeL_in + (EGWuintptr)sizeof(egwDoublyLinkedListNode)),
                       (EGWbyte*)((EGWuintptr)nodeR_in + (EGWuintptr)sizeof(egwDoublyLinkedListNode)), list_inout->eSize) < 0) {
            nodeL_in->next = egwDLListSortMerge(list_inout, nodeL_in->next, nodeR_in);
            return nodeL_in;
        } else {
            nodeR_in->next = egwDLListSortMerge(list_inout, nodeL_in, nodeR_in->next);
            return nodeR_in;
        }
    }
}

static egwDoublyLinkedListNode* egwDLListSortSplit(egwDoublyLinkedListNode* nodeL_in) {
    if(nodeL_in && nodeL_in->next) {
        egwDoublyLinkedListNode* nodeR = nodeL_in->next;
        nodeL_in->next = nodeR->next;
        nodeR->next = egwDLListSortSplit(nodeR->next);
        return nodeR;
    }
    
    return NULL;
}

static egwDoublyLinkedListNode* egwDLListSortRecurse(egwDoublyLinkedList* list_inout, egwDoublyLinkedListNode* nodeL_in) {
    if(nodeL_in && nodeL_in->next) {
        egwDoublyLinkedListNode* nodeR = egwDLListSortSplit(nodeL_in);
        nodeL_in = egwDLListSortRecurse(list_inout, nodeL_in);
        nodeR = egwDLListSortRecurse(list_inout, nodeR);
        return egwDLListSortMerge(list_inout, nodeL_in, nodeR);
    }
    
    return nodeL_in;
}

egwDoublyLinkedList* egwDLListInit(egwDoublyLinkedList* list_out, egwDataFuncs* funcs_in, EGWuint elmSize_in, EGWuint flags_in) {
    memset((void*)list_out, 0, sizeof(egwDoublyLinkedList));
    
    list_out->lFlags = (EGWuint16)flags_in;
    list_out->eSize = (EGWuint16)elmSize_in;
    
    if(funcs_in) {
        if(!(list_out->dFuncs = (egwDataFuncs*)malloc(sizeof(egwDataFuncs)))) { egwDLListFree(list_out); return NULL; }
        memcpy((void*)list_out->dFuncs, (const void*)funcs_in, sizeof(egwDataFuncs));
    }
    
    return list_out;
}

egwDoublyLinkedList* egwDLListCopy(const egwDoublyLinkedList* list_in, egwDoublyLinkedList* list_out) {
    memset((void*)list_out, 0, sizeof(egwDoublyLinkedList));
    
    if(list_in->lFlags & EGW_LIST_FLG_FREE) // Ownership sharing not permitted
        return NULL;
    
    list_out->lFlags = list_in->lFlags;
    list_out->eSize = list_in->eSize;
    list_out->eCount = list_in->eCount;
    
    if(list_in->dFuncs) {
        if(!(list_out->dFuncs = (egwDataFuncs*)malloc(sizeof(egwDataFuncs)))) { egwDLListFree(list_out); return NULL; }
        memcpy((void*)list_out->dFuncs, (const void*)list_in->dFuncs, sizeof(egwDataFuncs));
    }
    
    if(list_in->eCount) {
        EGWmallocfp mallocFunc = (list_out->dFuncs && list_out->dFuncs->fpMalloc ? (EGWmallocfp)list_out->dFuncs->fpMalloc : (EGWmallocfp)&malloc);
        EGWelementfp addFunc = (list_out->dFuncs && list_out->dFuncs->fpAdd ? (EGWelementfp)list_out->dFuncs->fpAdd : (EGWelementfp)NULL);
        egwDoublyLinkedListNode* node = list_in->lHead;
        egwDoublyLinkedListNode* newNode = NULL;
        EGWuintptr data = 0;
        
        while(node) {
            if(!(newNode = (egwDoublyLinkedListNode*)mallocFunc(((size_t)list_out->eSize + sizeof(egwDoublyLinkedListNode))))) { egwDLListFree(list_out); return NULL; }
            memset((void*)newNode, 0, ((size_t)list_out->eSize + sizeof(egwDoublyLinkedListNode)));
            
            if(list_out->lTail) {
                newNode->prev = list_out->lTail;
                list_out->lTail = list_out->lTail->next = newNode;
            } else
                list_out->lHead = list_out->lTail = newNode;
            
            data = (EGWuintptr)newNode + (EGWuintptr)sizeof(egwDoublyLinkedListNode);
            memcpy((void*)data, (const void*)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)), (size_t)list_out->eSize);
            
            if(list_out->lFlags & EGW_LIST_FLG_RETAIN)
                [(id<NSObject>)*(void**)data retain];
            
            if(addFunc)
                addFunc((EGWbyte*)data);
            
            node = node->next;
        }
    }
    
    return list_out;
}

egwDoublyLinkedList* egwDLListFree(egwDoublyLinkedList* list_inout) {
    EGWfreefp freeFunc = (list_inout->dFuncs && list_inout->dFuncs->fpFree ? (EGWfreefp)list_inout->dFuncs->fpFree : (EGWfreefp)&free);
    
    while(list_inout->lHead) {
        egwDoublyLinkedListNode* node = list_inout->lHead;
        
        if(list_inout->dFuncs && list_inout->dFuncs->fpRemove)
            list_inout->dFuncs->fpRemove((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)));
        if(list_inout->lFlags & EGW_LIST_FLG_RETAIN)
            [(id<NSObject>)*(void**)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)) release];
        if(list_inout->lFlags & EGW_LIST_FLG_FREE)
            free((void*)*(void**)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)));
        
        list_inout->lHead = list_inout->lHead->next;
        freeFunc(node);
    }
    
    if(list_inout->dFuncs)
        free((void*)(list_inout->dFuncs));
    
    memset((void*)list_inout, 0, sizeof(egwDoublyLinkedList));
    
    return list_inout;
}

EGWint egwDLListAddAt(egwDoublyLinkedList* list_inout, EGWuint index_in, const EGWbyte* data_in) {
    if(index_in != 0) {
        if(index_in < list_inout->eCount - 1) {
            egwDoublyLinkedListNode* newNode = NULL;
            
            {   EGWmallocfp mallocFunc = (list_inout->dFuncs && list_inout->dFuncs->fpMalloc ? (EGWmallocfp)list_inout->dFuncs->fpMalloc : (EGWmallocfp)&malloc);
                if(!(newNode = (egwDoublyLinkedListNode*)mallocFunc(((size_t)list_inout->eSize + sizeof(egwDoublyLinkedListNode))))) { return 0; }
                memset((void*)newNode, 0, ((size_t)list_inout->eSize + sizeof(egwDoublyLinkedListNode)));
            }
            
            ++list_inout->eCount;
            
            if(data_in)
                memcpy((void*)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwDoublyLinkedListNode)), (const void*)data_in, (size_t)list_inout->eSize);
            
            {   register egwDoublyLinkedListNode* node = list_inout->lHead;
                register EGWuint index = 1;
                
                while(index != index_in) {
                    node = node->next;
                    ++index;
                }
                
                newNode->prev = node;
                newNode->next = node->next;
                node->next = node->next->prev = newNode;
            }
            
            if(data_in && list_inout->lFlags & EGW_LIST_FLG_RETAIN)
                [(id<NSObject>)*(void**)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwDoublyLinkedListNode)) retain];
            if(list_inout->dFuncs && list_inout->dFuncs->fpAdd)
                list_inout->dFuncs->fpAdd((EGWbyte*)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwDoublyLinkedListNode)));
            
            return 1;
        } else
            return egwDLListAddTail(list_inout, data_in);
    } else
        return egwDLListAddHead(list_inout, data_in);
}

EGWint egwDLListAddHead(egwDoublyLinkedList* list_inout, const EGWbyte* data_in) {
    egwDoublyLinkedListNode* newNode = NULL;
    
    {   EGWmallocfp mallocFunc = (list_inout->dFuncs && list_inout->dFuncs->fpMalloc ? (EGWmallocfp)list_inout->dFuncs->fpMalloc : (EGWmallocfp)&malloc);
        if(!(newNode = (egwDoublyLinkedListNode*)mallocFunc(((size_t)list_inout->eSize + sizeof(egwDoublyLinkedListNode))))) { return 0; }
        memset((void*)newNode, 0, ((size_t)list_inout->eSize + sizeof(egwDoublyLinkedListNode)));
    }
    
    ++list_inout->eCount;
    
    if(data_in)
        memcpy((void*)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwDoublyLinkedListNode)), (const void*)data_in, (size_t)list_inout->eSize);
    
    if(list_inout->lHead) {
        newNode->next = list_inout->lHead;
        list_inout->lHead = list_inout->lHead->prev = newNode;
    } else 
        list_inout->lHead = list_inout->lTail = newNode;
    
    if(data_in && list_inout->lFlags & EGW_LIST_FLG_RETAIN)
        [(id<NSObject>)*(void**)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwDoublyLinkedListNode)) retain];
    if(list_inout->dFuncs && list_inout->dFuncs->fpAdd)
        list_inout->dFuncs->fpAdd((EGWbyte*)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwDoublyLinkedListNode)));
    
    return 1;
}

EGWint egwDLListAddTail(egwDoublyLinkedList* list_inout, const EGWbyte* data_in) {
    egwDoublyLinkedListNode* newNode = NULL;
    
    {   EGWmallocfp mallocFunc = (list_inout->dFuncs && list_inout->dFuncs->fpMalloc ? (EGWmallocfp)list_inout->dFuncs->fpMalloc : (EGWmallocfp)&malloc);
        if(!(newNode = (egwDoublyLinkedListNode*)mallocFunc(((size_t)list_inout->eSize + sizeof(egwDoublyLinkedListNode))))) { return 0; }
        memset((void*)newNode, 0, ((size_t)list_inout->eSize + sizeof(egwDoublyLinkedListNode)));
    }
    
    ++list_inout->eCount;
    
    if(data_in)
        memcpy((void*)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwDoublyLinkedListNode)), (const void*)data_in, (size_t)list_inout->eSize);
    
    if(list_inout->lTail) {
        newNode->prev = list_inout->lTail;
        list_inout->lTail = list_inout->lTail->next = newNode;
    } else
        list_inout->lHead = list_inout->lTail = newNode;
    
    if(data_in && list_inout->lFlags & EGW_LIST_FLG_RETAIN)
        [(id<NSObject>)*(void**)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwDoublyLinkedListNode)) retain];
    if(list_inout->dFuncs && list_inout->dFuncs->fpAdd)
        list_inout->dFuncs->fpAdd((EGWbyte*)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwDoublyLinkedListNode)));
    
    return 1;
}

EGWint egwDLListAddAfter(egwDoublyLinkedList* list_inout, egwDoublyLinkedListNode* node_inout, const EGWbyte* data_in) {
    if(node_inout) {
        if(list_inout->lTail != node_inout) {
            egwDoublyLinkedListNode* newNode = NULL;
            
            {   EGWmallocfp mallocFunc = (list_inout->dFuncs && list_inout->dFuncs->fpMalloc ? (EGWmallocfp)list_inout->dFuncs->fpMalloc : (EGWmallocfp)&malloc);
                if(!(newNode = (egwDoublyLinkedListNode*)mallocFunc(((size_t)list_inout->eSize + sizeof(egwDoublyLinkedListNode))))) { return 0; }
                memset((void*)newNode, 0, ((size_t)list_inout->eSize + sizeof(egwDoublyLinkedListNode)));
            }
            
            ++list_inout->eCount;
            
            if(data_in)
                memcpy((void*)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwDoublyLinkedListNode)), (const void*)data_in, (size_t)list_inout->eSize);
            
            newNode->prev = node_inout;
            newNode->next = node_inout->next;
            node_inout->next = node_inout->next->prev = newNode;
            
            if(data_in && list_inout->lFlags & EGW_LIST_FLG_RETAIN)
                [(id<NSObject>)*(void**)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwDoublyLinkedListNode)) retain];
            if(list_inout->dFuncs && list_inout->dFuncs->fpAdd)
                list_inout->dFuncs->fpAdd((EGWbyte*)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwDoublyLinkedListNode)));
            
            return 1;
        } else
            return egwDLListAddTail(list_inout, data_in);
    } else
        return egwDLListAddHead(list_inout, data_in);
}

EGWint egwDLListAddBefore(egwDoublyLinkedList* list_inout, egwDoublyLinkedListNode* node_inout, const EGWbyte* data_in) {
    if(node_inout) {
        if(list_inout->lHead != node_inout) {
            egwDoublyLinkedListNode* newNode = NULL;
            
            {   EGWmallocfp mallocFunc = (list_inout->dFuncs && list_inout->dFuncs->fpMalloc ? (EGWmallocfp)list_inout->dFuncs->fpMalloc : (EGWmallocfp)&malloc);
                if(!(newNode = (egwDoublyLinkedListNode*)mallocFunc(((size_t)list_inout->eSize + sizeof(egwDoublyLinkedListNode))))) { return 0; }
                memset((void*)newNode, 0, ((size_t)list_inout->eSize + sizeof(egwDoublyLinkedListNode)));
            }
            
            ++list_inout->eCount;
            
            if(data_in)
                memcpy((void*)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwDoublyLinkedListNode)), (const void*)data_in, (size_t)list_inout->eSize);
            
            newNode->prev = node_inout->prev;
            newNode->next = node_inout;
            node_inout->prev = node_inout->prev->next = newNode;
            
            if(data_in && list_inout->lFlags & EGW_LIST_FLG_RETAIN)
                [(id<NSObject>)*(void**)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwDoublyLinkedListNode)) retain];
            if(list_inout->dFuncs && list_inout->dFuncs->fpAdd)
                list_inout->dFuncs->fpAdd((EGWbyte*)((EGWuintptr)newNode + (EGWuintptr)sizeof(egwDoublyLinkedListNode)));
            
            return 1;
        } else
            return egwDLListAddHead(list_inout, data_in);
    } else
        return egwDLListAddTail(list_inout, data_in);
}

EGWint egwDLListRemove(egwDoublyLinkedList* list_inout, egwDoublyLinkedListNode* node_inout) {
    if(node_inout) {
        if(list_inout->dFuncs && list_inout->dFuncs->fpRemove)
            list_inout->dFuncs->fpRemove((EGWbyte*)((EGWuintptr)node_inout + (EGWuintptr)sizeof(egwDoublyLinkedListNode)));
        if(list_inout->lFlags & EGW_LIST_FLG_RETAIN)
            [(id<NSObject>)*(void**)((EGWuintptr)node_inout + (EGWuintptr)sizeof(egwDoublyLinkedListNode)) release];
        if(list_inout->lFlags & EGW_LIST_FLG_FREE)
            free((void*)*(void**)((EGWuintptr)node_inout + (EGWuintptr)sizeof(egwDoublyLinkedListNode)));
        
        if(node_inout != list_inout->lHead) {
            if(node_inout != list_inout->lTail) {
                node_inout->prev->next = node_inout->next;
                node_inout->next->prev = node_inout->prev;
            } else {
                list_inout->lTail = list_inout->lTail->prev;
                if(list_inout->lTail)
                    list_inout->lTail->next = NULL;
                else
                    list_inout->lHead = NULL;
            }
        } else {
            list_inout->lHead = list_inout->lHead->next;
            if(list_inout->lHead)
                list_inout->lHead->prev = NULL;
            else
                list_inout->lTail = NULL;
        }
        
        {   EGWfreefp freeFunc = (list_inout->dFuncs && list_inout->dFuncs->fpFree ? (EGWfreefp)list_inout->dFuncs->fpFree : (EGWfreefp)&free);
            freeFunc((void*)node_inout);
        }
        
        --list_inout->eCount;
        
        return 1;
    } else
        return 0;
}

EGWint egwDLListRemoveAt(egwDoublyLinkedList* list_inout, EGWuint index_in) {
    if(index_in != 0) {
        if(index_in < list_inout->eCount - 1) {
            egwDoublyLinkedListNode* node = list_inout->lHead->next;
            
            {   register EGWuint index = 1;
                
                while(index != index_in) {
                    node = node->next;
                    ++index;
                }
            }
            
            if(list_inout->dFuncs && list_inout->dFuncs->fpRemove)
                list_inout->dFuncs->fpRemove((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)));
            if(list_inout->lFlags & EGW_LIST_FLG_RETAIN)
                [(id<NSObject>)*(void**)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)) release];
            if(list_inout->lFlags & EGW_LIST_FLG_FREE)
                free((void*)*(void**)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)));
            
            node->prev->next = node->next;
            node->next->prev = node->prev;
            
            {   EGWfreefp freeFunc = (list_inout->dFuncs && list_inout->dFuncs->fpFree ? (EGWfreefp)list_inout->dFuncs->fpFree : (EGWfreefp)&free);
                freeFunc((void*)node);
            }
            
            --list_inout->eCount;
            
            return 1;
        } else
            return egwDLListRemoveTail(list_inout);
    } else
        return egwDLListRemoveHead(list_inout);
}

EGWint egwDLListRemoveHead(egwDoublyLinkedList* list_inout) {
    egwDoublyLinkedListNode* node = list_inout->lHead;
    
    if(node) {
        if(list_inout->dFuncs && list_inout->dFuncs->fpRemove)
            list_inout->dFuncs->fpRemove((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)));
        if(list_inout->lFlags & EGW_LIST_FLG_RETAIN)
            [(id<NSObject>)*(void**)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)) release];
        if(list_inout->lFlags & EGW_LIST_FLG_FREE)
            free((void*)*(void**)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)));
        
        list_inout->lHead = node->next;
        if(list_inout->lHead)
            list_inout->lHead->prev = NULL;
        else
            list_inout->lTail = NULL;
        
        {   EGWfreefp freeFunc = (list_inout->dFuncs && list_inout->dFuncs->fpFree ? (EGWfreefp)list_inout->dFuncs->fpFree : (EGWfreefp)&free);
            freeFunc((void*)node);
        }
        
        --list_inout->eCount;
        
        return 1;
    } else
        return 0;
}

EGWint egwDLListRemoveTail(egwDoublyLinkedList* list_inout) {
    egwDoublyLinkedListNode* node = list_inout->lTail;
    
    if(node) {
        if(list_inout->dFuncs && list_inout->dFuncs->fpRemove)
            list_inout->dFuncs->fpRemove((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)));
        if(list_inout->lFlags & EGW_LIST_FLG_RETAIN)
            [(id<NSObject>)*(void**)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)) release];
        if(list_inout->lFlags & EGW_LIST_FLG_FREE)
            free((void*)*(void**)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)));
        
        list_inout->lTail = node->prev;
        if(list_inout->lTail)
            list_inout->lTail->next = NULL;
        else
            list_inout->lHead = NULL;
        
        {   EGWfreefp freeFunc = (list_inout->dFuncs && list_inout->dFuncs->fpFree ? (EGWfreefp)list_inout->dFuncs->fpFree : (EGWfreefp)&free);
            freeFunc((void*)node);
        }
        
        --list_inout->eCount;
        
        return 1;
    } else
        return 0;
}

EGWint egwDLListRemoveAfter(egwDoublyLinkedList* list_inout, egwDoublyLinkedListNode* node_inout) {
    if(node_inout) {
        if(list_inout->lTail != node_inout) {
            egwDoublyLinkedListNode* node = node_inout->next;
            
            if(list_inout->dFuncs && list_inout->dFuncs->fpRemove)
                list_inout->dFuncs->fpRemove((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)));
            if(list_inout->lFlags & EGW_LIST_FLG_RETAIN)
                [(id<NSObject>)*(void**)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)) release];
            if(list_inout->lFlags & EGW_LIST_FLG_FREE)
                free((void*)*(void**)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)));
            
            if(list_inout->lTail == node)
                list_inout->lTail = node_inout;
            else
                node->next->prev = node_inout;
            
            node_inout->next = node->next;
            
            {   EGWfreefp freeFunc = (list_inout->dFuncs && list_inout->dFuncs->fpFree ? (EGWfreefp)list_inout->dFuncs->fpFree : (EGWfreefp)&free);
                freeFunc((void*)node);
            }
            
            --list_inout->eCount;
            
            return 1;
        } else
            return 0;
    } else
        return egwDLListRemoveHead(list_inout);
}

EGWint egwDLListRemoveBefore(egwDoublyLinkedList* list_inout, egwDoublyLinkedListNode* node_inout) {
    if(node_inout) {
        if(list_inout->lHead != node_inout) {
            egwDoublyLinkedListNode* node = node_inout->prev;
            
            if(list_inout->dFuncs && list_inout->dFuncs->fpRemove)
                list_inout->dFuncs->fpRemove((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)));
            if(list_inout->lFlags & EGW_LIST_FLG_RETAIN)
                [(id<NSObject>)*(void**)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)) release];
            if(list_inout->lFlags & EGW_LIST_FLG_FREE)
                free((void*)*(void**)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)));
            
            if(list_inout->lHead == node)
                list_inout->lHead = node_inout;
            else
                node->prev->next = node_inout;
            
            node_inout->prev = node->prev;
            
            {   EGWfreefp freeFunc = (list_inout->dFuncs && list_inout->dFuncs->fpFree ? (EGWfreefp)list_inout->dFuncs->fpFree : (EGWfreefp)&free);
                freeFunc((void*)node);
            }
            
            --list_inout->eCount;
            
            return 1;
        } else
            return 0;
    } else
        return egwDLListRemoveTail(list_inout);
}

EGWuint egwDLListRemoveAny(egwDoublyLinkedList* list_inout, const EGWbyte* data_in, EGWuint findMode_in) {
    EGWcomparefp compareFunc = (list_inout->dFuncs && list_inout->dFuncs->fpCompare ? (EGWcomparefp)list_inout->dFuncs->fpCompare : (EGWcomparefp)&memcmp);
    EGWuint retVal = 0;
    
    switch(findMode_in & EGW_FIND_MODE_EXMETHOD) {
        default:
        case EGW_FIND_MODE_LINHTT: {
            egwDoublyLinkedListNode* node = list_inout->lHead;
            egwDoublyLinkedListNode* prev = NULL;
            
            if(!(findMode_in & EGW_FIND_MODE_ISSORTED)) {
                while(node) {
                    if(0 != compareFunc((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)), data_in, list_inout->eSize)) {
                        prev = node;
                        node = node->next;
                    } else {
                        if(egwDLListRemove(list_inout, node)) {
                            ++retVal;
                            node = (prev ? prev->next : list_inout->lHead);
                        } else {
                            prev = node;
                            node = node->next;
                        }
                    }
                }
            } else {
                while(node) {
                    EGWint cmpResult = compareFunc((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)), data_in, list_inout->eSize);
                    
                    if(0 != cmpResult) {
                        if(cmpResult > 0)
                            break;
                        prev = node;
                        node = node->next;
                    } else {
                        if(egwDLListRemove(list_inout, node)) {
                            ++retVal;
                            node = (prev ? prev->next : list_inout->lHead);
                        } else {
                            if(cmpResult > 0)
                                break;
                            prev = node;
                            node = node->next;
                        }
                    }
                }
            }
        } break;
        
        case EGW_FIND_MODE_LINTTH: {
            egwDoublyLinkedListNode* node = list_inout->lTail;
            egwDoublyLinkedListNode* prev = NULL;
            
            if(!(findMode_in & EGW_FIND_MODE_ISSORTED)) {
                while(node) {
                    if(0 != compareFunc((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)), data_in, list_inout->eSize)) {
                        prev = node;
                        node = node->prev;
                    } else {
                        if(egwDLListRemove(list_inout, node)) {
                            ++retVal;
                            node = (prev ? prev->prev : list_inout->lTail);
                        } else {
                            prev = node;
                            node = node->prev;
                        }
                    }
                }
            } else {
                while(node) {
                    EGWint cmpResult = compareFunc((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)), data_in, list_inout->eSize);
                    
                    if(0 != cmpResult) {
                        if(cmpResult < 0)
                            break;
                        prev = node;
                        node = node->prev;
                    } else {
                        if(egwDLListRemove(list_inout, node)) {
                            ++retVal;
                            node = (prev ? prev->prev : list_inout->lTail);
                        } else {
                            if(cmpResult < 0)
                                break;
                            prev = node;
                            node = node->prev;
                        }
                    }
                }
            }
        } break;
    }
    
    return retVal;
}

EGWint egwDLListRemoveAll(egwDoublyLinkedList* list_inout) {
    EGWfreefp freeFunc = (list_inout->dFuncs && list_inout->dFuncs->fpFree ? (EGWfreefp)list_inout->dFuncs->fpFree : (EGWfreefp)&free);
    
    while(list_inout->lHead) {
        egwDoublyLinkedListNode* node = list_inout->lHead;
        
        if(list_inout->dFuncs && list_inout->dFuncs->fpRemove)
            list_inout->dFuncs->fpRemove((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)));
        if(list_inout->lFlags & EGW_LIST_FLG_RETAIN)
            [(id<NSObject>)*(void**)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)) release];
        if(list_inout->lFlags & EGW_LIST_FLG_FREE)
            free((void*)*(void**)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)));
        
        list_inout->lHead = list_inout->lHead->next;
        list_inout->lHead->prev = NULL;
        freeFunc(node);
    }
    
    list_inout->eCount = 0;
    list_inout->lHead = list_inout->lTail = NULL;
    
    return 1;
}

EGWint egwDLListPromoteToHead(egwDoublyLinkedList* list_inout, egwDoublyLinkedListNode* node_inout) {
    if(list_inout->lHead != node_inout) {
        if(node_inout == list_inout->lTail) {
            list_inout->lTail = node_inout->prev;
            list_inout->lTail->next = NULL;
        } else {
            node_inout->next->prev = node_inout->prev;
            node_inout->prev->next = node_inout->next;
        }
        
        node_inout->prev = NULL;
        node_inout->next = list_inout->lHead;
        list_inout->lHead->prev = node_inout;
        list_inout->lHead = node_inout;
        
        return 1;
    } else
        return 0;
}

EGWint egwDLListPromoteToTail(egwDoublyLinkedList* list_inout, egwDoublyLinkedListNode* node_inout) {
    if(list_inout->lTail != node_inout) {
        if(node_inout == list_inout->lHead) {
            list_inout->lHead = node_inout->next;
            list_inout->lHead->prev = NULL;
        } else {
            node_inout->next->prev = node_inout->prev;
            node_inout->prev->next = node_inout->next;
        }
        
        node_inout->next = NULL;
        node_inout->prev = list_inout->lTail;
        list_inout->lTail->next = node_inout;
        list_inout->lTail = node_inout;
        
        return 1;
        
    } else
        return 0;
}

void egwDLListGetElement(const egwDoublyLinkedList* list_in, const egwDoublyLinkedListNode* node_in, EGWbyte* data_out) {
    memcpy((void*)data_out, (void*)((EGWuintptr)node_in + (EGWuintptr)sizeof(egwDoublyLinkedListNode)), (size_t)(list_in->eSize));
}

void egwDLListGetElementAt(const egwDoublyLinkedList* list_in, EGWuint index_in, EGWbyte* data_out) {
    if(index_in < list_in->eCount) {
        if(index_in <= list_in->eCount >> 1) {
            register egwDoublyLinkedListNode* node = list_in->lHead;
            
            while(index_in--)
                node = node->next;
            
            memcpy((void*)data_out, (void*)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)), (size_t)(list_in->eSize));
        } else {
            register egwDoublyLinkedListNode* node = list_in->lTail;
            
            index_in = list_in->eCount - (index_in + 1);
            while(index_in--)
                node = node->prev;
            
            memcpy((void*)data_out, (void*)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)), (size_t)(list_in->eSize));
        }
    }
}

void egwDLListGetElementHead(const egwDoublyLinkedList* list_in, EGWbyte* data_out) {
    memcpy((void*)data_out, (void*)((EGWuintptr)(list_in->lHead) + (EGWuintptr)sizeof(egwDoublyLinkedListNode)), (size_t)(list_in->eSize));
}

void egwDLListGetElementTail(const egwDoublyLinkedList* list_in, EGWbyte* data_out) {
    memcpy((void*)data_out, (void*)((EGWuintptr)(list_in->lTail) + (EGWuintptr)sizeof(egwDoublyLinkedListNode)), (size_t)(list_in->eSize));
}

EGWbyte* egwDLListElementPtr(const egwDoublyLinkedListNode* node_in) {
    return (EGWbyte*)((EGWuintptr)node_in + (EGWuintptr)sizeof(egwDoublyLinkedListNode));
}

EGWbyte* egwDLListElementPtrAt(const egwDoublyLinkedList* list_in, EGWuint index_in) {
    if(index_in < list_in->eCount) {
        if(index_in <= list_in->eCount >> 1) {
            register egwDoublyLinkedListNode* node = list_in->lHead;
            
            while(index_in--)
                node = node->next;
            
            return (EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode));
        } else {
            register egwDoublyLinkedListNode* node = list_in->lTail;
            
            index_in = list_in->eCount - (index_in + 1);
            while(index_in--)
                node = node->prev;
            
            return (EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode));
        }
    } else
        return 0;
}

EGWbyte* egwDLListElementPtrHead(const egwDoublyLinkedList* list_in) {
    return (EGWbyte*)((EGWuintptr)(list_in->lHead) + (EGWuintptr)sizeof(egwDoublyLinkedListNode));
}

EGWbyte* egwDLListElementPtrTail(const egwDoublyLinkedList* list_in) {
    return (EGWbyte*)((EGWuintptr)(list_in->lTail) + (EGWuintptr)sizeof(egwDoublyLinkedListNode));
}

egwDoublyLinkedListNode* egwDLListNodePtr(const EGWbyte* data_in) {
    return (egwDoublyLinkedListNode*)((EGWuintptr)data_in - (EGWuintptr)sizeof(egwDoublyLinkedListNode));
}

egwDoublyLinkedListNode* egwDLListFind(const egwDoublyLinkedList* list_in, const EGWbyte* data_in, EGWuint findMode_in) {
    EGWcomparefp compareFunc = (list_in->dFuncs && list_in->dFuncs->fpCompare ? (EGWcomparefp)list_in->dFuncs->fpCompare : (EGWcomparefp)&memcmp);
    
    switch(findMode_in & EGW_FIND_MODE_EXMETHOD) {
        default:
        case EGW_FIND_MODE_LINHTT: {
            egwDoublyLinkedListNode* node = list_in->lHead;
            
            if(!(findMode_in & EGW_FIND_MODE_ISSORTED)) {
                while(node) {
                    if(0 != compareFunc((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)), data_in, list_in->eSize))
                        node = node->next;
                    else
                        return node;
                }
            } else {
                while(node) {
                    EGWint cmpResult = compareFunc((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)), data_in, list_in->eSize);
                    
                    if(0 != cmpResult) {
                        if(cmpResult > 0)
                            return NULL;
                        node = node->next;
                    } else
                        return node;
                }
            }
        } break;
        
        case EGW_FIND_MODE_LINTTH: {
            egwDoublyLinkedListNode* node = list_in->lTail;
            
            if(!(findMode_in & EGW_FIND_MODE_ISSORTED)) {
                while(node) {
                    if(0 != compareFunc((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)), data_in, list_in->eSize))
                        node = node->prev;
                    else
                        return node;
                }
            } else {
                while(node) {
                    EGWint cmpResult = compareFunc((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)), data_in, list_in->eSize);
                    
                    if(0 != cmpResult) {
                        if(cmpResult < 0)
                            return NULL;
                        node = node->prev;
                    } else
                        return node;
                }
            }
        } break;
    }
    
    return NULL;
}

EGWint egwDLListContains(const egwDoublyLinkedList* list_in, const EGWbyte* data_in, EGWuint findMode_in) {
    return (egwDLListFind(list_in, data_in, findMode_in) ? 1 : 0);
}

EGWuint egwDLListOccurances(const egwDoublyLinkedList* list_in, const EGWbyte* data_in, EGWuint findMode_in) {
    EGWuint retVal = 0;
    EGWcomparefp compareFunc = (list_in->dFuncs && list_in->dFuncs->fpCompare ? (EGWcomparefp)list_in->dFuncs->fpCompare : (EGWcomparefp)&memcmp);
    
    switch(findMode_in & EGW_FIND_MODE_EXMETHOD) {
        default:
        case EGW_FIND_MODE_LINHTT: {
            register egwDoublyLinkedListNode* node = list_in->lHead;
            
            if(!(findMode_in & EGW_FIND_MODE_ISSORTED)) {
                while(node) {
                    if(0 == compareFunc((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)), data_in, list_in->eSize))
                        ++retVal;
                    node = node->next;
                }
            } else {
                while(node) {
                    EGWint cmpResult = compareFunc((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)), data_in, list_in->eSize);
                    if(0 == cmpResult)
                        ++retVal;
                    else if(cmpResult > 0)
                        break;
                    node = node->next;
                }
            }
        } break;
            
        case EGW_FIND_MODE_LINTTH: {
            register egwDoublyLinkedListNode* node = list_in->lTail;
            
            if(!(findMode_in & EGW_FIND_MODE_ISSORTED)) {
                while(node) {
                    if(0 == compareFunc((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)), data_in, list_in->eSize))
                        ++retVal;
                    node = node->prev;
                }
            } else {
                while(node) {
                    EGWint cmpResult = compareFunc((EGWbyte*)((EGWuintptr)node + (EGWuintptr)sizeof(egwDoublyLinkedListNode)), data_in, list_in->eSize);
                    if(0 == cmpResult)
                        ++retVal;
                    else if(cmpResult < 0)
                        break;
                    node = node->prev;
                }
            }
        } break;
    }
    
    return retVal;
}

void egwDLListSort(egwDoublyLinkedList* list_inout) {
    if(list_inout->eCount > 1) {
        list_inout->lHead = egwDLListSortRecurse(list_inout, list_inout->lHead);
        
        list_inout->lTail = list_inout->lHead;
        if(list_inout->lTail) {
            list_inout->lHead->prev = NULL;
            
            while(list_inout->lTail->next) {
                list_inout->lTail->next->prev = list_inout->lTail;
                list_inout->lTail = list_inout->lTail->next;
            }
        }
    }
}

EGWint egwDLListEnumerateStart(const egwDoublyLinkedList* list_in, EGWuint iterMode_in, egwDoublyLinkedListIter* iter_out) {
    memset((void*)iter_out, 0, sizeof(egwDoublyLinkedListIter));
    
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

EGWint egwDLListEnumerateGetNext(egwDoublyLinkedListIter* iter_inout, EGWbyte* data_out) {
    EGWbyte* data = egwDLListEnumerateNextPtr(iter_inout);
    
    if(data) {
        memcpy((void*)data_out, (const void*)data, (size_t)iter_inout->pList->eSize);
        return 1;
    } else
        return 0;
}

EGWbyte* egwDLListEnumerateNextPtr(egwDoublyLinkedListIter* iter_inout) {
    if(iter_inout->nPos) {
        EGWbyte* retVal = (EGWbyte*)((EGWuintptr)iter_inout->nPos + (EGWuintptr)sizeof(egwDoublyLinkedListNode));
        
        if(++(iter_inout->eIndex) < iter_inout->pList->eCount - 1) {
            switch(iter_inout->iMode & EGW_ITERATE_MODE_EXLIN) {
                case EGW_ITERATE_MODE_LINHTT: {
                    iter_inout->nPos = iter_inout->nPos->next;
                } break;
                
                case EGW_ITERATE_MODE_LINTTH: {
                    register egwDoublyLinkedListNode* node = iter_inout->pList->lHead;
                    
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

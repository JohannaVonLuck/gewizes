// Copyright (C) 2008-2011 JWmicro. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the follow_ining conditions are met:
//  * Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the follow_ining disclaimer.
//  * Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the follow_ining disclaimer in the
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

/// @file egwCyclicArray.m
/// @ingroup geWizES_data_cyclicarray
/// Cyclic Array Implementation.

#import "egwCyclicArray.h"
#import "../math/egwMath.h"


static void egwCycArraySortRecurse(egwCyclicArray* array_inout, EGWbyte* temp_in, EGWint low_in, EGWint high_in) {
    if(high_in > low_in) {
        EGWcomparefp compareFunc = (array_inout->dFuncs && array_inout->dFuncs->fpCompare ? (EGWcomparefp)(array_inout->dFuncs->fpCompare) : (EGWcomparefp)&memcmp);
        EGWint pivot = (low_in + high_in) >> 1;
        EGWint left = low_in;
        EGWint right = high_in;
        
        while (left <= pivot && right >= pivot) {
            while(left <= pivot && compareFunc((EGWbyte*)((EGWuintptr)array_inout->rData + ((EGWuintptr)((array_inout->pOffset + left) % array_inout->eMaxCount) * (EGWuintptr)array_inout->eSize)),
                                               (EGWbyte*)((EGWuintptr)array_inout->rData + ((EGWuintptr)((array_inout->pOffset + pivot) % array_inout->eMaxCount) * (EGWuintptr)array_inout->eSize)), array_inout->eSize) < 0)
                ++left;
            
            while(right >= pivot && compareFunc((EGWbyte*)((EGWuintptr)array_inout->rData + ((EGWuintptr)((array_inout->pOffset + pivot) % array_inout->eMaxCount) * (EGWuintptr)array_inout->eSize)),
                                                (EGWbyte*)((EGWuintptr)array_inout->rData + ((EGWuintptr)((array_inout->pOffset + right) % array_inout->eMaxCount) * (EGWuintptr)array_inout->eSize)), array_inout->eSize) < 0)
                --right;
            
            memcpy((void*)temp_in, (void*)((EGWuintptr)array_inout->rData + ((EGWuintptr)((array_inout->pOffset + left) % array_inout->eMaxCount) * (EGWuintptr)array_inout->eSize)), (size_t)array_inout->eSize);
            memcpy((void*)((EGWuintptr)array_inout->rData + ((EGWuintptr)((array_inout->pOffset + left) % array_inout->eMaxCount) * (EGWuintptr)array_inout->eSize)),
                   (void*)((EGWuintptr)array_inout->rData + ((EGWuintptr)((array_inout->pOffset + right) % array_inout->eMaxCount) * (EGWuintptr)array_inout->eSize)), (size_t)array_inout->eSize);
            memcpy((void*)((EGWuintptr)array_inout->rData + ((EGWuintptr)((array_inout->pOffset + right) % array_inout->eMaxCount) * (EGWuintptr)array_inout->eSize)), (void*)temp_in, (size_t)array_inout->eSize);
            
            ++left; --right;
            if(left - 1 == pivot)
                pivot = ++right;
            else if(right + 1 == pivot)
                pivot = --left;
        }
        
        egwCycArraySortRecurse(array_inout, temp_in, low_in, pivot-1);
        egwCycArraySortRecurse(array_inout, temp_in, pivot+1, high_in);
    }
}

egwCyclicArray* egwCycArrayInit(egwCyclicArray* array_out, egwDataFuncs* funcs_in, EGWuint elmSize_in, EGWuint intCap_in, EGWuint flags_in) {
    memset((void*)array_out, 0, sizeof(egwCyclicArray));
    
    intCap_in = (EGWuint)egwMax2i(1, (EGWint)(EGWuint16)intCap_in);
    elmSize_in = (EGWuint)egwMax2i(1, (EGWint)(EGWuint16)elmSize_in);
    
    array_out->aFlags = (EGWuint32)flags_in;
    array_out->eSize = (EGWuint16)elmSize_in;
    array_out->eMinCount = array_out->eMaxCount = (EGWuint16)intCap_in;
    
    if(funcs_in) {
        if(!(array_out->dFuncs = (egwDataFuncs*)malloc(sizeof(egwDataFuncs)))) { egwCycArrayFree(array_out); return NULL; }
        memcpy((void*)array_out->dFuncs, (const void*)funcs_in, sizeof(egwDataFuncs));
    }
    
    {   EGWmallocfp mallocFunc = (array_out->dFuncs && array_out->dFuncs->fpMalloc ? (EGWmallocfp)array_out->dFuncs->fpMalloc : (EGWmallocfp)&malloc);
        if(!(array_out->rData = (EGWbyte*)mallocFunc(((size_t)array_out->eSize * (size_t)array_out->eMaxCount)))) { egwCycArrayFree(array_out); return NULL; }
    }
    
    return array_out;
}

egwCyclicArray* egwCycArrayCopy(const egwCyclicArray* array_in, egwCyclicArray* array_out) {
    memset((void*)array_out, 0, sizeof(egwCyclicArray));
    
    if(array_in->aFlags & EGW_ARRAY_FLG_FREE) // Ownership sharing not permitted
        return NULL;
    
    array_out->aFlags = array_in->aFlags;
    array_out->eSize = array_in->eSize;
    array_out->eCount = array_in->eCount;
    array_out->eMinCount = array_in->eMinCount;
    array_out->eMaxCount = (EGWuint16)egwMax2i(egwMax2i(1, (EGWint)array_in->eMaxCount), (EGWint)array_in->eCount);
    
    if(array_in->dFuncs) {
        if(!(array_out->dFuncs = (egwDataFuncs*)malloc(sizeof(egwDataFuncs)))) { egwCycArrayFree(array_out); return NULL; }
        memcpy((void*)(array_out->dFuncs), (const void*)(array_in->dFuncs), sizeof(egwDataFuncs));
    }
    
    {   EGWmallocfp mallocFunc = (array_out->dFuncs && array_out->dFuncs->fpMalloc ? (EGWmallocfp)(array_out->dFuncs->fpMalloc) : (EGWmallocfp)&malloc);
        if(!(array_out->rData = (EGWbyte*)mallocFunc(((size_t)(array_in->eSize) * (size_t)(array_in->eMaxCount))))) { egwCycArrayFree(array_out); return NULL; }
    }
    
    if(array_in->pOffset + array_in->eCount <= array_in->eMaxCount) // enclosed range
        memcpy((void*)(array_out->rData),
               (const void*)((EGWuintptr)(array_in->rData) + ((EGWuintptr)(array_in->pOffset) * (EGWuintptr)(array_in->eSize))),
               (size_t)(array_in->eSize) * (size_t)(array_in->eCount));
    else { // split range
        memcpy((void*)(array_out->rData),
               (const void*)((EGWuintptr)(array_in->rData) + ((EGWuintptr)(array_in->pOffset) * (EGWuintptr)(array_in->eSize))),
               (size_t)(array_in->eSize) * (size_t)(array_in->eMaxCount - array_in->pOffset));
        memcpy((void*)((EGWuintptr)(array_out->rData) + ((EGWuintptr)(array_in->eMaxCount - array_in->pOffset) * (EGWuintptr)(array_out->eSize))),
               (const void*)(array_in->rData),
               (size_t)(array_in->eSize) * (size_t)(array_in->pOffset + array_in->eCount - array_in->eMaxCount));
    }
    
    if(array_out->aFlags & EGW_ARRAY_FLG_RETAIN) {
        EGWuint16 index = array_out->eCount; while(index--)
            [(id<NSObject>)*(void**)((EGWuintptr)(array_out->rData) + ((EGWuintptr)((array_out->pOffset + index) % array_out->eMaxCount) * (EGWuintptr)(array_out->eSize))) retain];
    }
    if(array_out->dFuncs && array_out->dFuncs->fpAdd) {
        EGWuint16 index = array_out->eCount; while(index--)
            array_out->dFuncs->fpAdd((EGWbyte*)((EGWuintptr)(array_out->rData) + ((EGWuintptr)((array_out->pOffset + index) % array_out->eMaxCount) * (EGWuintptr)(array_out->eSize))));
    }
    
    return array_out;
}

egwCyclicArray* egwCycArrayFree(egwCyclicArray* array_inout) {
    if(array_inout->rData) {
        if(array_inout->dFuncs && array_inout->dFuncs->fpRemove) {
            EGWuint16 index = array_inout->eCount; while(index--)
                array_inout->dFuncs->fpRemove((EGWbyte*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)((array_inout->pOffset + index) % array_inout->eMaxCount) * (EGWuintptr)(array_inout->eSize))));
        }
        if(array_inout->aFlags & EGW_ARRAY_FLG_RETAIN) {
            EGWuint16 index = array_inout->eCount; while(index--)
                [(id<NSObject>)*(void**)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)((array_inout->pOffset + index) % array_inout->eMaxCount) * (EGWuintptr)(array_inout->eSize))) release];
        }
        if(array_inout->aFlags & EGW_ARRAY_FLG_FREE) {
            EGWuint16 index = array_inout->eCount; while(index--)
                free((void*)*(void**)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)((array_inout->pOffset + index) % array_inout->eMaxCount) * (EGWuintptr)(array_inout->eSize))));
        }
        
        {   EGWfreefp freeFunc = (array_inout->dFuncs && array_inout->dFuncs->fpFree ? (EGWfreefp)(array_inout->dFuncs->fpFree) : (EGWfreefp)&free);
            freeFunc((void*)(array_inout->rData));
        }
    }
    
    if(array_inout->dFuncs)
        free((void*)(array_inout->dFuncs));
    
    memset((void*)array_inout, 0, sizeof(egwCyclicArray));
    
    return array_inout;
}

EGWint egwCycArrayAddAt(egwCyclicArray* array_inout, EGWuint index_in, const EGWbyte* data_in) {
    if(index_in <= array_inout->eCount) {
        if(egwCycArrayGrowChk(array_inout) && !egwCycArrayGrow(array_inout))
            return 0;
        
        if(array_inout->eCount < array_inout->eMaxCount) {
            if(index_in == 0) { // is head
                if(array_inout->eCount) {
                    // quick shift left
                    array_inout->pOffset = (array_inout->eMaxCount + array_inout->pOffset - 1) % array_inout->eMaxCount;
                }
            } else if(index_in < array_inout->eCount) { // is not tail (tail is quick shift right)
                if(index_in >= (array_inout->eCount + 1) >> 1) { // grow right (shift right)
                    if(array_inout->pOffset + array_inout->eCount + 1 <= array_inout->eMaxCount) // enclosed range
                        memmove((void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->pOffset + index_in + 1) * (EGWuintptr)(array_inout->eSize))),
                                (const void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->pOffset + index_in) * (EGWuintptr)(array_inout->eSize))),
                                (size_t)(array_inout->eSize) * (size_t)(array_inout->eCount - index_in));
                    else { // split range
                        if(array_inout->pOffset + index_in >= array_inout->eMaxCount) // index in second half
                            memmove((void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)((array_inout->pOffset + index_in + 1) - array_inout->eMaxCount) * (EGWuintptr)(array_inout->eSize))),
                                    (const void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)((array_inout->pOffset + index_in) - array_inout->eMaxCount) * (EGWuintptr)(array_inout->eSize))),
                                    (size_t)(array_inout->eSize) * (size_t)(array_inout->eCount - index_in));
                        else { // index in first half
                            memmove((void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)1 * (EGWuintptr)(array_inout->eSize))), // shift second half by 1
                                    (const void*)(array_inout->rData),
                                    (size_t)(array_inout->eSize) * (size_t)((array_inout->pOffset + array_inout->eCount) - array_inout->eMaxCount));
                            memcpy((void*)(array_inout->rData), // copy end to head
                                   (const void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->eMaxCount - 1) * (EGWuintptr)(array_inout->eSize))),
                                   (size_t)(array_inout->eSize) * (size_t)1);
                            memmove((void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->pOffset + index_in + 1) * (EGWuintptr)(array_inout->eSize))),
                                    (const void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->pOffset + index_in) * (EGWuintptr)(array_inout->eSize))),
                                    (size_t)(array_inout->eSize) * (size_t)(array_inout->eMaxCount - (array_inout->pOffset + index_in + 1)));
                        }
                    }
                } else { // grow left (shift left)
                    if(array_inout->pOffset) {
                        if(array_inout->pOffset + array_inout->eCount <= array_inout->eMaxCount) // enclosed range
                            memmove((void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->pOffset - 1) * (EGWuintptr)(array_inout->eSize))),
                                    (const void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->pOffset) * (EGWuintptr)(array_inout->eSize))),
                                    (size_t)(array_inout->eSize) * (size_t)index_in);
                        else { // split range
                                if(array_inout->pOffset + index_in >= array_inout->eMaxCount) { // index in second half
                                    memmove((void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->pOffset - 1) * (EGWuintptr)(array_inout->eSize))),
                                            (const void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->pOffset) * (EGWuintptr)(array_inout->eSize))),
                                            (size_t)(array_inout->eSize) * (size_t)(array_inout->eMaxCount - array_inout->pOffset));
                                    memcpy((void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->eMaxCount - 1) * (EGWuintptr)(array_inout->eSize))), // copy end to head
                                           (const void*)(array_inout->rData),
                                           (size_t)(array_inout->eSize) * (size_t)1);
                                    memmove((void*)(array_inout->rData), // shift second half by 1
                                            (const void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)1 * (EGWuintptr)(array_inout->eSize))),
                                            (size_t)(array_inout->eSize) * (size_t)((array_inout->pOffset + index_in) - array_inout->eMaxCount));
                                } else // index in first half
                                    memmove((void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->pOffset - 1) * (EGWuintptr)(array_inout->eSize))),
                                            (const void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->pOffset) * (EGWuintptr)(array_inout->eSize))),
                                            (size_t)(array_inout->eSize) * (size_t)index_in);
                        }
                    } else { // special case
                        if(index_in) {
                            memcpy((void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->eMaxCount - 1) * (EGWuintptr)(array_inout->eSize))), // copy end to head
                                   (const void*)(array_inout->rData),
                                   (size_t)(array_inout->eSize) * (size_t)1);
                            memmove((void*)(array_inout->rData), // shift second half by 1
                                    (const void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)1 * (EGWuintptr)(array_inout->eSize))),
                                    (size_t)(array_inout->eSize) * (size_t)(index_in - 1));
                        }
                    }
                    
                    array_inout->pOffset = (array_inout->eMaxCount + array_inout->pOffset - 1) % array_inout->eMaxCount;
                }
            }
            
            if(data_in)
                memcpy((void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)((array_inout->pOffset + index_in) % array_inout->eMaxCount) * (EGWuintptr)(array_inout->eSize))),
                       (const void*)data_in,
                       (size_t)(array_inout->eSize));
            
            ++(array_inout->eCount);
            
            if(data_in && array_inout->aFlags & EGW_ARRAY_FLG_RETAIN)
                [(id<NSObject>)*(void**)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)((array_inout->pOffset + index_in) % array_inout->eMaxCount) * (EGWuintptr)(array_inout->eSize))) retain];
            if(array_inout->dFuncs && array_inout->dFuncs->fpAdd)
                array_inout->dFuncs->fpAdd((EGWbyte*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)((array_inout->pOffset + index_in) % array_inout->eMaxCount) * (EGWuintptr)(array_inout->eSize))));
            
            return 1;
        }
    }
    
    return 0;
}

EGWint egwCycArrayAddHead(egwCyclicArray* array_inout, const EGWbyte* data_in) {
    return egwCycArrayAddAt(array_inout, 0, data_in);
}

EGWint egwCycArrayAddTail(egwCyclicArray* array_inout, const EGWbyte* data_in) {
    return egwCycArrayAddAt(array_inout, array_inout->eCount, data_in);
}

EGWint egwCycArrayRemoveAt(egwCyclicArray* array_inout, EGWuint index_in) {
    if(index_in < array_inout->eCount) {
        if(array_inout->eCount > 0) {
            if(array_inout->dFuncs && array_inout->dFuncs->fpRemove)
                array_inout->dFuncs->fpRemove((EGWbyte*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)((array_inout->pOffset + index_in) % array_inout->eMaxCount) * (EGWuintptr)(array_inout->eSize))));
            if(array_inout->aFlags & EGW_ARRAY_FLG_RETAIN)
                [(id<NSObject>)*(void**)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)((array_inout->pOffset + index_in) % array_inout->eMaxCount) * (EGWuintptr)(array_inout->eSize))) release];
            if(array_inout->aFlags & EGW_ARRAY_FLG_FREE)
                free((void*)*(void**)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)((array_inout->pOffset + index_in) % array_inout->eMaxCount) * (EGWuintptr)(array_inout->eSize))));
            
            if(index_in == 0) { // is head
                if(array_inout->eCount) {
                    // quick shift right
                    array_inout->pOffset = (array_inout->pOffset + 1) % array_inout->eMaxCount;
                }
            } else if(index_in < array_inout->eCount - 1) { // is not tail (tail is quick shift left)
                if(index_in >= array_inout->eCount >> 1) { // shrink right (shift left)
                    if(array_inout->pOffset + array_inout->eCount <= array_inout->eMaxCount) // enclosed range
                        memmove((void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->pOffset + index_in) * (EGWuintptr)(array_inout->eSize))),
                                (const void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->pOffset + index_in + 1) * (EGWuintptr)(array_inout->eSize))),
                                (size_t)(array_inout->eSize) * (size_t)(array_inout->eCount - (index_in + 1)));
                    else { // split range
                        if(array_inout->pOffset + index_in >= array_inout->eMaxCount) // index in second half
                            memmove((void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)((array_inout->pOffset + index_in) - array_inout->eMaxCount) * (EGWuintptr)(array_inout->eSize))),
                                    (const void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)((array_inout->pOffset + index_in + 1) - array_inout->eMaxCount) * (EGWuintptr)(array_inout->eSize))),
                                    (size_t)(array_inout->eSize) * (size_t)(array_inout->eCount - (index_in + 1)));
                        else { // index in first half
                            memmove((void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->pOffset + index_in) * (EGWuintptr)(array_inout->eSize))),
                                    (const void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->pOffset + index_in + 1) * (EGWuintptr)(array_inout->eSize))),
                                    (size_t)(array_inout->eSize) * (size_t)(array_inout->eMaxCount - (array_inout->pOffset + index_in + 1)));
                            memcpy((void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->eMaxCount - 1) * (EGWuintptr)(array_inout->eSize))), // copy end to head
                                   (const void*)(array_inout->rData),
                                   (size_t)(array_inout->eSize) * (size_t)1);
                            memmove((void*)(array_inout->rData), // shift second half by 1
                                    (const void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)1 * (EGWuintptr)(array_inout->eSize))),
                                    (size_t)(array_inout->eSize) * (size_t)((array_inout->pOffset + array_inout->eCount - 1) - array_inout->eMaxCount));
                        }
                    }
                } else { // shrink left (shift right)
                    if(array_inout->pOffset + array_inout->eCount <= array_inout->eMaxCount) // enclosed range
                        memmove((void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->pOffset + 1) * (EGWuintptr)(array_inout->eSize))),
                                (const void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->pOffset) * (EGWuintptr)(array_inout->eSize))),
                                (size_t)(array_inout->eSize) * (size_t)index_in);
                    else { // split range
                        if(array_inout->pOffset + index_in >= array_inout->eMaxCount) { // index in second half
                            memmove((void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)1 * (EGWuintptr)(array_inout->eSize))), // shift second half by 1
                                    (const void*)(array_inout->rData),
                                    (size_t)(array_inout->eSize) * (size_t)((array_inout->pOffset + index_in) - array_inout->eMaxCount));
                            memcpy((void*)(array_inout->rData), // copy end to head
                                   (const void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->eMaxCount - 1) * (EGWuintptr)(array_inout->eSize))),
                                   (size_t)(array_inout->eSize) * (size_t)1);
                            memmove((void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->pOffset + 1) * (EGWuintptr)(array_inout->eSize))),
                                    (const void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->pOffset) * (EGWuintptr)(array_inout->eSize))),
                                    (size_t)(array_inout->eSize) * (size_t)(array_inout->eMaxCount - (array_inout->pOffset + 1)));
                        } else // index in first half
                            memmove((void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->pOffset + 1) * (EGWuintptr)(array_inout->eSize))),
                                    (const void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->pOffset) * (EGWuintptr)(array_inout->eSize))),
                                    (size_t)(array_inout->eSize) * (size_t)index_in);
                    }
                    
                    array_inout->pOffset = (array_inout->pOffset + 1) % array_inout->eMaxCount;
                }
            }
            
            --(array_inout->eCount);
            
            if(array_inout->eCount == 0)
                array_inout->pOffset = 0;
            
            if(egwCycArrayShrinkChk(array_inout) && !egwCycArrayShrink(array_inout))
                return 0;
            
            return 1;
        }
    }
    
    return 0;
}

EGWint egwCycArrayRemoveHead(egwCyclicArray* array_inout) {
    return egwCycArrayRemoveAt(array_inout, 0);
}

EGWint egwCycArrayRemoveTail(egwCyclicArray* array_inout) {
    return egwCycArrayRemoveAt(array_inout, (array_inout->eCount ? array_inout->eCount - 1 : 0));
}

EGWint egwCycArrayRemoveAll(egwCyclicArray* array_inout) {
    if(array_inout->eCount) {
        if(array_inout->dFuncs && array_inout->dFuncs->fpRemove) {
            EGWuint16 index = array_inout->eCount; while(index--)
                array_inout->dFuncs->fpRemove((EGWbyte*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)((array_inout->pOffset + index) % array_inout->eMaxCount) * (EGWuintptr)(array_inout->eSize))));
        }
        if(array_inout->aFlags & EGW_ARRAY_FLG_RETAIN) {
            EGWuint16 index = array_inout->eCount; while(index--)
                [(id<NSObject>)*(void**)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)((array_inout->pOffset + index) % array_inout->eMaxCount) * (EGWuintptr)(array_inout->eSize))) release];
        }
        if(array_inout->aFlags & EGW_ARRAY_FLG_FREE) {
            EGWuint16 index = array_inout->eCount; while(index--)
                free((void*)*(void**)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)((array_inout->pOffset + index) % array_inout->eMaxCount) * (EGWuintptr)(array_inout->eSize))));
        }
        
        if((array_inout->aFlags & EGW_ARRAY_FLG_EXSHRNKCND) && (array_inout->aFlags & EGW_ARRAY_FLG_EXSHRNKBY)) {
            while((array_inout->eCount)--)
                if(egwCycArrayShrinkChk(array_inout)) {
                    EGWuint16 count = array_inout->eCount;
                    array_inout->eCount = 0;
                    egwCycArrayShrink(array_inout);
                    array_inout->eCount = (EGWuint16)egwMin2i((EGWint)count, (EGWint)(array_inout->eMaxCount));
                }
        }
        
        array_inout->eCount = 0;
        
        return 1;
    } else
        return 0;
}

void egwCycArrayGetElementAt(const egwCyclicArray* array_in, EGWuint index_in, EGWbyte* data_out) {
    memcpy((void*)data_out,
           (const void*)((EGWuintptr)(array_in->rData) + ((EGWuintptr)((array_in->pOffset + index_in) % array_in->eMaxCount) * (EGWuintptr)(array_in->eSize))),
           (size_t)(array_in->eSize));
}

void egwCycArrayGetElementHead(const egwCyclicArray* array_in, EGWbyte* data_out) {
    memcpy((void*)data_out,
           (const void*)((EGWuintptr)(array_in->rData) + ((EGWuintptr)((array_in->pOffset + 0) % array_in->eMaxCount) * (EGWuintptr)(array_in->eSize))),
           (size_t)(array_in->eSize));
}

void egwCycArrayGetElementTail(const egwCyclicArray* array_in, EGWbyte* data_out) {
    memcpy((void*)data_out,
           (const void*)((EGWuintptr)(array_in->rData) + ((EGWuintptr)((array_in->pOffset + (array_in->eCount ? array_in->eCount - 1 : 0)) % array_in->eMaxCount) * (EGWuintptr)(array_in->eSize))),
           (size_t)(array_in->eSize));
}

EGWbyte* egwCycArrayElementPtrAt(const egwCyclicArray* array_in, EGWuint index_in) {
    return (EGWbyte*)((EGWuintptr)(array_in->rData) + ((EGWuintptr)((array_in->pOffset + index_in) % array_in->eMaxCount) * (EGWuintptr)(array_in->eSize)));
}

EGWbyte* egwCycArrayElementPtrHead(const egwCyclicArray* array_in) {
    return (EGWbyte*)((EGWuintptr)(array_in->rData) + ((EGWuintptr)(array_in->pOffset) * (EGWuintptr)(array_in->eSize)));
}

EGWbyte* egwCycArrayElementPtrTail(const egwCyclicArray* array_in) {
    return (EGWbyte*)((EGWuintptr)(array_in->rData) + ((EGWuintptr)((array_in->eMaxCount + array_in->pOffset + (array_in->eCount ? array_in->eCount - 1 : 0)) % array_in->eMaxCount) * (EGWuintptr)(array_in->eSize)));
}

EGWint egwCycArrayFind(const egwCyclicArray* array_in, const EGWbyte* data_in, EGWuint findMode_in) {
    EGWcomparefp compareFunc = (array_in->dFuncs && array_in->dFuncs->fpCompare ? (EGWcomparefp)(array_in->dFuncs->fpCompare) : (EGWcomparefp)&memcmp);
    
    switch(findMode_in & EGW_FIND_MODE_EXMETHOD) {
        case EGW_FIND_MODE_BINARY: {
            EGWint min = 0;
            EGWint max = array_in->eCount - 1;
            EGWint mid = min + ((max - min) >> 1);
            EGWint cmpResult = -1;
            
            while(min < max) {
                cmpResult = compareFunc((EGWbyte*)((EGWuintptr)array_in->rData + ((EGWuintptr)((array_in->pOffset + mid) % array_in->eMaxCount) * (EGWuintptr)array_in->eSize)), data_in, array_in->eSize);
                
                if(cmpResult >= 0)
                    max = mid - 1;
                else
                    min = mid + 1;
                mid = min + ((max - min) >> 1);
            }
            
            if(cmpResult == 0)
                return mid;
        } break;
        
        default:
        case EGW_FIND_MODE_LINHTT: {
            register EGWbyte* node = (EGWbyte*)((EGWuintptr)array_in->rData + ((EGWuintptr)((array_in->pOffset + 0) % array_in->eMaxCount) * (EGWuintptr)array_in->eSize));
            EGWbyte* tail = (EGWbyte*)((EGWuintptr)array_in->rData + ((EGWuintptr)(array_in->eMaxCount - 1) * (EGWuintptr)array_in->eSize));
            
            if(!(findMode_in & EGW_FIND_MODE_ISSORTED)) {
                EGWint count = array_in->eCount;
                while(count--) {
                    if(0 != compareFunc(node, data_in, array_in->eSize)) {
                        node = (EGWbyte*)((EGWuintptr)node + (EGWuintptr)array_in->eSize);
                        if(node > tail)
                            node = array_in->rData;
                    } else
                        return array_in->eCount - (count + 1);
                }
            } else {
                EGWint count = array_in->eCount;
                while(count--) {
                    EGWint cmpValue = compareFunc(node, data_in, array_in->eSize);
                    if(0 != cmpValue) {
                        if(cmpValue > 0)
                            return -1;
                        node = (EGWbyte*)((EGWuintptr)node + (EGWuintptr)array_in->eSize);
                        if(node > tail)
                            node = array_in->rData;
                    }
                    else
                        return array_in->eCount - (count + 1);
                }
            }
        } break;
        
        case EGW_FIND_MODE_LINTTH: {
            register EGWbyte* node = (EGWbyte*)((EGWuintptr)array_in->rData + ((EGWuintptr)((array_in->pOffset + (array_in->eCount - 1)) % array_in->eMaxCount) * (EGWuintptr)array_in->eSize));
            EGWbyte* tail = (EGWbyte*)((EGWuintptr)array_in->rData + ((EGWuintptr)(array_in->eMaxCount - 1) * (EGWuintptr)array_in->eSize));
            
            if(!(findMode_in & EGW_FIND_MODE_ISSORTED)) {
                EGWint count = array_in->eCount;
                while(count--) {
                    if(0 != compareFunc(node, data_in, array_in->eSize)) {
                        node = (EGWbyte*)((EGWuintptr)node - (EGWuintptr)array_in->eSize);
                        if(node < array_in->rData)
                            node = tail;
                    } else
                        return count;
                }
            } else {
                EGWint count = array_in->eCount;
                while(count--) {
                    EGWint cmpValue = compareFunc(node, data_in, array_in->eSize);
                    if(0 != cmpValue) {
                        if(cmpValue < 0)
                            return -1;
                        node = (EGWbyte*)((EGWuintptr)node - (EGWuintptr)array_in->eSize);
                        if(node < array_in->rData)
                            node = tail;
                    }
                    else
                        return count;
                }
            }
        } break;
    }
    
    return -1;
}

EGWint egwCycArrayContains(const egwCyclicArray* array_in, const EGWbyte* data_in, EGWuint findMode_in) {
    return (egwCycArrayFind(array_in, data_in, findMode_in) != -1 ? 1 : 0);
}

EGWuint egwCycArrayOccurances(const egwCyclicArray* array_in, const EGWbyte* data_in, EGWuint findMode_in) {
    EGWuint retVal = 0;
    EGWcomparefp compareFunc = (array_in->dFuncs && array_in->dFuncs->fpCompare ? (EGWcomparefp)(array_in->dFuncs->fpCompare) : (EGWcomparefp)&memcmp);
    
    switch(findMode_in & EGW_FIND_MODE_EXMETHOD) {
        case EGW_FIND_MODE_BINARY: {
            EGWint min = 0;
            EGWint max = array_in->eCount - 1;
            EGWint mid = min + ((max - min) >> 1);
            EGWint cmpResult = -1;
            
            while(min < max) {
                cmpResult = compareFunc((EGWbyte*)((EGWuintptr)array_in->rData + ((EGWuintptr)((array_in->pOffset + mid) % array_in->eMaxCount) * (EGWuintptr)array_in->eSize)), data_in, array_in->eSize);
                
                if(cmpResult >= 0)
                    max = mid - 1;
                else
                    min = mid + 1;
                mid = min + ((max - min) >> 1);
            }
            
            // Switch over to forward sweep mode
            if(cmpResult == 0) {
                register EGWbyte* node = (EGWbyte*)((EGWuintptr)array_in->rData + ((EGWuintptr)((array_in->pOffset + mid) % array_in->eMaxCount) * (EGWuintptr)array_in->eSize));
                EGWbyte* tail = (EGWbyte*)((EGWuintptr)array_in->rData + ((EGWuintptr)(array_in->eMaxCount - 1) * (EGWuintptr)array_in->eSize));
                
                EGWint count = array_in->eCount - mid;
                while(count--) {
                    EGWint cmpValue = compareFunc(node, data_in, array_in->eSize);
                    if(0 == cmpValue)
                        ++retVal;
                    else if(cmpValue > 0)
                        break;
                    node = (EGWbyte*)((EGWuintptr)node + (EGWuintptr)array_in->eSize);
                    if(node > tail)
                        node = array_in->rData;
                }
            }
        } break;
        
        default:
        case EGW_FIND_MODE_LINHTT: {
            register EGWbyte* node = (EGWbyte*)((EGWuintptr)array_in->rData + ((EGWuintptr)((array_in->pOffset + 0) % array_in->eMaxCount) * (EGWuintptr)array_in->eSize));
            EGWbyte* tail = (EGWbyte*)((EGWuintptr)array_in->rData + ((EGWuintptr)(array_in->eMaxCount - 1) * (EGWuintptr)array_in->eSize));
            
            if(!(findMode_in & EGW_FIND_MODE_ISSORTED)) {
                EGWint count = array_in->eCount;
                while(count--) {
                    if(0 == compareFunc(node, data_in, array_in->eSize))
                        ++retVal;
                    node = (EGWbyte*)((EGWuintptr)node + (EGWuintptr)array_in->eSize);
                    if(node > tail)
                        node = array_in->rData;
                }
            } else {
                EGWint count = array_in->eCount;
                while(count--) {
                    EGWint cmpValue = compareFunc(node, data_in, array_in->eSize);
                    if(0 == cmpValue)
                        ++retVal;
                    else if(cmpValue > 0)
                        break;
                    node = (EGWbyte*)((EGWuintptr)node + (EGWuintptr)array_in->eSize);
                    if(node > tail)
                        node = array_in->rData;
                }
            }
        } break;
        
        case EGW_FIND_MODE_LINTTH: {
            register EGWbyte* node = (EGWbyte*)((EGWuintptr)array_in->rData + ((EGWuintptr)((array_in->pOffset + (array_in->eCount - 1)) % array_in->eMaxCount) * (EGWuintptr)array_in->eSize));
            EGWbyte* tail = (EGWbyte*)((EGWuintptr)array_in->rData + ((EGWuintptr)(array_in->eMaxCount - 1) * (EGWuintptr)array_in->eSize));
            
            if(!(findMode_in & EGW_FIND_MODE_ISSORTED)) {
                EGWint count = array_in->eCount;
                while(count--) {
                    if(0 == compareFunc(node, data_in, array_in->eSize))
                        ++retVal;
                    node = (EGWbyte*)((EGWuintptr)node - (EGWuintptr)array_in->eSize);
                    if(node < array_in->rData)
                        node = tail;
                }
            } else {
                EGWint count = array_in->eCount;
                while(count--) {
                    EGWint cmpValue = compareFunc(node, data_in, array_in->eSize);
                    if(0 == cmpValue)
                        ++retVal;
                    else if(cmpValue < 0)
                        break;
                    node = (EGWbyte*)((EGWuintptr)node - (EGWuintptr)array_in->eSize);
                    if(node < array_in->rData)
                        node = tail;
                }
            }
        } break;
    }
    
    return retVal;
}

EGWint egwCycArrayResize(egwCyclicArray* array_inout, EGWuint newCap_in) {
    newCap_in = egwMax2ui(1, egwMin2ui(newCap_in, EGW_UINT16_MAX));
    if(array_inout->aFlags & EGW_ARRAY_FLG_USEMIN)
        newCap_in = egwMax2ui(array_inout->eMinCount, newCap_in);
    
    if(array_inout->eMaxCount != newCap_in) {
        if(array_inout->eCount) {
            EGWbyte* newRData;
            
            {   EGWmallocfp mallocFunc = (array_inout->dFuncs && array_inout->dFuncs->fpMalloc ? (EGWmallocfp)(array_inout->dFuncs->fpMalloc) : (EGWmallocfp)&malloc);
                if(!(newRData = (EGWbyte*)mallocFunc(((size_t)(array_inout->eSize) * (size_t)newCap_in)))) { return 0; }
            }
            
            if(array_inout->eCount > newCap_in) {
                if(array_inout->dFuncs && array_inout->dFuncs->fpRemove) {
                    EGWuint16 index = array_inout->eCount; while(index-- > (EGWuint16)newCap_in)
                        array_inout->dFuncs->fpRemove((EGWbyte*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)((array_inout->pOffset + index) % array_inout->eMaxCount) * (EGWuintptr)(array_inout->eSize))));
                }
                if(array_inout->aFlags & EGW_ARRAY_FLG_RETAIN) {
                    EGWuint16 index = array_inout->eCount; while(index-- > (EGWuint16)newCap_in)
                        [(id<NSObject>)*(void**)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)((array_inout->pOffset + index) % array_inout->eMaxCount) * (EGWuintptr)(array_inout->eSize))) release];
                }
                if(array_inout->aFlags & EGW_ARRAY_FLG_FREE) {
                    EGWuint16 index = array_inout->eCount; while(index-- > (EGWuint16)newCap_in)
                        free((void*)*(void**)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)((array_inout->pOffset + index) % array_inout->eMaxCount) * (EGWuintptr)(array_inout->eSize))));
                }
                
                array_inout->eCount = newCap_in;
            }
            
            if(array_inout->pOffset + array_inout->eCount <= array_inout->eMaxCount) // enclosed range
                memcpy((void*)newRData,
                       (const void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->pOffset) * (EGWuintptr)(array_inout->eSize))),
                       (size_t)(array_inout->eSize) * (size_t)(array_inout->eCount));
            else { // split range
                memcpy((void*)newRData,
                       (const void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(array_inout->pOffset) * (EGWuintptr)(array_inout->eSize))),
                       (size_t)(array_inout->eSize) * (size_t)(array_inout->eMaxCount - array_inout->pOffset));
                memcpy((void*)((EGWuintptr)newRData + ((EGWuintptr)(array_inout->eMaxCount - array_inout->pOffset) * (EGWuintptr)(array_inout->eSize))),
                       (const void*)(array_inout->rData),
                       (size_t)(array_inout->eSize) * (size_t)(array_inout->pOffset + array_inout->eCount - array_inout->eMaxCount));
            }
            
            array_inout->pOffset = 0;
            array_inout->eMaxCount = 0;
            
            {   EGWfreefp freeFunc = (array_inout->dFuncs && array_inout->dFuncs->fpFree ? (EGWfreefp)(array_inout->dFuncs->fpFree) : (EGWfreefp)&free);
                freeFunc((void*)array_inout->rData);
            }
            array_inout->rData = newRData;
        } else {
            // NOTE: In low_in memory situations, it's better to free first then malloc, if possible -jw
            array_inout->pOffset = 0;
            array_inout->eMaxCount = 0;
            
            {   EGWfreefp freeFunc = (array_inout->dFuncs && array_inout->dFuncs->fpFree ? (EGWfreefp)(array_inout->dFuncs->fpFree) : (EGWfreefp)&free);
                freeFunc((void*)array_inout->rData); array_inout->rData = NULL;
            }
            {   EGWmallocfp mallocFunc = (array_inout->dFuncs && array_inout->dFuncs->fpMalloc ? (EGWmallocfp)(array_inout->dFuncs->fpMalloc) : (EGWmallocfp)&malloc);
                if(!(array_inout->rData = (EGWbyte*)mallocFunc(((size_t)(array_inout->eSize) * (size_t)newCap_in)))) { return 0; }
            }
        }
        
        array_inout->eMaxCount = (EGWuint16)newCap_in;
    }
    
    return 1;
}

EGWint egwCycArrayGrowChk(const egwCyclicArray* array_in) {
    switch(array_in->aFlags & EGW_ARRAY_FLG_EXGROWCND) {
        case EGW_ARRAY_FLG_GRWCND100: {
            if(array_in->eCount >= array_in->eMaxCount)
                return 1;
        } break;
        
        case EGW_ARRAY_FLG_GRWCND90: {
            if(array_in->eCount >= ((array_in->eMaxCount * 9) / 10))
                return 1;
        } break;
        
        case EGW_ARRAY_FLG_GRWCND75: {
            if(array_in->eCount >= ((array_in->eMaxCount * 3) >> 2))
                return 1;
        } break;
        
        case EGW_ARRAY_FLG_GRWCND66: {
            if(array_in->eCount >= ((array_in->eMaxCount << 1) / 3))
                return 1;
        } break;
        
        case EGW_ARRAY_FLG_GRWCND50: {
            if(array_in->eCount >= (array_in->eMaxCount >> 1))
                return 1;
        } break;
    }
    
    return 0;
}

EGWint egwCycArrayShrinkChk(const egwCyclicArray* array_in) {
    switch(array_in->aFlags & EGW_ARRAY_FLG_EXSHRNKCND) {
        case EGW_ARRAY_FLG_SHRKCND00: {
            if(array_in->eCount <= 0)
                return 1;
        } break;
            
        case EGW_ARRAY_FLG_SHRKCND10: {
            if(array_in->eCount <= (array_in->eMaxCount / 10))
                return 1;
        } break;
            
        case EGW_ARRAY_FLG_SHRKCND25: {
            if(array_in->eCount <= (array_in->eMaxCount >> 2))
                return 1;
        } break;
            
        case EGW_ARRAY_FLG_SHRKCND33: {
            if(array_in->eCount <= (array_in->eMaxCount / 3))
                return 1;
        } break;
            
        case EGW_ARRAY_FLG_SHRKCND50: {
            if(array_in->eCount <= (array_in->eMaxCount >> 1))
                return 1;
        } break;
    }
    
    return 0;
}

EGWint egwCycArrayGrow(egwCyclicArray* array_inout) {
    switch(array_inout->aFlags & EGW_ARRAY_FLG_EXGROWBY) {
        case EGW_ARRAY_FLG_GROWBY2X: {
            return egwCycArrayResize(array_inout, array_inout->eMaxCount * 2);
        } break;
            
        case EGW_ARRAY_FLG_GROWBY3X: {
            return egwCycArrayResize(array_inout, array_inout->eMaxCount * 3);
        } break;
            
        case EGW_ARRAY_FLG_GROWBY10: {
            return egwCycArrayResize(array_inout, array_inout->eMaxCount + 10);
        } break;
            
        case EGW_ARRAY_FLG_GROWBY25: {
            return egwCycArrayResize(array_inout, array_inout->eMaxCount + 25);
        } break;
        
        case EGW_ARRAY_FLG_GROWBYSQRD: {
            return egwCycArrayResize(array_inout, array_inout->eMaxCount * array_inout->eMaxCount);
        } break;
    }
    
    return 0;
}

EGWint egwCycArrayShrink(egwCyclicArray* array_inout) {
    switch(array_inout->aFlags & EGW_ARRAY_FLG_EXSHRNKBY) {
        case EGW_ARRAY_FLG_SHRNKBY2X: {
            return egwCycArrayResize(array_inout, array_inout->eMaxCount >> 1);
        } break;
        
        case EGW_ARRAY_FLG_SHRNKBY3X: {
            return egwCycArrayResize(array_inout, array_inout->eMaxCount / 3);
        } break;
        
        case EGW_ARRAY_FLG_SHRNKBY10: {
            return egwCycArrayResize(array_inout, (array_inout->eMaxCount >= 10 ? array_inout->eMaxCount - 10 : 0));
        } break;
        
        case EGW_ARRAY_FLG_SHRNKBY25: {
            return egwCycArrayResize(array_inout, (array_inout->eMaxCount >= 25 ? array_inout->eMaxCount - 25 : 0));
        } break;
        
        case EGW_ARRAY_FLG_SHRNKBYSQRT: {
            return egwCycArrayResize(array_inout, egwSqrtd(array_inout->eMaxCount));
        } break;
    }
    
    return 0;
}

EGWint egwCycArraySort(egwCyclicArray* array_inout) {
    EGWbyte* temp_in = malloc((size_t)array_inout->eSize);
    
    if(temp_in) {
        if(array_inout->eCount > 1)
            egwCycArraySortRecurse(array_inout, temp_in, 0, array_inout->eCount - 1);
        
        free((void*)temp_in);
        return 1;
    }
    
    return 0;
}

EGWint egwCycArrayEnumerateStart(const egwCyclicArray* array_in, EGWuint iterMode_in, egwCyclicArrayIter* iter_out) {
    if(array_in->eCount) {
        iter_out->pArray = array_in;
        iter_out->nPos = NULL;
        iter_out->iMode = iterMode_in;
        iter_out->eIndex = -1;
        
        switch(iter_out->iMode & EGW_ITERATE_MODE_EXLIN) {
            case EGW_ITERATE_MODE_LINHTT: {
                iter_out->nPos = (EGWbyte*)((EGWuintptr)(array_in->rData) + ((EGWuintptr)((array_in->eMaxCount + array_in->pOffset) % array_in->eMaxCount) * (EGWuintptr)(array_in->eSize)));
            } break;
            
            case EGW_ITERATE_MODE_LINTTH: {
                iter_out->nPos = (EGWbyte*)((EGWuintptr)(array_in->rData) + ((EGWuintptr)((array_in->eMaxCount + array_in->pOffset + array_in->eCount - 1) % array_in->eMaxCount) * (EGWuintptr)(array_in->eSize)));
            } break;
        }
        
        return 1;
    } else
        return 0;
}

EGWint egwCycArrayEnumerateGetNext(egwCyclicArrayIter* iter_inout, EGWbyte* data_out) {
    EGWbyte* data = egwCycArrayEnumerateNextPtr(iter_inout);
    
    if(data) {
        memcpy((void*)data_out, (const void*)data, (size_t)(iter_inout->pArray->eSize));
        return 1;
    } else
        return 0;
}

EGWbyte* egwCycArrayEnumerateNextPtr(egwCyclicArrayIter* iter_inout) {
    if(iter_inout->nPos) {
        EGWbyte* retVal = iter_inout->nPos;
        
        if(++(iter_inout->eIndex) < iter_inout->pArray->eCount - 1) {
            switch(iter_inout->iMode & EGW_ITERATE_MODE_EXLIN) {
                case EGW_ITERATE_MODE_LINHTT: {
                    iter_inout->nPos = (EGWbyte*)((EGWuintptr)(iter_inout->pArray->rData) + ((EGWuintptr)((iter_inout->pArray->eMaxCount + iter_inout->pArray->pOffset + iter_inout->eIndex + 1) % iter_inout->pArray->eMaxCount) * (EGWuintptr)(iter_inout->pArray->eSize)));
                } break;
                
                case EGW_ITERATE_MODE_LINTTH: {
                    iter_inout->nPos = (EGWbyte*)((EGWuintptr)(iter_inout->pArray->rData) + ((EGWuintptr)((iter_inout->pArray->eMaxCount + iter_inout->pArray->pOffset + iter_inout->pArray->eCount - (iter_inout->eIndex + 1)) % iter_inout->pArray->eMaxCount) * (EGWuintptr)(iter_inout->pArray->eSize)));
                } break;
            }
        } else
            iter_inout->nPos = NULL;
        
        return retVal;
    }
    
    return NULL;
}

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

/// @file egwArray.m
/// @ingroup geWizES_data_array
/// Array Implementation.

#import "egwArray.h"
#import "../math/egwMath.h"


static void egwArraySortRecurse(egwArray* array_inout, EGWbyte* temp, EGWint low, EGWint high) {
    if(high > low) {
        EGWcomparefp compareFunc = (array_inout->dFuncs && array_inout->dFuncs->fpCompare ? (EGWcomparefp)(array_inout->dFuncs->fpCompare) : (EGWcomparefp)&memcmp);
        EGWint pivot = (low + high) >> 1;
        EGWint left = low;
        EGWint right = high;
        
        while (left <= pivot && right >= pivot) {
            while(left <= pivot && compareFunc((EGWbyte*)((EGWuintptr)array_inout->rData + ((EGWuintptr)left * (EGWuintptr)array_inout->eSize)),
                                               (EGWbyte*)((EGWuintptr)array_inout->rData + ((EGWuintptr)pivot * (EGWuintptr)array_inout->eSize)), array_inout->eSize) < 0)
                ++left;
            
            while(right >= pivot && compareFunc((EGWbyte*)((EGWuintptr)array_inout->rData + ((EGWuintptr)pivot * (EGWuintptr)array_inout->eSize)),
                                                (EGWbyte*)((EGWuintptr)array_inout->rData + ((EGWuintptr)right * (EGWuintptr)array_inout->eSize)), array_inout->eSize) < 0)
                --right;
            
            memcpy((void*)temp, (void*)((EGWuintptr)array_inout->rData + ((EGWuintptr)left * (EGWuintptr)array_inout->eSize)), (size_t)array_inout->eSize);
            memcpy((void*)((EGWuintptr)array_inout->rData + ((EGWuintptr)left * (EGWuintptr)array_inout->eSize)),
                   (void*)((EGWuintptr)array_inout->rData + ((EGWuintptr)right * (EGWuintptr)array_inout->eSize)), (size_t)array_inout->eSize);
            memcpy((void*)((EGWuintptr)array_inout->rData + ((EGWuintptr)right * (EGWuintptr)array_inout->eSize)), (void*)temp, (size_t)array_inout->eSize);
            
            ++left; --right;
            if(left - 1 == pivot)
                pivot = ++right;
            else if(right + 1 == pivot)
                pivot = --left;
        }
        
        egwArraySortRecurse(array_inout, temp, low, pivot-1);
        egwArraySortRecurse(array_inout, temp, pivot+1, high);
    }
}

egwArray* egwArrayInit(egwArray* array_out, egwDataFuncs* funcs_in, EGWuint elmSize_in, EGWuint intCap_in, EGWuint flags_in) {
    memset((void*)array_out, 0, sizeof(egwArray));
    
    intCap_in = (EGWuint)egwMax2i(1, (EGWint)(EGWuint16)intCap_in);
    elmSize_in = (EGWuint)egwMax2i(1, (EGWint)(EGWuint16)elmSize_in);
    
    array_out->aFlags = (EGWuint32)flags_in;
    array_out->eSize = (EGWuint16)elmSize_in;
    array_out->eMinCount = array_out->eMaxCount = (EGWuint16)intCap_in;
    
    if(funcs_in) {
        if(!(array_out->dFuncs = (egwDataFuncs*)malloc(sizeof(egwDataFuncs)))) { egwArrayFree(array_out); return NULL; }
        memcpy((void*)array_out->dFuncs, (const void*)funcs_in, sizeof(egwDataFuncs));
    }
    
    {   EGWmallocfp mallocFunc = (array_out->dFuncs && array_out->dFuncs->fpMalloc ? (EGWmallocfp)array_out->dFuncs->fpMalloc : (EGWmallocfp)&malloc);
        if(!(array_out->rData = (EGWbyte*)mallocFunc(((size_t)array_out->eSize * (size_t)array_out->eMaxCount)))) { egwArrayFree(array_out); return NULL; }
    }
    
    return array_out;
}

egwArray* egwArrayCopy(const egwArray* array_in, egwArray* array_out) {
    memset((void*)array_out, 0, sizeof(egwArray));
    
    if(array_in->aFlags & EGW_ARRAY_FLG_FREE) // Ownership sharing not permitted
        return NULL;
    
    array_out->aFlags = array_in->aFlags;
    array_out->eSize = array_in->eSize;
    array_out->eCount = array_in->eCount;
    array_out->eMinCount = array_in->eMinCount;
    array_out->eMaxCount = (EGWuint16)egwMax2i(egwMax2i(1, (EGWint)array_in->eMaxCount), (EGWint)array_in->eCount);
    
    if(array_in->dFuncs) {
        if(!(array_out->dFuncs = (egwDataFuncs*)malloc(sizeof(egwDataFuncs)))) { egwArrayFree(array_out); return NULL; }
        memcpy((void*)(array_out->dFuncs), (const void*)(array_in->dFuncs), sizeof(egwDataFuncs));
    }
    
    {   EGWmallocfp mallocFunc = (array_out->dFuncs && array_out->dFuncs->fpMalloc ? (EGWmallocfp)(array_out->dFuncs->fpMalloc) : (EGWmallocfp)&malloc);
        if(!(array_out->rData = (EGWbyte*)mallocFunc(((size_t)(array_in->eSize) * (size_t)(array_in->eMaxCount))))) { egwArrayFree(array_out); return NULL; }
    }
    
    memcpy((void*)(array_out->rData),
           (const void*)(array_in->rData),
           (size_t)(array_in->eSize) * (size_t)(array_in->eCount));
    
    if(array_out->aFlags & EGW_ARRAY_FLG_RETAIN) {
        EGWuint16 index = array_out->eCount; while(index--)
            [(id<NSObject>)*(void**)((EGWuintptr)(array_out->rData) + ((EGWuintptr)index * (EGWuintptr)(array_out->eSize))) retain];
    }
    if(array_out->dFuncs && array_out->dFuncs->fpAdd) {
        EGWuint16 index = array_out->eCount; while(index--)
            array_out->dFuncs->fpAdd((EGWbyte*)((EGWuintptr)(array_out->rData) + ((EGWuintptr)index * (EGWuintptr)(array_out->eSize))));
    }
    
    return array_out;
}

egwArray* egwArrayFree(egwArray* array_inout) {
    if(array_inout->rData) {
        if(array_inout->dFuncs && array_inout->dFuncs->fpRemove) {
            EGWuint16 index = array_inout->eCount; while(index--)
                array_inout->dFuncs->fpRemove((EGWbyte*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)index * (EGWuintptr)(array_inout->eSize))));
        }
        if(array_inout->aFlags & EGW_ARRAY_FLG_RETAIN) {
            EGWuint16 index = array_inout->eCount; while(index--)
                [(id<NSObject>)*(void**)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)index * (EGWuintptr)(array_inout->eSize))) release];
        }
        if(array_inout->aFlags & EGW_ARRAY_FLG_FREE) {
            EGWuint16 index = array_inout->eCount; while(index--)
                free((void*)*(void**)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)index * (EGWuintptr)(array_inout->eSize))));
        }
        
        {   EGWfreefp freeFunc = (array_inout->dFuncs && array_inout->dFuncs->fpFree ? (EGWfreefp)(array_inout->dFuncs->fpFree) : (EGWfreefp)&free);
            freeFunc((void*)(array_inout->rData));
        }
    }
    
    if(array_inout->dFuncs)
        free((void*)(array_inout->dFuncs));
    
    memset((void*)array_inout, 0, sizeof(egwArray));
    
    return array_inout;
}

EGWint egwArrayAddAt(egwArray* array_inout, EGWuint index_in, const EGWbyte* data_in) {
    if(index_in <= array_inout->eCount) {
        if(egwArrayGrowChk(array_inout) && !egwArrayGrow(array_inout))
            return 0;
        
        if(array_inout->eCount < array_inout->eMaxCount) {
            if(index_in < array_inout->eCount) // is not tail (tail is quick shift right)
                memmove((void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(index_in + 1) * (EGWuintptr)(array_inout->eSize))),
                        (const void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)index_in * (EGWuintptr)(array_inout->eSize))),
                        (size_t)(array_inout->eSize) * (size_t)(array_inout->eCount - index_in));
            
            if(data_in)
                memcpy((void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)index_in * (EGWuintptr)(array_inout->eSize))),
                       (const void*)data_in,
                       (size_t)(array_inout->eSize));
            
            ++(array_inout->eCount);
            
            if(data_in && array_inout->aFlags & EGW_ARRAY_FLG_RETAIN)
                [(id<NSObject>)*(void**)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)index_in * (EGWuintptr)(array_inout->eSize))) retain];
            if(array_inout->dFuncs && array_inout->dFuncs->fpAdd)
                array_inout->dFuncs->fpAdd((EGWbyte*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)index_in * (EGWuintptr)(array_inout->eSize))));
            
            return 1;
        }
    }
    
    return 0;
}

EGWint egwArrayAddHead(egwArray* array_inout, const EGWbyte* data_in) {
    return egwArrayAddAt(array_inout, 0, data_in);
}

EGWint egwArrayAddTail(egwArray* array_inout, const EGWbyte* data_in) {
    return egwArrayAddAt(array_inout, array_inout->eCount, data_in);
}

EGWint egwArrayRemoveAt(egwArray* array_inout, EGWuint index_in) {
    if(index_in < array_inout->eCount) {
        if(array_inout->eCount > 0) {
            if(array_inout->dFuncs && array_inout->dFuncs->fpRemove)
                array_inout->dFuncs->fpRemove((EGWbyte*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)index_in * (EGWuintptr)(array_inout->eSize))));
            if(array_inout->aFlags & EGW_ARRAY_FLG_RETAIN)
                [(id<NSObject>)*(void**)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)index_in * (EGWuintptr)(array_inout->eSize))) release];
            if(array_inout->aFlags & EGW_ARRAY_FLG_FREE)
                free((void*)*(void**)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)index_in * (EGWuintptr)(array_inout->eSize))));
            
            if(index_in < array_inout->eCount - 1) // is not tail (tail is quick shift left)
                memmove((void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)index_in * (EGWuintptr)(array_inout->eSize))),
                        (const void*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)(index_in + 1) * (EGWuintptr)(array_inout->eSize))),
                        (size_t)(array_inout->eSize) * (size_t)(array_inout->eCount - (index_in + 1)));
            
            --(array_inout->eCount);
            
            if(egwArrayShrinkChk(array_inout) && !egwArrayShrink(array_inout))
                return 0;
            
            return 1;
        }
    }
    
    return 0;
}

EGWint egwArrayRemoveHead(egwArray* array_inout) {
    return egwArrayRemoveAt(array_inout, 0);
}

EGWint egwArrayRemoveTail(egwArray* array_inout) {
    return egwArrayRemoveAt(array_inout, (array_inout->eCount ? array_inout->eCount - 1 : 0));
}

EGWint egwArrayRemoveAll(egwArray* array_inout) {
    if(array_inout->eCount) {
        if(array_inout->dFuncs && array_inout->dFuncs->fpRemove) {
            EGWuint16 index = array_inout->eCount; while(index--)
                array_inout->dFuncs->fpRemove((EGWbyte*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)index * (EGWuintptr)(array_inout->eSize))));
        }
        if(array_inout->aFlags & EGW_ARRAY_FLG_RETAIN) {
            EGWuint16 index = array_inout->eCount; while(index--)
                [(id<NSObject>)*(void**)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)index * (EGWuintptr)(array_inout->eSize))) release];
        }
        if(array_inout->aFlags & EGW_ARRAY_FLG_FREE) {
            EGWuint16 index = array_inout->eCount; while(index--)
                free((void*)*(void**)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)index * (EGWuintptr)(array_inout->eSize))));
        }
        
        if((array_inout->aFlags & EGW_ARRAY_FLG_EXSHRNKCND) && (array_inout->aFlags & EGW_ARRAY_FLG_EXSHRNKBY)) {
            while((array_inout->eCount)--)
                if(egwArrayShrinkChk(array_inout)) {
                    EGWuint16 count = array_inout->eCount;
                    array_inout->eCount = 0;
                    egwArrayShrink(array_inout);
                    array_inout->eCount = (EGWuint16)egwMin2i((EGWint)count, (EGWint)(array_inout->eMaxCount));
                }
        }
        
        array_inout->eCount = 0;
        
        return 1;
    } else
        return 0;
}

void egwArrayGetElementAt(const egwArray* array_in, EGWuint index_in, EGWbyte* data_out) {
    memcpy((void*)data_out,
           (const void*)((EGWuintptr)(array_in->rData) + ((EGWuintptr)index_in * (EGWuintptr)(array_in->eSize))),
           (size_t)(array_in->eSize));
}

void egwArrayGetElementHead(const egwArray* array_in, EGWbyte* data_out) {
    memcpy((void*)data_out,
           (const void*)array_in->rData,
           (size_t)(array_in->eSize));
}

void egwArrayGetElementTail(const egwArray* array_in, EGWbyte* data_out) {
    memcpy((void*)data_out,
           (const void*)((EGWuintptr)(array_in->rData) + ((EGWuintptr)(array_in->eCount ? array_in->eCount - 1 : 0) * (EGWuintptr)(array_in->eSize))),
           (size_t)(array_in->eSize));
}

EGWbyte* egwArrayElementPtrAt(const egwArray* array_in, EGWuint index_in) {
    return (EGWbyte*)((EGWuintptr)(array_in->rData) + ((EGWuintptr)index_in * (EGWuintptr)(array_in->eSize)));
}

EGWbyte* egwArrayElementPtrHead(const egwArray* array_in) {
    return array_in->rData;
}

EGWbyte* egwArrayElementPtrTail(const egwArray* array_in) {
    return (EGWbyte*)((EGWuintptr)(array_in->rData) + ((EGWuintptr)(array_in->eCount ? array_in->eCount - 1 : 0) * (EGWuintptr)(array_in->eSize)));
}

EGWint egwArrayFind(const egwArray* array_in, const EGWbyte* data_in, EGWuint findMode_in) {
    EGWcomparefp compareFunc = (array_in->dFuncs && array_in->dFuncs->fpCompare ? (EGWcomparefp)(array_in->dFuncs->fpCompare) : (EGWcomparefp)&memcmp);
    
    switch(findMode_in & EGW_FIND_MODE_EXMETHOD) {
        case EGW_FIND_MODE_BINARY: {
            EGWint min = 0;
            EGWint max = array_in->eCount - 1;
            EGWint mid = min + ((max - min) >> 1);
            EGWint cmpResult = -1;
            
            while(min < max) {
                cmpResult = compareFunc((EGWbyte*)((EGWuintptr)array_in->rData + ((EGWuintptr)mid * (EGWuintptr)array_in->eSize)), data_in, array_in->eSize);
                
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
            register EGWbyte* node = (EGWbyte*)array_in->rData;
            
            if(!(findMode_in & EGW_FIND_MODE_ISSORTED)) {
                EGWint count = array_in->eCount;
                while(count--) {
                    if(0 != compareFunc(node, data_in, array_in->eSize))
                        node = (EGWbyte*)((EGWuintptr)node + (EGWuintptr)array_in->eSize);
                    else
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
                    }
                    else
                        return array_in->eCount - (count + 1);
                }
            }
        } break;
            
        case EGW_FIND_MODE_LINTTH: {
            register EGWbyte* node = (EGWbyte*)((EGWuintptr)array_in->rData + ((EGWuintptr)(array_in->eCount - 1) * (EGWuintptr)array_in->eSize));
            
            if(!(findMode_in & EGW_FIND_MODE_ISSORTED)) {
                EGWint count = array_in->eCount;
                while(count--) {
                    if(0 != compareFunc(node, data_in, array_in->eSize))
                        node = (EGWbyte*)((EGWuintptr)node - (EGWuintptr)array_in->eSize);
                    else
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
                    }
                    else
                        return count;
                }
            }
        } break;
    }
    
    return -1;
}

EGWint egwArrayContains(const egwArray* array_in, const EGWbyte* data_in, EGWuint findMode_in) {
    return (egwArrayFind(array_in, data_in, findMode_in) != -1 ? 1 : 0);
}

EGWuint egwArrayOccurances(const egwArray* array_in, const EGWbyte* data_in, EGWuint findMode_in) {
    EGWuint retVal = 0;
    EGWcomparefp compareFunc = (array_in->dFuncs && array_in->dFuncs->fpCompare ? (EGWcomparefp)(array_in->dFuncs->fpCompare) : (EGWcomparefp)&memcmp);
    
    switch(findMode_in & EGW_FIND_MODE_EXMETHOD) {
        case EGW_FIND_MODE_BINARY: {
            EGWint min = 0;
            EGWint max = array_in->eCount - 1;
            EGWint mid = min + ((max - min) >> 1);
            EGWint cmpResult = -1;
            
            while(min < max) {
                cmpResult = compareFunc((EGWbyte*)((EGWuintptr)array_in->rData + ((EGWuintptr)mid * (EGWuintptr)array_in->eSize)), data_in, array_in->eSize);
                
                if(cmpResult >= 0)
                    max = mid - 1;
                else
                    min = mid + 1;
                mid = min + ((max - min) >> 1);
            }
            
            // Switch over to forward sweep mode
            if(cmpResult == 0) {
                register EGWbyte* node = (EGWbyte*)((EGWuintptr)array_in->rData + ((EGWuintptr)mid * (EGWuintptr)array_in->eSize));
                
                EGWint count = array_in->eCount - mid;
                while(count--) {
                    EGWint cmpValue = compareFunc(node, data_in, array_in->eSize);
                    if(0 == cmpValue)
                        ++retVal;
                    else if(cmpValue > 0)
                        break;
                    node = (EGWbyte*)((EGWuintptr)node + (EGWuintptr)array_in->eSize);
                }
            }
        } break;
        
        default:
        case EGW_FIND_MODE_LINHTT: {
            register EGWbyte* node = (EGWbyte*)array_in->rData;
            
            if(!(findMode_in & EGW_FIND_MODE_ISSORTED)) {
                EGWint count = array_in->eCount;
                while(count--) {
                    if(0 == compareFunc(node, data_in, array_in->eSize))
                        ++retVal;
                    node = (EGWbyte*)((EGWuintptr)node + (EGWuintptr)array_in->eSize);
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
                }
            }
        } break;
        
        case EGW_FIND_MODE_LINTTH: {
            register EGWbyte* node = (EGWbyte*)((EGWuintptr)array_in->rData + ((EGWuintptr)(array_in->eCount - 1) * (EGWuintptr)array_in->eSize));
            
            if(!(findMode_in & EGW_FIND_MODE_ISSORTED)) {
                EGWint count = array_in->eCount;
                while(count--) {
                    if(0 == compareFunc(node, data_in, array_in->eSize))
                        ++retVal;
                    node = (EGWbyte*)((EGWuintptr)node - (EGWuintptr)array_in->eSize);
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
                }
            }
        } break;
    }
    
    return retVal;
}

EGWint egwArrayResize(egwArray* array_inout, EGWuint newCap_in) {
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
                        array_inout->dFuncs->fpRemove((EGWbyte*)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)index * (EGWuintptr)(array_inout->eSize))));
                }
                if(array_inout->aFlags & EGW_ARRAY_FLG_RETAIN) {
                    EGWuint16 index = array_inout->eCount; while(index-- > (EGWuint16)newCap_in)
                        [(id<NSObject>)*(void**)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)index * (EGWuintptr)(array_inout->eSize))) release];
                }
                if(array_inout->aFlags & EGW_ARRAY_FLG_FREE) {
                    EGWuint16 index = array_inout->eCount; while(index-- > (EGWuint16)newCap_in)
                        free((void*)*(void**)((EGWuintptr)(array_inout->rData) + ((EGWuintptr)index * (EGWuintptr)(array_inout->eSize))));
                }
                
                array_inout->eCount = newCap_in;
            }
            
            memcpy((void*)newRData,
                   (const void*)(array_inout->rData),
                   (size_t)(array_inout->eSize) * (size_t)(array_inout->eCount));
            
            array_inout->eMaxCount = 0;
            
            {   EGWfreefp freeFunc = (array_inout->dFuncs && array_inout->dFuncs->fpFree ? (EGWfreefp)(array_inout->dFuncs->fpFree) : (EGWfreefp)&free);
                freeFunc((void*)array_inout->rData);
            }
            array_inout->rData = newRData;
        } else {
            // NOTE: In low memory situations, it's better to free first then malloc, if possible -jw
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

EGWint egwArrayGrowChk(const egwArray* array_in) {
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

EGWint egwArrayShrinkChk(const egwArray* array_in) {
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

EGWint egwArrayGrow(egwArray* array_inout) {
    switch(array_inout->aFlags & EGW_ARRAY_FLG_EXGROWBY) {
        case EGW_ARRAY_FLG_GROWBY2X: {
            return egwArrayResize(array_inout, array_inout->eMaxCount * 2);
        } break;
        
        case EGW_ARRAY_FLG_GROWBY3X: {
            return egwArrayResize(array_inout, array_inout->eMaxCount * 3);
        } break;
        
        case EGW_ARRAY_FLG_GROWBY10: {
            return egwArrayResize(array_inout, array_inout->eMaxCount + 10);
        } break;
        
        case EGW_ARRAY_FLG_GROWBY25: {
            return egwArrayResize(array_inout, array_inout->eMaxCount + 25);
        } break;
        
        case EGW_ARRAY_FLG_GROWBYSQRD: {
            return egwArrayResize(array_inout, array_inout->eMaxCount * array_inout->eMaxCount);
        } break;
    }
    
    return 0;
}

EGWint egwArrayShrink(egwArray* array_inout) {
    switch(array_inout->aFlags & EGW_ARRAY_FLG_EXSHRNKBY) {
        case EGW_ARRAY_FLG_SHRNKBY2X: {
            return egwArrayResize(array_inout, array_inout->eMaxCount >> 1);
        } break;
        
        case EGW_ARRAY_FLG_SHRNKBY3X: {
            return egwArrayResize(array_inout, array_inout->eMaxCount / 3);
        } break;
        
        case EGW_ARRAY_FLG_SHRNKBY10: {
            return egwArrayResize(array_inout, (array_inout->eMaxCount >= 10 ? array_inout->eMaxCount - 10 : 0));
        } break;
        
        case EGW_ARRAY_FLG_SHRNKBY25: {
            return egwArrayResize(array_inout, (array_inout->eMaxCount >= 25 ? array_inout->eMaxCount - 25 : 0));
        } break;
        
        case EGW_ARRAY_FLG_SHRNKBYSQRT: {
            return egwArrayResize(array_inout, egwSqrtd(array_inout->eMaxCount));
        } break;
    }
    
    return 0;
}

EGWint egwArraySort(egwArray* array_inout) {
    EGWbyte* temp = malloc((size_t)array_inout->eSize);
    
    if(temp) {
        if(array_inout->eCount > 1)
            egwArraySortRecurse(array_inout, temp, 0, array_inout->eCount - 1);
        
        free((void*)temp);
        return 1;
    }
    
    return 0;
}

EGWint egwArrayEnumerateStart(const egwArray* array_in, EGWuint iterMode_in, egwArrayIter* iter_out) {
    if(array_in->eCount) {
        iter_out->pArray = array_in;
        iter_out->nPos = NULL;
        iter_out->iMode = iterMode_in;
        iter_out->eIndex = -1;
        
        switch(iter_out->iMode & EGW_ITERATE_MODE_EXLIN) {
            case EGW_ITERATE_MODE_LINHTT: {
                iter_out->nPos = array_in->rData;
            } break;
            
            case EGW_ITERATE_MODE_LINTTH: {
                iter_out->nPos = (EGWbyte*)((EGWuintptr)(array_in->rData) + ((EGWuintptr)(array_in->eCount - 1) * (EGWuintptr)(array_in->eSize)));
            } break;
        }
        
        return 1;
    } else
        return 0;
}

EGWint egwArrayEnumerateGetNext(egwArrayIter* iter_inout, EGWbyte* data_out) {
    EGWbyte* data = egwArrayEnumerateNextPtr(iter_inout);
    
    if(data) {
        memcpy((void*)data_out, (const void*)data, (size_t)(iter_inout->pArray->eSize));
        return 1;
    } else
        return 0;
}

EGWbyte* egwArrayEnumerateNextPtr(egwArrayIter* iter_inout) {
    if(iter_inout->nPos) {
        EGWbyte* retVal = iter_inout->nPos;
        
        if(++(iter_inout->eIndex) < iter_inout->pArray->eCount - 1) {
            switch(iter_inout->iMode & EGW_ITERATE_MODE_EXLIN) {
                case EGW_ITERATE_MODE_LINHTT: {
                    iter_inout->nPos = (EGWbyte*)((EGWuintptr)(iter_inout->nPos) + (EGWuintptr)(iter_inout->pArray->eSize));
                } break;
                
                case EGW_ITERATE_MODE_LINTTH: {
                    iter_inout->nPos = (EGWbyte*)((EGWuintptr)(iter_inout->nPos) - (EGWuintptr)(iter_inout->pArray->eSize));
                } break;
            }
        } else
            iter_inout->nPos = NULL;
        
        return retVal;
    }
    
    return NULL;
}

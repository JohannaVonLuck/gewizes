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

/// @file egwSystem.m
/// @ingroup geWizES_sys_system
/// Base System Implementation.

#import <stdlib.h>
#import "egwSystem.h"


EGWuint egwParseStringi8cv(const EGWchar* string_in, EGWint8* array_out, EGWintptr strideB_out, EGWuint count) {
    const EGWchar* start = NULL;
    const EGWchar* end = NULL;
    EGWchar* value = NULL;
    EGWuint valueSize = 0;
    EGWuint processed = 0;
    
    while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
    if(*string_in == '\0') return processed;
    else start = end = string_in;
    
    while(processed < count) {
        if(!(*string_in <= ' ' || *string_in == ',' || *string_in == '\0'))
            end = ++string_in;
        else {
            if(valueSize < ((EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1)) {
                if(value) { free((void*)value); value = NULL; valueSize = 0; }
                valueSize = (EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1; valueSize = valueSize + (valueSize >> 1); // x1.5
                if(!(value = (EGWchar*)malloc((size_t)valueSize))) {
                    NSLog(@"egwParseStringi8cv: Failure allocating memory for temporary storage.");
                    return processed;
                }
            }
            
            strncpy((char*)value, (const char*)start, (size_t)((EGWuintptr)end - (EGWuintptr)start)); value[(EGWuint)((EGWuintptr)end - (EGWuintptr)start)] = '\0';
            
            *array_out = (EGWint8)atoi((const char*)value);
            array_out = (EGWint8*)((EGWintptr)array_out + (EGWintptr)sizeof(EGWint8) + strideB_out);
            
            ++processed;
            while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
            if(*string_in == '\0') break;
            else start = end = string_in;
        }
    }
    
    if(value) { free((void*)value); value = NULL; valueSize = 0; }
    
    return processed;
}

EGWuint egwParseStringi16cv(const EGWchar* string_in, EGWint16* array_out, EGWintptr strideB_out, EGWuint count) {
    const EGWchar* start = NULL;
    const EGWchar* end = NULL;
    EGWchar* value = NULL;
    EGWuint valueSize = 0;
    EGWuint processed = 0;
    
    while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
    if(*string_in == '\0') return processed;
    else start = end = string_in;
    
    while(processed < count) {
        if(!(*string_in <= ' ' || *string_in == ',' || *string_in == '\0'))
            end = ++string_in;
        else {
            if(valueSize < ((EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1)) {
                if(value) { free((void*)value); value = NULL; valueSize = 0; }
                valueSize = (EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1; valueSize = valueSize + (valueSize >> 1); // x1.5
                if(!(value = (EGWchar*)malloc((size_t)valueSize))) {
                    NSLog(@"egwParseStringi16cv: Failure allocating memory for temporary storage.");
                    return processed;
                }
            }
            
            strncpy((char*)value, (const char*)start, (size_t)((EGWuintptr)end - (EGWuintptr)start)); value[(EGWuint)((EGWuintptr)end - (EGWuintptr)start)] = '\0';
            
            *array_out = (EGWint16)atoi((const char*)value);
            array_out = (EGWint16*)((EGWintptr)array_out + (EGWintptr)sizeof(EGWint16) + strideB_out);
            
            ++processed;
            while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
            if(*string_in == '\0') break;
            else start = end = string_in;
        }
    }
    
    if(value) { free((void*)value); value = NULL; valueSize = 0; }
    
    return processed;
}

EGWuint egwParseStringi32cv(const EGWchar* string_in, EGWint32* array_out, EGWintptr strideB_out, EGWuint count) {
    const EGWchar* start = NULL;
    const EGWchar* end = NULL;
    EGWchar* value = NULL;
    EGWuint valueSize = 0;
    EGWuint processed = 0;
    
    while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
    if(*string_in == '\0') return processed;
    else start = end = string_in;
    
    while(processed < count) {
        if(!(*string_in <= ' ' || *string_in == ',' || *string_in == '\0'))
            end = ++string_in;
        else {
            if(valueSize < ((EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1)) {
                if(value) { free((void*)value); value = NULL; valueSize = 0; }
                valueSize = (EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1; valueSize = valueSize + (valueSize >> 1); // x1.5
                if(!(value = (EGWchar*)malloc((size_t)valueSize))) {
                    NSLog(@"egwParseStringi32cv: Failure allocating memory for temporary storage.");
                    return processed;
                }
            }
            
            strncpy((char*)value, (const char*)start, (size_t)((EGWuintptr)end - (EGWuintptr)start)); value[(EGWuint)((EGWuintptr)end - (EGWuintptr)start)] = '\0';
            
            *array_out = (EGWint32)atol((const char*)value);
            array_out = (EGWint32*)((EGWintptr)array_out + (EGWintptr)sizeof(EGWint32) + strideB_out);
            
            ++processed;
            while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
            if(*string_in == '\0') break;
            else start = end = string_in;
        }
    }
    
    if(value) { free((void*)value); value = NULL; valueSize = 0; }
    
    return processed;
}

EGWuint egwParseStringi64cv(const EGWchar* string_in, EGWint64* array_out, EGWintptr strideB_out, EGWuint count) {
    const EGWchar* start = NULL;
    const EGWchar* end = NULL;
    EGWchar* value = NULL;
    EGWuint valueSize = 0;
    EGWuint processed = 0;
    
    while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
    if(*string_in == '\0') return processed;
    else start = end = string_in;
    
    while(processed < count) {
        if(!(*string_in <= ' ' || *string_in == ',' || *string_in == '\0'))
            end = ++string_in;
        else {
            if(valueSize < ((EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1)) {
                if(value) { free((void*)value); value = NULL; valueSize = 0; }
                valueSize = (EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1; valueSize = valueSize + (valueSize >> 1); // x1.5
                if(!(value = (EGWchar*)malloc((size_t)valueSize))) {
                    NSLog(@"egwParseStringi64cv: Failure allocating memory for temporary storage.");
                    return processed;
                }
            }
            
            strncpy((char*)value, (const char*)start, (size_t)((EGWuintptr)end - (EGWuintptr)start)); value[(EGWuint)((EGWuintptr)end - (EGWuintptr)start)] = '\0';
            
            *array_out = (EGWint64)atoll((const char*)value);
            array_out = (EGWint64*)((EGWintptr)array_out + (EGWintptr)sizeof(EGWint64) + strideB_out);
            
            ++processed;
            while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
            if(*string_in == '\0') break;
            else start = end = string_in;
        }
    }
    
    if(value) { free((void*)value); value = NULL; valueSize = 0; }
    
    return processed;
}

EGWuint egwParseStringui8cv(const EGWchar* string_in, EGWuint8* array_out, EGWintptr strideB_out, EGWuint count) {
    const EGWchar* start = NULL;
    const EGWchar* end = NULL;
    EGWchar* value = NULL;
    EGWuint valueSize = 0;
    EGWuint processed = 0;
    
    while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
    if(*string_in == '\0') return processed;
    else start = end = string_in;
    
    while(processed < count) {
        if(!(*string_in <= ' ' || *string_in == ',' || *string_in == '\0'))
            end = ++string_in;
        else {
            if(valueSize < ((EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1)) {
                if(value) { free((void*)value); value = NULL; valueSize = 0; }
                valueSize = (EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1; valueSize = valueSize + (valueSize >> 1); // x1.5
                if(!(value = (EGWchar*)malloc((size_t)valueSize))) {
                    NSLog(@"egwParseStringui8cv: Failure allocating memory for temporary storage.");
                    return processed;
                }
            }
            
            strncpy((char*)value, (const char*)start, (size_t)((EGWuintptr)end - (EGWuintptr)start)); value[(EGWuint)((EGWuintptr)end - (EGWuintptr)start)] = '\0';
            
            *array_out = (EGWuint8)atoi((const char*)value);
            array_out = (EGWuint8*)((EGWintptr)array_out + (EGWintptr)sizeof(EGWuint8) + strideB_out);
            
            ++processed;
            while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
            if(*string_in == '\0') break;
            else start = end = string_in;
        }
    }
    
    if(value) { free((void*)value); value = NULL; valueSize = 0; }
    
    return processed;
}

EGWuint egwParseStringui16cv(const EGWchar* string_in, EGWuint16* array_out, EGWintptr strideB_out, EGWuint count) {
    const EGWchar* start = NULL;
    const EGWchar* end = NULL;
    EGWchar* value = NULL;
    EGWuint valueSize = 0;
    EGWuint processed = 0;
    
    while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
    if(*string_in == '\0') return processed;
    else start = end = string_in;
    
    while(processed < count) {
        if(!(*string_in <= ' ' || *string_in == ',' || *string_in == '\0'))
            end = ++string_in;
        else {
            if(valueSize < ((EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1)) {
                if(value) { free((void*)value); value = NULL; valueSize = 0; }
                valueSize = (EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1; valueSize = valueSize + (valueSize >> 1); // x1.5
                if(!(value = (EGWchar*)malloc((size_t)valueSize))) {
                    NSLog(@"egwParseStringui16cv: Failure allocating memory for temporary storage.");
                    return processed;
                }
            }
            
            strncpy((char*)value, (const char*)start, (size_t)((EGWuintptr)end - (EGWuintptr)start)); value[(EGWuint)((EGWuintptr)end - (EGWuintptr)start)] = '\0';
            
            *array_out = (EGWuint16)atoi((const char*)value);
            array_out = (EGWuint16*)((EGWintptr)array_out + (EGWintptr)sizeof(EGWuint16) + strideB_out);
            
            ++processed;
            while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
            if(*string_in == '\0') break;
            else start = end = string_in;
        }
    }
    
    if(value) { free((void*)value); value = NULL; valueSize = 0; }
    
    return processed;
}

EGWuint egwParseStringui32cv(const EGWchar* string_in, EGWuint32* array_out, EGWintptr strideB_out, EGWuint count) {
    const EGWchar* start = NULL;
    const EGWchar* end = NULL;
    EGWchar* value = NULL;
    EGWuint valueSize = 0;
    EGWuint processed = 0;
    
    while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
    if(*string_in == '\0') return processed;
    else start = end = string_in;
    
    while(processed < count) {
        if(!(*string_in <= ' ' || *string_in == ',' || *string_in == '\0'))
            end = ++string_in;
        else {
            if(valueSize < ((EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1)) {
                if(value) { free((void*)value); value = NULL; valueSize = 0; }
                valueSize = (EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1; valueSize = valueSize + (valueSize >> 1); // x1.5
                if(!(value = (EGWchar*)malloc((size_t)valueSize))) {
                    NSLog(@"egwParseStringui32cv: Failure allocating memory for temporary storage.");
                    return processed;
                }
            }
            
            strncpy((char*)value, (const char*)start, (size_t)((EGWuintptr)end - (EGWuintptr)start)); value[(EGWuint)((EGWuintptr)end - (EGWuintptr)start)] = '\0';
            
            *array_out = (EGWuint32)atoll((const char*)value);
            array_out = (EGWuint32*)((EGWintptr)array_out + (EGWintptr)sizeof(EGWuint32) + strideB_out);
            
            ++processed;
            while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
            if(*string_in == '\0') break;
            else start = end = string_in;
        }
    }
    
    if(value) { free((void*)value); value = NULL; valueSize = 0; }
    
    return processed;
}

EGWuint egwParseStringui64cv(const EGWchar* string_in, EGWuint64* array_out, EGWintptr strideB_out, EGWuint count) {
    const EGWchar* start = NULL;
    const EGWchar* end = NULL;
    EGWchar* value = NULL;
    EGWuint valueSize = 0;
    EGWuint processed = 0;
    
    while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
    if(*string_in == '\0') return processed;
    else start = end = string_in;
    
    while(processed < count) {
        if(!(*string_in <= ' ' || *string_in == ',' || *string_in == '\0'))
            end = ++string_in;
        else {
            if(valueSize < ((EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1)) {
                if(value) { free((void*)value); value = NULL; valueSize = 0; }
                valueSize = (EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1; valueSize = valueSize + (valueSize >> 1); // x1.5
                if(!(value = (EGWchar*)malloc((size_t)valueSize))) {
                    NSLog(@"egwParseStringui64cv: Failure allocating memory for temporary storage.");
                    return processed;
                }
            }
            
            strncpy((char*)value, (const char*)start, (size_t)((EGWuintptr)end - (EGWuintptr)start)); value[(EGWuint)((EGWuintptr)end - (EGWuintptr)start)] = '\0';
            
            *array_out = (EGWuint64)atoll((const char*)value);
            array_out = (EGWuint64*)((EGWintptr)array_out + (EGWintptr)sizeof(EGWuint64) + strideB_out);
            
            ++processed;
            while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
            if(*string_in == '\0') break;
            else start = end = string_in;
        }
    }
    
    if(value) { free((void*)value); value = NULL; valueSize = 0; }
    
    return processed;
}

EGWuint egwParseStringicv(const EGWchar* string_in, EGWint* array_out, EGWintptr strideB_out, EGWuint count) {
    const EGWchar* start = NULL;
    const EGWchar* end = NULL;
    EGWchar* value = NULL;
    EGWuint valueSize = 0;
    EGWuint processed = 0;
    
    while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
    if(*string_in == '\0') return processed;
    else start = end = string_in;
    
    while(processed < count) {
        if(!(*string_in <= ' ' || *string_in == ',' || *string_in == '\0'))
            end = ++string_in;
        else {
            if(valueSize < ((EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1)) {
                if(value) { free((void*)value); value = NULL; valueSize = 0; }
                valueSize = (EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1; valueSize = valueSize + (valueSize >> 1); // x1.5
                if(!(value = (EGWchar*)malloc((size_t)valueSize))) {
                    NSLog(@"egwParseStringicv: Failure allocating memory for temporary storage.");
                    return processed;
                }
            }
            
            strncpy((char*)value, (const char*)start, (size_t)((EGWuintptr)end - (EGWuintptr)start)); value[(EGWuint)((EGWuintptr)end - (EGWuintptr)start)] = '\0';
            
            *array_out = (EGWint)atol((const char*)value);
            array_out = (EGWint*)((EGWintptr)array_out + (EGWintptr)sizeof(EGWint) + strideB_out);
            
            ++processed;
            while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
            if(*string_in == '\0') break;
            else start = end = string_in;
        }
    }
    
    if(value) { free((void*)value); value = NULL; valueSize = 0; }
    
    return processed;
}

EGWuint egwParseStringuicv(const EGWchar* string_in, EGWuint* array_out, EGWintptr strideB_out, EGWuint count) {
    const EGWchar* start = NULL;
    const EGWchar* end = NULL;
    EGWchar* value = NULL;
    EGWuint valueSize = 0;
    EGWuint processed = 0;
    
    while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
    if(*string_in == '\0') return processed;
    else start = end = string_in;
    
    while(processed < count) {
        if(!(*string_in <= ' ' || *string_in == ',' || *string_in == '\0'))
            end = ++string_in;
        else {
            if(valueSize < ((EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1)) {
                if(value) { free((void*)value); value = NULL; valueSize = 0; }
                valueSize = (EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1; valueSize = valueSize + (valueSize >> 1); // x1.5
                if(!(value = (EGWchar*)malloc((size_t)valueSize))) {
                    NSLog(@"egwParseStringuicv: Failure allocating memory for temporary storage.");
                    return processed;
                }
            }
            
            strncpy((char*)value, (const char*)start, (size_t)((EGWuintptr)end - (EGWuintptr)start)); value[(EGWuint)((EGWuintptr)end - (EGWuintptr)start)] = '\0';
            
            *array_out = (EGWuint)atol((const char*)value);
            array_out = (EGWuint*)((EGWintptr)array_out + (EGWintptr)sizeof(EGWuint) + strideB_out);
            
            ++processed;
            while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
            if(*string_in == '\0') break;
            else start = end = string_in;
        }
    }
    
    if(value) { free((void*)value); value = NULL; valueSize = 0; }
    
    return processed;
}

EGWuint egwParseStringfcv(const EGWchar* string_in, EGWsingle* array_out, EGWintptr strideB_out, EGWuint count) {
    const EGWchar* start = NULL;
    const EGWchar* end = NULL;
    EGWchar* value = NULL;
    EGWuint valueSize = 0;
    EGWuint processed = 0;
    
    while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
    if(*string_in == '\0') return processed;
    else start = end = string_in;
    
    while(processed < count) {
        if(!(*string_in <= ' ' || *string_in == ',' || *string_in == '\0'))
            end = ++string_in;
        else {
            if(valueSize < ((EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1)) {
                if(value) { free((void*)value); value = NULL; valueSize = 0; }
                valueSize = (EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1; valueSize = valueSize + (valueSize >> 1); // x1.5
                if(!(value = (EGWchar*)malloc((size_t)valueSize))) {
                    NSLog(@"egwParseStringfcv: Failure allocating memory for temporary storage.");
                    return processed;
                }
            }
            
            strncpy((char*)value, (const char*)start, (size_t)((EGWuintptr)end - (EGWuintptr)start)); value[(EGWuint)((EGWuintptr)end - (EGWuintptr)start)] = '\0';
            
            *array_out = (EGWsingle)atof((const char*)value);
            array_out = (EGWsingle*)((EGWintptr)array_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
            
            ++processed;
            while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
            if(*string_in == '\0') break;
            else start = end = string_in;
        }
    }
    
    if(value) { free((void*)value); value = NULL; valueSize = 0; }
    
    return processed;
}

EGWuint egwParseStringdcv(const EGWchar* string_in, EGWdouble* array_out, EGWintptr strideB_out, EGWuint count) {
    const EGWchar* start = NULL;
    const EGWchar* end = NULL;
    EGWchar* value = NULL;
    EGWuint valueSize = 0;
    EGWuint processed = 0;
    
    while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
    if(*string_in == '\0') return processed;
    else start = end = string_in;
    
    while(processed < count) {
        if(!(*string_in <= ' ' || *string_in == ',' || *string_in == '\0'))
            end = ++string_in;
        else {
            if(valueSize < ((EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1)) {
                if(value) { free((void*)value); value = NULL; valueSize = 0; }
                valueSize = (EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1; valueSize = valueSize + (valueSize >> 1); // x1.5
                if(!(value = (EGWchar*)malloc((size_t)valueSize))) {
                    NSLog(@"egwParseStringdcv: Failure allocating memory for temporary storage.");
                    return processed;
                }
            }
            
            strncpy((char*)value, (const char*)start, (size_t)((EGWuintptr)end - (EGWuintptr)start)); value[(EGWuint)((EGWuintptr)end - (EGWuintptr)start)] = '\0';
            
            *array_out = (EGWdouble)atof((const char*)value);
            array_out = (EGWdouble*)((EGWintptr)array_out + (EGWintptr)sizeof(EGWdouble) + strideB_out);
            
            ++processed;
            while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
            if(*string_in == '\0') break;
            else start = end = string_in;
        }
    }
    
    if(value) { free((void*)value); value = NULL; valueSize = 0; }
    
    return processed;
}

EGWuint egwParseStringtcv(const EGWchar* string_in, EGWtriple* array_out, EGWintptr strideB_out, EGWuint count) {
    const EGWchar* start = NULL;
    const EGWchar* end = NULL;
    EGWchar* value = NULL;
    EGWuint valueSize = 0;
    EGWuint processed = 0;
    
    while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
    if(*string_in == '\0') return processed;
    else start = end = string_in;
    
    while(processed < count) {
        if(!(*string_in <= ' ' || *string_in == ',' || *string_in == '\0'))
            end = ++string_in;
        else {
            if(valueSize < ((EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1)) {
                if(value) { free((void*)value); value = NULL; valueSize = 0; }
                valueSize = (EGWuint)((EGWuintptr)end - (EGWuintptr)start) + 1; valueSize = valueSize + (valueSize >> 1); // x1.5
                if(!(value = (EGWchar*)malloc((size_t)valueSize))) {
                    NSLog(@"egwParseStringtcv: Failure allocating memory for temporary storage.");
                    return processed;
                }
            }
            
            strncpy((char*)value, (const char*)start, (size_t)((EGWuintptr)end - (EGWuintptr)start)); value[(EGWuint)((EGWuintptr)end - (EGWuintptr)start)] = '\0';
            
            *array_out = (EGWtriple)atof((const char*)value);
            array_out = (EGWtriple*)((EGWintptr)array_out + (EGWintptr)sizeof(EGWtriple) + strideB_out);
            
            ++processed;
            while((*string_in <= ' ' || *string_in == ',') && *string_in != '\0') ++string_in;
            if(*string_in == '\0') break;
            else start = end = string_in;
        }
    }
    
    if(value) { free((void*)value); value = NULL; valueSize = 0; }
    
    return processed;
}

EGWchar* egwTrimc(EGWchar* string_in) {
    EGWchar* end = string_in;
    
    while(*end != '\0') ++end;
    if(end > string_in) {
        while(end >= string_in && *end <= ' ') --end;
        *(++end) = '\0';
        while(*string_in != '\0' && *string_in <= ' ') ++string_in;
    }
    
    return string_in;
}

EGWchar* egwQTrimc(EGWchar* string_in, EGWint lengthC_in) {
    EGWchar* end = string_in;
    
    if(lengthC_in < 0)
        while(*end != '\0') ++end;
    else
        end = (EGWchar*)((EGWuintptr)string_in + ((EGWuintptr)lengthC_in * (EGWuintptr)sizeof(EGWchar)));
    
    if(end > string_in) {
        while(end >= string_in && *end <= ' ') --end;
        *(++end) = '\0';
        while(*string_in != '\0' && *string_in <= ' ') ++string_in;
    }
    
    return string_in;
}

EGWuint32 egwHash32b(const EGWbyte* data_in, EGWuint lengthB_in) {
    EGWuint32 hashVal = 5381;
    
    while(lengthB_in--) {
        hashVal = ((hashVal << 5) + hashVal) + (const EGWuint)*data_in++;
    }
    
    return (hashVal ? hashVal : 1);
}

EGWuint32 egwHash32c(const EGWchar* string_in) {
    EGWuint32 hashVal = 5381;
    
    while(*string_in != '\0') {
        hashVal = ((hashVal << 5) + hashVal) + (const EGWuint)*string_in++;
    }
    
    return (hashVal ? hashVal : 1);
}

EGWuint32 egwHashAdd32(EGWuint32 hash_lhs, EGWuint32 hash_rhs) {
    hash_lhs = ((hash_lhs << 5) + hash_lhs) + hash_rhs;
    
    return (hash_lhs ? hash_lhs : 1);
}

EGWuint64 egwHash64b(const EGWbyte* data_in, EGWuint lengthB_in) {
    EGWuint64 hashVal = 5381;
    
    while(lengthB_in--) {
        hashVal = ((hashVal << 5) + hashVal) + (const EGWuint)*data_in++;
    }
    
    return (hashVal ? hashVal : 1);
}

EGWuint64 egwHash64c(const EGWchar* string_in) {
    EGWuint64 hashVal = 5381;
    
    while(*string_in != '\0') {
        hashVal = ((hashVal << 5) + hashVal) + (const EGWuint)*string_in++;
    }
    
    return (hashVal ? hashVal : 1);
}

EGWuint64 egwHashAdd64(EGWuint64 hash_lhs, EGWuint64 hash_rhs) {
    hash_lhs = ((hash_lhs << 5) + hash_lhs) + hash_rhs;
    
    return (hash_lhs ? hash_lhs : 1);
}

void egwEndianSwapb(const EGWbyte* val_in, EGWbyte* val_out, EGWuint sizeB) {
    register const EGWbyte* valEnd_in = (const EGWbyte*)((EGWuintptr)val_in + (EGWuintptr)sizeB - (EGWuintptr)sizeof(EGWbyte));
    register EGWbyte* valEnd_out = (EGWbyte*)((EGWuintptr)val_out + (EGWuintptr)sizeB - (EGWuintptr)sizeof(EGWbyte));
    register EGWbyte temp;
    
    while((sizeB /= 2)) {
        temp = *valEnd_in;
        *valEnd_out = *val_in;
        *val_out = temp;
        
        val_in = (const EGWbyte*)((EGWuintptr)val_in + (EGWuintptr)sizeof(EGWbyte));
        valEnd_in = (const EGWbyte*)((EGWuintptr)valEnd_in - (EGWuintptr)sizeof(EGWbyte));
        val_out = (EGWbyte*)((EGWuintptr)val_out + (EGWuintptr)sizeof(EGWbyte));
        valEnd_out = (EGWbyte*)((EGWuintptr)valEnd_out - (EGWuintptr)sizeof(EGWbyte));
    }
}

void egwEndianSwapbv(const EGWbyte* vals_in, EGWbyte* vals_out, EGWuint sizeB, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        register const EGWbyte* valsEnd_in = (const EGWbyte*)((EGWuintptr)vals_in + (EGWuintptr)sizeB - (EGWuintptr)sizeof(EGWbyte));
        register EGWbyte* valsEnd_out = (EGWbyte*)((EGWuintptr)vals_out + (EGWuintptr)sizeB - (EGWuintptr)sizeof(EGWbyte));
        register EGWbyte temp;
        
        register EGWuint sizeB_count = sizeB;
        while((sizeB_count /= 2)) {
            temp = *valsEnd_in;
            *valsEnd_out = *vals_in;
            *vals_out = temp;
            
            vals_in = (const EGWbyte*)((EGWuintptr)vals_in + (EGWuintptr)sizeof(EGWbyte));
            valsEnd_in = (const EGWbyte*)((EGWuintptr)valsEnd_in - (EGWuintptr)sizeof(EGWbyte));
            vals_out = (EGWbyte*)((EGWuintptr)vals_out + (EGWuintptr)sizeof(EGWbyte));
            valsEnd_out = (EGWbyte*)((EGWuintptr)valsEnd_out - (EGWuintptr)sizeof(EGWbyte));
        }
        
        vals_in = (const EGWbyte*)((EGWintptr)vals_in + (EGWintptr)(sizeB & 1) + (EGWintptr)(sizeB >> 1) + strideB_in);
        vals_out = (EGWbyte*)((EGWintptr)vals_out + (EGWintptr)(sizeB & 1) + (EGWintptr)(sizeB >> 1) + strideB_in);
    }
}

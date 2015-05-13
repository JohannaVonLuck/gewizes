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

/// @file egwValidater.m
/// @ingroup geWizES_misc_validater
/// Validater Sync Implementation.

#import "egwValidater.h"


void (*egwSFPVldtrValidate)(id, SEL) = NULL;
void (*egwSFPVldtrInvalidate)(id, SEL) = NULL;
BOOL (*egwSFPVldtrIsValidated)(id, SEL) = NULL;
BOOL (*egwSFPVldtrIsInvalidated)(id, SEL) = NULL;


@interface egwValidater (Private)

- (void)backdoor_setValidation:(BOOL)validation;     // This is used internally to set validation status w/o sparking event handling, mainly in object tree and initBlank

@end


@implementation egwValidater

- (id)init {
    return [self initWithOwner:nil];
}

- (id)initWithOwner:(id<egwDValidationEvent>)owner {
    return [self initWithOwner:owner coreObjectTypes:EGW_COREOBJ_TYPE_NONE];
}

- (id)initWithOwner:(id<egwDValidationEvent>)owner coreObjectTypes:(EGWuint)coreObjects {
    return [self initWithOwner:owner validation:NO coreObjectTypes:coreObjects];
}

- (id)initWithOwner:(id<egwDValidationEvent>)owner validation:(BOOL)validation coreObjectTypes:(EGWuint)coreObjects {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    _owner = owner;
    if(_owner) {
        _fpOwnDidVld = (void(*)(id,SEL,id))[(NSObject*)owner methodForSelector:@selector(validaterDidValidate:)];
        _fpOwnDidInvld = (void(*)(id,SEL,id))[(NSObject*)owner methodForSelector:@selector(validaterDidInvalidate:)];
    } else {
        _fpOwnDidVld = NULL;
        _fpOwnDidInvld = NULL;
    }
    
    _cType = (EGWuint16)coreObjects;
    _isValidated = validation;
    
    return self;
}

- (void)dealloc {
    _owner = nil;
    
    [super dealloc];
}

- (void)invalidate {
    if(!_isIgnoring && _isValidated) {
        _isValidated = NO;
        if(_fpOwnDidInvld)
            _fpOwnDidInvld(_owner, @selector(validaterDidInvalidate:), self);
    }
}

- (void)validate {
    if(!_isIgnoring && !_isValidated) {
        _isValidated = YES;
        if(_fpOwnDidVld)
            _fpOwnDidVld(_owner, @selector(validaterDidValidate:), self);
    }
}

- (id<egwDValidationEvent>)owner {
    return _owner;
}

- (EGWuint)coreObjects {
    return (EGWuint)_cType;
}

- (void)setIgnoreValidations:(BOOL)status {
    _isIgnoring = status;
}

- (BOOL)isIgnoringValidations {
    return _isIgnoring;
}

- (BOOL)isValidated {
    return _isValidated;
}

- (BOOL)isInvalidated {
    return !_isValidated;
}

@end


@implementation egwValidater (Private)

- (void)backdoor_setValidation:(BOOL)validation {
    _isValidated = validation;
}

@end

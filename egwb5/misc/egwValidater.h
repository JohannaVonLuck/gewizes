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

/// @defgroup geWizES_misc_validater egwValidater
/// @ingroup geWizES_misc
/// Validater Sync.
/// @{

/// @file egwValidater.h
/// Validater Sync Interface.

#import "egwMiscTypes.h"
#import "../sys/egwSysTypes.h"


extern void (*egwSFPVldtrValidate)(id, SEL);        ///< Shared validate IMP function pointer (to reduce dynamic lookup).
extern void (*egwSFPVldtrInvalidate)(id, SEL);      ///< Shared invalidate IMP function pointer (to reduce dynamic lookup).
extern BOOL (*egwSFPVldtrIsValidated)(id, SEL);     ///< Shared isValidated IMP function pointer (to reduce dynamic lookup).
extern BOOL (*egwSFPVldtrIsInvalidated)(id, SEL);   ///< Shared isInvalidated IMP function pointer (to reduce dynamic lookup).


/// Validater Sync.
/// Provides a simple synchronization/validation tracker type with an event responder.
@interface egwValidater : NSObject {
    id<egwDValidationEvent> _owner;         ///< Owner (weak).
    
    void (*_fpOwnDidVld)(id,SEL,id);        ///< Owner validate CB IMP function pointer.
    void (*_fpOwnDidInvld)(id,SEL,id);      ///< Owner invalidate CB IMP function pointer.
    
    EGWuint16 _cType;                       ///< Core object type.
    BOOL _isValidated;                      ///< Tracks validation status.
    BOOL _isIgnoring;                       ///< Tracks ignoring validation status.
}

/// Initializer.
/// Initializes the validater with provided settings.
/// @param [in] owner Validater owner (weak).
/// @return Self upon success, otherwise nil.
- (id)initWithOwner:(id<egwDValidationEvent>)owner;

/// Initializer.
/// Initializes the validater with provided settings.
/// @param [in] owner Validater owner (weak).
/// @param [in] coreObjects Bit-wise core validation objects setting.
/// @return Self upon success, otherwise nil.
- (id)initWithOwner:(id<egwDValidationEvent>)owner coreObjectTypes:(EGWuint)coreObjects;

/// Designated Initializer.
/// Initializes the validater with provided settings.
/// @param [in] owner Validater owner (weak).
/// @param [in] validation Initial validation value.
/// @param [in] coreObjects Bit-wise core validation objects setting.
/// @return Self upon success, otherwise nil.
- (id)initWithOwner:(id<egwDValidationEvent>)owner validation:(BOOL)validation coreObjectTypes:(EGWuint)coreObjects;


/// Invalidate Method,
/// Invalidates the validater (if validated) and alerts owner.
- (void)invalidate;

/// Validate Method.
/// Validates the validater (if invalidated) and alerts owner.
- (void)validate;


/// Owner Accessor.
/// Returns the owner object of this validater.
/// @return Owner object.
- (id<egwDValidationEvent>)owner;

/// Core Object Accessor.
/// Returns the validater's managed core object types.
/// @return Bit-wise core object types.
- (EGWuint)coreObjects;


/// Ignore Validations Mutator.
/// Sets the ignore validations status to @a status.
/// @param [in] status Ignore status.
- (void)setIgnoreValidations:(BOOL)status;


/// IsIgnoringValidations Poller.
/// Polls the object to determine status.
/// @return YES if validater is ignoring validation messages, otherwise NO.
- (BOOL)isIgnoringValidations;

/// IsValidated Poller.
/// Polls the object to determine status.
/// @return YES if validater is validated, otherwise NO.
- (BOOL)isValidated;

/// IsInvalidated Poller.
/// Polls the object to determine status.
/// @return YES if validater is invalidated, otherwise NO.
- (BOOL)isInvalidated;

@end

/// @}

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

/// @defgroup geWizES_misc_boxingtypes egwBoxingTypes
/// @ingroup geWizES_misc
/// Boxing Types.
/// @{

/// @file egwBoxingTypes.h
/// Boxing Types Interfaces.

#import "egwMiscTypes.h"


// !!!: ***** Integers *****

/// 8-bit Integer Class.
/// A class wrapper for 8-bit integers.
@interface egwInt8 : NSObject <NSCoding, NSCopying> {
    EGWint8 _value;                         ///< Stored value.
}

/// Designated Initializer.
/// Initializes class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return Self upon success, otherwise nil.
- (id)initWithValue:(EGWint8)value;

/// Integer Producer.
/// Produces an autoreleased class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return New autoreleased object upon success, otherwise nil.
+ (id)integerWithValue:(EGWint8)value;

/// Value Accessor.
/// Returns stored value.
/// @return Stored value.
- (EGWint8)value;

/// Value Mutator.
/// Sets stored value.
/// @param [in] value Value to store.
- (void)setValue:(EGWint8)value;

@end


/// 16-bit Integer Class.
/// A class wrapper for 16-bit integers.
@interface egwInt16 : NSObject <NSCoding, NSCopying> {
    EGWint16 _value;                        ///< Stored value.
}

/// Designated Initializer.
/// Initializes class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return Self upon success, otherwise nil.
- (id)initWithValue:(EGWint16)value;

/// Integer Producer.
/// Produces an autoreleased class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return New autoreleased object upon success, otherwise nil.
+ (id)integerWithValue:(EGWint16)value;

/// Value Accessor.
/// Returns stored value.
/// @return Stored value.
- (EGWint16)value;

/// Value Mutator.
/// Sets stored value.
/// @param [in] value Value to store.
- (void)setValue:(EGWint16)value;

@end


/// 32-bit Integer Class.
/// A class wrapper for 32-bit integers.
@interface egwInt32 : NSObject <NSCoding, NSCopying> {
    EGWint32 _value;                        ///< Stored value.
}

/// Designated Initializer.
/// Initializes class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return Self upon success, otherwise nil.
- (id)initWithValue:(EGWint32)value;

/// Integer Producer.
/// Produces an autoreleased class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return New autoreleased object upon success, otherwise nil.
+ (id)integerWithValue:(EGWint32)value;

/// Value Accessor.
/// Returns stored value.
/// @return Stored value.
- (EGWint32)value;

/// Value Mutator.
/// Sets stored value.
/// @param [in] value Value to store.
- (void)setValue:(EGWint32)value;

@end


/// 64-bit Integer Class.
/// A class wrapper for 64-bit integers.
@interface egwInt64 : NSObject <NSCoding, NSCopying> {
    EGWint64 _value;                        ///< Stored value.
}

/// Designated Initializer.
/// Initializes class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return Self upon success, otherwise nil.
- (id)initWithValue:(EGWint64)value;

/// Integer Producer.
/// Produces an autoreleased class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return New autoreleased object upon success, otherwise nil.
+ (id)integerWithValue:(EGWint64)value;

/// Value Accessor.
/// Returns stored value.
/// @return Stored value.
- (EGWint64)value;

/// Value Mutator.
/// Sets stored value.
/// @param [in] value Value to store.
- (void)setValue:(EGWint64)value;

@end


// !!!: ***** Unsigned Integers *****

/// 8-bit Unsigned Integer Class.
/// A class wrapper for 8-bit unsigned integers.
@interface egwUInt8 : NSObject <NSCoding, NSCopying> {
    EGWuint8 _value;                        ///< Stored value.
}

/// Designated Initializer.
/// Initializes class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return Self upon success, otherwise nil.
- (id)initWithValue:(EGWuint8)value;

/// Integer Producer.
/// Produces an autoreleased class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return New autoreleased object upon success, otherwise nil.
+ (id)integerWithValue:(EGWuint8)value;

/// Value Accessor.
/// Returns stored value.
/// @return Stored value.
- (EGWuint8)value;

/// Value Mutator.
/// Sets stored value.
/// @param [in] value Value to store.
- (void)setValue:(EGWuint8)value;

@end


/// 16-bit Unsigned Integer Class.
/// A class wrapper for 16-bit unsigned integers.
@interface egwUInt16 : NSObject <NSCoding, NSCopying> {
    EGWuint16 _value;                       ///< Stored value.
}

/// Designated Initializer.
/// Initializes class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return Self upon success, otherwise nil.
- (id)initWithValue:(EGWuint16)value;

/// Integer Producer.
/// Produces an autoreleased class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return New autoreleased object upon success, otherwise nil.
+ (id)integerWithValue:(EGWuint16)value;

/// Value Accessor.
/// Returns stored value.
/// @return Stored value.
- (EGWuint16)value;

/// Value Mutator.
/// Sets stored value.
/// @param [in] value Value to store.
- (void)setValue:(EGWuint16)value;

@end


/// 32-bit Unsigned Integer Class.
/// A class wrapper for 32-bit unsigned integers.
@interface egwUInt32 : NSObject <NSCoding, NSCopying> {
    EGWuint32 _value;                       ///< Stored value.
}

/// Designated Initializer.
/// Initializes class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return Self upon success, otherwise nil.
- (id)initWithValue:(EGWuint32)value;

/// Integer Producer.
/// Produces an autoreleased class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return New autoreleased object upon success, otherwise nil.
+ (id)integerWithValue:(EGWuint32)value;

/// Value Accessor.
/// Returns stored value.
/// @return Stored value.
- (EGWuint32)value;

/// Value Mutator.
/// Sets stored value.
/// @param [in] value Value to store.
- (void)setValue:(EGWuint32)value;

@end


/// 64-bit Unsigned Integer Class.
/// A class wrapper for 64-bit unsigned integers.
@interface egwUInt64 : NSObject <NSCoding, NSCopying> {
    EGWuint64 _value;                       ///< Stored value.
}

/// Designated Initializer.
/// Initializes class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return Self upon success, otherwise nil.
- (id)initWithValue:(EGWuint64)value;

/// Integer Producer.
/// Produces an autoreleased class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return New autoreleased object upon success, otherwise nil.
+ (id)integerWithValue:(EGWuint64)value;

/// Value Accessor.
/// Returns stored value.
/// @return Stored value.
- (EGWuint64)value;

/// Value Mutator.
/// Sets stored value.
/// @param [in] value Value to store.
- (void)setValue:(EGWuint64)value;

@end


// !!!: ***** Native Integers *****

/// Integer Class.
/// A class wrapper for native register-sized integers.
@interface egwInt : NSObject <NSCoding, NSCopying> {
    EGWint _value;                          ///< Stored value.
}

/// Designated Initializer.
/// Initializes class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return Self upon success, otherwise nil.
- (id)initWithValue:(EGWint)value;

/// Integer Producer.
/// Produces an autoreleased class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return New autoreleased object upon success, otherwise nil.
+ (id)integerWithValue:(EGWint)value;

/// Value Accessor.
/// Returns stored value.
/// @return Stored value.
- (EGWint)value;

/// Value Mutator.
/// Sets stored value.
/// @param [in] value Value to store.
- (void)setValue:(EGWint)value;

@end


/// Unsigned Integer Class.
/// A class wrapper for native register-sized unsigned integers.
@interface egwUInt : NSObject <NSCoding, NSCopying> {
    EGWuint _value;                         ///< Stored value.
}

/// Designated Initializer.
/// Initializes class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return Self upon success, otherwise nil.
- (id)initWithValue:(EGWuint)value;

/// Integer Producer.
/// Produces an autoreleased class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return New autoreleased object upon success, otherwise nil.
+ (id)integerWithValue:(EGWuint)value;

/// Value Accessor.
/// Returns stored value.
/// @return Stored value.
- (EGWuint)value;

/// Value Mutator.
/// Sets stored value.
/// @param [in] value Value to store.
- (void)setValue:(EGWuint)value;

@end


// !!!: ***** Floaters *****

/// Single Precision Float Class.
/// A class wrapper for single precision floats.
@interface egwSingle : NSObject <NSCoding, NSCopying> {
    EGWsingle _value;                       ///< Stored value.
}

/// Designated Initializer.
/// Initializes class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return Self upon success, otherwise nil.
- (id)initWithValue:(EGWsingle)value;

/// Floater Producer.
/// Produces an autoreleased class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return New autoreleased object upon success, otherwise nil.
+ (id)floaterWithValue:(EGWsingle)value;

/// Value Accessor.
/// Returns stored value.
/// @return Stored value.
- (EGWsingle)value;

/// Value Mutator.
/// Sets stored value.
/// @param [in] value Value to store.
- (void)setValue:(EGWsingle)value;

@end


/// Double Precision Float Class.
/// A class wrapper for double precision floats.
@interface egwDouble : NSObject <NSCoding, NSCopying> {
    EGWdouble _value;                       ///< Stored value.
}

/// Designated Initializer.
/// Initializes class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return Self upon success, otherwise nil.
- (id)initWithValue:(EGWdouble)value;

/// Floater Producer.
/// Produces an autoreleased class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return New autoreleased object upon success, otherwise nil.
+ (id)floaterWithValue:(EGWdouble)value;

/// Value Accessor.
/// Returns stored value.
/// @return Stored value.
- (EGWdouble)value;

/// Value Mutator.
/// Sets stored value.
/// @param [in] value Value to store.
- (void)setValue:(EGWdouble)value;

@end


/// Triple Precision Float Class.
/// A class wrapper for triple precision floats.
@interface egwTriple : NSObject <NSCoding, NSCopying> {
    EGWtriple _value;                       ///< Stored value.
}

/// Designated Initializer.
/// Initializes class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return Self upon success, otherwise nil.
- (id)initWithValue:(EGWtriple)value;

/// Floater Producer.
/// Produces an autoreleased class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return New autoreleased object upon success, otherwise nil.
+ (id)floaterWithValue:(EGWtriple)value;

/// Value Accessor.
/// Returns stored value.
/// @return Stored value.
- (EGWtriple)value;

/// Value Mutator.
/// Sets stored value.
/// @param [in] value Value to store.
- (void)setValue:(EGWtriple)value;

@end


// !!!: ***** Other *****

/// Time Precision Class.
/// A class wrapper for time precision floats.
@interface egwTime : NSObject <NSCoding, NSCopying> {
    EGWtime _value;                         ///< Stored value.
}

/// Designated Initializer.
/// Initializes class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return Self upon success, otherwise nil.
- (id)initWithValue:(EGWtime)value;

/// Time Producer.
/// Produces an autoreleased class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return New autoreleased object upon success, otherwise nil.
+ (id)timeWithValue:(EGWtime)value;

/// Value Accessor.
/// Returns stored value.
/// @return Stored value.
- (EGWtime)value;

/// Value Mutator.
/// Sets stored value.
/// @param [in] value Value to store.
- (void)setValue:(EGWtime)value;

@end


/// Pointer Class.
/// A class wrapper for pointers.
@interface egwPointer : NSObject <NSCoding, NSCopying> {
    void* _value;                           ///< Stored value.
}

/// Designated Initializer.
/// Initializes class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return Self upon success, otherwise nil.
- (id)initWithValue:(void*)value;

/// Pointer Producer.
/// Produces an autoreleased class wrapper with provided @a value.
/// @param [in] value Value to store.
/// @return New autoreleased object upon success, otherwise nil.
+ (id)pointerWithValue:(void*)value;

/// Value Accessor.
/// Returns stored value.
/// @return Stored value.
- (void*)value;

/// Value Mutator.
/// Sets stored value.
/// @param [in] value Value to store.
- (void)setValue:(void*)value;

@end

/// @}

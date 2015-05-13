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

/// @file egwBoxingTypes.m
/// @ingroup geWizES_misc_boxingtypes
/// Boxing Types Implementations.

#import "egwBoxingTypes.h"
#import "../sys/egwSystem.h"
#import "../math/egwMath.h"


static NSUInteger _numBytes;


@implementation egwInt8
- (id)init { _value = (EGWint8)0; return (self = [super init]); }
- (id)initWithValue:(EGWint8)value { _value = value; return (self = [super init]); }
+ (id)integerWithValue:(EGWint8)value { return [[(egwInt8*)[egwInt8 alloc] initWithValue:value] autorelease]; }
- (EGWint8)value { return _value; }
- (void)setValue:(EGWint8)value { _value = value; }
- (BOOL)isEqual:(id)object { return ([object respondsToSelector:@selector(value)] && (EGWint64)[(egwInt64*)object value] == (EGWint64)_value) ? YES : NO; }
- (NSUInteger)hash { return (NSUInteger)egwHash32b((const EGWbyte*)&_value, sizeof(EGWint8)); }
- (NSString*)description { return [NSString stringWithFormat:@"int8:%qi", (EGWint64)_value]; }
- (id)copyWithZone:(NSZone*)zone { return [(egwInt8*)[egwInt8 allocWithZone:zone] initWithValue:_value]; }
- (void)encodeWithCoder:(NSCoder*)aCoder { [aCoder encodeBytes:&_value length:sizeof(EGWint8)]; }
- (id)initWithCoder:(NSCoder*)aDecoder { _value = *(EGWint8*)[aDecoder decodeBytesWithReturnedLength:&_numBytes]; return (self = [super init]); }
@end


@implementation egwInt16
- (id)init { _value = (EGWint16)0; return (self = [super init]); }
- (id)initWithValue:(EGWint16)value { _value = value; return (self = [super init]); }
+ (id)integerWithValue:(EGWint16)value { return [[(egwInt16*)[egwInt16 alloc] initWithValue:value] autorelease]; }
- (EGWint16)value { return _value; }
- (void)setValue:(EGWint16)value { _value = value; }
- (BOOL)isEqual:(id)object { return ([object respondsToSelector:@selector(value)] && (EGWint64)[(egwInt64*)object value] == (EGWint64)_value) ? YES : NO; }
- (NSUInteger)hash { return (NSUInteger)egwHash32b((const EGWbyte*)&_value, sizeof(EGWint16)); }
- (NSString*)description { return [NSString stringWithFormat:@"int16:%qi", (EGWint64)_value]; }
- (id)copyWithZone:(NSZone*)zone { return [(egwInt16*)[egwInt16 allocWithZone:zone] initWithValue:_value]; }
- (void)encodeWithCoder:(NSCoder*)aCoder { [aCoder encodeBytes:&_value length:sizeof(EGWint16)]; }
- (id)initWithCoder:(NSCoder*)aDecoder { _value = *(EGWint16*)[aDecoder decodeBytesWithReturnedLength:&_numBytes]; return (self = [super init]); }
@end


@implementation egwInt32
- (id)init { _value = (EGWint32)0; return (self = [super init]); }
- (id)initWithValue:(EGWint32)value { _value = value; return (self = [super init]); }
+ (id)integerWithValue:(EGWint32)value { return [[(egwInt32*)[egwInt32 alloc] initWithValue:value] autorelease]; }
- (EGWint32)value { return _value; }
- (void)setValue:(EGWint32)value { _value = value; }
- (BOOL)isEqual:(id)object { return ([object respondsToSelector:@selector(value)] && (EGWint64)[(egwInt64*)object value] == (EGWint64)_value) ? YES : NO; }
- (NSUInteger)hash { return (NSUInteger)egwHash32b((const EGWbyte*)&_value, sizeof(EGWint32)); }
- (NSString*)description { return [NSString stringWithFormat:@"int32:%qi", (EGWint64)_value]; }
- (id)copyWithZone:(NSZone*)zone { return [(egwInt32*)[egwInt32 allocWithZone:zone] initWithValue:_value]; }
- (void)encodeWithCoder:(NSCoder*)aCoder { [aCoder encodeBytes:&_value length:sizeof(EGWint32)]; }
- (id)initWithCoder:(NSCoder*)aDecoder { _value = *(EGWint32*)[aDecoder decodeBytesWithReturnedLength:&_numBytes]; return (self = [super init]); }
@end


@implementation egwInt64
- (id)init { _value = (EGWint64)0; return (self = [super init]); }
- (id)initWithValue:(EGWint64)value { _value = value; return (self = [super init]); }
+ (id)integerWithValue:(EGWint64)value { return [[(egwInt64*)[egwInt64 alloc] initWithValue:value] autorelease]; }
- (EGWint64)value { return _value; }
- (void)setValue:(EGWint64)value { _value = value; }
- (BOOL)isEqual:(id)object { return ([object respondsToSelector:@selector(value)] && (EGWint64)[(egwInt64*)object value] == (EGWint64)_value) ? YES : NO; }
- (NSUInteger)hash { return (NSUInteger)egwHash32b((const EGWbyte*)&_value, sizeof(EGWint64)); }
- (NSString*)description { return [NSString stringWithFormat:@"int64:%qi", (EGWint64)_value]; }
- (id)copyWithZone:(NSZone*)zone { return [(egwInt64*)[egwInt64 allocWithZone:zone] initWithValue:_value]; }
- (void)encodeWithCoder:(NSCoder*)aCoder { [aCoder encodeBytes:&_value length:sizeof(EGWint64)]; }
- (id)initWithCoder:(NSCoder*)aDecoder { _value = *(EGWint64*)[aDecoder decodeBytesWithReturnedLength:&_numBytes]; return (self = [super init]); }
@end


@implementation egwUInt8
- (id)init { _value = (EGWuint8)0; return (self = [super init]); }
- (id)initWithValue:(EGWuint8)value { _value = value; return (self = [super init]); }
+ (id)integerWithValue:(EGWuint8)value { return [[(egwUInt8*)[egwUInt8 alloc] initWithValue:value] autorelease]; }
- (EGWuint8)value { return _value; }
- (void)setValue:(EGWuint8)value { _value = value; }
- (BOOL)isEqual:(id)object { return ([object respondsToSelector:@selector(value)] && (EGWuint64)[(egwUInt64*)object value] == (EGWuint64)_value) ? YES : NO; }
- (NSUInteger)hash { return (NSUInteger)egwHash32b((const EGWbyte*)&_value, sizeof(EGWuint8)); }
- (NSString*)description { return [NSString stringWithFormat:@"uint8:%qu", (EGWuint64)_value]; }
- (id)copyWithZone:(NSZone*)zone { return [(egwUInt8*)[egwUInt8 allocWithZone:zone] initWithValue:_value]; }
- (void)encodeWithCoder:(NSCoder*)aCoder { [aCoder encodeBytes:&_value length:sizeof(EGWuint8)]; }
- (id)initWithCoder:(NSCoder*)aDecoder { _value = *(EGWuint8*)[aDecoder decodeBytesWithReturnedLength:&_numBytes]; return (self = [super init]); }
@end


@implementation egwUInt16
- (id)init { _value = (EGWuint16)0; return (self = [super init]); }
- (id)initWithValue:(EGWuint16)value { _value = value; return (self = [super init]); }
+ (id)integerWithValue:(EGWuint16)value { return [[(egwUInt16*)[egwUInt16 alloc] initWithValue:value] autorelease]; }
- (EGWuint16)value { return _value; }
- (void)setValue:(EGWuint16)value { _value = value; }
- (BOOL)isEqual:(id)object { return ([object respondsToSelector:@selector(value)] && (EGWuint64)[(egwUInt64*)object value] == (EGWuint64)_value) ? YES : NO; }
- (NSUInteger)hash { return (NSUInteger)egwHash32b((const EGWbyte*)&_value, sizeof(EGWuint16)); }
- (NSString*)description { return [NSString stringWithFormat:@"uint16:%qu", (EGWuint64)_value]; }
- (id)copyWithZone:(NSZone*)zone { return [(egwUInt16*)[egwUInt16 allocWithZone:zone] initWithValue:_value]; }
- (void)encodeWithCoder:(NSCoder*)aCoder { [aCoder encodeBytes:&_value length:sizeof(EGWuint16)]; }
- (id)initWithCoder:(NSCoder*)aDecoder { _value = *(EGWuint16*)[aDecoder decodeBytesWithReturnedLength:&_numBytes]; return (self = [super init]); }
@end


@implementation egwUInt32
- (id)init { _value = (EGWuint32)0; return (self = [super init]); }
- (id)initWithValue:(EGWuint32)value { _value = value; return (self = [super init]); }
+ (id)integerWithValue:(EGWuint32)value { return [[(egwUInt32*)[egwUInt32 alloc] initWithValue:value] autorelease]; }
- (EGWuint32)value { return _value; }
- (void)setValue:(EGWuint32)value { _value = value; }
- (BOOL)isEqual:(id)object { return ([object respondsToSelector:@selector(value)] && (EGWuint64)[(egwUInt64*)object value] == (EGWuint64)_value) ? YES : NO; }
- (NSUInteger)hash { return (NSUInteger)egwHash32b((const EGWbyte*)&_value, sizeof(EGWuint32)); }
- (NSString*)description { return [NSString stringWithFormat:@"uint32:%qu", (EGWuint64)_value]; }
- (id)copyWithZone:(NSZone*)zone { return [(egwUInt32*)[egwUInt32 allocWithZone:zone] initWithValue:_value]; }
- (void)encodeWithCoder:(NSCoder*)aCoder { [aCoder encodeBytes:&_value length:sizeof(EGWuint32)]; }
- (id)initWithCoder:(NSCoder*)aDecoder { _value = *(EGWuint32*)[aDecoder decodeBytesWithReturnedLength:&_numBytes]; return (self = [super init]); }
@end


@implementation egwUInt64
- (id)init { _value = (EGWuint64)0; return (self = [super init]); }
- (id)initWithValue:(EGWuint64)value { _value = value; return (self = [super init]); }
+ (id)integerWithValue:(EGWuint64)value { return [[(egwUInt64*)[egwUInt64 alloc] initWithValue:value] autorelease]; }
- (EGWuint64)value { return _value; }
- (void)setValue:(EGWuint64)value { _value = value; }
- (BOOL)isEqual:(id)object { return ([object respondsToSelector:@selector(value)] && (EGWuint64)[(egwUInt64*)object value] == (EGWuint64)_value) ? YES : NO; }
- (NSUInteger)hash { return (NSUInteger)egwHash32b((const EGWbyte*)&_value, sizeof(EGWuint64)); }
- (NSString*)description { return [NSString stringWithFormat:@"uint64:%qu", (EGWuint64)_value]; }
- (id)copyWithZone:(NSZone*)zone { return [(egwUInt64*)[egwUInt64 allocWithZone:zone] initWithValue:_value]; }
- (void)encodeWithCoder:(NSCoder*)aCoder { [aCoder encodeBytes:&_value length:sizeof(EGWuint64)]; }
- (id)initWithCoder:(NSCoder*)aDecoder { _value = *(EGWuint64*)[aDecoder decodeBytesWithReturnedLength:&_numBytes]; return (self = [super init]); }
@end


@implementation egwInt
- (id)init { _value = (EGWint)0; return (self = [super init]); }
- (id)initWithValue:(EGWint)value { _value = value; return (self = [super init]); }
+ (id)integerWithValue:(EGWint)value { return [[(egwInt*)[egwInt alloc] initWithValue:value] autorelease]; }
- (EGWint)value { return _value; }
- (void)setValue:(EGWint)value { _value = value; }
- (BOOL)isEqual:(id)object { return ([object respondsToSelector:@selector(value)] && (EGWint64)[(egwInt64*)object value] == (EGWint64)_value) ? YES : NO; }
- (NSUInteger)hash { return (NSUInteger)egwHash32b((const EGWbyte*)&_value, sizeof(EGWint)); }
- (NSString*)description { return [NSString stringWithFormat:@"int:%qi", (EGWint64)_value]; }
- (id)copyWithZone:(NSZone*)zone { return [(egwInt*)[egwInt allocWithZone:zone] initWithValue:_value]; }
- (void)encodeWithCoder:(NSCoder*)aCoder { [aCoder encodeBytes:&_value length:sizeof(EGWint)]; }
- (id)initWithCoder:(NSCoder*)aDecoder { _value = *(EGWint*)[aDecoder decodeBytesWithReturnedLength:&_numBytes]; return (self = [super init]); }
@end


@implementation egwUInt
- (id)init { _value = (EGWuint)0; return (self = [super init]); }
- (id)initWithValue:(EGWuint)value { _value = value; return (self = [super init]); }
+ (id)integerWithValue:(EGWuint)value { return [[(egwUInt*)[egwUInt alloc] initWithValue:value] autorelease]; }
- (EGWuint)value { return _value; }
- (void)setValue:(EGWuint)value { _value = value; }
- (BOOL)isEqual:(id)object { return ([object respondsToSelector:@selector(value)] && (EGWuint64)[(egwUInt64*)object value] == (EGWuint64)_value) ? YES : NO; }
- (NSUInteger)hash { return (NSUInteger)egwHash32b((const EGWbyte*)&_value, sizeof(EGWuint)); }
- (NSString*)description { return [NSString stringWithFormat:@"uint:%qi", (EGWuint64)_value]; }
- (id)copyWithZone:(NSZone*)zone { return [(egwUInt*)[egwUInt allocWithZone:zone] initWithValue:_value]; }
- (void)encodeWithCoder:(NSCoder*)aCoder { [aCoder encodeBytes:&_value length:sizeof(EGWuint)]; }
- (id)initWithCoder:(NSCoder*)aDecoder { _value = *(EGWuint*)[aDecoder decodeBytesWithReturnedLength:&_numBytes]; return (self = [super init]); }
@end


@implementation egwSingle
- (id)init { _value = (EGWsingle)0; return (self = [super init]); }
- (id)initWithValue:(EGWsingle)value { _value = value; return (self = [super init]); }
+ (id)floaterWithValue:(EGWsingle)value { return [[(egwSingle*)[egwSingle alloc] initWithValue:value] autorelease]; }
- (EGWsingle)value { return _value; }
- (void)setValue:(EGWsingle)value { _value = value; }
- (BOOL)isEqual:(id)object { return ([object respondsToSelector:@selector(value)] && egwIsEqualf((EGWsingle)[(egwSingle*)object value], (EGWsingle)_value)) ? YES : NO; }
- (NSUInteger)hash { return (NSUInteger)egwHash32b((const EGWbyte*)&_value, sizeof(EGWsingle)); }
- (NSString*)description { return [NSString stringWithFormat:@"single:%f", (EGWdouble)_value]; }
- (id)copyWithZone:(NSZone*)zone { return [(egwSingle*)[egwSingle allocWithZone:zone] initWithValue:_value]; }
- (void)encodeWithCoder:(NSCoder*)aCoder { [aCoder encodeBytes:&_value length:sizeof(EGWsingle)]; }
- (id)initWithCoder:(NSCoder*)aDecoder { _value = *(EGWsingle*)[aDecoder decodeBytesWithReturnedLength:&_numBytes]; return (self = [super init]); }
@end


@implementation egwDouble
- (id)init { _value = (EGWdouble)0; return (self = [super init]); }
- (id)initWithValue:(EGWdouble)value { _value = value; return (self = [super init]); }
+ (id)floaterWithValue:(EGWdouble)value { return [[(egwDouble*)[egwDouble alloc] initWithValue:value] autorelease]; }
- (EGWdouble)value { return _value; }
- (void)setValue:(EGWdouble)value { _value = value; }
- (BOOL)isEqual:(id)object { return ([object respondsToSelector:@selector(value)] && egwIsEqualf((EGWsingle)[(egwSingle*)object value], (EGWsingle)_value)) ? YES : NO; }
- (NSUInteger)hash { return (NSUInteger)egwHash32b((const EGWbyte*)&_value, sizeof(EGWdouble)); }
- (NSString*)description { return [NSString stringWithFormat:@"double:%f", (EGWdouble)_value]; }
- (id)copyWithZone:(NSZone*)zone { return [(egwDouble*)[egwDouble allocWithZone:zone] initWithValue:_value]; }
- (void)encodeWithCoder:(NSCoder*)aCoder { [aCoder encodeBytes:&_value length:sizeof(EGWdouble)]; }
- (id)initWithCoder:(NSCoder*)aDecoder { _value = *(EGWdouble*)[aDecoder decodeBytesWithReturnedLength:&_numBytes]; return (self = [super init]); }
@end


@implementation egwTriple
- (id)init { _value = (EGWtriple)0; return (self = [super init]); }
- (id)initWithValue:(EGWtriple)value { _value = value; return (self = [super init]); }
+ (id)floaterWithValue:(EGWtriple)value { return [[(egwTriple*)[egwTriple alloc] initWithValue:value] autorelease]; }
- (EGWtriple)value { return _value; }
- (void)setValue:(EGWtriple)value { _value = value; }
- (BOOL)isEqual:(id)object { return ([object respondsToSelector:@selector(value)] && egwIsEqualf((EGWsingle)[(egwSingle*)object value], (EGWsingle)_value)) ? YES : NO; }
- (NSUInteger)hash { return (NSUInteger)egwHash32b((const EGWbyte*)&_value, sizeof(EGWtriple)); }
- (NSString*)description { return [NSString stringWithFormat:@"triple:%f", (EGWdouble)_value]; }
- (id)copyWithZone:(NSZone*)zone { return [(egwTriple*)[egwTriple allocWithZone:zone] initWithValue:_value]; }
- (void)encodeWithCoder:(NSCoder*)aCoder { [aCoder encodeBytes:&_value length:sizeof(EGWtriple)]; }
- (id)initWithCoder:(NSCoder*)aDecoder { _value = *(EGWtriple*)[aDecoder decodeBytesWithReturnedLength:&_numBytes]; return (self = [super init]); }
@end


@implementation egwTime
- (id)init { _value = (EGWtime)0; return (self = [super init]); }
- (id)initWithValue:(EGWtime)value { _value = value; return (self = [super init]); }
+ (id)timeWithValue:(EGWtime)value { return [[(egwTime*)[egwTime alloc] initWithValue:value] autorelease]; }
- (EGWtime)value { return _value; }
- (void)setValue:(EGWtime)value { _value = value; }
- (BOOL)isEqual:(id)object { return ([object respondsToSelector:@selector(value)] && egwIsEqualf((EGWsingle)[(egwSingle*)object value], (EGWsingle)_value)) ? YES : NO; }
- (NSUInteger)hash { return (NSUInteger)egwHash32b((const EGWbyte*)&_value, sizeof(EGWtime)); }
- (NSString*)description { return [NSString stringWithFormat:@"time:%f", (EGWtime)_value]; }
- (id)copyWithZone:(NSZone*)zone { return [(egwTime*)[egwTime allocWithZone:zone] initWithValue:_value]; }
- (void)encodeWithCoder:(NSCoder*)aCoder { [aCoder encodeBytes:&_value length:sizeof(EGWtime)]; }
- (id)initWithCoder:(NSCoder*)aDecoder { _value = *(EGWtime*)[aDecoder decodeBytesWithReturnedLength:&_numBytes]; return (self = [super init]); }
@end


@implementation egwPointer
- (id)init { _value = (void*)0; return (self = [super init]); }
- (id)initWithValue:(void*)value { _value = value; return (self = [super init]); }
+ (id)pointerWithValue:(void*)value { return [[(egwPointer*)[egwPointer alloc] initWithValue:value] autorelease]; }
- (void*)value { return _value; }
- (void)setValue:(void*)value { _value = value; }
- (BOOL)isEqual:(id)object { return ([object respondsToSelector:@selector(value)] && (EGWuintptr)[object performSelector:@selector(value)] == (EGWuintptr)_value) ? YES : NO; }
- (NSUInteger)hash { return (NSUInteger)egwHash32b((const EGWbyte*)&_value, sizeof(void*)); }
- (NSString*)description { return [NSString stringWithFormat:@"pointer:%p", (void*)_value]; }
- (id)copyWithZone:(NSZone*)zone { return [(egwPointer*)[egwPointer allocWithZone:zone] initWithValue:_value]; }
- (void)encodeWithCoder:(NSCoder*)aCoder { [aCoder encodeBytes:&_value length:sizeof(void*)]; }
- (id)initWithCoder:(NSCoder*)aDecoder { _value = (void*)*(EGWuintptr*)[aDecoder decodeBytesWithReturnedLength:&_numBytes]; return (self = [super init]); }
@end

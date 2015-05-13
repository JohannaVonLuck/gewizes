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

/// @defgroup geWizES_sys_system egwSystem
/// @ingroup geWizES_sys
/// Base System.
/// @{

/// @file egwSystem.h
/// Base System Interface.

#import "egwSysTypes.h"


// !!!: ***** String Routines *****

/// Parse String Routine.
/// Parses a string and extracts an array of values with provided parameters.
/// @note Deliminators are treated as any spaces, new lines, commas, or other control characters (i.e. <= ' ' || == ',').
/// @param [in] string_in Null-terminated string input operand.
/// @param [out] array_out Array of signed 8-bit integer value output operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
/// @return Number of elements parsed.
EGWuint egwParseStringi8cv(const EGWchar* string_in, EGWint8* array_out, EGWintptr strideB_out, EGWuint count);

/// Parse String Routine.
/// Parses a string and extracts an array of values with provided parameters.
/// @note Deliminators are treated as any spaces, new lines, commas, or other control characters (i.e. <= ' ' || == ',').
/// @param [in] string_in Null-terminated string input operand.
/// @param [out] array_out Array of signed 16-bit integer value output operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
/// @return Number of elements parsed.
EGWuint egwParseStringi16cv(const EGWchar* string_in, EGWint16* array_out, EGWintptr strideB_out, EGWuint count);

/// Parse String Routine.
/// Parses a string and extracts an array of values with provided parameters.
/// @note Deliminators are treated as any spaces, new lines, commas, or other control characters (i.e. <= ' ' || == ',').
/// @param [in] string_in Null-terminated string input operand.
/// @param [out] array_out Array of signed 32-bit integer value output operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
/// @return Number of elements parsed.
EGWuint egwParseStringi32cv(const EGWchar* string_in, EGWint32* array_out, EGWintptr strideB_out, EGWuint count);

/// Parse String Routine.
/// Parses a string and extracts an array of values with provided parameters.
/// @note Deliminators are treated as any spaces, new lines, commas, or other control characters (i.e. <= ' ' || == ',').
/// @param [in] string_in Null-terminated string input operand.
/// @param [out] array_out Array of signed 64-bit integer value output operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
/// @return Number of elements parsed.
EGWuint egwParseStringi64cv(const EGWchar* string_in, EGWint64* array_out, EGWintptr strideB_out, EGWuint count);

/// Parse String Routine.
/// Parses a string and extracts an array of values with provided parameters.
/// @note Deliminators are treated as any spaces, new lines, commas, or other control characters (i.e. <= ' ' || == ',').
/// @param [in] string_in Null-terminated string input operand.
/// @param [out] array_out Array of unsigned 8-bit integer value output operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
/// @return Number of elements parsed.
EGWuint egwParseStringui8cv(const EGWchar* string_in, EGWuint8* array_out, EGWintptr strideB_out, EGWuint count);

/// Parse String Routine.
/// Parses a string and extracts an array of values with provided parameters.
/// @note Deliminators are treated as any spaces, new lines, commas, or other control characters (i.e. <= ' ' || == ',').
/// @param [in] string_in Null-terminated string input operand.
/// @param [out] array_out Array of unsigned 16-bit integer value output operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
/// @return Number of elements parsed.
EGWuint egwParseStringui16cv(const EGWchar* string_in, EGWuint16* array_out, EGWintptr strideB_out, EGWuint count);

/// Parse String Routine.
/// Parses a string and extracts an array of values with provided parameters.
/// @note Deliminators are treated as any spaces, new lines, commas, or other control characters (i.e. <= ' ' || == ',').
/// @param [in] string_in Null-terminated string input operand.
/// @param [out] array_out Array of unsigned 32-bit integer value output operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
/// @return Number of elements parsed.
EGWuint egwParseStringui32cv(const EGWchar* string_in, EGWuint32* array_out, EGWintptr strideB_out, EGWuint count);

/// Parse String Routine.
/// Parses a string and extracts an array of values with provided parameters.
/// @note Deliminators are treated as any spaces, new lines, commas, or other control characters (i.e. <= ' ' || == ',').
/// @param [in] string_in Null-terminated string input operand.
/// @param [out] array_out Array of unsigned 64-bit integer value output operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
/// @return Number of elements parsed.
EGWuint egwParseStringui64cv(const EGWchar* string_in, EGWuint64* array_out, EGWintptr strideB_out, EGWuint count);

/// Parse String Routine.
/// Parses a string and extracts an array of values with provided parameters.
/// @note Deliminators are treated as any spaces, new lines, commas, or other control characters (i.e. <= ' ' || == ',').
/// @param [in] string_in Null-terminated string input operand.
/// @param [out] array_out Array of signed integer value output operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
/// @return Number of elements parsed.
EGWuint egwParseStringicv(const EGWchar* string_in, EGWint* array_out, EGWintptr strideB_out, EGWuint count);

/// Parse String Routine.
/// Parses a string and extracts an array of values with provided parameters.
/// @note Deliminators are treated as any spaces, new lines, commas, or other control characters (i.e. <= ' ' || == ',').
/// @param [in] string_in Null-terminated string input operand.
/// @param [out] array_out Array of unsigned integer value output operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
/// @return Number of elements parsed.
EGWuint egwParseStringuicv(const EGWchar* string_in, EGWuint* array_out, EGWintptr strideB_out, EGWuint count);

/// Parse String Routine.
/// Parses a string and extracts an array of values with provided parameters.
/// @note Deliminators are treated as any spaces, new lines, commas, or other control characters.
/// @param [in] string_in Null-terminated string input operand.
/// @param [out] array_out Array of single precision floater value output operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
/// @return Number of elements parsed.
EGWuint egwParseStringfcv(const EGWchar* string_in, EGWsingle* array_out, EGWintptr strideB_out, EGWuint count);

/// Parse String Routine.
/// Parses a string and extracts an array of values with provided parameters.
/// @note Deliminators are treated as any spaces, new lines, commas, or other control characters.
/// @param [in] string_in Null-terminated string input operand.
/// @param [out] array_out Array of double precision floater value output operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
/// @return Number of elements parsed.
EGWuint egwParseStringdcv(const EGWchar* string_in, EGWdouble* array_out, EGWintptr strideB_out, EGWuint count);

/// Parse String Routine.
/// Parses a string and extracts an array of values with provided parameters.
/// @note Deliminators are treated as any spaces, new lines, commas, or other control characters.
/// @param [in] string_in Null-terminated string input operand.
/// @param [out] array_out Array of triple precision floater value output operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
/// @return Number of elements parsed.
EGWuint egwParseStringtcv(const EGWchar* string_in, EGWtriple* array_out, EGWintptr strideB_out, EGWuint count);

/// String Trim Routine.
/// Replaces last whitespace character with a null terminator and returns first non-whitespace character.
/// @note Whitespace is treated as any spaces, new lines, or other control characters (i.e. <= ' ').
/// @param [in] string_in Null-terminated string input operand.
/// @return First non-whitespace character.
EGWchar* egwTrimc(EGWchar* string_in);

/// String Quick Trim Routine.
/// Replaces last whitespace character with a null terminator and returns first non-whitespace character.
/// @note Whitespace is treated as any spaces, new lines, or other control characters (i.e. <= ' ').
/// @param [in] string_in Null-terminated string input operand.
/// @param [in] lengthC_in String length (characters). May be -1 (for length walk).
/// @return First non-whitespace character.
EGWchar* egwQTrimc(EGWchar* string_in, EGWint lengthC_in);


// !!!: ***** Hashing (DJB) Routines *****

/// Hashing Routine (32-bit).
/// Computes the DJB hash from provided raw set of @a data bytes of size @a lengthB.
/// @param [in] data_in Raw byte data input operand.
/// @param [in] lengthB_in Size of raw data (bytes).
/// @return DJB hash value.
EGWuint32 egwHash32b(const EGWbyte* data_in, EGWuint lengthB_in);

/// String Hashing Routine (32-bit).
/// Computes the DJB hash from provided null-terminated @a string.
/// @param [in] string_in Null-terminated string input operand.
/// @return DJB hash value.
EGWuint32 egwHash32c(const EGWchar* string_in);

/// Hash Addition Routine (32-bit).
/// Computes the addition/combination of two DJB hashes from provided hashes.
/// @note This routine simply runs another iteration of the hashing algorithm incorporating @a hash_rhs into @a hash_lhs.
/// @param [in] hash_lhs Hash value lhs operand.
/// @param [in] hash_rhs Hash value rhs operand.
/// @return DJB hash value.
EGWuint32 egwHashAdd32(EGWuint32 hash_lhs, EGWuint32 hash_rhs);

/// Hashing Routine (64-bit).
/// Computes the DJB hash from provided raw set of @a data bytes of size @a lengthB.
/// @param [in] data_in Raw byte data input operand.
/// @param [in] lengthB_in Size of raw data (bytes).
/// @return DJB hash value.
EGWuint64 egwHash64b(const EGWbyte* data_in, EGWuint lengthB_in);

/// String Hashing Routine (64-bit).
/// Computes the DJB hash from provided null-terminated @a string.
/// @param [in] string_in Null-terminated string input operand.
/// @return DJB hash value.
EGWuint64 egwHash64c(const EGWchar* string_in);

/// Hash Addition Routine (64-bit).
/// Computes the addition/combination of two DJB hashes from provided hashes.
/// @note This routine simply runs another iteration of the hashing algorithm incorporating @a hash_rhs into @a hash_lhs.
/// @param [in] hash_lhs Hash value lhs operand.
/// @param [in] hash_rhs Hash value rhs operand.
/// @return DJB hash value.
EGWuint64 egwHashAdd64(EGWuint64 hash_lhs, EGWuint64 hash_rhs);


// !!!: ***** Endianness Swap Routines *****

/// Endian Swap Routine.
/// Swaps the endianness ordering of the provided data bytes.
/// @param [in] val_in Value bytes input operand.
/// @param [out] val_out Value bytes output operand.
/// @param [in] sizeB Size of value operand.
void egwEndianSwapb(const EGWbyte* val_in, EGWbyte* val_out, EGWuint sizeB);

/// Endian Swap Routine.
/// Swaps the endianness ordering of the provided data bytes.
/// @param [in] vals_in Array of value bytes input operands.
/// @param [out] vals_out Array of value bytes output operands.
/// @param [in] sizeB Size of value operand.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwEndianSwapbv(const EGWbyte* vals_in, EGWbyte* vals_out, EGWuint sizeB, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count);

/// @}

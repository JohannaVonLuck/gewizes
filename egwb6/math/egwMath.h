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

/// @defgroup geWizES_math_math egwMath
/// @ingroup geWizES_math
/// Base Mathematics.
/// @{

/// @file egwMath.h
/// Base Mathematics Interface.

#import <math.h>
#import "egwMathTypes.h"


// !!!: ***** Shared Instances *****

extern const EGWsingle egwSIZerof;                ///< Shared zero instance.
extern const EGWsingle egwSIOnef;                 ///< Shared one instance.
extern const EGWsingle egwSITwof;                 ///< Shared two instance.
extern const EGWsingle egwSINegOnef;              ///< Shared negative one instance.
extern const EGWsingle egwSINegTwof;              ///< Shared negative two instance.


// !!!: ***** Trivial Macros *****

#define egwIsZero(val,eps)  ((val) - (eps) <= (eps) && (val) + (eps) >= -(eps)) ///< Is zero macro.
#define egwIsOne(val,eps)   ((val) - (eps) <= 1 + (eps) && (val) + (eps) >= 1 - (eps)) ///< Is one macro.
#define egwIsNegOne(val,eps) ((val) - (eps) <= -1 + (eps) && (val) + (eps) >= -1 - (eps)) ///< Is negative one macro.
#define egwIsEqual(lhs,rhs,eps) ((lhs) - (eps) <= (rhs) + (eps) && (lhs) + (eps) >= (rhs) - (eps)) ///< Is equal macro.
#define egwIsNotEqual(lhs,rhs,eps) ((lhs) - (eps) > (rhs) + (eps) || (lhs) + (eps) < (rhs) - (eps)) ///< Is not equal macro.
#define egwAbs(val)         ((val) >= 0 ? (val) : -(val)) ///< Absolute value macro.
#define egwSign(val, eps)   ((val) - (eps) > (eps) ? 1 : ((val) + (eps) < -(eps) ? -1 : 0)) ///< Sign-of macro.
#define egwMax2(lhs,rhs)    ((lhs) > (rhs) ? (lhs) : (rhs)) ///< Maximum value macro.
#define egwMin2(lhs,rhs)    ((lhs) < (rhs) ? (lhs) : (rhs)) ///< Minimum value macro.
#define egwDbld(val)        ((val) + (val))             ///< Doubled value macro.
#define egwTrpl(val)        ((val) + (val) + (val))     ///< Tripled value macro.
#define egwSqrd(val)        ((val) * (val))             ///< Squared value macro.
#define egwSignSqrd(val)    ((val) >= 0 ? ((val) * (val)) : (-((val) * (val)))) ///< Signed correct squared value macro.
#define egwCubd(val)        ((val) * (val) * (val))     ///< Cubed value macro.
#define egwDegToRad(val)    ((val) * EGW_MATH_PI_180)   ///< Degrees to radians macro.
#define egwRadToDeg(val)    ((val) * EGW_MATH_180_PI)   ///< Radians to degrees macro.
#define egwClamp(val,low,hgh) ((val) < (low) ? (low) : ((val) > (hgh) ? (hgh) : (val))) ///< Value clamping macro.
#define egwClamp01(val)     ((val) < 0 ? 0 : ((val) > 1 ? 1 : val)) ///< 0-1 value clamping macro.
#define egwClampPos(val)    ((val) > 0 ? (val) : 0)     ///< Positive value clamping macro.
#define egwClampNeg(val)    ((val) < 0 ? (val) : 0)     ///< Negative value clamping macro.


// !!!: ***** Value Testing Routines *****

/// Is Zero Routine.
/// Determines if @a val is zero, taking into account FP epsilon.
/// @param [in] val Value operand.
/// @return 1 if @a val is zero, otherwise 0.
EGWint egwIsZerof(const EGWsingle val);

/// Is Zero Routine.
/// Determines if @a val is zero, taking into account FP epsilon.
/// @param [in] val Value operand.
/// @return 1 if @a val is zero, otherwise 0.
EGWint egwIsZerod(const EGWdouble val);

/// Is Zero Routine.
/// Determines if @a val is zero, taking into account FP epsilon.
/// @param [in] val Value operand.
/// @return 1 if @a val is zero, otherwise 0.
EGWint egwIsZerot(const EGWtriple val);

/// Is Zero Routine.
/// Determines if @a val is zero, taking into account FP epsilon.
/// @param [in] val Value operand.
/// @return 1 if @a val is zero, otherwise 0.
EGWint egwIsZerom(const EGWtime val);

/// Is One Routine.
/// Determines if @a val is one, taking into account FP epsilon.
/// @param [in] val Value operand.
/// @return 1 if @a val is one, otherwise 0.
EGWint egwIsOnef(const EGWsingle val);

/// Is One Routine.
/// Determines if @a val is one, taking into account FP epsilon.
/// @param [in] val Value operand.
/// @return 1 if @a val is one, otherwise 0.
EGWint egwIsOned(const EGWdouble val);

/// Is One Routine.
/// Determines if @a val is one, taking into account FP epsilon.
/// @param [in] val Value operand.
/// @return 1 if @a val is one, otherwise 0.
EGWint egwIsOnet(const EGWtriple val);

/// Is One Routine.
/// Determines if @a val is one, taking into account FP epsilon.
/// @param [in] val Value operand.
/// @return 1 if @a val is one, otherwise 0.
EGWint egwIsOnem(const EGWtime val);

/// Is Negative One Routine.
/// Determines if @a val is negative one, taking into account FP epsilon.
/// @param [in] val Value operand.
/// @return 1 if @a val is negative one, otherwise 0.
EGWint egwIsNegOnef(const EGWsingle val);

/// Is Negative One Routine.
/// Determines if @a val is negative one, taking into account FP epsilon.
/// @param [in] val Value operand.
/// @return 1 if @a val is negative one, otherwise 0.
EGWint egwIsNegOned(const EGWdouble val);

/// Is Negative One Routine.
/// Determines if @a val is negative one, taking into account FP epsilon.
/// @param [in] val Value operand.
/// @return 1 if @a val is negative one, otherwise 0.
EGWint egwIsNegOnet(const EGWtriple val);

/// Is Negative One Routine.
/// Determines if @a val is negative one, taking into account FP epsilon.
/// @param [in] val Value operand.
/// @return 1 if @a val is negative one, otherwise 0.
EGWint egwIsNegOnem(const EGWtime val);

/// Is Equal Routine.
/// Determines if @a val_lhs and @a val_rhs are equal, taking into account FP epsilon.
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return 1 if @a val_lhs equals val_rhs, otherwise 0.
EGWint egwIsEqualf(const EGWsingle val_lhs, const EGWsingle val_rhs);

/// Is Equal Routine.
/// Determines if @a val_lhs and @a val_rhs are equal, taking into account FP epsilon.
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return 1 if @a val_lhs equals val_rhs, otherwise 0.
EGWint egwIsEquald(const EGWdouble val_lhs, const EGWdouble val_rhs);

/// Is Equal Routine.
/// Determines if @a val_lhs and @a val_rhs are equal, taking into account FP epsilon.
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return 1 if @a val_lhs equals val_rhs, otherwise 0.
EGWint egwIsEqualt(const EGWtriple val_lhs, const EGWtriple val_rhs);

/// Is Equal Routine.
/// Determines if @a val_lhs and @a val_rhs are equal, taking into account FP epsilon.
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return 1 if @a val_lhs equals val_rhs, otherwise 0.
EGWint egwIsEqualm(const EGWtime val_lhs, const EGWtime val_rhs);

/// Is Not Equal Routine.
/// Determines if @a val_lhs and @a val_rhs are not equal, taking into account FP epsilon.
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return 1 if @a val_lhs does not equal val_rhs, otherwise 0.
EGWint egwIsNotEqualf(const EGWsingle val_lhs, const EGWsingle val_rhs);

/// Is Not Equal Routine.
/// Determines if @a val_lhs and @a val_rhs are not equal, taking into account FP epsilon.
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return 1 if @a val_lhs does not equal val_rhs, otherwise 0.
EGWint egwIsNotEquald(const EGWdouble val_lhs, const EGWdouble val_rhs);

/// Is Not Equal Routine.
/// Determines if @a val_lhs and @a val_rhs are not equal, taking into account FP epsilon.
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return 1 if @a val_lhs does not equal val_rhs, otherwise 0.
EGWint egwIsNotEqualt(const EGWtriple val_lhs, const EGWtriple val_rhs);

/// Is Not Equal Routine.
/// Determines if @a val_lhs and @a val_rhs are not equal, taking into account FP epsilon.
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return 1 if @a val_lhs does not equal val_rhs, otherwise 0.
EGWint egwIsNotEqualm(const EGWtime val_lhs, const EGWtime val_rhs);


// !!!: ***** Common Routines *****

/// Absolute Value Routine.
/// Computes the absolute value (positive form) of @a val.
/// @param [in] val Value operand.
/// @return Absolute value of @a val.
EGWint egwAbsi(const EGWint val);

/// Absolute Value Routine.
/// Computes the absolute value (positive form) of @a val.
/// @param [in] val Value operand.
/// @return Absolute value of @a val.
EGWint8 egwAbsi8(const EGWint8 val);

/// Absolute Value Routine.
/// Computes the absolute value (positive form) of @a val.
/// @param [in] val Value operand.
/// @return Absolute value of @a val.
EGWint16 egwAbsi16(const EGWint16 val);

/// Absolute Value Routine.
/// Computes the absolute value (positive form) of @a val.
/// @param [in] val Value operand.
/// @return Absolute value of @a val.
EGWint32 egwAbsi32(const EGWint32 val);

/// Absolute Value Routine.
/// Computes the absolute value (positive form) of @a val.
/// @param [in] val Value operand.
/// @return Absolute value of @a val.
EGWint64 egwAbsi64(const EGWint64 val);

/// Absolute Value Routine.
/// Computes the absolute value (positive form) of @a val.
/// @param [in] val Value operand.
/// @return Absolute value of @a val.
static inline EGWsingle egwAbsf(const EGWsingle val)
    { return fabsf(val); }

/// Absolute Value Routine.
/// Computes the absolute value (positive form) of @a val.
/// @param [in] val Value operand.
/// @return Absolute value of @a val.
static inline EGWdouble egwAbsd(const EGWdouble val)
    { return fabs(val); }

/// Absolute Value Routine.
/// Computes the absolute value (positive form) of @a val.
/// @param [in] val Value operand.
/// @return Absolute value of @a val.
static inline EGWtriple egwAbst(const EGWtriple val)
    { return fabsl(val); }

/// Absolute Value Routine.
/// Computes the absolute value (positive form) of @a val.
/// @param [in] val Value operand.
/// @return Absolute value of @a val.
static inline EGWtime egwAbsm(const EGWtime val)
    { return fabs(val); }

/// Sign Of Value Routine.
/// Tests sign of @a val, returning 1 if positive, 0 if zero, otherwise -1 if negative.
/// @param [in] val Value operand.
/// @return Sign of @a val, either 1, 0, otherwise -1 based on sign of value.
EGW_ATRB_FASTCALL EGWint egwSigni(const EGWint val);

/// Sign Of Value Routine.
/// Tests sign of @a val, returning 1 if positive, 0 if zero, otherwise -1 if negative.
/// @param [in] val Value operand.
/// @return Sign of @a val, either 1, 0, otherwise -1 based on sign of value.
EGW_ATRB_FASTCALL EGWint egwSigni8(const EGWint8 val);

/// Sign Of Value Routine.
/// Tests sign of @a val, returning 1 if positive, 0 if zero, otherwise -1 if negative.
/// @param [in] val Value operand.
/// @return Sign of @a val, either 1, 0, otherwise -1 based on sign of value.
EGW_ATRB_FASTCALL EGWint egwSigni16(const EGWint16 val);

/// Sign Of Value Routine.
/// Tests sign of @a val, returning 1 if positive, 0 if zero, otherwise -1 if negative.
/// @param [in] val Value operand.
/// @return Sign of @a val, either 1, 0, otherwise -1 based on sign of value.
EGW_ATRB_FASTCALL EGWint egwSigni32(const EGWint32 val);

/// Sign Of Value Routine.
/// Tests sign of @a val, returning 1 if positive, 0 if zero, otherwise -1 if negative.
/// @param [in] val Value operand.
/// @return Sign of @a val, either 1, 0, otherwise -1 based on sign of value.
EGW_ATRB_FASTCALL EGWint egwSigni64(const EGWint64 val);

/// Sign Of Value Routine.
/// Tests sign of @a val, returning 1 if positive, 0 if zero, otherwise -1 if negative.
/// @param [in] val Value operand.
/// @return Sign of @a val, either 1, 0, otherwise -1 based on sign of value.
EGWint egwSignf(const EGWsingle val);

/// Sign Of Value Routine.
/// Tests sign of @a val, returning 1 if positive, 0 if zero, otherwise -1 if negative.
/// @param [in] val Value operand.
/// @return Sign of @a val, either 1, 0, otherwise -1 based on sign of value.
EGWint egwSignd(const EGWdouble val);

/// Sign Of Value Routine.
/// Tests sign of @a val, returning 1 if positive, 0 if zero, otherwise -1 if negative.
/// @param [in] val Value operand.
/// @return Sign of @a val, either 1, 0, otherwise -1 based on sign of value.
EGWint egwSignt(const EGWtriple val);

/// Sign Of Value Routine.
/// Tests sign of @a val, returning 1 if positive, 0 if zero, otherwise -1 if negative.
/// @param [in] val Value operand.
/// @return Sign of @a val, either 1, 0, otherwise -1 based on sign of value.
EGWint egwSignm(const EGWtime val);

/// Floor Routine.
/// Computes the nearest integer that is less than or equal to @a val.
/// @param [in] val Value operand.
/// @return Floor'ed value of @a val.
static inline EGWsingle egwFloorf(const EGWsingle val)
    { return floorf(val); }

/// Floor Routine.
/// Computes the nearest integer that is less than or equal to @a val.
/// @param [in] val Value operand.
/// @return Floor'ed value of @a val.
static inline EGWdouble egwFloord(const EGWdouble val)
    { return floor(val); }

/// Floor Routine.
/// Computes the nearest integer that is less than or equal to @a val.
/// @param [in] val Value operand.
/// @return Floor'ed value of @a val.
static inline EGWtriple egwFloort(const EGWtriple val)
    { return floorl(val); }

/// Floor Routine.
/// Computes the nearest integer that is less than or equal to @a val.
/// @param [in] val Value operand.
/// @return Floor'ed value of @a val.
static inline EGWtime egwFloorm(const EGWtime val)
    { return floor(val); }

/// Ceiling Routine.
/// Computes the nearest integer that is greater than or equal to @a val.
/// @param [in] val Value operand.
/// @return Ceiling'ed value of @a val.
static inline EGWsingle egwCeilf(const EGWsingle val)
    { return ceilf(val); }

/// Ceiling Routine.
/// Computes the nearest integer that is greater than or equal to @a val.
/// @param [in] val Value operand.
/// @return Ceiling'ed value of @a val.
static inline EGWdouble egwCeild(const EGWdouble val)
    { return ceil(val); }

/// Ceiling Routine.
/// Computes the nearest integer that is greater than or equal to @a val.
/// @param [in] val Value operand.
/// @return Ceiling'ed value of @a val.
static inline EGWtriple egwCeilt(const EGWtriple val)
    { return ceill(val); }

/// Ceiling Routine.
/// Computes the nearest integer that is greater than or equal to @a val.
/// @param [in] val Value operand.
/// @return Ceiling'ed value of @a val.
static inline EGWtime egwCeilm(const EGWtime val)
    { return ceil(val); }

/// Fractional Portion Routine.
/// Computes the fractional portion of @a val (e.g. x - floor(x)).
/// @param [in] val Value operand.
/// @return Fractional portion of @a val.
EGWsingle egwFractf(const EGWsingle val);

/// Fractional Portion Routine.
/// Computes the fractional portion of @a val (e.g. x - floor(x)).
/// @param [in] val Value operand.
/// @return Fractional portion of @a val.
EGWdouble egwFractd(const EGWdouble val);

/// Fractional Portion Routine.
/// Computes the fractional portion of @a val (e.g. x - floor(x)).
/// @param [in] val Value operand.
/// @return Fractional portion of @a val.
EGWtriple egwFractt(const EGWtriple val);

/// Fractional Portion Routine.
/// Computes the fractional portion of @a val (e.g. x - floor(x)).
/// @param [in] val Value operand.
/// @return Fractional portion of @a val.
EGWtime egwFractm(const EGWtime val);

/// Minimum Value Routine.
/// Computes the minimum between two operands (e.g. y < x ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Minimum between @a val_lhs and @a val_rhs.
EGW_ATRB_FASTCALL EGWint egwMin2i(const EGWint val_lhs, const EGWint val_rhs);

/// Minimum Value Routine.
/// Computes the minimum between two operands (e.g. y < x ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Minimum between @a val_lhs and @a val_rhs.
EGW_ATRB_FASTCALL EGWint8 egwMin2i8(const EGWint8 val_lhs, const EGWint8 val_rhs);

/// Minimum Value Routine.
/// Computes the minimum between two operands (e.g. y < x ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Minimum between @a val_lhs and @a val_rhs.
EGW_ATRB_FASTCALL EGWint16 egwMin2i16(const EGWint16 val_lhs, const EGWint16 val_rhs);

/// Minimum Value Routine.
/// Computes the minimum between two operands (e.g. y < x ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Minimum between @a val_lhs and @a val_rhs.
EGW_ATRB_FASTCALL EGWint32 egwMin2i32(const EGWint32 val_lhs, const EGWint32 val_rhs);

/// Minimum Value Routine.
/// Computes the minimum between two operands (e.g. y < x ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Minimum between @a val_lhs and @a val_rhs.
EGW_ATRB_FASTCALL EGWint64 egwMin2i64(const EGWint64 val_lhs, const EGWint64 val_rhs);

/// Minimum Value Routine.
/// Computes the minimum between two operands (e.g. y < x ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Minimum between @a val_lhs and @a val_rhs.
EGW_ATRB_FASTCALL EGWuint egwMin2ui(const EGWuint val_lhs, const EGWuint val_rhs);

/// Minimum Value Routine.
/// Computes the minimum between two operands (e.g. y < x ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Minimum between @a val_lhs and @a val_rhs.
EGW_ATRB_FASTCALL EGWuint8 egwMin2ui8(const EGWuint8 val_lhs, const EGWuint8 val_rhs);

/// Minimum Value Routine.
/// Computes the minimum between two operands (e.g. y < x ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Minimum between @a val_lhs and @a val_rhs.
EGW_ATRB_FASTCALL EGWuint16 egwMin2ui16(const EGWuint16 val_lhs, const EGWuint16 val_rhs);

/// Minimum Value Routine.
/// Computes the minimum between two operands (e.g. y < x ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Minimum between @a val_lhs and @a val_rhs.
EGW_ATRB_FASTCALL EGWuint32 egwMin2ui32(const EGWuint32 val_lhs, const EGWuint32 val_rhs);

/// Minimum Value Routine.
/// Computes the minimum between two operands (e.g. y < x ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Minimum between @a val_lhs and @a val_rhs.
EGW_ATRB_FASTCALL EGWuint64 egwMin2ui64(const EGWuint64 val_lhs, const EGWuint64 val_rhs);

/// Minimum Value Routine.
/// Computes the minimum between two operands (e.g. y < x ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Minimum between @a val_lhs and @a val_rhs.
EGWsingle egwMin2f(const EGWsingle val_lhs, const EGWsingle val_rhs);

/// Minimum Value Routine.
/// Computes the minimum between two operands (e.g. y < x ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Minimum between @a val_lhs and @a val_rhs.
EGWdouble egwMin2d(const EGWdouble val_lhs, const EGWdouble val_rhs);

/// Minimum Value Routine.
/// Computes the minimum between two operands (e.g. y < x ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Minimum between @a val_lhs and @a val_rhs.
EGWtriple egwMin2t(const EGWtriple val_lhs, const EGWtriple val_rhs);

/// Minimum Value Routine.
/// Computes the minimum between two operands (e.g. y < x ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Minimum between @a val_lhs and @a val_rhs.
EGWtime egwMin2m(const EGWtime val_lhs, const EGWtime val_rhs);

/// Maximum Value Routine.
/// Computes the maximum between two operands (e.g. x < y ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Maximum between @a val_lhs and @a val_rhs.
EGW_ATRB_FASTCALL EGWint egwMax2i(const EGWint val_lhs, const EGWint val_rhs);

/// Maximum Value Routine.
/// Computes the maximum between two operands (e.g. x < y ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Maximum between @a val_lhs and @a val_rhs.
EGW_ATRB_FASTCALL EGWint8 egwMax2i8(const EGWint8 val_lhs, const EGWint8 val_rhs);

/// Maximum Value Routine.
/// Computes the maximum between two operands (e.g. x < y ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Maximum between @a val_lhs and @a val_rhs.
EGW_ATRB_FASTCALL EGWint16 egwMax2i16(const EGWint16 val_lhs, const EGWint16 val_rhs);

/// Maximum Value Routine.
/// Computes the maximum between two operands (e.g. x < y ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Maximum between @a val_lhs and @a val_rhs.
EGW_ATRB_FASTCALL EGWint32 egwMax2i32(const EGWint32 val_lhs, const EGWint32 val_rhs);

/// Maximum Value Routine.
/// Computes the maximum between two operands (e.g. x < y ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Maximum between @a val_lhs and @a val_rhs.
EGW_ATRB_FASTCALL EGWint64 egwMax2i64(const EGWint64 val_lhs, const EGWint64 val_rhs);

/// Maximum Value Routine.
/// Computes the maximum between two operands (e.g. x < y ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Maximum between @a val_lhs and @a val_rhs.
EGW_ATRB_FASTCALL EGWuint egwMax2ui(const EGWuint val_lhs, const EGWuint val_rhs);

/// Maximum Value Routine.
/// Computes the maximum between two operands (e.g. x < y ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Maximum between @a val_lhs and @a val_rhs.
EGW_ATRB_FASTCALL EGWuint8 egwMax2ui8(const EGWuint8 val_lhs, const EGWuint8 val_rhs);

/// Maximum Value Routine.
/// Computes the maximum between two operands (e.g. x < y ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Maximum between @a val_lhs and @a val_rhs.
EGW_ATRB_FASTCALL EGWuint16 egwMax2ui16(const EGWuint16 val_lhs, const EGWuint16 val_rhs);

/// Maximum Value Routine.
/// Computes the maximum between two operands (e.g. x < y ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Maximum between @a val_lhs and @a val_rhs.
EGW_ATRB_FASTCALL EGWuint32 egwMax2ui32(const EGWuint32 val_lhs, const EGWuint32 val_rhs);

/// Maximum Value Routine.
/// Computes the maximum between two operands (e.g. x < y ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Maximum between @a val_lhs and @a val_rhs.
EGW_ATRB_FASTCALL EGWuint64 egwMax2ui64(const EGWuint64 val_lhs, const EGWuint64 val_rhs);

/// Maximum Value Routine.
/// Computes the maximum between two operands (e.g. x < y ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Maximum between @a val_lhs and @a val_rhs.
EGWsingle egwMax2f(const EGWsingle val_lhs, const EGWsingle val_rhs);

/// Maximum Value Routine.
/// Computes the maximum between two operands (e.g. x < y ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Maximum between @a val_lhs and @a val_rhs.
EGWdouble egwMax2d(const EGWdouble val_lhs, const EGWdouble val_rhs);

/// Maximum Value Routine.
/// Computes the maximum between two operands (e.g. x < y ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Maximum between @a val_lhs and @a val_rhs.
EGWtriple egwMax2t(const EGWtriple val_lhs, const EGWtriple val_rhs);

/// Maximum Value Routine.
/// Computes the maximum between two operands (e.g. x < y ? y : x).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Maximum between @a val_lhs and @a val_rhs.
EGWtime egwMax2m(const EGWtime val_lhs, const EGWtime val_rhs);

/// FP Modulus Routine.
/// Computes the floating point modulus of @a val by @a mod producing values in range (-m,m).
/// @param [in] val Value operand.
/// @param [in] mod Modulo value.
/// @return Modulus of @a val by @a mod in range (-m,m).
static inline EGWsingle egwModf(const EGWsingle val, const EGWsingle mod)
    { return fmodf(val, mod); }

/// FP Modulus Routine.
/// Computes the floating point modulus of @a val by @a mod producing values in range (-m,m).
/// @param [in] val Value operand.
/// @param [in] mod Modulo value.
/// @return Modulus of @a val by @a mod in range (-m,m).
static inline EGWdouble egwModd(const EGWdouble val, const EGWdouble mod)
    { return fmod(val, mod); }

/// FP Modulus Routine.
/// Computes the floating point modulus of @a val by @a mod producing values in range (-m,m).
/// @param [in] val Value operand.
/// @param [in] mod Modulo value.
/// @return Modulus of @a val by @a mod in range (-m,m).
static inline EGWtriple egwModt(const EGWtriple val, const EGWtriple mod)
    { return fmodl(val, mod); }

/// FP Modulus Routine.
/// Computes the floating point modulus of @a val by @a mod producing values in range (-m,m).
/// @param [in] val Value operand.
/// @param [in] mod Modulo value.
/// @return Modulus of @a val by @a mod in range (-m,m).
static inline EGWtime egwModm(const EGWtime val, const EGWtime mod)
    { return fmod(val, mod); }

/// Even Value Test Routine.
/// Tests if @a val is even.
/// @param [in] val Value operand.
/// @return 1 if @a val is even, otherwise 0.
static inline EGWint egwIsEveni(const EGWint val)
    { return val & (EGWint)1 ? 0 : 1; }

/// Even Value Test Routine.
/// Tests if @a val is even.
/// @param [in] val Value operand.
/// @return 1 if @a val is even, otherwise 0.
static inline EGWint egwIsEvenui(const EGWuint val)
    { return val & (EGWuint)1 ? 0 : 1; }

/// Odd Value Test Routine.
/// Tests if @a val is odd.
/// @param [in] val Value operand.
/// @return 1 if @a val is odd, otherwise 0.
static inline EGWint egwIsOddi(const EGWint val)
    { return val & (EGWint)1 ? 1 : 0; }

/// Odd Value Test Routine.
/// Tests if @a val is odd.
/// @param [in] val Value operand.
/// @return 1 if @a val is odd, otherwise 0.
static inline EGWint egwIsOddui(const EGWuint val)
    { return val & (EGWuint)1 ? 1 : 0; }

/// Power of 2 Test Routine.
/// Tests if @a val is a power of 2.
/// @param [in] val Value operand.
/// @return 1 if @a val is a power of 2, otherwise 0.
EGW_ATRB_FASTCALL EGWint egwIsPow2i(const EGWint val);

/// Power of 2 Test Routine.
/// Tests if @a val is a power of 2.
/// @param [in] val Value operand.
/// @return 1 if @a val is a power of 2, otherwise 0.
EGW_ATRB_FASTCALL EGWint egwIsPow2i8(const EGWint8 val);

/// Power of 2 Test Routine.
/// Tests if @a val is a power of 2.
/// @param [in] val Value operand.
/// @return 1 if @a val is a power of 2, otherwise 0.
EGW_ATRB_FASTCALL EGWint egwIsPow2i16(const EGWint16 val);

/// Power of 2 Test Routine.
/// Tests if @a val is a power of 2.
/// @param [in] val Value operand.
/// @return 1 if @a val is a power of 2, otherwise 0.
EGW_ATRB_FASTCALL EGWint egwIsPow2i32(const EGWint32 val);

/// Power of 2 Test Routine.
/// Tests if @a val is a power of 2.
/// @param [in] val Value operand.
/// @return 1 if @a val is a power of 2, otherwise 0.
EGW_ATRB_FASTCALL EGWint egwIsPow2i64(const EGWint64 val);

/// Power of 2 Test Routine.
/// Tests if @a val is a power of 2.
/// @param [in] val Value operand.
/// @return 1 if @a val is a power of 2, otherwise 0.
EGW_ATRB_FASTCALL EGWint egwIsPow2ui(const EGWuint val);

/// Power of 2 Test Routine.
/// Tests if @a val is a power of 2.
/// @param [in] val Value operand.
/// @return 1 if @a val is a power of 2, otherwise 0.
EGW_ATRB_FASTCALL EGWint egwIsPow2ui8(const EGWuint8 val);

/// Power of 2 Test Routine.
/// Tests if @a val is a power of 2.
/// @param [in] val Value operand.
/// @return 1 if @a val is a power of 2, otherwise 0.
EGW_ATRB_FASTCALL EGWint egwIsPow2ui16(const EGWuint16 val);

/// Power of 2 Test Routine.
/// Tests if @a val is a power of 2.
/// @param [in] val Value operand.
/// @return 1 if @a val is a power of 2, otherwise 0.
EGW_ATRB_FASTCALL EGWint egwIsPow2ui32(const EGWuint32 val);

/// Power of 2 Test Routine.
/// Tests if @a val is a power of 2.
/// @param [in] val Value operand.
/// @return 1 if @a val is a power of 2, otherwise 0.
EGW_ATRB_FASTCALL EGWint egwIsPow2ui64(const EGWuint64 val);

/// Least Common Multiple Routine.
/// Computes the least common multiple of @a val_lhs and @a val_rhs.
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Least common multiple of @a val_lhs and @a val_rhs.
EGW_ATRB_FASTCALL EGWint egwLCMi(const EGWint val_lhs, const EGWint val_rhs);

/// Least Common Multiple Routine.
/// Computes the least common multiple of @a val_lhs and @a val_rhs.
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Least common multiple of @a val_lhs and @a val_rhs.
EGW_ATRB_FASTCALL EGWuint egwLCMui(const EGWuint val_lhs, const EGWuint val_rhs);

/// Greatest Common Divisor Routine.
/// Computes the greatest common divisor of @a val_lhs and @a val_rhs.
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Greatest common divisor of @a val_lhs and @a val_rhs.
EGW_ATRB_FASTCALL EGWint egwGCDi(const EGWint val_lhs, const EGWint val_rhs);

/// Greatest Common Divisor Routine.
/// Computes the greatest common divisor of @a val_lhs and @a val_rhs.
/// @param [in] val_lhs Value lhs operand.
/// @param [in] val_rhs Value rhs operand.
/// @return Greatest common divisor of @a val_lhs and @a val_rhs.
EGW_ATRB_FASTCALL EGWuint egwGCDui(const EGWuint val_lhs, const EGWuint val_rhs);


// !!!: ***** Trigonometric Routines *****

/// Sine Routine.
/// Computes the sine of the given angle @a angle_r.
/// @param [in] angle_r Angle value (radians).
/// @return Sine of @a angle_r.
static inline EGWsingle egwSinf(const EGWsingle angle_r)
    { return sinf(angle_r); }

/// Sine Routine.
/// Computes the sine of the given angle @a angle_r.
/// @param [in] angle_r Angle value (radians).
/// @return Sine of @a angle_r.
static inline EGWdouble egwSind(const EGWdouble angle_r)
    { return sin(angle_r); }

/// Sine Routine.
/// Computes the sine of the given angle @a angle_r.
/// @param [in] angle_r Angle value (radians).
/// @return Sine of @a angle_r.
static inline EGWtriple egwSint(const EGWtriple angle_r)
    { return sinl(angle_r); }

/// Cosine Routine.
/// Computes the cosine of the given angle @a angle_r.
/// @param [in] angle_r Angle value (radians).
/// @return Cosine of @a angle_r.
static inline EGWsingle egwCosf(const EGWsingle angle_r)
    { return cosf(angle_r); }

/// Cosine Routine.
/// Computes the cosine of the given angle @a angle_r.
/// @param [in] angle_r Angle value (radians).
/// @return Cosine of @a angle_r.
static inline EGWdouble egwCosd(const EGWdouble angle_r)
    { return cos(angle_r); }

/// Cosine Routine.
/// Computes the cosine of the given angle @a angle_r.
/// @param [in] angle_r Angle value (radians).
/// @return Cosine of @a angle_r.
static inline EGWtriple egwCost(const EGWtriple angle_r)
    { return cosl(angle_r); }

/// Tangent Routine.
/// Computes the tangent of the given angle @a angle_r.
/// @param [in] angle_r Angle value (radians).
/// @return Cosine of @a angle_r.
static inline EGWsingle egwTanf(const EGWsingle angle_r)
    { return tanf(angle_r); }

/// Tangent Routine.
/// Computes the tangent of the given angle @a angle_r.
/// @param [in] angle_r Angle value (radians).
/// @return Cosine of @a angle_r.
static inline EGWdouble egwTand(const EGWdouble angle_r)
    { return tan(angle_r); }

/// Tangent Routine.
/// Computes the tangent of the given angle @a angle_r.
/// @param [in] angle_r Angle value (radians).
/// @return Cosine of @a angle_r.
static inline EGWtriple egwTant(const EGWtriple angle_r)
    { return tanl(angle_r); }

/// Hyperbolic-Sine Routine.
/// Computes the hyperbolic-sine of the given angle @a angle_r.
/// @param [in] angle_r Angle value (radians).
/// @return Hyperbolic-sine of @a angle_r.
static inline EGWsingle egwHypSinf(const EGWsingle angle_r)
    { return sinhf(angle_r); }

/// Hyperbolic-Sine Routine.
/// Computes the hyperbolic-sine of the given angle @a angle_r.
/// @param [in] angle_r Angle value (radians).
/// @return Hyperbolic-sine of @a angle_r.
static inline EGWdouble egwHypSind(const EGWdouble angle_r)
    { return sinh(angle_r); }

/// Hyperbolic-Sine Routine.
/// Computes the hyperbolic-sine of the given angle @a angle_r.
/// @param [in] angle_r Angle value (radians).
/// @return Hyperbolic-sine of @a angle_r.
static inline EGWtriple egwHypSint(const EGWtriple angle_r)
    { return sinhl(angle_r); }

/// Hyperbolic-Cosine Routine.
/// Computes the hyperbolic-cosine of the given angle @a angle_r.
/// @param [in] angle_r Angle value (radians).
/// @return Hyperbolic-cosine of @a angle_r.
static inline EGWsingle egwHypCosf(const EGWsingle angle_r)
    { return coshf(angle_r); }

/// Hyperbolic-Cosine Routine.
/// Computes the hyperbolic-cosine of the given angle @a angle_r.
/// @param [in] angle_r Angle value (radians).
/// @return Hyperbolic-cosine of @a angle_r.
static inline EGWdouble egwHypCosd(const EGWdouble angle_r)
    { return cosh(angle_r); }

/// Hyperbolic-Cosine Routine.
/// Computes the hyperbolic-cosine of the given angle @a angle_r.
/// @param [in] angle_r Angle value (radians).
/// @return Hyperbolic-cosine of @a angle_r.
static inline EGWtriple egwHypCost(const EGWtriple angle_r)
    { return coshl(angle_r); }

/// Hyperbolic-Tangent Routine.
/// Computes the hyperbolic-tangent of the given angle @a angle_r.
/// @param [in] angle_r Angle value (radians).
/// @return Hyperbolic-tangent of @a angle_r.
static inline EGWsingle egwHypTanf(const EGWsingle angle_r)
    { return tanhf(angle_r); }

/// Hyperbolic-Tangent Routine.
/// Computes the hyperbolic-tangent of the given angle @a angle_r.
/// @param [in] angle_r Angle value (radians).
/// @return Hyperbolic-tangent of @a angle_r.
static inline EGWdouble egwHypTand(const EGWdouble angle_r)
    { return tanh(angle_r); }

/// Hyperbolic-Tangent Routine.
/// Computes the hyperbolic-tangent of the given angle @a angle_r.
/// @param [in] angle_r Angle value (radians).
/// @return Hyperbolic-tangent of @a angle_r.
static inline EGWtriple egwHypTant(const EGWtriple angle_r)
    { return tanhl(angle_r); }

/// Arc-Sine Routine.
/// Computes the arc-sine of the given value @a val in radians.
/// @param [in] val Value operand.
/// @return Arc-sine of @a val.
static inline EGWsingle egwArcSinf(const EGWsingle val)
    { return asinf(val); }

/// Arc-Sine Routine.
/// Computes the arc-sine of the given value @a val in radians.
/// @param [in] val Value operand.
/// @return Arc-sine of @a val.
static inline EGWdouble egwArcSind(const EGWdouble val)
    { return asin(val); }

/// Arc-Sine Routine.
/// Computes the arc-sine of the given value @a val in radians.
/// @param [in] val Value operand.
/// @return Arc-sine of @a val.
static inline EGWtriple egwArcSint(const EGWtriple val)
    { return asinl(val); }

/// Arc-Cosine Routine.
/// Computes the arc-cosine of the given value @a val in radians.
/// @param [in] val Value operand.
/// @return Arc-cosine of @a val.
static inline EGWsingle egwArcCosf(const EGWsingle val)
    { return acosf(val); }

/// Arc-Cosine Routine.
/// Computes the arc-cosine of the given value @a val in radians.
/// @param [in] val Value operand.
/// @return Arc-cosine of @a val.
static inline EGWdouble egwArcCosd(const EGWdouble val)
    { return acos(val); }

/// Arc-Cosine Routine.
/// Computes the arc-cosine of the given value @a val in radians.
/// @param [in] val Value operand.
/// @return Arc-cosine of @a val.
static inline EGWtriple egwArcCost(const EGWtriple val)
    { return acosl(val); }

/// Arc-Tangent Routine.
/// Computes the arc-cosine of the given value @a val in radians [-PI/2,PI/2].
/// @param [in] val Value operand.
/// @return Arc-tangent of @a val.
static inline EGWsingle egwArcTanf(const EGWsingle val)
    { return atanf(val); }

/// Arc-Tangent Routine.
/// Computes the arc-cosine of the given value @a val in radians [-PI/2,PI/2].
/// @param [in] val Value operand.
/// @return Arc-tangent of @a val.
static inline EGWdouble egwArcTand(const EGWdouble val)
    { return atan(val); }

/// Arc-Tangent Routine.
/// Computes the arc-cosine of the given value @a val in radians [-PI/2,PI/2].
/// @param [in] val Value operand.
/// @return Arc-tangent of @a val.
static inline EGWtriple egwArcTant(const EGWtriple val)
    { return atanl(val); }

/// Arc-Tangent Y/X Routine.
/// Computes the arc-tangent of the given value (@c val_nmr / @a val_dnm) in radians [-PI,PI].
/// @param [in] val_nmr Value numerator operand.
/// @param [in] val_dnm Value denominator operand.
/// @return Arc-tangent of @a val_nmr / @a val_dnm.
/// @note Since both numerator and denominator values (and their signs) are available the correct quadrant can be computed in this routine.
static inline EGWsingle egwArcTan2f(const EGWsingle val_nmr, const EGWsingle val_dnm)
    { return atan2(val_nmr, val_dnm); }

/// Arc-Tangent Y/X Routine.
/// Computes the arc-tangent of the given value (@c val_nmr / @a val_dnm) in radians [-PI,PI].
/// @param [in] val_nmr Value numerator operand.
/// @param [in] val_dnm Value denominator operand.
/// @return Arc-tangent of @a val_nmr / @a val_dnm.
/// @note Since both numerator and denominator values (and their signs) are available the correct quadrant can be computed in this routine.
static inline EGWdouble egwArcTan2d(const EGWdouble val_nmr, const EGWdouble val_dnm)
    { return atan2(val_nmr, val_dnm); }

/// Arc-Tangent Y/X Routine.
/// Computes the arc-tangent of the given value (@c val_nmr / @a val_dnm) in radians [-PI,PI].
/// @param [in] val_nmr Value numerator operand.
/// @param [in] val_dnm Value denominator operand.
/// @return Arc-tangent of @a val_nmr / @a val_dnm.
/// @note Since both numerator and denominator values (and their signs) are available the correct quadrant can be computed in this routine.
static inline EGWtriple egwArcTan2t(const EGWtriple val_nmr, const EGWtriple val_dnm)
    { return atan2l(val_nmr, val_dnm); }


// !!!: ***** Exponential Routines *****

/// Doubled Routine.
/// Computes the value of @a val doubled (e.g. x+x).
/// @param [in] val Value operand.
/// @return Value of @a val doubled.
EGWsingle egwDbldf(const EGWsingle val);

/// Doubled Routine.
/// Computes the value of @a val doubled (e.g. x+x).
/// @param [in] val Value operand.
/// @return Value of @a val doubled.
EGWdouble egwDbldd(const EGWdouble val);

/// Doubled Routine.
/// Computes the value of @a val doubled (e.g. x+x).
/// @param [in] val Value operand.
/// @return Value of @a val doubled.
EGWtriple egwDbldt(const EGWtriple val);

/// Doubled Routine.
/// Computes the value of @a val doubled (e.g. x+x).
/// @param [in] val Value operand.
/// @return Value of @a val doubled.
EGWtime egwDbldm(const EGWtime val);

/// Tripled Routine.
/// Computes the value of @a val tripled (e.g. x+x+x).
/// @param [in] val Value operand.
/// @return Value of @a val tripled.
EGWsingle egwTrplf(const EGWsingle val);

/// Tripled Routine.
/// Computes the value of @a val tripled (e.g. x+x+x).
/// @param [in] val Value operand.
/// @return Value of @a val tripled.
EGWdouble egwTrpld(const EGWdouble val);

/// Tripled Routine.
/// Computes the value of @a val tripled (e.g. x+x+x).
/// @param [in] val Value operand.
/// @return Value of @a val tripled.
EGWtriple egwTrplt(const EGWtriple val);

/// Tripled Routine.
/// Computes the value of @a val tripled (e.g. x+x+x).
/// @param [in] val Value operand.
/// @return Value of @a val tripled.
EGWtime egwTrplm(const EGWtime val);

/// Squared Routine.
/// Computes the value of @a val squared (e.g. x^2).
/// @param [in] val Value operand.
/// @return Value of @a val squared.
EGWsingle egwSqrdf(const EGWsingle val);

/// Squared Routine.
/// Computes the value of @a val squared (e.g. x^2).
/// @param [in] val Value operand.
/// @return Value of @a val squared.
EGWdouble egwSqrdd(const EGWdouble val);

/// Squared Routine.
/// Computes the value of @a val squared (e.g. x^2).
/// @param [in] val Value operand.
/// @return Value of @a val squared.
EGWtriple egwSqrdt(const EGWtriple val);

/// Squared Routine.
/// Computes the value of @a val squared (e.g. x^2).
/// @param [in] val Value operand.
/// @return Value of @a val squared.
EGWtime egwSqrdm(const EGWtime val);

/// Sign Correct Squared Routine.
/// Computes the value of @a val squared with the correct sign (e.g. x>0 ? x^2 : -(x^2)).
/// @param [in] val Value operand.
/// @return Value of @a val squared with correct sign.
EGWsingle egwSignSqrdf(const EGWsingle val);

/// Sign Correct Squared Routine.
/// Computes the value of @a val squared with the correct sign (e.g. x>0 ? x^2 : -(x^2)).
/// @param [in] val Value operand.
/// @return Value of @a val squared with correct sign.
EGWdouble egwSignSqrdd(const EGWdouble val);

/// Sign Correct Squared Routine.
/// Computes the value of @a val squared with the correct sign (e.g. x>0 ? x^2 : -(x^2)).
/// @param [in] val Value operand.
/// @return Value of @a val squared with correct sign.
EGWtriple egwSignSqrdt(const EGWtriple val);

/// Sign Correct Squared Routine.
/// Computes the value of @a val squared with the correct sign (e.g. x>0 ? x^2 : -(x^2)).
/// @param [in] val Value operand.
/// @return Value of @a val squared with correct sign.
EGWtime egwSignSqrdm(const EGWtime val);

/// Cubed Routine.
/// Computes the value of @a val cubed (e.g. x^3).
/// @param [in] val Value operand.
/// @return Value of @a val cubed.
EGWsingle egwCubdf(const EGWsingle val);

/// Cubed Routine.
/// Computes the value of @a val cubed (e.g. x^3).
/// @param [in] val Value operand.
/// @return Value of @a val cubed.
EGWdouble egwCubdd(const EGWdouble val);

/// Cubed Routine.
/// Computes the value of @a val cubed (e.g. x^3).
/// @param [in] val Value operand.
/// @return Value of @a val cubed.
EGWtriple egwCubdt(const EGWtriple val);

/// Cubed Routine.
/// Computes the value of @a val cubed (e.g. x^3).
/// @param [in] val Value operand.
/// @return Value of @a val cubed.
EGWtime egwCubdm(const EGWtime val);

/// Power Routine.
/// Computes the value of @a base raised to the @a xpn power (e.g. x^y).
/// @param [in] base Base operand.
/// @param [in] xpn Exponent operand.
/// @return Value of @a base raised to the @a xpn power.
static inline EGWsingle egwPowf(const EGWsingle base, const EGWsingle xpn)
    { return powf(base, xpn); }

/// Power Routine.
/// Computes the value of @a base raised to the @a xpn power (e.g. x^y).
/// @param [in] base Base operand.
/// @param [in] xpn Exponent operand.
/// @return Value of @a base raised to the @a xpn power.
static inline EGWdouble egwPowd(const EGWdouble base, const EGWdouble xpn)
    { return pow(base, xpn); }

/// Power Routine.
/// Computes the value of @a base raised to the @a xpn power (e.g. x^y).
/// @param [in] base Base operand.
/// @param [in] xpn Exponent operand.
/// @return Value of @a base raised to the @a xpn power.
static inline EGWtriple egwPowt(const EGWtriple base, const EGWtriple xpn)
    { return powl(base, xpn); }

/// Power of Natural Base Routine.
/// Computes the value of the natural base raised to the @a xpn power (e.g. e^x).
/// @param [in] xpn Exponent operand.
/// @return Value of natural base raised to the @a xpn power.
static inline EGWsingle egwExpf(const EGWsingle xpn)
    { return expf(xpn); }

/// Power of Natural Base Routine.
/// Computes the value of the natural base raised to the @a xpn power (e.g. e^x).
/// @param [in] xpn Exponent operand.
/// @return Value of natural base raised to the @a xpn power.
static inline EGWdouble egwExpd(const EGWdouble xpn)
    { return exp(xpn); }

/// Power of Natural Base Routine.
/// Computes the value of the natural base raised to the @a xpn power (e.g. e^x).
/// @param [in] xpn Exponent operand.
/// @return Value of natural base raised to the @a xpn power.
static inline EGWtriple egwExpt(const EGWtriple xpn)
    { return expl(xpn); }

/// Power of 2 Routine.
/// Computes the value of 2 raised to the @a xpn power (e.g. 2^x).
/// @param [in] xpn Exponent operand.
/// @return Value of 2 raised to the @a xpn power.
static inline EGWsingle egwExp2f(const EGWsingle xpn)
    { return exp2f(xpn); }

/// Power of 2 Routine.
/// Computes the value of 2 raised to the @a xpn power (e.g. 2^x).
/// @param [in] xpn Exponent operand.
/// @return Value of 2 raised to the @a xpn power.
static inline EGWdouble egwExp2d(const EGWdouble xpn)
    { return exp2(xpn); }

/// Power of 2 Routine.
/// Computes the value of 2 raised to the @a xpn power (e.g. 2^x).
/// @param [in] xpn Exponent operand.
/// @return Value of 2 raised to the @a xpn power.
static inline EGWtriple egwExp2t(const EGWtriple xpn)
    { return expl(xpn); }

/// Power of 10 Routine.
/// Computes the value of 10 raised to the @a xpn power (e.g. 10^x).
/// @param [in] xpn Exponent operand.
/// @return Value of 10 raised to the @a xpn power.
static inline EGWsingle egwExp10f(const EGWsingle xpn)
    { return powf(10.0f, xpn); }

/// Power of 10 Routine.
/// Computes the value of 10 raised to the @a xpn power (e.g. 10^x).
/// @param [in] xpn Exponent operand.
/// @return Value of 10 raised to the @a xpn power.
static inline EGWdouble egwExp10d(const EGWdouble xpn)
    { return pow(10.0, xpn); }

/// Power of 10 Routine.
/// Computes the value of 10 raised to the @a xpn power (e.g. 10^x).
/// @param [in] xpn Exponent operand.
/// @return Value of 10 raised to the @a xpn power.
static inline EGWtriple egwExp10t(const EGWtriple xpn)
    { return powf((EGWtriple)10.0, xpn); }

/// Natural Logarithm Routine.
/// Computes the natural logarithm of @a val (e.g. log10(x)/log10(e)).
/// @param [in] val Value operand.
/// @return Natural logarithm of @a val.
static inline EGWsingle egwLogf(const EGWsingle val)
    { return logf(val); }

/// Natural Logarithm Routine.
/// Computes the natural logarithm of @a val (e.g. log10(x)/log10(e)).
/// @param [in] val Value operand.
/// @return Natural logarithm of @a val.
static inline EGWdouble egwLogd(const EGWdouble val)
    { return log(val); }

/// Natural Logarithm Routine.
/// Computes the natural logarithm of @a val (e.g. log10(x)/log10(e)).
/// @param [in] val Value operand.
/// @return Natural logarithm of @a val.
static inline EGWtriple egwLogt(const EGWtriple val)
    { return logl(val); }

/// Base 2 Logarithm Routine.
/// Computes the base 2 logarithm of @a val (e.g. log10(x)/log10(2)).
/// @param [in] val Value operand.
/// @return Base 2 logarithm of @a val.
static inline EGWsingle egwLog2f(const EGWsingle val)
    { return log2f(val); }

/// Base 2 Logarithm Routine.
/// Computes the base 2 logarithm of @a val (e.g. log10(x)/log10(2)).
/// @param [in] val Value operand.
/// @return Base 2 logarithm of @a val.
static inline EGWdouble egwLog2d(const EGWdouble val)
    { return log2(val); }

/// Base 2 Logarithm Routine.
/// Computes the base 2 logarithm of @a val (e.g. log10(x)/log10(2)).
/// @param [in] val Value operand.
/// @return Base 2 logarithm of @a val.
static inline EGWtriple egwLog2t(const EGWtriple val)
    { return logl(val); }

/// Base 10 Logarithm Routine.
/// Computes the base 10 logarithm of @a val.
/// @param [in] val Value operand.
/// @return Base 10 logarithm of @a val.
static inline EGWsingle egwLog10f(const EGWsingle val)
    { return log10f(val); }

/// Base 10 Logarithm Routine.
/// Computes the base 10 logarithm of @a val.
/// @param [in] val Value operand.
/// @return Base 10 logarithm of @a val.
static inline EGWdouble egwLog10d(const EGWdouble val)
    { return log10(val); }

/// Base 10 Logarithm Routine.
/// Computes the base 10 logarithm of @a val.
/// @param [in] val Value operand.
/// @return Base 10 logarithm of @a val.
static inline EGWtriple egwLog10t(const EGWtriple val)
    { return log10l(val); }

/// Square Root Routine.
/// Computes the squared root of @a val.
/// @param [in] val Value operand.
/// @return Squared root of @a val.
static inline EGWsingle egwSqrtf(const EGWsingle val)
    { return sqrtf(val); }

/// Square Root Routine.
/// Computes the squared root of @a val.
/// @param [in] val Value operand.
/// @return Squared root of @a val.
static inline EGWdouble egwSqrtd(const EGWdouble val)
    { return sqrt(val); }

/// Square Root Routine.
/// Computes the squared root of @a val.
/// @param [in] val Value operand.
/// @return Squared root of @a val.
static inline EGWtriple egwSqrtt(const EGWtriple val)
    { return sqrtl(val); }

/// Inverse Square Root Routine.
/// Computes the inverse squared root of @a val (e.g. 1/sqrt(x)).
/// @param [in] val Value operand.
/// @return Inverse squared root of @a val.
static inline EGWsingle egwInvSqrtf(const EGWsingle val)
    { return 1.0f / sqrtf(val); }

/// Inverse Square Root Routine.
/// Computes the inverse squared root of @a val (e.g. 1/sqrt(x)).
/// @param [in] val Value operand.
/// @return Inverse squared root of @a val.
static inline EGWdouble egwInvSqrtd(const EGWdouble val)
    { return 1.0 / sqrt(val); }

/// Inverse Square Root Routine.
/// Computes the inverse squared root of @a val (e.g. 1/sqrt(x)).
/// @param [in] val Value operand.
/// @return Inverse squared root of @a val.
static inline EGWtriple egwInvSqrtt(const EGWtriple val)
    { return (EGWtriple)1.0 / sqrtl(val); }

/// Cubed Root Routine.
/// Computes the cubed root of @a val.
/// @param [in] val Value operand.
/// @return Cubed root of @a val.
static inline EGWsingle egwCbrtf(const EGWsingle val)
    { return cbrtf(val); }

/// Cubed Root Routine.
/// Computes the cubed root of @a val.
/// @param [in] val Value operand.
/// @return Cubed root of @a val.
static inline EGWdouble egwCbrtd(const EGWdouble val)
    { return cbrt(val); }

/// Cubed Root Routine.
/// Computes the cubed root of @a val.
/// @param [in] val Value operand.
/// @return Cubed root of @a val.
static inline EGWtriple egwCbrtt(const EGWtriple val)
    { return cbrtl(val); }

/// Inverse Cubed Root Routine.
/// Computes the inverse cubed root of @a val (i.e. 1/cbrt(x)).
/// @param [in] val Value operand.
/// @return Inverse squared root of @a val.
static inline EGWsingle egwInvCbrtf(const EGWsingle val)
    { return 1.0f / cbrtf(val); }

/// Inverse Cubed Root Routine.
/// Computes the inverse cubed root of @a val (i.e. 1/cbrt(x)).
/// @param [in] val Value operand.
/// @return Inverse squared root of @a val.
static inline EGWdouble egwInvCbrtd(const EGWdouble val)
    { return 1.0 / cbrt(val); }

/// Inverse Cubed Root Routine.
/// Computes the inverse cubed root of @a val (i.e. 1/cbrt(x)).
/// @param [in] val Value operand.
/// @return Inverse squared root of @a val.
static inline EGWtriple egwInvCbrtt(const EGWtriple val)
    { return (EGWtriple)1.0 / cbrtl(val); }


// !!!: ***** Angular Routines *****

/// Degrees-to-Radians Conversion Routine.
/// Converts an angle value in degrees into radians (e.g. x * multipler).
/// @param [in] angle_d Angle value (degrees).
/// @return Angle value (radians).
EGWsingle egwDegToRadf(const EGWsingle angle_d);

/// Degrees-to-Radians Conversion Routine.
/// Converts an angle value in degrees into radians (e.g. x * multipler).
/// @param [in] angle_d Angle value (degrees).
/// @return Angle value (radians).
EGWdouble egwDegToRadd(const EGWdouble angle_d);

/// Degrees-to-Radians Conversion Routine.
/// Converts an angle value in degrees into radians (e.g. x * multipler).
/// @param [in] angle_d Angle value (degrees).
/// @return Angle value (radians).
EGWtriple egwDegToRadt(const EGWtriple angle_d);

/// Radians-to-Degrees Conversion Routine.
/// Converts an angle value in radians into degrees (e.g. x * multipler).
/// @param [in] angle_r Angle value (radians).
/// @return Angle value (degrees).
EGWsingle egwRadToDegf(const EGWsingle angle_r);

/// Radians-to-Degrees Conversion Routine.
/// Converts an angle value in radians into degrees (e.g. x * multipler).
/// @param [in] angle_r Angle value (radians).
/// @return Angle value (degrees).
EGWdouble egwRadToDegd(const EGWdouble angle_r);

/// Radians-to-Degrees Conversion Routine.
/// Converts an angle value in radians into degrees (e.g. x * multipler).
/// @param [in] angle_r Angle value (radians).
/// @return Angle value (degrees).
EGWtriple egwRadToDegt(const EGWtriple angle_r);

/// Arrayed Degrees-to-Radians Conversion Routine.
/// Converts an array of angle values in degrees into radians (e.g. x * multipler).
/// @param [in] angle_d_in Array of angle value (degrees) input operands.
/// @param [out] angle_r_out Array of angle value (radians) output operands.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwDegToRadfv(const EGWsingle* angle_d_in, EGWsingle* angle_r_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);

/// Arrayed Degrees-to-Radians Conversion Routine.
/// Converts an array of angle values in degrees into radians (e.g. x * multipler).
/// @param [in] angle_d_in Array of angle value (degrees) input operands.
/// @param [out] angle_r_out Array of angle value (radians) output operands.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwDegToRaddv(const EGWdouble* angle_d_in, EGWdouble* angle_r_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);

/// Arrayed Degrees-to-Radians Conversion Routine.
/// Converts an array of angle values in degrees into radians (e.g. x * multipler).
/// @param [in] angle_d_in Array of angle value (degrees) input operands.
/// @param [out] angle_r_out Array of angle value (radians) output operands.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwDegToRadtv(const EGWtriple* angle_d_in, EGWtriple* angle_r_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);

/// Arrayed Radians-to-Degrees Conversion Routine.
/// Converts an array of angle values in radians into degrees (e.g. x * multipler).
/// @param [in] angle_r_in Array of angle value (radians) input operands.
/// @param [out] angle_d_out Array of angle value (degrees) output operands.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwRadToDegfv(const EGWsingle* angle_r_in, EGWsingle* angle_d_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);

/// Arrayed Radians-to-Degrees Conversion Routine.
/// Converts an array of angle values in radians into degrees (e.g. x * multipler).
/// @param [in] angle_r_in Array of angle value (radians) input operands.
/// @param [out] angle_d_out Array of angle value (degrees) output operands.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwRadToDegdv(const EGWdouble* angle_r_in, EGWdouble* angle_d_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);

/// Arrayed Radians-to-Degrees Conversion Routine.
/// Converts an array of angle values in radians into degrees (e.g. x * multipler).
/// @param [in] angle_r_in Array of angle value (radians) input operands.
/// @param [out] angle_d_out Array of angle value (degrees) output operands.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwRadToDegtv(const EGWtriple* angle_r_in, EGWtriple* angle_d_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count);

/// Radian Reduction [0,2PI) Routine.
/// Ensures a radian measurement to a range of [0,2PI).
/// @param [in] angle_r Angle value (radians).
/// @return Angle value [0,2PI) (radians).
EGWsingle egwRadReduce02PIf(EGWsingle angle_r);

/// Radian Reduction [0,2PI) Routine.
/// Ensures a radian measurement to a range of [0,2PI).
/// @param [in] angle_r Angle value (radians).
/// @return Angle value [0,2PI) (radians).
EGWdouble egwRadReduce02PId(EGWdouble angle_r);

/// Radian Reduction [0,2PI) Routine.
/// Ensures a radian measurement to a range of [0,2PI).
/// @param [in] angle_r Angle value (radians).
/// @return Angle value [0,2PI) (radians).
EGWtriple egwRadReduce02PIt(EGWtriple angle_r);

/// Radian Reduction [-PI,PI) Routine.
/// Ensures a radian measurement to a range of [-PI,PI).
/// @param [in] angle_r Angle value (radians).
/// @return Angle value [-PI,PI) (radians).
EGWsingle egwRadReduceNPIPIf(EGWsingle angle_r);

/// Radian Reduction [-PI,PI) Routine.
/// Ensures a radian measurement to a range of [-PI,PI).
/// @param [in] angle_r Angle value (radians).
/// @return Angle value [-PI,PI) (radians).
EGWdouble egwRadReduceNPIPId(EGWdouble angle_r);

/// Radian Reduction [-PI,PI) Routine.
/// Ensures a radian measurement to a range of [-PI,PI).
/// @param [in] angle_r Angle value (radians).
/// @return Angle value [-PI,PI) (radians).
EGWtriple egwRadReduceNPIPIt(EGWtriple angle_r);

/// Degree Reduction [0,360) Routine.
/// Ensures a degree measurement to a range of [0,360).
/// @param [in] angle_d Angle value (degrees).
/// @return Angle value [0,360) (degrees).
EGWsingle egwDegReduce0360f(EGWsingle angle_d);

/// Degree Reduction [0,360) Routine.
/// Ensures a degree measurement to a range of [0,360).
/// @param [in] angle_d Angle value (degrees).
/// @return Angle value [0,360) (degrees).
EGWdouble egwDegReduce0360d(EGWdouble angle_d);

/// Degree Reduction [0,360) Routine.
/// Ensures a degree measurement to a range of [0,360).
/// @param [in] angle_d Angle value (degrees).
/// @return Angle value [0,360) (degrees).
EGWtriple egwDegReduce0360t(EGWtriple angle_d);

/// Degree Reduction [-180,180) Routine.
/// Ensures a degree measurement to a range of [-180,180).
/// @param [in] angle_d Angle value (degrees).
/// @return Angle value [-180,180) (degrees).
EGWsingle egwDegReducefN180180f(EGWsingle angle_d);

/// Degree Reduction [-180,180) Routine.
/// Ensures a degree measurement to a range of [-180,180).
/// @param [in] angle_d Angle value (degrees).
/// @return Angle value [-180,180) (degrees).
EGWdouble egwDegReducefN180180d(EGWdouble angle_d);

/// Degree Reduction [-180,180) Routine.
/// Ensures a degree measurement to a range of [-180,180).
/// @param [in] angle_d Angle value (degrees).
/// @return Angle value [-180,180) (degrees).
EGWtriple egwDegReducefN180180t(EGWtriple angle_d);


// !!!: ***** Value Transition Routines *****

/// Value Clamping Routine.
/// Clamps @a val to be in the range [@c clamp_min, @a clamp_max] (e.g. min(max(x, min),max)).
/// @param [in] val Value operand.
/// @param [in] clamp_min Clamping signed minimum value.
/// @param [in] clamp_max Clamping signed maximum value.
/// @return Value clamped to [min,max].
EGW_ATRB_FASTCALL EGWint egwClampi(const EGWint val, const EGWint clamp_min, const EGWint clamp_max);

/// Value Clamping Routine.
/// Clamps @a val to be in the range [@c clamp_min, @a clamp_max] (e.g. min(max(x, min),max)).
/// @param [in] val Value operand.
/// @param [in] clamp_min Clamping unsigned minimum value.
/// @param [in] clamp_max Clamping unsigned maximum value.
/// @return Value clamped to [min,max].
EGW_ATRB_FASTCALL EGWuint egwClampui(const EGWuint val, const EGWuint clamp_min, const EGWuint clamp_max);

/// Value Clamping Routine.
/// Clamps @a val to be in the range [@c clamp_min, @a clamp_max] (e.g. min(max(x, min),max)), taking into account FP epsilon.
/// @param [in] val Value operand.
/// @param [in] clamp_min Clamping minimum value.
/// @param [in] clamp_max Clamping maximum value.
/// @return Value clamped to [min,max].
EGWsingle egwClampf(const EGWsingle val, const EGWsingle clamp_min, const EGWsingle clamp_max);

/// Value Clamping Routine.
/// Clamps @a val to be in the range [@c clamp_min, @a clamp_max] (e.g. min(max(x, min),max)), taking into account FP epsilon.
/// @param [in] val Value operand.
/// @param [in] clamp_min Clamping minimum value.
/// @param [in] clamp_max Clamping maximum value.
/// @return Value clamped to [min,max].
EGWdouble egwClampd(const EGWdouble val, const EGWdouble clamp_min, const EGWdouble clamp_max);

/// Value Clamping Routine.
/// Clamps @a val to be in the range [@c clamp_min, @a clamp_max] (e.g. min(max(x, min),max)), taking into account FP epsilon.
/// @param [in] val Value operand.
/// @param [in] clamp_min Clamping minimum value.
/// @param [in] clamp_max Clamping maximum value.
/// @return Value clamped to [min,max].
EGWtriple egwClampt(const EGWtriple val, const EGWtriple clamp_min, const EGWtriple clamp_max);

/// Value Clamping Routine.
/// Clamps @a val to be in the range [@c clamp_min, @a clamp_max] (e.g. min(max(x, min),max)), taking into account FP epsilon.
/// @param [in] val Value operand.
/// @param [in] clamp_min Clamping minimum value.
/// @param [in] clamp_max Clamping maximum value.
/// @return Value clamped to [min,max].
EGWtime egwClampm(const EGWtime val, const EGWtime clamp_min, const EGWtime clamp_max);

/// Value Clamping [0,1] Routine.
/// Clamps @a val to be in the range [0,1] (e.g. min(max(x, 0),1)).
/// @param [in] val Value operand.
/// @return Value clamped to [0,1].
EGW_ATRB_FASTCALL EGWint egwClamp01i(const EGWint val);

/// Value Clamping [0,1] Routine.
/// Clamps @a val to be in the range [0,1] (e.g. min(max(x, 0),1)).
/// @param [in] val Value operand.
/// @return Value clamped to [0,1].
EGW_ATRB_FASTCALL EGWuint egwClamp01ui(const EGWuint val);

/// Value Clamping [0,1] Routine.
/// Clamps @a val to be in the range [0,1] (e.g. min(max(x, 0),1)), taking into account FP epsilon.
/// @param [in] val Value operand.
/// @return Value clamped to [0,1].
EGWsingle egwClamp01f(const EGWsingle val);

/// Value Clamping [0,1] Routine.
/// Clamps @a val to be in the range [0,1] (e.g. min(max(x, 0),1)), taking into account FP epsilon.
/// @param [in] val Value operand.
/// @return Value clamped to [0,1].
EGWdouble egwClamp01d(const EGWdouble val);

/// Value Clamping [0,1] Routine.
/// Clamps @a val to be in the range [0,1] (e.g. min(max(x, 0),1)), taking into account FP epsilon.
/// @param [in] val Value operand.
/// @return Value clamped to [0,1].
EGWtriple egwClamp01t(const EGWtriple val);

/// Value Clamping [0,255] Routine.
/// Clamps @a val to be in the range [0,255] (e.g. min(max(x, 0), 255)).
/// @param [in] val Value operand.
/// @return Value clamped to [0,255].
EGW_ATRB_FASTCALL EGWint egwClamp0255i(const EGWint val);

/// Value Clamping [0,inf) Routine.
/// Clamps @a val to be in the positive range [0,inf) (e.g. min(max(x, 0), INT_MAX)).
/// @param [in] val Value operand.
/// @return Value clamped to [0,inf).
EGW_ATRB_FASTCALL EGWint egwClampPosi(const EGWint val);

/// Value Clamping [0,inf) Routine.
/// Clamps @a val to be in the positive range [0,inf) (e.g. min(max(x, 0), FLOAT_MAX)).
/// @param [in] val Value operand.
/// @return Value clamped to [0,inf).
EGWsingle egwClampPosf(const EGWsingle val);

/// Value Clamping (-inf,0] Routine.
/// Clamps @a val to be in the negative range (-inf,0] (e.g. min(max(x, INT_MIN), 0)).
/// @param [in] val Value operand.
/// @return Value clamped to (-inf,0].
EGW_ATRB_FASTCALL EGWint egwClampNegi(const EGWint val);

/// Value Clamping (-inf,0] Routine.
/// Clamps @a val to be in the negative range (-inf,0] (e.g. min(max(x, -FLOAT_MAX), 0)).
/// @param [in] val Value operand.
/// @return Value clamped to (-inf,0].
EGWsingle egwClampNegf(const EGWsingle val);

/// Round Up to Nearest Power of 2 Routine.
/// Rounds @a val up to the nearest power of 2 (if not already a power of 2).
/// @param [in] val Value operand.
/// @return Value rounded up to next power of 2.
EGW_ATRB_FASTCALL EGWuint egwRoundUpPow2ui(EGWuint val);

/// Round Up to Nearest Power of 2 Routine.
/// Rounds @a val up to the nearest power of 2 (if not already a power of 2).
/// @param [in] val Value operand.
/// @return Value rounded up to next power of 2.
EGW_ATRB_FASTCALL EGWuint8 egwRoundUpPow2ui8(EGWuint8 val);

/// Round Up to Nearest Power of 2 Routine.
/// Rounds @a val up to the nearest power of 2 (if not already a power of 2).
/// @param [in] val Value operand.
/// @return Value rounded up to next power of 2.
EGW_ATRB_FASTCALL EGWuint16 egwRoundUpPow2ui16(EGWuint16 val);

/// Round Up to Nearest Power of 2 Routine.
/// Rounds @a val up to the nearest power of 2 (if not already a power of 2).
/// @param [in] val Value operand.
/// @return Value rounded up to next power of 2.
EGW_ATRB_FASTCALL EGWuint32 egwRoundUpPow2ui32(EGWuint32 val);

/// Round Up to Nearest Power of 2 Routine.
/// Rounds @a val up to the nearest power of 2 (if not already a power of 2).
/// @param [in] val Value operand.
/// @return Value rounded up to next power of 2.
EGW_ATRB_FASTCALL EGWuint64 egwRoundUpPow2ui64(EGWuint64 val);

/// Round Down to Nearest Power of 2 Routine.
/// Rounds @a val down to the nearest power of 2 (if not already a power of 2).
/// @param [in] val Value operand.
/// @return Value rounded down to next power of 2.
static inline EGWuint egwRoundDownPow2ui(EGWuint val)
    { return egwRoundUpPow2ui((val >> 1) + 1); }

/// Round Down to Nearest Power of 2 Routine.
/// Rounds @a val down to the nearest power of 2 (if not already a power of 2).
/// @param [in] val Value operand.
/// @return Value rounded down to next power of 2.
static inline EGWuint8 egwRoundDownPow2ui8(EGWuint8 val)
    { return egwRoundUpPow2ui8((val >> 1) + 1); }

/// Round Down to Nearest Power of 2 Routine.
/// Rounds @a val down to the nearest power of 2 (if not already a power of 2).
/// @param [in] val Value operand.
/// @return Value rounded down to next power of 2.
static inline EGWuint16 egwRoundDownPow2ui16(EGWuint16 val)
    { return egwRoundUpPow2ui16((val >> 1) + 1); }

/// Round Down to Nearest Power of 2 Routine.
/// Rounds @a val down to the nearest power of 2 (if not already a power of 2).
/// @param [in] val Value operand.
/// @return Value rounded down to next power of 2.
static inline EGWuint32 egwRoundDownPow2ui32(EGWuint32 val)
    { return egwRoundUpPow2ui32((val >> 1) + 1); }

/// Round Down to Nearest Power of 2 Routine.
/// Rounds @a val down to the nearest power of 2 (if not already a power of 2).
/// @param [in] val Value operand.
/// @return Value rounded down to next power of 2.
static inline EGWuint64 egwRoundDownPow2ui64(EGWuint64 val)
    { return egwRoundUpPow2ui64((val >> 1) + 1); }

/// Round Up to Nearest Multiple Routine.
/// Rounds @a val up to the nearest multiple of @a mult (if not already a multiple of).
/// @param [in] val Value operand.
/// @param [in] mult Multiple value operand.
/// @return Value rounded up to next multiple of.
EGW_ATRB_FASTCALL EGWuint egwRoundUpMultipleui(EGWuint val, EGWuint mult);

/// Round Up to Nearest Multiple Routine.
/// Rounds @a val up to the nearest multiple of @a mult (if not already a multiple of).
/// @param [in] val Value operand.
/// @param [in] mult Multiple value operand.
/// @return Value rounded up to next multiple of.
EGW_ATRB_FASTCALL EGWuint8 egwRoundUpMultipleui8(EGWuint8 val, EGWuint8 mult);

/// Round Up to Nearest Multiple Routine.
/// Rounds @a val up to the nearest multiple of @a mult (if not already a multiple of).
/// @param [in] val Value operand.
/// @param [in] mult Multiple value operand.
/// @return Value rounded up to next multiple of.
EGW_ATRB_FASTCALL EGWuint16 egwRoundUpMultipleui16(EGWuint16 val, EGWuint16 mult);

/// Round Up to Nearest Multiple Routine.
/// Rounds @a val up to the nearest multiple of @a mult (if not already a multiple of).
/// @param [in] val Value operand.
/// @param [in] mult Multiple value operand.
/// @return Value rounded up to next multiple of.
EGW_ATRB_FASTCALL EGWuint32 egwRoundUpMultipleui32(EGWuint32 val, EGWuint32 mult);

/// Round Up to Nearest Multiple Routine.
/// Rounds @a val up to the nearest multiple of @a mult (if not already a multiple of).
/// @param [in] val Value operand.
/// @param [in] mult Multiple value operand.
/// @return Value rounded up to next multiple of.
EGW_ATRB_FASTCALL EGWuint64 egwRoundUpMultipleui64(EGWuint64 val, EGWuint64 mult);

/// Round Up to Nearest Multiple Routine.
/// Rounds @a val up to the nearest multiple of @a mult (if not already a multiple of).
/// @param [in] val Value operand.
/// @param [in] mult Multiple value operand.
/// @return Value rounded up to next multiple of.
EGW_ATRB_FASTCALL EGWint egwRoundUpMultiplei(EGWint val, EGWint mult);

/// Round Up to Nearest Multiple Routine.
/// Rounds @a val up to the nearest multiple of @a mult (if not already a multiple of).
/// @param [in] val Value operand.
/// @param [in] mult Multiple value operand.
/// @return Value rounded up to next multiple of.
EGW_ATRB_FASTCALL EGWint8 egwRoundUpMultiplei8(EGWint8 val, EGWint8 mult);

/// Round Up to Nearest Multiple Routine.
/// Rounds @a val up to the nearest multiple of @a mult (if not already a multiple of).
/// @param [in] val Value operand.
/// @param [in] mult Multiple value operand.
/// @return Value rounded up to next multiple of.
EGW_ATRB_FASTCALL EGWint16 egwRoundUpMultiplei16(EGWint16 val, EGWint16 mult);

/// Round Up to Nearest Multiple Routine.
/// Rounds @a val up to the nearest multiple of @a mult (if not already a multiple of).
/// @param [in] val Value operand.
/// @param [in] mult Multiple value operand.
/// @return Value rounded up to next multiple of.
EGW_ATRB_FASTCALL EGWint32 egwRoundUpMultiplei32(EGWint32 val, EGWint32 mult);

/// Round Up to Nearest Multiple Routine.
/// Rounds @a val up to the nearest multiple of @a mult (if not already a multiple of).
/// @param [in] val Value operand.
/// @param [in] mult Multiple value operand.
/// @return Value rounded up to next multiple of.
EGW_ATRB_FASTCALL EGWint64 egwRoundUpMultiplei64(EGWint64 val, EGWint64 mult);

/// Linear Interpolation Routine.
/// Computes the linear interpolation between @a val_src and @a val_dst based on transition coefficient @a alpha (e.g. x * (1 - a) + y * a).
/// @param [in] val_src Originating value.
/// @param [in] val_dst Destination value.
/// @param [in] alpha Transition coefficient [0,1].
/// @return Linearly interpolated value.
EGWsingle egwLerpf(const EGWsingle val_src, const EGWsingle val_dst, const EGWsingle alpha);

/// Linear Interpolation Routine.
/// Computes the linear interpolation between @a val_src and @a val_dst based on transition coefficient @a alpha (e.g. x * (1 - a) + y * a).
/// @param [in] val_src Originating value.
/// @param [in] val_dst Destination value.
/// @param [in] alpha Transition coefficient [0,1].
/// @return Linearly interpolated value.
EGWdouble egwLerpd(const EGWdouble val_src, const EGWdouble val_dst, const EGWdouble alpha);

/// Linear Interpolation Routine.
/// Computes the linear interpolation between @a val_src and @a val_dst based on transition coefficient @a alpha (e.g. x * (1 - a) + y * a).
/// @param [in] val_src Originating value.
/// @param [in] val_dst Destination value.
/// @param [in] alpha Transition coefficient [0,1].
/// @return Linearly interpolated value.
EGWtriple egwLerpt(const EGWtriple val_src, const EGWtriple val_dst, const EGWtriple alpha);

/// Linear Blend Routine.
/// Computes the linear blend between @a val_lhs and @a val_rhs based on respective weight coefficients (i.e.  x * wx + y * wy).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] wgt_lhs Weight coefficient for lhs operand [0,1].
/// @param [in] val_rhs Value rhs operand.
/// @param [in] wgt_rhs Weight coefficient for rhs operand [0.1].
/// @return Linearly blended value.
EGWsingle egwBlendf(const EGWsingle val_lhs, const EGWsingle wgt_lhs, const EGWsingle val_rhs, const EGWsingle wgt_rhs);

/// Linear Blend Routine.
/// Computes the linear blend between @a val_lhs and @a val_rhs based on respective weight coefficients (i.e.  x * wx + y * wy).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] wgt_lhs Weight coefficient for lhs operand [0,1].
/// @param [in] val_rhs Value rhs operand.
/// @param [in] wgt_rhs Weight coefficient for rhs operand [0.1].
/// @return Linearly blended value.
EGWdouble egwBlendd(const EGWdouble val_lhs, const EGWdouble wgt_lhs, const EGWdouble val_rhs, const EGWdouble wgt_rhs);

/// Linear Blend Routine.
/// Computes the linear blend between @a val_lhs and @a val_rhs based on respective weight coefficients (i.e.  x * wx + y * wy).
/// @param [in] val_lhs Value lhs operand.
/// @param [in] wgt_lhs Weight coefficient for lhs operand [0,1].
/// @param [in] val_rhs Value rhs operand.
/// @param [in] wgt_rhs Weight coefficient for rhs operand [0.1].
/// @return Linearly blended value.
EGWtriple egwBlendt(const EGWtriple val_lhs, const EGWtriple wgt_lhs, const EGWtriple val_rhs, const EGWtriple wgt_rhs);

/// Step Function Routine.
/// Evaluates a step function with input @a val and edge positioned at @a edge (e.g. x < edge ? 0 : 1).
/// @param [in] val Value operand.
/// @param [in] edge Step function's edge position.
/// @return 1 if @a val is greater or equal to @a edge, otherwise 0.
static inline EGWint egwStepi(const EGWint val, const EGWint edge)
    { return (val < edge ? 0 : 1); }

/// Step Function Routine.
/// Evaluates a step function with input @a val and edge positioned at @a edge (e.g. x < edge ? 0 : 1).
/// @param [in] val Value operand.
/// @param [in] edge Step function's edge position.
/// @return 1 if @a val is greater or equal to @a edge, otherwise 0.
static inline EGWint egwStepui(const EGWuint val, const EGWuint edge)
    { return (val < edge ? 0 : 1); }

/// Step Function Routine.
/// Evaluates a step function with input @a val and edge positioned at @a edge (e.g. x < edge ? 0 : 1), taking into account FP epsilon.
/// @param [in] val Value operand.
/// @param [in] edge Step function's edge position.
/// @return 1 if @a val is greater or equal to @a edge, otherwise 0.
static inline EGWint egwStepf(const EGWsingle val, const EGWsingle edge)
    { return (val + EGW_SFLT_EPSILON < edge - EGW_SFLT_EPSILON ? 0 : 1); }

/// Step Function Routine.
/// Evaluates a step function with input @a val and edge positioned at @a edge (e.g. x < edge ? 0 : 1), taking into account FP epsilon.
/// @param [in] val Value operand.
/// @param [in] edge Step function's edge position.
/// @return 1 if @a val is greater or equal to @a edge, otherwise 0.
static inline EGWint egwStepd(const EGWdouble val, const EGWdouble edge)
    { return (val + EGW_DFLT_EPSILON < edge - EGW_DFLT_EPSILON ? 0 : 1); }

/// Step Function Routine.
/// Evaluates a step function with input @a val and edge positioned at @a edge (e.g. x < edge ? 0 : 1), taking into account FP epsilon.
/// @param [in] val Value operand.
/// @param [in] edge Step function's edge position.
/// @return 1 if @a val is greater or equal to @a edge, otherwise 0.
static inline EGWint egwStept(const EGWtriple val, const EGWtriple edge)
    { return (val + EGW_TFLT_EPSILON < edge - EGW_TFLT_EPSILON ? 0 : 1); }

/// Smooth Step Function Routine.
/// Evaluates a smooth Hermite interpolation step function with input @a val and two edges positioned at @a edge_lead and at @a edge_trail.
/// @param [in] val Value operand.
/// @param [in] edge_lead Leading edge operand.
/// @param [in] edge_trail Trailing edge operand.
/// @return 0 if @a val is less than @a edge_lead, 1 if @a val is greater than @a edge_trail, smooth step function evaluation otherwise..
EGWsingle egwSmoothStepf(const EGWsingle val, const EGWsingle edge_lead, const EGWsingle edge_trail);

/// Smooth Step Function Routine.
/// Evaluates a smooth Hermite interpolation step function with input @a val and two edges positioned at @a edge_lead and at @a edge_trail.
/// @param [in] val Value operand.
/// @param [in] edge_lead Leading edge operand.
/// @param [in] edge_trail Trailing edge operand.
/// @return 0 if @a val is less than @a edge_lead, 1 if @a val is greater than @a edge_trail, smooth step function evaluation otherwise..
EGWdouble egwSmoothStepd(const EGWdouble val, const EGWdouble edge_lead, const EGWdouble edge_trail);

/// Smooth Step Function Routine.
/// Evaluates a smooth Hermite interpolation step function with input @a val and two edges positioned at @a edge_lead and at @a edge_trail.
/// @param [in] val Value operand.
/// @param [in] edge_lead Leading edge operand.
/// @param [in] edge_trail Trailing edge operand.
/// @return 0 if @a val is less than @a edge_lead, 1 if @a val is greater than @a edge_trail, smooth step function evaluation otherwise..
EGWtriple egwSmoothStept(const EGWtriple val, const EGWtriple edge_lead, const EGWtriple edge_trail);


// !!!: ***** Fast Routines *****

/// Fast Inverse Square Root Routine.
/// Computes the fast inverse squared root of @a val (e.g. 1/sqrt(x)).
/// @param [in] val Value operand.
/// @return Fast inverse squared root of @a val.
EGWsingle egwFastInvSqrtf(const EGWsingle val);

/// Fast Sine Routine.
/// Computes the fast sine of the given angle @a angle_r.
/// @param [in] angle_r Angle value (radians).
/// @return Fast sine of @a angle_r.
EGWsingle egwFastSinf(const EGWsingle angle_r);

/// Faster Sine Routine.
/// Computes the fast sine of the given clamped angle @a angle_r with less precision.
/// @param [in] angle_r Angle value (radians) [-PI,PI].
/// @return Fast sine of @a angle_r.
EGWsingle egwFasterSinf(const EGWsingle angle_r);

/// Fastest Sine Routine.
/// Computes the fast sine of the given clamped angle @a angle_r with even less precision.
/// @param [in] angle_r Angle value (radians) [-PI,PI].
/// @return Fast sine of @a angle_r.
EGWsingle egwFastestSinf(const EGWsingle angle_r);

/// Fast Cosine Routine.
/// Computes the fast cosine of the given angle @a angle_r.
/// @param [in] angle_r Angle value (radians).
/// @return Fast cosine of @a angle_r.
/// @note Uses egwFasterSin as a base, this routine is included for simplicity.
EGWsingle egwFastCosf(const EGWsingle angle_r);

/// Fast Tangent Routine.
/// Computes the fast tangent of the given angle @a angle_r.
/// @param [in] angle_r Angle value (radians).
/// @return Fast tangent of @a angle_r.
/// @note Uses egwFasterSin as a base, this routine is included for simplicity.
EGWsingle egwFastTanf(const EGWsingle angle_r);

/// Fast Arc-Sine Routine.
/// Computes the fast arc-sine of the given value @a val in radians.
/// @param [in] val Value operand.
/// @return Fast arc-sine of @a val.
EGWsingle egwFastArcSinf(const EGWsingle val);

/// Fast Arc-Cosine Routine.
/// Computes the fase arc-cosine of the given value @a val in radians.
/// @param [in] val Value operand.
/// @return Fast arc-cosine of @a val.
EGWsingle egwFastArcCosf(const EGWsingle val);

/// Fast Arc-Tangent Y/X Routine.
/// Computes the fast arc-tangent of the given value (@c val_nmr / @a val_dnm) in radians [-PI,PI].
/// @param [in] val_nmr Value numerator operand.
/// @param [in] val_dnm Value denominator operand.
/// @return Fast arc-tangent of @a val_nmr / @a val_dnm.
/// @note Since both numerator and denominator values (and their signs) are available the correct quadrant can be computed in this routine.
EGWsingle egwFastArcTan2f(const EGWtriple val_nmr, const EGWtriple val_dnm);

/// @}

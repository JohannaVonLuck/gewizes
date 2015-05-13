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

/// @file egwMath.m
/// @ingroup geWizES_math_math
/// Base Mathematics Implementation.

#import <math.h>
#import "egwMath.h"


const EGWsingle egwSIZerof = 0.0f;
const EGWsingle egwSIOnef = 1.0f;
const EGWsingle egwSITwof = 2.0f;
const EGWsingle egwSINegOnef = -1.0f;
const EGWsingle egwSINegTwof = -2.0f;

EGWint egwIsZerof(const EGWsingle val) {
    return val - EGW_SFLT_EPSILON <= EGW_SFLT_EPSILON && val + EGW_SFLT_EPSILON >= -EGW_SFLT_EPSILON;
}

EGWint egwIsZerod(const EGWdouble val) {
    return val - EGW_DFLT_EPSILON <= EGW_DFLT_EPSILON && val + EGW_DFLT_EPSILON >= -EGW_DFLT_EPSILON;
}

EGWint egwIsZerot(const EGWtriple val) {
    return val - EGW_TFLT_EPSILON <= EGW_TFLT_EPSILON && val + EGW_TFLT_EPSILON >= -EGW_TFLT_EPSILON;
}

EGWint egwIsZerom(const EGWtime val) {
    return val - EGW_TIME_EPSILON <= EGW_TIME_EPSILON && val + EGW_TIME_EPSILON >= -EGW_TIME_EPSILON;
}

EGWint egwIsOnef(const EGWsingle val) {
    return val - EGW_SFLT_EPSILON <= 1.0f + EGW_SFLT_EPSILON && val + EGW_SFLT_EPSILON >= 1.0f - EGW_SFLT_EPSILON;
}

EGWint egwIsOned(const EGWdouble val) {
    return val - EGW_DFLT_EPSILON <= 1.0 + EGW_DFLT_EPSILON && val + EGW_DFLT_EPSILON >= 1.0 - EGW_DFLT_EPSILON;
}

EGWint egwIsOnet(const EGWtriple val) {
    return val - EGW_TFLT_EPSILON <= (EGWtriple)1.0 + EGW_TFLT_EPSILON && val + EGW_TFLT_EPSILON >= (EGWtriple)1.0 - EGW_TFLT_EPSILON;
}

EGWint egwIsOnem(const EGWtime val) {
    return val - EGW_TIME_EPSILON <= (EGWtime)1.0 + EGW_TIME_EPSILON && val + EGW_TIME_EPSILON >= (EGWtime)1.0 - EGW_TIME_EPSILON;
}

EGWint egwIsNegOnef(const EGWsingle val) {
    return val - EGW_SFLT_EPSILON <= -1.0f + EGW_SFLT_EPSILON && val + EGW_SFLT_EPSILON >= -1.0f - EGW_SFLT_EPSILON;
}

EGWint egwIsNegOned(const EGWdouble val) {
    return val - EGW_DFLT_EPSILON <= -1.0 + EGW_DFLT_EPSILON && val + EGW_DFLT_EPSILON >= -1.0 - EGW_DFLT_EPSILON;
}

EGWint egwIsNegOnet(const EGWtriple val) {
    return val - EGW_TFLT_EPSILON <= (EGWtriple)-1.0 + EGW_TFLT_EPSILON && val + EGW_TFLT_EPSILON >= (EGWtriple)-1.0 - EGW_TFLT_EPSILON;
}

EGWint egwIsNegOnem(const EGWtime val) {
    return val - EGW_TIME_EPSILON <= (EGWtime)1.0 + EGW_TIME_EPSILON && val + EGW_TIME_EPSILON >= (EGWtime)1.0 - EGW_TIME_EPSILON;
}

EGWint egwIsEqualf(const EGWsingle val_lhs, const EGWsingle val_rhs) {
    return val_lhs - EGW_SFLT_EPSILON <= val_rhs + EGW_SFLT_EPSILON && val_lhs + EGW_SFLT_EPSILON >= val_rhs - EGW_SFLT_EPSILON;
}

EGWint egwIsEquald(const EGWdouble val_lhs, const EGWdouble val_rhs) {
    return val_lhs - EGW_DFLT_EPSILON <= val_rhs + EGW_DFLT_EPSILON && val_lhs + EGW_DFLT_EPSILON >= val_rhs - EGW_DFLT_EPSILON;
}

EGWint egwIsEqualt(const EGWtriple val_lhs, const EGWtriple val_rhs) {
    return val_lhs - EGW_TFLT_EPSILON <= val_rhs + EGW_TFLT_EPSILON && val_lhs + EGW_TFLT_EPSILON >= val_rhs - EGW_TFLT_EPSILON;
}

EGWint egwIsEqualm(const EGWtime val_lhs, const EGWtime val_rhs) {
    return val_lhs - EGW_TIME_EPSILON <= val_rhs + EGW_TIME_EPSILON && val_lhs + EGW_TIME_EPSILON >= val_rhs - EGW_TIME_EPSILON;
}

EGWint egwIsNotEqualf(const EGWsingle val_lhs, const EGWsingle val_rhs) {
    return val_lhs - EGW_SFLT_EPSILON > val_rhs + EGW_SFLT_EPSILON || val_lhs + EGW_SFLT_EPSILON < val_rhs - EGW_SFLT_EPSILON;
}

EGWint egwIsNotEquald(const EGWdouble val_lhs, const EGWdouble val_rhs) {
    return val_lhs - EGW_DFLT_EPSILON > val_rhs + EGW_DFLT_EPSILON || val_lhs + EGW_DFLT_EPSILON < val_rhs - EGW_DFLT_EPSILON;
}

EGWint egwIsNotEqualt(const EGWtriple val_lhs, const EGWtriple val_rhs) {
    return val_lhs - EGW_TFLT_EPSILON > val_rhs + EGW_TFLT_EPSILON || val_lhs + EGW_TFLT_EPSILON < val_rhs - EGW_TFLT_EPSILON;
}

EGWint egwIsNotEqualm(const EGWtime val_lhs, const EGWtime val_rhs) {
    return val_lhs - EGW_TIME_EPSILON > val_rhs + EGW_TIME_EPSILON || val_lhs + EGW_TIME_EPSILON < val_rhs - EGW_TIME_EPSILON;
}

EGWint egwAbsi(const EGWint val) {
    return (val >= 0 ? val : -val);
}

EGWint8 egwAbsi8(const EGWint8 val) {
    return (val >= 0 ? val : -val);
}

EGWint16 egwAbsi16(const EGWint16 val) {
    return (val >= 0 ? val : -val);
}

EGWint32 egwAbsi32(const EGWint32 val) {
    return (val >= 0 ? val : -val);
}

EGWint64 egwAbsi64(const EGWint64 val) {
    return (val >= 0 ? val : -val);
}

EGW_ATRB_FASTCALL EGWint egwSigni(const EGWint val) {
    return (val > (EGWint)0 ? 1 : (val < (EGWint)0 ? -1 : 0));
}

EGW_ATRB_FASTCALL EGWint egwSigni8(const EGWint8 val) {
    return (val > (EGWint8)0 ? 1 : (val < (EGWint8)0 ? -1 : 0));
}

EGW_ATRB_FASTCALL EGWint egwSigni16(const EGWint16 val) {
    return (val > (EGWint16)0 ? 1 : (val < (EGWint16)0 ? -1 : 0));
}

EGW_ATRB_FASTCALL EGWint egwSigni32(const EGWint32 val) {
    return (val > (EGWint32)0 ? 1 : (val < (EGWint32)0 ? -1 : 0));
}

EGW_ATRB_FASTCALL EGWint egwSigni64(const EGWint64 val) {
    return (val > (EGWint64)0 ? 1 : (val < (EGWint64)0 ? -1 : 0));
}

EGWint egwSignf(const EGWsingle val) {
    return (val - EGW_SFLT_EPSILON > EGW_SFLT_EPSILON ? 1 : (val + EGW_SFLT_EPSILON < -EGW_SFLT_EPSILON ? -1 : 0));
}

EGWint egwSignd(const EGWdouble val) {
    return (val - EGW_DFLT_EPSILON > EGW_DFLT_EPSILON ? 1 : (val + EGW_DFLT_EPSILON < -EGW_DFLT_EPSILON ? -1 : 0));
}

EGWint egwSignt(const EGWtriple val) {
    return (val - EGW_TFLT_EPSILON > EGW_TFLT_EPSILON ? 1 : (val + EGW_TFLT_EPSILON < -EGW_TFLT_EPSILON ? -1 : 0));
}

EGWint egwSignm(const EGWtime val) {
    return (val - EGW_TIME_EPSILON > EGW_TIME_EPSILON ? 1 : (val + EGW_TIME_EPSILON < -EGW_TIME_EPSILON ? -1 : 0));
}

EGWsingle egwFractf(const EGWsingle val) {
    return (val >= 0.0f ? val - floorf(val) : val + ceilf(val));
}

EGWdouble egwFractd(const EGWdouble val) {
    return (val >= 0.0f ? val - floor(val) : val + ceil(val));
}

EGWtriple egwFractt(const EGWtriple val) {
    return (val >= 0.0f ? val - floorl(val) : val + ceill(val));
}

EGWtime egwFractm(const EGWtime val) {
    return (val >= 0.0f ? val - floor(val) : val + ceil(val));
}

EGW_ATRB_FASTCALL EGWint egwMin2i(const EGWint val_lhs, const EGWint val_rhs) {
    return (val_lhs >= val_rhs ? val_rhs : val_lhs);
}

EGW_ATRB_FASTCALL EGWint8 egwMin2i8(const EGWint8 val_lhs, const EGWint8 val_rhs) {
    return (val_lhs >= val_rhs ? val_rhs : val_lhs);
}

EGW_ATRB_FASTCALL EGWint16 egwMin2i16(const EGWint16 val_lhs, const EGWint16 val_rhs) {
    return (val_lhs >= val_rhs ? val_rhs : val_lhs);
}

EGW_ATRB_FASTCALL EGWint32 egwMin2i32(const EGWint32 val_lhs, const EGWint32 val_rhs) {
    return (val_lhs >= val_rhs ? val_rhs : val_lhs);
}

EGW_ATRB_FASTCALL EGWint64 egwMin2i64(const EGWint64 val_lhs, const EGWint64 val_rhs) {
    return (val_lhs >= val_rhs ? val_rhs : val_lhs);
}

EGW_ATRB_FASTCALL EGWuint egwMin2ui(const EGWuint val_lhs, const EGWuint val_rhs) {
    return (val_lhs >= val_rhs ? val_rhs : val_lhs);
}

EGW_ATRB_FASTCALL EGWuint8 egwMin2ui8(const EGWuint8 val_lhs, const EGWuint8 val_rhs) {
    return (val_lhs >= val_rhs ? val_rhs : val_lhs);
}

EGW_ATRB_FASTCALL EGWuint16 egwMin2ui16(const EGWuint16 val_lhs, const EGWuint16 val_rhs) {
    return (val_lhs >= val_rhs ? val_rhs : val_lhs);
}

EGW_ATRB_FASTCALL EGWuint32 egwMin2ui32(const EGWuint32 val_lhs, const EGWuint32 val_rhs) {
    return (val_lhs >= val_rhs ? val_rhs : val_lhs);
}

EGW_ATRB_FASTCALL EGWuint64 egwMin2ui64(const EGWuint64 val_lhs, const EGWuint64 val_rhs) {
    return (val_lhs >= val_rhs ? val_rhs : val_lhs);
}

EGWsingle egwMin2f(const EGWsingle val_lhs, const EGWsingle val_rhs) {
    return (val_lhs >= val_rhs ? val_rhs : val_lhs);
}

EGWdouble egwMin2d(const EGWdouble val_lhs, const EGWdouble val_rhs) {
    return (val_lhs >= val_rhs ? val_rhs : val_lhs);
}

EGWtriple egwMin2t(const EGWtriple val_lhs, const EGWtriple val_rhs) {
    return (val_lhs >= val_rhs ? val_rhs : val_lhs);
}

EGWtime egwMin2m(const EGWtime val_lhs, const EGWtime val_rhs) {
    return (val_lhs >= val_rhs ? val_rhs : val_lhs);
}

EGW_ATRB_FASTCALL EGWint egwMax2i(const EGWint val_lhs, const EGWint val_rhs) {
    return (val_lhs >= val_rhs ? val_lhs : val_rhs);
}

EGW_ATRB_FASTCALL EGWint8 egwMax2i8(const EGWint8 val_lhs, const EGWint8 val_rhs) {
    return (val_lhs >= val_rhs ? val_lhs : val_rhs);
}

EGW_ATRB_FASTCALL EGWint16 egwMax2i16(const EGWint16 val_lhs, const EGWint16 val_rhs) {
    return (val_lhs >= val_rhs ? val_lhs : val_rhs);
}

EGW_ATRB_FASTCALL EGWint32 egwMax2i32(const EGWint32 val_lhs, const EGWint32 val_rhs) {
    return (val_lhs >= val_rhs ? val_lhs : val_rhs);
}

EGW_ATRB_FASTCALL EGWint64 egwMax2i64(const EGWint64 val_lhs, const EGWint64 val_rhs) {
    return (val_lhs >= val_rhs ? val_lhs : val_rhs);
}

EGW_ATRB_FASTCALL EGWuint egwMax2ui(const EGWuint val_lhs, const EGWuint val_rhs) {
    return (val_lhs >= val_rhs ? val_lhs : val_rhs);
}

EGW_ATRB_FASTCALL EGWuint8 egwMax2ui8(const EGWuint8 val_lhs, const EGWuint8 val_rhs) {
    return (val_lhs >= val_rhs ? val_lhs : val_rhs);
}

EGW_ATRB_FASTCALL EGWuint16 egwMax2ui16(const EGWuint16 val_lhs, const EGWuint16 val_rhs) {
    return (val_lhs >= val_rhs ? val_lhs : val_rhs);
}

EGW_ATRB_FASTCALL EGWuint32 egwMax2ui32(const EGWuint32 val_lhs, const EGWuint32 val_rhs) {
    return (val_lhs >= val_rhs ? val_lhs : val_rhs);
}

EGW_ATRB_FASTCALL EGWuint64 egwMax2ui64(const EGWuint64 val_lhs, const EGWuint64 val_rhs) {
    return (val_lhs >= val_rhs ? val_lhs : val_rhs);
}

EGWsingle egwMax2f(const EGWsingle val_lhs, const EGWsingle val_rhs) {
    return (val_lhs >= val_rhs ? val_lhs : val_rhs);
}

EGWdouble egwMax2d(const EGWdouble val_lhs, const EGWdouble val_rhs) {
    return (val_lhs >= val_rhs ? val_lhs : val_rhs);
}

EGWtriple egwMax2t(const EGWtriple val_lhs, const EGWtriple val_rhs) {
    return (val_lhs >= val_rhs ? val_lhs : val_rhs);
}

EGWtime egwMax2m(const EGWtime val_lhs, const EGWtime val_rhs) {
    return (val_lhs >= val_rhs ? val_lhs : val_rhs);
}

EGW_ATRB_FASTCALL EGWint egwIsPow2i(const EGWint val) {
    return val && !(val & (val - 1));
}

EGW_ATRB_FASTCALL EGWint egwIsPow2i8(const EGWint8 val) {
    return val && !(val & (val - 1));
}

EGW_ATRB_FASTCALL EGWint egwIsPow2i16(const EGWint16 val) {
    return val && !(val & (val - 1));
}

EGW_ATRB_FASTCALL EGWint egwIsPow2i32(const EGWint32 val) {
    return val && !(val & (val - 1));
}

EGW_ATRB_FASTCALL EGWint egwIsPow2i64(const EGWint64 val) {
    return val && !(val & (val - 1));
}

EGW_ATRB_FASTCALL EGWint egwIsPow2ui(const EGWuint val) {
    return val && !(val & (val - 1));
}

EGW_ATRB_FASTCALL EGWint egwIsPow2ui8(const EGWuint8 val) {
    return val && !(val & (val - 1));
}

EGW_ATRB_FASTCALL EGWint egwIsPow2ui16(const EGWuint16 val) {
    return val && !(val & (val - 1));
}

EGW_ATRB_FASTCALL EGWint egwIsPow2ui32(const EGWuint32 val) {
    return val && !(val & (val - 1));
}

EGW_ATRB_FASTCALL EGWint egwIsPow2ui64(const EGWuint64 val) {
    return val && !(val & (val - 1));
}

EGW_ATRB_FASTCALL EGWint egwLCMi(const EGWint val_lhs, const EGWint val_rhs) {
    return val_lhs / egwGCDi(val_lhs, val_rhs) * val_rhs;
}

EGW_ATRB_FASTCALL EGWuint egwLCMui(const EGWuint val_lhs, const EGWuint val_rhs) {
    return val_lhs / egwGCDui(val_lhs, val_rhs) * val_rhs;
}

EGW_ATRB_FASTCALL EGWint egwGCDi(const EGWint val_lhs, const EGWint val_rhs) {
    if(val_rhs == 0) return val_lhs;
    return egwGCDi(val_rhs, val_lhs % val_rhs);
}

EGW_ATRB_FASTCALL EGWuint egwGCDui(const EGWuint val_lhs, const EGWuint val_rhs) {
    if(val_rhs == 0) return val_lhs;
    return egwGCDui(val_rhs, val_lhs % val_rhs);
}

EGWsingle egwDbldf(const EGWsingle val) {
    return val + val;
}

EGWdouble egwDbldd(const EGWdouble val) {
    return val + val;
}

EGWtriple egwDbldt(const EGWtriple val) {
    return val + val;
}

EGWtime egwDbldm(const EGWtime val) {
    return val + val;
}

EGWsingle egwTrplf(const EGWsingle val) {
    return val + val + val;
}

EGWdouble egwTrpld(const EGWdouble val) {
    return val + val + val;
}

EGWtriple egwTrplt(const EGWtriple val) {
    return val + val + val;
}

EGWtime egwTrplm(const EGWtime val) {
    return val + val + val;
}

EGWsingle egwSqrdf(const EGWsingle val) {
    return val * val;
}

EGWdouble egwSqrdd(const EGWdouble val) {
    return val * val;
}

EGWtriple egwSqrdt(const EGWtriple val) {
    return val * val;
}

EGWtime egwSqrdm(const EGWtime val) {
    return val * val;
}

EGWsingle egwSignSqrdf(const EGWsingle val) {
    return (val >= 0.0f ? (val * val) : -(val * val));
}

EGWdouble egwSignSqrdd(const EGWdouble val) {
    return (val >= 0.0 ? (val * val) : -(val * val));
}

EGWtriple egwSignSqrdt(const EGWtriple val) {
    return (val >= (EGWtriple)0.0 ? (val * val) : -(val * val));
}

EGWtime egwSignSqrdm(const EGWtime val) {
    return (val >= (EGWtime)0.0 ? (val * val) : -(val * val));
}

EGWsingle egwCubdf(const EGWsingle val) {
    return val * val * val;
}

EGWdouble egwCubdd(const EGWdouble val) {
    return val * val * val;
}

EGWtriple egwCubdt(const EGWtriple val) {
    return val * val * val;
}

EGWtime egwCubdm(const EGWtime val) {
    return val * val * val;
}

EGWsingle egwDegToRadf(const EGWsingle angle_d) {
    return angle_d * (EGWsingle)EGW_MATH_PI_180;
}

EGWdouble egwDegToRadd(const EGWdouble angle_d) {
    return angle_d * (EGWdouble)EGW_MATH_PI_180;
}

EGWtriple egwDegToRadt(const EGWtriple angle_d) {
    return angle_d * (EGWtriple)EGW_MATH_PI_180;
}

EGWsingle egwRadToDegf(const EGWsingle angle_r) {
    return angle_r * (EGWsingle)EGW_MATH_180_PI;
}

EGWdouble egwRadToDegd(const EGWdouble angle_r) {
    return angle_r * (EGWdouble)EGW_MATH_180_PI;
}

EGWtriple egwRadToDegt(const EGWtriple angle_r) {
    return angle_r * (EGWtriple)EGW_MATH_180_PI;
}

void egwDegToRadfv(const EGWsingle* angle_d_in, EGWsingle* angle_r_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *angle_r_out = *angle_d_in * (EGWsingle)EGW_MATH_PI_180;
        angle_d_in = (const EGWsingle*)((EGWintptr)angle_d_in + (EGWintptr)sizeof(EGWsingle) + strideB_in);
        angle_r_out = (EGWsingle*)((EGWintptr)angle_r_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

void egwDegToRaddv(const EGWdouble* angle_d_in, EGWdouble* angle_r_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *angle_r_out = *angle_d_in * (EGWdouble)EGW_MATH_PI_180;
        angle_d_in = (const EGWdouble*)((EGWintptr)angle_d_in + (EGWintptr)sizeof(EGWdouble) + strideB_in);
        angle_r_out = (EGWdouble*)((EGWintptr)angle_r_out + (EGWintptr)sizeof(EGWdouble) + strideB_out);
    }
}

void egwDegToRadtv(const EGWtriple* angle_d_in, EGWtriple* angle_r_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *angle_r_out = *angle_d_in * (EGWtriple)EGW_MATH_PI_180;
        angle_d_in = (const EGWtriple*)((EGWintptr)angle_d_in + (EGWintptr)sizeof(EGWtriple) + strideB_in);
        angle_r_out = (EGWtriple*)((EGWintptr)angle_r_out + (EGWintptr)sizeof(EGWtriple) + strideB_out);
    }
}

void egwRadToDegfv(const EGWsingle* angle_r_in, EGWsingle* angle_d_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *angle_d_out = *angle_r_in * (EGWsingle)EGW_MATH_180_PI;
        angle_r_in = (const EGWsingle*)((EGWintptr)angle_r_in + (EGWintptr)sizeof(EGWsingle) + strideB_in);
        angle_d_out = (EGWsingle*)((EGWintptr)angle_d_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

void egwRadToDegdv(const EGWdouble* angle_r_in, EGWdouble* angle_d_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *angle_d_out = *angle_r_in * (EGWdouble)EGW_MATH_180_PI;
        angle_r_in = (const EGWdouble*)((EGWintptr)angle_r_in + (EGWintptr)sizeof(EGWdouble) + strideB_in);
        angle_d_out = (EGWdouble*)((EGWintptr)angle_d_out + (EGWintptr)sizeof(EGWdouble) + strideB_out);
    }
}

void egwRadToDegtv(const EGWtriple* angle_r_in, EGWtriple* angle_d_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *angle_d_out = *angle_r_in * (EGWtriple)EGW_MATH_180_PI;
        angle_r_in = (const EGWtriple*)((EGWintptr)angle_r_in + (EGWintptr)sizeof(EGWtriple) + strideB_in);
        angle_d_out = (EGWtriple*)((EGWintptr)angle_d_out + (EGWintptr)sizeof(EGWtriple) + strideB_out);
    }
}

EGWsingle egwRadReduce02PIf(EGWsingle angle_r) {
    while(angle_r >= (EGWsingle)EGW_MATH_2PI) angle_r -= (EGWsingle)EGW_MATH_2PI;
    while(angle_r < (EGWsingle)0.0) angle_r += (EGWsingle)EGW_MATH_2PI;
    return angle_r;
}

EGWdouble egwRadReduce02PId(EGWdouble angle_r) {
    while(angle_r >= (EGWdouble)EGW_MATH_2PI) angle_r -= (EGWdouble)EGW_MATH_2PI;
    while(angle_r < (EGWdouble)0.0) angle_r += (EGWdouble)EGW_MATH_2PI;
    return angle_r;
}

EGWtriple egwRadReduce02PIt(EGWtriple angle_r) {
    while(angle_r >= (EGWtriple)EGW_MATH_2PI) angle_r -= (EGWtriple)EGW_MATH_2PI;
    while(angle_r < (EGWtriple)0.0) angle_r += (EGWtriple)EGW_MATH_2PI;
    return angle_r;
}

EGWsingle egwRadReduceNPIPIf(EGWsingle angle_r) {
    while(angle_r >= (EGWsingle)EGW_MATH_PI) angle_r -= (EGWsingle)EGW_MATH_2PI;
    while(angle_r < (EGWsingle)-EGW_MATH_PI) angle_r += (EGWsingle)EGW_MATH_2PI;
    return angle_r;
}

EGWdouble egwRadReduceNPIPId(EGWdouble angle_r) {
    while(angle_r >= (EGWdouble)EGW_MATH_PI) angle_r -= (EGWdouble)EGW_MATH_2PI;
    while(angle_r < (EGWdouble)-EGW_MATH_PI) angle_r += (EGWdouble)EGW_MATH_2PI;
    return angle_r;
}

EGWtriple egwRadReduceNPIPIt(EGWtriple angle_r) {
    while(angle_r >= (EGWtriple)EGW_MATH_PI) angle_r -= (EGWtriple)EGW_MATH_2PI;
    while(angle_r < (EGWtriple)-EGW_MATH_PI) angle_r += (EGWtriple)EGW_MATH_2PI;
    return angle_r;
}

EGWsingle egwDegReduce0360f(EGWsingle angle_d) {
    while(angle_d >= (EGWsingle)360.0) angle_d -= (EGWsingle)360.0;
    while(angle_d < (EGWsingle)0.0) angle_d += (EGWsingle)360.0;
    return angle_d;
}

EGWdouble egwDegReduce0360d(EGWdouble angle_d) {
    while(angle_d >= (EGWdouble)360.0) angle_d -= (EGWdouble)360.0;
    while(angle_d < (EGWdouble)0.0) angle_d += (EGWdouble)360.0;
    return angle_d;
}

EGWtriple egwDegReduce0360t(EGWtriple angle_d) {
    while(angle_d >= (EGWtriple)360.0) angle_d -= (EGWtriple)360.0;
    while(angle_d < (EGWtriple)0.0) angle_d += (EGWtriple)360.0;
    return angle_d;
}

EGWsingle egwDegReducefN180180f(EGWsingle angle_d) {
    while(angle_d >= (EGWsingle)180.0) angle_d -= (EGWsingle)360.0;
    while(angle_d < (EGWsingle)-180.0) angle_d += (EGWsingle)360.0;
    return angle_d;
}

EGWdouble egwDegReducefN180180d(EGWdouble angle_d) {
    while(angle_d >= (EGWdouble)180.0) angle_d -= (EGWdouble)360.0;
    while(angle_d < (EGWdouble)-180.0) angle_d += (EGWdouble)360.0;
    return angle_d;
}

EGWtriple egwDegReducefN180180t(EGWtriple angle_d) {
    while(angle_d >= (EGWtriple)180.0) angle_d -= (EGWtriple)360.0;
    while(angle_d < (EGWtriple)-180.0) angle_d += (EGWtriple)360.0;
    return angle_d;
}

EGW_ATRB_FASTCALL EGWint egwClampi(const EGWint val, const EGWint clamp_min, const EGWint clamp_max) {
    return (val > clamp_max ? clamp_max : (val < clamp_min ? clamp_min : val));
}

EGW_ATRB_FASTCALL EGWuint egwClampui(const EGWuint val, const EGWuint clamp_min, const EGWuint clamp_max) {
    return (val > clamp_max ? clamp_max : (val < clamp_min ? clamp_min : val));
}

EGWsingle egwClampf(const EGWsingle val, const EGWsingle clamp_min, const EGWsingle clamp_max) {
    return (val >= clamp_max - EGW_SFLT_EPSILON ? clamp_max : (val <= clamp_min + EGW_SFLT_EPSILON ? clamp_min : val));
}

EGWdouble egwClampd(const EGWdouble val, const EGWdouble clamp_min, const EGWdouble clamp_max) {
    return (val >= clamp_max - EGW_DFLT_EPSILON ? clamp_max : (val <= clamp_min + EGW_DFLT_EPSILON ? clamp_min : val));
}

EGWtriple egwClampt(const EGWtriple val, const EGWtriple clamp_min, const EGWtriple clamp_max) {
    return (val >= clamp_max - EGW_TFLT_EPSILON ? clamp_max : (val <= clamp_min + EGW_TFLT_EPSILON ? clamp_min : val));
}

EGWtime egwClampm(const EGWtime val, const EGWtime clamp_min, const EGWtime clamp_max) {
    return (val >= clamp_max - EGW_TIME_EPSILON ? clamp_max : (val <= clamp_min + EGW_TIME_EPSILON ? clamp_min : val));
}

EGW_ATRB_FASTCALL EGWint egwClamp01i(const EGWint val) {
    return (val > 0 ? 1 : 0);
}

EGW_ATRB_FASTCALL EGWuint egwClamp01ui(const EGWuint val) {
    return (val > 0 ? 1 : 0);
}

EGWsingle egwClamp01f(const EGWsingle val) {
    return (val >= 1.0f - EGW_SFLT_EPSILON ? 1.0f : (val <= EGW_SFLT_EPSILON ? 0.0f : val));
}

EGWdouble egwClamp01d(const EGWdouble val) {
    return (val >= 1.0 - EGW_DFLT_EPSILON ? 1.0 : (val <= EGW_DFLT_EPSILON ? 0.0 : val));
}

EGWtriple egwClamp01t(const EGWtriple val) {
    return (val >= (EGWtriple)1.0 - EGW_TFLT_EPSILON ? (EGWtriple)1.0 : (val <= EGW_TFLT_EPSILON ? (EGWtriple)0.0 : val));
}

EGW_ATRB_FASTCALL EGWint egwClamp0255i(const EGWint val) {
    return (val > 255 ? 255 : (val < 0 ? 0 : val));
}

EGW_ATRB_FASTCALL EGWint egwClampPosi(const EGWint val) {
    return (val < 0 ? 0 : val);
}

EGWsingle egwClampPosf(const EGWsingle val) {
    return (val < 0 ? 0 : val);
}

EGW_ATRB_FASTCALL EGWint egwClampNegi(const EGWint val) {
    return (val > 0 ? 0 : val);
}

EGWsingle egwClampNegf(const EGWsingle val) {
    return (val > 0 ? 0 : val);
}

EGW_ATRB_FASTCALL EGWuint egwRoundUpPow2ui(EGWuint val) {
    --val;
    val |= val >> 1;
    val |= val >> 2;
    val |= val >> 4;
    val |= val >> 8;
    val |= val >> 16;
    #ifdef EGW_ARCH_64
    val |= val >> 32;
    #endif
    ++val;
    return val;
}

EGW_ATRB_FASTCALL EGWuint8 egwRoundUpPow2ui8(EGWuint8 val) {
    --val;
    val |= val >> 1;
    val |= val >> 2;
    val |= val >> 4;
    ++val;
    return val;
}

EGW_ATRB_FASTCALL EGWuint16 egwRoundUpPow2ui16(EGWuint16 val) {
    --val;
    val |= val >> 1;
    val |= val >> 2;
    val |= val >> 4;
    val |= val >> 8;
    ++val;
    return val;
}

EGW_ATRB_FASTCALL EGWuint32 egwRoundUpPow2ui32(EGWuint32 val) {
    --val;
    val |= val >> 1;
    val |= val >> 2;
    val |= val >> 4;
    val |= val >> 8;
    val |= val >> 16;
    ++val;
    return val;
}

EGW_ATRB_FASTCALL EGWuint64 egwRoundUpPow2ui64(EGWuint64 val) {
    --val;
    val |= val >> 1;
    val |= val >> 2;
    val |= val >> 4;
    val |= val >> 8;
    val |= val >> 16;
    val |= val >> 32;
    ++val;
    return val;
}

EGW_ATRB_FASTCALL EGWuint egwRoundUpMultipleui(EGWuint val, EGWuint mult) {
    return ((val + (mult - 1)) & (~mult + 1));
}

EGW_ATRB_FASTCALL EGWuint8 egwRoundUpMultipleui8(EGWuint8 val, EGWuint8 mult) {
    return ((val + (mult - 1)) & (~mult + 1));
}

EGW_ATRB_FASTCALL EGWuint16 egwRoundUpMultipleui16(EGWuint16 val, EGWuint16 mult) {
    return ((val + (mult - 1)) & (~mult + 1));
}

EGW_ATRB_FASTCALL EGWuint32 egwRoundUpMultipleui32(EGWuint32 val, EGWuint32 mult) {
    return ((val + (mult - 1)) & (~mult + 1));
}

EGW_ATRB_FASTCALL EGWuint64 egwRoundUpMultipleui64(EGWuint64 val, EGWuint64 mult) {
    return ((val + (mult - 1)) & (~mult + 1));
}

EGW_ATRB_FASTCALL EGWint egwRoundUpMultiplei(EGWint val, EGWint mult) {
    return ((val + (mult - 1)) & -mult);
}

EGW_ATRB_FASTCALL EGWint8 egwRoundUpMultiplei8(EGWint8 val, EGWint8 mult) {
    return ((val + (mult - 1)) & -mult);
}

EGW_ATRB_FASTCALL EGWint16 egwRoundUpMultiplei16(EGWint16 val, EGWint16 mult) {
    return ((val + (mult - 1)) & -mult);
}

EGW_ATRB_FASTCALL EGWint32 egwRoundUpMultiplei32(EGWint32 val, EGWint32 mult) {
    return ((val + (mult - 1)) & -mult);
}

EGW_ATRB_FASTCALL EGWint64 egwRoundUpMultiplei64(EGWint64 val, EGWint64 mult) {
    return ((val + (mult - 1)) & -mult);
}

EGWsingle egwLerpf(const EGWsingle val_src, const EGWsingle val_dst, const EGWsingle alpha) {
    return (val_src * (1.0f - alpha)) + (val_dst * alpha);
}

EGWdouble egwLerpd(const EGWdouble val_src, const EGWdouble val_dst, const EGWdouble alpha) {
    return (val_src * (1.0 - alpha)) + (val_dst * alpha);
}

EGWtriple egwLerpt(const EGWtriple val_src, const EGWtriple val_dst, const EGWtriple alpha) {
    return (val_src * ((EGWtriple)1.0 - alpha)) + (val_dst * alpha);
}

EGWsingle egwBlendf(const EGWsingle val_lhs, const EGWsingle wgt_lhs, const EGWsingle val_rhs, const EGWsingle wgt_rhs) {
    return val_lhs * wgt_lhs + val_rhs * wgt_rhs;
}

EGWdouble egwBlendd(const EGWdouble val_lhs, const EGWdouble wgt_lhs, const EGWdouble val_rhs, const EGWdouble wgt_rhs) {
    return val_lhs * wgt_lhs + val_rhs * wgt_rhs;
}

EGWtriple egwBlendt(const EGWtriple val_lhs, const EGWtriple wgt_lhs, const EGWtriple val_rhs, const EGWtriple wgt_rhs) {
    return val_lhs * wgt_lhs + val_rhs * wgt_rhs;
}

EGWsingle egwSmoothStepf(const EGWsingle val, const EGWsingle edge_lead, const EGWsingle edge_trail) {
    EGWsingle tmp = egwClamp01f((val - edge_lead) / (edge_trail - edge_lead));
    return tmp * tmp * (3.0f - (tmp + tmp));
}

EGWdouble egwSmoothStepd(const EGWdouble val, const EGWdouble edge_lead, const EGWdouble edge_trail) {
    EGWdouble tmp = egwClamp01d((val - edge_lead) / (edge_trail - edge_lead));
    return tmp * tmp * (3.0 - (tmp + tmp));
}

EGWtriple egwSmoothStept(const EGWtriple val, const EGWtriple edge_lead, const EGWtriple edge_trail) {
    EGWtriple tmp = egwClamp01t((val - edge_lead) / (edge_trail - edge_lead));
    return tmp * tmp * ((EGWtriple)3.0 - (tmp + tmp));
}

EGWsingle egwFastInvSqrtf(const EGWsingle val) {
    register union {
		EGWsingle f;
		EGWuint32 i;
	} tmp;
	tmp.f = val;
    tmp.i = 0x5f3759df - (tmp.i >> 1);
	return tmp.f * (1.5f - (0.5f * val * tmp.f * tmp.f));
}

EGWsingle egwFastSinf(const EGWsingle angle_r) {
    register EGWsingle sigma = egwRadReduceNPIPIf(angle_r);
    sigma = ((4.0f/EGW_MATH_PI) * sigma) + ((-4.0f/(EGW_MATH_PI*EGW_MATH_PI)) * sigma * fabsf(sigma));
    return (0.225f * ((sigma * fabsf(sigma)) - sigma)) + sigma; // Extra precision
}

EGWsingle egwFasterSinf(const EGWsingle angle_r) {
    register EGWsingle sigma = ((4.0f/EGW_MATH_PI) * angle_r) + ((-4.0f/(EGW_MATH_PI*EGW_MATH_PI)) * angle_r * fabsf(angle_r));
    return (0.225f * ((sigma * fabsf(sigma)) - sigma)) + sigma; // Extra precision
}

EGWsingle egwFastestSinf(const EGWsingle angle_r) {
    return ((4.0f/EGW_MATH_PI) * angle_r) + ((-4.0f/(EGW_MATH_PI*EGW_MATH_PI)) * angle_r * fabsf(angle_r));
}

EGWsingle egwFastCosf(const EGWsingle angle_r) {
    return egwFasterSinf(egwRadReduceNPIPIf(angle_r + EGW_MATH_PI_2));
}

EGWsingle egwFastTanf(const EGWsingle angle_r) {
    return egwFasterSinf(egwRadReduceNPIPIf(angle_r)) / egwFasterSinf(egwRadReduceNPIPIf(angle_r + EGW_MATH_PI_2));
}

EGWsingle egwFastArcSinf(const EGWsingle val) {
    register EGWsingle dblVal = val * val;
	return val * (1.0f + dblVal * (0.166667f + dblVal * (0.075f + dblVal * (0.044643f + dblVal*(0.030382f + dblVal * 0.022372f)))));

}

EGWsingle egwFastArcCosf(const EGWsingle val) {
    register EGWsingle valSqrd = val * val;
    register EGWsingle valCubd = val * valSqrd;
    return (-0.0232f * (valCubd * val)) - (0.43895f * valCubd) + (0.0053f * valSqrd) - (0.93773f * val) + 1.5708f;
}

EGWsingle egwFastArcTan2f(const EGWtriple val_nmr, const EGWtriple val_dnm) {
    register EGWsingle absNmr = egwAbsf(val_nmr) + EGW_SFLT_EPSILON; // Kludge to prevent 0/0 condition
    register EGWsingle angle = (val_dnm >= 0.0f ? EGW_MATH_PI_4 - EGW_MATH_PI_4 * ((val_dnm - absNmr) / (val_dnm + absNmr)) :
                                                  (3.0f * EGW_MATH_PI_4) - EGW_MATH_PI_4 * ((val_dnm + absNmr) / (absNmr - val_dnm)) );
    return (val_nmr >= 0.0f ? angle : -angle);
}

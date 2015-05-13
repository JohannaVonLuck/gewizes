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

/// @file egwVector.m
/// @ingroup geWizES_math_vector
/// Vector Implementation.

#import "egwVector.h"
#import "egwMath.h"


const egwVector2f egwSIVecZero2f =        {0.0f, 0.0f};
const egwVector3f egwSIVecZero3f =        {0.0f, 0.0f, 0.0f};
const egwVector4f egwSIVecZero4f =        {0.0f, 0.0f, 0.0f, 0.0f};
const egwVector2f egwSIVecOne2f =         {1.0f, 1.0f};
const egwVector3f egwSIVecOne3f =         {1.0f, 1.0f, 1.0f};
const egwVector4f egwSIVecOne4f =         {1.0f, 1.0f, 1.0f, 1.0f};
const egwVector2f egwSIVecUnitX2f =       {1.0f, 0.0f};
const egwVector3f egwSIVecUnitX3f =       {1.0f, 0.0f, 0.0f};
const egwVector4f egwSIVecUnitX4f =       {1.0f, 0.0f, 0.0f, 0.0f};
const egwVector2f egwSIVecUnitY2f =       {0.0f, 1.0f};
const egwVector3f egwSIVecUnitY3f =       {0.0f, 1.0f, 0.0f};
const egwVector4f egwSIVecUnitY4f =       {0.0f, 1.0f, 0.0f, 0.0f};
const egwVector3f egwSIVecUnitZ3f =       {0.0f, 0.0f, 1.0f};
const egwVector4f egwSIVecUnitZ4f =       {0.0f, 0.0f, 1.0f, 0.0f};
const egwVector4f egwSIVecUnitW4f =       {0.0f, 0.0f, 0.0f, 1.0f};
const egwVector2f egwSIVecNegUnitX2f =    {-1.0f, 0.0f};
const egwVector3f egwSIVecNegUnitX3f =    {-1.0f, 0.0f, 0.0f};
const egwVector4f egwSIVecNegUnitX4f =    {-1.0f, 0.0f, 0.0f, 0.0f};
const egwVector2f egwSIVecNegUnitY2f =    {0.0f, -1.0f};
const egwVector3f egwSIVecNegUnitY3f =    {0.0f, -1.0f, 0.0f};
const egwVector4f egwSIVecNegUnitY4f =    {0.0f, -1.0f, 0.0f, 0.0f};
const egwVector3f egwSIVecNegUnitZ3f =    {0.0f, 0.0f, -1.0f};
const egwVector4f egwSIVecNegUnitZ4f =    {0.0f, 0.0f, -1.0f, 0.0f};
const egwVector4f egwSIVecNegUnitW4f =    {0.0f, 0.0f, 0.0f, -1.0f};


egwVector2f* egwVecInit2f(egwVector2f* vec_out, const EGWsingle x, const EGWsingle y) {
    vec_out->axis.x = x;
    vec_out->axis.y = y;
    return vec_out;
}

egwVector3f* egwVecInit3f(egwVector3f* vec_out, const EGWsingle x, const EGWsingle y, const EGWsingle z) {
    vec_out->axis.x = x;
    vec_out->axis.y = y;
    vec_out->axis.z = z;
    return vec_out;
}

egwVector4f* egwVecInit4f(egwVector4f* vec_out, const EGWsingle x, const EGWsingle y, const EGWsingle z, const EGWsingle w) {
    vec_out->axis.x = x;
    vec_out->axis.y = y;
    vec_out->axis.z = z;
    vec_out->axis.w = w;
    return vec_out;
}

void egwVecInit2fv(egwVector2f* vecs_out, const EGWsingle x, const EGWsingle y, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        vecs_out->axis.x = x;
        vecs_out->axis.y = y;
        vecs_out = (egwVector2f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector2f) + strideB_out);
    }
}

void egwVecInit3fv(egwVector3f* vecs_out, const EGWsingle x, const EGWsingle y, const EGWsingle z, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        vecs_out->axis.x = x;
        vecs_out->axis.y = y;
        vecs_out->axis.z = z;
        vecs_out = (egwVector3f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector3f) + strideB_out);
    }
}

void egwVecInit4fv(egwVector4f* vecs_out, const EGWsingle x, const EGWsingle y, const EGWsingle z, const EGWsingle w, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        vecs_out->axis.x = x;
        vecs_out->axis.y = y;
        vecs_out->axis.z = z;
        vecs_out->axis.w = w;
        vecs_out = (egwVector4f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector4f) + strideB_out);
    }
}

egwVector2f* egwVecCopy2f(const egwVector2f* vec_in, egwVector2f* vec_out) {
    vec_out->axis.x = vec_in->axis.x;
    vec_out->axis.y = vec_in->axis.y;
    return vec_out;
}

egwVector3f* egwVecCopy3f(const egwVector3f* vec_in, egwVector3f* vec_out) {
    vec_out->axis.x = vec_in->axis.x;
    vec_out->axis.y = vec_in->axis.y;
    vec_out->axis.z = vec_in->axis.z;
    return vec_out;
}

egwVector4f* egwVecCopy4f(const egwVector4f* vec_in, egwVector4f* vec_out) {
    vec_out->axis.x = vec_in->axis.x;
    vec_out->axis.y = vec_in->axis.y;
    vec_out->axis.z = vec_in->axis.z;
    vec_out->axis.w = vec_in->axis.w;
    return vec_out;
}

void egwVecCopy2fv(const egwVector2f* vecs_in, egwVector2f* vecs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        vecs_out->axis.x = vecs_in->axis.x;
        vecs_out->axis.y = vecs_in->axis.y;
        vecs_in = (const egwVector2f*)((EGWintptr)vecs_in + (EGWintptr)sizeof(egwVector2f) + strideB_in);
        vecs_out = (egwVector2f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector2f) + strideB_out);
    }
}

void egwVecCopy3fv(const egwVector3f* vecs_in, egwVector3f* vecs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        vecs_out->axis.x = vecs_in->axis.x;
        vecs_out->axis.y = vecs_in->axis.y;
        vecs_out->axis.z = vecs_in->axis.z;
        vecs_in = (const egwVector3f*)((EGWintptr)vecs_in + (EGWintptr)sizeof(egwVector3f) + strideB_in);
        vecs_out = (egwVector3f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector3f) + strideB_out);
    }
}

void egwVecCopy4fv(const egwVector4f* vecs_in, egwVector4f* vecs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        vecs_out->axis.x = vecs_in->axis.x;
        vecs_out->axis.y = vecs_in->axis.y;
        vecs_out->axis.z = vecs_in->axis.z;
        vecs_out->axis.w = vecs_in->axis.w;
        vecs_in = (const egwVector4f*)((EGWintptr)vecs_in + (EGWintptr)sizeof(egwVector4f) + strideB_in);
        vecs_out = (egwVector4f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector4f) + strideB_out);
    }
}

EGWint egwVecIsEqual2f(const egwVector2f* vec_lhs, const egwVector2f* vec_rhs) {
    return ((vec_lhs == vec_rhs) || (egwIsEqualf(vec_lhs->axis.x, vec_rhs->axis.x) && egwIsEqualf(vec_lhs->axis.y, vec_rhs->axis.y)) ? 1 : 0);
}

EGWint egwVecIsEqual3f(const egwVector3f* vec_lhs, const egwVector3f* vec_rhs) {
    return ((vec_lhs == vec_rhs) || (egwIsEqualf(vec_lhs->axis.x, vec_rhs->axis.x) && egwIsEqualf(vec_lhs->axis.y, vec_rhs->axis.y) && egwIsEqualf(vec_lhs->axis.z, vec_rhs->axis.z)) ? 1 : 0);
}

EGWint egwVecIsEqual4f(const egwVector4f* vec_lhs, const egwVector4f* vec_rhs) {
    return ((vec_lhs == vec_rhs) || (egwIsEqualf(vec_lhs->axis.x, vec_rhs->axis.x) && egwIsEqualf(vec_lhs->axis.y, vec_rhs->axis.y) && egwIsEqualf(vec_lhs->axis.z, vec_rhs->axis.z) && egwIsEqualf(vec_lhs->axis.w, vec_rhs->axis.w)) ? 1 : 0);
}

EGWint egwVecIsPointVec2f(const egwVector3f* vec_in) {
    return (egwIsOnef(vec_in->axis.z) ? 1 : 0);
}

EGWint egwVecIsPointVec3f(const egwVector4f* vec_in) {
    return (egwIsOnef(vec_in->axis.w) ? 1 : 0);
}

EGWint egwVecIsDirectionVec2f(const egwVector3f* vec_in) {
    return (egwIsZerof(vec_in->axis.z) ? 1 : 0);
}

EGWint egwVecIsDirectionVec3f(const egwVector4f* vec_in) {
    return (egwIsZerof(vec_in->axis.w) ? 1 : 0);
}


EGWsingle egwVecDotProd2f(const egwVector2f* vec_lhs, const egwVector2f* vec_rhs) {
    return (vec_lhs->axis.x * vec_rhs->axis.x) + (vec_lhs->axis.y * vec_rhs->axis.y);
}

EGWsingle egwVecDotProd3f(const egwVector3f* vec_lhs, const egwVector3f* vec_rhs) {
    return (vec_lhs->axis.x * vec_rhs->axis.x) + (vec_lhs->axis.y * vec_rhs->axis.y) + (vec_lhs->axis.z * vec_rhs->axis.z);
}

void egwVecDotProd2fv(const egwVector2f* vecs_lhs, const egwVector2f* vecs_rhs, EGWsingle* dtps_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *dtps_out = (vecs_lhs->axis.x * vecs_rhs->axis.x) + (vecs_lhs->axis.y * vecs_rhs->axis.y);
        vecs_lhs = (const egwVector2f*)((EGWintptr)vecs_lhs + (EGWintptr)sizeof(egwVector2f) + strideB_lhs);
        vecs_rhs = (const egwVector2f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector2f) + strideB_rhs);
        dtps_out = (EGWsingle*)((EGWintptr)dtps_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

void egwVecDotProd3fv(const egwVector3f* vecs_lhs, const egwVector3f* vecs_rhs, EGWsingle* dtps_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *dtps_out = (vecs_lhs->axis.x * vecs_rhs->axis.x) + (vecs_lhs->axis.y * vecs_rhs->axis.y) + (vecs_lhs->axis.z * vecs_rhs->axis.z);
        vecs_lhs = (const egwVector3f*)((EGWintptr)vecs_lhs + (EGWintptr)sizeof(egwVector3f) + strideB_lhs);
        vecs_rhs = (const egwVector3f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector3f) + strideB_rhs);
        dtps_out = (EGWsingle*)((EGWintptr)dtps_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

EGWsingle egwVecCrossProd2f(const egwVector2f* vec_lhs, const egwVector2f* vec_rhs) {
    return (vec_lhs->axis.x * vec_rhs->axis.y) - (vec_lhs->axis.y * vec_rhs->axis.x);
}

egwVector3f* egwVecCrossProd3f(const egwVector3f* vec_lhs, const egwVector3f* vec_rhs, egwVector3f* vec_out) {
    if(vec_lhs != vec_out && vec_rhs != vec_out) {
        vec_out->axis.x = (vec_lhs->axis.y * vec_rhs->axis.z) - (vec_lhs->axis.z * vec_rhs->axis.y);
        vec_out->axis.y = (vec_lhs->axis.z * vec_rhs->axis.x) - (vec_lhs->axis.x * vec_rhs->axis.z);
        vec_out->axis.z = (vec_lhs->axis.x * vec_rhs->axis.y) - (vec_lhs->axis.y * vec_rhs->axis.x);
    } else {
        egwVector3f temp;
        temp.axis.x = (vec_lhs->axis.y * vec_rhs->axis.z) - (vec_lhs->axis.z * vec_rhs->axis.y);
        temp.axis.y = (vec_lhs->axis.z * vec_rhs->axis.x) - (vec_lhs->axis.x * vec_rhs->axis.z);
        temp.axis.z = (vec_lhs->axis.x * vec_rhs->axis.y) - (vec_lhs->axis.y * vec_rhs->axis.x);
        vec_out->axis.x = temp.axis.x;
        vec_out->axis.y = temp.axis.y;
        vec_out->axis.z = temp.axis.z;
    }
    
    return vec_out;
}

void egwVecCrossProd2fv(const egwVector2f* vecs_lhs, const egwVector2f* vecs_rhs, EGWsingle* crps_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *crps_out = (vecs_lhs->axis.x * vecs_rhs->axis.y) - (vecs_lhs->axis.y * vecs_rhs->axis.x);
        vecs_lhs = (const egwVector2f*)((EGWintptr)vecs_lhs + (EGWintptr)sizeof(egwVector2f) + strideB_lhs);
        vecs_rhs = (const egwVector2f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector2f) + strideB_rhs);
        crps_out = (EGWsingle*)((EGWintptr)crps_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

void egwVecCrossProd3fv(const egwVector3f* vecs_lhs, const egwVector3f* vecs_rhs, egwVector3f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    egwVector3f temp;
    while(count--) {
        temp.axis.x = (vecs_lhs->axis.y * vecs_rhs->axis.z) - (vecs_lhs->axis.z * vecs_rhs->axis.y);
        temp.axis.y = (vecs_lhs->axis.z * vecs_rhs->axis.x) - (vecs_lhs->axis.x * vecs_rhs->axis.z);
        temp.axis.z = (vecs_lhs->axis.x * vecs_rhs->axis.y) - (vecs_lhs->axis.y * vecs_rhs->axis.x);
        vecs_out->axis.x = temp.axis.x;
        vecs_out->axis.y = temp.axis.y;
        vecs_out->axis.z = temp.axis.z;
        vecs_lhs = (const egwVector3f*)((EGWintptr)vecs_lhs + (EGWintptr)sizeof(egwVector3f) + strideB_lhs);
        vecs_rhs = (const egwVector3f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector3f) + strideB_rhs);
        vecs_out = (egwVector3f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector3f) + strideB_out);
    }
}

EGWsingle egwVecAngleBtwn2f(const egwVector2f* vec_lhs, const egwVector2f* vec_rhs) {
    register EGWsingle magSqrdLhs = egwVecMagnitudeSqrd2f(vec_lhs);
    register EGWsingle magSqrdRhs = egwVecMagnitudeSqrd2f(vec_rhs);
    if(egwIsOnef(magSqrdLhs) && egwIsOnef(magSqrdRhs))
        return egwArcCosf(egwVecDotProd2f(vec_lhs, vec_rhs));
    else
        return egwArcCosf(egwVecDotProd2f(vec_lhs, vec_rhs)) * egwInvSqrtf(magSqrdLhs * magSqrdRhs);
}

EGWsingle egwVecAngleBtwn3f(const egwVector3f* vec_lhs, const egwVector3f* vec_rhs) {
    register EGWsingle magSqrdLhs = egwVecMagnitudeSqrd3f(vec_lhs);
    register EGWsingle magSqrdRhs = egwVecMagnitudeSqrd3f(vec_rhs);
    if(egwIsOnef(magSqrdLhs) && egwIsOnef(magSqrdRhs))
        return egwArcCosf(egwVecDotProd3f(vec_lhs, vec_rhs));
    else
        return egwArcCosf(egwVecDotProd3f(vec_lhs, vec_rhs)) * egwInvSqrtf(magSqrdLhs * magSqrdRhs);
}

void egwVecAngleBtwn2fv(const egwVector2f* vecs_lhs, const egwVector2f* vecs_rhs, EGWsingle* angles_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        register EGWsingle magSqrdLhs = egwVecMagnitudeSqrd2f(vecs_lhs);
        register EGWsingle magSqrdRhs = egwVecMagnitudeSqrd2f(vecs_rhs);
        if(egwIsOnef(magSqrdLhs) && egwIsOnef(magSqrdRhs))
            *angles_out = egwArcCosf(egwVecDotProd2f(vecs_lhs, vecs_rhs));
        else
            *angles_out = egwArcCosf(egwVecDotProd2f(vecs_lhs, vecs_rhs)) * egwInvSqrtf(magSqrdLhs * magSqrdRhs);
        vecs_lhs = (const egwVector2f*)((EGWintptr)vecs_lhs + (EGWintptr)sizeof(egwVector2f) + strideB_lhs);
        vecs_rhs = (const egwVector2f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector2f) + strideB_rhs);
        angles_out = (EGWsingle*)((EGWintptr)angles_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

void egwVecAngleBtwn3fv(const egwVector3f* vecs_lhs, const egwVector3f* vecs_rhs, EGWsingle* angles_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        register EGWsingle magSqrdLhs = egwVecMagnitudeSqrd3f(vecs_lhs);
        register EGWsingle magSqrdRhs = egwVecMagnitudeSqrd3f(vecs_rhs);
        if(egwIsOnef(magSqrdLhs) && egwIsOnef(magSqrdRhs))
            *angles_out = egwArcCosf(egwVecDotProd3f(vecs_lhs, vecs_rhs));
        else
            *angles_out = egwArcCosf(egwVecDotProd3f(vecs_lhs, vecs_rhs)) * egwInvSqrtf(magSqrdLhs * magSqrdRhs);
        vecs_lhs = (const egwVector3f*)((EGWintptr)vecs_lhs + (EGWintptr)sizeof(egwVector3f) + strideB_lhs);
        vecs_rhs = (const egwVector3f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector3f) + strideB_rhs);
        angles_out = (EGWsingle*)((EGWintptr)angles_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

EGWsingle egwVecFastAngleBtwn2f(const egwVector2f* vec_lhs, const egwVector2f* vec_rhs) {
    register EGWsingle magSqrdLhs = egwVecMagnitudeSqrd2f(vec_lhs);
    register EGWsingle magSqrdRhs = egwVecMagnitudeSqrd2f(vec_rhs);
    if(egwIsOnef(magSqrdLhs) && egwIsOnef(magSqrdRhs))
        return egwFastArcCosf(egwVecDotProd2f(vec_lhs, vec_rhs));
    else
        return egwFastArcCosf(egwVecDotProd2f(vec_lhs, vec_rhs)) * egwFastInvSqrtf(magSqrdLhs * magSqrdRhs);
}

EGWsingle egwVecFastAngleBtwn3f(const egwVector3f* vec_lhs, const egwVector3f* vec_rhs) {
    register EGWsingle magSqrdLhs = egwVecMagnitudeSqrd3f(vec_lhs);
    register EGWsingle magSqrdRhs = egwVecMagnitudeSqrd3f(vec_rhs);
    if(egwIsOnef(magSqrdLhs) && egwIsOnef(magSqrdRhs))
        return egwFastArcCosf(egwVecDotProd3f(vec_lhs, vec_rhs));
    else
        return egwFastArcCosf(egwVecDotProd3f(vec_lhs, vec_rhs)) * egwFastInvSqrtf(magSqrdLhs * magSqrdRhs);
}

void egwVecFastAngleBtwn2fv(const egwVector2f* vecs_lhs, const egwVector2f* vecs_rhs, EGWsingle* angles_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        register EGWsingle magSqrdLhs = egwVecMagnitudeSqrd2f(vecs_lhs);
        register EGWsingle magSqrdRhs = egwVecMagnitudeSqrd2f(vecs_rhs);
        if(egwIsOnef(magSqrdLhs) && egwIsOnef(magSqrdRhs))
            *angles_out = egwFastArcCosf(egwVecDotProd2f(vecs_lhs, vecs_rhs));
        else
            *angles_out = egwFastArcCosf(egwVecDotProd2f(vecs_lhs, vecs_rhs)) * egwFastInvSqrtf(magSqrdLhs * magSqrdRhs);
        vecs_lhs = (const egwVector2f*)((EGWintptr)vecs_lhs + (EGWintptr)sizeof(egwVector2f) + strideB_lhs);
        vecs_rhs = (const egwVector2f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector2f) + strideB_rhs);
        angles_out = (EGWsingle*)((EGWintptr)angles_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

void egwVecFastAngleBtwn3fv(const egwVector3f* vecs_lhs, const egwVector3f* vecs_rhs, EGWsingle* angles_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        register EGWsingle magSqrdLhs = egwVecMagnitudeSqrd3f(vecs_lhs);
        register EGWsingle magSqrdRhs = egwVecMagnitudeSqrd3f(vecs_rhs);
        if(egwIsOnef(magSqrdLhs) && egwIsOnef(magSqrdRhs))
            *angles_out = egwFastArcCosf(egwVecDotProd3f(vecs_lhs, vecs_rhs));
        else
            *angles_out = egwFastArcCosf(egwVecDotProd3f(vecs_lhs, vecs_rhs)) * egwFastInvSqrtf(magSqrdLhs * magSqrdRhs);
        vecs_lhs = (const egwVector3f*)((EGWintptr)vecs_lhs + (EGWintptr)sizeof(egwVector3f) + strideB_lhs);
        vecs_rhs = (const egwVector3f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector3f) + strideB_rhs);
        angles_out = (EGWsingle*)((EGWintptr)angles_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

EGWsingle egwVecMagnitude2f(const egwVector2f* vec_in) {
    return egwSqrtf((vec_in->axis.x * vec_in->axis.x) + (vec_in->axis.y * vec_in->axis.y));
}

EGWsingle egwVecMagnitude3f(const egwVector3f* vec_in) {
    return egwSqrtf((vec_in->axis.x * vec_in->axis.x) + (vec_in->axis.y * vec_in->axis.y) + (vec_in->axis.z * vec_in->axis.z));
}

void egwVecMagnitude2fv(const egwVector2f* vecs_in, EGWsingle* mags_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *mags_out = egwSqrtf((vecs_in->axis.x * vecs_in->axis.x) + (vecs_in->axis.y * vecs_in->axis.y));
        vecs_in = (const egwVector2f*)((EGWintptr)vecs_in + (EGWintptr)sizeof(egwVector2f) + strideB_in);
        mags_out = (EGWsingle*)((EGWintptr)mags_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

void egwVecMagnitude3fv(const egwVector3f* vecs_in, EGWsingle* mags_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *mags_out = egwSqrtf((vecs_in->axis.x * vecs_in->axis.x) + (vecs_in->axis.y * vecs_in->axis.y) + (vecs_in->axis.z * vecs_in->axis.z));
        vecs_in = (const egwVector3f*)((EGWintptr)vecs_in + (EGWintptr)sizeof(egwVector3f) + strideB_in);
        mags_out = (EGWsingle*)((EGWintptr)mags_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

EGWsingle egwVecFastMagnitude2f(const egwVector2f* vec_in) {
    return 1.0f / egwFastInvSqrtf((vec_in->axis.x * vec_in->axis.x) + (vec_in->axis.y * vec_in->axis.y));
}

EGWsingle egwVecFastMagnitude3f(const egwVector3f* vec_in) {
    return 1.0f / egwFastInvSqrtf((vec_in->axis.x * vec_in->axis.x) + (vec_in->axis.y * vec_in->axis.y) + (vec_in->axis.z * vec_in->axis.z));
}

void egwVecFastMagnitude2fv(const egwVector2f* vecs_in, EGWsingle* mags_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *mags_out = 1.0f / egwFastInvSqrtf((vecs_in->axis.x * vecs_in->axis.x) + (vecs_in->axis.y * vecs_in->axis.y));
        vecs_in = (const egwVector2f*)((EGWintptr)vecs_in + (EGWintptr)sizeof(egwVector2f) + strideB_in);
        mags_out = (EGWsingle*)((EGWintptr)mags_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

void egwVecFastMagnitude3fv(const egwVector3f* vecs_in, EGWsingle* mags_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *mags_out = 1.0f / egwFastInvSqrtf((vecs_in->axis.x * vecs_in->axis.x) + (vecs_in->axis.y * vecs_in->axis.y) + (vecs_in->axis.z * vecs_in->axis.z));
        vecs_in = (const egwVector3f*)((EGWintptr)vecs_in + (EGWintptr)sizeof(egwVector3f) + strideB_in);
        mags_out = (EGWsingle*)((EGWintptr)mags_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

EGWsingle egwVecMagnitudeSqrd2f(const egwVector2f* vec_in) {
    return (vec_in->axis.x * vec_in->axis.x) + (vec_in->axis.y * vec_in->axis.y);
}

EGWsingle egwVecMagnitudeSqrd3f(const egwVector3f* vec_in) {
    return (vec_in->axis.x * vec_in->axis.x) + (vec_in->axis.y * vec_in->axis.y) + (vec_in->axis.z * vec_in->axis.z);
}

void egwVecMagnitudeSqrd2fv(const egwVector2f* vecs_in, EGWsingle* mags_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *mags_out = (vecs_in->axis.x * vecs_in->axis.x) + (vecs_in->axis.y * vecs_in->axis.y);
        vecs_in = (const egwVector2f*)((EGWintptr)vecs_in + (EGWintptr)sizeof(egwVector2f) + strideB_in);
        mags_out = (EGWsingle*)((EGWintptr)mags_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

void egwVecMagnitudeSqrd3fv(const egwVector3f* vecs_in, EGWsingle* mags_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *mags_out = (vecs_in->axis.x * vecs_in->axis.x) + (vecs_in->axis.y * vecs_in->axis.y) + (vecs_in->axis.z * vecs_in->axis.z);
        vecs_in = (const egwVector3f*)((EGWintptr)vecs_in + (EGWintptr)sizeof(egwVector3f) + strideB_in);
        mags_out = (EGWsingle*)((EGWintptr)mags_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

egwVector2f* egwVecNormalize2f(const egwVector2f* vec_in, egwVector2f* vec_out) {
    EGWsingle factor = egwInvSqrtf((vec_in->axis.x * vec_in->axis.x) + (vec_in->axis.y * vec_in->axis.y));
    vec_out->axis.x = vec_in->axis.x * factor;
    vec_out->axis.y = vec_in->axis.y * factor;
    return vec_out;
}

egwVector3f* egwVecNormalize3f(const egwVector3f* vec_in, egwVector3f* vec_out) {
    EGWsingle factor = egwInvSqrtf((vec_in->axis.x * vec_in->axis.x) + (vec_in->axis.y * vec_in->axis.y) + (vec_in->axis.z * vec_in->axis.z));
    vec_out->axis.x = vec_in->axis.x * factor;
    vec_out->axis.y = vec_in->axis.y * factor;
    vec_out->axis.z = vec_in->axis.z * factor;
    return vec_out;
}

void egwVecNormalize2fv(const egwVector2f* vecs_in, egwVector2f* vecs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    EGWsingle factor;
    while(count--) {
        factor = egwInvSqrtf((vecs_in->axis.x * vecs_in->axis.x) + (vecs_in->axis.y * vecs_in->axis.y));
        vecs_out->axis.x = vecs_in->axis.x * factor;
        vecs_out->axis.y = vecs_in->axis.y * factor;
        vecs_in = (const egwVector2f*)((EGWintptr)vecs_in + (EGWintptr)sizeof(egwVector2f) + strideB_in);
        vecs_out = (egwVector2f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector2f) + strideB_out);
    }
}

void egwVecNormalize3fv(const egwVector3f* vecs_in, egwVector3f* vecs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    EGWsingle factor;
    while(count--) {
        factor = egwInvSqrtf((vecs_in->axis.x * vecs_in->axis.x) + (vecs_in->axis.y * vecs_in->axis.y) + (vecs_in->axis.z * vecs_in->axis.z));
        vecs_out->axis.x = vecs_in->axis.x * factor;
        vecs_out->axis.y = vecs_in->axis.y * factor;
        vecs_out->axis.z = vecs_in->axis.z * factor;
        vecs_in = (const egwVector3f*)((EGWintptr)vecs_in + (EGWintptr)sizeof(egwVector3f) + strideB_in);
        vecs_out = (egwVector3f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector3f) + strideB_out);
    }
}

egwVector2f* egwVecNormalizeMag2f(const egwVector2f* vec_lhs, const EGWsingle mag_rhs, egwVector2f* vec_out) {
    EGWsingle factor = 1.0f / mag_rhs;
    vec_out->axis.x = vec_lhs->axis.x * factor;
    vec_out->axis.y = vec_lhs->axis.y * factor;
    return vec_out;
}

egwVector3f* egwVecNormalizeMag3f(const egwVector3f* vec_lhs, const EGWsingle mag_rhs, egwVector3f* vec_out) {
    EGWsingle factor = 1.0f / mag_rhs;
    vec_out->axis.x = vec_lhs->axis.x * factor;
    vec_out->axis.y = vec_lhs->axis.y * factor;
    vec_out->axis.z = vec_lhs->axis.z * factor;
    return vec_out;
}

void egwVecNormalizeMag2fv(const egwVector2f* vecs_lhs, const EGWsingle* mags_rhs, egwVector2f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    EGWsingle factor;
    while(count--) {
        factor = 1.0f / *mags_rhs;
        vecs_out->axis.x = vecs_lhs->axis.x * factor;
        vecs_out->axis.y = vecs_lhs->axis.y * factor;
        vecs_lhs = (const egwVector2f*)((EGWintptr)vecs_lhs + (EGWintptr)sizeof(egwVector2f) + strideB_lhs);
        mags_rhs = (const  EGWsingle*)((EGWintptr)mags_rhs + (EGWintptr)sizeof(EGWsingle) + strideB_rhs);
        vecs_out = (egwVector2f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector2f) + strideB_out);
    }
}

void egwVecNormalizeMag3fv(const egwVector3f* vecs_lhs, const EGWsingle* mags_rhs, egwVector3f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    EGWsingle factor;
    while(count--) {
        factor = 1.0f / *mags_rhs;
        vecs_out->axis.x = vecs_lhs->axis.x * factor;
        vecs_out->axis.y = vecs_lhs->axis.y * factor;
        vecs_out->axis.z = vecs_lhs->axis.z * factor;
        vecs_lhs = (const egwVector3f*)((EGWintptr)vecs_lhs + (EGWintptr)sizeof(egwVector3f) + strideB_lhs);
        mags_rhs = (const EGWsingle*)((EGWintptr)mags_rhs + (EGWintptr)sizeof(EGWsingle) + strideB_rhs);
        vecs_out = (egwVector3f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector3f) + strideB_out);
    }
}

egwVector2f* egwVecFastNormalize2f(const egwVector2f* vec_in, egwVector2f* vec_out) {
    EGWsingle factor = egwFastInvSqrtf((vec_in->axis.x * vec_in->axis.x) + (vec_in->axis.y * vec_in->axis.y));
    vec_out->axis.x = vec_in->axis.x * factor;
    vec_out->axis.y = vec_in->axis.y * factor;
    return vec_out;
}

egwVector3f* egwVecFastNormalize3f(const egwVector3f* vec_in, egwVector3f* vec_out) {
    EGWsingle factor = egwFastInvSqrtf((vec_in->axis.x * vec_in->axis.x) + (vec_in->axis.y * vec_in->axis.y) + (vec_in->axis.z * vec_in->axis.z));
    vec_out->axis.x = vec_in->axis.x * factor;
    vec_out->axis.y = vec_in->axis.y * factor;
    vec_out->axis.z = vec_in->axis.z * factor;
    return vec_out;
}

void egwVecFastNormalize2fv(const egwVector2f* vecs_in, egwVector2f* vecs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    EGWsingle factor;
    while(count--) {
        factor = egwFastInvSqrtf((vecs_in->axis.x * vecs_in->axis.x) + (vecs_in->axis.y * vecs_in->axis.y));
        vecs_out->axis.x = vecs_in->axis.x * factor;
        vecs_out->axis.y = vecs_in->axis.y * factor;
        vecs_in = (const egwVector2f*)((EGWintptr)vecs_in + (EGWintptr)sizeof(egwVector2f) + strideB_in);
        vecs_out = (egwVector2f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector2f) + strideB_out);
    }
}

void egwVecFastNormalize3fv(const egwVector3f* vecs_in, egwVector3f* vecs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    EGWsingle factor;
    while(count--) {
        factor = egwFastInvSqrtf((vecs_in->axis.x * vecs_in->axis.x) + (vecs_in->axis.y * vecs_in->axis.y) + (vecs_in->axis.z * vecs_in->axis.z));
        vecs_out->axis.x = vecs_in->axis.x * factor;
        vecs_out->axis.y = vecs_in->axis.y * factor;
        vecs_out->axis.z = vecs_in->axis.z * factor;
        vecs_in = (const egwVector3f*)((EGWintptr)vecs_in + (EGWintptr)sizeof(egwVector3f) + strideB_in);
        vecs_out = (egwVector3f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector3f) + strideB_out);
    }
}

EGWsingle egwVecDistance2f(const egwVector2f* vec_lhs, const egwVector2f* vec_rhs) {
    return egwSqrtf(((vec_rhs->axis.x - vec_lhs->axis.x) * (vec_rhs->axis.x - vec_lhs->axis.x)) +
                    ((vec_rhs->axis.y - vec_lhs->axis.y) * (vec_rhs->axis.y - vec_lhs->axis.y)));
}

EGWsingle egwVecDistance3f(const egwVector3f* vec_lhs, const egwVector3f* vec_rhs) {
    return egwSqrtf(((vec_rhs->axis.x - vec_lhs->axis.x) * (vec_rhs->axis.x - vec_lhs->axis.x)) +
                    ((vec_rhs->axis.y - vec_lhs->axis.y) * (vec_rhs->axis.y - vec_lhs->axis.y)) +
                    ((vec_rhs->axis.z - vec_lhs->axis.z) * (vec_rhs->axis.z - vec_lhs->axis.z)));
}

void egwVecDistance2fv(const egwVector2f* vecs_lhs, const egwVector2f* vecs_rhs, EGWsingle* dsts_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *dsts_out = egwSqrtf(((vecs_rhs->axis.x - vecs_lhs->axis.x) * (vecs_rhs->axis.x - vecs_lhs->axis.x)) +
                             ((vecs_rhs->axis.y - vecs_lhs->axis.y) * (vecs_rhs->axis.y - vecs_lhs->axis.y)));
        vecs_lhs = (const egwVector2f*)((EGWintptr)vecs_lhs + (EGWintptr)sizeof(egwVector2f) + strideB_lhs);
        vecs_rhs = (const egwVector2f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector2f) + strideB_rhs);
        dsts_out = (EGWsingle*)((EGWintptr)dsts_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

void egwVecDistance3fv(const egwVector3f* vecs_lhs, const egwVector3f* vecs_rhs, EGWsingle* dsts_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *dsts_out = egwSqrtf(((vecs_rhs->axis.x - vecs_lhs->axis.x) * (vecs_rhs->axis.x - vecs_lhs->axis.x)) +
                             ((vecs_rhs->axis.y - vecs_lhs->axis.y) * (vecs_rhs->axis.y - vecs_lhs->axis.y)) +
                             ((vecs_rhs->axis.z - vecs_lhs->axis.z) * (vecs_rhs->axis.z - vecs_lhs->axis.z)));
        vecs_lhs = (const egwVector3f*)((EGWintptr)vecs_lhs + (EGWintptr)sizeof(egwVector3f) + strideB_lhs);
        vecs_rhs = (const egwVector3f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector3f) + strideB_rhs);
        dsts_out = (EGWsingle*)((EGWintptr)dsts_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

EGWsingle egwVecDistanceSqrd2f(const egwVector2f* vec_lhs, const egwVector2f* vec_rhs) {
    return ((vec_rhs->axis.x - vec_lhs->axis.x) * (vec_rhs->axis.x - vec_lhs->axis.x)) +
           ((vec_rhs->axis.y - vec_lhs->axis.y) * (vec_rhs->axis.y - vec_lhs->axis.y));
}

EGWsingle egwVecDistanceSqrd3f(const egwVector3f* vec_lhs, const egwVector3f* vec_rhs) {
    return ((vec_rhs->axis.x - vec_lhs->axis.x) * (vec_rhs->axis.x - vec_lhs->axis.x)) +
           ((vec_rhs->axis.y - vec_lhs->axis.y) * (vec_rhs->axis.y - vec_lhs->axis.y)) +
           ((vec_rhs->axis.z - vec_lhs->axis.z) * (vec_rhs->axis.z - vec_lhs->axis.z));
}

EGWsingle egwVecDistanceSqrdXZ3f(const egwVector3f* vec_lhs, const egwVector3f* vec_rhs) {
    return ((vec_rhs->axis.x - vec_lhs->axis.x) * (vec_rhs->axis.x - vec_lhs->axis.x)) +
           ((vec_rhs->axis.z - vec_lhs->axis.z) * (vec_rhs->axis.z - vec_lhs->axis.z));
}

void egwVecDistanceSqrd2fv(const egwVector2f* vecs_lhs, const egwVector2f* vecs_rhs, EGWsingle* dsts_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *dsts_out = ((vecs_rhs->axis.x - vecs_lhs->axis.x) * (vecs_rhs->axis.x - vecs_lhs->axis.x)) +
                    ((vecs_rhs->axis.y - vecs_lhs->axis.y) * (vecs_rhs->axis.y - vecs_lhs->axis.y));
        vecs_lhs = (const egwVector2f*)((EGWintptr)vecs_lhs + (EGWintptr)sizeof(egwVector2f) + strideB_lhs);
        vecs_rhs = (const egwVector2f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector2f) + strideB_rhs);
        dsts_out = (EGWsingle*)((EGWintptr)dsts_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

void egwVecDistanceSqrd3fv(const egwVector3f* vecs_lhs, const egwVector3f* vecs_rhs, EGWsingle* dsts_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *dsts_out = ((vecs_rhs->axis.x - vecs_lhs->axis.x) * (vecs_rhs->axis.x - vecs_lhs->axis.x)) +
                    ((vecs_rhs->axis.y - vecs_lhs->axis.y) * (vecs_rhs->axis.y - vecs_lhs->axis.y)) +
                    ((vecs_rhs->axis.z - vecs_lhs->axis.z) * (vecs_rhs->axis.z - vecs_lhs->axis.z));
        vecs_lhs = (const egwVector3f*)((EGWintptr)vecs_lhs + (EGWintptr)sizeof(egwVector3f) + strideB_lhs);
        vecs_rhs = (const egwVector3f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector3f) + strideB_rhs);
        dsts_out = (EGWsingle*)((EGWintptr)dsts_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

void egwVecDistanceSqrdXZ3fv(const egwVector3f* vecs_lhs, const egwVector3f* vecs_rhs, EGWsingle* dsts_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *dsts_out = ((vecs_rhs->axis.x - vecs_lhs->axis.x) * (vecs_rhs->axis.x - vecs_lhs->axis.x)) +
                    ((vecs_rhs->axis.z - vecs_lhs->axis.z) * (vecs_rhs->axis.z - vecs_lhs->axis.z));
        vecs_lhs = (const egwVector3f*)((EGWintptr)vecs_lhs + (EGWintptr)sizeof(egwVector3f) + strideB_lhs);
        vecs_rhs = (const egwVector3f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector3f) + strideB_rhs);
        dsts_out = (EGWsingle*)((EGWintptr)dsts_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

EGWsingle egwVecFastDistance2f(const egwVector2f* vec_lhs, const egwVector2f* vec_rhs) {
    return 1.0f / egwFastInvSqrtf(((vec_rhs->axis.x - vec_lhs->axis.x) * (vec_rhs->axis.x - vec_lhs->axis.x)) +
                                  ((vec_rhs->axis.y - vec_lhs->axis.y) * (vec_rhs->axis.y - vec_lhs->axis.y)));
}

EGWsingle egwVecFastDistance3f(const egwVector3f* vec_lhs, const egwVector3f* vec_rhs) {
    return 1.0f / egwFastInvSqrtf(((vec_rhs->axis.x - vec_lhs->axis.x) * (vec_rhs->axis.x - vec_lhs->axis.x)) +
                                  ((vec_rhs->axis.y - vec_lhs->axis.y) * (vec_rhs->axis.y - vec_lhs->axis.y)) +
                                  ((vec_rhs->axis.z - vec_lhs->axis.z) * (vec_rhs->axis.z - vec_lhs->axis.z)));
}

void egwVecFastDistance2fv(const egwVector2f* vecs_lhs, const egwVector2f* vecs_rhs, EGWsingle* dsts_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *dsts_out = 1.0f / egwFastInvSqrtf(((vecs_rhs->axis.x - vecs_lhs->axis.x) * (vecs_rhs->axis.x - vecs_lhs->axis.x)) +
                                           ((vecs_rhs->axis.y - vecs_lhs->axis.y) * (vecs_rhs->axis.y - vecs_lhs->axis.y)));
        vecs_lhs = (const egwVector2f*)((EGWintptr)vecs_lhs + (EGWintptr)sizeof(egwVector2f) + strideB_lhs);
        vecs_rhs = (const egwVector2f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector2f) + strideB_rhs);
        dsts_out = (EGWsingle*)((EGWintptr)dsts_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

void egwVecFastDistance3fv(const egwVector3f* vecs_lhs, const egwVector3f* vecs_rhs, EGWsingle* dsts_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *dsts_out = 1.0f / egwFastInvSqrtf(((vecs_rhs->axis.x - vecs_lhs->axis.x) * (vecs_rhs->axis.x - vecs_lhs->axis.x)) +
                                           ((vecs_rhs->axis.y - vecs_lhs->axis.y) * (vecs_rhs->axis.y - vecs_lhs->axis.y)) +
                                           ((vecs_rhs->axis.z - vecs_lhs->axis.z) * (vecs_rhs->axis.z - vecs_lhs->axis.z)));
        vecs_lhs = (const egwVector3f*)((EGWintptr)vecs_lhs + (EGWintptr)sizeof(egwVector3f) + strideB_lhs);
        vecs_rhs = (const egwVector3f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector3f) + strideB_rhs);
        dsts_out = (EGWsingle*)((EGWintptr)dsts_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

egwVector2f* egwVecNegate2f(const egwVector2f* vec_in, egwVector2f* vec_out) {
    vec_out->axis.x = -vec_in->axis.x;
    vec_out->axis.y = -vec_in->axis.y;
    return vec_out;
}

egwVector3f* egwVecNegate3f(const egwVector3f* vec_in, egwVector3f* vec_out) {
    vec_out->axis.x = -vec_in->axis.x;
    vec_out->axis.y = -vec_in->axis.y;
    vec_out->axis.z = -vec_in->axis.z;
    return vec_out;
}

void egwVecNegate2fv(const egwVector2f* vecs_in, egwVector2f* vecs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        vecs_out->axis.x = -vecs_in->axis.x;
        vecs_out->axis.y = -vecs_in->axis.y;
        vecs_in = (const egwVector2f*)((EGWintptr)vecs_in + (EGWintptr)sizeof(egwVector2f) + strideB_in);
        vecs_out = (egwVector2f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector2f) + strideB_out);
    }
}

void egwVecNegate3fv(const egwVector3f* vecs_in, egwVector3f* vecs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        vecs_out->axis.x = -vecs_in->axis.x;
        vecs_out->axis.y = -vecs_in->axis.y;
        vecs_out->axis.z = -vecs_in->axis.z;
        vecs_in = (const egwVector3f*)((EGWintptr)vecs_in + (EGWintptr)sizeof(egwVector3f) + strideB_in);
        vecs_out = (egwVector3f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector3f) + strideB_out);
    }
}

egwVector2f* egwVecInvert2f(const egwVector2f* vec_in, egwVector2f* vec_out) {
    vec_out->axis.x = 1.0f / vec_in->axis.x;
    vec_out->axis.y = 1.0f / vec_in->axis.y;
    return vec_out;
}

egwVector3f* egwVecInvert3f(const egwVector3f* vec_in, egwVector3f* vec_out) {
    vec_out->axis.x = 1.0f / vec_in->axis.x;
    vec_out->axis.y = 1.0f / vec_in->axis.y;
    vec_out->axis.z = 1.0f / vec_in->axis.z;
    return vec_out;
}

void egwVecInvert2fv(const egwVector2f* vecs_in, egwVector2f* vecs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        vecs_out->axis.x = 1.0f / vecs_in->axis.x;
        vecs_out->axis.y = 1.0f / vecs_in->axis.y;
        vecs_in = (const egwVector2f*)((EGWintptr)vecs_in + (EGWintptr)sizeof(egwVector2f) + strideB_in);
        vecs_out = (egwVector2f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector2f) + strideB_out);
    }
}

void egwVecInvert3fv(const egwVector3f* vecs_in, egwVector3f* vecs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        vecs_out->axis.x = 1.0f / vecs_in->axis.x;
        vecs_out->axis.y = 1.0f / vecs_in->axis.y;
        vecs_out->axis.z = 1.0f / vecs_in->axis.z;
        vecs_in = (const egwVector3f*)((EGWintptr)vecs_in + (EGWintptr)sizeof(egwVector3f) + strideB_in);
        vecs_out = (egwVector3f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector3f) + strideB_out);
    }
}

egwVector2f* egwVecAdd2f(const egwVector2f* vec_lhs, const egwVector2f* vec_rhs, egwVector2f* vec_out) {
    vec_out->axis.x = vec_lhs->axis.x + vec_rhs->axis.x;
    vec_out->axis.y = vec_lhs->axis.y + vec_rhs->axis.y;
    return vec_out;
}

egwVector3f* egwVecAdd3f(const egwVector3f* vec_lhs, const egwVector3f* vec_rhs, egwVector3f* vec_out) {
    vec_out->axis.x = vec_lhs->axis.x + vec_rhs->axis.x;
    vec_out->axis.y = vec_lhs->axis.y + vec_rhs->axis.y;
    vec_out->axis.z = vec_lhs->axis.z + vec_rhs->axis.z;
    return vec_out;
}

void egwVecAdd2fv(const egwVector2f* vecs_lhs, const egwVector2f* vecs_rhs, egwVector2f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        vecs_out->axis.x = vecs_lhs->axis.x + vecs_rhs->axis.x;
        vecs_out->axis.y = vecs_lhs->axis.y + vecs_rhs->axis.y;
        vecs_lhs = (const egwVector2f*)((EGWintptr)vecs_lhs + (EGWintptr)sizeof(egwVector2f) + strideB_lhs);
        vecs_rhs = (const egwVector2f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector2f) + strideB_rhs);
        vecs_out = (egwVector2f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector2f) + strideB_out);
    }
}

void egwVecAdd3fv(const egwVector3f* vecs_lhs, const egwVector3f* vecs_rhs, egwVector3f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        vecs_out->axis.x = vecs_lhs->axis.x + vecs_rhs->axis.x;
        vecs_out->axis.y = vecs_lhs->axis.y + vecs_rhs->axis.y;
        vecs_out->axis.z = vecs_lhs->axis.z + vecs_rhs->axis.z;
        vecs_lhs = (const egwVector3f*)((EGWintptr)vecs_lhs + (EGWintptr)sizeof(egwVector3f) + strideB_lhs);
        vecs_rhs = (const egwVector3f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector3f) + strideB_rhs);
        vecs_out = (egwVector3f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector3f) + strideB_out);
    }
}

egwVector2f* egwVecSubtract2f(const egwVector2f* vec_lhs, const egwVector2f* vec_rhs, egwVector2f* vec_out) {
    vec_out->axis.x = vec_lhs->axis.x - vec_rhs->axis.x;
    vec_out->axis.y = vec_lhs->axis.y - vec_rhs->axis.y;
    return vec_out;
}

egwVector3f* egwVecSubtract3f(const egwVector3f* vec_lhs, const egwVector3f* vec_rhs, egwVector3f* vec_out) {
    vec_out->axis.x = vec_lhs->axis.x - vec_rhs->axis.x;
    vec_out->axis.y = vec_lhs->axis.y - vec_rhs->axis.y;
    vec_out->axis.z = vec_lhs->axis.z - vec_rhs->axis.z;
    return vec_out;
}

void egwVecSubtract2fv(const egwVector2f* vecs_lhs, const egwVector2f* vecs_rhs, egwVector2f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        vecs_out->axis.x = vecs_lhs->axis.x - vecs_rhs->axis.x;
        vecs_out->axis.y = vecs_lhs->axis.y - vecs_rhs->axis.y;
        vecs_lhs = (const egwVector2f*)((EGWintptr)vecs_lhs + (EGWintptr)sizeof(egwVector2f) + strideB_lhs);
        vecs_rhs = (const egwVector2f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector2f) + strideB_rhs);
        vecs_out = (egwVector2f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector2f) + strideB_out);
    }
}

void egwVecSubtract3fv(const egwVector3f* vecs_lhs, const egwVector3f* vecs_rhs, egwVector3f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        vecs_out->axis.x = vecs_lhs->axis.x - vecs_rhs->axis.x;
        vecs_out->axis.y = vecs_lhs->axis.y - vecs_rhs->axis.y;
        vecs_out->axis.z = vecs_lhs->axis.z - vecs_rhs->axis.z;
        vecs_lhs = (const egwVector3f*)((EGWintptr)vecs_lhs + (EGWintptr)sizeof(egwVector3f) + strideB_lhs);
        vecs_rhs = (const egwVector3f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector3f) + strideB_rhs);
        vecs_out = (egwVector3f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector3f) + strideB_out);
    }
}

egwVector2f* egwVecMultiply2f(const egwVector2f* vec_lhs, const egwVector2f* vec_rhs, egwVector2f* vec_out) {
    vec_out->axis.x = vec_lhs->axis.x * vec_rhs->axis.x;
    vec_out->axis.y = vec_lhs->axis.y * vec_rhs->axis.y;
    return vec_out;
}

egwVector3f* egwVecMultiply3f(const egwVector3f* vec_lhs, const egwVector3f* vec_rhs, egwVector3f* vec_out) {
    vec_out->axis.x = vec_lhs->axis.x * vec_rhs->axis.x;
    vec_out->axis.y = vec_lhs->axis.y * vec_rhs->axis.y;
    vec_out->axis.z = vec_lhs->axis.z * vec_rhs->axis.z;
    return vec_out;
}

void egwVecMultiply2fv(const egwVector2f* vecs_lhs, const egwVector2f* vecs_rhs, egwVector2f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        vecs_out->axis.x = vecs_lhs->axis.x * vecs_rhs->axis.x;
        vecs_out->axis.y = vecs_lhs->axis.y * vecs_rhs->axis.y;
        vecs_lhs = (const egwVector2f*)((EGWintptr)vecs_lhs + (EGWintptr)sizeof(egwVector2f) + strideB_lhs);
        vecs_rhs = (const egwVector2f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector2f) + strideB_rhs);
        vecs_out = (egwVector2f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector2f) + strideB_out);
    }
}

void egwVecMultiply3fv(const egwVector3f* vecs_lhs, const egwVector3f* vecs_rhs, egwVector3f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        vecs_out->axis.x = vecs_lhs->axis.x * vecs_rhs->axis.x;
        vecs_out->axis.y = vecs_lhs->axis.y * vecs_rhs->axis.y;
        vecs_out->axis.z = vecs_lhs->axis.z * vecs_rhs->axis.z;
        vecs_lhs = (const egwVector3f*)((EGWintptr)vecs_lhs + (EGWintptr)sizeof(egwVector3f) + strideB_lhs);
        vecs_rhs = (const egwVector3f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector3f) + strideB_rhs);
        vecs_out = (egwVector3f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector3f) + strideB_out);
    }
}

egwVector2f* egwVecUScale2f(const egwVector2f* vec_lhs, const EGWsingle scale_rhs, egwVector2f* vec_out) {
    vec_out->axis.x = vec_lhs->axis.x * scale_rhs;
    vec_out->axis.y = vec_lhs->axis.y * scale_rhs;
    return vec_out;
}

egwVector3f* egwVecUScale3f(const egwVector3f* vec_lhs, const EGWsingle scale_rhs, egwVector3f* vec_out) {
    vec_out->axis.x = vec_lhs->axis.x * scale_rhs;
    vec_out->axis.y = vec_lhs->axis.y * scale_rhs;
    vec_out->axis.z = vec_lhs->axis.z * scale_rhs;
    return vec_out;
}

void egwVecUScale2fv(const egwVector2f* vecs_lhs, const EGWsingle* scales_rhs, egwVector2f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        vecs_out->axis.x = vecs_lhs->axis.x * *scales_rhs;
        vecs_out->axis.y = vecs_lhs->axis.y * *scales_rhs;
        vecs_lhs = (const egwVector2f*)((EGWintptr)vecs_lhs + (EGWintptr)sizeof(egwVector2f) + strideB_lhs);
        scales_rhs = (const EGWsingle*)((EGWintptr)scales_rhs + (EGWintptr)sizeof(EGWsingle) + strideB_rhs);
        vecs_out = (egwVector2f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector2f) + strideB_out);
    }
}

void egwVecUScale3fv(const egwVector3f* vecs_lhs, const EGWsingle* scales_rhs, egwVector3f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        vecs_out->axis.x = vecs_lhs->axis.x * *scales_rhs;
        vecs_out->axis.y = vecs_lhs->axis.y * *scales_rhs;
        vecs_out->axis.z = vecs_lhs->axis.z * *scales_rhs;
        vecs_lhs = (const egwVector3f*)((EGWintptr)vecs_lhs + (EGWintptr)sizeof(egwVector3f) + strideB_lhs);
        scales_rhs = (const EGWsingle*)((EGWintptr)scales_rhs + (EGWintptr)sizeof(EGWsingle) + strideB_rhs);
        vecs_out = (egwVector3f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector3f) + strideB_out);
    }
}

egwVector2f* egwVecSummation2fv(const egwVector2f* vecs_in, egwVector2f* vec_out, const EGWintptr strideB_in, EGWuint count) {
    vec_out->axis.x = vec_out->axis.y = 0.0f;
    while(count--) {
        vec_out->axis.x += vecs_in->axis.x;
        vec_out->axis.y += vecs_in->axis.y;
        vecs_in = (const egwVector2f*)((EGWintptr)vecs_in + (EGWintptr)sizeof(egwVector2f) + strideB_in);
    }
    return vec_out;
}

egwVector3f* egwVecSummation3fv(const egwVector3f* vecs_in, egwVector3f* vec_out, const EGWintptr strideB_in, EGWuint count) {
    vec_out->axis.x = vec_out->axis.y = vec_out->axis.z = 0.0f;
    while(count--) {
        vec_out->axis.x += vecs_in->axis.x;
        vec_out->axis.y += vecs_in->axis.y;
        vec_out->axis.z += vecs_in->axis.z;
        vecs_in = (const egwVector3f*)((EGWintptr)vecs_in + (EGWintptr)sizeof(egwVector3f) + strideB_in);
    }
    return vec_out;
}

void egwVecFindExtentsAxs2fv(const egwVector2f* vecs_in, egwVector2f* min_out, egwVector2f* max_out, const EGWintptr strideB_in, EGWuint count) {
    min_out->axis.x = min_out->axis.y = EGW_SFLT_MAX;
    max_out->axis.x = max_out->axis.y = -EGW_SFLT_MAX;
    
    while(count--) {
        if(vecs_in->axis.x < min_out->axis.x) min_out->axis.x = vecs_in->axis.x;
        if(vecs_in->axis.y < min_out->axis.y) min_out->axis.y = vecs_in->axis.y;
        if(vecs_in->axis.x > max_out->axis.x) max_out->axis.x = vecs_in->axis.x;
        if(vecs_in->axis.y > max_out->axis.y) max_out->axis.y = vecs_in->axis.y;
        vecs_in = (const egwVector2f*)((EGWintptr)vecs_in + (EGWintptr)sizeof(egwVector2f) + strideB_in);
    }
}

void egwVecFindExtentsAxs3fv(const egwVector3f* vecs_in, egwVector3f* min_out, egwVector3f* max_out, const EGWintptr strideB_in, EGWuint count) {
    min_out->axis.x = min_out->axis.y = min_out->axis.z = EGW_SFLT_MAX;
    max_out->axis.x = max_out->axis.y = max_out->axis.z = -EGW_SFLT_MAX;
    
    while(count--) {
        if(vecs_in->axis.x < min_out->axis.x) min_out->axis.x = vecs_in->axis.x;
        if(vecs_in->axis.y < min_out->axis.y) min_out->axis.y = vecs_in->axis.y;
        if(vecs_in->axis.z < min_out->axis.z) min_out->axis.z = vecs_in->axis.z;
        if(vecs_in->axis.x > max_out->axis.x) max_out->axis.x = vecs_in->axis.x;
        if(vecs_in->axis.y > max_out->axis.y) max_out->axis.y = vecs_in->axis.y;
        if(vecs_in->axis.z > max_out->axis.z) max_out->axis.z = vecs_in->axis.z;
        vecs_in = (const egwVector3f*)((EGWintptr)vecs_in + (EGWintptr)sizeof(egwVector3f) + strideB_in);
    }
}

void egwVecFindExtentsVct2fv(const egwVector2f* vecs_in, egwVector2f** minX_out, egwVector2f** maxX_out, egwVector2f** minY_out, egwVector2f** maxY_out, const EGWintptr strideB_in, EGWuint count) {
    *minX_out = *maxX_out = *minY_out = *maxY_out = (egwVector2f*)vecs_in;
    --count;
    vecs_in = (const egwVector2f*)((EGWintptr)vecs_in + (EGWintptr)sizeof(egwVector2f) + strideB_in);
    
    while(count--) {
        if(vecs_in->axis.x < (*minX_out)->axis.x) *minX_out = (egwVector2f*)vecs_in;
        if(vecs_in->axis.y < (*minY_out)->axis.y) *minX_out = (egwVector2f*)vecs_in;
        if(vecs_in->axis.x > (*maxX_out)->axis.x) *minX_out = (egwVector2f*)vecs_in;
        if(vecs_in->axis.y > (*maxY_out)->axis.y) *minX_out = (egwVector2f*)vecs_in;
        vecs_in = (const egwVector2f*)((EGWintptr)vecs_in + (EGWintptr)sizeof(egwVector2f) + strideB_in);
    }
}

void egwVecFindExtentsVct3fv(const egwVector3f* vecs_in, const egwVector3f** const minX_out, const egwVector3f** const maxX_out, const egwVector3f** const minY_out, const egwVector3f** const maxY_out, const egwVector3f** const minZ_out, const egwVector3f** const maxZ_out, const EGWintptr strideB_in, EGWuint count) {
    *minX_out = *maxX_out = *minY_out = *maxY_out = *minZ_out = *maxZ_out = (egwVector3f*)vecs_in;
    --count;
    vecs_in = (const egwVector3f*)((EGWintptr)vecs_in + (EGWintptr)sizeof(egwVector3f) + strideB_in);
    
    while(count--) {
        if(vecs_in->axis.x < (*minX_out)->axis.x) *minX_out = (egwVector3f*)vecs_in;
        if(vecs_in->axis.y < (*minY_out)->axis.y) *minY_out = (egwVector3f*)vecs_in;
        if(vecs_in->axis.z < (*minZ_out)->axis.z) *minZ_out = (egwVector3f*)vecs_in;
        if(vecs_in->axis.x > (*maxX_out)->axis.x) *maxX_out = (egwVector3f*)vecs_in;
        if(vecs_in->axis.y > (*maxY_out)->axis.y) *maxY_out = (egwVector3f*)vecs_in;
        if(vecs_in->axis.z > (*maxZ_out)->axis.z) *maxZ_out = (egwVector3f*)vecs_in;
        vecs_in = (const egwVector3f*)((EGWintptr)vecs_in + (EGWintptr)sizeof(egwVector3f) + strideB_in);
    }
}

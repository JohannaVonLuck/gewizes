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

/// @file egwMatrix.m
/// @ingroup geWizES_math_matrix
/// Matrix Implementation.

#import "egwMatrix.h"
#import "egwMath.h"
#import "egwVector.h"
#import "egwQuaternion.h"


const egwMatrix33f egwSIMatIdentity33f =  {1.0f, 0.0f, 0.0f,  0.0f, 1.0f, 0.0f,  0.0f, 0.0f, 1.0f};
const egwMatrix33f egwSIMatZero33f =      {0.0f, 0.0f, 0.0f,  0.0f, 0.0f, 0.0f,  0.0f, 0.0f, 0.0f};
const egwMatrix44f egwSIMatIdentity44f =  {1.0f, 0.0f, 0.0f, 0.0f,  0.0f, 1.0f, 0.0f, 0.0f,  0.0f, 0.0f, 1.0f, 0.0f,  0.0f, 0.0f, 0.0f, 1.0f};
const egwMatrix44f egwSIMatZero44f =      {0.0f, 0.0f, 0.0f, 0.0f,  0.0f, 0.0f, 0.0f, 0.0f,  0.0f, 0.0f, 0.0f, 0.0f,  0.0f, 0.0f, 0.0f, 0.0f};


egwMatrix33f* egwMatInit33f(egwMatrix33f* mat_out,
                                   const EGWsingle r1c1, const EGWsingle r1c2, const EGWsingle r1c3,
                                   const EGWsingle r2c1, const EGWsingle r2c2, const EGWsingle r2c3,
                                   const EGWsingle r3c1, const EGWsingle r3c2, const EGWsingle r3c3) {
    mat_out->component.r1c1 = r1c1; mat_out->component.r1c2 = r1c2; mat_out->component.r1c3 = r1c3;
    mat_out->component.r2c1 = r2c1; mat_out->component.r2c2 = r2c2; mat_out->component.r2c3 = r2c3;
    mat_out->component.r3c1 = r3c1; mat_out->component.r3c2 = r3c2; mat_out->component.r3c3 = r3c3;
    return mat_out;
}

egwMatrix44f* egwMatInit44f(egwMatrix44f* mat_out,
                                   const EGWsingle r1c1, const EGWsingle r1c2, const EGWsingle r1c3, const EGWsingle r1c4,
                                   const EGWsingle r2c1, const EGWsingle r2c2, const EGWsingle r2c3, const EGWsingle r2c4,
                                   const EGWsingle r3c1, const EGWsingle r3c2, const EGWsingle r3c3, const EGWsingle r3c4,
                                   const EGWsingle r4c1, const EGWsingle r4c2, const EGWsingle r4c3, const EGWsingle r4c4) {
    mat_out->component.r1c1 = r1c1; mat_out->component.r1c2 = r1c2; mat_out->component.r1c3 = r1c3; mat_out->component.r1c4 = r1c4;
    mat_out->component.r2c1 = r2c1; mat_out->component.r2c2 = r2c2; mat_out->component.r2c3 = r2c3; mat_out->component.r2c4 = r2c4;
    mat_out->component.r3c1 = r3c1; mat_out->component.r3c2 = r3c2; mat_out->component.r3c3 = r3c3; mat_out->component.r3c4 = r3c4;
    mat_out->component.r4c1 = r4c1; mat_out->component.r4c2 = r4c2; mat_out->component.r4c3 = r4c3; mat_out->component.r4c4 = r4c4;
    return mat_out;
}

void egwMatInit33fv(egwMatrix33f* mats_out,
                    const EGWsingle r1c1, const EGWsingle r1c2, const EGWsingle r1c3,
                    const EGWsingle r2c1, const EGWsingle r2c2, const EGWsingle r2c3,
                    const EGWsingle r3c1, const EGWsingle r3c2, const EGWsingle r3c3,
                    const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        mats_out->component.r1c1 = r1c1; mats_out->component.r1c2 = r1c2; mats_out->component.r1c3 = r1c3;
        mats_out->component.r2c1 = r2c1; mats_out->component.r2c2 = r2c2; mats_out->component.r2c3 = r2c3;
        mats_out->component.r3c1 = r3c1; mats_out->component.r3c2 = r3c2; mats_out->component.r3c3 = r3c3;
        mats_out = (egwMatrix33f*)((EGWintptr)mats_out + (EGWintptr)sizeof(egwMatrix33f) + strideB_out);
    }
}

void egwMatInit44fv(egwMatrix44f* mats_out,
                    const EGWsingle r1c1, const EGWsingle r1c2, const EGWsingle r1c3, const EGWsingle r1c4,
                    const EGWsingle r2c1, const EGWsingle r2c2, const EGWsingle r2c3, const EGWsingle r2c4,
                    const EGWsingle r3c1, const EGWsingle r3c2, const EGWsingle r3c3, const EGWsingle r3c4,
                    const EGWsingle r4c1, const EGWsingle r4c2, const EGWsingle r4c3, const EGWsingle r4c4,
                    EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        mats_out->component.r1c1 = r1c1; mats_out->component.r1c2 = r1c2; mats_out->component.r1c3 = r1c3; mats_out->component.r1c4 = r1c4;
        mats_out->component.r2c1 = r2c1; mats_out->component.r2c2 = r2c2; mats_out->component.r2c3 = r2c3; mats_out->component.r2c4 = r2c4;
        mats_out->component.r3c1 = r3c1; mats_out->component.r3c2 = r3c2; mats_out->component.r3c3 = r3c3; mats_out->component.r3c4 = r3c4;
        mats_out->component.r4c1 = r4c1; mats_out->component.r4c2 = r4c2; mats_out->component.r4c3 = r4c3; mats_out->component.r4c4 = r4c4;
        mats_out = (egwMatrix44f*)((EGWintptr)mats_out + (EGWintptr)sizeof(egwMatrix44f) + strideB_out);
    }
}

egwMatrix33f* egwMatCopy33f(const egwMatrix33f* mat_in, egwMatrix33f* mat_out) {
    mat_out->component.r1c1 = mat_in->component.r1c1; mat_out->component.r1c2 = mat_in->component.r1c2; mat_out->component.r1c3 = mat_in->component.r1c3;
    mat_out->component.r2c1 = mat_in->component.r2c1; mat_out->component.r2c2 = mat_in->component.r2c2; mat_out->component.r2c3 = mat_in->component.r2c3;
    mat_out->component.r3c1 = mat_in->component.r3c1; mat_out->component.r3c2 = mat_in->component.r3c2; mat_out->component.r3c3 = mat_in->component.r3c3;
    return mat_out;
}

egwMatrix44f* egwMatCopy44f(const egwMatrix44f* mat_in, egwMatrix44f* mat_out) {
    mat_out->component.r1c1 = mat_in->component.r1c1; mat_out->component.r1c2 = mat_in->component.r1c2; mat_out->component.r1c3 = mat_in->component.r1c3; mat_out->component.r1c4 = mat_in->component.r1c4;
    mat_out->component.r2c1 = mat_in->component.r2c1; mat_out->component.r2c2 = mat_in->component.r2c2; mat_out->component.r2c3 = mat_in->component.r2c3; mat_out->component.r2c4 = mat_in->component.r2c4;
    mat_out->component.r3c1 = mat_in->component.r3c1; mat_out->component.r3c2 = mat_in->component.r3c2; mat_out->component.r3c3 = mat_in->component.r3c3; mat_out->component.r3c4 = mat_in->component.r3c4;
    mat_out->component.r4c1 = mat_in->component.r4c1; mat_out->component.r4c2 = mat_in->component.r4c2; mat_out->component.r4c3 = mat_in->component.r4c3; mat_out->component.r4c4 = mat_in->component.r4c4;
    return mat_out;
}

void egwMatCopy33fv(const egwMatrix33f* mats_in, egwMatrix33f* mats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        mats_out->component.r1c1 = mats_in->component.r1c1; mats_out->component.r1c2 = mats_in->component.r1c2; mats_out->component.r1c3 = mats_in->component.r1c3;
        mats_out->component.r2c1 = mats_in->component.r2c1; mats_out->component.r2c2 = mats_in->component.r2c2; mats_out->component.r2c3 = mats_in->component.r2c3;
        mats_out->component.r3c1 = mats_in->component.r3c1; mats_out->component.r3c2 = mats_in->component.r3c2; mats_out->component.r3c3 = mats_in->component.r3c3;
        mats_in = (const egwMatrix33f*)((EGWintptr)mats_in + (EGWintptr)sizeof(egwMatrix33f) + strideB_in);
        mats_out = (egwMatrix33f*)((EGWintptr)mats_out + (EGWintptr)sizeof(egwMatrix33f) + strideB_out);
    }
}

void egwMatCopy44fv(const egwMatrix44f* mats_in, egwMatrix44f* mats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        mats_out->component.r1c1 = mats_in->component.r1c1; mats_out->component.r1c2 = mats_in->component.r1c2; mats_out->component.r1c3 = mats_in->component.r1c3; mats_out->component.r1c4 = mats_in->component.r1c4;
        mats_out->component.r2c1 = mats_in->component.r2c1; mats_out->component.r2c2 = mats_in->component.r2c2; mats_out->component.r2c3 = mats_in->component.r2c3; mats_out->component.r2c4 = mats_in->component.r2c4;
        mats_out->component.r3c1 = mats_in->component.r3c1; mats_out->component.r3c2 = mats_in->component.r3c2; mats_out->component.r3c3 = mats_in->component.r3c3; mats_out->component.r3c4 = mats_in->component.r3c4;
        mats_out->component.r4c1 = mats_in->component.r4c1; mats_out->component.r4c2 = mats_in->component.r4c2; mats_out->component.r4c3 = mats_in->component.r4c3; mats_out->component.r4c4 = mats_in->component.r4c4;
        mats_in = (const egwMatrix44f*)((EGWintptr)mats_in + (EGWintptr)sizeof(egwMatrix44f) + strideB_in);
        mats_out = (egwMatrix44f*)((EGWintptr)mats_out + (EGWintptr)sizeof(egwMatrix44f) + strideB_out);
    }
}

EGWint egwMatIsEqual33f(const egwMatrix33f* mat_lhs, const egwMatrix33f* mat_rhs) {
    return ((mat_lhs == mat_rhs) ||
            (egwIsEqualf(mat_lhs->component.r1c1, mat_rhs->component.r1c1) && egwIsEqualf(mat_lhs->component.r1c2, mat_rhs->component.r1c2) && egwIsEqualf(mat_lhs->component.r1c3, mat_rhs->component.r1c3) &&
             egwIsEqualf(mat_lhs->component.r2c1, mat_rhs->component.r2c1) && egwIsEqualf(mat_lhs->component.r2c2, mat_rhs->component.r2c2) && egwIsEqualf(mat_lhs->component.r2c3, mat_rhs->component.r2c3) &&
             egwIsEqualf(mat_lhs->component.r3c1, mat_rhs->component.r3c1) && egwIsEqualf(mat_lhs->component.r3c2, mat_rhs->component.r3c2) && egwIsEqualf(mat_lhs->component.r3c3, mat_rhs->component.r3c3)) ? 1 : 0);
}

EGWint egwMatIsEqual44f(const egwMatrix44f* mat_lhs, const egwMatrix44f* mat_rhs) {
    return ((mat_lhs == mat_rhs) ||
            (egwIsEqualf(mat_lhs->component.r1c1, mat_rhs->component.r1c1) && egwIsEqualf(mat_lhs->component.r1c2, mat_rhs->component.r1c2) && egwIsEqualf(mat_lhs->component.r1c3, mat_rhs->component.r1c3) && egwIsEqualf(mat_lhs->component.r1c4, mat_rhs->component.r1c4) &&
             egwIsEqualf(mat_lhs->component.r2c1, mat_rhs->component.r2c1) && egwIsEqualf(mat_lhs->component.r2c2, mat_rhs->component.r2c2) && egwIsEqualf(mat_lhs->component.r2c3, mat_rhs->component.r2c3) && egwIsEqualf(mat_lhs->component.r2c4, mat_rhs->component.r2c4) &&
             egwIsEqualf(mat_lhs->component.r3c1, mat_rhs->component.r3c1) && egwIsEqualf(mat_lhs->component.r3c2, mat_rhs->component.r3c2) && egwIsEqualf(mat_lhs->component.r3c3, mat_rhs->component.r3c3) && egwIsEqualf(mat_lhs->component.r3c4, mat_rhs->component.r3c4) &&
             egwIsEqualf(mat_lhs->component.r4c1, mat_rhs->component.r4c1) && egwIsEqualf(mat_lhs->component.r4c2, mat_rhs->component.r4c2) && egwIsEqualf(mat_lhs->component.r4c3, mat_rhs->component.r4c3) && egwIsEqualf(mat_lhs->component.r4c4, mat_rhs->component.r4c4)) ? 1 : 0);
}

EGWint egwMatIsHomogeneous33f(const egwMatrix33f* mat_in) {
    return ((egwIsZerof(mat_in->component.r3c1) && egwIsZerof(mat_in->component.r3c2) && egwIsOnef(mat_in->component.r3c3)) ? 1 : 0);
}

EGWint egwMatIsHomogeneous44f(const egwMatrix44f* mat_in) {
    return ((egwIsZerof(mat_in->component.r4c1) && egwIsZerof(mat_in->component.r4c2) && egwIsZerof(mat_in->component.r4c3) && egwIsOnef(mat_in->component.r4c4)) ? 1 : 0 );
}

EGWint egwMatIsOrthogonal33f(const egwMatrix33f* mat_in) {
    return (egwIsOnef(egwAbsf(egwMatDeterminant33f(mat_in))) ? 1 : 0);
}

EGWint egwMatIsOrthogonal44f(const egwMatrix44f* mat_in) {
    return (egwIsOnef(egwAbsf(egwMatDeterminant44f(mat_in))) ? 1 : 0);
}

egwMatrix33f* egwMatTranspose33f(const egwMatrix33f* mat_in, egwMatrix33f* mat_out) {
    if(mat_out == mat_in) {
        EGWsingle temp;
        temp = mat_in->component.r2c1; mat_out->component.r2c1 = mat_in->component.r1c2; mat_out->component.r1c2 = temp;
        temp = mat_in->component.r3c1; mat_out->component.r3c1 = mat_in->component.r1c3; mat_out->component.r1c3 = temp;
        temp = mat_in->component.r3c2; mat_out->component.r3c2 = mat_in->component.r2c3; mat_out->component.r2c3 = temp;
    } else {
        mat_out->component.r1c1 = mat_in->component.r1c1; mat_out->component.r1c2 = mat_in->component.r2c1; mat_out->component.r1c3 = mat_in->component.r3c1;
        mat_out->component.r2c1 = mat_in->component.r1c2; mat_out->component.r2c2 = mat_in->component.r2c2; mat_out->component.r2c3 = mat_in->component.r3c2;
        mat_out->component.r3c1 = mat_in->component.r1c3; mat_out->component.r3c2 = mat_in->component.r2c3; mat_out->component.r3c3 = mat_in->component.r3c3;
    }
    return mat_out;
}

egwMatrix44f* egwMatTranspose44f(const egwMatrix44f* mat_in, egwMatrix44f* mat_out) {
    if(mat_out == mat_in) {
        EGWsingle temp;
        temp = mat_in->component.r2c1; mat_out->component.r2c1 = mat_in->component.r1c2; mat_out->component.r1c2 = temp;
        temp = mat_in->component.r3c1; mat_out->component.r3c1 = mat_in->component.r1c3; mat_out->component.r1c3 = temp;
        temp = mat_in->component.r3c2; mat_out->component.r3c2 = mat_in->component.r2c3; mat_out->component.r2c3 = temp;
        temp = mat_in->component.r4c1; mat_out->component.r4c1 = mat_in->component.r1c4; mat_out->component.r1c4 = temp;
        temp = mat_in->component.r4c2; mat_out->component.r4c2 = mat_in->component.r2c4; mat_out->component.r2c4 = temp;
        temp = mat_in->component.r4c3; mat_out->component.r4c3 = mat_in->component.r3c4; mat_out->component.r3c4 = temp;
    } else {
        mat_out->component.r1c1 = mat_in->component.r1c1; mat_out->component.r1c2 = mat_in->component.r2c1; mat_out->component.r1c3 = mat_in->component.r3c1; mat_out->component.r1c4 = mat_in->component.r4c1;
        mat_out->component.r2c1 = mat_in->component.r1c2; mat_out->component.r2c2 = mat_in->component.r2c2; mat_out->component.r2c3 = mat_in->component.r3c2; mat_out->component.r2c4 = mat_in->component.r4c2;
        mat_out->component.r3c1 = mat_in->component.r1c3; mat_out->component.r3c2 = mat_in->component.r2c3; mat_out->component.r3c3 = mat_in->component.r3c3; mat_out->component.r3c4 = mat_in->component.r4c3;
        mat_out->component.r4c1 = mat_in->component.r1c4; mat_out->component.r4c2 = mat_in->component.r2c4; mat_out->component.r4c3 = mat_in->component.r3c4; mat_out->component.r4c4 = mat_in->component.r4c4;
    }
    return mat_out;
}

void egwMatTranspose33fv(const egwMatrix33f* mats_in, egwMatrix33f* mats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        if(mats_out == mats_in) {
            EGWsingle temp;
            temp = mats_in->component.r2c1; mats_out->component.r2c1 = mats_in->component.r1c2; mats_out->component.r1c2 = temp;
            temp = mats_in->component.r3c1; mats_out->component.r3c1 = mats_in->component.r1c3; mats_out->component.r1c3 = temp;
            temp = mats_in->component.r3c2; mats_out->component.r3c2 = mats_in->component.r2c3; mats_out->component.r2c3 = temp;
        } else {
            mats_out->component.r1c1 = mats_in->component.r1c1; mats_out->component.r1c2 = mats_in->component.r2c1; mats_out->component.r1c3 = mats_in->component.r3c1;
            mats_out->component.r2c1 = mats_in->component.r1c2; mats_out->component.r2c2 = mats_in->component.r2c2; mats_out->component.r2c3 = mats_in->component.r3c2;
            mats_out->component.r3c1 = mats_in->component.r1c3; mats_out->component.r3c2 = mats_in->component.r2c3; mats_out->component.r3c3 = mats_in->component.r3c3;
        }
        mats_in = (const egwMatrix33f*)((EGWintptr)mats_in + (EGWintptr)sizeof(egwMatrix33f) + strideB_in);
        mats_out = (egwMatrix33f*)((EGWintptr)mats_out + (EGWintptr)sizeof(egwMatrix33f) + strideB_out);
    }
}

void egwMatTranspose44fv(const egwMatrix44f* mats_in, egwMatrix44f* mats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        if(mats_out == mats_in) {
            EGWsingle temp;
            temp = mats_in->component.r2c1; mats_out->component.r2c1 = mats_in->component.r1c2; mats_out->component.r1c2 = temp;
            temp = mats_in->component.r3c1; mats_out->component.r3c1 = mats_in->component.r1c3; mats_out->component.r1c3 = temp;
            temp = mats_in->component.r3c2; mats_out->component.r3c2 = mats_in->component.r2c3; mats_out->component.r2c3 = temp;
            temp = mats_in->component.r4c1; mats_out->component.r4c1 = mats_in->component.r1c4; mats_out->component.r1c4 = temp;
            temp = mats_in->component.r4c2; mats_out->component.r4c2 = mats_in->component.r2c4; mats_out->component.r2c4 = temp;
            temp = mats_in->component.r4c3; mats_out->component.r4c3 = mats_in->component.r3c4; mats_out->component.r3c4 = temp;
        } else {
            mats_out->component.r1c1 = mats_in->component.r1c1; mats_out->component.r1c2 = mats_in->component.r2c1; mats_out->component.r1c3 = mats_in->component.r3c1; mats_out->component.r1c4 = mats_in->component.r4c1;
            mats_out->component.r2c1 = mats_in->component.r1c2; mats_out->component.r2c2 = mats_in->component.r2c2; mats_out->component.r2c3 = mats_in->component.r3c2; mats_out->component.r2c4 = mats_in->component.r4c2;
            mats_out->component.r3c1 = mats_in->component.r1c3; mats_out->component.r3c2 = mats_in->component.r2c3; mats_out->component.r3c3 = mats_in->component.r3c3; mats_out->component.r3c4 = mats_in->component.r4c3;
            mats_out->component.r4c1 = mats_in->component.r1c4; mats_out->component.r4c2 = mats_in->component.r2c4; mats_out->component.r4c3 = mats_in->component.r3c4; mats_out->component.r4c4 = mats_in->component.r4c4;
        }
        mats_in = (const egwMatrix44f*)((EGWintptr)mats_in + (EGWintptr)sizeof(egwMatrix44f) + strideB_in);
        mats_out = (egwMatrix44f*)((EGWintptr)mats_out + (EGWintptr)sizeof(egwMatrix44f) + strideB_out);
    }
}

egwMatrix33f* egwMatTransposeHmg33f(const egwMatrix33f* mat_in, egwMatrix33f* mat_out) {
    if(mat_out == mat_in) {
        EGWsingle temp;
        temp = mat_in->component.r2c1; mat_out->component.r2c1 = mat_in->component.r1c2; mat_out->component.r1c2 = temp;
    } else {
        mat_out->component.r1c1 = mat_in->component.r1c1; mat_out->component.r1c2 = mat_in->component.r2c1; mat_out->component.r1c3 = mat_in->component.r1c3;
        mat_out->component.r2c1 = mat_in->component.r1c2; mat_out->component.r2c2 = mat_in->component.r2c2; mat_out->component.r2c3 = mat_in->component.r2c3;
        mat_out->component.r3c1 = mat_in->component.r3c1; mat_out->component.r3c2 = mat_in->component.r3c2; mat_out->component.r3c3 = mat_in->component.r3c3;
    }
    return mat_out;
}

egwMatrix44f* egwMatTransposeHmg44f(const egwMatrix44f* mat_in, egwMatrix44f* mat_out) {
    if(mat_out == mat_in) {
        EGWsingle temp;
        temp = mat_in->component.r2c1; mat_out->component.r2c1 = mat_in->component.r1c2; mat_out->component.r1c2 = temp;
        temp = mat_in->component.r3c1; mat_out->component.r3c1 = mat_in->component.r1c3; mat_out->component.r1c3 = temp;
        temp = mat_in->component.r3c2; mat_out->component.r3c2 = mat_in->component.r2c3; mat_out->component.r2c3 = temp;
    } else {
        mat_out->component.r1c1 = mat_in->component.r1c1; mat_out->component.r1c2 = mat_in->component.r2c1; mat_out->component.r1c3 = mat_in->component.r3c1; mat_out->component.r1c4 = mat_in->component.r1c4;
        mat_out->component.r2c1 = mat_in->component.r1c2; mat_out->component.r2c2 = mat_in->component.r2c2; mat_out->component.r2c3 = mat_in->component.r3c2; mat_out->component.r2c4 = mat_in->component.r2c4;
        mat_out->component.r3c1 = mat_in->component.r1c3; mat_out->component.r3c2 = mat_in->component.r2c3; mat_out->component.r3c3 = mat_in->component.r3c3; mat_out->component.r3c4 = mat_in->component.r3c4;
        mat_out->component.r4c1 = mat_in->component.r4c1; mat_out->component.r4c2 = mat_in->component.r4c2; mat_out->component.r4c3 = mat_in->component.r4c3; mat_out->component.r4c4 = mat_in->component.r4c4;
    }
    return mat_out;
}

void egwMatTransposeHmg33fv(const egwMatrix33f* mats_in, egwMatrix33f* mats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        if(mats_out == mats_in) {
            EGWsingle temp;
            temp = mats_in->component.r2c1; mats_out->component.r2c1 = mats_in->component.r1c2; mats_out->component.r1c2 = temp;
        } else {
            mats_out->component.r1c1 = mats_in->component.r1c1; mats_out->component.r1c2 = mats_in->component.r2c1; mats_out->component.r1c3 = mats_in->component.r1c3;
            mats_out->component.r2c1 = mats_in->component.r1c2; mats_out->component.r2c2 = mats_in->component.r2c2; mats_out->component.r2c3 = mats_in->component.r2c3;
            mats_out->component.r3c1 = mats_in->component.r3c1; mats_out->component.r3c2 = mats_in->component.r3c2; mats_out->component.r3c3 = mats_in->component.r3c3;
        }
        mats_in = (const egwMatrix33f*)((EGWintptr)mats_in + (EGWintptr)sizeof(egwMatrix33f) + strideB_in);
        mats_out = (egwMatrix33f*)((EGWintptr)mats_out + (EGWintptr)sizeof(egwMatrix33f) + strideB_out);
    }
}

void egwMatTransposeHmg44fv(const egwMatrix44f* mats_in, egwMatrix44f* mats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        if(mats_out == mats_in) {
            EGWsingle temp;
            temp = mats_in->component.r2c1; mats_out->component.r2c1 = mats_in->component.r1c2; mats_out->component.r1c2 = temp;
            temp = mats_in->component.r3c1; mats_out->component.r3c1 = mats_in->component.r1c3; mats_out->component.r1c3 = temp;
            temp = mats_in->component.r3c2; mats_out->component.r3c2 = mats_in->component.r2c3; mats_out->component.r2c3 = temp;
        } else {
            mats_out->component.r1c1 = mats_in->component.r1c1; mats_out->component.r1c2 = mats_in->component.r2c1; mats_out->component.r1c3 = mats_in->component.r3c1; mats_out->component.r1c4 = mats_in->component.r1c4;
            mats_out->component.r2c1 = mats_in->component.r1c2; mats_out->component.r2c2 = mats_in->component.r2c2; mats_out->component.r2c3 = mats_in->component.r3c2; mats_out->component.r2c4 = mats_in->component.r2c4;
            mats_out->component.r3c1 = mats_in->component.r1c3; mats_out->component.r3c2 = mats_in->component.r2c3; mats_out->component.r3c3 = mats_in->component.r3c3; mats_out->component.r3c4 = mats_in->component.r3c4;
            mats_out->component.r4c1 = mats_in->component.r4c1; mats_out->component.r4c2 = mats_in->component.r4c2; mats_out->component.r4c3 = mats_in->component.r4c3; mats_out->component.r4c4 = mats_in->component.r4c4;
        }
        mats_in = (const egwMatrix44f*)((EGWintptr)mats_in + (EGWintptr)sizeof(egwMatrix44f) + strideB_in);
        mats_out = (egwMatrix44f*)((EGWintptr)mats_out + (EGWintptr)sizeof(egwMatrix44f) + strideB_out);
    }
}

EGWsingle egwMatDeterminant33f(const egwMatrix33f* mat_in) {
    return -(mat_in->component.r1c3 * mat_in->component.r2c2 * mat_in->component.r3c1) +
            (mat_in->component.r1c2 * mat_in->component.r2c3 * mat_in->component.r3c1) +
            (mat_in->component.r1c3 * mat_in->component.r2c1 * mat_in->component.r3c2) -
            (mat_in->component.r1c1 * mat_in->component.r2c3 * mat_in->component.r3c2) -
            (mat_in->component.r1c2 * mat_in->component.r2c1 * mat_in->component.r3c3) +
            (mat_in->component.r1c1 * mat_in->component.r2c2 * mat_in->component.r3c3);    
}

EGWsingle egwMatDeterminant44f(const egwMatrix44f* mat_in) {
    EGWsingle pair[12];
    
    pair[ 0] = (mat_in->component.r1c1 * mat_in->component.r2c2) - (mat_in->component.r2c1 * mat_in->component.r1c2);
    pair[ 1] = (mat_in->component.r1c1 * mat_in->component.r3c2) - (mat_in->component.r3c1 * mat_in->component.r1c2);
    pair[ 2] = (mat_in->component.r1c1 * mat_in->component.r4c2) - (mat_in->component.r4c1 * mat_in->component.r1c2);
    pair[ 3] = (mat_in->component.r2c1 * mat_in->component.r3c2) - (mat_in->component.r3c1 * mat_in->component.r2c2);
    pair[ 4] = (mat_in->component.r2c1 * mat_in->component.r4c2) - (mat_in->component.r4c1 * mat_in->component.r2c2);
    pair[ 5] = (mat_in->component.r3c1 * mat_in->component.r4c2) - (mat_in->component.r4c1 * mat_in->component.r3c2);
    pair[ 6] = (mat_in->component.r1c3 * mat_in->component.r2c4) - (mat_in->component.r2c3 * mat_in->component.r1c4);
    pair[ 7] = (mat_in->component.r1c3 * mat_in->component.r3c4) - (mat_in->component.r3c3 * mat_in->component.r1c4);
    pair[ 8] = (mat_in->component.r1c3 * mat_in->component.r4c4) - (mat_in->component.r4c3 * mat_in->component.r1c4);
    pair[ 9] = (mat_in->component.r2c3 * mat_in->component.r3c4) - (mat_in->component.r3c3 * mat_in->component.r2c4);
    pair[10] = (mat_in->component.r2c3 * mat_in->component.r4c4) - (mat_in->component.r4c3 * mat_in->component.r2c4);
    pair[11] = (mat_in->component.r3c3 * mat_in->component.r4c4) - (mat_in->component.r4c3 * mat_in->component.r3c4);
    
    return (pair[0] * pair[11]) - (pair[1] * pair[10]) + (pair[2] * pair[9]) + (pair[3] * pair[8]) - (pair[4] * pair[7]) + (pair[5] * pair[6]);
}

void egwMatDeterminant33fv(const egwMatrix33f* mats_in, EGWsingle* dets_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *dets_out = -(mats_in->component.r1c3 * mats_in->component.r2c2 * mats_in->component.r3c1) +
                     (mats_in->component.r1c2 * mats_in->component.r2c3 * mats_in->component.r3c1) +
                     (mats_in->component.r1c3 * mats_in->component.r2c1 * mats_in->component.r3c2) -
                     (mats_in->component.r1c1 * mats_in->component.r2c3 * mats_in->component.r3c2) -
                     (mats_in->component.r1c2 * mats_in->component.r2c1 * mats_in->component.r3c3) +
                     (mats_in->component.r1c1 * mats_in->component.r2c2 * mats_in->component.r3c3);
        mats_in = (const egwMatrix33f*)((EGWintptr)mats_in + (EGWintptr)sizeof(egwMatrix33f) + strideB_in);
        dets_out = (EGWsingle*)((EGWintptr)dets_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

void egwMatDeterminant44fv(const egwMatrix44f* mats_in, EGWsingle* dets_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    EGWsingle pair[12];
    
    while(count--) {
        pair[ 0] = (mats_in->component.r1c1 * mats_in->component.r2c2) - (mats_in->component.r2c1 * mats_in->component.r1c2);
        pair[ 1] = (mats_in->component.r1c1 * mats_in->component.r3c2) - (mats_in->component.r3c1 * mats_in->component.r1c2);
        pair[ 2] = (mats_in->component.r1c1 * mats_in->component.r4c2) - (mats_in->component.r4c1 * mats_in->component.r1c2);
        pair[ 3] = (mats_in->component.r2c1 * mats_in->component.r3c2) - (mats_in->component.r3c1 * mats_in->component.r2c2);
        pair[ 4] = (mats_in->component.r2c1 * mats_in->component.r4c2) - (mats_in->component.r4c1 * mats_in->component.r2c2);
        pair[ 5] = (mats_in->component.r3c1 * mats_in->component.r4c2) - (mats_in->component.r4c1 * mats_in->component.r3c2);
        pair[ 6] = (mats_in->component.r1c3 * mats_in->component.r2c4) - (mats_in->component.r2c3 * mats_in->component.r1c4);
        pair[ 7] = (mats_in->component.r1c3 * mats_in->component.r3c4) - (mats_in->component.r3c3 * mats_in->component.r1c4);
        pair[ 8] = (mats_in->component.r1c3 * mats_in->component.r4c4) - (mats_in->component.r4c3 * mats_in->component.r1c4);
        pair[ 9] = (mats_in->component.r2c3 * mats_in->component.r3c4) - (mats_in->component.r3c3 * mats_in->component.r2c4);
        pair[10] = (mats_in->component.r2c3 * mats_in->component.r4c4) - (mats_in->component.r4c3 * mats_in->component.r2c4);
        pair[11] = (mats_in->component.r3c3 * mats_in->component.r4c4) - (mats_in->component.r4c3 * mats_in->component.r3c4);
        *dets_out = (pair[0] * pair[11]) - (pair[1] * pair[10]) + (pair[2] * pair[9]) + (pair[3] * pair[8]) - (pair[4] * pair[7]) + (pair[5] * pair[6]);
        mats_in = (const egwMatrix44f*)((EGWintptr)mats_in + (EGWintptr)sizeof(egwMatrix44f) + strideB_in);
        dets_out = (EGWsingle*)((EGWintptr)dets_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

EGWsingle egwMatDeterminantHmg33f(const egwMatrix33f* mat_in) {
    return -(mat_in->component.r1c2 * mat_in->component.r2c1) +
            (mat_in->component.r1c1 * mat_in->component.r2c2);    
}

EGWsingle egwMatDeterminantHmg44f(const egwMatrix44f* mat_in) {
    return -(mat_in->component.r1c3 * mat_in->component.r2c2 * mat_in->component.r3c1) +
            (mat_in->component.r1c2 * mat_in->component.r2c3 * mat_in->component.r3c1) +
            (mat_in->component.r1c3 * mat_in->component.r2c1 * mat_in->component.r3c2) -
            (mat_in->component.r1c1 * mat_in->component.r2c3 * mat_in->component.r3c2) -
            (mat_in->component.r1c2 * mat_in->component.r2c1 * mat_in->component.r3c3) +
            (mat_in->component.r1c1 * mat_in->component.r2c2 * mat_in->component.r3c3);
}

void egwMatDeterminantHmg33fv(const egwMatrix33f* mats_in, EGWsingle* dets_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *dets_out = -(mats_in->component.r1c2 * mats_in->component.r2c1) +
                     (mats_in->component.r1c1 * mats_in->component.r2c2);
        mats_in = (const egwMatrix33f*)((EGWintptr)mats_in + (EGWintptr)sizeof(egwMatrix33f) + strideB_in);
        dets_out = (EGWsingle*)((EGWintptr)dets_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

void egwMatDeterminantHmg44fv(const egwMatrix44f* mats_in, EGWsingle* dets_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *dets_out = -(mats_in->component.r1c3 * mats_in->component.r2c2 * mats_in->component.r3c1) +
                     (mats_in->component.r1c2 * mats_in->component.r2c3 * mats_in->component.r3c1) +
                     (mats_in->component.r1c3 * mats_in->component.r2c1 * mats_in->component.r3c2) -
                     (mats_in->component.r1c1 * mats_in->component.r2c3 * mats_in->component.r3c2) -
                     (mats_in->component.r1c2 * mats_in->component.r2c1 * mats_in->component.r3c3) +
                     (mats_in->component.r1c1 * mats_in->component.r2c2 * mats_in->component.r3c3);
        mats_in = (const egwMatrix44f*)((EGWintptr)mats_in + (EGWintptr)sizeof(egwMatrix44f) + strideB_in);
        dets_out = (EGWsingle*)((EGWintptr)dets_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

EGWsingle egwMatTrace33f(const egwMatrix33f* mat_in) {
    return mat_in->component.r1c1 + mat_in->component.r2c2 + mat_in->component.r3c3;
}

EGWsingle egwMatTrace44f(const egwMatrix44f* mat_in) {
    return mat_in->component.r1c1 + mat_in->component.r2c2 + mat_in->component.r3c3 + mat_in->component.r4c4;
}

void egwMatTrace33fv(const egwMatrix33f* mats_in, EGWsingle* trcs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *trcs_out = mats_in->component.r1c1 + mats_in->component.r2c2 + mats_in->component.r3c3;
        mats_in = (const egwMatrix33f*)((EGWintptr)mats_in + (EGWintptr)sizeof(egwMatrix33f) + strideB_in);
        trcs_out = (EGWsingle*)((EGWintptr)trcs_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

void egwMatTrace44fv(const egwMatrix44f* mats_in, EGWsingle* trcs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *trcs_out = mats_in->component.r1c1 + mats_in->component.r2c2 + mats_in->component.r3c3 + mats_in->component.r4c4;
        mats_in = (const egwMatrix44f*)((EGWintptr)mats_in + (EGWintptr)sizeof(egwMatrix44f) + strideB_in);
        trcs_out = (EGWsingle*)((EGWintptr)trcs_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

egwMatrix33f* egwMatInvert33f(const egwMatrix33f* mat_in, egwMatrix33f* mat_out) {
    egwMatrix33f temp;
    EGWsingle factor;
    
    // Calculate cofactors
    temp.component.r1c1 =  ((mat_in->component.r2c2 * mat_in->component.r3c3) - (mat_in->component.r3c2 * mat_in->component.r2c3));
    temp.component.r1c2 = -((mat_in->component.r2c1 * mat_in->component.r3c3) - (mat_in->component.r2c3 * mat_in->component.r3c1));
    temp.component.r1c3 =  ((mat_in->component.r2c1 * mat_in->component.r3c2) - (mat_in->component.r3c1 * mat_in->component.r2c2));
    temp.component.r2c1 = -((mat_in->component.r1c2 * mat_in->component.r3c3) - (mat_in->component.r1c3 * mat_in->component.r3c2));
    temp.component.r2c2 =  ((mat_in->component.r1c1 * mat_in->component.r3c3) - (mat_in->component.r1c3 * mat_in->component.r3c1));
    temp.component.r2c3 = -((mat_in->component.r1c1 * mat_in->component.r3c2) - (mat_in->component.r3c1 * mat_in->component.r1c2));
    temp.component.r3c1 =  ((mat_in->component.r1c2 * mat_in->component.r2c3) - (mat_in->component.r1c3 * mat_in->component.r2c2));
    temp.component.r3c2 = -((mat_in->component.r1c1 * mat_in->component.r2c3) - (mat_in->component.r2c1 * mat_in->component.r1c3));
    temp.component.r3c3 =  ((mat_in->component.r1c1 * mat_in->component.r2c2) - (mat_in->component.r2c1 * mat_in->component.r1c2));
    
    // Calculate factor as 1.0 / determinant
    factor = 1.0f / egwMatDeterminant33f(mat_in);
    
    // Calculate matrix inverse
    mat_out->component.r1c1 = temp.component.r1c1 * factor;
    mat_out->component.r2c1 = temp.component.r2c1 * factor;
    mat_out->component.r3c1 = temp.component.r3c1 * factor;
    mat_out->component.r1c2 = temp.component.r1c2 * factor;
    mat_out->component.r2c2 = temp.component.r2c2 * factor;
    mat_out->component.r3c2 = temp.component.r3c2 * factor;
    mat_out->component.r1c3 = temp.component.r1c3 * factor;
    mat_out->component.r2c3 = temp.component.r2c3 * factor;
    mat_out->component.r3c3 = temp.component.r3c3 * factor;
    
    return mat_out;
}

egwMatrix44f* egwMatInvert44f(const egwMatrix44f* mat_in, egwMatrix44f* mat_out) {
    egwMatrix44f temp;
    EGWsingle pair[12];
    EGWsingle factor;
    
    // Calculate pairs for first 8 cofactors
    pair[ 0] = mat_in->component.r3c3 * mat_in->component.r4c4;
    pair[ 1] = mat_in->component.r3c4 * mat_in->component.r4c3;
    pair[ 2] = mat_in->component.r3c2 * mat_in->component.r4c4;
    pair[ 3] = mat_in->component.r3c4 * mat_in->component.r4c2;
    pair[ 4] = mat_in->component.r3c2 * mat_in->component.r4c3;
    pair[ 5] = mat_in->component.r3c3 * mat_in->component.r4c2;
    pair[ 6] = mat_in->component.r3c1 * mat_in->component.r4c4;
    pair[ 7] = mat_in->component.r3c4 * mat_in->component.r4c1;
    pair[ 8] = mat_in->component.r3c1 * mat_in->component.r4c3;
    pair[ 9] = mat_in->component.r3c3 * mat_in->component.r4c1;
    pair[10] = mat_in->component.r3c1 * mat_in->component.r4c2;
    pair[11] = mat_in->component.r3c2 * mat_in->component.r4c1;
    
    // Calculate first 8 cofactors
    temp.component.r1c1 = ((pair[ 0] * mat_in->component.r2c2) + (pair[ 3] * mat_in->component.r2c3) + (pair[ 4] * mat_in->component.r2c4)) -
                           ((pair[ 1] * mat_in->component.r2c2) + (pair[ 2] * mat_in->component.r2c3) + (pair[ 5] * mat_in->component.r2c4));
    temp.component.r2c1 = ((pair[ 1] * mat_in->component.r2c1) + (pair[ 6] * mat_in->component.r2c3) + (pair[ 9] * mat_in->component.r2c4)) -
                           ((pair[ 0] * mat_in->component.r2c1) + (pair[ 7] * mat_in->component.r2c3) + (pair[ 8] * mat_in->component.r2c4));
    temp.component.r3c1 = ((pair[ 2] * mat_in->component.r2c1) + (pair[ 7] * mat_in->component.r2c2) + (pair[10] * mat_in->component.r2c4)) -
                           ((pair[ 3] * mat_in->component.r2c1) + (pair[ 6] * mat_in->component.r2c2) + (pair[11] * mat_in->component.r2c4));
    temp.component.r4c1 = ((pair[ 5] * mat_in->component.r2c1) + (pair[ 8] * mat_in->component.r2c2) + (pair[11] * mat_in->component.r2c3)) -
                           ((pair[ 4] * mat_in->component.r2c1) + (pair[ 9] * mat_in->component.r2c2) + (pair[10] * mat_in->component.r2c3));
    
    temp.component.r1c2 = ((pair[ 1] * mat_in->component.r1c2) + (pair[ 2] * mat_in->component.r1c3) + (pair[ 5] * mat_in->component.r1c4)) -
                           ((pair[ 0] * mat_in->component.r1c2) + (pair[ 3] * mat_in->component.r1c3) + (pair[ 4] * mat_in->component.r1c4));
    temp.component.r2c2 = ((pair[ 0] * mat_in->component.r1c1) + (pair[ 7] * mat_in->component.r1c3) + (pair[ 8] * mat_in->component.r1c4)) -
                           ((pair[ 1] * mat_in->component.r1c1) + (pair[ 6] * mat_in->component.r1c3) + (pair[ 9] * mat_in->component.r1c4));
    temp.component.r3c2 = ((pair[ 3] * mat_in->component.r1c1) + (pair[ 6] * mat_in->component.r1c2) + (pair[11] * mat_in->component.r1c4)) -
                           ((pair[ 2] * mat_in->component.r1c1) + (pair[ 7] * mat_in->component.r1c2) + (pair[10] * mat_in->component.r1c4));
    temp.component.r4c2 = ((pair[ 4] * mat_in->component.r1c1) + (pair[ 9] * mat_in->component.r1c2) + (pair[10] * mat_in->component.r1c3)) -
                           ((pair[ 5] * mat_in->component.r1c1) + (pair[ 8] * mat_in->component.r1c2) + (pair[11] * mat_in->component.r1c3));
    
    // Calculate pairs for second 8 cofactors
    pair[ 0] = mat_in->component.r1c3 * mat_in->component.r2c4;
    pair[ 1] = mat_in->component.r1c4 * mat_in->component.r2c3;
    pair[ 2] = mat_in->component.r1c2 * mat_in->component.r2c4;
    pair[ 3] = mat_in->component.r1c4 * mat_in->component.r2c2;
    pair[ 4] = mat_in->component.r1c2 * mat_in->component.r2c3;
    pair[ 5] = mat_in->component.r1c3 * mat_in->component.r2c2;
    pair[ 6] = mat_in->component.r1c1 * mat_in->component.r2c4;
    pair[ 7] = mat_in->component.r1c4 * mat_in->component.r2c1;
    pair[ 8] = mat_in->component.r1c1 * mat_in->component.r2c3;
    pair[ 9] = mat_in->component.r1c3 * mat_in->component.r2c1;
    pair[10] = mat_in->component.r1c1 * mat_in->component.r2c2;
    pair[11] = mat_in->component.r1c2 * mat_in->component.r2c1;
    
    // Calculate second 8 elements cofactors
    temp.component.r1c3 = ((pair[ 0] * mat_in->component.r4c2) + (pair[ 3] * mat_in->component.r4c3) + (pair[ 4] * mat_in->component.r4c4)) -
                           ((pair[ 1] * mat_in->component.r4c2) + (pair[ 2] * mat_in->component.r4c3) + (pair[ 5] * mat_in->component.r4c4));
    temp.component.r2c3 = ((pair[ 1] * mat_in->component.r4c1) + (pair[ 6] * mat_in->component.r4c3) + (pair[ 9] * mat_in->component.r4c4)) -
                           ((pair[ 0] * mat_in->component.r4c1) + (pair[ 7] * mat_in->component.r4c3) + (pair[ 8] * mat_in->component.r4c4));
    temp.component.r3c3 = ((pair[ 2] * mat_in->component.r4c1) + (pair[ 7] * mat_in->component.r4c2) + (pair[10] * mat_in->component.r4c4)) -
                           ((pair[ 3] * mat_in->component.r4c1) + (pair[ 6] * mat_in->component.r4c2) + (pair[11] * mat_in->component.r4c4));
    temp.component.r4c3 = ((pair[ 5] * mat_in->component.r4c1) + (pair[ 8] * mat_in->component.r4c2) + (pair[11] * mat_in->component.r4c3)) -
                           ((pair[ 4] * mat_in->component.r4c1) + (pair[ 9] * mat_in->component.r4c2) + (pair[10] * mat_in->component.r4c3));
    
    temp.component.r1c4 = ((pair[ 2] * mat_in->component.r3c3) + (pair[ 5] * mat_in->component.r3c4) + (pair[ 1] * mat_in->component.r3c2)) -
                           ((pair[ 4] * mat_in->component.r3c4) + (pair[ 0] * mat_in->component.r3c2) + (pair[ 3] * mat_in->component.r3c3));
    temp.component.r2c4 = ((pair[ 8] * mat_in->component.r3c4) + (pair[ 0] * mat_in->component.r3c1) + (pair[ 7] * mat_in->component.r3c3)) -
                           ((pair[ 6] * mat_in->component.r3c3) + (pair[ 9] * mat_in->component.r3c4) + (pair[ 1] * mat_in->component.r3c1));
    temp.component.r3c4 = ((pair[ 6] * mat_in->component.r3c2) + (pair[11] * mat_in->component.r3c4) + (pair[ 3] * mat_in->component.r3c1)) -
                           ((pair[10] * mat_in->component.r3c4) + (pair[ 2] * mat_in->component.r3c1) + (pair[ 7] * mat_in->component.r3c2));
    temp.component.r4c4 = ((pair[10] * mat_in->component.r3c3) + (pair[ 4] * mat_in->component.r3c1) + (pair[ 9] * mat_in->component.r3c2)) -
                           ((pair[ 8] * mat_in->component.r3c2) + (pair[11] * mat_in->component.r3c3) + (pair[ 5] * mat_in->component.r3c1));
    
    // Calculate factor as 1.0 / determinant
    factor = 1.0f / ((mat_in->component.r1c1 * temp.component.r1c1) + (mat_in->component.r1c2 * temp.component.r2c1) + (mat_in->component.r1c3 * temp.component.r3c1) + (mat_in->component.r1c4 * temp.component.r4c1));
    
    // Calculate matrix inverse
    mat_out->component.r1c1 = temp.component.r1c1 * factor;
    mat_out->component.r2c1 = temp.component.r2c1 * factor;
    mat_out->component.r3c1 = temp.component.r3c1 * factor;
    mat_out->component.r4c1 = temp.component.r4c1 * factor;
    mat_out->component.r1c2 = temp.component.r1c2 * factor;
    mat_out->component.r2c2 = temp.component.r2c2 * factor;
    mat_out->component.r3c2 = temp.component.r3c2 * factor;
    mat_out->component.r4c2 = temp.component.r4c2 * factor;
    mat_out->component.r1c3 = temp.component.r1c3 * factor;
    mat_out->component.r2c3 = temp.component.r2c3 * factor;
    mat_out->component.r3c3 = temp.component.r3c3 * factor;
    mat_out->component.r4c3 = temp.component.r4c3 * factor;
    mat_out->component.r1c4 = temp.component.r1c4 * factor;
    mat_out->component.r2c4 = temp.component.r2c4 * factor;
    mat_out->component.r3c4 = temp.component.r3c4 * factor;
    mat_out->component.r4c4 = temp.component.r4c4 * factor;
    
    return mat_out;
}

void egwMatInvert33fv(const egwMatrix33f* mats_in, egwMatrix33f* mats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    egwMatrix33f temp;
    EGWsingle factor;
    
    while(count--) {
        // Calculate cofactors
        temp.component.r1c1 =  ((mats_in->component.r2c2 * mats_in->component.r3c3) - (mats_in->component.r3c2 * mats_in->component.r2c3));
        temp.component.r1c2 = -((mats_in->component.r2c1 * mats_in->component.r3c3) - (mats_in->component.r2c3 * mats_in->component.r3c1));
        temp.component.r1c3 =  ((mats_in->component.r2c1 * mats_in->component.r3c2) - (mats_in->component.r3c1 * mats_in->component.r2c2));
        temp.component.r2c1 = -((mats_in->component.r1c2 * mats_in->component.r3c3) - (mats_in->component.r1c3 * mats_in->component.r3c2));
        temp.component.r2c2 =  ((mats_in->component.r1c1 * mats_in->component.r3c3) - (mats_in->component.r1c3 * mats_in->component.r3c1));
        temp.component.r2c3 = -((mats_in->component.r1c1 * mats_in->component.r3c2) - (mats_in->component.r3c1 * mats_in->component.r1c2));
        temp.component.r3c1 =  ((mats_in->component.r1c2 * mats_in->component.r2c3) - (mats_in->component.r1c3 * mats_in->component.r2c2));
        temp.component.r3c2 = -((mats_in->component.r1c1 * mats_in->component.r2c3) - (mats_in->component.r2c1 * mats_in->component.r1c3));
        temp.component.r3c3 =  ((mats_in->component.r1c1 * mats_in->component.r2c2) - (mats_in->component.r2c1 * mats_in->component.r1c2));
        
        // Calculate factor as 1.0 / determinant
        factor = 1.0f / egwMatDeterminant33f(mats_in);
        
        // Calculate matrix inverse
        mats_out->component.r1c1 = temp.component.r1c1 * factor;
        mats_out->component.r2c1 = temp.component.r2c1 * factor;
        mats_out->component.r3c1 = temp.component.r3c1 * factor;
        mats_out->component.r1c2 = temp.component.r1c2 * factor;
        mats_out->component.r2c2 = temp.component.r2c2 * factor;
        mats_out->component.r3c2 = temp.component.r3c2 * factor;
        mats_out->component.r1c3 = temp.component.r1c3 * factor;
        mats_out->component.r2c3 = temp.component.r2c3 * factor;
        mats_out->component.r3c3 = temp.component.r3c3 * factor;
        
        mats_in = (const egwMatrix33f*)((EGWintptr)mats_in + (EGWintptr)sizeof(egwMatrix33f) + strideB_in);
        mats_out = (egwMatrix33f*)((EGWintptr)mats_out + (EGWintptr)sizeof(egwMatrix33f) + strideB_out);
    }
}

void egwMatInvert44fv(const egwMatrix44f* mats_in, egwMatrix44f* mats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    egwMatrix44f temp;
    EGWsingle pair[12];
    EGWsingle factor;
    
    while(count--) {
        // Calculate pairs for first 8 cofactors
        pair[ 0] = mats_in->component.r3c3 * mats_in->component.r4c4;
        pair[ 1] = mats_in->component.r3c4 * mats_in->component.r4c3;
        pair[ 2] = mats_in->component.r3c2 * mats_in->component.r4c4;
        pair[ 3] = mats_in->component.r3c4 * mats_in->component.r4c2;
        pair[ 4] = mats_in->component.r3c2 * mats_in->component.r4c3;
        pair[ 5] = mats_in->component.r3c3 * mats_in->component.r4c2;
        pair[ 6] = mats_in->component.r3c1 * mats_in->component.r4c4;
        pair[ 7] = mats_in->component.r3c4 * mats_in->component.r4c1;
        pair[ 8] = mats_in->component.r3c1 * mats_in->component.r4c3;
        pair[ 9] = mats_in->component.r3c3 * mats_in->component.r4c1;
        pair[10] = mats_in->component.r3c1 * mats_in->component.r4c2;
        pair[11] = mats_in->component.r3c2 * mats_in->component.r4c1;
        
        // Calculate first 8 cofactors
        temp.component.r1c1 = ((pair[ 0] * mats_in->component.r2c2) + (pair[ 3] * mats_in->component.r2c3) + (pair[ 4] * mats_in->component.r2c4)) -
                               ((pair[ 1] * mats_in->component.r2c2) + (pair[ 2] * mats_in->component.r2c3) + (pair[ 5] * mats_in->component.r2c4));
        temp.component.r2c1 = ((pair[ 1] * mats_in->component.r2c1) + (pair[ 6] * mats_in->component.r2c3) + (pair[ 9] * mats_in->component.r2c4)) -
                               ((pair[ 0] * mats_in->component.r2c1) + (pair[ 7] * mats_in->component.r2c3) + (pair[ 8] * mats_in->component.r2c4));
        temp.component.r3c1 = ((pair[ 2] * mats_in->component.r2c1) + (pair[ 7] * mats_in->component.r2c2) + (pair[10] * mats_in->component.r2c4)) -
                               ((pair[ 3] * mats_in->component.r2c1) + (pair[ 6] * mats_in->component.r2c2) + (pair[11] * mats_in->component.r2c4));
        temp.component.r4c1 = ((pair[ 5] * mats_in->component.r2c1) + (pair[ 8] * mats_in->component.r2c2) + (pair[11] * mats_in->component.r2c3)) -
                               ((pair[ 4] * mats_in->component.r2c1) + (pair[ 9] * mats_in->component.r2c2) + (pair[10] * mats_in->component.r2c3));
        
        temp.component.r1c2 = ((pair[ 1] * mats_in->component.r1c2) + (pair[ 2] * mats_in->component.r1c3) + (pair[ 5] * mats_in->component.r1c4)) -
                               ((pair[ 0] * mats_in->component.r1c2) + (pair[ 3] * mats_in->component.r1c3) + (pair[ 4] * mats_in->component.r1c4));
        temp.component.r2c2 = ((pair[ 0] * mats_in->component.r1c1) + (pair[ 7] * mats_in->component.r1c3) + (pair[ 8] * mats_in->component.r1c4)) -
                               ((pair[ 1] * mats_in->component.r1c1) + (pair[ 6] * mats_in->component.r1c3) + (pair[ 9] * mats_in->component.r1c4));
        temp.component.r3c2 = ((pair[ 3] * mats_in->component.r1c1) + (pair[ 6] * mats_in->component.r1c2) + (pair[11] * mats_in->component.r1c4)) -
                               ((pair[ 2] * mats_in->component.r1c1) + (pair[ 7] * mats_in->component.r1c2) + (pair[10] * mats_in->component.r1c4));
        temp.component.r4c2 = ((pair[ 4] * mats_in->component.r1c1) + (pair[ 9] * mats_in->component.r1c2) + (pair[10] * mats_in->component.r1c3)) -
                               ((pair[ 5] * mats_in->component.r1c1) + (pair[ 8] * mats_in->component.r1c2) + (pair[11] * mats_in->component.r1c3));
        
        // Calculate pairs for second 8 cofactors
        pair[ 0] = mats_in->component.r1c3 * mats_in->component.r2c4;
        pair[ 1] = mats_in->component.r1c4 * mats_in->component.r2c3;
        pair[ 2] = mats_in->component.r1c2 * mats_in->component.r2c4;
        pair[ 3] = mats_in->component.r1c4 * mats_in->component.r2c2;
        pair[ 4] = mats_in->component.r1c2 * mats_in->component.r2c3;
        pair[ 5] = mats_in->component.r1c3 * mats_in->component.r2c2;
        pair[ 6] = mats_in->component.r1c1 * mats_in->component.r2c4;
        pair[ 7] = mats_in->component.r1c4 * mats_in->component.r2c1;
        pair[ 8] = mats_in->component.r1c1 * mats_in->component.r2c3;
        pair[ 9] = mats_in->component.r1c3 * mats_in->component.r2c1;
        pair[10] = mats_in->component.r1c1 * mats_in->component.r2c2;
        pair[11] = mats_in->component.r1c2 * mats_in->component.r2c1;
        
        // Calculate second 8 elements cofactors
        temp.component.r1c3 = ((pair[ 0] * mats_in->component.r4c2) + (pair[ 3] * mats_in->component.r4c3) + (pair[ 4] * mats_in->component.r4c4)) -
                               ((pair[ 1] * mats_in->component.r4c2) + (pair[ 2] * mats_in->component.r4c3) + (pair[ 5] * mats_in->component.r4c4));
        temp.component.r2c3 = ((pair[ 1] * mats_in->component.r4c1) + (pair[ 6] * mats_in->component.r4c3) + (pair[ 9] * mats_in->component.r4c4)) -
                               ((pair[ 0] * mats_in->component.r4c1) + (pair[ 7] * mats_in->component.r4c3) + (pair[ 8] * mats_in->component.r4c4));
        temp.component.r3c3 = ((pair[ 2] * mats_in->component.r4c1) + (pair[ 7] * mats_in->component.r4c2) + (pair[10] * mats_in->component.r4c4)) -
                               ((pair[ 3] * mats_in->component.r4c1) + (pair[ 6] * mats_in->component.r4c2) + (pair[11] * mats_in->component.r4c4));
        temp.component.r4c3 = ((pair[ 5] * mats_in->component.r4c1) + (pair[ 8] * mats_in->component.r4c2) + (pair[11] * mats_in->component.r4c3)) -
                               ((pair[ 4] * mats_in->component.r4c1) + (pair[ 9] * mats_in->component.r4c2) + (pair[10] * mats_in->component.r4c3));
        
        temp.component.r1c4 = ((pair[ 2] * mats_in->component.r3c3) + (pair[ 5] * mats_in->component.r3c4) + (pair[ 1] * mats_in->component.r3c2)) -
                               ((pair[ 4] * mats_in->component.r3c4) + (pair[ 0] * mats_in->component.r3c2) + (pair[ 3] * mats_in->component.r3c3));
        temp.component.r2c4 = ((pair[ 8] * mats_in->component.r3c4) + (pair[ 0] * mats_in->component.r3c1) + (pair[ 7] * mats_in->component.r3c3)) -
                               ((pair[ 6] * mats_in->component.r3c3) + (pair[ 9] * mats_in->component.r3c4) + (pair[ 1] * mats_in->component.r3c1));
        temp.component.r3c4 = ((pair[ 6] * mats_in->component.r3c2) + (pair[11] * mats_in->component.r3c4) + (pair[ 3] * mats_in->component.r3c1)) -
                               ((pair[10] * mats_in->component.r3c4) + (pair[ 2] * mats_in->component.r3c1) + (pair[ 7] * mats_in->component.r3c2));
        temp.component.r4c4 = ((pair[10] * mats_in->component.r3c3) + (pair[ 4] * mats_in->component.r3c1) + (pair[ 9] * mats_in->component.r3c2)) -
                               ((pair[ 8] * mats_in->component.r3c2) + (pair[11] * mats_in->component.r3c3) + (pair[ 5] * mats_in->component.r3c1));
        
        // Calculate factor as 1.0 / determinant
        factor = 1.0f / ((mats_in->component.r1c1 * temp.component.r1c1) + (mats_in->component.r1c2 * temp.component.r2c1) + (mats_in->component.r1c3 * temp.component.r3c1) + (mats_in->component.r1c4 * temp.component.r4c1));
        
        // Calculate matrix inverse
        mats_out->component.r1c1 = temp.component.r1c1 * factor;
        mats_out->component.r2c1 = temp.component.r2c1 * factor;
        mats_out->component.r3c1 = temp.component.r3c1 * factor;
        mats_out->component.r4c1 = temp.component.r4c1 * factor;
        mats_out->component.r1c2 = temp.component.r1c2 * factor;
        mats_out->component.r2c2 = temp.component.r2c2 * factor;
        mats_out->component.r3c2 = temp.component.r3c2 * factor;
        mats_out->component.r4c2 = temp.component.r4c2 * factor;
        mats_out->component.r1c3 = temp.component.r1c3 * factor;
        mats_out->component.r2c3 = temp.component.r2c3 * factor;
        mats_out->component.r3c3 = temp.component.r3c3 * factor;
        mats_out->component.r4c3 = temp.component.r4c3 * factor;
        mats_out->component.r1c4 = temp.component.r1c4 * factor;
        mats_out->component.r2c4 = temp.component.r2c4 * factor;
        mats_out->component.r3c4 = temp.component.r3c4 * factor;
        mats_out->component.r4c4 = temp.component.r4c4 * factor;
        
        mats_in = (const egwMatrix44f*)((EGWintptr)mats_in + (EGWintptr)sizeof(egwMatrix44f) + strideB_in);
        mats_out = (egwMatrix44f*)((EGWintptr)mats_out + (EGWintptr)sizeof(egwMatrix44f) + strideB_out);
    }
}

egwMatrix33f* egwMatInvertDet33f(const egwMatrix33f* mat_lhs, const EGWsingle det_rhs, egwMatrix33f* mat_out) {
    egwMatrix33f temp;
    EGWsingle factor;
    
    // Calculate cofactors
    temp.component.r1c1 =  ((mat_lhs->component.r2c2 * mat_lhs->component.r3c3) - (mat_lhs->component.r3c2 * mat_lhs->component.r2c3));
    temp.component.r1c2 = -((mat_lhs->component.r2c1 * mat_lhs->component.r3c3) - (mat_lhs->component.r2c3 * mat_lhs->component.r3c1));
    temp.component.r1c3 =  ((mat_lhs->component.r2c1 * mat_lhs->component.r3c2) - (mat_lhs->component.r3c1 * mat_lhs->component.r2c2));
    temp.component.r2c1 = -((mat_lhs->component.r1c2 * mat_lhs->component.r3c3) - (mat_lhs->component.r1c3 * mat_lhs->component.r3c2));
    temp.component.r2c2 =  ((mat_lhs->component.r1c1 * mat_lhs->component.r3c3) - (mat_lhs->component.r1c3 * mat_lhs->component.r3c1));
    temp.component.r2c3 = -((mat_lhs->component.r1c1 * mat_lhs->component.r3c2) - (mat_lhs->component.r3c1 * mat_lhs->component.r1c2));
    temp.component.r3c1 =  ((mat_lhs->component.r1c2 * mat_lhs->component.r2c3) - (mat_lhs->component.r1c3 * mat_lhs->component.r2c2));
    temp.component.r3c2 = -((mat_lhs->component.r1c1 * mat_lhs->component.r2c3) - (mat_lhs->component.r2c1 * mat_lhs->component.r1c3));
    temp.component.r3c3 =  ((mat_lhs->component.r1c1 * mat_lhs->component.r2c2) - (mat_lhs->component.r2c1 * mat_lhs->component.r1c2));
    
    // Calculate factor as 1.0 / determinant
    factor = 1.0f / det_rhs;
    
    // Calculate matrix inverse
    mat_out->component.r1c1 = temp.component.r1c1 * factor;
    mat_out->component.r2c1 = temp.component.r2c1 * factor;
    mat_out->component.r3c1 = temp.component.r3c1 * factor;
    mat_out->component.r1c2 = temp.component.r1c2 * factor;
    mat_out->component.r2c2 = temp.component.r2c2 * factor;
    mat_out->component.r3c2 = temp.component.r3c2 * factor;
    mat_out->component.r1c3 = temp.component.r1c3 * factor;
    mat_out->component.r2c3 = temp.component.r2c3 * factor;
    mat_out->component.r3c3 = temp.component.r3c3 * factor;
    
    return mat_out;
}

egwMatrix44f* egwMatInvertDet44f(const egwMatrix44f* mat_lhs, const EGWsingle det_rhs, egwMatrix44f* mat_out) {
    egwMatrix44f temp;
    EGWsingle pair[12];
    EGWsingle factor;
    
    // Calculate pairs for first 8 cofactors
    pair[ 0] = mat_lhs->component.r3c3 * mat_lhs->component.r4c4;
    pair[ 1] = mat_lhs->component.r3c4 * mat_lhs->component.r4c3;
    pair[ 2] = mat_lhs->component.r3c2 * mat_lhs->component.r4c4;
    pair[ 3] = mat_lhs->component.r3c4 * mat_lhs->component.r4c2;
    pair[ 4] = mat_lhs->component.r3c2 * mat_lhs->component.r4c3;
    pair[ 5] = mat_lhs->component.r3c3 * mat_lhs->component.r4c2;
    pair[ 6] = mat_lhs->component.r3c1 * mat_lhs->component.r4c4;
    pair[ 7] = mat_lhs->component.r3c4 * mat_lhs->component.r4c1;
    pair[ 8] = mat_lhs->component.r3c1 * mat_lhs->component.r4c3;
    pair[ 9] = mat_lhs->component.r3c3 * mat_lhs->component.r4c1;
    pair[10] = mat_lhs->component.r3c1 * mat_lhs->component.r4c2;
    pair[11] = mat_lhs->component.r3c2 * mat_lhs->component.r4c1;
    
    // Calculate first 8 cofactors
    temp.component.r1c1 = ((pair[ 0] * mat_lhs->component.r2c2) + (pair[ 3] * mat_lhs->component.r2c3) + (pair[ 4] * mat_lhs->component.r2c4)) -
                           ((pair[ 1] * mat_lhs->component.r2c2) + (pair[ 2] * mat_lhs->component.r2c3) + (pair[ 5] * mat_lhs->component.r2c4));
    temp.component.r2c1 = ((pair[ 1] * mat_lhs->component.r2c1) + (pair[ 6] * mat_lhs->component.r2c3) + (pair[ 9] * mat_lhs->component.r2c4)) -
                           ((pair[ 0] * mat_lhs->component.r2c1) + (pair[ 7] * mat_lhs->component.r2c3) + (pair[ 8] * mat_lhs->component.r2c4));
    temp.component.r3c1 = ((pair[ 2] * mat_lhs->component.r2c1) + (pair[ 7] * mat_lhs->component.r2c2) + (pair[10] * mat_lhs->component.r2c4)) -
                           ((pair[ 3] * mat_lhs->component.r2c1) + (pair[ 6] * mat_lhs->component.r2c2) + (pair[11] * mat_lhs->component.r2c4));
    temp.component.r4c1 = ((pair[ 5] * mat_lhs->component.r2c1) + (pair[ 8] * mat_lhs->component.r2c2) + (pair[11] * mat_lhs->component.r2c3)) -
                           ((pair[ 4] * mat_lhs->component.r2c1) + (pair[ 9] * mat_lhs->component.r2c2) + (pair[10] * mat_lhs->component.r2c3));
    
    temp.component.r1c2 = ((pair[ 1] * mat_lhs->component.r1c2) + (pair[ 2] * mat_lhs->component.r1c3) + (pair[ 5] * mat_lhs->component.r1c4)) -
                           ((pair[ 0] * mat_lhs->component.r1c2) + (pair[ 3] * mat_lhs->component.r1c3) + (pair[ 4] * mat_lhs->component.r1c4));
    temp.component.r2c2 = ((pair[ 0] * mat_lhs->component.r1c1) + (pair[ 7] * mat_lhs->component.r1c3) + (pair[ 8] * mat_lhs->component.r1c4)) -
                           ((pair[ 1] * mat_lhs->component.r1c1) + (pair[ 6] * mat_lhs->component.r1c3) + (pair[ 9] * mat_lhs->component.r1c4));
    temp.component.r3c2 = ((pair[ 3] * mat_lhs->component.r1c1) + (pair[ 6] * mat_lhs->component.r1c2) + (pair[11] * mat_lhs->component.r1c4)) -
                           ((pair[ 2] * mat_lhs->component.r1c1) + (pair[ 7] * mat_lhs->component.r1c2) + (pair[10] * mat_lhs->component.r1c4));
    temp.component.r4c2 = ((pair[ 4] * mat_lhs->component.r1c1) + (pair[ 9] * mat_lhs->component.r1c2) + (pair[10] * mat_lhs->component.r1c3)) -
                           ((pair[ 5] * mat_lhs->component.r1c1) + (pair[ 8] * mat_lhs->component.r1c2) + (pair[11] * mat_lhs->component.r1c3));
    
    // Calculate pairs for second 8 cofactors
    pair[ 0] = mat_lhs->component.r1c3 * mat_lhs->component.r2c4;
    pair[ 1] = mat_lhs->component.r1c4 * mat_lhs->component.r2c3;
    pair[ 2] = mat_lhs->component.r1c2 * mat_lhs->component.r2c4;
    pair[ 3] = mat_lhs->component.r1c4 * mat_lhs->component.r2c2;
    pair[ 4] = mat_lhs->component.r1c2 * mat_lhs->component.r2c3;
    pair[ 5] = mat_lhs->component.r1c3 * mat_lhs->component.r2c2;
    pair[ 6] = mat_lhs->component.r1c1 * mat_lhs->component.r2c4;
    pair[ 7] = mat_lhs->component.r1c4 * mat_lhs->component.r2c1;
    pair[ 8] = mat_lhs->component.r1c1 * mat_lhs->component.r2c3;
    pair[ 9] = mat_lhs->component.r1c3 * mat_lhs->component.r2c1;
    pair[10] = mat_lhs->component.r1c1 * mat_lhs->component.r2c2;
    pair[11] = mat_lhs->component.r1c2 * mat_lhs->component.r2c1;
    
    // Calculate second 8 elements cofactors
    temp.component.r1c3 = ((pair[ 0] * mat_lhs->component.r4c2) + (pair[ 3] * mat_lhs->component.r4c3) + (pair[ 4] * mat_lhs->component.r4c4)) -
                           ((pair[ 1] * mat_lhs->component.r4c2) + (pair[ 2] * mat_lhs->component.r4c3) + (pair[ 5] * mat_lhs->component.r4c4));
    temp.component.r2c3 = ((pair[ 1] * mat_lhs->component.r4c1) + (pair[ 6] * mat_lhs->component.r4c3) + (pair[ 9] * mat_lhs->component.r4c4)) -
                           ((pair[ 0] * mat_lhs->component.r4c1) + (pair[ 7] * mat_lhs->component.r4c3) + (pair[ 8] * mat_lhs->component.r4c4));
    temp.component.r3c3 = ((pair[ 2] * mat_lhs->component.r4c1) + (pair[ 7] * mat_lhs->component.r4c2) + (pair[10] * mat_lhs->component.r4c4)) -
                           ((pair[ 3] * mat_lhs->component.r4c1) + (pair[ 6] * mat_lhs->component.r4c2) + (pair[11] * mat_lhs->component.r4c4));
    temp.component.r4c3 = ((pair[ 5] * mat_lhs->component.r4c1) + (pair[ 8] * mat_lhs->component.r4c2) + (pair[11] * mat_lhs->component.r4c3)) -
                           ((pair[ 4] * mat_lhs->component.r4c1) + (pair[ 9] * mat_lhs->component.r4c2) + (pair[10] * mat_lhs->component.r4c3));
    
    temp.component.r1c4 = ((pair[ 2] * mat_lhs->component.r3c3) + (pair[ 5] * mat_lhs->component.r3c4) + (pair[ 1] * mat_lhs->component.r3c2)) -
                           ((pair[ 4] * mat_lhs->component.r3c4) + (pair[ 0] * mat_lhs->component.r3c2) + (pair[ 3] * mat_lhs->component.r3c3));
    temp.component.r2c4 = ((pair[ 8] * mat_lhs->component.r3c4) + (pair[ 0] * mat_lhs->component.r3c1) + (pair[ 7] * mat_lhs->component.r3c3)) -
                           ((pair[ 6] * mat_lhs->component.r3c3) + (pair[ 9] * mat_lhs->component.r3c4) + (pair[ 1] * mat_lhs->component.r3c1));
    temp.component.r3c4 = ((pair[ 6] * mat_lhs->component.r3c2) + (pair[11] * mat_lhs->component.r3c4) + (pair[ 3] * mat_lhs->component.r3c1)) -
                           ((pair[10] * mat_lhs->component.r3c4) + (pair[ 2] * mat_lhs->component.r3c1) + (pair[ 7] * mat_lhs->component.r3c2));
    temp.component.r4c4 = ((pair[10] * mat_lhs->component.r3c3) + (pair[ 4] * mat_lhs->component.r3c1) + (pair[ 9] * mat_lhs->component.r3c2)) -
                           ((pair[ 8] * mat_lhs->component.r3c2) + (pair[11] * mat_lhs->component.r3c3) + (pair[ 5] * mat_lhs->component.r3c1));
    
    // Calculate factor as 1.0 / determinant
    factor = 1.0f / det_rhs;
    
    // Calculate matrix inverse
    mat_out->component.r1c1 = temp.component.r1c1 * factor;
    mat_out->component.r2c1 = temp.component.r2c1 * factor;
    mat_out->component.r3c1 = temp.component.r3c1 * factor;
    mat_out->component.r4c1 = temp.component.r4c1 * factor;
    mat_out->component.r1c2 = temp.component.r1c2 * factor;
    mat_out->component.r2c2 = temp.component.r2c2 * factor;
    mat_out->component.r3c2 = temp.component.r3c2 * factor;
    mat_out->component.r4c2 = temp.component.r4c2 * factor;
    mat_out->component.r1c3 = temp.component.r1c3 * factor;
    mat_out->component.r2c3 = temp.component.r2c3 * factor;
    mat_out->component.r3c3 = temp.component.r3c3 * factor;
    mat_out->component.r4c3 = temp.component.r4c3 * factor;
    mat_out->component.r1c4 = temp.component.r1c4 * factor;
    mat_out->component.r2c4 = temp.component.r2c4 * factor;
    mat_out->component.r3c4 = temp.component.r3c4 * factor;
    mat_out->component.r4c4 = temp.component.r4c4 * factor;
    
    return mat_out;
}

void egwMatInvertDet33fv(const egwMatrix33f* mats_lhs, const EGWsingle* dets_rhs, egwMatrix33f* mats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    egwMatrix33f temp;
    EGWsingle factor;
    
    while(count--) {
        // Calculate cofactors
        temp.component.r1c1 =  ((mats_lhs->component.r2c2 * mats_lhs->component.r3c3) - (mats_lhs->component.r3c2 * mats_lhs->component.r2c3));
        temp.component.r1c2 = -((mats_lhs->component.r2c1 * mats_lhs->component.r3c3) - (mats_lhs->component.r2c3 * mats_lhs->component.r3c1));
        temp.component.r1c3 =  ((mats_lhs->component.r2c1 * mats_lhs->component.r3c2) - (mats_lhs->component.r3c1 * mats_lhs->component.r2c2));
        temp.component.r2c1 = -((mats_lhs->component.r1c2 * mats_lhs->component.r3c3) - (mats_lhs->component.r1c3 * mats_lhs->component.r3c2));
        temp.component.r2c2 =  ((mats_lhs->component.r1c1 * mats_lhs->component.r3c3) - (mats_lhs->component.r1c3 * mats_lhs->component.r3c1));
        temp.component.r2c3 = -((mats_lhs->component.r1c1 * mats_lhs->component.r3c2) - (mats_lhs->component.r3c1 * mats_lhs->component.r1c2));
        temp.component.r3c1 =  ((mats_lhs->component.r1c2 * mats_lhs->component.r2c3) - (mats_lhs->component.r1c3 * mats_lhs->component.r2c2));
        temp.component.r3c2 = -((mats_lhs->component.r1c1 * mats_lhs->component.r2c3) - (mats_lhs->component.r2c1 * mats_lhs->component.r1c3));
        temp.component.r3c3 =  ((mats_lhs->component.r1c1 * mats_lhs->component.r2c2) - (mats_lhs->component.r2c1 * mats_lhs->component.r1c2));
        
        // Calculate factor as 1.0 / determinant
        factor = 1.0f / *dets_rhs;
        
        // Calculate matrix inverse
        mats_out->component.r1c1 = temp.component.r1c1 * factor;
        mats_out->component.r2c1 = temp.component.r2c1 * factor;
        mats_out->component.r3c1 = temp.component.r3c1 * factor;
        mats_out->component.r1c2 = temp.component.r1c2 * factor;
        mats_out->component.r2c2 = temp.component.r2c2 * factor;
        mats_out->component.r3c2 = temp.component.r3c2 * factor;
        mats_out->component.r1c3 = temp.component.r1c3 * factor;
        mats_out->component.r2c3 = temp.component.r2c3 * factor;
        mats_out->component.r3c3 = temp.component.r3c3 * factor;
        
        mats_lhs = (const egwMatrix33f*)((EGWintptr)mats_lhs + (EGWintptr)sizeof(egwMatrix33f) + strideB_lhs);
        dets_rhs = (const EGWsingle*)((EGWintptr)dets_rhs + (EGWintptr)sizeof(EGWsingle) + strideB_rhs);
        mats_out = (egwMatrix33f*)((EGWintptr)mats_out + (EGWintptr)sizeof(egwMatrix33f) + strideB_out);
    }
}

void egwMatInvertDet44fv(const egwMatrix44f* mats_lhs, const EGWsingle* dets_rhs, egwMatrix44f* mats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    egwMatrix44f temp;
    EGWsingle pair[12];
    EGWsingle factor;
    
    while(count--) {
        // Calculate pairs for first 8 cofactors
        pair[ 0] = mats_lhs->component.r3c3 * mats_lhs->component.r4c4;
        pair[ 1] = mats_lhs->component.r3c4 * mats_lhs->component.r4c3;
        pair[ 2] = mats_lhs->component.r3c2 * mats_lhs->component.r4c4;
        pair[ 3] = mats_lhs->component.r3c4 * mats_lhs->component.r4c2;
        pair[ 4] = mats_lhs->component.r3c2 * mats_lhs->component.r4c3;
        pair[ 5] = mats_lhs->component.r3c3 * mats_lhs->component.r4c2;
        pair[ 6] = mats_lhs->component.r3c1 * mats_lhs->component.r4c4;
        pair[ 7] = mats_lhs->component.r3c4 * mats_lhs->component.r4c1;
        pair[ 8] = mats_lhs->component.r3c1 * mats_lhs->component.r4c3;
        pair[ 9] = mats_lhs->component.r3c3 * mats_lhs->component.r4c1;
        pair[10] = mats_lhs->component.r3c1 * mats_lhs->component.r4c2;
        pair[11] = mats_lhs->component.r3c2 * mats_lhs->component.r4c1;
        
        // Calculate first 8 cofactors
        temp.component.r1c1 = ((pair[ 0] * mats_lhs->component.r2c2) + (pair[ 3] * mats_lhs->component.r2c3) + (pair[ 4] * mats_lhs->component.r2c4)) -
                               ((pair[ 1] * mats_lhs->component.r2c2) + (pair[ 2] * mats_lhs->component.r2c3) + (pair[ 5] * mats_lhs->component.r2c4));
        temp.component.r2c1 = ((pair[ 1] * mats_lhs->component.r2c1) + (pair[ 6] * mats_lhs->component.r2c3) + (pair[ 9] * mats_lhs->component.r2c4)) -
                               ((pair[ 0] * mats_lhs->component.r2c1) + (pair[ 7] * mats_lhs->component.r2c3) + (pair[ 8] * mats_lhs->component.r2c4));
        temp.component.r3c1 = ((pair[ 2] * mats_lhs->component.r2c1) + (pair[ 7] * mats_lhs->component.r2c2) + (pair[10] * mats_lhs->component.r2c4)) -
                               ((pair[ 3] * mats_lhs->component.r2c1) + (pair[ 6] * mats_lhs->component.r2c2) + (pair[11] * mats_lhs->component.r2c4));
        temp.component.r4c1 = ((pair[ 5] * mats_lhs->component.r2c1) + (pair[ 8] * mats_lhs->component.r2c2) + (pair[11] * mats_lhs->component.r2c3)) -
                               ((pair[ 4] * mats_lhs->component.r2c1) + (pair[ 9] * mats_lhs->component.r2c2) + (pair[10] * mats_lhs->component.r2c3));
        
        temp.component.r1c2 = ((pair[ 1] * mats_lhs->component.r1c2) + (pair[ 2] * mats_lhs->component.r1c3) + (pair[ 5] * mats_lhs->component.r1c4)) -
                               ((pair[ 0] * mats_lhs->component.r1c2) + (pair[ 3] * mats_lhs->component.r1c3) + (pair[ 4] * mats_lhs->component.r1c4));
        temp.component.r2c2 = ((pair[ 0] * mats_lhs->component.r1c1) + (pair[ 7] * mats_lhs->component.r1c3) + (pair[ 8] * mats_lhs->component.r1c4)) -
                               ((pair[ 1] * mats_lhs->component.r1c1) + (pair[ 6] * mats_lhs->component.r1c3) + (pair[ 9] * mats_lhs->component.r1c4));
        temp.component.r3c2 = ((pair[ 3] * mats_lhs->component.r1c1) + (pair[ 6] * mats_lhs->component.r1c2) + (pair[11] * mats_lhs->component.r1c4)) -
                               ((pair[ 2] * mats_lhs->component.r1c1) + (pair[ 7] * mats_lhs->component.r1c2) + (pair[10] * mats_lhs->component.r1c4));
        temp.component.r4c2 = ((pair[ 4] * mats_lhs->component.r1c1) + (pair[ 9] * mats_lhs->component.r1c2) + (pair[10] * mats_lhs->component.r1c3)) -
                               ((pair[ 5] * mats_lhs->component.r1c1) + (pair[ 8] * mats_lhs->component.r1c2) + (pair[11] * mats_lhs->component.r1c3));
        
        // Calculate pairs for second 8 cofactors
        pair[ 0] = mats_lhs->component.r1c3 * mats_lhs->component.r2c4;
        pair[ 1] = mats_lhs->component.r1c4 * mats_lhs->component.r2c3;
        pair[ 2] = mats_lhs->component.r1c2 * mats_lhs->component.r2c4;
        pair[ 3] = mats_lhs->component.r1c4 * mats_lhs->component.r2c2;
        pair[ 4] = mats_lhs->component.r1c2 * mats_lhs->component.r2c3;
        pair[ 5] = mats_lhs->component.r1c3 * mats_lhs->component.r2c2;
        pair[ 6] = mats_lhs->component.r1c1 * mats_lhs->component.r2c4;
        pair[ 7] = mats_lhs->component.r1c4 * mats_lhs->component.r2c1;
        pair[ 8] = mats_lhs->component.r1c1 * mats_lhs->component.r2c3;
        pair[ 9] = mats_lhs->component.r1c3 * mats_lhs->component.r2c1;
        pair[10] = mats_lhs->component.r1c1 * mats_lhs->component.r2c2;
        pair[11] = mats_lhs->component.r1c2 * mats_lhs->component.r2c1;
        
        // Calculate second 8 elements cofactors
        temp.component.r1c3 = ((pair[ 0] * mats_lhs->component.r4c2) + (pair[ 3] * mats_lhs->component.r4c3) + (pair[ 4] * mats_lhs->component.r4c4)) -
                               ((pair[ 1] * mats_lhs->component.r4c2) + (pair[ 2] * mats_lhs->component.r4c3) + (pair[ 5] * mats_lhs->component.r4c4));
        temp.component.r2c3 = ((pair[ 1] * mats_lhs->component.r4c1) + (pair[ 6] * mats_lhs->component.r4c3) + (pair[ 9] * mats_lhs->component.r4c4)) -
                               ((pair[ 0] * mats_lhs->component.r4c1) + (pair[ 7] * mats_lhs->component.r4c3) + (pair[ 8] * mats_lhs->component.r4c4));
        temp.component.r3c3 = ((pair[ 2] * mats_lhs->component.r4c1) + (pair[ 7] * mats_lhs->component.r4c2) + (pair[10] * mats_lhs->component.r4c4)) -
                               ((pair[ 3] * mats_lhs->component.r4c1) + (pair[ 6] * mats_lhs->component.r4c2) + (pair[11] * mats_lhs->component.r4c4));
        temp.component.r4c3 = ((pair[ 5] * mats_lhs->component.r4c1) + (pair[ 8] * mats_lhs->component.r4c2) + (pair[11] * mats_lhs->component.r4c3)) -
                               ((pair[ 4] * mats_lhs->component.r4c1) + (pair[ 9] * mats_lhs->component.r4c2) + (pair[10] * mats_lhs->component.r4c3));
        
        temp.component.r1c4 = ((pair[ 2] * mats_lhs->component.r3c3) + (pair[ 5] * mats_lhs->component.r3c4) + (pair[ 1] * mats_lhs->component.r3c2)) -
                               ((pair[ 4] * mats_lhs->component.r3c4) + (pair[ 0] * mats_lhs->component.r3c2) + (pair[ 3] * mats_lhs->component.r3c3));
        temp.component.r2c4 = ((pair[ 8] * mats_lhs->component.r3c4) + (pair[ 0] * mats_lhs->component.r3c1) + (pair[ 7] * mats_lhs->component.r3c3)) -
                               ((pair[ 6] * mats_lhs->component.r3c3) + (pair[ 9] * mats_lhs->component.r3c4) + (pair[ 1] * mats_lhs->component.r3c1));
        temp.component.r3c4 = ((pair[ 6] * mats_lhs->component.r3c2) + (pair[11] * mats_lhs->component.r3c4) + (pair[ 3] * mats_lhs->component.r3c1)) -
                               ((pair[10] * mats_lhs->component.r3c4) + (pair[ 2] * mats_lhs->component.r3c1) + (pair[ 7] * mats_lhs->component.r3c2));
        temp.component.r4c4 = ((pair[10] * mats_lhs->component.r3c3) + (pair[ 4] * mats_lhs->component.r3c1) + (pair[ 9] * mats_lhs->component.r3c2)) -
                               ((pair[ 8] * mats_lhs->component.r3c2) + (pair[11] * mats_lhs->component.r3c3) + (pair[ 5] * mats_lhs->component.r3c1));
        
        // Calculate factor as 1.0 / determinant
        factor = 1.0f / *dets_rhs;
        
        // Calculate matrix inverse
        mats_out->component.r1c1 = temp.component.r1c1 * factor;
        mats_out->component.r2c1 = temp.component.r2c1 * factor;
        mats_out->component.r3c1 = temp.component.r3c1 * factor;
        mats_out->component.r4c1 = temp.component.r4c1 * factor;
        mats_out->component.r1c2 = temp.component.r1c2 * factor;
        mats_out->component.r2c2 = temp.component.r2c2 * factor;
        mats_out->component.r3c2 = temp.component.r3c2 * factor;
        mats_out->component.r4c2 = temp.component.r4c2 * factor;
        mats_out->component.r1c3 = temp.component.r1c3 * factor;
        mats_out->component.r2c3 = temp.component.r2c3 * factor;
        mats_out->component.r3c3 = temp.component.r3c3 * factor;
        mats_out->component.r4c3 = temp.component.r4c3 * factor;
        mats_out->component.r1c4 = temp.component.r1c4 * factor;
        mats_out->component.r2c4 = temp.component.r2c4 * factor;
        mats_out->component.r3c4 = temp.component.r3c4 * factor;
        mats_out->component.r4c4 = temp.component.r4c4 * factor;
        
        mats_lhs = (const egwMatrix44f*)((EGWintptr)mats_lhs + (EGWintptr)sizeof(egwMatrix44f) + strideB_lhs);
        dets_rhs = (const EGWsingle*)((EGWintptr)dets_rhs + (EGWintptr)sizeof(EGWsingle) + strideB_rhs);
        mats_out = (egwMatrix44f*)((EGWintptr)mats_out + (EGWintptr)sizeof(egwMatrix44f) + strideB_out);
    }
}

egwMatrix33f* egwMatInvertOtg33f(const egwMatrix33f* mat_in, egwMatrix33f* mat_out) {
    if(mat_out == mat_in) {
        egwVector2f temp;
        temp.axis.x = mat_in->component.r2c1; mat_out->component.r2c1 = mat_in->component.r1c2; mat_out->component.r1c2 = temp.axis.x;
        temp.axis.x = -((mat_out->component.r1c1 * mat_in->component.r1c3) + (mat_out->component.r1c2 * mat_in->component.r2c3));
        temp.axis.y = -((mat_out->component.r2c1 * mat_in->component.r1c3) + (mat_out->component.r2c2 * mat_in->component.r2c3));
        mat_out->component.r1c3 = temp.axis.x;
        mat_out->component.r2c3 = temp.axis.y;
    } else {
        mat_out->component.r1c1 = mat_in->component.r1c1; mat_out->component.r1c2 = mat_in->component.r2c1;
        mat_out->component.r2c1 = mat_in->component.r1c2; mat_out->component.r2c2 = mat_in->component.r2c2;
        mat_out->component.r3c1 = mat_in->component.r1c3; mat_out->component.r3c2 = mat_in->component.r2c3; mat_out->component.r3c3 = mat_in->component.r3c3;
        mat_out->component.r1c3 = -((mat_out->component.r1c1 * mat_in->component.r1c3) + (mat_out->component.r1c2 * mat_in->component.r2c3));
        mat_out->component.r2c3 = -((mat_out->component.r2c1 * mat_in->component.r1c3) + (mat_out->component.r2c2 * mat_in->component.r2c3));
    }
    
    return mat_out;
}

egwMatrix44f* egwMatInvertOtg44f(const egwMatrix44f* mat_in, egwMatrix44f* mat_out) {
    if(mat_out == mat_in) {
        egwVector3f temp;
        temp.axis.x = mat_in->component.r2c1; mat_out->component.r2c1 = mat_in->component.r1c2; mat_out->component.r1c2 = temp.axis.x;
        temp.axis.x = mat_in->component.r3c1; mat_out->component.r3c1 = mat_in->component.r1c3; mat_out->component.r1c3 = temp.axis.x;
        temp.axis.x = mat_in->component.r3c2; mat_out->component.r3c2 = mat_in->component.r2c3; mat_out->component.r2c3 = temp.axis.x;
        temp.axis.x = -((mat_out->component.r1c1 * mat_in->component.r1c4) + (mat_out->component.r1c2 * mat_in->component.r2c4) + (mat_out->component.r1c3 * mat_in->component.r3c4));
        temp.axis.y = -((mat_out->component.r2c1 * mat_in->component.r1c4) + (mat_out->component.r2c2 * mat_in->component.r2c4) + (mat_out->component.r2c3 * mat_in->component.r3c4));
        temp.axis.z = -((mat_out->component.r3c1 * mat_in->component.r1c4) + (mat_out->component.r3c2 * mat_in->component.r2c4) + (mat_out->component.r3c3 * mat_in->component.r3c4));
        mat_out->component.r1c4 = temp.axis.x;
        mat_out->component.r2c4 = temp.axis.y;
        mat_out->component.r3c4 = temp.axis.z;
    } else {
        mat_out->component.r1c1 = mat_in->component.r1c1; mat_out->component.r1c2 = mat_in->component.r2c1; mat_out->component.r1c3 = mat_in->component.r3c1;
        mat_out->component.r2c1 = mat_in->component.r1c2; mat_out->component.r2c2 = mat_in->component.r2c2; mat_out->component.r2c3 = mat_in->component.r3c2;
        mat_out->component.r3c1 = mat_in->component.r1c3; mat_out->component.r3c2 = mat_in->component.r2c3; mat_out->component.r3c3 = mat_in->component.r3c3;
        mat_out->component.r4c1 = mat_in->component.r4c1; mat_out->component.r4c2 = mat_in->component.r4c2; mat_out->component.r4c3 = mat_in->component.r4c3; mat_out->component.r4c4 = mat_in->component.r4c4;
        mat_out->component.r1c4 = -((mat_out->component.r1c1 * mat_in->component.r1c4) + (mat_out->component.r1c2 * mat_in->component.r2c4) + (mat_out->component.r1c3 * mat_in->component.r3c4));
        mat_out->component.r2c4 = -((mat_out->component.r2c1 * mat_in->component.r1c4) + (mat_out->component.r2c2 * mat_in->component.r2c4) + (mat_out->component.r2c3 * mat_in->component.r3c4));
        mat_out->component.r3c4 = -((mat_out->component.r3c1 * mat_in->component.r1c4) + (mat_out->component.r3c2 * mat_in->component.r2c4) + (mat_out->component.r3c3 * mat_in->component.r3c4));
    }
    
    return mat_out;
}

void egwMatInvertOtg33fv(const egwMatrix33f* mats_in, egwMatrix33f* mats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        if(mats_out == mats_in) {
            egwVector2f temp;
            temp.axis.x = mats_in->component.r2c1; mats_out->component.r2c1 = mats_in->component.r1c2; mats_out->component.r1c2 = temp.axis.x;
            temp.axis.x = -((mats_out->component.r1c1 * mats_in->component.r1c3) + (mats_out->component.r1c2 * mats_in->component.r2c3));
            temp.axis.y = -((mats_out->component.r2c1 * mats_in->component.r1c3) + (mats_out->component.r2c2 * mats_in->component.r2c3));
            mats_out->component.r1c3 = temp.axis.x;
            mats_out->component.r2c3 = temp.axis.y;
        } else {
            mats_out->component.r1c1 = mats_in->component.r1c1; mats_out->component.r1c2 = mats_in->component.r2c1;
            mats_out->component.r2c1 = mats_in->component.r1c2; mats_out->component.r2c2 = mats_in->component.r2c2;
            mats_out->component.r3c1 = mats_in->component.r1c3; mats_out->component.r3c2 = mats_in->component.r2c3; mats_out->component.r3c3 = mats_in->component.r3c3;
            mats_out->component.r1c3 = -((mats_out->component.r1c1 * mats_in->component.r1c3) + (mats_out->component.r1c2 * mats_in->component.r2c3));
            mats_out->component.r2c3 = -((mats_out->component.r2c1 * mats_in->component.r1c3) + (mats_out->component.r2c2 * mats_in->component.r2c3));
        }
        
        mats_in = (const egwMatrix33f*)((EGWintptr)mats_in + (EGWintptr)sizeof(egwMatrix33f) + strideB_in);
        mats_out = (egwMatrix33f*)((EGWintptr)mats_out + (EGWintptr)sizeof(egwMatrix33f) + strideB_out);
    }
}

void egwMatInvertOtg44fv(const egwMatrix44f* mats_in, egwMatrix44f* mats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        if(mats_out == mats_in) {
            egwVector3f temp;
            temp.axis.x = mats_in->component.r2c1; mats_out->component.r2c1 = mats_in->component.r1c2; mats_out->component.r1c2 = temp.axis.x;
            temp.axis.x = mats_in->component.r3c1; mats_out->component.r3c1 = mats_in->component.r1c3; mats_out->component.r1c3 = temp.axis.x;
            temp.axis.x = mats_in->component.r3c2; mats_out->component.r3c2 = mats_in->component.r2c3; mats_out->component.r2c3 = temp.axis.x;
            temp.axis.x = -((mats_out->component.r1c1 * mats_in->component.r1c4) + (mats_out->component.r1c2 * mats_in->component.r2c4) + (mats_out->component.r1c3 * mats_in->component.r3c4));
            temp.axis.y = -((mats_out->component.r2c1 * mats_in->component.r1c4) + (mats_out->component.r2c2 * mats_in->component.r2c4) + (mats_out->component.r2c3 * mats_in->component.r3c4));
            temp.axis.z = -((mats_out->component.r3c1 * mats_in->component.r1c4) + (mats_out->component.r3c2 * mats_in->component.r2c4) + (mats_out->component.r3c3 * mats_in->component.r3c4));
            mats_out->component.r1c4 = temp.axis.x;
            mats_out->component.r2c4 = temp.axis.y;
            mats_out->component.r3c4 = temp.axis.z;
        } else {
            mats_out->component.r1c1 = mats_in->component.r1c1; mats_out->component.r1c2 = mats_in->component.r2c1; mats_out->component.r1c3 = mats_in->component.r3c1;
            mats_out->component.r2c1 = mats_in->component.r1c2; mats_out->component.r2c2 = mats_in->component.r2c2; mats_out->component.r2c3 = mats_in->component.r3c2;
            mats_out->component.r3c1 = mats_in->component.r1c3; mats_out->component.r3c2 = mats_in->component.r2c3; mats_out->component.r3c3 = mats_in->component.r3c3;
            mats_out->component.r4c1 = mats_in->component.r4c1; mats_out->component.r4c2 = mats_in->component.r4c2; mats_out->component.r4c3 = mats_in->component.r4c3; mats_out->component.r4c4 = mats_in->component.r4c4;
            mats_out->component.r1c4 = -((mats_out->component.r1c1 * mats_in->component.r1c4) + (mats_out->component.r1c2 * mats_in->component.r2c4) + (mats_out->component.r1c3 * mats_in->component.r3c4));
            mats_out->component.r2c4 = -((mats_out->component.r2c1 * mats_in->component.r1c4) + (mats_out->component.r2c2 * mats_in->component.r2c4) + (mats_out->component.r2c3 * mats_in->component.r3c4));
            mats_out->component.r3c4 = -((mats_out->component.r3c1 * mats_in->component.r1c4) + (mats_out->component.r3c2 * mats_in->component.r2c4) + (mats_out->component.r3c3 * mats_in->component.r3c4));
        }
        
        mats_in = (const egwMatrix44f*)((EGWintptr)mats_in + (EGWintptr)sizeof(egwMatrix44f) + strideB_in);
        mats_out = (egwMatrix44f*)((EGWintptr)mats_out + (EGWintptr)sizeof(egwMatrix44f) + strideB_out);
    }
}

egwMatrix33f* egwMatAdd33f(const egwMatrix33f* mat_lhs, const egwMatrix33f* mat_rhs, egwMatrix33f* mat_out) {
    mat_out->component.r1c1 = mat_lhs->component.r1c1 + mat_rhs->component.r1c1; mat_out->component.r1c2 = mat_lhs->component.r1c2 + mat_rhs->component.r1c2; mat_out->component.r1c3 = mat_lhs->component.r1c3 + mat_rhs->component.r1c3;
    mat_out->component.r2c1 = mat_lhs->component.r2c1 + mat_rhs->component.r2c1; mat_out->component.r2c2 = mat_lhs->component.r2c2 + mat_rhs->component.r2c2; mat_out->component.r2c3 = mat_lhs->component.r2c3 + mat_rhs->component.r2c3;
    mat_out->component.r3c1 = mat_lhs->component.r3c1 + mat_rhs->component.r3c1; mat_out->component.r3c2 = mat_lhs->component.r3c2 + mat_rhs->component.r3c2; mat_out->component.r3c3 = mat_lhs->component.r3c3 + mat_rhs->component.r3c3;
    return mat_out;
}

egwMatrix44f* egwMatAdd44f(const egwMatrix44f* mat_lhs, const egwMatrix44f* mat_rhs, egwMatrix44f* mat_out) {
    mat_out->component.r1c1 = mat_lhs->component.r1c1 + mat_rhs->component.r1c1; mat_out->component.r1c2 = mat_lhs->component.r1c2 + mat_rhs->component.r1c2; mat_out->component.r1c3 = mat_lhs->component.r1c3 + mat_rhs->component.r1c3; mat_out->component.r1c4 = mat_lhs->component.r1c4 + mat_rhs->component.r1c4;
    mat_out->component.r2c1 = mat_lhs->component.r2c1 + mat_rhs->component.r2c1; mat_out->component.r2c2 = mat_lhs->component.r2c2 + mat_rhs->component.r2c2; mat_out->component.r2c3 = mat_lhs->component.r2c3 + mat_rhs->component.r2c3; mat_out->component.r2c4 = mat_lhs->component.r2c4 + mat_rhs->component.r2c4;
    mat_out->component.r3c1 = mat_lhs->component.r3c1 + mat_rhs->component.r3c1; mat_out->component.r3c2 = mat_lhs->component.r3c2 + mat_rhs->component.r3c2; mat_out->component.r3c3 = mat_lhs->component.r3c3 + mat_rhs->component.r3c3; mat_out->component.r3c4 = mat_lhs->component.r3c4 + mat_rhs->component.r3c4;
    mat_out->component.r4c1 = mat_lhs->component.r4c1 + mat_rhs->component.r4c1; mat_out->component.r4c2 = mat_lhs->component.r4c2 + mat_rhs->component.r4c2; mat_out->component.r4c3 = mat_lhs->component.r4c3 + mat_rhs->component.r4c3; mat_out->component.r4c4 = mat_lhs->component.r4c4 + mat_rhs->component.r4c4;
    return mat_out;
}

void egwMatAdd33fv(const egwMatrix33f* mats_lhs, const egwMatrix33f* mats_rhs, egwMatrix33f* mats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        mats_out->component.r1c1 = mats_lhs->component.r1c1 + mats_rhs->component.r1c1; mats_out->component.r1c2 = mats_lhs->component.r1c2 + mats_rhs->component.r1c2; mats_out->component.r1c3 = mats_lhs->component.r1c3 + mats_rhs->component.r1c3;
        mats_out->component.r2c1 = mats_lhs->component.r2c1 + mats_rhs->component.r2c1; mats_out->component.r2c2 = mats_lhs->component.r2c2 + mats_rhs->component.r2c2; mats_out->component.r2c3 = mats_lhs->component.r2c3 + mats_rhs->component.r2c3;
        mats_out->component.r3c1 = mats_lhs->component.r3c1 + mats_rhs->component.r3c1; mats_out->component.r3c2 = mats_lhs->component.r3c2 + mats_rhs->component.r3c2; mats_out->component.r3c3 = mats_lhs->component.r3c3 + mats_rhs->component.r3c3;
        mats_lhs = (const egwMatrix33f*)((EGWintptr)mats_lhs + (EGWintptr)sizeof(egwMatrix33f) + strideB_lhs);
        mats_rhs = (const egwMatrix33f*)((EGWintptr)mats_rhs + (EGWintptr)sizeof(egwMatrix33f) + strideB_rhs);
        mats_out = (egwMatrix33f*)((EGWintptr)mats_out + (EGWintptr)sizeof(egwMatrix33f) + strideB_out);
    }
}

void egwMatAdd44fv(const egwMatrix44f* mats_lhs, const egwMatrix44f* mats_rhs, egwMatrix44f* mats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        mats_out->component.r1c1 = mats_lhs->component.r1c1 + mats_rhs->component.r1c1; mats_out->component.r1c2 = mats_lhs->component.r1c2 + mats_rhs->component.r1c2; mats_out->component.r1c3 = mats_lhs->component.r1c3 + mats_rhs->component.r1c3; mats_out->component.r1c4 = mats_lhs->component.r1c4 + mats_rhs->component.r1c4;
        mats_out->component.r2c1 = mats_lhs->component.r2c1 + mats_rhs->component.r2c1; mats_out->component.r2c2 = mats_lhs->component.r2c2 + mats_rhs->component.r2c2; mats_out->component.r2c3 = mats_lhs->component.r2c3 + mats_rhs->component.r2c3; mats_out->component.r2c4 = mats_lhs->component.r2c4 + mats_rhs->component.r2c4;
        mats_out->component.r3c1 = mats_lhs->component.r3c1 + mats_rhs->component.r3c1; mats_out->component.r3c2 = mats_lhs->component.r3c2 + mats_rhs->component.r3c2; mats_out->component.r3c3 = mats_lhs->component.r3c3 + mats_rhs->component.r3c3; mats_out->component.r3c4 = mats_lhs->component.r3c4 + mats_rhs->component.r3c4;
        mats_out->component.r4c1 = mats_lhs->component.r4c1 + mats_rhs->component.r4c1; mats_out->component.r4c2 = mats_lhs->component.r4c2 + mats_rhs->component.r4c2; mats_out->component.r4c3 = mats_lhs->component.r4c3 + mats_rhs->component.r4c3; mats_out->component.r4c4 = mats_lhs->component.r4c4 + mats_rhs->component.r4c4;
        mats_lhs = (const egwMatrix44f*)((EGWintptr)mats_lhs + (EGWintptr)sizeof(egwMatrix44f) + strideB_lhs);
        mats_rhs = (const egwMatrix44f*)((EGWintptr)mats_rhs + (EGWintptr)sizeof(egwMatrix44f) + strideB_rhs);
        mats_out = (egwMatrix44f*)((EGWintptr)mats_out + (EGWintptr)sizeof(egwMatrix44f) + strideB_out);
    }
}

egwMatrix33f* egwMatSubtract33f(const egwMatrix33f* mat_lhs, const egwMatrix33f* mat_rhs, egwMatrix33f* mat_out) {
    mat_out->component.r1c1 = mat_lhs->component.r1c1 - mat_rhs->component.r1c1; mat_out->component.r1c2 = mat_lhs->component.r1c2 - mat_rhs->component.r1c2; mat_out->component.r1c3 = mat_lhs->component.r1c3 - mat_rhs->component.r1c3;
    mat_out->component.r2c1 = mat_lhs->component.r2c1 - mat_rhs->component.r2c1; mat_out->component.r2c2 = mat_lhs->component.r2c2 - mat_rhs->component.r2c2; mat_out->component.r2c3 = mat_lhs->component.r2c3 - mat_rhs->component.r2c3;
    mat_out->component.r3c1 = mat_lhs->component.r3c1 - mat_rhs->component.r3c1; mat_out->component.r3c2 = mat_lhs->component.r3c2 - mat_rhs->component.r3c2; mat_out->component.r3c3 = mat_lhs->component.r3c3 - mat_rhs->component.r3c3;
    return mat_out;
}

egwMatrix44f* egwMatSubtract44f(const egwMatrix44f* mat_lhs, const egwMatrix44f* mat_rhs, egwMatrix44f* mat_out) {
    mat_out->component.r1c1 = mat_lhs->component.r1c1 - mat_rhs->component.r1c1; mat_out->component.r1c2 = mat_lhs->component.r1c2 - mat_rhs->component.r1c2; mat_out->component.r1c3 = mat_lhs->component.r1c3 - mat_rhs->component.r1c3; mat_out->component.r1c4 = mat_lhs->component.r1c4 - mat_rhs->component.r1c4;
    mat_out->component.r2c1 = mat_lhs->component.r2c1 - mat_rhs->component.r2c1; mat_out->component.r2c2 = mat_lhs->component.r2c2 - mat_rhs->component.r2c2; mat_out->component.r2c3 = mat_lhs->component.r2c3 - mat_rhs->component.r2c3; mat_out->component.r2c4 = mat_lhs->component.r2c4 - mat_rhs->component.r2c4;
    mat_out->component.r3c1 = mat_lhs->component.r3c1 - mat_rhs->component.r3c1; mat_out->component.r3c2 = mat_lhs->component.r3c2 - mat_rhs->component.r3c2; mat_out->component.r3c3 = mat_lhs->component.r3c3 - mat_rhs->component.r3c3; mat_out->component.r3c4 = mat_lhs->component.r3c4 - mat_rhs->component.r3c4;
    mat_out->component.r4c1 = mat_lhs->component.r4c1 - mat_rhs->component.r4c1; mat_out->component.r4c2 = mat_lhs->component.r4c2 - mat_rhs->component.r4c2; mat_out->component.r4c3 = mat_lhs->component.r4c3 - mat_rhs->component.r4c3; mat_out->component.r4c4 = mat_lhs->component.r4c4 - mat_rhs->component.r4c4;
    return mat_out;
}

void egwMatSubtract33fv(const egwMatrix33f* mats_lhs, const egwMatrix33f* mats_rhs, egwMatrix33f* mats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        mats_out->component.r1c1 = mats_lhs->component.r1c1 - mats_rhs->component.r1c1; mats_out->component.r1c2 = mats_lhs->component.r1c2 - mats_rhs->component.r1c2; mats_out->component.r1c3 = mats_lhs->component.r1c3 - mats_rhs->component.r1c3;
        mats_out->component.r2c1 = mats_lhs->component.r2c1 - mats_rhs->component.r2c1; mats_out->component.r2c2 = mats_lhs->component.r2c2 - mats_rhs->component.r2c2; mats_out->component.r2c3 = mats_lhs->component.r2c3 - mats_rhs->component.r2c3;
        mats_out->component.r3c1 = mats_lhs->component.r3c1 - mats_rhs->component.r3c1; mats_out->component.r3c2 = mats_lhs->component.r3c2 - mats_rhs->component.r3c2; mats_out->component.r3c3 = mats_lhs->component.r3c3 - mats_rhs->component.r3c3;
        mats_lhs = (const egwMatrix33f*)((EGWintptr)mats_lhs + (EGWintptr)sizeof(egwMatrix33f) + strideB_lhs);
        mats_rhs = (const egwMatrix33f*)((EGWintptr)mats_rhs + (EGWintptr)sizeof(egwMatrix33f) + strideB_rhs);
        mats_out = (egwMatrix33f*)((EGWintptr)mats_out + (EGWintptr)sizeof(egwMatrix33f) + strideB_out);
    }
}

void egwMatSubtract44fv(const egwMatrix44f* mats_lhs, const egwMatrix44f* mats_rhs, egwMatrix44f* mats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        mats_out->component.r1c1 = mats_lhs->component.r1c1 - mats_rhs->component.r1c1; mats_out->component.r1c2 = mats_lhs->component.r1c2 - mats_rhs->component.r1c2; mats_out->component.r1c3 = mats_lhs->component.r1c3 - mats_rhs->component.r1c3; mats_out->component.r1c4 = mats_lhs->component.r1c4 - mats_rhs->component.r1c4;
        mats_out->component.r2c1 = mats_lhs->component.r2c1 - mats_rhs->component.r2c1; mats_out->component.r2c2 = mats_lhs->component.r2c2 - mats_rhs->component.r2c2; mats_out->component.r2c3 = mats_lhs->component.r2c3 - mats_rhs->component.r2c3; mats_out->component.r2c4 = mats_lhs->component.r2c4 - mats_rhs->component.r2c4;
        mats_out->component.r3c1 = mats_lhs->component.r3c1 - mats_rhs->component.r3c1; mats_out->component.r3c2 = mats_lhs->component.r3c2 - mats_rhs->component.r3c2; mats_out->component.r3c3 = mats_lhs->component.r3c3 - mats_rhs->component.r3c3; mats_out->component.r3c4 = mats_lhs->component.r3c4 - mats_rhs->component.r3c4;
        mats_out->component.r4c1 = mats_lhs->component.r4c1 - mats_rhs->component.r4c1; mats_out->component.r4c2 = mats_lhs->component.r4c2 - mats_rhs->component.r4c2; mats_out->component.r4c3 = mats_lhs->component.r4c3 - mats_rhs->component.r4c3; mats_out->component.r4c4 = mats_lhs->component.r4c4 - mats_rhs->component.r4c4;
        mats_lhs = (const egwMatrix44f*)((EGWintptr)mats_lhs + (EGWintptr)sizeof(egwMatrix44f) + strideB_lhs);
        mats_rhs = (const egwMatrix44f*)((EGWintptr)mats_rhs + (EGWintptr)sizeof(egwMatrix44f) + strideB_rhs);
        mats_out = (egwMatrix44f*)((EGWintptr)mats_out + (EGWintptr)sizeof(egwMatrix44f) + strideB_out);
    }
}

egwMatrix33f* egwMatMultiply33f(const egwMatrix33f* mat_lhs, const egwMatrix33f* mat_rhs, egwMatrix33f* mat_out) {
    if(mat_lhs == mat_out || mat_rhs == mat_out) {
        egwMatrix33f temp;
        temp.component.r1c1 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c1) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c1) + (mat_lhs->component.r1c3 * mat_rhs->component.r3c1);
        temp.component.r1c2 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c2) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c2) + (mat_lhs->component.r1c3 * mat_rhs->component.r3c2);
        temp.component.r1c3 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c3) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c3) + (mat_lhs->component.r1c3 * mat_rhs->component.r3c3);
        temp.component.r2c1 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c1) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c1) + (mat_lhs->component.r2c3 * mat_rhs->component.r3c1);
        temp.component.r2c2 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c2) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c2) + (mat_lhs->component.r2c3 * mat_rhs->component.r3c2);
        temp.component.r2c3 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c3) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c3) + (mat_lhs->component.r2c3 * mat_rhs->component.r3c3);
        temp.component.r3c1 = (mat_lhs->component.r3c1 * mat_rhs->component.r1c1) + (mat_lhs->component.r3c2 * mat_rhs->component.r2c1) + (mat_lhs->component.r3c3 * mat_rhs->component.r3c1);
        temp.component.r3c2 = (mat_lhs->component.r3c1 * mat_rhs->component.r1c2) + (mat_lhs->component.r3c2 * mat_rhs->component.r2c2) + (mat_lhs->component.r3c3 * mat_rhs->component.r3c2);
        temp.component.r3c3 = (mat_lhs->component.r3c1 * mat_rhs->component.r1c3) + (mat_lhs->component.r3c2 * mat_rhs->component.r2c3) + (mat_lhs->component.r3c3 * mat_rhs->component.r3c3);
        mat_out->component.r1c1 = temp.component.r1c1; mat_out->component.r1c2 = temp.component.r1c2; mat_out->component.r1c3 = temp.component.r1c3;
        mat_out->component.r2c1 = temp.component.r2c1; mat_out->component.r2c2 = temp.component.r2c2; mat_out->component.r2c3 = temp.component.r2c3;
        mat_out->component.r3c1 = temp.component.r3c1; mat_out->component.r3c2 = temp.component.r3c2; mat_out->component.r3c3 = temp.component.r3c3;
    } else {
        mat_out->component.r1c1 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c1) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c1) + (mat_lhs->component.r1c3 * mat_rhs->component.r3c1);
        mat_out->component.r1c2 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c2) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c2) + (mat_lhs->component.r1c3 * mat_rhs->component.r3c2);
        mat_out->component.r1c3 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c3) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c3) + (mat_lhs->component.r1c3 * mat_rhs->component.r3c3);
        mat_out->component.r2c1 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c1) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c1) + (mat_lhs->component.r2c3 * mat_rhs->component.r3c1);
        mat_out->component.r2c2 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c2) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c2) + (mat_lhs->component.r2c3 * mat_rhs->component.r3c2);
        mat_out->component.r2c3 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c3) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c3) + (mat_lhs->component.r2c3 * mat_rhs->component.r3c3);
        mat_out->component.r3c1 = (mat_lhs->component.r3c1 * mat_rhs->component.r1c1) + (mat_lhs->component.r3c2 * mat_rhs->component.r2c1) + (mat_lhs->component.r3c3 * mat_rhs->component.r3c1);
        mat_out->component.r3c2 = (mat_lhs->component.r3c1 * mat_rhs->component.r1c2) + (mat_lhs->component.r3c2 * mat_rhs->component.r2c2) + (mat_lhs->component.r3c3 * mat_rhs->component.r3c2);
        mat_out->component.r3c3 = (mat_lhs->component.r3c1 * mat_rhs->component.r1c3) + (mat_lhs->component.r3c2 * mat_rhs->component.r2c3) + (mat_lhs->component.r3c3 * mat_rhs->component.r3c3);
    }
    
    return mat_out;
}

egwMatrix44f* egwMatMultiply44f(const egwMatrix44f* mat_lhs, const egwMatrix44f* mat_rhs, egwMatrix44f* mat_out) {
    if(mat_lhs == mat_out || mat_rhs == mat_out) {
        egwMatrix44f temp;
        temp.component.r1c1 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c1) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c1) + (mat_lhs->component.r1c3 * mat_rhs->component.r3c1) + (mat_lhs->component.r1c4 * mat_rhs->component.r4c1);
        temp.component.r1c2 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c2) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c2) + (mat_lhs->component.r1c3 * mat_rhs->component.r3c2) + (mat_lhs->component.r1c4 * mat_rhs->component.r4c2);
        temp.component.r1c3 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c3) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c3) + (mat_lhs->component.r1c3 * mat_rhs->component.r3c3) + (mat_lhs->component.r1c4 * mat_rhs->component.r4c3);
        temp.component.r1c4 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c4) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c4) + (mat_lhs->component.r1c3 * mat_rhs->component.r3c4) + (mat_lhs->component.r1c4 * mat_rhs->component.r4c4);
        temp.component.r2c1 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c1) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c1) + (mat_lhs->component.r2c3 * mat_rhs->component.r3c1) + (mat_lhs->component.r2c4 * mat_rhs->component.r4c1);
        temp.component.r2c2 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c2) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c2) + (mat_lhs->component.r2c3 * mat_rhs->component.r3c2) + (mat_lhs->component.r2c4 * mat_rhs->component.r4c2);
        temp.component.r2c3 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c3) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c3) + (mat_lhs->component.r2c3 * mat_rhs->component.r3c3) + (mat_lhs->component.r2c4 * mat_rhs->component.r4c3);
        temp.component.r2c4 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c4) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c4) + (mat_lhs->component.r2c3 * mat_rhs->component.r3c4) + (mat_lhs->component.r2c4 * mat_rhs->component.r4c4);
        temp.component.r3c1 = (mat_lhs->component.r3c1 * mat_rhs->component.r1c1) + (mat_lhs->component.r3c2 * mat_rhs->component.r2c1) + (mat_lhs->component.r3c3 * mat_rhs->component.r3c1) + (mat_lhs->component.r3c4 * mat_rhs->component.r4c1);
        temp.component.r3c2 = (mat_lhs->component.r3c1 * mat_rhs->component.r1c2) + (mat_lhs->component.r3c2 * mat_rhs->component.r2c2) + (mat_lhs->component.r3c3 * mat_rhs->component.r3c2) + (mat_lhs->component.r3c4 * mat_rhs->component.r4c2);
        temp.component.r3c3 = (mat_lhs->component.r3c1 * mat_rhs->component.r1c3) + (mat_lhs->component.r3c2 * mat_rhs->component.r2c3) + (mat_lhs->component.r3c3 * mat_rhs->component.r3c3) + (mat_lhs->component.r3c4 * mat_rhs->component.r4c3);
        temp.component.r3c4 = (mat_lhs->component.r3c1 * mat_rhs->component.r1c4) + (mat_lhs->component.r3c2 * mat_rhs->component.r2c4) + (mat_lhs->component.r3c3 * mat_rhs->component.r3c4) + (mat_lhs->component.r3c4 * mat_rhs->component.r4c4);
        temp.component.r4c1 = (mat_lhs->component.r4c1 * mat_rhs->component.r1c1) + (mat_lhs->component.r4c2 * mat_rhs->component.r2c1) + (mat_lhs->component.r4c3 * mat_rhs->component.r3c1) + (mat_lhs->component.r4c4 * mat_rhs->component.r4c1);
        temp.component.r4c2 = (mat_lhs->component.r4c1 * mat_rhs->component.r1c2) + (mat_lhs->component.r4c2 * mat_rhs->component.r2c2) + (mat_lhs->component.r4c3 * mat_rhs->component.r3c2) + (mat_lhs->component.r4c4 * mat_rhs->component.r4c2);
        temp.component.r4c3 = (mat_lhs->component.r4c1 * mat_rhs->component.r1c3) + (mat_lhs->component.r4c2 * mat_rhs->component.r2c3) + (mat_lhs->component.r4c3 * mat_rhs->component.r3c3) + (mat_lhs->component.r4c4 * mat_rhs->component.r4c3);
        temp.component.r4c4 = (mat_lhs->component.r4c1 * mat_rhs->component.r1c4) + (mat_lhs->component.r4c2 * mat_rhs->component.r2c4) + (mat_lhs->component.r4c3 * mat_rhs->component.r3c4) + (mat_lhs->component.r4c4 * mat_rhs->component.r4c4);
        mat_out->component.r1c1 = temp.component.r1c1; mat_out->component.r1c2 = temp.component.r1c2; mat_out->component.r1c3 = temp.component.r1c3; mat_out->component.r1c4 = temp.component.r1c4;
        mat_out->component.r2c1 = temp.component.r2c1; mat_out->component.r2c2 = temp.component.r2c2; mat_out->component.r2c3 = temp.component.r2c3; mat_out->component.r2c4 = temp.component.r2c4;
        mat_out->component.r3c1 = temp.component.r3c1; mat_out->component.r3c2 = temp.component.r3c2; mat_out->component.r3c3 = temp.component.r3c3; mat_out->component.r3c4 = temp.component.r3c4;
        mat_out->component.r4c1 = temp.component.r4c1; mat_out->component.r4c2 = temp.component.r4c2; mat_out->component.r4c3 = temp.component.r4c3; mat_out->component.r4c4 = temp.component.r4c4;
    } else {
        mat_out->component.r1c1 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c1) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c1) + (mat_lhs->component.r1c3 * mat_rhs->component.r3c1) + (mat_lhs->component.r1c4 * mat_rhs->component.r4c1);
        mat_out->component.r1c2 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c2) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c2) + (mat_lhs->component.r1c3 * mat_rhs->component.r3c2) + (mat_lhs->component.r1c4 * mat_rhs->component.r4c2);
        mat_out->component.r1c3 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c3) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c3) + (mat_lhs->component.r1c3 * mat_rhs->component.r3c3) + (mat_lhs->component.r1c4 * mat_rhs->component.r4c3);
        mat_out->component.r1c4 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c4) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c4) + (mat_lhs->component.r1c3 * mat_rhs->component.r3c4) + (mat_lhs->component.r1c4 * mat_rhs->component.r4c4);
        mat_out->component.r2c1 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c1) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c1) + (mat_lhs->component.r2c3 * mat_rhs->component.r3c1) + (mat_lhs->component.r2c4 * mat_rhs->component.r4c1);
        mat_out->component.r2c2 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c2) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c2) + (mat_lhs->component.r2c3 * mat_rhs->component.r3c2) + (mat_lhs->component.r2c4 * mat_rhs->component.r4c2);
        mat_out->component.r2c3 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c3) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c3) + (mat_lhs->component.r2c3 * mat_rhs->component.r3c3) + (mat_lhs->component.r2c4 * mat_rhs->component.r4c3);
        mat_out->component.r2c4 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c4) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c4) + (mat_lhs->component.r2c3 * mat_rhs->component.r3c4) + (mat_lhs->component.r2c4 * mat_rhs->component.r4c4);
        mat_out->component.r3c1 = (mat_lhs->component.r3c1 * mat_rhs->component.r1c1) + (mat_lhs->component.r3c2 * mat_rhs->component.r2c1) + (mat_lhs->component.r3c3 * mat_rhs->component.r3c1) + (mat_lhs->component.r3c4 * mat_rhs->component.r4c1);
        mat_out->component.r3c2 = (mat_lhs->component.r3c1 * mat_rhs->component.r1c2) + (mat_lhs->component.r3c2 * mat_rhs->component.r2c2) + (mat_lhs->component.r3c3 * mat_rhs->component.r3c2) + (mat_lhs->component.r3c4 * mat_rhs->component.r4c2);
        mat_out->component.r3c3 = (mat_lhs->component.r3c1 * mat_rhs->component.r1c3) + (mat_lhs->component.r3c2 * mat_rhs->component.r2c3) + (mat_lhs->component.r3c3 * mat_rhs->component.r3c3) + (mat_lhs->component.r3c4 * mat_rhs->component.r4c3);
        mat_out->component.r3c4 = (mat_lhs->component.r3c1 * mat_rhs->component.r1c4) + (mat_lhs->component.r3c2 * mat_rhs->component.r2c4) + (mat_lhs->component.r3c3 * mat_rhs->component.r3c4) + (mat_lhs->component.r3c4 * mat_rhs->component.r4c4);
        mat_out->component.r4c1 = (mat_lhs->component.r4c1 * mat_rhs->component.r1c1) + (mat_lhs->component.r4c2 * mat_rhs->component.r2c1) + (mat_lhs->component.r4c3 * mat_rhs->component.r3c1) + (mat_lhs->component.r4c4 * mat_rhs->component.r4c1);
        mat_out->component.r4c2 = (mat_lhs->component.r4c1 * mat_rhs->component.r1c2) + (mat_lhs->component.r4c2 * mat_rhs->component.r2c2) + (mat_lhs->component.r4c3 * mat_rhs->component.r3c2) + (mat_lhs->component.r4c4 * mat_rhs->component.r4c2);
        mat_out->component.r4c3 = (mat_lhs->component.r4c1 * mat_rhs->component.r1c3) + (mat_lhs->component.r4c2 * mat_rhs->component.r2c3) + (mat_lhs->component.r4c3 * mat_rhs->component.r3c3) + (mat_lhs->component.r4c4 * mat_rhs->component.r4c3);
        mat_out->component.r4c4 = (mat_lhs->component.r4c1 * mat_rhs->component.r1c4) + (mat_lhs->component.r4c2 * mat_rhs->component.r2c4) + (mat_lhs->component.r4c3 * mat_rhs->component.r3c4) + (mat_lhs->component.r4c4 * mat_rhs->component.r4c4);
    }
    
    return mat_out;
}

void egwMatMultiply33fv(const egwMatrix33f* mats_lhs, const egwMatrix33f* mats_rhs, egwMatrix33f* mats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        if(mats_lhs == mats_out || mats_rhs == mats_out) {
            egwMatrix33f temp;
            temp.component.r1c1 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c1) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c1) + (mats_lhs->component.r1c3 * mats_rhs->component.r3c1);
            temp.component.r1c2 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c2) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c2) + (mats_lhs->component.r1c3 * mats_rhs->component.r3c2);
            temp.component.r1c3 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c3) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c3) + (mats_lhs->component.r1c3 * mats_rhs->component.r3c3);
            temp.component.r2c1 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c1) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c1) + (mats_lhs->component.r2c3 * mats_rhs->component.r3c1);
            temp.component.r2c2 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c2) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c2) + (mats_lhs->component.r2c3 * mats_rhs->component.r3c2);
            temp.component.r2c3 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c3) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c3) + (mats_lhs->component.r2c3 * mats_rhs->component.r3c3);
            temp.component.r3c1 = (mats_lhs->component.r3c1 * mats_rhs->component.r1c1) + (mats_lhs->component.r3c2 * mats_rhs->component.r2c1) + (mats_lhs->component.r3c3 * mats_rhs->component.r3c1);
            temp.component.r3c2 = (mats_lhs->component.r3c1 * mats_rhs->component.r1c2) + (mats_lhs->component.r3c2 * mats_rhs->component.r2c2) + (mats_lhs->component.r3c3 * mats_rhs->component.r3c2);
            temp.component.r3c3 = (mats_lhs->component.r3c1 * mats_rhs->component.r1c3) + (mats_lhs->component.r3c2 * mats_rhs->component.r2c3) + (mats_lhs->component.r3c3 * mats_rhs->component.r3c3);
            mats_out->component.r1c1 = temp.component.r1c1; mats_out->component.r1c2 = temp.component.r1c2; mats_out->component.r1c3 = temp.component.r1c3;
            mats_out->component.r2c1 = temp.component.r2c1; mats_out->component.r2c2 = temp.component.r2c2; mats_out->component.r2c3 = temp.component.r2c3;
            mats_out->component.r3c1 = temp.component.r3c1; mats_out->component.r3c2 = temp.component.r3c2; mats_out->component.r3c3 = temp.component.r3c3;
        } else {
            mats_out->component.r1c1 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c1) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c1) + (mats_lhs->component.r1c3 * mats_rhs->component.r3c1);
            mats_out->component.r1c2 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c2) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c2) + (mats_lhs->component.r1c3 * mats_rhs->component.r3c2);
            mats_out->component.r1c3 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c3) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c3) + (mats_lhs->component.r1c3 * mats_rhs->component.r3c3);
            mats_out->component.r2c1 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c1) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c1) + (mats_lhs->component.r2c3 * mats_rhs->component.r3c1);
            mats_out->component.r2c2 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c2) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c2) + (mats_lhs->component.r2c3 * mats_rhs->component.r3c2);
            mats_out->component.r2c3 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c3) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c3) + (mats_lhs->component.r2c3 * mats_rhs->component.r3c3);
            mats_out->component.r3c1 = (mats_lhs->component.r3c1 * mats_rhs->component.r1c1) + (mats_lhs->component.r3c2 * mats_rhs->component.r2c1) + (mats_lhs->component.r3c3 * mats_rhs->component.r3c1);
            mats_out->component.r3c2 = (mats_lhs->component.r3c1 * mats_rhs->component.r1c2) + (mats_lhs->component.r3c2 * mats_rhs->component.r2c2) + (mats_lhs->component.r3c3 * mats_rhs->component.r3c2);
            mats_out->component.r3c3 = (mats_lhs->component.r3c1 * mats_rhs->component.r1c3) + (mats_lhs->component.r3c2 * mats_rhs->component.r2c3) + (mats_lhs->component.r3c3 * mats_rhs->component.r3c3);
        }
        
        mats_lhs = (const egwMatrix33f*)((EGWintptr)mats_lhs + (EGWintptr)sizeof(egwMatrix33f) + strideB_lhs);
        mats_rhs = (const egwMatrix33f*)((EGWintptr)mats_rhs + (EGWintptr)sizeof(egwMatrix33f) + strideB_rhs);
        mats_out = (egwMatrix33f*)((EGWintptr)mats_out + (EGWintptr)sizeof(egwMatrix33f) + strideB_out);
    }
}

void egwMatMultiply44fv(const egwMatrix44f* mats_lhs, const egwMatrix44f* mats_rhs, egwMatrix44f* mats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        if(mats_lhs == mats_out || mats_rhs == mats_out) {
            egwMatrix44f temp;
            temp.component.r1c1 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c1) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c1) + (mats_lhs->component.r1c3 * mats_rhs->component.r3c1) + (mats_lhs->component.r1c4 * mats_rhs->component.r4c1);
            temp.component.r1c2 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c2) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c2) + (mats_lhs->component.r1c3 * mats_rhs->component.r3c2) + (mats_lhs->component.r1c4 * mats_rhs->component.r4c2);
            temp.component.r1c3 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c3) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c3) + (mats_lhs->component.r1c3 * mats_rhs->component.r3c3) + (mats_lhs->component.r1c4 * mats_rhs->component.r4c3);
            temp.component.r1c4 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c4) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c4) + (mats_lhs->component.r1c3 * mats_rhs->component.r3c4) + (mats_lhs->component.r1c4 * mats_rhs->component.r4c4);
            temp.component.r2c1 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c1) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c1) + (mats_lhs->component.r2c3 * mats_rhs->component.r3c1) + (mats_lhs->component.r2c4 * mats_rhs->component.r4c1);
            temp.component.r2c2 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c2) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c2) + (mats_lhs->component.r2c3 * mats_rhs->component.r3c2) + (mats_lhs->component.r2c4 * mats_rhs->component.r4c2);
            temp.component.r2c3 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c3) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c3) + (mats_lhs->component.r2c3 * mats_rhs->component.r3c3) + (mats_lhs->component.r2c4 * mats_rhs->component.r4c3);
            temp.component.r2c4 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c4) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c4) + (mats_lhs->component.r2c3 * mats_rhs->component.r3c4) + (mats_lhs->component.r2c4 * mats_rhs->component.r4c4);
            temp.component.r3c1 = (mats_lhs->component.r3c1 * mats_rhs->component.r1c1) + (mats_lhs->component.r3c2 * mats_rhs->component.r2c1) + (mats_lhs->component.r3c3 * mats_rhs->component.r3c1) + (mats_lhs->component.r3c4 * mats_rhs->component.r4c1);
            temp.component.r3c2 = (mats_lhs->component.r3c1 * mats_rhs->component.r1c2) + (mats_lhs->component.r3c2 * mats_rhs->component.r2c2) + (mats_lhs->component.r3c3 * mats_rhs->component.r3c2) + (mats_lhs->component.r3c4 * mats_rhs->component.r4c2);
            temp.component.r3c3 = (mats_lhs->component.r3c1 * mats_rhs->component.r1c3) + (mats_lhs->component.r3c2 * mats_rhs->component.r2c3) + (mats_lhs->component.r3c3 * mats_rhs->component.r3c3) + (mats_lhs->component.r3c4 * mats_rhs->component.r4c3);
            temp.component.r3c4 = (mats_lhs->component.r3c1 * mats_rhs->component.r1c4) + (mats_lhs->component.r3c2 * mats_rhs->component.r2c4) + (mats_lhs->component.r3c3 * mats_rhs->component.r3c4) + (mats_lhs->component.r3c4 * mats_rhs->component.r4c4);
            temp.component.r4c1 = (mats_lhs->component.r4c1 * mats_rhs->component.r1c1) + (mats_lhs->component.r4c2 * mats_rhs->component.r2c1) + (mats_lhs->component.r4c3 * mats_rhs->component.r3c1) + (mats_lhs->component.r4c4 * mats_rhs->component.r4c1);
            temp.component.r4c2 = (mats_lhs->component.r4c1 * mats_rhs->component.r1c2) + (mats_lhs->component.r4c2 * mats_rhs->component.r2c2) + (mats_lhs->component.r4c3 * mats_rhs->component.r3c2) + (mats_lhs->component.r4c4 * mats_rhs->component.r4c2);
            temp.component.r4c3 = (mats_lhs->component.r4c1 * mats_rhs->component.r1c3) + (mats_lhs->component.r4c2 * mats_rhs->component.r2c3) + (mats_lhs->component.r4c3 * mats_rhs->component.r3c3) + (mats_lhs->component.r4c4 * mats_rhs->component.r4c3);
            temp.component.r4c4 = (mats_lhs->component.r4c1 * mats_rhs->component.r1c4) + (mats_lhs->component.r4c2 * mats_rhs->component.r2c4) + (mats_lhs->component.r4c3 * mats_rhs->component.r3c4) + (mats_lhs->component.r4c4 * mats_rhs->component.r4c4);
            mats_out->component.r1c1 = temp.component.r1c1; mats_out->component.r1c2 = temp.component.r1c2; mats_out->component.r1c3 = temp.component.r1c3; mats_out->component.r1c4 = temp.component.r1c4;
            mats_out->component.r2c1 = temp.component.r2c1; mats_out->component.r2c2 = temp.component.r2c2; mats_out->component.r2c3 = temp.component.r2c3; mats_out->component.r2c4 = temp.component.r2c4;
            mats_out->component.r3c1 = temp.component.r3c1; mats_out->component.r3c2 = temp.component.r3c2; mats_out->component.r3c3 = temp.component.r3c3; mats_out->component.r3c4 = temp.component.r3c4;
            mats_out->component.r4c1 = temp.component.r4c1; mats_out->component.r4c2 = temp.component.r4c2; mats_out->component.r4c3 = temp.component.r4c3; mats_out->component.r4c4 = temp.component.r4c4;
        } else {
            mats_out->component.r1c1 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c1) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c1) + (mats_lhs->component.r1c3 * mats_rhs->component.r3c1) + (mats_lhs->component.r1c4 * mats_rhs->component.r4c1);
            mats_out->component.r1c2 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c2) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c2) + (mats_lhs->component.r1c3 * mats_rhs->component.r3c2) + (mats_lhs->component.r1c4 * mats_rhs->component.r4c2);
            mats_out->component.r1c3 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c3) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c3) + (mats_lhs->component.r1c3 * mats_rhs->component.r3c3) + (mats_lhs->component.r1c4 * mats_rhs->component.r4c3);
            mats_out->component.r1c4 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c4) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c4) + (mats_lhs->component.r1c3 * mats_rhs->component.r3c4) + (mats_lhs->component.r1c4 * mats_rhs->component.r4c4);
            mats_out->component.r2c1 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c1) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c1) + (mats_lhs->component.r2c3 * mats_rhs->component.r3c1) + (mats_lhs->component.r2c4 * mats_rhs->component.r4c1);
            mats_out->component.r2c2 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c2) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c2) + (mats_lhs->component.r2c3 * mats_rhs->component.r3c2) + (mats_lhs->component.r2c4 * mats_rhs->component.r4c2);
            mats_out->component.r2c3 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c3) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c3) + (mats_lhs->component.r2c3 * mats_rhs->component.r3c3) + (mats_lhs->component.r2c4 * mats_rhs->component.r4c3);
            mats_out->component.r2c4 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c4) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c4) + (mats_lhs->component.r2c3 * mats_rhs->component.r3c4) + (mats_lhs->component.r2c4 * mats_rhs->component.r4c4);
            mats_out->component.r3c1 = (mats_lhs->component.r3c1 * mats_rhs->component.r1c1) + (mats_lhs->component.r3c2 * mats_rhs->component.r2c1) + (mats_lhs->component.r3c3 * mats_rhs->component.r3c1) + (mats_lhs->component.r3c4 * mats_rhs->component.r4c1);
            mats_out->component.r3c2 = (mats_lhs->component.r3c1 * mats_rhs->component.r1c2) + (mats_lhs->component.r3c2 * mats_rhs->component.r2c2) + (mats_lhs->component.r3c3 * mats_rhs->component.r3c2) + (mats_lhs->component.r3c4 * mats_rhs->component.r4c2);
            mats_out->component.r3c3 = (mats_lhs->component.r3c1 * mats_rhs->component.r1c3) + (mats_lhs->component.r3c2 * mats_rhs->component.r2c3) + (mats_lhs->component.r3c3 * mats_rhs->component.r3c3) + (mats_lhs->component.r3c4 * mats_rhs->component.r4c3);
            mats_out->component.r3c4 = (mats_lhs->component.r3c1 * mats_rhs->component.r1c4) + (mats_lhs->component.r3c2 * mats_rhs->component.r2c4) + (mats_lhs->component.r3c3 * mats_rhs->component.r3c4) + (mats_lhs->component.r3c4 * mats_rhs->component.r4c4);
            mats_out->component.r4c1 = (mats_lhs->component.r4c1 * mats_rhs->component.r1c1) + (mats_lhs->component.r4c2 * mats_rhs->component.r2c1) + (mats_lhs->component.r4c3 * mats_rhs->component.r3c1) + (mats_lhs->component.r4c4 * mats_rhs->component.r4c1);
            mats_out->component.r4c2 = (mats_lhs->component.r4c1 * mats_rhs->component.r1c2) + (mats_lhs->component.r4c2 * mats_rhs->component.r2c2) + (mats_lhs->component.r4c3 * mats_rhs->component.r3c2) + (mats_lhs->component.r4c4 * mats_rhs->component.r4c2);
            mats_out->component.r4c3 = (mats_lhs->component.r4c1 * mats_rhs->component.r1c3) + (mats_lhs->component.r4c2 * mats_rhs->component.r2c3) + (mats_lhs->component.r4c3 * mats_rhs->component.r3c3) + (mats_lhs->component.r4c4 * mats_rhs->component.r4c3);
            mats_out->component.r4c4 = (mats_lhs->component.r4c1 * mats_rhs->component.r1c4) + (mats_lhs->component.r4c2 * mats_rhs->component.r2c4) + (mats_lhs->component.r4c3 * mats_rhs->component.r3c4) + (mats_lhs->component.r4c4 * mats_rhs->component.r4c4);
        }
        
        mats_lhs = (const egwMatrix44f*)((EGWintptr)mats_lhs + (EGWintptr)sizeof(egwMatrix44f) + strideB_lhs);
        mats_rhs = (const egwMatrix44f*)((EGWintptr)mats_rhs + (EGWintptr)sizeof(egwMatrix44f) + strideB_rhs);
        mats_out = (egwMatrix44f*)((EGWintptr)mats_out + (EGWintptr)sizeof(egwMatrix44f) + strideB_out);
    }
}

egwMatrix33f* egwMatMultiplyHmg33f(const egwMatrix33f* mat_lhs, const egwMatrix33f* mat_rhs, egwMatrix33f* mat_out) {
    if(mat_lhs == mat_out || mat_rhs == mat_out) {
        egwMatrix33f temp;
        temp.component.r1c1 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c1) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c1);
        temp.component.r1c2 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c2) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c2);
        temp.component.r1c3 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c3) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c3) + (mat_lhs->component.r1c3);
        temp.component.r2c1 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c1) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c1);
        temp.component.r2c2 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c2) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c2);
        temp.component.r2c3 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c3) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c3) + (mat_lhs->component.r2c3);
        mat_out->component.r1c1 = temp.component.r1c1; mat_out->component.r1c2 = temp.component.r1c2; mat_out->component.r1c3 = temp.component.r1c3;
        mat_out->component.r2c1 = temp.component.r2c1; mat_out->component.r2c2 = temp.component.r2c2; mat_out->component.r2c3 = temp.component.r2c3;
    } else {
        mat_out->component.r1c1 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c1) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c1);
        mat_out->component.r1c2 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c2) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c2);
        mat_out->component.r1c3 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c3) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c3) + (mat_lhs->component.r1c3);
        mat_out->component.r2c1 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c1) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c1);
        mat_out->component.r2c2 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c2) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c2);
        mat_out->component.r2c3 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c3) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c3) + (mat_lhs->component.r2c3);
        mat_out->component.r3c1 = 0.0f;
        mat_out->component.r3c2 = 0.0f;
        mat_out->component.r3c3 = 1.0f;
    }
    
    return mat_out;
}

egwMatrix44f* egwMatMultiplyHmg44f(const egwMatrix44f* mat_lhs, const egwMatrix44f* mat_rhs, egwMatrix44f* mat_out) {
    if(mat_lhs == mat_out || mat_rhs == mat_out) {
        egwMatrix44f temp;
        temp.component.r1c1 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c1) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c1) + (mat_lhs->component.r1c3 * mat_rhs->component.r3c1);
        temp.component.r1c2 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c2) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c2) + (mat_lhs->component.r1c3 * mat_rhs->component.r3c2);
        temp.component.r1c3 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c3) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c3) + (mat_lhs->component.r1c3 * mat_rhs->component.r3c3);
        temp.component.r1c4 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c4) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c4) + (mat_lhs->component.r1c3 * mat_rhs->component.r3c4) + (mat_lhs->component.r1c4);
        temp.component.r2c1 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c1) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c1) + (mat_lhs->component.r2c3 * mat_rhs->component.r3c1);
        temp.component.r2c2 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c2) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c2) + (mat_lhs->component.r2c3 * mat_rhs->component.r3c2);
        temp.component.r2c3 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c3) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c3) + (mat_lhs->component.r2c3 * mat_rhs->component.r3c3);
        temp.component.r2c4 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c4) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c4) + (mat_lhs->component.r2c3 * mat_rhs->component.r3c4) + (mat_lhs->component.r2c4);
        temp.component.r3c1 = (mat_lhs->component.r3c1 * mat_rhs->component.r1c1) + (mat_lhs->component.r3c2 * mat_rhs->component.r2c1) + (mat_lhs->component.r3c3 * mat_rhs->component.r3c1);
        temp.component.r3c2 = (mat_lhs->component.r3c1 * mat_rhs->component.r1c2) + (mat_lhs->component.r3c2 * mat_rhs->component.r2c2) + (mat_lhs->component.r3c3 * mat_rhs->component.r3c2);
        temp.component.r3c3 = (mat_lhs->component.r3c1 * mat_rhs->component.r1c3) + (mat_lhs->component.r3c2 * mat_rhs->component.r2c3) + (mat_lhs->component.r3c3 * mat_rhs->component.r3c3);
        temp.component.r3c4 = (mat_lhs->component.r3c1 * mat_rhs->component.r1c4) + (mat_lhs->component.r3c2 * mat_rhs->component.r2c4) + (mat_lhs->component.r3c3 * mat_rhs->component.r3c4) + (mat_lhs->component.r3c4);
        mat_out->component.r1c1 = temp.component.r1c1; mat_out->component.r1c2 = temp.component.r1c2; mat_out->component.r1c3 = temp.component.r1c3; mat_out->component.r1c4 = temp.component.r1c4;
        mat_out->component.r2c1 = temp.component.r2c1; mat_out->component.r2c2 = temp.component.r2c2; mat_out->component.r2c3 = temp.component.r2c3; mat_out->component.r2c4 = temp.component.r2c4;
        mat_out->component.r3c1 = temp.component.r3c1; mat_out->component.r3c2 = temp.component.r3c2; mat_out->component.r3c3 = temp.component.r3c3; mat_out->component.r3c4 = temp.component.r3c4;
    } else {
        mat_out->component.r1c1 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c1) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c1) + (mat_lhs->component.r1c3 * mat_rhs->component.r3c1);
        mat_out->component.r1c2 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c2) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c2) + (mat_lhs->component.r1c3 * mat_rhs->component.r3c2);
        mat_out->component.r1c3 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c3) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c3) + (mat_lhs->component.r1c3 * mat_rhs->component.r3c3);
        mat_out->component.r1c4 = (mat_lhs->component.r1c1 * mat_rhs->component.r1c4) + (mat_lhs->component.r1c2 * mat_rhs->component.r2c4) + (mat_lhs->component.r1c3 * mat_rhs->component.r3c4) + (mat_lhs->component.r1c4);
        mat_out->component.r2c1 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c1) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c1) + (mat_lhs->component.r2c3 * mat_rhs->component.r3c1);
        mat_out->component.r2c2 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c2) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c2) + (mat_lhs->component.r2c3 * mat_rhs->component.r3c2);
        mat_out->component.r2c3 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c3) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c3) + (mat_lhs->component.r2c3 * mat_rhs->component.r3c3);
        mat_out->component.r2c4 = (mat_lhs->component.r2c1 * mat_rhs->component.r1c4) + (mat_lhs->component.r2c2 * mat_rhs->component.r2c4) + (mat_lhs->component.r2c3 * mat_rhs->component.r3c4) + (mat_lhs->component.r2c4);
        mat_out->component.r3c1 = (mat_lhs->component.r3c1 * mat_rhs->component.r1c1) + (mat_lhs->component.r3c2 * mat_rhs->component.r2c1) + (mat_lhs->component.r3c3 * mat_rhs->component.r3c1);
        mat_out->component.r3c2 = (mat_lhs->component.r3c1 * mat_rhs->component.r1c2) + (mat_lhs->component.r3c2 * mat_rhs->component.r2c2) + (mat_lhs->component.r3c3 * mat_rhs->component.r3c2);
        mat_out->component.r3c3 = (mat_lhs->component.r3c1 * mat_rhs->component.r1c3) + (mat_lhs->component.r3c2 * mat_rhs->component.r2c3) + (mat_lhs->component.r3c3 * mat_rhs->component.r3c3);
        mat_out->component.r3c4 = (mat_lhs->component.r3c1 * mat_rhs->component.r1c4) + (mat_lhs->component.r3c2 * mat_rhs->component.r2c4) + (mat_lhs->component.r3c3 * mat_rhs->component.r3c4) + (mat_lhs->component.r3c4);
        mat_out->component.r4c1 = 0.0f;
        mat_out->component.r4c2 = 0.0f;
        mat_out->component.r4c3 = 0.0f;
        mat_out->component.r4c4 = 1.0f;
    }
    
    return mat_out;
}

void egwMatMultiplyHmg33fv(const egwMatrix33f* mats_lhs, const egwMatrix33f* mats_rhs, egwMatrix33f* mats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        if(mats_lhs == mats_out || mats_rhs == mats_out) {
            egwMatrix33f temp;
            temp.component.r1c1 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c1) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c1);
            temp.component.r1c2 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c2) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c2);
            temp.component.r1c3 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c3) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c3) + (mats_lhs->component.r1c3);
            temp.component.r2c1 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c1) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c1);
            temp.component.r2c2 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c2) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c2);
            temp.component.r2c3 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c3) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c3) + (mats_lhs->component.r2c3);
            mats_out->component.r1c1 = temp.component.r1c1; mats_out->component.r1c2 = temp.component.r1c2; mats_out->component.r1c3 = temp.component.r1c3;
            mats_out->component.r2c1 = temp.component.r2c1; mats_out->component.r2c2 = temp.component.r2c2; mats_out->component.r2c3 = temp.component.r2c3;
        } else {
            mats_out->component.r1c1 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c1) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c1);
            mats_out->component.r1c2 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c2) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c2);
            mats_out->component.r1c3 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c3) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c3) + (mats_lhs->component.r1c3);
            mats_out->component.r2c1 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c1) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c1);
            mats_out->component.r2c2 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c2) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c2);
            mats_out->component.r2c3 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c3) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c3) + (mats_lhs->component.r2c3);
            mats_out->component.r3c1 = 0.0f;
            mats_out->component.r3c2 = 0.0f;
            mats_out->component.r3c3 = 1.0f;
        }
        
        mats_lhs = (const egwMatrix33f*)((EGWintptr)mats_lhs + (EGWintptr)sizeof(egwMatrix33f) + strideB_lhs);
        mats_rhs = (const egwMatrix33f*)((EGWintptr)mats_rhs + (EGWintptr)sizeof(egwMatrix33f) + strideB_rhs);
        mats_out = (egwMatrix33f*)((EGWintptr)mats_out + (EGWintptr)sizeof(egwMatrix33f) + strideB_out);
    }
}

void egwMatMultiplyHmg44fv(const egwMatrix44f* mats_lhs, const egwMatrix44f* mats_rhs, egwMatrix44f* mats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        if(mats_lhs == mats_out || mats_rhs == mats_out) {
            egwMatrix44f temp;
            temp.component.r1c1 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c1) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c1) + (mats_lhs->component.r1c3 * mats_rhs->component.r3c1);
            temp.component.r1c2 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c2) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c2) + (mats_lhs->component.r1c3 * mats_rhs->component.r3c2);
            temp.component.r1c3 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c3) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c3) + (mats_lhs->component.r1c3 * mats_rhs->component.r3c3);
            temp.component.r1c4 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c4) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c4) + (mats_lhs->component.r1c3 * mats_rhs->component.r3c4) + (mats_lhs->component.r1c4);
            temp.component.r2c1 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c1) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c1) + (mats_lhs->component.r2c3 * mats_rhs->component.r3c1);
            temp.component.r2c2 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c2) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c2) + (mats_lhs->component.r2c3 * mats_rhs->component.r3c2);
            temp.component.r2c3 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c3) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c3) + (mats_lhs->component.r2c3 * mats_rhs->component.r3c3);
            temp.component.r2c4 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c4) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c4) + (mats_lhs->component.r2c3 * mats_rhs->component.r3c4) + (mats_lhs->component.r2c4);
            temp.component.r3c1 = (mats_lhs->component.r3c1 * mats_rhs->component.r1c1) + (mats_lhs->component.r3c2 * mats_rhs->component.r2c1) + (mats_lhs->component.r3c3 * mats_rhs->component.r3c1);
            temp.component.r3c2 = (mats_lhs->component.r3c1 * mats_rhs->component.r1c2) + (mats_lhs->component.r3c2 * mats_rhs->component.r2c2) + (mats_lhs->component.r3c3 * mats_rhs->component.r3c2);
            temp.component.r3c3 = (mats_lhs->component.r3c1 * mats_rhs->component.r1c3) + (mats_lhs->component.r3c2 * mats_rhs->component.r2c3) + (mats_lhs->component.r3c3 * mats_rhs->component.r3c3);
            temp.component.r3c4 = (mats_lhs->component.r3c1 * mats_rhs->component.r1c4) + (mats_lhs->component.r3c2 * mats_rhs->component.r2c4) + (mats_lhs->component.r3c3 * mats_rhs->component.r3c4) + (mats_lhs->component.r3c4);
            mats_out->component.r1c1 = temp.component.r1c1; mats_out->component.r1c2 = temp.component.r1c2; mats_out->component.r1c3 = temp.component.r1c3; mats_out->component.r1c4 = temp.component.r1c4;
            mats_out->component.r2c1 = temp.component.r2c1; mats_out->component.r2c2 = temp.component.r2c2; mats_out->component.r2c3 = temp.component.r2c3; mats_out->component.r2c4 = temp.component.r2c4;
            mats_out->component.r3c1 = temp.component.r3c1; mats_out->component.r3c2 = temp.component.r3c2; mats_out->component.r3c3 = temp.component.r3c3; mats_out->component.r3c4 = temp.component.r3c4;
        } else {
            mats_out->component.r1c1 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c1) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c1) + (mats_lhs->component.r1c3 * mats_rhs->component.r3c1);
            mats_out->component.r1c2 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c2) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c2) + (mats_lhs->component.r1c3 * mats_rhs->component.r3c2);
            mats_out->component.r1c3 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c3) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c3) + (mats_lhs->component.r1c3 * mats_rhs->component.r3c3);
            mats_out->component.r1c4 = (mats_lhs->component.r1c1 * mats_rhs->component.r1c4) + (mats_lhs->component.r1c2 * mats_rhs->component.r2c4) + (mats_lhs->component.r1c3 * mats_rhs->component.r3c4) + (mats_lhs->component.r1c4);
            mats_out->component.r2c1 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c1) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c1) + (mats_lhs->component.r2c3 * mats_rhs->component.r3c1);
            mats_out->component.r2c2 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c2) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c2) + (mats_lhs->component.r2c3 * mats_rhs->component.r3c2);
            mats_out->component.r2c3 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c3) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c3) + (mats_lhs->component.r2c3 * mats_rhs->component.r3c3);
            mats_out->component.r2c4 = (mats_lhs->component.r2c1 * mats_rhs->component.r1c4) + (mats_lhs->component.r2c2 * mats_rhs->component.r2c4) + (mats_lhs->component.r2c3 * mats_rhs->component.r3c4) + (mats_lhs->component.r2c4);
            mats_out->component.r3c1 = (mats_lhs->component.r3c1 * mats_rhs->component.r1c1) + (mats_lhs->component.r3c2 * mats_rhs->component.r2c1) + (mats_lhs->component.r3c3 * mats_rhs->component.r3c1);
            mats_out->component.r3c2 = (mats_lhs->component.r3c1 * mats_rhs->component.r1c2) + (mats_lhs->component.r3c2 * mats_rhs->component.r2c2) + (mats_lhs->component.r3c3 * mats_rhs->component.r3c2);
            mats_out->component.r3c3 = (mats_lhs->component.r3c1 * mats_rhs->component.r1c3) + (mats_lhs->component.r3c2 * mats_rhs->component.r2c3) + (mats_lhs->component.r3c3 * mats_rhs->component.r3c3);
            mats_out->component.r3c4 = (mats_lhs->component.r3c1 * mats_rhs->component.r1c4) + (mats_lhs->component.r3c2 * mats_rhs->component.r2c4) + (mats_lhs->component.r3c3 * mats_rhs->component.r3c4) + (mats_lhs->component.r3c4);
            mats_out->component.r4c1 = 0.0f;
            mats_out->component.r4c2 = 0.0f;
            mats_out->component.r4c3 = 0.0f;
            mats_out->component.r4c4 = 1.0f;
        }
        
        mats_lhs = (const egwMatrix44f*)((EGWintptr)mats_lhs + (EGWintptr)sizeof(egwMatrix44f) + strideB_lhs);
        mats_rhs = (const egwMatrix44f*)((EGWintptr)mats_rhs + (EGWintptr)sizeof(egwMatrix44f) + strideB_rhs);
        mats_out = (egwMatrix44f*)((EGWintptr)mats_out + (EGWintptr)sizeof(egwMatrix44f) + strideB_out);
    }
}

egwMatrix33f* egwMatRotateEuler33f(const egwMatrix33f* mat_in, const EGWsingle angle_r, egwMatrix33f* mat_out) {
    if(mat_in) {
        egwMatrix33f temp;
        temp.component.r1c3 = temp.component.r2c3 = 
            temp.component.r3c1 = temp.component.r3c2 = 0.0f;
        temp.component.r3c3 = 1.0f;
        
        EGWsingle ca = egwCosf(angle_r);
        EGWsingle sa = egwSinf(angle_r);
        temp.component.r1c1 = ca; temp.component.r1c2 = sa;
        temp.component.r2c1 = -sa; temp.component.r2c2 = ca;
        
        egwMatMultiply33f(mat_in, &temp, mat_out);
    } else {
        mat_out->component.r1c3 = mat_out->component.r2c3 = 
            mat_out->component.r3c1 = mat_out->component.r3c2 = 0.0f;
        mat_out->component.r3c3 = 1.0f;
        
        EGWsingle ca = egwCosf(angle_r);
        EGWsingle sa = egwSinf(angle_r);
        mat_out->component.r1c1 = ca; mat_out->component.r1c2 = sa;
        mat_out->component.r2c1 = -sa; mat_out->component.r2c2 = ca;
    }
    
    return mat_out;
}

egwMatrix44f* egwMatRotateEuler44f(const egwMatrix44f* mat_in, const egwVector3f* angles_r, const EGWint order, egwMatrix44f* mat_out) {
    egwMatrix44f temp;
    temp.component.r1c4 = temp.component.r2c4 = temp.component.r3c4 =
        temp.component.r4c1 = temp.component.r4c2 = temp.component.r4c3 = 0.0f;
    temp.component.r4c4 = 1.0f;
    
    switch(order) {
        case EGW_EULERROT_ORDER_X: {
            EGWsingle cx = egwCosf(angles_r->axis.x);
            EGWsingle sx = egwSinf(angles_r->axis.x);
            temp.component.r1c1 = 1.0f; temp.component.r1c2 = 0.0; temp.component.r1c3 = 0.0f;
            temp.component.r2c1 = 0.0f; temp.component.r2c2 = cx; temp.component.r2c3 = -sx;
            temp.component.r3c1 = 0.0f; temp.component.r3c2 = sx; temp.component.r3c3 = cx;
        } break;
        case EGW_EULERROT_ORDER_Y: {
            EGWsingle cy = egwCosf(angles_r->axis.y);
            EGWsingle sy = egwSinf(angles_r->axis.y);
            temp.component.r1c1 = cy; temp.component.r1c2 = 0.0f; temp.component.r1c3 = sy;
            temp.component.r2c1 = 0.0f; temp.component.r2c2 = 1.0f; temp.component.r2c3 = 0.0f;
            temp.component.r3c1 = -sy; temp.component.r3c2 = 0.0f; temp.component.r3c3 = cy;
        } break;
        case EGW_EULERROT_ORDER_Z: {
            EGWsingle cz = egwCosf(angles_r->axis.z);
            EGWsingle sz = egwSinf(angles_r->axis.z);
            temp.component.r1c1 = cz; temp.component.r1c2 = -sz; temp.component.r1c3 = 0.0f;
            temp.component.r2c1 = sz; temp.component.r2c2 = cz; temp.component.r2c3 = 0.0f;
            temp.component.r3c1 = 0.0f; temp.component.r3c2 = 0.0f; temp.component.r3c3 = 1.0f;
        } break;
        case EGW_EULERROT_ORDER_XY: {
            EGWsingle cx = egwCosf(angles_r->axis.x);
            EGWsingle sx = egwSinf(angles_r->axis.x);
            EGWsingle cy = egwCosf(angles_r->axis.y);
            EGWsingle sy = egwSinf(angles_r->axis.y);
            temp.component.r1c1 = cy; temp.component.r1c2 = 0.0f; temp.component.r1c3 = sy;
            temp.component.r2c1 = sx * sy; temp.component.r2c2 = cx; temp.component.r2c3 = -cy * sx;
            temp.component.r3c1 = -cx * sy; temp.component.r3c2 = sx; temp.component.r3c3 = cx * cy;
        } break;
        case EGW_EULERROT_ORDER_XZ: {
            EGWsingle cx = egwCosf(angles_r->axis.x);
            EGWsingle sx = egwSinf(angles_r->axis.x);
            EGWsingle cz = egwCosf(angles_r->axis.z);
            EGWsingle sz = egwSinf(angles_r->axis.z);            
            temp.component.r1c1 = cz; temp.component.r1c2 = -sz; temp.component.r1c3 = 0.0f;
            temp.component.r2c1 = cx * sz; temp.component.r2c2 = cx * cz; temp.component.r2c3 = -sx;
            temp.component.r3c1 = sx * sz; temp.component.r3c2 = cz * sx; temp.component.r3c3 = cx;
        } break;
        case EGW_EULERROT_ORDER_YX: {
            EGWsingle cx = egwCosf(angles_r->axis.x);
            EGWsingle sx = egwSinf(angles_r->axis.x);
            EGWsingle cy = egwCosf(angles_r->axis.y);
            EGWsingle sy = egwSinf(angles_r->axis.y);
            temp.component.r1c1 = cy; temp.component.r1c2 = sx * sy; temp.component.r1c3 = cx * sy;
            temp.component.r2c1 = 0.0f; temp.component.r2c2 = cx; temp.component.r2c3 = -sx;
            temp.component.r3c1 = -sy; temp.component.r3c2 = cy * sx; temp.component.r3c3 = cx * cy;
        } break;
        case EGW_EULERROT_ORDER_YZ: {
            EGWsingle cy = egwCosf(angles_r->axis.y);
            EGWsingle sy = egwSinf(angles_r->axis.y);
            EGWsingle cz = egwCosf(angles_r->axis.z);
            EGWsingle sz = egwSinf(angles_r->axis.z);
            temp.component.r1c1 = cy * cz; temp.component.r1c2 = -cy * sz; temp.component.r1c3 = sy;
            temp.component.r2c1 = sz; temp.component.r2c2 = cz; temp.component.r2c3 = 0.0f;
            temp.component.r3c1 = -cy * sy; temp.component.r3c2 = sy * sz; temp.component.r3c3 = cy;
        } break;
        case EGW_EULERROT_ORDER_ZX: {
            EGWsingle cx = egwCosf(angles_r->axis.x);
            EGWsingle sx = egwSinf(angles_r->axis.x);
            EGWsingle cz = egwCosf(angles_r->axis.z);
            EGWsingle sz = egwSinf(angles_r->axis.z);
            temp.component.r1c1 = cz; temp.component.r1c2 = -cx * sz; temp.component.r1c3 = sx * sz;
            temp.component.r2c1 = sz; temp.component.r2c2 = cx * cz; temp.component.r2c3 = -cz * sx;
            temp.component.r3c1 = 0.0f; temp.component.r3c2 = sx; temp.component.r3c3 = cx;
        } break;
        case EGW_EULERROT_ORDER_ZY: {
            EGWsingle cy = egwCosf(angles_r->axis.y);
            EGWsingle sy = egwSinf(angles_r->axis.y);
            EGWsingle cz = egwCosf(angles_r->axis.z);
            EGWsingle sz = egwSinf(angles_r->axis.z);
            temp.component.r1c1 = cy * cz; temp.component.r1c2 = -sz; temp.component.r1c3 = cz * sy;
            temp.component.r2c1 = cy * sz; temp.component.r2c2 = cz; temp.component.r2c3 = sy * sz;
            temp.component.r3c1 = -sy; temp.component.r3c2 = 0.0f; temp.component.r3c3 = cy;
        } break;
        case EGW_EULERROT_ORDER_XYZ: {
            EGWsingle cx = egwCosf(angles_r->axis.x);
            EGWsingle sx = egwSinf(angles_r->axis.x);
            EGWsingle cy = egwCosf(angles_r->axis.y);
            EGWsingle sy = egwSinf(angles_r->axis.y);
            EGWsingle cz = egwCosf(angles_r->axis.z);
            EGWsingle sz = egwSinf(angles_r->axis.z);
            EGWsingle cxsz = cx * sz;
            EGWsingle czsx = cz * sx;
            EGWsingle sxsz = sx * sz;
            EGWsingle cxcz = cx * cz;
            temp.component.r1c1 = cy * cz; temp.component.r1c2 = -cy * sz; temp.component.r1c3 = sy;
            temp.component.r2c1 = (cxsz) + (czsx * sy); temp.component.r2c2 = (cxcz) - (sxsz * sy); temp.component.r2c3 = -cy * sx;
            temp.component.r3c1 = (sxsz) - (cxcz * sy); temp.component.r3c2 = (cxsz * sy) + (czsx); temp.component.r3c3 = cx * cy;
        } break;
        case EGW_EULERROT_ORDER_XZY: {
            EGWsingle cx = egwCosf(angles_r->axis.x);
            EGWsingle sx = egwSinf(angles_r->axis.x);
            EGWsingle cy = egwCosf(angles_r->axis.y);
            EGWsingle sy = egwSinf(angles_r->axis.y);
            EGWsingle cz = egwCosf(angles_r->axis.z);
            EGWsingle sz = egwSinf(angles_r->axis.z);
            EGWsingle cxcy = cx * cy;
            EGWsingle sxsy = sx * sy;
            EGWsingle cysx = cy * sx;
            EGWsingle cxsy = cx * sy;
            temp.component.r1c1 = cy * cz; temp.component.r1c2 = -sz; temp.component.r1c3 = cz * sy;
            temp.component.r2c1 = (cxcy * sz) + (sxsy); temp.component.r2c2 = cx * cz; temp.component.r2c3 = (cxsy * sz) - (cysx);
            temp.component.r3c1 = (cysx * sz) - (cxsy); temp.component.r3c2 = cz * sx; temp.component.r3c3 = (cxcy) + (sxsy * sz);
        } break;
        case EGW_EULERROT_ORDER_YXZ: {
            EGWsingle cx = egwCosf(angles_r->axis.x);
            EGWsingle sx = egwSinf(angles_r->axis.x);
            EGWsingle cy = egwCosf(angles_r->axis.y);
            EGWsingle sy = egwSinf(angles_r->axis.y);
            EGWsingle cz = egwCosf(angles_r->axis.z);
            EGWsingle sz = egwSinf(angles_r->axis.z);
            EGWsingle cycz = cy * cz;
            EGWsingle sysz = sy * sz;
            EGWsingle cysz = cy * sz;
            EGWsingle czsy = cy * sy;
            temp.component.r1c1 = (cycz) + (sx * sysz); temp.component.r1c2 = (czsy * sx) - (cysz); temp.component.r1c3 = cx * sy;
            temp.component.r2c1 = cx * sz; temp.component.r2c2 = cx * cz; temp.component.r2c3 = -sx;
            temp.component.r3c1 = (cysz * sx) - (czsy); temp.component.r3c2 = (cycz * sx) + (sysz); temp.component.r3c3 = cx * cy;
        } break;
        case EGW_EULERROT_ORDER_YZX: {
            EGWsingle cx = egwCosf(angles_r->axis.x);
            EGWsingle sx = egwSinf(angles_r->axis.x);
            EGWsingle cy = egwCosf(angles_r->axis.y);
            EGWsingle sy = egwSinf(angles_r->axis.y);
            EGWsingle cz = egwCosf(angles_r->axis.z);
            EGWsingle sz = egwSinf(angles_r->axis.z);
            EGWsingle sxsy = sx * sy;
            EGWsingle cxcy = cx * cy;
            EGWsingle cxsy = cx * sy;
            EGWsingle cysx = cy * sx;
            temp.component.r1c1 = cy * cz; temp.component.r1c2 = (sxsy) - (cxcy * sz); temp.component.r1c3 = (cxsy) + (cysx * sz);
            temp.component.r2c1 = sz; temp.component.r2c2 = cx * cz; temp.component.r2c3 = -cz * sx;
            temp.component.r3c1 = -cz * sy; temp.component.r3c2 = (cxsy * sz) + (cysx); temp.component.r3c3 = (cxcy) - (sxsy * sz);
        } break;
        case EGW_EULERROT_ORDER_ZXY: {
            EGWsingle cx = egwCosf(angles_r->axis.x);
            EGWsingle sx = egwSinf(angles_r->axis.x);
            EGWsingle cy = egwCosf(angles_r->axis.y);
            EGWsingle sy = egwSinf(angles_r->axis.y);
            EGWsingle cz = egwCosf(angles_r->axis.z);
            EGWsingle sz = egwSinf(angles_r->axis.z);
            EGWsingle cycz = cy * cz;
            EGWsingle sysz = sy * sz;
            EGWsingle cysz = cy * sz;
            EGWsingle czsy = cz * sy;
            temp.component.r1c1 = (cycz) - (sx * sysz); temp.component.r1c2 = -cx * sz; temp.component.r1c3 = (cysz * sx) + (czsy);
            temp.component.r2c1 = (cysz) + (czsy * sx); temp.component.r2c2 = cx * cz; temp.component.r2c3 = (sysz) - (cycz * sx);
            temp.component.r3c1 = -cx * sy; temp.component.r3c2 = sx; temp.component.r3c3 = cx * cy;
        } break;
        case EGW_EULERROT_ORDER_ZYX: {
            EGWsingle cx = egwCosf(angles_r->axis.x);
            EGWsingle sx = egwSinf(angles_r->axis.x);
            EGWsingle cy = egwCosf(angles_r->axis.y);
            EGWsingle sy = egwSinf(angles_r->axis.y);
            EGWsingle cz = egwCosf(angles_r->axis.z);
            EGWsingle sz = egwSinf(angles_r->axis.z);
            EGWsingle czsx = cz * sx;
            EGWsingle cxsz = cx * sz;
            EGWsingle cxcz = cx * cz;
            EGWsingle sxsz = sx * sz;
            temp.component.r1c1 = cy * cz; temp.component.r1c2 = (czsx * sy) - (cxsz); temp.component.r1c3 = (cxcz * sy) + (sxsz);
            temp.component.r2c1 = cy * sz; temp.component.r2c2 = (cxcz) + (sxsz * sy); temp.component.r2c3 = (cxsz * sy) - (czsx);
            temp.component.r3c1 = -sy; temp.component.r3c2 = cy * sx; temp.component.r3c3 = cx * cy;
        } break;
        default: {
            temp.component.r1c1 = 1.0f; temp.component.r1c2 = 0.0; temp.component.r1c3 = 0.0f;
            temp.component.r2c1 = 0.0f; temp.component.r2c2 = 1.0f; temp.component.r2c3 = 0.0f;
            temp.component.r3c1 = 0.0f; temp.component.r3c2 = 0.0f; temp.component.r3c3 = 1.0f;
        } break;
    }
    
    if(mat_in)
        egwMatMultiply44f(mat_in, &temp, mat_out);
    else {
        mat_out->component.r1c1 = temp.component.r1c1; mat_out->component.r1c2 = temp.component.r1c2; mat_out->component.r1c3 = temp.component.r1c3; mat_out->component.r1c4 = temp.component.r1c4;
        mat_out->component.r2c1 = temp.component.r2c1; mat_out->component.r2c2 = temp.component.r2c2; mat_out->component.r2c3 = temp.component.r2c3; mat_out->component.r2c4 = temp.component.r2c4;
        mat_out->component.r3c1 = temp.component.r3c1; mat_out->component.r3c2 = temp.component.r3c2; mat_out->component.r3c3 = temp.component.r3c3; mat_out->component.r3c4 = temp.component.r3c4;
        mat_out->component.r4c1 = temp.component.r4c1; mat_out->component.r4c2 = temp.component.r4c2; mat_out->component.r4c3 = temp.component.r4c3; mat_out->component.r4c4 = temp.component.r4c4;
    }
    
    return mat_out;
}

egwMatrix44f* egwMatRotateEuler44fs(const egwMatrix44f* mat_in, const EGWsingle angleX_r, const EGWsingle angleY_r, const EGWsingle angleZ_r, const EGWint order, egwMatrix44f* mat_out) {
    egwVector3f angles;
    angles.axis.x = angleX_r; angles.axis.y = angleY_r; angles.axis.z = angleZ_r;
    return egwMatRotateEuler44f(mat_in, &angles, order, mat_out);
}

egwMatrix44f* egwMatRotateAxis44f(const egwMatrix44f* mat_in, const egwVector3f* axis, egwMatrix44f* mat_out) {
    egwMatrix44f temp;
    temp.component.r1c4 = temp.component.r2c4 = temp.component.r3c4 =
        temp.component.r4c1 = temp.component.r4c2 = temp.component.r4c3 = 0.0f;
    temp.component.r4c4 = 1.0f;
    
    egwVector3f unitAxis;
    EGWsingle angle = egwVecMagnitude3f(axis);
    if(!egwIsZerof(angle)) {
        egwVecNormalizeMag3f(axis, angle, &unitAxis);
        
        EGWsingle sa = egwSinf(angle);
        EGWsingle ca = egwCosf(angle);
        EGWsingle OneMinusCa = 1.0f - ca;
        EGWsingle OneMinusCaRxRy = OneMinusCa * unitAxis.axis.x * unitAxis.axis.y;
        EGWsingle OneMinusCaRxRz = OneMinusCa * unitAxis.axis.x * unitAxis.axis.z;
        EGWsingle OneMinusCaRyRz = OneMinusCa * unitAxis.axis.y * unitAxis.axis.z;
        EGWsingle RxSa = unitAxis.axis.x * sa;
        EGWsingle RySa = unitAxis.axis.y * sa;
        EGWsingle RzSa = unitAxis.axis.z * sa;
        temp.component.r1c1 = ca + (OneMinusCa * egwSqrd(unitAxis.axis.x)); temp.component.r1c2 = OneMinusCaRxRy - RzSa; temp.component.r1c3 = OneMinusCaRxRz + RySa;
        temp.component.r2c1 = OneMinusCaRxRy + RzSa; temp.component.r2c2 = ca + (OneMinusCa * egwSqrd(unitAxis.axis.y)); temp.component.r2c3 = OneMinusCaRyRz - RxSa;
        temp.component.r3c1 = OneMinusCaRxRz - RySa; temp.component.r3c2 = OneMinusCaRyRz + RxSa; temp.component.r3c3 = ca + (OneMinusCa * egwSqrd(unitAxis.axis.z));
    } else // zero axis = no rotation
        egwMatCopy44f(&egwSIMatIdentity44f, &temp);
    
    if(mat_in)
        egwMatMultiply44f(mat_in, &temp, mat_out);
    else {
        mat_out->component.r1c1 = temp.component.r1c1; mat_out->component.r1c2 = temp.component.r1c2; mat_out->component.r1c3 = temp.component.r1c3; mat_out->component.r1c4 = temp.component.r1c4;
        mat_out->component.r2c1 = temp.component.r2c1; mat_out->component.r2c2 = temp.component.r2c2; mat_out->component.r2c3 = temp.component.r2c3; mat_out->component.r2c4 = temp.component.r2c4;
        mat_out->component.r3c1 = temp.component.r3c1; mat_out->component.r3c2 = temp.component.r3c2; mat_out->component.r3c3 = temp.component.r3c3; mat_out->component.r3c4 = temp.component.r3c4;
        mat_out->component.r4c1 = temp.component.r4c1; mat_out->component.r4c2 = temp.component.r4c2; mat_out->component.r4c3 = temp.component.r4c3; mat_out->component.r4c4 = temp.component.r4c4;
    }
    
    return mat_out;
}

egwMatrix44f* egwMatRotateAxis44fs(const egwMatrix44f* mat_in, const EGWsingle axisX, const EGWsingle axisY, const EGWsingle axisZ, egwMatrix44f* mat_out) {
    egwVector3f axis;
    axis.axis.x = axisX; axis.axis.y = axisY; axis.axis.z = axisZ;
    return egwMatRotateAxis44f(mat_in, &axis, mat_out);
}

egwMatrix44f* egwMatRotateAxisAngle44f(const egwMatrix44f* mat_in, const egwVector3f* axis_u, const EGWsingle angle_r, egwMatrix44f* mat_out) {
    egwMatrix44f temp;
    temp.component.r1c4 = temp.component.r2c4 = temp.component.r3c4 =
        temp.component.r4c1 = temp.component.r4c2 = temp.component.r4c3 = 0.0f;
    temp.component.r4c4 = 1.0f;
    
    if(!egwIsZerof(angle_r)) {
        EGWsingle sa = egwSinf(angle_r);
        EGWsingle ca = egwCosf(angle_r);
        EGWsingle OneMinusCa = 1.0f - ca;
        EGWsingle OneMinusCaRxRy = OneMinusCa * axis_u->axis.x * axis_u->axis.y;
        EGWsingle OneMinusCaRxRz = OneMinusCa * axis_u->axis.x * axis_u->axis.z;
        EGWsingle OneMinusCaRyRz = OneMinusCa * axis_u->axis.y * axis_u->axis.z;
        EGWsingle RxSa = axis_u->axis.x * sa;
        EGWsingle RySa = axis_u->axis.y * sa;
        EGWsingle RzSa = axis_u->axis.z * sa;
        temp.component.r1c1 = ca + (OneMinusCa * egwSqrd(axis_u->axis.x)); temp.component.r1c2 = OneMinusCaRxRy - RzSa; temp.component.r1c3 = OneMinusCaRxRz + RySa;
        temp.component.r2c1 = OneMinusCaRxRy + RzSa; temp.component.r2c2 = ca + (OneMinusCa * egwSqrd(axis_u->axis.y)); temp.component.r2c3 = OneMinusCaRyRz - RxSa;
        temp.component.r3c1 = OneMinusCaRxRz - RySa; temp.component.r3c2 = OneMinusCaRyRz + RxSa; temp.component.r3c3 = ca + (OneMinusCa * egwSqrd(axis_u->axis.z));
    } else // zero angle = no rotation
        egwMatCopy44f(&egwSIMatIdentity44f, &temp);
    
    if(mat_in)
        egwMatMultiply44f(mat_in, &temp, mat_out);
    else {
        mat_out->component.r1c1 = temp.component.r1c1; mat_out->component.r1c2 = temp.component.r1c2; mat_out->component.r1c3 = temp.component.r1c3; mat_out->component.r1c4 = temp.component.r1c4;
        mat_out->component.r2c1 = temp.component.r2c1; mat_out->component.r2c2 = temp.component.r2c2; mat_out->component.r2c3 = temp.component.r2c3; mat_out->component.r2c4 = temp.component.r2c4;
        mat_out->component.r3c1 = temp.component.r3c1; mat_out->component.r3c2 = temp.component.r3c2; mat_out->component.r3c3 = temp.component.r3c3; mat_out->component.r3c4 = temp.component.r3c4;
        mat_out->component.r4c1 = temp.component.r4c1; mat_out->component.r4c2 = temp.component.r4c2; mat_out->component.r4c3 = temp.component.r4c3; mat_out->component.r4c4 = temp.component.r4c4;
    }
    
    return mat_out;
}

egwMatrix44f* egwMatRotateAxisAngle44fs(const egwMatrix44f* mat_in, const EGWsingle axisX_u, const EGWsingle axisY_u, const EGWsingle axisZ_u, const EGWsingle angle_r, egwMatrix44f* mat_out) {
    egwVector3f unitAxis;
    unitAxis.axis.x = axisX_u; unitAxis.axis.y = axisY_u; unitAxis.axis.z = axisZ_u;
    return egwMatRotateAxisAngle44f(mat_in, &unitAxis, angle_r, mat_out);
}

egwMatrix33f* egwMatRotateVecVec33f(const egwMatrix33f* mat_in, const egwVector2f* vec_fr, const egwVector2f* vec_to, egwMatrix33f* mat_out) {
    return egwMatRotateEuler33f(mat_in, egwVecCrossProd2f(vec_fr, vec_to), mat_out);
}

egwMatrix44f* egwMatRotateVecVec44f(const egwMatrix44f* mat_in, const egwVector3f* vec_fr, const egwVector3f* vec_to, egwMatrix44f* mat_out) {
    egwMatrix44f temp;
    temp.component.r1c4 = temp.component.r2c4 = temp.component.r3c4 =
        temp.component.r4c1 = temp.component.r4c2 = temp.component.r4c3 = 0.0f;
    temp.component.r4c4 = 1.0f;
    
    egwVector3f unitAxis;
    egwVecCrossProd3f(vec_fr, vec_to, &unitAxis);
    EGWsingle sa = egwVecMagnitude3f(&unitAxis);
    EGWsingle ca = egwVecDotProd3f(vec_fr, vec_to);
    egwVecNormalizeMag3f(&unitAxis, sa, &unitAxis);
    EGWsingle OneMinusCa = 1.0f - ca;
    EGWsingle OneMinusCaRxRy = OneMinusCa * unitAxis.axis.x * unitAxis.axis.y;
    EGWsingle OneMinusCaRxRz = OneMinusCa * unitAxis.axis.x * unitAxis.axis.z;
    EGWsingle OneMinusCaRyRz = OneMinusCa * unitAxis.axis.y * unitAxis.axis.z;
    EGWsingle RxSa = unitAxis.axis.x * sa;
    EGWsingle RySa = unitAxis.axis.y * sa;
    EGWsingle RzSa = unitAxis.axis.z * sa;
    temp.component.r1c1 = ca + (OneMinusCa * egwSqrd(unitAxis.axis.x)); temp.component.r1c2 = OneMinusCaRxRy - RzSa; temp.component.r1c3 = OneMinusCaRxRz + RySa;
    temp.component.r2c1 = OneMinusCaRxRy + RzSa; temp.component.r2c2 = ca + (OneMinusCa * egwSqrd(unitAxis.axis.y)); temp.component.r2c3 = OneMinusCaRyRz - RxSa;
    temp.component.r3c1 = OneMinusCaRxRz - RySa; temp.component.r3c2 = OneMinusCaRyRz + RxSa; temp.component.r3c3 = ca + (OneMinusCa * egwSqrd(unitAxis.axis.z));
    
    if(mat_in)
        egwMatMultiply44f(mat_in, &temp, mat_out);
    else {
        mat_out->component.r1c1 = temp.component.r1c1; mat_out->component.r1c2 = temp.component.r1c2; mat_out->component.r1c3 = temp.component.r1c3; mat_out->component.r1c4 = temp.component.r1c4;
        mat_out->component.r2c1 = temp.component.r2c1; mat_out->component.r2c2 = temp.component.r2c2; mat_out->component.r2c3 = temp.component.r2c3; mat_out->component.r2c4 = temp.component.r2c4;
        mat_out->component.r3c1 = temp.component.r3c1; mat_out->component.r3c2 = temp.component.r3c2; mat_out->component.r3c3 = temp.component.r3c3; mat_out->component.r3c4 = temp.component.r3c4;
        mat_out->component.r4c1 = temp.component.r4c1; mat_out->component.r4c2 = temp.component.r4c2; mat_out->component.r4c3 = temp.component.r4c3; mat_out->component.r4c4 = temp.component.r4c4;
    }
    
    return mat_out;
}

egwMatrix33f* egwMatRotateVecVec33fs(const egwMatrix33f* mat_in, const EGWsingle vecX_fr, const EGWsingle vecY_fr, const EGWsingle vecX_to, const EGWsingle vecY_to, egwMatrix33f* mat_out) {
    egwVector2f vec_fr, vec_to;
    vec_fr.axis.x = vecX_fr; vec_fr.axis.y = vecY_fr;
    vec_to.axis.x = vecX_to; vec_to.axis.y = vecY_to;
    return egwMatRotateVecVec33f(mat_in, &vec_fr, &vec_to, mat_out);
}

egwMatrix44f* egwMatRotateVecVec44fs(const egwMatrix44f* mat_in, const EGWsingle vecX_fr, const EGWsingle vecY_fr, const EGWsingle vecZ_fr, const EGWsingle vecX_to, const EGWsingle vecY_to, const EGWsingle vecZ_to, egwMatrix44f* mat_out) {
    egwVector3f vec_fr, vec_to;
    vec_fr.axis.x = vecX_fr; vec_fr.axis.y = vecY_fr; vec_fr.axis.z = vecZ_fr;
    vec_to.axis.x = vecX_to; vec_to.axis.y = vecY_to; vec_to.axis.z = vecZ_to;
    return egwMatRotateVecVec44f(mat_in, &vec_fr, &vec_to, mat_out);
}

egwMatrix44f* egwMatRotateQuaternion44f(const egwMatrix44f* mat_in, const egwQuaternion4f* quat_in, egwMatrix44f* mat_out) {
    egwMatrix44f temp;
    temp.component.r1c4 = temp.component.r2c4 = temp.component.r3c4 =
        temp.component.r4c1 = temp.component.r4c2 = temp.component.r4c3 = 0.0f;
    temp.component.r4c4 = 1.0f;
    
    EGWsingle twoxy = quat_in->axis.x * quat_in->axis.y; twoxy += twoxy;
    EGWsingle twowz = quat_in->axis.w * quat_in->axis.z; twowz += twowz;
    EGWsingle twoxz = quat_in->axis.x * quat_in->axis.z; twoxz += twoxz;
    EGWsingle twowy = quat_in->axis.w * quat_in->axis.y; twowy += twowy;
    EGWsingle twoyz = quat_in->axis.y * quat_in->axis.z; twoyz += twoyz;
    EGWsingle twowx = quat_in->axis.w * quat_in->axis.x; twowx += twowx;
    EGWsingle twoxx = egwSqrd(quat_in->axis.x); twoxx += twoxx;
    EGWsingle twoyy = egwSqrd(quat_in->axis.y); twoyy += twoyy;
    EGWsingle twozz = egwSqrd(quat_in->axis.z); twozz += twozz;
    temp.component.r1c1 = 1.0f - twoyy - twozz; temp.component.r1c2 = twoxy - twowz; temp.component.r1c3 = twoxz + twowy;
    temp.component.r2c1 = twoxy + twowz; temp.component.r2c2 = 1.0f - twoxx - twozz; temp.component.r2c3 = twoyz - twowx;
    temp.component.r3c1 = twoxz - twowy; temp.component.r3c2 = twoyz + twowx; temp.component.r3c3 = 1.0f - twoxx - twoyy;
    
    if(mat_in)
        egwMatMultiply44f(mat_in, &temp, mat_out);
    else {
        mat_out->component.r1c1 = temp.component.r1c1; mat_out->component.r1c2 = temp.component.r1c2; mat_out->component.r1c3 = temp.component.r1c3; mat_out->component.r1c4 = temp.component.r1c4;
        mat_out->component.r2c1 = temp.component.r2c1; mat_out->component.r2c2 = temp.component.r2c2; mat_out->component.r2c3 = temp.component.r2c3; mat_out->component.r2c4 = temp.component.r2c4;
        mat_out->component.r3c1 = temp.component.r3c1; mat_out->component.r3c2 = temp.component.r3c2; mat_out->component.r3c3 = temp.component.r3c3; mat_out->component.r3c4 = temp.component.r3c4;
        mat_out->component.r4c1 = temp.component.r4c1; mat_out->component.r4c2 = temp.component.r4c2; mat_out->component.r4c3 = temp.component.r4c3; mat_out->component.r4c4 = temp.component.r4c4;
    }
    
    return mat_out;
}

egwMatrix33f* egwMatTranslate33f(const egwMatrix33f* mat_in, const egwVector2f* pos, egwMatrix33f* mat_out) {
    if(mat_in) {
        egwMatrix33f temp;
        temp.component.r2c1 = temp.component.r3c1 =
            temp.component.r1c2 = temp.component.r3c2 = 0.0f;
        temp.component.r1c1 = temp.component.r2c2 = temp.component.r3c3 = 1.0f;
        
        temp.component.r1c3 = pos->axis.x;
        temp.component.r2c3 = pos->axis.y;
        
        egwMatMultiply33f(mat_in, &temp, mat_out);
    } else {
        mat_out->component.r2c1 = mat_out->component.r3c1 =
            mat_out->component.r1c2 = mat_out->component.r3c2 = 0.0f;
        mat_out->component.r1c1 = mat_out->component.r2c2 = mat_out->component.r3c3 = 1.0f;
        
        mat_out->component.r1c3 = pos->axis.x;
        mat_out->component.r2c3 = pos->axis.y;
    }
    
    return mat_out;
}

egwMatrix44f* egwMatTranslate44f(const egwMatrix44f* mat_in, const egwVector3f* pos, egwMatrix44f* mat_out) {
    if(mat_in) {
        egwMatrix44f temp;
        temp.component.r2c1 = temp.component.r3c1 = temp.component.r4c1 =
            temp.component.r1c2 = temp.component.r3c2 = temp.component.r4c2 =
            temp.component.r1c3 = temp.component.r2c3 = temp.component.r4c3 = 0.0f;
        temp.component.r1c1 = temp.component.r2c2 = temp.component.r3c3 = temp.component.r4c4 = 1.0f;
        
        temp.component.r1c4 = pos->axis.x;
        temp.component.r2c4 = pos->axis.y;
        temp.component.r3c4 = pos->axis.z;
        
        egwMatMultiply44f(mat_in, &temp, mat_out);
    } else {
        mat_out->component.r2c1 = mat_out->component.r3c1 = mat_out->component.r4c1 =
            mat_out->component.r1c2 = mat_out->component.r3c2 = mat_out->component.r4c2 =
            mat_out->component.r1c3 = mat_out->component.r2c3 = mat_out->component.r4c3 = 0.0f;
        mat_out->component.r1c1 = mat_out->component.r2c2 = mat_out->component.r3c3 = mat_out->component.r4c4 = 1.0f;
        
        mat_out->component.r1c4 = pos->axis.x;
        mat_out->component.r2c4 = pos->axis.y;
        mat_out->component.r3c4 = pos->axis.z;
    }
    
    return mat_out;
}

egwMatrix33f* egwMatTranslate33fs(const egwMatrix33f* mat_in, const EGWsingle posX, const EGWsingle posY, egwMatrix33f* mat_out) {
    if(mat_in) {
        egwMatrix33f temp;
        temp.component.r2c1 = temp.component.r3c1 =
            temp.component.r1c2 = temp.component.r3c2 = 0.0f;
        temp.component.r1c1 = temp.component.r2c2 = temp.component.r3c3 = 1.0f;
        
        temp.component.r1c3 = posX;
        temp.component.r2c3 = posY;
        
        egwMatMultiply33f(mat_in, &temp, mat_out);
    } else {
        mat_out->component.r2c1 = mat_out->component.r3c1 =
            mat_out->component.r1c2 = mat_out->component.r3c2 = 0.0f;
        mat_out->component.r1c1 = mat_out->component.r2c2 = mat_out->component.r3c3 = 1.0f;
        
        mat_out->component.r1c3 = posX;
        mat_out->component.r2c3 = posY;
    }
    
    return mat_out;
}

egwMatrix44f* egwMatTranslate44fs(const egwMatrix44f* mat_in, const EGWsingle posX, const EGWsingle posY, const EGWsingle posZ, egwMatrix44f* mat_out) {
    if(mat_in) {
        egwMatrix44f temp;
        temp.component.r2c1 = temp.component.r3c1 = temp.component.r4c1 =
            temp.component.r1c2 = temp.component.r3c2 = temp.component.r4c2 =
            temp.component.r1c3 = temp.component.r2c3 = temp.component.r4c3 = 0.0f;
        temp.component.r1c1 = temp.component.r2c2 = temp.component.r3c3 = temp.component.r4c4 = 1.0f;
        
        temp.component.r1c4 = posX;
        temp.component.r2c4 = posY;
        temp.component.r3c4 = posZ;
        
        egwMatMultiply44f(mat_in, &temp, mat_out);
    } else {
        mat_out->component.r2c1 = mat_out->component.r3c1 = mat_out->component.r4c1 =
            mat_out->component.r1c2 = mat_out->component.r3c2 = mat_out->component.r4c2 =
            mat_out->component.r1c3 = mat_out->component.r2c3 = mat_out->component.r4c3 = 0.0f;
        mat_out->component.r1c1 = mat_out->component.r2c2 = mat_out->component.r3c3 = mat_out->component.r4c4 = 1.0f;
        
        mat_out->component.r1c4 = posX;
        mat_out->component.r2c4 = posY;
        mat_out->component.r3c4 = posZ;
    }
    
    return mat_out;
}

egwMatrix33f* egwMatScale33f(const egwMatrix33f* mat_in, const egwVector2f* scale, egwMatrix33f* mat_out) {
    if(mat_in) {
        egwMatrix33f temp;
        temp.component.r2c1 = temp.component.r3c1 =
            temp.component.r1c2 = temp.component.r3c2 =
            temp.component.r1c3 = temp.component.r2c3 = 0.0f;
        temp.component.r3c3 = 1.0f;
        
        temp.component.r1c1 = scale->axis.x;
        temp.component.r2c2 = scale->axis.y;
        
        egwMatMultiply33f(mat_in, &temp, mat_out);
    } else {
        mat_out->component.r2c1 = mat_out->component.r3c1 =
            mat_out->component.r1c2 = mat_out->component.r3c2 =
            mat_out->component.r1c3 = mat_out->component.r2c3 = 0.0f;
        mat_out->component.r3c3 = 1.0f;
        
        mat_out->component.r1c1 = scale->axis.x;
        mat_out->component.r2c2 = scale->axis.y;
    }
    
    return mat_out;
}

egwMatrix44f* egwMatScale44f(const egwMatrix44f* mat_in, const egwVector3f* scale, egwMatrix44f* mat_out) {
    if(mat_in) {
        egwMatrix44f temp;
        temp.component.r2c1 = temp.component.r3c1 = temp.component.r4c1 =
            temp.component.r1c2 = temp.component.r3c2 = temp.component.r4c2 =
            temp.component.r1c3 = temp.component.r2c3 = temp.component.r4c3 =
            temp.component.r1c4 = temp.component.r2c4 = temp.component.r3c4 = 0.0f;
        temp.component.r4c4 = 1.0f;
        
        temp.component.r1c1 = scale->axis.x;
        temp.component.r2c2 = scale->axis.y;
        temp.component.r3c3 = scale->axis.z;
        
        egwMatMultiply44f(mat_in, &temp, mat_out);
    } else {
        mat_out->component.r2c1 = mat_out->component.r3c1 = mat_out->component.r4c1 =
            mat_out->component.r1c2 = mat_out->component.r3c2 = mat_out->component.r4c2 =
            mat_out->component.r1c3 = mat_out->component.r2c3 = mat_out->component.r4c3 =
            mat_out->component.r1c4 = mat_out->component.r2c4 = mat_out->component.r3c4 = 0.0f;
        mat_out->component.r4c4 = 1.0f;
        
        mat_out->component.r1c1 = scale->axis.x;
        mat_out->component.r2c2 = scale->axis.y;
        mat_out->component.r3c3 = scale->axis.z;
    }
    
    return mat_out;
}

egwMatrix33f* egwMatScale33fs(const egwMatrix33f* mat_in, const EGWsingle scaleX, const EGWsingle scaleY, egwMatrix33f* mat_out) {
    if(mat_in) {
        egwMatrix33f temp;
        temp.component.r2c1 = temp.component.r3c1 =
            temp.component.r1c2 = temp.component.r3c2 =
            temp.component.r1c3 = temp.component.r2c3 = 0.0f;
        temp.component.r3c3 = 1.0f;
        
        temp.component.r1c1 = scaleX;
        temp.component.r2c2 = scaleY;
        
        egwMatMultiply33f(mat_in, &temp, mat_out);
    } else {
        mat_out->component.r2c1 = mat_out->component.r3c1 =
            mat_out->component.r1c2 = mat_out->component.r3c2 =
            mat_out->component.r1c3 = mat_out->component.r2c3 = 0.0f;
        mat_out->component.r3c3 = 1.0f;
        
        mat_out->component.r1c1 = scaleX;
        mat_out->component.r2c2 = scaleY;
    }
    
    return mat_out;
}

egwMatrix44f* egwMatScale44fs(const egwMatrix44f* mat_in, const EGWsingle scaleX, const EGWsingle scaleY, const EGWsingle scaleZ, egwMatrix44f* mat_out) {
    if(mat_in) {
        egwMatrix44f temp;
        temp.component.r2c1 = temp.component.r3c1 = temp.component.r4c1 =
            temp.component.r1c2 = temp.component.r3c2 = temp.component.r4c2 =
            temp.component.r1c3 = temp.component.r2c3 = temp.component.r4c3 =
            temp.component.r1c4 = temp.component.r2c4 = temp.component.r3c4 = 0.0f;
        temp.component.r4c4 = 1.0f;
        
        temp.component.r1c1 = scaleX;
        temp.component.r2c2 = scaleY;
        temp.component.r3c3 = scaleZ;
        
        egwMatMultiply44f(mat_in, &temp, mat_out);
    } else {
        mat_out->component.r2c1 = mat_out->component.r3c1 = mat_out->component.r4c1 =
            mat_out->component.r1c2 = mat_out->component.r3c2 = mat_out->component.r4c2 =
            mat_out->component.r1c3 = mat_out->component.r2c3 = mat_out->component.r4c3 =
            mat_out->component.r1c4 = mat_out->component.r2c4 = mat_out->component.r3c4 = 0.0f;
        mat_out->component.r4c4 = 1.0f;
        
        mat_out->component.r1c1 = scaleX;
        mat_out->component.r2c2 = scaleY;
        mat_out->component.r3c3 = scaleZ;
    }
    
    return mat_out;
}

egwMatrix33f* egwMatUScale33f(const egwMatrix33f* mat_in, const EGWsingle scaleU, egwMatrix33f* mat_out) {
    if(mat_in) {
        egwMatrix33f temp;
        temp.component.r2c1 = temp.component.r3c1 =
            temp.component.r1c2 = temp.component.r3c2 =
            temp.component.r1c3 = temp.component.r2c3 = 0.0f;
        temp.component.r3c3 = 1.0f;
        
        temp.component.r1c1 = scaleU;
        temp.component.r2c2 = scaleU;
        
        egwMatMultiply33f(mat_in, &temp, mat_out);
    } else {
        mat_out->component.r2c1 = mat_out->component.r3c1 =
            mat_out->component.r1c2 = mat_out->component.r3c2 =
            mat_out->component.r1c3 = mat_out->component.r2c3 = 0.0f;
        mat_out->component.r3c3 = 1.0f;
        
        mat_out->component.r1c1 = scaleU;
        mat_out->component.r2c2 = scaleU;
    }
    
    return mat_out;
}

egwMatrix44f* egwMatUScale44f(const egwMatrix44f* mat_in, const EGWsingle scaleU, egwMatrix44f* mat_out) {
    if(mat_in) {
        egwMatrix44f temp;
        temp.component.r2c1 = temp.component.r3c1 = temp.component.r4c1 =
            temp.component.r1c2 = temp.component.r3c2 = temp.component.r4c2 =
            temp.component.r1c3 = temp.component.r2c3 = temp.component.r4c3 =
            temp.component.r1c4 = temp.component.r2c4 = temp.component.r3c4 = 0.0f;
        temp.component.r4c4 = 1.0f;
        
        temp.component.r1c1 = scaleU;
        temp.component.r2c2 = scaleU;
        temp.component.r3c3 = scaleU;
        
        egwMatMultiply44f(mat_in, &temp, mat_out);
    } else {
        mat_out->component.r2c1 = mat_out->component.r3c1 = mat_out->component.r4c1 =
            mat_out->component.r1c2 = mat_out->component.r3c2 = mat_out->component.r4c2 =
            mat_out->component.r1c3 = mat_out->component.r2c3 = mat_out->component.r4c3 =
            mat_out->component.r1c4 = mat_out->component.r2c4 = mat_out->component.r3c4 = 0.0f;
        mat_out->component.r4c4 = 1.0f;
        
        mat_out->component.r1c1 = scaleU;
        mat_out->component.r2c2 = scaleU;
        mat_out->component.r3c3 = scaleU;
    }
    
    return mat_out;
}

egwMatrix33f* egwMatShear33f(const egwMatrix33f* mat_in, const EGWsingle shear, const EGWint type, egwMatrix33f* mat_out) {
    egwMatrix33f temp;
    temp.component.r2c1 = temp.component.r3c1 =
        temp.component.r1c2 = temp.component.r3c2 =
        temp.component.r1c3 = temp.component.r2c3 = 0.0f;
    temp.component.r1c1 = temp.component.r2c2 = temp.component.r3c3 = 1.0f;
    
    switch(type) {
        case EGW_MATRIX_SHEAR_TYPE_XBYY: {
            temp.component.r1c2 = shear;
        } break;
        case EGW_MATRIX_SHEAR_TYPE_YBYX: {
            temp.component.r2c1 = shear;
        } break;
        default: {
        } break;
    }
    
    if(mat_in)
        egwMatMultiply33f(mat_in, &temp, mat_out);
    else {
        mat_out->component.r1c1 = temp.component.r1c1; mat_out->component.r1c2 = temp.component.r1c2; mat_out->component.r1c3 = temp.component.r1c3;
        mat_out->component.r2c1 = temp.component.r2c1; mat_out->component.r2c2 = temp.component.r2c2; mat_out->component.r2c3 = temp.component.r2c3;
        mat_out->component.r3c1 = temp.component.r3c1; mat_out->component.r3c2 = temp.component.r3c2; mat_out->component.r3c3 = temp.component.r3c3;
    }
    
    return mat_out;
}

egwMatrix44f* egwMatShear44f(const egwMatrix44f* mat_in, const EGWsingle shear, const EGWint type, egwMatrix44f* mat_out) {
    egwMatrix44f temp;
    temp.component.r2c1 = temp.component.r3c1 = temp.component.r4c1 =
        temp.component.r1c2 = temp.component.r3c2 = temp.component.r4c2 =
        temp.component.r1c3 = temp.component.r2c3 = temp.component.r4c3 =
        temp.component.r1c4 = temp.component.r2c4 = temp.component.r3c4 = 0.0f;
    temp.component.r1c1 = temp.component.r2c2 = temp.component.r3c3 = temp.component.r4c4 = 1.0f;
    
    if(type & EGW_MATRIX_SHEAR_TYPE_XBYY)
        temp.component.r1c2 = shear;
    if(type & EGW_MATRIX_SHEAR_TYPE_XBYZ)
        temp.component.r1c3 = shear;
    if(type & EGW_MATRIX_SHEAR_TYPE_YBYX)
        temp.component.r2c1 = shear;
    if(type & EGW_MATRIX_SHEAR_TYPE_YBYZ)
        temp.component.r2c3 = shear;
    if(type & EGW_MATRIX_SHEAR_TYPE_ZBYX)
        temp.component.r3c1 = shear;
    if(type & EGW_MATRIX_SHEAR_TYPE_ZBYY)
        temp.component.r3c2 = shear;
    
    if(mat_in)
        egwMatMultiply44f(mat_in, &temp, mat_out);
    else {
        mat_out->component.r1c1 = temp.component.r1c1; mat_out->component.r1c2 = temp.component.r1c2; mat_out->component.r1c3 = temp.component.r1c3; mat_out->component.r1c4 = temp.component.r1c4;
        mat_out->component.r2c1 = temp.component.r2c1; mat_out->component.r2c2 = temp.component.r2c2; mat_out->component.r2c3 = temp.component.r2c3; mat_out->component.r2c4 = temp.component.r2c4;
        mat_out->component.r3c1 = temp.component.r3c1; mat_out->component.r3c2 = temp.component.r3c2; mat_out->component.r3c3 = temp.component.r3c3; mat_out->component.r3c4 = temp.component.r3c4;
        mat_out->component.r4c1 = temp.component.r4c1; mat_out->component.r4c2 = temp.component.r4c2; mat_out->component.r4c3 = temp.component.r4c3; mat_out->component.r4c4 = temp.component.r4c4;
    }
    
    return mat_out;
}

egwVector2f* egwVecTransform332f(const egwMatrix33f* mat_lhs, const egwVector2f* vec_rhs, const EGWsingle w_in, egwVector2f* vec_out) {
    if(vec_rhs == vec_out) {
        egwVector2f temp;
        temp.axis.x = (mat_lhs->component.r1c1 * vec_rhs->axis.x) + (mat_lhs->component.r1c2 * vec_rhs->axis.y) + (mat_lhs->component.r1c3 * w_in);
        temp.axis.y = (mat_lhs->component.r2c1 * vec_rhs->axis.x) + (mat_lhs->component.r2c2 * vec_rhs->axis.y) + (mat_lhs->component.r2c3 * w_in);
        vec_out->axis.x = temp.axis.x; vec_out->axis.y = temp.axis.y;
    } else {
        vec_out->axis.x = (mat_lhs->component.r1c1 * vec_rhs->axis.x) + (mat_lhs->component.r1c2 * vec_rhs->axis.y) + (mat_lhs->component.r1c3 * w_in);
        vec_out->axis.y = (mat_lhs->component.r2c1 * vec_rhs->axis.x) + (mat_lhs->component.r2c2 * vec_rhs->axis.y) + (mat_lhs->component.r2c3 * w_in);
    }
    
    return vec_out;
}

egwVector3f* egwVecTransform333f(const egwMatrix33f* mat_lhs, const egwVector3f* vec_rhs, egwVector3f* vec_out) {
    if(vec_rhs == vec_out) {
        egwVector2f temp;
        temp.axis.x = (mat_lhs->component.r1c1 * vec_rhs->axis.x) + (mat_lhs->component.r1c2 * vec_rhs->axis.y) + (mat_lhs->component.r1c3 * vec_rhs->axis.z);
        temp.axis.y = (mat_lhs->component.r2c1 * vec_rhs->axis.x) + (mat_lhs->component.r2c2 * vec_rhs->axis.y) + (mat_lhs->component.r2c3 * vec_rhs->axis.z);
        vec_out->axis.x = temp.axis.x; vec_out->axis.y = temp.axis.y;
    } else {
        vec_out->axis.x = (mat_lhs->component.r1c1 * vec_rhs->axis.x) + (mat_lhs->component.r1c2 * vec_rhs->axis.y) + (mat_lhs->component.r1c3 * vec_rhs->axis.z);
        vec_out->axis.y = (mat_lhs->component.r2c1 * vec_rhs->axis.x) + (mat_lhs->component.r2c2 * vec_rhs->axis.y) + (mat_lhs->component.r2c3 * vec_rhs->axis.z);
        vec_out->axis.z = vec_rhs->axis.z;
    }
    
    return vec_out;
}

egwVector3f* egwVecTransform443f(const egwMatrix44f* mat_lhs, const egwVector3f* vec_rhs, const EGWsingle w_in, egwVector3f* vec_out) {
    if(vec_rhs == vec_out) {
        egwVector3f temp;
        temp.axis.x = (mat_lhs->component.r1c1 * vec_rhs->axis.x) + (mat_lhs->component.r1c2 * vec_rhs->axis.y) + (mat_lhs->component.r1c3 * vec_rhs->axis.z) + (mat_lhs->component.r1c4 * w_in);
        temp.axis.y = (mat_lhs->component.r2c1 * vec_rhs->axis.x) + (mat_lhs->component.r2c2 * vec_rhs->axis.y) + (mat_lhs->component.r2c3 * vec_rhs->axis.z) + (mat_lhs->component.r2c4 * w_in);
        temp.axis.z = (mat_lhs->component.r3c1 * vec_rhs->axis.x) + (mat_lhs->component.r3c2 * vec_rhs->axis.y) + (mat_lhs->component.r3c3 * vec_rhs->axis.z) + (mat_lhs->component.r3c4 * w_in);
        vec_out->axis.x = temp.axis.x; vec_out->axis.y = temp.axis.y; vec_out->axis.z = temp.axis.z;
    } else {
        vec_out->axis.x = (mat_lhs->component.r1c1 * vec_rhs->axis.x) + (mat_lhs->component.r1c2 * vec_rhs->axis.y) + (mat_lhs->component.r1c3 * vec_rhs->axis.z) + (mat_lhs->component.r1c4 * w_in);
        vec_out->axis.y = (mat_lhs->component.r2c1 * vec_rhs->axis.x) + (mat_lhs->component.r2c2 * vec_rhs->axis.y) + (mat_lhs->component.r2c3 * vec_rhs->axis.z) + (mat_lhs->component.r2c4 * w_in);
        vec_out->axis.z = (mat_lhs->component.r3c1 * vec_rhs->axis.x) + (mat_lhs->component.r3c2 * vec_rhs->axis.y) + (mat_lhs->component.r3c3 * vec_rhs->axis.z) + (mat_lhs->component.r3c4 * w_in);
    }
    
    return vec_out;
}

egwVector4f* egwVecTransform444f(const egwMatrix44f* mat_lhs, const egwVector4f* vec_rhs, egwVector4f* vec_out) {
    if(vec_rhs == vec_out) {
        egwVector3f temp;
        temp.axis.x = (mat_lhs->component.r1c1 * vec_rhs->axis.x) + (mat_lhs->component.r1c2 * vec_rhs->axis.y) + (mat_lhs->component.r1c3 * vec_rhs->axis.z) + (mat_lhs->component.r1c4 * vec_rhs->axis.w);
        temp.axis.y = (mat_lhs->component.r2c1 * vec_rhs->axis.x) + (mat_lhs->component.r2c2 * vec_rhs->axis.y) + (mat_lhs->component.r2c3 * vec_rhs->axis.z) + (mat_lhs->component.r2c4 * vec_rhs->axis.w);
        temp.axis.z = (mat_lhs->component.r3c1 * vec_rhs->axis.x) + (mat_lhs->component.r3c2 * vec_rhs->axis.y) + (mat_lhs->component.r3c3 * vec_rhs->axis.z) + (mat_lhs->component.r3c4 * vec_rhs->axis.w);
        vec_out->axis.x = temp.axis.x; vec_out->axis.y = temp.axis.y; vec_out->axis.z = temp.axis.z;
    } else {
        vec_out->axis.x = (mat_lhs->component.r1c1 * vec_rhs->axis.x) + (mat_lhs->component.r1c2 * vec_rhs->axis.y) + (mat_lhs->component.r1c3 * vec_rhs->axis.z) + (mat_lhs->component.r1c4 * vec_rhs->axis.w);
        vec_out->axis.y = (mat_lhs->component.r2c1 * vec_rhs->axis.x) + (mat_lhs->component.r2c2 * vec_rhs->axis.y) + (mat_lhs->component.r2c3 * vec_rhs->axis.z) + (mat_lhs->component.r2c4 * vec_rhs->axis.w);
        vec_out->axis.z = (mat_lhs->component.r3c1 * vec_rhs->axis.x) + (mat_lhs->component.r3c2 * vec_rhs->axis.y) + (mat_lhs->component.r3c3 * vec_rhs->axis.z) + (mat_lhs->component.r3c4 * vec_rhs->axis.w);
        vec_out->axis.w = vec_rhs->axis.w;
    }
    
    return vec_out;
}

void egwVecTransform332fv(const egwMatrix33f* mats_lhs, const egwVector2f* vecs_rhs, const EGWsingle* ws_in, egwVector2f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        if(vecs_rhs == vecs_out) {
            egwVector2f temp;
            temp.axis.x = (mats_lhs->component.r1c1 * vecs_rhs->axis.x) + (mats_lhs->component.r1c2 * vecs_rhs->axis.y) + (mats_lhs->component.r1c3 * *ws_in);
            temp.axis.y = (mats_lhs->component.r2c1 * vecs_rhs->axis.x) + (mats_lhs->component.r2c2 * vecs_rhs->axis.y) + (mats_lhs->component.r2c3 * *ws_in);
            vecs_out->axis.x = temp.axis.x; vecs_out->axis.y = temp.axis.y;
        } else {
            vecs_out->axis.x = (mats_lhs->component.r1c1 * vecs_rhs->axis.x) + (mats_lhs->component.r1c2 * vecs_rhs->axis.y) + (mats_lhs->component.r1c3 * *ws_in);
            vecs_out->axis.y = (mats_lhs->component.r2c1 * vecs_rhs->axis.x) + (mats_lhs->component.r2c2 * vecs_rhs->axis.y) + (mats_lhs->component.r2c3 * *ws_in);
        }
        
        mats_lhs = (const egwMatrix33f*)((EGWintptr)mats_lhs + (EGWintptr)sizeof(egwMatrix33f) + strideB_lhs);
        vecs_rhs = (const egwVector2f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector2f) + strideB_rhs);
        ws_in = (const EGWsingle*)((EGWintptr)ws_in + (EGWintptr)sizeof(EGWsingle) + strideB_in);
        vecs_out = (egwVector2f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector2f) + strideB_out);
    }
}

void egwVecTransform333fv(const egwMatrix33f* mats_lhs, const egwVector3f* vecs_rhs, egwVector3f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        if(vecs_rhs == vecs_out) {
            egwVector2f temp;
            temp.axis.x = (mats_lhs->component.r1c1 * vecs_rhs->axis.x) + (mats_lhs->component.r1c2 * vecs_rhs->axis.y) + (mats_lhs->component.r1c3 * vecs_rhs->axis.z);
            temp.axis.y = (mats_lhs->component.r2c1 * vecs_rhs->axis.x) + (mats_lhs->component.r2c2 * vecs_rhs->axis.y) + (mats_lhs->component.r2c3 * vecs_rhs->axis.z);
            vecs_out->axis.x = temp.axis.x; vecs_out->axis.y = temp.axis.y;
        } else {
            vecs_out->axis.x = (mats_lhs->component.r1c1 * vecs_rhs->axis.x) + (mats_lhs->component.r1c2 * vecs_rhs->axis.y) + (mats_lhs->component.r1c3 * vecs_rhs->axis.z);
            vecs_out->axis.y = (mats_lhs->component.r2c1 * vecs_rhs->axis.x) + (mats_lhs->component.r2c2 * vecs_rhs->axis.y) + (mats_lhs->component.r2c3 * vecs_rhs->axis.z);
            vecs_out->axis.z = vecs_rhs->axis.z;
        }
        
        mats_lhs = (const egwMatrix33f*)((EGWintptr)mats_lhs + (EGWintptr)sizeof(egwMatrix33f) + strideB_lhs);
        vecs_rhs = (const egwVector3f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector3f) + strideB_rhs);
        vecs_out = (egwVector3f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector3f) + strideB_out);
    }
}

void egwVecTransform443fv(const egwMatrix44f* mats_lhs, const egwVector3f* vecs_rhs, const EGWsingle* ws_in, egwVector3f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        if(vecs_rhs == vecs_out) {
            egwVector3f temp;
            temp.axis.x = (mats_lhs->component.r1c1 * vecs_rhs->axis.x) + (mats_lhs->component.r1c2 * vecs_rhs->axis.y) + (mats_lhs->component.r1c3 * vecs_rhs->axis.z) + (mats_lhs->component.r1c4 * *ws_in);
            temp.axis.y = (mats_lhs->component.r2c1 * vecs_rhs->axis.x) + (mats_lhs->component.r2c2 * vecs_rhs->axis.y) + (mats_lhs->component.r2c3 * vecs_rhs->axis.z) + (mats_lhs->component.r2c4 * *ws_in);
            temp.axis.z = (mats_lhs->component.r3c1 * vecs_rhs->axis.x) + (mats_lhs->component.r3c2 * vecs_rhs->axis.y) + (mats_lhs->component.r3c3 * vecs_rhs->axis.z) + (mats_lhs->component.r3c4 * *ws_in);
            vecs_out->axis.x = temp.axis.x; vecs_out->axis.y = temp.axis.y; vecs_out->axis.z = temp.axis.z;
        } else {
            vecs_out->axis.x = (mats_lhs->component.r1c1 * vecs_rhs->axis.x) + (mats_lhs->component.r1c2 * vecs_rhs->axis.y) + (mats_lhs->component.r1c3 * vecs_rhs->axis.z) + (mats_lhs->component.r1c4 * *ws_in);
            vecs_out->axis.y = (mats_lhs->component.r2c1 * vecs_rhs->axis.x) + (mats_lhs->component.r2c2 * vecs_rhs->axis.y) + (mats_lhs->component.r2c3 * vecs_rhs->axis.z) + (mats_lhs->component.r2c4 * *ws_in);
            vecs_out->axis.z = (mats_lhs->component.r3c1 * vecs_rhs->axis.x) + (mats_lhs->component.r3c2 * vecs_rhs->axis.y) + (mats_lhs->component.r3c3 * vecs_rhs->axis.z) + (mats_lhs->component.r3c4 * *ws_in);
        }
        
        mats_lhs = (const egwMatrix44f*)((EGWintptr)mats_lhs + (EGWintptr)sizeof(egwMatrix44f) + strideB_lhs);
        vecs_rhs = (const egwVector3f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector3f) + strideB_rhs);
        ws_in = (const EGWsingle*)((EGWintptr)ws_in + (EGWintptr)sizeof(EGWsingle) + strideB_in);
        vecs_out = (egwVector3f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector3f) + strideB_out);
    }
}

void egwVecTransform444fv(const egwMatrix44f* mats_lhs, const egwVector4f* vecs_rhs, egwVector4f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        if(vecs_rhs == vecs_out) {
            egwVector3f temp;
            temp.axis.x = (mats_lhs->component.r1c1 * vecs_rhs->axis.x) + (mats_lhs->component.r1c2 * vecs_rhs->axis.y) + (mats_lhs->component.r1c3 * vecs_rhs->axis.z) + (mats_lhs->component.r1c4 * vecs_rhs->axis.w);
            temp.axis.y = (mats_lhs->component.r2c1 * vecs_rhs->axis.x) + (mats_lhs->component.r2c2 * vecs_rhs->axis.y) + (mats_lhs->component.r2c3 * vecs_rhs->axis.z) + (mats_lhs->component.r2c4 * vecs_rhs->axis.w);
            temp.axis.z = (mats_lhs->component.r3c1 * vecs_rhs->axis.x) + (mats_lhs->component.r3c2 * vecs_rhs->axis.y) + (mats_lhs->component.r3c3 * vecs_rhs->axis.z) + (mats_lhs->component.r3c4 * vecs_rhs->axis.w);
            vecs_out->axis.x = temp.axis.x; vecs_out->axis.y = temp.axis.y; vecs_out->axis.z = temp.axis.z;
        } else {
            vecs_out->axis.x = (mats_lhs->component.r1c1 * vecs_rhs->axis.x) + (mats_lhs->component.r1c2 * vecs_rhs->axis.y) + (mats_lhs->component.r1c3 * vecs_rhs->axis.z) + (mats_lhs->component.r1c4 * vecs_rhs->axis.w);
            vecs_out->axis.y = (mats_lhs->component.r2c1 * vecs_rhs->axis.x) + (mats_lhs->component.r2c2 * vecs_rhs->axis.y) + (mats_lhs->component.r2c3 * vecs_rhs->axis.z) + (mats_lhs->component.r2c4 * vecs_rhs->axis.w);
            vecs_out->axis.z = (mats_lhs->component.r3c1 * vecs_rhs->axis.x) + (mats_lhs->component.r3c2 * vecs_rhs->axis.y) + (mats_lhs->component.r3c3 * vecs_rhs->axis.z) + (mats_lhs->component.r3c4 * vecs_rhs->axis.w);
            vecs_out->axis.w = vecs_rhs->axis.w;
        }
        
        mats_lhs = (const egwMatrix44f*)((EGWintptr)mats_lhs + (EGWintptr)sizeof(egwMatrix44f) + strideB_lhs);
        vecs_rhs = (const egwVector4f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector4f) + strideB_rhs);
        vecs_out = (egwVector4f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector4f) + strideB_out);
    }
}

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

/// @file egwQuaternion.m
/// @ingroup geWizES_math_quaternion
/// Quaternion Implementation.

#import "egwQuaternion.h"
#import "egwMath.h"
#import "egwVector.h"


const egwQuaternion4f egwSIQuatIdentity4f =   {1.0f,  0.0f, 0.0f, 0.0f};
const egwQuaternion4f egwSIQuatZero4f =       {0.0f,  0.0f, 0.0f, 0.0f};


egwQuaternion4f* egwQuatInit4f(egwQuaternion4f* quat_out, const EGWsingle w, const EGWsingle x, const EGWsingle y, const EGWsingle z) {
    quat_out->axis.w = w;
    quat_out->axis.x = x;
    quat_out->axis.y = y;
    quat_out->axis.z = z;
    return quat_out;
}

void egwQuatInit4fv(egwQuaternion4f* quats_out, const EGWsingle w, const EGWsingle x, const EGWsingle y, const EGWsingle z, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        quats_out->axis.w = w;
        quats_out->axis.x = x;
        quats_out->axis.y = y;
        quats_out->axis.z = z;
        quats_out = (egwQuaternion4f*)((EGWintptr)quats_out + (EGWintptr)sizeof(egwQuaternion4f) + strideB_out);
    }
}

egwQuaternion4f* egwQuatCopy4f(const egwQuaternion4f* quat_in, egwQuaternion4f* quat_out) {
    quat_out->axis.w = quat_in->axis.w;
    quat_out->axis.x = quat_in->axis.x;
    quat_out->axis.y = quat_in->axis.y;
    quat_out->axis.z = quat_in->axis.z;
    return quat_out;
}

void egwQuatCopy4fv(const egwQuaternion4f* quats_in, egwQuaternion4f* quats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        quats_out->axis.w = quats_in->axis.w;
        quats_out->axis.x = quats_in->axis.x;
        quats_out->axis.y = quats_in->axis.y;
        quats_out->axis.z = quats_in->axis.z;
        quats_in = (const egwQuaternion4f*)((EGWintptr)quats_in + (EGWintptr)sizeof(egwQuaternion4f) + strideB_in);
        quats_out = (egwQuaternion4f*)((EGWintptr)quats_out + (EGWintptr)sizeof(egwQuaternion4f) + strideB_out);
    }
}

EGWint egwQuatIsEqual4f(const egwQuaternion4f* quat_lhs, const egwQuaternion4f* quat_rhs) {
    // FIXME: It can't possibly be this simple... -jw
    return ((quat_lhs == quat_rhs) || (egwIsEqualf(quat_lhs->axis.w, quat_rhs->axis.w) && egwIsEqualf(quat_lhs->axis.x, quat_rhs->axis.x) && egwIsEqualf(quat_lhs->axis.y, quat_rhs->axis.y) && egwIsEqualf(quat_lhs->axis.z, quat_rhs->axis.z)) ? 1 : 0);
}

EGWsingle egwQuatTensor4f(const egwQuaternion4f* quat_in) {
    return (quat_in->axis.w * quat_in->axis.w) + (quat_in->axis.x * quat_in->axis.x) + (quat_in->axis.y * quat_in->axis.y) + (quat_in->axis.z * quat_in->axis.z);
}

void egwQuatTensor4fv(const egwQuaternion4f* quats_in, EGWsingle* tsrs_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        *tsrs_out = (quats_in->axis.w * quats_in->axis.w) + (quats_in->axis.x * quats_in->axis.x) + (quats_in->axis.y * quats_in->axis.y) + (quats_in->axis.z * quats_in->axis.z);
        quats_in = (const egwQuaternion4f*)((EGWintptr)quats_in + (EGWintptr)sizeof(egwQuaternion4f) + strideB_in);
        tsrs_out = (EGWsingle*)((EGWintptr)tsrs_out + (EGWintptr)sizeof(EGWsingle) + strideB_out);
    }
}

egwQuaternion4f* egwQuatNormalize4f(const egwQuaternion4f* quat_in, egwQuaternion4f* quat_out) {
    EGWsingle factor = egwInvSqrtf((quat_in->axis.w * quat_in->axis.w) + (quat_in->axis.x * quat_in->axis.x) + (quat_in->axis.y * quat_in->axis.y) + (quat_in->axis.z * quat_in->axis.z));
    quat_out->axis.w = quat_in->axis.w * factor;
    quat_out->axis.x = quat_in->axis.x * factor;
    quat_out->axis.y = quat_in->axis.y * factor;
    quat_out->axis.z = quat_in->axis.z * factor;
    return quat_out;
}

void egwQuatNormalize4fv(const egwQuaternion4f* quats_in, egwQuaternion4f* quats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    EGWsingle factor;
    while(count--) {
        factor = egwInvSqrtf((quats_in->axis.w * quats_in->axis.w) + (quats_in->axis.x * quats_in->axis.x) + (quats_in->axis.y * quats_in->axis.y) + (quats_in->axis.z * quats_in->axis.z));
        quats_out->axis.w = quats_in->axis.w * factor;
        quats_out->axis.x = quats_in->axis.x * factor;
        quats_out->axis.y = quats_in->axis.y * factor;
        quats_out->axis.z = quats_in->axis.z * factor;
        quats_in = (const egwQuaternion4f*)((EGWintptr)quats_in + (EGWintptr)sizeof(egwQuaternion4f) + strideB_in);
        quats_out = (egwQuaternion4f*)((EGWintptr)quats_out + (EGWintptr)sizeof(egwQuaternion4f) + strideB_out);
    }
}

egwQuaternion4f* egwQuatFastNormalize4f(const egwQuaternion4f* quat_in, egwQuaternion4f* quat_out) {
    EGWsingle factor = egwFastInvSqrtf((quat_in->axis.w * quat_in->axis.w) + (quat_in->axis.x * quat_in->axis.x) + (quat_in->axis.y * quat_in->axis.y) + (quat_in->axis.z * quat_in->axis.z));
    quat_out->axis.w = quat_in->axis.w * factor;
    quat_out->axis.x = quat_in->axis.x * factor;
    quat_out->axis.y = quat_in->axis.y * factor;
    quat_out->axis.z = quat_in->axis.z * factor;
    return quat_out;
}

void egwQuatFastNormalize4fv(const egwQuaternion4f* quats_in, egwQuaternion4f* quats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    EGWsingle factor;
    while(count--) {
        factor = egwFastInvSqrtf((quats_in->axis.w * quats_in->axis.w) + (quats_in->axis.x * quats_in->axis.x) + (quats_in->axis.y * quats_in->axis.y) + (quats_in->axis.z * quats_in->axis.z));
        quats_out->axis.w = quats_in->axis.w * factor;
        quats_out->axis.x = quats_in->axis.x * factor;
        quats_out->axis.y = quats_in->axis.y * factor;
        quats_out->axis.z = quats_in->axis.z * factor;
        quats_in = (const egwQuaternion4f*)((EGWintptr)quats_in + (EGWintptr)sizeof(egwQuaternion4f) + strideB_in);
        quats_out = (egwQuaternion4f*)((EGWintptr)quats_out + (EGWintptr)sizeof(egwQuaternion4f) + strideB_out);
    }
}

egwQuaternion4f* egwQuatConjugate4f(const egwQuaternion4f* quat_in, egwQuaternion4f* quat_out) {
    quat_out->axis.w = quat_in->axis.w;
    quat_out->axis.x = -quat_in->axis.x;
    quat_out->axis.y = -quat_in->axis.y;
    quat_out->axis.z = -quat_in->axis.z;
    return quat_out;
}

void egwQuatConjugate4fv(const egwQuaternion4f* quats_in, egwQuaternion4f* quats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        quats_out->axis.w = quats_in->axis.w;
        quats_out->axis.x = -quats_in->axis.x;
        quats_out->axis.y = -quats_in->axis.y;
        quats_out->axis.z = -quats_in->axis.z;
        quats_in = (const egwQuaternion4f*)((EGWintptr)quats_in + (EGWintptr)sizeof(egwQuaternion4f) + strideB_in);
        quats_out = (egwQuaternion4f*)((EGWintptr)quats_out + (EGWintptr)sizeof(egwQuaternion4f) + strideB_out);
    }
}

egwQuaternion4f* egwQuatNegate4f(const egwQuaternion4f* quat_in, egwQuaternion4f* quat_out) {
    quat_out->axis.w = -quat_in->axis.w;
    quat_out->axis.x = -quat_in->axis.x;
    quat_out->axis.y = -quat_in->axis.y;
    quat_out->axis.z = -quat_in->axis.z;
    return quat_out;
}

void egwQuatNegate4fv(const egwQuaternion4f* quats_in, egwQuaternion4f* quats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        quats_out->axis.w = -quats_in->axis.w;
        quats_out->axis.x = -quats_in->axis.x;
        quats_out->axis.y = -quats_in->axis.y;
        quats_out->axis.z = -quats_in->axis.z;
        quats_in = (const egwQuaternion4f*)((EGWintptr)quats_in + (EGWintptr)sizeof(egwQuaternion4f) + strideB_in);
        quats_out = (egwQuaternion4f*)((EGWintptr)quats_out + (EGWintptr)sizeof(egwQuaternion4f) + strideB_out);
    }
}

egwQuaternion4f* egwQuatInvert4f(const egwQuaternion4f* quat_in, egwQuaternion4f* quat_out) {
    EGWsingle factor = 1.0f / ((quat_in->axis.w * quat_in->axis.w) + (quat_in->axis.x * quat_in->axis.x) + (quat_in->axis.y * quat_in->axis.y) + (quat_in->axis.z * quat_in->axis.z));
    quat_out->axis.w = quat_in->axis.w * factor;
    quat_out->axis.x = -quat_in->axis.x * factor;
    quat_out->axis.y = -quat_in->axis.y * factor;
    quat_out->axis.z = -quat_in->axis.z * factor;
    return quat_out;
}

void egwQuatInvert4fv(const egwQuaternion4f* quats_in, egwQuaternion4f* quats_out, const EGWintptr strideB_in, const EGWintptr strideB_out, EGWuint count) {
    EGWsingle factor;
    while(count--) {
        factor = 1.0f / ((quats_in->axis.w * quats_in->axis.w) + (quats_in->axis.x * quats_in->axis.x) + (quats_in->axis.y * quats_in->axis.y) + (quats_in->axis.z * quats_in->axis.z));
        quats_out->axis.w = quats_in->axis.w * factor;
        quats_out->axis.x = -quats_in->axis.x * factor;
        quats_out->axis.y = -quats_in->axis.y * factor;
        quats_out->axis.z = -quats_in->axis.z * factor;
        quats_in = (const egwQuaternion4f*)((EGWintptr)quats_in + (EGWintptr)sizeof(egwQuaternion4f) + strideB_in);
        quats_out = (egwQuaternion4f*)((EGWintptr)quats_out + (EGWintptr)sizeof(egwQuaternion4f) + strideB_out);
    }
}

egwQuaternion4f* egwQuatAdd4f(const egwQuaternion4f* quat_lhs, const egwQuaternion4f* quat_rhs, egwQuaternion4f* quat_out) {
    quat_out->axis.w = quat_lhs->axis.w + quat_rhs->axis.w;
    quat_out->axis.x = quat_lhs->axis.x + quat_rhs->axis.x;
    quat_out->axis.y = quat_lhs->axis.y + quat_rhs->axis.y;
    quat_out->axis.z = quat_lhs->axis.z + quat_rhs->axis.z;
    return quat_out;
}

void egwQuatAdd4fv(const egwQuaternion4f* quats_lhs, const egwQuaternion4f* quats_rhs, egwQuaternion4f* quats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        quats_out->axis.w = quats_lhs->axis.w + quats_rhs->axis.w;
        quats_out->axis.x = quats_lhs->axis.x + quats_rhs->axis.x;
        quats_out->axis.y = quats_lhs->axis.y + quats_rhs->axis.y;
        quats_out->axis.z = quats_lhs->axis.z + quats_rhs->axis.z;
        quats_lhs = (const egwQuaternion4f*)((EGWintptr)quats_lhs + (EGWintptr)sizeof(egwQuaternion4f) + strideB_lhs);
        quats_rhs = (const egwQuaternion4f*)((EGWintptr)quats_rhs + (EGWintptr)sizeof(egwQuaternion4f) + strideB_rhs);
        quats_out = (egwQuaternion4f*)((EGWintptr)quats_out + (EGWintptr)sizeof(egwQuaternion4f) + strideB_out);
    }
}

egwQuaternion4f* egwQuatSubtract4f(const egwQuaternion4f* quat_lhs, const egwQuaternion4f* quat_rhs, egwQuaternion4f* quat_out) {
    quat_out->axis.w = quat_lhs->axis.w - quat_rhs->axis.w;
    quat_out->axis.x = quat_lhs->axis.x - quat_rhs->axis.x;
    quat_out->axis.y = quat_lhs->axis.y - quat_rhs->axis.y;
    quat_out->axis.z = quat_lhs->axis.z - quat_rhs->axis.z;
    return quat_out;
}

void egwQuatSubtract4fv(const egwQuaternion4f* quats_lhs, const egwQuaternion4f* quats_rhs, egwQuaternion4f* quats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        quats_out->axis.w = quats_lhs->axis.w - quats_rhs->axis.w;
        quats_out->axis.x = quats_lhs->axis.x - quats_rhs->axis.x;
        quats_out->axis.y = quats_lhs->axis.y - quats_rhs->axis.y;
        quats_out->axis.z = quats_lhs->axis.z - quats_rhs->axis.z;
        quats_lhs = (const egwQuaternion4f*)((EGWintptr)quats_lhs + (EGWintptr)sizeof(egwQuaternion4f) + strideB_lhs);
        quats_rhs = (const egwQuaternion4f*)((EGWintptr)quats_rhs + (EGWintptr)sizeof(egwQuaternion4f) + strideB_rhs);
        quats_out = (egwQuaternion4f*)((EGWintptr)quats_out + (EGWintptr)sizeof(egwQuaternion4f) + strideB_out);
    }
}

egwQuaternion4f* egwQuatMultiply4f(const egwQuaternion4f* quat_lhs, const egwQuaternion4f* quat_rhs, egwQuaternion4f* quat_out) {
    if(quat_lhs == quat_out || quat_rhs == quat_out) {
        egwQuaternion4f temp;
        temp.axis.w = ((quat_lhs->axis.w * quat_rhs->axis.w) - (quat_lhs->axis.x * quat_rhs->axis.x) - (quat_lhs->axis.y * quat_rhs->axis.y) - (quat_lhs->axis.z * quat_rhs->axis.z));
        temp.axis.x = ((quat_lhs->axis.w * quat_rhs->axis.x) + (quat_lhs->axis.x * quat_rhs->axis.w) + (quat_lhs->axis.y * quat_rhs->axis.z) - (quat_lhs->axis.z * quat_rhs->axis.y));
        temp.axis.y = ((quat_lhs->axis.w * quat_rhs->axis.y) - (quat_lhs->axis.x * quat_rhs->axis.z) + (quat_lhs->axis.y * quat_rhs->axis.w) + (quat_lhs->axis.z * quat_rhs->axis.x));
        temp.axis.z = ((quat_lhs->axis.w * quat_rhs->axis.z) + (quat_lhs->axis.x * quat_rhs->axis.y) - (quat_lhs->axis.y * quat_rhs->axis.x) + (quat_lhs->axis.z * quat_rhs->axis.w));
        quat_out->axis.w = temp.axis.w;
        quat_out->axis.x = temp.axis.x;
        quat_out->axis.y = temp.axis.y;
        quat_out->axis.z = temp.axis.z;
    } else {
        quat_out->axis.w = ((quat_lhs->axis.w * quat_rhs->axis.w) - (quat_lhs->axis.x * quat_rhs->axis.x) - (quat_lhs->axis.y * quat_rhs->axis.y) - (quat_lhs->axis.z * quat_rhs->axis.z));
        quat_out->axis.x = ((quat_lhs->axis.w * quat_rhs->axis.x) + (quat_lhs->axis.x * quat_rhs->axis.w) + (quat_lhs->axis.y * quat_rhs->axis.z) - (quat_lhs->axis.z * quat_rhs->axis.y));
        quat_out->axis.y = ((quat_lhs->axis.w * quat_rhs->axis.y) - (quat_lhs->axis.x * quat_rhs->axis.z) + (quat_lhs->axis.y * quat_rhs->axis.w) + (quat_lhs->axis.z * quat_rhs->axis.x));
        quat_out->axis.z = ((quat_lhs->axis.w * quat_rhs->axis.z) + (quat_lhs->axis.x * quat_rhs->axis.y) - (quat_lhs->axis.y * quat_rhs->axis.x) + (quat_lhs->axis.z * quat_rhs->axis.w));
    }
    
    return quat_out;
}

void egwQuatMultiply4fv(const egwQuaternion4f* quats_lhs, const egwQuaternion4f* quats_rhs, egwQuaternion4f* quats_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    while(count--) {
        if(quats_lhs == quats_out || quats_rhs == quats_out) {
            egwQuaternion4f temp;
            temp.axis.w = ((quats_lhs->axis.w * quats_rhs->axis.w) - (quats_lhs->axis.x * quats_rhs->axis.x) - (quats_lhs->axis.y * quats_rhs->axis.y) - (quats_lhs->axis.z * quats_rhs->axis.z));
            temp.axis.x = ((quats_lhs->axis.w * quats_rhs->axis.x) + (quats_lhs->axis.x * quats_rhs->axis.w) + (quats_lhs->axis.y * quats_rhs->axis.z) - (quats_lhs->axis.z * quats_rhs->axis.y));
            temp.axis.y = ((quats_lhs->axis.w * quats_rhs->axis.y) - (quats_lhs->axis.x * quats_rhs->axis.z) + (quats_lhs->axis.y * quats_rhs->axis.w) + (quats_lhs->axis.z * quats_rhs->axis.x));
            temp.axis.z = ((quats_lhs->axis.w * quats_rhs->axis.z) + (quats_lhs->axis.x * quats_rhs->axis.y) - (quats_lhs->axis.y * quats_rhs->axis.x) + (quats_lhs->axis.z * quats_rhs->axis.w));
            quats_out->axis.w = temp.axis.w;
            quats_out->axis.x = temp.axis.x;
            quats_out->axis.y = temp.axis.y;
            quats_out->axis.z = temp.axis.z;
        } else {
            quats_out->axis.w = ((quats_lhs->axis.w * quats_rhs->axis.w) - (quats_lhs->axis.x * quats_rhs->axis.x) - (quats_lhs->axis.y * quats_rhs->axis.y) - (quats_lhs->axis.z * quats_rhs->axis.z));
            quats_out->axis.x = ((quats_lhs->axis.w * quats_rhs->axis.x) + (quats_lhs->axis.x * quats_rhs->axis.w) + (quats_lhs->axis.y * quats_rhs->axis.z) - (quats_lhs->axis.z * quats_rhs->axis.y));
            quats_out->axis.y = ((quats_lhs->axis.w * quats_rhs->axis.y) - (quats_lhs->axis.x * quats_rhs->axis.z) + (quats_lhs->axis.y * quats_rhs->axis.w) + (quats_lhs->axis.z * quats_rhs->axis.x));
            quats_out->axis.z = ((quats_lhs->axis.w * quats_rhs->axis.z) + (quats_lhs->axis.x * quats_rhs->axis.y) - (quats_lhs->axis.y * quats_rhs->axis.x) + (quats_lhs->axis.z * quats_rhs->axis.w));
        }
        
        quats_lhs = (const egwQuaternion4f*)((EGWintptr)quats_lhs + (EGWintptr)sizeof(egwQuaternion4f) + strideB_lhs);
        quats_rhs = (const egwQuaternion4f*)((EGWintptr)quats_rhs + (EGWintptr)sizeof(egwQuaternion4f) + strideB_rhs);
        quats_out = (egwQuaternion4f*)((EGWintptr)quats_out + (EGWintptr)sizeof(egwQuaternion4f) + strideB_out);
    }
}

egwQuaternion4f* egwQuatRotateEuler4f(const egwQuaternion4f* quat_in, const egwVector3f* angles_r, const EGWint order, egwQuaternion4f* quat_out) {
    egwQuaternion4f temp;
    
    switch(order) {
        case EGW_EULERROT_ORDER_X: {
            EGWsingle hlfAng = angles_r->axis.x * 0.5f;
            temp.axis.w = egwCosf(hlfAng);
            temp.axis.x = egwSinf(hlfAng);
            temp.axis.y = temp.axis.z = 0.0f;
        } break;
        case EGW_EULERROT_ORDER_Y: {
            EGWsingle hlfAng = angles_r->axis.y * 0.5f;
            temp.axis.w = egwCosf(hlfAng);
            temp.axis.y = egwSinf(hlfAng);
            temp.axis.x = temp.axis.z = 0.0f;
        } break;
        case EGW_EULERROT_ORDER_Z: {
            EGWsingle hlfAng = angles_r->axis.z * 0.5f;
            temp.axis.w = egwCosf(hlfAng);
            temp.axis.z = egwSinf(hlfAng);
            temp.axis.x = temp.axis.y = 0.0f;
        } break;
        case EGW_EULERROT_ORDER_XY: {
            egwQuatRotateEuler4f(NULL, angles_r, EGW_EULERROT_ORDER_X, &temp);
            egwQuatRotateEuler4f(&temp, angles_r, EGW_EULERROT_ORDER_Y, &temp);
        } break;
        case EGW_EULERROT_ORDER_XZ: {
            egwQuatRotateEuler4f(NULL, angles_r, EGW_EULERROT_ORDER_X, &temp);
            egwQuatRotateEuler4f(&temp, angles_r, EGW_EULERROT_ORDER_Z, &temp);
        } break;
        case EGW_EULERROT_ORDER_YX: {
            egwQuatRotateEuler4f(NULL, angles_r, EGW_EULERROT_ORDER_Y, &temp);
            egwQuatRotateEuler4f(&temp, angles_r, EGW_EULERROT_ORDER_X, &temp);
        } break;
        case EGW_EULERROT_ORDER_YZ: {
            egwQuatRotateEuler4f(NULL, angles_r, EGW_EULERROT_ORDER_Y, &temp);
            egwQuatRotateEuler4f(&temp, angles_r, EGW_EULERROT_ORDER_Z, &temp);
        } break;
        case EGW_EULERROT_ORDER_ZX: {
            egwQuatRotateEuler4f(NULL, angles_r, EGW_EULERROT_ORDER_Z, &temp);
            egwQuatRotateEuler4f(&temp, angles_r, EGW_EULERROT_ORDER_X, &temp);
        } break;
        case EGW_EULERROT_ORDER_ZY: {
            egwQuatRotateEuler4f(NULL, angles_r, EGW_EULERROT_ORDER_Z, &temp);
            egwQuatRotateEuler4f(&temp, angles_r, EGW_EULERROT_ORDER_Y, &temp);
        } break;
        case EGW_EULERROT_ORDER_XYZ: {
            egwQuatRotateEuler4f(NULL, angles_r, EGW_EULERROT_ORDER_X, &temp);
            egwQuatRotateEuler4f(&temp, angles_r, EGW_EULERROT_ORDER_Y, &temp);
            egwQuatRotateEuler4f(&temp, angles_r, EGW_EULERROT_ORDER_Z, &temp);
        } break;
        case EGW_EULERROT_ORDER_XZY: {
            egwQuatRotateEuler4f(NULL, angles_r, EGW_EULERROT_ORDER_X, &temp);
            egwQuatRotateEuler4f(&temp, angles_r, EGW_EULERROT_ORDER_Z, &temp);
            egwQuatRotateEuler4f(&temp, angles_r, EGW_EULERROT_ORDER_Y, &temp);
        } break;
        case EGW_EULERROT_ORDER_YXZ: {
            egwQuatRotateEuler4f(NULL, angles_r, EGW_EULERROT_ORDER_Y, &temp);
            egwQuatRotateEuler4f(&temp, angles_r, EGW_EULERROT_ORDER_X, &temp);
            egwQuatRotateEuler4f(&temp, angles_r, EGW_EULERROT_ORDER_Z, &temp);
        } break;
        case EGW_EULERROT_ORDER_YZX: {
            egwQuatRotateEuler4f(NULL, angles_r, EGW_EULERROT_ORDER_Y, &temp);
            egwQuatRotateEuler4f(&temp, angles_r, EGW_EULERROT_ORDER_Z, &temp);
            egwQuatRotateEuler4f(&temp, angles_r, EGW_EULERROT_ORDER_X, &temp);
        } break;
        case EGW_EULERROT_ORDER_ZXY: {
            egwQuatRotateEuler4f(NULL, angles_r, EGW_EULERROT_ORDER_Z, &temp);
            egwQuatRotateEuler4f(&temp, angles_r, EGW_EULERROT_ORDER_X, &temp);
            egwQuatRotateEuler4f(&temp, angles_r, EGW_EULERROT_ORDER_Y, &temp);
        } break;
        case EGW_EULERROT_ORDER_ZYX: {
            egwQuatRotateEuler4f(NULL, angles_r, EGW_EULERROT_ORDER_Z, &temp);
            egwQuatRotateEuler4f(&temp, angles_r, EGW_EULERROT_ORDER_Y, &temp);
            egwQuatRotateEuler4f(&temp, angles_r, EGW_EULERROT_ORDER_X, &temp);
        } break;
        default: {
            temp.axis.w = 1.0f; temp.axis.x = temp.axis.y = temp.axis.z = 0.0f;
        } break;
    }
    
    if(quat_in)
        egwQuatMultiply4f(quat_in, &temp, quat_out);
    else {
        quat_out->axis.w = temp.axis.w;
        quat_out->axis.x = temp.axis.x;
        quat_out->axis.y = temp.axis.y;
        quat_out->axis.z = temp.axis.z;
    }
    
    return quat_out;
}

egwQuaternion4f* egwQuatRotateEuler4fs(const egwQuaternion4f* quat_in, const EGWsingle angleX_r, const EGWsingle angleY_r, const EGWsingle angleZ_r, const EGWint order, egwQuaternion4f* quat_out) {
    egwVector3f angles;
    angles.axis.x = angleX_r; angles.axis.y = angleY_r; angles.axis.z = angleZ_r;
    return egwQuatRotateEuler4f(quat_in, &angles, order, quat_out);
}

egwQuaternion4f* egwQuatRotateAxis4f(const egwQuaternion4f* quat_in, const egwVector3f* axis, egwQuaternion4f* quat_out) {
    egwQuaternion4f temp;
    
    egwVector3f unitAxis;
    EGWsingle angle;
    angle = egwVecMagnitude3f(axis);
    if(!egwIsZerof(angle)) {
        egwVecNormalizeMag3f(axis, angle, &unitAxis);
        
        angle *= 0.5f;
        EGWsingle sinHlfAng = egwSinf(angle);
        temp.axis.w = egwCosf(angle);
        temp.axis.x = unitAxis.axis.x * sinHlfAng;
        temp.axis.y = unitAxis.axis.y * sinHlfAng;
        temp.axis.z = unitAxis.axis.z * sinHlfAng;
    } else // zero axis = no rotation
        egwQuatCopy4f(&egwSIQuatIdentity4f, &temp);
    
    if(quat_in)
        egwQuatMultiply4f(quat_in, &temp, quat_out);
    else {
        quat_out->axis.w = temp.axis.w;
        quat_out->axis.x = temp.axis.x;
        quat_out->axis.y = temp.axis.y;
        quat_out->axis.z = temp.axis.z;
    }
    
    return quat_out;
}

egwQuaternion4f* egwQuatRotateAxis4fs(const egwQuaternion4f* quat_in, const EGWsingle axisX, const EGWsingle axisY, const EGWsingle axisZ, egwQuaternion4f* quat_out) {
    egwVector3f axis;
    axis.axis.x = axisX; axis.axis.y = axisY; axis.axis.z = axisZ;
    return egwQuatRotateAxis4f(quat_in, &axis, quat_out);
}

egwQuaternion4f* egwQuatRotateAxisAngle4f(const egwQuaternion4f* quat_in, const egwVector3f* axis_u, EGWsingle angle_r, egwQuaternion4f* quat_out) {
    egwQuaternion4f temp;
    
    angle_r *= 0.5f;
    EGWsingle sinHlfAng = egwSinf(angle_r);
    temp.axis.w = egwCosf(angle_r);
    temp.axis.x = axis_u->axis.x * sinHlfAng;
    temp.axis.y = axis_u->axis.y * sinHlfAng;
    temp.axis.z = axis_u->axis.z * sinHlfAng;
    
    if(quat_in)
        egwQuatMultiply4f(quat_in, &temp, quat_out);
    else {
        quat_out->axis.w = temp.axis.w;
        quat_out->axis.x = temp.axis.x;
        quat_out->axis.y = temp.axis.y;
        quat_out->axis.z = temp.axis.z;
    }
    
    return quat_out;
}

egwQuaternion4f* egwQuatRotateAxisAngle4fs(const egwQuaternion4f* quat_in, const EGWsingle axisX_u, const EGWsingle axisY_u, const EGWsingle axisZ_u, const EGWsingle angle_r, egwQuaternion4f* quat_out) {
    egwVector3f unitAxis;
    unitAxis.axis.x = axisX_u; unitAxis.axis.y = axisY_u; unitAxis.axis.z = axisZ_u;
    return egwQuatRotateAxisAngle4f(quat_in, &unitAxis, angle_r, quat_out);
}

egwQuaternion4f* egwQuatRotateVecVec4f(const egwQuaternion4f* quat_in, const egwVector3f* vec_fr, const egwVector3f* vec_to, egwQuaternion4f* quat_out) {
    egwQuaternion4f temp;
    
    egwVector3f unitAxis;
    EGWsingle angle;
    egwVecCrossProd3f(vec_fr, vec_to, &unitAxis);
    angle = egwVecMagnitude3f(&unitAxis);
    egwVecNormalizeMag3f(&unitAxis, angle, &unitAxis);
    
    angle *= 0.5f;
    EGWsingle sinHlfAng = egwSinf(angle);
    temp.axis.w = egwCosf(angle);
    temp.axis.x = unitAxis.axis.x * sinHlfAng;
    temp.axis.y = unitAxis.axis.y * sinHlfAng;
    temp.axis.z = unitAxis.axis.z * sinHlfAng;
    
    if(quat_in)
        egwQuatMultiply4f(quat_in, &temp, quat_out);
    else {
        quat_out->axis.w = temp.axis.w;
        quat_out->axis.x = temp.axis.x;
        quat_out->axis.y = temp.axis.y;
        quat_out->axis.z = temp.axis.z;
    }
    
    return quat_out;
}

egwQuaternion4f* egwQuatRotateVecVec4fs(const egwQuaternion4f* quat_in, const EGWsingle vecX_fr, const EGWsingle vecY_fr, const EGWsingle vecZ_fr, const EGWsingle vecX_to, const EGWsingle vecY_to, const EGWsingle vecZ_to, egwQuaternion4f* quat_out) {
    egwVector3f vec_fr, vec_to;
    vec_fr.axis.x = vecX_fr; vec_fr.axis.y = vecY_fr; vec_fr.axis.z = vecZ_fr;
    vec_to.axis.x = vecX_to; vec_to.axis.y = vecY_to; vec_to.axis.z = vecZ_to;
    return egwQuatRotateVecVec4f(quat_in, &vec_fr, &vec_to, quat_out);
}

egwQuaternion4f* egwQuatRotateMatrix444f(const egwQuaternion4f* quat_in, const egwMatrix44f* mat_in, egwQuaternion4f* quat_out) {
    egwQuaternion4f temp;
    
    EGWsingle trace = mat_in->component.r1c1 + mat_in->component.r2c2 + mat_in->component.r3c3 + mat_in->component.r4c4;
    if(trace > EGW_SFLT_EPSILON) {
        EGWsingle factor = 0.5f * egwInvSqrtf(trace);
        temp.axis.w = 0.25f / factor;
        temp.axis.x = (mat_in->component.r3c2 - mat_in->component.r2c3) * factor;
        temp.axis.y = (mat_in->component.r1c3 - mat_in->component.r3c1) * factor;
        temp.axis.z = (mat_in->component.r2c1 - mat_in->component.r1c2) * factor;
    } else {
        if (mat_in->component.r1c1 > mat_in->component.r2c2 && mat_in->component.r1c1 > mat_in->component.r3c3) {
            EGWsingle factor = 0.5f * egwInvSqrtf(mat_in->component.r4c4 + mat_in->component.r1c1 - mat_in->component.r2c2 - mat_in->component.r3c3);
            temp.axis.w = (mat_in->component.r3c2 - mat_in->component.r2c3) * factor;
            temp.axis.x = 0.25f / factor;
            temp.axis.y = (mat_in->component.r1c2 + mat_in->component.r2c1) * factor;
            temp.axis.z = (mat_in->component.r1c3 + mat_in->component.r3c1) * factor;
        } else if (mat_in->component.r2c2 > mat_in->component.r3c3) {
            EGWsingle factor = 0.5f * egwInvSqrtf(mat_in->component.r4c4 + mat_in->component.r2c2 - mat_in->component.r1c1 - mat_in->component.r3c3);
            temp.axis.w = (mat_in->component.r1c3 - mat_in->component.r3c1) * factor;
            temp.axis.x = (mat_in->component.r1c2 + mat_in->component.r2c1) * factor;
            temp.axis.y = 0.25f / factor;
            temp.axis.z = (mat_in->component.r2c3 + mat_in->component.r3c2) * factor;
        } else {
            EGWsingle factor = 0.5f * egwInvSqrtf(mat_in->component.r4c4 + mat_in->component.r3c3 - mat_in->component.r1c1 - mat_in->component.r2c2);
            temp.axis.w = (mat_in->component.r2c1 - mat_in->component.r1c2) * factor;
            temp.axis.x = (mat_in->component.r1c3 + mat_in->component.r3c1) * factor;
            temp.axis.y = (mat_in->component.r2c3 + mat_in->component.r3c2) * factor;
            temp.axis.z = 0.25f / factor;
        }
    }    
    
    if(quat_in)
        egwQuatMultiply4f(quat_in, &temp, quat_out);
    else {
        quat_out->axis.w = temp.axis.w;
        quat_out->axis.x = temp.axis.x;
        quat_out->axis.y = temp.axis.y;
        quat_out->axis.z = temp.axis.z;
    }
    
    return quat_out;
}

egwVector3f* egwVecHomomorphize43f(const egwQuaternion4f* quat_lhs, const egwVector3f* vec_rhs, egwVector3f* vec_out) {
    egwVector3f temp;
    EGWsingle ssMinV = (quat_lhs->axis.w * quat_lhs->axis.w) - ((quat_lhs->axis.x * quat_lhs->axis.x) + (quat_lhs->axis.y * quat_lhs->axis.y) + (quat_lhs->axis.z * quat_lhs->axis.z));
    EGWsingle twos = (quat_lhs->axis.w + quat_lhs->axis.w);
    EGWsingle twosVx = twos * quat_lhs->axis.x;
    EGWsingle twosVy = twos * quat_lhs->axis.y;
    EGWsingle twosVz = twos * quat_lhs->axis.z;
    EGWsingle twoVdP = ((quat_lhs->axis.x * vec_rhs->axis.x) + (quat_lhs->axis.y * vec_rhs->axis.y) + (quat_lhs->axis.z * vec_rhs->axis.z)); twoVdP += twoVdP;
    
    temp.axis.x = (ssMinV * vec_rhs->axis.x) + ((twosVy * vec_rhs->axis.z) - (twosVz * vec_rhs->axis.y)) + (twoVdP * quat_lhs->axis.x);
    temp.axis.y = (ssMinV * vec_rhs->axis.y) + ((twosVz * vec_rhs->axis.x) - (twosVx * vec_rhs->axis.z)) + (twoVdP * quat_lhs->axis.y);
    temp.axis.z = (ssMinV * vec_rhs->axis.z) + ((twosVx * vec_rhs->axis.y) - (twosVy * vec_rhs->axis.x)) + (twoVdP * quat_lhs->axis.z);
    vec_out->axis.x = temp.axis.x;
    vec_out->axis.y = temp.axis.y;
    vec_out->axis.z = temp.axis.z;
    
    return vec_out;
}

egwVector4f* egwVecHomomorphize44f(const egwQuaternion4f* quat_lhs, const egwVector4f* vec_rhs, egwVector4f* vec_out) {
    egwVector3f temp;
    EGWsingle ssMinV = (quat_lhs->axis.w * quat_lhs->axis.w) - ((quat_lhs->axis.x * quat_lhs->axis.x) + (quat_lhs->axis.y * quat_lhs->axis.y) + (quat_lhs->axis.z * quat_lhs->axis.z));
    EGWsingle twos = (quat_lhs->axis.w + quat_lhs->axis.w);
    EGWsingle twosVx = twos * quat_lhs->axis.x;
    EGWsingle twosVy = twos * quat_lhs->axis.y;
    EGWsingle twosVz = twos * quat_lhs->axis.z;
    EGWsingle twoVdP = ((quat_lhs->axis.x * vec_rhs->axis.x) + (quat_lhs->axis.y * vec_rhs->axis.y) + (quat_lhs->axis.z * vec_rhs->axis.z)); twoVdP += twoVdP;
    
    temp.axis.x = (ssMinV * vec_rhs->axis.x) + ((twosVy * vec_rhs->axis.z) - (twosVz * vec_rhs->axis.y)) + (twoVdP * quat_lhs->axis.x);
    temp.axis.y = (ssMinV * vec_rhs->axis.y) + ((twosVz * vec_rhs->axis.x) - (twosVx * vec_rhs->axis.z)) + (twoVdP * quat_lhs->axis.y);
    temp.axis.z = (ssMinV * vec_rhs->axis.z) + ((twosVx * vec_rhs->axis.y) - (twosVy * vec_rhs->axis.x)) + (twoVdP * quat_lhs->axis.z);
    vec_out->axis.x = temp.axis.x;
    vec_out->axis.y = temp.axis.y;
    vec_out->axis.z = temp.axis.z;
    vec_out->axis.w = vec_rhs->axis.w;
    
    return vec_out;
}

void egwVecHomomorphize43fz(const egwQuaternion4f* quats_lhs, const egwVector3f* vecs_rhs, egwVector3f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    egwVector3f temp;
    
    while(count--) {
        {
            EGWsingle ssMinV = (quats_lhs->axis.w * quats_lhs->axis.w) - ((quats_lhs->axis.x * quats_lhs->axis.x) + (quats_lhs->axis.y * quats_lhs->axis.y) + (quats_lhs->axis.z * quats_lhs->axis.z));
            EGWsingle twos = (quats_lhs->axis.w + quats_lhs->axis.w);
            EGWsingle twosVx = twos * quats_lhs->axis.x;
            EGWsingle twosVy = twos * quats_lhs->axis.y;
            EGWsingle twosVz = twos * quats_lhs->axis.z;
            EGWsingle twoVdP = ((quats_lhs->axis.x * vecs_rhs->axis.x) + (quats_lhs->axis.y * vecs_rhs->axis.y) + (quats_lhs->axis.z * vecs_rhs->axis.z)); twoVdP += twoVdP;
            
            temp.axis.x = (ssMinV * vecs_rhs->axis.x) + ((twosVy * vecs_rhs->axis.z) - (twosVz * vecs_rhs->axis.y)) + (twoVdP * quats_lhs->axis.x);
            temp.axis.y = (ssMinV * vecs_rhs->axis.y) + ((twosVz * vecs_rhs->axis.x) - (twosVx * vecs_rhs->axis.z)) + (twoVdP * quats_lhs->axis.y);
            temp.axis.z = (ssMinV * vecs_rhs->axis.z) + ((twosVx * vecs_rhs->axis.y) - (twosVy * vecs_rhs->axis.x)) + (twoVdP * quats_lhs->axis.z);
            vecs_out->axis.x = temp.axis.x;
            vecs_out->axis.y = temp.axis.y;
            vecs_out->axis.z = temp.axis.z;
        }
        
        quats_lhs = (const egwQuaternion4f*)((EGWintptr)quats_lhs + (EGWintptr)sizeof(egwQuaternion4f) + strideB_lhs);
        vecs_rhs = (const egwVector3f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector3f) + strideB_rhs);
        vecs_out = (egwVector3f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector3f) + strideB_out);
    }
}

void egwVecHomomorphize44fz(const egwQuaternion4f* quats_lhs, const egwVector4f* vecs_rhs, egwVector4f* vecs_out, const EGWintptr strideB_lhs, const EGWintptr strideB_rhs, const EGWintptr strideB_out, EGWuint count) {
    egwVector3f temp;
    
    while(count--) {
        {
            EGWsingle ssMinV = (quats_lhs->axis.w * quats_lhs->axis.w) - ((quats_lhs->axis.x * quats_lhs->axis.x) + (quats_lhs->axis.y * quats_lhs->axis.y) + (quats_lhs->axis.z * quats_lhs->axis.z));
            EGWsingle twos = (quats_lhs->axis.w + quats_lhs->axis.w);
            EGWsingle twosVx = twos * quats_lhs->axis.x;
            EGWsingle twosVy = twos * quats_lhs->axis.y;
            EGWsingle twosVz = twos * quats_lhs->axis.z;
            EGWsingle twoVdP = ((quats_lhs->axis.x * vecs_rhs->axis.x) + (quats_lhs->axis.y * vecs_rhs->axis.y) + (quats_lhs->axis.z * vecs_rhs->axis.z)); twoVdP += twoVdP;
            
            temp.axis.x = (ssMinV * vecs_rhs->axis.x) + ((twosVy * vecs_rhs->axis.z) - (twosVz * vecs_rhs->axis.y)) + (twoVdP * quats_lhs->axis.x);
            temp.axis.y = (ssMinV * vecs_rhs->axis.y) + ((twosVz * vecs_rhs->axis.x) - (twosVx * vecs_rhs->axis.z)) + (twoVdP * quats_lhs->axis.y);
            temp.axis.z = (ssMinV * vecs_rhs->axis.z) + ((twosVx * vecs_rhs->axis.y) - (twosVy * vecs_rhs->axis.x)) + (twoVdP * quats_lhs->axis.z);
            vecs_out->axis.x = temp.axis.x;
            vecs_out->axis.y = temp.axis.y;
            vecs_out->axis.z = temp.axis.z;
            vecs_out->axis.w = vecs_rhs->axis.w;
        }
        
        quats_lhs = (const egwQuaternion4f*)((EGWintptr)quats_lhs + (EGWintptr)sizeof(egwQuaternion4f) + strideB_lhs);
        vecs_rhs = (const egwVector4f*)((EGWintptr)vecs_rhs + (EGWintptr)sizeof(egwVector4f) + strideB_rhs);
        vecs_out = (egwVector4f*)((EGWintptr)vecs_out + (EGWintptr)sizeof(egwVector4f) + strideB_out);
    }
}

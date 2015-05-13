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

/// @defgroup geWizES_math_types egwMathTypes
/// @ingroup geWizES_math
/// Math Types.
/// @{

/// @file egwMathTypes.h
/// Math Types.

#import "../inf/egwTypes.h"


// !!!: ***** Defines *****

#define EGW_MATH_E          2.718281829     ///< E.
#define EGW_MATH_GAMMA      0.577215665     ///< Gamma.
#define EGW_MATH_PHI        1.618033989     ///< Phi.
#define EGW_MATH_LN2        0.693147181     ///< Ln(2).
#define EGW_MATH_LN10       2.302585093     ///< Ln(10).
#define EGW_MATH_LNE_LN2    1.442695041     ///< Ln(E) / Ln(2).
#define EGW_MATH_LNE_LN10   0.434294482     ///< Ln(E) / Ln(10).
#define EGW_MATH_PI         3.141592654     ///< PI.
#define EGW_MATH_2PI        6.283185307     ///< 2 * PI.
#define EGW_MATH_PI_2       1.570796327     ///< PI / 2.
#define EGW_MATH_PI_4       0.785398163     ///< PI / 4.
#define EGW_MATH_PI_8       0.392699081     ///< PI / 8.
#define EGW_MATH_1_PI       0.318309886     ///< 1 / PI.
#define EGW_MATH_2_PI       0.636619772     ///< 2 / PI.
#define EGW_MATH_4_PI       1.273239545     ///< 4 / PI.
#define EGW_MATH_8_PI       2.546479089     ///< 8 / PI.
#define EGW_MATH_2_SQRTPI   1.128379167     ///< 2 / Sqrt(PI).
#define EGW_MATH_SQRT2      1.414213562     ///< Sqrt(2).
#define EGW_MATH_SQRT3      1.732050808     ///< Sqrt(3).
#define EGW_MATH_1_SQRT2    0.707106781     ///< 1 / Sqrt(2).
#define EGW_MATH_1_SQRT3    0.577350269     ///< 1 / Sqrt(3).
#define EGW_MATH_1_60       0.016666667     ///< 1 / 60 (i.e. one sixtieth of a second).
#define EGW_MATH_1_600      0.001666667     ///< 1 / 600 (i.e. one sixhundreth of a second).
#define EGW_MATH_180_PI     57.29577951     ///< 180 / PI (i.e. radians to degrees multiplier).
#define EGW_MATH_PI_180     0.017453293     ///< PI / 180 (i.e. degrees to radians multipler).
#define EGW_MATH_G          9.80665         ///< Mean Earth gravity (m/s^2).

#define EGW_EULERROT_ORDER_X        0x0100  ///< Rotation ordering: X.
#define EGW_EULERROT_ORDER_Y        0x0010  ///< Rotation ordering: Y.
#define EGW_EULERROT_ORDER_Z        0x0001  ///< Rotation ordering: Z.
#define EGW_EULERROT_ORDER_XY       0x0120  ///< Rotation ordering: X, Y.
#define EGW_EULERROT_ORDER_XZ       0x0102  ///< Rotation ordering: X, Z.
#define EGW_EULERROT_ORDER_YX       0x0210  ///< Rotation ordering: Y, X.
#define EGW_EULERROT_ORDER_YZ       0x0012  ///< Rotation ordering: Y, Z.
#define EGW_EULERROT_ORDER_ZX       0x0201  ///< Rotation ordering: Z, X.
#define EGW_EULERROT_ORDER_ZY       0x0021  ///< Rotation ordering: Z, Y.
#define EGW_EULERROT_ORDER_XYZ      0x0124  ///< Rotation ordering: X, Y, Z.
#define EGW_EULERROT_ORDER_XZY      0x0142  ///< Rotation ordering: X, Z, Y.
#define EGW_EULERROT_ORDER_YXZ      0x0214  ///< Rotation ordering: Y, X, Z.
#define EGW_EULERROT_ORDER_YZX      0x0412  ///< Rotation ordering: Y, Z, X.
#define EGW_EULERROT_ORDER_ZXY      0x0241  ///< Rotation ordering: Z, X, Y.
#define EGW_EULERROT_ORDER_ZYX      0x0421  ///< Rotation ordering: Z, Y, X.


// !!!: ***** Vectors *****

/// 1-D Vector (Single).
/// One dimensional vector structure.
typedef union {
    struct {
        EGWsingle x;                        ///< X-coordinate value.
    } axis;                                 ///< Axis coordinate values.
    EGWsingle vector[1];                    ///< Vector coordinates array.
    EGWuint8 bytes[4];                      ///< Byte array.
} egwVector1f;

/// 1-D Vector (Double).
/// One dimensional vector structure.
typedef union {
    struct {
        EGWdouble x;                        ///< X-coordinate value.
    } axis;                                 ///< Axis coordinate values.
    EGWdouble vector[1];                    ///< Vector coordinates array.
    EGWuint8 bytes[8];                     ///< Byte array.
} egwVector1d;

/// 1-D Vector (Triple).
/// One dimensional vector structure.
typedef union {
    struct {
        EGWtriple x;                        ///< X-coordinate value.
    } axis;                                 ///< Axis coordinate values.
    EGWtriple vector[1];                    ///< Vector coordinates array.
    EGWuint8 bytes[12];                     ///< Byte array.
} egwVector1t;

/// 2-D Vector (Single).
/// Two dimensional vector structure.
typedef union {
    struct {
        EGWsingle x;                        ///< X-coordinate value.
        EGWsingle y;                        ///< Y-coordinate value.
    } axis;                                 ///< Axis coordinate values.
    EGWsingle vector[2];                    ///< Vector coordinates array.
    EGWuint8 bytes[8];                      ///< Byte array.
} egwVector2f;

/// 2-D Vector (Double).
/// Two dimensional vector structure.
typedef union {
    struct {
        EGWdouble x;                        ///< X-coordinate value.
        EGWdouble y;                        ///< Y-coordinate value.
    } axis;                                 ///< Axis coordinate values.
    EGWdouble vector[2];                    ///< Vector coordinates array.
    EGWuint8 bytes[16];                     ///< Byte array.
} egwVector2d;

/// 2-D Vector (Triple).
/// Two dimensional vector structure.
typedef union {
    struct {
        EGWtriple x;                        ///< X-coordinate value.
        EGWtriple y;                        ///< Y-coordinate value.
    } axis;                                 ///< Axis coordinate values.
    EGWtriple vector[2];                    ///< Vector coordinates array.
    EGWuint8 bytes[24];                     ///< Byte array.
} egwVector2t;

/// 3-D Vector (Single).
/// Three dimensional vector structure.
/// @note In R2, Z-coordinate specifies type of vector (0.0f - directional, 1.0f - positional).
typedef union {
    struct {
        EGWsingle x;                        ///< X-coordinate value.
        EGWsingle y;                        ///< Y-coordinate value.
        EGWsingle z;                        ///< Z-coordinate value.
    } axis;                                 ///< Axis coordinate values.
    EGWsingle vector[3];                    ///< Vector coordinates array.
    EGWuint8 bytes[12];                     ///< Byte array.
} egwVector3f;

/// 3-D Vector (Double).
/// Three dimensional vector structure.
/// @note In R2, Z-coordinate specifies type of vector (0.0f - directional, 1.0f - positional).
typedef union {
    struct {
        EGWdouble x;                        ///< X-coordinate value.
        EGWdouble y;                        ///< Y-coordinate value.
        EGWdouble z;                        ///< Z-coordinate value.
    } axis;                                 ///< Axis coordinate values.
    EGWdouble vector[3];                    ///< Vector coordinates array.
    EGWuint8 bytes[24];                     ///< Byte array.
} egwVector3d;

/// 3-D Vector (Triple).
/// Three dimensional vector structure.
/// @note In R2, Z-coordinate specifies type of vector (0.0f - directional, 1.0f - positional).
typedef union {
    struct {
        EGWtriple x;                        ///< X-coordinate value.
        EGWtriple y;                        ///< Y-coordinate value.
        EGWtriple z;                        ///< Z-coordinate value.
    } axis;                                 ///< Axis coordinate values.
    EGWtriple vector[3];                    ///< Vector coordinates array.
    EGWuint8 bytes[36];                     ///< Byte array.
} egwVector3t;

/// 4-D Vector (Single).
/// Four dimensional vector structure.
/// @note In R3, W-coordinate specifies type of vector (0.0f - directional, 1.0f - positional).
typedef union {
    struct {
        EGWsingle x;                        ///< X-coordinate value.
        EGWsingle y;                        ///< Y-coordinate value.
        EGWsingle z;                        ///< Z-coordinate value.
        EGWsingle w;                        ///< W-coordinate value.
    } axis;                                 ///< Axis coordinate values.
    EGWsingle vector[4];                    ///< Vector coordinates array.
    EGWuint8 bytes[16];                     ///< Byte array.
} egwVector4f;

/// 4-D Vector (Double).
/// Four dimensional vector structure.
/// @note In R3, W-coordinate specifies type of vector (0.0f - directional, 1.0f - positional).
typedef union {
    struct {
        EGWdouble x;                        ///< X-coordinate value.
        EGWdouble y;                        ///< Y-coordinate value.
        EGWdouble z;                        ///< Z-coordinate value.
        EGWdouble w;                        ///< W-coordinate value.
    } axis;                                 ///< Axis coordinate values.
    EGWdouble vector[4];                    ///< Vector coordinates array.
    EGWuint8 bytes[32];                     ///< Byte array.
} egwVector4d;

/// 4-D Vector (Triple).
/// Four dimensional vector structure.
/// @note In R3, W-coordinate specifies type of vector (0.0f - directional, 1.0f - positional).
typedef union {
    struct {
        EGWtriple x;                        ///< X-coordinate value.
        EGWtriple y;                        ///< Y-coordinate value.
        EGWtriple z;                        ///< Z-coordinate value.
        EGWtriple w;                        ///< W-coordinate value.
    } axis;                                 ///< Axis coordinate values.
    EGWtriple vector[4];                    ///< Vector coordinates array.
    EGWuint8 bytes[64];                     ///< Byte array.
} egwVector4t;


// !!!: ***** Matricies *****

/// 3x3 Matrix (Single).
/// Nine element column-major matrix structure.
typedef union {
    struct {
        EGWsingle r1c1;                     ///< Row 1 column 1 element value.
        EGWsingle r2c1;                     ///< Row 2 column 1 element value.
        EGWsingle r3c1;                     ///< Row 3 column 1 element value.
        EGWsingle r1c2;                     ///< Row 1 column 2 element value.
        EGWsingle r2c2;                     ///< Row 2 column 2 element value.
        EGWsingle r3c2;                     ///< Row 3 column 2 element value.
        EGWsingle r1c3;                     ///< Row 1 column 3 element value.
        EGWsingle r2c3;                     ///< Row 2 column 3 element value.
        EGWsingle r3c3;                     ///< Row 3 column 3 element value.
    } component;                            ///< Component element values.
    struct {
        EGWsingle r1;                       ///< Row 1 element value.
        EGWsingle r2;                       ///< Row 2 element value.
        EGWsingle r3;                       ///< Row 3 element value.
    } column[3];                            ///< Column vectors array.
    EGWsingle matrix[9];                    ///< Matrix elements array.
    EGWuint8 bytes[36];                     ///< Byte array.
} egwMatrix33f;

/// 3x3 Matrix (Double).
/// Nine element column-major matrix structure.
typedef union {
    struct {
        EGWdouble r1c1;                     ///< Row 1 column 1 element value.
        EGWdouble r2c1;                     ///< Row 2 column 1 element value.
        EGWdouble r3c1;                     ///< Row 3 column 1 element value.
        EGWdouble r1c2;                     ///< Row 1 column 2 element value.
        EGWdouble r2c2;                     ///< Row 2 column 2 element value.
        EGWdouble r3c2;                     ///< Row 3 column 2 element value.
        EGWdouble r1c3;                     ///< Row 1 column 3 element value.
        EGWdouble r2c3;                     ///< Row 2 column 3 element value.
        EGWdouble r3c3;                     ///< Row 3 column 3 element value.
    } component;                            ///< Component element values.
    struct {
        EGWdouble r1;                       ///< Row 1 element value.
        EGWdouble r2;                       ///< Row 2 element value.
        EGWdouble r3;                       ///< Row 3 element value.
    } column[3];                            ///< Column vectors array.
    EGWdouble matrix[9];                    ///< Matrix elements array.
    EGWuint8 bytes[72];                     ///< Byte array.
} egwMatrix33d;

/// 3x3 Matrix (Triple).
/// Nine element column-major matrix structure.
typedef union {
    struct {
        EGWtriple r1c1;                     ///< Row 1 column 1 element value.
        EGWtriple r2c1;                     ///< Row 2 column 1 element value.
        EGWtriple r3c1;                     ///< Row 3 column 1 element value.
        EGWtriple r1c2;                     ///< Row 1 column 2 element value.
        EGWtriple r2c2;                     ///< Row 2 column 2 element value.
        EGWtriple r3c2;                     ///< Row 3 column 2 element value.
        EGWtriple r1c3;                     ///< Row 1 column 3 element value.
        EGWtriple r2c3;                     ///< Row 2 column 3 element value.
        EGWtriple r3c3;                     ///< Row 3 column 3 element value.
    } component;                            ///< Component element values.
    struct {
        EGWtriple r1;                       ///< Row 1 element value.
        EGWtriple r2;                       ///< Row 2 element value.
        EGWtriple r3;                       ///< Row 3 element value.
    } column[3];                            ///< Column vectors array.
    EGWtriple matrix[9];                    ///< Matrix elements array.
    EGWuint8 bytes[108];                    ///< Byte array.
} egwMatrix33t;

/// 4x4 Matrix (Single).
/// Sixteen element column-major matrix structure.
typedef union {
    struct {
        EGWsingle r1c1;                     ///< Row 1 column 1 element value.
        EGWsingle r2c1;                     ///< Row 2 column 1 element value.
        EGWsingle r3c1;                     ///< Row 3 column 1 element value.
        EGWsingle r4c1;                     ///< Row 4 column 1 element value.
        EGWsingle r1c2;                     ///< Row 1 column 2 element value.
        EGWsingle r2c2;                     ///< Row 2 column 2 element value.
        EGWsingle r3c2;                     ///< Row 3 column 2 element value.
        EGWsingle r4c2;                     ///< Row 4 column 2 element value.
        EGWsingle r1c3;                     ///< Row 1 column 3 element value.
        EGWsingle r2c3;                     ///< Row 2 column 3 element value.
        EGWsingle r3c3;                     ///< Row 3 column 3 element value.
        EGWsingle r4c3;                     ///< Row 4 column 3 element value.
        EGWsingle r1c4;                     ///< Row 1 column 4 element value.
        EGWsingle r2c4;                     ///< Row 2 column 4 element value.
        EGWsingle r3c4;                     ///< Row 3 column 4 element value.
        EGWsingle r4c4;                     ///< Row 4 column 4 element value.
    } component;                            ///< Component element values.
    struct {
        EGWsingle r1;                       ///< Row 1 element value.
        EGWsingle r2;                       ///< Row 2 element value.
        EGWsingle r3;                       ///< Row 3 element value.
        EGWsingle r4;                       ///< Row 4 element value.
    } column[4];                            ///< Column vectors array.
    EGWsingle matrix[16];                   ///< Matrix elements array.
    EGWuint8 bytes[64];                     ///< Byte array.
} egwMatrix44f;

/// 4x4 Matrix (Double).
/// Sixteen element column-major matrix structure.
typedef union {
    struct {
        EGWdouble r1c1;                     ///< Row 1 column 1 element value.
        EGWdouble r2c1;                     ///< Row 2 column 1 element value.
        EGWdouble r3c1;                     ///< Row 3 column 1 element value.
        EGWdouble r4c1;                     ///< Row 4 column 1 element value.
        EGWdouble r1c2;                     ///< Row 1 column 2 element value.
        EGWdouble r2c2;                     ///< Row 2 column 2 element value.
        EGWdouble r3c2;                     ///< Row 3 column 2 element value.
        EGWdouble r4c2;                     ///< Row 4 column 2 element value.
        EGWdouble r1c3;                     ///< Row 1 column 3 element value.
        EGWdouble r2c3;                     ///< Row 2 column 3 element value.
        EGWdouble r3c3;                     ///< Row 3 column 3 element value.
        EGWdouble r4c3;                     ///< Row 4 column 3 element value.
        EGWdouble r1c4;                     ///< Row 1 column 4 element value.
        EGWdouble r2c4;                     ///< Row 2 column 4 element value.
        EGWdouble r3c4;                     ///< Row 3 column 4 element value.
        EGWdouble r4c4;                     ///< Row 4 column 4 element value.
    } component;                            ///< Component element values.
    struct {
        EGWdouble r1;                       ///< Row 1 element value.
        EGWdouble r2;                       ///< Row 2 element value.
        EGWdouble r3;                       ///< Row 3 element value.
        EGWdouble r4;                       ///< Row 4 element value.
    } column[4];                            ///< Column vectors array.
    EGWdouble matrix[16];                   ///< Matrix elements array.
    EGWuint8 bytes[128];                    ///< Byte array.
} egwMatrix44d;

/// 4x4 Matrix (Triple).
/// Sixteen element column-major matrix structure.
typedef union {
    struct {
        EGWtriple r1c1;                     ///< Row 1 column 1 element value.
        EGWtriple r2c1;                     ///< Row 2 column 1 element value.
        EGWtriple r3c1;                     ///< Row 3 column 1 element value.
        EGWtriple r4c1;                     ///< Row 4 column 1 element value.
        EGWtriple r1c2;                     ///< Row 1 column 2 element value.
        EGWtriple r2c2;                     ///< Row 2 column 2 element value.
        EGWtriple r3c2;                     ///< Row 3 column 2 element value.
        EGWtriple r4c2;                     ///< Row 4 column 2 element value.
        EGWtriple r1c3;                     ///< Row 1 column 3 element value.
        EGWtriple r2c3;                     ///< Row 2 column 3 element value.
        EGWtriple r3c3;                     ///< Row 3 column 3 element value.
        EGWtriple r4c3;                     ///< Row 4 column 3 element value.
        EGWtriple r1c4;                     ///< Row 1 column 4 element value.
        EGWtriple r2c4;                     ///< Row 2 column 4 element value.
        EGWtriple r3c4;                     ///< Row 3 column 4 element value.
        EGWtriple r4c4;                     ///< Row 4 column 4 element value.
    } component;                            ///< Component element values.
    struct {
        EGWtriple r1;                       ///< Row 1 element value.
        EGWtriple r2;                       ///< Row 2 element value.
        EGWtriple r3;                       ///< Row 3 element value.
        EGWtriple r4;                       ///< Row 4 element value.
    } column[4];                            ///< Column vectors array.
    EGWtriple matrix[16];                   ///< Matrix elements array.
    EGWuint8 bytes[192];                    ///< Byte array.
} egwMatrix44t;


// !!!: ***** Quaternions *****

/// Quaternion (Single).
/// Four dimensional quaternion structure.
typedef union {
    struct {
        EGWsingle w;                        ///< W-coordinate value.
        EGWsingle x;                        ///< X-coordinate value.
        EGWsingle y;                        ///< Y-coordinate value.
        EGWsingle z;                        ///< Z-coordinate value.
    } axis;                                 ///< Axis coordinate values.
    EGWsingle vector[4];                    ///< Vector coordinates array.
    EGWuint8 bytes[16];                     ///< Byte array.
} egwQuaternion4f;

/// Quaternion (Double).
/// Four dimensional quaternion structure.
typedef union {
    struct {
        EGWdouble w;                        ///< W-coordinate value.
        EGWdouble x;                        ///< X-coordinate value.
        EGWdouble y;                        ///< Y-coordinate value.
        EGWdouble z;                        ///< Z-coordinate value.
    } axis;                                 ///< Axis coordinate values.
    EGWdouble vector[4];                    ///< Vector coordinates array.
    EGWuint8 bytes[32];                     ///< Byte array.
} egwQuaternion4d;

/// Quaternion (Triple).
/// Four dimensional quaternion structure.
typedef union {
    struct {
        EGWtriple w;                        ///< W-coordinate value.
        EGWtriple x;                        ///< X-coordinate value.
        EGWtriple y;                        ///< Y-coordinate value.
        EGWtriple z;                        ///< Z-coordinate value.
    } axis;                                 ///< Axis coordinate values.
    EGWtriple vector[4];                    ///< Vector coordinates array.
    EGWuint8 bytes[48];                     ///< Byte array.
} egwQuaternion4t;

/// @}

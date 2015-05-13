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

/// @defgroup geWizES_phy_types egwPhyTypes
/// @ingroup geWizES_phy
/// Physics Types.
/// @{

/// @file egwPhyTypes.h
/// Physics Types.

#import "../inf/egwTypes.h"
#import "../math/egwMathTypes.h"


// !!!: ***** Function Typedefs *****


// !!!: ***** Defines *****

#define EGW_POLATION_NONE           0x00000000  ///< No interpolation nor extrapolation.
#define EGW_POLATION_IPO_CONST      0x00000101  ///< Constant stepped value interpolation.
#define EGW_POLATION_IPO_LINEAR     0x00000202  ///< Simple linear interpolation.
#define EGW_POLATION_IPO_SLERP      0x0000040a  ///< Spherical linear interpolation.
#define EGW_POLATION_IPO_CUBICCR    0x00001014  ///< Cubic Catmull-Rom interpolation.
#define EGW_POLATION_EPO_CONST      0x01010000  ///< Constant end values extrapolation.
#define EGW_POLATION_EPO_LINEAR     0x02020000  ///< Constant linear end values' first derivatives extrapolation.
#define EGW_POLATION_EPO_CYCLIC     0x10820000  ///< Cylic curvature repeat extrapolation.
#define EGW_POLATION_EPO_CYCADD     0x20820000  ///< Additive cyclic curvature repeat extrapolation.
#define EGW_POLATION_EXREQEXTDATA   0x00080008  ///< Used to extract extra data required usage from bitfield.
#define EGW_POLATION_EXKNTPSHBKX1   0x00000010  ///< Used to extract x1 knot track pushback usage from bitfield.
#define EGW_POLATION_EXKNTPSHBKX2   0x00000020  ///< Used to extract x2 knot track pushback usage from bitfield.
#define EGW_POLATION_EXUSEENTTRCK   0x00400040  ///< Used to extract use entire track usage from bitfield.
#define EGW_POLATION_EXCYCLIC       0x00800080  ///< Used to extract cyclic usage from bitfield.
#define EGW_POLATION_EXMNPTCNT      0x00070007  ///< Used to extract minimum point count from bitfield.
#define EGW_POLATION_EXINTER        0x0000ffff  ///< Used to extract interpolation mode usage from bitfield.
#define EGW_POLATION_EXEXTRA        0xffff0000  ///< Used to extract extrapolation mode usage from bitfield.

#define EGW_KEYCHANNEL_FRMT_INT8    0x21    ///< Signed 8-bit integer key channels.
#define EGW_KEYCHANNEL_FRMT_UINT8   0x11    ///< Unsigned 8-bit integer key channels.
#define EGW_KEYCHANNEL_FRMT_INT16   0x22    ///< Signed 16-bit integer key channels.
#define EGW_KEYCHANNEL_FRMT_UINT16  0x12    ///< Unsigned 16-bit integer key channels.
#define EGW_KEYCHANNEL_FRMT_INT32   0x24    ///< Signed 32-bit integer key channels.
#define EGW_KEYCHANNEL_FRMT_UINT32  0x14    ///< Unsigned 32-bit integer key channels.
#define EGW_KEYCHANNEL_FRMT_SINGLE  0x44    ///< Signed 32-bit floater key channels.
#define EGW_KEYCHANNEL_FRMT_DOUBLE  0x48    ///< Signed 64-bit floater key channels.
#define EGW_KEYCHANNEL_FRMT_TRIPLE  0x4c    ///< Signed 96-bit floater key channels.
#define EGW_KEYCHANNEL_FRMT_EXBPC   0x0F    ///< Used to extract Bpc from bitfield.
#define EGW_KEYCHANNEL_FRMT_EXUINT  0x10    ///< Used to extract unsigned integer usage from bitfield.
#define EGW_KEYCHANNEL_FRMT_EXINT   0x20    ///< Used to extract signed integer usage from bitfield.
#define EGW_KEYCHANNEL_FRMT_EXFLT   0x40    ///< Used to extract signed floater usage from bitfield.


// !!!: ***** Predefs *****

@class egwValueInterpolator;
@class egwOrientationInterpolator;
@class egwInterpolatorBase;
//@class egwSpring;
//@class egwSpringBase;


// !!!: ***** Key Frames *****

/// Key Frames Container.
/// Universal key frame container.
typedef struct { 
    EGWuint16 fCount;                       ///< Key frame count.
    EGWuint16 cCount;                       ///< Component count.
    EGWuint16 kcCount;                      ///< Key channels count.
    EGWuint16 kcFormat;                     ///< Key channels format.
    EGWbyte* fKeys;                         ///< Frame keys (owned).
    EGWtime* tIndicies;                     ///< Time indicies (owned).
    EGWbyte* kfExtraDat;                    ///< Extra frame key data (if applicable) (owned).
} egwKeyFrame;

/// 3-D Orientation Key Frames Container.
/// Key frame container for three dimensional positional, rotational, & scaling keys.
typedef struct {
    EGWuint16 pfCount;                      ///< Positio key frame count.
    EGWuint16 rfCount;                      ///< Rotatio key frame count.
    EGWuint16 sfCount;                      ///< Scale key frame count.
    EGWuint16 kcFormat;                     ///< Key channels format (static spacer).
    egwVector3f* pfKeys;                    ///< Position frame keys (owned).
    egwQuaternion4f* rfKeys;                ///< Rotation frame keys (owned).
    egwVector3f* sfKeys;                    ///< Scale frame keys (owned).
    EGWtime* ptIndicies;                    ///< Position time indicies (owned, may be shared against another time index array).
    EGWtime* rtIndicies;                    ///< Rotation time indicies (owned, may be shared against another time index array).
    EGWtime* stIndicies;                    ///< Scale time indicies (owned, may be shared against another time index array).
    EGWbyte* pkfExtraDat;                   ///< Extra position frame key data (if applicable) (owned).
    EGWbyte* rkfExtraDat;                   ///< Extra rotation frame key data (if applicable) (owned).
    EGWbyte* skfExtraDat;                   ///< Extra scale frame key data (if applicable) (owned).
} egwOrientKeyFrame4f;

/// Knot Track Line.
/// Contains data related to knot track line tracking.
typedef struct {
    const EGWbyte* okFrame;                 ///< Offsetted knot frame pointer.
    const EGWtime* otIndicie;               ///< Offsetted time indicie pointer.
    const EGWbyte* okfExtraDat;             ///< Offsetted frame extra data pointer.
    EGWuint16 cmpCount;                     ///< Components count.
    EGWuint16 chnCount;                     ///< Channels count.
    EGWuint32 fdPitch;                      ///< Frame data pitch size.
    EGWuint32 efdPitch;                     ///< Extra frame data pitch size.
    EGWuint16 cdPitch;                      ///< Component data pitch size.
    EGWuint16 ecdPitch;                     ///< Extra component data pitch size.
} egwKnotTrackLine;

/// Inter/Extra-polator function type.
typedef void (*EGWiepofuncfp)(const egwKnotTrackLine*, EGWtime, EGWbyte*);

/// Create extra frame data function type.
typedef void (*EGWcefdfuncfp)(const EGWbyte*, EGWbyte* extraData_out, const EGWuint, const EGWuint, const EGWuint, const EGWuint, EGWuint, EGWuint, EGWuint);

/// Knot Track.
/// Contains data related to knot track tracking.
typedef struct {
    EGWint kIndex;                          ///< Knot index.
    egwKnotTrackLine line;                  ///< Track line.
    EGWuint32 pMode;                        ///< I/e-polation mode.
    EGWiepofuncfp fpIpoFunc;                ///< Interpolation routine fp.
    EGWiepofuncfp fpEpoFunc;                ///< Extrapolation routine fp.
} egwKnotTrack;

/// @}

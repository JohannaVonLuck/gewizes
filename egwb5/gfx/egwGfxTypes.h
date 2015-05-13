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

/// @defgroup geWizES_gfx_types egwGfxTypes
/// @ingroup geWizES_gfx
/// Graphics Types.
/// @{

/// @file egwGfxTypes.h
/// Graphics Types.

#import "../inf/egwTypes.h"
#import "../math/egwMathTypes.h"


// !!!: ***** Predefs *****

@class egwLightStack;
@class egwMaterialStack;
@class egwTextureStack;
@class egwInfiniteBounding;
@class egwZeroBounding;
@class egwBoundingSphere;
@class egwBoundingBox;
@class egwBoundingCylinder;
@class egwBoundingFrustum;
@class egwPerspectiveCamera;
@class egwOrthogonalCamera;
@class egwCameraBase;
@class egwBitmappedFont;
@class egwBitmappedFontBase;
@class egwPointLight;
@class egwDirectionalLight;
@class egwSpotLight;
@class egwLightBase;
@class egwMaterial;
@class egwColor;
@class egwShade;
@class egwRenderProxy;
@class egwTexture;
@class egwTextureBase;
@class egwSpritedTexture;
@class egwSpritedTextureBase;
//@class egwStreamedTexture;
//@class egwStreamedTextureBase;


// !!!: ***** Defines *****

#define EGW_TEXTURE_MAXSTATIC       8388608 ///< Maximum uncompressed texture surface size allowed before a streaming instance should be used instead.

#define EGW_SURFACE_DFLTBPACKING    8       ///< Default surface byte packing.

// Surface formats
#define EGW_SURFACE_FRMT_GS8        0x1008  ///< 8-bpp luminance (8).
#define EGW_SURFACE_FRMT_GS8A8      0x1110  ///< 16-bpp luminance + alpha (88).
#define EGW_SURFACE_FRMT_R5G6B5     0x2210  ///< 16-bpp color triplet (565).
#define EGW_SURFACE_FRMT_R5G5B5A1   0x2510  ///< 16-bpp color triplet + alpha (5551).
#define EGW_SURFACE_FRMT_R4G4B4A4   0x2910  ///< 16-bpp color triplet + alpha (4444).
#define EGW_SURFACE_FRMT_R8G8B8     0x2018  ///< 24-bpp color triplet (888).
#define EGW_SURFACE_FRMT_R8G8B8A8   0x2120  ///< 32-bpp color triplet + alpha (8888).
#define EGW_SURFACE_FRMT_PVRTCRGB2  0x12002 ///< 2-bpp PVRTC compressed color triplet (2).
#define EGW_SURFACE_FRMT_PVRTCRGBA2 0x12102 ///< 2-bpp PVRTC compressed color triplet + alpha (2).
#define EGW_SURFACE_FRMT_PVRTCRGB4  0x12004 ///< 4-bpp PVRTC compressed color triplet (4).
#define EGW_SURFACE_FRMT_PVRTCRGBA4 0x12104 ///< 4-bpp PVRTC compressed color triplet + alpha (4).
#define EGW_SURFACE_FRMT_RESERVED1  0x0040  ///< Reserved for future use.
#define EGW_SURFACE_FRMT_PGENMIPS   0x0080  ///< MIPs are pre-generated and appended to image data.
#define EGW_SURFACE_FRMT_EXKIND     0x1ff3f ///< Used to extract surface kind from bitfield.
#define EGW_SURFACE_FRMT_EXBPP      0x003f  ///< Used to extract bits per pixel (bpp) from bitfield.
#define EGW_SURFACE_FRMT_EXAC       0x0100  ///< Used to extract alpha channel usage from bitfield.
#define EGW_SURFACE_FRMT_EXGS       0x1000  ///< Used to extract grey-scale usage from bitfield.
#define EGW_SURFACE_FRMT_EXRGB      0x2000  ///< Used to extract color triplet usage from bitfield.
#define EGW_SURFACE_FRMT_EXPLT      0xc000  ///< Used to extract pallete usage from bitfield (>>12 for bpi).
#define EGW_SURFACE_FRMT_EXSPC      0x0e00  ///< Used to extract special RGB/565, RGBA/5551, RGBA/4444 usage from bitfield.
#define EGW_SURFACE_FRMT_EXCMPRSD   0x10000 ///< Used to extract compressed image usage from bitfield. Note: Operations on compressed images are not supported.
#define EGW_SURFACE_FRMT_EXPVRTC    0x10000 ///< Used to extract compressed PVRTC image usage from bitfield.

// Surface load transforms
#define EGW_SURFACE_TRFM_ENSRLTETMS 0x000001 ///< Ensures that surface size is less than or equal to the max static size.
#define EGW_SURFACE_TRFM_ENSRPOW2   0x000002 ///< Ensures that surface's width & height is a power of 2.
#define EGW_SURFACE_TRFM_ENSRSQR    0x000004 ///< Ensures that surface's width and height are equal.
#define EGW_SURFACE_TRFM_RSZHALF    0x000008 ///< Resizes image by half.
#define EGW_SURFACE_TRFM_FLIPVERT   0x000010 ///< Flips image vertically.
#define EGW_SURFACE_TRFM_FLIPHORZ   0x000020 ///< Flips image horizontally.
#define EGW_SURFACE_TRFM_SWAPRB     0x000040 ///< Swaps red/blue color channels (RGB<->BGR) (if RGB/RGBA).
#define EGW_SURFACE_TRFM_INVERTGS   0x000080 ///< Inverts grey color channel value ([0,1]<->[1,0]) (if GS/GSA).
#define EGW_SURFACE_TRFM_INVERTAC   0x000100 ///< Inverts alpha channel value ([0,1]<->[1,0]) (if GSA/RGBA).
#define EGW_SURFACE_TRFM_CYANTRANS  0x000200 ///< Makes any cyan color (0x00ffff) transparent (if RGBA).
#define EGW_SURFACE_TRFM_MGNTTRANS  0x000400 ///< Makes any purple color (0xff00ff) transparent (if RGBA).
#define EGW_SURFACE_TRFM_OPCTYDILT  0x000800 ///< Replaces transparent pixel's non-alpha values with a nearby opaque color.
#define EGW_SURFACE_TRFM_FORCEGS    0x001000 ///< Forces surface conversion to non-colored/grey-scale values.
#define EGW_SURFACE_TRFM_FORCERGB   0x002000 ///< Forces surface conversion to colored/R8G8B8 values.
#define EGW_SURFACE_TRFM_FORCEAC    0x004000 ///< Forces surface conversion to include alpha/A8 channel.
#define EGW_SURFACE_TRFM_FORCENOAC  0x008000 ///< Forces surface conversion to exclude alpha channel.
#define EGW_SURFACE_TRFM_FCGS8      0x009000 ///< Forces surface conversion to 8-bpp luminance (8).
#define EGW_SURFACE_TRFM_FCGS8A8    0x005000 ///< Forces surface conversion to 16-bpp luminance + alpha (88).
#define EGW_SURFACE_TRFM_FCR5G6B5   0x01a000 ///< Forces surface conversion to 16-bpp color triplet (565).
#define EGW_SURFACE_TRFM_FCR5G5B5A1 0x026000 ///< Forces surface conversion to 16-bpp color triplet + alpha (5551).
#define EGW_SURFACE_TRFM_FCR4G4B4A4 0x046000 ///< Forces surface conversion to 16-bpp color triplet + alpha (4444).
#define EGW_SURFACE_TRFM_FCR8G8B8   0x00a000 ///< Forces surface conversion to 24-bpp color triplet (888).
#define EGW_SURFACE_TRFM_FCR8G8B8A8 0x006000 ///< Forces surface conversion to 32-bpp color triplet + alpha (8888).
#define EGW_SURFACE_TRFM_FCBPCK1    0x100000 ///< Forces 1 byte packing on surface pitch size.
#define EGW_SURFACE_TRFM_FCBPCK2    0x200000 ///< Forces 2 byte packing on surface pitch size.
#define EGW_SURFACE_TRFM_FCBPCK4    0x300000 ///< Forces 4 byte packing on surface pitch size.
#define EGW_SURFACE_TRFM_FCBPCK8    0x400000 ///< Forces 8 byte packing on surface pitch size.
#define EGW_SURFACE_TRFM_FCBPCK16   0x500000 ///< Forces 16 byte packing on surface pitch size.
#define EGW_SURFACE_TRFM_FCBPCK32   0x600000 ///< Forces 32 byte packing on surface pitch size.
#define EGW_SURFACE_TRFM_FCBPCK64   0x700000 ///< Forces 64 byte packing on surface pitch size.
#define EGW_SURFACE_TRFM_FCBPCK128  0x800000 ///< Forces 128 byte packing on surface pitch size.
#define EGW_SURFACE_TRFM_FCBPCK256  0x900000 ///< Forces 256 byte packing on surface pitch size.
#define EGW_SURFACE_TRFM_FCBPCK512  0xa00000 ///< Forces 512 byte packing on surface pitch size.
#define EGW_SURFACE_TRFM_FCBPCK1024 0xb00000 ///< Forces 1024 byte packing on surface pitch size.
#define EGW_SURFACE_TRFM_FCBPCK2048 0xc00000 ///< Forces 2048 byte packing on surface pitch size.
#define EGW_SURFACE_TRFM_FCBPCK4096 0xd00000 ///< Forces 4096 byte packing on surface pitch size.
#define EGW_SURFACE_TRFM_FCBPCK8192 0xe00000 ///< Forces 8192 byte packing on surface pitch size.
#define EGW_SURFACE_TRFM_EXENSURES  0x000007 ///< Used to extract ensurances usage from bitfield.
#define EGW_SURFACE_TRFM_EXDATAOPS  0x000ff8 ///< Used to extract data operations usage from bitfield.
#define EGW_SURFACE_TRFM_EXFORCES   0x0ff000 ///< Used to extract forced conversions usage from bitfield.
#define EGW_SURFACE_TRFM_EXBPACKING 0xf00000 ///< Used to extract forced byte packing usage from bitfield.

// Texture transforms (extends surface transforms)
#define EGW_TEXTURE_TRFM_SHARPEN25  0x1000000 ///< Sharpen image (resize post-op) by .25 for each MIP level.
#define EGW_TEXTURE_TRFM_SHARPEN33  0x2000000 ///< Sharpen image (resize post-op) by .33 for each MIP level.
#define EGW_TEXTURE_TRFM_SHARPEN50  0x3000000 ///< Sharpen image (resize post-op) by .50 for each MIP level.
#define EGW_TEXTURE_TRFM_SHARPEN66  0x4000000 ///< Sharpen image (resize post-op) by .66 for each MIP level.
#define EGW_TEXTURE_TRFM_SHARPEN75  0x5000000 ///< Sharpen image (resize post-op) by .75 for each MIP level.
#define EGW_TEXTURE_TRFM_SHARPEN100 0x6000000 ///< Sharpen image (resize post-op) by 1.0 for each MIP level.
#define EGW_TEXTURE_TRFM_EXSHARPEN  0x7000000 ///< Used to extract sharpen usage from bitfield.

// Texture filtering (& mipmap)
#define EGW_TEXTURE_FLTR_NEAREST    0x0001  ///< Nearest texture filtering (non-mipped).
#define EGW_TEXTURE_FLTR_LINEAR     0x0002  ///< Linear texture filtering (non-mipped).
#define EGW_TEXTURE_FLTR_UNILINEAR  0x0010  ///< Uni-linear texture filtering (mipped).
#define EGW_TEXTURE_FLTR_BILINEAR   0x0020  ///< Bi-linear texture filtering (mipped).
#define EGW_TEXTURE_FLTR_BLHANSTRPC 0x0040  ///< Bi-linear half-anisotropic texture filtering (mipped).
#define EGW_TEXTURE_FLTR_BLFANSTRPC 0x0080  ///< Bi-linear fully-anisotropic texture filtering (mipped).
#define EGW_TEXTURE_FLTR_TRILINEAR  0x0100  ///< Tri-linear texture filtering (mipped).
#define EGW_TEXTURE_FLTR_TLHANSTRPC 0x0200  ///< Tri-linear half-anisotropic texture filtering (mipped).
#define EGW_TEXTURE_FLTR_TLFANSTRPC 0x0400  ///< Tri-linear fully-anisotropic texture filtering (mipped).
#define EGW_TEXTURE_FLTR_DFLTNMIP   0x1000  ///< Default non-mipped filtering.
#define EGW_TEXTURE_FLTR_DFLTMIP    0x2000  ///< Default mipped filtering.
#define EGW_TEXTURE_FLTR_EXNMIPPED  0x000f  ///< Used to extract non-mip-mapped usage from bitfield.
#define EGW_TEXTURE_FLTR_EXMIPPED   0x0ff0  ///< Used to extract mip-mapped usage from bitfield.
#define EGW_TEXTURE_FLTR_EXANSTRPC  0x06c0  ///< Used to extract anisotropic usage from bitfield.
#define EGW_TEXTURE_FLTR_EXDSTRYP   0x0ff0  ///< Used to extract surface destroy process from bitfield.

// Texture fragmentation environment
#define EGW_TEXTURE_FENV_MODULATE   0x0001  ///< Modulated texture fragmenting (default).
#define EGW_TEXTURE_FENV_MODULATEX2 0x0002  ///< Modulated (x2) texture fragmenting.
#define EGW_TEXTURE_FENV_MODULATEX4 0x0004  ///< Modulated (x4) texture fragmenting.
#define EGW_TEXTURE_FENV_DOT3       0x0008  ///< Bump-mapped texture fragmenting.
#define EGW_TEXTURE_FENV_ADD        0x0010  ///< Additive texture fragmenting.
#define EGW_TEXTURE_FENV_ADDSIGNED  0x0020  ///< Additive (signed) texture fragmenting.
#define EGW_TEXTURE_FENV_BLEND      0x0040  ///< Blendive texture fragmenting.
#define EGW_TEXTURE_FENV_DECAL      0x0080  ///< Decaled texture fragmenting.
#define EGW_TEXTURE_FENV_LERP       0x0100  ///< Interpolated texture fragmenting.
#define EGW_TEXTURE_FENV_REPLACE    0x0200  ///< Replaced texture fragmenting.
#define EGW_TEXTURE_FENV_SUBTRACT   0x0400  ///< Subtractive texture fragmenting.

// Texture edge wrapping
#define EGW_TEXTURE_WRAP_CLAMP      0x0001  ///< Clamped (to edge) wrapping.
#define EGW_TEXTURE_WRAP_REPEAT     0x0002  ///< Repeated wrapping.
#define EGW_TEXTURE_WRAP_MRRDREPEAT 0x0004  ///< Mirrored repeating wrapping.

// Font rasterization effects
#define EGW_FONT_EFCT_NORMAL        0x0000  ///< Normal font rasterization.
#define EGW_FONT_EFCT_BOLD          0x0001  ///< Bolded (scaled up) font rasterization.
#define EGW_FONT_EFCT_ITALIC        0x0002  ///< Italiced font rasterization.
#define EGW_FONT_EFCT_UPSIDEDOWN    0x0004  ///< Upsidedown font rasterization.
#define EGW_FONT_EFCT_BACKWARDS     0x0008  ///< Backwards font rasterization.
#define EGW_FONT_EFCT_DPI72         0x0010  ///< Use 72 DPI font rasterization.
#define EGW_FONT_EFCT_DPI75         0x0020  ///< Use 75 DPI font rasterization.
#define EGW_FONT_EFCT_DPI96         0x0040  ///< Use 96 DPI font rasterization (default).
#define EGW_FONT_EFCT_DPI192        0x0080  ///< Use 192 DPI font rasterization.
#define EGW_FONT_EFCT_EXSTYLE       0x000f  ///< Used to extract style usage from bitfield.
#define EGW_FONT_EFCT_EXDPI         0x00f0  ///< Used to extract DPI usage from bitfield.


// !!!: ***** Colors *****

/// 8-bit Grey-scale (FLT1).
typedef union {
    struct {
        EGWsingle l;                        ///< Luminance value [0,1].
    } channel;                              ///< Channel values.
    EGWsingle color[1];                     ///< Color array.
    EGWuint8 bytes[4];                      ///< Byte array.
} egwColor1f;

/// 16-bit Grey-scale + Alpha (FLT2).
typedef union {
    struct {
        EGWsingle l;                        ///< Luminance value [0,1].
        EGWsingle a;                        ///< Alpha value [0,1].
    } channel;                              ///< Channel values.
    EGWsingle color[2];                     ///< Color array.
    EGWuint8 bytes[8];                      ///< Byte array.
} egwColor2f;

/// 24-bit RGB Triplet (FLT3).
typedef union {
    struct {
        EGWsingle r;                        ///< Red value [0,1].
        EGWsingle g;                        ///< Green value [0,1].
        EGWsingle b;                        ///< Blue value [0,1].
    } channel;                              ///< Channel values.
    EGWsingle color[3];                     ///< Color array.
    EGWuint8 bytes[12];                     ///< Byte array.
} egwColor3f;

/// 32-bit RGB Triplet + Alpha (FLT4).
typedef union {
    struct {
        EGWsingle r;                        ///< Red value [0,1].
        EGWsingle g;                        ///< Green value [0,1].
        EGWsingle b;                        ///< Blue value [0,1].
        EGWsingle a;                        ///< Alpha value [0,1].
    } channel;                              ///< Channel values.
    EGWsingle color[4];                     ///< Color array.
    EGWuint8 bytes[16];                     ///< Byte array.
} egwColor4f;


// !!!: ***** Properties *****

/// Material.
/// Standard model material data.
typedef struct {
    egwColor4f ambient;                     ///< Ambient color.
    egwColor4f diffuse;                     ///< Diffuse color.
    egwColor4f specular;                    ///< Specular color.
    egwColor4f emmisive;                    ///< Emmisive color.
    EGWsingle shininess;                    ///< Shininess coefficient [0,1].
} egwMaterial4f;

/// Attenuation.
/// Standard model attenuation data.
typedef struct {
    EGWsingle constant;                     ///< Constant value (C in Ax^2 + Bx + C).
    EGWsingle linear;                       ///< Linear value (B in Ax^2 + Bx + C).
    EGWsingle quadratic;                    ///< Quadratic value (A in Ax^2 + Bx + C).
} egwAttenuation3f;


// !!!: ***** Surface Metrics ******

/// Surface Point.
/// Two dimensional surface point.
typedef union {
    struct {
        EGWint16 x;                         ///< X-coordinate value.
        EGWint16 y;                         ///< Y-coordinate value.
    } axis;                                 ///< Axis coordinate values.
    EGWint16 coord[2];                      ///< Point coordinates array.
    EGWuint8 bytes[4];                      ///< Byte array.
} egwPoint2i;

/// Surface Size.
/// Two dimensional surface size.
typedef union {
    struct {
        EGWuint16 width;                    ///< Width value.
        EGWuint16 height;                   ///< Height value.
    } span;                                 ///< Span values.
    EGWuint16 extent[2];                    ///< Span extents array.
    EGWuint8 bytes[4];                      ///< Byte array.
} egwSize2i;

/// Surface Area.
/// Two dimensional surface area.
typedef struct {
    egwPoint2i origin;                      ///< Origin point (min,min).
    egwSize2i dimension;                    ///< Dimension span.
} egwArea2i;

/// Surface Span.
/// Two dimensional surface span.
typedef struct {
    egwPoint2i origin;                      ///< Origin point.
    egwPoint2i extents;                     ///< Extents span.
} egwSpan2i;


// !!!: ***** Surface Colors *****

/// 8-bit Grey-scale (EGW_SURFACE_FRMT_GS8).
typedef union {
    struct {
        EGWuint8 l;                         ///< Luminance value [0,255].
    } channel;                              ///< Channel values.
    EGWuint8 color[1];                      ///< Color array.
    EGWuint8 bytes[1];                      ///< Byte array.
} egwColorGS;

/// 16-bit Grey-scale + Alpha (EGW_SURFACE_FRMT_GS8A8).
typedef union {
    struct {
        EGWuint8 l;                         ///< Luminance value [0,255].
        EGWuint8 a;                         ///< Alpha value [0,255].
    } channel;                              ///< Channel values.
    EGWuint8 color[2];                      ///< Color array.
    EGWuint8 bytes[2];                      ///< Byte array.
} egwColorGSA;

/// 24-bit RGB Triplet (EGW_SURFACE_FRMT_R8G8B8).
typedef union {
    struct {
        EGWuint8 r;                         ///< Red value [0,255].
        EGWuint8 g;                         ///< Green value [0,255].
        EGWuint8 b;                         ///< Blue value [0,255].
    } channel;                              ///< Channel values.
    EGWuint8 color[3];                      ///< Color array.
    EGWuint8 bytes[3];                      ///< Byte array.
} egwColorRGB;

/// 32-bit RGB Triplet + Alpha (EGW_SURFACE_FRMT_R8G8B8A8).
typedef union {
    struct {
        EGWuint8 r;                         ///< Red value [0,255].
        EGWuint8 g;                         ///< Green value [0,255].
        EGWuint8 b;                         ///< Blue value [0,255].
        EGWuint8 a;                         ///< Alpha value [0,255].
    } channel;                              ///< Channel values.
    EGWuint8 color[4];                      ///< Color array.
    EGWuint8 bytes[4];                      ///< Byte array.
} egwColorRGBA;


// !!!: ***** Surface Images ******

/// Surface Image Container.
/// Universal surface image container.
typedef struct {
    egwSize2i size;                         ///< Size dimensions (pixels).
    EGWuint32 pitch;                        ///< Scanline width (bytes).
    EGWuint32 format;                       ///< Data format.
    EGWbyte* data;                          ///< Pixel data buffer.
} egwSurface;

/// Surface Framing Container.
/// Contains data relating to frame partition of a surface.
typedef struct {
    EGWuint16 fOffset;                      ///< Frame offset for this surface.
    EGWuint16 fCount;                       ///< Total number of frames for this surface.
    EGWuint16 hFrames;                      ///< Total number of horizontal frames.
    EGWuint16 vFrames;                      ///< Total number of vertical frames.
    EGWdouble htSizer;                      ///< Horizontal texture scaling sizer.
    EGWdouble vtSizer;                      ///< Vertical texture scaling sizer.
} egwSurfaceFraming;


// !!!: ***** Font Glyphs *****

/// Font Pixmap Glyph.
/// Bitmapped glyph.
typedef struct {
    EGWuint8 gWidth;                        ///< Glyph width.
    EGWuint8 gHeight;                       ///< Glyph height.
    EGWint8 xOffset;                        ///< Glyph x offset.
    EGWint8 yOffset;                        ///< Glyph y offset.
    EGWuint8 xAdvance;                      ///< Glyph x advance.
    BOOL hasKerning;                        ///< Glyph kerning availability.
    EGWuint16 kernIndex;                    ///< Glyph kerning starting index.
    egwColorGS* gaData;                     ///< Glyph alpha data.
} egwBGlyph;

/// Font Kerning ASCII Mapping Set.
/// Glyph data for font kerning (ASCII-127 only).
typedef struct {
    EGWchar lChar;                          ///< Left character index.
    EGWchar rChar;                          ///< Right character index.
    EGWint8 xOffset;                        ///< Glyph extra x offset.
} egwAMKernSet;

/// Font Pixmap ASCII Mapping Set.
/// Bitmapped glyph mapping (ASCII-127 only).
typedef struct {
    EGWuint8 lHeight;                       ///< Line height.
    EGWint8 lOffset;                        ///< Line y offset.
    EGWuint8 sAdvance;                      ///< Space x advance.
    EGWuint8 flags;                         ///< Flags (NOT SUPPORTED - junk for now).
    EGWuint16 kernSets;                     ///< Kerning sets available.
    egwAMKernSet* kerns;                    ///< Kerning sets' data.
    egwBGlyph glyphs[94];                   ///< Glyph mappings [33,126].
} egwAMGlyphSet;


// !!!: ***** Parameters *****

/// Texture Parameters.
/// Contains optional parameters for texture initialization.
/// @note Used primarily for egwAssetManager:loadAsset: interaction.
typedef struct {
    EGWuint tEnvironment;                   ///< Fragmentation environment (EGW_TEXTRE_FENV_*).
    EGWuint tTransforms;                    ///< Load transformations (EGW_SURFACE_TRFM_* & EGW_TEXTURE_TRFM_*).
    EGWuint tFiltering;                     ///< Filtering operation (EGW_TEXTURE_FLTR_*).
    EGWuint16 tSWrapping;                   ///< Edge wrapping (horizontal/S-coord) (EGW_TEXTURE_WRAP_*).
    EGWuint16 tTWrapping;                   ///< Edge wrapping (vertical/T-coord) (EGW_TEXTURE_WRAP_*).
} egwTexParams;

/// Font Parameters.
/// Contains optional parameters for font initialization.
/// @note Used primarily for egwAssetManager:loadAsset: interaction.
typedef struct {
    EGWuint rEffects;                       ///< Rasterization effects (EGW_FONT_EFCT_*).
    EGWsingle pSize;                        ///< Point size.
    egwColor4f gColor;                      ///< Glyph coloring.
} egwFntParams;


// !!!: ***** Event Delegate Protocols *****

/// Renderable Proxy Event Delegate.
/// Contains event methods that a delegate object can handle.
@protocol egwDRenderProxyEvent <NSObject>

/// Render With Flags.
/// Renders object with provided rendering reply @a flags.
/// @note Do not call this method directly - this method is called automatically by the system.
/// @param [in] flags Bit-wise reply flag settings.
- (void)renderWithFlags:(EGWuint32)flags;

@end

/// @}

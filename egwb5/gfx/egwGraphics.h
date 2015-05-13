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

/// @defgroup geWizES_gfx_graphics egwGraphics
/// @ingroup geWizES_gfx
/// Base Graphics.
/// @{

/// @file egwMath.h
/// Base Graphics Interface.

#import <math.h>
#import "egwGfxTypes.h"
#import "../inf/egwPFont.h"
#import "../math/egwMathTypes.h"


// !!!: ***** Defines *****

#define EGW_OPACDLT_MAXITERATIONS       3   ///< Maximum iterations for opacity dialation to run over.


// !!!: ***** Shared Instances *****

extern egwMaterial4f egwSIMtrlDefault4f;    ///< Shared default material 4f instance.
extern egwMaterial4f egwSIMtrlWhite4f;      ///< Shared white material 4f instance.
extern egwMaterial4f egwSIMtrlBlack4f;      ///< Shared black material 4f instance.

extern egwAttenuation3f egwSIAttnDefault3f; ///< Shared default attenuation 3f instance.

extern egwPoint2i egwSIPointZero2i;         ///< Shared zero point 2i instance.

extern egwColorGSA egwSIColorWhiteGSA;      ///< Shared white color GSA instance.
extern egwColorGSA egwSIColorGrayGSA;       ///< Shared gray color GSA instance.
extern egwColorGSA egwSIColorBlackGSA;      ///< Shared black color GSA instance.
extern egwColorRGBA egwSIColorWhiteRGBA;    ///< Shared white color RGBA instance.
extern egwColorRGBA egwSIColorRedRGBA;      ///< Shared red color RGBA instance.
extern egwColorRGBA egwSIColorGreenRGBA;    ///< Shared green color RGBA instance.
extern egwColorRGBA egwSIColorBlueRGBA;     ///< Shared blue color RGBA instance.
extern egwColorRGBA egwSIColorGrayRGBA;     ///< Shared gray color RGBA instance.
extern egwColorRGBA egwSIColorBlackRGBA;    ///< Shared black color RGBA instance.


// !!!: ***** Helper Routines *****

/// Surface Format From Transforms Routine.
/// Calculates the resulting surface format using the provided parameters.
/// @param [in] transforms Surfacing transforms (EGW_SURFACE_TRFM_*).
/// @param [in] dfltFormat Default surface format (EGW_SURFACE_FRMT_*).
/// @return Resulting surface format (EGW_SURFACE_FRMT_*).
EGWuint32 egwFormatFromSrfcTrfm(EGWuint transforms, EGWuint32 dfltFormat);

/// Surface Byte Packing From Transforms Routine.
/// Calculates the resulting surface byte packing using the provided parameters.
/// @param [in] transforms Surfacing transforms (EGW_SURFACE_TRFM_*).
/// @param [in] dfltBPacking Default byte packing.
/// @return Resulting surface byte packing.
EGWint egwBytePackingFromSrfcTrfm(EGWuint transforms, EGWint dfltBPacking);

/// Format Font String To Constrained Width Routine.
/// Formats a C-style string replacing spaces with endlines in places appropriate to maintain a constrained line width.
/// @param [in] font Font object.
/// @param [in] width Constrained width (pixels).
/// @param [in] string_in C-style string input operand.
/// @param [out] string_out C-style string output operand.
/// @return Maximum width (pixels) of newly formated string, which may be considered an error if > @a width.
EGWuint16 egwFormatFontStringToFit(id<egwPFont> font, EGWuint16 width, const EGWchar* string_in, EGWchar* string_out);

/// Find Kerning Offset Routine.
/// Searches for the appropriate kerning set, if existant, returning the kerning X distance (pixels).
/// @param [in] kerns_in Kerning sets array.
/// @param [in] kernSets_in Number of kerning sets.
/// @param [in] leftChar_in Left character index input operand.
/// @param [in] rightChar_in Right character index input operand.
/// @param [in] start_in Starting search index.
/// @return Kerning X distance value (pixels).
EGWint8 egwFindKerningOffset(const egwAMKernSet* kerns_in, const EGWuint kernSets_in, const EGWchar leftChar_in, const EGWchar rightChar_in, EGWuint start_in);


// !!!: ***** Color Operations *****

/// Material Clamp Routine.
/// Clamps the contents of the material to within correct ranges.
/// @param [in] material_in Material input operand.
/// @param [out] material_out Material output operand.
/// @return @a material_out (for nesting).
egwMaterial4f* egwMtrlClamp4f(const egwMaterial4f* material_in, egwMaterial4f* material_out);

/// Color Clamp Routine (FLT1).
/// Clamps the contents of the color to within correct ranges.
/// @param [in] color_in Color input operand.
/// @param [out] color_out Color ouput operand.
/// @return @a color_out (for nesting).
egwColor1f* egwClrClamp1f(const egwColor1f* color_in, egwColor1f* color_out);

/// Color Clamp Routine (FLT2).
/// Clamps the contents of the color to within correct ranges.
/// @param [in] color_in Color input operand.
/// @param [out] color_out Color ouput operand.
/// @return @a color_out (for nesting).
egwColor2f* egwClrClamp2f(const egwColor2f* color_in, egwColor2f* color_out);

/// Color Clamp Routine (FLT3).
/// Clamps the contents of the color to within correct ranges.
/// @param [in] color_in Color input operand.
/// @param [out] color_out Color ouput operand.
/// @return @a color_out (for nesting).
egwColor3f* egwClrClamp3f(const egwColor3f* color_in, egwColor3f* color_out);

/// Color Clamp Routine (FLT4).
/// Clamps the contents of the color to within correct ranges.
/// @param [in] color_in Color input operand.
/// @param [out] color_out Color ouput operand.
/// @return @a color_out (for nesting).
egwColor4f* egwClrClamp4f(const egwColor4f* color_in, egwColor4f* color_out);

/// Color Convert Routine (FLT1->GS).
/// Converts the contents of a floated color to its byted equivalent.
/// @param [in] color_in Color floated input operand.
/// @param [out] color_out Color byted ouput operand.
/// @return @a color_out (for nesting).
egwColorGS* egwClrConvert1fGS(const egwColor1f* color_in, egwColorGS* color_out);

/// Color Convert Routine (FLT2->GSA).
/// Converts the contents of a floated color to its byted equivalent.
/// @param [in] color_in Color floated input operand.
/// @param [out] color_out Color byted ouput operand.
/// @return @a color_out (for nesting).
egwColorGSA* egwClrConvert2fGSA(const egwColor2f* color_in, egwColorGSA* color_out);

/// Color Convert Routine (FLT3->RGB).
/// Converts the contents of a floated color to its byted equivalent.
/// @param [in] color_in Color floated input operand.
/// @param [out] color_out Color byted ouput operand.
/// @return @a color_out (for nesting).
egwColorRGB* egwClrConvert3fRGB(const egwColor3f* color_in, egwColorRGB* color_out);

/// Color Convert Routine (FLT4->RGBA).
/// Converts the contents of a floated color to its byted equivalent.
/// @param [in] color_in Color floated input operand.
/// @param [out] color_out Color byted ouput operand.
/// @return @a color_out (for nesting).
egwColorRGBA* egwClrConvert4fRGBA(const egwColor4f* color_in, egwColorRGBA* color_out);

/// Color Convert Routine (GS->FLT1).
/// Converts the contents of a byted color to its floated equivalent.
/// @param [in] color_in Color byted input operand.
/// @param [out] color_out Color floated ouput operand.
/// @return @a color_out (for nesting).
egwColor1f* egwClrConvertGS1f(const egwColorGS* color_in, egwColor1f* color_out);

/// Color Convert Routine (GSA->FLT2).
/// Converts the contents of a byted color to its floated equivalent.
/// @param [in] color_in Color byted input operand.
/// @param [out] color_out Color floated ouput operand.
/// @return @a color_out (for nesting).
egwColor2f* egwClrConvertGSA2f(const egwColorGSA* color_in, egwColor2f* color_out);

/// Color Convert Routine (RGB->FLT3).
/// Converts the contents of a byted color to its floated equivalent.
/// @param [in] color_in Color byted input operand.
/// @param [out] color_out Color floated ouput operand.
/// @return @a color_out (for nesting).
egwColor3f* egwClrConvertRGB3f(const egwColorRGB* color_in, egwColor3f* color_out);

/// Color Convert Routine (RGBA->FLT4).
/// Converts the contents of a byted color to its floated equivalent.
/// @param [in] color_in Color byted input operand.
/// @param [out] color_out Color floated ouput operand.
/// @return @a color_out (for nesting).
egwColor4f* egwClrConvertRGBA4f(const egwColorRGBA* color_in, egwColor4f* color_out);


// !!!: ***** Point Operations *****

/// Point Distance Routine.
/// Calculates the distance between two points.
/// @param [in] point_lhs Point lhs operand.
/// @param [in] point_rhs Point rhs operand.
/// @return Distance scalar.
EGWint16 egwPntDistance2i(const egwPoint2i* point_lhs, const egwPoint2i* point_rhs);

/// Point Squared Distance Routine.
/// Calculates the squared distance between two points.
/// @param [in] point_lhs Point lhs operand.
/// @param [in] point_rhs Point rhs operand.
/// @return Distance squared scalar.
EGWint16 egwPntDistanceSqrd2i(const egwPoint2i* point_lhs, const egwPoint2i* point_rhs);

/// Point Angle Formed Routine.
/// Calculates the angle formed from two points.
/// @param [in] point_lhs Point lhs operand.
/// @param [in] point_rhs Point rhs operand.
/// @return Angle between scalar (radians).
EGWsingle egwPntAngleFrmd2i(const egwPoint2i* point_lhs, const egwPoint2i* point_rhs);

/// Point Area Routine.
/// Calculates the area from two points.
/// @param [in] point_fr Point from operand.
/// @param [in] point_to Point to operand.
/// @param [out] area_out Area output operand.
/// @return @a area_out (for nesting).
egwArea2i* egwPntArea2i(const egwPoint2i* point_fr, const egwPoint2i* point_to, egwArea2i* area_out);

/// Point Span Routine.
/// Calculates the span from two points.
/// @param [in] point_fr Point from operand.
/// @param [in] point_to Point to operand.
/// @param [out] span_out Span output operand.
/// @return @a span_out (for nesting).
egwSpan2i* egwPntSpan2i(const egwPoint2i* point_fr, const egwPoint2i* point_to, egwSpan2i* span_out);


// !!!: ***** Surface Operations *****

/// Surface Allocation Routine.
/// Allocates the surface structure using the provided parameters.
/// @param [out] surface_out Surface output structure.
/// @param [in] format Surface format (EGW_SURFACE_FRMT_*).
/// @param [in] width Surface width (pixels).
/// @param [in] height Surface height (pixels).
/// @param [in] packingB Surface byte packing.
/// @return @a surface_out (for nesting), otherwise NULL if failure initializing.
egwSurface* egwSrfcAlloc(egwSurface* surface_out, EGWuint32 format, EGWuint16 width, EGWuint16 height, EGWuint16 packingB);

/// Surface Copy Routine.
/// Copies the surface structure into a newly allocated one.
/// @param [in] surface_in Surface input structure.
/// @param [out] surface_out Surface output structure.
/// @return @a surface_out (for nesting), otherwise NULL if failure copying.
egwSurface* egwSrfcCopy(const egwSurface* surface_in, egwSurface* surface_out);

/// Surface Free Routine.
/// Frees the contents of the surface structure.
/// @param [in,out] surface_inout Surface input/output structure.
/// @return @a surface_inout (for nesting), otherwise NULL if failure free'ing.
egwSurface* egwSrfcFree(egwSurface* surface_inout);

/// Surface Resize Half Routine.
/// Attempts to resize the surface by half its original size.
/// @param [in,out] surface_inout Surface input/output structure.
/// @return @a surface_inout (for nesting), otherwise NULL if failure resizing.
egwSurface* egwSrfcResizeHalf(egwSurface* surface_inout);

/// Surface Flip Vertically Routine.
/// Flips a surface's contents vertically.
/// @param [in,out] surface_inout Surface input/output structure.
/// @return @a surface_inout (for nesting).
egwSurface* egwSrfcFlipVert(egwSurface* surface_inout);

/// Surface Flip Horizontal Routine.
/// Flips a surface's contents horizontally.
/// @param [in,out] surface_inout Surface input/output structure.
/// @return @a surface_inout (for nesting).
egwSurface* egwSrfcFlipHorz(egwSurface* surface_inout);

/// Surface Red/Blue Channel Swap Routine.
/// Swaps the red/blue channels of a RGB/A surface structure.
/// @param [in,out] surface_inout Surface input/output structure.
/// @return @a surface_inout (for nesting), otherwise NULL if surface not RGB/A.
egwSurface* egwSrfcSwapRB(egwSurface* surface_inout);

/// Surface Invert Grey Scale Routine.
/// Inverts the luminance value of a GS/A surface structure.
/// @param [in,out] surface_inout Surface input/output structure.
/// @return @a surface_inout (for nesting), otherwise NULL if surface not GS/A.
egwSurface* egwSrfcInvertGS(egwSurface* surface_inout);

/// Surface Invert Alpha Channel Routine.
/// Inverts the alpha channel value of a +A surface structure.
/// @param [in,out] surface_inout Surface input/output structure.
/// @return @a surface_inout (for nesting), otherwise NULL if surface not +A.
egwSurface* egwSrfcInvertAC(egwSurface* surface_inout);

/// Surface Cyan To Transparency Routine.
/// Converts all cyan colors (0,255,255) to full transparency in a surface.
/// @param [in,out] surface_inout Surface input/output structure.
/// @return @a surface_inout (for nesting), otherwise NULL if surface not RGB/A.
egwSurface* egwSrfcCyanTT(egwSurface* surface_inout);

/// Surface Magenta To Transparency Routine.
/// Converts all magenta colors (255,0,255) to full transparency in a surface.
/// @param [in,out] surface_inout Surface input/output structure.
/// @return @a surface_inout (for nesting), otherwise NULL if surface not RGB/A.
egwSurface* egwSrfcMagentaTT(egwSurface* surface_inout);

/// Surface Opacity Dialation Routine.
/// Smudges the color values of non-transparent pixels into nearby pixels that are transparent to reduce texture filter color bleeding.
/// @param [in,out] surface_inout Surface input/output structure.
/// @return @a surface_inout (for nesting), otherwise NULL if surface not +A.
egwSurface* egwSrfcOpacityDilate(egwSurface* surface_inout);

/// Surface Convert Routine.
/// Attempts to convert the surface structure to a new format.
/// @param [in] format New format to convert to (EGW_SURFACE_FRMT_*).
/// @param [in] surface_in Surface input structure.
/// @param [out] surface_out Surface output structure.
/// @return @a surface_out (for nesting), otherwise NULL if failure converting.
egwSurface* egwSrfcConvert(EGWuint format, const egwSurface* surface_in, egwSurface* surface_out);

/// Surface Repacking Routine.
/// Attempts to repack the surface structure to a new byte packing.
/// @param [in] packingB New byte packing.
/// @param [in] surface_in Surface input structure.
/// @param [out] surface_out Surface output structure.
/// @return @a surface_out (for nesting), otherwise NULL if failure repacking.
egwSurface* egwSrfcRepack(EGWuint16 packingB, const egwSurface* surface_in, egwSurface* surface_out);

/// Surface Smudge Extend Routine.
/// Attempts to smudge extend (copy edge pixels across an extended canvas size) a surface.
/// @param [in] width New surface width.
/// @param [in] height New surface height.
/// @param [in] surface_in Surface input structure.
/// @param [out] surface_out Surface output structure.
/// @return @a surface_out (for nesting), otherwise NULL if failure smudge extending.
egwSurface* egwSrfcSmdgExtd(EGWuint16 width, EGWuint16 height, const egwSurface* surface_in, egwSurface* surface_out);

/// Surface Maximum Alpha Routine.
/// Calculates the maximum alpha channel value contained by a surface structure.
/// @param [in] surface_in Surface input structure.
/// @return Maximum alpha channel value.
EGWuint8 egwSrfcMaxAC(const egwSurface* surface_in);

/// Surface Minimum Alpha Routine.
/// Calculates the minimum alpha channel value contained by a surface structure.
/// @param [in] surface_in Surface input structure.
/// @return Minimum alpha channel value.
EGWuint8 egwSrfcMinAC(const egwSurface* surface_in);

/// Surface Packing Routine.
/// Calculates the minimum byte packing that has been used by a surface structure.
/// @param [in] surface_in Surface input structure.
/// @return Minimum byte packing.
EGWint egwSrfcPacking(const egwSurface* surface_in);


// !!!: ***** Pixel Operations *****

/// Pixel Read Grey Scale Color.
/// Reads a grey scale color from a raw pixel buffer.
/// @param [in] format Format of raw pixel buffer.
/// @param [in] pxl_in Raw pixel input operand.
/// @param [out] val_out Grey scale color output operand.
void egwPxlReadGSb(EGWuint format, const EGWbyte* pxl_in, egwColorGS* val_out);

/// Pixel Read Grey Scale Alpha Color.
/// Reads a grey scale +alpha color from a raw pixel buffer.
/// @param [in] format Format of raw pixel buffer.
/// @param [in] pxl_in Raw pixel input operand.
/// @param [out] val_out Grey scale +alpha color output operand.
void egwPxlReadGSAb(EGWuint format, const EGWbyte* pxl_in, egwColorGSA* val_out);

/// Pixel Read Red Green Blue Color.
/// Reads a red green blue color from a raw pixel buffer.
/// @param [in] format Format of raw pixel buffer.
/// @param [in] pxl_in Raw pixel input operand.
/// @param [out] val_out Red green blue color output operand.
void egwPxlReadRGBb(EGWuint format, const EGWbyte* pxl_in, egwColorRGB* val_out);

/// Pixel Read Red Green Blue Alpha Color.
/// Reads a red green blue +alpha color from a raw pixel buffer.
/// @param [in] format Format of raw pixel buffer.
/// @param [in] pxl_in Raw pixel input operand.
/// @param [out] val_out Red green blue +alpha color output operand.
void egwPxlReadRGBAb(EGWuint format, const EGWbyte* pxl_in, egwColorRGBA* val_out);

/// Arrayed Pixel Read Grey Scale Color.
/// Reads an array of grey scale colors from a raw pixel buffer.
/// @param [in] format Format of raw pixel buffer.
/// @param [in] pxls_in Array of raw pixels input operands.
/// @param [out] vals_out Array of grey scale color output operands.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwPxlReadGSbv(EGWuint format, const EGWbyte* pxls_in, egwColorGS* vals_out, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count);

/// Arrayed Pixel Read Grey Scale Alpha Color.
/// Reads an array of grey scale +alpha colors from a raw pixel buffer.
/// @param [in] format Format of raw pixel buffer.
/// @param [in] pxls_in Array of raw pixels input operands.
/// @param [out] vals_out Array of grey scale +alpha color output operands.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwPxlReadGSAbv(EGWuint format, const EGWbyte* pxls_in, egwColorGSA* vals_out, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count);

/// Arrayed Pixel Read Red Green Blue Color.
/// Reads an array of red green blue colors from a raw pixel buffer.
/// @param [in] format Format of raw pixel buffer.
/// @param [in] pxls_in Array of raw pixels input operands.
/// @param [out] vals_out Array of red green blue color output operands.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwPxlReadRGBbv(EGWuint format, const EGWbyte* pxls_in, egwColorRGB* vals_out, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count);

/// Arrayed Pixel Read Red Green Blue Alpha Color.
/// Reads an array of red green blue +alpha colors from a raw pixel buffer.
/// @param [in] format Format of raw pixel buffer.
/// @param [in] pxls_in Array of raw pixels input operands.
/// @param [out] vals_out Array of red green blue +alpha color output operands.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwPxlReadRGBAbv(EGWuint format, const EGWbyte* pxls_in, egwColorRGBA* vals_out, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count);

/// Pixel Write Grey Scale Color.
/// Writes a grey scale color to a raw pixel buffer.
/// @param [in] format Format of raw pixel buffer.
/// @param [in] val_in Grey scale color input operand.
/// @param [out] pxl_out Raw pixel output operand.
void egwPxlWriteGSb(EGWuint format, const egwColorGS* val_in, EGWbyte* pxl_out);

/// Pixel Write Grey Scale Alpha Color.
/// Writes a grey scale +alpha color to a raw pixel buffer.
/// @param [in] format Format of raw pixel buffer.
/// @param [in] val_in Grey scale +alpha color input operand.
/// @param [out] pxl_out Raw pixel output operand.
void egwPxlWriteGSAb(EGWuint format, const egwColorGSA* val_in, EGWbyte* pxl_out);

/// Pixel Write Red Green Blue Color.
/// Writes a red green blue color to a raw pixel buffer.
/// @param [in] format Format of raw pixel buffer.
/// @param [in] val_in Red green blue color input operand.
/// @param [out] pxl_out Raw pixel output operand.
void egwPxlWriteRGBb(EGWuint format, const egwColorRGB* val_in, EGWbyte* pxl_out);

/// Pixel Write Red Green Blue Alpha Color.
/// Writes a red green blue +alpha color to a raw pixel buffer.
/// @param [in] format Format of raw pixel buffer.
/// @param [in] val_in Red green blue +alpha color input operand.
/// @param [out] pxl_out Raw pixel output operand.
void egwPxlWriteRGBAb(EGWuint format, const egwColorRGBA* val_in, EGWbyte* pxl_out);

/// Arrayed Pixel Write Grey Scale Color.
/// Writes an array of grey scale colors to a raw pixel buffer.
/// @param [in] format Format of raw pixel buffer.
/// @param [in] vals_in Array of grey scale color input operands.
/// @param [out] pxls_out Array of raw pixels output operands.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwPxlWriteGSbv(EGWuint format, const egwColorGS* vals_in, EGWbyte* pxls_out, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count);

/// Arrayed Pixel Write Grey Scale Alpha Color.
/// Writes an array of grey scale +alpha colors to a raw pixel buffer.
/// @param [in] format Format of raw pixel buffer.
/// @param [in] vals_in Array of grey scale +alpha color input operands.
/// @param [out] pxls_out Array of raw pixels output operands.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwPxlWriteGSAbv(EGWuint format, const egwColorGSA* vals_in, EGWbyte* pxls_out, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count);

/// Arrayed Pixel Write Red Green Blue Color.
/// Writes an array of red green blue colors to a raw pixel buffer.
/// @param [in] format Format of raw pixel buffer.
/// @param [in] vals_in Array of red green blue color input operands.
/// @param [out] pxls_out Array of raw pixels output operands.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwPxlWriteRGBbv(EGWuint format, const egwColorRGB* vals_in, EGWbyte* pxls_out, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count);

/// Arrayed Pixel Write Red Green Blue Alpha Color.
/// Writes an array of red green blue +alpha colors to a raw pixel buffer.
/// @param [in] format Format of raw pixel buffer.
/// @param [in] vals_in Array of red green blue +alpha color input operands.
/// @param [out] pxls_out Array of raw pixels output operands.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwPxlWriteRGBAbv(EGWuint format, const egwColorRGBA* vals_in, EGWbyte* pxls_out, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count);

/// @}

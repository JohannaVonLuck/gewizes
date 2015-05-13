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

/// @file egwGraphics.m
/// @ingroup geWizES_gfx_graphics
/// Base Graphics Implementation.

#import <math.h>
#import "egwGraphics.h"
#import "../math/egwMath.h"
#import "../math/egwVector.h"
#import "../geo/egwGeometry.h"


egwMaterial4f egwSIMtrlDefault4f =      { 0.2f,0.2f,0.2f,1.0f, 0.8f,0.8f,0.8f,1.0f, 0.0f,0.0f,0.0f,1.0f, 0.0f,0.0f,0.0f,1.0f, 0.0f };
egwMaterial4f egwSIMtrlWhite4f =        { 1.0f,1.0f,1.0f,1.0f, 0.8f,0.8f,0.8f,1.0f, 0.0f,0.0f,0.0f,1.0f, 0.0f,0.0f,0.0f,1.0f, 0.0f };
egwMaterial4f egwSIMtrlBlack4f =        { 0.2f,0.2f,0.2f,1.0f, 0.0f,0.0f,0.0f,1.0f, 0.0f,0.0f,0.0f,1.0f, 0.0f,0.0f,0.0f,1.0f, 0.0f };
egwAttenuation3f egwSIAttnDefault3f =   { 1.0f,0.0f,0.0f };
egwPoint2i egwSIPointZero2i =           { (EGWint16)0, (EGWint16)0 };
egwColorGSA egwSIColorWhiteGSA =        { (EGWuint8)255, (EGWuint8)255 };
egwColorGSA egwSIColorGrayGSA =         { (EGWuint8)128, (EGWuint8)255 };
egwColorGSA egwSIColorBlackGSA =        { (EGWuint8)0, (EGWuint8)255 };
egwColorRGBA egwSIColorWhiteRGBA =      { (EGWuint8)255, (EGWuint8)255, (EGWuint8)255, (EGWuint8)255 };
egwColorRGBA egwSIColorRedRGBA =        { (EGWuint8)255, (EGWuint8)0, (EGWuint8)0, (EGWuint8)255 };
egwColorRGBA egwSIColorGreenRGBA =      { (EGWuint8)0, (EGWuint8)255, (EGWuint8)0, (EGWuint8)255 };
egwColorRGBA egwSIColorBlueRGBA =       { (EGWuint8)0, (EGWuint8)0, (EGWuint8)255, (EGWuint8)255 };
egwColorRGBA egwSIColorGrayRGBA =       { (EGWuint8)128, (EGWuint8)128, (EGWuint8)128, (EGWuint8)255 };
egwColorRGBA egwSIColorBlackRGBA =      { (EGWuint8)0, (EGWuint8)0, (EGWuint8)0, (EGWuint8)255 };


EGWuint32 egwFormatFromSrfcTrfm(EGWuint transforms, EGWuint32 dfltFormat) {
    switch(transforms & EGW_SURFACE_TRFM_EXFORCES) {
        case EGW_SURFACE_TRFM_FCGS8: return EGW_SURFACE_FRMT_GS8;
        case EGW_SURFACE_TRFM_FCGS8A8: return EGW_SURFACE_FRMT_GS8A8;
        case EGW_SURFACE_TRFM_FCR5G6B5: return EGW_SURFACE_FRMT_R5G6B5;
        case EGW_SURFACE_TRFM_FCR5G5B5A1: return EGW_SURFACE_FRMT_R5G5B5A1;
        case EGW_SURFACE_TRFM_FCR4G4B4A4: return EGW_SURFACE_FRMT_R4G4B4A4;
        case EGW_SURFACE_TRFM_FCR8G8B8: return EGW_SURFACE_FRMT_R8G8B8;
        case EGW_SURFACE_TRFM_FCR8G8B8A8: return EGW_SURFACE_FRMT_R8G8B8A8;
        case EGW_SURFACE_TRFM_FORCEGS: {
            switch(dfltFormat) {
                case EGW_SURFACE_FRMT_GS8: return EGW_SURFACE_FRMT_GS8;
                case EGW_SURFACE_FRMT_GS8A8: return EGW_SURFACE_FRMT_GS8A8;
                case EGW_SURFACE_FRMT_R5G6B5: return EGW_SURFACE_FRMT_GS8;
                case EGW_SURFACE_FRMT_R5G5B5A1: return EGW_SURFACE_FRMT_GS8A8;
                case EGW_SURFACE_FRMT_R4G4B4A4: return EGW_SURFACE_FRMT_GS8A8;
                case EGW_SURFACE_FRMT_R8G8B8: return EGW_SURFACE_FRMT_GS8;
                case EGW_SURFACE_FRMT_R8G8B8A8: return EGW_SURFACE_FRMT_GS8A8;
                default: return (dfltFormat & ~(EGW_SURFACE_FRMT_EXGS | EGW_SURFACE_FRMT_EXRGB)) | EGW_SURFACE_FRMT_EXGS;
            }
        } break;
        case EGW_SURFACE_TRFM_FORCERGB: {
            switch(dfltFormat) {
                case EGW_SURFACE_FRMT_GS8: return EGW_SURFACE_FRMT_R8G8B8;
                case EGW_SURFACE_FRMT_GS8A8: return EGW_SURFACE_FRMT_R8G8B8A8;
                case EGW_SURFACE_FRMT_R5G6B5: return EGW_SURFACE_FRMT_R5G6B5;
                case EGW_SURFACE_FRMT_R5G5B5A1: return EGW_SURFACE_FRMT_R5G5B5A1;
                case EGW_SURFACE_FRMT_R4G4B4A4: return EGW_SURFACE_FRMT_R4G4B4A4;
                case EGW_SURFACE_FRMT_R8G8B8: return EGW_SURFACE_FRMT_R8G8B8;
                case EGW_SURFACE_FRMT_R8G8B8A8: return EGW_SURFACE_FRMT_R8G8B8A8;
                default: return (dfltFormat & ~(EGW_SURFACE_FRMT_EXGS | EGW_SURFACE_FRMT_EXRGB)) | EGW_SURFACE_FRMT_EXRGB;
            }
        } break;
        case EGW_SURFACE_TRFM_FORCEAC: {
            switch(dfltFormat) {
                case EGW_SURFACE_FRMT_GS8: return EGW_SURFACE_FRMT_GS8A8;
                case EGW_SURFACE_FRMT_GS8A8: return EGW_SURFACE_FRMT_GS8A8;
                case EGW_SURFACE_FRMT_R5G6B5: return EGW_SURFACE_FRMT_R5G5B5A1;
                case EGW_SURFACE_FRMT_R5G5B5A1: return EGW_SURFACE_FRMT_R5G5B5A1;
                case EGW_SURFACE_FRMT_R4G4B4A4: return EGW_SURFACE_FRMT_R4G4B4A4;
                case EGW_SURFACE_FRMT_R8G8B8: return EGW_SURFACE_FRMT_R8G8B8A8;
                case EGW_SURFACE_FRMT_R8G8B8A8: return EGW_SURFACE_FRMT_R8G8B8A8;
                default: return dfltFormat | EGW_SURFACE_FRMT_EXAC;
            }
        } break;
        case EGW_SURFACE_TRFM_FORCENOAC: {
            switch(dfltFormat) {
                case EGW_SURFACE_FRMT_GS8: return EGW_SURFACE_FRMT_GS8;
                case EGW_SURFACE_FRMT_GS8A8: return EGW_SURFACE_FRMT_GS8;
                case EGW_SURFACE_FRMT_R5G6B5: return EGW_SURFACE_FRMT_R5G6B5;
                case EGW_SURFACE_FRMT_R5G5B5A1: return EGW_SURFACE_FRMT_R5G6B5;
                case EGW_SURFACE_FRMT_R4G4B4A4: return EGW_SURFACE_FRMT_R5G6B5;
                case EGW_SURFACE_FRMT_R8G8B8: return EGW_SURFACE_FRMT_R8G8B8;
                case EGW_SURFACE_FRMT_R8G8B8A8: return EGW_SURFACE_FRMT_R8G8B8;
                default: return dfltFormat & ~EGW_SURFACE_FRMT_EXAC;
            }
        } break;
        default: return dfltFormat;
    }
}

EGWint egwBytePackingFromSrfcTrfm(EGWuint transforms, EGWint dfltBPacking) {
    switch(transforms & EGW_SURFACE_TRFM_EXBPACKING) {
        case EGW_SURFACE_TRFM_FCBPCK1: return 1;
        case EGW_SURFACE_TRFM_FCBPCK2: return 2;
        case EGW_SURFACE_TRFM_FCBPCK4: return 4;
        case EGW_SURFACE_TRFM_FCBPCK8: return 8;
        case EGW_SURFACE_TRFM_FCBPCK16: return 16;
        case EGW_SURFACE_TRFM_FCBPCK32: return 32;
        case EGW_SURFACE_TRFM_FCBPCK64: return 64;
        case EGW_SURFACE_TRFM_FCBPCK128: return 128;
        case EGW_SURFACE_TRFM_FCBPCK256: return 256;
        case EGW_SURFACE_TRFM_FCBPCK512: return 512;
        case EGW_SURFACE_TRFM_FCBPCK1024: return 1024;
        case EGW_SURFACE_TRFM_FCBPCK2048: return 2048;
        case EGW_SURFACE_TRFM_FCBPCK4096: return 4096;
        case EGW_SURFACE_TRFM_FCBPCK8192: return 8192;
        default: return dfltBPacking;
    }
}

EGWuint16 egwFormatFontStringToFit(id<egwPFont> font, EGWuint16 width, const EGWchar* string_in, EGWchar* string_out) {
    EGWuint16 retWidth = 0;
    
    if(*string_in) {
        EGWuint16 runWidth = 0;
        EGWchar* startRun = string_out;
        
        *string_out = *string_in;
        ++string_in; ++string_out;
        
        while(*startRun) {
            *string_out = *string_in;
            
            if(*string_in == ' ' || *string_in == '\n' || *string_in == '\0') {
                egwSize2i renderSize;
                {   EGWchar temp = *string_in; // Safety for when string_in == string_out and rewrite check
                    *string_out = '\0';
                    [font calculateString:startRun renderSize:&renderSize];
                    *string_out = temp;
                }
                runWidth += renderSize.span.width;
                
                if(runWidth < width) { // Less than alotment size
                    if(*string_in == ' ') { // Default continue
                        startRun = string_out;
                    } else if(*string_in == '\n') { // Newline on input
                        if(runWidth > retWidth) retWidth = runWidth;
                        runWidth = 0;
                        startRun = string_out + 1;
                    } else { // End of string
                        if(runWidth > retWidth) retWidth = runWidth;
                        startRun = string_out;
                    }
                } else if(runWidth == width || *startRun != ' ') { // Equal to size or oversize with initial word longer than alotment
                    if(*string_in != '\0') { // Push newline regardless
                        *string_out = '\n';
                        if(runWidth > retWidth) retWidth = runWidth;
                        runWidth = 0;
                        startRun = string_out + 1;
                    } else { // End of string
                        if(runWidth > retWidth) retWidth = runWidth;
                        startRun = string_out;
                    }
                } else { // Oversize and can fix (startRun at ' '), change last start run
                        *startRun = '\n';
                        runWidth -= renderSize.span.width;
                        if(runWidth > retWidth) retWidth = runWidth;
                        runWidth = 0;
                        startRun = startRun + 1; // Jump off previous startRun only
                        --string_in; --string_out; // Redo runLength compute/check
                }
            }
            
            ++string_in; ++string_out;
        }
    }
    
    return retWidth;
}

EGWint8 egwFindKerningOffset(const egwAMKernSet* kerns_in, const EGWuint kernSets_in, const EGWchar leftChar_in, const EGWchar rightChar_in, EGWuint start_in) {
    EGWint8 retVal = 0;
    
    if(kerns_in) {
        while(start_in < kernSets_in && kerns_in[start_in].lChar == leftChar_in) {
            if(kerns_in[start_in].rChar == rightChar_in) {
                retVal = kerns_in[start_in].xOffset;
                break;
            }
            
            ++start_in;
        }
    }
    
    return retVal;
}

egwMaterial4f* egwMtrlClamp4f(const egwMaterial4f* material_in, egwMaterial4f* material_out) {
    material_out->ambient.channel.r = egwClamp01f(material_in->ambient.channel.r);
    material_out->ambient.channel.g = egwClamp01f(material_in->ambient.channel.g);
    material_out->ambient.channel.b = egwClamp01f(material_in->ambient.channel.b);
    material_out->ambient.channel.a = egwClamp01f(material_in->ambient.channel.a);
    material_out->diffuse.channel.r = egwClamp01f(material_in->diffuse.channel.r);
    material_out->diffuse.channel.g = egwClamp01f(material_in->diffuse.channel.g);
    material_out->diffuse.channel.b = egwClamp01f(material_in->diffuse.channel.b);
    material_out->diffuse.channel.a = egwClamp01f(material_in->diffuse.channel.a);
    material_out->specular.channel.r = egwClamp01f(material_in->specular.channel.r);
    material_out->specular.channel.g = egwClamp01f(material_in->specular.channel.g);
    material_out->specular.channel.b = egwClamp01f(material_in->specular.channel.b);
    material_out->specular.channel.a = egwClamp01f(material_in->specular.channel.a);
    material_out->emmisive.channel.r = egwClamp01f(material_in->emmisive.channel.r);
    material_out->emmisive.channel.g = egwClamp01f(material_in->emmisive.channel.g);
    material_out->emmisive.channel.b = egwClamp01f(material_in->emmisive.channel.b);
    material_out->emmisive.channel.a = egwClamp01f(material_in->emmisive.channel.a);
    material_out->shininess = egwClamp01f(material_in->shininess);
    return material_out;
}

egwColor1f* egwClrClamp1f(const egwColor1f* color_in, egwColor1f* color_out) {
    color_out->channel.l = egwClamp01f(color_in->channel.l);
    return color_out;
}

egwColor2f* egwClrClamp2f(const egwColor2f* color_in, egwColor2f* color_out) {
    color_out->channel.l = egwClamp01f(color_in->channel.l);
    color_out->channel.a = egwClamp01f(color_in->channel.a);
    return color_out;
}

egwColor3f* egwClrClamp3f(const egwColor3f* color_in, egwColor3f* color_out) {
    color_out->channel.r = egwClamp01f(color_in->channel.r);
    color_out->channel.g = egwClamp01f(color_in->channel.g);
    color_out->channel.b = egwClamp01f(color_in->channel.b);
    return color_out;
}

egwColor4f* egwClrClamp4f(const egwColor4f* color_in, egwColor4f* color_out) {
    color_out->channel.r = egwClamp01f(color_in->channel.r);
    color_out->channel.g = egwClamp01f(color_in->channel.g);
    color_out->channel.b = egwClamp01f(color_in->channel.b);
    color_out->channel.a = egwClamp01f(color_in->channel.a);
    return color_out;
}

egwColorGS* egwClrConvert1fGS(const egwColor1f* color_in, egwColorGS* color_out) {
    color_out->channel.l = (EGWuint8)egwClamp0255i(color_in->channel.l * 255.0f);
    return color_out;
}

egwColorGSA* egwClrConvert2fGSA(const egwColor2f* color_in, egwColorGSA* color_out) {
    color_out->channel.l = (EGWuint8)egwClamp0255i(color_in->channel.l * 255.0f);
    color_out->channel.a = (EGWuint8)egwClamp0255i(color_in->channel.a * 255.0f);
    return color_out;
}

egwColorRGB* egwClrConvert3fRGB(const egwColor3f* color_in, egwColorRGB* color_out) {
    color_out->channel.r = (EGWuint8)egwClamp0255i(color_in->channel.r * 255.0f);
    color_out->channel.g = (EGWuint8)egwClamp0255i(color_in->channel.g * 255.0f);
    color_out->channel.b = (EGWuint8)egwClamp0255i(color_in->channel.b * 255.0f);
    return color_out;
}

egwColorRGBA* egwClrConvert4fRGBA(const egwColor4f* color_in, egwColorRGBA* color_out) {
    color_out->channel.r = (EGWuint8)egwClamp0255i(color_in->channel.r * 255.0f);
    color_out->channel.g = (EGWuint8)egwClamp0255i(color_in->channel.g * 255.0f);
    color_out->channel.b = (EGWuint8)egwClamp0255i(color_in->channel.b * 255.0f);
    color_out->channel.a = (EGWuint8)egwClamp0255i(color_in->channel.a * 255.0f);
    return color_out;
}

egwColor1f* egwClrConvertGS1f(const egwColorGS* color_in, egwColor1f* color_out) {
    color_out->channel.l = egwClamp01f((EGWsingle)(color_in->channel.l) / 255.0f);
    return color_out;
}

egwColor2f* egwClrConvertGSA2f(const egwColorGSA* color_in, egwColor2f* color_out) {
    color_out->channel.l = egwClamp01f((EGWsingle)(color_in->channel.l) / 255.0f);
    color_out->channel.a = egwClamp01f((EGWsingle)(color_in->channel.a) / 255.0f);
    return color_out;
}

egwColor3f* egwClrConvertRGB3f(const egwColorRGB* color_in, egwColor3f* color_out) {
    color_out->channel.r = egwClamp01f((EGWsingle)(color_in->channel.r) / 255.0f);
    color_out->channel.g = egwClamp01f((EGWsingle)(color_in->channel.g) / 255.0f);
    color_out->channel.b = egwClamp01f((EGWsingle)(color_in->channel.b) / 255.0f);
    return color_out;
}

egwColor4f* egwClrConvertRGBA4f(const egwColorRGBA* color_in, egwColor4f* color_out) {
    color_out->channel.r = egwClamp01f((EGWsingle)(color_in->channel.r) / 255.0f);
    color_out->channel.g = egwClamp01f((EGWsingle)(color_in->channel.g) / 255.0f);
    color_out->channel.b = egwClamp01f((EGWsingle)(color_in->channel.b) / 255.0f);
    color_out->channel.a = egwClamp01f((EGWsingle)(color_in->channel.a) / 255.0f);
    return color_out;
}

EGWint16 egwPntDistance2i(const egwPoint2i* point_lhs, const egwPoint2i* point_rhs) {
    return (EGWint16)egwSqrtf((EGWsingle)(((point_lhs->axis.x - point_rhs->axis.x) * (point_lhs->axis.x - point_rhs->axis.x)) +
                                          ((point_lhs->axis.y - point_rhs->axis.y) * (point_lhs->axis.y - point_rhs->axis.y))));
}

EGWint16 egwPntDistanceSqrd2i(const egwPoint2i* point_lhs, const egwPoint2i* point_rhs) {
    return (((point_lhs->axis.x - point_rhs->axis.x) * (point_lhs->axis.x - point_rhs->axis.x)) +
            ((point_lhs->axis.y - point_rhs->axis.y) * (point_lhs->axis.y - point_rhs->axis.y)));
}

EGWsingle egwPntAngleFrmd2i(const egwPoint2i* point_lhs, const egwPoint2i* point_rhs) {
    return egwArcTanf((EGWsingle)(point_lhs->axis.y - point_rhs->axis.y) / (EGWsingle)(point_lhs->axis.x - point_rhs->axis.x));
}

egwArea2i* egwPntArea2i(const egwPoint2i* point_fr, const egwPoint2i* point_to, egwArea2i* area_out) {
    area_out->origin.axis.x = (point_fr->axis.x <= point_to->axis.x ? point_fr->axis.x : point_to->axis.x);
    area_out->origin.axis.y = (point_fr->axis.y <= point_to->axis.y ? point_fr->axis.y : point_to->axis.y);
    area_out->dimension.span.width = (EGWuint16)egwAbsi((EGWint)(point_to->axis.x - point_fr->axis.x));
    area_out->dimension.span.height = (EGWuint16)egwAbsi((EGWint)(point_to->axis.y - point_fr->axis.y));
    
    return area_out;
}

egwSpan2i* egwPntSpan2i(const egwPoint2i* point_fr, const egwPoint2i* point_to, egwSpan2i* span_out) {
    span_out->origin.axis.x = point_fr->axis.x;
    span_out->origin.axis.y = point_fr->axis.y;
    span_out->extents.axis.x = (point_to->axis.x - point_fr->axis.x);
    span_out->extents.axis.y = (point_to->axis.y - point_fr->axis.y);
    
    return span_out;
}

egwSurface* egwSrfcAlloc(egwSurface* surface_out, EGWuint32 format, EGWuint16 width, EGWuint16 height, EGWuint16 packingB) {
    if(surface_out && width > 0 && height > 0 &&
       !(format & (EGW_SURFACE_FRMT_EXPLT | EGW_SURFACE_FRMT_EXCMPRSD))) { // not handling palletes or compressed
        EGWuint bpp = (EGWuint)(format & EGW_SURFACE_FRMT_EXBPP);
        
        surface_out->format = format;
        surface_out->size.span.width = width;
        surface_out->size.span.height = height;
        surface_out->pitch = (EGWuint32)((bpp * (EGWuint)surface_out->size.span.width) >> 3);
        if(packingB > 1)
            surface_out->pitch = egwRoundUpMultipleui32(surface_out->pitch, packingB);
        
        if(!(surface_out->data = (EGWbyte*)malloc((size_t)surface_out->pitch * (size_t)surface_out->size.span.height)))
            return NULL;
        
        return surface_out;
    }
    
    return NULL;
}

egwSurface* egwSrfcCopy(const egwSurface* surface_in, egwSurface* surface_out) {
    if(surface_in && surface_in->data && surface_out &&
       !(surface_in->format & (EGW_SURFACE_FRMT_EXPLT | EGW_SURFACE_FRMT_EXCMPRSD))) { // not handling palletes or compressed
        surface_out->format = surface_in->format;
        surface_out->size.span.width = surface_in->size.span.width;
        surface_out->size.span.height = surface_in->size.span.height;
        surface_out->pitch = surface_in->pitch;
        
        if(!(surface_out->data = (EGWbyte*)malloc((size_t)surface_out->pitch * (size_t)surface_out->size.span.height)))
            return NULL;
        
        memcpy((void*)surface_out->data, (const void*)surface_in->data, (size_t)surface_in->pitch * (size_t)surface_in->size.span.height);
        
        return surface_out;
    }
    
    return NULL;
}

egwSurface* egwSrfcFree(egwSurface* surface_inout) {
    if(surface_inout->data)
        free((void*)surface_inout->data);
    memset((void*)surface_inout, 0, sizeof(egwSurface));
    
    return surface_inout;
}

egwSurface* egwSrfcResizeHalf(egwSurface* surface_inout) {
    if(surface_inout->data && (surface_inout->size.span.width > 1 || surface_inout->size.span.height > 1)) {
        EGWuint row, col;
        EGWbyte* cAdr = NULL;
        EGWbyte* lAdr = NULL;
        EGWint dirCount = 0;
        EGWuintptr cScanline = 0, lScanline = 0;
        EGWuint16 lWidth = surface_inout->size.span.width, lHeight = surface_inout->size.span.height, lPitch = surface_inout->pitch;
        EGWuint Bpp = (surface_inout->format & EGW_SURFACE_FRMT_EXBPP) >> 3;
        
        lWidth = surface_inout->size.span.width; surface_inout->size.span.width >>= 1;
        if(surface_inout->size.span.width < 1)
            surface_inout->size.span.width = 1;
        else {
            lPitch = surface_inout->pitch; surface_inout->pitch >>= 1;
        }
        
        lHeight = surface_inout->size.span.height; surface_inout->size.span.height >>= 1;
        if(surface_inout->size.span.height < 1)
            surface_inout->size.span.height = 1;
        
        cScanline = lScanline = (EGWuintptr)(surface_inout->data);
        
        switch(surface_inout->format & EGW_SURFACE_FRMT_EXKIND) {
            case EGW_SURFACE_FRMT_GS8: {
                egwColorGS cColor; EGWint iColor[1];
                
                for(row = 0; row < (EGWuint)(surface_inout->size.span.height); ++row) {
                    cAdr = (EGWbyte*)cScanline;
                    lAdr = (EGWbyte*)lScanline;
                    
                    for(col = 0; col < (EGWuint)(surface_inout->size.span.width); ++col) {
                        egwPxlReadGSb(surface_inout->format, (EGWbyte*)((EGWuintptr)lAdr), &cColor);
                        iColor[0] = (EGWint)cColor.channel.l;
                        dirCount = 1;
                        if(lWidth > 1 && ((col << 1) + 1) < lWidth) {
                            egwPxlReadGSb(surface_inout->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)Bpp), &cColor);
                            iColor[0] += (EGWint)cColor.channel.l;
                            ++dirCount;
                        }
                        if(lHeight > 1 && ((row << 1) + 1) < lHeight) {
                            egwPxlReadGSb(surface_inout->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)lPitch), &cColor);
                            iColor[0] += (EGWint)cColor.channel.l;
                            ++dirCount;
                        }
                        if(lWidth > 1 && ((col << 1) + 1) < lWidth && lHeight > 1 && ((row << 1) + 1) < lHeight) {
                            egwPxlReadGSb(surface_inout->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)lPitch + (EGWuintptr)Bpp), &cColor);
                            iColor[0] += (EGWint)cColor.channel.l;
                            ++dirCount;
                        }
                        
                        cColor.channel.l = (EGWbyte)egwClamp0255i(iColor[0] / dirCount);
                        egwPxlWriteGSb(surface_inout->format, &cColor, (EGWbyte*)cAdr);
                        
                        cAdr = (EGWbyte*)((EGWuintptr)cAdr + (EGWuintptr)Bpp);
                        lAdr = (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)(Bpp << 1));
                    }
                    
                    cScanline += (EGWuintptr)surface_inout->pitch;
                    lScanline += ((EGWuintptr)lPitch + (EGWuintptr)lPitch);
                }
            } break;
                
            case EGW_SURFACE_FRMT_GS8A8: {
                egwColorGSA cColor; EGWint iColor[2];
                
                for(row = 0; row < (EGWuint)(surface_inout->size.span.height); ++row) {
                    cAdr = (EGWbyte*)cScanline;
                    lAdr = (EGWbyte*)lScanline;
                    
                    for(col = 0; col < (EGWuint)(surface_inout->size.span.width); ++col) {
                        egwPxlReadGSAb(surface_inout->format, (EGWbyte*)((EGWuintptr)lAdr), &cColor);
                        iColor[0] = ((EGWint)cColor.channel.l * (EGWint)cColor.channel.a);
                        iColor[1] = (EGWint)cColor.channel.a;
                        dirCount = 1;
                        if(lWidth > 1 && ((col << 1) + 1) < lWidth) {
                            egwPxlReadGSAb(surface_inout->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)Bpp), &cColor);
                            iColor[0] += ((EGWint)cColor.channel.l * (EGWint)cColor.channel.a);
                            iColor[1] += (EGWint)cColor.channel.a;
                            ++dirCount;
                        }
                        if(lHeight > 1 && ((row << 1) + 1) < lHeight) {
                            egwPxlReadGSAb(surface_inout->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)lPitch), &cColor);
                            iColor[0] += ((EGWint)cColor.channel.l * (EGWint)cColor.channel.a);
                            iColor[1] += (EGWint)cColor.channel.a;
                            ++dirCount;
                        }
                        if(lWidth > 1 && ((col << 1) + 1) < lWidth && lHeight > 1 && ((row << 1) + 1) < lHeight) {
                            egwPxlReadGSAb(surface_inout->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)lPitch + (EGWuintptr)Bpp), &cColor);
                            iColor[0] += ((EGWint)cColor.channel.l * (EGWint)cColor.channel.a);
                            iColor[1] += (EGWint)cColor.channel.a;
                            ++dirCount;
                        }
                        
                        cColor.channel.l = (EGWbyte)(iColor[1] ? egwClamp0255i(iColor[0] / iColor[1]) : 0);
                        cColor.channel.a = (EGWbyte)egwClamp0255i(iColor[1] / dirCount);
                        egwPxlWriteGSAb(surface_inout->format, &cColor, (EGWbyte*)cAdr);
                        
                        cAdr = (EGWbyte*)((EGWuintptr)cAdr + (EGWuintptr)Bpp);
                        lAdr = (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)(Bpp << 1));
                    }
                    
                    cScanline += (EGWuintptr)surface_inout->pitch;
                    lScanline += ((EGWuintptr)lPitch + (EGWuintptr)lPitch);
                }
            } break;
                
            case EGW_SURFACE_FRMT_R5G6B5:
            case EGW_SURFACE_FRMT_R8G8B8: {
                egwColorRGB cColor; EGWint iColor[3];
                
                for(row = 0; row < (EGWuint)(surface_inout->size.span.height); ++row) {
                    cAdr = (EGWbyte*)cScanline;
                    lAdr = (EGWbyte*)lScanline;
                    
                    for(col = 0; col < (EGWuint)(surface_inout->size.span.width); ++col) {
                        egwPxlReadRGBb(surface_inout->format, (EGWbyte*)((EGWuintptr)lAdr), &cColor);
                        iColor[0] = (EGWint)cColor.channel.r;
                        iColor[1] = (EGWint)cColor.channel.g;
                        iColor[2] = (EGWint)cColor.channel.b;
                        dirCount = 1;
                        if(lWidth > 1 && ((col << 1) + 1) < lWidth) {
                            egwPxlReadRGBb(surface_inout->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)Bpp), &cColor);
                            iColor[0] += (EGWint)cColor.channel.r;
                            iColor[1] += (EGWint)cColor.channel.g;
                            iColor[2] += (EGWint)cColor.channel.b;
                            ++dirCount;
                        }
                        if(lHeight > 1 && ((row << 1) + 1) < lHeight) {
                            egwPxlReadRGBb(surface_inout->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)lPitch), &cColor);
                            iColor[0] += (EGWint)cColor.channel.r;
                            iColor[1] += (EGWint)cColor.channel.g;
                            iColor[2] += (EGWint)cColor.channel.b;
                            ++dirCount;
                        }
                        if(lWidth > 1 && ((col << 1) + 1) < lWidth && lHeight > 1 && ((row << 1) + 1) < lHeight) {
                            egwPxlReadRGBb(surface_inout->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)lPitch + (EGWuintptr)Bpp), &cColor);
                            iColor[0] += (EGWint)cColor.channel.r;
                            iColor[1] += (EGWint)cColor.channel.g;
                            iColor[2] += (EGWint)cColor.channel.b;
                            ++dirCount;
                        }
                        
                        cColor.channel.r = (EGWbyte)egwClamp0255i(iColor[0] / dirCount);
                        cColor.channel.g = (EGWbyte)egwClamp0255i(iColor[1] / dirCount);
                        cColor.channel.b = (EGWbyte)egwClamp0255i(iColor[2] / dirCount);
                        egwPxlWriteRGBb(surface_inout->format, &cColor, (EGWbyte*)cAdr);
                        
                        cAdr = (EGWbyte*)((EGWuintptr)cAdr + (EGWuintptr)Bpp);
                        lAdr = (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)(Bpp << 1));
                    }
                    
                    cScanline += (EGWuintptr)surface_inout->pitch;
                    lScanline += ((EGWuintptr)lPitch + (EGWuintptr)lPitch);
                }
            } break;
                
            case EGW_SURFACE_FRMT_R5G5B5A1:
            case EGW_SURFACE_FRMT_R4G4B4A4:
            case EGW_SURFACE_FRMT_R8G8B8A8: {
                egwColorRGBA cColor; EGWint iColor[4];
                
                for(row = 0; row < (EGWuint)(surface_inout->size.span.height); ++row) {
                    cAdr = (EGWbyte*)cScanline;
                    lAdr = (EGWbyte*)lScanline;
                    
                    for(col = 0; col < (EGWuint)(surface_inout->size.span.width); ++col) {
                        egwPxlReadRGBAb(surface_inout->format, (EGWbyte*)((EGWuintptr)lAdr), &cColor);
                        iColor[0] = ((EGWint)cColor.channel.r * (EGWint)cColor.channel.a);
                        iColor[1] = ((EGWint)cColor.channel.g * (EGWint)cColor.channel.a);
                        iColor[2] = ((EGWint)cColor.channel.b * (EGWint)cColor.channel.a);
                        iColor[3] = (EGWint)cColor.channel.a;
                        dirCount = 1;
                        if(lWidth > 1 && ((col << 1) + 1) < lWidth) {
                            egwPxlReadRGBAb(surface_inout->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)Bpp), &cColor);
                            iColor[0] += ((EGWint)cColor.channel.r * (EGWint)cColor.channel.a);
                            iColor[1] += ((EGWint)cColor.channel.g * (EGWint)cColor.channel.a);
                            iColor[2] += ((EGWint)cColor.channel.b * (EGWint)cColor.channel.a);
                            iColor[3] += (EGWint)cColor.channel.a;
                            ++dirCount;
                        }
                        if(lHeight > 1 && ((row << 1) + 1) < lHeight) {
                            egwPxlReadRGBAb(surface_inout->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)lPitch), &cColor);
                            iColor[0] += ((EGWint)cColor.channel.r * (EGWint)cColor.channel.a);
                            iColor[1] += ((EGWint)cColor.channel.g * (EGWint)cColor.channel.a);
                            iColor[2] += ((EGWint)cColor.channel.b * (EGWint)cColor.channel.a);
                            iColor[3] += (EGWint)cColor.channel.a;
                            ++dirCount;
                        }
                        if(lWidth > 1 && ((col << 1) + 1) < lWidth && lHeight > 1 && ((row << 1) + 1) < lHeight) {
                            egwPxlReadRGBAb(surface_inout->format, (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)lPitch + (EGWuintptr)Bpp), &cColor);
                            iColor[0] += ((EGWint)cColor.channel.r * (EGWint)cColor.channel.a);
                            iColor[1] += ((EGWint)cColor.channel.g * (EGWint)cColor.channel.a);
                            iColor[2] += ((EGWint)cColor.channel.b * (EGWint)cColor.channel.a);
                            iColor[3] += (EGWint)cColor.channel.a;
                            ++dirCount;
                        }
                        
                        cColor.channel.r = (EGWbyte)(iColor[3] ? egwClamp0255i(iColor[0] / iColor[3]) : 0);
                        cColor.channel.g = (EGWbyte)(iColor[3] ? egwClamp0255i(iColor[1] / iColor[3]) : 0);
                        cColor.channel.b = (EGWbyte)(iColor[3] ? egwClamp0255i(iColor[2] / iColor[3]) : 0);
                        cColor.channel.a = (EGWbyte)egwClamp0255i(iColor[3] / dirCount);
                        egwPxlWriteRGBAb(surface_inout->format, &cColor, (EGWbyte*)cAdr);
                        
                        cAdr = (EGWbyte*)((EGWuintptr)cAdr + (EGWuintptr)Bpp);
                        lAdr = (EGWbyte*)((EGWuintptr)lAdr + (EGWuintptr)(Bpp << 1));
                    }
                    
                    cScanline += (EGWuintptr)surface_inout->pitch;
                    lScanline += ((EGWuintptr)lPitch + (EGWuintptr)lPitch);
                }
            } break;
        }
    }
    
    return surface_inout;
}

egwSurface* egwSrfcFlipVert(egwSurface* surface_inout) {
    EGWuintptr lScanline = (EGWuintptr)surface_inout->data;
    EGWuintptr cScanline = (EGWuintptr)surface_inout->data + ((EGWuintptr)(surface_inout->size.span.height - 1) * (EGWuintptr)surface_inout->pitch);
    EGWuint Bpp = (surface_inout->format & EGW_SURFACE_FRMT_EXBPP) >> 3;
    EGWbyte* lhsAdr = NULL;
    EGWbyte* rhsAdr = NULL;
    EGWbyte temp;    
    
    EGWuint row = surface_inout->size.span.height >> 1;
    while(row--) {
        lhsAdr = (EGWbyte*)lScanline;
        rhsAdr = (EGWbyte*)cScanline;
        
        EGWuint col = surface_inout->size.span.width;
        while(col--) {
            
            EGWuint bytes = Bpp;
            while(bytes--) {
                temp = *lhsAdr;
                *lhsAdr = *rhsAdr;
                *rhsAdr = temp;
                
                lhsAdr = (EGWbyte*)((EGWuintptr)lhsAdr + 1);
                rhsAdr = (EGWbyte*)((EGWuintptr)rhsAdr + 1);
            }
        }
        
        lScanline += (EGWuintptr)surface_inout->pitch;
        cScanline -= (EGWuintptr)surface_inout->pitch;
    }
    
    return surface_inout;
}

egwSurface* egwSrfcFlipHorz(egwSurface* surface_inout) {
    EGWbyte* lhsAdr = NULL;
    EGWbyte* rhsAdr = NULL;
    EGWbyte temp;
    EGWuintptr cScanline = (EGWuintptr)surface_inout->data;
    EGWuint Bpp = (surface_inout->format & EGW_SURFACE_FRMT_EXBPP) >> 3;
    
    EGWuint row = surface_inout->size.span.height;
    while(row--) {
        lhsAdr = (EGWbyte*)cScanline;
        rhsAdr = (EGWbyte*)(cScanline + ((EGWuintptr)(surface_inout->size.span.width - 1) * (EGWuintptr)Bpp));
        
        EGWuint col = surface_inout->size.span.width >> 1;
        while(col--) {
            
            EGWuint bytes = Bpp;
            while(bytes--) {
                temp = *lhsAdr;
                *lhsAdr = *rhsAdr;
                *rhsAdr = temp;
                
                lhsAdr = (EGWbyte*)((EGWuintptr)lhsAdr + 1);
                rhsAdr = (EGWbyte*)((EGWuintptr)rhsAdr + 1);
            }
            
            rhsAdr = (EGWbyte*)((EGWuintptr)rhsAdr - (EGWuintptr)(Bpp << 1));
        }
        
        cScanline += (EGWuintptr)surface_inout->pitch;
    }
    
    return surface_inout;
}

egwSurface* egwSrfcSwapRB(egwSurface* surface_inout) {
    if(surface_inout->format & EGW_SURFACE_FRMT_EXRGB) {
        EGWbyte* adr = NULL;
        egwColorRGBA pixel;
        EGWuint8 temp;
        EGWuintptr cScanline = (EGWuintptr)surface_inout->data;
        EGWuint Bpp = (surface_inout->format & EGW_SURFACE_FRMT_EXBPP) >> 3;
        
        EGWuint row = surface_inout->size.span.height;
        while(row--) {
            adr = (EGWbyte*)cScanline;
            
            EGWuint col = surface_inout->size.span.width;
            while(col--) {
                egwPxlReadRGBAb(surface_inout->format, adr, &pixel);
                temp = pixel.channel.r;
                pixel.channel.r = pixel.channel.b;
                pixel.channel.b = temp;
                egwPxlWriteRGBAb(surface_inout->format, &pixel, adr);
                
                adr = (EGWbyte*)((EGWuintptr)adr + (EGWuintptr)Bpp);
            }
            
            cScanline += (EGWuintptr)surface_inout->pitch;
        }
        
        return surface_inout;
    }
    
    return NULL;
}

egwSurface* egwSrfcInvertGS(egwSurface* surface_inout) {
    if(surface_inout->format & EGW_SURFACE_FRMT_EXGS) {
        EGWbyte* adr = NULL;
        egwColorGSA pixel;
        EGWuintptr cScanline = (EGWuintptr)surface_inout->data;
        EGWuint Bpp = (surface_inout->format & EGW_SURFACE_FRMT_EXBPP) >> 3;
        
        EGWuint row = surface_inout->size.span.height;
        while(row--) {
            adr = (EGWbyte*)cScanline;
            
            EGWuint col = surface_inout->size.span.width;
            while(col--) {
                egwPxlReadGSAb(surface_inout->format, adr, &pixel);
                pixel.channel.l = 255 - pixel.channel.l;
                egwPxlWriteGSAb(surface_inout->format, &pixel, adr);
                
                adr = (EGWbyte*)((EGWuintptr)adr + (EGWuintptr)Bpp);
            }
            
            cScanline += (EGWuintptr)surface_inout->pitch;
        }
        
        return surface_inout;
    }
    
    return NULL;
}

egwSurface* egwSrfcInvertAC(egwSurface* surface_inout) {
    if(surface_inout->format & EGW_SURFACE_FRMT_EXAC) {
        EGWbyte* adr = NULL;
        EGWuintptr cScanline = (EGWuintptr)surface_inout->data;
        EGWuint Bpp = (surface_inout->format & EGW_SURFACE_FRMT_EXBPP) >> 3;
        
        if(surface_inout->format & EGW_SURFACE_FRMT_EXRGB) {
            egwColorRGBA pixel;
            
            EGWuint row = surface_inout->size.span.height;
            while(row--) {
                adr = (EGWbyte*)cScanline;
                
                EGWuint col = surface_inout->size.span.width;
                while(col--) {
                    egwPxlReadRGBAb(surface_inout->format, adr, &pixel);
                    pixel.channel.a = 255 - pixel.channel.a;
                    egwPxlWriteRGBAb(surface_inout->format, &pixel, adr);
                    
                    adr = (EGWbyte*)((EGWuintptr)adr + (EGWuintptr)Bpp);
                }
                
                cScanline += (EGWuintptr)surface_inout->pitch;
            }
        } else { // GS
            egwColorGSA pixel;
            
            EGWuint row = surface_inout->size.span.height;
            while(row--) {
                adr = (EGWbyte*)cScanline;
                
                EGWuint col = surface_inout->size.span.width;
                while(col--) {
                    egwPxlReadGSAb(surface_inout->format, adr, &pixel);
                    pixel.channel.a = 255 - pixel.channel.a;
                    egwPxlWriteGSAb(surface_inout->format, &pixel, adr);
                    
                    adr = (EGWbyte*)((EGWuintptr)adr + (EGWuintptr)Bpp);
                }
                
                cScanline += (EGWuintptr)surface_inout->pitch;
            }
        }
        
        return surface_inout;
    }
    
    return NULL;
}

egwSurface* egwSrfcCyanTT(egwSurface* surface_inout) {
    if((surface_inout->format & EGW_SURFACE_FRMT_EXRGB) && (surface_inout->format & EGW_SURFACE_FRMT_EXAC)) {
        EGWbyte* adr = NULL;
        egwColorRGBA pixel;
        EGWuintptr cScanline = (EGWuintptr)surface_inout->data;
        EGWuint Bpp = (surface_inout->format & EGW_SURFACE_FRMT_EXBPP) >> 3;
        
        EGWuint row = surface_inout->size.span.height;
        while(row--) {
            adr = (EGWbyte*)cScanline;
            
            EGWuint col = surface_inout->size.span.width;
            while(col--) {
                egwPxlReadRGBAb(surface_inout->format, adr, &pixel);
                if(pixel.channel.r == 0 && pixel.channel.g == 255 && pixel.channel.b == 255 && pixel.channel.a != 0) {
                    pixel.channel.a = 0;
                    egwPxlWriteRGBAb(surface_inout->format, &pixel, adr);
                }
                
                adr = (EGWbyte*)((EGWuintptr)adr + (EGWuintptr)Bpp);
            }
            
            cScanline += (EGWuintptr)surface_inout->pitch;
        }
        
        return surface_inout;
    }
    
    return NULL;
}

egwSurface* egwSrfcMagentaTT(egwSurface* surface_inout) {
    if((surface_inout->format & EGW_SURFACE_FRMT_EXRGB) && (surface_inout->format & EGW_SURFACE_FRMT_EXAC)) {
        EGWbyte* adr = NULL;
        egwColorRGBA pixel;
        EGWuintptr cScanline = (EGWuintptr)surface_inout->data;
        EGWuint Bpp = (surface_inout->format & EGW_SURFACE_FRMT_EXBPP) >> 3;
        
        EGWuint row = surface_inout->size.span.height;
        while(row--) {
            adr = (EGWbyte*)cScanline;
            
            EGWuint col = surface_inout->size.span.width;
            while(col--) {
                egwPxlReadRGBAb(surface_inout->format, adr, &pixel);
                if(pixel.channel.r == 255 && pixel.channel.g == 0 && pixel.channel.b == 255 && pixel.channel.a != 0) {
                    pixel.channel.a = 0;
                    egwPxlWriteRGBAb(surface_inout->format, &pixel, adr);
                }
                
                adr = (EGWbyte*)((EGWuintptr)adr + (EGWuintptr)Bpp);
            }
            
            cScanline += (EGWuintptr)surface_inout->pitch;
        }
        
        return surface_inout;
    }
    
    return NULL;
}

egwSurface* egwSrfcOpacityDilate(egwSurface* surface_inout) {
    if((surface_inout->format & EGW_SURFACE_FRMT_EXAC) && egwSrfcMaxAC(surface_inout) > 0) {
        EGWbyte* adr = NULL;
        EGWuintptr cScanline = (EGWuintptr)surface_inout->data;
        EGWuint Bpp = (surface_inout->format & EGW_SURFACE_FRMT_EXBPP) >> 3;
        EGWuint pixelsLeft = (EGWuint)surface_inout->size.span.width * (EGWuint)surface_inout->size.span.height;
        
        EGWuint8* mask = (EGWuint8*)malloc(sizeof(EGWuint8) * (size_t)pixelsLeft);
        
        if(mask) {
            // mask holds direction flags, 0x01 = T, 0x02 = TR, 0x04 = R, 0x08 = BR, 0x10 = B, 0x20 = BL, 0x40 = L, 0x80 = TL
            memset((void*)mask, 0xff, sizeof(EGWuint8) * (size_t)pixelsLeft);
            
            if(surface_inout->format & EGW_SURFACE_FRMT_EXRGB) {
                egwColorRGBA pixel;
                
                // First pass is to reset all fully transparent pixels for accumulation passes, and remove flags from non transparent pixels
                EGWuint8* maskScan = mask;
                EGWuint row = surface_inout->size.span.height;
                while(row--) {
                    adr = (EGWbyte*)cScanline;
                    
                    EGWuint col = surface_inout->size.span.width;
                    while(col--) {
                        egwPxlReadRGBAb(surface_inout->format, adr, &pixel);
                        
                        if(pixel.channel.a == 0) {
                            if(col == (EGWuint)surface_inout->size.span.width-1) // Cannot go left any further
                                *maskScan &= ~(0x20 | 0x40 | 0x80);
                            if(col == 0) // Cannot go right any further
                                *maskScan &= ~(0x02 | 0x04 | 0x08);
                            if(row == (EGWuint)surface_inout->size.span.height-1) // Cannot go up any further
                                *maskScan &= ~(0x01 | 0x02 | 0x80);
                            if(row == 0) // Cannot go down any further
                                *maskScan &= ~(0x08 | 0x10 | 0x20);
                            
                            pixel.channel.r = pixel.channel.g = pixel.channel.b = 0;
                            egwPxlWriteRGBAb(surface_inout->format, &pixel, adr);
                        } else
                            *maskScan = 0x00;
                        
                        if(*maskScan == 0x00)
                            --pixelsLeft;
                        
                        adr = (EGWbyte*)((EGWuintptr)adr + (EGWuintptr)Bpp);
                        ++maskScan;
                    }
                    
                    cScanline += (EGWuintptr)surface_inout->pitch;
                }
                
                // Second pass is to keep on looping until all pixels have been filled
                BOOL atLeastOneMod = YES;
                EGWuint iterLeft = EGW_OPACDLT_MAXITERATIONS;
                while(pixelsLeft && atLeastOneMod && iterLeft--) {
                    atLeastOneMod = NO;
                    cScanline = (EGWuintptr)surface_inout->data;
                    maskScan = mask;
                    row = surface_inout->size.span.height;
                    while(row--) {
                        adr = (EGWbyte*)cScanline;
                        
                        EGWuint col = surface_inout->size.span.width;
                        while(col--) {
                            egwPxlReadRGBAb(surface_inout->format, adr, &pixel);
                            
                            if(*maskScan != 0x00) {
                                BOOL modifiedPixel = NO;
                                
                                if(*maskScan & 0x01) { // Try looking up a pixel
                                    if(*(EGWuint8*)((EGWuintptr)maskScan - (EGWuintptr)surface_inout->size.span.width) == 0x00) {
                                        egwColorRGBA oPixel;
                                        egwPxlReadRGBAb(surface_inout->format, (EGWbyte*)((EGWuintptr)adr - (EGWuintptr)surface_inout->pitch), &oPixel);
                                        
                                        EGWint dirTrvld = ((*maskScan & 0x01) && row<(EGWuint)surface_inout->size.span.height-1 ? 0 : 1) + ((*maskScan & 0x02) && row<(EGWuint)surface_inout->size.span.height-1 && col>0 ? 0 : 1) + ((*maskScan & 0x04) && col>0 ? 0 : 1) + ((*maskScan & 0x08) && row>0 && col>0 ? 0 : 1) + ((*maskScan & 0x10) && row>0 ? 0 : 1) + ((*maskScan & 0x20) && row>0 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x40) && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x80) && row<(EGWuint)surface_inout->size.span.height-1 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1);
                                        pixel.channel.r = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.r * dirTrvld) + (EGWint)oPixel.channel.r + (EGWint)1) / (EGWint)2);
                                        pixel.channel.g = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.g * dirTrvld) + (EGWint)oPixel.channel.g + (EGWint)1) / (EGWint)2);
                                        pixel.channel.b = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.b * dirTrvld) + (EGWint)oPixel.channel.b + (EGWint)1) / (EGWint)2);
                                        
                                        *maskScan &= ~0x01;
                                        modifiedPixel = YES;
                                    }
                                }
                                
                                if(*maskScan & 0x02) { // Try looking up right a pixel
                                    if(*(EGWuint8*)((EGWuintptr)maskScan - (EGWuintptr)surface_inout->size.span.width + (EGWuintptr)1) == 0x00) {
                                        egwColorRGBA oPixel;
                                        egwPxlReadRGBAb(surface_inout->format, (EGWbyte*)((EGWuintptr)adr - (EGWuintptr)surface_inout->pitch + (EGWuintptr)Bpp), &oPixel);
                                        
                                        EGWint dirTrvld = ((*maskScan & 0x01) && row<(EGWuint)surface_inout->size.span.height-1 ? 0 : 1) + ((*maskScan & 0x02) && row<(EGWuint)surface_inout->size.span.height-1 && col>0 ? 0 : 1) + ((*maskScan & 0x04) && col>0 ? 0 : 1) + ((*maskScan & 0x08) && row>0 && col>0 ? 0 : 1) + ((*maskScan & 0x10) && row>0 ? 0 : 1) + ((*maskScan & 0x20) && row>0 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x40) && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x80) && row<(EGWuint)surface_inout->size.span.height-1 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1);
                                        pixel.channel.r = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.r * dirTrvld) + (EGWint)oPixel.channel.r + (EGWint)1) / (EGWint)2);
                                        pixel.channel.g = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.g * dirTrvld) + (EGWint)oPixel.channel.g + (EGWint)1) / (EGWint)2);
                                        pixel.channel.b = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.b * dirTrvld) + (EGWint)oPixel.channel.b + (EGWint)1) / (EGWint)2);
                                        
                                        *maskScan &= ~0x02;
                                        modifiedPixel = YES;
                                    }
                                }
                                
                                if(*maskScan & 0x04) { // Try looking right a pixel
                                    if(*(EGWuint8*)((EGWuintptr)maskScan + (EGWuintptr)1) == 0x00) {
                                        egwColorRGBA oPixel;
                                        egwPxlReadRGBAb(surface_inout->format, (EGWbyte*)((EGWuintptr)adr + (EGWuintptr)Bpp), &oPixel);
                                        
                                        EGWint dirTrvld = ((*maskScan & 0x01) && row<(EGWuint)surface_inout->size.span.height-1 ? 0 : 1) + ((*maskScan & 0x02) && row<(EGWuint)surface_inout->size.span.height-1 && col>0 ? 0 : 1) + ((*maskScan & 0x04) && col>0 ? 0 : 1) + ((*maskScan & 0x08) && row>0 && col>0 ? 0 : 1) + ((*maskScan & 0x10) && row>0 ? 0 : 1) + ((*maskScan & 0x20) && row>0 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x40) && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x80) && row<(EGWuint)surface_inout->size.span.height-1 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1);
                                        pixel.channel.r = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.r * dirTrvld) + (EGWint)oPixel.channel.r + (EGWint)1) / (EGWint)2);
                                        pixel.channel.g = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.g * dirTrvld) + (EGWint)oPixel.channel.g + (EGWint)1) / (EGWint)2);
                                        pixel.channel.b = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.b * dirTrvld) + (EGWint)oPixel.channel.b + (EGWint)1) / (EGWint)2);
                                        
                                        *maskScan &= ~0x04;
                                        modifiedPixel = YES;
                                    }
                                }
                                
                                if(*maskScan & 0x08) { // Try looking down right a pixel
                                    if(*(EGWuint8*)((EGWuintptr)maskScan + (EGWuintptr)surface_inout->size.span.width + (EGWuintptr)1) == 0x00) {
                                        egwColorRGBA oPixel;
                                        egwPxlReadRGBAb(surface_inout->format, (EGWbyte*)((EGWuintptr)adr + (EGWuintptr)surface_inout->pitch + (EGWuintptr)Bpp), &oPixel);
                                        
                                        EGWint dirTrvld = ((*maskScan & 0x01) && row<(EGWuint)surface_inout->size.span.height-1 ? 0 : 1) + ((*maskScan & 0x02) && row<(EGWuint)surface_inout->size.span.height-1 && col>0 ? 0 : 1) + ((*maskScan & 0x04) && col>0 ? 0 : 1) + ((*maskScan & 0x08) && row>0 && col>0 ? 0 : 1) + ((*maskScan & 0x10) && row>0 ? 0 : 1) + ((*maskScan & 0x20) && row>0 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x40) && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x80) && row<(EGWuint)surface_inout->size.span.height-1 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1);
                                        pixel.channel.r = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.r * dirTrvld) + (EGWint)oPixel.channel.r + (EGWint)1) / (EGWint)2);
                                        pixel.channel.g = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.g * dirTrvld) + (EGWint)oPixel.channel.g + (EGWint)1) / (EGWint)2);
                                        pixel.channel.b = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.b * dirTrvld) + (EGWint)oPixel.channel.b + (EGWint)1) / (EGWint)2);
                                        
                                        *maskScan &= ~0x08;
                                        modifiedPixel = YES;
                                    }
                                }
                                
                                if(*maskScan & 0x10) { // Try looking down a pixel
                                    if(*(EGWuint8*)((EGWuintptr)maskScan + (EGWuintptr)surface_inout->size.span.width) == 0x00) {
                                        egwColorRGBA oPixel;
                                        egwPxlReadRGBAb(surface_inout->format, (EGWbyte*)((EGWuintptr)adr + (EGWuintptr)surface_inout->pitch), &oPixel);
                                        
                                        EGWint dirTrvld = ((*maskScan & 0x01) && row<(EGWuint)surface_inout->size.span.height-1 ? 0 : 1) + ((*maskScan & 0x02) && row<(EGWuint)surface_inout->size.span.height-1 && col>0 ? 0 : 1) + ((*maskScan & 0x04) && col>0 ? 0 : 1) + ((*maskScan & 0x08) && row>0 && col>0 ? 0 : 1) + ((*maskScan & 0x10) && row>0 ? 0 : 1) + ((*maskScan & 0x20) && row>0 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x40) && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x80) && row<(EGWuint)surface_inout->size.span.height-1 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1);
                                        pixel.channel.r = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.r * dirTrvld) + (EGWint)oPixel.channel.r + (EGWint)1) / (EGWint)2);
                                        pixel.channel.g = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.g * dirTrvld) + (EGWint)oPixel.channel.g + (EGWint)1) / (EGWint)2);
                                        pixel.channel.b = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.b * dirTrvld) + (EGWint)oPixel.channel.b + (EGWint)1) / (EGWint)2);
                                        
                                        *maskScan &= ~0x10;
                                        modifiedPixel = YES;
                                    }
                                }
                                
                                if(*maskScan & 0x20) { // Try looking down left a pixel
                                    if(*(EGWuint8*)((EGWuintptr)maskScan + (EGWuintptr)surface_inout->size.span.width - (EGWuintptr)1) == 0x00) {
                                        egwColorRGBA oPixel;
                                        egwPxlReadRGBAb(surface_inout->format, (EGWbyte*)((EGWuintptr)adr + (EGWuintptr)surface_inout->pitch - (EGWuintptr)Bpp), &oPixel);
                                        
                                        EGWint dirTrvld = ((*maskScan & 0x01) && row<(EGWuint)surface_inout->size.span.height-1 ? 0 : 1) + ((*maskScan & 0x02) && row<(EGWuint)surface_inout->size.span.height-1 && col>0 ? 0 : 1) + ((*maskScan & 0x04) && col>0 ? 0 : 1) + ((*maskScan & 0x08) && row>0 && col>0 ? 0 : 1) + ((*maskScan & 0x10) && row>0 ? 0 : 1) + ((*maskScan & 0x20) && row>0 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x40) && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x80) && row<(EGWuint)surface_inout->size.span.height-1 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1);
                                        pixel.channel.r = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.r * dirTrvld) + (EGWint)oPixel.channel.r + (EGWint)1) / (EGWint)2);
                                        pixel.channel.g = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.g * dirTrvld) + (EGWint)oPixel.channel.g + (EGWint)1) / (EGWint)2);
                                        pixel.channel.b = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.b * dirTrvld) + (EGWint)oPixel.channel.b + (EGWint)1) / (EGWint)2);
                                        
                                        *maskScan &= ~0x20;
                                        modifiedPixel = YES;
                                    }
                                }
                                
                                if(*maskScan & 0x40) { // Try looking left a pixel
                                    if(*(EGWuint8*)((EGWuintptr)maskScan - (EGWuintptr)1) == 0x00) {
                                        egwColorRGBA oPixel;
                                        egwPxlReadRGBAb(surface_inout->format, (EGWbyte*)((EGWuintptr)adr - (EGWuintptr)Bpp), &oPixel);
                                        
                                        EGWint dirTrvld = ((*maskScan & 0x01) && row<(EGWuint)surface_inout->size.span.height-1 ? 0 : 1) + ((*maskScan & 0x02) && row<(EGWuint)surface_inout->size.span.height-1 && col>0 ? 0 : 1) + ((*maskScan & 0x04) && col>0 ? 0 : 1) + ((*maskScan & 0x08) && row>0 && col>0 ? 0 : 1) + ((*maskScan & 0x10) && row>0 ? 0 : 1) + ((*maskScan & 0x20) && row>0 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x40) && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x80) && row<(EGWuint)surface_inout->size.span.height-1 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1);
                                        pixel.channel.r = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.r * dirTrvld) + (EGWint)oPixel.channel.r + (EGWint)1) / (EGWint)2);
                                        pixel.channel.g = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.g * dirTrvld) + (EGWint)oPixel.channel.g + (EGWint)1) / (EGWint)2);
                                        pixel.channel.b = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.b * dirTrvld) + (EGWint)oPixel.channel.b + (EGWint)1) / (EGWint)2);
                                        
                                        *maskScan &= ~0x40;
                                        modifiedPixel = YES;
                                    }
                                }
                                
                                if(*maskScan & 0x80) { // Try looking up left a pixel
                                    if(*(EGWuint8*)((EGWuintptr)maskScan - (EGWuintptr)surface_inout->size.span.width - (EGWuintptr)1) == 0x00) {
                                        egwColorRGBA oPixel;
                                        egwPxlReadRGBAb(surface_inout->format, (EGWbyte*)((EGWuintptr)adr - (EGWuintptr)surface_inout->pitch - (EGWuintptr)Bpp), &oPixel);
                                        
                                        EGWint dirTrvld = ((*maskScan & 0x01) && row<(EGWuint)surface_inout->size.span.height-1 ? 0 : 1) + ((*maskScan & 0x02) && row<(EGWuint)surface_inout->size.span.height-1 && col>0 ? 0 : 1) + ((*maskScan & 0x04) && col>0 ? 0 : 1) + ((*maskScan & 0x08) && row>0 && col>0 ? 0 : 1) + ((*maskScan & 0x10) && row>0 ? 0 : 1) + ((*maskScan & 0x20) && row>0 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x40) && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x80) && row<(EGWuint)surface_inout->size.span.height-1 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1);
                                        pixel.channel.r = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.r * dirTrvld) + (EGWint)oPixel.channel.r + (EGWint)1) / (EGWint)2);
                                        pixel.channel.g = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.g * dirTrvld) + (EGWint)oPixel.channel.g + (EGWint)1) / (EGWint)2);
                                        pixel.channel.b = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.b * dirTrvld) + (EGWint)oPixel.channel.b + (EGWint)1) / (EGWint)2);
                                        
                                        *maskScan &= ~0x80;
                                        modifiedPixel = YES;
                                    }
                                }
                                
                                if(modifiedPixel) {
                                    egwPxlWriteRGBAb(surface_inout->format, &pixel, adr);
                                    atLeastOneMod = YES;
                                }
                                
                                if(*maskScan == 0x00)
                                    --pixelsLeft;
                            }
                            
                            adr = (EGWbyte*)((EGWuintptr)adr + (EGWuintptr)Bpp);
                            ++maskScan;
                        }
                        
                        cScanline += (EGWuintptr)surface_inout->pitch;
                    }
                    
                    // Follow up is to set all intermediate mask scans to finished (since that's all the data that can be gathered)
                    if(!atLeastOneMod) {
                        maskScan = mask;
                        row = surface_inout->size.span.height;
                        while(row--) {
                            EGWuint col = surface_inout->size.span.width;
                            while(col--) {
                                if(*maskScan != 0xff && *maskScan != 0x00) {
                                    *maskScan = 0x00;
                                    --pixelsLeft;
                                    atLeastOneMod = YES;
                                }
                                
                                ++maskScan;
                            }
                        }
                    }
                }
            } else { // GS
                egwColorGSA pixel;
                
                // First pass is to reset all fully transparent pixels for accumulation passes, and remove flags from non transparent pixels
                EGWuint8* maskScan = mask;
                EGWuint row = surface_inout->size.span.height;
                while(row--) {
                    adr = (EGWbyte*)cScanline;
                    
                    EGWuint col = surface_inout->size.span.width;
                    while(col--) {
                        egwPxlReadGSAb(surface_inout->format, adr, &pixel);
                        
                        if(pixel.channel.a == 0) {
                            if(col == (EGWuint)surface_inout->size.span.width-1) // Cannot go left any further
                                *maskScan &= ~(0x20 | 0x40 | 0x80);
                            if(col == 0) // Cannot go right any further
                                *maskScan &= ~(0x02 | 0x04 | 0x08);
                            if(row == (EGWuint)surface_inout->size.span.height-1) // Cannot go up any further
                                *maskScan &= ~(0x01 | 0x02 | 0x80);
                            if(row == 0) // Cannot go down any further
                                *maskScan &= ~(0x08 | 0x10 | 0x20);
                            
                            pixel.channel.l = 0;
                            egwPxlWriteGSAb(surface_inout->format, &pixel, adr);
                        } else
                            *maskScan = 0x00;
                        
                        if(*maskScan == 0x00)
                            --pixelsLeft;
                        
                        adr = (EGWbyte*)((EGWuintptr)adr + (EGWuintptr)Bpp);
                        ++maskScan;
                    }
                    
                    cScanline += (EGWuintptr)surface_inout->pitch;
                }
                
                // Second pass is to keep on looping until all pixels have been filled
                BOOL atLeastOneMod = YES;
                EGWuint iterLeft = EGW_OPACDLT_MAXITERATIONS;
                while(pixelsLeft && atLeastOneMod && iterLeft--) {
                    atLeastOneMod = NO;
                    cScanline = (EGWuintptr)surface_inout->data;
                    maskScan = mask;
                    row = surface_inout->size.span.height;
                    while(row--) {
                        adr = (EGWbyte*)cScanline;
                        
                        EGWuint col = surface_inout->size.span.width;
                        while(col--) {
                            egwPxlReadGSAb(surface_inout->format, adr, &pixel);
                            
                            if(*maskScan != 0x00) {
                                BOOL modifiedPixel = NO;
                                
                                if(*maskScan & 0x01) { // Try looking up a pixel
                                    if(*(EGWuint8*)((EGWuintptr)maskScan - (EGWuintptr)surface_inout->size.span.width) == 0x00) {
                                        egwColorGSA oPixel;
                                        egwPxlReadGSAb(surface_inout->format, (EGWbyte*)((EGWuintptr)adr - (EGWuintptr)surface_inout->pitch), &oPixel);
                                        
                                        EGWint dirTrvld = ((*maskScan & 0x01) && row<(EGWuint)surface_inout->size.span.height-1 ? 0 : 1) + ((*maskScan & 0x02) && row<(EGWuint)surface_inout->size.span.height-1 && col>0 ? 0 : 1) + ((*maskScan & 0x04) && col>0 ? 0 : 1) + ((*maskScan & 0x08) && row>0 && col>0 ? 0 : 1) + ((*maskScan & 0x10) && row>0 ? 0 : 1) + ((*maskScan & 0x20) && row>0 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x40) && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x80) && row<(EGWuint)surface_inout->size.span.height-1 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1);
                                        pixel.channel.l = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.l * dirTrvld) + (EGWint)oPixel.channel.l + (EGWint)1) / (EGWint)2);
                                        
                                        *maskScan &= ~0x01;
                                        modifiedPixel = YES;
                                    }
                                }
                                
                                if(*maskScan & 0x02) { // Try looking up right a pixel
                                    if(*(EGWuint8*)((EGWuintptr)maskScan - (EGWuintptr)surface_inout->size.span.width + (EGWuintptr)1) == 0x00) {
                                        egwColorGSA oPixel;
                                        egwPxlReadGSAb(surface_inout->format, (EGWbyte*)((EGWuintptr)adr - (EGWuintptr)surface_inout->pitch + (EGWuintptr)Bpp), &oPixel);
                                        
                                        EGWint dirTrvld = ((*maskScan & 0x01) && row<(EGWuint)surface_inout->size.span.height-1 ? 0 : 1) + ((*maskScan & 0x02) && row<(EGWuint)surface_inout->size.span.height-1 && col>0 ? 0 : 1) + ((*maskScan & 0x04) && col>0 ? 0 : 1) + ((*maskScan & 0x08) && row>0 && col>0 ? 0 : 1) + ((*maskScan & 0x10) && row>0 ? 0 : 1) + ((*maskScan & 0x20) && row>0 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x40) && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x80) && row<(EGWuint)surface_inout->size.span.height-1 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1);
                                        pixel.channel.l = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.l * dirTrvld) + (EGWint)oPixel.channel.l + (EGWint)1) / (EGWint)2);
                                        
                                        *maskScan &= ~0x02;
                                        modifiedPixel = YES;
                                    }
                                }
                                
                                if(*maskScan & 0x04) { // Try looking right a pixel
                                    if(*(EGWuint8*)((EGWuintptr)maskScan + (EGWuintptr)1) == 0x00) {
                                        egwColorGSA oPixel;
                                        egwPxlReadGSAb(surface_inout->format, (EGWbyte*)((EGWuintptr)adr + (EGWuintptr)Bpp), &oPixel);
                                        
                                        EGWint dirTrvld = ((*maskScan & 0x01) && row<(EGWuint)surface_inout->size.span.height-1 ? 0 : 1) + ((*maskScan & 0x02) && row<(EGWuint)surface_inout->size.span.height-1 && col>0 ? 0 : 1) + ((*maskScan & 0x04) && col>0 ? 0 : 1) + ((*maskScan & 0x08) && row>0 && col>0 ? 0 : 1) + ((*maskScan & 0x10) && row>0 ? 0 : 1) + ((*maskScan & 0x20) && row>0 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x40) && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x80) && row<(EGWuint)surface_inout->size.span.height-1 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1);
                                        pixel.channel.l = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.l * dirTrvld) + (EGWint)oPixel.channel.l + (EGWint)1) / (EGWint)2);
                                        
                                        *maskScan &= ~0x04;
                                        modifiedPixel = YES;
                                    }
                                }
                                
                                if(*maskScan & 0x08) { // Try looking down right a pixel
                                    if(*(EGWuint8*)((EGWuintptr)maskScan + (EGWuintptr)surface_inout->size.span.width + (EGWuintptr)1) == 0x00) {
                                        egwColorGSA oPixel;
                                        egwPxlReadGSAb(surface_inout->format, (EGWbyte*)((EGWuintptr)adr + (EGWuintptr)surface_inout->pitch + (EGWuintptr)Bpp), &oPixel);
                                        
                                        EGWint dirTrvld = ((*maskScan & 0x01) && row<(EGWuint)surface_inout->size.span.height-1 ? 0 : 1) + ((*maskScan & 0x02) && row<(EGWuint)surface_inout->size.span.height-1 && col>0 ? 0 : 1) + ((*maskScan & 0x04) && col>0 ? 0 : 1) + ((*maskScan & 0x08) && row>0 && col>0 ? 0 : 1) + ((*maskScan & 0x10) && row>0 ? 0 : 1) + ((*maskScan & 0x20) && row>0 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x40) && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x80) && row<(EGWuint)surface_inout->size.span.height-1 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1);
                                        pixel.channel.l = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.l * dirTrvld) + (EGWint)oPixel.channel.l + (EGWint)1) / (EGWint)2);
                                        
                                        *maskScan &= ~0x08;
                                        modifiedPixel = YES;
                                    }
                                }
                                
                                if(*maskScan & 0x10) { // Try looking down a pixel
                                    if(*(EGWuint8*)((EGWuintptr)maskScan + (EGWuintptr)surface_inout->size.span.width) == 0x00) {
                                        egwColorGSA oPixel;
                                        egwPxlReadGSAb(surface_inout->format, (EGWbyte*)((EGWuintptr)adr + (EGWuintptr)surface_inout->pitch), &oPixel);
                                        
                                        EGWint dirTrvld = ((*maskScan & 0x01) && row<(EGWuint)surface_inout->size.span.height-1 ? 0 : 1) + ((*maskScan & 0x02) && row<(EGWuint)surface_inout->size.span.height-1 && col>0 ? 0 : 1) + ((*maskScan & 0x04) && col>0 ? 0 : 1) + ((*maskScan & 0x08) && row>0 && col>0 ? 0 : 1) + ((*maskScan & 0x10) && row>0 ? 0 : 1) + ((*maskScan & 0x20) && row>0 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x40) && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x80) && row<(EGWuint)surface_inout->size.span.height-1 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1);
                                        pixel.channel.l = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.l * dirTrvld) + (EGWint)oPixel.channel.l + (EGWint)1) / (EGWint)2);
                                        
                                        *maskScan &= ~0x10;
                                        modifiedPixel = YES;
                                    }
                                }
                                
                                if(*maskScan & 0x20) { // Try looking down left a pixel
                                    if(*(EGWuint8*)((EGWuintptr)maskScan + (EGWuintptr)surface_inout->size.span.width - (EGWuintptr)1) == 0x00) {
                                        egwColorGSA oPixel;
                                        egwPxlReadGSAb(surface_inout->format, (EGWbyte*)((EGWuintptr)adr + (EGWuintptr)surface_inout->pitch - (EGWuintptr)Bpp), &oPixel);
                                        
                                        EGWint dirTrvld = ((*maskScan & 0x01) && row<(EGWuint)surface_inout->size.span.height-1 ? 0 : 1) + ((*maskScan & 0x02) && row<(EGWuint)surface_inout->size.span.height-1 && col>0 ? 0 : 1) + ((*maskScan & 0x04) && col>0 ? 0 : 1) + ((*maskScan & 0x08) && row>0 && col>0 ? 0 : 1) + ((*maskScan & 0x10) && row>0 ? 0 : 1) + ((*maskScan & 0x20) && row>0 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x40) && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x80) && row<(EGWuint)surface_inout->size.span.height-1 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1);
                                        pixel.channel.l = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.l * dirTrvld) + (EGWint)oPixel.channel.l + (EGWint)1) / (EGWint)2);
                                        
                                        *maskScan &= ~0x20;
                                        modifiedPixel = YES;
                                    }
                                }
                                
                                if(*maskScan & 0x40) { // Try looking left a pixel
                                    if(*(EGWuint8*)((EGWuintptr)maskScan - (EGWuintptr)1) == 0x00) {
                                        egwColorGSA oPixel;
                                        egwPxlReadGSAb(surface_inout->format, (EGWbyte*)((EGWuintptr)adr - (EGWuintptr)Bpp), &oPixel);
                                        
                                        EGWint dirTrvld = ((*maskScan & 0x01) && row<(EGWuint)surface_inout->size.span.height-1 ? 0 : 1) + ((*maskScan & 0x02) && row<(EGWuint)surface_inout->size.span.height-1 && col>0 ? 0 : 1) + ((*maskScan & 0x04) && col>0 ? 0 : 1) + ((*maskScan & 0x08) && row>0 && col>0 ? 0 : 1) + ((*maskScan & 0x10) && row>0 ? 0 : 1) + ((*maskScan & 0x20) && row>0 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x40) && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x80) && row<(EGWuint)surface_inout->size.span.height-1 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1);
                                        pixel.channel.l = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.l * dirTrvld) + (EGWint)oPixel.channel.l + (EGWint)1) / (EGWint)2);
                                        
                                        *maskScan &= ~0x40;
                                        modifiedPixel = YES;
                                    }
                                }
                                
                                if(*maskScan & 0x80) { // Try looking up left a pixel
                                    if(*(EGWuint8*)((EGWuintptr)maskScan - (EGWuintptr)surface_inout->size.span.width - (EGWuintptr)1) == 0x00) {
                                        egwColorGSA oPixel;
                                        egwPxlReadGSAb(surface_inout->format, (EGWbyte*)((EGWuintptr)adr - (EGWuintptr)surface_inout->pitch - (EGWuintptr)Bpp), &oPixel);
                                        
                                        EGWint dirTrvld = ((*maskScan & 0x01) && row<(EGWuint)surface_inout->size.span.height-1 ? 0 : 1) + ((*maskScan & 0x02) && row<(EGWuint)surface_inout->size.span.height-1 && col>0 ? 0 : 1) + ((*maskScan & 0x04) && col>0 ? 0 : 1) + ((*maskScan & 0x08) && row>0 && col>0 ? 0 : 1) + ((*maskScan & 0x10) && row>0 ? 0 : 1) + ((*maskScan & 0x20) && row>0 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x40) && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1) + ((*maskScan & 0x80) && row<(EGWuint)surface_inout->size.span.height-1 && col<(EGWuint)surface_inout->size.span.width-1 ? 0 : 1);
                                        pixel.channel.l = (EGWuint8)egwClamp0255i((((EGWint)pixel.channel.l * dirTrvld) + (EGWint)oPixel.channel.l + (EGWint)1) / (EGWint)2);
                                        
                                        *maskScan &= ~0x80;
                                        modifiedPixel = YES;
                                    }
                                }
                                
                                if(modifiedPixel) {
                                    egwPxlWriteGSAb(surface_inout->format, &pixel, adr);
                                    atLeastOneMod = YES;
                                }
                                
                                if(*maskScan == 0x00)
                                    --pixelsLeft;
                            }
                            
                            adr = (EGWbyte*)((EGWuintptr)adr + (EGWuintptr)Bpp);
                            ++maskScan;
                        }
                        
                        cScanline += (EGWuintptr)surface_inout->pitch;
                    }
                    
                    // Follow up is to set all intermediate mask scans to finished (since that's all the data that can be gathered)
                    if(!atLeastOneMod) {
                        maskScan = mask;
                        row = surface_inout->size.span.height;
                        while(row--) {
                            EGWuint col = surface_inout->size.span.width;
                            while(col--) {
                                if(*maskScan != 0xff && *maskScan != 0x00) {
                                    *maskScan = 0x00;
                                    --pixelsLeft;
                                    atLeastOneMod = YES;
                                }
                                
                                ++maskScan;
                            }
                        }
                    }
                }
            }
            
            free((void*)mask);
            
            return surface_inout;
        }
    }
    
    return NULL;
}

egwSurface* egwSrfcConvert(EGWuint format, const egwSurface* surface_in, egwSurface* surface_out) {
    if(egwSrfcAlloc(surface_out, format, surface_in->size.span.width, surface_in->size.span.height, egwSrfcPacking(surface_in))) {
        EGWuintptr lScanline = (EGWuintptr)surface_in->data;
        EGWuintptr cScanline = (EGWuintptr)surface_out->data;
        
        if(surface_in->format & EGW_SURFACE_FRMT_EXRGB) {
            egwColorRGBA* tempRow = (egwColorRGBA*)malloc((size_t)surface_in->size.span.width * sizeof(egwColorRGBA));
            
            if(tempRow) {
                EGWuint row = surface_in->size.span.height;
                while(row--) {
                    egwPxlReadRGBAbv(surface_in->format, (EGWbyte*)lScanline, tempRow, 0, 0, surface_in->size.span.width);
                    egwPxlWriteRGBAbv(surface_out->format, tempRow, (EGWbyte*)cScanline, 0, 0, surface_out->size.span.width);
                    
                    lScanline += surface_in->pitch;
                    cScanline += surface_out->pitch;
                }
                
                free((void*)tempRow);
                
                return surface_out;
            }
        } else { // GS
            egwColorGSA* tempRow = (egwColorGSA*)malloc((size_t)surface_in->size.span.width * sizeof(egwColorGSA));
            
            if(tempRow) {
                EGWuint row = surface_in->size.span.height;
                while(row--) {
                    egwPxlReadGSAbv(surface_in->format, (EGWbyte*)lScanline, tempRow, 0, 0, surface_in->size.span.width);
                    egwPxlWriteGSAbv(surface_out->format, tempRow, (EGWbyte*)cScanline, 0, 0, surface_out->size.span.width);
                    
                    lScanline += surface_in->pitch;
                    cScanline += surface_out->pitch;
                }
                
                free((void*)tempRow);
                
                return surface_out;
            }
        }
    }
    
    return NULL;
}

egwSurface* egwSrfcRepack(EGWuint16 packingB, const egwSurface* surface_in, egwSurface* surface_out) {
    if(egwSrfcAlloc(surface_out, surface_in->format, surface_in->size.span.width, surface_in->size.span.height, packingB)) {
        EGWuintptr lScanline = (EGWuintptr)surface_in->data;
        EGWuintptr cScanline = (EGWuintptr)surface_out->data;
        EGWuint lineSize = ((EGWuint)(surface_in->format & EGW_SURFACE_FRMT_EXBPP) * (EGWuint)surface_in->size.span.width) >> 3;
        
        EGWuint row = surface_in->size.span.height;
        while(row--) {
            memcpy((void*)cScanline, (const void*)lScanline, (size_t)lineSize);
            
            lScanline += surface_in->pitch;
            cScanline += surface_out->pitch;
        }
        
        return surface_out;
    }
    
    return NULL;
}

egwSurface* egwSrfcSmdgExtd(EGWuint16 width, EGWuint16 height, const egwSurface* surface_in, egwSurface* surface_out) {
    if(surface_in && surface_in->data &&
       width >= surface_in->size.span.width && height >= surface_in->size.span.height &&
       !(surface_in->format & (EGW_SURFACE_FRMT_EXPLT | EGW_SURFACE_FRMT_EXCMPRSD))) { // not handling palletes or compressed
        egwSurface newSurface;
        
        if(egwSrfcAlloc(&newSurface, surface_in->format, width, height, egwSrfcPacking(surface_in))) {
            EGWuintptr lScanline = (EGWuintptr)surface_in->data;
            EGWuintptr cScanline = (EGWuintptr)newSurface.data;
            EGWuint Bpp = (EGWuint)((surface_in->format & EGW_SURFACE_FRMT_EXBPP) >> 3);
            EGWuint lWidth = Bpp * (EGWuint)surface_in->size.span.width;
            EGWuint cWidth = Bpp * (EGWuint)newSurface.size.span.width;
            
            for(EGWuint row = 0, col; row < (EGWuint)newSurface.size.span.height; ++row) {
                if(newSurface.format & EGW_SURFACE_FRMT_EXAC) { // Alpha channel -> specialized copy
                    if(newSurface.format & EGW_SURFACE_FRMT_EXRGB) { // RGBA
                        if(row <= (EGWuint)surface_in->size.span.height) { // Smudge extend end
                            egwColorRGBA rgbaColor;
                            
                            if(row < (EGWuint)surface_in->size.span.height) // Copy over old pitch
                                memcpy((void*)cScanline, (const void*)lScanline, (size_t)lWidth);
                            else { // Smudge extend old pitch
                                for(col = 0; (col + Bpp) <= lWidth; col += Bpp) { // Smudge extend old pitch
                                    egwPxlReadRGBAb(surface_in->format, (EGWbyte*)(lScanline + (EGWuintptr)col), &rgbaColor);
                                    rgbaColor.channel.a = 0; // Extended alpha channel of zero
                                    egwPxlWriteRGBAb(newSurface.format, &rgbaColor, (EGWbyte*)(cScanline + (EGWuintptr)col));
                                }
                            }
                            
                            egwPxlReadRGBAb(surface_in->format, (EGWbyte*)(lScanline + (EGWuintptr)lWidth - (EGWuintptr)Bpp), &rgbaColor);
                            rgbaColor.channel.a = 0; // Extended alpha channel of zero
                            egwPxlWriteRGBAb(newSurface.format, &rgbaColor, (EGWbyte*)(cScanline + (EGWuintptr)lWidth)); // Writes last Bpp+1
                            for(col = lWidth + Bpp; (col + Bpp) <= cWidth; col += Bpp) // Copies last Bpp+1 over to fill differences in pitch
                                memcpy((void*)(cScanline + (EGWuintptr)col), (const void*)(cScanline + (EGWuintptr)lWidth), (size_t)Bpp);
                            
                            if(col < (EGWuint)newSurface.pitch) // Fills remaining bytes on line with 0
                                memset((void*)(cScanline + (EGWuintptr)col), 0, (size_t)((EGWuint)newSurface.pitch - col));
                        } else // Copy last line (smudging done)
                            memcpy((void*)cScanline, (const void*)(cScanline - (EGWuintptr)newSurface.pitch), (size_t)newSurface.pitch);
                    } else { // GSA
                        if(row <= (EGWuint)surface_in->size.span.height) { // Smudge extend end
                            egwColorGSA gsaColor;
                            
                            if(row < (EGWuint)surface_in->size.span.height) // Copy over old pitch
                                memcpy((void*)cScanline, (const void*)lScanline, (size_t)lWidth);
                            else { // Smudge extend old pitch
                                for(col = 0; (col + Bpp) <= lWidth; col += Bpp) { // Smudge extend old pitch
                                    egwPxlReadGSAb(surface_in->format, (EGWbyte*)(lScanline + (EGWuintptr)col), &gsaColor);
                                    gsaColor.channel.a = 0; // Extended alpha channel of zero
                                    egwPxlWriteGSAb(newSurface.format, &gsaColor, (EGWbyte*)(cScanline + (EGWuintptr)col));
                                }
                            }
                            
                            egwPxlReadGSAb(surface_in->format, (EGWbyte*)(lScanline + (EGWuintptr)lWidth - (EGWuintptr)Bpp), &gsaColor);
                            gsaColor.channel.a = 0; // Extended alpha channel of zero
                            egwPxlWriteGSAb(newSurface.format, &gsaColor, (EGWbyte*)(cScanline + (EGWuintptr)lWidth)); // Writes last Bpp+1
                            for(col = lWidth + Bpp; (col + Bpp) <= cWidth; col += Bpp) // Copies last Bpp+1 over to fill differences in pitch
                                memcpy((void*)(cScanline + (EGWuintptr)col), (const void*)(cScanline + (EGWuintptr)lWidth), (size_t)Bpp);
                            
                            if(col < (EGWuint)newSurface.pitch) // Fills remaining bytes on line with 0
                                memset((void*)(cScanline + (EGWuintptr)col), 0, (size_t)((EGWuint)newSurface.pitch - col));
                        } else // Copy last line (smudging done)
                            memcpy((void*)cScanline, (const void*)(cScanline - (EGWuintptr)newSurface.pitch), (size_t)newSurface.pitch);
                    }
                } else { // No alpha channel -> direct copy
                    if(row <= (EGWuint)surface_in->size.span.height) { // Copy over old pitch, smudge extend end
                        memcpy((void*)cScanline, (const void*)lScanline, (size_t)lWidth); // Copies over old pitch
                        
                        for(col = lWidth; (col + Bpp) <= cWidth; col += Bpp) // Copies last Bpp over to fill differences in pitch
                            memcpy((void*)(cScanline + (EGWuintptr)col), (const void*)(lScanline + (EGWuintptr)lWidth - (EGWuintptr)Bpp), (size_t)Bpp);
                        
                        if(col < (EGWuint)newSurface.pitch) // Fills remaining bytes on line with 0
                            memset((void*)(cScanline + (EGWuintptr)col), 0, (size_t)((EGWuint)newSurface.pitch - col));
                    } else // Copy last line (smudging done)
                        memcpy((void*)cScanline, (const void*)(cScanline - (EGWuintptr)newSurface.pitch), (size_t)newSurface.pitch);
                }
                
                if(row+1 < (EGWuint)surface_in->size.span.height) // Don't go beyond last row of input
                    lScanline += (EGWuintptr)(surface_in->pitch);
                cScanline += (EGWuintptr)(newSurface.pitch);
            }
            
            if(surface_out == surface_in)
                free((void*)surface_out->data);
            memcpy((void*)surface_out, (const void*)&newSurface, sizeof(egwSurface));
            memset((void*)&newSurface, 0, sizeof(egwSurface));
            
            return surface_out;
        }
    }
    
    return NULL;
}

EGWuint8 egwSrfcMaxAC(const egwSurface* surface_in) {
    EGWuint8 maxAlpha = 0;
    
    if(surface_in->format & EGW_SURFACE_FRMT_EXAC) {
        EGWbyte* adr = NULL;
        EGWuintptr cScanline = (EGWuintptr)surface_in->data;
        EGWuint Bpp = (surface_in->format & EGW_SURFACE_FRMT_EXBPP) >> 3;
        
        if(surface_in->format & EGW_SURFACE_FRMT_EXRGB) {
            egwColorRGBA pixel;
            
            EGWuint row = surface_in->size.span.height;
            while(row--) {
                adr = (EGWbyte*)cScanline;
                
                EGWuint col = surface_in->size.span.width >> 1;
                while(col--) {
                    egwPxlReadRGBAb(surface_in->format, adr, &pixel);
                    if(pixel.channel.a > maxAlpha) {
                        maxAlpha = pixel.channel.a;
                        
                        if(maxAlpha == 255)
                            return maxAlpha;
                    }
                    
                    adr = (EGWbyte*)((EGWuintptr)adr + (EGWuintptr)Bpp);
                }
                
                cScanline += (EGWuintptr)surface_in->pitch;
            }
        } else { // GS
            egwColorGSA pixel;
            
            EGWuint row = surface_in->size.span.height;
            while(row--) {
                adr = (EGWbyte*)cScanline;
                
                EGWuint col = surface_in->size.span.width >> 1;
                while(col--) {
                    egwPxlReadGSAb(surface_in->format, adr, &pixel);
                    if(pixel.channel.a > maxAlpha) {
                        maxAlpha = pixel.channel.a;
                        
                        if(maxAlpha == 255)
                            return maxAlpha;
                    }
                    
                    adr = (EGWbyte*)((EGWuintptr)adr + (EGWuintptr)Bpp);
                }
                
                cScanline += (EGWuintptr)surface_in->pitch;
            }
        }
    }
    
    return maxAlpha;
}

EGWuint8 egwSrfcMinAC(const egwSurface* surface_in) {
    EGWuint8 minAlpha = 255;
    
    if(surface_in->format & EGW_SURFACE_FRMT_EXAC) {
        EGWbyte* adr = NULL;
        EGWuintptr cScanline = (EGWuintptr)surface_in->data;
        EGWuint Bpp = (surface_in->format & EGW_SURFACE_FRMT_EXBPP) >> 3;
        
        if(surface_in->format & EGW_SURFACE_FRMT_EXRGB) {
            egwColorRGBA pixel;
            
            EGWuint row = surface_in->size.span.height;
            while(row--) {
                adr = (EGWbyte*)cScanline;
                
                EGWuint col = surface_in->size.span.width >> 1;
                while(col--) {
                    egwPxlReadRGBAb(surface_in->format, adr, &pixel);
                    if(pixel.channel.a < minAlpha) {
                        minAlpha = pixel.channel.a;
                        
                        if(minAlpha == 0)
                            return minAlpha;
                    }
                    
                    adr = (EGWbyte*)((EGWuintptr)adr + (EGWuintptr)Bpp);
                }
                
                cScanline += (EGWuintptr)surface_in->pitch;
            }
        } else { // GS
            egwColorGSA pixel;
            
            EGWuint row = surface_in->size.span.height;
            while(row--) {
                adr = (EGWbyte*)cScanline;
                
                EGWuint col = surface_in->size.span.width >> 1;
                while(col--) {
                    egwPxlReadGSAb(surface_in->format, adr, &pixel);
                    if(pixel.channel.a < minAlpha) {
                        minAlpha = pixel.channel.a;
                        
                        if(minAlpha == 0)
                            return minAlpha;
                    }
                    
                    adr = (EGWbyte*)((EGWuintptr)adr + (EGWuintptr)Bpp);
                }
                
                cScanline += (EGWuintptr)surface_in->pitch;
            }
        }
    }
    
    return minAlpha;
}

EGWint egwSrfcPacking(const egwSurface* surface_in) {
    EGWuint bpp = (surface_in->format & EGW_SURFACE_FRMT_EXBPP);
    
    if(surface_in->pitch == ((surface_in->size.span.width * bpp) >> 3)) return 1;
    
    for(EGWint power = 2; power <= 8192; power <<= 1) {
        if(surface_in->pitch == egwRoundUpMultipleui32((((EGWuint)surface_in->size.span.width * bpp) >> 3), power))
            return power;
    }
    
    return -1;
}

void egwPxlReadGSb(EGWuint format, const EGWbyte* pxl_in, egwColorGS* val_out) {
    switch(format) {
        case EGW_SURFACE_FRMT_GS8: {
            val_out->channel.l = *(pxl_in);
        } break;
        case EGW_SURFACE_FRMT_GS8A8: {
            val_out->channel.l = *(pxl_in);
        } break;
        case EGW_SURFACE_FRMT_R5G6B5: {
            val_out->channel.l = (EGWbyte)egwClamp0255i(
                ((((((EGWint)*(pxl_in+1) & 0xf8) >> 3) * 8226) * 30) + 
                 ((((((EGWint)*(pxl_in+1) & 0x07) << 3) | (((EGWint)*(pxl_in) & 0xe0) >> 5)) * 4048) * 59) +
                 ((((EGWint)*(pxl_in) & 0x1f) * 8226) * 11)) / 100000);
        } break;
        case EGW_SURFACE_FRMT_R5G5B5A1: {
            val_out->channel.l = (EGWbyte)egwClamp0255i(
                ((((((EGWint)*(pxl_in+1) & 0xf8) >> 3) * 8226) * 30) + 
                 ((((((EGWint)*(pxl_in+1) & 0x07) << 2) | (((EGWint)*(pxl_in) & 0xc0) >> 6)) * 8226) * 59) +
                 (((((EGWint)*(pxl_in) & 0x3e) >> 1) * 8226) * 11)) / 100000);
        } break;
        case EGW_SURFACE_FRMT_R4G4B4A4: {
            val_out->channel.l = (EGWbyte)egwClamp0255i(
                ((((((EGWint)*(pxl_in+1) & 0xf0) >> 4) * 17000) * 30) + 
                 ((((EGWint)*(pxl_in+1) & 0x0f) * 17000) * 59) +
                 (((((EGWint)*(pxl_in) & 0xf0) >> 4) * 17000) * 11)) / 100000);
        } break;
        case EGW_SURFACE_FRMT_R8G8B8: {
            val_out->channel.l = (EGWbyte)egwClamp0255i((((EGWint)*(pxl_in) * 30) + ((EGWint)*(pxl_in+1) * 59) + ((EGWint)*(pxl_in+2) * 11)) / 100);
        } break;
        case EGW_SURFACE_FRMT_R8G8B8A8: {
            val_out->channel.l = (EGWbyte)egwClamp0255i((((EGWint)*(pxl_in) * 30) + ((EGWint)*(pxl_in+1) * 59) + ((EGWint)*(pxl_in+2) * 11)) / 100);
        } break;
    }
}

void egwPxlReadGSAb(EGWuint format, const EGWbyte* pxl_in, egwColorGSA* val_out) {
    switch(format) {
        case EGW_SURFACE_FRMT_GS8: {
            val_out->channel.l = *(pxl_in);
            val_out->channel.a = (EGWbyte)255;
        } break;
        case EGW_SURFACE_FRMT_GS8A8: {
            val_out->channel.l = *(pxl_in);
            val_out->channel.a = *(pxl_in+1);
        } break;
        case EGW_SURFACE_FRMT_R5G6B5: {
            val_out->channel.l = (EGWbyte)egwClamp0255i(
                ((((((EGWint)*(pxl_in+1) & 0xf8) >> 3) * 8226) * 30) + 
                 ((((((EGWint)*(pxl_in+1) & 0x07) << 3) | (((EGWint)*(pxl_in) & 0xe0) >> 5)) * 4048) * 59) +
                 ((((EGWint)*(pxl_in) & 0x1f) * 8226) * 11)) / 100000);
            val_out->channel.a = (EGWbyte)255;
        } break;
        case EGW_SURFACE_FRMT_R5G5B5A1: {
            val_out->channel.l = (EGWbyte)egwClamp0255i(
                ((((((EGWint)*(pxl_in+1) & 0xf8) >> 3) * 8226) * 30) + 
                 ((((((EGWint)*(pxl_in+1) & 0x07) << 2) | (((EGWint)*(pxl_in) & 0xc0) >> 6)) * 8226) * 59) +
                 (((((EGWint)*(pxl_in) & 0x3e) >> 1) * 8226) * 11)) / 100000);
            val_out->channel.a = (EGWbyte)egwClamp0255i(((EGWint)*(pxl_in) & 0x01) * 255);
        } break;
        case EGW_SURFACE_FRMT_R4G4B4A4: {
            val_out->channel.l = (EGWbyte)egwClamp0255i(
                ((((((EGWint)*(pxl_in+1) & 0xf0) >> 4) * 17000) * 30) + 
                 ((((EGWint)*(pxl_in+1) & 0x0f) * 17000) * 59) +
                 (((((EGWint)*(pxl_in) & 0xf0) >> 4) * 17000) * 11)) / 100000);
            val_out->channel.a = (EGWbyte)egwClamp0255i(((EGWint)*(pxl_in) & 0x0f)  * 15938);
        } break;
        case EGW_SURFACE_FRMT_R8G8B8: {
            val_out->channel.l = (EGWbyte)egwClamp0255i((((EGWint)*(pxl_in) * 30) + ((EGWint)*(pxl_in+1) * 59) + ((EGWint)*(pxl_in+2) * 11)) / 100);
            val_out->channel.a = (EGWbyte)255;
        } break;
        case EGW_SURFACE_FRMT_R8G8B8A8: {
            val_out->channel.l = (EGWbyte)egwClamp0255i((((EGWint)*(pxl_in) * 30) + ((EGWint)*(pxl_in+1) * 59) + ((EGWint)*(pxl_in+2) * 11)) / 100);
            val_out->channel.a = *(pxl_in+3);
        } break;
    }
}

void egwPxlReadRGBb(EGWuint format, const EGWbyte* pxl_in, egwColorRGB* val_out) {
    switch(format) {
        case EGW_SURFACE_FRMT_GS8: {
            val_out->channel.r = val_out->channel.g = val_out->channel.b = *(pxl_in);
        } break;
        case EGW_SURFACE_FRMT_GS8A8: {
            val_out->channel.r = val_out->channel.g = val_out->channel.b = *(pxl_in);
        } break;
        case EGW_SURFACE_FRMT_R5G6B5: {
            val_out->channel.r = (EGWbyte)egwClamp0255i(((((EGWint)*(pxl_in+1) & 0xf8) >> 3) * 8226) / 1000);
            val_out->channel.g = (EGWbyte)egwClamp0255i((((((EGWint)*(pxl_in+1) & 0x07) << 3) | (((EGWint)*(pxl_in) & 0xe0) >> 5)) * 4048) / 1000);
            val_out->channel.b = (EGWbyte)egwClamp0255i((((EGWint)*(pxl_in) & 0x1f) * 8226) / 1000);
        } break;
        case EGW_SURFACE_FRMT_R5G5B5A1: {
            val_out->channel.r = (EGWbyte)egwClamp0255i(((((EGWint)*(pxl_in+1) & 0xf8) >> 3) * 8226) / 1000);
            val_out->channel.g = (EGWbyte)egwClamp0255i((((((EGWint)*(pxl_in+1) & 0x07) << 2) | (((EGWint)*(pxl_in) & 0xc0) >> 6)) * 8226) / 1000);
            val_out->channel.b = (EGWbyte)egwClamp0255i(((((EGWint)*(pxl_in) & 0x3e) >> 1) * 8226) / 1000);
        } break;
        case EGW_SURFACE_FRMT_R4G4B4A4: {
            val_out->channel.r = (EGWbyte)egwClamp0255i((((EGWint)*(pxl_in+1) & 0xf0) >> 4) * 17);
            val_out->channel.g = (EGWbyte)egwClamp0255i(((EGWint)*(pxl_in+1) & 0x0f) * 17);
            val_out->channel.b = (EGWbyte)egwClamp0255i((((EGWint)*(pxl_in) & 0xf0) >> 4) * 17);
        } break;
        case EGW_SURFACE_FRMT_R8G8B8: {
            val_out->channel.r = *(pxl_in);
            val_out->channel.g = *(pxl_in+1);
            val_out->channel.b = *(pxl_in+2);
        } break;
        case EGW_SURFACE_FRMT_R8G8B8A8: {
            val_out->channel.r = *(pxl_in);
            val_out->channel.g = *(pxl_in+1);
            val_out->channel.b = *(pxl_in+2);
        } break;
    }
}

void egwPxlReadRGBAb(EGWuint format, const EGWbyte* pxl_in, egwColorRGBA* val_out) {
    switch(format) {
        case EGW_SURFACE_FRMT_GS8: {
            val_out->channel.r = val_out->channel.g = val_out->channel.b = *(pxl_in);
            val_out->channel.a = (EGWbyte)255;
        } break;
        case EGW_SURFACE_FRMT_GS8A8: {
            val_out->channel.r = val_out->channel.g = val_out->channel.b = *(pxl_in);
            val_out->channel.a = *(pxl_in+1);
        } break;
        case EGW_SURFACE_FRMT_R5G6B5: {
            val_out->channel.r = (EGWbyte)egwClamp0255i(((((EGWint)*(pxl_in+1) & 0xf8) >> 3) * 8226) / 1000);
            val_out->channel.g = (EGWbyte)egwClamp0255i((((((EGWint)*(pxl_in+1) & 0x07) << 3) | (((EGWint)*(pxl_in) & 0xe0) >> 5)) * 4048) / 1000);
            val_out->channel.b = (EGWbyte)egwClamp0255i((((EGWint)*(pxl_in) & 0x1f) * 8226) / 1000);
            val_out->channel.a = (EGWbyte)255;
        } break;
        case EGW_SURFACE_FRMT_R5G5B5A1: {
            val_out->channel.r = (EGWbyte)egwClamp0255i(((((EGWint)*(pxl_in+1) & 0xf8) >> 3) * 8226) / 1000);
            val_out->channel.g = (EGWbyte)egwClamp0255i((((((EGWint)*(pxl_in+1) & 0x07) << 2) | (((EGWint)*(pxl_in) & 0xc0) >> 6)) * 8226) / 1000);
            val_out->channel.b = (EGWbyte)egwClamp0255i(((((EGWint)*(pxl_in) & 0x3e) >> 1) * 8226) / 1000);
            val_out->channel.a = (EGWbyte)egwClamp0255i(((EGWint)*(pxl_in) & 0x01) * 255);
        } break;
        case EGW_SURFACE_FRMT_R4G4B4A4: {
            val_out->channel.r = (EGWbyte)egwClamp0255i((((EGWint)*(pxl_in+1) & 0xf0) >> 4) * 17);
            val_out->channel.g = (EGWbyte)egwClamp0255i(((EGWint)*(pxl_in+1) & 0x0f) * 17);
            val_out->channel.b = (EGWbyte)egwClamp0255i((((EGWint)*(pxl_in) & 0xf0) >> 4) * 17);
            val_out->channel.a = (EGWbyte)egwClamp0255i(((EGWint)*(pxl_in) & 0x0f) * 17);
        } break;
        case EGW_SURFACE_FRMT_R8G8B8: {
            val_out->channel.r = *(pxl_in);
            val_out->channel.g = *(pxl_in+1);
            val_out->channel.b = *(pxl_in+2);
            val_out->channel.a = (EGWbyte)255;
        } break;
        case EGW_SURFACE_FRMT_R8G8B8A8: {
            val_out->channel.r = *(pxl_in);
            val_out->channel.g = *(pxl_in+1);
            val_out->channel.b = *(pxl_in+2);
            val_out->channel.a = *(pxl_in+3);
        } break;
    }
}

void egwPxlReadGSbv(EGWuint format, const EGWbyte* pxls_in, egwColorGS* vals_out, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count) {
    switch(format) {
        case EGW_SURFACE_FRMT_GS8: {
            while(count--) {
                vals_out->channel.l = *(pxls_in);
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(1 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorGS*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorGS) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_GS8A8: {
            while(count--) {
                vals_out->channel.l = *(pxls_in);
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorGS*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorGS) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R5G6B5: {
            while(count--) {
                vals_out->channel.l = (EGWbyte)egwClamp0255i(
                    ((((((EGWint)*(pxls_in+1) & 0xf8) >> 3) * 8226) * 30) + 
                     ((((((EGWint)*(pxls_in+1) & 0x07) << 3) | (((EGWint)*(pxls_in) & 0xe0) >> 5)) * 4048) * 59) +
                     ((((EGWint)*(pxls_in) & 0x1f) * 8226) * 11)) / 100000);
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorGS*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorGS) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R5G5B5A1: {
            while(count--) {
                vals_out->channel.l = (EGWbyte)egwClamp0255i(
                    ((((((EGWint)*(pxls_in+1) & 0xf8) >> 3) * 8226) * 30) + 
                     ((((((EGWint)*(pxls_in+1) & 0x07) << 2) | (((EGWint)*(pxls_in) & 0xc0) >> 6)) * 8226) * 59) +
                     (((((EGWint)*(pxls_in) & 0x3e) >> 1) * 8226) * 11)) / 100000);
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorGS*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorGS) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R4G4B4A4: {
            while(count--) {
                vals_out->channel.l = (EGWbyte)egwClamp0255i(
                    ((((((EGWint)*(pxls_in+1) & 0xf0) >> 4) * 17000) * 30) + 
                     ((((EGWint)*(pxls_in+1) & 0x0f) * 17000) * 59) +
                     (((((EGWint)*(pxls_in) & 0xf0) >> 4) * 17000) * 11)) / 100000);
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorGS*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorGS) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R8G8B8: {
            while(count--) {
                vals_out->channel.l = (EGWbyte)egwClamp0255i((((EGWint)*(pxls_in) * 30) + ((EGWint)*(pxls_in+1) * 59) + ((EGWint)*(pxls_in+2) * 11)) / 100);
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(3 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorGS*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorGS) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R8G8B8A8: {
            while(count--) {
                vals_out->channel.l = (EGWbyte)egwClamp0255i((((EGWint)*(pxls_in) * 30) + ((EGWint)*(pxls_in+1) * 59) + ((EGWint)*(pxls_in+2) * 11)) / 100);
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(4 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorGS*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorGS) + strideB_out);
            }
        } break;
    }
}

void egwPxlReadGSAbv(EGWuint format, const EGWbyte* pxls_in, egwColorGSA* vals_out, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count) {
    switch(format) {
        case EGW_SURFACE_FRMT_GS8: {
            while(count--) {
                vals_out->channel.l = *(pxls_in);
                vals_out->channel.a = (EGWbyte)255;
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(1 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorGSA*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorGSA) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_GS8A8: {
            while(count--) {
                vals_out->channel.l = *(pxls_in);
                vals_out->channel.a = *(pxls_in+1);
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorGSA*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorGSA) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R5G6B5: {
            while(count--) {
                vals_out->channel.l = (EGWbyte)egwClamp0255i(
                    ((((((EGWint)*(pxls_in+1) & 0xf8) >> 3) * 8226) * 30) + 
                     ((((((EGWint)*(pxls_in+1) & 0x07) << 3) | (((EGWint)*(pxls_in) & 0xe0) >> 5)) * 4048) * 59) +
                     ((((EGWint)*(pxls_in) & 0x1f) * 8226) * 11)) / 100000);
                vals_out->channel.a = (EGWbyte)255;
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorGSA*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorGSA) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R5G5B5A1: {
            while(count--) {
                vals_out->channel.l = (EGWbyte)egwClamp0255i(
                    ((((((EGWint)*(pxls_in+1) & 0xf8) >> 3) * 8226) * 30) + 
                     ((((((EGWint)*(pxls_in+1) & 0x07) << 2) | (((EGWint)*(pxls_in) & 0xc0) >> 6)) * 8226) * 59) +
                     (((((EGWint)*(pxls_in) & 0x3e) >> 1) * 8226) * 11)) / 100000);
                vals_out->channel.a = (EGWbyte)egwClamp0255i(((EGWint)*(pxls_in) & 0x01) * 255);
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorGSA*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorGSA) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R4G4B4A4: {
            while(count--) {
                vals_out->channel.l = (EGWbyte)egwClamp0255i(
                    ((((((EGWint)*(pxls_in+1) & 0xf0) >> 4) * 17000) * 30) + 
                     ((((EGWint)*(pxls_in+1) & 0x0f) * 17000) * 59) +
                     (((((EGWint)*(pxls_in) & 0xf0) >> 4) * 17000) * 11)) / 100000);
                vals_out->channel.a = (EGWbyte)egwClamp0255i(((EGWint)*(pxls_in) & 0x0f)  * 15938);
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorGSA*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorGSA) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R8G8B8: {
            while(count--) {
                vals_out->channel.l = (EGWbyte)egwClamp0255i((((EGWint)*(pxls_in) * 30) + ((EGWint)*(pxls_in+1) * 59) + ((EGWint)*(pxls_in+2) * 11)) / 100);
                vals_out->channel.a = (EGWbyte)255;
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(3 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorGSA*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorGSA) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R8G8B8A8: {
            while(count--) {
                vals_out->channel.l = (EGWbyte)egwClamp0255i((((EGWint)*(pxls_in) * 30) + ((EGWint)*(pxls_in+1) * 59) + ((EGWint)*(pxls_in+2) * 11)) / 100);
                vals_out->channel.a = *(pxls_in+3);
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(4 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorGSA*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorGSA) + strideB_out);
            }
        } break;
    }
}

void egwPxlReadRGBbv(EGWuint format, const EGWbyte* pxls_in, egwColorRGB* vals_out, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count) {
    switch(format) {
        case EGW_SURFACE_FRMT_GS8: {
            while(count--) {
                vals_out->channel.r = vals_out->channel.g = vals_out->channel.b = *(pxls_in);
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(1 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorRGB*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorRGB) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_GS8A8: {
            while(count--) {
                vals_out->channel.r = vals_out->channel.g = vals_out->channel.b = *(pxls_in);
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorRGB*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorRGB) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R5G6B5: {
            while(count--) {
                vals_out->channel.r = (EGWbyte)egwClamp0255i(((((EGWint)*(pxls_in+1) & 0xf8) >> 3) * 8226) / 1000);
                vals_out->channel.g = (EGWbyte)egwClamp0255i((((((EGWint)*(pxls_in+1) & 0x07) << 3) | (((EGWint)*(pxls_in) & 0xe0) >> 5)) * 4048) / 1000);
                vals_out->channel.b = (EGWbyte)egwClamp0255i((((EGWint)*(pxls_in) & 0x1f) * 8226) / 1000);
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorRGB*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorRGB) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R5G5B5A1: {
            while(count--) {
                vals_out->channel.r = (EGWbyte)egwClamp0255i(((((EGWint)*(pxls_in+1) & 0xf8) >> 3) * 8226) / 1000);
                vals_out->channel.g = (EGWbyte)egwClamp0255i((((((EGWint)*(pxls_in+1) & 0x07) << 2) | (((EGWint)*(pxls_in) & 0xc0) >> 6)) * 8226) / 1000);
                vals_out->channel.b = (EGWbyte)egwClamp0255i(((((EGWint)*(pxls_in) & 0x3e) >> 1) * 8226) / 1000);
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorRGB*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorRGB) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R4G4B4A4: {
            while(count--) {
                vals_out->channel.r = (EGWbyte)egwClamp0255i((((EGWint)*(pxls_in+1) & 0xf0) >> 4) * 17);
                vals_out->channel.g = (EGWbyte)egwClamp0255i(((EGWint)*(pxls_in+1) & 0x0f) * 17);
                vals_out->channel.b = (EGWbyte)egwClamp0255i((((EGWint)*(pxls_in) & 0xf0) >> 4) * 17);
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorRGB*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorRGB) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R8G8B8: {
            while(count--) {
                vals_out->channel.r = *(pxls_in);
                vals_out->channel.g = *(pxls_in+1);
                vals_out->channel.b = *(pxls_in+2);
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(3 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorRGB*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorRGB) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R8G8B8A8: {
            while(count--) {
                vals_out->channel.r = *(pxls_in);
                vals_out->channel.g = *(pxls_in+1);
                vals_out->channel.b = *(pxls_in+2);
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(4 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorRGB*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorRGB) + strideB_out);
            }
        } break;
    }
}

void egwPxlReadRGBAbv(EGWuint format, const EGWbyte* pxls_in, egwColorRGBA* vals_out, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count) {
    switch(format) {
        case EGW_SURFACE_FRMT_GS8: {
            while(count--) {
                vals_out->channel.r = vals_out->channel.g = vals_out->channel.b = *(pxls_in);
                vals_out->channel.a = (EGWbyte)255;
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(1 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorRGBA*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorRGBA) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_GS8A8: {
            while(count--) {
                vals_out->channel.r = vals_out->channel.g = vals_out->channel.b = *(pxls_in);
                vals_out->channel.a = *(pxls_in+1);
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorRGBA*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorRGBA) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R5G6B5: {
            while(count--) {
                vals_out->channel.r = (EGWbyte)egwClamp0255i(((((EGWint)*(pxls_in+1) & 0xf8) >> 3) * 8226) / 1000);
                vals_out->channel.g = (EGWbyte)egwClamp0255i((((((EGWint)*(pxls_in+1) & 0x07) << 3) | (((EGWint)*(pxls_in) & 0xe0) >> 5)) * 4048) / 1000);
                vals_out->channel.b = (EGWbyte)egwClamp0255i((((EGWint)*(pxls_in) & 0x1f) * 8226) / 1000);
                vals_out->channel.a = (EGWbyte)255;
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorRGBA*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorRGBA) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R5G5B5A1: {
            while(count--) {
                vals_out->channel.r = (EGWbyte)egwClamp0255i(((((EGWint)*(pxls_in+1) & 0xf8) >> 3) * 8226) / 1000);
                vals_out->channel.g = (EGWbyte)egwClamp0255i((((((EGWint)*(pxls_in+1) & 0x07) << 2) | (((EGWint)*(pxls_in) & 0xc0) >> 6)) * 8226) / 1000);
                vals_out->channel.b = (EGWbyte)egwClamp0255i(((((EGWint)*(pxls_in) & 0x3e) >> 1) * 8226) / 1000);
                vals_out->channel.a = (EGWbyte)egwClamp0255i(((EGWint)*(pxls_in) & 0x01) * 255);
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorRGBA*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorRGBA) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R4G4B4A4: {
            while(count--) {
                vals_out->channel.r = (EGWbyte)egwClamp0255i((((EGWint)*(pxls_in+1) & 0xf0) >> 4) * 17);
                vals_out->channel.g = (EGWbyte)egwClamp0255i(((EGWint)*(pxls_in+1) & 0x0f) * 17);
                vals_out->channel.b = (EGWbyte)egwClamp0255i((((EGWint)*(pxls_in) & 0xf0) >> 4) * 17);
                vals_out->channel.a = (EGWbyte)egwClamp0255i(((EGWint)*(pxls_in) & 0x0f) * 17);
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorRGBA*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorRGBA) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R8G8B8: {
            while(count--) {
                vals_out->channel.r = *(pxls_in);
                vals_out->channel.g = *(pxls_in+1);
                vals_out->channel.b = *(pxls_in+2);
                vals_out->channel.a = (EGWbyte)255;
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(3 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorRGBA*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorRGBA) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R8G8B8A8: {
            while(count--) {
                vals_out->channel.r = *(pxls_in);
                vals_out->channel.g = *(pxls_in+1);
                vals_out->channel.b = *(pxls_in+2);
                vals_out->channel.a = *(pxls_in+3);
                
                pxls_in = (const EGWbyte*)((EGWintptr)pxls_in + (EGWintptr)(4 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwColorRGBA*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwColorRGBA) + strideB_out);
            }
        } break;
    }    
}

void egwPxlWriteGSb(EGWuint format, const egwColorGS* val_in, EGWbyte* pxl_out) {
    switch(format) {
        case EGW_SURFACE_FRMT_GS8: {
            *(pxl_out) = val_in->channel.l;
        } break;
        case EGW_SURFACE_FRMT_GS8A8: {
            *(pxl_out) = val_in->channel.l;
            *(pxl_out+1) = (EGWbyte)255;
        } break;
        case EGW_SURFACE_FRMT_R5G6B5: {
            register EGWbyte temp1 = (EGWbyte)((((EGWint)(val_in->channel.l) * 1000) / 8225) & 0x1f);
            register EGWbyte temp2 = (EGWbyte)((((EGWint)(val_in->channel.l) * 1000) / 4047) & 0x3f);
            *(pxl_out+1) = (temp1 << 3) | (temp2 >> 3);
            *(pxl_out) = ((temp2 & 0x07) << 5) | (temp1);
        } break;
        case EGW_SURFACE_FRMT_R5G5B5A1: {
            register EGWbyte temp1 = (EGWbyte)((((EGWint)(val_in->channel.l) * 1000) / 8225) & 0x1f);
            *(pxl_out+1) = (temp1 << 3) | (temp1 >> 2);
            *(pxl_out) = ((temp1 & 0x03) << 6) | (temp1 << 1) | (0x01);
        } break;
        case EGW_SURFACE_FRMT_R4G4B4A4: {
            register EGWbyte temp1 = (EGWbyte)((val_in->channel.l / 17) & 0x0f);
            *(pxl_out+1) = (temp1 << 4) | (temp1);
            *(pxl_out) = (temp1 << 4) | (0x0f);
        } break;
        case EGW_SURFACE_FRMT_R8G8B8: {
            *(pxl_out) = *(pxl_out+1) = *(pxl_out+2) = val_in->channel.l;
        } break;
        case EGW_SURFACE_FRMT_R8G8B8A8: {
            *(pxl_out) = *(pxl_out+1) = *(pxl_out+2) = val_in->channel.l;
            *(pxl_out+3) = (EGWbyte)255;
        } break;
    }
}

void egwPxlWriteGSAb(EGWuint format, const egwColorGSA* val_in, EGWbyte* pxl_out) {
    switch(format) {
        case EGW_SURFACE_FRMT_GS8: {
            *(pxl_out) = val_in->channel.l;
        } break;
        case EGW_SURFACE_FRMT_GS8A8: {
            *(pxl_out) = val_in->channel.l;
            *(pxl_out+1) = val_in->channel.a;
        } break;
        case EGW_SURFACE_FRMT_R5G6B5: {
            register EGWbyte temp1 = (EGWbyte)((((EGWint)(val_in->channel.l) * 1000) / 8225) & 0x1f);
            register EGWbyte temp2 = (EGWbyte)((((EGWint)(val_in->channel.l) * 1000) / 4047) & 0x3f);
            *(pxl_out+1) = (temp1 << 3) | (temp2 >> 3);
            *(pxl_out) = ((temp2 & 0x07) << 5) | (temp1);
        } break;
        case EGW_SURFACE_FRMT_R5G5B5A1: {
            register EGWbyte temp1 = (EGWbyte)((((EGWint)(val_in->channel.l) * 1000) / 8225) & 0x1f);
            register EGWbyte temp2 = (EGWbyte)((val_in->channel.a / 129) & 0x01);
            *(pxl_out+1) = (temp1 << 3) | (temp1 >> 2);
            *(pxl_out) = ((temp1 & 0x03) << 6) | (temp1 << 1) | (temp2);
        } break;
        case EGW_SURFACE_FRMT_R4G4B4A4: {
            register EGWbyte temp1 = (EGWbyte)((val_in->channel.l / 17) & 0x0f);
            register EGWbyte temp2 = (EGWbyte)((val_in->channel.a / 17) & 0x0f);
            *(pxl_out+1) = (temp1 << 4) | (temp1);
            *(pxl_out) = (temp1 << 4) | (temp2);
        } break;
        case EGW_SURFACE_FRMT_R8G8B8: {
            *(pxl_out) = *(pxl_out+1) = *(pxl_out+2) = val_in->channel.l;
        } break;
        case EGW_SURFACE_FRMT_R8G8B8A8: {
            *(pxl_out) = *(pxl_out+1) = *(pxl_out+2) = val_in->channel.l;
            *(pxl_out+3) = val_in->channel.a;
        } break;
    }
}

void egwPxlWriteRGBb(EGWuint format, const egwColorRGB* val_in, EGWbyte* pxl_out) {
    switch(format) {
        case EGW_SURFACE_FRMT_GS8: {
            *(pxl_out) = (EGWbyte)egwClamp0255i((((EGWint)(val_in->channel.r) * 30) +
                                                 ((EGWint)(val_in->channel.g) * 59) +
                                                 ((EGWint)(val_in->channel.b) * 11)) / 100);
        } break;
        case EGW_SURFACE_FRMT_GS8A8: {
            *(pxl_out) = (EGWbyte)egwClamp0255i((((EGWint)(val_in->channel.r) * 30) +
                                                 ((EGWint)(val_in->channel.g) * 59) +
                                                 ((EGWint)(val_in->channel.b) * 11)) / 100);
            *(pxl_out+1) = (EGWbyte)255;
        } break;
        case EGW_SURFACE_FRMT_R5G6B5: {
            register EGWbyte temp1 = (EGWbyte)((((EGWint)(val_in->channel.r) * 1000) / 8225) & 0x1f);
            register EGWbyte temp2 = (EGWbyte)((((EGWint)(val_in->channel.g) * 1000) / 4047) & 0x3f);
            register EGWbyte temp3 = (EGWbyte)((((EGWint)(val_in->channel.b) * 1000) / 8225) & 0x1f);
            *(pxl_out+1) = (temp1 << 3) | (temp2 >> 3);
            *(pxl_out) = ((temp2 & 0x07) << 5) | (temp3);
        } break;
        case EGW_SURFACE_FRMT_R5G5B5A1: {
            register EGWbyte temp1 = (EGWbyte)((((EGWint)(val_in->channel.r) * 1000) / 8225) & 0x1f);
            register EGWbyte temp2 = (EGWbyte)((((EGWint)(val_in->channel.g) * 1000) / 8225) & 0x1f);
            register EGWbyte temp3 = (EGWbyte)((((EGWint)(val_in->channel.b) * 1000) / 8225) & 0x1f);
            *(pxl_out+1) = (temp1 << 3) | (temp2 >> 2);
            *(pxl_out) = ((temp2 & 0x03) << 6) | (temp3 << 1) | (0x01);
        } break;
        case EGW_SURFACE_FRMT_R4G4B4A4: {
            register EGWbyte temp1 = (EGWbyte)((val_in->channel.r / 17) & 0x0f);
            register EGWbyte temp2 = (EGWbyte)((val_in->channel.g / 17) & 0x0f);
            register EGWbyte temp3 = (EGWbyte)((val_in->channel.b / 17) & 0x0f);
            *(pxl_out+1) = (temp1 << 4) | (temp2);
            *(pxl_out) = (temp3 << 4) | (0x0f);
        } break;
        case EGW_SURFACE_FRMT_R8G8B8: {
            *(pxl_out) = val_in->channel.r;
            *(pxl_out+1) = val_in->channel.g;
            *(pxl_out+2) = val_in->channel.b;
        } break;
        case EGW_SURFACE_FRMT_R8G8B8A8: {
            *(pxl_out) = val_in->channel.r;
            *(pxl_out+1) = val_in->channel.g;
            *(pxl_out+2) = val_in->channel.b;
            *(pxl_out+3) = (EGWbyte)255;
        } break;
    }
}

void egwPxlWriteRGBAb(EGWuint format, const egwColorRGBA* val_in, EGWbyte* pxl_out) {
    switch(format) {
        case EGW_SURFACE_FRMT_GS8: {
            *(pxl_out) = (EGWbyte)egwClamp0255i((((EGWint)(val_in->channel.r) * 30) +
                                                 ((EGWint)(val_in->channel.g) * 59) +
                                                 ((EGWint)(val_in->channel.b) * 11)) / 100);
        } break;
        case EGW_SURFACE_FRMT_GS8A8: {
            *(pxl_out) = (EGWbyte)egwClamp0255i((((EGWint)(val_in->channel.r) * 30) +
                                                 ((EGWint)(val_in->channel.g) * 59) +
                                                 ((EGWint)(val_in->channel.b) * 11)) / 100);
            *(pxl_out+1) = val_in->channel.a;
        } break;
        case EGW_SURFACE_FRMT_R5G6B5: {
            register EGWbyte temp1 = (EGWbyte)((((EGWint)(val_in->channel.r) * 1000) / 8225) & 0x1f);
            register EGWbyte temp2 = (EGWbyte)((((EGWint)(val_in->channel.g) * 1000) / 4047) & 0x3f);
            register EGWbyte temp3 = (EGWbyte)((((EGWint)(val_in->channel.b) * 1000) / 8225) & 0x1f);
            *(pxl_out+1) = (temp1 << 3) | (temp2 >> 3);
            *(pxl_out) = ((temp2 & 0x07) << 5) | (temp3);
        } break;
        case EGW_SURFACE_FRMT_R5G5B5A1: {
            register EGWbyte temp1 = (EGWbyte)((((EGWint)(val_in->channel.r) * 1000) / 8225) & 0x1f);
            register EGWbyte temp2 = (EGWbyte)((((EGWint)(val_in->channel.g) * 1000) / 8225) & 0x1f);
            register EGWbyte temp3 = (EGWbyte)((((EGWint)(val_in->channel.b) * 1000) / 8225) & 0x1f);
            register EGWbyte temp4 = (EGWbyte)((val_in->channel.a / 129) & 0x01);
            *(pxl_out+1) = (temp1 << 3) | (temp2 >> 2);
            *(pxl_out) = ((temp2 & 0x03) << 6) | (temp3 << 1) | (temp4);
        } break;
        case EGW_SURFACE_FRMT_R4G4B4A4: {
            register EGWbyte temp1 = (EGWbyte)((val_in->channel.r / 17) & 0x0f);
            register EGWbyte temp2 = (EGWbyte)((val_in->channel.g / 17) & 0x0f);
            register EGWbyte temp3 = (EGWbyte)((val_in->channel.b / 17) & 0x0f);
            register EGWbyte temp4 = (EGWbyte)((val_in->channel.a / 17) & 0x0f);
            *(pxl_out+1) = (temp1 << 4) | (temp2);
            *(pxl_out) = (temp3 << 4) | (temp4);
        } break;
        case EGW_SURFACE_FRMT_R8G8B8: {
            *(pxl_out) = val_in->channel.r;
            *(pxl_out+1) = val_in->channel.g;
            *(pxl_out+2) = val_in->channel.b;
        } break;
        case EGW_SURFACE_FRMT_R8G8B8A8: {
            *(pxl_out) = val_in->channel.r;
            *(pxl_out+1) = val_in->channel.g;
            *(pxl_out+2) = val_in->channel.b;
            *(pxl_out+3) = val_in->channel.a;
        } break;
    }
}

void egwPxlWriteGSbv(EGWuint format, const egwColorGS* vals_in, EGWbyte* pxls_out, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count) {
    switch(format) {
        case EGW_SURFACE_FRMT_GS8: {
            while(count--) {
                *(pxls_out) = vals_in->channel.l;
                
                vals_in = (const egwColorGS*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorGS) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(1 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_GS8A8: {
            while(count--) {
                *(pxls_out) = vals_in->channel.l;
                *(pxls_out+1) = (EGWbyte)255;
                
                vals_in = (const egwColorGS*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorGS) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R5G6B5: {
            while(count--) {
                register EGWbyte temp1 = (EGWbyte)((((EGWint)(vals_in->channel.l) * 1000) / 8225) & 0x1f);
                register EGWbyte temp2 = (EGWbyte)((((EGWint)(vals_in->channel.l) * 1000) / 4047) & 0x3f);
                *(pxls_out+1) = (temp1 << 3) | (temp2 >> 3);
                *(pxls_out) = ((temp2 & 0x07) << 5) | (temp1);
                
                vals_in = (const egwColorGS*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorGS) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R5G5B5A1: {
            while(count--) {
                register EGWbyte temp1 = (EGWbyte)((((EGWint)(vals_in->channel.l) * 1000) / 8225) & 0x1f);
                *(pxls_out+1) = (temp1 << 3) | (temp1 >> 2);
                *(pxls_out) = ((temp1 & 0x03) << 6) | (temp1 << 1) | (0x01);
                
                vals_in = (const egwColorGS*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorGS) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R4G4B4A4: {
            while(count--) {
                register EGWbyte temp1 = (EGWbyte)((vals_in->channel.l / 17) & 0x0f);
                *(pxls_out+1) = (temp1 << 4) | (temp1);
                *(pxls_out) = (temp1 << 4) | (0x0f);
                
                vals_in = (const egwColorGS*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorGS) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R8G8B8: {
            while(count--) {
                *(pxls_out) = *(pxls_out+1) = *(pxls_out+2) = vals_in->channel.l;
                
                vals_in = (const egwColorGS*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorGS) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(3 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R8G8B8A8: {
            while(count--) {
                *(pxls_out) = *(pxls_out+1) = *(pxls_out+2) = vals_in->channel.l;
                *(pxls_out+3) = (EGWbyte)255;
                
                vals_in = (const egwColorGS*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorGS) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(4 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
    }
}

void egwPxlWriteGSAbv(EGWuint format, const egwColorGSA* vals_in, EGWbyte* pxls_out, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count) {
    switch(format) {
        case EGW_SURFACE_FRMT_GS8: {
            while(count--) {
                *(pxls_out) = vals_in->channel.l;
                
                vals_in = (const egwColorGSA*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorGSA) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(1 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_GS8A8: {
            while(count--) {
                *(pxls_out) = vals_in->channel.l;
                *(pxls_out+1) = vals_in->channel.a;
                
                vals_in = (const egwColorGSA*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorGSA) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R5G6B5: {
            while(count--) {
                register EGWbyte temp1 = (EGWbyte)((((EGWint)(vals_in->channel.l) * 1000) / 8225) & 0x1f);
                register EGWbyte temp2 = (EGWbyte)((((EGWint)(vals_in->channel.l) * 1000) / 4047) & 0x3f);
                *(pxls_out+1) = (temp1 << 3) | (temp2 >> 3);
                *(pxls_out) = ((temp2 & 0x07) << 5) | (temp1);
                
                vals_in = (const egwColorGSA*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorGSA) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R5G5B5A1: {
            while(count--) {
                register EGWbyte temp1 = (EGWbyte)((((EGWint)(vals_in->channel.l) * 1000) / 8225) & 0x1f);
                register EGWbyte temp2 = (EGWbyte)((vals_in->channel.a / 129) & 0x01);
                *(pxls_out+1) = (temp1 << 3) | (temp1 >> 2);
                *(pxls_out) = ((temp1 & 0x03) << 6) | (temp1 << 1) | (temp2);
                
                vals_in = (const egwColorGSA*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorGSA) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R4G4B4A4: {
            while(count--) {
                register EGWbyte temp1 = (EGWbyte)((vals_in->channel.l / 17) & 0x0f);
                register EGWbyte temp2 = (EGWbyte)((vals_in->channel.a / 17) & 0x0f);
                *(pxls_out+1) = (temp1 << 4) | (temp1);
                *(pxls_out) = (temp1 << 4) | (temp2);
                
                vals_in = (const egwColorGSA*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorGSA) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R8G8B8: {
            while(count--) {
                *(pxls_out) = *(pxls_out+1) = *(pxls_out+2) = vals_in->channel.l;
                
                vals_in = (const egwColorGSA*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorGSA) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(3 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R8G8B8A8: {
            while(count--) {
                *(pxls_out) = *(pxls_out+1) = *(pxls_out+2) = vals_in->channel.l;
                *(pxls_out+3) = vals_in->channel.a;
                
                vals_in = (const egwColorGSA*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorGSA) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(4 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
    }
}

void egwPxlWriteRGBbv(EGWuint format, const egwColorRGB* vals_in, EGWbyte* pxls_out, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count) {
    switch(format) {
        case EGW_SURFACE_FRMT_GS8: {
            while(count--) {
                *(pxls_out) = (EGWbyte)egwClamp0255i((((EGWint)(vals_in->channel.r) * 30) +
                                                      ((EGWint)(vals_in->channel.g) * 59) +
                                                      ((EGWint)(vals_in->channel.b) * 11)) / 100);
                
                vals_in = (const egwColorRGB*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorRGB) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(1 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_GS8A8: {
            while(count--) {
                *(pxls_out) = (EGWbyte)egwClamp0255i((((EGWint)(vals_in->channel.r) * 30) +
                                                      ((EGWint)(vals_in->channel.g) * 59) +
                                                      ((EGWint)(vals_in->channel.b) * 11)) / 100);
                *(pxls_out+1) = (EGWbyte)255;
                
                vals_in = (const egwColorRGB*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorRGB) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R5G6B5: {
            while(count--) {
                register EGWbyte temp1 = (EGWbyte)((((EGWint)(vals_in->channel.r) * 1000) / 8225) & 0x1f);
                register EGWbyte temp2 = (EGWbyte)((((EGWint)(vals_in->channel.g) * 1000) / 4047) & 0x3f);
                register EGWbyte temp3 = (EGWbyte)((((EGWint)(vals_in->channel.b) * 1000) / 8225) & 0x1f);
                *(pxls_out+1) = (temp1 << 3) | (temp2 >> 3);
                *(pxls_out) = ((temp2 & 0x07) << 5) | (temp3);
                
                vals_in = (const egwColorRGB*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorRGB) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R5G5B5A1: {
            while(count--) {
                register EGWbyte temp1 = (EGWbyte)((((EGWint)(vals_in->channel.r) * 1000) / 8225) & 0x1f);
                register EGWbyte temp2 = (EGWbyte)((((EGWint)(vals_in->channel.g) * 1000) / 8225) & 0x1f);
                register EGWbyte temp3 = (EGWbyte)((((EGWint)(vals_in->channel.b) * 1000) / 8225) & 0x1f);
                *(pxls_out+1) = (temp1 << 3) | (temp2 >> 2);
                *(pxls_out) = ((temp2 & 0x03) << 6) | (temp3 << 1) | (0x01);
                
                vals_in = (const egwColorRGB*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorRGB) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R4G4B4A4: {
            while(count--) {
                register EGWbyte temp1 = (EGWbyte)((vals_in->channel.r / 17) & 0x0f);
                register EGWbyte temp2 = (EGWbyte)((vals_in->channel.g / 17) & 0x0f);
                register EGWbyte temp3 = (EGWbyte)((vals_in->channel.b / 17) & 0x0f);
                *(pxls_out+1) = (temp1 << 4) | (temp2);
                *(pxls_out) = (temp3 << 4) | (0x0f);
                
                vals_in = (const egwColorRGB*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorRGB) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R8G8B8: {
            while(count--) {
                *(pxls_out) = vals_in->channel.r;
                *(pxls_out+1) = vals_in->channel.g;
                *(pxls_out+2) = vals_in->channel.b;
                
                vals_in = (const egwColorRGB*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorRGB) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(3 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R8G8B8A8: {
            while(count--) {
                *(pxls_out) = vals_in->channel.r;
                *(pxls_out+1) = vals_in->channel.g;
                *(pxls_out+2) = vals_in->channel.b;
                *(pxls_out+3) = (EGWbyte)255;
                
                vals_in = (const egwColorRGB*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorRGB) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(4 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
    }
}

void egwPxlWriteRGBAbv(EGWuint format, const egwColorRGBA* vals_in, EGWbyte* pxls_out, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count) {
    switch(format) {
        case EGW_SURFACE_FRMT_GS8: {
            while(count--) {
                *(pxls_out) = (EGWbyte)egwClamp0255i((((EGWint)(vals_in->channel.r) * 30) +
                                                      ((EGWint)(vals_in->channel.g) * 59) +
                                                      ((EGWint)(vals_in->channel.b) * 11)) / 100);
                
                vals_in = (const egwColorRGBA*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorRGBA) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(1 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_GS8A8: {
            while(count--) {
                *(pxls_out) = (EGWbyte)egwClamp0255i((((EGWint)(vals_in->channel.r) * 30) +
                                                      ((EGWint)(vals_in->channel.g) * 59) +
                                                      ((EGWint)(vals_in->channel.b) * 11)) / 100);
                *(pxls_out+1) = vals_in->channel.a;
                
                vals_in = (const egwColorRGBA*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorRGBA) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R5G6B5: {
            while(count--) {
                register EGWbyte temp1 = (EGWbyte)((((EGWint)(vals_in->channel.r) * 1000) / 8225) & 0x1f);
                register EGWbyte temp2 = (EGWbyte)((((EGWint)(vals_in->channel.g) * 1000) / 4047) & 0x3f);
                register EGWbyte temp3 = (EGWbyte)((((EGWint)(vals_in->channel.b) * 1000) / 8225) & 0x1f);
                *(pxls_out+1) = (temp1 << 3) | (temp2 >> 3);
                *(pxls_out) = ((temp2 & 0x07) << 5) | (temp3);
                
                vals_in = (const egwColorRGBA*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorRGBA) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R5G5B5A1: {
            while(count--) {
                register EGWbyte temp1 = (EGWbyte)((((EGWint)(vals_in->channel.r) * 1000) / 8225) & 0x1f);
                register EGWbyte temp2 = (EGWbyte)((((EGWint)(vals_in->channel.g) * 1000) / 8225) & 0x1f);
                register EGWbyte temp3 = (EGWbyte)((((EGWint)(vals_in->channel.b) * 1000) / 8225) & 0x1f);
                register EGWbyte temp4 = (EGWbyte)((vals_in->channel.a / 129) & 0x01);
                *(pxls_out+1) = (temp1 << 3) | (temp2 >> 2);
                *(pxls_out) = ((temp2 & 0x03) << 6) | (temp3 << 1) | (temp4);
                
                vals_in = (const egwColorRGBA*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorRGBA) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R4G4B4A4: {
            while(count--) {
                register EGWbyte temp1 = (EGWbyte)((vals_in->channel.r / 17) & 0x0f);
                register EGWbyte temp2 = (EGWbyte)((vals_in->channel.g / 17) & 0x0f);
                register EGWbyte temp3 = (EGWbyte)((vals_in->channel.b / 17) & 0x0f);
                register EGWbyte temp4 = (EGWbyte)((vals_in->channel.a / 17) & 0x0f);
                *(pxls_out+1) = (temp1 << 4) | (temp2);
                *(pxls_out) = (temp3 << 4) | (temp4);
                
                vals_in = (const egwColorRGBA*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorRGBA) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R8G8B8: {
            while(count--) {
                *(pxls_out) = vals_in->channel.r;
                *(pxls_out+1) = vals_in->channel.g;
                *(pxls_out+2) = vals_in->channel.b;
                
                vals_in = (const egwColorRGBA*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorRGBA) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(3 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        case EGW_SURFACE_FRMT_R8G8B8A8: {
            while(count--) {
                *(pxls_out) = vals_in->channel.r;
                *(pxls_out+1) = vals_in->channel.g;
                *(pxls_out+2) = vals_in->channel.b;
                *(pxls_out+3) = vals_in->channel.a;
                
                vals_in = (const egwColorRGBA*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwColorRGBA) + strideB_in);
                pxls_out = (EGWbyte*)((EGWintptr)pxls_out + (EGWintptr)(4 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
    }
}

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

/// @file egwFonts.m
/// @ingroup geWizES_gfx_fonts
/// Font Assets Implementations.

#import "egwFonts.h"
#import "../sys/egwSysTypes.h"
#import "../sys/egwGfxContext.h"
#import "../sys/egwAssetManager.h"
#import "../math/egwVector.h"
#import "../gfx/egwGraphics.h"
#import "../geo/egwGeometry.h"


// !!!: ***** egwBitmappedFont *****

@implementation egwBitmappedFont

- (id)init {
    if([self isMemberOfClass:[egwBitmappedFont class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent glyphSet:(egwAMGlyphSet*)glyphSet glyphColor:(egwColorRGBA*)glyphColor {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwBitmappedFontBase alloc] initWithIdentity:assetIdent glyphSet:glyphSet])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    if(glyphColor) memcpy((void*)&_gColor, (const void*)glyphColor, sizeof(egwColorRGBA));
    else memset((void*)&_gColor, 0, sizeof(egwColorRGBA));
    if(_gColor.channel.a == 0) _gColor.channel.a = 255;
    
    _gSet = [_base glyphSet];
    
    return self;
}

- (id)initLoadedFromResourceFile:(NSString*)resourceFile withIdentity:(NSString*)assetIdent fontEffects:(EGWuint)effects pointSize:(EGWsingle)ptSize glyphColor:(egwColorRGBA*)glyphColor {
    egwAMGlyphSet glyphSet; memset((void*)&glyphSet, 0, sizeof(egwAMGlyphSet));
    
    if(!([egwSIAsstMngr loadGlyphMap:&glyphSet fromFile:resourceFile withEffects:effects pointSize:ptSize])) {
        for(EGWchar charIndex = 33; charIndex <= 126; ++charIndex) {
            if(glyphSet.glyphs[charIndex - 33].gaData) {
                free((void*)(glyphSet.glyphs[charIndex - 33].gaData));
                glyphSet.glyphs[charIndex - 33].gaData = NULL;
            }
        }
        [self release]; return (self = nil);
    }
    
    if(!(self = [self initWithIdentity:assetIdent glyphSet:&glyphSet glyphColor:glyphColor])) {
        for(EGWchar charIndex = 33; charIndex <= 126; ++charIndex) {
            if(glyphSet.glyphs[charIndex - 33].gaData) {
                free((void*)(glyphSet.glyphs[charIndex - 33].gaData));
                glyphSet.glyphs[charIndex - 33].gaData = NULL;
            }
        }
        return nil;
    }
    
    return self;
}

- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent glyphColor:(egwColorRGBA*)glyphColor {
    if(!([asset isKindOfClass:[self class]]) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = (egwBitmappedFontBase*)[[asset assetBase] retain])) { [self release]; return (self = nil); }
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    if(glyphColor) memcpy((void*)&_gColor, (const void*)glyphColor, sizeof(egwColorRGBA));
    else memset((void*)&_gColor, 0, sizeof(egwColorRGBA));
    if(_gColor.channel.a == 0) _gColor.channel.a = 255;
    
    _gSet = [_base glyphSet];
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwBitmappedFont* copy = nil;
    NSString* copyIdent = nil;
    
    if([_ident hasSuffix:@"_default"])
        copyIdent = [[NSString alloc] initWithFormat:@"%@_%d", [_base identity], [_base nextInstanceIndex]];
    else copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwBitmappedFont allocWithZone:zone] initCopyOf:self
                                                     withIdentity:copyIdent
                                                       glyphColor:&_gColor])) {
        NSLog(@"egwBitmappedFont: copyWithZone: Failure initializing new font from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    return copy;
}

- (void)dealloc {
    [_base release]; _base = nil;
    [_ident release]; _ident = nil;
    
    [super dealloc];
}

- (void)calculateString:(const EGWchar*)text renderSize:(egwSize2i*)size {
    if(text && size) {
        EGWuint16 lineSize = 0;
        const egwBGlyph* glyph = NULL;
        
        size->span.width = 0;
        size->span.height = (EGWuint16)_gSet->lHeight;
        
        while(*text != '\0') {
            if(*text >= 33 && *text <= 126) {
                glyph = &(_gSet->glyphs[*text - 33]);
                
                // Give extra space at front of line in case the initial xOffset is negative
                if(!(lineSize == 0 && glyph->xOffset < 0))
                    lineSize += (EGWint16)glyph->xAdvance;
                else
                    lineSize += (EGWint16)glyph->xAdvance + (EGWint16)-glyph->xOffset;
                
                // Give extra space at the character prior to end of line in case the total width is greater than the advance
                if(!(*(text + 1) < ' ' && (EGWint16)glyph->xAdvance < (EGWint16)glyph->xOffset + (EGWint16)glyph->gWidth)) {
                    if(glyph->hasKerning)
                        lineSize += egwFindKerningOffset(_gSet->kerns, _gSet->kernSets, *text, *(text + 1), glyph->kernIndex);
                } else
                    lineSize += ((EGWint16)glyph->xOffset + (EGWint16)glyph->gWidth) - (EGWint16)glyph->xAdvance;
                
                size->span.width = egwMax2ui16(size->span.width, lineSize);
            } else if(*text == ' ') {
                lineSize += (EGWint16)_gSet->sAdvance;
                size->span.width = egwMax2ui16(size->span.width, lineSize);
            } else if(*text == '\n') {
                lineSize = 0;
                size->span.height += (EGWint16)_gSet->lHeight;
            }
            
            ++text;
        }
    }
}

- (void)calculateText:(NSString*)text renderSize:(egwSize2i*)size {
    if(text) [self calculateString:(EGWchar*)[text UTF8String] renderSize:size];
}

- (void)renderString:(const EGWchar*)text toSurface:(egwSurface*)surface atCursor:(egwPoint2i*)cursor {
    if(!cursor) cursor = &egwSIPointZero2i;
    
    if(text && surface) {
        egwPoint2i csr = { cursor->axis.x, cursor->axis.y };
        const egwBGlyph* glyph = NULL;
        EGWint gRow, gCol, sRow, sCol;
        EGWuint gPitch, Bpp = (surface->format & EGW_SURFACE_FRMT_EXBPP) >> 3;
        egwColorGS* gAdr = NULL;
        EGWuintptr gScanline, sScanline;
        BOOL atFront = YES;
        
        switch(surface->format & EGW_SURFACE_FRMT_EXKIND) {
            case EGW_SURFACE_FRMT_GS8: {
                egwColorGS gColor; egwPxlWriteRGBAb(EGW_SURFACE_FRMT_GS8, &_gColor, (EGWbyte*)&gColor);
                egwColorGS* sAdr = NULL;
                
                while(*text != '\0' && (csr.axis.x < surface->size.span.width || *text == '\n') && csr.axis.y < surface->size.span.height) {
                    if(*text >= 33 && *text <= 126) {
                        glyph = &(_gSet->glyphs[*text - 33]);
                        gPitch = (EGWuint)(glyph->gWidth) * (EGWuint)sizeof(egwColorGS);
                        
                        if(atFront && glyph->xOffset < 0)
                            csr.axis.x += (EGWint16)-glyph->xOffset;
                        
                        gScanline = (EGWuintptr)(glyph->gaData);
                        sRow = csr.axis.y + _gSet->lHeight - _gSet->lOffset - glyph->yOffset - glyph->gHeight;
                        sScanline = ((EGWuintptr)(surface->data) + ((EGWuintptr)sRow * (EGWuintptr)(surface->pitch)) + ((EGWuintptr)(csr.axis.x + glyph->xOffset) * (EGWuintptr)Bpp));
                        
                        for(gRow = 0; gRow < glyph->gHeight && sRow < surface->size.span.height; ++gRow, ++sRow) {
                            if(sRow >= 0) {
                                gAdr = (egwColorGS*)gScanline;
                                sAdr = (egwColorGS*)sScanline;
                                
                                for(gCol = 0, sCol = csr.axis.x + glyph->xOffset; gCol < glyph->gWidth && sCol < surface->size.span.width; ++gCol, ++sCol) {
                                    if(sCol >= 0 && gAdr->channel.l)
                                        sAdr->channel.l = (EGWbyte)egwClamp0255i((((EGWint)(gColor.channel.l) * (EGWint)(gAdr->channel.l)) + (((EGWint)(sAdr->channel.l) * (255 - (EGWint)(gAdr->channel.l))))) / 255);
                                    
                                    gAdr = (egwColorGS*)((EGWuintptr)gAdr + (EGWuintptr)sizeof(egwColorGS));
                                    sAdr = (egwColorGS*)((EGWuintptr)sAdr + (EGWuintptr)Bpp);
                                }
                            }
                            
                            gScanline += (EGWuintptr)gPitch;
                            sScanline += (EGWuintptr)(surface->pitch);
                        }
                        
                        csr.axis.x += (EGWint16)glyph->xAdvance;
                        atFront = NO;
                        
                        if(glyph->hasKerning)
                            csr.axis.x += egwFindKerningOffset(_gSet->kerns, _gSet->kernSets, *text, *(text + 1), glyph->kernIndex);
                    } else if(*text == ' ') {
                        csr.axis.x += (EGWint16)_gSet->sAdvance;
                        atFront = NO;
                    } else if(*text == '\n') {
                        csr.axis.x = cursor->axis.x;
                        csr.axis.y += (EGWuint16)_gSet->lHeight;
                        atFront = YES;
                    }
                    
                    ++text;
                }
            } break;
            
            case EGW_SURFACE_FRMT_GS8A8: {
                egwColorGSA gColor; egwPxlWriteRGBAb(EGW_SURFACE_FRMT_GS8A8, &_gColor, (EGWbyte*)&gColor);
                egwColorGSA* sAdr = NULL;
                
                while(*text != '\0' && (csr.axis.x < surface->size.span.width || *text == '\n') && csr.axis.y < surface->size.span.height) {
                    if(*text >= 33 && *text <= 126) {
                        glyph = &(_gSet->glyphs[*text - 33]);
                        gPitch = (EGWuint)(glyph->gWidth) * (EGWuint)sizeof(egwColorGS);
                        
                        if(atFront && glyph->xOffset < 0)
                            csr.axis.x += (EGWint16)-glyph->xOffset;
                        
                        gScanline = (EGWuintptr)(glyph->gaData);
                        sRow = csr.axis.y + _gSet->lHeight - _gSet->lOffset - glyph->yOffset - glyph->gHeight;
                        sScanline = ((EGWuintptr)(surface->data) + ((EGWuintptr)sRow * (EGWuintptr)(surface->pitch)) + ((EGWuintptr)(csr.axis.x + glyph->xOffset) * (EGWuintptr)Bpp));
                        
                        for(gRow = 0; gRow < glyph->gHeight && sRow < surface->size.span.height; ++gRow, ++sRow) {
                            if(sRow >= 0) {
                                gAdr = (egwColorGS*)gScanline;
                                sAdr = (egwColorGSA*)sScanline;
                                
                                for(gCol = 0, sCol = csr.axis.x + glyph->xOffset; gCol < glyph->gWidth && sCol < surface->size.span.width; ++gCol, ++sCol) {
                                    if(sCol >= 0 && gAdr->channel.l) {
                                        sAdr->channel.l = (EGWbyte)egwClamp0255i((((EGWint)(gColor.channel.l) * (EGWint)(gAdr->channel.l)) + (((EGWint)(sAdr->channel.l) * (255 - (EGWint)(gAdr->channel.l))))) / 255);
                                        sAdr->channel.a = (EGWbyte)egwClamp0255i((((EGWint)(gColor.channel.a) * (EGWint)(gAdr->channel.l)) + (((EGWint)(sAdr->channel.a) * (255 - (EGWint)(gAdr->channel.l))))) / 255);
                                    }
                                    
                                    gAdr = (egwColorGS*)((EGWuintptr)gAdr + (EGWuintptr)sizeof(egwColorGS));
                                    sAdr = (egwColorGSA*)((EGWuintptr)sAdr + (EGWuintptr)Bpp);
                                }
                            }
                            
                            gScanline += (EGWuintptr)gPitch;
                            sScanline += (EGWuintptr)(surface->pitch);
                        }
                        
                        csr.axis.x += (EGWint16)glyph->xAdvance;
                        atFront = NO;
                        
                        if(glyph->hasKerning)
                            csr.axis.x += egwFindKerningOffset(_gSet->kerns, _gSet->kernSets, *text, *(text + 1), glyph->kernIndex);
                    } else if(*text == ' ') {
                        csr.axis.x += (EGWint16)_gSet->sAdvance;
                        atFront = NO;
                    } else if(*text == '\n') {
                        csr.axis.x = cursor->axis.x;
                        csr.axis.y += (EGWuint16)_gSet->lHeight;
                        atFront = YES;
                    }
                    
                    ++text;
                }
            } break;
            
            case EGW_SURFACE_FRMT_R5G6B5:
            case EGW_SURFACE_FRMT_R8G8B8: {
                egwColorRGB sColor;
                EGWbyte* sAdr = NULL;
                
                while(*text != '\0' && (csr.axis.x < surface->size.span.width || *text == '\n') && csr.axis.y < surface->size.span.height) {
                    if(*text >= 33 && *text <= 126) {
                        glyph = &(_gSet->glyphs[*text - 33]);
                        gPitch = (EGWuint)(glyph->gWidth) * (EGWuint)sizeof(egwColorGS);
                        
                        if(atFront && glyph->xOffset < 0)
                            csr.axis.x += (EGWint16)-glyph->xOffset;
                        
                        gScanline = (EGWuintptr)(glyph->gaData);
                        sRow = csr.axis.y + _gSet->lHeight - _gSet->lOffset - glyph->yOffset - glyph->gHeight;
                        sScanline = ((EGWuintptr)(surface->data) + ((EGWuintptr)sRow * (EGWuintptr)(surface->pitch)) + ((EGWuintptr)(csr.axis.x + glyph->xOffset) * (EGWuintptr)Bpp));
                        
                        for(gRow = 0; gRow < glyph->gHeight && sRow < surface->size.span.height; ++gRow, ++sRow) {
                            if(sRow >= 0) {
                                gAdr = (egwColorGS*)gScanline;
                                sAdr = (EGWbyte*)sScanline;
                                
                                for(gCol = 0, sCol = csr.axis.x + glyph->xOffset; gCol < glyph->gWidth && sCol < surface->size.span.width; ++gCol, ++sCol) {
                                    if(sCol >= 0 && gAdr->channel.l) {
                                        egwPxlReadRGBb(surface->format, (EGWbyte*)sAdr, &sColor);
                                        sColor.channel.r = (EGWbyte)egwClamp0255i((((EGWint)(_gColor.channel.r) * (EGWint)(gAdr->channel.l)) + (((EGWint)(sColor.channel.r) * (255 - (EGWint)(gAdr->channel.l))))) / 255);
                                        sColor.channel.g = (EGWbyte)egwClamp0255i((((EGWint)(_gColor.channel.g) * (EGWint)(gAdr->channel.l)) + (((EGWint)(sColor.channel.g) * (255 - (EGWint)(gAdr->channel.l))))) / 255);
                                        sColor.channel.b = (EGWbyte)egwClamp0255i((((EGWint)(_gColor.channel.b) * (EGWint)(gAdr->channel.l)) + (((EGWint)(sColor.channel.b) * (255 - (EGWint)(gAdr->channel.l))))) / 255);
                                        egwPxlWriteRGBb(surface->format, &sColor, (EGWbyte*)sAdr);
                                    }
                                    
                                    gAdr = (egwColorGS*)((EGWuintptr)gAdr + (EGWuintptr)sizeof(egwColorGS));
                                    sAdr = (EGWbyte*)((EGWuintptr)sAdr + (EGWuintptr)Bpp);
                                }
                            }
                            
                            gScanline += (EGWuintptr)gPitch;
                            sScanline += (EGWuintptr)(surface->pitch);
                        }
                        
                        csr.axis.x += (EGWint16)glyph->xAdvance;
                        atFront = NO;
                        
                        if(glyph->hasKerning)
                            csr.axis.x += egwFindKerningOffset(_gSet->kerns, _gSet->kernSets, *text, *(text + 1), glyph->kernIndex);
                    } else if(*text == ' ') {
                        csr.axis.x += (EGWint16)_gSet->sAdvance;
                        atFront = NO;
                    } else if(*text == '\n') {
                        csr.axis.x = cursor->axis.x;
                        csr.axis.y += (EGWuint16)_gSet->lHeight;
                        atFront = YES;
                    }
                    
                    ++text;
                }
            } break;
            
            case EGW_SURFACE_FRMT_R5G5B5A1:
            case EGW_SURFACE_FRMT_R4G4B4A4:
            case EGW_SURFACE_FRMT_R8G8B8A8: {
                egwColorRGBA sColor;
                EGWbyte* sAdr = NULL;
                
                while(*text != '\0' && (csr.axis.x < surface->size.span.width || *text == '\n') && csr.axis.y < surface->size.span.height) {
                    if(*text >= 33 && *text <= 126) {
                        glyph = &(_gSet->glyphs[*text - 33]);
                        gPitch = (EGWuint)(glyph->gWidth) * (EGWuint)sizeof(egwColorGS);
                        
                        if(atFront && glyph->xOffset < 0)
                            csr.axis.x += (EGWint16)-glyph->xOffset;
                        
                        gScanline = (EGWuintptr)(glyph->gaData);
                        sRow = csr.axis.y + _gSet->lHeight - _gSet->lOffset - glyph->yOffset - glyph->gHeight;
                        sScanline = ((EGWuintptr)(surface->data) + ((EGWuintptr)sRow * (EGWuintptr)(surface->pitch)) + ((EGWuintptr)(csr.axis.x + glyph->xOffset) * (EGWuintptr)Bpp));
                        
                        for(gRow = 0; gRow < glyph->gHeight && sRow < surface->size.span.height; ++gRow, ++sRow) {
                            if(sRow >= 0) {
                                gAdr = (egwColorGS*)gScanline;
                                sAdr = (EGWbyte*)sScanline;
                                
                                for(gCol = 0, sCol = csr.axis.x + glyph->xOffset; gCol < glyph->gWidth && sCol < surface->size.span.width; ++gCol, ++sCol) {
                                    if(sCol >= 0 && gAdr->channel.l) {
                                        egwPxlReadRGBAb(surface->format, (EGWbyte*)sAdr, &sColor);
                                        sColor.channel.r = (EGWbyte)egwClamp0255i((((EGWint)(_gColor.channel.r) * (EGWint)(gAdr->channel.l)) + (((EGWint)(sColor.channel.r) * (255 - (EGWint)(gAdr->channel.l))))) / 255);
                                        sColor.channel.g = (EGWbyte)egwClamp0255i((((EGWint)(_gColor.channel.g) * (EGWint)(gAdr->channel.l)) + (((EGWint)(sColor.channel.g) * (255 - (EGWint)(gAdr->channel.l))))) / 255);
                                        sColor.channel.b = (EGWbyte)egwClamp0255i((((EGWint)(_gColor.channel.b) * (EGWint)(gAdr->channel.l)) + (((EGWint)(sColor.channel.b) * (255 - (EGWint)(gAdr->channel.l))))) / 255);
                                        sColor.channel.a = (EGWbyte)egwClamp0255i((((EGWint)(_gColor.channel.a) * (EGWint)(gAdr->channel.l)) + (((EGWint)(sColor.channel.a) * (255 - (EGWint)(gAdr->channel.l))))) / 255);
                                        egwPxlWriteRGBAb(surface->format, &sColor, (EGWbyte*)sAdr);
                                    }
                                    
                                    gAdr = (egwColorGS*)((EGWuintptr)gAdr + (EGWuintptr)sizeof(egwColorGS));
                                    sAdr = (EGWbyte*)((EGWuintptr)sAdr + (EGWuintptr)Bpp);
                                }
                            }
                            
                            gScanline += (EGWuintptr)gPitch;
                            sScanline += (EGWuintptr)(surface->pitch);
                        }
                        
                        csr.axis.x += (EGWint16)glyph->xAdvance;
                        atFront = NO;
                        
                        if(glyph->hasKerning)
                            csr.axis.x += egwFindKerningOffset(_gSet->kerns, _gSet->kernSets, *text, *(text + 1), glyph->kernIndex);
                    } else if(*text == ' ') {
                        csr.axis.x += (EGWint16)_gSet->sAdvance;
                        atFront = NO;
                    } else if(*text == '\n') {
                        csr.axis.x = cursor->axis.x;
                        csr.axis.y += (EGWuint16)_gSet->lHeight;
                        atFront = YES;
                    }
                    
                    ++text;
                }
            } break;
            
            default: { NSLog(@"egwBitmappedFont: renderString:toSurface:atCursor: Unrecognized or unsupported surface format."); } break;
        }
    }
}

- (void)renderText:(NSString*)text toSurface:(egwSurface*)surface atCursor:(egwPoint2i*)cursor {
    if(text && surface) [self renderString:(const EGWchar*)[text UTF8String] toSurface:surface atCursor:cursor];
}

- (id<egwPAssetBase>)assetBase {
    return _base;
}

- (EGWuint)coreObjectTypes {
    return EGW_COREOBJ_TYPE_FONT;
}

- (NSString*)identity {
    return _ident;
}

- (egwColorRGBA*)glyphColor {
    return &_gColor;
}

@end


// !!!: ***** egwBitmappedFontBase *****

@implementation egwBitmappedFontBase

+ (id)allocWithZone:(NSZone*)zone {
    id alloc = [super allocWithZone:zone];
    if(alloc) [egwAssetManager incBaseRef];
    if(EGW_ENGINE_ASSETS_CREATIONMSGS) NSLog(@"egwBitmappedFontBase: allocWithZone: Creating new bitmapped font base asset (%p).", alloc);
    return alloc;
}

- (id)init {
    if([self isMemberOfClass:[egwBitmappedFontBase class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent glyphSet:(egwAMGlyphSet*)glyphSet {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    memset((void*)&_gSet, 0, sizeof(egwAMGlyphSet));
    
    if(glyphSet) {
        memcpy((void*)&_gSet, (const void*)glyphSet, sizeof(egwAMGlyphSet));
        memset((void*)glyphSet, 0, sizeof(egwAMGlyphSet));
    } else { [self release]; return (self = nil); }
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    return nil;
}

- (id)mutableCopyWithZone:(NSZone*)zone {
    return nil;
}

- (void)dealloc {
    for(EGWchar charIndex = 33; charIndex <= 126; ++charIndex) {
        if(_gSet.glyphs[charIndex - 33].gaData) {
            free((void*)(_gSet.glyphs[charIndex - 33].gaData));
            _gSet.glyphs[charIndex - 33].gaData = NULL;
        }
    }
    if(_gSet.kerns) {
        free((void*)_gSet.kerns);
        _gSet.kerns = NULL;
    }
    
    if(EGW_ENGINE_ASSETS_DESTROYMSGS) NSLog(@"egwBitmappedFontBase: dealloc: Destroying bitmapped font base asset '%@' (%p).", _ident, self);
    [_ident release]; _ident = nil;
    [egwAssetManager decBaseRef];
    [super dealloc];
}

- (const egwAMGlyphSet*)glyphSet {
    return &_gSet;
}

- (NSString*)identity {
    return _ident;
}

- (EGWuint)nextInstanceIndex {
    return ++_instCounter;
}

@end

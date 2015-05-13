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

/// @defgroup geWizES_gfx_fonts egwFonts
/// @ingroup geWizES_gfx
/// Font Assets.
/// @{

/// @file egwFonts.h
/// Font Assets Interfaces.

#import "egwGfxTypes.h"
#import "../inf/egwPAsset.h"
#import "../inf/egwPAssetBase.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPGfxContext.h"
#import "../inf/egwPFont.h"


/// Bitmapped Font Instance Asset.
/// Contains unique instance data relating to bitmapped fonts.
@interface egwBitmappedFont : NSObject <egwPAsset, egwPFont> {
    egwBitmappedFontBase* _base;            ///< Base object instance (retained).
    NSString* _ident;                       ///< Unique identity (retained).
    
    egwColorRGBA _gColor;                   ///< Glyph color.
    
    const egwAMGlyphSet* _gSet;             ///< Alphamapped glyph set (aliased).
}

/// Designated Initializer.
/// Initializes the bitmapped font asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] glyphSet Glyph mapping set (contents ownership transfer).
/// @param [in] glyphColor Glyph foreground color.
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent glyphSet:(egwAMGlyphSet*)glyphSet glyphColor:(egwColorRGBA*)glyphColor;

/// Loaded Font Initializer.
/// Initializes the bitmapped font asset from a loaded surface with provided settings.
/// @param [in] resourceFile Resource file to load from.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] effects Font rasterization effects (EGW_FONT_EFCT_*).
/// @param [in] ptSize Point size of font.
/// @param [in] glyphColor Glyph foreground color.
/// @return Self upon success, otherwise nil. 
- (id)initLoadedFromResourceFile:(NSString*)resourceFile withIdentity:(NSString*)assetIdent fontEffects:(EGWuint)effects pointSize:(EGWsingle)ptSize glyphColor:(egwColorRGBA*)glyphColor;

/// Copy Initializer.
/// Copies a bitmapped font asset with provided unique settings.
/// @param [in] asset Asset to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] glyphColor Glyph foreground color.
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent glyphColor:(egwColorRGBA*)glyphColor;


/// Glyph Color Accessor.
/// Returns the glyph's foreground color.
/// @return Glyph color.
- (egwColorRGBA*)glyphColor;

@end


/// Bitmapped Font Asset Base.
/// Contains shared instance data relating to bitmapped fonts.
@interface egwBitmappedFontBase : NSObject <egwPAssetBase> {
    EGWuint _instCounter;                   ///< Instantiation counter.
    NSString* _ident;                       ///< Unique identity (retained).
    
    egwAMGlyphSet _gSet;                    ///< Alphamapped glyph set (owned).
}

/// Designated Initializer.
/// Initializes the bitmapped font asset base with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] glyphSet Glyph mapping set (contents ownership transfer).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent glyphSet:(egwAMGlyphSet*)glyphSet;


/// Glyph Set Accessor.
/// Returns the base glyph mapping set.
/// @note Ownership transfer is not allowed.
/// @return Glyph set.
- (const egwAMGlyphSet*)glyphSet;

@end

/// @}

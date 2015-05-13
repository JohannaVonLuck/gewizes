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

/// @defgroup geWizES_gfx_materials egwMaterials
/// @ingroup geWizES_gfx
/// Material Assets.
/// @{

/// @file egwMaterials.h
/// Material Assets Interfaces.

#import "egwGfxTypes.h"
#import "../inf/egwPAsset.h"
#import "../inf/egwPAssetBase.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPGfxContext.h"
#import "../inf/egwPInterpolator.h"
#import "../inf/egwPMaterial.h"
#import "../misc/egwMiscTypes.h"


/// Material Instance Asset.
/// Contains instance data relating to basic materials.
@interface egwMaterial : NSObject <egwPAsset, egwPMaterial, egwDValidationEvent> {
    NSString* _ident;                       ///< Unique identity (retained).
    
    BOOL _isSBound;                         ///< Surfacing binding status.
    EGWuint _lastSBind;                     ///< Last surfacing binding stage.
    egwValidater* _sSync;                   ///< Surfacing binding sync (retained).
    id<egwPInterpolator> _mdIpo;            ///< Material driver interpolator (retained).
    
    egwMaterial4f _sMat;                    ///< Surfacing material.
}

/// Designated Initializer.
/// Initializes the material asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] srfcgMat Surfacing material. May be NULL (for default).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent surfacingMaterial:(egwMaterial4f*)srfcgMat;

/// Initializer.
/// Initializes the material asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] ambColor Material ambient color. May be NULL (for default).
/// @param [in] dfsColor Material diffuse color. May be NULL (for default).
/// @param [in] spcColor Material specular color. May be NULL (for default).
/// @param [in] emsColor Material emmisive color. May be NULL (for default).
/// @param [in] shineExp Material shininess exponent [0,1].
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent ambientColor:(const egwColor4f*)ambColor diffuseColor:(const egwColor4f*)dfsColor specularColor:(const egwColor4f*)spcColor emmisiveColor:(const egwColor4f*)emsColor shininessExponent:(const EGWsingle)shineExp;

/// Copy Initializer.
/// Copies a material asset with provided unique settings.
/// @param [in] asset Asset to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent;


/// Material Accessor.
/// Returns the base material data.
/// @return Material data.
- (egwMaterial4f*)material;

/// Material Driver Accessor.
/// Returns the material driver interpolator.
/// @return Material driver.
- (id<egwPInterpolator>)materialDriver;


/// Material Mutator.
/// Sets the base material data.
/// @param [in] srfcgMat Surfacing material. May be NULL (for default).
- (void)setMaterial:(egwMaterial4f*)srfcgMat;

/// Material Ambient Color Mutator.
/// Sets the base material ambient color data.
/// @param [in] ambColor Material ambient color. May be NULL (for default).
- (void)setMaterialAmbientColor:(const egwColor4f*)ambColor;

/// Material Diffuse Color Mutator.
/// Sets the base material diffuse color data.
/// @param [in] dfsColor Material diffuse color. May be NULL (for default).
- (void)setMaterialDiffuseColor:(const egwColor4f*)dfsColor;

/// Material Specular Color Mutator.
/// Sets the base material specular color data.
/// @param [in] spcColor Material specular color. May be NULL (for default).
- (void)setMaterialSpecularColor:(const egwColor4f*)spcColor;

/// Material Emmisive Color Mutator.
/// Sets the base material emmisive color data.
/// @param [in] emsColor Material emmisive color. May be NULL (for default).
- (void)setMaterialEmmisiveColor:(const egwColor4f*)emsColor;

/// Material Shininess Exponent Mutator.
/// Sets the base material shininess exponent data.
/// @param [in] shineExp Material shininess exponent. May be NULL (for default).
- (void)setMaterialShininessExponent:(const egwColor1f*)shineExp;


/// Material Driver Tryer.
/// Attempts to set the material's material driver to @a matIpo.
/// @param [in] matIpo Material driver (retained).
/// @return YES if interpolator driver is accepted, otherwise NO.
- (BOOL)trySetMaterialDriver:(id<egwPInterpolator>)matIpo;

@end


/// Color Instance Asset.
/// Contains instance data relating to a color material.
@interface egwColor : NSObject <egwPAsset, egwPMaterial, egwDValidationEvent> {
    NSString* _ident;                       ///< Unique identity (retained).
    
    BOOL _isSBound;                         ///< Surfacing binding status.
    EGWuint _lastSBind;                     ///< Last surfacing binding stage.
    egwValidater* _sSync;                   ///< Surfacing binding sync (retained).
    id<egwPInterpolator> _cdIpo;            ///< Coloring driver interpolator (retained).
    
    egwColor4f _sColor;                     ///< Surfacing color.
}

/// Designated Initializer.
/// Initializes the color asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] srfcgColor Surfacing color. May be NULL (for default).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent surfacingColor:(const egwColor4f*)srfcgColor;

/// Initializer.
/// Initializes the color asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] rgb Coloring rgb color. May be NULL (for default).
/// @param [in] alpha Coloring opacity color [0,1].
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent rgbColor:(const egwColor3f*)rgb alphaColor:(const EGWsingle)alpha;

/// Initializer.
/// Initializes the color asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] red Coloring red color [0,1].
/// @param [in] green Coloring green color [0,1].
/// @param [in] blue Coloring blue color [0,1].
/// @param [in] alpha Coloring opacity color [0,1].
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent redColor:(const EGWsingle)red greenColor:(const EGWsingle)green blueColor:(const EGWsingle)blue alphaColor:(const EGWsingle)alpha;

/// Copy Initializer.
/// Copies a color asset with provided unique settings.
/// @param [in] asset Asset to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent;


/// Coloring Accessor.
/// Returns the base coloring data.
/// @return Coloring data.
- (const egwColor4f*)coloring;

/// Coloring Driver Accessor.
/// Returns the coloring driver interpolator.
/// @return Coloring driver.
- (id<egwPInterpolator>)coloringDriver;


/// Coloring Mutator.
/// Sets the base coloring data.
/// @param [in] srfcgColor Surfacing color. May be NULL (for default).
- (void)setColoring:(const egwColor4f*)srfcgColor;

/// Coloring RGB Color Mutator.
/// Sets the base coloring RGB color data.
/// @param [in] rgb Coloring rgb color. May be NULL (for default).
- (void)setColoringRGBColor:(const egwColor3f*)rgb;

/// Coloring Red Color Mutator.
/// Sets the base coloring red color data.
/// @param [in] red Coloring red color. May be NULL (for default).
- (void)setColoringRedColor:(const egwColor1f*)red;

/// Coloring Green Color Mutator.
/// Sets the base coloring green color data.
/// @param [in] green Coloring green color. May be NULL (for default).
- (void)setColoringGreenColor:(const egwColor1f*)green;

/// Coloring Blue Color Mutator.
/// Sets the base coloring blue color data.
/// @param [in] blue Coloring blue color. May be NULL (for default).
- (void)setColoringBlueColor:(const egwColor1f*)blue;

/// Coloring Alpha Color Mutator.
/// Sets the base coloring alpha color data.
/// @param [in] alpha Coloring opacity color. May be NULL (for default).
- (void)setColoringAlphaColor:(const egwColor1f*)alpha;


/// Coloring Driver Tryer.
/// Attempts to set the material's coloring driver to @a clrIpo.
/// @param [in] clrIpo Coloring driver (retained).
/// @return YES if interpolator driver is accepted, otherwise NO.
- (BOOL)trySetColoringDriver:(id<egwPInterpolator>)clrIpo;

@end


/// Shade Instance Asset.
/// Contains instance data relating to a shade material.
@interface egwShade : NSObject <egwPAsset, egwPMaterial, egwDValidationEvent> {
    NSString* _ident;                       ///< Unique identity (retained).
    
    BOOL _isSBound;                         ///< Surfacing binding status.
    EGWuint _lastSBind;                     ///< Last surfacing binding stage.
    egwValidater* _sSync;                   ///< Surfacing binding sync (retained).
    id<egwPInterpolator> _sdIpo;            ///< Shading driver interpolator (retained).
    
    egwColor2f _sShade;                     ///< Surfacing shade.
}

/// Designated Initializer.
/// Initializes the shade asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] srfcgShade Surfacing shade. May be NULL (for default).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent surfacingShade:(const egwColor2f*)srfcgShade;

/// Initializer.
/// Initializes the shade asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] lum Shading luminance color [0,1].
/// @param [in] alpha Shading opacity color [0,1].
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent luminanceColor:(const EGWsingle)lum alphaColor:(const EGWsingle)alpha;

/// Copy Initializer.
/// Copies a shade asset with provided unique settings.
/// @param [in] asset Asset to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent;


/// Shading Accessor.
/// Returns the base shading data.
/// @return Shading data.
- (const egwColor2f*)shading;

/// Shading Driver Accessor.
/// Returns the shading driver interpolator.
/// @return Shading driver.
- (id<egwPInterpolator>)shadingDriver;


/// Shading Mutator.
/// Sets the base shading data.
/// @param [in] srfcgShade Surfacing shade. May be NULL (for default).
- (void)setShading:(const egwColor2f*)srfcgShade;

/// Shading Luminance Color Mutator.
/// Sets the base shading luminance color data.
/// @param [in] lum Shading luminance color. May be NULL (for default).
- (void)setShadingLuminanceColor:(const egwColor1f*)lum;

/// Shading Alpha Color Mutator.
/// Sets the base shading alpha color data.
/// @param [in] alpha Shading opacity color. May be NULL (for default).
- (void)setShadingAlphaColor:(const egwColor1f*)alpha;


/// Shading Driver Tryer.
/// Attempts to set the material's shading driver to @a shdIpo.
/// @param [in] shdIpo Shading driver (retained).
/// @return YES if interpolator driver is accepted, otherwise NO.
- (BOOL)trySetShadingDriver:(id<egwPInterpolator>)shdIpo;

@end

/// @}

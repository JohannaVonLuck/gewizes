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

/// @defgroup geWizES_gfx_lights egwLights
/// @ingroup geWizES_gfx
/// Light Assets.
/// @{

/// @file egwLights.h
/// Light Assets Interfaces.

#import "egwGfxTypes.h"
#import "../inf/egwPAsset.h"
#import "../inf/egwPObjLeaf.h"
#import "../inf/egwPAssetBase.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPGfxContext.h"
#import "../inf/egwPBounding.h"
#import "../inf/egwPLight.h"
#import "../math/egwMathTypes.h"
#import "../obj/egwObjTypes.h"
#import "../misc/egwMiscTypes.h"


/// Point Light Instance Asset.
/// Contains unique instance data relating to point lights.
@interface egwPointLight : NSObject <egwPAsset, egwPObjectLeaf, egwPLight> {
    egwLightBase* _base;                    ///< Base object instance (retained).
    NSString* _ident;                       ///< Unique identity (retained).
    BOOL _invkParent;                       ///< Parent invocation tracking.
    BOOL _ortPending;                       ///< Orientation transforms pending.
    BOOL _isIlluminating;                   ///< Tracks illumination status.
    id<egwPObjectBranch> _parent;           ///< Parent node (weak).
    
    EGWuint _iFlags;                        ///< Illumination flags.
    BOOL _isIBound;                         ///< Illumination binding status.
    EGWuint _lastIBind;                     ///< Last illumination binding stage.
    egwValidater* _iSync;                   ///< Illumination binding sync (retained).
    
    egwMatrix44f _wcsTrans;                 ///< Orientation transform (LCS->WCS).
    egwMatrix44f _lcsTrans;                 ///< Offset transform (MMCS->LCS).
    id<egwPBounding> _wcsIBVol;             ///< Light illumination volume (WCS, retained).
    id<egwPInterpolator> _wcsIpo;           ///< Orientation driver interpolator (retained).
    id<egwPInterpolator> _lcsIpo;           ///< Offset driver interpolator (retained).
    
    const egwMaterial4f* _lMat;             ///< Light illumination material (aliased).
    const egwAttenuation3f* _lAtten;        ///< Light illumination attenuation (MCS, aliased).
}

/// Designated Initializer.
/// Initializes the point light asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] illumRadius Light illumination LCS radius. May be EGW_SFLT_MAX (for infinite).
/// @param [in] illumMat Light illumination material (retained). May be NULL (for default).
/// @param [in] illumAtten Light illumination attenuation. May be NULL (for default).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent lightRadius:(EGWsingle)illumRadius lightMaterial:(egwMaterial4f*)illumMat lightAttenuation:(egwAttenuation3f*)illumAtten;

/// Copy Initializer.
/// Copies a point light asset with provided unique settings.
/// @param [in] asset Asset to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent;


/// Illumination Radius Accessor.
/// Returns the light's WCS illumination radius.
/// @return WCS illumination radius, or EGW_SFLT_MAX if infinite.
- (EGWsingle)illuminationRadius;

@end


/// Directional Light Instance Asset.
/// Contains unique instance data relating to directional lights.
@interface egwDirectionalLight : NSObject <egwPAsset, egwPObjectLeaf, egwPLight> {
    egwLightBase* _base;                    ///< Base object instance (retained).
    NSString* _ident;                       ///< Unique identity (retained).
    BOOL _invkParent;                       ///< Parent invocation tracking.
    BOOL _ortPending;                       ///< Orientation transforms pending.
    BOOL _isIlluminating;                   ///< Tracks illumination status.
    id<egwPObjectBranch> _parent;           ///< Parent node (weak).
    
    EGWuint _iFlags;                        ///< Illumination flags.
    BOOL _isIBound;                         ///< Illumination binding status.
    EGWuint _lastIBind;                     ///< Last illumination binding stage.
    egwValidater* _iSync;                   ///< Illumination binding sync (retained).
    
    egwMatrix44f _wcsTrans;                 ///< Orientation transform (LCS->WCS).
    egwMatrix44f _lcsTrans;                 ///< Offset transform (MMCS->LCS).
    egwVector4f _wcsDir;                    ///< Light illumination direction (WCS).
    id<egwPInterpolator> _wcsIpo;           ///< Orientation driver interpolator (retained).
    id<egwPInterpolator> _lcsIpo;           ///< Offset driver interpolator (retained).
    
    const egwMaterial4f* _lMat;             ///< Light illumination material (aliased).
    const egwAttenuation3f* _lAtten;        ///< Light illumination attenuation (MCS, aliased).
}

/// Designated Initializer.
/// Initializes the directional light asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] illumDir Light illumination LCS direction. May be nil (for negative unit-Z vector).
/// @param [in] illumMat Light illumination material (retained). May be NULL (for default).
/// @param [in] illumAtten Light illumination attenuation. May be NULL (for default).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent lightDirection:(egwVector3f*)illumDir lightMaterial:(egwMaterial4f*)illumMat lightAttenuation:(egwAttenuation3f*)illumAtten;

/// Copy Initializer.
/// Copies a directional light asset with provided unique settings.
/// @param [in] asset Asset to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent;


/// Illumination Direction Accessor.
/// Returns the light's WCS illumination direction.
/// @return WCS illumination direction.
- (const egwVector4f*)illuminationDirection;

@end


/// Spot Light Instance Asset.
/// Contains unique instance data relating to spot lights.
@interface egwSpotLight : NSObject <egwPAsset, egwPObjectLeaf, egwPLight> {
    egwLightBase* _base;                    ///< Base object instance (retained).
    NSString* _ident;                       ///< Unique identity (retained).
    BOOL _invkParent;                       ///< Parent invocation tracking.
    BOOL _ortPending;                       ///< Orientation transforms pending.
    BOOL _isIlluminating;                   ///< Tracks illumination status.
    id<egwPObjectBranch> _parent;           ///< Parent node (weak).
    
    EGWuint _iFlags;                        ///< Illumination flags.
    BOOL _isIBound;                         ///< Illumination binding status.
    EGWuint _lastIBind;                     ///< Last illumination binding stage.
    egwValidater* _iSync;                   ///< Illumination binding sync (retained).
    
    egwMatrix44f _wcsTrans;                 ///< Orientation transform (LCS->WCS).
    egwMatrix44f _lcsTrans;                 ///< Offset transform (MMCS->LCS).
    egwVector4f _wcsDir;                    ///< Light illumination direction (WCS).
    id<egwPBounding> _wcsIBVol;             ///< Light illumination volume (WCS, retained).
    id<egwPInterpolator> _wcsIpo;           ///< Orientation driver interpolator (retained).
    id<egwPInterpolator> _lcsIpo;           ///< Offset driver interpolator (retained).
    
    const egwMaterial4f* _lMat;             ///< Light illumination material (aliased).
    const egwAttenuation3f* _lAtten;        ///< Light illumination attenuation (MCS, aliased).
    EGWsingle _lAngle;                      ///< Light illumination angle (repeated).
    EGWsingle _lExponent;                   ///< Light illumination exponent (repeated).
}

/// Designated Initializer.
/// Initializes the spot light asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] illumDir Light illumination LCS direction. May be nil (for negative unit-Z vector).
/// @param [in] illumAngle Light illumination angle [0,90] (degrees).
/// @param [in] illumExp Light illumination exponent [0,1].
/// @param [in] illumMat Light illumination material (retained). May be NULL (for default).
/// @param [in] illumAtten Light illumination attenuation. May be NULL (for default).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent lightDirection:(egwVector3f*)illumDir lightAngle:(EGWsingle)illumAngle lightExponent:(EGWsingle)illumExp lightMaterial:(egwMaterial4f*)illumMat lightAttenuation:(egwAttenuation3f*)illumAtten;

/// Copy Initializer.
/// Copies a spot light asset with provided unique settings.
/// @param [in] asset Asset to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent;


/// Illumination Direction Accessor.
/// Returns the light's illumination angle.
/// @return illumination angle.
- (EGWsingle)illuminationAngle;

/// Illumination Direction Accessor.
/// Returns the light's WCS illumination direction.
/// @return WCS illumination direction.
- (const egwVector4f*)illuminationDirection;

/// Illumination Direction Accessor.
/// Returns the light's illumination exponent.
/// @return illumination exponent.
- (EGWsingle)illuminationExponent;

@end


/// Light Asset Base.
/// Contains shared instance data relating to lights.
/// @note Triples up for base to egwPointLight, egwDirectionalLight, and egwSpotLight - not all fields are used.
@interface egwLightBase : NSObject <egwPAssetBase> {
    EGWuint _instCounter;                   ///< Instantiation counter.
    NSString* _ident;                       ///< Unique identity (retained).
    id<egwPGfxContext> _gfxContext;         ///< Associated graphics context (retained).
    
    egwVector4f _mmcsDir;                   ///< Light illumination direction (MMCS).
    id<egwPBounding> _mmcsIBVol;            ///< Light illumination volume (MMCS).
    egwMaterial4f _lMat;                    ///< Light illumination material.
    egwAttenuation3f _lAtten;               ///< Light illumination attenuation (MCS).
}

/// Designated Initializer.
/// Initializes the light asset base with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] illumDir Light illumination MCS direction. May be nil (for negative unit-Z vector).
/// @param [in] illumVol Light illumination MCS volume (retained).
/// @param [in] illumMat Light illumination material. May be NULL (for default).
/// @param [in] illumAtten Light illumination attenuation. May be NULL (for default).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent lightDirection:(egwVector3f*)illumDir lightVolume:(id<egwPBounding>)illumVol lightMaterial:(egwMaterial4f*)illumMat lightAttenuation:(egwAttenuation3f*)illumAtten;


/// Offset (byTransform) Method.
/// Offsets the light base data in the MCS by the provided @a transform for subsequent render passes.
/// @note Base offsetting will cause untracked sync invalidation to shared object instances!
/// @param [in] transform MCS->MMCS transformation matrix.
- (void)baseOffsetByTransform:(const egwMatrix44f*)transform;


/// Illumination Attenuation Accessor.
/// Returns the base MCS illumination attenuation.
/// @return Illumination attenuation.
- (const egwAttenuation3f*)illuminationAttenuation;

/// Illumination Bounding Volume Accessor.
/// Returns the base MMCS illumination bounding volume.
/// @return Illumination bounding volume (MMCS).
- (id<egwPBounding>)illuminationBounding;

/// Illumination Direction Accessor.
/// Returns the base MMCS illumination direction.
/// @return Illumination direction (MMCS).
- (const egwVector4f*)illuminationDirection;

/// Illumination Material Accessor.
/// Returns the base illumination material.
/// @return Illumination material.
- (const egwMaterial4f*)illuminationMaterial;

@end

/// @}

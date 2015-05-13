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

/// @defgroup geWizES_gui_image egwImage
/// @ingroup geWizES_gui
/// Image Widget.
/// @{

/// @file egwImage.h
/// Image Widget Interface.

#import "egwGuiTypes.h"
#import "../inf/egwPAsset.h"
#import "../inf/egwPAssetBase.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPSubTask.h"
#import "../inf/egwPGfxContext.h"
#import "../inf/egwPWidget.h"
#import "../sys/egwSysTypes.h"
#import "../math/egwMathTypes.h"
#import "../gfx/egwGfxTypes.h"
#import "../obj/egwObjTypes.h"
#import "../misc/egwMiscTypes.h"


/// Image Widget.
/// Contains unique instance data relating to a basic 2-D image capable of being oriented & rendered (both 2D & 3D).
@interface egwImage : NSObject <egwPAsset, egwPWidget, egwDValidationEvent> {
    egwImageBase* _base;                    ///< Base object instance (retained).
    NSString* _ident;                       ///< Unique identity (retained).
    BOOL _invkParent;                       ///< Parent invocation tracking.
    BOOL _ortPending;                       ///< Orientation transforms pending.
    BOOL _isRendering;                      ///< Tracks rendering status.
    id<egwPObjectBranch> _parent;           ///< Parent node (weak).
    id<egwDWidgetEvent> _delegate;          ///< Event responder delegate (retained).
    
    EGWuint32 _rFlags;                      ///< Rendering flags.
    EGWuint16 _rFrame;                      ///< Rendering frame number.
    egwValidater* _rSync;                   ///< Rendering order sync (retained).
    egwLightStack* _lStack;                 ///< Light illumination stack (retained).
    egwMaterialStack* _mStack;              ///< Material rendering stack (retained).
    egwShaderStack* _sStack;                ///< Shader program stack (retained).
    
    BOOL _isEnabled;                        ///< Tracks event responders status.
    BOOL _isVisible;                        ///< Tracks visibility status.
    
    BOOL _isTBound;                         ///< Texturing binding status.
    EGWuint _lastTBind;                     ///< Last texturing binding stage.
    EGWuint _texEnv;                        ///< Texture fragmentation environment.
    egwValidater* _tSync;                   ///< Texturing binding sync (retained).
    
    egwMatrix44f _wcsTrans;                 ///< Orientation transform (LCS->WCS).
    egwMatrix44f _lcsTrans;                 ///< Offset transform (MMMCS->LCS).
    id<egwPBounding> _wcsRBVol;             ///< Optical volume (WCS, retained).
    id<egwPInterpolator> _wcsIpo;           ///< Orientation driver interpolator (retained).
    id<egwPInterpolator> _lcsIpo;           ///< Offset driver interpolator (retained).
    
    const EGWuint* _texID;                  ///< Texture identifier (aliased).
    const egwMatrix44f* _mcsTrans;          ///< Base offset transform (MCS->MMCS, aliased).
    const egwSQVAMesh4f* _iMesh;            ///< Image mesh data (MCS, aliased).
    const EGWuint* _geoAID;                 ///< Geometry buffer arrays identifier (aliased).
}

/// Designated Initializer.
/// Initializes the image asset with provided settings.
/// @note Non-power-of-two surfaces may be used, but will be smudge extended to a power-of-two surface.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] surface Image surface data (contents ownership transfer).
/// @param [in] width Image widget width (may be 0 for surface derivation, MCS).
/// @param [in] height Image widget height (may be 0 for surface derivation, MCS).
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] environment Texture fragmentation environment setting (EGW_TEXTURE_FENV_*).
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @param [in] shdrStack Associated shader stack (retained). May be nil (uses default).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent imageSurface:(egwSurface*)surface imageWidth:(EGWuint16)width imageHeight:(EGWuint16)height geometryStorage:(EGWuint)storage textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack shaderStack:(egwShaderStack*)shdrStack;

/// Blank Image Initializer.
/// Initializes the image asset as a blank surface with provided settings.
/// @note Non-power-of-two surfaces may be used, but will be smudge extended to a power-of-two surface.
/// @note This method does not clear/set-to-zero the allocated surface prior to return.
/// @note Once surface is prepared, one should invalidate the texture buffer sync to start the buffering sequence.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] format Image surface format (EGW_SURFACE_FRMT_*). May be 0 (for EGW_SURFACE_FRMT_R8G8B8A8).
/// @param [in] width Image widget width (MCS).
/// @param [in] height Image widget height (MCS).
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] environment Texture fragmentation environment setting (EGW_TEXTURE_FENV_*).
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @param [in] shdrStack Associated shader stack (retained). May be nil (uses default).
/// @return Self upon success, otherwise nil.
- (id)initBlankWithIdentity:(NSString*)assetIdent surfaceFormat:(EGWuint32)format imageWidth:(EGWuint16)width imageHeight:(EGWuint16)height geometryStorage:(EGWuint)storage textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack shaderStack:(egwShaderStack*)shdrStack;

/// Loaded Image Initializer.
/// Initializes the image asset from a loaded surface with provided settings.
/// @note Non-power-of-two surfaces may be used, but will be smudge extended to a power-of-two surface.
/// @param [in] resourceFile Resource file to load from.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] width Image widget width (may be 0 for surface derivation, MCS).
/// @param [in] height Image widget height (may be 0 for surface derivation, MCS).
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] environment Texture fragmentation environment setting (EGW_TEXTURE_FENV_*).
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @param [in] shdrStack Associated shader stack (retained). May be nil (uses default).
/// @return Self upon success, otherwise nil.
- (id)initLoadedFromResourceFile:(NSString*)resourceFile withIdentity:(NSString*)assetIdent imageWidth:(EGWuint16)width imageHeight:(EGWuint16)height geometryStorage:(EGWuint)storage textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack shaderStack:(egwShaderStack*)shdrStack;

/// Copy Initializer.
/// Copies an image asset with provided unique settings.
/// @param [in] widget Widget to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPWidget>)widget withIdentity:(NSString*)assetIdent;


/// Delegate Mutator.
/// Sets the widget's event responder delegate to @a delegate.
/// @param [in] delegate Event responder delegate (retained).
- (void)setDelegate:(id<egwDWidgetEvent>)delegate;

@end


/// Image Widget Base.
/// Contains shared instance data relating to a simple 2-D image capable of being oriented & rendered (both 2D & 3D).
@interface egwImageBase : NSObject <egwPAssetBase, egwPSubTask, egwDValidationEvent> {
    EGWuint _instCounter;                   ///< Instantiation counter.
    NSString* _ident;                       ///< Unique identity (retained).
    
    egwSurface _iSrfc;                      ///< Image surface (MCS, contents owned).
    egwSize2i _iSize;                       ///< Image size (MCS).
    egwSQVAMesh4f _iMesh;                   ///< Image mesh data (MCS).
    
    egwValidater* _gbSync;                  ///< Geometry buffer sync (retained).
    EGWuint _geoAID;                        ///< Geometry buffer arrays identifier.
    EGWuint _geoStrg;                       ///< Geometry storage/VBO setting.
    
    egwValidater* _tbSync;                  ///< Texture buffer sync (retained).
    EGWuint _texID;                         ///< Texture identifier.
    EGWuint _texTrans;                      ///< Texturing transforms.
    EGWuint _texFltr;                       ///< Texturing filter.
    
    egwMatrix44f _mcsTrans;                 ///< Base offset transform (MCS->MMCS).
    id<egwPBounding> _mmcsRBVol;            ///< Optical volume (MMCS, retained).
    
    BOOL _isTDPersist;                      ///< Tracks surface persistence status.
}

/// Designated Initializer.
/// Initializes the image asset base with provided settings.
/// @note Non-power-of-two surfaces may be used, but will be smudge extended to a power-of-two surface.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] surface Image surface data (contents ownership transfer).
/// @param [in] width Image widget width (may be 0 for surface derivation, MCS).
/// @param [in] height Image widget height (may be 0 for surface derivation, MCS).
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent imageSurface:(egwSurface*)surface imageWidth:(EGWuint16)width imageHeight:(EGWuint16)height geometryStorage:(EGWuint)storage texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter;

/// Blank Image Initializer.
/// Initializes the image asset base as a blank surface with provided settings.
/// @note Non-power-of-two surfaces may be used, but will be smudge extended to a power-of-two surface.
/// @note This method does not clear/set-to-zero the allocated surface prior to return.
/// @note Once surface is prepared, one should invalidate the texturing sync to start the buffering sequence.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] format Image surface format (EGW_SURFACE_FRMT_*). May be 0 (for EGW_SURFACE_FRMT_R8G8B8A8).
/// @param [in] width Image widget width (MCS).
/// @param [in] height Image widget height (MCS).
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @return Self upon success, otherwise nil.
- (id)initBlankWithIdentity:(NSString*)assetIdent surfaceFormat:(EGWuint32)format imageWidth:(EGWuint16)width imageHeight:(EGWuint16)height geometryStorage:(EGWuint)storage texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter;


/// Base Offset (byTransform) Method.
/// Offsets the widget's base data in the MCS by the provided @a transform for subsequent render passes.
/// @param [in] transform MCS->MMCS transformation matrix.
- (void)baseOffsetByTransform:(const egwMatrix44f*)transform;

/// Base Offset (byZeroAlign) Method.
/// Offsets the widget's base data in the MCS by the provided @a zfAlign axis extents edges for subsequent render passes.
/// @param [in] zfAlign Zero offset alignment mode (EGW_GFXOBJ_ZFALIGN_*)
- (void)baseOffsetByZeroAlign:(EGWuint)zfAlign;


/// Geometry Arrays ID Accessor.
/// Returns the base context referenced geometry arrays identifier.
/// @note Ownership transfer is not allowed.
/// @return Geometry arrays identifier.
- (const EGWuint*)geometryArraysID;

/// Geometry Buffer Syncronization Validater Accessor.
/// Returns the validater that manages component synchronization with a hardware buffer.
/// @return Geometry buffer validater, otherwise nil (if unused).
- (egwValidater*)geometryBufferSync;

/// Geometry Storage Accessor.
/// Returns the geometry storage/VBO setting.
/// @return Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
- (EGWuint)geometryStorage;

/// MCS->MMCS Transform Accessor.
/// Returns the object's MCS->MMCS transformation matrix.
/// @return MCS->MMCS transform.
- (const egwMatrix44f*)mcsTransform;

/// Rendering Bounding Volume Accessor.
/// Returns the base MMCS rendering bounding volume.
/// @return Rendering bounding volume (MMCS).
- (id<egwPBounding>)renderingBounding;

/// Texture Buffer Syncronization Validater Accessor.
/// Returns the validater that manages component synchronization with a hardware buffer.
/// @return Texture buffer validater.
- (egwValidater*)textureBufferSync;

/// Texture ID Accessor.
/// Returns the base context referenced texture identifier.
/// @note Ownership transfer is not allowed.
/// @return Texture identifier.
- (const EGWuint*)textureID;

/// Texturing Transforms Accessor.
/// Returns the base texture transforms settings.
/// @return Texturing transforms (EGW_TEXTURE_TRFM_*).
- (EGWuint)texturingTransforms;

/// Texturing Filter Accessor.
/// Returns the base texture filtering setting.
/// @return Texturing filter (EGW_TEXTURE_FLTR_*).
- (EGWuint)texturingFilter;

/// Texturing Edge Wrapping (S-Axis) Accessor.
/// Returns the base texture s-axis edge wrapping setting.
/// @return Texturing s-axis edge wrapping (EGW_TEXTURE_WRAP_*).
- (EGWuint16)texturingSWrap;

/// Texturing Edge Wrapping (T-Axis) Accessor.
/// Returns the base texture t-axis edge wrapping setting.
/// @return Texturing t-axis edge wrapping (EGW_TEXTURE_WRAP_*).
- (EGWuint16)texturingTWrap;

/// Widget Mesh Accessor.
/// Returns the widget's base MCS mesh data.
/// @return Mesh data (MCS).
- (const egwSQVAMesh4f*)widgetMesh;

/// Widget Size Accessor.
/// Returns the widget's MCS size.
/// @return Widget size (MCS).
- (const egwSize2i*)widgetSize;

/// Widget Surface Accessor.
/// Returns the widget's base surface data (if available).
/// @return Surface data, otherwise NULL (if unavailable).
- (const egwSurface*)widgetSurface;


/// Geometry Buffer Data Persistence Trier.
/// Attempts to set the persistence of local data for the geometry buffer to @a persist.
/// @param [in] persist Persistence setting of local buffer data.
/// @return YES if setting was successfully changed, otherwise NO.
- (BOOL)trySetGeometryDataPersistence:(BOOL)persist;

/// Geometry Storage Tryer.
/// Attempts to set the geometry environment setting to @a environment.
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @return YES if setting was successfully changed, otherwise NO.
- (BOOL)trySetGeometryStorage:(EGWuint)storage;

/// Texture Buffer Data Persistence Tryer.
/// Attempts to set the persistence of local data for the texture buffer to @a persist.
/// @param [in] persist Persistence setting of local buffer data.
/// @return YES if setting was successfully changed, otherwise NO.
- (BOOL)trySetTextureDataPersistence:(BOOL)persist;

/// Texturing Filter Tryer.
/// Attempts to set the texturing filter setting to @a filter.
/// @note Changing texture filtering may require a total texture reprocessing/load.
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @return YES if setting was successfully changed, otherwise NO.
- (BOOL)trySetTexturingFilter:(EGWuint)filter;

/// Texturing Edge Wrapping (S-Axis) Tryer.
/// Attempts to set the texture environment setting to @a sWrap.
/// @param [in] sWrap Texturing s-axis edge wrapping setting (EGW_TEXTURE_WRAP_*).
/// @return YES if setting was successfully changed, otherwise NO.
- (BOOL)trySetTexturingWrapS:(EGWuint16)sWrap;

/// Texturing Edge Wrapping (T-Axis) Tryer.
/// Attempts to set the texture environment setting to @a tWrap.
/// @param [in] tWrap Texturing t-axis edge wrapping setting (EGW_TEXTURE_WRAP_*).
/// @return YES if setting was successfully changed, otherwise NO.
- (BOOL)trySetTexturingWrapT:(EGWuint16)tWrap;


/// IsGeometryDataPersistent Poller.
/// Polls the object to determine status.
/// @return YES if geometry buffer is persistent, otherwise NO.
- (BOOL)isGeometryDataPersistent;

/// IsTextureDataPersistent Poller.
/// Polls the object to determine status.
/// @return YES if texture buffer is persistent, otherwise NO.
- (BOOL)isTextureDataPersistent;

@end

/// @}

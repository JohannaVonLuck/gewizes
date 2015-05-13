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

/// @defgroup geWizES_gui_spritedimage egwSpritedImage
/// @ingroup geWizES_gui
/// Animated Sprited Image Asset.
/// @{

/// @file egwSpritedImage.h
/// Animated Sprited Image Asset Interface.

#import "egwGuiTypes.h"
#import "../inf/egwPAsset.h"
#import "../inf/egwPAssetBase.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPSubTask.h"
#import "../inf/egwPGfxContext.h"
#import "../inf/egwPTimed.h"
#import "../inf/egwPTimer.h"
#import "../inf/egwPWidget.h"
#import "../sys/egwSysTypes.h"
#import "../math/egwMathTypes.h"
#import "../gfx/egwGfxTypes.h"
#import "../obj/egwObjTypes.h"
#import "../misc/egwMiscTypes.h"


/// Sprited Image Widget.
/// Contains unique instance data relating to a sprited 2-D image capable of being oriented & rendered (both 2D & 3D).
@interface egwSpritedImage : NSObject <egwPAsset, egwPSubTask, egwPTimed, egwPWidget, egwDValidationEvent> {
    egwSpritedImageBase* _base;             ///< Base object instance (retained).
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
    
    BOOL _isEnabled;                        ///< Tracks event responders status.
    BOOL _isVisible;                        ///< Tracks visibility status.
    EGWint16 _fIndex;                       ///< Current frame index.
    EGWint16 _sIndex;                       ///< Current surface index.    
    EGWsingle _sFPS;                        ///< Frames-per-second speed.
    struct {
        egwVector2f stCoords[4];            ///< Sprite texture coords (MCS).
    } _isMesh;                              ///< Sprite instance mesh data (MCS).
    id<egwPTimer> _eTimer;                  ///< Evaluation timer (retained).
    
    egwValidater* _gbSync;                  ///< Geometry buffer sync (retained).
    EGWuint _geoAID;                        ///< Geometry buffer arrays identifier.
    EGWuint _geoStrg;                       ///< Geometry storage.
    
    BOOL _isTBound;                         ///< Texturing binding status.
    EGWuint _lastTBind;                     ///< Last texturing binding stage.
    EGWuint _texEnv;                        ///< Texture fragmentation environment.
    egwValidater* _tSync;                   ///< Texturing binding sync (retained).
    
    egwMatrix44f _wcsTrans;                 ///< Orientation transform (LCS->WCS).
    egwMatrix44f _lcsTrans;                 ///< Offset transform (MMCS->LCS).
    id<egwPBounding> _wcsRBVol;             ///< Optical volume (WCS, retained).
    id<egwPInterpolator> _wcsIpo;           ///< Orientation driver interpolator (retained).
    id<egwPInterpolator> _lcsIpo;           ///< Offset driver interpolator (retained).
    
    EGWuint16 _fCount;                      ///< Total frames count (repeated).
    EGWuint16 _sCount;                      ///< Total surfaces count (repeated).
    const egwSurfaceFraming* _sFrames;      ///< Surface frames (aliased).
    EGWuint const * const * _texIDs;        ///< Texture identifiers (aliased).
    const egwMatrix44f* _mcsTrans;          ///< Base offset transform (MCS->MMCS, aliased).
    const egwSQVAMesh4f* _sMesh;            ///< Sprite mesh data (MCS, aliased).
    const EGWuint* _baseGeoAID;             ///< Base geometry buffer arrays identifier (aliased).
}

/// Designated Initializer.
/// Initializes the sprited image asset with provided settings.
/// @note Non-power-of-two surfaces may be used, but will be smudge extended to a power-of-two surface.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] surfaces Sprite surfaces' data (contents ownership transfer).
/// @param [in,out] framings Sprite surfaces' framing (contents copy).
/// @param [in] srfcCount Sprite surfaces count.
/// @param [in] width Sprite widget width (may be 0 for surface derivation, MCS).
/// @param [in] height Sprite widget height (may be 0 for surface derivation, MCS).
/// @param [in] fps Sprite frames-per-second (may be 0 for 25).
/// @param [in] instStorage Instance geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] baseStorage Base geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] environment Texture fragmentation environment setting (EGW_TEXTURE_FENV_*).
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent spriteSurfaces:(egwSurface*)surfaces surfaceFramings:(egwSurfaceFraming*)framings surfaceCount:(EGWuint16)srfcCount spriteWidth:(EGWuint16)width spriteHeight:(EGWuint16)height spriteFPS:(EGWsingle)fps instanceGeometryStorage:(EGWuint)instStorage baseGeometryStorage:(EGWuint)baseStorage textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack;

/// Blank Sprited Image Initializer.
/// Initializes the sprited image asset as a blank surface with provided settings.
/// @note Non-power-of-two surfaces may be used, but will be smudge extended to a power-of-two surface.
/// @note This method does not clear/set-to-zero the allocated surface prior to return.
/// @note Once surface is prepared, one should invalidate the texture buffer sync to start the buffering sequence.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] format Sprite surface format (EGW_SURFACE_FRMT_*). May be 0 (for EGW_SURFACE_FRMT_R8G8B8A8).
/// @param [in] width Sprite widget width (MCS).
/// @param [in] height Sprite widget height (MCS).
/// @param [in] frmCount Sprite frames count [2,inf].
/// @param [in] fps Sprite frames-per-second (may be 0 for 25).
/// @param [in] instStorage Instance geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] baseStorage Base geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] environment Texture fragmentation environment setting (EGW_TEXTURE_FENV_*).
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @return Self upon success, otherwise nil.
- (id)initBlankWithIdentity:(NSString*)assetIdent surfaceFormat:(EGWuint32)format spriteWidth:(EGWuint16)width spriteHeight:(EGWuint16)height frameCount:(EGWuint16)frmCount spriteFPS:(EGWsingle)fps instanceGeometryStorage:(EGWuint)instStorage baseGeometryStorage:(EGWuint)baseStorage textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack;

/// Loaded Sprited Image Initializer.
/// Initializes the sprited image asset from a loaded surface with provided settings.
/// @note Non-power-of-two surfaces may be used, but will be smudge extended to a power-of-two surface.
/// @param [in] resourceFiles Resource files to load from (separated by ';').
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] width Sprite widget width (may be 0 for surface derivation, MCS).
/// @param [in] height Sprite widget height (may be 0 for surface derivation, MCS).
/// @param [in] fps Sprite frames-per-second (may be 0 for 25).
/// @param [in] instStorage Instance geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] baseStorage Base geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] environment Texture fragmentation environment setting (EGW_TEXTURE_FENV_*).
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @return Self upon success, otherwise nil.
- (id)initLoadedFromResourceFiles:(NSString*)resourceFiles withIdentity:(NSString*)assetIdent spriteWidth:(EGWuint16)width spriteHeight:(EGWuint16)height spriteFPS:(EGWsingle)fps instanceGeometryStorage:(EGWuint)instStorage baseGeometryStorage:(EGWuint)baseStorage textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack;

/// Copy Initializer.
/// Copies an sprite asset with provided unique settings.
/// @param [in] widget Widget to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPWidget>)widget withIdentity:(NSString*)assetIdent;


/// Sprite FPS Accessor.
/// Returns the sprite's frames-per-second time evaluator.
/// @return Sprite's frmaes-per-second.
- (EGWsingle)spriteFPS;


/// Delegate Mutator.
/// Sets the widget's event responder delegate to @a delegate.
/// @param [in] delegate Event responder delegate (retained).
- (void)setDelegate:(id<egwDWidgetEvent>)delegate;

/// Sprite FPS Mutator.
/// Sets the sprite's frames-per-second time evaluator.
/// @param [in] fps Sprite frames-per-second (may be 0 for 25).
/// note This method doesn't update the current animation frame.
- (void)setSpriteFPS:(EGWsingle)fps;

@end


/// Sprited Image Widget Base.
/// Contains shared instance data relating to a sprited 2-D image capable of being oriented & rendered (both 2D & 3D).
@interface egwSpritedImageBase : NSObject <egwPAssetBase, egwPSubTask, egwDValidationEvent> {
    EGWuint _instCounter;                   ///< Instantiation counter.
    NSString* _ident;                       ///< Unique identity (retained).
    
    EGWuint16 _fCount;                      ///< Total frames count.
    EGWuint16 _sCount;                      ///< Total surfaces count.
    egwSurface* _sSrfcs;                    ///< Sprite surfaces (MCS, contents owned).
    egwSurfaceFraming* _sFrames;            ///< Sprite surface framings (MCS).
    egwSize2i _sSize;                       ///< Sprite size (MCS).
    egwSQVAMesh4f _sMesh;                   ///< Sprite mesh data (MCS).
    
    egwValidater* _tbSync;                  ///< Texture buffer sync (retained).
    EGWuint* _texIDs;                       ///< Texture identifiers.
    EGWuint _texTrans;                      ///< Texturing transforms.
    EGWuint _texFltr;                       ///< Texturing filter.
    
    egwValidater* _gbSync;                  ///< Geometry buffer sync (retained).
    EGWuint _geoAID;                        ///< Geometry buffer arrays identifier.
    EGWuint _geoStrg;                       ///< Geometry storage/VBO setting.
    
    egwMatrix44f _mcsTrans;                 ///< Base offset transform (MCS->MMCS).
    id<egwPBounding> _mmcsRBVol;            ///< Optical volume (MMCS, retained).
    
    BOOL _isTDPersist;                      ///< Tracks surface persistence status.
}

/// Designated Initializer.
/// Initializes the sprited image asset base with provided settings.
/// @note Non-power-of-two surfaces may be used, but will be smudge extended to a power-of-two surface.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] surfaces Sprite surfaces' data (contents ownership transfer).
/// @param [in,out] framings Sprite surfaces' framing (contents copy).
/// @param [in] srfcCount Sprite surfaces count.
/// @param [in] width Sprite widget width (may be 0 for surface derivation, MCS).
/// @param [in] height Sprite widget height (may be 0 for surface derivation, MCS).
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent spriteSurfaces:(egwSurface*)surfaces surfaceFramings:(egwSurfaceFraming*)framings surfaceCount:(EGWuint16)srfcCount spriteWidth:(EGWuint16)width spriteHeight:(EGWuint16)height geometryStorage:(EGWuint)storage texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter;

/// Blank Image Initializer.
/// Initializes the sprited image asset base as a blank surface with provided settings.
/// @note Non-power-of-two surfaces may be used, but will be smudge extended to a power-of-two surface.
/// @note This method does not clear/set-to-zero the allocated surface prior to return.
/// @note Once surface is prepared, one should invalidate the texturing sync to start the buffering sequence.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] format Sprite surface format (EGW_SURFACE_FRMT_*). May be 0 (for EGW_SURFACE_FRMT_R8G8B8A8).
/// @param [in] width Sprite widget width (MCS).
/// @param [in] height Sprite widget height (MCS).
/// @param [in] frmCount Sprite frames count [2,inf].
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @return Self upon success, otherwise nil.
- (id)initBlankWithIdentity:(NSString*)assetIdent surfaceFormat:(EGWuint32)format spriteWidth:(EGWuint16)width spriteHeight:(EGWuint16)height frameCount:(EGWuint16)frmCount geometryStorage:(EGWuint)storage texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter;


/// Base Offset (byTransform) Method.
/// Offsets the widget's base data in the MCS by the provided @a transform for subsequent render passes.
/// @param [in] transform MCS->MMCS transformation matrix.
- (void)baseOffsetByTransform:(const egwMatrix44f*)transform;

/// Base Offset (byZeroAlign) Method.
/// Offsets the widget's base data in the MCS by the provided @a zfAlign axis extents edges for subsequent render passes.
/// @param [in] zfAlign Zero offset alignment mode (EGW_GFXOBJ_ZFALIGN_*)
- (void)baseOffsetByZeroAlign:(EGWuint)zfAlign;


/// Frame Count Accessor.
/// Returns the total number of frames for the sprite.
/// @return Frame count.
- (EGWuint16)frameCount;

/// Surface Count Accessor.
/// Returns the total number of surfaces for the sprite.
/// @return Surface count.
- (EGWuint16)surfaceCount;

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

/// Texture IDs Accessor.
/// Returns the base context referenced texture identifiers.
/// @note Ownership transfer is not allowed.
/// @return Texture identifiers.
- (EGWuint const * const *)textureIDs;

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

/// Widget Surface Framings Accessor.
/// Returns the widget's base surface framings (if available).
/// @return Surface framings, otherwise NULL (if unavailable).
- (const egwSurfaceFraming*)widgetFramings;

/// Widget Mesh Accessor.
/// Returns the widget's base MCS mesh data.
/// @return Mesh data (MCS).
- (const egwSQVAMesh4f*)widgetMesh;

/// Widget Size Accessor.
/// Returns the widget's MCS size.
/// @return Widget size (MCS).
- (const egwSize2i*)widgetSize;

/// Widget Surfaces Accessor.
/// Returns the widget's base surface datas (if available).
/// @return Surface datas, otherwise NULL (if unavailable).
- (const egwSurface*)widgetSurfaces;


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

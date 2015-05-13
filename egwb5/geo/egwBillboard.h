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

/// @defgroup geWizES_geo_billboard egwBillboard
/// @ingroup geWizES_geo
/// Billboard Asset.
/// @{

/// @file egwBillboard.h
/// Billboard Asset Interface.

#import "egwGeoTypes.h"
#import "../inf/egwPAsset.h"
#import "../inf/egwPObjLeaf.h"
#import "../inf/egwPAssetBase.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPGfxContext.h"
#import "../inf/egwPRenderable.h"
#import "../inf/egwPBounding.h"
#import "../inf/egwPGeometry.h"
#import "../inf/egwPLight.h"
#import "../inf/egwPMaterial.h"
#import "../inf/egwPTexture.h"
#import "../math/egwMathTypes.h"
#import "../gfx/egwGfxTypes.h"
#import "../obj/egwObjTypes.h"
#import "../misc/egwMiscTypes.h"


/// Billboard Instance Asset.
/// Contains unique instance data relating to basic camera-facing billboards.
@interface egwBillboard : NSObject <egwPAsset, egwPGeometry> {
    egwBillboardBase* _base;                ///< Base object instance (retained).
    NSString* _ident;                       ///< Unique identity (retained).
    BOOL _invkParent;                       ///< Parent invocation tracking.
    BOOL _ortPending;                       ///< Orientation transforms pending.
    BOOL _isRendering;                      ///< Tracks rendering status.
    id<egwPObjectBranch> _parent;           ///< Parent node (weak).
    id<egwDGeometryEvent> _delegate;        ///< Event responder delegate (retained).
    
    EGWuint32 _rFlags;                      ///< Rendering flags.
    EGWuint16 _rFrame;                      ///< Rendering frame number.
    EGWuint16 _vFrame;                      ///< Camera viewing frame number.
    id<egwPCamera> _vCamera;                ///< Camera viewing reference (weak).
    const egwMatrix44f* _vcwcsTrans;        ///< Camera viewing WCS transform (weak).
    egwValidater* _rSync;                   ///< Rendering order sync (retained).
    egwLightStack* _lStack;                 ///< Light illumination stack (retained).
    egwMaterialStack* _mStack;              ///< Material rendering stack (retained).
    egwTextureStack* _tStack;               ///< Texture mapping stack (retained).
    
    egwMatrix44f _twcsTrans;                ///< Total world transform (MMCS->WCS).
    egwMatrix44f _twcsInverse;              ///< Total world transform inverse (WCS->MMCS).
    egwMatrix44f _wcsTrans;                 ///< Orientation transform (LCS->WCS).
    egwMatrix44f _lcsTrans;                 ///< Offset transform (MMCS->LCS).
    egwMatrix44f _broTrans;                 ///< Billboard reorientation transform.
    id<egwPBounding> _wcsRBVol;             ///< Billboard optical volume (WCS, retained).
    id<egwPInterpolator> _wcsIpo;           ///< Orientation driver interpolator (retained).
    id<egwPInterpolator> _lcsIpo;           ///< Offset driver interpolator (retained).
    
    const egwMatrix44f* _mcsTrans;          ///< Base offset transform (MCS->MMCS, aliased).
    egwSTVAMeshf* _bMesh;                   ///< Billboard mesh data (aliased, MCS).
    const EGWuint* _geoAID;                 ///< Geometry buffer arrays identifier (aliased).
}

/// Designated Initializer.
/// Initializes the billboard asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] meshData Polygon mesh data (contents ownership transfer).
/// @param [in] bndClass Associated bounding class. May be nil (for default).
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @param [in] txtrStack Associated texture stack (retained). May be nil (for non-textured).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent staticMesh:(egwSTVAMeshf*)meshData billboardBounding:(Class)bndClass geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack textureStack:(egwTextureStack*)txtrStack;

/// Blank Mesh Initializer.
/// Initializes the billboard asset as a blank polygon set with provided settings.
/// @note This method does not clear/set-to-zero the allocated arrays prior to return.
/// @note After custom polygon initialization, reboundWithClass should be used to set the bounding volume.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] vrtxCount Polygon mesh vertex count.
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @param [in] txtrStack Associated texture stack (retained). May be nil (for non-textured).
/// @return Self upon success, otherwise nil.
- (id)initBlankWithIdentity:(NSString*)assetIdent vertexCount:(EGWuint16)vrtxCount geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack textureStack:(egwTextureStack*)txtrStack;

/// Quad Initializer.
/// Initializes the billboard asset as a quad created from provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] quadWidth Billboard width.
/// @param [in] quadHeight Billboard height.
/// @param [in] bndClass Associated bounding class. May be nil (for default).
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @param [in] txtrStack Associated texture stack (retained). May be nil (for non-textured).
/// @return Self upon success, otherwise nil.
- (id)initQuadWithIdentity:(NSString*)assetIdent quadWidth:(EGWsingle)quadWidth quadHeight:(EGWsingle)quadHeight billboardBounding:(Class)bndClass geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack textureStack:(egwTextureStack*)txtrStack;

/// Copy Initializer.
/// Copies a billboard asset with provided unique settings.
/// @param [in] geometry Geometry to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPGeometry>)geometry withIdentity:(NSString*)assetIdent;


/// Delegate Mutator.
/// Sets the billboard's event responder delegate to @a delegate.
/// @param [in] delegate Event responder delegate (retained).
- (void)setDelegate:(id<egwDGeometryEvent>)delegate;

@end


/// Billboard Asset Base.
/// Contains shared instance data relating to camera-facing billboards.
@interface egwBillboardBase : NSObject <egwPAssetBase, egwPSubTask, egwDValidationEvent> {
    EGWuint _instCounter;                   ///< Instantiation counter.
    NSString* _ident;                       ///< Unique identity (retained).
    
    EGWsingle _bWidth;                      ///< Billboard x-axis width (MMCS).
    EGWsingle _bHeight;                     ///< Billboard y-axis height (MMCS).
    egwSTVAMeshf _bMesh;                    ///< Billboard mesh data (MCS, contents owned).
    
    egwValidater* _gbSync;                  ///< Geometry buffer sync (retained).
    EGWuint _geoAID;                        ///< Geometry buffer arrays identifier.
    EGWuint _geoStrg;                       ///< Geometry storage/VBO setting.
    
    egwMatrix44f _mcsTrans;                 ///< Base offset transform (MCS->MMCS).
    id<egwPBounding> _mmcsRBVol;            ///< Billboard optical volume (MMCS, retained).
    
    BOOL _isGDPersist;                      ///< Tracks surface persistence status.
}

/// Designated Initializer.
/// Initializes the billboard asset base with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] meshData Polygon mesh data (contents ownership transfer).
/// @param [in] bndClass Associated bounding class. May be nil (for default).
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent staticMesh:(egwSTVAMeshf*)meshData billboardBounding:(Class)bndClass geometryStorage:(EGWuint)storage;

/// Blank Mesh Initializer.
/// Initializes the billboard asset base as a blank polygon set with provided settings.
/// @note This method does not clear/set-to-zero the allocated arrays prior to return.
/// @note After custom polygon initialization, reboundWithClass should be used to set the bounding volume.
/// @note Once mesh is prepared, one should invalidate the geometry buffer sync to start the buffering sequence.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] vrtxCount Polygon mesh vertex count.
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @return Self upon success, otherwise nil.
- (id)initBlankWithIdentity:(NSString*)assetIdent vertexCount:(EGWuint16)vrtxCount geometryStorage:(EGWuint)storage;

/// Quad Initializer.
/// Initializes the billboard asset base as a quad created from provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] quadWidth Billboard width.
/// @param [in] quadHeight Billboard height.
/// @param [in] bndClass Associated bounding class. May be nil (for default).
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @return Self upon success, otherwise nil.
- (id)initQuadWithIdentity:(NSString*)assetIdent quadWidth:(EGWsingle)quadWidth quadHeight:(EGWsingle)quadHeight billboardBounding:(Class)bndClass geometryStorage:(EGWuint)storage;


/// Base Offset (byTransform) Method.
/// Offsets the billboard base data in the MCS by the provided @a transform for subsequent render passes.
/// @note Base offsetting will cause untracked sync invalidation to shared object instances!
/// @param [in] transform MCS->MMCS transformation matrix.
- (void)baseOffsetByTransform:(const egwMatrix44f*)transform;

/// Base Offset (byZeroAlign) Method.
/// Offsets the billboard base data in the MCS by the provided @a zfAlign axis extents edges for subsequent render passes.
/// @note Base offsetting will cause untracked sync invalidation to shared object instances!
/// @param [in] zfAlign Zero offset alignment mode (EGW_GFXOBJ_ZFALIGN_*)
- (void)baseOffsetByZeroAlign:(EGWuint)zfAlign;

/// Rebound (withClass) Method.
/// Rebinds the base optical MCS bounding volume with provided @a bndClass class.
/// @param [in] bndClass Associated bounding class. May be nil (for egwBoundingSphere).
- (void)reboundWithClass:(Class)bndClass;


/// Billboard Mesh Data Accessor.
/// Returns the base billboard polygon MMCS mesh data.
/// @return Billboard mesh data (MMCS).
- (egwSTVAMeshf*)billboardMesh;

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


/// IsGeometryDataPersistent Poller.
/// Polls the object to determine status.
/// @return YES if geometry buffer is persistent, otherwise NO.
- (BOOL)isGeometryDataPersistent;

@end

/// @}

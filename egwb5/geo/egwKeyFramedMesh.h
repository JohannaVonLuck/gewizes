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

/// @defgroup geWizES_geo_keyframedmesh egwKeyFramedMesh
/// @ingroup geWizES_geo
/// Animated Key Framed Polygon Mesh Asset.
/// @{

/// @file egwKeyFramedMesh.h
/// Animated Key Framed Polygon Mesh Asset Interface.

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
#import "../phy/egwPhyTypes.h"
#import "../misc/egwMiscTypes.h"


/// Key Framed Polygon Mesh Instance Asset.
/// Contains unique instance data relating to animated indexed vertex key framed array meshes.
@interface egwKeyFramedMesh : NSObject <egwPAsset, egwPGeometry, egwPSubTask, egwPTimed> {
    egwKeyFramedMeshBase* _base;            ///< Base object instance (retained).
    NSString* _ident;                       ///< Unique identity (retained).
    BOOL _invkParent;                       ///< Parent invocation tracking.
    BOOL _ortPending;                       ///< Orientation transforms pending.
    BOOL _isRendering;                      ///< Tracks rendering status.
    id<egwPObjectBranch> _parent;           ///< Parent node (weak).
    id<egwDGeometryEvent> _delegate;        ///< Event responder delegate (retained).
    
    EGWuint32 _rFlags;                      ///< Rendering flags.
    EGWuint16 _rFrame;                      ///< Rendering frame number.
    egwValidater* _rSync;                   ///< Rendering order sync (retained).
    egwLightStack* _lStack;                 ///< Light illumination stack (retained).
    egwMaterialStack* _mStack;              ///< Material rendering stack (retained).
    egwTextureStack* _tStack;               ///< Texture mapping stack (retained).
    
    egwSJITVAMeshf _ipMesh;                 ///< Polygon mesh instance (contents owned).
    egwKnotTrack _vTrack;                   ///< Vertex knot track.
    egwKnotTrack _nTrack;                   ///< Normal knot track.
    egwKnotTrack _tTrack;                   ///< Texture knot track.
    EGWtime _eAbsT;                         ///< Evaluated absolute time index (seconds).
    id<egwPTimer> _eTimer;                  ///< Evaluation timer (retained).
    
    egwValidater* _gbSync;                  ///< Geometry buffer sync (retained).
    EGWuint _geoAID;                        ///< Geometry buffer arrays identifier.
    EGWuint _geoEID;                        ///< Geometry buffer elements identifier.
    EGWuint _geoStrg;                       ///< Geometry storage/VBO setting.
    
    egwMatrix44f _wcsTrans;                 ///< Orientation transform (LCS->WCS).
    egwMatrix44f _lcsTrans;                 ///< Offset transform (MMCS->LCS).
    id<egwPBounding> _wcsRBVol;             ///< Mesh optical volume (WCS, retained).
    id<egwPBounding> _mcsRBVol;             ///< Mesh optical volume (MCS, retained).
    id<egwPInterpolator> _wcsIpo;           ///< Orientation driver interpolator (retained).
    id<egwPInterpolator> _lcsIpo;           ///< Offset driver interpolator (retained).
    
    egwKFJITVAMeshf* _kfMesh;               ///< Animated polygon mesh data (aliased, MMCS).
    
    BOOL _isNormNrmlVec;                    ///< Tracks normal vector renormalization.
}

/// Designated Initializer.
/// Initializes the mesh asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] keyFrmdMeshData Animated polygon mesh data (contents ownership transfer).
/// @param [in] vrtPolationMode Vertex bit-wise i/e-polation mode settings (EGW_POLATION_*).
/// @param [in] nrmPolationMode Normal bit-wise i/e-polation mode settings (EGW_POLATION_*).
/// @param [in] texPolationMode Texture bit-wise i/e-polation mode settings (EGW_POLATION_*).
/// @param [in] bndClass Associated bounding class. May be nil (for default).
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @param [in] txtrStack Associated texture stack (retained). May be nil (for non-textured).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent keyFramedMesh:(egwKFJITVAMeshf*)keyFrmdMeshData vertexPolationMode:(EGWuint32)vrtPolationMode normalPolationMode:(EGWuint32)nrmPolationMode texturePolationMode:(EGWuint32)texPolationMode meshBounding:(Class)bndClass geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack textureStack:(egwTextureStack*)txtrStack;

/// Blank Mesh Initializer.
/// Initializes the mesh asset as a blank polygon set with provided settings.
/// @note This method does not clear/set-to-zero the allocated arrays prior to return.
/// @note After custom polygon initialization, reboundWithClass should be used to set the bounding volume.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] vrtxCount Polygon mesh vertex count [3,inf].
/// @param [in] faceCount Polygon mesh face count [1,inf].
/// @param [in] vrtFrmCount Vertex key frames count [0|[1,inf]].
/// @param [in] vrtPolationMode Vertex bit-wise i/e-polation mode settings (EGW_POLATION_*).
/// @param [in] nrmFrmCount Normal key frames count [0|[1,inf]].
/// @param [in] nrmPolationMode Normal bit-wise i/e-polation mode settings (EGW_POLATION_*).
/// @param [in] texFrmCount Texture key frames count [0|[1,inf]].
/// @param [in] texPolationMode Texture bit-wise i/e-polation mode settings (EGW_POLATION_*).
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @param [in] txtrStack Associated texture stack (retained). May be nil (for non-textured).
/// @return Self upon success, otherwise nil.
- (id)initBlankWithIdentity:(NSString*)assetIdent vertexCount:(EGWuint16)vrtxCount faceCount:(EGWuint16)faceCount vertexFrameCount:(EGWuint16)vrtFrmCount vertexPolationMode:(EGWuint32)vrtPolationMode normalFrameCount:(EGWuint16)nrmFrmCount normalPolationMode:(EGWuint32)nrmPolationMode textureFrameCount:(EGWuint16)texFrmCount texturePolationMode:(EGWuint32)texPolationMode geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack textureStack:(egwTextureStack*)txtrStack;

/// Copy Initializer.
/// Copies a mesh asset with provided unique settings.
/// @param [in] geometry Geometry to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPGeometry>)geometry withIdentity:(NSString*)assetIdent;


/// Vertex Polation Mode Accessor.
/// Returns vertex i/e-polation mode settings.
/// @return Vertex bit-wise i/e-polation mode settings (EGW_POLATION_*).
- (EGWuint32)vertexPolationMode;

/// Normal Polation Mode Accessor.
/// Returns normal i/e-polation mode settings.
/// @return Normal bit-wise i/e-polation mode settings (EGW_POLATION_*).
- (EGWuint32)normalPolationMode;

/// Texture Polation Mode Accessor.
/// Returns texture i/e-polation mode settings.
/// @return Texture bit-wise i/e-polation mode settings (EGW_POLATION_*).
- (EGWuint32)texturePolationMode;


/// Delegate Mutator.
/// Sets the mesh's event responder delegate to @a delegate.
/// @param [in] delegate Event responder delegate (retained).
- (void)setDelegate:(id<egwDGeometryEvent>)delegate;

/// Vertex Polation Mode Mutator.
/// Sets the vertex i/e-polation mode settings to @a vrtPolationMode.
/// @param [in] vrtPolationMode Vertex bit-wise i/e-polation mode settings (EGW_POLATION_*).
/// @note Polation mode change may not succeed due to frame data requirements.
- (void)setVertexPolationMode:(EGWuint32)vrtPolationMode;

/// Normal Polation Mode Mutator.
/// Sets the normal i/e-polation mode settings to @a nrmPolationMode.
/// @param [in] nrmPolationMode Normal bit-wise i/e-polation mode settings (EGW_POLATION_*).
/// @note Polation mode change may not succeed due to frame data requirements.
- (void)setNormalPolationMode:(EGWuint32)nrmPolationMode;

/// Texture Polation Mode Mutator.
/// Sets the texture i/e-polation mode settings to @a texPolationMode.
/// @param [in] texPolationMode Texture bit-wise i/e-polation mode settings (EGW_POLATION_*).
/// @note Polation mode change may not succeed due to frame data requirements.
- (void)setTexturePolationMode:(EGWuint32)texPolationMode;

@end


/// Key Framed Polygon Mesh Asset Base.
/// Contains shared instance data relating to animated indexed vertex key framed array meshes.
@interface egwKeyFramedMeshBase : NSObject <egwPAssetBase> {
    EGWuint _instCounter;                   ///< Instantiation counter.
    NSString* _ident;                       ///< Unique identity (retained).
    
    id<egwPBounding> _mmcsRBVol;            ///< Mesh optical volume (MMCS, retained).
    egwKFJITVAMeshf _kfMesh;                ///< Key framed polygon mesh data (MMCS, contents owned).
}

/// Designated Initializer.
/// Initializes the animated mesh asset base with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] keyFrmdMeshData Animated polygon mesh data (contents ownership transfer).
/// @param [in] bndClass Associated bounding class. May be nil (for default).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent keyFramedMesh:(egwKFJITVAMeshf*)keyFrmdMeshData meshBounding:(Class)bndClass;

/// Blank Mesh Initializer.
/// Initializes the animated mesh asset base as a blank polygon set with provided settings.
/// @note This method does not clear/set-to-zero the allocated arrays prior to return.
/// @note After custom polygon initialization, reboundWithClass should be used to set the bounding volume.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] vrtxCount Polygon mesh vertex count [3,inf].
/// @param [in] faceCount Polygon mesh face count [1,inf].
/// @param [in] vrtFrmCount Vertex key frames count [0|[1,inf]].
/// @param [in] nrmFrmCount Normal key frames count [0|[1,inf]].
/// @param [in] texFrmCount Texture key frames count [0|[1,inf]].
/// @return Self upon success, otherwise nil.
- (id)initBlankWithIdentity:(NSString*)assetIdent vertexCount:(EGWuint16)vrtxCount faceCount:(EGWuint16)faceCount vertexFrameCount:(EGWuint16)vrtFrmCount normalFrameCount:(EGWuint16)nrmFrmCount textureFrameCount:(EGWuint16)texFrmCount;


/// Base Offset (byTransform) Method.
/// Offsets the mesh base data in the MCS by the provided @a transform for subsequent render passes.
/// @note Base offsetting will cause untracked sync invalidation to shared object instances!
/// @param [in] transform MCS->MMCS transformation matrix.
- (void)baseOffsetByTransform:(const egwMatrix44f*)transform;

/// Base Offset (byZeroAlign) Method.
/// Offsets the mesh base data in the MCS by the provided @a zfAlign axis extents edges for subsequent render passes.
/// @note Base offsetting will cause untracked sync invalidation to shared object instances!
/// @param [in] zfAlign Zero offset alignment mode (EGW_GFXOBJ_ZFALIGN_*)
- (void)baseOffsetByZeroAlign:(EGWuint)zfAlign;

/// Rebound (withClass) Method.
/// Rebinds the base optical MCS bounding volume with provided @a bndClass class.
/// @param [in] bndClass Associated bounding class. May be nil (for egwBoundingSphere).
- (void)reboundWithClass:(Class)bndClass;


/// Rendering Bounding Volume Accessor.
/// Returns the base MMCS rendering bounding volume.
/// @return Rendering bounding volume (MMCS).
- (id<egwPBounding>)renderingBounding;

/// Animated Polygon Mesh Data Accessor.
/// Returns the base animated polygon MMCS mesh data.
/// @return Animated polygon mesh data (MMCS).
- (egwKFJITVAMeshf*)keyFramedMesh;

@end

/// @}

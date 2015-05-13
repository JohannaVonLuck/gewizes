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

/// @defgroup geWizES_geo_mesh egwMesh
/// @ingroup geWizES_geo
/// Mesh Asset.
/// @{

/// @file egwMesh.h
/// Mesh Asset Interface.

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


/// Polygon Mesh Instance Asset.
/// Contains unique instance data relating to indexed vertex array meshes.
@interface egwMesh : NSObject <egwPAsset, egwPGeometry> {
    egwMeshBase* _base;                     ///< Base object instance (retained).
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
    
    egwMatrix44f _wcsTrans;                 ///< Orientation transform (LCS->WCS).
    egwMatrix44f _lcsTrans;                 ///< Offset transform (MMCS->LCS).
    id<egwPBounding> _wcsRBVol;             ///< Mesh optical volume (WCS, retained).
    id<egwPInterpolator> _wcsIpo;           ///< Orientation driver interpolator (retained).
    id<egwPInterpolator> _lcsIpo;           ///< Offset driver interpolator (retained).
    
    const egwMatrix44f* _mcsTrans;          ///< Base offset transform (MCS->MMCS, aliased).
    egwSJITVAMeshf* _pMesh;                 ///< Polygon mesh data (aliased, MCS).
    const EGWuint* _geoAID;                 ///< Geometry buffer arrays identifier (aliased).
    const EGWuint* _geoEID;                 ///< Geometry buffer elements identifier (aliased).
}

/// Designated Initializer.
/// Initializes the mesh asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] meshData Polygon mesh data (contents ownership transfer).
/// @param [in] bndClass Associated bounding class. May be nil (for default).
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @param [in] txtrStack Associated texture stack (retained). May be nil (for non-textured).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent staticMesh:(egwSJITVAMeshf*)meshData meshBounding:(Class)bndClass geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack textureStack:(egwTextureStack*)txtrStack;

/// Blank Mesh Initializer.
/// Initializes the mesh asset as a blank polygon set with provided settings.
/// @note This method does not clear/set-to-zero the allocated arrays prior to return.
/// @note After custom polygon initialization, reboundWithClass should be used to set the bounding volume.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] vrtxCount Polygon mesh vertex count [3,inf].
/// @param [in] faceCount Polygon mesh face count [1,inf].
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @param [in] txtrStack Associated texture stack (retained). May be nil (for non-textured).
/// @return Self upon success, otherwise nil.
- (id)initBlankWithIdentity:(NSString*)assetIdent vertexCount:(EGWuint16)vrtxCount faceCount:(EGWuint16)faceCount geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack textureStack:(egwTextureStack*)txtrStack;

/// Box Mesh Initializer.
/// Initializes the mesh asset as a box created from provided settings.
/// @note Texture mapping uses two horizontal strips of equi-spaced faces in order: left <[0,1/6]s,[1,0]t>, front <[1/6,2/6]s,[1,0]t>, right <[2/6,3/6]s,[1,0]t>, and then top <[3/6,4/6]s,[1,0]t>, back <[4/6,5/6]s,[1,0]t>, bottom <[5/6,1]s,[1,0]t>. Note that the last three are individually rotated 90 degrees counter-clockwise.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] width Box hortizontal width.
/// @param [in] height Box vertical height.
/// @param [in] depth Box side depth.
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @param [in] txtrStack Associated texture stack (retained). May be nil (for non-textured).
/// @return Self upon success, otherwise nil.
- (id)initBoxWithIdentity:(NSString*)assetIdent boxWidth:(EGWsingle)width boxHeight:(EGWsingle)height boxDepth:(EGWsingle)depth geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack textureStack:(egwTextureStack*)txtrStack;

/// Cone Mesh Initializer.
/// Initializes the mesh asset base as a cone created from provided settings.
/// @note Texture mapping uses one horizontal strip of equi-spaced faces in order: edge <[0,.5]s,[1,0]t>, base <[.5,1]s,[1,0]t>. Edge and base both use circular base mappings.
/// @note Vertical latitudial cuts is inclusive of the north pole point and base.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] radius Cone base radius.
/// @param [in] height Cone vertical height.
/// @param [in] lngCuts Horizontal longitudial cuts over 360 degrees [3,inf).
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @param [in] txtrStack Associated texture stack (retained). May be nil (for non-textured).
/// @return Self upon success, otherwise nil.
- (id)initConeWithIdentity:(NSString*)assetIdent coneRadius:(EGWsingle)radius coneHeight:(EGWsingle)height coneLongitudes:(EGWuint16)lngCuts geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack textureStack:(egwTextureStack*)txtrStack;

/// Cylinder Mesh Initializer.
/// Initializes the mesh asset base as a cylinder created from provided settings.
/// @note Texture mapping uses one horizontal strip of equi-spaced faces in order: edge <[0,1/2]s,[1,0]t>, top <[1/2,3/4]s,[1,0]t>, bottom <[3/4,1]s,[1,0]t>. Edge uses squared face mapping and bases uses circular base mapping.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] radius Cylinder radius.
/// @param [in] height Cylinder vertical height.
/// @param [in] lngCuts Horizontal longitudial cuts over 360 degrees [3,inf).
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @param [in] txtrStack Associated texture stack (retained). May be nil (for non-textured).
/// @return Self upon success, otherwise nil.
- (id)initCylinderWithIdentity:(NSString*)assetIdent cylinderRadius:(EGWsingle)radius cylinderHeight:(EGWsingle)height cylinderLongitudes:(EGWuint16)lngCuts geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack textureStack:(egwTextureStack*)txtrStack;

/// Pyramid Mesh Initializer.
/// Initializes the mesh asset base as a pyramid created from provided settings.
/// @note Texture mapping uses one horizontal strip of equi-spaced faces in order: top <[0,.5]s,[1,0]t>, base <[.5,1]s,[1,0]t>. Top sides uses top-down squared face mapping and bases uses squared base mappings, with north pole point at <.25s,.5t>.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] width Pyramid hortizontal width.
/// @param [in] height Pyramid vertical height.
/// @param [in] depth Pyramid side depth.
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @param [in] txtrStack Associated texture stack (retained). May be nil (for non-textured).
/// @return Self upon success, otherwise nil.
- (id)initPyramidWithIdentity:(NSString*)assetIdent pyramidWidth:(EGWsingle)width pyramidHeight:(EGWsingle)height pyramidDepth:(EGWsingle)depth geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack textureStack:(egwTextureStack*)txtrStack;

/// Sphere Mesh Initializer.
/// Initializes the mesh asset as a sphere created from provided settings.
/// @note Texture mapping uses a squared face mapping, with north and south pole points at <.5s,1t> and <.5s,0t> respectively.
/// @note Vertical latitudial cuts is inclusive of the north and south pole points.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] radius Sphere radius.
/// @param [in] lngCuts Horizontal longitudial cuts over 360 degrees [3,inf).
/// @param [in] latCuts Vertical latitudial cuts over 180 degrees [3,inf).
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @param [in] txtrStack Associated texture stack (retained). May be nil (for non-textured).
/// @return Self upon success, otherwise nil.
- (id)initSphereWithIdentity:(NSString*)assetIdent sphereRadius:(EGWsingle)radius sphereLongitudes:(EGWuint16)lngCuts sphereLatitudes:(EGWuint16)latCuts geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack textureStack:(egwTextureStack*)txtrStack;

/// Copy Initializer.
/// Copies a mesh asset with provided unique settings.
/// @param [in] geometry Geometry to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPGeometry>)geometry withIdentity:(NSString*)assetIdent;


/// Delegate Mutator.
/// Sets the mesh's event responder delegate to @a delegate.
/// @param [in] delegate Event responder delegate (retained).
- (void)setDelegate:(id<egwDGeometryEvent>)delegate;

@end


/// Polygon Mesh Asset Base.
/// Contains shared instance data relating to indexed vertex array meshes.
@interface egwMeshBase : NSObject <egwPAssetBase, egwPSubTask, egwDValidationEvent> {
    EGWuint _instCounter;                   ///< Instantiation counter.
    NSString* _ident;                       ///< Unique identity (retained).
    
    egwSJITVAMeshf _pMesh;                  ///< Polygon mesh data (MCS, contents owned).
    
    egwValidater* _gbSync;                  ///< Geometry buffer sync (retained).
    EGWuint _geoAID;                        ///< Geometry buffer arrays identifier.
    EGWuint _geoEID;                        ///< Geometry buffer elements identifier.
    EGWuint _geoStrg;                       ///< Geometry storage/VBO setting.
    
    egwMatrix44f _mcsTrans;                 ///< Base offset transform (MCS->MMCS).
    id<egwPBounding> _mmcsRBVol;            ///< Mesh optical volume (MMCS, retained).
    
    BOOL _isGDPersist;                      ///< Tracks surface persistence status.
}

/// Designated Initializer.
/// Initializes the mesh asset base with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] meshData Polygon mesh data (contents ownership transfer).
/// @param [in] bndClass Associated bounding class. May be nil (for default).
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent staticMesh:(egwSJITVAMeshf*)meshData meshBounding:(Class)bndClass geometryStorage:(EGWuint)storage;

/// Blank Mesh Initializer.
/// Initializes the mesh asset base as a blank polygon set with provided settings.
/// @note This method does not clear/set-to-zero the allocated arrays prior to return.
/// @note After custom polygon initialization, reboundWithClass should be used to set the bounding volume.
/// @note Once mesh is prepared, one should invalidate the geometry buffer sync to start the buffering sequence.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] vrtxCount Polygon mesh vertex count [3,inf].
/// @param [in] faceCount Polygon mesh face count [1,inf].
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @return Self upon success, otherwise nil.
- (id)initBlankWithIdentity:(NSString*)assetIdent vertexCount:(EGWuint16)vrtxCount faceCount:(EGWuint16)faceCount geometryStorage:(EGWuint)storage;

/// Box Mesh Initializer.
/// Initializes the mesh asset base as a box created from provided settings.
/// @note Texture mapping uses two horizontal strips of equi-spaced faces in order: left <[0,1/6]s,[1,0]t>, front <[1/6,2/6]s,[1,0]t>, right <[2/6,3/6]s,[1,0]t>, and then top <[3/6,4/6]s,[1,0]t>, back <[4/6,5/6]s,[1,0]t>, bottom <[5/6,1]s,[1,0]t>. Note that the last three are individually rotated 90 degrees counter-clockwise.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] width Box hortizontal width.
/// @param [in] height Box vertical height.
/// @param [in] depth Box side depth.
/// @param [in] hasTex Texture usage boolean.
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @return Self upon success, otherwise nil.
- (id)initBoxWithIdentity:(NSString*)assetIdent boxWidth:(EGWsingle)width boxHeight:(EGWsingle)height boxDepth:(EGWsingle)depth hasTexture:(BOOL)hasTex geometryStorage:(EGWuint)storage;

/// Cone Mesh Initializer.
/// Initializes the mesh asset base as a cone created from provided settings.
/// @note Texture mapping uses one horizontal strip of equi-spaced faces in order: edge <[0,.5]s,[1,0]t>, base <[.5,1]s,[1,0]t>. Edge and base both use circular base mappings.
/// @note Vertical latitudial cuts is inclusive of the north pole point and base.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] radius Cone base radius.
/// @param [in] height Cone vertical height.
/// @param [in] lngCuts Horizontal longitudial cuts over 360 degrees [3,inf).
/// @param [in] hasTex Texture usage boolean.
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @return Self upon success, otherwise nil.
- (id)initConeWithIdentity:(NSString*)assetIdent coneRadius:(EGWsingle)radius coneHeight:(EGWsingle)height coneLongitudes:(EGWuint16)lngCuts hasTexture:(BOOL)hasTex geometryStorage:(EGWuint)storage;

/// Cylinder Mesh Initializer.
/// Initializes the mesh asset base as a cylinder created from provided settings.
/// @note Texture mapping uses one horizontal strip of equi-spaced faces in order: edge <[0,1/2]s,[1,0]t>, top <[1/2,3/4]s,[1,0]t>, bottom <[3/4,1]s,[1,0]t>. Edge uses squared face mapping and bases uses circular base mapping.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] radius Cylinder radius.
/// @param [in] height Cylinder vertical height.
/// @param [in] lngCuts Horizontal longitudial cuts over 360 degrees [3,inf).
/// @param [in] hasTex Texture usage boolean.
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @return Self upon success, otherwise nil.
- (id)initCylinderWithIdentity:(NSString*)assetIdent cylinderRadius:(EGWsingle)radius cylinderHeight:(EGWsingle)height cylinderLongitudes:(EGWuint16)lngCuts hasTexture:(BOOL)hasTex geometryStorage:(EGWuint)storage;

/// Pyramid Mesh Initializer.
/// Initializes the mesh asset base as a pyramid created from provided settings.
/// @note Texture mapping uses one horizontal strip of equi-spaced faces in order: top <[0,.5]s,[1,0]t>, base <[.5,1]s,[1,0]t>. Top sides uses top-down squared face mapping and bases uses squared base mappings, with north pole point at <.25s,.5t>.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] width Pyramid hortizontal width.
/// @param [in] height Pyramid vertical height.
/// @param [in] depth Pyramid side depth.
/// @param [in] hasTex Texture usage boolean.
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @return Self upon success, otherwise nil.
- (id)initPyramidWithIdentity:(NSString*)assetIdent pyramidWidth:(EGWsingle)width pyramidHeight:(EGWsingle)height pyramidDepth:(EGWsingle)depth hasTexture:(BOOL)hasTex geometryStorage:(EGWuint)storage;

/// Sphere Mesh Initializer.
/// Initializes the mesh asset base as a sphere created from provided settings.
/// @note Texture mapping uses a squared face mapping, with north and south pole points at <.5s,1t> and <.5s,0t> respectively.
/// @note Vertical latitudial cuts is inclusive of the north and south pole points.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] radius Sphere radius.
/// @param [in] lngCuts Horizontal longitudial cuts over 360 degrees [3,inf).
/// @param [in] latCuts Vertical latitudial cuts over 180 degrees [3,inf).
/// @param [in] hasTex Texture usage boolean.
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @return Self upon success, otherwise nil.
- (id)initSphereWithIdentity:(NSString*)assetIdent sphereRadius:(EGWsingle)radius sphereLongitudes:(EGWuint16)lngCuts sphereLatitudes:(EGWuint16)latCuts hasTexture:(BOOL)hasTex geometryStorage:(EGWuint)storage;


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


/// Geometry Buffer Syncronization Validater Accessor.
/// Returns the validater that manages component synchronization with a hardware buffer.
/// @return Geometry buffer validater, otherwise nil (if unused).
- (egwValidater*)geometryBufferSync;

/// Geometry Arrays ID Accessor.
/// Returns the base context referenced geometry arrays identifier.
/// @note Ownership transfer is not allowed.
/// @return Geometry arrays identifier.
- (const EGWuint*)geometryArraysID;

/// Geometry Elements ID Accessor.
/// Returns the base context referenced geometry elements identifier.
/// @note Ownership transfer is not allowed.
/// @return Geometry elements identifier.
- (const EGWuint*)geometryElementsID;

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

/// Static Polygon Mesh Data Accessor.
/// Returns the base static polygon MMCS mesh data.
/// @return Static polygon mesh data (MMCS).
- (egwSJITVAMeshf*)staticMesh;


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

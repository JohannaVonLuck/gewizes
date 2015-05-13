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

/// @defgroup geWizES_geo_particlesystem egwParticleSystem
/// @ingroup geWizES_geo
/// Animated Point Sprite Particle System Asset.
/// @{

/// @file egwParticleSystem.h
/// Animated Point Sprite Particle System Asset Interface.

#import "egwGeoTypes.h"
#import "../inf/egwPAsset.h"
#import "../inf/egwPObjLeaf.h"
#import "../inf/egwPAssetBase.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPGfxContext.h"
#import "../inf/egwPRenderable.h"
#import "../inf/egwPActuator.h"
#import "../inf/egwPBounding.h"
#import "../inf/egwPGeometry.h"
#import "../inf/egwPLight.h"
#import "../inf/egwPMaterial.h"
#import "../inf/egwPTexture.h"
#import "../math/egwMathTypes.h"
#import "../data/egwDataTypes.h"
#import "../gfx/egwGfxTypes.h"
#import "../gui/egwGuiTypes.h"
#import "../obj/egwObjTypes.h"
#import "../misc/egwMiscTypes.h"


#define EGW_PSYS_MINEMITFREQTIMED   0.010   ///< Minimum emitter cutoff frequency for timed release (to prevent infinite loop).
#define EGW_PSYS_NPQUADSZMLTPLR     0.0075f ///< For non-point-based quads, use this as the particle size to vertex width/height calculation modifier.


/// Particle System Instance Asset.
/// Contains unique instance data relating to oriented particle systems.
/// @note This current component architecture is set to be completely redone in future revisions.
@interface egwParticleSystem : NSObject <egwPAsset, egwPGeometry, egwPActuator> {
    egwParticleSystemBase* _base;           ///< Base object instance (retained).
    NSString* _ident;                       ///< Unique identity (retained).
    BOOL _invkParent;                       ///< Parent invocation tracking.
    BOOL _ortPending;                       ///< Orientation transforms pending.
    BOOL _isRendering;                      ///< Tracks rendering status.
    id<egwPObjectBranch> _parent;           ///< Parent node (weak).
    id<egwDGeometryEvent,egwDActuatorEvent> _delegate; ///< Event responder delegate (retained).
    
    BOOL _isActuating;                      ///< Tracks actuating status.
    BOOL _isFinished;                       ///< Tracks finished status.
    BOOL _isPaused;                         ///< Tracks paused status.
    EGWuint16 _aFlags;                      ///< Actuator flags.
    
    EGWuint32 _rFlags;                      ///< Rendering flags.
    EGWuint16 _rFrame;                      ///< Rendering frame number.
    EGWuint16 _vFrame;                      ///< Camera viewing frame number.
    id<egwPCamera> _vCamera;                ///< Camera viewing reference (weak).
    const egwMatrix44f* _vcwcsTrans;        ///< Camera viewing WCS transform (weak).
    egwValidater* _rSync;                   ///< Rendering order sync (retained).
    egwLightStack* _lStack;                 ///< Light illumination stack (retained).
    egwTextureStack* _tStack;               ///< Texture mapping stack (retained).
    
    id<egwPTexture, egwPTimed> _drvTex;     ///< Driving texture (if timed).
    const egwTextureJumpTable* _dtJmpTbl;   ///< Driving texture jump table.
    EGWtime _drvTexBegAbsT;                 ///< Driving texture beginning time (absolute).
    EGWtime _drvTexEndAbsT;                 ///< Driving texture ending time (absolute).
    egwVector4f _wcsExtForce;               ///< External force vector (WCS).
    egwVector4f _mmcsExtForce;              ///< External force vector (MCS).
    EGWsingle _wcsGrndLevel;                ///< Ground level value (WCS).
    EGWsingle _mmcsGrndLevel;               ///< Ground level value (MCS).
    EGWtime _eFreq;                         ///< Emitter frequency value.
    EGWtime _efLeft;                        ///< Emitter frequency time left (countdown).
    union {
        struct {
            EGWsingle tParts;               ///< Total emitter particles (rounded to int).
            EGWuint32 tpCount;              ///< Total emitted particles counter.
        } counted;                          ///< Count emitted duration.
        struct {
            EGWtime dLeft;                  ///< Emitter duration time left (countdown).
        } timed;                            ///< Timed emitted duration.
    } _eDur;                                ///< Emitter duration.
    EGWuint16 _mParts;                      ///< Maximum particles (0 for inf, repeated).
    EGWuint16 _psFlags;                     ///< Particle system flags (repeated).
    egwArray _particles;                    ///< Particles collection array.
    egwVector3f _mmUpPos[2];                ///< Particles min/max updated positions (MCS).
    egwSQVAMesh4f* _pMesh;                  ///< Particle mesh (reused, MCS).
    BOOL _isPntSprtAvail;                   ///< Tracks point sprite extension availability.
    BOOL _isPntSzAryAval;                   ///< Tracks point sprite size array extension available.
    BOOL _isPntSzStatic;                    ///< Tracks static point size status.
    BOOL _isBBQuadRndrd;                    ///< Tracks billboarded quad rendered status.
    BOOL _isEmitFinished;                   ///< Tracks emitter frequency finish state.
    BOOL _isExtForceApp;                    ///< Tracks external force application state.
    
    EGWuint _geoAID;                        ///< Geometry buffer arrays identifier.
    EGWuint _geoStrg;                       ///< Geometry storage/VBO setting.
    
    egwMatrix44f _twcsTrans;                ///< Total world transform (MMCS->WCS).
    egwMatrix44f _twcsInverse;              ///< Total world transform inverse (WCS->MMCS).
    egwMatrix44f _wcsTrans;                 ///< Orientation transform (LCS->WCS).
    egwMatrix44f _lcsTrans;                 ///< Offset transform (MMCS->LCS).
    egwMatrix44f _broTrans;                 ///< Billboard reorientation transform (MMCS->MMCS).
    id<egwPBounding> _wcsRBVol;             ///< Particle system optical volume (WCS, retained).
    id<egwPBounding> _mmcsRBVol;            ///< Particle system optical volume (MMCS, retained).
    id<egwPInterpolator> _wcsIpo;           ///< Orientation driver interpolator (retained).
    id<egwPInterpolator> _lcsIpo;           ///< Offset driver interpolator (retained).
    
    const egwMatrix44f* _mcsTrans;          ///< Base offset transform (MCS->MMCS, aliased).
    const egwPSParticleDynamics* _pDynamics;///< Particle dynamics data (aliased).
    const egwPSSystemDynamics* _sDynamics;  ///< System dynamics data (aliased).
    const egwVector3f* _mmStPos;            ///< Min/max starting position (aliased).
    const egwVector3f* _velDelta;           ///< Velocity delta vector (MCS, aliased).
}

/// Designated Initializer.
/// Initializes the mesh asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] partDyn Particle dynamics data (contents ownership transfer).
/// @param [in,out] sysDyn System dynamics data (contents ownership transfer).
/// @param [in] bndClass Associated bounding class. May be nil (for default).
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*). Only applies when using billboarded quads.
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] txtrStack Associated texture stack (retained). May be nil (for non-textured).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent particleDynamics:(egwPSParticleDynamics*)partDyn systemDynamics:(egwPSSystemDynamics*)sysDyn systemBounding:(Class)bndClass geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack textureStack:(egwTextureStack*)txtrStack;

/// Copy Initializer.
/// Copies a mesh asset with provided unique settings.
/// @param [in] geometry Geometry to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPGeometry>)geometry withIdentity:(NSString*)assetIdent;


/// External Force Accessor.
/// Returns the external linear WCS force vector.
/// @return Linear external force vector (WCS).
- (const egwVector4f*)externalForce;

/// Ground Level Accessor.
/// Returns the ground level WCS location where particles come to rest.
/// @return Linear ground height location (WCS).
- (EGWsingle)groundLevel;

/// Maximum Particles Accessor,
/// Returns the total number of maximum particles allowed concurrently.
/// @return Maximum particle count (or 0 for infinite).
- (EGWuint16)maximumParticles;

/// Particle System Flags Accessor.
/// Returns the particle system's flags.
/// @return Particle system flags.
- (EGWuint16)systemFlags;


/// Delegate Mutator.
/// Sets the mesh's event responder delegate to @a delegate.
/// @param [in] delegate Event responder delegate (retained).
- (void)setDelegate:(id<egwDGeometryEvent,egwDActuatorEvent>)delegate;

/// External Force Mutator.
/// Sets the external linear WCS force vector to @a force.
/// @param [in] force Linear force vector (WCS).
- (void)setExternalForce:(const egwVector3f*)force;

/// Ground Level Mutator.
/// Sets the ground level WCS location to @a height where particles come to rest.
/// @param [in] height Linear ground height location (WCS).
- (void)setGroundLevel:(EGWsingle)height;

/// Maximum Particles Mutator.
/// Sets the total number of maximum particles allowed concurrently.
/// @param [in] maxPart Maximum number of concurrent particles. May be 0 (for infinite).
- (void)setMaximumParticles:(EGWuint16)maxPart;

/// Particle System Flags Mutator.
/// Sets the particle system's flags.
/// @param [in] sysFlags Particle system flags (EGW_PRTCLSYSFLAG_*).
- (void)setSystemFlags:(EGWuint16)sysFlags;

@end


/// Particle System Asset Base.
/// Contains shared instance data relating to oriented particle systems.
@interface egwParticleSystemBase : NSObject <egwPAssetBase> {
    EGWuint _instCounter;                   ///< Instantiation counter.
    NSString* _ident;                       ///< Unique identity (retained).
    
    egwMatrix44f _mcsTrans;                 ///< Base offset transform (MCS->MMCS).
    egwPSParticleDynamics _pDynamics;       ///< Particle dynamics data.
    egwPSSystemDynamics _sDynamics;         ///< System dynamics data.
    EGWsingle _mAlpha;                      ///< Min alpha attainable.
    egwVector3f _mmStPos[2];                ///< Min/max starting position.
    egwVector3f _sphVelDelta;               ///< Spherical velocity delta vector.
}

/// Designated Initializer.
/// Initializes the particle system asset base with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] partDyn Particle dynamics data (contents ownership transfer).
/// @param [in,out] sysDyn System dynamics data (contents ownership transfer).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent particleDynamics:(egwPSParticleDynamics*)partDyn systemDynamics:(egwPSSystemDynamics*)sysDyn;


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


/// MCS->MMCS Transform Accessor.
/// Returns the object's MCS->MMCS transformation matrix.
/// @return MCS->MMCS transform.
- (const egwMatrix44f*)mcsTransform;

/// Mimimal Alpha Attainable Accessor.
/// Returns the minimal alpha attainable [0,1] in the system.
/// @return Minimal alpha attainable [0,1].
- (const EGWsingle)minAlphaAttainable;

/// Mimimal/Maximal Starting Position Accessor.
/// Returns the minimal/maximal starting position attainable (MCS) in the system.
/// @return Minimal/maximal starting position attainable (MCS).
- (const egwVector3f*)minMaxStartPosition;

/// Particle Dynamics Data Accessor.
/// Returns the base particle dynamics data.
/// @return Particle dynamics data.
- (const egwPSParticleDynamics*)particleDynamics;

/// System Dynamics Data Accessor.
/// Returns the base system dynamics data.
/// @return System dynamics data.
- (const egwPSSystemDynamics*)systemDynamics;

/// Spherical Velocity Delta Accessor.
/// Returns the velocity delta array in terms of converted spherical to cartesian coords (MCS).
/// @return Spherical velocity delta vector (MCS).
- (const egwVector3f*)sphericalVelocityDelta;

@end

/// @}

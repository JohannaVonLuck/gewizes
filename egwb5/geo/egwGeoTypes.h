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

/// @defgroup geWizES_geo_types egwGeoTypes
/// @ingroup geWizES_geo
/// Geometry Types.
/// @{

/// @file egwGeoTypes.h
/// Geometry Types.

#import "../inf/egwTypes.h"
#import "../math/egwMathTypes.h"
#import "../gfx/egwGfxTypes.h"


// !!!: ***** Predefs *****

@class egwBillboard;
@class egwBillboardBase;
@class egwMesh;
@class egwMeshBase;
@class egwKeyFramedMesh;
@class egwKeyFramedMeshBase;
//@class egwSkeletalBonedMesh;
//@class egwSkeletalBonedMeshBase;
@class egwParticleSystem;
@class egwParticleSystemBase;


// !!!: ***** Defines *****

// Geometry storage/VBO settings
#define EGW_GEOMETRY_STRG_NONE       0x00  ///< No specialized geometry storage.
#define EGW_GEOMETRY_STRG_VBOSTATIC  0x01  ///< Static VBO usage.
#define EGW_GEOMETRY_STRG_VBODYNAMIC 0x02  ///< Dynamic VBO usage.
#define EGW_GEOMETRY_STRG_EXVBO      0x0f  ///< Used to extract VBO usage from bit-field.

// Particle system flags
#define EGW_PSYSFLAG_NONE           0x0000  ///< No particle system flags.
#define EGW_PSYSFLAG_EMITCNTDWN     0x0001  ///< Emitter emits along a timer countdown instead of total particle count (emitter frequency cannot be 0).
#define EGW_PSYSFLAG_EMITOLDRPLC    0x0002  ///< On new particle creation, in a particle limited system, do a full table search for oldest particle instead of quick right shift.
#define EGW_PSYSFLAG_EMITNORPLC     0x0004  ///< On new particle creation, in a particle limited system, don't emit a new particle if space is not available already (allows particles to fully finished before new ones created).
#define EGW_PSYSFLAG_EMITLEFTVAR    0x0008  ///< Emitter uses frequency variance on time left to emit (for each particle) rather than initial frequency value (useful for some effects).
#define EGW_PSYSFLAG_EMITTOWCS      0x0010  ///< Particles emit into the WCS upon creation and do not have any further movement from particle system re-orientation. This cannot be used with EGW_PSYSFLAG_CYCLICPOS.
#define EGW_PSYSFLAG_CYCLICPOS      0x0020  ///< Particles move cyclicly inside system's positional variance (while taking into account LCS offsets, e.g. for snow/rain). This cannot be used with EGW_PSYSFLAG_EMITTOWCS.
#define EGW_PSYSFLAG_VELUSEPYM      0x0040  ///< Velocity variant vector data is treated as spherical coords (pitch, yaw, magnitude) instead of linear coords (useful for some effects).
#define EGW_PSYSFLAG_EXTFRCISACCL   0x0080  ///< Treat any external force as a direct acceleration vector, not a newtonian force vector (weight values become meaningless).
#define EGW_PSYSFLAG_NOPOINTSPRT    0x0100  ///< Don't use point sprites, even if available.
#define EGW_PSYSFLAG_LOOPAFTRNP     0x0200  ///< Looping emitter waits until all particles are finished before looping.
#define EGW_PSYSFLAG_ALPHAOUTSHFT   0x0400  ///< If color variance has a negative alpha transition, move the transition offset begin so the end of life clamps to life span zero marker (ignores starting value).
#define EGW_PSYSFLAG_OFFTIMEDTEX    0x0800  ///< If particles use a timed texture, offset timer to non-variant begin mark (so life span variances do affect first frame timing).
#define EGW_PSYSFLAG_BNCGRNDCOR25   0x1000  ///< Treat ground collision as a particle bounce with a coefficient of restitution of 0.25.
#define EGW_PSYSFLAG_BNCGRNDCOR50   0x2000  ///< Treat ground collision as a particle bounce with a coefficient of restitution of 0.50.
#define EGW_PSYSFLAG_BNCGRNDCOR75   0x4000  ///< Treat ground collision as a particle bounce with a coefficient of restitution of 0.75.
#define EGW_PSYSFLAG_BNCGRNDCOR100  0x8000  ///< Treat ground collision as a particle bounce with a coefficient of restitution of 1.00.
#define EGW_PSYSFLAG_EXBNCGRND      0xf000  ///< Used to extract particle bounce usage from bit-field.


// !!!: ***** Primitive Geometries *****

/// 2-D Line.
/// Two dimensional line structure.
typedef struct {
    egwVector3f origin;                     ///< Origin point on line.
    egwVector3f normal;                     ///< Normal direction vector.
} egwLine3f;

/// 3-D Line.
/// Three dimnsional line structure.
typedef struct {
    egwVector4f origin;                     ///< Origin point on line.
    egwVector4f normal;                     ///< Normal direction vector.
} egwLine4f;

/// 2-D Ray.
/// Two dimensional ray structure.
typedef struct {
    egwLine3f line;                         ///< Line.
    EGWsingle s;                            ///< Start unit.
} egwRay3f;

/// 3-D Ray.
/// Three dimensional ray structure.
typedef struct {
    egwLine4f line;                         ///< Line.
    EGWsingle s;                            ///< Start unit.
} egwRay4f;

/// 2-D Line Segment.
/// Two dimensional line segment structure.
typedef struct {
    egwLine3f line;                         ///< Line.
    EGWsingle s;                            ///< Start unit.
    EGWsingle t;                            ///< End unit.
} egwLineSegment3f;

/// 3-D Line Segment.
/// Three dimensional line segment structure.
typedef struct {
    egwLine4f line;                         ///< Line.
    EGWsingle s;                            ///< Start unit.
    EGWsingle t;                            ///< End unit.
} egwLineSegment4f;

/// 2-D Plane.
/// Two dimenstional plane structure.
typedef struct {
    egwVector3f origin;                     ///< Origin point on plane.
    egwVector3f normal;                     ///< Normal vector.
    EGWsingle d;                            ///< D value.
} egwPlane3f;

/// 3-D Plane.
/// Three dimenstional plane structure.
typedef struct {
    egwVector4f origin;                     ///< Origin point on plane.
    egwVector4f normal;                     ///< Normal vector.
    EGWsingle d;                            ///< D value.
} egwPlane4f;

/// 2-D Circle.
/// Two dimensional circle structure.
typedef struct {
    egwVector3f origin;                     ///< Origin position.
    EGWsingle radius;                       ///< Radius value.
} egwCircle3f;

/// 3-D Oriented Circle.
/// Three dimensional circle structure (axis-oriented).
typedef struct {
    egwVector4f origin;                     ///< Origin position.
    egwVector4f hwAxis;                     ///< Half width axis (x+-axis).
    egwVector4f hdAxis;                     ///< Half depth axis (z+-axis).
    EGWsingle radius;                       ///< Radius value.
} egwOrientedCircle4f;

/// 3-D Sphere.
/// Three dimensional sphere structure.
typedef struct {
    egwVector4f origin;                     ///< Origin position.
    EGWsingle radius;                       ///< Radius value.
} egwSphere4f;

/// 2-D Box.
/// Two dimensional box structure (axis-aligned).
typedef struct {
    egwVector3f origin;                     ///< Origin position.
    egwVector3f min;                        ///< Minimum value extents.
    egwVector3f max;                        ///< Maximum value extents.
} egwBox3f;

/// 2-D Oriented Box.
/// Two dimensional box structure (axis-oriented).
typedef struct {
    egwVector3f origin;                     ///< Origin position.
    egwVector3f hwAxis;                     ///< Half width axis (x+-axis).
    egwVector3f hhAxis;                    ///< Half height axis (y+-axis).
} egwOrientedBox3f;

/// 3-D Box.
/// Three dimensional box structure (axis-aligned).
typedef struct {
    egwVector4f origin;                     ///< Origin position.
    egwVector4f min;                        ///< Minimum value extents.
    egwVector4f max;                        ///< Maximum value extents.
} egwBox4f;

/// 3-D Oriented Box.
/// Three dimensional box structure (axis-oriented).
typedef struct {
    egwVector4f origin;                     ///< Origin position.
    egwVector4f hwAxis;                     ///< Half width axis (x+-axis).
    egwVector4f hhAxis;                     ///< Half height axis (y+-axis).
    egwVector4f hdAxis;                     ///< Half depth axis (z+-axis).
} egwOrientedBox4f;

/// 3-D Cone.
/// Three dimensional cone structure (axis-aligned, tip pointing +y).
typedef struct {
    egwVector4f origin;                     ///< Origin position.
    EGWsingle hHeight;                      ///< Half height value (y-axis).
    EGWsingle radius;                       ///< Base radius value.
} egwCone4f;

/// 3-D Oriented Cone.
/// Three dimensional cone structure (axis-oriented, tip pointing +y).
typedef struct {
    egwVector4f origin;                     ///< Origin position.
    egwVector4f hhAxis;                     ///< Half height axis (y+-axis).
    EGWsingle radius;                       ///< Base radius value.
} egwOrientedCone4f;

/// 3-D Cylinder.
/// Three dimensional cylinder structure (axis-aligned, top pointing +y).
typedef struct {
    egwVector4f origin;                     ///< Origin position.
    EGWsingle hHeight;                      ///< Half height value (y-axis).
    EGWsingle radius;                       ///< Radius value.
} egwCylinder4f;

/// 3-D Oriented Cylinder.
/// Three dimensional cylinder structure (axis-oriented, top pointing +y).
typedef struct {
    egwVector4f origin;                     ///< Origin position.
    egwVector4f hhAxis;                     ///< Half height axis (y+-axis).
    EGWsingle radius;                       ///< Radius value.
} egwOrientedCylinder4f;

/// 3-D Frustum.
/// Three dimensional frustum structure.
typedef struct {
    egwVector4f origin;                     ///< Origin position.
    egwPlane4f xMin;                        ///< Minimum X-coord (left) plane.
    egwPlane4f xMax;                        ///< Maximum X-coord (right) plane.
    egwPlane4f yMin;                        ///< Minimum Y-coord (bottom) plane.
    egwPlane4f yMax;                        ///< Maximum Y-coord (top) plane.
    egwPlane4f zMin;                        ///< Minimum Z-coord (front) plane.
    egwPlane4f zMax;                        ///< Maximum Z-coord (back) plane.
} egwFrustum4f;


// !!!: ***** Face Indexing *****

/// Joint Indexed Triangle Face.
/// Face indexing structure capable of indexing joint vertices (T = Vi,Ni,Ti) in a mesh.
typedef union {
    struct {
        EGWuint16 i1;                       ///< Triangle joint VNT arrays index 1.
        EGWuint16 i2;                       ///< Triangle joint VNT arrays index 2.
        EGWuint16 i3;                       ///< Triangle joint VNT arrays index 3.
    } face;                                 ///< Triangle component indices.
    EGWuint16 index[3];                     ///< Triangle indices array.
    EGWuint8 bytes[6];                      ///< Byte array.
} egwJITFace;

/// Disjoint Indexed Triangle Face.
/// Face indexing structure capable of indexing disjoint vertices (T = Vvi,Nni,Tti) in a mesh.
typedef union {
    struct {
        EGWuint16 iv1;                      ///< Triangle vertex array index 1.
        EGWuint16 in1;                      ///< Triangle normal array index 1.
        EGWuint16 it1;                      ///< Triangle texture array index 1.
        EGWuint16 iv2;                      ///< Triangle vertex array index 2.
        EGWuint16 in2;                      ///< Triangle normal array index 2.
        EGWuint16 it2;                      ///< Triangle texture array index 2.
        EGWuint16 iv3;                      ///< Triangle vertex array index 3.
        EGWuint16 in3;                      ///< Triangle normal array index 3.
        EGWuint16 it3;                      ///< Triangle texture array index 3.
    } face;                                 ///< Triangle component indices.
    EGWuint16 index[9];                     ///< Triangle indices array.
    EGWuint8 bytes[18];                     ///< Byte array.
} egwDITFace;


// !!!: ***** Static Polygon Meshes *****

/// Static Triangles Vertex Array Mesh (Float).
/// Static mesh structure.
typedef struct {
    EGWuint16 vCount;                       ///< Vertex count.
    egwVector3f* vCoords;                   ///< Vertex coords array (owned).
    egwVector3f* nCoords;                   ///< Normal coords array (owned).
    egwVector2f* tCoords;                   ///< Texture coords array (owned).
} egwSTVAMeshf;

/// Static Joint Indexed Triangles Vertex Array Mesh (Float).
/// Static mesh structure with face indexing via joint lookup.
typedef struct {
    EGWuint16 vCount;                       ///< Vertex count.
    EGWuint16 fCount;                       ///< Face count.
    egwVector3f* vCoords;                   ///< Vertex coords array (owned).
    egwVector3f* nCoords;                   ///< Normal coords array (owned).
    egwVector2f* tCoords;                   ///< Texture coords array (owned).
    egwJITFace* fIndicies;                  ///< Face indexing array (owned).
} egwSJITVAMeshf;

/// Static Disjoint Indexed Triangles Vertex Array Mesh (Float).
/// Static mesh structure with face indexing via disjoint lookup.
typedef struct {
    EGWuint16 vCount;                       ///< Vertex count.
    EGWuint16 nCount;                       ///< Normal count.
    EGWuint16 tCount;                       ///< Texture count.
    EGWuint16 fCount;                       ///< Face count.
    egwVector3f* vCoords;                   ///< Vertex coords array (owned).
    egwVector3f* nCoords;                   ///< Normal coords array (owned).
    egwVector2f* tCoords;                   ///< Texture coords array (owned).
    egwDITFace* fIndicies;                  ///< Face indexing array (owned).
} egwSDITVAMeshf;


// !!!: ***** Animated Polygon Meshes *****

/// Key Framed Triangles Vertex Array Mesh.
/// KF animated mesh structure.
typedef struct {
    EGWuint16 vCount;                       ///< Vertex count.
    EGWuint16 vfCount;                      ///< Vertex key frame count.
    EGWuint16 nfCount;                      ///< Normal key frame count.
    EGWuint16 tfCount;                      ///< Texture key frame count.
    egwVector3f* vkCoords;                  ///< Vertex key framed coords array (owned).
    egwVector3f* nkCoords;                  ///< Normal key framed coords array (owned).
    egwVector2f* tkCoords;                  ///< Texture key framed coords array (owned).
    EGWtime* vtIndicies;                    ///< Vertex time indicies (owned, may be shared against another time index array).
    EGWtime* ntIndicies;                    ///< Normal time indicies (owned, may be shared against another time index array).
    EGWtime* ttIndicies;                    ///< Texture time indicies (owned, may be shared against another time index array).
    EGWbyte* vkfExtraDat;                   ///< Extra vertex frame key data (if applicable) (owned).
    EGWbyte* nkfExtraDat;                   ///< Extra normal frame key data (if applicable) (owned).
    EGWbyte* tkfExtraDat;                   ///< Extra texture frame key data (if applicable) (owned).
} egwKFTVAMeshf;

/// Key Framed Joint Indexed Triangles Vertex Array Mesh.
/// KF animated mesh structure with face indexing via joint lookup.
typedef struct {
    EGWuint16 vCount;                       ///< Vertex count.
    EGWuint16 fCount;                       ///< Face count.
    EGWuint16 vfCount;                      ///< Vertex key frame count.
    EGWuint16 nfCount;                      ///< Normal key frame count.
    EGWuint16 tfCount;                      ///< Texture key frame count.
    egwVector3f* vkCoords;                  ///< Vertex key framed coords array (owned).
    egwVector3f* nkCoords;                  ///< Normal key framed coords array (owned).
    egwVector2f* tkCoords;                  ///< Texture key framed coords array (owned).
    egwJITFace* fIndicies;                  ///< Face indexing array (owned).
    EGWtime* vtIndicies;                    ///< Vertex time indicies (owned, may be shared against another time index array).
    EGWtime* ntIndicies;                    ///< Normal time indicies (owned, may be shared against another time index array).
    EGWtime* ttIndicies;                    ///< Texture time indicies (owned, may be shared against another time index array).
    EGWbyte* vkfExtraDat;                   ///< Extra vertex frame key data (if applicable) (owned).
    EGWbyte* nkfExtraDat;                   ///< Extra normal frame key data (if applicable) (owned).
    EGWbyte* tkfExtraDat;                   ///< Extra texture frame key data (if applicable) (owned).
} egwKFJITVAMeshf;

/// Key Framed Disjoint Indexed Triangles Vertex Array Mesh.
/// KF animated mesh structure with face indexing via disjoint lookup.
typedef struct {
    EGWuint16 vCount;                       ///< Vertex count.
    EGWuint16 nCount;                       ///< Normal count.
    EGWuint16 tCount;                       ///< Texture count.
    EGWuint16 fCount;                       ///< Face count.
    EGWuint16 vfCount;                      ///< Vertex key frame count.
    EGWuint16 nfCount;                      ///< Normal key frame count.
    EGWuint16 tfCount;                      ///< Texture key frame count.
    egwVector3f* vkCoords;                  ///< Vertex key framed coords array (owned).
    egwVector3f* nkCoords;                  ///< Normal key framed coords array (owned).
    egwVector2f* tkCoords;                  ///< Texture key framed coords array (owned).
    egwDITFace* fIndicies;                  ///< Face indexing array (owned).
    EGWtime* vtIndicies;                    ///< Vertex time indicies (owned, may be shared against another time index array).
    EGWtime* ntIndicies;                    ///< Normal time indicies (owned, may be shared against another time index array).
    EGWtime* ttIndicies;                    ///< Texture time indicies (owned, may be shared against another time index array).
    EGWbyte* vkfExtraDat;                   ///< Extra vertex frame key data (if applicable) (owned).
    EGWbyte* nkfExtraDat;                   ///< Extra normal frame key data (if applicable) (owned).
    EGWbyte* tkfExtraDat;                   ///< Extra texture frame key data (if applicable) (owned).
} egwKFDITVAMeshf;


// !!!: ***** Special Effects *****

/// Variant Value (Float).
/// Variant value structure.
typedef struct {
    EGWsingle origin;                       ///< Linear origin value.
    EGWsingle variant;                      ///< Linear variance value.
    EGWsingle deltaT;                       ///< Linear change over time.
} egwVariantValuef;

/// 2-D Variant Vector.
/// Two dimensional variant vector structure.
typedef struct {
    egwVector2f origin;                     ///< Linear origin vector.
    egwVector2f variant;                    ///< Linear variance vector.
    egwVector2f deltaT;                     ///< Linear change over time.
} egwVariantVector2f;

/// 3-D Variant Vector.
/// Three dimensional variant vector structure.
typedef struct {
    egwVector3f origin;                     ///< Linear origin vector.
    egwVector3f variant;                    ///< Linear variance vector.
    egwVector3f deltaT;                     ///< Linear change over time.
} egwVariantVector3f;

/// 4-D Variant Vector.
/// Four dimensional variant vector structure.
typedef struct {
    egwVector4f origin;                     ///< Linear origin vector.
    egwVector4f variant;                    ///< Linear variance vector.
    egwVector4f deltaT;                     ///< Linear change over time.
} egwVariantVector4f;

/// Particle System Particle Dynamics.
/// Particle system particle initialize and update dynamics.
typedef struct {
    egwVariantVector3f pPosition;           ///< Position starting data (MCS).
    egwVariantVector3f pVelocity;           ///< Velocity starting data (MCS).
    egwVariantValuef pSize;                 ///< Size starting data (MCS).
    egwVariantValuef pWeight;               ///< Weight starting data.
    egwVariantValuef pLife;                 ///< Life left (countdown) starting data.
    egwVariantVector4f pColor;              ///< Coloration (non-clamped) starting data.
} egwPSParticleDynamics;

/// Particle System System Dynamics.
/// Particle system system initialize and update dynamics.
typedef struct {
    EGWuint16 psFlags;                      ///< Particle system flags.
    EGWuint16 mParticles;                   ///< Maximum particles (or 0 if infinite).
    union {
        egwVariantValuef tParticles;        ///< Total particles starting data.
        egwVariantValuef eTimeout;          ///< Emitter timeout starting data.
    } eDuration;                            ///< Emitter duration data.
    egwVariantValuef pFrequency;            ///< Emitter frequency starting data.
} egwPSSystemDynamics;

/// Particle System Particle.
/// Particle system particle data.
typedef struct {
    egwVector3f position;                   ///< Position vector (MCS).
    egwVector3f velocity;                   ///< Velocity vector (MCS).
    EGWsingle size;                         ///< Relative particle size (MCS).
    EGWsingle weight;                       ///< Particle weight (for external force calc.).
    EGWtime ltLeft;                         ///< Life time left (countdown).
    EGWtime ltAlive;                        ///< Life time alive (countup).
    egwColor4f color;                       ///< Coloration (non-clamped).
    egwMatrix44f* twcsTrans;                ///< Total world transform at creation time (MMCS->WCS).
} egwPSParticle;


// !!!: ***** Event Delegate Protocols *****

/// Geometry Event Delegate.
/// Defines events that a delegate object can handle.
@protocol egwDGeometryEvent <NSObject>

/// Geometry Did Behavior.
/// Called when a geometry object performs a behavior related to rendering.
/// @param [in] geometry Geometry object.
/// @param [in] action Behavioral flag setting (EGW_ACTION_*).
- (void)geometry:(id<egwPGeometry>)geometry did:(EGWuint32)action;

@end

/// @}

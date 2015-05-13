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

/// @defgroup geWizES_geo_graphics egwGeometry
/// @ingroup geWizES_geo
/// Base Geometry.
/// @{

/// @file egwMath.h
/// Base Geometry Interface.

#import "egwGeoTypes.h"
#import "../math/egwMath.h"
#import "../gfx/egwGfxTypes.h"


// !!!: ***** Defines *****

// Collision testing
#define EGW_CLSNTEST_BVOL_NA            -1  ///< Test not supported.
#define EGW_CLSNTEST_BVOL_NONE          0   ///< Volume lhs is not touching, intersecting, contained by, equal to, nor contains volume rhs.
#define EGW_CLSNTEST_BVOL_TOUCHES       1   ///< Volume lhs touches volume rhs's edge.
#define EGW_CLSNTEST_BVOL_INTERSECTS    2   ///< Volume lhs intersects volume rhs.
#define EGW_CLSNTEST_BVOL_CONTAINEDBY   3   ///< Volume lhs contained by volume rhs.
#define EGW_CLSNTEST_BVOL_EQUALS        4   ///< Volume lhs is equal to volume rhs.
#define EGW_CLSNTEST_BVOL_CONTAINS      5   ///< Volume lhs is containing volume rhs.
#define EGW_CLSNTEST_POINT_NA           -1  ///< Test not supported.
#define EGW_CLSNTEST_POINT_NONE         0   ///< Point rhs is not touching nor contained by volume lhs.
#define EGW_CLSNTEST_POINT_TOUCHES      1   ///< Point rhs touches volume lhs's edge.
#define EGW_CLSNTEST_POINT_CONTAINEDBY  2   ///< Point rhs is contained by volume lhs.
#define EGW_CLSNTEST_LINE_NA            -1  ///< Test not supported.
#define EGW_CLSNTEST_LINE_NONE          0   ///< Line rhs is not touching nor intersecting volume lhs.
#define EGW_CLSNTEST_LINE_TOUCHES       1   ///< Line rhs touches volume lhs's edge.
#define EGW_CLSNTEST_LINE_INTERSECTS    2   ///< Line rhs intersects volume lhs.
#define EGW_CLSNTEST_PLANE_NA           -1  ///< Test not supported.
#define EGW_CLSNTEST_PLANE_NONE         0   ///< Plane rhs is not touching nor intersecting volume lhs.
#define EGW_CLSNTEST_PLANE_TOUCHES      1   ///< Plane rhs touches volume lhs's edge.
#define EGW_CLSNTEST_PLANE_INTERSECTS   2   ///< Plane rhs intersects volume lhs.


// !!!: ***** Helper Routines *****

/// Geometry Surface Framing Texture Transform Routine.
/// Calculates the appropriate texture transform of a surface framing given the provided parameters.
/// @param [in] sFrame_in Surface framing structure.
/// @param [in] fIndex_in Frame index (should be a valid member of the surface framing).
/// @param [out] tTransform_out Texture transform.
void egwGeomSFrmTexTransform(const egwSurfaceFraming* sFrame_in, const EGWuint16 fIndex_in, egwMatrix44f* tTransform_out);


// !!!: ***** Static Collision Testing (Sphere) *****

/// Is Colliding Testing Routine (Sphere vs. Point).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] sphere_lhs Sphere lhs structure.
/// @param [in] point_rhs Point rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingSpherePointf(const egwSphere4f* sphere_lhs, const egwVector3f* point_rhs);

/// Is Colliding Testing Routine (Sphere vs. Line).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] sphere_lhs Sphere lhs structure.
/// @param [in] line_rhs Line rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingSphereLinef(const egwSphere4f* sphere_lhs, const egwLine4f* line_rhs);

/// Is Colliding Testing Routine (Sphere vs. Plane).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] sphere_lhs Sphere lhs structure.
/// @param [in] plane_rhs Plane rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingSpherePlanef(const egwSphere4f* sphere_lhs, const egwPlane4f* plane_rhs);

/// Is Colliding Testing Routine (Sphere vs. Sphere).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] sphere_lhs Sphere lhs structure.
/// @param [in] sphere_rhs Sphere rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingSphereSpheref(const egwSphere4f* sphere_lhs, const egwSphere4f* sphere_rhs);

/// Is Colliding Testing Routine (Sphere vs. Box).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] sphere_lhs Sphere lhs structure.
/// @param [in] box_rhs Box rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingSphereBoxf(const egwSphere4f* sphere_lhs, const egwBox4f* box_rhs);

/// Is Colliding Testing Routine (Sphere vs. Cylinder).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] sphere_lhs Sphere lhs structure.
/// @param [in] cylinder_rhs Cylinder rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingSphereCylinderf(const egwSphere4f* sphere_lhs, const egwCylinder4f* cylinder_rhs);

/// Is Colliding Testing Routine (Sphere vs. Frustum).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] sphere_lhs Sphere lhs structure.
/// @param [in] frustum_rhs Frustum rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingSphereFrustumf(const egwSphere4f* sphere_lhs, const egwFrustum4f* frustum_rhs);

/// Test Collision Testing Routine (Sphere vs. Point).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] sphere_lhs Sphere lhs structure.
/// @param [in] point_rhs Point rhs structure.
/// @return Type of collision (EGW_CLSNTEST_POINT_*).
EGWint egwTestCollisionSpherePointf(const egwSphere4f* sphere_lhs, const egwVector3f* point_rhs);

/// Test Collision Testing Routine (Sphere vs. Line).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] sphere_lhs Sphere lhs structure.
/// @param [in] line_rhs Line rhs structure.
/// @param [out] begT_out Beginning intersection T value (may be NULL).
/// @param [out] endT_out Ending intersection T value (may be NULL).
/// @return Type of collision (EGW_CLSNTEST_LINE_*).
EGWint egwTestCollisionSphereLinef(const egwSphere4f* sphere_lhs, const egwLine4f* line_rhs, EGWsingle* begT_out, EGWsingle* endT_out);

/// Test Collision Testing Routine (Sphere vs. Plane).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] sphere_lhs Sphere lhs structure.
/// @param [in] plane_rhs Plane rhs structure.
/// @param [out] side_out Side of plane lhs structure is relative to rhs (may be NULL).
/// @return Type of collision (EGW_CLSNTEST_PLANE_*).
EGWint egwTestCollisionSpherePlanef(const egwSphere4f* sphere_lhs, const egwPlane4f* plane_rhs, EGWint* side_out);

/// Test Collision Testing Routine (Sphere vs. Sphere).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] sphere_lhs Sphere lhs structure.
/// @param [in] sphere_rhs Sphere rhs structure.
/// @return Type of collision (EGW_CLSNTEST_BVOL_*).
EGWint egwTestCollisionSphereSpheref(const egwSphere4f* sphere_lhs, const egwSphere4f* sphere_rhs);

/// Test Collision Testing Routine (Sphere vs. Box).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] sphere_lhs Sphere lhs structure.
/// @param [in] box_rhs Box rhs structure.
/// @return Type of collision (EGW_CLSNTEST_BVOL_*).
EGWint egwTestCollisionSphereBoxf(const egwSphere4f* sphere_lhs, const egwBox4f* box_rhs);

/// Test Collision Testing Routine (Sphere vs. Cylinder).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] sphere_lhs Sphere lhs structure.
/// @param [in] cylinder_rhs Cylinder rhs structure.
/// @return Type of collision (EGW_CLSNTEST_BVOL_*).
EGWint egwTestCollisionSphereCylinderf(const egwSphere4f* sphere_lhs, const egwCylinder4f* cylinder_rhs);

/// Test Collision Testing Routine (Sphere vs. Frustum).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] sphere_lhs Sphere lhs structure.
/// @param [in] frustum_rhs Frustum rhs structure.
/// @return Type of collision (EGW_CLSNTEST_BVOL_*).
EGWint egwTestCollisionSphereFrustumf(const egwSphere4f* sphere_lhs, const egwFrustum4f* frustum_rhs);


// !!!: ***** Static Collision Testing (Box) *****

/// Is Colliding Testing Routine (Box vs. Point).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] box_lhs Box lhs structure.
/// @param [in] point_rhs Point rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingBoxPointf(const egwBox4f* box_lhs, const egwVector3f* point_rhs);

/// Is Colliding Testing Routine (Box vs. Line).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] box_lhs Box lhs structure.
/// @param [in] line_rhs Line rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingBoxLinef(const egwBox4f* box_lhs, const egwLine4f* line_rhs);

/// Is Colliding Testing Routine (Box vs. Plane).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] box_lhs Box lhs structure.
/// @param [in] plane_rhs Plane rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingBoxPlanef(const egwBox4f* box_lhs, const egwPlane4f* plane_rhs);

/// Is Colliding Testing Routine (Box vs. Sphere).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] box_lhs Box lhs structure.
/// @param [in] sphere_rhs Sphere rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingBoxSpheref(const egwBox4f* box_lhs, const egwSphere4f* sphere_rhs);

/// Is Colliding Testing Routine (Box vs. Box).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] box_lhs Box lhs structure.
/// @param [in] box_rhs Box rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingBoxBoxf(const egwBox4f* box_lhs, const egwBox4f* box_rhs);

/// Is Colliding Testing Routine (Box vs. Cylinder).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] box_lhs Box lhs structure.
/// @param [in] cylinder_rhs Cylinder rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingBoxCylinderf(const egwBox4f* box_lhs, const egwCylinder4f* cylinder_rhs);

/// Is Colliding Testing Routine (Box vs. Frustum).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] box_lhs Box lhs structure.
/// @param [in] frustum_rhs Frustum rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingBoxFrustumf(const egwBox4f* box_lhs, const egwFrustum4f* frustum_rhs);

/// Test Collision Testing Routine (Box vs. Point).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] box_lhs Box lhs structure.
/// @param [in] point_rhs Point rhs structure.
/// @return Type of collision (EGW_CLSNTEST_POINT_*).
EGWint egwTestCollisionBoxPointf(const egwBox4f* box_lhs, const egwVector3f* point_rhs);

/// Test Collision Testing Routine (Box vs. Line).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] box_lhs Box lhs structure.
/// @param [in] line_rhs Line rhs structure.
/// @param [out] begT_out Beginning intersection T value (may be NULL).
/// @param [out] endT_out Ending intersection T value (may be NULL).
/// @return Type of collision (EGW_CLSNTEST_LINE_*).
EGWint egwTestCollisionBoxLinef(const egwBox4f* box_lhs, const egwLine4f* line_rhs, EGWsingle* begT_out, EGWsingle* endT_out);

/// Test Collision Testing Routine (Box vs. Plane).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] box_lhs Box lhs structure.
/// @param [in] plane_rhs Plane rhs structure.
/// @param [out] side_out Side of plane lhs structure is relative to rhs (may be NULL).
/// @return Type of collision (EGW_CLSNTEST_PLANE_*).
EGWint egwTestCollisionBoxPlanef(const egwBox4f* box_lhs, const egwPlane4f* plane_rhs, EGWint* side_out);

/// Test Collision Testing Routine (Box vs. Sphere).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] box_lhs Box lhs structure.
/// @param [in] sphere_rhs Sphere rhs structure.
/// @return Type of collision (EGW_CLSNTEST_BVOL_*).
EGWint egwTestCollisionBoxSpheref(const egwBox4f* box_lhs, const egwSphere4f* sphere_rhs);

/// Test Collision Testing Routine (Box vs. Box).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] box_lhs Box lhs structure.
/// @param [in] box_rhs Box rhs structure.
/// @return Type of collision (EGW_CLSNTEST_BVOL_*).
EGWint egwTestCollisionBoxBoxf(const egwBox4f* box_lhs, const egwBox4f* box_rhs);

/// Test Collision Testing Routine (Box vs. Cylinder).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] box_lhs Box lhs structure.
/// @param [in] cylinder_rhs Cylinder rhs structure.
/// @return Type of collision (EGW_CLSNTEST_BVOL_*).
EGWint egwTestCollisionBoxCylinderf(const egwBox4f* box_lhs, const egwCylinder4f* cylinder_rhs);

/// Test Collision Testing Routine (Box vs. Frustum).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] box_lhs Box lhs structure.
/// @param [in] frustum_rhs Frustum rhs structure.
/// @return Type of collision (EGW_CLSNTEST_BVOL_*).
EGWint egwTestCollisionBoxFrustumf(const egwBox4f* box_lhs, const egwFrustum4f* frustum_rhs);


// !!!: ***** Static Collision Testing (Cylinder) *****

/// Is Colliding Testing Routine (Cylinder vs. Point).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] cylinder_lhs Cylinder lhs structure.
/// @param [in] point_rhs Point rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingCylinderPointf(const egwCylinder4f* cylinder_lhs, const egwVector3f* point_rhs);

/// Is Colliding Testing Routine (Cylinder vs. Line).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] cylinder_lhs Cylinder lhs structure.
/// @param [in] line_rhs Line rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingCylinderLinef(const egwCylinder4f* cylinder_lhs, const egwLine4f* line_rhs);

/// Is Colliding Testing Routine (Cylinder vs. Plane).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] cylinder_lhs Cylinder lhs structure.
/// @param [in] plane_rhs Plane rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingCylinderPlanef(const egwCylinder4f* cylinder_lhs, const egwPlane4f* plane_rhs);

/// Is Colliding Testing Routine (Cylinder vs. Sphere).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] cylinder_lhs Cylinder lhs structure.
/// @param [in] sphere_rhs Sphere rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingCylinderSpheref(const egwCylinder4f* cylinder_lhs, const egwSphere4f* sphere_rhs);

/// Is Colliding Testing Routine (Cylinder vs. Box).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] cylinder_lhs Cylinder lhs structure.
/// @param [in] box_rhs Box rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingCylinderBoxf(const egwCylinder4f* cylinder_lhs, const egwBox4f* box_rhs);

/// Is Colliding Testing Routine (Cylinder vs. Cylinder).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] cylinder_lhs Cylinder lhs structure.
/// @param [in] cylinder_rhs Cylinder rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingCylinderCylinderf(const egwCylinder4f* cylinder_lhs, const egwCylinder4f* cylinder_rhs);

/// Is Colliding Testing Routine (Cylinder vs. Frustum).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] cylinder_lhs Cylinder lhs structure.
/// @param [in] frustum_rhs Frustum rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingCylinderFrustumf(const egwCylinder4f* cylinder_lhs, const egwFrustum4f* frustum_rhs);

/// Test Collision Testing Routine (Cylinder vs. Point).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] cylinder_lhs Cylinder lhs structure.
/// @param [in] point_rhs Point rhs structure.
/// @return Type of collision (EGW_CLSNTEST_POINT_*).
EGWint egwTestCollisionCylinderPointf(const egwCylinder4f* cylinder_lhs, const egwVector3f* point_rhs);

/// Test Collision Testing Routine (Cylinder vs. Line).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] cylinder_lhs Cylinder lhs structure.
/// @param [in] line_rhs Line rhs structure.
/// @param [out] begT_out Beginning intersection T value (may be NULL).
/// @param [out] endT_out Ending intersection T value (may be NULL).
/// @return Type of collision (EGW_CLSNTEST_LINE_*).
EGWint egwTestCollisionCylinderLinef(const egwCylinder4f* cylinder_lhs, const egwLine4f* line_rhs, EGWsingle* begT_out, EGWsingle* endT_out);

/// Test Collision Testing Routine (Cylinder vs. Plane).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] cylinder_lhs Cylinder lhs structure.
/// @param [in] plane_rhs Plane rhs structure.
/// @param [out] side_out Side of plane lhs structure is relative to rhs (may be NULL).
/// @return Type of collision (EGW_CLSNTEST_PLANE_*).
EGWint egwTestCollisionCylinderPlanef(const egwCylinder4f* cylinder_lhs, const egwPlane4f* plane_rhs, EGWint* side_out);

/// Test Collision Testing Routine (Cylinder vs. Sphere).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] cylinder_lhs Cylinder lhs structure.
/// @param [in] sphere_rhs Sphere rhs structure.
/// @return Type of collision (EGW_CLSNTEST_BVOL_*).
EGWint egwTestCollisionCylinderSpheref(const egwCylinder4f* cylinder_lhs, const egwSphere4f* sphere_rhs);

/// Test Collision Testing Routine (Cylinder vs. Box).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] cylinder_lhs Cylinder lhs structure.
/// @param [in] box_rhs Box rhs structure.
/// @return Type of collision (EGW_CLSNTEST_BVOL_*).
EGWint egwTestCollisionCylinderBoxf(const egwCylinder4f* cylinder_lhs, const egwBox4f* box_rhs);

/// Test Collision Testing Routine (Cylinder vs. Cylinder).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] cylinder_lhs Cylinder lhs structure.
/// @param [in] cylinder_rhs Cylinder rhs structure.
/// @return Type of collision (EGW_CLSNTEST_BVOL_*).
EGWint egwTestCollisionCylinderCylinderf(const egwCylinder4f* cylinder_lhs, const egwCylinder4f* cylinder_rhs);

/// Test Collision Testing Routine (Cylinder vs. Frustum).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] cylinder_lhs Cylinder lhs structure.
/// @param [in] frustum_rhs Frustum rhs structure.
/// @return Type of collision (EGW_CLSNTEST_BVOL_*).
EGWint egwTestCollisionCylinderFrustumf(const egwCylinder4f* cylinder_lhs, const egwFrustum4f* frustum_rhs);


// !!!: ***** Static Collision Testing (Frustum) *****

/// Is Colliding Testing Routine (Frustum vs. Point).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] frustum_lhs Frustum lhs structure.
/// @param [in] point_rhs Point rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingFrustumPointf(const egwFrustum4f* frustum_lhs, const egwVector3f* point_rhs);

/// Is Colliding Testing Routine (Frustum vs. Line).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] frustum_lhs Frustum lhs structure.
/// @param [in] line_rhs Line rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingFrustumLinef(const egwFrustum4f* frustum_lhs, const egwLine4f* line_rhs);

/// Is Colliding Testing Routine (Frustum vs. Plane).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] frustum_lhs Frustum lhs structure.
/// @param [in] plane_rhs Plane rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingFrustumPlanef(const egwFrustum4f* frustum_lhs, const egwPlane4f* plane_rhs);

/// Is Colliding Testing Routine (Frustum vs. Sphere).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] frustum_lhs Frustum lhs structure.
/// @param [in] sphere_rhs Sphere rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingFrustumSpheref(const egwFrustum4f* frustum_lhs, const egwSphere4f* sphere_rhs);

/// Is Colliding Testing Routine (Frustum vs. Box).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] frustum_lhs Frustum lhs structure.
/// @param [in] box_rhs Box rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingFrustumBoxf(const egwFrustum4f* frustum_lhs, const egwBox4f* box_rhs);

/// Is Colliding Testing Routine (Frustum vs. Cylinder).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] frustum_lhs Frustum lhs structure.
/// @param [in] cylinder_rhs Cylinder rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingFrustumCylinderf(const egwFrustum4f* frustum_lhs, const egwCylinder4f* cylinder_rhs);

/// Is Colliding Testing Routine (Frustum vs. Frustum).
/// Tests for a simple contact collision (using minimal operations) between the lhs and rhs geometries.
/// @param [in] frustum_lhs Frustum lhs structure.
/// @param [in] frustum_rhs Frustum rhs structure.
/// @return 1 if shapes are colliding, otherwise 0.
EGWint egwIsCollidingFrustumFrustumf(const egwFrustum4f* frustum_lhs, const egwFrustum4f* frustum_rhs);

/// Test Collision Testing Routine (Frustum vs. Point).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] frustum_lhs Frustum lhs structure.
/// @param [in] point_rhs Point rhs structure.
/// @return Type of collision (EGW_CLSNTEST_POINT_*).
EGWint egwTestCollisionFrustumPointf(const egwFrustum4f* frustum_lhs, const egwVector3f* point_rhs);

/// Test Collision Testing Routine (Frustum vs. Line).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] frustum_lhs Frustum lhs structure.
/// @param [in] line_rhs Line rhs structure.
/// @param [out] begT_out Beginning intersection T value (may be NULL).
/// @param [out] endT_out Ending intersection T value (may be NULL).
/// @return Type of collision (EGW_CLSNTEST_LINE_*).
EGWint egwTestCollisionFrustumLinef(const egwFrustum4f* frustum_lhs, const egwLine4f* line_rhs, EGWsingle* begT_out, EGWsingle* endT_out);

/// Test Collision Testing Routine (Frustum vs. Plane).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] frustum_lhs Frustum lhs structure.
/// @param [in] plane_rhs Plane rhs structure.
/// @param [out] side_out Side of plane lhs structure is relative to rhs (may be NULL).
/// @return Type of collision (EGW_CLSNTEST_PLANE_*).
EGWint egwTestCollisionFrustumPlanef(const egwFrustum4f* frustum_lhs, const egwPlane4f* plane_rhs, EGWint* side_out);

/// Test Collision Testing Routine (Frustum vs. Sphere).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] frustum_lhs Frustum lhs structure.
/// @param [in] sphere_rhs Sphere rhs structure.
/// @return Type of collision (EGW_CLSNTEST_BVOL_*).
EGWint egwTestCollisionFrustumSpheref(const egwFrustum4f* frustum_lhs, const egwSphere4f* sphere_rhs);

/// Test Collision Testing Routine (Frustum vs. Box).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] frustum_lhs Frustum lhs structure.
/// @param [in] box_rhs Box rhs structure.
/// @return Type of collision (EGW_CLSNTEST_BVOL_*).
EGWint egwTestCollisionFrustumBoxf(const egwFrustum4f* frustum_lhs, const egwBox4f* box_rhs);

/// Test Collision Testing Routine (Frustum vs. Cylinder).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] frustum_lhs Frustum lhs structure.
/// @param [in] cylinder_rhs Cylinder rhs structure.
/// @return Type of collision (EGW_CLSNTEST_BVOL_*).
EGWint egwTestCollisionFrustumCylinderf(const egwFrustum4f* frustum_lhs, const egwCylinder4f* cylinder_rhs);

/// Test Collision Testing Routine (Frustum vs. Frustum).
/// Tests for collision (using full operation) between the lhs and rhs geometries.
/// @param [in] frustum_lhs Frustum lhs structure.
/// @param [in] frustum_rhs Frustum rhs structure.
/// @return Type of collision (EGW_CLSNTEST_BVOL_*).
EGWint egwTestCollisionFrustumFrustumf(const egwFrustum4f* frustum_lhs, const egwFrustum4f* frustum_rhs);


// !!!: ***** Basic Geometric Routines *****

/// 2-D Point On Line Closest To Point Routine.
/// Calulates the T value of a point on the line that is closest to the reference point provided.
/// @param [in] line_lhs Line lhs structure.
/// @param [in] point_rhs Reference point rhs structure.
/// @return T value along line of closest point.
EGWsingle egwLinePointClosestS3f(const egwLine3f* line_lhs, const egwVector2f* point_rhs);

/// 3-D Point On Line Closest To Point Routine.
/// Calulates the T value of a point on the line that is closest to the reference point provided.
/// @param [in] line_lhs Line lhs structure.
/// @param [in] point_rhs Reference point rhs structure.
/// @return T value along line of closest point.
EGWsingle egwLinePointClosestS4f(const egwLine4f* line_lhs, const egwVector3f* point_rhs);

/// 2-D Point On Line Closest To Point Distance Routine.
/// Calulates the distance from a point on the line that is closest to the reference point provided to that reference point.
/// @param [in] line_lhs Line lhs structure.
/// @param [in] point_rhs Reference point rhs structure.
/// @return Distance from reference point to closest point on line.
EGWsingle egwLinePointClosestDist3f(const egwLine3f* line_lhs, const egwVector2f* point_rhs);

/// 3-D Point On Line Closest To Point Distance Routine.
/// Calulates the distance from a point on the line that is closest to the reference point provided to that reference point.
/// @param [in] line_lhs Line lhs structure.
/// @param [in] point_rhs Reference point rhs structure.
/// @return Distance from reference point to closest point on line.
EGWsingle egwLinePointClosestDist4f(const egwLine4f* line_lhs, const egwVector3f* point_rhs);

/// 2-D Point On Line Closest To Point Distance Squared Routine.
/// Calulates the squared distance from a point on the line that is closest to the reference point provided to that reference point.
/// @param [in] line_lhs Line lhs structure.
/// @param [in] point_rhs Reference point rhs structure.
/// @return Squared distance from reference point to closest point on line.
EGWsingle egwLinePointClosestDistSqrd3f(const egwLine3f* line_lhs, const egwVector2f* point_rhs);

/// 3-D Point On Line Closest To Point Distance Squared Routine.
/// Calulates the squared distance from a point on the line that is closest to the reference point provided to that reference point.
/// @param [in] line_lhs Line lhs structure.
/// @param [in] point_rhs Reference point rhs structure.
/// @return Squared distance from reference point to closest point on line.
EGWsingle egwLinePointClosestDistSqrd4f(const egwLine4f* line_lhs, const egwVector3f* point_rhs);

/// 2-D Point On Line Closest to Line Routine.
/// Calculates the S value of a point on the lhs line that is closest to the rhs line.
/// @param [in] line_lhs Line lhs structure.
/// @param [in] line_rhs Line rhs structure.
/// @return S value alone lhs line of closest point.
EGWsingle egwLineLineClosestS3f(const egwLine3f* line_lhs, const egwLine3f* line_rhs);

/// 3-D Point On Line Closest to Line Routine.
/// Calculates the S value of a point on the lhs line that is closest to the rhs line.
/// @param [in] line_lhs Line lhs structure.
/// @param [in] line_rhs Line rhs structure.
/// @return S value alone lhs line of closest point.
EGWsingle egwLineLineClosestS4f(const egwLine4f* line_lhs, const egwLine4f* line_rhs);

/// 2-D Point On Line Closest to Line (S&T) Routine.
/// Calculates both the S value of a point on the lhs line that is closest to the rhs line and the T value of a point on the rhs line that is closest to the lhs line.
/// @param [in] line_lhs Line lhs structure.
/// @param [in] line_rhs Line rhs structure.
/// @param [out] s_out S value along lhs line of closest point.
/// @param [out] t_out T value along rhs line of closest point.
void egwLineLineClosestST3f(const egwLine3f* line_lhs, const egwLine3f* line_rhs, EGWsingle* s_out, EGWsingle* t_out);

/// 3-D Point On Line Closest to Line (S&T) Routine.
/// Calculates both the S value of a point on the lhs line that is closest to the rhs line and the T value of a point on the rhs line that is closest to the lhs line.
/// @param [in] line_lhs Line lhs structure.
/// @param [in] line_rhs Line rhs structure.
/// @param [out] s_out S value along lhs line of closest point.
/// @param [out] t_out T value along rhs line of closest point.
void egwLineLineClosestST4f(const egwLine4f* line_lhs, const egwLine4f* line_rhs, EGWsingle* s_out, EGWsingle* t_out);

/// 2-D Point On Line Closest to Line Distance Routine.
/// Calculates the distance from a point on the lhs line that is closest to the rhs line to that closest point on the rhs line.
/// @param [in] line_lhs Line lhs structure.
/// @param [in] line_rhs Line rhs structure.
/// @return Distance between the two closest points along the lhs and rhs lines.
EGWsingle egwLineLineClosestDist3f(const egwLine3f* line_lhs, const egwLine3f* line_rhs);

/// 3-D Point On Line Closest to Line Distance Routine.
/// Calculates the distance from a point on the lhs line that is closest to the rhs line to that closest point on the rhs line.
/// @param [in] line_lhs Line lhs structure.
/// @param [in] line_rhs Line rhs structure.
/// @return Distance between the two closest points along the lhs and rhs lines.
EGWsingle egwLineLineClosestDist4f(const egwLine4f* line_lhs, const egwLine4f* line_rhs);

/// 2-D Point On Line Closest to Line Distance Squared Routine.
/// Calculates the squared distance from a point on the lhs line that is closest to the rhs line to that closest point on the rhs line.
/// @param [in] line_lhs Line lhs structure.
/// @param [in] line_rhs Line rhs structure.
/// @return Squared distance between the two closest points along the lhs and rhs lines.
EGWsingle egwLineLineClosestDistSqrd3f(const egwLine3f* line_lhs, const egwLine3f* line_rhs);

/// 3-D Point On Line Closest to Line Distance Squared Routine.
/// Calculates the squared distance from a point on the lhs line that is closest to the rhs line to that closest point on the rhs line.
/// @param [in] line_lhs Line lhs structure.
/// @param [in] line_rhs Line rhs structure.
/// @return Squared distance between the two closest points along the lhs and rhs lines.
EGWsingle egwLineLineClosestDistSqrd4f(const egwLine4f* line_lhs, const egwLine4f* line_rhs);

/// 3x3 Matrix 2-D Line Transform Routine.
/// Calculates line vector transforms with the provided parameters.
/// @param [in] mat_lhs 3x3 matrix lhs operand.
/// @param [in] line_rhs 2-D line rhs operand.
/// @param [out] line_out 2-D line vector output of transformations.
/// @return @a line_out (for nesting).
egwLine3f* egwLineTransform333f(const egwMatrix33f* mat_lhs, const egwLine3f* line_rhs, egwLine3f* line_out);

/// 4x4 Matrix 3-D Line Transform Routine.
/// Calculates line vector transforms with the provided parameters.
/// @param [in] mat_lhs 4x4 matrix lhs operand.
/// @param [in] line_rhs 3-D line rhs operand.
/// @param [out] line_out 3-D line vector output of transformations.
/// @return @a line_out (for nesting).
egwLine4f* egwLineTransform444f(const egwMatrix44f* mat_lhs, const egwLine4f* line_rhs, egwLine4f* line_out);

/// 2-D Point On Plane Closest To Point Routine.
/// Calulates the position of a point on the plane that is closest to the reference point provided.
/// @param [in] plane_lhs Plane lhs structure.
/// @param [in] point_rhs Reference point rhs structure.
/// @param [out] point_out Point on plane closet to reference point output structure.
/// @return @a point_out (for nesting).
egwVector2f* egwPlanePointPointClosest3f(const egwPlane3f* plane_lhs, const egwVector2f* point_rhs, egwVector2f* point_out);

/// 3-D Point On Plane Closest To Point Routine.
/// Calulates the position of a point on the plane that is closest to the reference point provided.
/// @param [in] plane_lhs Plane lhs structure.
/// @param [in] point_rhs Reference point rhs structure.
/// @param [out] point_out Point on plane closet to reference point output structure.
/// @return @a point_out (for nesting).
egwVector3f* egwPlanePointPointClosest4f(const egwPlane4f* plane_lhs, const egwVector3f* point_rhs, egwVector3f* point_out);

/// 2-D Point On Plane Closest To Point Distance Routine.
/// Calulates the distance from a point on the plane that is closest to the reference point provided to that reference point.
/// @param [in] plane_lhs Plane lhs structure.
/// @param [in] point_rhs Reference point rhs structure.
/// @return Distance from reference point to closest point on plane.
EGWsingle egwPlanePointClosestDist3f(const egwPlane3f* plane_lhs, const egwVector2f* point_rhs);

/// 3-D Point On Plane Closest To Point Distance Routine.
/// Calulates the distance from a point on the plane that is closest to the reference point provided to that reference point.
/// @param [in] plane_lhs Plane lhs structure.
/// @param [in] point_rhs Reference point rhs structure.
/// @return Distance from reference point to closest point on plane.
EGWsingle egwPlanePointClosestDist4f(const egwPlane4f* plane_lhs, const egwVector3f* point_rhs);

/// 2-D Point On Line Closest To Plane Routine.
/// Calculates the T value of a point on the rhs line that is closest to the lhs plane.
/// @param [in] plane_lhs Plane lhs structure.
/// @param [in] line_rhs Reference point rhs structure.
/// @return T value alone rhs line of closest point, otherwise EGW_SFLT_NAN if the line and plane are parallel.
EGWsingle egwPlaneLineClosestS3f(const egwPlane3f* plane_lhs, const egwLine3f* line_rhs);

/// 3-D Point On Line Closest To Plane Routine.
/// Calculates the T value of a point on the rhs line that is closest to the lhs plane.
/// @param [in] plane_lhs Plane lhs structure.
/// @param [in] line_rhs Reference point rhs structure.
/// @return T value alone rhs line of closest point, otherwise EGW_SFLT_NAN if the line and plane are parallel.
EGWsingle egwPlaneLineClosestS4f(const egwPlane4f* plane_lhs, const egwLine4f* line_rhs);

/// 3x3 Matrix 2-D Plane Transform Routine.
/// Calculates plane vector transforms with the provided parameters.
/// @param [in] mat_lhs 3x3 matrix lhs operand.
/// @param [in] plane_rhs 2-D plane rhs operand.
/// @param [out] plane_out 2-D plane vector output of transformations.
/// @return @a plane_out (for nesting).
egwPlane3f* egwPlaneTransform333f(const egwMatrix33f* mat_lhs, const egwPlane3f* plane_rhs, egwPlane3f* plane_out);

/// 4x4 Matrix 3-D Plane Transform Routine.
/// Calculates plane vector transforms with the provided parameters.
/// @param [in] mat_lhs 4x4 matrix lhs operand.
/// @param [in] plane_rhs 3-D plane rhs operand.
/// @param [out] plane_out 3-D plane vector output of transformations.
/// @return @a plane_out (for nesting).
egwPlane4f* egwPlaneTransform444f(const egwMatrix44f* mat_lhs, const egwPlane4f* plane_rhs, egwPlane4f* plane_out);


// !!!: ***** Mesh Operations *****

/// Static Triangle Vertex Array Mesh Allocation Routine.
/// Allocates mesh data with provided parameters.
/// @param [out] mesh_out Mesh output of allocation.
/// @param [in] verticesC_in Vertices count.
/// @param [in] normalsC_in Normals count.
/// @param [in] texuvsC_in Texture UVs count.
/// @return @a mesh_out (for nesting), otherwise NULL if failure allocating.
egwSTVAMeshf* egwMeshAllocSTVAf(egwSTVAMeshf* mesh_out, EGWuint16 verticesC_in, EGWuint16 normalsC_in, EGWuint16 texuvsC_in);

/// Static Jointly Indexed Triangle Vertex Array Mesh Allocation Routine.
/// Allocates mesh data with provided parameters.
/// @param [out] mesh_out Mesh output of allocation.
/// @param [in] verticesC_in Vertices count.
/// @param [in] normalsC_in Normals count.
/// @param [in] texuvsC_in Texture UVs count.
/// @param [in] facesC_in Faces count.
/// @return @a mesh_out (for nesting), otherwise NULL if failure allocating.
egwSJITVAMeshf* egwMeshAllocSJITVAf(egwSJITVAMeshf* mesh_out, EGWuint16 verticesC_in, EGWuint16 normalsC_in, EGWuint16 texuvsC_in, EGWuint16 facesC_in);

/// Static Disjointly Indexed Triangle Vertex Array Mesh Allocation Routine.
/// Allocates mesh data with provided parameters.
/// @param [out] mesh_out Mesh output of allocation.
/// @param [in] verticesC_in Vertices count.
/// @param [in] normalsC_in Normals count.
/// @param [in] texuvsC_in Texture UVs count.
/// @param [in] facesC_in Faces count.
/// @return @a mesh_out (for nesting), otherwise NULL if failure allocating.
egwSDITVAMeshf* egwMeshAllocSDITVAf(egwSDITVAMeshf* mesh_out, EGWuint16 verticesC_in, EGWuint16 normalsC_in, EGWuint16 texuvsC_in, EGWuint16 facesC_in);

/// Key Framed Triangle Vertex Array Mesh Allocation Routine.
/// Allocates key framed mesh data with provided parameters.
/// @param [out] mesh_out Key framed mesh output of allocation.
/// @param [in] verticesC_in Vertices count.
/// @param [in] normalsC_in Normals count.
/// @param [in] texuvsC_in Texture UVs count.
/// @param [in] vertFramesC_in Vertex frames count.
/// @param [in] nrmlFramesC_in Normal frames count.
/// @param [in] txuvFramesC_in Texture UV frames count.
/// @return @a mesh_out (for nesting), otherwise NULL if failure allocating.
egwKFTVAMeshf* egwMeshAllocKFTVAf(egwKFTVAMeshf* mesh_out, EGWuint16 verticesC_in, EGWuint16 normalsC_in, EGWuint16 texuvsC_in, EGWuint16 vertFramesC_in, EGWuint16 nrmlFramesC_in, EGWuint16 txuvFramesC_in);

/// Key Framed Jointly Indexed Triangle Vertex Array Mesh Allocation Routine.
/// Allocates key framed mesh data with provided parameters.
/// @param [out] mesh_out Key framed mesh output of allocation.
/// @param [in] verticesC_in Vertices count.
/// @param [in] normalsC_in Normals count.
/// @param [in] texuvsC_in Texture UVs count.
/// @param [in] facesC_in Faces count.
/// @param [in] vertFramesC_in Vertex frames count.
/// @param [in] nrmlFramesC_in Normal frames count.
/// @param [in] txuvFramesC_in Texture UV frames count.
/// @return @a mesh_out (for nesting), otherwise NULL if failure allocating.
egwKFJITVAMeshf* egwMeshAllocKFJITVAf(egwKFJITVAMeshf* mesh_out, EGWuint16 verticesC_in, EGWuint16 normalsC_in, EGWuint16 texuvsC_in, EGWuint16 facesC_in, EGWuint16 vertFramesC_in, EGWuint16 nrmlFramesC_in, EGWuint16 txuvFramesC_in);

/// Key Framed Disjointly Indexed Triangle Vertex Array Mesh Allocation Routine.
/// Allocates key framed mesh data with provided parameters.
/// @param [out] mesh_out Key framed mesh output of allocation.
/// @param [in] verticesC_in Vertices count.
/// @param [in] normalsC_in Normals count.
/// @param [in] texuvsC_in Texture UVs count.
/// @param [in] facesC_in Faces count.
/// @param [in] vertFramesC_in Vertex frames count.
/// @param [in] nrmlFramesC_in Normal frames count.
/// @param [in] txuvFramesC_in Texture UV frames count.
/// @return @a mesh_out (for nesting), otherwise NULL if failure allocating.
egwKFDITVAMeshf* egwMeshAllocKFDITVAf(egwKFDITVAMeshf* mesh_out, EGWuint16 verticesC_in, EGWuint16 normalsC_in, EGWuint16 texuvsC_in, EGWuint16 facesC_in, EGWuint16 vertFramesC_in, EGWuint16 nrmlFramesC_in, EGWuint16 txuvFramesC_in);

/// Static Triangle Vertex Array Mesh Free Routine.
/// Frees the contents of the mesh.
/// @param [in,out] mesh_inout Mesh input/output structure.
/// @return @a mesh_inout (for nesting).
egwSTVAMeshf* egwMeshFreeSTVAf(egwSTVAMeshf* mesh_inout);

/// Static Jointly Indexed Triangle Vertex Array Mesh Free Routine.
/// Frees the contents of the mesh.
/// @param [in,out] mesh_inout Mesh input/output structure.
/// @return @a mesh_inout (for nesting).
egwSJITVAMeshf* egwMeshFreeSJITVAf(egwSJITVAMeshf* mesh_inout);

/// Static Disjointly Indexed Triangle Vertex Array Mesh Free Routine.
/// Frees the contents of the mesh.
/// @param [in,out] mesh_inout Mesh input/output structure.
/// @return @a mesh_inout (for nesting).
egwSDITVAMeshf* egwMeshFreeSDITVAf(egwSDITVAMeshf* mesh_inout);

/// Key Framed Triangle Vertex Array Mesh Free Routine.
/// Frees the contents of the key framed mesh.
/// @param [in,out] mesh_inout Key framed mesh input/output structure.
/// @return @a mesh_inout (for nesting).
egwKFTVAMeshf* egwMeshFreeKFTVAf(egwKFTVAMeshf* mesh_inout);

/// Key Framed Jointly Indexed Triangle Vertex Array Mesh Free Routine.
/// Frees the contents of the key framed mesh.
/// @param [in,out] mesh_inout Key framed mesh input/output structure.
/// @return @a mesh_inout (for nesting).
egwKFJITVAMeshf* egwMeshFreeKFJITVAf(egwKFJITVAMeshf* mesh_inout);

/// Key Framed Disjointly Indexed Triangle Vertex Array Mesh Free Routine.
/// Frees the contents of the key framed mesh.
/// @param [in,out] mesh_inout Key framed mesh input/output structure.
/// @return @a mesh_inout (for nesting).
egwKFDITVAMeshf* egwMeshFreeKFDITVAf(egwKFDITVAMeshf* mesh_inout);

/// Static Triangle Vertex Array To Static Jointly Indexed Triangle Vertex Array Mesh Conversion Routine.
/// Converts the contents of one mesh storage format to another.
/// @param [in] mesh_in Mesh input structure.
/// @param [out] mesh_out Mesh output structure.
/// @return @a mesh_out (for nesting), otherwise NULL if failure converting.
egwSJITVAMeshf* egwMeshConvertSTVAfSJITVAf(const egwSTVAMeshf* mesh_in, egwSJITVAMeshf* mesh_out);

/// Static Triangle Vertex Array To Static Disjointly Indexed Triangle Vertex Array Mesh Conversion Routine.
/// Converts the contents of one mesh storage format to another.
/// @param [in] mesh_in Mesh input structure.
/// @param [out] mesh_out Mesh output structure.
/// @return @a mesh_out (for nesting), otherwise NULL if failure converting.
egwSDITVAMeshf* egwMeshConvertSTVAfSDITVAf(const egwSTVAMeshf* mesh_in, egwSDITVAMeshf* mesh_out);

/// Static Jointly Indexed Triangle Vertex Array To Static Triangle Vertex Array Mesh Conversion Routine.
/// Converts the contents of one mesh storage format to another.
/// @param [in] mesh_in Mesh input structure.
/// @param [out] mesh_out Mesh output structure.
/// @return @a mesh_out (for nesting), otherwise NULL if failure converting.
egwSTVAMeshf* egwMeshConvertSJITVAfSTVAf(const egwSJITVAMeshf* mesh_in, egwSTVAMeshf* mesh_out);

/// Static Jointly Indexed Triangle Vertex Array To Static Disjointly Indexed Triangle Vertex Array Mesh Conversion Routine.
/// Converts the contents of one mesh storage format to another.
/// @param [in] mesh_in Mesh input structure.
/// @param [out] mesh_out Mesh output structure.
/// @return @a mesh_out (for nesting), otherwise NULL if failure converting.
egwSDITVAMeshf* egwMeshConvertSJITVAfSDITVAf(const egwSJITVAMeshf* mesh_in, egwSDITVAMeshf* mesh_out);

/// Static Disjointly Indexed Triangle Vertex Array To Static Triangle Vertex Array Mesh Conversion Routine.
/// Converts the contents of one mesh storage format to another.
/// @param [in] mesh_in Mesh input structure.
/// @param [out] mesh_out Mesh output structure.
/// @return @a mesh_out (for nesting), otherwise NULL if failure converting.
egwSTVAMeshf* egwMeshConvertSDITVAfSTVAf(const egwSDITVAMeshf* mesh_in, egwSTVAMeshf* mesh_out);

/// Static Disjointly Indexed Triangle Vertex Array To Static Jointly Indexed Triangle Vertex Array Mesh Conversion Routine.
/// Converts the contents of one mesh storage format to another.
/// @param [in] mesh_in Mesh input structure.
/// @param [out] mesh_out Mesh output structure.
/// @return @a mesh_out (for nesting), otherwise NULL if failure converting.
egwSJITVAMeshf* egwMeshConvertSDITVAfSJITVAf(const egwSDITVAMeshf* mesh_in, egwSJITVAMeshf* mesh_out);

/// Key Framed Triangle Vertex Array To Key Framed Jointly Indexed Triangle Vertex Array Mesh Conversion Routine.
/// Converts the contents of one key framed mesh storage format to another.
/// @param [in] mesh_in Key framed mesh input structure.
/// @param [out] mesh_out Key framed mesh output structure.
/// @return @a mesh_out (for nesting), otherwise NULL if failure converting.
egwKFJITVAMeshf* egwMeshConvertKFTVAfKFJITVAf(const egwKFTVAMeshf* mesh_in, egwKFJITVAMeshf* mesh_out);

/// Key Framed Triangle Vertex Array To Key Framed Disjointly Indexed Triangle Vertex Array Mesh Conversion Routine.
/// Converts the contents of one key framed mesh storage format to another.
/// @param [in] mesh_in Key framed mesh input structure.
/// @param [out] mesh_out Key framed mesh output structure.
/// @return @a mesh_out (for nesting), otherwise NULL if failure converting.
egwKFDITVAMeshf* egwMeshConvertKFTVAfKFDITVAf(const egwKFTVAMeshf* mesh_in, egwKFDITVAMeshf* mesh_out);

/// Key Framed Jointly Indexed Triangle Vertex Array To Key Framed Triangle Vertex Array Mesh Conversion Routine.
/// Converts the contents of one key framed mesh storage format to another.
/// @param [in] mesh_in Key framed mesh input structure.
/// @param [out] mesh_out Key framed mesh output structure.
/// @return @a mesh_out (for nesting), otherwise NULL if failure converting.
egwKFTVAMeshf* egwMeshConvertKFJITVAfKFTVAf(const egwKFJITVAMeshf* mesh_in, egwKFTVAMeshf* mesh_out);

/// Key Framed Jointly Indexed Triangle Vertex Array To Key Framed Disjointly Indexed Triangle Vertex Array Mesh Conversion Routine.
/// Converts the contents of one key framed mesh storage format to another.
/// @param [in] mesh_in Key framed mesh input structure.
/// @param [out] mesh_out Key framed mesh output structure.
/// @return @a mesh_out (for nesting), otherwise NULL if failure converting.
egwKFDITVAMeshf* egwMeshConvertKFJITVAfKFDITVAf(const egwKFJITVAMeshf* mesh_in, egwKFDITVAMeshf* mesh_out);

/// Key Framed Disjointly Indexed Triangle Vertex Array To Key Framed Triangle Vertex Array Mesh Conversion Routine.
/// Converts the contents of one key framed mesh storage format to another.
/// @param [in] mesh_in Key framed mesh input structure.
/// @param [out] mesh_out Key framed mesh output structure.
/// @return @a mesh_out (for nesting), otherwise NULL if failure converting.
egwKFTVAMeshf* egwMeshConvertKFDITVAfKFTVAf(const egwKFDITVAMeshf* mesh_in, egwKFTVAMeshf* mesh_out);

/// Key Framed Disjointly Indexed Triangle Vertex Array To Key Framed Jointly Indexed Triangle Vertex Array Mesh Conversion Routine.
/// Converts the contents of one key framed mesh storage format to another.
/// @param [in] mesh_in Key framed mesh input structure.
/// @param [out] mesh_out Key framed mesh output structure.
/// @return @a mesh_out (for nesting), otherwise NULL if failure converting.
egwKFJITVAMeshf* egwMeshConvertKFDITVAfKFJITVAf(const egwKFDITVAMeshf* mesh_in, egwKFJITVAMeshf* mesh_out);

/// @}

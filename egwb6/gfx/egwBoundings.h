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

/// @defgroup geWizES_gfx_boundings egwBoundings
/// @ingroup geWizES_gfx
/// Bounding Volumes.
/// @{

/// @file egwBoundings.h
/// Bounding Volume Interfaces.

#import "egwGfxTypes.h"
#import "../inf/egwPBounding.h"
#import "../math/egwMathTypes.h"
#import "../geo/egwGeoTypes.h"


/// Zero Bounding Interface.
/// Provides a zero bounding volume used to encapsulate absolutely no space.
@interface egwZeroBounding : NSObject <egwPBounding> {
    egwVector4f _origin;                    ///< Bounding origin position.
}

/// Initializer.
/// Initializes the bounding volume with provided settings.
/// @param [in] bndOrigin Bounding origin position.
/// @return Self upon success, otherwise nil.
- (id)initWithBoundingOrigin:(const egwVector3f*)bndOrigin;

@end


/// Infinite Bounding Interface.
/// Provides an infinite bounding volume used to encapsulate infinite space.
@interface egwInfiniteBounding : NSObject <egwPBounding> {
    egwVector4f _origin;                    ///< Bounding origin position.
}

/// Initializer.
/// Initializes the bounding volume with provided settings.
/// @param [in] bndOrigin Bounding origin position.
/// @return Self upon success, otherwise nil.
- (id)initWithBoundingOrigin:(const egwVector3f*)bndOrigin;

@end


/// Bounding Sphere Interface.
/// Provides a bounding sphere volume used to encapsulate a spherical space.
@interface egwBoundingSphere : NSObject <egwPBounding> {
    egwSphere4f _bounding;                  ///< Bounding area sphere.
}

/// Initializer.
/// Initializes the bounding volume with provided settings.
/// @param [in] bndOrigin Bounding origin position.
/// @param [in] bndRadius bounding radius.
/// @return Self upon success, otherwise nil.
- (id)initWithBoundingOrigin:(const egwVector3f*)bndOrigin boundingRadius:(EGWsingle)bndRadius;


/// Bounding Object Accessor.
/// Returns the bounding area object.
/// @return Bounding area object.
- (const egwSphere4f*)boundingObject;

/// Bounding Radius Accessor.
/// Returns the bounding radius.
/// @return Bounding radius.
- (EGWsingle)boundingRadius;

@end


/// Axis-Aligned Bounding Box Interface.
/// Provides an axis-aligned bounding box volume used to encapsulate a boxed axes space.
@interface egwBoundingBox : NSObject <egwPBounding> {
    egwBox4f _bounding;                     ///< Bounding area box.
}

/// Initializer.
/// Initializes the bounding volume with provided settings.
/// @param [in] bndOrigin Bounding origin position.
/// @param [in] bndMinimum Bounding minimum axis value extents.
/// @param [in] bndMaximum Bounding maximum axis value extents.
/// @return Self upon success, otherwise nil.
- (id)initWithBoundingOrigin:(const egwVector3f*)bndOrigin boundingMinimum:(egwVector3f*)bndMinimum boundingMaximum:(egwVector3f*)bndMaximum;


/// Bounding Object Accessor.
/// Returns the bounding area object.
/// @return Bounding area object.
- (const egwBox4f*)boundingObject;

/// Bounding Radius Accessor.
/// Returns the bounding minimum value extents.
/// @return Bounding minimum value extents.
- (const egwVector4f*)boundingMinimum;

/// Bounding Radius Accessor.
/// Returns the bounding maximum value extents.
/// @return Bounding maximum value extents.
- (const egwVector4f*)boundingMaximum;

@end


/// Bounding Cylinder Interface.
/// Provides an axis-aligned upright standing (+Y-axis) bounding cylinder volume used to encapsulate a cylindrical space.
@interface egwBoundingCylinder : NSObject <egwPBounding> {
    egwCylinder4f _bounding;                ///< Bounding area cylinder.
}

/// Initializer.
/// Initializes the bounding volume with provided settings.
/// @param [in] bndOrigin Bounding origin position.
/// @param [in] bndHeight bounding height.
/// @param [in] bndRadius bounding radius.
/// @return Self upon success, otherwise nil.
- (id)initWithBoundingOrigin:(const egwVector3f*)bndOrigin boundingHeight:(EGWsingle)bndHeight boundingRadius:(EGWsingle)bndRadius;


/// Bounding Object Accessor.
/// Returns the bounding area object.
/// @return Bounding area object.
- (const egwCylinder4f*)boundingObject;

/// Bounding Height Accessor.
/// Returns the bounding height.
/// @return Bounding height.
- (EGWsingle)boundingHeight;

/// Bounding Radius Accessor.
/// Returns the bounding radius.
/// @return Bounding radius.
- (EGWsingle)boundingRadius;

@end


/// Bounding Frustum.
/// Provides a bounding frustum volume used to encapsulate a pyramidal-shaped space.
@interface egwBoundingFrustum : NSObject <egwPBounding> {
    egwFrustum4f _bounding;                 ///< Bounding area frustum.
}

/// Initializer.
/// Initializes the bounding volume with provided settings.
/// @param [in] bndOrigin Bounding origin position.
/// @param [in] bndPlnMinX Minimum-X axis bounding plane.
/// @param [in] bndPlnMaxX Maximum-X axis bounding plane.
/// @param [in] bndPlnMinY Minimum-Y axis bounding plane.
/// @param [in] bndPlnMaxY Maximum-Y axis bounding plane.
/// @param [in] bndPlnMinZ Minimum-Z axis bounding plane.
/// @param [in] bndPlnMaxZ Maximum-Z axis bounding plane.
/// @return Self upon success, otherwise nil.
- (id)initWithBoundingOrigin:(const egwVector3f*)bndOrigin boundingPlaneMinX:(egwPlane4f*)bndPlnMinX boundingPlaneMaxX:(egwPlane4f*)bndPlnMaxX boundingPlaneMinY:(egwPlane4f*)bndPlnMinY boundingPlaneMaxY:(egwPlane4f*)bndPlnMaxY boundingPlaneMinZ:(egwPlane4f*)bndPlnMinZ boundingPlaneMaxZ:(egwPlane4f*)bndPlnMaxZ;

/// Initializer.
/// Initializes the bounding volume with provided settings.
/// @note This initializer is meant to set up a perspective-based camera view volume sourced at <0,0,0> and pointing in the negative Z direction.
/// @param [in] fov Field of view angle (degrees).
/// @param [in] aspect Viewing aspect ratio (width/height).
/// @param [in] near Front/near viewing clip plane.
/// @param [in] far Back/far viewing clip plane.
/// @return Self upon success, otherwise nil.
- (id)initPerspectiveWithFieldOfView:(EGWsingle)fov aspectRatio:(EGWsingle)aspect frontPlane:(EGWsingle)near backPlane:(EGWsingle)far;


/// Bounding Object Accessor.
/// Returns the bounding area object.
/// @return Bounding area object.
- (const egwFrustum4f*)boundingObject;

/// Bounding Plane (MinX) Accessor.
/// Returns the min-X bounding plane object.
/// @return Min-X bounding plane object.
- (const egwPlane4f*)boundingPlaneMinX;

/// Bounding Plane (MaxX) Accessor.
/// Returns the max-X bounding plane object.
/// @return Max-X bounding plane object.
- (const egwPlane4f*)boundingPlaneMaxX;

/// Bounding Plane (MinY) Accessor.
/// Returns the min-Y bounding plane object.
/// @return Min-Y bounding plane object.
- (const egwPlane4f*)boundingPlaneMinY;

/// Bounding Plane (MaxY) Accessor.
/// Returns the max-Y bounding plane object.
/// @return Max-Y bounding plane object.
- (const egwPlane4f*)boundingPlaneMaxY;

/// Bounding Plane (MinZ) Accessor.
/// Returns the min-Z bounding plane object.
/// @return Min-Z bounding plane object.
- (const egwPlane4f*)boundingPlaneMinZ;

/// Bounding Plane (MaxZ) Accessor.
/// Returns the max-Z bounding plane object.
/// @return Max-Z bounding plane object.
- (const egwPlane4f*)boundingPlaneMaxZ;

@end

/// @}

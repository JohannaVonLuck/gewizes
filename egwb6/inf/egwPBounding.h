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

/// @defgroup geWizES_inf_pbounding egwPBounding
/// @ingroup geWizES_inf
/// Bounding Volume Protocol.
/// @{

/// @file egwPBounding.h
/// Bounding Volume Protocol.

#import "egwTypes.h"
#import "../math/egwMathTypes.h"
#import "../geo/egwGeoTypes.h"


/// Bounding Volume Protocol.
/// Defines interactions for bounding volumes.
@protocol egwPBounding <NSObject, NSCopying>

/// Initializer.
/// Initializes bounding volume with provided mesh data.
/// @param [in] optSource Optical source position of visual extent. May be nil (for calculation).
/// @param [in] vertexCount Number of vertices.
/// @param [in] vertexCoords Vertex vector coordinates array.
/// @param [in] vCoordsStride Vertex coords stride parameter.
/// @return Self upon success, otherwise nil.
- (id)initWithOpticalSource:(const egwVector3f*)optSource vertexCount:(EGWuint16)vertexCount vertexCoords:(const egwVector3f*)vertexCoords vertexCoordsStride:(EGWintptr)vCoordsStride;


/// Merge Volumes Method.
/// Extends this bounding volume to encapsulate another.
/// @param [in] boundVolume Bounding volume object.
- (void)mergeWithVolume:(const id<egwPBounding>)boundVolume;

/// Base Offset (byTransform) Method.
/// Offsets the bounding volume by the provided @a transform.
/// @param [in] transform Transformation matrix.
- (void)baseOffsetByTransform:(const egwMatrix44f*)transform;

/// Orientate (byTransform) Method.
/// Orients the bounding volume with the provided parameters.
/// @param [in] wcsTransform LCS->WCS transformation matrix.
/// @param [in] lcsVolume LCS bounding volume.
- (void)orientateByTransform:(const egwMatrix44f*)wcsTransform fromVolume:(id<egwPBounding>)lcsVolume;

/// Reset Method.
/// Extends a bounding volume to its most-nullified state.
- (void)reset;

/// Test Collision (withPoint) Method.
/// Tests for intersection with provided @a point.
/// @note It is assumed that both bounding and point exist in the same CS.
/// @param [in] point 3-D point object.
/// @return Intersection identity (EGW_CLSNTEST_*).
/// @see geWizES_math_geometry
- (EGWint)testCollisionWithPoint:(const egwVector3f*)point;

/// Test Collision (withLine) Method.
/// Tests for intersection with provided @a line.
/// @note It is assumed that both bounding and line exist in the same CS.
/// @param [in] line 3-D line object.
/// @param [out] begT Starting unit return. May by NULL (for skipped calculation/return).
/// @param [out] endT Ending unit return. May by NULL (for skipped calculation/return).
/// @return Intersection identity (EGW_CLSNTEST_*).
/// @see geWizES_math_geometry
- (EGWint)testCollisionWithLine:(const egwLine4f*)line startingAt:(EGWsingle*)begT endingAt:(EGWsingle*)endT;

/// Test Collision (withPlane) Method.
/// Tests for intersection with provided @a plane.
/// @note It is assumed that both bounding and plane exist in the same CS.
/// @param [in] plane 3-D plane object.
/// @param [out] side Side object is on [-1,0,1]. May by NULL (for skipped calculation/return).
/// @return Intersection identity (EGW_CLSNTEST_*).
/// @see geWizES_math_geometry
- (EGWint)testCollisionWithPlane:(const egwPlane4f*)plane onSide:(EGWint*)side;

/// Test Collision (withVolume) Method.
/// Tests for intersection with provided @a boundVolume.
/// @note It is assumed that both boundings exist in the same CS.
/// @param [in] boundVolume Bounding volume object.
/// @return Intersection identity (EGW_CLSNTEST_*).
/// @see geWizES_math_geometry
- (EGWint)testCollisionWithVolume:(const id<egwPBounding>)boundVolume;


/// Bounding Origin Accessor.
/// Returns the bounding origin position.
/// @return Bounding origin position.
- (const egwVector4f*)boundingOrigin;


/// IsColliding (withPoint) Poller.
/// Polls the object to determine status.
/// @note It is assumed that both boundings exist in the same CS.
/// @param [in] point 3-D point object.
/// @return YES if @a point is touching or contained by this volume, otherwise NO.
/// @see geWizES_math_geometry
- (BOOL)isCollidingWithPoint:(const egwVector3f*)point;

/// IsColliding (withLine) Poller.
/// Polls the object to determine status.
/// @note It is assumed that both boundings exist in the same CS.
/// @param [in] line 3-D line object.
/// @return YES if @a line is touching or intersecting this volume, otherwise NO.
/// @see geWizES_math_geometry
- (BOOL)isCollidingWithLine:(const egwLine4f*)line;

/// IsColliding (withPlane) Poller.
/// Polls the object to determine status.
/// @note It is assumed that both boundings exist in the same CS.
/// @param [in] plane 3-D plane object.
/// @return YES if @a plane is touching or intersecting this volume, otherwise NO.
/// @see geWizES_math_geometry
- (BOOL)isCollidingWithPlane:(const egwPlane4f*)plane;

/// IsColliding (withVolume) Poller.
/// Polls the object to determine status.
/// @note It is assumed that both boundings exist in the same CS.
/// @param [in] boundVolume Bounding volume object.
/// @return YES if @a boundVolume is touching, intersecting, contains, equal to, or contained by this volume, otherwise NO.
/// @see geWizES_math_geometry
- (BOOL)isCollidingWithVolume:(const id<egwPBounding>)boundVolume;

/// IsReset Poller.
/// Polls the object to determine status.
/// @return YES if bounding volume is currently in a "reset" state, otherwise NO.
- (BOOL)isReset;

@end

/// @}

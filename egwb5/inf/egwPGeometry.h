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

/// @defgroup geWizES_inf_pgeometry egwPGeometry
/// @ingroup geWizES_inf
/// Geometry Protocol.
/// @{

/// @file egwPGeometry.h
/// Geometry Protocol.

#import "egwTypes.h"
#import "../inf/egwPObjLeaf.h"
#import "../inf/egwPOrientated.h"
#import "../inf/egwPRenderable.h"


/// Geometry Protocol.
/// Defines interactions for geometries.
@protocol egwPGeometry <egwPObjectLeaf, egwPOrientated, egwPRenderable>

/// Rebound (withClass) Method.
/// Rebinds the base optical MCS & WCS bounding volumes with provided @a bndClass class.
/// @param [in] bndClass Associated bounding class. May be nil (for egwBoundingSphere).
- (void)reboundWithClass:(Class)bndClass;


/// Geometry Buffer Syncronization Validater Accessor.
/// Returns the validater that manages component synchronization with a hardware buffer.
/// @return Geometry buffer validater, otherwise nil (if unused).
- (egwValidater*)geometryBufferSync;

/// Geometry Storage Accessor.
/// Returns the geometry storage/VBO setting.
/// @return Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
- (EGWuint)geometryStorage;

/// Texture Stack Accessor.
/// Returns the object's associated texture stack.
/// @return Texture stack, otherwise nil (if unused).
- (egwTextureStack*)textureStack;


/// Texture Stack Mutator.
/// Sets the texture stack associated with the object.
/// @param [in] txtrStack Texture stack (retained).
- (void)setTextureStack:(egwTextureStack*)txtrStack;


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

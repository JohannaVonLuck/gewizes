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

/// @defgroup geWizES_gfx_texture egwTexture
/// @ingroup geWizES_gfx
/// Texture Asset.
/// @{

/// @file egwTexture.h
/// Texture Asset Interface.

#import "egwGfxTypes.h"
#import "../inf/egwPAsset.h"
#import "../inf/egwPAssetBase.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPSubTask.h"
#import "../inf/egwPGfxContext.h"
#import "../inf/egwPTexture.h"
#import "../misc/egwMiscTypes.h"


/// Texture Instance Asset.
/// Contains unique instance data relating to a basic texture object.
@interface egwTexture : NSObject <egwPAsset, egwPTexture, egwDValidationEvent> {
    egwTextureBase* _base;                  ///< Base object instance (retained).
    NSString* _ident;                       ///< Unique identity (retained).
    
    BOOL _isTBound;                         ///< Texturing binding status.
    EGWuint _lastTBind;                     ///< Last texturing binding stage.
    EGWuint _texEnv;                        ///< Texture fragmentation environment.
    egwValidater* _tSync;                   ///< Texturing binding sync (retained).
    
    const EGWuint* _texID;                  ///< Texture identifier (aliased).
}

/// Designated Initializer.
/// Initializes the texture asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] surface Texture surface data (contents ownership transfer).
/// @param [in] environment Texture fragmentation environment setting (EGW_TEXTURE_FENV_*).
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @param [in] sWrap Texturing s-axis edge wrapping setting (EGW_TEXTURE_WRAP_*).
/// @param [in] tWrap Texturing t-axis edge wrapping setting (EGW_TEXTURE_WRAP_*).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent textureSurface:(egwSurface*)surface textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter texturingSWrap:(EGWuint16)sWrap texturingTWrap:(EGWuint16)tWrap;

/// Blank Texture Initializer.
/// Initializes the texture asset as a blank surface with provided settings.
/// @note Only power-of-two surface widths & heights may be used.
/// @note This method does not clear/set-to-zero the allocated surface prior to return.
/// @note Once surface is prepared, one should invalidate the texture buffer sync to start the buffering sequence.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] format Texture surface format (EGW_SURFACE_FRMT_*). May be 0 (for EGW_SURFACE_FRMT_R8G8B8A8).
/// @param [in] width Texture width.
/// @param [in] height Texture height.
/// @param [in] environment Texture fragmentation environment setting (EGW_TEXTURE_FENV_*).
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @param [in] sWrap Texturing s-axis edge wrapping setting (EGW_TEXTURE_WRAP_*).
/// @param [in] tWrap Texturing t-axis edge wrapping setting (EGW_TEXTURE_WRAP_*).
/// @param [in] texOpacity Opaque determination boolean.
/// @return Self upon success, otherwise nil.
- (id)initBlankWithIdentity:(NSString*)assetIdent surfaceFormat:(EGWuint32)format textureWidth:(EGWuint16)width textureHeight:(EGWuint16)height textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter texturingSWrap:(EGWuint16)sWrap texturingTWrap:(EGWuint16)tWrap texturingOpacity:(BOOL)texOpacity;

/// Preallocated Texture Initializer.
/// Initializes the texture asset from a pre-allocated texture identifier with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] textureID Texture identifier (ownership transfer).
/// @param [in,out] surface Texture surface data (contents ownership transfer). Field .data may be NULL (if already managed).
/// @param [in] environment Texture fragmentation environment setting (EGW_TEXTURE_FENV_*).
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @param [in] sWrap Texturing s-axis edge wrapping setting (EGW_TEXTURE_WRAP_*).
/// @param [in] tWrap Texturing t-axis edge wrapping setting (EGW_TEXTURE_WRAP_*).
/// @param [in] texOpacity Opaque determination boolean.
/// @return Self upon success, otherwise nil.
- (id)initPreallocatedWithIdentity:(NSString*)assetIdent textureID:(EGWuint*)textureID textureSurface:(egwSurface*)surface textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter texturingSWrap:(EGWuint16)sWrap texturingTWrap:(EGWuint16)tWrap texturingOpacity:(BOOL)texOpacity;

/// Loaded Texture Initializer.
/// Initializes the texture asset from a loaded surface with provided settings.
/// @param [in] resourceFile Resource file to load from.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] environment Texture fragmentation environment setting (EGW_TEXTURE_FENV_*).
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @param [in] sWrap Texturing s-axis edge wrapping setting (EGW_TEXTURE_WRAP_*).
/// @param [in] tWrap Texturing t-axis edge wrapping setting (EGW_TEXTURE_WRAP_*).
/// @return Self upon success, otherwise nil.
- (id)initLoadedFromResourceFile:(NSString*)resourceFile withIdentity:(NSString*)assetIdent textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter texturingSWrap:(EGWuint16)sWrap texturingTWrap:(EGWuint16)tWrap;

/// Copy Initializer.
/// Copies a texture asset with provided unique settings.
/// @param [in] asset Asset to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent;

@end


/// Texture Asset Base.
/// Contains shared instance data relating to basic texture objects.
@interface egwTextureBase : NSObject <egwPAssetBase, egwPSubTask, egwDValidationEvent> {
    EGWuint _instCounter;                   ///< Instantiation counter.
    NSString* _ident;                       ///< Unique identity (retained).
    
    egwSurface _tSrfc;                      ///< Texture surface (MCS).
    
    egwValidater* _tbSync;                  ///< Texture buffer sync (retained).
    EGWuint _texID;                         ///< Texture identifier.
    EGWuint _texTrans;                      ///< Texturing transforms.
    EGWuint _texFltr;                       ///< Texturing filter.
    EGWuint16 _texSWrp;                     ///< Texturing s-axis edge wrapping.
    EGWuint16 _texTWrp;                     ///< Texturing s-axis edge wrapping.
    
    BOOL _isOpaque;                         ///< Tracks opacity status.
    BOOL _isTDPersist;                      ///< Tracks surface persistence status.
}

/// Designated Initializer.
/// Initializes the texture asset base with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] surface Texture surface data (contents ownership transfer).
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @param [in] sWrap Texturing s-axis edge wrapping setting (EGW_TEXTURE_WRAP_*).
/// @param [in] tWrap Texturing t-axis edge wrapping setting (EGW_TEXTURE_WRAP_*).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent textureSurface:(egwSurface*)surface texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter texturingSWrap:(EGWuint16)sWrap texturingTWrap:(EGWuint16)tWrap;

/// Blank Texture Initializer.
/// Initializes the texture asset base as a blank surface with provided settings.
/// @note Only power-of-two surface widths & heights may be used.
/// @note This method does not clear/set-to-zero the allocated surface prior to return.
/// @note Once surface is prepared, one should invalidate the texture buffer sync to start the buffering sequence.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] format Texture surface format (EGW_SURFACE_FRMT_*). May be 0 (for EGW_SURFACE_FRMT_R8G8B8A8).
/// @param [in] width Texture width.
/// @param [in] height Texture height.
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @param [in] sWrap Texturing s-axis edge wrapping setting (EGW_TEXTURE_WRAP_*).
/// @param [in] tWrap Texturing t-axis edge wrapping setting (EGW_TEXTURE_WRAP_*).
/// @param [in] texOpacity Opaque determination boolean.
/// @return Self upon success, otherwise nil.
- (id)initBlankWithIdentity:(NSString*)assetIdent surfaceFormat:(EGWuint32)format textureWidth:(EGWuint16)width textureHeight:(EGWuint16)height texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter texturingSWrap:(EGWuint16)sWrap texturingTWrap:(EGWuint16)tWrap texturingOpacity:(BOOL)texOpacity;

/// Preallocated Texture Initializer.
/// Initializes the texture asset base from a pre-allocated texture identifier with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] textureID Texture identifier (ownership transfer).
/// @param [in,out] surface Texture surface data (contents ownership transfer). Field .data may be NULL (if already managed).
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @param [in] sWrap Texturing s-axis edge wrapping setting (EGW_TEXTURE_WRAP_*).
/// @param [in] tWrap Texturing t-axis edge wrapping setting (EGW_TEXTURE_WRAP_*).
/// @param [in] texOpacity Opaque determination boolean.
/// @return Self upon success, otherwise nil.
- (id)initPreallocatedWithIdentity:(NSString*)assetIdent textureID:(EGWuint*)textureID textureSurface:(egwSurface*)surface texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter texturingSWrap:(EGWuint16)sWrap texturingTWrap:(EGWuint16)tWrap texturingOpacity:(BOOL)texOpacity;


/// Texture Buffer Syncronization Validater Accessor.
/// Returns the validater that manages component synchronization with a hardware buffer.
/// @return Texture buffer validater.
- (egwValidater*)textureBufferSync;

/// Texture ID Accessor.
/// Returns the base context referenced texture identifier.
/// @note Ownership transfer is not allowed.
/// @return Texture identifier.
- (const EGWuint*)textureID;

/// Texture Surface Accessor.
/// Returns the texture's base surface data (if available).
/// @return Texture base surface data, otherwise NULL (if unavailable).
- (const egwSurface*)textureSurface;

/// Texturing Filter Accessor.
/// Returns the base texture filtering setting.
/// @return Texturing filter (EGW_TEXTURE_FLTR_*).
- (EGWuint)texturingFilter;

/// Texturing Transforms Accessor.
/// Returns the base texture transforms settings.
/// @return Texturing transforms (EGW_TEXTURE_TRFM_*).
- (EGWuint)texturingTransforms;

/// Texturing Edge Wrapping (S-Axis) Accessor.
/// Returns the base texture s-axis edge wrapping setting.
/// @return Texturing s-axis edge wrapping (EGW_TEXTURE_WRAP_*).
- (EGWuint16)texturingSWrap;

/// Texturing Edge Wrapping (T-Axis) Accessor.
/// Returns the base texture t-axis edge wrapping setting.
/// @return Texturing t-axis edge wrapping (EGW_TEXTURE_WRAP_*).
- (EGWuint16)texturingTWrap;


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


/// IsOpaque Poller.
/// Polls the object to determine status.
/// @return YES if texture is opaque, otherwise NO.
- (BOOL)isOpaque;

/// IsTextureDataPersistent Poller.
/// Polls the object to determine status.
/// @return YES if texture buffer is persistent, otherwise NO.
- (BOOL)isTextureDataPersistent;

@end

/// @}

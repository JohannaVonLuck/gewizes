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

/// @defgroup geWizES_inf_ptexture egwPTexture
/// @ingroup geWizES_inf
/// Texture Protocol.
/// @{

/// @file egwPTexture.h
/// Texture Protocol.

#import "egwTypes.h"
#import "../inf/egwPCoreObject.h"
#import "../inf/egwPOrientated.h"
#import "../math/egwMathTypes.h"
#import "../misc/egwMiscTypes.h"


/// Texture Jump Table.
/// Contains function pointers to class methods for faster invocation in low tier sections.
typedef struct {
    id (*fpRetain)(id, SEL);                    ///< FP to retain.
    void (*fpRelease)(id, SEL);                 ///< FP to release.
    BOOL (*fpTBind)(id, SEL, EGWuint, EGWuint); ///< FP to bindForTexturingStage:withFlags:.
    BOOL (*fpTUnbind)(id, SEL, EGWuint);        ///< FP to unbindTexturingWithFlags:.
    id<NSObject> (*fpTBase)(id, SEL);           ///< FP to textureBase.
    const EGWuint* (*fpTID)(id, SEL);           ///< FP to textureID.
    egwValidater* (*fpTSync)(id, SEL);          ///< FP to texturingSync.
    EGWuint (*fpTLBStage)(id, SEL);             ///< FP to lastTexturingBindingStage.
    BOOL (*fpOpaque)(id, SEL);                  ///< FP to isOpaque.
} egwTextureJumpTable;


/// Texture Protocol.
/// Defines interactions for textures.
@protocol egwPTexture <egwPCoreObject>

/// Bind Texturing Method.
/// Binds texture for provided texturing stage with provided @a flags.
/// @note Do not call this method directly - this method is called automatically by the system.
/// @param [in] txtrStage Texturing stage number.
/// @param [in] flags Binding flags.
/// @return YES if bind was successful, otherwise NO.
- (BOOL)bindForTexturingStage:(EGWuint)txtrStage withFlags:(EGWuint)flags;

/// Unbind Texturing Method.
/// Unbinds texture from its last bound stage with provided @a flags.
/// @note Do not call this method directly - this method is called automatically by the system.
/// @param [in] flags Binding flags.
/// @return YES if unbind was successful, otherwise NO.
- (BOOL)unbindTexturingWithFlags:(EGWuint)flags;


/// Texture Buffer Syncronization Validater Accessor.
/// Returns the validater that manages component synchronization with a hardware buffer.
/// @return Texture buffer validater, otherwise nil (if unused).
- (egwValidater*)textureBufferSync;

/// Texture Jump Table Accessor.
/// Returns the texture's jump table for subsequent low tier calls.
/// @return Texture jump table.
- (const egwTextureJumpTable*)textureJumpTable;

/// Texturing Base Object Accessor.
/// Returns the corresponding base instance object.
/// @note This is used for determination of EGW_BNDOBJ_BINDFLG_SAMELASTBASE reply flag.
/// @return Base instance object, otherwise self (if unused).
- (id<NSObject>)textureBase;

/// Texture Environment Accessor.
/// Returns the texture environment/fragmentation setting.
/// @return Texture fragmentation environment (EGW_TEXTURE_FENV_*).
- (EGWuint)textureEnvironment;

/// Texturing Filter Accessor.
/// Returns the texture filtering setting.
/// @return Texturing filter (EGW_TEXTURE_FLTR_*).
- (EGWuint)texturingFilter;

/// Texture ID Accessor.
/// Returns the base context referenced texture identifier.
/// @note Ownership transfer is not allowed.
/// @return Texture identifier.
- (const EGWuint*)textureID;

/// Texturing Syncronization Validater Accessor.
/// Returns the validater that manages component synchronization with an API interface.
/// @return Texturing validater, otherwise nil (if unused).
- (egwValidater*)texturingSync;

/// Texturing Transforms Accessor.
/// Returns the texture transforms settings.
/// @return Texturing transforms (EGW_TEXTURE_TRFM_*).
- (EGWuint)texturingTransforms;

/// Texturing Edge Wrapping (S-Axis) Accessor.
/// Returns the texture s-axis edge wrapping setting.
/// @return Texturing s-axis edge wrapping (EGW_TEXTURE_WRAP_*).
- (EGWuint16)texturingSWrap;

/// Texturing Edge Wrapping (T-Axis) Accessor.
/// Returns the texture t-axis edge wrapping setting.
/// @return Texturing t-axis edge wrapping (EGW_TEXTURE_WRAP_*).
- (EGWuint16)texturingTWrap;

/// Last Texturing Binding Stage Accessor.
/// Returns the least recently used texturing binding stage number.
/// @return Last texturing binding stage number, otherwise NSNotFound if not yet bounded.
- (EGWuint)lastTexturingBindingStage;


/// Texture Buffer Data Persistence Tryer.
/// Attempts to set the persistence of local data for the texture buffer to @a persist.
/// @param [in] persist Persistence setting of local buffer data.
/// @return YES if setting was successfully changed, otherwise NO.
- (BOOL)trySetTextureDataPersistence:(BOOL)persist;

/// Texturing Environment Tryer.
/// Attempts to set the texture environment setting to @a environment.
/// @param [in] environment Texture fragmentation environment setting (EGW_TEXTURE_FENV_*).
/// @return YES if setting was successfully changed, otherwise NO.
- (BOOL)trySetTextureEnvironment:(EGWuint)environment;

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


/// IsBoundForTexturing Poller.
/// Polls the object to determine status.
/// @return YES if texture is currently bound, otherwise NO.
- (BOOL)isBoundForTexturing;

/// IsOpaque Poller.
/// Polls the object to determine status.
/// @return YES if texture is considered opaque, otherwise NO.
- (BOOL)isOpaque;

/// IsTextureDataPersistent Poller.
/// Polls the object to determine status.
/// @return YES if texture buffer is persistent, otherwise NO.
- (BOOL)isTextureDataPersistent;

@end

/// @}

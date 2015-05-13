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

/// @defgroup geWizES_sys_gfxcontextagl egwGfxContextAGL
/// @ingroup geWizES_sys
/// Abstract OpenGL Graphics Context.
/// @{

/// @file egwGfxContextAGL.h
/// Abstract OpenGL Graphics Context Interface.

#import "egwSysTypes.h"
#import "egwGfxContext.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPGfxContext.h"
#import "../inf/egwPTask.h"
#import "../inf/egwPCamera.h"
#import "../inf/egwPLight.h"
#import "../inf/egwPMaterial.h"
#import "../inf/egwPFont.h"
#import "../inf/egwPShader.h"
#import "../inf/egwPTexture.h"
#import "../data/egwDataTypes.h"
#import "../gui/egwGuiTypes.h"


#if defined(EGW_BUILDMODE_DESKTOP) || defined(EGW_BUILDMODE_IPHONE)
#define EGW_BUILDMODE_GFX_GL


/// OpenGL Light Stage Container.
/// Contains data relevant to managing the EGW/GL illumination stack.
typedef struct {
    struct {
        EGWint8 exstStage;                  ///< Existing stage index for stack index.
        EGWint8 nextStage;                  ///< Next stage index for stack index.
    } stack;
    struct {
        EGWint8 stage;                      ///< Least-recently-used stage index (0->least).
    } lru;
    struct {
        EGWint8 nextStack;                  ///< Next stack index inverse stage index.
        id<egwPLight> exstBind;             ///< Existing stage binding (retained).
        const egwLightJumpTable* exstJmpT;  ///< Existing stage jump table (weak).
        id<egwPLight> nextBind;             ///< Next stage binding (retained).
        const egwLightJumpTable* nextJmpT;  ///< Next stage jump table (weak).
        EGWuint32 flags;                    ///< Internal flags.
    } stage;
} egwLightStageAGL;

/// OpenGL Material Stage Container.
/// Contains data relevant to managing the EGW/GL material stack.
typedef struct {
    id<egwPMaterial> exstBind;              ///< Existing stage binding (retained).
    const egwMaterialJumpTable* exstJmpT;   ///< Existing stage jump table (weak).
    id<egwPMaterial> nextBind;              ///< Next stage binding (retained).
    const egwMaterialJumpTable* nextJmpT;   ///< Next stage jump table (weak).
    EGWuint32 flags;                        ///< Internal flags.
} egwMaterialStageAGL;

/// OpenGL Shader Stage Container.
/// Contains data relevant to managing the EGW/GL shading stack.
typedef struct {
    id<egwPShader> exstBind;                ///< Existing stage binding (retained).
    const egwShaderJumpTable* exstJmpT;     ///< Existing stage jump table (weak).
    id<egwPShader> nextBind;                ///< Next stage binding (retained).
    const egwShaderJumpTable* nextJmpT;     ///< Next stage jump table (weak).
    EGWuint32 flags;                        ///< Internal flags.
} egwShaderStageAGL;

/// OpenGL Texture Stage Container.
/// Contains data relevant to managing the EGW/GL texturing stack.
typedef struct {
    id<egwPTexture> exstBind;               ///< Existing stage binding (retained).
    const egwTextureJumpTable* exstJmpT;    ///< Existing stage jump table (weak).
    id<egwPTexture> nextBind;               ///< Next stage binding (retained).
    const egwTextureJumpTable* nextJmpT;    ///< Next stage jump table (weak).
    EGWuint32 flags;                        ///< Internal flags.
} egwTextureStageAGL;


extern void (*egwAFPGfxCntxAGLCheckBindings)(id, SEL);  ///< Active checkBindings IMP function pointer (to reduce dynamic lookup).


/// Abstract OpenGL Graphics Context.
/// Contains abstract contextual data related to an OpenGL graphics API.
@interface egwGfxContextAGL : egwGfxContext {
    NSArray* _extensions;                   ///< Available GL extensions.
    
    unsigned int _clears;                   ///< Clearing bits to utilize (GLbitfield).
    
    BOOL _inPass;                           ///< Tracks in-pass status.
    
    pthread_mutex_t _iLock;                 ///< Index mutex lock.
    
    EGWuint16 _actvLights;                  ///< # of next-to-be-bound EGW lights.
    egwLightStageAGL* _lightStages;         ///< GL light stages container.
    
    EGWuint16 _actvMaterials;               ///< # of next-to-be-bound EGW materials.
    egwMaterialStageAGL* _materialStages;   ///< GL material stages container.
    
    EGWuint16 _actvShaders;                 ///< # of next-to-be-bound EGW shaders.
    egwShaderStageAGL* _shaderStages;       ///< GL shader stages container.
    
    EGWuint16 _actvTextures;                ///< # of next-to-be-bound EGW textures.
    egwTextureStageAGL* _textureStages;     ///< GL texture stages container.
    
    NSMutableIndexSet* _availTexIDs;        ///< Available GL texture IDs.
    NSMutableIndexSet* _usedTexIDs;         ///< Utilized GL texture IDs.
    NSMutableIndexSet* _dstryTexIDs;        ///< Delayed destroy GL texture IDs (wrapped in sub-task).
    
    NSMutableIndexSet* _availBufIDs;        ///< Available GL buffer IDs.
    NSMutableIndexSet* _usedBufIDs;         ///< Utilized GL buffer IDs.
    NSMutableIndexSet* _dstryBufIDs;        ///< Delayed destroy GL buffer IDs (wrapped in sub-task).
    
    EGWuint _dfltFilter;                    ///< Default filtering setting.
}

/// Check Bindings Method.
/// Checks all light, material, and texture bindings to ensure the EGW bind is still valid, invalidating binds as necessary.
- (void)checkBindings;

/// Request Texture Identifier Method.
/// Requests a context specific texture identifier, generating more if none available.
/// @note Generating more texture identifiers may fail if this context is unable to become active (on the current thread).
/// @return Texture identifier, otherwise NSNotFound if error.
- (EGWuint)requestFreeTextureID;

/// Return Texture Identifier Method.
/// Returns a context specific texture identifier, destroying the corresponding texture.
/// @note Destroying the texture may fail if this context is unable to become active (on the current thread).
/// @param [in] textureID Texture identifier.
/// @return NSNotFound (for simplicity).
- (EGWuint)returnUsedTextureID:(EGWuint)textureID;

/// Request Buffer Identifier Method.
/// Requests a context specific buffer identifier (e.g. VBO), generating more if non available.
/// @note Generating more buffer identifiers may fail if this context is unable to become active (on the current thread).
/// @return Buffer identifier, otherwise 0 if error.
- (EGWuint)requestFreeBufferID;

/// Return Buffer Identifier Method.
/// Returns a context specific geometry identifier (e.g. VBO), destroying the corresponding buffer.
/// @note Destroying the buffer may fail if this context is unable to become active (on the current thread).
/// @param [in] bufferID Buffer identifier.
/// @return 0 (for simplicity).
- (EGWuint)returnUsedBufferID:(EGWuint)bufferID;

@end


/// Abstract OpenGL Graphics Context (Texture Loading).
/// Adds GL texture loading capabilities from surfaces.
@interface egwGfxContextAGL (TextureLoading)

/// Load Texture Identifier Method.
/// Loads @a surface into @a textureID with provided parameters.
/// @note If filtering requires mip-map generation, surface data is overwritten and thus not persistent.
/// @param [in,out] textureID Texture identifier (outwards ownership transfer). May be NSNotFound (for request).
/// @param [in] surface Texture surface data.
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @param [in] sWrap Texturing s-axis edge wrapping setting (EGW_TEXTURE_WRAP_*).
/// @param [in] tWrap Texturing t-axis edge wrapping setting (EGW_TEXTURE_WRAP_*).
/// @return YES if load successful, otherwise NO.
- (BOOL)loadTextureID:(EGWuint*)textureID withSurface:(egwSurface*)surface texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter texturingSWrap:(EGWuint16)sWrap texturingTWrap:(EGWuint16)tWrap;

/// Default Texturing Filter Mutator Method.
/// Sets the default texturing @a filter to apply to textures using the special EGW_TEXTURE_FLTR_DFLTNMIP & EGW_TEXTURE_FLTR_DFLTMIP flags.
/// @param [in] filter Bit-wise mode setting, containing both a non-mipped and mipped filter setting.
- (void)setDefaultTexturingFilter:(EGWuint)filter;

@end


/// Abstract OpenGL Graphics Context (Buffer Loading).
/// Adds GL buffer loading capabilities from geometries.
@interface egwGfxContextAGL (BufferLoading)

/// Load Buffer Identifier (STVA) Method.
/// Loads @a mesh into @a bufferID with provided parameters.
/// @param [in,out] arraysBufID Buffer arrays identifier (outwards ownership transfer). May be 0 (for request).
/// @param [in] mesh Polygon mesh data.
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_VBO*).
- (BOOL)loadBufferArraysID:(EGWuint*)arraysBufID withSTVAMesh:(const egwSTVAMeshf*)mesh geometryStorage:(EGWuint)storage;

/// Load Buffer Identifier (SJITVA) Method.
/// Loads @a mesh vertex arrays into @a arrayBufId and @a mesh face elements into @a elementBufId with provided parameters.
/// @param [in,out] arraysBufID Buffer arrays identifier (outwards ownership transfer). May be 0 (for request).
/// @param [in,out] elementsBufID Buffer elements identifier (outwards ownership transfer). May be 0 (for request).
/// @param [in] mesh Polygon mesh data.
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_VBO*).
- (BOOL)loadBufferArraysID:(EGWuint*)arraysBufID bufferElementsID:(EGWuint*)elementsBufID withSJITVAMesh:(const egwSJITVAMeshf*)mesh geometryStorage:(EGWuint)storage;

/// Load Buffer Identifier (SQVA) Method.
/// Loads @a mesh into @a bufferID with provided parameters.
/// @param [in,out] arraysBufID Buffer arrays identifier (outwards ownership transfer). May be 0 (for request).
/// @param [in] mesh Quad mesh data.
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_VBO*).
- (BOOL)loadBufferArraysID:(EGWuint*)arraysBufID withSQVAMesh:(const egwSQVAMesh4f*)mesh geometryStorage:(EGWuint)storage;

/// Load Buffer Identifier (Raw) Method.
/// Loads @a rawData into @a bufferID with provided parameters.
/// @param [in,out] arraysBufID Buffer arrays identifier (outwards ownership transfer). May be 0 (for request).
/// @param [in] rawData Raw data array.
/// @param [in] dataSize Raw data size.
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_VBO*).
- (BOOL)loadBufferArraysID:(EGWuint*)arraysBufID withRawData:(const EGWbyte*)rawData dataSize:(EGWuint)dataSize geometryStorage:(EGWuint)storage;

@end


/// GL Error Poller.
/// Polls for an error in GL.
/// @note Resultant errorString strings are owned by this routine and should thus not be released.
/// @param [out] errorString Error string associated with error.
/// @return 1 upon any error flag set high, otherwise 0.
EGWint egwIsGLError(NSString** errorString);

/// GL Client Active Texture Routine.
/// Checks current active texture before setting GL client active texture.
/// @param [in] texture GL texture stack position (GL_TEXTUREXX).
/// @return YES if GL state was changed, otherwise NO.
BOOL egw_glClientActiveTexture(EGWuint texture);

/// GL Texture Bind Routine.
/// Checks current binding before binding GL texture.
/// @param [in] texture GL texture stack position (GL_TEXTUREXX).
/// @param [in] target GL texture target (GL_TEXTURE_*).
/// @param [in] identifier GL texture identifier.
/// @return YES if GL state was changed, otherwise NO.
BOOL egw_glBindTexture(EGWuint texture, EGWuint target, EGWuint identifier);

/// GL Buffer Bind Routine.
/// Checks current binding before binding GL buffer.
/// @param [in] target GL buffer target.
/// @param [in] buffer GL buffer identifier.
/// @return YES if GL state was changed, otherwise NO.
BOOL egw_glBindBuffer(EGWuint target, EGWuint buffer);

/// EGW/GL Environment Bind Routine.
/// Checks current environment binding before binding EGW environment.
/// @param [in] environment EGW environment target.
/// @return YES if GL state was changed, otherwise NO.
BOOL egw_glBindEnvironment(EGWuint environment);


#else

/// Abstract OpenGL Graphics Context (Blank).
/// Contains a placeholder to the actual class in the invalid build case.
@interface egwGfxContextAGL : egwGfxContext {
}
@end

#endif


/// Global currently active egwGfxContextAGL instance (weak).
extern egwGfxContextAGL* egwAIGfxCntxAGL;

/// @}

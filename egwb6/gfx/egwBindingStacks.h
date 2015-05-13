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

/// @defgroup geWizES_gfx_bindingstacks egwBindingStacks
/// @ingroup geWizES_gfx
/// Binding Stacks.
/// @{

/// @file egwBindingStacks.h
/// Binding Stack Interfaces.

#import "egwGfxTypes.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPGfxContext.h"
#import "../inf/egwPBounding.h"
#import "../inf/egwPLight.h"
#import "../inf/egwPMaterial.h"
#import "../inf/egwPShader.h"
#import "../inf/egwPTexture.h"
#import "../math/egwMathTypes.h"


#define EGW_LGHTSTACK_MAXLIGHTS     5       ///< Maximum number of lights supported by light stacks.
#define EGW_LGHTSTACK_HTBLSIZE      23      ///< Hash table size for hash indexing table.
#define EGW_SHDRSTACK_MAXSHADERS    2       ///< Maximum number of shaders supported by shader stacks.
#define EGW_TXTRSTACK_MAXTEXTURES   2       ///< Maximum number of textures supported by texture stacks.
#define EGW_MTRLSTACK_MAXMATERIALS  1       ///< Maximum number of materials supported by material stacks.


extern void (*egwSFPLghtStckPushAndBindLights)(id, SEL);    ///< Shared pushAndBindLights IMP function pointer (to reduce dynamic lookup).
extern void (*egwSFPLghtStckPopLights)(id, SEL);            ///< Shared popLights IMP function pointer (to reduce dynamic lookup).
extern EGWuint32 (*egwSFPLghtStckStackHash)(id, SEL);       ///< Shared stackHash IMP function pointer (to reduce dynamic lookup).
extern void (*egwSFPMtrlStckPushAndBindMaterials)(id, SEL); ///< Shared pushAndBindMaterials IMP function pointer (to reduce dynamic lookup).
extern void (*egwSFPMtrlStckPopMaterials)(id, SEL);         ///< Shared popMaterials IMP function pointer (to reduce dynamic lookup).
extern EGWuint32 (*egwSFPMtrlStckStackHash)(id, SEL);       ///< Shared stackHash IMP function pointer (to reduce dynamic lookup).
extern BOOL (*egwSFPMtrlStckOpaque)(id, SEL);               ///< Shared isOpaque IMP function pointer (to reduce dynamic lookup).
extern void (*egwSFPShdrStckPushAndBindShaders)(id, SEL);   ///< Shared pushAndBindShaders IMP function pointer (to reduce dynamic lookup).
extern void (*egwSFPShdrStckPopShaders)(id, SEL);           ///< Shared popShaders IMP function pointer (to reduce dynamic lookup).
extern EGWuint32 (*egwSFPShdrStckStackHash)(id, SEL);       ///< Shared stackHash IMP function pointer (to reduce dynamic lookup).
extern BOOL (*egwSFPShdrStckOpaque)(id, SEL);               ///< Shared isOpaque IMP function pointer (to reduce dynamic lookup).
extern void (*egwSFPTxtrStckPushAndBindTextures)(id, SEL);  ///< Shared pushAndBindTextures IMP function pointer (to reduce dynamic lookup).
extern void (*egwSFPTxtrStckPopTextures)(id, SEL);          ///< Shared popTextures IMP function pointer (to reduce dynamic lookup).
extern EGWuint32 (*egwSFPTxtrStckStackHash)(id, SEL);       ///< Shared stackHash IMP function pointer (to reduce dynamic lookup).
extern BOOL (*egwSFPTxtrStckOpaque)(id, SEL);               ///< Shared isOpaque IMP function pointer (to reduce dynamic lookup).


/// Light Stack.
/// Provides a re-usable stack that manages a stack of lights with automatic illumination frame checking.
@interface egwLightStack : NSObject <NSCopying> {
    EGWint8 _hIndex[EGW_LGHTSTACK_HTBLSIZE];///< Hash indexing table.
    struct {
        id<egwPLight> light;                ///< Light object (retained).
        const egwLightJumpTable* jmpTbl;    ///< Light object jump table (strong).
        EGWuint16 lFrame;                   ///< Illumination frame.
        EGWint8 rIndex;                     ///< Reverse hash index.
        EGWsingle sortVal;                  ///< Sort information.
    } _lights[EGW_LGHTSTACK_MAXLIGHTS];     ///< Lights array.
    EGWuint8 _lCount;                       ///< Light count.
    EGWuint16 _lFrame;                      ///< Latest frame.
    EGWint8 _farthest;                      ///< Farthest light index.
    EGWuint32 _sHash;                       ///< Stack hash.
}

/// Designated Initializer.
/// Initializes the light stack with a list of lights to initially add.
/// @param [in] firstLight First light object to add. May be nil.
/// @return Self upon success, otherwise nil.
- (id)initWithLights:(id<egwPLight>)firstLight, ...;


/// Add Light Method.
/// Adds a @a light to the stack, performing illumination frame checking and distance sorting (if @a sortOrigin is provided).
/// @param [in] light Light object (retained).
/// @param [in] sortOrigin Distance sorting position.
- (void)addLight:(id<egwPLight>)light sortByPosition:(egwVector3f*)sortOrigin;

/// Remove All Lights Method.
/// Releases all lights from the stack.
- (void)removeAllLights;

/// Push Light Method.
/// Pushes all lights onto the active graphics context's light stack.
- (void)pushLights;

/// Push and Bind Lights Method.
/// Pushes all lights onto the active graphics context's light stack, and binds lights.
- (void)pushAndBindLights;

/// Pop Lights Method.
/// Pops all lights off the active graphics context's light stack.
- (void)popLights;


/// Light Count Accessor.
/// Returns the number of lights in the stack that are current with their illumination frame number.
/// @return Light count.
- (EGWuint)lightCount;

/// Stack Hash Accessor.
/// Returns the stack hash for the current light stack contents.
- (EGWuint32)stackHash;

@end


/// Material Stack.
/// Provides a re-usable stack that manages a stack of materials.
@interface egwMaterialStack : NSObject <NSCopying> {
    struct {
        id<egwPMaterial> material;          ///< Material object (retained).
        const egwMaterialJumpTable* jmpTbl; ///< Material object jump table (strong).
    } _materials[EGW_MTRLSTACK_MAXMATERIALS];///< Materials array.
    EGWuint8 _mCount;                       ///< Material count.
    EGWuint32 _sHash;                       ///< Stack hash.
}

/// Designated Initializer.
/// Initializes the material stack with a list of materials to initially add.
/// @param [in] firstMaterial First material object to add. May be nil.
/// @return Self upon success, otherwise nil.
- (id)initWithMaterials:(id<egwPMaterial>)firstMaterial, ...;


/// Add Material Method.
/// Adds a @a material to the stack.
/// @param [in] material Material object (retained).
- (void)addMaterial:(id<egwPMaterial>)material;

/// Remove All Materials Method.
/// Releases all materials from the stack.
- (void)removeAllMaterials;

/// Push Materials Method.
/// Pushes all materials onto the active graphics context's material stack.
- (void)pushMaterials;

/// Push and Bind Materials Method.
/// Pushes all materials onto the active graphics context's material stack, and binds materials.
- (void)pushAndBindMaterials;

/// Pop Materials Method.
/// Pops all materials off the active graphics context's material stack.
- (void)popMaterials;


/// Material Count Accessor.
/// Returns the number of materials in the stack.
/// @return Material count.
- (EGWuint)materialCount;

/// Stack Hash Accessor.
/// Returns the stack hash for the current material stack contents.
- (EGWuint32)stackHash;


/// IsOpaque Poller.
/// Polls the object to determine status.
/// @return YES if material collection is considered opaque, otherwise NO.
- (BOOL)isOpaque;

@end


/// Shader Stack.
/// Provides a re-usable stack that manages a stack of shaders.
@interface egwShaderStack : NSObject <NSCopying> {
    struct {
        id<egwPShader> shader;              ///< Shader object (retained).
        const egwShaderJumpTable* jmpTbl;   ///< Shader object jump table (strong).
    } _shaders[EGW_SHDRSTACK_MAXSHADERS];   ///< Shaders array.
    BOOL _hasTimed;                         ///< Tracks having any timed textures.
    EGWuint8 _sCount;                       ///< Texture count.
    EGWuint32 _sHash;                       ///< Stack hash.
}

/// Designated Initializer.
/// Initializes the shader stack with a list of shaders to initially add.
/// @param [in] firstShader First shader object to add. May be nil.
/// @return Self upon success, otherwise nil.
- (id)initWithShaders:(id<egwPShader>)firstShader, ...;


/// Add Shader Method.
/// Adds a @a shader to the stack.
/// @param [in] shader Shader object (retained).
- (void)addShader:(id<egwPShader>)shader;

/// Remove All Shaders Method.
/// Releases all shaders from the stack.
- (void)removeAllShaders;

/// Push Shaders Method.
/// Pushes all shaders onto the active graphics context's shader stack.
- (void)pushShaders;

/// Push and Bind Shaders Method.
/// Pushes all shaders onto the active graphics context's shader stack, and binds shaders.
- (void)pushAndBindShaders;

/// Pop Shaders Method.
/// Pops all shaders off the active graphics context's shader stack.
- (void)popShaders;


/// First Timed Shader Accessor.
/// Returns the first shader that is also timed.
/// @return First timed shader, otherwise nil.
- (id<egwPTimed,egwPShader>)firstTimedShader;

/// Shader Count Accessor.
/// Returns the number of shaders in the stack.
/// @return Shader count.
- (EGWuint)shaderCount;

/// Stack Hash Accessor.
/// Returns the stack hash for the current shader stack contents.
- (EGWuint32)stackHash;


/// IsOpaque Poller.
/// Polls the object to determine status.
/// @return YES if shader collection is considered opaque, otherwise NO.
- (BOOL)isOpaque;

@end


/// Texture Stack.
/// Provides a re-usable stack that manages a stack of textures.
@interface egwTextureStack : NSObject <NSCopying> {
    struct {
        id<egwPTexture> texture;            ///< Texture object (retained).
        const egwTextureJumpTable* jmpTbl;  ///< Texture object jump table (strong).
    } _textures[EGW_TXTRSTACK_MAXTEXTURES]; ///< Textures array.
    BOOL _hasTimed;                         ///< Tracks having any timed textures.
    EGWuint8 _tCount;                       ///< Texture count.
    EGWuint32 _sHash;                       ///< Stack hash.
}

/// Designated Initializer.
/// Initializes the texture stack with a list of textures to initially add.
/// @param [in] firstTexture First texture object to add. May be nil.
/// @return Self upon success, otherwise nil.
- (id)initWithTextures:(id<egwPTexture>)firstTexture, ...;


/// Add Texture Method.
/// Adds a @a texture to the stack.
/// @param [in] texture Texture object (retained).
- (void)addTexture:(id<egwPTexture>)texture;

/// Remove All Textures Method.
/// Releases all textures from the stack.
- (void)removeAllTextures;

/// Push Textures Method.
/// Pushes all textures onto the active graphics context's texture stack.
- (void)pushTextures;

/// Push and Bind Textures Method.
/// Pushes all textures onto the active graphics context's texture stack, and binds textures.
- (void)pushAndBindTextures;

/// Pop Textures Method.
/// Pops all textures off the active graphics context's texture stack.
- (void)popTextures;


/// First Timed Texture Accessor.
/// Returns the first texture that is also timed.
/// @return First timed texture, otherwise nil.
- (id<egwPTimed,egwPTexture>)firstTimedTexture;

/// Stack Hash Accessor.
/// Returns the stack hash for the current texture stack contents.
- (EGWuint32)stackHash;

/// Texture Count Accessor.
/// Returns the number of textures in the stack.
/// @return Texture count.
- (EGWuint)textureCount;


/// IsOpaque Poller.
/// Polls the object to determine status.
/// @return YES if texture collection is considered opaque, otherwise NO.
- (BOOL)isOpaque;

@end

/// @}

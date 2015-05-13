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

/// @defgroup geWizES_inf_pgfxcontext egwPGfxContext
/// @ingroup geWizES_inf
/// Graphics API Context Protcol.
/// @{

/// @file egwPGfxContext.h
/// Graphics API Context Protcol.

#import "egwTypes.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPCamera.h"
#import "../gfx/egwGfxTypes.h"


/// Graphics Context Event Delegate.
/// Contains event methods that a delegate object can handle.
// TODO: Move this to sys. -jw
@protocol egwDGfxContextEvent <NSObject>
- (BOOL)willFinishInitializingGfxContext:(id<egwPGfxContext>)context;                   ///< @brief Further setup calls should go here. Return NO if failure.
- (void)didFinishInitializingGfxContext:(id<egwPGfxContext>)context;                    ///< @brief Notification of completed initialization.
- (BOOL)willShutDownGfxContext:(id<egwPGfxContext>)context;                             ///< @brief Determination of should shut down should go here. Return NO if cancel.
- (void)didShutDownGfxContext:(id<egwPGfxContext>)context;                              ///< @brief Notification of completed shut down.
- (void)didUpdateContext:(id<egwPGfxContext>)context framesPerSecond:(EGWsingle)fps;    ///< @brief Notification of updated FPS value.
@end


/// Graphics API Context Protocol.
/// Defines interactions for graphical API contexts (e.g. ones that manage graphical API interactivity).
@protocol egwPGfxContext <egwPContext>

/// Push Light Method.
/// Pushes @a light object onto light stack.
/// @param [in] light Light object (retained).
- (void)pushLight:(id<egwPLight>)light;

/// Pop Lights Method.
/// Pops @a count lights off the light stack.
/// @param [in] count Number of pops.
- (void)popLights:(EGWuint)count;

/// Bind Lights Method.
/// Re-binds all changed lights on the light stack.
- (void)bindLights;

/// Unbind Lights Method.
/// Un-binds all lights off the light stack.
- (void)unbindLights;

/// Push Material Method.
/// Pushes @a material object onto material stack.
/// @param [in] material Material object (retained).
- (void)pushMaterial:(id<egwPMaterial>)material;

/// Pop Materials Method.
/// Pops @a count materials off the material stack.
/// @param [in] count Number of pops.
- (void)popMaterials:(EGWuint)count;

/// Bind Material Method.
/// Re-binds all changed materials on the material stack.
- (void)bindMaterials;

/// Unbind Material Method.
/// Un-binds all materials off the material stack.
- (void)unbindMaterials;

/// Push Texture Method.
/// Pushes @a texture object onto texture stack.
/// @param [in] texture Texture object (retained).
- (void)pushTexture:(id<egwPTexture>)texture;

/// Pop Textures Method.
/// Pops @a count textures off the texture stack.
/// @param [in] count Number of pops.
- (void)popTextures:(EGWuint)count;

/// Bind Texture Method.
/// Re-binds all changed textures on the texture stack.
- (void)bindTextures;

/// Unbind Texture Method.
/// Un-binds all textures off the texture stack.
- (void)unbindTextures;

/// Opacity Determination Method.
/// Determines if the provided @a alpha is considered opaque or not.
/// @param [in] alpha Alpha value [0,1].
/// @return YES if @a alpha is considered opaque, otherwise NO.
- (BOOL)determineOpacity:(const EGWsingle)alpha;

/// Report Dirty Light Bind For Illumination Stage Method.
/// Marks the light binded to @a illumStage as invalidated.
/// @param [in] illumStage Illumination stage number.
/// @note If one modifies light bindings for the given stage outside of the binding system, one should always call this method.
- (void)reportDirtyLightBindForIlluminationStage:(EGWuint)illumStage;

/// Report Dirty Material Bind For Surfacing Stage Method.
/// Marks the material binded to @a srfcgStage as invalidated.
/// @param [in] srfcgStage Surfacing stage number.
/// @note If one modifies material bindings for the given stage outside of the binding system, one should always call this method.
- (void)reportDirtyMaterialBindForSurfacingStage:(EGWuint)srfcgStage;

/// Report Dirty Texture Bind For Texturing Stage Method.
/// Marks the texture binded to @a srfcgStage as invalidated.
/// @param [in] txtrStage Texturing stage number.
/// @note If one modifies texture bindings for the given texturing stage outside of the binding system, one should always call this method.
- (void)reportDirtyTextureBindForTexturingStage:(EGWuint)txtrStage;

/// Active Camera Accessor.
/// Returns the currently activate rendering camera.
/// @return Rendering camera.
- (id<egwPCamera>)activeCamera;

/// Illumination Frame Accessor.
/// Returns the current illumination frame number.
/// @return Illumination frame number.
- (EGWuint16)illuminationFrame;

/// Rendering Frame Accessor.
/// Returns the current rendering frame number.
/// @return Rendering frame number.
- (EGWuint16)renderingFrame;

/// Max Lights Accessor.
/// Returns the max supported number of consecutively active lights (i.e. light stack size).
/// @return Maximum active lights.
- (EGWuint16)maxActiveLights;

/// Max Materials Accessor.
/// Returns the max supported number of consecutively active materials (i.e. material stack size).
/// @return Maximum active materials.
- (EGWuint16)maxActiveMaterials;

/// Max Multitextures Accessor.
/// Returns the max supported number of consecutively active textures (i.e. texture stack size).
/// @return Maximum active textures.
- (EGWuint16)maxActiveTextures;

/// Max Texture Size Accessor.
/// Returns the max texture size supported.
/// @return Maximum texture size.
- (const egwSize2i*)maxTextureSize;


/// Active Camera Mutator.
/// Sets the currently active rendering camera.
/// @param [in] camera Rendering camera object (retained).
- (void)setActiveCamera:(id<egwPCamera>)camera;

@end

/// @}

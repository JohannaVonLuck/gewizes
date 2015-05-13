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

/// @defgroup geWizES_inf_prenderable egwPRenderable
/// @ingroup geWizES_inf
/// Renderable Protocol.
/// @{

/// @file egwPRenderable.h
/// Renderable Protocol.

#import "egwTypes.h"
#import "../inf/egwPCoreObject.h"
#import "../sys/egwSysTypes.h"
#import "../math/egwMathTypes.h"
#import "../gfx/egwGfxTypes.h"
#import "../misc/egwMiscTypes.h"


/// Renderable Protocol.
/// Defines interactions for renderable components (i.e. objects that can be rendered).
@protocol egwPRenderable <egwPCoreObject>

/// Illuminate With Light Method.
/// Illuminates object with the provided @a light for subsequent render passes for when light frame check is valid.
/// @param [in] light Light object.
- (void)illuminateWithLight:(id<egwPLight>)light;

/// Start Rendering Method.
/// Starts rendering object by adding itself into the world scene.
- (void)startRendering;

/// Stop Rendering Method.
/// Stops rendering object by removing itself from the world scene.
- (void)stopRendering;

/// Render With Flags Method.
/// Renders object with provided rendering reply @a flags.
/// @note Do not call this method directly - this method is called automatically by the system.
/// @param [in] flags Bit-wise reply flag settings.
- (void)renderWithFlags:(EGWuint32)flags;


/// Light Stack Accessor.
/// Returns the object's associated light stack.
/// @return Light stack, otherwise nil (if unused).
- (egwLightStack*)lightStack;

/// Material Stack Accessor.
/// Returns the object's associated material stack.
/// @return Material stack, otherwise nil (if unused).
- (egwMaterialStack*)materialStack;

/// Rendering Base Object Accessor.
/// Returns the corresponding base instance object.
/// @note This is used for determination of EGW_GFXOBJ_RPLYFLG_SAMELASTBASE reply flag.
/// @return Base instance object, otherwise self (if unused).
- (id<NSObject>)renderingBase;

/// Rendering Bounding Volume Accessor.
/// Returns the object's WCS rendering bounding volume.
/// @return Rendering bounding volume (WCS).
- (id<egwPBounding>)renderingBounding;

/// Rendering Flags Accessor.
/// Returns the object's rendering flags for subsequent render calls.
/// @return Bit-wise flag settings.
- (EGWuint32)renderingFlags;

/// Rendering Frame Accessor.
/// Returns the current rendering frame number that this object is set to be rendered on,
/// @return Current rendering frame number.
- (EGWuint16)renderingFrame;

/// Rendering Source Accessor.
/// Returns the object's WCS rendering source position (i.e. optical center).
/// @return Rendering source position (WCS).
- (const egwVector4f*)renderingSource;

/// Rendering Syncronization Validater Accessor.
/// Returns the validater that manages component synchronization with a graphics renderer.
/// @return Rendering validater, otherwise nil (if unused).
- (egwValidater*)renderingSync;


/// Light Stack Mutator.
/// Sets the light stack associated with the object.
/// @param [in] lghtStack Light stack (retained).
- (void)setLightStack:(egwLightStack*)lghtStack;

/// Material Stack Mutator.
/// Sets the material stack associated with the object.
/// @param [in] mtrlStack Material stack (retained).
- (void)setMaterialStack:(egwMaterialStack*)mtrlStack;

/// Rendering Flags Mutator.
/// Sets the object's rendering @a flags for subsequent render calls.
/// @param [in] flags Bit-wise flag settings.
- (void)setRenderingFlags:(EGWuint)flags;

/// Rendering Frame Mutator.
/// Sets the rendering frame @a frameNumber for this object to be rendered on.
/// @param [in] frmNumber Next frame number to render on.
- (void)setRenderingFrame:(EGWint)frmNumber;


/// IsOpaque Poller.
/// Polls the object to determine status.
/// @note This method is used in deferred rendering to order objects before rendering runthrough.
/// @return YES if object is considered opaque, otherwise NO.
- (BOOL)isOpaque;

/// IsRendering Poller.
/// Polls the object to determine status.
/// @return YES if object is rendering, otherwise NO.
- (BOOL)isRendering;

@end

/// @}

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

/// @defgroup geWizES_inf_plight egwPLight
/// @ingroup geWizES_inf
/// Light Protocol.
/// @{

/// @file egwPLight.h
/// Light Protocol.

#import "egwTypes.h"
#import "../inf/egwPCoreObject.h"
#import "../inf/egwPOrientated.h"
#import "../inf/egwPBounding.h"
#import "../math/egwMathTypes.h"
#import "../misc/egwMiscTypes.h"


/// Light Jump Table.
/// Contains function pointers to class methods for faster invocation in low tier sections.
typedef struct {
    BOOL (*fpIBind)(id, SEL, EGWuint, EGWuint); ///< FP to bindForIlluminationStage:withFlags:.
    BOOL (*fpIUnbind)(id, SEL, EGWuint);        ///< FP to unbindIlluminationWithFlags:.
    id<NSObject> (*fpLBase)(id, SEL);           ///< FP to lightBase.
    EGWuint (*fpIFlags)(id, SEL);               ///< FP to illuminationFlags.
    egwValidater* (*fpISync)(id, SEL);          ///< FP to illuminationSync.
    EGWuint (*fpILBStage)(id, SEL);             ///< FP to lastIlluminationBindingStage.
} egwLightJumpTable;


/// Light Protocol.
/// Defines interactions for lights.
@protocol egwPLight <egwPCoreObject, egwPOrientated>

/// Start Illuminating Method.
/// Starts illuminating object by adding itself into the world scene.
- (void)startIlluminating;

/// Stop Illuminating Method.
/// Stops illuminating object by removing itself from the world scene.
- (void)stopIlluminating;

/// Bind Illumination Method.
/// Binds light for provided illumination stage with provided @a flags.
/// @note Do not call this method directly - this method is called automatically by the system.
/// @param [in] illumStage Illumination stage number.
/// @param [in] flags Binding flags.
/// @return YES if bind was successful, otherwise NO.
- (BOOL)bindForIlluminationStage:(EGWuint)illumStage withFlags:(EGWuint)flags;

/// Unbind Illumination Method.
/// Unbinds light from its last bound stage with provided @a flags.
/// @note Do not call this method directly - this method is called automatically by the system.
/// @param [in] flags Binding flags.
/// @return YES if unbind was successful, otherwise NO.
- (BOOL)unbindIlluminationWithFlags:(EGWuint)flags;


/// Light Jump Table.
/// Returns the light's jump table for subsequent low tier calls.
/// @return Light jump table.
- (const egwLightJumpTable*)lightJumpTable;

/// Illumination Base Object Accessor.
/// Returns the corresponding base instance object.
/// @note This is used for determination of EGW_BNDOBJ_BINDFLG_SAMELASTBASE reply flag.
/// @return Base instance object, otherwise self (if unused).
- (id<NSObject>)lightBase;

/// Illumination Attenuation Accessor.
/// Returns the light's illumination attenuation.
/// @return Illumination attenuation.
- (const egwAttenuation3f*)illuminationAttenuation;

/// Illumination Bounding Volume Accessor.
/// Returns the light's WCS illumination bounding volume.
/// @return Illumination bounding volume (WCS).
- (id<egwPBounding>)illuminationBounding;

/// Illumination Flags Accessor.
/// Returns the light's illumination flags for subsequent illumination calls.
/// @return Bit-wise flag settings.
- (EGWuint)illuminationFlags;

/// Illumination Material Accessor.
/// Returns the light's illumination material.
/// @return Associated illumination material.
- (const egwMaterial4f*)illuminationMaterial;

/// Illumination Source Accessor.
/// Returns the light's WCS illumination source position.
/// @return WCS illumination source position.
- (const egwVector4f*)illuminationSource;

/// Illumination Syncronization Validater Accessor.
/// Returns the validater that manages component synchronization with an API interface.
/// @return Illumination validater, otherwise nil (if unused).
- (egwValidater*)illuminationSync;

/// Last Illumination Binding Stage Accessor.
/// Returns the least recently used illumination binding stage number.
/// @return Last illumination binding stage number, otherwise NSNotFound if not yet bounded.
- (EGWuint)lastIlluminationBindingStage;


/// Illumination Flags Mutator.
/// Sets the light's illumination @a flags for subsequent illumination calls.
/// @param [in] flags Bit-wise flag settings.
- (void)setIlluminationFlags:(EGWuint)flags;


/// IsBoundForIllumination Poller.
/// Polls the object to determine status.
/// @return YES if light is currently bound, otherwise NO.
- (BOOL)isBoundForIllumination;

/// IsIlluminating Poller.
/// Polls the object to determine status.
/// @return YES if light is currently illuminating, otherwise NO.
- (BOOL)isIlluminating;

@end

/// @}

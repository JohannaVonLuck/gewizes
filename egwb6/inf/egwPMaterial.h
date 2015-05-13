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

/// @defgroup geWizES_inf_pmaterial egwPMaterial
/// @ingroup geWizES_inf
/// Material Protocol.
/// @{

/// @file egwPMaterial.h
/// Material Protocol.

#import "egwTypes.h"
#import "../inf/egwPCoreObject.h"
#import "../misc/egwMiscTypes.h"


/// Material Jump Table.
/// Contains function pointers to class methods for faster invocation in low tier sections.
typedef struct {
    id (*fpRetain)(id, SEL);                    ///< FP to retain.
    void (*fpRelease)(id, SEL);                 ///< FP to release.
    BOOL (*fpSBind)(id, SEL, EGWuint, EGWuint); ///< FP to bindForSurfacingStage:withFlags:.
    BOOL (*fpSUnbind)(id, SEL, EGWuint);        ///< FP to unbindSurfacingWithFlags:.
    id<NSObject> (*fpMBase)(id, SEL);           ///< FP to materialBase.
    egwValidater* (*fpSSync)(id, SEL);          ///< FP to surfacingSync.
    EGWuint (*fpSLBStage)(id, SEL);             ///< FP to lastSurfacingBindingStage.
    BOOL (*fpOpaque)(id, SEL);                  ///< FP to isOpaque.
} egwMaterialJumpTable;


/// Material Protocol.
/// Defines interactions for materials.
@protocol egwPMaterial <egwPCoreObject>

/// Bind Surfacing Method.
/// Binds material for next object surfacing pass with provided @a flags.
/// @note Do not call this method directly - this method is called automatically by the system.
/// @param [in] srfcgStage Surfacing stage number.
/// @param [in] flags Binding flags.
/// @return YES if bind was successful, otherwise NO.
- (BOOL)bindForSurfacingStage:(EGWuint)srfcgStage withFlags:(EGWuint)flags;

/// Unbind Surfacing Method.
/// Unbinds material from its last bound stage with provided @a flags.
/// @note Do not call this method directly - this method is called automatically by the system.
/// @param [in] flags Binding flags.
/// @return YES if unbind was successful, otherwise NO.
- (BOOL)unbindSurfacingWithFlags:(EGWuint)flags;


/// Material Jump Table Accessor.
/// Returns the material's jump table for subsequent low tier calls.
/// @return Material jump table.
- (const egwMaterialJumpTable*)materialJumpTable;

/// Material Base Object Accessor.
/// Returns the corresponding base instance object.
/// @note This is used for determination of EGW_BNDOBJ_BINDFLG_SAMELASTBASE reply flag.
/// @return Base instance object, otherwise self (if unused).
- (id<NSObject>)materialBase;

/// Surfacing Syncronization Validater Accessor.
/// Returns the validater that manages component synchronization with an API interface.
/// @return Surfacing material validater, otherwise nil (if unused).
- (egwValidater*)surfacingSync;

/// Last Surfacing Binding Stage Accessor.
/// Returns the least recently used surfacing binding stage number.
/// @return Last binding stage number, otherwise NSNotFound if not yet bounded.
- (EGWuint)lastSurfacingBindingStage;


/// Surfacing Material Getter.
/// Fills passed buffer with a compatible material representation.
/// @param [out] srfcgMat Surfacing material.
- (void)getSurfacingMaterial:(egwMaterial4f*)srfcgMat;


/// IsBoundForSurfacing Poller.
/// Polls the object to determine status.
/// @return YES if material is currently bound, otherwise NO.
- (BOOL)isBoundForSurfacing;

/// IsOpaque Poller.
/// Polls the object to determine status.
/// @return YES if material is considered opaque, otherwise NO.
- (BOOL)isOpaque;

@end

/// @}

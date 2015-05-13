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

/// @defgroup geWizES_inf_porientated egwPOrientated
/// @ingroup geWizES_inf
/// Orientated Protocol.
/// @{

/// @file egwPOrientated.h
/// Orientated Protocol.

#import "egwTypes.h"
#import "../inf/egwPBounding.h"
#import "../inf/egwPInterpolator.h"
#import "../math/egwMathTypes.h"
#import "../misc/egwMiscTypes.h"


/// Orientated Protocol.
/// Defines interactions for orientated components.
@protocol egwPOrientated <NSObject>

/// Apply Orientation Method.
/// Applies the object's LCS and WCS transforms to its underlying components.
- (void)applyOrientation;

/// Offset (byTransform) Method.
/// Offsets the object in the LCS by the provided @a transform for subsequent task passes.
/// @note This method delays application of @a lcsTransform until an object's corresponding sync is validated or applyOrientation is called.
/// @param [in] lcsTransform MMCS->LCS transformation matrix.
- (void)offsetByTransform:(const egwMatrix44f*)lcsTransform;

/// Orientate (byTransform) Method.
/// Orients the object in the WCS by the provided @a wcsTransform for subsequent task passes.
/// @note This method delays application of @a wcsTransform until an object's corresponding sync is validated or applyOrientation is called.
/// @param [in] wcsTransform LCS->WCS transformation matrix.
- (void)orientateByTransform:(const egwMatrix44f*)wcsTransform;

/// Orientate (byImpending) Method.
/// Instructs object that it will be offseted/oriented in the future for subsequent task passes.
/// @note This method is used to invalidate any orientation syncs, usually in conjunction with the object tree system.
- (void)orientateByImpending;


/// MMCS->LCS Transform Accessor.
/// Returns the object's MMCS->LCS transformation matrix.
/// @return MMCS->LCS transform.
- (const egwMatrix44f*)lcsTransform;

/// LCS->WCS Transform Accessor.
/// Returns the object's LCS->WCS transformation matrix.
/// @return LCS->WCS transform.
- (const egwMatrix44f*)wcsTransform;

/// Offset Driver Accessor.
/// Returns the offset driver interpolator.
/// @return Offset driver.
- (id<egwPInterpolator>)offsetDriver;

/// Orientate Driver Accessor.
/// Returns the orientate driver interpolator.
/// @return Orientate driver.
- (id<egwPInterpolator>)orientateDriver;


/// Offset Driver Tryer.
/// Attempts to set the object's LCS offset driver to @a lcsIpo.
/// @param [in] lcsIpo MMCS->LCS transformation driver (retained).
/// @return YES if interpolator driver is accepted, otherwise NO.
- (BOOL)trySetOffsetDriver:(id<egwPInterpolator>)lcsIpo;

/// Orientate Driver Tryer.
/// Attempts to set the object's WCS orientate driver to @a wcsIpo.
/// @param [in] wcsIpo LCS->WCS transformation driver (retained).
/// @return YES if interpolator driver is accepted, otherwise NO.
- (BOOL)trySetOrientateDriver:(id<egwPInterpolator>)wcsIpo;


/// IsOrientationPending Poller.
/// Polls the object to determine status.
/// @return YES if object has a pending orientation, otherwise NO.
- (BOOL)isOrientationPending;

@end

/// @}

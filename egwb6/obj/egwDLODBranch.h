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

/// @defgroup geWizES_obj_dlodbranch egwDLODBranch
/// @ingroup geWizES_obj
/// Discrete Level-of-Detail Branch Node Asset.
/// @{

/// @file egwDLODBranch.h
/// Discrete Level-of-Detail Branch Node Asset Interface.

#import "egwObjTypes.h"
#import "../inf/egwPAsset.h"
#import "../inf/egwPObjNode.h"
#import "../inf/egwPObjBranch.h"
#import "../inf/egwPRenderable.h"
#import "../math/egwMathTypes.h"
#import "../obj/egwObjectBranch.h"
#import "../obj/egwSwitchBranch.h"
#import "../misc/egwMiscTypes.h"


/// Discrete Level-of-Detail Branch Node Asset.
/// Acts as an renderable multi-container for object nodes arranged in a hierarchy capable of being discretely switched between at runtime based upon distance from active camera.
@interface egwDLODBranch : egwSwitchBranch <egwPRenderable> {
    BOOL _isRendering;                      ///< Tracks rendering status.
    id<egwPGfxContext> _gfxContext;         ///< Associated graphics context (retained).
    
    BOOL _opacity;                          ///< Opacity tracking.
    EGWuint16 _vFrame;                      ///< Camera viewing frame number.
    
    EGWsingle* _cSqrdDiss;                  ///< DLOD control squared distances (repeated).
}

/// Designated Initializer.
/// Initializes the DLOD node asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] parent Parent container node (retained).
/// @param [in] nodes Children node instances array (contents retained).
/// @param [in] bndClass Default bounding class. May be nil (for egwBoundingSphere).
/// @param [in] sets Total child set collections.
/// @param [in] distances DLOD control distances (>=, n-1). May be NULL (creates blank).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent parentNode:(id<egwPObjectBranch>)parent childNodes:(NSArray*)nodes defaultBounding:(Class)bndClass totalSets:(EGWuint16)sets controlDistances:(EGWsingle*)distances;


/// Set DLOD Control Distance Mutator.
/// Sets the DLOD control distance for the child set collection indexed by @a setIndex to @a distance.
/// @note Control distances should always stay in ascending sorted order.
/// @param [in] setIndex Child set collection index [1,n-1].
/// @param [in] distance Control distance value (>=).
- (void)setDLOD:(EGWuint16)setIndex controlDistance:(EGWsingle)distance;

@end

/// @}

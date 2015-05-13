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

/// @defgroup geWizES_obj_transformbranch egwTransformBranch
/// @ingroup geWizES_obj
/// Transform Branch Node Asset.
/// @{

/// @file egwTransformBranch.h
/// Transform Branch Node Asset Interface.

#import "egwObjTypes.h"
#import "../inf/egwPAsset.h"
#import "../inf/egwPObjNode.h"
#import "../inf/egwPObjBranch.h"
#import "../inf/egwPBounding.h"
#import "../math/egwMathTypes.h"
#import "../obj/egwObjectBranch.h"
#import "../misc/egwMiscTypes.h"


/// Transform Branch Node Asset.
/// Acts as an abstract container for object nodes arranged in a hierarchy capable of being hierarchially transformed.
@interface egwTransformBranch : egwObjectBranch <egwPOrientated> {
    BOOL _ortPending;                       ///< Orientation transforms pending.
    
    egwMatrix44f _wcsTrans;                 ///< Orientation transform (LCS->WCS).
    egwMatrix44f _lcsTrans;                 ///< Offset transform (MMCS->LCS).
    id<egwPInterpolator> _wcsIpo;           ///< Orientation driver interpolator (retained).
    id<egwPInterpolator> _lcsIpo;           ///< Offset driver interpolator (retained).
}

@end

/// @}

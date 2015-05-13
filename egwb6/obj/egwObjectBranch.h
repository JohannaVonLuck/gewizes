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

/// @defgroup geWizES_obj_objectbranch egwObjectBranch
/// @ingroup geWizES_obj
/// Object Branch Node Asset.
/// @{

/// @file egwObjectBranch.h
/// Object Branch Node Asset Interface.

#import "egwObjTypes.h"
#import "../inf/egwPAsset.h"
#import "../inf/egwPObjNode.h"
#import "../inf/egwPObjBranch.h"
#import "../inf/egwPBounding.h"
#import "../math/egwMathTypes.h"
#import "../misc/egwMiscTypes.h"


/// Object Branch Node Asset.
/// Acts as an abstract container for object nodes arranged in a hierarchy.
/// @note INTENDED AS AN ABSTRACT CLASS ONLY!
@interface egwObjectBranch : NSObject <egwPAsset, egwPObjectBranch> {
    NSString* _ident;                       ///< Unique identity (retained).
    
    BOOL _invkChild;                        ///< Child invocation tracking.
    BOOL _invkSelf;                         ///< Self invocation tracking.
    BOOL _invkParent;                       ///< Parent invocation tracking.
    NSMutableArray* _children;              ///< Children collection (retained).
    id<egwPObjectBranch> _parent;           ///< Parent node (weak).
    Class _dfltBnd;                         ///< Default bounding class.
    EGWuint _cType;                         ///< Merged core object type.
    
    EGWuint16 _audioObjCount;               ///< Audio core objects count.
    EGWuint16 _graphicObjCount;             ///< Graphic core objects count.
    EGWuint16 _animateObjCount;             ///< Animate core objects count.
    EGWuint8 _cameraObjCount;               ///< Camera core objects count.
    EGWuint8 _lightObjCount;                ///< Light core objects count.
    egwCoreComponents* _audioObj;           ///< Audio core objects merged component set.
    egwCoreComponents* _graphicObj;         ///< Graphic core objects merged component set.
    egwCoreComponents* _animateObj;         ///< Animate core object merged component set.
    egwCoreComponents* _cameraObj;          ///< Camera core object merged component set.
    egwCoreComponents* _lightObj;           ///< Light core objects merged component set.
}

/// Designated Initializer.
/// Initializes the object node asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] parent Parent container node (retained).
/// @param [in] nodes Children node instances array (contents retained).
/// @param [in] bndClass Default bounding class. May be nil (for egwBoundingSphere).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent parentNode:(id<egwPObjectBranch>)parent childNodes:(NSArray*)nodes defaultBounding:(Class)bndClass;

@end

/// @}

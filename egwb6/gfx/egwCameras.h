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

/// @defgroup geWizES_gfx_cameras egwCameras
/// @ingroup geWizES_gfx
/// Camera Assets.
/// @{

/// @file egwCameras.h
/// Camera Assets Interfaces.

#import "egwGfxTypes.h"
#import "../inf/egwPAsset.h"
#import "../inf/egwPObjLeaf.h"
#import "../inf/egwPAssetBase.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPGfxContext.h"
#import "../inf/egwPBounding.h"
#import "../inf/egwPCamera.h"
#import "../math/egwMathTypes.h"
#import "../obj/egwObjTypes.h"
#import "../misc/egwMiscTypes.h"


#define EGW_CAMERA_ORTHO_ZFALIGN_BTMLFT 0x1100  ///< Zero position is at bottom-left-hand of screen (up flow).
#define EGW_CAMERA_ORTHO_ZFALIGN_TOPLFT 0x1400  ///< Zero position is at top-left-hand of screen (down flow).
#define EGW_CAMERA_ORTHO_ZFALIGN_CENTER 0x2200  ///< Zero position is at center of screen (center flow).


/// Perspective Camera Instance Asset.
/// Contains unique instance data relating to perspective cameras.
@interface egwPerspectiveCamera : NSObject <egwPAsset, egwPObjectLeaf, egwPCamera> {
    egwCameraBase* _base;                   ///< Base object instance (retained).
    NSString* _ident;                       ///< Unique identity (retained).
    BOOL _invkParent;                       ///< Parent invocation tracking.
    BOOL _ortPending;                       ///< Orientation transforms pending.
    id<egwPObjectBranch> _parent;           ///< Parent node (weak).
    
    EGWuint _vFlags;                        ///< Viewing flags.
    EGWuint16 _vFrame;                      ///< Viewing frame number.
    egwValidater* _pSync;                   ///< Playback order sync (retained).
    egwValidater* _rSync;                   ///< Rendering order sync (retained).
    egwValidater* _vSync;                   ///< Viewing order sync (retained).
    
    egwMatrix44f _wcsTrans;                 ///< Orientation transform (LCS->WCS).
    egwMatrix44f _lcsTrans;                 ///< Offset transform (MMCS->LCS).
    egwMatrix44f _ccsTrans;                 ///< Inverse orientation transform (WCS->MCS).
    egwVector4f _wcsVelocity;               ///< Velocity vector (WCS).
    id<egwPBounding> _wcsFVBVol;            ///< Camera fine-grained viewing volume (WCS, retained).
    id<egwPBounding> _wcsCVBVol;            ///< Camera coarse-grained viewing volume (WCS, retained).
    id<egwPInterpolator> _wcsIpo;           ///< Orientation driver interpolator (retained).
    id<egwPInterpolator> _lcsIpo;           ///< Offset driver interpolator (retained).
}

/// Designated Initializer.
/// Initializes a perspective projected camera asset (for 3D rendering) with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] angle Grasp angle (degrees).
/// @param [in] fov Field of view angle (degrees).
/// @param [in] aspect Viewing aspect ratio (width/height).
/// @param [in] near Front/near viewing clip plane.
/// @param [in] far Back/far viewing clip plane.
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent graspAngle:(EGWsingle)angle fieldOfView:(EGWsingle)fov aspectRatio:(EGWsingle)aspect frontPlane:(EGWsingle)near backPlane:(EGWsingle)far;

/// Copy Initializer.
/// Copies a camera asset with provided unique settings.
/// @param [in] asset Asset to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent;


/// WCS->CCS Transform Accessor.
/// Returns the camera's WCS->CCS transformation matrix.
/// @return WCS->CCS transform.
- (const egwMatrix44f*)ccsTransform;

@end


/// Orthogonal Camera Instance Asset.
/// Contains unique instance data relating to orthogonal cameras.
@interface egwOrthogonalCamera : NSObject <egwPAsset, egwPObjectLeaf, egwPCamera> {
    egwCameraBase* _base;                   ///< Base object instance (retained).
    NSString* _ident;                       ///< Unique identity (retained).
    BOOL _invkParent;                       ///< Parent invocation tracking.
    BOOL _ortPending;                       ///< Orientation transforms pending.
    id<egwPObjectBranch> _parent;           ///< Parent node (weak).
    
    EGWuint _vFlags;                        ///< Viewing flags.
    EGWuint16 _vFrame;                      ///< Viewing frame number.
    egwValidater* _pSync;                   ///< Playback order sync (retained).
    egwValidater* _rSync;                   ///< Rendering order sync (retained).
    egwValidater* _vSync;                   ///< Viewing order sync (retained).
    
    egwMatrix44f _wcsTrans;                 ///< Orientation transform (LCS->WCS).
    egwMatrix44f _lcsTrans;                 ///< Offset transform (MMCS->LCS).
    egwMatrix44f _ccsTrans;                 ///< Camera scene transform (WCS->CCS, i.e. WCS->MCS).
    egwVector4f _wcsVelocity;               ///< Velocity vector (WCS).
    id<egwPBounding> _wcsFVBVol;            ///< Camera fine-grained viewing volume (WCS, retained).
    id<egwPBounding> _wcsCVBVol;            ///< Camera coarse-grained viewing volume (WCS, retained).
    id<egwPInterpolator> _wcsIpo;           ///< Orientation driver interpolator (retained).
    id<egwPInterpolator> _lcsIpo;           ///< Offset driver interpolator (retained).
}

/// Designated Initializer.
/// Initializes an orthogonal projected camera asset (for 2D rendering) with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] angle Grasp angle (degrees).
/// @param [in] width WCS surface width.
/// @param [in] height WCS surface height.
/// @param [in] zfAlign Zero offset alignment mode (EGW_CAMERA_ORTHO_ZFALIGN_*).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent graspAngle:(EGWsingle)angle surfaceWidth:(EGWsingle)width surfaceHeight:(EGWsingle)height zeroAlign:(EGWuint)zfAlign;

/// Copy Initializer.
/// Copies a camera asset with provided unique settings.
/// @param [in] asset Asset to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent;


/// WCS->CCS Transform Accessor.
/// Returns the camera's WCS->CCS transformation matrix.
/// @return WCS->CCS transform.
- (egwMatrix44f*)ccsTransform;

@end


/// Camera Asset Base.
/// Contains shared instance data relating to cameras.
/// @note Doubles up for base to both egwPerspectiveCamera and egwOrthogonalCamera - not all fields are used.
@interface egwCameraBase : NSObject <egwPAssetBase> {
    EGWuint _instCounter;                   ///< Instantiation counter.
    NSString* _ident;                       ///< Unique identity (retained).
    id<egwPGfxContext> _gfxContext;         ///< Associated graphics context (retained).
    id<egwPSndContext> _sndContext;         ///< Associated sound context (retained).
    
    egwMatrix44f _ndcsTrans;                ///< Normalized device transform (CCS->NDCS).
    egwMatrix44f _ccsTrans;                 ///< Picking ray transform (NDCS->CCS).
    id<egwPBounding> _mcsFVBVol;            ///< Camera fine-grained viewing volume (CCS).
    id<egwPBounding> _mcsCVBVol;            ///< Camera coarse-grained viewing volume (CCS).
}

/// Perspective Initializer.
/// Initializes a perspective projected camera asset base (for 3D rendering) with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] angle Grasp angle (degrees).
/// @param [in] fov Field of view angle (degrees).
/// @param [in] aspect Viewing aspect ratio (width/height).
/// @param [in] near Front/near viewing clip plane.
/// @param [in] far Back/far viewing clip plane.
/// @return Self upon success, otherwise nil.
- (id)initPerspectiveWithIdentity:(NSString*)assetIdent graspAngle:(EGWsingle)angle fieldOfView:(EGWsingle)fov aspectRatio:(EGWsingle)aspect frontPlane:(EGWsingle)near backPlane:(EGWsingle)far;

/// Orhtogonal Initializer.
/// Initializes an orthogonal projected camera asset base (for 2D rendering) with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] angle Grasp angle (degrees).
/// @param [in] width WCS surface width.
/// @param [in] height WCS surface height.
/// @param [in] zfAlign Zero offset alignment mode (EGW_CAMERA_ORTHO_ZFALIGN_*).
/// @return Self upon success, otherwise nil.
- (id)initOrthogonalWithIdentity:(NSString*)assetIdent graspAngle:(EGWsingle)angle surfaceWidth:(EGWsingle)width surfaceHeight:(EGWsingle)height zeroAlign:(EGWuint)zfAlign;


/// CCS->NDCS Transform Accessor.
/// Returns the base CCS->NDCS transformation matrix.
/// @return CCS->NDCS transform.
- (egwMatrix44f*)ndcsTransform;

/// NDCS->CCS Transform Accessor.
/// Returns the base NDCS->CCS transformation matrix.
/// @return NDCS->CCS transform.
- (egwMatrix44f*)ccsTransform;

/// Coarse Viewing Volume Accessor.
/// Returns the base MMCS coarse viewing bounding volume.
/// @return Coarse viewing volume (MMCS).
- (id<egwPBounding>)viewingBounding;

/// Fine Viewing Volume Accessor.
/// Returns the base MMCS fine viewing bounding volume.
/// @return Fine viewing volume (MMCS).
- (id<egwPBounding>)cameraBounding;

@end

/// @}

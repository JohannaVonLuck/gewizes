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

/// @defgroup geWizES_gui_pager egwPager
/// @ingroup geWizES_gui
/// Pager Widget.
/// @{

/// @file egwPager.h
/// Pager Widget Interface.

#import "egwGuiTypes.h"
#import "../inf/egwPAsset.h"
#import "../inf/egwPAssetBase.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPSubTask.h"
#import "../inf/egwPGfxContext.h"
#import "../inf/egwPWidget.h"
#import "../sys/egwSysTypes.h"
#import "../math/egwMathTypes.h"
#import "../gfx/egwGfxTypes.h"
#import "../obj/egwObjTypes.h"
#import "../misc/egwMiscTypes.h"


/// Pager Widget.
/// Contains unique instance data relating to a linear page dot pageser capable of being oriented, & rendered (both 2D & 3D).
@interface egwPager : NSObject <egwPAsset, egwPSubTask, egwPWidget, egwDValidationEvent> {
    egwSpritedImageBase* _base;             ///< Base object instance (retained).
    NSString* _ident;                       ///< Unique identity (retained).
    BOOL _invkParent;                       ///< Parent invocation tracking.
    BOOL _ortPending;                       ///< Orientation transforms pending.
    BOOL _isRendering;                      ///< Tracks rendering status.
    id<egwPObjectBranch> _parent;           ///< Parent node (weak).
    id<egwDPagerEvent> _delegate;           ///< Event responder delegate (retained).
    
    EGWuint32 _rFlags;                      ///< Rendering flags.
    EGWuint16 _rFrame;                      ///< Rendering frame number.
    egwValidater* _rSync;                   ///< Rendering order sync (retained).
    egwLightStack* _lStack;                 ///< Light illumination stack (retained).
    egwMaterialStack* _mStack;              ///< Material rendering stack (retained).
    
    BOOL _isEnabled;                        ///< Tracks event responders status.
    BOOL _isVisible;                        ///< Tracks visibility status.
    EGWuint _actvPage;                      ///< Tracks active page index.
    EGWuint _totalPages;                    ///< Tracks total pages.
    struct {
        egwVector2f iptCoords[4];           ///< Inactive page texture coordinates (MCS, repeated).
        egwVector2f aptCoords[4];           ///< Active page texture coordinates (MCS, repeated).
    } _isMesh;                              ///< Sprite instance mesh data (MCS).
    egwSize2i _pSize;                       ///< Pager size (MMCS, repeated).
    
    egwValidater* _gbSync;                  ///< Geometry buffer sync (retained).
    EGWuint _geoAID;                        ///< Geometry buffer arrays identifier.
    EGWuint _geoStrg;                       ///< Geometry storage.
    
    BOOL _isTBound;                         ///< Texturing binding status.
    EGWuint _lastTBind;                     ///< Last texturing binding stage.
    EGWuint _texEnv;                        ///< Texture fragmentation environment.
    egwValidater* _tSync;                   ///< Texturing binding sync (retained).
    
    egwMatrix44f _wcsTrans;                 ///< Orientation transform (LCS->WCS).
    egwMatrix44f _lcsTrans;                 ///< Offset transform (MMCS->LCS).
    id<egwPBounding> _wcsRBVol;             ///< Optical volume (WCS, retained).
    id<egwPInterpolator> _wcsIpo;           ///< Orientation driver interpolator (retained).
    id<egwPInterpolator> _lcsIpo;           ///< Offset driver interpolator (retained).
    
    const egwSurfaceFraming* _sFrames;      ///< Surface frames (aliased).
    EGWuint const * const * _texIDs;        ///< Texture identifiers (aliased).
    const egwMatrix44f* _mcsTrans;          ///< Base offset transform (MCS->MMCS, aliased).
    const egwSQVAMesh4f* _pMesh;            ///< Pager mesh data (MCS, aliased).
    const EGWuint* _baseGeoAID;             ///< Base geometry buffer arrays identifier (aliased).
}

/// Designated Initializer.
/// Initializes the pager asset with provided settings.
/// @note Non-power-of-two surfaces may be used, but will be smudge extended to a power-of-two surface.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] surface Pager surface data (contents ownership transfer).
/// @param [in] width Pager widget width (may be 0 for surface derivation, MCS).
/// @param [in] height Pager widget height (may be 0 for surface derivation, MCS).
/// @param [in] pages Total page count.
/// @param [in] instStorage Instance geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] baseStorage Base geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] environment Texture fragmentation environment setting (EGW_TEXTURE_FENV_*).
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent pagerSurface:(egwSurface*)surface pagerWidth:(EGWuint16)width pagerHeight:(EGWuint16)height totalPages:(EGWuint)pages instanceGeometryStorage:(EGWuint)instStorage baseGeometryStorage:(EGWuint)baseStorage textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack;

/// Blank Pager Initializer.
/// Initializes the pager asset as a blank surface with provided settings.
/// @note Non-power-of-two surfaces may be used, but will be smudge extended to a power-of-two surface.
/// @note This method does not clear/set-to-zero the allocated surface prior to return.
/// @note Once surface is prepared, one should invalidate the texture buffer sync to start the buffering sequence.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] format Pager surface format (EGW_SURFACE_FRMT_*). May be 0 (for EGW_SURFACE_FRMT_R8G8B8A8).
/// @param [in] width Pager widget width (MCS).
/// @param [in] height Pager widget height (MCS).
/// @param [in] pages Total page count.
/// @param [in] instStorage Instance geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] baseStorage Base geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] environment Texture fragmentation environment setting (EGW_TEXTURE_FENV_*).
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @return Self upon success, otherwise nil.
- (id)initBlankWithIdentity:(NSString*)assetIdent surfaceFormat:(EGWuint32)format pagerWidth:(EGWuint16)width pagerHeight:(EGWuint16)height totalPages:(EGWuint)pages instanceGeometryStorage:(EGWuint)instStorage baseGeometryStorage:(EGWuint)baseStorage textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack;

/// Loaded Pager Initializer.
/// Initializes the pager asset from a loaded surface with provided settings.
/// @note Non-power-of-two surfaces may be used, but will be smudge extended to a power-of-two surface.
/// @param [in] resourceFile Resource file to load from.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] width Pager widget width (may be 0 for surface derivation, MCS).
/// @param [in] height Pager widget height (may be 0 for surface derivation, MCS).
/// @param [in] pages Total page count.
/// @param [in] instStorage Instance geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] baseStorage Base geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] environment Texture fragmentation environment setting (EGW_TEXTURE_FENV_*).
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @return Self upon success, otherwise nil.
- (id)initLoadedFromResourceFile:(NSString*)resourceFile withIdentity:(NSString*)assetIdent pagerWidth:(EGWuint16)width pagerHeight:(EGWuint16)height totalPages:(EGWuint)pages instanceGeometryStorage:(EGWuint)instStorage baseGeometryStorage:(EGWuint)baseStorage textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack;

/// Copy Initializer.
/// Copies an pager asset with provided unique settings.
/// @param [in] widget Widget to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPWidget>)widget withIdentity:(NSString*)assetIdent;


/// Active Page Accessor.
/// Returns the widget's active page.
/// @return Active page index. May be 0 (for none).
- (EGWuint)activePage;

/// Total Pages Accessor.
/// Returns the widget's total page pages.
/// @return Total page pages.
- (EGWuint)totalPages;

/// Delegate Mutator.
/// Sets the widget's event responder delegate to @a delegate.
/// @param [in] delegate Event responder delegate (retained).
- (void)setDelegate:(id<egwDPagerEvent>)delegate;

/// Active Page Mutator.
/// Sets the widget's active page to provided @a actvPage index.
/// @param [in] actvPage Active page (one-indexed). May be 0 (for none).
- (void)setActivePage:(EGWuint)actvPage;

/// Total Pages Mutuator.
/// Sets the widget's maximum page count to provided @a pages.
/// @param [in] pages Total page count.
- (void)setTotalPages:(EGWuint)pages;

@end

/// @}

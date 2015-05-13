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

/// @defgroup geWizES_gui_slider egwSlider
/// @ingroup geWizES_gui
/// Slider Widget.
/// @{

/// @file egwSlider.h
/// Slider Widget Interface.

#import "egwGuiTypes.h"
#import "../inf/egwPAsset.h"
#import "../inf/egwPAssetBase.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPSubTask.h"
#import "../inf/egwPGfxContext.h"
#import "../inf/egwPHook.h"
#import "../inf/egwPWidget.h"
#import "../sys/egwSysTypes.h"
#import "../math/egwMathTypes.h"
#import "../gfx/egwGfxTypes.h"
#import "../geo/egwGeoTypes.h"
#import "../obj/egwObjTypes.h"
#import "../gui/egwImage.h"
#import "../misc/egwMiscTypes.h"


#define EGW_SLIDER_HOOKFACTOR       0.25f   ///< Hooking distance factor (i.e. distance from slider to picking ray based as percentage of length of slider track line) required to hook slider.
#define EGW_SLIDER_EDGEFACTOR   0.01953125f ///< Edge distance factor (i.e. distance from slider to edge based as percentage of length of slider track line) cutoff.
#define EGW_SLIDER_BVOLSCALE        1.35f   ///< Bounding volume extension scaling factor (to make hooking easier).


/// Slider Widget.
/// Contains unique instance data relating to a simple 2-D slider capable of being hooked, oriented, & rendered (both 2D & 3D).
@interface egwSlider : NSObject <egwPAsset, egwPHook, egwPSubTask, egwPWidget, egwDValidationEvent> {
    egwSliderBase* _base;                   ///< Base object instance (retained).
    NSString* _ident;                       ///< Unique identity (retained).
    BOOL _invkParent;                       ///< Parent invocation tracking.
    BOOL _ortPending;                       ///< Orientation transforms pending.
    BOOL _isRendering;                      ///< Tracks rendering status.
    id<egwPObjectBranch> _parent;           ///< Parent node (weak).
    id<egwDSliderEvent> _delegate;          ///< Event responder delegate (retained).
    
    EGWuint32 _rFlags;                      ///< Rendering flags.
    EGWuint16 _rFrame;                      ///< Rendering frame number.
    egwValidater* _rSync;                   ///< Rendering order sync (retained).
    egwLightStack* _lStack;                 ///< Light illumination stack (retained).
    egwMaterialStack* _mStack;              ///< Material rendering stack (retained).
    
    BOOL _isEnabled;                        ///< Tracks event responders status.
    BOOL _isVisible;                        ///< Tracks visibility status.
    BOOL _isPressed;                        ///< Tracks pressed status.
    BOOL _isHooked;                         ///< Tracks hooking status.
    egwLine4f _wcsTrack;                    ///< Slider track line (WCS).
    EGWsingle _tOffset;                     ///< Slider track offset [0,1].
    EGWsingle _trOffset;                    ///< Slider track render offset [EDGE,1-EDGE].
    struct {
        egwVector3f tfvCoords[4];           ///< Slider (filled) track vertex coordinates (MCS).
        egwVector2f tftCoords[4];           ///< Slider (filled) track texture coordinates (MCS).
        egwVector3f tuvCoords[4];           ///< Slider (unfilled) track vertex coordinates (MCS).
        egwVector2f tutCoords[4];           ///< Slider (unfilled) track texture coordinates (MCS).
        egwVector2f btCoords[4];            ///< Slider button texture coordinates (MCS).
    } _isMesh;                              ///< Sprite instance mesh data (MCS).
    
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
    
    const EGWuint* _texID;                  ///< Texture identifier (aliased).
    const egwMatrix44f* _mcsTrans;          ///< Base offset transform (MCS->MMCS, aliased).
    const egwSQVAMesh4f* _stMesh;           ///< Slider track mesh data (MCS, aliased).
    const egwSQVAMesh4f* _sbMesh;           ///< Slider button mesh data (MCS, aliased).
    const egwLine4f* _mmcsTrack;            ///< Slider track line (MMCS, aliased).
    const EGWuint* _baseGeoAID;             ///< Base geometry buffer arrays identifier (aliased).
}

/// Designated Initializer.
/// Initializes the slider asset with provided settings.
/// @note Non-power-of-two surfaces may be used, but will be smudge extended to a power-of-two surface.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] surface Slider surface data (contents ownership transfer).
/// @param [in] trckWidth Slider widget track width (MCS).
/// @param [in] trckHeight Slider widget track height (MCS).
/// @param [in] btnWidth Slider widget button width (MCS).
/// @param [in] btnHeight Slider widget button height (MCS).
/// @param [in] instStorage Instance geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] baseStorage Base geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] environment Texture fragmentation environment setting (EGW_TEXTURE_FENV_*).
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent sliderSurface:(egwSurface*)surface sliderTrackWidth:(EGWuint16)trckWidth sliderTrackHeight:(EGWuint16)trckHeight sliderButtonWidth:(EGWuint16)btnWidth sliderButtonHeight:(EGWuint16)btnHeight instanceGeometryStorage:(EGWuint)instStorage baseGeometryStorage:(EGWuint)baseStorage textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack;

/// Blank Slider Initializer.
/// Initializes the slider asset as a blank surface with provided settings.
/// @note Non-power-of-two surfaces may be used, but will be smudge extended to a power-of-two surface.
/// @note This method does not clear/set-to-zerzo the allocated surface prior to return.
/// @note Once surface is prepared, one should invalidate the texture buffer sync to start the buffering sequence.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] format Slider surface format (EGW_SURFACE_FRMT_*). May be 0 (for EGW_SURFACE_FRMT_R8G8B8A8).
/// @param [in] trckWidth Slider widget track width (MCS).
/// @param [in] trckHeight Slider widget track height (MCS).
/// @param [in] btnWidth Slider widget button width (MCS).
/// @param [in] btnHeight Slider widget button height (MCS).
/// @param [in] instStorage Instance geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] baseStorage Base geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] environment Texture fragmentation environment setting (EGW_TEXTURE_FENV_*).
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @return Self upon success, otherwise nil.
- (id)initBlankWithIdentity:(NSString*)assetIdent surfaceFormat:(EGWuint32)format sliderTrackWidth:(EGWuint16)trckWidth sliderTrackHeight:(EGWuint16)trckHeight sliderButtonWidth:(EGWuint16)btnWidth sliderButtonHeight:(EGWuint16)btnHeight instanceGeometryStorage:(EGWuint)instStorage baseGeometryStorage:(EGWuint)baseStorage textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack;

/// Loaded Slider Initializer.
/// Initializes the slider asset from a loaded surface with provided settings.
/// @note Non-power-of-two surfaces may be used, but will be smudge extended to a power-of-two surface.
/// @param [in] resourceFile Resource file to load from.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] trckWidth Slider widget track width (MCS).
/// @param [in] trckHeight Slider widget track height (MCS).
/// @param [in] btnWidth Slider widget button width (MCS).
/// @param [in] btnHeight Slider widget button height (MCS).
/// @param [in] instStorage Instance geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] baseStorage Base geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] environment Texture fragmentation environment setting (EGW_TEXTURE_FENV_*).
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @return Self upon success, otherwise nil.
- (id)initLoadedFromResourceFile:(NSString*)resourceFile withIdentity:(NSString*)assetIdent sliderTrackWidth:(EGWuint16)trckWidth sliderTrackHeight:(EGWuint16)trckHeight sliderButtonWidth:(EGWuint16)btnWidth sliderButtonHeight:(EGWuint16)btnHeight instanceGeometryStorage:(EGWuint)instStorage baseGeometryStorage:(EGWuint)baseStorage textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack;

/// Copy Initializer.
/// Copies an slider asset with provided unique settings.
/// @param [in] widget Widget to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPWidget>)widget withIdentity:(NSString*)assetIdent;


/// Delegate Mutator.
/// Sets the widget's event responder delegate to @a delegate.
/// @param [in] delegate Event responder delegate (retained).
- (void)setDelegate:(id<egwDSliderEvent>)delegate;


/// Slider Offset Accessor.
/// Returns the widget's slider offset.
/// @return Slider offset [0,1].
- (EGWsingle)sliderOffset;

/// Slider Track Line Accessor,
/// Returns the widget's slider WCS track line.
/// @return Slider track line (WCS).
- (const egwLine4f*)sliderTrackLine;


/// Pressed Status Mutator.
/// Sets the widget's pressed-in status to provided @a status flag.
/// @param [in] status Pressed-in status.
- (void)setPressed:(BOOL)status;

/// Slider Offset Mutator.
/// Sets the widget's slider @a offset.
/// @param [in] offset Slider offset [0,1].
- (void)setSliderOffset:(EGWsingle)offset;

@end


/// Slider Widget Base.
/// Contains shared instance data relating to a simple 2-D slider capable of being hooked, oriented, & rendered (both 2D & 3D).
@interface egwSliderBase : egwImageBase {
    egwSize2i _stSize;                      ///< Slider track size (MCS).
    egwSize2i _sbSize;                      ///< Slider button size (MCS).
    struct {
        egwSQVAMesh4f tMesh;                ///< Slider track mesh data (MCS).
        egwSQVAMesh4f bMesh;                ///< Slider button mesh data (MCS).
    } _sMesh;                               ///< Sprite base mesh data (MCS.
    egwLine4f _mmcsTrack;                   ///< Slider track line (MMCS).
}

/// Designated Initializer.
/// Initializes the slider asset base with provided settings.
/// @note Non-power-of-two surfaces may be used, but will be smudge extended to a power-of-two surface.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] surface Slider surface data (contents ownership transfer).
/// @param [in] trckWidth Slider widget track width (MCS).
/// @param [in] trckHeight Slider widget track height (MCS).
/// @param [in] btnWidth Slider widget button width (MCS).
/// @param [in] btnHeight Slider widget button height (MCS).
/// @param [in] storage Base geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent sliderSurface:(egwSurface*)surface sliderTrackWidth:(EGWuint16)trckWidth sliderTrackHeight:(EGWuint16)trckHeight sliderButtonWidth:(EGWuint16)btnWidth sliderButtonHeight:(EGWuint16)btnHeight geometryStorage:(EGWuint)storage texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter;

/// Blank Slider Initializer.
/// Initializes the slider asset base as a blank surface with provided settings.
/// @note Non-power-of-two surfaces may be used, but will be smudge extended to a power-of-two surface.
/// @note This method does not clear/set-to-zero the allocated surface prior to return.
/// @note Once surface is prepared, one should invalidate the texturing sync to start the buffering sequence.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] format Slider surface format (EGW_SURFACE_FRMT_*). May be 0 (for EGW_SURFACE_FRMT_R8G8B8A8).
/// @param [in] trckWidth Slider widget track width (MCS).
/// @param [in] trckHeight Slider widget track height (MCS).
/// @param [in] btnWidth Slider widget button width (MCS).
/// @param [in] btnHeight Slider widget button height (MCS).
/// @param [in] storage Base geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @return Self upon success, otherwise nil.
- (id)initBlankWithIdentity:(NSString*)assetIdent surfaceFormat:(EGWuint32)format sliderTrackWidth:(EGWuint16)trckWidth sliderTrackHeight:(EGWuint16)trckHeight sliderButtonWidth:(EGWuint16)btnWidth sliderButtonHeight:(EGWuint16)btnHeight geometryStorage:(EGWuint)storage texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter;


/// Slider Button Mesh Accessor.
/// Returns the widget's base slider MCS button mesh data.
/// @return Slider button mesh data (MCS).
- (const egwSQVAMesh4f*)sliderButtonMesh;

/// Slider Button Size Accessor.
/// Returns the widget's base slider MCS button size.
/// @return Slider button size (MCS).
- (const egwSize2i*)sliderButtonSize;

/// Slider Track Mesh Accessor.
/// Returns the widget's base slider MCS track mesh data.
/// @return Slider track mesh data (MCS).
- (const egwSQVAMesh4f*)sliderTrackMesh;

/// Slider Track Size Accessor.
/// Returns the widget's base slider MCS track size.
/// @return Slider track size (MCS).
- (const egwSize2i*)sliderTrackSize;

/// Slider Track Line Accessor,
/// Returns the widget's base slider MMCS track line.
/// @return Slider track line (MMCS).
- (const egwLine4f*)sliderTrackLine;

@end

/// @}

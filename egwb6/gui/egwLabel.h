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

/// @defgroup geWizES_gui_label egwLabel
/// @ingroup geWizES_gui
/// Label Widget.
/// @{

/// @file egwLabel.h
/// Label Widget Interface.

#import "egwGuiTypes.h"
#import "../inf/egwPAsset.h"
#import "../inf/egwPAssetBase.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPSubTask.h"
#import "../inf/egwPGfxContext.h"
#import "../inf/egwPHook.h"
#import "../inf/egwPFont.h"
#import "../inf/egwPWidget.h"
#import "../sys/egwSysTypes.h"
#import "../math/egwMathTypes.h"
#import "../gfx/egwGfxTypes.h"
#import "../obj/egwObjTypes.h"
#import "../misc/egwMiscTypes.h"


/// Label Widget.
/// Provides a basic graphical text string capable of being oriented & rendered (both 2D & 3D).
@interface egwLabel : NSObject <egwPAsset, egwPSubTask, egwPWidget, egwDValidationEvent> {
    NSString* _ident;                       ///< Unique identity (retained).
    BOOL _invkParent;                       ///< Parent invocation tracking.
    BOOL _ortPending;                       ///< Orientation transforms pending.
    BOOL _isRendering;                      ///< Tracks rendering status.
    id<egwPObjectBranch> _parent;           ///< Parent node (weak).
    id<egwDWidgetEvent> _delegate;          ///< Event responder delegate (retained).
    
    EGWuint32 _rFlags;                      ///< Rendering flags.
    EGWuint16 _rFrame;                      ///< Rendering frame number.
    egwValidater* _rSync;                   ///< Rendering order sync (retained).
    egwLightStack* _lStack;                 ///< Light illumination stack (retained).
    egwMaterialStack* _mStack;              ///< Material rendering stack (retained).
    egwShaderStack* _sStack;                ///< Shader program stack (retained).
    
    BOOL _isEnabled;                        ///< Tracks event responders status.
    BOOL _isVisible;                        ///< Tracks visibility status.
    NSString* _exstText;                    ///< Existing (rendered) text string (retained).
    egwSize2i _exstSize;                    ///< Existing (rendered) text string size.
    NSString* _nextText;                    ///< Next (to-be-rendered) text string (retained).
    id<egwPFont> _lFont;                    ///< Rendering font (retained).
    egwSurface _lSrfc;                      ///< Rendered text surface (MCS).
    egwSQVAMesh4f _lMesh;                   ///< Label text mesh data (MCS).
    
    egwValidater* _gbSync;                  ///< Geometry buffer sync (retained).
    EGWuint _geoAID;                        ///< Geometry buffer arrays identifier.
    EGWuint _geoStrg;                       ///< Geometry storage.
    
    BOOL _isTBound;                         ///< Texturing binding status.
    BOOL _isTBoundable;                     ///< Texturing bindable status.
    BOOL _isTDPersist;                      ///< Tracks surface persistence status.
    egwValidater* _tbSync;                  ///< Texture buffer sync (retained).
    EGWuint _lastTBind;                     ///< Last texturing binding stage.
    EGWuint _texEnv;                        ///< Texture fragmentation environment.
    EGWuint _texID;                         ///< Texture identifier.
    EGWuint _texTrans;                      ///< Texturing transforms.
    EGWuint _texFltr;                       ///< Texturing filter.
    egwValidater* _tSync;                   ///< Texturing binding sync (retained).
    
    egwMatrix44f _wcsTrans;                 ///< Orientation transform (LCS->WCS).
    egwMatrix44f _lcsTrans;                 ///< Offset transform (MMCS->LCS).
    egwMatrix44f _mcsTrans;                 ///< Base offset transform (MCS->MMCS).
    id<egwPBounding> _mmcsRBVol;            ///< Optical volume (MMCS, retained).
    id<egwPBounding> _wcsRBVol;             ///< Optical volume (WCS, retained).
    id<egwPInterpolator> _wcsIpo;           ///< Orientation driver interpolator (retained).
    id<egwPInterpolator> _lcsIpo;           ///< Offset driver interpolator (retained).
}

/// Designated Initializer.
/// Initializes the label asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] format Label surface format (EGW_SURFACE_FRMT_*). May be 0 (for EGW_SURFACE_FRMT_R8G8B8A8).
/// @param [in] text Initial label text (retained). May be nil (for blank).
/// @param [in] font Rendering font (retained).
/// @param [in] storage Geometry storage/VBO setting (EGW_GEOMETRY_STRG_*).
/// @param [in] environment Texture fragmentation environment setting (EGW_TEXTURE_FENV_*).
/// @param [in] transforms Texture surface load transformations (EGW_TEXTURE_TRFM_*).
/// @param [in] filter Texturing filter setting (EGW_TEXTURE_FLTR_*).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @param [in] shdrStack Associated shader stack (retained). May be nil (uses default).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent surfaceFormat:(EGWuint32)format labelText:(NSString*)text renderingFont:(id<egwPFont>)font geometryStorage:(EGWuint)storage textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack shaderStack:(egwShaderStack*)shdrStack;

/// Copy Initializer.
/// Copies a label asset with provided unique settings.
/// @param [in] widget Widget to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPWidget>)widget withIdentity:(NSString*)assetIdent;


/// Base Offset (byTransform) Method.
/// Offsets the widget's base data in the MCS by the provided @a transform for subsequent render passes.
/// @param [in] transform MCS->MMCS transformation matrix.
- (void)baseOffsetByTransform:(const egwMatrix44f*)transform;

/// Base Offset (byZeroAlign) Method.
/// Offsets the widget's base data in the MCS by the provided @a zfAlign axis extents edges for subsequent render passes.
/// @param [in] zfAlign Zero offset alignment mode (EGW_GFXOBJ_ZFALIGN_*)
- (void)baseOffsetByZeroAlign:(EGWuint)zfAlign;


/// Label Text Accessor.
/// Returns the current label text string.
/// @return Label text.
- (NSString*)labelText;

/// MCS->MMCS Transform Accessor.
/// Returns the object's MCS->MMCS transformation matrix.
/// @return MCS->MMCS transform.
- (const egwMatrix44f*)mcsTransform;

/// Rendering Font Accessor.
/// Returns the current rendering font object.
/// @return Rendering font.
- (id<egwPFont>)renderingFont;

/// Surface Format Accessor.
/// Returns the current surface format identifier.
/// @return Surface format.
- (EGWuint32)surfaceFormat;


/// Delegate Mutator.
/// Sets the widget's event responder delegate to @a delegate.
/// @param [in] delegate Event responder delegate (retained).
- (void)setDelegate:(id<egwDWidgetEvent>)delegate;

/// Label Text Mutator.
/// Sets the current label text string to provided @a text string.
/// @param [in] text C-style text string. May be NULL (for blank).
- (void)setLabelString:(const EGWchar*)text;

/// Label Text Mutator.
/// Sets the current label text string to provided @a text string.
/// @param [in] text Label text (retained). May be nil (for blank).
- (void)setLabelText:(NSString*)text;

/// Rendering Font Mutator.
/// Sets the current rendering font to provided @a font object.
/// @param [in] font Rendering font (retained).
- (void)setRenderingFont:(id<egwPFont>)font;

@end

/// @}

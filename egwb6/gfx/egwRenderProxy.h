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

/// @defgroup geWizES_gfx_renderproxy egwRenderProxy
/// @ingroup geWizES_gfx
/// Renderable Proxy Asset.
/// @{

/// @file egwRenderProxy.h
/// Renderable Proxy Interface.

#import "egwGfxTypes.h"
#import "../inf/egwPAsset.h"
#import "../inf/egwPAssetBase.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPGfxContext.h"
#import "../inf/egwPObjLeaf.h"
#import "../inf/egwPRenderable.h"
#import "../misc/egwMiscTypes.h"


/// Renderable Proxy Asset.
/// Provides a basic proxy element that passes rendering calls to be handled by a delegate object.
@interface egwRenderProxy : NSObject <egwPAsset, egwPObjectLeaf, egwPRenderable, egwDValidationEvent> {
    NSString* _ident;                       ///< Unique identity (retained).
    BOOL _invkParent;                       ///< Parent invocation tracking.
    BOOL _ortPending;                       ///< Orientation transforms pending.
    BOOL _isRendering;                      ///< Tracks rendering status.
    id<egwPObjectBranch> _parent;           ///< Parent node (weak).
    
    id<egwDRenderProxyEvent> _delegate;          ///< Delegate object (retained).
    id (*_fpRender)(id, SEL, EGWuint32);    ///< IMP function pointer to renderWithFlags method.
    
    EGWuint32 _rFlags;                      ///< Rendering flags.
    EGWuint16 _rFrame;                      ///< Rendering frame number.
    egwValidater* _rSync;                   ///< Rendering order sync (retained).
    egwLightStack* _lStack;                 ///< Light illumination stack (retained).
    egwMaterialStack* _mStack;              ///< Material rendering stack (retained).
    egwShaderStack* _sStack;                ///< Shader program stack (retained).
    egwTextureStack* _tStack;               ///< Texture mapping stack (retained).
    
    id<egwPBounding> _wcsRBVol;             ///< Optical volume (WCS, retained).
}

/// Designated Initializer.
/// Initializes the renderable proxy asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] wcsRBVolume Optical volume (WCS, retained).
/// @param [in] lghtStack Associated light stack (retained). May be nil (creates unique).
/// @param [in] mtrlStack Associated material stack (retained). May be nil (uses default).
/// @param [in] shdrStack Associated shader stack (retained). May be nil (uses default).
/// @param [in] txtrStack Associated texture stack (retained). May be nil (for non-textured).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent renderingVolume:(id<egwPBounding>)wcsRBVolume lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack shaderStack:(egwShaderStack*)shdrStack textureStack:(egwTextureStack*)txtrStack;

/// Copy Initializer.
/// Copies a renderable proxy asset with provided unique settings.
/// @param [in] asset Asset to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent;


/// Delegate Mutator.
/// Sets the proxy's event responder delegate to @a delegate.
/// @param [in] delegate Event responder delegate (retained).
- (void)setDelegate:(id<egwDRenderProxyEvent>)delegate;

@end

/// @}

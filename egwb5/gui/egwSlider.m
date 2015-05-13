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

/// @file egwSlider.m
/// @ingroup geWizES_gui_slider
/// Slider Widget Implementation.

#import "egwSlider.h"
#import "../sys/egwSysTypes.h"
#import "../sys/egwAssetManager.h"
#import "../sys/egwGfxContext.h"
#import "../sys/egwGfxContextNSGL.h"  // NOTE: Below code has a dependence on GL.
#import "../sys/egwGfxContextEAGLES.h"
#import "../sys/egwGfxRenderer.h"
#import "../math/egwMath.h"
#import "../math/egwVector.h"
#import "../math/egwMatrix.h"
#import "../gfx/egwBoundings.h"
#import "../gfx/egwBindingStacks.h"
#import "../gfx/egwGraphics.h"
#import "../geo/egwGeometry.h"
#import "../gui/egwInterface.h"
#import "../gui/egwSpritedImage.h"
#import "../obj/egwObjectBranch.h"
#import "../phy/egwInterpolators.h"
#import "../misc/egwValidater.h"


// !!!: ***** egwSlider *****

@implementation egwSlider

static egwTextureJumpTable _egwTJT = { NULL };

+ (id)allocWithZone:(NSZone*)zone {
    NSObject* inst = (NSObject*)[super allocWithZone:zone];
    
    if(!_egwTJT.fpTBind && [inst isMemberOfClass:[egwSlider class]]) {
        _egwTJT.fpTBind = (BOOL(*)(id, SEL, EGWuint, EGWuint))[inst methodForSelector:@selector(bindForTexturingStage:withFlags:)];
        _egwTJT.fpTUnbind = (BOOL(*)(id, SEL, EGWuint))[inst methodForSelector:@selector(unbindTexturingWithFlags:)];
        _egwTJT.fpTBase = (id<NSObject>(*)(id, SEL))[inst methodForSelector:@selector(textureBase)];
        _egwTJT.fpTSync = (egwValidater*(*)(id, SEL))[inst methodForSelector:@selector(texturingSync)];
        _egwTJT.fpTLBStage = (EGWuint(*)(id, SEL))[inst methodForSelector:@selector(lastTexturingBindingStage)];
    }
    
    return (id)inst;
}

- (id)init {
    if([self isMemberOfClass:[egwSlider class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent sliderSurface:(egwSurface*)surface sliderTrackWidth:(EGWuint16)trckWidth sliderTrackHeight:(EGWuint16)trckHeight sliderButtonWidth:(EGWuint16)btnWidth sliderButtonHeight:(EGWuint16)btnHeight instanceGeometryStorage:(EGWuint)instStorage baseGeometryStorage:(EGWuint)baseStorage textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwSliderBase alloc] initWithIdentity:assetIdent sliderSurface:surface sliderTrackWidth:trckWidth sliderTrackHeight:trckHeight sliderButtonWidth:btnWidth sliderButtonHeight:btnHeight geometryStorage:baseStorage texturingTransforms:transforms texturingFilter:filter])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _rFlags = EGW_GFXOBJ_RNDRFLG_DFLT;
    _rFrame = EGW_FRAME_ALWAYSPASS;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = (lghtStack ? [lghtStack retain] : [[egwLightStack alloc] init]))) { [self release]; return (self = nil); }
    if(!(_mStack = (mtrlStack ? [mtrlStack retain] : [[egwSIEngine defaultMaterialStack] retain]))) { [self release]; return (self = nil); }
    
    _isEnabled = _isVisible = YES;
    memcpy((void*)&_wcsTrack, (const void*)[_base sliderTrackLine], sizeof(egwLine4f));
    _tOffset = 0.0f;
    _trOffset = ((_tOffset * (1.0f - (EGW_SLIDER_EDGEFACTOR * 2.0f))) + EGW_SLIDER_EDGEFACTOR);
    
    _geoStrg = instStorage;
    if(!(_gbSync = [[egwValidater alloc] initWithOwner:self validation:(_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES) coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    
    _lastTBind = NSNotFound;
    _texEnv = environment;
    if(!(_tSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    if(!(_wcsRBVol = [(NSObject*)[_base renderingBounding] copy])) { [self release]; return (self = nil); }
    
    _texID = [_base textureID];
    _mcsTrans = [_base mcsTransform];
    _stMesh = [_base sliderTrackMesh];
    _sbMesh = [_base sliderButtonMesh];
    _mmcsTrack = [_base sliderTrackLine];
    _baseGeoAID = [_base geometryArraysID];
    
    // Since image might have to be upscaled to pow2, use tCoords from base to adjust accordingly
    memcpy((void*)&_isMesh.tuvCoords, (const void*)&_stMesh->vCoords, 4 * sizeof(egwVector3f));
    memcpy((void*)&_isMesh.tutCoords, (const void*)&_stMesh->tCoords, 4 * sizeof(egwVector2f));
    memcpy((void*)&_isMesh.tfvCoords, (const void*)&_stMesh->vCoords, 4 * sizeof(egwVector3f));
    memcpy((void*)&_isMesh.tftCoords, (const void*)&_stMesh->tCoords, 4 * sizeof(egwVector2f));
    memcpy((void*)&_isMesh.btCoords, (const void*)&_sbMesh->tCoords, 4 * sizeof(egwVector2f));
    
    _isMesh.tftCoords[2].axis.y = _isMesh.tftCoords[3].axis.y = _stMesh->tCoords[0].axis.y;
    _isMesh.tftCoords[0].axis.y = _isMesh.tftCoords[1].axis.y = _stMesh->tCoords[0].axis.y * 2.0f;
    
    _isMesh.tfvCoords[1].axis.x = _isMesh.tfvCoords[2].axis.x = _isMesh.tuvCoords[0].axis.x = _isMesh.tuvCoords[3].axis.x = egwLerpf(_stMesh->vCoords[0].axis.x, _stMesh->vCoords[1].axis.x, _trOffset);
    _isMesh.tftCoords[1].axis.x = _isMesh.tftCoords[2].axis.x = _isMesh.tutCoords[0].axis.x = _isMesh.tutCoords[3].axis.x = egwLerpf(_stMesh->tCoords[0].axis.x, _stMesh->tCoords[1].axis.x, _trOffset);
    
    _isMesh.btCoords[2].axis.y = _isMesh.btCoords[3].axis.y = (_isPressed ? _sbMesh->tCoords[0].axis.y : 0.0f);
    _isMesh.btCoords[0].axis.y = _isMesh.btCoords[1].axis.y = (_isPressed ? _sbMesh->tCoords[0].axis.y * 2.0f : _sbMesh->tCoords[0].axis.y);
    
    _isMesh.btCoords[0].axis.x = _isMesh.btCoords[3].axis.x = _sbMesh->tCoords[0].axis.x;
    _isMesh.btCoords[1].axis.x = _isMesh.btCoords[2].axis.x = _sbMesh->tCoords[1].axis.x;
    
    if((_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && !([egwAIGfxCntxAGL isActive] && [self performSubTaskForComponent:egwAIGfxCntxAGL forSync:_gbSync])) // Attempt to load, if context active on this thread
        [egwAIGfxCntx addSubTask:self forSync:_gbSync]; // Delayed load for context sub task to handle
    
    return self;
}

- (id)initBlankWithIdentity:(NSString*)assetIdent surfaceFormat:(EGWuint32)format sliderTrackWidth:(EGWuint16)trckWidth sliderTrackHeight:(EGWuint16)trckHeight sliderButtonWidth:(EGWuint16)btnWidth sliderButtonHeight:(EGWuint16)btnHeight instanceGeometryStorage:(EGWuint)instStorage baseGeometryStorage:(EGWuint)baseStorage textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwImageBase alloc] initBlankWithIdentity:assetIdent surfaceFormat:format sliderTrackWidth:trckWidth sliderTrackHeight:trckHeight sliderButtonWidth:btnWidth sliderButtonHeight:btnHeight geometryStorage:baseStorage texturingTransforms:transforms texturingFilter:filter])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _rFlags = EGW_GFXOBJ_RNDRFLG_DFLT;
    _rFrame = EGW_FRAME_ALWAYSPASS;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = (lghtStack ? [lghtStack retain] : [[egwLightStack alloc] init]))) { [self release]; return (self = nil); }
    if(!(_mStack = (mtrlStack ? [mtrlStack retain] : [[egwSIEngine defaultMaterialStack] retain]))) { [self release]; return (self = nil); }
    
    _isEnabled = _isVisible = YES;
    memcpy((void*)&_wcsTrack, (const void*)[_base sliderTrackLine], sizeof(egwLine4f));
    _tOffset = 0.0f;
    _trOffset = ((_tOffset * (1.0f - (EGW_SLIDER_EDGEFACTOR * 2.0f))) + EGW_SLIDER_EDGEFACTOR);
    
    _geoStrg = instStorage;
    if(!(_gbSync = [[egwValidater alloc] initWithOwner:self validation:(_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES) coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    
    _lastTBind = NSNotFound;
    _texEnv = environment;
    if(!(_tSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    if(!(_wcsRBVol = [(NSObject*)[_base renderingBounding] copy])) { [self release]; return (self = nil); }
    
    _texID = [_base textureID];
    _mcsTrans = [_base mcsTransform];
    _stMesh = [_base sliderTrackMesh];
    _sbMesh = [_base sliderButtonMesh];
    _mmcsTrack = [_base sliderTrackLine];
    _baseGeoAID = [_base geometryArraysID];
    
    // Since image might have to be upscaled to pow2, use tCoords from base to adjust accordingly
    memcpy((void*)&_isMesh.tuvCoords, (const void*)&_stMesh->vCoords, 4 * sizeof(egwVector3f));
    memcpy((void*)&_isMesh.tutCoords, (const void*)&_stMesh->tCoords, 4 * sizeof(egwVector2f));
    memcpy((void*)&_isMesh.tfvCoords, (const void*)&_stMesh->vCoords, 4 * sizeof(egwVector3f));
    memcpy((void*)&_isMesh.tftCoords, (const void*)&_stMesh->tCoords, 4 * sizeof(egwVector2f));
    memcpy((void*)&_isMesh.btCoords, (const void*)&_sbMesh->tCoords, 4 * sizeof(egwVector2f));
    
    _isMesh.tftCoords[2].axis.y = _isMesh.tftCoords[3].axis.y = _stMesh->tCoords[0].axis.y;
    _isMesh.tftCoords[0].axis.y = _isMesh.tftCoords[1].axis.y = _stMesh->tCoords[0].axis.y * 2.0f;
    
    _isMesh.tfvCoords[1].axis.x = _isMesh.tfvCoords[2].axis.x = _isMesh.tuvCoords[0].axis.x = _isMesh.tuvCoords[3].axis.x = egwLerpf(_stMesh->vCoords[0].axis.x, _stMesh->vCoords[1].axis.x, _trOffset);
    _isMesh.tftCoords[1].axis.x = _isMesh.tftCoords[2].axis.x = _isMesh.tutCoords[0].axis.x = _isMesh.tutCoords[3].axis.x = egwLerpf(_stMesh->tCoords[0].axis.x, _stMesh->tCoords[1].axis.x, _trOffset);
    
    _isMesh.btCoords[2].axis.y = _isMesh.btCoords[3].axis.y = (_isPressed ? _sbMesh->tCoords[0].axis.y : 0.0f);
    _isMesh.btCoords[0].axis.y = _isMesh.btCoords[1].axis.y = (_isPressed ? _sbMesh->tCoords[0].axis.y * 2.0f : _sbMesh->tCoords[0].axis.y);
    
    _isMesh.btCoords[0].axis.x = _isMesh.btCoords[3].axis.x = _sbMesh->tCoords[0].axis.x;
    _isMesh.btCoords[1].axis.x = _isMesh.btCoords[2].axis.x = _sbMesh->tCoords[1].axis.x;
    
    if((_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && !([egwAIGfxCntxAGL isActive] && [self performSubTaskForComponent:egwAIGfxCntxAGL forSync:_gbSync])) // Attempt to load, if context active on this thread
        [egwAIGfxCntx addSubTask:self forSync:_gbSync]; // Delayed load for context sub task to handle
    
    // NOTE: Delayed load will occur on buffer sync invalidation. -jw
    
    return self;
}

- (id)initLoadedFromResourceFile:(NSString*)resourceFile withIdentity:(NSString*)assetIdent sliderTrackWidth:(EGWuint16)trckWidth sliderTrackHeight:(EGWuint16)trckHeight sliderButtonWidth:(EGWuint16)btnWidth sliderButtonHeight:(EGWuint16)btnHeight instanceGeometryStorage:(EGWuint)instStorage baseGeometryStorage:(EGWuint)baseStorage textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack {
    egwSurface surface; memset((void*)&surface, 0, sizeof(egwSurface));
    
    if(!([egwSIAsstMngr loadSurface:&surface fromFile:resourceFile withTransforms:(transforms & ~EGW_SURFACE_TRFM_ENSRPOW2)])) {
        if(surface.data) egwSrfcFree(&surface);
        [self release]; return (self = nil);
    }
    
    if(!(self = [self initWithIdentity:assetIdent sliderSurface:&surface sliderTrackWidth:trckWidth sliderTrackHeight:trckHeight sliderButtonWidth:btnWidth sliderButtonHeight:btnHeight instanceGeometryStorage:instStorage baseGeometryStorage:baseStorage textureEnvironment:environment texturingTransforms:(transforms | EGW_SURFACE_TRFM_ENSRPOW2) texturingFilter:filter lightStack:lghtStack materialStack:mtrlStack])) {
        if(surface.data) egwSrfcFree(&surface);
        return nil;
    }
    
    return self;
}

- (id)initCopyOf:(id<egwPWidget>)widget withIdentity:(NSString*)assetIdent {
    if(!([widget isKindOfClass:[self class]]) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = (egwSliderBase*)[[(egwSlider*)widget assetBase] retain])) { [self release]; return (self = nil); }
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _rFlags = [(egwSlider*)widget renderingFlags];
    _rFrame = EGW_FRAME_ALWAYSPASS;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = [[widget lightStack] retain])) { [self release]; return (self = nil); }
    if(!(_mStack = [[widget materialStack] retain])) { [self release]; return (self = nil); }
    
    _isEnabled = [widget isEnabled];
    _isVisible = [widget isVisible];
    memcpy((void*)&_wcsTrack, (const void*)[(egwSlider*)widget sliderTrackLine], sizeof(egwLine4f));
    _tOffset = [(egwSlider*)widget sliderOffset];
    _trOffset = ((_tOffset * (1.0f - (EGW_SLIDER_EDGEFACTOR * 2.0f))) + EGW_SLIDER_EDGEFACTOR);
    
    _geoStrg = [(egwSlider*)widget geometryStorage];
    if(!(_gbSync = [[egwValidater alloc] initWithOwner:self validation:(_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES) coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    
    _lastTBind = NSNotFound;
    _texEnv = [widget textureEnvironment];
    if(!(_tSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    
    egwMatCopy44f([(egwSlider*)widget wcsTransform], &_wcsTrans);
    egwMatCopy44f([(egwSlider*)widget lcsTransform], &_lcsTrans);
    if(!(_wcsRBVol = [(NSObject*)[(egwSlider*)widget renderingBounding] copy])) { [self release]; return (self = nil); }
    if([(id<egwPOrientated>)widget offsetDriver] && ![self trySetOffsetDriver:[(id<egwPOrientated>)widget offsetDriver]]) { [self release]; return (self = nil); }
    if([(id<egwPOrientated>)widget orientateDriver] && ![self trySetOrientateDriver:[(id<egwPOrientated>)widget orientateDriver]]) { [self release]; return (self = nil); }
    
    _texID = [_base textureID];
    _mcsTrans = [_base mcsTransform];
    _stMesh = [_base sliderTrackMesh];
    _sbMesh = [_base sliderButtonMesh];
    _mmcsTrack = [_base sliderTrackLine];
    _baseGeoAID = [_base geometryArraysID];
    
    // Since image might have to be upscaled to pow2, use tCoords from base to adjust accordingly
    memcpy((void*)&_isMesh.tuvCoords, (const void*)&_stMesh->vCoords, 4 * sizeof(egwVector3f));
    memcpy((void*)&_isMesh.tutCoords, (const void*)&_stMesh->tCoords, 4 * sizeof(egwVector2f));
    memcpy((void*)&_isMesh.tfvCoords, (const void*)&_stMesh->vCoords, 4 * sizeof(egwVector3f));
    memcpy((void*)&_isMesh.tftCoords, (const void*)&_stMesh->tCoords, 4 * sizeof(egwVector2f));
    memcpy((void*)&_isMesh.btCoords, (const void*)&_sbMesh->tCoords, 4 * sizeof(egwVector2f));
    
    _isMesh.tftCoords[2].axis.y = _isMesh.tftCoords[3].axis.y = _stMesh->tCoords[0].axis.y;
    _isMesh.tftCoords[0].axis.y = _isMesh.tftCoords[1].axis.y = _stMesh->tCoords[0].axis.y * 2.0f;
    
    _isMesh.tfvCoords[1].axis.x = _isMesh.tfvCoords[2].axis.x = _isMesh.tuvCoords[0].axis.x = _isMesh.tuvCoords[3].axis.x = egwLerpf(_stMesh->vCoords[0].axis.x, _stMesh->vCoords[1].axis.x, _trOffset);
    _isMesh.tftCoords[1].axis.x = _isMesh.tftCoords[2].axis.x = _isMesh.tutCoords[0].axis.x = _isMesh.tutCoords[3].axis.x = egwLerpf(_stMesh->tCoords[0].axis.x, _stMesh->tCoords[1].axis.x, _trOffset);
    
    _isMesh.btCoords[2].axis.y = _isMesh.btCoords[3].axis.y = (_isPressed ? _sbMesh->tCoords[0].axis.y : 0.0f);
    _isMesh.btCoords[0].axis.y = _isMesh.btCoords[1].axis.y = (_isPressed ? _sbMesh->tCoords[0].axis.y * 2.0f : _sbMesh->tCoords[0].axis.y);
    
    _isMesh.btCoords[0].axis.x = _isMesh.btCoords[3].axis.x = _sbMesh->tCoords[0].axis.x;
    _isMesh.btCoords[1].axis.x = _isMesh.btCoords[2].axis.x = _sbMesh->tCoords[1].axis.x;
    
    if((_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && !([egwAIGfxCntxAGL isActive] && [self performSubTaskForComponent:egwAIGfxCntxAGL forSync:_gbSync])) // Attempt to load, if context active on this thread
        [egwAIGfxCntx addSubTask:self forSync:_gbSync]; // Delayed load for context sub task to handle
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwSlider* copy = nil;
    NSString* copyIdent = nil;
    
    if([_ident hasSuffix:@"_default"])
        copyIdent = [[NSString alloc] initWithFormat:@"%@_%d", [_base identity], [_base nextInstanceIndex]];
    else copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwSlider allocWithZone:zone] initCopyOf:self
                                              withIdentity:copyIdent])) {
        NSLog(@"egwSlider: copyWithZone: Failure initializing new slider from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    return copy;
}

- (void)dealloc {
    if(_isTBound) [self unbindTexturingWithFlags:EGW_BNDOBJ_BINDFLG_DFLT];
    if(_isHooked) { _isHooked = NO; [_delegate widget:self did:EGW_ACTION_UNHOOK]; }
    if(_geoAID)
        _geoAID = [egwAIGfxCntxAGL returnUsedBufferID:_geoAID];
    
    [_mStack release]; _mStack = nil;
    [_lStack release]; _lStack = nil;
    [_rSync release]; _rSync = nil;
    
    [_wcsRBVol release]; _wcsRBVol = nil;
    
    if(_lcsIpo) { [_lcsIpo removeTargetWithObject:self]; [_lcsIpo release]; _lcsIpo = nil; }
    if(_wcsIpo) { [_wcsIpo removeTargetWithObject:self]; [_wcsIpo release]; _wcsIpo = nil; }
    
    _texID = NULL;
    _mcsTrans = NULL;
    _stMesh = NULL;
    _sbMesh = NULL;
    _mmcsTrack = NULL;
    _baseGeoAID = NULL;
    
    [_tSync release]; _tSync = nil;
    
    [_gbSync release]; _gbSync = nil;
    
    [_delegate release]; _delegate = nil;
    if(_parent) [self setParent:nil];
    [_ident release]; _ident = nil;
    [_base release]; _base = nil;
    
    [super dealloc];
}

- (void)applyOrientation {
    if(_ortPending && !_invkParent) {
        _invkParent = YES;
        
        [(id<egwPOrientated>)_parent applyOrientation]; // NOTE: Because the parent contains self, it will always be an orientated branch line, also parents never call a child's applyOrientation method -jw
        
        egwMatrix44f twcsTrans;
        if(!(_rFlags & EGW_OBJEXTEND_FLG_ALWAYSOTGHMG))
            egwMatMultiply44f(&_wcsTrans, &_lcsTrans, &twcsTrans);
        else
            egwMatMultiplyHmg44f(&_wcsTrans, &_lcsTrans, &twcsTrans);
        
        [_wcsRBVol orientateByTransform:&twcsTrans fromVolume:[_base renderingBounding]];
        egwLineTransform444f(&twcsTrans, _mmcsTrack, &_wcsTrack);
        
        _ortPending = NO;
        
        if((EGW_NODECMPMRG_GRAPHIC & (EGW_CORECMP_TYPE_BVOLS | EGW_CORECMP_TYPE_SOURCES | EGW_CORECMP_TYPE_SYNCS)) &&
           _parent && ![_parent isInvokingChild]) {
            EGWuint cmpntTypes = (((_rFlags & EGW_OBJTREE_FLG_NOUMRGBVOLS) || [_wcsRBVol class] == [egwZeroBounding class]) ? 0 : EGW_CORECMP_TYPE_BVOLS & EGW_NODECMPMRG_GRAPHIC) |
                                   (_rFlags & EGW_OBJTREE_FLG_NOUMRGSYNCS ? 0 : EGW_CORECMP_TYPE_SOURCES & EGW_NODECMPMRG_GRAPHIC) |
                                   (_rFlags & EGW_OBJTREE_FLG_NOUMRGSOURCES ? 0 : EGW_CORECMP_TYPE_SYNCS & EGW_NODECMPMRG_GRAPHIC);
            if(cmpntTypes)
                [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        }
        
        _invkParent = NO;
    }
}

- (BOOL)bindForTexturingStage:(EGWuint)txtrStage withFlags:(EGWuint)flags {
    // NOTE: The code below is non-abstracted OpenGLES dependent. Staying this way till ES2. -jw
    if(!_isTBound || (flags & EGW_BNDOBJ_BINDFLG_APISYNCINVLD) || egwSFPVldtrIsInvalidated(_tSync, @selector(isInvalidated))) {
        GLenum texture = GL_TEXTURE0 + (_lastTBind = txtrStage);
        
        //glActiveTexture(texture);
        egw_glClientActiveTexture(texture);
        
        if(!(flags & EGW_BNDOBJ_BINDFLG_SAMELASTBASE)) {
            if(_texID && *_texID) {
                egw_glBindTexture(texture, GL_TEXTURE_2D, (GLuint)*_texID);
                //glFinish();
            } else return NO;
        }
        
        //if(!_isTBound || (flags & EGW_BNDOBJ_BINDFLG_APISYNCINVLD) || egwSFPVldtrIsInvalidated(_tSync, @selector(isInvalidated)))
            egw_glBindEnvironment(_texEnv);
        
        _isTBound = YES;
        egwSFPVldtrValidate(_tSync, @selector(validate));
        return YES;
    }
    
    return NO;
}

- (BOOL)unbindTexturingWithFlags:(EGWuint)flags {
    // NOTE: The code below is non-abstracted OpenGLES dependent. Staying this way till ES2. -jw
    if(_isTBound) {
        if(flags & EGW_BNDOBJ_BINDFLG_TOGGLE) {
            GLenum texture = GL_TEXTURE0 + _lastTBind;
            //glActiveTexture(texture);
            egw_glClientActiveTexture(texture);
            egw_glBindTexture(texture, GL_TEXTURE_2D, (GLuint)NSNotFound);
            //glFinish();
        }
        
        _isTBound = NO;
        return YES;
    }
    
    return NO;
}

- (void)illuminateWithLight:(id<egwPLight>)light {
    [_lStack addLight:light sortByPosition:(egwVector3f*)[_wcsRBVol boundingOrigin]];
}

- (void)offsetByTransform:(const egwMatrix44f*)lcsTransform {
    egwMatCopy44f(lcsTransform, &_lcsTrans);
    
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (void)orientateByTransform:(const egwMatrix44f*)wcsTransform {
    egwMatCopy44f(wcsTransform, &_wcsTrans);
    
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (void)orientateByImpending {
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (BOOL)performSubTaskForComponent:(id<NSObject>)component forSync:(egwValidater*)sync {
    if((id)component == (id)egwAIGfxCntxAGL) {
        if(_gbSync == sync && (_geoStrg & EGW_GEOMETRY_STRG_EXVBO)) {
            if([egwAIGfxCntxAGL loadBufferArraysID:&_geoAID withRawData:(const EGWbyte*)&_isMesh dataSize:(EGWuint)sizeof(_isMesh) geometryStorage:_geoStrg]) {
                egwSFPVldtrValidate(_gbSync, @selector(validate)); // Event delegate will dealloc if not persistent
                
                return YES; // Done with this item, no other work left
            } else
                NSLog(@"egwSlider: performSubTaskForComponent:forSync: Failure buffering instance geometry mesh for asset '%@' (%p).", _ident, self);
            
            return NO; // Failure to load, try again next time
        }
    }
    
    return YES; // Nothing to do
}

- (void)startRendering {
    [egwSIGfxRdr renderObject:self]; // TODO: Replace with call to world scene.
}

- (void)stopRendering {
    [egwSIGfxRdr removeObject:self]; // TODO: Replace with call to world scene.
}

- (void)renderWithFlags:(EGWuint32)flags {
    // NOTE: The code below is non-abstracted OpenGLES dependent. Staying this way till ES2. -jw
    if(flags & EGW_GFXOBJ_RPLYFLY_DORENDERPASS) {
        if(_isVisible) {
            if(_lStack) egwSFPLghtStckPushAndBindLights(_lStack, @selector(pushAndBindLights));
            else egwAFPGfxCntxBindLights(egwAIGfxCntx, @selector(bindLights));
            if(_mStack) egwSFPMtrlStckPushAndBindMaterials(_mStack, @selector(pushAndBindMaterials));
            else egwAFPGfxCntxBindMaterials(egwAIGfxCntx, @selector(bindMaterials));
            egwAFPGfxCntxPushTexture(egwAIGfxCntx, @selector(pushTexture:), self);
            egwAFPGfxCntxBindTextures(egwAIGfxCntx, @selector(bindTextures));
            
            if(_isTBound) {
                glPushMatrix();
                
                glMultMatrixf((const GLfloat*)&_wcsTrans);
                glMultMatrixf((const GLfloat*)&_lcsTrans);
                glMultMatrixf((const GLfloat*)_mcsTrans);
                
                if(*_baseGeoAID) {
                    egw_glBindBuffer(GL_ARRAY_BUFFER, *_baseGeoAID);
                    
                    glNormalPointer(GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)((EGWuint)sizeof(egwVector3f) * 4));
                } else {
                    egw_glBindBuffer(GL_ARRAY_BUFFER, 0);
                    
                    glNormalPointer(GL_FLOAT, (GLsizei)0, (const GLvoid*)&_stMesh->nCoords[0]);
                }
                
                if(_geoAID) {
                    egw_glBindBuffer(GL_ARRAY_BUFFER, _geoAID);
                    
                    glVertexPointer((GLint)3, GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)0);
                    glTexCoordPointer((GLint)2, GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)((EGWuint)sizeof(egwVector3f) * 4));
                    
                    glDrawArrays(GL_TRIANGLE_FAN, 0, (GLsizei)4);
                    
                    glVertexPointer((GLint)3, GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)((EGWuint)sizeof(egwVector3f) * 4 + (EGWuint)sizeof(egwVector2f) * 4));
                    glTexCoordPointer((GLint)2, GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)((EGWuint)sizeof(egwVector3f) * 4 * 2 + (EGWuint)sizeof(egwVector2f) * 4));
                    
                    glDrawArrays(GL_TRIANGLE_FAN, 0, (GLsizei)4);
                } else {
                    egw_glBindBuffer(GL_ARRAY_BUFFER, 0);
                    
                    glVertexPointer((GLint)3, GL_FLOAT, (GLsizei)0, (const GLvoid*)&_isMesh.tfvCoords[0]);
                    glTexCoordPointer((GLint)2, GL_FLOAT, (GLsizei)0, (const GLvoid*)&_isMesh.tftCoords[0]);
                    
                    glDrawArrays(GL_TRIANGLE_FAN, 0, (GLsizei)4);
                    
                    glVertexPointer((GLint)3, GL_FLOAT, (GLsizei)0, (const GLvoid*)&_isMesh.tuvCoords[0]);
                    glTexCoordPointer((GLint)2, GL_FLOAT, (GLsizei)0, (const GLvoid*)&_isMesh.tutCoords[0]);
                    
                    glDrawArrays(GL_TRIANGLE_FAN, 0, (GLsizei)4);
                }
                
                glTranslatef(egwLerpf(_stMesh->vCoords[0].axis.x, _stMesh->vCoords[1].axis.x, _trOffset), 0.0f, 0.00001f);
                
                if(*_baseGeoAID) {
                    egw_glBindBuffer(GL_ARRAY_BUFFER, *_baseGeoAID);
                    
                    glVertexPointer((GLint)3, GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)sizeof(egwSQVAMesh4f));
                    glNormalPointer(GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)((EGWuint)sizeof(egwSQVAMesh4f) + (EGWuint)sizeof(egwVector3f) * 4));
                } else {
                    egw_glBindBuffer(GL_ARRAY_BUFFER, 0);
                    
                    glVertexPointer((GLint)3, GL_FLOAT, (GLsizei)0, (const GLvoid*)&_sbMesh->vCoords[0]);
                    glNormalPointer(GL_FLOAT, (GLsizei)0, (const GLvoid*)&_sbMesh->nCoords[0]);
                }
                
                if(_geoAID) {
                    egw_glBindBuffer(GL_ARRAY_BUFFER, _geoAID);
                    
                    glTexCoordPointer((GLint)2, GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)((EGWuint)sizeof(egwVector3f) * 4 * 2 + (EGWuint)sizeof(egwVector2f) * 4 * 2));
                } else {
                    egw_glBindBuffer(GL_ARRAY_BUFFER, 0);
                    
                    glTexCoordPointer((GLint)2, GL_FLOAT, (GLsizei)0, (const GLvoid*)&_isMesh.btCoords[0]);
                }
                
                glDrawArrays(GL_TRIANGLE_FAN, 0, (GLsizei)4);
                
                glPopMatrix();
            }
            
            egwAFPGfxCntxPopTextures(egwAIGfxCntx, @selector(popTextures:), 1);
            if(_mStack) egwSFPMtrlStckPopMaterials(_mStack, @selector(popMaterials));
            if(_lStack) egwSFPLghtStckPopLights(_lStack, @selector(popLights));
        }
    } else if(flags & EGW_GFXOBJ_RPLYFLG_DORENDERSTART) {
        _isRendering = YES;
        
        if(_delegate)
            [_delegate widget:self did:EGW_ACTION_START];
    } else if(flags & EGW_GFXOBJ_RPLYFLG_DORENDERSTOP) {
        _isRendering = NO;
        
        if(_isPressed) [self setPressed:NO];
        if(_isHooked) [self unhook];
        
        egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
        
        if(_delegate)
            [_delegate widget:self did:EGW_ACTION_STOP];
    }
}

- (void)unhook {
    if(_isHooked) {
        _isHooked = NO;
        if(_isPressed) [self setPressed:NO];
        [_delegate widget:self did:EGW_ACTION_UNHOOK];
    }
}

- (void)updateHookWithPickingRay:(egwRay4f*)ray {
    if(_isRendering && _isVisible && _isEnabled && _isHooked) {
        EGWsingle s = egwLineLineClosestS4f(&_wcsTrack, &(ray->line));
        
        s = egwClamp01f((s - EGW_SLIDER_EDGEFACTOR) * (1.0f / (1.0f - (EGW_SLIDER_EDGEFACTOR * 2.0f))));
        
        if(!egwIsEqualf(_tOffset, s)) {
            _tOffset = s;
            _trOffset = ((_tOffset * (1.0f - (EGW_SLIDER_EDGEFACTOR * 2.0f))) + EGW_SLIDER_EDGEFACTOR);
            
            _isMesh.tfvCoords[1].axis.x = _isMesh.tfvCoords[2].axis.x = _isMesh.tuvCoords[0].axis.x = _isMesh.tuvCoords[3].axis.x = 
                _stMesh->vCoords[0].axis.x + ((_stMesh->vCoords[1].axis.x - _stMesh->vCoords[0].axis.x) * _trOffset);
            _isMesh.tftCoords[1].axis.x = _isMesh.tftCoords[2].axis.x = _isMesh.tutCoords[0].axis.x = _isMesh.tutCoords[3].axis.x = 
                _stMesh->tCoords[0].axis.x + ((_stMesh->tCoords[1].axis.x - _stMesh->tCoords[0].axis.x) * _trOffset);
            
            if(_geoStrg & EGW_GEOMETRY_STRG_EXVBO)
                egwSFPVldtrInvalidate(_gbSync, @selector(invalidate));
            [_delegate sliderDidChange:self toOffset:_tOffset];
        }
        
        return;
    }
    
    _isHooked = NO;
    if(_isPressed) [self setPressed:NO];
    [_delegate widget:self did:EGW_ACTION_UNHOOK];
}

- (id<egwPAssetBase>)assetBase {
    return (id<egwPAssetBase>)_base;
}

- (EGWuint)coreObjectTypes {
    return (EGW_COREOBJ_TYPE_GRAPHIC | EGW_COREOBJ_TYPE_HOOKABLE | EGW_COREOBJ_TYPE_ORIENTABLE | EGW_COREOBJ_TYPE_TEXTURE | EGW_COREOBJ_TYPE_WIDGET);
}

- (egwValidater*)geometryBufferSync {
    return _gbSync;
}

- (EGWuint)geometryStorage {
    return _geoStrg;
}

- (NSString*)identity {
    return _ident;
}

- (EGWuint)lastTexturingBindingStage {
    return _lastTBind;
}

- (egwLightStack*)lightStack {
    return _lStack;
}

- (egwMaterialStack*)materialStack {
    return _mStack;
}

- (id<egwPInterpolator>)offsetDriver {
    return _lcsIpo;
}

- (id<egwPInterpolator>)orientateDriver {
    return _wcsIpo;
}

- (id<NSObject>)renderingBase {
    return (id<NSObject>)_base;
}

- (id<egwPBounding>)renderingBounding {
    return _wcsRBVol;
}

- (EGWuint32)renderingFlags {
    return _rFlags;
}

- (EGWuint16)renderingFrame {
    return _rFrame;
}

- (const egwVector4f*)renderingSource {
    return [_wcsRBVol boundingOrigin];
}

- (egwValidater*)renderingSync {
    return _rSync;
}

- (EGWsingle)sliderOffset {
    return _tOffset;
}

- (const egwLine4f*)sliderTrackLine {
    return &_wcsTrack;
}

- (egwValidater*)textureBufferSync {
    return [_base textureBufferSync];
}

- (const egwTextureJumpTable*)textureJumpTable {
    return &_egwTJT;
}

- (id<NSObject>)textureBase {
    return (id<NSObject>)_base;
}

- (EGWuint)textureEnvironment {
    return _texEnv;
}

- (EGWuint)texturingFilter {
    return [_base texturingFilter];
}

- (egwValidater*)texturingSync {
    return _tSync;
}

- (EGWuint)texturingTransforms {
    return [_base texturingTransforms];
}

- (EGWuint16)texturingSWrap {
    return [_base texturingSWrap];
}

- (EGWuint16)texturingTWrap {
    return [_base texturingTWrap];
}

- (const egwMatrix44f*)lcsTransform {
    return &_lcsTrans;
}

- (const egwMatrix44f*)wcsTransform {
    return &_wcsTrans;
}

- (const egwSize2i*)widgetSize {
    return [_base widgetSize];
}

- (id<egwPObjectBranch>)parent {
    return _parent;
}

- (id<egwPObjectBranch>)root {
    return (_parent ? [_parent root] : nil);
}

- (void)setDelegate:(id<egwDSliderEvent>)delegate {
    [delegate retain];
    [_delegate release];
    _delegate = delegate;
}

- (void)setParent:(id<egwPObjectBranch>)parent {
    if(_parent != parent && (id)_parent != (id)self && !_invkParent) {
        [self retain];
        
        if(_parent && ![_parent isInvokingChild]) {
            _invkParent = YES;
            [_parent removeChild:self];
            [_parent performSelector:@selector(decrementCoreObjectTypes:countBy:) withObject:(id)[self coreObjectTypes] withObject:(id)1 inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_CORECMP_TYPE_ALL withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            _invkParent = NO;
        }
        
        if(parent && _wcsIpo) {
            NSLog(@"egwSlider: setParent: Warning: Object system is overriding WCS interpolator driver for instance asset '%@' (%p).", _ident, self);
            [self trySetOrientateDriver:nil];
        }
        
        _parent = parent; // NOTE: Weak reference, do not retain! -jw
        
        if(_parent && ![_parent isInvokingChild]) {
            _invkParent = YES;
            [_parent addChild:self];
            [_parent performSelector:@selector(incrementCoreObjectTypes:countBy:) withObject:(id)[self coreObjectTypes] withObject:(id)1 inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_CORECMP_TYPE_ALL withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            _invkParent = NO;
        }
        
        [self release];
    }
}

- (void)setEnabled:(BOOL)enable {
    _isEnabled = enable;
    
    if(!_isEnabled) {
        if(_isPressed) [self setPressed:NO];
        if(_isHooked) [self unhook];
    }
}

- (void)setLightStack:(egwLightStack*)lghtStack {
    if(lghtStack && _lStack != lghtStack) {
        [lghtStack retain];
        [_lStack release];
        _lStack = lghtStack;
        
        egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
    }
}

- (void)setMaterialStack:(egwMaterialStack*)mtrlStack {
    if(mtrlStack && _mStack != mtrlStack) {
        [mtrlStack retain];
        [_mStack release];
        _mStack = mtrlStack;
        
        egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
    }
}

- (void)setPressed:(BOOL)status {
    _isPressed = status;
    
    _isMesh.btCoords[2].axis.y = _isMesh.btCoords[3].axis.y = (_isPressed ? _sbMesh->tCoords[0].axis.y : 0.0f);
    _isMesh.btCoords[0].axis.y = _isMesh.btCoords[1].axis.y = (_isPressed ? _sbMesh->tCoords[0].axis.y * 2.0f : _sbMesh->tCoords[0].axis.y);
    
    if(_geoStrg & EGW_GEOMETRY_STRG_EXVBO)
        egwSFPVldtrInvalidate(_gbSync, @selector(invalidate));
}

- (void)setRenderingFlags:(EGWuint)flags {
    _rFlags = flags;
    
    if((EGW_NODECMPMRG_GRAPHIC & EGW_CORECMP_TYPE_FLAGS) &&
       _parent && !_invkParent && ![_parent isInvokingChild]) {
        _invkParent = YES;
        EGWuint cmpntTypes = (_rFlags & EGW_OBJTREE_FLG_NOUMRGFLAGS ? 0 : EGW_CORECMP_TYPE_FLAGS & EGW_NODECMPMRG_GRAPHIC);
        if(cmpntTypes)
            [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        _invkParent = NO;
    }
}

- (void)setRenderingFrame:(EGWint)frmNumber {
    _rFrame = frmNumber;
    
    if((EGW_NODECMPMRG_GRAPHIC & EGW_CORECMP_TYPE_FRAMES) &&
       _parent && ![_parent isInvokingChild]) {
        _invkParent = YES;
        EGWuint cmpntTypes = (_rFlags & EGW_OBJTREE_FLG_NOUMRGFRAMES ? 0 : EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_GRAPHIC);
        if(cmpntTypes)
            [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        _invkParent = NO;
    }
}

- (void)setSliderOffset:(EGWsingle)offset {
    _tOffset = egwClamp01f(egwAbsf(offset));
    _trOffset = ((_tOffset * (1.0f - (EGW_SLIDER_EDGEFACTOR * 2.0f))) + EGW_SLIDER_EDGEFACTOR);
    
    _isMesh.tfvCoords[1].axis.x = _isMesh.tfvCoords[2].axis.x = _isMesh.tuvCoords[0].axis.x = _isMesh.tuvCoords[3].axis.x = egwLerpf(_stMesh->vCoords[0].axis.x, _stMesh->vCoords[1].axis.x, _trOffset);
    _isMesh.tftCoords[1].axis.x = _isMesh.tftCoords[2].axis.x = _isMesh.tutCoords[0].axis.x = _isMesh.tutCoords[3].axis.x = egwLerpf(_stMesh->tCoords[0].axis.x, _stMesh->tCoords[1].axis.x, _trOffset);
    
    if(_geoStrg & EGW_GEOMETRY_STRG_EXVBO)
        egwSFPVldtrInvalidate(_gbSync, @selector(invalidate));
    
    [_delegate sliderDidChange:self toOffset:_tOffset];
}

- (void)setVisible:(BOOL)visible {
    _isVisible = visible;
    
    if(!_isVisible) {
        if(_isPressed) [self setPressed:NO];
        if(_isHooked) [self unhook];
    }
    
    egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (BOOL)tryHookingWithPickingRay:(egwRay4f*)ray {
    EGWsingle s, t;
    
    if(_isRendering && _isVisible && _isEnabled && !_isHooked && [_wcsRBVol testCollisionWithLine:&(ray->line) startingAt:&s endingAt:&t] >= EGW_CLSNTEST_LINE_TOUCHES) {
        if((s >= ray->s - EGW_SFLT_EPSILON) || (t >= ray->s - EGW_SFLT_EPSILON)) {
            egwVector3f Rs, Tt; // ray at S, track at _tOffset
            
            s = egwLineLineClosestS4f(&(ray->line), &_wcsTrack);
            
            egwVecAdd3f((egwVector3f*)&(ray->line.origin), egwVecUScale3f((egwVector3f*)&(ray->line.normal), s, &Rs), &Rs);
            egwVecAdd3f((egwVector3f*)&(_wcsTrack.origin), egwVecUScale3f((egwVector3f*)&(_wcsTrack.normal), _tOffset, &Tt), &Tt);
            
            if(egwVecDistanceSqrd3f(&Rs, &Tt) <= (egwVecMagnitudeSqrd3f((egwVector3f*)&(_wcsTrack.normal)) * (EGW_SLIDER_HOOKFACTOR * EGW_SLIDER_HOOKFACTOR)) + EGW_SFLT_EPSILON) { // in x^2
                _isHooked = YES;
                if(!_isPressed) [self setPressed:YES];
                [_delegate widget:self did:EGW_ACTION_HOOK];
                return YES;
            }
        }
    }
    
    return NO;
}

- (BOOL)trySetGeometryDataPersistence:(BOOL)persist {
    // Not supported
    return NO;
}

- (BOOL)trySetGeometryStorage:(EGWuint)storage {
    _geoStrg = storage;
    
    egwSFPVldtrInvalidate(_gbSync, @selector(invalidate));
    
    return YES;
}

- (BOOL)trySetOffsetDriver:(id<egwPInterpolator>)lcsIpo {
    if(lcsIpo) {
        if(([lcsIpo isKindOfClass:[egwOrientationInterpolator class]]) ||
           ([lcsIpo isKindOfClass:[egwValueInterpolator class]] && [(egwValueInterpolator*)lcsIpo channelCount] == 16 && [(egwValueInterpolator*)lcsIpo channelFormat] == EGW_KEYCHANNEL_FRMT_SINGLE)) {
            [_lcsIpo removeTargetWithObject:self];
            [lcsIpo retain];
            [_lcsIpo release];
            _lcsIpo = lcsIpo;
            [_lcsIpo addTargetWithObject:self method:@selector(offsetByTransform:)];
            
            return YES;
        }
    } else {
        [_lcsIpo removeTargetWithObject:self];
        [_lcsIpo release]; _lcsIpo = nil;
        
        return YES;
    }
    
    return NO;
}

- (BOOL)trySetOrientateDriver:(id<egwPInterpolator>)wcsIpo {
    if(wcsIpo) {
        if(!_parent &&
           (([wcsIpo isKindOfClass:[egwOrientationInterpolator class]]) ||
            ([wcsIpo isKindOfClass:[egwValueInterpolator class]] && [(egwValueInterpolator*)wcsIpo channelCount] == 16 && [(egwValueInterpolator*)wcsIpo channelFormat] == EGW_KEYCHANNEL_FRMT_SINGLE))) {
            [_wcsIpo removeTargetWithObject:self];
            [wcsIpo retain];
            [_wcsIpo release];
            _wcsIpo = wcsIpo;
            [_wcsIpo addTargetWithObject:self method:@selector(orientateByTransform:)];
            
            return YES;
        }
    } else {
        [_wcsIpo removeTargetWithObject:self];
        [_wcsIpo release]; _wcsIpo = nil;
        
        return YES;
    }
    
    return NO;
}

- (BOOL)trySetTextureDataPersistence:(BOOL)persist {
    return [_base trySetTextureDataPersistence:persist];
}

- (BOOL)trySetTextureEnvironment:(EGWuint)environment {
    _texEnv = environment;
    
    egwSFPVldtrInvalidate(_tSync, @selector(invalidate));
    
    return YES;
}

- (BOOL)trySetTexturingFilter:(EGWuint)filter {
    return [_base trySetTexturingFilter:filter];
}

- (BOOL)trySetTexturingWrapS:(EGWuint16)sWrap {
    return [_base trySetTexturingWrapS:sWrap];
}

- (BOOL)trySetTexturingWrapT:(EGWuint16)tWrap {
    return [_base trySetTexturingWrapT:tWrap];
}

- (BOOL)isChildOf:(id<egwPObjectBranch>)parent {
    return (_parent == parent ? YES : NO);
}

- (BOOL)isGeometryDataPersistent {
    return YES;
}

- (BOOL)isInvokingParent {
    return _invkParent;
}

- (BOOL)isLeaf {
    return YES;
}

- (BOOL)isOrientationPending {
    return _ortPending;
}

- (BOOL)isRendering {
    return _isRendering;
}

- (BOOL)isBoundForTexturing {
    return _isTBound;
}

- (BOOL)isEnabled {
    return _isEnabled;
}

- (BOOL)isHooked {
    return _isHooked;
}

- (BOOL)isOpaque {
    return !(_rFlags & EGW_GFXOBJ_RNDRFLG_ISTRANSPARENT) && ((_rFlags & EGW_GFXOBJ_RNDRFLG_ISOPAQUE) || ((([_base widgetSurface]->format & EGW_SURFACE_FRMT_EXAC) ? NO : (!_mStack || [_mStack isOpaque]))));
}

- (BOOL)isTextureDataPersistent {
    return [_base isTextureDataPersistent];
}

- (BOOL)isVisible {
    return _isVisible;
}

- (void)validaterDidValidate:(egwValidater*)validater {
    if(_ortPending) [self applyOrientation];
    
    if(_rSync == validater &&
       (EGW_NODECMPMRG_GRAPHIC & EGW_CORECMP_TYPE_SYNCS) &&
       _parent && !_invkParent && ![_parent isInvokingChild]) {
        _invkParent = YES;
        EGWuint cmpntTypes = (_rFlags & EGW_OBJTREE_FLG_NOUMRGSYNCS ? 0 : EGW_OBJTREE_FLG_NOUMRGSYNCS & EGW_NODECMPMRG_GRAPHIC);
        if(cmpntTypes)
            [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[validater coreObjects] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        _invkParent = NO;
    }
}

- (void)validaterDidInvalidate:(egwValidater*)validater {
    if(_rSync == validater &&
       (EGW_NODECMPMRG_GRAPHIC & EGW_CORECMP_TYPE_SYNCS) &&
       _parent && !_invkParent && ![_parent isInvokingChild]) {
        _invkParent = YES;
        EGWuint cmpntTypes = (_rFlags & EGW_OBJTREE_FLG_NOUMRGSYNCS ? 0 : EGW_OBJTREE_FLG_NOUMRGSYNCS & EGW_NODECMPMRG_GRAPHIC);
        if(cmpntTypes)
            [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[validater coreObjects] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        _invkParent = NO;
    } else if(_gbSync == validater) {
        if(_geoStrg & EGW_GEOMETRY_STRG_EXVBO) // Buffer mesh data up through context
            [egwAIGfxCntx addSubTask:self forSync:_gbSync];
        else
            egwSFPVldtrValidate(_gbSync, @selector(validate));
    }
}

@end


@implementation egwSliderBase

- (id)initWithIdentity:(NSString*)assetIdent sliderSurface:(egwSurface*)surface sliderTrackWidth:(EGWuint16)trckWidth sliderTrackHeight:(EGWuint16)trckHeight sliderButtonWidth:(EGWuint16)btnWidth sliderButtonHeight:(EGWuint16)btnHeight geometryStorage:(EGWuint)storage texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter {
    if(!(surface && trckWidth && trckHeight && btnWidth && btnHeight)) { [self release]; return (self = nil); }
    
    // TODO: Allow auto width/height find via examining surface data and looking for centerline blank row(s) and centerline blank col(s). -jw
    
    if(!([super initWithIdentity:assetIdent imageSurface:surface imageWidth:(trckWidth + btnWidth) imageHeight:egwMax2ui16(trckHeight * 2, btnHeight * 2) geometryStorage:storage texturingTransforms:transforms texturingFilter:filter])) { return nil; }
    
    _iSize.span.width = egwMax2ui16(trckWidth, btnWidth);
    _iSize.span.height = egwMax2ui16(trckHeight, btnHeight);
    _stSize.span.width = trckWidth;
    _stSize.span.height = trckHeight;
    _sbSize.span.width = btnWidth;
    _sbSize.span.height = btnHeight;
    memcpy((void*)&_sMesh.tMesh, (const void*)&_iMesh, sizeof(egwSQVAMesh4f));
    memcpy((void*)&_sMesh.bMesh, (const void*)&_iMesh, sizeof(egwSQVAMesh4f));
    
    // NOTE: The MCS widget layout is always direct center zero aligned with half widths on -X to +X and half heights on -Y to +Y, this vertex set should _NEVER_ be directly transformed -jw
    {   EGWsingle halfWidth = (EGWsingle)_iSize.span.width * 0.5f;
        EGWsingle halfHeight = (EGWsingle)_iSize.span.height * 0.5f;
        
        _iMesh.vCoords[0].axis.x = -halfWidth; _iMesh.vCoords[0].axis.y = -halfHeight;
        _iMesh.vCoords[1].axis.x =  halfWidth; _iMesh.vCoords[1].axis.y = -halfHeight;
        _iMesh.vCoords[2].axis.x =  halfWidth; _iMesh.vCoords[2].axis.y =  halfHeight;
        _iMesh.vCoords[3].axis.x = -halfWidth; _iMesh.vCoords[3].axis.y =  halfHeight;
        
        [_mmcsRBVol initWithOpticalSource:&egwSIVecZero3f vertexCount:4 vertexCoords:(const egwVector3f*)&_iMesh.vCoords[0] vertexCoordsStride:0];
        
        // Do bvol extension scaling
        {   egwMatrix44f sTrans;
            egwMatScale44fs(NULL, EGW_SLIDER_BVOLSCALE, EGW_SLIDER_BVOLSCALE, EGW_SLIDER_BVOLSCALE, &sTrans);
            [_mmcsRBVol baseOffsetByTransform:&sTrans];
        }
        
        halfWidth = (EGWsingle)_stSize.span.width * 0.5f;
        halfHeight = (EGWsingle)_stSize.span.height * 0.5f;
        
        _sMesh.tMesh.vCoords[0].axis.x = -halfWidth; _sMesh.tMesh.vCoords[0].axis.y = -halfHeight;
        _sMesh.tMesh.vCoords[1].axis.x =  halfWidth; _sMesh.tMesh.vCoords[1].axis.y = -halfHeight;
        _sMesh.tMesh.vCoords[2].axis.x =  halfWidth; _sMesh.tMesh.vCoords[2].axis.y =  halfHeight;
        _sMesh.tMesh.vCoords[3].axis.x = -halfWidth; _sMesh.tMesh.vCoords[3].axis.y =  halfHeight;
        
        halfWidth = (EGWsingle)_sbSize.span.width * 0.5f;
        halfHeight = (EGWsingle)_sbSize.span.height * 0.5f;
        
        _sMesh.bMesh.vCoords[0].axis.x = -halfWidth; _sMesh.bMesh.vCoords[0].axis.y = -halfHeight;
        _sMesh.bMesh.vCoords[1].axis.x =  halfWidth; _sMesh.bMesh.vCoords[1].axis.y = -halfHeight;
        _sMesh.bMesh.vCoords[2].axis.x =  halfWidth; _sMesh.bMesh.vCoords[2].axis.y =  halfHeight;
        _sMesh.bMesh.vCoords[3].axis.x = -halfWidth; _sMesh.bMesh.vCoords[3].axis.y =  halfHeight;
    }
    
    _sMesh.tMesh.tCoords[0].axis.x = _sMesh.tMesh.tCoords[3].axis.x = (EGWsingle)EGW_WIDGET_TXCCORRECT; 
    _sMesh.tMesh.tCoords[1].axis.x = _sMesh.tMesh.tCoords[2].axis.x =
        (EGWsingle)egwClamp01d(((EGWdouble)_stSize.span.width / (EGWdouble)_iSrfc.size.span.width) - (EGWdouble)EGW_WIDGET_TXCCORRECT);
    _sMesh.bMesh.tCoords[0].axis.x = _sMesh.bMesh.tCoords[3].axis.x =
        (EGWsingle)egwClamp01d(((EGWdouble)_stSize.span.width / (EGWdouble)(_iSrfc.size.span.width-1)) + (EGWdouble)EGW_WIDGET_TXCCORRECT);
    _sMesh.tMesh.tCoords[2].axis.y = _sMesh.tMesh.tCoords[3].axis.y =
        _sMesh.bMesh.tCoords[2].axis.y = _sMesh.bMesh.tCoords[3].axis.y = (EGWsingle)EGW_WIDGET_TXCCORRECT;
    _sMesh.tMesh.tCoords[0].axis.y = _sMesh.tMesh.tCoords[1].axis.y =
        (EGWsingle)egwClamp01d(((EGWdouble)_stSize.span.height / (EGWdouble)_iSrfc.size.span.height) - (EGWdouble)EGW_WIDGET_TXCCORRECT);
    _sMesh.bMesh.tCoords[0].axis.y = _sMesh.bMesh.tCoords[1].axis.y =
        (EGWsingle)egwClamp01d(((EGWdouble)_sbSize.span.height / (EGWdouble)_iSrfc.size.span.height) - (EGWdouble)EGW_WIDGET_TXCCORRECT);
    
    // Make the track line, from left side to right
    _mmcsTrack.origin.axis.x = _sMesh.tMesh.vCoords[0].axis.x;
    _mmcsTrack.origin.axis.y = _mmcsTrack.origin.axis.z = 0.0f;
    _mmcsTrack.origin.axis.w = 1.0f;
    _mmcsTrack.normal.axis.x = _sMesh.tMesh.vCoords[1].axis.x * 2.0f; // NOTE: Must be length of widget, do not normalize! -jw
    _mmcsTrack.normal.axis.y = _mmcsTrack.normal.axis.z = 0.0f;
    _mmcsTrack.normal.axis.w = 0.0f;
    
    return self;
}

- (id)initBlankWithIdentity:(NSString*)assetIdent surfaceFormat:(EGWuint32)format sliderTrackWidth:(EGWuint16)trckWidth sliderTrackHeight:(EGWuint16)trckHeight sliderButtonWidth:(EGWuint16)btnWidth sliderButtonHeight:(EGWuint16)btnHeight geometryStorage:(EGWuint)storage texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter {
    if(!(trckWidth && trckHeight && btnWidth && btnHeight)) { [self release]; return (self = nil); }
    
    if(!([super initBlankWithIdentity:assetIdent surfaceFormat:format imageWidth:(trckWidth + btnWidth) imageHeight:egwMax2ui16(trckHeight * 2, btnHeight * 2) geometryStorage:storage texturingTransforms:transforms texturingFilter:filter])) { return nil; }
    
    _iSize.span.width = egwMax2ui16(trckWidth, btnWidth);
    _iSize.span.height = egwMax2ui16(trckHeight, btnHeight);
    _stSize.span.width = trckWidth;
    _stSize.span.height = trckHeight;
    _sbSize.span.width = btnWidth;
    _sbSize.span.height = btnHeight;
    memcpy((void*)&_sMesh.tMesh, (const void*)&_iMesh, sizeof(egwSQVAMesh4f));
    memcpy((void*)&_sMesh.bMesh, (const void*)&_iMesh, sizeof(egwSQVAMesh4f));
    
    // NOTE: The MCS widget layout is always direct center zero aligned with half widths on -X to +X and half heights on -Y to +Y, this vertex set should _NEVER_ be directly transformed -jw
    {   EGWsingle halfWidth = (EGWsingle)_iSize.span.width * 0.5f;
        EGWsingle halfHeight = (EGWsingle)_iSize.span.height * 0.5f;
        
        _iMesh.vCoords[0].axis.x = -halfWidth; _iMesh.vCoords[0].axis.y = -halfHeight;
        _iMesh.vCoords[1].axis.x =  halfWidth; _iMesh.vCoords[1].axis.y = -halfHeight;
        _iMesh.vCoords[2].axis.x =  halfWidth; _iMesh.vCoords[2].axis.y =  halfHeight;
        _iMesh.vCoords[3].axis.x = -halfWidth; _iMesh.vCoords[3].axis.y =  halfHeight;
        
        [_mmcsRBVol initWithOpticalSource:&egwSIVecZero3f vertexCount:4 vertexCoords:(const egwVector3f*)&_iMesh.vCoords[0] vertexCoordsStride:0];
        
        // Do bvol extension scaling
        {   egwMatrix44f sTrans;
            egwMatScale44fs(NULL, EGW_SLIDER_BVOLSCALE, EGW_SLIDER_BVOLSCALE, EGW_SLIDER_BVOLSCALE, &sTrans);
            [_mmcsRBVol baseOffsetByTransform:&sTrans];
        }
        
        halfWidth = (EGWsingle)_stSize.span.width * 0.5f;
        halfHeight = (EGWsingle)_stSize.span.height * 0.5f;
        
        _sMesh.tMesh.vCoords[0].axis.x = -halfWidth; _sMesh.tMesh.vCoords[0].axis.y = -halfHeight;
        _sMesh.tMesh.vCoords[1].axis.x =  halfWidth; _sMesh.tMesh.vCoords[1].axis.y = -halfHeight;
        _sMesh.tMesh.vCoords[2].axis.x =  halfWidth; _sMesh.tMesh.vCoords[2].axis.y =  halfHeight;
        _sMesh.tMesh.vCoords[3].axis.x = -halfWidth; _sMesh.tMesh.vCoords[3].axis.y =  halfHeight;
        
        halfWidth = (EGWsingle)_sbSize.span.width * 0.5f;
        halfHeight = (EGWsingle)_sbSize.span.height * 0.5f;
        
        _sMesh.bMesh.vCoords[0].axis.x = -halfWidth; _sMesh.bMesh.vCoords[0].axis.y = -halfHeight;
        _sMesh.bMesh.vCoords[1].axis.x =  halfWidth; _sMesh.bMesh.vCoords[1].axis.y = -halfHeight;
        _sMesh.bMesh.vCoords[2].axis.x =  halfWidth; _sMesh.bMesh.vCoords[2].axis.y =  halfHeight;
        _sMesh.bMesh.vCoords[3].axis.x = -halfWidth; _sMesh.bMesh.vCoords[3].axis.y =  halfHeight;
    }
    
    _sMesh.tMesh.tCoords[0].axis.x = _sMesh.tMesh.tCoords[3].axis.x = (EGWsingle)EGW_WIDGET_TXCCORRECT; 
    _sMesh.tMesh.tCoords[1].axis.x = _sMesh.tMesh.tCoords[2].axis.x =
        (EGWsingle)egwClamp01d(((EGWdouble)_stSize.span.width / (EGWdouble)_iSrfc.size.span.width) - (EGWdouble)EGW_WIDGET_TXCCORRECT);
    _sMesh.bMesh.tCoords[0].axis.x = _sMesh.bMesh.tCoords[3].axis.x =
        (EGWsingle)egwClamp01d(((EGWdouble)_stSize.span.width / (EGWdouble)(_iSrfc.size.span.width-1)) + (EGWdouble)EGW_WIDGET_TXCCORRECT);
    _sMesh.tMesh.tCoords[2].axis.y = _sMesh.tMesh.tCoords[3].axis.y =
    _sMesh.bMesh.tCoords[2].axis.y = _sMesh.bMesh.tCoords[3].axis.y = (EGWsingle)EGW_WIDGET_TXCCORRECT;
    _sMesh.tMesh.tCoords[0].axis.y = _sMesh.tMesh.tCoords[1].axis.y =
        (EGWsingle)egwClamp01d(((EGWdouble)_stSize.span.height / (EGWdouble)_iSrfc.size.span.height) - (EGWdouble)EGW_WIDGET_TXCCORRECT);
    _sMesh.bMesh.tCoords[0].axis.y = _sMesh.bMesh.tCoords[1].axis.y =
        (EGWsingle)egwClamp01d(((EGWdouble)_sbSize.span.height / (EGWdouble)_iSrfc.size.span.height) - (EGWdouble)EGW_WIDGET_TXCCORRECT);
    
    // Make the track line, from left side to right
    _mmcsTrack.origin.axis.x = _sMesh.tMesh.vCoords[0].axis.x;
    _mmcsTrack.origin.axis.y = _mmcsTrack.origin.axis.z = 0.0f;
    _mmcsTrack.origin.axis.w = 1.0f;
    _mmcsTrack.normal.axis.x = _sMesh.tMesh.vCoords[1].axis.x * 2.0f; // NOTE: Must be length of widget, do not normalize! -jw
    _mmcsTrack.normal.axis.y = _mmcsTrack.normal.axis.z = 0.0f;
    _mmcsTrack.normal.axis.w = 0.0f;
    
    return self;
}

- (id)initWithIdentity:(NSString*)assetIdent imageSurface:(egwSurface*)surface imageWidth:(EGWuint16)width imageHeight:(EGWuint16)height texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter {
    NSLog(@"egwSliderBase: initWithIdentity:imageSurface:imageWidth:imageHeight:texturingTransforms:texturingFilter: This method is unused for this instance (%p).", self);
    [self release]; return (self = nil);
}

- (id)initBlankWithIdentity:(NSString*)assetIdent surfaceFormat:(EGWuint32)format imageWidth:(EGWuint16)width imageHeight:(EGWuint16)height texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter {
    NSLog(@"egwSliderBase: initBlankWithIdentity:surfaceFormat:imageWidth:imageHeight:texturingTransforms:texturingFilter: This method is unused for this instance (%p).", self);
    [self release]; return (self = nil);
}

- (void)dealloc {
    [super dealloc];
}

- (void)baseOffsetByTransform:(const egwMatrix44f*)transform {
    egwMatMultiply44f(&_mcsTrans, transform, &_mcsTrans);
    [_mmcsRBVol baseOffsetByTransform:transform];
    egwLineTransform444f(transform, &_mmcsTrack, &_mmcsTrack);
}

- (BOOL)performSubTaskForComponent:(id<NSObject>)component forSync:(egwValidater*)sync {
    if((id)component == (id)egwAIGfxCntxAGL) {
        if(_gbSync == sync && (_geoStrg & EGW_GEOMETRY_STRG_EXVBO)) {
            if([egwAIGfxCntxAGL loadBufferArraysID:&_geoAID withRawData:(const EGWbyte*)&_sMesh dataSize:(EGWuint)sizeof(_sMesh) geometryStorage:_geoStrg]) {
                egwSFPVldtrValidate(_gbSync, @selector(validate)); // Event delegate will dealloc if not persistent
                
                return YES; // Done with this item, no other work left
            } else
                NSLog(@"egwImageBase: performSubTaskForComponent:forSync: Failure buffering geometry mesh for asset '%@' (%p).", _ident, self);
            
            return NO; // Failure to load, try again next time
        }
    }
    
    return [super performSubTaskForComponent:component forSync:sync]; // Nothing to do
}

- (const egwSQVAMesh4f*)sliderButtonMesh {
    return &_sMesh.bMesh;
}

- (const egwSize2i*)sliderButtonSize {
    return &_sbSize;
}

- (const egwSQVAMesh4f*)sliderTrackMesh {
    return &_sMesh.tMesh;
}

- (const egwSize2i*)sliderTrackSize {
    return &_stSize;
}

- (const egwLine4f*)sliderTrackLine {
    return &_mmcsTrack;
}

@end

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

/// @file egwButton.m
/// @ingroup geWizES_gui_button
/// Button Widget Implementation.

#import "egwButton.h"
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


// !!!: ***** egwButton *****

@implementation egwButton

static egwTextureJumpTable _egwTJT = { NULL };

+ (id)allocWithZone:(NSZone*)zone {
    NSObject* inst = (NSObject*)[super allocWithZone:zone];
    
    if(!_egwTJT.fpTBind && [inst isMemberOfClass:[egwButton class]]) {
        _egwTJT.fpTBind = (BOOL(*)(id, SEL, EGWuint, EGWuint))[inst methodForSelector:@selector(bindForTexturingStage:withFlags:)];
        _egwTJT.fpTUnbind = (BOOL(*)(id, SEL, EGWuint))[inst methodForSelector:@selector(unbindTexturingWithFlags:)];
        _egwTJT.fpTBase = (id<NSObject>(*)(id, SEL))[inst methodForSelector:@selector(textureBase)];
        _egwTJT.fpTSync = (egwValidater*(*)(id, SEL))[inst methodForSelector:@selector(texturingSync)];
        _egwTJT.fpTLBStage = (EGWuint(*)(id, SEL))[inst methodForSelector:@selector(lastTexturingBindingStage)];
    }
    
    return (id)inst;
}

- (id)init {
    if([self isMemberOfClass:[egwButton class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent buttonSurface:(egwSurface*)surface buttonWidth:(EGWuint16)width buttonHeight:(EGWuint16)height instanceGeometryStorage:(EGWuint)instStorage baseGeometryStorage:(EGWuint)baseStorage textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack {
    if(!(surface && [super init])) { [self release]; return (self = nil); }
    
    // Assign appropriate width and height (or auto-assign)
    // NOTE: This auto-assignment won't be accurate in the case of pre-upscaled-to-pow2 images. No fix possible. -jw
    {   register EGWuint16 autoWidth = surface->size.span.width >> 1;
        register EGWuint16 autoHeight = surface->size.span.height;
        
        if(!width || width > autoWidth) width = autoWidth;
        if(!height || height > autoHeight) height = autoHeight;
    }
    
    // Build framing and bvol extension scaling
    {   egwSurfaceFraming sFrame;
        egwMatrix44f sTrans;
        
        sFrame.fCount = 2;
        sFrame.fOffset = 0;
        sFrame.hFrames = 2;
        sFrame.vFrames = 1;
        // These two are auto readjusted if resize occurs during load up
        sFrame.htSizer = (EGWdouble)((EGWuint)width * (EGWuint)sFrame.hFrames) / (EGWdouble)surface->size.span.width / (EGWdouble)sFrame.hFrames;
        sFrame.vtSizer = (EGWdouble)((EGWuint)height * (EGWuint)sFrame.vFrames) / (EGWdouble)surface->size.span.height / (EGWdouble)sFrame.vFrames;
        
        if(!(_base = [[egwSpritedImageBase alloc] initWithIdentity:assetIdent spriteSurfaces:surface surfaceFramings:&sFrame surfaceCount:1 spriteWidth:width spriteHeight:height geometryStorage:baseStorage texturingTransforms:transforms texturingFilter:filter])) { [self release]; return (self = nil); }
        
        egwMatScale44fs(NULL, EGW_BUTTON_BVOLSCALE, EGW_BUTTON_BVOLSCALE, EGW_BUTTON_BVOLSCALE, &sTrans);
        [[_base renderingBounding] baseOffsetByTransform:&sTrans];
    }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _rFlags = EGW_GFXOBJ_RNDRFLG_DFLT;
    _rFrame = EGW_FRAME_ALWAYSPASS;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = (lghtStack ? [lghtStack retain] : [[egwLightStack alloc] init]))) { [self release]; return (self = nil); }
    if(!(_mStack = (mtrlStack ? [mtrlStack retain] : [[egwSIEngine defaultMaterialStack] retain]))) { [self release]; return (self = nil); }
    
    _isEnabled = _isVisible = YES;
    
    _geoStrg = instStorage;
    if(!(_gbSync = [[egwValidater alloc] initWithOwner:self validation:(_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES) coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    
    _lastTBind = NSNotFound;
    _texEnv = environment;
    if(!(_tSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    if(!(_wcsRBVol = [(NSObject*)[_base renderingBounding] copy])) { [self release]; return (self = nil); }
    
    _sFrames = [_base widgetFramings];
    _texIDs = [_base textureIDs];
    _mcsTrans = [_base mcsTransform];
    _bMesh = [_base widgetMesh];
    _baseGeoAID = [_base geometryArraysID];
    
    egwWdgtSFrmtTexOffset(&_sFrames[0], (_isPressed ? 1 : 0), &_isMesh.btCoords[0]);
    
    if((_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && !([egwAIGfxCntxAGL isActive] && [self performSubTaskForComponent:egwAIGfxCntxAGL forSync:_gbSync])) // Attempt to load, if context active on this thread
        [egwAIGfxCntx addSubTask:self forSync:_gbSync]; // Delayed load for context sub task to handle
    
    return self;
}

- (id)initBlankWithIdentity:(NSString*)assetIdent surfaceFormat:(EGWuint32)format buttonWidth:(EGWuint16)width buttonHeight:(EGWuint16)height instanceGeometryStorage:(EGWuint)instStorage baseGeometryStorage:(EGWuint)baseStorage textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack {
    if(!(width && height && (self = [super init]))) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwSpritedImageBase alloc] initBlankWithIdentity:assetIdent surfaceFormat:format spriteWidth:width spriteHeight:height frameCount:2 geometryStorage:baseStorage texturingTransforms:transforms texturingFilter:filter])) { [self release]; return (self = nil); }
    if([_base surfaceCount] != 1) { [self release]; return (self = nil); } // Enforce singular surface for internal logic control
    // Do bvol extension scaling
    {   egwMatrix44f sTrans;
        egwMatScale44fs(NULL, EGW_BUTTON_BVOLSCALE, EGW_BUTTON_BVOLSCALE, EGW_BUTTON_BVOLSCALE, &sTrans);
        [[_base renderingBounding] baseOffsetByTransform:&sTrans];
    }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _rFlags = EGW_GFXOBJ_RNDRFLG_DFLT;
    _rFrame = EGW_FRAME_ALWAYSPASS;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = (lghtStack ? [lghtStack retain] : [[egwLightStack alloc] init]))) { [self release]; return (self = nil); }
    if(!(_mStack = (mtrlStack ? [mtrlStack retain] : [[egwSIEngine defaultMaterialStack] retain]))) { [self release]; return (self = nil); }
    
    _isEnabled = _isVisible = YES;
    
    _geoStrg = instStorage;
    if(!(_gbSync = [[egwValidater alloc] initWithOwner:self validation:(_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES) coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    
    _lastTBind = NSNotFound;
    _texEnv = environment;
    if(!(_tSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    if(!(_wcsRBVol = [(NSObject*)[_base renderingBounding] copy])) { [self release]; return (self = nil); }
    
    _sFrames = [_base widgetFramings];
    _texIDs = [_base textureIDs];
    _mcsTrans = [_base mcsTransform];
    _bMesh = [_base widgetMesh];
    _baseGeoAID = [_base geometryArraysID];
    
    egwWdgtSFrmtTexOffset(&_sFrames[0], (_isPressed ? 1 : 0), &_isMesh.btCoords[0]);
    
    if((_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && !([egwAIGfxCntxAGL isActive] && [self performSubTaskForComponent:egwAIGfxCntxAGL forSync:_gbSync])) // Attempt to load, if context active on this thread
        [egwAIGfxCntx addSubTask:self forSync:_gbSync]; // Delayed load for context sub task to handle
    
    // NOTE: Delayed load will occur on buffer sync invalidation. -jw
    
    return self;
}

- (id)initLoadedFromResourceFile:(NSString*)resourceFile withIdentity:(NSString*)assetIdent buttonWidth:(EGWuint16)width buttonHeight:(EGWuint16)height instanceGeometryStorage:(EGWuint)instStorage baseGeometryStorage:(EGWuint)baseStorage textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack {
    egwSurface surface; memset((void*)&surface, 0, sizeof(egwSurface));
    
    if(!([egwSIAsstMngr loadSurface:&surface fromFile:resourceFile withTransforms:(transforms & ~EGW_SURFACE_TRFM_ENSRPOW2)])) {
        if(surface.data) egwSrfcFree(&surface);
        [self release]; return (self = nil);
    }
    
    if(!(self = [self initWithIdentity:assetIdent buttonSurface:&surface buttonWidth:width buttonHeight:height instanceGeometryStorage:instStorage baseGeometryStorage:baseStorage textureEnvironment:environment texturingTransforms:(transforms | EGW_SURFACE_TRFM_ENSRPOW2) texturingFilter:filter lightStack:lghtStack materialStack:mtrlStack])) {
        if(surface.data) egwSrfcFree(&surface);
        return nil;
    }
    
    return self;
}

- (id)initCopyOf:(id<egwPWidget>)widget withIdentity:(NSString*)assetIdent {
    if(!([widget isKindOfClass:[self class]]) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = (egwSpritedImageBase*)[[(egwImage*)widget assetBase] retain])) { [self release]; return (self = nil); }
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _rFlags = [(egwImage*)widget renderingFlags];
    _rFrame = EGW_FRAME_ALWAYSPASS;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = [[widget lightStack] retain])) { [self release]; return (self = nil); }
    if(!(_mStack = [[widget materialStack] retain])) { [self release]; return (self = nil); }
    
    _isEnabled = [widget isEnabled];
    _isVisible = [widget isVisible];
    
    _geoStrg = [(egwButton*)widget geometryStorage];
    if(!(_gbSync = [[egwValidater alloc] initWithOwner:self validation:(_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES) coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    
    _lastTBind = NSNotFound;
    _texEnv = [widget textureEnvironment];
    if(!(_tSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    
    egwMatCopy44f([(egwImage*)widget wcsTransform], &_wcsTrans);
    egwMatCopy44f([(egwImage*)widget lcsTransform], &_lcsTrans);
    if(!(_wcsRBVol = [(NSObject*)[(egwImage*)widget renderingBounding] copy])) { [self release]; return (self = nil); }
    if([(id<egwPOrientated>)widget offsetDriver] && ![self trySetOffsetDriver:[(id<egwPOrientated>)widget offsetDriver]]) { [self release]; return (self = nil); }
    if([(id<egwPOrientated>)widget orientateDriver] && ![self trySetOrientateDriver:[(id<egwPOrientated>)widget orientateDriver]]) { [self release]; return (self = nil); }
    
    _sFrames = [_base widgetFramings];
    _texIDs = [_base textureIDs];
    _mcsTrans = [_base mcsTransform];
    _bMesh = [_base widgetMesh];
    _baseGeoAID = [_base geometryArraysID];
    
    egwWdgtSFrmtTexOffset(&_sFrames[0], (_isPressed ? 1 : 0), &_isMesh.btCoords[0]);
    
    if((_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && !([egwAIGfxCntxAGL isActive] && [self performSubTaskForComponent:egwAIGfxCntxAGL forSync:_gbSync])) // Attempt to load, if context active on this thread
        [egwAIGfxCntx addSubTask:self forSync:_gbSync]; // Delayed load for context sub task to handle
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwButton* copy = nil;
    NSString* copyIdent = nil;
    
    if([_ident hasSuffix:@"_default"])
        copyIdent = [[NSString alloc] initWithFormat:@"%@_%d", [_base identity], [_base nextInstanceIndex]];
    else copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwButton allocWithZone:zone] initCopyOf:self
                                              withIdentity:copyIdent])) {
        NSLog(@"egwButton: copyWithZone: Failure initializing new button from instance asset '%@' (%p). Failure creating copy.", _ident, self);
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
    
    _sFrames = NULL;
    _texIDs = NULL;
    _mcsTrans = NULL;
    _bMesh = NULL;
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
            if(_texIDs && *_texIDs && (*_texIDs)[0]) {
                egw_glBindTexture(texture, GL_TEXTURE_2D, (GLuint)(*_texIDs)[0]);
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
                NSLog(@"egwButton: performSubTaskForComponent:forSync: Failure buffering instance geometry mesh for asset '%@' (%p).", _ident, self);
            
            return NO; // Failure to load, try again next time
        }
    }
    
    return YES; // Nothing to do
}

- (void)press {
    if(_isRendering && _isVisible && _isEnabled && _isHooked && _isPressed)
        [_delegate buttonDidPress:self];
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
                    if(egw_glBindBuffer(GL_ARRAY_BUFFER, *_baseGeoAID) || !(flags & EGW_GFXOBJ_RPLYFLG_SAMELASTBASE)) {
                        glVertexPointer((GLint)3, GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)0);
                        glNormalPointer(GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)((EGWuint)sizeof(egwVector3f) * 4));
                    }
                } else {
                    if(egw_glBindBuffer(GL_ARRAY_BUFFER, 0) || !(flags & EGW_GFXOBJ_RPLYFLG_SAMELASTBASE)) {
                        glVertexPointer((GLint)3, GL_FLOAT, (GLsizei)0, (const GLvoid*)&_bMesh->vCoords[0]);
                        glNormalPointer(GL_FLOAT, (GLsizei)0, (const GLvoid*)&_bMesh->nCoords[0]);
                    }
                }
                
                if(_geoAID) {
                    egw_glBindBuffer(GL_ARRAY_BUFFER, _geoAID);
                    
                    glTexCoordPointer((GLint)2, GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)0);
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
    EGWsingle s, t;
    
    if(_isRendering && _isVisible && _isEnabled && _isHooked && [_wcsRBVol testCollisionWithLine:&(ray->line) startingAt:&s endingAt:&t] >= EGW_CLSNTEST_LINE_TOUCHES) {
        if((s >= ray->s - EGW_SFLT_EPSILON) || (t >= ray->s - EGW_SFLT_EPSILON)) {
            return;
        }
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

- (void)setDelegate:(id<egwDButtonEvent>)delegate {
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
            NSLog(@"egwButton: setParent: Warning: Object system is overriding WCS interpolator driver for instance asset '%@' (%p).", _ident, self);
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

- (void)setRenderingFlags:(EGWuint)flags {
	_rFlags = flags;
	
	if((EGW_NODECMPMRG_GRAPHIC & EGW_CORECMP_TYPE_FLAGS) &&
	   _parent && !_invkParent && ![_parent isInvokingChild]) {
		EGWuint cmpntTypes = (_rFlags & EGW_OBJTREE_FLG_NOUMRGFLAGS ? 0 : EGW_CORECMP_TYPE_FLAGS & EGW_NODECMPMRG_GRAPHIC);
		_invkParent = YES;
		if(cmpntTypes)
			[_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
		_invkParent = NO;
	}
}

- (void)setRenderingFrame:(EGWint)frmNumber {
	_rFrame = frmNumber;
	
	if((EGW_NODECMPMRG_GRAPHIC & EGW_CORECMP_TYPE_FRAMES) &&
	   _parent && !_invkParent && ![_parent isInvokingChild]) {
		EGWuint cmpntTypes = (_rFlags & EGW_OBJTREE_FLG_NOUMRGFRAMES ? 0 : EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_GRAPHIC);
		_invkParent = YES;
		if(cmpntTypes)
			[_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
		_invkParent = NO;
	}
}

- (void)setPressed:(BOOL)status {
    _isPressed = status;
    
    egwWdgtSFrmtTexOffset(&_sFrames[0], (_isPressed ? 1 : 0), &_isMesh.btCoords[0]);
    if(_geoStrg & EGW_GEOMETRY_STRG_EXVBO)
        egwSFPVldtrInvalidate(_gbSync, @selector(invalidate));
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
            _isHooked = YES;
            if(!_isPressed) [self setPressed:YES];
            [_delegate widget:self did:EGW_ACTION_HOOK];
            
            return YES;
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
    return !(_rFlags & EGW_GFXOBJ_RNDRFLG_ISTRANSPARENT) && ((_rFlags & EGW_GFXOBJ_RNDRFLG_ISOPAQUE) || ((([_base widgetSurfaces]->format & EGW_SURFACE_FRMT_EXAC) ? NO : (!_mStack || [_mStack isOpaque]))));
}

- (BOOL)isTextureDataPersistent {
    return [_base isTextureDataPersistent];
}

- (BOOL)isPressed {
    return _isPressed;
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

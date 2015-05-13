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

/// @file egwSpritedImage.m
/// @ingroup geWizES_gui_spritedimage
/// Animated Sprited Image Asset Implementation.

#import "egwSpritedImage.h"
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
#import "../obj/egwObjectBranch.h"
#import "../phy/egwInterpolators.h"
#import "../misc/egwValidater.h"


// !!!: ***** egwSpritedImage *****

@implementation egwSpritedImage

static egwTextureJumpTable _egwTJT = { NULL };

+ (id)allocWithZone:(NSZone*)zone {
    NSObject* inst = (NSObject*)[super allocWithZone:zone];
    
    if(!_egwTJT.fpTBind && [inst isMemberOfClass:[egwSpritedImage class]]) {
        _egwTJT.fpTBind = (BOOL(*)(id, SEL, EGWuint, EGWuint))[inst methodForSelector:@selector(bindForTexturingStage:withFlags:)];
        _egwTJT.fpTUnbind = (BOOL(*)(id, SEL, EGWuint))[inst methodForSelector:@selector(unbindTexturingWithFlags:)];
        _egwTJT.fpTBase = (id<NSObject>(*)(id, SEL))[inst methodForSelector:@selector(textureBase)];
        _egwTJT.fpTSync = (egwValidater*(*)(id, SEL))[inst methodForSelector:@selector(texturingSync)];
        _egwTJT.fpTLBStage = (EGWuint(*)(id, SEL))[inst methodForSelector:@selector(lastTexturingBindingStage)];
    }
    
    return (id)inst;
}

- (id)init {
    if([self isMemberOfClass:[egwSpritedImage class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent spriteSurfaces:(egwSurface*)surfaces surfaceFramings:(egwSurfaceFraming*)framings surfaceCount:(EGWuint16)srfcCount spriteWidth:(EGWuint16)width spriteHeight:(EGWuint16)height spriteFPS:(EGWsingle)fps instanceGeometryStorage:(EGWuint)instStorage baseGeometryStorage:(EGWuint)baseStorage textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwSpritedImageBase alloc] initWithIdentity:assetIdent spriteSurfaces:surfaces surfaceFramings:framings surfaceCount:srfcCount spriteWidth:width spriteHeight:height geometryStorage:baseStorage texturingTransforms:transforms texturingFilter:filter])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _rFlags = EGW_GFXOBJ_RNDRFLG_DFLT;
    _rFrame = EGW_FRAME_ALWAYSPASS;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = (lghtStack ? [lghtStack retain] : [[egwLightStack alloc] init]))) { [self release]; return (self = nil); }
    if(!(_mStack = (mtrlStack ? [mtrlStack retain] : [[egwSIEngine defaultMaterialStack] retain]))) { [self release]; return (self = nil); }
    
    _isEnabled = _isVisible = YES;
    _fIndex = _sIndex = -1;
    _sFPS = fps;
    
    _geoStrg = instStorage;
    if(!(_gbSync = [[egwValidater alloc] initWithOwner:self validation:(_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES) coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    
    _lastTBind = NSNotFound;
    _texEnv = environment;
    if(!(_tSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    if(!(_wcsRBVol = [(NSObject*)[_base renderingBounding] copy])) { [self release]; return (self = nil); }
    
    _fCount = [_base frameCount];
    _sCount = [_base surfaceCount];
    _sFrames = [_base widgetFramings];
    _texIDs = [_base textureIDs];
    _mcsTrans = [_base mcsTransform];
    _sMesh = [_base widgetMesh];
    _baseGeoAID = [_base geometryArraysID];
    
    memcpy((void*)&_isMesh, (const void*)&_sMesh->tCoords[0], sizeof(egwVector2f) * (size_t)4); // Temporary init until evaluateTo is called
    
    if((_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && !([egwAIGfxCntxAGL isActive] && [self performSubTaskForComponent:egwAIGfxCntxAGL forSync:_gbSync])) // Attempt to load, if context active on this thread
        [egwAIGfxCntx addSubTask:self forSync:_gbSync]; // Delayed load for context sub task to handle
    
    return self;
}

- (id)initBlankWithIdentity:(NSString*)assetIdent surfaceFormat:(EGWuint32)format spriteWidth:(EGWuint16)width spriteHeight:(EGWuint16)height frameCount:(EGWuint16)frmCount spriteFPS:(EGWsingle)fps instanceGeometryStorage:(EGWuint)instStorage baseGeometryStorage:(EGWuint)baseStorage textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwSpritedImageBase alloc] initBlankWithIdentity:assetIdent surfaceFormat:format spriteWidth:width spriteHeight:height frameCount:frmCount geometryStorage:baseStorage texturingTransforms:transforms texturingFilter:filter])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _rFlags = EGW_GFXOBJ_RNDRFLG_DFLT;
    _rFrame = EGW_FRAME_ALWAYSPASS;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = (lghtStack ? [lghtStack retain] : [[egwLightStack alloc] init]))) { [self release]; return (self = nil); }
    if(!(_mStack = (mtrlStack ? [mtrlStack retain] : [[egwSIEngine defaultMaterialStack] retain]))) { [self release]; return (self = nil); }
    
    _isEnabled = _isVisible = YES;
    _fIndex = _sIndex = -1;
    _sFPS = fps;
    
    _geoStrg = instStorage;
    if(!(_gbSync = [[egwValidater alloc] initWithOwner:self validation:(_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES) coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    
    _lastTBind = NSNotFound;
    _texEnv = environment;
    if(!(_tSync = [[egwValidater alloc] initWithOwner:self validation:YES coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    if(!(_wcsRBVol = [(NSObject*)[_base renderingBounding] copy])) { [self release]; return (self = nil); }
    
    _fCount = [_base frameCount];
    _sCount = [_base surfaceCount];
    _sFrames = [_base widgetFramings];
    _texIDs = [_base textureIDs];
    _mcsTrans = [_base mcsTransform];
    _sMesh = [_base widgetMesh];
    _baseGeoAID = [_base geometryArraysID];
    
    memcpy((void*)&_isMesh, (const void*)&_sMesh->tCoords[0], sizeof(egwVector2f) * (size_t)4); // Temporary init until evaluateTo is called
    
    if((_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && !([egwAIGfxCntxAGL isActive] && [self performSubTaskForComponent:egwAIGfxCntxAGL forSync:_gbSync])) // Attempt to load, if context active on this thread
        [egwAIGfxCntx addSubTask:self forSync:_gbSync]; // Delayed load for context sub task to handle
    
    // NOTE: Delayed load will occur on buffer sync invalidation. -jw
    
    return self;
}

- (id)initLoadedFromResourceFiles:(NSString*)resourceFiles withIdentity:(NSString*)assetIdent spriteWidth:(EGWuint16)width spriteHeight:(EGWuint16)height spriteFPS:(EGWsingle)fps instanceGeometryStorage:(EGWuint)instStorage baseGeometryStorage:(EGWuint)baseStorage textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack {
    egwSurface* surfaces = NULL;
    egwSurfaceFraming* framings = NULL;
    NSArray* resources = [resourceFiles componentsSeparatedByString:@";,"];
    EGWuint16 srfcCount = (EGWuint16)[resources count];
    EGWuint16 frmCount = 0;
    
    if(srfcCount) {
        if(!(surfaces = (egwSurface*)malloc((size_t)srfcCount * sizeof(egwSurface)))) goto ErrorCleanup;
        else memset((void*)surfaces, 0, (size_t)srfcCount * sizeof(egwSurface));
        if(!(framings = (egwSurfaceFraming*)malloc((size_t)srfcCount * sizeof(egwSurfaceFraming)))) goto ErrorCleanup;
        else memset((void*)framings, 0, (size_t)srfcCount * sizeof(egwSurfaceFraming));
        
        for(EGWuint16 sIndex = 0; sIndex < srfcCount; ++sIndex) {
            if(!([egwSIAsstMngr loadSurface:&surfaces[sIndex] fromFile:(NSString*)[resources objectAtIndex:(NSUInteger)sIndex] withTransforms:(transforms & ~EGW_SURFACE_TRFM_ENSRPOW2)])) goto ErrorCleanup;
            
            framings[sIndex].hFrames = surfaces[sIndex].size.span.width / width;
            framings[sIndex].vFrames = surfaces[sIndex].size.span.height / height;
            framings[sIndex].fOffset = frmCount;
            framings[sIndex].fCount = framings[sIndex].hFrames * framings[sIndex].vFrames;
            frmCount += framings[sIndex].fCount;
            framings[sIndex].htSizer = (EGWdouble)((EGWuint)width * (EGWuint)framings[sIndex].hFrames) / (EGWdouble)surfaces[sIndex].size.span.width / (EGWdouble)framings[sIndex].hFrames;
            framings[sIndex].vtSizer = (EGWdouble)((EGWuint)height * (EGWuint)framings[sIndex].vFrames) / (EGWdouble)surfaces[sIndex].size.span.height / (EGWdouble)framings[sIndex].vFrames;
        }
        
        if(!(self = [self initWithIdentity:assetIdent spriteSurfaces:surfaces surfaceFramings:framings surfaceCount:srfcCount spriteWidth:width spriteHeight:height spriteFPS:fps instanceGeometryStorage:(EGWuint)instStorage baseGeometryStorage:(EGWuint)baseStorage textureEnvironment:environment texturingTransforms:(transforms | EGW_SURFACE_TRFM_ENSRPOW2) texturingFilter:filter lightStack:lghtStack materialStack:mtrlStack])) goto ErrorCleanup;
    } else goto ErrorCleanup;
    
    return self;
    
ErrorCleanup:
    if(surfaces) {
        for(EGWuint16 sIndex = 0; sIndex < srfcCount; ++sIndex)
            egwSrfcFree(&surfaces[sIndex]);
        free((void*)surfaces); surfaces = NULL;
    }
    if(framings) {
        free((void*)framings); framings = NULL;
    }
    [self release]; return (self = nil);
}

- (id)initCopyOf:(id<egwPWidget>)widget withIdentity:(NSString*)assetIdent {
    if(!([widget isKindOfClass:[self class]]) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = (egwSpritedImageBase*)[[(egwSpritedImage*)widget assetBase] retain])) { [self release]; return (self = nil); }
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _rFlags = [(egwSpritedImage*)widget renderingFlags];
    _rFrame = EGW_FRAME_ALWAYSPASS;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = [[widget lightStack] retain])) { [self release]; return (self = nil); }
    if(!(_mStack = [[widget materialStack] retain])) { [self release]; return (self = nil); }
    
    _isEnabled = _isVisible = YES;
    _fIndex = _sIndex = -1;
    _sFPS = [(egwSpritedImage*)widget spriteFPS];
    
    _geoStrg = [(egwSpritedImage*)widget geometryStorage];
    if(!(_gbSync = [[egwValidater alloc] initWithOwner:self validation:(_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES) coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    
    _lastTBind = NSNotFound;
    _texEnv = [widget textureEnvironment];
    if(!(_tSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    
    egwMatCopy44f([(egwSpritedImage*)widget wcsTransform], &_wcsTrans);
    egwMatCopy44f([(egwSpritedImage*)widget lcsTransform], &_lcsTrans);
    if(!(_wcsRBVol = [(NSObject*)[(egwSpritedImage*)widget renderingBounding] copy])) { [self release]; return (self = nil); }
    if([(id<egwPOrientated>)widget offsetDriver] && ![self trySetOffsetDriver:[(id<egwPOrientated>)widget offsetDriver]]) { [self release]; return (self = nil); }
    if([(id<egwPOrientated>)widget orientateDriver] && ![self trySetOrientateDriver:[(id<egwPOrientated>)widget orientateDriver]]) { [self release]; return (self = nil); }
    
    _fCount = [_base frameCount];
    _sCount = [_base surfaceCount];
    _sFrames = [_base widgetFramings];
    _texIDs = [_base textureIDs];
    _mcsTrans = [_base mcsTransform];
    _sMesh = [_base widgetMesh];
    _baseGeoAID = [_base geometryArraysID];
    
    memcpy((void*)&_isMesh, (const void*)&_sMesh->tCoords[0], sizeof(egwVector2f) * (size_t)4); // Temporary init until evaluateTo is called
    
    [self setEvaluationTimer:[(egwSpritedImage*)widget evaluationTimer]];
    
    if((_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && !([egwAIGfxCntxAGL isActive] && [self performSubTaskForComponent:egwAIGfxCntxAGL forSync:_gbSync])) // Attempt to load, if context active on this thread
        [egwAIGfxCntx addSubTask:self forSync:_gbSync]; // Delayed load for context sub task to handle
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwSpritedImage* copy = nil;
    NSString* copyIdent = nil;
    
    if([_ident hasSuffix:@"_default"])
        copyIdent = [[NSString alloc] initWithFormat:@"%@_%d", [_base identity], [_base nextInstanceIndex]];
    else copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwSpritedImage allocWithZone:zone] initCopyOf:self
                                                    withIdentity:copyIdent])) {
        NSLog(@"egwSpritedImage: copyWithZone: Failure initializing new image from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    return copy;
}

- (void)dealloc {
    if(_eTimer) [self setEvaluationTimer:nil];
    if(_isTBound) [self unbindTexturingWithFlags:EGW_BNDOBJ_BINDFLG_DFLT];
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
    _sMesh = NULL;
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
        
        if(_texIDs && *_texIDs && (*_texIDs)[_sIndex]) {
            egw_glBindTexture(texture, GL_TEXTURE_2D, (GLuint)(*_texIDs)[_sIndex]);
            //glFinish();
        } else return NO;
        
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

- (void)evaluateToTime:(EGWtime)absT {
    EGWint16 oldFIndex = _fIndex;
    EGWint16 oldSIndex = _sIndex;
    _fIndex = (EGWuint16)((EGWsingle)absT * (EGWsingle)_sFPS);
    if(_fIndex >= _fCount) _fIndex = _fCount - 1;
    if(_sIndex == -1) _sIndex = 0;
    
    // FIXME: Write this the better way so that it does O(log n) search to the right screen index. -jw
    
    if(_fIndex > oldFIndex) { // Going forward
        while(!(_fIndex >= _sFrames[_sIndex].fOffset && _fIndex < _sFrames[_sIndex].fOffset + _sFrames[_sIndex].fCount))
            _sIndex = (_sIndex + 1) % _sCount;
        
        egwWdgtSFrmtTexOffset(&_sFrames[_sIndex], _fIndex, &_isMesh.stCoords[0]);
    } else if(_fIndex < oldFIndex) { // Going backward
        while(!(_fIndex >= _sFrames[_sIndex].fOffset && _fIndex < _sFrames[_sIndex].fOffset + _sFrames[_sIndex].fCount))
            _sIndex = (_sIndex + _sCount - 1) % _sCount;
        
        egwWdgtSFrmtTexOffset(&_sFrames[_sIndex], _fIndex, &_isMesh.stCoords[0]);
    }
    
    if(_sIndex != oldSIndex)
        egwSFPVldtrInvalidate(_tSync, @selector(invalidate));
    if((_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && _fIndex != oldFIndex || _sIndex != oldSIndex)
        egwSFPVldtrInvalidate(_gbSync, @selector(invalidate));
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
                NSLog(@"egwSpritedImage: performSubTaskForComponent:forSync: Failure buffering instance geometry mesh for asset '%@' (%p).", _ident, self);
            
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
        if(_isVisible && _fIndex != -1) {
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
                        glVertexPointer((GLint)3, GL_FLOAT, (GLsizei)0, (const GLvoid*)&_sMesh->vCoords[0]);
                        glNormalPointer(GL_FLOAT, (GLsizei)0, (const GLvoid*)&_sMesh->nCoords[0]);
                    }
                }
                
                if(_geoAID) {
                    egw_glBindBuffer(GL_ARRAY_BUFFER, _geoAID);
                    
                    glTexCoordPointer((GLint)2, GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)0);
                } else {
                    egw_glBindBuffer(GL_ARRAY_BUFFER, 0);
                    
                    glTexCoordPointer((GLint)2, GL_FLOAT, (GLsizei)0, (const GLvoid*)&_isMesh.stCoords[0]);
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
        
        egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
        
        if(_delegate)
            [_delegate widget:self did:EGW_ACTION_STOP];
    }
}

- (id<egwPAssetBase>)assetBase {
    return (id<egwPAssetBase>)_base;
}

- (EGWuint)coreObjectTypes {
    return (EGW_COREOBJ_TYPE_GRAPHIC | EGW_COREOBJ_TYPE_ORIENTABLE | EGW_COREOBJ_TYPE_TEXTURE | EGW_COREOBJ_TYPE_WIDGET);
}

- (EGWtime)evaluatedAtTime {
    return (_fIndex >= 0 ? (EGWtime)_fIndex * (EGWtime)_sFPS : EGW_TIME_NAN);
}

- (EGWtime)evaluationBoundsBegin {
    return (EGWtime)0.0f;
}

- (EGWtime)evaluationBoundsEnd {
    return (EGWtime)_fCount / (EGWtime)_sFPS;
}

- (id<egwPTimer>)evaluationTimer {
    return _eTimer;
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

- (EGWsingle)spriteFPS {
    return _sFPS;
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

- (void)setDelegate:(id<egwDWidgetEvent>)delegate {
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
            NSLog(@"egwSpritedImage: setParent: Warning: Object system is overriding WCS interpolator driver for instance asset '%@' (%p).", _ident, self);
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
}

- (void)setEvaluationTimer:(id<egwPTimer>)timer {
    [timer retain];
    [_eTimer removeOwner:self];
    [_eTimer release];
    _eTimer = timer;
    [_eTimer addOwner:self];
}

- (void)setSpriteFPS:(EGWsingle)fps {
    _sFPS = fps;
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
	   _parent && !_invkParent && ![_parent isInvokingChild]) {
		_invkParent = YES;
		EGWuint cmpntTypes = (_rFlags & EGW_OBJTREE_FLG_NOUMRGFRAMES ? 0 : EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_GRAPHIC);
		if(cmpntTypes)
			[_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
		_invkParent = NO;
	}
}

- (void)setVisible:(BOOL)visible {
    _isVisible = visible;
    
    egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
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

- (BOOL)isOpaque {
    return !(_rFlags & EGW_GFXOBJ_RNDRFLG_ISTRANSPARENT) && ((_rFlags & EGW_GFXOBJ_RNDRFLG_ISOPAQUE) || ((([_base widgetSurfaces]->format & EGW_SURFACE_FRMT_EXAC) ? NO : (!_mStack || [_mStack isOpaque]))));
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
    }
}

@end


// !!!: ***** egwSpritedImageBase *****

@implementation egwSpritedImageBase

+ (id)allocWithZone:(NSZone*)zone {
    id alloc = [super allocWithZone:zone];
    if(alloc) [egwAssetManager incBaseRef];
    if(EGW_ENGINE_ASSETS_CREATIONMSGS) NSLog(@"egwSpritedImageBase: allocWithZone: Creating new image base asset (%p).", alloc);
        return alloc;
}

- (id)init {
    if([self isMemberOfClass:[egwSpritedImageBase class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent spriteSurfaces:(egwSurface*)surfaces surfaceFramings:(egwSurfaceFraming*)framings surfaceCount:(EGWuint16)srfcCount spriteWidth:(EGWuint16)width spriteHeight:(EGWuint16)height geometryStorage:(EGWuint)storage texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter {
    egwSize2i maxTexSize; memcpy((void*)&maxTexSize, (const void*)[egwAIGfxCntx maxTextureSize], sizeof(egwSize2i));
    
    if(!(surfaces && framings && srfcCount && (self = [super init]))) { [self release]; return (self = nil); }
    for(EGWuint16 sIndex = 0; sIndex < srfcCount; ++sIndex) {
        if(!(surfaces[sIndex].data && !(surfaces[sIndex].format & EGW_SURFACE_FRMT_EXPLT) &&
             surfaces[sIndex].size.span.width <= maxTexSize.span.width && surfaces[sIndex].size.span.height <= maxTexSize.span.height)) { [self release]; return (self = nil); }
    }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _fCount = 0;
    _sCount = srfcCount;
    
    if(!(_sSrfcs = (egwSurface*)malloc((size_t)_sCount * sizeof(egwSurface)))) { [self release]; return (self = nil); }
    else memset((void*)_sSrfcs, 0, (size_t)_sCount * sizeof(egwSurface));
    if(!(_sFrames = (egwSurfaceFraming*)malloc((size_t)_sCount * sizeof(egwSurfaceFraming)))) { [self release]; return (self = nil); }
    else memset((void*)_sFrames, 0, (size_t)_sCount * sizeof(egwSurfaceFraming));
    if(!(_texIDs = (EGWuint*)malloc((size_t)_sCount * sizeof(EGWuint)))) { [self release]; return (self = nil); }
    else memset((void*)_texIDs, 0, (size_t)_sCount * sizeof(EGWuint));
    
    _geoStrg = storage;
    if(!(_gbSync = [[egwValidater alloc] initWithOwner:self validation:(_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES) coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    
    if(!(_tbSync = [[egwValidater alloc] initWithOwner:self validation:NO coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    _texTrans = transforms;
    _texFltr = filter;
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_mcsTrans);
    if(!(_mmcsRBVol = [[egwBoundingBox alloc] init])) { [self release]; return (self = nil); }
    
    for(EGWuint16 sIndex = 0; sIndex < _sCount; ++sIndex) {
        memcpy((void*)&_sSrfcs[sIndex], (const void*)&surfaces[sIndex], sizeof(egwSurface));
        memset((void*)(const void*)&surfaces[sIndex], 0, sizeof(egwSurface));
        memcpy((void*)&_sFrames[sIndex], (const void*)&framings[sIndex], sizeof(egwSurfaceFraming));
        _fCount += _sFrames[sIndex].fCount;
        _texIDs[sIndex] = NSNotFound;
    }
    
    // Assign appropriate width and height (or auto-assign)
    // NOTE: This auto-assignment won't be accurate in the case of pre-upscaled-to-pow2 images. No fix possible. -jw
    {   register EGWuint16 autoWidth = _sSrfcs[0].size.span.width / _sFrames[0].hFrames;
        register EGWuint16 autoHeight = _sSrfcs[0].size.span.height / _sFrames[0].vFrames;
        
        if(!width || width > autoWidth) width = autoWidth;
        if(!height || height > autoHeight) height = autoHeight;
    }
    
    _sSize.span.width = width;
    _sSize.span.height = height;
    
    // Smudge extend to power-of-2 surfaces
    for(EGWuint16 sIndex = 0; sIndex < _sCount; ++sIndex) {
        if(!(_sSrfcs[sIndex].format & EGW_SURFACE_FRMT_EXCMPRSD) &&
           !(egwIsPow2ui((EGWuint)_sSrfcs[sIndex].size.span.width) && egwIsPow2ui((EGWuint)_sSrfcs[sIndex].size.span.height))) {
            if(!(egwSrfcSmdgExtd((EGWuint16)egwRoundUpPow2ui((EGWuint)_sSrfcs[sIndex].size.span.width),
                                 (EGWuint16)egwRoundUpPow2ui((EGWuint)_sSrfcs[sIndex].size.span.height),
                                 &_sSrfcs[sIndex], &_sSrfcs[sIndex]))) { [self release]; return (self = nil); }
            else { // Readjust framing sizers after resize
                _sFrames[sIndex].htSizer = (EGWdouble)((EGWuint)_sSize.span.width * (EGWuint)_sFrames[sIndex].hFrames) / (EGWdouble)_sSrfcs[sIndex].size.span.width / (EGWdouble)_sFrames[sIndex].hFrames;
                _sFrames[sIndex].vtSizer = (EGWdouble)((EGWuint)_sSize.span.height * (EGWuint)_sFrames[sIndex].vFrames) / (EGWdouble)_sSrfcs[sIndex].size.span.height / (EGWdouble)_sFrames[sIndex].vFrames;
            }
        }
    }
    
    egwWdgtMeshBVInit(&_sMesh, _mmcsRBVol, NO, &_sSize, &_sSize); // Tex coords -> 1.0, overidden by parent
    
    if(!([egwAIGfxCntxAGL isActive] && [self performSubTaskForComponent:egwAIGfxCntxAGL forSync:_tbSync])) // Attempt to load, if context active on this thread
        [egwAIGfxCntx addSubTask:self forSync:_tbSync]; // Delayed load for context sub task to handle
    
    if((_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && !([egwAIGfxCntxAGL isActive] && [self performSubTaskForComponent:egwAIGfxCntxAGL forSync:_gbSync])) // Attempt to load, if context active on this thread
        [egwAIGfxCntx addSubTask:self forSync:_gbSync]; // Delayed load for context sub task to handle
    
    return self;
}

- (id)initBlankWithIdentity:(NSString*)assetIdent surfaceFormat:(EGWuint32)format spriteWidth:(EGWuint16)width spriteHeight:(EGWuint16)height frameCount:(EGWuint16)frmCount geometryStorage:(EGWuint)storage texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter {
    egwSize2i maxTexSize; memcpy((void*)&maxTexSize, (const void*)[egwAIGfxCntx maxTextureSize], sizeof(egwSize2i));
    
    if(!(width && width <= maxTexSize.span.width && height && height <= maxTexSize.span.height && frmCount >= 2 && (self = [super init]))) { [self release]; return (self = nil); }
    if(!format) format = EGW_SURFACE_FRMT_R8G8B8A8;
    format = egwFormatFromSrfcTrfm(transforms, format);
    if(!(format == EGW_SURFACE_FRMT_GS8 || format == EGW_SURFACE_FRMT_GS8A8 || format == EGW_SURFACE_FRMT_R5G6B5 || format == EGW_SURFACE_FRMT_R5G5B5A1 || format == EGW_SURFACE_FRMT_R4G4B4A4 || format == EGW_SURFACE_FRMT_R8G8B8 || format == EGW_SURFACE_FRMT_R8G8B8A8)) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _sSize.span.width = width;
    _sSize.span.height = height;
    
    _fCount = 0;
    if(!(_sCount = egwWdgtMinFSprtSrfcCount(&_sSize, &maxTexSize, frmCount))) { [self release]; return (self = nil); } // too big a sprite
    
    if(!(_sSrfcs = (egwSurface*)malloc((size_t)_sCount * sizeof(egwSurface)))) { [self release]; return (self = nil); }
    else memset((void*)_sSrfcs, 0, (size_t)_sCount * sizeof(egwSurface));
    if(!(_sFrames = (egwSurfaceFraming*)malloc((size_t)_sCount * sizeof(egwSurfaceFraming)))) { [self release]; return (self = nil); }
    else memset((void*)_sFrames, 0, (size_t)_sCount * sizeof(egwSurfaceFraming));
    if(!(_texIDs = (EGWuint*)malloc((size_t)_sCount * sizeof(EGWuint)))) { [self release]; return (self = nil); }
    else memset((void*)_texIDs, 0, (size_t)_sCount * sizeof(EGWuint));
    
    _geoStrg = storage;
    if(!(_gbSync = [[egwValidater alloc] initWithOwner:self validation:(_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES) coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    
    if(!(_tbSync = [[egwValidater alloc] initWithOwner:self validation:YES coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    _texTrans = transforms;
    _texFltr = filter;
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_mcsTrans);
    if(!(_mmcsRBVol = [[egwBoundingBox alloc] init])) { [self release]; return (self = nil); }
    
    // Determine frame count, best size per surface, and allocations
    for(EGWuint16 sIndex = 0; sIndex < _sCount; ++sIndex) {
        egwSize2i bestSize;
        
        if(!(_sFrames[sIndex].fCount = egwWdgtOptPow2FSprtSfrcSize(&_sSize, &maxTexSize, frmCount, &bestSize))) { [self release]; return (self = nil); }
        if(!(egwSrfcAlloc(&_sSrfcs[sIndex], format, egwRoundUpPow2ui16(bestSize.span.width), egwRoundUpPow2ui16(bestSize.span.height), (EGWuint16)egwBytePackingFromSrfcTrfm(transforms, EGW_SURFACE_DFLTBPACKING)))) { [self release]; return (self = nil); }
        _sFrames[sIndex].hFrames = bestSize.span.width / _sSize.span.width;
        _sFrames[sIndex].vFrames = bestSize.span.height / _sSize.span.height;
        if(_sFrames[sIndex].fCount != _sFrames[sIndex].hFrames * _sFrames[sIndex].vFrames) { [self release]; return (self = nil); }
        frmCount -= _sFrames[sIndex].fCount;
        _sFrames[sIndex].fOffset = _fCount;
        _fCount += _sFrames[sIndex].fCount;
        _sFrames[sIndex].htSizer = (EGWdouble)((EGWuint)_sSize.span.width * (EGWuint)_sFrames[sIndex].hFrames) / (EGWdouble)_sSrfcs[sIndex].size.span.width / (EGWdouble)_sFrames[sIndex].hFrames;
        _sFrames[sIndex].vtSizer = (EGWdouble)((EGWuint)_sSize.span.height * (EGWuint)_sFrames[sIndex].vFrames) / (EGWdouble)_sSrfcs[sIndex].size.span.height / (EGWdouble)_sFrames[sIndex].vFrames;
        _texIDs[sIndex] = NSNotFound;
    }
    
    egwWdgtMeshBVInit(&_sMesh, _mmcsRBVol, NO, &_sSize, &_sSize); // Tex coords -> 1.0, overidden by parent
    
    if((_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && !([egwAIGfxCntxAGL isActive] && [self performSubTaskForComponent:egwAIGfxCntxAGL forSync:_gbSync])) // Attempt to load, if context active on this thread
        [egwAIGfxCntx addSubTask:self forSync:_gbSync]; // Delayed load for context sub task to handle
    
    // NOTE: Delayed load will occur on buffer sync invalidation. -jw
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    return nil;
}

- (id)mutableCopyWithZone:(NSZone*)zone {
    return nil;
}

- (void)dealloc {
    if(_texIDs) {
        for(EGWuint16 sIndex = 0; sIndex < _sCount; ++sIndex)
            if(_texIDs[sIndex] && _texIDs[sIndex] != NSNotFound)
                _texIDs[sIndex] = [egwAIGfxCntxAGL returnUsedTextureID:_texIDs[sIndex]];
        free((void*)_texIDs); _texIDs = NULL;
    }
    if(_geoAID)
        _geoAID = [egwAIGfxCntxAGL returnUsedBufferID:_geoAID];
    
    if(_sSrfcs) {
        for(EGWuint16 sIndex = 0; sIndex < _sCount; ++sIndex)
            egwSrfcFree(&_sSrfcs[sIndex]);
        free((void*)_sSrfcs); _sSrfcs = NULL;
    }
    
    if(_sFrames) {
        free((void*)_sFrames); _sFrames = NULL;
    }
    
    [_tbSync release]; _tbSync = nil;
    
    [_gbSync release]; _gbSync = nil;
    
    [_mmcsRBVol release]; _mmcsRBVol = nil;
    
    if(EGW_ENGINE_ASSETS_DESTROYMSGS) NSLog(@"egwSpritedImageBase: dealloc: Destroying image base asset '%@' (%p).", _ident, self);
    [_ident release]; _ident = nil;
    [egwAssetManager decBaseRef];
    [super dealloc];
}

- (void)baseOffsetByTransform:(const egwMatrix44f*)transform {
    egwMatMultiply44f(&_mcsTrans, transform, &_mcsTrans);
    [_mmcsRBVol baseOffsetByTransform:transform];
}

- (void)baseOffsetByZeroAlign:(EGWuint)zfAlign {
    egwVector3f offset, min, max;
    egwMatrix44f transform;
    
    // NOTE: Since mesh is not directly transformed by _mcsTrans and vCoords are distortion offsetted -> rebuild vCoords get offsets. -jw
    
    {   egwVector3f vCoords[4];
        EGWsingle thalfWidth = (EGWsingle)_sSize.span.width * 0.5f;
        EGWsingle thalfHeight = (EGWsingle)_sSize.span.height * 0.5f;
        vCoords[0].axis.x = -thalfWidth; vCoords[0].axis.y = -thalfHeight; vCoords[0].axis.z = 0.0f;
        vCoords[1].axis.x =  thalfWidth; vCoords[1].axis.y = -thalfHeight; vCoords[1].axis.z = 0.0f;
        vCoords[2].axis.x =  thalfWidth; vCoords[2].axis.y =  thalfHeight; vCoords[2].axis.z = 0.0f;
        vCoords[3].axis.x = -thalfWidth; vCoords[3].axis.y =  thalfHeight; vCoords[3].axis.z = 0.0f;
        egwVecTransform443fv(&_mcsTrans, (egwVector3f*)&vCoords, &egwSIOnef, (egwVector3f*)&vCoords, -sizeof(egwMatrix44f), 0, -sizeof(EGWsingle), 0, 4);
        egwVecFindExtentsAxs3fv((egwVector3f*)&vCoords, &min, &max, 0, 4);
    }
    
    switch(zfAlign & EGW_GFXOBJ_ZFALIGN_EXX) {
        case EGW_GFXOBJ_ZFALIGN_XMIN: {
            offset.axis.x = -min.axis.x;
        } break;
        case EGW_GFXOBJ_ZFALIGN_XCTR: {
            offset.axis.x = -((min.axis.x + max.axis.x) * 0.5f);
        } break;
        case EGW_GFXOBJ_ZFALIGN_XMAX: {
            offset.axis.x = -max.axis.x;
        } break;
        default: offset.axis.x = 0.0f;
    }
    
    switch(zfAlign & EGW_GFXOBJ_ZFALIGN_EXY) {
        case EGW_GFXOBJ_ZFALIGN_YMIN: {
            offset.axis.y = -min.axis.y;
        } break;
        case EGW_GFXOBJ_ZFALIGN_YCTR: {
            offset.axis.y = -((min.axis.y + max.axis.y) * 0.5f);
        } break;
        case EGW_GFXOBJ_ZFALIGN_YMAX: {
            offset.axis.y = -max.axis.y;
        } break;
        default: offset.axis.y = 0.0f;
    }
    
    switch(zfAlign & EGW_GFXOBJ_ZFALIGN_EXZ) {
        case EGW_GFXOBJ_ZFALIGN_ZMIN: {
            offset.axis.z = -min.axis.z;
        } break;
        case EGW_GFXOBJ_ZFALIGN_ZCTR: {
            offset.axis.z = -((min.axis.z + max.axis.z) * 0.5f);
        } break;
        case EGW_GFXOBJ_ZFALIGN_ZMAX: {
            offset.axis.z = -max.axis.z;
        } break;
        default: offset.axis.z = 0.0f;
    }
    
    egwMatTranslate44f(NULL, &offset, &transform);
    if(zfAlign & EGW_GFXOBJ_ZFALIGN_EXINV)
        egwMatScale44fs(&transform, (zfAlign & EGW_GFXOBJ_ZFALIGN_XINV ? -1.0f : 1.0f), (zfAlign & EGW_GFXOBJ_ZFALIGN_YINV ? -1.0f : 1.0f), (zfAlign & EGW_GFXOBJ_ZFALIGN_ZINV ? -1.0f : 1.0f), &transform);
        
        [self baseOffsetByTransform:&transform];
}

- (BOOL)performSubTaskForComponent:(id<NSObject>)component forSync:(egwValidater*)sync {
    if((id)component == (id)egwAIGfxCntxAGL) {
        if(_tbSync == sync && _sSrfcs) {
            for(EGWuint16 sIndex = 0; sIndex < _sCount; ++sIndex) {
                if(_sSrfcs[sIndex].data) {
                    egwSurface usageSurface; memcpy((void*)&usageSurface, (const void*)&_sSrfcs[sIndex], sizeof(egwSurface));
                    
                    if(_isTDPersist && (_texFltr & EGW_TEXTURE_FLTR_EXDSTRYP)) {
                        // Use temporary space for texture filters that destroy surface if persistence needs to be maintained
                        if(!(usageSurface.data = (EGWbyte*)malloc(((size_t)usageSurface.pitch * (size_t)usageSurface.size.span.height)))) {
                            NSLog(@"egwSpritedImageBase: performSubTaskForComponent:forSync: Failure allocating %d bytes for temporary image surface. Failure buffering widget texture #%d/%d for asset '%@' (%p).", ((size_t)usageSurface.pitch * (size_t)usageSurface.size.span.height), (EGWuint)sIndex+1, (EGWuint)_sCount, _ident, self);
                            return NO;
                        } else
                            memcpy((void*)usageSurface.data, (const void*)_sSrfcs[sIndex].data, ((size_t)usageSurface.pitch * (size_t)usageSurface.size.span.height));
                    }
                    
                    if([egwAIGfxCntxAGL loadTextureID:&_texIDs[sIndex] withSurface:&usageSurface texturingTransforms:_texTrans texturingFilter:_texFltr texturingSWrap:EGW_TEXTURE_WRAP_CLAMP texturingTWrap:EGW_TEXTURE_WRAP_CLAMP]) {
                        if(usageSurface.data && usageSurface.data != _sSrfcs[sIndex].data) {
                            free((void*)usageSurface.data); usageSurface.data = NULL;
                        }
                        
                        continue; // Done with this item, on to next
                    } else
                        NSLog(@"egwSpritedImageBase: performSubTaskForComponent:forSync: Failure buffering widget texture #%d/%d for asset '%@' (%p).", (EGWuint)sIndex+1, (EGWuint)_sCount, _ident, self);
                    
                    if(usageSurface.data && usageSurface.data != _sSrfcs[sIndex].data) {
                        free((void*)usageSurface.data); usageSurface.data = NULL;
                    }
                    
                    return NO; // Failure to load, try again next time
                }
            }
            
            egwSFPVldtrValidate(_tbSync, @selector(validate)); // Event delegate will dealloc if not persistent
            
            return YES; // Finished with sub task
        } else if(_gbSync == sync && (_geoStrg & EGW_GEOMETRY_STRG_EXVBO)) {
            if([egwAIGfxCntxAGL loadBufferArraysID:&_geoAID withRawData:(const EGWbyte*)&_sMesh dataSize:((EGWuint)sizeof(egwVector3f) * 4 * 2) geometryStorage:_geoStrg]) {
                egwSFPVldtrValidate(_gbSync, @selector(validate)); // Event delegate will dealloc if not persistent
                
                return YES; // Done with this item, no other work left
            } else
                NSLog(@"egwSpritedImageBase: performSubTaskForComponent:forSync: Failure buffering base geometry mesh for asset '%@' (%p).", _ident, self);
            
            return NO; // Failure to load, try again next time
        }
    }
    
    return YES; // Nothing to do
}

- (const EGWuint*)geometryArraysID {
    return &_geoAID;
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

- (EGWuint16)frameCount {
    return _fCount;
}

- (EGWuint16)surfaceCount {
    return _sCount;
}

- (const egwMatrix44f*)mcsTransform {
    return &_mcsTrans;
}

- (EGWuint)nextInstanceIndex {
    return ++_instCounter;
}

- (id<egwPBounding>)renderingBounding {
    return _mmcsRBVol;
}

- (egwValidater*)textureBufferSync {
    return _tbSync;
}

- (EGWuint const * const *)textureIDs {
    return (EGWuint const * const *)&_texIDs;
}

- (EGWuint)texturingFilter {
    return _texFltr;
}

- (EGWuint)texturingTransforms {
    return _texTrans;
}

- (EGWuint16)texturingSWrap {
    return EGW_TEXTURE_WRAP_CLAMP;
}

- (EGWuint16)texturingTWrap {
    return EGW_TEXTURE_WRAP_CLAMP;
}

- (const egwSurfaceFraming*)widgetFramings {
    return _sFrames;
}

- (const egwSQVAMesh4f*)widgetMesh {
    return &_sMesh;
}

- (const egwSize2i*)widgetSize {
    return &_sSize;
}

- (const egwSurface*)widgetSurfaces {
    return _sSrfcs;
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

- (BOOL)trySetTextureDataPersistence:(BOOL)persist {
    _isTDPersist = persist;
    
    if(!_isTDPersist && egwSFPVldtrIsValidated(_tbSync, @selector(isValidated))) {
        for(EGWuint16 sIndex = 0; sIndex < _sCount; ++sIndex)
            if(_sSrfcs[sIndex].data) {
                free((void*)_sSrfcs[sIndex].data); _sSrfcs[sIndex].data = NULL;
            }
    }
    
    return YES;
}

- (BOOL)trySetTexturingFilter:(EGWuint)filter {
    if(_sSrfcs) {
        for(EGWuint16 sIndex = 0; sIndex < _sCount; ++sIndex)
            if(!_sSrfcs[sIndex].data)
                return NO;
        
        _texFltr = filter;
        egwSFPVldtrInvalidate(_tbSync, @selector(invalidate));
        return YES;
    }
    
    return NO;
}

- (BOOL)trySetTexturingWrapS:(EGWuint16)sWrap {
    // Not supported
    return NO;
}

- (BOOL)trySetTexturingWrapT:(EGWuint16)tWrap {
    // Not supported
    return NO;
}

- (BOOL)isGeometryDataPersistent {
    return YES;
}

- (BOOL)isTextureDataPersistent {
    return _isTDPersist;
}

- (void)validaterDidValidate:(egwValidater*)validater {
    if(_tbSync == validater) {
        if(!_isTDPersist) { // Persistence check & dealloc
            if(_sSrfcs) {
                // NOTE: The widget surface is still used even after image data is deleted - do not free the surface! -jw
                for(EGWuint16 sIndex = 0; sIndex < _sCount; ++sIndex)
                    if(_sSrfcs[sIndex].data) {
                        free((void*)_sSrfcs[sIndex].data); _sSrfcs[sIndex].data = NULL;
                    }
            }
        }
    }
}

- (void)validaterDidInvalidate:(egwValidater*)validater {
    if(_tbSync == validater) {
        if(_sSrfcs && _sSrfcs[0].data) {
            for(EGWuint16 sIndex = 1; sIndex < _sCount; ++sIndex) // Already checked 0 line before for speed
                if(!_sSrfcs[sIndex].data)
                    return;
            
            // Buffer image data up through context
            [egwAIGfxCntx addSubTask:self forSync:_tbSync];
        } else
            egwSFPVldtrValidate(_tbSync, @selector(validate));
    } else if(_gbSync == validater) {
        if(_geoStrg & EGW_GEOMETRY_STRG_EXVBO) // Buffer mesh data up through context
            [egwAIGfxCntx addSubTask:self forSync:_gbSync];
        else
            egwSFPVldtrValidate(_gbSync, @selector(validate));
    }
}

@end

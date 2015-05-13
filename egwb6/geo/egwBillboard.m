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

/// @file egwBillboard.m
/// @ingroup geWizES_geo_billboard
/// Billboard Asset Implementation.

#import <pthread.h>
#import "egwBillboard.h"
#import "../sys/egwSysTypes.h"
#import "../sys/egwAssetManager.h"
#import "../sys/egwGfxContext.h"
#import "../sys/egwGfxContextNSGL.h"  // NOTE: Below code has a dependence on GL.
#import "../sys/egwGfxContextEAGLES.h"
#import "../sys/egwGfxRenderer.h"
#import "../math/egwVector.h"
#import "../math/egwMatrix.h"
#import "../gfx/egwGraphics.h"
#import "../gfx/egwBindingStacks.h"
#import "../gfx/egwBoundings.h"
#import "../gfx/egwMaterials.h"
#import "../gfx/egwTexture.h"
#import "../geo/egwGeometry.h"
#import "../obj/egwObjectBranch.h"
#import "../phy/egwInterpolators.h"
#import "../misc/egwValidater.h"


// !!!: ***** egwBillboard *****

@implementation egwBillboard

static egwRenderableJumpTable _egwRJT = { NULL };

+ (id)allocWithZone:(NSZone*)zone {
    NSObject* inst = (NSObject*)[super allocWithZone:zone];
    
    if(!_egwRJT.fpRetain && [inst isMemberOfClass:[egwBillboard class]]) {
        _egwRJT.fpRetain = (id(*)(id, SEL))[inst methodForSelector:@selector(retain)];
        _egwRJT.fpRelease = (void(*)(id, SEL))[inst methodForSelector:@selector(release)];
        _egwRJT.fpRender = (void(*)(id, SEL, EGWuint))[inst methodForSelector:@selector(renderWithFlags:)];
        _egwRJT.fpRBase = (id<NSObject>(*)(id, SEL))[inst methodForSelector:@selector(renderingBase)];
        _egwRJT.fpRFlags = (EGWuint32(*)(id, SEL))[inst methodForSelector:@selector(renderingFlags)];
        _egwRJT.fpRFrame = (EGWuint16(*)(id, SEL))[inst methodForSelector:@selector(renderingFrame)];
        _egwRJT.fpRSource = (const egwVector4f*(*)(id, SEL))[inst methodForSelector:@selector(renderingSource)];
        _egwRJT.fpRSync = (egwValidater*(*)(id, SEL))[inst methodForSelector:@selector(renderingSync)];
        _egwRJT.fpLStack = (egwLightStack*(*)(id, SEL))[inst methodForSelector:@selector(lightStack)];
        _egwRJT.fpMStack = (egwMaterialStack*(*)(id, SEL))[inst methodForSelector:@selector(materialStack)];
        _egwRJT.fpSStack = (egwShaderStack*(*)(id, SEL))[inst methodForSelector:@selector(shaderStack)];
        _egwRJT.fpTStack = (egwTextureStack*(*)(id, SEL))[inst methodForSelector:@selector(textureStack)];
        _egwRJT.fpSetRFrame = (void(*)(id, SEL, EGWuint16))[inst methodForSelector:@selector(setRenderingFrame:)];
        _egwRJT.fpOpaque = (BOOL(*)(id, SEL))[inst methodForSelector:@selector(isOpaque)];
        _egwRJT.fpRendering = (BOOL(*)(id, SEL))[inst methodForSelector:@selector(isRendering)];
    }
    
    return (id)inst;
}

- (id)init {
    if([self isMemberOfClass:[egwBillboard class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent staticMesh:(egwSTVAMeshf*)meshData billboardBounding:(Class)bndClass geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack shaderStack:(egwShaderStack*)shdrStack textureStack:(egwTextureStack*)txtrStack {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwBillboardBase alloc] initWithIdentity:assetIdent staticMesh:meshData billboardBounding:bndClass geometryStorage:storage])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _rFlags = EGW_GFXOBJ_RNDRFLG_DFLT;
    _rFrame = EGW_FRAME_ALWAYSPASS;
    _vFrame = EGW_FRAME_ALWAYSFAIL;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = (lghtStack ? [lghtStack retain] : [[egwLightStack alloc] init]))) { [self release]; return (self = nil); }
    if(!(_mStack = (mtrlStack ? [mtrlStack retain] : [[egwSIEngine defaultMaterialStack] retain]))) { [self release]; return (self = nil); }
    _sStack = (shdrStack ? [shdrStack retain] : nil);
    _tStack = (txtrStack ? [txtrStack retain] : nil);
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_broTrans);
    if(!(_wcsRBVol = [(NSObject*)[_base renderingBounding] copy])) { [self release]; return (self = nil); }
    
    _mcsTrans = [_base mcsTransform];
    _bMesh = [_base billboardMesh];
    _geoAID = [_base geometryArraysID];
    
    return self;
}

- (id)initBlankWithIdentity:(NSString*)assetIdent vertexCount:(EGWuint16)vrtxCount geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack shaderStack:(egwShaderStack*)shdrStack textureStack:(egwTextureStack*)txtrStack {
    if(!vrtxCount || vrtxCount % 3 != 0 || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwBillboardBase alloc] initBlankWithIdentity:assetIdent vertexCount:vrtxCount geometryStorage:storage])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _rFlags = EGW_GFXOBJ_RNDRFLG_DFLT;
    _rFrame = EGW_FRAME_ALWAYSPASS;
    _vFrame = EGW_FRAME_ALWAYSFAIL;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = (lghtStack ? [lghtStack retain] : [[egwLightStack alloc] init]))) { [self release]; return (self = nil); }
    if(!(_mStack = (mtrlStack ? [mtrlStack retain] : [[egwSIEngine defaultMaterialStack] retain]))) { [self release]; return (self = nil); }
    _sStack = (shdrStack ? [shdrStack retain] : nil);
    _tStack = (txtrStack ? [txtrStack retain] : nil);
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_broTrans);
    _wcsRBVol = nil; // will require manual rebinding later
    
    _mcsTrans = [_base mcsTransform];
    _bMesh = [_base billboardMesh];
    _geoAID = [_base geometryArraysID];
    
    return self;
}

- (id)initQuadWithIdentity:(NSString*)assetIdent quadWidth:(EGWsingle)quadWidth quadHeight:(EGWsingle)quadHeight billboardBounding:(Class)bndClass geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack shaderStack:(egwShaderStack*)shdrStack textureStack:(egwTextureStack*)txtrStack {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwBillboardBase alloc] initQuadWithIdentity:assetIdent quadWidth:quadWidth quadHeight:quadHeight billboardBounding:bndClass geometryStorage:storage])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _rFlags = EGW_GFXOBJ_RNDRFLG_DFLT;
    _rFrame = EGW_FRAME_ALWAYSPASS;
    _vFrame = EGW_FRAME_ALWAYSFAIL;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = (lghtStack ? [lghtStack retain] : [[egwLightStack alloc] init]))) { [self release]; return (self = nil); }
    if(!(_mStack = (mtrlStack ? [mtrlStack retain] : [[egwSIEngine defaultMaterialStack] retain]))) { [self release]; return (self = nil); }
    _sStack = (shdrStack ? [shdrStack retain] : nil);
    _tStack = (txtrStack ? [txtrStack retain] : nil);
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_broTrans);
    if(!(_wcsRBVol = [(NSObject*)[_base renderingBounding] copy])) { [self release]; return (self = nil); }
    
    _mcsTrans = [_base mcsTransform];
    _bMesh = [_base billboardMesh];
    _geoAID = [_base geometryArraysID];
    
    return self;
}

- (id)initCopyOf:(id<egwPGeometry>)geometry withIdentity:(NSString*)assetIdent {
    if(!([geometry isKindOfClass:[self class]]) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = (egwBillboardBase*)[[(id<egwPAsset>)geometry assetBase] retain])) { [self release]; return (self = nil); }
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _rFlags = [(egwBillboard*)geometry renderingFlags];
    _rFrame = EGW_FRAME_ALWAYSPASS;
    _vFrame = EGW_FRAME_ALWAYSFAIL;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = [[geometry lightStack] retain])) { [self release]; return (self = nil); }
    if(!(_mStack = [[geometry materialStack] retain])) { [self release]; return (self = nil); }
    _sStack = [[geometry shaderStack] retain];
    _tStack = [[geometry textureStack] retain];
    
    egwMatCopy44f([(egwBillboard*)geometry wcsTransform], &_wcsTrans);
    egwMatCopy44f([(egwBillboard*)geometry lcsTransform], &_lcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_broTrans);
    if(!(_wcsRBVol = [(NSObject*)[(egwBillboard*)geometry renderingBounding] copy])) { [self release]; return (self = nil); }
    if([(id<egwPOrientated>)geometry offsetDriver] && ![self trySetOffsetDriver:[(id<egwPOrientated>)geometry offsetDriver]]) { [self release]; return (self = nil); }
    if([(id<egwPOrientated>)geometry orientateDriver] && ![self trySetOrientateDriver:[(id<egwPOrientated>)geometry orientateDriver]]) { [self release]; return (self = nil); }
    
    _mcsTrans = [_base mcsTransform];
    _bMesh = [_base billboardMesh];
    _geoAID = [_base geometryArraysID];
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwBillboard* copy = nil;
    NSString* copyIdent = nil;
    
    if([_ident hasSuffix:@"_default"])
        copyIdent = [[NSString alloc] initWithFormat:@"%@_%d", [_base identity], [_base nextInstanceIndex]];
    else copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwBillboard allocWithZone:zone] initCopyOf:self
                                                 withIdentity:copyIdent])) {
        NSLog(@"egwBillboard: copyWithZone: Failure initializing new billboard from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    return copy;
}

- (void)dealloc {
    _mcsTrans = NULL;
    _bMesh = NULL;
    _geoAID = NULL;
    
    [_wcsRBVol release]; _wcsRBVol = nil;
    
    if(_lcsIpo) { [_lcsIpo removeTargetWithObject:self]; [_lcsIpo release]; _lcsIpo = nil; }
    if(_wcsIpo) { [_wcsIpo removeTargetWithObject:self]; [_wcsIpo release]; _wcsIpo = nil; }
    
    _vCamera = nil;
    _vcwcsTrans = NULL;
    [_lStack release]; _lStack = nil;
    [_mStack release]; _mStack = nil;
    [_sStack release]; _sStack = nil;
    [_tStack release]; _tStack = nil;
    [_rSync release]; _rSync = nil;
    
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
        
        if(!(_rFlags & EGW_OBJEXTEND_FLG_ALWAYSOTGHMG)) {
            egwMatMultiply44f(&_wcsTrans, &_lcsTrans, &_twcsTrans);
            
            EGWsingle det = egwMatDeterminant44f(&_twcsTrans);
            if(egwIsOnef(egwAbsf(det)))
                egwMatInvertOtg44f(&_twcsTrans, &_twcsInverse);
            else
                egwMatInvertDet44f(&_twcsTrans, det, &_twcsInverse);
            
            if(!(_rFlags & EGW_OBJEXTEND_FLG_LAZYBOUNDING)) {
                egwMatrix44f etwcsTrans;
                egwMatMultiply44f(&_twcsTrans, &_broTrans, &etwcsTrans);
                [_wcsRBVol orientateByTransform:&etwcsTrans fromVolume:[_base renderingBounding]];
            } else
                [_wcsRBVol orientateByTransform:&_twcsTrans fromVolume:[_base renderingBounding]];
        } else {
            egwMatMultiplyHmg44f(&_wcsTrans, &_lcsTrans, &_twcsTrans);
            
            egwMatInvertOtg44f(&_twcsTrans, &_twcsInverse);
            
            if(!(_rFlags & EGW_OBJEXTEND_FLG_LAZYBOUNDING)) {
                egwMatrix44f etwcsTrans;
                egwMatMultiplyHmg44f(&_twcsTrans, &_broTrans, &etwcsTrans);
                [_wcsRBVol orientateByTransform:&etwcsTrans fromVolume:[_base renderingBounding]];
            } else
                [_wcsRBVol orientateByTransform:&_twcsTrans fromVolume:[_base renderingBounding]];
        }
        
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

- (void)illuminateWithLight:(id<egwPLight>)light {
    [_lStack addLight:light sortByPosition:(egwVector3f*)[_wcsRBVol boundingOrigin]];
}

- (void)offsetByTransform:(const egwMatrix44f*)lcsTransform {
    egwMatCopy44f(lcsTransform, &_lcsTrans);
    
    _vFrame = EGW_FRAME_ALWAYSFAIL;
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (void)orientateByTransform:(const egwMatrix44f*)wcsTransform {
    egwMatCopy44f(wcsTransform, &_wcsTrans);
    
    _vFrame = EGW_FRAME_ALWAYSFAIL;
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (void)orientateByImpending {
    _vFrame = EGW_FRAME_ALWAYSFAIL;
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (void)reboundWithClass:(Class)bndClass {
    if([_wcsRBVol class] != bndClass) {
        [_wcsRBVol release];
        _wcsRBVol = [[(bndClass && [bndClass conformsToProtocol:@protocol(egwPBounding)] ? bndClass : [egwBoundingSphere class]) alloc] init];
    }
    
    _vFrame = EGW_FRAME_ALWAYSFAIL;
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
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
        // Camera frame check to update BRO transform to always face camera
        {   id<egwPCamera> vCamera = egwAFPGfxCntxActiveCamera(egwAIGfxCntx, @selector(activeCamera));
            EGWuint16 vFrame = egwAFPGfxCntxActiveCameraViewingFrame(egwAIGfxCntx, @selector(activeCameraViewingFrame));
            
            if(vCamera != _vCamera) {
                _vFrame = EGW_FRAME_ALWAYSFAIL;
                _vCamera = vCamera;
                _vcwcsTrans = [_vCamera wcsTransform];
            }
            
            if(_vFrame == EGW_FRAME_ALWAYSFAIL || vFrame == EGW_FRAME_ALWAYSFAIL ||
               (vFrame != EGW_FRAME_ALWAYSPASS && _vFrame != EGW_FRAME_ALWAYSPASS && _vFrame != vFrame)) {
                if(!(_rFlags & EGW_OBJEXTEND_FLG_ALWAYSOTGHMG))
                    egwMatMultiply44f(&_twcsInverse, _vcwcsTrans, &_broTrans);
                else
                    egwMatMultiplyHmg44f(&_twcsInverse, _vcwcsTrans, &_broTrans);
                _broTrans.component.r1c4 = _broTrans.component.r2c4 = _broTrans.component.r3c4 = 0.0f; // Remove inverse offset
                
                _vFrame = vFrame;
                
                if(!(_rFlags & EGW_OBJEXTEND_FLG_LAZYBOUNDING)) {
                    _ortPending = YES;
                    egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
                    [self applyOrientation];
                }
            }
        }
        
        if(_lStack) egwSFPLghtStckPushAndBindLights(_lStack, @selector(pushAndBindLights));
        else egwAFPGfxCntxBindLights(egwAIGfxCntx, @selector(bindLights));
        if(_mStack) egwSFPMtrlStckPushAndBindMaterials(_mStack, @selector(pushAndBindMaterials));
        else egwAFPGfxCntxBindMaterials(egwAIGfxCntx, @selector(bindMaterials));
        if(_sStack) egwSFPShdrStckPushAndBindShaders(_sStack, @selector(pushAndBindShaders));
        else egwAFPGfxCntxBindShaders(egwAIGfxCntx, @selector(bindShaders));
        if(_tStack) egwSFPTxtrStckPushAndBindTextures(_tStack, @selector(pushAndBindTextures));
        else egwAFPGfxCntxBindTextures(egwAIGfxCntx, @selector(bindTextures));
        glPushMatrix();
        
        glMultMatrixf((const GLfloat*)&_twcsTrans);
        glMultMatrixf((const GLfloat*)&_broTrans);
        glMultMatrixf((const GLfloat*)_mcsTrans);
        
        if(*_geoAID) {
            if(egw_glBindBuffer(GL_ARRAY_BUFFER, *_geoAID) || !(flags & EGW_GFXOBJ_RPLYFLG_SAMELASTBASE)) {
                glVertexPointer((GLint)3, GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)0);
                glNormalPointer(GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)((EGWuint)sizeof(egwVector3f) * (EGWuint)_bMesh->vCount));
                if(_tStack) glTexCoordPointer((GLint)2, GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)((EGWuint)sizeof(egwVector3f) * (EGWuint)_bMesh->vCount * 2));
            }
        } else {
            if(egw_glBindBuffer(GL_ARRAY_BUFFER, 0) || !(flags & EGW_GFXOBJ_RPLYFLG_SAMELASTBASE)) {
                glVertexPointer((GLint)3, GL_FLOAT, (GLsizei)0, (const GLvoid*)_bMesh->vCoords);
                glNormalPointer(GL_FLOAT, (GLsizei)0, (const GLvoid*)_bMesh->nCoords);
                if(_tStack) glTexCoordPointer((GLint)2, GL_FLOAT, (GLsizei)0, (const GLvoid*)_bMesh->tCoords);
            }
        }
        
        glDrawArrays((_bMesh->vCount == 4 ? GL_TRIANGLE_FAN : GL_TRIANGLES), 0, (GLsizei)_bMesh->vCount);
        
        glPopMatrix();
        if(_tStack) egwSFPTxtrStckPopTextures(_tStack, @selector(popTextures));
        if(_sStack) egwSFPShdrStckPopShaders(_sStack, @selector(popShaders));
        if(_mStack) egwSFPMtrlStckPopMaterials(_mStack, @selector(popMaterials));
        if(_lStack) egwSFPLghtStckPopLights(_lStack, @selector(popLights));
    } else if(flags & EGW_GFXOBJ_RPLYFLG_DORENDERSTART) {
        _isRendering = YES;
        
        if(_delegate)
            [_delegate geometry:self did:EGW_ACTION_START];
    } else if(flags & EGW_GFXOBJ_RPLYFLG_DORENDERSTOP) {
        _isRendering = NO;
        
        egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
        
        if(_delegate)
            [_delegate geometry:self did:EGW_ACTION_STOP];
    }
}

- (id<egwPAssetBase>)assetBase {
    return _base;
}

- (EGWuint)coreObjectTypes {
    return (EGW_COREOBJ_TYPE_GRAPHIC | EGW_COREOBJ_TYPE_ORIENTABLE);
}

- (egwValidater*)geometryBufferSync {
    return [_base geometryBufferSync];
}

- (EGWuint)geometryStorage {
    return [_base geometryStorage];
}

- (NSString*)identity {
    return _ident;
}

- (const egwRenderableJumpTable*)renderableJumpTable {
    return &_egwRJT;
}

- (egwLightStack*)lightStack {
    return _lStack;
}

- (egwMaterialStack*)materialStack {
    return _mStack;
}

- (egwShaderStack*)shaderStack {
    return _sStack;
}

- (egwTextureStack*)textureStack {
    return _tStack;
}

- (id<egwPInterpolator>)offsetDriver {
    return _lcsIpo;
}

- (id<egwPInterpolator>)orientateDriver {
    return _wcsIpo;
}

- (id<NSObject>)renderingBase {
    return _base;
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

- (const egwMatrix44f*)lcsTransform {
    return &_lcsTrans;
}

- (const egwMatrix44f*)wcsTransform {
    return &_wcsTrans;
}

- (id<egwPObjectBranch>)parent {
    return _parent;
}

- (id<egwPObjectBranch>)root {
    return (_parent ? [_parent root] : nil);
}

- (void)setDelegate:(id<egwDGeometryEvent>)delegate {
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
            NSLog(@"egwBillboard: setParent: Warning: Object system is overriding WCS interpolator driver for instance asset '%@' (%p).", _ident, self);
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

- (void)setShaderStack:(egwShaderStack*)shdrStack {
    [shdrStack retain];
    [_sStack release];
    _sStack = shdrStack;
    
    egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (void)setTextureStack:(egwTextureStack*)txtrStack {
    [txtrStack retain];
    [_tStack release];
    _tStack = txtrStack;
    
    egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
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

- (BOOL)trySetGeometryDataPersistence:(BOOL)persist {
    return [_base trySetGeometryDataPersistence:persist];
}

- (BOOL)trySetGeometryStorage:(EGWuint)storage {
    return [_base trySetGeometryStorage:storage];
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

- (BOOL)isChildOf:(id<egwPObjectBranch>)parent {
    return (_parent == parent ? YES : NO);
}

- (BOOL)isGeometryDataPersistent {
    return [_base isGeometryDataPersistent];
}

- (BOOL)isInvokingParent {
    return _invkParent;
}

- (BOOL)isLeaf {
    return YES;
}

- (BOOL)isOpaque {
    return !(_rFlags & EGW_GFXOBJ_RNDRFLG_ISTRANSPARENT) && ((_rFlags & EGW_GFXOBJ_RNDRFLG_ISOPAQUE) || ((!_mStack || egwSFPMtrlStckOpaque(_mStack, @selector(isOpaque))) && (!_sStack || egwSFPShdrStckOpaque(_sStack, @selector(isOpaque))) && (!_tStack || egwSFPTxtrStckOpaque(_tStack, @selector(isOpaque)))));
}

- (BOOL)isOrientationPending {
    return _ortPending;
}

- (BOOL)isRendering {
    return _isRendering;
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
    }
}

@end


// !!!: ***** egwBillboardBase *****

@implementation egwBillboardBase

+ (id)allocWithZone:(NSZone*)zone {
    id alloc = [super allocWithZone:zone];
    if(alloc) [egwAssetManager incBaseRef];
    if(EGW_ENGINE_ASSETS_CREATIONMSGS) NSLog(@"egwBillboardBase: allocWithZone: Creating new billboard base asset (%p).", alloc);
    return alloc;
}

- (id)init {
    if([self isMemberOfClass:[egwBillboardBase class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent staticMesh:(egwSTVAMeshf*)meshData billboardBounding:(Class)bndClass geometryStorage:(EGWuint)storage {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    memset((void*)&_bMesh, 0, sizeof(egwSTVAMeshf));
    
    if(meshData && meshData->vCount && meshData->vCoords) {
        memcpy((void*)&_bMesh, (const void*)meshData, sizeof(egwSTVAMeshf));
        memset((void*)meshData, 0, sizeof(egwSTVAMeshf));
    } else { [self release]; return (self = nil); }
    
    _geoStrg = storage;
    if(!(_gbSync = [[egwValidater alloc] initWithOwner:self validation:(_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES) coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    _isGDPersist = (_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES);
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_mcsTrans);
    if(!(_mmcsRBVol = [[(bndClass && [bndClass conformsToProtocol:@protocol(egwPBounding)] ? bndClass : [egwBoundingSphere class]) alloc] initWithOpticalSource:NULL vertexCount:_bMesh.vCount vertexCoords:_bMesh.vCoords vertexCoordsStride:0])) { [self release]; return (self = nil); }
    
    if((_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && !([egwAIGfxCntxAGL isActive] && [self performSubTaskForComponent:egwAIGfxCntxAGL forSync:_gbSync])) // Attempt to load, if context active on this thread
        [egwAIGfxCntx addSubTask:self forSync:_gbSync]; // Delayed load for context sub task to handle
    
    return self;
}

- (id)initBlankWithIdentity:(NSString*)assetIdent vertexCount:(EGWuint16)vrtxCount geometryStorage:(EGWuint)storage {
    if(!vrtxCount || vrtxCount % 3 != 0 || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    memset((void*)&_bMesh, 0, sizeof(egwSTVAMeshf));
    
    if(!egwMeshAllocSTVAf(&_bMesh, vrtxCount, vrtxCount, vrtxCount)) { [self release]; return (self = nil); }
    
    _geoStrg = storage;
    if(!(_gbSync = [[egwValidater alloc] initWithOwner:self validation:YES coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    _isGDPersist = (_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES);
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_mcsTrans);
    _mmcsRBVol = nil; // will require manual rebinding later
    
    // NOTE: Delayed load will occur on buffer sync invalidation. -jw
    
    return self;
}

- (id)initQuadWithIdentity:(NSString*)assetIdent quadWidth:(EGWsingle)quadWidth quadHeight:(EGWsingle)quadHeight billboardBounding:(Class)bndClass geometryStorage:(EGWuint)storage {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    memset((void*)&_bMesh, 0, sizeof(egwSTVAMeshf));
    
    _bMesh.vCount = 4;
    if(!egwMeshAllocSTVAf(&_bMesh, _bMesh.vCount, _bMesh.vCount, _bMesh.vCount)) { [self release]; return (self = nil); }
    
    _geoStrg = storage;
    if(!(_gbSync = [[egwValidater alloc] initWithOwner:self validation:(_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES) coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    _isGDPersist = (_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES);
    
    {   EGWsingle halfWidth = quadWidth * 0.5f;
        EGWsingle halfHeight = quadHeight * 0.5f;
        _bMesh.vCoords[0].axis.x = -halfWidth; _bMesh.vCoords[0].axis.y = -halfHeight; _bMesh.vCoords[0].axis.z = 0.0f; // mm
        _bMesh.vCoords[1].axis.x =  halfWidth; _bMesh.vCoords[1].axis.y = -halfHeight; _bMesh.vCoords[1].axis.z = 0.0f; // Mm
        _bMesh.vCoords[2].axis.x =  halfWidth; _bMesh.vCoords[2].axis.y =  halfHeight; _bMesh.vCoords[2].axis.z = 0.0f; // MM
        _bMesh.vCoords[3].axis.x = -halfWidth; _bMesh.vCoords[3].axis.y =  halfHeight; _bMesh.vCoords[3].axis.z = 0.0f; // mM
    }
    
    _bMesh.nCoords[0].axis.x = -EGW_MATH_1_SQRT3; _bMesh.nCoords[0].axis.y = -EGW_MATH_1_SQRT3; _bMesh.nCoords[0].axis.z = EGW_MATH_1_SQRT3; // mm
    _bMesh.nCoords[1].axis.x =  EGW_MATH_1_SQRT3; _bMesh.nCoords[1].axis.y = -EGW_MATH_1_SQRT3; _bMesh.nCoords[1].axis.z = EGW_MATH_1_SQRT3; // Mm
    _bMesh.nCoords[2].axis.x =  EGW_MATH_1_SQRT3; _bMesh.nCoords[2].axis.y =  EGW_MATH_1_SQRT3; _bMesh.nCoords[2].axis.z = EGW_MATH_1_SQRT3; // MM
    _bMesh.nCoords[3].axis.x = -EGW_MATH_1_SQRT3; _bMesh.nCoords[3].axis.y =  EGW_MATH_1_SQRT3; _bMesh.nCoords[3].axis.z = EGW_MATH_1_SQRT3; // mM
    
    _bMesh.tCoords[0].axis.x = 0.0f; _bMesh.tCoords[0].axis.y = 1.0f; // mm
    _bMesh.tCoords[1].axis.x = 1.0f; _bMesh.tCoords[1].axis.y = 1.0f; // Mm
    _bMesh.tCoords[2].axis.x = 1.0f; _bMesh.tCoords[2].axis.y = 0.0f; // MM
    _bMesh.tCoords[3].axis.x = 0.0f; _bMesh.tCoords[3].axis.y = 0.0f; // mM
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_mcsTrans);
    if(!(_mmcsRBVol = [[(bndClass && [bndClass conformsToProtocol:@protocol(egwPBounding)] ? bndClass : [egwBoundingSphere class]) alloc] initWithOpticalSource:&egwSIVecZero3f vertexCount:_bMesh.vCount vertexCoords:_bMesh.vCoords vertexCoordsStride:0])) { [self release]; return (self = nil); }
    
    if((_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && !([egwAIGfxCntxAGL isActive] && [self performSubTaskForComponent:egwAIGfxCntxAGL forSync:_gbSync])) // Attempt to load, if context active on this thread
        [egwAIGfxCntx addSubTask:self forSync:_gbSync]; // Delayed load for context sub task to handle
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    return nil;
}

- (id)mutableCopyWithZone:(NSZone*)zone {
    return nil;
}

- (void)dealloc {
    if(_geoAID)
        _geoAID = [egwAIGfxCntxAGL returnUsedBufferID:_geoAID];
    
    [_gbSync release]; _gbSync = nil;
    [_mmcsRBVol release]; _mmcsRBVol = nil;
    egwMeshFreeSTVAf(&_bMesh);
    
    if(EGW_ENGINE_ASSETS_DESTROYMSGS) NSLog(@"egwBillboardBase: dealloc: Destroying billboard base asset '%@' (%p).", _ident, self);
    [_ident release]; _ident = nil;
    [egwAssetManager decBaseRef];
    [super dealloc];
}

- (void)baseOffsetByTransform:(const egwMatrix44f*)transform {
    egwMatMultiply44f(&_mcsTrans, transform, &_mcsTrans);
    [_mmcsRBVol baseOffsetByTransform:transform];
}

- (void)baseOffsetByZeroAlign:(EGWuint)zfAlign {
    if(_bMesh.vCoords) {
        egwVector3f offset, min, max;
        egwMatrix44f transform;
        
        egwVecFindExtentsAxs3fv(_bMesh.vCoords, &min, &max, 0, _bMesh.vCount);
        
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
}

- (BOOL)performSubTaskForComponent:(id<NSObject>)component forSync:(egwValidater*)sync {
    if((id)component == (id)egwAIGfxCntxAGL) {
        if(_gbSync == sync && (_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && _bMesh.vCoords) {
            if([egwAIGfxCntxAGL loadBufferArraysID:&_geoAID withSTVAMesh:&_bMesh geometryStorage:_geoStrg]) {
                egwSFPVldtrValidate(_gbSync, @selector(validate)); // Event delegate will dealloc if not persistent
                
                return YES; // Done with this item, no other work left
            } else
                NSLog(@"egwBillboardBase: performSubTaskForComponent:forSync: Failure buffering geometry mesh for asset '%@' (%p).", _ident, self);
            
            return NO; // Failure to load, try again next time
        }
    }
    
    return YES; // Nothing to do
}

- (void)reboundWithClass:(Class)bndClass {
    if(_bMesh.vCoords) {
        [_mmcsRBVol release]; _mmcsRBVol = nil;
        _mmcsRBVol = [[(bndClass && [bndClass conformsToProtocol:@protocol(egwPBounding)] ? bndClass : [egwBoundingSphere class]) alloc] initWithOpticalSource:NULL vertexCount:_bMesh.vCount vertexCoords:_bMesh.vCoords vertexCoordsStride:0];
        [_mmcsRBVol baseOffsetByTransform:&_mcsTrans];
    } else {
        id<egwPBounding> bnd = [[(bndClass && [bndClass conformsToProtocol:@protocol(egwPBounding)] ? bndClass : [egwBoundingSphere class]) alloc] init];
        [bnd orientateByTransform:&egwSIMatIdentity44f fromVolume:_mmcsRBVol];
        [_mmcsRBVol release]; _mmcsRBVol = bnd; bnd = nil;
    }
}

- (egwSTVAMeshf*)billboardMesh {
    return &_bMesh;
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

- (const egwMatrix44f*)mcsTransform {
    return &_mcsTrans;
}

- (EGWuint)nextInstanceIndex {
    return ++_instCounter;
}

- (id<egwPBounding>)renderingBounding {
    return _mmcsRBVol;
}

- (BOOL)trySetGeometryDataPersistence:(BOOL)persist {
    _isGDPersist = persist;
    
    if(!_isGDPersist && egwSFPVldtrIsValidated(_gbSync, @selector(isValidated))) {
        if(_bMesh.vCoords) {
            free((void*)_bMesh.vCoords); _bMesh.vCoords = NULL;
        }
        if(_bMesh.nCoords) {
            free((void*)_bMesh.nCoords); _bMesh.nCoords = NULL;
        }
        if(_bMesh.tCoords) {
            free((void*)_bMesh.tCoords); _bMesh.tCoords = NULL;
        }
    }
    
    return YES;
}

- (BOOL)trySetGeometryStorage:(EGWuint)storage {
    if(_bMesh.vCoords && _bMesh.nCoords) {
        _geoStrg = storage;
        
        egwSFPVldtrInvalidate(_gbSync, @selector(invalidate));
        
        return YES;
    }
    
    return NO;
}

- (BOOL)isGeometryDataPersistent {
    return _isGDPersist;
}

- (void)validaterDidValidate:(egwValidater*)validater {
    if(_gbSync == validater) {
        if(!_isGDPersist && _bMesh.vCoords) { // Persistence check & dealloc
            // NOTE: The geometry mesh stats are still used even after mesh data is deleted - do not free the mesh! -jw
            if(_bMesh.vCoords) {
                free((void*)_bMesh.vCoords); _bMesh.vCoords = NULL;
            }
            if(_bMesh.nCoords) {
                free((void*)_bMesh.nCoords); _bMesh.nCoords = NULL;
            }
            if(_bMesh.tCoords) {
                free((void*)_bMesh.tCoords); _bMesh.tCoords = NULL;
            }
        }
    }
}

- (void)validaterDidInvalidate:(egwValidater*)validater {
    if(_gbSync == validater) {
        if((_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && _bMesh.vCoords) // Buffer mesh data up through context
            [egwAIGfxCntx addSubTask:self forSync:_gbSync];
        else
            egwSFPVldtrValidate(_gbSync, @selector(validate));
    }
}

@end

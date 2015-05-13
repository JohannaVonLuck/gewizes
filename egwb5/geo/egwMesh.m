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

/// @file egwMesh.m
/// @ingroup geWizES_geo_mesh
/// Mesh Asset Implementation.

#import <pthread.h>
#import "egwMesh.h"
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


// !!!: ***** egwMesh *****

@implementation egwMesh

- (id)init {
    if([self isMemberOfClass:[egwMesh class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent staticMesh:(egwSJITVAMeshf*)meshData meshBounding:(Class)bndClass geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack textureStack:(egwTextureStack*)txtrStack {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwMeshBase alloc] initWithIdentity:assetIdent staticMesh:meshData meshBounding:bndClass geometryStorage:storage])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _rFlags = EGW_GFXOBJ_RNDRFLG_DFLT;
    _rFrame = EGW_FRAME_ALWAYSPASS;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = (lghtStack ? [lghtStack retain] : [[egwLightStack alloc] init]))) { [self release]; return (self = nil); }
    if(!(_mStack = (mtrlStack ? [mtrlStack retain] : [[egwSIEngine defaultMaterialStack] retain]))) { [self release]; return (self = nil); }
    _tStack = (txtrStack ? [txtrStack retain] : nil);
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    if(!(_wcsRBVol = [(NSObject*)[_base renderingBounding] copy])) { [self release]; return (self = nil); }
    
    _mcsTrans = [_base mcsTransform];
    _pMesh = [_base staticMesh];
    _geoAID = [_base geometryArraysID];
    _geoEID = [_base geometryElementsID];
    
    return self;
}

- (id)initBlankWithIdentity:(NSString*)assetIdent vertexCount:(EGWuint16)vrtxCount faceCount:(EGWuint16)faceCount geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack textureStack:(egwTextureStack*)txtrStack {
    if(!vrtxCount || !faceCount || vrtxCount > 3 * faceCount || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwMeshBase alloc] initBlankWithIdentity:assetIdent vertexCount:vrtxCount faceCount:faceCount geometryStorage:storage])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _rFlags = EGW_GFXOBJ_RNDRFLG_DFLT;
    _rFrame = EGW_FRAME_ALWAYSPASS;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = (lghtStack ? [lghtStack retain] : [[egwLightStack alloc] init]))) { [self release]; return (self = nil); }
    if(!(_mStack = (mtrlStack ? [mtrlStack retain] : [[egwSIEngine defaultMaterialStack] retain]))) { [self release]; return (self = nil); }
    _tStack = (txtrStack ? [txtrStack retain] : nil);
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    _wcsRBVol = nil; // will require manual rebinding later
    
    _mcsTrans = [_base mcsTransform];
    _pMesh = [_base staticMesh];
    _geoAID = [_base geometryArraysID];
    _geoEID = [_base geometryElementsID];
    
    return self;
}

- (id)initBoxWithIdentity:(NSString*)assetIdent boxWidth:(EGWsingle)width boxHeight:(EGWsingle)height boxDepth:(EGWsingle)depth geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack textureStack:(egwTextureStack*)txtrStack {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwMeshBase alloc] initBoxWithIdentity:assetIdent boxWidth:width boxHeight:height boxDepth:depth hasTexture:(txtrStack ? YES : NO) geometryStorage:storage])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _rFlags = EGW_GFXOBJ_RNDRFLG_DFLT;
    _rFrame = EGW_FRAME_ALWAYSPASS;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = (lghtStack ? [lghtStack retain] : [[egwLightStack alloc] init]))) { [self release]; return (self = nil); }
    if(!(_mStack = (mtrlStack ? [mtrlStack retain] : [[egwSIEngine defaultMaterialStack] retain]))) { [self release]; return (self = nil); }
    _tStack = (txtrStack ? [txtrStack retain] : nil);
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    if(!(_wcsRBVol = [(NSObject*)[_base renderingBounding] copy])) { [self release]; return (self = nil); }
    
    _mcsTrans = [_base mcsTransform];
    _pMesh = [_base staticMesh];
    _geoAID = [_base geometryArraysID];
    _geoEID = [_base geometryElementsID];
    
    return self;
}

- (id)initConeWithIdentity:(NSString*)assetIdent coneRadius:(EGWsingle)radius coneHeight:(EGWsingle)height coneLongitudes:(EGWuint16)lngCuts geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack textureStack:(egwTextureStack*)txtrStack {
    if(lngCuts < 3 || egwIsZerof(radius) || egwIsZerof(height) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwMeshBase alloc] initConeWithIdentity:assetIdent coneRadius:radius coneHeight:height coneLongitudes:lngCuts hasTexture:(txtrStack ? YES : NO) geometryStorage:storage])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _rFlags = EGW_GFXOBJ_RNDRFLG_DFLT;
    _rFrame = EGW_FRAME_ALWAYSPASS;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = (lghtStack ? [lghtStack retain] : [[egwLightStack alloc] init]))) { [self release]; return (self = nil); }
    if(!(_mStack = (mtrlStack ? [mtrlStack retain] : [[egwSIEngine defaultMaterialStack] retain]))) { [self release]; return (self = nil); }
    _tStack = (txtrStack ? [txtrStack retain] : nil);
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    if(!(_wcsRBVol = [(NSObject*)[_base renderingBounding] copy])) { [self release]; return (self = nil); }
    
    _mcsTrans = [_base mcsTransform];
    _pMesh = [_base staticMesh];
    _geoAID = [_base geometryArraysID];
    _geoEID = [_base geometryElementsID];
    
    return self;
}

- (id)initCylinderWithIdentity:(NSString*)assetIdent cylinderRadius:(EGWsingle)radius cylinderHeight:(EGWsingle)height cylinderLongitudes:(EGWuint16)lngCuts geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack textureStack:(egwTextureStack*)txtrStack {
    if(lngCuts < 3 || egwIsZerof(radius) || egwIsZerof(height) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwMeshBase alloc] initCylinderWithIdentity:assetIdent cylinderRadius:radius cylinderHeight:height cylinderLongitudes:lngCuts hasTexture:(txtrStack ? YES : NO) geometryStorage:storage])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _rFlags = EGW_GFXOBJ_RNDRFLG_DFLT;
    _rFrame = EGW_FRAME_ALWAYSPASS;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = (lghtStack ? [lghtStack retain] : [[egwLightStack alloc] init]))) { [self release]; return (self = nil); }
    if(!(_mStack = (mtrlStack ? [mtrlStack retain] : [[egwSIEngine defaultMaterialStack] retain]))) { [self release]; return (self = nil); }
    _tStack = (txtrStack ? [txtrStack retain] : nil);
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    if(!(_wcsRBVol = [(NSObject*)[_base renderingBounding] copy])) { [self release]; return (self = nil); }
    
    _mcsTrans = [_base mcsTransform];
    _pMesh = [_base staticMesh];
    _geoAID = [_base geometryArraysID];
    _geoEID = [_base geometryElementsID];
    
    return self;
}

- (id)initPyramidWithIdentity:(NSString*)assetIdent pyramidWidth:(EGWsingle)width pyramidHeight:(EGWsingle)height pyramidDepth:(EGWsingle)depth geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack textureStack:(egwTextureStack*)txtrStack {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwMeshBase alloc] initPyramidWithIdentity:assetIdent pyramidWidth:width pyramidHeight:height pyramidDepth:depth hasTexture:(txtrStack ? YES : NO) geometryStorage:storage])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _rFlags = EGW_GFXOBJ_RNDRFLG_DFLT;
    _rFrame = EGW_FRAME_ALWAYSPASS;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = (lghtStack ? [lghtStack retain] : [[egwLightStack alloc] init]))) { [self release]; return (self = nil); }
    if(!(_mStack = (mtrlStack ? [mtrlStack retain] : [[egwSIEngine defaultMaterialStack] retain]))) { [self release]; return (self = nil); }
    _tStack = (txtrStack ? [txtrStack retain] : nil);
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    if(!(_wcsRBVol = [(NSObject*)[_base renderingBounding] copy])) { [self release]; return (self = nil); }
    
    _mcsTrans = [_base mcsTransform];
    _pMesh = [_base staticMesh];
    _geoAID = [_base geometryArraysID];
    _geoEID = [_base geometryElementsID];
    
    return self;
}

- (id)initSphereWithIdentity:(NSString*)assetIdent sphereRadius:(EGWsingle)radius sphereLongitudes:(EGWuint16)lngCuts sphereLatitudes:(EGWuint16)latCuts geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack textureStack:(egwTextureStack*)txtrStack {
    if(lngCuts < 3 || latCuts < 3 || egwIsZerof(radius) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwMeshBase alloc] initSphereWithIdentity:assetIdent sphereRadius:radius sphereLongitudes:lngCuts sphereLatitudes:latCuts hasTexture:(txtrStack ? YES : NO) geometryStorage:storage])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _rFlags = EGW_GFXOBJ_RNDRFLG_DFLT;
    _rFrame = EGW_FRAME_ALWAYSPASS;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = (lghtStack ? [lghtStack retain] : [[egwLightStack alloc] init]))) { [self release]; return (self = nil); }
    if(!(_mStack = (mtrlStack ? [mtrlStack retain] : [[egwSIEngine defaultMaterialStack] retain]))) { [self release]; return (self = nil); }
    _tStack = (txtrStack ? [txtrStack retain] : nil);
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    if(!(_wcsRBVol = [(NSObject*)[_base renderingBounding] copy])) { [self release]; return (self = nil); }
    
    _mcsTrans = [_base mcsTransform];
    _pMesh = [_base staticMesh];
    _geoAID = [_base geometryArraysID];
    _geoEID = [_base geometryElementsID];
    
    return self;
}

- (id)initCopyOf:(id<egwPGeometry>)geometry withIdentity:(NSString*)assetIdent {
    if(!([geometry isKindOfClass:[self class]]) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = (egwMeshBase*)[[(id<egwPAsset>)geometry assetBase] retain])) { [self release]; return (self = nil); }
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _rFlags = [(egwMesh*)geometry renderingFlags];
    _rFrame = EGW_FRAME_ALWAYSPASS;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = [[geometry lightStack] retain])) { [self release]; return (self = nil); }
    if(!(_mStack = [[geometry materialStack] retain])) { [self release]; return (self = nil); }
    _tStack = [[geometry textureStack] retain];
    
    egwMatCopy44f([(egwMesh*)geometry wcsTransform], &_wcsTrans);
    egwMatCopy44f([(egwMesh*)geometry lcsTransform], &_lcsTrans);
    if(!(_wcsRBVol = [(NSObject*)[(egwMesh*)geometry renderingBounding] copy])) { [self release]; return (self = nil); }
    if([(id<egwPOrientated>)geometry offsetDriver] && ![self trySetOffsetDriver:[(id<egwPOrientated>)geometry offsetDriver]]) { [self release]; return (self = nil); }
    if([(id<egwPOrientated>)geometry orientateDriver] && ![self trySetOrientateDriver:[(id<egwPOrientated>)geometry orientateDriver]]) { [self release]; return (self = nil); }
    
    _mcsTrans = [_base mcsTransform];
    _pMesh = [_base staticMesh];
    _geoAID = [_base geometryArraysID];
    _geoEID = [_base geometryElementsID];
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwMesh* copy = nil;
    NSString* copyIdent = nil;
    
    if([_ident hasSuffix:@"_default"])
        copyIdent = [[NSString alloc] initWithFormat:@"%@_%d", [_base identity], [_base nextInstanceIndex]];
    else copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwMesh allocWithZone:zone] initCopyOf:self
                                            withIdentity:copyIdent])) {
        NSLog(@"egwMesh: copyWithZone: Failure initializing new mesh from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    return copy;
}

- (void)dealloc {
    _mcsTrans = NULL;
    _pMesh = NULL;
    _geoAID = NULL;
    _geoEID = NULL;
    
    [_wcsRBVol release]; _wcsRBVol = nil;
    
    if(_lcsIpo) { [_lcsIpo removeTargetWithObject:self]; [_lcsIpo release]; _lcsIpo = nil; }
    if(_wcsIpo) { [_wcsIpo removeTargetWithObject:self]; [_wcsIpo release]; _wcsIpo = nil; }
    
    [_tStack release]; _tStack = nil;
    [_mStack release]; _mStack = nil;
    [_lStack release]; _lStack = nil;
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

- (void)reboundWithClass:(Class)bndClass {
    if([_wcsRBVol class] != bndClass) {
        [_wcsRBVol release];
        _wcsRBVol = [[(bndClass && [bndClass conformsToProtocol:@protocol(egwPBounding)] ? bndClass : [egwBoundingSphere class]) alloc] init];
    }
    
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
        if(_lStack) egwSFPLghtStckPushAndBindLights(_lStack, @selector(pushAndBindLights));
        else egwAFPGfxCntxBindLights(egwAIGfxCntx, @selector(bindLights));
        if(_mStack) egwSFPMtrlStckPushAndBindMaterials(_mStack, @selector(pushAndBindMaterials));
        else egwAFPGfxCntxBindMaterials(egwAIGfxCntx, @selector(bindMaterials));
        if(_tStack) egwSFPTxtrStckPushAndBindTextures(_tStack, @selector(pushAndBindTextures));
        else egwAFPGfxCntxBindTextures(egwAIGfxCntx, @selector(bindTextures));
        glPushMatrix();
        
        glMultMatrixf((const GLfloat*)&_wcsTrans);
        glMultMatrixf((const GLfloat*)&_lcsTrans);
        glMultMatrixf((const GLfloat*)_mcsTrans);
        
        if(*_geoAID && *_geoEID) {
            if(egw_glBindBuffer(GL_ARRAY_BUFFER, *_geoAID) || !(flags & EGW_GFXOBJ_RPLYFLG_SAMELASTBASE)) {
                glVertexPointer((GLint)3, GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)0);
                glNormalPointer(GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)((EGWuint)sizeof(egwVector3f) * (EGWuint)_pMesh->vCount));
                if(_tStack) glTexCoordPointer((GLint)2, GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)((EGWuint)sizeof(egwVector3f) * (EGWuint)_pMesh->vCount * 2));
            }
            
            egw_glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, *_geoEID);
            
            glDrawElements(GL_TRIANGLES, (GLsizei)(_pMesh->fCount * 3), GL_UNSIGNED_SHORT, (const GLvoid*)(EGWuintptr)0);
        } else {
            if(egw_glBindBuffer(GL_ARRAY_BUFFER, 0) || !(flags & EGW_GFXOBJ_RPLYFLG_SAMELASTBASE)) {
                glVertexPointer((GLint)3, GL_FLOAT, (GLsizei)0, (const GLvoid*)_pMesh->vCoords);
                glNormalPointer(GL_FLOAT, (GLsizei)0, (const GLvoid*)_pMesh->nCoords);
                if(_tStack) glTexCoordPointer((GLint)2, GL_FLOAT, (GLsizei)0, (const GLvoid*)_pMesh->tCoords);
            }
            
            egw_glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
            
            glDrawElements(GL_TRIANGLES, (GLsizei)(_pMesh->fCount * 3), GL_UNSIGNED_SHORT, (const GLvoid*)_pMesh->fIndicies);
        }
        
        glPopMatrix();
        if(_tStack) egwSFPTxtrStckPopTextures(_tStack, @selector(popTextures));
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

- (egwLightStack*)lightStack {
    return _lStack;
}

- (egwMaterialStack*)materialStack {
    return _mStack;
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
            NSLog(@"egwMesh: setParent: Warning: Object system is overriding WCS interpolator driver for instance asset '%@' (%p).", _ident, self);
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
    return !(_rFlags & EGW_GFXOBJ_RNDRFLG_ISTRANSPARENT) && ((_rFlags & EGW_GFXOBJ_RNDRFLG_ISOPAQUE) || ((!_mStack || [_mStack isOpaque]) && (!_tStack || [_tStack isOpaque])));
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


// !!!: ***** egwMeshBase *****

@implementation egwMeshBase

+ (id)allocWithZone:(NSZone*)zone {
    id alloc = [super allocWithZone:zone];
    if(alloc) [egwAssetManager incBaseRef];
    if(EGW_ENGINE_ASSETS_CREATIONMSGS) NSLog(@"egwMeshBase: allocWithZone: Creating new static mesh base asset (%p).", alloc);
    return alloc;
}

- (id)init {
    if([self isMemberOfClass:[egwMeshBase class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent staticMesh:(egwSJITVAMeshf*)meshData meshBounding:(Class)bndClass geometryStorage:(EGWuint)storage {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    if(meshData && meshData->vCount && meshData->fCount && meshData->vCount <= meshData->fCount * 3 && meshData->vCoords && meshData->fIndicies) {
        memcpy((void*)&_pMesh, (const void*)meshData, sizeof(egwSJITVAMeshf));
        memset((void*)meshData, 0, sizeof(egwSJITVAMeshf));
    } else { [self release]; return (self = nil); }
    
    _geoStrg = storage;
    if(!(_gbSync = [[egwValidater alloc] initWithOwner:self validation:(_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES) coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    _isGDPersist = (_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES);
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_mcsTrans);
    if(!(_mmcsRBVol = [[(bndClass && [bndClass conformsToProtocol:@protocol(egwPBounding)] ? bndClass : [egwBoundingSphere class]) alloc] initWithOpticalSource:NULL vertexCount:(_pMesh.vCount) vertexCoords:&(_pMesh.vCoords[0]) vertexCoordsStride:0])) { [self release]; return (self = nil); }
    
    if((_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && !([egwAIGfxCntxAGL isActive] && [self performSubTaskForComponent:egwAIGfxCntxAGL forSync:_gbSync])) // Attempt to load, if context active on this thread
        [egwAIGfxCntx addSubTask:self forSync:_gbSync]; // Delayed load for context sub task to handle
    
    return self;
}

- (id)initBlankWithIdentity:(NSString*)assetIdent vertexCount:(EGWuint16)vrtxCount faceCount:(EGWuint16)faceCount geometryStorage:(EGWuint)storage {
    if(!vrtxCount || !faceCount || vrtxCount > 3 * faceCount || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    if(!egwMeshAllocSJITVAf(&_pMesh, vrtxCount, vrtxCount, vrtxCount, faceCount)) { [self release]; return (self = nil); }
    
    _geoStrg = storage;
    if(!(_gbSync = [[egwValidater alloc] initWithOwner:self validation:YES coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    _isGDPersist = (_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES);
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_mcsTrans);
    _mmcsRBVol = nil; // will require manual rebinding later
    
    // NOTE: Delayed load will occur on buffer sync invalidation. -jw
    
    return self;
}

- (id)initBoxWithIdentity:(NSString*)assetIdent boxWidth:(EGWsingle)width boxHeight:(EGWsingle)height boxDepth:(EGWsingle)depth hasTexture:(BOOL)hasTex geometryStorage:(EGWuint)storage {
    EGWsingle halfWidth, halfHeight, halfDepth;
    EGWint t;
    
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    halfWidth = (width = egwAbsf(width)) * 0.5f;
    halfHeight = (height = egwAbsf(height)) * 0.5f;
    halfDepth = (depth = egwAbsf(depth)) * 0.5f;
    
    _pMesh.vCount = (hasTex ? 16 : 8);  // 2 strips if textured, otherwise 1
    _pMesh.fCount = 12; // 6 sides * 2 polys a side
    if(!egwMeshAllocSJITVAf(&_pMesh, _pMesh.vCount, _pMesh.vCount, (hasTex ? _pMesh.vCount : 0), _pMesh.fCount)) { [self release]; return (self = nil); }
    
    _geoStrg = storage;
    if(!(_gbSync = [[egwValidater alloc] initWithOwner:self validation:(_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES) coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    _isGDPersist = (_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES);
    
    for(t = 0; t <= (hasTex ? 8 : 0); t += 8) {
        _pMesh.vCoords[0+t].axis.x = -halfWidth; _pMesh.vCoords[0+t].axis.y = -halfHeight; _pMesh.vCoords[0+t].axis.z = -halfDepth; /// mmm
        _pMesh.vCoords[1+t].axis.x = -halfWidth; _pMesh.vCoords[1+t].axis.y = -halfHeight; _pMesh.vCoords[1+t].axis.z =  halfDepth; /// mmM
        _pMesh.vCoords[2+t].axis.x = -halfWidth; _pMesh.vCoords[2+t].axis.y =  halfHeight; _pMesh.vCoords[2+t].axis.z = -halfDepth; /// mMm
        _pMesh.vCoords[3+t].axis.x = -halfWidth; _pMesh.vCoords[3+t].axis.y =  halfHeight; _pMesh.vCoords[3+t].axis.z =  halfDepth; /// mMM
        _pMesh.vCoords[4+t].axis.x =  halfWidth; _pMesh.vCoords[4+t].axis.y = -halfHeight; _pMesh.vCoords[4+t].axis.z = -halfDepth; /// Mmm
        _pMesh.vCoords[5+t].axis.x =  halfWidth; _pMesh.vCoords[5+t].axis.y = -halfHeight; _pMesh.vCoords[5+t].axis.z =  halfDepth; /// MmM
        _pMesh.vCoords[6+t].axis.x =  halfWidth; _pMesh.vCoords[6+t].axis.y =  halfHeight; _pMesh.vCoords[6+t].axis.z = -halfDepth; /// MMm
        _pMesh.vCoords[7+t].axis.x =  halfWidth; _pMesh.vCoords[7+t].axis.y =  halfHeight; _pMesh.vCoords[7+t].axis.z =  halfDepth; /// MMM
        
        _pMesh.nCoords[0+t].axis.x = -EGW_MATH_1_SQRT3; _pMesh.nCoords[0+t].axis.y = -EGW_MATH_1_SQRT3; _pMesh.nCoords[0+t].axis.z = -EGW_MATH_1_SQRT3; /// mmm
        _pMesh.nCoords[1+t].axis.x = -EGW_MATH_1_SQRT3; _pMesh.nCoords[1+t].axis.y = -EGW_MATH_1_SQRT3; _pMesh.nCoords[1+t].axis.z =  EGW_MATH_1_SQRT3; /// mmM
        _pMesh.nCoords[2+t].axis.x = -EGW_MATH_1_SQRT3; _pMesh.nCoords[2+t].axis.y =  EGW_MATH_1_SQRT3; _pMesh.nCoords[2+t].axis.z = -EGW_MATH_1_SQRT3; /// mMm
        _pMesh.nCoords[3+t].axis.x = -EGW_MATH_1_SQRT3; _pMesh.nCoords[3+t].axis.y =  EGW_MATH_1_SQRT3; _pMesh.nCoords[3+t].axis.z =  EGW_MATH_1_SQRT3; /// mMM
        _pMesh.nCoords[4+t].axis.x =  EGW_MATH_1_SQRT3; _pMesh.nCoords[4+t].axis.y = -EGW_MATH_1_SQRT3; _pMesh.nCoords[4+t].axis.z = -EGW_MATH_1_SQRT3; /// Mmm
        _pMesh.nCoords[5+t].axis.x =  EGW_MATH_1_SQRT3; _pMesh.nCoords[5+t].axis.y = -EGW_MATH_1_SQRT3; _pMesh.nCoords[5+t].axis.z =  EGW_MATH_1_SQRT3; /// MmM
        _pMesh.nCoords[6+t].axis.x =  EGW_MATH_1_SQRT3; _pMesh.nCoords[6+t].axis.y =  EGW_MATH_1_SQRT3; _pMesh.nCoords[6+t].axis.z = -EGW_MATH_1_SQRT3; /// MMm
        _pMesh.nCoords[7+t].axis.x =  EGW_MATH_1_SQRT3; _pMesh.nCoords[7+t].axis.y =  EGW_MATH_1_SQRT3; _pMesh.nCoords[7+t].axis.z =  EGW_MATH_1_SQRT3; /// MMM
    }
    
    if(hasTex) {
        EGWsingle s = 1.0f / 6.0f;
        _pMesh.tCoords[ 0].axis.x =   0.0f; _pMesh.tCoords[ 0].axis.y = 1.0f; /// mmm S1
        _pMesh.tCoords[ 1].axis.x = s*1.0f; _pMesh.tCoords[ 1].axis.y = 1.0f; /// mmM S1
        _pMesh.tCoords[ 2].axis.x =   0.0f; _pMesh.tCoords[ 2].axis.y = 0.0f; /// mMm S1
        _pMesh.tCoords[ 3].axis.x = s*1.0f; _pMesh.tCoords[ 3].axis.y = 0.0f; /// mMM S1
        _pMesh.tCoords[ 4].axis.x = s*3.0f; _pMesh.tCoords[ 4].axis.y = 1.0f; /// Mmm S1
        _pMesh.tCoords[ 5].axis.x = s*2.0f; _pMesh.tCoords[ 5].axis.y = 1.0f; /// MmM S1
        _pMesh.tCoords[ 6].axis.x = s*3.0f; _pMesh.tCoords[ 6].axis.y = 0.0f; /// MMm S1
        _pMesh.tCoords[ 7].axis.x = s*2.0f; _pMesh.tCoords[ 7].axis.y = 0.0f; /// MMM S1
        _pMesh.tCoords[ 8].axis.x = s*5.0f; _pMesh.tCoords[ 8].axis.y = 0.0f; /// mmm S2
        _pMesh.tCoords[ 9].axis.x =   1.0f; _pMesh.tCoords[ 9].axis.y = 0.0f; /// mmM S2
        _pMesh.tCoords[10].axis.x = s*4.0f; _pMesh.tCoords[10].axis.y = 0.0f; /// mMm S2
        _pMesh.tCoords[11].axis.x = s*3.0f; _pMesh.tCoords[11].axis.y = 0.0f; /// mMM S2
        _pMesh.tCoords[12].axis.x = s*5.0f; _pMesh.tCoords[12].axis.y = 1.0f; /// Mmm S2
        _pMesh.tCoords[13].axis.x =   1.0f; _pMesh.tCoords[13].axis.y = 1.0f; /// MmM S2
        _pMesh.tCoords[14].axis.x = s*4.0f; _pMesh.tCoords[14].axis.y = 1.0f; /// MMm S2
        _pMesh.tCoords[15].axis.x = s*3.0f; _pMesh.tCoords[15].axis.y = 1.0f; /// MMM S2
        t = 8;
    } else t = 0;
    
    _pMesh.fIndicies[ 0].face.i1 = 0; _pMesh.fIndicies[ 0].face.i2 = 1; _pMesh.fIndicies[ 0].face.i3 = 2; // LB
    _pMesh.fIndicies[ 1].face.i1 = 2; _pMesh.fIndicies[ 1].face.i2 = 1; _pMesh.fIndicies[ 1].face.i3 = 3; // LT
    _pMesh.fIndicies[ 2].face.i1 = 1; _pMesh.fIndicies[ 2].face.i2 = 5; _pMesh.fIndicies[ 2].face.i3 = 3; // FB
    _pMesh.fIndicies[ 3].face.i1 = 3; _pMesh.fIndicies[ 3].face.i2 = 5; _pMesh.fIndicies[ 3].face.i3 = 7; // FT
    _pMesh.fIndicies[ 4].face.i1 = 5; _pMesh.fIndicies[ 4].face.i2 = 4; _pMesh.fIndicies[ 4].face.i3 = 7; // RB
    _pMesh.fIndicies[ 5].face.i1 = 7; _pMesh.fIndicies[ 5].face.i2 = 4; _pMesh.fIndicies[ 5].face.i3 = 6; // RT
    _pMesh.fIndicies[ 6].face.i1 = 2+t; _pMesh.fIndicies[ 6].face.i2 = 7+t; _pMesh.fIndicies[ 6].face.i3 = 6+t; // TB
    _pMesh.fIndicies[ 7].face.i1 = 3+t; _pMesh.fIndicies[ 7].face.i2 = 7+t; _pMesh.fIndicies[ 7].face.i3 = 2+t; // TF
    _pMesh.fIndicies[ 8].face.i1 = 4+t; _pMesh.fIndicies[ 8].face.i2 = 0+t; _pMesh.fIndicies[ 8].face.i3 = 6+t; // OB
    _pMesh.fIndicies[ 9].face.i1 = 6+t; _pMesh.fIndicies[ 9].face.i2 = 0+t; _pMesh.fIndicies[ 9].face.i3 = 2+t; // OT
    _pMesh.fIndicies[10].face.i1 = 4+t; _pMesh.fIndicies[10].face.i2 = 1+t; _pMesh.fIndicies[10].face.i3 = 0+t; // BB
    _pMesh.fIndicies[11].face.i1 = 5+t; _pMesh.fIndicies[11].face.i2 = 1+t; _pMesh.fIndicies[11].face.i3 = 4+t; // BF
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_mcsTrans);
    if(!(_mmcsRBVol = [[egwBoundingBox alloc] initWithOpticalSource:&egwSIVecZero3f vertexCount:(_pMesh.vCount) vertexCoords:&(_pMesh.vCoords[0]) vertexCoordsStride:0])) { [self release]; return (self = nil); }
    
    if((_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && !([egwAIGfxCntxAGL isActive] && [self performSubTaskForComponent:egwAIGfxCntxAGL forSync:_gbSync])) // Attempt to load, if context active on this thread
        [egwAIGfxCntx addSubTask:self forSync:_gbSync]; // Delayed load for context sub task to handle
    
    return self;
}

- (id)initConeWithIdentity:(NSString*)assetIdent coneRadius:(EGWsingle)radius coneHeight:(EGWsingle)height coneLongitudes:(EGWuint16)lngCuts hasTexture:(BOOL)hasTex geometryStorage:(EGWuint)storage {
    if(lngCuts < 3 || egwIsZerof(radius) || egwIsZerof(height) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    radius = egwAbsf(radius); height = egwAbsf(height);
    
    EGWuint lngCutsT = lngCuts + (hasTex ? 1 : 0);
    _pMesh.vCount = (lngCuts * 1) + (lngCuts + lngCutsT); // S base (separate) + N/S intermediate side points (+1 if textured)
    _pMesh.fCount = ((lngCuts - 2) * 1) + (lngCuts * 1); // S base fan + intermediate sides (1x per cut, 1 row)
    if(!egwMeshAllocSJITVAf(&_pMesh, _pMesh.vCount, _pMesh.vCount, (hasTex ? _pMesh.vCount : 0), _pMesh.fCount)) { [self release]; return (self = nil); }
    
    _geoStrg = storage;
    if(!(_gbSync = [[egwValidater alloc] initWithOwner:self validation:(_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES) coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    _isGDPersist = (_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES);
    
    {   EGWsingle yaw, yawInc, baseHeight, heightInc;
        EGWuint lat, lng, base, faceIndex = 0;
        
        yawInc = EGW_MATH_2PI / (EGWsingle)lngCuts;
        heightInc = -height;
        baseHeight = -(height *= 0.5f);
        
        // Side vertices
        for(lat = 0, base = 0; lat < 2; ++lat, height += heightInc) {
            for(lng = 0, yaw = -EGW_MATH_PI; lng < lngCuts; ++lng, yaw += yawInc) {
                // Cylindrical -> Cartesian conversion (produces unit-length vectors, set normals first then scale to vertices)
                if(lat == 0) { // N point
                    _pMesh.vCoords[base + lng].axis.x = 0.0f;
                    _pMesh.vCoords[base + lng].axis.y = height;
                    _pMesh.vCoords[base + lng].axis.z = 0.0f;
                    
                    _pMesh.nCoords[base + lng].axis.x = egwCosf(yaw + (yawInc * 0.5f));
                    _pMesh.nCoords[base + lng].axis.y = 3.0f;
                    _pMesh.nCoords[base + lng].axis.z = egwSinf(yaw + (yawInc * 0.5f));
                    egwVecNormalize3f(&_pMesh.nCoords[base + lng], &_pMesh.nCoords[base + lng]);
                } else {
                    _pMesh.nCoords[base + lng].axis.x = egwCosf(yaw);
                    _pMesh.nCoords[base + lng].axis.y = 0.0f;
                    _pMesh.nCoords[base + lng].axis.z = egwSinf(yaw);
                    
                    _pMesh.vCoords[base + lng].axis.x = _pMesh.nCoords[base + lng].axis.x * radius;
                    _pMesh.vCoords[base + lng].axis.y = height;
                    _pMesh.vCoords[base + lng].axis.z = _pMesh.nCoords[base + lng].axis.z * radius;
                }
                
                if(hasTex) {
                    if(lat == 0) { // N point
                        _pMesh.tCoords[base + lng].axis.x = 0.25f;
                        _pMesh.tCoords[base + lng].axis.y = 0.5f;
                    } else {
                        _pMesh.tCoords[base + lng].axis.x = egwClampf(0.25f + (egwCosf(yaw) * 0.25f), 0.0f, 0.5f);
                        _pMesh.tCoords[base + lng].axis.y = egwClamp01f(0.5f + (egwSinf(yaw) * 0.5f));
                    }
                    
                }
                
                // Intermediate sides face connections (down left cover)
                if(base == 0) {
                    _pMesh.fIndicies[faceIndex].face.i1 = base + lngCuts + lng;
                    _pMesh.fIndicies[faceIndex].face.i2 = base + lngCuts + ((lng + 1) % lngCutsT);
                    _pMesh.fIndicies[faceIndex].face.i3 = base + lng;
                    ++faceIndex;
                }
            }
            
            // Special case extra vertex (per cut) pickup when textured
            if(lat == 1 && hasTex) {
                // NOTE: lng = lngCut since out of for loop
                _pMesh.vCoords[base + lng].axis.x = _pMesh.vCoords[base].axis.x;
                _pMesh.vCoords[base + lng].axis.y = _pMesh.vCoords[base].axis.y;
                _pMesh.vCoords[base + lng].axis.z = _pMesh.vCoords[base].axis.z;
                _pMesh.nCoords[base + lng].axis.x = _pMesh.nCoords[base].axis.x;
                _pMesh.nCoords[base + lng].axis.y = _pMesh.nCoords[base].axis.y;
                _pMesh.nCoords[base + lng].axis.z = _pMesh.nCoords[base].axis.z;
                _pMesh.tCoords[base + lng].axis.x = 0.0f;
                _pMesh.tCoords[base + lng].axis.y = _pMesh.tCoords[base].axis.y;
            }
            
            if(lat == 0) 
                base += lngCuts;
            else
                base += lngCutsT;
        }
        
        // Special case extra S base vertices pickup (for independent down vector)
        for(lng = 0, yaw = 0.0f; lng < lngCuts; ++lng, yaw += yawInc) {
            _pMesh.vCoords[base + lng].axis.x = _pMesh.vCoords[base - lngCutsT + lng].axis.x;
            _pMesh.vCoords[base + lng].axis.y = _pMesh.vCoords[base - lngCutsT + lng].axis.y; // copy to avoid FP error gaps
            _pMesh.vCoords[base + lng].axis.z = _pMesh.vCoords[base - lngCutsT + lng].axis.z;
            _pMesh.nCoords[base + lng].axis.x = 0.0f;
            _pMesh.nCoords[base + lng].axis.y = -1.0f;
            _pMesh.nCoords[base + lng].axis.z = 0.0f;
            if(hasTex) {
                // NOTE: There isn't a +1 vertex position needed here since texture is circular
                _pMesh.tCoords[base + lng].axis.x = egwClampf(0.75f - (egwCosf(yaw) * 0.25f), 0.5f, 1.0f);
                _pMesh.tCoords[base + lng].axis.y = egwClamp01f(0.5f + (egwSinf(yaw) * 0.5f));
            }
        }
        
        // Special case S base fan connector faces (lat = 1)
        for(lng = 0; lng < (lngCuts - 2); ++lng, ++faceIndex) {
            _pMesh.fIndicies[faceIndex].face.i1 = base;
            _pMesh.fIndicies[faceIndex].face.i2 = base + (lng + 2);
            _pMesh.fIndicies[faceIndex].face.i3 = base + (lng + 1);
        }
    }
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_mcsTrans);
    if(!(_mmcsRBVol = [[egwBoundingBox alloc] initWithOpticalSource:&egwSIVecZero3f vertexCount:(_pMesh.vCount) vertexCoords:&(_pMesh.vCoords[0]) vertexCoordsStride:0])) { [self release]; return (self = nil); }
    
    if((_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && !([egwAIGfxCntxAGL isActive] && [self performSubTaskForComponent:egwAIGfxCntxAGL forSync:_gbSync])) // Attempt to load, if context active on this thread
        [egwAIGfxCntx addSubTask:self forSync:_gbSync]; // Delayed load for context sub task to handle
    
    return self;
}

- (id)initCylinderWithIdentity:(NSString*)assetIdent cylinderRadius:(EGWsingle)radius cylinderHeight:(EGWsingle)height cylinderLongitudes:(EGWuint16)lngCuts hasTexture:(BOOL)hasTex geometryStorage:(EGWuint)storage {
    if(lngCuts < 3 || egwIsZerof(radius) || egwIsZerof(height) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    radius = egwAbsf(radius); height = egwAbsf(height);
    
    EGWuint lngCutsT = lngCuts + (hasTex ? 1 : 0);
    _pMesh.vCount = (lngCuts * 2) + (lngCutsT * 2); // N/S bases (separate) + N/S intermediate side points (+1 if textured)
    _pMesh.fCount = ((lngCuts - 2) * 2) + (lngCuts * 2); // N/S base fans + intermediate sides (2x per cut, 1 row)
    if(!egwMeshAllocSJITVAf(&_pMesh, _pMesh.vCount, _pMesh.vCount, (hasTex ? _pMesh.vCount : 0), _pMesh.fCount)) { [self release]; return (self = nil); }
    
    _geoStrg = storage;
    if(!(_gbSync = [[egwValidater alloc] initWithOwner:self validation:(_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES) coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    _isGDPersist = (_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES);
    
    {   EGWsingle yaw, yawInc, baseHeight, heightInc;
        EGWuint lat, lng, base, faceIndex = 0;
        
        yawInc = EGW_MATH_2PI / (EGWsingle)lngCuts;
        heightInc = -height;
        baseHeight = -(height *= 0.5f);
        
        // Special case N base fan connector faces (lat = 0)
        for(lng = 0, base = 0; lng < (lngCuts - 2); ++lng, ++faceIndex) {
            _pMesh.fIndicies[faceIndex].face.i1 = base;
            _pMesh.fIndicies[faceIndex].face.i2 = base + (lng + 1);
            _pMesh.fIndicies[faceIndex].face.i3 = base + (lng + 2);
        }
        
        // Side vertices
        for(lat = 0, base = lngCuts; lat < 2; ++lat, height += heightInc, base += lngCutsT) {
            for(lng = 0, yaw = -EGW_MATH_PI; lng < lngCuts; ++lng, yaw += yawInc) {
                // Cylindrical -> Cartesian conversion (produces unit-length vectors, set normals first then scale to vertices)
                _pMesh.nCoords[base + lng].axis.x = egwCosf(yaw);
                _pMesh.nCoords[base + lng].axis.y = 0.0f;
                _pMesh.nCoords[base + lng].axis.z = egwSinf(yaw);
                
                _pMesh.vCoords[base + lng].axis.x = _pMesh.nCoords[base + lng].axis.x * radius;
                _pMesh.vCoords[base + lng].axis.y = height;
                _pMesh.vCoords[base + lng].axis.z = _pMesh.nCoords[base + lng].axis.z * radius;
                
                if(hasTex) {
                    _pMesh.tCoords[base + lng].axis.x = egwClampf(0.5f - (((EGWsingle)lng / (EGWsingle)lngCuts) * 0.5f), 0.0f, 0.5f);
                    _pMesh.tCoords[base + lng].axis.y = (lat == 0 ? 0.0f : 1.0f);
                }
                
                // Intermediate sides face connections (down left cover)
                if(base == 0) {
                    _pMesh.fIndicies[faceIndex].face.i1 = base + lngCutsT + lng;
                    _pMesh.fIndicies[faceIndex].face.i2 = base + lng;
                    _pMesh.fIndicies[faceIndex].face.i3 = base + ((lng + 1) % lngCutsT);
                    ++faceIndex;
                    _pMesh.fIndicies[faceIndex].face.i1 = base + lngCutsT + lng;
                    _pMesh.fIndicies[faceIndex].face.i2 = base + ((lng + 1) % lngCutsT);
                    _pMesh.fIndicies[faceIndex].face.i3 = base + lngCutsT + ((lng + 1) % lngCutsT);
                    ++faceIndex;
                }
            }
            
            // Special case extra vertex (per cut) pickup when textured
            if(hasTex) {
                // NOTE: lng = lngCut since out of for loop
                _pMesh.vCoords[base + lng].axis.x = _pMesh.vCoords[base].axis.x;
                _pMesh.vCoords[base + lng].axis.y = _pMesh.vCoords[base].axis.y;
                _pMesh.vCoords[base + lng].axis.z = _pMesh.vCoords[base].axis.z;
                _pMesh.nCoords[base + lng].axis.x = _pMesh.nCoords[base].axis.x;
                _pMesh.nCoords[base + lng].axis.y = _pMesh.nCoords[base].axis.y;
                _pMesh.nCoords[base + lng].axis.z = _pMesh.nCoords[base].axis.z;
                _pMesh.tCoords[base + lng].axis.x = 0.0f;
                _pMesh.tCoords[base + lng].axis.y = _pMesh.tCoords[base].axis.y;
            }
        }
        
        // Special case extra N base vertices pickup (for independent up vector)
        for(lng = 0, yaw = 0.0f; lng < lngCuts; ++lng, yaw += yawInc) {
            _pMesh.vCoords[lng].axis.x = _pMesh.vCoords[lngCuts + lng].axis.x;
            _pMesh.vCoords[lng].axis.y = _pMesh.vCoords[lngCuts + lng].axis.y; // copy to avoid FP error gaps
            _pMesh.vCoords[lng].axis.z = _pMesh.vCoords[lngCuts + lng].axis.z;
            _pMesh.nCoords[lng].axis.x = 0.0f;
            _pMesh.nCoords[lng].axis.y = 1.0f;
            _pMesh.nCoords[lng].axis.z = 0.0f;
            if(hasTex) {
                // NOTE: There isn't a +1 vertex position needed here since texture is circular
                _pMesh.tCoords[lng].axis.x = egwClampf(0.625f - (egwCosf(yaw) * 0.125f), 0.5f, 0.75f);
                _pMesh.tCoords[lng].axis.y = egwClamp01f(0.5f + (egwSinf(yaw) * 0.5f));
            }
        }
        
        // Special case extra S base vertices pickup (for independent down vector)
        for(lng = 0, yaw = 0.0f; lng < lngCuts; ++lng, yaw += yawInc) {
            _pMesh.vCoords[base + lng].axis.x = _pMesh.vCoords[base - lngCutsT + lng].axis.x;
            _pMesh.vCoords[base + lng].axis.y = _pMesh.vCoords[base - lngCutsT + lng].axis.y; // copy to avoid FP error gaps
            _pMesh.vCoords[base + lng].axis.z = _pMesh.vCoords[base - lngCutsT + lng].axis.z;
            _pMesh.nCoords[base + lng].axis.x = 0.0f;
            _pMesh.nCoords[base + lng].axis.y = -1.0f;
            _pMesh.nCoords[base + lng].axis.z = 0.0f;
            if(hasTex) {
                // NOTE: There isn't a +1 vertex position needed here since texture is circular
                _pMesh.tCoords[base + lng].axis.x = egwClampf(0.875f - (egwCosf(yaw) * 0.125f), 0.75f, 1.0f);
                _pMesh.tCoords[base + lng].axis.y = egwClamp01f(0.5f + (egwSinf(yaw) * 0.5f));
            }
        }
        
        // Special case S base fan connector faces (lat = 1)
        for(lng = 0; lng < (lngCuts - 2); ++lng, ++faceIndex) {
            _pMesh.fIndicies[faceIndex].face.i1 = base;
            _pMesh.fIndicies[faceIndex].face.i2 = base + (lng + 2);
            _pMesh.fIndicies[faceIndex].face.i3 = base + (lng + 1);
        }
    }
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_mcsTrans);
    if(!(_mmcsRBVol = [[egwBoundingBox alloc] initWithOpticalSource:&egwSIVecZero3f vertexCount:(_pMesh.vCount) vertexCoords:&(_pMesh.vCoords[0]) vertexCoordsStride:0])) { [self release]; return (self = nil); }
    
    if((_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && !([egwAIGfxCntxAGL isActive] && [self performSubTaskForComponent:egwAIGfxCntxAGL forSync:_gbSync])) // Attempt to load, if context active on this thread
        [egwAIGfxCntx addSubTask:self forSync:_gbSync]; // Delayed load for context sub task to handle
    
    return self;
}

- (id)initPyramidWithIdentity:(NSString*)assetIdent pyramidWidth:(EGWsingle)width pyramidHeight:(EGWsingle)height pyramidDepth:(EGWsingle)depth hasTexture:(BOOL)hasTex geometryStorage:(EGWuint)storage {
    EGWsingle halfWidth, halfHeight, halfDepth;
    
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    halfWidth = (width = egwAbsf(width)) * 0.5f;
    halfHeight = (height = egwAbsf(height)) * 0.5f;
    halfDepth = (depth = egwAbsf(depth)) * 0.5f;
    
    _pMesh.vCount = 4 + 1 + 4; // Base (always separate) + N pole + edge bases.
    _pMesh.fCount = 4 + 2; // Edges + base
    if(!egwMeshAllocSJITVAf(&_pMesh, _pMesh.vCount, _pMesh.vCount, (hasTex ? _pMesh.vCount : 0), _pMesh.fCount)) { [self release]; return (self = nil); }
    
    _geoStrg = storage;
    if(!(_gbSync = [[egwValidater alloc] initWithOwner:self validation:(_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES) coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    _isGDPersist = (_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES);
    
    _pMesh.vCoords[0].axis.x = 0.0f; _pMesh.vCoords[0].axis.y = halfHeight; _pMesh.vCoords[0].axis.z = 0.0f; // Np
    _pMesh.vCoords[1].axis.x = -halfWidth; _pMesh.vCoords[1].axis.y = -halfHeight; _pMesh.vCoords[1].axis.z =  halfDepth; // mmE
    _pMesh.vCoords[2].axis.x =  halfWidth; _pMesh.vCoords[2].axis.y = -halfHeight; _pMesh.vCoords[2].axis.z =  halfDepth; // MmE
    _pMesh.vCoords[3].axis.x =  halfWidth; _pMesh.vCoords[3].axis.y = -halfHeight; _pMesh.vCoords[3].axis.z = -halfDepth; // MME
    _pMesh.vCoords[4].axis.x = -halfWidth; _pMesh.vCoords[4].axis.y = -halfHeight; _pMesh.vCoords[4].axis.z = -halfDepth; // mME
    _pMesh.vCoords[5].axis.x = -halfWidth; _pMesh.vCoords[5].axis.y = -halfHeight; _pMesh.vCoords[5].axis.z =  halfDepth; // mmB
    _pMesh.vCoords[6].axis.x =  halfWidth; _pMesh.vCoords[6].axis.y = -halfHeight; _pMesh.vCoords[6].axis.z =  halfDepth; // MmB
    _pMesh.vCoords[7].axis.x =  halfWidth; _pMesh.vCoords[7].axis.y = -halfHeight; _pMesh.vCoords[7].axis.z = -halfDepth; // MMB
    _pMesh.vCoords[8].axis.x = -halfWidth; _pMesh.vCoords[8].axis.y = -halfHeight; _pMesh.vCoords[8].axis.z = -halfDepth; // mMB
    
    _pMesh.nCoords[0].axis.x = 0.0f; _pMesh.nCoords[0].axis.y = 1.0f; _pMesh.nCoords[0].axis.z = 0.0f; // Np
    _pMesh.nCoords[1].axis.x = -EGW_MATH_1_SQRT3; _pMesh.nCoords[1].axis.y = EGW_MATH_1_SQRT3; _pMesh.nCoords[1].axis.z =  EGW_MATH_1_SQRT3; // mmE
    _pMesh.nCoords[2].axis.x =  EGW_MATH_1_SQRT3; _pMesh.nCoords[2].axis.y = EGW_MATH_1_SQRT3; _pMesh.nCoords[2].axis.z =  EGW_MATH_1_SQRT3; // MmE
    _pMesh.nCoords[3].axis.x =  EGW_MATH_1_SQRT3; _pMesh.nCoords[3].axis.y = EGW_MATH_1_SQRT3; _pMesh.nCoords[3].axis.z = -EGW_MATH_1_SQRT3; // MME
    _pMesh.nCoords[4].axis.x = -EGW_MATH_1_SQRT3; _pMesh.nCoords[4].axis.y = EGW_MATH_1_SQRT3; _pMesh.nCoords[4].axis.z = -EGW_MATH_1_SQRT3; // mME
    _pMesh.nCoords[5].axis.x = 0.0f; _pMesh.nCoords[5].axis.y = -1.0f; _pMesh.nCoords[5].axis.z = 0.0f; // mmB
    _pMesh.nCoords[6].axis.x = 0.0f; _pMesh.nCoords[6].axis.y = -1.0f; _pMesh.nCoords[6].axis.z = 0.0f; // MmB
    _pMesh.nCoords[7].axis.x = 0.0f; _pMesh.nCoords[7].axis.y = -1.0f; _pMesh.nCoords[7].axis.z = 0.0f; // MMB
    _pMesh.nCoords[8].axis.x = 0.0f; _pMesh.nCoords[8].axis.y = -1.0f; _pMesh.nCoords[8].axis.z = 0.0f; // mMB
    
    if(hasTex) {
        _pMesh.tCoords[0].axis.x = 0.25f; _pMesh.tCoords[0].axis.y = 0.5f; // Np
        _pMesh.tCoords[1].axis.x = 0.0f; _pMesh.tCoords[1].axis.y = 0.0f; // mmE
        _pMesh.tCoords[2].axis.x = 0.5f; _pMesh.tCoords[2].axis.y = 0.0f; // MmE
        _pMesh.tCoords[3].axis.x = 0.5f; _pMesh.tCoords[3].axis.y = 0.1f; // MME
        _pMesh.tCoords[4].axis.x = 0.0f; _pMesh.tCoords[4].axis.y = 0.1f; // mME
        _pMesh.tCoords[5].axis.x = 0.5f; _pMesh.tCoords[5].axis.y = 0.0f; // mmB
        _pMesh.tCoords[6].axis.x = 1.0f; _pMesh.tCoords[6].axis.y = 0.0f; // MmB
        _pMesh.tCoords[7].axis.x = 1.0f; _pMesh.tCoords[7].axis.y = 0.1f; // MMB
        _pMesh.tCoords[8].axis.x = 0.5f; _pMesh.tCoords[8].axis.y = 0.1f; // mMB
    }
    
    _pMesh.fIndicies[0].face.i1 = 0; _pMesh.fIndicies[0].face.i1 = 1; _pMesh.fIndicies[0].face.i1 = 2; // EF
    _pMesh.fIndicies[1].face.i1 = 0; _pMesh.fIndicies[1].face.i1 = 2; _pMesh.fIndicies[1].face.i1 = 3; // ER
    _pMesh.fIndicies[2].face.i1 = 0; _pMesh.fIndicies[2].face.i1 = 3; _pMesh.fIndicies[2].face.i1 = 4; // EB
    _pMesh.fIndicies[3].face.i1 = 0; _pMesh.fIndicies[3].face.i1 = 4; _pMesh.fIndicies[3].face.i1 = 1; // EL
    _pMesh.fIndicies[4].face.i1 = 5; _pMesh.fIndicies[4].face.i1 = 7; _pMesh.fIndicies[4].face.i1 = 6; // B1
    _pMesh.fIndicies[5].face.i1 = 5; _pMesh.fIndicies[5].face.i1 = 8; _pMesh.fIndicies[5].face.i1 = 7; // B2
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_mcsTrans);
    if(!(_mmcsRBVol = [[egwBoundingBox alloc] initWithOpticalSource:&egwSIVecZero3f vertexCount:(_pMesh.vCount) vertexCoords:&(_pMesh.vCoords[0]) vertexCoordsStride:0])) { [self release]; return (self = nil); }
    
    if((_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && !([egwAIGfxCntxAGL isActive] && [self performSubTaskForComponent:egwAIGfxCntxAGL forSync:_gbSync])) // Attempt to load, if context active on this thread
        [egwAIGfxCntx addSubTask:self forSync:_gbSync]; // Delayed load for context sub task to handle
    
    return self;
}

- (id)initSphereWithIdentity:(NSString*)assetIdent sphereRadius:(EGWsingle)radius sphereLongitudes:(EGWuint16)lngCuts sphereLatitudes:(EGWuint16)latCuts hasTexture:(BOOL)hasTex geometryStorage:(EGWuint)storage {
    if(lngCuts < 3 || latCuts < 3 || egwIsZerof(radius) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    radius = egwAbsf(radius);
    
    EGWuint lngCutsT = lngCuts + (hasTex ? 1 : 0);
    _pMesh.vCount = 2 + ((latCuts - 2) * lngCutsT); // N/S pole point + side points per intermediate latitude cut (+1 if textured)
    _pMesh.fCount = (lngCuts * 2) + ((latCuts - 3) * (lngCuts * 2)); // N/S pole connectors + intermediate latitude sides (2x per cut)
    if(!egwMeshAllocSJITVAf(&_pMesh, _pMesh.vCount, _pMesh.vCount, (hasTex ? _pMesh.vCount : 0), _pMesh.fCount)) { [self release]; return (self = nil); }
    
    _geoStrg = storage;
    if(!(_gbSync = [[egwValidater alloc] initWithOwner:self validation:(_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES) coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    _isGDPersist = (_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES);
    
    {   EGWsingle yaw, pitch, yawInc, pitchInc, cosPitch, sinPitch;
        EGWuint lat, lng, base, faceIndex = 0;
        
        yawInc = EGW_MATH_2PI / (EGWsingle)lngCuts;
        pitchInc = EGW_MATH_PI / (EGWsingle)(latCuts - 1);
        
        // Special case N/S poles
        _pMesh.vCoords[0].axis.x = 0.0f; _pMesh.vCoords[0].axis.y = radius; _pMesh.vCoords[0].axis.z = 0.0f;
        _pMesh.nCoords[0].axis.x = 0.0f; _pMesh.nCoords[0].axis.y = 1.0f; _pMesh.nCoords[0].axis.z = 0.0f;
        _pMesh.vCoords[_pMesh.vCount-1].axis.x = 0.0f; _pMesh.vCoords[_pMesh.vCount-1].axis.y = -radius; _pMesh.vCoords[_pMesh.vCount-1].axis.z = 0.0f;
        _pMesh.nCoords[_pMesh.vCount-1].axis.x = 0.0f; _pMesh.nCoords[_pMesh.vCount-1].axis.y = -1.0f; _pMesh.nCoords[_pMesh.vCount-1].axis.z = 0.0f;
        if(hasTex) {
            _pMesh.tCoords[0].axis.x = 0.5f; _pMesh.tCoords[0].axis.y = 1.0f;
            _pMesh.tCoords[_pMesh.vCount-1].axis.x = 0.5f; _pMesh.tCoords[_pMesh.vCount-1].axis.y = 0.0f;
        }
        
        // Special case N pole connector faces (lat = 0)
        for(lng = 0, base = 1; lng < lngCuts; ++lng, ++faceIndex) {
            _pMesh.fIndicies[faceIndex].face.i1 = base + lng;
            _pMesh.fIndicies[faceIndex].face.i2 = 0;
            _pMesh.fIndicies[faceIndex].face.i3 = base + ((lng + 1) % lngCutsT);
        }
        
        // Side vertices
        for(lat = 1, pitch = pitchInc; lat < (latCuts - 1); ++lat, pitch += pitchInc, base += lngCutsT) {
            cosPitch = egwCosf(pitch);
            sinPitch = egwSinf(pitch);
            
            for(lng = 0, yaw = -EGW_MATH_PI; lng < lngCuts; ++lng, yaw += yawInc) {
                // Spherical -> Cartesian conversion (produces unit-length vectors, set normals first then scale to vertices)
                _pMesh.nCoords[base + lng].axis.x = egwCosf(yaw) * sinPitch;
                _pMesh.nCoords[base + lng].axis.y = cosPitch;
                _pMesh.nCoords[base + lng].axis.z = egwSinf(yaw) * sinPitch;
                
                _pMesh.vCoords[base + lng].axis.x = _pMesh.nCoords[base + lng].axis.x * radius;
                _pMesh.vCoords[base + lng].axis.y = _pMesh.nCoords[base + lng].axis.y * radius;
                _pMesh.vCoords[base + lng].axis.z = _pMesh.nCoords[base + lng].axis.z * radius;
                
                if(hasTex) {
                    _pMesh.tCoords[base + lng].axis.x = egwClamp01f((EGWsingle)lng / (EGWsingle)lngCuts);
                    if(lng) _pMesh.tCoords[base + lng].axis.y = _pMesh.tCoords[base].axis.y;
                    else _pMesh.tCoords[base].axis.y = egwClamp01f(1.0f - (EGWsingle)lat / (EGWsingle)(latCuts - 1));
                }
                
                // Intermediate sides face connections (down left cover)
                if(lat < (latCuts - 2)) {
                    _pMesh.fIndicies[faceIndex].face.i1 = base + lngCutsT + lng;
                    _pMesh.fIndicies[faceIndex].face.i2 = base + lng;
                    _pMesh.fIndicies[faceIndex].face.i3 = base + ((lng + 1) % lngCutsT);
                    ++faceIndex;
                    _pMesh.fIndicies[faceIndex].face.i1 = base + lngCutsT + lng;
                    _pMesh.fIndicies[faceIndex].face.i2 = base + ((lng + 1) % lngCutsT);
                    _pMesh.fIndicies[faceIndex].face.i3 = base + lngCutsT + ((lng + 1) % lngCutsT);
                    ++faceIndex;
                }
            }
            
            // Special case extra vertex (per cut) pickup when textured
            if(hasTex) {
                _pMesh.vCoords[base + lng].axis.x = _pMesh.vCoords[base].axis.x;
                _pMesh.vCoords[base + lng].axis.y = _pMesh.vCoords[base].axis.y;
                _pMesh.vCoords[base + lng].axis.z = _pMesh.vCoords[base].axis.z;
                _pMesh.nCoords[base + lng].axis.x = _pMesh.nCoords[base].axis.x;
                _pMesh.nCoords[base + lng].axis.y = _pMesh.nCoords[base].axis.y;
                _pMesh.nCoords[base + lng].axis.z = _pMesh.nCoords[base].axis.z;
                _pMesh.tCoords[base + lng].axis.x = 1.0f;
                _pMesh.tCoords[base + lng].axis.y = _pMesh.tCoords[base].axis.y;
            }
        }
        base -= lngCutsT;
        
        // Special case S pole connector faces (lat = latCuts-1)
        for(lng = 0; lng < lngCuts; ++lng, ++faceIndex) {
            _pMesh.fIndicies[faceIndex].face.i1 = base + lng;
            _pMesh.fIndicies[faceIndex].face.i2 = _pMesh.vCount-1;
            _pMesh.fIndicies[faceIndex].face.i3 = base + ((lng + 1) % lngCutsT);
        }
    }    
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_mcsTrans);
    if(!(_mmcsRBVol = [[egwBoundingSphere alloc] initWithOpticalSource:&egwSIVecZero3f vertexCount:(_pMesh.vCount) vertexCoords:&(_pMesh.vCoords[0]) vertexCoordsStride:0])) { [self release]; return (self = nil); }
    
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
    if(_geoEID)
        _geoEID = [egwAIGfxCntxAGL returnUsedBufferID:_geoEID];
    
    [_gbSync release]; _gbSync = nil;
    [_mmcsRBVol release]; _mmcsRBVol = nil;
    egwMeshFreeSJITVAf(&_pMesh);
    
    if(EGW_ENGINE_ASSETS_DESTROYMSGS) NSLog(@"egwMeshBase: dealloc: Destroying static mesh base asset '%@' (%p).", _ident, self);
    [_ident release]; _ident = nil;
    [egwAssetManager decBaseRef];
    [super dealloc];
}

- (void)baseOffsetByTransform:(const egwMatrix44f*)transform {
    egwMatMultiply44f(&_mcsTrans, transform, &_mcsTrans);
    [_mmcsRBVol baseOffsetByTransform:transform];
}

- (void)baseOffsetByZeroAlign:(EGWuint)zfAlign {
    if(_pMesh.vCoords) {
        egwVector3f offset, min, max;
        egwMatrix44f transform;
        
        egwVecFindExtentsAxs3fv(_pMesh.vCoords, &min, &max, 0, _pMesh.vCount);
        
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
        if(_gbSync == sync && (_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && _pMesh.vCoords && _pMesh.nCoords && _pMesh.fIndicies) {
            if([egwAIGfxCntxAGL loadBufferArraysID:&_geoAID bufferElementsID:&_geoEID withSJITVAMesh:&_pMesh geometryStorage:_geoStrg]) {
                egwSFPVldtrValidate(_gbSync, @selector(validate)); // Event delegate will dealloc if not persistent
                
                return YES; // Done with this item, no other work left
            } else
                NSLog(@"egwMeshBase: performSubTaskForComponent:forSync: Failure buffering geometry mesh for asset '%@' (%p).", _ident, self);
            
            return NO; // Failure to load, try again next time
        }
    }
    
    return YES; // Nothing to do
}

- (void)reboundWithClass:(Class)bndClass {
    if(_pMesh.vCoords) {
        [_mmcsRBVol release]; _mmcsRBVol = nil;
        _mmcsRBVol = [[(bndClass && [bndClass conformsToProtocol:@protocol(egwPBounding)] ? bndClass : [egwBoundingSphere class]) alloc] initWithOpticalSource:NULL vertexCount:_pMesh.vCount vertexCoords:_pMesh.vCoords vertexCoordsStride:0];
        [_mmcsRBVol baseOffsetByTransform:&_mcsTrans];
    } else {
        id<egwPBounding> bnd = [[(bndClass && [bndClass conformsToProtocol:@protocol(egwPBounding)] ? bndClass : [egwBoundingSphere class]) alloc] init];
        [bnd orientateByTransform:&egwSIMatIdentity44f fromVolume:_mmcsRBVol];
        [_mmcsRBVol release]; _mmcsRBVol = bnd; bnd = nil;
    }
}

- (egwValidater*)geometryBufferSync {
    return _gbSync;
}

- (const EGWuint*)geometryArraysID {
    return &_geoAID;
}

- (const EGWuint*)geometryElementsID {
    return &_geoEID;
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

- (egwSJITVAMeshf*)staticMesh {
    return &_pMesh;
}

- (BOOL)trySetGeometryDataPersistence:(BOOL)persist {
    _isGDPersist = persist;
    
    if(!_isGDPersist && egwSFPVldtrIsValidated(_gbSync, @selector(isValidated))) {
        if(_pMesh.vCoords) {
            free((void*)_pMesh.vCoords); _pMesh.vCoords = NULL;
        }
        if(_pMesh.nCoords) {
            free((void*)_pMesh.nCoords); _pMesh.nCoords = NULL;
        }
        if(_pMesh.tCoords) {
            free((void*)_pMesh.tCoords); _pMesh.tCoords = NULL;
        }
        if(_pMesh.fIndicies) {
            free((void*)_pMesh.fIndicies); _pMesh.fIndicies = NULL;
        }
    }
    
    return YES;
}

- (BOOL)trySetGeometryStorage:(EGWuint)storage {
    if(_pMesh.vCoords && _pMesh.nCoords) {
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
        if(!_isGDPersist && (_pMesh.vCoords || _pMesh.nCoords || _pMesh.fIndicies)) { // Persistence check & dealloc
            // NOTE: The geometry mesh stats are still used even after mesh data is deleted - do not free the mesh! -jw
            if(_pMesh.vCoords) {
                free((void*)_pMesh.vCoords); _pMesh.vCoords = NULL;
            }
            if(_pMesh.nCoords) {
                free((void*)_pMesh.nCoords); _pMesh.nCoords = NULL;
            }
            if(_pMesh.tCoords) {
                free((void*)_pMesh.tCoords); _pMesh.tCoords = NULL;
            }
            if(_pMesh.fIndicies) {
                free((void*)_pMesh.fIndicies); _pMesh.fIndicies = NULL;
            }
        }
    }
}

- (void)validaterDidInvalidate:(egwValidater*)validater {
    if(_gbSync == validater) {
        if((_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && _pMesh.vCoords && _pMesh.nCoords && _pMesh.fIndicies) // Buffer mesh data up through context
            [egwAIGfxCntx addSubTask:self forSync:_gbSync];
        else
            egwSFPVldtrValidate(_gbSync, @selector(validate));
    }
}

@end

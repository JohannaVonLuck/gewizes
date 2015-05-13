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

/// @file egwKeyFramedMesh.m
/// @ingroup geWizES_geo_keyframedmesh
/// Animated Key Framed Polygon Mesh Asset Implementation.

#import "egwKeyFramedMesh.h"
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
#import "../phy/egwPhysics.h"
#import "../phy/egwInterpolators.h"
#import "../misc/egwValidater.h"


// !!!: ***** egwKeyFramedMesh *****

@implementation egwKeyFramedMesh

- (id)init {
    if([self isMemberOfClass:[egwKeyFramedMesh class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent keyFramedMesh:(egwKFJITVAMeshf*)keyFrmdMeshData vertexPolationMode:(EGWuint32)vrtPolationMode normalPolationMode:(EGWuint32)nrmPolationMode texturePolationMode:(EGWuint32)texPolationMode meshBounding:(Class)bndClass geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack textureStack:(egwTextureStack*)txtrStack {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwKeyFramedMeshBase alloc] initWithIdentity:assetIdent keyFramedMesh:keyFrmdMeshData meshBounding:bndClass])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _rFlags = EGW_GFXOBJ_RNDRFLG_DFLT;
    _rFrame = EGW_FRAME_ALWAYSPASS;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = (lghtStack ? [lghtStack retain] : [[egwLightStack alloc] init]))) { [self release]; return (self = nil); }
    if(!(_mStack = (mtrlStack ? [mtrlStack retain] : [[egwSIEngine defaultMaterialStack] retain]))) { [self release]; return (self = nil); }
    _tStack = (txtrStack ? [txtrStack retain] : nil);
    
    _vTrack.pMode = _nTrack.pMode = _tTrack.pMode = EGW_POLATION_NONE;
    _eAbsT = EGW_TIME_NAN;
    _vTrack.kIndex = _nTrack.kIndex = _tTrack.kIndex = -1;
    
    _geoStrg = storage;
    if(!(_gbSync = [[egwValidater alloc] initWithOwner:self validation:(_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES) coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    if(!(_wcsRBVol = [(NSObject*)[_base renderingBounding] copy])) { [self release]; return (self = nil); }
    if(!(_mcsRBVol = [(NSObject*)[_base renderingBounding] copy])) { [self release]; return (self = nil); }
    
    _kfMesh = [_base keyFramedMesh];
    
    _vTrack.line.chnCount = 3;
    _vTrack.line.cmpCount = _kfMesh->vCount;
    _vTrack.line.cdPitch = (EGWuint16)sizeof(egwVector3f);
    _vTrack.line.fdPitch = (EGWuint16)sizeof(egwVector3f) * _kfMesh->vCount;
    _nTrack.line.chnCount = 3;
    _nTrack.line.cmpCount = _kfMesh->vCount;
    _nTrack.line.cdPitch = (EGWuint16)sizeof(egwVector3f);
    _nTrack.line.fdPitch = (EGWuint16)sizeof(egwVector3f) * _kfMesh->vCount;
    _tTrack.line.chnCount = 2;
    _tTrack.line.cmpCount = _kfMesh->vCount;
    _tTrack.line.cdPitch = (EGWuint16)sizeof(egwVector2f);
    _tTrack.line.fdPitch = (EGWuint16)sizeof(egwVector2f) * _kfMesh->vCount;
    
    // Custom allocation so some components can be shared with _kfMesh to reduce memory usage (unsetting done before free in dealloc)
    _ipMesh.vCount = _kfMesh->vCount;
    _ipMesh.fCount = _kfMesh->fCount;
    if(_kfMesh->vkCoords && _kfMesh->vfCount && _kfMesh->vtIndicies) {
        if(!(_ipMesh.vCoords = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)_ipMesh.vCount))) { [self release]; return (self = nil); }
    } else _ipMesh.vCoords = _kfMesh->vkCoords;
    if(_kfMesh->nkCoords && _kfMesh->nfCount && _kfMesh->ntIndicies) {
        if(!(_ipMesh.nCoords = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)_ipMesh.vCount))) { [self release]; return (self = nil); }
    } else _ipMesh.nCoords = _kfMesh->nkCoords;
    if(_kfMesh->tkCoords && _kfMesh->tfCount && _kfMesh->ttIndicies) {
        if(!(_ipMesh.tCoords = (egwVector2f*)malloc(sizeof(egwVector2f) * (size_t)_ipMesh.vCount))) { [self release]; return (self = nil); }
    } else _ipMesh.tCoords = _kfMesh->tkCoords;
    _ipMesh.fIndicies = _kfMesh->fIndicies;
    
    [self setVertexPolationMode:vrtPolationMode];
    [self setNormalPolationMode:nrmPolationMode];
    [self setTexturePolationMode:texPolationMode];
    
    if((_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && !([egwAIGfxCntxAGL isActive] && [self performSubTaskForComponent:egwAIGfxCntxAGL forSync:_gbSync])) // Attempt to load, if context active on this thread
        [egwAIGfxCntx addSubTask:self forSync:_gbSync]; // Delayed load for context sub task to handle
    
    return self;
}

- (id)initBlankWithIdentity:(NSString*)assetIdent vertexCount:(EGWuint16)vrtxCount faceCount:(EGWuint16)faceCount vertexFrameCount:(EGWuint16)vrtFrmCount vertexPolationMode:(EGWuint32)vrtPolationMode normalFrameCount:(EGWuint16)nrmFrmCount normalPolationMode:(EGWuint32)nrmPolationMode textureFrameCount:(EGWuint16)texFrmCount texturePolationMode:(EGWuint32)texPolationMode geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack textureStack:(egwTextureStack*)txtrStack {
    if(!vrtxCount || !faceCount || vrtxCount > 3 * faceCount || !(vrtFrmCount || nrmFrmCount || texFrmCount) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwKeyFramedMeshBase alloc] initBlankWithIdentity:assetIdent vertexCount:vrtxCount faceCount:faceCount vertexFrameCount:vrtFrmCount normalFrameCount:nrmFrmCount textureFrameCount:texFrmCount])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _rFlags = EGW_GFXOBJ_RNDRFLG_DFLT;
    _rFrame = EGW_FRAME_ALWAYSPASS;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = (lghtStack ? [lghtStack retain] : [[egwLightStack alloc] init]))) { [self release]; return (self = nil); }
    if(!(_mStack = (mtrlStack ? [mtrlStack retain] : [[egwSIEngine defaultMaterialStack] retain]))) { [self release]; return (self = nil); }
    _tStack = (txtrStack ? [txtrStack retain] : nil);
    
    _vTrack.pMode = _nTrack.pMode = _tTrack.pMode = EGW_POLATION_NONE;
    _eAbsT = EGW_TIME_NAN;
    _vTrack.kIndex = _nTrack.kIndex = _tTrack.kIndex = -1;
    
    _geoStrg = storage;
    if(!(_gbSync = [[egwValidater alloc] initWithOwner:self validation:YES coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    _wcsRBVol = nil; // will require manual rebinding later
    _mcsRBVol = nil; // will require manual rebinding later
    
    _kfMesh = [_base keyFramedMesh];
    
    _vTrack.line.chnCount = 3;
    _vTrack.line.cmpCount = _kfMesh->vCount;
    _vTrack.line.cdPitch = (EGWuint16)sizeof(egwVector3f);
    _vTrack.line.fdPitch = (EGWuint16)sizeof(egwVector3f) * _kfMesh->vCount;
    _nTrack.line.chnCount = 3;
    _nTrack.line.cmpCount = _kfMesh->vCount;
    _nTrack.line.cdPitch = (EGWuint16)sizeof(egwVector3f);
    _nTrack.line.fdPitch = (EGWuint16)sizeof(egwVector3f) * _kfMesh->vCount;
    _tTrack.line.chnCount = 2;
    _tTrack.line.cmpCount = _kfMesh->vCount;
    _tTrack.line.cdPitch = (EGWuint16)sizeof(egwVector2f);
    _tTrack.line.fdPitch = (EGWuint16)sizeof(egwVector2f) * _kfMesh->vCount;
    
    // Custom allocation so some components can be shared with _kfMesh to reduce memory usage (unsetting done before free in dealloc)
    _ipMesh.vCount = _kfMesh->vCount;
    _ipMesh.fCount = _kfMesh->fCount;
    if(_kfMesh->vkCoords && _kfMesh->vfCount && _kfMesh->vtIndicies) {
        if(!(_ipMesh.vCoords = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)_ipMesh.vCount))) { [self release]; return (self = nil); }
    } else _ipMesh.vCoords = _kfMesh->vkCoords;
    if(_kfMesh->nkCoords && _kfMesh->nfCount && _kfMesh->ntIndicies) {
        if(!(_ipMesh.nCoords = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)_ipMesh.vCount))) { [self release]; return (self = nil); }
    } else _ipMesh.nCoords = _kfMesh->nkCoords;
    if(_kfMesh->tkCoords && _kfMesh->tfCount && _kfMesh->ttIndicies) {
        if(!(_ipMesh.tCoords = (egwVector2f*)malloc(sizeof(egwVector2f) * (size_t)_ipMesh.vCount))) { [self release]; return (self = nil); }
    } else _ipMesh.tCoords = _kfMesh->tkCoords;
    _ipMesh.fIndicies = _kfMesh->fIndicies;
    
    [self setVertexPolationMode:vrtPolationMode];
    [self setNormalPolationMode:nrmPolationMode];
    [self setTexturePolationMode:texPolationMode];
    
    // NOTE: Delayed load will occur on buffer sync invalidation. -jw
    
    return self;
}

- (id)initCopyOf:(id<egwPGeometry>)geometry withIdentity:(NSString*)assetIdent {
    if(!([geometry isKindOfClass:[self class]]) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = (egwKeyFramedMeshBase*)[[(id<egwPAsset>)geometry assetBase] retain])) { [self release]; return (self = nil); }
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _rFlags = [(egwKeyFramedMesh*)geometry renderingFlags];
    _rFrame = EGW_FRAME_ALWAYSPASS;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = [[geometry lightStack] retain])) { [self release]; return (self = nil); }
    if(!(_mStack = [[geometry materialStack] retain])) { [self release]; return (self = nil); }
    _tStack = [[geometry textureStack] retain];
    
    _vTrack.pMode = _nTrack.pMode = _tTrack.pMode = EGW_POLATION_NONE;
    _eAbsT = EGW_TIME_NAN;
    _vTrack.kIndex = _nTrack.kIndex = _tTrack.kIndex = -1;
    
    _geoStrg = [(egwKeyFramedMesh*)geometry geometryStorage];
    if(!(_gbSync = [[egwValidater alloc] initWithOwner:self validation:(_geoStrg & EGW_GEOMETRY_STRG_EXVBO ? NO : YES) coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    
    egwMatCopy44f([(egwKeyFramedMesh*)geometry wcsTransform], &_wcsTrans);
    egwMatCopy44f([(egwKeyFramedMesh*)geometry lcsTransform], &_lcsTrans);
    if(!(_wcsRBVol = [(NSObject*)[(egwKeyFramedMesh*)geometry renderingBounding] copy])) { [self release]; return (self = nil); }
    if(!(_mcsRBVol = [(NSObject*)[_base renderingBounding] copy])) { [self release]; return (self = nil); }
    if([(id<egwPOrientated>)geometry offsetDriver] && ![self trySetOffsetDriver:[(id<egwPOrientated>)geometry offsetDriver]]) { [self release]; return (self = nil); }
    if([(id<egwPOrientated>)geometry orientateDriver] && ![self trySetOrientateDriver:[(id<egwPOrientated>)geometry orientateDriver]]) { [self release]; return (self = nil); }
    
    _kfMesh = [_base keyFramedMesh];
    
    _vTrack.line.chnCount = 3;
    _vTrack.line.cmpCount = _kfMesh->vCount;
    _vTrack.line.cdPitch = (EGWuint16)sizeof(egwVector3f);
    _vTrack.line.fdPitch = (EGWuint16)sizeof(egwVector3f) * _kfMesh->vCount;
    _nTrack.line.chnCount = 3;
    _nTrack.line.cmpCount = _kfMesh->vCount;
    _nTrack.line.cdPitch = (EGWuint16)sizeof(egwVector3f);
    _nTrack.line.fdPitch = (EGWuint16)sizeof(egwVector3f) * _kfMesh->vCount;
    _tTrack.line.chnCount = 2;
    _tTrack.line.cmpCount = _kfMesh->vCount;
    _tTrack.line.cdPitch = (EGWuint16)sizeof(egwVector2f);
    _tTrack.line.fdPitch = (EGWuint16)sizeof(egwVector2f) * _kfMesh->vCount;
    
    // Custom allocation so some components can be shared with _kfMesh to reduce memory usage (unsetting done before free in dealloc)
    _ipMesh.vCount = _kfMesh->vCount;
    _ipMesh.fCount = _kfMesh->fCount;
    if(_kfMesh->vkCoords && _kfMesh->vfCount && _kfMesh->vtIndicies) {
        if(!(_ipMesh.vCoords = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)_ipMesh.vCount))) { [self release]; return (self = nil); }
    } else _ipMesh.vCoords = _kfMesh->vkCoords;
    if(_kfMesh->nkCoords && _kfMesh->nfCount && _kfMesh->ntIndicies) {
        if(!(_ipMesh.nCoords = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)_ipMesh.vCount))) { [self release]; return (self = nil); }
    } else _ipMesh.nCoords = _kfMesh->nkCoords;
    if(_kfMesh->tkCoords && _kfMesh->tfCount && _kfMesh->ttIndicies) {
        if(!(_ipMesh.tCoords = (egwVector2f*)malloc(sizeof(egwVector2f) * (size_t)_ipMesh.vCount))) { [self release]; return (self = nil); }
    } else _ipMesh.tCoords = _kfMesh->tkCoords;
    _ipMesh.fIndicies = _kfMesh->fIndicies;
    
    [self setVertexPolationMode:[(egwKeyFramedMesh*)geometry vertexPolationMode]];
    [self setNormalPolationMode:[(egwKeyFramedMesh*)geometry normalPolationMode]];
    [self setTexturePolationMode:[(egwKeyFramedMesh*)geometry texturePolationMode]];
    
    if((_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && !([egwAIGfxCntxAGL isActive] && [self performSubTaskForComponent:egwAIGfxCntxAGL forSync:_gbSync])) // Attempt to load, if context active on this thread
        [egwAIGfxCntx addSubTask:self forSync:_gbSync]; // Delayed load for context sub task to handle
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwKeyFramedMesh* copy = nil;
    NSString* copyIdent = nil;
    
    if([_ident hasSuffix:@"_default"])
        copyIdent = [[NSString alloc] initWithFormat:@"%@_%d", [_base identity], [_base nextInstanceIndex]];
    else copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwKeyFramedMesh allocWithZone:zone] initCopyOf:self
                                            withIdentity:copyIdent])) {
        NSLog(@"egwKeyFramedMesh: copyWithZone: Failure initializing new key framed mesh from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    return copy;
}

- (void)dealloc {
    // Unset shared array set
    if(_kfMesh) {
        if(_ipMesh.vCoords && _ipMesh.vCoords == _kfMesh->vkCoords) _ipMesh.vCoords = NULL;
        if(_ipMesh.nCoords && _ipMesh.nCoords == _kfMesh->nkCoords) _ipMesh.nCoords = NULL;
        if(_ipMesh.tCoords && _ipMesh.tCoords == _kfMesh->tkCoords) _ipMesh.tCoords = NULL;
        if(_ipMesh.fIndicies && _ipMesh.fIndicies == _kfMesh->fIndicies) _ipMesh.fIndicies = NULL;
        _kfMesh = NULL;
    }
    
    if(_geoAID)
        _geoAID = [egwAIGfxCntxAGL returnUsedBufferID:_geoAID];
    if(_geoEID)
        _geoEID = [egwAIGfxCntxAGL returnUsedBufferID:_geoEID];
    
    [_gbSync release]; _gbSync = nil;
    
    [_wcsRBVol release]; _wcsRBVol = nil;
    [_mcsRBVol release]; _mcsRBVol = nil;
    
    if(_lcsIpo) { [_lcsIpo removeTargetWithObject:self]; [_lcsIpo release]; _lcsIpo = nil; }
    if(_wcsIpo) { [_wcsIpo removeTargetWithObject:self]; [_wcsIpo release]; _wcsIpo = nil; }
    
    memset((void*)&_vTrack, 0, sizeof(egwKnotTrack));
    memset((void*)&_nTrack, 0, sizeof(egwKnotTrack));
    memset((void*)&_tTrack, 0, sizeof(egwKnotTrack));
    egwMeshFreeSJITVAf(&_ipMesh);
    
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
        
        [(id<egwPOrientated>)_parent applyOrientation]; // NOTE: Because the parent cortains self, it will always be an orientated branch line, also parents never call a child's applyOrientation method -jw
        
        if(_rFlags & EGW_OBJEXTEND_FLG_LAZYBOUNDING) {
            egwMatrix44f twcsTrans;
            if(!(_rFlags & EGW_OBJEXTEND_FLG_ALWAYSOTGHMG))
                egwMatMultiply44f(&_wcsTrans, &_lcsTrans, &twcsTrans);
            else
                egwMatMultiplyHmg44f(&_wcsTrans, &_lcsTrans, &twcsTrans);
            
            [_wcsRBVol orientateByTransform:&twcsTrans fromVolume:[_base renderingBounding]];
        } else {
            egwMatrix44f twcsTrans;
            if(!(_rFlags & EGW_OBJEXTEND_FLG_ALWAYSOTGHMG))
                egwMatMultiply44f(&_wcsTrans, &_lcsTrans, &twcsTrans);
            else
                egwMatMultiplyHmg44f(&_wcsTrans, &_lcsTrans, &twcsTrans);
            
            [_wcsRBVol orientateByTransform:&twcsTrans fromVolume:_mcsRBVol];
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

- (void)evaluateToTime:(EGWtime)absT {
    EGWtime oldEAbsT = (!isnan(_eAbsT) ? _eAbsT : absT);
    _eAbsT = absT;
    BOOL lookForward = (_eAbsT >= oldEAbsT - EGW_TIME_EPSILON ? YES : NO);
    
    if(_kfMesh->vtIndicies) {
        EGWtime vrtAbsT = _eAbsT;
        
    HandleVCyclic: // !!!: KF: handle cyclic v-knot.
        
        if((_vTrack.pMode & EGW_POLATION_EXEXTRA) & EGW_POLATION_EXCYCLIC)
            vrtAbsT = egwClampm(egwModm(vrtAbsT - _kfMesh->vtIndicies[0], _kfMesh->vtIndicies[_kfMesh->vfCount-1] - _kfMesh->vtIndicies[0]) + _kfMesh->vtIndicies[0], _kfMesh->vtIndicies[0], _kfMesh->vtIndicies[_kfMesh->vfCount-1]);
        
    FindVIndex: // !!!: KF: find v-index.
        
        if(_vTrack.kIndex == -1) { // Binsearch the frame index up
            if(vrtAbsT >= _kfMesh->vtIndicies[0] - EGW_TIME_EPSILON) {
                if(vrtAbsT <= _kfMesh->vtIndicies[_kfMesh->vfCount-1] + EGW_TIME_EPSILON) {
                    EGWint16 flIndex = 0;
                    EGWint16 fhIndex = _kfMesh->vfCount - 1;
                    EGWint16 fmIndex = fhIndex / 2;
                    do {
                        if(_kfMesh->vtIndicies[fmIndex] < vrtAbsT - EGW_TIME_EPSILON)
                            flIndex = fmIndex + 1;  // if stored < insert, go to higher half
                        else
                            fhIndex = fmIndex - 1; // if stored >= insert, go to lower half
                        fmIndex = (flIndex + fhIndex) / 2;    
                    } while(flIndex <= fhIndex);
                    _vTrack.kIndex = fmIndex + 1;
                } else _vTrack.kIndex = _kfMesh->vfCount;
            } else _vTrack.kIndex = 0;
            _vTrack.line.okFrame = NULL;
        }
        
    VerifyVIndex: // !!!: KF: verify v-index.
        
        if(lookForward) { // Look forward
            if(_kfMesh->vfCount > 1 && (
                (_vTrack.kIndex >= 1 && _vTrack.kIndex < _kfMesh->vfCount && !(vrtAbsT <= _kfMesh->vtIndicies[_vTrack.kIndex] + EGW_TIME_EPSILON && vrtAbsT >= _kfMesh->vtIndicies[_vTrack.kIndex-1] - EGW_TIME_EPSILON)) || // Past current knot end
                (_vTrack.kIndex == 0 && vrtAbsT >= _kfMesh->vtIndicies[0] - EGW_TIME_EPSILON) || // At start, not equal
                (_vTrack.kIndex == _kfMesh->vfCount && vrtAbsT <= _kfMesh->vtIndicies[_kfMesh->vfCount-1] + EGW_TIME_EPSILON))) { // At end, not equal
                // Forward seek 2 knots else binsearch
                if(_vTrack.kIndex+1 < _kfMesh->vfCount && ((vrtAbsT >= _kfMesh->vtIndicies[_vTrack.kIndex+1-1] - EGW_TIME_EPSILON) && (vrtAbsT <= _kfMesh->vtIndicies[_vTrack.kIndex+1] + EGW_TIME_EPSILON))) {
                    _vTrack.kIndex += 1;
                    _vTrack.line.okFrame = NULL;
                } else if (_vTrack.kIndex+2 < _kfMesh->vfCount && ((vrtAbsT >= _kfMesh->vtIndicies[_vTrack.kIndex+2-1] - EGW_TIME_EPSILON) && (vrtAbsT <= _kfMesh->vtIndicies[_vTrack.kIndex+2] + EGW_TIME_EPSILON))) {
                    _vTrack.kIndex += 2;
                    _vTrack.line.okFrame = NULL;
                } else {
                    _vTrack.kIndex = -1;
                    goto FindVIndex;
                }
            }
        } else { // Look backward
            if(_kfMesh->vfCount > 1 && (
                (_vTrack.kIndex >= 1 && _vTrack.kIndex < _kfMesh->vfCount && !(vrtAbsT >= _kfMesh->vtIndicies[_vTrack.kIndex-1] - EGW_TIME_EPSILON && vrtAbsT <= _kfMesh->vtIndicies[_vTrack.kIndex] + EGW_TIME_EPSILON)) || // Past current knot start
                (_vTrack.kIndex == 0 && vrtAbsT >= _kfMesh->vtIndicies[0] - EGW_TIME_EPSILON) || // At start, not equal
                (_vTrack.kIndex == _kfMesh->vfCount && vrtAbsT <= _kfMesh->vtIndicies[_kfMesh->vfCount-1] + EGW_TIME_EPSILON))) { // At end, not equal
                // Reverse seek 2 knots else binsearch
                if(_vTrack.kIndex-1 >= 1 && ((vrtAbsT >= _kfMesh->vtIndicies[_vTrack.kIndex-1-1] - EGW_TIME_EPSILON) && (vrtAbsT <= _kfMesh->vtIndicies[_vTrack.kIndex-1] + EGW_TIME_EPSILON))) {
                    _vTrack.kIndex -= 1;
                    _vTrack.line.okFrame = NULL;
                } else if (_vTrack.kIndex-2 >= 1 && ((vrtAbsT >= _kfMesh->vtIndicies[_vTrack.kIndex-2-1] - EGW_TIME_EPSILON) && (vrtAbsT <= _kfMesh->vtIndicies[_vTrack.kIndex-2] + EGW_TIME_EPSILON))) {
                    _vTrack.kIndex -= 2;
                    _vTrack.line.okFrame = NULL;
                } else {
                    _vTrack.kIndex = -1;
                    goto FindVIndex;
                }
            }
        }
        
    FindVOffsets: // !!!: KF: find v-frame offsets.
        
        if(!_vTrack.line.okFrame) { // Acts as a sentinel to force update when NULL
            if(_kfMesh->vfCount > 1 && _vTrack.kIndex >= 1 && _vTrack.kIndex < _kfMesh->vfCount) { // Interpolate required
                EGWint indexOffset = (((_vTrack.pMode & EGW_POLATION_EXINTER) & EGW_POLATION_EXKNTPSHBKX1) ? 1 : 0) +
                (((_vTrack.pMode & EGW_POLATION_EXINTER) & EGW_POLATION_EXKNTPSHBKX2) ? 2 : 0);
                
                if(((EGWint)_vTrack.kIndex - indexOffset) > 1) {
                    EGWint mptCnt = (EGWint)((_vTrack.pMode & EGW_POLATION_EXINTER) & EGW_POLATION_EXMNPTCNT);
                    
                    if((EGWint)_vTrack.kIndex - (indexOffset + 1) + (mptCnt - 1) < ((EGWint)_kfMesh->vfCount - 1)) // center bounds
                        indexOffset = (EGWint)_vTrack.kIndex - (indexOffset + 1);
                    else // right bounding
                        indexOffset = (EGWint)_kfMesh->vfCount - mptCnt;
                    
                    _vTrack.line.okFrame = (EGWbyte*)((EGWuintptr)_kfMesh->vkCoords + (_vTrack.line.fdPitch * (EGWuintptr)indexOffset));
                    _vTrack.line.okfExtraDat = (_kfMesh->vkfExtraDat ? (EGWbyte*)((EGWuintptr)_kfMesh->vkfExtraDat + (_vTrack.line.efdPitch * (EGWuintptr)indexOffset)) : (EGWbyte*)NULL);
                    _vTrack.line.otIndicie = &_kfMesh->vtIndicies[indexOffset];
                } else { // left bounding
                    _vTrack.line.okFrame = (EGWbyte*)_kfMesh->vkCoords;
                    _vTrack.line.okfExtraDat = (EGWbyte*)_kfMesh->vkfExtraDat;
                    _vTrack.line.otIndicie = _kfMesh->vtIndicies;
                }
            } else { // Extrapolate required
                if(_vTrack.kIndex != 0) { // beyond end
                    EGWint indexOffset = (EGWint)_kfMesh->vfCount - (EGWint)(((_vTrack.pMode & EGW_POLATION_EXEXTRA) & EGW_POLATION_EXMNPTCNT) >> 16);
                    
                    _vTrack.line.okFrame = (EGWbyte*)((EGWuintptr)_kfMesh->vkCoords + (_vTrack.line.fdPitch * (EGWuintptr)indexOffset));
                    _vTrack.line.okfExtraDat = (_kfMesh->vkfExtraDat ? (EGWbyte*)((EGWuintptr)_kfMesh->vkfExtraDat + (_vTrack.line.efdPitch * (EGWuintptr)indexOffset)) : (EGWbyte*)NULL);
                    _vTrack.line.otIndicie = &_kfMesh->vtIndicies[indexOffset];
                } else { // beyond start
                    _vTrack.line.okFrame = (EGWbyte*)_kfMesh->vkCoords;
                    _vTrack.line.okfExtraDat = (EGWbyte*)_kfMesh->vkfExtraDat;
                    _vTrack.line.otIndicie = _kfMesh->vtIndicies;
                }
            }
        }
        
    WriteVVector: // !!!: KF: write v-vector.
        
        if(_vTrack.line.okFrame) {
            if(_vTrack.kIndex >= 1 && _vTrack.kIndex < _kfMesh->vfCount) // Interpolate required
                _vTrack.fpIpoFunc(&_vTrack.line, vrtAbsT, (EGWbyte*)_ipMesh.vCoords);
            else // Extrapolate required
                _vTrack.fpEpoFunc(&_vTrack.line, vrtAbsT, (EGWbyte*)_ipMesh.vCoords);
            
            if(!(_rFlags & EGW_OBJEXTEND_FLG_LAZYBOUNDING)) {
                [_mcsRBVol initWithOpticalSource:NULL vertexCount:_ipMesh.vCount vertexCoords:_ipMesh.vCoords vertexCoordsStride:0];
                _ortPending = YES;
                egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
            }
        }
    }
    
    if(_kfMesh->ntIndicies) {
        EGWtime nrmAbsT = _eAbsT;
        
    HandleNCyclic: // !!!: KF: handle cyclic n-knot.
        
        if((_nTrack.pMode & EGW_POLATION_EXEXTRA) & EGW_POLATION_EXCYCLIC)
            nrmAbsT = egwClampm(egwModm(nrmAbsT - _kfMesh->ntIndicies[0], _kfMesh->ntIndicies[_kfMesh->nfCount-1] - _kfMesh->ntIndicies[0]) + _kfMesh->ntIndicies[0], _kfMesh->ntIndicies[0], _kfMesh->ntIndicies[_kfMesh->nfCount-1]);
        
    FindNIndex: // !!!: KF: find n-index.
        
        if(_kfMesh->ntIndicies == _kfMesh->vtIndicies) { // Frame index overlap special case
            if(_nTrack.kIndex != _vTrack.kIndex) {
                _nTrack.kIndex = _vTrack.kIndex;
                _nTrack.line.okFrame = NULL;
            }
            goto FindNOffsets;
        }
        
        if(_nTrack.kIndex == -1) { // Binsearch the frame index up
            if(nrmAbsT >= _kfMesh->ntIndicies[0] - EGW_TIME_EPSILON) {
                if(nrmAbsT <= _kfMesh->ntIndicies[_kfMesh->nfCount-1] + EGW_TIME_EPSILON) {
                    EGWint16 flIndex = 0;
                    EGWint16 fhIndex = _kfMesh->nfCount - 1;
                    EGWint16 fmIndex = fhIndex / 2;
                    do {
                        if(_kfMesh->ntIndicies[fmIndex] < nrmAbsT - EGW_TIME_EPSILON)
                            flIndex = fmIndex + 1;  // if stored < insert, go to higher half
                        else
                            fhIndex = fmIndex - 1; // if stored >= insert, go to lower half
                        fmIndex = (flIndex + fhIndex) / 2;    
                    } while(flIndex <= fhIndex);
                    _nTrack.kIndex = fmIndex + 1;
                } else _nTrack.kIndex = _kfMesh->nfCount;
            } else _nTrack.kIndex = 0;
            _nTrack.line.okFrame = NULL;
        }
        
    VerifyNIndex: // !!!: KF: verify n-index.
        
        if(lookForward) { // Look forward
            if(_kfMesh->nfCount > 1 && (
                (_nTrack.kIndex >= 1 && _nTrack.kIndex < _kfMesh->nfCount && !(nrmAbsT <= _kfMesh->ntIndicies[_nTrack.kIndex] + EGW_TIME_EPSILON && nrmAbsT >= _kfMesh->ntIndicies[_nTrack.kIndex-1] - EGW_TIME_EPSILON)) || // Past current knot end
                (_nTrack.kIndex == 0 && nrmAbsT >= _kfMesh->ntIndicies[0] - EGW_TIME_EPSILON) || // At start, not equal
                (_nTrack.kIndex == _kfMesh->nfCount && nrmAbsT <= _kfMesh->ntIndicies[_kfMesh->nfCount-1] + EGW_TIME_EPSILON))) { // At end, not equal
                // Forward seek 2 knots else binsearch
                if(_nTrack.kIndex+1 < _kfMesh->nfCount && ((nrmAbsT >= _kfMesh->ntIndicies[_nTrack.kIndex+1-1] - EGW_TIME_EPSILON) && (nrmAbsT <= _kfMesh->ntIndicies[_nTrack.kIndex+1] + EGW_TIME_EPSILON))) {
                    _nTrack.kIndex += 1;
                    _nTrack.line.okFrame = NULL;
                } else if (_nTrack.kIndex+2 < _kfMesh->nfCount && ((nrmAbsT >= _kfMesh->ntIndicies[_nTrack.kIndex+2-1] - EGW_TIME_EPSILON) && (nrmAbsT <= _kfMesh->ntIndicies[_nTrack.kIndex+2] + EGW_TIME_EPSILON))) {
                    _nTrack.kIndex += 2;
                    _nTrack.line.okFrame = NULL;
                } else {
                    _nTrack.kIndex = -1;
                    goto FindNIndex;
                }
            }
        } else { // Look backward
            if(_kfMesh->nfCount > 1 && (
                (_nTrack.kIndex >= 1 && _nTrack.kIndex < _kfMesh->nfCount && !(nrmAbsT >= _kfMesh->ntIndicies[_nTrack.kIndex-1] - EGW_TIME_EPSILON && nrmAbsT <= _kfMesh->ntIndicies[_nTrack.kIndex] + EGW_TIME_EPSILON)) || // Past current knot start
                (_nTrack.kIndex == 0 && nrmAbsT >= _kfMesh->ntIndicies[0] - EGW_TIME_EPSILON) || // At start, not equal
                (_nTrack.kIndex == _kfMesh->nfCount && nrmAbsT <= _kfMesh->ntIndicies[_kfMesh->nfCount-1] + EGW_TIME_EPSILON))) { // At end, not equal
                // Reverse seek 2 knots else binsearch
                if(_nTrack.kIndex-1 >= 1 && ((nrmAbsT >= _kfMesh->ntIndicies[_nTrack.kIndex-1-1] - EGW_TIME_EPSILON) && (nrmAbsT <= _kfMesh->ntIndicies[_nTrack.kIndex-1] + EGW_TIME_EPSILON))) {
                    _nTrack.kIndex -= 1;
                    _nTrack.line.okFrame = NULL;
                } else if (_nTrack.kIndex-2 >= 1 && ((nrmAbsT >= _kfMesh->ntIndicies[_nTrack.kIndex-2-1] - EGW_TIME_EPSILON) && (nrmAbsT <= _kfMesh->ntIndicies[_nTrack.kIndex-2] + EGW_TIME_EPSILON))) {
                    _nTrack.kIndex -= 2;
                    _nTrack.line.okFrame = NULL;
                } else {
                    _nTrack.kIndex = -1;
                    goto FindNIndex;
                }
            }
        }
        
    FindNOffsets: // !!!: KF: find n-frame offsets.
        
        if(!_nTrack.line.okFrame) { // Acts as a sentinel to force update when NULL
            if(_kfMesh->nfCount > 1 && _nTrack.kIndex >= 1 && _nTrack.kIndex < _kfMesh->nfCount) { // Interpolate required
                EGWint indexOffset = (((_nTrack.pMode & EGW_POLATION_EXINTER) & EGW_POLATION_EXKNTPSHBKX1) ? 1 : 0) +
                (((_nTrack.pMode & EGW_POLATION_EXINTER) & EGW_POLATION_EXKNTPSHBKX2) ? 2 : 0);
                
                if(((EGWint)_nTrack.kIndex - indexOffset) > 1) {
                    EGWint mptCnt = (EGWint)((_nTrack.pMode & EGW_POLATION_EXINTER) & EGW_POLATION_EXMNPTCNT);
                    
                    if((EGWint)_nTrack.kIndex - (indexOffset + 1) + (mptCnt - 1) < ((EGWint)_kfMesh->nfCount - 1)) // center bounds
                        indexOffset = (EGWint)_nTrack.kIndex - (indexOffset + 1);
                    else // right bounding
                        indexOffset = (EGWint)_kfMesh->nfCount - mptCnt;
                    
                    _nTrack.line.okFrame = (EGWbyte*)((EGWuintptr)_kfMesh->nkCoords + (_nTrack.line.fdPitch * (EGWuintptr)indexOffset));
                    _nTrack.line.okfExtraDat = (_kfMesh->nkfExtraDat ? (EGWbyte*)((EGWuintptr)_kfMesh->nkfExtraDat + (_nTrack.line.efdPitch * (EGWuintptr)indexOffset)) : (EGWbyte*)NULL);
                    _nTrack.line.otIndicie = &_kfMesh->ntIndicies[indexOffset];
                } else { // left bounding
                    _nTrack.line.okFrame = (EGWbyte*)_kfMesh->nkCoords;
                    _nTrack.line.okfExtraDat = (EGWbyte*)_kfMesh->nkfExtraDat;
                    _nTrack.line.otIndicie = _kfMesh->ntIndicies;
                }
            } else { // Extrapolate required
                if(_nTrack.kIndex != 0) { // beyond end
                    EGWint indexOffset = (EGWint)_kfMesh->nfCount - (EGWint)(((_nTrack.pMode & EGW_POLATION_EXEXTRA) & EGW_POLATION_EXMNPTCNT) >> 16);
                    
                    _nTrack.line.okFrame = (EGWbyte*)((EGWuintptr)_kfMesh->nkCoords + (_nTrack.line.fdPitch * (EGWuintptr)indexOffset));
                    _nTrack.line.okfExtraDat = (_kfMesh->nkfExtraDat ? (EGWbyte*)((EGWuintptr)_kfMesh->nkfExtraDat + (_nTrack.line.efdPitch * (EGWuintptr)indexOffset)) : (EGWbyte*)NULL);
                    _nTrack.line.otIndicie = &_kfMesh->ntIndicies[indexOffset];
                } else { // beyond start
                    _nTrack.line.okFrame = (EGWbyte*)_kfMesh->nkCoords;
                    _nTrack.line.okfExtraDat = (EGWbyte*)_kfMesh->nkfExtraDat;
                    _nTrack.line.otIndicie = _kfMesh->ntIndicies;
                }
            }
        }
        
    WriteNVector: // !!!: KF: write n-vector.
        
        if(_nTrack.line.okFrame) {
            if(_nTrack.kIndex >= 1 && _nTrack.kIndex < _kfMesh->nfCount) // Interpolate required
                _nTrack.fpIpoFunc(&_nTrack.line, nrmAbsT, (EGWbyte*)_ipMesh.nCoords);
            else // Extrapolate required
                _nTrack.fpEpoFunc(&_nTrack.line, nrmAbsT, (EGWbyte*)_ipMesh.nCoords);
            
            if(_isNormNrmlVec) // FIXME: Technically, this setting should be made in the KFM def itself, not as a part of the actuator flags from timer. -jw
                egwVecFastNormalize3fv(_ipMesh.nCoords, _ipMesh.nCoords, 0, 0, _ipMesh.vCount); // FIXME: Would be better to check for mach schnell status somehow here (tls?). -jw
        }
    }
    
    if(_kfMesh->ttIndicies) {
        EGWtime texAbsT = _eAbsT;
        
    HandleTCyclic: // !!!: KF: handle cyclic t-knot.
        
        if((_tTrack.pMode & EGW_POLATION_EXEXTRA) & EGW_POLATION_EXCYCLIC)
            texAbsT = egwClampm(egwModm(texAbsT - _kfMesh->ttIndicies[0], _kfMesh->ttIndicies[_kfMesh->tfCount-1] - _kfMesh->ttIndicies[0]) + _kfMesh->ttIndicies[0], _kfMesh->ttIndicies[0], _kfMesh->ttIndicies[_kfMesh->tfCount-1]);
        
    FindTIndex: // !!!: KF: find t-index.
        
        if(_kfMesh->ttIndicies == _kfMesh->vtIndicies) { // Frame index overlap special case
            if(_tTrack.kIndex != _vTrack.kIndex) {
                _tTrack.kIndex = _vTrack.kIndex;
                _tTrack.line.okFrame = NULL;
            }
            goto FindTOffsets;
        } else if(_kfMesh->ttIndicies == _kfMesh->ntIndicies) { // Frame index overlap special case
            if(_tTrack.kIndex != _nTrack.kIndex) {
                _tTrack.kIndex = _nTrack.kIndex;
                _tTrack.line.okFrame = NULL;
            }
            goto FindTOffsets;
        }
        
        if(_tTrack.kIndex == -1) { // Binsearch the frame index up
            if(texAbsT >= _kfMesh->ttIndicies[0] - EGW_TIME_EPSILON) {
                if(texAbsT <= _kfMesh->ttIndicies[_kfMesh->tfCount-1] + EGW_TIME_EPSILON) {
                    EGWint16 flIndex = 0;
                    EGWint16 fhIndex = _kfMesh->tfCount - 1;
                    EGWint16 fmIndex = fhIndex / 2;
                    do {
                        if(_kfMesh->ttIndicies[fmIndex] < texAbsT - EGW_TIME_EPSILON)
                            flIndex = fmIndex + 1;  // if stored < insert, go to higher half
                        else
                            fhIndex = fmIndex - 1; // if stored >= insert, go to lower half
                        fmIndex = (flIndex + fhIndex) / 2;    
                    } while(flIndex <= fhIndex);
                    _tTrack.kIndex = fmIndex + 1;
                } else _tTrack.kIndex = _kfMesh->tfCount;
            } else _tTrack.kIndex = 0;
            _tTrack.line.okFrame = NULL;
        }
        
    VerifyTIndex: // !!!: KF: verify t-index.
        
        if(lookForward) { // Look forward
            if(_kfMesh->tfCount > 1 && (
                (_tTrack.kIndex >= 1 && _tTrack.kIndex < _kfMesh->tfCount && !(texAbsT <= _kfMesh->ttIndicies[_tTrack.kIndex] + EGW_TIME_EPSILON && texAbsT >= _kfMesh->ttIndicies[_tTrack.kIndex-1] - EGW_TIME_EPSILON)) || // Past current knot end
                (_tTrack.kIndex == 0 && texAbsT >= _kfMesh->ttIndicies[0] - EGW_TIME_EPSILON) || // At start, not equal
                (_tTrack.kIndex == _kfMesh->tfCount && texAbsT <= _kfMesh->ttIndicies[_kfMesh->tfCount-1] + EGW_TIME_EPSILON))) { // At end, not equal
                // Forward seek 2 knots else binsearch
                if(_tTrack.kIndex+1 < _kfMesh->tfCount && ((texAbsT >= _kfMesh->ttIndicies[_tTrack.kIndex+1-1] - EGW_TIME_EPSILON) && (texAbsT <= _kfMesh->ttIndicies[_tTrack.kIndex+1] + EGW_TIME_EPSILON))) {
                    _tTrack.kIndex += 1;
                    _tTrack.line.okFrame = NULL;
                } else if (_tTrack.kIndex+2 < _kfMesh->tfCount && ((texAbsT >= _kfMesh->ttIndicies[_tTrack.kIndex+2-1] - EGW_TIME_EPSILON) && (texAbsT <= _kfMesh->ttIndicies[_tTrack.kIndex+2] + EGW_TIME_EPSILON))) {
                    _tTrack.kIndex += 2;
                    _tTrack.line.okFrame = NULL;
                } else {
                    _tTrack.kIndex = -1;
                    goto FindNIndex;
                }
            }
        } else { // Look backward
            if(_kfMesh->tfCount > 1 && (
                (_tTrack.kIndex >= 1 && _tTrack.kIndex < _kfMesh->tfCount && !(texAbsT >= _kfMesh->ttIndicies[_tTrack.kIndex-1] - EGW_TIME_EPSILON && texAbsT <= _kfMesh->ttIndicies[_tTrack.kIndex] + EGW_TIME_EPSILON)) || // Past current knot start
                (_tTrack.kIndex == 0 && texAbsT >= _kfMesh->ttIndicies[0] - EGW_TIME_EPSILON) || // At start, not equal
                (_tTrack.kIndex == _kfMesh->tfCount && texAbsT <= _kfMesh->ttIndicies[_kfMesh->tfCount-1] + EGW_TIME_EPSILON))) { // At end, not equal
                // Reverse seek 2 knots else binsearch
                if(_tTrack.kIndex-1 >= 1 && ((texAbsT >= _kfMesh->ttIndicies[_tTrack.kIndex-1-1] - EGW_TIME_EPSILON) && (texAbsT <= _kfMesh->ttIndicies[_tTrack.kIndex-1] + EGW_TIME_EPSILON))) {
                    _tTrack.kIndex -= 1;
                    _tTrack.line.okFrame = NULL;
                } else if (_tTrack.kIndex-2 >= 1 && ((texAbsT >= _kfMesh->ttIndicies[_tTrack.kIndex-2-1] - EGW_TIME_EPSILON) && (texAbsT <= _kfMesh->ttIndicies[_tTrack.kIndex-2] + EGW_TIME_EPSILON))) {
                    _tTrack.kIndex -= 2;
                    _tTrack.line.okFrame = NULL;
                } else {
                    _tTrack.kIndex = -1;
                    goto FindNIndex;
                }
            }
        }
        
    FindTOffsets: // !!!: KF: find t-frame offsets.
        
        if(!_tTrack.line.okFrame) { // Acts as a sentinel to force update when NULL
            if(_kfMesh->tfCount > 1 && _tTrack.kIndex >= 1 && _tTrack.kIndex < _kfMesh->tfCount) { // Interpolate required
                EGWint indexOffset = (((_tTrack.pMode & EGW_POLATION_EXINTER) & EGW_POLATION_EXKNTPSHBKX1) ? 1 : 0) +
                (((_tTrack.pMode & EGW_POLATION_EXINTER) & EGW_POLATION_EXKNTPSHBKX2) ? 2 : 0);
                
                if(((EGWint)_tTrack.kIndex - indexOffset) > 1) {
                    EGWint mptCnt = (EGWint)((_tTrack.pMode & EGW_POLATION_EXINTER) & EGW_POLATION_EXMNPTCNT);
                    
                    if((EGWint)_tTrack.kIndex - (indexOffset + 1) + (mptCnt - 1) < ((EGWint)_kfMesh->tfCount - 1)) // center bounds
                        indexOffset = (EGWint)_tTrack.kIndex - (indexOffset + 1);
                    else // right bounding
                        indexOffset = (EGWint)_kfMesh->tfCount - mptCnt;
                    
                    _tTrack.line.okFrame = (EGWbyte*)((EGWuintptr)_kfMesh->tkCoords + (_tTrack.line.fdPitch * (EGWuintptr)indexOffset));
                    _tTrack.line.okfExtraDat = (_kfMesh->tkfExtraDat ? (EGWbyte*)((EGWuintptr)_kfMesh->tkfExtraDat + (_tTrack.line.efdPitch * (EGWuintptr)indexOffset)) : (EGWbyte*)NULL);
                    _tTrack.line.otIndicie = &_kfMesh->ttIndicies[indexOffset];
                } else { // left bounding
                    _tTrack.line.okFrame = (EGWbyte*)_kfMesh->tkCoords;
                    _tTrack.line.okfExtraDat = (EGWbyte*)_kfMesh->tkfExtraDat;
                    _tTrack.line.otIndicie = _kfMesh->ttIndicies;
                }
            } else { // Extrapolate required
                if(_tTrack.kIndex != 0) { // beyond end
                    EGWint indexOffset = (EGWint)_kfMesh->tfCount - (EGWint)(((_tTrack.pMode & EGW_POLATION_EXEXTRA) & EGW_POLATION_EXMNPTCNT) >> 16);
                    
                    _tTrack.line.okFrame = (EGWbyte*)((EGWuintptr)_kfMesh->tkCoords + (_tTrack.line.fdPitch * (EGWuintptr)indexOffset));
                    _tTrack.line.okfExtraDat = (_kfMesh->tkfExtraDat ? (EGWbyte*)((EGWuintptr)_kfMesh->tkfExtraDat + (_tTrack.line.efdPitch * (EGWuintptr)indexOffset)) : (EGWbyte*)NULL);
                    _tTrack.line.otIndicie = &_kfMesh->ttIndicies[indexOffset];
                } else { // beyond start
                    _tTrack.line.okFrame = (EGWbyte*)_kfMesh->tkCoords;
                    _tTrack.line.okfExtraDat = (EGWbyte*)_kfMesh->tkfExtraDat;
                    _tTrack.line.otIndicie = _kfMesh->ttIndicies;
                }
            }
        }
        
    WriteTVector: // !!!: KF: write t-vector.
        
        if(_tTrack.line.okFrame) {
            if(_tTrack.kIndex >= 1 && _tTrack.kIndex < _kfMesh->tfCount) // Interpolate required
                _tTrack.fpIpoFunc(&_tTrack.line, texAbsT, (EGWbyte*)_ipMesh.tCoords);
            else // Extrapolate required
                _tTrack.fpEpoFunc(&_tTrack.line, texAbsT, (EGWbyte*)_ipMesh.tCoords);
        }
    }
    
    // Geometry buffer sync is always invalidated on an eval, if VBO'ed
    if(_geoStrg & EGW_GEOMETRY_STRG_EXVBO)
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
        if(_gbSync == sync && (_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && _ipMesh.vCoords && _ipMesh.nCoords && _ipMesh.fIndicies) {
            if([egwAIGfxCntxAGL loadBufferArraysID:&_geoAID bufferElementsID:&_geoEID withSJITVAMesh:&_ipMesh geometryStorage:_geoStrg]) {
                egwSFPVldtrValidate(_gbSync, @selector(validate)); // Event delegate will dealloc if not persistent
                
                return YES; // Done with this item, no other work left
            } else
                NSLog(@"egwKeyFramedMesh: performSubTaskForComponent:forSync: Failure buffering geometry mesh for asset '%@' (%p).", _ident, self);
            
            return NO; // Failure to load, try again next time
        }
    }
    
    return YES; // Nothing to do
}

- (void)reboundWithClass:(Class)bndClass {
    if([_wcsRBVol class] != bndClass) {
        [_wcsRBVol release];
        _wcsRBVol = [[(bndClass && [bndClass conformsToProtocol:@protocol(egwPBounding)] ? bndClass : [egwBoundingSphere class]) alloc] init];
        [_mcsRBVol release];
        _mcsRBVol = [[(bndClass && [bndClass conformsToProtocol:@protocol(egwPBounding)] ? bndClass : [egwBoundingSphere class]) alloc] initWithOpticalSource:NULL vertexCount:(_kfMesh->vCount * (_kfMesh->vfCount ? _kfMesh->vfCount : 1)) vertexCoords:_kfMesh->vkCoords vertexCoordsStride:0];
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
    // NOTE: The code below is non-abttracted OpenGLES dependent. Staying this way till ES2. -jw
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
        
        if(_geoAID && _geoEID) {
            if(egw_glBindBuffer(GL_ARRAY_BUFFER, _geoAID) || !(flags & EGW_GFXOBJ_RPLYFLG_SAMELASTBASE)) {
                glVertexPointer((GLint)3, GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)0);
                glNormalPointer(GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)((EGWuint)sizeof(egwVector3f) * (EGWuint)_ipMesh.vCount));
                if(_tStack) glTexCoordPointer((GLint)2, GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)((EGWuint)sizeof(egwVector3f) * (EGWuint)_ipMesh.vCount * 2));
            }
            
            egw_glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _geoEID);
            
            glDrawElements(GL_TRIANGLES, (GLsizei)(_ipMesh.fCount * 3), GL_UNSIGNED_SHORT, (const GLvoid*)(EGWuintptr)0);
        } else {
            if(egw_glBindBuffer(GL_ARRAY_BUFFER, 0) || !(flags & EGW_GFXOBJ_RPLYFLG_SAMELASTBASE)) {
                glVertexPointer((GLint)3, GL_FLOAT, (GLsizei)0, (const GLvoid*)_ipMesh.vCoords);
                glNormalPointer(GL_FLOAT, (GLsizei)0, (const GLvoid*)_ipMesh.nCoords);
                if(_tStack) glTexCoordPointer((GLint)2, GL_FLOAT, (GLsizei)0, (const GLvoid*)_ipMesh.tCoords);
            }
            
            egw_glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
            
            glDrawElements(GL_TRIANGLES, (GLsizei)(_ipMesh.fCount * 3), GL_UNSIGNED_SHORT, (const GLvoid*)_ipMesh.fIndicies);
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

- (EGWtime)evaluatedAtTime {
    return _eAbsT;
}

- (EGWtime)evaluationBoundsBegin {
    if(_kfMesh->vtIndicies) { // v??
        if(_kfMesh->ntIndicies) { // vn?
            if(_kfMesh->ttIndicies) { // vrt
                return (_kfMesh->vtIndicies[0] <= _kfMesh->ntIndicies[0] ?
                        (_kfMesh->vtIndicies[0] <= _kfMesh->ttIndicies[0] ? _kfMesh->vtIndicies[0] : _kfMesh->ttIndicies[0]) :
                        (_kfMesh->ntIndicies[0] <= _kfMesh->ttIndicies[0] ? _kfMesh->ntIndicies[0] : _kfMesh->ttIndicies[0]));
            } else { // vnx
                return (_kfMesh->vtIndicies[0] <= _kfMesh->ntIndicies[0] ? _kfMesh->vtIndicies[0] : _kfMesh->ntIndicies[0]);
            }
        } else if(_kfMesh->ttIndicies) { // vxt
            return (_kfMesh->vtIndicies[0] <= _kfMesh->ttIndicies[0] ? _kfMesh->vtIndicies[0] : _kfMesh->ttIndicies[0]);
        } else { // vxx
            return _kfMesh->vtIndicies[0];
        }
    } else if(_kfMesh->ntIndicies) { // xn?
        if(_kfMesh->ttIndicies) { // xnt
            return (_kfMesh->ntIndicies[0] <= _kfMesh->ttIndicies[0] ? _kfMesh->ntIndicies[0] : _kfMesh->ttIndicies[0]);
        } else { //xnx
            return _kfMesh->ntIndicies[0];
        }
    } else if(_kfMesh->ttIndicies) { // xxt
        return _kfMesh->ttIndicies[0];
    }
    
    return EGW_TIME_NAN;
}

- (EGWtime)evaluationBoundsEnd {
    if(_kfMesh->vtIndicies) { // v??
        if(_kfMesh->ntIndicies) { // vn?
            if(_kfMesh->ttIndicies) { // vrt
                return (_kfMesh->vtIndicies[_kfMesh->vfCount-1] >= _kfMesh->ntIndicies[_kfMesh->nfCount-1] ?
                        (_kfMesh->vtIndicies[_kfMesh->vfCount-1] >= _kfMesh->ttIndicies[_kfMesh->tfCount-1] ? _kfMesh->vtIndicies[_kfMesh->vfCount-1] : _kfMesh->ttIndicies[_kfMesh->tfCount-1]) :
                        (_kfMesh->ntIndicies[_kfMesh->nfCount-1] >= _kfMesh->ttIndicies[_kfMesh->tfCount-1] ? _kfMesh->ntIndicies[_kfMesh->nfCount-1] : _kfMesh->ttIndicies[_kfMesh->tfCount-1]));
            } else { // vnx
                return (_kfMesh->vtIndicies[_kfMesh->vfCount-1] >= _kfMesh->ntIndicies[_kfMesh->nfCount-1] ? _kfMesh->vtIndicies[_kfMesh->vfCount-1] : _kfMesh->ntIndicies[_kfMesh->nfCount-1]);
            }
        } else if(_kfMesh->ttIndicies) { // vxt
            return (_kfMesh->vtIndicies[_kfMesh->vfCount-1] >= _kfMesh->ttIndicies[_kfMesh->tfCount-1] ? _kfMesh->vtIndicies[_kfMesh->vfCount-1] : _kfMesh->ttIndicies[_kfMesh->tfCount-1]);
        } else { // vxx
            return _kfMesh->vtIndicies[_kfMesh->vfCount-1];
        }
    } else if(_kfMesh->ntIndicies) { // xn?
        if(_kfMesh->ttIndicies) { // xnt
            return (_kfMesh->ntIndicies[_kfMesh->nfCount-1] >= _kfMesh->ttIndicies[_kfMesh->tfCount-1] ? _kfMesh->ntIndicies[_kfMesh->nfCount-1] : _kfMesh->ttIndicies[_kfMesh->tfCount-1]);
        } else { //xnx
            return _kfMesh->ntIndicies[_kfMesh->nfCount-1];
        }
    } else if(_kfMesh->ttIndicies) { // xxt
        return _kfMesh->ttIndicies[_kfMesh->tfCount-1];
    }
    
    return EGW_TIME_NAN;
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

- (EGWuint32)vertexPolationMode {
    return _vTrack.pMode;
}

- (EGWuint32)normalPolationMode {
    return _nTrack.pMode;
}

- (EGWuint32)texturePolationMode {
    return _tTrack.pMode;
}

- (void)setDelegate:(id<egwDGeometryEvent>)delegate {
    [delegate retain];
    [_delegate release];
    _delegate = delegate;
}

- (void)setEvaluationTimer:(id<egwPTimer>)timer {
    [timer retain];
    [_eTimer removeOwner:self];
    [_eTimer release];
    _eTimer = timer;
    [_eTimer addOwner:self];
    
    _isNormNrmlVec = ([_eTimer actuatorFlags] & EGW_ACTOBJ_ACTRFLG_NRMLZVECS ? YES : NO);
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
            NSLog(@"egwKeyFramedMesh: setParent: Warning: Object syttem is overriding WCS interpolator driver for instance asset '%@' (%p).", _ident, self);
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

- (void)setVertexPolationMode:(EGWuint32)vrtPolationMode {
    EGWuint32 ipoMode = (vrtPolationMode & EGW_POLATION_EXINTER);
    EGWuint32 epoMode = (vrtPolationMode & EGW_POLATION_EXEXTRA);
    
    if(ipoMode &&
       (_kfMesh->vfCount >= (ipoMode & EGW_POLATION_EXMNPTCNT)) &&
       (!(ipoMode & EGW_POLATION_EXREQEXTDATA) || _kfMesh->vkfExtraDat) && // Extra data cannot be created on-the-fly (needs to be pre-filled/computed)
       (_vTrack.fpIpoFunc = egwIpoRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, ipoMode)))
        _vTrack.pMode = (_vTrack.pMode & ~EGW_POLATION_EXINTER) | ipoMode;
    else {
        _vTrack.pMode = (_vTrack.pMode & ~EGW_POLATION_EXINTER) | EGW_POLATION_IPO_CONST;
        _vTrack.fpIpoFunc = egwIpoRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, _vTrack.pMode);
    }
    
    if(epoMode &&
       (_kfMesh->vfCount >= ((epoMode & EGW_POLATION_EXMNPTCNT) >> 16)) &&
       (!(epoMode & EGW_POLATION_EXREQEXTDATA) || _kfMesh->vkfExtraDat) && // Extra data cannot be created on-the-fly (needs to be pre-filled/computed)
       (_vTrack.fpEpoFunc = egwEpoRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, epoMode)))
        _vTrack.pMode = (_vTrack.pMode & ~EGW_POLATION_EXEXTRA) | epoMode;
    else {
        _vTrack.pMode = (_vTrack.pMode & ~EGW_POLATION_EXEXTRA) | EGW_POLATION_EPO_CONST;
        _vTrack.fpEpoFunc = egwEpoRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, _vTrack.pMode);
    }
    
    _vTrack.line.okFrame = NULL; // Changing polation mode potentially changes offseted track line
    _vTrack.line.ecdPitch = (EGWuint16)egwIpoExtFrmDatCmpPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 3, _vTrack.pMode);
    _vTrack.line.efdPitch = (EGWuint16)egwIpoExtFrmDatFrmPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 3, _kfMesh->vCount, _vTrack.pMode);
}

- (void)setNormalPolationMode:(EGWuint32)nrmPolationMode {
    EGWuint32 ipoMode = (nrmPolationMode & EGW_POLATION_EXINTER);
    EGWuint32 epoMode = (nrmPolationMode & EGW_POLATION_EXEXTRA);
    
    if(ipoMode &&
       (_kfMesh->nfCount >= (ipoMode & EGW_POLATION_EXMNPTCNT)) &&
       (!(ipoMode & EGW_POLATION_EXREQEXTDATA) || _kfMesh->nkfExtraDat) && // Extra data cannot be created on-the-fly (needs to be pre-filled/computed)
       (_nTrack.fpIpoFunc = egwIpoRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, ipoMode)))
        _nTrack.pMode = (_nTrack.pMode & ~EGW_POLATION_EXINTER) | ipoMode;
    else {
        _nTrack.pMode = (_nTrack.pMode & ~EGW_POLATION_EXINTER) | EGW_POLATION_IPO_CONST;
        _nTrack.fpIpoFunc = egwIpoRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, _nTrack.pMode);
    }
    
    if(epoMode &&
       (_kfMesh->nfCount >= ((epoMode & EGW_POLATION_EXMNPTCNT) >> 16)) &&
       (!(epoMode & EGW_POLATION_EXREQEXTDATA) || _kfMesh->nkfExtraDat) && // Extra data cannot be created on-the-fly (needs to be pre-filled/computed)
       (_nTrack.fpEpoFunc = egwEpoRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, epoMode)))
        _nTrack.pMode = (_nTrack.pMode & ~EGW_POLATION_EXEXTRA) | epoMode;
    else {
        _nTrack.pMode = (_nTrack.pMode & ~EGW_POLATION_EXEXTRA) | EGW_POLATION_EPO_CONST;
        _nTrack.fpEpoFunc = egwEpoRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, _nTrack.pMode);
    }
    
    _nTrack.line.okFrame = NULL; // Changing polation mode potentially changes offseted track line
    _nTrack.line.ecdPitch = (EGWuint16)egwIpoExtFrmDatCmpPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 3, _nTrack.pMode);
    _nTrack.line.efdPitch = (EGWuint16)egwIpoExtFrmDatFrmPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 3, _kfMesh->vCount, _nTrack.pMode);
}

- (void)setTexturePolationMode:(EGWuint32)texPolationMode {
    EGWuint32 ipoMode = (texPolationMode & EGW_POLATION_EXINTER);
    EGWuint32 epoMode = (texPolationMode & EGW_POLATION_EXEXTRA);
    
    if(ipoMode &&
       (_kfMesh->tfCount >= (ipoMode & EGW_POLATION_EXMNPTCNT)) &&
       (!(ipoMode & EGW_POLATION_EXREQEXTDATA) || _kfMesh->tkfExtraDat) && // Extra data cannot be created on-the-fly (needs to be pre-filled/computed)
       (_tTrack.fpIpoFunc = egwIpoRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, ipoMode)))
        _tTrack.pMode = (_tTrack.pMode & ~EGW_POLATION_EXINTER) | ipoMode;
    else {
        _tTrack.pMode = (_tTrack.pMode & ~EGW_POLATION_EXINTER) | EGW_POLATION_IPO_CONST;
        _tTrack.fpIpoFunc = egwIpoRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, _tTrack.pMode);
    }
    
    if(epoMode &&
       (_kfMesh->tfCount >= ((epoMode & EGW_POLATION_EXMNPTCNT) >> 16)) &&
       (!(epoMode & EGW_POLATION_EXREQEXTDATA) || _kfMesh->tkfExtraDat) && // Extra data cannot be created on-the-fly (needs to be pre-filled/computed)
       (_tTrack.fpEpoFunc = egwEpoRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, epoMode)))
        _tTrack.pMode = (_tTrack.pMode & ~EGW_POLATION_EXEXTRA) | epoMode;
    else {
        _tTrack.pMode = (_tTrack.pMode & ~EGW_POLATION_EXEXTRA) | EGW_POLATION_EPO_CONST;
        _tTrack.fpEpoFunc = egwEpoRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, _tTrack.pMode);
    }
    
    _tTrack.line.okFrame = NULL; // Changing polation mode potentially changes offseted track line
    _tTrack.line.ecdPitch = (EGWuint16)egwIpoExtFrmDatCmpPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 2, _tTrack.pMode);
    _tTrack.line.efdPitch = (EGWuint16)egwIpoExtFrmDatFrmPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 2, _kfMesh->vCount, _tTrack.pMode);
}

- (BOOL)trySetGeometryDataPersistence:(BOOL)persist {
    return NO; // Geometry data is always persistent
}

- (BOOL)trySetGeometryStorage:(EGWuint)storage {
    if(_ipMesh.vCoords && _ipMesh.nCoords) {
        _geoStrg = storage;
        
        egwSFPVldtrInvalidate(_gbSync, @selector(invalidate));
        
        return YES;
    }
    
    return NO;
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

- (BOOL)isInvokingParent {
    return _invkParent;
}

- (BOOL)isLeaf {
    return YES;
}

- (BOOL)isGeometryDataPersistent {
    return YES; // Geometry data is always persistent in this current implementation
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
    } else if(_gbSync == validater) {
        if((_geoStrg & EGW_GEOMETRY_STRG_EXVBO) && _ipMesh.vCoords && _ipMesh.nCoords && _ipMesh.fIndicies) // Buffer mesh data up through context
            [egwAIGfxCntx addSubTask:self forSync:_gbSync];
        else
            egwSFPVldtrValidate(_gbSync, @selector(validate));
    }
}

@end


// !!!: ***** egwKeyFramedMeshBase *****

@implementation egwKeyFramedMeshBase

+ (id)allocWithZone:(NSZone*)zone {
    id alloc = [super allocWithZone:zone];
    if(alloc) [egwAssetManager incBaseRef];
    if(EGW_ENGINE_ASSETS_CREATIONMSGS) NSLog(@"egwKeyFramedMeshBase: allocWithZone: Creating new key framed mesh base asset (%p).", alloc);
    return alloc;
}

- (id)init {
    if([self isMemberOfClass:[egwKeyFramedMeshBase class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent keyFramedMesh:(egwKFJITVAMeshf*)keyFrmdMeshData meshBounding:(Class)bndClass {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    if(keyFrmdMeshData && keyFrmdMeshData->vCount && keyFrmdMeshData->fCount && keyFrmdMeshData->vCount <= keyFrmdMeshData->fCount * 3 && keyFrmdMeshData->vkCoords && keyFrmdMeshData->fIndicies && (keyFrmdMeshData->vfCount || keyFrmdMeshData->nfCount || keyFrmdMeshData->tfCount)) {
        memcpy((void*)&_kfMesh, (const void*)keyFrmdMeshData, sizeof(egwKFJITVAMeshf));
        memset((void*)keyFrmdMeshData, 0, sizeof(egwKFJITVAMeshf));
    } else { [self release]; return (self = nil); }
    
    // Bounding volume only gets used in lazy boundings, so make it scan the entire set of possible vertex positions
    if(!(_mmcsRBVol = [[(bndClass && [bndClass conformsToProtocol:@protocol(egwPBounding)] ? bndClass : [egwBoundingSphere class]) alloc] initWithOpticalSource:NULL vertexCount:(_kfMesh.vCount * (_kfMesh.vfCount ? _kfMesh.vfCount : 1)) vertexCoords:_kfMesh.vkCoords vertexCoordsStride:0])) { [self release]; return (self = nil); }
    
    return self;
}

- (id)initBlankWithIdentity:(NSString*)assetIdent vertexCount:(EGWuint16)vrtxCount faceCount:(EGWuint16)faceCount vertexFrameCount:(EGWuint16)vrtFrmCount normalFrameCount:(EGWuint16)nrmFrmCount textureFrameCount:(EGWuint16)texFrmCount {
    if(!vrtxCount || !faceCount || vrtxCount > 3 * faceCount || !(vrtFrmCount || nrmFrmCount || texFrmCount) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    if(!egwMeshAllocKFJITVAf(&_kfMesh, vrtxCount, vrtxCount, vrtxCount, faceCount, vrtFrmCount, nrmFrmCount, texFrmCount)) { [self release]; return (self = nil); }
    
    _mmcsRBVol = nil; // will require manual rebinding later
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    return nil;
}

- (id)mutableCopyWithZone:(NSZone*)zone {
    return nil;
}

- (void)dealloc {
    [_mmcsRBVol release]; _mmcsRBVol = nil;
    egwMeshFreeKFJITVAf(&_kfMesh);
    
    if(EGW_ENGINE_ASSETS_DESTROYMSGS) NSLog(@"egwKeyFramedMeshBase: dealloc: Destroying key framed mesh base asset '%@' (%p).", _ident, self);
    [_ident release]; _ident = nil;
    [egwAssetManager decBaseRef];
    [super dealloc];
}

- (void)baseOffsetByTransform:(const egwMatrix44f*)transform {
    egwVecTransform443fv(transform, _kfMesh.vkCoords, &egwSIOnef, _kfMesh.vkCoords, -sizeof(egwMatrix44f), 0, -sizeof(EGWsingle), 0, _kfMesh.vCount * (_kfMesh.vfCount ? _kfMesh.vfCount : 1));
    egwVecTransform443fv(transform, _kfMesh.nkCoords, &egwSIZerof, _kfMesh.nkCoords, -sizeof(egwMatrix44f), 0, -sizeof(EGWsingle), 0, _kfMesh.vCount * (_kfMesh.nfCount ? _kfMesh.nfCount : 1));
    
    [_mmcsRBVol baseOffsetByTransform:transform];
}

- (void)baseOffsetByZeroAlign:(EGWuint)zfAlign {
    egwVector3f offset, min, max;
    egwMatrix44f transform;
    
    egwVecFindExtentsAxs3fv(_kfMesh.vkCoords, &min, &max, 0, _kfMesh.vCount);
    
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

- (void)reboundWithClass:(Class)bndClass {
    [_mmcsRBVol release];
    
    // Bounding volume only gets used in lazy boundings, so make it scan the entire set of possible vertex positions
    _mmcsRBVol = [[(bndClass && [bndClass conformsToProtocol:@protocol(egwPBounding)] ? bndClass : [egwBoundingSphere class]) alloc] initWithOpticalSource:NULL vertexCount:(_kfMesh.vCount * (_kfMesh.vfCount ? _kfMesh.vfCount : 1)) vertexCoords:_kfMesh.vkCoords vertexCoordsStride:0];
}

- (NSString*)identity {
    return _ident;
}

- (egwKFJITVAMeshf*)keyFramedMesh {
    return &_kfMesh;
}

- (EGWuint)nextInstanceIndex {
    return ++_instCounter;
}

- (id<egwPBounding>)renderingBounding {
    return _mmcsRBVol;
}

@end

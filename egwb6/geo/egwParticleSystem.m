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

/// @file egwParticleSystem.m
/// @ingroup geWizES_geo_particlesystem
/// Animated Point Sprite Particle System Asset Implementation.

#import "egwParticleSystem.h"
#import "../sys/egwSysTypes.h"
#import "../sys/egwAssetManager.h"
#import "../sys/egwGfxContext.h"
#import "../sys/egwGfxContextNSGL.h"  // NOTE: Below code has a dependence on GL.
#import "../sys/egwGfxContextEAGLES.h"
#import "../sys/egwGfxRenderer.h"
#import "../sys/egwPhyActuator.h"
#import "../math/egwVector.h"
#import "../math/egwMatrix.h"
#import "../data/egwArray.h"
#import "../gfx/egwGraphics.h"
#import "../gfx/egwBindingStacks.h"
#import "../gfx/egwBoundings.h"
#import "../gfx/egwMaterials.h"
#import "../gfx/egwTexture.h"
#import "../geo/egwGeometry.h"
#import "../obj/egwObjectBranch.h"
#import "../phy/egwInterpolators.h"
#import "../misc/egwValidater.h"


static void egwPSysRemoveParticle(egwPSParticle* particle) {
    if(particle->twcsTrans) {
        free((void*)particle->twcsTrans); particle->twcsTrans = NULL;
    }
}


// !!!: ***** egwParticleSystem *****

@implementation egwParticleSystem

static egwRenderableJumpTable _egwRJT = { NULL };
static egwActuatorJumpTable _egwAJT = { NULL };

+ (id)allocWithZone:(NSZone*)zone {
    NSObject* inst = (NSObject*)[super allocWithZone:zone];
    
    if(!_egwRJT.fpRetain && [inst isMemberOfClass:[egwParticleSystem class]]) {
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
        _egwAJT.fpRetain = (id(*)(id, SEL))[inst methodForSelector:@selector(retain)];
        _egwAJT.fpRelease = (void(*)(id, SEL))[inst methodForSelector:@selector(release)];
        _egwAJT.fpUpdate = (void(*)(id, SEL, EGWtime, EGWuint))[inst methodForSelector:@selector(update:withFlags:)];
        _egwAJT.fpABase = (id<NSObject>(*)(id, SEL))[inst methodForSelector:@selector(assetBase)];
        _egwAJT.fpAFlags = (EGWuint32(*)(id, SEL))[inst methodForSelector:@selector(actuatorFlags)];
        _egwAJT.fpActuating = (BOOL(*)(id, SEL))[inst methodForSelector:@selector(isActuating)];
        _egwAJT.fpFinished = (BOOL(*)(id, SEL))[inst methodForSelector:@selector(isFinished)];
    }
    
    return (id)inst;
}

- (id)init {
    if([self isMemberOfClass:[egwParticleSystem class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent particleDynamics:(egwPSParticleDynamics*)partDyn systemDynamics:(egwPSSystemDynamics*)sysDyn systemBounding:(Class)bndClass geometryStorage:(EGWuint)storage lightStack:(egwLightStack*)lghtStack shaderStack:(egwShaderStack*)shdrStack textureStack:(egwTextureStack*)txtrStack {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwParticleSystemBase alloc] initWithIdentity:assetIdent particleDynamics:partDyn systemDynamics:sysDyn])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _aFlags = EGW_ACTOBJ_ACTRFLG_DFLT;
    _rFlags = EGW_GFXOBJ_RNDRFLG_DFLT;
    _rFrame = EGW_FRAME_ALWAYSPASS;
    _vFrame = EGW_FRAME_ALWAYSFAIL;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = (lghtStack ? [lghtStack retain] : [[egwLightStack alloc] init]))) { [self release]; return (self = nil); }
    _sStack = (shdrStack ? [shdrStack retain] : nil);
    _tStack = (txtrStack ? [txtrStack retain] : nil);
    
    _drvTex = [[_tStack firstTimedTexture] retain];
    _dtJmpTbl = [_drvTex textureJumpTable];
    _drvTexBegAbsT = (_drvTex ? [_drvTex evaluationBoundsBegin] : (EGWtime)0.0);
    _drvTexEndAbsT = (_drvTex ? [_drvTex evaluationBoundsEnd] : (EGWtime)0.0);
    egwVecCopy4f(&egwSIVecZero4f, &_wcsExtForce);
    egwVecCopy4f(&egwSIVecZero4f, &_mmcsExtForce);
    _wcsGrndLevel = _mmcsGrndLevel = -EGW_SFLT_MAX;
    _mmUpPos[0].axis.x = _mmUpPos[0].axis.y = _mmUpPos[0].axis.z = EGW_SFLT_MAX;
    _mmUpPos[1].axis.x = _mmUpPos[1].axis.y = _mmUpPos[1].axis.z = -EGW_SFLT_MAX;
    
    _geoStrg = storage;
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_twcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_twcsInverse);
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_broTrans);
    if(!(_wcsRBVol = [[(bndClass && [bndClass conformsToProtocol:@protocol(egwPBounding)] ? bndClass : [egwBoundingBox class]) alloc] init])) { [self release]; return (self = nil); }
    if(!(_mmcsRBVol = [[(bndClass && [bndClass conformsToProtocol:@protocol(egwPBounding)] ? bndClass : [egwBoundingBox class]) alloc] init])) { [self release]; return (self = nil); }
    
    _mcsTrans = [_base mcsTransform];
    _pDynamics = [_base particleDynamics];
    _sDynamics = [_base systemDynamics];
    _mmStPos = [_base minMaxStartPosition];
    
    _mParts = _sDynamics->mParticles;
    _psFlags = _sDynamics->psFlags;
    {   egwDataFuncs funcs; memset((void*)&funcs, 0, sizeof(egwDataFuncs));
        funcs.fpRemove = (EGWelementfp)&egwPSysRemoveParticle;
        if(!(egwArrayInit(&_particles, &funcs, sizeof(egwPSParticle), (_mParts ? _mParts : 10), (_mParts ? EGW_ARRAY_FLG_DFLT : EGW_ARRAY_FLG_NONE)))) { [self release]; return (self = nil); }
    }
    
    _isPntSprtAvail = [egwAIGfxCntx isExtAvailable:@"GL_OES_point_sprite"] || [egwAIGfxCntx isExtAvailable:@"GL_ARB_point_sprite"];
    _isPntSzAryAval = [egwAIGfxCntx isExtAvailable:@"GL_OES_point_size_array"];
    _isPntSzStatic = egwIsZerof(_pDynamics->pSize.deltaT) && egwIsZerof(_pDynamics->pSize.variant);
    _isBBQuadRndrd = ((!(_isPntSprtAvail && (_isPntSzAryAval || _isPntSzStatic)) || (_psFlags & EGW_PSYSFLAG_NOPOINTSPRT) || _drvTex) ? YES : NO);
    _velDelta = (!(_psFlags & EGW_PSYSFLAG_VELUSEPYM) ? (const egwVector3f*)&_pDynamics->pVelocity.deltaT : (const egwVector3f*)[_base sphericalVelocityDelta]);
    
    return self;
}

- (id)initCopyOf:(id<egwPGeometry>)geometry withIdentity:(NSString*)assetIdent {
    if(!([geometry isKindOfClass:[self class]]) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = (egwParticleSystemBase*)[[(id<egwPAsset>)geometry assetBase] retain])) { [self release]; return (self = nil); }
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _aFlags = [(egwParticleSystem*)geometry actuatorFlags];
    _rFlags = [(egwParticleSystem*)geometry renderingFlags];
    _rFrame = EGW_FRAME_ALWAYSPASS;
    _vFrame = EGW_FRAME_ALWAYSFAIL;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = [[geometry lightStack] retain])) { [self release]; return (self = nil); }
    _sStack = [[geometry shaderStack] retain];
    _tStack = [[geometry textureStack] retain];
    
    _drvTex = [[_tStack firstTimedTexture] retain];
    _dtJmpTbl = [_drvTex textureJumpTable];
    _drvTexBegAbsT = (_drvTex ? [_drvTex evaluationBoundsBegin] : (EGWtime)0.0);
    _drvTexEndAbsT = (_drvTex ? [_drvTex evaluationBoundsEnd] : (EGWtime)0.0);
    egwVecCopy3f((const egwVector3f*)[(egwParticleSystem*)geometry externalForce], (egwVector3f*)&_wcsExtForce); _wcsExtForce.axis.w = 0.0f;
    egwVecCopy4f(&egwSIVecZero4f, &_mmcsExtForce);
    _wcsGrndLevel = [(egwParticleSystem*)geometry groundLevel];
    _mmcsGrndLevel = -EGW_SFLT_MAX;
    
    if(!(_psFlags & EGW_PSYSFLAG_EMITTOWCS) && (!egwVecIsEqual3f((egwVector3f*)&_wcsExtForce, &egwSIVecZero3f) || _wcsGrndLevel != -EGW_SFLT_MAX))
        _ortPending = YES;
    
    _mParts = [(egwParticleSystem*)geometry maximumParticles];
    _psFlags = [(egwParticleSystem*)geometry systemFlags];
    _mmUpPos[0].axis.x = _mmUpPos[0].axis.y = _mmUpPos[0].axis.z = EGW_SFLT_MAX;
    _mmUpPos[1].axis.x = _mmUpPos[1].axis.y = _mmUpPos[1].axis.z = -EGW_SFLT_MAX;
    {   egwDataFuncs funcs; memset((void*)&funcs, 0, sizeof(egwDataFuncs));
        funcs.fpRemove = (EGWelementfp)&egwPSysRemoveParticle;
        if(!(egwArrayInit(&_particles, &funcs, sizeof(egwPSParticle), (_mParts ? _mParts : 10), (_mParts ? EGW_ARRAY_FLG_DFLT : EGW_ARRAY_FLG_NONE)))) { [self release]; return (self = nil); }
    }
    
    _geoStrg = [(egwParticleSystem*)geometry geometryStorage];
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_twcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_twcsInverse);
    egwMatCopy44f([(egwParticleSystem*)geometry wcsTransform], &_wcsTrans);
    egwMatCopy44f([(egwParticleSystem*)geometry lcsTransform], &_lcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_broTrans);
    if(!(_wcsRBVol = [(NSObject*)[(egwParticleSystem*)geometry renderingBounding] copy])) { [self release]; return (self = nil); }
    else [_wcsRBVol reset];
    if(!(_mmcsRBVol = [(NSObject*)_wcsRBVol copy])) { [self release]; return (self = nil); }
    else [_mmcsRBVol reset];
    if([(id<egwPOrientated>)geometry offsetDriver] && ![self trySetOffsetDriver:[(id<egwPOrientated>)geometry offsetDriver]]) { [self release]; return (self = nil); }
    if([(id<egwPOrientated>)geometry orientateDriver] && ![self trySetOrientateDriver:[(id<egwPOrientated>)geometry orientateDriver]]) { [self release]; return (self = nil); }
    
    _mcsTrans = [_base mcsTransform];
    _pDynamics = [_base particleDynamics];
    _sDynamics = [_base systemDynamics];
    _mmStPos = [_base minMaxStartPosition];
    
    _isPntSprtAvail = [egwAIGfxCntx isExtAvailable:@"GL_OES_point_sprite"] || [egwAIGfxCntx isExtAvailable:@"GL_ARB_point_sprite"];
    _isPntSzAryAval = [egwAIGfxCntx isExtAvailable:@"GL_OES_point_size_array"];
    _isPntSzStatic = egwIsZerof(_pDynamics->pSize.deltaT) && egwIsZerof(_pDynamics->pSize.variant);
    _isBBQuadRndrd = ((!(_isPntSprtAvail && (_isPntSzAryAval || _isPntSzStatic)) || (_psFlags & EGW_PSYSFLAG_NOPOINTSPRT) || _drvTex) ? YES : NO);
    _velDelta = (!(_psFlags & EGW_PSYSFLAG_VELUSEPYM) ? (const egwVector3f*)&_pDynamics->pVelocity.deltaT : (const egwVector3f*)[_base sphericalVelocityDelta]);
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwParticleSystem* copy = nil;
    NSString* copyIdent = nil;
    
    if([_ident hasSuffix:@"_default"])
        copyIdent = [[NSString alloc] initWithFormat:@"%@_%d", [_base identity], [_base nextInstanceIndex]];
    else copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwParticleSystem allocWithZone:zone] initCopyOf:self
                                                      withIdentity:copyIdent])) {
        NSLog(@"egwParticleSystem: copyWithZone: Failure initializing new particle system from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    return copy;
}

- (void)dealloc {
    if(_geoAID)
        _geoAID = [egwAIGfxCntxAGL returnUsedBufferID:_geoAID];
    
    [_drvTex release]; _drvTex = nil;
    _dtJmpTbl = NULL;
    if(_pMesh) {
        free((void*)_pMesh); _pMesh = NULL;
    }
    egwArrayFree(&_particles);
    
    _mcsTrans = NULL;
    _pDynamics = NULL;
    _sDynamics = NULL;
    _mmStPos = NULL;
    _velDelta = NULL;
    
    [_wcsRBVol release]; _wcsRBVol = nil;
    
    if(_lcsIpo) { [_lcsIpo removeTargetWithObject:self]; [_lcsIpo release]; _lcsIpo = nil; }
    if(_wcsIpo) { [_wcsIpo removeTargetWithObject:self]; [_wcsIpo release]; _wcsIpo = nil; }
    
    _vCamera = nil;
    _vcwcsTrans = NULL;
    [_lStack release]; _lStack = nil;
    //[_mStack release]; _mStack = nil;
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
            
            if(!(_psFlags & EGW_PSYSFLAG_EMITTOWCS)) {
                EGWsingle det = egwMatDeterminant44f(&_twcsTrans);
                if(egwIsOnef(egwAbsf(det)))
                    egwMatInvertOtg44f(&_twcsTrans, &_twcsInverse);
                else
                    egwMatInvertDet44f(&_twcsTrans, det, &_twcsInverse);
                
                if(!(_rFlags & EGW_OBJEXTEND_FLG_LAZYBOUNDING)) {
                    if(_particles.eCount) {
                        if([_mmcsRBVol isReset])
                            [_mmcsRBVol initWithOpticalSource:NULL vertexCount:_particles.eCount vertexCoords:(const egwVector3f*)&(((const egwPSParticle*)_particles.rData)[0].position) vertexCoordsStride:(EGWintptr)sizeof(egwPSParticle)];
                        
                        [_wcsRBVol orientateByTransform:&_twcsTrans fromVolume:_mmcsRBVol];
                    } else {
                        [_mmcsRBVol reset];
                        [_wcsRBVol reset];
                    }
                } else {
                    if(_particles.eCount) {
                        if([_mmcsRBVol isReset])
                            [_mmcsRBVol initWithOpticalSource:NULL vertexCount:2 vertexCoords:(const egwVector3f*)&_mmUpPos[0] vertexCoordsStride:0];
                        
                        [_wcsRBVol orientateByTransform:&_twcsTrans fromVolume:_mmcsRBVol];
                    } else {
                        [_mmcsRBVol reset];
                        [_wcsRBVol reset];
                    }
                }
            } else {
                if(!(_rFlags & EGW_OBJEXTEND_FLG_LAZYBOUNDING)) {
                    if(_particles.eCount) {
                        if([_wcsRBVol isReset])
                            [_wcsRBVol initWithOpticalSource:NULL vertexCount:_particles.eCount vertexCoords:(const egwVector3f*)&(((const egwPSParticle*)_particles.rData)[0].position) vertexCoordsStride:(EGWintptr)sizeof(egwPSParticle)];
                    } else {
                        [_wcsRBVol reset];
                    }
                } else {
                    if(_particles.eCount) {
                        if([_wcsRBVol isReset])
                            [_wcsRBVol initWithOpticalSource:NULL vertexCount:2 vertexCoords:(const egwVector3f*)&_mmUpPos[0] vertexCoordsStride:0];
                    } else {
                        [_wcsRBVol reset];
                    }
                }
            }
        } else {
            egwMatMultiplyHmg44f(&_wcsTrans, &_lcsTrans, &_twcsTrans);
            
            if(!(_psFlags & EGW_PSYSFLAG_EMITTOWCS)) {
                egwMatInvertOtg44f(&_twcsTrans, &_twcsInverse);
                
                if(!(_rFlags & EGW_OBJEXTEND_FLG_LAZYBOUNDING)) {
                    if(_particles.eCount) {
                        if([_mmcsRBVol isReset])
                            [_mmcsRBVol initWithOpticalSource:NULL vertexCount:_particles.eCount vertexCoords:(const egwVector3f*)&(((const egwPSParticle*)_particles.rData)[0].position) vertexCoordsStride:(EGWintptr)sizeof(egwPSParticle)];
                        
                        [_wcsRBVol orientateByTransform:&_twcsTrans fromVolume:_mmcsRBVol];
                    } else {
                        [_mmcsRBVol reset];
                        [_wcsRBVol reset];
                    }
                } else {
                    if(_particles.eCount) {
                        if([_mmcsRBVol isReset])
                            [_mmcsRBVol initWithOpticalSource:NULL vertexCount:2 vertexCoords:(const egwVector3f*)&_mmUpPos[0] vertexCoordsStride:0];
                        
                        [_wcsRBVol orientateByTransform:&_twcsTrans fromVolume:_mmcsRBVol];
                    } else {
                        [_mmcsRBVol reset];
                        [_wcsRBVol reset];
                    }
                }
            } else {
                if(!(_rFlags & EGW_OBJEXTEND_FLG_LAZYBOUNDING)) {
                    if(_particles.eCount) {
                        if([_wcsRBVol isReset])
                            [_wcsRBVol initWithOpticalSource:NULL vertexCount:_particles.eCount vertexCoords:(const egwVector3f*)&(((const egwPSParticle*)_particles.rData)[0].position) vertexCoordsStride:(EGWintptr)sizeof(egwPSParticle)];
                    } else {
                        [_wcsRBVol reset];
                    }
                } else {
                    if(_particles.eCount) {
                        if([_wcsRBVol isReset])
                            [_wcsRBVol initWithOpticalSource:NULL vertexCount:2 vertexCoords:(const egwVector3f*)&_mmUpPos[0] vertexCoordsStride:0];
                    } else {
                        [_wcsRBVol reset];
                    }
                }
            }
        }
        
        if(!(_psFlags & EGW_PSYSFLAG_EMITTOWCS)) {
            egwVecTransform444f(&_twcsInverse, &_wcsExtForce, &_mmcsExtForce);
            _isExtForceApp = (!egwVecIsEqual3f((egwVector3f*)&_mmcsExtForce, &egwSIVecZero3f) ? YES : NO);
            
            if(_wcsGrndLevel != -EGW_SFLT_MAX)
                _mmcsGrndLevel = _twcsInverse.component.r2c3 * _wcsGrndLevel + _twcsInverse.component.r2c4;
            else
                _mmcsGrndLevel = -EGW_SFLT_MAX;
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
        _wcsRBVol = [[(bndClass && [bndClass conformsToProtocol:@protocol(egwPBounding)] ? bndClass : [egwBoundingBox class]) alloc] init];
    }
    
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (void)startActuating {
    [egwSIPhyAct actuateObject:self];
}

- (void)startRendering {
    [egwSIGfxRdr renderObject:self]; // TODO: Replace with call to world scene.
}

- (void)stopActuating {
    [egwSIPhyAct removeObject:self];
}

- (void)stopRendering {
    [egwSIGfxRdr removeObject:self]; // TODO: Replace with call to world scene.
}

- (void)renderWithFlags:(EGWuint32)flags {
    // NOTE: The code below is non-abstracted OpenGLES dependent. Staying this way till ES2. -jw
    if(flags & EGW_GFXOBJ_RPLYFLY_DORENDERPASS) {
        if(_particles.eCount) {
            if(_lStack) egwSFPLghtStckPushAndBindLights(_lStack, @selector(pushAndBindLights));
            else egwAFPGfxCntxBindLights(egwAIGfxCntx, @selector(bindLights));
            egwAFPGfxCntxBindMaterials(egwAIGfxCntx, @selector(bindMaterials));
            [egwAIGfxCntx reportDirtyMaterialBindForSurfacingStage:0]; // Will be setting our own coloration, so need to mark existing bind as dirty
            if(_sStack) egwSFPShdrStckPushAndBindShaders(_sStack, @selector(pushAndBindShaders));
            else egwAFPGfxCntxBindShaders(egwAIGfxCntx, @selector(bindShaders));
            
            glPushMatrix();
            
            if(!(_psFlags & EGW_PSYSFLAG_EMITTOWCS))
                glMultMatrixf((const GLfloat*)&_twcsTrans);
            
            #if defined(GL_POINT_SPRITE) || defined(GL_POINT_SPRITE_OES)
            if(_isBBQuadRndrd) { // Use billboarded quads
            #endif
                if(_tStack) {
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
                            if(!(_psFlags & EGW_PSYSFLAG_EMITTOWCS)) {
                                if(!(_rFlags & EGW_OBJEXTEND_FLG_ALWAYSOTGHMG))
                                    egwMatMultiply44f(&_twcsInverse, _vcwcsTrans, &_broTrans);
                                else
                                    egwMatMultiplyHmg44f(&_twcsInverse, _vcwcsTrans, &_broTrans);
                            } else // WCS particles do not require inversion run through, just the normal camera wcs matrix
                                egwMatCopy44f(_vcwcsTrans, &_broTrans);
                            _broTrans.component.r1c4 = _broTrans.component.r2c4 = _broTrans.component.r3c4 = 0.0f; // Remove inverse offset
                            
                            _vFrame = vFrame;
                            
                            // NOTE: Since the particles are treated as infinitely small dots, the rendering volume is not effected by the BRO transform. -jw
                        }
                    }
                    
                    if(!_pMesh && (!(_geoStrg & EGW_GEOMETRY_STRG_EXVBO) || !_geoAID)) {
                        _pMesh = (egwSQVAMesh4f*)malloc(sizeof(egwSQVAMesh4f)); memset((void*)_pMesh, 0, sizeof(egwSQVAMesh4f));
                        
                        _pMesh->vCoords[0].axis.x = _pMesh->vCoords[3].axis.x = -1.0f;
                        _pMesh->vCoords[1].axis.x = _pMesh->vCoords[2].axis.x =  1.0f;
                        _pMesh->vCoords[0].axis.y = _pMesh->vCoords[1].axis.y = -1.0f;
                        _pMesh->vCoords[2].axis.y = _pMesh->vCoords[3].axis.y =  1.0f;
                        
                        _pMesh->nCoords[0].axis.z = _pMesh->nCoords[1].axis.z =
                            _pMesh->nCoords[2].axis.z = _pMesh->nCoords[3].axis.z = 1.0f;
                        
                        _pMesh->tCoords[0].axis.x = _pMesh->tCoords[3].axis.x = 0.0f + EGW_WIDGET_TXCCORRECT;
                        _pMesh->tCoords[1].axis.x = _pMesh->tCoords[2].axis.x = 1.0f - EGW_WIDGET_TXCCORRECT;
                        _pMesh->tCoords[0].axis.y = _pMesh->tCoords[1].axis.y = 1.0f - EGW_WIDGET_TXCCORRECT;
                        _pMesh->tCoords[2].axis.y = _pMesh->tCoords[3].axis.y = 0.0f + EGW_WIDGET_TXCCORRECT;
                        
                        if(_geoStrg & EGW_GEOMETRY_STRG_EXVBO) {
                            if([egwAIGfxCntxAGL loadBufferArraysID:&_geoAID withSQVAMesh:_pMesh geometryStorage:_geoStrg]) {
                                free((void*)_pMesh); _pMesh = nil;
                            } else {
                                NSLog(@"egwParticleSystem: renderWithFlags: Failure buffering geometry mesh for asset '%@' (%p).", _ident, self);
                                _geoStrg = EGW_GEOMETRY_STRG_NONE; // Don't try beyond here to buffer this over
                            }
                        }
                    }
                    
                    egwSFPTxtrStckPushAndBindTextures(_tStack, @selector(pushAndBindTextures));
                    
                    if(_geoAID) {
                        egw_glBindBuffer(GL_ARRAY_BUFFER, _geoAID);
                        glVertexPointer((GLint)3, GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)0);
                        glNormalPointer(GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)((EGWuint)sizeof(egwVector3f) * 4));
                        glTexCoordPointer((GLint)2, GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)((EGWuint)sizeof(egwVector3f) * 4 * 2));
                    } else {
                        egw_glBindBuffer(GL_ARRAY_BUFFER, 0);
                        
                        glVertexPointer((GLint)3, GL_FLOAT, (GLsizei)0, (const GLvoid*)&_pMesh->vCoords[0]);
                        glNormalPointer(GL_FLOAT, (GLsizei)0, (const GLvoid*)&_pMesh->nCoords[0]);
                        glTexCoordPointer((GLint)2, GL_FLOAT, (GLsizei)0, (const GLvoid*)&_pMesh->tCoords[0]);
                    }
                    
                    for(EGWint pIndex = 0; pIndex < (EGWint)_particles.eCount; ++pIndex) {
                        egwPSParticle* particle = &(((egwPSParticle*)_particles.rData)[pIndex]);
                        EGWsingle size = egwMax2f(0.0f, particle->size * EGW_PSYS_NPQUADSZMLTPLR);
                        if(size <= EGW_SFLT_EPSILON)
                            continue;
                        
                        if(_drvTex) {
                            [_drvTex evaluateToTime:egwClampm(particle->ltAlive, _drvTexBegAbsT, _drvTexEndAbsT)];
                            _dtJmpTbl->fpTBind(_drvTex, @selector(bindForTexturingStage:withFlags:), _dtJmpTbl->fpTLBStage(_drvTex, @selector(lastTexturingBindingStage)), ((pIndex ? EGW_BNDOBJ_BINDFLG_SAMELASTBASE : 0) | EGW_BNDOBJ_BINDFLG_APISYNCINVLD | (flags & EGW_GFXOBJ_RPLYFLG_MACHSCHNELL ? EGW_BNDOBJ_BINDFLG_MACHSCHNELL : 0)));
                        }
                        
                        glPushMatrix();
                        
                        egwVecCopy3f(&particle->position, (egwVector3f*)&_broTrans.column[3]);
                        glMultMatrixf((const GLfloat*)&_broTrans);
                        glMultMatrixf((const GLfloat*)_mcsTrans);
                        glScalef(size, size, 1.0f);
                        
                        glColor4f(particle->color.channel.r, particle->color.channel.g, particle->color.channel.b, particle->color.channel.a);
                        
                        glDrawArrays(GL_TRIANGLE_FAN, (GLint)0, (GLsizei)4);
                        
                        glPopMatrix();
                    }
                    
                    egwSFPTxtrStckPopTextures(_tStack, @selector(popTextures));
                } else { // Non-textured render
                    egwAFPGfxCntxBindTextures(egwAIGfxCntx, @selector(bindTextures));
                    
                    glMultMatrixf((const GLfloat*)_mcsTrans);
                    
                    egw_glBindBuffer(GL_ARRAY_BUFFER, 0);
                    
                    #if defined(GL_POINT_SIZE_ARRAY_OES)
                        if(_isPntSzAryAval && !_isPntSzStatic) {
                            glEnableClientState(GL_COLOR_ARRAY);
                            glEnableClientState(GL_POINT_SIZE_ARRAY_OES);
                            glDisableClientState(GL_NORMAL_ARRAY);
                            
                            glVertexPointer((GLint)3, GL_FLOAT, (GLsizei)sizeof(egwPSParticle), (const GLvoid*)&(((const egwPSParticle*)_particles.rData)[0].position));
                            glPointSizePointerOES(GL_FLOAT, (GLsizei)sizeof(egwPSParticle), (const GLvoid*)&(((const egwPSParticle*)_particles.rData)[0].size));
                            glColorPointer((GLint)4, GL_FLOAT, (GLsizei)sizeof(egwPSParticle), (const GLvoid*)&(((const egwPSParticle*)_particles.rData)[0].color));
                            
                            glDrawArrays(GL_POINTS, (GLint)0, (GLsizei)_particles.eCount);
                            
                            glEnableClientState(GL_NORMAL_ARRAY);
                            glDisableClientState(GL_POINT_SIZE_ARRAY_OES);
                            glDisableClientState(GL_COLOR_ARRAY);
                        } else
                    #endif
                    if(_isPntSzStatic) {
                        glEnableClientState(GL_COLOR_ARRAY);
                        glDisableClientState(GL_NORMAL_ARRAY);
                        
                        glVertexPointer((GLint)3, GL_FLOAT, (GLsizei)sizeof(egwPSParticle), (const GLvoid*)&(((const egwPSParticle*)_particles.rData)[0].position));
                        glPointSize((GLfloat)_pDynamics->pSize.origin);
                        glColorPointer((GLint)4, GL_FLOAT, (GLsizei)sizeof(egwPSParticle), (const GLvoid*)&(((const egwPSParticle*)_particles.rData)[0].color));
                        
                        glDrawArrays(GL_POINTS, (GLint)0, (GLsizei)_particles.eCount);
                        
                        glEnableClientState(GL_NORMAL_ARRAY);
                        glDisableClientState(GL_COLOR_ARRAY);
                    } else {
                        glDisableClientState(GL_NORMAL_ARRAY);
                        
                        for(EGWint pIndex = 0; pIndex < (EGWint)_particles.eCount; ++pIndex) {
                            egwPSParticle* particle = &(((egwPSParticle*)_particles.rData)[pIndex]);
                            
                            glVertexPointer((GLint)3, GL_FLOAT, (GLsizei)0, (const GLvoid*)&particle->position);
                            glPointSize((GLfloat)particle->size);
                            glColor4f(particle->color.channel.r, particle->color.channel.g, particle->color.channel.b, particle->color.channel.a);
                            
                            glDrawArrays(GL_POINTS, (GLint)0, (GLsizei)1);
                        }
                        
                        glEnableClientState(GL_NORMAL_ARRAY);
                    }
                }
            #if defined(GL_POINT_SPRITE) || defined(GL_POINT_SPRITE_OES)
            } else { // Use point sprites
                #if defined(GL_POINT_SPRITE)
                    glEnable(GL_POINT_SPRITE);
                #elif defined(GL_POINT_SPRITE_OES)
                    glEnable(GL_POINT_SPRITE_OES);
                #endif
                glEnableClientState(GL_COLOR_ARRAY);
                #if defined(GL_POINT_SIZE_ARRAY_OES)
                    if(_isPntSzAryAval)
                        glEnableClientState(GL_POINT_SIZE_ARRAY_OES);
                #endif
                glDisableClientState(GL_NORMAL_ARRAY);
                if(_tStack) {
                    egwSFPTxtrStckPushAndBindTextures(_tStack, @selector(pushAndBindTextures));
                    #if defined(GL_POINT_SPRITE)
                        for(EGWint i = [_tStack textureCount] - 1; i >= 0; --i) {
                            egw_glClientActiveTexture(GL_TEXTURE0 + i);
                            glTexEnvf(GL_POINT_SPRITE, GL_COORD_REPLACE, GL_TRUE);
                        }
                    #elif defined(GL_POINT_SPRITE_OES)
                        for(EGWint i = [_tStack textureCount] - 1; i >= 0; --i) {
                            egw_glClientActiveTexture(GL_TEXTURE0 + i);
                            glTexEnvf(GL_POINT_SPRITE_OES, GL_COORD_REPLACE_OES, GL_TRUE);
                        }
                    #endif
                } else egwAFPGfxCntxBindTextures(egwAIGfxCntx, @selector(bindTextures));
                
                glMultMatrixf((const GLfloat*)_mcsTrans);
                
                egw_glBindBuffer(GL_ARRAY_BUFFER, 0);
                
                glVertexPointer((GLint)3, GL_FLOAT, (GLsizei)sizeof(egwPSParticle), (const GLvoid*)&(((const egwPSParticle*)_particles.rData)[0].position));
                #if defined(GL_POINT_SIZE_ARRAY_OES)
                    if(_isPntSzAryAval)
                        glPointSizePointerOES(GL_FLOAT, (GLsizei)sizeof(egwPSParticle), (const GLvoid*)&(((const egwPSParticle*)_particles.rData)[0].size));
                    else
                        glPointSize((GLfloat)_pDynamics->pSize.origin);
                #else
                    glPointSize((GLfloat)_pDynamics->pSize.origin);
                #endif
                glColorPointer((GLint)4, GL_FLOAT, (GLsizei)sizeof(egwPSParticle), (const GLvoid*)&(((const egwPSParticle*)_particles.rData)[0].color));
                
                glDrawArrays(GL_POINTS, (GLint)0, (GLsizei)_particles.eCount);
                
                if(_tStack) {
                    #if defined(GL_POINT_SPRITE)
                        for(EGWint i = [_tStack textureCount] - 1; i >= 0; --i) {
                            egw_glClientActiveTexture(GL_TEXTURE0 + i);
                            glTexEnvf(GL_POINT_SPRITE, GL_COORD_REPLACE, GL_FALSE);
                        }
                    #elif defined(GL_POINT_SPRITE_OES)
                        for(EGWint i = [_tStack textureCount] - 1; i >= 0; --i) {
                            egw_glClientActiveTexture(GL_TEXTURE0 + i);
                            glTexEnvf(GL_POINT_SPRITE_OES, GL_COORD_REPLACE_OES, GL_FALSE);
                        }
                    #endif
                    egwSFPTxtrStckPopTextures(_tStack, @selector(popTextures));
                }
                glEnableClientState(GL_NORMAL_ARRAY);
                #if defined(GL_POINT_SIZE_ARRAY_OES)
                    if(_isPntSzAryAval)
                        glDisableClientState(GL_POINT_SIZE_ARRAY_OES);
                #endif
                glDisableClientState(GL_COLOR_ARRAY);
                #if defined(GL_POINT_SPRITE)
                    glDisable(GL_POINT_SPRITE);
                #elif defined(GL_POINT_SPRITE_OES)
                    glDisable(GL_POINT_SPRITE_OES);
                #endif
            }
            #endif
            
            glPopMatrix();
            if(_sStack) egwSFPShdrStckPopShaders(_sStack, @selector(popShaders));
            if(_lStack) egwSFPLghtStckPopLights(_lStack, @selector(popLights));
        }
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

- (void)update:(EGWtime)deltaT withFlags:(EGWuint)flags {
    if(flags & EGW_ACTOBJ_RPLYFLG_DOUPDATEPASS) {
        if(!_isActuating || _isPaused) return;
        
        if(_ortPending) [self applyOrientation]; // Safety
        
        // deltaT modification
        switch(_aFlags & EGW_ACTOBJ_ACTRFLG_EXTHROTTLE) {
            case EGW_ACTOBJ_ACTRFLG_THROTTLE20:  deltaT *= (EGWtime)0.20; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE25:  deltaT *= (EGWtime)0.25; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE33:  deltaT *= (EGWtime)0.33; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE50:  deltaT *= (EGWtime)0.50; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE66:  deltaT *= (EGWtime)0.66; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE75:  deltaT *= (EGWtime)0.75; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE88:  deltaT *= (EGWtime)0.88; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE125: deltaT *= (EGWtime)1.25; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE150: deltaT *= (EGWtime)1.50; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE200: deltaT *= (EGWtime)2.00; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE250: deltaT *= (EGWtime)2.50; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE300: deltaT *= (EGWtime)3.00; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE400: deltaT *= (EGWtime)4.00; break;
            case EGW_ACTOBJ_ACTRFLG_THROTTLE500: deltaT *= (EGWtime)5.00; break;
            default: break;
        }
        
        BOOL particlesUpdate = NO;
        BOOL minMaxUpdated = NO;
        
        while(!_isFinished && deltaT > EGW_TIME_EPSILON) { // Update method drains deltaT over time
            EGWtime clmpDeltaT = deltaT;
            BOOL releaseParticle = NO;
            
            // !!!: Update system dynamics.
            if(!_isEmitFinished) {
                // Do a clamped delta time update to ensure added accuracy with frequency emmisions that are more rapid than deltaT updates
                clmpDeltaT = egwMin2m(_efLeft, deltaT);
                
                _efLeft -= clmpDeltaT;
                _eFreq += ((EGWtime)_sDynamics->pFrequency.deltaT * clmpDeltaT);
                
                if(!(_psFlags & EGW_PSYSFLAG_EMITCNTDWN)) { // Total particle duration
                    if(_efLeft <= EGW_TIME_EPSILON) {
                        releaseParticle = YES;
                        _eDur.counted.tpCount++;
                    }
                    _eDur.counted.tParts += (EGWsingle)((EGWtime)_sDynamics->eDuration.tParticles.deltaT * clmpDeltaT);
                    _isEmitFinished = (_eDur.counted.tpCount >= (EGWuint32)(_eDur.counted.tParts + 0.5f) ? YES :
                                       (_mParts && _eDur.counted.tpCount >= (EGWuint32)_mParts && egwIsZerom(_eFreq) ? YES : NO)); // Special case cut off when total emitted is at least max allowed and particles are emitting on full blast
                } else { // Timed duration
                    if(_efLeft <= EGW_TIME_EPSILON)
                        releaseParticle = YES;
                    _eDur.timed.dLeft -= clmpDeltaT;
                    _eDur.timed.dLeft += _sDynamics->eDuration.eTimeout.deltaT * clmpDeltaT;
                    _isEmitFinished = (_eDur.timed.dLeft <= EGW_TIME_EPSILON ? YES : NO);
                }
            }
            
            // !!!: Release new particle.
            if(releaseParticle) {
                // If mParts 0 then infinite otherwise if full have to remove an old guy
                if(_mParts && _particles.eCount >= _mParts) {
                    if(!(_psFlags & EGW_PSYSFLAG_EMITOLDRPLC)) {
                        if(!(_psFlags & EGW_PSYSFLAG_EMITNORPLC)) { // Quick shift (assume oldest is more towards tail)
                            while(_particles.eCount >= _mParts)
                                egwArrayRemoveTail(&_particles);
                        } else { // No new emission, disable flag
                            releaseParticle = NO;
                        }
                    } else {
                        if(!(_psFlags & EGW_PSYSFLAG_EMITNORPLC)) { // Find oldest particles and remove
                            while(_particles.eCount >= _mParts) {
                                EGWint oldestIndex = 0;
                                egwPSParticle* parts = (egwPSParticle*)_particles.rData;
                                
                                for(EGWint pIndex = 1; pIndex < (EGWint)_particles.eCount; ++pIndex)
                                    if(parts[pIndex].ltAlive > parts[oldestIndex].ltAlive)
                                        oldestIndex = pIndex;
                                egwArrayRemoveAt(&_particles, (EGWuint)oldestIndex);
                            }
                        } else { // No new emission, disable flag
                            releaseParticle = NO;
                        }
                    }
                }
                
                // Check for release flag again to implement no new emission control
                if(releaseParticle) {
                    egwPSParticle particle; //memset((void*)&particle, 0, sizeof(egwPSParticle));
                    
                    particle.position.axis.x = _pDynamics->pPosition.origin.axis.x + ((((EGWsingle)rand() / (EGWsingle)RAND_MAX) - 0.5f) * _pDynamics->pPosition.variant.axis.x);
                    particle.position.axis.y = _pDynamics->pPosition.origin.axis.y + ((((EGWsingle)rand() / (EGWsingle)RAND_MAX) - 0.5f) * _pDynamics->pPosition.variant.axis.y);
                    particle.position.axis.z = _pDynamics->pPosition.origin.axis.z + ((((EGWsingle)rand() / (EGWsingle)RAND_MAX) - 0.5f) * _pDynamics->pPosition.variant.axis.z);
                    
                    if(!(_psFlags & EGW_PSYSFLAG_VELUSEPYM)) { // Use linear velocity initialize
                        particle.velocity.axis.x = _pDynamics->pVelocity.origin.axis.x + ((((EGWsingle)rand() / (EGWsingle)RAND_MAX) - 0.5f) * _pDynamics->pVelocity.variant.axis.x);
                        particle.velocity.axis.y = _pDynamics->pVelocity.origin.axis.y + ((((EGWsingle)rand() / (EGWsingle)RAND_MAX) - 0.5f) * _pDynamics->pVelocity.variant.axis.y);
                        particle.velocity.axis.z = _pDynamics->pVelocity.origin.axis.z + ((((EGWsingle)rand() / (EGWsingle)RAND_MAX) - 0.5f) * _pDynamics->pVelocity.variant.axis.z);
                    } else { // Use PYM spherical velocity initialize
                        egwVector3f pymVec;
                        
                        pymVec.axis.x = _pDynamics->pVelocity.origin.axis.x + ((((EGWsingle)rand() / (EGWsingle)RAND_MAX) - 0.5f) * _pDynamics->pVelocity.variant.axis.x);
                        pymVec.axis.y = _pDynamics->pVelocity.origin.axis.y + ((((EGWsingle)rand() / (EGWsingle)RAND_MAX) - 0.5f) * _pDynamics->pVelocity.variant.axis.y);
                        pymVec.axis.z = _pDynamics->pVelocity.origin.axis.z + ((((EGWsingle)rand() / (EGWsingle)RAND_MAX) - 0.5f) * _pDynamics->pVelocity.variant.axis.z);
                        
                        if(!egwIsZerof(pymVec.axis.z)) {
                            if(!(flags & EGW_ACTOBJ_RPLYFLG_MACHSCHNELL)) {
                                particle.velocity.axis.x = egwSinf(pymVec.axis.x);
                                particle.velocity.axis.z = particle.velocity.axis.x * -egwSinf(pymVec.axis.y) * pymVec.axis.z;
                                particle.velocity.axis.x *= egwCosf(pymVec.axis.y) * pymVec.axis.z;
                                particle.velocity.axis.y = egwCosf(pymVec.axis.x) * pymVec.axis.z;
                            } else {
                                particle.velocity.axis.x = egwFastSinf(pymVec.axis.x);
                                particle.velocity.axis.z = particle.velocity.axis.x * -egwFastSinf(pymVec.axis.y) * pymVec.axis.z;
                                particle.velocity.axis.x *= egwFastCosf(pymVec.axis.y) * pymVec.axis.z;
                                particle.velocity.axis.y = egwFastCosf(pymVec.axis.x) * pymVec.axis.z;
                            }
                        } else {
                            particle.velocity.axis.x = particle.velocity.axis.y = particle.velocity.axis.z = 0.0f;
                        }
                    }
                    
                    particle.size = _pDynamics->pSize.origin + ((((EGWsingle)rand() / (EGWsingle)RAND_MAX) - 0.5f) * _pDynamics->pSize.variant);
                    particle.weight = _pDynamics->pWeight.origin + ((((EGWsingle)rand() / (EGWsingle)RAND_MAX) - 0.5f) * _pDynamics->pWeight.variant);
                    
                    particle.ltLeft = (EGWtime)_pDynamics->pLife.origin + ((((EGWtime)rand() / (EGWtime)RAND_MAX) - (EGWtime)0.5) * (EGWtime)_pDynamics->pLife.variant);
                    if(!(_psFlags & EGW_PSYSFLAG_OFFTIMEDTEX)) // Use default alive start
                        particle.ltAlive = _drvTexBegAbsT;
                    else // Offset alive time so that pLife origin marks 0.0
                        particle.ltAlive = _drvTexBegAbsT + ((EGWtime)_pDynamics->pLife.origin - particle.ltLeft);
                    
                    particle.color.channel.r = _pDynamics->pColor.origin.axis.x + ((((EGWsingle)rand() / (EGWsingle)RAND_MAX) - 0.5f) * _pDynamics->pColor.variant.axis.x);
                    particle.color.channel.g = _pDynamics->pColor.origin.axis.y + ((((EGWsingle)rand() / (EGWsingle)RAND_MAX) - 0.5f) * _pDynamics->pColor.variant.axis.y);
                    particle.color.channel.b = _pDynamics->pColor.origin.axis.z + ((((EGWsingle)rand() / (EGWsingle)RAND_MAX) - 0.5f) * _pDynamics->pColor.variant.axis.z);
                    if(!(_psFlags & EGW_PSYSFLAG_ALPHAOUTSHFT)) // Normal alpha set
                        particle.color.channel.a = _pDynamics->pColor.origin.axis.w + ((((EGWsingle)rand() / (EGWsingle)RAND_MAX) - 0.5f) * _pDynamics->pColor.variant.axis.w);
                    else // Offset so that ltLeft at 0.0 alpha hits 0.0f as well
                        particle.color.channel.a = -_pDynamics->pColor.deltaT.axis.w * particle.ltLeft;
                    
                    if(!(_psFlags & EGW_PSYSFLAG_EMITTOWCS))
                        particle.twcsTrans = NULL;
                    else {
                        egwVecTransform443f(&_twcsTrans, &particle.position, 1.0f, &particle.position);
                        egwVecTransform443f(&_twcsTrans, &particle.velocity, 0.0f, &particle.velocity);
                        egwVector3f size; size.axis.x = size.axis.y = size.axis.z = particle.size;
                        egwVecTransform443f(&_twcsTrans, &size, 0.0f, &size);
                        particle.size = egwMax2f(egwMax2f(egwAbsf(size.axis.x), egwAbsf(size.axis.y)), egwAbsf(size.axis.z));
                        
                        particle.twcsTrans = (egwMatrix44f*)malloc(sizeof(egwMatrix44f));
                        if(particle.twcsTrans)
                            egwMatCopy44f(&_twcsTrans, particle.twcsTrans);
                    }
                    
                    if(!(egwArrayAddHead(&_particles, (const EGWbyte*)&particle))) {
                        if(particle.twcsTrans) {
                            free((void*)particle.twcsTrans); particle.twcsTrans = NULL;
                        }
                    }
                }
                
                // Reset frequency left counter
                if(!_isEmitFinished) {
                    if(!(_psFlags & EGW_PSYSFLAG_EMITCNTDWN)) { // Emit to total particles
                        if(!(_psFlags & EGW_PSYSFLAG_EMITLEFTVAR))
                            _efLeft = egwMax2m(0.0, _eFreq);
                        else
                            _efLeft = egwMax2m(0.0, _eFreq + ((((EGWtime)rand() / (EGWtime)RAND_MAX) - (EGWtime)0.5) * (EGWtime)_sDynamics->pFrequency.variant));
                    } else { // Emit for a duration
                        if(!(_psFlags & EGW_PSYSFLAG_EMITLEFTVAR))
                            _efLeft = egwMax2m((EGWtime)EGW_PSYS_MINEMITFREQTIMED, _eFreq);
                        else
                            _efLeft = egwMax2m((EGWtime)EGW_PSYS_MINEMITFREQTIMED, _eFreq + ((((EGWtime)rand() / (EGWtime)RAND_MAX) - (EGWtime)0.5) * (EGWtime)_sDynamics->pFrequency.variant));
                    }
                }
            }
            
            // !!!: Update particle dynamics (per particle).
            if(clmpDeltaT > EGW_TIME_EPSILON && _particles.eCount) {
                particlesUpdate = YES;
                
                for(EGWint pIndex = _particles.eCount - 1; pIndex >= 0; --pIndex) {
                    egwPSParticle* particle = &(((egwPSParticle*)_particles.rData)[pIndex]);
                    
                    particle->ltLeft -= clmpDeltaT;
                    particle->ltAlive += clmpDeltaT;
                    
                    if(particle->ltLeft <= EGW_TIME_EPSILON)
                        egwArrayRemoveAt(&_particles, (EGWuint)pIndex);
                    else {
                        EGWtime mvmntClmpDeltaT;
                        
                        // Handle reversed systems by inversing the movement update time value to a negative value
                        if(!(_aFlags & EGW_ACTOBJ_ACTRFLG_REVERSE))
                            mvmntClmpDeltaT = clmpDeltaT;
                        else
                            mvmntClmpDeltaT = -clmpDeltaT;
                        
                        if(!(_psFlags & EGW_PSYSFLAG_EMITTOWCS)) {
                            particle->velocity.axis.x += (EGWsingle)((EGWtime)_velDelta->axis.x * mvmntClmpDeltaT);
                            particle->velocity.axis.y += (EGWsingle)((EGWtime)_velDelta->axis.y * mvmntClmpDeltaT);
                            particle->velocity.axis.z += (EGWsingle)((EGWtime)_velDelta->axis.z * mvmntClmpDeltaT);
                            
                            particle->size += (EGWsingle)((EGWtime)_pDynamics->pSize.deltaT * clmpDeltaT);
                            particle->weight += (EGWsingle)((EGWtime)_pDynamics->pWeight.deltaT * clmpDeltaT);
                            
                            if(_isExtForceApp) {
                                if(!(_psFlags & EGW_PSYSFLAG_EXTFRCISACCL)) { // Treat external force as newtonian force
                                    if(!egwIsZerof(particle->weight)) {
                                        EGWtime invWeight = (EGWtime)1.0 / (EGWtime)particle->weight;
                                        particle->velocity.axis.x += (EGWsingle)((EGWtime)_mmcsExtForce.axis.x * invWeight * clmpDeltaT);
                                        particle->velocity.axis.y += (EGWsingle)((EGWtime)_mmcsExtForce.axis.y * invWeight * clmpDeltaT);
                                        particle->velocity.axis.z += (EGWsingle)((EGWtime)_mmcsExtForce.axis.z * invWeight * clmpDeltaT);
                                    }
                                } else { // Treat external force as direct acceleration
                                    particle->velocity.axis.x += (EGWsingle)((EGWtime)_mmcsExtForce.axis.x * clmpDeltaT);
                                    particle->velocity.axis.y += (EGWsingle)((EGWtime)_mmcsExtForce.axis.y * clmpDeltaT);
                                    particle->velocity.axis.z += (EGWsingle)((EGWtime)_mmcsExtForce.axis.z * clmpDeltaT);
                                }
                            }
                            
                            particle->position.axis.x += (EGWsingle)(((EGWtime)_pDynamics->pPosition.deltaT.axis.x * mvmntClmpDeltaT) +
                                                                     ((EGWtime)particle->velocity.axis.x * mvmntClmpDeltaT));
                            particle->position.axis.y += (EGWsingle)(((EGWtime)_pDynamics->pPosition.deltaT.axis.y * mvmntClmpDeltaT) +
                                                                     ((EGWtime)particle->velocity.axis.y * mvmntClmpDeltaT));
                            particle->position.axis.z += (EGWsingle)(((EGWtime)_pDynamics->pPosition.deltaT.axis.z * mvmntClmpDeltaT) +
                                                                     ((EGWtime)particle->velocity.axis.z * mvmntClmpDeltaT));
                            
                            if(particle->position.axis.y <= _mmcsGrndLevel + EGW_SFLT_EPSILON) {
                                EGWsingle cor = 0.0f;
                                
                                switch(_psFlags & EGW_PSYSFLAG_EXBNCGRND) {
                                    case EGW_PSYSFLAG_BNCGRNDCOR25: {
                                        cor = 0.25f;
                                    } break;
                                    case EGW_PSYSFLAG_BNCGRNDCOR50: {
                                        cor = 0.50f;
                                    } break;
                                    case EGW_PSYSFLAG_BNCGRNDCOR75: {
                                        cor = 0.75f;
                                    } break;
                                    case EGW_PSYSFLAG_BNCGRNDCOR100: {
                                        cor = 1.00f;
                                    } break;
                                }
                                
                                // Technically this is really cheating appropriate back-up-and-reapply-velocity-at-new-rate, but good enough for now
                                particle->velocity.axis.x *= cor;
                                particle->velocity.axis.z *= cor;
                                particle->velocity.axis.y = cor * egwAbsf(particle->velocity.axis.y);
                                particle->position.axis.y = _mmcsGrndLevel + (cor * egwAbsf(_mmcsGrndLevel - particle->position.axis.y));
                            }
                        } else {
                            egwVector3f temp;
                            
                            egwVecTransform443f(particle->twcsTrans, _velDelta, 0.0f, &temp);
                            particle->velocity.axis.x += (EGWsingle)((EGWtime)temp.axis.x * mvmntClmpDeltaT);
                            particle->velocity.axis.y += (EGWsingle)((EGWtime)temp.axis.y * mvmntClmpDeltaT);
                            particle->velocity.axis.z += (EGWsingle)((EGWtime)temp.axis.z * mvmntClmpDeltaT);
                            
                            temp.axis.x = temp.axis.y = temp.axis.z = _pDynamics->pSize.deltaT;
                            egwVecTransform443f(particle->twcsTrans, &temp, 0.0f, &temp);
                            temp.axis.x = egwMax2f(egwMax2f(egwAbsf(temp.axis.x), egwAbsf(temp.axis.y)), egwAbsf(temp.axis.z));
                            particle->size += (EGWsingle)((EGWtime)temp.axis.x * clmpDeltaT);
                            particle->weight += (EGWsingle)((EGWtime)_pDynamics->pWeight.deltaT * clmpDeltaT);
                            
                            if(_isExtForceApp) {
                                if(!(_psFlags & EGW_PSYSFLAG_EXTFRCISACCL)) { // Treat external force as newtonian force
                                    if(!egwIsZerof(particle->weight)) {
                                        EGWtime invWeight = (EGWtime)1.0 / (EGWtime)particle->weight;
                                        particle->velocity.axis.x += (EGWsingle)((EGWtime)_wcsExtForce.axis.x * invWeight * clmpDeltaT);
                                        particle->velocity.axis.y += (EGWsingle)((EGWtime)_wcsExtForce.axis.y * invWeight * clmpDeltaT);
                                        particle->velocity.axis.z += (EGWsingle)((EGWtime)_wcsExtForce.axis.z * invWeight * clmpDeltaT);
                                    }
                                } else { // Treat external force as direct acceleration
                                    particle->velocity.axis.x += (EGWsingle)((EGWtime)_wcsExtForce.axis.x * clmpDeltaT);
                                    particle->velocity.axis.y += (EGWsingle)((EGWtime)_wcsExtForce.axis.y * clmpDeltaT);
                                    particle->velocity.axis.z += (EGWsingle)((EGWtime)_wcsExtForce.axis.z * clmpDeltaT);
                                }
                            }
                            
                            egwVecTransform443f(particle->twcsTrans, &_pDynamics->pPosition.deltaT, 0.0f, &temp); // DeltaTs are always directional based
                            particle->position.axis.x += (EGWsingle)(((EGWtime)temp.axis.x * mvmntClmpDeltaT) +
                                                                     ((EGWtime)particle->velocity.axis.x * mvmntClmpDeltaT));
                            particle->position.axis.y += (EGWsingle)(((EGWtime)temp.axis.y * mvmntClmpDeltaT) +
                                                                     ((EGWtime)particle->velocity.axis.y * mvmntClmpDeltaT));
                            particle->position.axis.z += (EGWsingle)(((EGWtime)temp.axis.z * mvmntClmpDeltaT) +
                                                                     ((EGWtime)particle->velocity.axis.z * mvmntClmpDeltaT));
                            
                            if(particle->position.axis.y <= _wcsGrndLevel + EGW_SFLT_EPSILON) {
                                EGWsingle cor = 0.0f;
                                
                                switch(_psFlags & EGW_PSYSFLAG_EXBNCGRND) {
                                    case EGW_PSYSFLAG_BNCGRNDCOR25: {
                                        cor = 0.25f;
                                    } break;
                                    case EGW_PSYSFLAG_BNCGRNDCOR50: {
                                        cor = 0.50f;
                                    } break;
                                    case EGW_PSYSFLAG_BNCGRNDCOR75: {
                                        cor = 0.75f;
                                    } break;
                                    case EGW_PSYSFLAG_BNCGRNDCOR100: {
                                        cor = 1.00f;
                                    } break;
                                }
                                
                                // Technically this is really cheating appropriate back-up-and-reapply-velocity-at-new-rate, but good enough for now
                                particle->velocity.axis.x *= cor;
                                particle->velocity.axis.z *= cor;
                                particle->velocity.axis.y = cor * egwAbsf(particle->velocity.axis.y);
                                particle->position.axis.y = _wcsGrndLevel + (cor * egwAbsf(_wcsGrndLevel - particle->position.axis.y));
                            }
                            
                        }
                        
                        if(egwIsEqualf(clmpDeltaT, deltaT)) { // Only do these items on last update
                            if(_psFlags & EGW_PSYSFLAG_CYCLICPOS) { // Cyclic positioning
                                while(particle->position.axis.x < _mmStPos[0].axis.x - EGW_SFLT_EPSILON)
                                    particle->position.axis.x += _pDynamics->pPosition.variant.axis.x;
                                while(particle->position.axis.x > _mmStPos[1].axis.x + EGW_SFLT_EPSILON)
                                    particle->position.axis.x -= _pDynamics->pPosition.variant.axis.x;
                                while(particle->position.axis.y < _mmStPos[0].axis.y - EGW_SFLT_EPSILON)
                                    particle->position.axis.y += _pDynamics->pPosition.variant.axis.y;
                                while(particle->position.axis.y > _mmStPos[1].axis.y + EGW_SFLT_EPSILON)
                                    particle->position.axis.y -= _pDynamics->pPosition.variant.axis.y;
                                while(particle->position.axis.z < _mmStPos[0].axis.z - EGW_SFLT_EPSILON)
                                    particle->position.axis.z += _pDynamics->pPosition.variant.axis.z;
                                while(particle->position.axis.z > _mmStPos[1].axis.z + EGW_SFLT_EPSILON)
                                    particle->position.axis.z -= _pDynamics->pPosition.variant.axis.z;
                            }
                            
                            if(_rFlags & EGW_OBJEXTEND_FLG_LAZYBOUNDING) {
                                if(particle->position.axis.x < _mmUpPos[0].axis.x) {
                                    _mmUpPos[0].axis.x = particle->position.axis.x;
                                    minMaxUpdated = YES;
                                }
                                if(particle->position.axis.x > _mmUpPos[1].axis.x) {
                                    _mmUpPos[1].axis.x = particle->position.axis.x;
                                    minMaxUpdated = YES;
                                }
                                if(particle->position.axis.y < _mmUpPos[0].axis.y) {
                                    _mmUpPos[0].axis.y = particle->position.axis.y;
                                    minMaxUpdated = YES;
                                }
                                if(particle->position.axis.y > _mmUpPos[1].axis.y) {
                                    _mmUpPos[1].axis.y = particle->position.axis.y;
                                    minMaxUpdated = YES;
                                }
                                if(particle->position.axis.z < _mmUpPos[0].axis.z) {
                                    _mmUpPos[0].axis.z = particle->position.axis.z;
                                    minMaxUpdated = YES;
                                }
                                if(particle->position.axis.z > _mmUpPos[1].axis.z) {
                                    _mmUpPos[1].axis.z = particle->position.axis.z;
                                    minMaxUpdated = YES;
                                }
                            }
                        }
                        
                        particle->color.channel.r += (EGWsingle)((EGWtime)_pDynamics->pColor.deltaT.axis.x * clmpDeltaT);
                        particle->color.channel.g += (EGWsingle)((EGWtime)_pDynamics->pColor.deltaT.axis.y * clmpDeltaT);
                        particle->color.channel.b += (EGWsingle)((EGWtime)_pDynamics->pColor.deltaT.axis.z * clmpDeltaT);
                        particle->color.channel.a += (EGWsingle)((EGWtime)_pDynamics->pColor.deltaT.axis.w * clmpDeltaT);
                    }
                }
            }
            
            // Update deltaT to reflect this run of update
            deltaT -= clmpDeltaT;
            
            // !!!: End condition checking.
            if(!_isFinished && _isEmitFinished) {
                if(!(_aFlags & EGW_ACTOBJ_ACTRFLG_LOOPING)) { // Check for finish condition
                    if(_particles.eCount == 0) {
                        _isFinished = YES;
                        
                        [self stopRendering];
                    }
                } else if(!(_psFlags & EGW_PSYSFLAG_LOOPAFTRNP) || _particles.eCount == 0) { // Check for loop around condition
                    if(!(_psFlags & EGW_PSYSFLAG_EMITCNTDWN)) { // Emit to total particles
                        _eDur.counted.tParts = egwMax2f(0.0f, _sDynamics->eDuration.tParticles.origin + ((((EGWsingle)rand() / (EGWsingle)RAND_MAX) - 0.5f) * (EGWsingle)_sDynamics->eDuration.tParticles.variant));
                        _eDur.counted.tpCount = 0;
                        if(!(_psFlags & EGW_PSYSFLAG_EMITLEFTVAR)) {
                            _eFreq = egwMax2m(0.0, (EGWtime)_sDynamics->pFrequency.origin + ((((EGWtime)rand() / (EGWtime)RAND_MAX) - (EGWtime)0.5) * (EGWtime)_sDynamics->pFrequency.variant));
                            _efLeft = egwMax2m(0.0, _eFreq);
                        } else {
                            _eFreq = egwMax2m(0.0, (EGWtime)_sDynamics->pFrequency.origin);
                            _efLeft = egwMax2m(0.0, _eFreq + ((((EGWtime)rand() / (EGWtime)RAND_MAX) - (EGWtime)0.5) * (EGWtime)_sDynamics->pFrequency.variant));
                        }
                        _isEmitFinished = (_eDur.counted.tpCount >= (EGWuint32)(_eDur.counted.tParts + 0.5f) ? YES : NO);
                    } else { // Emit for a duration
                        _eDur.timed.dLeft = egwMax2m((EGWtime)0.0, (EGWtime)_sDynamics->eDuration.eTimeout.origin + ((((EGWtime)rand() / (EGWtime)RAND_MAX) - (EGWtime)0.5) * (EGWtime)_sDynamics->eDuration.eTimeout.variant));
                        if(!(_psFlags & EGW_PSYSFLAG_EMITLEFTVAR)) {
                            _eFreq = egwMax2m((EGWtime)EGW_PSYS_MINEMITFREQTIMED, (EGWtime)_sDynamics->pFrequency.origin + ((((EGWtime)rand() / (EGWtime)RAND_MAX) - (EGWtime)0.5) * (EGWtime)_sDynamics->pFrequency.variant));
                            _efLeft = egwMax2m((EGWtime)EGW_PSYS_MINEMITFREQTIMED, _eFreq);
                        } else {
                            _eFreq = egwMax2m((EGWtime)EGW_PSYS_MINEMITFREQTIMED, (EGWtime)_sDynamics->pFrequency.origin);
                            _efLeft = egwMax2m((EGWtime)EGW_PSYS_MINEMITFREQTIMED, _eFreq + ((((EGWtime)rand() / (EGWtime)RAND_MAX) - (EGWtime)0.5) * (EGWtime)_sDynamics->pFrequency.variant));
                        }
                        _isEmitFinished = (_eDur.timed.dLeft <= EGW_TIME_EPSILON ? YES : NO);
                    }
                }
            }
        }
        
        if(particlesUpdate) {
            if(!(_psFlags & EGW_PSYSFLAG_EMITTOWCS)) {
                if(!(_rFlags & EGW_OBJEXTEND_FLG_LAZYBOUNDING)) {
                    if(_particles.eCount)
                        [_mmcsRBVol initWithOpticalSource:NULL vertexCount:_particles.eCount vertexCoords:(const egwVector3f*)&(((const egwPSParticle*)_particles.rData)[0].position) vertexCoordsStride:(EGWintptr)sizeof(egwPSParticle)];
                    else
                        [_mmcsRBVol reset];
                    
                    _ortPending = YES;
                    [self applyOrientation];
                } else if(minMaxUpdated) {
                    if(_particles.eCount)
                        [_mmcsRBVol initWithOpticalSource:NULL vertexCount:2 vertexCoords:(const egwVector3f*)&_mmUpPos[0] vertexCoordsStride:0];
                    else
                        [_mmcsRBVol reset];
                    
                    _ortPending = YES;
                }
                
                egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
            } else {
                if(!(_rFlags & EGW_OBJEXTEND_FLG_LAZYBOUNDING)) {
                    if(_particles.eCount)
                        [_wcsRBVol initWithOpticalSource:NULL vertexCount:_particles.eCount vertexCoords:(const egwVector3f*)&(((const egwPSParticle*)_particles.rData)[0].position) vertexCoordsStride:(EGWintptr)sizeof(egwPSParticle)];
                    else
                        [_wcsRBVol reset];
                } else if(minMaxUpdated) {
                    if(_particles.eCount)
                        [_wcsRBVol initWithOpticalSource:NULL vertexCount:2 vertexCoords:(const egwVector3f*)&_mmUpPos[0] vertexCoordsStride:0];
                    else
                        [_wcsRBVol reset];
                }
                
                egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
            }
        }
        
        if(_isFinished && _delegate)
            [_delegate actuator:self did:EGW_ACTION_FINISH];
    } else if(flags & EGW_ACTOBJ_RPLYFLG_DOUPDATESTART) {
        if(!(_psFlags & EGW_PSYSFLAG_EMITCNTDWN)) { // Emit to total particles
            _eDur.counted.tParts = egwMax2f(0.0f, _sDynamics->eDuration.tParticles.origin + ((((EGWsingle)rand() / (EGWsingle)RAND_MAX) - 0.5f) * (EGWsingle)_sDynamics->eDuration.tParticles.variant));
            _eDur.counted.tpCount = 0;
            if(!(_psFlags & EGW_PSYSFLAG_EMITLEFTVAR)) {
                _eFreq = egwMax2m(0.0, (EGWtime)_sDynamics->pFrequency.origin + ((((EGWtime)rand() / (EGWtime)RAND_MAX) - (EGWtime)0.5) * (EGWtime)_sDynamics->pFrequency.variant));
                _efLeft = egwMax2m(0.0, _eFreq);
            } else {
                _eFreq = egwMax2m(0.0, (EGWtime)_sDynamics->pFrequency.origin);
                _efLeft = egwMax2m(0.0, _eFreq + ((((EGWtime)rand() / (EGWtime)RAND_MAX) - (EGWtime)0.5) * (EGWtime)_sDynamics->pFrequency.variant));
            }
            _isEmitFinished = (_eDur.counted.tpCount >= (EGWuint32)(_eDur.counted.tParts + 0.5f) ? YES : NO);
        } else { // Emit for a duration
            _eDur.timed.dLeft = egwMax2m((EGWtime)0.0, (EGWtime)_sDynamics->eDuration.eTimeout.origin + ((((EGWtime)rand() / (EGWtime)RAND_MAX) - (EGWtime)0.5) * (EGWtime)_sDynamics->eDuration.eTimeout.variant));
            if(!(_psFlags & EGW_PSYSFLAG_EMITLEFTVAR)) {
                _eFreq = egwMax2m((EGWtime)EGW_PSYS_MINEMITFREQTIMED, (EGWtime)_sDynamics->pFrequency.origin + ((((EGWtime)rand() / (EGWtime)RAND_MAX) - (EGWtime)0.5) * (EGWtime)_sDynamics->pFrequency.variant));
                _efLeft = egwMax2m((EGWtime)EGW_PSYS_MINEMITFREQTIMED, _eFreq);
            } else {
                _eFreq = egwMax2m((EGWtime)EGW_PSYS_MINEMITFREQTIMED, (EGWtime)_sDynamics->pFrequency.origin);
                _efLeft = egwMax2m((EGWtime)EGW_PSYS_MINEMITFREQTIMED, _eFreq + ((((EGWtime)rand() / (EGWtime)RAND_MAX) - (EGWtime)0.5) * (EGWtime)_sDynamics->pFrequency.variant));
            }
            _isEmitFinished = (_eDur.timed.dLeft <= EGW_TIME_EPSILON ? YES : NO);
        }
        
        if(!_isActuating) {
            _isFinished = NO;
            _isPaused = NO;
            _isActuating = YES;
            
            egwArrayRemoveAll(&_particles);
            
            _mmUpPos[0].axis.x = _mmUpPos[0].axis.y = _mmUpPos[0].axis.z = EGW_SFLT_MAX;
            _mmUpPos[1].axis.x = _mmUpPos[1].axis.y = _mmUpPos[1].axis.z = -EGW_SFLT_MAX;
            
            [self startRendering];
            
            if(_delegate)
                [_delegate actuator:self did:EGW_ACTION_START];
        } else { // If already actuating, then restart
            _isFinished = NO;
            _isPaused = NO;
            _isActuating = YES;
            
            if(_delegate)
                [_delegate actuator:self did:EGW_ACTION_RESTART];
        }
    } else if(flags & EGW_ACTOBJ_RPLYFLG_DOUPDATEPAUSE) {
        if(_isActuating) {
            if(!_isPaused) {
                _isPaused = YES;
            } else {
                _isPaused = NO;
            }
            
            if(_delegate)
                [_delegate actuator:self did:(_isPaused ? EGW_ACTION_PAUSE : EGW_ACTION_UNPAUSE)];
        }
    } else if(flags & EGW_ACTOBJ_RPLYFLG_DOUPDATESTOP) {
        if(_isActuating) {
            _isActuating = NO;
            _isPaused = NO;
            
            [self stopRendering];
            
            if(_delegate)
                [_delegate actuator:self did:EGW_ACTION_STOP];
        }
    }
}

- (EGWuint16)actuatorFlags {
    return _aFlags;
}

- (const egwActuatorJumpTable*)actuatorJumpTable {
    return &_egwAJT;
}

- (id<egwPAssetBase>)assetBase {
    return _base;
}

- (EGWuint)coreObjectTypes {
    return (EGW_COREOBJ_TYPE_ACTUATOR | EGW_COREOBJ_TYPE_GRAPHIC | EGW_COREOBJ_TYPE_ORIENTABLE);
}

- (const egwVector4f*)externalForce {
    return &_wcsExtForce;
}

- (egwValidater*)geometryBufferSync {
    return nil;
}

- (EGWuint)geometryStorage {
    return _geoStrg;
}

- (EGWsingle)groundLevel {
    return _wcsGrndLevel;
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
    return nil;
}

- (egwShaderStack*)shaderStack {
    return _sStack;
}

- (egwTextureStack*)textureStack {
    return _tStack;
}

- (EGWuint16)maximumParticles {
    return _mParts;
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

- (EGWuint16)systemFlags {
    return _psFlags;
}

- (void)setActuatorFlags:(EGWuint16)flags {
    _aFlags = flags;
}

- (void)setDelegate:(id<egwDGeometryEvent,egwDActuatorEvent>)delegate {
    [delegate retain];
    [_delegate release];
    _delegate = delegate;
}

- (void)setExternalForce:(const egwVector3f*)force {
    egwVecCopy3f(force, (egwVector3f*)&_wcsExtForce);
    
    if(!(_psFlags & EGW_PSYSFLAG_EMITTOWCS)) {
        if(!_ortPending) { // If ort pending, then just wait to do this in applyOrientation
            egwVecTransform444f(&_twcsInverse, &_wcsExtForce, &_mmcsExtForce);
            _isExtForceApp = (!egwVecIsEqual3f((egwVector3f*)&_mmcsExtForce, &egwSIVecZero3f) ? YES : NO);
        }
    } else {
        _isExtForceApp = (!egwVecIsEqual3f((egwVector3f*)&_wcsExtForce, &egwSIVecZero3f) ? YES : NO);
    }
}

- (void)setGroundLevel:(EGWsingle)height {
    _wcsGrndLevel = height;
    
    if(!(_psFlags & EGW_PSYSFLAG_EMITTOWCS)) {
        if(_wcsGrndLevel != -EGW_SFLT_MAX) {
            if(!_ortPending) { // If ort pending, then just wait to do this in applyOrientation
                _mmcsGrndLevel = _twcsInverse.component.r2c3 * _wcsGrndLevel + _twcsInverse.component.r2c4;
            }
        } else
            _mmcsGrndLevel = -EGW_SFLT_MAX;
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
    // Do nothing
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
    
    id<egwPTexture,egwPTimed> drvTex = [[_tStack firstTimedTexture] retain];
    [_drvTex release];
    _drvTex = drvTex;
    _dtJmpTbl = [_drvTex textureJumpTable];
    _drvTexBegAbsT = (_drvTex ? [_drvTex evaluationBoundsBegin] : (EGWtime)0.0);
    _drvTexEndAbsT = (_drvTex ? [_drvTex evaluationBoundsEnd] : (EGWtime)0.0);
    
    _isBBQuadRndrd = ((!(_isPntSprtAvail && (_isPntSzAryAval || _isPntSzStatic)) || (_psFlags & EGW_PSYSFLAG_NOPOINTSPRT) || _drvTex) ? YES : NO);
    
    egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (void)setMaximumParticles:(EGWuint16)maxPart {
    EGWuint16 oldMParts = _mParts;
    _mParts = maxPart;
    
    if(_mParts && _mParts < oldMParts && _particles.eCount > _mParts) { // If mParts 0 then infinite
        if(!(_psFlags & EGW_PSYSFLAG_EMITOLDRPLC)) // Quick shift (assume oldest is more towards tail)
            while(_particles.eCount > _mParts)
                egwArrayRemoveTail(&_particles);
        else { // Find oldest particles and remove
            while(_particles.eCount > _mParts) {
                EGWint oldestIndex = 0;
                egwPSParticle* parts = (egwPSParticle*)_particles.rData;
                
                for(EGWint pIndex = 1; pIndex < (EGWint)_particles.eCount; ++pIndex)
                    if(parts[pIndex].ltAlive > parts[oldestIndex].ltAlive)
                        oldestIndex = pIndex;
                egwArrayRemoveAt(&_particles, (EGWuint)oldestIndex);
            }
        }
    }
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
            NSLog(@"egwParticleSystem: setParent: Warning: Object system is overriding WCS interpolator driver for instance asset '%@' (%p).", _ident, self);
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

- (void)setSystemFlags:(EGWuint16)sysFlags {
    _psFlags = sysFlags;
    
    _isBBQuadRndrd = ((!(_isPntSprtAvail && (_isPntSzAryAval || _isPntSzStatic)) || (_psFlags & EGW_PSYSFLAG_NOPOINTSPRT) || _drvTex) ? YES : NO);
    _velDelta = (!(_psFlags & EGW_PSYSFLAG_VELUSEPYM) ? (const egwVector3f*)&_pDynamics->pVelocity.deltaT : (const egwVector3f*)[_base sphericalVelocityDelta]);
}

- (BOOL)trySetGeometryDataPersistence:(BOOL)persist {
    return persist; // Geometry data does not have to be persistent since it is always -1/+1 quaded
}

- (BOOL)trySetGeometryStorage:(EGWuint)storage {
    return NO; // Geometry storage is too complex to allow changing
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

- (BOOL)isActuating {
    return _isActuating;
}

- (BOOL)isChildOf:(id<egwPObjectBranch>)parent {
    return (_parent == parent ? YES : NO);
}

- (BOOL)isFinished {
    return _isFinished;
}

- (BOOL)isInvokingParent {
    return _invkParent;
}

- (BOOL)isGeometryDataPersistent {
    return NO; // Geometry data does not have to be persistent since it is always -1/+1 quaded
}

- (BOOL)isLeaf {
    return YES;
}

- (BOOL)isOpaque {
    return !(_rFlags & EGW_GFXOBJ_RNDRFLG_ISTRANSPARENT) && ((_rFlags & EGW_GFXOBJ_RNDRFLG_ISOPAQUE) || ((!_tStack || egwSFPTxtrStckOpaque(_tStack, @selector(isOpaque))) && [egwAIGfxCntx determineOpacity:[_base minAlphaAttainable]]));
}

- (BOOL)isOrientationPending {
    return _ortPending;
}

- (BOOL)isPaused {
    return _isPaused;
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


// !!!: ***** egwParticleSystemBase *****

@implementation egwParticleSystemBase

+ (id)allocWithZone:(NSZone*)zone {
    id alloc = [super allocWithZone:zone];
    if(alloc) [egwAssetManager incBaseRef];
    if(EGW_ENGINE_ASSETS_CREATIONMSGS) NSLog(@"egwParticleSystemBase: allocWithZone: Creating new particle system base asset (%p).", alloc);
    return alloc;
}

- (id)init {
    if([self isMemberOfClass:[egwParticleSystemBase class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent particleDynamics:(egwPSParticleDynamics*)partDyn systemDynamics:(egwPSSystemDynamics*)sysDyn {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    memset((void*)&_pDynamics, 0, sizeof(egwPSParticleDynamics));
    
    if(partDyn) {
        memcpy((void*)&_pDynamics, (const void*)partDyn, sizeof(egwPSParticleDynamics));
        memset((void*)partDyn, 0, sizeof(egwPSParticleDynamics));
        
        // These are values that must be kept positive due to math elsewhere
        _pDynamics.pPosition.variant.axis.x = egwAbsf(_pDynamics.pPosition.variant.axis.x);
        _pDynamics.pPosition.variant.axis.y = egwAbsf(_pDynamics.pPosition.variant.axis.y);
        _pDynamics.pPosition.variant.axis.z = egwAbsf(_pDynamics.pPosition.variant.axis.z);
        _pDynamics.pLife.variant = egwAbsf(_pDynamics.pLife.variant);
        _pDynamics.pColor.variant.axis.w = egwAbsf(_pDynamics.pColor.variant.axis.w);
    } else { [self release]; return (self = nil); }
    
    if(sysDyn) {
        memcpy((void*)&_sDynamics, (const void*)sysDyn, sizeof(egwPSSystemDynamics));
        memset((void*)sysDyn, 0, sizeof(egwPSSystemDynamics));
    } else { [self release]; return (self = nil); }
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_mcsTrans);
    
    _mAlpha = egwClamp01f(_pDynamics.pColor.origin.axis.w - (_pDynamics.pColor.variant.axis.w * 0.5f) + (_pDynamics.pColor.deltaT.axis.w < EGW_SFLT_EPSILON ? _pDynamics.pColor.deltaT.axis.w * (_pDynamics.pLife.origin + (_pDynamics.pLife.variant * 0.5f)) : 0.0f));
    _mmStPos[0].axis.x = _pDynamics.pPosition.origin.axis.x - (_pDynamics.pPosition.variant.axis.x * 0.5f);
    _mmStPos[0].axis.y = _pDynamics.pPosition.origin.axis.y - (_pDynamics.pPosition.variant.axis.y * 0.5f);
    _mmStPos[0].axis.z = _pDynamics.pPosition.origin.axis.z - (_pDynamics.pPosition.variant.axis.z * 0.5f);
    _mmStPos[1].axis.x = _pDynamics.pPosition.origin.axis.x + (_pDynamics.pPosition.variant.axis.x * 0.5f);
    _mmStPos[1].axis.y = _pDynamics.pPosition.origin.axis.y + (_pDynamics.pPosition.variant.axis.y * 0.5f);
    _mmStPos[1].axis.z = _pDynamics.pPosition.origin.axis.z + (_pDynamics.pPosition.variant.axis.z * 0.5f);
    _sphVelDelta.axis.x = egwSinf(_pDynamics.pVelocity.deltaT.axis.x);
    _sphVelDelta.axis.z = _sphVelDelta.axis.x * -egwSinf(_pDynamics.pVelocity.deltaT.axis.y) * _pDynamics.pVelocity.deltaT.axis.z;
    _sphVelDelta.axis.x *= egwCosf(_pDynamics.pVelocity.deltaT.axis.y) * _pDynamics.pVelocity.deltaT.axis.z;
    _sphVelDelta.axis.y = egwCosf(_pDynamics.pVelocity.deltaT.axis.x) * _pDynamics.pVelocity.deltaT.axis.z;
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    return nil;
}

- (id)mutableCopyWithZone:(NSZone*)zone {
    return nil;
}

- (void)dealloc {
    if(EGW_ENGINE_ASSETS_DESTROYMSGS) NSLog(@"egwParticleSystemBase: dealloc: Destroying particle system base asset '%@' (%p).", _ident, self);
    [_ident release]; _ident = nil;
    [egwAssetManager decBaseRef];
    [super dealloc];
}

- (void)baseOffsetByTransform:(const egwMatrix44f*)transform {
    egwMatMultiply44f(&_mcsTrans, transform, &_mcsTrans);
}

- (void)baseOffsetByZeroAlign:(EGWuint)zfAlign {
    egwVector3f offset, min, max;
    egwMatrix44f transform;
    
    min.axis.x = _mmStPos[0].axis.x;
    min.axis.y = _mmStPos[0].axis.y;
    min.axis.z = _mmStPos[0].axis.z;
    
    max.axis.x = _mmStPos[1].axis.x;
    max.axis.y = _mmStPos[1].axis.y;
    max.axis.z = _mmStPos[1].axis.z;
    
    // Transform all edges in order to find extent after the transform
    egwVector3f edges[8];
    edges[0].axis.x = min.axis.x; edges[0].axis.y = min.axis.y; edges[0].axis.z = min.axis.z; // mmm
    edges[1].axis.x = min.axis.x; edges[1].axis.y = min.axis.y; edges[1].axis.z = max.axis.z; // mmM
    edges[2].axis.x = min.axis.x; edges[2].axis.y = max.axis.y; edges[2].axis.z = min.axis.z; // mMm
    edges[3].axis.x = min.axis.x; edges[3].axis.y = max.axis.y; edges[3].axis.z = max.axis.z; // mMM
    edges[4].axis.x = max.axis.x; edges[4].axis.y = min.axis.y; edges[4].axis.z = min.axis.z; // Mmm
    edges[5].axis.x = max.axis.x; edges[5].axis.y = min.axis.y; edges[5].axis.z = max.axis.z; // MmM
    edges[6].axis.x = max.axis.x; edges[6].axis.y = max.axis.y; edges[6].axis.z = min.axis.z; // MMm
    edges[7].axis.x = max.axis.x; edges[7].axis.y = max.axis.y; edges[7].axis.z = max.axis.z; // MMM
    
    egwVecTransform443fv(&_mcsTrans, &edges[0], &egwSIOnef, &edges[0], -sizeof(egwMatrix44f), 0, -sizeof(float), 0, 8);
    
    egwVecFindExtentsAxs3fv(&edges[0], &min, &max, 0, 8);
    
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

- (NSString*)identity {
    return _ident;
}

- (const egwMatrix44f*)mcsTransform {
    return &_mcsTrans;
}

- (const EGWsingle)minAlphaAttainable {
    return _mAlpha;
}

- (const egwVector3f*)minMaxStartPosition {
    return &_mmStPos[0];
}

- (EGWuint)nextInstanceIndex {
    return ++_instCounter;
}

- (const egwPSParticleDynamics*)particleDynamics {
    return &_pDynamics;
}

- (const egwPSSystemDynamics*)systemDynamics {
    return &_sDynamics;
}

- (const egwVector3f*)sphericalVelocityDelta {
    return &_sphVelDelta;
}

@end
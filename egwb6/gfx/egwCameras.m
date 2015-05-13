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

/// @file egwCameras.m
/// @ingroup geWizES_gfx_cameras
/// Camera Assets Implementations.

#import "egwCameras.h"
#import "../sys/egwSysTypes.h"
#import "../sys/egwAssetManager.h"
#import "../sys/egwGfxContext.h"
#import "../sys/egwGfxContextNSGL.h"  // NOTE: Below code has a dependence on GL.
#import "../sys/egwGfxContextEAGLES.h"
#import "../sys/egwSndContext.h"
#import "../sys/egwSndContextAL.h"  // NOTE: Below code has a dependence on AL.
#import "../math/egwMath.h"
#import "../math/egwVector.h"
#import "../math/egwMatrix.h"
#import "../gfx/egwBoundings.h"
#import "../obj/egwObjectBranch.h"
#import "../phy/egwInterpolators.h"
#import "../misc/egwValidater.h"


// !!!: ***** egwPerspectiveCamera *****

@implementation egwPerspectiveCamera

- (id)init {
    if([self isMemberOfClass:[egwPerspectiveCamera class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent graspAngle:(EGWsingle)angle fieldOfView:(EGWsingle)fov aspectRatio:(EGWsingle)aspect frontPlane:(EGWsingle)near backPlane:(EGWsingle)far {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwCameraBase alloc] initPerspectiveWithIdentity:assetIdent graspAngle:angle fieldOfView:fov aspectRatio:aspect frontPlane:near backPlane:far])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_ccsTrans);
    egwVecCopy4f(&egwSIVecZero4f, &_wcsVelocity);
    if(!(_wcsFVBVol = [(NSObject*)[_base cameraBounding] copy])) { [self release]; return (self = nil); }
    if(!(_wcsCVBVol = [(NSObject*)[_base viewingBounding] copy])) { [self release]; return (self = nil); }
    
    _vFlags = EGW_CAMOBJ_VIEWFLG_DFLT;
    _vFrame = 1;
    if(!(_pSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_AUDIO])) { [self release]; return (self = nil); }
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_GRAPHIC])) { [self release]; return (self = nil); }
    if(!(_vSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_CAMERA])) { [self release]; return (self = nil); }
    
    return self;
}

- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent {
    if(!([asset isKindOfClass:[self class]]) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = (egwCameraBase*)[[asset assetBase] retain])) { [self release]; return (self = nil); }
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    egwMatCopy44f([(egwPerspectiveCamera*)asset wcsTransform], &_wcsTrans);
    egwMatCopy44f([(egwPerspectiveCamera*)asset lcsTransform], &_lcsTrans);
    egwMatCopy44f([(egwPerspectiveCamera*)asset ccsTransform], &_ccsTrans);
    egwVecCopy3f((egwVector3f*)[(egwPerspectiveCamera*)asset linearVelocity], (egwVector3f*)&_wcsVelocity); _wcsVelocity.axis.w = 0.0f;
    if(!(_wcsFVBVol = [(NSObject*)[(egwPerspectiveCamera*)asset cameraBounding] copy])) { [self release]; return (self = nil); }
    if(!(_wcsCVBVol = [(NSObject*)[(egwPerspectiveCamera*)asset viewingBounding] copy])) { [self release]; return (self = nil); }
    if([(id<egwPOrientated>)asset offsetDriver] && ![self trySetOffsetDriver:[(id<egwPOrientated>)asset offsetDriver]]) { [self release]; return (self = nil); }
    if([(id<egwPOrientated>)asset orientateDriver] && ![self trySetOrientateDriver:[(id<egwPOrientated>)asset orientateDriver]]) { [self release]; return (self = nil); }
    
    _vFlags = [(egwPerspectiveCamera*)asset viewingFlags];
    _vFrame = 1;
    if(!(_pSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_AUDIO])) { [self release]; return (self = nil); }
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_GRAPHIC])) { [self release]; return (self = nil); }
    if(!(_vSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_CAMERA])) { [self release]; return (self = nil); }
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwPerspectiveCamera* copy = nil;
    NSString* copyIdent = nil;
    
    if([_ident hasSuffix:@"_default"])
        copyIdent = [[NSString alloc] initWithFormat:@"%@_%d", [_base identity], [_base nextInstanceIndex]];
    else copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwPerspectiveCamera allocWithZone:zone] initCopyOf:self
                                                         withIdentity:copyIdent])) {
        NSLog(@"egwPerspectiveCamera: copyWithZone: Failure initializing new camera from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    return copy;
}

- (void)dealloc {
    [_wcsFVBVol release]; _wcsFVBVol = nil;
    [_wcsCVBVol release]; _wcsCVBVol = nil;
    
    if(_lcsIpo) { [_lcsIpo removeTargetWithObject:self]; [_lcsIpo release]; _lcsIpo = nil; }
    if(_wcsIpo) { [_wcsIpo removeTargetWithObject:self]; [_wcsIpo release]; _wcsIpo = nil; }
    
    [_vSync release]; _vSync = nil;
    [_rSync release]; _rSync = nil;
    [_pSync release]; _pSync = nil;
    
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
        if(!(_vFlags & EGW_OBJEXTEND_FLG_ALWAYSOTGHMG)) {
            egwMatMultiply44f(&_wcsTrans, &_lcsTrans, &twcsTrans);
            
            EGWsingle det = egwMatDeterminant44f(&twcsTrans);
            if(egwIsOnef(egwAbsf(det)))
                egwMatInvertOtg44f(&twcsTrans, &_ccsTrans);
            else
                egwMatInvertDet44f(&twcsTrans, det, &_ccsTrans);
        } else {
            egwMatMultiplyHmg44f(&_wcsTrans, &_lcsTrans, &twcsTrans);
            
            egwMatInvertOtg44f(&twcsTrans, &_ccsTrans);
        }
        
        [_wcsFVBVol orientateByTransform:&twcsTrans fromVolume:[_base cameraBounding]];
        [_wcsCVBVol orientateByTransform:&twcsTrans fromVolume:[_base viewingBounding]];
        
        _ortPending = NO;
        
        if((EGW_NODECMPMRG_CAMERA & (EGW_CORECMP_TYPE_BVOLS | EGW_CORECMP_TYPE_FRAMES | EGW_CORECMP_TYPE_SOURCES | EGW_CORECMP_TYPE_SYNCS)) &&
           _parent && ![_parent isInvokingChild]) {
            EGWuint cmpntTypes = (((_vFlags & EGW_OBJTREE_FLG_NOUMRGBVOLS) || [_wcsCVBVol class] == [egwZeroBounding class]) ? 0 : EGW_CORECMP_TYPE_BVOLS & EGW_NODECMPMRG_CAMERA) |
                                   (_vFlags & EGW_OBJTREE_FLG_NOUMRGFRAMES ? 0 : EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_CAMERA) |
                                   (_vFlags & EGW_OBJTREE_FLG_NOUMRGSYNCS ? 0 : EGW_CORECMP_TYPE_SOURCES & EGW_NODECMPMRG_CAMERA) |
                                   (_vFlags & EGW_OBJTREE_FLG_NOUMRGSOURCES ? 0 : EGW_CORECMP_TYPE_SYNCS & EGW_NODECMPMRG_CAMERA);
            if(cmpntTypes)
                [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        }
        
        _invkParent = NO;
    }
}

- (BOOL)bindForPlaybackWithFlags:(EGWuint)flags {
    if(_ortPending) [self applyOrientation];
    
    // NOTE: The code below is non-abstracted OpenAL dependent.
    ALfloat orient[6] = {-_wcsTrans.column[2].r1, -_wcsTrans.column[2].r2, -_wcsTrans.column[2].r3,
                          _wcsTrans.column[1].r1,  _wcsTrans.column[1].r2,  _wcsTrans.column[1].r3};
    alListenerfv(AL_POSITION, (const ALfloat*)&(_wcsTrans.column[3]));
    alListenerfv(AL_VELOCITY, (const ALfloat*)&_wcsVelocity);
    alListenerfv(AL_ORIENTATION, orient);
    
    egwSFPVldtrValidate(_pSync, @selector(validate));
    if(egwSFPVldtrIsValidated(_pSync, @selector(isValidated)) && egwSFPVldtrIsValidated(_rSync, @selector(isValidated)))
        egwSFPVldtrValidate(_vSync, @selector(validate));
    return YES;
}

- (BOOL)bindForRenderingWithFlags:(EGWuint)flags {
    if(_ortPending) [self applyOrientation];
    
    // NOTE: The code below is non-abstracted OpenGLES dependent. Staying this way till ES2. -jw
    glMatrixMode(GL_PROJECTION);
    glLoadMatrixf((const GLfloat*)[_base ndcsTransform]);
    glMultMatrixf((const GLfloat*)&_ccsTrans);
    glMatrixMode(GL_TEXTURE);
    glLoadIdentity();
    glMatrixMode(GL_MODELVIEW);
    //glLoadMatrixf((const GLfloat*)&_ccsTrans);
    glLoadIdentity();
    
    egwSFPVldtrValidate(_rSync, @selector(validate));
    if(egwSFPVldtrIsValidated(_pSync, @selector(isValidated)) && egwSFPVldtrIsValidated(_rSync, @selector(isValidated)))
        egwSFPVldtrValidate(_vSync, @selector(validate));
    return YES;
}

- (void)offsetByTransform:(const egwMatrix44f*)lcsTransform {
    egwVecCopy3f((egwVector3f*)&(lcsTransform->column[3]), (egwVector3f*)&(_lcsTrans.column[3]));
    
    if(++_vFrame == EGW_FRAME_ALWAYSFAIL) _vFrame = 1;
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_pSync, @selector(invalidate)); egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (void)orientateByTransform:(const egwMatrix44f*)wcsTransform {
    egwMatCopy44f(wcsTransform, &_wcsTrans);
    
    if(++_vFrame == EGW_FRAME_ALWAYSFAIL) _vFrame = 1;
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_pSync, @selector(invalidate)); egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (void)orientateByImpending {
    if(++_vFrame == EGW_FRAME_ALWAYSFAIL) _vFrame = 1;
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_pSync, @selector(invalidate)); egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (void)orientateByLookingAt:(const egwVector3f*)lookPos withCameraAt:(const egwVector3f*)camPos {
    egwVector3f lookAtDir;
    
    egwVecInit3f(&lookAtDir, lookPos->axis.x - camPos->axis.x, lookPos->axis.y - camPos->axis.y, lookPos->axis.z - camPos->axis.z);
    
    _wcsTrans.component.r1c3 = -lookAtDir.axis.x; _wcsTrans.component.r2c3 = -lookAtDir.axis.y; _wcsTrans.component.r3c3 = -lookAtDir.axis.z; _wcsTrans.component.r4c3 = 0.0f;
    
    if(!(egwIsZerof(_wcsTrans.component.r1c3) && !egwIsZerof(_wcsTrans.component.r2c3) && egwIsZerof(_wcsTrans.component.r3c3))) {
        egwVecCrossProd3f(&lookAtDir, &egwSIVecUnitY3f, (egwVector3f*)&(_wcsTrans.column[0])); _wcsTrans.component.r4c1 = 0.0f;
    } else {
        egwVecCrossProd3f(&lookAtDir, (lookAtDir.axis.y >= 0.0f ? &egwSIVecUnitZ3f : &egwSIVecNegUnitZ3f), (egwVector3f*)&(_wcsTrans.column[0])); _wcsTrans.component.r4c1 = 0.0f;
    }
    
    egwVecCrossProd3f((egwVector3f*)&(_wcsTrans.column[0]), &lookAtDir, (egwVector3f*)&(_wcsTrans.column[1])); _wcsTrans.component.r4c2 = 0.0f;
    
    egwVecNormalize3f((egwVector3f*)&(_wcsTrans.column[0]), (egwVector3f*)&(_wcsTrans.column[0]));
    egwVecNormalize3f((egwVector3f*)&(_wcsTrans.column[1]), (egwVector3f*)&(_wcsTrans.column[1]));
    egwVecNormalize3f((egwVector3f*)&(_wcsTrans.column[2]), (egwVector3f*)&(_wcsTrans.column[2]));
    
    egwVecCopy3f(camPos, (egwVector3f*)&(_wcsTrans.column[3])); _wcsTrans.component.r4c4 = 1.0f;
    
    if(++_vFrame == EGW_FRAME_ALWAYSFAIL) _vFrame = 1;
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_pSync, @selector(invalidate)); egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (void)pickingRay:(egwRay4f*)pickRay fromPoint:(const egwPoint2i*)scrnPoint {
    egwMatrix44f twcsTrans;
    
    // We can cheat a bit and use the camera's WCS position as the origin point here
    egwVecAdd3f((egwVector3f*)&(_lcsTrans.column[3]), (egwVector3f*)&(_wcsTrans.column[3]), (egwVector3f*)&(pickRay->line.origin)); pickRay->line.origin.axis.w = 1.0f;
    
    pickRay->line.normal.axis.x = ((EGWsingle)(scrnPoint->axis.x) / (EGWsingle)[egwAIGfxCntxAGL bufferWidth]) * 2.0f - 1.0f;
    pickRay->line.normal.axis.y = (1.0f - ((EGWsingle)(scrnPoint->axis.y) / (EGWsingle)[egwAIGfxCntxAGL bufferHeight])) * 2.0f - 1.0f;
    pickRay->line.normal.axis.z = -1.0f; // front plane
    pickRay->line.normal.axis.w = 1.0f; // point at first
    pickRay->s = 0.0f;
    
    egwVecTransform444f([_base ccsTransform], &(pickRay->line.normal), &(pickRay->line.normal)); // NDCS -> CCS
    
    egwMatMultiply44f(&_wcsTrans, &_lcsTrans, &twcsTrans);
    egwVecTransform444f(&twcsTrans, &(pickRay->line.normal), &(pickRay->line.normal)); // CCS -> WCS
    
    egwVecSubtract3f((egwVector3f*)&(pickRay->line.normal), (egwVector3f*)&(pickRay->line.origin), (egwVector3f*)&(pickRay->line.normal)); pickRay->line.normal.axis.w = 0.0f; // now dir
    egwVecNormalize3f((egwVector3f*)&(pickRay->line.normal), (egwVector3f*)&(pickRay->line.normal));
}

- (id<egwPAssetBase>)assetBase {
    return _base;
}

- (EGWuint)coreObjectTypes {
    return (EGW_COREOBJ_TYPE_CAMERA | EGW_COREOBJ_TYPE_ORIENTABLE);
}

- (NSString*)identity {
    return _ident;
}

- (egwValidater*)playbackSync {
    if(egwSFPVldtrIsInvalidated(_vSync, @selector(isInvalidated)))
        egwSFPVldtrInvalidate(_pSync, @selector(invalidate));
    return _pSync;
}

- (egwValidater*)renderingSync {
    if(egwSFPVldtrIsInvalidated(_vSync, @selector(isInvalidated)))
        egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
    return _rSync;
}

- (const egwVector4f*)linearVelocity {
    return &_wcsVelocity;
}

- (id<egwPInterpolator>)offsetDriver {
    return _lcsIpo;
}

- (id<egwPInterpolator>)orientateDriver {
    return _wcsIpo;
}

- (id<egwPBounding>)viewingBounding {
    return _wcsCVBVol;
}

- (id<egwPBounding>)cameraBounding {
    return _wcsFVBVol;
}

- (EGWuint)viewingFlags {
    return _vFlags;
}

- (EGWuint16)viewingFrame {
    return _vFrame;
}

- (const egwVector4f*)viewingSource {
    return (const egwVector4f*)&(_wcsTrans.column[3]);
}

- (egwValidater*)viewingSync {
    return _vSync;
}

- (const egwMatrix44f*)wcsTransform {
    return &_wcsTrans;
}

- (const egwMatrix44f*)lcsTransform {
    return &_lcsTrans;
}

- (egwMatrix44f*)ccsTransform {
    return &_ccsTrans;
}

- (id<egwPObjectBranch>)parent {
    return _parent;
}

- (id<egwPObjectBranch>)root {
    return (_parent ? [_parent root] : nil);
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
            NSLog(@"egwPerspectiveCamera: setParent: Warning: Object system is overriding WCS interpolator driver for instance asset '%@' (%p).", _ident, self);
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

- (void)setLinearVelocity:(egwVector3f*)velocity {
    egwVecCopy3f(velocity, (egwVector3f*)&_wcsVelocity);
    egwSFPVldtrInvalidate(_pSync, @selector(invalidate));
}

- (void)setViewingFlags:(EGWuint)flags {
    _vFlags = flags;
    
    if((EGW_NODECMPMRG_CAMERA & EGW_CORECMP_TYPE_FLAGS) &&
       _parent && !_invkParent && ![_parent isInvokingChild]) {
        _invkParent = YES;
        EGWuint cmpntTypes = (_vFlags & EGW_OBJTREE_FLG_NOUMRGFLAGS ? 0 : EGW_CORECMP_TYPE_FLAGS & EGW_NODECMPMRG_CAMERA);
        if(cmpntTypes)
            [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        _invkParent = NO;
    }
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

- (BOOL)isOrientationPending {
    return _ortPending;
}

- (void)validaterDidValidate:(egwValidater*)validater {
    if(_ortPending) [self applyOrientation];
    
    if(_pSync == validater || _rSync == validater) {
        if(egwSFPVldtrIsInvalidated(_vSync, @selector(isInvalidated)) && egwSFPVldtrIsValidated(_rSync, @selector(isValidated)) && egwSFPVldtrIsValidated(_pSync, @selector(isValidated)))
            egwSFPVldtrValidate(_vSync, @selector(validate));
    } else if(_vSync == validater &&
              (EGW_NODECMPMRG_CAMERA & EGW_CORECMP_TYPE_SYNCS) &&
              _parent && !_invkParent && ![_parent isInvokingChild]) {
        _invkParent = YES;
        EGWuint cmpntTypes = (_vFlags & EGW_OBJTREE_FLG_NOUMRGSYNCS ? 0 : EGW_OBJTREE_FLG_NOUMRGSYNCS & EGW_NODECMPMRG_CAMERA);
        if(cmpntTypes)
            [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[validater coreObjects] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        _invkParent = NO;
    }
}

- (void)validaterDidInvalidate:(egwValidater*)validater {
    if(_pSync == validater || _rSync == validater) {
        if(egwSFPVldtrIsValidated(_vSync, @selector(isValidated)) && (egwSFPVldtrIsInvalidated(_rSync, @selector(isInvalidated)) || egwSFPVldtrIsInvalidated(_pSync, @selector(isInvalidated))))
            egwSFPVldtrInvalidate(_vSync, @selector(invalidate));
    } else if(_vSync == validater &&
              (EGW_NODECMPMRG_CAMERA & EGW_CORECMP_TYPE_SYNCS) &&
              _parent && !_invkParent && ![_parent isInvokingChild]) {
        _invkParent = YES;
        EGWuint cmpntTypes = (_vFlags & EGW_OBJTREE_FLG_NOUMRGSYNCS ? 0 : EGW_OBJTREE_FLG_NOUMRGSYNCS & EGW_NODECMPMRG_CAMERA);
        if(cmpntTypes)
            [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[validater coreObjects] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        _invkParent = NO;
    }
}

@end


// !!!: ***** egwOrthogonalCamera *****

@implementation egwOrthogonalCamera

- (id)init {
    if([self isMemberOfClass:[egwOrthogonalCamera class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent graspAngle:(EGWsingle)angle surfaceWidth:(EGWsingle)width surfaceHeight:(EGWsingle)height zeroAlign:(EGWuint)zfAlign {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwCameraBase alloc] initOrthogonalWithIdentity:assetIdent graspAngle:angle surfaceWidth:width surfaceHeight:height zeroAlign:zfAlign])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_ccsTrans);
    egwVecCopy4f(&egwSIVecZero4f, &_wcsVelocity);
    if(!(_wcsFVBVol = [(NSObject*)[_base cameraBounding] copy])) { [self release]; return (self = nil); }
    if(!(_wcsCVBVol = [(NSObject*)[_base viewingBounding] copy])) { [self release]; return (self = nil); }
    
    _vFlags = EGW_CAMOBJ_VIEWFLG_DFLT;
    _vFrame = 1;
    if(!(_pSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_AUDIO])) { [self release]; return (self = nil); }
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_GRAPHIC])) { [self release]; return (self = nil); }
    if(!(_vSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_CAMERA])) { [self release]; return (self = nil); }
    
    return self;
}

- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent {
    if(!([asset isKindOfClass:[self class]]) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = (egwCameraBase*)[[asset assetBase] retain])) { [self release]; return (self = nil); }
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    egwMatCopy44f([(egwOrthogonalCamera*)asset wcsTransform], &_wcsTrans);
    egwMatCopy44f([(egwOrthogonalCamera*)asset lcsTransform], &_lcsTrans);
    egwMatCopy44f([(egwOrthogonalCamera*)asset ccsTransform], &_ccsTrans);
    egwVecCopy3f((egwVector3f*)[(egwOrthogonalCamera*)asset linearVelocity], (egwVector3f*)&_wcsVelocity); _wcsVelocity.axis.w = 0.0f;
    if(!(_wcsFVBVol = [(NSObject*)[(egwOrthogonalCamera*)asset cameraBounding] copy])) { [self release]; return (self = nil); }
    if(!(_wcsCVBVol = [(NSObject*)[(egwOrthogonalCamera*)asset viewingBounding] copy])) { [self release]; return (self = nil); }
    if([(id<egwPOrientated>)asset offsetDriver] && ![self trySetOffsetDriver:[(id<egwPOrientated>)asset offsetDriver]]) { [self release]; return (self = nil); }
    if([(id<egwPOrientated>)asset orientateDriver] && ![self trySetOrientateDriver:[(id<egwPOrientated>)asset orientateDriver]]) { [self release]; return (self = nil); }
    
    _vFlags = [(egwOrthogonalCamera*)asset viewingFlags];
    _vFrame = 1;
    if(!(_pSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_AUDIO])) { [self release]; return (self = nil); }
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_GRAPHIC])) { [self release]; return (self = nil); }
    if(!(_vSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_CAMERA])) { [self release]; return (self = nil); }
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwOrthogonalCamera* copy = nil;
    NSString* copyIdent = nil;
    
    if([_ident hasSuffix:@"_default"])
        copyIdent = [[NSString alloc] initWithFormat:@"%@_%d", [_base identity], [_base nextInstanceIndex]];
    else copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwOrthogonalCamera allocWithZone:zone] initCopyOf:self
                                                        withIdentity:copyIdent])) {
        NSLog(@"egwOrthogonalCamera: copyWithZone: Failure initializing new camera from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    return copy;
}

- (void)dealloc {
    [_wcsFVBVol release]; _wcsFVBVol = nil;
    [_wcsCVBVol release]; _wcsCVBVol = nil;
    
    if(_lcsIpo) { [_lcsIpo removeTargetWithObject:self]; [_lcsIpo release]; _lcsIpo = nil; }
    if(_wcsIpo) { [_wcsIpo removeTargetWithObject:self]; [_wcsIpo release]; _wcsIpo = nil; }
    
    [_vSync release]; _vSync = nil;
    [_rSync release]; _rSync = nil;
    [_pSync release]; _pSync = nil;
    
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
        if(!(_vFlags & EGW_OBJEXTEND_FLG_ALWAYSOTGHMG)) {
            egwMatMultiply44f(&_wcsTrans, &_lcsTrans, &twcsTrans);
            
            EGWsingle det = egwMatDeterminant44f(&twcsTrans);
            if(egwIsOnef(egwAbsf(det)))
                egwMatInvertOtg44f(&twcsTrans, &_ccsTrans);
            else
                egwMatInvertDet44f(&twcsTrans, det, &_ccsTrans);
        } else {
            egwMatMultiplyHmg44f(&_wcsTrans, &_lcsTrans, &twcsTrans);
            
            egwMatInvertOtg44f(&twcsTrans, &_ccsTrans);
        }
        
        [_wcsFVBVol orientateByTransform:&twcsTrans fromVolume:[_base cameraBounding]];
        [_wcsCVBVol orientateByTransform:&twcsTrans fromVolume:[_base viewingBounding]];
        
        _ortPending = NO;
        
        if((EGW_NODECMPMRG_CAMERA & (EGW_CORECMP_TYPE_BVOLS | EGW_CORECMP_TYPE_FRAMES | EGW_CORECMP_TYPE_SOURCES | EGW_CORECMP_TYPE_SYNCS)) &&
           _parent && ![_parent isInvokingChild]) {
            EGWuint cmpntTypes = (((_vFlags & EGW_OBJTREE_FLG_NOUMRGBVOLS) || [_wcsCVBVol class] == [egwZeroBounding class]) ? 0 : EGW_CORECMP_TYPE_BVOLS & EGW_NODECMPMRG_CAMERA) |
                                   (_vFlags & EGW_OBJTREE_FLG_NOUMRGFRAMES ? 0 : EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_CAMERA) |
                                   (_vFlags & EGW_OBJTREE_FLG_NOUMRGSYNCS ? 0 : EGW_CORECMP_TYPE_SOURCES & EGW_NODECMPMRG_CAMERA) |
                                   (_vFlags & EGW_OBJTREE_FLG_NOUMRGSOURCES ? 0 : EGW_CORECMP_TYPE_SYNCS & EGW_NODECMPMRG_CAMERA);
            if(cmpntTypes)
                [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        }
        
        _invkParent = NO;
    }
}

- (BOOL)bindForPlaybackWithFlags:(EGWuint)flags {
    if(_ortPending) [self applyOrientation];
    
    // NOTE: The code below is non-abstracted OpenAL dependent.
    ALfloat orient[6] = {-_wcsTrans.column[2].r1, -_wcsTrans.column[2].r2, -_wcsTrans.column[2].r3,
    _wcsTrans.column[1].r1,  _wcsTrans.column[1].r2,  _wcsTrans.column[1].r3};
    alListenerfv(AL_POSITION, (const ALfloat*)&(_wcsTrans.column[3]));
    alListenerfv(AL_VELOCITY, (const ALfloat*)&_wcsVelocity);
    alListenerfv(AL_ORIENTATION, orient);
    
    egwSFPVldtrValidate(_pSync, @selector(validate));
    return YES;
}

- (BOOL)bindForRenderingWithFlags:(EGWuint)flags {
    if(_ortPending) [self applyOrientation];
    
    // NOTE: The code below is non-abstracted OpenGLES dependent. Staying this way till ES2. -jw
    glMatrixMode(GL_PROJECTION);
    glLoadMatrixf((const GLfloat*)[_base ndcsTransform]);
    glMultMatrixf((const GLfloat*)&_ccsTrans);
    glMatrixMode(GL_TEXTURE);
    glLoadIdentity();
    glMatrixMode(GL_MODELVIEW);
    //glLoadMatrixf((const GLfloat*)&_ccsTrans);
    glLoadIdentity();
    
    egwSFPVldtrValidate(_rSync, @selector(validate));
    return YES;
}

- (void)offsetByTransform:(const egwMatrix44f*)lcsTransform {
    egwVecCopy3f((egwVector3f*)&(lcsTransform->column[3]), (egwVector3f*)&(_lcsTrans.column[3]));
    
    if(++_vFrame == EGW_FRAME_ALWAYSFAIL) _vFrame = 1;
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_pSync, @selector(invalidate)); egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (void)orientateByTransform:(const egwMatrix44f*)wcsTransform {
    egwMatCopy44f(wcsTransform, &_wcsTrans);
    
    if(++_vFrame == EGW_FRAME_ALWAYSFAIL) _vFrame = 1;
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_pSync, @selector(invalidate)); egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (void)orientateByImpending {
    if(++_vFrame == EGW_FRAME_ALWAYSFAIL) _vFrame = 1;
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_pSync, @selector(invalidate)); egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (void)orientateByLookingAt:(const egwVector3f*)lookPos withCameraAt:(const egwVector3f*)camPos {
    egwVector3f lookAtDir;
    
    egwVecInit3f(&lookAtDir, lookPos->axis.x - camPos->axis.x, lookPos->axis.y - camPos->axis.y, lookPos->axis.z - camPos->axis.z);
    
    _wcsTrans.component.r1c3 = -lookAtDir.axis.x; _wcsTrans.component.r2c3 = -lookAtDir.axis.y; _wcsTrans.component.r3c3 = -lookAtDir.axis.z; _wcsTrans.component.r4c3 = 0.0f;
    
    if(!(egwIsZerof(_wcsTrans.component.r1c3) && !egwIsZerof(_wcsTrans.component.r2c3) && egwIsZerof(_wcsTrans.component.r3c3))) {
        egwVecCrossProd3f(&lookAtDir, &egwSIVecUnitY3f, (egwVector3f*)&(_wcsTrans.column[0])); _wcsTrans.component.r4c1 = 0.0f;
    } else {
        egwVecCrossProd3f(&lookAtDir, (lookAtDir.axis.y >= 0.0f ? &egwSIVecUnitZ3f : &egwSIVecNegUnitZ3f), (egwVector3f*)&(_wcsTrans.column[0])); _wcsTrans.component.r4c1 = 0.0f;
    }
    
    egwVecCrossProd3f((egwVector3f*)&(_wcsTrans.column[0]), &lookAtDir, (egwVector3f*)&(_wcsTrans.column[1])); _wcsTrans.component.r4c2 = 0.0f;
    
    egwVecNormalize3f((egwVector3f*)&(_wcsTrans.column[0]), (egwVector3f*)&(_wcsTrans.column[0]));
    egwVecNormalize3f((egwVector3f*)&(_wcsTrans.column[1]), (egwVector3f*)&(_wcsTrans.column[1]));
    egwVecNormalize3f((egwVector3f*)&(_wcsTrans.column[2]), (egwVector3f*)&(_wcsTrans.column[2]));
    
    egwVecCopy3f(camPos, (egwVector3f*)&(_wcsTrans.column[3])); _wcsTrans.component.r4c4 = 1.0f;
    
    if(++_vFrame == EGW_FRAME_ALWAYSFAIL) _vFrame = 1;
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_pSync, @selector(invalidate)); egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (void)pickingRay:(egwRay4f*)pickRay fromPoint:(const egwPoint2i*)scrnPoint {
    egwMatrix44f twcsTrans;
    
    pickRay->line.origin.axis.x = ((EGWsingle)(scrnPoint->axis.x) / (EGWsingle)[egwAIGfxCntxAGL bufferWidth]) * 2.0f - 1.0f;
    pickRay->line.origin.axis.y = (1.0f - ((EGWsingle)(scrnPoint->axis.y) / (EGWsingle)[egwAIGfxCntxAGL bufferHeight])) * 2.0f - 1.0f;
    pickRay->line.origin.axis.z = -1.0f; // front plane
    pickRay->line.origin.axis.w = 1.0f;
    pickRay->line.normal.axis.x = pickRay->line.origin.axis.x;
    pickRay->line.normal.axis.y = pickRay->line.origin.axis.y;
    pickRay->line.normal.axis.z = 1.0f; // back plane
    pickRay->line.normal.axis.w = 1.0f; // point at first
    pickRay->s = 0.0f;
    
    egwVecTransform444f([_base ccsTransform], &(pickRay->line.origin), &(pickRay->line.origin)); // NDCS -> CCS
    egwVecTransform444f([_base ccsTransform], &(pickRay->line.normal), &(pickRay->line.normal)); // NDCS -> CCS
    
    egwMatMultiply44f(&_wcsTrans, &_lcsTrans, &twcsTrans);
    egwVecTransform444f(&twcsTrans, &(pickRay->line.origin), &(pickRay->line.origin)); // CCS -> WCS
    egwVecTransform444f(&twcsTrans, &(pickRay->line.normal), &(pickRay->line.normal)); // CCS -> WCS
    
    egwVecSubtract3f((egwVector3f*)&(pickRay->line.normal), (egwVector3f*)&(pickRay->line.origin), (egwVector3f*)&(pickRay->line.normal)); pickRay->line.normal.axis.w = 0.0f; // now dir, 
    egwVecNormalize3f((egwVector3f*)&(pickRay->line.normal), (egwVector3f*)&(pickRay->line.normal));
}

- (id<egwPAssetBase>)assetBase {
    return _base;
}

- (EGWuint)coreObjectTypes {
    return (EGW_COREOBJ_TYPE_CAMERA | EGW_COREOBJ_TYPE_ORIENTABLE);
}

- (NSString*)identity {
    return _ident;
}

- (egwValidater*)playbackSync {
    return _pSync;
}

- (egwValidater*)renderingSync {
    return _rSync;
}

- (const egwVector4f*)linearVelocity {
    return &_wcsVelocity;
}

- (id<egwPInterpolator>)offsetDriver {
    return _lcsIpo;
}

- (id<egwPInterpolator>)orientateDriver {
    return _wcsIpo;
}

- (id<egwPBounding>)viewingBounding {
    return _wcsCVBVol;
}

- (id<egwPBounding>)cameraBounding {
    return _wcsFVBVol;
}

- (EGWuint)viewingFlags {
    return _vFlags;
}

- (EGWuint16)viewingFrame {
    return _vFrame;
}

- (const egwVector4f*)viewingSource {
    return (const egwVector4f*)&(_wcsTrans.column[3]);
}

- (egwValidater*)viewingSync {
    return _vSync;
}

- (const egwMatrix44f*)wcsTransform {
    return &_wcsTrans;
}

- (const egwMatrix44f*)lcsTransform {
    return &_lcsTrans;
}

- (egwMatrix44f*)ccsTransform {
    return &_ccsTrans;
}

- (id<egwPObjectBranch>)parent {
    return _parent;
}

- (id<egwPObjectBranch>)root {
    return (_parent ? [_parent root] : nil);
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
            NSLog(@"egwOrthogonalCamera: setParent: Warning: Object system is overriding WCS interpolator driver for instance asset '%@' (%p).", _ident, self);
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

- (void)setLinearVelocity:(egwVector3f*)velocity {
    egwVecCopy3f(velocity, (egwVector3f*)&_wcsVelocity);
    egwSFPVldtrInvalidate(_pSync, @selector(invalidate));
}

- (void)setViewingFlags:(EGWuint)flags {
    _vFlags = flags;
    
    if((EGW_NODECMPMRG_CAMERA & EGW_CORECMP_TYPE_FLAGS) &&
       _parent && !_invkParent && ![_parent isInvokingChild]) {
        EGWuint cmpntTypes = (_vFlags & EGW_OBJTREE_FLG_NOUMRGFLAGS ? 0 : EGW_CORECMP_TYPE_FLAGS & EGW_NODECMPMRG_CAMERA);
        _invkParent = YES;
        if(cmpntTypes)
            [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        _invkParent = NO;
    }
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

- (BOOL)isOrientationPending {
    return _ortPending;
}

- (void)validaterDidValidate:(egwValidater*)validater {
    if(_ortPending) [self applyOrientation];
    
    if(_pSync == validater || _rSync == validater) {
        if(egwSFPVldtrIsInvalidated(_vSync, @selector(isInvalidated)) && egwSFPVldtrIsValidated(_rSync, @selector(isValidated)) && egwSFPVldtrIsValidated(_pSync, @selector(isValidated)))
            egwSFPVldtrValidate(_vSync, @selector(validate));
    } else if(_vSync == validater &&
              (EGW_NODECMPMRG_CAMERA & EGW_CORECMP_TYPE_SYNCS) &&
              _parent && !_invkParent && ![_parent isInvokingChild]) {
        _invkParent = YES;
        EGWuint cmpntTypes = (_vFlags & EGW_OBJTREE_FLG_NOUMRGSYNCS ? 0 : EGW_OBJTREE_FLG_NOUMRGSYNCS & EGW_NODECMPMRG_CAMERA);
        if(cmpntTypes)
            [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[validater coreObjects] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        _invkParent = NO;
    }
}

- (void)validaterDidInvalidate:(egwValidater*)validater {
    if(_pSync == validater || _rSync == validater) {
        if(egwSFPVldtrIsValidated(_vSync, @selector(isValidated)) && (egwSFPVldtrIsInvalidated(_rSync, @selector(isInvalidated)) || egwSFPVldtrIsInvalidated(_pSync, @selector(isInvalidated))))
            egwSFPVldtrInvalidate(_vSync, @selector(invalidate));
    } else if(_vSync == validater &&
              (EGW_NODECMPMRG_CAMERA & EGW_CORECMP_TYPE_SYNCS) &&
              _parent && !_invkParent && ![_parent isInvokingChild]) {
        _invkParent = YES;
        EGWuint cmpntTypes = (_vFlags & EGW_OBJTREE_FLG_NOUMRGSYNCS ? 0 : EGW_OBJTREE_FLG_NOUMRGSYNCS & EGW_NODECMPMRG_CAMERA);
        if(cmpntTypes)
            [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[validater coreObjects] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        _invkParent = NO;
    }
}

@end


// !!!: ***** egwCameraBase *****

@implementation egwCameraBase

+ (id)allocWithZone:(NSZone*)zone {
    id alloc = [super allocWithZone:zone];
    if(alloc) [egwAssetManager incBaseRef];
    if(EGW_ENGINE_ASSETS_CREATIONMSGS) NSLog(@"egwCameraBase: allocWithZone: Creating new camera base asset (%p).", alloc);
    return alloc;
}

- (id)init {
    if([self isMemberOfClass:[egwCameraBase class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initPerspectiveWithIdentity:(NSString*)assetIdent graspAngle:(EGWsingle)angle fieldOfView:(EGWsingle)fov aspectRatio:(EGWsingle)aspect frontPlane:(EGWsingle)near backPlane:(EGWsingle)far {
    egwVector3f farPoint;
    EGWsingle f;
    
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    // Perspective projection mapping WCS down to [-1,1][-1,1][-1,1]
    near = egwAbsf(near); far = egwAbsf(far);
    
    f = egwTanf(egwDegToRad(egwClampf(fov, EGW_SFLT_EPSILON, 180.0f - EGW_SFLT_EPSILON)) * 0.5f);
    
    if(aspect >= 1.0f) {
        egwMatInit44f(&_ndcsTrans,
            near / f, 0.0f, 0.0f, 0.0f,
            0.0f, near / (f / (1.0f / aspect)), 0.0f, 0.0f,
            0.0f, 0.0f, -((far + near) / (far - near)), -((2.0f * far * near) / (far - near)),
            0.0f, 0.0f, -1.0f, 0.0f);
    } else {
        egwMatInit44f(&_ndcsTrans,
            near / (f / (1.0f / aspect)), 0.0f, 0.0f, 0.0f,
            0.0f, near / f, 0.0f, 0.0f,
            0.0f, 0.0f, -((far + near) / (far - near)), -((2.0f * far * near) / (far - near)),
            0.0f, 0.0f, -1.0f, 0.0f);
    }
    
    if(!egwIsZerof(angle)) {
        egwMatrix44f rotate;
        egwMatRotateAxisAngle44fs(NULL, 0.0f, 0.0f, 1.0f, egwDegToRad(angle), &rotate);
        egwMatMultiply44f(&_ndcsTrans, &rotate, &_ndcsTrans); // Rotate happens after normalization
    }
    
    egwMatInvert44f(&_ndcsTrans, &_ccsTrans);
    
    if(!(_mcsFVBVol = [[egwBoundingFrustum alloc] initPerspectiveWithFieldOfView:fov aspectRatio:aspect frontPlane:near backPlane:far])) { [self release]; return (self = nil); }
    
    egwVecInit3f(&farPoint, f * aspect * far, f * far, -far);
    if(!(_mcsCVBVol = [[egwBoundingSphere alloc] initWithBoundingOrigin:(egwVector3f*)[_mcsFVBVol boundingOrigin] boundingRadius:egwVecDistance3f((egwVector3f*)[_mcsFVBVol boundingOrigin], &farPoint)])) { [self release]; return (self = nil); }
    
    return self;
}

- (id)initOrthogonalWithIdentity:(NSString*)assetIdent graspAngle:(EGWsingle)angle surfaceWidth:(EGWsingle)width surfaceHeight:(EGWsingle)height zeroAlign:(EGWuint)zfAlign {
    egwVector3f origin, min, max;
    
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    // Orthogonal projection mapping WCS (z clipped at [0,-1]) down to [-1,1][-1,1][-1,1]
    width = egwAbsf(width); height = egwAbsf(height);
    switch(zfAlign) {
        default:
        case EGW_CAMERA_ORTHO_ZFALIGN_BTMLFT: {
            egwMatInit44f(&_ndcsTrans,
                2.0f / width, 0.0f, 0.0f, -1.0f,
                0.0f, 2.0f / height, 0.0f, -1.0f,
                0.0f, 0.0f, -1.999999f, 0.999999f, // [0b,1f)
                0.0f, 0.0f, 0.0f, 1.0f);
            egwVecInit3f(&origin, width * 0.5f, height * 0.5f, -0.5f);
            egwVecInit3f(&min, 0.0f, 0.0f, -1.0f);
            egwVecInit3f(&max, width, height, 0.0f);
        } break;
        
        case EGW_CAMERA_ORTHO_ZFALIGN_TOPLFT: {
            egwMatInit44f(&_ndcsTrans,
                2.0f / width, 0.0f, 0.0f, -1.0f,
                0.0f, 2.0f / -height, 0.0f, 1.0f,
                0.0f, 0.0f, -1.999999f, 0.999999f, // [0b,1f)
                0.0f, 0.0f, 0.0f, 1.0f);
            egwVecInit3f(&origin, width * 0.5f, height * 0.5f, -0.5f);
            egwVecInit3f(&min, 0.0f, 0.0f, -1.0f);
            egwVecInit3f(&max, width, height, 0.0f);
        } break;
        
        case EGW_CAMERA_ORTHO_ZFALIGN_CENTER: {
            egwMatInit44f(&_ndcsTrans,
                2.0f / width, 0.0f, 0.0f, 0.0f,
                0.0f, 2.0f / height, 0.0f, 0.0f,
                0.0f, 0.0f, -1.999999f, 0.999999f, // [0b,1f)
                0.0f, 0.0f, 0.0f, 1.0f);
            egwVecInit3f(&origin, 0.0f, 0.0f, -0.5f);
            egwVecInit3f(&min, width * -0.5f, height * -0.5f, -1.0f);
            egwVecInit3f(&max, width * 0.5f, height * 0.5f, 0.0f);
        } break;
    }
    // NOTE: The z mapping must create values from [0,1] to (1,-1] (otherwise are clipped), so .999999 ensures a smidget of non-inclusiveness at both ends. -jw
    
    if(!egwIsZerof(angle)) {
        egwMatrix44f rotate;
        egwMatRotateAxisAngle44fs(NULL, 0.0f, 0.0f, 1.0f, egwDegToRad(angle), &rotate);
        egwMatMultiply44f(&rotate, &_ndcsTrans, &_ndcsTrans); // Rotate happens before normalization
    }
    
    egwMatInvert44f(&_ndcsTrans, &_ccsTrans);
    
    if(!(_mcsFVBVol = [[egwBoundingBox alloc] initWithBoundingOrigin:&origin boundingMinimum:&min boundingMaximum:&max])) { [self release]; return (self = nil); }
    
    if(!(_mcsCVBVol = [[egwBoundingSphere alloc] initWithBoundingOrigin:(egwVector3f*)[_mcsFVBVol boundingOrigin] boundingRadius:egwVecDistance3f(&origin, &max)])) { [self release]; return (self = nil); }
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    return nil;
}

- (id)mutableCopyWithZone:(NSZone*)zone {
    return nil;
}

- (void)dealloc {
    _instCounter = NSNotFound;
    
    [_mcsFVBVol release]; _mcsFVBVol = nil;
    [_mcsCVBVol release]; _mcsCVBVol = nil;
    
    if(EGW_ENGINE_ASSETS_DESTROYMSGS) NSLog(@"egwCameraBase: dealloc: Destroying camera base asset '%@' (%p).", _ident, self);
    [_ident release]; _ident = nil;
    [egwAssetManager decBaseRef];
    [super dealloc];
}

- (NSString*)identity {
    return _ident;
}

- (egwMatrix44f*)ndcsTransform {
    return &_ndcsTrans;
}

- (egwMatrix44f*)ccsTransform {
    return &_ccsTrans;
}

- (EGWuint)nextInstanceIndex {
    return ++_instCounter;
}

- (id<egwPBounding>)viewingBounding {
    return _mcsCVBVol;
}

- (id<egwPBounding>)cameraBounding {
    return _mcsFVBVol;
}

@end

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

/// @file egwLights.m
/// @ingroup geWizES_gfx_lights
/// Light Assets Implementations.

#import "egwLights.h"
#import "../sys/egwSysTypes.h"
#import "../sys/egwAssetManager.h"
#import "../sys/egwGfxContext.h"
#import "../sys/egwGfxContextNSGL.h"  // NOTE: Below code has a dependence on GL.
#import "../sys/egwGfxContextEAGLES.h"
#import "../math/egwMatrix.h"
#import "../math/egwVector.h"
#import "../gfx/egwGraphics.h"
#import "../gfx/egwBoundings.h"
#import "../gfx/egwMaterials.h"
#import "../geo/egwGeometry.h"
#import "../obj/egwObjectBranch.h"
#import "../phy/egwInterpolators.h"
#import "../misc/egwValidater.h"


// !!!: ***** egwPointLight *****

@implementation egwPointLight

static egwLightJumpTable _egwPLJT = { NULL };

+ (id)allocWithZone:(NSZone*)zone {
    NSObject* inst = (NSObject*)[super allocWithZone:zone];
    
    if(!_egwPLJT.fpRetain && [inst isMemberOfClass:[egwPointLight class]]) {
        _egwPLJT.fpRetain = (id(*)(id, SEL))[inst methodForSelector:@selector(retain)];
        _egwPLJT.fpRelease = (void(*)(id, SEL))[inst methodForSelector:@selector(release)];
        _egwPLJT.fpIBind = (BOOL(*)(id, SEL, EGWuint, EGWuint))[inst methodForSelector:@selector(bindForIlluminationStage:withFlags:)];
        _egwPLJT.fpIUnbind = (BOOL(*)(id, SEL, EGWuint))[inst methodForSelector:@selector(unbindIlluminationWithFlags:)];
        _egwPLJT.fpLBase = (id<NSObject>(*)(id, SEL))[inst methodForSelector:@selector(lightBase)];
        _egwPLJT.fpIBounding = (id<egwPBounding>(*)(id, SEL))[inst methodForSelector:@selector(illuminationBounding)];
        _egwPLJT.fpIFlags = (EGWuint(*)(id, SEL))[inst methodForSelector:@selector(illuminationFlags)];
        _egwPLJT.fpISync = (egwValidater*(*)(id, SEL))[inst methodForSelector:@selector(illuminationSync)];
        _egwPLJT.fpILBStage = (EGWuint(*)(id, SEL))[inst methodForSelector:@selector(lastIlluminationBindingStage)];
    }
    
    return (id)inst;
}

- (id)init {
    if([self isMemberOfClass:[egwPointLight class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent lightRadius:(EGWsingle)illumRadius lightMaterial:(egwMaterial4f*)illumMat lightAttenuation:(egwAttenuation3f*)illumAtten {
    id<egwPBounding> illumVol;
    
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    _lastIBind = NSNotFound;
    
    // Fudge an egwInfiniteBounding in place of a egwBoundingSphere if radius is EGW_SFLT_MAX, for faster testing
    if(!(illumVol = (illumRadius < EGW_SFLT_MAX ? [[egwBoundingSphere alloc] initWithBoundingOrigin:&egwSIVecZero3f boundingRadius:illumRadius] : [[egwInfiniteBounding alloc] initWithBoundingOrigin:&egwSIVecZero3f]))) { [self release]; return (self = nil); }
    if(!(_base = [[egwLightBase alloc] initWithIdentity:assetIdent lightDirection:NULL lightVolume:illumVol lightMaterial:illumMat lightAttenuation:illumAtten])) { [illumVol release]; illumVol = nil; [self release]; return (self = nil); }
    else { [illumVol release]; illumVol = nil; }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _iFlags = EGW_LGTOBJ_ILLMFLG_DFLT;
    if(!(_iSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_LIGHT])) { [self release]; return (self = nil); }
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    if(!(_wcsIBVol = [(NSObject*)[_base illuminationBounding] copy])) { [self release]; return (self = nil); }
    
    _lMat = [_base illuminationMaterial];
    _lAtten = [_base illuminationAttenuation];
    
    return self;
}

- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent {
    if(!([asset isKindOfClass:[self class]]) || !(self = [super init])) { [self release]; return (self = nil); }
    
    _lastIBind = NSNotFound;
    
    if(!(_base = (egwLightBase*)[[asset assetBase] retain])) { [self release]; return (self = nil); }
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _iFlags = [(egwPointLight*)asset illuminationFlags];
    if(!(_iSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_LIGHT])) { [self release]; return (self = nil); }
    
    egwMatCopy44f([(egwPointLight*)asset wcsTransform], &_wcsTrans);
    egwMatCopy44f([(egwPointLight*)asset lcsTransform], &_lcsTrans);
    if(!(_wcsIBVol = [(NSObject*)[(egwPointLight*)asset illuminationBounding] copy])) { [self release]; return (self = nil); }
    if([(id<egwPOrientated>)asset offsetDriver] && ![self trySetOffsetDriver:[(id<egwPOrientated>)asset offsetDriver]]) { [self release]; return (self = nil); }
    if([(id<egwPOrientated>)asset orientateDriver] && ![self trySetOrientateDriver:[(id<egwPOrientated>)asset orientateDriver]]) { [self release]; return (self = nil); }
    
    _lMat = [_base illuminationMaterial];
    _lAtten = [_base illuminationAttenuation];
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwPointLight* copy = nil;
    NSString* copyIdent = nil;
    
    if([_ident hasSuffix:@"_default"])
        copyIdent = [[NSString alloc] initWithFormat:@"%@_%d", [_base identity], [_base nextInstanceIndex]];
    else copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwPointLight allocWithZone:zone] initCopyOf:self
                                                  withIdentity:copyIdent])) {
        NSLog(@"egwPointLight: copyWithZone: Failure initializing new light from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    return copy;
}

- (void)dealloc {
    if(_isIBound) [self unbindIlluminationWithFlags:EGW_BNDOBJ_BINDFLG_DFLT];
    
    [_iSync release]; _iSync = nil;
    [_wcsIBVol release]; _wcsIBVol = nil;
    
    if(_lcsIpo) { [_lcsIpo removeTargetWithObject:self]; [_lcsIpo release]; _lcsIpo = nil; }
    if(_wcsIpo) { [_wcsIpo removeTargetWithObject:self]; [_wcsIpo release]; _wcsIpo = nil; }
    
    _lMat = NULL;
    _lAtten = NULL;
    
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
        if(!(_iFlags & EGW_OBJEXTEND_FLG_ALWAYSOTGHMG))
            egwMatMultiply44f(&_wcsTrans, &_lcsTrans, &twcsTrans);
        else
            egwMatMultiplyHmg44f(&_wcsTrans, &_lcsTrans, &twcsTrans);
        
        [_wcsIBVol orientateByTransform:&twcsTrans fromVolume:[_base illuminationBounding]];
        // TODO: Need to modify attenuation to do MCS->WCS transform -jw
        
        _ortPending = NO;
        
        if((EGW_NODECMPMRG_LIGHT & (EGW_CORECMP_TYPE_BVOLS | EGW_CORECMP_TYPE_FRAMES | EGW_CORECMP_TYPE_SOURCES | EGW_CORECMP_TYPE_SYNCS)) &&
           _parent && ![_parent isInvokingChild]) {
            EGWuint cmpntTypes = (((_iFlags & EGW_OBJTREE_FLG_NOUMRGBVOLS) || [_wcsIBVol class] == [egwZeroBounding class]) ? 0 : EGW_CORECMP_TYPE_BVOLS & EGW_NODECMPMRG_LIGHT) |
                                   (_iFlags & EGW_OBJTREE_FLG_NOUMRGFRAMES ? 0 : EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_LIGHT) |
                                   (_iFlags & EGW_OBJTREE_FLG_NOUMRGSYNCS ? 0 : EGW_CORECMP_TYPE_SOURCES & EGW_NODECMPMRG_LIGHT) |
                                   (_iFlags & EGW_OBJTREE_FLG_NOUMRGSOURCES ? 0 : EGW_CORECMP_TYPE_SYNCS & EGW_NODECMPMRG_LIGHT);
            if(cmpntTypes)
                [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        }
        
        _invkParent = NO;
    }
}

- (void)startIlluminating {
    if(!_isIlluminating) {
        @synchronized(self) {
            if(!_isIlluminating) {
                // TODO: Add into world scene.
                
                _isIlluminating = YES;
            }
        }
    }
}

- (void)stopIlluminating {
    if(_isIlluminating) {
        @synchronized(self) {
            if(_isIlluminating) {
                // TODO: Add into world scene.
                
                _isIlluminating = NO;
            }
        }
    }
}

- (BOOL)bindForIlluminationStage:(EGWuint)illumStage withFlags:(EGWuint)flags {
    if(_ortPending) [self applyOrientation];
    
    // NOTE: The code below is non-abstracted OpenGLES dependent. Staying this way till ES2. -jw
    if(!_isIBound || (flags & EGW_BNDOBJ_BINDFLG_APISYNCINVLD) || egwSFPVldtrIsInvalidated(_iSync, @selector(isInvalidated))) {
        GLenum light = GL_LIGHT0 + (_lastIBind = illumStage);
        
        if(flags & EGW_BNDOBJ_BINDFLG_TOGGLE)
            glEnable(light);
        
        if(!(flags & EGW_BNDOBJ_BINDFLG_SAMELASTBASE)) {
            glLightfv(light, GL_AMBIENT, (const GLfloat*)&_lMat->ambient);
            glLightfv(light, GL_DIFFUSE, (const GLfloat*)&_lMat->diffuse);
            glLightfv(light, GL_SPECULAR, (const GLfloat*)&_lMat->specular);
            glLightfv(light, GL_EMISSION, (const GLfloat*)&_lMat->emmisive);
            
            glLightf(light, GL_CONSTANT_ATTENUATION, (GLfloat)_lAtten->constant);
            glLightf(light, GL_LINEAR_ATTENUATION, (GLfloat)_lAtten->linear);
            glLightf(light, GL_QUADRATIC_ATTENUATION, (GLfloat)_lAtten->quadratic);
            
            glLightf(light, GL_SPOT_CUTOFF, (GLfloat)180.0f);
            glLightf(light, GL_SPOT_EXPONENT, (GLfloat)0.0f);
        }
        
        //if(!_isIBound || (flags & EGW_BNDOBJ_BINDFLG_APISYNCINVLD) || egwSFPVldtrIsInvalidated(_iSync, @selector(isInvalidated)))
            glLightfv(light, GL_POSITION, (const GLfloat*)[_wcsIBVol boundingOrigin]);
        
        _isIBound = YES;
        egwSFPVldtrValidate(_iSync, @selector(validate));
        return YES;
    }
    
    return NO;
}

- (BOOL)unbindIlluminationWithFlags:(EGWuint)flags {
    // NOTE: The code below is non-abstracted OpenGLES dependent. Staying this way till ES2. -jw
    if(_isIBound) {
        if(flags & EGW_BNDOBJ_BINDFLG_TOGGLE)
            glDisable(GL_LIGHT0 + _lastIBind);
        
        _isIBound = NO;
        return YES;
    }
    
    return NO;
}

- (void)offsetByTransform:(const egwMatrix44f*)lcsTransform {
    egwMatCopy44f(lcsTransform, &_lcsTrans);
    
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_iSync, @selector(invalidate));
}

- (void)orientateByTransform:(const egwMatrix44f*)wcsTransform {
    egwMatCopy44f(wcsTransform, &_wcsTrans);
    
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_iSync, @selector(invalidate));
}

- (void)orientateByImpending {
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_iSync, @selector(invalidate));
}

- (id<egwPAssetBase>)assetBase {
    return _base;
}

- (EGWuint)coreObjectTypes {
    return (EGW_COREOBJ_TYPE_LIGHT | EGW_COREOBJ_TYPE_ORIENTABLE);
}

- (NSString*)identity {
    return _ident;
}

- (const egwAttenuation3f*)illuminationAttenuation {
    return _lAtten;
}

- (id<NSObject>)lightBase {
    return _base;
}

- (id<egwPBounding>)illuminationBounding {
    return _wcsIBVol;
}

- (EGWuint)illuminationFlags {
    return _iFlags;
}

- (const egwLightJumpTable*)lightJumpTable {
    return &_egwPLJT;
}

- (const egwMaterial4f*)illuminationMaterial {
    return _lMat;
}

- (EGWsingle)illuminationRadius {
    // Only an egwBoundingSphere has a legit radius, otherwise is fudged by an egwInfiniteBounding
    if([_wcsIBVol isMemberOfClass:[egwBoundingSphere class]])
        return [(egwBoundingSphere*)_wcsIBVol boundingRadius];
    return EGW_SFLT_MAX;
}

- (const egwVector4f*)illuminationSource {
    return [_wcsIBVol boundingOrigin];
}

- (egwValidater*)illuminationSync {
    return _iSync;
}

- (EGWuint)lastIlluminationBindingStage {
    return _lastIBind;
}

- (const egwMatrix44f*)lcsTransform {
    return &_lcsTrans;
}

- (const egwMatrix44f*)wcsTransform {
    return &_wcsTrans;
}

- (id<egwPInterpolator>)offsetDriver {
    return _lcsIpo;
}

- (id<egwPInterpolator>)orientateDriver {
    return _wcsIpo;
}

- (id<egwPObjectBranch>)parent {
    return _parent;
}

- (id<egwPObjectBranch>)root {
    return (_parent ? [_parent root] : nil);
}

- (void)setIlluminationFlags:(EGWuint)flags {
    _iFlags = flags;
        
    if((EGW_NODECMPMRG_LIGHT & EGW_CORECMP_TYPE_FLAGS) &&
       _parent && !_invkParent && ![_parent isInvokingChild]) {
        _invkParent = YES;
        EGWuint cmpntTypes = (_iFlags & EGW_OBJTREE_FLG_NOUMRGFLAGS ? 0 : EGW_CORECMP_TYPE_FLAGS & EGW_NODECMPMRG_LIGHT);
        if(cmpntTypes)
            [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        _invkParent = NO;
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
            NSLog(@"egwPointLight: setParent: Warning: Object system is overriding WCS interpolator driver for instance asset '%@' (%p).", _ident, self);
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

- (BOOL)isIlluminating {
    return _isIlluminating;
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

- (BOOL)isBoundForIllumination {
    return _isIBound;
}

- (void)validaterDidValidate:(egwValidater*)validater {
    if(_ortPending) [self applyOrientation];
    
    if((EGW_NODECMPMRG_LIGHT & EGW_CORECMP_TYPE_SYNCS) && _parent && !_invkParent && ![_parent isInvokingChild]) {
        _invkParent = YES;
        [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_CORECMP_TYPE_SYNCS withObject:(id)[validater coreObjects] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        _invkParent = NO;
    }
}

- (void)validaterDidInvalidate:(egwValidater*)validater {
    if((EGW_NODECMPMRG_LIGHT & EGW_CORECMP_TYPE_SYNCS) && _parent && !_invkParent && ![_parent isInvokingChild]) {
        _invkParent = YES;
        [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_CORECMP_TYPE_SYNCS withObject:(id)[validater coreObjects] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        _invkParent = NO;
    }
}

@end


// !!!: ***** egwDirectionalLight *****

@implementation egwDirectionalLight

static egwLightJumpTable _egwDLJT = { NULL };

+ (id)allocWithZone:(NSZone*)zone {
    NSObject* inst = (NSObject*)[super allocWithZone:zone];
    
    if(!_egwDLJT.fpRetain && [inst isMemberOfClass:[egwDirectionalLight class]]) {
        _egwDLJT.fpRetain = (id(*)(id, SEL))[inst methodForSelector:@selector(retain)];
        _egwDLJT.fpRelease = (void(*)(id, SEL))[inst methodForSelector:@selector(release)];
        _egwDLJT.fpIBind = (BOOL(*)(id, SEL, EGWuint, EGWuint))[inst methodForSelector:@selector(bindForIlluminationStage:withFlags:)];
        _egwDLJT.fpIUnbind = (BOOL(*)(id, SEL, EGWuint))[inst methodForSelector:@selector(unbindIlluminationWithFlags:)];
        _egwDLJT.fpLBase = (id<NSObject>(*)(id, SEL))[inst methodForSelector:@selector(lightBase)];
        _egwPLJT.fpIBounding = (id<egwPBounding>(*)(id, SEL))[inst methodForSelector:@selector(illuminationBounding)];
        _egwDLJT.fpIFlags = (EGWuint(*)(id, SEL))[inst methodForSelector:@selector(illuminationFlags)];
        _egwDLJT.fpISync = (egwValidater*(*)(id, SEL))[inst methodForSelector:@selector(illuminationSync)];
        _egwDLJT.fpILBStage = (EGWuint(*)(id, SEL))[inst methodForSelector:@selector(lastIlluminationBindingStage)];
    }
    
    return (id)inst;
}

- (id)init {
    if([self isMemberOfClass:[egwDirectionalLight class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent lightDirection:(egwVector3f*)illumDir lightMaterial:(egwMaterial4f*)illumMat lightAttenuation:(egwAttenuation3f*)illumAtten {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    _lastIBind = NSNotFound;
    
    if(!(_base = [[egwLightBase alloc] initWithIdentity:assetIdent lightDirection:illumDir lightVolume:[[egwInfiniteBounding alloc] initWithBoundingOrigin:&egwSIVecZero3f] lightMaterial:illumMat lightAttenuation:illumAtten])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _iFlags = EGW_LGTOBJ_ILLMFLG_DFLT;
    if(!(_iSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_LIGHT])) { [self release]; return (self = nil); }
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    egwVecCopy4f([_base illuminationDirection], &_wcsDir);
    
    _lMat = [_base illuminationMaterial];
    _lAtten = [_base illuminationAttenuation];
    
    return self;
}

- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent {
    if(!([asset isKindOfClass:[self class]]) || !(self = [super init])) { [self release]; return (self = nil); }
    
    _lastIBind = NSNotFound;
    
    if(!(_base = (egwLightBase*)[[asset assetBase] retain])) { [self release]; return (self = nil); }
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _iFlags = [(egwDirectionalLight*)asset illuminationFlags];
    if(!(_iSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_LIGHT])) { [self release]; return (self = nil); }
    
    egwMatCopy44f([(egwDirectionalLight*)asset wcsTransform], &_wcsTrans);
    egwMatCopy44f([(egwDirectionalLight*)asset lcsTransform], &_lcsTrans);
    egwVecCopy4f([(egwDirectionalLight*)asset illuminationDirection], &_wcsDir);
    if([(id<egwPOrientated>)asset offsetDriver] && ![self trySetOffsetDriver:[(id<egwPOrientated>)asset offsetDriver]]) { [self release]; return (self = nil); }
    if([(id<egwPOrientated>)asset orientateDriver] && ![self trySetOrientateDriver:[(id<egwPOrientated>)asset orientateDriver]]) { [self release]; return (self = nil); }
    
    _lMat = [_base illuminationMaterial];
    _lAtten = [_base illuminationAttenuation];
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwDirectionalLight* copy = nil;
    NSString* copyIdent = nil;
    
    if([_ident hasSuffix:@"_default"])
        copyIdent = [[NSString alloc] initWithFormat:@"%@_%d", [_base identity], [_base nextInstanceIndex]];
    else copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwDirectionalLight allocWithZone:zone] initCopyOf:self
                                                        withIdentity:copyIdent])) {
        NSLog(@"egwDirectionalLight: copyWithZone: Failure initializing new light from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    return copy;
}

- (void)dealloc {
    if(_isIBound) [self unbindIlluminationWithFlags:EGW_BNDOBJ_BINDFLG_DFLT];
    
    if(_lcsIpo) { [_lcsIpo removeTargetWithObject:self]; [_lcsIpo release]; _lcsIpo = nil; }
    if(_wcsIpo) { [_wcsIpo removeTargetWithObject:self]; [_wcsIpo release]; _wcsIpo = nil; }
    
    [_iSync release]; _iSync = nil;
    
    _lMat = NULL;
    _lAtten = NULL;
    
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
        if(!(_iFlags & EGW_OBJEXTEND_FLG_ALWAYSOTGHMG))
            egwMatMultiply44f(&_wcsTrans, &_lcsTrans, &twcsTrans);
        else
            egwMatMultiplyHmg44f(&_wcsTrans, &_lcsTrans, &twcsTrans);
        
        egwVecTransform444f(&twcsTrans, [_base illuminationDirection], &_wcsDir);
        // TODO: Need to modify attenuation to do MCS->WCS transform -jw
        
        _ortPending = NO;
        
        if((EGW_NODECMPMRG_LIGHT & (EGW_CORECMP_TYPE_BVOLS | EGW_CORECMP_TYPE_FRAMES | EGW_CORECMP_TYPE_SOURCES | EGW_CORECMP_TYPE_SYNCS)) &&
           _parent && ![_parent isInvokingChild]) {
            EGWuint cmpntTypes = (_iFlags & EGW_OBJTREE_FLG_NOUMRGBVOLS ? 0 : EGW_CORECMP_TYPE_BVOLS & EGW_NODECMPMRG_LIGHT) |
                                 (_iFlags & EGW_OBJTREE_FLG_NOUMRGFRAMES ? 0 : EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_LIGHT) |
                                 (_iFlags & EGW_OBJTREE_FLG_NOUMRGSYNCS ? 0 : EGW_CORECMP_TYPE_SOURCES & EGW_NODECMPMRG_LIGHT) |
                                 (_iFlags & EGW_OBJTREE_FLG_NOUMRGSOURCES ? 0 : EGW_CORECMP_TYPE_SYNCS & EGW_NODECMPMRG_LIGHT);
            if(cmpntTypes)
                [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        }
        
        _invkParent = NO;
    }
}

- (void)startIlluminating {
    if(!_isIlluminating) {
        @synchronized(self) {
            if(!_isIlluminating) {
                // TODO: Add into world scene.
                
                _isIlluminating = YES;
            }
        }
    }
}

- (void)stopIlluminating {
    if(_isIlluminating) {
        @synchronized(self) {
            if(_isIlluminating) {
                // TODO: Add into world scene.
                
                _isIlluminating = NO;
            }
        }
    }
}

- (BOOL)bindForIlluminationStage:(EGWuint)illumStage withFlags:(EGWuint)flags {
    if(_ortPending) [self applyOrientation];
    
    // NOTE: The code below is non-abstracted OpenGLES dependent. Staying this way till ES2. -jw
    if(!_isIBound || (flags & EGW_BNDOBJ_BINDFLG_APISYNCINVLD) || egwSFPVldtrIsInvalidated(_iSync, @selector(isInvalidated))) {
        GLenum light = GL_LIGHT0 + (_lastIBind = illumStage);
        
        if(flags & EGW_BNDOBJ_BINDFLG_TOGGLE)
            glEnable(light);
        
        if(!(flags & EGW_BNDOBJ_BINDFLG_SAMELASTBASE)) {
            glLightfv(light, GL_AMBIENT, (const GLfloat*)&_lMat->ambient);
            glLightfv(light, GL_DIFFUSE, (const GLfloat*)&_lMat->diffuse);
            glLightfv(light, GL_SPECULAR, (const GLfloat*)&_lMat->specular);
            glLightfv(light, GL_EMISSION, (const GLfloat*)&_lMat->emmisive);
            
            glLightf(light, GL_CONSTANT_ATTENUATION, (GLfloat)_lAtten->constant);
            glLightf(light, GL_LINEAR_ATTENUATION, (GLfloat)_lAtten->linear);
            glLightf(light, GL_QUADRATIC_ATTENUATION, (GLfloat)_lAtten->quadratic);
            
            glLightf(light, GL_SPOT_CUTOFF, (GLfloat)180.0f);
            glLightf(light, GL_SPOT_EXPONENT, (GLfloat)0.0f);
        }
        
        //if(!_isIBound || (flags & EGW_BNDOBJ_BINDFLG_APISYNCINVLD) || egwSFPVldtrIsInvalidated(_iSync, @selector(isInvalidated)))
            glLightfv(light, GL_POSITION, (const GLfloat*)&_wcsDir);
        
        _isIBound = YES;
        egwSFPVldtrValidate(_iSync, @selector(validate));
        return YES;
    }
    
    return NO;
}

- (BOOL)unbindIlluminationWithFlags:(EGWuint)flags {
    // NOTE: The code below is non-abstracted OpenGLES dependent. Staying this way till ES2. -jw
    if(_isIBound) {
        if(flags & EGW_BNDOBJ_BINDFLG_TOGGLE)
            glDisable(GL_LIGHT0 + _lastIBind);
        
        _isIBound = NO;
        return YES;
    }
    
    return NO;
}

- (void)offsetByTransform:(const egwMatrix44f*)lcsTransform {
    egwMatCopy44f(lcsTransform, &_lcsTrans);
    
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_iSync, @selector(invalidate));
}

- (void)orientateByTransform:(const egwMatrix44f*)wcsTransform {
    egwMatCopy44f(wcsTransform, &_wcsTrans);
    
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_iSync, @selector(invalidate));
}

- (void)orientateByImpending {
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_iSync, @selector(invalidate));
}

- (id<egwPAssetBase>)assetBase {
    return _base;
}

- (EGWuint)coreObjectTypes {
    return (EGW_COREOBJ_TYPE_LIGHT | EGW_COREOBJ_TYPE_ORIENTABLE);
}

- (NSString*)identity {
    return _ident;
}

- (const egwAttenuation3f*)illuminationAttenuation {
    return _lAtten;
}

- (id<egwPBounding>)illuminationBounding {
    return [_base illuminationBounding];
}

- (id<NSObject>)lightBase {
    return _base;
}

- (const egwVector4f*)illuminationDirection {
    return &_wcsDir;
}

- (EGWuint)illuminationFlags {
    return _iFlags;
}

- (const egwLightJumpTable*)lightJumpTable {
    return &_egwDLJT;
}

- (const egwMaterial4f*)illuminationMaterial {
    return _lMat;
}

- (const egwVector4f*)illuminationSource {
    return &egwSIVecZero4f;
}

- (egwValidater*)illuminationSync {
    return _iSync;
}

- (EGWuint)lastIlluminationBindingStage {
    return _lastIBind;
}

- (const egwMatrix44f*)lcsTransform {
    return &_lcsTrans;
}

- (const egwMatrix44f*)wcsTransform {
    return &_wcsTrans;
}

- (id<egwPInterpolator>)offsetDriver {
    return _lcsIpo;
}

- (id<egwPInterpolator>)orientateDriver {
    return _wcsIpo;
}

- (id<egwPObjectBranch>)parent {
    return _parent;
}

- (id<egwPObjectBranch>)root {
    return (_parent ? [_parent root] : nil);
}

- (void)setIlluminationFlags:(EGWuint)flags {
    _iFlags = flags;
        
    if((EGW_NODECMPMRG_LIGHT & EGW_CORECMP_TYPE_FLAGS) &&
       _parent && !_invkParent &&![_parent isInvokingChild]) {
        _invkParent = YES;
        EGWuint cmpntTypes = (_iFlags & EGW_OBJTREE_FLG_NOUMRGFLAGS ? 0 : EGW_CORECMP_TYPE_FLAGS & EGW_NODECMPMRG_LIGHT);
        if(cmpntTypes)
            [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        _invkParent = NO;
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
            NSLog(@"egwDirectionalLight: setParent: Warning: Object system is overriding WCS interpolator driver for instance asset '%@' (%p).", _ident, self);
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

- (BOOL)isIlluminating {
    return _isIlluminating;
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

- (BOOL)isBoundForIllumination {
    return _isIBound;
}

- (void)validaterDidValidate:(egwValidater*)validater {
    if(_ortPending) [self applyOrientation];
    
    if((EGW_NODECMPMRG_LIGHT & EGW_CORECMP_TYPE_SYNCS) && _parent && !_invkParent && ![_parent isInvokingChild]) {
        _invkParent = YES;
        [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_CORECMP_TYPE_SYNCS withObject:(id)[validater coreObjects] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        _invkParent = NO;
    }
}

- (void)validaterDidInvalidate:(egwValidater*)validater {
    if((EGW_NODECMPMRG_LIGHT & EGW_CORECMP_TYPE_SYNCS) && _parent && !_invkParent && ![_parent isInvokingChild]) {
        _invkParent = YES;
        [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_CORECMP_TYPE_SYNCS withObject:(id)[validater coreObjects] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        _invkParent = NO;
    }
}

@end


// !!!: ***** egwSpotLight *****

@implementation egwSpotLight

static egwLightJumpTable _egwSLJT = { NULL };

+ (id)allocWithZone:(NSZone*)zone {
    NSObject* inst = (NSObject*)[super allocWithZone:zone];
    
    if(!_egwSLJT.fpRetain && [inst isMemberOfClass:[egwSpotLight class]]) {
        _egwSLJT.fpRetain = (id(*)(id, SEL))[inst methodForSelector:@selector(retain)];
        _egwSLJT.fpRelease = (void(*)(id, SEL))[inst methodForSelector:@selector(release)];
        _egwSLJT.fpIBind = (BOOL(*)(id, SEL, EGWuint, EGWuint))[inst methodForSelector:@selector(bindForIlluminationStage:withFlags:)];
        _egwSLJT.fpIUnbind = (BOOL(*)(id, SEL, EGWuint))[inst methodForSelector:@selector(unbindIlluminationWithFlags:)];
        _egwSLJT.fpLBase = (id<NSObject>(*)(id, SEL))[inst methodForSelector:@selector(lightBase)];
        _egwPLJT.fpIBounding = (id<egwPBounding>(*)(id, SEL))[inst methodForSelector:@selector(illuminationBounding)];
        _egwSLJT.fpIFlags = (EGWuint(*)(id, SEL))[inst methodForSelector:@selector(illuminationFlags)];
        _egwSLJT.fpISync = (egwValidater*(*)(id, SEL))[inst methodForSelector:@selector(illuminationSync)];
        _egwSLJT.fpILBStage = (EGWuint(*)(id, SEL))[inst methodForSelector:@selector(lastIlluminationBindingStage)];
    }
    
    return (id)inst;
}

- (id)init {
    if([self isMemberOfClass:[egwSpotLight class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent lightDirection:(egwVector3f*)illumDir lightAngle:(EGWsingle)illumAngle lightExponent:(EGWsingle)illumExp lightMaterial:(egwMaterial4f*)illumMat lightAttenuation:(egwAttenuation3f*)illumAtten {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    _lastIBind = NSNotFound;
    
    // TODO: Need to replace the illumination volume with a conic -jw
    if(!(_base = [[egwLightBase alloc] initWithIdentity:assetIdent lightDirection:NULL lightVolume:[[egwInfiniteBounding alloc] initWithBoundingOrigin:&egwSIVecZero3f] lightMaterial:illumMat lightAttenuation:illumAtten])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _iFlags = EGW_LGTOBJ_ILLMFLG_DFLT;
    if(!(_iSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_LIGHT])) { [self release]; return (self = nil); }
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    egwVecCopy4f([_base illuminationDirection], &_wcsDir);
    
    _lMat = [_base illuminationMaterial];
    _lAtten = [_base illuminationAttenuation];
    _lAngle = egwClampf(illumAngle, 0.0f, 90.0f);
    _lExponent = egwClamp01f(illumExp);
    
    return self;
}

- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent {
    if(!([asset isKindOfClass:[self class]]) || !(self = [super init])) { [self release]; return (self = nil); }
    
    _lastIBind = NSNotFound;
    
    if(!(_base = (egwLightBase*)[[asset assetBase] retain])) { [self release]; return (self = nil); }
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _iFlags = [(egwSpotLight*)asset illuminationFlags];
    if(!(_iSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_LIGHT])) { [self release]; return (self = nil); }
    
    egwMatCopy44f([(egwSpotLight*)asset wcsTransform], &_wcsTrans);
    egwMatCopy44f([(egwSpotLight*)asset lcsTransform], &_lcsTrans);
    egwVecCopy4f([(egwSpotLight*)asset illuminationDirection], &_wcsDir);
    if(!(_wcsIBVol = [(NSObject*)[(egwSpotLight*)asset illuminationBounding] copy])) { [self release]; return (self = nil); }
    if([(id<egwPOrientated>)asset offsetDriver] && ![self trySetOffsetDriver:[(id<egwPOrientated>)asset offsetDriver]]) { [self release]; return (self = nil); }
    if([(id<egwPOrientated>)asset orientateDriver] && ![self trySetOrientateDriver:[(id<egwPOrientated>)asset orientateDriver]]) { [self release]; return (self = nil); }
    
    _lMat = [_base illuminationMaterial];
    _lAtten = [_base illuminationAttenuation];
    _lAngle = egwClampf([(egwSpotLight*)asset illuminationAngle], 0.0f, 90.0f);
    _lExponent = egwClamp01f([(egwSpotLight*)asset illuminationExponent]);
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwSpotLight* copy = nil;
    NSString* copyIdent = nil;
    
    if([_ident hasSuffix:@"_default"])
        copyIdent = [[NSString alloc] initWithFormat:@"%@_%d", [_base identity], [_base nextInstanceIndex]];
    else copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwSpotLight allocWithZone:zone] initCopyOf:self
                                                 withIdentity:copyIdent])) {
        NSLog(@"egwSpotLight: copyWithZone: Failure initializing new light from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    return copy;
}

- (void)dealloc {
    if(_isIBound) [self unbindIlluminationWithFlags:EGW_BNDOBJ_BINDFLG_DFLT];
    
    [_iSync release]; _iSync = nil;
    [_wcsIBVol release]; _wcsIBVol = nil;
    
    if(_lcsIpo) { [_lcsIpo removeTargetWithObject:self]; [_lcsIpo release]; _lcsIpo = nil; }
    if(_wcsIpo) { [_wcsIpo removeTargetWithObject:self]; [_wcsIpo release]; _wcsIpo = nil; }
    
    _lMat = NULL;
    _lAtten = NULL;
    
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
        if(!(_iFlags & EGW_OBJEXTEND_FLG_ALWAYSOTGHMG))
            egwMatMultiply44f(&_wcsTrans, &_lcsTrans, &twcsTrans);
        else
            egwMatMultiplyHmg44f(&_wcsTrans, &_lcsTrans, &twcsTrans);
        
        egwVecTransform444f(&twcsTrans, [_base illuminationDirection], &_wcsDir);
        [_wcsIBVol orientateByTransform:&twcsTrans fromVolume:[_base illuminationBounding]];
        // TODO: Need to modify attenuation to do MCS->WCS transform -jw
        
        _ortPending = NO;
        
        if((EGW_NODECMPMRG_LIGHT & (EGW_CORECMP_TYPE_BVOLS | EGW_CORECMP_TYPE_FRAMES | EGW_CORECMP_TYPE_SOURCES | EGW_CORECMP_TYPE_SYNCS)) &&
           _parent && ![_parent isInvokingChild]) {
            EGWuint cmpntTypes = (((_iFlags & EGW_OBJTREE_FLG_NOUMRGBVOLS) || [_wcsIBVol class] == [egwZeroBounding class]) ? 0 : EGW_CORECMP_TYPE_BVOLS & EGW_NODECMPMRG_LIGHT) |
                                   (_iFlags & EGW_OBJTREE_FLG_NOUMRGFRAMES ? 0 : EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_LIGHT) |
                                   (_iFlags & EGW_OBJTREE_FLG_NOUMRGSYNCS ? 0 : EGW_CORECMP_TYPE_SOURCES & EGW_NODECMPMRG_LIGHT) |
                                   (_iFlags & EGW_OBJTREE_FLG_NOUMRGSOURCES ? 0 : EGW_CORECMP_TYPE_SYNCS & EGW_NODECMPMRG_LIGHT);
            if(cmpntTypes)
                [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        }
        
        _invkParent = NO;
    }
}

- (void)startIlluminating {
    if(!_isIlluminating) {
        @synchronized(self) {
            if(!_isIlluminating) {
                // TODO: Add into world scene.
                
                _isIlluminating = YES;
            }
        }
    }
}

- (void)stopIlluminating {
    if(_isIlluminating) {
        @synchronized(self) {
            if(_isIlluminating) {
                // TODO: Add into world scene.
                
                _isIlluminating = NO;
            }
        }
    }
}

- (BOOL)bindForIlluminationStage:(EGWuint)illumStage withFlags:(EGWuint)flags {
    if(_ortPending) [self applyOrientation];
    
    // NOTE: The code below is non-abstracted OpenGLES dependent. Staying this way till ES2. -jw
    if(!_isIBound || (flags & EGW_BNDOBJ_BINDFLG_APISYNCINVLD) || egwSFPVldtrIsInvalidated(_iSync, @selector(isInvalidated))) {
        GLenum light = GL_LIGHT0 + (_lastIBind = illumStage);
        
        if(flags & EGW_BNDOBJ_BINDFLG_TOGGLE)
            glEnable(light);
        
        if(!(flags & EGW_BNDOBJ_BINDFLG_SAMELASTBASE)) {
            glLightfv(light, GL_AMBIENT, (const GLfloat*)&_lMat->ambient);
            glLightfv(light, GL_DIFFUSE, (const GLfloat*)&_lMat->diffuse);
            glLightfv(light, GL_SPECULAR, (const GLfloat*)&_lMat->specular);
            glLightfv(light, GL_EMISSION, (const GLfloat*)&_lMat->emmisive);
            
            glLightf(light, GL_CONSTANT_ATTENUATION, (GLfloat)_lAtten->constant);
            glLightf(light, GL_LINEAR_ATTENUATION, (GLfloat)_lAtten->linear);
            glLightf(light, GL_QUADRATIC_ATTENUATION, (GLfloat)_lAtten->quadratic);
            
            glLightf(light, GL_SPOT_CUTOFF, (GLfloat)_lAngle);
            glLightf(light, GL_SPOT_EXPONENT, (GLfloat)(_lExponent * 128.0f));
        }
        
        //if(!_isIBound || (flags & EGW_BNDOBJ_BINDFLG_APISYNCINVLD) || egwSFPVldtrIsInvalidated(_iSync, @selector(isInvalidated))) {
            glLightfv(light, GL_POSITION, (const GLfloat*)&(_wcsTrans.column[3]));
            glLightfv(light, GL_SPOT_DIRECTION, (const GLfloat*)&_wcsDir);
        //}
        
        _isIBound = YES;
        egwSFPVldtrValidate(_iSync, @selector(validate));
        return YES;
    }
    
    return NO;
}

- (BOOL)unbindIlluminationWithFlags:(EGWuint)flags {
    // NOTE: The code below is non-abstracted OpenGLES dependent. Staying this way till ES2. -jw
    if(_isIBound) {
        if(flags & EGW_BNDOBJ_BINDFLG_TOGGLE)
            glDisable(GL_LIGHT0 + _lastIBind);
        
        _isIBound = NO;
        return YES;
    }
    
    return NO;
}

- (void)offsetByTransform:(const egwMatrix44f*)lcsTransform {
    egwMatCopy44f(lcsTransform, &_lcsTrans);
    
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_iSync, @selector(invalidate));
}

- (void)orientateByTransform:(const egwMatrix44f*)wcsTransform {
    egwMatCopy44f(wcsTransform, &_wcsTrans);
    
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_iSync, @selector(invalidate));
}

- (void)orientateByImpending {
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_iSync, @selector(invalidate));
}

- (id<egwPAssetBase>)assetBase {
    return _base;
}

- (EGWuint)coreObjectTypes {
    return (EGW_COREOBJ_TYPE_LIGHT | EGW_COREOBJ_TYPE_ORIENTABLE);
}

- (NSString*)identity {
    return _ident;
}

- (EGWsingle)illuminationAngle {
    return _lAngle;
}

- (const egwAttenuation3f*)illuminationAttenuation {
    return _lAtten;
}

- (id<NSObject>)lightBase {
    return _base;
}

- (id<egwPBounding>)illuminationBounding {
    return _wcsIBVol;
}

- (const egwVector4f*)illuminationDirection {
    return &_wcsDir;
}

- (EGWuint)illuminationFlags {
    return _iFlags;
}

- (EGWsingle)illuminationExponent {
    return _lExponent;
}

- (const egwLightJumpTable*)lightJumpTable {
    return &_egwSLJT;
}

- (const egwMaterial4f*)illuminationMaterial {
    return _lMat;
}

- (const egwVector4f*)illuminationSource {
    return (const egwVector4f*)&(_wcsTrans.column[3]);
}

- (egwValidater*)illuminationSync {
    return _iSync;
}

- (EGWuint)lastIlluminationBindingStage {
    return _lastIBind;
}

- (const egwMatrix44f*)lcsTransform {
    return &_lcsTrans;
}

- (const egwMatrix44f*)wcsTransform {
    return &_wcsTrans;
}

- (id<egwPInterpolator>)offsetDriver {
    return _lcsIpo;
}

- (id<egwPInterpolator>)orientateDriver {
    return _wcsIpo;
}

- (id<egwPObjectBranch>)parent {
    return _parent;
}

- (id<egwPObjectBranch>)root {
    return (_parent ? [_parent root] : nil);
}

- (void)setIlluminationFlags:(EGWuint)flags {
    _iFlags = flags;
        
    if((EGW_NODECMPMRG_LIGHT & EGW_CORECMP_TYPE_FLAGS) &&
       _parent && !_invkParent && ![_parent isInvokingChild]) {
        _invkParent = YES;
        EGWuint cmpntTypes = (_iFlags & EGW_OBJTREE_FLG_NOUMRGFLAGS ? 0 : EGW_CORECMP_TYPE_FLAGS & EGW_NODECMPMRG_LIGHT);
        if(cmpntTypes)
            [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        _invkParent = NO;
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
            NSLog(@"egwSpotLight: setParent: Warning: Object system is overriding WCS interpolator driver for instance asset '%@' (%p).", _ident, self);
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

- (BOOL)isIlluminating {
    return _isIlluminating;
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

- (BOOL)isBoundForIllumination {
    return _isIBound;
}

- (void)validaterDidValidate:(egwValidater*)validater {
    if(_ortPending) [self applyOrientation];
    
    if(_iSync == validater &&
       (EGW_NODECMPMRG_LIGHT & EGW_CORECMP_TYPE_SYNCS) &&
       _parent && !_invkParent && ![_parent isInvokingChild]) {
        _invkParent = YES;
        EGWuint cmpntTypes = (_iFlags & EGW_OBJTREE_FLG_NOUMRGSYNCS ? 0 : EGW_OBJTREE_FLG_NOUMRGSYNCS & EGW_NODECMPMRG_LIGHT);
        if(cmpntTypes)
            [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[validater coreObjects] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        _invkParent = NO;
    }
}

- (void)validaterDidInvalidate:(egwValidater*)validater {
    if(_iSync == validater &&
       (EGW_NODECMPMRG_LIGHT & EGW_CORECMP_TYPE_SYNCS) &&
       _parent && !_invkParent && ![_parent isInvokingChild]) {
        _invkParent = YES;
        EGWuint cmpntTypes = (_iFlags & EGW_OBJTREE_FLG_NOUMRGSYNCS ? 0 : EGW_OBJTREE_FLG_NOUMRGSYNCS & EGW_NODECMPMRG_LIGHT);
        if(cmpntTypes)
            [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[validater coreObjects] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
        _invkParent = NO;
    }
}

@end


// !!!: ***** egwLightBase *****

@implementation egwLightBase

+ (id)allocWithZone:(NSZone*)zone {
    id alloc = [super allocWithZone:zone];
    if(alloc) [egwAssetManager incBaseRef];
    if(EGW_ENGINE_ASSETS_CREATIONMSGS) NSLog(@"egwLightBase: allocWithZone: Creating new light base asset (%p).", alloc);
    return alloc;
}

- (id)init {
    if([self isMemberOfClass:[egwLightBase class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent lightDirection:(egwVector3f*)illumDir lightVolume:(id<egwPBounding>)illumVol lightMaterial:(egwMaterial4f*)illumMat lightAttenuation:(egwAttenuation3f*)illumAtten {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    if(illumDir) { egwVecCopy3f(illumDir, (egwVector3f*)&_mmcsDir); _mmcsDir.axis.w = 0.0f; }
    else egwVecCopy4f(&egwSIVecNegUnitZ4f, &_mmcsDir);
    
    if(!(_mmcsIBVol = [illumVol retain])) { [self release]; return (self = nil); }
    
    if(illumMat) egwMtrlClamp4f(illumMat, &_lMat);
    else memcpy((void*)&_lMat, (const void*)&egwSIMtrlDefault4f, sizeof(egwMaterial4f));
    
    if(illumAtten) memcpy((void*)&_lAtten, (const void*)illumAtten, sizeof(egwAttenuation3f));
    else memcpy((void*)&_lAtten, (const void*)&egwSIAttnDefault3f, sizeof(egwAttenuation3f));
    
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
    
    [_mmcsIBVol release]; _mmcsIBVol = nil;
    
    if(EGW_ENGINE_ASSETS_DESTROYMSGS) NSLog(@"egwLightBase: dealloc: Destroying light base asset '%@' (%p).", _ident, self);
    [_ident release]; _ident = nil;
    [egwAssetManager decBaseRef];
    [super dealloc];
}

- (void)baseOffsetByTransform:(const egwMatrix44f*)transform {
    [_mmcsIBVol baseOffsetByTransform:transform];
    egwVecTransform444f(transform, &_mmcsDir, &_mmcsDir);
}

- (NSString*)identity {
    return _ident;
}

- (const egwAttenuation3f*)illuminationAttenuation {
    return &_lAtten;
}

- (id<egwPBounding>)illuminationBounding {
    return _mmcsIBVol;
}

- (const egwVector4f*)illuminationDirection {
    return &_mmcsDir;
}

- (const egwMaterial4f*)illuminationMaterial {
    return &_lMat;
}

- (EGWuint)nextInstanceIndex {
    return ++_instCounter;
}

@end

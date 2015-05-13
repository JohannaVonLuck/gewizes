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

/// @file egwMaterials.m
/// @ingroup geWizES_gfx_materials
/// Material Assets Implementations.

#import "egwMaterials.h"
#import "../sys/egwSysTypes.h"
#import "../sys/egwAssetManager.h"
#import "../sys/egwGfxContext.h"
#import "../sys/egwGfxContextNSGL.h"  // NOTE: Below code has a dependence on GL.
#import "../sys/egwGfxContextEAGLES.h"
#import "../math/egwMath.h"
#import "../math/egwVector.h"
#import "../gfx/egwGraphics.h"
#import "../phy/egwInterpolators.h"
#import "../misc/egwValidater.h"


// !!!: ***** egwMaterial *****

@implementation egwMaterial

static egwMaterialJumpTable _egwMMJT = { NULL };

+ (id)allocWithZone:(NSZone*)zone {
    NSObject* inst = (NSObject*)[super allocWithZone:zone];
    
    if(!_egwMMJT.fpSBind && [inst isMemberOfClass:[egwMaterial class]]) {
        _egwMMJT.fpSBind = (BOOL(*)(id, SEL, EGWuint, EGWuint))[inst methodForSelector:@selector(bindForSurfacingStage:withFlags:)];
        _egwMMJT.fpSUnbind = (BOOL(*)(id, SEL, EGWuint))[inst methodForSelector:@selector(unbindSurfacingWithFlags:)];
        _egwMMJT.fpMBase = (id<NSObject>(*)(id, SEL))[inst methodForSelector:@selector(materialBase)];
        _egwMMJT.fpSSync = (egwValidater*(*)(id, SEL))[inst methodForSelector:@selector(surfacingSync)];
        _egwMMJT.fpSLBStage = (EGWuint(*)(id, SEL))[inst methodForSelector:@selector(lastSurfacingBindingStage)];
    }
    
    return (id)inst;
}

- (id)init {
    if([self isMemberOfClass:[egwMaterial class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent surfacingMaterial:(egwMaterial4f*)srfcgMat {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _lastSBind = NSNotFound;
    if(!(_sSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_MATERIAL])) { [self release]; return (self = nil); }
    
    if(srfcgMat) egwMtrlClamp4f(srfcgMat, &_sMat);
    else memcpy((void*)&_sMat, (const void*)&egwSIMtrlDefault4f, sizeof(egwMaterial4f));
    
    return self;
}

- (id)initWithIdentity:(NSString*)assetIdent ambientColor:(const egwColor4f*)ambColor diffuseColor:(const egwColor4f*)dfsColor specularColor:(const egwColor4f*)spcColor emmisiveColor:(const egwColor4f*)emsColor shininessExponent:(const EGWsingle)shineExp {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _lastSBind = NSNotFound;
    if(!(_sSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_MATERIAL])) { [self release]; return (self = nil); }
    
    if(ambColor) egwClrClamp4f(ambColor, &_sMat.ambient);
    else memcpy((void*)&_sMat.ambient, (const void*)&egwSIMtrlDefault4f.ambient, sizeof(egwColor4f));
    
    if(dfsColor) egwClrClamp4f(dfsColor, &_sMat.diffuse);
    else memcpy((void*)&_sMat.diffuse, (const void*)&egwSIMtrlDefault4f.diffuse, sizeof(egwColor4f));
    
    if(spcColor) egwClrClamp4f(spcColor, &_sMat.specular);
    else memcpy((void*)&_sMat.specular, (const void*)&egwSIMtrlDefault4f.specular, sizeof(egwColor4f));
    
    if(emsColor) egwClrClamp4f(emsColor, &_sMat.emmisive);
    else memcpy((void*)&_sMat.emmisive, (const void*)&egwSIMtrlDefault4f.emmisive, sizeof(egwColor4f));
    
    _sMat.shininess = egwClamp01f(shineExp);
    
    return self;
}

- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent {
    if(!([asset isKindOfClass:[self class]]) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _lastSBind = NSNotFound;
    if(!(_sSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_MATERIAL])) { [self release]; return (self = nil); }
    if([(egwMaterial*)asset materialDriver] && ![self trySetMaterialDriver:[(egwMaterial*)asset materialDriver]]) { [self release]; return (self = nil); }
    
    memcpy((void*)&_sMat, (const void*)[(egwMaterial*)asset material], sizeof(egwMaterial4f));
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwMaterial* copy = nil;
    NSString* copyIdent = nil;
    
    copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwMaterial allocWithZone:zone] initCopyOf:self
                                                withIdentity:copyIdent])) {
        NSLog(@"egwMaterial: copyWithZone: Failure initializing new material from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    return copy;
}

- (void)dealloc {
    [_sSync release]; _sSync = nil;
    if(_mdIpo) { [_mdIpo removeTargetWithObject:self]; [_mdIpo release]; _mdIpo = nil; }
    
    [super dealloc];
}

- (BOOL)bindForSurfacingStage:(EGWuint)srfcgStage withFlags:(EGWuint)flags {
    // NOTE: The code below is non-abstracted OpenGLES dependent. Staying this way till ES2. -jw
    if(!_isSBound || (flags & EGW_BNDOBJ_BINDFLG_APISYNCINVLD) || egwSFPVldtrIsInvalidated(_sSync, @selector(isInvalidated))) {
        _lastSBind = srfcgStage;
        // no material stage enable/disable
        
        //if(!_isSBound || (flags & EGW_BNDOBJ_BINDFLG_APISYNCINVLD) || egwSFPVldtrIsInvalidated(_sSync, @selector(isInvalidated))) {
            glColor4f((GLfloat)_sMat.diffuse.channel.r, (GLfloat)_sMat.diffuse.channel.g, (GLfloat)_sMat.diffuse.channel.b, (GLfloat)_sMat.diffuse.channel.a);
            glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, (const GLfloat*)&(_sMat.ambient));
            glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, (const GLfloat*)&(_sMat.diffuse));
            glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, (const GLfloat*)&(_sMat.specular));
            glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, (const GLfloat*)&(_sMat.emmisive));
            glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, (GLfloat)(_sMat.shininess * 128.0f));
        //}
        
        _isSBound = YES;
        egwSFPVldtrValidate(_sSync, @selector(validate));
        return YES;
    }
    
    return NO;
}

- (BOOL)unbindSurfacingWithFlags:(EGWuint)flags {
    // NOTE: The code below is non-abstracted OpenGLES dependent. Staying this way till ES2. -jw
    if(_isSBound) {
        _isSBound = NO;
        return YES;
    }
    
    return NO;
}

- (id<egwPAssetBase>)assetBase {
    return nil;
}

- (EGWuint)coreObjectTypes {
    return EGW_COREOBJ_TYPE_MATERIAL;
}

- (NSString*)identity {
    return _ident;
}

- (EGWuint)lastSurfacingBindingStage {
    return _lastSBind;
}

- (egwMaterial4f*)material {
    return &_sMat;
}

- (id<NSObject>)materialBase {
    return self;
}

- (id<egwPInterpolator>)materialDriver {
    return _mdIpo;
}

- (const egwMaterialJumpTable*)materialJumpTable {
    return &_egwMMJT;
}

- (egwValidater*)surfacingSync {
    return _sSync;
}

- (void)getSurfacingMaterial:(egwMaterial4f*)srfcgMat {
    memcpy((void*)srfcgMat, (const void*)&_sMat, sizeof(egwMaterial4f));
}

- (void)setMaterial:(egwMaterial4f*)srfcgMat {
    if(srfcgMat) egwMtrlClamp4f(srfcgMat, &_sMat);
    else memcpy((void*)&_sMat, (const void*)&egwSIMtrlDefault4f, sizeof(egwMaterial4f));
    
    egwSFPVldtrInvalidate(_sSync, @selector(invalidate));
}

- (void)setMaterialAmbientColor:(const egwColor4f*)ambColor {
    if(ambColor) egwClrClamp4f(ambColor, &_sMat.ambient);
    else memcpy((void*)&_sMat.ambient, (const void*)&egwSIMtrlDefault4f.ambient, sizeof(egwColor4f));
    
    egwSFPVldtrInvalidate(_sSync, @selector(invalidate));
}

- (void)setMaterialDiffuseColor:(const egwColor4f*)dfsColor {
    if(dfsColor) egwClrClamp4f(dfsColor, &_sMat.diffuse);
    else memcpy((void*)&_sMat.diffuse, (const void*)&egwSIMtrlDefault4f.diffuse, sizeof(egwColor4f));
    
    egwSFPVldtrInvalidate(_sSync, @selector(invalidate));
}

- (void)setMaterialSpecularColor:(const egwColor4f*)spcColor {
    if(spcColor) egwClrClamp4f(spcColor, &_sMat.specular);
    else memcpy((void*)&_sMat.specular, (const void*)&egwSIMtrlDefault4f.specular, sizeof(egwColor4f));
    
    egwSFPVldtrInvalidate(_sSync, @selector(invalidate));
}

- (void)setMaterialEmmisiveColor:(const egwColor4f*)emsColor {
    if(emsColor) egwClrClamp4f(emsColor, &_sMat.emmisive);
    else memcpy((void*)&_sMat.emmisive, (const void*)&egwSIMtrlDefault4f.emmisive, sizeof(egwColor4f));
    
    egwSFPVldtrInvalidate(_sSync, @selector(invalidate));
}

- (void)setMaterialShininessExponent:(const egwColor1f*)shineExp {
    if(shineExp) _sMat.shininess = egwClamp01f(shineExp->channel.l);
    else _sMat.shininess = 0.0f;
    
    egwSFPVldtrInvalidate(_sSync, @selector(invalidate));
}

- (BOOL)trySetMaterialDriver:(id<egwPInterpolator>)matIpo {
    if(matIpo) {
        if([matIpo isKindOfClass:[egwValueInterpolator class]] && [(egwValueInterpolator*)matIpo channelCount] == 17 && [(egwValueInterpolator*)matIpo channelFormat] == EGW_KEYCHANNEL_FRMT_SINGLE) {
            [_mdIpo removeTargetWithObject:self];
            [matIpo retain];
            [_mdIpo release];
            _mdIpo = matIpo;
            [_mdIpo addTargetWithObject:self method:@selector(setMaterial:)];
            
            return YES;
        }
    } else {
        [_mdIpo removeTargetWithObject:self];
        [_mdIpo release]; _mdIpo = nil;
        
        return YES;
    }
    
    return NO;
}

- (BOOL)isBoundForSurfacing {
    return _isSBound;
}

- (BOOL)isOpaque {
    return [egwAIGfxCntx determineOpacity:_sMat.diffuse.channel.a];
}

- (void)validaterDidValidate:(egwValidater*)validater {
}

- (void)validaterDidInvalidate:(egwValidater*)validater {
}

@end


// !!!: ***** egwColor *****

@implementation egwColor

static egwMaterialJumpTable _egwCMJT = { NULL };

+ (id)allocWithZone:(NSZone*)zone {
    NSObject* inst = (NSObject*)[super allocWithZone:zone];
    
    if(!_egwCMJT.fpSBind && [inst isMemberOfClass:[egwColor class]]) {
        _egwCMJT.fpSBind = (BOOL(*)(id, SEL, EGWuint, EGWuint))[inst methodForSelector:@selector(bindForSurfacingStage:withFlags:)];
        _egwCMJT.fpSUnbind = (BOOL(*)(id, SEL, EGWuint))[inst methodForSelector:@selector(unbindSurfacingWithFlags:)];
        _egwCMJT.fpMBase = (id<NSObject>(*)(id, SEL))[inst methodForSelector:@selector(materialBase)];
        _egwCMJT.fpSSync = (egwValidater*(*)(id, SEL))[inst methodForSelector:@selector(surfacingSync)];
        _egwCMJT.fpSLBStage = (EGWuint(*)(id, SEL))[inst methodForSelector:@selector(lastSurfacingBindingStage)];
    }
    
    return (id)inst;
}

- (id)init {
    if([self isMemberOfClass:[egwColor class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent surfacingColor:(const egwColor4f*)srfcgColor {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _lastSBind = NSNotFound;
    if(!(_sSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_MATERIAL])) { [self release]; return (self = nil); }
    
    if(srfcgColor) egwClrClamp4f(srfcgColor, &_sColor);
    else memcpy((void*)&_sColor, (const void*)&egwSIMtrlDefault4f.diffuse, sizeof(egwColor4f));
    
    return self;
}

- (id)initWithIdentity:(NSString*)assetIdent rgbColor:(const egwColor3f*)rgb alphaColor:(const EGWsingle)alpha {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _lastSBind = NSNotFound;
    if(!(_sSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_MATERIAL])) { [self release]; return (self = nil); }
    
    if(rgb) egwClrClamp3f(rgb, (egwColor3f*)&_sColor);
    else memcpy((void*)&_sColor, (const void*)&egwSIMtrlDefault4f.diffuse, sizeof(egwColor3f));
    
    _sColor.channel.a = egwClamp01f(alpha);
    
    return self;
}

- (id)initWithIdentity:(NSString*)assetIdent redColor:(const EGWsingle)red greenColor:(const EGWsingle)green blueColor:(const EGWsingle)blue alphaColor:(const EGWsingle)alpha {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _lastSBind = NSNotFound;
    if(!(_sSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_MATERIAL])) { [self release]; return (self = nil); }
    
    _sColor.channel.r = egwClamp01f(red);
    _sColor.channel.g = egwClamp01f(green);
    _sColor.channel.b = egwClamp01f(blue);
    _sColor.channel.a = egwClamp01f(alpha);
    
    return self;
}

- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent {
    if(!([asset isKindOfClass:[self class]]) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _lastSBind = NSNotFound;
    if(!(_sSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_MATERIAL])) { [self release]; return (self = nil); }
    if([(egwColor*)asset coloringDriver] && ![self trySetColoringDriver:[(egwColor*)asset coloringDriver]]) { [self release]; return (self = nil); }
    
    memcpy((void*)&_sColor, (const void*)[(egwColor*)asset coloring], sizeof(egwColor4f));
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwColor* copy = nil;
    NSString* copyIdent = nil;
    
    copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwColor allocWithZone:zone] initCopyOf:self
                                             withIdentity:copyIdent])) {
        NSLog(@"egwColor: copyWithZone: Failure initializing new color from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    return copy;
}

- (void)dealloc {
    [_sSync release]; _sSync = nil;
    if(_cdIpo) { [_cdIpo removeTargetWithObject:self]; [_cdIpo release]; _cdIpo = nil; }
    
    [super dealloc];
}

- (BOOL)bindForSurfacingStage:(EGWuint)srfcgStage withFlags:(EGWuint)flags {
    // NOTE: The code below is non-abstracted OpenGLES dependent. Staying this way till ES2. -jw
    if(!_isSBound || (flags & EGW_BNDOBJ_BINDFLG_APISYNCINVLD) || egwSFPVldtrIsInvalidated(_sSync, @selector(isInvalidated))) {
        _lastSBind = srfcgStage;
        // no material stage enable/disable
        
        //if(!_isSBound || (flags & EGW_BNDOBJ_BINDFLG_APISYNCINVLD) || egwSFPVldtrIsInvalidated(_sSync, @selector(isInvalidated))) {
            glColor4f(_sColor.channel.r, _sColor.channel.g, _sColor.channel.b, _sColor.channel.a);
            glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, (const GLfloat*)&_sColor);
            glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, (const GLfloat*)&_sColor);
            glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, (const GLfloat*)&egwSIVecZero4f);
            glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, (const GLfloat*)&egwSIVecZero4f);
            glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, (GLfloat)0.0f);
        //}
        
        _isSBound = YES;
        egwSFPVldtrValidate(_sSync, @selector(validate));
        return YES;
    }
    
    return NO;
}

- (BOOL)unbindSurfacingWithFlags:(EGWuint)flags {
    // NOTE: The code below is non-abstracted OpenGLES dependent. Staying this way till ES2. -jw
    if(_isSBound) {
        _isSBound = NO;
        return YES;
    }
    
    return NO;
}

- (id<egwPAssetBase>)assetBase {
    return nil;
}

- (EGWuint)coreObjectTypes {
    return EGW_COREOBJ_TYPE_MATERIAL;
}

- (NSString*)identity {
    return _ident;
}

- (EGWuint)lastSurfacingBindingStage {
    return _lastSBind;
}

- (id<NSObject>)materialBase {
    return self;
}

- (const egwMaterialJumpTable*)materialJumpTable {
    return &_egwCMJT;
}

- (egwValidater*)surfacingSync {
    return _sSync;
}

- (const egwColor4f*)coloring {
    return &_sColor;
}

- (id<egwPInterpolator>)coloringDriver {
    return _cdIpo;
}

- (void)getSurfacingMaterial:(egwMaterial4f*)srfcgMat {
    memcpy((void*)&srfcgMat->ambient, (const void*)&_sColor, sizeof(egwColor4f));
    memcpy((void*)&srfcgMat->diffuse, (const void*)&_sColor, sizeof(egwColor4f));
    memcpy((void*)&srfcgMat->specular, (const void*)&egwSIVecZero4f, sizeof(egwColor4f));
    memcpy((void*)&srfcgMat->emmisive, (const void*)&egwSIVecZero4f, sizeof(egwColor4f));
    srfcgMat->shininess = 0.0f;
}

- (void)setColoring:(const egwColor4f*)srfcgColor {
    if(srfcgColor) egwClrClamp4f(srfcgColor, &_sColor);
    else memcpy((void*)&_sColor, (const void*)&egwSIMtrlDefault4f.diffuse, sizeof(egwColor4f));
    
    egwSFPVldtrInvalidate(_sSync, @selector(invalidate));
}

- (void)setColoringRGBColor:(const egwColor3f*)rgb {
    if(rgb) egwClrClamp3f(rgb, (egwColor3f*)&_sColor);
    else memcpy((void*)&_sColor, (const void*)&egwSIMtrlDefault4f.diffuse, sizeof(egwColor3f));
    
    egwSFPVldtrInvalidate(_sSync, @selector(invalidate));
}

- (void)setColoringRedColor:(const egwColor1f*)red {
    if(red) _sColor.channel.r = egwClamp01f(red->channel.l);
    else _sColor.channel.r = egwSIMtrlDefault4f.diffuse.channel.r;
    
    egwSFPVldtrInvalidate(_sSync, @selector(invalidate));
}

- (void)setColoringGreenColor:(const egwColor1f*)green {
    if(green) _sColor.channel.g = egwClamp01f(green->channel.l);
    else _sColor.channel.g = egwSIMtrlDefault4f.diffuse.channel.g;
    
    egwSFPVldtrInvalidate(_sSync, @selector(invalidate));
}

- (void)setColoringBlueColor:(const egwColor1f*)blue {
    if(blue) _sColor.channel.b = egwClamp01f(blue->channel.l);
    else _sColor.channel.b = egwSIMtrlDefault4f.diffuse.channel.b;
    
    egwSFPVldtrInvalidate(_sSync, @selector(invalidate));
}

- (void)setColoringAlphaColor:(const egwColor1f*)alpha {
    if(alpha) _sColor.channel.a = egwClamp01f(alpha->channel.l);
    else _sColor.channel.a = egwSIMtrlDefault4f.diffuse.channel.a;
    
    egwSFPVldtrInvalidate(_sSync, @selector(invalidate));
}

- (BOOL)trySetColoringDriver:(id<egwPInterpolator>)clrIpo {
    if(clrIpo) {
        if([clrIpo isKindOfClass:[egwValueInterpolator class]] && [(egwValueInterpolator*)clrIpo channelCount] == 4 && [(egwValueInterpolator*)clrIpo channelFormat] == EGW_KEYCHANNEL_FRMT_SINGLE) {
            [_cdIpo removeTargetWithObject:self];
            [clrIpo retain];
            [_cdIpo release];
            _cdIpo = clrIpo;
            [_cdIpo addTargetWithObject:self method:@selector(setColoring:)];
            
            return YES;
        }
    } else {
        [_cdIpo removeTargetWithObject:self];
        [_cdIpo release]; _cdIpo = nil;
        
        return YES;
    }
    
    return NO;
}

- (BOOL)isBoundForSurfacing {
    return _isSBound;
}

- (BOOL)isOpaque {
    return [egwAIGfxCntx determineOpacity:_sColor.channel.a];
}

- (void)validaterDidValidate:(egwValidater*)validater {
}

- (void)validaterDidInvalidate:(egwValidater*)validater {
}

@end



// !!!: ***** egwShade *****

@implementation egwShade

static egwMaterialJumpTable _egwSMJT = { NULL };

+ (id)allocWithZone:(NSZone*)zone {
    NSObject* inst = (NSObject*)[super allocWithZone:zone];
    
    if(!_egwSMJT.fpSBind && [inst isMemberOfClass:[egwShade class]]) {
        _egwSMJT.fpSBind = (BOOL(*)(id, SEL, EGWuint, EGWuint))[inst methodForSelector:@selector(bindForSurfacingStage:withFlags:)];
        _egwSMJT.fpSUnbind = (BOOL(*)(id, SEL, EGWuint))[inst methodForSelector:@selector(unbindSurfacingWithFlags:)];
        _egwSMJT.fpMBase = (id<NSObject>(*)(id, SEL))[inst methodForSelector:@selector(materialBase)];
        _egwSMJT.fpSSync = (egwValidater*(*)(id, SEL))[inst methodForSelector:@selector(surfacingSync)];
        _egwSMJT.fpSLBStage = (EGWuint(*)(id, SEL))[inst methodForSelector:@selector(lastSurfacingBindingStage)];
    }
    
    return (id)inst;
}

- (id)init {
    if([self isMemberOfClass:[egwShade class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent surfacingShade:(const egwColor2f*)srfcgShade {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _lastSBind = NSNotFound;
    if(!(_sSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_MATERIAL])) { [self release]; return (self = nil); }
    
    if(srfcgShade) egwClrClamp2f(srfcgShade, &_sShade);
    else memcpy((void*)&_sShade, (const void*)&egwSIVecOne2f, sizeof(egwColor2f));
    
    return self;
}

- (id)initWithIdentity:(NSString*)assetIdent luminanceColor:(const EGWsingle)lum alphaColor:(const EGWsingle)alpha {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _lastSBind = NSNotFound;
    if(!(_sSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_MATERIAL])) { [self release]; return (self = nil); }
    
    _sShade.channel.l = egwClamp01f(lum);
    _sShade.channel.a = egwClamp01f(alpha);
    
    return self;
}

- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent {
    if(!([asset isKindOfClass:[self class]]) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _lastSBind = NSNotFound;
    if(!(_sSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_MATERIAL])) { [self release]; return (self = nil); }
    if([(egwShade*)asset shadingDriver] && ![self trySetShadingDriver:[(egwShade*)asset shadingDriver]]) { [self release]; return (self = nil); }
    
    memcpy((void*)&_sShade, (const void*)[(egwShade*)asset shading], sizeof(egwColor2f));
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwShade* copy = nil;
    NSString* copyIdent = nil;
    
    copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwShade allocWithZone:zone] initCopyOf:self
                                             withIdentity:copyIdent])) {
        NSLog(@"egwShade: copyWithZone: Failure initializing new shade from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    return copy;
}

- (void)dealloc {
    [_sSync release]; _sSync = nil;
    if(_sdIpo) { [_sdIpo removeTargetWithObject:self]; [_sdIpo release]; _sdIpo = nil; }
    
    [super dealloc];
}

- (BOOL)bindForSurfacingStage:(EGWuint)srfcgStage withFlags:(EGWuint)flags {
    // NOTE: The code below is non-abstracted OpenGLES dependent. Staying this way till ES2. -jw
    if(!_isSBound || (flags & EGW_BNDOBJ_BINDFLG_APISYNCINVLD) || egwSFPVldtrIsInvalidated(_sSync, @selector(isInvalidated))) {
        _lastSBind = srfcgStage;
        // no material stage enable/disable
        
        //if(!_isSBound || (flags & EGW_BNDOBJ_BINDFLG_APISYNCINVLD) || egwSFPVldtrIsInvalidated(_sSync, @selector(isInvalidated))) {
            GLfloat material[4] = { _sShade.channel.l, _sShade.channel.l, _sShade.channel.l, _sShade.channel.a };
            glColor4f(material[0], material[1], material[2], material[3]);
            glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, (const GLfloat*)&material[0]);
            glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, (const GLfloat*)&material[0]);
            glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, (const GLfloat*)&egwSIVecZero4f);
            glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, (const GLfloat*)&egwSIVecZero4f);
            glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, (GLfloat)0.0f);
        //}
        
        _isSBound = YES;
        egwSFPVldtrValidate(_sSync, @selector(validate));
        return YES;
    }
    
    return NO;
}

- (BOOL)unbindSurfacingWithFlags:(EGWuint)flags {
    // NOTE: The code below is non-abstracted OpenGLES dependent. Staying this way till ES2. -jw
    if(_isSBound) {
        _isSBound = NO;
        return YES;
    }
    
    return NO;
}

- (id<egwPAssetBase>)assetBase {
    return nil;
}

- (EGWuint)coreObjectTypes {
    return EGW_COREOBJ_TYPE_MATERIAL;
}

- (NSString*)identity {
    return _ident;
}

- (EGWuint)lastSurfacingBindingStage {
    return _lastSBind;
}

- (id<NSObject>)materialBase {
    return self;
}

- (const egwMaterialJumpTable*)materialJumpTable {
    return &_egwSMJT;
}

- (egwValidater*)surfacingSync {
    return _sSync;
}

- (const egwColor2f*)shading {
    return &_sShade;
}

- (id<egwPInterpolator>)shadingDriver {
    return _sdIpo;
}

- (void)getSurfacingMaterial:(egwMaterial4f*)srfcgMat {
    srfcgMat->ambient.channel.r = srfcgMat->ambient.channel.g = srfcgMat->ambient.channel.b =
        srfcgMat->diffuse.channel.r = srfcgMat->diffuse.channel.g = srfcgMat->diffuse.channel.b = _sShade.channel.l;
    srfcgMat->ambient.channel.a = srfcgMat->diffuse.channel.a = _sShade.channel.a;
    memcpy((void*)&srfcgMat->specular, (const void*)&egwSIVecZero4f, sizeof(egwColor4f));
    memcpy((void*)&srfcgMat->emmisive, (const void*)&egwSIVecZero4f, sizeof(egwColor4f));
    srfcgMat->shininess = 0.0f;
}

- (void)setShading:(const egwColor2f*)srfcgShade {
    if(srfcgShade) egwClrClamp2f(srfcgShade, &_sShade);
    else memcpy((void*)&_sShade, (const void*)&egwSIVecOne2f, sizeof(egwColor2f));
    
    egwSFPVldtrInvalidate(_sSync, @selector(invalidate));
}

- (void)setShadingLuminanceColor:(const egwColor1f*)lum {
    if(lum) _sShade.channel.l = egwClamp01f(lum->channel.l);
    else _sShade.channel.l = 1.0f;
    
    egwSFPVldtrInvalidate(_sSync, @selector(invalidate));
}

- (void)setShadingAlphaColor:(const egwColor1f*)alpha {
    if(alpha) _sShade.channel.a = egwClamp01f(alpha->channel.l);
    else _sShade.channel.a = 1.0f;
    
    egwSFPVldtrInvalidate(_sSync, @selector(invalidate));
}

- (BOOL)trySetShadingDriver:(id<egwPInterpolator>)shdIpo {
    if(shdIpo) {
        if([shdIpo isKindOfClass:[egwValueInterpolator class]] && [(egwValueInterpolator*)shdIpo channelCount] == 2 && [(egwValueInterpolator*)shdIpo channelFormat] == EGW_KEYCHANNEL_FRMT_SINGLE) {
            [_sdIpo removeTargetWithObject:self];
            [shdIpo retain];
            [_sdIpo release];
            _sdIpo = shdIpo;
            [_sdIpo addTargetWithObject:self method:@selector(setShading:)];
            
            return YES;
        }
    } else {
        [_sdIpo removeTargetWithObject:self];
        [_sdIpo release]; _sdIpo = nil;
        
        return YES;
    }
    
    return NO;
}

- (BOOL)isBoundForSurfacing {
    return _isSBound;
}

- (BOOL)isOpaque {
    return [egwAIGfxCntx determineOpacity:_sShade.channel.a];
}

- (void)validaterDidValidate:(egwValidater*)validater {
}

- (void)validaterDidInvalidate:(egwValidater*)validater {
}

@end

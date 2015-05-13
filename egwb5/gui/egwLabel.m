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

/// @file egwLabel.m
/// @ingroup geWizES_gui_label
/// Label Widget Implementation.

#import "egwLabel.h"
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


@interface egwLabel (Private)

- (void)renderLabel;

@end


@implementation egwLabel

static egwTextureJumpTable _egwTJT = { NULL };

+ (id)allocWithZone:(NSZone*)zone {
    NSObject* inst = (NSObject*)[super allocWithZone:zone];
    
    if(!_egwTJT.fpTBind && [inst isMemberOfClass:[egwLabel class]]) {
        _egwTJT.fpTBind = (BOOL(*)(id, SEL, EGWuint, EGWuint))[inst methodForSelector:@selector(bindForTexturingStage:withFlags:)];
        _egwTJT.fpTUnbind = (BOOL(*)(id, SEL, EGWuint))[inst methodForSelector:@selector(unbindTexturingWithFlags:)];
        _egwTJT.fpTBase = (id<NSObject>(*)(id, SEL))[inst methodForSelector:@selector(textureBase)];
        _egwTJT.fpTSync = (egwValidater*(*)(id, SEL))[inst methodForSelector:@selector(texturingSync)];
        _egwTJT.fpTLBStage = (EGWuint(*)(id, SEL))[inst methodForSelector:@selector(lastTexturingBindingStage)];
    }
    
    return (id)inst;
}

- (id)init {
    if([self isMemberOfClass:[egwLabel class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent surfaceFormat:(EGWuint32)format labelText:(NSString*)text renderingFont:(id<egwPFont>)font geometryStorage:(EGWuint)storage textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack {
    memset((void*)&_lSrfc, 0, sizeof(egwSurface));
    
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!format) format = EGW_SURFACE_FRMT_R8G8B8A8;
    format = egwFormatFromSrfcTrfm(transforms, format);
    if(!(format == EGW_SURFACE_FRMT_GS8 || format == EGW_SURFACE_FRMT_GS8A8 || format == EGW_SURFACE_FRMT_R5G6B5 || format == EGW_SURFACE_FRMT_R5G5B5A1 || format == EGW_SURFACE_FRMT_R4G4B4A4 || format == EGW_SURFACE_FRMT_R8G8B8 || format == EGW_SURFACE_FRMT_R8G8B8A8)) { [self release]; return (self = nil); }
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _rFlags = EGW_GFXOBJ_RNDRFLG_DFLT;
    _rFrame = EGW_FRAME_ALWAYSPASS;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = (lghtStack ? [lghtStack retain] : [[egwLightStack alloc] init]))) { [self release]; return (self = nil); }
    if(!(_mStack = (mtrlStack ? [mtrlStack retain] : [[egwSIEngine defaultMaterialStack] retain]))) { [self release]; return (self = nil); }
    
    _isEnabled = _isVisible = YES;
    _exstText = nil;
    _nextText = [text retain];
    if(!(_lFont = [font retain])) { [self release]; return (self = nil); }
    _lSrfc.format = format;
    _lMesh.vCoords[0].axis.x = -0.0f; _lMesh.vCoords[0].axis.y = -0.0f; _lMesh.vCoords[0].axis.z = 0.0f;
    _lMesh.vCoords[1].axis.x =  0.0f; _lMesh.vCoords[1].axis.y = -0.0f; _lMesh.vCoords[1].axis.z = 0.0f;
    _lMesh.vCoords[2].axis.x =  0.0f; _lMesh.vCoords[2].axis.y =  0.0f; _lMesh.vCoords[2].axis.z = 0.0f;
    _lMesh.vCoords[3].axis.x = -0.0f; _lMesh.vCoords[3].axis.y =  0.0f; _lMesh.vCoords[3].axis.z = 0.0f;
    _exstSize.span.width = _exstSize.span.height = 0;
    _lMesh.nCoords[0].axis.x = 0.0f; _lMesh.nCoords[0].axis.y = 0.0f; _lMesh.nCoords[0].axis.z = 1.0f;
    _lMesh.nCoords[1].axis.x = 0.0f; _lMesh.nCoords[1].axis.y = 0.0f; _lMesh.nCoords[1].axis.z = 1.0f;
    _lMesh.nCoords[2].axis.x = 0.0f; _lMesh.nCoords[2].axis.y = 0.0f; _lMesh.nCoords[2].axis.z = 1.0f;
    _lMesh.nCoords[3].axis.x = 0.0f; _lMesh.nCoords[3].axis.y = 0.0f; _lMesh.nCoords[3].axis.z = 1.0f;
    _lMesh.tCoords[0].axis.x = 0.0f; _lMesh.tCoords[0].axis.y = 1.0f;
    _lMesh.tCoords[1].axis.x = 1.0f; _lMesh.tCoords[1].axis.y = 1.0f;
    _lMesh.tCoords[2].axis.x = 1.0f; _lMesh.tCoords[2].axis.y = 0.0f;
    _lMesh.tCoords[3].axis.x = 0.0f; _lMesh.tCoords[3].axis.y = 0.0f;
    
    _geoStrg = storage;
    if(!(_gbSync = [[egwValidater alloc] initWithOwner:self validation:YES coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    
    if(!(_tbSync = [[egwValidater alloc] initWithOwner:self validation:YES coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    _lastTBind = NSNotFound;
    _texID = NSNotFound;
    _texEnv = environment;
    _texTrans = transforms;
    _texFltr = filter;
    if(!(_tSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_mcsTrans);
    if(!(_mmcsRBVol = [[egwBoundingBox alloc] initWithOpticalSource:&egwSIVecZero3f vertexCount:4 vertexCoords:(const egwVector3f*)&(_lMesh.vCoords[0]) vertexCoordsStride:0])) { [self release]; return (self = nil); }
    if(!(_wcsRBVol = [(NSObject*)_mmcsRBVol copy])) { [self release]; return (self = nil); }
    
    if(_exstText != _nextText)
        [self renderLabel];
    
    return self;
}

- (id)initCopyOf:(id<egwPWidget>)widget withIdentity:(NSString*)assetIdent {
    if(!([widget isKindOfClass:[self class]])) { [self release]; return (self = nil); }
    
    if((self = [self initWithIdentity:assetIdent
                        surfaceFormat:[(egwLabel*)widget surfaceFormat]
                            labelText:[(egwLabel*)widget labelText]
                        renderingFont:[(egwLabel*)widget renderingFont]
                      geometryStorage:[(egwLabel*)widget geometryStorage]
                   textureEnvironment:[(egwLabel*)widget textureEnvironment]
                  texturingTransforms:[(egwLabel*)widget texturingTransforms]
                      texturingFilter:[(egwLabel*)widget texturingFilter]
                           lightStack:[(egwLabel*)widget lightStack]
                        materialStack:[(egwLabel*)widget materialStack]])) {
        [self setRenderingFlags:[(egwLabel*)widget renderingFlags]];
        [self baseOffsetByTransform:[(egwLabel*)widget mcsTransform]];
        [self offsetByTransform:[(egwLabel*)widget lcsTransform]];
        [self orientateByTransform:[(egwLabel*)widget wcsTransform]];
        [self trySetOffsetDriver:[(egwLabel*)widget offsetDriver]];
        [self trySetOrientateDriver:[(egwLabel*)widget orientateDriver]];
    } else { [self release]; return (self = nil); }
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwLabel* copy = nil;
    NSString* copyIdent = nil;
    
    copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwLabel allocWithZone:zone] initWithIdentity:copyIdent
                                                  surfaceFormat:_lSrfc.format
                                                      labelText:_nextText
                                                  renderingFont:_lFont
                                                geometryStorage:_geoStrg
                                             textureEnvironment:_texEnv
                                            texturingTransforms:_texTrans
                                                texturingFilter:_texFltr
                                                     lightStack:_lStack
                                                  materialStack:_mStack])) {
        NSLog(@"egwLabel: copyWithZone: Failure initializing new label from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    [copy setRenderingFlags:_rFlags];
    [copy baseOffsetByTransform:&_mcsTrans];
    [copy offsetByTransform:&_lcsTrans];
    [copy orientateByTransform:&_wcsTrans];
    [copy trySetOffsetDriver:_lcsIpo];
    [copy trySetOrientateDriver:_wcsIpo];
    
    return copy;
}

- (void)dealloc {
    if(_isTBound) [self unbindTexturingWithFlags:EGW_BNDOBJ_BINDFLG_DFLT];
    if(_texID && _texID != NSNotFound) { _texID = [egwAIGfxCntxAGL returnUsedTextureID:_texID]; }
    if(_geoAID)
        _geoAID = [egwAIGfxCntxAGL returnUsedBufferID:_geoAID];
    
    egwSrfcFree(&_lSrfc);
    
    [_mStack release]; _mStack = nil;
    [_lStack release]; _lStack = nil;
    [_rSync release]; _rSync = nil;
    
    [_tSync release]; _tSync = nil;
    [_tbSync release]; _tbSync = nil;
    
    [_gbSync release]; _gbSync = nil;
    
    [_exstText release]; _exstText = nil;
    [_nextText release]; _nextText = nil;
    [_lFont release]; _lFont = nil;
    
    [_mmcsRBVol release]; _mmcsRBVol = nil;
    [_wcsRBVol release]; _wcsRBVol = nil;
    
    if(_lcsIpo) { [_lcsIpo removeTargetWithObject:self]; [_lcsIpo release]; _lcsIpo = nil; }
    if(_wcsIpo) { [_wcsIpo removeTargetWithObject:self]; [_wcsIpo release]; _wcsIpo = nil; }
    
    [_delegate release]; _delegate = nil;
    if(_parent) [self setParent:nil];
    [_ident release]; _ident = nil;
    
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
        
        [_wcsRBVol orientateByTransform:&twcsTrans fromVolume:_mmcsRBVol];
        
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
    if(_isTBoundable &&
       (!_isTBound || (flags & EGW_BNDOBJ_BINDFLG_APISYNCINVLD) || egwSFPVldtrIsInvalidated(_tSync, @selector(isInvalidated)))) {
        GLenum texture = GL_TEXTURE0 + (_lastTBind = txtrStage);
        
        //glActiveTexture(texture);
        egw_glClientActiveTexture(texture);
        
        if(!(flags & EGW_BNDOBJ_BINDFLG_SAMELASTBASE)) {
            if(_isTBoundable && _texID) {
                egw_glBindTexture(texture, GL_TEXTURE_2D, (GLuint)_texID);
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

- (void)baseOffsetByTransform:(const egwMatrix44f*)transform {
    egwMatMultiply44f(&_mcsTrans, transform, &_mcsTrans);
    [_mmcsRBVol baseOffsetByTransform:transform];
    
    _ortPending = YES;
    
    egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
}

- (void)baseOffsetByZeroAlign:(EGWuint)zfAlign {
    egwVector3f offset, min, max;
    egwMatrix44f transform;
    
    // Since this method has a dependency relation on the text rendering size, must have text rendered
    if(_exstText != _nextText)
        [self renderLabel];
    
    // NOTE: Since mesh is not directly transformed by _mcsTrans and vCoords are distortion offsetted -> rebuild vCoords get offsets. -jw
    
    {   egwVector3f vCoords[4];
        EGWsingle thalfWidth = (EGWsingle)_exstSize.span.width * 0.5f;
        EGWsingle thalfHeight = (EGWsingle)_exstSize.span.height * 0.5f;
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
    
    // Build base transform matrix and reuse other method
    egwMatTranslate44f(NULL, &offset, &transform);
    if(zfAlign & EGW_GFXOBJ_ZFALIGN_EXINV)
        egwMatScale44fs(&transform, (zfAlign & EGW_GFXOBJ_ZFALIGN_XINV ? -1.0f : 1.0f), (zfAlign & EGW_GFXOBJ_ZFALIGN_YINV ? -1.0f : 1.0f), (zfAlign & EGW_GFXOBJ_ZFALIGN_ZINV ? -1.0f : 1.0f), &transform);
    
    [self baseOffsetByTransform:&transform];
}

- (BOOL)performSubTaskForComponent:(id<NSObject>)component forSync:(egwValidater*)sync {
    if((id)component == (id)egwAIGfxCntxAGL) {
        if(_exstText != _nextText)
            [self renderLabel];
        
        if(_tbSync == sync) {
            if(_lSrfc.data) { // Surface data -> load into texture
                egwSurface usageSurface; memcpy((void*)&usageSurface, (const void*)&_lSrfc, sizeof(egwSurface));
                
                if(_isTDPersist && (_texFltr & EGW_TEXTURE_FLTR_EXDSTRYP)) {
                    // Use temporary space for texture filters that destroy surface if persistence needs to be maintained
                    if(!(usageSurface.data = (EGWbyte*)malloc(((size_t)usageSurface.pitch * (size_t)usageSurface.size.span.height)))) {
                        NSLog(@"egwLabel: performSubTaskForComponent:forSync: Failure allocating %d bytes for temporary image surface. Failure buffering widget texture for asset '%@' (%p).", ((size_t)usageSurface.pitch * (size_t)usageSurface.size.span.height), _ident, self);
                        return NO;
                    } else
                        memcpy((void*)usageSurface.data, (const void*)_lSrfc.data, ((size_t)usageSurface.pitch * (size_t)usageSurface.size.span.height));
                }
                
                _isTBoundable = NO;
                if([egwAIGfxCntxAGL loadTextureID:&_texID withSurface:&usageSurface texturingTransforms:_texTrans texturingFilter:_texFltr texturingSWrap:EGW_TEXTURE_WRAP_CLAMP texturingTWrap:EGW_TEXTURE_WRAP_CLAMP]) {
                    _isTBoundable = YES;
                    
                    // Cleanup usage surface (if unique due to mipped)
                    if(usageSurface.data && usageSurface.data != _lSrfc.data) {
                        free((void*)usageSurface.data); usageSurface.data = NULL;
                    }
                    
                    egwSFPVldtrValidate(_tbSync, @selector(validate)); // Event delegate will dealloc if not persistent
                    
                    return YES; // Done with this item, no other work left
                } else
                    NSLog(@"egwLabel: performSubTaskForComponent:forSync: Failure buffering widget texture for asset '%@' (%p).", _ident, self);
                
                // Cleanup usage surface (if unique due to mipped)
                if(usageSurface.data && usageSurface.data != _lSrfc.data) {
                    free((void*)usageSurface.data); usageSurface.data = NULL;
                }
                
                return NO; // Failure to load, try again next time
            } else { // No surface data -> delete texture
                if(_texID && _texID != NSNotFound)
                    _texID = [egwAIGfxCntxAGL returnUsedTextureID:_texID];
                
                egwSFPVldtrValidate(_tbSync, @selector(validate)); // Event delegate will dealloc if not persistent
                
                return YES; // Done with this item, no other work left
            }
        } else if(_gbSync == sync && (_geoStrg & EGW_GEOMETRY_STRG_EXVBO)) {
            if([egwAIGfxCntxAGL loadBufferArraysID:&_geoAID withSQVAMesh:&_lMesh geometryStorage:_geoStrg]) {
                egwSFPVldtrValidate(_gbSync, @selector(validate)); // Event delegate will dealloc if not persistent
                
                return YES; // Done with this item, no other work left
            } else
                NSLog(@"egwLabel: performSubTaskForComponent:forSync: Failure buffering instance geometry mesh for asset '%@' (%p).", _ident, self);
            
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
            
            if(_isTBoundable && _isTBound) {
                glPushMatrix();
                
                glMultMatrixf((const GLfloat*)&_wcsTrans);
                glMultMatrixf((const GLfloat*)&_lcsTrans);
                glMultMatrixf((const GLfloat*)&_mcsTrans);
                
                if(_geoAID) {
                    egw_glBindBuffer(GL_ARRAY_BUFFER, _geoAID);
                    
                    glVertexPointer((GLint)3, GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)0);
                    glNormalPointer(GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)((EGWuint)sizeof(egwVector3f) * 4));
                    glTexCoordPointer((GLint)2, GL_FLOAT, (GLsizei)0, (const GLvoid*)(EGWuintptr)((EGWuint)sizeof(egwVector3f) * 4 * 2));
                } else {
                    egw_glBindBuffer(GL_ARRAY_BUFFER, 0);
                    
                    glVertexPointer((GLint)3, GL_FLOAT, (GLsizei)0, (const GLvoid*)&_lMesh.vCoords[0]);
                    glNormalPointer(GL_FLOAT, (GLsizei)0, (const GLvoid*)&_lMesh.nCoords[0]);
                    glTexCoordPointer((GLint)2, GL_FLOAT, (GLsizei)0, (const GLvoid*)&_lMesh.tCoords[0]);
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
    return nil;
}

- (EGWuint)coreObjectTypes {
    return (EGW_COREOBJ_TYPE_GRAPHIC | EGW_COREOBJ_TYPE_ORIENTABLE | EGW_COREOBJ_TYPE_TEXTURE | EGW_COREOBJ_TYPE_WIDGET);
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

- (NSString*)labelText {
    if(_exstText != _nextText)
        [self renderLabel];
    return _nextText;
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

- (const egwMatrix44f*)mcsTransform {
    return &_mcsTrans;
}

- (id<egwPInterpolator>)offsetDriver {
    return _lcsIpo;
}

- (id<egwPInterpolator>)orientateDriver {
    return _wcsIpo;
}

- (id<NSObject>)renderingBase {
    return self;
}

- (id<egwPBounding>)renderingBounding {
    return _wcsRBVol;
}

- (EGWuint32)renderingFlags {
    return _rFlags;
}

- (id<egwPFont>)renderingFont {
    return _lFont;
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

- (EGWuint32)surfaceFormat {
    return _lSrfc.format;
}

- (egwValidater*)textureBufferSync {
    return _tbSync;
}

- (const egwTextureJumpTable*)textureJumpTable {
    return &_egwTJT;
}

- (id<NSObject>)textureBase {
    return self;
}

- (EGWuint)textureEnvironment {
    return _texEnv;
}

- (EGWuint)texturingFilter {
    return _texFltr;
}

- (egwValidater*)texturingSync {
    return _tSync;
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

- (const egwMatrix44f*)lcsTransform {
    return &_lcsTrans;
}

- (const egwMatrix44f*)wcsTransform {
    return &_wcsTrans;
}

- (const egwSize2i*)widgetSize {
    if(_exstText != _nextText)
        [self renderLabel];
    return &_exstSize;
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
            NSLog(@"egwLabel: setParent: Warning: Object system is overriding WCS interpolator driver for instance asset '%@' (%p).", _ident, self);
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

- (void)setLabelString:(const EGWchar*)text {
    if(text && *text != '\0') {
        NSString* txt = [[NSString alloc] initWithUTF8String:(const char*)text];
        
        if(txt) {
            [self setLabelText:txt];
            [txt release]; txt = nil;
        } else
            NSLog(@"egwLabel: setLabelString: Failure allocating string container for text \"%s\" for label %@.", text, _ident);
    } else
        [self setLabelString:nil];
}

- (void)setLabelText:(NSString*)text {
    @synchronized(self) {
        if(text && [text length]) { // Valid text
            if(!_nextText || (_nextText != text && ![_nextText isEqualToString:text])) { // Next isn't already text
                if(!_exstText || (_exstText != text && ![_exstText isEqualToString:text])) { // Existing isn't already text -> invalid tbSync to queue up sub task call to renderLabel to make text data and up to a texID
                    [text retain];
                    [_nextText release];
                    _nextText = text;
                    
                    egwSFPVldtrInvalidate(_tbSync, @selector(invalidate));
                    if(_geoStrg & EGW_GEOMETRY_STRG_EXVBO)
                        egwSFPVldtrInvalidate(_gbSync, @selector(invalidate));
                } else { // Existing is already text -> set next back to existing -> no invalidation req.
                    [_exstText retain];
                    [_nextText release];
                    _nextText = _exstText;
                }
            } // else next already set -> do nothing
        } else { // Invalid text
            if(_nextText != nil) { // Next isn't already nil'ed
                [_nextText release]; _nextText = nil;
                
                if(_exstText != nil) { // Existing isn't already nil'ed -> invalidate tbSync to queue up sub task call to renderLabel to remove text data and free texID
                    egwSFPVldtrInvalidate(_tbSync, @selector(invalidate));
                    if(_geoStrg & EGW_GEOMETRY_STRG_EXVBO)
                        egwSFPVldtrInvalidate(_gbSync, @selector(invalidate));
                } // else existing already set -> no invalidation req.
            } // else next already set -> do nothing
        }
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
	   _parent && !_invkParent &&![_parent isInvokingChild]) {
		_invkParent = YES;
		EGWuint cmpntTypes = (_rFlags & EGW_OBJTREE_FLG_NOUMRGFRAMES ? 0 : EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_GRAPHIC);
		if(cmpntTypes)
			[_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
		_invkParent = NO;
	}
}

- (void)setRenderingFont:(id<egwPFont>)font {
    @synchronized(self) {
        if(_lFont != font) {
            [font retain];
            [_lFont release];
            _lFont = font;
            
            // Remove existing text -> no longer valid
            [_exstText release]; _exstText = nil;
            
            egwSFPVldtrInvalidate(_tbSync, @selector(invalidate));
        }
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
    _isTDPersist = persist;
    
    if(!_isTDPersist && _lSrfc.data && egwSFPVldtrIsValidated(_tbSync, @selector(isValidated))) {
        free((void*)_lSrfc.data); _lSrfc.data = NULL;
    }
    
    return YES;
}

- (BOOL)trySetTextureEnvironment:(EGWuint)environment {
    _texEnv = environment;
    
    egwSFPVldtrInvalidate(_tSync, @selector(invalidate));
    
    return YES;
}

- (BOOL)trySetTexturingFilter:(EGWuint)filter {
    if(filter == EGW_TEXTURE_FLTR_NEAREST || filter == EGW_TEXTURE_FLTR_LINEAR) {
        _texFltr = filter;
        
        egwSFPVldtrInvalidate(_tSync, @selector(invalidate));
        
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
    return !(_rFlags & EGW_GFXOBJ_RNDRFLG_ISTRANSPARENT) && ((_rFlags & EGW_GFXOBJ_RNDRFLG_ISOPAQUE) || (((_lSrfc.format & EGW_SURFACE_FRMT_EXAC) ? NO : (!_mStack || [_mStack isOpaque]))));
}

- (BOOL)isTextureDataPersistent {
    return _isTDPersist;
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
    } else if(_tbSync == validater) {
        if(!_isTDPersist && _lSrfc.data) { // Persistence check & dealloc
            // NOTE: The widget surface is still used even after image data is deleted - do not free the surface! -jw
            free((void*)_lSrfc.data); _lSrfc.data = NULL;
        }
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
    } else if(_tbSync == validater) {
        if(_lSrfc.data || _nextText) // Buffer image data up through context
            [egwAIGfxCntx addSubTask:self forSync:_tbSync];
        else
            egwSFPVldtrValidate(_tbSync, @selector(validate));
    } else if(_gbSync == validater) {
        if(_geoStrg & EGW_GEOMETRY_STRG_EXVBO) // Buffer mesh data up through context
            [egwAIGfxCntx addSubTask:self forSync:_gbSync];
        else
            egwSFPVldtrValidate(_gbSync, @selector(validate));
    }
}

@end


@implementation egwLabel (Private)

- (void)renderLabel {
    if(_exstText != _nextText) {
        @synchronized(self) {
            if(_exstText != _nextText) {
                if(_nextText) {
                    const EGWchar* nextStr = (const EGWchar*)[_nextText UTF8String]; // UTF8String return is auto-released
                    EGWuint Bpp, dataSize;
                    egwSize2i nextSize;
                    egwPoint2i cursor = { 0, 0 };
                    BOOL reuseSrfc = (_isTDPersist && _exstText && _lSrfc.data ? YES : NO);
                    
                    Bpp = (_lSrfc.format & EGW_SURFACE_FRMT_EXBPP) >> 3;
                    [_lFont calculateString:nextStr renderSize:&nextSize];
                    
                    // If next text size isn't big enough to fit in allocated container or is too big, then must redo in full
                    if(_lSrfc.data && (_lSrfc.size.span.width < nextSize.span.width || _lSrfc.size.span.height < nextSize.span.height || _lSrfc.size.span.width >= (nextSize.span.width << 1) || _lSrfc.size.span.height >= (nextSize.span.height << 1))) {
                        free((void*)_lSrfc.data); _lSrfc.data = NULL;
                        [_exstText release]; _exstText = nil;
                        reuseSrfc = NO; // Never reuse surface in the event of a new resize (forgo copy-over)
                    }
                    if(!_lSrfc.data) {
                        _lSrfc.size.span.width = (EGWuint16)egwRoundUpPow2ui((EGWuint)nextSize.span.width);
                        _lSrfc.size.span.height = (EGWuint16)egwRoundUpPow2ui((EGWuint)nextSize.span.height);
                        _lSrfc.pitch = _lSrfc.size.span.width * Bpp;
                        
                        EGWint packingB = egwBytePackingFromSrfcTrfm(_texTrans, EGW_SURFACE_DFLTBPACKING);
                        if(packingB > 1)
                            _lSrfc.pitch = egwRoundUpMultipleui32(_lSrfc.pitch, packingB);
                    }
                    dataSize = (EGWuint)_lSrfc.pitch * (EGWuint)_lSrfc.size.span.height;
                    
                    if(_lSrfc.data || (_lSrfc.data = malloc((size_t)dataSize))) {
                        if(reuseSrfc) {
                            const EGWchar* exstStr = (const EGWchar*)[_exstText UTF8String]; // UTF8String return is auto-released
                            EGWchar* splitStr1 = malloc((size_t)((egwMax2i((EGWint)[_exstText length], (EGWint)[_nextText length]) + 2) * (EGWint)sizeof(EGWchar)));
                            
                            if(splitStr1) {
                                EGWchar* splitStr2 = NULL;
                                
                                // Need to find the shared prefix / non-shared postfix
                                {   EGWchar* csr = splitStr1;
                                    while(*exstStr != '\0' && *exstStr == *nextStr) {
                                        *csr = *exstStr;
                                        ++csr; ++exstStr; ++nextStr;
                                    }
                                    *csr = '\0';
                                    splitStr2 = ++csr;
                                    while(*nextStr != '\0') {
                                        *csr = *nextStr;
                                        ++csr; ++nextStr;
                                    }
                                    *csr = '\0';
                                }
                                
                                if(*splitStr2 != '\0') { // Tail changed (render non-shared postfix)
                                    if(*splitStr1 != '\0') { // Head shared (skip shared prefix)
                                        {   egwSize2i splitSize;
                                            [_lFont calculateString:splitStr1 renderSize:&splitSize];
                                            cursor.axis.x = splitSize.span.width;
                                        }
                                        
                                        // Clear out the non-shared postfix tail only
                                        {   EGWuint remainPitch = (EGWuint)_lSrfc.pitch - ((EGWuint)(cursor.axis.x) * Bpp);
                                            EGWuintptr scanline = (EGWuintptr)_lSrfc.data + ((EGWuintptr)_lSrfc.pitch - (EGWuintptr)remainPitch);
                                            if((_lSrfc.format & EGW_SURFACE_FRMT_EXAC) && [_lFont respondsToSelector:@selector(glyphColor)]) { // FIXME: This glyphColor grab should be abstracted out better. -jw
                                                egwColorRGBA glyphColor; memcpy((void*)&glyphColor, (const void*)(egwColorRGBA*)[_lFont performSelector:@selector(glyphColor)], sizeof(egwColorRGBA)); glyphColor.channel.a = 0;
                                                
                                                if(_lSrfc.format & EGW_SURFACE_FRMT_EXRGB) {
                                                    for(EGWuint row = 0; row < (EGWuint)_lSrfc.size.span.height; ++row) {
                                                        egwPxlWriteRGBAbv(_lSrfc.format, &glyphColor, (EGWbyte*)scanline, -sizeof(egwColorRGBA), 0, remainPitch / Bpp); // writes to end of pitch (inclusive)
                                                        scanline += (EGWuintptr)_lSrfc.pitch;
                                                    }
                                                } else {
                                                    egwColorGSA glyphGASColor; egwPxlWriteRGBAb(_lSrfc.format, &glyphColor, (EGWbyte*)&glyphGASColor);
                                                    
                                                    for(EGWuint row = 0; row < (EGWuint)_lSrfc.size.span.height; ++row) {
                                                        egwPxlWriteGSAbv(_lSrfc.format, &glyphGASColor, (EGWbyte*)scanline, -sizeof(egwColorGSA), 0, remainPitch / Bpp); // writes to end of pitch (inclusive)
                                                        scanline += (EGWuintptr)_lSrfc.pitch;
                                                    }
                                                }
                                            } else { // Surface has no alpha channel, write 0s
                                                for(EGWuint row = 0; row < (EGWuint)_lSrfc.size.span.height; ++row) {
                                                    memset((void*)scanline, 0, (size_t)remainPitch);
                                                    scanline += (EGWuintptr)_lSrfc.pitch;
                                                }
                                            }
                                        }
                                    } else { // No head (no shared prefix)
                                        // Clear out everything (full redo)
                                        if((_lSrfc.format & EGW_SURFACE_FRMT_EXAC) && [_lFont respondsToSelector:@selector(glyphColor)]) {
                                            EGWuintptr scanline = (EGWuintptr)_lSrfc.data;
                                            egwColorRGBA glyphColor; memcpy((void*)&glyphColor, (const void*)(egwColorRGBA*)[_lFont performSelector:@selector(glyphColor)], sizeof(egwColorRGBA)); glyphColor.channel.a = 0;
                                            
                                            if(_lSrfc.format & EGW_SURFACE_FRMT_EXRGB) {
                                                for(EGWuint row = 0; row < (EGWuint)_lSrfc.size.span.height; ++row) {
                                                    egwPxlWriteRGBAbv(_lSrfc.format, &glyphColor, (EGWbyte*)scanline, -sizeof(egwColorRGBA), 0, (EGWuint)_lSrfc.pitch / Bpp); // writes to end of pitch (inclusive)
                                                    scanline += (EGWuintptr)_lSrfc.pitch;
                                                }
                                            } else {
                                                egwColorGSA glyphGASColor; egwPxlWriteRGBAb(_lSrfc.format, &glyphColor, (EGWbyte*)&glyphGASColor);
                                                
                                                for(EGWuint row = 0; row < (EGWuint)_lSrfc.size.span.height; ++row) {
                                                    egwPxlWriteGSAbv(_lSrfc.format, &glyphGASColor, (EGWbyte*)scanline, -sizeof(egwColorGSA), 0, (EGWuint)_lSrfc.pitch / Bpp); // writes to end of pitch (inclusive)
                                                    scanline += (EGWuintptr)_lSrfc.pitch;
                                                }
                                            }
                                        } else // Surface has no alpha channel, write 0s
                                            memset((void*)_lSrfc.data, 0, dataSize);
                                    }
                                    
                                    [_lFont renderString:splitStr2 toSurface:&_lSrfc atCursor:&cursor];
                                }
                                
                                free((void*)splitStr1);
                            } else {
                                NSLog(@"egwLabel: renderLabel: Failure allocating %d bytes of storage for string data. Auto-hiding self.", ((egwMax2i([_exstText length], [_nextText length]) + 2) * sizeof(EGWchar)));
                                [self setVisible:NO]; return;
                            }
                        } else { // Not reusing surface
                            // Clear out everything
                            if((_lSrfc.format & EGW_SURFACE_FRMT_EXAC) && [_lFont respondsToSelector:@selector(glyphColor)]) {
                                EGWuintptr scanline = (EGWuintptr)_lSrfc.data;
                                egwColorRGBA glyphColor; memcpy((void*)&glyphColor, (const void*)(egwColorRGBA*)[_lFont performSelector:@selector(glyphColor)], sizeof(egwColorRGBA)); glyphColor.channel.a = 0;
                                
                                if(_lSrfc.format & EGW_SURFACE_FRMT_EXRGB) {
                                    for(EGWuint row = 0; row < (EGWuint)_lSrfc.size.span.height; ++row) {
                                        egwPxlWriteRGBAbv(_lSrfc.format, &glyphColor, (EGWbyte*)scanline, -sizeof(egwColorRGBA), 0, (EGWuint)_lSrfc.pitch / Bpp);
                                        scanline += (EGWuintptr)_lSrfc.pitch;
                                    }
                                } else {
                                    egwColorGSA glyphGASColor; egwPxlWriteRGBAb(_lSrfc.format, &glyphColor, (EGWbyte*)&glyphGASColor);
                                    
                                    for(EGWuint row = 0; row < (EGWuint)_lSrfc.size.span.height; ++row) {
                                        egwPxlWriteGSAbv(_lSrfc.format, &glyphGASColor, (EGWbyte*)scanline, -sizeof(egwColorGSA), 0, (EGWuint)_lSrfc.pitch / Bpp);
                                        scanline += (EGWuintptr)_lSrfc.pitch;
                                    }
                                }
                            } else // Surface has no alpha channel, write 0s
                                memset((void*)_lSrfc.data, 0, dataSize);
                            
                            [_lFont renderText:_nextText toSurface:&_lSrfc atCursor:&cursor];
                        }
                        
                        // If the next size isn't even, then there is potential to cause distortion due to 0.5 offset in vertex grid half cut -> make even
                        if(egwIsOddui((EGWuint)nextSize.span.width))
                            nextSize.span.width += 1;
                        if(egwIsOddui((EGWuint)nextSize.span.height))
                            nextSize.span.height += 1;
                        
                        _exstSize.span.width = nextSize.span.width;
                        _exstSize.span.height = nextSize.span.height;
                        [_exstText release]; _exstText = [_nextText retain];
                        
                        egwWdgtMeshBVInit(&_lMesh, _mmcsRBVol, (_lSrfc.format & EGW_SURFACE_FRMT_EXAC ? YES : NO), &_exstSize, &_lSrfc.size);
                        [_mmcsRBVol baseOffsetByTransform:&_mcsTrans];
                        
                        _ortPending = YES;
                        
                        egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
                        egwSFPVldtrInvalidate(_tbSync, @selector(invalidate));
                        if(_geoStrg & EGW_GEOMETRY_STRG_EXVBO)
                            egwSFPVldtrInvalidate(_gbSync, @selector(invalidate));
                    } else {
                        NSLog(@"egwLabel: renderLabel: Failure allocating %d bytes of storage for surface data. Auto-hiding label %@.", dataSize, _ident);
                        [self setVisible:NO];
                    }
                } else { // No _nextText -> remove surface
                    // NOTE: The widget surface is still used even after image data is deleted - do not free the surface! -jw
                    free((void*)_lSrfc.data); _lSrfc.data = NULL;
                    _lSrfc.size.span.width = _lSrfc.size.span.height = _lSrfc.pitch = 0;
                    
                    _exstSize.span.width = _exstSize.span.height = 0;
                    [_exstText release]; _exstText = nil;
                    
                    // Adjust vCoords to correspond to render size for correct MCS offsetting (must be done first due to interface on bounding volumes)
                    _lMesh.vCoords[0].axis.x = -0.0f; _lMesh.vCoords[0].axis.y = -0.0f;
                    _lMesh.vCoords[1].axis.x =  0.0f; _lMesh.vCoords[1].axis.y = -0.0f;
                    _lMesh.vCoords[2].axis.x =  0.0f; _lMesh.vCoords[2].axis.y =  0.0f;
                    _lMesh.vCoords[3].axis.x = -0.0f; _lMesh.vCoords[3].axis.y =  0.0f;
                        
                    // Reapply offseting
                    [_mmcsRBVol initWithOpticalSource:&egwSIVecZero3f vertexCount:4 vertexCoords:(const egwVector3f*)&(_lMesh.vCoords) vertexCoordsStride:0];
                    [_mmcsRBVol baseOffsetByTransform:&_lcsTrans];
                    [_wcsRBVol orientateByTransform:&_wcsTrans fromVolume:_mmcsRBVol];
                    
                    // Adjust tCoords to correspond to zero [0,0] size
                    _lMesh.tCoords[1].axis.x = _lMesh.tCoords[2].axis.x = 0.0f;
                    _lMesh.tCoords[0].axis.y = _lMesh.tCoords[1].axis.y = 0.0f;
                    
                    egwSFPVldtrInvalidate(_tbSync, @selector(invalidate));
                    if(_geoStrg & EGW_GEOMETRY_STRG_EXVBO)
                        egwSFPVldtrInvalidate(_gbSync, @selector(invalidate));
                }
            }
        }
    }
}

@end

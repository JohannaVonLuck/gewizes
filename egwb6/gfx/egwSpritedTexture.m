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

/// @file egwSpritedTexture.m
/// @ingroup geWizES_gfx_spritedtexture
/// Sprited Texture Asset Implementation.

#import "egwSpritedTexture.h"
#import "../sys/egwSysTypes.h"
#import "../sys/egwAssetManager.h"
#import "../sys/egwGfxContext.h"
#import "../sys/egwGfxContextNSGL.h"  // NOTE: Below code has a dependence on GL.
#import "../sys/egwGfxContextEAGLES.h"
#import "../math/egwMath.h"
#import "../gfx/egwGraphics.h"
#import "../geo/egwGeometry.h"
#import "../misc/egwValidater.h"


// !!!: ***** egwSpritedTexture *****

@implementation egwSpritedTexture

static egwTextureJumpTable _egwTJT = { NULL };

+ (id)allocWithZone:(NSZone*)zone {
    NSObject* inst = (NSObject*)[super allocWithZone:zone];
    
    if(!_egwTJT.fpRetain && [inst isMemberOfClass:[egwSpritedTexture class]]) {
        _egwTJT.fpRetain = (id(*)(id, SEL))[inst methodForSelector:@selector(retain)];
        _egwTJT.fpRelease = (void(*)(id, SEL))[inst methodForSelector:@selector(release)];
        _egwTJT.fpTBind = (BOOL(*)(id, SEL, EGWuint, EGWuint))[inst methodForSelector:@selector(bindForTexturingStage:withFlags:)];
        _egwTJT.fpTUnbind = (BOOL(*)(id, SEL, EGWuint))[inst methodForSelector:@selector(unbindTexturingWithFlags:)];
        _egwTJT.fpTBase = (id<NSObject>(*)(id, SEL))[inst methodForSelector:@selector(textureBase)];
        _egwTJT.fpTID = (const EGWuint*(*)(id, SEL))[inst methodForSelector:@selector(textureID)];
        _egwTJT.fpTSync = (egwValidater*(*)(id, SEL))[inst methodForSelector:@selector(texturingSync)];
        _egwTJT.fpTLBStage = (EGWuint(*)(id, SEL))[inst methodForSelector:@selector(lastTexturingBindingStage)];
        _egwTJT.fpOpaque = (BOOL(*)(id, SEL))[inst methodForSelector:@selector(isOpaque)];
    }
    
    return (id)inst;
}

- (id)init {
    if([self isMemberOfClass:[egwSpritedTexture class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent spriteSurfaces:(egwSurface*)surfaces surfaceFramings:(egwSurfaceFraming*)framings surfaceCount:(EGWuint16)srfcCount spriteFPS:(EGWsingle)fps textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwSpritedTextureBase alloc] initWithIdentity:assetIdent spriteSurfaces:surfaces surfaceFramings:framings surfaceCount:srfcCount texturingTransforms:transforms texturingFilter:filter])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _fIndex = _sIndex = -1;
    _sFPS = fps;
    
    _lastTBind = NSNotFound;
    _texEnv = environment;
    if(!(_tSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_TEXTURE])) { [self release]; return (self = nil); }
    
    _fCount = [_base frameCount];
    _sCount = [_base surfaceCount];
    _sFrames = [_base textureFramings];
    _texIDs = [_base textureIDs];
    
    return self;
}

- (id)initBlankWithIdentity:(NSString*)assetIdent surfaceFormat:(EGWuint32)format textureWidth:(EGWuint16)width textureHeight:(EGWuint16)height horizontalSplits:(EGWuint16)hrztlSplits verticalSplits:(EGWuint16)vrtclSplits frameCount:(EGWuint16)frmCount spriteFPS:(EGWsingle)fps textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter texturingOpacity:(BOOL)texOpacity {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwSpritedTextureBase alloc] initBlankWithIdentity:assetIdent surfaceFormat:format textureWidth:width textureHeight:height horizontalSplits:hrztlSplits verticalSplits:vrtclSplits frameCount:frmCount texturingTransforms:transforms texturingFilter:filter texturingOpacity:texOpacity])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _fIndex = _sIndex = -1;
    _sFPS = fps;
    
    _lastTBind = NSNotFound;
    _texEnv = environment;
    if(!(_tSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_TEXTURE])) { [self release]; return (self = nil); }
    
    _fCount = [_base frameCount];
    _sCount = [_base surfaceCount];
    _sFrames = [_base textureFramings];
    _texIDs = [_base textureIDs];
    
    return self;
}

- (id)initLoadedFromResourceFiles:(NSString*)resourceFiles withIdentity:(NSString*)assetIdent horizontalSplits:(EGWuint16)hrztlSplits verticalSplits:(EGWuint16)vrtclSplits spriteFPS:(EGWsingle)fps textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter {
    egwSurface* surfaces = NULL;
    egwSurfaceFraming* framings = NULL;
    NSArray* resources = [resourceFiles componentsSeparatedByString:@";,"];
    EGWuint16 srfcCount = (EGWuint16)[resources count];
    EGWuint16 frmCount = 0;
    
    if(!hrztlSplits || !vrtclSplits) goto ErrorCleanup;
    
    if(srfcCount) {
        if(!(surfaces = (egwSurface*)malloc((size_t)srfcCount * sizeof(egwSurface)))) goto ErrorCleanup;
        else memset((void*)surfaces, 0, (size_t)srfcCount * sizeof(egwSurface));
        if(!(framings = (egwSurfaceFraming*)malloc((size_t)srfcCount * sizeof(egwSurfaceFraming)))) goto ErrorCleanup;
        else memset((void*)framings, 0, (size_t)srfcCount * sizeof(egwSurfaceFraming));
        
        for(EGWuint16 sIndex = 0; sIndex < srfcCount; ++sIndex) {
            if(!([egwSIAsstMngr loadSurface:&surfaces[sIndex] fromFile:(NSString*)[resources objectAtIndex:(NSUInteger)sIndex] withTransforms:(transforms | EGW_SURFACE_TRFM_ENSRPOW2)])) goto ErrorCleanup;
            
            framings[sIndex].hFrames = hrztlSplits;
            framings[sIndex].vFrames = vrtclSplits;
            framings[sIndex].fOffset = frmCount;
            framings[sIndex].fCount = framings[sIndex].hFrames * framings[sIndex].vFrames;
            frmCount += framings[sIndex].fCount;
            framings[sIndex].htSizer = 1.0 / (EGWdouble)framings[sIndex].hFrames;
            framings[sIndex].vtSizer = 1.0 / (EGWdouble)framings[sIndex].vFrames;
        }
        
        if(!(self = [self initWithIdentity:assetIdent spriteSurfaces:surfaces surfaceFramings:framings surfaceCount:srfcCount spriteFPS:fps textureEnvironment:environment texturingTransforms:transforms texturingFilter:filter])) goto ErrorCleanup;
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

- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent {
    if(!([asset isKindOfClass:[self class]]) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[asset assetBase] retain])) { [self release]; return (self = nil); }
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _fIndex = _sIndex = -1;
    _sFPS = [(egwSpritedTexture*)asset spriteFPS];
    
    _lastTBind = NSNotFound;
    _texEnv = [(egwSpritedTexture*)asset textureEnvironment];
    if(!(_tSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_TEXTURE])) { [self release]; return (self = nil); }
    
    _fCount = [_base frameCount];
    _sCount = [_base surfaceCount];
    _sFrames = [_base textureFramings];
    _texIDs = [_base textureIDs];
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwSpritedTexture* copy = nil;
    NSString* copyIdent = nil;
    
    if([_ident hasSuffix:@"_default"])
        copyIdent = [[NSString alloc] initWithFormat:@"%@_%d", [_base identity], [_base nextInstanceIndex]];
    else copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwSpritedTexture allocWithZone:zone] initCopyOf:self
                                               withIdentity:copyIdent])) {
        NSLog(@"egwSpritedTexture: copyWithZone: Failure initializing new sprited texture from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    return copy;
}

- (void)dealloc {
    if(_eTimer) [self setEvaluationTimer:nil];
    
    if(_isTBound) [self unbindTexturingWithFlags:EGW_BNDOBJ_BINDFLG_DFLT];
    
    _sFrames = NULL;
    _texIDs = NULL;
    
    [_tSync release]; _tSync = nil;
    
    [_base release]; _base = nil;
    [_ident release]; _ident = nil;
    
    [super dealloc];
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
        
        glMatrixMode(GL_TEXTURE);
        glLoadMatrixf((const GLfloat*)&_stTrans);
        glMatrixMode(GL_MODELVIEW);
        
        _isTBound = YES;
        egwSFPVldtrValidate(_tSync, @selector(validate));
        return YES;
    }
    
    return NO;
}

- (BOOL)unbindTexturingWithFlags:(EGWuint)flags {
    // NOTE: The code below is non-abstracted OpenGLES dependent. Staying this way till ES2. -jw
    if(_isTBound) {
        GLenum texture = GL_TEXTURE0 + _lastTBind;
        egw_glClientActiveTexture(texture);
        
        if(flags & EGW_BNDOBJ_BINDFLG_TOGGLE) {
            //glActiveTexture(texture);
            egw_glBindTexture(texture, GL_TEXTURE_2D, (GLuint)NSNotFound);
            //glFinish();
        }
        
        glMatrixMode(GL_TEXTURE);
        glLoadIdentity();
        glMatrixMode(GL_MODELVIEW);
        
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
        
        egwGeomSFrmTexTransform(_sFrames, _fIndex, &_stTrans);
    } else if(_fIndex < oldFIndex) { // Going backward
        while(!(_fIndex >= _sFrames[_sIndex].fOffset && _fIndex < _sFrames[_sIndex].fOffset + _sFrames[_sIndex].fCount))
            _sIndex = (_sIndex + _sCount - 1) % _sCount;
        
        egwGeomSFrmTexTransform(_sFrames, _fIndex, &_stTrans);
    }
    
    if(_fIndex != oldFIndex || _sIndex != oldSIndex)
        egwSFPVldtrInvalidate(_tSync, @selector(invalidate));
}

- (id<egwPAssetBase>)assetBase {
    return _base;
}

- (EGWuint)coreObjectTypes {
    return (EGW_COREOBJ_TYPE_TEXTURE | EGW_COREOBJ_TYPE_ORIENTABLE);
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

- (NSString*)identity {
    return _ident;
}

- (EGWuint)lastTexturingBindingStage {
    return _lastTBind;
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
    return _base;
}

- (EGWuint)textureEnvironment {
    return _texEnv;
}

- (EGWuint)texturingFilter {
    return [_base texturingFilter];
}

- (const EGWuint*)textureID {
    return _texIDs[_sIndex];
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

- (BOOL)isBoundForTexturing {
    return _isTBound;
}

- (BOOL)isOpaque {
    return [_base isOpaque];
}

- (BOOL)isTextureDataPersistent {
    return [_base isTextureDataPersistent];
}

- (void)validaterDidValidate:(egwValidater*)validater {
}

- (void)validaterDidInvalidate:(egwValidater*)validater {
}

@end


// !!!: ***** egwSpritedTextureBase *****

@implementation egwSpritedTextureBase

+ (id)allocWithZone:(NSZone*)zone {
    id alloc = [super allocWithZone:zone];
    if(alloc) [egwAssetManager incBaseRef];
    if(EGW_ENGINE_ASSETS_CREATIONMSGS) NSLog(@"egwSpritedTextureBase: allocWithZone: Creating new texture base asset (%p).", alloc);
    return alloc;
}

- (id)init {
    if([self isMemberOfClass:[egwSpritedTextureBase class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent spriteSurfaces:(egwSurface*)surfaces surfaceFramings:(egwSurfaceFraming*)framings surfaceCount:(EGWuint16)srfcCount texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter {
    egwSize2i maxTexSize; memcpy((void*)&maxTexSize, (const void*)[egwAIGfxCntx maxTextureSize], sizeof(egwSize2i));
    
    if(!(surfaces && framings && srfcCount && (self = [super init]))) { [self release]; return (self = nil); }
    for(EGWuint16 sIndex = 0; sIndex < srfcCount; ++sIndex) {
        if(!(surfaces[sIndex].data && !(surfaces[sIndex].format & EGW_SURFACE_FRMT_EXPLT) &&
             egwIsPow2ui16(surfaces[sIndex].size.span.width) && egwIsPow2ui16(surfaces[sIndex].size.span.height) && // No auto-upscale, must be exactly pow2
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
    
    if(!(_tbSync = [[egwValidater alloc] initWithOwner:self validation:NO coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    _texTrans = transforms;
    _texFltr = filter;
    _isOpaque = YES;
    
    for(EGWuint16 sIndex = 0; sIndex < _sCount; ++sIndex) {
        memcpy((void*)&_sSrfcs[sIndex], (const void*)&surfaces[sIndex], sizeof(egwSurface));
        memset((void*)(const void*)&surfaces[sIndex], 0, sizeof(egwSurface));
        memcpy((void*)&_sFrames[sIndex], (const void*)&framings[sIndex], sizeof(egwSurfaceFraming));
        _fCount += _sFrames[sIndex].fCount;
        _texIDs[sIndex] = NSNotFound;
        if(_isOpaque)
            _isOpaque = [egwAIGfxCntx determineOpacity:(((EGWsingle)egwSrfcMinAC(&_sSrfcs[sIndex])) / 255.0f)];
    }
    
    if(!([egwAIGfxCntxAGL isActive] && [self performSubTaskForComponent:egwAIGfxCntxAGL forSync:_tbSync])) // Attempt to load, if context active on this thread
        [egwAIGfxCntx addSubTask:self forSync:_tbSync]; // Delayed load for context sub task to handle
    
    return self;
}

- (id)initBlankWithIdentity:(NSString*)assetIdent surfaceFormat:(EGWuint32)format textureWidth:(EGWuint16)width textureHeight:(EGWuint16)height horizontalSplits:(EGWuint16)hrztlSplits verticalSplits:(EGWuint16)vrtclSplits frameCount:(EGWuint16)frmCount texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter texturingOpacity:(BOOL)texOpacity {
    egwSize2i maxTexSize; memcpy((void*)&maxTexSize, (const void*)[egwAIGfxCntx maxTextureSize], sizeof(egwSize2i));
    
    if(!(width && width <= maxTexSize.span.width && egwIsPow2ui16(width) && hrztlSplits && height && height <= maxTexSize.span.height && egwIsPow2ui16(height) && frmCount >= 2 && (self = [super init]))) { [self release]; return (self = nil); } // No auto-upscale, must be exactly pow2
    if(!format) format = EGW_SURFACE_FRMT_R8G8B8A8;
    format = egwFormatFromSrfcTrfm(transforms, format);
    if(!(format == EGW_SURFACE_FRMT_GS8 || format == EGW_SURFACE_FRMT_GS8A8 || format == EGW_SURFACE_FRMT_R5G6B5 || format == EGW_SURFACE_FRMT_R5G5B5A1 || format == EGW_SURFACE_FRMT_R4G4B4A4 || format == EGW_SURFACE_FRMT_R8G8B8 || format == EGW_SURFACE_FRMT_R8G8B8A8)) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _fCount = 0;
    _sCount = (hrztlSplits * vrtclSplits) / (frmCount + ((hrztlSplits * vrtclSplits) - 1)); // Up round
    
    if(!(_sSrfcs = (egwSurface*)malloc((size_t)_sCount * sizeof(egwSurface)))) { [self release]; return (self = nil); }
    else memset((void*)_sSrfcs, 0, (size_t)_sCount * sizeof(egwSurface));
    if(!(_sFrames = (egwSurfaceFraming*)malloc((size_t)_sCount * sizeof(egwSurfaceFraming)))) { [self release]; return (self = nil); }
    else memset((void*)_sFrames, 0, (size_t)_sCount * sizeof(egwSurfaceFraming));
    if(!(_texIDs = (EGWuint*)malloc((size_t)_sCount * sizeof(EGWuint)))) { [self release]; return (self = nil); }
    else memset((void*)_texIDs, 0, (size_t)_sCount * sizeof(EGWuint));
    
    if(!(_tbSync = [[egwValidater alloc] initWithOwner:self validation:YES coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    _texTrans = transforms;
    _texFltr = filter;
    _isOpaque = texOpacity;
    
    // Do allocations
    for(EGWuint16 sIndex = 0; sIndex < _sCount; ++sIndex) {
        if(!(egwSrfcAlloc(&_sSrfcs[sIndex], format, width, height, (EGWuint16)egwBytePackingFromSrfcTrfm(transforms, EGW_SURFACE_DFLTBPACKING)))) { [self release]; return (self = nil); }
        _sFrames[sIndex].hFrames = hrztlSplits;
        _sFrames[sIndex].vFrames = vrtclSplits;
        _sFrames[sIndex].fCount = hrztlSplits * vrtclSplits;
        frmCount -= _sFrames[sIndex].fCount;
        _sFrames[sIndex].fOffset = _fCount;
        _fCount += _sFrames[sIndex].fCount;
        _sFrames[sIndex].htSizer = 1.0 / (EGWdouble)_sFrames[sIndex].hFrames;
        _sFrames[sIndex].vtSizer = 1.0 / (EGWdouble)_sFrames[sIndex].vFrames;
        _texIDs[sIndex] = NSNotFound;
    }
    
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
    if(_sSrfcs) {
        for(EGWuint16 sIndex = 0; sIndex < _sCount; ++sIndex)
            egwSrfcFree(&_sSrfcs[sIndex]);
        free((void*)_sSrfcs); _sSrfcs = NULL;
    }
    
    if(_sFrames) {
        free((void*)_sFrames); _sFrames = NULL;
    }
    
    if(_texIDs) {
        for(EGWuint16 sIndex = 0; sIndex < _sCount; ++sIndex)
            if(_texIDs[sIndex] && _texIDs[sIndex] != NSNotFound)
                _texIDs[sIndex] = [egwAIGfxCntxAGL returnUsedTextureID:_texIDs[sIndex]];
        free((void*)_texIDs); _texIDs = NULL;
    }
    
    [_tbSync release]; _tbSync = nil;
    
    if(EGW_ENGINE_ASSETS_DESTROYMSGS) NSLog(@"egwSpritedTextureBase: dealloc: Destroying texture base asset '%@' (%p).", _ident, self);
    [_ident release]; _ident = nil;
    [egwAssetManager decBaseRef];
    [super dealloc];
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
                            NSLog(@"egwSpritedTextureBase: performSubTaskForComponent:forSync: Failure allocating %lu bytes for temporary image surface. Failure buffering texture #%d/%d for asset '%@' (%p).", ((size_t)usageSurface.pitch * (size_t)usageSurface.size.span.height), (EGWuint)sIndex+1, (EGWuint)_sCount, _ident, self);
                            return NO;
                        } else
                            memcpy((void*)usageSurface.data, (const void*)_sSrfcs[sIndex].data, ((size_t)usageSurface.pitch * (size_t)usageSurface.size.span.height));
                    }
                    
                    if([egwAIGfxCntxAGL loadTextureID:&_texIDs[sIndex] withSurface:&usageSurface texturingTransforms:_texTrans texturingFilter:_texFltr texturingSWrap:EGW_TEXTURE_WRAP_REPEAT texturingTWrap:EGW_TEXTURE_WRAP_REPEAT]) {
                        if(usageSurface.data && usageSurface.data != _sSrfcs[sIndex].data) {
                            free((void*)usageSurface.data); usageSurface.data = NULL;
                        }
                        
                        continue; // Done with this item, on to next
                    } else
                        NSLog(@"egwSpritedTextureBase: performSubTaskForComponent:forSync: Failure buffering texture #%d/%d for asset '%@' (%p).", (EGWuint)sIndex+1, (EGWuint)_sCount, _ident, self);
                    
                    if(usageSurface.data && usageSurface.data != _sSrfcs[sIndex].data) {
                        free((void*)usageSurface.data); usageSurface.data = NULL;
                    }
                    
                    return NO; // Failure to load, try again next time
                }
            }
            
            egwSFPVldtrValidate(_tbSync, @selector(validate)); // Event delegate will dealloc if not persistent
            
            return YES; // Finished with sub task
        }
    }
    
    return YES; // Nothing to do
}

- (EGWuint16)frameCount {
    return _fCount;
}

- (EGWuint16)surfaceCount {
    return _sCount;
}

- (NSString*)identity {
    return _ident;
}

- (EGWuint)nextInstanceIndex {
    return ++_instCounter;
}

- (egwValidater*)textureBufferSync {
    return _tbSync;
}

- (EGWuint const * const *)textureIDs {
    return (EGWuint const * const *)&_texIDs;
}

- (egwSurfaceFraming*)textureFramings {
    return _sFrames;
}

- (const egwSurface*)textureSurfaces {
    return _sSrfcs;
}

- (EGWuint)texturingFilter {
    return _texFltr;
}

- (EGWuint)texturingTransforms {
    return _texTrans;
}

- (EGWuint16)texturingSWrap {
    return EGW_TEXTURE_WRAP_REPEAT;
}

- (EGWuint16)texturingTWrap {
    return EGW_TEXTURE_WRAP_REPEAT;
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

- (BOOL)isOpaque {
    return _isOpaque;
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
    }
}

@end

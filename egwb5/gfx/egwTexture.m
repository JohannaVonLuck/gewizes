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

/// @file egwTexture.m
/// @ingroup geWizES_gfx_texture
/// Texture Asset Implementation.

#import "egwTexture.h"
#import "../sys/egwSysTypes.h"
#import "../sys/egwAssetManager.h"
#import "../sys/egwGfxContext.h"
#import "../sys/egwGfxContextNSGL.h"  // NOTE: Below code has a dependence on GL.
#import "../sys/egwGfxContextEAGLES.h"
#import "../math/egwMath.h"
#import "../gfx/egwGraphics.h"
#import "../misc/egwValidater.h"


// !!!: ***** egwTexture *****

@implementation egwTexture

static egwTextureJumpTable _egwTJT = { NULL };

+ (id)allocWithZone:(NSZone*)zone {
    NSObject* inst = (NSObject*)[super allocWithZone:zone];
    
    if(!_egwTJT.fpTBind && [inst isMemberOfClass:[egwTexture class]]) {
        _egwTJT.fpTBind = (BOOL(*)(id, SEL, EGWuint, EGWuint))[inst methodForSelector:@selector(bindForTexturingStage:withFlags:)];
        _egwTJT.fpTUnbind = (BOOL(*)(id, SEL, EGWuint))[inst methodForSelector:@selector(unbindTexturingWithFlags:)];
        _egwTJT.fpTBase = (id<NSObject>(*)(id, SEL))[inst methodForSelector:@selector(textureBase)];
        _egwTJT.fpTSync = (egwValidater*(*)(id, SEL))[inst methodForSelector:@selector(texturingSync)];
        _egwTJT.fpTLBStage = (EGWuint(*)(id, SEL))[inst methodForSelector:@selector(lastTexturingBindingStage)];
    }
    
    return (id)inst;
}

- (id)init {
    if([self isMemberOfClass:[egwTexture class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent textureSurface:(egwSurface*)surface textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter texturingSWrap:(EGWuint16)sWrap texturingTWrap:(EGWuint16)tWrap {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwTextureBase alloc] initWithIdentity:assetIdent textureSurface:surface texturingTransforms:transforms texturingFilter:filter texturingSWrap:sWrap texturingTWrap:tWrap])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _lastTBind = NSNotFound;
    _texEnv = environment;
    if(!(_tSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_TEXTURE])) { [self release]; return (self = nil); }
    
    _texID = [_base textureID];
    
    return self;
}

- (id)initBlankWithIdentity:(NSString*)assetIdent surfaceFormat:(EGWuint32)format textureWidth:(EGWuint16)width textureHeight:(EGWuint16)height textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter texturingSWrap:(EGWuint16)sWrap texturingTWrap:(EGWuint16)tWrap texturingOpacity:(BOOL)texOpacity {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwTextureBase alloc] initBlankWithIdentity:assetIdent surfaceFormat:format textureWidth:width textureHeight:height texturingTransforms:transforms texturingFilter:filter texturingSWrap:sWrap texturingTWrap:tWrap texturingOpacity:texOpacity])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _texEnv = environment;
    _lastTBind = NSNotFound;
    if(!(_tSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_TEXTURE])) { [self release]; return (self = nil); }
    
    _texID = [_base textureID];
    
    return self;
}

- (id)initPreallocatedWithIdentity:(NSString*)assetIdent textureID:(EGWuint*)textureID textureSurface:(egwSurface*)surface textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter texturingSWrap:(EGWuint16)sWrap texturingTWrap:(EGWuint16)tWrap texturingOpacity:(BOOL)texOpacity {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[egwTextureBase alloc] initPreallocatedWithIdentity:assetIdent textureID:textureID textureSurface:surface texturingTransforms:transforms texturingFilter:filter texturingSWrap:sWrap texturingTWrap:tWrap texturingOpacity:texOpacity])) { [self release]; return (self = nil); }
    if(!(_ident = [[NSString alloc] initWithFormat:@"%@_default", assetIdent])) { [self release]; return (self = nil); }
    
    _lastTBind = NSNotFound;
    _texEnv = environment;
    if(!(_tSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_TEXTURE])) { [self release]; return (self = nil); }
    
    _texID = [_base textureID];
    
    return self;
}

- (id)initLoadedFromResourceFile:(NSString*)resourceFile withIdentity:(NSString*)assetIdent textureEnvironment:(EGWuint)environment texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter texturingSWrap:(EGWuint16)sWrap texturingTWrap:(EGWuint16)tWrap {
    egwSurface surface; memset((void*)&surface, 0, sizeof(egwSurface));
    
    if(!([egwSIAsstMngr loadSurface:&surface fromFile:resourceFile withTransforms:(transforms | EGW_SURFACE_TRFM_ENSRPOW2)])) {
        if(surface.data) egwSrfcFree(&surface);
        [self release]; return (self = nil);
    }
    
    if(!(self = [self initWithIdentity:assetIdent textureSurface:&surface textureEnvironment:environment texturingTransforms:(transforms | EGW_SURFACE_TRFM_ENSRPOW2) texturingFilter:filter texturingSWrap:sWrap texturingTWrap:tWrap])) {
        if(surface.data) egwSrfcFree(&surface);
        return nil;
    }
    
    return self;
}

- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent {
    if(!([asset isKindOfClass:[self class]]) || !(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_base = [[asset assetBase] retain])) { [self release]; return (self = nil); }
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _lastTBind = NSNotFound;
    _texEnv = [(egwTexture*)asset textureEnvironment];
    if(!(_tSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_TEXTURE])) { [self release]; return (self = nil); }
    
    _texID = [_base textureID];
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwTexture* copy = nil;
    NSString* copyIdent = nil;
    
    if([_ident hasSuffix:@"_default"])
        copyIdent = [[NSString alloc] initWithFormat:@"%@_%d", [_base identity], [_base nextInstanceIndex]];
    else copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwTexture allocWithZone:zone] initCopyOf:self
                                               withIdentity:copyIdent])) {
        NSLog(@"egwTexture: copyWithZone: Failure initializing new texture from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    return copy;
}

- (void)dealloc {
    if(_isTBound) [self unbindTexturingWithFlags:EGW_BNDOBJ_BINDFLG_DFLT];
    
    _texID = NULL;
    
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
        
        if(!(flags & EGW_BNDOBJ_BINDFLG_SAMELASTBASE)) {
            if(_texID && *_texID) {
                egw_glBindTexture(texture, GL_TEXTURE_2D, (GLuint)*_texID);
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

- (id<egwPAssetBase>)assetBase {
    return _base;
}

- (EGWuint)coreObjectTypes {
    return (EGW_COREOBJ_TYPE_TEXTURE | EGW_COREOBJ_TYPE_ORIENTABLE);
}

- (NSString*)identity {
    return _ident;
}

- (EGWuint)lastTexturingBindingStage {
    return _lastTBind;
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


// !!!: ***** egwTextureBase *****

@implementation egwTextureBase

+ (id)allocWithZone:(NSZone*)zone {
    id alloc = [super allocWithZone:zone];
    if(alloc) [egwAssetManager incBaseRef];
    if(EGW_ENGINE_ASSETS_CREATIONMSGS) NSLog(@"egwTextureBase: allocWithZone: Creating new texture base asset (%p).", alloc);
    return alloc;
}

- (id)init {
    if([self isMemberOfClass:[egwTextureBase class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent textureSurface:(egwSurface*)surface texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter texturingSWrap:(EGWuint16)sWrap texturingTWrap:(EGWuint16)tWrap {
    egwSize2i maxTexSize; memcpy((void*)&maxTexSize, (const void*)[egwAIGfxCntx maxTextureSize], sizeof(egwSize2i));
    
    if(!(surface && surface->data && !(surface->format & EGW_SURFACE_FRMT_EXPLT) &&
         surface->size.span.width <= maxTexSize.span.width && surface->size.span.height <= maxTexSize.span.height &&
         egwIsPow2ui16(surface->size.span.width) && egwIsPow2ui16(surface->size.span.height) && // No auto-upscale, must be exactly pow2
         (self = [super init]))) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    if(!(_tbSync = [[egwValidater alloc] initWithOwner:self validation:NO coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    memcpy((void*)&_tSrfc, (const void*)surface, sizeof(egwSurface));
    memset((void*)surface, 0, sizeof(egwSurface));
    _texID = NSNotFound;
    _texTrans = transforms;
    _texFltr = filter;
    _texSWrp = sWrap;
    _texTWrp = tWrap;
    _isOpaque = [egwAIGfxCntx determineOpacity:(((EGWsingle)egwSrfcMinAC(&_tSrfc)) / 255.0f)];
    
    if(!([egwAIGfxCntxAGL isActive] && [self performSubTaskForComponent:egwAIGfxCntxAGL forSync:_tbSync])) // Attempt to load, if context active on this thread
        [egwAIGfxCntx addSubTask:self forSync:_tbSync]; // Delayed load for context sub task to handle
    
    return self;
}

- (id)initBlankWithIdentity:(NSString*)assetIdent surfaceFormat:(EGWuint32)format textureWidth:(EGWuint16)width textureHeight:(EGWuint16)height texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter texturingSWrap:(EGWuint16)sWrap texturingTWrap:(EGWuint16)tWrap texturingOpacity:(BOOL)texOpacity {
    egwSize2i maxTexSize; memcpy((void*)&maxTexSize, (const void*)[egwAIGfxCntx maxTextureSize], sizeof(egwSize2i));
    
    if(!(width && width <= maxTexSize.span.width && egwIsPow2ui16(width) && height && height <= maxTexSize.span.height && egwIsPow2ui16(height) && (self = [super init]))) { [self release]; return (self = nil); } // No auto-upscale, must be exactly pow2
    if(!format) format = EGW_SURFACE_FRMT_R8G8B8A8;
    format = egwFormatFromSrfcTrfm(transforms, format);
    if(!(format == EGW_SURFACE_FRMT_GS8 || format == EGW_SURFACE_FRMT_GS8A8 || format == EGW_SURFACE_FRMT_R5G6B5 || format == EGW_SURFACE_FRMT_R5G5B5A1 || format == EGW_SURFACE_FRMT_R4G4B4A4 || format == EGW_SURFACE_FRMT_R8G8B8 || format == EGW_SURFACE_FRMT_R8G8B8A8)) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    if(!(_tbSync = [[egwValidater alloc] initWithOwner:self validation:YES coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    _texID = NSNotFound;
    _texTrans = transforms;
    _texFltr = filter;
    _texSWrp = sWrap;
    _texTWrp = tWrap;
    _isOpaque = texOpacity;
    
    if(!(egwSrfcAlloc(&_tSrfc, format, egwRoundUpPow2ui16(width), egwRoundUpPow2ui16(height), (EGWuint16)egwBytePackingFromSrfcTrfm(transforms, EGW_SURFACE_DFLTBPACKING)))) { [self release]; return (self = nil); }
    
    // NOTE: Delayed load will occur on buffer sync invalidation. -jw
    
    return self;
}

- (id)initPreallocatedWithIdentity:(NSString*)assetIdent textureID:(EGWuint*)textureID textureSurface:(egwSurface*)surface texturingTransforms:(EGWuint)transforms texturingFilter:(EGWuint)filter texturingSWrap:(EGWuint16)sWrap texturingTWrap:(EGWuint16)tWrap texturingOpacity:(BOOL)texOpacity {
    if(!(textureID && *textureID && *textureID != NSNotFound && surface && (self = [super init]))) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    if(!(_tbSync = [[egwValidater alloc] initWithOwner:self validation:YES coreObjectTypes:EGW_COREOBJ_TYPE_INTERNAL])) { [self release]; return (self = nil); }
    memcpy((void*)&_tSrfc, (const void*)surface, sizeof(egwSurface));
    memset((void*)surface, 0, sizeof(egwSurface));
    _texID = *textureID; *textureID = NSNotFound;
    _texTrans = transforms;
    _texFltr = filter;
    _texSWrp = sWrap;
    _texTWrp = tWrap;
    _isOpaque = texOpacity;
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    return nil;
}

- (id)mutableCopyWithZone:(NSZone*)zone {
    return nil;
}

- (void)dealloc {
    egwSrfcFree(&_tSrfc);
    
    if(_texID && _texID != NSNotFound)
        _texID = [egwAIGfxCntxAGL returnUsedTextureID:_texID];
    
    [_tbSync release]; _tbSync = nil;
    
    if(EGW_ENGINE_ASSETS_DESTROYMSGS) NSLog(@"egwTextureBase: dealloc: Destroying texture base asset '%@' (%p).", _ident, self);
    [_ident release]; _ident = nil;
    [egwAssetManager decBaseRef];
    [super dealloc];
}

- (BOOL)performSubTaskForComponent:(id<NSObject>)component forSync:(egwValidater*)sync {
    if((id)component == (id)egwAIGfxCntxAGL) {
        if(_tbSync == sync && _tSrfc.data) {
            egwSurface usageSurface; memcpy((void*)&usageSurface, (const void*)&_tSrfc, sizeof(egwSurface));
            
            if(_isTDPersist && (_texFltr & EGW_TEXTURE_FLTR_EXDSTRYP)) {
                // Use temporary space for texture filters that destroy surface if persistence needs to be maintained
                if(!(usageSurface.data = (EGWbyte*)malloc(((size_t)usageSurface.pitch * (size_t)usageSurface.size.span.height)))) {
                    NSLog(@"egwTextureBase: performSubTaskForComponent:forSync: Failure allocating %d bytes for temporary image surface. Failure buffering image texture for asset '%@' (%p).", ((size_t)usageSurface.pitch * (size_t)usageSurface.size.span.height), _ident, self);
                    return NO;
                } else
                    memcpy((void*)usageSurface.data, (const void*)_tSrfc.data, ((size_t)usageSurface.pitch * (size_t)usageSurface.size.span.height));
            }
            
            if([egwAIGfxCntxAGL loadTextureID:&_texID withSurface:&usageSurface texturingTransforms:_texTrans texturingFilter:_texFltr texturingSWrap:_texSWrp texturingTWrap:_texTWrp]) {
                if(usageSurface.data && usageSurface.data != _tSrfc.data) {
                    free((void*)usageSurface.data); usageSurface.data = NULL;
                }
                
                egwSFPVldtrValidate(_tbSync, @selector(validate)); // Event delegate will dealloc if not persistent
                
                return YES; // Done with this item, no other work left
            } else
                NSLog(@"egwTextureBase: performSubTaskForComponent:forSync: Failure buffering image texture for asset '%@' (%p).", _ident, self);
            
            if(usageSurface.data && usageSurface.data != _tSrfc.data) {
                free((void*)usageSurface.data); usageSurface.data = NULL;
            }
            
            return NO; // Failure to load, try again next time
        }
    }
    
    return YES; // Nothing to do
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

- (const EGWuint*)textureID {
    return &_texID;
}

- (const egwSurface*)textureSurface {
    return &_tSrfc;
}

- (EGWuint)texturingFilter {
    return _texFltr;
}

- (EGWuint)texturingTransforms {
    return _texTrans;
}

- (EGWuint16)texturingSWrap {
    return _texSWrp;
}

- (EGWuint16)texturingTWrap {
    return _texTWrp;
}

- (BOOL)trySetTextureDataPersistence:(BOOL)persist {
    _isTDPersist = persist;
    
    if(!_isTDPersist && egwSFPVldtrIsValidated(_tbSync, @selector(isValidated))) {
        if(_tSrfc.data) {
            free((void*)_tSrfc.data); _tSrfc.data = NULL;
        }
    }
    
    return YES;
}

- (BOOL)trySetTexturingFilter:(EGWuint)filter {
    if(_tSrfc.data) {
        _texFltr = filter;
        
        egwSFPVldtrInvalidate(_tbSync, @selector(invalidate));
        
        return YES;
    }
    
    return NO;
}

- (BOOL)trySetTexturingWrapS:(EGWuint16)sWrap {
    if(_tSrfc.data) {
        _texSWrp = sWrap;
        
        egwSFPVldtrInvalidate(_tbSync, @selector(invalidate));
        
        return YES;
    }
    
    return NO;
}

- (BOOL)trySetTexturingWrapT:(EGWuint16)tWrap {
    if(_tSrfc.data) {
        _texTWrp = tWrap;
        
        egwSFPVldtrInvalidate(_tbSync, @selector(invalidate));
        
        return YES;
    }
    
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
        if(!_isTDPersist && _tSrfc.data) { // Persistence check & dealloc
            // NOTE: The texture surface is still used even after image data is deleted - do not free the surface! -jw
            free((void*)_tSrfc.data); _tSrfc.data = NULL;
        }
    }
}

- (void)validaterDidInvalidate:(egwValidater*)validater {
    if(_tbSync == validater) {
        if(_tSrfc.data) // Buffer image data up through context
            [egwAIGfxCntx addSubTask:self forSync:_tbSync];
        else
            egwSFPVldtrValidate(_tbSync, @selector(validate));
    }
}

@end

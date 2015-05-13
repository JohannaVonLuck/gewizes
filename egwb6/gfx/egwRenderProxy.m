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
/// Renderable Proxy Implementation.

#import "egwRenderProxy.h"
#import "../sys/egwSysTypes.h"
#import "../sys/egwEngine.h"
#import "../sys/egwGfxContext.h"
#import "../sys/egwAssetManager.h"
#import "../sys/egwGfxRenderer.h"
#import "../math/egwMath.h"
#import "../gfx/egwBindingStacks.h"
#import "../gfx/egwBoundings.h"
#import "../gfx/egwLights.h"
#import "../gfx/egwMaterials.h"
#import "../obj/egwObjectBranch.h"
#import "../misc/egwValidater.h"


@implementation egwRenderProxy

static egwRenderableJumpTable _egwRJT = { NULL };

+ (id)allocWithZone:(NSZone*)zone {
    NSObject* inst = (NSObject*)[super allocWithZone:zone];
    
    if(!_egwRJT.fpRetain && [inst isMemberOfClass:[egwRenderProxy class]]) {
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
    if([self isMemberOfClass:[egwRenderProxy class]]) { [self release]; return (self = nil); }
    return (self = [super init]);
}

- (id)initWithIdentity:(NSString*)assetIdent renderingVolume:(id<egwPBounding>)wcsRBVolume lightStack:(egwLightStack*)lghtStack materialStack:(egwMaterialStack*)mtrlStack shaderStack:(egwShaderStack*)shdrStack textureStack:(egwTextureStack*)txtrStack {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [assetIdent retain])) { [self release]; return (self = nil); }
    
    _rFlags = EGW_GFXOBJ_RNDRFLG_DFLT;
    _rFrame = EGW_FRAME_ALWAYSPASS;
    if(!(_rSync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:[self coreObjectTypes]])) { [self release]; return (self = nil); }
    if(!(_lStack = (lghtStack ? [lghtStack retain] : [[egwLightStack alloc] init]))) { [self release]; return (self = nil); }
    if(!(_mStack = (mtrlStack ? [mtrlStack retain] : [[egwSIEngine defaultMaterialStack] retain]))) { [self release]; return (self = nil); }
    _sStack = (shdrStack ? [shdrStack retain] : nil);
    _tStack = (txtrStack ? [txtrStack retain] : nil);
    
    if(!(_wcsRBVol = (wcsRBVolume ? [wcsRBVolume retain] : [[egwZeroBounding alloc] init]))) { [self release]; return (self = nil); }
    
    return self;
}

- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent {
    if(!([asset isKindOfClass:[self class]])) { [self release]; return (self = nil); }
    
    if((self = [self initWithIdentity:assetIdent
                      renderingVolume:[(egwRenderProxy*)asset renderingBounding]
                           lightStack:[(egwRenderProxy*)asset lightStack]
                        materialStack:[(egwRenderProxy*)asset materialStack]
                          shaderStack:[(egwRenderProxy*)asset shaderStack]
                         textureStack:[(egwRenderProxy*)asset textureStack]])) {
        [self setRenderingFlags:[(egwRenderProxy*)asset renderingFlags]];
    } else { [self release]; return (self = nil); }
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwRenderProxy* copy = nil;
    NSString* copyIdent = nil;
    
    copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[egwRenderProxy allocWithZone:zone] initWithIdentity:copyIdent
                                                      renderingVolume:_wcsRBVol
                                                           lightStack:_lStack
                                                        materialStack:_mStack
                                                          shaderStack:_sStack
                                                         textureStack:_tStack])) {
        NSLog(@"egwRenderProxy: copyWithZone: Failure initializing new renderable proxy from asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    [copy setRenderingFlags:_rFlags];
    
    return copy;
}

- (void)dealloc {
    [_delegate release]; _delegate = nil;
    _fpRender = (id (*)(id, SEL, EGWuint32))NULL;
    
    [_lStack release]; _lStack = nil;
    [_mStack release]; _mStack = nil;
    [_sStack release]; _sStack = nil;
    [_tStack release]; _tStack = nil;
    [_rSync release]; _rSync = nil;
    
    if(_parent) [self setParent:nil];
    [_ident release]; _ident = nil;
    
    [super dealloc];
}

- (void)illuminateWithLight:(id<egwPLight>)light {
    [_lStack addLight:light sortByPosition:(egwVector3f*)[_wcsRBVol boundingOrigin]];
}

- (void)startRendering {
    [egwSIGfxRdr renderObject:self]; // TODO: Replace with call to world scene.
}

- (void)stopRendering {
    [egwSIGfxRdr removeObject:self]; // TODO: Replace with call to world scene.
}

- (void)renderWithFlags:(EGWuint32)flags {
    if(flags & EGW_GFXOBJ_RPLYFLY_DORENDERPASS) {
        if(_lStack) egwSFPLghtStckPushAndBindLights(_lStack, @selector(pushAndBindLights));
        else egwAFPGfxCntxBindLights(egwAIGfxCntx, @selector(bindLights));
        if(_mStack) egwSFPMtrlStckPushAndBindMaterials(_mStack, @selector(pushAndBindMaterials));
        else egwAFPGfxCntxBindMaterials(egwAIGfxCntx, @selector(bindMaterials));
        if(_sStack) egwSFPShdrStckPushAndBindShaders(_sStack, @selector(pushAndBindShaders));
        else egwAFPGfxCntxBindShaders(egwAIGfxCntx, @selector(bindShaders));
        if(_tStack) egwSFPTxtrStckPushAndBindTextures(_tStack, @selector(pushAndBindTextures));
        else egwAFPGfxCntxBindTextures(egwAIGfxCntx, @selector(bindTextures));
        
        if(_delegate)
            _fpRender(_delegate, @selector(renderWithFlags:), flags);
         
        if(_tStack) egwSFPTxtrStckPopTextures(_tStack, @selector(popTextures));
        if(_sStack) egwSFPShdrStckPopShaders(_sStack, @selector(popShaders));
        if(_mStack) egwSFPMtrlStckPopMaterials(_mStack, @selector(popMaterials));
        if(_lStack) egwSFPLghtStckPopLights(_lStack, @selector(popLights));
    } else if(flags & EGW_GFXOBJ_RPLYFLG_DORENDERSTART) {
        _isRendering = YES;
        
        if(_delegate)
            _fpRender(_delegate, @selector(renderWithFlags:), flags);
    } else if(flags & EGW_GFXOBJ_RPLYFLG_DORENDERSTOP) {
        _isRendering = NO;
        
        egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
        
        if(_delegate)
            _fpRender(_delegate, @selector(renderWithFlags:), flags);
    }
}

- (id<egwPAssetBase>)assetBase {
    return nil;
}

- (EGWuint)coreObjectTypes {
    return (EGW_COREOBJ_TYPE_GRAPHIC | EGW_COREOBJ_TYPE_PROXY);
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

- (id<NSObject>)renderingBase {
    return self;
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

- (void)setDelegate:(id<egwDRenderProxyEvent>)delegate {
    [delegate retain];
    [_delegate release];
    _delegate = delegate;
    if(_delegate)
        _fpRender = (id (*)(id, SEL, EGWuint32))[(NSObject*)delegate methodForSelector:@selector(renderWithFlags:)];
    else
        _fpRender = (id (*)(id, SEL, EGWuint32))NULL;
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
	   _parent && !_invkParent &&![_parent isInvokingChild]) {
		_invkParent = YES;
		EGWuint cmpntTypes = (_rFlags & EGW_OBJTREE_FLG_NOUMRGFRAMES ? 0 : EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_GRAPHIC);
		if(cmpntTypes)
			[_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)cmpntTypes withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
		_invkParent = NO;
	}
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

- (BOOL)isRendering {
    return _isRendering;
}

- (BOOL)isOpaque {
    return !(_rFlags & EGW_GFXOBJ_RNDRFLG_ISTRANSPARENT) && ((_rFlags & EGW_GFXOBJ_RNDRFLG_ISOPAQUE) || ((!_mStack || egwSFPMtrlStckOpaque(_mStack, @selector(isOpaque))) && (!_sStack || egwSFPShdrStckOpaque(_sStack, @selector(isOpaque)))));
}

- (void)validaterDidValidate:(egwValidater*)validater {
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

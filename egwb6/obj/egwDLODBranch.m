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

/// @file egwDLODBranch.m
/// @ingroup geWizES_obj_dlodbranch
/// Discrete Level-of-Detail Branch Node Asset Implementation.

#import "egwDLODBranch.h"
#import "../inf/egwPObjLeaf.h"
#import "../sys/egwSysTypes.h"
#import "../sys/egwGfxContext.h"
#import "../sys/egwGfxContextAGL.h"
#import "../sys/egwGfxRenderer.h"
#import "../math/egwMath.h"
#import "../math/egwVector.h"
#import "../math/egwMatrix.h"
#import "../gfx/egwBindingStacks.h"
#import "../gfx/egwBoundings.h"
#import "../phy/egwInterpolators.h"
#import "../misc/egwValidater.h"


@implementation egwDLODBranch

static egwRenderableJumpTable _egwRJT = { NULL };

+ (id)allocWithZone:(NSZone*)zone {
    NSObject* inst = (NSObject*)[super allocWithZone:zone];
    
    if(!_egwRJT.fpRetain && [inst isMemberOfClass:[egwDLODBranch class]]) {
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
    [self release]; return (self = nil);
}

- (id)initWithIdentity:(NSString*)nodeIdent parentNode:(id<egwPObjectBranch>)parent childNodes:(NSArray*)nodes defaultBounding:(Class)bndClass {
    return [self initWithIdentity:nodeIdent parentNode:parent childNodes:nodes defaultBounding:bndClass totalSets:1];
}

- (id)initWithIdentity:(NSString*)nodeIdent parentNode:(id<egwPObjectBranch>)parent childNodes:(NSArray*)nodes defaultBounding:(Class)bndClass totalSets:(EGWuint16)sets {
    return [self initWithIdentity:nodeIdent parentNode:parent childNodes:nodes defaultBounding:bndClass totalSets:sets controlDistances:NULL];
}

- (id)initWithIdentity:(NSString*)nodeIdent parentNode:(id<egwPObjectBranch>)parent childNodes:(NSArray*)nodes defaultBounding:(Class)bndClass totalSets:(EGWuint16)sets controlDistances:(EGWsingle*)distances {
    if(!([super initWithIdentity:nodeIdent parentNode:parent childNodes:nodes defaultBounding:bndClass totalSets:sets])) { return nil; }
    
    [super incrementCoreObjectTypes:EGW_COREOBJ_TYPE_GRAPHIC countBy:1]; // Always have a 1-off count for ourselves
    
    _graphicObj->flags = EGW_GFXOBJ_RNDRFLG_DFLT;
    _graphicObj->frame = EGW_FRAME_ALWAYSPASS;
    _vFrame = EGW_FRAME_ALWAYSFAIL;
    if(!(_graphicObj->sync = [[egwValidater alloc] initWithOwner:self coreObjectTypes:EGW_COREOBJ_TYPE_GRAPHIC])) { [self release]; return (self = nil); }
    
    if(!(_cSqrdDiss = (EGWsingle*)malloc((size_t)(_sCount-1) * sizeof(EGWsingle)))) { [self release]; return (self = nil); }
    else if(distances) {
        memcpy((void*)_cSqrdDiss, (const void*)distances, (size_t)(_sCount-1) * sizeof(EGWsingle));
        
        for(EGWuint16 disIndex = 0; disIndex < _sCount-1; ++disIndex)
            _cSqrdDiss[disIndex] *= _cSqrdDiss[disIndex];
    }
    
    [self mergeCoreComponentTypes:EGW_CORECMP_TYPE_ALL forCoreObjectTypes:EGW_COREOBJ_TYPE_GRAPHIC];
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwDLODBranch* copy = nil;
    NSString* copyIdent = nil;
    
    copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[[self class] allocWithZone:zone] initWithIdentity:copyIdent
                                                         parentNode:nil
                                                         childNodes:nil
                                                    defaultBounding:_dfltBnd
                                                          totalSets:_sCount
                                                   controlDistances:NULL])){ // will fill in later (since this expects non-sqrd and we only store sqrd)
        NSLog(@"egwDLODBranch: copyWithZone: Failure initializing new node tree node from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    // Make default copies of individual elements
    if(copy) {
        if(_sChildren) {
            for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                for(id<egwPAsset, egwPObjectNode> node in _sChildren[setIndex]) {
                    id<egwPObjectLeaf> copyAsset = (id<egwPObjectLeaf>)[(NSObject*)node copy];
                    
                    if(copyAsset) {
                        [copy addChild:copyAsset toSetByIndex:setIndex];
                        [copyAsset release]; copyAsset = nil;
                    } else {
                        NSLog(@"egwSwitchBranch: copyWithZone: Failure making default copy of node '%@'. Failure creating copy.", [node identity]);
                    }
                }
            }
        }
        
        for(EGWuint16 setIndex = 1; setIndex < _sCount; ++setIndex)
            [copy setDLOD:setIndex controlDistance:egwSqrtf(_cSqrdDiss[setIndex-1])];
    }
    
    return copy;
}

- (void)dealloc {
    if(_cSqrdDiss) {
        free((void*)_cSqrdDiss); _cSqrdDiss = NULL;
    }
    
    [super dealloc];
}

- (void)addChild:(id<egwPObjectNode>)node {
    if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_GRAPHIC) && !([node coreObjectTypes] & (EGW_COREOBJ_TYPE_NODE | EGW_COREOBJ_TYPE_AUDIO | EGW_COREOBJ_TYPE_ANIMATE | EGW_COREOBJ_TYPE_CAMERA | EGW_COREOBJ_TYPE_LIGHT))) {
        [super addChild:node];
    }
}

- (void)addChild:(id<egwPObjectNode>)node toSetByIndex:(EGWuint)setIndex {
    if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_GRAPHIC) && !([node coreObjectTypes] & (EGW_COREOBJ_TYPE_NODE | EGW_COREOBJ_TYPE_AUDIO | EGW_COREOBJ_TYPE_ANIMATE | EGW_COREOBJ_TYPE_CAMERA | EGW_COREOBJ_TYPE_LIGHT))) {
        [super addChild:node toSetByIndex:setIndex];
    }
}

- (void)addAllChildren:(NSArray*)nodes {
    NSMutableArray* graphicAssets = [[NSMutableArray alloc] initWithCapacity:[nodes count]];
    if(graphicAssets) {
        for(id<egwPObjectNode> node in nodes)
            if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_GRAPHIC) && !([node coreObjectTypes] & (EGW_COREOBJ_TYPE_NODE | EGW_COREOBJ_TYPE_AUDIO | EGW_COREOBJ_TYPE_ANIMATE | EGW_COREOBJ_TYPE_CAMERA | EGW_COREOBJ_TYPE_LIGHT))) {
                [graphicAssets addObject:(id)node];
            }
        
        if([graphicAssets count])
            [super addAllChildren:(NSArray*)graphicAssets];
        
        [graphicAssets release]; graphicAssets = nil;
    }
}

- (void)addAllChildren:(NSArray*)nodes toSetByIndex:(EGWuint)setIndex {
    NSMutableArray* graphicAssets = [[NSMutableArray alloc] initWithCapacity:[nodes count]];
    if(graphicAssets) {
        for(id<egwPObjectNode> node in nodes)
            if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_GRAPHIC) && !([node coreObjectTypes] & (EGW_COREOBJ_TYPE_NODE | EGW_COREOBJ_TYPE_AUDIO | EGW_COREOBJ_TYPE_ANIMATE | EGW_COREOBJ_TYPE_CAMERA | EGW_COREOBJ_TYPE_LIGHT))) {
                [graphicAssets addObject:(id)node];
            }
        
        if([graphicAssets count])
            [super addAllChildren:(NSArray*)graphicAssets toSetByIndex:setIndex];
        
        [graphicAssets release]; graphicAssets = nil;
    }
}

- (void)illuminateWithLight:(id<egwPLight>)light {
    [self performSelector:@selector(illuminateWithLight:) withObject:light inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERPSC)];
}

- (void)mergeCoreComponentTypes:(EGWuint)coreCmpnts forCoreObjectTypes:(EGWuint)coreObjects {
    if(_sChildren) {
        if(coreCmpnts & EGW_CORECMP_TYPE_INTERNAL) {
            _opacity = YES; // NOTE: If any object added has an opacity change, this doesn't get updated unless explicitly merged -jw
            
            for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex)
                for(id<egwPObjectNode> node in _sChildren[setIndex])
                    if(![node performSelector:@selector(isOpaque)]) {
                        _opacity = NO;
                        break;
                    }
        }
    }
    
    [super mergeCoreComponentTypes:coreCmpnts forCoreObjectTypes:coreObjects];
}

- (void)offsetByTransform:(const egwMatrix44f*)lcsTransform {
    _vFrame = EGW_FRAME_ALWAYSFAIL;
    
    // NOTE: Since object is on leaf=yes, must continue method down the line manually -jw
    [super performSelector:@selector(offsetByTransform:) withObject:(id)lcsTransform inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERCSP)];
    
    if(EGW_NODECMPMRG_COMBINED & (EGW_CORECMP_TYPE_FRAMES | EGW_CORECMP_TYPE_SYNCS))
        [self mergeCoreComponentTypes:(EGW_NODECMPMRG_COMBINED & (EGW_CORECMP_TYPE_FRAMES | EGW_CORECMP_TYPE_SYNCS)) forCoreObjectTypes:[self coreObjectTypes]];
}

- (void)orientateByTransform:(const egwMatrix44f*)wcsTransform {
    _vFrame = EGW_FRAME_ALWAYSFAIL;
    
    // NOTE: Since object is on leaf=yes, must continue method down the line manually -jw
    [super performSelector:@selector(orientateByTransform:) withObject:(id)wcsTransform inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERCSP)];
    
    if(EGW_NODECMPMRG_COMBINED & (EGW_CORECMP_TYPE_FRAMES | EGW_CORECMP_TYPE_SYNCS))
        [self mergeCoreComponentTypes:(EGW_NODECMPMRG_COMBINED & (EGW_CORECMP_TYPE_FRAMES | EGW_CORECMP_TYPE_SYNCS)) forCoreObjectTypes:[self coreObjectTypes]];
}

- (void)startRendering {
    [egwSIGfxRdr renderObject:self]; // TODO: Replace with call to world scene.
}

- (void)stopRendering {
    [egwSIGfxRdr removeObject:self]; // TODO: Replace with call to world scene.
}

- (void)renderWithFlags:(EGWuint32)flags {
    // NOTE: At the moment, the DLOD node is treated as a graphic object, adding itself into the graphic object system itself. This will change in the future. -jw
    if(flags & EGW_GFXOBJ_RPLYFLY_DORENDERPASS) {
        flags &= ~EGW_GFXOBJ_RPLYFLG_SAMELASTBASE;
        
        // Camera frame check to update DLOD switch
        {   EGWuint16 vFrame = egwAFPGfxCntxActiveCameraViewingFrame(egwAIGfxCntx, @selector(activeCameraViewingFrame));
            if((vFrame != EGW_FRAME_ALWAYSPASS && _vFrame != EGW_FRAME_ALWAYSPASS && _vFrame != vFrame) ||
               _vFrame == EGW_FRAME_ALWAYSFAIL || vFrame == EGW_FRAME_ALWAYSFAIL) {
                EGWuint16 sDecision;
                EGWsingle distSqrd = egwVecDistanceSqrd3f((egwVector3f*)[egwAFPGfxCntxActiveCamera(egwAIGfxCntx, @selector(activeCamera)) viewingSource], (egwVector3f*)[self renderingSource]);
                
                for(sDecision = 0; sDecision < _sCount-1; ++sDecision)
                    if(distSqrd < _cSqrdDiss[sDecision])
                        break;
                
                if(_sActive != sDecision)
                    [super setActiveSetByIndex:sDecision];
                
                _vFrame = vFrame;
            }
        }
        
        if(_children && !_invkChild) {
            _invkChild = YES;
            for(id<egwPObjectNode> node in _children)
                [node performSelector:@selector(renderWithFlags:) withObject:(id)(EGWuint)flags];
            _invkChild = NO;
        }
    } else if(flags & EGW_GFXOBJ_RPLYFLG_DORENDERSTART) {
        _isRendering = YES;
    } else if(flags & EGW_GFXOBJ_RPLYFLG_DORENDERSTOP) {
        _isRendering = NO;
        
        //egwSFPVldtrInvalidate(_rSync, @selector(invalidate));
    }
}

- (EGWuint)coreObjectTypes {
    return _cType;
}

- (EGWuint)baseCoreObjectType {
    return (EGW_COREOBJ_TYPE_NODE | EGW_COREOBJ_TYPE_GRAPHIC);
}

- (const egwRenderableJumpTable*)renderableJumpTable {
    return &_egwRJT;
}

- (egwLightStack*)lightStack {
    return nil;
}

- (egwMaterialStack*)materialStack {
    return nil;
}

- (egwShaderStack*)shaderStack {
    return nil;
}

- (egwTextureStack*)textureStack {
    return nil;
}

- (id<NSObject>)renderingBase {
    return nil;
}

- (id<egwPBounding>)renderingBounding {
    return _graphicObj->bVol;
}

- (EGWuint32)renderingFlags {
    return _graphicObj->flags;
}

- (EGWuint16)renderingFrame {
    return _graphicObj->frame;
}

- (const egwVector4f*)renderingSource {
    return &(_graphicObj->source);
}

- (egwValidater*)renderingSync {
    return _graphicObj->sync;
}

- (void)setActiveSetByIndex:(EGWuint16)setIndex {
    // Ignore this from external sources
    return;
}

- (void)setDLOD:(EGWuint16)setIndex controlDistance:(EGWsingle)distance {
    if(setIndex >= 1 && setIndex < _sCount)
        _cSqrdDiss[--setIndex] = distance * distance;
}

- (void)setLightStack:(egwLightStack*)lghtStack {
    [self performSelector:@selector(setLightStack:) withObject:lghtStack inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERPSC)];
}

- (void)setMaterialStack:(egwMaterialStack*)mtrlStack {
    [self performSelector:@selector(setMaterialStack:) withObject:mtrlStack inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERPSC)];
}

- (void)setShaderStack:(egwShaderStack*)shdrStack {
    [self performSelector:@selector(setShaderStack:) withObject:shdrStack inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERPSC)];
}

- (void)setTextureStack:(egwTextureStack*)txtrStack {
    [self performSelector:@selector(setTextureStack:) withObject:txtrStack inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERPSC)];
}

- (void)setRenderingFlags:(EGWuint)flags {
    [self performSelector:@selector(setRenderingFlags:) withObject:(id)flags inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERCSP)];
    _graphicObj->flags = flags;
    // NOTE: No need to merge since children will have same value as well -jw
}

- (void)setRenderingFrame:(EGWint)frmNumber {
    [self performSelector:@selector(setRenderingFrame:) withObject:(id)frmNumber inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERCSP)];
    _graphicObj->frame = frmNumber;
    // NOTE: No need to merge since children will have same value as well -jw
}

- (void)setParent:(id<egwPObjectBranch>)parent {
    if(_parent != parent && (id)_parent != (id)self && !_invkParent) {
        [self retain];
        
        if(_parent && ![_parent isInvokingChild]) {
            _invkParent = YES;
            [_parent removeChild:self];
            [_parent performSelector:@selector(decrementCoreObjectTypes:countBy:) withObject:(id)[self coreObjectTypes] withObject:(id)1 inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_GRAPHIC withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            _invkParent = NO;
        }
        
        _parent = parent; // NOTE: Weak reference, do not retain! -jw
        
        if(_parent && ![_parent isInvokingChild]) {
            _invkParent = YES;
            [_parent addChild:self];
            [_parent performSelector:@selector(incrementCoreObjectTypes:countBy:) withObject:(id)[self coreObjectTypes] withObject:(id)1 inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            [_parent performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_GRAPHIC withObject:(id)[self coreObjectTypes] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            _invkParent = NO;
        }
        
        [self release];
    }
}

- (BOOL)isLeaf {
    // NOTE: This has the net affect of turning the node into an leaf stand-in so operations halt (no method pass-off) when this is encountered. -jw
    return YES;
}

- (BOOL)isOpaque {
    return _opacity;
}

- (BOOL)isRendering {
    return _isRendering;
}

@end

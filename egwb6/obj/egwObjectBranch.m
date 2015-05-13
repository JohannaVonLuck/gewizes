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

/// @file egwObjectBranch.m
/// @ingroup geWizES_obj_objectbranch
/// Object Branch Node Asset Implementation.

#import "egwObjectBranch.h"
#import "../inf/egwPObjLeaf.h"
#import "../sys/egwSysTypes.h"
#import "../math/egwVector.h"
#import "../math/egwMatrix.h"
#import "../gfx/egwBoundings.h"
#import "../misc/egwValidater.h"


@interface egwObjectBranch (Overrides)
- (void)applyOrientation;
- (void)offsetByTransform:(const egwMatrix44f*)lcsTransform;
- (void)orientateByTransform:(const egwMatrix44f*)wcsTransform;
- (void)orientateByImpending;
- (void)startPlayback;
- (void)stopPlayback;
- (id<egwPBounding>)playbackBounding;
- (EGWuint32)playbackFlags;
- (EGWuint16)playbackFrame;
- (const egwVector4f*)playbackSource;
- (egwValidater*)playbackSync;
- (void)setPlaybackFlags:(EGWuint)flags;
- (void)setPlaybackFrame:(EGWint)frmNumber;
- (void)startRendering;
- (void)stopRendering;
- (id<egwPBounding>)renderingBounding;
- (EGWuint32)renderingFlags;
- (EGWuint16)renderingFrame;
- (const egwVector4f*)renderingSource;
- (egwValidater*)renderingSync;
- (void)setRenderingFlags:(EGWuint)flags;
- (void)setRenderingFrame:(EGWint)frmNumber;
- (void)startInteracting;
- (void)stopInteracting;
- (id<egwPBounding>)interactionBounding;
- (EGWuint32)interactionFlags;
- (EGWuint16)interactionFrame;
- (const egwVector4f*)interactionSource;
- (egwValidater*)interactionSync;
- (void)setInteractionFlags:(EGWuint)flags;
- (void)setInteractionFrame:(EGWint)frmNumber;
- (id<egwPBounding>)viewingBounding;
- (EGWuint)viewingFlags;
- (EGWuint16)viewingFrame;
- (const egwVector4f*)viewingSource;
- (egwValidater*)viewingSync;
- (void)setViewingFlags:(EGWuint)flags;
- (void)setViewingFrame:(EGWint)frmNumber;
- (id<egwPBounding>)illuminationBounding;
- (EGWuint)illuminationFlags;
- (EGWuint16)illuminationFrame;
- (const egwVector4f*)illuminationSource;
- (egwValidater*)illuminationSync;
- (void)setIlluminationFlags:(EGWuint)flags;
- (void)setIlluminationFrame:(EGWint)frmNumber;
@end


@implementation egwObjectBranch

- (id)init {
    [self release]; return (self = nil);
}

- (id)initWithIdentity:(NSString*)nodeIdent parentNode:(id<egwPObjectBranch>)parent childNodes:(NSArray*)nodes defaultBounding:(Class)bndClass {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_ident = [nodeIdent retain])) { [self release]; return (self = nil); }
    
    _invkChild = _invkParent = NO; _children = nil; _parent = nil;
    
    if(!(_children = [[NSMutableArray alloc] init])) { [self release]; return (self = nil); }
    _dfltBnd = (bndClass && [bndClass conformsToProtocol:@protocol(egwPBounding)] ? bndClass : [egwBoundingSphere class]);
    _cType = [self baseCoreObjectType];
    
    if(parent) [self setParent:parent];
    if(nodes && [nodes count]) [self addAllChildren:nodes];
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwObjectBranch* copy = nil;
    NSString* copyIdent = nil;
    
    copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[[self class] allocWithZone:zone] initWithIdentity:copyIdent
                                                         parentNode:nil
                                                         childNodes:nil
                                                    defaultBounding:_dfltBnd])) {
        NSLog(@"egwObjectBranch: copyWithZone: Failure initializing new node tree node from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    // Make default copies of individual elements
    if(copy) {
        if(0xdeadc0de) {
            if(_children && [_children count]) {
                _invkChild = YES;
                
                for(id<egwPAsset, egwPObjectNode> node in _children) {
                    id<egwPObjectLeaf> copyAsset = (id<egwPObjectLeaf>)[(NSObject*)node copy];
                    
                    if(copyAsset) {
                        [copy addChild:copyAsset];
                        [copyAsset release]; copyAsset = nil;
                    } else {
                        NSLog(@"egwObjectBranch: copyWithZone: Failure making default copy of node '@%'. Failure creating copy.", [node identity]);
                    }
                }
                
                _invkChild = NO;
            }
        }
    }
    
    return copy;
}

- (void)dealloc {
    if(_parent) [self setParent:nil];
    if(_children) [self removeAllChildren];
    
    if(_audioObj) { free(_audioObj); _audioObj = NULL; _audioObjCount = 0; }
    if(_graphicObj) { free(_graphicObj); _graphicObj = NULL; _graphicObjCount = 0; }
    if(_animateObj) { free(_animateObj); _animateObj = NULL; _animateObjCount = 0; }
    if(_cameraObj) { free(_cameraObj); _cameraObj = NULL; _cameraObjCount = 0; }
    if(_lightObj) { free(_lightObj); _lightObj = NULL; _lightObjCount = 0; }
    
    [_ident release]; _ident = nil;
    
    [_children release]; _children = nil;
    
    [super dealloc];
}

- (void)addChild:(id<egwPObjectNode>)node {
    if(0xdeadc0de) {
        if(_children && (id)node != (id)self && !_invkChild && ![node isChildOf:self]) {
            EGWuint objCounter[5] = { 0 };
            
            if(![node isInvokingParent]) {
                _invkChild = YES;
                [node setParent:self];
                _invkChild = NO;
                
                if([node isLeaf]) {
                    if([node coreObjectTypes] & EGW_COREOBJ_TYPE_AUDIO) ++objCounter[0];
                    if([node coreObjectTypes] & EGW_COREOBJ_TYPE_GRAPHIC) ++objCounter[1];
                    if([node coreObjectTypes] & EGW_COREOBJ_TYPE_ANIMATE) ++objCounter[2];
                    if([node coreObjectTypes] & EGW_COREOBJ_TYPE_CAMERA) ++objCounter[3];
                    if([node coreObjectTypes] & EGW_COREOBJ_TYPE_LIGHT) ++objCounter[4];
                } else {
                    EGWuint count;
                    if((count = [(id<egwPObjectBranch>)node countCoreObjectTypes:EGW_COREOBJ_TYPE_AUDIO])) objCounter[0] += count;
                    if((count = [(id<egwPObjectBranch>)node countCoreObjectTypes:EGW_COREOBJ_TYPE_GRAPHIC])) objCounter[1] += count;
                    if((count = [(id<egwPObjectBranch>)node countCoreObjectTypes:EGW_COREOBJ_TYPE_ANIMATE])) objCounter[2] += count;
                    if((count = [(id<egwPObjectBranch>)node countCoreObjectTypes:EGW_COREOBJ_TYPE_CAMERA])) objCounter[3] += count;
                    if((count = [(id<egwPObjectBranch>)node countCoreObjectTypes:EGW_COREOBJ_TYPE_LIGHT])) objCounter[4] += count;
                }
            }
            
            [_children addObject:(id)node];
            
            if(objCounter[0]) {
                [self performSelector:@selector(incrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_AUDIO withObject:(id)objCounter[0] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
                [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_AUDIO withObject:(id)EGW_COREOBJ_TYPE_AUDIO inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            }
            
            if(objCounter[1]) {
                [self performSelector:@selector(incrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_GRAPHIC withObject:(id)objCounter[1] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
                [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_GRAPHIC withObject:(id)EGW_COREOBJ_TYPE_GRAPHIC inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            }
            
            if(objCounter[2]) {
                [self performSelector:@selector(incrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_ANIMATE withObject:(id)objCounter[2] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
                [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_ANIMATE withObject:(id)EGW_COREOBJ_TYPE_ANIMATE inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            }
            
            if(objCounter[3]) {
                [self performSelector:@selector(incrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_CAMERA withObject:(id)objCounter[3] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
                [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_CAMERA withObject:(id)EGW_COREOBJ_TYPE_CAMERA inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            }
            
            if(objCounter[4]) {
                [self performSelector:@selector(incrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_LIGHT withObject:(id)objCounter[4] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
                [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_LIGHT withObject:(id)EGW_COREOBJ_TYPE_LIGHT inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            }
        }
    }
}

- (void)addAllChildren:(NSArray*)nodes {
    if(0xdeadc0de) {
        if(_children && !_invkChild) {
            EGWuint objCounter[5] = { 0 };
            
            for(id<egwPObjectNode> node in nodes) {
                if((id)node != (id)self && ![node isChildOf:self]) {
                    if(![node isInvokingParent]) {
                        _invkChild = YES;
                        [node setParent:self];
                        _invkChild = NO;
                        
                        if([node isLeaf]) {
                            if([node coreObjectTypes] & EGW_COREOBJ_TYPE_AUDIO) ++objCounter[0];
                            if([node coreObjectTypes] & EGW_COREOBJ_TYPE_GRAPHIC) ++objCounter[1];
                            if([node coreObjectTypes] & EGW_COREOBJ_TYPE_ANIMATE) ++objCounter[2];
                            if([node coreObjectTypes] & EGW_COREOBJ_TYPE_CAMERA) ++objCounter[3];
                            if([node coreObjectTypes] & EGW_COREOBJ_TYPE_LIGHT) ++objCounter[4];
                        } else {
                            EGWuint count;
                            if((count = [(id<egwPObjectBranch>)node countCoreObjectTypes:EGW_COREOBJ_TYPE_AUDIO])) objCounter[0] += count;
                            if((count = [(id<egwPObjectBranch>)node countCoreObjectTypes:EGW_COREOBJ_TYPE_GRAPHIC])) objCounter[1] += count;
                            if((count = [(id<egwPObjectBranch>)node countCoreObjectTypes:EGW_COREOBJ_TYPE_ANIMATE])) objCounter[2] += count;
                            if((count = [(id<egwPObjectBranch>)node countCoreObjectTypes:EGW_COREOBJ_TYPE_CAMERA])) objCounter[3] += count;
                            if((count = [(id<egwPObjectBranch>)node countCoreObjectTypes:EGW_COREOBJ_TYPE_LIGHT])) objCounter[4] += count;
                        }
                    }
                    
                    [_children addObject:(id)node];
                }
            }
            
            if(objCounter[0]) {
                [self performSelector:@selector(incrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_AUDIO withObject:(id)objCounter[0] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
                [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_AUDIO withObject:(id)EGW_COREOBJ_TYPE_AUDIO inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            }
            
            if(objCounter[1]) {
                [self performSelector:@selector(incrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_GRAPHIC withObject:(id)objCounter[1] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
                [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_GRAPHIC withObject:(id)EGW_COREOBJ_TYPE_GRAPHIC inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            }
            
            if(objCounter[2]) {
                [self performSelector:@selector(incrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_ANIMATE withObject:(id)objCounter[2] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
                [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_ANIMATE withObject:(id)EGW_COREOBJ_TYPE_ANIMATE inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            }
            
            if(objCounter[3]) {
                [self performSelector:@selector(incrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_CAMERA withObject:(id)objCounter[3] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
                [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_CAMERA withObject:(id)EGW_COREOBJ_TYPE_CAMERA inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            }
            
            if(objCounter[4]) {
                [self performSelector:@selector(incrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_LIGHT withObject:(id)objCounter[4] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
                [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_LIGHT withObject:(id)EGW_COREOBJ_TYPE_LIGHT inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            }
        }
    }
}

- (BOOL)containsChild:(id<egwPObjectNode>)node {
    if(0xdeadc0de) {
        return [_children containsObject:(id)node];
    }
    
    return NO;
}

- (void)removeChild:(id<egwPObjectNode>)node {
    if(0xdeadc0de) {
        if(_children && !_invkChild && [node isChildOf:self]) {
            EGWuint objCounter[5] = { 0 };
            
            if(![node isInvokingParent]) {
                _invkChild = YES;
                [node setParent:nil];
                _invkChild = NO;
                
                if([node isLeaf]) {
                    if([node coreObjectTypes] & EGW_COREOBJ_TYPE_AUDIO) ++objCounter[0];
                    if([node coreObjectTypes] & EGW_COREOBJ_TYPE_GRAPHIC) ++objCounter[1];
                    if([node coreObjectTypes] & EGW_COREOBJ_TYPE_ANIMATE) ++objCounter[2];
                    if([node coreObjectTypes] & EGW_COREOBJ_TYPE_CAMERA) ++objCounter[3];
                    if([node coreObjectTypes] & EGW_COREOBJ_TYPE_LIGHT) ++objCounter[4];
                } else {
                    EGWuint count;
                    if((count = [(id<egwPObjectBranch>)node countCoreObjectTypes:EGW_COREOBJ_TYPE_AUDIO])) objCounter[0] += count;
                    if((count = [(id<egwPObjectBranch>)node countCoreObjectTypes:EGW_COREOBJ_TYPE_GRAPHIC])) objCounter[1] += count;
                    if((count = [(id<egwPObjectBranch>)node countCoreObjectTypes:EGW_COREOBJ_TYPE_ANIMATE])) objCounter[2] += count;
                    if((count = [(id<egwPObjectBranch>)node countCoreObjectTypes:EGW_COREOBJ_TYPE_CAMERA])) objCounter[3] += count;
                    if((count = [(id<egwPObjectBranch>)node countCoreObjectTypes:EGW_COREOBJ_TYPE_LIGHT])) objCounter[4] += count;
                }
            }
            
            [_children removeObject:(id)node];
            
            if(objCounter[0]) {
                [self performSelector:@selector(decrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_AUDIO withObject:(id)objCounter[0] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
                [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_AUDIO withObject:(id)EGW_COREOBJ_TYPE_AUDIO inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            }
            
            if(objCounter[1]) {
                [self performSelector:@selector(decrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_GRAPHIC withObject:(id)objCounter[1] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
                [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_GRAPHIC withObject:(id)EGW_COREOBJ_TYPE_GRAPHIC inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            }
            
            if(objCounter[2]) {
                [self performSelector:@selector(decrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_ANIMATE withObject:(id)objCounter[2] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
                [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_ANIMATE withObject:(id)EGW_COREOBJ_TYPE_ANIMATE inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            }
            
            if(objCounter[3]) {
                [self performSelector:@selector(decrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_CAMERA withObject:(id)objCounter[3] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
                [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_CAMERA withObject:(id)EGW_COREOBJ_TYPE_CAMERA inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            }
            
            if(objCounter[4]) {
                [self performSelector:@selector(decrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_LIGHT withObject:(id)objCounter[4] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
                [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_LIGHT withObject:(id)EGW_COREOBJ_TYPE_LIGHT inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            }
        }
    }
}

- (void)removeAllChildren {
    if(0xdeadc0de) {
        if(_children && !_invkChild) {
            EGWuint objCounter[5] = { 0 };
            
            for(id<egwPObjectNode> node in _children)
                if(![node isInvokingParent]) {
                    _invkChild = YES;
                    [node setParent:nil];
                    _invkChild = NO;
                    
                    if([node isLeaf]) {
                        if([node coreObjectTypes] & EGW_COREOBJ_TYPE_AUDIO) ++objCounter[0];
                        if([node coreObjectTypes] & EGW_COREOBJ_TYPE_GRAPHIC) ++objCounter[1];
                        if([node coreObjectTypes] & EGW_COREOBJ_TYPE_ANIMATE) ++objCounter[2];
                        if([node coreObjectTypes] & EGW_COREOBJ_TYPE_CAMERA) ++objCounter[3];
                        if([node coreObjectTypes] & EGW_COREOBJ_TYPE_LIGHT) ++objCounter[4];
                    } else {
                        EGWuint count;
                        if((count = [(id<egwPObjectBranch>)node countCoreObjectTypes:EGW_COREOBJ_TYPE_AUDIO])) objCounter[0] += count;
                        if((count = [(id<egwPObjectBranch>)node countCoreObjectTypes:EGW_COREOBJ_TYPE_GRAPHIC])) objCounter[1] += count;
                        if((count = [(id<egwPObjectBranch>)node countCoreObjectTypes:EGW_COREOBJ_TYPE_ANIMATE])) objCounter[2] += count;
                        if((count = [(id<egwPObjectBranch>)node countCoreObjectTypes:EGW_COREOBJ_TYPE_CAMERA])) objCounter[3] += count;
                        if((count = [(id<egwPObjectBranch>)node countCoreObjectTypes:EGW_COREOBJ_TYPE_LIGHT])) objCounter[4] += count;
                    }
                }
            
            [_children removeAllObjects];
            
            if(objCounter[0]) {
                [self performSelector:@selector(decrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_AUDIO withObject:(id)objCounter[0] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
                [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_AUDIO withObject:(id)EGW_COREOBJ_TYPE_AUDIO inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            }
            
            if(objCounter[1]) {
                [self performSelector:@selector(decrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_GRAPHIC withObject:(id)objCounter[1] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
                [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_GRAPHIC withObject:(id)EGW_COREOBJ_TYPE_GRAPHIC inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            }
            
            if(objCounter[2]) {
                [self performSelector:@selector(decrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_ANIMATE withObject:(id)objCounter[2] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
                [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_ANIMATE withObject:(id)EGW_COREOBJ_TYPE_ANIMATE inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            }
            
            if(objCounter[3]) {
                [self performSelector:@selector(decrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_CAMERA withObject:(id)objCounter[3] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
                [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_CAMERA withObject:(id)EGW_COREOBJ_TYPE_CAMERA inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            }
            
            if(objCounter[4]) {
                [self performSelector:@selector(decrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_LIGHT withObject:(id)objCounter[4] inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
                [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_LIGHT withObject:(id)EGW_COREOBJ_TYPE_LIGHT inDirection:EGW_NODEMSG_DIR_BREADTHUPWARDS];
            }
        }
    }
}

- (EGWuint)countCoreObjectTypes:(EGWuint)coreObjects {
    EGWuint count = 0;
    
    if(coreObjects & EGW_COREOBJ_TYPE_AUDIO)
        count += (EGWuint)_audioObjCount;
    if(coreObjects & EGW_COREOBJ_TYPE_GRAPHIC)
        count += (EGWuint)_graphicObjCount;
    if(coreObjects & EGW_COREOBJ_TYPE_ANIMATE)
        count += (EGWuint)_animateObjCount;
    if(coreObjects & EGW_COREOBJ_TYPE_CAMERA)
        count += (EGWuint)_cameraObjCount;
    if(coreObjects & EGW_COREOBJ_TYPE_LIGHT)
        count += (EGWuint)_lightObjCount;
    
    return count;
}

- (void)incrementCoreObjectTypes:(EGWuint)coreObjects countBy:(EGWuint)count {
    if(coreObjects & EGW_COREOBJ_TYPE_AUDIO)
        _audioObjCount += count;
    if(coreObjects & EGW_COREOBJ_TYPE_GRAPHIC)
        _graphicObjCount += count;
    if(coreObjects & EGW_COREOBJ_TYPE_ANIMATE)
        _animateObjCount += count;
    if(coreObjects & EGW_COREOBJ_TYPE_CAMERA)
        _cameraObjCount += count;
    if(coreObjects & EGW_COREOBJ_TYPE_LIGHT)
        _lightObjCount += count;
    
    if(!_audioObj && _audioObjCount) {
        _audioObj = malloc(sizeof(egwCoreComponents));
        memset((void*)_audioObj, -1, sizeof(egwCoreComponents)); _audioObj->bVol = nil; _audioObj->sync = nil;
        _audioObj->invalidations = EGW_CORECMP_TYPE_NONE;
        if(EGW_CORECMP_TYPE_BVOLS & EGW_NODECMPMRG_AUDIO)
            _audioObj->bVol = [[_dfltBnd alloc] init];
        if(EGW_CORECMP_TYPE_FLAGS & EGW_NODECMPMRG_AUDIO)
            _audioObj->flags = 0;
        if(EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_AUDIO)
            _audioObj->frame = EGW_FRAME_ALWAYSFAIL;
        if(EGW_CORECMP_TYPE_SOURCES & EGW_NODECMPMRG_AUDIO)
            egwVecCopy4f(&egwSIVecUnitW4f, &(_audioObj->source));
        if(EGW_CORECMP_TYPE_SYNCS & EGW_NODECMPMRG_AUDIO)
            _audioObj->sync = [[egwValidater alloc] initWithOwner:self validation:YES coreObjectTypes:EGW_COREOBJ_TYPE_AUDIO];
    }
    
    if(!_graphicObj && _graphicObjCount) {
        _graphicObj = malloc(sizeof(egwCoreComponents));
        memset((void*)_graphicObj, -1, sizeof(egwCoreComponents)); _graphicObj->bVol = nil; _graphicObj->sync = nil;
        _graphicObj->invalidations = EGW_CORECMP_TYPE_NONE;
        if(EGW_CORECMP_TYPE_BVOLS & EGW_NODECMPMRG_GRAPHIC)
            _graphicObj->bVol = [[_dfltBnd alloc] init];
        if(EGW_CORECMP_TYPE_FLAGS & EGW_NODECMPMRG_GRAPHIC)
            _graphicObj->flags = 0;
        if(EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_GRAPHIC)
            _graphicObj->frame = EGW_FRAME_ALWAYSFAIL;
        if(EGW_CORECMP_TYPE_SOURCES & EGW_NODECMPMRG_GRAPHIC)
            egwVecCopy4f(&egwSIVecUnitW4f, &(_graphicObj->source));
        if(EGW_CORECMP_TYPE_SYNCS & EGW_NODECMPMRG_GRAPHIC)
            _graphicObj->sync = [[egwValidater alloc] initWithOwner:self validation:YES coreObjectTypes:EGW_COREOBJ_TYPE_GRAPHIC];
    }
    
    if(!_animateObj && _animateObjCount) {
        _animateObj = malloc(sizeof(egwCoreComponents));
        memset((void*)_animateObj, -1, sizeof(egwCoreComponents)); _animateObj->bVol = nil; _animateObj->sync = nil;
        _animateObj->invalidations = EGW_CORECMP_TYPE_NONE;
        if(EGW_CORECMP_TYPE_BVOLS & EGW_NODECMPMRG_ANIMATE)
            _animateObj->bVol = [[_dfltBnd alloc] init];
        if(EGW_CORECMP_TYPE_FLAGS & EGW_NODECMPMRG_ANIMATE)
            _animateObj->flags = 0;
        if(EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_ANIMATE)
            _animateObj->frame = EGW_FRAME_ALWAYSFAIL;
        if(EGW_CORECMP_TYPE_SOURCES & EGW_NODECMPMRG_ANIMATE)
            egwVecCopy4f(&egwSIVecUnitW4f, &(_animateObj->source));
        if(EGW_CORECMP_TYPE_SYNCS & EGW_NODECMPMRG_ANIMATE)
            _animateObj->sync = [[egwValidater alloc] initWithOwner:self validation:YES coreObjectTypes:EGW_COREOBJ_TYPE_ANIMATE];
    }
    
    if(!_cameraObj && _cameraObjCount) {
        _cameraObj = malloc(sizeof(egwCoreComponents));
        memset((void*)_cameraObj, -1, sizeof(egwCoreComponents)); _cameraObj->bVol = nil; _cameraObj->sync = nil;
        _cameraObj->invalidations = EGW_CORECMP_TYPE_NONE;
        if(EGW_CORECMP_TYPE_BVOLS & EGW_NODECMPMRG_CAMERA)
            _cameraObj->bVol = [[_dfltBnd alloc] init];
        if(EGW_CORECMP_TYPE_FLAGS & EGW_NODECMPMRG_CAMERA)
            _cameraObj->flags = 0;
        if(EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_CAMERA)
            _cameraObj->frame = EGW_FRAME_ALWAYSFAIL;
        if(EGW_CORECMP_TYPE_SOURCES & EGW_NODECMPMRG_CAMERA)
            egwVecCopy4f(&egwSIVecUnitW4f, &(_cameraObj->source));
        if(EGW_CORECMP_TYPE_SYNCS & EGW_NODECMPMRG_CAMERA)
            _cameraObj->sync = [[egwValidater alloc] initWithOwner:self validation:YES coreObjectTypes:EGW_COREOBJ_TYPE_CAMERA];
    }
    
    if(!_lightObj && _lightObjCount) {
        _lightObj = malloc(sizeof(egwCoreComponents));
        memset((void*)_lightObj, -1, sizeof(egwCoreComponents)); _lightObj->bVol = nil; _lightObj->sync = nil;
        _lightObj->invalidations = EGW_CORECMP_TYPE_NONE;
        if(EGW_CORECMP_TYPE_BVOLS & EGW_NODECMPMRG_LIGHT)
            _lightObj->bVol = [[_dfltBnd alloc] init];
        if(EGW_CORECMP_TYPE_FLAGS & EGW_NODECMPMRG_LIGHT)
            _lightObj->flags = 0;
        if(EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_LIGHT)
            _lightObj->frame = EGW_FRAME_ALWAYSFAIL;
        if(EGW_CORECMP_TYPE_SOURCES & EGW_NODECMPMRG_LIGHT)
            egwVecCopy4f(&egwSIVecUnitW4f, &(_lightObj->source));
        if(EGW_CORECMP_TYPE_SYNCS & EGW_NODECMPMRG_LIGHT)
            _lightObj->sync = [[egwValidater alloc] initWithOwner:self validation:YES coreObjectTypes:EGW_COREOBJ_TYPE_LIGHT];
    }
}

- (void)decrementCoreObjectTypes:(EGWuint)coreObjects countBy:(EGWuint)count {
    if(coreObjects & EGW_COREOBJ_TYPE_AUDIO)
        _audioObjCount -= count;
    if(coreObjects & EGW_COREOBJ_TYPE_GRAPHIC)
        _graphicObjCount -= count;
    if(coreObjects & EGW_COREOBJ_TYPE_ANIMATE)
        _animateObjCount -= count;
    if(coreObjects & EGW_COREOBJ_TYPE_CAMERA)
        _cameraObjCount -= count;
    if(coreObjects & EGW_COREOBJ_TYPE_LIGHT)
        _lightObjCount -= count;
    
    if(_audioObj && !_audioObjCount) {
        [_audioObj->bVol release]; _audioObj->bVol = nil;
        [_audioObj->sync release]; _audioObj->sync = nil;
        free(_audioObj); _audioObj = NULL;
    }
    
    if(_graphicObj && !_graphicObjCount) {
        [_graphicObj->bVol release]; _graphicObj->bVol = nil;
        [_graphicObj->sync release]; _graphicObj->sync = nil;
        free(_graphicObj); _graphicObj = NULL;
    }
    
    if(_animateObj && !_animateObjCount) {
        [_animateObj->bVol release]; _animateObj->bVol = nil;
        [_animateObj->sync release]; _animateObj->sync = nil;
        free(_animateObj); _animateObj = NULL;
    }
    
    if(_cameraObj && !_cameraObjCount) {
        [_cameraObj->bVol release]; _cameraObj->bVol = nil;
        [_cameraObj->sync release]; _cameraObj->sync = nil;
        free(_cameraObj); _cameraObj = NULL;
    }
    
    if(_lightObj && !_lightObjCount) {
        [_lightObj->bVol release]; _lightObj->bVol = nil;
        [_lightObj->sync release]; _lightObj->sync = nil;
        free(_lightObj); _lightObj = NULL;
    }
}

- (BOOL)conformsToProtocol:(Protocol*)aProtocol {
    if([[self class] conformsToProtocol:aProtocol])
        return YES;
    else
        return [self conformsToProtocol:aProtocol inDirection:EGW_NODEMSG_DIR_DEFAULT];
}

- (BOOL)conformsToProtocol:(Protocol*)protocol inDirection:(EGWuint)direction {
    if(0xdeadc0de) {
        if(!(direction & EGW_NODEMSG_DIR_FULLBROADCAST)) {
            if(direction & EGW_NODEMSG_DIR_ORDERCSP) {
                if((direction & EGW_NODEMSG_DIR_TOCHILDREN) && _children && !_invkChild) {
                    for(id<egwPObjectNode> node in _children) {
                        if([node isLeaf]) {
                            _invkChild = YES;
                            
                            if(![node isInvokingParent] && [node conformsToProtocol:protocol]) {
                                _invkChild = NO;
                                return YES;
                            }
                            
                            _invkChild = NO;
                        } else {
                            _invkChild = YES;
                            
                            if([(id<egwPObjectBranch>)node conformsToProtocol:protocol inDirection:(direction | EGW_NODEMSG_DIR_TOSELF)]) {
                                _invkChild = NO;
                                return YES;
                            }
                            
                            _invkChild = NO;
                        }
                    }
                }
                
                if((direction & EGW_NODEMSG_DIR_TOSELF) && !_invkSelf) {
                    _invkSelf = YES;
                    
                    if([[self class] conformsToProtocol:protocol]) {
                        _invkSelf = NO;
                        return YES;
                    }
                    
                    _invkSelf = NO;
                }
                
                if((direction & EGW_NODEMSG_DIR_TOPARENTS) && _parent && !_invkParent && ![_parent isInvokingChild]) {
                    _invkParent = YES;
                    
                    if([_parent conformsToProtocol:protocol inDirection:(direction | EGW_NODEMSG_DIR_TOSELF)]) {
                        _invkParent = NO;
                        return YES;
                    }
                    
                    _invkParent = NO;
                }
            } else if(direction & EGW_NODEMSG_DIR_ORDERPSC) {
                if((direction & EGW_NODEMSG_DIR_TOPARENTS) && _parent && !_invkParent && ![_parent isInvokingChild]) {
                    _invkParent = YES;
                    
                    if([_parent conformsToProtocol:protocol inDirection:(direction | EGW_NODEMSG_DIR_TOSELF)]) {
                        _invkParent = NO;
                        return YES;
                    }
                    
                    _invkParent = NO;
                }
                
                if((direction & EGW_NODEMSG_DIR_TOSELF) && !_invkSelf) {
                    _invkSelf = YES;
                    
                    if([[self class] conformsToProtocol:protocol]) {
                        _invkSelf = NO;
                        return YES;
                    }
                    
                    _invkSelf = NO;
                }
                
                if((direction & EGW_NODEMSG_DIR_TOCHILDREN) && _children && !_invkChild) {
                    for(id<egwPObjectNode> node in _children) {
                        if([node isLeaf]) {
                            _invkChild = YES;
                            
                            if(![node isInvokingParent] && [node conformsToProtocol:protocol]) {
                                _invkChild = NO;
                                return YES;
                            }
                            
                            _invkChild = NO;
                        } else {
                            _invkChild = YES;
                            
                            if([(id<egwPObjectBranch>)node conformsToProtocol:protocol inDirection:(direction | EGW_NODEMSG_DIR_TOSELF)]) {
                                _invkChild = NO;
                                return YES;
                            }
                            
                            _invkChild = NO;
                        }
                    }
                }
            } else {
                if((direction & EGW_NODEMSG_DIR_TOSELF) && !_invkSelf) {
                    _invkSelf = YES;
                    
                    if([[self class] conformsToProtocol:protocol]) {
                        _invkSelf = NO;
                        return YES;
                    }
                    
                    _invkSelf = NO;
                }
            }
        } else
            return [[self root] conformsToProtocol:protocol inDirection:((direction & ~(EGW_NODEMSG_DIR_LINEBROADCAST | EGW_NODEMSG_DIR_FULLBROADCAST)) | (EGW_NODEMSG_DIR_TOSELF | EGW_NODEMSG_DIR_TOCHILDREN))];
    }
    
    return NO;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    if([[self class] instancesRespondToSelector:aSelector])
        return YES;
    else
        return [self respondsToSelector:aSelector inDirection:EGW_NODEMSG_DIR_DEFAULT];
}

- (BOOL)respondsToSelector:(SEL)selector inDirection:(EGWuint)direction {
    if(0xdeadc0de) {
        if(!(direction & EGW_NODEMSG_DIR_FULLBROADCAST)) {
            if(direction & EGW_NODEMSG_DIR_ORDERCSP) {
                if((direction & EGW_NODEMSG_DIR_TOCHILDREN) && _children && !_invkChild) {
                    for(id<egwPObjectNode> node in _children) {
                        if([node isLeaf]) {
                            _invkChild = YES;
                            
                            if(![node isInvokingParent] && [node respondsToSelector:selector]) {
                                _invkChild = NO;
                                return YES;
                            }
                            
                            _invkChild = NO;
                        } else {
                            _invkChild = YES;
                            
                            if([(id<egwPObjectBranch>)node respondsToSelector:selector inDirection:(direction | EGW_NODEMSG_DIR_TOSELF)]) {
                                _invkChild = NO;
                                return YES;
                            }
                            
                            _invkChild = NO;
                        }
                    }
                }
                
                if((direction & EGW_NODEMSG_DIR_TOSELF) && !_invkSelf) {
                    _invkSelf = YES;
                    
                    if([[self class] instancesRespondToSelector:selector]) {
                        _invkSelf = NO;
                        return YES;
                    }
                    
                    _invkSelf = NO;
                }
                
                if((direction & EGW_NODEMSG_DIR_TOPARENTS) && _parent && !_invkParent && ![_parent isInvokingChild]) {
                    _invkParent = YES;
                    
                    if([_parent respondsToSelector:selector inDirection:(direction | EGW_NODEMSG_DIR_TOSELF)]) {
                        _invkParent = NO;
                        return YES;
                    }
                    
                    _invkParent = NO;
                }
            } else if(direction & EGW_NODEMSG_DIR_ORDERPSC) {
                if((direction & EGW_NODEMSG_DIR_TOPARENTS) && _parent && !_invkParent && ![_parent isInvokingChild]) {
                    _invkParent = YES;
                    
                    if([_parent respondsToSelector:selector inDirection:(direction | EGW_NODEMSG_DIR_TOSELF)]) {
                        _invkParent = NO;
                        return YES;
                    }
                    
                    _invkParent = NO;
                }
                
                if((direction & EGW_NODEMSG_DIR_TOSELF) && !_invkSelf) {
                    _invkSelf = YES;
                    
                    if([[self class] instancesRespondToSelector:selector]) {
                        _invkSelf = NO;
                        return YES;
                    }
                    
                    _invkSelf = NO;
                }
                
                if((direction & EGW_NODEMSG_DIR_TOCHILDREN) && _children && !_invkChild) {
                    for(id<egwPObjectNode> node in _children) {
                        if([node isLeaf]) {
                            _invkChild = YES;
                            
                            if(![node isInvokingParent] && [node respondsToSelector:selector]) {
                                _invkChild = NO;
                                return YES;
                            }
                            
                            _invkChild = NO;
                        } else {
                            _invkChild = YES;
                            
                            if([(id<egwPObjectBranch>)node respondsToSelector:selector inDirection:(direction | EGW_NODEMSG_DIR_TOSELF)]) {
                                _invkChild = NO;
                                return YES;
                            }
                            
                            _invkChild = NO;
                        }
                    }
                }
            } else {
                if((direction & EGW_NODEMSG_DIR_TOSELF) && !_invkSelf) {
                    _invkSelf = YES;
                    
                    if([[self class] instancesRespondToSelector:selector]) {
                        _invkSelf = NO;
                        return YES;
                    }
                    
                    _invkSelf = NO;
                }
            }
        } else
            return [[self root] respondsToSelector:selector inDirection:((direction & ~(EGW_NODEMSG_DIR_LINEBROADCAST | EGW_NODEMSG_DIR_FULLBROADCAST)) | (EGW_NODEMSG_DIR_TOSELF | EGW_NODEMSG_DIR_TOCHILDREN))];
    }
    
    return NO;
}

- (id)performSelector:(SEL)aSelector {
    if([[self class] instancesRespondToSelector:aSelector])
        return [super performSelector:aSelector];
    else
        return [self performSelector:aSelector inDirection:EGW_NODEMSG_DIR_DEFAULT];
}

- (id)performSelector:(SEL)selector inDirection:(EGWuint)direction {
    id result = nil;
    
    if(0xdeadc0de) {
        if(!(direction & EGW_NODEMSG_DIR_FULLBROADCAST)) {
            if(direction & EGW_NODEMSG_DIR_ORDERCSP) {
                if((direction & EGW_NODEMSG_DIR_TOCHILDREN) && _children && !_invkChild) {
                    for(id<egwPObjectNode> node in _children) {
                        if([node isLeaf]) {
                            _invkChild = YES;
                            
                            if(![node isInvokingParent] && [node respondsToSelector:selector])
                                [node performSelector:selector];
                            
                            _invkChild = NO;
                        } else {
                            _invkChild = YES;
                            
                            [(id<egwPObjectBranch>)node performSelector:selector inDirection:(direction | EGW_NODEMSG_DIR_TOSELF)];
                            
                            _invkChild = NO;
                        }
                    }
                }
                
                if((direction & EGW_NODEMSG_DIR_TOSELF) && !_invkSelf) {
                    _invkSelf = YES;
                    
                    if([[self class] instancesRespondToSelector:selector])
                        result = [super performSelector:selector];
                    
                    _invkSelf = NO;
                }
                
                if((direction & EGW_NODEMSG_DIR_TOPARENTS) && _parent && !_invkParent && ![_parent isInvokingChild]) {
                    _invkParent = YES;
                    
                    [_parent performSelector:selector inDirection:(direction | EGW_NODEMSG_DIR_TOSELF)];
                    
                    _invkParent = NO;
                }
            } else if(direction & EGW_NODEMSG_DIR_ORDERPSC) {
                if((direction & EGW_NODEMSG_DIR_TOPARENTS) && _parent && !_invkParent && ![_parent isInvokingChild]) {
                    _invkParent = YES;
                    
                    [_parent performSelector:selector inDirection:(direction | EGW_NODEMSG_DIR_TOSELF)];
                    
                    _invkParent = NO;
                }
                
                if((direction & EGW_NODEMSG_DIR_TOSELF) && !_invkSelf) {
                    _invkSelf = YES;
                    
                    if([[self class] instancesRespondToSelector:selector])
                        result = [super performSelector:selector];
                    
                    _invkSelf = NO;
                }
                
                if((direction & EGW_NODEMSG_DIR_TOCHILDREN) && _children && !_invkChild) {
                    for(id<egwPObjectNode> node in _children) {
                        if([node isLeaf]) {
                            _invkChild = YES;
                            
                            if(![node isInvokingParent] && [node respondsToSelector:selector])
                                [node performSelector:selector];
                            
                            _invkChild = NO;
                        } else {
                            _invkChild = YES;
                            
                            [(id<egwPObjectBranch>)node performSelector:selector inDirection:(direction | EGW_NODEMSG_DIR_TOSELF)];
                            
                            _invkChild = NO;
                        }
                    }
                }
            } else {
                if((direction & EGW_NODEMSG_DIR_TOSELF) && !_invkSelf) {
                    _invkSelf = YES;
                    
                    if([[self class] instancesRespondToSelector:selector])
                        result = [super performSelector:selector];
                    
                    _invkSelf = NO;
                }
            }
        } else
            result = [[self root] performSelector:selector inDirection:((direction & ~(EGW_NODEMSG_DIR_LINEBROADCAST | EGW_NODEMSG_DIR_FULLBROADCAST)) | (EGW_NODEMSG_DIR_TOSELF | EGW_NODEMSG_DIR_TOCHILDREN))];
    }
    
    return result;
}

- (id)performSelector:(SEL)aSelector withObject:(id)object {
    if([[self class] instancesRespondToSelector:aSelector])
        return [super performSelector:aSelector withObject:object];
    else
        return [self performSelector:aSelector withObject:object inDirection:EGW_NODEMSG_DIR_DEFAULT];
}

- (id)performSelector:(SEL)selector withObject:(id)object inDirection:(EGWuint)direction {
    id result = nil;
    
    if(0xdeadc0de) {
        if(!(direction & EGW_NODEMSG_DIR_FULLBROADCAST)) {
            if(direction & EGW_NODEMSG_DIR_ORDERCSP) {
                if((direction & EGW_NODEMSG_DIR_TOCHILDREN) && _children && !_invkChild) {
                    for(id<egwPObjectNode> node in _children) {
                        if([node isLeaf]) {
                            _invkChild = YES;
                            
                            if(![node isInvokingParent] && [node respondsToSelector:selector])
                                [node performSelector:selector withObject:object];
                            
                            _invkChild = NO;
                        } else {
                            _invkChild = YES;
                            
                            [(id<egwPObjectBranch>)node performSelector:selector withObject:object inDirection:(direction | EGW_NODEMSG_DIR_TOSELF)];
                            
                            _invkChild = NO;
                        }
                    }
                }
                
                if((direction & EGW_NODEMSG_DIR_TOSELF) && !_invkSelf) {
                    _invkSelf = YES;
                    
                    if([[self class] instancesRespondToSelector:selector])
                        result = [super performSelector:selector withObject:object];
                    
                    _invkSelf = NO;
                }
                
                if((direction & EGW_NODEMSG_DIR_TOPARENTS) && _parent && !_invkParent && ![_parent isInvokingChild]) {
                    _invkParent = YES;
                    
                    [_parent performSelector:selector withObject:object inDirection:(direction | EGW_NODEMSG_DIR_TOSELF)];
                    
                    _invkParent = NO;
                }
            } else if(direction & EGW_NODEMSG_DIR_ORDERPSC) {
                if((direction & EGW_NODEMSG_DIR_TOPARENTS) && _parent && !_invkParent && ![_parent isInvokingChild]) {
                    _invkParent = YES;
                    
                    [_parent performSelector:selector withObject:object inDirection:(direction | EGW_NODEMSG_DIR_TOSELF)];
                    
                    _invkParent = NO;
                }
                
                if((direction & EGW_NODEMSG_DIR_TOSELF) && !_invkSelf) {
                    _invkSelf = YES;
                    
                    if([[self class] instancesRespondToSelector:selector])
                        result = [super performSelector:selector withObject:object];
                    
                    _invkSelf = NO;
                }
                
                if((direction & EGW_NODEMSG_DIR_TOCHILDREN) && _children && !_invkChild) {
                    for(id<egwPObjectNode> node in _children) {
                        if([node isLeaf]) {
                            _invkChild = YES;
                            
                            if(![node isInvokingParent] && [node respondsToSelector:selector])
                                [node performSelector:selector withObject:object];
                            
                            _invkChild = NO;
                        } else {
                            _invkChild = YES;
                            
                            [(id<egwPObjectBranch>)node performSelector:selector withObject:object inDirection:(direction | EGW_NODEMSG_DIR_TOSELF)];
                            
                            _invkChild = NO;
                        }
                    }
                }
            } else {
                if((direction & EGW_NODEMSG_DIR_TOSELF) && !_invkSelf) {
                    _invkSelf = YES;
                    
                    if([[self class] instancesRespondToSelector:selector])
                        result = [super performSelector:selector withObject:object];
                    
                    _invkSelf = NO;
                }
            }
        } else
            result = [[self root] performSelector:selector withObject:object inDirection:((direction & ~(EGW_NODEMSG_DIR_LINEBROADCAST | EGW_NODEMSG_DIR_FULLBROADCAST)) | (EGW_NODEMSG_DIR_TOSELF | EGW_NODEMSG_DIR_TOCHILDREN))];
    }
    
    return result;
}

- (id)performSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2 {
    if([[self class] instancesRespondToSelector:aSelector])
        return [super performSelector:aSelector withObject:object1 withObject:object2];
    else
        return [self performSelector:aSelector withObject:object1 withObject:object2 inDirection:EGW_NODEMSG_DIR_DEFAULT];
}

- (id)performSelector:(SEL)selector withObject:(id)object1 withObject:(id)object2 inDirection:(EGWuint)direction {
    id result = nil;
    
    if(0xdeadc0de) {
        if(!(direction & EGW_NODEMSG_DIR_FULLBROADCAST)) {
            if(direction & EGW_NODEMSG_DIR_ORDERCSP) {
                if((direction & EGW_NODEMSG_DIR_TOCHILDREN) && _children && !_invkChild) {
                    for(id<egwPObjectNode> node in _children) {
                        if([node isLeaf]) {
                            _invkChild = YES;
                            
                            if(![node isInvokingParent] && [node respondsToSelector:selector])
                                [node performSelector:selector withObject:object1 withObject:object2];
                            
                            _invkChild = NO;
                        } else {
                            _invkChild = YES;
                            
                            [(id<egwPObjectBranch>)node performSelector:selector withObject:object1 withObject:object2 inDirection:(direction | EGW_NODEMSG_DIR_TOSELF)];
                            
                            _invkChild = NO;
                        }
                    }
                }
                
                if((direction & EGW_NODEMSG_DIR_TOSELF) && !_invkSelf) {
                    _invkSelf = YES;
                    
                    if([[self class] instancesRespondToSelector:selector])
                        result = [super performSelector:selector withObject:object1 withObject:object2];
                    
                    _invkSelf = NO;
                }
                
                if((direction & EGW_NODEMSG_DIR_TOPARENTS) && _parent && !_invkParent && ![_parent isInvokingChild]) {
                    _invkParent = YES;
                    
                    [_parent performSelector:selector withObject:object1 withObject:object2 inDirection:(direction | EGW_NODEMSG_DIR_TOSELF)];
                    
                    _invkParent = NO;
                }
            } else if(direction & EGW_NODEMSG_DIR_ORDERPSC) {
                if((direction & EGW_NODEMSG_DIR_TOPARENTS) && _parent && !_invkParent && ![_parent isInvokingChild]) {
                    _invkParent = YES;
                    
                    [_parent performSelector:selector withObject:object1 withObject:object2 inDirection:(direction | EGW_NODEMSG_DIR_TOSELF)];
                    
                    _invkParent = NO;
                }
                
                if((direction & EGW_NODEMSG_DIR_TOSELF) && !_invkSelf) {
                    _invkSelf = YES;
                    
                    if([[self class] instancesRespondToSelector:selector])
                        result = [super performSelector:selector withObject:object1 withObject:object2];
                    
                    _invkSelf = NO;
                }
                
                if((direction & EGW_NODEMSG_DIR_TOCHILDREN) && _children && !_invkChild) {
                    for(id<egwPObjectNode> node in _children) {
                        if([node isLeaf]) {
                            _invkChild = YES;
                            
                            if(![node isInvokingParent] && [node respondsToSelector:selector])
                                [node performSelector:selector withObject:object1 withObject:object2];
                            
                            _invkChild = NO;
                        } else {
                            _invkChild = YES;
                            
                            [(id<egwPObjectBranch>)node performSelector:selector withObject:object1 withObject:object2 inDirection:(direction | EGW_NODEMSG_DIR_TOSELF)];
                            
                            _invkChild = NO;
                        }
                    }
                }
            } else {
                if((direction & EGW_NODEMSG_DIR_TOSELF) && !_invkSelf) {
                    _invkSelf = YES;
                    
                    if([[self class] instancesRespondToSelector:selector])
                        result = [super performSelector:selector withObject:object1 withObject:object2];
                    
                    _invkSelf = NO;
                }
            }
        } else
            result = [[self root] performSelector:selector withObject:object1 withObject:object2 inDirection:((direction & ~(EGW_NODEMSG_DIR_LINEBROADCAST | EGW_NODEMSG_DIR_FULLBROADCAST)) | (EGW_NODEMSG_DIR_TOSELF | EGW_NODEMSG_DIR_TOCHILDREN))];
    }
    
    return result;
}

- (void)mergeCoreComponentTypes:(EGWuint)coreCmpnts forCoreObjectTypes:(EGWuint)coreObjects {
    if(0xdeadc0de) {
        if(_children && [_children count]) {
            id result;
            
            if(coreCmpnts & EGW_CORECMP_TYPE_INTERNAL) {
                _cType = [self baseCoreObjectType];
                
                for(id<egwPObjectNode> node in _children)
                    _cType |= [node coreObjectTypes];
            }
            
            if((coreObjects & (EGW_COREOBJ_TYPE_AUDIO | EGW_COREOBJ_TYPE_NODE)) && _audioObj) {
                if(coreCmpnts & EGW_CORECMP_TYPE_BVOLS & EGW_NODECMPMRG_AUDIO) {
                    [_audioObj->bVol reset];
                    
                    for(id<egwPObjectNode> node in _children) {
                        _invkChild = YES;
                        
                        if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_AUDIO) &&
                           !((EGWuint)[node performSelector:@selector(playbackFlags)] & EGW_OBJTREE_FLG_NOUMRGBVOLS)) {
                            if([node isLeaf])
                                result = [node performSelector:@selector(playbackBounding)];
                            else
                                result = [(id<egwPObjectBranch>)node performSelector:@selector(playbackBounding) inDirection:EGW_NODEMSG_DIR_TOSELF];
                            
                            if(result && [result class] != [egwZeroBounding class])
                                [_audioObj->bVol mergeWithVolume:(id<egwPBounding>)result];
                        }
                        
                        _invkChild = NO;
                    }
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_FLAGS & EGW_NODECMPMRG_AUDIO) {
                    _audioObj->flags = EGW_OBJTREE_FLG_EXNOUMRG;
                    
                    for(id<egwPObjectNode> node in _children) {
                        _invkChild = YES;
                        
                        if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_AUDIO) &&
                           !((EGWuint)[node performSelector:@selector(playbackFlags)] & EGW_OBJTREE_FLG_NOUMRGFLAGS)) {
                            if([node isLeaf])
                                result = [node performSelector:@selector(playbackFlags)];
                            else
                                result = [(id<egwPObjectBranch>)node performSelector:@selector(playbackFlags) inDirection:EGW_NODEMSG_DIR_TOSELF];
                            
                            _audioObj->flags = (_audioObj->flags | ((EGWuint)result & ~EGW_OBJTREE_FLG_EXNOUMRG)) & ~(_audioObj->flags & (EGWuint)result & EGW_OBJTREE_FLG_EXNOUMRG);
                        }
                        
                        _invkChild = NO;
                    }
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_AUDIO) {
                    _audioObj->frame = EGW_FRAME_ALWAYSFAIL;
                    
                    for(id<egwPObjectNode> node in _children) {
                        _invkChild = YES;
                        
                        if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_AUDIO) &&
                           !((EGWuint)[node performSelector:@selector(playbackFlags)] & EGW_OBJTREE_FLG_NOUMRGFRAMES)) {
                            if([node isLeaf])
                                result = [node performSelector:@selector(playbackFrame)];
                            else
                                result = [(id<egwPObjectBranch>)node performSelector:@selector(playbackFrame) inDirection:EGW_NODEMSG_DIR_TOSELF];
                            
                            if((EGWuint16)(EGWuint)result < _audioObj->frame)
                                _audioObj->frame = (EGWuint16)(EGWuint)result;
                        }
                        
                        _invkChild = NO;
                    }
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_SOURCES & EGW_NODECMPMRG_AUDIO) {
                    egwVecCopy3f(&egwSIVecZero3f, (egwVector3f*)&(_audioObj->source));
                    
                    for(id<egwPObjectNode> node in _children) {
                        _invkChild = YES;
                        
                        if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_AUDIO) &&
                           !((EGWuint)[node performSelector:@selector(playbackFlags)] & EGW_OBJTREE_FLG_NOUMRGSOURCES)) {
                            if([node isLeaf])
                                result = [node performSelector:@selector(playbackSource)];
                            else
                                result = [(id<egwPObjectBranch>)node performSelector:@selector(playbackSource) inDirection:EGW_NODEMSG_DIR_TOSELF];
                            
                            if(result)
                                egwVecAdd3f((egwVector3f*)&(_audioObj->source), (egwVector3f*)result, (egwVector3f*)&(_audioObj->source));
                        }
                        
                        _invkChild = NO;
                    }
                    
                    if([_children count] > 1)
                        egwVecUScale3f((egwVector3f*)&(_audioObj->source), 1.0f / (EGWsingle)[_children count], (egwVector3f*)&(_audioObj->source));
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_SYNCS & EGW_NODECMPMRG_AUDIO) {
                    [_audioObj->sync performSelector:@selector(backdoor_setValidation:) withObject:(id)YES];
                    
                    for(id<egwPObjectNode> node in _children) {
                        _invkChild = YES;
                        
                        if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_AUDIO) &&
                           !((EGWuint)[node performSelector:@selector(playbackFlags)] & EGW_OBJTREE_FLG_NOUMRGSYNCS)) {
                            if([node isLeaf])
                                result = [node performSelector:@selector(playbackSync)];
                            else
                                result = [(id<egwPObjectBranch>)node performSelector:@selector(playbackSync) inDirection:EGW_NODEMSG_DIR_TOSELF];
                            
                            if(result && [(egwValidater*)result isInvalidated]) {
                                [_audioObj->sync performSelector:@selector(backdoor_setValidation:) withObject:(id)NO];
                                _invkChild = NO;
                                break;
                            }
                        }
                        
                        _invkChild = NO;
                    }
                }
            }
            
            if((coreObjects & (EGW_COREOBJ_TYPE_GRAPHIC | EGW_COREOBJ_TYPE_NODE)) && _graphicObj) {
                if(coreCmpnts & EGW_CORECMP_TYPE_BVOLS & EGW_NODECMPMRG_GRAPHIC) {
                    [_graphicObj->bVol reset];
                    
                    for(id<egwPObjectNode> node in _children) {
                        _invkChild = YES;
                        
                        if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_GRAPHIC) &&
                           !((EGWuint)[node performSelector:@selector(renderingFlags)] & EGW_OBJTREE_FLG_NOUMRGBVOLS)) {
                            if([node isLeaf])
                                result = [node performSelector:@selector(renderingBounding)];
                            else
                                result = [(id<egwPObjectBranch>)node performSelector:@selector(renderingBounding) inDirection:EGW_NODEMSG_DIR_TOSELF];
                            
                            if(result && [result class] != [egwZeroBounding class])
                                [_graphicObj->bVol mergeWithVolume:(id<egwPBounding>)result];
                        }
                        
                        _invkChild = NO;
                    }
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_FLAGS & EGW_NODECMPMRG_GRAPHIC) {
                    _graphicObj->flags = EGW_OBJTREE_FLG_EXNOUMRG;
                    
                    for(id<egwPObjectNode> node in _children) {
                        _invkChild = YES;
                        
                        if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_GRAPHIC) &&
                           !((EGWuint)[node performSelector:@selector(renderingFlags)] & EGW_OBJTREE_FLG_NOUMRGFLAGS)) {
                            if([node isLeaf])
                                result = [node performSelector:@selector(renderingFlags)];
                            else
                                result = [(id<egwPObjectBranch>)node performSelector:@selector(renderingFlags) inDirection:EGW_NODEMSG_DIR_TOSELF];
                            
                            _graphicObj->flags = (_graphicObj->flags | ((EGWuint)result & ~EGW_OBJTREE_FLG_EXNOUMRG)) & ~(_graphicObj->flags & (EGWuint)result & EGW_OBJTREE_FLG_EXNOUMRG);
                        }
                        
                        _invkChild = NO;
                    }
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_GRAPHIC) {
                    _graphicObj->frame = EGW_FRAME_ALWAYSFAIL;
                    
                    for(id<egwPObjectNode> node in _children) {
                        _invkChild = YES;
                        
                        if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_GRAPHIC) &&
                           !((EGWuint)[node performSelector:@selector(renderingFlags)] & EGW_OBJTREE_FLG_NOUMRGFRAMES)) {
                            if([node isLeaf])
                                result = [node performSelector:@selector(renderingFrame)];
                            else
                                result = [(id<egwPObjectBranch>)node performSelector:@selector(renderingFrame) inDirection:EGW_NODEMSG_DIR_TOSELF];
                            
                            if((EGWuint16)(EGWuint)result < _graphicObj->frame)
                                _graphicObj->frame = (EGWuint16)(EGWuint)result;
                        }
                        
                        _invkChild = NO;
                    }
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_SOURCES & EGW_NODECMPMRG_GRAPHIC) {
                    egwVecCopy3f(&egwSIVecZero3f, (egwVector3f*)&(_graphicObj->source));
                    
                    for(id<egwPObjectNode> node in _children) {
                        _invkChild = YES;
                        
                        if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_GRAPHIC) &&
                           !((EGWuint)[node performSelector:@selector(renderingFlags)] & EGW_OBJTREE_FLG_NOUMRGSOURCES)) {
                            if([node isLeaf])
                                result = [node performSelector:@selector(renderingSource)];
                            else
                                result = [(id<egwPObjectBranch>)node performSelector:@selector(renderingSource) inDirection:EGW_NODEMSG_DIR_TOSELF];
                            
                            if(result)
                                egwVecAdd3f((egwVector3f*)&(_graphicObj->source), (egwVector3f*)result, (egwVector3f*)&(_graphicObj->source));
                        }
                        
                        _invkChild = NO;
                    }
                    
                    if([_children count] > 1)
                        egwVecUScale3f((egwVector3f*)&(_graphicObj->source), 1.0f / (EGWsingle)[_children count], (egwVector3f*)&(_graphicObj->source));
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_SYNCS & EGW_NODECMPMRG_GRAPHIC) {
                    [_graphicObj->sync performSelector:@selector(backdoor_setValidation:) withObject:(id)YES];
                    
                    for(id<egwPObjectNode> node in _children) {
                        _invkChild = YES;
                        
                        if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_GRAPHIC) &&
                           !((EGWuint)[node performSelector:@selector(renderingFlags)] & EGW_OBJTREE_FLG_NOUMRGSYNCS)) {
                            if([node isLeaf])
                                result = [node performSelector:@selector(renderingSync)];
                            else
                                result = [(id<egwPObjectBranch>)node performSelector:@selector(renderingSync) inDirection:EGW_NODEMSG_DIR_TOSELF];
                            
                            if(result && [(egwValidater*)result isInvalidated]) {
                                [_graphicObj->sync performSelector:@selector(backdoor_setValidation:) withObject:(id)NO];
                                _invkChild = NO;
                                break;
                            }
                        }
                        
                        _invkChild = NO;
                    }
                }
            }
            
            if((coreObjects & (EGW_COREOBJ_TYPE_ANIMATE | EGW_COREOBJ_TYPE_NODE)) && _animateObj) {
                if(coreCmpnts & EGW_CORECMP_TYPE_BVOLS & EGW_NODECMPMRG_ANIMATE) {
                    [_animateObj->bVol reset];
                    
                    for(id<egwPObjectNode> node in _children) {
                        _invkChild = YES;
                        
                        if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_ANIMATE) &&
                           !((EGWuint)[node performSelector:@selector(interactionFlags)] & EGW_OBJTREE_FLG_NOUMRGBVOLS)) {
                            if([node isLeaf])
                                result = [node performSelector:@selector(interactionBounding)];
                            else
                                result = [(id<egwPObjectBranch>)node performSelector:@selector(interactionBounding) inDirection:EGW_NODEMSG_DIR_TOSELF];
                            
                            if(result && [result class] != [egwZeroBounding class])
                                [_animateObj->bVol mergeWithVolume:(id<egwPBounding>)result];
                        }
                        
                        _invkChild = NO;
                    }
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_FLAGS & EGW_NODECMPMRG_ANIMATE) {
                    _animateObj->flags = EGW_OBJTREE_FLG_EXNOUMRG;
                    
                    for(id<egwPObjectNode> node in _children) {
                        _invkChild = YES;
                        
                        if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_ANIMATE) &&
                           !((EGWuint)[node performSelector:@selector(interactionFlags)] & EGW_OBJTREE_FLG_NOUMRGFLAGS)) {
                            if([node isLeaf])
                                result = [node performSelector:@selector(interactionFlags)];
                            else
                                result = [(id<egwPObjectBranch>)node performSelector:@selector(interactionFlags) inDirection:EGW_NODEMSG_DIR_TOSELF];
                            
                            _animateObj->flags = (_animateObj->flags | ((EGWuint)result & ~EGW_OBJTREE_FLG_EXNOUMRG)) & ~(_animateObj->flags & (EGWuint)result & EGW_OBJTREE_FLG_EXNOUMRG);
                        }
                        
                        _invkChild = NO;
                    }
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_ANIMATE) {
                    _animateObj->frame = EGW_FRAME_ALWAYSFAIL;
                    
                    for(id<egwPObjectNode> node in _children) {
                        _invkChild = YES;
                        
                        if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_ANIMATE) &&
                           !((EGWuint)[node performSelector:@selector(interactionFlags)] & EGW_OBJTREE_FLG_NOUMRGFRAMES)) {
                            if([node isLeaf])
                                result = [node performSelector:@selector(interactionFrame)];
                            else
                                result = [(id<egwPObjectBranch>)node performSelector:@selector(interactionFrame) inDirection:EGW_NODEMSG_DIR_TOSELF];
                            
                            if((EGWuint16)(EGWuint)result < _animateObj->frame)
                                _animateObj->frame = (EGWuint16)(EGWuint)result;
                        }
                        
                        _invkChild = NO;
                    }
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_SOURCES & EGW_NODECMPMRG_ANIMATE) {
                    egwVecCopy3f(&egwSIVecZero3f, (egwVector3f*)&(_animateObj->source));
                    
                    for(id<egwPObjectNode> node in _children) {
                        _invkChild = YES;
                        
                        if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_ANIMATE) &&
                           !((EGWuint)[node performSelector:@selector(interactionFlags)] & EGW_OBJTREE_FLG_NOUMRGSOURCES)) {
                            if([node isLeaf])
                                result = [node performSelector:@selector(interactionSource)];
                            else
                                result = [(id<egwPObjectBranch>)node performSelector:@selector(interactionSource) inDirection:EGW_NODEMSG_DIR_TOSELF];
                            
                            if(result)
                                egwVecAdd3f((egwVector3f*)&(_animateObj->source), (egwVector3f*)result, (egwVector3f*)&(_animateObj->source));
                        }
                        
                        _invkChild = NO;
                    }
                    
                    if([_children count] > 1)
                        egwVecUScale3f((egwVector3f*)&(_animateObj->source), 1.0f / (EGWsingle)[_children count], (egwVector3f*)&(_animateObj->source));
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_SYNCS & EGW_NODECMPMRG_ANIMATE) {
                    [_animateObj->sync performSelector:@selector(backdoor_setValidation:) withObject:(id)YES];
                    
                    for(id<egwPObjectNode> node in _children) {
                        _invkChild = YES;
                        
                        if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_ANIMATE) &&
                           !((EGWuint)[node performSelector:@selector(interactionFlags)] & EGW_OBJTREE_FLG_NOUMRGSYNCS)) {
                            if([node isLeaf])
                                result = [node performSelector:@selector(interactionSync)];
                            else
                                result = [(id<egwPObjectBranch>)node performSelector:@selector(interactionSync) inDirection:EGW_NODEMSG_DIR_TOSELF];
                            
                            if(result && [(egwValidater*)result isInvalidated]) {
                                [_animateObj->sync performSelector:@selector(backdoor_setValidation:) withObject:(id)NO];
                                _invkChild = NO;
                                break;
                            }
                        }
                        
                        _invkChild = NO;
                    }
                }
            }
            
            if((coreObjects & (EGW_COREOBJ_TYPE_CAMERA | EGW_COREOBJ_TYPE_NODE)) && _cameraObj) {
                if(coreCmpnts & EGW_CORECMP_TYPE_BVOLS & EGW_NODECMPMRG_CAMERA) {
                    [_cameraObj->bVol reset];
                    
                    for(id<egwPObjectNode> node in _children) {
                        _invkChild = YES;
                        
                        if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_CAMERA) &&
                           !((EGWuint)[node performSelector:@selector(viewingFlags)] & EGW_OBJTREE_FLG_NOUMRGBVOLS)) {
                            if([node isLeaf])
                                result = [node performSelector:@selector(viewingBounding)];
                            else
                                result = [(id<egwPObjectBranch>)node performSelector:@selector(viewingBounding) inDirection:EGW_NODEMSG_DIR_TOSELF];
                            
                            if(result && [result class] != [egwZeroBounding class])
                                [_cameraObj->bVol mergeWithVolume:(id<egwPBounding>)result];
                        }
                        
                        _invkChild = NO;
                    }
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_FLAGS & EGW_NODECMPMRG_CAMERA) {
                    _cameraObj->flags = EGW_OBJTREE_FLG_EXNOUMRG;
                    
                    for(id<egwPObjectNode> node in _children) {
                        _invkChild = YES;
                        
                        if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_CAMERA) &&
                           !((EGWuint)[node performSelector:@selector(viewingFlags)] & EGW_OBJTREE_FLG_NOUMRGFLAGS)) {
                            if([node isLeaf])
                                result = [node performSelector:@selector(viewingFlags)];
                            else
                                result = [(id<egwPObjectBranch>)node performSelector:@selector(viewingFlags) inDirection:EGW_NODEMSG_DIR_TOSELF];
                            
                            _cameraObj->flags = (_cameraObj->flags | ((EGWuint)result & ~EGW_OBJTREE_FLG_EXNOUMRG)) & ~(_cameraObj->flags & (EGWuint)result & EGW_OBJTREE_FLG_EXNOUMRG);
                        }
                        
                        _invkChild = NO;
                    }
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_CAMERA) {
                    _cameraObj->frame = EGW_FRAME_ALWAYSFAIL;
                    
                    for(id<egwPObjectNode> node in _children) {
                        _invkChild = YES;
                        
                        if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_CAMERA) &&
                           !((EGWuint)[node performSelector:@selector(viewingFlags)] & EGW_OBJTREE_FLG_NOUMRGFRAMES)) {
                            if([node isLeaf])
                                result = [node performSelector:@selector(viewingFrame)];
                            else
                                result = [(id<egwPObjectBranch>)node performSelector:@selector(viewingFrame) inDirection:EGW_NODEMSG_DIR_TOSELF];
                            
                            if((EGWuint16)(EGWuint)result < _cameraObj->frame)
                                _cameraObj->frame = (EGWuint16)(EGWuint)result;
                        }
                        
                        _invkChild = NO;
                    }
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_SOURCES & EGW_NODECMPMRG_CAMERA) {
                    egwVecCopy3f(&egwSIVecZero3f, (egwVector3f*)&(_cameraObj->source));
                    
                    for(id<egwPObjectNode> node in _children) {
                        _invkChild = YES;
                        
                        if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_CAMERA) &&
                           !((EGWuint)[node performSelector:@selector(viewingFlags)] & EGW_OBJTREE_FLG_NOUMRGSOURCES)) {
                            if([node isLeaf])
                                result = [node performSelector:@selector(viewingSource)];
                            else
                                result = [(id<egwPObjectBranch>)node performSelector:@selector(viewingSource) inDirection:EGW_NODEMSG_DIR_TOSELF];
                            
                            if(result)
                                egwVecAdd3f((egwVector3f*)&(_cameraObj->source), (egwVector3f*)result, (egwVector3f*)&(_cameraObj->source));
                        }
                        
                        _invkChild = NO;
                    }
                    
                    if([_children count] > 1)
                        egwVecUScale3f((egwVector3f*)&(_cameraObj->source), 1.0f / (EGWsingle)[_children count], (egwVector3f*)&(_cameraObj->source));
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_SYNCS & EGW_NODECMPMRG_CAMERA) {
                    [_cameraObj->sync performSelector:@selector(backdoor_setValidation:) withObject:(id)YES];
                    
                    for(id<egwPObjectNode> node in _children) {
                        _invkChild = YES;
                        
                        if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_CAMERA) &&
                           !((EGWuint)[node performSelector:@selector(viewingFlags)] & EGW_OBJTREE_FLG_NOUMRGSYNCS)) {
                            if([node isLeaf])
                                result = [node performSelector:@selector(viewingSync)];
                            else
                                result = [(id<egwPObjectBranch>)node performSelector:@selector(viewingSync) inDirection:EGW_NODEMSG_DIR_TOSELF];
                            
                            if(result && [(egwValidater*)result isInvalidated]) {
                                [_cameraObj->sync performSelector:@selector(backdoor_setValidation:) withObject:(id)NO];
                                _invkChild = NO;
                                break;
                            }
                        }
                        
                        _invkChild = NO;
                    }
                }
            }
            
            if((coreObjects & (EGW_COREOBJ_TYPE_LIGHT | EGW_COREOBJ_TYPE_NODE)) && _lightObj) {
                if(coreCmpnts & EGW_CORECMP_TYPE_BVOLS & EGW_NODECMPMRG_LIGHT) {
                    [_lightObj->bVol reset];
                    
                    for(id<egwPObjectNode> node in _children) {
                        _invkChild = YES;
                        
                        if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_LIGHT) &&
                           !((EGWuint)[node performSelector:@selector(illuminationFlags)] & EGW_OBJTREE_FLG_NOUMRGBVOLS)) {
                            if([node isLeaf])
                                result = [node performSelector:@selector(illuminationBounding)];
                            else
                                result = [(id<egwPObjectBranch>)node performSelector:@selector(illuminationBounding) inDirection:EGW_NODEMSG_DIR_TOSELF];
                            
                            if(result && [result class] != [egwZeroBounding class])
                                [_lightObj->bVol mergeWithVolume:(id<egwPBounding>)result];
                        }
                        
                        _invkChild = NO;
                    }
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_FLAGS & EGW_NODECMPMRG_LIGHT) {
                    _lightObj->flags = EGW_OBJTREE_FLG_EXNOUMRG;
                    
                    for(id<egwPObjectNode> node in _children) {
                        _invkChild = YES;
                        
                        if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_LIGHT) &&
                           !((EGWuint)[node performSelector:@selector(illuminationFlags)] & EGW_OBJTREE_FLG_NOUMRGFLAGS)) {
                            if([node isLeaf])
                                result = [node performSelector:@selector(illuminationFlags)];
                            else
                                result = [(id<egwPObjectBranch>)node performSelector:@selector(illuminationFlags) inDirection:EGW_NODEMSG_DIR_TOSELF];
                            
                            _lightObj->flags = (_lightObj->flags | ((EGWuint)result & ~EGW_OBJTREE_FLG_EXNOUMRG)) & ~(_lightObj->flags & (EGWuint)result & EGW_OBJTREE_FLG_EXNOUMRG);
                        }
                        
                        _invkChild = NO;
                    }
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_LIGHT) {
                    _lightObj->frame = EGW_FRAME_ALWAYSFAIL;
                    
                    for(id<egwPObjectNode> node in _children) {
                        _invkChild = YES;
                        
                        if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_LIGHT) &&
                           !((EGWuint)[node performSelector:@selector(illuminationFlags)] & EGW_OBJTREE_FLG_NOUMRGFRAMES)) {
                            if([node isLeaf])
                                result = [node performSelector:@selector(illuminationFrame)];
                            else
                                result = [(id<egwPObjectBranch>)node performSelector:@selector(illuminationFrame) inDirection:EGW_NODEMSG_DIR_TOSELF];
                            
                            if((EGWuint16)(EGWuint)result < _lightObj->frame)
                                _lightObj->frame = (EGWuint16)(EGWuint)result;
                        }
                        
                        _invkChild = NO;
                    }
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_SOURCES & EGW_NODECMPMRG_LIGHT) {
                    egwVecCopy3f(&egwSIVecZero3f, (egwVector3f*)&(_lightObj->source));
                    
                    for(id<egwPObjectNode> node in _children) {
                        _invkChild = YES;
                        
                        if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_LIGHT) &&
                           !((EGWuint)[node performSelector:@selector(illuminationFlags)] & EGW_OBJTREE_FLG_NOUMRGSOURCES)) {
                            if([node isLeaf])
                                result = [node performSelector:@selector(illuminationSource)];
                            else
                                result = [(id<egwPObjectBranch>)node performSelector:@selector(illuminationSource) inDirection:EGW_NODEMSG_DIR_TOSELF];
                            
                            if(result)
                                egwVecAdd3f((egwVector3f*)&(_lightObj->source), (egwVector3f*)result, (egwVector3f*)&(_lightObj->source));
                        }
                        
                        _invkChild = NO;
                    }
                    
                    if([_children count] > 1)
                        egwVecUScale3f((egwVector3f*)&(_lightObj->source), 1.0f / (EGWsingle)[_children count], (egwVector3f*)&(_lightObj->source));
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_SYNCS & EGW_NODECMPMRG_LIGHT) {
                    [_lightObj->sync performSelector:@selector(backdoor_setValidation:) withObject:(id)YES];
                    
                    for(id<egwPObjectNode> node in _children) {
                        _invkChild = YES;
                        
                        if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_LIGHT) &&
                           !((EGWuint)[node performSelector:@selector(illuminationFlags)] & EGW_OBJTREE_FLG_NOUMRGSYNCS)) {
                            if([node isLeaf])
                                result = [node performSelector:@selector(illuminationSync)];
                            else
                                result = [(id<egwPObjectBranch>)node performSelector:@selector(illuminationSync) inDirection:EGW_NODEMSG_DIR_TOSELF];
                            
                            if(result && [(egwValidater*)result isInvalidated]) {
                                [_lightObj->sync performSelector:@selector(backdoor_setValidation:) withObject:(id)NO];
                                _invkChild = NO;
                                break;
                            }
                        }
                        
                        _invkChild = NO;
                    }
                }
            }
        }
        
        if(![self isAnybodyInvoking])
            [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)coreCmpnts withObject:(id)coreObjects inDirection:(EGW_NODEMSG_DIR_TOPARENTS | EGW_NODEMSG_DIR_ORDERCSP)];
    }
}

- (void)reboundWithClass:(Class)bndClass forCoreObjectTypes:(EGWuint)coreObjects {
    if(0xdeadc0de) {
        id<egwPBounding> newBVol = nil;
        
        if(!bndClass || ![bndClass conformsToProtocol:@protocol(egwPBounding)]) bndClass = [egwBoundingSphere class];
        
        if((coreObjects & (EGW_COREOBJ_TYPE_INTERNAL | EGW_COREOBJ_TYPE_NODE)) && _dfltBnd != bndClass)
            _dfltBnd = bndClass;
        
        if((coreObjects & (EGW_COREOBJ_TYPE_AUDIO | EGW_COREOBJ_TYPE_NODE)) && _audioObj && [_audioObj->bVol class] != bndClass) {
            newBVol = [[bndClass alloc] init];
            [newBVol mergeWithVolume:(_audioObj->bVol)];
            [_audioObj->bVol release]; _audioObj->bVol = newBVol; newBVol = nil;
        }
        
        if((coreObjects & (EGW_COREOBJ_TYPE_GRAPHIC | EGW_COREOBJ_TYPE_NODE)) && _graphicObj && [_graphicObj->bVol class] != bndClass) {
            newBVol = [[bndClass alloc] init];
            [newBVol mergeWithVolume:(_graphicObj->bVol)];
            [_graphicObj->bVol release]; _graphicObj->bVol = newBVol; newBVol = nil;
        }
        
        if((coreObjects & (EGW_COREOBJ_TYPE_ANIMATE | EGW_COREOBJ_TYPE_NODE)) && _animateObj && [_animateObj->bVol class] != bndClass) {
            newBVol = [[bndClass alloc] init];
            [newBVol mergeWithVolume:(_animateObj->bVol)];
            [_animateObj->bVol release]; _animateObj->bVol = newBVol; newBVol = nil;
        }
        
        if((coreObjects & (EGW_COREOBJ_TYPE_CAMERA | EGW_COREOBJ_TYPE_NODE)) && _cameraObj && [_cameraObj->bVol class] != bndClass) {
            newBVol = [[bndClass alloc] init];
            [newBVol mergeWithVolume:(_cameraObj->bVol)];
            [_cameraObj->bVol release]; _cameraObj->bVol = newBVol; newBVol = nil;
        }
        
        if((coreObjects & (EGW_COREOBJ_TYPE_LIGHT | EGW_COREOBJ_TYPE_NODE)) && _lightObj && [_lightObj->bVol class] != bndClass) {
            newBVol = [[bndClass alloc] init];
            [newBVol mergeWithVolume:(_lightObj->bVol)];
            [_lightObj->bVol release]; _lightObj->bVol = newBVol; newBVol = nil;
        }
        
        if(![self isAnybodyInvoking])
            [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_CORECMP_TYPE_BVOLS withObject:(id)coreObjects inDirection:(EGW_NODEMSG_DIR_TOPARENTS | EGW_NODEMSG_DIR_ORDERCSP)];
    }
}

- (void)forwardInvocation:(NSInvocation*)anInvocation {
    for(id<egwPObjectNode> node in _children)
        if([node respondsToSelector:[anInvocation selector]])
            [anInvocation invokeWithTarget:node];
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector {
    for(id<egwPObjectNode> node in _children)
        if([node respondsToSelector:aSelector])
            return [(NSObject*)node methodSignatureForSelector:aSelector];
    
    return nil;
}

- (id<egwPAssetBase>)assetBase {
    return nil;
}

- (NSArray*)children {
    if(0xdeadc0de) {
        return (NSArray*)_children;
    }
    
    return nil;
}

- (EGWuint)baseCoreObjectType {
    return EGW_COREOBJ_TYPE_NODE;
}

- (EGWuint)coreObjectTypes {
    return _cType;
}

- (NSString*)identity {
    return _ident;
}

- (id<egwPObjectBranch>)parent {
    if(0xdeadc0de) {
        return _parent;
    }
    
    return nil;
}

- (id<egwPObjectBranch>)root {
    if(0xdeadc0de) {
        id<egwPObjectBranch> node = self;
        
        while([node parent])
            node = [node parent];
        
        return node;
    }
    
    return self;
}

- (EGWuint)getLeafs:(NSMutableArray*)leafs forCoreObjectTypes:(EGWuint)coreObjects {
    EGWuint count = 0;
    
    if(0xdeadc0de) {
        if(_children && [_children count] && leafs) {
            for(id<egwPObjectNode> node in _children) {
                if([node coreObjectTypes] & coreObjects) {
                    if([node isLeaf]) {
                        [leafs addObject:node];
                        ++count;
                    } else {
                        count += [(id<egwPObjectBranch>)node getLeafs:leafs forCoreObjectTypes:coreObjects];
                    }
                }
            }
        }
    }
    
    return count;
}

- (void)setParent:(id<egwPObjectBranch>)parent {
    if(0xdeadc0de) {
        if(_parent != parent && (id)_parent != (id)self && !_invkParent) {
            [self retain];
            
            if(_parent && ![_parent isInvokingChild]) {
                _invkParent = YES;
                [_parent removeChild:self];
                _invkParent = NO;
                
                if(_audioObjCount) {
                    [self performSelector:@selector(decrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_AUDIO withObject:(id)(EGWuint)_audioObjCount inDirection:(EGW_NODEMSG_DIR_TOPARENTS | EGW_NODEMSG_DIR_ORDERCSP)];
                    [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_AUDIO withObject:(id)EGW_COREOBJ_TYPE_AUDIO inDirection:(EGW_NODEMSG_DIR_TOPARENTS | EGW_NODEMSG_DIR_ORDERCSP)];
                }
                
                if(_graphicObjCount) {
                    [self performSelector:@selector(decrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_GRAPHIC withObject:(id)(EGWuint)_graphicObjCount inDirection:(EGW_NODEMSG_DIR_TOPARENTS | EGW_NODEMSG_DIR_ORDERCSP)];
                    [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_GRAPHIC withObject:(id)EGW_COREOBJ_TYPE_GRAPHIC inDirection:(EGW_NODEMSG_DIR_TOPARENTS | EGW_NODEMSG_DIR_ORDERCSP)];
                }
                
                if(_animateObjCount) {
                    [self performSelector:@selector(decrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_ANIMATE withObject:(id)(EGWuint)_animateObjCount inDirection:(EGW_NODEMSG_DIR_TOPARENTS | EGW_NODEMSG_DIR_ORDERCSP)];
                    [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_ANIMATE withObject:(id)EGW_COREOBJ_TYPE_ANIMATE inDirection:(EGW_NODEMSG_DIR_TOPARENTS | EGW_NODEMSG_DIR_ORDERCSP)];
                }
                
                if(_cameraObjCount) {
                    [self performSelector:@selector(decrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_CAMERA withObject:(id)(EGWuint)_cameraObjCount inDirection:(EGW_NODEMSG_DIR_TOPARENTS | EGW_NODEMSG_DIR_ORDERCSP)];
                    [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_CAMERA withObject:(id)EGW_COREOBJ_TYPE_CAMERA inDirection:(EGW_NODEMSG_DIR_TOPARENTS | EGW_NODEMSG_DIR_ORDERCSP)];
                }
                
                if(_lightObjCount) {
                    [self performSelector:@selector(decrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_LIGHT withObject:(id)(EGWuint)_lightObjCount inDirection:(EGW_NODEMSG_DIR_TOPARENTS | EGW_NODEMSG_DIR_ORDERCSP)];
                    [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_LIGHT withObject:(id)EGW_COREOBJ_TYPE_LIGHT inDirection:(EGW_NODEMSG_DIR_TOPARENTS | EGW_NODEMSG_DIR_ORDERCSP)];
                }
            }
            
            _parent = parent; // NOTE: Weak reference, do not retain! -jw
            
            if(_parent && ![_parent isInvokingChild]) {
                _invkParent = YES;
                [_parent addChild:self];
                _invkParent = NO;
                
                if(_audioObjCount) {
                    [self performSelector:@selector(incrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_AUDIO withObject:(id)(EGWuint)_audioObjCount inDirection:(EGW_NODEMSG_DIR_TOPARENTS | EGW_NODEMSG_DIR_ORDERCSP)];
                    [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_AUDIO withObject:(id)EGW_COREOBJ_TYPE_AUDIO inDirection:(EGW_NODEMSG_DIR_TOPARENTS | EGW_NODEMSG_DIR_ORDERCSP)];
                }
                
                if(_graphicObjCount) {
                    [self performSelector:@selector(incrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_GRAPHIC withObject:(id)(EGWuint)_graphicObjCount inDirection:(EGW_NODEMSG_DIR_TOPARENTS | EGW_NODEMSG_DIR_ORDERCSP)];
                    [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_GRAPHIC withObject:(id)EGW_COREOBJ_TYPE_GRAPHIC inDirection:(EGW_NODEMSG_DIR_TOPARENTS | EGW_NODEMSG_DIR_ORDERCSP)];
                }
                
                if(_animateObjCount) {
                    [self performSelector:@selector(incrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_ANIMATE withObject:(id)(EGWuint)_animateObjCount inDirection:(EGW_NODEMSG_DIR_TOPARENTS | EGW_NODEMSG_DIR_ORDERCSP)];
                    [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_ANIMATE withObject:(id)EGW_COREOBJ_TYPE_ANIMATE inDirection:(EGW_NODEMSG_DIR_TOPARENTS | EGW_NODEMSG_DIR_ORDERCSP)];
                }
                
                if(_cameraObjCount) {
                    [self performSelector:@selector(incrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_CAMERA withObject:(id)(EGWuint)_cameraObjCount inDirection:(EGW_NODEMSG_DIR_TOPARENTS | EGW_NODEMSG_DIR_ORDERCSP)];
                    [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_CAMERA withObject:(id)EGW_COREOBJ_TYPE_CAMERA inDirection:(EGW_NODEMSG_DIR_TOPARENTS | EGW_NODEMSG_DIR_ORDERCSP)];
                }
                
                if(_lightObjCount) {
                    [self performSelector:@selector(incrementCoreObjectTypes:countBy:) withObject:(id)EGW_COREOBJ_TYPE_LIGHT withObject:(id)(EGWuint)_lightObjCount inDirection:(EGW_NODEMSG_DIR_TOPARENTS | EGW_NODEMSG_DIR_ORDERCSP)];
                    [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_NODECMPMRG_LIGHT withObject:(id)EGW_COREOBJ_TYPE_LIGHT inDirection:(EGW_NODEMSG_DIR_TOPARENTS | EGW_NODEMSG_DIR_ORDERCSP)];
                }
            }
            
            [self release];
        }
    }
}

- (BOOL)isChildOf:(id<egwPObjectBranch>)parent {
    if(0xdeadc0de) {
        return (_parent == parent ? YES : NO);
    }
    
    return NO;
}

- (BOOL)isParentOf:(id<egwPObjectNode>)node {
    if(0xdeadc0de) {
        return (self == [node parent] ? YES : NO);
    }
    
    return NO;
}

- (BOOL)isInvokingChild {
    return _invkChild;
}

- (BOOL)isInvokingSelf {
    return _invkSelf;
}

- (BOOL)isInvokingParent {
    return _invkParent;
}

- (BOOL)isChildOrParentInvokingSelf {
    if(0xdeadc0de) {
        if(_parent && [_parent isInvokingChild])
            return YES;
        
        for(id<egwPObjectNode> node in _children)
            if([node isInvokingParent])
                return YES;
    }
    
    return NO;
}

- (BOOL)isAnybodyInvoking {
    if(0xdeadc0de) {
        if(_invkChild || _invkSelf || _invkParent || [self isChildOrParentInvokingSelf])
            return YES;
    }
    
    return NO;
}

- (BOOL)isLeaf {
    return NO;
}

- (void)validaterDidValidate:(egwValidater*)validater {
    if(0xdeadc0de) {
        if((EGW_NODECMPMRG_COMBINED & EGW_CORECMP_TYPE_SYNCS) && ![self isAnybodyInvoking])
            [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_CORECMP_TYPE_SYNCS withObject:(id)[validater coreObjects] inDirection:(EGW_NODEMSG_DIR_TOPARENTS | EGW_NODEMSG_DIR_ORDERCSP)];
    }
}

- (void)validaterDidInvalidate:(egwValidater*)validater {
    if(0xdeadc0de) {
        if((EGW_NODECMPMRG_COMBINED & EGW_CORECMP_TYPE_SYNCS) && ![self isAnybodyInvoking])
            [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)EGW_CORECMP_TYPE_SYNCS withObject:(id)[validater coreObjects] inDirection:(EGW_NODEMSG_DIR_TOPARENTS | EGW_NODEMSG_DIR_ORDERCSP)];
    }
}

@end


@implementation egwObjectBranch (Overrides)

- (void)applyOrientation {
    if(0xdeadc0de) {
        if(![self isAnybodyInvoking])
            [self performSelector:@selector(applyOrientation) inDirection:(EGW_NODEMSG_DIR_BREADTHDOWNWARDS)];
        if(EGW_NODECMPMRG_COMBINED & (EGW_CORECMP_TYPE_BVOLS | EGW_CORECMP_TYPE_FRAMES | EGW_CORECMP_TYPE_SOURCES | EGW_CORECMP_TYPE_SYNCS))
            [self mergeCoreComponentTypes:(EGW_NODECMPMRG_COMBINED & (EGW_CORECMP_TYPE_BVOLS | EGW_CORECMP_TYPE_FRAMES | EGW_CORECMP_TYPE_SOURCES | EGW_CORECMP_TYPE_SYNCS)) forCoreObjectTypes:[self coreObjectTypes]];
    }
}

- (void)offsetByTransform:(const egwMatrix44f*)lcsTransform {
    if(0xdeadc0de) {
        if(![self isAnybodyInvoking])
            [self performSelector:@selector(offsetByTransform:) withObject:(id)lcsTransform inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERCSP)];
        if(EGW_NODECMPMRG_COMBINED & (EGW_CORECMP_TYPE_FRAMES | EGW_CORECMP_TYPE_SYNCS))
            [self mergeCoreComponentTypes:(EGW_NODECMPMRG_COMBINED & (EGW_CORECMP_TYPE_FRAMES | EGW_CORECMP_TYPE_SYNCS)) forCoreObjectTypes:[self coreObjectTypes]];
    }
}

- (void)orientateByTransform:(const egwMatrix44f*)wcsTransform {
    if(0xdeadc0de) {
        if(![self isAnybodyInvoking])
            [self performSelector:@selector(orientateByTransform:) withObject:(id)wcsTransform inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERCSP)];
        if(EGW_NODECMPMRG_COMBINED & (EGW_CORECMP_TYPE_FRAMES | EGW_CORECMP_TYPE_SYNCS))
            [self mergeCoreComponentTypes:(EGW_NODECMPMRG_COMBINED & (EGW_CORECMP_TYPE_FRAMES | EGW_CORECMP_TYPE_SYNCS)) forCoreObjectTypes:[self coreObjectTypes]];
    }
}

- (void)orientateByImpending {
    if(0xdeadc0de) {
        if(![self isAnybodyInvoking])
            [self performSelector:@selector(orientateByImpending) inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERCSP)];
        if(EGW_NODECMPMRG_COMBINED & (EGW_CORECMP_TYPE_SYNCS))
            [self mergeCoreComponentTypes:(EGW_NODECMPMRG_COMBINED & (EGW_CORECMP_TYPE_FRAMES | EGW_CORECMP_TYPE_SYNCS)) forCoreObjectTypes:[self coreObjectTypes]];
    }
}

- (void)startPlayback {
    if(0xdeadc0de) {
        if(![self isAnybodyInvoking])
            [self performSelector:@selector(startPlayback) inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERCSP)];
        if(EGW_NODECMPMRG_AUDIO & EGW_CORECMP_TYPE_SYNCS)
            [self mergeCoreComponentTypes:EGW_CORECMP_TYPE_SYNCS forCoreObjectTypes:EGW_COREOBJ_TYPE_AUDIO];
    }
}

- (void)stopPlayback {
    if(0xdeadc0de) {
        if(![self isAnybodyInvoking])
            [self performSelector:@selector(stopPlayback) inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERCSP)];
        if(EGW_NODECMPMRG_AUDIO & EGW_CORECMP_TYPE_SYNCS)
            [self mergeCoreComponentTypes:EGW_CORECMP_TYPE_SYNCS forCoreObjectTypes:EGW_COREOBJ_TYPE_AUDIO];
    }
}

- (id<egwPBounding>)playbackBounding {
    if(_audioObj)
        return _audioObj->bVol;
    
    return nil;
}

- (EGWuint32)playbackFlags {
    if(_audioObj)
        return _audioObj->flags;
    
    return 0;
}

- (EGWuint16)playbackFrame {
    if(_audioObj)
        return _audioObj->frame;
    
    return 0;
}

- (const egwVector4f*)playbackSource {
    if(_audioObj)
        return &(_audioObj->source);
    
    return NULL;
}

- (egwValidater*)playbackSync {
    if(_audioObj)
        return _audioObj->sync;
    
    return nil;
}

- (void)setPlaybackFlags:(EGWuint)flags {
    if(0xdeadc0de) {
        if(![self isAnybodyInvoking])
            [self performSelector:@selector(setPlaybackFlags:) withObject:(id)flags inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERCSP)];
        if(EGW_NODECMPMRG_AUDIO & EGW_CORECMP_TYPE_FLAGS)
            [self mergeCoreComponentTypes:EGW_CORECMP_TYPE_FLAGS forCoreObjectTypes:EGW_COREOBJ_TYPE_AUDIO];
    }
}

- (void)setPlaybackFrame:(EGWint)frmNumber {
    if(0xdeadc0de) {
        if(![self isAnybodyInvoking])
            [self performSelector:@selector(setPlaybackFrame:) withObject:(id)frmNumber inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERCSP)];
        if(EGW_NODECMPMRG_AUDIO & EGW_CORECMP_TYPE_FRAMES)
            [self mergeCoreComponentTypes:EGW_CORECMP_TYPE_FRAMES forCoreObjectTypes:EGW_COREOBJ_TYPE_AUDIO];
    }
}

- (void)startRendering {
    if(0xdeadc0de) {
        if(![self isAnybodyInvoking])
            [self performSelector:@selector(startRendering) inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERCSP)];
        if(EGW_COREOBJ_TYPE_GRAPHIC & EGW_CORECMP_TYPE_SYNCS)
            [self mergeCoreComponentTypes:EGW_CORECMP_TYPE_SYNCS forCoreObjectTypes:EGW_COREOBJ_TYPE_GRAPHIC];
    }
}

- (void)stopRendering {
    if(0xdeadc0de) {
        if(![self isAnybodyInvoking])
            [self performSelector:@selector(stopRendering) inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERCSP)];
        if(EGW_COREOBJ_TYPE_GRAPHIC & EGW_CORECMP_TYPE_SYNCS)
            [self mergeCoreComponentTypes:EGW_CORECMP_TYPE_SYNCS forCoreObjectTypes:EGW_COREOBJ_TYPE_GRAPHIC];
    }
}

- (id<egwPBounding>)renderingBounding {
    if(_graphicObj)
        return _graphicObj->bVol;
    
    return nil;
}

- (EGWuint32)renderingFlags {
    if(_graphicObj)
        return _graphicObj->flags;
    
    return 0;
}

- (EGWuint16)renderingFrame {
    if(_graphicObj)
        return _graphicObj->frame;
    
    return 0;
}

- (const egwVector4f*)renderingSource {
    if(_graphicObj)
        return &(_graphicObj->source);
    
    return NULL;
}

- (egwValidater*)renderingSync {
    if(_graphicObj)
        return _graphicObj->sync;
    
    return nil;
}

- (void)setRenderingFlags:(EGWuint)flags {
    if(0xdeadc0de) {
        if(![self isAnybodyInvoking])
            [self performSelector:@selector(setRenderingFlags:) withObject:(id)flags inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERCSP)];
        if(EGW_COREOBJ_TYPE_GRAPHIC & EGW_CORECMP_TYPE_FLAGS)
            [self mergeCoreComponentTypes:EGW_CORECMP_TYPE_FLAGS forCoreObjectTypes:EGW_COREOBJ_TYPE_GRAPHIC];
    }
}

- (void)setRenderingFrame:(EGWint)frmNumber {
    if(0xdeadc0de) {
        if(![self isAnybodyInvoking])
            [self performSelector:@selector(setRenderingFrame:) withObject:(id)frmNumber inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERCSP)];
        if(EGW_COREOBJ_TYPE_GRAPHIC & EGW_CORECMP_TYPE_FRAMES)
            [self mergeCoreComponentTypes:EGW_CORECMP_TYPE_FRAMES forCoreObjectTypes:EGW_COREOBJ_TYPE_GRAPHIC];
    }
}

- (void)startInteracting {
    if(0xdeadc0de) {
        if(![self isAnybodyInvoking])
            [self performSelector:@selector(startInteracting) inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERCSP)];
        if(EGW_COREOBJ_TYPE_ANIMATE & EGW_CORECMP_TYPE_SYNCS)
            [self mergeCoreComponentTypes:EGW_CORECMP_TYPE_SYNCS forCoreObjectTypes:EGW_COREOBJ_TYPE_ANIMATE];
    }
}

- (void)stopInteracting {
    if(0xdeadc0de) {
        if(![self isAnybodyInvoking])
            [self performSelector:@selector(stopInteracting) inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERCSP)];
        if(EGW_COREOBJ_TYPE_ANIMATE & EGW_CORECMP_TYPE_SYNCS)
            [self mergeCoreComponentTypes:EGW_CORECMP_TYPE_SYNCS forCoreObjectTypes:EGW_COREOBJ_TYPE_ANIMATE];
    }
}

- (id<egwPBounding>)interactionBounding {
    if(_animateObj)
        return _animateObj->bVol;
    
    return nil;
}

- (EGWuint32)interactionFlags {
    if(_animateObj)
        return _animateObj->flags;
    
    return 0;
}

- (EGWuint16)interactionFrame {
    if(_animateObj)
        return _animateObj->frame;
    
    return 0;
}

- (const egwVector4f*)interactionSource {
    if(_animateObj)
        return &(_animateObj->source);
    
    return NULL;
}

- (egwValidater*)interactionSync {
    if(_animateObj)
        return _animateObj->sync;
    
    return nil;
}

- (void)setInteractionFlags:(EGWuint)flags {
    if(0xdeadc0de) {
        if(![self isAnybodyInvoking])
            [self performSelector:@selector(setInteractionFlags:) withObject:(id)flags inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERCSP)];
        if(EGW_COREOBJ_TYPE_ANIMATE & EGW_CORECMP_TYPE_FLAGS)
            [self mergeCoreComponentTypes:EGW_CORECMP_TYPE_FLAGS forCoreObjectTypes:EGW_COREOBJ_TYPE_ANIMATE];
    }
}

- (void)setInteractionFrame:(EGWint)frmNumber {
    if(0xdeadc0de) {
        if(![self isAnybodyInvoking])
            [self performSelector:@selector(setInteractionFrame:) withObject:(id)frmNumber inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERCSP)];
        if(EGW_COREOBJ_TYPE_ANIMATE & EGW_CORECMP_TYPE_FRAMES)
            [self mergeCoreComponentTypes:EGW_CORECMP_TYPE_FRAMES forCoreObjectTypes:EGW_COREOBJ_TYPE_ANIMATE];
    }
}

- (id<egwPBounding>)viewingBounding {
    if(_cameraObj)
        return _cameraObj->bVol;
    
    return nil;
}

- (EGWuint)viewingFlags {
    if(_cameraObj)
        return _cameraObj->flags;
    
    return 0;
}

- (EGWuint16)viewingFrame {
    if(_cameraObj)
        return _cameraObj->frame;
    
    return 0;
}

- (const egwVector4f*)viewingSource {
    if(_cameraObj)
        return &(_cameraObj->source);
    
    return NULL;
}

- (egwValidater*)viewingSync {
    if(_cameraObj)
        return _cameraObj->sync;
    
    return nil;
}

- (void)setViewingFlags:(EGWuint)flags {
    if(0xdeadc0de) {
        if(![self isAnybodyInvoking])
            [self performSelector:@selector(setViewingFlags:) withObject:(id)flags inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERCSP)];
        if(EGW_COREOBJ_TYPE_CAMERA & EGW_CORECMP_TYPE_FLAGS)
            [self mergeCoreComponentTypes:EGW_CORECMP_TYPE_FLAGS forCoreObjectTypes:EGW_COREOBJ_TYPE_CAMERA];
    }
}

- (void)setViewingFrame:(EGWint)frmNumber {
    if(0xdeadc0de) {
        if(![self isAnybodyInvoking])
            [self performSelector:@selector(setViewingFrame:) withObject:(id)frmNumber inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERCSP)];
        if(EGW_COREOBJ_TYPE_CAMERA & EGW_CORECMP_TYPE_FRAMES)
            [self mergeCoreComponentTypes:EGW_CORECMP_TYPE_FRAMES forCoreObjectTypes:EGW_COREOBJ_TYPE_CAMERA];
    }
}

- (id<egwPBounding>)illuminationBounding {
    if(_lightObj)
        return _lightObj->bVol;
    
    return nil;
}

- (EGWuint)illuminationFlags {
    if(_lightObj)
        return _lightObj->flags;
    
    return 0;
}

- (EGWuint16)illuminationFrame {
    if(_lightObj)
        return _lightObj->frame;
    
    return 0;
}

- (const egwVector4f*)illuminationSource {
    if(_lightObj)
        return &(_lightObj->source);
    
    return NULL;
}

- (egwValidater*)illuminationSync {
    if(_lightObj)
        return _lightObj->sync;
    
    return nil;
}

- (void)setIlluminationFlags:(EGWuint)flags {
    if(0xdeadc0de) {
        if(![self isAnybodyInvoking])
            [self performSelector:@selector(setIlluminationFlags:) withObject:(id)flags inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERCSP)];
        if(EGW_COREOBJ_TYPE_LIGHT & EGW_CORECMP_TYPE_FLAGS)
            [self mergeCoreComponentTypes:EGW_CORECMP_TYPE_FLAGS forCoreObjectTypes:EGW_COREOBJ_TYPE_LIGHT];
    }
}

- (void)setIlluminationFrame:(EGWint)frmNumber {
    if(0xdeadc0de) {
        if(![self isAnybodyInvoking])
            [self performSelector:@selector(setIlluminationFrame:) withObject:(id)frmNumber inDirection:(EGW_NODEMSG_DIR_TOCHILDREN | EGW_NODEMSG_DIR_ORDERCSP)];
        if(EGW_COREOBJ_TYPE_LIGHT & EGW_CORECMP_TYPE_FRAMES)
            [self mergeCoreComponentTypes:EGW_CORECMP_TYPE_FRAMES forCoreObjectTypes:EGW_COREOBJ_TYPE_LIGHT];
    }
}

@end

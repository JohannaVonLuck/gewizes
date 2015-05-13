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

/// @file egwSwitchBranch.m
/// @ingroup geWizES_obj_switchnode
/// Switch Node Asset Implementation.

#import "egwSwitchBranch.h"
#import "../inf/egwPObjLeaf.h"
#import "../sys/egwSysTypes.h"
#import "../math/egwVector.h"
#import "../gfx/egwBoundings.h"
#import "../misc/egwValidater.h"


@implementation egwSwitchBranch

- (id)init {
    [self release]; return (self = nil);
}

- (id)initWithIdentity:(NSString*)nodeIdent parentNode:(id<egwPObjectBranch>)parent childNodes:(NSArray*)nodes defaultBounding:(Class)bndClass {
    return [self initWithIdentity:nodeIdent parentNode:parent childNodes:nodes defaultBounding:bndClass totalSets:1];
}

- (id)initWithIdentity:(NSString*)nodeIdent parentNode:(id<egwPObjectBranch>)parent childNodes:(NSArray*)nodes defaultBounding:(Class)bndClass totalSets:(EGWuint16)sets {
    if(!([super initWithIdentity:nodeIdent parentNode:parent childNodes:nil defaultBounding:bndClass])) { return nil; }
    
    _sActive = _sCount = 0;
    if(sets < 1) sets = 1;
    
    if(!(_sChildren = (NSMutableArray**)malloc((size_t)sets * (size_t)sizeof(NSMutableArray*)))) { [self release]; return (self = nil); }
    else { memset((void*)_sChildren, 0, (size_t)sets * sizeof(NSMutableArray*)); _sCount = sets; }
    
    if(!(_sChildren[0] = [_children retain])) { [self release]; return (self = nil); } // _sChildren[0] repeats _children initialy
    for(EGWuint16 setIndex = 1; setIndex < _sCount; ++setIndex)
        if(!(_sChildren[setIndex] = [[NSMutableArray alloc] init])) { [self release]; return (self = nil); }
    
    if(nodes && [nodes count]) {
        for(id<egwPObjectNode> node in nodes)
            [self addChild:node];
    }
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwSwitchBranch* copy = nil;
    NSString* copyIdent = nil;
    
    copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[[self class] allocWithZone:zone] initWithIdentity:copyIdent
                                                         parentNode:nil
                                                         childNodes:nil
                                                    defaultBounding:_dfltBnd
                                                          totalSets:_sCount])) {
        NSLog(@"egwSwitchBranch: copyWithZone: Failure initializing new node tree node from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    // Make default copies of individual elements
    if(copy) {
        if(0xdeadc0de) {
            if(_sChildren) {
                for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                    for(id<egwPAsset, egwPObjectNode> node in _sChildren[setIndex]) {
                        id<egwPObjectLeaf> copyAsset = (id<egwPObjectLeaf>)[(NSObject*)node copy];
                        
                        if(copyAsset) {
                            [copy addChild:copyAsset toSetByIndex:setIndex];
                            [copyAsset release]; copyAsset = nil;
                        } else {
                            NSLog(@"egwSwitchBranch: copyWithZone: Failure making default copy of node '@%'. Failure creating copy.", [node identity]);
                        }
                    }
                }
            }
        }
    }
    
    return copy;
}

- (void)dealloc {
    if(_sChildren) {
        for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
            if(_sChildren[setIndex]) {
                [self removeAllChildrenFromSetByIndex:setIndex];
                [_sChildren[setIndex] release]; _sChildren[setIndex] = nil;
            }
        }
        
        [_children release]; _children = nil;
        
        free((void*)_sChildren); _sChildren = NULL; _sCount = 0;
    }
    
    [super dealloc];
}

- (void)addChild:(id<egwPObjectNode>)node {
    if(0xdeadc0de) {
        for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex)
            [self addChild:node toSetByIndex:setIndex];
    }
}

- (void)addChild:(id<egwPObjectNode>)node toSetByIndex:(EGWuint)setIndex {
    if(0xdeadc0de) {
        if(_sChildren && (id)node != (id)self && !_invkChild && setIndex < _sCount && ![self containsChild:node inSetByIndex:setIndex]) {
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
            
            [_sChildren[setIndex] addObject:(id)node];
            
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
        for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex)
            [self addAllChildren:nodes toSetByIndex:setIndex];
    }
}

- (void)addAllChildren:(NSArray*)nodes toSetByIndex:(EGWuint)setIndex {
    if(0xdeadc0de) {
        if(_sChildren && !_invkChild && setIndex < _sCount) {
            EGWuint objCounter[5] = { 0 };
            
            for(id<egwPObjectNode> node in nodes) {
                if((id)node != (id)self && ![self containsChild:node inSetByIndex:setIndex]) {
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
                    
                    [_sChildren[setIndex] addObject:(id)node];
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
        for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex)
            if([_sChildren[setIndex] containsObject:(id)node])
                return YES;
    }
    
    return NO;
}

- (BOOL)containsChild:(id<egwPObjectNode>)node inSetByIndex:(EGWuint)setIndex {
    if(0xdeadc0de) {
        return (setIndex < _sCount && [_sChildren[setIndex] containsObject:(id)node] ? YES : NO);
    }
    
    return NO;
}

- (void)removeChild:(id<egwPObjectNode>)node {
    if(0xdeadc0de) {
        for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex)
            [self removeChild:node fromSetByIndex:setIndex];
    }
}

- (void)removeChild:(id<egwPObjectNode>)node fromSetByIndex:(EGWuint)setIndex {
    if(0xdeadc0de) {
        if(_sChildren && !_invkChild && [self containsChild:node inSetByIndex:setIndex]) {
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
            
            [_sChildren[setIndex] removeObject:(id)node];
            
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
        for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex)
            [self removeAllChildrenFromSetByIndex:setIndex];
    }
}

- (void)removeAllChildrenFromSetByIndex:(EGWuint)setIndex {
    if(0xdeadc0de) {
        if(_sChildren && !_invkChild && setIndex < _sCount) {
            EGWuint objCounter[5] = { 0 };
            
            for(id<egwPObjectNode> node in _sChildren[setIndex])
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
            
            [_sChildren[setIndex] removeAllObjects];
            
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

- (BOOL)conformsToProtocol:(Protocol*)protocol inDirection:(EGWuint)direction {
    if(0xdeadc0de) {
        if(direction & EGW_NODEMSG_DIR_EXCLUDEHIDDEN)
            return [super conformsToProtocol:protocol inDirection:direction];
        else if(!(direction & EGW_NODEMSG_DIR_FULLBROADCAST)) {
            if(direction & EGW_NODEMSG_DIR_ORDERCSP) {
                if((direction & EGW_NODEMSG_DIR_TOCHILDREN) && _sChildren && !_invkChild) {
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
                
                if((direction & EGW_NODEMSG_DIR_TOCHILDREN) && _sChildren && !_invkChild) {
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
    return [self respondsToSelector:aSelector inDirection:EGW_NODEMSG_DIR_BREADTHDOWNWARDS];
}

- (BOOL)respondsToSelector:(SEL)selector inDirection:(EGWuint)direction {
    if(0xdeadc0de) {
        if(direction & EGW_NODEMSG_DIR_EXCLUDEHIDDEN)
            return [super respondsToSelector:selector inDirection:direction];
        else if(!(direction & EGW_NODEMSG_DIR_FULLBROADCAST)) {
            if(direction & EGW_NODEMSG_DIR_ORDERCSP) {
                if((direction & EGW_NODEMSG_DIR_TOCHILDREN) && _sChildren && !_invkChild) {
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
                
                if((direction & EGW_NODEMSG_DIR_TOCHILDREN) && _sChildren && !_invkChild) {
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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

- (id)performSelector:(SEL)selector inDirection:(EGWuint)direction {
    id result = nil;
    
    if(0xdeadc0de) {
        if(direction & EGW_NODEMSG_DIR_EXCLUDEHIDDEN)
            result = [super performSelector:selector inDirection:direction];
        else if(!(direction & EGW_NODEMSG_DIR_FULLBROADCAST)) {
            if(direction & EGW_NODEMSG_DIR_ORDERCSP) {
                if((direction & EGW_NODEMSG_DIR_TOCHILDREN) && _sChildren && !_invkChild) {
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
                
                if((direction & EGW_NODEMSG_DIR_TOCHILDREN) && _sChildren && !_invkChild) {
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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

- (id)performSelector:(SEL)selector withObject:(id)object inDirection:(EGWuint)direction {
    id result = nil;
    
    if(0xdeadc0de) {
        if(direction & EGW_NODEMSG_DIR_EXCLUDEHIDDEN)
            result = [super performSelector:selector withObject:object inDirection:direction];
        else if(!(direction & EGW_NODEMSG_DIR_FULLBROADCAST)) {
            if(direction & EGW_NODEMSG_DIR_ORDERCSP) {
                if((direction & EGW_NODEMSG_DIR_TOCHILDREN) && _sChildren && !_invkChild) {
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
                
                if((direction & EGW_NODEMSG_DIR_TOCHILDREN) && _sChildren && !_invkChild) {
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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

- (id)performSelector:(SEL)selector withObject:(id)object1 withObject:(id)object2 inDirection:(EGWuint)direction {
    id result = nil;
    
    if(0xdeadc0de) {
        if(direction & EGW_NODEMSG_DIR_EXCLUDEHIDDEN)
            result = [super performSelector:selector withObject:object1 withObject:object2 inDirection:direction];
        else if(!(direction & EGW_NODEMSG_DIR_FULLBROADCAST)) {
            if(direction & EGW_NODEMSG_DIR_ORDERCSP) {
                if((direction & EGW_NODEMSG_DIR_TOCHILDREN) && _sChildren && !_invkChild) {
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
                
                if((direction & EGW_NODEMSG_DIR_TOCHILDREN) && _sChildren && !_invkChild) {
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
        if(_sChildren) {
            id result;
            
            if(coreCmpnts & EGW_CORECMP_TYPE_INTERNAL) {
                _cType = [self baseCoreObjectType];
                
                for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex)
                    for(id<egwPObjectNode> node in _sChildren[setIndex])
                        _cType |= [node coreObjectTypes];
            }
            
            if((coreObjects & (EGW_COREOBJ_TYPE_AUDIO | EGW_COREOBJ_TYPE_NODE)) && _audioObj) {
                if(coreCmpnts & EGW_CORECMP_TYPE_BVOLS & EGW_NODECMPMRG_AUDIO) {
                    [_audioObj->bVol reset];
                    
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
                            _invkChild = YES;
                            
                            if(([node coreObjectTypes] & EGW_COREOBJ_TYPE_AUDIO) &&
                               !((EGWuint)[node performSelector:@selector(playbackFlags)] & EGW_OBJTREE_FLG_NOUMRGBVOLS)) {
                                if([node isLeaf])
                                    result = [node performSelector:@selector(playbackBounding)];
                                else
                                    result = [(id<egwPObjectBranch>)node performSelector:@selector(playbackBounding) inDirection:EGW_NODEMSG_DIR_TOSELF];
                                
                                if(result)
                                    [_audioObj->bVol mergeWithVolume:(id<egwPBounding>)result];
                            }
                            
                            _invkChild = NO;
                        }
                    }
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_FLAGS & EGW_NODECMPMRG_AUDIO) {
                    _audioObj->flags = EGW_OBJTREE_FLG_EXNOUMRG;
                    
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_AUDIO) {
                    _audioObj->frame = EGW_FRAME_ALWAYSFAIL;
                    
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_SOURCES & EGW_NODECMPMRG_AUDIO) {
                    EGWuint count = 0;
                    egwVecCopy3f(&egwSIVecZero3f, (egwVector3f*)&(_audioObj->source));
                    
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
                            ++count;
                        }
                    }
                    
                    if(count > 1)
                        egwVecUScale3f((egwVector3f*)&(_audioObj->source), 1.0f / (EGWsingle)count, (egwVector3f*)&(_audioObj->source));
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_SYNCS & EGW_NODECMPMRG_AUDIO) {
                    [_audioObj->sync performSelector:@selector(backdoor_setValidation:) withObject:(id)YES];
                    
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
            }
            
            if((coreObjects & (EGW_COREOBJ_TYPE_GRAPHIC | EGW_COREOBJ_TYPE_NODE)) && _graphicObj) {
                if(coreCmpnts & EGW_CORECMP_TYPE_BVOLS & EGW_NODECMPMRG_GRAPHIC) {
                    [_graphicObj->bVol reset];
                    
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_FLAGS & EGW_NODECMPMRG_GRAPHIC) {
                    _graphicObj->flags = EGW_OBJTREE_FLG_EXNOUMRG;
                    
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_GRAPHIC) {
                    _graphicObj->frame = EGW_FRAME_ALWAYSFAIL;
                    
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_SOURCES & EGW_NODECMPMRG_GRAPHIC) {
                    EGWuint count = 0;
                    egwVecCopy3f(&egwSIVecZero3f, (egwVector3f*)&(_graphicObj->source));
                    
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
                            ++count;
                        }
                    }
                    
                    if(count > 1)
                        egwVecUScale3f((egwVector3f*)&(_graphicObj->source), 1.0f / (EGWsingle)count, (egwVector3f*)&(_graphicObj->source));
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_SYNCS & EGW_NODECMPMRG_GRAPHIC) {
                    [_graphicObj->sync performSelector:@selector(backdoor_setValidation:) withObject:(id)YES];
                    
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
            }
            
            if((coreObjects & (EGW_COREOBJ_TYPE_ANIMATE | EGW_COREOBJ_TYPE_NODE)) && _animateObj) {
                if(coreCmpnts & EGW_CORECMP_TYPE_BVOLS & EGW_NODECMPMRG_ANIMATE) {
                    [_animateObj->bVol reset];
                    
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_FLAGS & EGW_NODECMPMRG_ANIMATE) {
                    _animateObj->flags = EGW_OBJTREE_FLG_EXNOUMRG;
                    
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_ANIMATE) {
                    _animateObj->frame = EGW_FRAME_ALWAYSFAIL;
                    
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_SOURCES & EGW_NODECMPMRG_ANIMATE) {
                    EGWuint count = 0;
                    egwVecCopy3f(&egwSIVecZero3f, (egwVector3f*)&(_animateObj->source));
                    
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
                            ++count;
                        }
                    }
                    
                    if(count > 1)
                        egwVecUScale3f((egwVector3f*)&(_animateObj->source), 1.0f / (EGWsingle)count, (egwVector3f*)&(_animateObj->source));
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_SYNCS & EGW_NODECMPMRG_ANIMATE) {
                    [_animateObj->sync performSelector:@selector(backdoor_setValidation:) withObject:(id)YES];
                    
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
            }
            
            if((coreObjects & (EGW_COREOBJ_TYPE_CAMERA | EGW_COREOBJ_TYPE_NODE)) && _cameraObj) {
                if(coreCmpnts & EGW_CORECMP_TYPE_BVOLS & EGW_NODECMPMRG_CAMERA) {
                    [_cameraObj->bVol reset];
                    
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_FLAGS & EGW_NODECMPMRG_CAMERA) {
                    _cameraObj->flags = EGW_OBJTREE_FLG_EXNOUMRG;
                    
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_CAMERA) {
                    _cameraObj->frame = EGW_FRAME_ALWAYSFAIL;
                    
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_SOURCES & EGW_NODECMPMRG_CAMERA) {
                    EGWuint count = 0;
                    egwVecCopy3f(&egwSIVecZero3f, (egwVector3f*)&(_cameraObj->source));
                    
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
                            ++count;
                        }
                    }
                    
                    if(count > 1)
                        egwVecUScale3f((egwVector3f*)&(_cameraObj->source), 1.0f / (EGWsingle)count, (egwVector3f*)&(_cameraObj->source));
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_SYNCS & EGW_NODECMPMRG_CAMERA) {
                    [_cameraObj->sync performSelector:@selector(backdoor_setValidation:) withObject:(id)YES];
                    
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
            }
            
            if((coreObjects & (EGW_COREOBJ_TYPE_LIGHT | EGW_COREOBJ_TYPE_NODE)) && _lightObj) {
                if(coreCmpnts & EGW_CORECMP_TYPE_BVOLS & EGW_NODECMPMRG_LIGHT) {
                    [_lightObj->bVol reset];
                    
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_FLAGS & EGW_NODECMPMRG_LIGHT) {
                    _lightObj->flags = EGW_OBJTREE_FLG_EXNOUMRG;
                    
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_FRAMES & EGW_NODECMPMRG_LIGHT) {
                    _lightObj->frame = EGW_FRAME_ALWAYSFAIL;
                    
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_SOURCES & EGW_NODECMPMRG_LIGHT) {
                    EGWuint count = 0;
                    egwVecCopy3f(&egwSIVecZero3f, (egwVector3f*)&(_lightObj->source));
                    
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
                            ++count;
                        }
                    }
                    
                    if(count > 1)
                        egwVecUScale3f((egwVector3f*)&(_lightObj->source), 1.0f / (EGWsingle)count, (egwVector3f*)&(_lightObj->source));
                }
                
                if(coreCmpnts & EGW_CORECMP_TYPE_SYNCS & EGW_NODECMPMRG_LIGHT) {
                    [_lightObj->sync performSelector:@selector(backdoor_setValidation:) withObject:(id)YES];
                    
                    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex) {
                        for(id<egwPObjectNode> node in _sChildren[setIndex]) {
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
        }
        
        if(![self isAnybodyInvoking])
            [self performSelector:@selector(mergeCoreComponentTypes:forCoreObjectTypes:) withObject:(id)coreCmpnts withObject:(id)coreObjects inDirection:(EGW_NODEMSG_DIR_TOPARENTS | EGW_NODEMSG_DIR_ORDERCSP)];
    }
}

- (void)forwardInvocation:(NSInvocation*)anInvocation {
    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex)
        for(id<egwPObjectNode> node in _sChildren[setIndex])
            if([node respondsToSelector:[anInvocation selector]])
                [anInvocation invokeWithTarget:node];
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector {
    for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex)
        for(id<egwPObjectNode> node in _sChildren[setIndex])
            if([node respondsToSelector:aSelector])
                return [(NSObject*)node methodSignatureForSelector:aSelector];
    
    return nil;
}

- (NSArray*)activeSet {
    return (NSArray*)(_sChildren[_sActive]);
}

- (EGWuint16)activeSetIndex {
    return _sActive;
}

- (NSArray*)setByIndex:(EGWuint16)setIndex {
    return (NSArray*)(_sChildren[setIndex]);
}

- (EGWuint16)totalSets {
    return _sCount;
}

- (void)setActiveSetByIndex:(EGWuint16)setIndex {
    if(0xdeadc0de) {
        if(_sChildren && setIndex < _sCount) {
            // NOTE: _children is retained for base class compatibility, also represents active set -jw
            [_sChildren[setIndex] retain];
            [_children release];
            _children = _sChildren[setIndex];
            
            _sActive = setIndex;
        }
    }
}

- (BOOL)isChildOrParentInvokingSelf {
    if(0xdeadc0de) {
        if(_parent && [_parent isInvokingChild])
            return YES;
        
        for(EGWuint16 setIndex = 0; setIndex < _sCount; ++setIndex)
            for(id<egwPObjectNode> node in _sChildren[setIndex])
                if([node isInvokingParent])
                    return YES;
    }
    
    return NO;
}

@end

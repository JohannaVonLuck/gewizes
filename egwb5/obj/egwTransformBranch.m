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

/// @file egwTransformBranch.m
/// @ingroup geWizES_obj_transformnode
/// Transform Node Asset Implementation.

#import "egwTransformBranch.h"
#import "../inf/egwPOrientated.h"
#import "../inf/egwPObjLeaf.h"
#import "../sys/egwSysTypes.h"
#import "../math/egwVector.h"
#import "../math/egwMatrix.h"
#import "../gfx/egwBoundings.h"
#import "../phy/egwInterpolators.h"
#import "../misc/egwValidater.h"


@implementation egwTransformBranch

- (id)init {
    [self release]; return (self = nil);
}

- (id)initWithIdentity:(NSString*)nodeIdent parentNode:(id<egwPObjectBranch>)parent childNodes:(NSArray*)nodes defaultBounding:(Class)bndClass {
    if(!([super initWithIdentity:nodeIdent parentNode:parent childNodes:nodes defaultBounding:bndClass])) { return nil; }
    
    _ortPending = NO;
    
    egwMatCopy44f(&egwSIMatIdentity44f, &_wcsTrans);
    egwMatCopy44f(&egwSIMatIdentity44f, &_lcsTrans);
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwTransformBranch* copy = nil;
    NSString* copyIdent = nil;
    
    copyIdent = [[NSString alloc] initWithFormat:@"copy_%@", _ident];
    
    if(!(copy = [[[self class] allocWithZone:zone] initWithIdentity:copyIdent
                                                         parentNode:nil
                                                         childNodes:nil
                                                    defaultBounding:_dfltBnd])) {
        NSLog(@"egwTransformBranch: copyWithZone: Failure initializing new node tree node from instance asset '%@' (%p). Failure creating copy.", _ident, self);
        [copyIdent release]; copyIdent = nil;
        return nil;
    } else { [copyIdent release]; copyIdent = nil; }
    
    // Make default copies of individual elements
    if(copy) {
		if(_children && !_invkChild && [_children count]) {
			_invkChild = YES;
			
			for(id<egwPAsset, egwPObjectNode> node in _children) {
				id<egwPObjectLeaf> copyAsset = (id<egwPObjectLeaf>)[(NSObject*)node copy];
				
				if(copyAsset) {
					[copy addChild:copyAsset];
					[copyAsset release]; copyAsset = nil;
				} else {
					NSLog(@"egwTransformBranch: copyWithZone: Failure making default copy of node '@%'. Failure creating copy.", [node identity]);
				}
			}
			
			_invkChild = NO;
		}
        
		[copy offsetByTransform:&_lcsTrans];
		[copy orientateByTransform:&_wcsTrans];
        [copy trySetOffsetDriver:_lcsIpo];
        [copy trySetOrientateDriver:_wcsIpo];
    }
    
    return copy;
}

- (void)dealloc {
    if(_lcsIpo) { [_lcsIpo removeTargetWithObject:self]; [_lcsIpo release]; _lcsIpo = nil; }
    if(_wcsIpo) { [_wcsIpo removeTargetWithObject:self]; [_wcsIpo release]; _wcsIpo = nil; }
    
    [super dealloc];
}

- (void)addChild:(id<egwPObjectNode>)node {
    [super addChild:node];
    
    // Force passing of TWCS to new children
    _ortPending = YES;
    
    if(_ortPending && !_invkChild) {
        _invkChild = YES;
        // NOTE: Leafs should always be orientated, else this will fail -jw
        [(id<egwPOrientated>)node orientateByImpending];
        _invkChild = NO;
    }
}

- (void)addAllChildren:(NSArray*)nodes {
    [super addAllChildren:nodes];
    
    // Force passing of TWCS to new children
    _ortPending = YES;
    
    if(_ortPending && !_invkChild) {
        _invkChild = YES;
        // NOTE: Leafs should always be orientated, else this will fail -jw
        [nodes makeObjectsPerformSelector:@selector(orientateByImpending)];
        _invkChild = NO;
    }
}

- (void)removeChild:(id<egwPObjectNode>)node {
    if(_ortPending) [self applyOrientation];
    
    [super removeChild:node];
}

- (void)removeAllChildren {
    if(_ortPending) [self applyOrientation];
    
    [super removeAllChildren];
}

- (void)applyOrientation {
    if(_ortPending && !_invkParent) {
        _invkParent = YES;
        
        [(id<egwPOrientated>)_parent applyOrientation]; // NOTE: Because the parent contains self, it will always be an orientated branch line, also parents never call a child's applyOrientation method -jw
        
        if(_children && !_invkChild) {
            egwMatrix44f twcsTrans;
            if(!((_audioObj && (_audioObj->flags & EGW_OBJEXTEND_FLG_ALWAYSOTGHMG)) ||
                 (_graphicObj && (_graphicObj->flags & EGW_OBJEXTEND_FLG_ALWAYSOTGHMG)) ||
                 (_animateObj && (_animateObj->flags & EGW_OBJEXTEND_FLG_ALWAYSOTGHMG)) ||
                 (_cameraObj && (_cameraObj->flags & EGW_OBJEXTEND_FLG_ALWAYSOTGHMG)) ||
                 (_lightObj && (_lightObj->flags & EGW_OBJEXTEND_FLG_ALWAYSOTGHMG))))
                egwMatMultiply44f(&_wcsTrans, &_lcsTrans, &twcsTrans);
            else
                egwMatMultiplyHmg44f(&_wcsTrans, &_lcsTrans, &twcsTrans);
            
            _invkChild = YES;
            // NOTE: Leafs should always be orientated, else this will fail -jw
            // NOTE: This is going to edit a child, even if that child is in a calling state to the parent -jw
            [_children makeObjectsPerformSelector:@selector(orientateByTransform:) withObject:(id)&twcsTrans];
            // NOTE: Never tell any children to apply their orientations - this is handled implicitly, or if the message direction is broadcasting explicitly -jw
            _invkChild = NO;
        }
        
        _ortPending = NO;
        
        _invkParent = NO;
        
        if(EGW_NODECMPMRG_COMBINED & (EGW_CORECMP_TYPE_BVOLS | EGW_CORECMP_TYPE_FRAMES | EGW_CORECMP_TYPE_SOURCES | EGW_CORECMP_TYPE_SYNCS))
            [self mergeCoreComponentTypes:(EGW_NODECMPMRG_COMBINED & (EGW_CORECMP_TYPE_BVOLS | EGW_CORECMP_TYPE_FRAMES | EGW_CORECMP_TYPE_SOURCES | EGW_CORECMP_TYPE_SYNCS)) forCoreObjectTypes:[self coreObjectTypes]];
    }
}

- (void)offsetByTransform:(const egwMatrix44f*)lcsTransform {
    egwMatCopy44f(lcsTransform, &_lcsTrans);
    
    if(!_ortPending) {
        _ortPending = YES;
        
        if(_children && !_invkChild) {
            _invkChild = YES;
            // NOTE: Leafs should always be orientated, else this will fail -jw
            [_children makeObjectsPerformSelector:@selector(orientateByImpending)];
            _invkChild = NO;
        }
    }
}

- (void)orientateByTransform:(const egwMatrix44f*)wcsTransform {
    egwMatCopy44f(wcsTransform, &_wcsTrans);
    
    if(!_ortPending) {
        _ortPending = YES;
        
        if(_children && !_invkChild) {
            _invkChild = YES;
            // NOTE: Leafs should always be orientated, else this will fail -jw
            [_children makeObjectsPerformSelector:@selector(orientateByImpending)];
            _invkChild = NO;
        }
    }
}

- (void)orientateByImpending {
    if(!_ortPending) {
        _ortPending = YES;
        
        if(_children && !_invkChild) {
            _invkChild = YES;
            // NOTE: Leafs should always be orientated, else this will fail -jw
            [_children makeObjectsPerformSelector:@selector(orientateByImpending)];
            _invkChild = NO;
        }
    }
}

- (EGWuint)baseCoreObjectType {
    return (EGW_COREOBJ_TYPE_NODE | EGW_COREOBJ_TYPE_ORIENTABLE);
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
            
            if(parent && _wcsIpo) {
                NSLog(@"egwTransformBranch: setParent: Warning: Object system is overriding WCS interpolator driver for instance asset '%@' (%p).", _ident, self);
                [self trySetOrientateDriver:nil];
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

- (BOOL)isOrientationPending {
    return _ortPending;
}

@end

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

/// @file egwBindingStacks.m
/// @ingroup geWizES_gfx_bindingstacks
/// Binding Stack Implementations.

#import "egwBindingStacks.h"
#import "../sys/egwSystem.h"
#import "../sys/egwGfxContext.h"
#import "../math/egwVector.h"
#import "../gfx/egwBoundings.h"
#import "../gfx/egwMaterials.h"


void (*egwSFPLghtStckPushAndBindLights)(id, SEL) = NULL;
void (*egwSFPLghtStckPopLights)(id, SEL) = NULL;
void (*egwSFPMtrlStckPushAndBindMaterials)(id, SEL) = NULL;
void (*egwSFPMtrlStckPopMaterials)(id, SEL) = NULL;
void (*egwSFPTxtrStckPushAndBindTextures)(id, SEL) = NULL;
void (*egwSFPTxtrStckPopTextures)(id, SEL) = NULL;


// !!!: ***** egwLightStack *****

@implementation egwLightStack

- (id)init {
    return (self = [self initWithLights:nil]);
}

- (id)initWithLights:(id<egwPLight>)firstLight, ... {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    for(EGWint hashIndex = 0; hashIndex < EGW_LGHTSTACK_HTBLSIZE; ++hashIndex)
        _hIndex[hashIndex] = -1;
    
    for(EGWint lightIndex = 0; lightIndex < EGW_LGHTSTACK_MAXLIGHTS; ++lightIndex) {
        _lights[lightIndex].light = nil;
        _lights[lightIndex].lFrame = EGW_FRAME_ALWAYSPASS;
        _lights[lightIndex].sortVal = -1.0f;
        _lights[lightIndex].rIndex = -1;
    }
    
    _lFrame = _lCount = 0;
    _farthest = -1;
    
    if (firstLight) {
        va_list argumentList;
        id<egwPLight> eachLight;
        
        [self addLight:firstLight sortByPosition:NULL];
        
        va_start(argumentList, firstLight);
        while(eachLight = va_arg(argumentList, id<egwPLight>))
            [self addLight:eachLight sortByPosition:NULL];
        va_end(argumentList);
    }
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    EGWuint8 lightsLeft = _lCount;
    egwLightStack* copy = nil;
    
    if(!(copy = [[egwLightStack allocWithZone:zone] init])) { return nil; }
    
    for(EGWint lightIndex = 0; lightsLeft && lightIndex < EGW_LGHTSTACK_MAXLIGHTS; ++lightIndex)
        if(_lights[lightIndex].light) {
            [copy addLight:_lights[lightIndex].light sortByPosition:NULL];
            --lightsLeft;
        }
    
    return copy;
}

- (void)dealloc {
    [self removeAllLights];
    
    [super dealloc];
}

- (void)addLight:(id<egwPLight>)light sortByPosition:(egwVector3f*)sortSource {
    EGWuint32 lightIndex;
    EGWuint16 lframe = [egwAIGfxCntx illuminationFrame];
    
    // Adding lights happens on every pass of illumination determination. It is
    // the responsibility of this method to ensure the light stack is filled
    // correctly and sorted (if need be) if more lights are illuminating the
    // object than what is supported.
    
    if(_lFrame != lframe) {
        // Remove lights if the stack is out of sync with the frame
        [self removeAllLights];
        _lFrame = lframe;
    }
    
    if(_lCount < EGW_LGHTSTACK_MAXLIGHTS) {
        EGWuint32 hashIndex;
        // Do an initial run through the hash indexing table. Hashing on the
        // light address will solve any duplication problems (at least on the
        // same illumination frame).
        
        lightIndex = hashIndex = egwHash32b((const EGWbyte*)&light, sizeof(id<egwPLight>)) % EGW_LGHTSTACK_HTBLSIZE;
        
        do {
            if(_hIndex[hashIndex] == -1) break;
            else {
                if(_lights[_hIndex[hashIndex]].light == light) break;
                else if(_lights[_hIndex[hashIndex]].lFrame != _lFrame) break;
            }
            
            hashIndex = (hashIndex + 7) % EGW_LGHTSTACK_HTBLSIZE;
        } while(hashIndex != lightIndex);
        
        if(_lights[_hIndex[hashIndex]].light != light) {
            lightIndex = _lCount++;
            _hIndex[hashIndex] = lightIndex;
            [light retain];
            [_lights[lightIndex].light release];
            _lights[lightIndex].light = light;
        }
        
        _lights[lightIndex].rIndex = hashIndex;
        _lights[lightIndex].lFrame = _lFrame;
        _lights[lightIndex].sortVal = -1.0f;
    } else if(sortSource) {
        id<egwPBounding> volume;
        EGWsingle sortVal;
        // At this point, the entire lights arrays has been filled with entries
        // that are at least at the current illumination frame, but we have to
        // now switch over to using a sorting algorithm.
        
        // Update sort values if first run-through
        if(_lights[0].sortVal == -1.0f) {
            for(lightIndex = 0; lightIndex < EGW_LGHTSTACK_MAXLIGHTS; ++lightIndex) {
                // Infinite boundings have no origin, thus special case
                volume = [_lights[lightIndex].light illuminationBounding];
                if(![(NSObject*)volume isMemberOfClass:[egwInfiniteBounding class]])
                    _lights[lightIndex].sortVal = egwVecDistanceSqrd3f(sortSource, (egwVector3f*)[volume boundingOrigin]);
                else
                    _lights[lightIndex].sortVal = 0.0f;
            }
        }
        
        // Find index with largest sort value (farthest distance)
        if(_farthest == -1) {
            _farthest = 0;
            for(lightIndex = 1; lightIndex < EGW_LGHTSTACK_MAXLIGHTS; ++lightIndex) {
                if(_lights[_farthest].sortVal < _lights[lightIndex].sortVal - EGW_SFLT_EPSILON)
                    _farthest = lightIndex;
            }
        }
        
        // Calculate this lights sort value
        // Infinite boundings have no origin, thus special case
        volume = [light illuminationBounding];
        if(![(NSObject*)volume isMemberOfClass:[egwInfiniteBounding class]])
            sortVal = egwVecDistanceSqrd3f(sortSource, (egwVector3f*)[volume boundingOrigin]);
        else
            sortVal = 0.0f;
        
        // See if this light is closer than farthest light in stack
        if(sortVal < _lights[_farthest].sortVal - EGW_SFLT_EPSILON) {
            if(_lights[_hIndex[_farthest]].light != light) {
                [light retain];
                [_lights[_farthest].light release];
                _lights[_farthest].light = light;
            }
            _lights[_farthest].lFrame = _lFrame;
            _lights[_farthest].sortVal = sortVal;
            _hIndex[_lights[_farthest].rIndex] = -1; // Not using indexing atm
            _lights[_farthest].rIndex = -1;
            _farthest = -1; // Pickup on next add
        }
    }
}

- (void)removeAllLights {
    for(EGWint hashIndex = 0; hashIndex < EGW_LGHTSTACK_HTBLSIZE; ++hashIndex)
        _hIndex[hashIndex] = -1;
    
    for(EGWint lightIndex = 0; lightIndex < EGW_LGHTSTACK_MAXLIGHTS; ++lightIndex) {
        [_lights[lightIndex].light release]; _lights[lightIndex].light = nil;
        _lights[lightIndex].lFrame = EGW_FRAME_ALWAYSPASS;
        _lights[lightIndex].sortVal = -1.0f;
        _lights[lightIndex].rIndex = -1;
    }
    
    _lFrame = _lCount = 0;
    _farthest = -1;
}

- (void)pushLights {
    EGWuint8 lightsLeft = _lCount;
    EGWuint16 lframe = [egwAIGfxCntx illuminationFrame];
    
    if(_lFrame == lframe) {
        for(EGWint lightIndex = 0; lightsLeft && lightIndex < EGW_LGHTSTACK_MAXLIGHTS; ++lightIndex) {
            if(_lights[lightIndex].light) {
                if(_lights[lightIndex].lFrame == _lFrame) {
                    egwAFPGfxCntxPushLight(egwAIGfxCntx, @selector(pushLight:), _lights[lightIndex].light);
                    --lightsLeft;
                } else
                    _lights[lightIndex].lFrame = EGW_FRAME_ALWAYSPASS; // Set to invalid spot for now
            }
        }
    } else {
        // No time to be removing lights right now - wait till next frame update.
        _lFrame = EGW_FRAME_ALWAYSPASS;
        _lCount = 0;
        _farthest = -1;
    }
}

- (void)pushAndBindLights {
    EGWuint8 lightsLeft = _lCount;
    EGWuint16 lframe = [egwAIGfxCntx illuminationFrame];
    
    if(_lFrame == lframe) {
        for(EGWint lightIndex = 0; lightsLeft && lightIndex < EGW_LGHTSTACK_MAXLIGHTS; ++lightIndex) {
            if(_lights[lightIndex].light) {
                if(_lights[lightIndex].lFrame == _lFrame) {
                    egwAFPGfxCntxPushLight(egwAIGfxCntx, @selector(pushLight:), _lights[lightIndex].light);
                    --lightsLeft;
                } else
                    _lights[lightIndex].lFrame = EGW_FRAME_ALWAYSPASS; // Set to invalid spot for now
            }
        }
    } else {
        // No time to be removing lights right now - wait till next frame update.
        _lFrame = EGW_FRAME_ALWAYSPASS;
        _lCount = 0;
        _farthest = -1;
    }
    
    egwAFPGfxCntxBindLights(egwAIGfxCntx, @selector(bindLights));
}

- (void)popLights {
    egwAFPGfxCntxPopLights(egwAIGfxCntx, @selector(popLights:), (EGWuint)_lCount);
}

- (EGWuint)lightCount {
    return (EGWuint)_lCount;
}

@end


// !!!: ***** egwMaterialStack *****

@implementation egwMaterialStack

- (id)init {
    return (self = [self initWithMaterials:nil]);
}

- (id)initWithMaterials:(id<egwPMaterial>)firstMaterial, ... {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    for(EGWint materialIndex = 0; materialIndex < EGW_MTRLSTACK_MAXMATERIALS; ++materialIndex)
        _materials[materialIndex].material = nil;
    _mCount = 0;
    
    if (firstMaterial) {
        va_list argumentList;
        id<egwPMaterial> eachMaterial;
        
        [self addMaterial:firstMaterial];
        
        va_start(argumentList, firstMaterial);
        while(eachMaterial = va_arg(argumentList, id<egwPMaterial>))
            [self addMaterial:eachMaterial];
        va_end(argumentList);
    }
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwMaterialStack* copy = nil;
    
    if(!(copy = [[egwMaterialStack allocWithZone:zone] init])) { return nil; }
    
    for(EGWint materialIndex = 0; materialIndex < _mCount; ++materialIndex)
        [copy addMaterial:_materials[materialIndex].material];
    
    return copy;
}

- (void)dealloc {
    [self removeAllMaterials];
    
    [super dealloc];
}

- (void)addMaterial:(id<egwPMaterial>)material {
    if(_mCount < EGW_MTRLSTACK_MAXMATERIALS)
        _materials[_mCount++].material = [material retain];
}

- (void)removeAllMaterials {
    for(EGWint materialIndex = 0; materialIndex < _mCount; ++materialIndex) {
        [_materials[materialIndex].material release]; _materials[materialIndex].material = nil;
    }
    
    _mCount = 0;
}

- (void)pushMaterials {
    for(EGWint materialIndex = 0; materialIndex < _mCount; ++materialIndex)
        egwAFPGfxCntxPushMaterial(egwAIGfxCntx, @selector(pushMaterial:), _materials[materialIndex].material);
}

- (void)pushAndBindMaterials {
    for(EGWint materialIndex = 0; materialIndex < _mCount; ++materialIndex)
        egwAFPGfxCntxPushMaterial(egwAIGfxCntx, @selector(pushMaterial:), _materials[materialIndex].material);
    
    egwAFPGfxCntxBindMaterials(egwAIGfxCntx, @selector(bindMaterials));
}

- (void)popMaterials {
    egwAFPGfxCntxPopMaterials(egwAIGfxCntx, @selector(popMaterials:), (EGWuint)_mCount);
}

- (EGWuint)materialCount {
    return (EGWuint)_mCount;
}

- (BOOL)isOpaque {
    for(EGWint materialIndex = 0; materialIndex < _mCount; ++materialIndex)
        if(![_materials[materialIndex].material isOpaque])
            return NO;
    return YES;
}

@end


// !!!: ***** egwTextureStack *****

@implementation egwTextureStack

- (id)init {
    return (self = [self initWithTextures:nil]);
}

- (id)initWithTextures:(id<egwPTexture>)firstTexture, ... {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    for(EGWint textureIndex = 0; textureIndex < EGW_TXTRSTACK_MAXTEXTURES; ++textureIndex)
        _textures[textureIndex].texture = nil;
    _tCount = 0;
    
    if (firstTexture) {
        va_list argumentList;
        id<egwPTexture> eachTexture;
        
        [self addTexture:firstTexture];
        
        va_start(argumentList, firstTexture);
        while(eachTexture = va_arg(argumentList, id<egwPTexture>))
            [self addTexture:eachTexture];
        va_end(argumentList);
    }
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwTextureStack* copy = nil;
    
    if(!(copy = [[egwTextureStack allocWithZone:zone] init])) { return nil; }
    
    for(EGWint textureIndex = 0; textureIndex < _tCount; ++textureIndex)
        [copy addTexture:_textures[textureIndex].texture];
    
    return copy;
}

- (void)dealloc {
    [self removeAllTextures];
    
    [super dealloc];
}

- (void)addTexture:(id<egwPTexture>)texture {
    if(_tCount < EGW_TXTRSTACK_MAXTEXTURES)
        _textures[_tCount++].texture = [texture retain];
}

- (void)removeAllTextures {
    for(EGWint textureIndex = 0; textureIndex < _tCount; ++textureIndex) {
        [_textures[textureIndex].texture release]; _textures[textureIndex].texture = nil;
    }
    
    _tCount = 0;
}

- (void)pushTextures {
    for(EGWint textureIndex = 0; textureIndex < _tCount; ++textureIndex)
        egwAFPGfxCntxPushTexture(egwAIGfxCntx, @selector(pushTexture:), _textures[textureIndex].texture);
}

- (void)pushAndBindTextures {
    for(EGWint textureIndex = 0; textureIndex < _tCount; ++textureIndex)
        egwAFPGfxCntxPushTexture(egwAIGfxCntx, @selector(pushTexture:), _textures[textureIndex].texture);
    
    egwAFPGfxCntxBindTextures(egwAIGfxCntx, @selector(bindTextures));
}

- (void)popTextures {
    egwAFPGfxCntxPopTextures(egwAIGfxCntx, @selector(popTextures:), (EGWuint)_tCount);
}

- (id<egwPTimed,egwPTexture>)firstTimedTexture {
    for(EGWint textureIndex = 0; textureIndex < _tCount; ++textureIndex)
        if([(NSObject*)_textures[textureIndex].texture conformsToProtocol:@protocol(egwPTimed)])
            return (id<egwPTimed,egwPTexture>)_textures[textureIndex].texture;
    return nil;
}

- (EGWuint)textureCount {
    return (EGWuint)_tCount;
}

- (BOOL)isOpaque {
    for(EGWint textureIndex = 0; textureIndex < _tCount; ++textureIndex)
        if(![_textures[textureIndex].texture isOpaque])
            return NO;
    return YES;
}

@end

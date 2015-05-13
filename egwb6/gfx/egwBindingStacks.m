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
EGWuint32 (*egwSFPLghtStckStackHash)(id, SEL) = NULL;
void (*egwSFPMtrlStckPushAndBindMaterials)(id, SEL) = NULL;
void (*egwSFPMtrlStckPopMaterials)(id, SEL) = NULL;
EGWuint32 (*egwSFPMtrlStckStackHash)(id, SEL) = NULL;
BOOL (*egwSFPMtrlStckOpaque)(id, SEL) = NULL;
void (*egwSFPShdrStckPushAndBindShaders)(id, SEL) = NULL;
void (*egwSFPShdrStckPopShaders)(id, SEL) = NULL;
EGWuint32 (*egwSFPShdrStckStackHash)(id, SEL) = NULL;
BOOL (*egwSFPShdrStckOpaque)(id, SEL) = NULL;
void (*egwSFPTxtrStckPushAndBindTextures)(id, SEL) = NULL;
void (*egwSFPTxtrStckPopTextures)(id, SEL) = NULL;
EGWuint32 (*egwSFPTxtrStckStackHash)(id, SEL) = NULL;
BOOL (*egwSFPTxtrStckOpaque)(id, SEL) = NULL;


// !!!: ***** egwLightStack *****

@implementation egwLightStack

- (id)init {
    return (self = [self initWithLights:nil]);
}

- (id)initWithLights:(id<egwPLight>)firstLight, ... {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    for(EGWuint hashIndex = 0; hashIndex < EGW_LGHTSTACK_HTBLSIZE; ++hashIndex)
        _hIndex[hashIndex] = -1;
    
    for(EGWuint lightIndex = 0; lightIndex < EGW_LGHTSTACK_MAXLIGHTS; ++lightIndex) {
        _lights[lightIndex].light = nil;
        _lights[lightIndex].lFrame = EGW_FRAME_ALWAYSPASS;
        _lights[lightIndex].sortVal = -1.0f;
        _lights[lightIndex].rIndex = -1;
    }
    
    _lFrame = _lCount = 0;
    _farthest = -1;
    
    if(firstLight) {
        va_list argumentList;
        id<egwPLight> eachLight;
        
        [self addLight:firstLight sortByPosition:NULL];
        
        va_start(argumentList, firstLight);
        while((eachLight = va_arg(argumentList, id<egwPLight>)))
            [self addLight:eachLight sortByPosition:NULL];
        va_end(argumentList);
    }
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    EGWuint8 lightsLeft = _lCount;
    egwLightStack* copy = nil;
    
    if(!(copy = [[egwLightStack allocWithZone:zone] init])) { return nil; }
    
    for(EGWuint lightIndex = 0; lightsLeft && lightIndex < EGW_LGHTSTACK_MAXLIGHTS; ++lightIndex)
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
    EGWuint lightIndex;
    EGWuint16 lframe = egwAFPGfxCntxIlluminationFrame(egwAIGfxCntx, @selector(illuminationFrame));
    
    // Adding lights happens on every pass of illumination determination. It is
    // the responsibility of this method to ensure the light stack is filled
    // correctly and sorted (if need be) if more lights are illuminating the
    // object than what is supported.
    
    if(_lFrame != lframe) {
        // Remove lights if the stack is out of sync with the frame
        for(EGWuint hashIndex = 0; hashIndex < EGW_LGHTSTACK_HTBLSIZE; ++hashIndex)
            _hIndex[hashIndex] = -1;
        
        for(EGWuint lightIndex = 0; lightIndex < EGW_LGHTSTACK_MAXLIGHTS; ++lightIndex) {
            if(_lights[lightIndex].light) {
                _lights[lightIndex].jmpTbl->fpRelease(_lights[lightIndex].light, @selector(release)); _lights[lightIndex].light = nil;
                _lights[lightIndex].jmpTbl = NULL;
                _lights[lightIndex].lFrame = EGW_FRAME_ALWAYSPASS;
                _lights[lightIndex].sortVal = -1.0f;
                _lights[lightIndex].rIndex = -1;
            }
        }
        
        _lFrame = _lCount = 0;
        _farthest = -1;
        
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
            const egwLightJumpTable* jmpTbl = [light lightJumpTable];
            jmpTbl->fpRetain(light, @selector(retain));
            if(_lights[lightIndex].light)
                _lights[lightIndex].jmpTbl->fpRelease(_lights[lightIndex].light, @selector(release));
            _lights[lightIndex].light = light;
            _lights[lightIndex].jmpTbl = jmpTbl;
        }
        
        _lights[lightIndex].rIndex = hashIndex;
        _lights[lightIndex].lFrame = _lFrame;
        _lights[lightIndex].sortVal = -1.0f;
    } else if(sortSource) {
        // At this point, the entire lights arrays has been filled with entries
        // that are at least at the current illumination frame, but we have to
        // now switch over to using a sorting algorithm.
        
        // Update sort values if first run-through
        if(_lights[0].sortVal == -1.0f) {
            for(lightIndex = 0; lightIndex < EGW_LGHTSTACK_MAXLIGHTS; ++lightIndex) {
                id<egwPBounding> volume = _lights[lightIndex].jmpTbl->fpIBounding(_lights[lightIndex].light, @selector(illuminationBounding));
                _lights[lightIndex].sortVal = egwVecDistanceSqrd3f(sortSource, (egwVector3f*)[volume boundingOrigin]);
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
        const egwLightJumpTable* jmpTable = [light lightJumpTable];
        id<egwPBounding> volume = jmpTable->fpIBounding(light, @selector(illuminationBounding));
        EGWsingle sortVal = egwVecDistanceSqrd3f(sortSource, (egwVector3f*)[volume boundingOrigin]);
        
        // See if this light is closer than farthest light in stack
        if(sortVal < _lights[_farthest].sortVal - EGW_SFLT_EPSILON) {
            if(_lights[_hIndex[_farthest]].light != light) {
                const egwLightJumpTable* jmpTbl = [light lightJumpTable];
                jmpTbl->fpRetain(light, @selector(retain));
                if(_lights[_farthest].light)
                    _lights[_farthest].jmpTbl->fpRelease(_lights[_farthest].light, @selector(release));
                _lights[_farthest].light = light;
                _lights[_farthest].jmpTbl = jmpTbl;
            }
            _lights[_farthest].lFrame = _lFrame;
            _lights[_farthest].sortVal = sortVal;
            _hIndex[_lights[_farthest].rIndex] = -1; // Not using indexing atm
            _lights[_farthest].rIndex = -1;
            _farthest = -1; // Pickup on next add
        }
    }
    
    _sHash = 0;
    for(lightIndex = 0; lightIndex < EGW_LGHTSTACK_MAXLIGHTS; lightIndex++)
        if(_lights[lightIndex].light)
            _sHash += (egwHash32b((const EGWbyte*)&_lights[lightIndex].light, sizeof(id<egwPLight>)) &
                       (0xffffffff >> (32 - (32 / EGW_LGHTSTACK_MAXLIGHTS)))) <<
                      ((32 / EGW_LGHTSTACK_MAXLIGHTS) * (EGW_LGHTSTACK_MAXLIGHTS - (lightIndex + 1)));
}

- (void)removeAllLights {
    for(EGWuint hashIndex = 0; hashIndex < EGW_LGHTSTACK_HTBLSIZE; ++hashIndex)
        _hIndex[hashIndex] = -1;
    
    for(EGWuint lightIndex = 0; lightIndex < EGW_LGHTSTACK_MAXLIGHTS; ++lightIndex) {
        if(_lights[lightIndex].light) {
            _lights[lightIndex].jmpTbl->fpRelease(_lights[lightIndex].light, @selector(release)); _lights[lightIndex].light = nil;
            _lights[lightIndex].jmpTbl = NULL;
            _lights[lightIndex].lFrame = EGW_FRAME_ALWAYSPASS;
            _lights[lightIndex].sortVal = -1.0f;
            _lights[lightIndex].rIndex = -1;
        }
    }
    
    _lFrame = _lCount = 0;
    _farthest = -1;
    _sHash = 0;
}

- (void)pushLights {
    EGWuint8 lightsLeft = _lCount;
    EGWuint16 lframe = egwAFPGfxCntxIlluminationFrame(egwAIGfxCntx, @selector(illuminationFrame));
    
    if(_lFrame == lframe) {
        for(EGWuint lightIndex = 0; lightsLeft && lightIndex < EGW_LGHTSTACK_MAXLIGHTS; ++lightIndex) {
            if(_lights[lightIndex].light) {
                if(_lights[lightIndex].lFrame == _lFrame) {
                    egwAFPGfxCntxPushLight(egwAIGfxCntx, @selector(pushLight:withLightJumpTable:), _lights[lightIndex].light, _lights[lightIndex].jmpTbl);
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
    EGWuint16 lframe = egwAFPGfxCntxIlluminationFrame(egwAIGfxCntx, @selector(illuminationFrame));
    
    if(_lFrame == lframe) {
        for(EGWuint lightIndex = 0; lightsLeft && lightIndex < EGW_LGHTSTACK_MAXLIGHTS; ++lightIndex) {
            if(_lights[lightIndex].light) {
                if(_lights[lightIndex].lFrame == _lFrame) {
                    egwAFPGfxCntxPushLight(egwAIGfxCntx, @selector(pushLight:withLightJumpTable:), _lights[lightIndex].light, _lights[lightIndex].jmpTbl);
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

- (EGWuint32)stackHash {
    if(self)
        return _sHash;
    return 0;
}

@end


// !!!: ***** egwMaterialStack *****

@implementation egwMaterialStack

- (id)init {
    return (self = [self initWithMaterials:nil]);
}

- (id)initWithMaterials:(id<egwPMaterial>)firstMaterial, ... {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    for(EGWuint materialIndex = 0; materialIndex < EGW_MTRLSTACK_MAXMATERIALS; ++materialIndex)
        _materials[materialIndex].material = nil;
    _mCount = 0;
    
    if(firstMaterial) {
        va_list argumentList;
        id<egwPMaterial> eachMaterial;
        
        [self addMaterial:firstMaterial];
        
        va_start(argumentList, firstMaterial);
        while((eachMaterial = va_arg(argumentList, id<egwPMaterial>)))
            [self addMaterial:eachMaterial];
        va_end(argumentList);
    }
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwMaterialStack* copy = nil;
    
    if(!(copy = [[egwMaterialStack allocWithZone:zone] init])) { return nil; }
    
    for(EGWuint materialIndex = 0; materialIndex < _mCount; ++materialIndex)
        [copy addMaterial:_materials[materialIndex].material];
    
    return copy;
}

- (void)dealloc {
    [self removeAllMaterials];
    
    [super dealloc];
}

- (void)addMaterial:(id<egwPMaterial>)material {
    if(_mCount < EGW_MTRLSTACK_MAXMATERIALS) {
        _materials[_mCount].jmpTbl = [material materialJumpTable];
        _materials[_mCount].material = _materials[_mCount].jmpTbl->fpRetain(material, @selector(retain));
        
        _sHash += (egwHash32b((const EGWbyte*)&_materials[_mCount].material, sizeof(id<egwPMaterial>)) &
                   (0xffffffff >> (32 - (32 / EGW_MTRLSTACK_MAXMATERIALS)))) <<
                  ((32 / EGW_MTRLSTACK_MAXMATERIALS) * (EGW_MTRLSTACK_MAXMATERIALS - (_mCount + 1)));
        ++_mCount;
    }
}

- (void)removeAllMaterials {
    for(EGWuint materialIndex = 0; materialIndex < _mCount; ++materialIndex) {
        if(_materials[materialIndex].material) {
            _materials[materialIndex].jmpTbl->fpRelease(_materials[materialIndex].material, @selector(release)); _materials[materialIndex].material = nil;
            _materials[materialIndex].jmpTbl = NULL;
        }
    }
    
    _mCount = 0;
    _sHash = 0;
}

- (void)pushMaterials {
    for(EGWuint materialIndex = 0; materialIndex < _mCount; ++materialIndex)
        egwAFPGfxCntxPushMaterial(egwAIGfxCntx, @selector(pushMaterial:withMaterialJumpTable:), _materials[materialIndex].material, _materials[materialIndex].jmpTbl);
}

- (void)pushAndBindMaterials {
    for(EGWuint materialIndex = 0; materialIndex < _mCount; ++materialIndex)
        egwAFPGfxCntxPushMaterial(egwAIGfxCntx, @selector(pushMaterial:withMaterialJumpTable:), _materials[materialIndex].material, _materials[materialIndex].jmpTbl);
    
    egwAFPGfxCntxBindMaterials(egwAIGfxCntx, @selector(bindMaterials));
}

- (void)popMaterials {
    egwAFPGfxCntxPopMaterials(egwAIGfxCntx, @selector(popMaterials:), (EGWuint)_mCount);
}

- (EGWuint)materialCount {
    return (EGWuint)_mCount;
}

- (EGWuint32)stackHash {
    if(self)
        return _sHash;
    return 0;
}

- (BOOL)isOpaque {
    for(EGWuint materialIndex = 0; materialIndex < _mCount; ++materialIndex)
        if(_materials[materialIndex].material && !_materials[materialIndex].jmpTbl->fpOpaque(_materials[materialIndex].material, @selector(isOpaque)))
            return NO;
    return YES;
}

@end


// !!!: ***** egwShaderStack *****

@implementation egwShaderStack

- (id)init {
    return (self = [self initWithShaders:nil]);
}

- (id)initWithShaders:(id<egwPShader>)firstShader, ... {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    for(EGWuint shaderIndex = 0; shaderIndex < EGW_SHDRSTACK_MAXSHADERS; ++shaderIndex)
        _shaders[shaderIndex].shader = nil;
    _sCount = 0;
    
    if(firstShader) {
        va_list argumentList;
        id<egwPShader> eachShader;
        
        [self addShader:firstShader];
        
        va_start(argumentList, firstShader);
        while((eachShader = va_arg(argumentList, id<egwPShader>)))
            [self addShader:eachShader];
        va_end(argumentList);
    }
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwShaderStack* copy = nil;
    
    if(!(copy = [[egwShaderStack allocWithZone:zone] init])) { return nil; }
    
    for(EGWuint shaderIndex = 0; shaderIndex < _sCount; ++shaderIndex)
        [copy addShader:_shaders[shaderIndex].shader];
    
    return copy;
}

- (void)dealloc {
    [self removeAllShaders];
    
    [super dealloc];
}

- (void)addShader:(id<egwPShader>)shader {
    if(_sCount < EGW_SHDRSTACK_MAXSHADERS) {
        _shaders[_sCount].jmpTbl = [shader shaderJumpTable];
        _shaders[_sCount].shader = _shaders[_sCount].jmpTbl->fpRetain(shader, @selector(retain));
        
        if(!_hasTimed && [(NSObject*)_shaders[_sCount].shader conformsToProtocol:@protocol(egwPTimed)])
            _hasTimed = YES;
        _sHash += (egwHash32b((const EGWbyte*)[_shaders[_sCount].shader shaderID], sizeof(EGWuint)) &
                   (0xffffffff >> (32 - (32 / EGW_SHDRSTACK_MAXSHADERS)))) <<
                  ((32 / EGW_SHDRSTACK_MAXSHADERS) * (EGW_SHDRSTACK_MAXSHADERS - (_sCount + 1)));
        ++_sCount;
    }
}

- (void)removeAllShaders {
    for(EGWuint shaderIndex = 0; shaderIndex < _sCount; ++shaderIndex) {
        if(_shaders[shaderIndex].shader) {
            _shaders[shaderIndex].jmpTbl->fpRelease(_shaders[shaderIndex].shader, @selector(release)); _shaders[shaderIndex].shader = nil;
            _shaders[shaderIndex].jmpTbl = NULL;
        }
    }
    
    _sCount = 0;
    _hasTimed = NO;
    _sHash = 0;
}

- (void)pushShaders {
    for(EGWuint shaderIndex = 0; shaderIndex < _sCount; ++shaderIndex)
        egwAFPGfxCntxPushShader(egwAIGfxCntx, @selector(pushShader:withShaderJumpTable:), _shaders[shaderIndex].shader, _shaders[shaderIndex].jmpTbl);
}

- (void)pushAndBindShaders {
    for(EGWuint shaderIndex = 0; shaderIndex < _sCount; ++shaderIndex)
        egwAFPGfxCntxPushShader(egwAIGfxCntx, @selector(pushShader:withShaderJumpTable:), _shaders[shaderIndex].shader, _shaders[shaderIndex].jmpTbl);
    
    egwAFPGfxCntxBindShaders(egwAIGfxCntx, @selector(bindShaders));
}

- (void)popShaders {
    egwAFPGfxCntxPopShaders(egwAIGfxCntx, @selector(popShaders:), (EGWuint)_sCount);
}

- (id<egwPTimed,egwPShader>)firstTimedShader {
    for(EGWuint shaderIndex = 0; shaderIndex < _sCount; ++shaderIndex)
        if([(NSObject*)_shaders[shaderIndex].shader conformsToProtocol:@protocol(egwPTimed)])
            return (id<egwPTimed,egwPShader>)_shaders[shaderIndex].shader;
    return nil;
}

- (EGWuint)shaderCount {
    return (EGWuint)_sCount;
}

- (EGWuint32)stackHash {
    if(self) {
        if(_hasTimed) {
            _sHash = 0;
            for(EGWuint shaderIndex = 0; shaderIndex < _sCount; ++shaderIndex) {
                _sHash += (egwHash32b((const EGWbyte*)[_shaders[shaderIndex].shader shaderID], sizeof(EGWuint)) &
                           (0xffffffff >> (32 - (32 / EGW_SHDRSTACK_MAXSHADERS)))) <<
                          ((32 / EGW_SHDRSTACK_MAXSHADERS) * (EGW_SHDRSTACK_MAXSHADERS - (shaderIndex + 1)));
            }
        }
        
        return _sHash;
    }
    
    return 0;
}

- (BOOL)isOpaque {
    for(EGWuint shaderIndex = 0; shaderIndex < _sCount; ++shaderIndex)
        if(_shaders[shaderIndex].shader && !_shaders[shaderIndex].jmpTbl->fpOpaque(_shaders[shaderIndex].shader, @selector(isOpaque)))
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
    
    for(EGWuint textureIndex = 0; textureIndex < EGW_TXTRSTACK_MAXTEXTURES; ++textureIndex)
        _textures[textureIndex].texture = nil;
    _tCount = 0;
    
    if(firstTexture) {
        va_list argumentList;
        id<egwPTexture> eachTexture;
        
        [self addTexture:firstTexture];
        
        va_start(argumentList, firstTexture);
        while((eachTexture = va_arg(argumentList, id<egwPTexture>)))
            [self addTexture:eachTexture];
        va_end(argumentList);
    }
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    egwTextureStack* copy = nil;
    
    if(!(copy = [[egwTextureStack allocWithZone:zone] init])) { return nil; }
    
    for(EGWuint textureIndex = 0; textureIndex < _tCount; ++textureIndex)
        [copy addTexture:_textures[textureIndex].texture];
    
    return copy;
}

- (void)dealloc {
    [self removeAllTextures];
    
    [super dealloc];
}

- (void)addTexture:(id<egwPTexture>)texture {
    if(_tCount < EGW_TXTRSTACK_MAXTEXTURES) {
        _textures[_tCount].jmpTbl = [texture textureJumpTable];
        _textures[_tCount].texture = _textures[_tCount].jmpTbl->fpRetain(texture, @selector(retain));
        
        if(!_hasTimed && [(NSObject*)_textures[_tCount].texture conformsToProtocol:@protocol(egwPTimed)])
            _hasTimed = YES;
        _sHash += (egwHash32b((const EGWbyte*)[_textures[_tCount].texture textureID], sizeof(EGWuint)) &
                   (0xffffffff >> (32 - (32 / EGW_TXTRSTACK_MAXTEXTURES)))) <<
                  ((32 / EGW_TXTRSTACK_MAXTEXTURES) * (EGW_TXTRSTACK_MAXTEXTURES - (_tCount + 1)));
        ++_tCount;
    }
}

- (void)removeAllTextures {
    for(EGWuint textureIndex = 0; textureIndex < _tCount; ++textureIndex) {
        if(_textures[textureIndex].texture) {
            _textures[textureIndex].jmpTbl->fpRelease(_textures[textureIndex].texture, @selector(release)); _textures[textureIndex].texture = nil;
            _textures[textureIndex].jmpTbl = NULL;
        }
    }
    
    _tCount = 0;
    _hasTimed = NO;
    _sHash = 0;
}

- (void)pushTextures {
    for(EGWuint textureIndex = 0; textureIndex < _tCount; ++textureIndex)
        egwAFPGfxCntxPushTexture(egwAIGfxCntx, @selector(pushTexture:withTextureJumpTable:), _textures[textureIndex].texture, _textures[textureIndex].jmpTbl);
}

- (void)pushAndBindTextures {
    for(EGWuint textureIndex = 0; textureIndex < _tCount; ++textureIndex)
        egwAFPGfxCntxPushTexture(egwAIGfxCntx, @selector(pushTexture:withTextureJumpTable:), _textures[textureIndex].texture, _textures[textureIndex].jmpTbl);
    
    egwAFPGfxCntxBindTextures(egwAIGfxCntx, @selector(bindTextures));
}

- (void)popTextures {
    egwAFPGfxCntxPopTextures(egwAIGfxCntx, @selector(popTextures:), (EGWuint)_tCount);
}

- (id<egwPTimed,egwPTexture>)firstTimedTexture {
    for(EGWuint textureIndex = 0; textureIndex < _tCount; ++textureIndex)
        if([(NSObject*)_textures[textureIndex].texture conformsToProtocol:@protocol(egwPTimed)])
            return (id<egwPTimed,egwPTexture>)_textures[textureIndex].texture;
    return nil;
}

- (EGWuint32)stackHash {
    if(self) {
        if(_hasTimed) {
            _sHash = 0;
            for(EGWuint textureIndex = 0; textureIndex < _tCount; ++textureIndex) {
                _sHash += (egwHash32b((const EGWbyte*)[_textures[textureIndex].texture textureID], sizeof(EGWuint)) &
                           (0xffffffff >> (32 - (32 / EGW_TXTRSTACK_MAXTEXTURES)))) <<
                          ((32 / EGW_TXTRSTACK_MAXTEXTURES) * (EGW_TXTRSTACK_MAXTEXTURES - (textureIndex + 1)));
            }
        }
        
        return _sHash;
    }
    
    return 0;
}

- (EGWuint)textureCount {
    return (EGWuint)_tCount;
}

- (BOOL)isOpaque {
    for(EGWuint textureIndex = 0; textureIndex < _tCount; ++textureIndex)
        if(_textures[textureIndex].texture && !_textures[textureIndex].jmpTbl->fpOpaque(_textures[textureIndex].texture, @selector(isOpaque)))
            return NO;
    return YES;
}

@end

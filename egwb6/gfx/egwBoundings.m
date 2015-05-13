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

/// @file egwBoundings.m
/// @ingroup geWizES_gfx_boundings
/// Bounding Volume Implementations.

#import "egwBoundings.h"
#import "../math/egwMath.h"
#import "../math/egwVector.h"
#import "../math/egwMatrix.h"
#import "../geo/egwGeometry.h"


// !!!: ***** egwZeroBounding *****

@implementation egwZeroBounding

- (id)init {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    _origin.axis.w = 1.0f;
    
    [self reset];
    
    return self;
}

- (id)initWithOpticalSource:(const egwVector3f*)optSource vertexCount:(EGWuint16)vertexCount vertexCoords:(const egwVector3f*)vertexCoords vertexCoordsStride:(EGWintptr)vCoordsStride {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(optSource)
        egwVecCopy3f(optSource, (egwVector3f*)&(_origin));
    else {
        // Find center manually
        egwVecSummation3fv(vertexCoords, (egwVector3f*)&(_origin), vCoordsStride, vertexCount);
        egwVecUScale3f((egwVector3f*)&(_origin), 1.0f / (float)vertexCount, (egwVector3f*)&(_origin));
    }
    _origin.axis.w = 1.0f;
    
    return self;
}

- (id)initWithBoundingOrigin:(const egwVector3f*)bndOrigin {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    egwVecCopy3f(bndOrigin, (egwVector3f*)&(_origin));
    _origin.axis.w = 1.0f;
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    return [[egwZeroBounding allocWithZone:zone] initWithBoundingOrigin:(egwVector3f*)&(_origin)];
}

- (void)dealloc {
    [super dealloc];
}

- (void)mergeWithVolume:(const id<egwPBounding>)boundVolume {
    if(_origin.axis.x != -EGW_SFLT_MAX) {
        // Average position only (shape on infinite)
        egwVecAdd3f((egwVector3f*)[boundVolume boundingOrigin], (egwVector3f*)&_origin, (egwVector3f*)&_origin);
        egwVecUScale3f((egwVector3f*)&_origin, 0.5f, (egwVector3f*)&_origin);
    } else {
        // Direct copy-over (from reset)
        egwVecCopy3f((egwVector3f*)[boundVolume boundingOrigin], (egwVector3f*)&_origin);
    }
}

- (void)baseOffsetByTransform:(const egwMatrix44f*)transform {
    egwVecTransform444f(transform, &_origin, &_origin);
}

- (void)orientateByTransform:(const egwMatrix44f*)wcsTransform fromVolume:(id<egwPBounding>)lcsVolume {
    egwVecTransform444f(wcsTransform, [lcsVolume boundingOrigin], &_origin);
}

- (void)reset {
    _origin.axis.x = _origin.axis.y = _origin.axis.z = -EGW_SFLT_MAX;
}

- (EGWint)testCollisionWithPoint:(const egwVector3f*)point {
    return EGW_CLSNTEST_POINT_NONE;
}

- (EGWint)testCollisionWithLine:(const egwLine4f*)line startingAt:(EGWsingle*)begT endingAt:(EGWsingle*)endT {
    if(begT) *begT = EGW_SFLT_MAX;
    if(endT) *endT = -EGW_SFLT_MAX;
    return EGW_CLSNTEST_LINE_NONE;
}

- (EGWint)testCollisionWithPlane:(const egwPlane4f*)plane onSide:(EGWint*)side {
    if(side) *side = 0;
    return EGW_CLSNTEST_PLANE_NONE;
}

- (EGWint)testCollisionWithVolume:(const id<egwPBounding>)boundVolume {
    return EGW_CLSNTEST_BVOL_NONE;
}

- (const egwVector4f*)boundingOrigin {
    return &_origin;
}

- (BOOL)isCollidingWithPoint:(const egwVector3f*)point {
    return NO;
}

- (BOOL)isCollidingWithLine:(const egwLine4f*)line {
    return NO;
}

- (BOOL)isCollidingWithPlane:(const egwPlane4f*)plane {
    return NO;
}

- (BOOL)isCollidingWithVolume:(const id<egwPBounding>)boundVolume {
    return NO;
}

- (BOOL)isReset {
    return (_origin.axis.x == -EGW_SFLT_MAX ? YES : NO);
}

@end


// !!!: ***** egwInfiniteBounding *****

@implementation egwInfiniteBounding

- (id)init {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    _origin.axis.w = 1.0f;
    
    [self reset];
    
    return self;
}

- (id)initWithOpticalSource:(const egwVector3f*)optSource vertexCount:(EGWuint16)vertexCount vertexCoords:(const egwVector3f*)vertexCoords vertexCoordsStride:(EGWintptr)vCoordsStride {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(optSource)
        egwVecCopy3f(optSource, (egwVector3f*)&(_origin));
    else {
        // Find center manually
        egwVecSummation3fv(vertexCoords, (egwVector3f*)&(_origin), vCoordsStride, vertexCount);
        egwVecUScale3f((egwVector3f*)&(_origin), 1.0f / (float)vertexCount, (egwVector3f*)&(_origin));
    }
    _origin.axis.w = 1.0f;
    
    return self;
}

- (id)initWithBoundingOrigin:(const egwVector3f*)bndOrigin {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    egwVecCopy3f(bndOrigin, (egwVector3f*)&(_origin));
    _origin.axis.w = 1.0f;
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    return [[egwInfiniteBounding allocWithZone:zone] initWithBoundingOrigin:(egwVector3f*)&(_origin)];
}

- (void)dealloc {
    [super dealloc];
}

- (void)mergeWithVolume:(const id<egwPBounding>)boundVolume {
    if(![boundVolume isMemberOfClass:[egwZeroBounding class]]) {
        if(_origin.axis.x != -EGW_SFLT_MAX) {
            // Average position only (shape on infinite)
            egwVecAdd3f((egwVector3f*)[boundVolume boundingOrigin], (egwVector3f*)&_origin, (egwVector3f*)&_origin);
            egwVecUScale3f((egwVector3f*)&_origin, 0.5f, (egwVector3f*)&_origin);
        } else {
            // Direct copy-over (from reset)
            egwVecCopy3f((egwVector3f*)[boundVolume boundingOrigin], (egwVector3f*)&_origin);
        }
    }
}

- (void)baseOffsetByTransform:(const egwMatrix44f*)transform {
    egwVecTransform444f(transform, &_origin, &_origin);
}

- (void)orientateByTransform:(const egwMatrix44f*)wcsTransform fromVolume:(id<egwPBounding>)lcsVolume {
    egwVecTransform444f(wcsTransform, [lcsVolume boundingOrigin], &_origin);
}

- (void)reset {
    _origin.axis.x = _origin.axis.y = _origin.axis.z = -EGW_SFLT_MAX;
}

- (EGWint)testCollisionWithPoint:(const egwVector3f*)point {
    return EGW_CLSNTEST_POINT_CONTAINEDBY;
}

- (EGWint)testCollisionWithLine:(const egwLine4f*)line startingAt:(EGWsingle*)begT endingAt:(EGWsingle*)endT {
    if(begT) *begT = -EGW_SFLT_MAX;
    if(endT) *endT = EGW_SFLT_MAX;
    return EGW_CLSNTEST_LINE_INTERSECTS;
}

- (EGWint)testCollisionWithPlane:(const egwPlane4f*)plane onSide:(EGWint*)side {
    if(side) *side = 0;
    return EGW_CLSNTEST_PLANE_INTERSECTS;
}

- (EGWint)testCollisionWithVolume:(const id<egwPBounding>)boundVolume {
    if(![(NSObject*)boundVolume isMemberOfClass:[egwInfiniteBounding class]])
        return EGW_CLSNTEST_BVOL_CONTAINS;
    return EGW_CLSNTEST_BVOL_EQUALS;
}

- (const egwVector4f*)boundingOrigin {
    return &_origin;
}

- (BOOL)isCollidingWithPoint:(const egwVector3f*)point {
    return YES;
}

- (BOOL)isCollidingWithLine:(const egwLine4f*)line {
    return YES;
}

- (BOOL)isCollidingWithPlane:(const egwPlane4f*)plane {
    return YES;
}

- (BOOL)isCollidingWithVolume:(const id<egwPBounding>)boundVolume {
    return YES;
}

- (BOOL)isReset {
    return (_origin.axis.x == -EGW_SFLT_MAX ? YES : NO);
}

@end


// !!!: ***** egwBoundingSphere *****

@implementation egwBoundingSphere

- (id)init {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    _bounding.origin.axis.w = 1.0f;
    
    [self reset];
    
    return self;
}

- (id)initWithOpticalSource:(const egwVector3f*)optSource vertexCount:(EGWuint16)vertexCount vertexCoords:(const egwVector3f*)vertexCoords vertexCoordsStride:(EGWintptr)vCoordsStride {
    egwVector3f min, max;
    EGWsingle temp;
    
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(optSource)
        egwVecCopy3f(optSource, (egwVector3f*)&_bounding.origin);
    else {
        // Find center manually
        egwVecSummation3fv(vertexCoords, (egwVector3f*)&_bounding.origin, vCoordsStride, vertexCount);
        egwVecUScale3f((egwVector3f*)&_bounding.origin, 1.0f / (float)vertexCount, (egwVector3f*)&_bounding.origin);
    }
    _bounding.origin.axis.w = 1.0f;
    
    // TODO: Find a clever way to find the point that exists as farthest from origin. -jw
    egwVecFindExtentsAxs3fv(vertexCoords, &min, &max, vCoordsStride, vertexCount);
    _bounding.radius = egwVecDistanceSqrd3f((egwVector3f*)&_bounding.origin, &min);
    if(_bounding.radius < (temp = egwVecDistanceSqrd3f((egwVector3f*)&_bounding.origin, &max))) _bounding.radius = temp;
    _bounding.radius = egwSqrtf(_bounding.radius);
    
    return self;
}

- (id)initWithBoundingOrigin:(const egwVector3f*)bndOrigin boundingRadius:(EGWsingle)bndRadius {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    egwVecCopy3f(bndOrigin, (egwVector3f*)&_bounding.origin); _bounding.origin.axis.w = 1.0f;
    _bounding.radius = bndRadius;
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    return [[egwBoundingSphere allocWithZone:zone] initWithBoundingOrigin:(egwVector3f*)&_bounding.origin boundingRadius:_bounding.radius];
}

- (void)dealloc {
    [super dealloc];
}

- (void)mergeWithVolume:(const id<egwPBounding>)boundVolume {
    if([boundVolume isMemberOfClass:[egwBoundingSphere class]]) {
        const egwSphere4f* volume = [(egwBoundingSphere*)boundVolume boundingObject];
        
        if(_bounding.radius != -EGW_SFLT_MAX) {
            if(_bounding.radius != EGW_SFLT_MAX && volume->radius != EGW_SFLT_MAX) {
                egwVector3f diff; egwVecSubtract3f((egwVector3f*)&volume->origin, (egwVector3f*)&_bounding.origin, &diff);
                EGWsingle mag = egwVecMagnitudeSqrd3f(&diff);
                
                if(mag > (egwSignSqrdf(_bounding.radius - volume->radius) + EGW_SFLT_EPSILON)) { // Only extend if not already contained
                    mag = egwSqrtf(mag);
                    egwVecAdd3f((egwVector3f*)&_bounding.origin,
                                egwVecUScale3f(&diff, ((volume->radius + mag - _bounding.radius) * 0.5f) / mag, &diff),
                                (egwVector3f*)&_bounding.origin);
                    _bounding.radius = (_bounding.radius + mag + volume->radius) * 0.5f;
                }
            } else {
                // Average position only (shape on infinite)
                egwVecAdd3f((egwVector3f*)&volume->origin, (egwVector3f*)&_bounding.origin, (egwVector3f*)&_bounding.origin);
                egwVecUScale3f((egwVector3f*)&_bounding.origin, 0.5f, (egwVector3f*)&_bounding.origin);
                _bounding.radius = EGW_SFLT_MAX;
            }
        } else {
            // Direct copy-over (from reset)
            _bounding.origin.axis.x = volume->origin.axis.x;
            _bounding.origin.axis.y = volume->origin.axis.y;
            _bounding.origin.axis.z = volume->origin.axis.z;
            _bounding.radius = volume->radius;
        }
    } else if([boundVolume isMemberOfClass:[egwBoundingBox class]]) {
        const egwBox4f* volume = [(egwBoundingBox*)boundVolume boundingObject];
        
        if(_bounding.radius != -EGW_SFLT_MAX) {
            if(_bounding.radius != EGW_SFLT_MAX && volume->min.axis.x != -EGW_SFLT_MAX && volume->max.axis.x != EGW_SFLT_MAX) {
                egwVector3f diff; egwVecSubtract3f((egwVector3f*)&volume->max, (egwVector3f*)&_bounding.origin, &diff);
                EGWsingle mag;
                if(egwAbsf(diff.axis.x) < egwAbsf((mag = (volume->min.axis.x - _bounding.origin.axis.x)))) diff.axis.x = mag;
                if(egwAbsf(diff.axis.y) < egwAbsf((mag = (volume->min.axis.y - _bounding.origin.axis.y)))) diff.axis.y = mag;
                if(egwAbsf(diff.axis.z) < egwAbsf((mag = (volume->min.axis.z - _bounding.origin.axis.z)))) diff.axis.z = mag;
                mag = egwVecMagnitudeSqrd3f(&diff);
                
                if(mag > (egwSqrd(_bounding.radius) + EGW_SFLT_EPSILON)) { // Only extend if not already contained
                    mag = egwSqrtf(mag);
                    egwVecAdd3f((egwVector3f*)&_bounding.origin,
                                egwVecUScale3f(&diff, ((mag - _bounding.radius) * 0.5f) / mag, &diff),
                                (egwVector3f*)&_bounding.origin);
                    _bounding.radius = (_bounding.radius + mag) * 0.5f;
                }
            } else {
                const egwVector4f* volOrigin = [boundVolume boundingOrigin];
                
                // Average position only (shape on infinite)
                egwVecAdd3f((egwVector3f*)volOrigin, (egwVector3f*)&_bounding.origin, (egwVector3f*)&_bounding.origin);
                egwVecUScale3f((egwVector3f*)&_bounding.origin, 0.5f, (egwVector3f*)&_bounding.origin);
                _bounding.radius = EGW_SFLT_MAX;
            }
        } else {
            const egwVector4f* volOrigin = [boundVolume boundingOrigin];
            
            // Direct copy-over (from reset)
            _bounding.origin.axis.x = volOrigin->axis.x;
            _bounding.origin.axis.y = volOrigin->axis.y;
            _bounding.origin.axis.z = volOrigin->axis.z;
            _bounding.radius = egwVecDistance3f((egwVector3f*)volOrigin, (egwVector3f*)&volume->max);
        }
    } else if([boundVolume isMemberOfClass:[egwBoundingCylinder class]]) {
        const egwCylinder4f* volume = [(egwBoundingCylinder*)boundVolume boundingObject];
        
        if(_bounding.radius != -EGW_SFLT_MAX) {
            if(_bounding.radius != EGW_SFLT_MAX && volume->radius != EGW_SFLT_MAX) {
                egwVector3f diff;
                EGWsingle mag;
                diff.axis.x = volume->origin.axis.x - _bounding.origin.axis.x;
                diff.axis.y = (volume->origin.axis.y + volume->hHeight) - _bounding.origin.axis.y;
                if(egwAbsf(diff.axis.y) < egwAbsf((mag = ((volume->origin.axis.y - volume->hHeight) - _bounding.origin.axis.y)))) diff.axis.y = mag;
                diff.axis.z = volume->origin.axis.z - _bounding.origin.axis.z;
                mag = egwVecMagnitudeSqrd3f(&diff);
                
                if(mag > (egwSqrd(_bounding.radius) + EGW_SFLT_EPSILON)) { // Only extend if not already contained
                    mag = egwSqrtf(mag);
                    egwVecAdd3f((egwVector3f*)&_bounding.origin,
                                egwVecUScale3f(&diff, ((mag - _bounding.radius) * 0.5f) / mag, &diff),
                                (egwVector3f*)&_bounding.origin);
                    _bounding.radius = (_bounding.radius + mag) * 0.5f;
                }
            } else {
                // Average position only (shape on infinite)
                egwVecAdd3f((egwVector3f*)&volume->origin, (egwVector3f*)&_bounding.origin, (egwVector3f*)&_bounding.origin);
                egwVecUScale3f((egwVector3f*)&_bounding.origin, 0.5f, (egwVector3f*)&_bounding.origin);
                _bounding.radius = EGW_SFLT_MAX;
            }
        } else {
            // Direct copy-over (from reset)
            _bounding.origin.axis.x = volume->origin.axis.x;
            _bounding.origin.axis.y = volume->origin.axis.y;
            _bounding.origin.axis.z = volume->origin.axis.z;
            _bounding.radius = egwSqrtf(egwSqrdf(volume->radius + volume->hHeight));
        }
    } else if([boundVolume isMemberOfClass:[egwBoundingFrustum class]]) {
        NSLog(@"egwBoundingSphere: mergeWithVolume: Error: Method not implemented for bounding sphere vs. bounding frustum.");
        // TODO: egwBoundingSphere: mergeWithVolume: egwBoundingFrustum.
    } else {
        if(![boundVolume isMemberOfClass:[egwZeroBounding class]]) { // Zero bounding does nothing to extend
            if(_bounding.radius != -EGW_SFLT_MAX) {
                // Average position only
                egwVecAdd3f((egwVector3f*)[boundVolume boundingOrigin], (egwVector3f*)&_bounding.origin, (egwVector3f*)&_bounding.origin);
                egwVecUScale3f((egwVector3f*)&_bounding.origin, 0.5f, (egwVector3f*)&_bounding.origin);
            } else {
                // Direct copy-over (from reset)
                egwVecCopy3f((egwVector3f*)[boundVolume boundingOrigin], (egwVector3f*)&_bounding.origin);
            }
            
            if([boundVolume isMemberOfClass:[egwInfiniteBounding class]])
                _bounding.radius = EGW_SFLT_MAX;
        }
    }
}

- (void)baseOffsetByTransform:(const egwMatrix44f*)transform {
    if(!transform) transform = &egwSIMatIdentity44f;
    
    egwVecTransform444f(transform, &_bounding.origin, &_bounding.origin);
    // FIXME: I'm unsure if this is the right way to find the wcsRadius, given that more than scaling (i.e. skewing) is at work here. I think you have to find the max value of the skew-symetry. -jw
    _bounding.radius = _bounding.radius * egwMax2f(1.0f, egwMax2f(egwMax2f(transform->component.r1c1, transform->component.r2c2), transform->component.r3c3));
}

- (void)orientateByTransform:(const egwMatrix44f*)wcsTransform fromVolume:(id<egwPBounding>)lcsVolume {
    if(!wcsTransform) wcsTransform = &egwSIMatIdentity44f;
    
    egwVecTransform444f(wcsTransform, [lcsVolume boundingOrigin], &_bounding.origin);
    
    if([lcsVolume isMemberOfClass:[egwBoundingSphere class]]) {
        // FIXME: I'm unsure if this is the right way to find the wcsRadius, given that more than scaling (i.e. skewing) is at work here. I think you have to find the max value of the skew-symetry. -jw
        _bounding.radius = [(egwBoundingSphere*)lcsVolume boundingRadius] * egwMax2f(1.0f, egwMax2f(egwMax2f(egwAbsf(wcsTransform->component.r1c1), egwAbsf(wcsTransform->component.r2c2)), egwAbsf(wcsTransform->component.r3c3)));
    } else if([lcsVolume isMemberOfClass:[egwBoundingBox class]]) {
        egwVector3f edges[8], min, max;
        EGWsingle temp;
        
        // Transform all edges in order to find extent after the transform
        const egwBox4f* volume = [(egwBoundingBox*)lcsVolume boundingObject];
        
        edges[0].axis.x = volume->min.axis.x; edges[0].axis.y = volume->min.axis.y; edges[0].axis.z = volume->min.axis.z; // mmm
        edges[1].axis.x = volume->min.axis.x; edges[1].axis.y = volume->min.axis.y; edges[1].axis.z = volume->max.axis.z; // mmM
        edges[2].axis.x = volume->min.axis.x; edges[2].axis.y = volume->max.axis.y; edges[2].axis.z = volume->min.axis.z; // mMm
        edges[3].axis.x = volume->min.axis.x; edges[3].axis.y = volume->max.axis.y; edges[3].axis.z = volume->max.axis.z; // mMM
        edges[4].axis.x = volume->max.axis.x; edges[4].axis.y = volume->min.axis.y; edges[4].axis.z = volume->min.axis.z; // Mmm
        edges[5].axis.x = volume->max.axis.x; edges[5].axis.y = volume->min.axis.y; edges[5].axis.z = volume->max.axis.z; // MmM
        edges[6].axis.x = volume->max.axis.x; edges[6].axis.y = volume->max.axis.y; edges[6].axis.z = volume->min.axis.z; // MMm
        edges[7].axis.x = volume->max.axis.x; edges[7].axis.y = volume->max.axis.y; edges[7].axis.z = volume->max.axis.z; // MMM
        
        egwVecTransform443fv(wcsTransform, &edges[0], &egwSIOnef, &edges[0], -sizeof(egwMatrix44f), 0, -sizeof(float), 0, 8);
        
        egwVecFindExtentsAxs3fv(&edges[0], &min, &max, 0, 8);
        
        _bounding.radius = egwVecDistanceSqrd3f((egwVector3f*)&_bounding.origin, &min);
        if(_bounding.radius < (temp = egwVecDistanceSqrd3f((egwVector3f*)&_bounding.origin, &max))) _bounding.radius = temp;
        _bounding.radius = egwSqrtf(_bounding.radius);
    } else if([lcsVolume isMemberOfClass:[egwBoundingCylinder class]]) {
        const egwCylinder4f* volume = [(egwBoundingCylinder*)lcsVolume boundingObject];
        
        // FIXME: I'm unsure if this is the right way to find the wcsRadius, given that more than scaling (i.e. skewing) is at work here. I think you have to find the max value of the skew-symetry. -jw
        EGWsingle radius = volume->radius * egwMax2f(1.0f, egwMax2f(egwAbsf(wcsTransform->component.r1c1), egwAbsf(wcsTransform->component.r3c3)));
        EGWsingle halfHeight = volume->hHeight * egwMax2f(1.0f, egwAbsf(wcsTransform->component.r2c2));
        
        _bounding.radius = egwSqrtf(egwSqrdf(radius + halfHeight));
    } else if([lcsVolume isMemberOfClass:[egwBoundingFrustum class]]) {
        NSLog(@"egwBoundingSphere: orientateByTransform:fromVolume: Error: Method not implemented for bounding sphere vs. bounding frustum.");
        // TODO: egwBoundingSphere: orientateByTransform:fromVolume: egwBoundingFrustum.
    } else if([lcsVolume isMemberOfClass:[egwInfiniteBounding class]]) {
        _bounding.radius = EGW_SFLT_MAX;
    } else if([lcsVolume isMemberOfClass:[egwZeroBounding class]]) {
        _bounding.radius = 0.0f;
    }
}

- (void)reset {
    _bounding.origin.axis.x = _bounding.origin.axis.y = _bounding.origin.axis.z = _bounding.radius = -EGW_SFLT_MAX;
}

- (EGWint)testCollisionWithPoint:(const egwVector3f*)point {
    return egwTestCollisionSpherePointf(&_bounding, point);
}

- (EGWint)testCollisionWithLine:(const egwLine4f*)line startingAt:(EGWsingle*)begT endingAt:(EGWsingle*)endT {
    return egwTestCollisionSphereLinef(&_bounding, line, begT, endT);
}

- (EGWint)testCollisionWithPlane:(const egwPlane4f*)plane onSide:(EGWint*)side {
    return egwTestCollisionSpherePlanef(&_bounding, plane, side);
}

- (EGWint)testCollisionWithVolume:(const id<egwPBounding>)boundVolume {
    if([boundVolume isMemberOfClass:[egwBoundingSphere class]]) {
        return egwTestCollisionSphereSpheref(&_bounding, [(egwBoundingSphere*)boundVolume boundingObject]);
    } else if([boundVolume isMemberOfClass:[egwBoundingBox class]]) {
        return egwTestCollisionSphereBoxf(&_bounding, [(egwBoundingBox*)boundVolume boundingObject]);
    } else if([boundVolume isMemberOfClass:[egwBoundingCylinder class]]) {
        return egwTestCollisionSphereCylinderf(&_bounding, [(egwBoundingCylinder*)boundVolume boundingObject]);
    } else if([boundVolume isMemberOfClass:[egwBoundingFrustum class]]) {
        return egwTestCollisionSphereFrustumf(&_bounding, [(egwBoundingFrustum*)boundVolume boundingObject]);
    } else if([boundVolume isMemberOfClass:[egwInfiniteBounding class]]) {
        return EGW_CLSNTEST_BVOL_CONTAINEDBY;
    } else if([boundVolume isMemberOfClass:[egwZeroBounding class]]) {
        return EGW_CLSNTEST_BVOL_NONE;
    }
    
    return EGW_CLSNTEST_BVOL_NA;
}

- (const egwVector4f*)boundingOrigin {
    return &_bounding.origin;
}

- (const egwSphere4f*)boundingObject {
    return &_bounding;
}

- (EGWsingle)boundingRadius {
    return _bounding.radius;
}

- (BOOL)isCollidingWithPoint:(const egwVector3f*)point {
    return (egwIsCollidingSpherePointf(&_bounding, point) > 0) ? YES : NO;
}

- (BOOL)isCollidingWithLine:(const egwLine4f*)line {
    return (egwIsCollidingSphereLinef(&_bounding, line) > 0) ? YES : NO;
}

- (BOOL)isCollidingWithPlane:(const egwPlane4f*)plane {
    return (egwIsCollidingSpherePlanef(&_bounding, plane) > 0) ? YES : NO;
}

- (BOOL)isCollidingWithVolume:(const id<egwPBounding>)boundVolume {
    if([boundVolume isMemberOfClass:[egwBoundingSphere class]]) {
        return (egwIsCollidingSphereSpheref(&_bounding, [(egwBoundingSphere*)boundVolume boundingObject]) > 0) ? YES : NO;
    } else if([boundVolume isMemberOfClass:[egwBoundingBox class]]) {
        return (egwIsCollidingSphereBoxf(&_bounding, [(egwBoundingBox*)boundVolume boundingObject]) > 0) ? YES : NO;
    } else if([boundVolume isMemberOfClass:[egwBoundingCylinder class]]) {
        return (egwIsCollidingSphereCylinderf(&_bounding, [(egwBoundingCylinder*)boundVolume boundingObject]) > 0) ? YES : NO;
    } else if([boundVolume isMemberOfClass:[egwBoundingFrustum class]]) {
        return (egwIsCollidingSphereFrustumf(&_bounding, [(egwBoundingFrustum*)boundVolume boundingObject]) > 0) ? YES : NO;
    } else if([boundVolume isMemberOfClass:[egwInfiniteBounding class]]) {
        return YES;
    } else if([boundVolume isMemberOfClass:[egwZeroBounding class]]) {
        return NO;
    }
    
    return NO;
}

- (BOOL)isReset {
    return (_bounding.radius == -EGW_SFLT_MAX ? YES : NO);
}

@end


// !!!: ***** egwBoundingBox *****

@implementation egwBoundingBox

- (id)init {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    _bounding.origin.axis.w = 1.0f;
    
    [self reset];
    
    return self;
}

- (id)initWithOpticalSource:(const egwVector3f*)optSource vertexCount:(EGWuint16)vertexCount vertexCoords:(const egwVector3f*)vertexCoords vertexCoordsStride:(EGWintptr)vCoordsStride {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(optSource)
        egwVecCopy3f(optSource, (egwVector3f*)&_bounding.origin);
    else {
        // Find center manually
        egwVecSummation3fv(vertexCoords, (egwVector3f*)&_bounding.origin, vCoordsStride, vertexCount);
        egwVecUScale3f((egwVector3f*)&_bounding.origin, 1.0f / (float)vertexCount, (egwVector3f*)&_bounding.origin);
    }
    _bounding.origin.axis.w = 1.0f;
    
    egwVecFindExtentsAxs3fv(vertexCoords, (egwVector3f*)&_bounding.min, (egwVector3f*)&_bounding.max, vCoordsStride, vertexCount);
    _bounding.min.axis.w = _bounding.max.axis.w =  1.0f;
    
    return self;
}

- (id)initWithBoundingOrigin:(const egwVector3f*)bndOrigin boundingMinimum:(egwVector3f*)bndMinimum boundingMaximum:(egwVector3f*)bndMaximum {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    egwVecCopy3f(bndOrigin, (egwVector3f*)&_bounding.origin); _bounding.origin.axis.w = 1.0f;
    egwVecCopy3f(bndMinimum, (egwVector3f*)&_bounding.min); _bounding.min.axis.w = 1.0f;
    egwVecCopy3f(bndMaximum, (egwVector3f*)&_bounding.max); _bounding.max.axis.w = 1.0f;
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    return [[egwBoundingBox allocWithZone:zone] initWithBoundingOrigin:(egwVector3f*)&_bounding.origin boundingMinimum:(egwVector3f*)&_bounding.min boundingMaximum:(egwVector3f*)&_bounding.max];
}

- (void)dealloc {
    [super dealloc];
}

- (void)mergeWithVolume:(const id<egwPBounding>)boundVolume {
    if([boundVolume isMemberOfClass:[egwBoundingBox class]]) {
        const egwBox4f* volume = [(egwBoundingBox*)boundVolume boundingObject];
        const egwVector4f* volOrigin = [boundVolume boundingOrigin];
        
        if(_bounding.origin.axis.x != -EGW_SFLT_MAX) {
            if(_bounding.min.axis.x != -EGW_SFLT_MAX && _bounding.max.axis.x != EGW_SFLT_MAX && volume->min.axis.x != -EGW_SFLT_MAX && volume->max.axis.x != EGW_SFLT_MAX) {
                if(_bounding.min.axis.x > volume->min.axis.x) _bounding.min.axis.x = volume->min.axis.x;
                if(_bounding.min.axis.y > volume->min.axis.y) _bounding.min.axis.y = volume->min.axis.y;
                if(_bounding.min.axis.z > volume->min.axis.z) _bounding.min.axis.z = volume->min.axis.z;
                if(_bounding.max.axis.x < volume->max.axis.x) _bounding.max.axis.x = volume->max.axis.x;
                if(_bounding.max.axis.y < volume->max.axis.y) _bounding.max.axis.y = volume->max.axis.y;
                if(_bounding.max.axis.z < volume->max.axis.z) _bounding.max.axis.z = volume->max.axis.z;
                _bounding.origin.axis.x = (_bounding.min.axis.x + _bounding.max.axis.x) * 0.5f;
                _bounding.origin.axis.y = (_bounding.min.axis.y + _bounding.max.axis.y) * 0.5f;
                _bounding.origin.axis.z = (_bounding.min.axis.z + _bounding.max.axis.z) * 0.5f;
            } else {
                // Average position only (shape on infinite)
                egwVecAdd3f((egwVector3f*)volOrigin, (egwVector3f*)&_bounding.origin, (egwVector3f*)&_bounding.origin);
                egwVecUScale3f((egwVector3f*)&_bounding.origin, 0.5f, (egwVector3f*)&_bounding.origin);
                _bounding.min.axis.x = _bounding.min.axis.y = _bounding.min.axis.z = -EGW_SFLT_MAX;
                _bounding.max.axis.x = _bounding.max.axis.y = _bounding.max.axis.z = EGW_SFLT_MAX;
            }
        } else {
            // Direct copy-over (from reset)
            _bounding.origin.axis.x = volOrigin->axis.x;
            _bounding.origin.axis.y = volOrigin->axis.y;
            _bounding.origin.axis.z = volOrigin->axis.z;
            _bounding.min.axis.x = volume->min.axis.x;
            _bounding.min.axis.y = volume->min.axis.y;
            _bounding.min.axis.z = volume->min.axis.z;
            _bounding.max.axis.x = volume->max.axis.x;
            _bounding.max.axis.y = volume->max.axis.y;
            _bounding.max.axis.z = volume->max.axis.z;
        }
    } else if([boundVolume isMemberOfClass:[egwBoundingSphere class]]) {
        const egwSphere4f* volume = [(egwBoundingSphere*)boundVolume boundingObject];
        
        if(_bounding.origin.axis.x != -EGW_SFLT_MAX) {
            if(_bounding.min.axis.x != -EGW_SFLT_MAX && _bounding.max.axis.x != EGW_SFLT_MAX && volume->radius != EGW_SFLT_MAX) {
                EGWsingle temp;
                if(_bounding.min.axis.x > (temp = volume->origin.axis.x - volume->radius)) _bounding.min.axis.x = temp;
                if(_bounding.min.axis.y > (temp = volume->origin.axis.y - volume->radius)) _bounding.min.axis.y = temp;
                if(_bounding.min.axis.z > (temp = volume->origin.axis.z - volume->radius)) _bounding.min.axis.z = temp;
                if(_bounding.max.axis.x < (temp = volume->origin.axis.x + volume->radius)) _bounding.max.axis.x = temp;
                if(_bounding.max.axis.y < (temp = volume->origin.axis.y + volume->radius)) _bounding.max.axis.y = temp;
                if(_bounding.max.axis.z < (temp = volume->origin.axis.z + volume->radius)) _bounding.max.axis.z = temp;
                _bounding.origin.axis.x = (_bounding.min.axis.x + _bounding.max.axis.x) * 0.5f;
                _bounding.origin.axis.y = (_bounding.min.axis.y + _bounding.max.axis.y) * 0.5f;
                _bounding.origin.axis.z = (_bounding.min.axis.z + _bounding.max.axis.z) * 0.5f;
            } else {
                // Average position only (shape on infinite)
                egwVecAdd3f((egwVector3f*)&volume->origin, (egwVector3f*)&_bounding.origin, (egwVector3f*)&_bounding.origin);
                egwVecUScale3f((egwVector3f*)&_bounding.origin, 0.5f, (egwVector3f*)&_bounding.origin);
                _bounding.min.axis.x = _bounding.min.axis.y = _bounding.min.axis.z = -EGW_SFLT_MAX;
                _bounding.max.axis.x = _bounding.max.axis.y = _bounding.max.axis.z = EGW_SFLT_MAX;
            }
        } else {
            // Direct copy-over (from reset)
            _bounding.origin.axis.x = volume->origin.axis.x;
            _bounding.origin.axis.y = volume->origin.axis.y;
            _bounding.origin.axis.z = volume->origin.axis.z;
            _bounding.min.axis.x = volume->origin.axis.x - volume->radius;
            _bounding.min.axis.y = volume->origin.axis.y - volume->radius;
            _bounding.min.axis.z = volume->origin.axis.z - volume->radius;
            _bounding.max.axis.x = volume->origin.axis.x + volume->radius;
            _bounding.max.axis.y = volume->origin.axis.y + volume->radius;
            _bounding.max.axis.z = volume->origin.axis.z + volume->radius;
        }
    } else if([boundVolume isMemberOfClass:[egwBoundingCylinder class]]) {
        const egwCylinder4f* volume = [(egwBoundingCylinder*)boundVolume boundingObject];
        
        if(_bounding.origin.axis.x != -EGW_SFLT_MAX) {
            if(_bounding.min.axis.x != -EGW_SFLT_MAX && _bounding.max.axis.x != EGW_SFLT_MAX && volume->radius != EGW_SFLT_MAX) {
                EGWsingle temp;
                if(_bounding.min.axis.x > (temp = volume->origin.axis.x - volume->radius)) _bounding.min.axis.x = temp;
                if(_bounding.min.axis.y > (temp = volume->origin.axis.y - volume->hHeight)) _bounding.min.axis.y = temp;
                if(_bounding.min.axis.z > (temp = volume->origin.axis.z - volume->radius)) _bounding.min.axis.z = temp;
                if(_bounding.max.axis.x < (temp = volume->origin.axis.x + volume->radius)) _bounding.max.axis.x = temp;
                if(_bounding.max.axis.y < (temp = volume->origin.axis.y + volume->hHeight)) _bounding.max.axis.y = temp;
                if(_bounding.max.axis.z < (temp = volume->origin.axis.z + volume->radius)) _bounding.max.axis.z = temp;
                _bounding.origin.axis.x = (_bounding.min.axis.x + _bounding.max.axis.x) * 0.5f;
                _bounding.origin.axis.y = (_bounding.min.axis.y + _bounding.max.axis.y) * 0.5f;
                _bounding.origin.axis.z = (_bounding.min.axis.z + _bounding.max.axis.z) * 0.5f;
            } else {
                // Average position only (shape on infinite)
                egwVecAdd3f((egwVector3f*)&volume->origin, (egwVector3f*)&_bounding.origin, (egwVector3f*)&_bounding.origin);
                egwVecUScale3f((egwVector3f*)&_bounding.origin, 0.5f, (egwVector3f*)&_bounding.origin);
                _bounding.min.axis.x = _bounding.min.axis.y = _bounding.min.axis.z = -EGW_SFLT_MAX;
                _bounding.max.axis.x = _bounding.max.axis.y = _bounding.max.axis.z = EGW_SFLT_MAX;
            }
        } else {
            // Direct copy-over (from reset)
            _bounding.origin.axis.x = volume->origin.axis.x;
            _bounding.origin.axis.y = volume->origin.axis.y;
            _bounding.origin.axis.z = volume->origin.axis.z;
            _bounding.min.axis.x = volume->origin.axis.x - volume->radius;
            _bounding.min.axis.y = volume->origin.axis.y - volume->hHeight;
            _bounding.min.axis.z = volume->origin.axis.z - volume->radius;
            _bounding.max.axis.x = volume->origin.axis.x + volume->radius;
            _bounding.max.axis.y = volume->origin.axis.y + volume->hHeight;
            _bounding.max.axis.z = volume->origin.axis.z + volume->radius;
        }
    } else if([boundVolume isMemberOfClass:[egwBoundingFrustum class]]) {
        NSLog(@"egwBoundingBox: mergeWithVolume: Error: Method not implemented for axis-aligned bounding box vs. bounding frustum.");
        // TODO: egwBoundingBox: mergeWithVolume: egwBoundingFrustum.
    } else {
        if(![boundVolume isMemberOfClass:[egwZeroBounding class]]) { // Zero bounding does nothing to extend
            if(_bounding.origin.axis.x != -EGW_SFLT_MAX) {
                // Average position only
                egwVecAdd3f((egwVector3f*)[boundVolume boundingOrigin], (egwVector3f*)&_bounding.origin, (egwVector3f*)&_bounding.origin);
                egwVecUScale3f((egwVector3f*)&_bounding.origin, 0.5f, (egwVector3f*)&_bounding.origin);
            } else {
                // Direct copy-over (from reset)
                egwVecCopy3f((egwVector3f*)[boundVolume boundingOrigin], (egwVector3f*)&_bounding.origin);
            }
            
            if([boundVolume isMemberOfClass:[egwInfiniteBounding class]]) {
                _bounding.min.axis.x = _bounding.min.axis.y = _bounding.min.axis.z = -EGW_SFLT_MAX;
                _bounding.max.axis.x = _bounding.max.axis.y = _bounding.max.axis.z = EGW_SFLT_MAX;
            }
        }
    }
}

- (void)baseOffsetByTransform:(const egwMatrix44f*)transform {
    egwVector3f edges[8];
    
    if(!transform) transform = &egwSIMatIdentity44f;
    
    egwVecTransform444f(transform, &_bounding.origin, &_bounding.origin);
    
    // Transform all edges in order to find extent after the transform
    edges[0].axis.x = _bounding.min.axis.x; edges[0].axis.y = _bounding.min.axis.y; edges[0].axis.z = _bounding.min.axis.z; // mmm
    edges[1].axis.x = _bounding.min.axis.x; edges[1].axis.y = _bounding.min.axis.y; edges[1].axis.z = _bounding.max.axis.z; // mmM
    edges[2].axis.x = _bounding.min.axis.x; edges[2].axis.y = _bounding.max.axis.y; edges[2].axis.z = _bounding.min.axis.z; // mMm
    edges[3].axis.x = _bounding.min.axis.x; edges[3].axis.y = _bounding.max.axis.y; edges[3].axis.z = _bounding.max.axis.z; // mMM
    edges[4].axis.x = _bounding.max.axis.x; edges[4].axis.y = _bounding.min.axis.y; edges[4].axis.z = _bounding.min.axis.z; // Mmm
    edges[5].axis.x = _bounding.max.axis.x; edges[5].axis.y = _bounding.min.axis.y; edges[5].axis.z = _bounding.max.axis.z; // MmM
    edges[6].axis.x = _bounding.max.axis.x; edges[6].axis.y = _bounding.max.axis.y; edges[6].axis.z = _bounding.min.axis.z; // MMm
    edges[7].axis.x = _bounding.max.axis.x; edges[7].axis.y = _bounding.max.axis.y; edges[7].axis.z = _bounding.max.axis.z; // MMM
    
    egwVecTransform443fv(transform, &edges[0], &egwSIOnef, &edges[0], -sizeof(egwMatrix44f), 0, -sizeof(float), 0, 8);
    
    egwVecFindExtentsAxs3fv(&edges[0], (egwVector3f*)&_bounding.min, (egwVector3f*)&_bounding.max, 0, 8);
}

- (void)orientateByTransform:(const egwMatrix44f*)wcsTransform fromVolume:(id<egwPBounding>)lcsVolume {
    egwVector3f edges[8];
    
    if(!wcsTransform) wcsTransform = &egwSIMatIdentity44f;
    
    egwVecTransform444f(wcsTransform, [lcsVolume boundingOrigin], &_bounding.origin);
    
    if([lcsVolume isMemberOfClass:[egwBoundingBox class]]) {
        const egwBox4f* volume = [(egwBoundingBox*)lcsVolume boundingObject];
        
        // Transform all edges in order to find extent after the transform
        edges[0].axis.x = volume->min.axis.x; edges[0].axis.y = volume->min.axis.y; edges[0].axis.z = volume->min.axis.z; // mmm
        edges[1].axis.x = volume->min.axis.x; edges[1].axis.y = volume->min.axis.y; edges[1].axis.z = volume->max.axis.z; // mmM
        edges[2].axis.x = volume->min.axis.x; edges[2].axis.y = volume->max.axis.y; edges[2].axis.z = volume->min.axis.z; // mMm
        edges[3].axis.x = volume->min.axis.x; edges[3].axis.y = volume->max.axis.y; edges[3].axis.z = volume->max.axis.z; // mMM
        edges[4].axis.x = volume->max.axis.x; edges[4].axis.y = volume->min.axis.y; edges[4].axis.z = volume->min.axis.z; // Mmm
        edges[5].axis.x = volume->max.axis.x; edges[5].axis.y = volume->min.axis.y; edges[5].axis.z = volume->max.axis.z; // MmM
        edges[6].axis.x = volume->max.axis.x; edges[6].axis.y = volume->max.axis.y; edges[6].axis.z = volume->min.axis.z; // MMm
        edges[7].axis.x = volume->max.axis.x; edges[7].axis.y = volume->max.axis.y; edges[7].axis.z = volume->max.axis.z; // MMM
        
        egwVecTransform443fv(wcsTransform, &edges[0], &egwSIOnef, &edges[0], -sizeof(egwMatrix44f), 0, -sizeof(float), 0, 8);
        
        egwVecFindExtentsAxs3fv(&edges[0], (egwVector3f*)&_bounding.min, (egwVector3f*)&_bounding.max, 0, 8);
    } else if([lcsVolume isMemberOfClass:[egwBoundingSphere class]]) {
        // FIXME: I'm unsure if this is the right way to find the wcsRadius, given that more than scaling (i.e. skewing) is at work here. I think you have to find the max value of the skew-symetry. -jw
        EGWsingle radius = [(egwBoundingSphere*)lcsVolume boundingRadius] * egwMax2f(1.0f, egwMax2f(egwMax2f(egwAbsf(wcsTransform->component.r1c1), egwAbsf(wcsTransform->component.r2c2)), egwAbsf(wcsTransform->component.r3c3)));
        
        egwVecInit3f((egwVector3f*)&_bounding.min, _bounding.origin.axis.x - radius, _bounding.origin.axis.y - radius, _bounding.origin.axis.z - radius);
        egwVecInit3f((egwVector3f*)&_bounding.max, _bounding.origin.axis.x + radius, _bounding.origin.axis.y + radius, _bounding.origin.axis.z + radius);
    } else if([lcsVolume isMemberOfClass:[egwBoundingCylinder class]]) {
        const egwCylinder4f* volume = [(egwBoundingCylinder*)lcsVolume boundingObject];
        
        // FIXME: I'm unsure if this is the right way to find the wcsRadius, given that more than scaling (i.e. skewing) is at work here. I think you have to find the max value of the skew-symetry. -jw
        EGWsingle radius = volume->radius * egwMax2f(1.0f, egwMax2f(egwAbsf(wcsTransform->component.r1c1), egwAbsf(wcsTransform->component.r3c3)));
        EGWsingle halfHeight = volume->hHeight * egwMax2f(1.0f, egwAbsf(wcsTransform->component.r2c2));
        
        egwVecInit3f((egwVector3f*)&_bounding.min, _bounding.origin.axis.x - radius, _bounding.origin.axis.y - halfHeight, _bounding.origin.axis.z - radius);
        egwVecInit3f((egwVector3f*)&_bounding.max, _bounding.origin.axis.x + radius, _bounding.origin.axis.y + halfHeight, _bounding.origin.axis.z + radius);
    } else if([lcsVolume isMemberOfClass:[egwBoundingFrustum class]]) {
        NSLog(@"egwBoundingBox: orientateByTransform:fromVolume: Error: Method not implemented for axis-aligned bounding box vs. bounding frustum.");
        // TODO: egwBoundingBox: orientateByTransform:fromVolume: egwBoundingFrustum.
    } else if([lcsVolume isMemberOfClass:[egwInfiniteBounding class]]) {
        _bounding.min.axis.x = _bounding.min.axis.y = _bounding.min.axis.z = -EGW_SFLT_MAX;
        _bounding.max.axis.x = _bounding.max.axis.y = _bounding.max.axis.z = EGW_SFLT_MAX;
    } else if([lcsVolume isMemberOfClass:[egwZeroBounding class]]) {
        _bounding.min.axis.x = _bounding.min.axis.y = _bounding.min.axis.z = EGW_SFLT_MAX;
        _bounding.max.axis.x = _bounding.max.axis.y = _bounding.max.axis.z = -EGW_SFLT_MAX;
    }
}

- (void)reset {
    _bounding.origin.axis.x = _bounding.origin.axis.y = _bounding.origin.axis.z =
        _bounding.max.axis.x = _bounding.max.axis.y = _bounding.max.axis.z = -EGW_SFLT_MAX;
    _bounding.min.axis.x = _bounding.min.axis.y = _bounding.min.axis.z = EGW_SFLT_MAX;
}

- (EGWint)testCollisionWithPoint:(const egwVector3f*)point {
    return egwTestCollisionBoxPointf(&_bounding, point);
}

- (EGWint)testCollisionWithLine:(const egwLine4f*)line startingAt:(EGWsingle*)begT endingAt:(EGWsingle*)endT {
    return egwTestCollisionBoxLinef(&_bounding, line, begT, endT);
}

- (EGWint)testCollisionWithPlane:(const egwPlane4f*)plane onSide:(EGWint*)side {
    return egwTestCollisionBoxPlanef(&_bounding, plane, side);
}

- (EGWint)testCollisionWithVolume:(const id<egwPBounding>)boundVolume {
    if([boundVolume isMemberOfClass:[egwBoundingSphere class]]) {
        return egwTestCollisionBoxSpheref(&_bounding, [(egwBoundingSphere*)boundVolume boundingObject]);
    } else if([boundVolume isMemberOfClass:[egwBoundingBox class]]) {
        return egwTestCollisionBoxBoxf(&_bounding, [(egwBoundingBox*)boundVolume boundingObject]);
    } else if([boundVolume isMemberOfClass:[egwBoundingCylinder class]]) {
        return egwTestCollisionBoxCylinderf(&_bounding, [(egwBoundingCylinder*)boundVolume boundingObject]);
    } else if([boundVolume isMemberOfClass:[egwBoundingFrustum class]]) {
        return egwTestCollisionBoxFrustumf(&_bounding, [(egwBoundingFrustum*)boundVolume boundingObject]);
    } else if([boundVolume isMemberOfClass:[egwInfiniteBounding class]]) {
        return EGW_CLSNTEST_BVOL_CONTAINEDBY;
    } else if([boundVolume isMemberOfClass:[egwZeroBounding class]]) {
        return EGW_CLSNTEST_BVOL_NONE;
    }
    
    return EGW_CLSNTEST_BVOL_NA;
}

- (const egwVector4f*)boundingOrigin {
    return &_bounding.origin;
}

- (const egwBox4f*)boundingObject {
    return &_bounding;
}

- (const egwVector4f*)boundingMinimum {
    return &_bounding.min;
}

- (const egwVector4f*)boundingMaximum {
    return &_bounding.max;
}

- (BOOL)isCollidingWithPoint:(const egwVector3f*)point {
    return (egwIsCollidingBoxPointf(&_bounding, point) > 0) ? YES : NO;
}

- (BOOL)isCollidingWithLine:(const egwLine4f*)line {
    return (egwIsCollidingBoxLinef(&_bounding, line) > 0) ? YES : NO;
}

- (BOOL)isCollidingWithPlane:(const egwPlane4f*)plane {
    return (egwIsCollidingBoxPlanef(&_bounding, plane) > 0) ? YES : NO;
}

- (BOOL)isCollidingWithVolume:(const id<egwPBounding>)boundVolume {
    if([boundVolume isMemberOfClass:[egwBoundingSphere class]]) {
        return (egwIsCollidingBoxSpheref(&_bounding, [(egwBoundingSphere*)boundVolume boundingObject]) > 0) ? YES : NO;
    } else if([boundVolume isMemberOfClass:[egwBoundingBox class]]) {
        return (egwIsCollidingBoxBoxf(&_bounding, [(egwBoundingBox*)boundVolume boundingObject]) > 0) ? YES : NO;
    } else if([boundVolume isMemberOfClass:[egwBoundingCylinder class]]) {
        return (egwIsCollidingBoxCylinderf(&_bounding, [(egwBoundingCylinder*)boundVolume boundingObject]) > 0) ? YES : NO;
    } else if([boundVolume isMemberOfClass:[egwBoundingFrustum class]]) {
        return (egwIsCollidingBoxFrustumf(&_bounding, [(egwBoundingFrustum*)boundVolume boundingObject]) > 0) ? YES : NO;
    } else if([boundVolume isMemberOfClass:[egwInfiniteBounding class]]) {
        return YES;
    } else if([boundVolume isMemberOfClass:[egwZeroBounding class]]) {
        return NO;
    }
    
    return NO;
}

- (BOOL)isReset {
    return (_bounding.origin.axis.x == -EGW_SFLT_MAX ? YES : NO);
}

@end


// !!!: ***** egwBoundingCylinder *****

@implementation egwBoundingCylinder

- (id)init {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    _bounding.origin.axis.w = 1.0f;
    
    [self reset];
    
    return self;
}

- (id)initWithOpticalSource:(const egwVector3f*)optSource vertexCount:(EGWuint16)vertexCount vertexCoords:(const egwVector3f*)vertexCoords vertexCoordsStride:(EGWintptr)vCoordsStride {
    egwVector3f min, max;
    EGWsingle temp;
    
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(optSource)
        egwVecCopy3f(optSource, (egwVector3f*)&_bounding.origin);
    else {
        // Find center manually
        egwVecSummation3fv(vertexCoords, (egwVector3f*)&_bounding.origin, vCoordsStride, vertexCount);
        egwVecUScale3f((egwVector3f*)&_bounding.origin, 1.0f / (float)vertexCount, (egwVector3f*)&_bounding.origin);
    }
    _bounding.origin.axis.w = 1.0f;
    
    egwVecFindExtentsAxs3fv(vertexCoords, &min, &max, vCoordsStride, vertexCount);
    _bounding.radius = egwVecDistanceSqrdXZ3f((egwVector3f*)&_bounding.origin, &min);
    if(_bounding.radius < (temp = egwVecDistanceSqrdXZ3f((egwVector3f*)&_bounding.origin, &max))) _bounding.radius = temp;
    _bounding.radius = egwSqrtf(_bounding.radius);
    _bounding.hHeight = egwAbsf(max.axis.y - min.axis.y) * 0.5f;
    _bounding.origin.axis.y = (max.axis.y + min.axis.y) * 0.5f;
    
    return self;
}

- (id)initWithBoundingOrigin:(const egwVector3f*)bndOrigin boundingHeight:(EGWsingle)bndHeight boundingRadius:(EGWsingle)bndRadius {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    egwVecCopy3f(bndOrigin, (egwVector3f*)&_bounding.origin); _bounding.origin.axis.w = 1.0f;
    _bounding.hHeight = bndHeight * 0.5f;
    _bounding.radius = bndRadius;
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    return [[egwBoundingCylinder allocWithZone:zone] initWithBoundingOrigin:(egwVector3f*)&_bounding.origin boundingHeight:egwDbld(_bounding.hHeight) boundingRadius:_bounding.radius];
}

- (void)dealloc {
    [super dealloc];
}

- (void)mergeWithVolume:(const id<egwPBounding>)boundVolume {
    if([boundVolume isMemberOfClass:[egwBoundingCylinder class]]) {
        const egwCylinder4f* volume = [(egwBoundingCylinder*)boundVolume boundingObject];
        
        if(_bounding.radius != -EGW_SFLT_MAX) {
            if(_bounding.radius != EGW_SFLT_MAX && volume->radius != EGW_SFLT_MAX) {
                egwVector3f diff; egwVecSubtract3f((egwVector3f*)&volume->origin, (egwVector3f*)&_bounding.origin, &diff);
                EGWsingle mag = egwVecMagnitudeSqrd3f(&diff);
                
                if(mag > (egwSignSqrdf(_bounding.radius - volume->radius) + EGW_SFLT_EPSILON)) { // Only extend if not already contained
                    mag = egwSqrtf(mag);
                    egwVecAdd3f((egwVector3f*)&_bounding.origin,
                                egwVecUScale3f(&diff, ((volume->radius + mag - _bounding.radius) * 0.5f) / mag, &diff),
                                (egwVector3f*)&_bounding.origin);
                    _bounding.radius = (_bounding.radius + mag + volume->radius) * 0.5f;
                }
                
                EGWsingle high = egwMax2f(_bounding.origin.axis.y + _bounding.hHeight, volume->origin.axis.y + volume->hHeight);
                EGWsingle low = egwMin2f(_bounding.origin.axis.y - _bounding.hHeight, volume->origin.axis.y - volume->hHeight);
                _bounding.hHeight = egwAbsf(high - low) * 0.5f;
                _bounding.origin.axis.y = (high + low) * 0.5f;
            } else {
                // Average position only (shape on infinite)
                egwVecAdd3f((egwVector3f*)&volume->origin, (egwVector3f*)&_bounding.origin, (egwVector3f*)&_bounding.origin);
                egwVecUScale3f((egwVector3f*)&_bounding.origin, 0.5f, (egwVector3f*)&_bounding.origin);
                _bounding.hHeight = _bounding.radius = EGW_SFLT_MAX;
            }
        } else {
            // Direct copy-over (from reset)
            _bounding.origin.axis.x = volume->origin.axis.x;
            _bounding.origin.axis.y = volume->origin.axis.y;
            _bounding.origin.axis.z = volume->origin.axis.z;
            _bounding.hHeight = volume->hHeight;
            _bounding.radius = volume->radius;
        }
    } else if([boundVolume isMemberOfClass:[egwBoundingSphere class]]) {
        const egwSphere4f* volume = [(egwBoundingSphere*)boundVolume boundingObject];
        
        if(_bounding.radius != -EGW_SFLT_MAX) {
            if(_bounding.radius != EGW_SFLT_MAX && volume->radius != EGW_SFLT_MAX) {
                egwVector3f diff; egwVecSubtract3f((egwVector3f*)&volume->origin, (egwVector3f*)&_bounding.origin, &diff);
                EGWsingle mag = egwVecMagnitudeSqrd3f(&diff);
                
                if(mag > (egwSignSqrdf(_bounding.radius - volume->radius) + EGW_SFLT_EPSILON)) { // Only extend if not already contained
                    mag = egwSqrtf(mag);
                    egwVecAdd3f((egwVector3f*)&_bounding.origin,
                                egwVecUScale3f(&diff, ((volume->radius + mag - _bounding.radius) * 0.5f) / mag, &diff),
                                (egwVector3f*)&_bounding.origin);
                    _bounding.radius = (_bounding.radius + mag + volume->radius) * 0.5f;
                }
                
                EGWsingle high = egwMax2f(_bounding.origin.axis.y + _bounding.hHeight, volume->origin.axis.y + volume->radius);
                EGWsingle low = egwMin2f(_bounding.origin.axis.y - _bounding.hHeight, volume->origin.axis.y - volume->radius);
                _bounding.hHeight = egwAbsf(high - low) * 0.5f;
                _bounding.origin.axis.y = (high + low) * 0.5f;
            } else {
                // Average position only (shape on infinite)
                egwVecAdd3f((egwVector3f*)&volume->origin, (egwVector3f*)&_bounding.origin, (egwVector3f*)&_bounding.origin);
                egwVecUScale3f((egwVector3f*)&_bounding.origin, 0.5f, (egwVector3f*)&_bounding.origin);
                _bounding.hHeight = _bounding.radius = EGW_SFLT_MAX;
            }
        } else {
            // Direct copy-over (from reset)
            _bounding.origin.axis.x = volume->origin.axis.x;
            _bounding.origin.axis.y = volume->origin.axis.y;
            _bounding.origin.axis.z = volume->origin.axis.z;
            _bounding.hHeight = volume->radius;
            _bounding.radius = volume->radius;
        }
    } else if([boundVolume isMemberOfClass:[egwBoundingBox class]]) {
        const egwBox4f* volume = [(egwBoundingBox*)boundVolume boundingObject];
        
        if(_bounding.radius != -EGW_SFLT_MAX) {
            if(_bounding.radius != EGW_SFLT_MAX && volume->min.axis.x != -EGW_SFLT_MAX && volume->max.axis.x != EGW_SFLT_MAX) {
                egwVector3f diff; egwVecSubtract3f((egwVector3f*)&volume->max, (egwVector3f*)&_bounding.origin, &diff);
                EGWsingle mag;
                if(egwAbsf(diff.axis.x) < egwAbsf((mag = (volume->min.axis.x - _bounding.origin.axis.x)))) diff.axis.x = mag;
                if(egwAbsf(diff.axis.y) < egwAbsf((mag = (volume->min.axis.y - _bounding.origin.axis.y)))) diff.axis.y = mag;
                if(egwAbsf(diff.axis.z) < egwAbsf((mag = (volume->min.axis.z - _bounding.origin.axis.z)))) diff.axis.z = mag;
                mag = egwVecMagnitudeSqrd3f(&diff);
                
                if(mag > (egwSqrd(_bounding.radius) + EGW_SFLT_EPSILON)) { // Only extend if not already contained
                    mag = egwSqrtf(mag);
                    
                    egwVecAdd3f((egwVector3f*)&_bounding.origin,
                                egwVecUScale3f(&diff, ((mag - _bounding.radius) * 0.5f) / mag, &diff),
                                (egwVector3f*)&_bounding.origin);
                    _bounding.radius = (_bounding.radius + mag) * 0.5f;
                }
                
                EGWsingle high = egwMax2f(_bounding.origin.axis.y + _bounding.hHeight, volume->max.axis.y);
                EGWsingle low = egwMin2f(_bounding.origin.axis.y - _bounding.hHeight, volume->min.axis.y);
                _bounding.hHeight = egwAbsf(high - low) * 0.5f;
                _bounding.origin.axis.y = (high + low) * 0.5f;
            } else {
                const egwVector4f* volOrigin = [boundVolume boundingOrigin];
                
                // Average position only (shape on infinite)
                egwVecAdd3f((egwVector3f*)volOrigin, (egwVector3f*)&_bounding.origin, (egwVector3f*)&_bounding.origin);
                egwVecUScale3f((egwVector3f*)&_bounding.origin, 0.5f, (egwVector3f*)&_bounding.origin);
                _bounding.hHeight = _bounding.radius = EGW_SFLT_MAX;
            }
        } else {
            const egwVector4f* volOrigin = [boundVolume boundingOrigin];
            
            // Direct copy-over (from reset)
            _bounding.origin.axis.x = volOrigin->axis.x;
            _bounding.origin.axis.y = volOrigin->axis.y;
            _bounding.origin.axis.z = volOrigin->axis.z;
            _bounding.radius = egwSqrtf(egwVecDistanceSqrdXZ3f((egwVector3f*)volOrigin, (egwVector3f*)&volume->max));
            _bounding.hHeight = egwAbsf(volume->max.axis.y - volume->origin.axis.y);
        }
    } else if([boundVolume isMemberOfClass:[egwBoundingFrustum class]]) {
        NSLog(@"egwBoundingCylinder: mergeWithVolume: Error: Method not implemented for axis-aligned cylinder vs. bounding frustum.");
        // TODO: egwBoundingCylinder: mergeWithVolume: egwBoundingFrustum.
    } else {
        if(![boundVolume isMemberOfClass:[egwZeroBounding class]]) { // Zero bounding does nothing to extend
            if(_bounding.origin.axis.x != -EGW_SFLT_MAX) {
                // Average position only
                egwVecAdd3f((egwVector3f*)[boundVolume boundingOrigin], (egwVector3f*)&_bounding.origin, (egwVector3f*)&_bounding.origin);
                egwVecUScale3f((egwVector3f*)&_bounding.origin, 0.5f, (egwVector3f*)&_bounding.origin);
            } else {
                // Direct copy-over (from reset)
                egwVecCopy3f((egwVector3f*)[boundVolume boundingOrigin], (egwVector3f*)&_bounding.origin);
            }
            
            if([boundVolume isMemberOfClass:[egwInfiniteBounding class]]) {
                _bounding.hHeight = _bounding.radius = EGW_SFLT_MAX;
            }
        }
    }
}

- (void)baseOffsetByTransform:(const egwMatrix44f*)transform {
    if(!transform) transform = &egwSIMatIdentity44f;
    
    egwVecTransform444f(transform, &_bounding.origin, &_bounding.origin);
    // FIXME: I'm unsure if this is the right way to find the wcsRadius, given that more than scaling (i.e. skewing) is at work here. I think you have to find the max value of the skew-symetry. -jw
    _bounding.radius *= egwMax2f(1.0f, egwMax2f(transform->component.r1c1, transform->component.r3c3));
    _bounding.hHeight *= egwMax2f(1.0f, transform->component.r2c2);
}

- (void)orientateByTransform:(const egwMatrix44f*)wcsTransform fromVolume:(id<egwPBounding>)lcsVolume {
    if(!wcsTransform) wcsTransform = &egwSIMatIdentity44f;
    
    egwVecTransform444f(wcsTransform, [lcsVolume boundingOrigin], &_bounding.origin);
    
    if([lcsVolume isMemberOfClass:[egwBoundingCylinder class]]) {
        const egwCylinder4f* volume = [(egwBoundingCylinder*)lcsVolume boundingObject];
        
        // FIXME: I'm unsure if this is the right way to find the wcsRadius, given that more than scaling (i.e. skewing) is at work here. I think you have to find the max value of the skew-symetry. -jw
        _bounding.radius = volume->radius * egwMax2f(1.0f, egwMax2f(egwAbsf(wcsTransform->component.r1c1), egwAbsf(wcsTransform->component.r3c3)));
        _bounding.hHeight = volume->hHeight * egwMax2f(1.0f, egwAbsf(wcsTransform->component.r2c2));
    } else if([lcsVolume isMemberOfClass:[egwBoundingSphere class]]) {
        const egwSphere4f* volume = [(egwBoundingSphere*)lcsVolume boundingObject];
        
        // FIXME: I'm unsure if this is the right way to find the wcsRadius, given that more than scaling (i.e. skewing) is at work here. I think you have to find the max value of the skew-symetry. -jw
        _bounding.radius = volume->radius * egwMax2f(1.0f, egwMax2f(egwAbsf(wcsTransform->component.r1c1), egwAbsf(wcsTransform->component.r3c3)));
        _bounding.hHeight = volume->radius * egwMax2f(1.0f, egwAbsf(wcsTransform->component.r2c2));
    } else if([lcsVolume isMemberOfClass:[egwBoundingBox class]]) {
        egwVector3f edges[8], min, max;
        EGWsingle temp;
        
        // Transform all edges in order to find extent after the transform
        const egwBox4f* volume = [(egwBoundingBox*)lcsVolume boundingObject];
        
        edges[0].axis.x = volume->min.axis.x; edges[0].axis.y = volume->min.axis.y; edges[0].axis.z = volume->min.axis.z; // mmm
        edges[1].axis.x = volume->min.axis.x; edges[1].axis.y = volume->min.axis.y; edges[1].axis.z = volume->max.axis.z; // mmM
        edges[2].axis.x = volume->min.axis.x; edges[2].axis.y = volume->max.axis.y; edges[2].axis.z = volume->min.axis.z; // mMm
        edges[3].axis.x = volume->min.axis.x; edges[3].axis.y = volume->max.axis.y; edges[3].axis.z = volume->max.axis.z; // mMM
        edges[4].axis.x = volume->max.axis.x; edges[4].axis.y = volume->min.axis.y; edges[4].axis.z = volume->min.axis.z; // Mmm
        edges[5].axis.x = volume->max.axis.x; edges[5].axis.y = volume->min.axis.y; edges[5].axis.z = volume->max.axis.z; // MmM
        edges[6].axis.x = volume->max.axis.x; edges[6].axis.y = volume->max.axis.y; edges[6].axis.z = volume->min.axis.z; // MMm
        edges[7].axis.x = volume->max.axis.x; edges[7].axis.y = volume->max.axis.y; edges[7].axis.z = volume->max.axis.z; // MMM
        
        egwVecTransform443fv(wcsTransform, &edges[0], &egwSIOnef, &edges[0], -sizeof(egwMatrix44f), 0, -sizeof(float), 0, 8);
        
        egwVecFindExtentsAxs3fv(&edges[0], &min, &max, 0, 8);
        
        _bounding.radius = egwVecDistanceSqrdXZ3f((egwVector3f*)&_bounding.origin, &min);
        if(_bounding.radius < (temp = egwVecDistanceSqrdXZ3f((egwVector3f*)&_bounding.origin, &max))) _bounding.radius = temp;
        _bounding.radius = egwSqrtf(_bounding.radius);
        _bounding.hHeight = egwAbsf(max.axis.y - min.axis.y) * 0.5f;
        _bounding.origin.axis.y = (max.axis.y + min.axis.y) * 0.5f;
    } else if([lcsVolume isMemberOfClass:[egwBoundingFrustum class]]) {
        NSLog(@"egwBoundingCylinder: orientateByTransform:fromVolume: Error: Method not implemented for axis-aligned cylinder vs. bounding frustum.");
        // TODO: egwBoundingCylinder: orientateByTransform:fromVolume: egwBoundingFrustum.
    } else if([lcsVolume isMemberOfClass:[egwInfiniteBounding class]]) {
        _bounding.hHeight = _bounding.radius = EGW_SFLT_MAX;
    } else if([lcsVolume isMemberOfClass:[egwZeroBounding class]]) {
        _bounding.hHeight = _bounding.radius = -EGW_SFLT_MAX;
    }
}

- (void)reset {
    _bounding.origin.axis.x = _bounding.origin.axis.y = _bounding.origin.axis.z = -EGW_SFLT_MAX;
    _bounding.hHeight = _bounding.radius = -EGW_SFLT_MAX;
}

- (EGWint)testCollisionWithPoint:(const egwVector3f*)point {
    return egwTestCollisionCylinderPointf(&_bounding, point);
}

- (EGWint)testCollisionWithLine:(const egwLine4f*)line startingAt:(EGWsingle*)begT endingAt:(EGWsingle*)endT {
    return egwTestCollisionCylinderLinef(&_bounding, line, begT, endT);
}

- (EGWint)testCollisionWithPlane:(const egwPlane4f*)plane onSide:(EGWint*)side {
    return egwTestCollisionCylinderPlanef(&_bounding, plane, side);
}

- (EGWint)testCollisionWithVolume:(const id<egwPBounding>)boundVolume {
    if([boundVolume isMemberOfClass:[egwBoundingSphere class]]) {
        return egwTestCollisionCylinderSpheref(&_bounding, [(egwBoundingSphere*)boundVolume boundingObject]);
    } else if([boundVolume isMemberOfClass:[egwBoundingBox class]]) {
        return egwTestCollisionCylinderBoxf(&_bounding, [(egwBoundingBox*)boundVolume boundingObject]);
    } else if([boundVolume isMemberOfClass:[egwBoundingCylinder class]]) {
        return egwTestCollisionCylinderCylinderf(&_bounding, [(egwBoundingCylinder*)boundVolume boundingObject]);
    } else if([boundVolume isMemberOfClass:[egwBoundingFrustum class]]) {
        return egwTestCollisionCylinderFrustumf(&_bounding, [(egwBoundingFrustum*)boundVolume boundingObject]);
    } else if([boundVolume isMemberOfClass:[egwInfiniteBounding class]]) {
        return EGW_CLSNTEST_BVOL_CONTAINEDBY;
    } else if([boundVolume isMemberOfClass:[egwZeroBounding class]]) {
        return EGW_CLSNTEST_BVOL_NONE;
    }
    
    return EGW_CLSNTEST_BVOL_NA;
}

- (const egwVector4f*)boundingOrigin {
    return &_bounding.origin;
}

- (const egwCylinder4f*)boundingObject {
    return &_bounding;
}

- (EGWsingle)boundingHeight {
    return egwDbld(_bounding.hHeight);
}

- (EGWsingle)boundingRadius {
    return _bounding.radius;
}

- (BOOL)isCollidingWithPoint:(const egwVector3f*)point {
    return (egwIsCollidingCylinderPointf(&_bounding, point) > 0) ? YES : NO;
}

- (BOOL)isCollidingWithLine:(const egwLine4f*)line {
    return (egwIsCollidingCylinderLinef(&_bounding, line) > 0) ? YES : NO;
}

- (BOOL)isCollidingWithPlane:(const egwPlane4f*)plane {
    return (egwIsCollidingCylinderPlanef(&_bounding, plane) > 0) ? YES : NO;
}

- (BOOL)isCollidingWithVolume:(const id<egwPBounding>)boundVolume {
    if([boundVolume isMemberOfClass:[egwBoundingSphere class]]) {
        return (egwIsCollidingCylinderSpheref(&_bounding, [(egwBoundingSphere*)boundVolume boundingObject]) > 0) ? YES : NO;
    } else if([boundVolume isMemberOfClass:[egwBoundingBox class]]) {
        return (egwIsCollidingCylinderBoxf(&_bounding, [(egwBoundingBox*)boundVolume boundingObject]) > 0) ? YES : NO;
    } else if([boundVolume isMemberOfClass:[egwBoundingCylinder class]]) {
        return (egwIsCollidingCylinderCylinderf(&_bounding, [(egwBoundingCylinder*)boundVolume boundingObject]) > 0) ? YES : NO;
    } else if([boundVolume isMemberOfClass:[egwBoundingFrustum class]]) {
        return (egwIsCollidingCylinderFrustumf(&_bounding, [(egwBoundingFrustum*)boundVolume boundingObject]) > 0) ? YES : NO;
    } else if([boundVolume isMemberOfClass:[egwInfiniteBounding class]]) {
        return YES;
    } else if([boundVolume isMemberOfClass:[egwZeroBounding class]]) {
        return NO;
    }
    
    return NO;
}

- (BOOL)isReset {
    return (_bounding.radius == -EGW_SFLT_MAX ? YES : NO);
}

@end


// !!!: ***** egwBoundingFrustum *****

@implementation egwBoundingFrustum

- (id)init {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    _bounding.origin.axis.w = 1.0f;
    
    [self reset];
    
    return self;
}

- (id)initWithOpticalSource:(const egwVector3f*)optSource vertexCount:(EGWuint16)vertexCount vertexCoords:(const egwVector3f*)vertexCoords vertexCoordsStride:(EGWintptr)vCoordsStride {
    egwVector3f min, max;
    
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(optSource)
        egwVecCopy3f(optSource, (egwVector3f*)&_bounding.origin);
    else {
        // Find center manually
        egwVecSummation3fv(vertexCoords, (egwVector3f*)&_bounding.origin, vCoordsStride, vertexCount);
        egwVecUScale3f((egwVector3f*)&_bounding.origin, 1.0f / (float)vertexCount, (egwVector3f*)&_bounding.origin);
    }
    _bounding.origin.axis.w = 1.0f;
    
    egwVecFindExtentsAxs3fv(vertexCoords, (egwVector3f*)&(min), (egwVector3f*)&(max), vCoordsStride, vertexCount);
    
    // Init each plane side to simply be an OBB, really. There isn't any other
    // really nice easy way to come up with some sort of frustum with this info.
    
    egwVecInit4f(&(_bounding.xMin.normal), 1.0f, 0.0f, 0.0f, 0.0f);
    _bounding.xMin.d = -egwVecDotProd3f((egwVector3f*)&(_bounding.xMin.normal), &min);
    egwVecInit4f(&(_bounding.xMin.origin), 1.0f * -_bounding.xMin.d, 0.0f, 0.0f, 1.0f);
    
    egwVecInit4f(&(_bounding.xMax.normal), -1.0f, 0.0f, 0.0f, 0.0f);
    _bounding.xMax.d = -egwVecDotProd3f((egwVector3f*)&(_bounding.xMax.normal), &max);
    egwVecInit4f(&(_bounding.xMax.origin), -1.0f * -_bounding.xMax.d, 0.0f, 0.0f, 1.0f);
    
    egwVecInit4f(&(_bounding.yMin.normal), 0.0f, 1.0f, 0.0f, 0.0f);
    _bounding.yMin.d = -egwVecDotProd3f((egwVector3f*)&(_bounding.yMin.normal), &min);
    egwVecInit4f(&(_bounding.yMin.origin), 0.0f, 1.0f * -_bounding.yMin.d, 0.0f, 1.0f);
    
    egwVecInit4f(&(_bounding.yMax.normal), 0.0f, -1.0f, 0.0f, 0.0f);
    _bounding.yMax.d = -egwVecDotProd3f((egwVector3f*)&(_bounding.yMax.normal), &max);
    egwVecInit4f(&(_bounding.yMax.origin), 0.0f, -1.0f * -_bounding.yMax.d, 0.0f, 1.0f);
    
    egwVecInit4f(&(_bounding.zMin.normal), 0.0f, 0.0f, 1.0f, 0.0f);
    _bounding.zMin.d = -egwVecDotProd3f((egwVector3f*)&(_bounding.zMin.normal), &min);
    egwVecInit4f(&(_bounding.zMin.origin), 0.0f, 0.0f, 1.0f * -_bounding.zMin.d, 1.0f);
    
    egwVecInit4f(&(_bounding.zMax.normal), 0.0f, 0.0f, -1.0f, 0.0f);
    _bounding.zMax.d = -egwVecDotProd3f((egwVector3f*)&(_bounding.zMax.normal), &max);
    egwVecInit4f(&(_bounding.zMax.origin), 0.0f, 0.0f, -1.0f * -_bounding.zMax.d, 1.0f);
    
    return self;
}

- (id)initPerspectiveWithFieldOfView:(EGWsingle)fov aspectRatio:(EGWsingle)aspect frontPlane:(EGWsingle)near backPlane:(EGWsingle)far {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    egwVecInit4f(&_bounding.origin, 0.0f, 0.0f, -(((far - near) * 0.5f) + near), 1.0f);
    
    egwVecCopy4f(&egwSIVecUnitW4f, &(_bounding.xMin.origin));
    egwVecCopy4f(&egwSIVecUnitW4f, &(_bounding.xMax.origin));
    egwVecCopy4f(&egwSIVecUnitW4f, &(_bounding.yMin.origin));
    egwVecCopy4f(&egwSIVecUnitW4f, &(_bounding.yMax.origin));
    egwVecCopy4f(&egwSIVecUnitW4f, &(_bounding.zMin.origin)); _bounding.zMin.origin.axis.z = -far;
    egwVecCopy4f(&egwSIVecUnitW4f, &(_bounding.zMax.origin)); _bounding.zMax.origin.axis.z = near;
    
    fov = egwDegToRad(egwClampf(fov, EGW_SFLT_EPSILON, 180.0f - EGW_SFLT_EPSILON));
    
    if(aspect >= 1.0f) {
        egwVecInit4f(&(_bounding.yMin.normal), 0.0f, egwCosf(fov), -egwSinf(fov), 0.0f);
        egwVecInit4f(&(_bounding.xMin.normal), _bounding.yMin.normal.axis.y / aspect, 0.0f, _bounding.yMin.normal.axis.z, 0.0f);
        egwVecNormalize3f((egwVector3f*)&(_bounding.xMin.normal), (egwVector3f*)&(_bounding.xMin.normal));
    } else {
        egwVecInit4f(&(_bounding.xMin.normal), egwCosf(fov), 0.0f, -egwSinf(fov), 0.0f);
        egwVecInit4f(&(_bounding.yMin.normal), 0.0f, _bounding.xMin.normal.axis.y / aspect, _bounding.xMin.normal.axis.z, 0.0f);
        egwVecNormalize3f((egwVector3f*)&(_bounding.yMin.normal), (egwVector3f*)&(_bounding.yMin.normal));
    }
    
    egwVecCopy4f(&(_bounding.xMin.normal), &(_bounding.xMax.normal)); _bounding.xMax.normal.axis.x = -_bounding.xMax.normal.axis.x;
    egwVecCopy4f(&(_bounding.yMin.normal), &(_bounding.yMax.normal)); _bounding.yMax.normal.axis.y = -_bounding.yMax.normal.axis.y;
    egwVecCopy4f(&egwSIVecUnitZ4f, &(_bounding.zMin.normal));
    egwVecCopy4f(&egwSIVecNegUnitZ4f, &(_bounding.zMax.normal));
    
    _bounding.xMin.d = _bounding.xMax.d = _bounding.yMin.d = _bounding.yMax.d = 0.0f;
    _bounding.zMin.d = -egwVecDotProd3f((egwVector3f*)&(_bounding.zMin.normal), (egwVector3f*)&(_bounding.zMin.origin));
    _bounding.zMax.d = -egwVecDotProd3f((egwVector3f*)&(_bounding.zMax.normal), (egwVector3f*)&(_bounding.zMax.origin));
    
    return self;
}

- (id)initWithBoundingOrigin:(const egwVector3f*)bndOrigin boundingPlaneMinX:(egwPlane4f*)bndPlnMinX boundingPlaneMaxX:(egwPlane4f*)bndPlnMaxX boundingPlaneMinY:(egwPlane4f*)bndPlnMinY boundingPlaneMaxY:(egwPlane4f*)bndPlnMaxY boundingPlaneMinZ:(egwPlane4f*)bndPlnMinZ boundingPlaneMaxZ:(egwPlane4f*)bndPlnMaxZ {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    egwVecCopy3f(bndOrigin, (egwVector3f*)&_bounding.origin); _bounding.origin.axis.w = 1.0f;
    memcpy((void*)&(_bounding.xMin), (const void*)bndPlnMinX, sizeof(egwPlane4f));
    memcpy((void*)&(_bounding.xMax), (const void*)bndPlnMaxX, sizeof(egwPlane4f));
    memcpy((void*)&(_bounding.yMin), (const void*)bndPlnMinY, sizeof(egwPlane4f));
    memcpy((void*)&(_bounding.yMax), (const void*)bndPlnMaxY, sizeof(egwPlane4f));
    memcpy((void*)&(_bounding.zMin), (const void*)bndPlnMinZ, sizeof(egwPlane4f));
    memcpy((void*)&(_bounding.zMax), (const void*)bndPlnMaxZ, sizeof(egwPlane4f));
    
    return self;
}

- (id)copyWithZone:(NSZone*)zone {
    return [[egwBoundingFrustum allocWithZone:zone] initWithBoundingOrigin:(egwVector3f*)&_bounding.origin boundingPlaneMinX:(egwPlane4f*)&(_bounding.xMin) boundingPlaneMaxX:(egwPlane4f*)&(_bounding.xMax) boundingPlaneMinY:(egwPlane4f*)&(_bounding.yMin) boundingPlaneMaxY:(egwPlane4f*)&(_bounding.yMax) boundingPlaneMinZ:(egwPlane4f*)&(_bounding.zMin) boundingPlaneMaxZ:(egwPlane4f*)&(_bounding.zMax)];
}

- (void)dealloc {
    [super dealloc];
}

- (void)mergeWithVolume:(const id<egwPBounding>)boundVolume {
    NSLog(@"egwBoundingFrustum: mergeWithVolume: Error: Method not implemented.");
    
    if([boundVolume isMemberOfClass:[egwBoundingFrustum class]]) {
        // TODO: egwBoundingFrustum: mergeWithVolume: egwBoundingFrustum.
    } else if([boundVolume isMemberOfClass:[egwBoundingSphere class]]) {
        // TODO: egwBoundingFrustum: mergeWithVolum: egwBoundingSphere.
    } else if([boundVolume isMemberOfClass:[egwBoundingBox class]]) {
        // TODO: egwBoundingFrustum: mergeWithVolum: egwBoundingBox.
    } else if([boundVolume isMemberOfClass:[egwBoundingCylinder class]]) {
        // TODO: egwBoundingFrustum: mergeWithVolum: egwBoundingCylinder.
    } else {
        if(![boundVolume isMemberOfClass:[egwZeroBounding class]]) { // Zero bounding does nothing to extend
            if(_bounding.origin.axis.x != -EGW_SFLT_MAX) {
                // Average position only
                egwVecAdd3f((egwVector3f*)[boundVolume boundingOrigin], (egwVector3f*)&_bounding.origin, (egwVector3f*)&_bounding.origin);
                egwVecUScale3f((egwVector3f*)&_bounding.origin, 0.5f, (egwVector3f*)&_bounding.origin);
            } else {
                // Direct copy-over (from reset)
                egwVecCopy3f((egwVector3f*)[boundVolume boundingOrigin], (egwVector3f*)&_bounding.origin);
            }
            
            if([boundVolume isMemberOfClass:[egwInfiniteBounding class]]) {
                _bounding.xMin.d = _bounding.yMin.d = _bounding.zMin.d = -EGW_SFLT_MAX;
                _bounding.xMax.d = _bounding.yMax.d = _bounding.zMax.d = EGW_SFLT_MAX;
            }
        }
    }
}

- (void)baseOffsetByTransform:(const egwMatrix44f*)transform {
    if(!transform) transform = &egwSIMatIdentity44f;
    
    egwVecTransform444f(transform, &_bounding.origin, &_bounding.origin);
    
    egwPlaneTransform444f(transform, &_bounding.xMin, &_bounding.xMin);
    egwPlaneTransform444f(transform, &_bounding.xMax, &_bounding.xMax);
    egwPlaneTransform444f(transform, &_bounding.yMin, &_bounding.yMin);
    egwPlaneTransform444f(transform, &_bounding.yMax, &_bounding.yMax);
    egwPlaneTransform444f(transform, &_bounding.zMin, &_bounding.zMin);
    egwPlaneTransform444f(transform, &_bounding.zMax, &_bounding.zMax);
}

- (void)orientateByTransform:(const egwMatrix44f*)wcsTransform fromVolume:(id<egwPBounding>)lcsVolume {
    if(!wcsTransform) wcsTransform = &egwSIMatIdentity44f;
    
    egwVecTransform444f(wcsTransform, [lcsVolume boundingOrigin], &_bounding.origin);
    
    if([lcsVolume isMemberOfClass:[egwBoundingFrustum class]]) {
        const egwFrustum4f* volume = [(egwBoundingFrustum*)lcsVolume boundingObject];
        
        egwPlaneTransform444f(wcsTransform, &volume->xMin, &_bounding.xMin);
        egwPlaneTransform444f(wcsTransform, &volume->xMax, &_bounding.xMax);
        egwPlaneTransform444f(wcsTransform, &volume->yMin, &_bounding.yMin);
        egwPlaneTransform444f(wcsTransform, &volume->yMax, &_bounding.yMax);
        egwPlaneTransform444f(wcsTransform, &volume->zMin, &_bounding.zMin);
        egwPlaneTransform444f(wcsTransform, &volume->zMax, &_bounding.zMax);
    } else if([lcsVolume isMemberOfClass:[egwBoundingSphere class]]) {
        NSLog(@"egwBoundingFrustum: orientateByTransform:fromVolume: Error: Method not implemented for bounding frustum vs. bounding sphere.");
        // TODO: egwBoundingFrustum: orientateByTransform:fromVolume: egwBoundingSphere.
    } else if([lcsVolume isMemberOfClass:[egwBoundingBox class]]) {
        NSLog(@"egwBoundingFrustum: orientateByTransform:fromVolume: Error: Method not implemented for bounding frustum vs. axis-aligned bounding box.");
        // TODO: egwBoundingFrustum: orientateByTransform:fromVolume: egwBoundingBox.
    } else if([lcsVolume isMemberOfClass:[egwBoundingCylinder class]]) { 
        NSLog(@"egwBoundingFrustum: orientateByTransform:fromVolume: Error: Method not implemented for bounding frustum vs. axis-aligned bounding cylinder.");
        // TODO: egwBoundingFrustum: orientateByTransform:fromVolume: egwBoundingCylinder.
    } else if([lcsVolume isMemberOfClass:[egwInfiniteBounding class]]) {
        _bounding.xMin.d = _bounding.yMin.d = _bounding.zMin.d = -EGW_SFLT_MAX;
        _bounding.xMax.d = _bounding.yMax.d = _bounding.zMax.d = EGW_SFLT_MAX;
    } else if([lcsVolume isMemberOfClass:[egwZeroBounding class]]) {
        _bounding.xMin.d = _bounding.yMin.d = _bounding.zMin.d = EGW_SFLT_MAX;
        _bounding.xMax.d = _bounding.yMax.d = _bounding.zMax.d = -EGW_SFLT_MAX;
    }
}

- (void)reset {
    _bounding.origin.axis.x = _bounding.origin.axis.y = _bounding.origin.axis.z = -EGW_SFLT_MAX;
    _bounding.xMin.origin.axis.x = _bounding.xMin.origin.axis.y = _bounding.xMin.origin.axis.z =
        _bounding.xMin.normal.axis.x = _bounding.xMin.normal.axis.y = _bounding.xMin.normal.axis.z = -EGW_SFLT_MAX;
    _bounding.xMin.d = EGW_SFLT_MAX;
    _bounding.xMax.origin.axis.x = _bounding.xMax.origin.axis.y = _bounding.xMax.origin.axis.z =
        _bounding.xMax.normal.axis.x = _bounding.xMax.normal.axis.y = _bounding.xMax.normal.axis.z = -EGW_SFLT_MAX;
    _bounding.xMax.d = -EGW_SFLT_MAX;
    memcpy((void*)&_bounding.yMin, (const void*)&_bounding.xMin, sizeof(egwPlane4f));
    memcpy((void*)&_bounding.yMax, (const void*)&_bounding.xMax, sizeof(egwPlane4f));
    memcpy((void*)&_bounding.zMin, (const void*)&_bounding.xMin, sizeof(egwPlane4f));
    memcpy((void*)&_bounding.zMax, (const void*)&_bounding.xMax, sizeof(egwPlane4f));
}

- (EGWint)testCollisionWithPoint:(const egwVector3f*)point {
    return egwTestCollisionFrustumPointf(&_bounding, point);
}

- (EGWint)testCollisionWithLine:(const egwLine4f*)line startingAt:(EGWsingle*)begT endingAt:(EGWsingle*)endT {
    return egwTestCollisionFrustumLinef(&_bounding, line, begT, endT);
}

- (EGWint)testCollisionWithPlane:(const egwPlane4f*)plane onSide:(EGWint*)side {
    return egwTestCollisionFrustumPlanef(&_bounding, plane, side);
}

- (EGWint)testCollisionWithVolume:(const id<egwPBounding>)boundVolume {
    if([boundVolume isMemberOfClass:[egwBoundingSphere class]]) {
        return egwTestCollisionFrustumSpheref(&_bounding, [(egwBoundingSphere*)boundVolume boundingObject]);
    } else if([boundVolume isMemberOfClass:[egwBoundingBox class]]) {
        return egwTestCollisionFrustumBoxf(&_bounding, [(egwBoundingBox*)boundVolume boundingObject]);
    } else if([boundVolume isMemberOfClass:[egwBoundingCylinder class]]) {
        return egwTestCollisionFrustumCylinderf(&_bounding, [(egwBoundingCylinder*)boundVolume boundingObject]);
    } else if([boundVolume isMemberOfClass:[egwBoundingFrustum class]]) {
        return egwTestCollisionFrustumFrustumf(&_bounding, [(egwBoundingFrustum*)boundVolume boundingObject]);
    } else if([boundVolume isMemberOfClass:[egwInfiniteBounding class]]) {
        return EGW_CLSNTEST_BVOL_CONTAINEDBY;
    } else if([boundVolume isMemberOfClass:[egwZeroBounding class]]) {
        return EGW_CLSNTEST_BVOL_NONE;
    }
    
    return EGW_CLSNTEST_BVOL_NA;
}

- (const egwVector4f*)boundingOrigin {
    return &_bounding.origin;
}

- (const egwFrustum4f*)boundingObject {
    return &_bounding;
}

- (const egwPlane4f*)boundingPlaneMinX {
    return &(_bounding.xMin);
}

- (const egwPlane4f*)boundingPlaneMaxX {
    return &(_bounding.xMax);
}

- (const egwPlane4f*)boundingPlaneMinY {
    return &(_bounding.yMin);
}

- (const egwPlane4f*)boundingPlaneMaxY {
    return &(_bounding.yMax);
}

- (const egwPlane4f*)boundingPlaneMinZ {
    return &(_bounding.zMin);
}

- (const egwPlane4f*)boundingPlaneMaxZ {
    return &(_bounding.zMax);
}

- (BOOL)isCollidingWithPoint:(const egwVector3f*)point {
    return (egwIsCollidingFrustumPointf(&_bounding, point) > 0) ? YES : NO;
}

- (BOOL)isCollidingWithLine:(const egwLine4f*)line {
    return (egwIsCollidingFrustumLinef(&_bounding, line) > 0) ? YES : NO;
}

- (BOOL)isCollidingWithPlane:(const egwPlane4f*)plane {
    return (egwIsCollidingFrustumPlanef(&_bounding, plane) > 0) ? YES : NO;
}

- (BOOL)isCollidingWithVolume:(const id<egwPBounding>)boundVolume {
    if([boundVolume isMemberOfClass:[egwBoundingSphere class]]) {
        return (egwIsCollidingFrustumSpheref(&_bounding, [(egwBoundingSphere*)boundVolume boundingObject]) > 0) ? YES : NO;
    } else if([boundVolume isMemberOfClass:[egwBoundingBox class]]) {
        return (egwIsCollidingFrustumBoxf(&_bounding, [(egwBoundingBox*)boundVolume boundingObject]) > 0) ? YES : NO;
    } else if([boundVolume isMemberOfClass:[egwBoundingCylinder class]]) {
        return (egwIsCollidingFrustumCylinderf(&_bounding, [(egwBoundingCylinder*)boundVolume boundingObject]) > 0) ? YES : NO;
    } else if([boundVolume isMemberOfClass:[egwBoundingFrustum class]]) {
        return (egwIsCollidingFrustumFrustumf(&_bounding, [(egwBoundingFrustum*)boundVolume boundingObject]) > 0) ? YES : NO;
    } else if([boundVolume isMemberOfClass:[egwInfiniteBounding class]]) {
        return YES;
    } else if([boundVolume isMemberOfClass:[egwZeroBounding class]]) {
        return NO;
    }
    
    return NO;
}

- (BOOL)isReset {
    return (_bounding.origin.axis.x == -EGW_SFLT_MAX ? YES : NO);
}

@end

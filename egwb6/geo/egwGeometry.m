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

/// @file egwGeometry.m
/// @ingroup geWizES_math_geometry
/// Geometry Implementation.

#import <math.h>
#import "egwGeometry.h"
#import "../math/egwVector.h"
#import "../math/egwMatrix.h"
#import "../gfx/egwGraphics.h"
#import "../gui/egwGuiTypes.h"


void egwGeomSFrmTexTransform(const egwSurfaceFraming* sFrame_in, const EGWuint16 fIndex_in, egwMatrix44f* tTransform_out) {
    register EGWuint16 offset = fIndex_in - sFrame_in->fOffset;
    register EGWuint16 hOffset = offset % sFrame_in->hFrames;
    register EGWuint16 vOffset = offset / sFrame_in->hFrames;
    egwMatScale44fs(NULL,
                    (EGWsingle)(sFrame_in->htSizer - EGW_WIDGET_TXCCORRECT),
                    (EGWsingle)(sFrame_in->vtSizer - EGW_WIDGET_TXCCORRECT),
                    1.0f,
                    tTransform_out);
    tTransform_out->component.r1c4 = (EGWsingle)(((EGWdouble)hOffset * sFrame_in->htSizer) + (EGWdouble)EGW_WIDGET_TXCCORRECT);
    tTransform_out->component.r2c4 = (EGWsingle)(((EGWdouble)vOffset * sFrame_in->vtSizer) + (EGWdouble)EGW_WIDGET_TXCCORRECT);
}

EGWint egwIsCollidingSpherePointf(const egwSphere4f* sphere_lhs, const egwVector3f* point_rhs) {
    return (egwVecDistanceSqrd3f((egwVector3f*)&(sphere_lhs->origin), point_rhs) -
            egwSqrd(sphere_lhs->radius) <= EGW_SFLT_EPSILON) ? 1 : 0;
}

EGWint egwIsCollidingSphereLinef(const egwSphere4f* sphere_lhs, const egwLine4f* line_rhs) {
    egwVector3f orgMinCen;
    EGWsingle discr, nrmDotOrgMinCen;
    
    egwVecSubtract3f((egwVector3f*)&(line_rhs->origin), (egwVector3f*)&(sphere_lhs->origin), &orgMinCen);
    nrmDotOrgMinCen = egwVecDotProd3f((egwVector3f*)&(line_rhs->normal), &orgMinCen);
    discr = egwSqrd(nrmDotOrgMinCen) - (egwVecDotProd3f(&orgMinCen, &orgMinCen) - egwSqrd(sphere_lhs->radius));
    
    return (discr >= -EGW_SFLT_EPSILON) ? 1 : 0;
}

EGWint egwIsCollidingSpherePlanef(const egwSphere4f* sphere_lhs, const egwPlane4f* plane_rhs) {
    EGWsingle t = egwVecDotProd3f((egwVector3f*)&(plane_rhs->normal), (egwVector3f*)&(sphere_lhs->origin)) + plane_rhs->d;
    
    return (t + sphere_lhs->radius <= EGW_SFLT_EPSILON &&
            t - sphere_lhs->radius >= -EGW_SFLT_EPSILON) ? 1 : 0;
}

EGWint egwIsCollidingSphereSpheref(const egwSphere4f* sphere_lhs, const egwSphere4f* sphere_rhs) {
    return (egwVecDistanceSqrd3f((egwVector3f*)&(sphere_lhs->origin), (egwVector3f*)&(sphere_rhs->origin)) <=
            (egwSqrdf(sphere_lhs->radius + sphere_rhs->radius) + EGW_SFLT_EPSILON)) ? 1 : 0;
}

EGWint egwIsCollidingSphereBoxf(const egwSphere4f* sphere_lhs, const egwBox4f* box_rhs) {
    return (box_rhs->min.axis.x - (sphere_lhs->origin.axis.x + sphere_lhs->radius) <= EGW_SFLT_EPSILON &&
            box_rhs->min.axis.y - (sphere_lhs->origin.axis.y + sphere_lhs->radius) <= EGW_SFLT_EPSILON &&
            box_rhs->min.axis.z - (sphere_lhs->origin.axis.z + sphere_lhs->radius) <= EGW_SFLT_EPSILON &&
            box_rhs->max.axis.x - (sphere_lhs->origin.axis.x - sphere_lhs->radius) >= -EGW_SFLT_EPSILON &&
            box_rhs->max.axis.y - (sphere_lhs->origin.axis.y - sphere_lhs->radius) >= -EGW_SFLT_EPSILON &&
            box_rhs->max.axis.z - (sphere_lhs->origin.axis.z - sphere_lhs->radius) >= -EGW_SFLT_EPSILON) ? 1 : 0;
}

EGWint egwIsCollidingSphereCylinderf(const egwSphere4f* sphere_lhs, const egwCylinder4f* cylinder_rhs) {
    return egwVecDistanceSqrdXZ3f((egwVector3f*)&sphere_lhs->origin, (egwVector3f*)&cylinder_rhs->origin) <=
           (egwSqrdf(sphere_lhs->radius + cylinder_rhs->radius) + EGW_SFLT_EPSILON) &&
           sphere_lhs->origin.axis.y - sphere_lhs->radius <= cylinder_rhs->origin.axis.y + cylinder_rhs->hHeight + EGW_SFLT_EPSILON &&
           sphere_lhs->origin.axis.y + sphere_lhs->radius >= cylinder_rhs->origin.axis.y - cylinder_rhs->hHeight - EGW_SFLT_EPSILON ? 1 : 0;
}

EGWint egwIsCollidingSphereFrustumf(const egwSphere4f* sphere_lhs, const egwFrustum4f* frustum_rhs) {
    return egwIsCollidingFrustumSpheref(frustum_rhs, sphere_lhs);
}

EGWint egwTestCollisionSpherePointf(const egwSphere4f* sphere_lhs, const egwVector3f* point_rhs) {
    EGWsingle diffSqrd = egwVecDistanceSqrd3f((egwVector3f*)&(sphere_lhs->origin), point_rhs) - egwSqrd(sphere_lhs->radius);
    
    if(diffSqrd <= EGW_SFLT_EPSILON) {
        if(diffSqrd < -EGW_SFLT_EPSILON) {
            return EGW_CLSNTEST_POINT_CONTAINEDBY;
        }
        return EGW_CLSNTEST_POINT_TOUCHES;
    }
    return EGW_CLSNTEST_POINT_NONE;
}

EGWint egwTestCollisionSphereLinef(const egwSphere4f* sphere_lhs, const egwLine4f* line_rhs, EGWsingle* begT_out, EGWsingle* endT_out) {
    egwVector3f orgMinCen;
    EGWsingle discr, nrmDotOrgMinCen;
    
    egwVecSubtract3f((egwVector3f*)&(line_rhs->origin), (egwVector3f*)&(sphere_lhs->origin), &orgMinCen);
    nrmDotOrgMinCen = egwVecDotProd3f((egwVector3f*)&(line_rhs->normal), &orgMinCen);
    discr = egwSqrd(nrmDotOrgMinCen) - (egwVecDotProd3f(&orgMinCen, &orgMinCen) - egwSqrd(sphere_lhs->radius));
    
    if(discr >= -EGW_SFLT_EPSILON) {
        if(begT_out || endT_out) {
            if(discr > EGW_SFLT_EPSILON) {
                discr = egwSqrtf(discr);
                if(begT_out) *begT_out = -nrmDotOrgMinCen - discr;
                if(endT_out) *endT_out = -nrmDotOrgMinCen + discr;
                return EGW_CLSNTEST_LINE_INTERSECTS;
            } else {
                discr = 0.0f;
                if(begT_out) *begT_out = -nrmDotOrgMinCen;
                if(endT_out) *endT_out = -nrmDotOrgMinCen;
                return EGW_CLSNTEST_LINE_TOUCHES;
            }
        }
        
        if(discr > EGW_SFLT_EPSILON) {
            return EGW_CLSNTEST_LINE_INTERSECTS;
        }
        return EGW_CLSNTEST_LINE_TOUCHES;
    }
    return EGW_CLSNTEST_LINE_NONE;
}

EGWint egwTestCollisionSpherePlanef(const egwSphere4f* sphere_lhs, const egwPlane4f* plane_rhs, EGWint* side_out) {
    EGWsingle t = egwVecDotProd3f((egwVector3f*)&(plane_rhs->normal), (egwVector3f*)&(sphere_lhs->origin)) + plane_rhs->d;
    EGWsingle t1 = t + sphere_lhs->radius;
    EGWsingle t2 = t - sphere_lhs->radius;
    
    if(side_out) *side_out = (t >= -EGW_SFLT_EPSILON ? (t <= EGW_SFLT_EPSILON ? 0 : 1) : -1);
    
    if(t1 <= EGW_SFLT_EPSILON && t2 >= -EGW_SFLT_EPSILON) {
        if(t1 < -EGW_SFLT_EPSILON && t2 > EGW_SFLT_EPSILON) {
            return EGW_CLSNTEST_PLANE_INTERSECTS;
        }
        return EGW_CLSNTEST_PLANE_TOUCHES;
    }
    return EGW_CLSNTEST_PLANE_NONE;
}

EGWint egwTestCollisionSphereSpheref(const egwSphere4f* sphere_lhs, const egwSphere4f* sphere_rhs) {
    EGWsingle distSqrd = egwVecDistanceSqrd3f((egwVector3f*)&sphere_lhs->origin, (egwVector3f*)&sphere_rhs->origin);
    EGWsingle diffSqrd = distSqrd - egwSqrdf(sphere_lhs->radius + sphere_rhs->radius);
    
    if(diffSqrd <= EGW_SFLT_EPSILON) {
        if(diffSqrd < -EGW_SFLT_EPSILON) {
            diffSqrd = distSqrd - egwSignSqrdf(sphere_lhs->radius - sphere_rhs->radius);
            if(distSqrd < egwSqrd(sphere_lhs->radius) - EGW_SFLT_EPSILON) {
                if(diffSqrd < -EGW_SFLT_EPSILON) {
                    return EGW_CLSNTEST_BVOL_CONTAINS;
                } else if(egwIsZerof(distSqrd) && diffSqrd <= EGW_SFLT_EPSILON) {
                    return EGW_CLSNTEST_BVOL_EQUALS;
                } else {
                    return EGW_CLSNTEST_BVOL_CONTAINEDBY;
                }
            }
            return EGW_CLSNTEST_BVOL_INTERSECTS;
        }
        return EGW_CLSNTEST_BVOL_TOUCHES;
    }
    return EGW_CLSNTEST_BVOL_NONE;
}

EGWint egwTestCollisionSphereBoxf(const egwSphere4f* sphere_lhs, const egwBox4f* box_rhs) {
    EGWint retVal = egwTestCollisionBoxSpheref(box_rhs, sphere_lhs);
    
    if(retVal == EGW_CLSNTEST_BVOL_CONTAINEDBY)
        retVal = EGW_CLSNTEST_BVOL_CONTAINS;
    else if(retVal == EGW_CLSNTEST_BVOL_CONTAINS)
        retVal = EGW_CLSNTEST_BVOL_CONTAINEDBY;
    
    return retVal;
}

EGWint egwTestCollisionSphereCylinderf(const egwSphere4f* sphere_lhs, const egwCylinder4f* cylinder_rhs) {
    EGWsingle diffMinY, diffMaxY;
    EGWsingle distSqrd = egwVecDistanceSqrd3f((egwVector3f*)&sphere_lhs->origin, (egwVector3f*)&cylinder_rhs->origin);
    EGWsingle diffSqrd = distSqrd - egwSqrdf(sphere_lhs->radius + cylinder_rhs->radius);
    
    diffMinY = (cylinder_rhs->origin.axis.y - cylinder_rhs->hHeight) - (sphere_lhs->origin.axis.y + sphere_lhs->radius);
    diffMaxY = (cylinder_rhs->origin.axis.y + cylinder_rhs->hHeight) - (sphere_lhs->origin.axis.y - sphere_lhs->radius);
    
    if(diffSqrd <= EGW_SFLT_EPSILON && diffMinY <= EGW_SFLT_EPSILON && diffMaxY >= -EGW_SFLT_EPSILON) {
        if(diffSqrd < -EGW_SFLT_EPSILON && diffMinY < -EGW_SFLT_EPSILON && diffMaxY > EGW_SFLT_EPSILON) {
            diffSqrd = distSqrd - egwSignSqrdf(sphere_lhs->radius - cylinder_rhs->radius);
            diffMinY = (cylinder_rhs->origin.axis.y + cylinder_rhs->hHeight) - (sphere_lhs->origin.axis.y - sphere_lhs->radius);
            diffMaxY = (cylinder_rhs->origin.axis.y - cylinder_rhs->hHeight) - (sphere_lhs->origin.axis.y + sphere_lhs->radius);
            
            if(distSqrd < egwSqrd(sphere_lhs->radius) - EGW_SFLT_EPSILON) {
                if(diffSqrd < -EGW_SFLT_EPSILON && diffMinY > EGW_SFLT_EPSILON && diffMaxY < -EGW_SFLT_EPSILON) {
                    return EGW_CLSNTEST_BVOL_CONTAINS;
                } else if(diffMinY < -EGW_SFLT_EPSILON && diffMaxY > EGW_SFLT_EPSILON &&
                          egwSqrdf((cylinder_rhs->origin.axis.x - cylinder_rhs->radius) - sphere_lhs->origin.axis.x) +
                          egwSqrdf((cylinder_rhs->origin.axis.y - cylinder_rhs->hHeight) - sphere_lhs->origin.axis.y) +
                          egwSqrdf((cylinder_rhs->origin.axis.z - cylinder_rhs->radius) - sphere_lhs->origin.axis.z) <
                          egwSqrd(cylinder_rhs->radius) - EGW_SFLT_EPSILON) {
                    return EGW_CLSNTEST_BVOL_CONTAINEDBY;
                }
            }
            return EGW_CLSNTEST_BVOL_INTERSECTS;
        }
        return EGW_CLSNTEST_BVOL_TOUCHES;
    }
    return EGW_CLSNTEST_BVOL_NONE;
}

EGWint egwTestCollisionSphereFrustumf(const egwSphere4f* sphere_lhs, const egwFrustum4f* frustum_rhs) {
    EGWint retVal = egwTestCollisionFrustumSpheref(frustum_rhs, sphere_lhs);
    
    if(retVal == EGW_CLSNTEST_BVOL_CONTAINEDBY)
        retVal = EGW_CLSNTEST_BVOL_CONTAINS;
    else if(retVal == EGW_CLSNTEST_BVOL_CONTAINS)
        retVal = EGW_CLSNTEST_BVOL_CONTAINEDBY;
    
    return retVal;
}

EGWint egwIsCollidingBoxPointf(const egwBox4f* box_lhs, const egwVector3f* point_rhs) {
    return (box_lhs->min.axis.x - point_rhs->axis.x <= EGW_SFLT_EPSILON &&
            box_lhs->min.axis.y - point_rhs->axis.y <= EGW_SFLT_EPSILON &&
            box_lhs->min.axis.z - point_rhs->axis.z <= EGW_SFLT_EPSILON &&
            box_lhs->max.axis.x - point_rhs->axis.x >= -EGW_SFLT_EPSILON &&
            box_lhs->max.axis.y - point_rhs->axis.y >= -EGW_SFLT_EPSILON &&
            box_lhs->max.axis.z - point_rhs->axis.z >= -EGW_SFLT_EPSILON) ? 1 : 0;
}

EGWint egwIsCollidingBoxLinef(const egwBox4f* box_lhs, const egwLine4f* line_rhs) {
    EGWsingle tXm, tXM, tYm, tYM, tZm, tZM;
    
    // Determine plane intersection coefficients and check for range intersections.
    
    if(!egwIsZerof(line_rhs->normal.axis.x)) {
        tXm = (box_lhs->min.axis.x - line_rhs->origin.axis.x) / (line_rhs->normal.axis.x);
        tXM = (box_lhs->max.axis.x - line_rhs->origin.axis.x) / (line_rhs->normal.axis.x);
    } else if(line_rhs->origin.axis.x >= box_lhs->min.axis.x - EGW_SFLT_EPSILON && line_rhs->origin.axis.x <= box_lhs->max.axis.x + EGW_SFLT_EPSILON) {
        // Makes X calculations not count against intersection
        tXm = -EGW_SFLT_MAX;
        tXM = EGW_SFLT_MAX;
    } else
        return 0;
    
    if(!egwIsZerof(line_rhs->normal.axis.y)) {
        tYm = (box_lhs->min.axis.y - line_rhs->origin.axis.y) / (line_rhs->normal.axis.y);
        tYM = (box_lhs->max.axis.y - line_rhs->origin.axis.y) / (line_rhs->normal.axis.y);
    } else if(line_rhs->origin.axis.y >= box_lhs->min.axis.y - EGW_SFLT_EPSILON && line_rhs->origin.axis.y <= box_lhs->max.axis.y + EGW_SFLT_EPSILON) {
        // Makes Y calculations not count against intersection
        tYm = -EGW_SFLT_MAX;
        tYM = EGW_SFLT_MAX;
    } else
        return 0;
    
    if(!egwIsZerof(line_rhs->normal.axis.z)) {
        tZm = (box_lhs->min.axis.z - line_rhs->origin.axis.z) / (line_rhs->normal.axis.z);
        tZM = (box_lhs->max.axis.z - line_rhs->origin.axis.z) / (line_rhs->normal.axis.z);
    } else if(line_rhs->origin.axis.z >= box_lhs->min.axis.z - EGW_SFLT_EPSILON && line_rhs->origin.axis.z <= box_lhs->max.axis.z + EGW_SFLT_EPSILON) {
        // Makes Z calculations not count against intersection
        tZm = -EGW_SFLT_MAX;
        tZM = EGW_SFLT_MAX;
    } else
        return 0;
    
    // If T ranges overlap, then intersecting (mins always <= other maxes)
    return (tXm <= tYM + EGW_SFLT_EPSILON && tXm <= tZM + EGW_SFLT_EPSILON &&
            tYm <= tXM + EGW_SFLT_EPSILON && tYm <= tZM + EGW_SFLT_EPSILON &&
            tZm <= tXM + EGW_SFLT_EPSILON && tZm <= tYM + EGW_SFLT_EPSILON) ? 1 : 0;
}

EGWint egwIsCollidingBoxPlanef(const egwBox4f* box_lhs, const egwPlane4f* plane_rhs) {
    egwVector3f edge;
    
    return (egwVecDotProd3f((egwVector3f*)&(plane_rhs->normal), egwVecInit3f(&edge, (plane_rhs->normal.axis.x >= -EGW_SFLT_EPSILON ? box_lhs->max.axis.x : box_lhs->min.axis.x), (plane_rhs->normal.axis.y >= -EGW_SFLT_EPSILON ? box_lhs->max.axis.y : box_lhs->min.axis.y), (plane_rhs->normal.axis.z >= -EGW_SFLT_EPSILON ? box_lhs->max.axis.z : box_lhs->min.axis.z))) + plane_rhs->d >= -EGW_SFLT_EPSILON &&
            egwVecDotProd3f((egwVector3f*)&(plane_rhs->normal), egwVecInit3f(&edge, (plane_rhs->normal.axis.x >= -EGW_SFLT_EPSILON ? box_lhs->min.axis.x : box_lhs->max.axis.x), (plane_rhs->normal.axis.y >= -EGW_SFLT_EPSILON ? box_lhs->min.axis.y : box_lhs->max.axis.y), (plane_rhs->normal.axis.z >= -EGW_SFLT_EPSILON ? box_lhs->min.axis.z : box_lhs->max.axis.z))) + plane_rhs->d <= EGW_SFLT_EPSILON) ? 1 : 0;
}

EGWint egwIsCollidingBoxSpheref(const egwBox4f* box_lhs, const egwSphere4f* sphere_rhs) {
    return egwIsCollidingSphereBoxf(sphere_rhs, box_lhs);
}

EGWint egwIsCollidingBoxBoxf(const egwBox4f* box_lhs, const egwBox4f* box_rhs) {
    return (box_lhs->min.axis.x - box_rhs->max.axis.x <= EGW_SFLT_EPSILON &&
            box_lhs->min.axis.y - box_rhs->max.axis.y <= EGW_SFLT_EPSILON &&
            box_lhs->min.axis.z - box_rhs->max.axis.z <= EGW_SFLT_EPSILON &&
            box_lhs->max.axis.x - box_rhs->min.axis.x >= -EGW_SFLT_EPSILON &&
            box_lhs->max.axis.y - box_rhs->min.axis.y >= -EGW_SFLT_EPSILON &&
            box_lhs->max.axis.z - box_rhs->min.axis.z >= -EGW_SFLT_EPSILON) ? 1 : 0;
}

EGWint egwIsCollidingBoxCylinderf(const egwBox4f* box_lhs, const egwCylinder4f* cylinder_rhs) {
    return (box_lhs->min.axis.x - (cylinder_rhs->origin.axis.x + cylinder_rhs->radius) <= EGW_SFLT_EPSILON &&
            box_lhs->min.axis.y - (cylinder_rhs->origin.axis.y + cylinder_rhs->hHeight) <= EGW_SFLT_EPSILON &&
            box_lhs->min.axis.z - (cylinder_rhs->origin.axis.z + cylinder_rhs->radius) <= EGW_SFLT_EPSILON &&
            box_lhs->max.axis.x - (cylinder_rhs->origin.axis.x - cylinder_rhs->radius) >= -EGW_SFLT_EPSILON &&
            box_lhs->max.axis.y - (cylinder_rhs->origin.axis.y - cylinder_rhs->hHeight) >= -EGW_SFLT_EPSILON &&
            box_lhs->max.axis.z - (cylinder_rhs->origin.axis.z - cylinder_rhs->radius) >= -EGW_SFLT_EPSILON) ? 1 : 0;
}

EGWint egwIsCollidingBoxFrustumf(const egwBox4f* box_lhs, const egwFrustum4f* frustum_rhs) {
    return egwIsCollidingFrustumBoxf(frustum_rhs, box_lhs);
}

EGWint egwTestCollisionBoxPointf(const egwBox4f* box_lhs, const egwVector3f* point_rhs) {
    egwVector3f diffMin, diffMax;
    
    egwVecInit3f(&diffMin, box_lhs->min.axis.x - point_rhs->axis.x,
                           box_lhs->min.axis.y - point_rhs->axis.y,
                           box_lhs->min.axis.z - point_rhs->axis.z);
    egwVecInit3f(&diffMax, box_lhs->max.axis.x - point_rhs->axis.x,
                           box_lhs->max.axis.y - point_rhs->axis.y,
                           box_lhs->max.axis.z - point_rhs->axis.z);
    
    if(diffMin.axis.x <= EGW_SFLT_EPSILON && diffMin.axis.y <= EGW_SFLT_EPSILON && diffMin.axis.z <= EGW_SFLT_EPSILON &&
       diffMax.axis.x >= -EGW_SFLT_EPSILON && diffMax.axis.y >= -EGW_SFLT_EPSILON && diffMax.axis.z >= -EGW_SFLT_EPSILON) {
        if(diffMin.axis.x < -EGW_SFLT_EPSILON && diffMin.axis.y < -EGW_SFLT_EPSILON && diffMin.axis.z < -EGW_SFLT_EPSILON &&
           diffMax.axis.x > EGW_SFLT_EPSILON && diffMax.axis.y > EGW_SFLT_EPSILON && diffMax.axis.z > EGW_SFLT_EPSILON) {
            return EGW_CLSNTEST_POINT_CONTAINEDBY;
        }
        return EGW_CLSNTEST_POINT_TOUCHES;
    }
    return EGW_CLSNTEST_POINT_NONE;
}

EGWint egwTestCollisionBoxLinef(const egwBox4f* box_lhs, const egwLine4f* line_rhs, EGWsingle* begT_out, EGWsingle* endT_out) {
    EGWsingle tXm, tXM, tYm, tYM, tZm, tZM, temp;
    
    // Determine plane intersection coefficients and check for range intersections.
    
    if(!egwIsZerof(line_rhs->normal.axis.x)) {
        tXm = (box_lhs->min.axis.x - line_rhs->origin.axis.x) / (line_rhs->normal.axis.x);
        tXM = (box_lhs->max.axis.x - line_rhs->origin.axis.x) / (line_rhs->normal.axis.x);
        if(tXm > tXM) { temp = tXm; tXm = tXM; tXM = temp; }
    } else if(line_rhs->origin.axis.x >= box_lhs->min.axis.x - EGW_SFLT_EPSILON && line_rhs->origin.axis.x <= box_lhs->max.axis.x + EGW_SFLT_EPSILON) {
        // Makes X calculations not count against intersection
        tXm = -EGW_SFLT_MAX;
        tXM = EGW_SFLT_MAX;
    } else
        return EGW_CLSNTEST_LINE_NONE;
    
    if(!egwIsZerof(line_rhs->normal.axis.y)) {
        tYm = (box_lhs->min.axis.y - line_rhs->origin.axis.y) / (line_rhs->normal.axis.y);
        tYM = (box_lhs->max.axis.y - line_rhs->origin.axis.y) / (line_rhs->normal.axis.y);
        if(tYm > tYM) { temp = tYm; tYm = tYM; tYM = temp; }
    } else if(line_rhs->origin.axis.y >= box_lhs->min.axis.y - EGW_SFLT_EPSILON && line_rhs->origin.axis.y <= box_lhs->max.axis.y + EGW_SFLT_EPSILON) {
        // Makes Y calculations not count against intersection
        tYm = -EGW_SFLT_MAX;
        tYM = EGW_SFLT_MAX;
    } else
        return EGW_CLSNTEST_LINE_NONE;
    
    if(!egwIsZerof(line_rhs->normal.axis.z)) {
        tZm = (box_lhs->min.axis.z - line_rhs->origin.axis.z) / (line_rhs->normal.axis.z);
        tZM = (box_lhs->max.axis.z - line_rhs->origin.axis.z) / (line_rhs->normal.axis.z);
        if(tZm > tZM) { temp = tZm; tZm = tZM; tZM = temp; }
    } else if(line_rhs->origin.axis.z >= box_lhs->min.axis.z - EGW_SFLT_EPSILON && line_rhs->origin.axis.z <= box_lhs->max.axis.z + EGW_SFLT_EPSILON) {
        // Makes Z calculations not count against intersection
        tZm = -EGW_SFLT_MAX;
        tZM = EGW_SFLT_MAX;
    } else
        return EGW_CLSNTEST_LINE_NONE;
    
    // If T ranges overlap, then intersecting (mins always <= other maxes)
    if(tXm <= tYM + EGW_SFLT_EPSILON && tXm <= tZM + EGW_SFLT_EPSILON &&
       tYm <= tXM + EGW_SFLT_EPSILON && tYm <= tZM + EGW_SFLT_EPSILON &&
       tZm <= tXM + EGW_SFLT_EPSILON && tZm <= tYM + EGW_SFLT_EPSILON) {
        
        // The maximum minT and minimum maxT are the enter and exit positions
        if(begT_out) *begT_out = egwMax2f(tXm, egwMax2f(tYm, tZm));
        if(endT_out) *endT_out = egwMin2f(tXM, egwMin2f(tYM, tZM));
        
        if(tXm < tYM - EGW_SFLT_EPSILON && tXm < tZM - EGW_SFLT_EPSILON &&
           tYm < tXM - EGW_SFLT_EPSILON && tYm < tZM - EGW_SFLT_EPSILON &&
           tZm < tXM - EGW_SFLT_EPSILON && tZm < tYM - EGW_SFLT_EPSILON) {
            return EGW_CLSNTEST_LINE_INTERSECTS;
        }
        return EGW_CLSNTEST_LINE_TOUCHES;
    }
    return EGW_CLSNTEST_LINE_NONE;
}

EGWint egwTestCollisionBoxPlanef(const egwBox4f* box_lhs, const egwPlane4f* plane_rhs, EGWint* side_out) {
    egwVector3f edge1, edge2;
    EGWsingle t1 = egwVecDotProd3f((egwVector3f*)&(plane_rhs->normal), egwVecInit3f(&edge1, (plane_rhs->normal.axis.x >= -EGW_SFLT_EPSILON ? box_lhs->max.axis.x : box_lhs->min.axis.x), (plane_rhs->normal.axis.y >= -EGW_SFLT_EPSILON ? box_lhs->max.axis.y : box_lhs->min.axis.y), (plane_rhs->normal.axis.z >= -EGW_SFLT_EPSILON ? box_lhs->max.axis.z : box_lhs->min.axis.z))) + plane_rhs->d;
    EGWsingle t2 = egwVecDotProd3f((egwVector3f*)&(plane_rhs->normal), egwVecInit3f(&edge2, (plane_rhs->normal.axis.x >= -EGW_SFLT_EPSILON ? box_lhs->min.axis.x : box_lhs->max.axis.x), (plane_rhs->normal.axis.y >= -EGW_SFLT_EPSILON ? box_lhs->min.axis.y : box_lhs->max.axis.y), (plane_rhs->normal.axis.z >= -EGW_SFLT_EPSILON ? box_lhs->min.axis.z : box_lhs->max.axis.z))) + plane_rhs->d;
    
    if(side_out) {
        if(t1 >= -EGW_SFLT_EPSILON && t2 <= EGW_SFLT_EPSILON && egwIsEqualf(egwAbsf(t1), egwAbsf(t2)))
            *side_out = 0;
        else {
            if(t1 >= -EGW_SFLT_EPSILON) {
                if(t2 >= -EGW_SFLT_EPSILON) *side_out = 1;
                else *side_out = (egwAbsf(t1) > egwAbsf(t2) ? 1 : -1);
            } else {
                if(t2 <= EGW_SFLT_EPSILON) *side_out = -1;
                else *side_out = (egwAbsf(t1) > egwAbsf(t2) ? -1 : 1);
            }
        }
    }
    
    if(t1 >= -EGW_SFLT_EPSILON && t2 <= EGW_SFLT_EPSILON) {
        if(t1 > EGW_SFLT_EPSILON && t2 < -EGW_SFLT_EPSILON) {
            return EGW_CLSNTEST_PLANE_INTERSECTS;
        }
        return EGW_CLSNTEST_PLANE_TOUCHES;
    }
    return EGW_CLSNTEST_PLANE_NONE;
}

EGWint egwTestCollisionBoxSpheref(const egwBox4f* box_lhs, const egwSphere4f* sphere_rhs) {
    egwVector3f diffMin, diffMax;
    
    egwVecInit3f(&diffMin, box_lhs->min.axis.x - (sphere_rhs->origin.axis.x + sphere_rhs->radius),
                           box_lhs->min.axis.y - (sphere_rhs->origin.axis.y + sphere_rhs->radius),
                           box_lhs->min.axis.z - (sphere_rhs->origin.axis.z + sphere_rhs->radius));
    egwVecInit3f(&diffMax, box_lhs->max.axis.x - (sphere_rhs->origin.axis.x - sphere_rhs->radius),
                           box_lhs->max.axis.y - (sphere_rhs->origin.axis.y - sphere_rhs->radius),
                           box_lhs->max.axis.z - (sphere_rhs->origin.axis.z - sphere_rhs->radius));
    
    if(diffMin.axis.x <= EGW_SFLT_EPSILON && diffMin.axis.y <= EGW_SFLT_EPSILON && diffMin.axis.z <= EGW_SFLT_EPSILON &&
       diffMax.axis.x >= -EGW_SFLT_EPSILON && diffMax.axis.y >= -EGW_SFLT_EPSILON && diffMax.axis.z >= -EGW_SFLT_EPSILON) {
        if(diffMin.axis.x < -EGW_SFLT_EPSILON && diffMin.axis.y < -EGW_SFLT_EPSILON && diffMin.axis.z < -EGW_SFLT_EPSILON &&
           diffMax.axis.x > EGW_SFLT_EPSILON && diffMax.axis.y > EGW_SFLT_EPSILON && diffMax.axis.z > EGW_SFLT_EPSILON) {
            egwVecInit3f(&diffMin, box_lhs->min.axis.x - (sphere_rhs->origin.axis.x - sphere_rhs->radius),
                                   box_lhs->min.axis.y - (sphere_rhs->origin.axis.y - sphere_rhs->radius),
                                   box_lhs->min.axis.z - (sphere_rhs->origin.axis.z - sphere_rhs->radius));
            egwVecInit3f(&diffMax, box_lhs->max.axis.x - (sphere_rhs->origin.axis.x + sphere_rhs->radius),
                                   box_lhs->max.axis.y - (sphere_rhs->origin.axis.y + sphere_rhs->radius),
                                   box_lhs->max.axis.z - (sphere_rhs->origin.axis.z + sphere_rhs->radius));
            
            if(diffMin.axis.x < -EGW_SFLT_EPSILON && diffMin.axis.y < -EGW_SFLT_EPSILON && diffMin.axis.z < -EGW_SFLT_EPSILON &&
               diffMax.axis.x > EGW_SFLT_EPSILON && diffMax.axis.y > EGW_SFLT_EPSILON && diffMax.axis.z > EGW_SFLT_EPSILON) {
                return EGW_CLSNTEST_BVOL_CONTAINS;
            } else if(diffMin.axis.x > EGW_SFLT_EPSILON && diffMin.axis.y > EGW_SFLT_EPSILON && diffMin.axis.z > EGW_SFLT_EPSILON &&
                      diffMax.axis.x < -EGW_SFLT_EPSILON && diffMax.axis.y < -EGW_SFLT_EPSILON && diffMax.axis.z < -EGW_SFLT_EPSILON &&
                      egwSqrdf(egwMax2f(egwAbsf(box_lhs->min.axis.x - sphere_rhs->origin.axis.x), egwAbsf(box_lhs->max.axis.x - sphere_rhs->origin.axis.x))) +
                      egwSqrdf(egwMax2f(egwAbsf(box_lhs->min.axis.y - sphere_rhs->origin.axis.y), egwAbsf(box_lhs->max.axis.y - sphere_rhs->origin.axis.y))) +
                      egwSqrdf(egwMax2f(egwAbsf(box_lhs->min.axis.z - sphere_rhs->origin.axis.z), egwAbsf(box_lhs->max.axis.z - sphere_rhs->origin.axis.z))) <
                      egwSqrd(sphere_rhs->radius) - EGW_SFLT_EPSILON) {
                    return EGW_CLSNTEST_BVOL_CONTAINEDBY;
            }
            return EGW_CLSNTEST_BVOL_INTERSECTS;
        }
        return EGW_CLSNTEST_BVOL_TOUCHES;
    }
    return EGW_CLSNTEST_BVOL_NONE;
}

EGWint egwTestCollisionBoxBoxf(const egwBox4f* box_lhs, const egwBox4f* box_rhs) {
    egwVector3f diffMin, diffMax;
    
    egwVecInit3f(&diffMin, box_lhs->min.axis.x - box_rhs->max.axis.x,
                           box_lhs->min.axis.y - box_rhs->max.axis.y,
                           box_lhs->min.axis.z - box_rhs->max.axis.z);
    egwVecInit3f(&diffMax, box_lhs->max.axis.x - box_rhs->min.axis.x,
                           box_lhs->max.axis.y - box_rhs->min.axis.y,
                           box_lhs->max.axis.z - box_rhs->min.axis.z);
    
    if(diffMin.axis.x <= EGW_SFLT_EPSILON && diffMin.axis.y <= EGW_SFLT_EPSILON && diffMin.axis.z <= EGW_SFLT_EPSILON &&
       diffMax.axis.x >= -EGW_SFLT_EPSILON && diffMax.axis.y >= -EGW_SFLT_EPSILON && diffMax.axis.z >= -EGW_SFLT_EPSILON) {
        if(diffMin.axis.x < -EGW_SFLT_EPSILON && diffMin.axis.y < -EGW_SFLT_EPSILON && diffMin.axis.z < -EGW_SFLT_EPSILON &&
           diffMax.axis.x > EGW_SFLT_EPSILON && diffMax.axis.y > EGW_SFLT_EPSILON && diffMax.axis.z > EGW_SFLT_EPSILON) {
            egwVecInit3f(&diffMin, box_lhs->min.axis.x - box_rhs->min.axis.x,
                                   box_lhs->min.axis.y - box_rhs->min.axis.y,
                                   box_lhs->min.axis.z - box_rhs->min.axis.z);
            egwVecInit3f(&diffMax, box_lhs->max.axis.x - box_rhs->max.axis.x,
                                   box_lhs->max.axis.y - box_rhs->max.axis.y,
                                   box_lhs->max.axis.z - box_rhs->max.axis.z);
            
            if(diffMin.axis.x < -EGW_SFLT_EPSILON && diffMin.axis.y < -EGW_SFLT_EPSILON && diffMin.axis.z < -EGW_SFLT_EPSILON &&
               diffMax.axis.x > EGW_SFLT_EPSILON && diffMax.axis.y > EGW_SFLT_EPSILON && diffMax.axis.z > EGW_SFLT_EPSILON) {
                return EGW_CLSNTEST_BVOL_CONTAINS;
            } else if(egwVecIsEqual3f(&diffMin, &egwSIVecZero3f) && egwVecIsEqual3f(&diffMax, &egwSIVecZero3f)) {
                return EGW_CLSNTEST_BVOL_EQUALS;
            } else if(diffMin.axis.x > EGW_SFLT_EPSILON && diffMin.axis.y > EGW_SFLT_EPSILON && diffMin.axis.z > EGW_SFLT_EPSILON &&
                      diffMax.axis.x < -EGW_SFLT_EPSILON && diffMax.axis.y < -EGW_SFLT_EPSILON && diffMax.axis.z < -EGW_SFLT_EPSILON) {
                return EGW_CLSNTEST_BVOL_CONTAINEDBY;
            }
            return EGW_CLSNTEST_BVOL_INTERSECTS;
        }
        return EGW_CLSNTEST_BVOL_TOUCHES;
    }
    return EGW_CLSNTEST_BVOL_NONE;
}

EGWint egwTestCollisionBoxCylinderf(const egwBox4f* box_lhs, const egwCylinder4f* cylinder_rhs) {
    egwVector3f diffMin, diffMax;
    
    egwVecInit3f(&diffMin, box_lhs->min.axis.x - (cylinder_rhs->origin.axis.x + cylinder_rhs->radius),
                           box_lhs->min.axis.y - (cylinder_rhs->origin.axis.y + cylinder_rhs->hHeight),
                           box_lhs->min.axis.z - (cylinder_rhs->origin.axis.z + cylinder_rhs->radius));
    egwVecInit3f(&diffMax, box_lhs->max.axis.x - (cylinder_rhs->origin.axis.x - cylinder_rhs->radius),
                           box_lhs->max.axis.y - (cylinder_rhs->origin.axis.y - cylinder_rhs->hHeight),
                           box_lhs->max.axis.z - (cylinder_rhs->origin.axis.z - cylinder_rhs->radius));
    
    if(diffMin.axis.x <= EGW_SFLT_EPSILON && diffMin.axis.y <= EGW_SFLT_EPSILON && diffMin.axis.z <= EGW_SFLT_EPSILON &&
       diffMax.axis.x >= -EGW_SFLT_EPSILON && diffMax.axis.y >= -EGW_SFLT_EPSILON && diffMax.axis.z >= -EGW_SFLT_EPSILON) {
        if(diffMin.axis.x < -EGW_SFLT_EPSILON && diffMin.axis.y < -EGW_SFLT_EPSILON && diffMin.axis.z < -EGW_SFLT_EPSILON &&
           diffMax.axis.x > EGW_SFLT_EPSILON && diffMax.axis.y > EGW_SFLT_EPSILON && diffMax.axis.z > EGW_SFLT_EPSILON) {
            egwVecInit3f(&diffMin, box_lhs->min.axis.x - (cylinder_rhs->origin.axis.x - cylinder_rhs->radius),
                                   box_lhs->min.axis.y - (cylinder_rhs->origin.axis.y - cylinder_rhs->hHeight),
                                   box_lhs->min.axis.z - (cylinder_rhs->origin.axis.z - cylinder_rhs->radius));
            egwVecInit3f(&diffMax, box_lhs->max.axis.x - (cylinder_rhs->origin.axis.x + cylinder_rhs->radius),
                                   box_lhs->max.axis.y - (cylinder_rhs->origin.axis.y + cylinder_rhs->hHeight),
                                   box_lhs->max.axis.z - (cylinder_rhs->origin.axis.z + cylinder_rhs->radius));
            
            if(diffMin.axis.x < -EGW_SFLT_EPSILON && diffMin.axis.y < -EGW_SFLT_EPSILON && diffMin.axis.z < -EGW_SFLT_EPSILON &&
               diffMax.axis.x > EGW_SFLT_EPSILON && diffMax.axis.y > EGW_SFLT_EPSILON && diffMax.axis.z > EGW_SFLT_EPSILON) {
                return EGW_CLSNTEST_BVOL_CONTAINS;
            }  else if(diffMin.axis.x > EGW_SFLT_EPSILON && diffMin.axis.y > EGW_SFLT_EPSILON && diffMin.axis.z > EGW_SFLT_EPSILON &&
                       diffMax.axis.x < -EGW_SFLT_EPSILON && diffMax.axis.y < -EGW_SFLT_EPSILON && diffMax.axis.z < -EGW_SFLT_EPSILON &&
                       egwSqrdf(egwMax2f(egwAbsf(box_lhs->min.axis.x - cylinder_rhs->origin.axis.x), egwAbsf(box_lhs->max.axis.x - cylinder_rhs->origin.axis.x))) +
                       egwSqrdf(egwMax2f(egwAbsf(box_lhs->min.axis.z - cylinder_rhs->origin.axis.z), egwAbsf(box_lhs->max.axis.z - cylinder_rhs->origin.axis.z))) <
                       egwSqrd(cylinder_rhs->radius) - EGW_SFLT_EPSILON) {
                return EGW_CLSNTEST_BVOL_CONTAINEDBY;
            }
            return EGW_CLSNTEST_BVOL_INTERSECTS;
        }
        return EGW_CLSNTEST_BVOL_TOUCHES;
    }
    return EGW_CLSNTEST_BVOL_NONE;
}

EGWint egwTestCollisionBoxFrustumf(const egwBox4f* box_lhs, const egwFrustum4f* frustum_rhs) {
    EGWint retVal = egwTestCollisionFrustumBoxf(frustum_rhs, box_lhs);
    
    if(retVal == EGW_CLSNTEST_BVOL_CONTAINEDBY)
        retVal = EGW_CLSNTEST_BVOL_CONTAINS;
    else if(retVal == EGW_CLSNTEST_BVOL_CONTAINS)
        retVal = EGW_CLSNTEST_BVOL_CONTAINEDBY;
    
    return retVal;
}

EGWint egwIsCollidingCylinderPointf(const egwCylinder4f* cylinder_lhs, const egwVector3f* point_rhs) {
    return egwVecDistanceSqrdXZ3f((egwVector3f*)&cylinder_lhs->origin, point_rhs) -
           egwSqrd(cylinder_lhs->radius) <= EGW_SFLT_EPSILON &&
           point_rhs->axis.y <= cylinder_lhs->origin.axis.y + cylinder_lhs->hHeight + EGW_SFLT_EPSILON &&
           point_rhs->axis.y >= cylinder_lhs->origin.axis.y - cylinder_lhs->hHeight - EGW_SFLT_EPSILON ? 1 : 0;
}

EGWint egwIsCollidingCylinderLinef(const egwCylinder4f* cylinder_lhs, const egwLine4f* line_rhs) {
    // TODO: egwIsCollidingCylinderLinef.
    NSLog(@"egwIsCollidingCylinderLinef: Error: This routine not currently implemented.");
    return -1;
}

EGWint egwIsCollidingCylinderPlanef(const egwCylinder4f* cylinder_lhs, const egwPlane4f* plane_rhs) {
    EGWsingle dotPnCa = egwAbsf(egwVecDotProd3f((egwVector3f*)&plane_rhs->normal, &egwSIVecUnitY3f)); // replace UnitY with axis direction for oriented
    return egwAbsf(egwPlanePointClosestDist4f(plane_rhs, (egwVector3f*)&cylinder_lhs->origin)) <=
           (cylinder_lhs->radius * egwSqrtf(egwAbsf(1.0f - egwSqrd(dotPnCa)))) + (cylinder_lhs->hHeight * dotPnCa) + EGW_SFLT_EPSILON ? 1 : 0;
}

EGWint egwIsCollidingCylinderSpheref(const egwCylinder4f* cylinder_lhs, const egwSphere4f* sphere_rhs) {
    return egwIsCollidingSphereCylinderf(sphere_rhs, cylinder_lhs);
}

EGWint egwIsCollidingCylinderBoxf(const egwCylinder4f* cylinder_lhs, const egwBox4f* box_rhs) {
    return egwIsCollidingBoxCylinderf(box_rhs, cylinder_lhs);
}

EGWint egwIsCollidingCylinderCylinderf(const egwCylinder4f* cylinder_lhs, const egwCylinder4f* cylinder_rhs) {
    return ((egwVecDistanceSqrdXZ3f((egwVector3f*)&cylinder_lhs->origin, (egwVector3f*)&cylinder_rhs->origin) <=
             egwSqrdf(cylinder_lhs->radius + cylinder_rhs->radius) + EGW_SFLT_EPSILON) &&
            (egwAbsf(cylinder_lhs->origin.axis.y - cylinder_rhs->origin.axis.y) <=
             cylinder_lhs->hHeight + cylinder_rhs->hHeight + EGW_SFLT_EPSILON)) ? 1 : 0;
}

EGWint egwIsCollidingCylinderFrustumf(const egwCylinder4f* cylinder_lhs, const egwFrustum4f* frustum_rhs) {
    return egwIsCollidingFrustumCylinderf(frustum_rhs, cylinder_lhs);
}

EGWint egwTestCollisionCylinderPointf(const egwCylinder4f* cylinder_lhs, const egwVector3f* point_rhs) {
    // TODO: egwTestCollisionCylinderPointf.
    NSLog(@"egwTestCollisionCylinderPointf: Error: This routine not currently implemented.");
    return EGW_CLSNTEST_POINT_NA;
}

EGWint egwTestCollisionCylinderLinef(const egwCylinder4f* cylinder_lhs, const egwLine4f* line_rhs, EGWsingle* begT_out, EGWsingle* endT_out) {
    // TODO: egwTestCollisionCylinderLinef.
    NSLog(@"egwTestCollisionCylinderLinef: Error: This routine not currently implemented.");
    return EGW_CLSNTEST_LINE_NA;
}

EGWint egwTestCollisionCylinderPlanef(const egwCylinder4f* cylinder_lhs, const egwPlane4f* plane_rhs, EGWint* side_out) {
    // TODO: egwTestCollisionCylinderPlanef.
    NSLog(@"egwTestCollisionCylinderPlanef: Error: This routine not currently implemented.");
    return EGW_CLSNTEST_PLANE_NA;
}

EGWint egwTestCollisionCylinderSpheref(const egwCylinder4f* cylinder_lhs, const egwSphere4f* sphere_rhs) {
    EGWint retVal = egwTestCollisionSphereCylinderf(sphere_rhs, cylinder_lhs);
    
    if(retVal == EGW_CLSNTEST_BVOL_CONTAINEDBY)
        retVal = EGW_CLSNTEST_BVOL_CONTAINS;
    else if(retVal == EGW_CLSNTEST_BVOL_CONTAINS)
        retVal = EGW_CLSNTEST_BVOL_CONTAINEDBY;
    
    return retVal;
}

EGWint egwTestCollisionCylinderBoxf(const egwCylinder4f* cylinder_lhs, const egwBox4f* box_rhs) {
    EGWint retVal = egwTestCollisionBoxCylinderf(box_rhs, cylinder_lhs);
    
    if(retVal == EGW_CLSNTEST_BVOL_CONTAINEDBY)
        retVal = EGW_CLSNTEST_BVOL_CONTAINS;
    else if(retVal == EGW_CLSNTEST_BVOL_CONTAINS)
        retVal = EGW_CLSNTEST_BVOL_CONTAINEDBY;
    
    return retVal;
}

EGWint egwTestCollisionCylinderCylinderf(const egwCylinder4f* cylinder_lhs, const egwCylinder4f* cylinder_rhs) {
    EGWsingle diffMinY, diffMaxY;
    EGWsingle distSqrd = egwVecDistanceSqrdXZ3f((egwVector3f*)&cylinder_lhs->origin, (egwVector3f*)&cylinder_rhs->origin);
    EGWsingle diffSqrd = distSqrd - egwSqrdf(cylinder_lhs->radius + cylinder_rhs->radius);
    
    diffMinY = (cylinder_rhs->origin.axis.y - cylinder_rhs->hHeight) - (cylinder_lhs->origin.axis.y + cylinder_lhs->hHeight);
    diffMaxY = (cylinder_rhs->origin.axis.y + cylinder_rhs->hHeight) - (cylinder_lhs->origin.axis.y - cylinder_lhs->hHeight);
    
    if(diffSqrd <= EGW_SFLT_EPSILON && diffMinY <= EGW_SFLT_EPSILON && diffMaxY >= -EGW_SFLT_EPSILON) {
        if(diffSqrd < -EGW_SFLT_EPSILON && diffMinY < -EGW_SFLT_EPSILON && diffMaxY > EGW_SFLT_EPSILON) {
            diffSqrd = distSqrd - egwSignSqrdf(cylinder_lhs->radius - cylinder_rhs->radius);
            diffMinY = (cylinder_rhs->origin.axis.y + cylinder_rhs->hHeight) - (cylinder_lhs->origin.axis.y - cylinder_lhs->hHeight);
            diffMaxY = (cylinder_rhs->origin.axis.y - cylinder_rhs->hHeight) - (cylinder_lhs->origin.axis.y + cylinder_lhs->hHeight);
            
            if(distSqrd < egwSqrd(cylinder_lhs->radius) - EGW_SFLT_EPSILON) {
                if(diffSqrd < -EGW_SFLT_EPSILON && diffMinY > EGW_SFLT_EPSILON && diffMaxY < -EGW_SFLT_EPSILON) {
                    return EGW_CLSNTEST_BVOL_CONTAINS;
                } else if(diffSqrd <= EGW_SFLT_EPSILON && egwIsZerof(diffMinY) && egwIsZerof(diffMaxY)) {
                    return EGW_CLSNTEST_BVOL_EQUALS;
                } else if(diffMinY < -EGW_SFLT_EPSILON && diffMaxY > EGW_SFLT_EPSILON) {
                    return EGW_CLSNTEST_BVOL_CONTAINEDBY;
                }
            }
            return EGW_CLSNTEST_BVOL_INTERSECTS;
        }
        return EGW_CLSNTEST_BVOL_TOUCHES;
    }
    return EGW_CLSNTEST_BVOL_NONE;
}

EGWint egwTestCollisionCylinderFrustumf(const egwCylinder4f* cylinder_lhs, const egwFrustum4f* frustum_rhs) {
    EGWint retVal = egwTestCollisionFrustumCylinderf(frustum_rhs, cylinder_lhs);
    
    if(retVal == EGW_CLSNTEST_BVOL_CONTAINEDBY)
        retVal = EGW_CLSNTEST_BVOL_CONTAINS;
    else if(retVal == EGW_CLSNTEST_BVOL_CONTAINS)
        retVal = EGW_CLSNTEST_BVOL_CONTAINEDBY;
    
    return retVal;
}

EGWint egwIsCollidingFrustumPointf(const egwFrustum4f* frustum_lhs, const egwVector3f* point_rhs) {
    return (egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMin.normal), point_rhs) + frustum_lhs->xMin.d >= -EGW_SFLT_EPSILON &&
            egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMax.normal), point_rhs) + frustum_lhs->xMax.d >= -EGW_SFLT_EPSILON &&
            egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMin.normal), point_rhs) + frustum_lhs->yMin.d >= -EGW_SFLT_EPSILON &&
            egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMax.normal), point_rhs) + frustum_lhs->yMax.d >= -EGW_SFLT_EPSILON &&
            egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMin.normal), point_rhs) + frustum_lhs->zMin.d >= -EGW_SFLT_EPSILON &&
            egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMax.normal), point_rhs) + frustum_lhs->zMax.d >= -EGW_SFLT_EPSILON) ? 1 : 0;
}

EGWint egwIsCollidingFrustumLinef(const egwFrustum4f* frustum_lhs, const egwLine4f* line_rhs) {
    egwVector3f orgMinOrg;
    EGWsingle tXm, tXM, tYm, tYM, tZm, tZM;
    
    // Determine plane intersection coefficients and check for range intersections.
    
    tXm = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMin.normal), (egwVector3f*)&(line_rhs->normal));
    if(!egwIsZerof(tXm)) {
        tXm = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMin.normal), egwVecSubtract3f((egwVector3f*)&(frustum_lhs->xMin.origin), (egwVector3f*)&(line_rhs->origin), &orgMinOrg)) / tXm;
    } else if(egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMin.normal), (egwVector3f*)&(line_rhs->origin)) + frustum_lhs->xMin.d >= -EGW_SFLT_EPSILON) {
        // Makes Xmin calculations not count against intersection
        tXm = -EGW_SFLT_MAX;
    } else
        return 0;
    
    tXM = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMax.normal), (egwVector3f*)&(line_rhs->normal));
    if(!egwIsZerof(tXM)) {
        tXM = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMax.normal), egwVecSubtract3f((egwVector3f*)&(frustum_lhs->xMax.origin), (egwVector3f*)&(line_rhs->origin), &orgMinOrg)) / tXM;
    } else if(egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMax.normal), (egwVector3f*)&(line_rhs->origin)) + frustum_lhs->xMax.d >= -EGW_SFLT_EPSILON) {
        // Makes Xmax calculations not count against intersection
        tXM = EGW_SFLT_MAX;
    } else
        return 0;
    
    tYm = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMin.normal), (egwVector3f*)&(line_rhs->normal));
    if(!egwIsZerof(tYm)) {
        tYm = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMin.normal), egwVecSubtract3f((egwVector3f*)&(frustum_lhs->yMin.origin), (egwVector3f*)&(line_rhs->origin), &orgMinOrg)) / tYm;
    } else if(egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMin.normal), (egwVector3f*)&(line_rhs->origin)) + frustum_lhs->yMin.d >= -EGW_SFLT_EPSILON) {
        // Makes Ymin calculations not count against intersection
        tYm = -EGW_SFLT_MAX;
    } else
        return 0;
    
    tYM = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMax.normal), (egwVector3f*)&(line_rhs->normal));
    if(!egwIsZerof(tYM)) {
        tYM = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMax.normal), egwVecSubtract3f((egwVector3f*)&(frustum_lhs->yMax.origin), (egwVector3f*)&(line_rhs->origin), &orgMinOrg)) / tYM;
    } else if(egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMax.normal), (egwVector3f*)&(line_rhs->origin)) + frustum_lhs->yMax.d >= -EGW_SFLT_EPSILON) {
        // Makes Ymax calculations not count against intersection
        tYM = EGW_SFLT_MAX;
    } else
        return 0;
    
    tZm = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMin.normal), (egwVector3f*)&(line_rhs->normal));
    if(!egwIsZerof(tZm)) {
        tZm = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMin.normal), egwVecSubtract3f((egwVector3f*)&(frustum_lhs->zMin.origin), (egwVector3f*)&(line_rhs->origin), &orgMinOrg)) / tZm;
    } else if(egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMin.normal), (egwVector3f*)&(line_rhs->origin)) + frustum_lhs->zMin.d >= -EGW_SFLT_EPSILON) {
        // Makes Zmin calculations not count against intersection
        tZm = -EGW_SFLT_MAX;
    } else
        return 0;
    
    tZM = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMax.normal), (egwVector3f*)&(line_rhs->normal));
    if(!egwIsZerof(tZM)) {
        tZM = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMax.normal), egwVecSubtract3f((egwVector3f*)&(frustum_lhs->zMax.origin), (egwVector3f*)&(line_rhs->origin), &orgMinOrg)) / tZM;
    } else if(egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMax.normal), (egwVector3f*)&(line_rhs->origin)) + frustum_lhs->zMax.d >= -EGW_SFLT_EPSILON) {
        // Makes Zmax calculations not count against intersection
        tZM = EGW_SFLT_MAX;
    } else
        return 0;
    
    // If T ranges overlap, then intersecting (mins always <= other maxes)
    return (tXm <= tYM + EGW_SFLT_EPSILON && tXm <= tZM + EGW_SFLT_EPSILON &&
            tYm <= tXM + EGW_SFLT_EPSILON && tYm <= tZM + EGW_SFLT_EPSILON &&
            tZm <= tXM + EGW_SFLT_EPSILON && tZm <= tYM + EGW_SFLT_EPSILON) ? 1 : 0;
}

EGWint egwIsCollidingFrustumPlanef(const egwFrustum4f* frustum_lhs, const egwPlane4f* plane_rhs) {
    // TODO: egwIsCollidingFrustumPlanef.
    NSLog(@"egwIsCollidingFrustumPlanef: Error: This routine not currently implemented.");
    return -1;
}

EGWint egwIsCollidingFrustumSpheref(const egwFrustum4f* frustum_lhs, const egwSphere4f* sphere_rhs) {
    return (egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMin.normal), (egwVector3f*)&(sphere_rhs->origin)) + frustum_lhs->xMin.d + sphere_rhs->radius >= -EGW_SFLT_EPSILON &&
            egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMax.normal), (egwVector3f*)&(sphere_rhs->origin)) + frustum_lhs->xMax.d + sphere_rhs->radius >= -EGW_SFLT_EPSILON &&
            egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMin.normal), (egwVector3f*)&(sphere_rhs->origin)) + frustum_lhs->yMin.d + sphere_rhs->radius >= -EGW_SFLT_EPSILON &&
            egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMax.normal), (egwVector3f*)&(sphere_rhs->origin)) + frustum_lhs->yMax.d + sphere_rhs->radius >= -EGW_SFLT_EPSILON &&
            egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMin.normal), (egwVector3f*)&(sphere_rhs->origin)) + frustum_lhs->zMin.d + sphere_rhs->radius >= -EGW_SFLT_EPSILON &&
            egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMax.normal), (egwVector3f*)&(sphere_rhs->origin)) + frustum_lhs->zMax.d + sphere_rhs->radius >= -EGW_SFLT_EPSILON) ? 1 : 0;
}

EGWint egwIsCollidingFrustumBoxf(const egwFrustum4f* frustum_lhs, const egwBox4f* box_rhs) {
    egwVector3f edge;
    
    return (egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMin.normal), egwVecInit3f(&edge, (frustum_lhs->xMin.normal.axis.x >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.x : box_rhs->min.axis.x), (frustum_lhs->xMin.normal.axis.y >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.y : box_rhs->min.axis.y), (frustum_lhs->xMin.normal.axis.z >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.z : box_rhs->min.axis.z))) + frustum_lhs->xMin.d >= -EGW_SFLT_EPSILON &&
            egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMax.normal), egwVecInit3f(&edge, (frustum_lhs->xMax.normal.axis.x >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.x : box_rhs->min.axis.x), (frustum_lhs->xMax.normal.axis.y >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.y : box_rhs->min.axis.y), (frustum_lhs->xMax.normal.axis.z >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.z : box_rhs->min.axis.z))) + frustum_lhs->xMax.d >= -EGW_SFLT_EPSILON &&
            egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMin.normal), egwVecInit3f(&edge, (frustum_lhs->yMin.normal.axis.x >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.x : box_rhs->min.axis.x), (frustum_lhs->yMin.normal.axis.y >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.y : box_rhs->min.axis.y), (frustum_lhs->yMin.normal.axis.z >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.z : box_rhs->min.axis.z))) + frustum_lhs->yMin.d >= -EGW_SFLT_EPSILON &&
            egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMax.normal), egwVecInit3f(&edge, (frustum_lhs->yMax.normal.axis.x >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.x : box_rhs->min.axis.x), (frustum_lhs->yMax.normal.axis.y >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.y : box_rhs->min.axis.y), (frustum_lhs->yMax.normal.axis.z >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.z : box_rhs->min.axis.z))) + frustum_lhs->yMax.d >= -EGW_SFLT_EPSILON &&
            egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMin.normal), egwVecInit3f(&edge, (frustum_lhs->zMin.normal.axis.x >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.x : box_rhs->min.axis.x), (frustum_lhs->zMin.normal.axis.y >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.y : box_rhs->min.axis.y), (frustum_lhs->zMin.normal.axis.z >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.z : box_rhs->min.axis.z))) + frustum_lhs->zMin.d >= -EGW_SFLT_EPSILON &&
            egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMax.normal), egwVecInit3f(&edge, (frustum_lhs->zMax.normal.axis.x >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.x : box_rhs->min.axis.x), (frustum_lhs->zMax.normal.axis.y >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.y : box_rhs->min.axis.y), (frustum_lhs->zMax.normal.axis.z >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.z : box_rhs->min.axis.z))) + frustum_lhs->zMax.d >= -EGW_SFLT_EPSILON) ? 1 : 0;
}

EGWint egwIsCollidingFrustumCylinderf(const egwFrustum4f* frustum_lhs, const egwCylinder4f* cylinder_rhs) {
    // TODO: egwIsCollidingFrustumCylinderf.
    NSLog(@"egwIsCollidingFrustumCylinderf: Error: This routine not currently implemented.");
    return -1;
}

EGWint egwIsCollidingFrustumFrustumf(const egwFrustum4f* frustum_lhs, const egwFrustum4f* frustum_rhs) {
    // TODO: egwIsCollidingFrustumFrustumf.
    NSLog(@"egwIsCollidingFrustumFrustumf: Error: This routine not currently implemented.");
    return -1;
}

EGWint egwTestCollisionFrustumPointf(const egwFrustum4f* frustum_lhs, const egwVector3f* point_rhs) {
    EGWint bestRetVal = EGW_CLSNTEST_POINT_CONTAINEDBY;
    EGWsingle t;
    
    t = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMin.normal), point_rhs) + frustum_lhs->xMin.d;
    if(t <= EGW_SFLT_EPSILON) {
        if(t >= -EGW_SFLT_EPSILON) bestRetVal = EGW_CLSNTEST_POINT_TOUCHES;
        else return EGW_CLSNTEST_POINT_NONE;
    }
    
    t = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMax.normal), point_rhs) + frustum_lhs->xMax.d;
    if(t <= EGW_SFLT_EPSILON) {
        if(t >= -EGW_SFLT_EPSILON) bestRetVal = EGW_CLSNTEST_POINT_TOUCHES;
        else return EGW_CLSNTEST_POINT_NONE;
    }
    
    t = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMin.normal), point_rhs) + frustum_lhs->yMin.d;
    if(t <= EGW_SFLT_EPSILON) {
        if(t >= -EGW_SFLT_EPSILON) bestRetVal = EGW_CLSNTEST_POINT_TOUCHES;
        else return EGW_CLSNTEST_POINT_NONE;
    }
    
    t = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMax.normal), point_rhs) + frustum_lhs->yMax.d;
    if(t <= EGW_SFLT_EPSILON) {
        if(t >= -EGW_SFLT_EPSILON) bestRetVal = EGW_CLSNTEST_POINT_TOUCHES;
        else return EGW_CLSNTEST_POINT_NONE;
    }
    
    t = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMin.normal), point_rhs) + frustum_lhs->zMin.d;
    if(t <= EGW_SFLT_EPSILON) {
        if(t >= -EGW_SFLT_EPSILON) bestRetVal = EGW_CLSNTEST_POINT_TOUCHES;
        else return EGW_CLSNTEST_POINT_NONE;
    }
    
    t = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMax.normal), point_rhs) + frustum_lhs->zMax.d;
    if(t <= EGW_SFLT_EPSILON) {
        if(t >= -EGW_SFLT_EPSILON) bestRetVal = EGW_CLSNTEST_POINT_TOUCHES;
        else return EGW_CLSNTEST_POINT_NONE;
    }
    
    return bestRetVal;
}

EGWint egwTestCollisionFrustumLinef(const egwFrustum4f* frustum_lhs, const egwLine4f* line_rhs, EGWsingle* begT_out, EGWsingle* endT_out) {
    egwVector3f orgMinOrg;
    EGWsingle tXm, tXM, tYm, tYM, tZm, tZM;
    
    // Determine plane intersection coefficients and check for range intersections.
    
    tXm = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMin.normal), (egwVector3f*)&(line_rhs->normal));
    if(!egwIsZerof(tXm)) {
        tXm = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMin.normal), egwVecSubtract3f((egwVector3f*)&(frustum_lhs->xMin.origin), (egwVector3f*)&(line_rhs->origin), &orgMinOrg)) / tXm;
    } else if(egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMin.normal), (egwVector3f*)&(line_rhs->origin)) + frustum_lhs->xMin.d >= -EGW_SFLT_EPSILON) {
        // Makes Xmin calculations not count against intersection
        tXm = -EGW_SFLT_MAX;
    } else
        return 0;
    
    tXM = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMax.normal), (egwVector3f*)&(line_rhs->normal));
    if(!egwIsZerof(tXM)) {
        tXM = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMax.normal), egwVecSubtract3f((egwVector3f*)&(frustum_lhs->xMax.origin), (egwVector3f*)&(line_rhs->origin), &orgMinOrg)) / tXM;
    } else if(egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMax.normal), (egwVector3f*)&(line_rhs->origin)) + frustum_lhs->xMax.d >= -EGW_SFLT_EPSILON) {
        // Makes Xmax calculations not count against intersection
        tXM = EGW_SFLT_MAX;
    } else
        return 0;
    
    tYm = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMin.normal), (egwVector3f*)&(line_rhs->normal));
    if(!egwIsZerof(tYm)) {
        tYm = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMin.normal), egwVecSubtract3f((egwVector3f*)&(frustum_lhs->yMin.origin), (egwVector3f*)&(line_rhs->origin), &orgMinOrg)) / tYm;
    } else if(egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMin.normal), (egwVector3f*)&(line_rhs->origin)) + frustum_lhs->yMin.d >= -EGW_SFLT_EPSILON) {
        // Makes Ymin calculations not count against intersection
        tYm = -EGW_SFLT_MAX;
    } else
        return 0;
    
    tYM = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMax.normal), (egwVector3f*)&(line_rhs->normal));
    if(!egwIsZerof(tYM)) {
        tYM = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMax.normal), egwVecSubtract3f((egwVector3f*)&(frustum_lhs->yMax.origin), (egwVector3f*)&(line_rhs->origin), &orgMinOrg)) / tYM;
    } else if(egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMax.normal), (egwVector3f*)&(line_rhs->origin)) + frustum_lhs->yMax.d >= -EGW_SFLT_EPSILON) {
        // Makes Ymax calculations not count against intersection
        tYM = EGW_SFLT_MAX;
    } else
        return 0;
    
    tZm = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMin.normal), (egwVector3f*)&(line_rhs->normal));
    if(!egwIsZerof(tZm)) {
        tZm = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMin.normal), egwVecSubtract3f((egwVector3f*)&(frustum_lhs->zMin.origin), (egwVector3f*)&(line_rhs->origin), &orgMinOrg)) / tZm;
    } else if(egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMin.normal), (egwVector3f*)&(line_rhs->origin)) + frustum_lhs->zMin.d >= -EGW_SFLT_EPSILON) {
        // Makes Zmin calculations not count against intersection
        tZm = -EGW_SFLT_MAX;
    } else
        return 0;
    
    tZM = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMax.normal), (egwVector3f*)&(line_rhs->normal));
    if(!egwIsZerof(tZM)) {
        tZM = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMax.normal), egwVecSubtract3f((egwVector3f*)&(frustum_lhs->zMax.origin), (egwVector3f*)&(line_rhs->origin), &orgMinOrg)) / tZM;
    } else if(egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMax.normal), (egwVector3f*)&(line_rhs->origin)) + frustum_lhs->zMax.d >= -EGW_SFLT_EPSILON) {
        // Makes Zmax calculations not count against intersection
        tZM = EGW_SFLT_MAX;
    } else
        return 0;
    
    // If T ranges overlap, then intersecting (mins always <= other maxes)
    if(tXm <= tYM + EGW_SFLT_EPSILON && tXm <= tZM + EGW_SFLT_EPSILON &&
       tYm <= tXM + EGW_SFLT_EPSILON && tYm <= tZM + EGW_SFLT_EPSILON &&
       tZm <= tXM + EGW_SFLT_EPSILON && tZm <= tYM + EGW_SFLT_EPSILON) {
        
        // The maximum minT and minimum maxT are the enter and exit positions
        if(begT_out) *begT_out = egwMax2f(tXm, egwMax2f(tYm, tZm));
        if(endT_out) *endT_out = egwMin2f(tXM, egwMin2f(tYM, tZM));
        
        if(tXm < tYM - EGW_SFLT_EPSILON && tXm < tZM - EGW_SFLT_EPSILON &&
           tYm < tXM - EGW_SFLT_EPSILON && tYm < tZM - EGW_SFLT_EPSILON &&
           tZm < tXM - EGW_SFLT_EPSILON && tZm < tYM - EGW_SFLT_EPSILON) {
            return EGW_CLSNTEST_LINE_INTERSECTS;
        }
        return EGW_CLSNTEST_LINE_TOUCHES;
    }
    return EGW_CLSNTEST_LINE_NONE;
}

EGWint egwTestCollisionFrustumPlanef(const egwFrustum4f* frustum_lhs, const egwPlane4f* plane_rhs, EGWint* side_out) {
    // TODO: egwTestCollisionFrustumPlanef.
    NSLog(@"egwTestCollisionFrustumPlanef: Error: This routine not currently implemented.");
    return EGW_CLSNTEST_PLANE_NA;
}

EGWint egwTestCollisionFrustumSpheref(const egwFrustum4f* frustum_lhs, const egwSphere4f* sphere_rhs) {
    EGWint numOutside, numInside;
    EGWsingle t;
    
    numOutside = numInside = 0;
    
    t = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMin.normal), (egwVector3f*)&(sphere_rhs->origin)) + frustum_lhs->xMin.d;
    if(t + sphere_rhs->radius >= -EGW_SFLT_EPSILON) {
        if(t + sphere_rhs->radius > EGW_SFLT_EPSILON) ++numInside;
        if(t - sphere_rhs->radius >= -EGW_SFLT_EPSILON) ++numInside;
        else ++numOutside;
    } else
        return EGW_CLSNTEST_BVOL_NONE;
    
    t = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMax.normal), (egwVector3f*)&(sphere_rhs->origin)) + frustum_lhs->xMax.d;
    if(t + sphere_rhs->radius >= -EGW_SFLT_EPSILON) {
        if(t + sphere_rhs->radius > EGW_SFLT_EPSILON) ++numInside;
        if(t - sphere_rhs->radius >= -EGW_SFLT_EPSILON) ++numInside;
        else ++numOutside;
    } else
        return EGW_CLSNTEST_BVOL_NONE;
    
    t = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMin.normal), (egwVector3f*)&(sphere_rhs->origin)) + frustum_lhs->yMin.d;
    if(t + sphere_rhs->radius >= -EGW_SFLT_EPSILON) {
        if(t + sphere_rhs->radius > EGW_SFLT_EPSILON) ++numInside;
        if(t - sphere_rhs->radius >= -EGW_SFLT_EPSILON) ++numInside;
        else ++numOutside;
    } else
        return EGW_CLSNTEST_BVOL_NONE;
    
    t = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMax.normal), (egwVector3f*)&(sphere_rhs->origin)) + frustum_lhs->yMax.d;
    if(t + sphere_rhs->radius >= -EGW_SFLT_EPSILON) {
        if(t + sphere_rhs->radius > EGW_SFLT_EPSILON) ++numInside;
        if(t - sphere_rhs->radius >= -EGW_SFLT_EPSILON) ++numInside;
        else ++numOutside;
    } else
        return EGW_CLSNTEST_BVOL_NONE;
    
    t = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMin.normal), (egwVector3f*)&(sphere_rhs->origin)) + frustum_lhs->zMin.d;
    if(t + sphere_rhs->radius >= -EGW_SFLT_EPSILON) {
        if(t + sphere_rhs->radius > EGW_SFLT_EPSILON) ++numInside;
        if(t - sphere_rhs->radius >= -EGW_SFLT_EPSILON) ++numInside;
        else ++numOutside;
    } else
        return EGW_CLSNTEST_BVOL_NONE;
    
    t = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMax.normal), (egwVector3f*)&(sphere_rhs->origin)) + frustum_lhs->zMax.d;
    if(t + sphere_rhs->radius >= -EGW_SFLT_EPSILON) {
        if(t + sphere_rhs->radius > EGW_SFLT_EPSILON) ++numInside;
        if(t - sphere_rhs->radius >= -EGW_SFLT_EPSILON) ++numInside;
        else ++numOutside;
    } else
        return EGW_CLSNTEST_BVOL_NONE;
    
    if(numOutside == 0 && numInside == 12)
        return EGW_CLSNTEST_BVOL_CONTAINS;
    if(numOutside == 6 && numInside == 6)
        return EGW_CLSNTEST_BVOL_CONTAINEDBY;
    if(numOutside > 0 && numInside >= 6)
        return EGW_CLSNTEST_BVOL_INTERSECTS;
    return EGW_CLSNTEST_BVOL_TOUCHES;
}

EGWint egwTestCollisionFrustumBoxf(const egwFrustum4f* frustum_lhs, const egwBox4f* box_rhs) {
    EGWint numOutside, numInside;
    EGWsingle t;
    egwVector3f edge;
    
    t = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMin.normal), egwVecInit3f(&edge, (frustum_lhs->xMin.normal.axis.x >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.x : box_rhs->min.axis.x), (frustum_lhs->xMin.normal.axis.y >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.y : box_rhs->min.axis.y), (frustum_lhs->xMin.normal.axis.z >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.z : box_rhs->min.axis.z))) + frustum_lhs->xMin.d;
    if(t >= -EGW_SFLT_EPSILON) {
        if(t > EGW_SFLT_EPSILON) ++numInside;
        t = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMin.normal), egwVecInit3f(&edge, (frustum_lhs->xMin.normal.axis.x >= -EGW_SFLT_EPSILON ? box_rhs->min.axis.x : box_rhs->max.axis.x), (frustum_lhs->xMin.normal.axis.y >= -EGW_SFLT_EPSILON ? box_rhs->min.axis.y : box_rhs->max.axis.y), (frustum_lhs->xMin.normal.axis.z >= -EGW_SFLT_EPSILON ? box_rhs->min.axis.z : box_rhs->max.axis.z))) + frustum_lhs->xMin.d;
        if(t >= -EGW_SFLT_EPSILON) ++numInside;
        else ++numOutside;
    } else
        return EGW_CLSNTEST_BVOL_NONE;
    
    t = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMax.normal), egwVecInit3f(&edge, (frustum_lhs->xMax.normal.axis.x >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.x : box_rhs->min.axis.x), (frustum_lhs->xMax.normal.axis.y >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.y : box_rhs->min.axis.y), (frustum_lhs->xMax.normal.axis.z >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.z : box_rhs->min.axis.z))) + frustum_lhs->xMax.d;
    if(t >= -EGW_SFLT_EPSILON) {
        if(t > EGW_SFLT_EPSILON) ++numInside;
        t = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->xMax.normal), egwVecInit3f(&edge, (frustum_lhs->xMax.normal.axis.x >= -EGW_SFLT_EPSILON ? box_rhs->min.axis.x : box_rhs->max.axis.x), (frustum_lhs->xMax.normal.axis.y >= -EGW_SFLT_EPSILON ? box_rhs->min.axis.y : box_rhs->max.axis.y), (frustum_lhs->xMax.normal.axis.z >= -EGW_SFLT_EPSILON ? box_rhs->min.axis.z : box_rhs->max.axis.z))) + frustum_lhs->xMax.d;
        if(t >= -EGW_SFLT_EPSILON) ++numInside;
        else ++numOutside;
    } else
        return EGW_CLSNTEST_BVOL_NONE;
    
    t = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMin.normal), egwVecInit3f(&edge, (frustum_lhs->yMin.normal.axis.x >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.x : box_rhs->min.axis.x), (frustum_lhs->yMin.normal.axis.y >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.y : box_rhs->min.axis.y), (frustum_lhs->yMin.normal.axis.z >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.z : box_rhs->min.axis.z))) + frustum_lhs->yMin.d;
    if(t >= -EGW_SFLT_EPSILON) {
        if(t > EGW_SFLT_EPSILON) ++numInside;
        t = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMin.normal), egwVecInit3f(&edge, (frustum_lhs->yMin.normal.axis.x >= -EGW_SFLT_EPSILON ? box_rhs->min.axis.x : box_rhs->max.axis.x), (frustum_lhs->yMin.normal.axis.y >= -EGW_SFLT_EPSILON ? box_rhs->min.axis.y : box_rhs->max.axis.y), (frustum_lhs->yMin.normal.axis.z >= -EGW_SFLT_EPSILON ? box_rhs->min.axis.z : box_rhs->max.axis.z))) + frustum_lhs->yMin.d;
        if(t >= -EGW_SFLT_EPSILON) ++numInside;
        else ++numOutside;
    } else
        return EGW_CLSNTEST_BVOL_NONE;
    
    t = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMax.normal), egwVecInit3f(&edge, (frustum_lhs->yMax.normal.axis.x >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.x : box_rhs->min.axis.x), (frustum_lhs->yMax.normal.axis.y >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.y : box_rhs->min.axis.y), (frustum_lhs->yMax.normal.axis.z >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.z : box_rhs->min.axis.z))) + frustum_lhs->yMax.d;
    if(t >= -EGW_SFLT_EPSILON) {
        if(t > EGW_SFLT_EPSILON) ++numInside;
        t = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->yMax.normal), egwVecInit3f(&edge, (frustum_lhs->yMax.normal.axis.x >= -EGW_SFLT_EPSILON ? box_rhs->min.axis.x : box_rhs->max.axis.x), (frustum_lhs->yMax.normal.axis.y >= -EGW_SFLT_EPSILON ? box_rhs->min.axis.y : box_rhs->max.axis.y), (frustum_lhs->yMax.normal.axis.z >= -EGW_SFLT_EPSILON ? box_rhs->min.axis.z : box_rhs->max.axis.z))) + frustum_lhs->yMax.d;
        if(t >= -EGW_SFLT_EPSILON) ++numInside;
        else ++numOutside;
    } else
        return EGW_CLSNTEST_BVOL_NONE;
    
    t = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMin.normal), egwVecInit3f(&edge, (frustum_lhs->zMin.normal.axis.x >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.x : box_rhs->min.axis.x), (frustum_lhs->zMin.normal.axis.y >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.y : box_rhs->min.axis.y), (frustum_lhs->zMin.normal.axis.z >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.z : box_rhs->min.axis.z))) + frustum_lhs->zMin.d;
    if(t >= -EGW_SFLT_EPSILON) {
        if(t > EGW_SFLT_EPSILON) ++numInside;
        t = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMin.normal), egwVecInit3f(&edge, (frustum_lhs->zMin.normal.axis.x >= -EGW_SFLT_EPSILON ? box_rhs->min.axis.x : box_rhs->max.axis.x), (frustum_lhs->zMin.normal.axis.y >= -EGW_SFLT_EPSILON ? box_rhs->min.axis.y : box_rhs->max.axis.y), (frustum_lhs->zMin.normal.axis.z >= -EGW_SFLT_EPSILON ? box_rhs->min.axis.z : box_rhs->max.axis.z))) + frustum_lhs->zMin.d;
        if(t >= -EGW_SFLT_EPSILON) ++numInside;
        else ++numOutside;
    } else
        return EGW_CLSNTEST_BVOL_NONE;
    
    t = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMax.normal), egwVecInit3f(&edge, (frustum_lhs->zMax.normal.axis.x >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.x : box_rhs->min.axis.x), (frustum_lhs->zMax.normal.axis.y >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.y : box_rhs->min.axis.y), (frustum_lhs->zMax.normal.axis.z >= -EGW_SFLT_EPSILON ? box_rhs->max.axis.z : box_rhs->min.axis.z))) + frustum_lhs->zMax.d;
    if(t >= -EGW_SFLT_EPSILON) {
        if(t > EGW_SFLT_EPSILON) ++numInside;
        t = egwVecDotProd3f((egwVector3f*)&(frustum_lhs->zMax.normal), egwVecInit3f(&edge, (frustum_lhs->zMax.normal.axis.x >= -EGW_SFLT_EPSILON ? box_rhs->min.axis.x : box_rhs->max.axis.x), (frustum_lhs->zMax.normal.axis.y >= -EGW_SFLT_EPSILON ? box_rhs->min.axis.y : box_rhs->max.axis.y), (frustum_lhs->zMax.normal.axis.z >= -EGW_SFLT_EPSILON ? box_rhs->min.axis.z : box_rhs->max.axis.z))) + frustum_lhs->zMax.d;
        if(t >= -EGW_SFLT_EPSILON) ++numInside;
        else ++numOutside;
    } else
        return EGW_CLSNTEST_BVOL_NONE;
    
    if(numOutside == 0 && numInside == 12)
        return EGW_CLSNTEST_BVOL_CONTAINS;
    if(numOutside == 6 && numInside == 6)
        return EGW_CLSNTEST_BVOL_CONTAINEDBY;
    if(numOutside > 0 && numInside >= 6)
        return EGW_CLSNTEST_BVOL_INTERSECTS;
    return EGW_CLSNTEST_BVOL_TOUCHES;
}

EGWint egwTestCollisionFrustumCylinderf(const egwFrustum4f* frustum_lhs, const egwCylinder4f* cylinder_rhs) {
    // TODO: egwTestCollisionFrustumCylinderf.
    NSLog(@"egwTestCollisionFrustumCylinderf: Error: This routine not currently implemented.");
    return EGW_CLSNTEST_BVOL_NA;
}

EGWint egwTestCollisionFrustumFrustumf(const egwFrustum4f* frustum_lhs, const egwFrustum4f* frustum_rhs) {
    // TODO: egwTestCollisionFrustumFrustumf.
    NSLog(@"egwTestCollisionFrustumFrustumf: Error: This routine not currently implemented.");
    return EGW_CLSNTEST_BVOL_NA;
}

EGWsingle egwLinePointClosestS3f(const egwLine3f* line_lhs, const egwVector2f* point_rhs) {
    // s = line.normal . (p - line.origin)
    egwVector2f diff;
    return egwVecDotProd2f((egwVector2f*)&line_lhs->normal, egwVecSubtract2f((egwVector2f*)point_rhs, (egwVector2f*)&line_lhs->origin, &diff));
}

EGWsingle egwLinePointClosestS4f(const egwLine4f* line_lhs, const egwVector3f* point_rhs) {
    egwVector3f diff;
    return egwVecDotProd3f((egwVector3f*)&line_lhs->normal, egwVecSubtract3f((egwVector3f*)point_rhs, (egwVector3f*)&line_lhs->origin, &diff));
}

EGWsingle egwLinePointClosestDist3f(const egwLine3f* line_lhs, const egwVector2f* point_rhs) {
    return egwSqrtf(egwLinePointClosestDistSqrd3f(line_lhs, point_rhs));
}

EGWsingle egwLinePointClosestDist4f(const egwLine4f* line_lhs, const egwVector3f* point_rhs) {
    return egwSqrtf(egwLinePointClosestDistSqrd4f(line_lhs, point_rhs));
}

EGWsingle egwLinePointClosestDistSqrd3f(const egwLine3f* line_lhs, const egwVector2f* point_rhs) {
    egwVector2f diff, pnt;
    return egwVecDotProd2f(&diff,
                           egwVecSubtract2f(&diff,
                                            egwVecUScale2f((egwVector2f*)&line_lhs->normal,
                                                           egwVecDotProd2f((egwVector2f*)&line_lhs->normal,
                                                                           egwVecSubtract2f((egwVector2f*)point_rhs, (egwVector2f*)&line_lhs->origin, &diff)),
                                                           &pnt),
                                            &diff));
}

EGWsingle egwLinePointClosestDistSqrd4f(const egwLine4f* line_lhs, const egwVector3f* point_rhs) {
    egwVector3f diff, pnt;
    return egwVecDotProd3f(&diff,
                           egwVecSubtract3f(&diff,
                                            egwVecUScale3f((egwVector3f*)&line_lhs->normal,
                                                           egwVecDotProd3f((egwVector3f*)&line_lhs->normal,
                                                                           egwVecSubtract3f((egwVector3f*)point_rhs, (egwVector3f*)&line_lhs->origin, &diff)),
                                                           &pnt),
                                            &diff));
}

EGWsingle egwLineLineClosestS3f(const egwLine3f* line_lhs, const egwLine3f* line_rhs) {
    // Pu lhs, Qv rhs,  w0 = P0-Q0
    // Then, letting a = u · u, b = u · v, c = v · v, d = u · w0, and e = v · w0, we solve for sc and tc as:
    // S = be-cd / ac - bb
    // T = ae-bd / ac - bb
    
    egwVector2f W; egwVecSubtract2f((egwVector2f*)&(line_lhs->origin), (egwVector2f*)&(line_rhs->origin), &W); // P-Q
    EGWsingle a = egwVecDotProd2f((egwVector2f*)&(line_lhs->normal), (egwVector2f*)&(line_lhs->normal)); // u.u
    EGWsingle b = egwVecDotProd2f((egwVector2f*)&(line_lhs->normal), (egwVector2f*)&(line_rhs->normal)); // u.v
    EGWsingle c = egwVecDotProd2f((egwVector2f*)&(line_rhs->normal), (egwVector2f*)&(line_rhs->normal)); // v.v
    EGWsingle d = egwVecDotProd2f((egwVector2f*)&(line_lhs->normal), &W); // u.W
    EGWsingle e = egwVecDotProd2f((egwVector2f*)&(line_rhs->normal), &W); // v.W
    
    return (((b * e) - (c * d)) / ((a * c) - (b * b)));
}

EGWsingle egwLineLineClosestS4f(const egwLine4f* line_lhs, const egwLine4f* line_rhs) {
    egwVector3f W; egwVecSubtract3f((egwVector3f*)&(line_lhs->origin), (egwVector3f*)&(line_rhs->origin), &W); // P-Q
    EGWsingle a = egwVecDotProd3f((egwVector3f*)&(line_lhs->normal), (egwVector3f*)&(line_lhs->normal)); // u.u
    EGWsingle b = egwVecDotProd3f((egwVector3f*)&(line_lhs->normal), (egwVector3f*)&(line_rhs->normal)); // u.v
    EGWsingle c = egwVecDotProd3f((egwVector3f*)&(line_rhs->normal), (egwVector3f*)&(line_rhs->normal)); // v.v
    EGWsingle d = egwVecDotProd3f((egwVector3f*)&(line_lhs->normal), &W); // u.W
    EGWsingle e = egwVecDotProd3f((egwVector3f*)&(line_rhs->normal), &W); // v.W
    
    return (((b * e) - (c * d)) / ((a * c) - (b * b)));
}

void egwLineLineClosestST3f(const egwLine3f* line_lhs, const egwLine3f* line_rhs, EGWsingle* s_out, EGWsingle* t_out) {
    egwVector2f W; egwVecSubtract2f((egwVector2f*)&(line_lhs->origin), (egwVector2f*)&(line_rhs->origin), &W); // P-Q
    EGWsingle a = egwVecDotProd2f((egwVector2f*)&(line_lhs->normal), (egwVector2f*)&(line_lhs->normal)); // u.u
    EGWsingle b = egwVecDotProd2f((egwVector2f*)&(line_lhs->normal), (egwVector2f*)&(line_rhs->normal)); // u.v
    EGWsingle c = egwVecDotProd2f((egwVector2f*)&(line_rhs->normal), (egwVector2f*)&(line_rhs->normal)); // v.v
    EGWsingle d = egwVecDotProd2f((egwVector2f*)&(line_lhs->normal), &W); // u.W
    EGWsingle e = egwVecDotProd2f((egwVector2f*)&(line_rhs->normal), &W); // v.W
    EGWsingle denom = ((a * c) - (b * b));
    
    if(s_out) *s_out = (((b * e) - (c * d)) / denom);
    if(t_out) *t_out = (((a * e) - (b * d)) / denom);
}

void egwLineLineClosestST4f(const egwLine4f* line_lhs, const egwLine4f* line_rhs, EGWsingle* s_out, EGWsingle* t_out) {
    egwVector3f W; egwVecSubtract3f((egwVector3f*)&(line_lhs->origin), (egwVector3f*)&(line_rhs->origin), &W); // P-Q
    EGWsingle a = egwVecDotProd3f((egwVector3f*)&(line_lhs->normal), (egwVector3f*)&(line_lhs->normal)); // u.u
    EGWsingle b = egwVecDotProd3f((egwVector3f*)&(line_lhs->normal), (egwVector3f*)&(line_rhs->normal)); // u.v
    EGWsingle c = egwVecDotProd3f((egwVector3f*)&(line_rhs->normal), (egwVector3f*)&(line_rhs->normal)); // v.v
    EGWsingle d = egwVecDotProd3f((egwVector3f*)&(line_lhs->normal), &W); // u.W
    EGWsingle e = egwVecDotProd3f((egwVector3f*)&(line_rhs->normal), &W); // v.W
    EGWsingle denom = ((a * c) - (b * b));
    
    if(s_out) *s_out = (((b * e) - (c * d)) / denom);
    if(t_out) *t_out = (((a * e) - (b * d)) / denom);
}

EGWsingle egwLineLineClosestDist3f(const egwLine3f* line_lhs, const egwLine3f* line_rhs) {
    return egwSqrtf(egwLineLineClosestDistSqrd3f(line_lhs, line_rhs));
}

EGWsingle egwLineLineClosestDist4f(const egwLine4f* line_lhs, const egwLine4f* line_rhs) {
    return egwSqrtf(egwLineLineClosestDistSqrd4f(line_lhs, line_rhs));
}

EGWsingle egwLineLineClosestDistSqrd3f(const egwLine3f* line_lhs, const egwLine3f* line_rhs) {
    EGWsingle s, t;
    egwVector2f Ps, Qt;
    
    egwLineLineClosestST3f(line_lhs, line_rhs, &s, &t);
    
    egwVecAdd2f((egwVector2f*)&(line_lhs->origin), egwVecUScale2f((egwVector2f*)&(line_lhs->normal), s, &Ps), &Ps);
    egwVecAdd2f((egwVector2f*)&(line_rhs->origin), egwVecUScale2f((egwVector2f*)&(line_rhs->normal), t, &Qt), &Qt);
    
    return egwVecDistanceSqrd2f(&Ps, &Qt);
}

EGWsingle egwLineLineClosestDistSqrd4f(const egwLine4f* line_lhs, const egwLine4f* line_rhs) {
    EGWsingle s, t;
    egwVector3f Ps, Qt;
    
    egwLineLineClosestST4f(line_lhs, line_rhs, &s, &t);
    
    egwVecAdd3f((egwVector3f*)&(line_lhs->origin), egwVecUScale3f((egwVector3f*)&(line_lhs->normal), s, &Ps), &Ps);
    egwVecAdd3f((egwVector3f*)&(line_rhs->origin), egwVecUScale3f((egwVector3f*)&(line_rhs->normal), t, &Qt), &Qt);
    
    return egwVecDistanceSqrd3f(&Ps, &Qt);
}

egwLine3f* egwLineTransform333f(const egwMatrix33f* mat_lhs, const egwLine3f* line_rhs, egwLine3f* line_out) {
    egwVecTransform333f(mat_lhs, &(line_rhs->origin), &(line_out->origin));
    egwVecTransform333f(mat_lhs, &(line_rhs->normal), &(line_out->normal));
    return line_out;
}

egwLine4f* egwLineTransform444f(const egwMatrix44f* mat_lhs, const egwLine4f* line_rhs, egwLine4f* line_out) {
    egwVecTransform444f(mat_lhs, &(line_rhs->origin), &(line_out->origin));
    egwVecTransform444f(mat_lhs, &(line_rhs->normal), &(line_out->normal));
    return line_out;
}

egwVector2f* egwPlanePointPointClosest3f(const egwPlane3f* plane_lhs, const egwVector2f* point_rhs, egwVector2f* point_out) {
    egwVector2f temp;
    
    return egwVecSubtract2f(point_rhs,
                            egwVecUScale2f((egwVector2f*)&plane_lhs->normal,
                                           egwVecDotProd2f((egwVector2f*)&plane_lhs->normal, egwVecSubtract2f(point_rhs, (egwVector2f*)&plane_lhs->origin, &temp)),
                                           &temp),
                            point_out);
}

egwVector3f* egwPlanePointPointClosest4f(const egwPlane4f* plane_lhs, const egwVector3f* point_rhs, egwVector3f* point_out) {
    egwVector3f temp;
    
    return egwVecSubtract3f(point_rhs,
                            egwVecUScale3f((egwVector3f*)&plane_lhs->normal,
                                           egwVecDotProd3f((egwVector3f*)&plane_lhs->normal, egwVecSubtract3f(point_rhs, (egwVector3f*)&plane_lhs->origin, &temp)),
                                           &temp),
                            point_out);
    
}

EGWsingle egwPlanePointClosestDist3f(const egwPlane3f* plane_lhs, const egwVector2f* point_rhs) {
    egwVector2f temp;
    return egwVecDotProd2f((egwVector2f*)&plane_lhs->normal, egwVecSubtract2f(point_rhs, (egwVector2f*)&plane_lhs->origin, &temp));
}

EGWsingle egwPlanePointClosestDist4f(const egwPlane4f* plane_lhs, const egwVector3f* point_rhs) {
    egwVector3f temp;
    return egwVecDotProd3f((egwVector3f*)&plane_lhs->normal, egwVecSubtract3f(point_rhs, (egwVector3f*)&plane_lhs->origin, &temp));
}

EGWsingle egwPlaneLineClosestS3f(const egwPlane3f* plane_lhs, const egwLine3f* line_rhs) {
    EGWsingle denom = egwVecDotProd2f((egwVector2f*)&plane_lhs->normal, (egwVector2f*)&line_rhs->normal);
    
    if(!egwIsZerof(denom)) {
        egwVector2f temp;
        return (egwVecDotProd2f((egwVector2f*)&plane_lhs->normal,
                                egwVecSubtract2f((egwVector2f*)&plane_lhs->origin,
                                                 (egwVector2f*)&line_rhs->origin, &temp)) + plane_lhs->d) / denom;
    }
    
    return EGW_SFLT_NAN;
}

EGWsingle egwPlaneLineClosestS4f(const egwPlane4f* plane_lhs, const egwLine4f* line_rhs) {
    EGWsingle denom = egwVecDotProd3f((egwVector3f*)&plane_lhs->normal, (egwVector3f*)&line_rhs->normal);
    
    if(!egwIsZerof(denom)) {
        egwVector3f temp;
        return (egwVecDotProd3f((egwVector3f*)&plane_lhs->normal,
                               egwVecSubtract3f((egwVector3f*)&plane_lhs->origin,
                                                (egwVector3f*)&line_rhs->origin, &temp)) + plane_lhs->d) / denom;
    }
    
    return EGW_SFLT_NAN;
}

egwPlane3f* egwPlaneTransform333f(const egwMatrix33f* mat_lhs, const egwPlane3f* plane_rhs, egwPlane3f* plane_out) {
    egwVecTransform333f(mat_lhs, &plane_rhs->normal, &plane_out->normal);
    egwVecTransform333f(mat_lhs, &plane_rhs->origin, &plane_out->origin);
    plane_out->d = -egwVecDotProd2f((egwVector2f*)&plane_out->normal, (egwVector2f*)&plane_out->origin);
    return plane_out;
}

egwPlane4f* egwPlaneTransform444f(const egwMatrix44f* mat_lhs, const egwPlane4f* plane_rhs, egwPlane4f* plane_out) {
    egwVecTransform444f(mat_lhs, &plane_rhs->normal, &plane_out->normal);
    egwVecTransform444f(mat_lhs, &plane_rhs->origin, &plane_out->origin);
    plane_out->d = -egwVecDotProd3f((egwVector3f*)&plane_out->normal, (egwVector3f*)&plane_out->origin);
    return plane_out;
}

egwSTVAMeshf* egwMeshAllocSTVAf(egwSTVAMeshf* mesh_out, EGWuint16 verticesC_in, EGWuint16 normalsC_in, EGWuint16 texuvsC_in) {
    memset((void*)mesh_out, 0, sizeof(egwSTVAMeshf));
    
    mesh_out->vCount = (verticesC_in > 0 ? verticesC_in : (normalsC_in > 0 ? normalsC_in : (texuvsC_in > 0 ? texuvsC_in : 0)));
    
    if(mesh_out->vCount) {
        if(verticesC_in && !(mesh_out->vCoords = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)(mesh_out->vCount)))) { egwMeshFreeSTVAf(mesh_out); return NULL; }
        if(normalsC_in && !(mesh_out->nCoords = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)(mesh_out->vCount)))) { egwMeshFreeSTVAf(mesh_out); return NULL; }
        if(texuvsC_in && !(mesh_out->tCoords = (egwVector2f*)malloc(sizeof(egwVector2f) * (size_t)(mesh_out->vCount)))) { egwMeshFreeSTVAf(mesh_out); return NULL; }
    } else { egwMeshFreeSTVAf(mesh_out); return NULL; }
    
    return mesh_out;
}

egwSJITVAMeshf* egwMeshAllocSJITVAf(egwSJITVAMeshf* mesh_out, EGWuint16 verticesC_in, EGWuint16 normalsC_in, EGWuint16 texuvsC_in, EGWuint16 facesC_in) {
    memset((void*)mesh_out, 0, sizeof(egwSJITVAMeshf));
    
    mesh_out->vCount = (verticesC_in > 0 ? verticesC_in : (normalsC_in > 0 ? normalsC_in : (texuvsC_in > 0 ? texuvsC_in : 0)));
    mesh_out->fCount = facesC_in;
    
    if(mesh_out->vCount && mesh_out->fCount && !(mesh_out->vCount > 3 * mesh_out->fCount)) {
        if(verticesC_in && !(mesh_out->vCoords = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)(mesh_out->vCount)))) { egwMeshFreeSJITVAf(mesh_out); return NULL; }
        if(normalsC_in && !(mesh_out->nCoords = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)(mesh_out->vCount)))) { egwMeshFreeSJITVAf(mesh_out); return NULL; }
        if(texuvsC_in && !(mesh_out->tCoords = (egwVector2f*)malloc(sizeof(egwVector2f) * (size_t)(mesh_out->vCount)))) { egwMeshFreeSJITVAf(mesh_out); return NULL; }
        if(!(mesh_out->fIndicies = (egwJITFace*)malloc(sizeof(egwJITFace) * (size_t)(mesh_out->fCount)))) { egwMeshFreeSJITVAf(mesh_out); return NULL; }
    } else { egwMeshFreeSJITVAf(mesh_out); return NULL; }
    
    return mesh_out;
}

egwSDITVAMeshf* egwMeshAllocSDITVAf(egwSDITVAMeshf* mesh_out, EGWuint16 verticesC_in, EGWuint16 normalsC_in, EGWuint16 texuvsC_in, EGWuint16 facesC_in) {
    memset((void*)mesh_out, 0, sizeof(egwSDITVAMeshf));
    
    mesh_out->vCount = verticesC_in;
    mesh_out->nCount = normalsC_in;
    mesh_out->tCount = texuvsC_in;
    mesh_out->fCount = facesC_in;
    
    if(mesh_out->vCount && mesh_out->fCount && !(mesh_out->vCount > 3 * mesh_out->fCount)) {
        if(verticesC_in && !(mesh_out->vCoords = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)(mesh_out->vCount)))) { egwMeshFreeSDITVAf(mesh_out); return NULL; }
        if(normalsC_in && !(mesh_out->nCoords = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)(mesh_out->nCount)))) { egwMeshFreeSDITVAf(mesh_out); return NULL; }
        if(texuvsC_in && !(mesh_out->tCoords = (egwVector2f*)malloc(sizeof(egwVector2f) * (size_t)(mesh_out->tCount)))) { egwMeshFreeSDITVAf(mesh_out); return NULL; }
        if(!(mesh_out->fIndicies = (egwDITFace*)malloc(sizeof(egwDITFace) * (size_t)(mesh_out->fCount)))) { egwMeshFreeSDITVAf(mesh_out); return NULL; }
    } else { egwMeshFreeSDITVAf(mesh_out); return NULL; }
    
    return mesh_out;
}

egwKFTVAMeshf* egwMeshAllocKFTVAf(egwKFTVAMeshf* mesh_out, EGWuint16 verticesC_in, EGWuint16 normalsC_in, EGWuint16 texuvsC_in, EGWuint16 vertFramesC_in, EGWuint16 nrmlFramesC_in, EGWuint16 txuvFramesC_in) {
    memset((void*)mesh_out, 0, sizeof(egwKFTVAMeshf));
    
    mesh_out->vCount = (verticesC_in > 0 ? verticesC_in : (normalsC_in > 0 ? normalsC_in : (texuvsC_in > 0 ? texuvsC_in : 0)));
    mesh_out->vfCount = vertFramesC_in;
    mesh_out->nfCount = nrmlFramesC_in;
    mesh_out->tfCount = txuvFramesC_in;
    
    if(mesh_out->vCount && (mesh_out->vfCount >= 1 || mesh_out->nfCount >= 1 || mesh_out->tfCount >= 1)) {
        if(verticesC_in && !(mesh_out->vkCoords = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)(mesh_out->vCount) * (size_t)(mesh_out->vfCount ? mesh_out->vfCount : 1)))) { egwMeshFreeKFTVAf(mesh_out); return NULL; }
        if(normalsC_in && !(mesh_out->nkCoords = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)(mesh_out->vCount) * (size_t)(mesh_out->nfCount ? mesh_out->nfCount : 1)))) { egwMeshFreeKFTVAf(mesh_out); return NULL; }
        if(texuvsC_in && !(mesh_out->tkCoords = (egwVector2f*)malloc(sizeof(egwVector2f) * (size_t)(mesh_out->vCount) * (size_t)(mesh_out->tfCount ? mesh_out->tfCount : 1)))) { egwMeshFreeKFTVAf(mesh_out); return NULL; }
        if(verticesC_in && vertFramesC_in && !(mesh_out->vtIndicies = (EGWtime*)malloc((sizeof(EGWtime) * (size_t)(mesh_out->vfCount))))) { egwMeshFreeKFTVAf(mesh_out); return NULL; }
        if(normalsC_in && nrmlFramesC_in && !(mesh_out->ntIndicies = (EGWtime*)malloc((sizeof(EGWtime) * (size_t)(mesh_out->nfCount))))) { egwMeshFreeKFTVAf(mesh_out); return NULL; }
        if(verticesC_in && txuvFramesC_in && !(mesh_out->ttIndicies = (EGWtime*)malloc((sizeof(EGWtime) * (size_t)(mesh_out->tfCount))))) { egwMeshFreeKFTVAf(mesh_out); return NULL; }
    } else { egwMeshFreeKFTVAf(mesh_out); return NULL; }
    
    return mesh_out;
}

egwKFJITVAMeshf* egwMeshAllocKFJITVAf(egwKFJITVAMeshf* mesh_out, EGWuint16 verticesC_in, EGWuint16 normalsC_in, EGWuint16 texuvsC_in, EGWuint16 facesC_in, EGWuint16 vertFramesC_in, EGWuint16 nrmlFramesC_in, EGWuint16 txuvFramesC_in) {
    memset((void*)mesh_out, 0, sizeof(egwKFJITVAMeshf));
    
    mesh_out->vCount = (verticesC_in > 0 ? verticesC_in : (normalsC_in > 0 ? normalsC_in : (texuvsC_in > 0 ? texuvsC_in : 0)));
    mesh_out->fCount = facesC_in;
    mesh_out->vfCount = vertFramesC_in;
    mesh_out->nfCount = nrmlFramesC_in;
    mesh_out->tfCount = txuvFramesC_in;
    
    if(mesh_out->vCount && mesh_out->fCount && !(mesh_out->vCount > 3 * mesh_out->fCount) && (mesh_out->vfCount >= 1 || mesh_out->nfCount >= 1 || mesh_out->tfCount >= 1)) {
        if(verticesC_in && !(mesh_out->vkCoords = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)(mesh_out->vCount) * (size_t)(mesh_out->vfCount ? mesh_out->vfCount : 1)))) { egwMeshFreeKFJITVAf(mesh_out); return NULL; }
        if(normalsC_in && !(mesh_out->nkCoords = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)(mesh_out->vCount) * (size_t)(mesh_out->nfCount ? mesh_out->nfCount : 1)))) { egwMeshFreeKFJITVAf(mesh_out); return NULL; }
        if(texuvsC_in && !(mesh_out->tkCoords = (egwVector2f*)malloc(sizeof(egwVector2f) * (size_t)(mesh_out->vCount) * (size_t)(mesh_out->tfCount ? mesh_out->tfCount : 1)))) { egwMeshFreeKFJITVAf(mesh_out); return NULL; }
        if(!(mesh_out->fIndicies = (egwJITFace*)malloc(sizeof(egwJITFace) * (size_t)(mesh_out->fCount)))) { egwMeshFreeKFJITVAf(mesh_out); return NULL; }
        if(verticesC_in && vertFramesC_in && !(mesh_out->vtIndicies = (EGWtime*)malloc((sizeof(EGWtime) * (size_t)(mesh_out->vfCount))))) { egwMeshFreeKFJITVAf(mesh_out); return NULL; }
        if(normalsC_in && nrmlFramesC_in && !(mesh_out->ntIndicies = (EGWtime*)malloc((sizeof(EGWtime) * (size_t)(mesh_out->nfCount))))) { egwMeshFreeKFJITVAf(mesh_out); return NULL; }
        if(verticesC_in && txuvFramesC_in && !(mesh_out->ttIndicies = (EGWtime*)malloc((sizeof(EGWtime) * (size_t)(mesh_out->tfCount))))) { egwMeshFreeKFJITVAf(mesh_out); return NULL; }
    } else { egwMeshFreeKFJITVAf(mesh_out); return NULL; }
    
    return mesh_out;
}

egwKFDITVAMeshf* egwMeshAllocKFDITVAf(egwKFDITVAMeshf* mesh_out, EGWuint16 verticesC_in, EGWuint16 normalsC_in, EGWuint16 texuvsC_in, EGWuint16 facesC_in, EGWuint16 vertFramesC_in, EGWuint16 nrmlFramesC_in, EGWuint16 txuvFramesC_in) {
    memset((void*)mesh_out, 0, sizeof(egwKFDITVAMeshf));
    
    mesh_out->vCount = verticesC_in;
    mesh_out->nCount = normalsC_in;
    mesh_out->tCount = texuvsC_in;
    mesh_out->fCount = facesC_in;
    mesh_out->vfCount = vertFramesC_in;
    mesh_out->nfCount = nrmlFramesC_in;
    mesh_out->tfCount = txuvFramesC_in;
    
    if(mesh_out->vCount && mesh_out->fCount && !(mesh_out->vCount > 3 * mesh_out->fCount) && (mesh_out->vfCount >= 1 || mesh_out->nfCount >= 1 || mesh_out->tfCount >= 1)) {
        if(verticesC_in && !(mesh_out->vkCoords = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)(mesh_out->vCount) * (size_t)(mesh_out->vfCount ? mesh_out->vfCount : 1)))) { egwMeshFreeKFDITVAf(mesh_out); return NULL; }
        if(normalsC_in && !(mesh_out->nkCoords = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)(mesh_out->nCount) * (size_t)(mesh_out->nfCount ? mesh_out->nfCount : 1)))) { egwMeshFreeKFDITVAf(mesh_out); return NULL; }
        if(texuvsC_in && !(mesh_out->tkCoords = (egwVector2f*)malloc(sizeof(egwVector2f) * (size_t)(mesh_out->tCount) * (size_t)(mesh_out->tfCount ? mesh_out->tfCount : 1)))) { egwMeshFreeKFDITVAf(mesh_out); return NULL; }
        if(!(mesh_out->fIndicies = (egwDITFace*)malloc(sizeof(egwDITFace) * (size_t)(mesh_out->fCount)))) { egwMeshFreeKFDITVAf(mesh_out); return NULL; }
        if(verticesC_in && vertFramesC_in && !(mesh_out->vtIndicies = (EGWtime*)malloc((sizeof(EGWtime) * (size_t)(mesh_out->vfCount))))) { egwMeshFreeKFDITVAf(mesh_out); return NULL; }
        if(normalsC_in && nrmlFramesC_in && !(mesh_out->ntIndicies = (EGWtime*)malloc((sizeof(EGWtime) * (size_t)(mesh_out->nfCount))))) { egwMeshFreeKFDITVAf(mesh_out); return NULL; }
        if(verticesC_in && txuvFramesC_in && !(mesh_out->ttIndicies = (EGWtime*)malloc((sizeof(EGWtime) * (size_t)(mesh_out->tfCount))))) { egwMeshFreeKFDITVAf(mesh_out); return NULL; }
    } else { egwMeshFreeKFDITVAf(mesh_out); return NULL; }
    
    return mesh_out;
}

egwSTVAMeshf* egwMeshFreeSTVAf(egwSTVAMeshf* mesh_inout) {
    mesh_inout->vCount = 0;
    if(mesh_inout->vCoords) { free((void*)mesh_inout->vCoords); mesh_inout->vCoords = NULL; }
    if(mesh_inout->nCoords) { free((void*)mesh_inout->nCoords); mesh_inout->nCoords = NULL; }
    if(mesh_inout->tCoords) { free((void*)mesh_inout->tCoords); mesh_inout->tCoords = NULL; }
    return mesh_inout;
}

egwSJITVAMeshf* egwMeshFreeSJITVAf(egwSJITVAMeshf* mesh_inout) {
    mesh_inout->vCount = 0;
    if(mesh_inout->vCoords) { free((void*)mesh_inout->vCoords); mesh_inout->vCoords = NULL; }
    if(mesh_inout->nCoords) { free((void*)mesh_inout->nCoords); mesh_inout->nCoords = NULL; }
    if(mesh_inout->tCoords) { free((void*)mesh_inout->tCoords); mesh_inout->tCoords = NULL; }
    mesh_inout->fCount = 0;
    if(mesh_inout->fIndicies) { free((void*)mesh_inout->fIndicies); mesh_inout->fIndicies = NULL; }
    return mesh_inout;
}

egwSDITVAMeshf* egwMeshFreeSDITVAf(egwSDITVAMeshf* mesh_inout) {
    mesh_inout->vCount = 0;
    if(mesh_inout->vCoords) { free((void*)mesh_inout->vCoords); mesh_inout->vCoords = NULL; }
    mesh_inout->nCount = 0;
    if(mesh_inout->nCoords) { free((void*)mesh_inout->nCoords); mesh_inout->nCoords = NULL; }
    mesh_inout->tCount = 0;
    if(mesh_inout->tCoords) { free((void*)mesh_inout->tCoords); mesh_inout->tCoords = NULL; }
    mesh_inout->fCount = 0;
    if(mesh_inout->fIndicies) { free((void*)mesh_inout->fIndicies); mesh_inout->fIndicies = NULL; }
    return mesh_inout;
}

egwKFTVAMeshf* egwMeshFreeKFTVAf(egwKFTVAMeshf* mesh_inout) {
    mesh_inout->vCount = 0;
    if(mesh_inout->vkCoords) { free((void*)mesh_inout->vkCoords); mesh_inout->vkCoords = NULL; }
    if(mesh_inout->nkCoords) { free((void*)mesh_inout->nkCoords); mesh_inout->nkCoords = NULL; }
    if(mesh_inout->tkCoords) { free((void*)mesh_inout->tkCoords); mesh_inout->tkCoords = NULL; }
    mesh_inout->vfCount = mesh_inout->nfCount = mesh_inout->tfCount = 0;
    if(mesh_inout->vtIndicies && mesh_inout->vtIndicies != mesh_inout->ntIndicies && mesh_inout->vtIndicies != mesh_inout->ttIndicies) {
        free((void*)mesh_inout->vtIndicies); mesh_inout->vtIndicies = NULL;
    } else mesh_inout->vtIndicies = NULL;
    if(mesh_inout->ntIndicies && mesh_inout->ntIndicies != mesh_inout->ttIndicies) {
        free((void*)mesh_inout->ntIndicies); mesh_inout->ntIndicies = NULL;
    } else mesh_inout->ntIndicies = NULL;
    if(mesh_inout->ttIndicies) { free((void*)mesh_inout->ttIndicies); mesh_inout->ttIndicies = NULL; }
    if(mesh_inout->vkfExtraDat) { free((void*)mesh_inout->vkfExtraDat); mesh_inout->vkfExtraDat = NULL; }
    if(mesh_inout->nkfExtraDat) { free((void*)mesh_inout->nkfExtraDat); mesh_inout->nkfExtraDat = NULL; }
    if(mesh_inout->tkfExtraDat) { free((void*)mesh_inout->tkfExtraDat); mesh_inout->tkfExtraDat = NULL; }
    return mesh_inout;
}

egwKFJITVAMeshf* egwMeshFreeKFJITVAf(egwKFJITVAMeshf* mesh_inout) {
    mesh_inout->vCount = 0;
    if(mesh_inout->vkCoords) { free((void*)mesh_inout->vkCoords); mesh_inout->vkCoords = NULL; }
    if(mesh_inout->nkCoords) { free((void*)mesh_inout->nkCoords); mesh_inout->nkCoords = NULL; }
    if(mesh_inout->tkCoords) { free((void*)mesh_inout->tkCoords); mesh_inout->tkCoords = NULL; }
    mesh_inout->fCount = 0;
    if(mesh_inout->fIndicies) { free((void*)mesh_inout->fIndicies); mesh_inout->fIndicies = NULL; }
    mesh_inout->vfCount = mesh_inout->nfCount = mesh_inout->tfCount = 0;
    if(mesh_inout->vtIndicies && mesh_inout->vtIndicies != mesh_inout->ntIndicies && mesh_inout->vtIndicies != mesh_inout->ttIndicies) {
        free((void*)mesh_inout->vtIndicies); mesh_inout->vtIndicies = NULL;
    } else mesh_inout->vtIndicies = NULL;
    if(mesh_inout->ntIndicies && mesh_inout->ntIndicies != mesh_inout->ttIndicies) {
        free((void*)mesh_inout->ntIndicies); mesh_inout->ntIndicies = NULL;
    } else mesh_inout->ntIndicies = NULL;
    if(mesh_inout->ttIndicies) { free((void*)mesh_inout->ttIndicies); mesh_inout->ttIndicies = NULL; }
    if(mesh_inout->vkfExtraDat) { free((void*)mesh_inout->vkfExtraDat); mesh_inout->vkfExtraDat = NULL; }
    if(mesh_inout->nkfExtraDat) { free((void*)mesh_inout->nkfExtraDat); mesh_inout->nkfExtraDat = NULL; }
    if(mesh_inout->tkfExtraDat) { free((void*)mesh_inout->tkfExtraDat); mesh_inout->tkfExtraDat = NULL; }
    return mesh_inout;
}

egwKFDITVAMeshf* egwMeshFreeKFDITVAf(egwKFDITVAMeshf* mesh_inout) {
    mesh_inout->vCount = 0;
    if(mesh_inout->vkCoords) { free((void*)mesh_inout->vkCoords); mesh_inout->vkCoords = NULL; }
    mesh_inout->nCount = 0;
    if(mesh_inout->nkCoords) { free((void*)mesh_inout->nkCoords); mesh_inout->nkCoords = NULL; }
    mesh_inout->tCount = 0;
    if(mesh_inout->tkCoords) { free((void*)mesh_inout->tkCoords); mesh_inout->tkCoords = NULL; }
    mesh_inout->fCount = 0;
    if(mesh_inout->fIndicies) { free((void*)mesh_inout->fIndicies); mesh_inout->fIndicies = NULL; }
    mesh_inout->vfCount = mesh_inout->nfCount = mesh_inout->tfCount = 0;
    if(mesh_inout->vtIndicies && mesh_inout->vtIndicies != mesh_inout->ntIndicies && mesh_inout->vtIndicies != mesh_inout->ttIndicies) {
        free((void*)mesh_inout->vtIndicies); mesh_inout->vtIndicies = NULL;
    } else mesh_inout->vtIndicies = NULL;
    if(mesh_inout->ntIndicies && mesh_inout->ntIndicies != mesh_inout->ttIndicies) {
        free((void*)mesh_inout->ntIndicies); mesh_inout->ntIndicies = NULL;
    } else mesh_inout->ntIndicies = NULL;
    if(mesh_inout->ttIndicies) { free((void*)mesh_inout->ttIndicies); mesh_inout->ttIndicies = NULL; }
    if(mesh_inout->vkfExtraDat) { free((void*)mesh_inout->vkfExtraDat); mesh_inout->vkfExtraDat = NULL; }
    if(mesh_inout->nkfExtraDat) { free((void*)mesh_inout->nkfExtraDat); mesh_inout->nkfExtraDat = NULL; }
    if(mesh_inout->tkfExtraDat) { free((void*)mesh_inout->tkfExtraDat); mesh_inout->tkfExtraDat = NULL; }
    return mesh_inout;
}

egwSJITVAMeshf* egwMeshConvertSTVAfSJITVAf(const egwSTVAMeshf* mesh_in, egwSJITVAMeshf* mesh_out) {
    EGWint vertexIndex, scanIndex;
    EGWuint foundFlags;
    EGWuint vCount = (mesh_in->vCoords || mesh_in->nCoords || mesh_in->tCoords ? mesh_in->vCount : 0);
    
    if(vCount) {
        for(vertexIndex = 1; vertexIndex < mesh_in->vCount; ++vertexIndex) {
            foundFlags = (vCount ? 7 : 0);
            
            for(scanIndex = vertexIndex - 1; scanIndex >= 0 && foundFlags; --scanIndex) {
                if((foundFlags & 7) && (!(mesh_in->vCoords) || egwVecIsEqual3f(&(mesh_in->vCoords[vertexIndex]), &(mesh_in->vCoords[scanIndex])))
                   && (!(mesh_in->nCoords) || egwVecIsEqual3f(&(mesh_in->nCoords[vertexIndex]), &(mesh_in->nCoords[scanIndex])))
                   && (!(mesh_in->tCoords) || egwVecIsEqual2f(&(mesh_in->tCoords[vertexIndex]), &(mesh_in->tCoords[scanIndex])))) { --vCount; foundFlags = foundFlags & ~7; }
            }
        }
        
        if(egwMeshAllocSJITVAf(mesh_out, (mesh_in->vCoords ? vCount : 0), (mesh_in->nCoords ? vCount : 0), (mesh_in->tCoords ? vCount : 0), (mesh_in->vCount / 3))) {
            EGWint faceIndex;
            vCount = 0;
            
            for(faceIndex = 0, vertexIndex = 0; faceIndex < mesh_out->fCount && vertexIndex < mesh_in->vCount; ++faceIndex, vertexIndex += 3) {
                foundFlags = 0x007;
                for(scanIndex = 0; scanIndex < vCount && foundFlags; ++scanIndex) {
                    if((foundFlags & 0x007) && (!(mesh_in->vCoords && mesh_out->vCoords) || egwVecIsEqual3f(&(mesh_in->vCoords[vertexIndex+0]), &(mesh_out->vCoords[scanIndex])))
                       && (!(mesh_in->nCoords && mesh_out->nCoords) || egwVecIsEqual3f(&(mesh_in->nCoords[vertexIndex+0]), &(mesh_out->nCoords[scanIndex])))
                       && (!(mesh_in->tCoords && mesh_out->tCoords) || egwVecIsEqual2f(&(mesh_in->tCoords[vertexIndex+0]), &(mesh_out->tCoords[scanIndex])))) { mesh_out->fIndicies[faceIndex].face.i1 = scanIndex; foundFlags = foundFlags & ~0x007; } }
                if(foundFlags & 0x007) {
                    if(mesh_in->vCoords && mesh_out->vCoords) egwVecCopy3f(&(mesh_in->vCoords[vertexIndex+0]), &(mesh_out->vCoords[vCount]));
                    if(mesh_in->nCoords && mesh_out->nCoords) egwVecCopy3f(&(mesh_in->nCoords[vertexIndex+0]), &(mesh_out->nCoords[vCount]));
                    if(mesh_in->tCoords && mesh_out->tCoords) egwVecCopy2f(&(mesh_in->tCoords[vertexIndex+0]), &(mesh_out->tCoords[vCount]));
                    mesh_out->fIndicies[faceIndex].face.i1 = vCount++;
                }
                
                foundFlags = 0x070;
                for(scanIndex = 0; scanIndex < vCount && foundFlags; ++scanIndex) {
                    if((foundFlags & 0x070) && (!(mesh_in->vCoords && mesh_out->vCoords) || egwVecIsEqual3f(&(mesh_in->vCoords[vertexIndex+1]), &(mesh_out->vCoords[scanIndex])))
                       && (!(mesh_in->nCoords && mesh_out->nCoords) || egwVecIsEqual3f(&(mesh_in->nCoords[vertexIndex+1]), &(mesh_out->nCoords[scanIndex])))
                       && (!(mesh_in->tCoords && mesh_out->tCoords) || egwVecIsEqual2f(&(mesh_in->tCoords[vertexIndex+1]), &(mesh_out->tCoords[scanIndex])))) { mesh_out->fIndicies[faceIndex].face.i2 = scanIndex; foundFlags = foundFlags & ~0x070; } }
                if(foundFlags & 0x070) {
                    if(mesh_in->vCoords && mesh_out->vCoords) egwVecCopy3f(&(mesh_in->vCoords[vertexIndex+1]), &(mesh_out->vCoords[vCount]));
                    if(mesh_in->nCoords && mesh_out->nCoords) egwVecCopy3f(&(mesh_in->nCoords[vertexIndex+1]), &(mesh_out->nCoords[vCount]));
                    if(mesh_in->tCoords && mesh_out->tCoords) egwVecCopy2f(&(mesh_in->tCoords[vertexIndex+1]), &(mesh_out->tCoords[vCount]));
                    mesh_out->fIndicies[faceIndex].face.i2 = vCount++;
                }
                
                foundFlags = 0x700;
                for(scanIndex = 0; scanIndex < vCount && foundFlags; ++scanIndex) {
                    if((foundFlags & 0x700) && (!(mesh_in->vCoords && mesh_out->vCoords) || egwVecIsEqual3f(&(mesh_in->vCoords[vertexIndex+2]), &(mesh_out->vCoords[scanIndex])))
                       && (!(mesh_in->nCoords && mesh_out->nCoords) || egwVecIsEqual3f(&(mesh_in->nCoords[vertexIndex+2]), &(mesh_out->nCoords[scanIndex])))
                       && (!(mesh_in->tCoords && mesh_out->tCoords) || egwVecIsEqual2f(&(mesh_in->tCoords[vertexIndex+2]), &(mesh_out->tCoords[scanIndex])))) { mesh_out->fIndicies[faceIndex].face.i3 = scanIndex; foundFlags = foundFlags & ~0x700; } }
                if(foundFlags & 0x700) {
                    if(mesh_in->vCoords && mesh_out->vCoords) egwVecCopy3f(&(mesh_in->vCoords[vertexIndex+2]), &(mesh_out->vCoords[vCount]));
                    if(mesh_in->nCoords && mesh_out->nCoords) egwVecCopy3f(&(mesh_in->nCoords[vertexIndex+2]), &(mesh_out->nCoords[vCount]));
                    if(mesh_in->tCoords && mesh_out->tCoords) egwVecCopy2f(&(mesh_in->tCoords[vertexIndex+2]), &(mesh_out->tCoords[vCount]));
                    mesh_out->fIndicies[faceIndex].face.i3 = vCount++;
                }
            }
            
            if(vCount == mesh_out->vCount) return mesh_out;
            else egwMeshFreeSJITVAf(mesh_out);
        }
    }
    
    return NULL;
}

egwSDITVAMeshf* egwMeshConvertSTVAfSDITVAf(const egwSTVAMeshf* mesh_in, egwSDITVAMeshf* mesh_out) {
    EGWint vertexIndex, scanIndex;
    EGWuint foundFlags;
    EGWuint vCount = (mesh_in->vCoords ? mesh_in->vCount : 0);
    EGWuint nCount = (mesh_in->nCoords ? mesh_in->vCount : 0);
    EGWuint tCount = (mesh_in->tCoords ? mesh_in->vCount : 0);
    
    if(vCount || nCount || tCount) {
        for(vertexIndex = 1; vertexIndex < mesh_in->vCount; ++vertexIndex) {
            foundFlags = (vCount ? 1 : 0) | (nCount ? 2 : 0) | (tCount ? 4 : 0);
            
            for(scanIndex = vertexIndex - 1; scanIndex >= 0 && foundFlags; --scanIndex) {
                if((foundFlags & 1) && egwVecIsEqual3f(&(mesh_in->vCoords[vertexIndex]), &(mesh_in->vCoords[scanIndex]))) { --vCount; foundFlags = foundFlags & ~1; }
                if((foundFlags & 2) && egwVecIsEqual3f(&(mesh_in->nCoords[vertexIndex]), &(mesh_in->nCoords[scanIndex]))) { --nCount; foundFlags = foundFlags & ~2; }
                if((foundFlags & 4) && egwVecIsEqual2f(&(mesh_in->tCoords[vertexIndex]), &(mesh_in->tCoords[scanIndex]))) { --tCount; foundFlags = foundFlags & ~4; }
            }
        }
        
        if(egwMeshAllocSDITVAf(mesh_out, vCount, nCount, tCount, (mesh_in->vCount / 3))) {
            EGWint faceIndex;
            vCount = nCount = tCount = 0;
            
            for(faceIndex = 0, vertexIndex = 0; faceIndex < mesh_out->fCount && vertexIndex < mesh_in->vCount; ++faceIndex, vertexIndex += 3) {
                if(mesh_out->vCoords) {
                    foundFlags = 0x001;
                    for(scanIndex = 0; scanIndex < vCount && foundFlags; ++scanIndex)
                        if((foundFlags & 0x001) && egwVecIsEqual3f(&(mesh_in->vCoords[vertexIndex+0]), &(mesh_out->vCoords[scanIndex]))) { mesh_out->fIndicies[faceIndex].face.iv1 = scanIndex; foundFlags = foundFlags & ~0x001; }
                    if(foundFlags & 0x001) { egwVecCopy3f(&(mesh_in->vCoords[vertexIndex+0]), &(mesh_out->vCoords[vCount])); mesh_out->fIndicies[faceIndex].face.iv1 = vCount++; }
                    
                    foundFlags = 0x010;
                    for(scanIndex = 0; scanIndex < vCount && foundFlags; ++scanIndex)
                        if((foundFlags & 0x010) && egwVecIsEqual3f(&(mesh_in->vCoords[vertexIndex+1]), &(mesh_out->vCoords[scanIndex]))) { mesh_out->fIndicies[faceIndex].face.iv2 = scanIndex; foundFlags = foundFlags & ~0x010; }
                    if(foundFlags & 0x010) { egwVecCopy3f(&(mesh_in->vCoords[vertexIndex+1]), &(mesh_out->vCoords[vCount])); mesh_out->fIndicies[faceIndex].face.iv2 = vCount++; }
                    
                    foundFlags = 0x100;
                    for(scanIndex = 0; scanIndex < vCount && foundFlags; ++scanIndex)
                        if((foundFlags & 0x100) && egwVecIsEqual3f(&(mesh_in->vCoords[vertexIndex+2]), &(mesh_out->vCoords[scanIndex]))) { mesh_out->fIndicies[faceIndex].face.iv3 = scanIndex; foundFlags = foundFlags & ~0x100; }
                    if(foundFlags & 0x100) { egwVecCopy3f(&(mesh_in->vCoords[vertexIndex+2]), &(mesh_out->vCoords[vCount])); mesh_out->fIndicies[faceIndex].face.iv3 = vCount++; }
                }
                
                if(mesh_out->nCoords) {
                    foundFlags = 0x002;
                    for(scanIndex = 0; scanIndex < nCount && foundFlags; ++scanIndex)
                        if((foundFlags & 0x002) && egwVecIsEqual3f(&(mesh_in->nCoords[vertexIndex+0]), &(mesh_out->nCoords[scanIndex]))) { mesh_out->fIndicies[faceIndex].face.in1 = scanIndex; foundFlags = foundFlags & ~0x002; }
                    if(foundFlags & 0x002) { egwVecCopy3f(&(mesh_in->nCoords[vertexIndex+0]), &(mesh_out->nCoords[nCount])); mesh_out->fIndicies[faceIndex].face.in1 = nCount++; }
                    
                    foundFlags = 0x020;
                    for(scanIndex = 0; scanIndex < nCount && foundFlags; ++scanIndex)
                        if((foundFlags & 0x020) && egwVecIsEqual3f(&(mesh_in->nCoords[vertexIndex+1]), &(mesh_out->nCoords[scanIndex]))) { mesh_out->fIndicies[faceIndex].face.in2 = scanIndex; foundFlags = foundFlags & ~0x020; }
                    if(foundFlags & 0x020) { egwVecCopy3f(&(mesh_in->nCoords[vertexIndex+1]), &(mesh_out->nCoords[nCount])); mesh_out->fIndicies[faceIndex].face.in2 = nCount++; }
                    
                    foundFlags = 0x200;
                    for(scanIndex = 0; scanIndex < nCount && foundFlags; ++scanIndex)
                        if((foundFlags & 0x200) && egwVecIsEqual3f(&(mesh_in->nCoords[vertexIndex+2]), &(mesh_out->nCoords[scanIndex]))) { mesh_out->fIndicies[faceIndex].face.in3 = scanIndex; foundFlags = foundFlags & ~0x200; }
                    if(foundFlags & 0x200) { egwVecCopy3f(&(mesh_in->nCoords[vertexIndex+2]), &(mesh_out->nCoords[nCount])); mesh_out->fIndicies[faceIndex].face.in3 = nCount++; }
                }
                
                if(mesh_out->tCoords) {
                    foundFlags = 0x004;
                    for(scanIndex = 0; scanIndex < tCount && foundFlags; ++scanIndex)
                        if((foundFlags & 0x004) && egwVecIsEqual2f(&(mesh_in->tCoords[vertexIndex+0]), &(mesh_out->tCoords[scanIndex]))) { mesh_out->fIndicies[faceIndex].face.it1 = scanIndex; foundFlags = foundFlags & ~0x004; }
                    if(foundFlags & 0x004) { egwVecCopy2f(&(mesh_in->tCoords[vertexIndex+0]), &(mesh_out->tCoords[tCount])); mesh_out->fIndicies[faceIndex].face.it1 = tCount++; }
                    
                    foundFlags = 0x040;
                    for(scanIndex = 0; scanIndex < tCount && foundFlags; ++scanIndex)
                        if((foundFlags & 0x040) && egwVecIsEqual2f(&(mesh_in->tCoords[vertexIndex+1]), &(mesh_out->tCoords[scanIndex]))) { mesh_out->fIndicies[faceIndex].face.it2 = scanIndex; foundFlags = foundFlags & ~0x040; }
                    if(foundFlags & 0x040) { egwVecCopy2f(&(mesh_in->tCoords[vertexIndex+1]), &(mesh_out->tCoords[tCount])); mesh_out->fIndicies[faceIndex].face.it2 = tCount++; }
                    
                    foundFlags = 0x400;
                    for(scanIndex = 0; scanIndex < tCount && foundFlags; ++scanIndex)
                        if((foundFlags & 0x400) && egwVecIsEqual2f(&(mesh_in->tCoords[vertexIndex+2]), &(mesh_out->tCoords[scanIndex]))) { mesh_out->fIndicies[faceIndex].face.it3 = scanIndex; foundFlags = foundFlags & ~0x400; }
                    if(foundFlags & 0x400) { egwVecCopy2f(&(mesh_in->tCoords[vertexIndex+2]), &(mesh_out->tCoords[tCount])); mesh_out->fIndicies[faceIndex].face.it3 = tCount++; }
                }
            }
            
            if(vCount == mesh_out->vCount && nCount == mesh_out->nCount && tCount == mesh_out->tCount) return mesh_out;
            else egwMeshFreeSDITVAf(mesh_out);
        }
    }
    
    return NULL;
}

egwSTVAMeshf* egwMeshConvertSJITVAfSTVAf(const egwSJITVAMeshf* mesh_in, egwSTVAMeshf* mesh_out) {
    if(egwMeshAllocSTVAf(mesh_out, (mesh_in->vCoords ? mesh_in->fCount * 3 : 0), (mesh_in->nCoords ? mesh_in->fCount * 3 : 0), (mesh_in->tCoords ? mesh_in->fCount * 3 : 0))) {
        for(EGWint faceIndex = 0, vertexIndex = 0; faceIndex < mesh_in->fCount && vertexIndex < mesh_out->vCount; ++faceIndex, vertexIndex += 3) {
            if(mesh_in->vCoords && mesh_out->vCoords) {
                egwVecCopy3f(&(mesh_in->vCoords[mesh_in->fIndicies[faceIndex].face.i1]), &(mesh_out->vCoords[vertexIndex+0]));
                egwVecCopy3f(&(mesh_in->vCoords[mesh_in->fIndicies[faceIndex].face.i2]), &(mesh_out->vCoords[vertexIndex+1]));
                egwVecCopy3f(&(mesh_in->vCoords[mesh_in->fIndicies[faceIndex].face.i3]), &(mesh_out->vCoords[vertexIndex+2]));
            }
            if(mesh_in->nCoords && mesh_out->nCoords) {
                egwVecCopy3f(&(mesh_in->nCoords[mesh_in->fIndicies[faceIndex].face.i1]), &(mesh_out->nCoords[vertexIndex+0]));
                egwVecCopy3f(&(mesh_in->nCoords[mesh_in->fIndicies[faceIndex].face.i2]), &(mesh_out->nCoords[vertexIndex+1]));
                egwVecCopy3f(&(mesh_in->nCoords[mesh_in->fIndicies[faceIndex].face.i3]), &(mesh_out->nCoords[vertexIndex+2]));
            }
            if(mesh_in->tCoords && mesh_out->tCoords) {
                egwVecCopy2f(&(mesh_in->tCoords[mesh_in->fIndicies[faceIndex].face.i1]), &(mesh_out->tCoords[vertexIndex+0]));
                egwVecCopy2f(&(mesh_in->tCoords[mesh_in->fIndicies[faceIndex].face.i2]), &(mesh_out->tCoords[vertexIndex+1]));
                egwVecCopy2f(&(mesh_in->tCoords[mesh_in->fIndicies[faceIndex].face.i3]), &(mesh_out->tCoords[vertexIndex+2]));
            }
        }
        
        return mesh_out;
    }
    
    return NULL;
}

egwSDITVAMeshf* egwMeshConvertSJITVAfSDITVAf(const egwSJITVAMeshf* mesh_in, egwSDITVAMeshf* mesh_out) {
    egwSTVAMeshf temp; memset((void*)&temp, 0, sizeof(egwSTVAMeshf));
    
    if(egwMeshConvertSJITVAfSTVAf(mesh_in, &temp) && egwMeshConvertSTVAfSDITVAf(&temp, mesh_out)) {
        egwMeshFreeSTVAf(&temp);
        return mesh_out;
    }
    
    egwMeshFreeSTVAf(&temp);
    return NULL;
}

egwSTVAMeshf* egwMeshConvertSDITVAfSTVAf(const egwSDITVAMeshf* mesh_in, egwSTVAMeshf* mesh_out) {
    if(egwMeshAllocSTVAf(mesh_out, (mesh_in->vCoords ? mesh_in->fCount * 3 : 0), (mesh_in->nCoords ? mesh_in->fCount * 3 : 0), (mesh_in->tCoords ? mesh_in->fCount * 3 : 0))) {
        for(EGWint faceIndex = 0, vertexIndex = 0; faceIndex < mesh_in->fCount && vertexIndex < mesh_out->vCount; ++faceIndex, vertexIndex += 3) {
            if(mesh_in->vCoords && mesh_out->vCoords) {
                egwVecCopy3f(&(mesh_in->vCoords[mesh_in->fIndicies[faceIndex].face.iv1]), &(mesh_out->vCoords[vertexIndex+0]));
                egwVecCopy3f(&(mesh_in->vCoords[mesh_in->fIndicies[faceIndex].face.iv2]), &(mesh_out->vCoords[vertexIndex+1]));
                egwVecCopy3f(&(mesh_in->vCoords[mesh_in->fIndicies[faceIndex].face.iv3]), &(mesh_out->vCoords[vertexIndex+2]));
            }
            if(mesh_in->nCoords && mesh_out->nCoords) {
                egwVecCopy3f(&(mesh_in->nCoords[mesh_in->fIndicies[faceIndex].face.in1]), &(mesh_out->nCoords[vertexIndex+0]));
                egwVecCopy3f(&(mesh_in->nCoords[mesh_in->fIndicies[faceIndex].face.in2]), &(mesh_out->nCoords[vertexIndex+1]));
                egwVecCopy3f(&(mesh_in->nCoords[mesh_in->fIndicies[faceIndex].face.in3]), &(mesh_out->nCoords[vertexIndex+2]));
            }
            if(mesh_in->tCoords && mesh_out->tCoords) {
                egwVecCopy2f(&(mesh_in->tCoords[mesh_in->fIndicies[faceIndex].face.it1]), &(mesh_out->tCoords[vertexIndex+0]));
                egwVecCopy2f(&(mesh_in->tCoords[mesh_in->fIndicies[faceIndex].face.it2]), &(mesh_out->tCoords[vertexIndex+1]));
                egwVecCopy2f(&(mesh_in->tCoords[mesh_in->fIndicies[faceIndex].face.it3]), &(mesh_out->tCoords[vertexIndex+2]));
            }
        }
        
        return mesh_out;
    }
    
    return NULL;
}

egwSJITVAMeshf* egwMeshConvertSDITVAfSJITVAf(const egwSDITVAMeshf* mesh_in, egwSJITVAMeshf* mesh_out) {
    egwSTVAMeshf temp; memset((void*)&temp, 0, sizeof(egwSTVAMeshf));
    
    if(egwMeshConvertSDITVAfSTVAf(mesh_in, &temp) && egwMeshConvertSTVAfSJITVAf(&temp, mesh_out)) {
        egwMeshFreeSTVAf(&temp);
        return mesh_out;
    }
    
    egwMeshFreeSTVAf(&temp);
    return NULL;
}

egwKFJITVAMeshf* egwMeshConvertKFTVAfKFJITVAf(const egwKFTVAMeshf* mesh_in, egwKFJITVAMeshf* mesh_out) {
    EGWint vertexIndex, scanIndex;
    EGWuint foundFlags;
    EGWuint vCount = (mesh_in->vkCoords || mesh_in->nkCoords || mesh_in->tkCoords ? mesh_in->vCount : 0);
    
    if(vCount) {
        for(vertexIndex = 1; vertexIndex < mesh_in->vCount; ++vertexIndex) {
            foundFlags = (vCount ? 7 : 0);
            
            for(scanIndex = vertexIndex - 1; scanIndex >= 0 && foundFlags; --scanIndex) {
                if((foundFlags & 7) && (!(mesh_in->vkCoords) || egwVecIsEqual3f(&(mesh_in->vkCoords[vertexIndex]), &(mesh_in->vkCoords[scanIndex])))
                   && (!(mesh_in->nkCoords) || egwVecIsEqual3f(&(mesh_in->nkCoords[vertexIndex]), &(mesh_in->nkCoords[scanIndex])))
                   && (!(mesh_in->tkCoords) || egwVecIsEqual2f(&(mesh_in->tkCoords[vertexIndex]), &(mesh_in->tkCoords[scanIndex])))) { --vCount; foundFlags = foundFlags & ~7; }
            }
        }
        
        if(egwMeshAllocKFJITVAf(mesh_out, (mesh_in->vkCoords ? vCount : 0), (mesh_in->nkCoords ? vCount : 0), (mesh_in->tkCoords ? vCount : 0), (mesh_in->vCount / 3), mesh_in->vfCount, mesh_in->nfCount, mesh_in->tfCount)) {
            EGWint faceIndex;
            vCount = 0;
            
            for(faceIndex = 0, vertexIndex = 0; faceIndex < mesh_out->fCount && vertexIndex < mesh_in->vCount; ++faceIndex, vertexIndex += 3) {
                foundFlags = 0x007;
                for(scanIndex = 0; scanIndex < vCount && foundFlags; ++scanIndex) {
                    if((foundFlags & 0x007) && (!(mesh_in->vkCoords && mesh_out->vkCoords) || egwVecIsEqual3f(&(mesh_in->vkCoords[vertexIndex+0]), &(mesh_out->vkCoords[scanIndex])))
                       && (!(mesh_in->nkCoords && mesh_out->nkCoords) || egwVecIsEqual3f(&(mesh_in->nkCoords[vertexIndex+0]), &(mesh_out->nkCoords[scanIndex])))
                       && (!(mesh_in->tkCoords && mesh_out->tkCoords) || egwVecIsEqual2f(&(mesh_in->tkCoords[vertexIndex+0]), &(mesh_out->tkCoords[scanIndex])))) { mesh_out->fIndicies[faceIndex].face.i1 = scanIndex; foundFlags = foundFlags & ~0x007; } }
                if(foundFlags & 0x007) {
                    if(mesh_in->vkCoords && mesh_out->vkCoords)
                        for(EGWint frameOffset = 0; frameOffset < (mesh_in->vfCount ? mesh_in->vfCount : 1); ++frameOffset)
                            egwVecCopy3f(&(mesh_in->vkCoords[(mesh_in->vCount * frameOffset) + vertexIndex+0]), &(mesh_out->vkCoords[(mesh_out->vCount * frameOffset) + vCount]));
                    if(mesh_in->nkCoords && mesh_out->nkCoords)
                        for(EGWint frameOffset = 0; frameOffset < (mesh_in->nfCount ? mesh_in->nfCount : 1); ++frameOffset)
                            egwVecCopy3f(&(mesh_in->nkCoords[(mesh_in->vCount * frameOffset) + vertexIndex+0]), &(mesh_out->nkCoords[(mesh_out->vCount * frameOffset) + vCount]));
                    if(mesh_in->tkCoords && mesh_out->tkCoords)
                        for(EGWint frameOffset = 0; frameOffset < (mesh_in->tfCount ? mesh_in->tfCount : 1); ++frameOffset)
                            egwVecCopy2f(&(mesh_in->tkCoords[(mesh_in->vCount * frameOffset) + vertexIndex+0]), &(mesh_out->tkCoords[(mesh_out->vCount * frameOffset) + vCount]));
                    mesh_out->fIndicies[faceIndex].face.i1 = vCount++;
                }
                
                foundFlags = 0x070;
                for(scanIndex = 0; scanIndex < vCount && foundFlags; ++scanIndex) {
                    if((foundFlags & 0x070) && (!(mesh_in->vkCoords && mesh_out->vkCoords) || egwVecIsEqual3f(&(mesh_in->vkCoords[vertexIndex+1]), &(mesh_out->vkCoords[scanIndex])))
                       && (!(mesh_in->nkCoords && mesh_out->nkCoords) || egwVecIsEqual3f(&(mesh_in->nkCoords[vertexIndex+1]), &(mesh_out->nkCoords[scanIndex])))
                       && (!(mesh_in->tkCoords && mesh_out->tkCoords) || egwVecIsEqual2f(&(mesh_in->tkCoords[vertexIndex+1]), &(mesh_out->tkCoords[scanIndex])))) { mesh_out->fIndicies[faceIndex].face.i2 = scanIndex; foundFlags = foundFlags & ~0x070; } }
                if(foundFlags & 0x070) {
                    if(mesh_in->vkCoords && mesh_out->vkCoords)
                        for(EGWint frameOffset = 0; frameOffset < (mesh_in->vfCount ? mesh_in->vfCount : 1); ++frameOffset)
                            egwVecCopy3f(&(mesh_in->vkCoords[(mesh_in->vCount * frameOffset) + vertexIndex+1]), &(mesh_out->vkCoords[(mesh_out->vCount * frameOffset) + vCount]));
                    if(mesh_in->nkCoords && mesh_out->nkCoords)
                        for(EGWint frameOffset = 0; frameOffset < (mesh_in->nfCount ? mesh_in->nfCount : 1); ++frameOffset)
                            egwVecCopy3f(&(mesh_in->nkCoords[(mesh_in->vCount * frameOffset) + vertexIndex+1]), &(mesh_out->nkCoords[(mesh_out->vCount * frameOffset) + vCount]));
                    if(mesh_in->tkCoords && mesh_out->tkCoords)
                        for(EGWint frameOffset = 0; frameOffset < (mesh_in->tfCount ? mesh_in->tfCount : 1); ++frameOffset)
                            egwVecCopy2f(&(mesh_in->tkCoords[(mesh_in->vCount * frameOffset) + vertexIndex+1]), &(mesh_out->tkCoords[(mesh_out->vCount * frameOffset) + vCount]));
                    mesh_out->fIndicies[faceIndex].face.i2 = vCount++;
                }
                
                foundFlags = 0x700;
                for(scanIndex = 0; scanIndex < vCount && foundFlags; ++scanIndex) {
                    if((foundFlags & 0x700) && (!(mesh_in->vkCoords && mesh_out->vkCoords) || egwVecIsEqual3f(&(mesh_in->vkCoords[vertexIndex+2]), &(mesh_out->vkCoords[scanIndex])))
                       && (!(mesh_in->nkCoords && mesh_out->nkCoords) || egwVecIsEqual3f(&(mesh_in->nkCoords[vertexIndex+2]), &(mesh_out->nkCoords[scanIndex])))
                       && (!(mesh_in->tkCoords && mesh_out->tkCoords) || egwVecIsEqual2f(&(mesh_in->tkCoords[vertexIndex+2]), &(mesh_out->tkCoords[scanIndex])))) { mesh_out->fIndicies[faceIndex].face.i3 = scanIndex; foundFlags = foundFlags & ~0x700; } }
                if(foundFlags & 0x700) {
                    if(mesh_in->vkCoords && mesh_out->vkCoords)
                        for(EGWint frameOffset = 0; frameOffset < (mesh_in->vfCount ? mesh_in->vfCount : 1); ++frameOffset)
                            egwVecCopy3f(&(mesh_in->vkCoords[(mesh_in->vCount * frameOffset) + vertexIndex+2]), &(mesh_out->vkCoords[(mesh_out->vCount * frameOffset) + vCount]));
                    if(mesh_in->nkCoords && mesh_out->nkCoords)
                        for(EGWint frameOffset = 0; frameOffset < (mesh_in->nfCount ? mesh_in->nfCount : 1); ++frameOffset)
                            egwVecCopy3f(&(mesh_in->nkCoords[(mesh_in->vCount * frameOffset) + vertexIndex+2]), &(mesh_out->nkCoords[(mesh_out->vCount * frameOffset) + vCount]));
                    if(mesh_in->tkCoords && mesh_out->tkCoords)
                        for(EGWint frameOffset = 0; frameOffset < (mesh_in->tfCount ? mesh_in->tfCount : 1); ++frameOffset)
                            egwVecCopy2f(&(mesh_in->tkCoords[(mesh_in->vCount * frameOffset) + vertexIndex+2]), &(mesh_out->tkCoords[(mesh_out->vCount * frameOffset) + vCount]));
                    mesh_out->fIndicies[faceIndex].face.i3 = vCount++;
                }
            }
            
            if(vCount == mesh_out->vCount) return mesh_out;
            else egwMeshFreeKFJITVAf(mesh_out);
        }
    }
    
    return NULL;
}

egwKFDITVAMeshf* egwMeshConvertKFTVAfKFDITVAf(const egwKFTVAMeshf* mesh_in, egwKFDITVAMeshf* mesh_out) {
    EGWint vertexIndex, scanIndex;
    EGWuint foundFlags;
    EGWuint vCount = (mesh_in->vkCoords ? mesh_in->vCount : 0);
    EGWuint nCount = (mesh_in->nkCoords ? mesh_in->vCount : 0);
    EGWuint tCount = (mesh_in->tkCoords ? mesh_in->vCount : 0);
    
    if(vCount || nCount || tCount) {
        for(vertexIndex = 1; vertexIndex < mesh_in->vCount; ++vertexIndex) {
            foundFlags = (vCount ? 1 : 0) | (nCount ? 2 : 0) | (tCount ? 4 : 0);
            
            for(scanIndex = vertexIndex - 1; scanIndex >= 0 && foundFlags; --scanIndex) {
                if((foundFlags & 1) && egwVecIsEqual3f(&(mesh_in->vkCoords[vertexIndex]), &(mesh_in->vkCoords[scanIndex]))) { --vCount; foundFlags = foundFlags & ~1; }
                if((foundFlags & 2) && egwVecIsEqual3f(&(mesh_in->nkCoords[vertexIndex]), &(mesh_in->nkCoords[scanIndex]))) { --nCount; foundFlags = foundFlags & ~2; }
                if((foundFlags & 4) && egwVecIsEqual2f(&(mesh_in->tkCoords[vertexIndex]), &(mesh_in->tkCoords[scanIndex]))) { --tCount; foundFlags = foundFlags & ~4; }
            }
        }
        
        if(egwMeshAllocKFDITVAf(mesh_out, vCount, nCount, tCount, (mesh_in->vCount / 3), mesh_in->vfCount, mesh_in->nfCount, mesh_in->tfCount)) {
            EGWint faceIndex;
            vCount = nCount = tCount = 0;
            
            for(faceIndex = 0, vertexIndex = 0; faceIndex < mesh_out->fCount && vertexIndex < mesh_in->vCount; ++faceIndex, vertexIndex += 3) {
                if(mesh_out->vkCoords) {
                    foundFlags = 0x001;
                    for(scanIndex = 0; scanIndex < vCount && foundFlags; ++scanIndex)
                        if((foundFlags & 0x001) && egwVecIsEqual3f(&(mesh_in->vkCoords[vertexIndex+0]), &(mesh_out->vkCoords[scanIndex]))) { mesh_out->fIndicies[faceIndex].face.iv1 = scanIndex; foundFlags = foundFlags & ~0x001; }
                    if(foundFlags & 0x001) {
                        for(EGWint frameOffset = 0; frameOffset < (mesh_in->vfCount ? mesh_in->vfCount : 1); ++frameOffset)
                            egwVecCopy3f(&(mesh_in->vkCoords[(mesh_in->vCount * frameOffset) + vertexIndex+0]), &(mesh_out->vkCoords[(mesh_out->vCount * frameOffset) + vCount]));
                        mesh_out->fIndicies[faceIndex].face.iv1 = vCount++;
                    }
                    
                    foundFlags = 0x010;
                    for(scanIndex = 0; scanIndex < vCount && foundFlags; ++scanIndex)
                        if((foundFlags & 0x010) && egwVecIsEqual3f(&(mesh_in->vkCoords[vertexIndex+1]), &(mesh_out->vkCoords[scanIndex]))) { mesh_out->fIndicies[faceIndex].face.iv2 = scanIndex; foundFlags = foundFlags & ~0x010; }
                    if(foundFlags & 0x010) {
                        for(EGWint frameOffset = 0; frameOffset < (mesh_in->vfCount ? mesh_in->vfCount : 1); ++frameOffset)
                            egwVecCopy3f(&(mesh_in->vkCoords[(mesh_in->vCount * frameOffset) + vertexIndex+1]), &(mesh_out->vkCoords[(mesh_out->vCount * frameOffset) + vCount]));
                        mesh_out->fIndicies[faceIndex].face.iv2 = vCount++;
                    }
                    
                    foundFlags = 0x100;
                    for(scanIndex = 0; scanIndex < vCount && foundFlags; ++scanIndex)
                        if((foundFlags & 0x100) && egwVecIsEqual3f(&(mesh_in->vkCoords[vertexIndex+2]), &(mesh_out->vkCoords[scanIndex]))) { mesh_out->fIndicies[faceIndex].face.iv3 = scanIndex; foundFlags = foundFlags & ~0x100; }
                    if(foundFlags & 0x100) {
                        for(EGWint frameOffset = 0; frameOffset < (mesh_in->vfCount ? mesh_in->vfCount : 1); ++frameOffset)
                            egwVecCopy3f(&(mesh_in->vkCoords[(mesh_in->vCount * frameOffset) + vertexIndex+2]), &(mesh_out->vkCoords[(mesh_out->vCount * frameOffset) + vCount]));
                        mesh_out->fIndicies[faceIndex].face.iv3 = vCount++;
                    }
                }
                
                if(mesh_out->nkCoords) {
                    foundFlags = 0x002;
                    for(scanIndex = 0; scanIndex < nCount && foundFlags; ++scanIndex)
                        if((foundFlags & 0x002) && egwVecIsEqual3f(&(mesh_in->nkCoords[vertexIndex+0]), &(mesh_out->nkCoords[scanIndex]))) { mesh_out->fIndicies[faceIndex].face.in1 = scanIndex; foundFlags = foundFlags & ~0x002; }
                    if(foundFlags & 0x002) {
                        for(EGWint frameOffset = 0; frameOffset < (mesh_in->nfCount ? mesh_in->nfCount : 1); ++frameOffset)
                            egwVecCopy3f(&(mesh_in->nkCoords[(mesh_in->vCount * frameOffset) + vertexIndex+0]), &(mesh_out->nkCoords[(mesh_out->nCount * frameOffset) + nCount]));
                        mesh_out->fIndicies[faceIndex].face.in1 = nCount++;
                    }
                    
                    foundFlags = 0x020;
                    for(scanIndex = 0; scanIndex < nCount && foundFlags; ++scanIndex)
                        if((foundFlags & 0x020) && egwVecIsEqual3f(&(mesh_in->nkCoords[vertexIndex+1]), &(mesh_out->nkCoords[scanIndex]))) { mesh_out->fIndicies[faceIndex].face.in2 = scanIndex; foundFlags = foundFlags & ~0x020; }
                    if(foundFlags & 0x020) {
                        for(EGWint frameOffset = 0; frameOffset < (mesh_in->nfCount ? mesh_in->nfCount : 1); ++frameOffset)
                            egwVecCopy3f(&(mesh_in->nkCoords[(mesh_in->vCount * frameOffset) + vertexIndex+1]), &(mesh_out->nkCoords[(mesh_out->nCount * frameOffset) + nCount]));
                        mesh_out->fIndicies[faceIndex].face.in2 = nCount++;
                    }
                    
                    foundFlags = 0x200;
                    for(scanIndex = 0; scanIndex < nCount && foundFlags; ++scanIndex)
                        if((foundFlags & 0x200) && egwVecIsEqual3f(&(mesh_in->nkCoords[vertexIndex+2]), &(mesh_out->nkCoords[scanIndex]))) { mesh_out->fIndicies[faceIndex].face.in3 = scanIndex; foundFlags = foundFlags & ~0x200; }
                    if(foundFlags & 0x200) {
                        for(EGWint frameOffset = 0; frameOffset < (mesh_in->nfCount ? mesh_in->nfCount : 1); ++frameOffset)
                            egwVecCopy3f(&(mesh_in->nkCoords[(mesh_in->vCount * frameOffset) + vertexIndex+2]), &(mesh_out->nkCoords[(mesh_out->nCount * frameOffset) + nCount]));
                        mesh_out->fIndicies[faceIndex].face.in3 = nCount++;
                    }
                }
                
                if(mesh_out->tkCoords) {
                    foundFlags = 0x004;
                    for(scanIndex = 0; scanIndex < tCount && foundFlags; ++scanIndex)
                        if((foundFlags & 0x004) && egwVecIsEqual2f(&(mesh_in->tkCoords[vertexIndex+0]), &(mesh_out->tkCoords[scanIndex]))) { mesh_out->fIndicies[faceIndex].face.it1 = scanIndex; foundFlags = foundFlags & ~0x004; }
                    if(foundFlags & 0x004) {
                        for(EGWint frameOffset = 0; frameOffset < (mesh_in->tfCount ? mesh_in->tfCount : 1); ++frameOffset)
                            egwVecCopy2f(&(mesh_in->tkCoords[(mesh_in->vCount * frameOffset) + vertexIndex+0]), &(mesh_out->tkCoords[(mesh_out->tCount * frameOffset) + tCount]));
                        mesh_out->fIndicies[faceIndex].face.it1 = tCount++;
                    }
                    
                    foundFlags = 0x040;
                    for(scanIndex = 0; scanIndex < tCount && foundFlags; ++scanIndex)
                        if((foundFlags & 0x040) && egwVecIsEqual2f(&(mesh_in->tkCoords[vertexIndex+1]), &(mesh_out->tkCoords[scanIndex]))) { mesh_out->fIndicies[faceIndex].face.it2 = scanIndex; foundFlags = foundFlags & ~0x040; }
                    if(foundFlags & 0x040) {
                        for(EGWint frameOffset = 0; frameOffset < (mesh_in->tfCount ? mesh_in->tfCount : 1); ++frameOffset)
                            egwVecCopy2f(&(mesh_in->tkCoords[(mesh_in->vCount * frameOffset) + vertexIndex+1]), &(mesh_out->tkCoords[(mesh_out->tCount * frameOffset) + tCount]));
                        mesh_out->fIndicies[faceIndex].face.it2 = tCount++;
                    }
                    
                    foundFlags = 0x400;
                    for(scanIndex = 0; scanIndex < tCount && foundFlags; ++scanIndex)
                        if((foundFlags & 0x400) && egwVecIsEqual2f(&(mesh_in->tkCoords[vertexIndex+2]), &(mesh_out->tkCoords[scanIndex]))) { mesh_out->fIndicies[faceIndex].face.it3 = scanIndex; foundFlags = foundFlags & ~0x400; }
                    if(foundFlags & 0x400) {
                        for(EGWint frameOffset = 0; frameOffset < (mesh_in->tfCount ? mesh_in->tfCount : 1); ++frameOffset)
                            egwVecCopy2f(&(mesh_in->tkCoords[(mesh_in->vCount * frameOffset) + vertexIndex+2]), &(mesh_out->tkCoords[(mesh_out->tCount * frameOffset) + tCount]));
                        mesh_out->fIndicies[faceIndex].face.it3 = tCount++;
                    }
                }
            }
            
            if(vCount == mesh_out->vCount && nCount == mesh_out->nCount && tCount == mesh_out->tCount) return mesh_out;
            else egwMeshFreeKFDITVAf(mesh_out);
        }
    }
    
    return NULL;
}

egwKFTVAMeshf* egwMeshConvertKFJITVAfKFTVAf(const egwKFJITVAMeshf* mesh_in, egwKFTVAMeshf* mesh_out) {
    if(egwMeshAllocKFTVAf(mesh_out, (mesh_in->vkCoords ? mesh_in->fCount * 3 : 0), (mesh_in->nkCoords ? mesh_in->fCount * 3 : 0), (mesh_in->tkCoords ? mesh_in->fCount * 3 : 0), mesh_in->vfCount, mesh_in->nfCount, mesh_in->tfCount)) {
        for(EGWint faceIndex = 0, vertexIndex = 0; faceIndex < mesh_in->fCount && vertexIndex < mesh_out->vCount; ++faceIndex, vertexIndex += 3) {
            if(mesh_in->vkCoords && mesh_out->vkCoords) {
                for(EGWint frameOffset = 0; frameOffset < (mesh_in->vfCount ? mesh_in->vfCount : 1); ++frameOffset) {
                    egwVecCopy3f(&(mesh_in->vkCoords[(mesh_in->vCount * frameOffset) + mesh_in->fIndicies[faceIndex].face.i1]), &(mesh_out->vkCoords[(mesh_out->vCount * frameOffset) + vertexIndex+0]));
                    egwVecCopy3f(&(mesh_in->vkCoords[(mesh_in->vCount * frameOffset) + mesh_in->fIndicies[faceIndex].face.i2]), &(mesh_out->vkCoords[(mesh_out->vCount * frameOffset) + vertexIndex+1]));
                    egwVecCopy3f(&(mesh_in->vkCoords[(mesh_in->vCount * frameOffset) + mesh_in->fIndicies[faceIndex].face.i3]), &(mesh_out->vkCoords[(mesh_out->vCount * frameOffset) + vertexIndex+2]));
                }
            }
            if(mesh_in->nkCoords && mesh_out->nkCoords) {
                for(EGWint frameOffset = 0; frameOffset < (mesh_in->nfCount ? mesh_in->nfCount : 1); ++frameOffset) {
                    egwVecCopy3f(&(mesh_in->nkCoords[(mesh_in->vCount * frameOffset) + mesh_in->fIndicies[faceIndex].face.i1]), &(mesh_out->nkCoords[(mesh_out->vCount * frameOffset) + vertexIndex+0]));
                    egwVecCopy3f(&(mesh_in->nkCoords[(mesh_in->vCount * frameOffset) + mesh_in->fIndicies[faceIndex].face.i2]), &(mesh_out->nkCoords[(mesh_out->vCount * frameOffset) + vertexIndex+1]));
                    egwVecCopy3f(&(mesh_in->nkCoords[(mesh_in->vCount * frameOffset) + mesh_in->fIndicies[faceIndex].face.i3]), &(mesh_out->nkCoords[(mesh_out->vCount * frameOffset) + vertexIndex+2]));
                }
            }
            if(mesh_in->tkCoords && mesh_out->tkCoords) {
                for(EGWint frameOffset = 0; frameOffset < (mesh_in->tfCount ? mesh_in->tfCount : 1); ++frameOffset) {
                    egwVecCopy2f(&(mesh_in->tkCoords[(mesh_in->vCount * frameOffset) + mesh_in->fIndicies[faceIndex].face.i1]), &(mesh_out->tkCoords[(mesh_out->vCount * frameOffset) + vertexIndex+0]));
                    egwVecCopy2f(&(mesh_in->tkCoords[(mesh_in->vCount * frameOffset) + mesh_in->fIndicies[faceIndex].face.i2]), &(mesh_out->tkCoords[(mesh_out->vCount * frameOffset) + vertexIndex+1]));
                    egwVecCopy2f(&(mesh_in->tkCoords[(mesh_in->vCount * frameOffset) + mesh_in->fIndicies[faceIndex].face.i3]), &(mesh_out->tkCoords[(mesh_out->vCount * frameOffset) + vertexIndex+2]));
                }
            }
        }
        
        return mesh_out;
    }
    
    return NULL;
}

egwKFDITVAMeshf* egwMeshConvertKFJITVAfKFDITVAf(const egwKFJITVAMeshf* mesh_in, egwKFDITVAMeshf* mesh_out) {
    egwKFTVAMeshf temp; memset((void*)&temp, 0, sizeof(egwKFTVAMeshf));
    
    if(egwMeshConvertKFJITVAfKFTVAf(mesh_in, &temp) && egwMeshConvertKFTVAfKFDITVAf(&temp, mesh_out)) {
        egwMeshFreeKFTVAf(&temp);
        return mesh_out;
    }
    
    egwMeshFreeKFTVAf(&temp);
    return NULL;
}

egwKFTVAMeshf* egwMeshConvertKFDITVAfKFTVAf(const egwKFDITVAMeshf* mesh_in, egwKFTVAMeshf* mesh_out) {
    if(egwMeshAllocKFTVAf(mesh_out, (mesh_in->vkCoords ? mesh_in->fCount * 3 : 0), (mesh_in->nkCoords ? mesh_in->fCount * 3 : 0), (mesh_in->tkCoords ? mesh_in->fCount * 3 : 0), mesh_in->vfCount, mesh_in->nfCount, mesh_in->tfCount)) {
        for(EGWint faceIndex = 0, vertexIndex = 0; faceIndex < mesh_in->fCount && vertexIndex < mesh_out->vCount; ++faceIndex, vertexIndex += 3) {
            if(mesh_in->vkCoords && mesh_out->vkCoords) {
                for(EGWint frameOffset = 0; frameOffset < (mesh_in->vfCount ? mesh_in->vfCount : 1); ++frameOffset) {
                    egwVecCopy3f(&(mesh_in->vkCoords[(mesh_in->vCount * frameOffset) + mesh_in->fIndicies[faceIndex].face.iv1]), &(mesh_out->vkCoords[(mesh_out->vCount * frameOffset) + vertexIndex+0]));
                    egwVecCopy3f(&(mesh_in->vkCoords[(mesh_in->vCount * frameOffset) + mesh_in->fIndicies[faceIndex].face.iv2]), &(mesh_out->vkCoords[(mesh_out->vCount * frameOffset) + vertexIndex+1]));
                    egwVecCopy3f(&(mesh_in->vkCoords[(mesh_in->vCount * frameOffset) + mesh_in->fIndicies[faceIndex].face.iv3]), &(mesh_out->vkCoords[(mesh_out->vCount * frameOffset) + vertexIndex+2]));
                }
            }
            if(mesh_in->nkCoords && mesh_out->nkCoords) {
                for(EGWint frameOffset = 0; frameOffset < (mesh_in->nfCount ? mesh_in->nfCount : 1); ++frameOffset) {
                    egwVecCopy3f(&(mesh_in->nkCoords[(mesh_in->nCount * frameOffset) + mesh_in->fIndicies[faceIndex].face.in1]), &(mesh_out->nkCoords[(mesh_out->vCount * frameOffset) + vertexIndex+0]));
                    egwVecCopy3f(&(mesh_in->nkCoords[(mesh_in->nCount * frameOffset) + mesh_in->fIndicies[faceIndex].face.in2]), &(mesh_out->nkCoords[(mesh_out->vCount * frameOffset) + vertexIndex+1]));
                    egwVecCopy3f(&(mesh_in->nkCoords[(mesh_in->nCount * frameOffset) + mesh_in->fIndicies[faceIndex].face.in3]), &(mesh_out->nkCoords[(mesh_out->vCount * frameOffset) + vertexIndex+2]));
                }
            }
            if(mesh_in->tkCoords && mesh_out->tkCoords) {
                for(EGWint frameOffset = 0; frameOffset < (mesh_in->tfCount ? mesh_in->tfCount : 1); ++frameOffset) {
                    egwVecCopy2f(&(mesh_in->tkCoords[(mesh_in->tCount * frameOffset) + mesh_in->fIndicies[faceIndex].face.it1]), &(mesh_out->tkCoords[(mesh_out->vCount * frameOffset) + vertexIndex+0]));
                    egwVecCopy2f(&(mesh_in->tkCoords[(mesh_in->tCount * frameOffset) + mesh_in->fIndicies[faceIndex].face.it2]), &(mesh_out->tkCoords[(mesh_out->vCount * frameOffset) + vertexIndex+1]));
                    egwVecCopy2f(&(mesh_in->tkCoords[(mesh_in->tCount * frameOffset) + mesh_in->fIndicies[faceIndex].face.it3]), &(mesh_out->tkCoords[(mesh_out->vCount * frameOffset) + vertexIndex+2]));
                }
            }
        }
        
        return mesh_out;
    }
    
    return NULL;
}

egwKFJITVAMeshf* egwMeshConvertKFDITVAfKFJITVAf(const egwKFDITVAMeshf* mesh_in, egwKFJITVAMeshf* mesh_out) {
    egwKFTVAMeshf temp; memset((void*)&temp, 0, sizeof(egwKFTVAMeshf));
    
    if(egwMeshConvertKFDITVAfKFTVAf(mesh_in, &temp) && egwMeshConvertKFTVAfKFJITVAf(&temp, mesh_out)) {
        egwMeshFreeKFTVAf(&temp);
        return mesh_out;
    }
    
    egwMeshFreeKFTVAf(&temp);
    return NULL;
}
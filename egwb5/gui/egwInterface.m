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

/// @file egwInterface.m
/// @ingroup geWizES_gui_interface
/// Base GUI Implementation.

#import "egwInterface.h"
#import "../math/egwMath.h"
#import "../math/egwVector.h"
#import "../gfx/egwGraphics.h"


void egwWdgtMeshBVInit(egwSQVAMesh4f* mcsMesh_out, id<egwPBounding> mcsVolume_out, BOOL alphaExtended_in, egwSize2i* widgetSize_in, egwSize2i* surfaceSize_in) {
    // NOTE: FP error in the texture coordinates potentially causes distortions on render -> fix to surfaces with an alpha extend use all their UV offsetting to draw. -jw
    // NOTE: The MCS widget layout is always direct center zero aligned with half widget widths on -XL to +XR and half widget heights on -YB to +YT -> this vertex set should _NEVER_ be directly transformed. -jw
    // NOTE: Fancy footwork to have the volume init by widget size, but if alpha extended mesh has to tack on remaining image size. -jw
    // 3 -- 2     +
    // |SQVA| -,+ ,
    // 0 -- 1     -
    
    {   EGWsingle halfWidth = (EGWsingle)widgetSize_in->span.width * 0.5f;
        EGWsingle halfHeight = (EGWsingle)widgetSize_in->span.height * 0.5f;
        
        mcsMesh_out->vCoords[0].axis.x = mcsMesh_out->vCoords[3].axis.x = -halfWidth;
        mcsMesh_out->vCoords[1].axis.x = mcsMesh_out->vCoords[2].axis.x =  halfWidth;
        mcsMesh_out->vCoords[2].axis.y = mcsMesh_out->vCoords[3].axis.y =  halfHeight;
        mcsMesh_out->vCoords[0].axis.y = mcsMesh_out->vCoords[1].axis.y = -halfHeight;
        mcsMesh_out->vCoords[0].axis.z = mcsMesh_out->vCoords[1].axis.z = mcsMesh_out->vCoords[2].axis.z =
            mcsMesh_out->vCoords[3].axis.z = 0.0f;
        
        [mcsVolume_out initWithOpticalSource:&egwSIVecZero3f vertexCount:4 vertexCoords:(const egwVector3f*)&mcsMesh_out->vCoords[0] vertexCoordsStride:0];
        
        if(alphaExtended_in && widgetSize_in->span.width != surfaceSize_in->span.width)
            mcsMesh_out->vCoords[1].axis.x = mcsMesh_out->vCoords[2].axis.x = halfWidth + (EGWsingle)(surfaceSize_in->span.width - widgetSize_in->span.width);
        
        if(alphaExtended_in && widgetSize_in->span.height != surfaceSize_in->span.height)
            mcsMesh_out->vCoords[0].axis.y = mcsMesh_out->vCoords[1].axis.y = -halfHeight - (EGWsingle)(surfaceSize_in->span.height - widgetSize_in->span.height);
    }
    
    if(alphaExtended_in || widgetSize_in->span.width == surfaceSize_in->span.width) {
        mcsMesh_out->tCoords[0].axis.x = mcsMesh_out->tCoords[3].axis.x = 0.0f;
        mcsMesh_out->tCoords[1].axis.x = mcsMesh_out->tCoords[2].axis.x = 1.0f;
    } else {
        mcsMesh_out->tCoords[0].axis.x = mcsMesh_out->tCoords[3].axis.x = 0.0f;
        mcsMesh_out->tCoords[1].axis.x = mcsMesh_out->tCoords[2].axis.x = (EGWsingle)egwClamp01d(((EGWdouble)widgetSize_in->span.width / (EGWdouble)surfaceSize_in->span.width) - (EGWdouble)EGW_WIDGET_TXCCORRECT);
    }
    
    if(alphaExtended_in || widgetSize_in->span.height == surfaceSize_in->span.height) {
        mcsMesh_out->tCoords[2].axis.y = mcsMesh_out->tCoords[3].axis.y = 0.0f;
        mcsMesh_out->tCoords[0].axis.y = mcsMesh_out->tCoords[1].axis.y = 1.0f;
    } else {
        mcsMesh_out->tCoords[2].axis.y = mcsMesh_out->tCoords[3].axis.y = 0.0f;
        mcsMesh_out->tCoords[0].axis.y = mcsMesh_out->tCoords[1].axis.y = (EGWsingle)egwClamp01d(((EGWdouble)widgetSize_in->span.height / (EGWdouble)surfaceSize_in->span.height) - (EGWdouble)EGW_WIDGET_TXCCORRECT);
    }
    
    mcsMesh_out->nCoords[0].axis.x = mcsMesh_out->nCoords[0].axis.y = mcsMesh_out->nCoords[1].axis.x =
        mcsMesh_out->nCoords[1].axis.y = mcsMesh_out->nCoords[2].axis.x = mcsMesh_out->nCoords[2].axis.y =
        mcsMesh_out->nCoords[3].axis.x = mcsMesh_out->nCoords[3].axis.y = 0.0f;
    mcsMesh_out->nCoords[0].axis.z = mcsMesh_out->nCoords[1].axis.z = mcsMesh_out->nCoords[2].axis.z =
        mcsMesh_out->nCoords[3].axis.z = 1.0f;
}

void egwWdgtSFrmtTexOffset(const egwSurfaceFraming* sFrame_in, const EGWuint16 fIndex_in, egwVector2f* tCoords_out) {
    register EGWuint16 offset = fIndex_in - sFrame_in->fOffset;
    register EGWuint16 hOffset = offset % sFrame_in->hFrames;
    register EGWuint16 vOffset = offset / sFrame_in->hFrames;
    tCoords_out[0].axis.x = tCoords_out[3].axis.x = (EGWsingle)egwClamp01d(((EGWdouble)hOffset * sFrame_in->htSizer) + (EGWdouble)EGW_WIDGET_TXCCORRECT);
    tCoords_out[1].axis.x = tCoords_out[2].axis.x = (EGWsingle)egwClamp01d(((EGWdouble)(hOffset + 1) * sFrame_in->htSizer) - (EGWdouble)EGW_WIDGET_TXCCORRECT);
    tCoords_out[2].axis.y = tCoords_out[3].axis.y = (EGWsingle)egwClamp01d(((EGWdouble)vOffset * sFrame_in->vtSizer) + (EGWdouble)EGW_WIDGET_TXCCORRECT);
    tCoords_out[0].axis.y = tCoords_out[1].axis.y = (EGWsingle)egwClamp01d(((EGWdouble)(vOffset + 1) * sFrame_in->vtSizer) - (EGWdouble)EGW_WIDGET_TXCCORRECT);
}

EGWuint egwWdgtMinFSprtSrfcCount(const egwSize2i* widgetSize_in, const egwSize2i* maxSize_in, const EGWuint16 fCount_in) {
    EGWuint maxFrmPerSrfc = (EGWuint)(maxSize_in->span.width / widgetSize_in->span.width) * (EGWuint)(maxSize_in->span.height / widgetSize_in->span.height);
    return ((EGWuint)fCount_in + (maxFrmPerSrfc - 1)) / maxFrmPerSrfc; // ceil(fCount/maxFrmPerSrfc)
}

EGWuint egwWdgtOptPow2FSprtSfrcSize(const egwSize2i* widgetSize_in, const egwSize2i* maxSize_in, const EGWuint16 fCount_in, egwSize2i* bestSize_out) {
    EGWuint16 maxCols = maxSize_in->span.width / widgetSize_in->span.width;
    EGWuint16 maxRows = maxSize_in->span.height / widgetSize_in->span.height;
    
    if((EGWuint)fCount_in < (EGWuint)maxCols * (EGWuint)maxRows) {
        EGWuint16 bestCols, bestRows, currCols, currRows;
        EGWuint bestLeftOver, currLeftOver, stdUsage;
        
        stdUsage = (EGWuint)fCount_in * ((EGWuint)widgetSize_in->span.width * (EGWuint)widgetSize_in->span.height);
        
        bestCols = currCols = maxCols;
        bestRows = currRows = (fCount_in + (currCols - 1)) / currCols; // ceil(fCount/currCols)
        bestLeftOver = currLeftOver = (egwRoundUpPow2ui((EGWuint)currCols * (EGWuint)widgetSize_in->span.width) *
                                       egwRoundUpPow2ui((EGWuint)currRows * (EGWuint)widgetSize_in->span.height)) - stdUsage;
        
        while(currCols > 1 && currRows <= maxRows) {
            --currCols;
            currRows = (fCount_in + (currCols - 1)) / currCols; // ceil(fCount/currCols)
            
            if(currRows <= maxRows) {
                currLeftOver = (egwRoundUpPow2ui((EGWuint)currCols * (EGWuint)widgetSize_in->span.width) *
                                egwRoundUpPow2ui((EGWuint)currRows * (EGWuint)widgetSize_in->span.height)) - stdUsage;
                
                if(currLeftOver < bestLeftOver ||
                   (currLeftOver == bestLeftOver && egwAbsi((EGWint)currCols - (EGWint)currRows) <= egwAbsi((EGWint)bestCols - (EGWint)bestRows))) {
                    bestCols = currCols;
                    bestRows = currRows;
                    bestLeftOver = currLeftOver;
                }
            }
        }
        
        bestSize_out->span.width = bestCols * widgetSize_in->span.width;
        bestSize_out->span.height = bestRows * widgetSize_in->span.height;
        return (EGWuint)bestCols * (EGWuint)bestRows;
    } else if(maxCols && maxRows) {
        bestSize_out->span.width = maxSize_in->span.width;
        bestSize_out->span.height = maxSize_in->span.height;
        return (EGWuint)maxCols * (EGWuint)maxRows;
    } else { // too big for even 1 sprite
        bestSize_out->span.width = 0;
        bestSize_out->span.height = 0;
        return 0;
    }
}

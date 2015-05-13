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

/// @defgroup geWizES_gui_interface egwInterface
/// @ingroup geWizES_gui
/// Base GUI.
/// @{

/// @file egwInterface.h
/// Base GUI Interface.

#import "egwGuiTypes.h"
#import "../inf/egwPBounding.h"
#import "../gfx/egwGfxTypes.h"


// !!!: ***** Helper Routines *****

/// Widget Mesh & Bounding Volume Initialization Routine.
/// Initializes a standard rectangular widget mesh and bounding volume using the provided parameters.
/// @param [out] mcsMesh_out Widget mesh structure.
/// @param [out] mcsVolume_out Widget bounding volume.
/// @param [in] alphaExtended_in Boolean that determines whenever the created mesh/bounding can be alpha extended to the next power-of-2 sizing.
/// @param [in] widgetSize_in Size of the widget.
/// @param [in] surfaceSize_in Size of the containing image surface.
void egwWdgtMeshBVInit(egwSQVAMesh4f* mcsMesh_out, id<egwPBounding> mcsVolume_out, BOOL alphaExtended_in, egwSize2i* widgetSize_in, egwSize2i* surfaceSize_in);

/// Widget Surface Framing Texture Offset Routine.
/// Calculates the appropriate texture coordinate offset of a surface framing given the provided parameters.
/// @param [in] sFrame_in Surface framing structure.
/// @param [in] fIndex_in Frame index (should be a valid member of the surface framing).
/// @param [out] tCoords_out Texture coordinate offset.
void egwWdgtSFrmtTexOffset(const egwSurfaceFraming* sFrame_in, const EGWuint16 fIndex_in, egwVector2f* tCoords_out);

/// Widget Minimum Frame Sprite Surfaces Count Routine.
/// Calculates the number of surfaces required to store the number of frames for a sprited rectangular widget given the provided parameters.
/// @param [in] widgetSize_in Size of the widget.
/// @param [in] maxSize_in Maximum size of surface.
/// @param [in] fCount_in Number of frames.
/// @return Number of surfaces.
EGWuint egwWdgtMinFSprtSrfcCount(const egwSize2i* widgetSize_in, const egwSize2i* maxSize_in, const EGWuint16 fCount_in);

/// Widget Optimum Power-of-2 Framed Sprited Surface Size Routine.
/// Calculates the optimum power-of-2 sized surface for a sprited rectangular widget given the provided paramters.
/// @param [in] widgetSize_in Size of the widget.
/// @param [in] maxSize_in Maximum size of surface.
/// @param [in] fCount_in Number of frames.
/// @param [out] bestSize_out Optimum size of surface.
/// @return Maximum number of frames available on calculated surface size.
EGWuint egwWdgtOptPow2FSprtSfrcSize(const egwSize2i* widgetSize_in, const egwSize2i* maxSize_in, const EGWuint16 fCount_in, egwSize2i* bestSize_out);

/// @}

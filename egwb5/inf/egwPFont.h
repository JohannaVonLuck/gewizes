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

/// @defgroup geWizES_inf_pfont egwPFont
/// @ingroup geWizES_inf
/// Font Protocol.
/// @{

/// @file egwPFont.h
/// Font Protocol.

#import "egwTypes.h"
#import "../inf/egwPAsset.h"
#import "../math/egwMathTypes.h"
#import "../gfx/egwGfxTypes.h"


/// Font Protocol.
/// Defines interactions for fonts.
@protocol egwPFont <NSObject>

/// Calculate Text (renderSize) Method.
/// Calculates the resultant width and height @a size of provided C-style @a text string.
/// @param [in] text C-style text string.
/// @param [out] size Calculated render width & height.
- (void)calculateString:(const EGWchar*)text renderSize:(egwSize2i*)size;

/// Calculate Text (renderSize) Method.
/// Calculates the resultant width and height @a size of provided unicode @a text string.
/// @param [in] text Text string.
/// @param [out] size Calculated render width & height.
- (void)calculateText:(NSString*)text renderSize:(egwSize2i*)size;

/// Render C-Style String (toSurfaceAtCursor) Method.
/// Renders provided C-style @a text string onto @a surface at provided @a cursor position.
/// @param [in] text C-style text string.
/// @param [in,out] surface Rendering surface.
/// @param [in] cursor Cursor start position (down flow). May be NULL (for <0,0>).
- (void)renderString:(const EGWchar*)text toSurface:(egwSurface*)surface atCursor:(egwPoint2i*)cursor;

/// Render Text (toSurfaceAtCursor) Method.
/// Renders provided unicode @a text string onto @a surface at provided @a cursor position.
/// @param [in] text Text string.
/// @param [in,out] surface Rendering surface.
/// @param [in] cursor Cursor start position (down flow). May be NULL (for <0,0>).
- (void)renderText:(NSString*)text toSurface:(egwSurface*)surface atCursor:(egwPoint2i*)cursor;

@end

/// @}

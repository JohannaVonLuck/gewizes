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

/// @defgroup geWizES_hwd_nsopenglviewsurface egwNSOpenGLViewSurface
/// @ingroup geWizES_hwd
/// NS OpenGL View Surface.
/// @{

/// @file egwNSOpenGLViewSurface.h
/// NS OpenGL View Surface Interface.

#if defined(EGW_BUILDMODE_COCOA) || defined(EGW_BUILDMODE_GNUSTEP)

#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>
#import "egwHwdTypes.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPTask.h"
#import "../sys/egwGfxContext.h"
#import "../sys/egwGfxRenderer.h"


/// NSView Surface Mouse Event Delegate.
/// Contains mouse event methods that a delegate object can handle.
@protocol egwDNSViewSurfaceMouseEvent <NSObject>
@end

/// NSView Surface Keyboard Event Delegate.
/// Contains keyboard event methods that a delegate object can handle.
@protocol egwDNSViewSurfaceKeyboardEvent <NSObject>
@end


/// NS OpenGL View Surface.
/// This class provides a graphics context interfaced NSOpenGLView object for the Cocoa/GNUstep AppKit.
@interface egwNSOpenGLViewSurface : NSOpenGLView {
    id<egwDNSViewSurfaceMouseEvent> _mDelegate;     ///< Mouse event responder.
    id<egwDNSViewSurfaceKeyboardEvent> _kDelegate;  ///< Keyboard event responder.
    
    egwGfxContextNSGL* _gfxContext;         ///< Owned graphics context (retained).
    
    EGWuint16 _width;                       ///< Width of view surface (pixels).
    EGWuint16 _height;                      ///< Height of view surface (pixels).
    BOOL _autoresize;                       ///< Automatic context resize.
}

/// Backwards Initializer.
/// Initializes surface with provided settings.
/// @param [in] frame Frame bounds of surface on parent view.
/// @param [in] format An NSOpenGLPixelFormat object.
/// @note Avoid calling this method if possible. It is used primarily for backwards compatibility, but some settings are mutually exclusive.
/// @return Self upon success, otherwise nil.
- (id)initWithFrame:(NSRect)frame pixelFormat:(NSOpenGLPixelFormat*)format;

/// Designated Initializer.
/// Initializes surface with provided settings.
/// @param [in] frame Frame bounds of surface on parent view.
/// @param [in] params Context parameters structure.
/// @return Self upon success, otherwise nil.
- (id)initWithFrame:(NSRect)frame contextParams:(void*)params;


/// Associated egwGfxContext Accessor.
/// Returns the associated egwGfxContext object owned by this view.
/// @return Owned egwGfxContext object.
- (egwGfxContextNSGL*)associatedGfxContext;

/// View Surface Width.
/// Returns the surface width of this view.
/// @return View surface width.
- (EGWuint16)surfaceWidth;

/// View Surface Height.
/// Returns the surface height of this view.
/// @return View surface height.
- (EGWuint16)surfaceHeight;


- (void)setMouseDelegate:(id<egwDNSViewSurfaceMouseEvent>)delegate;

- (void)setKeyboardDelegate:(id<egwDNSViewSurfaceKeyboardEvent>)delegate;


/// Convert NSOpenGLPixelFormat to egwGfxCntxParams Trier.
/// Converts the pixel format object described by @a format to an associated @a params parameters structure.
/// @param [in] format An NSOpenGLPixelFormat object.
/// @param [out] params An egwGfxCntxParams structure.
/// @return YES upon successful conversion, otherwise NO.
/// @note This method assumes @a cntxParams is already zero'ed out.
//+ (BOOL)tryConvertNSGLPixelFormat:(NSOpenGLPixelFormat*)format toGfxCntxParams:(egwGfxCntxParams*)params;

/// Convert NSOpenGLPixelFormat to egwGfxCntxParams Trier.
/// Converts the parameters structure described by @a params to a newly allocated @a format pixel format object.
/// @param [in] params An egwGfxCntxParams structure.
/// @param [out] format An NSOpenGLPixelFormat object.
/// @return YES upon successful conversion, otherwise NO.
/// @note This method assumes @a format is not already allocated.
//+ (BOOL)tryConvertGfxCntxParams:(egwGfxCntxParams*)params toNSGLPixelFormat:(NSOpenGLPixelFormat**)format;

@end

#endif

/// @}

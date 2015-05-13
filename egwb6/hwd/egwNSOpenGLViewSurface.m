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

/// @file egwNSOpenGLViewSurface.m
/// @ingroup geWizES_hwd_nsopenglviewsurface
/// NS OpenGL View Surface Interface Implementation.

#if defined(EGW_BUILDMODE_COCOA) || defined(EGW_BUILDMODE_GNUSTEP)

#import "egwNSOpenGLViewSurface.h"


@interface egwNSOpenGLViewSurface (Private)
- (BOOL)initSurfaceWithPixelFormat:(NSOpenGLPixelFormat*)format contextParams:(egwGfxCntxParams*)gfxParams;
@end


@implementation egwNSOpenGLViewSurface

- (id)initWithFrame:(NSRect)frame pixelFormat:(NSOpenGLPixelFormat*)format {
    // TODO
}

- (id)initWithFrame:(NSRect)frame contextParams:(void*)params {
    // TODO
}

- (void)dealloc {
    [_mDelegate release]; _mDelegate = nil;
    [_kDelegate release]; _kDelegate = nil;
    
    [_gfxContext release]; _gfxContext = nil;
    
    [super dealloc];
}

- (void)drawRect:(CGRect)rect {
    //[super drawRect:rect]; // does nothing
}

- (egwGfxContextNSGL*)associatedGfxContext {
    return _gfxContext;
}

- (EGWuint16)surfaceWidth {
    return _width;
}

- (EGWuint16)surfaceHeight {
    return _height;
}

- (void)setMouseDelegate:(id<egwDNSViewSurfaceMouseEvent>)delegate {
    if(_mDelegate != delegate) {
        [delegate retain];
        [_mDelegate release];
        _mDelegate = delegate;
    }
}

- (void)setKeyboardDelegate:(id<egwDNSViewSurfaceKeyboardEvent>)delegate {
    if(_kDelegate != delegate) {
        [delegate retain];
        [_kDelegate release];
        _kDelegate = delegate;
    }
}

@end


@implementation egwNSOpenGLViewSurface (Private)

- (BOOL)initSurfaceWithPixelFormat:(NSOpenGLPixelFormat*)format contextParams:(egwGfxCntxParams*)gfxParams {
}

@end

#endif

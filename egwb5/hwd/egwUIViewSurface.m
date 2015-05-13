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

/// @file egwUIViewSurface.m
/// @ingroup geWizES_hwd_uiviewsurface
/// iPhone UI View Surface Implementation.

#if defined(EGW_BUILDMODE_IPHONE)

#import "egwUIViewSurface.h"


@interface egwUIViewSurface (Private)
- (BOOL)initSurfaceWithContextParams:(egwGfxCntxParams*)gfxParams;
@end


@implementation egwUIViewSurface

#if !(__IPHONE_OS_VERSION_MIN_REQUIRED >= 40000)
@synthesize contentScaleFactor = _scale;
#endif

- (id)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame contentScale:1.0 contextParams:nil];
}

- (id)initWithFrame:(CGRect)frame contentScale:(CGFloat)scale {
    return [self initWithFrame:frame contentScale:scale contextParams:nil];
}

- (id)initWithFrame:(CGRect)frame contextParams:(void*)params {
    return [self initWithFrame:frame contentScale:1.0 contextParams:params];
}

- (id)initWithFrame:(CGRect)frame contentScale:(CGFloat)scale contextParams:(void*)params {
    egwGfxCntxParams* gfxParams = (egwGfxCntxParams*)params;
    
    if(!([super initWithFrame:frame])) { goto ErrorCleanup; }
    
    if(!gfxParams && !(gfxParams = malloc(sizeof(egwGfxCntxParams)))) { goto ErrorCleanup; }
    
    _width = (EGWuint16)frame.size.width;
    _height = (EGWuint16)frame.size.height;
    if(gfxParams->fbWidth == 0) gfxParams->fbWidth = _width;
    if(gfxParams->fbHeight == 0) gfxParams->fbHeight = _height;
    
    self.contentScaleFactor = _scale = scale;
    
    if(![self initSurfaceWithContextParams:gfxParams]) { goto ErrorCleanup; }
    
    if(!(_gfxContext = [[egwSIEngine createGfxContext:(id)gfxParams] retain])) { goto ErrorCleanup; }
    
    if((id)gfxParams != params) {
        free((void*)gfxParams);
        gfxParams = NULL;
    }
    return self;
    
ErrorCleanup:
    if((id)gfxParams != params) {
        free((void*)gfxParams);
        gfxParams = NULL;
    }
    [self release]; return (self = nil);
}

- (void)dealloc {
    if(_rcvAccel > 0.0 && [UIAccelerometer sharedAccelerometer].delegate == self) {
        [UIAccelerometer sharedAccelerometer].updateInterval = DBL_MAX;
        [UIAccelerometer sharedAccelerometer].delegate = nil;
    }
    
    [_tDelegate release]; _tDelegate = nil;
    [_aDelegate release]; _aDelegate = nil;
    
    [_gfxContext release]; _gfxContext = nil;
    
    [super dealloc];
}

//- (void)drawRect:(CGRect)rect {
    //[super drawRect:rect]; // does nothing
//}

- (void)layoutSubviews {
	/*CGRect bounds = [self bounds];
    EGWuint16 width = (EGWuint16)bounds.size.width;
    EGWuint16 height = (EGWuint16)bounds.size.height;
    
    if(_autoresize) {
        if(![egwAIGfxCntx resizeBufferWidth:width bufferHeight:height]) {
            NSLog(@"egwUIViewSurface: layoutSubviews: Failure resizing context buffers to %dx%d.", width, height);
        } else {
            _width = width;
            _height = height;
        }
    }*/
	
    //[super layoutSubviews]; // does nothing
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    [_tDelegate touchesBegan:touches withEvent:event inView:(UIView*)self];
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
    [_tDelegate touchesCancelled:touches withEvent:event inView:(UIView*)self];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
    [_tDelegate touchesEnded:touches withEvent:event inView:(UIView*)self];
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
    [_tDelegate touchesMoved:touches withEvent:event inView:(UIView*)self];
}

- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration {
    [_aDelegate accelerometer:accelerometer didAccelerate:acceleration];
}

- (NSTimeInterval)accelerometerUpdateFrequency {
    return _rcvAccel;
}

- (egwGfxContextEAGLES*)associatedGfxContext {
    return _gfxContext;
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (EGWuint16)surfaceWidth {
    return _width;
}

- (EGWuint16)surfaceHeight {
    return _height;
}

- (void)setTouchDelegate:(id<egwDUIViewSurfaceTouchEvent>)delegate {
    if(_tDelegate != delegate) {
        [delegate retain];
        [_tDelegate release];
        _tDelegate = delegate;
    }
}

- (void)setMultipleTouchEnabled:(BOOL)enable {
    [super setMultipleTouchEnabled:enable];
}

- (void)setAccelerometerDelegate:(id<egwDUIViewSurfaceAccelerometerEvent>)delegate {
    if(_aDelegate != delegate) {
        [delegate retain];
        [_aDelegate release];
        _aDelegate = delegate;
    }
}

- (void)setAccelerometerUpdateFrequency:(NSTimeInterval)interval {
    if(interval > 0.0) {
        if([UIAccelerometer sharedAccelerometer].delegate != self)
            [UIAccelerometer sharedAccelerometer].delegate = self;
        [UIAccelerometer sharedAccelerometer].updateInterval = interval;
    } else {
        if([UIAccelerometer sharedAccelerometer].delegate == self) {
            [UIAccelerometer sharedAccelerometer].updateInterval = DBL_MAX;
            [UIAccelerometer sharedAccelerometer].delegate = nil;
        }
    }
}

@end


@implementation egwUIViewSurface (Private)

- (BOOL)initSurfaceWithContextParams:(egwGfxCntxParams*)gfxParams {
    CAEAGLLayer* surface;
    NSNumber* retainedBacking;
    NSString* colorFormat;
    NSDictionary* surfaceProps;
    
    _rcvAccel = 0.0;
    
    if(!(surface = (CAEAGLLayer*)[self layer])) { return NO; }
    else gfxParams->contextData = (id)surface;
    
    // Translate the context options into the EAGL surface options.
    
    // Framebuffer format (only 16, 32 supported)
    if(gfxParams->fbDepth != 0) {
        if(gfxParams->fbDepth == 16)        colorFormat = kEAGLColorFormatRGB565;
        else if(gfxParams->fbDepth == 24) { NSLog(@"egwUIViewSurface: initSurfaceWithContextParams: Framebuffer depth not supported, bumping up to 32bpp.");
            gfxParams->fbDepth = 32; // not really supported...
            colorFormat = kEAGLColorFormatRGBA8; }
        else if(gfxParams->fbDepth == 32)   colorFormat = kEAGLColorFormatRGBA8;
        else {
            NSLog(@"egwUIViewSurface: initSurfaceWithContextParams: Framebuffer depth not supported.");
            return NO;
        }
    } else
        colorFormat = kEAGLColorFormatRGB565;
    
    // Retain the backing (e.g. !clear)
    if(gfxParams->fbClear != 0) {
        if(gfxParams->fbClear == -1)        retainedBacking = [[NSNumber alloc] initWithBool:YES];
        else if(gfxParams->fbClear == 1)    retainedBacking = [[NSNumber alloc] initWithBool:NO];
        else {
            NSLog(@"egwUIViewSurface: initSurfaceWithContextParams: Clear flag not supported.");
            return NO;
        }
    } else
        retainedBacking = [[NSNumber alloc] initWithBool:YES];
    
    // Autoresize boolean
    if(gfxParams->fbResize != 0) {
        if(gfxParams->fbResize == -1)      _autoresize = NO;
        else if(gfxParams->fbResize == 1)  _autoresize = YES;
        else {
            NSLog(@"egwUIViewSurface: initSurfaceWithContextParams: Resize flag not supported.");
            [retainedBacking release]; return NO;
        }
    } else
        _autoresize = YES;
    
    // Set the EAGL surface to the properties defined.
    
    if(!(surfaceProps = [[NSDictionary alloc] initWithObjectsAndKeys:
                         retainedBacking, kEAGLDrawablePropertyRetainedBacking,
                         colorFormat, kEAGLDrawablePropertyColorFormat,
                         nil])) { [retainedBacking release]; return NO; }
    
    surface.drawableProperties = surfaceProps;
    
    [surfaceProps release];
    [retainedBacking release];
    
    return YES;
}

@end

#endif

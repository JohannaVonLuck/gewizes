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

/// @defgroup geWizES_hwd_uiviewsurface egwUIViewSurface
/// @ingroup geWizES_hwd
/// iPhone UI View Surface.
/// @{

/// @file egwUIViewSurface.h
/// iPhone UI View Surface Interface.

#if defined(EGW_BUILDMODE_IPHONE)

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import "egwHwdTypes.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPTask.h"
#import "../sys/egwGfxContext.h"
#import "../sys/egwGfxRenderer.h"


/// UIView Surface Touch Event Delegate.
/// Contains touch event methods that a delegate object can handle.
@protocol egwDUIViewSurfaceTouchEvent <NSObject>
@optional
- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event inView:(UIView*)view;
- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event inView:(UIView*)view;
- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event inView:(UIView*)view;
- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event inView:(UIView*)view;
@end

/// UIView Surface Accelerometer Event Delegate.
/// Contains accelerometer event methods that a delegate object can handle.
@protocol egwDUIViewSurfaceAccelerometerEvent <NSObject>
@optional
- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration;
@end


/// iPhone UI View Surface.
/// This class provides a graphics context interfaced UIView object for the iPhone UIKit.
@interface egwUIViewSurface : UIView <UIAccelerometerDelegate> {
    id<egwDUIViewSurfaceTouchEvent> _tDelegate;         ///< Touch event responder.
    id<egwDUIViewSurfaceAccelerometerEvent> _aDelegate; ///< Accelerometer event responder.
    
    egwGfxContextEAGLES* _gfxContext;       ///< Owned graphics context (retained).
    
    EGWuint16 _width;                       ///< Width of view surface (pixels).
    EGWuint16 _height;                      ///< Height of view surface (pixels).
    CGFloat _scale;                         ///< Content scale factor.
    BOOL _autoresize;                       ///< Automatic context resize.
    
    NSTimeInterval _rcvAccel;               ///< Accelerometer update interval.
}

#if !(__IPHONE_OS_VERSION_MIN_REQUIRED >= 40000)
@property CGFloat contentScaleFactor;
#endif

/// Initializer.
/// Initializes surface with provided settings.
/// @param [in] frame Frame bounds of surface on parent view.
/// @return Self upon success, otherwise nil.
- (id)initWithFrame:(CGRect)frame;

/// Initializer.
/// Initializes surface with provided settings.
/// @param [in] frame Frame bounds of surface on parent view.
/// @param [in] scale Content scale factor.
/// @return Self upon success, otherwise nil.
- (id)initWithFrame:(CGRect)frame contentScale:(CGFloat)scale;

/// Initializer.
/// Initializes surface with provided settings.
/// @param [in] frame Frame bounds of surface on parent view.
/// @param [in] params Context parameters structure.
/// @return Self upon success, otherwise nil.
- (id)initWithFrame:(CGRect)frame contextParams:(void*)params;

/// Designated Initializer.
/// Initializes surface with provided settings.
/// @param [in] frame Frame bounds of surface on parent view.
/// @param [in] scale Content scale factor.
/// @param [in] params Context parameters structure.
/// @return Self upon success, otherwise nil.
- (id)initWithFrame:(CGRect)frame contentScale:(CGFloat)scale contextParams:(void*)params;


- (NSTimeInterval)accelerometerUpdateFrequency;

/// Associated egwGfxContext Accessor.
/// Returns the associated egwGfxContext object owned by this view.
/// @return Owned egwGfxContext object.
- (egwGfxContextEAGLES*)associatedGfxContext;

/// Layer Class.
/// Returns the underlying layer's CoreAnimation class.
/// @return Layer class.
/// @note This method is required to return CAEAGLLayer for the iPhone UIKit to work correctly to create a OpenGLES/EAGL based context.
+ (Class)layerClass;

/// View Surface Width.
/// Returns the surface width of this view.
/// @return View surface width.
- (EGWuint16)surfaceWidth;

/// View Surface Height.
/// Returns the surface height of this view.
/// @return View surface height.
- (EGWuint16)surfaceHeight;


- (void)setTouchDelegate:(id<egwDUIViewSurfaceTouchEvent>)delegate;

- (void)setMultipleTouchEnabled:(BOOL)enable;

- (void)setAccelerometerDelegate:(id<egwDUIViewSurfaceAccelerometerEvent>)delegate;

- (void)setAccelerometerUpdateFrequency:(NSTimeInterval)interval;

@end

#endif

/// @}

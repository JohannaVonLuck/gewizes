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

/// @defgroup geWizES_hwd_types egwHwdTypes
/// @ingroup geWizES_hwd
/// Window Handler Types.
/// @{

/// @file egwHwdTypes.h
/// Window Handler Types.

#import "../inf/egwTypes.h"
#import "../gfx/egwGfxTypes.h"


// !!!: ***** Predefs *****

#if defined(EGW_BUILDMODE_IPHONE)
@class egwUIViewSurface;
#endif
#if defined(EGW_BUILDMODE_COCOA) || defined(EGW_BUILDMODE_GNUSTEP)
@class egwNSOpenGLViewSurface;
#endif
#if defined(EGW_BUILDMODE_IPHONE)
@class egwTouchDecoder;
#endif
//@class egwAccelerometerDecoder;
#if defined(EGW_BUILDMODE_COCOA) || defined(EGW_BUILDMODE_GNUSTEP)
@class egwMouseDecoder;
#endif
//@class egwKeyboardDecoder;


// !!!: ***** Delegates *****

/// Decoded Stroke Event Delegate.
/// Contains decoded stroke event methods that a delegate object can handle.
@protocol egwDDecodedStrokeEvent <NSObject>
- (void)startedActionAt:(egwPoint2i*)avgPosition pads:(EGWuint)padCount;
- (void)canceledAction;
- (void)continuedTappingAt:(egwPoint2i*)avgPosition taps:(EGWuint)tapCount time:(EGWtime)elapsed;
- (void)finishedTappingAt:(egwPoint2i*)avgPosition taps:(EGWuint)tapCount time:(EGWtime)elapsed;
- (void)continuedSwipingAt:(egwPoint2i*)avgPosition covering:(egwSpan2i*)avgTotalSpan moving:(egwSpan2i*)avgDeltaSpan pads:(EGWuint)padCount time:(EGWtime)elapsed;
- (void)finishedSwipingAt:(egwPoint2i*)avgPosition covering:(egwSpan2i*)avgTotalSpan pads:(EGWuint)maxPadCount time:(EGWtime)elapsed;
- (void)continuedPinchingAt:(egwPoint2i*)ctrPosition covering:(EGWsingle)totalDist moving:(EGWsingle)deltaDist time:(EGWtime)elapsed;
- (void)finishedPinchingAt:(egwPoint2i*)ctrPosition covering:(EGWsingle)totalDist time:(EGWtime)elapsed;
- (void)continuedRotatingAt:(egwPoint2i*)ctrPosition covering:(EGWsingle)totalAngle moving:(EGWsingle)deltaAngle time:(EGWtime)elapsed;
- (void)finishedRotatingAt:(egwPoint2i*)ctrPosition covering:(EGWsingle)totalAngle time:(EGWtime)elapsed;
@end

/// @}

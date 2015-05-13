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

/// @defgroup geWizES_hwd_touchdecoder egwTouchDecoder
/// @ingroup geWizES_hwd
/// iPhone Touch Decoder.
/// @{

/// @file egwTouchDecoder.h
/// iPhone Touch Decoder Interface.

#if defined(EGW_BUILDMODE_IPHONE)

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import "egwHwdTypes.h"
#import "egwUIViewSurface.h"
#import "../math/egwMathTypes.h"
#import "../gfx/egwGfxTypes.h"


#define EGW_TOUCHDEC_TAPTIMEOUT         0.1
#define EGW_TOUCHDEC_SWIPETOLERANCE     10
#define EGW_TOUCHDEC_PINCHTOLERANCE     22
#define EGW_TOUCHDEC_ROTATETOLERANCE    0.0724


/// Touch Decoder.
/// This class provides a touch decoder mechanism to convert UIKit touch events into EGW stroke events.
@interface egwTouchDecoder : NSObject <egwDUIViewSurfaceTouchEvent> {
    id<egwDDecodedStrokeEvent> _delegate;   ///< Event responder delegate (retained).
    
    EGWuint _state;
    EGWdouble _scale;
    
    egwPoint2i _avgIntPos;
    EGWuint16 _intFingerCount;
    EGWtime _intTime;
    
    EGWuint16 _tapCount;
    NSTimer* _tapTimer;
    
    egwSpan2i _avgTotalSpan;
    egwSpan2i _avgDeltaSpan;
    
    egwVector2f _intVector;
    EGWsingle _totalValue;
}

- (id)initWithScale:(EGWdouble)scale;

- (void)setDelegate:(id<egwDDecodedStrokeEvent>)delegate;

@end

#endif

/// @}

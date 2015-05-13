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

/// @file egwTouchDecoder.m
/// @ingroup geWizES_hwd_touchdecoder
/// iPhone Touch Decoder Implementation.

#if defined(EGW_BUILDMODE_IPHONE)

#import "egwTouchDecoder.h"
#import "../math/egwVector.h"
#import "../gfx/egwGraphics.h"
#import "../geo/egwGeometry.h"


void egwAverageLocation(NSSet* touches_in, UIView* view_in, EGWdouble scale_in, egwPoint2i* avgPos_inout) {
    EGWint16 count = (EGWint16)[touches_in count];
    
    avgPos_inout->axis.x = avgPos_inout->axis.y = (EGWint16)0;
    
    for(UITouch* touch in [touches_in objectEnumerator]) {
        CGPoint loc = [touch locationInView:view_in];
        avgPos_inout->axis.x += (EGWint16)(loc.x * scale_in);
        avgPos_inout->axis.y += (EGWint16)(loc.y * scale_in);
    }
    
    if(count) {
        avgPos_inout->axis.x /= count;
        avgPos_inout->axis.y /= count;
    }
}

void egwAveragePreviousLocation(NSSet* touches_in, UIView* view_in, EGWdouble scale_in, egwPoint2i* avgPos_inout) {
    EGWint16 count = (EGWint16)[touches_in count];
    
    avgPos_inout->axis.x = avgPos_inout->axis.y = (EGWint16)0;
    
    for(UITouch* touch in [touches_in objectEnumerator]) {
        CGPoint loc = [touch previousLocationInView:view_in];
        avgPos_inout->axis.x += (EGWint16)(loc.x * scale_in);
        avgPos_inout->axis.y += (EGWint16)(loc.y * scale_in);
    }
    
    if(count) {
        avgPos_inout->axis.x /= count;
        avgPos_inout->axis.y /= count;
    }
}


@interface egwTouchDecoder (Private)

- (void)timerFireMethod:(NSTimer*)theTimer;

@end


@implementation egwTouchDecoder

- (id)init {
    return [self initWithScale:1.0];
}

- (id)initWithScale:(EGWdouble)scale {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    _scale = scale;
    
    return self;
}

- (void)dealloc {
    [_tapTimer invalidate]; [_tapTimer release]; _tapTimer = nil;
    
    [_delegate release]; _delegate = nil;
    
    [super dealloc];
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event inView:(UIView*)view {
    switch(_state) {
        case 0: { // reset
            if([touches count] == 1)
                _state = 1; // could be tap or swipe
            else if ([touches count] == 2) {
                _state = 2; // could be pinch or rotate
                
                CGPoint tempPnt[2];
                EGWuint i = 0;
                
                for(UITouch* touch in [touches objectEnumerator])
                    tempPnt[i++] = [touch locationInView:view];
                
                _intVector.axis.x = (EGWsingle)(tempPnt[1].x * _scale) - (EGWsingle)(tempPnt[0].x * _scale);
                _intVector.axis.y = (EGWsingle)(tempPnt[1].y * _scale) - (EGWsingle)(tempPnt[0].y * _scale);
                
                _totalValue = 0.0f;
            } else
                _state = 4; // can only be swipe
            
            egwAverageLocation(touches, view, _scale, &_avgIntPos);
            _intFingerCount = (EGWuint16)[touches count];
            _intTime = (EGWtime)(event.timestamp);
            
            [_delegate startedActionAt:&_avgIntPos pads:(EGWuint)_intFingerCount];
        } break;
        
        case 3: { // tap
            [_tapTimer invalidate]; [_tapTimer release]; _tapTimer = nil; // down press removes timer
        } break;
        
        case 4: { // swipe
            _intFingerCount = (EGWuint16)egwMax2i((EGWint)_intFingerCount, (EGWint)[touches count]);
        } break;
        
        case 5: // pinch
        case 6: { // rotate
            if([touches count] == 2) {
                // new finger moving down means new initials
                CGPoint tempPnt[2];
                EGWuint i = 0;
                
                for(UITouch* touch in [touches objectEnumerator])
                    tempPnt[i++] = [touch locationInView:view];
                
                _intVector.axis.x = (EGWsingle)(tempPnt[1].x * _scale) - (EGWsingle)(tempPnt[0].x * _scale);
                _intVector.axis.y = (EGWsingle)(tempPnt[1].y * _scale) - (EGWsingle)(tempPnt[0].y * _scale);
            }
            
            egwAverageLocation(touches, view, _scale, &_avgIntPos);
        } break;
    }
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event inView:(UIView*)view {
    switch(_state) {
        case 1: { // tap or swipe
            if([touches count] == 1) {
                CGPoint tempPnt;
                egwPoint2i tempPos;
                
                UITouch* touch = (UITouch*)[touches anyObject];
                tempPnt = [touch locationInView:view];
                tempPos.axis.x = (EGWint16)tempPnt.x; tempPos.axis.y = (EGWint16)tempPnt.y;
                
                // tolerance check for distance -> swipe
                if(egwPntDistanceSqrd2i(&_avgIntPos, &tempPos) > (EGW_TOUCHDEC_SWIPETOLERANCE * EGW_TOUCHDEC_SWIPETOLERANCE)) {
                    _state = 4; // swipe
                    [self touchesMoved:touches withEvent:event inView:view];
                    return;
                }
                
                // otherwise finger is slipping a tad, ignore
            } else {
                _state = 4; // swipe
                [self touchesMoved:touches withEvent:event inView:view];
                return;
            }
        } break;
        
        case 2: { // swipe, pinch, or rotate
            if([touches count] == 2) {
                egwPoint2i avgPos;
                egwVector2f newVector;
                EGWsingle deltaValue;
                
                {   CGPoint tempPnt[2];
                    EGWuint i = 0;
                    for(UITouch* touch in [touches objectEnumerator])
                        tempPnt[i++] = [touch locationInView:view];
                    
                    newVector.axis.x = (EGWsingle)(tempPnt[1].x * _scale) - (EGWsingle)(tempPnt[0].x * _scale);
                    newVector.axis.y = (EGWsingle)(tempPnt[1].y * _scale) - (EGWsingle)(tempPnt[0].y * _scale);
                }
                
                // tolerance check for avg. center -> swipe
                egwAverageLocation(touches, view, _scale, &avgPos);
                if(egwPntDistanceSqrd2i(&_avgIntPos, &avgPos) > (EGW_TOUCHDEC_SWIPETOLERANCE * EGW_TOUCHDEC_SWIPETOLERANCE)) {
                    _state = 4; // swipe
                    [self touchesMoved:touches withEvent:event inView:view];
                    return;
                }
                
                // tolerance check for distance -> pinch
                deltaValue = egwVecMagnitude2f(&newVector) - egwVecMagnitude2f(&_intVector);
                if(egwAbsf(deltaValue) > (EGWsingle)EGW_TOUCHDEC_PINCHTOLERANCE) {
                    _state = 5; // pinch
                    [self touchesMoved:touches withEvent:event inView:view];
                    return;
                }
                
                // tolerance check for angle -> rotate
                deltaValue = egwVecAngleBtwn2f(&_intVector, &newVector); // already abs
                if(deltaValue > (EGWsingle)EGW_TOUCHDEC_ROTATETOLERANCE) {
                    _state = 6; // rotate
                    [self touchesMoved:touches withEvent:event inView:view];
                    return;
                }
            }
            // else finger slipping a tad while repositioning other finger, ignore
        } break;
        
        case 3: { // tap
            // finger is slipping a tad, ignore
        } break;
        
        case 4: { // swipe
            egwPoint2i avgPos, avgPrevPos;
            egwAverageLocation(touches, view, _scale, &avgPos);
            egwAveragePreviousLocation(touches, view, _scale, &avgPrevPos);
            egwPntSpan2i(&_avgIntPos, &avgPos, &_avgTotalSpan);
            egwPntSpan2i(&avgPrevPos, &avgPos, &_avgDeltaSpan);
            [_delegate continuedSwipingAt:&avgPos covering:&_avgTotalSpan moving:&_avgDeltaSpan pads:_intFingerCount time:((EGWtime)(event.timestamp) - _intTime)];
        } break;
        
        case 5: // pinch
        case 6: { // rotate
            if([touches count] == 2) {
                egwVector2f newVector[2];
                
                {   CGPoint tempPnt[2][2];
                    EGWuint i = 0;
                    for(UITouch* touch in [touches objectEnumerator]) {
                        tempPnt[0][i] = [touch previousLocationInView:view];
                        tempPnt[1][i] = [touch locationInView:view];
                        ++i;
                    }
                    
                    newVector[0].axis.x = (EGWsingle)(tempPnt[0][1].x * _scale) - (EGWsingle)(tempPnt[0][0].x * _scale);
                    newVector[0].axis.y = (EGWsingle)(tempPnt[0][1].y * _scale) - (EGWsingle)(tempPnt[0][0].y * _scale);
                    
                    newVector[1].axis.x = (EGWsingle)(tempPnt[1][1].x * _scale) - (EGWsingle)(tempPnt[1][0].x * _scale);
                    newVector[1].axis.y = (EGWsingle)(tempPnt[1][1].y * _scale) - (EGWsingle)(tempPnt[1][0].y * _scale);
                }
                
                if(_state == 5) {
                    EGWsingle deltaDist = egwVecMagnitude2f(&newVector[1]) - egwVecMagnitude2f(&newVector[0]);
                    _totalValue += deltaDist;
                    [_delegate continuedPinchingAt:&_avgIntPos covering:_totalValue moving:deltaDist time:((EGWtime)(event.timestamp) - _intTime)];
                } else {
                    EGWsingle deltaAngle;
                    if(egwVecCrossProd2f(&newVector[0], &newVector[1]) >= 0.0f) // + -> counter-clock-wise
                        deltaAngle = egwVecAngleBtwn2f(&newVector[0], &newVector[1]);
                    else // - -> clock-wise
                        deltaAngle = -egwVecAngleBtwn2f(&newVector[0], &newVector[1]);
                    _totalValue += deltaAngle;
                    [_delegate continuedRotatingAt:&_avgIntPos covering:_totalValue moving:deltaAngle time:((EGWtime)(event.timestamp) - _intTime)];
                }
            }
            // else finger slipping a tad while repositioning other finger, ignore
        } break;
    }
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event inView:(UIView*)view {
    switch(_state) {
        case 1: // tap or swipe
        case 2: { // swipe, pinch, or rotate
            //  at this point it is best to determine that this is a tap
            _tapCount = 0;
            _state = 3; // tap
            [self touchesEnded:touches withEvent:event inView:view];
            return;
        } break;
        
        case 3: { // tap
            egwPoint2i avgPos;
            egwAverageLocation(touches, view, _scale, &avgPos);
            _avgIntPos.axis.x = ((_avgIntPos.axis.x * _tapCount) + avgPos.axis.x) / (_tapCount + 1);
            _avgIntPos.axis.y = ((_avgIntPos.axis.y * _tapCount) + avgPos.axis.y) / (_tapCount + 1);
            
            // need to track for multiple taps, so start timer before saying we're finished
            [_tapTimer invalidate]; [_tapTimer release]; _tapTimer = nil;
            [_delegate continuedTappingAt:&_avgIntPos taps:(EGWuint)++_tapCount time:((EGWtime)(event.timestamp) - _intTime)]; // delegate message sent on finger release
            _tapTimer = [[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)EGW_TOUCHDEC_TAPTIMEOUT target:(id)self selector:@selector(timerFireMethod:) userInfo:(id)event repeats:NO] retain];
        } break;
        
        case 4: { // swipe
            egwPoint2i avgPos;
            egwAverageLocation(touches, view, _scale, &avgPos);
            [_delegate finishedSwipingAt:&avgPos covering:&_avgTotalSpan pads:_intFingerCount time:((EGWtime)(event.timestamp) - _intTime)];
            _state = 0;
        } break;
        
        case 5: { // pinch
            if([touches count] == 2) {
                egwAverageLocation(touches, view, _scale, &_avgIntPos);
                [_delegate finishedPinchingAt:&_avgIntPos covering:_totalValue time:((EGWtime)(event.timestamp) - _intTime)];
                _state = 0;
            }
        } break;
        
        case 6: { // rotate
            if([touches count] == 2) {
                egwAverageLocation(touches, view, _scale, &_avgIntPos);
                [_delegate finishedRotatingAt:&_avgIntPos covering:_totalValue time:((EGWtime)(event.timestamp) - _intTime)];
                _state = 0;
            }
        } break;
    }
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event inView:(UIView*)view {
    [_tapTimer invalidate]; [_tapTimer release]; _tapTimer = nil;
    
    if(_state != 0) {
        [_delegate canceledAction];
        _state = 0;
    }
}

- (void)setDelegate:(id<egwDDecodedStrokeEvent>)delegate {
    if(_delegate != delegate && _state == 0) {
        [delegate retain];
        [_delegate release];
        _delegate = delegate;
    }
}

@end


@implementation egwTouchDecoder (Private)

- (void)timerFireMethod:(NSTimer*)theTimer {
    if(_state == 3 && theTimer == _tapTimer) {
        [_delegate finishedTappingAt:&_avgIntPos taps:_tapCount time:((EGWtime)(((UIEvent*)[theTimer userInfo]).timestamp) - _intTime)];
        [_tapTimer release]; _tapTimer = nil;
        _state = 0;
    }
}

@end

#endif

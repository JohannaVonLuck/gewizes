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

/// @defgroup geWizES_misc_timer egwTimer
/// @ingroup geWizES_misc
/// Timer Asset.
/// @{

/// @file egwTimer.h
/// Timer Asset Interface.

#import "egwMiscTypes.h"
#import "../inf/egwPAsset.h"
#import "../inf/egwPActuator.h"
#import "../inf/egwPTimed.h"
#import "../inf/egwPTimer.h"
#import "../data/egwDataTypes.h"
#import "../phy/egwPhyTypes.h"


/// Timer Asset.
/// Provides a simple timer controller capable of producing a time evaluation.
@interface egwTimer : NSObject <egwPAsset, egwPTimer> {
    NSString* _ident;                       ///< Unique identity (retained).
    id<egwDTimerEvent> _delegate;           ///< Event responder delegate (retained).
    
    BOOL _isActuating;                      ///< Tracks actuating status.
    BOOL _isFinished;                       ///< Tracks finished status.
    BOOL _isPaused;                         ///< Tracks paused status.
    EGWuint16 _aFlags;                      ///< Actuator flags.
    
    EGWtime _tIndex;                        ///< Current time index (absolute).
    egwAbsTimeBound _otBounds;              ///< Owners' time boundaries union.
    
    egwSinglyLinkedList _tOutputs;          ///< Owner output collection (contents weak).
    pthread_mutex_t _oLock;                 ///< Owner output collection lock.
    
    BOOL _isExplicitBound;                  ///< Tracks explicit bounding status.
}

/// Designated Initializer.
/// Initializes the timer asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent;

/// Copy Initializer.
/// Copies a timer asset with provided unique settings.
/// @param [in] asset Asset to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent;


/// Delegate Mutator.
/// Sets the timer's event responder delegate to @a delegate.
/// @param [in] delegate Event responder delegate (retained).
- (void)setDelegate:(id<egwDTimerEvent>)delegate;

/// Explicit Bounds Mutator.
/// Sets the timer's boundaries explcitly to @a begin and @a end.
/// @param [in] begin Absolute time bounds beginning (seconds).
/// @param [in] end Absolute time bounds ending (seconds).
/// @note Once this method is called automatic boundary adjustment is disabled.
- (void)setExplicitBoundsBegin:(EGWtime)begin andEnd:(EGWtime)end;


/// IsExplicitlyBounded Poller.
/// Polls the object to determine status.
/// @return YES if object's timer bounds are explicitly controlled, otherwise NO.
- (BOOL)isExplicitlyBounded;

@end

/// @}

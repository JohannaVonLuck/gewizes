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

/// @defgroup geWizES_misc_actionedtimer egwActionedTimer
/// @ingroup geWizES_misc
/// Actioned Timer Asset.
/// @{

/// @file egwActionedTimer.h
/// Actioned Timer Asset Interface.

#import "egwMiscTypes.h"
#import "../inf/egwPAsset.h"
#import "../inf/egwPAssetBase.h"
#import "../inf/egwPActioned.h"
#import "../inf/egwPActuator.h"
#import "../inf/egwPTimed.h"
#import "../inf/egwPTimer.h"
#import "../data/egwDataTypes.h"
#import "../phy/egwPhyTypes.h"


/// Actioned Timer Instance Asset.
/// Provides an action partitioned timer controller capable of producing a time evaluation.
@interface egwActionedTimer : NSObject <egwPAsset, egwPActioned, egwPTimer> {
    egwActionedTimerBase* _base;            ///< Base object instance (retained).
    NSString* _ident;                       ///< Unique identity (retained).
    id<egwDActionedTimerEvent> _delegate;   ///< Event responder delegate (retained).
    
    BOOL _isActuating;                      ///< Tracks actuating status.
    BOOL _isFinished;                       ///< Tracks finished status.
    BOOL _isPaused;                         ///< Tracks paused status.
    BOOL _isBreaking;                       ///< Tracks breaking status.
    EGWuint16 _baIndex;                     ///< Breaking to action index.
    EGWuint16 _aFlags;                      ///< Actuator flags.
    
    EGWtime _tIndex;                        ///< Current time index (absolute).
    egwAbsTimeBound _otBounds;              ///< Owners' time boundaries union.
    
    egwSinglyLinkedList _tOutputs;          ///< Owner output collection (contents weak).
    pthread_mutex_t _oLock;                 ///< Owner output collection lock.
    
    EGWuint16 _caIndex;                     ///< Current action index.
    EGWint16 _caOffset;                     ///< Current action offset.
    egwCyclicArray _aQueue;                 ///< Queueued action states.
    pthread_mutex_t _aLock;                 ///< Action queue lock.
    
    egwAbsTimedActions* _actions;           ///< Timed actions container set (aliased).
}

/// Designated Initializer.
/// Initializes the actioned timer asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] actions Timed actions container set (contents ownership transfer).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent actionsSet:(egwAbsTimedActions*)actions;

/// Blank Actioned Timer Initializer.
/// Initializes the actioned timer asset as a blank timed actions set set with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] actsCount Actions count [1,inf].
/// @param [in] dfltActIndex Default action state index.
/// @note This method does not clear/set-to-zero the allocated timed actions set set prior to return.
/// @return Self upon success, otherwise nil.
- (id)initBlankWithIdentity:(NSString*)assetIdent actionCount:(EGWuint16)actsCount defaultAction:(EGWuint16)dfltActIndex;

/// Copy Initializer.
/// Copies an actioned timer asset with provided unique settings.
/// @param [in] asset Asset to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent;


/// Action Starting Bounds Accessor.
/// Returns the starting time for the action at @a actIndex.
/// @param [in] actIndex Action state index.
/// @return Absolute action time bounds beginning (seconds).
- (EGWtime)actionBoundsBegin:(EGWuint16)actIndex;

/// Action Finishing Bounds Accessor.
/// Returns the finishing time for the action at @a actIndex.
/// @param [in] actIndex Action state index.
/// @return Absolute action time bounds ending (seconds).
- (EGWtime)actionBoundsEnd:(EGWuint16)actIndex;

/// Action Index Offset Accessor.
/// Returns the action index offset modifier currently set.
/// @return Action index offset modifier.
- (EGWint16)actionIndexOffset;


/// Action Time Boundaries Mutator.
/// Sets the action at @a actIndex to time boundings @a begin and @a end.
/// @param [in] actIndex Action state index.
/// @param [in] begin Action's absolute time bounds beginning (seconds).
/// @param [in] end Action's absolute time bounds ending (seconds).
/// @note This method is provided for simplicity; it affects all asset instances connected to the asset base.
- (void)setAction:(EGWuint16)actIndex timeBoundsBegin:(EGWtime)begin andEnd:(EGWtime)end;

/// Action Index Offset Mutator.
/// Sets the action index offset to @a offset, adjusting current time to fit.
/// @param [in] offset Action index offset modifier.
/// @note This method is used usually in conjuction with a dynamic direction fitting.
- (void)setActionIndexOffset:(EGWint16)offset;

/// Delegate Mutator.
/// Sets the interpolator's event responder delegate to @a delegate.
/// @param [in] delegate Event responder delegate (retained).
- (void)setDelegate:(id<egwDActionedTimerEvent>)delegate;

@end


/// Actioned Timer Asset Base.
/// Contains shared instance data relating to actioned timers.
@interface egwActionedTimerBase : NSObject <egwPAssetBase> {
    EGWuint _instCounter;                   ///< Instantiation counter.
    NSString* _ident;                       ///< Unique identity (retained).
    
    egwAbsTimedActions* _actions;              ///< Timed actions container set (contents owned).
}

/// Designated Initializer.
/// Initializes the actioned timer asset base with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] actions Timed actions container set (contents ownership transfer).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent actionsSet:(egwAbsTimedActions*)actions;


/// Actions Set Accessor.
/// Returns the timed actions set data structure.
/// @return Actions set data structure.
- (egwAbsTimedActions*)actionsSet;

@end

/// @}

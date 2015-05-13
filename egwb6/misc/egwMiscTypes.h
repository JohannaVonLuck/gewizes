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

/// @defgroup geWizES_misc_types egwMiscTypes
/// @ingroup geWizES_misc
/// Miscellaneous Types.
/// @{

/// @file egwMiscTypes.h
/// Miscellaneous Types.

#import "../inf/egwTypes.h"


// !!!: ***** Predefs *****

@class egwInt8;
@class egwInt16;
@class egwInt32;
@class egwInt64;
@class egwUInt8;
@class egwUInt16;
@class egwUInt32;
@class egwUInt64;
@class egwInt;
@class egwUInt;
@class egwSingle;
@class egwDouble;
@class egwTriple;
@class egwTime;
@class egwPointer;
@class egwTimer;
@class egwActionedTimer;
@class egwActionedTimerBase;
//@class egwActionedTimersArray;
//@class egwStreamer;
@class egwValidater;


// !!!: ***** Misc. Structures *****

/// Absolute Time Bound Container.
/// Stores a bounding of time specified in absolute units.
typedef struct {
    EGWtime tBegin;                         ///< Absolute beginning time (seconds).
    EGWtime tEnd;                           ///< Absolute ending time (seconds).
} egwAbsTimeBound;

/// Absolute Timed Actions Container.
/// Contains timed actions' bounds specified in absolute units.
typedef struct {
    EGWuint16 aCount;                       ///< Actions count.
    EGWuint16 daIndex;                      ///< Default action index.
    egwAbsTimeBound* tBounds;               ///< Time bounds per action (owned).
    EGWchar** aNames;                       ///< Action names (optional, owned).
} egwAbsTimedActions;

/// Multi Target Output.
/// A dynamic multiple target output store.
typedef struct {
    union {                                 ///< Output writing union.
        struct {
            egwValidater* vSync;            ///< Validater sync (optional, possibly retained).
            EGWbyte* oAddress;              ///< Output address (weak).
            EGWuint32 oSize;                ///< Output block size.
        } address;
        struct {
            id<NSObject> oObj;              ///< Output object (possibly retained).
            SEL oMethod;                    ///< Output method selector.
            IMP oRoutine;                   ///< Output routine address.
        } message;
    } write;
    EGWuint8 oType;                         ///< Output type (1 = address, 2 = message).
    EGWuint8 oFlags;                        ///< Output flags (1 = retained sync/obj).
} egwMultiTargetOutput;


// !!!: ***** Event Delegate Protocols *****

/// Validator Event Delegate.
/// Defines events that a delegate object can handle.
@protocol egwDValidationEvent <NSObject>

/// Validater Did Validate.
/// Called when a validater object validates itself.
/// @param [in] validater Validater object.
- (void)validaterDidValidate:(egwValidater*)validater;

/// Validater Did Invalidate.
/// Called when a validater object invalidates itself.
/// @param [in] validater Validater object.
- (void)validaterDidInvalidate:(egwValidater*)validater;

@end

/// Actuator Event Delegate.
/// Defines events that a delegate object can handle.
@protocol egwDActuatorEvent <NSObject>

/// Actuator Did Behavior.
/// Called when an actuator object performs a behavior related to actuating.
/// @param [in] actuator Actuator object.
/// @param [in] action Behavioral flag setting (EGW_ACTION_*).
- (void)actuator:(id<egwPActuator>)actuator did:(EGWuint32)action;

@end

/// Timer Event Delegate.
/// Defines events that a delegate object can handle.
@protocol egwDTimerEvent <NSObject>

/// Timer Did Behavior.
/// Called when a timer object performs a behavior related to actuating.
/// @param [in] timer Timer object.
/// @param [in] action Behavioral flag setting (EGW_ACTION_*).
- (void)timer:(id<egwPTimer>)timer did:(EGWuint32)action;

@end

/// Actioned Timer Event Delegate.
/// Defines events that a delegate object can handle.
@protocol egwDActionedTimerEvent <egwDTimerEvent>

/// Actioned Timer Action Did Behavior.
/// Called when an actioned timer object's action performs a behavior related to action processing.
/// @param [in] timer Actioned timer object.
/// @param [in] actIndex Action state index.
/// @param [in] action Behavioral flag setting (EGW_ACTION_*).
- (void)actionedTimer:(egwActionedTimer*)timer action:(EGWuint16)actIndex did:(EGWuint32)action;

@end

/// @}

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

/// @defgroup geWizES_sys_phyactuator egwPhyActuator
/// @ingroup geWizES_sys
/// Physical Actuator.
/// @{

/// @file egwPhyActuator.h
/// Physical Actuator Interface.

#import <time.h>
#import "egwSysTypes.h"
#import "../inf/egwPSingleton.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPPhyContext.h"
#import "../inf/egwPTask.h"
#import "../inf/egwPInteractable.h"
#import "../inf/egwPActuator.h"
#import "../sys/egwEngine.h"
#import "../data/egwDataTypes.h"


#define EGW_PHYACTR_ACTRMODE_DFLT           0x0302  ///< Default actuator mode.
#define EGW_PHYACTR_ACTRMODE_IMMEDIATE      0x0001  ///< Use immediate interaction mode.
#define EGW_PHYACTR_ACTRMODE_DEFERRED       0x0002  ///< Use deferred interaction mode (i.e. sorted list).
#define EGW_PHYACTR_ACTRMODE_PERSISTENT     0x0100  ///< Use a persistent object list (i.e. manual removal). Note: If unused, all objects are removed after each frame and must be re-enqueued.
#define EGW_PHYACTR_ACTRMODE_FRAMECHECK     0x0200  ///< Use delayed object removal (i.e. frame number check). Note: Unlike other tasks, the frame check is performed AFTER update, not before.

#define EGW_PHYACTR_ACTRQUEUE_ALL           0x00ff  ///< All interaction queues.
#define EGW_PHYACTR_ACTRQUEUE_PREPASS       0x0001  ///< Pre-pass interaction queue.
#define EGW_PHYACTR_ACTRQUEUE_ACTUATOR      0x0002  ///< Actuator interaction queue.
#define EGW_PHYACTR_ACTRQUEUE_MAINPASS      0x0004  ///< Main pass interaction queue.

#define EGW_PHYACTR_DFLTPRIORITY    0.55    ///< Default physics actuator priority.
#define EGW_PHYACTR_MAXDELTAT       0.5     ///< Maximum allowable delta time value.
#define EGW_PHYACTR_MINDELTAT       0.0     ///< Minimum allowable delta time value.
#define EGW_PHYACTR_NSDATEMAX 1000000.0     ///< Maximum seconds allowed for an NSDate object to use before creating a new one.
#define EGW_PHYACTR_USENSDATE               ///< When defined, uses NSDate instead of clock() for timing control. This is useful for situations where ticks are being CPU scaled.

#define EGW_PHYACTR_ACTRQUEUE_INSERT       0x0100   ///< Insert object into queue list structure.
#define EGW_PHYACTR_ACTRQUEUE_REMOVE       0x0200   ///< Remove object from queue list structure.
#define EGW_PHYACTR_ACTRQUEUE_PAUSE        0x0400   ///< Pause/resume object in queue list structure.


/// Physical Actuator.
/// Task that manages and executes updatable object instances.
@interface egwPhyActuator : NSObject <egwPSingleton, egwPTask> {
    egwPhyActParams _params;                ///< Actuator parameters (copy).
    
    pthread_mutex_t _qLock;                 ///< Interaction queue mutex lock (retained).
    pthread_mutex_t _rLock;                 ///< Request queue mutex lock.
    
    egwSinglyLinkedList _iQueues[3];        ///< Interaction queues (contents retained).
    
    EGWuint _iReplies[3];                   ///< Interaction replies array (alias).
    
    #ifndef EGW_PHYACTR_USENSDATE
        clock_t _lTime;                     ///< Interaction frame timer (clock()).
    #else
        NSDate* _lTime;                     ///< Interaction frame timer (NSDate).
        EGWtime _lTimeOffset;                   ///< Interaction time offset.
    #endif
    EGWtime _deltaT;                        ///< Interaction frame delta time value.
    EGWtime _mThrottle;                     ///< Master throttle multiplier.
    
    egwArray _pendingList;                  ///< Queue work item pending list for remove/resort (weak).
    egwArray _requestList;                  ///< Queue work request list for insertion/removal.
    
    id<NSObject> _lBase;                    ///< Last base tracker (retained).
    EGWuint16 _tFrame;                      ///< Interaction task frame.
    
    BOOL _amRunning;                        ///< Tracks run status.
    BOOL _doShutdown;                       ///< Tracks to-shutdown status.
    BOOL _doPreprocessing;                  ///< Tracks pre-processing status.
    BOOL _doPostprocessing;                 ///< Tracks post-processing status.
}

/// Designated Initializer.
/// Initializes the task with provided settings.
/// @param [in] params Parameters option structure. May be NULL for default.
/// @return Self upon success, otherwise nil.
- (id)initWithParams:(egwPhyActParams*)params;


/// Actuate Object Method.
/// Enqueue provided @a actuatorObject for actuating on the next frames.
/// @note An object may only be enqueued once, but multiple enqueues will still signal start actuating reply messages (restart trick).
/// @param [in] actuatorObject Acuator object instance.
- (void)actuateObject:(id<egwPActuator>)actuatorObject;

/// Interact Object Method.
/// Enqueue provided @a interactableObject for interacting on the next frames.
/// @note An object may only be enqueued once, but multiple enqueues will still signal start interaction reply messages (restart trick).
/// @param [in] interactableObject Interactable object instance.
- (void)interactObject:(id<egwPInteractable>)interactableObject;

/// Pause Object Method.
/// Pauses or resumes provided @a object from/to actuating/updating on the next frames.
/// @param [in] object Object instance.
- (void)pauseObject:(id<NSObject>)object;

/// Update Finish Method.
/// Instructs the physical actuator that there are no more objects left to enqueue for current interaction frame.
/// @note This method is used only in immediate mode to signify end of frame.
- (void)updateFinish;

/// Remove Object Method.
/// Releases any retained @a object instances currently queued.
/// @param [in] object Object instance.
- (void)removeObject:(id<NSObject>)object;


/// Set Master Throttle Mutator.
/// Sets the master throttle to @a throttle for subsequent update frames.
/// @param [in] throttle Throttle multiplier.
- (void)setMasterThrottle:(EGWtime)throttle;


@end


/// Global current singleton egwPhyActuator instance (weak).
extern egwPhyActuator* egwSIPhyAct;

/// @}

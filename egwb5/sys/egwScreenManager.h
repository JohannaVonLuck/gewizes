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

/// @defgroup geWizES_sys_screenmanager egwScreenManager
/// @ingroup geWizES_sys
/// Screen Manager.
/// @{

/// @file egwScreenManager.h
/// Screen Manager Interface.

#import "egwSysTypes.h"
#import "../inf/egwPSingleton.h"
#import "../inf/egwPScreen.h"
#import "../inf/egwPTask.h"
#import "../data/egwData.h"


#define EGW_SCRNMNGR_DFLTPRIORITY   0.50    ///< Default screen manager priority.


/// Screen Manager.
/// Manages instances and executions of cyclic tasks and performs operations relating to such.
@interface egwScreenManager : NSThread <egwPSingleton, egwPTask> {
    double _priority;                       ///< Task priority.
    
    pthread_mutex_t _rcLock;                ///< Responder chain mutex lock.
    egwSinglyLinkedList _rChain;            ///< Responder chain (retained).
    egwSinglyLinkedList _luScreens;         ///< Loading screens (retained).
    egwSinglyLinkedList _unScreens;         ///< Unloading screens (retained).
    id<egwPScreen> _kScreen;                ///< Key screen (retained).
    
    pthread_mutex_t _wLock;                 ///< Work todo mutex lock.
    egwSinglyLinkedList _sWork;             ///< Screen work (retained).
    
    BOOL _amRunning;                        ///< Tracks run status.
    BOOL _doShutdown;                       ///< Tracks to-shutdown status.
}

/// Designated Initializer.
/// @param [in] priority Task priority.
/// @return Self upon success, otherwise nil.
- (id)initWithPriority:(double)priority;


/// Manage Screen Method.
/// Begins managing @a screen at the tail end of the responder chain, performing loading if necessary.
/// @param [in] screen Screen object (retained).
- (void)manageScreen:(id<egwPScreen>)screen;

/// Make Key Screen Method.
/// Promotes @a screen to the head end of the responder chain.
/// @param [in] screen Screen object (retained).
- (void)makeKeyScreen:(id<egwPScreen>)screen;

/// Unmanage Screen Method.
/// Stops managing @a screen, performing unloading if necessary.
/// @param [in] screen Screen object (retained).
- (void)unmanageScreen:(id<egwPScreen>)screen;

/// Unmanage Screen Without Unload Method.
/// Stops managing @a screen, skipping any unload invocations.
/// @param [in] screen Screen object (retained).
- (void)unmanageScreenWithoutUnload:(id<egwPScreen>)screen;

/// Shut Down Screen Management Method.
/// Signals screens to unload and stops accepting new management.
/// @note This method blocks until all screens are removed (or timeout), screens being responsible for removing themselves.
- (void)shutDownScreenManagement;

/// Perform Selector On Responder Chain Method.
/// Forwards an invocation to screens in the responder chain using the specified parameters.
/// @param [in] selector Method selector (may only be a void return).
/// @param [in] broadcast Broadcast to all screens (if NO stops on first YES responder on screen tryer).
/// @param [in] skipKey Skips key screen invocation.
/// @return Number of screens in the responder chain that acted on the invocation.
- (EGWuint)performSelectorOnResponderChain:(SEL)selector asBroadcast:(BOOL)broadcast skipKeyScreen:(BOOL)skipKey;

/// Perform Selector On Responder Chain Method.
/// Forwards an invocation to screens in the responder chain using the specified parameters.
/// @param [in] selector Method selector (may only be a void return).
/// @param [in] object Method argument.
/// @param [in] broadcast Broadcast to all screens (if NO stops on first YES responder on screen tryer).
/// @param [in] skipKey Skips key screen invocation.
/// @return Number of screens in the responder chain that acted on the invocation.
- (EGWuint)performSelectorOnResponderChain:(SEL)selector withObject:(id)object asBroadcast:(BOOL)broadcast skipKeyScreen:(BOOL)skipKey;

/// Perform Selector On Responder Chain Method.
/// Forwards an invocation to screens in the responder chain using the specified parameters.
/// @param [in] selector Method selector (may only be a void return).
/// @param [in] object1 Method argument.
/// @param [in] object2 Method argument.
/// @param [in] broadcast Broadcast to all screens (if NO stops on first YES responder on screen tryer).
/// @param [in] skipKey Skips key screen invocation.
/// @return Number of screens in the responder chain that acted on the invocation.
- (EGWuint)performSelectorOnResponderChain:(SEL)selector withObject:(id)object1 withObject:(id)object2 asBroadcast:(BOOL)broadcast skipKeyScreen:(BOOL)skipKey;

/// Perform Invocation On Responder Chain Method.
/// Forwards an invocation to screens in the responder chain using the specified parameters.
/// @param [in,out] invocation Invocation container (may not be void return if broadcasting).
/// @param [in] broadcast Broadcast to all screens (if NO stops on first YES responder on screen tryer).
/// @param [in] skipKey Skips key screen invocation.
/// @return Number of screens in the responder chain that acted on the invocation.
- (EGWuint)performInvocationOnResponderChain:(NSInvocation*)invocation asBroadcast:(BOOL)broadcast skipKeyScreen:(BOOL)skipKey;


/// Key Screen Accesor.
/// Returns the current set key screen object.
- (id<egwPScreen>)keyScreen;

/// Screens Loading Accessor.
/// Returns the number of screens tracked that are loading into the responder chain.
/// @return Screens loading into responder chain.
- (EGWuint)screensLoading;

/// Screens Performing Accessor.
/// Returns the number of screens tracked that are performing on the responder chain.
/// @return Screens performing on responder chain.
- (EGWuint)screensPerforming;

/// Screens Unloading Accessor.
/// Returns the number of screens tracked that are unloading from the responder chain.
/// @return Screens unloading from responder chain.
- (EGWuint)screensUnloading;


/// IsShuttingDownScreenManagement Poller.
/// Polls the object to determine status.
/// @return YES if the screen manager is shutting down its screen management, otherwise NO.
- (BOOL)isShuttingDownScreenManagement;

@end


/// Global current singleton egwScreenManager instance (weak).
extern egwScreenManager* egwSIScrnMngr;

/// @}

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

/// @defgroup geWizES_inf_pscreen egwPScreen
/// @ingroup geWizES_inf
/// Screen Protcol.
/// @{

/// @file egwPScreen.h
/// Screen Protcol.

#import "egwTypes.h"


/// Screen Protocol.
/// Defines interactions for playable screens.
@protocol egwPScreen <NSObject>

/// Perform Screen Method.
/// Performs a round of execution relevant to the screen.
/// @note Do not call this method directly - this method is called automatically by the system.
- (void)performScreen;

/// Make Key Screen Method.
/// Alerts the screen that it is being made the key screen.
/// @note Do not call this method directly - this method is called automatically by the system.
- (void)makeKeyScreen;

/// Recede Key Screen Method.
/// Alerts the screen that it is receding its key screen status.
/// @note Do not call this method directly - this method is called automatically by the system.
- (void)recedeKeyScreen;

/// Load Screen Method.
/// Performs operations necessary to load the screen.
/// @note This method may be cyclic in nature to support threaded loads, acting like a poller.
/// @return YES if screen is finished loading, otherwise NO.
- (BOOL)loadScreen;

/// Unload Screen Method.
/// Performs operations necessary to load the screen.
/// @note This method may be cyclic in nature to support threaded unloads, acting like a poller.
/// @return YES if screen is finished unloading, otherwise NO.
- (BOOL)unloadScreen;

/// Pause Screen Method.
/// Pauses the screen from further execution.
/// @note This method acts as a high-end pause, and my be de-coupled from more specialized low-end pause logic.
- (void)pauseScreen;

/// Resume Screen Method.
/// Unpauses the screen from further execution.
/// @note This method acts as a high-end unpause, and my be de-coupled from more specialized low-end unpause logic.
- (void)resumeScreen;


/// IsScreenPaused Poller.
/// Polls the object to determine status.
/// @return YES if screen is paused, otherwise NO.
- (BOOL)isScreenPaused;

/// IsScreenPerforming Poller.
/// Polls the object to determine status.
/// @return YES if screen is currently in a round of execution, otherwise NO.
- (BOOL)isScreenPerforming;

/// IsScreenLoaded Poller.
/// Polls the object to determine status.
/// @return YES if screen has been loaded, otherwise NO.
- (BOOL)isScreenLoaded;

/// IsScreenUnloaded Poller.
/// Polls the object to determine status.
/// @return YES if screen has been unloaded, otherwise NO.
- (BOOL)isScreenUnloaded;

/// IsScreenKeyed Poller.
/// Polls the object to determine status.
/// @return YES if screen is key screen, otherwise NO.
- (BOOL)isScreenKeyed;

@end

/// @}

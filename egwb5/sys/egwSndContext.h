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

/// @defgroup geWizES_sys_sndcontext egwSndContext
/// @ingroup geWizES_sys
/// Abstract Sound Context.
/// @{

/// @file egwSndContext.h
/// Abstract Sound Context Interface.

#import "egwSysTypes.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPSndContext.h"
#import "../inf/egwPCamera.h"
#import "../data/egwSinglyLinkedList.h"


#define EGW_SNDCONTEXT_MAXSOUNDS    32      ///< The upper bounding maximum number of sounds (e.g. sources) to support overall. Note: The true max number of sounds is hardware dependent.
#define EGW_SNDCONTEXT_BFFRGENCNT   10      ///< Number of buffer IDs to generate when more are needed.
#define EGW_SNDCONTEXT_BUFDATATTL    5      ///< Time-to-live for buffer data segment return (seconds). Note: This is used to delay free()'ing of buffer data until hardware dispatch has had its way.


/// Abstract Sound Context.
/// Contains abstract contextual data related to the in-use sound API.
@interface egwSndContext : NSObject <egwPSndContext> {
    id<egwDSndContextEvent> _delegate;      ///< Event responder (retained).
    
    NSThread* _thread;                      ///< Thread which owns this context (weak).
    NSMutableArray* _tasks;                 ///< Associated tasks (retained).
    id<egwPCamera> _actvCamera;             ///< Currently active camera (retained).
    
    pthread_mutex_t _stLock;                ///< Sub tasks list mutex lock.
    egwSinglyLinkedList _sTasks;            ///< Sub tasks list.
    
    egwArray _dstryBufData;                 ///< Delayed destroy audio buffer data segments (wrapped in sub-task).
    
    EGWuint16 _pFrame;                      ///< Current playback frame.
    
    EGWuint16 _maxSources;                  ///< Maximum # of active sources.
    
    EGWint _sVolume;                        ///< System (context) volume [0,100].
    
    BOOL _doShutdown;                       ///< Tracks to-shutdown status.
}

/// Advance Playback Frame Method.
/// Advances playback frame number by one.
- (void)advancePlaybackFrame;

/// Request Buffer Data Segment Method.
/// Requests a context specific buffer data segment, generating more if none available.
/// @note This method is provided to maintain req/ret structure - it just does a malloc.
/// @param [in] sizeB Size of buffer (bytes).
/// @return Buffer identifier, otherwise NSNotFound if error.
- (EGWbyte*)requestFreeBufferDataWithSize:(EGWuint)sizeB;

/// Return Buffer Data Segment Method.
/// Returns a context specific buffer data segment, destroying the corresponding buffer.
/// @note This method is provided to maintain req/ret structure - it just does a time delayed free.
/// @param [in,out] bufferData Buffer data segment (ownership transfer).
- (void)returnUsedBufferData:(EGWbyte**)bufferData;

@end


/// Global currently active egwSndContext instance (weak).
extern egwSndContext* egwAISndCntx;

/// @}

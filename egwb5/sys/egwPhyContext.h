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

/// @defgroup geWizES_sys_phycontext egwPhyContext
/// @ingroup geWizES_sys
/// Abstract Physics Context.
/// @{

/// @file egwPhyContext.h
/// Abstract Physics Context Interface.

#import "egwSysTypes.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPPhyContext.h"
#import "../data/egwSinglyLinkedList.h"


/// Abstract Physics Context.
/// Contains abstract contextual data related to the in-use physics API.
@interface egwPhyContext : NSObject <egwPPhyContext> {
    id<egwDPhyContextEvent> _delegate;      ///< Event responder (retained).
    
    NSThread* _thread;                      ///< Thread which owns this context (weak).
    NSMutableArray* _tasks;                 ///< Associated tasks (retained).
    
    pthread_mutex_t _stLock;                ///< Sub tasks list mutex lock.
    egwSinglyLinkedList _sTasks;            ///< Sub tasks list.
    
    EGWuint16 _uFrame;                      ///< Current interaction frame.
    
    BOOL _doShutdown;                       ///< Tracks to-shutdown status.
}

/// Advance Interaction Frame Method.
/// Advances interaction frame number by one.
- (void)advanceInteractionFrame;

@end


/// Global currently active egwPhyContext instance (weak).
extern egwPhyContext* egwAIPhyCntx;

/// @}

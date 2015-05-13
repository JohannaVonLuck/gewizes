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

/// @defgroup geWizES_inf_pcontext egwPContext
/// @ingroup geWizES_inf
/// API Context Protcol.
/// @{

/// @file egwPContext.h
/// API Context Protcol.

#import "egwTypes.h"
#import "../inf/egwPTask.h"
#import "../inf/egwPSubTask.h"


/// API Context Protocol.
/// Defines interactions for API contexts (e.g. ones that manage API interactivity).
@protocol egwPContext <NSObject>

/// Designated Initializer.
/// Initializes the API context with provided settings.
/// @param [in] params Parameters option structure. May be nil for default [in some cases].
/// @return Self upon success, otherwise nil.
/// @note Do not call this method directly; instead always go through egwEngine's create* methods to ensure appropriate tracking.
/// @note If this is the first context of a particular type created, context should automatically set itself as currently active context.
/// @note Although @a params may be nil for default, not all context types will accept this behavior.
- (id)initWithParams:(void*)params;

/// Add Sub Task Method.
/// Adds the sub task @a sTask to the sub task list.
/// @param [in] sTask Sub task reference (retained).
/// @param [in] vSync Validater sync reference (strong). May be nil.
- (void)addSubTask:(id<egwPSubTask>)sTask forSync:(egwValidater*)vSync;

/// Perform Sub Tasks Method.
/// Performs any sub task's tasks, if any.
- (void)performSubTasks;

/// Remove Sub Task Method.
/// Removes the sub task @a sTask from the sub task list.
/// @param [in] sTask Sub task reference.
- (void)removeSubTask:(id<egwPSubTask>)sTask;

/// Task Association Method.
/// Associates the provided @a task with this context.
/// @note Task association ensures that a dependent task has its shutDownTask method called upon context shut down.
/// @param [in] task Task object (retained).
/// @return YES if association successful, otherwise NO.
- (BOOL)associateTask:(id<egwPTask>)task;

/// Task Deassociation Method.
/// De-associates the provided @a task with this context.
/// @param [in] task Task object.
/// @return YES if de-association successful, otherwise NO.
- (BOOL)deassociateTask:(id<egwPTask>)task;

/// Make Context Active Method.
/// Makes this context the currently one in-use/activated [on calling thread].
/// @note This method will deactivate and reactivate API context regardless if API context is already active [on this thread] or not.
/// @note This method will update the egwAI* globals to reflect the active context.
/// @note This method will lock the API mutex then unlock after finished activating; system deadlock will result if already previously locked.
/// @return YES if context was made active, otherwise NO.
- (BOOL)makeActive;

/// Make Context Active And Locked Method.
/// Makes this context the currently one in-use/activated on the calling thread and leaves API mutex locked.
/// @note This method will deactivate and reactivate API context regardless if API context is already active [on this thread] or not.
/// @note This method will update the egwAI* globals to reflect the active context and tasks (if associated).
/// @note This method will lock the API mutex then finish activating; system deadlock will result if already previously locked.
/// @note It is the calling thread's responsibility to explicitly unlock the API mutex when finished processing; failure to do so will result in system deadlock.
/// @return YES if context was made active, otherwise NO.
- (BOOL)makeActiveAndLocked;

/// Shut Down Context Method.
/// Performs any related context shut down tasks.
- (void)shutDownContext;


/// API Identification Class Accessor.
/// Returns the type of API this class works for.
/// @return API identification (EGW_ENGINE_XXXAPI_*).
+ (EGWint)apiIdent;

/// Critical Section Lock Class Accessor.
/// Returns the mutex lock associated with this context for performing critical section work.
/// @return Critical section lock object. May be nil.
/// @note The mutex lock should be created when first context of said API is created, and destroyed when last context of said API is destroyed.
+ (pthread_mutex_t*)apiMutex;

/// Associated Tasks Accessor.
/// Returns the array of associated tasks with this context.
/// @return Array of tasks.
- (NSArray*)associatedTasks;


/// IsActive Poller.
/// Polls the object to determine status.
/// @return YES if context is currently active, otherwise NO.
- (BOOL)isActive;

/// IsContextThread Poller.
/// Polls the object to determine status.
/// @return YES if current thread owns the context, otherwise NO.
- (BOOL)isContextThread;

/// Extension Available Poller.
/// Polls the object to determine status.
/// @param [in] extName Name of extension.
/// @return YES if extension is available, otherwise NO.
- (BOOL)isExtAvailable:(NSString*)extName;

/// IsContextShutDown Poller.
/// Polls the object to determine status.
/// @return YES if context is shut(ting) down, otherwise NO.
- (BOOL)isContextShutDown;

@end

/// @}

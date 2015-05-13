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

/// @defgroup geWizES_sys_taskmanager egwTaskManager
/// @ingroup geWizES_sys
/// Task Manager.
/// @{

/// @file egwTaskManager.h
/// Task Manager Interface.

#import "egwSysTypes.h"
#import "../inf/egwPSingleton.h"
#import "../inf/egwPTask.h"


#define EGW_TASKMNGR_TASKTHREADS        3   ///< Total number of task threads in thread pool.
#define EGW_TASKMNGR_MAXTASKHANDLES     16  ///< Max number of tracked task handles.
#define EGW_TASKMNGR_MAXDEPENDENCIES    16  ///< Max number of tracked task dependencies.
#define EGW_TASKMNGR_MAXTASKDEPENDENTS  4   ///< Max number of dependencies per task handle.


/// Task Item Structure.
typedef struct {
    id<egwPTask> task;                      ///< Task object (retained).
    IMP fpPrfmTask;                         ///< Reference to performTask to reduce frequent dynamic lookup overhead.
    EGWsingle tPriority;                    ///< Task priority.
    EGWuint16 tiFlags;                      ///< Task item flags.
    EGWint8 ttDeps;                         ///< Total number of tasks this task is dependent on.
    EGWint8 twDeps;                         ///< Number of tasks this task is waiting for.
    EGWint8 tdDeps;                         ///< Total number of tasks dependent on this task.
    EGWint8 ttIndicies[EGW_TASKMNGR_MAXTASKDEPENDENTS]; ///< Task dependency indicies for linkage to tasks this task is dependent on (left).
    EGWint8 tdIndicies[EGW_TASKMNGR_MAXTASKDEPENDENTS]; ///< Task dependency indicies for linkage to tasks dependent on this task (right).
} egwTaskItem;

/// Task Dependency Structure.
typedef struct {
    EGWuint8 tdFlags;                       ///< Task dependency flags.
    EGWint8 ttiIndex;                       ///< Task item index.
    EGWint8 tdiIndex;                       ///< Task depedent-on item index.
} egwTaskDependency;


/// Task Manager.
/// Manages instances and executions of cyclic tasks and performs operations relating to such.
@interface egwTaskManager : NSThread <egwPSingleton> {
    pthread_mutex_t _cLock;                 ///< Counter mutex lock.
    pthread_cond_t _wCond;                  ///< Work wait signal condition.
    NSThread* _tPool[EGW_TASKMNGR_TASKTHREADS]; ///< Task threads pool.
    id<egwPTask> _tOwner[EGW_TASKMNGR_TASKTHREADS]; ///< Task thread owner (retained).
    
    EGWuint16 _ttCount;                                 ///< Task threads (up) count.
    EGWuint16 _tiCount;                                 ///< Task items count.
    EGWint8 _tHndLkup[EGW_TASKMNGR_MAXTASKHANDLES];     ///< Task handle -> index lookup.
    egwTaskItem _tItems[EGW_TASKMNGR_MAXTASKHANDLES];   ///< Task items array.
    EGWuint _tdCount;                                   ///< Task dependencies count.
    egwTaskDependency _tDeps[EGW_TASKMNGR_MAXDEPENDENCIES]; ///< Task dependencies array.
    
    BOOL _threadAlert[EGW_TASKMNGR_TASKTHREADS]; ///< Tracks thread alert status.
    BOOL _doMemClean[EGW_TASKMNGR_TASKTHREADS]; ///< Tracks memory cleanup status.
    EGWuint8 _memCleanLeft;                 ///< Tracks number of threads left to clean.
    
    BOOL _doShutdownPh1;                    ///< Tracks phase 1 shut down status.
    BOOL _doShutdownPh2;                    ///< Tracks phase 2 shut down status.
}

/// Enable All Tasks Method.
/// Sets all managed tasks to enabled status.
- (void)enableAllTasks;

/// Enable Task Method.
/// Sets managed task with @a taskHandle to enabled status.
/// @param [in] taskHandle Task handle identifier.
- (void)enableTask:(EGWint)taskHandle;

/// Disable All Tasks Method.
/// Sets all managed tasks to disabled status.
- (void)disableAllTasks;

/// Disable Task Method.
/// Sets managed task with @a taskHandle to disabled status.
/// @param [in] taskHandle Task handle identifier.
- (void)disableTask:(EGWint)taskHandle;

/// Jump Start Task Method.
/// Sets managed task with @a taskHandle to starter task status.
/// @note This method is provided for simplicity.
/// @param [in] taskHandle Task handle identifier.
- (void)jumpStartTask:(EGWint)taskHandle;

/// Register Task (using) Method.
/// Registers the provided @a task into the managed task set.
/// @param [in] task Task object instance.
/// @return Task handle identifier.
- (EGWint)registerTaskUsing:(id<egwPTask>)task;

/// Register Starter Task (using) Method.
/// Registers the provided @a task into the managed task set with starter task status.
/// @param [in] task Task object instance.
/// @return Task handle identifier.
- (EGWint)registerStarterTaskUsing:(id<egwPTask>)task;

/// Register Temporary Task (using) Method.
/// Registers the provided @a task into the managed task set with temporary task status.
/// @param [in] task Task object instance.
/// @return Task handle identifier.
- (EGWint)registerTemporaryTaskUsing:(id<egwPTask>)task;

/// Register Dependency (forTaskWithDepOnTask) Method.
/// Registers a dependency relation between provided @a taskHandle and its dependent @a depTaskHandle.
/// @param [in] taskHandle Task handle identifier.
/// @param [in] depTaskHandle Dependent task handle identifier.
/// @return YES if registration successful, otherwise NO.
- (BOOL)registerDependencyForTask:(EGWint)taskHandle withTask:(EGWint)depTaskHandle;

/// Unregister All Tasks Method.
/// Removes all tasks and their dependencies from the managed task set.
/// @note Calling this method from inside a task manager thread may cause deadlock.
- (void)unregisterAllTasks;

/// Unregister All Tasks (using) Method.
/// Removes all tasks using @a task and their dependencies from the managed task set.
/// @note Calling this method from inside a task manager thread may cause deadlock.
/// @param [in] task Task object instance.
- (void)unregisterAllTasksUsing:(id<egwPTask>)task;

/// Unregister Task Method.
/// Removes task @a taskHandle and any of its dependencies from the managed task set.
/// @note Calling this method from inside a task manager thread may cause deadlock.
/// @param [in] taskHandle Task handle identifier.
- (void)unregisterTask:(EGWint)taskHandle;

/// Perform Memory Cleanup Method.
/// Forces release of auto-release pools tp try to free up memory not being used up by the underlying system.
/// @note This method blocks until all task threads have responded to the cleanup request.
- (void)performMemoryCleanup;

/// Shut Down Task Threads Method.
/// Signals task threads to shut down.
/// @note This method blocks until all tasks are removed (or timeout), taks being responsible for removing themselves.
- (void)shutDownTaskThreads;


/// Dependency Count Accessor.
/// Returns the number of dependencies tracked in the managed task set.
/// @return Number of dependencies.
- (EGWuint)depdendencyCount;

/// Task Count Accessor.
/// Returns the number of tasks tracked in the managed task set.
/// @return Number of tasks.
- (EGWuint)taskCount;


/// IsShuttingDownTaskThreads Poller.
/// Polls the object to determine status.
/// @return YES if the task manager is shutting down its task threads, otherwise NO.
- (BOOL)isShuttingDownTaskThreads;

/// IsTaskEnabled Poller.
/// Polls the object to determine status.
/// @param [in] taskHandle Task handle identifier.
/// @return YES if the task is enabled, otherwise NO.
- (BOOL)isTaskEnabled:(EGWint)taskHandle;

/// IsTaskManagerThread Poller.
/// Polls the object to determine status.
/// @return YES if current thread is owned by task manager, otherwise NO.
- (BOOL)isTaskManagerThread;

@end


/// Global current singleton egwTaskManager instance (weak).
extern egwTaskManager* egwSITaskMngr;

/// @}

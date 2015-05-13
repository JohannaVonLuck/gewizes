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

/// @file egwTaskManager.m
/// @ingroup geWizES_sys_taskmanager
/// Task Manager Implementation.

#import <pthread.h>
#import "egwTaskManager.h"
#import "../sys/egwEngine.h"
#import "../sys/egwGfxContext.h"
#import "../sys/egwPhyContext.h"
#import "../sys/egwSndContext.h"
#import "../math/egwMath.h"
#import "../misc/egwBoxingTypes.h"


#define EGW_TSKITMFLG_NONE          0x0000  // No flags.
#define EGW_TSKITMFLG_DISABLED      0x0100  // Task is disabled.
#define EGW_TSKITMFLG_ISRUNNING     0x0200  // Task is running.
#define EGW_TSKITMFLG_STARTER       0x0400  // Task is a starter task.
#define EGW_TSKITMFLG_TEMPORARY     0x0800  // Task is a temporary/run-once.
#define EGW_TSKITMFLG_OWNSTHRD      0x1000  // Task owns a thread.
#define EGW_TSKITMFLG_MARKEDREM     0x8000  // Task is marked for removal.
#define EGW_TSKITMFLG_EXLASTTHRD    0x00ff  // Used to extract last used thread from bitfield.

#define EGW_TSKDPDFLG_NONE          0x00    // No flags.
#define EGW_TSKDPDFLG_SATISFIED     0x01    // Dependent task has ran.


egwTaskManager* egwSITaskMngr = nil;


// !!!: ***** egwTaskManager *****

@interface egwTaskManager (Private)
- (void)unregisterTaskAlreadyLocked:(EGWint)taskHandle;
- (void)taskThreadEntryPoint;
- (void)taskThreadMainLoop:(NSAutoreleasePool**)arPool;
@end


@implementation egwTaskManager

static egwTaskManager* _singleton = nil;

+ (id)alloc {
    @synchronized(self) {
        if(!_singleton)
            egwSITaskMngr = _singleton = [super alloc];
    }
    return _singleton;
}

- (id)init {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    _tiCount = _tdCount = 0;
    
    memset((void*)&(_tItems[0]), 0, sizeof(egwTaskItem) * EGW_TASKMNGR_MAXTASKHANDLES);
    memset((void*)&(_tDeps[0]), 0, sizeof(egwTaskDependency) * EGW_TASKMNGR_MAXDEPENDENCIES);
    
    if(pthread_mutex_init(&_cLock, NULL)) { [self release]; return (self = nil); }
    if(pthread_cond_init(&_wCond, NULL)) { [self release]; return (self = nil); }
    
    // Set up task handle lookup
    for(EGWint taskIndex = 0; taskIndex < EGW_TASKMNGR_MAXTASKHANDLES; ++taskIndex)
        _tHndLkup[taskIndex] = -1;
    
    // Initialize task threads first, then start afterwords
    for(EGWint threadIndex = 0; threadIndex < EGW_TASKMNGR_TASKTHREADS; ++threadIndex) {
        if(!(_tPool[threadIndex] = [[NSThread alloc] initWithTarget:self selector:@selector(taskThreadEntryPoint) object:nil])) { [self release]; return (self = nil); }
        [_tPool[threadIndex] setName:[[NSString alloc] initWithFormat:@"egwTaskManagerTaskThread%02d", (threadIndex+1)]];
        _tOwner[threadIndex] = nil;
    }
    for(EGWint threadIndex = 0; threadIndex < EGW_TASKMNGR_TASKTHREADS; ++threadIndex)
        [_tPool[threadIndex] start];
    
    if(EGW_ENGINE_MANAGERS_STARTUPMSGS) NSLog(@"egwTaskManager: init: Task manager has been initialized.");
    
    return self;
}

+ (void)dealloc {
    @synchronized(self) {
        [_singleton release];
        egwSITaskMngr = _singleton = nil;
    }
    if(0) [super dealloc];
}

- (void)dealloc {
    if(!_doShutdownPh1 && !_doShutdownPh2)
        [self shutDownTaskThreads];
    
    for(EGWint threadIndex = 0; threadIndex < EGW_TASKMNGR_TASKTHREADS; ++threadIndex) {
        [_tPool[threadIndex] release]; _tPool[threadIndex] = nil;
        [_tOwner[threadIndex] release]; _tOwner[threadIndex] = nil;
    }
    
    for(EGWint taskIndex = 0; taskIndex < EGW_TASKMNGR_MAXTASKHANDLES; ++taskIndex) {
        [_tItems[taskIndex].task release]; _tItems[taskIndex].task = nil;
    }
    
    pthread_cond_destroy(&_wCond);
    pthread_mutex_destroy(&_cLock);
    
    if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwTaskManager: dealloc: Task manager has been deallocated.");
    
    [super dealloc];
}

- (void)enableAllTasks {
    if(!_doShutdownPh1 && _tiCount) {
        pthread_mutex_lock(&_cLock);
        
        if(_tiCount) {
            EGWint taskIndex = _tiCount; while(taskIndex--)
                if(_tItems[taskIndex].task)
                    _tItems[taskIndex].tiFlags &= ~EGW_TSKITMFLG_DISABLED;
        
            pthread_cond_broadcast(&_wCond);
        }
        
        pthread_mutex_unlock(&_cLock);
    }
}

- (void)enableTask:(EGWint)taskHandle {
    if(!_doShutdownPh1 && _tiCount && taskHandle >= 1 && _tHndLkup[taskHandle-1] >= 0) {
        pthread_mutex_lock(&_cLock);
        
        if(_tiCount && taskHandle >= 1 && _tHndLkup[taskHandle-1] >= 0) {
            taskHandle = (EGWint)_tHndLkup[taskHandle-1];
            
            _tItems[taskHandle].tiFlags &= ~EGW_TSKITMFLG_DISABLED;
            
            pthread_cond_broadcast(&_wCond);
        }
        
        pthread_mutex_unlock(&_cLock);
    }
}

- (void)disableAllTasks {
    if(!_doShutdownPh1 && _tiCount) {
        pthread_mutex_lock(&_cLock);
        
        if(_tiCount) {
            EGWint taskIndex = _tiCount; while(taskIndex--)
                if(_tItems[taskIndex].task)
                    _tItems[taskIndex].tiFlags |= EGW_TSKITMFLG_DISABLED;
        }
        
        pthread_mutex_unlock(&_cLock);
    }
}

- (void)disableTask:(EGWint)taskHandle {
    if(!_doShutdownPh1 && _tiCount && taskHandle >= 1 && _tHndLkup[taskHandle-1] >= 0) {
        pthread_mutex_lock(&_cLock);
        
        if(_tiCount && taskHandle >= 1 && _tHndLkup[taskHandle-1] >= 0) {
            taskHandle = (EGWint)_tHndLkup[taskHandle-1];
            
            _tItems[taskHandle].tiFlags |= EGW_TSKITMFLG_DISABLED;
            
            pthread_cond_broadcast(&_wCond);
        }
        
        pthread_mutex_unlock(&_cLock);
    }
}

- (void)jumpStartTask:(EGWint)taskHandle {
    if(!_doShutdownPh1 && _tiCount && taskHandle >= 1 && _tHndLkup[taskHandle-1] >= 0) {
        pthread_mutex_lock(&_cLock);
        
        if(_tiCount && taskHandle >= 1 && _tHndLkup[taskHandle-1] >= 0) {
            taskHandle = (EGWint)_tHndLkup[taskHandle-1];
            
            _tItems[taskHandle].tiFlags |= EGW_TSKITMFLG_STARTER;
            _tItems[taskHandle].tiFlags &= ~EGW_TSKITMFLG_DISABLED;
        
            pthread_cond_broadcast(&_wCond);
        }
        
        pthread_mutex_unlock(&_cLock);
    }
}

- (EGWint)registerTaskUsing:(id<egwPTask>)task {
    if(!_doShutdownPh1 && task && _tiCount < EGW_TASKMNGR_MAXTASKHANDLES) {
        pthread_mutex_lock(&_cLock);
        
        if(task && _tiCount < EGW_TASKMNGR_MAXTASKHANDLES) {
            EGWint handleIndex = 0;
            for(; handleIndex < EGW_TASKMNGR_MAXTASKHANDLES; ++handleIndex)
                if(_tHndLkup[handleIndex] == -1) {
                    _tHndLkup[handleIndex] = _tiCount;
                    break;
                }
            
            if(handleIndex < EGW_TASKMNGR_MAXTASKHANDLES) {
                _tItems[_tiCount].task = [task retain];
                _tItems[_tiCount].tiFlags = EGW_TSKITMFLG_NONE | EGW_TSKITMFLG_DISABLED | ([task isThreadOwner] ? EGW_TSKITMFLG_OWNSTHRD : 0);
                _tItems[_tiCount].tPriority = (EGWsingle)[task taskPriority];
                _tItems[_tiCount].ttDeps = 0;
                _tItems[_tiCount].twDeps = 0;
                _tItems[_tiCount].tdDeps = 0;
                memset((void*)&(_tItems[_tiCount].ttIndicies[0]), -1, sizeof(EGWint8) * EGW_TASKMNGR_MAXTASKDEPENDENTS);
                memset((void*)&(_tItems[_tiCount].tdIndicies[0]), -1, sizeof(EGWint8) * EGW_TASKMNGR_MAXTASKDEPENDENTS);
                _tItems[_tiCount].fpPrfmTask = [((NSObject*)_tItems[_tiCount].task) methodForSelector:@selector(performTask)];
                
                ++_tiCount;
                
                pthread_mutex_unlock(&_cLock);
                return handleIndex+1;
            }
        }
        
        pthread_mutex_unlock(&_cLock);
    }
    
    return 0;
}

- (EGWint)registerStarterTaskUsing:(id<egwPTask>)task {
    if(!_doShutdownPh1 && task && _tiCount < EGW_TASKMNGR_MAXTASKHANDLES) {
        pthread_mutex_lock(&_cLock);
        
        if(task && _tiCount < EGW_TASKMNGR_MAXTASKHANDLES) {
            EGWint handleIndex = 0;
            for(; handleIndex < EGW_TASKMNGR_MAXTASKHANDLES; ++handleIndex)
                if(_tHndLkup[handleIndex] == -1) {
                    _tHndLkup[handleIndex] = _tiCount;
                    break;
                }
            
            if(handleIndex < EGW_TASKMNGR_MAXTASKHANDLES) {
                _tItems[_tiCount].task = [task retain];
                _tItems[_tiCount].tiFlags = EGW_TSKITMFLG_NONE | EGW_TSKITMFLG_DISABLED | EGW_TSKITMFLG_STARTER | ([task isThreadOwner] ? EGW_TSKITMFLG_OWNSTHRD : 0);
                _tItems[_tiCount].tPriority = (EGWsingle)[task taskPriority];
                _tItems[_tiCount].ttDeps = 0;
                _tItems[_tiCount].twDeps = 0;
                _tItems[_tiCount].tdDeps = 0;
                memset((void*)&(_tItems[_tiCount].ttIndicies[0]), -1, sizeof(EGWint8) * EGW_TASKMNGR_MAXTASKDEPENDENTS);
                memset((void*)&(_tItems[_tiCount].tdIndicies[0]), -1, sizeof(EGWint8) * EGW_TASKMNGR_MAXTASKDEPENDENTS);
                _tItems[_tiCount].fpPrfmTask = [((NSObject*)_tItems[_tiCount].task) methodForSelector:@selector(performTask)];
                
                ++_tiCount;
                
                pthread_mutex_unlock(&_cLock);
                return handleIndex+1;
            }
        }
        
        pthread_mutex_unlock(&_cLock);
    }
    
    return 0;
}

- (EGWint)registerTemporaryTaskUsing:(id<egwPTask>)task {
    if(!_doShutdownPh1 && task && _tiCount < EGW_TASKMNGR_MAXTASKHANDLES) {
        pthread_mutex_lock(&_cLock);
        
        if(task && _tiCount < EGW_TASKMNGR_MAXTASKHANDLES) {
            EGWint handleIndex = 0;
            for(; handleIndex < EGW_TASKMNGR_MAXTASKHANDLES; ++handleIndex)
                if(_tHndLkup[handleIndex] == -1) {
                    _tHndLkup[handleIndex] = _tiCount;
                    break;
                }
            
            if(handleIndex < EGW_TASKMNGR_MAXTASKHANDLES) {
                _tItems[_tiCount].task = [task retain];
                _tItems[_tiCount].tiFlags = EGW_TSKITMFLG_NONE | EGW_TSKITMFLG_DISABLED | EGW_TSKITMFLG_TEMPORARY | ([task isThreadOwner] ? EGW_TSKITMFLG_OWNSTHRD : 0);
                _tItems[_tiCount].tPriority = (EGWsingle)[task taskPriority];
                _tItems[_tiCount].ttDeps = 0;
                _tItems[_tiCount].twDeps = 0;
                _tItems[_tiCount].tdDeps = 0;
                memset((void*)&(_tItems[_tiCount].ttIndicies[0]), -1, sizeof(EGWint8) * EGW_TASKMNGR_MAXTASKDEPENDENTS);
                memset((void*)&(_tItems[_tiCount].tdIndicies[0]), -1, sizeof(EGWint8) * EGW_TASKMNGR_MAXTASKDEPENDENTS);
                _tItems[_tiCount].fpPrfmTask = [((NSObject*)_tItems[_tiCount].task) methodForSelector:@selector(performTask)];
                
                ++_tiCount;
                
                pthread_mutex_unlock(&_cLock);
                return handleIndex+1;
            }
        }
        
        pthread_mutex_unlock(&_cLock);
    }
    
    return 0;
}

- (BOOL)registerDependencyForTask:(EGWint)taskHandle withTask:(EGWint)depTaskHandle {
    if(!_doShutdownPh1 && _tiCount && _tdCount < EGW_TASKMNGR_MAXDEPENDENCIES && taskHandle >= 1 && _tHndLkup[taskHandle-1] >= 0 && depTaskHandle >= 1 && _tHndLkup[depTaskHandle-1] >= 0) {
        pthread_mutex_lock(&_cLock);
        
        if(_tiCount && _tdCount < EGW_TASKMNGR_MAXDEPENDENCIES && taskHandle >= 1 && _tHndLkup[taskHandle-1] >= 0 && depTaskHandle >= 1 && _tHndLkup[depTaskHandle-1] >= 0) {
            taskHandle = (EGWint)_tHndLkup[taskHandle-1];
            depTaskHandle = (EGWint)_tHndLkup[depTaskHandle-1];
            
            _tDeps[_tdCount].tdFlags = EGW_TSKDPDFLG_NONE;
            _tDeps[_tdCount].ttiIndex = taskHandle;
            _tDeps[_tdCount].tdiIndex = depTaskHandle;
            
            _tItems[taskHandle].ttIndicies[_tItems[taskHandle].ttDeps++] = _tdCount; // left linkages
            _tItems[depTaskHandle].tdIndicies[_tItems[depTaskHandle].tdDeps++] = _tdCount; // right linkages
            
            ++_tItems[taskHandle].twDeps;
            
            ++_tdCount;
            
            pthread_mutex_unlock(&_cLock);
            return YES;
        }
        
        pthread_mutex_unlock(&_cLock);
    }
    
    return NO;
}

- (void)performMemoryCleanup {
    if(!_doShutdownPh1) {
        @synchronized(self) {
            pthread_mutex_lock(&_cLock);
            
            for(EGWint threadIndex = 0; threadIndex < EGW_TASKMNGR_TASKTHREADS; ++threadIndex) {
                if(_tPool[threadIndex]) {
                    _doMemClean[threadIndex] = YES;
                    ++_memCleanLeft;
                    _threadAlert[threadIndex] = YES;
                }
            }
            
            if(_memCleanLeft)
                pthread_cond_broadcast(&_wCond);
            
            {   NSDate* waitTill = [[NSDate alloc] initWithTimeIntervalSinceNow:(NSTimeInterval)EGW_ENGINE_MANAGERS_TIMETOWAIT];
                while(_memCleanLeft) {   
                    if([waitTill timeIntervalSinceNow] < (NSTimeInterval)0.0) {
                        NSLog(@"egwTaskManager: performMemoryCleanup: Failure waiting for %d task(s) to report memory cleanup.", _memCleanLeft);
                        break;
                    }
                    
                    pthread_mutex_unlock(&_cLock);
                    [NSThread sleepForTimeInterval:EGW_ENGINE_MANAGERS_TIMETOSLEEP];
                    pthread_mutex_lock(&_cLock);
                    pthread_cond_broadcast(&_wCond);
                }
                [waitTill release];
            }
            
            pthread_mutex_unlock(&_cLock);
        }
    }
}

- (void)shutDownTaskThreads {
    if(!_doShutdownPh1 && !_doShutdownPh2) {
        @synchronized(self) {
            if(!_doShutdownPh1 && !_doShutdownPh2) {
                pthread_mutex_lock(&_cLock);
                
                if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwTaskManager: shutDownTaskThreads: Shutting down task threads.");
                
                _doShutdownPh1 = YES; // Forces task removal
                
                // Take corresponding task off all process blocks (delayed removal)
                {   EGWint taskIndex = _tiCount; while(taskIndex--)
                        if(_tItems[taskIndex].task)
                            _tItems[taskIndex].tiFlags |= (EGW_TSKITMFLG_DISABLED | EGW_TSKITMFLG_MARKEDREM);
                }
                
                for(EGWint threadIndex = 0; threadIndex < EGW_TASKMNGR_TASKTHREADS; ++threadIndex)
                    if(_tPool[threadIndex])
                        _threadAlert[threadIndex] = YES;
                
                pthread_cond_broadcast(&_wCond);
                
                {   NSDate* waitTill = [[NSDate alloc] initWithTimeIntervalSinceNow:(NSTimeInterval)EGW_ENGINE_MANAGERS_TIMETOWAIT];
                    while(_tiCount) {
                        if([waitTill timeIntervalSinceNow] < (NSTimeInterval)0.0) {
                            for(EGWint i = 0; i < EGW_TASKMNGR_MAXTASKHANDLES; ++i) {
                                if(_tItems[i].task) {
                                    EGWint j = EGW_TASKMNGR_MAXTASKHANDLES;
                                    while(j--)
                                        if(_tHndLkup[j] == i)
                                            break;
                                    NSLog(@"egwTaskManager: shutDownTaskThreads: Failure waiting on task '%@' with task handle #%d to unregister.", _tItems[i].task, j+1);
                                }
                            }
                            break;
                        }
                        
                        pthread_mutex_unlock(&_cLock);
                        [NSThread sleepForTimeInterval:EGW_ENGINE_MANAGERS_TIMETOSLEEP];
                        pthread_mutex_lock(&_cLock);
                        pthread_cond_broadcast(&_wCond);
                    }
                    [waitTill release];
                }
                
                _doShutdownPh2 = YES; // Forces thread shutdown
                
                for(EGWint threadIndex = 0; threadIndex < EGW_TASKMNGR_TASKTHREADS; ++threadIndex)
                    if(_tPool[threadIndex])
                        _threadAlert[threadIndex] = YES;
                
                pthread_cond_broadcast(&_wCond);
                
                {   NSDate* waitTill = [[NSDate alloc] initWithTimeIntervalSinceNow:(NSTimeInterval)EGW_ENGINE_MANAGERS_TIMETOWAIT];
                    while(_ttCount) {
                        if([waitTill timeIntervalSinceNow] < (NSTimeInterval)0.0) {
                            NSLog(@"egwTaskManager: shutDownTaskThreads: Failure waiting for %d task thread(s) to quit.", _ttCount);
                            break;
                        }
                        
                        pthread_mutex_unlock(&_cLock);
                        [NSThread sleepForTimeInterval:EGW_ENGINE_MANAGERS_TIMETOSLEEP];
                        pthread_mutex_lock(&_cLock);
                        pthread_cond_broadcast(&_wCond);
                    }
                    [waitTill release];
                }
                
                pthread_mutex_unlock(&_cLock);
                
                if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwTaskManager: shutDownTaskThreads: Task threads shut down.");
            }
        }
    }
}

- (void)unregisterAllTasks {
    pthread_mutex_lock(&_cLock);
    
    // Take all tasks off all process blocks (delayed removal)
    EGWint taskIndex = _tiCount; while(taskIndex--)
        if(_tItems[taskIndex].task)
            _tItems[taskIndex].tiFlags |= (EGW_TSKITMFLG_DISABLED | EGW_TSKITMFLG_MARKEDREM);
    
    pthread_mutex_unlock(&_cLock);
}

- (void)unregisterAllTasksUsing:(id<egwPTask>)task {
    if(task) {
        pthread_mutex_lock(&_cLock);
        
        // Take corresponding task off all process blocks (delayed removal)
        EGWint taskIndex = _tiCount; while(taskIndex--)
            if(_tItems[taskIndex].task == task)
                _tItems[taskIndex].tiFlags |= (EGW_TSKITMFLG_DISABLED | EGW_TSKITMFLG_MARKEDREM);
        
        pthread_mutex_unlock(&_cLock);
    }
}

- (void)unregisterTask:(EGWint)taskHandle {
    if(_tiCount && _tdCount < EGW_TASKMNGR_MAXDEPENDENCIES && taskHandle >= 1 && _tHndLkup[taskHandle-1] >= 0) {
        pthread_mutex_lock(&_cLock);
        
        [self unregisterTaskAlreadyLocked:taskHandle];
        
        pthread_mutex_unlock(&_cLock);
    }
}

- (id)copy {
    return _singleton;
}

- (id)mutableCopy {
    return _singleton;
}

- (EGWuint)depdendencyCount {
    return (EGWuint)_tdCount;
}

+ (id)sharedSingleton {
    return _singleton;
}

- (EGWuint)taskCount {
    return (EGWuint)_tiCount;
}

+ (BOOL)isAllocated {
    return (_singleton ? YES : NO);
}

- (BOOL)isShuttingDownTaskThreads {
    return _doShutdownPh1 || _doShutdownPh2;
}

- (BOOL)isTaskEnabled:(EGWint)taskHandle {
    if(taskHandle >= 1 && taskHandle <= EGW_TASKMNGR_MAXTASKHANDLES && _tHndLkup[taskHandle-1] >= 0)
        return ((_tItems[_tHndLkup[taskHandle-1]].tiFlags & EGW_TSKITMFLG_DISABLED) ? NO : YES);
    return NO;
}

- (BOOL)isTaskManagerThread {
    NSThread* currentThread = [NSThread currentThread];
    
    EGWint threadIndex = EGW_TASKMNGR_TASKTHREADS; while(threadIndex--)
        if(_tPool[threadIndex] == currentThread)
            return YES;
    
    return NO;
}

@end


@implementation egwTaskManager (Private)

- (void)unregisterTaskAlreadyLocked:(EGWint)taskHandle {
    if(_tiCount && _tdCount < EGW_TASKMNGR_MAXDEPENDENCIES && taskHandle >= 1 && _tHndLkup[taskHandle-1] >= 0) {
        taskHandle = (EGWint)_tHndLkup[taskHandle-1];
        
        // Take task off process block (delayed removal if running)
        _tItems[taskHandle].tiFlags |= (EGW_TSKITMFLG_DISABLED | EGW_TSKITMFLG_MARKEDREM);
        
        // If the task is running, don't remove it, rely on the MARKEDREM flag to force remove after finished running, call to this will be made afterword
        if(!(_tItems[taskHandle].tiFlags & EGW_TSKITMFLG_ISRUNNING)) {
            EGWint index;
            
            // Cannot continue if any task with taskIndex higher than taskHandle is currently in run state due to selTaskIndex being shifted
            index = _tiCount; while(--index > taskHandle)
                if(_tItems[index].tiFlags & EGW_TSKITMFLG_ISRUNNING)
                    return;
            
            // Go through handle table and remove reference to taskHandle, also offset/decrement anything > taskHandle
            index = EGW_TASKMNGR_MAXTASKHANDLES; while(index--) {
                if(_tHndLkup[index] == taskHandle)
                    _tHndLkup[index] = -1;
                else if(_tHndLkup[index] > taskHandle)
                    --_tHndLkup[index];
            }
            
            // Go through dependency table removing any dependencys that reference taskHandle
            index = _tdCount; while(index--) {
                if(_tDeps[index].ttiIndex == taskHandle || _tDeps[index].tdiIndex == taskHandle) { // Removing this one!
                    EGWint taskIndex;
                    
                    // Ensure a correct twDep count on tasks dependent on the one we're removing
                    if(_tDeps[index].tdiIndex == taskHandle) { // We're dependent to next - decrease their twDeps
                        if(!(_tDeps[index].tdFlags & EGW_TSKDPDFLG_SATISFIED)) { // We haven't satisfied their dwDep count
                            --_tItems[_tDeps[index].ttiIndex].twDeps;
                            _tDeps[index].tdFlags |= EGW_TSKDPDFLG_SATISFIED;
                        }
                    } // NOTE: ttDeps will get correctly set in the next run
                    
                    // Go through _EVERY_ task handle and sniff/remove index from ttIndicies & tdIndicies, also offset/decrement anything > index
                    taskIndex = _tiCount; while(taskIndex--) {
                        if(taskIndex != taskHandle) { // Skip the one we're removing
                            EGWint linkIndex;
                            
                            // Remove from ttIndicies & scoot down
                            linkIndex = _tItems[taskIndex].ttDeps; while(linkIndex--) {
                                if(_tItems[taskIndex].ttIndicies[linkIndex] == index) {
                                    for(EGWint scootIndex = linkIndex; scootIndex < _tItems[taskIndex].ttDeps - 1; ++scootIndex)
                                        _tItems[taskIndex].ttIndicies[scootIndex] = _tItems[taskIndex].ttIndicies[scootIndex+1];
                                    _tItems[taskIndex].ttIndicies[_tItems[taskIndex].ttDeps-1] = -1;
                                    --_tItems[taskIndex].ttDeps;
                                }
                            }
                            // Remove from tdIndicies & scoot down
                            linkIndex = _tItems[taskIndex].tdDeps; while(linkIndex--) {
                                if(_tItems[taskIndex].tdIndicies[linkIndex] == index) {
                                    for(EGWint scootIndex = linkIndex; scootIndex < _tItems[taskIndex].tdDeps - 1; ++scootIndex)
                                        _tItems[taskIndex].tdIndicies[scootIndex] = _tItems[taskIndex].tdIndicies[scootIndex+1];
                                    _tItems[taskIndex].tdIndicies[_tItems[taskIndex].tdDeps-1] = -1;
                                    --_tItems[taskIndex].tdDeps;
                                }
                            }
                            // Offset ttIndicies that are > index
                            linkIndex = _tItems[taskIndex].ttDeps; while(linkIndex--) {
                                if(_tItems[taskIndex].ttIndicies[linkIndex] > index)
                                    --_tItems[taskIndex].ttIndicies[linkIndex];
                            }
                            // Offset tdIndicies that are > index
                            linkIndex = _tItems[taskIndex].tdDeps; while(linkIndex--) {
                                if(_tItems[taskIndex].tdIndicies[linkIndex] > index)
                                    --_tItems[taskIndex].tdIndicies[linkIndex];
                            }
                        }
                    }
                    
                    // Remove from tDeps & scoot down
                    for(EGWint scootIndex = index; scootIndex < _tdCount - 1; ++scootIndex)
                        memcpy((void*)&(_tDeps[scootIndex]), (const void*)&(_tDeps[scootIndex+1]), sizeof(egwTaskDependency));
                    memset((void*)&(_tDeps[_tdCount-1]), 0, sizeof(egwTaskDependency));
                    --_tdCount;
                }
            }
            
            // Offset tDeps that are > taskHandle
            index = _tdCount; while(index--) {
                if(_tDeps[index].ttiIndex > taskHandle) --_tDeps[index].ttiIndex;
                if(_tDeps[index].tdiIndex > taskHandle) --_tDeps[index].tdiIndex;
            }
            
            // Release any ownerships
            index = EGW_TASKMNGR_TASKTHREADS; while(index--) {
                if(_tOwner[index] == _tItems[taskHandle].task) {
                    [_tOwner[index] release]; _tOwner[index] = nil;
                }
            }
            
            [_tItems[taskHandle].task release]; _tItems[taskHandle].task = nil;
            
            // Remove from tItems & scoot down
            for(EGWint scootIndex = taskHandle; scootIndex < _tiCount - 1; ++scootIndex)
                memcpy((void*)&(_tItems[scootIndex]), (const void*)&(_tItems[scootIndex+1]), sizeof(egwTaskItem));
            memset((void*)&(_tItems[_tiCount-1]), 0, sizeof(egwTaskItem));
            
            --_tiCount;
        }
    }
}

- (void)taskThreadEntryPoint {
    NSAutoreleasePool* arPool = [[NSAutoreleasePool alloc] init];
    
    [self taskThreadMainLoop:&arPool];
    
    [arPool release]; arPool = nil;
}

- (void)taskThreadMainLoop:(NSAutoreleasePool**)arPool {
    EGWsingle threadPriority = (EGWsingle)[NSThread threadPriority];
    EGWuint8 index, selTaskIndex, threadNumber, oddJobCounter = EGW_ENGINE_MANAGERS_ODDJOBSPINCYCLE;
    time_t drainAfter = time(NULL) + (time_t)EGW_ENGINE_MANAGERS_TIMETODRAIN;
    
    // Determine this thread number
    for(threadNumber = 1; threadNumber <= EGW_TASKMNGR_TASKTHREADS; ++threadNumber)
        if(_tPool[threadNumber-1] == [NSThread currentThread])
            break;
    
    // Thread alert poller to switch to odd jobs
    BOOL* threadAlert = &_threadAlert[threadNumber-1];
    
    pthread_mutex_lock(&_cLock);
    ++_ttCount;
    pthread_mutex_unlock(&_cLock);
    
    if(EGW_ENGINE_MANAGERS_STARTUPMSGS) NSLog(@"egwTaskManager: taskThreadMainLoop: Task thread #%d starting up.", threadNumber);
    
    // NOTICE: TIER 0 CODE SECTION!
    while(1) {
        if(oddJobCounter-- && _tiCount && !*threadAlert) {
            pthread_mutex_lock(&_cLock);
            
            selTaskIndex = _tiCount; // sentinel
            
            index = _tiCount; while(index--) {
                if(((_tItems[index].twDeps == 0 || (_tItems[index].tiFlags & EGW_TSKITMFLG_STARTER)) &&
                   !(_tItems[index].tiFlags & (EGW_TSKITMFLG_DISABLED | EGW_TSKITMFLG_ISRUNNING))) ||
                   (_tItems[index].tiFlags & EGW_TSKITMFLG_MARKEDREM)) {
                    register EGWuint lastThread = (EGWuint)(_tItems[index].tiFlags & EGW_TSKITMFLG_EXLASTTHRD);
                    
                    if(lastThread == threadNumber ||
                       (!lastThread && (!(_tItems[index].tiFlags & EGW_TSKITMFLG_OWNSTHRD) || (_tOwner[threadNumber-1] == nil || _tOwner[threadNumber-1] == _tItems[index].task)))) { // Only one task thread owner per thread
                        selTaskIndex = index; // Always prefer same thread last executed on
                        
                        if(!lastThread && (_tItems[index].tiFlags & EGW_TSKITMFLG_OWNSTHRD)) // Enable ownership of thread if being used for first time by a task thread owner
                            _tOwner[threadNumber-1] = [_tItems[index].task retain];
                        
                        break; // No more options to consider at this point
                    } else if(!(_tItems[index].tiFlags & EGW_TSKITMFLG_OWNSTHRD)) { // Don't consider this task any longer if task owns its thread, and we ain't that thread
                        if(selTaskIndex == _tiCount) // sentinel, use first available
                            selTaskIndex = index;
                        else if(_tItems[index].tPriority == threadPriority && _tItems[selTaskIndex].tPriority != threadPriority) // match better priority
                            selTaskIndex = index;
                    } else if(_tItems[index].tiFlags & EGW_TSKITMFLG_MARKEDREM) {
                        selTaskIndex = index; // Always can do for a removal
                        break;
                    }
                }
            }
            
            if(selTaskIndex != _tiCount) {
                if(!(_tItems[selTaskIndex].tiFlags & EGW_TSKITMFLG_MARKEDREM)) {
                    // These are here before unlock so that other threads don't grab them after we already have
                    _tItems[selTaskIndex].twDeps = _tItems[selTaskIndex].ttDeps;
                    _tItems[selTaskIndex].tiFlags &= ~(EGW_TSKITMFLG_STARTER | EGW_TSKITMFLG_EXLASTTHRD);
                    _tItems[selTaskIndex].tiFlags |= (EGW_TSKITMFLG_ISRUNNING | ((EGWuint16)threadNumber & EGW_TSKITMFLG_EXLASTTHRD));
                    
                    if(threadPriority != _tItems[selTaskIndex].tPriority)
                        egwSFPNSThreadSetThreadPriority(nil, @selector(setThreadPriority:), (double)(threadPriority = _tItems[selTaskIndex].tPriority));
                    
                    pthread_mutex_unlock(&_cLock);
                    
                    _tItems[selTaskIndex].fpPrfmTask(_tItems[selTaskIndex].task, @selector(performTask));
                    
                    pthread_mutex_lock(&_cLock);
                    
                    _tItems[selTaskIndex].tiFlags &= ~EGW_TSKITMFLG_ISRUNNING;
                    
                    // Tell all links this was dependent on to unflag satisfied (left uncheck)
                    index = _tItems[selTaskIndex].ttDeps; while(index--) {
                        _tDeps[_tItems[selTaskIndex].ttIndicies[index]].tdFlags &= ~EGW_TSKDPDFLG_SATISFIED;
                    }
                    
                    // Tell all tasks dependent on this to satisfy linkage (right check), to decrement twDeps, check for workAvail, signal
                    index = _tItems[selTaskIndex].tdDeps; while(index--) {
                        if(!(_tDeps[_tItems[selTaskIndex].tdIndicies[index]].tdFlags & EGW_TSKDPDFLG_SATISFIED)) {
                            _tDeps[_tItems[selTaskIndex].tdIndicies[index]].tdFlags |= EGW_TSKDPDFLG_SATISFIED;
                            
                            if((--_tItems[_tDeps[_tItems[selTaskIndex].tdIndicies[index]].ttiIndex].twDeps) == 0)
                                pthread_cond_broadcast(&_wCond);
                        }
                    }
                }
                
                if(_tItems[selTaskIndex].tiFlags & (EGW_TSKITMFLG_TEMPORARY | EGW_TSKITMFLG_MARKEDREM)) {
                    // Reverse lookup for selTaskIndex into handle lookup
                    index = EGW_TASKMNGR_MAXTASKHANDLES; while(index--)
                        if(_tHndLkup[index] == selTaskIndex) {
                            [self unregisterTaskAlreadyLocked:(index+1)];
                            break;
                        }
                }
                
                pthread_mutex_unlock(&_cLock);
            } else {
                // No work yet available, wait for a new work signal
                pthread_cond_wait(&_wCond, &_cLock);
                pthread_mutex_unlock(&_cLock);
            }
        } else {
            if(*threadAlert) *threadAlert = NO;
            
            if(!_tPool[threadNumber-1] || [_tPool[threadNumber-1] isCancelled] || _doShutdownPh2)
                goto ThreadBreak;
            else if(time(NULL) >= drainAfter || _doMemClean[threadNumber-1]) {
                [*arPool release]; *arPool = [[NSAutoreleasePool alloc] init];
                drainAfter = time(NULL) + (time_t)EGW_ENGINE_MANAGERS_TIMETODRAIN;
                if(_doMemClean[threadNumber-1]) {
                    pthread_mutex_lock(&_cLock);
                    
                    if(_doMemClean[threadNumber-1]) {
                        _doMemClean[threadNumber-1] = NO;
                        --_memCleanLeft;
                    }
                    
                    pthread_mutex_unlock(&_cLock);
                }
            }
            
            oddJobCounter = EGW_ENGINE_MANAGERS_ODDJOBSPINCYCLE;
        }
    }
    
ThreadBreak:
    if(_doMemClean[threadNumber-1]) {
        pthread_mutex_lock(&_cLock);
        
        [*arPool release]; *arPool = nil;
        
        if(_doMemClean[threadNumber-1]) {
            _doMemClean[threadNumber-1] = NO;
            --_memCleanLeft;
        }
        
        pthread_mutex_unlock(&_cLock);
    }
    
    pthread_mutex_lock(&_cLock);
    --_ttCount;
    pthread_mutex_unlock(&_cLock);
    
    if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwTaskManager: taskThreadMainLoop: Task thread #%d shut down.", threadNumber);
    
    return;
}

@end

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

/// @file egwPhyContext.m
/// @ingroup geWizES_sys_phycontext
/// Abstract Physics Context Implementation.

#import <pthread.h>
#import "egwPhyContext.h"
#import "../sys/egwEngine.h"
#import "../sys/egwTaskManager.h"
#import "../sys/egwPhyActuator.h"


EGWuint16 (*egwAFPPhyCntxInteractionFrame)(id, SEL) = NULL;
void (*egwAFPPhyCntxAdvanceInteractionFrame)(id, SEL) = NULL;
BOOL (*egwAFPPhyCntxMakeActive)(id, SEL) = NULL;
BOOL (*egwAFPPhyCntxActive)(id, SEL) = NULL;
void (*egwAFPPhyCntxPerformSubTasks)(id, SEL) = NULL;
egwPhyContext* egwAIPhyCntx = nil;


// Sub Task Work Item Structure.
typedef struct {
    id<egwPSubTask> sTask;                  // Subtask object (retained).
    egwValidater* vSync;                    // Validater sync (strong).
} egwContextSubTaskWorkItem;


@implementation egwPhyContext

- (id)init {
    if(![[self class] isSubclassOfClass:[egwPhyContext class]]) {
        NSLog(@"egwPhyContext: init: Error: This method must only be called from derived classes. YOU'RE DOING IT WRONG!");
        [self release]; return (self = nil);
    }
    
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    if(!(_tasks = [[NSMutableArray alloc] init])) { [self release]; return (self = nil); }
    
    if(pthread_mutex_init(&_stLock, NULL)) { [self release]; return (self = nil); }
    if(!egwSLListInit(&_sTasks, NULL, sizeof(egwContextSubTaskWorkItem), EGW_LIST_FLG_RETAIN)) { [self release]; return (self = nil); }
    
    // Start frame checking at always pass (0) until incremented
    _iFrame = EGW_FRAME_ALWAYSPASS;
    
    return self;
}

- (id)initWithParams:(void*)params {
    NSLog(@"egwPhyContext: initWithParams: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
    [self release]; return (self = nil);
}

- (void)dealloc {
    [_delegate release]; _delegate = nil;
    
    pthread_mutex_destroy(&_stLock);
    egwSLListFree(&_sTasks);
    
    // Wait for tasks to de-associate themselves gracefully, otherwise continue
    {   NSDate* waitTill = [[NSDate alloc] initWithTimeIntervalSinceNow:(NSTimeInterval)EGW_ENGINE_MANAGERS_TIMETOWAIT];
        while([_tasks count]) {
            if([waitTill timeIntervalSinceNow] < (NSTimeInterval)0.0) {
                NSLog(@"egwPhyContext: dealloc: Failure waiting for %d task(s) to de-associate.", [_tasks count]);
                break;
            }
            
            [NSThread sleepForTimeInterval:EGW_ENGINE_MANAGERS_TIMETOSLEEP];
        }
        [waitTill release];
        [_tasks removeAllObjects];
        [_tasks release]; _tasks = nil;
    }
    
    [super dealloc];
}

- (void)advanceInteractionFrame {
    ++_iFrame;
    if(_iFrame == EGW_FRAME_ALWAYSFAIL) _iFrame = 1;
}

- (BOOL)associateTask:(id<egwPTask>)task; {
    if(task && ![_tasks containsObject:(id)task]) {
        [_tasks addObject:(id)task];
        
        return YES;
    }
    
    return NO;
}

- (BOOL)deassociateTask:(id<egwPTask>)task {
    if(task && [_tasks containsObject:(id)task]) {
        [_tasks removeObject:(id)task];
        
        return YES;
    }
    
    return NO;
}

- (void)addSubTask:(id<egwPSubTask>)sTask forSync:(egwValidater*)vSync {
    if(sTask) {
        pthread_mutex_lock(&_stLock);
        
        egwContextSubTaskWorkItem workItem;
        workItem.sTask = sTask;
        workItem.vSync = vSync;
        egwSLListAddTail(&_sTasks, (const EGWbyte*)&workItem);
        
        pthread_mutex_unlock(&_stLock);
    }
}

- (void)performSubTasks {
    if(_sTasks.eCount) {
        pthread_mutex_lock(&_stLock);
        
        egwSinglyLinkedListIter iter;
        
        if(egwSLListEnumerateStart(&_sTasks, EGW_ITERATE_MODE_LINHTT, &iter)) {
            egwContextSubTaskWorkItem* workItem;
            egwSinglyLinkedListNode* prev = NULL;
            
            while(workItem = (egwContextSubTaskWorkItem*)egwSLListEnumerateNextPtr(&iter)) {
                if([workItem->sTask performSubTaskForComponent:self forSync:workItem->vSync])
                    egwSLListRemoveAfter(&_sTasks, prev);
                else
                    prev = (prev ? prev->next : _sTasks.lHead);
            }
        }
        
        pthread_mutex_unlock(&_stLock);
    }
}

- (void)removeSubTask:(id<egwPSubTask>)sTask {
    if(sTask && _sTasks.eCount) {
        pthread_mutex_lock(&_stLock);
        
        egwSinglyLinkedListIter iter;
        
        if(egwSLListEnumerateStart(&_sTasks, EGW_ITERATE_MODE_LINHTT, &iter)) {
            egwContextSubTaskWorkItem* workItem;
            egwSinglyLinkedListNode* prev = NULL;
            
            while(workItem = (egwContextSubTaskWorkItem*)egwSLListEnumerateNextPtr(&iter)) {
                if(workItem->sTask == sTask)
                    egwSLListRemoveAfter(&_sTasks, prev);
                else
                    prev = (prev ? prev->next : _sTasks.lHead);
            }
        }
        
        pthread_mutex_unlock(&_stLock);
    }
}

- (BOOL)makeActive {
    NSLog(@"egwPhyContext: makeActive: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
    return NO;
}

- (BOOL)makeActiveAndLocked {
    NSLog(@"egwPhyContext: makeActiveAndLocked: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
    return NO;
}

- (void)shutDownContext { // Entrant from derived classes only, already locked
    if(_tasks) {
        [_tasks makeObjectsPerformSelector:@selector(shutDownTask)];
    }
    
    if(_sTasks.eCount) {
        pthread_mutex_lock(&_stLock);
        egwSLListRemoveAll(&_sTasks);
        pthread_mutex_unlock(&_stLock);
    }
}

+ (EGWint)apiIdent {
    NSLog(@"egwPhyContext: apiIdent: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
    return EGW_ENGINE_PHYAPI_INVALID;
}

+ (pthread_mutex_t*)apiMutex {
    NSLog(@"egwPhyContext: apiMutex: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
    return NULL;
}

- (NSArray*)associatedTasks {
    return _tasks;
}

- (EGWuint16)interactionFrame {
    return _iFrame;
}

- (BOOL)isActive {
    NSLog(@"egwPhyContext: isActive: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
    return NO;
}

- (BOOL)isContextThread {
    return (_thread == egwSFPNSThreadCurrentThread(nil, @selector(currentThread)) ? YES : NO);
}

- (BOOL)isExtAvailable:(NSString*)extName {
    NSLog(@"egwPhyContext: isExtAvailable: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
    return NO;
}

- (BOOL)isContextShutDown {
    return _doShutdown;
}

@end

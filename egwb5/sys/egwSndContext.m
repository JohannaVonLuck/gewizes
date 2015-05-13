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

/// @file egwSndContext.m
/// @ingroup geWizES_sys_sndcontext
/// Abstract Sound Context Implementation.

#import <pthread.h>
#import "egwSndContext.h"
#import "../sys/egwEngine.h"
#import "../sys/egwSndMixer.h"
#import "../data/egwArray.h"
#import "../math/egwMath.h"
#import "../misc/egwValidater.h"


egwSndContext* egwAISndCntx = nil;


// Sound Buffer Destroy Work Item Structure.
typedef struct {
    time_t timeToFree;                      // Time ahead when free() is okay to do.
    EGWbyte* bufferData;                    // Buffer data (owned).
} egwBufferDataDestroyWorkItem;

// Sub Task Work Item Structure.
typedef struct {
    id<egwPSubTask> sTask;                  // Subtask object (retained).
    egwValidater* vSync;                    // Validater sync (strong).
} egwContextSubTaskWorkItem;


@implementation egwSndContext

- (id)init {
    if(![[self class] isSubclassOfClass:[egwSndContext class]]) {
        NSLog(@"egwSndContext: init: Error: This method must only be called from derived classes. YOU'RE DOING IT WRONG!");
        [self release]; return (self = nil);
    }
    
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    // Create task array
    if(!(_tasks = [[NSMutableArray alloc] init])) { [self release]; return (self = nil); }
    
    // Create sub task array and lock
    if(pthread_mutex_init(&_stLock, NULL)) { [self release]; return (self = nil); }
    if(!egwSLListInit(&_sTasks, NULL, sizeof(egwContextSubTaskWorkItem), EGW_LIST_FLG_RETAIN)) { [self release]; return (self = nil); }
    
    // Start frame checking at always pass (0) until incremented
    _pFrame = EGW_FRAME_ALWAYSPASS;
    
    return self;
}

- (id)initWithParams:(void*)params {
    NSLog(@"egwSndContext: initWithParams: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
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
                NSLog(@"egwSndContext: dealloc: Failure waiting for %d task(s) to de-associate.", [_tasks count]);
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

- (void)advancePlaybackFrame {
    ++_pFrame;
    if(_pFrame == EGW_FRAME_ALWAYSFAIL) _pFrame = 1;
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
    if(_sTasks.eCount || _dstryBufData.eCount) {
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
        
        if(_dstryBufData.eCount) {
            time_t timeNow = time(0);
            
            for(EGWint bufferIndex = _dstryBufData.eCount - 1; bufferIndex >= 0; --bufferIndex) {
                egwBufferDataDestroyWorkItem* item = (egwBufferDataDestroyWorkItem*)egwArrayElementPtrAt(&_dstryBufData, bufferIndex);
                if(item->timeToFree <= timeNow) {
                    free((void*)(item->bufferData));
                    egwArrayRemoveAt(&_dstryBufData, bufferIndex);
                }
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

- (EGWbyte*)requestFreeBufferDataWithSize:(EGWuint)sizeB {
    EGWbyte* bufferData;
    
    if(!(bufferData = malloc((size_t)sizeB)))
        NSLog(@"egwSndContextAL: requestFreeBufferDataWithSize: Failure generating new buffers of size %d.", sizeB);
    
    return bufferData;
}

- (void)returnUsedBufferData:(EGWbyte**)bufferData {
    if(bufferData && *bufferData) {
        // Move to destroy list for delayed removal
        if(egwArrayAddTail(&_dstryBufData, NULL)) { // skip copy init
            egwBufferDataDestroyWorkItem* item = (egwBufferDataDestroyWorkItem*)egwArrayElementPtrTail(&_dstryBufData);
            item->timeToFree = time(0) + (time_t)EGW_SNDCONTEXT_BUFDATATTL;
            item->bufferData = *bufferData; // Ownership transfer!
            *bufferData = NULL;
        } else {
            // Note: This may cause problems doing it this way - better than leaking -jw
            [NSThread sleepForTimeInterval:0.01]; // This is a hack/fix for the audio hardware not catching up in time to remove sounds from the hardware buffer and thus causing access faults due to static buffer usage
            free((void*)*bufferData);
            *bufferData = NULL;
        }
    }
}

- (BOOL)makeActive {
    NSLog(@"egwSndContext: makeActive: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
    return NO;
}

- (BOOL)makeActiveAndLocked {
    NSLog(@"egwSndContext: makeActiveAndLocked: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
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
    
    [_actvCamera release]; _actvCamera = nil;
}

- (id<egwPCamera>)activeCamera {
    return _actvCamera;
}

+ (EGWint)apiIdent {
    NSLog(@"egwSndContext: apiIdent: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
    return EGW_ENGINE_PHYAPI_INVALID;
}

+ (pthread_mutex_t*)apiMutex {
    NSLog(@"egwSndContext: apiMutex: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
    return NULL;
}

- (NSArray*)associatedTasks {
    return _tasks;
}

- (EGWuint16)maxActiveSources {
    return _maxSources;
}

- (EGWuint16)playbackFrame {
    return _pFrame;
}

- (EGWuint)systemVolume {
    return _sVolume;
}

- (void)setActiveCamera:(id<egwPCamera>)camera {
    if(camera != _actvCamera) {
        [camera retain];
        egwSFPVldtrInvalidate([camera playbackSync], @selector(invalidate));
        [_actvCamera release];
        _actvCamera = camera;
    }
}

- (void)setSystemVolume:(EGWuint)volume {
    NSLog(@"egwSndContext: setSystemVolume: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
}

- (BOOL)isActive {
    NSLog(@"egwSndContext: isActive: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
    return NO;
}

- (BOOL)isContextThread {
    return (_thread == [NSThread currentThread] ? YES : NO);
}

- (BOOL)isExtAvailable:(NSString*)extName {
    NSLog(@"egwSndContext: isExtAvailable: Error: This method must be overridden. YOU'RE DOING IT WRONG!");
    return NO;
}

- (BOOL)isContextShutDown {
    return _doShutdown;
}

@end

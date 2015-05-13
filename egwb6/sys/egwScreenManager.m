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

/// @file egwScreenManager.m
/// @ingroup geWizES_sys_screenmanager
/// Screen Manager Implementation.

#import <pthread.h>
#import "egwScreenManager.h"
#import "../sys/egwEngine.h"
#import "../data/egwSinglyLinkedList.h"


egwScreenManager* egwSIScrnMngr = nil;


#define EGW_SCRNWRKITMFLG_NONE      0x00    // No flags.
#define EGW_SCRNWRKITMFLG_MANAGE    0x01    // Begin managing.
#define EGW_SCRNWRKITMFLG_MAKEKEY   0x02    // Make screen key.
#define EGW_SCRNWRKITMFLG_UNMANAGE  0x04    // Unmanage screen.
#define EGW_SCRNWRKITMFLG_UNMNGNOUL 0x08    // Unmanage screen w/o unload.

typedef struct {
    id<egwPScreen> screen;                  // Screen (retained).
    EGWuint wFlags;                         // Work flags.
} egwScreenWorkReq;

typedef struct {
    id<egwPScreen> screen;                  // Screen (retained).
    id (*fpPerformScreen)(id, SEL);         // IMP function pointer to performScreen method to reduce ObjC overhead.
} egwScreenWorkItem;


@implementation egwScreenManager

static egwScreenManager* _singleton = nil;

+ (id)alloc {
    @synchronized(self) {
        if(!_singleton)
            egwSIScrnMngr = _singleton = [super alloc];
    }
    return _singleton;
}

+ (void)dealloc {
    @synchronized(self) {
        [_singleton release];
        egwSIScrnMngr = _singleton = nil;
    }
    if(0) [super dealloc];
}

+ (id)sharedSingleton {
    return _singleton;
}

- (id)copy {
    return _singleton;
}

- (id)mutableCopy {
    return _singleton;
}

+ (BOOL)isAllocated {
    return (_singleton ? YES : NO);
}

- (id)init {
    return [self initWithPriority:EGW_SCRNMNGR_DFLTPRIORITY];
}

- (id)initWithPriority:(double)priority {
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    _priority = priority;
    
    if(pthread_mutex_init(&_rcLock, NULL)) { [self release]; return (self = nil); }
    egwSLListInit(&_rChain, NULL, sizeof(egwScreenWorkItem), EGW_LIST_FLG_RETAIN);
    egwSLListInit(&_unScreens, NULL, sizeof(egwScreenWorkItem), EGW_LIST_FLG_RETAIN);
    egwSLListInit(&_luScreens, NULL, sizeof(egwScreenWorkItem), EGW_LIST_FLG_RETAIN);
    
    if(pthread_mutex_init(&_wLock, NULL)) { [self release]; return (self = nil); }
    egwSLListInit(&_sWork, NULL, sizeof(egwScreenWorkReq), EGW_LIST_FLG_RETAIN);
    
    if(EGW_ENGINE_MANAGERS_STARTUPMSGS) NSLog(@"egwScreenManager: initWithPriority: Screen manager has been initialized.");
    
    return self;
}

- (void)dealloc {
    if(!_doShutdown)
        [self shutDownScreenManagement];
    
    egwSLListFree(&_sWork);
    pthread_mutex_destroy(&_wLock);
    
    [_kScreen release]; _kScreen = nil;
    egwSLListFree(&_unScreens);
    egwSLListFree(&_luScreens);
    egwSLListFree(&_rChain);
    pthread_mutex_destroy(&_rcLock);
    
    if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwScreenManager: dealloc: Screen manager has been deallocated.");
    
    [super dealloc];
}

- (void)forwardInvocation:(NSInvocation*)anInvocation {
    egwSinglyLinkedListIter iter;
    
    pthread_mutex_lock(&_rcLock);
    
    if(egwSLListEnumerateStart(&_rChain, EGW_ITERATE_MODE_DFLT, &iter)) {
        egwScreenWorkItem* workItem;
        
        while((workItem = (egwScreenWorkItem*)egwSLListEnumerateNextPtr(&iter))) {
            if([workItem->screen respondsToSelector:[anInvocation selector]]) {
                [anInvocation invokeWithTarget:workItem->screen];
                break;
            }
        }
    }
    
    pthread_mutex_unlock(&_rcLock);
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector {
    egwSinglyLinkedListIter iter;
    
    pthread_mutex_lock(&_rcLock);
    
    if(egwSLListEnumerateStart(&_rChain, EGW_ITERATE_MODE_DFLT, &iter)) {
        egwScreenWorkItem* workItem;
        
        while((workItem = (egwScreenWorkItem*)egwSLListEnumerateNextPtr(&iter))) {
            if([workItem->screen respondsToSelector:aSelector])
                return [(NSObject*)workItem->screen methodSignatureForSelector:aSelector];
        }
    }
    
    pthread_mutex_unlock(&_rcLock);
    
    return nil;
}

- (void)manageScreen:(id<egwPScreen>)screen {
    if(!_doShutdown) {
        pthread_mutex_lock(&_wLock);
        
        if(!_doShutdown) {
            egwScreenWorkReq workItemReq;
            workItemReq.screen = screen;
            workItemReq.wFlags = EGW_SCRNWRKITMFLG_MANAGE;
            
            egwSLListAddTail(&_sWork, (const EGWbyte*)&workItemReq);
        }
        
        pthread_mutex_unlock(&_wLock);
    }
}

- (void)makeKeyScreen:(id<egwPScreen>)screen {
    if(!_doShutdown) {
        pthread_mutex_lock(&_wLock);
        
        if(!_doShutdown) {
            egwScreenWorkReq workItemReq;
            workItemReq.screen = screen;
            workItemReq.wFlags = EGW_SCRNWRKITMFLG_MAKEKEY;
            
            egwSLListAddTail(&_sWork, (const EGWbyte*)&workItemReq);
        }
        
        pthread_mutex_unlock(&_wLock);
    }
}

- (void)unmanageScreen:(id<egwPScreen>)screen {
    if(!_doShutdown) {
        pthread_mutex_lock(&_wLock);
        
        if(!_doShutdown) {
            egwScreenWorkReq workItemReq;
            workItemReq.screen = screen;
            workItemReq.wFlags = EGW_SCRNWRKITMFLG_UNMANAGE;
            
            egwSLListAddTail(&_sWork, (const EGWbyte*)&workItemReq);
        }
        
        pthread_mutex_unlock(&_wLock);
    }
}

- (void)unmanageScreenWithoutUnload:(id<egwPScreen>)screen {
    if(!_doShutdown) {
        pthread_mutex_lock(&_wLock);
        
        if(!_doShutdown) {
            egwScreenWorkReq workItemReq;
            workItemReq.screen = screen;
            workItemReq.wFlags = EGW_SCRNWRKITMFLG_UNMNGNOUL;
            
            egwSLListAddTail(&_sWork, (const EGWbyte*)&workItemReq);
        }
        
        pthread_mutex_unlock(&_wLock);
    }
}

- (void)shutDownScreenManagement {
    if(!_doShutdown) {
        @synchronized(self) {
            if(!_doShutdown) {
                pthread_mutex_lock(&_wLock);
                
                _doShutdown = YES;
                
                if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwScreenManager: shutDownScreenManagement: Shutting down screen management.");
                
                egwSinglyLinkedListIter iter;
                
                if(egwSLListEnumerateStart(&_rChain, EGW_ITERATE_MODE_DFLT, &iter)) {
                    egwScreenWorkItem* workItem;
                    
                    // NOTE: Since the base system may have responded with its own shut down procedures, the
                    // screens are told to unmanage (/w unload) in work items. If work items before that tell
                    // the screen otherwise, those are followed first and these are ignored. -jw
                    
                    while((workItem = (egwScreenWorkItem*)egwSLListEnumerateNextPtr(&iter))) {
                        egwScreenWorkReq workItemReq;
                        workItemReq.screen = workItem->screen;
                        workItemReq.wFlags = EGW_SCRNWRKITMFLG_UNMANAGE;
                        
                        egwSLListAddTail(&_sWork, (const EGWbyte*)&workItemReq);
                    }
                }
                
                pthread_mutex_unlock(&_wLock);
                
                // NOTE: Loading screens are left to load fully before automatically being sent to the
                // unload list over responder chain. This is done purposely so that weird load cancelations
                // don't occur; keeps user code cleaner. -jw
                
                pthread_mutex_lock(&_rcLock);
                
                {   NSDate* waitTill = [[NSDate alloc] initWithTimeIntervalSinceNow:(NSTimeInterval)EGW_ENGINE_MANAGERS_TIMETOWAIT];
                    while(_luScreens.eCount || _unScreens.eCount || _sWork.eCount) {
                        if([waitTill timeIntervalSinceNow] < (NSTimeInterval)0.0) {
                            NSLog(@"egwScreenManager: shutDownScreenManagement: Failure waiting for %d screen(s) to unload.", _luScreens.eCount + _unScreens.eCount + _sWork.eCount);
                            break;
                        }
                        
                        pthread_mutex_unlock(&_rcLock);
                        [NSThread sleepForTimeInterval:EGW_ENGINE_MANAGERS_TIMETOSLEEP];
                        pthread_mutex_lock(&_rcLock);
                    }
                    [waitTill release];
                }
                
                pthread_mutex_unlock(&_rcLock);
                
                if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwScreenManager: shutDownScreenManagement: Screen management shut down.");
            }
        }
    }
}

- (EGWuint)performSelectorOnResponderChain:(SEL)selector asBroadcast:(BOOL)broadcast skipKeyScreen:(BOOL)skipKey {
    EGWuint retVal = 0;
    egwSinglyLinkedListIter iter;
    
    pthread_mutex_lock(&_rcLock);
    
    if(egwSLListEnumerateStart(&_rChain, EGW_ITERATE_MODE_DFLT, &iter)) {
        egwScreenWorkItem* workItem;
        
        while((retVal == 0 || broadcast) && (workItem = (egwScreenWorkItem*)egwSLListEnumerateNextPtr(&iter))) {
            if((!skipKey || _kScreen != workItem->screen) &&
               [workItem->screen respondsToSelector:selector]) {
                [workItem->screen performSelector:selector];
                ++retVal;
            }
        }
    }
    
    pthread_mutex_unlock(&_rcLock);
    
    return retVal;
}

- (EGWuint)performSelectorOnResponderChain:(SEL)selector withObject:(id)object asBroadcast:(BOOL)broadcast skipKeyScreen:(BOOL)skipKey {
    EGWuint retVal = 0;
    egwSinglyLinkedListIter iter;
    
    pthread_mutex_lock(&_rcLock);
    
    if(egwSLListEnumerateStart(&_rChain, EGW_ITERATE_MODE_DFLT, &iter)) {
        egwScreenWorkItem* workItem;
        
        while((retVal == 0 || broadcast) && (workItem = (egwScreenWorkItem*)egwSLListEnumerateNextPtr(&iter))) {
            if((!skipKey || _kScreen != workItem->screen) &&
               [workItem->screen respondsToSelector:selector]) {
                [workItem->screen performSelector:selector withObject:object];
                ++retVal;
            }
        }
    }
    
    pthread_mutex_unlock(&_rcLock);
    
    return retVal;
}

- (EGWuint)performSelectorOnResponderChain:(SEL)selector withObject:(id)object1 withObject:(id)object2 asBroadcast:(BOOL)broadcast skipKeyScreen:(BOOL)skipKey {
    EGWuint retVal = 0;
    egwSinglyLinkedListIter iter;
    
    pthread_mutex_lock(&_rcLock);
    
    if(egwSLListEnumerateStart(&_rChain, EGW_ITERATE_MODE_DFLT, &iter)) {
        egwScreenWorkItem* workItem;
        
        while((retVal == 0 || broadcast) && (workItem = (egwScreenWorkItem*)egwSLListEnumerateNextPtr(&iter))) {
            if((!skipKey || _kScreen != workItem->screen) &&
               [workItem->screen respondsToSelector:selector]) {
                [workItem->screen performSelector:selector withObject:object1 withObject:object2];
                ++retVal;
            }
        }
    }
    
    pthread_mutex_unlock(&_rcLock);
    
    return retVal;
}

- (EGWuint)performInvocationOnResponderChain:(NSInvocation*)invocation asBroadcast:(BOOL)broadcast skipKeyScreen:(BOOL)skipKey {
    EGWuint retVal = 0;
    egwSinglyLinkedListIter iter;
    
    pthread_mutex_lock(&_rcLock);
    
    if(egwSLListEnumerateStart(&_rChain, EGW_ITERATE_MODE_DFLT, &iter)) {
        egwScreenWorkItem* workItem;
        
        while((retVal == 0 || broadcast) && (workItem = (egwScreenWorkItem*)egwSLListEnumerateNextPtr(&iter))) {
            if((!skipKey || _kScreen != workItem->screen) &&
               [workItem->screen respondsToSelector:[invocation selector]]) {
                [invocation invokeWithTarget:workItem->screen];
                ++retVal;
            }
        }
    }
    
    pthread_mutex_unlock(&_rcLock);
    
    return retVal;
}

- (void)performTask {
    egwSinglyLinkedListIter iter;
    
    pthread_mutex_lock(&_rcLock);
    
    _amRunning = YES;
    
    if(_sWork.eCount) {
        pthread_mutex_lock(&_wLock);
        
        if(_sWork.eCount) {
            egwScreenWorkReq* workItemReq;
            egwSinglyLinkedListNode* prev = NULL;
            
            if(egwSLListEnumerateStart(&_sWork, EGW_ITERATE_MODE_DFLT, &iter)) {
                while((workItemReq = (egwScreenWorkReq*)egwSLListEnumerateNextPtr(&iter))) {
                    switch(workItemReq->wFlags) {
                        case EGW_SCRNWRKITMFLG_MANAGE: {
                            if(![workItemReq->screen isScreenUnloaded]) { // screens are left to load even if shutting down
                                egwScreenWorkItem workItem;
                                workItem.screen = workItemReq->screen;
                                workItem.fpPerformScreen = (id(*)(id, SEL))[(NSObject*)workItemReq->screen methodForSelector:@selector(performScreen)];
                                
                                if(![workItemReq->screen isScreenLoaded])
                                    egwSLListAddTail(&_luScreens, (const EGWbyte*)&workItem);
                                else {
                                    if(egwSLListAddTail(&_rChain, (const EGWbyte*)&workItem)) {
                                        if(!_kScreen) {
                                            _kScreen = [workItemReq->screen retain];
                                            [_kScreen makeKeyScreen];
                                        }
                                    }
                                }
                                
                                egwSLListRemoveAfter(&_sWork, prev);
                            } else
                                egwSLListRemoveAfter(&_sWork, prev);
                        } break;
                        
                        case EGW_SCRNWRKITMFLG_MAKEKEY: {
                            if(!_doShutdown) {
                                if(_rChain.eCount >= 1 && _luScreens.eCount == 0 && [workItemReq->screen isScreenLoaded]) {
                                    egwSinglyLinkedListIter luIter;
                                    egwSinglyLinkedListNode* luPrev = NULL;
                                    
                                    if(egwSLListEnumerateStart(&_rChain, EGW_ITERATE_MODE_DFLT, &luIter)) {
                                        egwScreenWorkItem* luWorkItem;
                                        
                                        while((luWorkItem = (egwScreenWorkItem*)egwSLListEnumerateNextPtr(&luIter))) {
                                            if(luWorkItem->screen != workItemReq->screen)
                                                luPrev = egwSLListNodePtr((const EGWbyte*)luWorkItem);
                                            else {
                                                if(_kScreen != luWorkItem->screen && egwSLListPromoteToHeadAfter(&_rChain, luPrev)) {
                                                    [_kScreen recedeKeyScreen];
                                                    [_kScreen release];
                                                    _kScreen = [workItemReq->screen retain];
                                                    [_kScreen makeKeyScreen];
                                                }
                                                break;
                                            }
                                        }
                                    }
                                    
                                    egwSLListRemoveAfter(&_sWork, prev);
                                } else // make key reqs stay on work queue until they're found, so that loader screens get key made
                                    prev = egwSLListNodePtr((const EGWbyte*)workItemReq);
                            } else // skip make key reqs if shutting down
                                egwSLListRemoveAfter(&_sWork, prev);
                        } break;
                        
                        case EGW_SCRNWRKITMFLG_UNMANAGE:
                        case EGW_SCRNWRKITMFLG_UNMNGNOUL: {
                            if(_luScreens.eCount == 0) {
                                egwSinglyLinkedListIter luIter;
                                egwSinglyLinkedListNode* luPrev = NULL;
                                
                                if(egwSLListEnumerateStart(&_rChain, EGW_ITERATE_MODE_DFLT, &luIter)) {
                                    egwScreenWorkItem* luWorkItem;
                                    
                                    while((luWorkItem = (egwScreenWorkItem*)egwSLListEnumerateNextPtr(&luIter))) {
                                        if(luWorkItem->screen != workItemReq->screen)
                                            luPrev = egwSLListNodePtr((const EGWbyte*)luWorkItem);
                                        else {
                                            if(workItemReq->wFlags != EGW_SCRNWRKITMFLG_UNMNGNOUL && ![workItemReq->screen isScreenUnloaded])
                                                egwSLListAddTail(&_unScreens, (const EGWbyte*)luWorkItem);
                                            if(egwSLListRemoveAfter(&_rChain, luPrev)) {
                                                if(_kScreen == workItemReq->screen) {
                                                    [_kScreen recedeKeyScreen];
                                                    [_kScreen release];
                                                    _kScreen = (_rChain.eCount ? [((egwScreenWorkItem*)egwSLListElementPtrHead(&_rChain))->screen retain] : nil);
                                                    [_kScreen makeKeyScreen];
                                                }
                                            }
                                            break;
                                        }
                                    }
                                }
                                
                                egwSLListRemoveAfter(&_sWork, prev);
                            } else // unmanage reqs stay on work queue until they're found, so that loader screens get unmanaged
                                prev = egwSLListNodePtr((const EGWbyte*)workItemReq);
                        } break;
                        
                        default: {
                            egwSLListRemoveAfter(&_sWork, prev);
                        } break;
                    }
                }
            }
        }
        
        pthread_mutex_unlock(&_wLock);
    }
    
    // NOTE: Perform screens is always performed BEFORE loading/unloading of screens. This is done
    // purposely since there may be queued work items (e.g. make key) sitting on queue that are
    // waiting for a screen to get on the main work queue but need those commands sent to those
    // screens before any initial call to performScreen. -jw
    
    if(egwSLListEnumerateStart(&_rChain, EGW_ITERATE_MODE_DFLT, &iter)) {
        egwScreenWorkItem* workItem;
        
        while((workItem = (egwScreenWorkItem*)egwSLListEnumerateNextPtr(&iter))) {
            workItem->fpPerformScreen(workItem->screen, @selector(performScreen));
        }
    }
    
    // NOTE: Unloading screens is always performed BEFORE loading of screens. This is done purposely
    // for a variety of reasons, the most notable being that loads may overlap asset contents of the
    // unloads, which could potentially cause issues. -jw
    
    if(_unScreens.eCount) {
        egwScreenWorkItem* workItem;
        egwSinglyLinkedListNode* prev = NULL;
        
        if(egwSLListEnumerateStart(&_unScreens, EGW_ITERATE_MODE_DFLT, &iter)) {
            while((workItem = (egwScreenWorkItem*)egwSLListEnumerateNextPtr(&iter))) {
                if(!([workItem->screen unloadScreen]))
                    prev = egwSLListNodePtr((const EGWbyte*)workItem);
                else
                    egwSLListRemoveAfter(&_unScreens, prev);
            }
        }
    } else if(_luScreens.eCount) {
        egwScreenWorkItem* workItem;
        egwSinglyLinkedListNode* prev = NULL;
        
        if(egwSLListEnumerateStart(&_luScreens, EGW_ITERATE_MODE_DFLT, &iter)) {
            while((workItem = (egwScreenWorkItem*)egwSLListEnumerateNextPtr(&iter))) {
                if(!([workItem->screen loadScreen]))
                    prev = egwSLListNodePtr((const EGWbyte*)workItem);
                else {
                    if(!_doShutdown) {
                        if(egwSLListAddTail(&_rChain, (const EGWbyte*)workItem)) {
                            if(!_kScreen) {
                                _kScreen = [workItem->screen retain];
                                [_kScreen makeKeyScreen];
                            }
                        }
                    } else // if shutting down, once screen loaded, skip to unload
                        egwSLListAddTail(&_unScreens, (const EGWbyte*)workItem);
                    egwSLListRemoveAfter(&_luScreens, prev);
                }
            }
        }
    }
    
    _amRunning = NO;
    
    pthread_mutex_unlock(&_rcLock);
}

- (void)shutDownTask {
    if(!_doShutdown)
        [self shutDownScreenManagement];
}

- (id<egwPScreen>)keyScreen {
    return _kScreen;
}

- (EGWuint)screensLoading {
    EGWuint retVal = 0;
    
    if(!_doShutdown) {
        pthread_mutex_lock(&_rcLock);
        
        retVal = (EGWuint)_luScreens.eCount;
        
        pthread_mutex_unlock(&_rcLock);
    }
    
    return retVal;
}

- (EGWuint)screensPerforming {
    EGWuint retVal = 0;
    
    if(!_doShutdown) {
        pthread_mutex_lock(&_rcLock);
        
        retVal = (EGWuint)_rChain.eCount;
        
        pthread_mutex_unlock(&_rcLock);
    }
    
    return retVal;
}

- (EGWuint)screensUnloading {
    EGWuint retVal = 0;
    
    if(!_doShutdown) {
        pthread_mutex_lock(&_rcLock);
        
        retVal = (EGWuint)_unScreens.eCount;
        
        pthread_mutex_unlock(&_rcLock);
    }
    
    return retVal;
}

- (double)taskPriority {
    return _priority;
}

- (BOOL)isTaskPerforming {
    return _amRunning;
}

- (BOOL)isTaskShutDown {
    return _doShutdown;
}

- (BOOL)isThreadOwner {
    return NO;
}

- (BOOL)isShuttingDownScreenManagement {
    return _doShutdown;
}

@end
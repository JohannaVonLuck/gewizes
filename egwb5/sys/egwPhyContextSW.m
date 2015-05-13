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

/// @file egwPhyContextSW.m
/// @ingroup geWizES_sys_phycontextsw
/// Software Physics Context Implementation.

#import <pthread.h>
#import "egwPhyContextSW.h"
#import "../sys/egwEngine.h"
#import "../sys/egwPhyActuator.h"


egwPhyContextSW* egwAIPhyCntxSW = nil;


#if defined(EGW_BUILDMODE_DESKTOP) || defined(EGW_BUILDMODE_IPHONE)

int egwIsPSFTError(NSString** errorString) {
    if(errorString) *errorString = nil;
    //if(errorString) *errorString = [NSString stringWithString:@"PSFT_NOT_IMPLEMENTED: Not yet implemented."];
    return 1;
}


@implementation egwPhyContextSW

static EGWint _apiRefCnt_PSFT = 0;
static pthread_mutex_t _apiLock_PSFT = PTHREAD_MUTEX_INITIALIZER;

- (id)init {
    return [self initWithParams:nil];
}

- (id)initWithParams:(void*)params {
    NSString* errorString = nil;
    egwPhyCntxParams* phyParams = (egwPhyCntxParams*)params;
    egwPhyContext* oldContext = nil;
    //NSMutableArray* availExtensions = nil;
    //const char* exts = NULL;
    
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    // Handle params and set up any particulars
    _delegate = (phyParams && phyParams->delegate ? [phyParams->delegate retain] : nil);
    
    // Lock API
    pthread_mutex_lock(&_apiLock_PSFT);
    
    // Create context
    if(!(1)) { // Software
        egwIsPSFTError(&errorString);
        NSLog(@"egwPhyContextSW: initWithParams: Failure creating context. PSFTError: %@", (errorString ? errorString : @"PSFT_NO_ERROR."));
        ++_apiRefCnt_PSFT; goto ErrorCleanup;    // cleanup will refcnt-1, invalidate that
    }
    
    // Increase reference count now that context was created - if error occurs
    // later then this gets decremented correctly and lock dealloc'ed if 0.
    ++_apiRefCnt_PSFT;
    
    // Bind context (store old one for later)
    oldContext = egwAIPhyCntx;
    if(!(1)) { // TODO
        egwIsPSFTError(&errorString);
        NSLog(@"egwPhyContextSW: initWithParams: Failure making created context current. PSFTError: %@", (errorString ? errorString : @"PSFT_NO_ERROR."));
        goto ErrorCleanup;
    } else {
        _thread = [NSThread currentThread];
        egwAIPhyCntx = self;
        egwAIPhyCntxSW = self;
    }
    
    // No further initializations to be made.
    
    // If there is a delegate defined, call its willFinish method
    if(_delegate && ![_delegate willFinishInitializingPhyContext:self]) {
        NSLog(@"egwPhyContextSW: initWithParams: Failure in user initialization code.");
        goto ErrorCleanup;
    }
	
    // If there was an old context, revert back to it, otherwise keep this one enabled.
    pthread_mutex_unlock(&_apiLock_PSFT);
    if(oldContext) [oldContext makeActive];
    
    [_delegate didFinishInitializingPhyContext:self];
    
    if(EGW_ENGINE_MANAGERS_STARTUPMSGS) NSLog(@"egwPhyContextSW: initWithParams: Physics context has been initialized.");
    
    return self;
    
ErrorCleanup:
    --_apiRefCnt_PSFT;
    _thread = nil;
    pthread_mutex_unlock(&_apiLock_PSFT);
    [oldContext makeActive];
    [self release]; return (self = nil);    
}

- (void)dealloc {
    // Forced shutdown - delegates should not be able to cancel
    {   id<egwDPhyContextEvent> delegate = _delegate;
        _delegate = nil;
        [self shutDownContext];
        _delegate = delegate;
        [_delegate didShutDownPhyContext:self];
    }
    
    if(_apiRefCnt_PSFT == 0) {
        @synchronized(self) {
            if(_apiRefCnt_PSFT == 0) {
                pthread_mutex_destroy(&_apiLock_PSFT);
            }
        }
    }
    
    [super dealloc];
}

- (BOOL)makeActive {
    pthread_mutex_lock(&_apiLock_PSFT);
    
    egwAIPhyCntx = self;
    egwAIPhyCntxSW = self;
    
    pthread_mutex_unlock(&_apiLock_PSFT);
    return YES;
}

- (BOOL)makeActiveAndLocked {
    pthread_mutex_lock(&_apiLock_PSFT);
    
    egwAIPhyCntx = self;
    egwAIPhyCntxSW = self;
    
    return YES;
}

- (void)shutDownContext {
    if(!_doShutdown) {
        @synchronized(self) {
            if(!_doShutdown) {
                // Allow delegate to cancel shutDownContext, else proceed
                if(_delegate && ![_delegate willShutDownPhyContext:self]) return;
                _doShutdown = YES;
                
                if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwPhyContextSW: shutDownContext: Shutting down physics context.");
                
                if(1 && ![self isActive]) [self makeActive];
                pthread_mutex_lock(&_apiLock_PSFT);
                
                [super shutDownContext];
                
                // Destroy context (TODO).
                if(egwAIPhyCntx == self) {
                    egwAIPhyCntx = nil;
                    egwAIPhyCntxSW = nil;
                }
                _thread = nil;
                
                pthread_mutex_unlock(&_apiLock_PSFT);
                [_delegate didShutDownPhyContext:self];
                
                if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwPhyContextSW: shutDownContext: Physics context shut down.");
            }
        }
    }
}

+ (EGWint)apiIdent {
    return EGW_ENGINE_PHYAPI_SOFTWARE;
}

+ (pthread_mutex_t*)apiMutex {
    return &_apiLock_PSFT;
}

- (BOOL)isActive {
    return (egwAIPhyCntx == self ? YES : NO); // no  && _thread == [NSThread currentThread]
}

- (BOOL)isContextThread {
    return YES;
}

- (BOOL)isExtAvailable:(NSString*)extName {
    return NO;
}

@end


#else

@implementation egwPhyContextSW

- (id)init {
    NSLog(@"egwPhyContextSW: init: Cannot initialize object due to build mode settings. YOU'RE DOING IT WRONG!");
    
    [self release]; return (self = nil);
}

- (id)initWithParams:(void*)params {
    NSLog(@"egwPhyContextSW: initWithParams: Cannot initialize object due to build mode settings. YOU'RE DOING IT WRONG!");
    
    [self release]; return (self = nil);
}

@end

#endif

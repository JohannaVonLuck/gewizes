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

/// @file egwSndContextAL.m
/// @ingroup geWizES_sys_sndcontextal
/// Sound Context Implementation.

#import <pthread.h>
#import "egwSndContextAL.h"
#import "../sys/egwEngine.h"
#import "../sys/egwSndMixer.h"
#import "../math/egwMath.h"
#import "../math/egwVector.h"
#import "../data/egwArray.h"
#import "../snd/egwSound.h"
#import "../misc/egwValidater.h"


egwSndContextAL* egwAISndCntxAL = nil;


#if defined(EGW_BUILDMODE_DESKTOP) || defined(EGW_BUILDMODE_IPHONE)

#ifdef EGW_BUILDMODE_MACOSX
alBufferDataStaticProcPtr alBufferDataStatic = 0;
#endif
LPALBUFFERDATA egw_alBufferData = &alBufferData;


typedef struct {
    time_t timeToFree;
    EGWbyte* bufferData;
} egwBufferDataDestroyWorkItem;


EGWint egwIsALCError(ALCdevice* device, NSString** errorString) {
    ALCenum errorEnum = alcGetError(device);
    switch(errorEnum) {
        case ALC_NO_ERROR: {
            if(errorString) *errorString = nil;
        } return 0;
        case ALC_INVALID_DEVICE: {
            if(errorString) *errorString = [NSString stringWithString:@"ALC_INVALID_DEVICE: Invalid device ID."];
        } return 1;
        case ALC_INVALID_CONTEXT: {
            if(errorString) *errorString = [NSString stringWithString:@"ALC_INVALID_CONTEXT: Invalid context ID."];
        } return 1;
        case ALC_INVALID_ENUM: {
            if(errorString) *errorString = [NSString stringWithString:@"ALC_INVALID_ENUM: Invalid parameter passed to ALC call."];
        } return 1;
        case ALC_INVALID_VALUE: {
            if(errorString) *errorString = [NSString stringWithString:@"ALC_INVALID_VALUE: Invalid enum parameter value."];
        } return 1;
        case ALC_OUT_OF_MEMORY: {
            if(errorString) *errorString = [NSString stringWithString:@"ALC_OUT_OF_MEMORY: Out of memory."];
        } return 1;
    }
    
    return 0;
}

EGWint egwIsALError(NSString** errorString) {
    ALenum errorEnum = alGetError();
    switch(errorEnum) {
        case AL_NO_ERROR: {
            if(errorString) *errorString = nil;
        } return 0;
        case AL_INVALID_NAME: {
            if(errorString) *errorString = [NSString stringWithString:@"AL_INVALID_NAME: Invalid Name paramater passed to AL call."];
        } return 1;
        case AL_INVALID_ENUM: {
            if(errorString) *errorString = [NSString stringWithString:@"AL_INVALID_ENUM: Invalid parameter passed to AL call."];
        } return 1;
        case AL_INVALID_VALUE: {
            if(errorString) *errorString = [NSString stringWithString:@"AL_INVALID_VALUE: Invalid enum parameter value."];
        } return 1;
        case AL_INVALID_OPERATION: {
            if(errorString) *errorString = [NSString stringWithString:@"AL_INVALID_OPERATION: Illegal call."];
        } return 1;
        case AL_OUT_OF_MEMORY: {
            if(errorString) *errorString = [NSString stringWithString:@"AL_OUT_OF_MEMORY: Out of memory."];
        } return 1;
    }
    
    return 0;
}


@implementation egwSndContextAL

static EGWint _apiRefCnt_AL = 0;
static pthread_mutex_t _apiLock_AL = PTHREAD_MUTEX_INITIALIZER;

- (id)init {
    return [self initWithParams:nil];
}

- (id)initWithParams:(void*)params {
    NSString* errorString = nil;
    egwSndCntxParams* sndParams = (egwSndCntxParams*)params;
    ALCint contextAttr[5] = {0};
    egwSndContext* oldContext = nil;
    NSMutableArray* availExtensions = nil;
    const char* exts = NULL;
    
    if(!(self = [super init])) { [self release]; return (self = nil); }
    
    // Handle params and set up any particulars
    contextAttr[0] = ALC_FREQUENCY;
    contextAttr[1] = (sndParams && sndParams->mixerFreq ? sndParams->mixerFreq : 22050);
    contextAttr[2] = ALC_REFRESH;
    contextAttr[3] = (sndParams && sndParams->refreshIntvl ? sndParams->refreshIntvl : 5);
    contextAttr[4] = 0;
    _delegate = (sndParams && sndParams->delegate ? [sndParams->delegate retain] : nil);
    
    // Create index lock
    if(pthread_mutex_init(&_iLock, NULL)) { [self release]; return (self = nil); }
    
    // Lock API
    pthread_mutex_lock(&_apiLock_AL);
    
    // Create device
    if(!sndParams || !sndParams->deviceName) {
        _device = alcOpenDevice(NULL);
        if(egwIsALCError(_device, &errorString) || _device == NULL) {
            NSLog(@"egwSndContextAL: initWithParams: Failure opening default device. ALCError: %@", (errorString ? errorString : @"ALC_NO_ERROR."));
            ++_apiRefCnt_AL; goto ErrorCleanup;  // cleanup will refcnt-1, invalidate that
        }
    } else {
        _device = alcOpenDevice([(sndParams->deviceName) UTF8String]);
        if(egwIsALCError(_device, &errorString) || _device == NULL) {
            NSLog(@"egwSndContextAL: initWithParams: Failure opening device named '%@'. ALCError: %@", sndParams->deviceName, (errorString ? errorString : @"ALC_NO_ERROR."));
            ++_apiRefCnt_AL; goto ErrorCleanup;  // cleanup will refcnt-1, invalidate that
        }
    }
    
    // Create context
    _context = alcCreateContext(_device, (const ALCint*)&contextAttr[0]);
    if(egwIsALCError(_device, &errorString) || _context == NULL) {
        NSLog(@"egwSndContextAL: initWithParams: Failure creating context. ALCError: %@", (errorString ? errorString : @"ALC_NO_ERROR."));
        ++_apiRefCnt_AL; goto ErrorCleanup;  // cleanup will refcnt-1, invalidate that
    }
    
    // Increase reference count now that context was created - if error occurs
    // later then this gets decremented correctly and lock dealloc'ed if 0.
    ++_apiRefCnt_AL;
    
    // Bind context (store old one for later)
    oldContext = egwAISndCntx;
    if(!alcMakeContextCurrent(_context)) {
        egwIsALCError(_device, &errorString);
        NSLog(@"egwSndContextAL: initWithParams: Failure making created context current. ALCError: %@", (errorString ? errorString : @"ALC_NONE."));
        goto ErrorCleanup;
    } else {
        _thread = [NSThread currentThread];
        egwAISndCntx = self;
        egwAISndCntxAL = self;
    }
    
    // Determine extensions
    if(!(availExtensions = [[NSMutableArray alloc] init])) {
        NSLog(@"egwSndContextAL: initWithParams: Failure allocating object.");
        goto ErrorCleanup;
    }
    
    exts = alcGetString(_device, ALC_EXTENSIONS);
    if(!egwIsALCError(_device, &errorString) && exts) {
        if(*exts != '\0') {
            const char* scan = exts;
            do {
                if(*(++scan) == ' ' || *scan == '\0') {
                    NSString* extString = [[NSString alloc] initWithCString:exts length:(EGWuint)(scan-exts)];
                    [availExtensions addObject:extString];
                    [extString release];
                    exts = (*scan == ' ' ? scan + 1 : scan);
                }
            } while (*exts != '\0');
        }
    } else {
        NSLog(@"egwSndContextAL: initWithParams: Failure querying ALC extensions. ALCError: %@", (errorString ? errorString : @"ALC_NONE."));
        [availExtensions release]; availExtensions = nil;
        goto ErrorCleanup;
    }
    
    exts = alGetString(AL_EXTENSIONS);
    if(!egwIsALError(&errorString) && exts) {
        if(*exts != '\0') {
            const char* scan = exts;
            do {
                if(*(++scan) == ' ' || *scan == '\0') {
                    NSString* extString = [[NSString alloc] initWithCString:exts length:(EGWuint)(scan-exts)];
                    [availExtensions addObject:extString];
                    [extString release];
                    exts = (*scan == ' ' ? scan + 1 : scan);
                }
            } while (*exts != '\0');
        }
    } else {
        NSLog(@"egwSndContextAL: initWithParams: Failure querying AL extensions. ALError: %@", (errorString ? errorString : @"AL_NO_ERROR."));
        [availExtensions release]; availExtensions = nil;
        goto ErrorCleanup;
    }
    
    if(!(_extensions = [[NSArray alloc] initWithArray:availExtensions])) {
        NSLog(@"egwSndContextAL: initWithParams: Failure allocating object.");
        [availExtensions release]; availExtensions = nil;
        goto ErrorCleanup;
    } else {
        [availExtensions release]; availExtensions = nil;
    }
    
    // Set up static buffer routine if not already
    #ifdef EGW_BUILDMODE_MACOSX
    if(alBufferDataStatic == NULL && [_extensions containsObject:@"AL_EXT_STATIC_BUFFER"])
        alBufferDataStatic = (alBufferDataStaticProcPtr)alcGetProcAddress(_device, (const ALchar*)"alBufferDataStatic");
    #endif
    
    // Create source holders & fill to determine actual max number of sources
    if(!(_availSrcIDs = [[NSMutableIndexSet alloc] init])) {
        NSLog(@"egwSndContextAL: initWithParams: Failure allocating object.");
        goto ErrorCleanup;
    } else {
        ALuint sourceID;
        _maxSources = 0;
        do {
            alGenSources(1, &sourceID);
            if(alGetError() == AL_NO_ERROR) {
                ++_maxSources;
                [_availSrcIDs addIndex:(EGWuint)sourceID];
            } else break;
        } while (_maxSources < (sndParams && sndParams->limitSources && sndParams->limitSources < EGW_SNDCONTEXT_MAXSOUNDS ? sndParams->limitSources : EGW_SNDCONTEXT_MAXSOUNDS));
    }
    if(!(_usedSrcIDs = [[NSMutableIndexSet alloc] init])) {
        NSLog(@"egwSndContextAL: initWithParams: Failure allocating object.");
        goto ErrorCleanup;
    }
    
    // Create buffer holders
    if(!(_availBufIDs = [[NSMutableIndexSet alloc] init])) {
        NSLog(@"egwSndContextAL: initWithParams: Failure allocating object.");
        goto ErrorCleanup;
    }
    if(!(_usedBufIDs = [[NSMutableIndexSet alloc] init])) {
        NSLog(@"egwSndContextAL: initWithParams: Failure allocating object.");
        goto ErrorCleanup;
    }
    if(!(_dstryBufIDs = [[NSMutableIndexSet alloc] init])) {
        NSLog(@"egwSndContextAL: initWithParams: Failure allocating object.");
        goto ErrorCleanup;
    }
    if(!(egwArrayInit(&_dstryBufData, NULL, sizeof(egwBufferDataDestroyWorkItem), 10, (EGW_ARRAY_FLG_GROWBY10 | EGW_ARRAY_FLG_GRWCND100 | EGW_ARRAY_FLG_SHRNKBY10)))) {
        NSLog(@"egwSndContextAL: initWithParams: Failure allocating object.");
        goto ErrorCleanup;
    }
    
    // Perform context-related state work
    _sVolume = 100;
    //alSpeedOfSound((ALfloat)val);
    //alDopplerFactor((ALfloat)val);
    //alDopplerVelocity((ALfloat)val);
    
    // If there is a delegate defined, call its willFinish method
    if(_delegate && ![_delegate willFinishInitializingSndContext:self]) {
        NSLog(@"egwSndContextAL: initWithParams: Failure in user initialization code.");
        goto ErrorCleanup;
    }
    
    // If there was an old context, revert back to it, otherwise keep this one enabled.
    pthread_mutex_unlock(&_apiLock_AL);
    if(oldContext) [oldContext makeActive];
    
    [_delegate didFinishInitializingSndContext:self];
    
    if(EGW_ENGINE_MANAGERS_STARTUPMSGS) NSLog(@"egwSndContextAL: initWithParams: Sound context has been initialized.");
    
    return self;
    
ErrorCleanup:
    --_apiRefCnt_AL;
    _thread = nil;
    pthread_mutex_unlock(&_apiLock_AL);
    [oldContext makeActive];
    [self release]; return (self = nil);
}

- (void)dealloc {
    // Forced shutdown - delegates should not be able to cancel
    {   id<egwDSndContextEvent> delegate = _delegate;
        _delegate = nil;
        [self shutDownContext];
        _delegate = delegate;
        [_delegate didShutDownSndContext:self];
    }
    
    if(_apiRefCnt_AL == 0) {
        @synchronized(self) {
            if(_apiRefCnt_AL == 0) {
                pthread_mutex_destroy(&_apiLock_AL);
            }
        }
    }
    
    [_extensions release]; _extensions = nil;
    
    pthread_mutex_destroy(&_iLock);
        
    [super dealloc];
}

- (void)performSubTasks {
    if(_sTasks.eCount || _dstryBufData.eCount || [_dstryBufIDs count]) {
        [super performSubTasks];
        
        pthread_mutex_lock(&_iLock);
        
        while([_dstryBufIDs count]) {
            NSString* errorString = nil;
            EGWuint bufID = (EGWuint)[_dstryBufIDs firstIndex];
            
            alGetError(); // Clear background errors
            
            if(alIsBuffer((ALuint)bufID)) {
                alDeleteBuffers((ALsizei)1, (const ALuint*)&bufID);
            }
            
            if(!egwIsALError(&errorString))
                [_dstryBufIDs removeIndex:(NSUInteger)bufID];
            else {
                NSLog(@"egwSndContextAL: performSubTasks: Failure deleting buffer ID %d, buffering 0x00 placeholder and moving to zombie set. ALError: %@", bufID, errorString);
                [_dstryBufIDs removeIndex:(NSUInteger)bufID];
                
                // NOTE: To ensure that we're using as minimal of memory as possible, reflash buffer with 0x00 to ensure as limited of memory as possible being wasted
                pthread_mutex_lock(&_apiLock_AL);
                egw_alBufferData((ALint)bufID,                          // Buffer identifier
                                 AL_FORMAT_MONO8,                       // Audio format
                                 (ALvoid*)&egwSIVecZero4f,              // Raw data buffer
                                 (ALsizei)1,                            // Size of data buffer (bytes)
                                 (ALsizei)11000);                       // Sampling rate (samples/sec)
                pthread_mutex_unlock(&_apiLock_AL);
                
                if(egwIsALError(&errorString))
                    NSLog(@"egwSndContextAL: performSubTasks: Failure buffering 0x00 placeholder into buffer ID %d, buffer memory is now being wasted. ALError: %s", bufID, (errorString ? (const char*)errorString : (const char*)"AL_NONE"));
            }
        }
        
        pthread_mutex_unlock(&_iLock);
    }
}

- (BOOL)makeActive {
    pthread_mutex_lock(&_apiLock_AL);
    
    if(_context) {
        if(egwAISndCntx == self)
            alcMakeContextCurrent(NULL);
        alcMakeContextCurrent(_context);
        egwAISndCntx = self;
        egwAISndCntxAL = self;
        
        pthread_mutex_unlock(&_apiLock_AL);
        return YES;
    } else {
        NSLog(@"egwSndContextAL: makeActive: Failure making active. Context is not valid.");
    }
    
    pthread_mutex_unlock(&_apiLock_AL);
    return NO;
}

- (BOOL)makeActiveAndLocked {
    if(_context) {
        pthread_mutex_lock(&_apiLock_AL);
        
        if(_context) {
            if(egwAISndCntx == self)
                alcMakeContextCurrent(NULL);
            alcMakeContextCurrent(_context);
            egwAISndCntx = self;
            egwAISndCntxAL = self;
            
            return YES;
        } else {
            NSLog(@"egwSndContextAL: makeActive: Failure making active. Context is not valid.");
            pthread_mutex_unlock(&_apiLock_AL);
        }
    } else {
        NSLog(@"egwSndContextAL: makeActive: Failure making active. Context is not valid.");
    }
    
    return NO;
}

- (EGWuint)requestFreeSourceID {
    EGWuint sourceID = NSNotFound;
    
    @synchronized(self) {
        if([_availSrcIDs count]) {
            sourceID = [_availSrcIDs lastIndex];
            [_availSrcIDs removeIndex:sourceID];
            [_usedSrcIDs addIndex:sourceID];
        } else {
            NSLog(@"egwSndContextAL: requestFreeSourceID: Failure generating new sources. Limit count reached.");
        } // sources are pre-gen'ed to max sounds, do not gen more!
    }
    
    return sourceID;
}

- (EGWuint)returnUsedSourceID:(EGWuint)sourceID {
    @synchronized(self) {
        if(sourceID && sourceID != NSNotFound) {  // sources ALWAYS get reused!
            //alSourcei((ALuint)sourceID, AL_BUFFER, (ALint)NULL);
            [_usedSrcIDs removeIndex:sourceID];
            [_availSrcIDs addIndex:sourceID];
        }
    }
    
    return NSNotFound;
}

- (EGWuint)requestFreeBufferID {
    EGWuint bufferID = NSNotFound;
    
    @synchronized(self) {
        if([_availBufIDs count]) {
            bufferID = [_availBufIDs lastIndex];
            [_availBufIDs removeIndex:bufferID];
            [_usedBufIDs addIndex:bufferID];
        } else {
            if([self isActive]) {
                NSString* errorString = nil;
                ALuint bufferIDs[EGW_SNDCONTEXT_BFFRGENCNT];
                
                alGetError(); // Clear background errors
                
                alGenBuffers(EGW_SNDCONTEXT_BFFRGENCNT, bufferIDs);
                
                if(!egwIsALError(&errorString)) {
                    for(EGWint i = EGW_SNDCONTEXT_BFFRGENCNT - 1; i > 0; --i)
                        [_availBufIDs addIndex:(EGWuint)bufferIDs[i]];
                    bufferID = (EGWuint)bufferIDs[0];
                    [_usedBufIDs addIndex:bufferID];
                } else {
                    NSLog(@"egwSndContextAL: requestFreeBufferID: Failure generating new buffers. ALError: %@", errorString);
                }
            } else {
                NSLog(@"egwSndContextAL: requestFreeBufferID: Failure generating new buffers. Context is not active [on this thread].");
            }
        }
    }
    
    return bufferID;
}

- (EGWuint)returnUsedBufferID:(EGWuint)bufferID {
    @synchronized(self) {
        if(bufferID && bufferID != NSNotFound) {  // Buffers should be deleted rather than re-used
            // Move to destroy list for delayed removal
            [_usedBufIDs removeIndex:(NSUInteger)bufferID];
            
            pthread_mutex_lock(&_iLock);
            [_dstryBufIDs addIndex:(NSUInteger)bufferID];
            pthread_mutex_unlock(&_iLock);
        }
    }
    
    return NSNotFound;
}

- (void)shutDownContext {
    if(!_doShutdown) {
        @synchronized(self) {
            if(!_doShutdown) {
                // Allow delegate to cancel shutDownContext, else proceed
                if(_delegate && ![_delegate willShutDownSndContext:self]) return;
                _doShutdown = YES;
                
                if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwSndContextAL: shutDownContext: Shutting down sound context.");
                
                if(_context && ![self isActive]) [self makeActive];
                pthread_mutex_lock(&_apiLock_AL);
                
                [super shutDownContext];
                
                // Destroy sources
                if(_usedSrcIDs) {
                    EGWuint sourcesCount = [_usedSrcIDs count];
                    if(sourcesCount) {
                        EGWuint* sourceIDs = (EGWuint*)malloc(sourcesCount * sizeof(EGWuint));
                        sourcesCount = [_usedSrcIDs getIndexes:sourceIDs maxCount:sourcesCount inIndexRange:nil];
                        alSourceStopv((ALsizei)sourcesCount, (const ALuint*)sourceIDs);
                        alDeleteSources((ALsizei)sourcesCount, (const ALuint*)sourceIDs);
                        free((void*)sourceIDs);
                    }
                    [_usedSrcIDs release]; _usedSrcIDs = nil;
                }
                if(_availSrcIDs) {
                    EGWuint sourcesCount = [_availSrcIDs count];
                    if(sourcesCount) {
                        EGWuint* sourceIDs = (EGWuint*)malloc(sourcesCount * sizeof(EGWuint));
                        sourcesCount = [_availSrcIDs getIndexes:sourceIDs maxCount:sourcesCount inIndexRange:nil];
                        alDeleteSources((ALsizei)sourcesCount, (const ALuint*)sourceIDs);
                        free((void*)sourceIDs);
                    }
                    [_availSrcIDs release]; _availSrcIDs = nil;
                }
                
                // Destroy buffers
                if(_dstryBufIDs) {
                    EGWuint buffersCount = [_dstryBufIDs count];
                    if(buffersCount) {
                        EGWuint* bufferIDs = (EGWuint*)malloc(buffersCount * sizeof(EGWuint));
                        buffersCount = [_dstryBufIDs getIndexes:bufferIDs maxCount:buffersCount inIndexRange: nil];
                        alDeleteBuffers((ALsizei)buffersCount, (const ALuint*)bufferIDs);
                        free((void*)bufferIDs);
                    }
                    [_dstryBufIDs release]; _dstryBufIDs = nil;
                }
                
                // NOTE: Buffer data segments are destroyed after context is brought down -jw
                
                if(_usedBufIDs) {
                    EGWuint buffersCount = [_usedBufIDs count];
                    if(buffersCount) {
                        EGWuint* bufferIDs = (EGWuint*)malloc(buffersCount * sizeof(EGWuint));
                        buffersCount = [_usedBufIDs getIndexes:bufferIDs maxCount:buffersCount inIndexRange: nil];
                        alDeleteBuffers((ALsizei)buffersCount, (const ALuint*)bufferIDs);
                        free((void*)bufferIDs);
                    }
                    [_usedBufIDs release]; _usedBufIDs = nil;
                }
                if(_availBufIDs) {
                    EGWuint buffersCount = [_availBufIDs count];
                    if(buffersCount) {
                        EGWuint* bufferIDs = (EGWuint*)malloc(buffersCount * sizeof(EGWuint));
                        buffersCount = [_availBufIDs getIndexes:bufferIDs maxCount:buffersCount inIndexRange: nil];
                        alDeleteBuffers((ALsizei)buffersCount, (const ALuint*)bufferIDs);
                        free((void*)bufferIDs);
                    }
                    [_availBufIDs release]; _availBufIDs = nil;
                }
                
                // Destroy context
                if(_context) {
                    --_apiRefCnt_AL;
                    if(egwAISndCntx == self) {
                        alcMakeContextCurrent(NULL);
                        egwAISndCntx = nil;
                        egwAISndCntxAL = nil;
                    }
                    _thread = nil;
                    alcDestroyContext(_context);
                    _context = NULL;
                }
                
                // Destroy device
                if(_device) {
                    alcCloseDevice(_device);
                    _device = NULL;
                }
                
                // Destroy buffer data segments
                if(_dstryBufData.eCount) {
                    [NSThread sleepForTimeInterval:0.01]; // This is a hack/fix for the audio hardware not catching up in time to remove sounds from the hardware buffer and thus causing access faults due to static buffer usage
                    
                    while(_dstryBufData.eCount) {
                        free((void*)(((egwBufferDataDestroyWorkItem*)egwArrayElementPtrTail(&_dstryBufData))->bufferData));
                        egwArrayRemoveTail(&_dstryBufData);
                    }
                }
                egwArrayFree(&_dstryBufData);
                
                pthread_mutex_unlock(&_apiLock_AL);
                [_delegate didShutDownSndContext:self];
                
                if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwSndContextAL: shutDownContext: Sound context shut down.");
            }
        }
    }
}

- (id<egwPCamera>)activeCamera {
    return _actvCamera;
}

+ (EGWint)apiIdent {
    return EGW_ENGINE_SNDAPI_OPENAL;
}

+ (pthread_mutex_t*)apiMutex {
    return &_apiLock_AL;
}

- (void)setSystemVolume:(EGWuint)volume {
    _sVolume = egwClampi(volume, 0, 100);
    
    // FIXME: We're just going to use the active camera playback sync for now. -jw
    if(_actvCamera)
        egwSFPVldtrInvalidate([_actvCamera playbackSync], @selector(invalidate));
}

- (BOOL)isActive {
    return (egwAISndCntx == self ? YES : NO); // no  && _thread == [NSThread currentThread]
}

- (BOOL)isExtAvailable:(NSString*)extName {
    if([_extensions containsObject:extName])
        return YES;
    return NO;
}

@end


@implementation egwSndContextAL (BufferLoading)

- (BOOL)loadBufferID:(EGWuint*)bufferID withAudio:(egwAudio*)audio resonationTransforms:(EGWuint)transforms {
    NSString* errorString = nil;
    BOOL apiLocked = NO;
    BOOL genID = NO;
    ALenum format;
    
    alGetError(); // Clear background errors
    
    if(!bufferID || !audio || !audio->data) {
        NSLog(@"egwSndContextAL: loadBufferID:withAudio:resonationTransforms: Invalid arguments passed to method.");
        goto ErrorCleanup;
    }
    
    if(![self makeActiveAndLocked]) {
        NSLog(@"egwSndContextAL: loadBufferID:withAudio:resonationTransforms: Failure making sound context active [on this thread] to buffer in sound data.");
        goto ErrorCleanup;
    }
    
    apiLocked = YES;
    
    if(*bufferID == 0 || *bufferID == NSNotFound) {
        if((*bufferID = [self requestFreeBufferID]) == NSNotFound) {
            NSLog(@"egwSndContextAL: loadBufferID:withAudio:resonationTransforms: Failure requesting free buffer ID.");
            goto ErrorCleanup;
        }
        
        genID = YES;
    }
    
    {   EGWint packingB = egwAudioPacking(audio);
        if(packingB != 1) {
            NSLog(@"egwSndContextAL: loadBufferID:withAudio:resonationTransforms: Failure setting up unpack alignment (%d) for sound data buffer. Data is not correctly byte aligned for AL buffering (should be 1).", packingB);
            goto ErrorCleanup;
        }
    }
    
    switch(audio->format) {
        case EGW_AUDIO_FRMT_MONOU8: { format = AL_FORMAT_MONO8; } break;
        case EGW_AUDIO_FRMT_MONOS16: { format = AL_FORMAT_MONO16; } break;
        case EGW_AUDIO_FRMT_STEREOU8: { format = AL_FORMAT_STEREO8; } break;
        case EGW_AUDIO_FRMT_STEREOS16: { format = AL_FORMAT_STEREO16; } break;
        default: {
            NSLog(@"egwSndContextAL: loadBufferID:withAudio:resonationTransforms: Unrecognized or unsupported audio format.");
            goto ErrorCleanup;
        } break;
    }
    
    egw_alBufferData((ALint)*bufferID,                          // Buffer identifier
                     format,                                    // Audio format
                     (ALvoid*)audio->data,                      // Raw data buffer
                     (ALsizei)(audio->pitch * audio->count),    // Size of data buffer (bytes)
                     (ALsizei)audio->rate);                     // Sampling rate (samples/sec)
    
    if(egwIsALError(&errorString)) {
        NSLog(@"egwSndContextAL: loadBufferID:withAudio:resonationTransforms: Failure buffering audio data into hardware buffer. ALError: %@", errorString);
        goto ErrorCleanup;
    }
    
    // Transfer complete, close it up.
    
    if(apiLocked) {
        apiLocked = NO;
        pthread_mutex_unlock([[self class] apiMutex]);
    }
    
    return YES;
    
ErrorCleanup:
    if(apiLocked) {
        if(genID)
            *bufferID = [self returnUsedBufferID:*bufferID];
        
        apiLocked = NO;
        pthread_mutex_unlock([[self class] apiMutex]);
    }
    
    return NO;
}

@end


#else

@implementation egwSndContextAL

- (id)init {
    NSLog(@"egwSndContextAL: init: Cannot initialize object due to build mode settings. YOU'RE DOING IT WRONG!");
    
    [self release]; return (self = nil);
}

- (id)initWithParams:(void*)params {
    NSLog(@"egwSndContextAL: initWithParams: Cannot initialize object due to build mode settings. YOU'RE DOING IT WRONG!");
    
    [self release]; return (self = nil);
}

@end

#endif


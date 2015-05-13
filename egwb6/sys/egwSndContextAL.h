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

/// @defgroup geWizES_sys_sndcontextal egwSndContextAL
/// @ingroup geWizES_sys
/// Sound Context.
/// @{

/// @file egwSndContextAL.h
/// Sound Context Interface.

#import "egwSysTypes.h"
#import "egwSndContext.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPSndContext.h"
#import "../inf/egwPCamera.h"
#import "../data/egwDataTypes.h"
#import "../snd/egwSndTypes.h"


#if defined(EGW_BUILDMODE_DESKTOP) || defined(EGW_BUILDMODE_IPHONE)
#define EGW_BUILDMODE_SND_AL

#import <OpenAL/al.h>
#import <OpenAL/alc.h>
#if defined(EGW_BUILDMODE_IPHONE)
#import <OpenAL/oalStaticBufferExtension.h>
#elif defined(EGW_BUILDMODE_MACOSX)
#import <OpenAL/MacOSX_OALExtensions.h>
#endif


/// OpenAL Sound Context.
/// Contains contextual data related to an OpenAL sound API.
@interface egwSndContextAL : egwSndContext {
    ALCdevice* _device;                     ///< OpenAL device.
    ALCcontext* _context;                   ///< OpenAL context.
    
    NSArray* _extensions;                   ///< Available AL/ALC extensions.
    
    pthread_mutex_t _iLock;                 ///< Index mutex lock.
    
    NSMutableIndexSet* _availSrcIDs;        ///< Available OpenAL sources.
    NSMutableIndexSet* _usedSrcIDs;         ///< Utilized OpenAL sources.
    
    NSMutableIndexSet* _availBufIDs;        ///< Available OpenAL buffer IDs.
    NSMutableIndexSet* _usedBufIDs;         ///< Utilized OpenAL buffer IDs.
    NSMutableIndexSet* _dstryBufIDs;        ///< Delayed destroy OpenAL buffer IDs (wrapped in sub-task).
}

/// Request Source Identifier Method.
/// Requests a context specific source identifier from the allocation pool.
/// @note Source identifiers are pre-generated, limited to the maximum number of active sources, and thus are re-used.
/// @return Source identifier, otherwise NSNotFound if error.
- (EGWuint)requestFreeSourceID;

/// Return Source Identifier Method.
/// Returns a context specific source identifier back to the allocation pool.
/// @param [in] sourceID Source identifier.
/// @return NSNotFound (for simplicity).
- (EGWuint)returnUsedSourceID:(EGWuint)sourceID;

/// Request Buffer Identifier Method.
/// Requests a context specific buffer identifier, generating more if none available.
/// @note Generating more buffer identifiers may fail if this context is unable to become active (on the current thread).
/// @return Buffer identifier, otherwise NSNotFound if error.
- (EGWuint)requestFreeBufferID;

/// Return Buffer Identifier Method.
/// Returns a context specific buffer identifier, destroying the corresponding buffer.
/// @param [in] bufferID Buffer identifier.
/// @return NSNotFound (for simplicity).
- (EGWuint)returnUsedBufferID:(EGWuint)bufferID;

@end


/// OpenAL Sound Context (Texture Loading).
/// Adds AL buffer loading capabilities from audios.
@interface egwSndContextAL (BufferLoading)

/// Load Buffer Identifier Method.
/// Loads @a audio into @a bufferID with provided parameters.
/// @param [in,out] bufferID Buffer identifier (outwards ownership transfer). May be NSNotFound (for request).
/// @param [in] audio Buffer audio data.
/// @param [in] transforms Sound audio load transformations (EGW_SOUND_TRFM_*).
/// @return YES if load successful, otherwise NO.
- (BOOL)loadBufferID:(EGWuint*)bufferID withAudio:(egwAudio*)audio resonationTransforms:(EGWuint)transforms;

@end


/// ALC Error Poller.
/// Polls for an error in ALC.
/// @note Resultant errorString strings are owned by this routine and should thus not be released.
/// @param [in] device OpenAL device context.
/// @param [out] errorString Error string associated with error.
/// @return 1 upon any error flag set high, otherwise 0.
EGWint egwIsALCError(ALCdevice* device, NSString** errorString);

/// AL Error Poller.
/// Polls for an error in AL.
/// @note Resultant errorString strings are owned by this routine and should thus not be released.
/// @param [out] errorString Error string associated with error.
/// @return 1 upon any error flag set high, otherwise 0.
EGWint egwIsALError(NSString** errorString);


#ifdef EGW_BUILDMODE_MACOSX
#define EGW_BUILDMODE_SND_AL_STATICBUFFER
/// AL Buffer Data Static Routine.
/// Pointer to the iPhone's OpenAL static (context local) data buffering routine.
/// @note Only set upon first instancing of an OpenAL context and if extension is available.
extern alBufferDataStaticProcPtr alBufferDataStatic;
#endif

/// AL Buffer Data Routine.
/// Assigned to static buffer routine if available, otherwise to normal routine.
/// @note Only set upon first instancing of an OpenAL context and if extension is available.
extern LPALBUFFERDATA egw_alBufferData;


#else

/// OpenAL Sound Context (Blank).
/// Contains a placeholder to the actual class in the invalid build case.
@interface egwSndContextAL : egwSndContext {
}
@end

#endif


/// Global currently active egwSndContextAL instance (weak).
extern egwSndContextAL* egwAISndCntxAL;

/// @}

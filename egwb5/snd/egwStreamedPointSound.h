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

/// @defgroup geWizES_snd_streamedpointsound egwStreamedPointSound
/// @ingroup geWizES_snd
/// Streamed Point Sound Asset.
/// @{

/// @file egwStreamedPointSound.h
/// Streamed Point Sound Asset Interface.

#import "egwSndTypes.h"
#import "../inf/egwPAsset.h"
#import "../inf/egwPObjLeaf.h"
#import "../inf/egwPAssetBase.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPPlayable.h"
#import "../inf/egwPStreamed.h"
#import "../inf/egwPStreamer.h"
#import "../math/egwMathTypes.h"
#import "../obj/egwObjTypes.h"
#import "../snd/egwPointSound.h"
#import "../misc/egwMiscTypes.h"


/// Streamed Point Sound Instance Asset.
/// Contains unique instance data relating to a streamed point sound object.
@interface egwStreamedPointSound : egwPointSound <egwPStreamed> {
    pthread_mutex_t _cLock;                 ///< Mutex lock for counter tracking.
    EGWuint32 _sCurr;                       ///< Current segment.
    EGWuint32 _sCount;                      ///< Segment count.
    EGWint32 _obsWork;                      ///< Outbound segments.
    EGWint32 _sQueued;                      ///< Segments queued.
    EGWint32 _sUnqueued;                    ///< Segments unqueued.
    
    EGWbyte** _bDatas;                      ///< Buffer datas (owned).
    EGWuint* _bufIDs;                       ///< Buffer identifiers (owned).
    EGWuint16 _bCount;                      ///< Buffer count.
    EGWuint16 _bSize;                       ///< Buffer size.
    
    void const * const * _stream;           ///< Stream decoder (alias).
}

/// Designated Initializer.
/// Initializes the streaming point sound asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] stream Decoder stream structure (ownership transfer).
/// @param [in] bfrCount Number of audio buffers to use. May be 0 (for default).
/// @param [in] bfrSize Size of audio buffers to use. May be 0 (for default).
/// @param [in] radius Sound hearing/bounding radius.
/// @param [in] transforms Sound audio load transformations (EGW_SOUND_TRFM_*).
/// @param [in] effects Sound audio effects. May be NULL (for default).
/// @param [in] rolloff Sound attenuation rolloff factor [0,inf).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent decoderStream:(void**)stream totalBuffers:(EGWuint16)bfrCount bufferSize:(EGWuint16)bfrSize soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms resonationEffects:(egwAudioEffects2f*)effects resonationRolloff:(EGWsingle)rolloff;

/// Preallocated Sound Initializer.
/// Initializes the streaming point sound asset from pre-allocated buffer identifiers/datas with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] stream Decoder stream structure (ownership transfer).
/// @param [in,out] bufferIDs Buffer identifiers (ownership transfer).
/// @param [in,out] bufferDatas Buffer datas (ownership transfer). May be NULL (if already managed).
/// @param [in] bfrCount Number of audio buffers to use. May be 0 (for default).
/// @param [in] bfrSize Size of audio buffers to use. May be 0 (for default).
/// @param [in] radius Sound hearing/bounding radius.
/// @param [in] transforms Sound audio load transformations (EGW_SOUND_TRFM_*).
/// @param [in] effects Sound audio effects. May be NULL (for default).
/// @param [in] rolloff Sound attenuation rolloff factor [0,inf).
/// @return Self upon success, otherwise nil.
- (id)initPreallocatedWithIdentity:(NSString*)assetIdent decoderStream:(void**)stream bufferIDs:(EGWuint**)bufferIDs bufferDatas:(EGWbyte***)bufferDatas totalBuffers:(EGWuint16)bfrCount bufferSize:(EGWuint16)bfrSize soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms resonationEffects:(egwAudioEffects2f*)effects resonationRolloff:(EGWsingle)rolloff;

/// Loaded Sound Initializer.
/// Initializes the streaming point sound asset from a loaded audio stream with provided settings.
/// @note Non-power-of-two surfaces may be used, but will be smudge extended to a power-of-two surface.
/// @param [in] resourceFile Resource file to load from.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] bfrCount Number of audio buffers to use. May be 0 (for default).
/// @param [in] bfrSize Size of audio buffers to use. May be 0 (for default).
/// @param [in] radius Sound hearing/bounding radius.
/// @param [in] transforms Sound audio load transformations (EGW_SOUND_TRFM_*).
/// @param [in] effects Sound audio effects. May be NULL (for default).
/// @param [in] rolloff Sound attenuation rolloff factor [0,inf).
/// @return Self upon success, otherwise nil.
- (id)initLoadedFromResourceFile:(NSString*)resourceFile withIdentity:(NSString*)assetIdent totalBuffers:(EGWuint16)bfrCount bufferSize:(EGWuint16)bfrSize soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms resonationEffects:(egwAudioEffects2f*)effects resonationRolloff:(EGWsingle)rolloff;

/// Copy Initializer.
/// Copies a streaming sound asset with provided unique settings.
/// @param [in] asset Asset to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] bfrCount Number of audio buffers to use. May be 0 (for copy-over).
/// @param [in] bfrSize Size of audio buffers to use. May be 0 (for copy-over).
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent totalBuffers:(EGWuint16)bfrCount bufferSize:(EGWuint16)bfrSize;


/// Buffer Count Accessor.
/// Returns the total number of buffers.
/// @return Number of buffers.
- (EGWuint)bufferCount;

/// Buffer Size Accessor.
/// Returns the size of buffers.
/// @return Buffer size (bytes).
- (EGWuint)bufferSize;

/// Buffer ID Accessor.
/// Returns the buffer identifiers array.
/// @note Ownership transfer is not allowed.
/// @return Buffer identifiers array.
- (const EGWuint*)bufferIDs;

/// Buffer Datas Accessor.
/// Returns buffer data array.
/// @return Buffer datas array.
- (EGWbyte const * const *)bufferDatas;

/// Total Segments Accessor.
/// Returns the total number of segments for the sound.
/// @return Total segments.
- (EGWuint)segmentCount;

/// Current Segment Accessor.
/// Returns the current segment the sound is playing on.
/// @return Current segment.
- (EGWuint)segmentCurrent;

@end

/// @}

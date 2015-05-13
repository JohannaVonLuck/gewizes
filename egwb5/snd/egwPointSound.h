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

/// @defgroup geWizES_snd_pointsound egwPointSound
/// @ingroup geWizES_snd
/// Point Sound Asset.
/// @{

/// @file egwPointSound.h
/// Point Sound Asset Interface.

#import "egwSndTypes.h"
#import "../inf/egwPAsset.h"
#import "../inf/egwPObjLeaf.h"
#import "../inf/egwPAssetBase.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPSubTask.h"
#import "../inf/egwPPlayable.h"
#import "../inf/egwPBounding.h"
#import "../inf/egwPSound.h"
#import "../math/egwMathTypes.h"
#import "../obj/egwObjTypes.h"
#import "../misc/egwMiscTypes.h"


/// Point Sound Instance Asset.
/// Contains unique instance data relating to a static point sound object.
@interface egwPointSound : NSObject <egwPAsset, egwPObjectLeaf, egwPSound, egwDValidationEvent> {
    egwPointSoundBase* _base;               ///< Base object instance (retained).
    NSString* _ident;                       ///< Unique identity (retained).
    id<egwDSoundEvent> _delegate;           ///< Event responder delegate (retained).
    BOOL _invkParent;                       ///< Parent invocation tracking.
    BOOL _ortPending;                       ///< Orientation transforms pending.
    BOOL _isPlaying;                        ///< Tracks playing status.
    id<egwPObjectBranch> _parent;           ///< Parent node (weak).
    
    EGWuint32 _pFlags;                      ///< Playback flags.
    EGWuint16 _pFrame;                      ///< Playback frame number.
    egwValidater* _pSync;                   ///< Playback order sync (retained).
    
    egwAudioEffects2f _effects;             ///< Audio effects settings.
    EGWsingle _rolloff;                     ///< Distance attenuation factor.
    egwValidater* _rSync;                   ///< Resonation binding sync (retained).
    id<egwPInterpolator> _effectsIpo;       ///< Audio effects driver interpolator (retained).
    
    egwMatrix44f _wcsTrans;                 ///< Orientation transform (LCS->WCS).
    egwMatrix44f _lcsTrans;                 ///< Offset transform (MMCS->LCS).
    egwVector4f _wcsVelocity;               ///< Velocity vector (WCS).
    id<egwPBounding> _wcsPBVol;             ///< Playback volume (WCS, retained).
    id<egwPInterpolator> _wcsIpo;           ///< Orientation driver interpolator (retained).
    id<egwPInterpolator> _lcsIpo;           ///< Offset driver interpolator (retained).
    
    EGWuint _srcID;                         ///< Source identifier.
    EGWuint _smpOffset;                     ///< Sample offset of sound.
    BOOL _isRestarting;                     ///< Tracks restarting status.
    BOOL _isPaused;                         ///< Tracks paused status.
    BOOL _isFinished;                       ///< Tracks finished status.
    BOOL _stopHandled;                      ///< Tracks handlement of stopped status.
}

/// Designated Initializer.
/// Initializes the point sound asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] audio Sound audio data (contents ownership transfer).
/// @param [in] radius Sound hearing/bounding radius.
/// @param [in] transforms Sound audio load transformations (EGW_SOUND_TRFM_*).
/// @param [in] effects Sound audio effects. May be NULL (for default).
/// @param [in] rolloff Sound attenuation rolloff factor [0,inf).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent soundAudio:(egwAudio*)audio soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms resonationEffects:(egwAudioEffects2f*)effects resonationRolloff:(EGWsingle)rolloff;

/// Blank Sound Initializer.
/// Initializes the point sound asset as blank audio with provided settings.
/// @note This method does not clear/set-to-zero the allocated surface prior to return.
/// @note Once audio is prepared, one should invalidate the sound buffer sync to start the buffering sequence.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] format Sound audio format (EGW_AUDIO_FRMT_*). May be 0 (for EGW_AUDIO_FRMT_STEREO_INT16).
/// @param [in] rate Sound audio sampling rate (samples per second).
/// @param [in] count Sound audio samples count [2,inf).
/// @param [in] radius Sound hearing/bounding radius.
/// @param [in] transforms Sound audio load transformations (EGW_SOUND_TRFM_*).
/// @param [in] effects Sound audio effects. May be NULL (for default).
/// @param [in] rolloff Sound attenuation rolloff factor [0,inf).
/// @return Self upon success, otherwise nil.
- (id)initBlankWithIdentity:(NSString*)assetIdent audioFormat:(EGWuint32)format soundRate:(EGWuint)rate soundSamples:(EGWuint)count soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms resonationEffects:(egwAudioEffects2f*)effects resonationRolloff:(EGWsingle)rolloff;

/// Preallocated Sound Initializer.
/// Initializes the point sound asset from a pre-allocated buffer identifier/data with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] bufferID Buffer identifier (ownership transfer).
/// @param [in,out] audio Sound audio data (contents ownership transfer).
/// @param [in] radius Sound hearing/bounding radius.
/// @param [in] transforms Sound audio load transformations (EGW_SOUND_TRFM_*).
/// @param [in] effects Sound audio effects. May be NULL (for default).
/// @param [in] rolloff Sound attenuation rolloff factor [0,inf).
/// @return Self upon success, otherwise nil.
- (id)initPreallocatedWithIdentity:(NSString*)assetIdent bufferID:(EGWuint*)bufferID soundAudio:(egwAudio*)audio soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms resonationEffects:(egwAudioEffects2f*)effects resonationRolloff:(EGWsingle)rolloff;

/// Loaded Sound Initializer.
/// Initializes the point sound asset from a loaded audio with provided settings.
/// @note Non-power-of-two surfaces may be used, but will be smudge extended to a power-of-two surface.
/// @param [in] resourceFile Resource file to load from.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] radius Sound hearing/bounding radius.
/// @param [in] transforms Sound audio load transformations (EGW_SOUND_TRFM_*).
/// @param [in] effects Sound audio effects. May be NULL (for default).
/// @param [in] rolloff Sound attenuation rolloff factor [0,inf).
/// @return Self upon success, otherwise nil.
- (id)initLoadedFromResourceFile:(NSString*)resourceFile withIdentity:(NSString*)assetIdent soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms resonationEffects:(egwAudioEffects2f*)effects resonationRolloff:(EGWsingle)rolloff;

/// Copy Initializer.
/// Copies a point sound asset with provided unique settings.
/// @param [in] asset Asset to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent;


/// Sample Offset Accessor.
/// Returns the (last polled) PCM sample offset of sound.
/// @return Sample offset.
- (EGWuint)sampleOffset;

/// Source ID Accessor.
/// Returns the context referenced source identifier.
/// @note Ownership transfer is not allowed.
/// @return Source identifier.
- (EGWuint)sourceID;


/// Delegate Mutator.
/// Sets the sound's event responder delegate to @a delegate.
/// @param [in] delegate Event responder delegate (retained).
- (void)setDelegate:(id<egwDSoundEvent>)delegate;

/// Gain Mutator.
/// Sets the gain level.
/// @param [in] gain Sound gain level [0,1]. May be NULL (for default).
- (void)setGain:(EGWsingle*)gain;

/// Pitch Mutator.
/// Sets the pitch level.
/// @param [in] pitch Sound pitch level [0,1]. May be NULL (for default).
- (void)setPitch:(EGWsingle*)pitch;

@end


/// Point Sound Asset Base.
/// Contains shared instance data relating to point sound objects.
/// @note Doubles up for base to both egwPointSound and egwStreamedPointSound - not all fields are used.
@interface egwPointSoundBase : NSObject <egwPAssetBase, egwPSubTask, egwDValidationEvent> {
    EGWuint _instCounter;                   ///< Instantiation counter.
    NSString* _ident;                       ///< Unique identity (retained).
    
    BOOL _isSDPersist;                      ///< Tracks audio persistence status.
    
    egwValidater* _sbSync;                  ///< Sound buffer sync (retained).
    EGWuint _rsnTrans;                      ///< Sound transforms.
    union {
        struct {
            egwAudio sAudio;                ///< Sound audio (contents owned).
            EGWuint bufID;                  ///< Buffer identifier.
        } ns;                               ///< Non-streaming buffer data.
        struct {
            void* dStream;                  ///< Stream decoder structure.
        } s;                                ///< Streaming buffer data.
    } _bfData;                              ///< Buffer data union.
    EGWuint _bfType;                        ///< Buffer data type (1-NS, 2-S).
    
    id<egwPBounding> _mmcsPBVol;            ///< Playback volume (MMCS, retained).
}

/// Point Sound Initializer.
/// Initializes the sound asset base for use with a non-streaming point sound with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] audio Sound audio data (contents ownership transfer).
/// @param [in] radius Sound hearing/bounding radius.
/// @param [in] transforms Sound audio load transformations (EGW_SOUND_TRFM_*).
/// @return Self upon success, otherwise nil.
- (id)initNSWithIdentity:(NSString*)assetIdent soundAudio:(egwAudio*)audio soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms;

/// Blank Sound Initializer.
/// Initializes the sound asset base for use with a non-streaming point sound as blank audio with provided settings.
/// @note This method does not clear/set-to-zero the allocated surface prior to return.
/// @note Once audio is prepared, one should invalidate the sound buffer sync to start the buffering sequence.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] format Sound audio format (EGW_AUDIO_FRMT_*). May be 0 (for EGW_AUDIO_FRMT_STEREO_INT16).
/// @param [in] rate Sound audio sampling rate (samples per second).
/// @param [in] count Sound audio samples count [2,inf).
/// @param [in] radius Sound hearing/bounding radius.
/// @param [in] transforms Sound audio load transformations (EGW_SOUND_TRFM_*).
/// @return Self upon success, otherwise nil.
- (id)initNSBlankWithIdentity:(NSString*)assetIdent audioFormat:(EGWuint32)format soundRate:(EGWuint)rate soundSamples:(EGWuint)count soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms;

/// Preallocated Point Sound Initializer.
/// Initializes the sound asset base from a pre-allocated buffer identifier/data for use with a non-streaming point sound with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] bufferID Buffer identifier (ownership transfer).
/// @param [in,out] audio Sound audio data (contents ownership transfer). Field .data may be NULL (if already managed).
/// @param [in] radius Sound hearing/bounding radius.
/// @param [in] transforms Sound audio load transformations (EGW_SOUND_TRFM_*).
/// @return Self upon success, otherwise nil.
- (id)initNSPreallocatedWithIdentity:(NSString*)assetIdent bufferID:(EGWuint*)bufferID soundAudio:(egwAudio*)audio soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms;

/// Streaming Point Sound Initializer.
/// Initializes the sound asset base for use with a streaming point sound with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] stream Decoder stream structure (ownership transfer).
/// @param [in] radius Sound hearing/bounding radius.
/// @param [in] transforms Sound audio load transformations (EGW_SOUND_TRFM_*).
/// @return Self upon success, otherwise nil.
- (id)initSWithIdentity:(NSString*)assetIdent decoderStream:(void**)stream soundRadius:(EGWsingle)radius resonationTransforms:(EGWuint)transforms;


/// Base Offset (byTransform) Method.
/// Offsets the sound base data in the MCS by the provided @a transform for subsequent render passes.
/// @note Base offsetting will cause untracked sync invalidation to shared object instances!
/// @param [in] transform MCS->MMCS transformation matrix.
- (void)baseOffsetByTransform:(const egwMatrix44f*)transform;


/// Sound Buffer Syncronization Validater Accessor.
/// Returns the validater that manages component synchronization with a hardware buffer.
/// @return Sound buffer validater, otherwise nil (if unused).
- (egwValidater*)soundBufferSync;

/// Sound Radius Accessor.
/// Returns the base MMCS sound bounding radius.
/// @return Sound radius (MMCS).
- (EGWsingle)soundRadius;

/// Playback Bounding Volume Accessor.
/// Returns the base MMCS playback bounding volume.
/// @return Playback bounding volume (MMCS).
- (id<egwPBounding>)playbackBounding;

/// Resonation Transforms Accessor.
/// Returns the sound transforms settings.
/// @return Resonation transforms (EGW_SOUND_TRFM_*).
- (EGWuint)resonationTransforms;

/// Buffer Type Accessor.
/// Returns the type of buffer data stored.
/// @return Buffer type (1-Non-streaming, 2-Streaming).
- (EGWuint)bufferType;

/// Buffer ID Accessor.
/// Returns the context referenced buffer identifier.
/// @note Ownership transfer is not allowed.
/// @return Buffer identifier, otherwise NULL (if not non-streaming buffer data).
- (const EGWuint*)bufferID;

/// Sound Audio Accessor.
/// Returns the sound's base audio data (if available).
/// @return Sound base audio data, otherwise NULL (if unavailable or not non-streaming buffer data).
- (const egwAudio*)soundAudio;

/// Stream Decoder Accessor.
/// Returns a pointer to the decoder stream structure.
/// @note Ownership transfer is not allowed.
/// @return Stream decoder structure, otherwise NULL (if not streaming buffer data).
- (void const * const *)streamDecoder;


/// Sound Buffer Data Persistence Tryer.
/// Attempts to set the persistence of local data for the sound buffer to @a persist.
/// @param [in] persist Persistence setting of local buffer data.
/// @return YES if setting was successfully changed, otherwise NO.
- (BOOL)trySetSoundDataPersistence:(BOOL)persist;


/// IsSoundDataPersistent Poller.
/// Polls the object to determine status.
/// @return YES if sound buffer is persistent, otherwise NO.
- (BOOL)isSoundDataPersistent;

@end

/// @}

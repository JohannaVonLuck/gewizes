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

/// @defgroup geWizES_sys_assetmanager egwAssetManager
/// @ingroup geWizES_sys
/// Asset Manager.
/// @{

/// @file egwAssetManager.h
/// Asset Manager Interface.

#import "egwSysTypes.h"
#import "../inf/egwPSingleton.h"
#import "../inf/egwPAsset.h"
#import "../inf/egwPAssetBase.h"
#import "../data/egwDataTypes.h"
#import "../snd/egwSndTypes.h"


#define EGW_ASSTMNGR_SDECTHREADS     1      ///< Total number of stream decoder threads in thread pool.
#define EGW_ASSTMNGR_SDECPRIORITY    0.50   ///< Stream decoder threads' priority.


/// Asset Manager.
/// Manages instances of assets and performs operations relating to such. In
/// other words, is just one big hash table that keeps tags on referenced assets
/// for tracking & retrieval purposes.
@interface egwAssetManager : NSObject <egwPSingleton> {
    pthread_mutex_t _aLock;                 ///< Assets table lock.
    NSMutableDictionary* _assetsTable;      ///< Assets table dictionary.
    NSString* _workDir;                     ///< Current working directory.
    NSString* _pfPerf;                      ///< Postfix filename perferance.
    
    pthread_mutex_t _qLock;                 ///< Work item queues lock.
    pthread_cond_t _wCond;                  ///< Work wait signal condition.
    NSThread* _tPool[EGW_ASSTMNGR_SDECTHREADS]; ///< Decoder threads pool.
    egwCyclicArray _wQueue;                 ///< Decoding work items queue.
    
    BOOL _doShutdown;                       ///< Tracks to-shutdown status.
}

/// Asset Load (fromFile) Method.
/// Loads the asset named @a assetIdent into manager from provided @a resourceFile.
/// @note The resource file may be a manifest file.
/// @note In the case of a non-manifest file @a assetIdent names the resource.
/// @param [in] assetIdent Asset name identifier (retained).
/// @param [in] resourceFile Resource file to examine.
/// @return YES upon success, otherwise NO.
- (BOOL)loadAsset:(NSString*)assetIdent fromFile:(NSString*)resourceFile;

/// Asset Load (fromFilewithParams) Method.
/// Loads the asset named @a assetIdent into manager from provided @a resourceFile with the provided @a params.
/// @note The resource file may be a manifest file.
/// @note In the case of a non-manifest file @a assetIdent names the resource.
/// @param [in] assetIdent Asset name identifier (retained).
/// @param [in] resourceFile Resource file to examine.
/// @param [in] params Parameters option structure. May be nil for default (if supported).
/// @return YES upon success, otherwise NO.
- (BOOL)loadAsset:(NSString*)assetIdent fromFile:(NSString*)resourceFile withParams:(void*)params;

/// Asset Load (fromExisting) Method.
/// Loads an existing asset into manager from provided @a asset.
/// @param [in] assetIdent Asset name identifier (retained).
/// @param [in] asset Asset resource.
/// @return YES upon success, otherwise NO.
- (BOOL)loadAsset:(NSString*)assetIdent fromExisting:(id<egwPAsset>)asset;

/// Assets Load (fromManifest) Method.
/// Loads all assets into manager from provided @a resourceFile.
/// @note The resource file _MUST_ be a manifest file.
/// @param [in] resourceFile Resource file to examine.
/// @return Number of assets loaded.
- (EGWuint)loadAssetsFromManifest:(NSString*)resourceFile;

/// Asset Unload Method.
/// Releases the asset named @a assetIdent from manager.
/// @param [in] assetIdent Asset name identifier.
/// @return YES if asset removed, otherwise NO.
- (BOOL)unloadAsset:(NSString*)assetIdent;

/// Asset Unload (withPrefix) Method.
/// Releases any assets named with prefix @a assetIdentPrefix from manager.
/// @param [in] assetIdentPrefix Asset name identifier prefix.
/// @return Number of assets removed.
- (EGWuint)unloadAssetsWithPrefix:(NSString*)assetIdentPrefix;

/// Asset Unload (withSuffix) Method.
/// Releases any assets named with suffix @a assetIdentSuffix from manager.
/// @param [in] assetIdentSuffix Asset name identifier suffix.
/// @return Number of assets removed.
- (EGWuint)unloadAssetsWithSuffix:(NSString*)assetIdentSuffix;

/// All Assets Unload Method.
/// Releases all assets from manager.
/// @return Number of assets removed.
- (EGWuint)unloadAllAssets;

/// Asset Retrieval Method.
/// Returns asset named @a assetIdent.
/// @param [in] assetIdent Asset name identifier.
/// @return Asset resource.
- (id<egwPAsset>)retrieveAsset:(NSString*)assetIdent;

/// Assets Retrieval (withPrefixUsingArray) Method.
/// Returns any asset named  with prefix @a assetIdentPrefix.
/// @param [in] assetIdentPrefix Asset name identifier prefix.
/// @param [out] assetArray Array of assets output operand.
/// @return Number of elements found.
- (EGWuint)retrieveAssetsWithPrefix:(NSString*)assetIdentPrefix usingArray:(NSMutableArray*)assetArray;

/// Assets Retrieval (withSuffixUsingArray) Method.
/// Returns any asset named  with suffix @a assetIdentSuffix.
/// @param [in] assetIdentSuffix Asset name identifier suffix.
/// @param [out] assetArray Array of assets output operand.
/// @return Number of elements found.
- (EGWuint)retrieveAssetsWithSuffix:(NSString*)assetIdentSuffix usingArray:(NSMutableArray*)assetArray;

/// Asset Insantiation Method.
/// Returns a new instantiation (copy of default) of asset named @a assetIdent.
/// @param [in] assetIdent Asset name identifier.
/// @return Asset resource (autoreleased).
- (id<egwPAsset>)instantiateAsset:(NSString*)assetIdent;

/// Add Decoding Work (forSoundAsset) Method.
/// Enqueue a work item for @a streamedAsset to the streaming sound decoder mechanism with provided parameters.
/// @note After work is completed a reply message to playWithFlags: is sent back to the sound object with flags EGW_SNDOBJ_PLAYFLG_BUFFERLOADED set and the upper 16 bits set to the lower 16 bits of @a bufferID.
/// @param [in] streamedAsset Streaming asset object (retained).
/// @param [in] stream Pointer to a data structure with decoder specific data.
/// @param [in] segmentID Segment identifier. May be NSNotFound (destroys stream).
/// @param [in] bufferID Buffer identifier. May be NSNotFound (destroys stream).
/// @param [in] bufferData Buffer raw data. Ownership should be retained, but not transfered.
/// @param [in] bufferSize Buffer size.
/// @return YES upon successful addition, otherwise NO.
- (BOOL)addDecodingWorkForSoundAsset:(id<egwPAsset>)streamedAsset withStreamDecoder:(void*)stream segmentID:(EGWuint)segmentID bufferID:(EGWuint)bufferID bufferData:(EGWbyte*)bufferData bufferSize:(EGWuint)bufferSize;

/// Remove All Decoding Work (forSoundAsset) Method.
/// Dequeues any work items for @a streamedAsset from the streaming sound decoder mechanism.
/// @param [in] streamedAsset Streaming asset object.
/// @return Number of work items removed.
- (EGWuint)removeAllDecodingWorkForSoundAsset:(id<egwPAsset>)streamedAsset;

/// Shut Down Stream Decoders Method.
/// Signals stream decoders to shut down.
- (void)shutDownStreamDecoders;


/// Working Directory Accessor.
/// Returns the current working directory.
/// @return Current working directory.
- (NSString*)workingDirectory;


/// Filename Postfix Perferance Mutator.
/// Sets the filename postfix perferance, used to "prefer" one file type over another, effective on all asset manager loader methods.
/// @param[in] postfix Filename postfix perferance.
- (void)setFilenamePostfixPerferance:(NSString*)postfix;

/// Working Directory Mutator.
/// Sets the current working directory.
/// @param [in] directory Working directory.
- (void)setWorkingDirectory:(NSString*)directory;

@end


/// Asset Manager (Base Tracking).
/// Adds asset base tracking capabilities. Asset manager gracefully stalls for
/// a few seconds on shutdown in an attempt to wait for all asset bases to
/// release gracefully, otherwise issues an error message and continues with an
/// ungraceful shutdown.
@interface egwAssetManager (BaseTracking)

/// Increment Base References.
/// Increments base reference count by one.
+ (void)incBaseRef;

/// Decrement Base References.
/// Decrements base reference count by one.
+ (void)decBaseRef;

@end


/// Asset Manager (Data Loading).
/// Adds direct data loading capabilities from resource files.
@interface egwAssetManager (DataLoading)

/// Audio Loading Method.
/// Loads an audio from @a resourceFile to @a audio with provided audio @a transforms.
/// @param [out] audio Audio data from load.
/// @param [in] resourceFile Resource file to load from.
/// @param [in] transforms Audio load transformations (EGW_AUDIO_TRFM_*).
/// @return YES if load successful, otherwise NO.
- (BOOL)loadAudio:(egwAudio*)audio fromFile:(NSString*)resourceFile withTransforms:(EGWuint)transforms;

/// Audio Streamer Loading Method.
/// Loads an audio streamer from @a resourceFile to @a stream with provided audio @a transforms.
/// @note Due to streaming, not all transforms are applicable.
/// @param [out] stream Pointer to audio streamer structure from load.
/// @param [in] resourceFile Resource file to laod from.
/// @param [in] transforms Audio load transformations (EGW_AUDIO_TRFM_*).
/// @return YES if load successful, otherwise NO.
- (BOOL)loadAudioStream:(void**)stream fromFile:(NSString*)resourceFile withTransforms:(EGWuint)transforms;

/// Glyph Map Loading Method.
/// Loads a glpyh mapping set from @a resourceFile to @a mapset with provided surface @a transforms.
/// @param [out] mapset Glyph mapset data from load.
/// @param [in] resourceFile Resource file to load from.
/// @param [in] effects Font rasterization effects (EGW_FONT_EFCT_*).
/// @param [in] ptSize Point size of font.
/// @return YES if load successful, otherwise NO.
- (BOOL)loadGlyphMap:(egwAMGlyphSet*)mapset fromFile:(NSString*)resourceFile withEffects:(EGWuint)effects pointSize:(EGWsingle)ptSize;

/// Surface Loading Method.
/// Loads a surface from @a resourceFile to @a surface with provided surface @a transforms.
/// @param [out] surface Surface data from load.
/// @param [in] resourceFile Resource file to load from.
/// @param [in] transforms Surface load transformations (EGW_SURFACE_TRFM_*).
/// @return YES if load successful, otherwise NO.
- (BOOL)loadSurface:(egwSurface*)surface fromFile:(NSString*)resourceFile withTransforms:(EGWuint)transforms;

@end


/// OV Error Poller.
/// Polls for an error in OggVorbis.
/// @note Resultant errorString strings are owned by this routine and should thus not be released.
/// @param [in] retVal Routine return value.
/// @param [out] errorString Error string associated with error.
/// @return 1 upon any error flag set high, otherwise 0.
EGWint egwIsOggVorbisError(EGWint retVal, NSString** errorString);

/// FT Error Poller.
/// Polls for an error in FreeType.
/// @note Resultant errorString strings are owned by this routine and should thus not be released.
/// @param [in] retVal Routine return value.
/// @param [out] errorString Error string associated with error.
/// @return 1 upon any error flag set high, otherwise 0.
EGWint egwIsFreeTypeError(EGWint retVal, NSString** errorString);


/// Global current singleton egwAssetManager instance (weak).
extern egwAssetManager* egwSIAsstMngr;

/// @}

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

/// @defgroup geWizES_phy_interpolators egwInterpolators
/// @ingroup geWizES_phy
/// Interpolator Assets.
/// @{

/// @file egwInterpolators.h
/// Interpolator Assets Interfaces.

#import "egwPhyTypes.h"
#import "../inf/egwPAsset.h"
#import "../inf/egwPAssetBase.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPPhyContext.h"
#import "../inf/egwPOrientated.h"
#import "../inf/egwPInterpolator.h"
#import "../inf/egwPTimed.h"
#import "../inf/egwPTimer.h"
#import "../math/egwMathTypes.h"
#import "../data/egwDataTypes.h"
#import "../misc/egwMiscTypes.h"


/// Key Frame Value Interpolator Instance Asset.
/// Contains unique instance data relating to a key framed value interpolator.
@interface egwValueInterpolator : NSObject <egwPAsset, egwPInterpolator> {
    egwInterpolatorBase* _base;             ///< Base object instance (retained).
    NSString* _ident;                       ///< Unique identity (retained).
    
    egwKnotTrack _track;                    ///< Main knot track.
    EGWtime _eAbsT;                         ///< Evaluated absolute time index (seconds).
    id<egwPTimer> _eTimer;                  ///< Evaluation timer (retained).
    
    egwSinglyLinkedList _tOutputs;          ///< Target output collection (contents weak).
    pthread_mutex_t _tLock;                 ///< Target output collection lock.
    EGWbyte* _tvOutput;                     ///< Target temp value output storage (owned).
    
    egwKeyFrame* _kFrames;                  ///< Key frames (aliased).
}

/// Designated Initializer.
/// Initializes the interpolator asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] frames Interpolation key frame data (contents ownership transfer).
/// @param [in] polationMode Bit-wise i/e-polation mode settings (EGW_POLATION_*).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent keyFrames:(egwKeyFrame*)frames polationMode:(EGWuint32)polationMode;

/// Blank Interpolator Initializer.
/// Initializes the interpolator asset as a blank key frame set with provided settings.
/// @note This method does not clear/set-to-zero the allocated key frames prior to return.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] chnFormat Key value channel format (EGW_KEYCHANNEL_FRMT_*).
/// @param [in] chnCount Key value channel count [1,inf].
/// @param [in] cmpCount Component count [1,inf].
/// @param [in] frmCount Key frame count [1,inf].
/// @param [in] polationMode Bit-wise i/e-polation mode settings (EGW_POLATION_*).
/// @return Self upon success, otherwise nil.
- (id)initBlankWithIdentity:(NSString*)assetIdent channelFormat:(EGWuint16)chnFormat channelCount:(EGWuint16)chnCount componentCount:(EGWuint16)cmpCount frameCount:(EGWuint16)frmCount polationMode:(EGWuint32)polationMode;

/// Copy Initializer.
/// Copies an interpolator asset with provided unique settings.
/// @param [in] asset Asset to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent;


/// Channel Format Accessor.
/// Returns the channel format.
/// @return Channel format (EGW_KEYCHANNEL_FRMT_*).
- (EGWuint16)channelFormat;

/// Channel Count Accessor.
/// Returns the channel count.
/// @return Channel count.
- (EGWuint16)channelCount;

/// Component Count Accessor.
/// Returns the component count.
/// @return Component count.
- (EGWuint16)componentCount;

/// Frame Count Accessor.
/// Returns the frame count.
/// @return Frame count.
- (EGWuint16)frameCount;

/// Last Output Accessor.
/// Returns the last output used by the interpolator.
/// @return Last used output.
- (const EGWbyte*)lastOutput;

/// Polation Mode Accessor.
/// Returns i/e-polation mode settings.
/// @return Bit-wise i/e-polation mode settings (EGW_POLATION_*).
- (EGWuint32)polationMode;


/// Key Frame Key Data Mutator.
/// Sets the key data indexed by key frame @a frameIndex to @a data.
/// @param [in] frameIndex Frame index [0,n-1].
/// @param [in] data Key value data (contents copy).
/// @note This method is provided for simplicity; it affects all asset instances connected to the asset base.
- (void)setKeyFrame:(EGWuint16)frameIndex keyData:(EGWbyte*)data;

/// Key Frame Extra Key Data Mutator.
/// Sets the extra key data indexed by key frame @a frameIndex to @a data.
/// @param [in] frameIndex Frame index [0,n-1].
/// @param [in] data Key value extra data (contents copy).
/// @note This method is provided for simplicity; it affects all asset instances connected to the asset base.
- (void)setKeyFrame:(EGWuint16)frameIndex extraKeyData:(EGWbyte*)data;

/// Key Frame Time Index Mutator.
/// Sets the time index indexed by key frame @a frameIndex to @a time.
/// @param [in] frameIndex Frame index [0,n-1].
/// @param [in] time Absolute key frame time (seconds).
/// @note Time indexes should always stay in ascending sorted order.
/// @note This method is provided for simplicity; it affects all asset instances connected to the asset base.
- (void)setKeyFrame:(EGWuint16)frameIndex timeIndex:(EGWtime)time;

/// Polation Mode Mutator.
/// Sets the i/e-polation mode settings to @a polationMode.
/// @param [in] polationMode Bit-wise i/e-polation mode settings (EGW_POLATION_*).
/// @note Polation mode change may not succeed due to frame data requirements.
- (void)setPolationMode:(EGWuint32)polationMode;

@end


/// Key Frame Object Orientator Instance Asset.
/// Contains unique instance data relating to a key framed orientation interpolator (orientator).
@interface egwOrientationInterpolator : NSObject <egwPAsset, egwPInterpolator> {
    egwInterpolatorBase* _base;             ///< Base object instance (retained).
    NSString* _ident;                       ///< Unique identity (retained).
    
    egwKnotTrack _pTrack;                   ///< Position knot track.
    egwKnotTrack _rTrack;                   ///< Rotation knot track.
    egwKnotTrack _sTrack;                   ///< Scaling knot track.
    EGWtime _eAbsT;                         ///< Evaluated absolute time index (seconds).
    id<egwPTimer> _eTimer;                  ///< Evaluation timer (retained).
    
    egwSinglyLinkedList _tOutputs;          ///< Target output collection (contents retained).
    pthread_mutex_t _tLock;                 ///< Target output collection lock.
    egwMatrix44f _tmOutput;                 ///< Target temp matrix output storage.
    
    egwOrientKeyFrame4f* _kFrames;          ///< Orientation key frames (aliased).
    
    BOOL _isNormQuatRot;                    ///< Tracks quaternion renormalization.
}

/// Designated Initializer.
/// Initializes the interpolator asset with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] frames Interpolation key frame data (contents ownership transfer).
/// @param [in] posPolationMode Position bit-wise i/e-polation mode settings (EGW_POLATION_*).
/// @param [in] rotPolationMode Rotation bit-wise i/e-polation mode settings (EGW_POLATION_*).
/// @param [in] sclPolationMode Scale bit-wise i/e-polation mode settings (EGW_POLATION_*).
/// @return Self upon success, otherwise nil.
- (id)initWithIdentity:(NSString*)assetIdent keyFrames:(egwOrientKeyFrame4f*)frames positionPolationMode:(EGWuint32)posPolationMode rotationPolationMode:(EGWuint32)rotPolationMode scalePolationMode:(EGWuint32)sclPolationMode;

/// Blank Interpolator Initializer.
/// Initializes the interpolator asset as a blank key frame set with provided settings.
/// @note This method does not clear/set-to-zero the allocated key frames prior to return.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in] posFrmCount Positional key frames count [0|[1,inf]].
/// @param [in] posPolationMode Position bit-wise i/e-polation mode settings (EGW_POLATION_*).
/// @param [in] rotFrmCount Rotational key frames count [0|[1,inf]].
/// @param [in] rotPolationMode Rotation bit-wise i/e-polation mode settings (EGW_POLATION_*).
/// @param [in] sclFrmCount Scaling key frames count [0|[1,inf]].
/// @param [in] sclPolationMode Scale bit-wise i/e-polation mode settings (EGW_POLATION_*).
/// @return Self upon success, otherwise nil.
- (id)initBlankWithIdentity:(NSString*)assetIdent positionFrameCount:(EGWuint16)posFrmCount positionPolationMode:(EGWuint32)posPolationMode rotationFrameCount:(EGWuint16)rotFrmCount rotationPolationMode:(EGWuint32)rotPolationMode scaleFrameCount:(EGWuint16)sclFrmCount scalePolationMode:(EGWuint32)sclPolationMode;

/// Copy Initializer.
/// Copies an interpolator asset with provided unique settings.
/// @param [in] asset Asset to clone.
/// @param [in] assetIdent Unique object identity (retained).
/// @return Self upon success, otherwise nil.
- (id)initCopyOf:(id<egwPAsset>)asset withIdentity:(NSString*)assetIdent;


/// Last Output Accessor.
/// Returns the last output used by the interpolator.
/// @return Last used output.
- (const egwMatrix44f*)lastOutput;

/// Position Frame Count Accessor.
/// Returns the position frame count.
/// @return Position frame count.
- (EGWuint16)positionFrameCount;

/// Position Polation Mode Accessor.
/// Returns position i/e-polation mode settings.
/// @return Position bit-wise i/e-polation mode settings (EGW_POLATION_*).
- (EGWuint32)positionPolationMode;

/// Rotation Frame Count Accessor.
/// Returns the rotation frame count.
/// @return Rotation frame count.
- (EGWuint16)rotationFrameCount;

/// Rotation Polation Mode Accessor.
/// Returns rotation i/e-polation mode settings.
/// @return Rotation bit-wise i/e-polation mode settings (EGW_POLATION_*).
- (EGWuint32)rotationPolationMode;

/// Scale Frame Count Accessor.
/// Returns the scale frame count.
/// @return Scale frame count.
- (EGWuint16)scaleFrameCount;

/// Scale Polation Mode Accessor.
/// Returns scale i/e-polation mode settings.
/// @return Scale bit-wise i/e-polation mode settings (EGW_POLATION_*).
- (EGWuint32)scalePolationMode;


/// Positional Key Frame Key Data Mutator.
/// Sets the positional key data indexed by key frame @a frameIndex to @a data.
/// @param [in] frameIndex Frame index [0,n-1].
/// @param [in] data Key value position vector.
/// @note This method is provided for simplicity; it affects all asset instances connected to the asset base.
- (void)setPositionKeyFrame:(EGWuint16)frameIndex keyData:(egwVector3f*)data;

/// Positional Key Frame Extra Key Data Mutator.
/// Sets the positional extra key data indexed by key frame @a frameIndex to @a data.
/// @param [in] frameIndex Frame index [0,n-1].
/// @param [in] data Extra key value data.
/// @note This method is provided for simplicity; it affects all asset instances connected to the asset base.
- (void)setPositionKeyFrame:(EGWuint16)frameIndex extraKeyData:(EGWbyte*)data;

/// Positional Key Frame Time Index Mutator.
/// Sets the positional time index indexed by key frame @a frameIndex to @a time.
/// @param [in] frameIndex Frame index [0,n-1].
/// @param [in] time Absolute key frame time (seconds).
/// @note Time indexes should always stay in ascending sorted order.
/// @note This method is provided for simplicity; it affects all asset instances connected to the asset base.
- (void)setPositionKeyFrame:(EGWuint16)frameIndex timeIndex:(EGWtime)time;

/// Position Polation Mode Mutator.
/// Sets the position i/e-polation mode settings to @a posPolationMode.
/// @param [in] posPolationMode Position bit-wise i/e-polation mode settings (EGW_POLATION_*).
/// @note Polation mode change may not succeed due to frame data requirements.
- (void)setPositionPolationMode:(EGWuint32)posPolationMode;

/// Rotational Key Frame Key Data Mutator.
/// Sets the rotational key data indexed by key frame @a frameIndex to @a data.
/// @param [in] frameIndex Frame index [0,n-1].
/// @param [in] data Key value quaternion.
/// @note This method is provided for simplicity; it affects all asset instances connected to the asset base.
- (void)setRotationKeyFrame:(EGWuint16)frameIndex keyData:(egwQuaternion4f*)data;

/// Rotational Key Frame Extra Key Data Mutator.
/// Sets the rotational extra key data indexed by key frame @a frameIndex to @a data.
/// @param [in] frameIndex Frame index [0,n-1].
/// @param [in] data Extra key value data.
/// @note This method is provided for simplicity; it affects all asset instances connected to the asset base.
- (void)setRotationKeyFrame:(EGWuint16)frameIndex extraKeyData:(EGWbyte*)data;

/// Rotational Key Frame Time Index Mutator.
/// Sets the rotational time index indexed by key frame @a frameIndex to @a time.
/// @param [in] frameIndex Frame index [0,n-1].
/// @param [in] time Absolute key frame time (seconds).
/// @note Time indexes should always stay in ascending sorted order.
/// @note This method is provided for simplicity; it affects all asset instances connected to the asset base.
- (void)setRotationKeyFrame:(EGWuint16)frameIndex timeIndex:(EGWtime)time;

/// Rotation Polation Mode Mutator.
/// Sets the rotation i/e-polation mode settings to @a rotPolationMode.
/// @param [in] rotPolationMode Rotation bit-wise i/e-polation mode settings (EGW_POLATION_*).
/// @note Polation mode change may not succeed due to frame data requirements.
- (void)setRotationPolationMode:(EGWuint32)rotPolationMode;

/// Scaling Key Frame Key Data Mutator.
/// Sets the scaling key data indexed by key frame @a frameIndex to @a data.
/// @param [in] frameIndex Frame index [0,n-1].
/// @param [in] data Key value scaling vector.
/// @note This method is provided for simplicity; it affects all asset instances connected to the asset base.
- (void)setScaleKeyFrame:(EGWuint16)frameIndex keyData:(egwVector3f*)data;

/// Scaling Key Frame Extra Key Data Mutator.
/// Sets the scaling extra key data indexed by key frame @a frameIndex to @a data.
/// @param [in] frameIndex Frame index [0,n-1].
/// @param [in] data Extra key value data.
/// @note This method is provided for simplicity; it affects all asset instances connected to the asset base.
- (void)setScaleKeyFrame:(EGWuint16)frameIndex extraKeyData:(EGWbyte*)data;

/// Scaling Key Frame Time Index Mutator.
/// Sets the scaling time index indexed by key frame @a frameIndex to @a time.
/// @param [in] frameIndex Frame index [0,n-1].
/// @param [in] time Absolute key frame time (seconds).
/// @note Time indexes should always stay in ascending sorted order.
/// @note This method is provided for simplicity; it affects all asset instances connected to the asset base.
- (void)setScaleKeyFrame:(EGWuint16)frameIndex timeIndex:(EGWtime)time;

/// Scale Polation Mode Mutator.
/// Sets the scale i/e-polation mode settings to @a sclPolationMode.
/// @param [in] sclPolationMode Scale bit-wise i/e-polation mode settings (EGW_POLATION_*).
/// @note Polation mode change may not succeed due to frame data requirements.
- (void)setScalePolationMode:(EGWuint32)sclPolationMode;

@end


/// Key Frame Asset Base.
/// Contains shared instance data relating to key frames.
@interface egwInterpolatorBase : NSObject <egwPAssetBase> {
    EGWuint _instCounter;                   ///< Instantiation counter.
    NSString* _ident;                       ///< Unique identity (retained).
    
    union {
        egwKeyFrame* iFrames;               ///< Value interpolator key frames (owned).
        egwOrientKeyFrame4f* oFrames;       ///< Orientation interpolator key frames (owned).
    } _kFrames;                             ///< Key frames union.
    EGWuint _kfType;                        ///< Key frame type (1-VI, 2-OI).
}

/// Value Interpolator Initializer.
/// Initializes the interpolator asset base for use with a value interpolator with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] frames Interpolation key frame data (contents ownership transfer).
/// @return Self upon success, otherwise nil.
- (id)initVIBWithIdentity:(NSString*)assetIdent keyFrames:(egwKeyFrame*)frames;

/// Orientation Interpolator Initializer.
/// Initializes the interpolator asset base for use with an orientation interpolator with provided settings.
/// @param [in] assetIdent Unique object identity (retained).
/// @param [in,out] frames Interpolation key frame data (contents ownership transfer).
/// @return Self upon success, otherwise nil.
- (id)initOIBWithIdentity:(NSString*)assetIdent orientKeyFrames:(egwOrientKeyFrame4f*)frames;


/// Keys Type Accessor.
/// Returns the type of key frames data stored.
/// @return Key frames type (1-Value Interpolator, 2-Orientation Interpolator).
- (EGWuint)keysType;

/// Key Frames Accessor.
/// Returns the key frame data structure.
/// @return Key frame data structure, otherwise NULL if not value interpolator key frame data.
- (egwKeyFrame*)keyFrames;

/// Orient Key Frames Accessor.
/// Returns the orient key frame data structure.
/// @return Orient key frame data structure, otherwise NULL if not orientation interpolator key frame data.
- (egwOrientKeyFrame4f*)orientKeyFrames;

@end


/// @}

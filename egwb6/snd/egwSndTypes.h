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

/// @defgroup geWizES_snd_types egwSndTypes
/// @ingroup geWizES_snd
/// Sound Types.
/// @{

/// @file egwSndTypes.h
/// Sound Types.

#import "../inf/egwTypes.h"


// !!!: ***** Predefs *****

@class egwPointSound;
@class egwPointSoundBase;
@class egwStreamedPointSound;


// !!!: ***** Defines *****

#define EGW_SOUND_MAXSTATIC         2097152 ///< Maximum uncompressed sound audio size allowed before a streaming instance should be used instead.

#define EGW_STRMSOUND_BUFFERSIZE    16384   ///< Streaming sound buffer size (should always be divisable by 4).
#define EGW_STRMSOUND_NUMBUFFERS    30      ///< Number of stream buffers allocated for sound objects that stream (cyclic).
#define EGW_STRMSOUND_NUMBFNTPLY    25      ///< Number of stream buffers that need to be fully loaded in order for sound to start playing.

#define EGW_AUDIO_DFLTBPACKING      1       ///< Default audio byte packing.

// Audio formats
#define EGW_AUDIO_FRMT_MONOU8       0x0108  ///< 8-bpc unsigned mono (8um).
#define EGW_AUDIO_FRMT_MONOS16      0x4110  ///< 16-bpc signed mono (16sm).
#define EGW_AUDIO_FRMT_STEREOU8     0x0208  ///< 8-bpc unsigned stereo (8us).
#define EGW_AUDIO_FRMT_STEREOS16    0x4210  ///< 16-bpc/32-bpdp signed stereo (16ss).
#define EGW_AUDIO_FRMT_EXMONO       0x0100  ///< Used to extract mono channel usage from bitfield.
#define EGW_AUDIO_FRMT_EXSTEREO     0x0200  ///< Used to extract stereo channel usage from bitfield.
#define EGW_AUDIO_FRMT_EXBPC        0x00ff  ///< Used to extract bits per channel (bpc) from bitfield.
#define EGW_AUDIO_FRMT_EXSIGNED     0x4000  ///< Used to extract signed channel usage from bitfield.

// Audio load transforms
#define EGW_AUDIO_TRFM_ENSRLTETMS  0x000001 ///< Ensures that audio size is less than or equal to the max static size.
#define EGW_AUDIO_TRFM_INVERTS     0x000010 ///< Inverts audio signal.
#define EGW_AUDIO_TRFM_SWAPLR      0x000020 ///< Swaps audio left/right orientation (if >= stereo).
#define EGW_AUDIO_TRFM_RVRSDIR     0x000040 ///< Reverses audio direction forwards/backwards.
#define EGW_AUDIO_TRFM_FORCEU8     0x000100 ///< Forces audio conversion to 8-bpc unsigned channel values.
#define EGW_AUDIO_TRFM_FORCES16    0x000200 ///< Forces audio conversion to 16-bpc signed channel values.
#define EGW_AUDIO_TRFM_FORCEMONO   0x000400 ///< Forces audio conversion to a mono channel.
#define EGW_AUDIO_TRFM_FORCESTEREO 0x000800 ///< Forces audio conversion to a stereo channel.
#define EGW_AUDIO_TRFM_FCMONOU8    0x000500 ///< Forces audio conversion to 8-bpc unsigned mono.
#define EGW_AUDIO_TRFM_FCMONOS16   0x000600 ///< Forces audio conversion to 16-bpc signed mono.
#define EGW_AUDIO_TRFM_FCSTEREOU8  0x000900 ///< Forces audio conversion to 8-bpc unsigned stereo.
#define EGW_AUDIO_TRFM_FCSTEREOS16 0x000a00 ///< Forces audio conversion to 16-bpc signed stereo.
#define EGW_AUDIO_TRFM_FCBPCK1     0x100000 ///< Forces 1 byte packing on audio pitch size.
#define EGW_AUDIO_TRFM_FCBPCK2     0x200000 ///< Forces 2 byte packing on audio pitch size.
#define EGW_AUDIO_TRFM_FCBPCK4     0x300000 ///< Forces 4 byte packing on audio pitch size.
#define EGW_AUDIO_TRFM_FCBPCK8     0x400000 ///< Forces 8 byte packing on audio pitch size.
#define EGW_AUDIO_TRFM_FCBPCK16    0x500000 ///< Forces 16 byte packing on audio pitch size.
#define EGW_AUDIO_TRFM_FCBPCK32    0x600000 ///< Forces 32 byte packing on audio pitch size.
#define EGW_AUDIO_TRFM_FCBPCK64    0x700000 ///< Forces 64 byte packing on audio pitch size.
#define EGW_AUDIO_TRFM_FCBPCK128   0x800000 ///< Forces 128 byte packing on audio pitch size.
#define EGW_AUDIO_TRFM_FCBPCK256   0x900000 ///< Forces 256 byte packing on audio pitch size.
#define EGW_AUDIO_TRFM_FCBPCK512   0xa00000 ///< Forces 512 byte packing on audio pitch size.
#define EGW_AUDIO_TRFM_FCBPCK1024  0xb00000 ///< Forces 1024 byte packing on audio pitch size.
#define EGW_AUDIO_TRFM_FCBPCK2048  0xc00000 ///< Forces 2048 byte packing on audio pitch size.
#define EGW_AUDIO_TRFM_FCBPCK4096  0xd00000 ///< Forces 4096 byte packing on audio pitch size.
#define EGW_AUDIO_TRFM_FCBPCK8192  0xe00000 ///< Forces 8192 byte packing on audio pitch size.
#define EGW_AUDIO_TRFM_EXBPACKING  0xf00000 ///< Used to extract forced byte packing usage from bitfield.
#define EGW_AUDIO_TRFM_EXENSURES   0x00000f ///< Used to extract ensurances usage from bitfield.
#define EGW_AUDIO_TRFM_EXDATAOPS   0x000ff0 ///< Used to extract data operations usage from bitfield.
#define EGW_AUDIO_TRFM_EXFORCES    0x0ff000 ///< Used to extract forced conversions usage from bitfield.
#define EGW_AUDIO_TRFM_EXBPACKING  0xf00000 ///< Used to extract forced byte packing usage from bitfield.

// !!!: ***** Audio Structures *****

/// Audio Samples Container.
/// Universal PCM audio samples container.
typedef struct {
    EGWuint32 format;                       ///< Data format.
    EGWuint32 rate;                         ///< Sampling rate (per second).
    EGWuint32 pitch;                        ///< Sample width (bytes).
    EGWuint32 count;                        ///< Samples count.
    EGWtime length;                         ///< Approximated audio length (seconds).
    EGWbyte* data;                          ///< Audio data buffer.
} egwAudio;

/// Audio Effects Container.
/// Contains audio effect settings.
typedef struct {
    EGWsingle gain;                         ///< Signal amplitude factor [0,1].
    EGWsingle pitch;                        ///< Signal frequency factor [0,1].
} egwAudioEffects2f;


// !!!: ***** Audio Samples *****

/// 16-bit Mono (EGW_AUDIO_FRMT_MONOS16).
typedef union {
    struct {
        EGWint16 m;                         ///< Magnitude value [-32768, 32767].
    } channel;                              ///< Channel values.
    EGWint16 sample[1];                     ///< Samples array.
    EGWuint8 bytes[2];                      ///< Byte array.
} egwMonoPCM;

/// 16-bit Stereo (EGW_AUDIO_FRMT_STEREOS16).
typedef union {
    struct {
        EGWint16 l;                         ///< Left channel magnitude value [-32768, 32767].
        EGWint16 r;                         ///< Right channel magnitude value [-32768, 32767].
    } channel;                              ///< Channel values.
    EGWint16 sample[2];                     ///< Samples array.
    EGWuint8 bytes[4];                      ///< Byte array.
} egwStereoPCM;


// !!!: ***** Parameters *****

/// Sound Parameters.
/// Contains optional parameters for point sound initialization.
/// @note Used primarily for egwAssetManager:loadAsset: interaction.
typedef struct {
    EGWuint aTransforms;                    ///< Load transformations (EGW_AUDIO_TRFM_*).
    EGWsingle aRadius;                      ///< Audio hearing radius.
    egwAudioEffects2f aEffects;             ///< Audio effects settings.
    EGWsingle aRolloff;                     ///< Audio rolloff factor.
    EGWuint8 tBuffers;                      ///< Total audio buffers (only for streamed instances).
    EGWuint16 bSize;                        ///< Audio buffer size (only for streamed instances).
} egwSndParams;


// !!!: ***** Event Delegate Protocols *****

/// Sound Event Delegate.
/// Defines events that a delegate object can handle.
@protocol egwDSoundEvent <NSObject>

/// Sound Did Behavior.
/// Called when a sound object performs a behavior related to playing.
/// @param [in] sound Sound object.
/// @param [in] action Behavioral flag setting (EGW_ACTION_*).
- (void)sound:(id<egwPSound>)sound did:(EGWuint32)action;

@end

/// @}

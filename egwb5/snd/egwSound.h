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

/// @defgroup geWizES_snd_sound egwSound
/// @ingroup geWizES_snd
/// Base Sound.
/// @{

/// @file egwSound.h
/// Base Sound Interface.

#import "egwSndTypes.h"


// !!!: ***** Helper Routines *****

/// Audio Format From Transforms Routine.
/// Calculates the resulting audio format using the provided parameters.
/// @param [in] transforms Audio transforms (EGW_AUDIO_TRFM_*).
/// @param [in] dfltFormat Default audio format (EGW_AUDIO_FRMT_*).
/// @return Resulting surface format (EGW_AUDIO_FRMT_*).
EGWuint32 egwFormatFromAudioTrfm(EGWuint transforms, EGWuint32 dfltFormat);

/// Audio Byte Packing From Transforms Routine.
/// Calculates the resulting audio sample byte packing using the provided parameters.
/// @param [in] transforms Audio transforms (EGW_AUDIO_TRFM_*).
/// @param [in] dfltBPacking Default sample byte packing.
/// @return Resulting audio sample byte packing.
EGWint egwBytePackingFromAudioTrfm(EGWuint transforms, EGWint dfltBPacking);


// !!!: ***** Audio Operations *****

/// Audio Allocation Routine.
/// Allocates the audio structure using the provided parameters.
/// @param [out] audio_out Audio output structure.
/// @param [in] format Audio format (EGW_AUDIO_FRMT_*).
/// @param [in] rate Audio sample playback bit-rate (bytes/second).
/// @param [in] samples Audio samples count.
/// @param [in] packingB Audio byte packing.
/// @return @a audio_out (for nesting), otherwise NULL if failure initializing.
egwAudio* egwAudioAlloc(egwAudio* audio_out, EGWuint32 format, EGWuint32 rate, EGWuint32 samples, EGWuint16 packingB);

/// Audio Copy Routine.
/// Copies the audio structure into a newly allocated one.
/// @param [in] audio_in Audio input structure.
/// @param [out] audio_out Audio output structure.
/// @return @a audio_out (for nesting), otherwise NULL if failure copying.
egwAudio* egwAudioCopy(const egwAudio* audio_in, egwAudio* audio_out);

/// Audio Free Routine.
/// Frees the contents of the audio structure.
/// @param [in,out] audio_inout Audio input/output structure.
/// @return @a audio_inout (for nesting), otherwise NULL if failure free'ing.
egwAudio* egwAudioFree(egwAudio* audio_inout);

/// Audio Left/Right Channel Swap Routine.
/// Swaps the left/right channels of a stereo audio structure.
/// @param [in,out] audio_inout Audio input/output structure.
/// @return @a audio_inout (for nesting), otherwise NULL if not a stereo audio.
egwAudio* egwAudioSwapLR(egwAudio* audio_inout);

/// Audio Invert Signal Routine.
/// Inverts the magnitude signals of an audio structure.
/// @param [in,out] audio_inout Audio input/output structure.
/// @return @a audio_inout (for nesting).
egwAudio* egwAudioInvertSig(egwAudio* audio_inout);

/// Audio Reverse Direction Routine.
/// Reverses the direction of an audio structure by reordering its byte stream.
/// @param [in,out] audio_inout Audio input/output structure.
/// @return @a audio_inout (for nesting).
egwAudio* egwAudioReverseDir(egwAudio* audio_inout);

/// Audio Convert Routine.
/// Attempts to convert the audio structure to a new format.
/// @param [in] format New format to convert to (EGW_AUDIO_FRMT_*).
/// @param [in] audio_in Audio input structure.
/// @param [out] audio_out Audio output structure.
/// @return @a audio_out (for nesting), otherwise NULL if failure converting.
egwAudio* egwAudioConvert(EGWuint format, const egwAudio* audio_in, egwAudio* audio_out);

/// Audio Repacking Routine.
/// Attempts to repack the audio structure to a new byte packing.
/// @param [in] packingB New byte packing.
/// @param [in] audio_in Audio input structure.
/// @param [out] audio_out Audio output structure.
/// @return @a audio_out (for nesting), otherwise NULL if failure repacking.
egwAudio* egwAudioRepack(EGWuint16 packingB, const egwAudio* audio_in, egwAudio* audio_out);

/// Audio Maximum Signal Routine.
/// Calculates the maximum signal magnitude generated by an audio structure.
/// @param [in] audio_in Audio input structure.
/// @return Maximum signal magnitude.
EGWint16 egwAudioMaxSig(const egwAudio* audio_in);

/// Audio Minimum Signal Routine.
/// Calculates the minimum signal magnitude generated by an audio structure.
/// @param [in] audio_in Audio input structure.
/// @return Minimum signal magnitude.
EGWint16 egwAudioMinSig(const egwAudio* audio_in);

/// Audio Packing Routine.
/// Calculates the minimum byte packing that has been used by an audio structure.
/// @param [in] audio_in Audio input structure.
/// @return Minimum byte packing.
EGWint egwAudioPacking(const egwAudio* audio_in);


// !!!: ***** PCM Operations *****

/// PCM Read Mono.
/// Reads a mono PCM sample from a raw PCM stream.
/// @param [in] format Format of raw PCM stream.
/// @param [in] pcm_in Raw PCM input operand.
/// @param [out] val_out Mono PCM output operand.
void egwPCMReadMb(EGWuint format, const EGWbyte* pcm_in, egwMonoPCM* val_out);

/// PCM Read Stereo.
/// Reads a stereo PCM sample from a raw PCM stream.
/// @param [in] format Format of raw PCM stream.
/// @param [in] pcm_in Raw PCM input operand.
/// @param [out] val_out Stereo PCM output operand.
void egwPCMReadSb(EGWuint format, const EGWbyte* pcm_in, egwStereoPCM* val_out);

/// Arrayed PCM Read Mono.
/// Reads an array of mono PCM samples from a raw PCM stream.
/// @param [in] format Format of raw PCM stream.
/// @param [in] pcms_in Array of raw PCM input operands.
/// @param [out] vals_out Array of mono PCM output operands.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwPCMReadMbv(EGWuint format, const EGWbyte* pcms_in, egwMonoPCM* vals_out, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count);

/// Arrayed PCM Read Stereo.
/// Reads an array of stereo PCM samples from a raw PCM stream.
/// @param [in] format Format of raw PCM stream.
/// @param [in] pcms_in Array of raw PCM input operands.
/// @param [out] vals_out Array of stereo PCM output operands.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwPCMReadSbv(EGWuint format, const EGWbyte* pcms_in, egwStereoPCM* vals_out, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count);

/// PCM Write Mono.
/// Writes a mono PCM sample to a raw PCM stream.
/// @param [in] format Format of raw PCM stream.
/// @param [in] val_in Mono PCM input operand.
/// @param [out] pcm_out Raw PCM output operand.
void egwPCMWriteMb(EGWuint format, const egwMonoPCM* val_in, EGWbyte* pcm_out);

/// PCM Write Stereo.
/// Writes a stereo PCM sample to a raw PCM stream.
/// @param [in] format Format of raw PCM stream.
/// @param [in] val_in Stereo PCM input operand.
/// @param [out] pcm_out Raw PCM output operand.
void egwPCMWriteSb(EGWuint format, const egwStereoPCM* val_in, EGWbyte* pcm_out);

/// Arrayed PCM Write Mono.
/// Writes an array of mono PCM samples to a raw PCM stream.
/// @param [in] format Format of raw PCM stream.
/// @param [in] vals_in Array of mono PCM input operands.
/// @param [out] pcms_out Array of raw PCM output operands.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwPCMWriteMbv(EGWuint format, const egwMonoPCM* vals_in, EGWbyte* pcms_out, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count);

/// Arrayed PCM Write Stereo.
/// Writes an array of stereo PCM samples to a raw PCM stream.
/// @param [in] format Format of raw PCM stream.
/// @param [in] vals_in Array of stereo PCM input operands.
/// @param [out] pcms_out Array of raw PCM output operands.
/// @param [in] strideB_in Array advancing skip bytes on input operands.
/// @param [in] strideB_out Array advancing skip bytes on output operands.
/// @param [in] count Array element count.
void egwPCMWriteSbv(EGWuint format, const egwStereoPCM* vals_in, EGWbyte* pcms_out, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count);

/// @}

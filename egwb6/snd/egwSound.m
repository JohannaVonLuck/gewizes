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

/// @file egwSound.m
/// @ingroup geWizES_snd_sound
/// Base Sound Implementation.

#import "egwSound.h"
#import "../math/egwMath.h"


EGWuint32 egwFormatFromAudioTrfm(EGWuint transforms, EGWuint32 dfltFormat) {
    switch(transforms & EGW_AUDIO_TRFM_EXFORCES) {
        case EGW_AUDIO_TRFM_FCMONOU8: return EGW_AUDIO_FRMT_MONOU8;
        case EGW_AUDIO_TRFM_FCMONOS16: return EGW_AUDIO_FRMT_MONOS16;
        case EGW_AUDIO_TRFM_FCSTEREOU8: return EGW_AUDIO_FRMT_STEREOU8;
        case EGW_AUDIO_TRFM_FCSTEREOS16: return EGW_AUDIO_FRMT_STEREOS16;
        case EGW_AUDIO_TRFM_FORCEU8: {
            switch(dfltFormat) {
                case EGW_AUDIO_FRMT_MONOU8: return EGW_AUDIO_FRMT_MONOU8;
                case EGW_AUDIO_FRMT_MONOS16: return EGW_AUDIO_FRMT_MONOU8;
                case EGW_AUDIO_FRMT_STEREOU8: return EGW_AUDIO_FRMT_STEREOU8;
                case EGW_AUDIO_FRMT_STEREOS16: return EGW_AUDIO_FRMT_STEREOU8;
                default: return dfltFormat & ~EGW_AUDIO_FRMT_EXSIGNED;
            }
        } break;
        case EGW_AUDIO_TRFM_FORCES16: {
            switch(dfltFormat) {
                case EGW_AUDIO_FRMT_MONOU8: return EGW_AUDIO_FRMT_MONOS16;
                case EGW_AUDIO_FRMT_MONOS16: return EGW_AUDIO_FRMT_MONOS16;
                case EGW_AUDIO_FRMT_STEREOU8: return EGW_AUDIO_FRMT_STEREOS16;
                case EGW_AUDIO_FRMT_STEREOS16: return EGW_AUDIO_FRMT_STEREOS16;
                default: return dfltFormat | EGW_AUDIO_FRMT_EXSIGNED;
            }
        } break;
        case EGW_AUDIO_TRFM_FORCEMONO: {
            switch(dfltFormat) {
                case EGW_AUDIO_FRMT_MONOU8: return EGW_AUDIO_FRMT_MONOU8;
                case EGW_AUDIO_FRMT_MONOS16: return EGW_AUDIO_FRMT_MONOS16;
                case EGW_AUDIO_FRMT_STEREOU8: return EGW_AUDIO_FRMT_MONOU8;
                case EGW_AUDIO_FRMT_STEREOS16: return EGW_AUDIO_FRMT_MONOS16;
                default: return (dfltFormat & ~(EGW_AUDIO_FRMT_EXMONO | EGW_AUDIO_FRMT_EXSTEREO)) | EGW_AUDIO_FRMT_EXMONO;
            }
        } break;
        case EGW_AUDIO_TRFM_FORCESTEREO: {
            switch(dfltFormat) {
                case EGW_AUDIO_FRMT_MONOU8: return EGW_AUDIO_FRMT_STEREOU8;
                case EGW_AUDIO_FRMT_MONOS16: return EGW_AUDIO_FRMT_STEREOS16;
                case EGW_AUDIO_FRMT_STEREOU8: return EGW_AUDIO_FRMT_STEREOU8;
                case EGW_AUDIO_FRMT_STEREOS16: return EGW_AUDIO_FRMT_STEREOS16;
                default: return (dfltFormat & ~(EGW_AUDIO_FRMT_EXMONO | EGW_AUDIO_FRMT_EXSTEREO)) | EGW_AUDIO_FRMT_EXSTEREO;
            }
        } break;
        default: return dfltFormat;
    }
}

EGWint egwBytePackingFromAudioTrfm(EGWuint transforms, EGWint dfltBPacking) {
    switch(transforms & EGW_AUDIO_TRFM_EXBPACKING) {
        case EGW_AUDIO_TRFM_FCBPCK1: return 1;
        case EGW_AUDIO_TRFM_FCBPCK2: return 2;
        case EGW_AUDIO_TRFM_FCBPCK4: return 4;
        case EGW_AUDIO_TRFM_FCBPCK8: return 8;
        case EGW_AUDIO_TRFM_FCBPCK16: return 16;
        case EGW_AUDIO_TRFM_FCBPCK32: return 32;
        case EGW_AUDIO_TRFM_FCBPCK64: return 64;
        case EGW_AUDIO_TRFM_FCBPCK128: return 128;
        case EGW_AUDIO_TRFM_FCBPCK256: return 256;
        case EGW_AUDIO_TRFM_FCBPCK512: return 512;
        case EGW_AUDIO_TRFM_FCBPCK1024: return 1024;
        case EGW_AUDIO_TRFM_FCBPCK2048: return 2048;
        case EGW_AUDIO_TRFM_FCBPCK4096: return 4096;
        case EGW_AUDIO_TRFM_FCBPCK8192: return 8192;
        default: return dfltBPacking;
    }
}

egwAudio* egwAudioAlloc(egwAudio* audio_out, EGWuint32 format, EGWuint32 rate, EGWuint32 samples, EGWuint16 packingB) {
    if(audio_out && rate > 0 && samples > 0) {
        EGWuint bpc = (EGWuint)(format & EGW_AUDIO_FRMT_EXBPC);
        
        audio_out->format = format;
        audio_out->rate = rate;
        audio_out->pitch = (EGWuint32)(bpc >> 3) * (format & EGW_AUDIO_FRMT_EXMONO ? 1 : 2);
        if(packingB > 1)
            audio_out->pitch = egwRoundUpMultipleui32(audio_out->pitch, packingB);
        audio_out->count = samples;
        audio_out->length = (EGWtime)audio_out->count / (EGWtime)rate;
        
        if(!(audio_out->data = (EGWbyte*)malloc((size_t)audio_out->pitch * (size_t)audio_out->count)))
            return NULL;
        
        return audio_out;
    }
    
    return NULL;
}

egwAudio* egwAudioCopy(const egwAudio* audio_in, egwAudio* audio_out) {
    if(audio_in && audio_in->data && audio_out) {
        audio_out->format = audio_in->format;
        audio_out->rate = audio_in->rate;
        audio_out->pitch = audio_in->pitch;
        audio_out->count = audio_in->count;
        audio_out->length = audio_in->length;
        
        if(!(audio_out->data = (EGWbyte*)malloc((size_t)audio_out->pitch * (size_t)audio_out->count)))
            return NULL;
        
        memcpy((void*)audio_out->data, (const void*)audio_in->data, (size_t)audio_in->pitch * (size_t)audio_out->count);
        
        return audio_out;
    }
    
    return NULL;
}

egwAudio* egwAudioFree(egwAudio* audio_inout) {
    if(audio_inout->data)
        free((void*)audio_inout->data);
    memset((void*)audio_inout, 0, sizeof(egwAudio));
    
    return audio_inout;
}

egwAudio* egwAudioSwapLR(egwAudio* audio_inout) {
    if(audio_inout->format & EGW_AUDIO_FRMT_EXSTEREO) {
        egwStereoPCM sample;
        EGWint16 temp;
        EGWuintptr cScanline = (EGWuintptr)audio_inout->data;
        
        EGWuint count = audio_inout->count;
        while(count--) {
            egwPCMReadSb(audio_inout->format, (EGWbyte*)cScanline, &sample);
            temp = sample.channel.l;
            sample.channel.l = sample.channel.r;
            sample.channel.r = temp;
            egwPCMWriteSb(audio_inout->format, &sample, (EGWbyte*)cScanline);
            
            cScanline += (EGWuintptr)audio_inout->pitch;
        }
        
        return audio_inout;
    }
    
    return NULL;
}

egwAudio* egwAudioInvertSig(egwAudio* audio_inout) {
    EGWuintptr cScanline = (EGWuintptr)audio_inout->data;
    
    if(audio_inout->format & EGW_AUDIO_FRMT_EXSTEREO) {
        egwStereoPCM sample;
        
        EGWuint count = audio_inout->count;
        while(count--) {
            egwPCMReadSb(audio_inout->format, (EGWbyte*)cScanline, &sample);
            sample.channel.l = -sample.channel.l;
            sample.channel.r = -sample.channel.r;
            egwPCMWriteSb(audio_inout->format, &sample, (EGWbyte*)cScanline);
            
            cScanline += (EGWuintptr)audio_inout->pitch;
        }
    } else { // Mono
        egwMonoPCM sample;
        
        EGWuint count = audio_inout->count;
        while(count--) {
            egwPCMReadMb(audio_inout->format, (EGWbyte*)cScanline, &sample);
            sample.channel.m = 255 - sample.channel.m;
            egwPCMWriteMb(audio_inout->format, &sample, (EGWbyte*)cScanline);
            
            cScanline += (EGWuintptr)audio_inout->pitch;
        }
    }
    
    return audio_inout;
}

egwAudio* egwAudioReverseDir(egwAudio* audio_inout) {
    EGWuintptr lScanline = (EGWuintptr)audio_inout->data;
    EGWuintptr cScanline = (EGWuintptr)audio_inout->data + ((EGWuintptr)(audio_inout->count - 1) * (EGWuintptr)audio_inout->pitch);
    EGWuint Bps = ((EGWuint)(audio_inout->format & EGW_AUDIO_FRMT_EXBPC) * (audio_inout->format & EGW_AUDIO_FRMT_EXMONO ? 1 : 2)) >> 3;
    EGWbyte* lhsAdr = NULL;
    EGWbyte* rhsAdr = NULL;
    EGWbyte temp;
    
    EGWuint count = audio_inout->count >> 1;
    while(count--) {
        lhsAdr = (EGWbyte*)lScanline;
        rhsAdr = (EGWbyte*)cScanline;
        
        EGWuint bytes = Bps;
        while(bytes--) {
            temp = *lhsAdr;
            *lhsAdr = *rhsAdr;
            *rhsAdr = temp;
            
            lhsAdr = (EGWbyte*)((EGWuintptr)lhsAdr + 1);
            rhsAdr = (EGWbyte*)((EGWuintptr)rhsAdr + 1);
        }
        
        lScanline += (EGWuintptr)audio_inout->pitch;
        cScanline -= (EGWuintptr)audio_inout->pitch;
    }
    
    return audio_inout;
}

egwAudio* egwAudioConvert(EGWuint format, const egwAudio* audio_in, egwAudio* audio_out) {
    if(egwAudioAlloc(audio_out, format, audio_in->rate, audio_in->count, egwAudioPacking(audio_in))) {
        EGWuintptr lScanline = (EGWuintptr)audio_in->data;
        EGWuintptr cScanline = (EGWuintptr)audio_out->data;
        
        if(audio_in->format & EGW_AUDIO_FRMT_EXSTEREO) {
            egwStereoPCM sample;
            
            EGWuint count = audio_in->count;
            while(count--) {
                egwPCMReadSb(audio_out->format, (EGWbyte*)lScanline, &sample);
                egwPCMWriteSb(audio_out->format, &sample, (EGWbyte*)cScanline);
                
                lScanline += audio_in->pitch;
                cScanline += audio_out->pitch;
            }
            
            return audio_out;
        } else { // Mono
            egwMonoPCM sample;
            
            EGWuint count = audio_in->count;
            while(count--) {
                egwPCMReadMb(audio_out->format, (EGWbyte*)lScanline, &sample);
                egwPCMWriteMb(audio_out->format, &sample, (EGWbyte*)cScanline);
                
                lScanline += audio_in->pitch;
                cScanline += audio_out->pitch;
            }
            
            return audio_out;
        }
    }
    
    return NULL;
}

egwAudio* egwAudioRepack(EGWuint16 packingB, const egwAudio* audio_in, egwAudio* audio_out) {
    if(egwAudioAlloc(audio_out, audio_in->format, audio_in->rate, audio_in->count, packingB)) {
        EGWuintptr lScanline = (EGWuintptr)audio_in->data;
        EGWuintptr cScanline = (EGWuintptr)audio_out->data;
        EGWuint Bps = ((EGWuint)(audio_in->format & EGW_AUDIO_FRMT_EXBPC) * (audio_in->format & EGW_AUDIO_FRMT_EXMONO ? 1 : 2)) >> 3;
        
        EGWuint count = audio_in->count;
        while(count--) {
            memcpy((void*)cScanline, (const void*)lScanline, (size_t)Bps);
            
            lScanline += audio_in->pitch;
            cScanline += audio_out->pitch;
        }
        
        return audio_out;
    }
    
    return NULL;
}

EGWint16 egwAudioMaxSig(const egwAudio* audio_in) {
    EGWint16 maxSignal = EGW_INT16_MIN;
    EGWuintptr cScanline = (EGWuintptr)audio_in->data;
    
    if(audio_in->format & EGW_AUDIO_FRMT_EXSTEREO) {
        egwStereoPCM sample;
        
        EGWuint count = audio_in->count;
        while(count--) {
            egwPCMReadSb(audio_in->format, (EGWbyte*)cScanline, &sample);
            if(sample.channel.l > maxSignal) {
                maxSignal = sample.channel.l;
                
                if(maxSignal == EGW_INT16_MAX)
                    return maxSignal;
            }
            if(sample.channel.r > maxSignal) {
                maxSignal = sample.channel.r;
                
                if(maxSignal == EGW_INT16_MAX)
                    return maxSignal;
            }
            
            cScanline += (EGWuintptr)audio_in->pitch;
        }
    } else { // Mono
        egwMonoPCM sample;
        
        EGWuint count = audio_in->count;
        while(count--) {
            egwPCMReadMb(audio_in->format, (EGWbyte*)cScanline, &sample);
            if(sample.channel.m > maxSignal) {
                maxSignal = sample.channel.m;
                
                if(maxSignal == EGW_INT16_MAX)
                    return maxSignal;
            }
            
            cScanline += (EGWuintptr)audio_in->pitch;
        }
    }
    
    return maxSignal;
}

EGWint16 egwAudioMinSig(const egwAudio* audio_in) {
    EGWint16 minSignal = EGW_INT16_MAX;
    EGWuintptr cScanline = (EGWuintptr)audio_in->data;
    
    if(audio_in->format & EGW_AUDIO_FRMT_EXSTEREO) {
        egwStereoPCM sample;
        
        EGWuint count = audio_in->count;
        while(count--) {
            egwPCMReadSb(audio_in->format, (EGWbyte*)cScanline, &sample);
            if(sample.channel.l < minSignal) {
                minSignal = sample.channel.l;
                
                if(minSignal == EGW_INT16_MIN)
                    return minSignal;
            }
            if(sample.channel.r < minSignal) {
                minSignal = sample.channel.r;
                
                if(minSignal == EGW_INT16_MIN)
                    return minSignal;
            }
            
            cScanline += (EGWuintptr)audio_in->pitch;
        }
    } else { // Mono
        egwMonoPCM sample;
        
        EGWuint count = audio_in->count;
        while(count--) {
            egwPCMReadMb(audio_in->format, (EGWbyte*)cScanline, &sample);
            if(sample.channel.m < minSignal) {
                minSignal = sample.channel.m;
                
                if(minSignal == EGW_INT16_MIN)
                    return minSignal;
            }
            
            cScanline += (EGWuintptr)audio_in->pitch;
        }
    }
    
    return minSignal;
}

EGWint egwAudioPacking(const egwAudio* audio_in) {
    EGWuint bps = (audio_in->format & EGW_AUDIO_FRMT_EXBPC); // This is bpc, convert to bps
    if(audio_in->format & EGW_AUDIO_FRMT_EXSTEREO)
        bps *= 2;
    
    if(audio_in->pitch == (bps >> 3)) return 1;
    
    for(EGWint power = 2; power <= 8192; power *= 2) {
        if(audio_in->pitch == egwRoundUpMultipleui32(bps >> 3, power))
            return power;
    }
    
    return -1;
}

void egwPCMReadMb(EGWuint format, const EGWbyte* pcm_in, egwMonoPCM* val_out) {
    switch(format) {
        case EGW_AUDIO_FRMT_MONOU8: {
            val_out->channel.m = ((EGWint16)(*(EGWuint8*)pcm_in) - 128) * 256;
        } break;
        
        case EGW_AUDIO_FRMT_MONOS16: {
            val_out->channel.m = *(EGWint16*)pcm_in;
        } break;
        
        case EGW_AUDIO_FRMT_STEREOU8: {
            val_out->channel.m = (EGWint16)(((((EGWint)(*(EGWuint8*)(pcm_in+0)) - 128) * 256) + (((EGWint)(*(EGWuint8*)(pcm_in+1)) - 128) * 256)) / 2);
        } break;
        
        case EGW_AUDIO_FRMT_STEREOS16: {
            val_out->channel.m = (EGWint16)(((EGWint)*(EGWint16*)(pcm_in+0) + (EGWint)*(EGWint16*)(pcm_in+2)) / 2);
        } break;
    }
}

void egwPCMReadSb(EGWuint format, const EGWbyte* pcm_in, egwStereoPCM* val_out) {
    switch(format) {
        case EGW_AUDIO_FRMT_MONOU8: {
            val_out->channel.l = val_out->channel.r = ((EGWint16)(*(EGWuint8*)pcm_in) - 128) * 256;
        } break;
        
        case EGW_AUDIO_FRMT_MONOS16: {
            val_out->channel.l = val_out->channel.r = *(EGWint16*)pcm_in;
        } break;
        
        case EGW_AUDIO_FRMT_STEREOU8: {
            val_out->channel.l = ((EGWint16)(*(EGWuint8*)(pcm_in+0)) - 128) * 256;
            val_out->channel.r = ((EGWint16)(*(EGWuint8*)(pcm_in+1)) - 128) * 256;
        } break;
        
        case EGW_AUDIO_FRMT_STEREOS16: {
            val_out->channel.l = *(EGWint16*)(pcm_in+0);
            val_out->channel.r = *(EGWint16*)(pcm_in+2);
        } break;
    }
}

void egwPCMReadMbv(EGWuint format, const EGWbyte* pcms_in, egwMonoPCM* vals_out, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count) {
    switch(format) {
        case EGW_AUDIO_FRMT_MONOU8: {
            while(count--) {
                vals_out->channel.m = ((EGWint16)(*(EGWuint8*)pcms_in) - 128) * 256;
                
                pcms_in = (const EGWbyte*)((EGWintptr)pcms_in + (EGWintptr)(1 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwMonoPCM*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwMonoPCM) + strideB_out);
            }
        } break;
        
        case EGW_AUDIO_FRMT_MONOS16: {
            while(count--) {
                vals_out->channel.m = *(EGWint16*)pcms_in;
                
                pcms_in = (const EGWbyte*)((EGWintptr)pcms_in + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwMonoPCM*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwMonoPCM) + strideB_out);
            }
        } break;
        
        case EGW_AUDIO_FRMT_STEREOU8: {
            while(count--) {
                vals_out->channel.m = (EGWint16)(((((EGWint)(*(EGWuint8*)(pcms_in+0)) - 128) * 256) + (((EGWint)(*(EGWuint8*)(pcms_in+1)) - 128) * 256)) / 2);
                
                pcms_in = (const EGWbyte*)((EGWintptr)pcms_in + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwMonoPCM*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwMonoPCM) + strideB_out);
            }
        } break;
        
        case EGW_AUDIO_FRMT_STEREOS16: {
            while(count--) {
                vals_out->channel.m = (EGWint16)(((EGWint)*(EGWint16*)(pcms_in+0) + (EGWint)*(EGWint16*)(pcms_in+2)) / 2);
                
                pcms_in = (const EGWbyte*)((EGWintptr)pcms_in + (EGWintptr)(4 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwMonoPCM*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwMonoPCM) + strideB_out);
            }
        } break;
    }
}

void egwPCMReadSbv(EGWuint format, const EGWbyte* pcms_in, egwStereoPCM* vals_out, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count) {
    switch(format) {
        case EGW_AUDIO_FRMT_MONOU8: {
            while(count--) {
                vals_out->channel.l = vals_out->channel.r = ((EGWint16)(*(EGWuint8*)pcms_in) - 128) * 256;
                
                pcms_in = (const EGWbyte*)((EGWintptr)pcms_in + (EGWintptr)(1 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwStereoPCM*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwStereoPCM) + strideB_out);
            }
        } break;
        
        case EGW_AUDIO_FRMT_MONOS16: {
            while(count--) {
                vals_out->channel.l = vals_out->channel.r = *(EGWint16*)pcms_in;
                
                pcms_in = (const EGWbyte*)((EGWintptr)pcms_in + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwStereoPCM*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwStereoPCM) + strideB_out);
            }
        } break;
        
        case EGW_AUDIO_FRMT_STEREOU8: {
            while(count--) {
                vals_out->channel.l = ((EGWint16)(*(EGWuint8*)(pcms_in+0)) - 128) * 256;
                vals_out->channel.r = ((EGWint16)(*(EGWuint8*)(pcms_in+1)) - 128) * 256;
                
                pcms_in = (const EGWbyte*)((EGWintptr)pcms_in + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwStereoPCM*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwStereoPCM) + strideB_out);
            }
        } break;
        
        case EGW_AUDIO_FRMT_STEREOS16: {
            while(count--) {
                vals_out->channel.l = *(EGWint16*)(pcms_in+0);
                vals_out->channel.r = *(EGWint16*)(pcms_in+2);
                
                pcms_in = (const EGWbyte*)((EGWintptr)pcms_in + (EGWintptr)(4 * sizeof(EGWbyte)) + strideB_in);
                vals_out = (egwStereoPCM*)((EGWintptr)vals_out + (EGWintptr)sizeof(egwStereoPCM) + strideB_out);
            }
        } break;
    }
}

void egwPCMWriteMb(EGWuint format, const egwMonoPCM* val_in, EGWbyte* pcm_out) {
    switch(format) {
        case EGW_AUDIO_FRMT_MONOU8: {
            *(EGWuint8*)pcm_out = (EGWuint8)((val_in->channel.m / 256) + 128);
        } break;
        
        case EGW_AUDIO_FRMT_MONOS16: {
            *(EGWint16*)pcm_out = val_in->channel.m;
        } break;
        
        case EGW_AUDIO_FRMT_STEREOU8: {
            *(EGWuint8*)(pcm_out+0) = *(EGWuint8*)(pcm_out+1) = (EGWuint8)((val_in->channel.m / 256) + 128);
        } break;
        
        case EGW_AUDIO_FRMT_STEREOS16: {
            *(EGWint16*)(pcm_out+0) = *(EGWint16*)(pcm_out+2) = val_in->channel.m;
        } break;
    }
}

void egwPCMWriteSb(EGWuint format, const egwStereoPCM* val_in, EGWbyte* pcm_out) {
    switch(format) {
        case EGW_AUDIO_FRMT_MONOU8: {
            *(EGWuint8*)pcm_out = (EGWuint8)(((((EGWint)val_in->channel.l / 256) + 128) + (((EGWint)val_in->channel.r / 256) + 128)) / 2);
        } break;
        
        case EGW_AUDIO_FRMT_MONOS16: {
            *(EGWint16*)pcm_out = (EGWint16)(((EGWint)val_in->channel.l + (EGWint)val_in->channel.r) / 2);
        } break;
        
        case EGW_AUDIO_FRMT_STEREOU8: {
            *(EGWuint8*)(pcm_out+0) = (EGWuint8)((val_in->channel.l / 256) + 128);
            *(EGWuint8*)(pcm_out+1) = (EGWuint8)((val_in->channel.r / 256) + 128);
        } break;
        
        case EGW_AUDIO_FRMT_STEREOS16: {
            *(EGWint16*)(pcm_out+0) = val_in->channel.l;
            *(EGWint16*)(pcm_out+2) = val_in->channel.r;
        } break;
    }
}

void egwPCMWriteMbv(EGWuint format, const egwMonoPCM* vals_in, EGWbyte* pcms_out, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count) {
    switch(format) {
        case EGW_AUDIO_FRMT_MONOU8: {
            while(count--) {
                *(EGWuint8*)pcms_out = (EGWuint8)((vals_in->channel.m / 256) + 128);
                
                vals_in = (const egwMonoPCM*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwMonoPCM) + strideB_in);
                pcms_out = (EGWbyte*)((EGWintptr)pcms_out + (EGWintptr)(1 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        
        case EGW_AUDIO_FRMT_MONOS16: {
            while(count--) {
                *(EGWint16*)pcms_out = vals_in->channel.m;
                
                vals_in = (const egwMonoPCM*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwMonoPCM) + strideB_in);
                pcms_out = (EGWbyte*)((EGWintptr)pcms_out + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        
        case EGW_AUDIO_FRMT_STEREOU8: {
            while(count--) {
                *(EGWuint8*)(pcms_out+0) = *(EGWuint8*)(pcms_out+1) = (EGWuint8)((vals_in->channel.m / 256) + 128);
                
                vals_in = (const egwMonoPCM*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwMonoPCM) + strideB_in);
                pcms_out = (EGWbyte*)((EGWintptr)pcms_out + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        
        case EGW_AUDIO_FRMT_STEREOS16: {
            while(count--) {
                *(EGWint16*)(pcms_out+0) = *(EGWint16*)(pcms_out+2) = vals_in->channel.m;
                
                vals_in = (const egwMonoPCM*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwMonoPCM) + strideB_in);
                pcms_out = (EGWbyte*)((EGWintptr)pcms_out + (EGWintptr)(4 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
    }
}

void egwPCMWriteSbv(EGWuint format, const egwStereoPCM* vals_in, EGWbyte* pcms_out, EGWintptr strideB_in, EGWintptr strideB_out, EGWuint count) {
    switch(format) {
        case EGW_AUDIO_FRMT_MONOU8: {
            while(count--) {
                *(EGWuint8*)pcms_out = (EGWuint8)(((((EGWint)vals_in->channel.l / 256) + 128) + (((EGWint)vals_in->channel.r / 256) + 128)) / 2);
                
                vals_in = (const egwStereoPCM*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwStereoPCM) + strideB_in);
                pcms_out = (EGWbyte*)((EGWintptr)pcms_out + (EGWintptr)(1 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        
        case EGW_AUDIO_FRMT_MONOS16: {
            while(count--) {
                *(EGWint16*)pcms_out = (EGWint16)(((EGWint)vals_in->channel.l + (EGWint)vals_in->channel.r) / 2);
                
                vals_in = (const egwStereoPCM*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwStereoPCM) + strideB_in);
                pcms_out = (EGWbyte*)((EGWintptr)pcms_out + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        
        case EGW_AUDIO_FRMT_STEREOU8: {
            while(count--) {
                *(EGWuint8*)(pcms_out+0) = (EGWuint8)((vals_in->channel.l / 256) + 128);
                *(EGWuint8*)(pcms_out+1) = (EGWuint8)((vals_in->channel.r / 256) + 128);
                
                vals_in = (const egwStereoPCM*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwStereoPCM) + strideB_in);
                pcms_out = (EGWbyte*)((EGWintptr)pcms_out + (EGWintptr)(2 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
        
        case EGW_AUDIO_FRMT_STEREOS16: {
            while(count--) {
                *(EGWint16*)(pcms_out+0) = vals_in->channel.l;
                *(EGWint16*)(pcms_out+2) = vals_in->channel.r;
                
                vals_in = (const egwStereoPCM*)((EGWintptr)vals_in + (EGWintptr)sizeof(egwStereoPCM) + strideB_in);
                pcms_out = (EGWbyte*)((EGWintptr)pcms_out + (EGWintptr)(4 * sizeof(EGWbyte)) + strideB_out);
            }
        } break;
    }
}

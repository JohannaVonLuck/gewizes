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

/// @file egwPhysics.m
/// @ingroup geWizES_phy_physics
/// Base Physics Implementation.

#import <math.h>
#import "egwPhysics.h"
#import "../math/egwMath.h"
#import "../math/egwVector.h"
#import "../math/egwMatrix.h"

EGWiepofuncfp egwIpoRoutine(EGWuint chnFormat_in, EGWuint32 polationMode_in) {
    switch(polationMode_in & EGW_POLATION_EXINTER) {
        case EGW_POLATION_IPO_CONST: {
            switch(chnFormat_in) {
                case EGW_KEYCHANNEL_FRMT_INT8:   return (EGWiepofuncfp)&egwIpoSteppedi8;
                case EGW_KEYCHANNEL_FRMT_UINT8:  return (EGWiepofuncfp)&egwIpoSteppedui8;
                case EGW_KEYCHANNEL_FRMT_INT16:  return (EGWiepofuncfp)&egwIpoSteppedi16;
                case EGW_KEYCHANNEL_FRMT_UINT16: return (EGWiepofuncfp)&egwIpoSteppedui16;
                case EGW_KEYCHANNEL_FRMT_INT32:  return (EGWiepofuncfp)&egwIpoSteppedi32;
                case EGW_KEYCHANNEL_FRMT_UINT32: return (EGWiepofuncfp)&egwIpoSteppedui32;
                case EGW_KEYCHANNEL_FRMT_SINGLE: return (EGWiepofuncfp)&egwIpoSteppedf;
                case EGW_KEYCHANNEL_FRMT_DOUBLE: return (EGWiepofuncfp)&egwIpoSteppedd;
                case EGW_KEYCHANNEL_FRMT_TRIPLE: return (EGWiepofuncfp)&egwIpoSteppedt;
            }
        } break;
        case EGW_POLATION_IPO_LINEAR: {
            switch(chnFormat_in) {
                case EGW_KEYCHANNEL_FRMT_INT8:   return (EGWiepofuncfp)&egwIpoLineari8;
                case EGW_KEYCHANNEL_FRMT_UINT8:  return (EGWiepofuncfp)&egwIpoLinearui8;
                case EGW_KEYCHANNEL_FRMT_INT16:  return (EGWiepofuncfp)&egwIpoLineari16;
                case EGW_KEYCHANNEL_FRMT_UINT16: return (EGWiepofuncfp)&egwIpoLinearui16;
                case EGW_KEYCHANNEL_FRMT_INT32:  return (EGWiepofuncfp)&egwIpoLineari32;
                case EGW_KEYCHANNEL_FRMT_UINT32: return (EGWiepofuncfp)&egwIpoLinearui32;
                case EGW_KEYCHANNEL_FRMT_SINGLE: return (EGWiepofuncfp)&egwIpoLinearf;
                case EGW_KEYCHANNEL_FRMT_DOUBLE: return (EGWiepofuncfp)&egwIpoLineard;
                case EGW_KEYCHANNEL_FRMT_TRIPLE: return (EGWiepofuncfp)&egwIpoLineart;
            }
        } break;
        case EGW_POLATION_IPO_SLERP: {
            switch(chnFormat_in) {
                case EGW_KEYCHANNEL_FRMT_INT8:   return (EGWiepofuncfp)NULL;
                case EGW_KEYCHANNEL_FRMT_UINT8:  return (EGWiepofuncfp)NULL;
                case EGW_KEYCHANNEL_FRMT_INT16:  return (EGWiepofuncfp)NULL;
                case EGW_KEYCHANNEL_FRMT_UINT16: return (EGWiepofuncfp)NULL;
                case EGW_KEYCHANNEL_FRMT_INT32:  return (EGWiepofuncfp)NULL;
                case EGW_KEYCHANNEL_FRMT_UINT32: return (EGWiepofuncfp)NULL;
                case EGW_KEYCHANNEL_FRMT_SINGLE: return (EGWiepofuncfp)&egwIpoSlerpf;
                case EGW_KEYCHANNEL_FRMT_DOUBLE: return (EGWiepofuncfp)&egwIpoSlerpd;
                case EGW_KEYCHANNEL_FRMT_TRIPLE: return (EGWiepofuncfp)&egwIpoSlerpt;
            }
        } break;
        case EGW_POLATION_IPO_CUBICCR: {
            switch(chnFormat_in) {
                case EGW_KEYCHANNEL_FRMT_INT8:   return (EGWiepofuncfp)NULL;
                case EGW_KEYCHANNEL_FRMT_UINT8:  return (EGWiepofuncfp)NULL;
                case EGW_KEYCHANNEL_FRMT_INT16:  return (EGWiepofuncfp)NULL;
                case EGW_KEYCHANNEL_FRMT_UINT16: return (EGWiepofuncfp)NULL;
                case EGW_KEYCHANNEL_FRMT_INT32:  return (EGWiepofuncfp)NULL;
                case EGW_KEYCHANNEL_FRMT_UINT32: return (EGWiepofuncfp)NULL;
                case EGW_KEYCHANNEL_FRMT_SINGLE: return (EGWiepofuncfp)&egwIpoCubicCRf;
                case EGW_KEYCHANNEL_FRMT_DOUBLE: return (EGWiepofuncfp)&egwIpoCubicCRd;
                case EGW_KEYCHANNEL_FRMT_TRIPLE: return (EGWiepofuncfp)&egwIpoCubicCRt;
            }
        } break;
    }
    
    return NULL;
}

EGWcefdfuncfp egwIpoCreateExtFrmDatRoutine(EGWuint chnFormat_in, EGWuint32 polationMode_in) {
    if((polationMode_in & EGW_POLATION_EXINTER) == EGW_POLATION_IPO_SLERP && chnFormat_in == EGW_KEYCHANNEL_FRMT_SINGLE)
        return (EGWcefdfuncfp)&egwIpoSlerpCreateExtFrmDatf;
    else if((polationMode_in & EGW_POLATION_EXINTER) == EGW_POLATION_IPO_SLERP && chnFormat_in == EGW_KEYCHANNEL_FRMT_DOUBLE)
        return (EGWcefdfuncfp)&egwIpoSlerpCreateExtFrmDatd;
    else if((polationMode_in & EGW_POLATION_EXINTER) == EGW_POLATION_IPO_SLERP && chnFormat_in == EGW_KEYCHANNEL_FRMT_TRIPLE)
        return (EGWcefdfuncfp)&egwIpoSlerpCreateExtFrmDatt;
    return NULL;
}

EGWuint egwIpoExtFrmDatFrmPitch(EGWuint chnFormat_in, EGWuint chnCount_in, EGWuint cmpCount_in, EGWuint32 polationMode_in) {
    if((polationMode_in & EGW_POLATION_EXINTER) == EGW_POLATION_IPO_SLERP && chnFormat_in == EGW_KEYCHANNEL_FRMT_SINGLE)
        return (EGWuint32)sizeof(EGWsingle) * 3 * cmpCount_in;
    else if((polationMode_in & EGW_POLATION_EXINTER) == EGW_POLATION_IPO_SLERP && chnFormat_in == EGW_KEYCHANNEL_FRMT_DOUBLE)
        return (EGWuint32)sizeof(EGWdouble) * 3 * cmpCount_in;
    else if((polationMode_in & EGW_POLATION_EXINTER) == EGW_POLATION_IPO_SLERP && chnFormat_in == EGW_KEYCHANNEL_FRMT_TRIPLE)
        return (EGWuint32)sizeof(EGWtriple) * 3 * cmpCount_in;
    return 0;
}

EGWuint egwIpoExtFrmDatCmpPitch(EGWuint chnFormat_in, EGWuint chnCount_in, EGWuint32 polationMode_in) {
    if((polationMode_in & EGW_POLATION_EXINTER) == EGW_POLATION_IPO_SLERP && chnFormat_in == EGW_KEYCHANNEL_FRMT_SINGLE)
        return (EGWuint32)sizeof(EGWsingle) * 3;
    else if((polationMode_in & EGW_POLATION_EXINTER) == EGW_POLATION_IPO_SLERP && chnFormat_in == EGW_KEYCHANNEL_FRMT_DOUBLE)
        return (EGWuint32)sizeof(EGWdouble) * 3;
    else if((polationMode_in & EGW_POLATION_EXINTER) == EGW_POLATION_IPO_SLERP && chnFormat_in == EGW_KEYCHANNEL_FRMT_TRIPLE)
        return (EGWuint32)sizeof(EGWtriple) * 3;
    return 0;
}

void egwIpoSteppedi8(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWint8* result_out) {
    EGWuintptr fdOffset = 0;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWint8* frmData = (const EGWint8*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = *frmData;
            frmData = (const EGWint8*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWint8));
            result_out = (EGWint8*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWint8));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwIpoSteppedui8(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWuint8* result_out) {
    EGWuintptr fdOffset = 0;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWuint8* frmData = (const EGWuint8*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = *frmData;
            frmData = (const EGWuint8*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWuint8));
            result_out = (EGWuint8*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWuint8));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwIpoSteppedi16(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWint16* result_out) {
    EGWuintptr fdOffset = 0;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWint16* frmData = (const EGWint16*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = *frmData;
            frmData = (const EGWint16*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWint16));
            result_out = (EGWint16*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWint16));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwIpoSteppedui16(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWuint16* result_out) {
    EGWuintptr fdOffset = 0;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWuint16* frmData = (const EGWuint16*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = *frmData;
            frmData = (const EGWuint16*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWuint16));
            result_out = (EGWuint16*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWuint16));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwIpoSteppedi32(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWint32* result_out) {
    EGWuintptr fdOffset = 0;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWint32* frmData = (const EGWint32*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = *frmData;
            frmData = (const EGWint32*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWint32));
            result_out = (EGWint32*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWint32));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwIpoSteppedui32(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWuint32* result_out) {
    EGWuintptr fdOffset = 0;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWuint32* frmData = (const EGWuint32*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = *frmData;
            frmData = (const EGWuint32*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWuint32));
            result_out = (EGWuint32*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWuint32));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwIpoSteppedf(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWsingle* result_out) {
    EGWuintptr fdOffset = 0;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWsingle* frmData = (const EGWsingle*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = *frmData;
            frmData = (const EGWsingle*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWsingle));
            result_out = (EGWsingle*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWsingle));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwIpoSteppedd(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWdouble* result_out) {
    EGWuintptr fdOffset = 0;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWdouble* frmData = (const EGWdouble*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = *frmData;
            frmData = (const EGWdouble*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWdouble));
            result_out = (EGWdouble*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWdouble));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwIpoSteppedt(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWtriple* result_out) {
    EGWuintptr fdOffset = 0;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWtriple* frmData = (const EGWtriple*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = *frmData;
            frmData = (const EGWtriple*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWtriple));
            result_out = (EGWtriple*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWtriple));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwIpoLineari8(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWint8* result_out) {
    EGWuintptr fdOffset = 0;
    const EGWtime theta = (absT_in - line_in->otIndicie[0]) / (line_in->otIndicie[1] - line_in->otIndicie[0]);
    const EGWint sigma = (EGWint)(theta * (EGWtime)10000.0f);
    const EGWint opsSigma = 10000 - sigma;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWint8* frmData = (const EGWint8*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = (EGWint8)((((EGWint)(*frmData) * opsSigma) + ((EGWint)(*(EGWint8*)((EGWuintptr)frmData + line_in->fdPitch)) * sigma)) / (EGWint)10000);
            frmData = (const EGWint8*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWint8));
            result_out = (EGWint8*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWint8));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwIpoLinearui8(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWuint8* result_out) {
    EGWuintptr fdOffset = 0;
    const EGWtime theta = (absT_in - line_in->otIndicie[0]) / (line_in->otIndicie[1] - line_in->otIndicie[0]);
    const EGWuint sigma = (EGWuint)(theta * (EGWtime)10000.0f);
    const EGWuint opsSigma = 10000 - sigma;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWuint8* frmData = (const EGWuint8*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = (EGWuint8)((((EGWuint)(*frmData) * opsSigma) + ((EGWuint)(*(EGWuint8*)((EGWuintptr)frmData + line_in->fdPitch)) * sigma)) / (EGWuint)10000);
            frmData = (const EGWuint8*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWuint8));
            result_out = (EGWuint8*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWuint8));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwIpoLineari16(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWint16* result_out) {
    EGWuintptr fdOffset = 0;
    const EGWtime theta = (absT_in - line_in->otIndicie[0]) / (line_in->otIndicie[1] - line_in->otIndicie[0]);
    const EGWint sigma = (EGWint)(theta * (EGWtime)10000.0f);
    const EGWint opsSigma = 10000 - sigma;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWint16* frmData = (const EGWint16*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = (EGWint16)((((EGWint)(*frmData) * opsSigma) + ((EGWint)(*(EGWint16*)((EGWuintptr)frmData + line_in->fdPitch)) * sigma)) / (EGWint)10000);
            frmData = (const EGWint16*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWint16));
            result_out = (EGWint16*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWint16));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwIpoLinearui16(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWuint16* result_out) {
    EGWuintptr fdOffset = 0;
    const EGWtime theta = (absT_in - line_in->otIndicie[0]) / (line_in->otIndicie[1] - line_in->otIndicie[0]);
    const EGWuint sigma = (EGWuint)(theta * (EGWtime)10000.0f);
    const EGWuint opsSigma = 10000 - sigma;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWuint16* frmData = (const EGWuint16*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = (EGWuint16)((((EGWuint)(*frmData) * opsSigma) + ((EGWuint)(*(EGWuint16*)((EGWuintptr)frmData + line_in->fdPitch)) * sigma)) / (EGWuint)10000);
            frmData = (const EGWuint16*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWuint16));
            result_out = (EGWuint16*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWuint16));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwIpoLineari32(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWint32* result_out) {
    EGWuintptr fdOffset = 0;
    const EGWtime theta = (absT_in - line_in->otIndicie[0]) / (line_in->otIndicie[1] - line_in->otIndicie[0]);
    const EGWint64 sigma = (EGWint64)(theta * (EGWtime)10000.0f);
    const EGWint64 opsSigma = 10000 - sigma;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWint32* frmData = (const EGWint32*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = (EGWint32)((((EGWint64)(*frmData) * opsSigma) + ((EGWint64)(*(EGWint32*)((EGWuintptr)frmData + line_in->fdPitch)) * sigma)) / (EGWint64)10000);
            frmData = (const EGWint32*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWint32));
            result_out = (EGWint32*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWint32));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwIpoLinearui32(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWuint32* result_out) {
    EGWuintptr fdOffset = 0;
    const EGWtime theta = (absT_in - line_in->otIndicie[0]) / (line_in->otIndicie[1] - line_in->otIndicie[0]);
    const EGWuint64 sigma = (EGWuint64)(theta * (EGWtime)10000.0f);
    const EGWuint64 opsSigma = 10000 - sigma;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWuint32* frmData = (const EGWuint32*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = (EGWuint32)((((EGWuint64)(*frmData) * opsSigma) + ((EGWuint64)(*(EGWuint32*)((EGWuintptr)frmData + line_in->fdPitch)) * sigma)) / (EGWuint64)10000);
            frmData = (const EGWuint32*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWuint32));
            result_out = (EGWuint32*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWuint32));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwIpoLinearf(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWsingle* result_out) {
    EGWuintptr fdOffset = 0;
    const EGWtime theta = (absT_in - line_in->otIndicie[0]) / (line_in->otIndicie[1] - line_in->otIndicie[0]);
    const EGWtime opsTheta = 1.0 - theta;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWsingle* frmData = (const EGWsingle*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = ((*frmData) * (EGWsingle)opsTheta) + ((*(const EGWsingle*)((EGWuintptr)frmData + line_in->fdPitch)) * (EGWsingle)theta);
            frmData = (const EGWsingle*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWsingle));
            result_out = (EGWsingle*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWsingle));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwIpoLineard(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWdouble* result_out) {
    EGWuintptr fdOffset = 0;
    const EGWtime theta = (absT_in - line_in->otIndicie[0]) / (line_in->otIndicie[1] - line_in->otIndicie[0]);
    const EGWtime opsTheta = 1.0 - theta;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWdouble* frmData = (const EGWdouble*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = ((*frmData) * (EGWdouble)opsTheta) + ((*(const EGWdouble*)((EGWuintptr)frmData + line_in->fdPitch)) * (EGWdouble)theta);
            frmData = (const EGWdouble*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWdouble));
            result_out = (EGWdouble*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWdouble));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwIpoLineart(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWtriple* result_out) {
    EGWuintptr fdOffset = 0;
    const EGWtime theta = (absT_in - line_in->otIndicie[0]) / (line_in->otIndicie[1] - line_in->otIndicie[0]);
    const EGWtime opsTheta = 1.0 - theta;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWtriple* frmData = (const EGWtriple*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = ((*frmData) * (EGWtriple)opsTheta) + ((*(const EGWtriple*)((EGWuintptr)frmData + line_in->fdPitch)) * (EGWtriple)theta);
            frmData = (const EGWtriple*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWtriple));
            result_out = (EGWtriple*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWtriple));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwIpoSlerpCreateExtFrmDatf(const EGWsingle* keyData_in, EGWsingle* extraData_out, const EGWuint cmpntPitch_in, const EGWuint framePitch_in, const EGWuint exDatCmpntPitch_out, const EGWuint exDatFramePitch_out, EGWuint frameCount, EGWuint cmpCount, EGWuint chnCount) {
    EGWuintptr fdOffset = 0;
    EGWuintptr efdOffset = 0;
    
    EGWuint frmCnt = frameCount; while(frmCnt--) {
        EGWuintptr cdOffset = 0;
        EGWuintptr ecdOffset = 0;
        
        if(frmCnt) {
            EGWuint cmpCnt = cmpCount; while(cmpCnt--) {
                const EGWsingle* keyData = (const EGWsingle*)((EGWuintptr)keyData_in + fdOffset + cdOffset);
                const EGWsingle* keyDataNext = (const EGWsingle*)((EGWuintptr)keyData_in + fdOffset + cdOffset + framePitch_in);
                EGWsingle* keyExtra = (EGWsingle*)((EGWuintptr)extraData_out + efdOffset + ecdOffset);
                
                // Get the normalization multiplier (to make vector normal) for both vectors
                EGWsingle nrmMlt = 0.0f;
                EGWsingle nrmNextMlt = 0.0f;
                
                for(EGWuint kcIndex = 0; kcIndex < chnCount; ++kcIndex) {
                    nrmMlt += keyData[kcIndex] * keyData[kcIndex];
                    nrmNextMlt += keyDataNext[kcIndex] * keyDataNext[kcIndex];
                }
                
                nrmMlt = egwInvSqrtf(nrmMlt);
                nrmNextMlt = egwInvSqrtf(nrmNextMlt);
                
                EGWsingle dotProd = 0.0f;
                // Calculate the dot product between both normalized vectors
                for(EGWuint kcIndex = 0; kcIndex < chnCount; ++kcIndex)
                    dotProd += (keyData[kcIndex] * nrmMlt) * (keyDataNext[kcIndex] * nrmNextMlt);
                
                // If dot product is negative, then a long route is being taken, mark inverse multiplier
                if(dotProd >= 0.0f) {
                    keyExtra[0] = 1.0f;
                } else {
                    dotProd = -dotProd;
                    keyExtra[0] = -1.0f;
                }
                
                if(dotProd < 1.0f - EGW_SFLT_EPSILON) {
                    // Arc cosine of dot product of two normal vectors is the angle
                    keyExtra[1] = egwArcCosf(dotProd);
                    
                    // Other value is just the inverse sin of the angle
                    keyExtra[2] = 1.0f / egwSinf(keyExtra[1]);
                } else { // No rotation, do this to prevent nan
                    keyExtra[0] = keyExtra[1] = keyExtra[2] = 0.0f;
                }
                
                cdOffset += cmpntPitch_in;
                ecdOffset += exDatCmpntPitch_out;
            }
        } else { // Last value isn't ever used (or at least never should be)
            EGWuint cmpCnt = cmpCount; while(cmpCnt--) {
                EGWsingle* keyExtra = (EGWsingle*)((EGWuintptr)extraData_out + efdOffset + ecdOffset);
                
                keyExtra[0] = keyExtra[1] = keyExtra[2] = 0.0f;
                
                cdOffset += cmpntPitch_in;
                ecdOffset += exDatCmpntPitch_out;
            }
        }
        
        fdOffset += framePitch_in;
        efdOffset += exDatFramePitch_out;
    }
}

void egwIpoSlerpCreateExtFrmDatd(const EGWdouble* keyData_in, EGWdouble* extraData_out, const EGWuint cmpntPitch_in, const EGWuint framePitch_in, const EGWuint exDatCmpntPitch_out, const EGWuint exDatFramePitch_out, EGWuint frameCount, EGWuint cmpCount, EGWuint chnCount) {
    EGWuintptr fdOffset = 0;
    EGWuintptr efdOffset = 0;
    
    EGWuint frmCnt = frameCount; while(frmCnt--) {
        EGWuintptr cdOffset = 0;
        EGWuintptr ecdOffset = 0;
        
        if(frmCnt) {
            EGWuint cmpCnt = cmpCount; while(cmpCnt--) {
                const EGWdouble* keyData = (const EGWdouble*)((EGWuintptr)keyData_in + fdOffset + cdOffset);
                const EGWdouble* keyDataNext = (const EGWdouble*)((EGWuintptr)keyData_in + fdOffset + cdOffset + framePitch_in);
                EGWdouble* keyExtra = (EGWdouble*)((EGWuintptr)extraData_out + efdOffset + ecdOffset);
                
                // Get the normalization multiplier (to make vector normal) for both vectors
                EGWdouble nrmMlt = 0.0;
                EGWdouble nrmNextMlt = 0.0;
                
                for(EGWuint kcIndex = 0; kcIndex < chnCount; ++kcIndex) {
                    nrmMlt += keyData[kcIndex] * keyData[kcIndex];
                    nrmNextMlt += keyDataNext[kcIndex] * keyDataNext[kcIndex];
                }
                
                nrmMlt = egwInvSqrtd(nrmMlt);
                nrmNextMlt = egwInvSqrtd(nrmNextMlt);
                
                EGWdouble dotProd = 0.0;
                // Calculate the dot product between both normalized vectors
                for(EGWuint kcIndex = 0; kcIndex < chnCount; ++kcIndex)
                    dotProd += (keyData[kcIndex] * nrmMlt) * (keyDataNext[kcIndex] * nrmNextMlt);
                
                // If dot product is negative, then a long route is being taken, mark inverse multiplier
                if(dotProd >= 0.0) {
                    keyExtra[0] = 1.0;
                } else {
                    dotProd = -dotProd;
                    keyExtra[0] = -1.0;
                }
                
                if(dotProd < 1.0 - EGW_DFLT_EPSILON) {
                    // Arc cosine of dot product of two normal vectors is the angle
                    keyExtra[1] = egwArcCosd(dotProd);
                    
                    // Other value is just the inverse sin of the angle
                    keyExtra[2] = 1.0 / egwSind(keyExtra[1]);
                } else { // No rotation, do this to prevent nan
                    keyExtra[0] = keyExtra[1] = keyExtra[2] = 0.0;
                }
                
                cdOffset += cmpntPitch_in;
                ecdOffset += exDatCmpntPitch_out;
            }
        } else { // Last value isn't ever used (or at least never should be)
            EGWuint cmpCnt = cmpCount; while(cmpCnt--) {
                EGWdouble* keyExtra = (EGWdouble*)((EGWuintptr)extraData_out + efdOffset + ecdOffset);
                
                keyExtra[0] = keyExtra[1] = keyExtra[2] = 0.0;
                
                cdOffset += cmpntPitch_in;
                ecdOffset += exDatCmpntPitch_out;
            }
        }
        
        fdOffset += framePitch_in;
        efdOffset += exDatFramePitch_out;
    }
}

void egwIpoSlerpCreateExtFrmDatt(const EGWtriple* keyData_in, EGWtriple* extraData_out, const EGWuint cmpntPitch_in, const EGWuint framePitch_in, const EGWuint exDatCmpntPitch_out, const EGWuint exDatFramePitch_out, EGWuint frameCount, EGWuint cmpCount, EGWuint chnCount) {
    EGWuintptr fdOffset = 0;
    EGWuintptr efdOffset = 0;
    
    EGWuint frmCnt = frameCount; while(frmCnt--) {
        EGWuintptr cdOffset = 0;
        EGWuintptr ecdOffset = 0;
        
        if(frmCnt) {
            EGWuint cmpCnt = cmpCount; while(cmpCnt--) {
                const EGWtriple* keyData = (const EGWtriple*)((EGWuintptr)keyData_in + fdOffset + cdOffset);
                const EGWtriple* keyDataNext = (const EGWtriple*)((EGWuintptr)keyData_in + fdOffset + cdOffset + framePitch_in);
                EGWtriple* keyExtra = (EGWtriple*)((EGWuintptr)extraData_out + efdOffset + ecdOffset);
                
                // Get the normalization multiplier (to make vector normal) for both vectors
                EGWtriple nrmMlt = (EGWtriple)0.0;
                EGWtriple nrmNextMlt = (EGWtriple)0.0;
                
                for(EGWuint kcIndex = 0; kcIndex < chnCount; ++kcIndex) {
                    nrmMlt += keyData[kcIndex] * keyData[kcIndex];
                    nrmNextMlt += keyDataNext[kcIndex] * keyDataNext[kcIndex];
                }
                
                nrmMlt = egwInvSqrtt(nrmMlt);
                nrmNextMlt = egwInvSqrtt(nrmNextMlt);
                
                EGWtriple dotProd = (EGWtriple)0.0;
                // Calculate the dot product between both normalized vectors
                for(EGWuint kcIndex = 0; kcIndex < chnCount; ++kcIndex)
                    dotProd += (keyData[kcIndex] * nrmMlt) * (keyDataNext[kcIndex] * nrmNextMlt);
                
                // If dot product is negative, then a long route is being taken, mark inverse multiplier
                if(dotProd >= (EGWtriple)0.0) {
                    keyExtra[0] = (EGWtriple)1.0;
                } else {
                    dotProd = -dotProd;
                    keyExtra[0] = -(EGWtriple)1.0;
                }
                
                if(dotProd < (EGWtriple)1.0 - EGW_TFLT_EPSILON) {
                    // Arc cosine of dot product of two normal vectors is the angle
                    keyExtra[1] = egwArcCost(dotProd);
                    
                    // Other value is just the inverse sin of the angle
                    keyExtra[2] = (EGWtriple)1.0 / egwSint(keyExtra[1]);
                } else { // No rotation, do this to prevent nan
                    keyExtra[0] = keyExtra[1] = keyExtra[2] = (EGWtriple)0.0;
                }
                
                cdOffset += cmpntPitch_in;
                ecdOffset += exDatCmpntPitch_out;
            }
        } else { // Last value isn't ever used (or at least never should be)
            EGWuint cmpCnt = cmpCount; while(cmpCnt--) {
                EGWtriple* keyExtra = (EGWtriple*)((EGWuintptr)extraData_out + efdOffset + ecdOffset);
                
                keyExtra[0] = keyExtra[1] = keyExtra[2] = (EGWtriple)0.0;
                
                cdOffset += cmpntPitch_in;
                ecdOffset += exDatCmpntPitch_out;
            }
        }
        
        fdOffset += framePitch_in;
        efdOffset += exDatFramePitch_out;
    }
}

void egwIpoSlerpf(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWsingle* result_out) {
    EGWuintptr fdOffset = 0;
    EGWuintptr efdOffset = 0;
    const EGWtime theta = (absT_in - line_in->otIndicie[0]) / (line_in->otIndicie[1] - line_in->otIndicie[0]);
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWsingle* frmData = (const EGWsingle*)((EGWuintptr)line_in->okFrame + fdOffset);
        const EGWsingle* extData = (const EGWsingle*)((EGWuintptr)line_in->okfExtraDat + efdOffset);
        
        if(extData[2] > 0.0f) {
            const EGWsingle sigma = extData[0] * egwSinf((EGWsingle)(1.0 - theta) * extData[1]) * extData[2];
            const EGWsingle opsSigma = egwSinf((EGWsingle)theta * extData[1]) * extData[2];
            
            EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
                *result_out = ((*frmData) * sigma) + ((*(const EGWsingle*)((EGWuintptr)frmData + line_in->fdPitch)) * opsSigma);
                frmData = (const EGWsingle*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWsingle));
                result_out = (EGWsingle*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWsingle));
            }
        } else { // No rotation
            EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
                *result_out = *frmData;
                frmData = (const EGWsingle*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWsingle));
                result_out = (EGWsingle*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWsingle));
            }
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
        efdOffset += (EGWuintptr)line_in->ecdPitch;
    }
}

void egwIpoSlerpd(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWdouble* result_out) {
    EGWuintptr fdOffset = 0;
    EGWuintptr efdOffset = 0;
    const EGWtime theta = (absT_in - line_in->otIndicie[0]) / (line_in->otIndicie[1] - line_in->otIndicie[0]);
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWdouble* frmData = (const EGWdouble*)((EGWuintptr)line_in->okFrame + fdOffset);
        const EGWdouble* extData = (const EGWdouble*)((EGWuintptr)line_in->okfExtraDat + efdOffset);
        
        if(extData[2] > 0.0) {
            const EGWdouble sigma = extData[0] * egwSind((EGWdouble)(1.0 - theta) * extData[1]) * extData[2];
            const EGWdouble opsSigma = egwSind((EGWdouble)theta * extData[1]) * extData[2];
            
            EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
                *result_out = ((*frmData) * sigma) + ((*(const EGWdouble*)((EGWuintptr)frmData + line_in->fdPitch)) * opsSigma);
                frmData = (const EGWdouble*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWdouble));
                result_out = (EGWdouble*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWdouble));
            }
        } else { // No rotation
            EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
                *result_out = *frmData;
                frmData = (const EGWdouble*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWdouble));
                result_out = (EGWdouble*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWdouble));
            }
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
        efdOffset += (EGWuintptr)line_in->ecdPitch;
    }
}

void egwIpoSlerpt(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWtriple* result_out) {
    EGWuintptr fdOffset = 0;
    EGWuintptr efdOffset = 0;
    const EGWtime theta = (absT_in - line_in->otIndicie[0]) / (line_in->otIndicie[1] - line_in->otIndicie[0]);
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWtriple* frmData = (const EGWtriple*)((EGWuintptr)line_in->okFrame + fdOffset);
        const EGWtriple* extData = (const EGWtriple*)((EGWuintptr)line_in->okfExtraDat + efdOffset);
        
        if(extData[2] > (EGWtriple)0.0) {
            const EGWtriple sigma = extData[0] * egwSint((EGWtriple)(1.0 - theta) * extData[1]) * extData[2];
            const EGWtriple opsSigma = egwSint((EGWtriple)theta * extData[1]) * extData[2];
            
            EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
                *result_out = ((*frmData) * sigma) + ((*(const EGWtriple*)((EGWuintptr)frmData + line_in->fdPitch)) * opsSigma);
                frmData = (const EGWtriple*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWtriple));
                result_out = (EGWtriple*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWtriple));
            }
        } else { // No rotation
            EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
                *result_out = *frmData;
                frmData = (const EGWtriple*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWtriple));
                result_out = (EGWtriple*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWtriple));
            }
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
        efdOffset += (EGWuintptr)line_in->ecdPitch;
    }
}

void egwIpoCubicCRf(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWsingle* result_out) {
    EGWuintptr fdOffset = 0;
    const EGWuintptr pitch2 = line_in->fdPitch + line_in->fdPitch;
    const EGWuintptr pitch3 = pitch2 + line_in->fdPitch;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWsingle* frmData = (const EGWsingle*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        if(absT_in >= line_in->otIndicie[1] - EGW_TIME_EPSILON) { // knot index = 1 or 2
            if(absT_in <= line_in->otIndicie[2] + EGW_TIME_EPSILON) { // knot index = 1
                EGWsingle theta = (EGWsingle)(absT_in - line_in->otIndicie[1]) / (EGWsingle)(line_in->otIndicie[2] - line_in->otIndicie[1]);
                EGWsingle thetaSqrd = theta * theta;
                EGWsingle thetaCubed = thetaSqrd * theta;
                
                EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
                    *result_out = 0.5f * (
                        ((-(*frmData) + 3.0f*(*((EGWsingle*)((EGWuintptr)frmData + line_in->fdPitch))) - 3.0f*(*((EGWsingle*)((EGWuintptr)frmData + pitch2))) + (*((EGWsingle*)((EGWuintptr)frmData + pitch3)))) * thetaCubed) +
                        ((2.0f*(*frmData) - 5.0f*(*((EGWsingle*)((EGWuintptr)frmData + line_in->fdPitch))) + 4.0f*(*((EGWsingle*)((EGWuintptr)frmData + pitch2))) - (*((EGWsingle*)((EGWuintptr)frmData + pitch3)))) * thetaSqrd) +
                        ((-(*frmData) + (*((EGWsingle*)((EGWuintptr)frmData + pitch2)))) * theta) +
                        (2.0f*(*((EGWsingle*)((EGWuintptr)frmData + line_in->fdPitch)))));
                    
                    frmData = (const EGWsingle*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWsingle));
                    result_out = (EGWsingle*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWsingle));
                }
            } else { // knot index = 2, extend right
                EGWsingle theta = (EGWsingle)(absT_in - line_in->otIndicie[2]) / (EGWsingle)(line_in->otIndicie[3] - line_in->otIndicie[2]);
                EGWsingle thetaSqrd = theta * theta;
                EGWsingle thetaCubed = thetaSqrd * theta;
                
                EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
                    EGWsingle rP = (*((EGWsingle*)((EGWuintptr)frmData + pitch3))) + ((*((EGWsingle*)((EGWuintptr)frmData + pitch3))) - (*((EGWsingle*)((EGWuintptr)frmData + pitch2))));
                    
                    *result_out = 0.5f * (
                        ((-(*((EGWsingle*)((EGWuintptr)frmData + line_in->fdPitch))) + 3.0f*(*((EGWsingle*)((EGWuintptr)frmData + pitch2))) - 3.0f*(*((EGWsingle*)((EGWuintptr)frmData + pitch3))) + rP) * thetaCubed) +
                        ((2.0f*(*((EGWsingle*)((EGWuintptr)frmData + line_in->fdPitch))) - 5.0f*(*((EGWsingle*)((EGWuintptr)frmData + pitch2))) + 4.0f*(*((EGWsingle*)((EGWuintptr)frmData + pitch3))) - rP) * thetaSqrd) +
                        ((-(*((EGWsingle*)((EGWuintptr)frmData + line_in->fdPitch))) + (*((EGWsingle*)((EGWuintptr)frmData + pitch3)))) * theta) +
                        (2.0f*(*((EGWsingle*)((EGWuintptr)frmData + pitch2)))));
                    
                    frmData = (const EGWsingle*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWsingle));
                    result_out = (EGWsingle*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWsingle));
                }
            }
        } else { // knot index = 0, extend left
            EGWsingle theta = (EGWsingle)(absT_in - line_in->otIndicie[0]) / (EGWsingle)(line_in->otIndicie[1] - line_in->otIndicie[0]);
            EGWsingle thetaSqrd = theta * theta;
            EGWsingle thetaCubed = thetaSqrd * theta;
            
            EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
                EGWsingle lP = (*frmData) - ((*((EGWsingle*)((EGWuintptr)frmData + line_in->fdPitch))) - (*frmData));
                
                *result_out = 0.5f * (
                    ((-lP + 3.0f*(*frmData) - 3.0f*(*((EGWsingle*)((EGWuintptr)frmData + line_in->fdPitch))) + (*((EGWsingle*)((EGWuintptr)frmData + pitch2)))) * thetaCubed) +
                    ((2.0f*lP - 5.0f*(*frmData) + 4.0f*(*((EGWsingle*)((EGWuintptr)frmData + line_in->fdPitch))) - (*((EGWsingle*)((EGWuintptr)frmData + pitch2)))) * thetaSqrd) +
                    ((-lP + (*((EGWsingle*)((EGWuintptr)frmData + line_in->fdPitch)))) * theta) +
                    (2.0f*(*frmData)));
                frmData = (const EGWsingle*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWsingle));
                result_out = (EGWsingle*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWsingle));
            }
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwIpoCubicCRd(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWdouble* result_out) {
    EGWuintptr fdOffset = 0;
    const EGWuintptr pitch2 = line_in->fdPitch + line_in->fdPitch;
    const EGWuintptr pitch3 = pitch2 + line_in->fdPitch;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWdouble* frmData = (const EGWdouble*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        if(absT_in >= line_in->otIndicie[1] - EGW_TIME_EPSILON) { // knot index = 1 or 2
            if(absT_in <= line_in->otIndicie[2] + EGW_TIME_EPSILON) { // knot index = 1
                EGWdouble theta = (EGWdouble)(absT_in - line_in->otIndicie[1]) / (EGWdouble)(line_in->otIndicie[2] - line_in->otIndicie[1]);
                EGWdouble thetaSqrd = theta * theta;
                EGWdouble thetaCubed = thetaSqrd * theta;
                
                EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
                    *result_out = 0.5 * (
                        ((-(*frmData) + 3.0*(*((EGWdouble*)((EGWuintptr)frmData + line_in->fdPitch))) - 3.0*(*((EGWdouble*)((EGWuintptr)frmData + pitch2))) + (*((EGWdouble*)((EGWuintptr)frmData + pitch3)))) * thetaCubed) +
                        ((2.0*(*frmData) - 5.0*(*((EGWdouble*)((EGWuintptr)frmData + line_in->fdPitch))) + 4.0*(*((EGWdouble*)((EGWuintptr)frmData + pitch2))) - (*((EGWdouble*)((EGWuintptr)frmData + pitch3)))) * thetaSqrd) +
                        ((-(*frmData) + (*((EGWdouble*)((EGWuintptr)frmData + pitch2)))) * theta) +
                        (2.0*(*((EGWdouble*)((EGWuintptr)frmData + line_in->fdPitch)))));
                    
                    frmData = (const EGWdouble*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWdouble));
                    result_out = (EGWdouble*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWdouble));
                }
            } else { // knot index = 2, extend right
                EGWdouble theta = (EGWdouble)(absT_in - line_in->otIndicie[2]) / (EGWdouble)(line_in->otIndicie[3] - line_in->otIndicie[2]);
                EGWdouble thetaSqrd = theta * theta;
                EGWdouble thetaCubed = thetaSqrd * theta;
                
                EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
                    EGWdouble rP = (*((EGWdouble*)((EGWuintptr)frmData + pitch3))) + ((*((EGWdouble*)((EGWuintptr)frmData + pitch3))) - (*((EGWdouble*)((EGWuintptr)frmData + pitch2))));
                    
                    *result_out = 0.5 * (
                        ((-(*((EGWdouble*)((EGWuintptr)frmData + line_in->fdPitch))) + 3.0*(*((EGWdouble*)((EGWuintptr)frmData + pitch2))) - 3.0*(*((EGWdouble*)((EGWuintptr)frmData + pitch3))) + rP) * thetaCubed) +
                        ((2.0*(*((EGWdouble*)((EGWuintptr)frmData + line_in->fdPitch))) - 5.0*(*((EGWdouble*)((EGWuintptr)frmData + pitch2))) + 4.0*(*((EGWdouble*)((EGWuintptr)frmData + pitch3))) - rP) * thetaSqrd) +
                        ((-(*((EGWdouble*)((EGWuintptr)frmData + line_in->fdPitch))) + (*((EGWdouble*)((EGWuintptr)frmData + pitch3)))) * theta) +
                        (2.0*(*((EGWdouble*)((EGWuintptr)frmData + pitch2)))));
                    
                    frmData = (const EGWdouble*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWdouble));
                    result_out = (EGWdouble*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWdouble));
                }
            }
        } else { // knot index = 0, extend left
            EGWdouble theta = (EGWdouble)(absT_in - line_in->otIndicie[0]) / (EGWdouble)(line_in->otIndicie[1] - line_in->otIndicie[0]);
            EGWdouble thetaSqrd = theta * theta;
            EGWdouble thetaCubed = thetaSqrd * theta;
            
            EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
                EGWdouble lP = (*frmData) - ((*((EGWdouble*)((EGWuintptr)frmData + line_in->fdPitch))) - (*frmData));
                
                *result_out = 0.5 * (
                    ((-lP + 3.0*(*frmData) - 3.0*(*((EGWdouble*)((EGWuintptr)frmData + line_in->fdPitch))) + (*((EGWdouble*)((EGWuintptr)frmData + pitch2)))) * thetaCubed) +
                    ((2.0*lP - 5.0*(*frmData) + 4.0*(*((EGWdouble*)((EGWuintptr)frmData + line_in->fdPitch))) - (*((EGWdouble*)((EGWuintptr)frmData + pitch2)))) * thetaSqrd) +
                    ((-lP + (*((EGWdouble*)((EGWuintptr)frmData + line_in->fdPitch)))) * theta) +
                    (2.0*(*frmData)));
                frmData = (const EGWdouble*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWdouble));
                result_out = (EGWdouble*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWdouble));
            }
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwIpoCubicCRt(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWtriple* result_out) {
    EGWuintptr fdOffset = 0;
    const EGWuintptr pitch2 = line_in->fdPitch + line_in->fdPitch;
    const EGWuintptr pitch3 = pitch2 + line_in->fdPitch;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWtriple* frmData = (const EGWtriple*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        if(absT_in >= line_in->otIndicie[1] - EGW_TIME_EPSILON) { // knot index = 1 or 2
            if(absT_in <= line_in->otIndicie[2] + EGW_TIME_EPSILON) { // knot index = 1
                EGWtriple theta = (EGWtriple)(absT_in - line_in->otIndicie[1]) / (EGWtriple)(line_in->otIndicie[2] - line_in->otIndicie[1]);
                EGWtriple thetaSqrd = theta * theta;
                EGWtriple thetaCubed = thetaSqrd * theta;
                
                EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
                    *result_out = (EGWtriple)0.5 * (
                        ((-(*frmData) + (EGWtriple)3.0*(*((EGWtriple*)((EGWuintptr)frmData + line_in->fdPitch))) - (EGWtriple)3.0*(*((EGWtriple*)((EGWuintptr)frmData + pitch2))) + (*((EGWtriple*)((EGWuintptr)frmData + pitch3)))) * thetaCubed) +
                        (((EGWtriple)2.0*(*frmData) - (EGWtriple)5.0*(*((EGWtriple*)((EGWuintptr)frmData + line_in->fdPitch))) + (EGWtriple)4.0*(*((EGWtriple*)((EGWuintptr)frmData + pitch2))) - (*((EGWtriple*)((EGWuintptr)frmData + pitch3)))) * thetaSqrd) +
                        ((-(*frmData) + (*((EGWtriple*)((EGWuintptr)frmData + pitch2)))) * theta) +
                        ((EGWtriple)2.0*(*((EGWtriple*)((EGWuintptr)frmData + line_in->fdPitch)))));
                    
                    frmData = (const EGWtriple*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWtriple));
                    result_out = (EGWtriple*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWtriple));
                }
            } else { // knot index = 2, extend right
                EGWtriple theta = (EGWtriple)(absT_in - line_in->otIndicie[2]) / (EGWtriple)(line_in->otIndicie[3] - line_in->otIndicie[2]);
                EGWtriple thetaSqrd = theta * theta;
                EGWtriple thetaCubed = thetaSqrd * theta;
                
                EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
                    EGWtriple rP = (*((EGWtriple*)((EGWuintptr)frmData + pitch3))) + ((*((EGWtriple*)((EGWuintptr)frmData + pitch3))) - (*((EGWtriple*)((EGWuintptr)frmData + pitch2))));
                    
                    *result_out = (EGWtriple)0.5 * (
                        ((-(*((EGWtriple*)((EGWuintptr)frmData + line_in->fdPitch))) + (EGWtriple)3.0*(*((EGWtriple*)((EGWuintptr)frmData + pitch2))) - (EGWtriple)3.0*(*((EGWtriple*)((EGWuintptr)frmData + pitch3))) + rP) * thetaCubed) +
                        (((EGWtriple)2.0*(*((EGWtriple*)((EGWuintptr)frmData + line_in->fdPitch))) - (EGWtriple)5.0*(*((EGWtriple*)((EGWuintptr)frmData + pitch2))) + (EGWtriple)4.0*(*((EGWtriple*)((EGWuintptr)frmData + pitch3))) - rP) * thetaSqrd) +
                        ((-(*((EGWtriple*)((EGWuintptr)frmData + line_in->fdPitch))) + (*((EGWtriple*)((EGWuintptr)frmData + pitch3)))) * theta) +
                        ((EGWtriple)2.0*(*((EGWtriple*)((EGWuintptr)frmData + pitch2)))));
                    
                    frmData = (const EGWtriple*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWtriple));
                    result_out = (EGWtriple*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWtriple));
                }
            }
        } else { // knot index = 0, extend left
            EGWtriple theta = (EGWtriple)(absT_in - line_in->otIndicie[0]) / (EGWtriple)(line_in->otIndicie[1] - line_in->otIndicie[0]);
            EGWtriple thetaSqrd = theta * theta;
            EGWtriple thetaCubed = thetaSqrd * theta;
            
            EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
                EGWtriple lP = (*frmData) - ((*((EGWtriple*)((EGWuintptr)frmData + line_in->fdPitch))) - (*frmData));
                
                *result_out = (EGWtriple)0.5 * (
                    ((-lP + (EGWtriple)3.0*(*frmData) - (EGWtriple)3.0*(*((EGWtriple*)((EGWuintptr)frmData + line_in->fdPitch))) + (*((EGWtriple*)((EGWuintptr)frmData + pitch2)))) * thetaCubed) +
                    (((EGWtriple)2.0*lP - (EGWtriple)5.0*(*frmData) + (EGWtriple)4.0*(*((EGWtriple*)((EGWuintptr)frmData + line_in->fdPitch))) - (*((EGWtriple*)((EGWuintptr)frmData + pitch2)))) * thetaSqrd) +
                    ((-lP + (*((EGWtriple*)((EGWuintptr)frmData + line_in->fdPitch)))) * theta) +
                    ((EGWtriple)2.0*(*frmData)));
                frmData = (const EGWtriple*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWtriple));
                result_out = (EGWtriple*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWtriple));
            }
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

EGWiepofuncfp egwEpoRoutine(EGWuint chnFormat_in, EGWuint32 polationMode_in) {
    switch(polationMode_in & EGW_POLATION_EXEXTRA) {
        case EGW_POLATION_EPO_CONST: {
            switch(chnFormat_in) {
                case EGW_KEYCHANNEL_FRMT_INT8:   return (EGWiepofuncfp)&egwEpoConstanti8;
                case EGW_KEYCHANNEL_FRMT_UINT8:  return (EGWiepofuncfp)&egwEpoConstantui8;
                case EGW_KEYCHANNEL_FRMT_INT16:  return (EGWiepofuncfp)&egwEpoConstanti16;
                case EGW_KEYCHANNEL_FRMT_UINT16: return (EGWiepofuncfp)&egwEpoConstantui16;
                case EGW_KEYCHANNEL_FRMT_INT32:  return (EGWiepofuncfp)&egwEpoConstanti32;
                case EGW_KEYCHANNEL_FRMT_UINT32: return (EGWiepofuncfp)&egwEpoConstantui32;
                case EGW_KEYCHANNEL_FRMT_SINGLE: return (EGWiepofuncfp)&egwEpoConstantf;
                case EGW_KEYCHANNEL_FRMT_DOUBLE: return (EGWiepofuncfp)&egwEpoConstantd;
                case EGW_KEYCHANNEL_FRMT_TRIPLE: return (EGWiepofuncfp)&egwEpoConstantt;
            }
        } break;
        case EGW_POLATION_EPO_LINEAR: {
            switch(chnFormat_in) {
                case EGW_KEYCHANNEL_FRMT_INT8:   return (EGWiepofuncfp)&egwEpoLineari8;
                case EGW_KEYCHANNEL_FRMT_UINT8:  return (EGWiepofuncfp)&egwEpoLinearui8;
                case EGW_KEYCHANNEL_FRMT_INT16:  return (EGWiepofuncfp)&egwEpoLineari16;
                case EGW_KEYCHANNEL_FRMT_UINT16: return (EGWiepofuncfp)&egwEpoLinearui16;
                case EGW_KEYCHANNEL_FRMT_INT32:  return (EGWiepofuncfp)&egwEpoLineari32;
                case EGW_KEYCHANNEL_FRMT_UINT32: return (EGWiepofuncfp)&egwEpoLinearui32;
                case EGW_KEYCHANNEL_FRMT_SINGLE: return (EGWiepofuncfp)&egwEpoLinearf;
                case EGW_KEYCHANNEL_FRMT_DOUBLE: return (EGWiepofuncfp)&egwEpoLineard;
                case EGW_KEYCHANNEL_FRMT_TRIPLE: return (EGWiepofuncfp)&egwEpoLineart;
            }
        } break;
        case EGW_POLATION_EPO_CYCLIC:
        case EGW_POLATION_EPO_CYCADD: {
            return (EGWiepofuncfp)&egwEpoNoOp;
        } break;
    }
    
    return NULL;
}

void egwEpoConstanti8(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWint8* result_out) {
    EGWuintptr fdOffset = 0;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWint8* frmData = (const EGWint8*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = *frmData;
            frmData = (const EGWint8*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWint8));
            result_out = (EGWint8*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWint8));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwEpoConstantui8(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWuint8* result_out) {
    EGWuintptr fdOffset = 0;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWuint8* frmData = (const EGWuint8*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = *frmData;
            frmData = (const EGWuint8*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWuint8));
            result_out = (EGWuint8*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWuint8));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwEpoConstanti16(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWint16* result_out) {
    EGWuintptr fdOffset = 0;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWint16* frmData = (const EGWint16*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = *frmData;
            frmData = (const EGWint16*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWint16));
            result_out = (EGWint16*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWint16));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwEpoConstantui16(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWuint16* result_out) {
    EGWuintptr fdOffset = 0;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWuint16* frmData = (const EGWuint16*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = *frmData;
            frmData = (const EGWuint16*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWuint16));
            result_out = (EGWuint16*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWuint16));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwEpoConstanti32(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWint32* result_out) {
    EGWuintptr fdOffset = 0;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWint32* frmData = (const EGWint32*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = *frmData;
            frmData = (const EGWint32*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWint32));
            result_out = (EGWint32*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWint32));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwEpoConstantui32(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWuint32* result_out) {
    EGWuintptr fdOffset = 0;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWuint32* frmData = (const EGWuint32*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = *frmData;
            frmData = (const EGWuint32*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWuint32));
            result_out = (EGWuint32*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWuint32));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwEpoConstantf(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWsingle* result_out) {
    EGWuintptr fdOffset = 0;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWsingle* frmData = (const EGWsingle*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = *frmData;
            frmData = (const EGWsingle*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWsingle));
            result_out = (EGWsingle*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWsingle));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwEpoConstantd(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWdouble* result_out) {
    EGWuintptr fdOffset = 0;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWdouble* frmData = (const EGWdouble*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = *frmData;
            frmData = (const EGWdouble*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWdouble));
            result_out = (EGWdouble*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWdouble));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwEpoConstantt(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWtriple* result_out) {
    EGWuintptr fdOffset = 0;
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWtriple* frmData = (const EGWtriple*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = *frmData;
            frmData = (const EGWtriple*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWtriple));
            result_out = (EGWtriple*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWtriple));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwEpoLineari8(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWint8* result_out) {
    EGWuintptr fdOffset = 0;
    const EGWtime theta = (absT_in - line_in->otIndicie[1]) / (line_in->otIndicie[1] - line_in->otIndicie[0]);
    const EGWint sigma = (EGWint)(theta * (EGWtime)10000.0f);
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWint8* frmData = (const EGWint8*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = (EGWint8)(((EGWint)(*(EGWint8*)((EGWuintptr)frmData + line_in->fdPitch)) + (((EGWint)(*(EGWint8*)((EGWuintptr)frmData + line_in->fdPitch)) - (EGWint)*frmData) * sigma)) / (EGWint)10000);
            frmData = (const EGWint8*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWint8));
            result_out = (EGWint8*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWint8));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwEpoLinearui8(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWuint8* result_out) {
    EGWuintptr fdOffset = 0;
    const EGWtime theta = (absT_in - line_in->otIndicie[1]) / (line_in->otIndicie[1] - line_in->otIndicie[0]);
    const EGWuint sigma = (EGWuint)(theta * (EGWtime)10000.0f);
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWuint8* frmData = (const EGWuint8*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = (EGWuint8)(((EGWuint)(*(EGWuint8*)((EGWuintptr)frmData + line_in->fdPitch)) + (((EGWuint)(*(EGWuint8*)((EGWuintptr)frmData + line_in->fdPitch)) - (EGWuint)*frmData) * sigma)) / (EGWuint)10000);
            frmData = (const EGWuint8*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWuint8));
            result_out = (EGWuint8*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWuint8));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwEpoLineari16(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWint16* result_out) {
    EGWuintptr fdOffset = 0;
    const EGWtime theta = (absT_in - line_in->otIndicie[1]) / (line_in->otIndicie[1] - line_in->otIndicie[0]);
    const EGWint sigma = (EGWint)(theta * (EGWtime)10000.0f);
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWint16* frmData = (const EGWint16*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = (EGWint16)(((EGWint)(*(EGWint16*)((EGWuintptr)frmData + line_in->fdPitch)) + (((EGWint)(*(EGWint16*)((EGWuintptr)frmData + line_in->fdPitch)) - (EGWint)*frmData) * sigma)) / (EGWint)10000);
            frmData = (const EGWint16*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWint16));
            result_out = (EGWint16*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWint16));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwEpoLinearui16(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWuint16* result_out) {
    EGWuintptr fdOffset = 0;
    const EGWtime theta = (absT_in - line_in->otIndicie[1]) / (line_in->otIndicie[1] - line_in->otIndicie[0]);
    const EGWuint sigma = (EGWuint)(theta * (EGWtime)10000.0f);
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWuint16* frmData = (const EGWuint16*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = (EGWuint16)(((EGWuint)(*(EGWuint16*)((EGWuintptr)frmData + line_in->fdPitch)) + (((EGWuint)(*(EGWuint16*)((EGWuintptr)frmData + line_in->fdPitch)) - (EGWuint)*frmData) * sigma)) / (EGWuint)10000);
            frmData = (const EGWuint16*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWuint16));
            result_out = (EGWuint16*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWuint16));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwEpoLineari32(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWint32* result_out) {
    EGWuintptr fdOffset = 0;
    const EGWtime theta = (absT_in - line_in->otIndicie[1]) / (line_in->otIndicie[1] - line_in->otIndicie[0]);
    const EGWint64 sigma = (EGWint64)(theta * (EGWtime)10000.0f);
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWint32* frmData = (const EGWint32*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = (EGWint32)(((EGWint64)(*(EGWint32*)((EGWuintptr)frmData + line_in->fdPitch)) + (((EGWint64)(*(EGWint32*)((EGWuintptr)frmData + line_in->fdPitch)) - (EGWint64)*frmData) * sigma)) / (EGWint64)10000);
            frmData = (const EGWint32*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWint32));
            result_out = (EGWint32*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWint32));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwEpoLinearui32(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWuint32* result_out) {
    EGWuintptr fdOffset = 0;
    const EGWtime theta = (absT_in - line_in->otIndicie[1]) / (line_in->otIndicie[1] - line_in->otIndicie[0]);
    const EGWuint64 sigma = (EGWuint64)(theta * (EGWtime)10000.0f);
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWuint32* frmData = (const EGWuint32*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = (EGWuint32)(((EGWuint64)(*(EGWuint32*)((EGWuintptr)frmData + line_in->fdPitch)) + (((EGWuint64)(*(EGWuint32*)((EGWuintptr)frmData + line_in->fdPitch)) - (EGWuint64)*frmData) * sigma)) / (EGWuint64)10000);
            frmData = (const EGWuint32*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWuint32));
            result_out = (EGWuint32*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWuint32));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwEpoLinearf(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWsingle* result_out) {
    EGWuintptr fdOffset = 0;
    const EGWtime theta = (absT_in - line_in->otIndicie[1]) / (line_in->otIndicie[1] - line_in->otIndicie[0]);
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWsingle* frmData = (const EGWsingle*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = (*(const EGWsingle*)((EGWuintptr)frmData + line_in->fdPitch)) + (((*(const EGWsingle*)((EGWuintptr)frmData + line_in->fdPitch)) - *frmData) * (EGWsingle)theta);
            frmData = (const EGWsingle*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWsingle));
            result_out = (EGWsingle*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWsingle));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwEpoLineard(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWdouble* result_out) {
    EGWuintptr fdOffset = 0;
    const EGWtime theta = (absT_in - line_in->otIndicie[1]) / (line_in->otIndicie[1] - line_in->otIndicie[0]);
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWdouble* frmData = (const EGWdouble*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = (*(const EGWdouble*)((EGWuintptr)frmData + line_in->fdPitch)) + (((*(const EGWdouble*)((EGWuintptr)frmData + line_in->fdPitch)) - *frmData) * (EGWdouble)theta);
            frmData = (const EGWdouble*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWdouble));
            result_out = (EGWdouble*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWdouble));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwEpoLineart(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWtriple* result_out) {
    EGWuintptr fdOffset = 0;
    const EGWtime theta = (absT_in - line_in->otIndicie[1]) / (line_in->otIndicie[1] - line_in->otIndicie[0]);
    
    EGWuint cmpCount = (EGWuint)line_in->cmpCount; while(cmpCount--) {
        register const EGWtriple* frmData = (const EGWtriple*)((EGWuintptr)line_in->okFrame + fdOffset);
        
        EGWuint chnCount = (EGWuint)line_in->chnCount; while(chnCount--) {
            *result_out = (*(const EGWtriple*)((EGWuintptr)frmData + line_in->fdPitch)) + (((*(const EGWtriple*)((EGWuintptr)frmData + line_in->fdPitch)) - *frmData) * (EGWtriple)theta);
            frmData = (const EGWtriple*)((EGWuintptr)frmData + (EGWuintptr)sizeof(EGWtriple));
            result_out = (EGWtriple*)((EGWuintptr)result_out + (EGWuintptr)sizeof(EGWtriple));
        }
        
        fdOffset += (EGWuintptr)line_in->cdPitch;
    }
}

void egwEpoNoOp(const egwKnotTrackLine* line_in, EGWtime absT_in, EGWbyte* result_out) {
    return;
}

void egwForceToAcceleration(const egwVector3f* force_in, const EGWsingle massInv_in, egwVector3f* accel_out) {
    accel_out->axis.x = massInv_in * force_in->axis.x;
    accel_out->axis.y = massInv_in * force_in->axis.y;
    accel_out->axis.z = massInv_in * force_in->axis.z;
}

void egwForceToTorque(const egwVector3f* force_in, const egwVector3f* offset_in, egwVector3f* torque_out) {
    torque_out->axis.x = (offset_in->axis.y * force_in->axis.z) - (offset_in->axis.z * force_in->axis.y);
    torque_out->axis.y = (offset_in->axis.z * force_in->axis.x) - (offset_in->axis.x * force_in->axis.z);
    torque_out->axis.z = (offset_in->axis.x * force_in->axis.y) - (offset_in->axis.y * force_in->axis.x);
}

void egwTorqueToAcceleration(const egwVector3f* torque_in, const egwMatrix44f* inertiaInv_in, egwVector3f* accel_out) {
    accel_out->axis.x = (inertiaInv_in->component.r1c1 * torque_in->axis.x) + (inertiaInv_in->component.r1c2 * torque_in->axis.y) + (inertiaInv_in->component.r1c3 * torque_in->axis.z);
    accel_out->axis.y = (inertiaInv_in->component.r2c1 * torque_in->axis.x) + (inertiaInv_in->component.r2c2 * torque_in->axis.y) + (inertiaInv_in->component.r2c3 * torque_in->axis.z);
    accel_out->axis.z = (inertiaInv_in->component.r3c1 * torque_in->axis.x) + (inertiaInv_in->component.r3c2 * torque_in->axis.y) + (inertiaInv_in->component.r3c3 * torque_in->axis.z);
}

void egwPositionsToMatrix(const egwVector3f* linearPos_in, const egwVector3f* angularPos_in, egwMatrix44f* matrix_out) {
    egwVector3f axis;
    matrix_out->component.r1c4 = matrix_out->component.r2c4 = matrix_out->component.r3c4 = 0.0f;
    matrix_out->component.r4c4 = 1.0f;
    
    EGWsingle angle = egwVecMagnitude3f(angularPos_in);
    egwVecNormalizeMag3f(angularPos_in, angle, &axis);
    EGWsingle sa = egwSinf(angle);
    EGWsingle ca = egwCosf(angle);
    EGWsingle OneMinusCa = 1.0f - ca;
    EGWsingle OneMinusCaRxRy = OneMinusCa * axis.axis.x * axis.axis.y;
    EGWsingle OneMinusCaRxRz = OneMinusCa * axis.axis.x * axis.axis.z;
    EGWsingle OneMinusCaRyRz = OneMinusCa * axis.axis.y * axis.axis.z;
    EGWsingle RxSa = axis.axis.x * sa;
    EGWsingle RySa = axis.axis.y * sa;
    EGWsingle RzSa = axis.axis.z * sa;
    matrix_out->component.r1c1 = ca + (OneMinusCa * egwSqrd(axis.axis.x)); matrix_out->component.r1c2 = OneMinusCaRxRy - RzSa; matrix_out->component.r1c3 = OneMinusCaRxRz + RySa;
    matrix_out->component.r2c1 = OneMinusCaRxRy + RzSa; matrix_out->component.r2c2 = ca + (OneMinusCa * egwSqrd(axis.axis.y)); matrix_out->component.r2c3 = OneMinusCaRyRz - RxSa;
    matrix_out->component.r3c1 = OneMinusCaRxRz - RySa; matrix_out->component.r3c2 = OneMinusCaRyRz + RxSa; matrix_out->component.r3c3 = ca + (OneMinusCa * egwSqrd(axis.axis.z));
    matrix_out->component.r4c1 = linearPos_in->axis.x;
    matrix_out->component.r4c2 = linearPos_in->axis.y;
    matrix_out->component.r4c3 = linearPos_in->axis.z;
}

void egwIntegrateLinear(const egwVector3f* rate_in, const EGWsingle damping_in, const EGWtime deltaT_in, egwVector3f* vector_inout) {
    if(damping_in == 1.0f) {
        vector_inout->axis.x = vector_inout->axis.x + (rate_in->axis.x * deltaT_in);
        vector_inout->axis.y = vector_inout->axis.y + (rate_in->axis.y * deltaT_in);
        vector_inout->axis.z = vector_inout->axis.z + (rate_in->axis.z * deltaT_in);
    } else {
        vector_inout->axis.x = (vector_inout->axis.x * egwPowf(damping_in, deltaT_in)) + (rate_in->axis.x * deltaT_in);
        vector_inout->axis.y = (vector_inout->axis.y * egwPowf(damping_in, deltaT_in)) + (rate_in->axis.y * deltaT_in);
        vector_inout->axis.z = (vector_inout->axis.z * egwPowf(damping_in, deltaT_in)) + (rate_in->axis.z * deltaT_in);
    }
}

void egwIntegrateLinAvg(const egwVector3f* prevRate_in, const egwVector3f* nextRate_in, const EGWsingle damping_in, const EGWtime deltaT_in, egwVector3f* vector_inout) {
    egwVector3f avgRate;
    avgRate.axis.x = (nextRate_in->axis.x + prevRate_in->axis.x) * 0.5f;
    avgRate.axis.y = (nextRate_in->axis.y + prevRate_in->axis.y) * 0.5f;
    avgRate.axis.z = (nextRate_in->axis.z + prevRate_in->axis.z) * 0.5f;
    
    if(damping_in == 1.0f) {
        vector_inout->axis.x = vector_inout->axis.x + (avgRate.axis.x * deltaT_in);
        vector_inout->axis.y = vector_inout->axis.y + (avgRate.axis.y * deltaT_in);
        vector_inout->axis.z = vector_inout->axis.z + (avgRate.axis.z * deltaT_in);
    } else {
        vector_inout->axis.x = (vector_inout->axis.x * egwPowf(damping_in, deltaT_in)) + (avgRate.axis.x * deltaT_in);
        vector_inout->axis.y = (vector_inout->axis.y * egwPowf(damping_in, deltaT_in)) + (avgRate.axis.y * deltaT_in);
        vector_inout->axis.z = (vector_inout->axis.z * egwPowf(damping_in, deltaT_in)) + (avgRate.axis.z * deltaT_in);
    }
}

void egwInertiaTensorSolidSphere(const egwSphere4f* sphere_in, const EGWsingle mass_in, egwMatrix44f* inertia_out) {
    inertia_out->component.r1c1 = inertia_out->component.r2c2 = inertia_out->component.r3c3 = (2.0f / 5.0f) * mass_in * (sphere_in->radius * sphere_in->radius);
    inertia_out->component.r2c1 = inertia_out->component.r3c1 = inertia_out->component.r4c1 =
        inertia_out->component.r1c2 = inertia_out->component.r3c2 = inertia_out->component.r4c2 =
        inertia_out->component.r1c3 = inertia_out->component.r2c3 = inertia_out->component.r4c3 =
    inertia_out->component.r1c4 = inertia_out->component.r2c4 = inertia_out->component.r3c4 = 0.0f;
    inertia_out->component.r4c4 = 1.0f;
}

void egwInertiaTensorHollowSphere(const egwSphere4f* sphere_in, const EGWsingle mass_in, egwMatrix44f* inertia_out) {
    inertia_out->component.r1c1 = inertia_out->component.r2c2 = inertia_out->component.r3c3 = (2.0f / 3.0f) * mass_in * (sphere_in->radius * sphere_in->radius);
    inertia_out->component.r2c1 = inertia_out->component.r3c1 = inertia_out->component.r4c1 =
        inertia_out->component.r1c2 = inertia_out->component.r3c2 = inertia_out->component.r4c2 =
        inertia_out->component.r1c3 = inertia_out->component.r2c3 = inertia_out->component.r4c3 =
        inertia_out->component.r1c4 = inertia_out->component.r2c4 = inertia_out->component.r3c4 = 0.0f;
    inertia_out->component.r4c4 = 1.0f;
}

void egwInertiaTensorSolidBox(const egwBox4f* box_in, const EGWsingle mass_in, egwMatrix44f* inertia_out) {
    EGWsingle widthSqr = egwAbsf(box_in->max.axis.x - box_in->min.axis.x); widthSqr *= widthSqr;
    EGWsingle heightSqr = egwAbsf(box_in->max.axis.y - box_in->min.axis.y); heightSqr *= heightSqr;
    EGWsingle depthSqr = egwAbsf(box_in->max.axis.z - box_in->min.axis.z); depthSqr *= depthSqr;
    EGWsingle massSigma = mass_in * (1.0f / 12.0f);
    
    inertia_out->component.r1c1 = massSigma * (heightSqr * depthSqr);
    inertia_out->component.r2c2 = massSigma * (widthSqr * depthSqr);
    inertia_out->component.r3c3 = massSigma * (widthSqr * heightSqr);
    inertia_out->component.r2c1 = inertia_out->component.r3c1 = inertia_out->component.r4c1 =
        inertia_out->component.r1c2 = inertia_out->component.r3c2 = inertia_out->component.r4c2 =
        inertia_out->component.r1c3 = inertia_out->component.r2c3 = inertia_out->component.r4c3 =
        inertia_out->component.r1c4 = inertia_out->component.r2c4 = inertia_out->component.r3c4 = 0.0f;
    inertia_out->component.r4c4 = 1.0f;
}

void egwInertiaTensorHollowBox(const egwBox4f* box_in, const EGWsingle mass_in, egwMatrix44f* inertia_out) {
    EGWsingle widthSqr = egwAbsf(box_in->max.axis.x - box_in->min.axis.x); widthSqr *= widthSqr;
    EGWsingle heightSqr = egwAbsf(box_in->max.axis.y - box_in->min.axis.y); heightSqr *= heightSqr;
    EGWsingle depthSqr = egwAbsf(box_in->max.axis.z - box_in->min.axis.z); depthSqr *= depthSqr;
    EGWsingle massSigma = mass_in * (10.0f / 72.0f);
    
    inertia_out->component.r1c1 = massSigma * (heightSqr * depthSqr);
    inertia_out->component.r2c2 = massSigma * (widthSqr * depthSqr);
    inertia_out->component.r3c3 = massSigma * (widthSqr * heightSqr);
    inertia_out->component.r2c1 = inertia_out->component.r3c1 = inertia_out->component.r4c1 =
        inertia_out->component.r1c2 = inertia_out->component.r3c2 = inertia_out->component.r4c2 =
        inertia_out->component.r1c3 = inertia_out->component.r2c3 = inertia_out->component.r4c3 =
        inertia_out->component.r1c4 = inertia_out->component.r2c4 = inertia_out->component.r3c4 = 0.0f;
    inertia_out->component.r4c4 = 1.0f;
}

void egwInertiaTensorSolidCone(const egwCone4f* cone_in, const EGWsingle mass_in, egwMatrix44f* inertia_out) {
    EGWsingle heightSqr = egwSqrdf(egwDbld(cone_in->hHeight));
    EGWsingle radiusSqr = egwSqrd(cone_in->radius);
    
    inertia_out->component.r1c1 = inertia_out->component.r3c3 = ((1.0f / 10.0f) * mass_in * heightSqr) + ((3.0f / 10.0f) * mass_in * radiusSqr);
    inertia_out->component.r2c2 = (3.0f / 10.0f) * mass_in * radiusSqr;
    inertia_out->component.r2c1 = inertia_out->component.r3c1 = inertia_out->component.r4c1 =
        inertia_out->component.r1c2 = inertia_out->component.r3c2 = inertia_out->component.r4c2 =
        inertia_out->component.r1c3 = inertia_out->component.r2c3 = inertia_out->component.r4c3 =
        inertia_out->component.r1c4 = inertia_out->component.r2c4 = inertia_out->component.r3c4 = 0.0f;
    inertia_out->component.r4c4 = 1.0f;
}

void egwInertiaTensorHollowCone(const egwCone4f* cone_in, const EGWsingle mass_in, egwMatrix44f* inertia_out) {
    EGWsingle heightSqr = egwSqrdf(egwDbld(cone_in->hHeight));
    EGWsingle radiusSqr = egwSqrd(cone_in->radius);
    
    inertia_out->component.r1c1 = inertia_out->component.r3c3 = (0.25f * mass_in * heightSqr) + ((1.0f / 12.0f) * mass_in * radiusSqr);
    inertia_out->component.r2c2 = 0.5f * mass_in * radiusSqr;
    inertia_out->component.r2c1 = inertia_out->component.r3c1 = inertia_out->component.r4c1 =
        inertia_out->component.r1c2 = inertia_out->component.r3c2 = inertia_out->component.r4c2 =
        inertia_out->component.r1c3 = inertia_out->component.r2c3 = inertia_out->component.r4c3 =
        inertia_out->component.r1c4 = inertia_out->component.r2c4 = inertia_out->component.r3c4 = 0.0f;
    inertia_out->component.r4c4 = 1.0f;
}

void egwInertiaTensorSolidCylinder(const egwCylinder4f* cylinder_in, const EGWsingle mass_in, egwMatrix44f* inertia_out) {
    EGWsingle heightSqr = egwSqrdf(egwDbld(cylinder_in->hHeight));
    EGWsingle radiusSqr = egwSqrd(cylinder_in->radius);
    
    inertia_out->component.r1c1 = inertia_out->component.r3c3 = ((1.0f / 12.0f) * mass_in * heightSqr) + ((1.0f / 4.0f) * mass_in * radiusSqr);
    inertia_out->component.r2c2 = (1.0f / 2.0f) * mass_in * radiusSqr;
    inertia_out->component.r2c1 = inertia_out->component.r3c1 = inertia_out->component.r4c1 =
        inertia_out->component.r1c2 = inertia_out->component.r3c2 = inertia_out->component.r4c2 =
        inertia_out->component.r1c3 = inertia_out->component.r2c3 = inertia_out->component.r4c3 =
        inertia_out->component.r1c4 = inertia_out->component.r2c4 = inertia_out->component.r3c4 = 0.0f;
    inertia_out->component.r4c4 = 1.0f;
}

void egwInertiaTensorHollowCylinder(const egwCylinder4f* cylinder_in, const EGWsingle mass_in, egwMatrix44f* inertia_out) {
    EGWsingle heightSqr = egwSqrdf(egwDbld(cylinder_in->hHeight));
    EGWsingle radiusSqr = egwSqrd(cylinder_in->radius);
    
    inertia_out->component.r1c1 = inertia_out->component.r3c3 = ((5.0f / 24.0f) * mass_in * heightSqr) + ((5.0f / 72.0f) * mass_in * radiusSqr);
    inertia_out->component.r2c2 = 0.5f * mass_in * radiusSqr;
    inertia_out->component.r2c1 = inertia_out->component.r3c1 = inertia_out->component.r4c1 =
        inertia_out->component.r1c2 = inertia_out->component.r3c2 = inertia_out->component.r4c2 =
        inertia_out->component.r1c3 = inertia_out->component.r2c3 = inertia_out->component.r4c3 =
        inertia_out->component.r1c4 = inertia_out->component.r2c4 = inertia_out->component.r3c4 = 0.0f;
    inertia_out->component.r4c4 = 1.0f;
}

void egwInertiaTensorCenteredRod(const EGWsingle rodLenX_in, const EGWsingle mass_in, egwMatrix44f* inertia_out) {
    EGWsingle lengthSqr = egwSqrd(rodLenX_in);
    
    inertia_out->component.r2c2 = inertia_out->component.r3c3 = (1.0f / 12.0f) * mass_in * lengthSqr;
    inertia_out->component.r1c1 =
        inertia_out->component.r2c1 = inertia_out->component.r3c1 = inertia_out->component.r4c1 =
        inertia_out->component.r1c2 = inertia_out->component.r3c2 = inertia_out->component.r4c2 =
        inertia_out->component.r1c3 = inertia_out->component.r2c3 = inertia_out->component.r4c3 =
        inertia_out->component.r1c4 = inertia_out->component.r2c4 = inertia_out->component.r3c4 = 0.0f;
    inertia_out->component.r4c4 = 1.0f;
}

void egwInertiaTensorExtendedRod(const EGWsingle rodLenX_in, const EGWsingle mass_in, egwMatrix44f* inertia_out) {
    EGWsingle lengthSqr = egwSqrd(rodLenX_in);
    
    inertia_out->component.r2c2 = inertia_out->component.r3c3 = (1.0f / 3.0f) * mass_in * lengthSqr;
    inertia_out->component.r1c1 =
        inertia_out->component.r2c1 = inertia_out->component.r3c1 = inertia_out->component.r4c1 =
        inertia_out->component.r1c2 = inertia_out->component.r3c2 = inertia_out->component.r4c2 =
        inertia_out->component.r1c3 = inertia_out->component.r2c3 = inertia_out->component.r4c3 =
        inertia_out->component.r1c4 = inertia_out->component.r2c4 = inertia_out->component.r3c4 = 0.0f;
    inertia_out->component.r4c4 = 1.0f;
}

egwKeyFrame* egwKeyFrmAlloc(egwKeyFrame* kyfrm_out, EGWuint16 chnFormat_in, EGWuint16 channelC_in, EGWuint16 componentC_in, EGWuint16 frameC_in) {
    memset((void*)kyfrm_out, 0, sizeof(egwKeyFrame));
    
    kyfrm_out->kcFormat = chnFormat_in;
    kyfrm_out->kcCount = channelC_in;
    kyfrm_out->cCount = componentC_in;
    kyfrm_out->fCount = frameC_in;
    
    if((kyfrm_out->kcFormat & EGW_KEYCHANNEL_FRMT_EXBPC) && kyfrm_out->kcCount && kyfrm_out->cCount && kyfrm_out->fCount) {
        if(!(kyfrm_out->fKeys = (EGWbyte*)malloc((size_t)(kyfrm_out->kcFormat & EGW_KEYCHANNEL_FRMT_EXBPC) * (size_t)(kyfrm_out->kcCount) * (size_t)(kyfrm_out->cCount) * (size_t)(kyfrm_out->fCount)))) { egwKeyFrmFree(kyfrm_out); return NULL; }
        if(!(kyfrm_out->tIndicies = (EGWtime*)malloc(sizeof(EGWtime) * (size_t)(kyfrm_out->fCount)))) { egwKeyFrmFree(kyfrm_out); return NULL; }
    } else { egwKeyFrmFree(kyfrm_out); return NULL; }
    
    return kyfrm_out;
}

egwOrientKeyFrame4f* egwOrtKeyFrmAllocf(egwOrientKeyFrame4f* orkyfrm_out, EGWuint16 posFrameC_in, EGWuint16 rotFrameC_in, EGWuint16 sclFrameC_in) {
    memset((void*)orkyfrm_out, 0, sizeof(egwOrientKeyFrame4f));
    
    orkyfrm_out->pfCount = posFrameC_in;
    orkyfrm_out->rfCount = rotFrameC_in;
    orkyfrm_out->sfCount = sclFrameC_in;
    
    if(orkyfrm_out->pfCount || orkyfrm_out->rfCount || orkyfrm_out->sfCount) {
        if(posFrameC_in && !(orkyfrm_out->pfKeys = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)(orkyfrm_out->pfCount)))) { egwOrtKeyFrmFree(orkyfrm_out); return NULL; }
        if(posFrameC_in && !(orkyfrm_out->ptIndicies = (EGWtime*)malloc(sizeof(EGWtime) * (size_t)(orkyfrm_out->pfCount)))) { egwOrtKeyFrmFree(orkyfrm_out); return NULL; }
        if(rotFrameC_in && !(orkyfrm_out->rfKeys = (egwQuaternion4f*)malloc(sizeof(egwQuaternion4f) * (size_t)(orkyfrm_out->rfCount)))) { egwOrtKeyFrmFree(orkyfrm_out); return NULL; }
        if(rotFrameC_in && !(orkyfrm_out->rtIndicies = (EGWtime*)malloc(sizeof(EGWtime) * (size_t)(orkyfrm_out->rfCount)))) { egwOrtKeyFrmFree(orkyfrm_out); return NULL; }
        if(sclFrameC_in && !(orkyfrm_out->sfKeys = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)(orkyfrm_out->sfCount)))) { egwOrtKeyFrmFree(orkyfrm_out); return NULL; }
        if(sclFrameC_in && !(orkyfrm_out->stIndicies = (EGWtime*)malloc(sizeof(EGWtime) * (size_t)(orkyfrm_out->sfCount)))) { egwOrtKeyFrmFree(orkyfrm_out); return NULL; }
    } else { egwOrtKeyFrmFree(orkyfrm_out); return NULL; }
    
    return orkyfrm_out;
}

egwKeyFrame* egwKeyFrmFree(egwKeyFrame* kyfrm_inout) {
    kyfrm_inout->fCount = 0;
    kyfrm_inout->kcCount = kyfrm_inout->kcFormat = 0;
    if(kyfrm_inout->fKeys) { free((void*)kyfrm_inout->fKeys); kyfrm_inout->fKeys = NULL; }
    if(kyfrm_inout->tIndicies) { free((void*)kyfrm_inout->tIndicies); kyfrm_inout->tIndicies = NULL; }
    if(kyfrm_inout->kfExtraDat) { free((void*)kyfrm_inout->kfExtraDat); kyfrm_inout->kfExtraDat = NULL; }
    return kyfrm_inout;
}

egwOrientKeyFrame4f* egwOrtKeyFrmFree(egwOrientKeyFrame4f* orkyfrm_inout) {
    orkyfrm_inout->pfCount = orkyfrm_inout->rfCount = orkyfrm_inout->sfCount = 0;
    if(orkyfrm_inout->pfKeys) { free((void*)orkyfrm_inout->pfKeys); orkyfrm_inout->pfKeys = NULL; }
    if(orkyfrm_inout->rfKeys) { free((void*)orkyfrm_inout->rfKeys); orkyfrm_inout->rfKeys = NULL; }
    if(orkyfrm_inout->sfKeys) { free((void*)orkyfrm_inout->sfKeys); orkyfrm_inout->sfKeys = NULL; }
    if(orkyfrm_inout->ptIndicies && orkyfrm_inout->ptIndicies != orkyfrm_inout->rtIndicies && orkyfrm_inout->ptIndicies != orkyfrm_inout->stIndicies) {
        free((void*)orkyfrm_inout->ptIndicies); orkyfrm_inout->ptIndicies = NULL;
    } else orkyfrm_inout->ptIndicies = NULL;
    if(orkyfrm_inout->rtIndicies && orkyfrm_inout->rtIndicies != orkyfrm_inout->stIndicies) {
        free((void*)orkyfrm_inout->rtIndicies); orkyfrm_inout->rtIndicies = NULL;
    } else orkyfrm_inout->rtIndicies = NULL;
    if(orkyfrm_inout->stIndicies) { free((void*)orkyfrm_inout->stIndicies); orkyfrm_inout->stIndicies = NULL; }
    if(orkyfrm_inout->pkfExtraDat) { free((void*)orkyfrm_inout->pkfExtraDat); orkyfrm_inout->pkfExtraDat = NULL; }
    if(orkyfrm_inout->rkfExtraDat) { free((void*)orkyfrm_inout->rkfExtraDat); orkyfrm_inout->rkfExtraDat = NULL; }
    if(orkyfrm_inout->skfExtraDat) { free((void*)orkyfrm_inout->skfExtraDat); orkyfrm_inout->skfExtraDat = NULL; }
    return orkyfrm_inout;
}

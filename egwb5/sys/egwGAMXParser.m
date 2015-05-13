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

/// @file egwGAMXParser.m
/// @ingroup geWizES_sys_assetmanager
/// GAMX Parser Implementation.

#import <stdio.h>
#import <libxml/xmlreader.h>
#import "egwAssetManager.h"
#import "../sys/egwSystem.h"
#import "../sys/egwEngine.h"
#import "../sys/egwGfxContext.h"
#import "../sys/egwPhyContext.h"
#import "../sys/egwSndContext.h"
#import "../math/egwMath.h"
#import "../math/egwMatrix.h"
#import "../math/egwVector.h"
#import "../math/egwQuaternion.h"
#import "../gfx/egwGraphics.h"
#import "../gfx/egwBindingStacks.h"
#import "../gfx/egwBoundings.h"
#import "../gfx/egwCameras.h"
#import "../gfx/egwFonts.h"
#import "../gfx/egwLights.h"
#import "../gfx/egwMaterials.h"
#import "../gfx/egwTexture.h"
#import "../geo/egwGeometry.h"
#import "../geo/egwBillboard.h"
#import "../geo/egwMesh.h"
#import "../gui/egwButton.h"
#import "../gui/egwImage.h"
#import "../gui/egwSpritedImage.h"
#import "../gui/egwLabel.h"
#import "../gui/egwPager.h"
#import "../gui/egwSlider.h"
#import "../gui/egwToggle.h"
#import "../obj/egwDLODBranch.h"
#import "../obj/egwObjectBranch.h"
#import "../obj/egwSwitchBranch.h"
#import "../obj/egwTransformBranch.h"
#import "../phy/egwPhysics.h"
#import "../phy/egwInterpolators.h"
#import "../snd/egwSound.h"
#import "../snd/egwPointSound.h"
#import "../snd/egwStreamedPointSound.h"
#import "../misc/egwBoxingTypes.h"
#import "../misc/egwTimer.h"
#import "../misc/egwActionedTimer.h"


@interface egwAssetManager (Private)

// Shared transformers
- (BOOL)performAudioEnsurances:(egwAudio*)audio fromFile:(const EGWchar*)resourceFile withTransforms:(EGWuint*)transforms;
- (BOOL)performAudioConversions:(egwAudio*)audio fromFile:(const EGWchar*)resourceFile withTransforms:(EGWuint*)transforms;
- (BOOL)performAudioModifications:(egwAudio*)audio fromFile:(const EGWchar*)resourceFile withTransforms:(EGWuint*)transforms;
- (BOOL)performSurfaceEnsurances:(egwSurface*)surface fromFile:(const EGWchar*)resourceFile withTransforms:(EGWuint*)transforms;
- (BOOL)performSurfaceConversions:(egwSurface*)surface fromFile:(const EGWchar*)resourceFile withTransforms:(EGWuint*)transforms;
- (BOOL)performSurfaceModifications:(egwSurface*)surface fromFile:(const EGWchar*)resourceFile withTransforms:(EGWuint*)transforms;

// NOTE: Have to perform modifications before and after conversion due to
// certain modifications only applying to certain formats. It should be
// noted in documentation that transforms apply at the first chance they
// get, either before or after any conversions. This is why the tranforms
// var is pass-by-ref, so double transforms aren't applied. -jw

@end


// !!!: ***** GAMX Asset Manifest Loader *****

// NOTE: Below routines always return retained items - remember to release!
// NOTE: nodeTypes: 1: <openingtag> (including <tag/>), 3: >innersectiontext<, 14: <=' ' (ws|endl), 15: </closingtag>

typedef struct {
    id object2;         // Second object (or nil) (weak)
    id object1;         // First object (or nil) (weak)
    SEL method;         // Method selector
} egwGAMPostPerforms;

id<NSObject> egwGAMXParseEntity(const EGWchar* resourceFile, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* loadCounter, const xmlChar* entityNodeName);

// !!!: **** Shared Parsers ****

// !!!: *** General Parsers ***

// Skips current & runs up to next 1,3,15 nodeType, or nodeDepth <= nodeStartDepth, returns cursor nodeType
EGWint egwGAMXParseRunup(xmlTextReaderPtr xmlReadHandle, EGWint* retVal) {
    EGWint nodeStartDepth;
    EGWint nodeType;
    
    if(*retVal != 1) return -1;
    
    nodeStartDepth = xmlTextReaderDepth(xmlReadHandle);
    
    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
        nodeType = xmlTextReaderNodeType(xmlReadHandle);
        
        if(nodeType == 1 || nodeType == 3 || nodeType == 15 || xmlTextReaderDepth(xmlReadHandle) < nodeStartDepth) break;
    }
    
    return nodeType;
}

// Including current, skips junk up to next <skipNodeName/> or </skipNodeName>, AND nodeDepth <= nodeStartDepth (so it doesn't get stuck in depth)
void egwGAMXParseSkip(xmlTextReaderPtr xmlReadHandle, EGWint* retVal, const xmlChar* skipNodeName) {
    EGWint nodeType, nodeStartDepth;
    xmlChar* nodeName = NULL;
    
    if(*retVal != 1) return;
    
    // Check to see if we're already at </skipNodeName> or <skipNodeName/>
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = xmlTextReaderName(xmlReadHandle);
    if(nodeName && strcasecmp((const char*)nodeName, (const char*)skipNodeName) == 0) {
        if((nodeType == 1 && xmlTextReaderIsEmptyElement(xmlReadHandle)) ||
           (nodeType == 15)) {
            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
            return;
        }
    }
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    
    // Track the node start depth, because the matchup has to be <= than this
    nodeStartDepth = xmlTextReaderDepth(xmlReadHandle);
    
    // Read past junk to next </skipNodeName>
    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
        
        if(nodeType == 15 && xmlTextReaderDepth(xmlReadHandle) <= nodeStartDepth && nodeName && strcasecmp((const char*)nodeName, (const char*)skipNodeName) == 0) break;
        
        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
        if(*retVal != 1) break;
    }
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
}

// !!!: *** Audio Parsers ***

// Parses <format> sections inside of <audio> sections
void egwGAMXParseAudio_Format(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* format) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"format") == 0) {
        const char* delims = " ,\t\r\n\0";
        
        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
            xmlChar* entityFrmt = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
            for(entityFrmt = (xmlChar*)strtok((char*)entityFrmt, delims); entityFrmt; entityFrmt = (xmlChar*)strtok(NULL, delims)) {
                if(strcasecmp((const char*)entityFrmt, (const char*)"uint8") == 0) *format |= (EGW_AUDIO_FRMT_EXBPC & 8);
                else if(strcasecmp((const char*)entityFrmt, (const char*)"int16") == 0) *format |= (EGW_AUDIO_FRMT_EXBPC & 16) | EGW_AUDIO_FRMT_EXSIGNED;
                else if(strcasecmp((const char*)entityFrmt, (const char*)"mono") == 0) *format |= EGW_AUDIO_FRMT_EXMONO;
                else if(strcasecmp((const char*)entityFrmt, (const char*)"stereo") == 0) *format |= EGW_AUDIO_FRMT_EXSTEREO;
                else if(strcasecmp((const char*)entityFrmt, (const char*)"mono_uint8") == 0) *format |= EGW_AUDIO_FRMT_MONOU8;
                else if(strcasecmp((const char*)entityFrmt, (const char*)"mono_int16") == 0) *format |= EGW_AUDIO_FRMT_MONOS16;
                else if(strcasecmp((const char*)entityFrmt, (const char*)"stereo_uint8") == 0) *format |= EGW_AUDIO_FRMT_STEREOU8;
                else if(strcasecmp((const char*)entityFrmt, (const char*)"stereo_int16") == 0) *format |= EGW_AUDIO_FRMT_STEREOS16;
                else NSLog(@"egwAssetManager: egwGAMXParseAudio_Format: Failure parsing in manifest input file '%s', for asset '%s': Audio format '%s' not supported.", resourceFile, entityID, entityFrmt);
            }
        }
        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"format");
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// Parses <transforms> sections inside of <audio> sections
void egwGAMXParseAudio_Transforms(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* transforms) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"transforms") == 0) {
        const char* delims = " ,\t\r\n\0";
        
        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
            xmlChar* entityTrans = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
            for(entityTrans = (xmlChar*)strtok((char*)entityTrans, delims); entityTrans; entityTrans = (xmlChar*)strtok(NULL, delims)) {
                if(strcasecmp((const char*)entityTrans, (const char*)"ensure_lt_mstatic") == 0) *transforms |= EGW_AUDIO_TRFM_ENSRLTETMS;
                else if(strcasecmp((const char*)entityTrans, (const char*)"invert_sig") == 0) *transforms |= EGW_AUDIO_TRFM_INVERTS;
                else if(strcasecmp((const char*)entityTrans, (const char*)"swap_lr") == 0) *transforms |= EGW_AUDIO_TRFM_SWAPLR;
                else if(strcasecmp((const char*)entityTrans, (const char*)"reverse_dir") == 0) *transforms |= EGW_AUDIO_TRFM_RVRSDIR;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_u8") == 0) *transforms |= EGW_AUDIO_TRFM_FORCEU8;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_s16") == 0) *transforms |= EGW_AUDIO_TRFM_FORCES16;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_mono") == 0) *transforms |= EGW_AUDIO_TRFM_FORCEMONO;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_stereo") == 0) *transforms |= EGW_AUDIO_TRFM_FORCESTEREO;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_monou8") == 0) *transforms |= EGW_AUDIO_TRFM_FCMONOU8;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_monos16") == 0) *transforms |= EGW_AUDIO_TRFM_FCMONOS16;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_stereou8") == 0) *transforms |= EGW_AUDIO_TRFM_FCSTEREOU8;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_stereos16") == 0) *transforms |= EGW_AUDIO_TRFM_FCSTEREOS16;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack1") == 0) *transforms |= EGW_AUDIO_TRFM_FCBPCK1;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack2") == 0) *transforms |= EGW_AUDIO_TRFM_FCBPCK2;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack4") == 0) *transforms |= EGW_AUDIO_TRFM_FCBPCK4;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack8") == 0) *transforms |= EGW_AUDIO_TRFM_FCBPCK8;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack16") == 0) *transforms |= EGW_AUDIO_TRFM_FCBPCK16;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack32") == 0) *transforms |= EGW_AUDIO_TRFM_FCBPCK32;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack64") == 0) *transforms |= EGW_AUDIO_TRFM_FCBPCK64;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack128") == 0) *transforms |= EGW_AUDIO_TRFM_FCBPCK128;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack256") == 0) *transforms |= EGW_AUDIO_TRFM_FCBPCK256;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack512") == 0) *transforms |= EGW_AUDIO_TRFM_FCBPCK512;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack1024") == 0) *transforms |= EGW_AUDIO_TRFM_FCBPCK1024;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack2048") == 0) *transforms |= EGW_AUDIO_TRFM_FCBPCK2048;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack4096") == 0) *transforms |= EGW_AUDIO_TRFM_FCBPCK4096;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack8192") == 0) *transforms |= EGW_AUDIO_TRFM_FCBPCK8192;
                else NSLog(@"egwAssetManager: egwGAMXParseAudio_Transforms: Failure parsing in manifest input file '%s', for asset '%s': Audio transform '%s' not supported.", resourceFile, entityID, entityTrans);
            }
        }
        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"transforms");
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// Parses <audio source="internal" type="pcm_array"> sections
void egwGAMXParseAudio_PCMA(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, egwAudio* audio, EGWuint* transforms) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"audio") == 0) {
        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
        
        // pcm array read
        while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
            nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
            
            if(nodeType == 14) continue;
            else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"audio") == 0) break;
            else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"samples") == 0 && !xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                xmlChar* entityFormat = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"format");
                EGWuint sCount; xmlChar* entityCount = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"count");
                
                if(entityCount && egwParseStringuicv((EGWchar*)entityCount, (EGWuint*)&sCount, 0, 1) == 1) {
                    sCount = egwClampui(sCount, 1, EGW_UINT16_MAX);
                    if(!entityFormat || strcasecmp((const char*)entityFormat, (const char*)"mono") == 0) {
                        if(egwAudioAlloc(audio, EGW_AUDIO_FRMT_MONOS16, 48000, sCount, EGW_AUDIO_DFLTBPACKING)) {
                            EGWuint nodesProcessed = 0;
                            
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                nodesProcessed += egwParseStringi16cv((EGWchar*)nodeValue, (EGWint16*)audio->data, 0, sCount);
                            }
                            
                            if(nodesProcessed != (EGWuint)audio->count) { // Pad rest with zeros if short
                                NSLog(@"egwAssetManager: egwGAMXParseAudio_PCMA: Warning parsing in manifest input file '%s', for asset '%s': Total samples read %d does not match %d samples reported.", resourceFile, entityID, nodesProcessed, sCount);
                                memset((void*)&(((EGWint16*)audio->data)[nodesProcessed]), 0, sizeof(EGWint16) * (size_t)((EGWuint)audio->count - nodesProcessed));
                            }
                        } else NSLog(@"egwAssetManager: egwGAMXParseAudio_PCMA: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for audio structure.", resourceFile, entityID, sizeof(EGWint16) * sCount);
                    } else if(strcasecmp((const char*)entityFormat, (const char*)"stereo") == 0) {
                        if(egwAudioAlloc(audio, EGW_AUDIO_FRMT_STEREOS16, 48000, sCount, EGW_AUDIO_DFLTBPACKING)) {
                            EGWuint nodesProcessed = 0;
                            
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                nodesProcessed += egwParseStringi16cv((EGWchar*)nodeValue, (EGWint16*)audio->data, 0, sCount * 2);
                            }
                            
                            if(nodesProcessed != (EGWuint)audio->count * 2) { // Pad rest with zeros if short
                                NSLog(@"egwAssetManager: egwGAMXParseAudio_PCMA: Warning parsing in manifest input file '%s', for asset '%s': Total samples read %d does not match %d samples reported.", resourceFile, entityID, nodesProcessed / 2, sCount * 2);
                                memset((void*)&(((EGWint16*)audio->data)[nodesProcessed]), 0, sizeof(EGWint16) * (size_t)(((EGWuint)audio->count * 2) - nodesProcessed));
                            }
                        } else NSLog(@"egwAssetManager: egwGAMXParseAudio_PCMA: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for audio structure.", resourceFile, entityID, sizeof(EGWint16) * sCount * 2);
                    } else NSLog(@"egwAssetManager: egwGAMXParseAudio_PCMA: Failure parsing in manifest input file '%s', for asset '%s': Audio format '%s' not supported.", resourceFile, entityID, (entityFormat ? (const char*)entityFormat : (const char*)"<NULL>"));
                } else NSLog(@"egwAssetManager: egwGAMXParseAudio_PCMA: Failure parsing in manifest input file '%s', for asset '%s': Samples count not specified.", resourceFile, entityID);
                
                if(entityFormat) { xmlFree(entityFormat); entityFormat = NULL; }
                if(entityCount) { xmlFree(entityCount); entityCount = NULL; }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"samples");
            } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"rate") == 0) {
                if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                    egwParseStringui32cv((EGWchar*)nodeValue, (EGWuint32*)&audio->rate, 0, 1);
                }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"rate");
            } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"transforms") == 0) {
                egwGAMXParseAudio_Transforms(resourceFile, entityID, xmlReadHandle, retVal, transforms);
            }
            
            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
            if(*retVal != 1) break;
        }
        
        if(*retVal == 1) {
            EGWuint entitySTransCopy = *transforms;
            
            if(![egwSIAsstMngr performAudioEnsurances:audio fromFile:resourceFile withTransforms:&entitySTransCopy] ||
               ![egwSIAsstMngr performAudioModifications:audio fromFile:resourceFile withTransforms:&entitySTransCopy] ||
               ![egwSIAsstMngr performAudioConversions:audio fromFile:resourceFile withTransforms:&entitySTransCopy] ||
               ![egwSIAsstMngr performAudioModifications:audio fromFile:resourceFile withTransforms:&entitySTransCopy]) {
                NSLog(@"egwAssetManager: egwGAMXParseAudio_PCMA: Failure parsing in manifest input file '%s', for asset '%s': Failure applying audio transforms.", resourceFile, entityID);
                egwAudioFree(audio);
            }
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"audio");
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// Parses <audio source="external"> sections
void egwGAMXParseAudio_External(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, egwAudio* audio, EGWuint* transforms) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"audio") == 0) {
        NSString* entityExternalFile = nil;
        
        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
        
        // external audio read
        while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
            nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
            
            if(nodeType == 14) continue;
            else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"audio") == 0) break;
            else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"url") == 0) {
                if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                    [entityExternalFile release]; entityExternalFile = nil;
                    entityExternalFile = [[NSString alloc] initWithUTF8String:(const char*)egwQTrimc((EGWchar*)nodeValue, -1)];
                }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"url");
            } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"transforms") == 0) {
                egwGAMXParseAudio_Transforms(resourceFile, entityID, xmlReadHandle, retVal, transforms);
            }
            
            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
            if(*retVal != 1) break;
        }
        
        if(*retVal == 1) {
            if(![egwSIAsstMngr loadAudio:audio fromFile:entityExternalFile withTransforms:*transforms])
                NSLog(@"egwAssetManager: egwGAMXParseSurface_External: Failure parsing in manifest input file '%s', for asset '%s': Failure loading audio from external file '%s'.", resourceFile, entityID, entityExternalFile);
        }
        
        [entityExternalFile release]; entityExternalFile = nil;
        
        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"audio");
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// Parses <audio_stream source="external"> sections
void egwGAMXParseAudioStream_External(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, void** stream, EGWuint* transforms) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"audio_stream") == 0) {
        NSString* entityExternalFile = nil;
        
        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
        
        // external audio read
        while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
            nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
            
            if(nodeType == 14) continue;
            else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"audio_stream") == 0) break;
            else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"url") == 0) {
                if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                    [entityExternalFile release]; entityExternalFile = nil;
                    entityExternalFile = [[NSString alloc] initWithUTF8String:(const char*)egwQTrimc((EGWchar*)nodeValue, -1)];
                }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"url");
            } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"transforms") == 0) {
                egwGAMXParseAudio_Transforms(resourceFile, entityID, xmlReadHandle, retVal, transforms);
            }
            
            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
            if(*retVal != 1) break;
        }
        
        if(*retVal == 1) {
            if(![egwSIAsstMngr loadAudioStream:stream fromFile:entityExternalFile withTransforms:*transforms])
                NSLog(@"egwAssetManager: egwGAMXParseAudioStream_External: Failure parsing in manifest input file '%s', for asset '%s': Failure loading audio stream from external file '%s'.", resourceFile, entityID, entityExternalFile);
        }
        
        [entityExternalFile release]; entityExternalFile = nil;
        
        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"audio_stream");
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// !!!: *** Flag Parsers ***

// Parses <render_flags> section, pre cursor should be on <render_flags, post cursor on <render_flags/> or </, works with current values
void egwGAMXParseFlags_Render(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* flags) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"render_flags") == 0) {
        const char* delims = " ,\t\r\n\0";
        
        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
            xmlChar* entityFlag = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
            for(entityFlag = (xmlChar*)strtok((char*)entityFlag, delims); entityFlag; entityFlag = (xmlChar*)strtok(NULL, delims)) {
                if(strcasecmp((const char*)entityFlag, (const char*)"first_pass") == 0) *flags |= EGW_GFXOBJ_RNDRFLG_FIRSTPASS;
                else if(strcasecmp((const char*)entityFlag, (const char*)"second_pass") == 0) *flags |= EGW_GFXOBJ_RNDRFLG_SECONDPASS;
                else if(strcasecmp((const char*)entityFlag, (const char*)"third_pass") == 0) *flags |= EGW_GFXOBJ_RNDRFLG_THIRDPASS;
                else if(strcasecmp((const char*)entityFlag, (const char*)"fourth_pass") == 0) *flags |= EGW_GFXOBJ_RNDRFLG_FOURTHPASS;
                else if(strcasecmp((const char*)entityFlag, (const char*)"fifth_pass") == 0) *flags |= EGW_GFXOBJ_RNDRFLG_FIFTHPASS;
                else if(strcasecmp((const char*)entityFlag, (const char*)"sixth_pass") == 0) *flags |= EGW_GFXOBJ_RNDRFLG_SIXTHPASS;
                else if(strcasecmp((const char*)entityFlag, (const char*)"seventh_pass") == 0) *flags |= EGW_GFXOBJ_RNDRFLG_SEVENTHPASS;
                else if(strcasecmp((const char*)entityFlag, (const char*)"eigth_pass") == 0) *flags |= EGW_GFXOBJ_RNDRFLG_EIGHTHPASS;
                else if(strcasecmp((const char*)entityFlag, (const char*)"force_opaque") == 0) *flags |= EGW_GFXOBJ_RNDRFLG_ISOPAQUE;
                else if(strcasecmp((const char*)entityFlag, (const char*)"force_transparent") == 0) *flags |= EGW_GFXOBJ_RNDRFLG_ISTRANSPARENT;
                else if(strcasecmp((const char*)entityFlag, (const char*)"objt_no_umerge_bvols") == 0) *flags |= EGW_OBJTREE_FLG_NOUMRGBVOLS;
                else if(strcasecmp((const char*)entityFlag, (const char*)"objt_no_umerge_flags") == 0) *flags |= EGW_OBJTREE_FLG_NOUMRGFLAGS;
                else if(strcasecmp((const char*)entityFlag, (const char*)"objt_no_umerge_frames") == 0) *flags |= EGW_OBJTREE_FLG_NOUMRGFRAMES;
                else if(strcasecmp((const char*)entityFlag, (const char*)"objt_no_umerge_sources") == 0) *flags |= EGW_OBJTREE_FLG_NOUMRGSOURCES;
                else if(strcasecmp((const char*)entityFlag, (const char*)"objt_no_umerge_syncs") == 0) *flags |= EGW_OBJTREE_FLG_NOUMRGSYNCS;
                else if(strcasecmp((const char*)entityFlag, (const char*)"objt_no_umerge_any") == 0) *flags |= EGW_OBJTREE_FLG_EXNOUMRG;
                else if(strcasecmp((const char*)entityFlag, (const char*)"obje_always_otg_hmg") == 0) *flags |= EGW_OBJEXTEND_FLG_ALWAYSOTGHMG;
                else if(strcasecmp((const char*)entityFlag, (const char*)"obje_lazy_bounding") == 0) *flags |= EGW_OBJEXTEND_FLG_LAZYBOUNDING;
                else NSLog(@"egwAssetManager: egwGAMXParseFlags_Render: Failure parsing in manifest input file '%s', for asset '%s': Render flag '%s' not supported.", resourceFile, entityID, entityFlag);
            }
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"render_flags");
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// Parses <playback_flags> section, pre cursor should be on <playback_flags, post cursor on <playback_flags/> or </, works with current values
void egwGAMXParseFlags_Playback(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* flags) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"playback_flags") == 0) {
        const char* delims = " ,\t\r\n\0";
        
        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
            xmlChar* entityFlag = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
            for(entityFlag = (xmlChar*)strtok((char*)entityFlag, delims); entityFlag; entityFlag = (xmlChar*)strtok(NULL, delims)) {
                if(strcasecmp((const char*)entityFlag, (const char*)"lowp_queue") == 0) *flags |= EGW_SNDOBJ_PLAYFLG_LOWPRI;
                else if(strcasecmp((const char*)entityFlag, (const char*)"medp_queue") == 0) *flags |= EGW_SNDOBJ_PLAYFLG_MEDPRI;
                else if(strcasecmp((const char*)entityFlag, (const char*)"highp_queue") == 0) *flags |= EGW_SNDOBJ_PLAYFLG_HIGHPRI;
                else if(strcasecmp((const char*)entityFlag, (const char*)"music_queue") == 0) *flags |= EGW_SNDOBJ_PLAYFLG_MUSIC;
                else if(strcasecmp((const char*)entityFlag, (const char*)"looping") == 0) *flags |= EGW_SNDOBJ_PLAYFLG_LOOPING;
                else if(strcasecmp((const char*)entityFlag, (const char*)"pause_dequeued") == 0) *flags |= EGW_SNDOBJ_PLAYFLG_AUTOPAUSE;
                else if(strcasecmp((const char*)entityFlag, (const char*)"priority_queued") == 0) *flags |= EGW_SNDOBJ_PLAYFLG_PRIORITY;
                else if(strcasecmp((const char*)entityFlag, (const char*)"can_wait") == 0) *flags |= EGW_SNDOBJ_PLAYFLG_CANWAIT;
                else if(strcasecmp((const char*)entityFlag, (const char*)"strict_queued") == 0) *flags |= EGW_SNDOBJ_PLAYFLG_STRICT;
                else if(strcasecmp((const char*)entityFlag, (const char*)"objt_no_umerge_bvols") == 0) *flags |= EGW_OBJTREE_FLG_NOUMRGBVOLS;
                else if(strcasecmp((const char*)entityFlag, (const char*)"objt_no_umerge_flags") == 0) *flags |= EGW_OBJTREE_FLG_NOUMRGFLAGS;
                else if(strcasecmp((const char*)entityFlag, (const char*)"objt_no_umerge_frames") == 0) *flags |= EGW_OBJTREE_FLG_NOUMRGFRAMES;
                else if(strcasecmp((const char*)entityFlag, (const char*)"objt_no_umerge_sources") == 0) *flags |= EGW_OBJTREE_FLG_NOUMRGSOURCES;
                else if(strcasecmp((const char*)entityFlag, (const char*)"objt_no_umerge_syncs") == 0) *flags |= EGW_OBJTREE_FLG_NOUMRGSYNCS;
                else if(strcasecmp((const char*)entityFlag, (const char*)"objt_no_umerge_any") == 0) *flags |= EGW_OBJTREE_FLG_EXNOUMRG;
                else if(strcasecmp((const char*)entityFlag, (const char*)"obje_always_otg_hmg") == 0) *flags |= EGW_OBJEXTEND_FLG_ALWAYSOTGHMG;
                else if(strcasecmp((const char*)entityFlag, (const char*)"obje_lazy_bounding") == 0) *flags |= EGW_OBJEXTEND_FLG_LAZYBOUNDING;
                else NSLog(@"egwAssetManager: egwGAMXParseFlags_Render: Failure parsing in manifest input file '%s', for asset '%s': Playback flag '%s' not supported.", resourceFile, entityID, entityFlag);
            }
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"playback_flags");
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// Parses <interaction_flags> section, pre cursor should be on <interaction_flags, post cursor on <interaction_flags/> or </, works with current values
void egwGAMXParseFlags_Interaction(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* flags) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"interaction_flags") == 0) {
        const char* delims = " ,\t\r\n\0";
        
        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
            xmlChar* entityFlag = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
            for(entityFlag = (xmlChar*)strtok((char*)entityFlag, delims); entityFlag; entityFlag = (xmlChar*)strtok(NULL, delims)) {
                if(strcasecmp((const char*)entityFlag, (const char*)"pre_pass") == 0) *flags |= EGW_PHYOBJ_INCTFLG_PREPASS;
                else if(strcasecmp((const char*)entityFlag, (const char*)"main_pass") == 0) *flags |= EGW_PHYOBJ_INCTFLG_MAINPASS;
                else if(strcasecmp((const char*)entityFlag, (const char*)"objt_no_umerge_bvols") == 0) *flags |= EGW_OBJTREE_FLG_NOUMRGBVOLS;
                else if(strcasecmp((const char*)entityFlag, (const char*)"objt_no_umerge_flags") == 0) *flags |= EGW_OBJTREE_FLG_NOUMRGFLAGS;
                else if(strcasecmp((const char*)entityFlag, (const char*)"objt_no_umerge_frames") == 0) *flags |= EGW_OBJTREE_FLG_NOUMRGFRAMES;
                else if(strcasecmp((const char*)entityFlag, (const char*)"objt_no_umerge_sources") == 0) *flags |= EGW_OBJTREE_FLG_NOUMRGSOURCES;
                else if(strcasecmp((const char*)entityFlag, (const char*)"objt_no_umerge_syncs") == 0) *flags |= EGW_OBJTREE_FLG_NOUMRGSYNCS;
                else if(strcasecmp((const char*)entityFlag, (const char*)"objt_no_umerge_any") == 0) *flags |= EGW_OBJTREE_FLG_EXNOUMRG;
                else if(strcasecmp((const char*)entityFlag, (const char*)"obje_always_otg_hmg") == 0) *flags |= EGW_OBJEXTEND_FLG_ALWAYSOTGHMG;
                else if(strcasecmp((const char*)entityFlag, (const char*)"obje_lazy_bounding") == 0) *flags |= EGW_OBJEXTEND_FLG_LAZYBOUNDING;
                else NSLog(@"egwAssetManager: egwGAMXParseFlags_Render: Failure parsing in manifest input file '%s', for asset '%s': Interaction flag '%s' not supported.", resourceFile, entityID, entityFlag);
            }
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"interaction_flags");
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// Parses <actuator_flags> section, pre cursor should be on <actuator_flags, post cursor on <actuator_flags/> or </, works with current values
void egwGAMXParseFlags_Actuator(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* flags) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"actuator_flags") == 0) {
        const char* delims = " ,\t\r\n\0";
        
        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
            xmlChar* entityFlag = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
            for(entityFlag = (xmlChar*)strtok((char*)entityFlag, delims); entityFlag; entityFlag = (xmlChar*)strtok(NULL, delims)) {
                if(strcasecmp((const char*)entityFlag, (const char*)"reverse") == 0) *flags |= EGW_ACTOBJ_ACTRFLG_REVERSE;
                else if(strcasecmp((const char*)entityFlag, (const char*)"looping") == 0) *flags |= EGW_ACTOBJ_ACTRFLG_LOOPING;
                else if(strcasecmp((const char*)entityFlag, (const char*)"auto_enqueue_dstate") == 0) *flags |= EGW_ACTOBJ_ACTRFLG_AUTOENQDS;
                else if(strcasecmp((const char*)entityFlag, (const char*)"normalize_vecs") == 0) *flags |= EGW_ACTOBJ_ACTRFLG_NRMLZVECS;
                else if(strcasecmp((const char*)entityFlag, (const char*)"throttle_20") == 0) *flags |= EGW_ACTOBJ_ACTRFLG_THROTTLE20;
                else if(strcasecmp((const char*)entityFlag, (const char*)"throttle_25") == 0) *flags |= EGW_ACTOBJ_ACTRFLG_THROTTLE25;
                else if(strcasecmp((const char*)entityFlag, (const char*)"throttle_33") == 0) *flags |= EGW_ACTOBJ_ACTRFLG_THROTTLE33;
                else if(strcasecmp((const char*)entityFlag, (const char*)"throttle_50") == 0) *flags |= EGW_ACTOBJ_ACTRFLG_THROTTLE50;
                else if(strcasecmp((const char*)entityFlag, (const char*)"throttle_66") == 0) *flags |= EGW_ACTOBJ_ACTRFLG_THROTTLE66;
                else if(strcasecmp((const char*)entityFlag, (const char*)"throttle_75") == 0) *flags |= EGW_ACTOBJ_ACTRFLG_THROTTLE75;
                else if(strcasecmp((const char*)entityFlag, (const char*)"throttle_88") == 0) *flags |= EGW_ACTOBJ_ACTRFLG_THROTTLE88;
                else if(strcasecmp((const char*)entityFlag, (const char*)"throttle_125") == 0) *flags |= EGW_ACTOBJ_ACTRFLG_THROTTLE125;
                else if(strcasecmp((const char*)entityFlag, (const char*)"throttle_150") == 0) *flags |= EGW_ACTOBJ_ACTRFLG_THROTTLE150;
                else if(strcasecmp((const char*)entityFlag, (const char*)"throttle_200") == 0) *flags |= EGW_ACTOBJ_ACTRFLG_THROTTLE200;
                else if(strcasecmp((const char*)entityFlag, (const char*)"throttle_250") == 0) *flags |= EGW_ACTOBJ_ACTRFLG_THROTTLE250;
                else if(strcasecmp((const char*)entityFlag, (const char*)"throttle_300") == 0) *flags |= EGW_ACTOBJ_ACTRFLG_THROTTLE300;
                else if(strcasecmp((const char*)entityFlag, (const char*)"throttle_400") == 0) *flags |= EGW_ACTOBJ_ACTRFLG_THROTTLE400;
                else if(strcasecmp((const char*)entityFlag, (const char*)"throttle_500") == 0) *flags |= EGW_ACTOBJ_ACTRFLG_THROTTLE500;
                else NSLog(@"egwAssetManager: egwGAMXParseFlags_Render: Failure parsing in manifest input file '%s', for asset '%s': Actuator flag '%s' not supported.", resourceFile, entityID, entityFlag);
            }
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"actuator_flags");
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// !!!: *** Glyphmap Parsers ***

// Parses <glyphmap source="external"> sections
void egwGAMXParseGlyphmap_External(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, egwAMGlyphSet* glyphmap, EGWuint* effects) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"glyphmap") == 0) {
        NSString* entityExternalFile = nil;
        EGWsingle entityFSize = 12.0f;
        const char* delims = " ,\t\r\n\0";
        
        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
        
        // external glyphmap read
        while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
            nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
            
            if(nodeType == 14) continue;
            else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"glyphmap") == 0) break;
            else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"url") == 0) {
                if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                    [entityExternalFile release]; entityExternalFile = nil;
                    entityExternalFile = [[NSString alloc] initWithUTF8String:(const char*)egwQTrimc((EGWchar*)nodeValue, -1)];
                }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"url");
            } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"size") == 0) {
                if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                    egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&entityFSize, 0, 1);
                    entityFSize = egwClampPosf(entityFSize);
                }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"size");
            } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"effects") == 0) {
                if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                    xmlChar* entityEffect = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                    for(entityEffect = (xmlChar*)strtok((char*)entityEffect, delims); entityEffect; entityEffect = (xmlChar*)strtok(NULL, delims)) {
                        if(strcasecmp((const char*)entityEffect, (const char*)"bold") == 0) *effects |= EGW_FONT_EFCT_BOLD;
                        else if(strcasecmp((const char*)entityEffect, (const char*)"italic") == 0) *effects |= EGW_FONT_EFCT_ITALIC;
                        else if(strcasecmp((const char*)entityEffect, (const char*)"upsidedown") == 0) *effects |= EGW_FONT_EFCT_UPSIDEDOWN;
                        else if(strcasecmp((const char*)entityEffect, (const char*)"backwards") == 0) *effects |= EGW_FONT_EFCT_BACKWARDS;
                        else if(strcasecmp((const char*)entityEffect, (const char*)"dpi72") == 0) *effects |= EGW_FONT_EFCT_DPI72;
                        else if(strcasecmp((const char*)entityEffect, (const char*)"dpi75") == 0) *effects |= EGW_FONT_EFCT_DPI75;
                        else if(strcasecmp((const char*)entityEffect, (const char*)"dpi96") == 0) *effects |= EGW_FONT_EFCT_DPI96;
                        else if(strcasecmp((const char*)entityEffect, (const char*)"dpi192") == 0) *effects |= EGW_FONT_EFCT_DPI192;
                        else NSLog(@"egwAssetManager: egwGAMXParseGlyphmap_External: Failure parsing in manifest input file '%s', for asset '%s': Rasterization effect '%s' not supported.", resourceFile, entityID, entityEffect);
                    }
                }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"effects");
            }
            
            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
            if(*retVal != 1) break;
        }
        
        if(*retVal == 1) {
            if(![egwSIAsstMngr loadGlyphMap:glyphmap fromFile:entityExternalFile withEffects:*effects pointSize:entityFSize])
                NSLog(@"egwAssetManager: egwGAMXParseGlyphmap_External: Failure parsing in manifest input file '%s', for asset '%s': Failure loading glyph map from external file '%s'.", resourceFile, entityID, entityExternalFile);
        }
        
        [entityExternalFile release]; entityExternalFile = nil;
        
        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"glyphmap");
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// !!!: *** Geometry Parsers ***

// Parses <geometry source="internal" type="vertex_array"> sections
void egwGAMXParseGeometry_STVA(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, egwSTVAMeshf* geometry) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"geometry") == 0) {
        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
        
        // vertex array read
        while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
            nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
            
            if(nodeType == 14) continue;
            else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"geometry") == 0) break;
            else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"vertices") == 0) {
                EGWuint vCount; xmlChar* entityCount = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"count");
                if(geometry->vCoords) { free((void*)geometry->vCoords); geometry->vCoords = NULL; }
                
                if(entityCount && egwParseStringuicv((EGWchar*)entityCount, (EGWuint*)&vCount, 0, 1) == 1) {
                    vCount = egwClampui(vCount, 1, EGW_UINT16_MAX); if(geometry->vCount == 0 || vCount < geometry->vCount) geometry->vCount = vCount;
                    if(geometry->vCoords = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)geometry->vCount)) {
                        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                            EGWuint nodesProcessed = egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)(geometry->vCoords), 0, geometry->vCount * 3);
                            if(nodesProcessed != geometry->vCount * 3) { // Pad rest with zeros if short
                                NSLog(@"egwAssetManager: egwGAMXParseSTVAMesh: Warning parsing in manifest input file '%s', for asset '%s': Total vertex values read %d does not match %d vertex values reported.", resourceFile, entityID, nodesProcessed, geometry->vCount * 3);
                                memset((void*)&(((EGWsingle*)(geometry->vCoords))[nodesProcessed]), 0, sizeof(EGWsingle) * ((geometry->vCount * 3) - nodesProcessed));
                            }
                        } else {
                            NSLog(@"egwAssetManager: egwGAMXParseSTVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Malformed vertices node.", resourceFile, entityID);
                            if(geometry->vCoords) { free((void*)geometry->vCoords); geometry->vCoords = NULL; }
                        }
                    } else NSLog(@"egwAssetManager: egwGAMXParseSTVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for vertex array.", resourceFile, entityID, ((EGWuint)sizeof(egwVector3f) * geometry->vCount));
                } else NSLog(@"egwAssetManager: egwGAMXParseSTVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Vertex count not specified.", resourceFile, entityID);
                
                if(entityCount) { xmlFree(entityCount); entityCount = NULL; }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"vertices");
            } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"normals") == 0) {
                EGWuint nCount; xmlChar* entityCount = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"count");
                if(geometry->nCoords) { free((void*)geometry->nCoords); geometry->nCoords = NULL; }
                
                if(entityCount && egwParseStringuicv((EGWchar*)entityCount, (EGWuint*)&nCount, 0, 1) == 1) {
                    nCount = egwClampui(nCount, 1, EGW_UINT16_MAX); if(geometry->vCount == 0 || nCount < geometry->vCount) geometry->vCount = nCount;
                    if(geometry->nCoords = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)geometry->vCount)) {
                        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                            EGWuint nodesProcessed = egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)(geometry->nCoords), 0, geometry->vCount * 3);
                            if(nodesProcessed != geometry->vCount * 3) { // Pad rest with zeros if short
                                NSLog(@"egwAssetManager: egwGAMXParseSTVAMesh: Warning parsing in manifest input file '%s', for asset '%s': Total normal values read %d does not match %d normal values reported.", resourceFile, entityID, nodesProcessed, geometry->vCount * 3);
                                memset((void*)&(((EGWsingle*)(geometry->nCoords))[nodesProcessed]), 0, sizeof(EGWsingle) * ((geometry->vCount * 3) - nodesProcessed));
                            }
                        } else {
                            NSLog(@"egwAssetManager: egwGAMXParseSTVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Malformed normals node.", resourceFile, entityID);
                            if(geometry->nCoords) { free((void*)geometry->nCoords); geometry->nCoords = NULL; geometry->vCount = 0; }
                        }
                    } else NSLog(@"egwAssetManager: egwGAMXParseSTVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for normal array.", resourceFile, entityID, ((EGWuint)sizeof(egwVector3f) * geometry->vCount));
                } else NSLog(@"egwAssetManager: egwGAMXParseSTVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Normal count not specified.", resourceFile, entityID);
                
                if(entityCount) { xmlFree(entityCount); entityCount = NULL; }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"normals");
            } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"texuvs") == 0) {
                EGWuint tCount; xmlChar* entityCount = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"count");
                if(geometry->tCoords) { free((void*)geometry->tCoords); geometry->tCoords = NULL; }
                
                if(entityCount && egwParseStringuicv((EGWchar*)entityCount, (EGWuint*)&tCount, 0, 1) == 1) {
                    tCount = egwClampui(tCount, 1, EGW_UINT16_MAX); if(geometry->vCount == 0 || tCount < geometry->vCount) geometry->vCount = tCount;
                    if(geometry->tCoords = (egwVector2f*)malloc(sizeof(egwVector2f) * (size_t)geometry->vCount)) {
                        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                            EGWuint nodesProcessed = egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)(geometry->tCoords), 0, geometry->vCount * 2);
                            if(nodesProcessed != geometry->vCount * 2) { // Pad rest with zeros if short
                                NSLog(@"egwAssetManager: egwGAMXParseSTVAMesh: Warning parsing in manifest input file '%s', for asset '%s': Total texture UV values read %d does not match %d texture UV values reported.", resourceFile, entityID, nodesProcessed, geometry->vCount * 2);
                                memset((void*)&(((EGWsingle*)(geometry->tCoords))[nodesProcessed]), 0, sizeof(EGWsingle) * ((geometry->vCount * 2) - nodesProcessed));
                            }
                        } else {
                            NSLog(@"egwAssetManager: egwGAMXParseSTVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Malformed texuvs node.", resourceFile, entityID);
                            if(geometry->tCoords) { free((void*)geometry->tCoords); geometry->tCoords = NULL; }
                        }
                    } else NSLog(@"egwAssetManager: egwGAMXParseSTVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for texture UV array.", resourceFile, entityID, ((EGWuint)sizeof(egwVector2f) * geometry->vCount));
                } else NSLog(@"egwAssetManager: egwGAMXParseSTVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Texture UV count not specified.", resourceFile, entityID);
                
                if(entityCount) { xmlFree(entityCount); entityCount = NULL; }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"texuvs");
            }
            
            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
            if(*retVal != 1) break;
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"geometry");
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// Parses <geometry source="internal" type="joint_indexed_vertex_array"> sections
void egwGAMXParseGeometry_SJITVA(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, egwSJITVAMeshf* geometry) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"geometry") == 0) {
        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
        
        // joint indexed vertex array read
        while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
            nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
            
            if(nodeType == 14) continue;
            else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"geometry") == 0) break;
            else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"vertices") == 0) {
                EGWuint vCount; xmlChar* entityCount = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"count");
                if(geometry->vCoords) { free((void*)geometry->vCoords); geometry->vCoords = NULL; }
                
                if(entityCount && egwParseStringuicv((EGWchar*)entityCount, (EGWuint*)&vCount, 0, 1) == 1) {
                    vCount = egwClampui(vCount, 1, EGW_UINT16_MAX); if(geometry->vCount == 0 || vCount < geometry->vCount) geometry->vCount = vCount;
                    if(geometry->vCoords = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)geometry->vCount)) {
                        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                            EGWuint nodesProcessed = egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)(geometry->vCoords), 0, geometry->vCount * 3);
                            if(nodesProcessed != geometry->vCount * 3) { // Pad rest with zeros if short
                                NSLog(@"egwAssetManager: egwGAMXParseSJITVAMesh: Warning parsing in manifest input file '%s', for asset '%s': Total vertex values read %d does not match %d vertex values reported.", resourceFile, entityID, nodesProcessed, geometry->vCount * 3);
                                memset((void*)&(((EGWsingle*)(geometry->vCoords))[nodesProcessed]), 0, sizeof(EGWsingle) * ((geometry->vCount * 3) - nodesProcessed));
                            }
                        } else {
                            NSLog(@"egwAssetManager: egwGAMXParseSJITVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Malformed vertices node.", resourceFile, entityID);
                            if(geometry->vCoords) { free((void*)geometry->vCoords); geometry->vCoords = NULL; }
                        }
                    } else NSLog(@"egwAssetManager: egwGAMXParseSJITVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for vertex array.", resourceFile, entityID, ((EGWuint)sizeof(egwVector3f) * geometry->vCount));
                } else NSLog(@"egwAssetManager: egwGAMXParseSJITVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Vertex count not specified.", resourceFile, entityID);
                
                if(entityCount) { xmlFree(entityCount); entityCount = NULL; }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"vertices");
            } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"normals") == 0) {
                EGWuint nCount; xmlChar* entityCount = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"count");
                if(geometry->nCoords) { free((void*)geometry->nCoords); geometry->nCoords = NULL; }
                
                if(entityCount && egwParseStringuicv((EGWchar*)entityCount, (EGWuint*)&nCount, 0, 1) == 1) {
                    nCount = egwClampui(nCount, 1, EGW_UINT16_MAX); if(geometry->vCount == 0 || nCount < geometry->vCount) geometry->vCount = nCount;
                    if(geometry->nCoords = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)geometry->vCount)) {
                        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                            EGWuint nodesProcessed = egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)(geometry->nCoords), 0, geometry->vCount * 3);
                            if(nodesProcessed != geometry->vCount * 3) { // Pad rest with zeros if short
                                NSLog(@"egwAssetManager: egwGAMXParseSJITVAMesh: Warning parsing in manifest input file '%s', for asset '%s': Total normal values read %d does not match %d normal values reported.", resourceFile, entityID, nodesProcessed, geometry->vCount * 3);
                                memset((void*)&(((EGWsingle*)(geometry->nCoords))[nodesProcessed]), 0, sizeof(EGWsingle) * ((geometry->vCount * 3) - nodesProcessed));
                            }
                        } else {
                            NSLog(@"egwAssetManager: egwGAMXParseSJITVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Malformed normals node.", resourceFile, entityID);
                            if(geometry->nCoords) { free((void*)geometry->nCoords); geometry->nCoords = NULL; geometry->vCount = 0; }
                        }
                    } else NSLog(@"egwAssetManager: egwGAMXParseSJITVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for normal array.", resourceFile, entityID, ((EGWuint)sizeof(egwVector3f) * geometry->vCount));
                } else NSLog(@"egwAssetManager: egwGAMXParseSJITVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Normal count not specified.", resourceFile, entityID);
                
                if(entityCount) { xmlFree(entityCount); entityCount = NULL; }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"normals");
            } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"texuvs") == 0) {
                EGWuint tCount; xmlChar* entityCount = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"count");
                if(geometry->tCoords) { free((void*)geometry->tCoords); geometry->tCoords = NULL; }
                
                if(entityCount && egwParseStringuicv((EGWchar*)entityCount, (EGWuint*)&tCount, 0, 1) == 1) {
                    tCount = egwClampui(tCount, 1, EGW_UINT16_MAX); if(geometry->vCount == 0 || tCount < geometry->vCount) geometry->vCount = tCount;
                    if(geometry->tCoords = (egwVector2f*)malloc(sizeof(egwVector2f) * (size_t)geometry->vCount)) {
                        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                            EGWuint nodesProcessed = egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)(geometry->tCoords), 0, geometry->vCount * 2);
                            if(nodesProcessed != geometry->vCount * 2) { // Pad rest with zeros if short
                                NSLog(@"egwAssetManager: egwGAMXParseSJITVAMesh: Warning parsing in manifest input file '%s', for asset '%s': Total texture UV values read %d does not match %d texture UV values reported.", resourceFile, entityID, nodesProcessed, geometry->vCount * 2);
                                memset((void*)&(((EGWsingle*)(geometry->tCoords))[nodesProcessed]), 0, sizeof(EGWsingle) * ((geometry->vCount * 2) - nodesProcessed));
                            }
                        } else {
                            NSLog(@"egwAssetManager: egwGAMXParseSJITVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Malformed texuvs node.", resourceFile, entityID);
                            if(geometry->tCoords) { free((void*)geometry->tCoords); geometry->tCoords = NULL; }
                        }
                    } else NSLog(@"egwAssetManager: egwGAMXParseSJITVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for texture UV array.", resourceFile, entityID, ((EGWuint)sizeof(egwVector2f) * geometry->vCount));
                } else NSLog(@"egwAssetManager: egwGAMXParseSJITVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Texture UV count not specified.", resourceFile, entityID);
                
                if(entityCount) { xmlFree(entityCount); entityCount = NULL; }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"texuvs");
            } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"faces") == 0) {
                EGWuint fCount; xmlChar* entityCount = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"count");
                if(geometry->fIndicies) { free((void*)geometry->fIndicies); geometry->fIndicies = NULL; geometry->fCount = 0; }
                
                if(entityCount && egwParseStringuicv((EGWchar*)entityCount, (EGWuint*)&fCount, 0, 1) == 1) {
                    geometry->fCount = egwClampui(fCount, 1, EGW_UINT16_MAX);
                    if(geometry->fIndicies = (egwJITFace*)malloc(sizeof(egwJITFace) * (size_t)geometry->fCount)) {
                        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                            EGWuint nodesProcessed = egwParseStringui16cv((EGWchar*)nodeValue, (EGWuint16*)(geometry->fIndicies), 0, geometry->fCount * 3);
                            if(nodesProcessed != geometry->fCount * 3) { // Pad rest with zeros if short
                                NSLog(@"egwAssetManager: egwGAMXParseSJITVAMesh: Warning parsing in manifest input file '%s', for asset '%s': Total face values read %d does not match %d face values reported. Filled remaining buffer with zeros.", resourceFile, entityID, nodesProcessed, geometry->fCount * 3);
                                memset((void*)&(((EGWsingle*)(geometry->fIndicies))[nodesProcessed]), 0, sizeof(EGWuint16) * ((geometry->fCount * 3) - nodesProcessed));
                            }
                        } else {
                            NSLog(@"egwAssetManager: egwGAMXParseSJITVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Malformed faces node.", resourceFile, entityID);
                            if(geometry->fIndicies) { free((void*)geometry->fIndicies); geometry->fIndicies = NULL; geometry->fCount = 0; }
                        }
                    } else NSLog(@"egwAssetManager: egwGAMXParseSJITVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for face indicies.", resourceFile, entityID, ((EGWuint)sizeof(egwJITFace) * geometry->fCount));
                } else NSLog(@"egwAssetManager: egwGAMXParseSJITVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Face indicies count not specified.", resourceFile, entityID);
                
                if(entityCount) { xmlFree(entityCount); entityCount = NULL; }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"faces");
            }
            
            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
            if(*retVal != 1) break;
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"geometry");
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// Parses <geometry source="internal" type="disjoint_indexed_vertex_array"> sections
void egwGAMXParseGeometry_SDITVA(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, egwSDITVAMeshf* geometry) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"geometry") == 0) {
        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
        
        // disjoint indexed vertex array read
        while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
            nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
            
            if(nodeType == 14) continue;
            else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"geometry") == 0) break;
            else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"vertices") == 0) {
                EGWuint vCount; xmlChar* entityCount = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"count");
                if(geometry->vCoords) { free((void*)geometry->vCoords); geometry->vCoords = NULL; geometry->vCount = 0; }
                
                if(entityCount && egwParseStringuicv((EGWchar*)entityCount, (EGWuint*)&vCount, 0, 1) == 1) {
                    vCount = egwClampui(vCount, 1, EGW_UINT16_MAX); if(geometry->vCount == 0 || vCount < geometry->vCount) geometry->vCount = vCount;
                    if(geometry->vCoords = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)geometry->vCount)) {
                        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                            EGWuint nodesProcessed = egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)(geometry->vCoords), 0, geometry->vCount * 3);
                            if(nodesProcessed != geometry->vCount * 3) { // Pad rest with zeros if short
                                NSLog(@"egwAssetManager: egwGAMXParseSDITVAMesh: Warning parsing in manifest input file '%s', for asset '%s': Total vertex values read %d does not match %d vertex values reported.", resourceFile, entityID, nodesProcessed, geometry->vCount * 3);
                                memset((void*)&(((EGWsingle*)(geometry->vCoords))[nodesProcessed]), 0, sizeof(EGWsingle) * ((geometry->vCount * 3) - nodesProcessed));
                            }
                        } else {
                            NSLog(@"egwAssetManager: egwGAMXParseSDITVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Malformed vertices node.", resourceFile, entityID);
                            if(geometry->vCoords) { free((void*)geometry->vCoords); geometry->vCoords = NULL; geometry->vCount = 0; }
                        }
                    } else NSLog(@"egwAssetManager: egwGAMXParseSDITVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for vertex array.", resourceFile, entityID, ((EGWuint)sizeof(egwVector3f) * geometry->vCount));
                } else NSLog(@"egwAssetManager: egwGAMXParseSDITVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Vertex count not specified.", resourceFile, entityID);
                
                if(entityCount) { xmlFree(entityCount); entityCount = NULL; }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"vertices");
            } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"normals") == 0) {
                EGWuint nCount; xmlChar* entityCount = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"count");
                if(geometry->nCoords) { free((void*)geometry->nCoords); geometry->nCoords = NULL; geometry->nCount = 0; }
                
                if(entityCount && egwParseStringuicv((EGWchar*)entityCount, (EGWuint*)&nCount, 0, 1) == 1) {
                    nCount = egwClampui(nCount, 1, EGW_UINT16_MAX); if(geometry->nCount == 0 || nCount < geometry->nCount) geometry->nCount = nCount;
                    if(geometry->nCoords = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)geometry->nCount)) {
                        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                            EGWuint nodesProcessed = egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)(geometry->nCoords), 0, geometry->nCount * 3);
                            if(nodesProcessed != geometry->nCount * 3) { // Pad rest with zeros if short
                                NSLog(@"egwAssetManager: egwGAMXParseSDITVAMesh: Warning parsing in manifest input file '%s', for asset '%s': Total normal values read %d does not match %d normal values reported.", resourceFile, entityID, nodesProcessed, geometry->nCount * 3);
                                memset((void*)&(((EGWsingle*)(geometry->nCoords))[nodesProcessed]), 0, sizeof(EGWsingle) * ((geometry->nCount * 3) - nodesProcessed));
                            }
                        } else {
                            NSLog(@"egwAssetManager: egwGAMXParseSDITVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Malformed normals node.", resourceFile, entityID);
                            if(geometry->nCoords) { free((void*)geometry->nCoords); geometry->nCoords = NULL; geometry->nCount = 0; }
                        }
                    } else NSLog(@"egwAssetManager: egwGAMXParseSDITVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for normal array.", resourceFile, entityID, ((EGWuint)sizeof(egwVector3f) * geometry->nCount));
                } else NSLog(@"egwAssetManager: egwGAMXParseSDITVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Normal count not specified.", resourceFile, entityID);
                
                if(entityCount) { xmlFree(entityCount); entityCount = NULL; }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"normals");
            } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"texuvs") == 0) {
                EGWuint tCount; xmlChar* entityCount = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"count");
                if(geometry->tCoords) { free((void*)geometry->tCoords); geometry->tCoords = NULL; geometry->tCount = 0; }
                
                if(entityCount && egwParseStringuicv((EGWchar*)entityCount, (EGWuint*)&tCount, 0, 1) == 1) {
                    tCount = egwClampui(tCount, 1, EGW_UINT16_MAX); if(geometry->tCount == 0 || tCount < geometry->tCount) geometry->tCount = tCount;
                    if(geometry->tCoords = (egwVector2f*)malloc(sizeof(egwVector2f) * (size_t)geometry->tCount)) {
                        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                            EGWuint nodesProcessed = egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)(geometry->tCoords), 0, geometry->tCount * 2);
                            if(nodesProcessed != geometry->tCount * 2) { // Pad rest with zeros if short
                                NSLog(@"egwAssetManager: egwGAMXParseSDITVAMesh: Warning parsing in manifest input file '%s', for asset '%s': Total texture UV values read %d does not match %d texture UV values reported.", resourceFile, entityID, nodesProcessed, geometry->tCount * 2);
                                memset((void*)&(((EGWsingle*)(geometry->tCoords))[nodesProcessed]), 0, sizeof(EGWsingle) * ((geometry->tCount * 2) - nodesProcessed));
                            }
                        } else {
                            NSLog(@"egwAssetManager: egwGAMXParseSDITVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Malformed texuvs node.", resourceFile, entityID);
                            if(geometry->tCoords) { free((void*)geometry->tCoords); geometry->tCoords = NULL; geometry->tCount = 0; }
                        }
                    } else NSLog(@"egwAssetManager: egwGAMXParseSDITVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for texture UV array.", resourceFile, entityID, ((EGWuint)sizeof(egwVector2f) * geometry->tCount));
                } else NSLog(@"egwAssetManager: egwGAMXParseSDITVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Texture UV count not specified.", resourceFile, entityID);
                
                if(entityCount) { xmlFree(entityCount); entityCount = NULL; }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"texuvs");
            } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"faces") == 0) {
                EGWuint fCount; xmlChar* entityCount = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"count");
                if(geometry->fIndicies) { free((void*)geometry->fIndicies); geometry->fIndicies = NULL; geometry->fCount = 0; }
                
                if(entityCount && egwParseStringuicv((EGWchar*)entityCount, (EGWuint*)&fCount, 0, 1) == 1) {
                    geometry->fCount = egwClampui(fCount, 1, EGW_UINT16_MAX);
                    if(geometry->fIndicies = (egwDITFace*)malloc(sizeof(egwDITFace) * (size_t)geometry->fCount)) {
                        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                            EGWuint nodesProcessed = egwParseStringui16cv((EGWchar*)nodeValue, (EGWuint16*)(geometry->fIndicies), 0, geometry->fCount * 9);
                            if(nodesProcessed == geometry->fCount * 6 && geometry->tCount == 0) { // texcoord shuffle
                                EGWuint16* nAdr = (EGWuint16*)((EGWuintptr)(geometry->fIndicies) + ((EGWuintptr)sizeof(EGWuint16) * (EGWuintptr)((geometry->fCount-1) * 9)));
                                EGWuint16* oAdr = (EGWuint16*)((EGWuintptr)(geometry->fIndicies) + ((EGWuintptr)sizeof(EGWuint16) * (EGWuintptr)((geometry->fCount-1) * 6)));
                                
                                while((EGWuintptr)nAdr >= (EGWuintptr)oAdr) { // these will cross at fIndicies
                                    nAdr[0] = oAdr[0]; nAdr[3] = oAdr[2]; nAdr[6] = oAdr[4]; // vert indicies
                                    nAdr[1] = oAdr[1]; nAdr[4] = oAdr[3]; nAdr[7] = oAdr[5]; // normal indicies
                                    nAdr[2] = 0; nAdr[5] = 0; nAdr[8] = 0; // texture indicies
                                    
                                    nAdr = (EGWuint16*)((EGWuintptr)nAdr - (EGWuintptr)(sizeof(EGWuint16) * 9));
                                    oAdr = (EGWuint16*)((EGWuintptr)oAdr - (EGWuintptr)(sizeof(EGWuint16) * 6));
                                }
                                
                                NSLog(@"egwAssetManager: egwGAMXParseSDITVAMesh: Warning parsing in manifest input file '%s', for asset '%s': Total face values read %d does not match %d face values reported. Reshuffled & dropped texture UV indicies to correct.", resourceFile, entityID, nodesProcessed, geometry->fCount * 9);
                            } else if(nodesProcessed != geometry->fCount * 9) { // Pad rest with zeros if short
                                NSLog(@"egwAssetManager: egwGAMXParseSDITVAMesh: Warning parsing in manifest input file '%s', for asset '%s': Total face values read %d does not match %d face values reported. Filled remaining buffer with zeros.", resourceFile, entityID, nodesProcessed, geometry->fCount * 9);
                                memset((void*)&(((EGWsingle*)(geometry->fIndicies))[nodesProcessed]), 0, sizeof(EGWuint16) * ((geometry->fCount * 9) - nodesProcessed));
                            }
                        } else {
                            NSLog(@"egwAssetManager: egwGAMXParseSDITVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Malformed faces node.", resourceFile, entityID);
                            if(geometry->fIndicies) { free((void*)geometry->fIndicies); geometry->fIndicies = NULL; geometry->fCount = 0; }
                        }
                    } else NSLog(@"egwAssetManager: egwGAMXParseSDITVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for face indicies.", resourceFile, entityID, ((EGWuint)sizeof(egwDITFace) * geometry->fCount));
                } else NSLog(@"egwAssetManager: egwGAMXParseSDITVAMesh: Failure parsing in manifest input file '%s', for asset '%s': Face indicies count not specified.", resourceFile, entityID);
                
                if(entityCount) { xmlFree(entityCount); entityCount = NULL; }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"faces");
            }
            
            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
            if(*retVal != 1) break;
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"geometry");
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// Parses <storage>/<base_storage> sections, pre cursor should be on <storage>/<base_storage>, post cursor on </storage>/<base_storage>, works with current values
void egwGAMXParseGeometry_Storage(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* storage) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasestr((const char*)nodeName, (const char*)"storage")) {
        const char* delims = " ,\t\r\n\0";
        
        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
            xmlChar* entityStrg = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
            for(entityStrg = (xmlChar*)strtok((char*)entityStrg, delims); entityStrg; entityStrg = (xmlChar*)strtok(NULL, delims)) {
                if(strcasecmp((const char*)entityStrg, (const char*)"vbo_static") == 0) *storage |= EGW_GEOMETRY_STRG_VBOSTATIC;
                else if(strcasecmp((const char*)entityStrg, (const char*)"vbo_dynamic") == 0) *storage |= EGW_GEOMETRY_STRG_VBODYNAMIC;
                else NSLog(@"egwAssetManager: egwGAMXParseGeometry_Storage: Failure parsing in manifest input file '%s', for asset '%s': Geometry storage/VBO setting '%s' not supported.", resourceFile, entityID, entityStrg);
            }
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, nodeName);
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// !!!: *** Keyframe Parsers ***

// Parses <channel_format> sections inside of <keyframe> sections
void egwGAMXParseKeyFrames_ChFormat(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint16* format) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"channel_format") == 0) {
        const char* delims = " ,\t\r\n\0";
        
        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
            xmlChar* entityFrmt = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
            for(entityFrmt = (xmlChar*)strtok((char*)entityFrmt, delims); entityFrmt; entityFrmt = (xmlChar*)strtok(NULL, delims)) {
                if(strcasecmp((const char*)entityFrmt, (const char*)"uint8") == 0) *format |= EGW_KEYCHANNEL_FRMT_UINT8;
                else if(strcasecmp((const char*)entityFrmt, (const char*)"uint16") == 0) *format |= EGW_KEYCHANNEL_FRMT_UINT16;
                else if(strcasecmp((const char*)entityFrmt, (const char*)"uint32") == 0) *format |= EGW_KEYCHANNEL_FRMT_UINT32;
                else if(strcasecmp((const char*)entityFrmt, (const char*)"int8") == 0) *format |= EGW_KEYCHANNEL_FRMT_INT8;
                else if(strcasecmp((const char*)entityFrmt, (const char*)"int16") == 0) *format |= EGW_KEYCHANNEL_FRMT_INT16;
                else if(strcasecmp((const char*)entityFrmt, (const char*)"int32") == 0) *format |= EGW_KEYCHANNEL_FRMT_INT32;
                else if(strcasecmp((const char*)entityFrmt, (const char*)"single") == 0) *format |= EGW_KEYCHANNEL_FRMT_SINGLE;
                else if(strcasecmp((const char*)entityFrmt, (const char*)"double") == 0) *format |= EGW_KEYCHANNEL_FRMT_DOUBLE;
                else if(strcasecmp((const char*)entityFrmt, (const char*)"triple") == 0) *format |= EGW_KEYCHANNEL_FRMT_TRIPLE;
                else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_ChFormat: Failure parsing in manifest input file '%s', for asset '%s': Keyframes channel format '%s' not supported.", resourceFile, entityID, entityFrmt);
            }
        }
        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"channel_format");
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// Parses <XXXpolation> sections inside of <interpolator> sections
void egwGAMXParseKeyFrames_Polation(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint32* polation) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasestr((const char*)nodeName, (const char*)"polation")) {
        const char* delims = " ,\t\r\n\0";
        
        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
            xmlChar* entityPltn = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
            for(entityPltn = (xmlChar*)strtok((char*)entityPltn, delims); entityPltn; entityPltn = (xmlChar*)strtok(NULL, delims)) {
                if(strcasecmp((const char*)entityPltn, (const char*)"ipo_const") == 0) *polation |= EGW_POLATION_IPO_CONST;
                else if(strcasecmp((const char*)entityPltn, (const char*)"ipo_linear") == 0) *polation |= EGW_POLATION_IPO_LINEAR;
                else if(strcasecmp((const char*)entityPltn, (const char*)"ipo_slerp") == 0) *polation |= EGW_POLATION_IPO_SLERP;
                else if(strcasecmp((const char*)entityPltn, (const char*)"ipo_cubiccr") == 0) *polation |= EGW_POLATION_IPO_CUBICCR;
                else if(strcasecmp((const char*)entityPltn, (const char*)"epo_const") == 0) *polation |= EGW_POLATION_EPO_CONST;
                else if(strcasecmp((const char*)entityPltn, (const char*)"epo_linear") == 0) *polation |= EGW_POLATION_EPO_LINEAR;
                else if(strcasecmp((const char*)entityPltn, (const char*)"epo_cyclic") == 0) *polation |= EGW_POLATION_EPO_CYCLIC;
                else if(strcasecmp((const char*)entityPltn, (const char*)"epo_cyclicadd") == 0) *polation |= EGW_POLATION_EPO_CYCADD;
                else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_Polation: Failure parsing in manifest input file '%s', for asset '%s': Keyframes polation format '%s' not supported.", resourceFile, entityID, entityPltn);
            }
        }
        egwGAMXParseSkip(xmlReadHandle, retVal, nodeName);
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// Parses <keyframes source="internal" type="value_array"> sections
void egwGAMXParseKeyFrames_VA(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, egwKeyFrame* frames) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"keyframes") == 0) {
        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
        
        // value array read
        while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
            nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
            
            if(nodeType == 14) continue;
            else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"keyframes") == 0) break;
            else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"time_indicies") == 0) {
                EGWuint iCount; xmlChar* entityCount = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"count");
                if(frames->tIndicies) { free((void*)frames->tIndicies); frames->tIndicies = NULL; }
                
                if(entityCount && egwParseStringuicv((EGWchar*)entityCount, (EGWuint*)&iCount, 0, 1) == 1) {
                    iCount = egwClampui(iCount, 1, EGW_UINT16_MAX); if(frames->fCount == 0 || iCount < frames->fCount) frames->fCount = iCount;
                    if(frames->tIndicies = (EGWtime*)malloc(sizeof(EGWtime) * (size_t)(frames->fCount))) {
                        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                            EGWuint nodesProcessed = 0;
                            
                            if(sizeof(EGWtime) == sizeof(EGWsingle)) nodesProcessed = egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)(frames->tIndicies), 0, (EGWuint)(frames->fCount));
                            else if(sizeof(EGWtime) == sizeof(EGWdouble)) nodesProcessed = egwParseStringdcv((EGWchar*)nodeValue, (EGWdouble*)(frames->tIndicies), 0, (EGWuint)(frames->fCount));
                            else if(sizeof(EGWtime) == sizeof(EGWtriple)) nodesProcessed = egwParseStringtcv((EGWchar*)nodeValue, (EGWtriple*)(frames->tIndicies), 0, (EGWuint)(frames->fCount));
                            
                            if(nodesProcessed != (EGWuint)(frames->fCount)) { // Pad rest with zeros if short
                                NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_VA: Warning parsing in manifest input file '%s', for asset '%s': Total time indicies read %d does not match %d time indicies reported.", resourceFile, entityID, nodesProcessed, (EGWuint)(frames->fCount));
                                memset((void*)&(frames->tIndicies[nodesProcessed]), 0, sizeof(EGWtime) * (size_t)((EGWuint)(frames->fCount) - nodesProcessed));
                            }
                        } else {
                            NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_VA: Failure parsing in manifest input file '%s', for asset '%s': Malformed time indicies node.", resourceFile, entityID);
                            if(frames->tIndicies) { free((void*)frames->tIndicies); frames->tIndicies = NULL; }
                        }
                    } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_VA: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for time indicies array.", resourceFile, entityID, ((EGWuint)sizeof(EGWtime) * (EGWuint)(frames->fCount)));
                } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_VA: Failure parsing in manifest input file '%s', for asset '%s': Time indicies count not specified.", resourceFile, entityID);
                
                if(entityCount) { xmlFree(entityCount); entityCount = NULL; }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"time_indicies");
            } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"key_values") == 0) {
                EGWuint kCount; xmlChar* entityCount = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"count");
                EGWuint cmpCount; xmlChar* entityComponents = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"components");
                EGWuint chnCount; xmlChar* entityChannels = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"channels");
                if(frames->fKeys) { free((void*)frames->fKeys); frames->fKeys = NULL; frames->cCount = frames->kcCount = frames->kcFormat = 0; }
                
                if(entityCount && egwParseStringuicv((EGWchar*)entityCount, (EGWuint*)&kCount, 0, 1) == 1 &&
                   ((!entityComponents && (cmpCount = 1)) || (entityComponents && egwParseStringuicv((EGWchar*)entityComponents, (EGWuint*)&cmpCount, 0, 1) == 1)) &&
                   ((!entityChannels && (chnCount = 1)) || (entityChannels && egwParseStringuicv((EGWchar*)entityChannels, (EGWuint*)&chnCount, 0, 1) == 1))) {
                    xmlChar* entityFormat = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"format");
                    EGWuint nodesProcessed = 0, entityPitch = 0;
                    
                    kCount = egwClampui(kCount, 1, EGW_UINT16_MAX); if(frames->fCount == 0 || kCount < frames->fCount) frames->fCount = kCount;
                    cmpCount = egwClampui(cmpCount, 1, EGW_UINT16_MAX); frames->cCount = cmpCount;
                    chnCount = egwClampui(chnCount, 1, EGW_UINT16_MAX); frames->kcCount = chnCount;
                    
                    frames->kcFormat = 0;
                    if(!entityFormat || strcasecmp((const char*)entityFormat, (const char*)"single") == 0) {
                        frames->kcFormat = EGW_KEYCHANNEL_FRMT_SINGLE; entityPitch = (EGWuint)(frames->kcFormat & EGW_KEYCHANNEL_FRMT_EXBPC) * (EGWuint)(frames->kcCount);
                        if(frames->fKeys = (EGWbyte*)malloc((size_t)entityPitch * (size_t)(frames->fCount))) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                nodesProcessed = egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)(frames->fKeys), 0, ((EGWuint)(frames->fCount) * (EGWuint)(frames->cCount) * (EGWuint)(frames->kcCount)));
                            } else {
                                NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_VA: Failure parsing in manifest input file '%s', for asset '%s': Malformed key values node.", resourceFile, entityID);
                                if(frames->fKeys) { free((void*)frames->fKeys); frames->fKeys = NULL; frames->cCount = frames->kcCount = frames->kcFormat = 0; }
                            }
                        } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_VA: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for key values array.", resourceFile, entityID, ((EGWuint)entityPitch * (EGWuint)(frames->fCount)));
                    } else if(entityFormat && (strcasecmp((const char*)entityFormat, (const char*)"int") == 0 || strcasecmp((const char*)entityFormat, (const char*)"int32") == 0)) {
                        frames->kcFormat = EGW_KEYCHANNEL_FRMT_INT32;
                        entityPitch = (EGWuint)(frames->kcFormat & EGW_KEYCHANNEL_FRMT_EXBPC) * (EGWuint)(frames->kcCount) * (EGWuint)(frames->cCount);
                        if(frames->fKeys = (EGWbyte*)malloc((size_t)entityPitch * (size_t)(frames->fCount))) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                nodesProcessed = egwParseStringi32cv((EGWchar*)nodeValue, (EGWint32*)(frames->fKeys), 0, ((EGWuint)(frames->fCount) * (EGWuint)(frames->cCount) * (EGWuint)(frames->kcCount)));
                            } else {
                                NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_VA: Failure parsing in manifest input file '%s', for asset '%s': Malformed key values node.", resourceFile, entityID);
                                if(frames->fKeys) { free((void*)frames->fKeys); frames->fKeys = NULL; frames->cCount = frames->kcCount = frames->kcFormat = 0; }
                            }
                        } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_VA: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for key values array.", resourceFile, entityID, ((EGWuint)entityPitch * (EGWuint)(frames->fCount)));
                    } else if(entityFormat && (strcasecmp((const char*)entityFormat, (const char*)"uint") == 0 || strcasecmp((const char*)entityFormat, (const char*)"uint32") == 0)) {
                        frames->kcFormat = EGW_KEYCHANNEL_FRMT_UINT32;
                        entityPitch = (EGWuint)(frames->kcFormat & EGW_KEYCHANNEL_FRMT_EXBPC) * (EGWuint)(frames->kcCount) * (EGWuint)(frames->cCount);
                        if(frames->fKeys = (EGWbyte*)malloc((size_t)entityPitch * (size_t)(frames->fCount))) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                nodesProcessed = egwParseStringui32cv((EGWchar*)nodeValue, (EGWuint32*)(frames->fKeys), 0, ((EGWuint)(frames->fCount) * (EGWuint)(frames->cCount) * (EGWuint)(frames->kcCount)));
                            } else {
                                NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_VA: Failure parsing in manifest input file '%s', for asset '%s': Malformed key values node.", resourceFile, entityID);
                                if(frames->fKeys) { free((void*)frames->fKeys); frames->fKeys = NULL; frames->cCount = frames->kcCount = frames->kcFormat = 0; }
                            }
                        } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_VA: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for key values array.", resourceFile, entityID, ((EGWuint)entityPitch * (EGWuint)(frames->fCount)));
                    } else if(entityFormat && strcasecmp((const char*)entityFormat, (const char*)"double") == 0) {
                        frames->kcFormat = EGW_KEYCHANNEL_FRMT_DOUBLE;
                        entityPitch = (EGWuint)(frames->kcFormat & EGW_KEYCHANNEL_FRMT_EXBPC) * (EGWuint)(frames->kcCount) * (EGWuint)(frames->cCount);
                        if(frames->fKeys = (EGWbyte*)malloc((size_t)entityPitch * (size_t)(frames->fCount))) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                nodesProcessed = egwParseStringdcv((EGWchar*)nodeValue, (EGWdouble*)(frames->fKeys), 0, ((EGWuint)(frames->fCount) * (EGWuint)(frames->cCount) * (EGWuint)(frames->kcCount)));
                            } else {
                                NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_VA: Failure parsing in manifest input file '%s', for asset '%s': Malformed key values node.", resourceFile, entityID);
                                if(frames->fKeys) { free((void*)frames->fKeys); frames->fKeys = NULL; frames->cCount = frames->kcCount = frames->kcFormat = 0; }
                            }
                        } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_VA: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for key values array.", resourceFile, entityID, ((EGWuint)entityPitch * (EGWuint)(frames->fCount)));
                    } else if(entityFormat && strcasecmp((const char*)entityFormat, (const char*)"uint16") == 0) {
                        frames->kcFormat = EGW_KEYCHANNEL_FRMT_UINT16;
                        entityPitch = (EGWuint)(frames->kcFormat & EGW_KEYCHANNEL_FRMT_EXBPC) * (EGWuint)(frames->kcCount) * (EGWuint)(frames->cCount);
                        if(frames->fKeys = (EGWbyte*)malloc((size_t)entityPitch * (size_t)(frames->fCount))) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                nodesProcessed = egwParseStringui16cv((EGWchar*)nodeValue, (EGWuint16*)(frames->fKeys), 0, ((EGWuint)(frames->fCount) * (EGWuint)(frames->cCount) * (EGWuint)(frames->kcCount)));
                            } else {
                                NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_VA: Failure parsing in manifest input file '%s', for asset '%s': Malformed key values node.", resourceFile, entityID);
                                if(frames->fKeys) { free((void*)frames->fKeys); frames->fKeys = NULL; frames->cCount = frames->kcCount = frames->kcFormat = 0; }
                            }
                        } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_VA: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for key values array.", resourceFile, entityID, ((EGWuint)entityPitch * (EGWuint)(frames->fCount)));
                    } else if(entityFormat && strcasecmp((const char*)entityFormat, (const char*)"int16") == 0) {
                        frames->kcFormat = EGW_KEYCHANNEL_FRMT_INT16;
                        entityPitch = (EGWuint)(frames->kcFormat & EGW_KEYCHANNEL_FRMT_EXBPC) * (EGWuint)(frames->kcCount) * (EGWuint)(frames->cCount);
                        if(frames->fKeys = (EGWbyte*)malloc((size_t)entityPitch * (size_t)(frames->fCount))) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                nodesProcessed = egwParseStringi16cv((EGWchar*)nodeValue, (EGWint16*)(frames->fKeys), 0, ((EGWuint)(frames->fCount) * (EGWuint)(frames->cCount) * (EGWuint)(frames->kcCount)));
                            } else {
                                NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_VA: Failure parsing in manifest input file '%s', for asset '%s': Malformed key values node.", resourceFile, entityID);
                                if(frames->fKeys) { free((void*)frames->fKeys); frames->fKeys = NULL; frames->cCount = frames->kcCount = frames->kcFormat = 0; }
                            }
                        } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_VA: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for key values array.", resourceFile, entityID, ((EGWuint)entityPitch * (EGWuint)(frames->fCount)));
                    } else if(entityFormat && strcasecmp((const char*)entityFormat, (const char*)"uint8") == 0) {
                        frames->kcFormat = EGW_KEYCHANNEL_FRMT_UINT8;
                        entityPitch = (EGWuint)(frames->kcFormat & EGW_KEYCHANNEL_FRMT_EXBPC) * (EGWuint)(frames->kcCount) * (EGWuint)(frames->cCount);
                        if(frames->fKeys = (EGWbyte*)malloc((size_t)entityPitch * (size_t)(frames->fCount))) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                nodesProcessed = egwParseStringui8cv((EGWchar*)nodeValue, (EGWuint8*)(frames->fKeys), 0, ((EGWuint)(frames->fCount) * (EGWuint)(frames->cCount) * (EGWuint)(frames->kcCount)));
                            } else {
                                NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_VA: Failure parsing in manifest input file '%s', for asset '%s': Malformed key values node.", resourceFile, entityID);
                                if(frames->fKeys) { free((void*)frames->fKeys); frames->fKeys = NULL; frames->cCount = frames->kcCount = frames->kcFormat = 0; }
                            }
                        } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_VA: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for key values array.", resourceFile, entityID, ((EGWuint)entityPitch * (EGWuint)(frames->fCount)));
                    } else if(entityFormat && strcasecmp((const char*)entityFormat, (const char*)"int8") == 0) {
                        frames->kcFormat = EGW_KEYCHANNEL_FRMT_INT8;
                        entityPitch = (EGWuint)(frames->kcFormat & EGW_KEYCHANNEL_FRMT_EXBPC) * (EGWuint)(frames->kcCount) * (EGWuint)(frames->cCount);
                        if(frames->fKeys = (EGWbyte*)malloc((size_t)entityPitch * (size_t)(frames->fCount))) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                nodesProcessed = egwParseStringi8cv((EGWchar*)nodeValue, (EGWint8*)(frames->fKeys), 0, ((EGWuint)(frames->fCount) * (EGWuint)(frames->cCount) * (EGWuint)(frames->kcCount)));
                            } else {
                                NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_VA: Failure parsing in manifest input file '%s', for asset '%s': Malformed key values node.", resourceFile, entityID);
                                if(frames->fKeys) { free((void*)frames->fKeys); frames->fKeys = NULL; frames->cCount = frames->kcCount = frames->kcFormat = 0; }
                            }
                        } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_VA: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for key values array.", resourceFile, entityID, ((EGWuint)entityPitch * (EGWuint)(frames->fCount)));
                    } else if(entityFormat && strcasecmp((const char*)entityFormat, (const char*)"triple") == 0) {
                        frames->kcFormat = EGW_KEYCHANNEL_FRMT_TRIPLE;
                        entityPitch = (EGWuint)(frames->kcFormat & EGW_KEYCHANNEL_FRMT_EXBPC) * (EGWuint)(frames->kcCount) * (EGWuint)(frames->cCount);
                        if(frames->fKeys = (EGWbyte*)malloc((size_t)entityPitch * (size_t)(frames->fCount))) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                nodesProcessed = egwParseStringtcv((EGWchar*)nodeValue, (EGWtriple*)(frames->fKeys), 0, ((EGWuint)(frames->fCount) * (EGWuint)(frames->cCount) * (EGWuint)(frames->kcCount)));
                            } else {
                                NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_VA: Failure parsing in manifest input file '%s', for asset '%s': Malformed key values node.", resourceFile, entityID);
                                if(frames->fKeys) { free((void*)frames->fKeys); frames->fKeys = NULL; frames->cCount = frames->kcCount = frames->kcFormat = 0; }
                            }
                        } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_VA: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for key values array.", resourceFile, entityID, ((EGWuint)entityPitch * (EGWuint)(frames->fCount)));
                    } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_VA: Failure parsing in manifest input file '%s', for asset '%s': Key value format '%s' not supported.", resourceFile, entityID, (entityFormat ? (const char*)entityFormat : (const char*)"<NULL>"));
                    
                    if(frames->kcFormat) {
                        if(nodesProcessed != ((EGWuint)(frames->fCount) * (EGWuint)(frames->cCount) * (EGWuint)(frames->kcCount))) { // Pad rest with zeros if short
                            NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_VA: Warning parsing in manifest input file '%s', for asset '%s': Total key values read %d does not match %d key values reported.", resourceFile, entityID, nodesProcessed, ((EGWuint)(frames->fCount) * (EGWuint)(frames->cCount) * (EGWuint)(frames->kcCount)));
                            memset((void*)((EGWuintptr)(frames->fKeys) + (EGWuintptr)((EGWuint)(frames->kcFormat & EGW_KEYCHANNEL_FRMT_EXBPC) * nodesProcessed)), 0, (size_t)((EGWuint)(frames->kcFormat & EGW_KEYCHANNEL_FRMT_EXBPC) * (((EGWuint)(frames->fCount) * (EGWuint)(frames->cCount) * (EGWuint)(frames->kcCount)) - nodesProcessed)));
                        }
                    }
                    
                    if(entityFormat) { xmlFree(entityFormat); entityFormat = NULL; }
                } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_VA: Failure parsing in manifest input file '%s', for asset '%s': Key value count, component count, and/or channel count not specified.", resourceFile, entityID);
                
                if(entityChannels) { xmlFree(entityChannels); entityChannels = NULL; }
                if(entityCount) { xmlFree(entityCount); entityCount = NULL; }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"key_values");
            }
            
            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
            if(*retVal != 1) break;
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"keyframes");
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// Parses <keyframes source="internal" type="prs_array"> sections
void egwGAMXParseKeyFrames_PRSA(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, egwOrientKeyFrame4f* frames) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"keyframes") == 0) {
        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
        
        // vertex array read
        while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
            nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
            
            if(nodeType == 14) continue;
            else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"keyframes") == 0) break;
            else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"pos_time_indicies") == 0) {
                EGWuint iCount; xmlChar* entityCount = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"count");
                if(frames->ptIndicies) { free((void*)frames->ptIndicies); frames->ptIndicies = NULL; }
                
                if(entityCount && egwParseStringuicv((EGWchar*)entityCount, (EGWuint*)&iCount, 0, 1) == 1) {
                    iCount = egwClampui(iCount, 1, EGW_UINT16_MAX); if(frames->pfCount == 0 || iCount < frames->pfCount) frames->pfCount = iCount;
                    if(frames->ptIndicies = (EGWtime*)malloc(sizeof(EGWtime) * (size_t)(frames->pfCount))) {
                        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                            EGWuint nodesProcessed = 0;
                            
                            if(sizeof(EGWtime) == sizeof(EGWsingle)) nodesProcessed = egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)(frames->ptIndicies), 0, (EGWuint)(frames->pfCount));
                            else if(sizeof(EGWtime) == sizeof(EGWdouble)) nodesProcessed = egwParseStringdcv((EGWchar*)nodeValue, (EGWdouble*)(frames->ptIndicies), 0, (EGWuint)(frames->pfCount));
                            else if(sizeof(EGWtime) == sizeof(EGWtriple)) nodesProcessed = egwParseStringtcv((EGWchar*)nodeValue, (EGWtriple*)(frames->ptIndicies), 0, (EGWuint)(frames->pfCount));
                            
                            if(nodesProcessed != (EGWuint)(frames->pfCount)) { // Pad rest with zeros if short
                                NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Warning parsing in manifest input file '%s', for asset '%s': Total position time indicies read %d does not match %d position time indicies reported.", resourceFile, entityID, nodesProcessed, (EGWuint)(frames->pfCount));
                                memset((void*)&(frames->ptIndicies[nodesProcessed]), 0, sizeof(EGWtime) * (size_t)((EGWuint)(frames->pfCount) - nodesProcessed));
                            }
                        } else {
                            NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Failure parsing in manifest input file '%s', for asset '%s': Malformed position time indicies node.", resourceFile, entityID);
                            if(frames->ptIndicies) { free((void*)frames->ptIndicies); frames->ptIndicies = NULL; }
                        }
                    } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for position time indicies array.", resourceFile, entityID, ((EGWuint)sizeof(EGWtime) * (EGWuint)(frames->pfCount)));
                } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Failure parsing in manifest input file '%s', for asset '%s': Position time indicies count not specified.", resourceFile, entityID);
                
                if(entityCount) { xmlFree(entityCount); entityCount = NULL; }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"pos_time_indicies");
            } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"pos_key_values") == 0) {
                EGWuint iCount; xmlChar* entityCount = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"count");
                if(frames->pfKeys) { free((void*)frames->pfKeys); frames->pfKeys = NULL; }
                
                if(entityCount && egwParseStringuicv((EGWchar*)entityCount, (EGWuint*)&iCount, 0, 1) == 1) {
                    iCount = egwClampui(iCount, 1, EGW_UINT16_MAX); if(frames->pfCount == 0 || iCount < frames->pfCount) frames->pfCount = iCount;
                    if(frames->pfKeys = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)(frames->pfCount))) {
                        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                            EGWuint nodesProcessed = egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)(frames->pfKeys), 0, (EGWuint)(frames->pfCount) * 3);
                            if(nodesProcessed != (EGWuint)(frames->pfCount) * 3) { // Pad rest with zeros if short
                                NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Warning parsing in manifest input file '%s', for asset '%s': Total position key values read %d does not match %d position key values reported.", resourceFile, entityID, nodesProcessed, ((EGWuint)(frames->pfCount) * 3));
                                memset((void*)&(((EGWsingle*)(frames->pfKeys))[nodesProcessed]), 0, sizeof(EGWsingle) * (size_t)(((EGWuint)(frames->pfCount) * 3) - nodesProcessed));
                            }
                        } else {
                            NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Failure parsing in manifest input file '%s', for asset '%s': Malformed position key values node.", resourceFile, entityID);
                            if(frames->pfKeys) { free((void*)frames->pfKeys); frames->pfKeys = NULL; }
                        }
                    } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for position key values array.", resourceFile, entityID, ((EGWuint)sizeof(egwVector3f) * (EGWuint)(frames->pfCount)));
                } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Failure parsing in manifest input file '%s', for asset '%s': Position key values count not specified.", resourceFile, entityID);
                
                if(entityCount) { xmlFree(entityCount); entityCount = NULL; }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"pos_key_values");
            } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"rot_time_indicies") == 0) {
                EGWuint iCount; xmlChar* entityCount = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"count");
                if(frames->rtIndicies) { free((void*)frames->rtIndicies); frames->rtIndicies = NULL; }
                
                if(entityCount && egwParseStringuicv((EGWchar*)entityCount, (EGWuint*)&iCount, 0, 1) == 1) {
                    iCount = egwClampui(iCount, 1, EGW_UINT16_MAX); if(frames->rfCount == 0 || iCount < frames->rfCount) frames->rfCount = iCount;
                    if(frames->rtIndicies = (EGWtime*)malloc(sizeof(EGWtime) * (size_t)(frames->rfCount))) {
                        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                            EGWuint nodesProcessed = 0;
                            
                            if(sizeof(EGWtime) == sizeof(EGWsingle)) nodesProcessed = egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)(frames->rtIndicies), 0, (EGWuint)(frames->rfCount));
                            else if(sizeof(EGWtime) == sizeof(EGWdouble)) nodesProcessed = egwParseStringdcv((EGWchar*)nodeValue, (EGWdouble*)(frames->rtIndicies), 0, (EGWuint)(frames->rfCount));
                            else if(sizeof(EGWtime) == sizeof(EGWtriple)) nodesProcessed = egwParseStringtcv((EGWchar*)nodeValue, (EGWtriple*)(frames->rtIndicies), 0, (EGWuint)(frames->rfCount));
                            
                            if(nodesProcessed != (EGWuint)(frames->rfCount)) { // Pad rest with zeros if short
                                NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Warning parsing in manifest input file '%s', for asset '%s': Total rotation time indicies read %d does not match %d rotation time indicies reported.", resourceFile, entityID, nodesProcessed, (EGWuint)(frames->rfCount));
                                memset((void*)&(frames->rtIndicies[nodesProcessed]), 0, sizeof(EGWtime) * (size_t)((EGWuint)(frames->rfCount) - nodesProcessed));
                            }
                        } else {
                            NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Failure parsing in manifest input file '%s', for asset '%s': Malformed rotation time indicies node.", resourceFile, entityID);
                            if(frames->rtIndicies) { free((void*)frames->rtIndicies); frames->rtIndicies = NULL; }
                        }
                    } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for rotation time indicies array.", resourceFile, entityID, ((EGWuint)sizeof(EGWtime) * (EGWuint)(frames->rfCount)));
                } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Failure parsing in manifest input file '%s', for asset '%s': Rotation time indicies count not specified.", resourceFile, entityID);
                
                if(entityCount) { xmlFree(entityCount); entityCount = NULL; }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"rot_time_indicies");
            } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"rot_key_values") == 0) {
                EGWuint iCount; xmlChar* entityCount = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"count");
                if(frames->rfKeys) { free((void*)frames->rfKeys); frames->rfKeys = NULL; }
                
                if(entityCount && egwParseStringuicv((EGWchar*)entityCount, (EGWuint*)&iCount, 0, 1) == 1) {
                    iCount = egwClampui(iCount, 1, EGW_UINT16_MAX); if(frames->rfCount == 0 || iCount < frames->rfCount) frames->rfCount = iCount;
                    if(frames->rfKeys = (egwQuaternion4f*)malloc(sizeof(egwQuaternion4f) * (size_t)(frames->rfCount))) {
                        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                            EGWuint nodesProcessed = egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)(frames->rfKeys), 0, (EGWuint)(frames->rfCount) * 4);
                            if(nodesProcessed != (EGWuint)(frames->rfCount) * 4) { // Pad rest with zeros if short
                                NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Warning parsing in manifest input file '%s', for asset '%s': Total rotation key values read %d does not match %d rotation key values reported.", resourceFile, entityID, nodesProcessed, ((EGWuint)(frames->rfCount) * 4));
                                memset((void*)&(((EGWsingle*)(frames->rfKeys))[nodesProcessed]), 0, sizeof(EGWsingle) * (size_t)(((EGWuint)(frames->rfCount) * 4) - nodesProcessed));
                            }
                        } else {
                            NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Failure parsing in manifest input file '%s', for asset '%s': Malformed rotation key values node.", resourceFile, entityID);
                            if(frames->rfKeys) { free((void*)frames->rfKeys); frames->rfKeys = NULL; }
                        }
                    } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for rotation key values array.", resourceFile, entityID, ((EGWuint)sizeof(egwQuaternion4f) * (EGWuint)(frames->rfCount)));
                } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Failure parsing in manifest input file '%s', for asset '%s': Rotation key values count not specified.", resourceFile, entityID);
                
                if(entityCount) { xmlFree(entityCount); entityCount = NULL; }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"rot_key_values");
            } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"scl_time_indicies") == 0) {
                EGWuint iCount; xmlChar* entityCount = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"count");
                if(frames->stIndicies) { free((void*)frames->stIndicies); frames->stIndicies = NULL; }
                
                if(entityCount && egwParseStringuicv((EGWchar*)entityCount, (EGWuint*)&iCount, 0, 1) == 1) {
                    iCount = egwClampui(iCount, 1, EGW_UINT16_MAX); if(frames->sfCount == 0 || iCount < frames->sfCount) frames->sfCount = iCount;
                    if(frames->stIndicies = (EGWtime*)malloc(sizeof(EGWtime) * (size_t)(frames->sfCount))) {
                        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                            EGWuint nodesProcessed = 0;
                            
                            if(sizeof(EGWtime) == sizeof(EGWsingle)) nodesProcessed = egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)(frames->stIndicies), 0, (EGWuint)(frames->sfCount));
                            else if(sizeof(EGWtime) == sizeof(EGWdouble)) nodesProcessed = egwParseStringdcv((EGWchar*)nodeValue, (EGWdouble*)(frames->stIndicies), 0, (EGWuint)(frames->sfCount));
                            else if(sizeof(EGWtime) == sizeof(EGWtriple)) nodesProcessed = egwParseStringtcv((EGWchar*)nodeValue, (EGWtriple*)(frames->stIndicies), 0, (EGWuint)(frames->sfCount));
                            
                            if(nodesProcessed != (EGWuint)(frames->sfCount)) { // Pad rest with zeros if short
                                NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Warning parsing in manifest input file '%s', for asset '%s': Total scale time indicies read %d does not match %d scale time indicies reported.", resourceFile, entityID, nodesProcessed, (EGWuint)(frames->sfCount));
                                memset((void*)&(frames->stIndicies[nodesProcessed]), 0, sizeof(EGWtime) * (size_t)((EGWuint)(frames->sfCount) - nodesProcessed));
                            }
                        } else {
                            NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Failure parsing in manifest input file '%s', for asset '%s': Malformed scale time indicies node.", resourceFile, entityID);
                            if(frames->stIndicies) { free((void*)frames->stIndicies); frames->stIndicies = NULL; }
                        }
                    } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for scale time indicies array.", resourceFile, entityID, ((EGWuint)sizeof(EGWtime) * (EGWuint)(frames->sfCount)));
                } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Failure parsing in manifest input file '%s', for asset '%s': Scale time indicies count not specified.", resourceFile, entityID);
                
                if(entityCount) { xmlFree(entityCount); entityCount = NULL; }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"scl_time_indicies");
            } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"scl_key_values") == 0) {
                EGWuint iCount; xmlChar* entityCount = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"count");
                if(frames->sfKeys) { free((void*)frames->sfKeys); frames->sfKeys = NULL; }
                
                if(entityCount && egwParseStringuicv((EGWchar*)entityCount, (EGWuint*)&iCount, 0, 1) == 1) {
                    iCount = egwClampui(iCount, 1, EGW_UINT16_MAX); if(frames->sfCount == 0 || iCount < frames->sfCount) frames->sfCount = iCount;
                    if(frames->sfKeys = (egwVector3f*)malloc(sizeof(egwVector3f) * (size_t)(frames->sfCount))) {
                        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                            EGWuint nodesProcessed = egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)(frames->sfKeys), 0, (EGWuint)(frames->sfCount) * 3);
                            if(nodesProcessed != (EGWuint)(frames->sfCount) * 3) { // Pad rest with zeros if short
                                NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Warning parsing in manifest input file '%s', for asset '%s': Total scale key values read %d does not match %d scale key values reported.", resourceFile, entityID, nodesProcessed, ((EGWuint)(frames->sfCount) * 3));
                                memset((void*)&(((EGWsingle*)(frames->sfKeys))[nodesProcessed]), 0, sizeof(EGWsingle) * (size_t)(((EGWuint)(frames->sfCount) * 3) - nodesProcessed));
                            }
                        } else {
                            NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Failure parsing in manifest input file '%s', for asset '%s': Malformed scale key values node.", resourceFile, entityID);
                            if(frames->sfKeys) { free((void*)frames->sfKeys); frames->sfKeys = NULL; }
                        }
                    } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for scale key values array.", resourceFile, entityID, ((EGWuint)sizeof(egwVector3f) * (EGWuint)(frames->sfCount)));
                } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Failure parsing in manifest input file '%s', for asset '%s': Scale key values count not specified.", resourceFile, entityID);
                
                if(entityCount) { xmlFree(entityCount); entityCount = NULL; }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"scl_key_values");
            } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"time_indicies") == 0) {
                EGWuint iCount; xmlChar* entityCount = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"count");
                if(frames->ptIndicies) { free((void*)frames->ptIndicies); frames->ptIndicies = NULL; }
                if(frames->rtIndicies) { free((void*)frames->rtIndicies); frames->rtIndicies = NULL; }
                if(frames->stIndicies) { free((void*)frames->stIndicies); frames->stIndicies = NULL; }
                
                if(entityCount && egwParseStringuicv((EGWchar*)entityCount, (EGWuint*)&iCount, 0, 1) == 1) {
                    iCount = egwClampui(iCount, 1, EGW_UINT16_MAX);
                    if(frames->pfCount == 0 || iCount < frames->pfCount) frames->pfCount = iCount;
                    if(frames->rfCount == 0 || iCount < frames->rfCount) frames->rfCount = iCount;
                    if(frames->sfCount == 0 || iCount < frames->sfCount) frames->sfCount = iCount;
                    
                    // NOTE: Time indicies can overlap like this (and works better overall if they are), but this parse does introduce the possibility of issues if another time indicie op alloc/free is performed. -jw
                    if(frames->ptIndicies = frames->rtIndicies = frames->stIndicies = (EGWtime*)malloc(sizeof(EGWtime) * (size_t)iCount)) {
                        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                            EGWuint nodesProcessed = 0;
                            
                            if(sizeof(EGWtime) == sizeof(EGWsingle)) nodesProcessed = egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)(frames->ptIndicies), 0, iCount);
                            else if(sizeof(EGWtime) == sizeof(EGWdouble)) nodesProcessed = egwParseStringdcv((EGWchar*)nodeValue, (EGWdouble*)(frames->ptIndicies), 0, iCount);
                            else if(sizeof(EGWtime) == sizeof(EGWtriple)) nodesProcessed = egwParseStringtcv((EGWchar*)nodeValue, (EGWtriple*)(frames->ptIndicies), 0, iCount);
                            
                            if(nodesProcessed != iCount) { // Pad rest with zeros if short
                                NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Warning parsing in manifest input file '%s', for asset '%s': Total time indicies read %d does not match %d time indicies reported.", resourceFile, entityID, nodesProcessed, iCount);
                                memset((void*)&(frames->ptIndicies[nodesProcessed]), 0, sizeof(EGWtime) * (size_t)(iCount - nodesProcessed));
                            }
                        } else {
                            NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Failure parsing in manifest input file '%s', for asset '%s': Malformed time indicies node.", resourceFile, entityID);
                            if(frames->ptIndicies) { free((void*)frames->ptIndicies); frames->ptIndicies = frames->rtIndicies = frames->stIndicies = NULL; }
                        }
                    } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for time indicies array.", resourceFile, entityID, ((EGWuint)sizeof(EGWtime) * iCount));
                } else NSLog(@"egwAssetManager: egwGAMXParseKeyFrames_PRSA: Failure parsing in manifest input file '%s', for asset '%s': Time indicies count not specified.", resourceFile, entityID);
                
                if(entityCount) { xmlFree(entityCount); entityCount = NULL; }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"time_indicies");
            }
            
            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
            if(*retVal != 1) break;
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"keyframes");
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// !!!: *** Surface Parsers ***

// Parses <format> sections inside of <surface> sections
void egwGAMXParseSurface_Format(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* format) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"format") == 0) {
        const char* delims = " ,\t\r\n\0";
        
        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
            xmlChar* entityFrmt = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
            for(entityFrmt = (xmlChar*)strtok((char*)entityFrmt, delims); entityFrmt; entityFrmt = (xmlChar*)strtok(NULL, delims)) {
                if(strcasecmp((const char*)entityFrmt, (const char*)"gs") == 0) *format |= EGW_SURFACE_FRMT_EXGS;
                else if(strcasecmp((const char*)entityFrmt, (const char*)"rgb") == 0) *format |= EGW_SURFACE_FRMT_EXRGB;
                else if(strcasecmp((const char*)entityFrmt, (const char*)"ac") == 0) *format |= EGW_SURFACE_FRMT_EXAC;
                else if(strcasecmp((const char*)entityFrmt, (const char*)"gs8") == 0) *format |= EGW_SURFACE_FRMT_GS8;
                else if(strcasecmp((const char*)entityFrmt, (const char*)"gs8a8") == 0) *format |= EGW_SURFACE_FRMT_GS8A8;
                else if(strcasecmp((const char*)entityFrmt, (const char*)"r5g6b5") == 0) *format |= EGW_SURFACE_FRMT_R5G6B5;
                else if(strcasecmp((const char*)entityFrmt, (const char*)"r5g5b5a1") == 0) *format |= EGW_SURFACE_FRMT_R5G5B5A1;
                else if(strcasecmp((const char*)entityFrmt, (const char*)"r4g4b4a4") == 0) *format |= EGW_SURFACE_FRMT_R4G4B4A4;
                else if(strcasecmp((const char*)entityFrmt, (const char*)"r8g8b8") == 0) *format |= EGW_SURFACE_FRMT_R8G8B8;
                else if(strcasecmp((const char*)entityFrmt, (const char*)"r8g8b8a8") == 0) *format |= EGW_SURFACE_FRMT_R8G8B8A8;
                else NSLog(@"egwAssetManager: egwGAMXParseSurface_Format: Failure parsing in manifest input file '%s', for asset '%s': Surface format '%s' not supported.", resourceFile, entityID, entityFrmt);
            }
        }
        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"format");
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// Parses <transforms> sections inside of <surface> sections
void egwGAMXParseSurface_Transforms(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* transforms) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"transforms") == 0) {
        const char* delims = " ,\t\r\n\0";
        
        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
            xmlChar* entityTrans = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
            for(entityTrans = (xmlChar*)strtok((char*)entityTrans, delims); entityTrans; entityTrans = (xmlChar*)strtok(NULL, delims)) {
                if(strcasecmp((const char*)entityTrans, (const char*)"ensure_lt_mstatic") == 0) *transforms |= EGW_SURFACE_TRFM_ENSRLTETMS;
                else if(strcasecmp((const char*)entityTrans, (const char*)"ensure_pow2") == 0) *transforms |= EGW_SURFACE_TRFM_ENSRPOW2;
                else if(strcasecmp((const char*)entityTrans, (const char*)"ensure_square") == 0) *transforms |= EGW_SURFACE_TRFM_ENSRSQR;
                else if(strcasecmp((const char*)entityTrans, (const char*)"resize_half") == 0) *transforms |= EGW_SURFACE_TRFM_RSZHALF;
                else if(strcasecmp((const char*)entityTrans, (const char*)"flip_vert") == 0) *transforms |= EGW_SURFACE_TRFM_FLIPVERT;
                else if(strcasecmp((const char*)entityTrans, (const char*)"flip_horz") == 0) *transforms |= EGW_SURFACE_TRFM_FLIPHORZ;
                else if(strcasecmp((const char*)entityTrans, (const char*)"swap_rb") == 0) *transforms |= EGW_SURFACE_TRFM_SWAPRB;
                else if(strcasecmp((const char*)entityTrans, (const char*)"invert_gs") == 0) *transforms |= EGW_SURFACE_TRFM_INVERTGS;
                else if(strcasecmp((const char*)entityTrans, (const char*)"invert_ac") == 0) *transforms |= EGW_SURFACE_TRFM_INVERTAC;
                else if(strcasecmp((const char*)entityTrans, (const char*)"cyan_to_alpha") == 0) *transforms |= EGW_SURFACE_TRFM_CYANTRANS;
                else if(strcasecmp((const char*)entityTrans, (const char*)"magenta_to_alpha") == 0) *transforms |= EGW_SURFACE_TRFM_MGNTTRANS;
                else if(strcasecmp((const char*)entityTrans, (const char*)"opacity_dilate") == 0) *transforms |= EGW_SURFACE_TRFM_OPCTYDILT;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_gs") == 0) *transforms |= EGW_SURFACE_TRFM_FORCEGS;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_rgb") == 0) *transforms |= EGW_SURFACE_TRFM_FORCERGB;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_ac") == 0) *transforms |= EGW_SURFACE_TRFM_FORCEAC;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_no_ac") == 0) *transforms |= EGW_SURFACE_TRFM_FORCENOAC;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_gs8") == 0) *transforms |= EGW_SURFACE_TRFM_FCGS8;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_gs8a8") == 0) *transforms |= EGW_SURFACE_TRFM_FCGS8A8;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_r5g6b5") == 0) *transforms |= EGW_SURFACE_TRFM_FCR5G6B5;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_r5g5b5a1") == 0) *transforms |= EGW_SURFACE_TRFM_FCR5G5B5A1;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_r4g4b4a4") == 0) *transforms |= EGW_SURFACE_TRFM_FCR4G4B4A4;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_r8g8b8") == 0) *transforms |= EGW_SURFACE_TRFM_FCR8G8B8;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_r8g8b8a8") == 0) *transforms |= EGW_SURFACE_TRFM_FCR8G8B8A8;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack1") == 0) *transforms |= EGW_SURFACE_TRFM_FCBPCK1;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack2") == 0) *transforms |= EGW_SURFACE_TRFM_FCBPCK2;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack4") == 0) *transforms |= EGW_SURFACE_TRFM_FCBPCK4;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack8") == 0) *transforms |= EGW_SURFACE_TRFM_FCBPCK8;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack16") == 0) *transforms |= EGW_SURFACE_TRFM_FCBPCK16;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack32") == 0) *transforms |= EGW_SURFACE_TRFM_FCBPCK32;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack64") == 0) *transforms |= EGW_SURFACE_TRFM_FCBPCK64;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack128") == 0) *transforms |= EGW_SURFACE_TRFM_FCBPCK128;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack256") == 0) *transforms |= EGW_SURFACE_TRFM_FCBPCK256;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack512") == 0) *transforms |= EGW_SURFACE_TRFM_FCBPCK512;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack1024") == 0) *transforms |= EGW_SURFACE_TRFM_FCBPCK1024;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack2048") == 0) *transforms |= EGW_SURFACE_TRFM_FCBPCK2048;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack4096") == 0) *transforms |= EGW_SURFACE_TRFM_FCBPCK4096;
                else if(strcasecmp((const char*)entityTrans, (const char*)"force_bytepack8192") == 0) *transforms |= EGW_SURFACE_TRFM_FCBPCK8192;
                else if(strcasecmp((const char*)entityTrans, (const char*)"mip_sharpen25") == 0) *transforms |= EGW_TEXTURE_TRFM_SHARPEN25;
                else if(strcasecmp((const char*)entityTrans, (const char*)"mip_sharpen33") == 0) *transforms |= EGW_TEXTURE_TRFM_SHARPEN33;
                else if(strcasecmp((const char*)entityTrans, (const char*)"mip_sharpen50") == 0) *transforms |= EGW_TEXTURE_TRFM_SHARPEN50;
                else if(strcasecmp((const char*)entityTrans, (const char*)"mip_sharpen66") == 0) *transforms |= EGW_TEXTURE_TRFM_SHARPEN66;
                else if(strcasecmp((const char*)entityTrans, (const char*)"mip_sharpen75") == 0) *transforms |= EGW_TEXTURE_TRFM_SHARPEN75;
                else if(strcasecmp((const char*)entityTrans, (const char*)"mip_sharpen100") == 0) *transforms |= EGW_TEXTURE_TRFM_SHARPEN100;
                else NSLog(@"egwAssetManager: egwGAMXParseSurface_Transforms: Failure parsing in manifest input file '%s', for asset '%s': Surface transform '%s' not supported.", resourceFile, entityID, entityTrans);
            }
        }
        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"transforms");
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// Parses <surface source="internal" type="non_palleted_pixels"> sections
void egwGAMXParseSurface_NPPA(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, egwSurface* surface, EGWuint* transforms) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"surface") == 0) {
        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
        
        // pcm array read
        while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
            nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
            
            if(nodeType == 14) continue;
            else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"surface") == 0) break;
            else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"pixels") == 0 && !xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                xmlChar* entityFormat = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"format");
                EGWuint dCount[2]; xmlChar* entityDCount = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"dimensions");
                
                if(entityDCount && egwParseStringuicv((EGWchar*)entityDCount, (EGWuint*)&dCount[0], 0, 1) == 2) {
                    dCount[0] = egwClampui(dCount[0], 1, EGW_UINT16_MAX); dCount[1] = egwClampui(dCount[1], 1, EGW_UINT16_MAX);
                    if(!entityFormat || strcasecmp((const char*)entityFormat, (const char*)"gs") == 0) {
                        if(egwSrfcAlloc(surface, EGW_SURFACE_FRMT_GS8, (EGWuint16)dCount[0], (EGWuint16)dCount[1], EGW_SURFACE_DFLTBPACKING)) {
                            // TODO: NPPA surface read GS8.
                            /*EGWuint nodesProcessed = 0;
                            
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                nodesProcessed += egwParseStringi16cv((EGWchar*)nodeValue, (EGWint16*)surface->data, 0, sCount);
                            }
                            
                            if(nodesProcessed != (EGWuint)surface->count) { // Pad rest with zeros if short
                                NSLog(@"egwAssetManager: egwGAMXParseSurface_NPPA: Warning parsing in manifest input file '%s', for asset '%s': Total pixels read %d does not match %d pixels reported.", resourceFile, entityID, nodesProcessed, sCount);
                                memset((void*)&(((EGWint16*)surface->data)[nodesProcessed]), 0, sizeof(EGWint16) * (size_t)((EGWuint)surface->count - nodesProcessed));
                            }*/
                        } else NSLog(@"egwAssetManager: egwGAMXParseSurface_NPPA: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for surface structure.", resourceFile, entityID, sizeof(EGWuint8) * 1 * dCount[0] * dCount[1]);
                    } else if(strcasecmp((const char*)entityFormat, (const char*)"gsa") == 0) {
                        if(egwSrfcAlloc(surface, EGW_SURFACE_FRMT_GS8A8, (EGWuint16)dCount[0], (EGWuint16)dCount[1], EGW_SURFACE_DFLTBPACKING)) {
                            // TODO: NPPA surface read GS8A8.
                            /*EGWuint nodesProcessed = 0;
                            
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                nodesProcessed += egwParseStringi16cv((EGWchar*)nodeValue, (EGWint16*)surface->data, 0, sCount * 2);
                            }
                            
                            if(nodesProcessed != (EGWuint)surface->count * 2) { // Pad rest with zeros if short
                                NSLog(@"egwAssetManager: egwGAMXParseSurface_NPPA: Warning parsing in manifest input file '%s', for asset '%s': Total pixels read %d does not match %d pixels reported.", resourceFile, entityID, nodesProcessed / 2, sCount * 2);
                                memset((void*)&(((EGWint16*)surface->data)[nodesProcessed]), 0, sizeof(EGWint16) * (size_t)(((EGWuint)surface->count * 2) - nodesProcessed));
                            }*/
                        } else NSLog(@"egwAssetManager: egwGAMXParseSurface_NPPA: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for surface structure.", resourceFile, entityID, sizeof(EGWuint8) * 2 * dCount[0] * dCount[1]);
                    } else if(strcasecmp((const char*)entityFormat, (const char*)"rgb") == 0) {
                        if(egwSrfcAlloc(surface, EGW_SURFACE_FRMT_R8G8B8, (EGWuint16)dCount[0], (EGWuint16)dCount[1], EGW_SURFACE_DFLTBPACKING)) {
                            // TODO: NPPA surface read R8G8B8.
                            /*EGWuint nodesProcessed = 0;
                             
                             if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                             nodesProcessed += egwParseStringi16cv((EGWchar*)nodeValue, (EGWint16*)surface->data, 0, sCount * 2);
                             }
                             
                             if(nodesProcessed != (EGWuint)surface->count * 2) { // Pad rest with zeros if short
                             NSLog(@"egwAssetManager: egwGAMXParseSurface_NPPA: Warning parsing in manifest input file '%s', for asset '%s': Total pixels read %d does not match %d pixels reported.", resourceFile, entityID, nodesProcessed / 2, sCount * 2);
                             memset((void*)&(((EGWint16*)surface->data)[nodesProcessed]), 0, sizeof(EGWint16) * (size_t)(((EGWuint)surface->count * 2) - nodesProcessed));
                             }*/
                        } else NSLog(@"egwAssetManager: egwGAMXParseSurface_NPPA: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for surface structure.", resourceFile, entityID, sizeof(EGWuint8) * 3 * dCount[0] * dCount[1]);
                    } else if(strcasecmp((const char*)entityFormat, (const char*)"rgba") == 0) {
                        if(egwSrfcAlloc(surface, EGW_SURFACE_FRMT_R8G8B8A8, (EGWuint16)dCount[0], (EGWuint16)dCount[1], EGW_SURFACE_DFLTBPACKING)) {
                            // TODO: NPPA surface read R8G8B8A8.
                            /*EGWuint nodesProcessed = 0;
                             
                             if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                             nodesProcessed += egwParseStringi16cv((EGWchar*)nodeValue, (EGWint16*)surface->data, 0, sCount * 2);
                             }
                             
                             if(nodesProcessed != (EGWuint)surface->count * 2) { // Pad rest with zeros if short
                             NSLog(@"egwAssetManager: egwGAMXParseSurface_NPPA: Warning parsing in manifest input file '%s', for asset '%s': Total pixels read %d does not match %d pixels reported.", resourceFile, entityID, nodesProcessed / 2, sCount * 2);
                             memset((void*)&(((EGWint16*)surface->data)[nodesProcessed]), 0, sizeof(EGWint16) * (size_t)(((EGWuint)surface->count * 2) - nodesProcessed));
                             }*/
                        } else NSLog(@"egwAssetManager: egwGAMXParseSurface_NPPA: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for surface structure.", resourceFile, entityID, sizeof(EGWuint8) * 4 * dCount[0] * dCount[1]);
                    } else NSLog(@"egwAssetManager: egwGAMXParseSurface_NPPA: Failure parsing in manifest input file '%s', for asset '%s': Surface format '%s' not supported.", resourceFile, entityID, (entityFormat ? (const char*)entityFormat : (const char*)"<NULL>"));
                } else NSLog(@"egwAssetManager: egwGAMXParseSurface_NPPA: Failure parsing in manifest input file '%s', for asset '%s': Samples count not specified.", resourceFile, entityID);
                
                if(entityFormat) { xmlFree(entityFormat); entityFormat = NULL; }
                if(entityDCount) { xmlFree(entityDCount); entityDCount = NULL; }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"pixels");
            } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"transforms") == 0) {
                egwGAMXParseSurface_Transforms(resourceFile, entityID, xmlReadHandle, retVal, transforms);
            }
            
            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
            if(*retVal != 1) break;
        }
        
        if(*retVal == 1) {
            EGWuint entitySTransCopy = *transforms;
            
            if(![egwSIAsstMngr performSurfaceEnsurances:surface fromFile:resourceFile withTransforms:&entitySTransCopy] ||
               ![egwSIAsstMngr performSurfaceModifications:surface fromFile:resourceFile withTransforms:&entitySTransCopy] ||
               ![egwSIAsstMngr performSurfaceConversions:surface fromFile:resourceFile withTransforms:&entitySTransCopy] ||
               ![egwSIAsstMngr performSurfaceModifications:surface fromFile:resourceFile withTransforms:&entitySTransCopy]) {
                NSLog(@"egwAssetManager: egwGAMXParseSurface_NPPA: Failure parsing in manifest input file '%s', for asset '%s': Failure applying surface transforms.", resourceFile, entityID);
                egwSrfcFree(surface);
            }
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"surface");
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// Parses <surface source="external"> sections
void egwGAMXParseSurface_External(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, egwSurface* surface, EGWuint* transforms) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"surface") == 0) {
        NSString* entityExternalFile = nil;
        
        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
        
        // external surface read
        while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
            nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
            
            if(nodeType == 14) continue;
            else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"surface") == 0) break;
            else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"url") == 0) {
                if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                    [entityExternalFile release]; entityExternalFile = nil;
                    entityExternalFile = [[NSString alloc] initWithUTF8String:(const char*)egwQTrimc((EGWchar*)nodeValue, -1)];
                }
                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"url");
            } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"transforms") == 0) {
                egwGAMXParseSurface_Transforms(resourceFile, entityID, xmlReadHandle, retVal, transforms);
            }
            
            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
            if(*retVal != 1) break;
        }
        
        if(*retVal == 1) {
            if(![egwSIAsstMngr loadSurface:surface fromFile:entityExternalFile withTransforms:*transforms])
                NSLog(@"egwAssetManager: egwGAMXParseSurface_External: Failure parsing in manifest input file '%s', for asset '%s': Failure loading surface from external file '%s'.", resourceFile, entityID, entityExternalFile);
        }
        
        [entityExternalFile release]; entityExternalFile = nil;
        
        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"surface");
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// !!!: *** Texturing Parsers ***

// Parses <environment> sections, pre cursor should be on <environment>, post cursor on </environment>, works with current values
void egwGAMXParseTexture_Environment(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* environment) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"environment") == 0) {
        const char* delims = " ,\t\r\n\0";
        
        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
            xmlChar* entityEnv = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
            for(entityEnv = (xmlChar*)strtok((char*)entityEnv, delims); entityEnv; entityEnv = (xmlChar*)strtok(NULL, delims)) {
                if(strcasecmp((const char*)entityEnv, (const char*)"modulate") == 0) *environment |= EGW_TEXTURE_FENV_MODULATE;
                else if(strcasecmp((const char*)entityEnv, (const char*)"modulate_x2") == 0) *environment |= EGW_TEXTURE_FENV_MODULATEX2;
                else if(strcasecmp((const char*)entityEnv, (const char*)"modulate_x4") == 0) *environment |= EGW_TEXTURE_FENV_MODULATEX4;
                else if(strcasecmp((const char*)entityEnv, (const char*)"dot3") == 0) *environment |= EGW_TEXTURE_FENV_DOT3;
                else if(strcasecmp((const char*)entityEnv, (const char*)"add") == 0) *environment |= EGW_TEXTURE_FENV_ADD;
                else if(strcasecmp((const char*)entityEnv, (const char*)"add_signed") == 0) *environment |= EGW_TEXTURE_FENV_ADDSIGNED;
                else if(strcasecmp((const char*)entityEnv, (const char*)"blend") == 0) *environment |= EGW_TEXTURE_FENV_BLEND;
                else if(strcasecmp((const char*)entityEnv, (const char*)"decal") == 0) *environment |= EGW_TEXTURE_FENV_DECAL;
                else if(strcasecmp((const char*)entityEnv, (const char*)"lerp") == 0) *environment |= EGW_TEXTURE_FENV_LERP;
                else if(strcasecmp((const char*)entityEnv, (const char*)"replace") == 0) *environment |= EGW_TEXTURE_FENV_REPLACE;
                else if(strcasecmp((const char*)entityEnv, (const char*)"subtract") == 0) *environment |= EGW_TEXTURE_FENV_SUBTRACT;
                else NSLog(@"egwAssetManager: egwGAMXParseTexture_Environment: Failure parsing in manifest input file '%s', for asset '%s': Texture fragmentation environment '%s' not supported.", resourceFile, entityID, entityEnv);
            }
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, nodeName);
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// Parses <filter> sections, pre cursor should be on <filter>, post cursor on </filter>, works with current values
void egwGAMXParseTexture_Filter(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* filter) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"filter") == 0) {
        const char* delims = " ,\t\r\n\0";
        
        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
            xmlChar* entityFilter = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
            for(entityFilter = (xmlChar*)strtok((char*)entityFilter, delims); entityFilter; entityFilter = (xmlChar*)strtok(NULL, delims)) {
                if(strcasecmp((const char*)entityFilter, (const char*)"nearest") == 0) *filter |= EGW_TEXTURE_FLTR_NEAREST;
                else if(strcasecmp((const char*)entityFilter, (const char*)"linear") == 0) *filter |= EGW_TEXTURE_FLTR_LINEAR;
                else if(strcasecmp((const char*)entityFilter, (const char*)"unilinear") == 0) *filter |= EGW_TEXTURE_FLTR_UNILINEAR;
                else if(strcasecmp((const char*)entityFilter, (const char*)"bilinear") == 0) *filter |= EGW_TEXTURE_FLTR_BILINEAR;
                else if(strcasecmp((const char*)entityFilter, (const char*)"bilinear_halfanisotropic") == 0) *filter |= EGW_TEXTURE_FLTR_BLHANSTRPC;
                else if(strcasecmp((const char*)entityFilter, (const char*)"bilinear_anisotropic") == 0) *filter |= EGW_TEXTURE_FLTR_BLFANSTRPC;
                else if(strcasecmp((const char*)entityFilter, (const char*)"trilinear") == 0) *filter |= EGW_TEXTURE_FLTR_TRILINEAR;
                else if(strcasecmp((const char*)entityFilter, (const char*)"trilinear_halfanisotropic") == 0) *filter |= EGW_TEXTURE_FLTR_TLHANSTRPC;
                else if(strcasecmp((const char*)entityFilter, (const char*)"trilinear_anisotropic") == 0) *filter |= EGW_TEXTURE_FLTR_TLFANSTRPC;
                else if(strcasecmp((const char*)entityFilter, (const char*)"default_nonmipped") == 0) *filter |= EGW_TEXTURE_FLTR_DFLTNMIP;
                else if(strcasecmp((const char*)entityFilter, (const char*)"default_mipped") == 0) *filter |= EGW_TEXTURE_FLTR_DFLTMIP;
                else NSLog(@"egwAssetManager: egwGAMXParseTexture_Filter: Failure parsing in manifest input file '%s', for asset '%s': Texturing filter '%s' not supported.", resourceFile, entityID, entityFilter);
            }
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, nodeName);
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// Parses <Xwrap> sections, pre cursor should be on <Xwrap>, post cursor on </Xwrap>, works with current values
void egwGAMXParseTexture_Wrap(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint16* wrap) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)&nodeName[1], (const char*)"wrap") == 0) {
        const char* delims = " ,\t\r\n\0";
        
        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
            xmlChar* entityWrap = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
            for(entityWrap = (xmlChar*)strtok((char*)entityWrap, delims); entityWrap; entityWrap = (xmlChar*)strtok(NULL, delims)) {
                if(strcasecmp((const char*)entityWrap, (const char*)"clamp") == 0) *wrap |= EGW_TEXTURE_WRAP_CLAMP;
                else if(strcasecmp((const char*)entityWrap, (const char*)"repeat") == 0) *wrap |= EGW_TEXTURE_WRAP_REPEAT;
                else if(strcasecmp((const char*)entityWrap, (const char*)"mirrored_repeat") == 0) *wrap |= EGW_TEXTURE_WRAP_MRRDREPEAT;
                else NSLog(@"egwAssetManager: egwGAMXParseTexture_Wrap: Failure parsing in manifest input file '%s', for asset '%s': Texturing %c-axis edge wrapping '%s' not supported.", resourceFile, entityID, nodeName[0], entityWrap);
            }
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, nodeName);
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// *** Transform Parsers ***

// Parses <transform> section, pre cursor should be on <transform, post cursor on <transform/> or </
// Matricies read as row-major then transposed to column-major, auto unit conversion to radians, multiplied against existing values
void egwGAMXParseTransform(xmlTextReaderPtr xmlReadHandle, EGWint* retVal, egwMatrix44f* matrix) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    egwMatrix44f transform;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"transform") == 0) {
        EGWint componentsLeft = 16;
        
        if(xmlTextReaderIsEmptyElement(xmlReadHandle)) { // <transform/>
            if((nodeValue = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"matrix"))) { /// matrix only
                egwMatCopy44f(&egwSIMatIdentity44f, &transform);
                componentsLeft -= egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)((EGWuintptr)&transform + ((EGWuintptr)sizeof(EGWsingle) * (EGWuintptr)(16 - componentsLeft))), 0, componentsLeft); // row-major
            } else { /// rotation + position
                if((nodeValue = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"quaternion"))) {
                    egwQuatCopy4f(&egwSIQuatIdentity4f, (egwQuaternion4f*)&transform);
                    egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&transform, 0, 4);
                    egwQuatNormalize4f((egwQuaternion4f*)&transform, (egwQuaternion4f*)&transform);
                    egwMatRotateQuaternion44f(NULL, (egwQuaternion4f*)&transform, &transform);
                } else { // rest may need converted
                    xmlChar* nodeUnits = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"mode");
                    if(nodeUnits && !strcasestr((const char*)nodeUnits, (const char*)"degrees")) { xmlFree(nodeUnits); nodeUnits = NULL; } // if !nodeUnits then radians else degrees
                    
                    if((nodeValue = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"axis"))) {
                        egwVecCopy3f(&egwSIVecZero3f, (egwVector3f*)&transform);
                        egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&transform, 0, 3);
                        if(nodeUnits) egwDegToRadfv((EGWsingle*)&transform, (EGWsingle*)&transform, 0, 0, 3);
                        egwMatRotateAxis44f(NULL, (egwVector3f*)&transform, &transform);
                    } else if((nodeValue = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"axis_angle"))) {
                        egwVecCopy4f(&egwSIVecZero4f, (egwVector4f*)&transform);
                        egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&transform, 0, 4);
                        egwVecNormalize3f((egwVector3f*)&transform, (egwVector3f*)&transform);
                        egwMatRotateAxisAngle44f(NULL, (egwVector3f*)&transform, (!nodeUnits ? transform.matrix[3] : egwDegToRadf(transform.matrix[3])), &transform);
                    } else if((nodeValue = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"eulerx"))) {
                        egwVecCopy3f(&egwSIVecZero3f, (egwVector3f*)&transform);
                        egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&transform, 0, 1);
                        if(nodeUnits) egwDegToRadfv((EGWsingle*)&transform, (EGWsingle*)&transform, 0, 0, 1);
                        egwMatRotateEuler44f(NULL, (egwVector3f*)&transform, EGW_EULERROT_ORDER_X, &transform);
                    } else if((nodeValue = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"eulery"))) {
                        egwVecCopy3f(&egwSIVecZero3f, (egwVector3f*)&transform);
                        egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&transform, 0, 1);
                        if(nodeUnits) egwDegToRadfv((EGWsingle*)&transform, (EGWsingle*)&transform, 0, 0, 1);
                        egwMatRotateEuler44f(NULL, (egwVector3f*)&transform, EGW_EULERROT_ORDER_Y, &transform);
                    } else if((nodeValue = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"eulerz"))) {
                        egwVecCopy3f(&egwSIVecZero3f, (egwVector3f*)&transform);
                        egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&transform, 0, 1);
                        if(nodeUnits) egwDegToRadfv((EGWsingle*)&transform, (EGWsingle*)&transform, 0, 0, 1);
                        egwMatRotateEuler44f(NULL, (egwVector3f*)&transform, EGW_EULERROT_ORDER_Z, &transform);
                    } else if((nodeValue = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"eulerxy"))) {
                        egwVecCopy3f(&egwSIVecZero3f, (egwVector3f*)&transform);
                        egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&transform, 0, 2);
                        if(nodeUnits) egwDegToRadfv((EGWsingle*)&transform, (EGWsingle*)&transform, 0, 0, 2);
                        egwMatRotateEuler44f(NULL, (egwVector3f*)&transform, EGW_EULERROT_ORDER_XY, &transform);
                    } else if((nodeValue = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"eulerxz"))) {
                        egwVecCopy3f(&egwSIVecZero3f, (egwVector3f*)&transform);
                        egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&transform, 0, 2);
                        if(nodeUnits) egwDegToRadfv((EGWsingle*)&transform, (EGWsingle*)&transform, 0, 0, 2);
                        egwMatRotateEuler44f(NULL, (egwVector3f*)&transform, EGW_EULERROT_ORDER_XZ, &transform);
                    } else if((nodeValue = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"euleryx"))) {
                        egwVecCopy3f(&egwSIVecZero3f, (egwVector3f*)&transform);
                        egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&transform, 0, 2);
                        if(nodeUnits) egwDegToRadfv((EGWsingle*)&transform, (EGWsingle*)&transform, 0, 0, 2);
                        egwMatRotateEuler44f(NULL, (egwVector3f*)&transform, EGW_EULERROT_ORDER_YX, &transform);
                    } else if((nodeValue = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"euleryz"))) {
                        egwVecCopy3f(&egwSIVecZero3f, (egwVector3f*)&transform);
                        egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&transform, 0, 2);
                        if(nodeUnits) egwDegToRadfv((EGWsingle*)&transform, (EGWsingle*)&transform, 0, 0, 2);
                        egwMatRotateEuler44f(NULL, (egwVector3f*)&transform, EGW_EULERROT_ORDER_YZ, &transform);
                    } else if((nodeValue = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"eulerxyz"))) {
                        egwVecCopy3f(&egwSIVecZero3f, (egwVector3f*)&transform);
                        egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&transform, 0, 3);
                        if(nodeUnits) egwDegToRadfv((EGWsingle*)&transform, (EGWsingle*)&transform, 0, 0, 3);
                        egwMatRotateEuler44f(NULL, (egwVector3f*)&transform, EGW_EULERROT_ORDER_XYZ, &transform);
                    } else if((nodeValue = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"eulerxzy"))) {
                        egwVecCopy3f(&egwSIVecZero3f, (egwVector3f*)&transform);
                        egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&transform, 0, 3);
                        if(nodeUnits) egwDegToRadfv((EGWsingle*)&transform, (EGWsingle*)&transform, 0, 0, 3);
                        egwMatRotateEuler44f(NULL, (egwVector3f*)&transform, EGW_EULERROT_ORDER_XZY, &transform);
                    } else if((nodeValue = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"euleryxz"))) {
                        egwVecCopy3f(&egwSIVecZero3f, (egwVector3f*)&transform);
                        egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&transform, 0, 3);
                        if(nodeUnits) egwDegToRadfv((EGWsingle*)&transform, (EGWsingle*)&transform, 0, 0, 3);
                        egwMatRotateEuler44f(NULL, (egwVector3f*)&transform, EGW_EULERROT_ORDER_YXZ, &transform);
                    } else if((nodeValue = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"euleryzx"))) {
                        egwVecCopy3f(&egwSIVecZero3f, (egwVector3f*)&transform);
                        egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&transform, 0, 3);
                        if(nodeUnits) egwDegToRadfv((EGWsingle*)&transform, (EGWsingle*)&transform, 0, 0, 3);
                        egwMatRotateEuler44f(NULL, (egwVector3f*)&transform, EGW_EULERROT_ORDER_YZX, &transform);
                    } else if((nodeValue = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"eulerzxy"))) {
                        egwVecCopy3f(&egwSIVecZero3f, (egwVector3f*)&transform);
                        egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&transform, 0, 3);
                        if(nodeUnits) egwDegToRadfv((EGWsingle*)&transform, (EGWsingle*)&transform, 0, 0, 3);
                        egwMatRotateEuler44f(NULL, (egwVector3f*)&transform, EGW_EULERROT_ORDER_ZXY, &transform);
                    } else if((nodeValue = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"eulerzyx"))) {
                        egwVecCopy3f(&egwSIVecZero3f, (egwVector3f*)&transform);
                        egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&transform, 0, 3);
                        if(nodeUnits) egwDegToRadfv((EGWsingle*)&transform, (EGWsingle*)&transform, 0, 0, 3);
                        egwMatRotateEuler44f(NULL, (egwVector3f*)&transform, EGW_EULERROT_ORDER_ZYX, &transform);
                    } else {
                        egwMatCopy44f(&egwSIMatIdentity44f, &transform);
                    }
                    
                    if(nodeUnits) { xmlFree(nodeUnits); nodeUnits = NULL; }
                }
                
                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                if((nodeValue = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"position")) || (nodeValue = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"translate"))) {
                    egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&(transform.column[3]), 0, 3);
                }
                
                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                if((nodeValue = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"scale")) || (nodeValue = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"size"))) {
                    egwVector3f scale; egwVecCopy3f(&egwSIVecOne3f, &scale);
                    if(egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&scale, 0, 3) == 1)
                        egwMatUScale44f(&transform, scale.vector[0], &transform);
                    else egwMatScale44f(&transform, &scale, &transform);
                }
            }
        } else { // <transform>matrix</transform>
            egwMatCopy44f(&egwSIMatIdentity44f, &transform);
            
            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                xmlChar* entityMat = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                if(entityMat && strcasecmp((const char*)entityMat, (const char*)"identity") == 0)
                    egwMatCopy44f(&egwSIMatIdentity44f, &transform);
                else if(entityMat && strcasecmp((const char*)entityMat, (const char*)"zero") == 0)
                    egwMatCopy44f(&egwSIMatZero44f, &transform);
                else if(entityMat && strcasecmp((const char*)entityMat, (const char*)"flip_xy") == 0)
                    egwMatInit44f(&transform, 0.0f, 1.0f, 0.0f, 0.0f,
                                              1.0f, 0.0f, 0.0f, 0.0f,
                                              0.0f, 0.0f, 1.0f, 0.0f,
                                              0.0f, 0.0f, 0.0f, 1.0f);
                else if(entityMat && strcasecmp((const char*)entityMat, (const char*)"flip_xz") == 0)
                    egwMatInit44f(&transform, 0.0f, 0.0f, 1.0f, 0.0f,
                                              0.0f, 1.0f, 0.0f, 0.0f,
                                              1.0f, 0.0f, 0.0f, 0.0f,
                                              0.0f, 0.0f, 0.0f, 1.0f);
                else if(entityMat && strcasecmp((const char*)entityMat, (const char*)"flip_yz") == 0)
                    egwMatInit44f(&transform, 1.0f, 0.0f, 0.0f, 0.0f,
                                              0.0f, 0.0f, 1.0f, 0.0f,
                                              0.0f, 1.0f, 0.0f, 0.0f,
                                              0.0f, 0.0f, 0.0f, 1.0f);
                else if(entityMat && strcasecmp((const char*)entityMat, (const char*)"screen_extent") == 0)
                    egwMatTranslate44fs(NULL, egwAIGfxCntx ? (EGWsingle)[egwAIGfxCntx bufferWidth] : 0.0f, egwAIGfxCntx ? (EGWsingle)[egwAIGfxCntx bufferHeight] : 0.0f, 0.0f, &transform);
                else if(entityMat && strcasecmp((const char*)entityMat, (const char*)"screen_center") == 0)
                    egwMatTranslate44fs(NULL, egwAIGfxCntx ? (EGWsingle)[egwAIGfxCntx bufferWidth] * 0.5f : 0.0f, egwAIGfxCntx ? (EGWsingle)[egwAIGfxCntx bufferHeight] * 0.5f : 0.0f, 0.0f, &transform);
                else if(entityMat && strcasecmp((const char*)entityMat, (const char*)"screen_width") == 0)
                    egwMatTranslate44fs(NULL, egwAIGfxCntx ? (EGWsingle)[egwAIGfxCntx bufferWidth] : 0.0f, 0.0f, 0.0f, &transform);
                else if(entityMat && strcasecmp((const char*)entityMat, (const char*)"half_screen_width") == 0)
                    egwMatTranslate44fs(NULL, egwAIGfxCntx ? (EGWsingle)[egwAIGfxCntx bufferWidth] * 0.5f : 0.0f, 0.0f, 0.0f, &transform);
                else if(entityMat && strcasecmp((const char*)entityMat, (const char*)"screen_height") == 0)
                    egwMatTranslate44fs(NULL, 0.0f, egwAIGfxCntx ? (EGWsingle)[egwAIGfxCntx bufferHeight] : 0.0f, 0.0f, &transform);
                else if(entityMat && strcasecmp((const char*)entityMat, (const char*)"half_screen_height") == 0)
                    egwMatTranslate44fs(NULL, 0.0f, egwAIGfxCntx ? (EGWsingle)[egwAIGfxCntx bufferHeight] * 0.5f : 0.0f, 0.0f, &transform);
                else if(entityMat && strcasecmp((const char*)entityMat, (const char*)"swap_xy_pos") == 0) {
                    egwMatCopy44f(&egwSIMatIdentity44f, &transform);
                    EGWsingle temp = matrix->component.r1c4;
                    matrix->component.r1c4 = matrix->component.r2c4;
                    matrix->component.r2c4 = temp;
                } else if(entityMat && strcasecmp((const char*)entityMat, (const char*)"swap_xz_pos") == 0) {
                    egwMatCopy44f(&egwSIMatIdentity44f, &transform);
                    EGWsingle temp = matrix->component.r1c4;
                    matrix->component.r1c4 = matrix->component.r3c4;
                    matrix->component.r3c4 = temp;
                } else if(entityMat && strcasecmp((const char*)entityMat, (const char*)"swap_yz_pos") == 0) {
                    egwMatCopy44f(&egwSIMatIdentity44f, &transform);
                    EGWsingle temp = matrix->component.r2c4;
                    matrix->component.r2c4 = matrix->component.r3c4;
                    matrix->component.r3c4 = temp;
                } else if(entityMat && strcasecmp((const char*)entityMat, (const char*)"transpose") == 0) {
                    egwMatCopy44f(&egwSIMatIdentity44f, &transform);
                    egwMatTranspose44f(matrix, matrix);
                } else if(entityMat && strcasecmp((const char*)entityMat, (const char*)"invert") == 0) {
                    egwMatCopy44f(&egwSIMatIdentity44f, &transform);
                    egwMatInvert44f(matrix, matrix);
                } else if(entityMat) {
                    componentsLeft -= egwParseStringfcv((EGWchar*)entityMat, (EGWsingle*)((EGWuintptr)&transform + ((EGWuintptr)sizeof(EGWsingle) * (EGWuintptr)(16 - componentsLeft))), 0, componentsLeft); // row-major
                }
            }
        }
        
        if(componentsLeft < 16) // If something was read in, then it needs converted
            egwMatTranspose44f(&transform, &transform);
        
        egwMatMultiply44f(matrix, &transform, matrix);
        
        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"transform");
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// Parses <zfalign> section, pre cursor should be on <zfalign, post cursor on <zfalign/> or </, works with current values
void egwGAMXParseZFAlign(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* zfAlign) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"zfalign") == 0) {
        if(xmlTextReaderIsEmptyElement(xmlReadHandle)) { // <zfalign/>
            if((nodeValue = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"x"))) {
                xmlChar* entityValue = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                if(strcasecmp((const char*)entityValue, (const char*)"min") == 0) *zfAlign = (*zfAlign & ~EGW_GFXOBJ_ZFALIGN_EXX) | EGW_GFXOBJ_ZFALIGN_XMIN;
                else if(strcasecmp((const char*)entityValue, (const char*)"center") == 0) *zfAlign = (*zfAlign & ~EGW_GFXOBJ_ZFALIGN_EXX) | EGW_GFXOBJ_ZFALIGN_XCTR;
                else if(strcasecmp((const char*)entityValue, (const char*)"max") == 0) *zfAlign = (*zfAlign & ~EGW_GFXOBJ_ZFALIGN_EXX) | EGW_GFXOBJ_ZFALIGN_XMAX;
                else NSLog(@"egwAssetManager: egwGAMXParseZFAlign: Failure parsing in manifest input file '%s', for asset '%s': Zero offset x-axis align attribute '%s' not supported.", resourceFile, entityID, entityValue);
                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
            }
            
            if((nodeValue = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"y"))) {
                xmlChar* entityValue = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                if(strcasecmp((const char*)entityValue, (const char*)"min") == 0) *zfAlign = (*zfAlign & ~EGW_GFXOBJ_ZFALIGN_EXY) | EGW_GFXOBJ_ZFALIGN_YMIN;
                else if(strcasecmp((const char*)entityValue, (const char*)"center") == 0) *zfAlign = (*zfAlign & ~EGW_GFXOBJ_ZFALIGN_EXY) | EGW_GFXOBJ_ZFALIGN_YCTR;
                else if(strcasecmp((const char*)entityValue, (const char*)"max") == 0) *zfAlign = (*zfAlign & ~EGW_GFXOBJ_ZFALIGN_EXY) | EGW_GFXOBJ_ZFALIGN_YMAX;
                else NSLog(@"egwAssetManager: egwGAMXParseZFAlign: Failure parsing in manifest input file '%s', for asset '%s': Zero offset y-axis align attribute '%s' not supported.", resourceFile, entityID, entityValue);
                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
            }
            
            if((nodeValue = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"z"))) {
                xmlChar* entityValue = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                if(strcasecmp((const char*)entityValue, (const char*)"min") == 0) *zfAlign = (*zfAlign & ~EGW_GFXOBJ_ZFALIGN_EXZ) | EGW_GFXOBJ_ZFALIGN_ZMIN;
                else if(strcasecmp((const char*)entityValue, (const char*)"center") == 0) *zfAlign = (*zfAlign & ~EGW_GFXOBJ_ZFALIGN_EXZ) | EGW_GFXOBJ_ZFALIGN_ZCTR;
                else if(strcasecmp((const char*)entityValue, (const char*)"max") == 0) *zfAlign = (*zfAlign & ~EGW_GFXOBJ_ZFALIGN_EXZ) | EGW_GFXOBJ_ZFALIGN_ZMAX;
                else NSLog(@"egwAssetManager: egwGAMXParseZFAlign: Failure parsing in manifest input file '%s', for asset '%s': Zero offset z-axis align attribute '%s' not supported.", resourceFile, entityID, entityValue);
                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
            }
            
            if((nodeValue = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"invert"))) {
                xmlChar* entityValue = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                *zfAlign = (*zfAlign & ~EGW_GFXOBJ_ZFALIGN_EXINV);
                if(strcasestr((const char*)entityValue, (const char*)"x")) *zfAlign |= EGW_GFXOBJ_ZFALIGN_XINV;
                if(strcasestr((const char*)entityValue, (const char*)"y")) *zfAlign |= EGW_GFXOBJ_ZFALIGN_YINV;
                if(strcasestr((const char*)entityValue, (const char*)"z")) *zfAlign |= EGW_GFXOBJ_ZFALIGN_ZINV;
                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
            }
        } else { // <zfalign>flags</zfalign>
            const char* delims = " ,\t\r\n\0";
            
            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                xmlChar* entityValues = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                for(entityValues = (xmlChar*)strtok((char*)entityValues, delims); entityValues; entityValues = (xmlChar*)strtok(NULL, delims)) {
                    if(strcasecmp((const char*)entityValues, (const char*)"xmin") == 0) *zfAlign = (*zfAlign & ~EGW_GFXOBJ_ZFALIGN_EXX) | EGW_GFXOBJ_ZFALIGN_XMIN;
                    else if(strcasecmp((const char*)entityValues, (const char*)"xcenter") == 0) *zfAlign = (*zfAlign & ~EGW_GFXOBJ_ZFALIGN_EXX) | EGW_GFXOBJ_ZFALIGN_XCTR;
                    else if(strcasecmp((const char*)entityValues, (const char*)"xmax") == 0) *zfAlign = (*zfAlign & ~EGW_GFXOBJ_ZFALIGN_EXX) | EGW_GFXOBJ_ZFALIGN_XMAX;
                    else if(strcasecmp((const char*)entityValues, (const char*)"xinvert") == 0) *zfAlign |= EGW_GFXOBJ_ZFALIGN_XINV;
                    else if(strcasecmp((const char*)entityValues, (const char*)"ymin") == 0) *zfAlign = (*zfAlign & ~EGW_GFXOBJ_ZFALIGN_EXY) | EGW_GFXOBJ_ZFALIGN_YMIN;
                    else if(strcasecmp((const char*)entityValues, (const char*)"ycenter") == 0) *zfAlign = (*zfAlign & ~EGW_GFXOBJ_ZFALIGN_EXY) | EGW_GFXOBJ_ZFALIGN_YCTR;
                    else if(strcasecmp((const char*)entityValues, (const char*)"ymax") == 0) *zfAlign = (*zfAlign & ~EGW_GFXOBJ_ZFALIGN_EXY) | EGW_GFXOBJ_ZFALIGN_YMAX;
                    else if(strcasecmp((const char*)entityValues, (const char*)"yinvert") == 0) *zfAlign |= EGW_GFXOBJ_ZFALIGN_YINV;
                    else if(strcasecmp((const char*)entityValues, (const char*)"zmin") == 0) *zfAlign = (*zfAlign & ~EGW_GFXOBJ_ZFALIGN_EXZ) | EGW_GFXOBJ_ZFALIGN_ZMIN;
                    else if(strcasecmp((const char*)entityValues, (const char*)"zcenter") == 0) *zfAlign = (*zfAlign & ~EGW_GFXOBJ_ZFALIGN_EXZ) | EGW_GFXOBJ_ZFALIGN_ZCTR;
                    else if(strcasecmp((const char*)entityValues, (const char*)"zmax") == 0) *zfAlign = (*zfAlign & ~EGW_GFXOBJ_ZFALIGN_EXZ) | EGW_GFXOBJ_ZFALIGN_ZMAX;
                    else if(strcasecmp((const char*)entityValues, (const char*)"zinvert") == 0) *zfAlign |= EGW_GFXOBJ_ZFALIGN_ZINV;
                    else NSLog(@"egwAssetManager: egwGAMXParseZFAlign: Failure parsing in manifest input file '%s', for asset '%s': Zero offset align attribute '%s' not supported.", resourceFile, entityID, entityValues);
                }
            }
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"zfalign");
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// !!!: *** Volume Parsers ***

// Parses <volume> sections, pre cursor should be on <volume, post cursor on <volume/> or </
// TODO: Expand node read to include pre-determined volume init dist -jw
void egwGAMXParseVolume(const EGWchar* resourceFile, const xmlChar* entityID, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, Class* bVolumeClass, id<egwPBounding>* bVolumeInstance) {
    EGWint nodeType;
    xmlChar* nodeName = NULL;
    xmlChar* nodeValue = NULL;
    
    if(*retVal != 1) return;
    
    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 ? xmlTextReaderName(xmlReadHandle) : NULL);
    if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"volume") == 0) {
        xmlChar* entityNodeType = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"type");
        
        if(!entityNodeType || strcasecmp((const char*)entityNodeType, (const char*)"none") == 0) {
            if(bVolumeClass) *bVolumeClass = nil;
            if(bVolumeInstance) { [*bVolumeInstance release]; *bVolumeInstance = nil; }
        } else if(strcasecmp((const char*)entityNodeType, (const char*)"sphere") == 0) {
            if(bVolumeClass) *bVolumeClass = [egwBoundingSphere class];
        } else if(strcasecmp((const char*)entityNodeType, (const char*)"aabb") == 0) {
            if(bVolumeClass) *bVolumeClass = [egwBoundingBox class];
        } else if(strcasecmp((const char*)entityNodeType, (const char*)"infinite") == 0) {
            if(bVolumeClass) *bVolumeClass = [egwInfiniteBounding class];
        } else if(strcasecmp((const char*)entityNodeType, (const char*)"zero") == 0) {
            if(bVolumeClass) *bVolumeClass = [egwZeroBounding class];
        } else NSLog(@"egwAssetManager: egwGAMXParseVolume: Failure parsing in manifest input file '%s', for asset '%s': Bounding volume type '%s' not supported.", resourceFile, entityID, (entityNodeType ? (const char*)entityNodeType : (const char*)"<NULL>"));
        
        if(entityNodeType) { xmlFree(entityNodeType); entityNodeType = NULL; }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"volume");
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
}

// !!!: **** Entity Parsers ****

// Instantiation type and distinct parameter values for geometry parsing
typedef struct {
    EGWint16 type; // invalid type = -1, static billboard = 0
    EGWint16 srcType; // invalid type = -1, billboard geometry = 0, billboard blank = 1, billboard quad = 2
    union {
        struct { egwSTVAMeshf geometry; } geom; // billboard geometry = 0
        struct { EGWuint16 vCount; } blnk; // billboard blank = 1
        struct { EGWuint16 dim[2]; } quad; // billboard quad = 2
    } dist;
} egwBillboardParams;

id<NSObject> egwGAMXParseBillboard(const EGWchar* resourceFile, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* loadCounter, const xmlChar* entityNodeName) {
    id<NSObject> entity = nil;
    xmlChar* entityID = NULL;
    xmlChar* entityRefID = NULL;
    
    if(entityNodeName) {
        if(strcasecmp((const char*)entityNodeName, (const char*)"billboard") == 0) {
            entityID = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"id");
            entityRefID = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"ref");
            
            if(entityID && !entityRefID) { // New
                xmlChar* entityNodeType = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"type");
                
                if((!entityNodeType || strcasecmp((const char*)entityNodeType, (const char*)"static") == 0) && !xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                    EGWint nodeType;
                    xmlChar* nodeName = NULL;
                    xmlChar* nodeValue = NULL;
                    egwBillboardParams entityParams; memset((void*)&entityParams, 0, sizeof(egwBillboardParams)); entityParams.type = entityParams.srcType = -1;
                    EGWuint entityRFlags = 0;
                    Class entityBBounding = nil;
                    EGWuint entityGStorage = 0;
                    egwMaterialStack* entityMStack = nil;
                    egwTextureStack* entityTStack = nil;
                    egwMatrix44f entityBaseOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityBaseOffset);
                    EGWuint entityBaseZFAlign = 0;
                    egwMatrix44f entityOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityOffset);
                    egwMatrix44f entityOrient; egwMatCopy44f(&egwSIMatIdentity44f, &entityOrient);
                    egwSinglyLinkedList entityPerforms; egwSLListInit(&entityPerforms, NULL, sizeof(egwGAMPostPerforms), EGW_LIST_FLG_DFLT);
                    
                    if(!entityNodeType || strcasecmp((const char*)entityNodeType, (const char*)"static") == 0)
                        entityParams.type = 0;
                    
                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                        
                        if(nodeType == 14) continue;
                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"geometry") == 0 && !xmlTextReaderIsEmptyElement(xmlReadHandle) && entityParams.type == 0) {
                            xmlChar* entitySourceSrc = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"source");
                            
                            if(!entitySourceSrc || strcasecmp((const char*)entitySourceSrc, (const char*)"internal") == 0) {
                                xmlChar* entitySourceType = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"type");
                                
                                if(entitySourceType && strcasecmp((const char*)entitySourceType, (const char*)"vertex_array") == 0) {
                                    egwGAMXParseGeometry_STVA(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.geom.geometry);
                                    
                                    if(*retVal == 1) {
                                        if(entityParams.dist.geom.geometry.vCount && entityParams.dist.geom.geometry.vCoords) {
                                            entityParams.srcType = 0; // billboard geometry
                                        }
                                    }
                                } else if(entitySourceType && strcasecmp((const char*)entitySourceType, (const char*)"joint_indexed_vertex_array") == 0) {
                                    egwSJITVAMeshf entitySJITVAMesh; memset((void*)&entitySJITVAMesh, 0, sizeof(egwSJITVAMeshf));
                                    
                                    egwGAMXParseGeometry_SJITVA(resourceFile, entityID, xmlReadHandle, retVal, &entitySJITVAMesh);
                                    
                                    if(*retVal == 1) {
                                        if(entitySJITVAMesh.vCount && entitySJITVAMesh.vCoords && entitySJITVAMesh.fCount && entitySJITVAMesh.fIndicies &&
                                           egwMeshConvertSJITVAfSTVAf(&entitySJITVAMesh, &entityParams.dist.geom.geometry) &&
                                           entityParams.dist.geom.geometry.vCount && entityParams.dist.geom.geometry.vCoords) {
                                           entityParams.srcType = 0; // billboard geometry
                                        }
                                    }
                                    
                                    egwMeshFreeSJITVAf(&entitySJITVAMesh);
                                } else if(entitySourceType && strcasecmp((const char*)entitySourceType, (const char*)"disjoint_indexed_vertex_array") == 0) {
                                    egwSDITVAMeshf entitySDITVAMesh; memset((void*)&entitySDITVAMesh, 0, sizeof(egwSDITVAMeshf));
                                    
                                    egwGAMXParseGeometry_SDITVA(resourceFile, entityID, xmlReadHandle, retVal, &entitySDITVAMesh);
                                    
                                    if(*retVal == 1) {
                                        if(entitySDITVAMesh.vCount && entitySDITVAMesh.vCoords && entitySDITVAMesh.fCount && entitySDITVAMesh.fIndicies &&
                                           egwMeshConvertSDITVAfSTVAf(&entitySDITVAMesh, &entityParams.dist.geom.geometry) &&
                                           entityParams.dist.geom.geometry.vCount && entityParams.dist.geom.geometry.vCoords) {
                                           entityParams.srcType = 0; // billboard geometry
                                        }
                                    }
                                    
                                    egwMeshFreeSDITVAf(&entitySDITVAMesh);
                                } else if(entitySourceType && strcasecmp((const char*)entitySourceType, (const char*)"blank") == 0) {
                                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                    
                                    // blank primitive read
                                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                        
                                        if(nodeType == 14) continue;
                                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"geometry") == 0) break;
                                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"vertex_count") == 0) {
                                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                                egwParseStringui16cv((EGWchar*)nodeValue, (EGWuint16*)&entityParams.dist.blnk.vCount, 0, 1);
                                            }
                                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"vertex_count");
                                        }
                                        
                                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    
                                    if(*retVal == 1) {
                                        entityParams.srcType = 1; // billboard blank
                                    }
                                } else if(entitySourceType && strcasecmp((const char*)entitySourceType, (const char*)"quad_primitive") == 0) {
                                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                    
                                    // quad primitive read
                                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                        
                                        if(nodeType == 14) continue;
                                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"geometry") == 0) break;
                                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"dimensions") == 0) {
                                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                                egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&entityParams.dist.quad.dim[0], 0, 2);
                                                entityParams.dist.quad.dim[0] = egwClampPosf(entityParams.dist.quad.dim[0]);
                                                entityParams.dist.quad.dim[1] = egwClampPosf(entityParams.dist.quad.dim[1]);
                                            }
                                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"dimensions");
                                        }
                                        
                                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    
                                    if(*retVal == 1) {
                                        entityParams.srcType = 2; // billboard quad
                                    }
                                } else NSLog(@"egwAssetManager: egwGAMXParseBillboard: Failure parsing in manifest input file '%s', for asset '%s': Surface internal type '%s' not supported.", resourceFile, entityID, (entitySourceType ? (const char*)entitySourceType : (const char*)"<NULL>"));
                                
                                if(entitySourceType) { xmlFree(entitySourceType); entitySourceType = NULL; }
                            //} else if(strcasecmp((const char*)entitySourceSrc, (const char*)"external") == 0) {
                                // TODO: Billboard read external geometry.
                            } else NSLog(@"egwAssetManager: egwGAMXParseBillboard: Failure parsing in manifest input file '%s', for asset '%s': Surface source '%s' not supported.", resourceFile, entityID, (entitySourceSrc ? (const char*)entitySourceSrc : (const char*)"<NULL>"));
                            
                            if(entitySourceSrc) { xmlFree(entitySourceSrc); entitySourceSrc = NULL; }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"geometry");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"storage") == 0) {
                            egwGAMXParseGeometry_Storage(resourceFile, entityID, xmlReadHandle, retVal, &entityGStorage);
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"materials") == 0) {
                            if(!entityMStack && !(entityMStack = [[egwMaterialStack alloc] init]))
                                NSLog(@"egwAssetManager: egwGAMXParseBillboard: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating a material stack.", resourceFile, entityID, nodeValue);
                            else {
                                while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                    id<NSObject> entityRef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityRef && [entityRef conformsToProtocol:@protocol(egwPMaterial)]) {
                                        [entityMStack addMaterial:(id<egwPMaterial>)entityRef];
                                    } else {
                                        NSLog(@"egwAssetManager: egwGAMXParseBillboard: Failure parsing in manifest input file '%s', for asset '%s': Material stack node type '%s' not supported.", resourceFile, entityID, nodeValue);
                                        egwGAMXParseSkip(xmlReadHandle, retVal, nodeValue);
                                    }
                                    [entityRef release]; entityRef = nil;
                                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                    if(*retVal != 1) break;
                                }
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"materials");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"textures") == 0) {
                            if(!entityTStack && !(entityTStack = [[egwTextureStack alloc] init]))
                                NSLog(@"egwAssetManager: egwGAMXParseBillboard: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating a texture stack.", resourceFile, entityID, nodeValue);
                            else {
                                while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                    id<NSObject> entityRef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityRef && [entityRef conformsToProtocol:@protocol(egwPTexture)]) {
                                        [entityTStack addTexture:(id<egwPTexture>)entityRef];
                                    } else {
                                        NSLog(@"egwAssetManager: egwGAMXParseBillboard: Failure parsing in manifest input file '%s', for asset '%s': Texture stack node type '%s' not supported.", resourceFile, entityID, nodeValue);
                                        egwGAMXParseSkip(xmlReadHandle, retVal, nodeValue);
                                    }
                                    [entityRef release]; entityRef = nil;
                                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                    if(*retVal != 1) break;
                                }
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"textures");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"render_flags") == 0) {
                            egwGAMXParseFlags_Render(resourceFile, entityID, xmlReadHandle, retVal, &entityRFlags);
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"base_offset") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityBaseOffset);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"zfalign") == 0)
                                    egwGAMXParseZFAlign(resourceFile, entityID, xmlReadHandle, retVal, &entityBaseZFAlign);
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"base_offset");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"offset") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityOffset);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetOffsetDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"offset");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"orient") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityOrient);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetOrientateDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"orient");
                        }
                        
                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                        if(*retVal != 1) break;
                    }
                    
                    if(*retVal == 1) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        
                        if((entityParams.srcType == 0 && // billboard geometry
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwBillboard alloc] initWithIdentity:entityIDIdent staticMesh:&entityParams.dist.geom.geometry billboardBounding:entityBBounding geometryStorage:entityGStorage lightStack:nil materialStack:entityMStack textureStack:entityTStack])]) ||
                           (entityParams.srcType == 1 && // billboard blank
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwBillboard alloc] initBlankWithIdentity:entityIDIdent vertexCount:entityParams.dist.blnk.vCount geometryStorage:entityGStorage lightStack:nil materialStack:entityMStack textureStack:entityTStack])]) ||
                           (entityParams.srcType == 2 && // billboard quad
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwBillboard alloc] initQuadWithIdentity:entityIDIdent quadWidth:entityParams.dist.quad.dim[0] quadHeight:entityParams.dist.quad.dim[1] billboardBounding:entityBBounding geometryStorage:entityGStorage lightStack:nil materialStack:entityMStack textureStack:entityTStack])])) {
                            BOOL entityBaseWasAligned = NO;
                            if(entityBaseZFAlign != 0) { [(egwBillboardBase*)[(id<egwPGeometry>)entity renderingBase] baseOffsetByZeroAlign:entityBaseZFAlign]; entityBaseWasAligned = YES; }
                            if(!egwMatIsEqual44f(&entityBaseOffset, &egwSIMatIdentity44f)) { [(egwBillboardBase*)[(id<egwPGeometry>)entity renderingBase] baseOffsetByTransform:&entityBaseOffset]; entityBaseWasAligned = YES; }
                            if(!egwMatIsEqual44f(&entityOffset, &egwSIMatIdentity44f)) [(id<egwPGeometry>)entity offsetByTransform:&entityOffset];
                            if(!egwMatIsEqual44f(&entityOrient, &egwSIMatIdentity44f) || entityBaseWasAligned) [(id<egwPGeometry>)entity orientateByTransform:&entityOrient];
                            if(entityRFlags) [(id<egwPGeometry>)entity setRenderingFlags:entityRFlags];
                            if(entityPerforms.eCount) {
                                egwSinglyLinkedListIter iter;
                                
                                if(egwSLListEnumerateStart(&entityPerforms, EGW_ITERATE_MODE_DFLT, &iter)) {
                                    egwGAMPostPerforms* action;
                                    
                                    while((action = (egwGAMPostPerforms*)egwSLListEnumerateNextPtr(&iter))) {
                                        if(action->object1 && action->object2)
                                            [entity performSelector:action->method withObject:action->object1 withObject:action->object2];
                                        else if(action->object1)
                                            [entity performSelector:action->method withObject:action->object1];
                                        else
                                            [entity performSelector:action->method];
                                    }
                                }
                            }
                            ++(*loadCounter);
                        } else
                            NSLog(@"egwAssetManager: egwGAMXParseBillboard: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating billboard asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    }
                    
                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                    if(entityParams.srcType == 0) egwMeshFreeSTVAf(&entityParams.dist.geom.geometry);
                    [entityMStack release]; entityMStack = nil;
                    [entityTStack release]; entityTStack = nil;
                    egwSLListFree(&entityPerforms);
                } else
                    NSLog(@"egwAssetManager: egwGAMXParseBillboard: Failure parsing in manifest input file '%s', for asset '%s': Billboard node malformed or type attribute '%s' not supported.", resourceFile, entityID, (entityNodeType ? (const char*)entityNodeType : (const char*)"<NULL>"));
                
                if(entityNodeType) { xmlFree(entityNodeType); entityNodeType = NULL; }
            } else if (entityRefID) { // !!!: Billboard Copy/Get
                NSString* entityRefIdent = [[NSString alloc] initWithUTF8String:(const char*)entityRefID];
                id<NSObject> entityRef = (id<NSObject>)[[egwSIAsstMngr retrieveAsset:entityRefIdent] retain];
                
                if(entityRef && entityID) { // Copy
                    if([entityRef isKindOfClass:[egwBillboard class]]) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwBillboard alloc] initCopyOf:(id<egwPAsset,egwPGeometry>)entityRef withIdentity:entityIDIdent])])
                            ++(*loadCounter);
                        else
                            NSLog(@"egwAssetManager: egwGAMXParseBillboard: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating billboard asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    } else {
                        NSLog(@"egwAssetManager: egwGAMXParseBillboard: Failure parsing in manifest input file '%s', for asset '%s': Copying billboard class type '%@' not supported.", resourceFile, entityID, [entityRef class]);
                    }
                    
                    if(entity) { // Shared unique properties (offset/orient)
                        if(!xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                            EGWint nodeType;
                            xmlChar* nodeName = NULL;
                            xmlChar* nodeValue = NULL;
                            EGWuint entityRFlags = [(id<egwPGeometry>)entityRef renderingFlags];
                            egwMaterialStack* entityMStack = nil;
                            egwTextureStack* entityTStack = nil;
                            egwMatrix44f entityOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityOffset);
                            egwMatrix44f entityOrient; egwMatCopy44f(&egwSIMatIdentity44f, &entityOrient);
                            
                            while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                
                                if(nodeType == 14) continue;
                                else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                                else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"materials") == 0) {
                                    if(!entityMStack && !(entityMStack = [[egwMaterialStack alloc] init]))
                                        NSLog(@"egwAssetManager: egwGAMXParseBillboard: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating a material stack.", resourceFile, entityID, nodeValue);
                                    else {
                                        while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                            id<NSObject> entityRef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                            if(entityRef && [entityRef conformsToProtocol:@protocol(egwPMaterial)]) {
                                                [entityMStack addMaterial:(id<egwPMaterial>)entityRef];
                                            } else {
                                                NSLog(@"egwAssetManager: egwGAMXParseBillboard: Failure parsing in manifest input file '%s', for asset '%s': Material stack node type '%s' not supported.", resourceFile, entityID, nodeValue);
                                                egwGAMXParseSkip(xmlReadHandle, retVal, nodeValue);
                                            }
                                            [entityRef release]; entityRef = nil;
                                            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                            if(*retVal != 1) break;
                                        }
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"materials");
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"textures") == 0) {
                                    if(!entityTStack && !(entityTStack = [[egwTextureStack alloc] init]))
                                        NSLog(@"egwAssetManager: egwGAMXParseBillboard: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating a texture stack.", resourceFile, entityID, nodeValue);
                                    else {
                                        while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                            id<NSObject> entityRef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                            if(entityRef && [entityRef conformsToProtocol:@protocol(egwPTexture)]) {
                                                [entityTStack addTexture:(id<egwPTexture>)entityRef];
                                            } else {
                                                NSLog(@"egwAssetManager: egwGAMXParseBillboard: Failure parsing in manifest input file '%s', for asset '%s': Texture stack node type '%s' not supported.", resourceFile, entityID, nodeValue);
                                                egwGAMXParseSkip(xmlReadHandle, retVal, nodeValue);
                                            }
                                            [entityRef release]; entityRef = nil;
                                            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                            if(*retVal != 1) break;
                                        }
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"textures");
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"render_flags") == 0) {
                                    egwGAMXParseFlags_Render(resourceFile, entityID, xmlReadHandle, retVal, &entityRFlags);
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"offset") == 0) {
                                    while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                        if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                            egwGAMXParseTransform(xmlReadHandle, retVal, &entityOffset);
                                        else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                            id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                            if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                                [(id<egwPOrientated>)entity trySetOffsetDriver:(id<egwPInterpolator>)entityIPORef];
                                            }
                                            [entityIPORef release]; entityIPORef = nil;
                                        }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"offset");
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"orient") == 0) {
                                    while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                        if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                            egwGAMXParseTransform(xmlReadHandle, retVal, &entityOrient);
                                        else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                            id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                            if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                                [(id<egwPOrientated>)entity trySetOrientateDriver:(id<egwPInterpolator>)entityIPORef];
                                            }
                                            [entityIPORef release]; entityIPORef = nil;
                                        }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"orient");
                                }
                                
                                if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            
                            if(*retVal == 1) {
                                if(!egwMatIsEqual44f(&entityOffset, &egwSIMatIdentity44f)) [(id<egwPGeometry>)entity offsetByTransform:&entityOffset];
                                if(!egwMatIsEqual44f(&entityOrient, &egwSIMatIdentity44f)) [(id<egwPGeometry>)entity orientateByTransform:&entityOrient];
                                if(entityRFlags != [(id<egwPGeometry>)entityRef renderingFlags]) [(id<egwPGeometry>)entity setRenderingFlags:entityRFlags];
                                if(entityMStack) [(id<egwPGeometry>)entity setMaterialStack:entityMStack];
                                if(entityTStack) [(id<egwPGeometry>)entity setTextureStack:entityTStack];
                            }
                            
                            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                            [entityMStack release]; entityMStack = nil;
                            [entityTStack release]; entityTStack = nil;
                        }
                    }
                } else if(entityRef && !entityID) { // Get
                    entity = [entityRef retain];
                } else {
                    NSLog(@"egwAssetManager: egwGAMXParseBillboard: Failure parsing in manifest input file '%s', for asset '%s': Billboard asset '%@' does not exist.", resourceFile, entityID, entityRefIdent);
                }
                
                [entityRefIdent release]; entityRefIdent = nil;
                [entityRef release]; entityRef = nil;
            } else {
                NSLog(@"egwAssetManager: egwGAMXParseBillboard: Failure parsing in manifest input file '%s', for asset '%s': Billboard node must contain an ID and/or reference an ID.", resourceFile, entityID);
            }
            
            if(entityID) { xmlFree(entityID); entityID = NULL; }
            if(entityRefID) { xmlFree(entityRefID); entityRefID = NULL; }
        } else {
            NSLog(@"egwAssetManager: egwGAMXParseBillboard: Failure parsing in manifest input file '%s', for asset '%s': Billboard node type '%s' not supported.", resourceFile, entityID, entityNodeName);
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, entityNodeName);
    }
    
    return entity;
}

// TODO: Switch egwGAMXParseCamera to egwGAMXCameraParams structure usage. -jw

id<NSObject> egwGAMXParseCamera(const EGWchar* resourceFile, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* loadCounter, const xmlChar* entityNodeName) {
    id<NSObject> entity = nil;
    xmlChar* entityID = NULL;
    xmlChar* entityRefID = NULL;
    
    if(entityNodeName) {
        if(strcasecmp((const char*)entityNodeName, (const char*)"camera") == 0) {
            entityID = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"id");
            entityRefID = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"ref");
            
            if(entityID && !entityRefID) { // New
                xmlChar* entityNodeType = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"type");
                
                if((!entityNodeType || strcasecmp((const char*)entityNodeType, (const char*)"perspective") == 0) && !xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                    EGWint nodeType;
                    xmlChar* nodeName = NULL;
                    xmlChar* nodeValue = NULL;
                    EGWsingle entityFOV = 45.0f;
                    EGWsingle entityARatio = 320.0f / 460.0f;
                    EGWsingle entityZNear = 1.0f;
                    EGWsingle entityZFar = 1000.0f;
                    EGWsingle entityGAngle = 0.0f;
                    egwMatrix44f entityOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityOffset);
                    egwMatrix44f entityOrient; egwMatCopy44f(&egwSIMatIdentity44f, &entityOrient);
                    egwVector3f entityLookat[2]; egwVecCopy3fv(&egwSIVecZero3f, entityLookat, -sizeof(egwVector3f), 0, 2);
                    egwSinglyLinkedList entityPerforms; egwSLListInit(&entityPerforms, NULL, sizeof(egwGAMPostPerforms), EGW_LIST_FLG_DFLT);
                    
                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                        
                        if(nodeType == 14) continue;
                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"grasp_angle") == 0) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&entityGAngle, 0, 1);
                                entityGAngle = egwDegToRadf(entityGAngle);
                                entityGAngle = egwRadReduce02PIf(entityGAngle);
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"grasp_angle");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"fov") == 0) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&entityFOV, 0, 1);
                                entityFOV = egwClampPosf(entityFOV);
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"fov");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"aspect") == 0) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                xmlChar* entityAspect = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                                if(strcasecmp((const char*)entityAspect, "auto_fullscreen") == 0) {
                                    entityARatio = (EGWsingle)[egwAIGfxCntx bufferWidth] / (EGWsingle)[egwAIGfxCntx bufferHeight];
                                } else if(strcasecmp((const char*)entityAspect, "auto_reverse_fullscreen") == 0) {
                                    entityARatio = (EGWsingle)[egwAIGfxCntx bufferHeight] / (EGWsingle)[egwAIGfxCntx bufferWidth];
                                } else if(strcasecmp((const char*)entityAspect, "3:4") == 0) {
                                    entityARatio = 3.0f / 4.0f;
                                } else if(strcasecmp((const char*)entityAspect, "4:3") == 0) {
                                    entityARatio = 4.0f / 3.0f;
                                } else if(strcasecmp((const char*)entityAspect, "2:3") == 0) {
                                    entityARatio = 2.0f / 3.0f;
                                } else if(strcasecmp((const char*)entityAspect, "3:2") == 0) {
                                    entityARatio = 3.0f / 2.0f;
                                } else {
                                    egwParseStringfcv((EGWchar*)entityAspect, (EGWsingle*)&entityARatio, 0, 1);
                                    entityARatio = egwClampPosf(entityARatio);
                                }
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"aspect");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"znear") == 0) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&entityZNear, 0, 1);
                                entityZNear = egwClampPosf(entityZNear);
                                if(entityZNear > entityZFar) entityZFar = entityZNear;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"znear");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"zfar") == 0) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&entityZFar, 0, 1);
                                entityZFar = egwClampPosf(entityZFar);
                                if(entityZFar < entityZNear) entityZNear = entityZFar;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"zfar");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"offset") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityOffset);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetOffsetDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"offset");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"orient") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityOrient);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"lookat") == 0) {
                                    xmlChar* entityCamPos = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"camera");
                                    xmlChar* entityLookatPos = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"position");
                                    if(entityCamPos) {
                                        egwParseStringfcv((EGWchar*)entityCamPos, (EGWsingle*)&(entityLookat[0]), 0, 3);
                                        xmlFree(entityCamPos); entityCamPos = NULL;
                                    }
                                    if(entityLookatPos) {
                                        egwParseStringfcv((EGWchar*)entityLookatPos, (EGWsingle*)&(entityLookat[1]), 0, 3);
                                        xmlFree(entityLookatPos); entityLookatPos = NULL;
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"lookat");
                                } else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetOrientateDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"orient");
                        }
                        
                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                        if(*retVal != 1) break;
                    }
                    
                    if(*retVal == 1) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwPerspectiveCamera alloc] initWithIdentity:entityIDIdent graspAngle:egwRadToDegf(entityGAngle) fieldOfView:entityFOV aspectRatio:entityARatio frontPlane:entityZNear backPlane:entityZFar])]) {
                            if(!egwMatIsEqual44f(&entityOffset, &egwSIMatIdentity44f)) [(id<egwPCamera>)entity offsetByTransform:&entityOffset];
                            if(!egwMatIsEqual44f(&entityOrient, &egwSIMatIdentity44f)) [(id<egwPCamera>)entity orientateByTransform:&entityOrient];
                            else if(!egwVecIsEqual3f(&entityLookat[0], &egwSIVecZero3f) || !egwVecIsEqual3f(&entityLookat[1], &egwSIVecZero3f)) [(id<egwPCamera>)entity orientateByLookingAt:&entityLookat[1] withCameraAt:&entityLookat[0]];
                            if(entityPerforms.eCount) {
                                egwSinglyLinkedListIter iter;
                                
                                if(egwSLListEnumerateStart(&entityPerforms, EGW_ITERATE_MODE_DFLT, &iter)) {
                                    egwGAMPostPerforms* action;
                                    
                                    while((action = (egwGAMPostPerforms*)egwSLListEnumerateNextPtr(&iter))) {
                                        if(action->object1 && action->object2)
                                            [entity performSelector:action->method withObject:action->object1 withObject:action->object2];
                                        else if(action->object1)
                                            [entity performSelector:action->method withObject:action->object1];
                                        else
                                            [entity performSelector:action->method];
                                    }
                                }
                            }
                            ++(*loadCounter);
                        } else
                            NSLog(@"egwAssetManager: egwGAMXParseCamera: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating perspective camera asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    }
                    
                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                    egwSLListFree(&entityPerforms);
                } else if(entityNodeType && strcasecmp((const char*)entityNodeType, (const char*)"orthogonal") == 0 && !xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                    EGWint nodeType;
                    xmlChar* nodeName = NULL;
                    xmlChar* nodeValue = NULL;
                    EGWsingle entitySDim[2] = { (egwAIGfxCntx ? [egwAIGfxCntx bufferWidth] : 1.0f), (egwAIGfxCntx ? [egwAIGfxCntx bufferHeight] : 1.0f) };
                    EGWsingle entityZFAlign = EGW_CAMERA_ORTHO_ZFALIGN_BTMLFT;
                    EGWsingle entityGAngle = 0.0f;
                    egwMatrix44f entityOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityOffset);
                    egwMatrix44f entityOrient; egwMatCopy44f(&egwSIMatIdentity44f, &entityOrient);
                    egwSinglyLinkedList entityPerforms; egwSLListInit(&entityPerforms, NULL, sizeof(egwGAMPostPerforms), EGW_LIST_FLG_DFLT);
                    
                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                        
                        if(nodeType == 14) continue;
                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"grasp_angle") == 0) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&entityGAngle, 0, 1);
                                entityGAngle = egwDegToRadf(entityGAngle);
                                entityGAngle = egwRadReduce02PIf(entityGAngle);
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"grasp_angle");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"dimensions") == 0) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                xmlChar* entityDims = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                                if(strcasecmp((const char*)entityDims, "auto_fullscreen") == 0) {
                                    entitySDim[0] = (EGWsingle)[egwAIGfxCntx bufferWidth];
                                    entitySDim[1] = (EGWsingle)[egwAIGfxCntx bufferHeight];
                                } else {
                                    egwParseStringfcv((EGWchar*)entityDims, (EGWsingle*)&entitySDim[0], 0, 2);
                                    entitySDim[0] = egwClampPosf(entitySDim[0]);
                                    entitySDim[1] = egwClampPosf(entitySDim[1]);
                                }
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"dimensions");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"zfalign") == 0) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                xmlChar* entityZero = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                                if(strcasecmp((const char*)entityZero, "bottom_left") == 0) entityZFAlign = EGW_CAMERA_ORTHO_ZFALIGN_BTMLFT;
                                else if(strcasecmp((const char*)entityZero, "top_left") == 0) entityZFAlign = EGW_CAMERA_ORTHO_ZFALIGN_TOPLFT;
                                else if(strcasecmp((const char*)entityZero, "center") == 0) entityZFAlign = EGW_CAMERA_ORTHO_ZFALIGN_CENTER;
                                else NSLog(@"egwAssetManager: egwGAMXParseCamera: Failure parsing in manifest input file '%s', for asset '%s': Camera zero offset align '%s' not supported.", resourceFile, entityID, entityZero);
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"zero");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"offset") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityOffset);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetOffsetDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"offset");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"orient") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityOrient);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetOrientateDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"orient");
                        }
                        
                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                        if(*retVal != 1) break;
                    }
                    
                    if(*retVal == 1) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwOrthogonalCamera alloc] initWithIdentity:entityIDIdent graspAngle:egwRadToDegf(entityGAngle) surfaceWidth:entitySDim[0] surfaceHeight:entitySDim[1] zeroAlign:entityZFAlign])]) {
                            if(!egwMatIsEqual44f(&entityOffset, &egwSIMatIdentity44f)) [(id<egwPCamera>)entity offsetByTransform:&entityOffset];
                            if(!egwMatIsEqual44f(&entityOrient, &egwSIMatIdentity44f)) [(id<egwPCamera>)entity orientateByTransform:&entityOrient];
                            if(entityPerforms.eCount) {
                                egwSinglyLinkedListIter iter;
                                
                                if(egwSLListEnumerateStart(&entityPerforms, EGW_ITERATE_MODE_DFLT, &iter)) {
                                    egwGAMPostPerforms* action;
                                    
                                    while((action = (egwGAMPostPerforms*)egwSLListEnumerateNextPtr(&iter))) {
                                        if(action->object1 && action->object2)
                                            [entity performSelector:action->method withObject:action->object1 withObject:action->object2];
                                        else if(action->object1)
                                            [entity performSelector:action->method withObject:action->object1];
                                        else
                                            [entity performSelector:action->method];
                                    }
                                }
                            }
                            ++(*loadCounter);
                        } else
                            NSLog(@"egwAssetManager: egwGAMXParseCamera: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating orthogonal camera asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    }
                    
                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                    egwSLListFree(&entityPerforms);
                } else {
                    NSLog(@"egwAssetManager: egwGAMXParseCamera: Failure parsing in manifest input file '%s', for asset '%s': Camera node malformed or type attribute '%s' not supported.", resourceFile, entityID, (entityNodeType ? (const char*)entityNodeType : (const char*)"<NULL>"));
                }
                
                if(entityNodeType) { xmlFree(entityNodeType); entityNodeType = NULL; }
            } else if (entityRefID) { // Copy/Get
                NSString* entityRefIdent = [[NSString alloc] initWithUTF8String:(const char*)entityRefID];
                id<NSObject> entityRef = (id<NSObject>)[[egwSIAsstMngr retrieveAsset:entityRefIdent] retain];
                
                if(entityRef && entityID) { // Copy
                    if([entityRef isKindOfClass:[egwPerspectiveCamera class]]) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwPerspectiveCamera alloc] initCopyOf:(id<egwPAsset>)entityRef withIdentity:entityIDIdent])])
                            ++(*loadCounter);
                        else
                            NSLog(@"egwAssetManager: egwGAMXParseCamera: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating perspective camera asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    } else if([entityRef isKindOfClass:[egwOrthogonalCamera class]]) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwOrthogonalCamera alloc] initCopyOf:(id<egwPAsset>)entityRef withIdentity:entityIDIdent])])
                            ++(*loadCounter);
                        else
                            NSLog(@"egwAssetManager: egwGAMXParseCamera: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating orthogonal camera asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    } else {
                        NSLog(@"egwAssetManager: egwGAMXParseCamera: Failure parsing in manifest input file '%s', for asset '%s': Copying camera class type '%@' not supported.", resourceFile, entityID, [entityRef class]);
                    }
                    
                    if(entity) { // Shared unique properties (offset/orient)
                        if(!xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                            EGWint nodeType;
                            xmlChar* nodeName = NULL;
                            xmlChar* nodeValue = NULL;
                            egwMatrix44f entityOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityOffset);
                            egwMatrix44f entityOrient; egwMatCopy44f(&egwSIMatIdentity44f, &entityOrient);
                            egwVector3f entityLookat[2]; egwVecCopy3fv(&egwSIVecZero3f, entityLookat, -sizeof(egwVector3f), 0, 2);
                            
                            while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                
                                if(nodeType == 14) continue;
                                else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                                else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"offset") == 0) {
                                    while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                        if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                            egwGAMXParseTransform(xmlReadHandle, retVal, &entityOffset);
                                        else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                            id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                            if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                                [(id<egwPOrientated>)entity trySetOffsetDriver:(id<egwPInterpolator>)entityIPORef];
                                            }
                                            [entityIPORef release]; entityIPORef = nil;
                                        }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"offset");
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"orient") == 0) {
                                    while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                        if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                            egwGAMXParseTransform(xmlReadHandle, retVal, &entityOrient);
                                        else if([entityRef isKindOfClass:[egwPerspectiveCamera class]] && strcasecmp((const char*)nodeValue, (const char*)"lookat") == 0) {
                                            xmlChar* entityCamPos = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"camera");
                                            xmlChar* entityLookatPos = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"position");
                                            if(entityCamPos) {
                                                egwParseStringfcv((EGWchar*)entityCamPos, (EGWsingle*)&(entityLookat[0]), 0, 3);
                                                xmlFree(entityCamPos); entityCamPos = NULL;
                                            }
                                            if(entityLookatPos) {
                                                egwParseStringfcv((EGWchar*)entityLookatPos, (EGWsingle*)&(entityLookat[1]), 0, 3);
                                                xmlFree(entityLookatPos); entityLookatPos = NULL;
                                            }
                                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"lookat");
                                        } else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                            id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                            if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                                [(id<egwPOrientated>)entity trySetOrientateDriver:(id<egwPInterpolator>)entityIPORef];
                                            }
                                            [entityIPORef release]; entityIPORef = nil;
                                        }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"orient");
                                }
                                
                                if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            
                            if(*retVal == 1) {
                                if(!egwMatIsEqual44f(&entityOffset, &egwSIMatIdentity44f)) [(id<egwPOrientated>)entity offsetByTransform:&entityOffset];
                                if(!egwMatIsEqual44f(&entityOrient, &egwSIMatIdentity44f)) [(id<egwPOrientated>)entity orientateByTransform:&entityOrient];
                                else if(!egwVecIsEqual3f(&entityLookat[0], &egwSIVecZero3f) || !egwVecIsEqual3f(&entityLookat[1], &egwSIVecZero3f)) [(id<egwPCamera>)entity orientateByLookingAt:&entityLookat[1] withCameraAt:&entityLookat[0]];
                            }
                            
                            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                        }
                    }
                } else if(entityRef && !entityID) { // Get
                    entity = [entityRef retain];
                    egwGAMXParseSkip(xmlReadHandle, retVal, entityNodeName);
                } else {
                    NSLog(@"egwAssetManager: egwGAMXParseCamera: Failure parsing in manifest input file '%s', for asset '%s': Camera asset '%@' does not exist.", resourceFile, entityID, entityRefIdent);
                }
                
                [entityRefIdent release]; entityRefIdent = nil;
                [entityRef release]; entityRef = nil;
            } else {
                NSLog(@"egwAssetManager: egwGAMXParseCamera: Failure parsing in manifest input file '%s', for asset '%s': Camera node must contain an ID and/or reference an ID.", resourceFile, entityID);
            }
            
            if(entityID) { xmlFree(entityID); entityID = NULL; }
            if(entityRefID) { xmlFree(entityRefID); entityRefID = NULL; }
        } else {
            NSLog(@"egwAssetManager: egwGAMXParseCamera: Failure parsing in manifest input file '%s', for asset '%s': Camera node type '%s' not supported.", resourceFile, entityID, entityNodeName);
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, entityNodeName);
    }
    
    return entity;
}

// TODO: Switch egwGAMXParseFont to egwGAMXFontParams structure usage. -jw

id<NSObject> egwGAMXParseFont(const EGWchar* resourceFile, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* loadCounter, const xmlChar* entityNodeName) {
    id<NSObject> entity = nil;
    xmlChar* entityID = NULL;
    xmlChar* entityRefID = NULL;
    
    if(entityNodeName) {
        if(strcasecmp((const char*)entityNodeName, (const char*)"font") == 0) {
            entityID = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"id");
            entityRefID = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"ref");
            
            if(entityID && !entityRefID) { // New
                xmlChar* entityNodeType = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"type");
                
                if((!entityNodeType || strcasecmp((const char*)entityNodeType, (const char*)"bitmapped") == 0) && !xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                    EGWint nodeType;
                    xmlChar* nodeName = NULL;
                    xmlChar* nodeValue = NULL;
                    egwAMGlyphSet entityFGlyphmap; memset((void*)&entityFGlyphmap, 0, sizeof(egwAMGlyphSet));
                    EGWint entityFType = -1; // invalid type = -1, glyphmap = 0
                    EGWuint entityFEffects = 0;
                    egwColorRGBA entityGColor; entityGColor.channel.r = entityGColor.channel.g = entityGColor.channel.b = 0; entityGColor.channel.a = 255;
                    
                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                        
                        if(nodeType == 14) continue;
                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"glyphmap") == 0 && !xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                            xmlChar* entitySourceSrc = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"source");
                            
                            if(!entitySourceSrc || strcasecmp((const char*)entitySourceSrc, (const char*)"external") == 0) {
                                egwGAMXParseGlyphmap_External(resourceFile, entityID, xmlReadHandle, retVal, &entityFGlyphmap, &entityFEffects);
                                
                                if(*retVal == 1) {
                                    if(entityFGlyphmap.glyphs)
                                        entityFType = 1; // glyphmap
                                }
                            //} else if(strcasecmp((const char*)entitySourceSrc, (const char*)"internal") == 0) {
                                // TODO: Font read internal glyphmap.
                            } else NSLog(@"egwAssetManager: egwGAMXParseFont: Failure parsing in manifest input file '%s', for asset '%s': Surface source '%s' not supported.", resourceFile, entityID, (entitySourceSrc ? (const char*)entitySourceSrc : (const char*)"<NULL>"));
                            
                            if(entitySourceSrc) { xmlFree(entitySourceSrc); entitySourceSrc = NULL; }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"glyphmap");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"color") == 0) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                egwColor4f entityColor; entityColor.channel.r = entityColor.channel.g = entityColor.channel.b = 0.0f; entityColor.channel.a = 1.0f;
                                egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&entityColor, 0, 4);
                                egwClrConvert4fRGBA(egwClrClamp4f(&entityColor, &entityColor), &entityGColor);
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"color");
                        }
                        
                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                        if(*retVal != 1) break;
                    }
                    
                    if(*retVal == 1) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if((entityFType == 0 && // glyphmap
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwBitmappedFont alloc] initWithIdentity:entityIDIdent glyphSet:&entityFGlyphmap glyphColor:&entityGColor])])) {
                                ++(*loadCounter);
                        } else
                            NSLog(@"egwAssetManager: egwGAMXParseFont: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating bitmapped font asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    }
                    
                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                    for(EGWchar charIndex = 33; charIndex <= 126; ++charIndex) {
                        if(entityFGlyphmap.glyphs[charIndex - 33].gaData) {
                            free((void*)(entityFGlyphmap.glyphs[charIndex - 33].gaData));
                            entityFGlyphmap.glyphs[charIndex - 33].gaData = NULL;
                        }
                    }
                } else {
                    NSLog(@"egwAssetManager: egwGAMXParseFont: Failure parsing in manifest input file '%s', for asset '%s': Font node malformed or type attribute '%s' not supported.", resourceFile, entityID, (entityNodeType ? (const char*)entityNodeType : (const char*)"<NULL>"));
                }
                
                if(entityNodeType) { xmlFree(entityNodeType); entityNodeType = NULL; }
            } else if (entityRefID) { // Copy/Get
                NSString* entityRefIdent = [[NSString alloc] initWithUTF8String:(const char*)entityRefID];
                id<NSObject> entityRef = (id<NSObject>)[[egwSIAsstMngr retrieveAsset:entityRefIdent] retain];
                
                if(entityRef && entityID) { // Copy
                    if([entityRef isKindOfClass:[egwBitmappedFont class]]) {
                        egwColorRGBA entityGColor; memcpy((void*)&entityGColor, (const void*)[(egwBitmappedFont*)entityRef glyphColor], sizeof(egwColorRGBA));
                        
                        if(!xmlTextReaderIsEmptyElement(xmlReadHandle)) { // Unique class properties (color)
                            EGWint nodeType;
                            xmlChar* nodeName = NULL;
                            xmlChar* nodeValue = NULL;
                            
                            while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                
                                if(nodeType == 14) continue;
                                else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                                else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"color") == 0) {
                                    if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                        egwColor4f entityColor; entityColor.channel.r = entityColor.channel.g = entityColor.channel.b = 0.0f; entityColor.channel.a = 1.0f;
                                        egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&entityColor, 0, 4);
                                        egwClrConvert4fRGBA(egwClrClamp4f(&entityColor, &entityColor), &entityGColor);
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"color");
                                }
                                
                                if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            
                            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                        }
                        
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwBitmappedFont alloc] initCopyOf:(id<egwPAsset>)entityRef withIdentity:entityIDIdent glyphColor:&entityGColor])])
                            ++(*loadCounter);
                        else
                            NSLog(@"egwAssetManager: egwGAMXParseFont: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating bitmapped font asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    } else {
                        NSLog(@"egwAssetManager: egwGAMXParseFont: Failure parsing in manifest input file '%s', for asset '%s': Copying font class type '%@' not supported.", resourceFile, entityID, [entityRef class]);
                    }
                } else if(entityRef && !entityID) { // Get
                    entity = [entityRef retain];
                } else {
                    NSLog(@"egwAssetManager: egwGAMXParseFont: Failure parsing in manifest input file '%s', for asset '%s': Font asset '%@' does not exist.", resourceFile, entityID, entityRefIdent);
                }
                
                [entityRefIdent release]; entityRefIdent = nil;
                [entityRef release]; entityRef = nil;
            } else {
                NSLog(@"egwAssetManager: egwGAMXParseFont: Failure parsing in manifest input file '%s', for asset '%s': Font node must contain an ID and/or reference an ID.", resourceFile, entityID);
            }
            
            if(entityID) { xmlFree(entityID); entityID = NULL; }
            if(entityRefID) { xmlFree(entityRefID); entityRefID = NULL; }
        } else {
            NSLog(@"egwAssetManager: egwGAMXParseFont: Failure parsing in manifest input file '%s', for asset '%s': Font node type '%s' not supported.", resourceFile, entityID, entityNodeName);
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, entityNodeName);
    }
    
    return entity;
}

// Instantiation type and distinct parameter values for interpolator parsing
typedef struct {
    EGWint16 type; // invalid type = -1, value interpolator = 0, orientation interpolator = 1
    EGWint16 srcType; // invalid type = -1, value keyframes = 0, value blank = 1, orientation keyframes = 2, orientation blank = 3
    union {
        struct { egwKeyFrame keyframes; EGWuint32 polation; } vikfrm; // value keyframes = 0
        struct { EGWuint16 format; EGWuint kFrames; EGWuint kComponents; EGWuint kChannels; EGWuint32 polation; } viblnk; // value blank = 1
        struct { egwOrientKeyFrame4f keyframes; EGWuint32 pPolation; EGWuint32 rPolation; EGWuint32 sPolation; } oikfrm; // orientation keyframes = 2
        struct { EGWuint pFrames; EGWuint rFrames; EGWuint sFrames; EGWuint32 pPolation; EGWuint32 rPolation; EGWuint32 sPolation; } oiblnk; // orientation blank = 3
    } dist;
} egwGAMXInterpolatorParams;

id<NSObject> egwGAMXParseInterpolator(const EGWchar* resourceFile, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* loadCounter, const xmlChar* entityNodeName) {
    id<NSObject> entity = nil;
    xmlChar* entityID = NULL;
    xmlChar* entityRefID = NULL;
    
    if(entityNodeName) {
        if(strcasecmp((const char*)entityNodeName, (const char*)"interpolator") == 0) {
            entityID = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"id");
            entityRefID = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"ref");
            
            if(entityID && !entityRefID) { // New
                xmlChar* entityNodeType = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"type");
                
                if((!entityNodeType || (strcasecmp((const char*)entityNodeType, (const char*)"value") == 0 || strcasecmp((const char*)entityNodeType, (const char*)"orientation") == 0)) && !xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                    EGWint nodeType;
                    xmlChar* nodeName = NULL;
                    xmlChar* nodeValue = NULL;
                    egwGAMXInterpolatorParams entityParams; memset((void*)&entityParams, 0, sizeof(egwGAMXInterpolatorParams)); entityParams.type = entityParams.srcType = -1;
                    id<egwPTimer> entityIController = nil;
                    
                    if(!entityNodeType || strcasecmp((const char*)entityNodeType, (const char*)"value") == 0)
                        entityParams.type = 0; // value interpolator
                    else if(strcasecmp((const char*)entityNodeType, (const char*)"orientation") == 0)
                        entityParams.type = 1; // orientation interpolator
                    
                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                        
                        if(nodeType == 14) continue;
                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"keyframes") == 0 && !xmlTextReaderIsEmptyElement(xmlReadHandle) && entityParams.type == 0) {
                            xmlChar* entitySourceSrc = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"source");
                            
                            if(!entitySourceSrc || strcasecmp((const char*)entitySourceSrc, (const char*)"internal") == 0) {
                                xmlChar* entitySourceType = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"type");
                                
                                if(entitySourceType && strcasecmp((const char*)entitySourceType, (const char*)"value_array") == 0) {
                                    egwGAMXParseKeyFrames_VA(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.vikfrm.keyframes);
                                    
                                    if(*retVal == 1) {
                                        if(entityParams.dist.vikfrm.keyframes.tIndicies && entityParams.dist.vikfrm.keyframes.fKeys)
                                            entityParams.srcType = 0; // value keyframes
                                    }
                                } else if(entitySourceType && strcasecmp((const char*)entitySourceType, (const char*)"blank") == 0) {
                                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                    
                                    // blank read
                                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                        
                                        if(nodeType == 14) continue;
                                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"keyframes") == 0) break;
                                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"channel_format") == 0) {
                                            egwGAMXParseKeyFrames_ChFormat(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.viblnk.format);
                                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"frames") == 0) {
                                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                                egwParseStringuicv((EGWchar*)nodeValue, (EGWuint*)&entityParams.dist.viblnk.kFrames, 0, 1);
                                                entityParams.dist.viblnk.kFrames = egwClampui(entityParams.dist.viblnk.kFrames, 1, EGW_UINT16_MAX);
                                            }
                                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"frames");
                                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"components") == 0) {
                                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                                egwParseStringuicv((EGWchar*)nodeValue, (EGWuint*)&entityParams.dist.viblnk.kComponents, 0, 1);
                                                entityParams.dist.viblnk.kComponents = egwClampui(entityParams.dist.viblnk.kComponents, 1, EGW_UINT16_MAX);
                                            }
                                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"components");
                                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"channels") == 0) {
                                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                                egwParseStringuicv((EGWchar*)nodeValue, (EGWuint*)&entityParams.dist.viblnk.kChannels, 0, 1);
                                                entityParams.dist.viblnk.kChannels = egwClampui(entityParams.dist.viblnk.kChannels, 1, EGW_UINT16_MAX);
                                            }
                                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"channels");
                                        }
                                        
                                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    
                                    if(*retVal == 1) {
                                        entityParams.srcType = 1; // value blank
                                    }
                                } else NSLog(@"egwAssetManager: egwGAMXParseInterpolator: Failure parsing in manifest input file '%s', for asset '%s': Keyframe internal type '%s' not supported.", resourceFile, entityID, (entitySourceType ? (const char*)entitySourceType : (const char*)"<NULL>"));
                                
                                if(entitySourceType) { xmlFree(entitySourceType); entitySourceType = NULL; }
                            //} else if(strcasecmp((const char*)entitySourceSrc, (const char*)"external") == 0) {
                                // TODO: Value ipo read external keyframes.
                            } else NSLog(@"egwAssetManager: egwGAMXParseInterpolator: Failure parsing in manifest input file '%s', for asset '%s': Keyframe source '%s' not supported.", resourceFile, entityID, (entitySourceSrc ? (const char*)entitySourceSrc : (const char*)"<NULL>"));
                            
                            if(entitySourceSrc) { xmlFree(entitySourceSrc); entitySourceSrc = NULL; }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"keyframes");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"keyframes") == 0 && !xmlTextReaderIsEmptyElement(xmlReadHandle) && entityParams.type == 1) {
                            xmlChar* entitySourceSrc = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"source");
                            
                            if(!entitySourceSrc || strcasecmp((const char*)entitySourceSrc, (const char*)"internal") == 0) {
                                xmlChar* entitySourceType = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"type");
                                
                                if(entitySourceType && strcasecmp((const char*)entitySourceType, (const char*)"prs_array") == 0) {
                                    egwGAMXParseKeyFrames_PRSA(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.oikfrm.keyframes);
                                    
                                    if(*retVal == 1) {
                                        if((entityParams.dist.oikfrm.keyframes.ptIndicies && entityParams.dist.oikfrm.keyframes.pfKeys) ||
                                           (entityParams.dist.oikfrm.keyframes.rtIndicies && entityParams.dist.oikfrm.keyframes.rfKeys) ||
                                           (entityParams.dist.oikfrm.keyframes.stIndicies && entityParams.dist.oikfrm.keyframes.sfKeys))
                                            entityParams.srcType = 2; // orientation keyframes
                                    }
                                } else if(entitySourceType && strcasecmp((const char*)entitySourceType, (const char*)"blank") == 0) {
                                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                    
                                    // blank read
                                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                        
                                        if(nodeType == 14) continue;
                                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"keyframes") == 0) break;
                                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"pos_frames") == 0) {
                                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                                egwParseStringuicv((EGWchar*)nodeValue, (EGWuint*)&entityParams.dist.oiblnk.pFrames, 0, 1);
                                                entityParams.dist.oiblnk.pFrames = egwClampui(entityParams.dist.oiblnk.pFrames, 1, EGW_UINT16_MAX);
                                            }
                                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"pos_frames");
                                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"rot_frames") == 0) {
                                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                                egwParseStringuicv((EGWchar*)nodeValue, (EGWuint*)&entityParams.dist.oiblnk.rFrames, 0, 1);
                                                entityParams.dist.oiblnk.rFrames = egwClampui(entityParams.dist.oiblnk.rFrames, 1, EGW_UINT16_MAX);
                                            }
                                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"rot_frames");
                                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"scl_frames") == 0) {
                                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                                egwParseStringuicv((EGWchar*)nodeValue, (EGWuint*)&entityParams.dist.oiblnk.sFrames, 0, 1);
                                                entityParams.dist.oiblnk.sFrames = egwClampui(entityParams.dist.oiblnk.sFrames, 1, EGW_UINT16_MAX);
                                            }
                                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"scl_frames");
                                        }
                                        
                                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    
                                    if(*retVal == 1) {
                                        entityParams.srcType = 3; // orientation blank
                                    }
                                } else NSLog(@"egwAssetManager: egwGAMXParseInterpolator: Failure parsing in manifest input file '%s', for asset '%s': Keyframe internal type '%s' not supported.", resourceFile, entityID, (entitySourceType ? (const char*)entitySourceType : (const char*)"<NULL>"));
                                
                                if(entitySourceType) { xmlFree(entitySourceType); entitySourceType = NULL; }
                            //} else if(strcasecmp((const char*)entitySourceSrc, (const char*)"external") == 0) {
                                // TODO: Orientation ipo read external keyframes.
                            } else NSLog(@"egwAssetManager: egwGAMXParseInterpolator: Failure parsing in manifest input file '%s', for asset '%s': Keyframe source '%s' not supported.", resourceFile, entityID, (entitySourceSrc ? (const char*)entitySourceSrc : (const char*)"<NULL>"));
                            
                            if(entitySourceSrc) { xmlFree(entitySourceSrc); entitySourceSrc = NULL; }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"keyframes");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"controller") == 0) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                id<NSObject> entityTRef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                if(entityTRef && [entityTRef conformsToProtocol:@protocol(egwPTimer)]) {
                                    [entityIController release]; entityIController = nil;
                                    entityIController = (id<egwPTimer>)[entityTRef retain];
                                } else {
                                    NSLog(@"egwAssetManager: egwGAMXParseInterpolator: Failure parsing in manifest input file '%s', for asset '%s': Controller timer type '%s' not supported.", resourceFile, entityID, nodeValue);
                                    egwGAMXParseSkip(xmlReadHandle, retVal, nodeValue);
                                }
                                [entityTRef release]; entityTRef = nil;
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"controller");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"polation") == 0 && (entityParams.type == 0 || entityParams.type == 1)) {
                            if(entityParams.type == 0) {
                                if(entityParams.srcType == 0)
                                    egwGAMXParseKeyFrames_Polation(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.vikfrm.polation);
                                else
                                    egwGAMXParseKeyFrames_Polation(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.viblnk.polation);
                            } else if(entityParams.type == 1) {
                                if(entityParams.srcType == 2) {
                                    egwGAMXParseKeyFrames_Polation(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.oikfrm.pPolation);
                                    entityParams.dist.oikfrm.rPolation = entityParams.dist.oikfrm.sPolation = entityParams.dist.oikfrm.pPolation;
                                } else {
                                    egwGAMXParseKeyFrames_Polation(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.oiblnk.pPolation);
                                    entityParams.dist.oiblnk.rPolation = entityParams.dist.oiblnk.sPolation = entityParams.dist.oiblnk.pPolation;
                                }
                            }
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"pos_polation") == 0 && entityParams.type == 1) {
                            if(entityParams.srcType == 2)
                                egwGAMXParseKeyFrames_Polation(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.oikfrm.pPolation);
                            else
                                egwGAMXParseKeyFrames_Polation(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.oiblnk.pPolation);
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"rot_polation") == 0 && entityParams.type == 1) {
                            if(entityParams.srcType == 2)
                                egwGAMXParseKeyFrames_Polation(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.oikfrm.rPolation);
                            else
                                egwGAMXParseKeyFrames_Polation(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.oiblnk.rPolation);
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"scl_polation") == 0 && entityParams.type == 1) {
                            if(entityParams.srcType == 2)
                                egwGAMXParseKeyFrames_Polation(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.oikfrm.sPolation);
                            else
                                egwGAMXParseKeyFrames_Polation(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.oiblnk.sPolation);
                        }
                        
                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                        if(*retVal != 1) break;
                    }
                    
                    if(*retVal == 1) {
                        // Do automatic time indicies reduction for overlapping time indicies
                        if(entityParams.srcType == 2) { // orientation keyframes
                            // Check pos against rot
                            if(entityParams.dist.oikfrm.keyframes.pfCount &&
                               entityParams.dist.oikfrm.keyframes.pfCount == entityParams.dist.oikfrm.keyframes.rfCount &&
                               entityParams.dist.oikfrm.keyframes.ptIndicies != entityParams.dist.oikfrm.keyframes.rtIndicies) {
                                BOOL match = YES;
                                
                                for(EGWuint tIndex = 0; tIndex < (EGWuint)entityParams.dist.oikfrm.keyframes.pfCount; ++tIndex)
                                    if(!egwIsEqualm(entityParams.dist.oikfrm.keyframes.ptIndicies[tIndex], entityParams.dist.oikfrm.keyframes.rtIndicies[tIndex])) {
                                        match = NO;
                                        break;
                                    }
                                
                                if(match) {
                                    free((void*)entityParams.dist.oikfrm.keyframes.ptIndicies);
                                    entityParams.dist.oikfrm.keyframes.ptIndicies = entityParams.dist.oikfrm.keyframes.rtIndicies;
                                }
                            }
                            
                            // Check pos against scl
                            if(entityParams.dist.oikfrm.keyframes.pfCount &&
                               entityParams.dist.oikfrm.keyframes.pfCount == entityParams.dist.oikfrm.keyframes.sfCount &&
                               entityParams.dist.oikfrm.keyframes.ptIndicies != entityParams.dist.oikfrm.keyframes.stIndicies) {
                                BOOL match = YES;
                                
                                for(EGWuint tIndex = 0; tIndex < (EGWuint)entityParams.dist.oikfrm.keyframes.pfCount; ++tIndex)
                                    if(!egwIsEqualm(entityParams.dist.oikfrm.keyframes.ptIndicies[tIndex], entityParams.dist.oikfrm.keyframes.stIndicies[tIndex])) {
                                        match = NO;
                                        break;
                                    }
                                
                                if(match) {
                                    if(entityParams.dist.oikfrm.keyframes.ptIndicies != entityParams.dist.oikfrm.keyframes.rtIndicies)
                                        free((void*)entityParams.dist.oikfrm.keyframes.ptIndicies);
                                    else {
                                        free((void*)entityParams.dist.oikfrm.keyframes.rtIndicies);
                                        entityParams.dist.oikfrm.keyframes.rtIndicies = entityParams.dist.oikfrm.keyframes.stIndicies;
                                    }
                                    entityParams.dist.oikfrm.keyframes.ptIndicies = entityParams.dist.oikfrm.keyframes.stIndicies;
                                }
                            }
                            
                            // Check rot against scl
                            if(entityParams.dist.oikfrm.keyframes.rfCount &&
                               entityParams.dist.oikfrm.keyframes.rfCount == entityParams.dist.oikfrm.keyframes.sfCount &&
                               entityParams.dist.oikfrm.keyframes.rtIndicies != entityParams.dist.oikfrm.keyframes.stIndicies) {
                                BOOL match = YES;
                                
                                for(EGWuint tIndex = 0; tIndex < (EGWuint)entityParams.dist.oikfrm.keyframes.pfCount; ++tIndex)
                                    if(!egwIsEqualm(entityParams.dist.oikfrm.keyframes.rtIndicies[tIndex], entityParams.dist.oikfrm.keyframes.stIndicies[tIndex])) {
                                        match = NO;
                                        break;
                                    }
                                
                                if(match) {
                                    free((void*)entityParams.dist.oikfrm.keyframes.rtIndicies);
                                    entityParams.dist.oikfrm.keyframes.rtIndicies = entityParams.dist.oikfrm.keyframes.stIndicies;
                                }
                            }
                        }
                        
                        // Do automatic extra data fill in for extra data need
                        if(entityParams.srcType == 0) { // value keyframes
                            EGWuint32 efdPitch = egwIpoExtFrmDatFrmPitch(entityParams.dist.vikfrm.keyframes.kcFormat, entityParams.dist.vikfrm.keyframes.kcCount, entityParams.dist.vikfrm.keyframes.cCount, entityParams.dist.vikfrm.polation);
                            
                            if(efdPitch) {
                                if(entityParams.dist.vikfrm.keyframes.kfExtraDat = (EGWbyte*)malloc((size_t)efdPitch * (size_t)entityParams.dist.vikfrm.keyframes.fCount)) {
                                    EGWcefdfuncfp createFP = egwIpoCreateExtFrmDatRoutine(entityParams.dist.vikfrm.keyframes.kcFormat, entityParams.dist.vikfrm.polation);
                                    
                                    if(createFP)
                                        createFP((const EGWbyte*)entityParams.dist.vikfrm.keyframes.fKeys, (EGWbyte*)entityParams.dist.vikfrm.keyframes.kfExtraDat, 
                                                 (entityParams.dist.vikfrm.keyframes.kcFormat & EGW_KEYCHANNEL_FRMT_EXBPC) * entityParams.dist.vikfrm.keyframes.kcCount,
                                                 (entityParams.dist.vikfrm.keyframes.kcFormat & EGW_KEYCHANNEL_FRMT_EXBPC) * entityParams.dist.vikfrm.keyframes.kcCount * entityParams.dist.vikfrm.keyframes.cCount,
                                                 egwIpoExtFrmDatCmpPitch(entityParams.dist.vikfrm.keyframes.kcFormat, entityParams.dist.vikfrm.keyframes.kcCount, entityParams.dist.vikfrm.polation), efdPitch,
                                                 (EGWuint)entityParams.dist.vikfrm.keyframes.fCount, (EGWuint)entityParams.dist.vikfrm.keyframes.cCount, (EGWuint)entityParams.dist.vikfrm.keyframes.kcCount);
                                    else {
                                        NSLog(@"egwAssetManager: egwGAMXParseInterpolator: Failure parsing in manifest input file '%s', for asset '%s': The polation mode required extra frame data but no handler is in place to calculate it.", resourceFile, entityID);
                                        free((void*)entityParams.dist.vikfrm.keyframes.kfExtraDat); entityParams.dist.vikfrm.keyframes.kfExtraDat = NULL;
                                    }
                                } else {
                                    NSLog(@"egwAssetManager: egwGAMXParseInterpolator: Failure parsing in manifest input file '%s', for asset '%s': Failure allocated %d bytes for extra frame data.", resourceFile, entityID, (size_t)efdPitch * (size_t)entityParams.dist.vikfrm.keyframes.fCount);
                                }
                            }
                        } else if(entityParams.srcType == 2) { // orientation keyframes
                            EGWuint32 efdPitch = egwIpoExtFrmDatFrmPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 3, 1, entityParams.dist.oikfrm.pPolation);
                            
                            if(efdPitch) {
                                if(entityParams.dist.oikfrm.keyframes.pkfExtraDat = (EGWbyte*)malloc((size_t)efdPitch * (size_t)entityParams.dist.oikfrm.keyframes.pfCount)) {
                                    EGWcefdfuncfp createFP = egwIpoCreateExtFrmDatRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, entityParams.dist.oikfrm.pPolation);
                                    if(createFP)
                                        createFP((const EGWbyte*)entityParams.dist.oikfrm.keyframes.pfKeys, (EGWbyte*)entityParams.dist.oikfrm.keyframes.pkfExtraDat, 
                                                 sizeof(egwVector3f), sizeof(egwVector3f), egwIpoExtFrmDatCmpPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 3, entityParams.dist.oikfrm.pPolation), efdPitch,
                                                 (EGWuint)entityParams.dist.oikfrm.keyframes.pfCount, 1, 3);
                                    else {
                                        NSLog(@"egwAssetManager: egwGAMXParseInterpolator: Failure parsing in manifest input file '%s', for asset '%s': The position polation mode required extra frame data but no handler is in place to calculate it.", resourceFile, entityID);
                                        free((void*)entityParams.dist.oikfrm.keyframes.pkfExtraDat); entityParams.dist.oikfrm.keyframes.pkfExtraDat = NULL;
                                    }
                                } else {
                                    NSLog(@"egwAssetManager: egwGAMXParseInterpolator: Failure parsing in manifest input file '%s', for asset '%s': Failure allocated %d bytes for extra position frame data.", resourceFile, entityID, (size_t)efdPitch * (size_t)entityParams.dist.oikfrm.keyframes.pfCount);
                                }
                            }
                            
                            efdPitch = egwIpoExtFrmDatFrmPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 4, 1, entityParams.dist.oikfrm.rPolation);
                            
                            if(efdPitch) {
                                if(entityParams.dist.oikfrm.keyframes.rkfExtraDat = (EGWbyte*)malloc((size_t)efdPitch * (size_t)entityParams.dist.oikfrm.keyframes.rfCount)) {
                                    EGWcefdfuncfp createFP = egwIpoCreateExtFrmDatRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, entityParams.dist.oikfrm.rPolation);
                                    if(createFP)
                                        createFP((const EGWbyte*)entityParams.dist.oikfrm.keyframes.rfKeys, (EGWbyte*)entityParams.dist.oikfrm.keyframes.rkfExtraDat, 
                                                 sizeof(egwQuaternion4f), sizeof(egwQuaternion4f), egwIpoExtFrmDatCmpPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 4, entityParams.dist.oikfrm.rPolation), efdPitch,
                                                 (EGWuint)entityParams.dist.oikfrm.keyframes.rfCount, 1, 4);
                                    else {
                                        NSLog(@"egwAssetManager: egwGAMXParseInterpolator: Failure parsing in manifest input file '%s', for asset '%s': The rotation polation mode required extra frame data but no handler is in place to calculate it.", resourceFile, entityID);
                                        free((void*)entityParams.dist.oikfrm.keyframes.rkfExtraDat); entityParams.dist.oikfrm.keyframes.rkfExtraDat = NULL;
                                    }
                                } else {
                                    NSLog(@"egwAssetManager: egwGAMXParseInterpolator: Failure parsing in manifest input file '%s', for asset '%s': Failure allocated %d bytes for extra rotation frame data.", resourceFile, entityID, (size_t)efdPitch * (size_t)entityParams.dist.oikfrm.keyframes.rfCount);
                                }
                            }
                            
                            efdPitch = egwIpoExtFrmDatFrmPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 3, 1, entityParams.dist.oikfrm.sPolation);
                            
                            if(efdPitch) {
                                if(entityParams.dist.oikfrm.keyframes.skfExtraDat = (EGWbyte*)malloc((size_t)efdPitch * (size_t)entityParams.dist.oikfrm.keyframes.sfCount)) {
                                    EGWcefdfuncfp createFP = egwIpoCreateExtFrmDatRoutine(EGW_KEYCHANNEL_FRMT_SINGLE, entityParams.dist.oikfrm.sPolation);
                                    if(createFP)
                                        createFP((const EGWbyte*)entityParams.dist.oikfrm.keyframes.sfKeys, (EGWbyte*)entityParams.dist.oikfrm.keyframes.skfExtraDat, 
                                                 sizeof(egwVector3f), sizeof(egwVector3f), egwIpoExtFrmDatCmpPitch(EGW_KEYCHANNEL_FRMT_SINGLE, 3, entityParams.dist.oikfrm.sPolation), efdPitch,
                                                 (EGWuint)entityParams.dist.oikfrm.keyframes.sfCount, 1, 3);
                                    else {
                                        NSLog(@"egwAssetManager: egwGAMXParseInterpolator: Failure parsing in manifest input file '%s', for asset '%s': The scale polation mode required extra frame data but no handler is in place to calculate it.", resourceFile, entityID);
                                        free((void*)entityParams.dist.oikfrm.keyframes.skfExtraDat); entityParams.dist.oikfrm.keyframes.skfExtraDat = NULL;
                                    }
                                } else {
                                    NSLog(@"egwAssetManager: egwGAMXParseInterpolator: Failure parsing in manifest input file '%s', for asset '%s': Failure allocated %d bytes for extra scale frame data.", resourceFile, entityID, (size_t)efdPitch * (size_t)entityParams.dist.oikfrm.keyframes.sfCount);
                                }
                            }
                        }
                        
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if((entityParams.srcType == 0 && // value keyframes
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwValueInterpolator alloc] initWithIdentity:entityIDIdent keyFrames:&entityParams.dist.vikfrm.keyframes polationMode:entityParams.dist.vikfrm.polation])]) ||
                           (entityParams.srcType == 1 && // value blank
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwValueInterpolator alloc] initBlankWithIdentity:entityIDIdent channelFormat:entityParams.dist.viblnk.format channelCount:entityParams.dist.viblnk.kChannels componentCount:entityParams.dist.viblnk.kComponents frameCount:entityParams.dist.viblnk.kFrames polationMode:entityParams.dist.viblnk.polation])]) ||
                           (entityParams.srcType == 2 && // orientation keyframes
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwOrientationInterpolator alloc] initWithIdentity:entityIDIdent keyFrames:&entityParams.dist.oikfrm.keyframes positionPolationMode:entityParams.dist.oikfrm.pPolation rotationPolationMode:entityParams.dist.oikfrm.rPolation scalePolationMode:entityParams.dist.oikfrm.sPolation])]) ||
                           (entityParams.srcType == 3 && // orientation blank
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwOrientationInterpolator alloc] initBlankWithIdentity:entityIDIdent positionFrameCount:entityParams.dist.oiblnk.pFrames positionPolationMode:entityParams.dist.oiblnk.pPolation rotationFrameCount:entityParams.dist.oiblnk.rFrames rotationPolationMode:entityParams.dist.oiblnk.rPolation scaleFrameCount:entityParams.dist.oiblnk.sFrames scalePolationMode:entityParams.dist.oiblnk.sPolation])])) {
                            if(entityIController) [(id<egwPTimed>)entity setEvaluationTimer:entityIController];
                            ++(*loadCounter);
                        } else
                            NSLog(@"egwAssetManager: egwGAMXParseInterpolator: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating interpolator asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    }
                    
                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                    [entityIController release]; entityIController = nil;
                    if(entityParams.srcType == 0) {
                        egwKeyFrmFree(&entityParams.dist.vikfrm.keyframes);
                    }
                    if(entityParams.srcType == 2) {
                        egwOrtKeyFrmFree(&entityParams.dist.oikfrm.keyframes);
                    }
                } else {
                    NSLog(@"egwAssetManager: egwGAMXParseInterpolator: Failure parsing in manifest input file '%s', for asset '%s': Interpolator node malformed or type attribute '%s' not supported.", resourceFile, entityID, (entityNodeType ? (const char*)entityNodeType : (const char*)"<NULL>"));
                }
                
                if(entityNodeType) { xmlFree(entityNodeType); entityNodeType = NULL; }
            } else if (entityRefID) { // !!!: Interpolator Copy/Get
                NSString* entityRefIdent = [[NSString alloc] initWithUTF8String:(const char*)entityRefID];
                id<NSObject> entityRef = (id<NSObject>)[[egwSIAsstMngr retrieveAsset:entityRefIdent] retain];
                EGWint16 entityIType = -1;
                
                if(entityRef && entityID) { // Copy
                    if([entityRef isKindOfClass:[egwValueInterpolator class]]) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwValueInterpolator alloc] initCopyOf:(id<egwPAsset,egwPInterpolator>)entityRef withIdentity:entityIDIdent])]) {
                            entityIType = 0;
                            ++(*loadCounter);
                        } else
                            NSLog(@"egwAssetManager: egwGAMXParseInterpolator: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating value interpolator asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    } else if([entityRef isKindOfClass:[egwOrientationInterpolator class]]) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwOrientationInterpolator alloc] initCopyOf:(id<egwPAsset,egwPInterpolator>)entityRef withIdentity:entityIDIdent])]) {
                            entityIType = 1;
                            ++(*loadCounter);
                        } else
                            NSLog(@"egwAssetManager: egwGAMXParseInterpolator: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating orientation interpolator asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    } else {
                        NSLog(@"egwAssetManager: egwGAMXParseInterpolator: Failure parsing in manifest input file '%s', for asset '%s': Copying interpolator class type '%@' not supported.", resourceFile, entityID, [entityRef class]);
                    }
                    
                    if(entity) {
                        if(!xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                            EGWint nodeType;
                            xmlChar* nodeName = NULL;
                            xmlChar* nodeValue = NULL;
                            id<egwPTimer> entityIController = nil;
                            EGWuint32 entityIPolation = (entityIType == 0 ? [(egwValueInterpolator*)entity polationMode] : 0);
                            EGWuint32 entityIPPolation = (entityIType == 1 ? [(egwOrientationInterpolator*)entity positionPolationMode] : 0);
                            EGWuint32 entityIRPolation = (entityIType == 1 ? [(egwOrientationInterpolator*)entity rotationPolationMode] : 0);
                            EGWuint32 entityISPolation = (entityIType == 1 ? [(egwOrientationInterpolator*)entity scalePolationMode] : 0);
                            
                            while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                
                                if(nodeType == 14) continue;
                                else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                                else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"controller") == 0) {
                                    if(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                        id<NSObject> entityTRef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                        if(entityTRef && [entityTRef conformsToProtocol:@protocol(egwPTimer)]) {
                                            [entityIController release]; entityIController = nil;
                                            entityIController = (id<egwPTimer>)[entityTRef retain];
                                        } else {
                                            NSLog(@"egwAssetManager: egwGAMXParseInterpolator: Failure parsing in manifest input file '%s', for asset '%s': Controller timer type '%s' not supported.", resourceFile, entityID, nodeValue);
                                            egwGAMXParseSkip(xmlReadHandle, retVal, nodeValue);
                                        }
                                        [entityTRef release]; entityTRef = nil;
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"controller");
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"polation") == 0 && entityIType == 0) {
                                    egwGAMXParseKeyFrames_Polation(resourceFile, entityID, xmlReadHandle, retVal, &entityIPolation);
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"pos_polation") == 0 && entityIType == 1) {
                                    egwGAMXParseKeyFrames_Polation(resourceFile, entityID, xmlReadHandle, retVal, &entityIPPolation);
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"rot_polation") == 0 && entityIType == 1) {
                                    egwGAMXParseKeyFrames_Polation(resourceFile, entityID, xmlReadHandle, retVal, &entityIRPolation);
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"scl_polation") == 0 && entityIType == 1) {
                                    egwGAMXParseKeyFrames_Polation(resourceFile, entityID, xmlReadHandle, retVal, &entityISPolation);
                                }
                                
                                if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            
                            if(*retVal == 1) {
                                if(entityIController) [entityIController addOwner:(id<egwPInterpolator>)entity];
                                if(entityIType == 0 && entityIPolation != [(egwValueInterpolator*)entity polationMode]) [(egwValueInterpolator*)entity setPolationMode:entityIPolation];
                                if(entityIType == 1 && entityIPPolation != [(egwOrientationInterpolator*)entity positionPolationMode]) [(egwOrientationInterpolator*)entity setPositionPolationMode:entityIPPolation];
                                if(entityIType == 1 && entityIRPolation != [(egwOrientationInterpolator*)entity rotationPolationMode]) [(egwOrientationInterpolator*)entity setRotationPolationMode:entityIRPolation];
                                if(entityIType == 1 && entityISPolation != [(egwOrientationInterpolator*)entity scalePolationMode]) [(egwOrientationInterpolator*)entity setScalePolationMode:entityISPolation];
                            }
                            
                            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                            [entityIController release]; entityIController = nil;
                        }
                    }
                } else if(entityRef && !entityID) { // Get
                    entity = [entityRef retain];
                } else {
                    NSLog(@"egwAssetManager: egwGAMXParseInterpolator: Failure parsing in manifest input file '%s', for asset '%s': Interpolator asset '%@' does not exist.", resourceFile, entityID, entityRefIdent);
                }
                
                [entityRefIdent release]; entityRefIdent = nil;
                [entityRef release]; entityRef = nil;
            } else {
                NSLog(@"egwAssetManager: egwGAMXParseInterpolator: Failure parsing in manifest input file '%s', for asset '%s': Interpolator node must contain an ID and/or reference an ID.", resourceFile, entityID);
            }
            
            if(entityID) { xmlFree(entityID); entityID = NULL; }
            if(entityRefID) { xmlFree(entityRefID); entityRefID = NULL; }
        } else {
            NSLog(@"egwAssetManager: egwGAMXParseInterpolator: Failure parsing in manifest input file '%s', for asset '%s': Interpolator node type '%s' not supported.", resourceFile, entityID, entityNodeName);
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, entityNodeName);
    }
    
    return entity;
}

// TODO: Switch egwGAMXParseLight to egwGAMXLightParams structure usage. -jw

id<NSObject> egwGAMXParseLight(const EGWchar* resourceFile, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* loadCounter, const xmlChar* entityNodeName) {
    id<NSObject> entity = nil;
    xmlChar* entityID = NULL;
    xmlChar* entityRefID = NULL;
    
    if(entityNodeName) {
        if(strcasecmp((const char*)entityNodeName, (const char*)"light") == 0) {
            entityID = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"id");
            entityRefID = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"ref");
            
            if(entityID && !entityRefID) { // New
                xmlChar* entityNodeType = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"type");
                
                if((!entityNodeType || strcasecmp((const char*)entityNodeType, (const char*)"point") == 0) && !xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                    EGWint nodeType;
                    xmlChar* nodeName = NULL;
                    xmlChar* nodeValue = NULL;
                    EGWsingle entityRadius = EGW_SFLT_MAX;
                    egwMaterial4f entityMaterial; memcpy((void*)&entityMaterial, (const void*)&egwSIMtrlDefault4f, sizeof(egwMaterial4f));
                    egwAttenuation3f entityAttenuation; memcpy((void*)&entityAttenuation, (const void*)&egwSIAttnDefault3f, sizeof(egwAttenuation3f));
                    egwMatrix44f entityBaseOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityBaseOffset);
                    egwMatrix44f entityOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityOffset);
                    egwMatrix44f entityOrient; egwMatCopy44f(&egwSIMatIdentity44f, &entityOrient);
                    egwSinglyLinkedList entityPerforms; egwSLListInit(&entityPerforms, NULL, sizeof(egwGAMPostPerforms), EGW_LIST_FLG_DFLT);
                    
                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                        
                        if(nodeType == 14) continue;
                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"radius") == 0) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                xmlChar* entityRad = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                                if(entityRad && strcasecmp((const char*)entityRad, (const char*)"infinite") == 0)
                                    entityRadius = EGW_SFLT_MAX;
                                else {
                                    egwParseStringfcv((EGWchar*)entityRad, (EGWsingle*)&entityRadius, 0, 1);
                                    entityRadius = egwClampPosf(entityRadius);
                                }
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"radius");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"illumination") == 0) {
                            EGWint runup, readup = 0;
                            while((runup = egwGAMXParseRunup(xmlReadHandle, retVal)) != 15 && *retVal == 1 && ((runup == 1 ? (nodeValue = xmlTextReaderName(xmlReadHandle)) : (nodeValue = xmlTextReaderValue(xmlReadHandle))))) {
                                if(runup == 3 && readup < 17) {
                                    readup += egwParseStringfcv((EGWchar*)nodeValue, &((EGWsingle*)&entityMaterial)[readup], 0, egwClampPosi(17 - readup));
                                    egwMtrlClamp4f(&entityMaterial, &entityMaterial);
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"illumination");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"attenuation") == 0) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && (nodeValue = xmlTextReaderValue(xmlReadHandle)))
                                egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&entityAttenuation, 0, 3);
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"attenuation");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"base_offset") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityBaseOffset);
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"base_offset");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"offset") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityOffset);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetOffsetDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"offset");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"orient") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityOrient);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetOrientateDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"orient");
                        }
                        
                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                        if(*retVal != 1) break;
                    }
                    
                    if(*retVal == 1) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwPointLight alloc] initWithIdentity:entityIDIdent lightRadius:entityRadius lightMaterial:&entityMaterial lightAttenuation:&entityAttenuation])]) {
                            BOOL entityBaseWasAligned = NO;
                            if(!egwMatIsEqual44f(&entityBaseOffset, &egwSIMatIdentity44f)) { [(egwLightBase*)[(id<egwPLight>)entity lightBase] baseOffsetByTransform:&entityBaseOffset]; entityBaseWasAligned = YES; }
                            if(!egwMatIsEqual44f(&entityOffset, &egwSIMatIdentity44f)) [(id<egwPLight>)entity offsetByTransform:&entityOffset];
                            if(!egwMatIsEqual44f(&entityOrient, &egwSIMatIdentity44f) || entityBaseWasAligned) [(id<egwPLight>)entity orientateByTransform:&entityOrient];
                            if(entityPerforms.eCount) {
                                egwSinglyLinkedListIter iter;
                                
                                if(egwSLListEnumerateStart(&entityPerforms, EGW_ITERATE_MODE_DFLT, &iter)) {
                                    egwGAMPostPerforms* action;
                                    
                                    while((action = (egwGAMPostPerforms*)egwSLListEnumerateNextPtr(&iter))) {
                                        if(action->object1 && action->object2)
                                            [entity performSelector:action->method withObject:action->object1 withObject:action->object2];
                                        else if(action->object1)
                                            [entity performSelector:action->method withObject:action->object1];
                                        else
                                            [entity performSelector:action->method];
                                    }
                                }
                            }
                            ++(*loadCounter);
                        } else
                            NSLog(@"egwAssetManager: egwGAMXParseLight: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating point light asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    }
                    
                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                    egwSLListFree(&entityPerforms);
                } else if(entityNodeType && strcasecmp((const char*)entityNodeType, (const char*)"directional") == 0 && !xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                    EGWint nodeType;
                    xmlChar* nodeName = NULL;
                    xmlChar* nodeValue = NULL;
                    egwVector3f entityDirection; egwVecCopy3f(&egwSIVecNegUnitZ3f, &entityDirection);
                    egwMaterial4f entityMaterial; memcpy((void*)&entityMaterial, (const void*)&egwSIMtrlDefault4f, sizeof(egwMaterial4f));
                    egwAttenuation3f entityAttenuation; memcpy((void*)&entityAttenuation, (const void*)&egwSIAttnDefault3f, sizeof(egwAttenuation3f));
                    egwMatrix44f entityBaseOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityBaseOffset);
                    egwMatrix44f entityOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityOffset);
                    egwMatrix44f entityOrient; egwMatCopy44f(&egwSIMatIdentity44f, &entityOrient);
                    egwSinglyLinkedList entityPerforms; egwSLListInit(&entityPerforms, NULL, sizeof(egwGAMPostPerforms), EGW_LIST_FLG_DFLT);
                    
                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                        
                        if(nodeType == 14) continue;
                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"direction") == 0) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&entityDirection, 0, 3);
                                egwVecNormalize3f(&entityDirection, &entityDirection);
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"direction");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"illumination") == 0) {
                            EGWint runup, readup = 0;
                            while((runup = egwGAMXParseRunup(xmlReadHandle, retVal)) != 15 && *retVal == 1 && ((runup == 1 ? (nodeValue = xmlTextReaderName(xmlReadHandle)) : (nodeValue = xmlTextReaderValue(xmlReadHandle))))) {
                                if(runup == 3 && readup < 17) {
                                    readup += egwParseStringfcv((EGWchar*)nodeValue, &((EGWsingle*)&entityMaterial)[readup], 0, egwClampPosi(17 - readup));
                                    egwMtrlClamp4f(&entityMaterial, &entityMaterial);
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"illumination");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"attenuation") == 0) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && (nodeValue = xmlTextReaderValue(xmlReadHandle)))
                                egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&entityAttenuation, 0, 3);
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"attenuation");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"base_offset") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityBaseOffset);
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"base_offset");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"offset") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityOffset);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetOffsetDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"offset");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"orient") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityOrient);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetOrientateDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"orient");
                        }
                        
                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                        if(*retVal != 1) break;
                    }
                    
                    if(*retVal == 1) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwDirectionalLight alloc] initWithIdentity:entityIDIdent lightDirection:&entityDirection lightMaterial:&entityMaterial lightAttenuation:&entityAttenuation])]) {
                            BOOL entityBaseWasAligned = NO;
                            if(!egwMatIsEqual44f(&entityBaseOffset, &egwSIMatIdentity44f)) { [(egwLightBase*)[(id<egwPLight>)entity lightBase] baseOffsetByTransform:&entityBaseOffset]; entityBaseWasAligned = YES; }
                            if(!egwMatIsEqual44f(&entityOffset, &egwSIMatIdentity44f)) [(id<egwPLight>)entity offsetByTransform:&entityOffset];
                            if(!egwMatIsEqual44f(&entityOrient, &egwSIMatIdentity44f) || entityBaseWasAligned) [(id<egwPLight>)entity orientateByTransform:&entityOrient];
                            if(entityPerforms.eCount) {
                                egwSinglyLinkedListIter iter;
                                
                                if(egwSLListEnumerateStart(&entityPerforms, EGW_ITERATE_MODE_DFLT, &iter)) {
                                    egwGAMPostPerforms* action;
                                    
                                    while((action = (egwGAMPostPerforms*)egwSLListEnumerateNextPtr(&iter))) {
                                        if(action->object1 && action->object2)
                                            [entity performSelector:action->method withObject:action->object1 withObject:action->object2];
                                        else if(action->object1)
                                            [entity performSelector:action->method withObject:action->object1];
                                        else
                                            [entity performSelector:action->method];
                                    }
                                }
                            }
                            ++(*loadCounter);
                        } else
                            NSLog(@"egwAssetManager: egwGAMXParseLight: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating directional light asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    }
                    
                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                    egwSLListFree(&entityPerforms);
                } else if(entityNodeType && strcasecmp((const char*)entityNodeType, (const char*)"spot") == 0 && !xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                    EGWint nodeType;
                    xmlChar* nodeName = NULL;
                    xmlChar* nodeValue = NULL;
                    EGWsingle entityAngle = 90.0f;
                    EGWsingle entityExponent = 0.0f;
                    egwVector3f entityDirection; egwVecCopy3f(&egwSIVecNegUnitZ3f, &entityDirection);
                    egwMaterial4f entityMaterial; memcpy((void*)&entityMaterial, (const void*)&egwSIMtrlDefault4f, sizeof(egwMaterial4f));
                    egwAttenuation3f entityAttenuation; memcpy((void*)&entityAttenuation, (const void*)&egwSIAttnDefault3f, sizeof(egwAttenuation3f));
                    egwMatrix44f entityBaseOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityBaseOffset);
                    egwMatrix44f entityOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityOffset);
                    egwMatrix44f entityOrient; egwMatCopy44f(&egwSIMatIdentity44f, &entityOrient);
                    egwSinglyLinkedList entityPerforms; egwSLListInit(&entityPerforms, NULL, sizeof(egwGAMPostPerforms), EGW_LIST_FLG_DFLT);
                    
                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                        
                        if(nodeType == 14) continue;
                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"angle") == 0) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&entityAngle, 0, 1);
                                entityAngle = egwClampf(entityAngle, 0.0f, 90.0f);
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"angle");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"exponent") == 0) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&entityExponent, 0, 1);
                                entityExponent = egwClamp01f(entityExponent);
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"exponent");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"direction") == 0) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&entityDirection, 0, 3);
                                egwVecNormalize3f(&entityDirection, &entityDirection);
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"direction");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"illumination") == 0) {
                            EGWint runup, readup = 0;
                            while((runup = egwGAMXParseRunup(xmlReadHandle, retVal)) != 15 && *retVal == 1 && ((runup == 1 ? (nodeValue = xmlTextReaderName(xmlReadHandle)) : (nodeValue = xmlTextReaderValue(xmlReadHandle))))) {
                                if(runup == 3 && readup < 17) {
                                    readup += egwParseStringfcv((EGWchar*)nodeValue, &((EGWsingle*)&entityMaterial)[readup], 0, egwClampPosi(17 - readup));
                                    egwMtrlClamp4f(&entityMaterial, &entityMaterial);
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"illumination");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"attenuation") == 0) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && (nodeValue = xmlTextReaderValue(xmlReadHandle)))
                                egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&entityAttenuation, 0, 3);
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"attenuation");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"base_offset") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityBaseOffset);
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"base_offset");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"offset") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityOffset);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetOffsetDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"offset");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"orient") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityOrient);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetOrientateDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"orient");
                        }
                        
                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                        if(*retVal != 1) break;
                    }
                    
                    if(*retVal == 1) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwSpotLight alloc] initWithIdentity:entityIDIdent lightDirection:&entityDirection lightAngle:entityAngle lightExponent:entityExponent lightMaterial:&entityMaterial lightAttenuation:&entityAttenuation])]) {
                            BOOL entityBaseWasAligned = NO;
                            if(!egwMatIsEqual44f(&entityBaseOffset, &egwSIMatIdentity44f)) { [(egwLightBase*)[(id<egwPLight>)entity lightBase] baseOffsetByTransform:&entityBaseOffset]; entityBaseWasAligned = YES; }
                            if(!egwMatIsEqual44f(&entityOffset, &egwSIMatIdentity44f)) [(id<egwPLight>)entity offsetByTransform:&entityOffset];
                            if(!egwMatIsEqual44f(&entityOrient, &egwSIMatIdentity44f) || entityBaseWasAligned) [(id<egwPLight>)entity orientateByTransform:&entityOrient];
                            if(entityPerforms.eCount) {
                                egwSinglyLinkedListIter iter;
                                
                                if(egwSLListEnumerateStart(&entityPerforms, EGW_ITERATE_MODE_DFLT, &iter)) {
                                    egwGAMPostPerforms* action;
                                    
                                    while((action = (egwGAMPostPerforms*)egwSLListEnumerateNextPtr(&iter))) {
                                        if(action->object1 && action->object2)
                                            [entity performSelector:action->method withObject:action->object1 withObject:action->object2];
                                        else if(action->object1)
                                            [entity performSelector:action->method withObject:action->object1];
                                        else
                                            [entity performSelector:action->method];
                                    }
                                }
                            }
                            ++(*loadCounter);
                        } else
                            NSLog(@"egwAssetManager: egwGAMXParseLight: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating spot light asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    }
                    
                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                    egwSLListFree(&entityPerforms);
                } else {
                    NSLog(@"egwAssetManager: egwGAMXParseLight: Failure parsing in manifest input file '%s', for asset '%s': Light node malformed or type attribute '%s' not supported.", resourceFile, entityID, (entityNodeType ? (const char*)entityNodeType : (const char*)"<NULL>"));
                }
                
                if(entityNodeType) { xmlFree(entityNodeType); entityNodeType = NULL; }
            } else if (entityRefID) { // Copy/Get
                NSString* entityRefIdent = [[NSString alloc] initWithUTF8String:(const char*)entityRefID];
                id<NSObject> entityRef = (id<NSObject>)[[egwSIAsstMngr retrieveAsset:entityRefIdent] retain];
                
                if(entityRef && entityID) { // Copy
                    if([entityRef isKindOfClass:[egwPointLight class]]) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwPointLight alloc] initCopyOf:(id<egwPAsset>)entityRef withIdentity:entityIDIdent])])
                            ++(*loadCounter);
                        else
                            NSLog(@"egwAssetManager: egwGAMXParseLight: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating point light asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    } else if([entityRef isKindOfClass:[egwDirectionalLight class]]) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwDirectionalLight alloc] initCopyOf:(id<egwPAsset>)entityRef withIdentity:entityIDIdent])])
                            ++(*loadCounter);
                        else
                            NSLog(@"egwAssetManager: egwGAMXParseLight: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating directional light asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    } else if([entityRef isKindOfClass:[egwSpotLight class]]) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwSpotLight alloc] initCopyOf:(id<egwPAsset>)entityRef withIdentity:entityIDIdent])])
                            ++(*loadCounter);
                        else
                            NSLog(@"egwAssetManager: egwGAMXParseLight: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating spot light asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    } else {
                        NSLog(@"egwAssetManager: egwGAMXParseLight: Failure parsing in manifest input file '%s', for asset '%s': Copying light class type '%@' not supported.", resourceFile, entityID, [entityRef class]);
                    }
                    
                    if(entity) { // Shared unique properties (offset/orient)
                        if(!xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                            EGWint nodeType;
                            xmlChar* nodeName = NULL;
                            xmlChar* nodeValue = NULL;
                            egwMatrix44f entityOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityOffset);
                            egwMatrix44f entityOrient; egwMatCopy44f(&egwSIMatIdentity44f, &entityOrient);
                            
                            while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                
                                if(nodeType == 14) continue;
                                else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                                else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"offset") == 0) {
                                    while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                        if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                            egwGAMXParseTransform(xmlReadHandle, retVal, &entityOffset);
                                        else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                            id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                            if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                                [(id<egwPOrientated>)entity trySetOffsetDriver:(id<egwPInterpolator>)entityIPORef];
                                            }
                                            [entityIPORef release]; entityIPORef = nil;
                                        }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"offset");
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"orient") == 0) {
                                    while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                        if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                            egwGAMXParseTransform(xmlReadHandle, retVal, &entityOrient);
                                        else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                            id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                            if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                                [(id<egwPOrientated>)entity trySetOrientateDriver:(id<egwPInterpolator>)entityIPORef];
                                            }
                                            [entityIPORef release]; entityIPORef = nil;
                                        }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"orient");
                                }
                                
                                if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            
                            if(*retVal == 1) {
                                if(!egwMatIsEqual44f(&entityOffset, &egwSIMatIdentity44f)) [(id<egwPOrientated>)entity offsetByTransform:&entityOffset];
                                if(!egwMatIsEqual44f(&entityOrient, &egwSIMatIdentity44f)) [(id<egwPOrientated>)entity orientateByTransform:&entityOrient];
                            }
                            
                            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                        }
                    }
                } else if(entityRef && !entityID) { // Get
                    entity = [entityRef retain];
                } else {
                    NSLog(@"egwAssetManager: egwGAMXParseLight: Failure parsing in manifest input file '%s', for asset '%s': Light asset '%@' does not exist.", resourceFile, entityID, entityRefIdent);
                }
                
                [entityRefIdent release]; entityRefIdent = nil;
                [entityRef release]; entityRef = nil;
            } else {
                NSLog(@"egwAssetManager: egwGAMXParseLight: Failure parsing in manifest input file '%s', for asset '%s': Light node must contain an ID and/or reference an ID.", resourceFile, entityID);
            }
            
            if(entityID) { xmlFree(entityID); entityID = NULL; }
            if(entityRefID) { xmlFree(entityRefID); entityRefID = NULL; }
        } else {
            NSLog(@"egwAssetManager: egwGAMXParseLight: Failure parsing in manifest input file '%s', for asset '%s': Light node type '%s' not supported.", resourceFile, entityID, entityNodeName);
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, entityNodeName);
    }
    
    return entity;
}

// TODO: Switch egwGAMXParseMaterial to egwGAMXMaterialParams structure usage. -jw

id<NSObject> egwGAMXParseMaterial(const EGWchar* resourceFile, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* loadCounter, const xmlChar* entityNodeName) {
    id<NSObject> entity = nil;
    xmlChar* entityID = NULL;
    xmlChar* entityRefID = NULL;
    
    if(entityNodeName) {
        if(strcasecmp((const char*)entityNodeName, (const char*)"material") == 0) {
            entityID = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"id");
            entityRefID = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"ref");
            
            if(entityID && !entityRefID) { // New
                xmlChar* entityNodeType = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"type");
                
                if((!entityNodeType || strcasecmp((const char*)entityNodeType, (const char*)"material") == 0) && !xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                    EGWint nodeType;
                    xmlChar* nodeName = NULL;
                    xmlChar* nodeValue = NULL;
                    egwMaterial4f entityMaterial; memcpy((void*)&entityMaterial, (const void*)&egwSIMtrlDefault4f, sizeof(egwMaterial4f));
                    egwSinglyLinkedList entityPerforms; egwSLListInit(&entityPerforms, NULL, sizeof(egwGAMPostPerforms), EGW_LIST_FLG_DFLT);
                    
                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                        
                        if(nodeType == 14) continue;
                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"material") == 0) {
                            EGWint runup, readup = 0;
                            while((runup = egwGAMXParseRunup(xmlReadHandle, retVal)) != 15 && *retVal == 1 && ((runup == 1 ? (nodeValue = xmlTextReaderName(xmlReadHandle)) : (nodeValue = xmlTextReaderValue(xmlReadHandle))))) {
                                if(runup == 1 && strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetMaterialDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                } else if(runup == 3 && readup < 17) {
                                    readup += egwParseStringfcv((EGWchar*)nodeValue, &((EGWsingle*)&entityMaterial)[readup], 0, egwClampPosi(17 - readup));
                                    egwMtrlClamp4f(&entityMaterial, &entityMaterial);
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"material");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"ambient") == 0) {
                            EGWint runup, readup = 0;
                            while((runup = egwGAMXParseRunup(xmlReadHandle, retVal)) != 15 && *retVal == 1 && ((runup == 1 ? (nodeValue = xmlTextReaderName(xmlReadHandle)) : (nodeValue = xmlTextReaderValue(xmlReadHandle))))) {
                                if(runup == 3 && readup < 4) {
                                    readup += egwParseStringfcv((EGWchar*)nodeValue, &((EGWsingle*)&entityMaterial.ambient)[readup], 0, egwClampPosi(4 - readup));
                                    egwClrClamp4f(&entityMaterial.ambient, &entityMaterial.ambient);
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"ambient");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"diffuse") == 0) {
                            EGWint runup, readup = 0;
                            while((runup = egwGAMXParseRunup(xmlReadHandle, retVal)) != 15 && *retVal == 1 && ((runup == 1 ? (nodeValue = xmlTextReaderName(xmlReadHandle)) : (nodeValue = xmlTextReaderValue(xmlReadHandle))))) {
                                if(runup == 3 && readup < 4) {
                                    readup += egwParseStringfcv((EGWchar*)nodeValue, &((EGWsingle*)&entityMaterial.diffuse)[readup], 0, egwClampPosi(4 - readup));
                                    egwClrClamp4f(&entityMaterial.diffuse, &entityMaterial.diffuse);
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"diffuse");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"specular") == 0) {
                            EGWint runup, readup = 0;
                            while((runup = egwGAMXParseRunup(xmlReadHandle, retVal)) != 15 && *retVal == 1 && ((runup == 1 ? (nodeValue = xmlTextReaderName(xmlReadHandle)) : (nodeValue = xmlTextReaderValue(xmlReadHandle))))) {
                                if(runup == 3 && readup < 4) {
                                    readup += egwParseStringfcv((EGWchar*)nodeValue, &((EGWsingle*)&entityMaterial.specular)[readup], 0, egwClampPosi(4 - readup));
                                    egwClrClamp4f(&entityMaterial.specular, &entityMaterial.specular);
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"specular");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"emmisive") == 0) {
                            EGWint runup, readup = 0;
                            while((runup = egwGAMXParseRunup(xmlReadHandle, retVal)) != 15 && *retVal == 1 && ((runup == 1 ? (nodeValue = xmlTextReaderName(xmlReadHandle)) : (nodeValue = xmlTextReaderValue(xmlReadHandle))))) {
                                if(runup == 3 && readup < 4) {
                                    readup += egwParseStringfcv((EGWchar*)nodeValue, &((EGWsingle*)&entityMaterial.emmisive)[readup], 0, egwClampPosi(4 - readup));
                                    egwClrClamp4f(&entityMaterial.emmisive, &entityMaterial.emmisive);
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"emmisive");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"shininess") == 0) {
                            EGWint runup, readup = 0;
                            while((runup = egwGAMXParseRunup(xmlReadHandle, retVal)) != 15 && *retVal == 1 && ((runup == 1 ? (nodeValue = xmlTextReaderName(xmlReadHandle)) : (nodeValue = xmlTextReaderValue(xmlReadHandle))))) {
                                if(runup == 3 && readup < 1) {
                                    readup += egwParseStringfcv((EGWchar*)nodeValue, &((EGWsingle*)&entityMaterial.shininess)[readup], 0, egwClampPosi(1 - readup));
                                    entityMaterial.shininess = egwClamp01f(entityMaterial.shininess);
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"shininess");
                        }
                        
                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                        if(*retVal != 1) break;
                    }
                    
                    if(*retVal == 1) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwMaterial alloc] initWithIdentity:entityIDIdent surfacingMaterial:&entityMaterial])]) {
                            if(entityPerforms.eCount) {
                                egwSinglyLinkedListIter iter;
                                
                                if(egwSLListEnumerateStart(&entityPerforms, EGW_ITERATE_MODE_DFLT, &iter)) {
                                    egwGAMPostPerforms* action;
                                    
                                    while((action = (egwGAMPostPerforms*)egwSLListEnumerateNextPtr(&iter))) {
                                        if(action->object1 && action->object2)
                                            [entity performSelector:action->method withObject:action->object1 withObject:action->object2];
                                        else if(action->object1)
                                            [entity performSelector:action->method withObject:action->object1];
                                        else
                                            [entity performSelector:action->method];
                                    }
                                }
                            }
                            ++(*loadCounter);
                        } else
                            NSLog(@"egwAssetManager: egwGAMXParseMaterial: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating material asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    }
                    
                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                } else if(entityNodeType && strcasecmp((const char*)entityNodeType, (const char*)"color") == 0 && !xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                    EGWint nodeType;
                    xmlChar* nodeName = NULL;
                    xmlChar* nodeValue = NULL;
                    egwColor4f entityColor; memcpy((void*)&entityColor, (const void*)&egwSIMtrlDefault4f.diffuse, sizeof(egwColor4f));
                    egwSinglyLinkedList entityPerforms; egwSLListInit(&entityPerforms, NULL, sizeof(egwGAMPostPerforms), EGW_LIST_FLG_DFLT);
                    
                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                        
                        if(nodeType == 14) continue;
                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"color") == 0) {
                            EGWint runup, readup = 0;
                            while((runup = egwGAMXParseRunup(xmlReadHandle, retVal)) != 15 && *retVal == 1 && ((runup == 1 ? (nodeValue = xmlTextReaderName(xmlReadHandle)) : (nodeValue = xmlTextReaderValue(xmlReadHandle))))) {
                                if(runup == 1 && strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetColoringDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                } else if(runup == 3 && readup < 4) {
                                    readup += egwParseStringfcv((EGWchar*)nodeValue, &((EGWsingle*)&entityColor)[readup], 0, egwClampPosi(4 - readup));
                                    egwClrClamp4f(&entityColor, &entityColor);
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"color");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"rgb") == 0) {
                            EGWint runup, readup = 0;
                            while((runup = egwGAMXParseRunup(xmlReadHandle, retVal)) != 15 && *retVal == 1 && ((runup == 1 ? (nodeValue = xmlTextReaderName(xmlReadHandle)) : (nodeValue = xmlTextReaderValue(xmlReadHandle))))) {
                                if(runup == 3 && readup < 3) {
                                    readup += egwParseStringfcv((EGWchar*)nodeValue, &((EGWsingle*)&entityColor)[readup], 0, egwClampPosi(3 - readup));
                                    egwClrClamp3f((egwColor3f*)&entityColor, (egwColor3f*)&entityColor);
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"rgb");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"red") == 0) {
                            EGWint runup, readup = 0;
                            while((runup = egwGAMXParseRunup(xmlReadHandle, retVal)) != 15 && *retVal == 1 && ((runup == 1 ? (nodeValue = xmlTextReaderName(xmlReadHandle)) : (nodeValue = xmlTextReaderValue(xmlReadHandle))))) {
                                if(runup == 3 && readup < 1) {
                                    readup += egwParseStringfcv((EGWchar*)nodeValue, &((EGWsingle*)&entityColor.channel.r)[readup], 0, egwClampPosi(1 - readup));
                                    egwClrClamp1f((egwColor1f*)&entityColor.channel.r, (egwColor1f*)&entityColor.channel.r);
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"red");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"green") == 0) {
                            EGWint runup, readup = 0;
                            while((runup = egwGAMXParseRunup(xmlReadHandle, retVal)) != 15 && *retVal == 1 && ((runup == 1 ? (nodeValue = xmlTextReaderName(xmlReadHandle)) : (nodeValue = xmlTextReaderValue(xmlReadHandle))))) {
                                if(runup == 3 && readup < 1) {
                                    readup += egwParseStringfcv((EGWchar*)nodeValue, &((EGWsingle*)&entityColor.channel.g)[readup], 0, egwClampPosi(1 - readup));
                                    egwClrClamp1f((egwColor1f*)&entityColor.channel.g, (egwColor1f*)&entityColor.channel.g);
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"green");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"blue") == 0) {
                            EGWint runup, readup = 0;
                            while((runup = egwGAMXParseRunup(xmlReadHandle, retVal)) != 15 && *retVal == 1 && ((runup == 1 ? (nodeValue = xmlTextReaderName(xmlReadHandle)) : (nodeValue = xmlTextReaderValue(xmlReadHandle))))) {
                                if(runup == 3 && readup < 1) {
                                    readup += egwParseStringfcv((EGWchar*)nodeValue, &((EGWsingle*)&entityColor.channel.b)[readup], 0, egwClampPosi(1 - readup));
                                    egwClrClamp1f((egwColor1f*)&entityColor.channel.b, (egwColor1f*)&entityColor.channel.b);
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"blue");
                        }
                        
                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                        if(*retVal != 1) break;
                    }
                    
                    if(*retVal == 1) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwColor alloc] initWithIdentity:entityIDIdent surfacingColor:&entityColor])]) {
                            if(entityPerforms.eCount) {
                                egwSinglyLinkedListIter iter;
                                
                                if(egwSLListEnumerateStart(&entityPerforms, EGW_ITERATE_MODE_DFLT, &iter)) {
                                    egwGAMPostPerforms* action;
                                    
                                    while((action = (egwGAMPostPerforms*)egwSLListEnumerateNextPtr(&iter))) {
                                        if(action->object1 && action->object2)
                                            [entity performSelector:action->method withObject:action->object1 withObject:action->object2];
                                        else if(action->object1)
                                            [entity performSelector:action->method withObject:action->object1];
                                        else
                                            [entity performSelector:action->method];
                                    }
                                }
                            }
                            ++(*loadCounter);
                        } else
                            NSLog(@"egwAssetManager: egwGAMXParseMaterial: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating material asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    }
                    
                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                } else if(entityNodeType && strcasecmp((const char*)entityNodeType, (const char*)"shading") == 0 && !xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                    EGWint nodeType;
                    xmlChar* nodeName = NULL;
                    xmlChar* nodeValue = NULL;
                    egwColor2f entityShade; memcpy((void*)&entityShade, (const void*)&egwSIVecOne2f, sizeof(egwColor2f));
                    egwSinglyLinkedList entityPerforms; egwSLListInit(&entityPerforms, NULL, sizeof(egwGAMPostPerforms), EGW_LIST_FLG_DFLT);
                    
                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                        
                        if(nodeType == 14) continue;
                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"shade") == 0) {
                            EGWint runup, readup = 0;
                            while((runup = egwGAMXParseRunup(xmlReadHandle, retVal)) != 15 && *retVal == 1 && ((runup == 1 ? (nodeValue = xmlTextReaderName(xmlReadHandle)) : (nodeValue = xmlTextReaderValue(xmlReadHandle))))) {
                                if(runup == 1 && strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetShadingDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                } else if(runup == 3 && readup < 2) {
                                    readup += egwParseStringfcv((EGWchar*)nodeValue, &((EGWsingle*)&entityShade)[readup], 0, egwClampPosi(2 - readup));
                                    egwClrClamp2f(&entityShade, &entityShade);
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"shade");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"luminance") == 0) {
                            EGWint runup, readup = 0;
                            while((runup = egwGAMXParseRunup(xmlReadHandle, retVal)) != 15 && *retVal == 1 && ((runup == 1 ? (nodeValue = xmlTextReaderName(xmlReadHandle)) : (nodeValue = xmlTextReaderValue(xmlReadHandle))))) {
                                if(runup == 3 && readup < 1) {
                                    readup += egwParseStringfcv((EGWchar*)nodeValue, &((EGWsingle*)&entityShade.channel.l)[readup], 0, egwClampPosi(1 - readup));
                                    egwClrClamp1f((egwColor1f*)&entityShade.channel.l, (egwColor1f*)&entityShade.channel.l);
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"luminance");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"alpha") == 0) {
                            EGWint runup, readup = 0;
                            while((runup = egwGAMXParseRunup(xmlReadHandle, retVal)) != 15 && *retVal == 1 && ((runup == 1 ? (nodeValue = xmlTextReaderName(xmlReadHandle)) : (nodeValue = xmlTextReaderValue(xmlReadHandle))))) {
                                if(runup == 3 && readup < 1) {
                                    readup += egwParseStringfcv((EGWchar*)nodeValue, &((EGWsingle*)&entityShade.channel.a)[readup], 0, egwClampPosi(1 - readup));
                                    egwClrClamp1f((egwColor1f*)&entityShade.channel.a, (egwColor1f*)&entityShade.channel.a);
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"alpha");
                        }
                        
                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                        if(*retVal != 1) break;
                    }
                    
                    if(*retVal == 1) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwShade alloc] initWithIdentity:entityIDIdent surfacingShade:&entityShade])]) {
                            if(entityPerforms.eCount) {
                                egwSinglyLinkedListIter iter;
                                
                                if(egwSLListEnumerateStart(&entityPerforms, EGW_ITERATE_MODE_DFLT, &iter)) {
                                    egwGAMPostPerforms* action;
                                    
                                    while((action = (egwGAMPostPerforms*)egwSLListEnumerateNextPtr(&iter))) {
                                        if(action->object1 && action->object2)
                                            [entity performSelector:action->method withObject:action->object1 withObject:action->object2];
                                        else if(action->object1)
                                            [entity performSelector:action->method withObject:action->object1];
                                        else
                                            [entity performSelector:action->method];
                                    }
                                }
                            }
                            ++(*loadCounter);
                        } else
                            NSLog(@"egwAssetManager: egwGAMXParseMaterial: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating material asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    }
                    
                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                } else {
                    NSLog(@"egwAssetManager: egwGAMXParseMaterial: Failure parsing in manifest input file '%s', for asset '%s': Material node malformed or type attribute '%s' not supported.", resourceFile, entityID, (entityNodeType ? (const char*)entityNodeType : (const char*)"<NULL>"));
                }
                
                if(entityNodeType) { xmlFree(entityNodeType); entityNodeType = NULL; }
            } else if (entityRefID) { // Copy/Get
                NSString* entityRefIdent = [[NSString alloc] initWithUTF8String:(const char*)entityRefID];
                id<NSObject> entityRef = (id<NSObject>)[[egwSIAsstMngr retrieveAsset:entityRefIdent] retain];
                
                if(entityRef && entityID) { // Copy
                    if([entityRef isKindOfClass:[egwMaterial class]]) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwMaterial alloc] initCopyOf:(id<egwPAsset>)entityRef withIdentity:entityIDIdent])])
                            ++(*loadCounter);
                        else
                            NSLog(@"egwAssetManager: egwGAMXParseMaterial: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating material asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    } else if([entityRef isKindOfClass:[egwColor class]]) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwColor alloc] initCopyOf:(id<egwPAsset>)entityRef withIdentity:entityIDIdent])])
                            ++(*loadCounter);
                        else
                            NSLog(@"egwAssetManager: egwGAMXParseMaterial: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating color asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    } else if([entityRef isKindOfClass:[egwShade class]]) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwShade alloc] initCopyOf:(id<egwPAsset>)entityRef withIdentity:entityIDIdent])])
                            ++(*loadCounter);
                        else
                            NSLog(@"egwAssetManager: egwGAMXParseMaterial: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating shade asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    } else {
                        NSLog(@"egwAssetManager: egwGAMXParseMaterial: Failure parsing in manifest input file '%s', for asset '%s': Copying material class type '%@' not supported.", resourceFile, entityID, [entityRef class]);
                    }
                    
                    // FIXME: There are unique properties for material copies - this is a definate bug that needs fixed. -jw
                    
                } else if(entityRef && !entityID) { // Get
                    entity = [entityRef retain];
                } else {
                    NSLog(@"egwAssetManager: egwGAMXParseMaterial: Failure parsing in manifest input file '%s', for asset '%s': Material asset '%@' does not exist.", resourceFile, entityID, entityRefIdent);
                }
                
                [entityRefIdent release]; entityRefIdent = nil;
                [entityRef release]; entityRef = nil;
            } else {
                NSLog(@"egwAssetManager: egwGAMXParseMaterial: Failure parsing in manifest input file '%s', for asset '%s': Material node must contain an ID and/or reference an ID.", resourceFile, entityID);
            }
            
            if(entityID) { xmlFree(entityID); entityID = NULL; }
            if(entityRefID) { xmlFree(entityRefID); entityRefID = NULL; }
        } else {
            NSLog(@"egwAssetManager: egwGAMXParseMaterial: Failure parsing in manifest input file '%s', for asset '%s': Material node type '%s' not supported.", resourceFile, entityID, entityNodeName);
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, entityNodeName);
    }
    
    return entity;
}

// Instantiation type and distinct parameter values for geometry parsing
typedef struct {
    EGWint16 type; // invalid type = -1, static mesh = 0
    EGWint16 srcType; // invalid type = -1, static geometry = 0, static blank = 1, static box = 2, static cone = 3, static cylinder = 4, static pyramid = 5, static sphere = 6 
    union {
        struct { egwSJITVAMeshf geometry; } geom; // static geometry = 0
        struct { EGWuint16 vCount; EGWuint16 fCount; } vfc; // static blank = 1
        struct { EGWsingle dim[3]; } whd; // static box = 2, static pyramid = 5
        struct { EGWsingle radius; EGWsingle height; EGWuint16 longitudes; } rhl; // static cone = 3, static cylinder = 4
        struct { EGWsingle radius; EGWuint16 latitudes; EGWuint16 longitudes; } rll; // static sphere = 6
    } dist;
} egwGAMXMeshParams;

id<NSObject> egwGAMXParseMesh(const EGWchar* resourceFile, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* loadCounter, const xmlChar* entityNodeName) {
    id<NSObject> entity = nil;
    xmlChar* entityID = NULL;
    xmlChar* entityRefID = NULL;
    
    if(entityNodeName) {
        if(strcasecmp((const char*)entityNodeName, (const char*)"mesh") == 0) {
            entityID = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"id");
            entityRefID = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"ref");
            
            if(entityID && !entityRefID) { // New
                xmlChar* entityNodeType = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"type");
                
                if((!entityNodeType || strcasecmp((const char*)entityNodeType, (const char*)"static") == 0) && !xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                    EGWint nodeType;
                    xmlChar* nodeName = NULL;
                    xmlChar* nodeValue = NULL;
                    egwGAMXMeshParams entityParams; memset((void*)&entityParams, 0, sizeof(egwGAMXMeshParams)); entityParams.type = entityParams.srcType = -1;
                    EGWuint entityRFlags = 0;
                    Class entityMBounding = nil;
                    EGWuint entityGStorage = 0;
                    egwMaterialStack* entityMStack = nil;
                    egwTextureStack* entityTStack = nil;
                    egwMatrix44f entityBaseOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityBaseOffset);
                    EGWuint entityBaseZFAlign = 0;
                    egwMatrix44f entityOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityOffset);
                    egwMatrix44f entityOrient; egwMatCopy44f(&egwSIMatIdentity44f, &entityOrient);
                    egwSinglyLinkedList entityPerforms; egwSLListInit(&entityPerforms, NULL, sizeof(egwGAMPostPerforms), EGW_LIST_FLG_DFLT);
                    
                    if(!entityNodeType || strcasecmp((const char*)entityNodeType, (const char*)"static") == 0)
                        entityParams.type = 0; // static mesh
                    
                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                        
                        if(nodeType == 14) continue;
                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"geometry") == 0  && !xmlTextReaderIsEmptyElement(xmlReadHandle) && entityParams.type == 0) {
                            xmlChar* entitySourceSrc = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"source");
                            
                            if(!entitySourceSrc || strcasecmp((const char*)entitySourceSrc, (const char*)"internal") == 0) {
                                xmlChar* entitySourceType = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"type");
                                
                                if(entitySourceType && strcasecmp((const char*)entitySourceType, (const char*)"vertex_array") == 0) {
                                    egwSTVAMeshf entitySTVAMesh; memset((void*)&entitySTVAMesh, 0, sizeof(egwSTVAMeshf));
                                    
                                    egwGAMXParseGeometry_STVA(resourceFile, entityID, xmlReadHandle, retVal, &entitySTVAMesh);
                                    
                                    if(*retVal == 1) {
                                        if(entitySTVAMesh.vCount && entitySTVAMesh.vCoords &&
                                           egwMeshConvertSTVAfSJITVAf(&entitySTVAMesh, &entityParams.dist.geom.geometry) &&
                                           entityParams.dist.geom.geometry.vCount && entityParams.dist.geom.geometry.vCoords && entityParams.dist.geom.geometry.fCount && entityParams.dist.geom.geometry.fIndicies) {
                                            entityParams.srcType = 0; // static geometry
                                        }
                                    }
                                    
                                    egwMeshFreeSTVAf(&entitySTVAMesh);
                                } else if(entitySourceType && strcasecmp((const char*)entitySourceType, (const char*)"joint_indexed_vertex_array") == 0) {
                                    egwGAMXParseGeometry_SJITVA(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.geom.geometry);
                                    
                                    if(*retVal == 1) {
                                        if(entityParams.dist.geom.geometry.vCount && entityParams.dist.geom.geometry.vCoords && entityParams.dist.geom.geometry.fCount && entityParams.dist.geom.geometry.fIndicies) {
                                            entityParams.srcType = 0; // static geometry
                                        }
                                    }
                                } else if(entitySourceType && strcasecmp((const char*)entitySourceType, (const char*)"disjoint_indexed_vertex_array") == 0) {
                                    egwSDITVAMeshf entitySDITVAMesh; memset((void*)&entitySDITVAMesh, 0, sizeof(egwSDITVAMeshf));
                                    
                                    egwGAMXParseGeometry_SDITVA(resourceFile, entityID, xmlReadHandle, retVal, &entitySDITVAMesh);
                                    
                                    if(*retVal == 1) {
                                        if(entitySDITVAMesh.vCount && entitySDITVAMesh.vCoords && entitySDITVAMesh.fCount && entitySDITVAMesh.fIndicies &&
                                           egwMeshConvertSDITVAfSJITVAf(&entitySDITVAMesh, &entityParams.dist.geom.geometry) &&
                                           entityParams.dist.geom.geometry.vCount && entityParams.dist.geom.geometry.vCoords && entityParams.dist.geom.geometry.fCount && entityParams.dist.geom.geometry.fIndicies) {
                                            entityParams.srcType = 0; // static geometry
                                        }
                                    }
                                    
                                    egwMeshFreeSDITVAf(&entitySDITVAMesh);
                                } else if(entitySourceType && strcasecmp((const char*)entitySourceType, (const char*)"blank") == 0) {
                                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                    
                                    // blank primitive read
                                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                        
                                        if(nodeType == 14) continue;
                                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"geometry") == 0) break;
                                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"vertex_count") == 0) {
                                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                                egwParseStringui16cv((EGWchar*)nodeValue, (EGWuint16*)&entityParams.dist.vfc.vCount, 0, 1);
                                            }
                                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"vertex_count");
                                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"face_count") == 0) {
                                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                                egwParseStringui16cv((EGWchar*)nodeValue, (EGWuint16*)&entityParams.dist.vfc.fCount, 0, 1);
                                            }
                                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"face_count");
                                        }
                                        
                                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    
                                    if(*retVal == 1) {
                                        entityParams.srcType = 1; // static blank
                                    }
                                } else if(entitySourceType && (strcasecmp((const char*)entitySourceType, (const char*)"box_primitive") == 0 || strcasecmp((const char*)entitySourceType, (const char*)"pyramid_primitive") == 0)) {
                                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                    
                                    // box/pyramid primitives read
                                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                        
                                        if(nodeType == 14) continue;
                                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"geometry") == 0) break;
                                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"dimensions") == 0) {
                                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                                egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&(entityParams.dist.whd.dim[0]), 0, 3);
                                                entityParams.dist.whd.dim[0] = egwClampPosf(entityParams.dist.whd.dim[0]);
                                                entityParams.dist.whd.dim[1] = egwClampPosf(entityParams.dist.whd.dim[1]);
                                                entityParams.dist.whd.dim[2] = egwClampPosf(entityParams.dist.whd.dim[2]);
                                            }
                                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"dimensions");
                                        }
                                        
                                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    
                                    if(*retVal == 1) {
                                        if(strncasecmp((const char*)entitySourceType, (const char*)"box", 3) == 0) entityParams.srcType = 2; // static box
                                        else if(strncasecmp((const char*)entitySourceType, (const char*)"pyramid", 7) == 0) entityParams.srcType = 5; // static pyramid
                                    }
                                } else if(entitySourceType && (strcasecmp((const char*)entitySourceType, (const char*)"cone_primitive") == 0 || strcasecmp((const char*)entitySourceType, (const char*)"cylinder_primitive") == 0)) {
                                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                    
                                    // cone/clyinder primitives read
                                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                        
                                        if(nodeType == 14) continue;
                                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"geometry") == 0) break;
                                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"radius") == 0) {
                                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                                egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&(entityParams.dist.rhl.radius), 0, 1);
                                                entityParams.dist.rhl.radius = egwClampPosf(entityParams.dist.rhl.radius);
                                            }
                                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"radius");
                                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"height") == 0) {
                                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                                egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&(entityParams.dist.rhl.height), 0, 1);
                                                entityParams.dist.rhl.height = egwClampPosf(entityParams.dist.rhl.height);
                                            }
                                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"height");
                                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"longitudes") == 0) {
                                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle)))
                                                egwParseStringui16cv((EGWchar*)nodeValue, (EGWuint16*)&(entityParams.dist.rhl.longitudes), 0, 1);
                                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"longitudes");
                                        }
                                        
                                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    
                                    if(*retVal == 1) {
                                        if(strncasecmp((const char*)entitySourceType, (const char*)"cone", 4) == 0) entityParams.srcType = 3; // static cone
                                        else if(strncasecmp((const char*)entitySourceType, (const char*)"cylinder", 8) == 0) entityParams.srcType = 4; // static cylinder
                                    }
                                } else if(entitySourceType && strcasecmp((const char*)entitySourceType, (const char*)"sphere_primitive") == 0) {
                                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                    
                                    // sphere primitive read
                                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                        
                                        if(nodeType == 14) continue;
                                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"geometry") == 0) break;
                                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"radius") == 0) {
                                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                                egwParseStringfcv((EGWchar*)nodeValue, (EGWsingle*)&(entityParams.dist.rll.radius), 0, 1);
                                                entityParams.dist.rll.radius = egwClampPosf(entityParams.dist.rll.radius);
                                            }
                                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"radius");
                                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"latitudes") == 0) {
                                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle)))
                                                egwParseStringui16cv((EGWchar*)nodeValue, (EGWuint16*)&(entityParams.dist.rll.latitudes), 0, 1);
                                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"latitudes");
                                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"longitudes") == 0) {
                                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle)))
                                                egwParseStringui16cv((EGWchar*)nodeValue, (EGWuint16*)&(entityParams.dist.rll.longitudes), 0, 1);
                                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"longitudes");
                                        }
                                        
                                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    
                                    if(*retVal == 1) {
                                        entityParams.srcType = 6; // static sphere
                                    }
                                } else NSLog(@"egwAssetManager: egwGAMXParseMesh: Failure parsing in manifest input file '%s', for asset '%s': Surface internal type '%s' not supported.", resourceFile, entityID, (entitySourceType ? (const char*)entitySourceType : (const char*)"<NULL>"));
                                
                                if(entitySourceType) { xmlFree(entitySourceType); entitySourceType = NULL; }
                            //} else if(strcasecmp((const char*)entitySourceSrc, (const char*)"external") == 0) {
                                // TODO: Mesh read external geometry.
                            } else NSLog(@"egwAssetManager: egwGAMXParseBillboard: Failure parsing in manifest input file '%s', for asset '%s': Surface source '%s' not supported.", resourceFile, entityID, (entitySourceSrc ? (const char*)entitySourceSrc : (const char*)"<NULL>"));
                            
                            if(entitySourceSrc) { xmlFree(entitySourceSrc); entitySourceSrc = NULL; }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"geometry");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"bounding") == 0) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"volume") == 0)
                                    egwGAMXParseVolume(resourceFile, entityID, xmlReadHandle, retVal, &entityMBounding, NULL);
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"bounding");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"storage") == 0) {
                            egwGAMXParseGeometry_Storage(resourceFile, entityID, xmlReadHandle, retVal, &entityGStorage);
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"materials") == 0) {
                            if(!entityMStack && !(entityMStack = [[egwMaterialStack alloc] init]))
                                NSLog(@"egwAssetManager: egwGAMXParseMesh: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating a material stack.", resourceFile, entityID, nodeValue);
                            else {
                                while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                    id<NSObject> entityRef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityRef && [entityRef conformsToProtocol:@protocol(egwPMaterial)]) {
                                        [entityMStack addMaterial:(id<egwPMaterial>)entityRef];
                                    } else {
                                        NSLog(@"egwAssetManager: egwGAMXParseMesh: Failure parsing in manifest input file '%s', for asset '%s': Material stack node type '%s' not supported.", resourceFile, entityID, nodeValue);
                                        egwGAMXParseSkip(xmlReadHandle, retVal, nodeValue);
                                    }
                                    [entityRef release]; entityRef = nil;
                                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                    if(*retVal != 1) break;
                                }
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"materials");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"textures") == 0) {
                            if(!entityTStack && !(entityTStack = [[egwTextureStack alloc] init]))
                                NSLog(@"egwAssetManager: egwGAMXParseMesh: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating a texture stack.", resourceFile, entityID, nodeValue);
                            else {
                                while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                    id<NSObject> entityRef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityRef && [entityRef conformsToProtocol:@protocol(egwPTexture)]) {
                                        [entityTStack addTexture:(id<egwPTexture>)entityRef];
                                    } else {
                                        NSLog(@"egwAssetManager: egwGAMXParseMesh: Failure parsing in manifest input file '%s', for asset '%s': Texture stack node type '%s' not supported.", resourceFile, entityID, nodeValue);
                                        egwGAMXParseSkip(xmlReadHandle, retVal, nodeValue);
                                    }
                                    [entityRef release]; entityRef = nil;
                                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                    if(*retVal != 1) break;
                                }
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"textures");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"render_flags") == 0) {
                            egwGAMXParseFlags_Render(resourceFile, entityID, xmlReadHandle, retVal, &entityRFlags);
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"base_offset") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityBaseOffset);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"zfalign") == 0)
                                    egwGAMXParseZFAlign(resourceFile, entityID, xmlReadHandle, retVal, &entityBaseZFAlign);
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"base_offset");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"offset") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityOffset);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetOffsetDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"offset");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"orient") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityOrient);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetOrientateDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"orient");
                        }
                        
                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                        if(*retVal != 1) break;
                    }
                    
                    if(*retVal == 1) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        
                        if(entityTStack && [entityTStack textureCount] == 0) { [entityTStack release]; entityTStack = nil; }
                        
                        if((entityParams.srcType == 0 && // static geometry
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwMesh alloc] initWithIdentity:entityIDIdent staticMesh:&entityParams.dist.geom.geometry meshBounding:entityMBounding geometryStorage:entityGStorage lightStack:nil materialStack:entityMStack textureStack:entityTStack])]) ||
                           (entityParams.srcType == 1 && // static blank
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwMesh alloc] initBlankWithIdentity:entityIDIdent vertexCount:entityParams.dist.vfc.vCount faceCount:entityParams.dist.vfc.fCount geometryStorage:entityGStorage lightStack:nil materialStack:entityMStack textureStack:entityTStack])]) ||
                           (entityParams.srcType == 2 && // static box
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwMesh alloc] initBoxWithIdentity:entityIDIdent boxWidth:entityParams.dist.whd.dim[0] boxHeight:entityParams.dist.whd.dim[1] boxDepth:entityParams.dist.whd.dim[2] geometryStorage:entityGStorage lightStack:nil materialStack:entityMStack textureStack:entityTStack])]) ||
                           (entityParams.srcType == 3 && // static cone
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwMesh alloc] initConeWithIdentity:entityIDIdent coneRadius:entityParams.dist.rhl.radius coneHeight:entityParams.dist.rhl.height coneLongitudes:entityParams.dist.rhl.longitudes geometryStorage:entityGStorage lightStack:nil materialStack:entityMStack textureStack:entityTStack])]) ||
                           (entityParams.srcType == 4 && // static cylinder
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwMesh alloc] initCylinderWithIdentity:entityIDIdent cylinderRadius:entityParams.dist.rhl.radius cylinderHeight:entityParams.dist.rhl.height cylinderLongitudes:entityParams.dist.rhl.longitudes geometryStorage:entityGStorage lightStack:nil materialStack:entityMStack textureStack:entityTStack])]) ||
                           (entityParams.srcType == 5 && // static pyramid
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwMesh alloc] initPyramidWithIdentity:entityIDIdent pyramidWidth:entityParams.dist.whd.dim[0] pyramidHeight:entityParams.dist.whd.dim[1] pyramidDepth:entityParams.dist.whd.dim[2] geometryStorage:entityGStorage lightStack:nil materialStack:entityMStack textureStack:entityTStack])]) ||
                           (entityParams.srcType == 6 && // static sphere
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwMesh alloc] initSphereWithIdentity:entityIDIdent sphereRadius:entityParams.dist.rll.radius sphereLongitudes:entityParams.dist.rll.longitudes sphereLatitudes:entityParams.dist.rll.latitudes geometryStorage:entityGStorage lightStack:nil materialStack:entityMStack textureStack:entityTStack])])) {
                            BOOL entityBaseWasAligned = NO;
                            if(entityBaseZFAlign != 0) { [(egwMeshBase*)[(id<egwPGeometry>)entity renderingBase] baseOffsetByZeroAlign:entityBaseZFAlign]; entityBaseWasAligned = YES; }
                            if(!egwMatIsEqual44f(&entityBaseOffset, &egwSIMatIdentity44f)) { [(egwMeshBase*)[(id<egwPGeometry>)entity renderingBase] baseOffsetByTransform:&entityBaseOffset]; entityBaseWasAligned = YES; }
                            if(!egwMatIsEqual44f(&entityOffset, &egwSIMatIdentity44f)) [(id<egwPGeometry>)entity offsetByTransform:&entityOffset];
                            if(!egwMatIsEqual44f(&entityOrient, &egwSIMatIdentity44f) || entityBaseWasAligned) [(id<egwPGeometry>)entity orientateByTransform:&entityOrient];
                            if(entityRFlags) [(id<egwPGeometry>)entity setRenderingFlags:entityRFlags];
                            if(entityPerforms.eCount) {
                                egwSinglyLinkedListIter iter;
                                
                                if(egwSLListEnumerateStart(&entityPerforms, EGW_ITERATE_MODE_DFLT, &iter)) {
                                    egwGAMPostPerforms* action;
                                    
                                    while((action = (egwGAMPostPerforms*)egwSLListEnumerateNextPtr(&iter))) {
                                        if(action->object1 && action->object2)
                                            [entity performSelector:action->method withObject:action->object1 withObject:action->object2];
                                        else if(action->object1)
                                            [entity performSelector:action->method withObject:action->object1];
                                        else
                                            [entity performSelector:action->method];
                                    }
                                }
                            }
                            ++(*loadCounter);
                        } else
                            NSLog(@"egwAssetManager: egwGAMXParseMesh: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating static geometry asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    }
                    
                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                    if(entityParams.srcType == 0) egwMeshFreeSJITVAf(&entityParams.dist.geom.geometry);
                    [entityMStack release]; entityMStack = nil;
                    [entityTStack release]; entityTStack = nil;
                    egwSLListFree(&entityPerforms);
                } else {
                    NSLog(@"egwAssetManager: egwGAMXParseMesh: Failure parsing in manifest input file '%s', for asset '%s': Mesh node malformed or type attribute '%s' not supported.", resourceFile, entityID, (entityNodeType ? (const char*)entityNodeType : (const char*)"<NULL>"));
                }
                
                if(entityNodeType) { xmlFree(entityNodeType); entityNodeType = NULL; }
            } else if (entityRefID) { // !!!: Mesh Copy/Get
                NSString* entityRefIdent = [[NSString alloc] initWithUTF8String:(const char*)entityRefID];
                id<NSObject> entityRef = (id<NSObject>)[[egwSIAsstMngr retrieveAsset:entityRefIdent] retain];
                
                if(entityRef && entityID) { // Copy
                    if([entityRef isKindOfClass:[egwMesh class]]) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwMesh alloc] initCopyOf:(id<egwPAsset,egwPGeometry>)entityRef withIdentity:entityIDIdent])])
                            ++(*loadCounter);
                        else
                            NSLog(@"egwAssetManager: egwGAMXParseMesh: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating static geometry asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    } else {
                        NSLog(@"egwAssetManager: egwGAMXParseMesh: Failure parsing in manifest input file '%s', for asset '%s': Copying geometry class type '%@' not supported.", resourceFile, entityID, [entityRef class]);
                    }
                    
                    if(entity) { // Shared unique properties (offset/orient)
                        if(!xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                            EGWint nodeType;
                            xmlChar* nodeName = NULL;
                            xmlChar* nodeValue = NULL;
                            EGWuint entityRFlags = [(id<egwPGeometry>)entityRef renderingFlags];
                            egwMaterialStack* entityMStack = nil;
                            egwTextureStack* entityTStack = nil;
                            egwMatrix44f entityOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityOffset);
                            egwMatrix44f entityOrient; egwMatCopy44f(&egwSIMatIdentity44f, &entityOrient);
                            
                            while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                
                                if(nodeType == 14) continue;
                                else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                                else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"materials") == 0) {
                                    if(!entityMStack && !(entityMStack = [[egwMaterialStack alloc] init]))
                                        NSLog(@"egwAssetManager: egwGAMXParseMesh: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating a material stack.", resourceFile, entityID, nodeValue);
                                    else {
                                        while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                            id<NSObject> entityRef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                            if(entityRef && [entityRef conformsToProtocol:@protocol(egwPMaterial)]) {
                                                [entityMStack addMaterial:(id<egwPMaterial>)entityRef];
                                            } else {
                                                NSLog(@"egwAssetManager: egwGAMXParseMesh: Failure parsing in manifest input file '%s', for asset '%s': Material stack node type '%s' not supported.", resourceFile, entityID, nodeValue);
                                                egwGAMXParseSkip(xmlReadHandle, retVal, nodeValue);
                                            }
                                            [entityRef release]; entityRef = nil;
                                            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                            if(*retVal != 1) break;
                                        }
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"materials");
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"textures") == 0) {
                                    if(!entityTStack && !(entityTStack = [[egwTextureStack alloc] init]))
                                        NSLog(@"egwAssetManager: egwGAMXParseMesh: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating a texture stack.", resourceFile, entityID, nodeValue);
                                    else {
                                        while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                            id<NSObject> entityRef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                            if(entityRef && [entityRef conformsToProtocol:@protocol(egwPTexture)]) {
                                                [entityTStack addTexture:(id<egwPTexture>)entityRef];
                                            } else {
                                                NSLog(@"egwAssetManager: egwGAMXParseMesh: Failure parsing in manifest input file '%s', for asset '%s': Texture stack node type '%s' not supported.", resourceFile, entityID, nodeValue);
                                                egwGAMXParseSkip(xmlReadHandle, retVal, nodeValue);
                                            }
                                            [entityRef release]; entityRef = nil;
                                            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                            if(*retVal != 1) break;
                                        }
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"textures");
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"render_flags") == 0) {
                                    egwGAMXParseFlags_Render(resourceFile, entityID, xmlReadHandle, retVal, &entityRFlags);
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"offset") == 0) {
                                    while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                        if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                            egwGAMXParseTransform(xmlReadHandle, retVal, &entityOffset);
                                        else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                            id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                            if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                                [(id<egwPOrientated>)entity trySetOffsetDriver:(id<egwPInterpolator>)entityIPORef];
                                            }
                                            [entityIPORef release]; entityIPORef = nil;
                                        }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"offset");
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"orient") == 0) {
                                    while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                        if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                            egwGAMXParseTransform(xmlReadHandle, retVal, &entityOrient);
                                        else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                            id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                            if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                                [(id<egwPOrientated>)entity trySetOrientateDriver:(id<egwPInterpolator>)entityIPORef];
                                            }
                                            [entityIPORef release]; entityIPORef = nil;
                                        }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"orient");
                                }
                                
                                if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            
                            if(*retVal == 1) {
                                if(!egwMatIsEqual44f(&entityOffset, &egwSIMatIdentity44f)) [(id<egwPGeometry>)entity offsetByTransform:&entityOffset];
                                if(!egwMatIsEqual44f(&entityOrient, &egwSIMatIdentity44f)) [(id<egwPGeometry>)entity orientateByTransform:&entityOrient];
                                if(entityRFlags != [(id<egwPGeometry>)entityRef renderingFlags]) [(id<egwPGeometry>)entity setRenderingFlags:entityRFlags];
                                if(entityMStack) [(id<egwPGeometry>)entity setMaterialStack:entityMStack];
                                if(entityTStack) [(id<egwPGeometry>)entity setTextureStack:entityTStack];
                            }
                            
                            [entityMStack release]; entityMStack = nil;
                            [entityTStack release]; entityTStack = nil;
                            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                        }
                    }
                } else if(entityRef && !entityID) { // Get
                    entity = [entityRef retain];
                } else {
                    NSLog(@"egwAssetManager: egwGAMXParseMesh: Failure parsing in manifest input file '%s', for asset '%s': Mesh asset '%@' does not exist.", resourceFile, entityID, entityRefIdent);
                }
                
                [entityRefIdent release]; entityRefIdent = nil;
                [entityRef release]; entityRef = nil;
            } else {
                NSLog(@"egwAssetManager: egwGAMXParseMesh: Failure parsing in manifest input file '%s', for asset '%s': Mesh node must contain an ID and/or reference an ID.", resourceFile, entityID);
            }
            
            if(entityID) { xmlFree(entityID); entityID = NULL; }
            if(entityRefID) { xmlFree(entityRefID); entityRefID = NULL; }
        } else {
            NSLog(@"egwAssetManager: egwGAMXParseMesh: Failure parsing in manifest input file '%s', for asset '%s': Mesh node type '%s' not supported.", resourceFile, entityID, entityNodeName);
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, entityNodeName);
    }
    
    return entity;
}

id<NSObject> egwGAMXParseNode(const EGWchar* resourceFile, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* loadCounter, const xmlChar* entityNodeName) {
    id<NSObject> entity = nil;
    xmlChar* entityID = NULL;
    xmlChar* entityRefID = NULL;
    
    if(entityNodeName) {
        if(strcasecmp((const char*)entityNodeName, (const char*)"node") == 0) {
            entityID = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"id");
            entityRefID = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"ref");
            
            if(entityID && !entityRefID) { // New
                xmlChar* entityNodeType = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"type");
                
                if((!entityNodeType || strcasecmp((const char*)entityNodeType, (const char*)"transform") == 0) && !xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                    EGWint nodeType;
                    xmlChar* nodeName = NULL;
                    xmlChar* nodeValue = NULL;
                    NSMutableArray* entityChildren = [[NSMutableArray alloc] init];
                    Class entityTBounding = nil;
                    egwMatrix44f entityOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityOffset);
                    egwMatrix44f entityOrient; egwMatCopy44f(&egwSIMatIdentity44f, &entityOrient);
                    egwSinglyLinkedList entityPerforms; egwSLListInit(&entityPerforms, NULL, sizeof(egwGAMPostPerforms), EGW_LIST_FLG_DFLT);
                    
                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                        
                        if(nodeType == 14) continue;
                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"bounding") == 0) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"volume") == 0)
                                    egwGAMXParseVolume(resourceFile, entityID, xmlReadHandle, retVal, &entityTBounding, NULL);
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"bounding");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"offset") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityOffset);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetOffsetDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"offset");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"orient") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityOrient);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetOrientateDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"orient");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"assets") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                id<NSObject> entityRef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                if(entityRef && [entityRef conformsToProtocol:@protocol(egwPObjectNode)]) {
                                    [entityChildren addObject:(id)entityRef];
                                } else {
                                    NSLog(@"egwAssetManager: egwGAMXParseNode: Failure parsing in manifest input file '%s', for asset '%s': Asset node type '%s' not supported.", resourceFile, entityID, nodeValue);
                                    egwGAMXParseSkip(xmlReadHandle, retVal, nodeValue);
                                }
                                [entityRef release]; entityRef = nil;
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"assets");
                        }
                        
                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                        if(*retVal != 1) break;
                    }
                    
                    if(*retVal == 1) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwTransformBranch alloc] initWithIdentity:entityIDIdent parentNode:nil childNodes:(NSArray*)entityChildren defaultBounding:entityTBounding])]) {
                            if(!egwMatIsEqual44f(&entityOffset, &egwSIMatIdentity44f)) [(id<egwPOrientated>)entity offsetByTransform:&entityOffset];
                            if(!egwMatIsEqual44f(&entityOrient, &egwSIMatIdentity44f)) [(id<egwPOrientated>)entity orientateByTransform:&entityOrient];
                            if(entityPerforms.eCount) {
                                egwSinglyLinkedListIter iter;
                                
                                if(egwSLListEnumerateStart(&entityPerforms, EGW_ITERATE_MODE_DFLT, &iter)) {
                                    egwGAMPostPerforms* action;
                                    
                                    while((action = (egwGAMPostPerforms*)egwSLListEnumerateNextPtr(&iter))) {
                                        if(action->object1 && action->object2)
                                            [entity performSelector:action->method withObject:action->object1 withObject:action->object2];
                                        else if(action->object1)
                                            [entity performSelector:action->method withObject:action->object1];
                                        else
                                            [entity performSelector:action->method];
                                    }
                                }
                            }
                            ++(*loadCounter);
                        } else
                            NSLog(@"egwAssetManager: egwGAMXParseNode: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating transform node asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    }
                    
                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                    [entityChildren release]; entityChildren = nil;
                    egwSLListFree(&entityPerforms);
                } else if(entityNodeType && strcasecmp((const char*)entityNodeType, (const char*)"dlod") == 0 && !xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                    EGWint nodeType;
                    xmlChar* nodeName = NULL;
                    xmlChar* nodeValue = NULL;
                    NSMutableArray* entityChildrenLayers = [[NSMutableArray alloc] init];
                    NSMutableArray* entityLayerDistances = [[NSMutableArray alloc] init];
                    Class entityTBounding = nil;
                    EGWuint16 entityTLayers = 0;
                    egwMatrix44f entityOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityOffset);
                    egwMatrix44f entityOrient; egwMatCopy44f(&egwSIMatIdentity44f, &entityOrient);
                    egwSinglyLinkedList entityPerforms; egwSLListInit(&entityPerforms, NULL, sizeof(egwGAMPostPerforms), EGW_LIST_FLG_DFLT);
                    
                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                        
                        if(nodeType == 14) continue;
                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"bounding") == 0) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"volume") == 0)
                                    egwGAMXParseVolume(resourceFile, entityID, xmlReadHandle, retVal, &entityTBounding, NULL);
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"bounding");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"offset") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityOffset);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetOffsetDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"offset");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"orient") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityOrient);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetOrientateDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"orient");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"layers") == 0) {
                            xmlChar* entityLayers = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"count");
                            
                            if(entityLayers && egwParseStringui16cv((EGWchar*)entityLayers, &entityTLayers, 0, 1) && entityTLayers >= 1) {
                                while(entityChildrenLayers && entityLayerDistances && (EGWuint16)[entityChildrenLayers count] < entityTLayers &&
                                      egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                    if(strcasecmp((const char*)nodeValue, (const char*)"assets") == 0) {
                                        if([entityChildrenLayers count] >= 1) {
                                            EGWsingle entityLDistance;
                                            xmlChar* entityDistance = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"distance");
                                            
                                            if(entityDistance && egwParseStringfcv((EGWchar*)entityDistance, &entityLDistance, 0, 1)) {
                                                egwSingle* boxedValue = [(egwSingle*)[egwSingle alloc] initWithValue:entityLDistance];
                                                [entityLayerDistances addObject:boxedValue];
                                                [boxedValue release]; boxedValue = nil;
                                            } else {
                                                NSLog(@"egwAssetManager: egwGAMXParseNode: Failure parsing in manifest input file '%s', for asset '%s': Layer distance not specified.", resourceFile, entityID);
                                                [entityChildrenLayers release]; entityChildrenLayers = nil;
                                                [entityLayerDistances release]; entityLayerDistances = nil;
                                            }
                                            
                                            if(entityDistance) { xmlFree(entityDistance); entityDistance = NULL; }
                                        }
                                        
                                        if(entityChildrenLayers && entityLayerDistances) {
                                            NSMutableArray* entityChildren = [[NSMutableArray alloc] init];
                                            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                            
                                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                                id<NSObject> entityRef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                                if(entityRef && [entityRef conformsToProtocol:@protocol(egwPObjectNode)]) {
                                                    [entityChildren addObject:(id)entityRef];
                                                } else {
                                                    NSLog(@"egwAssetManager: egwGAMXParseNode: Failure parsing in manifest input file '%s', for asset '%s': Asset node type '%s' not supported.", resourceFile, entityID, nodeValue);
                                                    egwGAMXParseSkip(xmlReadHandle, retVal, nodeValue);
                                                }
                                                [entityRef release]; entityRef = nil;
                                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                                if(*retVal != 1) break;
                                            }
                                            
                                            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                            [entityChildrenLayers addObject:(id)entityChildren];
                                            [entityChildren release]; entityChildren = nil;
                                        }
                                        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"assets");
                                    } else NSLog(@"egwAssetManager: egwGAMXParseNode: Failure parsing in manifest input file '%s', for asset '%s': Layer node malformed or layer type '%s' not supported.", resourceFile, entityID, (nodeValue ? (const char*)nodeValue : (const char*)"<NULL>"));
                                    
                                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                    if(*retVal != 1) break;
                                }
                            } else NSLog(@"egwAssetManager: egwGAMXParseNode: Failure parsing in manifest input file '%s', for asset '%s': Layer count not specified.", resourceFile, entityID);
                            
                            if(entityLayers) { xmlFree(entityLayers); entityLayers = NULL; }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"layers");
                        }
                        
                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                        if(*retVal != 1) break;
                    }
                    
                    if(*retVal == 1) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        
                        if(entityChildrenLayers && entityLayerDistances && entityTLayers == (EGWuint16)[entityChildrenLayers count] && entityTLayers == (EGWuint16)([entityLayerDistances count] + 1) &&
                           [egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwDLODBranch alloc] initWithIdentity:entityIDIdent parentNode:nil childNodes:nil defaultBounding:entityTBounding totalSets:entityTLayers controlDistances:NULL])]) {
                            {   EGWuint setIndex = 0;
                                for(NSMutableArray* layer in entityChildrenLayers)
                                    [(egwDLODBranch*)entity addAllChildren:(NSArray*)layer toSetByIndex:setIndex++];
                                setIndex = 1;
                                for(egwSingle* boxedValue in entityLayerDistances)
                                    [(egwDLODBranch*)entity setDLOD:setIndex++ controlDistance:[boxedValue value]];
                            }
                            if(!egwMatIsEqual44f(&entityOffset, &egwSIMatIdentity44f)) [(id<egwPOrientated>)entity offsetByTransform:&entityOffset];
                            if(!egwMatIsEqual44f(&entityOrient, &egwSIMatIdentity44f)) [(id<egwPOrientated>)entity orientateByTransform:&entityOrient];
                            if(entityPerforms.eCount) {
                                egwSinglyLinkedListIter iter;
                                
                                if(egwSLListEnumerateStart(&entityPerforms, EGW_ITERATE_MODE_DFLT, &iter)) {
                                    egwGAMPostPerforms* action;
                                    
                                    while((action = (egwGAMPostPerforms*)egwSLListEnumerateNextPtr(&iter))) {
                                        if(action->object1 && action->object2)
                                            [entity performSelector:action->method withObject:action->object1 withObject:action->object2];
                                        else if(action->object1)
                                            [entity performSelector:action->method withObject:action->object1];
                                        else
                                            [entity performSelector:action->method];
                                    }
                                }
                            }
                            ++(*loadCounter);
                        } else
                            NSLog(@"egwAssetManager: egwGAMXParseNode: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating transform node asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    }
                    
                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                    [entityChildrenLayers release]; entityChildrenLayers = nil;
                    [entityLayerDistances release]; entityLayerDistances = nil;
                    egwSLListFree(&entityPerforms);
                } else {
                    NSLog(@"egwAssetManager: egwGAMXParseNode: Failure parsing in manifest input file '%s', for asset '%s': Node node malformed or type attribute '%s' not supported.", resourceFile, entityID, (entityNodeType ? (const char*)entityNodeType : (const char*)"<NULL>"));
                }
                
                if(entityNodeType) { xmlFree(entityNodeType); entityNodeType = NULL; }
            } else if (entityRefID) { // Copy/Get
                NSString* entityRefIdent = [[NSString alloc] initWithUTF8String:(const char*)entityRefID];
                id<NSObject> entityRef = (id<NSObject>)[[egwSIAsstMngr retrieveAsset:entityRefIdent] retain];
                
                if(entityRef && entityID) { // Copy
                    NSLog(@"egwAssetManager: egwGAMXParseNode: Failure parsing in manifest input file '%s', for asset '%s': Copying node class type '%@' not supported.", resourceFile, entityID, [entityRef class]);
                } else if(entityRef && !entityID) { // Get
                    entity = [entityRef retain];
                } else {
                    NSLog(@"egwAssetManager: egwGAMXParseNode: Failure parsing in manifest input file '%s', for asset '%s': Node asset '%@' does not exist.", resourceFile, entityID, entityRefIdent);
                }
                
                [entityRefIdent release]; entityRefIdent = nil;
                [entityRef release]; entityRef = nil;
            } else {
                NSLog(@"egwAssetManager: egwGAMXParseNode: Failure parsing in manifest input file '%s', for asset '%s': Node node must contain an ID and/or reference an ID.", resourceFile, entityID);
            }
            
            if(entityID) { xmlFree(entityID); entityID = NULL; }
            if(entityRefID) { xmlFree(entityRefID); entityRefID = NULL; }
        } else {
            NSLog(@"egwAssetManager: egwGAMXParseNode: Failure parsing in manifest input file '%s', for asset '%s': Node node type '%s' not supported.", resourceFile, entityID, entityNodeName);
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, entityNodeName);
    }
    
    return entity;
}

// Instantiation type and distinct parameter values for timer parsing
typedef struct {
    EGWint16 type; // invalid type = -1, basic timer = 0, actioned timer = 1
    EGWint16 srcType; // invalid type = -1, basic = 0, actioned boundings = 1, actioned blank = 2
    union {
        struct { egwAbsTimeBound bounds; } bsctmr; // basic = 0
        struct { egwAbsTimedActions actions; } actbnd; // actioned boundings = 1
        struct { EGWuint16 aCount; EGWuint16 dAction; } actblnk; // actioned blank = 2
    } dist;
} egwGAMXTimerParams;

id<NSObject> egwGAMXParseTimer(const EGWchar* resourceFile, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* loadCounter, const xmlChar* entityNodeName) {
    id<NSObject> entity = nil;
    xmlChar* entityID = NULL;
    xmlChar* entityRefID = NULL;
    
    if(entityNodeName) {
        if(strcasecmp((const char*)entityNodeName, (const char*)"timer") == 0) {
            entityID = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"id");
            entityRefID = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"ref");
            
            if(entityID && !entityRefID) { // New
                xmlChar* entityNodeType = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"type");
                
                if((!entityNodeType || (strcasecmp((const char*)entityNodeType, (const char*)"basic") == 0 || strcasecmp((const char*)entityNodeType, (const char*)"actioned") == 0)) && !xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                    EGWint nodeType;
                    xmlChar* nodeName = NULL;
                    xmlChar* nodeValue = NULL;
                    egwGAMXTimerParams entityParams; memset((void*)&entityParams, 0, sizeof(egwGAMXTimerParams)); entityParams.type = entityParams.srcType = -1;
                    EGWuint entityAFlags = 0;
                    
                    if(!entityNodeType || strcasecmp((const char*)entityNodeType, (const char*)"basic") == 0)
                        entityParams.type = 0; // basic timer
                    else if(strcasecmp((const char*)entityNodeType, (const char*)"actioned") == 0)
                        entityParams.type = 1; // actioned timer
                    
                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                        
                        if(nodeType == 14) continue;
                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"actions") == 0 && !xmlTextReaderIsEmptyElement(xmlReadHandle) && entityParams.type == 1) {
                            xmlChar* entitySourceSrc = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"source");
                            
                            if(!entitySourceSrc || strcasecmp((const char*)entitySourceSrc, (const char*)"internal") == 0) {
                                xmlChar* entitySourceType = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"type");
                                
                                if(entitySourceType && strcasecmp((const char*)entitySourceType, (const char*)"boundings") == 0) {
                                    EGWuint aCount; xmlChar* entityACount = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"count");
                                    
                                    if(entityACount && egwParseStringuicv((EGWchar*)entityACount, (EGWuint*)&aCount, 0, 1) == 1) {
                                        aCount = egwClampui(aCount, 1, EGW_UINT16_MAX);
                                        
                                        if((entityParams.dist.actbnd.actions.tBounds = (egwAbsTimeBound*)malloc((size_t)aCount * sizeof(egwAbsTimeBound))) &&
                                           (entityParams.dist.actbnd.actions.aNames = (EGWchar**)malloc((size_t)aCount * sizeof(EGWchar*)))) { // This malloc has to be last since it's a 2D array
                                            EGWuint boundingsProcessed = 0;
                                            
                                            memset((void*)entityParams.dist.actbnd.actions.tBounds, 0, (size_t)aCount * sizeof(egwAbsTimeBound));
                                            memset((void*)entityParams.dist.actbnd.actions.aNames, 0, (size_t)aCount * sizeof(EGWchar*));
                                            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                            
                                            // boundings read
                                            while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                                nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                                
                                                if(nodeType == 14) continue;
                                                else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"actions") == 0) break;
                                                else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"bounding") == 0) {
                                                    xmlChar* entityBName = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"name");
                                                    if(entityBName) {
                                                        if(entityParams.dist.actbnd.actions.aNames[boundingsProcessed])
                                                            free((void*)entityParams.dist.actbnd.actions.aNames[boundingsProcessed]);
                                                        entityParams.dist.actbnd.actions.aNames[boundingsProcessed] = (EGWchar*)strdup((const char*)entityBName);
                                                        xmlFree(entityBName); entityBName = NULL;
                                                    }
                                                    
                                                    xmlChar* entityBOptions = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"options");
                                                    if(entityBOptions) {
                                                        if(strcasestr((const char*)entityBOptions, (const char*)"default"))
                                                            entityParams.dist.actbnd.actions.daIndex = boundingsProcessed;
                                                        xmlFree(entityBOptions); entityBOptions = NULL;
                                                    }
                                                    
                                                    if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                                        EGWuint nodesProcessed = 0;
                                                        xmlChar* entityBnds = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                                                        
                                                        if(sizeof(EGWtime) == sizeof(EGWsingle)) nodesProcessed = egwParseStringfcv((EGWchar*)entityBnds, (EGWsingle*)&entityParams.dist.actbnd.actions.tBounds[boundingsProcessed], 0, 2);
                                                        else if(sizeof(EGWtime) == sizeof(EGWdouble)) nodesProcessed = egwParseStringdcv((EGWchar*)entityBnds, (EGWdouble*)&entityParams.dist.actbnd.actions.tBounds[boundingsProcessed], 0, 2);
                                                        else if(sizeof(EGWtime) == sizeof(EGWtriple)) nodesProcessed = egwParseStringtcv((EGWchar*)entityBnds, (EGWtriple*)&entityParams.dist.actbnd.actions.tBounds[boundingsProcessed], 0, 2);
                                                        
                                                        if(nodesProcessed != 2) { // Pad rest if short
                                                            NSLog(@"egwAssetManager: egwGAMXParseTimer: Warning parsing in manifest input file '%s', for asset '%s': Boundings read %d for action %d does not match 2 needed. Padded rest with neighbors/zeroes.", resourceFile, entityID, nodesProcessed, boundingsProcessed+1);
                                                            if(nodesProcessed == 1)
                                                                entityParams.dist.actbnd.actions.tBounds[boundingsProcessed].tEnd = entityParams.dist.actbnd.actions.tBounds[boundingsProcessed].tBegin;
                                                            else if(boundingsProcessed)
                                                                entityParams.dist.actbnd.actions.tBounds[boundingsProcessed].tEnd = entityParams.dist.actbnd.actions.tBounds[boundingsProcessed].tBegin = entityParams.dist.actbnd.actions.tBounds[boundingsProcessed-1].tEnd;
                                                            else
                                                                entityParams.dist.actbnd.actions.tBounds[boundingsProcessed].tEnd = entityParams.dist.actbnd.actions.tBounds[boundingsProcessed].tBegin = (EGWtime)0.0;
                                                        }
                                                    }
                                                    
                                                    if(*retVal == 1) {
                                                        ++boundingsProcessed;
                                                        if(boundingsProcessed >= aCount) {
                                                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"actions");
                                                            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                                            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                                            break;
                                                        }
                                                    }
                                                    
                                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"bounding");
                                                }
                                                
                                                if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                                if(*retVal != 1) break;
                                            }
                                            
                                            if(*retVal == 1) {
                                                if(entityParams.dist.actbnd.actions.tBounds) {
                                                    entityParams.dist.actbnd.actions.aCount = (EGWuint16)aCount;
                                                    entityParams.srcType = 1; // actioned boundings
                                                    
                                                    if(boundingsProcessed != aCount)
                                                        NSLog(@"egwAssetManager: egwGAMXParseTimer: Warning parsing in manifest input file '%s', for asset '%s': Bounding pairs read %d does not match %d actions specified. Padded rest with zeroes.", resourceFile, entityID, boundingsProcessed, aCount);
                                                }
                                            }
                                        } else {
                                            NSLog(@"egwAssetManager: egwGAMXParseTimer: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for bounding structures.", resourceFile, entityID, (size_t)aCount * (sizeof(EGWchar*) + sizeof(egwAbsTimeBound)));
                                            if(entityParams.dist.actbnd.actions.tBounds) { free((void*)entityParams.dist.actbnd.actions.tBounds); entityParams.dist.actbnd.actions.tBounds = NULL; }
                                            if(entityParams.dist.actbnd.actions.aNames) { free((void*)entityParams.dist.actbnd.actions.aNames); entityParams.dist.actbnd.actions.aNames = NULL; }
                                        }
                                    } else NSLog(@"egwAssetManager: egwGAMXParseTimer: Failure parsing in manifest input file '%s', for asset '%s': Boundings count not specified.", resourceFile, entityID);
                                    
                                    if(entityACount) { xmlFree(entityACount); entityACount = NULL; }
                                } else if(entitySourceType && strcasecmp((const char*)entitySourceType, (const char*)"blank") == 0) {
                                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                    
                                    // blank read
                                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                        
                                        if(nodeType == 14) continue;
                                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"actions") == 0) break;
                                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"action_count") == 0) {
                                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                                egwParseStringui16cv((EGWchar*)nodeValue, (EGWuint16*)&entityParams.dist.actblnk.aCount, 0, 1);
                                                if(entityParams.dist.actblnk.aCount < 1) entityParams.dist.actblnk.aCount = 1;
                                            }
                                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"action_count");
                                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"default_action") == 0) {
                                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                                egwParseStringuicv((EGWchar*)nodeValue, (EGWuint*)&entityParams.dist.actblnk.dAction, 0, 1);
                                            }
                                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"default_action");
                                        }
                                        
                                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    
                                    if(*retVal == 1) {
                                        entityParams.srcType = 3; // actioned blank
                                    }
                                } else NSLog(@"egwAssetManager: egwGAMXParseTimer: Failure parsing in manifest input file '%s', for asset '%s': Timer internal type '%s' not supported.", resourceFile, entityID, (entitySourceType ? (const char*)entitySourceType : (const char*)"<NULL>"));
                                
                                if(entitySourceType) { xmlFree(entitySourceType); entitySourceType = NULL; }
                            //} else if(strcasecmp((const char*)entitySourceSrc, (const char*)"external") == 0) {
                                // TODO: Actioned timer read external actions.
                            } else NSLog(@"egwAssetManager: egwGAMXParseTimer: Failure parsing in manifest input file '%s', for asset '%s': Timer source '%s' not supported.", resourceFile, entityID, (entitySourceSrc ? (const char*)entitySourceSrc : (const char*)"<NULL>"));
                            
                            if(entitySourceSrc) { xmlFree(entitySourceSrc); entitySourceSrc = NULL; }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"actions");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"bounding") == 0 && entityParams.type == 0) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                EGWuint nodesProcessed = 0;
                                xmlChar* entityBnds = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                                
                                if(sizeof(EGWtime) == sizeof(EGWsingle)) nodesProcessed = egwParseStringfcv((EGWchar*)entityBnds, (EGWsingle*)&entityParams.dist.bsctmr.bounds, 0, 2);
                                else if(sizeof(EGWtime) == sizeof(EGWdouble)) nodesProcessed = egwParseStringdcv((EGWchar*)entityBnds, (EGWdouble*)&entityParams.dist.bsctmr.bounds, 0, 2);
                                else if(sizeof(EGWtime) == sizeof(EGWtriple)) nodesProcessed = egwParseStringtcv((EGWchar*)entityBnds, (EGWtriple*)&entityParams.dist.bsctmr.bounds, 0, 2);
                                
                                if(nodesProcessed != 2) { // Pad rest if short
                                    NSLog(@"egwAssetManager: egwGAMXParseTimer: Warning parsing in manifest input file '%s', for asset '%s': Explicit boundings read %d does not match 2 needed.", resourceFile, entityID, nodesProcessed);
                                    if(nodesProcessed == 1)
                                        entityParams.dist.bsctmr.bounds.tEnd = entityParams.dist.bsctmr.bounds.tBegin;
                                }
                                
                                entityParams.srcType = 0;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"bounding");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"actuator_flags") == 0) {
                            egwGAMXParseFlags_Actuator(resourceFile, entityID, xmlReadHandle, retVal, &entityAFlags);
                        }
                        
                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                        if(*retVal != 1) break;
                    }
                    
                    if(*retVal == 1) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if((((entityParams.srcType == -1 && entityParams.type == 0) || entityParams.srcType == 0) && // basic
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwTimer alloc] initWithIdentity:entityIDIdent])]) ||
                           (entityParams.srcType == 1 && // actioned boundings
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwActionedTimer alloc] initWithIdentity:entityIDIdent actionsSet:&entityParams.dist.actbnd.actions])]) ||
                           (entityParams.srcType == 2 && // actioned blank
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwActionedTimer alloc] initBlankWithIdentity:entityIDIdent actionCount:entityParams.dist.actblnk.aCount defaultAction:entityParams.dist.actblnk.dAction])])) {
                                if(entityParams.type == 0 && entityParams.srcType == 0) [(egwTimer*)entity setExplicitBoundsBegin:entityParams.dist.bsctmr.bounds.tBegin andEnd:entityParams.dist.bsctmr.bounds.tEnd];
                                if(entityAFlags) [(id<egwPTimer>)entity setActuatorFlags:entityAFlags];
                                ++(*loadCounter);
                            } else
                                NSLog(@"egwAssetManager: egwGAMXParseTimer: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating timer asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    }
                    
                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                    if(entityParams.srcType == 1) {
                        if(entityParams.dist.actbnd.actions.tBounds) { free((void*)entityParams.dist.actbnd.actions.tBounds); entityParams.dist.actbnd.actions.tBounds = NULL; }
                        if(entityParams.dist.actbnd.actions.aNames) {
                            for(EGWint actIndex = 0; actIndex < entityParams.dist.actbnd.actions.aCount; ++actIndex)
                                if(entityParams.dist.actbnd.actions.aNames[actIndex]) { free((void*)entityParams.dist.actbnd.actions.aNames[actIndex]); entityParams.dist.actbnd.actions.aNames[actIndex] = NULL; }
                            free((void*)entityParams.dist.actbnd.actions.aNames); entityParams.dist.actbnd.actions.aNames = NULL; }
                    }
                } else {
                    NSLog(@"egwAssetManager: egwGAMXParseTimer: Failure parsing in manifest input file '%s', for asset '%s': Timer node malformed or type attribute '%s' not supported.", resourceFile, entityID, (entityNodeType ? (const char*)entityNodeType : (const char*)"<NULL>"));
                }
                
                if(entityNodeType) { xmlFree(entityNodeType); entityNodeType = NULL; }
            } else if (entityRefID) { // !!!: Timer Copy/Get
                NSString* entityRefIdent = [[NSString alloc] initWithUTF8String:(const char*)entityRefID];
                id<NSObject> entityRef = (id<NSObject>)[[egwSIAsstMngr retrieveAsset:entityRefIdent] retain];
                EGWint16 entityTType = -1;
                
                if(entityRef && entityID) { // Copy
                    if([entityRef isKindOfClass:[egwTimer class]]) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwTimer alloc] initCopyOf:(id<egwPAsset,egwPTimer>)entityRef withIdentity:entityIDIdent])]) {
                            entityTType = 0;
                            ++(*loadCounter);
                        } else
                            NSLog(@"egwAssetManager: egwGAMXParseTimer: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating basic timer asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    } else if([entityRef isKindOfClass:[egwActionedTimer class]]) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwActionedTimer alloc] initCopyOf:(id<egwPAsset,egwPTimer>)entityRef withIdentity:entityIDIdent])]) {
                            entityTType = 1;
                            ++(*loadCounter);
                        } else
                            NSLog(@"egwAssetManager: egwGAMXParseTimer: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating actioned timer asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    } else {
                        NSLog(@"egwAssetManager: egwGAMXParseTimer: Failure parsing in manifest input file '%s', for asset '%s': Copying timer class type '%@' not supported.", resourceFile, entityID, [entityRef class]);
                    }
                    
                    if(entity) {
                        if(!xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                            EGWint nodeType;
                            xmlChar* nodeName = NULL;
                            xmlChar* nodeValue = NULL;
                            EGWuint entityAFlags = [(id<egwPTimer>)entity actuatorFlags];
                            
                            while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                
                                if(nodeType == 14) continue;
                                else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                                else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"actuator_flags") == 0) {
                                    egwGAMXParseFlags_Actuator(resourceFile, entityID, xmlReadHandle, retVal, &entityAFlags);
                                }
                                
                                if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            
                            if(*retVal == 1) {
                                if(entityAFlags != [(id<egwPTimer>)entity actuatorFlags]) [(id<egwPTimer>)entity setActuatorFlags:entityAFlags];
                            }
                            
                            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                        }
                    }
                } else if(entityRef && !entityID) { // Get
                    entity = [entityRef retain];
                } else {
                    NSLog(@"egwAssetManager: egwGAMXParseTimer: Failure parsing in manifest input file '%s', for asset '%s': Timer asset '%@' does not exist.", resourceFile, entityID, entityRefIdent);
                }
                
                [entityRefIdent release]; entityRefIdent = nil;
                [entityRef release]; entityRef = nil;
            } else {
                NSLog(@"egwAssetManager: egwGAMXParseTimer: Failure parsing in manifest input file '%s', for asset '%s': Timer node must contain an ID and/or reference an ID.", resourceFile, entityID);
            }
            
            if(entityID) { xmlFree(entityID); entityID = NULL; }
            if(entityRefID) { xmlFree(entityRefID); entityRefID = NULL; }
        } else {
            NSLog(@"egwAssetManager: egwGAMXParseTimer: Failure parsing in manifest input file '%s', for asset '%s': Timer node type '%s' not supported.", resourceFile, entityID, entityNodeName);
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, entityNodeName);
    }
    
    return entity;
}

// Instantiation type and distinct parameter values for sound parsing
typedef struct {
    EGWint16 type; // invalid type = -1, point sound = 0, streamed point sound = 1
    EGWint16 srcType; // invalid type = -1, point audio = 0, point blank = 1, streamed point audio stream = 2
    union {
        struct { egwAudio audio; } ado; // point audio = 0
        struct { EGWuint32 format; EGWuint rate; EGWuint count; } blnk; // point blank = 1
        struct { void* stream; EGWuint16 bCount; EGWuint bSize; } strm; // streamed point audio stream = 2
    } dist;
} egwGAMXSoundParams;

id<NSObject> egwGAMXParseSound(const EGWchar* resourceFile, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* loadCounter, const xmlChar* entityNodeName) {
    id<NSObject> entity = nil;
    xmlChar* entityID = NULL;
    xmlChar* entityRefID = NULL;
    
    if(entityNodeName) {
        if(strcasecmp((const char*)entityNodeName, (const char*)"sound") == 0) {
            entityID = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"id");
            entityRefID = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"ref");
            
            if(entityID && !entityRefID) { // New
                xmlChar* entityNodeType = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"type");
                
                if((!entityNodeType || strcasecmp((const char*)entityNodeType, (const char*)"point") == 0 || strcasecmp((const char*)entityNodeType, (const char*)"streamed_point") == 0) && !xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                    EGWint nodeType;
                    xmlChar* nodeName = NULL;
                    xmlChar* nodeValue = NULL;
                    egwGAMXSoundParams entityParams; memset((void*)&entityParams, 0, sizeof(egwGAMXSoundParams)); entityParams.type = entityParams.srcType = -1;
                    EGWuint entitySTrans = 0;
                    EGWuint entitySFlags = 0;
                    EGWsingle entitySRolloff = 1.0f;
                    EGWsingle entitySRadius = EGW_SFLT_MAX;
                    egwAudioEffects2f entitySEffects; memcpy((void*)&entitySEffects, (const void*)&egwSIVecOne2f, sizeof(egwAudioEffects2f));
                    egwMatrix44f entityBaseOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityBaseOffset);
                    egwMatrix44f entityOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityOffset);
                    egwMatrix44f entityOrient; egwMatCopy44f(&egwSIMatIdentity44f, &entityOrient);
                    egwSinglyLinkedList entityPerforms; egwSLListInit(&entityPerforms, NULL, sizeof(egwGAMPostPerforms), EGW_LIST_FLG_DFLT);
                    
                    if(!entityNodeType || strcasecmp((const char*)entityNodeType, (const char*)"point") == 0)
                        entityParams.type = 0; // point sound
                    else if(strcasecmp((const char*)entityNodeType, (const char*)"streamed_point") == 0)
                        entityParams.type = 1; // streamed point sound
                    
                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                        
                        if(nodeType == 14) continue;
                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"audio") == 0 && !xmlTextReaderIsEmptyElement(xmlReadHandle) && entityParams.type == 0) {
                            xmlChar* entitySourceSrc = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"source");
                            
                            if(!entitySourceSrc || strcasecmp((const char*)entitySourceSrc, (const char*)"internal") == 0) {
                                xmlChar* entitySourceType = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"type");
                                
                                if(entitySourceType && strcasecmp((const char*)entitySourceType, (const char*)"pcm_array") == 0) {
                                    egwGAMXParseAudio_PCMA(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.ado.audio, &entitySTrans);
                                    
                                    if(*retVal == 1) {
                                        if(entityParams.dist.ado.audio.data)
                                            entityParams.srcType = 0; // point audio
                                    }
                                } else if(entitySourceType && strcasecmp((const char*)entitySourceType, (const char*)"blank") == 0) {
                                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                    
                                    // blank read
                                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                        
                                        if(nodeType == 14) continue;
                                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"audio") == 0) break;
                                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"format") == 0) {
                                            egwGAMXParseAudio_Format(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.blnk.format);
                                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"rate") == 0) {
                                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                                egwParseStringuicv((EGWchar*)nodeValue, (EGWuint*)&entityParams.dist.blnk.rate, 0, 1);
                                            }
                                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"rate");
                                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"count") == 0) {
                                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                                egwParseStringuicv((EGWchar*)nodeValue, (EGWuint*)&entityParams.dist.blnk.count, 0, 1);
                                            }
                                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"count");
                                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"transforms") == 0) {
                                            egwGAMXParseAudio_Transforms(resourceFile, entityID, xmlReadHandle, retVal, &entitySTrans);
                                        }
                                        
                                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    
                                    if(*retVal == 1) {
                                        entityParams.srcType = 1; // point blank
                                    }
                                } else NSLog(@"egwAssetManager: egwGAMXParseSound: Failure parsing in manifest input file '%s', for asset '%s': Audio internal type '%s' not supported.", resourceFile, entityID, (entitySourceType ? (const char*)entitySourceType : (const char*)"<NULL>"));
                                
                                if(entitySourceType) { xmlFree(entitySourceType); entitySourceType = NULL; }
                            } else if(strcasecmp((const char*)entitySourceSrc, (const char*)"external") == 0) {
                                egwGAMXParseAudio_External(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.ado.audio, &entitySTrans);
                                
                                if(*retVal == 1) {
                                    if(entityParams.dist.ado.audio.data)
                                        entityParams.srcType = 0; // point audio
                                }
                            } else NSLog(@"egwAssetManager: egwGAMXParseSound: Failure parsing in manifest input file '%s', for asset '%s': Audio source '%s' not supported.", resourceFile, entityID, (entitySourceSrc ? (const char*)entitySourceSrc : (const char*)"<NULL>"));
                            
                            if(entitySourceSrc) { xmlFree(entitySourceSrc); entitySourceSrc = NULL; }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"audio");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"audio_stream") == 0 && !xmlTextReaderIsEmptyElement(xmlReadHandle) && entityParams.type == 1) {
                            xmlChar* entitySourceSrc = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"source");
                            
                            if(!entitySourceSrc || strcasecmp((const char*)entitySourceSrc, (const char*)"external") == 0) {
                                egwGAMXParseAudioStream_External(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.strm.stream, &entitySTrans);
                                
                                if(*retVal == 1) {
                                    if(entityParams.dist.strm.stream)
                                        entityParams.srcType = 2; // streamed point audio stream
                                }
                            //} else if(strcasecmp((const char*)entitySourceSrc, (const char*)"internal") == 0) {
                                // TODO: Sound read internal audio stream.
                            } else NSLog(@"egwAssetManager: egwGAMXParseSound: Failure parsing in manifest input file '%s', for asset '%s': Audio source '%s' not supported.", resourceFile, entityID, (entitySourceSrc ? (const char*)entitySourceSrc : (const char*)"<NULL>"));
                            
                            if(entitySourceSrc) { xmlFree(entitySourceSrc); entitySourceSrc = NULL; }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"audio_stream");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"radius") == 0) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                xmlChar* entityRad = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                                if(entityRad && strcasecmp((const char*)entityRad, (const char*)"infinite") == 0)
                                    entitySRadius = EGW_SFLT_MAX;
                                else {
                                    egwParseStringfcv((EGWchar*)entityRad, (EGWsingle*)&entitySRadius, 0, 1);
                                    entitySRadius = egwClampPosf(entitySRadius);
                                }
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"radius");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"effects") == 0) {
                            EGWint runup, readup = 0;
                            while((runup = egwGAMXParseRunup(xmlReadHandle, retVal)) != 15 && *retVal == 1 && ((runup == 1 ? (nodeValue = xmlTextReaderName(xmlReadHandle)) : (nodeValue = xmlTextReaderValue(xmlReadHandle))))) {
                                if(runup == 1 && strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetResonationEffectsDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                } else if(runup == 3 && readup < 2) {
                                    readup += egwParseStringfcv((EGWchar*)nodeValue, &((EGWsingle*)&entitySEffects)[readup], 0, egwClampPosi(2 - readup));
                                    egwClrClamp2f((egwColor2f*)&entitySEffects, (egwColor2f*)&entitySEffects);
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"effects");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"rolloff") == 0) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                xmlChar* entityRol = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                                if(entityRol && strcasecmp((const char*)entityRol, (const char*)"disable") == 0)
                                    entitySRolloff = 0.0f;
                                else {
                                    egwParseStringfcv((EGWchar*)entityRol, (EGWsingle*)&entitySRolloff, 0, 1);
                                    entitySRolloff = egwClampPosf(entitySRolloff);
                                }
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"rolloff");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"buffer_count") == 0 && entityParams.srcType == 2) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                xmlChar* entityBfr = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                                if(entityBfr && strcasecmp((const char*)entityBfr, (const char*)"default") == 0)
                                    entityParams.dist.strm.bCount = 0;
                                else {
                                    egwParseStringui16cv((EGWchar*)entityBfr, (EGWuint16*)&entityParams.dist.strm.bCount, 0, 1);
                                }
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"buffer_count");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"buffer_size") == 0 && entityParams.srcType == 2) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                xmlChar* entityBfr = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                                if(entityBfr && strcasecmp((const char*)entityBfr, (const char*)"default") == 0)
                                    entityParams.dist.strm.bSize = 0;
                                else {
                                    egwParseStringui16cv((EGWchar*)entityBfr, (EGWuint16*)&entityParams.dist.strm.bSize, 0, 1);
                                }
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"buffer_size");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"playback_flags") == 0) {
                            egwGAMXParseFlags_Playback(resourceFile, entityID, xmlReadHandle, retVal, &entitySFlags);
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"base_offset") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityBaseOffset);
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"base_offset");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"offset") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityOffset);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetOffsetDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"offset");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"orient") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityOrient);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetOrientateDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"orient");
                        }
                        
                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                        if(*retVal != 1) break;
                    }
                    
                    if(*retVal == 1) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if((entityParams.srcType == 0 && // point audio
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwPointSound alloc] initWithIdentity:entityIDIdent soundAudio:&entityParams.dist.ado.audio soundRadius:entitySRadius resonationTransforms:entitySTrans resonationEffects:&entitySEffects resonationRolloff:entitySRolloff])]) ||
                           (entityParams.srcType == 1 && // point blank
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwPointSound alloc] initBlankWithIdentity:entityIDIdent audioFormat:entityParams.dist.blnk.format soundRate:entityParams.dist.blnk.rate soundSamples:entityParams.dist.blnk.count soundRadius:entitySRadius resonationTransforms:entitySTrans resonationEffects:&entitySEffects resonationRolloff:entitySRolloff])]) ||
                           (entityParams.srcType == 2 && // streamed point audio stream
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwStreamedPointSound alloc] initWithIdentity:entityIDIdent decoderStream:&entityParams.dist.strm.stream totalBuffers:entityParams.dist.strm.bCount bufferSize:entityParams.dist.strm.bSize soundRadius:entitySRadius resonationTransforms:entitySTrans resonationEffects:&entitySEffects resonationRolloff:entitySRolloff])])) {
                                BOOL entityBaseWasAligned = NO;
                                if(!egwMatIsEqual44f(&entityBaseOffset, &egwSIMatIdentity44f)) { [(egwPointSoundBase*)[(id<egwPSound>)entity playbackBase] baseOffsetByTransform:&entityBaseOffset]; entityBaseWasAligned = YES; }
                                if(!egwMatIsEqual44f(&entityOffset, &egwSIMatIdentity44f)) [(id<egwPSound>)entity offsetByTransform:&entityOffset];
                                if(!egwMatIsEqual44f(&entityOrient, &egwSIMatIdentity44f) || entityBaseWasAligned) [(id<egwPSound>)entity orientateByTransform:&entityOrient];
                                if(entitySFlags) [(id<egwPSound>)entity setPlaybackFlags:entitySFlags];
                                if(entityPerforms.eCount) {
                                    egwSinglyLinkedListIter iter;
                                    
                                    if(egwSLListEnumerateStart(&entityPerforms, EGW_ITERATE_MODE_DFLT, &iter)) {
                                        egwGAMPostPerforms* action;
                                        
                                        while((action = (egwGAMPostPerforms*)egwSLListEnumerateNextPtr(&iter))) {
                                            if(action->object1 && action->object2)
                                                [entity performSelector:action->method withObject:action->object1 withObject:action->object2];
                                            else if(action->object1)
                                                [entity performSelector:action->method withObject:action->object1];
                                            else
                                                [entity performSelector:action->method];
                                        }
                                    }
                                }
                                ++(*loadCounter);
                            } else
                                NSLog(@"egwAssetManager: egwGAMXParseSound: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating point sound asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    }
                    
                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                    if(entityParams.srcType == 0) egwAudioFree(&entityParams.dist.ado.audio);
                    if(entityParams.srcType == 2 && entityParams.dist.strm.stream) [egwSIAsstMngr addDecodingWorkForSoundAsset:nil withStreamDecoder:entityParams.dist.strm.stream segmentID:0 bufferID:0 bufferData:NULL bufferSize:0];
                    egwSLListFree(&entityPerforms);
                } else {
                    NSLog(@"egwAssetManager: egwGAMXParseSound: Failure parsing in manifest input file '%s', for asset '%s': Sound node malformed or type attribute '%s' not supported.", resourceFile, entityID, (entityNodeType ? (const char*)entityNodeType : (const char*)"<NULL>"));
                }
                
                if(entityNodeType) { xmlFree(entityNodeType); entityNodeType = NULL; }
            } else if (entityRefID) { // !!!: Sound Copy/Get
                NSString* entityRefIdent = [[NSString alloc] initWithUTF8String:(const char*)entityRefID];
                id<NSObject> entityRef = (id<NSObject>)[[egwSIAsstMngr retrieveAsset:entityRefIdent] retain];
                
                if(entityRef && entityID) { // Copy
                    if([entityRef isKindOfClass:[egwStreamedPointSound class]]) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwStreamedPointSound alloc] initCopyOf:(id<egwPAsset>)entityRef withIdentity:entityIDIdent totalBuffers:0 bufferSize:0])])
                            ++(*loadCounter);
                        else
                            NSLog(@"egwAssetManager: egwGAMXParseSound: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating streaming point sound asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    } else if([entityRef isKindOfClass:[egwPointSound class]]) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwPointSound alloc] initCopyOf:(id<egwPAsset>)entityRef withIdentity:entityIDIdent])])
                            ++(*loadCounter);
                        else
                            NSLog(@"egwAssetManager: egwGAMXParseSound: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating point sound asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    } else {
                        NSLog(@"egwAssetManager: egwGAMXParseSound: Failure parsing in manifest input file '%s', for asset '%s': Copying sound class type '%@' not supported.", resourceFile, entityID, [entityRef class]);
                    }
                    
                    if(entity) { // Shared unique properties (offset/orient/effects)
                        if(!xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                            EGWint nodeType;
                            xmlChar* nodeName = NULL;
                            xmlChar* nodeValue = NULL;
                            EGWuint entitySFlags = [(id<egwPSound>)entityRef playbackFlags];
                            EGWsingle entitySRolloff = [(id<egwPSound>)entityRef resonationRolloff];
                            egwAudioEffects2f entitySEffects; memcpy((void*)&entitySEffects, (const void*)[(id<egwPSound>)entityRef resonationEffects], sizeof(egwAudioEffects2f));
                            egwMatrix44f entityOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityOffset);
                            egwMatrix44f entityOrient; egwMatCopy44f(&egwSIMatIdentity44f, &entityOrient);
                            
                            while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                
                                if(nodeType == 14) continue;
                                else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                                else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"effects") == 0) {
                                    EGWint runup, readup = 0;
                                    while((runup = egwGAMXParseRunup(xmlReadHandle, retVal)) != 15 && *retVal == 1 && ((runup == 1 ? (nodeValue = xmlTextReaderName(xmlReadHandle)) : (nodeValue = xmlTextReaderValue(xmlReadHandle))))) {
                                        if(runup == 1 && strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                            id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                            if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                                [(id<egwPSound>)entity trySetResonationEffectsDriver:(id<egwPInterpolator>)entityIPORef];
                                            }
                                            [entityIPORef release]; entityIPORef = nil;
                                        } else if(runup == 3 && readup < 2) {
                                            readup += egwParseStringfcv((EGWchar*)nodeValue, &((EGWsingle*)&entitySEffects)[readup], 0, egwClampPosi(2 - readup));
                                            egwClrClamp2f((egwColor2f*)&entitySEffects, (egwColor2f*)&entitySEffects);
                                        }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"effects");
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"rolloff") == 0) {
                                    if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                        xmlChar* entityRol = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                                        if(entityRol && strcasecmp((const char*)entityRol, (const char*)"disable") == 0)
                                            entitySRolloff = 0.0f;
                                        else {
                                            egwParseStringfcv((EGWchar*)entityRol, (EGWsingle*)&entitySRolloff, 0, 1);
                                            entitySRolloff = egwClampPosf(entitySRolloff);
                                        }
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"rolloff");
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"playback_flags") == 0) {
                                    egwGAMXParseFlags_Playback(resourceFile, entityID, xmlReadHandle, retVal, &entitySFlags);
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"offset") == 0) {
                                    while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                        if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                            egwGAMXParseTransform(xmlReadHandle, retVal, &entityOffset);
                                        else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                            id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                            if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                                [(id<egwPOrientated>)entity trySetOffsetDriver:(id<egwPInterpolator>)entityIPORef];
                                            }
                                            [entityIPORef release]; entityIPORef = nil;
                                        }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"offset");
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"orient") == 0) {
                                    while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                        if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                            egwGAMXParseTransform(xmlReadHandle, retVal, &entityOrient);
                                        else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                            id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                            if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                                [(id<egwPOrientated>)entity trySetOrientateDriver:(id<egwPInterpolator>)entityIPORef];
                                            }
                                            [entityIPORef release]; entityIPORef = nil;
                                        }
                                        
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"orient");
                                }
                                
                                if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            
                            if(*retVal == 1) {
                                if(!egwMatIsEqual44f(&entityOffset, &egwSIMatIdentity44f)) [(id<egwPSound>)entity offsetByTransform:&entityOffset];
                                if(!egwMatIsEqual44f(&entityOrient, &egwSIMatIdentity44f)) [(id<egwPSound>)entity orientateByTransform:&entityOrient];
                                if(entitySFlags != [(id<egwPSound>)entityRef playbackFlags]) [(id<egwPSound>)entity setPlaybackFlags:entitySFlags];
                                if(!egwVecIsEqual2f((egwVector2f*)&entitySEffects, (egwVector2f*)[(id<egwPSound>)entityRef resonationEffects])) [(id<egwPSound>)entity setResonationEffects:&entitySEffects];
                            }
                            
                            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                        }
                    }
                } else if(entityRef && !entityID) { // Get
                    entity = [entityRef retain];
                } else {
                    NSLog(@"egwAssetManager: egwGAMXParseSound: Failure parsing in manifest input file '%s', for asset '%s': Sound asset '%@' does not exist.", resourceFile, entityID, entityRefIdent);
                }
                
                [entityRefIdent release]; entityRefIdent = nil;
                [entityRef release]; entityRef = nil;
            } else {
                NSLog(@"egwAssetManager: egwGAMXParseSound: Failure parsing in manifest input file '%s', for asset '%s': Sound node must contain an ID and/or reference an ID.", resourceFile, entityID);
            }
            
            if(entityID) { xmlFree(entityID); entityID = NULL; }
            if(entityRefID) { xmlFree(entityRefID); entityRefID = NULL; }
        } else {
            NSLog(@"egwAssetManager: egwGAMXParseSound: Failure parsing in manifest input file '%s', for asset '%s': Sound node type '%s' not supported.", resourceFile, entityID, entityNodeName);
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, entityNodeName);
    }
    
    return entity;
}

// Instantiation type and distinct parameter values for texture parsing
typedef struct {
    EGWint16 type; // invalid type = -1, static texture = 0
    EGWint16 srcType; // invalid type = -1, static surface = 0, static blank = 1
    union {
        struct { egwSurface surface; } srfc; // static surface = 0
        struct { EGWuint32 format; EGWuint16 dim[2]; } blnk; // static blank = 1
    } dist;
} egwGAMXTextureParams;

id<NSObject> egwGAMXParseTexture(const EGWchar* resourceFile, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* loadCounter, const xmlChar* entityNodeName) {
    id<NSObject> entity = nil;
    xmlChar* entityID = NULL;
    xmlChar* entityRefID = NULL;
    
    if(entityNodeName) {
        if(strcasecmp((const char*)entityNodeName, (const char*)"texture") == 0) {
            entityID = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"id");
            entityRefID = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"ref");
            
            if(entityID && !entityRefID) { // New
                xmlChar* entityNodeType = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"type");
                
                if((!entityNodeType || strcasecmp((const char*)entityNodeType, (const char*)"static") == 0) && !xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                    EGWint nodeType;
                    xmlChar* nodeName = NULL;
                    xmlChar* nodeValue = NULL;
                    egwGAMXTextureParams entityParams; memset((void*)&entityParams, 0, sizeof(egwGAMXTextureParams)); entityParams.type = entityParams.srcType = -1;
                    EGWuint entityTTrans = 0;
                    EGWuint entityTEnvironment = 0;
                    EGWuint entityTFilter = 0;
                    EGWuint16 entityTSWrap = 0;
                    EGWuint16 entityTTWrap = 0;
                    //egwMatrix44f entityBaseOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityBaseOffset);
                    //egwMatrix44f entityOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityOffset);
                    //egwMatrix44f entityOrient; egwMatCopy44f(&egwSIMatIdentity44f, &entityOrient);
                    //egwSinglyLinkedList entityPerforms; egwSLListInit(&entityPerforms, NULL, sizeof(egwGAMPostPerforms), EGW_LIST_FLG_DFLT);
                    
                    if(!entityNodeType || strcasecmp((const char*)entityNodeType, (const char*)"static") == 0)
                        entityParams.type = 0; // static texture
                    
                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                        
                        if(nodeType == 14) continue;
                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"surface") == 0 && !xmlTextReaderIsEmptyElement(xmlReadHandle) && entityParams.type == 0) {
                            xmlChar* entitySourceSrc = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"source");
                            
                            if(!entitySourceSrc || strcasecmp((const char*)entitySourceSrc, (const char*)"internal") == 0) {
                                xmlChar* entitySourceType = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"type");
                                
                                if(entitySourceType && strcasecmp((const char*)entitySourceType, (const char*)"non_palleted_pixels") == 0) {
                                    egwGAMXParseSurface_NPPA(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.srfc.surface, &entityTTrans);
                                    
                                    if(*retVal == 1) {
                                        if(entityParams.dist.srfc.surface.data)
                                            entityParams.srcType = 0; // static surface
                                    }
                                } else if(entitySourceType && strcasecmp((const char*)entitySourceType, (const char*)"blank") == 0) {
                                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                    
                                    // blank read
                                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                        
                                        if(nodeType == 14) continue;
                                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"surface") == 0) break;
                                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"format") == 0) {
                                            egwGAMXParseSurface_Format(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.blnk.format);
                                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"dimensions") == 0) {
                                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                                egwParseStringui16cv((EGWchar*)nodeValue, (EGWuint16*)&entityParams.dist.blnk.dim[0], 0, 2);
                                                if(entityParams.dist.blnk.dim[0] < 2) entityParams.dist.blnk.dim[0] = 2;
                                                if(entityParams.dist.blnk.dim[1] < 2) entityParams.dist.blnk.dim[1] = 2;
                                            }
                                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"dimensions");
                                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"transforms") == 0) {
                                            egwGAMXParseSurface_Transforms(resourceFile, entityID, xmlReadHandle, retVal, &entityTTrans);
                                        }
                                        
                                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    
                                    if(*retVal == 1) {
                                        entityParams.srcType = 1; // static blank
                                    }
                                } else NSLog(@"egwAssetManager: egwGAMXParseTexture: Failure parsing in manifest input file '%s', for asset '%s': Surface internal type '%s' not supported.", resourceFile, entityID, (entitySourceType ? (const char*)entitySourceType : (const char*)"<NULL>"));
                                
                                if(entitySourceType) { xmlFree(entitySourceType); entitySourceType = NULL; }
                            } else if(strcasecmp((const char*)entitySourceSrc, (const char*)"external") == 0) {
                                egwGAMXParseSurface_External(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.srfc.surface, &entityTTrans);
                                
                                if(*retVal == 1) {
                                    if(entityParams.dist.srfc.surface.data)
                                        entityParams.srcType = 0; // static surface
                                }
                            } else NSLog(@"egwAssetManager: egwGAMXParseTexture: Failure parsing in manifest input file '%s', for asset '%s': Surface source '%s' not supported.", resourceFile, entityID, (entitySourceSrc ? (const char*)entitySourceSrc : (const char*)"<NULL>"));
                            
                            if(entitySourceSrc) { xmlFree(entitySourceSrc); entitySourceSrc = NULL; }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"surface");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"environment") == 0) {
                            egwGAMXParseTexture_Environment(resourceFile, entityID, xmlReadHandle, retVal, &entityTEnvironment);
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"filter") == 0) {
                            egwGAMXParseTexture_Filter(resourceFile, entityID, xmlReadHandle, retVal, &entityTFilter);
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"swrap") == 0) {
                            egwGAMXParseTexture_Wrap(resourceFile, entityID, xmlReadHandle, retVal, &entityTSWrap);
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"twrap") == 0) {
                            egwGAMXParseTexture_Wrap(resourceFile, entityID, xmlReadHandle, retVal, &entityTTWrap);
                        } /*else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"base_offset") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityBaseOffset);
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"base_offset");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"offset") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityOffset);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetOffsetDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"offset");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"orient") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityOrient);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetOrientateDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"orient");
                        }*/
                        
                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                        if(*retVal != 1) break;
                    }
                    
                    if(*retVal == 1) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if((entityParams.srcType == 0 && // static surface
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwTexture alloc] initWithIdentity:entityIDIdent textureSurface:&entityParams.dist.srfc.surface textureEnvironment:entityTEnvironment texturingTransforms:entityTTrans texturingFilter:entityTFilter texturingSWrap:entityTSWrap texturingTWrap:entityTTWrap])]) ||
                           (entityParams.srcType == 1 && // static blank
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwTexture alloc] initBlankWithIdentity:entityIDIdent surfaceFormat:entityParams.dist.blnk.format textureWidth:entityParams.dist.blnk.dim[0] textureHeight:entityParams.dist.blnk.dim[1] textureEnvironment:entityTEnvironment texturingTransforms:entityTTrans texturingFilter:entityTFilter texturingSWrap:entityTSWrap texturingTWrap:entityTTWrap texturingOpacity:(entityParams.dist.blnk.format & EGW_SURFACE_FRMT_EXAC ? NO : YES)])])) {
                                //BOOL entityBaseWasAligned = NO;
                                //if(!egwMatIsEqual44f(&entityBaseOffset, &egwSIMatIdentity44f)) { [(egwTextureBase*)[(id<egwPTexture>)entity textureBase] baseOffsetByTransform:&entityBaseOffset]; entityBaseWasAligned = YES; }
                                //if(!egwMatIsEqual44f(&entityOffset, &egwSIMatIdentity44f)) [(id<egwPTexture>)entity offsetByTransform:&entityOffset];
                                //if(!egwMatIsEqual44f(&entityOrient, &egwSIMatIdentity44f) || entityBaseWasAligned) [(id<egwPTexture>)entity orientateByTransform:&entityOrient];
                                /*if(entityPerforms.eCount) {
                                    egwSinglyLinkedListIter iter;
                                    
                                    if(egwSLListEnumerateStart(&entityPerforms, EGW_ITERATE_MODE_DFLT, &iter)) {
                                        egwGAMPostPerforms* action;
                                        
                                        while((action = (egwGAMPostPerforms*)egwSLListEnumerateNextPtr(&iter))) {
                                            if(action->object1 && action->object2)
                                                [entity performSelector:action->method withObject:action->object1 withObject:action->object2];
                                            else if(action->object1)
                                                [entity performSelector:action->method withObject:action->object1];
                                            else
                                                [entity performSelector:action->method];
                                        }
                                    }
                                }*/
                                ++(*loadCounter);
                            } else
                                NSLog(@"egwAssetManager: egwGAMXParseTexture: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating texture asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    }
                    
                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                    if(entityParams.srcType == 0) egwSrfcFree(&entityParams.dist.srfc.surface);
                    //egwSLListFree(&entityPerforms);
                } else {
                    NSLog(@"egwAssetManager: egwGAMXParseTexture: Failure parsing in manifest input file '%s', for asset '%s': Texture node malformed or type attribute '%s' not supported.", resourceFile, entityID, (entityNodeType ? (const char*)entityNodeType : (const char*)"<NULL>"));
                }
                
                if(entityNodeType) { xmlFree(entityNodeType); entityNodeType = NULL; }
            } else if (entityRefID) { // !!!: Texture Copy/Get
                NSString* entityRefIdent = [[NSString alloc] initWithUTF8String:(const char*)entityRefID];
                id<NSObject> entityRef = (id<NSObject>)[[egwSIAsstMngr retrieveAsset:entityRefIdent] retain];
                
                if(entityRef && entityID) { // Copy
                    if([entityRef isKindOfClass:[egwTexture class]]) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwTexture alloc] initCopyOf:(id<egwPAsset>)entityRef withIdentity:entityIDIdent])])
                            ++(*loadCounter);
                        else
                            NSLog(@"egwAssetManager: egwGAMXParseTexture: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating static texture asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    } else {
                        NSLog(@"egwAssetManager: egwGAMXParseTexture: Failure parsing in manifest input file '%s', for asset '%s': Copying texture class type '%@' not supported.", resourceFile, entityID, [entityRef class]);
                    }
                    
                    if(entity) { // Shared unique properties (offset/orient/effects)
                        if(!xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                            EGWint nodeType;
                            xmlChar* nodeName = NULL;
                            xmlChar* nodeValue = NULL;
                            EGWuint entityTEnvironment = [(id<egwPTexture>)entityRef textureEnvironment];
                            egwMatrix44f entityOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityOffset);
                            egwMatrix44f entityOrient; egwMatCopy44f(&egwSIMatIdentity44f, &entityOrient);
                            
                            while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                
                                if(nodeType == 14) continue;
                                else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                                else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"environment") == 0) {
                                    egwGAMXParseTexture_Environment(resourceFile, entityID, xmlReadHandle, retVal, &entityTEnvironment);
                                } /*else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"offset") == 0) {
                                    while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                        if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                            egwGAMXParseTransform(xmlReadHandle, retVal, &entityOffset);
                                        else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                            id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                            if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                                [(id<egwPOrientated>)entity trySetOffsetDriver:(id<egwPInterpolator>)entityIPORef];
                                            }
                                            [entityIPORef release]; entityIPORef = nil;
                                        }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"offset");
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"orient") == 0) {
                                    while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                        if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                            egwGAMXParseTransform(xmlReadHandle, retVal, &entityOrient);
                                        else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                            id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                            if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                                [(id<egwPOrientated>)entity trySetOrientateDriver:(id<egwPInterpolator>)entityIPORef];
                                            }
                                            [entityIPORef release]; entityIPORef = nil;
                                        }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"orient");
                                }*/
                                
                                if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            
                            if(*retVal == 1) {
                                //if(!egwMatIsEqual44f(&entityOffset, &egwSIMatIdentity44f)) [(id<egwPTexture>)entity offsetByTransform:&entityOffset];
                                //if(!egwMatIsEqual44f(&entityOrient, &egwSIMatIdentity44f)) [(id<egwPTexture>)entity orientateByTransform:&entityOrient];
                                if(entityTEnvironment != [(id<egwPTexture>)entityRef textureEnvironment]) [(id<egwPTexture>)entity trySetTextureEnvironment:entityTEnvironment];
                            }
                            
                            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                        }
                    }
                } else if(entityRef && !entityID) { // Get
                    entity = [entityRef retain];
                } else {
                    NSLog(@"egwAssetManager: egwGAMXParseTexture: Failure parsing in manifest input file '%s', for asset '%s': Texture asset '%@' does not exist.", resourceFile, entityID, entityRefIdent);
                }
                
                [entityRefIdent release]; entityRefIdent = nil;
                [entityRef release]; entityRef = nil;
            } else {
                NSLog(@"egwAssetManager: egwGAMXParseTexture: Failure parsing in manifest input file '%s', for asset '%s': Texture node must contain an ID and/or reference an ID.", resourceFile, entityID);
            }
            
            if(entityID) { xmlFree(entityID); entityID = NULL; }
            if(entityRefID) { xmlFree(entityRefID); entityRefID = NULL; }
        } else {
            NSLog(@"egwAssetManager: egwGAMXParseTexture: Failure parsing in manifest input file '%s', for asset '%s': Texture node type '%s' not supported.", resourceFile, entityID, entityNodeName);
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, entityNodeName);
    }
    
    return entity;
}

// Instantiation type and distinct parameter values for widget parsing
typedef struct {
    EGWint16 type; // invalid type = -1, image widget = 0, button widget = 1, toggle widget = 2, pager widget = 3, slider widget = 4, label widget = 5, sprited image widget = 6
    EGWint16 srcType; // invalid type = -1, image surface = 0, image blank = 1, button surface = 2, button blank = 3, toggle surface = 4, toggle blank = 5, pager surface = 6, pager blank = 7, slider surface = 8, slider blank = 9, label = 10, sprited image surface framings = 11, sprited image blank = 12
    union {
        struct { egwSurface surface; EGWuint16 dim[2]; } srfc; // image surface = 0, button surface = 2, toggle surface = 4
        struct { EGWuint32 format; EGWuint16 dim[2]; } blnk; // image blank = 1, button blank = 3, toggle blank = 5
        struct { egwSurface surface; EGWuint16 dim[2]; EGWuint pages; } pgr; // pager surface = 6
        struct { EGWuint32 format; EGWuint16 dim[2]; EGWuint pages; } pgrblnk; // pager blank = 7
        struct { egwSurface surface; EGWuint16 tDim[2]; EGWuint16 bDim[2]; } sldr; // slider surface = 8
        struct { EGWuint32 format; EGWuint16 tDim[2]; EGWuint16 bDim[2]; } sldrblnk; // slider blank = 9
        struct { EGWuint32 format; NSString* text; id<egwPFont> font; } lbl; // label = 10
        struct { egwSurface* surfaces; egwSurfaceFraming* framings; EGWuint16 dim[2]; EGWuint sCount; EGWsingle fps; id<egwPTimer> scntrl; } sprtdimg; // sprited image surface framings = 11
        struct { EGWuint32 format; EGWuint16 dim[2]; EGWuint fCount; EGWsingle fps; id<egwPTimer> scntrl; } sprtdimgblnk; // sprited image blank = 12
    } dist;
} egwGAMXWidgetParams;

id<NSObject> egwGAMXParseWidget(const EGWchar* resourceFile, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* loadCounter, const xmlChar* entityNodeName) {
    id<NSObject> entity = nil;
    xmlChar* entityID = NULL;
    xmlChar* entityRefID = NULL;
    
    if(entityNodeName) {
        if(strcasecmp((const char*)entityNodeName, (const char*)"widget") == 0) {
            entityID = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"id");
            entityRefID = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"ref");
            
            if(entityID && !entityRefID) { // New
                xmlChar* entityNodeType = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"type");
                
                if((!entityNodeType || (strcasecmp((const char*)entityNodeType, (const char*)"image") == 0 || strcasecmp((const char*)entityNodeType, (const char*)"button") == 0 || strcasecmp((const char*)entityNodeType, (const char*)"toggle") == 0 || strcasecmp((const char*)entityNodeType, (const char*)"pager") == 0 || strcasecmp((const char*)entityNodeType, (const char*)"slider") == 0 || strcasecmp((const char*)entityNodeType, (const char*)"label") == 0) || strcasecmp((const char*)entityNodeType, (const char*)"sprited_image") == 0) && !xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                    EGWint nodeType;
                    xmlChar* nodeName = NULL;
                    xmlChar* nodeValue = NULL;
                    egwGAMXWidgetParams entityParams; memset((void*)&entityParams, 0, sizeof(egwGAMXWidgetParams)); entityParams.type = entityParams.srcType = -1;
                    EGWuint entityGStorage = 0;
                    EGWuint entityBGStorage = 0;
                    EGWuint entityTTrans = 0;
                    EGWuint entityTEnvironment = 0;
                    EGWuint entityTFilter = 0;
                    EGWuint entityRFlags = 0;
                    egwMaterialStack* entityMStack = nil;
                    egwMatrix44f entityBaseOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityBaseOffset);
                    EGWuint entityBaseZFAlign = 0;
                    egwMatrix44f entityOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityOffset);
                    egwMatrix44f entityOrient; egwMatCopy44f(&egwSIMatIdentity44f, &entityOrient);
                    egwSinglyLinkedList entityPerforms; egwSLListInit(&entityPerforms, NULL, sizeof(egwGAMPostPerforms), EGW_LIST_FLG_DFLT);
                    
                    if(!entityNodeType || strcasecmp((const char*)entityNodeType, (const char*)"image") == 0)
                        entityParams.type = 0; // image widget
                    else if(strcasecmp((const char*)entityNodeType, (const char*)"button") == 0)
                        entityParams.type = 1; // button widget
                    else if(strcasecmp((const char*)entityNodeType, (const char*)"toggle") == 0)
                        entityParams.type = 2; // toggle widget
                    else if(strcasecmp((const char*)entityNodeType, (const char*)"pager") == 0)
                        entityParams.type = 3; // pager widget
                    else if(strcasecmp((const char*)entityNodeType, (const char*)"slider") == 0)
                        entityParams.type = 4; // slider widget
                    else if(strcasecmp((const char*)entityNodeType, (const char*)"label") == 0)
                        entityParams.type = 5; // label widget
                    else if(strcasecmp((const char*)entityNodeType, (const char*)"sprited_image") == 0)
                        entityParams.type = 6; // sprited image widget
                    
                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                        
                        if(nodeType == 14) continue;
                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"surface") == 0 && !xmlTextReaderIsEmptyElement(xmlReadHandle) && (entityParams.type == 0 || entityParams.type == 1 || entityParams.type == 2 || entityParams.type == 3 || entityParams.type == 4)) {
                            xmlChar* entitySourceSrc = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"source");
                            
                            if(!entitySourceSrc || strcasecmp((const char*)entitySourceSrc, (const char*)"internal") == 0) {
                                xmlChar* entitySourceType = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"type");
                                
                                if(entitySourceType && strcasecmp((const char*)entitySourceType, (const char*)"non_palleted_pixels") == 0) {
                                    egwGAMXParseSurface_NPPA(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.srfc.surface, &entityTTrans);
                                    
                                    if(*retVal == 1) {
                                        if(entityParams.dist.srfc.surface.data) {
                                            if(entityParams.type == 0)
                                                entityParams.srcType = 0; // image surface
                                            else if(entityParams.type == 1)
                                                entityParams.srcType = 2; // button surface
                                            else if(entityParams.type == 2)
                                                entityParams.srcType = 4; // toggle surface
                                            else if(entityParams.type == 3)
                                                entityParams.srcType = 6; // pager surface
                                            else if(entityParams.type == 4)
                                                entityParams.srcType = 8; // slider surface
                                        }
                                    }
                                } else if(entitySourceType && strcasecmp((const char*)entitySourceType, (const char*)"blank") == 0) {
                                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                    
                                    // blank read
                                    while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                        
                                        if(nodeType == 14) continue;
                                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"surface") == 0) break;
                                        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"format") == 0) {
                                            egwGAMXParseSurface_Format(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.blnk.format);
                                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"transforms") == 0) {
                                            egwGAMXParseSurface_Transforms(resourceFile, entityID, xmlReadHandle, retVal, &entityTTrans);
                                        }
                                        
                                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    
                                    if(*retVal == 1) {
                                        if(entityParams.type == 0)
                                            entityParams.srcType = 1; // image blank
                                        else if(entityParams.type == 1)
                                            entityParams.srcType = 3; // button blank
                                        else if(entityParams.type == 2)
                                            entityParams.srcType = 4; // toggle blank
                                        else if(entityParams.type == 3)
                                            entityParams.srcType = 7; // pager blank
                                        else if(entityParams.type == 4)
                                            entityParams.srcType = 9; // slider blank
                                    }
                                } else NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Surface internal type '%s' not supported.", resourceFile, entityID, (entitySourceType ? (const char*)entitySourceType : (const char*)"<NULL>"));
                                
                                if(entitySourceType) { xmlFree(entitySourceType); entitySourceType = NULL; }
                            } else if(strcasecmp((const char*)entitySourceSrc, (const char*)"external") == 0) {
                                egwGAMXParseSurface_External(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.srfc.surface, &entityTTrans);
                                
                                if(*retVal == 1) {
                                    if(entityParams.dist.srfc.surface.data) {
                                        if(entityParams.type == 0)
                                            entityParams.srcType = 0; // image surface
                                        else if(entityParams.type == 1)
                                            entityParams.srcType = 2; // button surface
                                        else if(entityParams.type == 2)
                                            entityParams.srcType = 4; // toggle surface
                                        else if(entityParams.type == 3)
                                            entityParams.srcType = 6; // pager surface
                                        else if(entityParams.type == 4)
                                            entityParams.srcType = 8; // slider surface
                                    }
                                }
                            } else NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Surface source '%s' not supported.", resourceFile, entityID, (entitySourceSrc ? (const char*)entitySourceSrc : (const char*)"<NULL>"));
                            
                            if(entitySourceSrc) { xmlFree(entitySourceSrc); entitySourceSrc = NULL; }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"surface");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"surface") == 0 && !xmlTextReaderIsEmptyElement(xmlReadHandle) && entityParams.type == 5) {
                            xmlChar* entitySourceType = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"type");
                            
                            if(!entitySourceType || strcasecmp((const char*)entitySourceType, (const char*)"auto") == 0) {
                                if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                
                                // auto read
                                while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                    
                                    if(nodeType == 14) continue;
                                    else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"surface") == 0) break;
                                    else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"format") == 0) {
                                        egwGAMXParseSurface_Format(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.lbl.format);
                                    } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"transforms") == 0) {
                                        egwGAMXParseSurface_Transforms(resourceFile, entityID, xmlReadHandle, retVal, &entityTTrans);
                                    }
                                    
                                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                    if(*retVal != 1) break;
                                }
                                
                                if(*retVal == 1) {
                                    entityParams.srcType = 10; // label
                                }
                            } else NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Surface internal type '%s' not supported.", resourceFile, entityID, (entitySourceType ? (const char*)entitySourceType : (const char*)"<NULL>"));
                            
                            if(entitySourceType) { xmlFree(entitySourceType); entitySourceType = NULL; }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"surface");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"sprites") == 0 && !xmlTextReaderIsEmptyElement(xmlReadHandle) && entityParams.type == 6) {
                            xmlChar* entitySourceType = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"type");
                            
                            if(entitySourceType && strcasecmp((const char*)entitySourceType, (const char*)"surface_framings") == 0) {
                                xmlChar* entitySCount = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"count");
                                
                                if(entitySCount && egwParseStringuicv((EGWchar*)entitySCount, (EGWuint*)&entityParams.dist.sprtdimg.sCount, 0, 1) == 1) {
                                    entityParams.dist.sprtdimg.sCount = egwClampui(entityParams.dist.sprtdimg.sCount, 1, EGW_UINT16_MAX);
                                    
                                    if((entityParams.dist.sprtdimg.surfaces = (egwSurface*)malloc((size_t)entityParams.dist.sprtdimg.sCount * sizeof(egwSurface))) &&
                                       (entityParams.dist.sprtdimg.framings = (egwSurfaceFraming*)malloc((size_t)entityParams.dist.sprtdimg.sCount * sizeof(egwSurfaceFraming)))) {
                                        EGWuint framesProcessed = 0;
                                        
                                        memset((void*)entityParams.dist.sprtdimg.surfaces, 0, (size_t)entityParams.dist.sprtdimg.sCount * sizeof(egwSurface));
                                        memset((void*)entityParams.dist.sprtdimg.framings, 0, (size_t)entityParams.dist.sprtdimg.sCount * sizeof(egwSurfaceFraming));
                                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                        
                                        // surface framings read
                                        while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                            nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                            
                                            if(nodeType == 14) continue;
                                            else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"sprites") == 0) break;
                                            else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"frame") == 0) {
                                                if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                                
                                                // frame read
                                                while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                                    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                                    
                                                    if(nodeType == 14) continue;
                                                    else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"frame") == 0) break;
                                                    else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"surface") == 0) {
                                                        xmlChar* entitySourceSrc = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"source");
                                                        
                                                        if(!entitySourceSrc || strcasecmp((const char*)entitySourceSrc, (const char*)"internal") == 0) {
                                                            xmlChar* entitySourceType = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"type");
                                                            
                                                            if(entitySourceType && strcasecmp((const char*)entitySourceType, (const char*)"non_palleted_pixels") == 0) {
                                                                EGWuint discardedTrans = entityTTrans;
                                                                egwGAMXParseSurface_NPPA(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.sprtdimg.surfaces[framesProcessed], &discardedTrans);
                                                            } else NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Surface frame %d internal type '%s' not supported.", resourceFile, entityID, framesProcessed+1, (entitySourceType ? (const char*)entitySourceType : (const char*)"<NULL>"));
                                                            
                                                            if(entitySourceType) { xmlFree(entitySourceType); entitySourceType = NULL; }
                                                        } else if(strcasecmp((const char*)entitySourceSrc, (const char*)"external") == 0) {
                                                            EGWuint discardedTrans = entityTTrans;
                                                            egwGAMXParseSurface_External(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.sprtdimg.surfaces[framesProcessed], &discardedTrans);
                                                        } else NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Surface frame %d source '%s' not supported.", resourceFile, entityID, framesProcessed+1, (entitySourceSrc ? (const char*)entitySourceSrc : (const char*)"<NULL>"));
                                                        
                                                        if(entitySourceSrc) { xmlFree(entitySourceSrc); entitySourceSrc = NULL; }
                                                        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"surface");
                                                    } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"framing") == 0) {
                                                        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                                            xmlChar* entityDims = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                                                            EGWuint16 dim[2];
                                                            egwParseStringui16cv((EGWchar*)entityDims, (EGWuint16*)&dim[0], 0, 2);
                                                            entityParams.dist.sprtdimg.framings[framesProcessed].hFrames = (dim[0] > 1 ? dim[0] : 1);
                                                            entityParams.dist.sprtdimg.framings[framesProcessed].vFrames = (dim[1] > 1 ? dim[1] : 1);
                                                        }
                                                        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"framing");
                                                    }
                                                    
                                                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                                    if(*retVal != 1) break;
                                                }
                                                
                                                if(*retVal == 1)
                                                    ++framesProcessed;
                                                
                                                egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"frame");
                                            } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"transforms") == 0) {
                                                egwGAMXParseSurface_Transforms(resourceFile, entityID, xmlReadHandle, retVal, &entityTTrans);
                                            }
                                            
                                            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                            if(*retVal != 1) break;
                                        }
                                        
                                        if(*retVal == 1) {
                                            if(entityParams.dist.sprtdimg.surfaces && entityParams.dist.sprtdimg.framings) {
                                                EGWuint sIndex = 0;
                                                for(; sIndex < entityParams.dist.sprtdimg.sCount; ++sIndex) {
                                                    if(!entityParams.dist.sprtdimg.surfaces[sIndex].data)
                                                        break;
                                                }
                                                if(sIndex == entityParams.dist.sprtdimg.sCount)
                                                    entityParams.srcType = 11; // sprited image surface framings
                                            }
                                        }
                                    } else {
                                        NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating %d bytes for framing structures.", resourceFile, entityID, (size_t)entityParams.dist.sprtdimg.sCount * (sizeof(egwSurface) + sizeof(egwSurfaceFraming)));
                                        if(entityParams.dist.sprtdimg.surfaces) { free((void*)entityParams.dist.sprtdimg.surfaces); entityParams.dist.sprtdimg.surfaces = NULL; }
                                        if(entityParams.dist.sprtdimg.framings) { free((void*)entityParams.dist.sprtdimg.framings); entityParams.dist.sprtdimg.framings = NULL; }
                                    }
                                } else NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Surfaces count not specified.", resourceFile, entityID);
                                
                                if(entitySCount) { xmlFree(entitySCount); entitySCount = NULL; }
                            } else if(entitySourceType && strcasecmp((const char*)entitySourceType, (const char*)"blank") == 0) {
                                if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                
                                // blank read
                                while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                    nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                    
                                    if(nodeType == 14) continue;
                                    else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"sprites") == 0) break;
                                    else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"format") == 0) {
                                        egwGAMXParseSurface_Format(resourceFile, entityID, xmlReadHandle, retVal, &entityParams.dist.sprtdimgblnk.format);
                                    } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"frames") == 0) {
                                        if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                            egwParseStringuicv((EGWchar*)nodeValue, (EGWuint*)&entityParams.dist.sprtdimgblnk.fCount, 0, 1);
                                        }
                                        egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"frames");
                                    } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"transforms") == 0) {
                                        egwGAMXParseSurface_Transforms(resourceFile, entityID, xmlReadHandle, retVal, &entityTTrans);
                                    }
                                    
                                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                    if(*retVal != 1) break;
                                }
                                
                                if(*retVal == 1) {
                                    entityParams.srcType = 12; // sprited image blank
                                }
                            } else NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Surface internal type '%s' not supported.", resourceFile, entityID, (entitySourceType ? (const char*)entitySourceType : (const char*)"<NULL>"));
                            
                            if(entitySourceType) { xmlFree(entitySourceType); entitySourceType = NULL; }                            
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"sprites");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"dimensions") == 0 && (entityParams.type == 0 || entityParams.type == 1 || entityParams.type == 2 || entityParams.type == 3)) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                xmlChar* entityDims = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                                if(entityParams.srcType % 2 == 0) {
                                    egwParseStringui16cv((EGWchar*)entityDims, &entityParams.dist.srfc.dim[0], 0, 2);
                                    if(entityParams.dist.srfc.dim[0] < 1) entityParams.dist.srfc.dim[0] = 1;
                                    if(entityParams.dist.srfc.dim[1] < 1) entityParams.dist.srfc.dim[1] = 1;
                                } else {
                                    egwParseStringui16cv((EGWchar*)entityDims, &entityParams.dist.blnk.dim[0], 0, 2);
                                    if(entityParams.dist.blnk.dim[0] < 1) entityParams.dist.blnk.dim[0] = 1;
                                    if(entityParams.dist.blnk.dim[1] < 1) entityParams.dist.blnk.dim[1] = 1;
                                }
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"dimensions");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"dimensions") == 0 && entityParams.type == 6) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                xmlChar* entityDims = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                                if(entityParams.srcType == 11) {
                                    egwParseStringui16cv((EGWchar*)entityDims, &entityParams.dist.sprtdimg.dim[0], 0, 2);
                                    if(entityParams.dist.sprtdimg.dim[0] < 1) entityParams.dist.sprtdimg.dim[0] = 1;
                                    if(entityParams.dist.sprtdimg.dim[1] < 1) entityParams.dist.sprtdimg.dim[1] = 1;
                                } else {
                                    egwParseStringui16cv((EGWchar*)entityDims, &entityParams.dist.sprtdimgblnk.dim[0], 0, 2);
                                    if(entityParams.dist.sprtdimgblnk.dim[0] < 1) entityParams.dist.sprtdimgblnk.dim[0] = 1;
                                    if(entityParams.dist.sprtdimgblnk.dim[1] < 1) entityParams.dist.sprtdimgblnk.dim[1] = 1;
                                }
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"dimensions");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"track_dimensions") == 0 && entityParams.type == 4) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                xmlChar* entityDims = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                                if(entityParams.srcType == 8) {
                                    egwParseStringui16cv((EGWchar*)entityDims, &entityParams.dist.sldr.tDim[0], 0, 2);
                                    if(entityParams.dist.sldr.tDim[0] < 1) entityParams.dist.sldr.tDim[0] = 1;
                                    if(entityParams.dist.sldr.tDim[1] < 1) entityParams.dist.sldr.tDim[1] = 1;
                                } else {
                                    egwParseStringui16cv((EGWchar*)entityDims, &entityParams.dist.sldrblnk.tDim[0], 0, 2);
                                    if(entityParams.dist.sldrblnk.tDim[0] < 1) entityParams.dist.sldrblnk.tDim[0] = 1;
                                    if(entityParams.dist.sldrblnk.tDim[1] < 1) entityParams.dist.sldrblnk.tDim[1] = 1;
                                }
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"track_dimensions");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"button_dimensions") == 0 && entityParams.type == 4) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                xmlChar* entityDims = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                                if(entityParams.srcType == 8) {
                                    egwParseStringui16cv((EGWchar*)entityDims, &entityParams.dist.sldr.bDim[0], 0, 2);
                                    if(entityParams.dist.sldr.bDim[0] < 1) entityParams.dist.sldr.bDim[0] = 1;
                                    if(entityParams.dist.sldr.bDim[1] < 1) entityParams.dist.sldr.bDim[1] = 1;
                                } else {
                                    egwParseStringui16cv((EGWchar*)entityDims, &entityParams.dist.sldrblnk.bDim[0], 0, 2);
                                    if(entityParams.dist.sldrblnk.bDim[0] < 1) entityParams.dist.sldrblnk.bDim[0] = 1;
                                    if(entityParams.dist.sldrblnk.bDim[1] < 1) entityParams.dist.sldrblnk.bDim[1] = 1;
                                }
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"button_dimensions");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"pages") == 0 && entityParams.type == 3) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                xmlChar* entityPages = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                                egwParseStringuicv((EGWchar*)entityPages, &entityParams.dist.pgr.pages, 0, 1);
                                if(entityParams.dist.pgr.pages < 1) entityParams.dist.pgr.pages = 1;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"pages");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"typeface") == 0 && entityParams.type == 5) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                id<NSObject> entityFRef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                if(entityFRef && [entityFRef conformsToProtocol:@protocol(egwPFont)]) {
                                    [entityParams.dist.lbl.font release]; entityParams.dist.lbl.font = nil;
                                    entityParams.dist.lbl.font = (id<egwPFont>)[entityFRef retain];
                                } else {
                                    NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Typeface font type '%s' not supported.", resourceFile, entityID, nodeValue);
                                    egwGAMXParseSkip(xmlReadHandle, retVal, nodeValue);
                                }
                                [entityFRef release]; entityFRef = nil;
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"typeface");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"text") == 0 && entityParams.type == 5) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                [entityParams.dist.lbl.text release]; entityParams.dist.lbl.text = nil;
                                entityParams.dist.lbl.text = [[NSString alloc] initWithUTF8String:(const char*)egwQTrimc((EGWchar*)nodeValue, -1)];
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"text");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"fps") == 0 && entityParams.type == 6) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                xmlChar* entityPages = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                                if(entityParams.srcType == 11) {
                                    egwParseStringfcv((EGWchar*)entityPages, &entityParams.dist.sprtdimg.fps, 0, 1);
                                    entityParams.dist.sprtdimg.fps = egwClampPosf(entityParams.dist.sprtdimg.fps);
                                } else {
                                    egwParseStringfcv((EGWchar*)entityPages, &entityParams.dist.sprtdimgblnk.fps, 0, 1);
                                    entityParams.dist.sprtdimgblnk.fps = egwClampPosf(entityParams.dist.sprtdimgblnk.fps);
                                }
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"fps");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"controller") == 0 && entityParams.type == 6) {
                            if(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                id<NSObject> entityTRef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                if(entityTRef && [entityTRef conformsToProtocol:@protocol(egwPTimer)]) {
                                    if(entityParams.srcType == 11) {
                                        [entityParams.dist.sprtdimg.scntrl release]; entityParams.dist.sprtdimg.scntrl = nil;
                                        entityParams.dist.sprtdimg.scntrl = (id<egwPTimer>)[entityTRef retain];
                                    } else {
                                        [entityParams.dist.sprtdimgblnk.scntrl release]; entityParams.dist.sprtdimgblnk.scntrl = nil;
                                        entityParams.dist.sprtdimgblnk.scntrl = (id<egwPTimer>)[entityTRef retain];
                                    }
                                } else {
                                    NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Controller timer type '%s' not supported.", resourceFile, entityID, nodeValue);
                                    egwGAMXParseSkip(xmlReadHandle, retVal, nodeValue);
                                }
                                [entityTRef release]; entityTRef = nil;
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"controller");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"storage") == 0) {
                            egwGAMXParseGeometry_Storage(resourceFile, entityID, xmlReadHandle, retVal, &entityGStorage);
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"base_storage") == 0 && entityParams.type != 0 && entityParams.type != 5) {
                            egwGAMXParseGeometry_Storage(resourceFile, entityID, xmlReadHandle, retVal, &entityBGStorage);
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"environment") == 0) {
                            egwGAMXParseTexture_Environment(resourceFile, entityID, xmlReadHandle, retVal, &entityTEnvironment);
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"filter") == 0) {
                            egwGAMXParseTexture_Filter(resourceFile, entityID, xmlReadHandle, retVal, &entityTFilter);
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"materials") == 0) {
                            if(!entityMStack && !(entityMStack = [[egwMaterialStack alloc] init]))
                                NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating a material stack.", resourceFile, entityID, nodeValue);
                            else {
                                while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                    id<NSObject> entityRef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityRef && [entityRef conformsToProtocol:@protocol(egwPMaterial)]) {
                                        [entityMStack addMaterial:(id<egwPMaterial>)entityRef];
                                    } else {
                                        NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Material stack node type '%s' not supported.", resourceFile, entityID, nodeValue);
                                        egwGAMXParseSkip(xmlReadHandle, retVal, nodeValue);
                                    }
                                    [entityRef release]; entityRef = nil;
                                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                    if(*retVal != 1) break;
                                }
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"materials");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"render_flags") == 0) {
                            egwGAMXParseFlags_Render(resourceFile, entityID, xmlReadHandle, retVal, &entityRFlags);
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"base_offset") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityBaseOffset);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"zfalign") == 0)
                                    egwGAMXParseZFAlign(resourceFile, entityID, xmlReadHandle, retVal, &entityBaseZFAlign);
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"base_offset");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"offset") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityOffset);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetOffsetDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"offset");
                        } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"orient") == 0) {
                            while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                    egwGAMXParseTransform(xmlReadHandle, retVal, &entityOrient);
                                else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                    id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                    if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                        egwGAMPostPerforms action; memset((void*)&action, 0, sizeof(egwGAMPostPerforms));
                                        action.object1 = (id<egwPInterpolator>)entityIPORef;
                                        action.method = @selector(trySetOrientateDriver:);
                                        egwSLListAddTail(&entityPerforms, (const EGWbyte*)&action);
                                    }
                                    [entityIPORef release]; entityIPORef = nil;
                                }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"orient");
                        }
                        
                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                        if(*retVal != 1) break;
                    }
                    
                    if(*retVal == 1) {
                        // Do framings calculations/corrections for sprited image surface
                        if(entityParams.srcType == 11) {
                            EGWuint16 frameCount = 0;
                            for(EGWuint sIndex = 0; sIndex < entityParams.dist.sprtdimg.sCount; ++sIndex) {
                                if(!entityParams.dist.sprtdimg.framings[sIndex].hFrames)
                                    entityParams.dist.sprtdimg.framings[sIndex].hFrames = entityParams.dist.sprtdimg.surfaces[sIndex].size.span.width / entityParams.dist.sprtdimg.dim[0];
                                if(!entityParams.dist.sprtdimg.framings[sIndex].vFrames)
                                    entityParams.dist.sprtdimg.framings[sIndex].vFrames = entityParams.dist.sprtdimg.surfaces[sIndex].size.span.height / entityParams.dist.sprtdimg.dim[1];
                                entityParams.dist.sprtdimg.framings[sIndex].fOffset = frameCount;
                                entityParams.dist.sprtdimg.framings[sIndex].fCount = entityParams.dist.sprtdimg.framings[sIndex].hFrames * entityParams.dist.sprtdimg.framings[sIndex].vFrames;
                                frameCount += entityParams.dist.sprtdimg.framings[sIndex].fCount;
                                entityParams.dist.sprtdimg.framings[sIndex].htSizer = (EGWdouble)((EGWuint)entityParams.dist.sprtdimg.dim[0] * (EGWuint)entityParams.dist.sprtdimg.framings[sIndex].hFrames) / (EGWdouble)entityParams.dist.sprtdimg.surfaces[sIndex].size.span.width / (EGWdouble)entityParams.dist.sprtdimg.framings[sIndex].hFrames;
                                entityParams.dist.sprtdimg.framings[sIndex].vtSizer = (EGWdouble)((EGWuint)entityParams.dist.sprtdimg.dim[1] * (EGWuint)entityParams.dist.sprtdimg.framings[sIndex].vFrames) / (EGWdouble)entityParams.dist.sprtdimg.surfaces[sIndex].size.span.height / (EGWdouble)entityParams.dist.sprtdimg.framings[sIndex].vFrames;
                            }
                        }
                        
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if((entityParams.srcType == 0 && // image surface
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwImage alloc] initWithIdentity:entityIDIdent imageSurface:&entityParams.dist.srfc.surface imageWidth:entityParams.dist.srfc.dim[0] imageHeight:entityParams.dist.srfc.dim[1] geometryStorage:entityGStorage textureEnvironment:entityTEnvironment texturingTransforms:entityTTrans texturingFilter:entityTFilter lightStack:nil materialStack:entityMStack])]) ||
                           (entityParams.srcType == 1 && // image blank
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwImage alloc] initBlankWithIdentity:entityIDIdent surfaceFormat:entityParams.dist.blnk.format imageWidth:entityParams.dist.blnk.dim[0] imageHeight:entityParams.dist.blnk.dim[1] geometryStorage:entityGStorage textureEnvironment:entityTEnvironment texturingTransforms:entityTTrans texturingFilter:entityTFilter lightStack:nil materialStack:entityMStack])]) ||
                           (entityParams.srcType == 2 && // button surface
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwButton alloc] initWithIdentity:entityIDIdent buttonSurface:&entityParams.dist.srfc.surface buttonWidth:entityParams.dist.srfc.dim[0] buttonHeight:entityParams.dist.srfc.dim[1] instanceGeometryStorage:entityGStorage baseGeometryStorage:entityBGStorage textureEnvironment:entityTEnvironment texturingTransforms:entityTTrans texturingFilter:entityTFilter lightStack:nil materialStack:entityMStack])]) ||
                           (entityParams.srcType == 3 && // button blank
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwButton alloc] initBlankWithIdentity:entityIDIdent surfaceFormat:entityParams.dist.blnk.format buttonWidth:entityParams.dist.blnk.dim[0] buttonHeight:entityParams.dist.blnk.dim[1] instanceGeometryStorage:entityGStorage baseGeometryStorage:entityBGStorage textureEnvironment:entityTEnvironment texturingTransforms:entityTTrans texturingFilter:entityTFilter lightStack:nil materialStack:entityMStack])]) ||
                           (entityParams.srcType == 4 && // toggle surface
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwToggle alloc] initWithIdentity:entityIDIdent toggleSurface:&entityParams.dist.srfc.surface toggleWidth:entityParams.dist.srfc.dim[0] toggleHeight:entityParams.dist.srfc.dim[1] instanceGeometryStorage:entityGStorage baseGeometryStorage:entityBGStorage textureEnvironment:entityTEnvironment texturingTransforms:entityTTrans texturingFilter:entityTFilter lightStack:nil materialStack:entityMStack])]) ||
                           (entityParams.srcType == 5 && // toggle blank
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwToggle alloc] initBlankWithIdentity:entityIDIdent surfaceFormat:entityParams.dist.blnk.format toggleWidth:entityParams.dist.blnk.dim[0] toggleHeight:entityParams.dist.blnk.dim[1] instanceGeometryStorage:entityGStorage baseGeometryStorage:entityBGStorage textureEnvironment:entityTEnvironment texturingTransforms:entityTTrans texturingFilter:entityTFilter lightStack:nil materialStack:entityMStack])]) ||
                           (entityParams.srcType == 6 && // pager surface
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwPager alloc] initWithIdentity:entityIDIdent pagerSurface:&entityParams.dist.pgr.surface pagerWidth:entityParams.dist.pgr.dim[0] pagerHeight:entityParams.dist.pgr.dim[1] totalPages:entityParams.dist.pgr.pages instanceGeometryStorage:entityGStorage baseGeometryStorage:entityBGStorage textureEnvironment:entityTEnvironment texturingTransforms:entityTTrans texturingFilter:entityTFilter lightStack:nil materialStack:entityMStack])]) ||
                           (entityParams.srcType == 7 && // pager blank
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwPager alloc] initBlankWithIdentity:entityIDIdent surfaceFormat:entityParams.dist.pgrblnk.format pagerWidth:entityParams.dist.pgrblnk.dim[0] pagerHeight:entityParams.dist.pgrblnk.dim[1] totalPages:entityParams.dist.pgrblnk.pages instanceGeometryStorage:entityGStorage baseGeometryStorage:entityBGStorage textureEnvironment:entityTEnvironment texturingTransforms:entityTTrans texturingFilter:entityTFilter lightStack:nil materialStack:entityMStack])]) ||
                           (entityParams.srcType == 8 && // slider surface
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwSlider alloc] initWithIdentity:entityIDIdent sliderSurface:&entityParams.dist.sldr.surface sliderTrackWidth:entityParams.dist.sldr.tDim[0] sliderTrackHeight:entityParams.dist.sldr.tDim[1] sliderButtonWidth:entityParams.dist.sldr.bDim[0] sliderButtonHeight:entityParams.dist.sldr.bDim[1] instanceGeometryStorage:entityGStorage baseGeometryStorage:entityBGStorage textureEnvironment:entityTEnvironment texturingTransforms:entityTTrans texturingFilter:entityTFilter lightStack:nil materialStack:entityMStack])]) ||
                           (entityParams.srcType == 9 && // slider blank
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwSlider alloc] initBlankWithIdentity:entityIDIdent surfaceFormat:entityParams.dist.sldrblnk.format sliderTrackWidth:entityParams.dist.sldrblnk.tDim[0] sliderTrackHeight:entityParams.dist.sldrblnk.tDim[1] sliderButtonWidth:entityParams.dist.sldrblnk.bDim[0] sliderButtonHeight:entityParams.dist.sldrblnk.bDim[1] instanceGeometryStorage:entityGStorage baseGeometryStorage:entityBGStorage textureEnvironment:entityTEnvironment texturingTransforms:entityTTrans texturingFilter:entityTFilter lightStack:nil materialStack:entityMStack])]) ||
                           (entityParams.srcType == 10 && // label
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwLabel alloc] initWithIdentity:entityIDIdent surfaceFormat:entityParams.dist.lbl.format labelText:entityParams.dist.lbl.text renderingFont:entityParams.dist.lbl.font geometryStorage:entityGStorage textureEnvironment:entityTEnvironment texturingTransforms:entityTTrans texturingFilter:entityTFilter lightStack:nil materialStack:entityMStack])]) ||
                           (entityParams.srcType == 11 && // sprited image surfaces
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwSpritedImage alloc] initWithIdentity:entityIDIdent spriteSurfaces:entityParams.dist.sprtdimg.surfaces surfaceFramings:entityParams.dist.sprtdimg.framings surfaceCount:entityParams.dist.sprtdimg.sCount spriteWidth:entityParams.dist.sprtdimg.dim[0] spriteHeight:entityParams.dist.sprtdimg.dim[1] spriteFPS:entityParams.dist.sprtdimg.fps instanceGeometryStorage:entityGStorage baseGeometryStorage:entityBGStorage textureEnvironment:entityTEnvironment texturingTransforms:entityTTrans texturingFilter:entityTFilter lightStack:nil materialStack:entityMStack])]) ||
                           (entityParams.srcType == 12 && // sprited image blank
                            [egwSIAsstMngr loadAsset:entityIDIdent
                                        fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwSpritedImage alloc] initBlankWithIdentity:entityIDIdent surfaceFormat:entityParams.dist.sprtdimgblnk.format spriteWidth:entityParams.dist.sprtdimgblnk.dim[0] spriteHeight:entityParams.dist.sprtdimgblnk.dim[1] frameCount:entityParams.dist.sprtdimgblnk.fCount spriteFPS:entityParams.dist.sprtdimgblnk.fps instanceGeometryStorage:entityGStorage baseGeometryStorage:entityBGStorage textureEnvironment:entityTEnvironment texturingTransforms:entityTTrans texturingFilter:entityTFilter lightStack:nil materialStack:entityMStack])])) {
                            BOOL entityBaseWasAligned = NO;
                            if(entityBaseZFAlign != 0) { [(egwImageBase*)[(egwImage*)entity assetBase] baseOffsetByZeroAlign:entityBaseZFAlign]; entityBaseWasAligned = YES; }
                            if(!egwMatIsEqual44f(&entityBaseOffset, &egwSIMatIdentity44f)) { [(egwImageBase*)[(egwImage*)entity assetBase] baseOffsetByTransform:&entityBaseOffset]; entityBaseWasAligned = YES; }
                            if(!egwMatIsEqual44f(&entityOffset, &egwSIMatIdentity44f)) [(id<egwPOrientated>)entity offsetByTransform:&entityOffset];
                            if(!egwMatIsEqual44f(&entityOrient, &egwSIMatIdentity44f) || entityBaseWasAligned) [(id<egwPOrientated>)entity orientateByTransform:&entityOrient];
                            if(entityParams.srcType == 11 && entityParams.dist.sprtdimg.scntrl) [(egwSpritedImage*)entity setEvaluationTimer:entityParams.dist.sprtdimg.scntrl];
                            else if(entityParams.srcType == 12 && entityParams.dist.sprtdimgblnk.scntrl) [(egwSpritedImage*)entity setEvaluationTimer:entityParams.dist.sprtdimgblnk.scntrl];
                            if(entityRFlags) [(id<egwPWidget>)entity setRenderingFlags:entityRFlags];
                            if(entityPerforms.eCount) {
                                egwSinglyLinkedListIter iter;
                                
                                if(egwSLListEnumerateStart(&entityPerforms, EGW_ITERATE_MODE_DFLT, &iter)) {
                                    egwGAMPostPerforms* action;
                                    
                                    while((action = (egwGAMPostPerforms*)egwSLListEnumerateNextPtr(&iter))) {
                                        if(action->object1 && action->object2)
                                            [entity performSelector:action->method withObject:action->object1 withObject:action->object2];
                                        else if(action->object1)
                                            [entity performSelector:action->method withObject:action->object1];
                                        else
                                            [entity performSelector:action->method];
                                    }
                                }
                            }
                            ++(*loadCounter);
                        } else
                            NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating image widget asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    }
                    
                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                    if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                    if(entityParams.srcType == 0 || entityParams.srcType == 2 || entityParams.srcType == 4 || entityParams.srcType == 6 || entityParams.srcType == 8) egwSrfcFree(&entityParams.dist.srfc.surface);
                    if(entityParams.type == 5) {
                        [entityParams.dist.lbl.text release]; entityParams.dist.lbl.text = nil;
                        [entityParams.dist.lbl.font release]; entityParams.dist.lbl.font = nil;
                    }
                    if(entityParams.srcType == 11) {
                        if(entityParams.dist.sprtdimg.surfaces) {
                            for(EGWuint sIndex = 0; sIndex < entityParams.dist.sprtdimg.sCount; ++sIndex)
                                egwSrfcFree(&entityParams.dist.sprtdimg.surfaces[sIndex]);
                            free((void*)entityParams.dist.sprtdimg.surfaces); entityParams.dist.sprtdimg.surfaces = NULL;
                        }
                        if(entityParams.dist.sprtdimg.framings) { free((void*)entityParams.dist.sprtdimg.framings); entityParams.dist.sprtdimg.framings = NULL; }
                    }
                    [entityMStack release]; entityMStack = nil;
                    egwSLListFree(&entityPerforms);
                } else {
                    NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Widget node malformed or type attribute '%s' not supported.", resourceFile, entityID, (entityNodeType ? (const char*)entityNodeType : (const char*)"<NULL>"));
                }
                
                if(entityNodeType) { xmlFree(entityNodeType); entityNodeType = NULL; }
            } else if (entityRefID) { // !!!: Widget Copy/Get
                NSString* entityRefIdent = [[NSString alloc] initWithUTF8String:(const char*)entityRefID];
                id<NSObject> entityRef = (id<NSObject>)[[egwSIAsstMngr retrieveAsset:entityRefIdent] retain];
                EGWint16 entityWType = -1;
                
                if(entityRef && entityID) { // Copy
                    if([entityRef isKindOfClass:[egwImage class]]) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwImage alloc] initCopyOf:(id<egwPAsset,egwPWidget>)entityRef withIdentity:entityIDIdent])]) {
                            entityWType = 0;
                            ++(*loadCounter);
                        } else
                            NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating image widget asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    } else if([entityRef isKindOfClass:[egwButton class]]) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwButton alloc] initCopyOf:(id<egwPAsset,egwPWidget>)entityRef withIdentity:entityIDIdent])]) {
                            entityWType = 1;
                            ++(*loadCounter);
                        } else
                            NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating button widget asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    } else if([entityRef isKindOfClass:[egwToggle class]]) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwToggle alloc] initCopyOf:(id<egwPAsset,egwPWidget>)entityRef withIdentity:entityIDIdent])]) {
                            entityWType = 2;
                            ++(*loadCounter);
                        } else
                            NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating toggle widget asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    } else if([entityRef isKindOfClass:[egwPager class]]) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwPager alloc] initCopyOf:(id<egwPAsset,egwPWidget>)entityRef withIdentity:entityIDIdent])]) {
                            entityWType = 3;
                            ++(*loadCounter);
                        } else
                            NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating pager widget asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    } else if([entityRef isKindOfClass:[egwSlider class]]) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwSlider alloc] initCopyOf:(id<egwPAsset,egwPWidget>)entityRef withIdentity:entityIDIdent])]) {
                            entityWType = 4;
                            ++(*loadCounter);
                        } else
                            NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating slider widget asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    } else if([entityRef isKindOfClass:[egwSpritedImage class]]) {
                        NSString* entityIDIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
                        if([egwSIAsstMngr loadAsset:entityIDIdent
                                       fromExisting:(id<egwPAsset>)(entity = (id<NSObject>)[[egwSpritedImage alloc] initCopyOf:(id<egwPAsset,egwPWidget>)entityRef withIdentity:entityIDIdent])]) {
                            entityWType = 6;
                            ++(*loadCounter);
                        } else
                            NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Failure instantiating sprited image widget asset '%@'.", resourceFile, entityID, entityIDIdent);
                        [entityIDIdent release]; entityIDIdent = nil;
                    } else {
                        NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Copying widget class type '%@' not supported.", resourceFile, entityID, [entityRef class]);
                    }
                    
                    if(entity) {
                        if(!xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                            EGWint nodeType;
                            xmlChar* nodeName = NULL;
                            xmlChar* nodeValue = NULL;
                            EGWuint entityTEnvironment = [(id<egwPTexture>)entityRef textureEnvironment];
                            EGWuint entityPPages = (entityWType == 3 ? [(egwPager*)entityRef totalPages] : 0);
                            EGWsingle entitySIFPS = (entityWType == 6 ? [(egwSpritedImage*)entityRef spriteFPS] : 0.0f);
                            EGWuint entityGStorage = [(id<egwPWidget>)entityRef geometryStorage];
                            EGWuint entityRFlags = [(id<egwPWidget>)entityRef renderingFlags];
                            egwMaterialStack* entityMStack = nil;
                            egwMatrix44f entityOffset; egwMatCopy44f(&egwSIMatIdentity44f, &entityOffset);
                            egwMatrix44f entityOrient; egwMatCopy44f(&egwSIMatIdentity44f, &entityOrient);
                            
                            while((*retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                                nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                                
                                if(nodeType == 14) continue;
                                else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)entityNodeName) == 0) break;
                                else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"pages") == 0 && entityWType == 3) {
                                    if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                        xmlChar* entityPages = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                                        egwParseStringuicv((EGWchar*)entityPages, &entityPPages, 0, 1);
                                        if(entityPPages < 1) entityPPages = 1;
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"pages");
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"fps") == 0 && entityWType == 6) {
                                    if(egwGAMXParseRunup(xmlReadHandle, retVal) == 3 && *retVal == 1 && (nodeValue = xmlTextReaderValue(xmlReadHandle))) {
                                        xmlChar* entityPages = (xmlChar*)egwQTrimc((EGWchar*)nodeValue, -1); // nodeValue retains ownership
                                        egwParseStringfcv((EGWchar*)entityPages, &entitySIFPS, 0, 1);
                                        entitySIFPS = egwClampPosf(entitySIFPS);
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"fps");
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"storage") == 0 && entityWType != 0) {
                                    egwGAMXParseGeometry_Storage(resourceFile, entityID, xmlReadHandle, retVal, &entityGStorage);
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"environment") == 0) {
                                    egwGAMXParseTexture_Environment(resourceFile, entityID, xmlReadHandle, retVal, &entityTEnvironment);
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"materials") == 0) {
                                    if(!entityMStack && !(entityMStack = [[egwMaterialStack alloc] init]))
                                        NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Failure allocating a material stack.", resourceFile, entityID, nodeValue);
                                    else {
                                        while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                            id<NSObject> entityRef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                            if(entityRef && [entityRef conformsToProtocol:@protocol(egwPMaterial)]) {
                                                [entityMStack addMaterial:(id<egwPMaterial>)entityRef];
                                            } else {
                                                NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Material stack node type '%s' not supported.", resourceFile, entityID, nodeValue);
                                                egwGAMXParseSkip(xmlReadHandle, retVal, nodeValue);
                                            }
                                            [entityRef release]; entityRef = nil;
                                            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                            if(*retVal != 1) break;
                                        }
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"materials");
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"render_flags") == 0) {
                                    egwGAMXParseFlags_Render(resourceFile, entityID, xmlReadHandle, retVal, &entityRFlags);
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"offset") == 0) {
                                    while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                        if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                            egwGAMXParseTransform(xmlReadHandle, retVal, &entityOffset);
                                        else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                            id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                            if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                                [(id<egwPOrientated>)entity trySetOffsetDriver:(id<egwPInterpolator>)entityIPORef];
                                            }
                                            [entityIPORef release]; entityIPORef = nil;
                                        }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"offset");
                                } else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"orient") == 0) {
                                    while(egwGAMXParseRunup(xmlReadHandle, retVal) == 1 && *retVal == 1 && (nodeValue = xmlTextReaderName(xmlReadHandle))) {
                                        if(strcasecmp((const char*)nodeValue, (const char*)"transform") == 0)
                                            egwGAMXParseTransform(xmlReadHandle, retVal, &entityOrient);
                                        else if(strcasecmp((const char*)nodeValue, (const char*)"interpolator") == 0) {
                                            id<NSObject> entityIPORef = egwGAMXParseEntity(resourceFile, xmlReadHandle, retVal, loadCounter, nodeValue);
                                            if(entityIPORef && [entityIPORef conformsToProtocol:@protocol(egwPInterpolator)]) {
                                                [(id<egwPOrientated>)entity trySetOrientateDriver:(id<egwPInterpolator>)entityIPORef];
                                            }
                                            [entityIPORef release]; entityIPORef = nil;
                                        }
                                        if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                        if(*retVal != 1) break;
                                    }
                                    egwGAMXParseSkip(xmlReadHandle, retVal, (const xmlChar*)"orient");
                                }
                                
                                if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                                if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                                if(*retVal != 1) break;
                            }
                            
                            if(*retVal == 1) {
                                if(!egwMatIsEqual44f(&entityOffset, &egwSIMatIdentity44f)) [(id<egwPOrientated>)entity offsetByTransform:&entityOffset];
                                if(!egwMatIsEqual44f(&entityOrient, &egwSIMatIdentity44f)) [(id<egwPOrientated>)entity orientateByTransform:&entityOrient];
                                if(entityRFlags != [(id<egwPWidget>)entityRef renderingFlags]) [(id<egwPWidget>)entity setRenderingFlags:entityRFlags];
                                if(entityGStorage != [(id<egwPWidget>)entityRef geometryStorage]) [(id<egwPWidget>)entity trySetGeometryStorage:entityGStorage];
                                if(entityTEnvironment != [(id<egwPWidget>)entityRef textureEnvironment]) [(id<egwPWidget>)entity trySetTextureEnvironment:entityTEnvironment];
                                if(entityWType == 3 && entityPPages != [(egwPager*)entityRef totalPages]) [(egwPager*)entity setTotalPages:entityPPages];
                                if(entityWType == 6 && !egwIsEqualf(entitySIFPS, [(egwSpritedImage*)entityRef spriteFPS])) [(egwSpritedImage*)entity setSpriteFPS:entitySIFPS];
                                if(entityMStack) [(id<egwPWidget>)entity setMaterialStack:entityMStack];
                            }
                            
                            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                            if(nodeValue) { xmlFree(nodeValue); nodeValue = NULL; }
                            [entityMStack release]; entityMStack = nil;
                        }
                    }
                } else if(entityRef && !entityID) { // Get
                    entity = [entityRef retain];
                } else {
                    NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Widget asset '%@' does not exist.", resourceFile, entityID, entityRefIdent);
                }
                
                [entityRefIdent release]; entityRefIdent = nil;
                [entityRef release]; entityRef = nil;
            } else {
                NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Widget node must contain an ID and/or reference an ID.", resourceFile, entityID);
            }
            
            if(entityID) { xmlFree(entityID); entityID = NULL; }
            if(entityRefID) { xmlFree(entityRefID); entityRefID = NULL; }
        } else {
            NSLog(@"egwAssetManager: egwGAMXParseWidget: Failure parsing in manifest input file '%s', for asset '%s': Widget node type '%s' not supported.", resourceFile, entityID, entityNodeName);
        }
        
        egwGAMXParseSkip(xmlReadHandle, retVal, entityNodeName);
    }
    
    return entity;
}

id<NSObject> egwGAMXParseEntity(const EGWchar* resourceFile, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* loadCounter, const xmlChar* entityNodeName) {
    if(entityNodeName) {
        xmlChar* entityID = xmlTextReaderGetAttribute(xmlReadHandle, (const xmlChar*)"id");
        if(entityID) {
            NSString* entityIdent = [[NSString alloc] initWithUTF8String:(const char*)entityID];
            id<egwPAsset> asset = nil;
            
            if((asset = [egwSIAsstMngr retrieveAsset:entityIdent])) {
                if(EGW_ENGINE_ASSETS_ALRDYLDDMSGS) NSLog(@"egwAssetManager: egwGAMXParseEntity: Warning parsing in manifest input file '%s': Asset '%@' is already loaded.", resourceFile, entityIdent);
                egwGAMXParseSkip(xmlReadHandle, retVal, entityNodeName);
                [entityIdent release]; entityIdent = nil;
                xmlFree((void*)entityID); entityID = NULL;
                return [(id<NSObject>)asset retain]; // Must always return a retained asset (due to potential release in main parser)
            }
            
            [entityIdent release]; entityIdent = nil;
            xmlFree((void*)entityID); entityID = NULL;
        }
        
        if((entityNodeName[0] >= 'a' && entityNodeName[0] <= 'l') || (entityNodeName[0] >= 'A' && entityNodeName[0] <= 'L')) { // [a,l]
            if((entityNodeName[0] >= 'a' && entityNodeName[0] <= 'h') || (entityNodeName[0] >= 'A' && entityNodeName[0] <= 'H')) { // [a,h]
                if(strncasecmp((const char*)entityNodeName, (const char*)"billboard", 9) == 0)
                    return egwGAMXParseBillboard(resourceFile, xmlReadHandle, retVal, loadCounter, entityNodeName);
                else if(strncasecmp((const char*)entityNodeName, (const char*)"camera", 6) == 0)
                    return egwGAMXParseCamera(resourceFile, xmlReadHandle, retVal, loadCounter, entityNodeName);
                else if(strncasecmp((const char*)entityNodeName, (const char*)"font", 4) == 0)
                    return egwGAMXParseFont(resourceFile, xmlReadHandle, retVal, loadCounter, entityNodeName);
            } else { // [i,l]
                if(strncasecmp((const char*)entityNodeName, (const char*)"light", 5) == 0)
                    return egwGAMXParseLight(resourceFile, xmlReadHandle, retVal, loadCounter, entityNodeName);
                else if(strncasecmp((const char*)entityNodeName, (const char*)"interpolator", 12) == 0)
                    return egwGAMXParseInterpolator(resourceFile, xmlReadHandle, retVal, loadCounter, entityNodeName);
            }
        } else { // [m,z]
            if((entityNodeName[0] >= 'm' && entityNodeName[0] <= 'r') || (entityNodeName[0] >= 'M' && entityNodeName[0] <= 'R')) { // [m,r]
                if(strncasecmp((const char*)entityNodeName, (const char*)"material", 8) == 0)
                    return egwGAMXParseMaterial(resourceFile, xmlReadHandle, retVal, loadCounter, entityNodeName);
                else if(strncasecmp((const char*)entityNodeName, (const char*)"mesh", 4) == 0)
                    return egwGAMXParseMesh(resourceFile, xmlReadHandle, retVal, loadCounter, entityNodeName);
                else if(strncasecmp((const char*)entityNodeName, (const char*)"node", 4) == 0)
                    return egwGAMXParseNode(resourceFile, xmlReadHandle, retVal, loadCounter, entityNodeName);
            } else { // [s,z]
                if(strncasecmp((const char*)entityNodeName, (const char*)"texture", 7) == 0)
                    return egwGAMXParseTexture(resourceFile, xmlReadHandle, retVal, loadCounter, entityNodeName);
                else if(strncasecmp((const char*)entityNodeName, (const char*)"timer", 5) == 0)
                    return egwGAMXParseTimer(resourceFile, xmlReadHandle, retVal, loadCounter, entityNodeName);
                else if(strncasecmp((const char*)entityNodeName, (const char*)"sound", 5) == 0)
                    return egwGAMXParseSound(resourceFile, xmlReadHandle, retVal, loadCounter, entityNodeName);
                else if(strncasecmp((const char*)entityNodeName, (const char*)"widget", 6) == 0)
                    return egwGAMXParseWidget(resourceFile, xmlReadHandle, retVal, loadCounter, entityNodeName);
            }
        }
    }
    
    NSLog(@"egwAssetManager: egwGAMXParseEntity: Failure parsing in manifest input file '%s': Node type '%s' not supported.", resourceFile, entityNodeName);
    egwGAMXParseSkip(xmlReadHandle, retVal, entityNodeName);
    
    return nil;
}

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

/// @file egwAssetManager.m
/// @ingroup geWizES_sys_assetmanager
/// Asset Manager Implementation.

#import <stdio.h>
#import <zlib.h>
#import <png.h>
#import <pthread.h>
#import <libxml/xmlreader.h>
#import <ft2build.h>
#import FT_FREETYPE_H 
#import FT_GLYPH_H
#import <vorbis/ogg.h>
#import <vorbis/ivorbiscodec.h>
#import <vorbis/ivorbisfile.h>
#import "egwAssetManager.h"
#import "../sys/egwEngine.h"
#import "../sys/egwGfxContext.h"
#import "../sys/egwGfxContextNSGL.h"  // NOTE: Below code has a dependence on GL.
#import "../sys/egwGfxContextEAGLES.h"
#import "../sys/egwPhyContext.h"
#import "../sys/egwPhyContextSW.h" // NOTE: Below code has a depdendence on SW.
#import "../sys/egwSndContext.h"
#import "../sys/egwSndContextAL.h"  // NOTE: Below code has a dependence on AL.
#import "../math/egwMath.h"
#import "../math/egwMatrix.h"
#import "../data/egwArray.h"
#import "../data/egwCyclicArray.h"
#import "../gfx/egwGraphics.h"
#import "../gfx/egwFonts.h"
#import "../gfx/egwTexture.h"
#import "../geo/egwGeometry.h"
#import "../snd/egwSound.h"
#import "../snd/egwPointSound.h"
#import "../snd/egwStreamedPointSound.h"
#import "../misc/egwBoxingTypes.h"

typedef struct {
    EGWchar   chunkID[4];       // Chunk identifier
    EGWuint32 chunkSize;        // Chunk size
} egwWAVFileHeaderChunk;

typedef struct {
    EGWchar   chunkID[4];       // This should just contain "RIFF"
    EGWuint32 fileSize;         // The size of the rest of the file after this field. Entire File Size - 8
    EGWchar   fileFormat[4];    // This should just contain "WAVE"
    EGWchar   subChunk1ID[4];   // This should just contain "fmt "
    EGWuint32 subChunk1Size;    // For PCM files, this will be 16
    EGWuint16 audioFormat;      // Should be 1 for uncompressed audio
    EGWuint16 numChannels;      // 1, 2, ...
    EGWuint32 sampleRate;       // CD quality would be 44100
    EGWuint32 byteRate;         // SampleRate * NumChannels * BitsPerSample / 8
    EGWuint16 blockAlign;       // Channels * BitsPerSample / 8
    EGWuint16 bitsPerSample;    // 8, 16, 24, ...
    egwWAVFileHeaderChunk data; // This scans along until "data", to read the contents
} egwWAVFileHeader;

typedef struct {
    EGWchar   type[2];          // This should just contain "BM"
    EGWuint32 size;             // Size of BMP file in bytes (unreliable)
    EGWuint32 reserved;         // Reserved, must be zero
    EGWuint32 bitmapOffset;     // Offset to start of image data, must be 54
    EGWuint32 headerSize;       // Size of header structure, must be 40
    EGWint32  width;            // Image width in pixels
    EGWint32  height;           // Image height in pixels
    EGWuint16 planes;           // Number of planes in the image, must be 1
    EGWuint16 bitsPerPixel;     // Number of bits per pixel (1, 4, 8 (palettes), or 24)
    EGWuint32 compression;      // Compression type (0=none, 1=RLE-8, 2=RLE-4)
    EGWuint32 bitmapSize;       // Size of image data in bytes (including padding)
    EGWint32  horizontalRes;    // Horizontal resolution in pixels per meter (unreliable)
    EGWint32  verticalRes;      // Vertical resolution in pixels per meter (unreliable)
    EGWuint32 numColors;        // Number of colors in image, or zero
    EGWuint32 numImprtntColors; // Number of important colors in image, or zero
} egwBMPFileHeader;

typedef struct {
    EGWchar fileType[8];        // This should just contain "GWPVRTC1"
    EGWuint16 srfcSize;         // Width and height of image (PVRTC images always square)
    EGWuint32 srfcFormat;       // Surface format identifier
    EGWuint32 dataSize;         // The size of the data
} egwPVRTCFileHeader;


egwAssetManager* egwSIAsstMngr = nil;


EGWint egwIsOggVorbisError(EGWint retVal, NSString** errorString) {
    switch(retVal) {
        case 0: {
            if(errorString) *errorString = nil;
        } return 0;
        case OV_FALSE: {
            if(errorString) *errorString = [NSString stringWithString:@"OV_FALSE: Indicates that playback is not in progress."];
        } return 1;
        case OV_EOF: {
            if(errorString) *errorString = [NSString stringWithString:@"OV_EOF: Indicates stream is at end of file."];
        } return 1;
        case OV_HOLE: {
            if(errorString) *errorString = [NSString stringWithString:@"OV_HOLE: Indicates there was an interruption in the data."];
        } return 1;
        case OV_EREAD: {
            if(errorString) *errorString = [NSString stringWithString:@"OV_EREAD: A read from media returned an error."];
        } return 1;
        case OV_EFAULT: {
            if(errorString) *errorString = [NSString stringWithString:@"OV_EFAULT: Internal logic fault; indicates a bug or heap/stack corruption."];
        } return 1;
        case OV_EIMPL: {
            if(errorString) *errorString = [NSString stringWithString:@"OV_EIMPL: Setup failed."];
        } return 1;
        case OV_EINVAL: {
            if(errorString) *errorString = [NSString stringWithString:@"OV_EINVAL: Invalid argument value; possibly called with an OggVorbis_File structure that isn't open."];
        } return 1;
        case OV_ENOTVORBIS: {
            if(errorString) *errorString = [NSString stringWithString:@"OV_ENOTVORBIS: Bitstream does not contain any Vorbis data."];
        } return 1;
        case OV_EBADHEADER: {
            if(errorString) *errorString = [NSString stringWithString:@"OV_EBADHEADER: Invalid Vorbis bitstream header."];
        } return 1;
        case OV_EVERSION: {
            if(errorString) *errorString = [NSString stringWithString:@"OV_EVERSION: Vorbis version mismatch."];
        } return 1;
        case OV_ENOTAUDIO: {
            if(errorString) *errorString = [NSString stringWithString:@"OV_ENOTAUDIO: Not an audio data packet."];
        } return 1;
        case OV_EBADPACKET: {
            if(errorString) *errorString = [NSString stringWithString:@"OV_EBADPACKET: Invalid data packet."];
        } return 1;
        case OV_EBADLINK: {
            if(errorString) *errorString = [NSString stringWithString:@"OV_EBADLINK: Invalid stream section supplied to libvorbisfile, or the requested link is corrupt."];
        } return 1;
        case OV_ENOSEEK: {
            if(errorString) *errorString = [NSString stringWithString:@"OV_ENOSEEK: Bitstream is not seekable."];
        } return 1;
    }
    
    return 0;
}

EGWint egwIsFreeTypeError(EGWint retVal, NSString** errorString) {
    if(retVal) {
        if(errorString) {
            #undef __FTERRORS_H__
            #define FT_ERRORDEF( e, v, s )  { e, s },
            #define FT_ERROR_START_LIST     {
            #define FT_ERROR_END_LIST       { 0, 0 } };
            const struct
            {
                int          err_code;
                const char*  err_msg;
            } ft_errors[] =
            #include FT_ERRORS_H
            
            *errorString = [NSString stringWithUTF8String:ft_errors[retVal].err_msg];
        }
        return 1;
    } else if(errorString) *errorString = nil;
    
    return 0;
}


// !!!: ***** Decoding Work Structures *****

#define EGW_DECODEWORK_TYPE_SOUND   0x01    // Sound decoding work

typedef struct {
    id<egwPAsset> asset;
    void* stream;
    EGWuint8 workType;
    union {
        struct {
            EGWuint segmentID;
            EGWuint bufferID;
            EGWbyte* bufferData;
            EGWuint bufferSize;
            id (*fpPlay)(id, SEL, EGWuint32);   // IMP function pointer to playWithFlags method to reduce ObjC overhead.
        } sound;
    } contents;
} egwDecodingWorkItem;


// !!!: ***** egwAssetManager *****

@interface egwAssetManager (Private)

// Stream decoder
- (void)streamDecoderEntryPoint;
- (void)streamDecoderMainLoop:(NSAutoreleasePool**)arPool;

// Asset loaders
- (BOOL)loadAsset_Font:(NSString*)assetIdent fromFile:(const EGWchar*)resourceFile withParams:(void*)params;
- (BOOL)loadAsset_Sound:(NSString*)assetIdent fromFile:(const EGWchar*)resourceFile withParams:(void*)params;
- (BOOL)loadAsset_Texture:(NSString*)assetIdent fromFile:(const EGWchar*)resourceFile withParams:(void*)params;

// Core audio loaders
- (BOOL)loadAudio_WAV:(egwAudio*)audio fromFile:(const EGWchar*)resourceFile withTransforms:(EGWuint)transforms;
- (BOOL)loadAudio_OGG:(egwAudio*)audio fromFile:(const EGWchar*)resourceFile withTransforms:(EGWuint)transforms;
- (BOOL)loadAudioStream_OGG:(void**)stream fromFile:(const EGWchar*)resourceFile withTransforms:(EGWuint)transforms;

// Core glyph map loaders
- (BOOL)loadGlyphMap_TTF:(egwAMGlyphSet*)mapset fromFile:(const EGWchar*)resourceFile withEffects:(EGWuint)effects pointSize:(EGWsingle)ptSize;

// Core surface loaders
- (BOOL)loadSurface_BMP:(egwSurface*)surface fromFile:(const EGWchar*)resourceFile withTransforms:(EGWuint)transforms;
- (BOOL)loadSurface_PNG:(egwSurface*)surface fromFile:(const EGWchar*)resourceFile withTransforms:(EGWuint)transforms;
- (BOOL)loadSurface_PVRTC:(egwSurface*)surface fromFile:(const EGWchar*)resourceFile withTransforms:(EGWuint)transforms;

// Manifest loaders
- (EGWuint)loadManifest_GAM:(const EGWchar*)resourceFile;
- (EGWuint)loadManifest_GAMX:(const EGWchar*)resourceFile;

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


@implementation egwAssetManager

static egwAssetManager* _singleton = nil;
static EGWint _baseRefs = 0;
static FT_Library _ftLibrary = { NULL };

+ (id)alloc {
    @synchronized(self) {
        if(!_singleton)
            egwSIAsstMngr = _singleton = [super alloc];
    }
    return _singleton;
}

+ (void)dealloc {
    @synchronized(self) {
        [_singleton release];
        egwSIAsstMngr = _singleton = nil;
    }
    if(0) [super dealloc];
}

+ (id)sharedSingleton {
    return _singleton;
}

- (id)copy {
    return _singleton;
}

- (id)mutableCopy {
    return _singleton;
}

+ (BOOL)isAllocated {
    return (_singleton ? YES : NO);
}

- (id)init {
    NSString* errorString = nil;
    
    if(![super init]) { [self release]; return (self = nil); }
    
    _doShutdown = NO;
    
    if(pthread_mutex_init(&_aLock, NULL)) { [self release]; return (self = nil); }
    if(!(_assetsTable = [[NSMutableDictionary alloc] init])) { [self release]; return (self = nil); }
    
    if(pthread_mutex_init(&_qLock, NULL)) { [self release]; return (self = nil); }
    if(pthread_cond_init(&_wCond, NULL)) { [self release]; return (self = nil); }
    if(!egwCycArrayInit(&_wQueue, NULL, sizeof(egwDecodingWorkItem), 10, (EGW_ARRAY_FLG_GROWBY10 | EGW_ARRAY_FLG_GRWCND100 | EGW_ARRAY_FLG_SHRNKBY10))) { [self release]; return (self = nil); }
    
    // Initialize decoder threads first, then start afterwords
    for(EGWint threadIndex = 0; threadIndex < EGW_ASSTMNGR_SDECTHREADS; ++threadIndex) {
        if(!(_tPool[threadIndex] = [[NSThread alloc] initWithTarget:self selector:@selector(streamDecoderEntryPoint) object:nil])) { [self release]; return (self = nil); }
        [_tPool[threadIndex] setName:[[NSString alloc] initWithFormat:@"egwAssetManagerStreamDecoder%02d", (threadIndex+1)]];
    }
    for(EGWint threadIndex = 0; threadIndex < EGW_ASSTMNGR_SDECTHREADS; ++threadIndex)
        [_tPool[threadIndex] start];
    
    if(egwIsFreeTypeError(FT_Init_FreeType(&_ftLibrary), &errorString)) {
        NSLog(@"egwAssetManager: init: Failure instantiating FreeType engine. FTError: %@", (errorString ? errorString : @"TT_Err_Ok."));
        [self release]; return (self = nil);
    }
    
    _workDir = [[NSString alloc] initWithString:@"./"];
    
    if(EGW_ENGINE_MANAGERS_STARTUPMSGS) NSLog(@"egwAssetManager: init: Asset manager has been initialized.");
    
    return self;
}

- (void)dealloc {
    if(!_doShutdown)
        [self shutDownStreamDecoders];
    
    // Wait for baseRefs and workItems to remove/finish gracefully, otherwise continue
    pthread_mutex_lock(&_aLock);
    [_assetsTable removeAllObjects];
    pthread_mutex_unlock(&_aLock);
    {   NSDate* waitTill = [[NSDate alloc] initWithTimeIntervalSinceNow:(NSTimeInterval)EGW_ENGINE_MANAGERS_TIMETOWAIT];
        while(_baseRefs || _wQueue.eCount) {
            if([waitTill timeIntervalSinceNow] < (NSTimeInterval)0.0) {
                NSLog(@"egwAssetManager: dealloc: Failure waiting for %d base asset(s) to release and %d work item(s) to finish.", _baseRefs, _wQueue.eCount);
                break;
            }
        }
        [waitTill release];
    }
    
    if(&_ftLibrary) {
         FT_Done_FreeType(_ftLibrary);
    }
    
    pthread_mutex_destroy(&_aLock);
    [_assetsTable release]; _assetsTable = nil;
    [_workDir release]; _workDir = nil;
    [_pfPerf release]; _pfPerf = nil;
    
    pthread_mutex_destroy(&_qLock);
    pthread_cond_destroy(&_wCond);
    egwCycArrayFree(&_wQueue);
    
    if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwAssetManager: dealloc: Asset manager has been deallocated.");
    
    [super dealloc];
}

- (BOOL)loadAsset:(NSString*)assetIdent fromFile:(NSString*)resourceFile {
    return [self loadAsset:assetIdent fromFile:resourceFile withParams:nil];
}

- (BOOL)loadAsset:(NSString*)assetIdent fromFile:(NSString*)resourceFile withParams:(void*)params {
    BOOL retVal = NO;
    NSString* resFile = nil;
    
    pthread_mutex_lock(&_aLock);
    if([_assetsTable valueForKey:assetIdent]) {
        if(EGW_ENGINE_ASSETS_ALRDYLDDMSGS) NSLog(@"egwAssetManager: loadAsset:fromFile:withParams: Warning: Asset '%@' is already loaded.", assetIdent);
        pthread_mutex_unlock(&_aLock);
        return NO;
    }
    pthread_mutex_unlock(&_aLock);
    
    if([resourceFile hasPrefix:@"/"]) resFile = [resourceFile retain];
    else resFile = [[NSString alloc] initWithFormat:@"%@%@", _workDir, resourceFile];
    
    if(_pfPerf && [_pfPerf length]) {
        NSUInteger loc = [resFile rangeOfString:@"." options:NSBackwardsSearch].location;
        NSString* resFileName = [resFile substringToIndex:loc];
        
        if(![resFileName hasSuffix:_pfPerf]) {
            NSString* perfResFile = [[NSString alloc] initWithFormat:@"%@%@%@", resFileName, _pfPerf, [resFile substringFromIndex:loc]];
            
            if([[NSFileManager defaultManager] fileExistsAtPath:perfResFile]) {
                [resFile release];
                resFile = perfResFile;
                perfResFile = nil;
            }
            
            [perfResFile release]; perfResFile = nil;
        }
    }
    
    if([[resFile lowercaseString] hasSuffix:@".ogg"] || [[resFile lowercaseString] hasSuffix:@".wav"]) {
        if([[NSFileManager defaultManager] fileExistsAtPath:resFile])
             retVal = [self loadAsset_Sound:assetIdent fromFile:(const EGWchar*)[[NSFileManager defaultManager] fileSystemRepresentationWithPath:resFile] withParams:params];
        else
            NSLog(@"egwAssetManager: loadAsset:fromFile:withParams: Asset file '%@' not found.", resFile);
    } else if([[resFile lowercaseString] hasSuffix:@".png"] || [[resFile lowercaseString] hasSuffix:@".pvrtc"] || [[resFile lowercaseString] hasSuffix:@".bmp"]) {
        if([[NSFileManager defaultManager] fileExistsAtPath:resFile])
            retVal = [self loadAsset_Texture:assetIdent fromFile:(const EGWchar*)[[NSFileManager defaultManager] fileSystemRepresentationWithPath:resFile] withParams:params];
        else
            NSLog(@"egwAssetManager: loadAsset:fromFile:withParams: Asset file '%@' not found.", resFile);
    } else if([[resFile lowercaseString] hasSuffix:@".ttf"]) {
        if([[NSFileManager defaultManager] fileExistsAtPath:resFile])
            retVal = [self loadAsset_Font:assetIdent fromFile:(const EGWchar*)[[NSFileManager defaultManager] fileSystemRepresentationWithPath:resFile] withParams:params];
        else
            NSLog(@"egwAssetManager: loadAsset:fromFile:withParams: Asset file '%@' not found.", resFile);
    } else
        NSLog(@"egwAssetManager: loadAsset:fromFile:withParams: Asset file type '%@' not supported.", [resFile substringFromIndex:[resFile rangeOfString:@"." options:NSBackwardsSearch].location]);
    
    [resFile release]; resFile = nil;
    
    return retVal;
}

- (BOOL)loadAsset:(NSString*)assetIdent fromExisting:(id<egwPAsset>)asset {
    if(asset) {
        pthread_mutex_lock(&_aLock);
        NSString* key = (assetIdent ? assetIdent : ([asset assetBase] ? [[asset assetBase] identity] : [asset identity]));
        if(![_assetsTable valueForKey:key])
            [_assetsTable setValue:asset forKey:key];
        else {
            if(EGW_ENGINE_ASSETS_ALRDYLDDMSGS) NSLog(@"egwAssetManager: loadAsset:fromExisting: Warning: Asset '%@' is already loaded.", key);
            pthread_mutex_unlock(&_aLock);
            return NO;
        }
        pthread_mutex_unlock(&_aLock);
        return YES;
    }
    
    return NO;
}

- (EGWuint)loadAssetsFromManifest:(NSString*)resourceFile {
    EGWuint retVal = 0;
    NSString* resFile = nil;
    
    if([resourceFile hasPrefix:@"/"]) resFile = [resourceFile retain];
    else resFile = [[NSString alloc] initWithFormat:@"%@%@", _workDir, resourceFile];
    
    if(_pfPerf && [_pfPerf length]) {
        NSUInteger loc = [resFile rangeOfString:@"." options:NSBackwardsSearch].location;
        NSString* resFileName = [resFile substringToIndex:loc];
        
        if(![resFileName hasSuffix:_pfPerf]) {
            NSString* perfResFile = [[NSString alloc] initWithFormat:@"%@%@%@", resFileName, _pfPerf, [resFile substringFromIndex:loc]];
            
            if([[NSFileManager defaultManager] fileExistsAtPath:perfResFile]) {
                [resFile release];
                resFile = perfResFile;
                perfResFile = nil;
            }
            
            [perfResFile release]; perfResFile = nil;
        }
    }
    
    if([[resFile lowercaseString] hasSuffix:@".gam"] || [[resFile lowercaseString] hasSuffix:@".gamx"]) {
        NSString* resFileName = [resFile substringToIndex:[resFile rangeOfString:@"." options:NSBackwardsSearch].location];
        NSString* binaryResFile = [NSString stringWithFormat:@"%@.gam", resFileName];
        NSString* textResFile = [NSString stringWithFormat:@"%@.gamx", resFileName];
        
        if([[NSFileManager defaultManager] fileExistsAtPath:binaryResFile] && [[NSFileManager defaultManager] fileExistsAtPath:textResFile]) {
            NSDictionary* binaryResFileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:binaryResFile error:nil];
            NSDictionary* textResFileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:textResFile error:nil];
            
            if([(NSDate*)[binaryResFileAttributes objectForKey:NSFileModificationDate] timeIntervalSinceDate:(NSDate*)[textResFileAttributes objectForKey:NSFileModificationDate]] >= 0.0)
                retVal = [self loadManifest_GAM:(const EGWchar*)[[NSFileManager defaultManager] fileSystemRepresentationWithPath:binaryResFile]];
            else
                retVal = [self loadManifest_GAMX:(const EGWchar*)[[NSFileManager defaultManager] fileSystemRepresentationWithPath:textResFile]];
        } else if([[NSFileManager defaultManager] fileExistsAtPath:binaryResFile])
            retVal = [self loadManifest_GAM:(const EGWchar*)[[NSFileManager defaultManager] fileSystemRepresentationWithPath:binaryResFile]];
        else if([[NSFileManager defaultManager] fileExistsAtPath:textResFile])
            retVal = [self loadManifest_GAMX:(const EGWchar*)[[NSFileManager defaultManager] fileSystemRepresentationWithPath:textResFile]];
        else
            NSLog(@"egwAssetManager: loadAssetsFromManifest: Manifest file '%@' not found.", resFile);
    } else
        NSLog(@"egwAssetManager: loadAssetsFromManifest: Manifest file type '%@' not supported.", [resFile substringFromIndex:[resFile rangeOfString:@"." options:NSBackwardsSearch].location]);
    
    [resFile release]; resFile = nil;
    
    return retVal;
}

- (BOOL)unloadAsset:(NSString*)assetIdent {
    pthread_mutex_lock(&_aLock);
    
    if([_assetsTable objectForKey:(id)assetIdent]) {
        [_assetsTable removeObjectForKey:(id)assetIdent];
        
        pthread_mutex_unlock(&_aLock);
        return YES;
    }
    
    pthread_mutex_unlock(&_aLock);
    return NO;
}

- (EGWuint)unloadAssetsWithPrefix:(NSString*)assetIdentPrefix {
    NSMutableArray* remove = [[NSMutableArray alloc] init];
    EGWuint removed = 0;
    
    if(remove) {
        pthread_mutex_lock(&_aLock);
        
        for(NSString* key in [_assetsTable keyEnumerator])
            if([key hasPrefix:assetIdentPrefix])
                [remove addObject:key];
        
        for(NSString* key in remove)
            [_assetsTable removeObjectForKey:(id)key];
        
        removed = (EGWuint)[remove count];
        [remove release]; remove = nil;
        
        pthread_mutex_unlock(&_aLock);
    } else
        NSLog(@"egwAssetManager: unloadAssetsWithPrefix: Failure creating temporary removal array object. Failure unloading.");
    
    return removed;
}

- (EGWuint)unloadAssetsWithSuffix:(NSString*)assetIdentSuffix {
    NSMutableArray* remove = [[NSMutableArray alloc] init];
    EGWuint removed = 0;
    
    if(remove) {
        pthread_mutex_lock(&_aLock);
        
        for(NSString* key in [_assetsTable keyEnumerator])
            if([key hasSuffix:assetIdentSuffix])
                [remove addObject:key];
        
        for(NSString* key in remove)
            [_assetsTable removeObjectForKey:(id)key];
        
        removed = (EGWuint)[remove count];
        [remove release]; remove = nil;
        
        pthread_mutex_unlock(&_aLock);
    } else
        NSLog(@"egwAssetManager: unloadAssetsWithSuffix: Failure creating temporary removal array object. Failure unloading.");
    
    return removed;
}

- (EGWuint)unloadAllAssets {
    EGWuint removed = 0;
    
    pthread_mutex_lock(&_aLock);
    
    removed = (EGWuint)[_assetsTable count];
    [_assetsTable removeAllObjects];
    
    pthread_mutex_unlock(&_aLock);
    
    return removed;
}

- (id<egwPAsset>)retrieveAsset:(NSString*)assetIdent {
    id<egwPAsset> asset = nil;
    pthread_mutex_lock(&_aLock);
    asset = (id<egwPAsset>)[_assetsTable valueForKey:assetIdent];
    pthread_mutex_unlock(&_aLock);
    return asset;
}

- (EGWuint)retrieveAssetsWithPrefix:(NSString*)assetIdentPrefix usingArray:(NSMutableArray*)assetArray {
    if(assetArray) {
        pthread_mutex_lock(&_aLock);
        
        for(NSString* key in [_assetsTable keyEnumerator])
            if([key hasPrefix:assetIdentPrefix])
                [assetArray addObject:[_assetsTable objectForKey:(id)key]];
        
        pthread_mutex_unlock(&_aLock);
        
        return (EGWuint)[assetArray count];
    }
    
    return 0;
}

- (EGWuint)retrieveAssetsWithSuffix:(NSString*)assetIdentSuffix usingArray:(NSMutableArray*)assetArray {
    if(assetArray) {
        pthread_mutex_lock(&_aLock);
        
        for(NSString* key in [_assetsTable keyEnumerator])
            if([key hasSuffix:assetIdentSuffix])
                [assetArray addObject:[_assetsTable objectForKey:(id)key]];
        
        pthread_mutex_unlock(&_aLock);
        
        return (EGWuint)[assetArray count];
    }
    return 0;
}

- (id<egwPAsset>)instantiateAsset:(NSString*)assetIdent {
    id<NSObject, egwPAsset> asset = [_assetsTable valueForKey:assetIdent];
    return [[(NSObject*)asset copy] autorelease];
}

- (BOOL)addDecodingWorkForSoundAsset:(id<egwPAsset>)streamedAsset withStreamDecoder:(void*)stream segmentID:(EGWuint)segmentID bufferID:(EGWuint)bufferID bufferData:(EGWbyte*)bufferData bufferSize:(EGWuint)bufferSize {
    if(!_doShutdown) {
        egwDecodingWorkItem* workItem;
        pthread_mutex_lock(&_qLock);
        
        if(egwCycArrayAddTail(&_wQueue, NULL)) { // skip copy init
            if((workItem = (egwDecodingWorkItem*)egwCycArrayElementPtrTail(&_wQueue))) {
                workItem->asset = [streamedAsset retain]; // manual retain/release
                workItem->stream = stream;
                workItem->workType = EGW_DECODEWORK_TYPE_SOUND;
                workItem->contents.sound.segmentID = segmentID;
                workItem->contents.sound.bufferID = bufferID;
                workItem->contents.sound.bufferData = bufferData;
                workItem->contents.sound.bufferSize = bufferSize;
                workItem->contents.sound.fpPlay = (id(*)(id, SEL, EGWuint32))[((NSObject*)workItem->asset) methodForSelector:@selector(playWithFlags:)];
                
                pthread_cond_broadcast(&_wCond);
                pthread_mutex_unlock(&_qLock);
                return YES;
            } else
                egwCycArrayRemoveTail(&_wQueue);
        }
        
        pthread_mutex_unlock(&_qLock);
        NSLog(@"egwAssetManager: addDecodingWorkForSoundAsset:withStreamDecoder:segmentID:bufferID: Failure creating a new work item for asset %@, decoder data %p, segmentID %d, bufferID %d. A buffer underrun is imminent.", [streamedAsset identity], stream, segmentID, bufferID);
    }
    
    return NO;
}

- (EGWuint)removeAllDecodingWorkForSoundAsset:(id<egwPAsset>)streamedAsset {
    EGWuint found = 0;
    
    EGWuint workIndex;
    egwDecodingWorkItem* workItem;
    pthread_mutex_lock(&_qLock);
    
    workIndex = _wQueue.eCount; while(workIndex--) {
        if((workItem = (egwDecodingWorkItem*)egwCycArrayElementPtrAt(&_wQueue, workIndex)) &&
           workItem->asset == streamedAsset &&
           workItem->workType == EGW_DECODEWORK_TYPE_SOUND) {
            ++found;
            [workItem->asset release]; workItem->asset = nil;
            egwCycArrayRemoveAt(&_wQueue, workIndex);
        }
    }
    
    pthread_mutex_unlock(&_qLock);
    
    return found;
}

- (void)shutDownStreamDecoders {
    if(!_doShutdown) {
        @synchronized(self) {
            if(!_doShutdown) {
                egwDecodingWorkItem* workItem;
                
                pthread_mutex_lock(&_qLock);
                
                _doShutdown = YES;
                
                if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwAssetManager: shutDownStreamDecoders: Shutting down stream decoders.");
                
                for(EGWint threadIndex = 0; threadIndex < EGW_ASSTMNGR_SDECTHREADS; ++threadIndex) {
                    [_tPool[threadIndex] cancel]; [_tPool[threadIndex] release]; _tPool[threadIndex] = nil;
                }
                
                while(_wQueue.eCount) {
                    workItem = (egwDecodingWorkItem*)egwCycArrayElementPtrHead(&_wQueue);
                    [workItem->asset release]; workItem->asset = nil;
                    egwCycArrayRemoveHead(&_wQueue);
                }
                
                pthread_mutex_unlock(&_qLock);
                
                if(EGW_ENGINE_MANAGERS_SHUTDOWNMSGS) NSLog(@"egwAssetManager: shutDownStreamDecoders: Stream decoders shut down.");
            }
        }
    }
}

- (NSString*)workingDirectory {
    return _workDir;
}

- (void)setFilenamePostfixPerferance:(NSString*)postfix {
    [postfix retain];
    [_pfPerf release];
    _pfPerf = postfix;
}

- (void)setWorkingDirectory:(NSString*)directory {
    if(directory && ([directory hasPrefix:@"/"] || [directory hasPrefix:@"./"] || [directory hasPrefix:@"../"])) {
        NSString* dir = nil;
        
        if([directory hasSuffix:@"/"]) dir = [directory retain];
        else dir = [[NSString alloc] initWithFormat:@"%@%@", directory, @"/"];
        
        [dir retain];
        [_workDir release];
        _workDir = dir;
        
        [dir release];
    }
}

@end


@implementation egwAssetManager (BaseTracking)

+ (void)incBaseRef {
    @synchronized(self) {
        ++_baseRefs;
    }
}

+ (void)decBaseRef {
    @synchronized(self) {
        --_baseRefs;
    }
}

@end


@implementation egwAssetManager (DataLoading)

- (BOOL)loadAudio:(egwAudio*)audio fromFile:(NSString*)resourceFile withTransforms:(EGWuint)transforms {
    BOOL retVal = NO;
    NSString* resFile = nil;
    
    if([resourceFile hasPrefix:@"/"]) resFile = [resourceFile retain];
    else resFile = [[NSString alloc] initWithFormat:@"%@%@", _workDir, resourceFile];
    
    if(_pfPerf && [_pfPerf length]) {
        NSUInteger loc = [resFile rangeOfString:@"." options:NSBackwardsSearch].location;
        NSString* resFileName = [resFile substringToIndex:loc];
        
        if(![resFileName hasSuffix:_pfPerf]) {
            NSString* perfResFile = [[NSString alloc] initWithFormat:@"%@%@%@", resFileName, _pfPerf, [resFile substringFromIndex:loc]];
            
            if([[NSFileManager defaultManager] fileExistsAtPath:perfResFile]) {
                [resFile release];
                resFile = perfResFile;
                perfResFile = nil;
            }
            
            [perfResFile release]; perfResFile = nil;
        }
    }
    
    if([[resFile lowercaseString] hasSuffix:@".wav"]) {
        if([[NSFileManager defaultManager] fileExistsAtPath:resFile])
            retVal = [self loadAudio_WAV:audio fromFile:(const EGWchar*)[[NSFileManager defaultManager] fileSystemRepresentationWithPath:resFile] withTransforms:transforms];
        else
            NSLog(@"egwAssetManager: loadAudio:fromFile:withTransforms: File '%@' not found.", resFile);
    } else if([[resFile lowercaseString] hasSuffix:@".ogg"]) {
        if([[NSFileManager defaultManager] fileExistsAtPath:resFile])
            retVal = [self loadAudio_OGG:audio fromFile:(const EGWchar*)[[NSFileManager defaultManager] fileSystemRepresentationWithPath:resFile] withTransforms:transforms];
        else
            NSLog(@"egwAssetManager: loadAudio:fromFile:withTransforms: File '%@' not found.", resFile);
    } else
        NSLog(@"egwAssetManager: loadAudio:fromFile:withTransforms: File type '%@' unsupported.", [resFile substringFromIndex:[resFile rangeOfString:@"." options:NSBackwardsSearch].location]);
    
    [resFile release]; resFile = nil;
    
    return retVal;
}

- (BOOL)loadAudioStream:(void**)stream fromFile:(NSString*)resourceFile withTransforms:(EGWuint)transforms {
    BOOL retVal = NO;
    NSString* resFile = nil;
    
    if([resourceFile hasPrefix:@"/"]) resFile = [resourceFile retain];
    else resFile = [[NSString alloc] initWithFormat:@"%@%@", _workDir, resourceFile];
    
    if(_pfPerf && [_pfPerf length]) {
        NSUInteger loc = [resFile rangeOfString:@"." options:NSBackwardsSearch].location;
        NSString* resFileName = [resFile substringToIndex:loc];
        
        if(![resFileName hasSuffix:_pfPerf]) {
            NSString* perfResFile = [[NSString alloc] initWithFormat:@"%@%@%@", resFileName, _pfPerf, [resFile substringFromIndex:loc]];
            
            if([[NSFileManager defaultManager] fileExistsAtPath:perfResFile]) {
                [resFile release];
                resFile = perfResFile;
                perfResFile = nil;
            }
            
            [perfResFile release]; perfResFile = nil;
        }
    }
    
    if([[resFile lowercaseString] hasSuffix:@".ogg"]) {
        if([[NSFileManager defaultManager] fileExistsAtPath:resFile])
            retVal = [self loadAudioStream_OGG:stream fromFile:(const EGWchar*)[[NSFileManager defaultManager] fileSystemRepresentationWithPath:resFile] withTransforms:transforms];
        else
            NSLog(@"egwAssetManager: loadAudioStream:fromFile:withTransforms: File '%@' not found.", resFile);
    } else
        NSLog(@"egwAssetManager: loadAudioStream:fromFile:withTransforms: File type '%@' unsupported.", [resFile substringFromIndex:[resFile rangeOfString:@"." options:NSBackwardsSearch].location]);
    
    [resFile release]; resFile = nil;
    
    return retVal;
}

- (BOOL)loadSurface:(egwSurface*)surface fromFile:(NSString*)resourceFile withTransforms:(EGWuint)transforms {
    BOOL retVal = NO;
    NSString* resFile = nil;
    
    if([resourceFile hasPrefix:@"/"]) resFile = [resourceFile retain];
    else resFile = [[NSString alloc] initWithFormat:@"%@%@", _workDir, resourceFile];
    
    if(_pfPerf && [_pfPerf length]) {
        NSUInteger loc = [resFile rangeOfString:@"." options:NSBackwardsSearch].location;
        NSString* resFileName = [resFile substringToIndex:loc];
        
        if(![resFileName hasSuffix:_pfPerf]) {
            NSString* perfResFile = [[NSString alloc] initWithFormat:@"%@%@%@", resFileName, _pfPerf, [resFile substringFromIndex:loc]];
            
            if([[NSFileManager defaultManager] fileExistsAtPath:perfResFile]) {
                [resFile release];
                resFile = perfResFile;
                perfResFile = nil;
            }
            
            [perfResFile release]; perfResFile = nil;
        }
    }
    
    if([[resFile lowercaseString] hasSuffix:@".bmp"]) {
        if([[NSFileManager defaultManager] fileExistsAtPath:resFile])
            retVal = [self loadSurface_BMP:surface fromFile:(const EGWchar*)[[NSFileManager defaultManager] fileSystemRepresentationWithPath:resFile] withTransforms:transforms];
        else
            NSLog(@"egwAssetManager: loadSurface:fromFile:withTransforms: File '%@' not found.", resFile);
    } else if([[resFile lowercaseString] hasSuffix:@".png"]) {
        if([[NSFileManager defaultManager] fileExistsAtPath:resFile])
            retVal = [self loadSurface_PNG:surface fromFile:(const EGWchar*)[[NSFileManager defaultManager] fileSystemRepresentationWithPath:resFile] withTransforms:transforms];
        else
            NSLog(@"egwAssetManager: loadSurface:fromFile:withTransforms: File '%@' not found.", resFile);
    } else if([[resFile lowercaseString] hasSuffix:@".pvrtc"]) {
        if([[NSFileManager defaultManager] fileExistsAtPath:resFile])
            retVal = [self loadSurface_PVRTC:surface fromFile:(const EGWchar*)[[NSFileManager defaultManager] fileSystemRepresentationWithPath:resFile] withTransforms:transforms];
        else
            NSLog(@"egwAssetManager: loadSurface:fromFile:withTransforms: File '%@' not found.", resFile);
    } else
        NSLog(@"egwAssetManager: loadSurface:fromFile:withTransforms: File type '%@' unsupported.", [resFile substringFromIndex:[resFile rangeOfString:@"." options:NSBackwardsSearch].location]);
    
    [resFile release]; resFile = nil;
    
    return retVal;
}

- (BOOL)loadGlyphMap:(egwAMGlyphSet*)mapset fromFile:(NSString*)resourceFile withEffects:(EGWuint)effects pointSize:(EGWsingle)ptSize {
    BOOL retVal = NO;
    NSString* resFile = nil;
    
    if([resourceFile hasPrefix:@"/"]) resFile = [resourceFile retain];
    else resFile = [[NSString alloc] initWithFormat:@"%@%@", _workDir, resourceFile];
    
    if(_pfPerf && [_pfPerf length]) {
        NSUInteger loc = [resFile rangeOfString:@"." options:NSBackwardsSearch].location;
        NSString* resFileName = [resFile substringToIndex:loc];
        
        if(![resFileName hasSuffix:_pfPerf]) {
            NSString* perfResFile = [[NSString alloc] initWithFormat:@"%@%@%@", resFileName, _pfPerf, [resFile substringFromIndex:loc]];
            
            if([[NSFileManager defaultManager] fileExistsAtPath:perfResFile]) {
                [resFile release];
                resFile = perfResFile;
                perfResFile = nil;
            }
            
            [perfResFile release]; perfResFile = nil;
        }
    }
    
    if([[resFile lowercaseString] hasSuffix:@".ttf"]) {
        if([[NSFileManager defaultManager] fileExistsAtPath:resFile])
            retVal = [self loadGlyphMap_TTF:mapset fromFile:(const EGWchar*)[[NSFileManager defaultManager] fileSystemRepresentationWithPath:resFile] withEffects:effects pointSize:ptSize];
        else
            NSLog(@"egwAssetManager: loadGlyphMap:fromFile:withTransforms: File '%@' not found.", resFile);
    } else
        NSLog(@"egwAssetManager: loadGlyphMap:fromFile:withTransforms: File type '%@' unsupported.", [resFile substringFromIndex:[resFile rangeOfString:@"." options:NSBackwardsSearch].location]);
    
    [resFile release]; resFile = nil;
    
    return retVal;
}

@end


@implementation egwAssetManager (Private)

// !!!: Stream decoder.

- (void)streamDecoderEntryPoint {
    NSAutoreleasePool* arPool = [[NSAutoreleasePool alloc] init];
    
    [NSThread setThreadPriority:(double)EGW_ASSTMNGR_SDECPRIORITY];
    
    [self streamDecoderMainLoop:&arPool];
    
    [arPool release];
}

- (void)streamDecoderMainLoop:(NSAutoreleasePool**)arPool {
    NSString* errorString = nil;
    egwDecodingWorkItem workItem;
    EGWbyte* rawSndDataBuffer = (EGWbyte*)malloc((size_t)EGW_STRMSOUND_BUFFERSIZE);
    EGWuint rawSndDataBufferAllocSize = EGW_STRMSOUND_BUFFERSIZE;
    EGWuint8 threadNumber, oddJobCounter = EGW_ENGINE_MANAGERS_ODDJOBSPINCYCLE;
    time_t drainAfter = time(NULL) + (time_t)EGW_ENGINE_MANAGERS_TIMETODRAIN;
    
    // Determine this thread number
    for(threadNumber = 1; threadNumber <= EGW_ASSTMNGR_SDECTHREADS; ++threadNumber)
        if(_tPool[threadNumber-1] == [NSThread currentThread])
            break;
    
    // NOTICE: TIER 0 CODE SECTION!
    while(1) {
        if(oddJobCounter-- && !_doShutdown) {
            pthread_mutex_lock(&_qLock);
            
            if(_wQueue.eCount) {
                memcpy((void*)&workItem, (const void*)egwCycArrayElementPtrHead(&_wQueue), sizeof(egwDecodingWorkItem));
                egwCycArrayRemoveHead(&_wQueue);
                pthread_mutex_unlock(&_qLock);
                
                switch(workItem.workType) {
                    case EGW_DECODEWORK_TYPE_SOUND: {
                        if(!workItem.contents.sound.bufferData && rawSndDataBufferAllocSize < workItem.contents.sound.bufferSize) {
                            if(egwAISndCntx)
                                [egwAISndCntx returnUsedBufferData:&rawSndDataBuffer];
                            else {
                                free((void*)rawSndDataBuffer); rawSndDataBuffer = NULL;
                            }
                            rawSndDataBuffer = (EGWbyte*)malloc((size_t)workItem.contents.sound.bufferSize);
                            rawSndDataBufferAllocSize = workItem.contents.sound.bufferSize;
                        }
                        
                        EGWbyte* rawSndData = (workItem.contents.sound.bufferData ? workItem.contents.sound.bufferData : rawSndDataBuffer);
                        OggVorbis_File* oggData = NULL;
                        vorbis_info* oggInfo = NULL;
                        ogg_int64_t seekPosition = 0;
                        EGWint bytesRead = 0;
                        EGWint totalBytesRead = 0;
                        int bitstream = 0;
                        
                        if((oggData = (OggVorbis_File*)workItem.stream) && (oggInfo = ov_info(oggData, -1))) {
                            if(workItem.contents.sound.bufferID != NSNotFound && workItem.contents.sound.segmentID != NSNotFound) {
                                // Do decoding work for a buffer.
                                
                                seekPosition = (ogg_int64_t)(workItem.contents.sound.bufferSize / ((EGWuint)sizeof(EGWuint16) * (EGWuint)(oggInfo->channels))) * (ogg_int64_t)workItem.contents.sound.segmentID;
                                if(!egwIsOggVorbisError(ov_pcm_seek(oggData, seekPosition), &errorString)) {
                                    // Read the audio data.
                                    
                                    // NOTE: Must continually loop around since liboggvorbis likes to not fully read the amount we give to it.
                                    do {
                                        bytesRead = (EGWuint16)
                                        ov_read(oggData,                            // OggVorbis_File pointer
                                                (char*)((EGWuintptr)rawSndData + (EGWuintptr)totalBytesRead), // Raw data buffer (offsetted)
                                                (int)(workItem.contents.sound.bufferSize - totalBytesRead), // Read chunk size (bytes)
                                                //0,                                  // Endianness (0-little, 1-big)
                                                //sizeof(short),                      // Word size (bytes)
                                                //1,                                  // Data sign (0-unsigned, 1-signed)
                                                &bitstream);                        // Bitstream positioning
                                        
                                        if(bytesRead >= 0) totalBytesRead += bytesRead;
                                        else if(egwIsOggVorbisError((EGWint)bytesRead, &errorString)) {
                                            NSLog(@"egwAssetManager: streamDecoderMainLoop: Warning: Failure decoding stream after %d bytes for audio asset %@ segment %d. OVError: %s", totalBytesRead, [(id<egwPAsset>)(workItem.asset) identity], workItem.contents.sound.segmentID, (errorString ? (const char*)errorString : (const char*)"No error."));
                                            break;
                                        }
                                    } while (bytesRead > 0 && totalBytesRead < workItem.contents.sound.bufferSize);
                                    
                                    // NOTE: To save time, we assume that the total bytes read, even if less than the buffer size (which almost always happens on last segment), does correctly correspond to end of the sound, and not due to a bad file -jw
                                } else { // Failure seeking
                                    NSLog(@"egwAssetManager: streamDecoderMainLoop: Warning: Failure seeking stream to PCM sample %d for audio asset %@ segment %d. OVError: %s", seekPosition, [(id<egwPAsset>)(workItem.asset) identity], workItem.contents.sound.segmentID, (errorString ? (const char*)errorString : (const char*)"No error."));
                                    memset((void*)rawSndData, 0, (size_t)workItem.contents.sound.bufferSize);
                                    totalBytesRead = (EGWint16)workItem.contents.sound.bufferSize;
                                }
                                
                                // NOTE: The code below is non-abstracted OpenAL dependent.
                                
                                // FIXME: Audio contexts are not currently thread dependent, will need to fix if that changes -jw
                                //if([[[[workItem asset] assetBase] associatedSndContext] isActive] || [[[[workItem asset] assetBase] associatedSndContext] makeActive]) {
                                egw_alBufferData((ALint)workItem.contents.sound.bufferID, // Buffer identifier
                                                 (oggInfo->channels == 1 ?                // Audio format
                                                    AL_FORMAT_MONO16 : AL_FORMAT_STEREO16), // NOTE: OggVorbis always is 16-bit PCM
                                                 (ALvoid*)rawSndData,                     // Raw data buffer
                                                 (ALsizei)totalBytesRead,                 // Size of data buffer (bytes)
                                                 (ALsizei)(oggInfo->rate));               // Sampling rate (samples/sec)
                                
                                // Tell the sound asset we've loaded an owned buffer
                                workItem.contents.sound.fpPlay((id)workItem.asset, @selector(playWithFlags:), (EGW_SNDOBJ_RPLYFLG_BUFFERLOADED | ((EGWuint)workItem.contents.sound.bufferID << 16)));
                                //} else {
                                //    NSLog(@"egwAssetManager: streamDecoderMainLoop: Failure making sound context active [on this thread] to buffer in audio data. A buffer underrun is potential.");
                                //}
                            } else {
                                // Shut down oggData
                                ov_clear(oggData);
                                free((void*)oggData);
                            }
                        }
                    } break;
                    
                    default: {
                        // Unknown work item
                    } break;
                }
                
                [workItem.asset release]; workItem.asset = nil;
            } else {
                // Wait for work signal
                pthread_cond_wait(&_wCond, &_qLock);
                pthread_mutex_unlock(&_qLock);
            }
        } else {
            if([_tPool[threadNumber-1] isCancelled] || _doShutdown)
                goto ThreadBreak;
            else if(time(NULL) >= drainAfter) {
                [*arPool release]; *arPool = [[NSAutoreleasePool alloc] init];
                drainAfter = time(NULL) + (time_t)EGW_ENGINE_MANAGERS_TIMETODRAIN;
            }
            
            oddJobCounter = EGW_ENGINE_MANAGERS_ODDJOBSPINCYCLE;
        }
    }
    
ThreadBreak:
    if(rawSndDataBuffer)
        [egwAISndCntx returnUsedBufferData:&rawSndDataBuffer];
}

// !!!: Font asset loader.
// TODO: Font asset streaming instance. -jw

- (BOOL)loadAsset_Font:(NSString*)assetIdent fromFile:(const EGWchar*)resourceFile withParams:(void*)params {
    egwFntParams* fntParams = (egwFntParams*)params;
    egwAMGlyphSet mapset; memset((void*)&mapset, 0, sizeof(egwAMGlyphSet));
    egwTexture* asset = nil;
    egwColorRGBA glyphColor;
    
    if(!([self loadGlyphMap:&mapset
                   fromFile:[[NSFileManager defaultManager] stringWithFileSystemRepresentation:(const char*)resourceFile length:(NSUInteger)strlen((const char*)resourceFile)]
                withEffects:(EGWuint)(fntParams ? fntParams->rEffects : 0)
                  pointSize:(fntParams ? fntParams->pSize : 12.0f)]))
        goto ErrorCleanup;
    
    if(!(asset = [[egwBitmappedFont alloc] initWithIdentity:assetIdent
                                                   glyphSet:&mapset // Ownership transfer!
                                                 glyphColor:(fntParams ? egwClrConvert4fRGBA(&fntParams->gColor, &glyphColor) : NULL)])) {
        NSLog(@"egwAssetManager: loadAsset_Font:fromFile:withParams: Failure assetifying font input file '%@'. Failure instantiating egwBitmappedFont asset.", resourceFile);
        goto ErrorCleanup;
    }
    
    if(![self loadAsset:assetIdent fromExisting:asset]) goto ErrorCleanup;
    else { [asset release]; asset = nil; } // asset is now owned by _assetsTable
    
    return YES;
    
ErrorCleanup:
    if(asset) [asset release];
    for(EGWchar charIndex = 33; charIndex <= 126; ++charIndex) {
        if(mapset.glyphs[charIndex - 33].gaData) {
            free((void*)mapset.glyphs[charIndex - 33].gaData);
            mapset.glyphs[charIndex - 33].gaData = NULL;
        }
    }
    
    return NO;
}

// !!!: Sound asset loader.

- (BOOL)loadAsset_Sound:(NSString*)assetIdent fromFile:(const EGWchar*)resourceFile withParams:(void*)params {
    NSString* errorString = nil;
    egwSndParams* sndParams = (egwSndParams*)params;
    egwAudio audio; memset((void*)&audio, 0, sizeof(egwAudio));
    void* stream = NULL;
    egwPointSound* asset = nil;
    BOOL useStreamingInstance = NO;
    
    // Determine if file is so large that it needs a streaming instance
    {   FILE* fin = NULL;
        NSString* resFile = [[[NSFileManager defaultManager] stringWithFileSystemRepresentation:(const char*)resourceFile length:(NSUInteger)strlen((const char*)resourceFile)] lowercaseString];
        
        if(!(fin = fopen((const char*)resourceFile, "rb"))) {
            NSLog(@"egwAssetManager: loadAsset_Sound:fromFile:withParams: Failure opening sound input file '%s'. File not found or cannot be opened.", resourceFile);
            fclose(fin);
            goto ErrorCleanup;
        }
        
        if([resFile hasSuffix:@".ogg"]) {
            OggVorbis_File* oggData = NULL;
            vorbis_info* oggInfo = NULL;
            
            if(!(oggData = (OggVorbis_File*)malloc(sizeof(OggVorbis_File))) ||
               egwIsOggVorbisError(ov_open(fin, oggData, NULL, 0), &errorString)) {
                NSLog(@"egwAssetManager: loadAsset_Sound:fromFile:withParams: Failure opening sound input file '%s'. OVError: %@", resourceFile, (errorString ? (const char*)errorString : (const char*)"No error."));
                fclose(fin);
                goto ErrorCleanup;
            }
            
            // OV will control file close from here
            fin = NULL;
            
            if(!(oggInfo = ov_info(oggData, -1))) {
                NSLog(@"egwAssetManager: loadAsset_Sound:fromFile:withParams: Failure accessing Vorbis data info structure for sound input file '%s'.", resourceFile);
                if(oggData) { ov_clear(oggData); free((void*)oggData); }
                goto ErrorCleanup;
            }
            
            if(ov_pcm_total(oggData, -1) * sizeof(EGWuint16) * oggInfo->channels > EGW_SOUND_MAXSTATIC)
                useStreamingInstance = YES;
            
            if(oggData) { ov_clear(oggData); free((void*)oggData); }
        } else if([resFile hasSuffix:@".wav"]) {
            fseek(fin, 0, SEEK_END);
            
            // TODO: Once streaming from WAV is supported, un-comment this section. -jw
            //if((EGWuint)(ftell(fin) - sizeof(egwWAVFileHeader)) > EGW_SOUND_MAXSTATIC)
            //    useStreamingInstance = YES;
        }
        
        if(fin) fclose(fin);
    }
    
    if(!useStreamingInstance) {
        if(!([self loadAudio:&audio
                    fromFile:[[NSFileManager defaultManager] stringWithFileSystemRepresentation:(const char*)resourceFile length:(NSUInteger)strlen((const char*)resourceFile)]
              withTransforms:(EGWuint)(sndParams ? sndParams->aTransforms : 0) | EGW_AUDIO_TRFM_ENSRLTETMS]))
            goto ErrorCleanup;
        
        if(!(asset = [[egwPointSound alloc] initWithIdentity:assetIdent
                                                  soundAudio:&audio
                                                 soundRadius:(sndParams ? sndParams->aRadius : EGW_SFLT_MAX)
                                        resonationTransforms:((sndParams ? sndParams->aTransforms : 0) | EGW_AUDIO_TRFM_ENSRLTETMS)
                                           resonationEffects:(sndParams ? &sndParams->aEffects : NULL)
                                           resonationRolloff:(sndParams ? sndParams->aRolloff : 1.0f)])) {
            NSLog(@"egwAssetManager: loadAsset_Sound:fromFile:withParams: Failure assetifying sound input file '%@'. Failure instantiating egwPointSound asset.", resourceFile);
            goto ErrorCleanup;
        }
    } else {
        if(!([self loadAudioStream:&stream
                          fromFile:[[NSFileManager defaultManager] stringWithFileSystemRepresentation:(const char*)resourceFile length:(NSUInteger)strlen((const char*)resourceFile)]
                    withTransforms:(EGWuint)(sndParams ? sndParams->aTransforms : 0)]))
            goto ErrorCleanup;
        
        if(!(asset = (egwPointSound*)[[egwStreamedPointSound alloc] initWithIdentity:assetIdent
                                                                       decoderStream:&stream
                                                                        totalBuffers:(sndParams && sndParams->tBuffers ? sndParams->tBuffers : EGW_STRMSOUND_NUMBUFFERS)
                                                                          bufferSize:(sndParams && sndParams->bSize ? sndParams->bSize : EGW_STRMSOUND_BUFFERSIZE)
                                                                         soundRadius:(sndParams ? sndParams->aRadius : EGW_SFLT_MAX)
                                                                resonationTransforms:(sndParams ? sndParams->aTransforms : 0)
                                                                   resonationEffects:(sndParams ? &sndParams->aEffects : NULL)
                                                                   resonationRolloff:(sndParams ? sndParams->aRolloff : 1.0f)])) {
            NSLog(@"egwAssetManager: loadAsset_Sound:fromFile:withParams: Failure assetifying sound input file '%@'. Failure instantiating egwStreamedPointSound asset.", resourceFile);
            goto ErrorCleanup;
        }
    }
    
    if(![self loadAsset:assetIdent fromExisting:asset]) goto ErrorCleanup;
    else { [asset release]; asset = nil; } // asset is now owned by _assetsTable
    
    return YES;
    
ErrorCleanup:
    if(asset) [asset release];
    if(audio.data) egwAudioFree(&audio);
    if(stream) { ov_clear((OggVorbis_File*)stream); free(stream); } // Assuming stream is always an Ogg Vorbis file structure
    return NO;
}

// !!!: Texture asset loader.
// TODO: Texture asset streaming instance. -jw

- (BOOL)loadAsset_Texture:(NSString*)assetIdent fromFile:(const EGWchar*)resourceFile withParams:(void*)params {
    egwTexParams* texParams = (egwTexParams*)params;
    egwSurface surface; memset((void*)&surface, 0, sizeof(egwSurface));
    egwTexture* asset = nil;
    
    if(!([self loadSurface:&surface
                  fromFile:[[NSFileManager defaultManager] stringWithFileSystemRepresentation:(const char*)resourceFile length:(NSUInteger)strlen((const char*)resourceFile)]
            withTransforms:(EGWuint)((texParams ? texParams->tTransforms : 0) | (EGW_SURFACE_TRFM_ENSRLTETMS | EGW_SURFACE_TRFM_ENSRPOW2))]))
        goto ErrorCleanup;
    
    if(!(asset = [[egwTexture alloc] initWithIdentity:assetIdent
                                       textureSurface:&surface
                                 textureEnvironment:(texParams ? texParams->tEnvironment : 0)
                                  texturingTransforms:((texParams ? texParams->tTransforms : 0) | (EGW_SURFACE_TRFM_ENSRLTETMS | EGW_SURFACE_TRFM_ENSRPOW2))
                                      texturingFilter:(texParams ? texParams->tFiltering : 0)
                                       texturingSWrap:(texParams ? texParams->tSWrapping : 0)
                                       texturingTWrap:(texParams ? texParams->tTWrapping : 0)])) {
        NSLog(@"egwAssetManager: loadAsset_Texture:fromFile:withParams: Failure assetifying image input file '%@'. Failure instantiating egwTexture asset.", resourceFile);
        goto ErrorCleanup;
    }
    
    if(![self loadAsset:assetIdent fromExisting:asset]) goto ErrorCleanup;
    else { [asset release]; asset = nil; } // asset is now owned by _assetsTable
    
    return YES;
    
ErrorCleanup:
    if(asset) [asset release];
    if(surface.data) egwSrfcFree(&surface);
    return NO;
}

// !!!: WAV audio loader.
// TODO: WAV parser big-endian value flipping. -jw

- (BOOL)loadAudio_WAV:(egwAudio*)audio fromFile:(const EGWchar*)resourceFile withTransforms:(EGWuint)transforms {
    FILE* fin = NULL;
    egwWAVFileHeader header;
    
    if(!audio) {
        NSLog(@"egwAssetManager: loadAudio_WAV:fromFile:withTransforms: Failure opening sound input file '%s'. Invalid audio container object.", resourceFile);
        goto ErrorCleanup;
    } else memset((void*)audio, 0, sizeof(egwAudio));
    
    // Open file and read data, checking over consistency of file, ensurances, and filling out audio.
    
    if(!(fin = fopen((const char*)resourceFile, "rb"))) {
        NSLog(@"egwAssetManager: loadAudio_WAV:fromFile:withTransforms: Failure opening sound input file '%s'. File not found or cannot be opened.", resourceFile);
        goto ErrorCleanup;
    }
    
    fread(&header.chunkID, sizeof(header.chunkID), 1, fin);
    
    if(strncmp((const char*)&header.chunkID, "RIFF", 4) != 0) {
        NSLog(@"egwAssetManager: loadAudio_WAV:fromFile:withTransforms: Failure parsing sound input file '%s'. File type is not a WAV ('%c%c%c%c' tag, should be 'RIFF').", resourceFile, header.chunkID[0], header.chunkID[1], header.chunkID[2], header.chunkID[3]);
        goto ErrorCleanup;
    }
    
    fread(&header.fileSize, sizeof(header.fileSize), 1, fin);
    fread(&header.fileFormat, sizeof(header.fileFormat), 1, fin);
    
    if(strncmp((const char*)&header.fileFormat, "WAVE", 4) != 0) {
        NSLog(@"egwAssetManager: loadAudio_WAV:fromFile:withTransforms: Failure parsing sound input file '%s'. File type is not a WAV ('%c%c%c%c' tag, should be 'WAVE').", resourceFile, header.fileFormat[0], header.fileFormat[1], header.fileFormat[2], header.fileFormat[3]);
        goto ErrorCleanup;
    }
    
    fread(&header.subChunk1ID, sizeof(header.subChunk1ID), 1, fin);
    
    if(strncmp((const char*)&header.subChunk1ID, "fmt ", 4) != 0) {
        NSLog(@"egwAssetManager: loadAudio_WAV:fromFile:withTransforms: Failure parsing sound input file '%s'. File type is not a WAV ('%c%c%c%c' tag, should be 'fmt ').", resourceFile, header.subChunk1ID[0], header.subChunk1ID[1], header.subChunk1ID[2], header.subChunk1ID[3]);
        goto ErrorCleanup;
    }
    
    fread(&header.subChunk1Size, sizeof(header.subChunk1Size), 1, fin);
    
    if(header.subChunk1Size != 16) {
        NSLog(@"egwAssetManager: loadAudio_WAV:fromFile:withTransforms: Failure parsing sound input file '%s'. Invalid sub chunk size (%d bytes, should be 16).", resourceFile, header.subChunk1Size);
        goto ErrorCleanup;
    }
    
    fread(&header.audioFormat, sizeof(header.audioFormat), 1, fin);
    
    if(header.audioFormat != 1) {
        NSLog(@"egwAssetManager: loadAudio_WAV:fromFile:withTransforms: Failure parsing sound input file '%s'. Parser does not support compressed sound data.", resourceFile);
        goto ErrorCleanup;
    }
    
    fread(&header.numChannels, sizeof(header.numChannels), 1, fin);
    
    if(!(header.numChannels == 1 || header.numChannels == 2)) {
        NSLog(@"egwAssetManager: loadAudio_WAV:fromFile:withTransforms: Failure parsing sound input file '%s'. Parser does not support number of channels (%d, should be 1 or 2).", resourceFile, header.numChannels);
        goto ErrorCleanup;
    }
    
    fread(&header.sampleRate, sizeof(header.sampleRate), 1, fin);
    fread(&header.byteRate, sizeof(header.byteRate), 1, fin);
    fread(&header.blockAlign, sizeof(header.blockAlign), 1, fin);
    fread(&header.bitsPerSample, sizeof(header.bitsPerSample), 1, fin);
    
    if(!(header.bitsPerSample == 8 || header.bitsPerSample == 16)) {
        NSLog(@"egwAssetManager: loadAudio_WAV:fromFile:withTransforms: Failure parsing sound input file '%s'. Parser does not support bpc (%d, should be 8 or 16)", resourceFile, header.bitsPerSample);
        goto ErrorCleanup;
    }
    
    fread(&header.data.chunkID, sizeof(header.data.chunkID), 1, fin);
    fread(&header.data.chunkSize, sizeof(header.data.chunkSize), 1, fin);
    
    while(strncmp((const char*)&header.data.chunkID, "data", 4) != 0) {
        fseek(fin, header.data.chunkSize, SEEK_CUR);
        fread(&header.data.chunkID, sizeof(header.data.chunkID), 1, fin);
        fread(&header.data.chunkSize, sizeof(header.data.chunkSize), 1, fin);
    }
    
    if(header.numChannels == 1) {
        if(header.bitsPerSample == 8)
            audio->format = EGW_AUDIO_FRMT_MONOU8;
        else audio->format = EGW_AUDIO_FRMT_MONOS16;
    } else {
        if(header.bitsPerSample == 8)
            audio->format = EGW_AUDIO_FRMT_STEREOU8;
        else audio->format = EGW_AUDIO_FRMT_STEREOS16;
    }
    audio->count = (EGWuint32)header.data.chunkSize / (EGWuint32)header.blockAlign; // Technically the block alignment is the correct pitch
    audio->rate = (EGWuint32)header.sampleRate;
    audio->length = (EGWtime)audio->count / (EGWtime)audio->rate;
    audio->pitch = (EGWuint32)header.blockAlign;
    
    if(EGW_ENGINE_ASSETS_LOADERMSGS)
        NSLog(@"egwAssetManager: loadAudio_OGG:fromFile:withParams: Audio input file '%s' details: Channels: %d, Rate: %d, Slab size: %d", resourceFile, (audio->format & EGW_AUDIO_FRMT_EXSTEREO ? 2 : 1), audio->rate, (EGWuint)audio->pitch * (EGWuint)audio->count * (audio->format & EGW_AUDIO_FRMT_EXSTEREO ? 2 : 1));
    
    if((transforms & EGW_AUDIO_TRFM_EXENSURES) && ![self performAudioEnsurances:audio fromFile:resourceFile withTransforms:&transforms])
        goto ErrorCleanup;
    
    if(!(audio->data = (EGWbyte*)malloc((size_t)header.data.chunkSize))) {
        NSLog(@"egwAssetManager: loadAudio_WAV:fromFile:withTransforms: Failure parsing sound input file '%s'. Parser cannot allocate %d bytes for raw data buffer.", resourceFile, (size_t)header.data.chunkSize);
        goto ErrorCleanup;
    }
    
    // Read file data and close it up.
    
    fread(audio->data, sizeof(EGWbyte), header.data.chunkSize, fin);
    
    //egwEndianSwapbv((EGWbyte*)audio->data, (EGWbyte*)audio->data, header.bitsPerSample / 8, audio->pitch - (header.bitsPerSample / 8), audio->pitch - (header.bitsPerSample / 8), audio->count);
    
    fclose(fin); fin = NULL;
    
    // Perform any post-op transformations.
    
    // Perform pre-conversion modifications, conversions, and post-conversion modifications
    if((transforms & EGW_AUDIO_TRFM_EXDATAOPS) && ![self performAudioModifications:audio fromFile:resourceFile withTransforms:&transforms])
        goto ErrorCleanup;
    if((transforms & (EGW_AUDIO_TRFM_EXFORCES | EGW_AUDIO_TRFM_EXBPACKING)) && ![self performAudioConversions:audio fromFile:resourceFile withTransforms:&transforms])
        goto ErrorCleanup;
    if((transforms & EGW_AUDIO_TRFM_EXDATAOPS) && ![self performAudioModifications:audio fromFile:resourceFile withTransforms:&transforms])
        goto ErrorCleanup;
    
    return YES;
    
ErrorCleanup:
    if(audio) egwAudioFree(audio);
    if(fin) fclose(fin);
    return NO;
}

// !!!: OGG audio loader.

- (BOOL)loadAudio_OGG:(egwAudio*)audio fromFile:(const EGWchar*)resourceFile withTransforms:(EGWuint)transforms {
    NSString* errorString = nil;
    FILE* fin = NULL;
    OggVorbis_File* oggData = NULL;
    vorbis_info* oggInfo = NULL;
    int bitstream;
    EGWint packingB, rawChunkSize, rawChunkSizeAttain;
    EGWint totalRawBytesRemaining, rawBytesRead, totalRawBytesRead = 0;
    EGWuint totalSamplesRemaining, samplesRead, totalSamplesRead = 0;
    EGWuintptr scanline;
    
    // Phase 1: Prepare decoder & structures.
    // Phase 2: Read & transform data based on params.
    // Phase 3: ... PROFIT!
    
    // Prepare data structures and file for input.
    
    if(!audio) {
        NSLog(@"egwAssetManager: loadAudio_OGG:fromFile:withTransforms: Failure opening sound input file '%s'. Invalid audio container object.", resourceFile);
        goto ErrorCleanup;
    } else memset((void*)audio, 0, sizeof(egwAudio));
    
    if(!(fin = fopen((const char*)resourceFile, "rb"))) {
        NSLog(@"egwAssetManager: loadAudio_OGG:fromFile:withParams: Failure opening sound input file '%s'. File not found or cannot be opened.", resourceFile);
        goto ErrorCleanup;
    }
    
    if(!(oggData = (OggVorbis_File*)malloc(sizeof(OggVorbis_File))) ||
       egwIsOggVorbisError(ov_open(fin, oggData, NULL, 0), &errorString)) {
        NSLog(@"egwAssetManager: loadAudio_OGG:fromFile:withParams: Failure opening sound input file '%s'. OVError: %@", resourceFile, (errorString ? (const char*)errorString : (const char*)"No error."));
        goto ErrorCleanup;
    }
    
    // OV will control file close from here
    fin = NULL;
    
    // Read the info structure, which defines the initial audio props.
    
    if(!(oggInfo = ov_info(oggData, -1))) {
        NSLog(@"egwAssetManager: loadAudio_OGG:fromFile:withParams: Failure accessing Vorbis data info structure for sound input file '%s'.", resourceFile);
        goto ErrorCleanup;
    }
    
    totalRawBytesRemaining = (EGWint)ov_pcm_total(oggData, -1) * (EGWint)sizeof(EGWint16) * (EGWint)oggInfo->channels;
    
    if(EGW_ENGINE_ASSETS_LOADERMSGS)
        NSLog(@"egwAssetManager: loadAudio_OGG:fromFile:withParams: Audio input file '%s' details: Bit-rate (lower/nominal/upper): %d/%d/%d, Channels: %d, Rate: %d, Slab size: %d.", resourceFile, oggInfo->bitrate_lower, oggInfo->bitrate_nominal, oggInfo->bitrate_upper, oggInfo->channels, oggInfo->rate, totalRawBytesRemaining);
    
    // Fill in audio container.
    
    audio->count = (EGWuint32)(totalSamplesRemaining = (EGWuint)ov_pcm_total(oggData, -1));
    audio->rate = (EGWuint32)oggInfo->rate;
    audio->length = (EGWtime)audio->count / (EGWtime)audio->rate;
    
    switch(oggInfo->channels) { // NOTE: Ogg vorbis sound data is always signed 16-bit. -jw
        case 1: { audio->format = EGW_AUDIO_FRMT_MONOS16; audio->pitch = (EGWuint32)(rawChunkSize = 2); } break;
        case 2: { audio->format = EGW_AUDIO_FRMT_STEREOS16; audio->pitch = (EGWuint32)(rawChunkSize = 4); } break;
        default: {
            NSLog(@"egwAssetManager: loadAudio_OGG:fromFile:withParams: Audio input file '%s' has an unsupported channel count (%d).", resourceFile, oggInfo->channels);
            goto ErrorCleanup;
        } break;
    }
    
    // Handle custom byte packing on load
    packingB = egwBytePackingFromAudioTrfm(transforms, EGW_AUDIO_DFLTBPACKING);
    transforms &= ~EGW_AUDIO_TRFM_EXBPACKING;
    if(packingB > 1)
        audio->pitch = egwRoundUpMultipleui32(audio->pitch, packingB);
    
    if((transforms & EGW_AUDIO_TRFM_EXENSURES) && ![self performAudioEnsurances:audio fromFile:resourceFile withTransforms:&transforms])
        goto ErrorCleanup;
    
    if(!(audio->data = (EGWbyte*)malloc((size_t)audio->pitch * (size_t)audio->count))) {
        NSLog(@"egwAssetManager: loadAudio_OGG:fromFile:withParams: Failure allocating %d bytes for audio data buffer for sound input file '%s'.", ((size_t)audio->pitch * (size_t)audio->count), resourceFile);
        goto ErrorCleanup;
    }
    
    // Read the audio data.
    // NOTE: Fancy footwork has to be done to account for reading a # of bytes in sequence that may be less than the size of an actual sample. -jw
    
    scanline = (EGWuintptr)audio->data;
    totalSamplesRead = rawChunkSizeAttain = 0;
    
    do {
        rawBytesRead =
            ov_read(oggData,        // OggVorbis_File pointer
                (char*)scanline,    // Raw data buffer (offsetted)
                (int)(packingB == 1 ?
                      totalRawBytesRemaining
                      : rawChunkSize - rawChunkSizeAttain), // Read chunk size (bytes)
                // NOTE: These three values were removed for Tremor library. -jw
                //0,                  // Endianness (0-little, 1-big)
                //sizeof(short),      // Word size (bytes)
                //1,                  // Data sign (0-unsigned, 1-signed)
                &bitstream);        // Bitstream positioning
        
        if(rawBytesRead > 0) {
            totalRawBytesRemaining -= rawBytesRead;
            totalRawBytesRead += rawBytesRead;
            rawChunkSizeAttain += rawBytesRead;
            
            if(rawChunkSizeAttain >= rawChunkSize) { // Ensures entire sample is read before incrementing samples' counters
                samplesRead = (EGWuint)(rawChunkSizeAttain / rawChunkSize); // Should always be 1 when packing != 1
                rawChunkSizeAttain %= rawChunkSize; // Should always be 0 when packing != 1
                totalSamplesRead += samplesRead;
                totalSamplesRemaining -= samplesRead;
                scanline += (EGWuintptr)((EGWuint)audio->pitch * (EGWuint)samplesRead) + (EGWuintptr)rawChunkSizeAttain;
            } else
                scanline += (EGWuintptr)rawBytesRead;
        } else if(rawBytesRead < 0 && egwIsOggVorbisError(rawBytesRead, &errorString)) {
            NSLog(@"egwAssetManager: loadAudio_OGG:fromFile:withParams: Failure decoding stream after %d samples read from sound input file '%s'. OVError: %@", totalSamplesRead, resourceFile, (errorString ? errorString : @"No error."));
            goto ErrorCleanup;
        }
    } while(rawBytesRead > 0 && totalRawBytesRemaining && totalSamplesRemaining);
    
    if(totalSamplesRemaining) { // Check for missing end of file
        NSLog(@"egwAssetManager: loadAudio_OGG:fromFile:withParams: Warning: Total samples read (%d) from sound input file '%s' does not match total samples reported (%d). Filling remaining buffer with zeros.", totalSamplesRead, resourceFile, totalSamplesRead + totalSamplesRemaining);
        memset((void*)((EGWuintptr)audio->data + (EGWuintptr)(totalSamplesRead * (EGWint)audio->pitch)), 0, totalSamplesRemaining * (EGWint)audio->pitch);
    }
    
    // Done with the file & transfer, close 'em up.
    
    ov_clear(oggData);
    free((void*)oggData); oggData = NULL; oggInfo = NULL;
    
    // Perform any post-op transformations.
    
    // Perform pre-conversion modifications, conversions, and post-conversion modifications
    if((transforms & EGW_AUDIO_TRFM_EXDATAOPS) && ![self performAudioModifications:audio fromFile:resourceFile withTransforms:&transforms])
        goto ErrorCleanup;
    if((transforms & (EGW_AUDIO_TRFM_EXFORCES | EGW_AUDIO_TRFM_EXBPACKING)) && ![self performAudioConversions:audio fromFile:resourceFile withTransforms:&transforms])
        goto ErrorCleanup;
    if((transforms & EGW_AUDIO_TRFM_EXDATAOPS) && ![self performAudioModifications:audio fromFile:resourceFile withTransforms:&transforms])
        goto ErrorCleanup;
    
    return YES;
    
ErrorCleanup:
    if(audio) egwAudioFree(audio);
    if(oggData) { ov_clear(oggData); free((void*)oggData); }
    if(fin) fclose(fin);
    return NO;
}

// !!!: OGG audio stream loader.

- (BOOL)loadAudioStream_OGG:(void**)stream fromFile:(const EGWchar*)resourceFile withTransforms:(EGWuint)transforms {
    NSString* errorString = nil;
    FILE* fin = NULL;
    OggVorbis_File* oggData = NULL;
    vorbis_info* oggInfo = NULL;
    egwAudio audio;
    
    if(!stream) {
        NSLog(@"egwAssetManager: loadAudioStream_OGG:fromFile:withTransforms: Failure opening sound input file '%s'. Invalid audio stream structure object.", resourceFile);
        goto ErrorCleanup;
    }
    
    if(!(fin = fopen((const char*)resourceFile, "rb"))) {
        NSLog(@"egwAssetManager: loadAudioStream_OGG:fromFile:withParams: Failure opening sound input file '%s'. File not found or cannot be opened.", resourceFile);
        goto ErrorCleanup;
    }
    
    if(!(oggData = (OggVorbis_File*)malloc(sizeof(OggVorbis_File))) ||
       egwIsOggVorbisError(ov_open(fin, oggData, NULL, 0), &errorString)) {
        NSLog(@"egwAssetManager: loadAudioStream_OGG:fromFile:withParams: Failure opening sound input file '%s'. OVError: %@", resourceFile, (errorString ? (const char*)errorString : (const char*)"No error."));
        goto ErrorCleanup;
    }
    
    // OV will control file close from here
    fin = NULL;
    
    // Read the info structure, which defines the initial audio props.
    
    if(!(oggInfo = ov_info(oggData, -1))) {
        NSLog(@"egwAssetManager: loadAudioStream_OGG:fromFile:withParams: Failure accessing Vorbis data info structure for sound input file '%s'.", resourceFile);
        goto ErrorCleanup;
    }
    
    if(EGW_ENGINE_ASSETS_LOADERMSGS)
        NSLog(@"egwAssetManager: loadAudioStream_OGG:fromFile:withParams: Audio input file '%s' details: Bit-rate (lower/nominal/upper): %d/%d/%d, Channels: %d, Rate: %d, Slab size: %d.", resourceFile, oggInfo->bitrate_lower, oggInfo->bitrate_nominal, oggInfo->bitrate_upper, oggInfo->channels, oggInfo->rate, (EGWuint)ov_pcm_total(oggData, -1) * (EGWuint)sizeof(EGWint16) * (EGWuint)oggInfo->channels);
    
    // Fill in audio container.
    
    switch(oggInfo->channels) { // NOTE: Ogg vorbis sound data is always signed 16-bit. -jw
        case 1: { audio.format = EGW_AUDIO_FRMT_MONOS16; audio.pitch = 2; } break;
        case 2: { audio.format = EGW_AUDIO_FRMT_STEREOS16; audio.pitch = 4; } break;
        default: {
            NSLog(@"egwAssetManager: loadAudioStream_OGG:fromFile:withParams: Audio input file '%s' has an unsupported channel count (%d).", resourceFile, oggInfo->channels);
            goto ErrorCleanup;
        } break;
    }
    
    audio.count = (EGWuint32)ov_pcm_total(oggData, -1);
    audio.rate = (EGWuint32)oggInfo->rate;
    audio.length = (EGWtime)audio.count / (EGWtime)audio.rate;
    
    if((transforms & EGW_AUDIO_TRFM_EXENSURES) && ![self performAudioEnsurances:&audio fromFile:resourceFile withTransforms:&transforms])
        goto ErrorCleanup;
    
    if(transforms & (EGW_AUDIO_TRFM_EXDATAOPS | EGW_AUDIO_TRFM_EXFORCES | EGW_AUDIO_TRFM_EXBPACKING)) {
        NSLog(@"egwAssetManager: loadAudioStream_OGG:fromFile:withParams: Warning while parsing audio input file '%s'. Data operations and forced conversions not supported for streamed data.", resourceFile);
        transforms &= ~(EGW_AUDIO_TRFM_EXDATAOPS | EGW_AUDIO_TRFM_EXFORCES | EGW_AUDIO_TRFM_EXBPACKING);
    }
    
    *stream = (void*)oggData;
    oggData = NULL;
    
    return YES;
    
ErrorCleanup:
    if(oggData) { ov_clear(oggData); free((void*)oggData); }
    if(fin) fclose(fin);
    return NO;
}

// !!!: TTF glyph map loader.

- (BOOL)loadGlyphMap_TTF:(egwAMGlyphSet*)mapset fromFile:(const EGWchar*)resourceFile withEffects:(EGWuint)effects pointSize:(EGWsingle)ptSize {
    NSString* errorString = nil;
    FT_Face face;
    FT_Int32 loadFlags = FT_LOAD_DEFAULT;
    FT_Render_Mode renderFlags = FT_RENDER_MODE_NORMAL;
    egwArray kernTable; memset((void*)&kernTable, 0, sizeof(egwArray));
    
    if(!egwArrayInit(&kernTable, NULL, sizeof(egwAMKernSet), 10, EGW_ARRAY_FLG_DFLT) ||
       egwIsFreeTypeError(FT_New_Face(_ftLibrary, (const char*)resourceFile, 0, &face), &errorString)) {
        NSLog(@"egwAssetManager: loadGlyphMap_TTF:fromFile:withEffects:pointSize: Failure opening font input file '%s'. Invalid glyph map container object. FTError: %@", resourceFile, (errorString ? errorString : @"FT_Err_Ok."));
        goto ErrorCleanup;
    }
    
    {   EGWuint dpi;
        
        switch(effects & EGW_FONT_EFCT_EXDPI) {
            case EGW_FONT_EFCT_DPI72: { dpi = 72; } break;
            case EGW_FONT_EFCT_DPI75: { dpi = 75; } break;
            default:
            case EGW_FONT_EFCT_DPI96: { dpi = 96; } break;
            case EGW_FONT_EFCT_DPI192: { dpi = 192; } break;
        }
        
        if(egwIsFreeTypeError(FT_Set_Char_Size(face, 0, (EGWuint)(ptSize * 64.0), dpi, dpi), &errorString)) {
            NSLog(@"egwAssetManager: loadGlyphMap_TTF:fromFile:withEffects:pointSize: Failure setting DPI resolution and/or point size for font instance for font input file '%s'. FTError: %@", resourceFile, (errorString ? errorString : @"FT_Err_Ok."));
            goto ErrorCleanup;
        }
    }
    
    {   FT_Matrix matrix, transform;
        
        matrix.xx = (FT_Fixed)(1.0 * 0x10000);
        matrix.xy = (FT_Fixed)(0.0 * 0x10000);
        matrix.yx = (FT_Fixed)(0.0 * 0x10000);
        matrix.yy = (FT_Fixed)(1.0 * 0x10000);
        
        if(effects & EGW_FONT_EFCT_BOLD) {
            transform.xx = (FT_Fixed)(1.2 * 0x10000);
            transform.xy = (FT_Fixed)(0.0 * 0x10000);
            transform.yx = (FT_Fixed)(0.0 * 0x10000);
            transform.yy = (FT_Fixed)(1.2 * 0x10000);
            FT_Matrix_Multiply(&matrix, &transform);
            memcpy((void*)&matrix, (const void*)&transform, sizeof(FT_Matrix));
        }
        
        if(effects & EGW_FONT_EFCT_ITALIC) {
            transform.xx = (FT_Fixed)(1.0 * 0x10000);
            transform.xy = (FT_Fixed)(0.2 * 0x10000);
            transform.yx = (FT_Fixed)(0.0 * 0x10000);
            transform.yy = (FT_Fixed)(1.0 * 0x10000);
            FT_Matrix_Multiply(&matrix, &transform);
            memcpy((void*)&matrix, (const void*)&transform, sizeof(FT_Matrix));
        }
        
        if(effects & EGW_FONT_EFCT_UPSIDEDOWN) {
            transform.xx = (FT_Fixed)(1.0 * 0x10000);
            transform.xy = (FT_Fixed)(0.0 * 0x10000);
            transform.yx = (FT_Fixed)(0.0 * 0x10000);
            transform.yy = (FT_Fixed)(-1.0 * 0x10000);
            FT_Matrix_Multiply(&matrix, &transform);
            memcpy((void*)&matrix, (const void*)&transform, sizeof(FT_Matrix));
        }
        
        if(effects & EGW_FONT_EFCT_BACKWARDS) {
            transform.xx = (FT_Fixed)(-1.0 * 0x10000);
            transform.xy = (FT_Fixed)(0.0 * 0x10000);
            transform.yx = (FT_Fixed)(0.0 * 0x10000);
            transform.yy = (FT_Fixed)(1.0 * 0x10000);
            FT_Matrix_Multiply(&matrix, &transform);
            memcpy((void*)&matrix, (const void*)&transform, sizeof(FT_Matrix));
        }
        
        FT_Set_Transform(face, &matrix, NULL);
    }
    
    for(EGWchar charIndex = 32; charIndex <= 126; ++charIndex) {
        EGWint yMax;
        FT_UInt glyphIndex, glyphIndexNext;
        
        if(glyphIndex = FT_Get_Char_Index(face, charIndex)) {
            if(!egwIsFreeTypeError(FT_Load_Glyph(face, glyphIndex, loadFlags), &errorString)) {
                if(!egwIsFreeTypeError(FT_Render_Glyph(face->glyph, renderFlags), &errorString)) {
                    if(charIndex > 32) {
                        egwBGlyph* glyph = &mapset->glyphs[charIndex - 33];
                        
                        // Setup glyph contents (+63/64 rounds up to next 64 boundary)
                        glyph->gWidth = (EGWuint8)face->glyph->bitmap.width;
                        glyph->gHeight = (EGWuint8)face->glyph->bitmap.rows;
                        glyph->xOffset = (EGWint8)((face->glyph->metrics.horiBearingX + (face->glyph->metrics.horiBearingX >= 0 ? 63 : -63)) / 64);
                        glyph->yOffset = (EGWint8)((face->glyph->metrics.horiBearingY + (face->glyph->metrics.horiBearingY >= 0 ? 63 : -63)) / 64) - glyph->gHeight;
                        glyph->xAdvance = (EGWuint8)(((egwMax2i(face->glyph->metrics.horiAdvance, 0) - (EGWint)0) + 63) / 64); // Last 0 was originally xMin in FT1 imp
                        
                        // Track line height (max height encountered) and line offset (max yoffset encountered)
                        yMax = (EGWint)glyph->gHeight + (EGWint)glyph->yOffset;
                        if(yMax > (EGWint)(mapset->lHeight)) mapset->lHeight = (EGWuint8)yMax;
                        if(glyph->yOffset < mapset->lOffset) mapset->lOffset = glyph->yOffset;
                        
                        if(glyph->gaData = (egwColorGS*)malloc((size_t)face->glyph->bitmap.width * (size_t)face->glyph->bitmap.rows * sizeof(egwColorGS))) {
                            egwColorGS* adr1 = glyph->gaData;
                            EGWbyte* adr2 = NULL;
                            
                            // Blit bitmap to GS surface
                            for(EGWint row = 0; row < (EGWint)face->glyph->bitmap.rows; ++row) {
                                adr2 = (EGWbyte*)((EGWuintptr)(face->glyph->bitmap.buffer) + (EGWuintptr)(row * face->glyph->bitmap.pitch));
                                
                                for(EGWint col = 0; col < (EGWint)face->glyph->bitmap.width; ++col) {
                                    adr1->channel.l = *adr2;
                                    
                                    adr1 = (egwColorGS*)((EGWuintptr)adr1 + (EGWuintptr)sizeof(egwColorGS));
                                    adr2 = (EGWbyte*)((EGWuintptr)adr2 + (EGWuintptr)sizeof(EGWbyte));
                                }
                            }
                        }
                        
                        glyph->hasKerning = NO;
                        glyph->kernIndex = 0;
                        
                        for(EGWchar charKernIndex = 32; charKernIndex <= 126; ++charKernIndex) {
                            if(glyphIndexNext = FT_Get_Char_Index(face, charKernIndex)) {
                                FT_Vector kerning = { 0 };
                                if(0 == FT_Get_Kerning(face, glyphIndex, glyphIndexNext, FT_KERNING_DEFAULT, &kerning) &&
                                   kerning.x != 0) {
                                    if(!glyph->hasKerning) {
                                        glyph->hasKerning = YES;
                                        glyph->kernIndex = kernTable.eCount;
                                    }
                                    
                                    egwAMKernSet kern;
                                    kern.lChar = charIndex;
                                    kern.rChar = charKernIndex;
                                    kern.xOffset = (kerning.x + (kerning.x >= 0 ? 63 : -63)) / 64;
                                    egwArrayAddTail(&kernTable, (const EGWbyte*)&kern);
                                }
                            } // No error is else displayed, as to not choke up the output log
                        }
                    } else { // Space is only used for the advance width
                        mapset->sAdvance = (egwMax2i(face->glyph->metrics.horiAdvance, 0) + 63) / 64; // round up to the next 64 boundary
                    }
                } else {
                    NSLog(@"egwAssetManager: loadGlyphMap_TTF:fromFile:withEffects:pointSize: Failure rendering glyph mapped to '%c' (%d) for font input file '%s'. FTError: %@", charIndex, (EGWint)charIndex, resourceFile, (errorString ? errorString : @"FT_Err_Ok."));
                    continue;
                }
            } else {
                NSLog(@"egwAssetManager: loadGlyphMap_TTF:fromFile:withEffects:pointSize: Failure loading glyph mapped to '%c' (%d) for font input file '%s'. FTError: %@", charIndex, (EGWint)charIndex, resourceFile, (errorString ? errorString : @"FT_Err_Ok."));
                continue;
            }
        }
    }
    
    mapset->lHeight = (EGWuint8)egwAbsi((EGWint)mapset->lHeight - (EGWint)mapset->lOffset);
    mapset->lOffset = -mapset->lOffset;
    
    // Special case with upside down rasterization
    if(effects & EGW_FONT_EFCT_UPSIDEDOWN) {
        for(EGWchar charIndex = 33; charIndex <= 126; ++charIndex) {
            egwBGlyph* glyph = &mapset->glyphs[charIndex - 33];
            glyph->yOffset += mapset->lHeight - mapset->lOffset - glyph->yOffset - glyph->gHeight - mapset->lOffset - glyph->yOffset;
        }
    }
    
    // Special case with backwards rasterization
    if(effects & EGW_FONT_EFCT_UPSIDEDOWN) {
        for(EGWchar charIndex = 33; charIndex <= 126; ++charIndex) {
            egwBGlyph* glyph = &mapset->glyphs[charIndex - 33];
            glyph->xOffset = glyph->xAdvance - glyph->xOffset - glyph->gWidth - glyph->xOffset;
        }
    }
    
    // Cheating here and assigning the kerning table from the array over.
    if(kernTable.eCount > 0) {
        mapset->kernSets = kernTable.eCount;
        mapset->kerns = (egwAMKernSet*)realloc((void*)kernTable.rData, (size_t)mapset->kernSets * sizeof(egwAMKernSet));
        kernTable.eCount = kernTable.eMaxCount = 0;
        kernTable.rData = NULL;
    }
    
    // Transfer complete, close it up.
    egwArrayFree(&kernTable);
    FT_Done_Face(face);
    
    return YES;
    
ErrorCleanup:
    egwArrayFree(&kernTable);
    FT_Done_Face(face);
    for(EGWchar charIndex = 33; charIndex <= 126; ++charIndex) {
        if(mapset->glyphs[charIndex - 33].gaData) {
            free((void*)(mapset->glyphs[charIndex - 33].gaData));
            mapset->glyphs[charIndex - 33].gaData = NULL;
        }
    }
    if(mapset->kerns) {
        free((void*)mapset->kerns);
        mapset->kerns = NULL;
    }
    
    return NO;
}

// !!!: BMP surface loader.
// TODO: BMP parser big-endian value flipping. -jw

- (BOOL)loadSurface_BMP:(egwSurface*)surface fromFile:(const EGWchar*)resourceFile withTransforms:(EGWuint)transforms {
    FILE* fin = NULL;
    egwBMPFileHeader header;
    EGWuint16 packingB;
    
    if(!surface) {
        NSLog(@"egwAssetManager: loadSurface_BMP:fromFile:withTransforms: Failure opening image input file '%s'. Invalid surface container object.", resourceFile);
        goto ErrorCleanup;
    } else memset((void*)surface, 0, sizeof(egwSurface));
    
    // Open file and read data, checking over consistency of file, ensurances, and filling out surface.
    
    if(!(fin = fopen((const char*)resourceFile, "rb"))) {
        NSLog(@"egwAssetManager: loadSurface_BMP:fromFile:withTransforms: Failure opening image input file '%s'. File not found or cannot be opened.", resourceFile);
        goto ErrorCleanup;
    }
    
    fread(&header, sizeof(egwBMPFileHeader), 1, fin);
    
    if(strncmp((const char*)&header.type[0], "BM", 2) != 0) {
        NSLog(@"egwAssetManager: loadSurface_BMP:fromFile:withTransforms: Failure parsing image input file '%s'. File type is not a BMP ('%c%c' tag, should be 'BM').", resourceFile, header.type[0], header.type[1]);
        goto ErrorCleanup;
    }
    
    if(header.reserved) {
        NSLog(@"egwAssetManager: loadSurface_BMP:fromFile:withTransforms: Failure parsing image input file '%s'. Invalid reserved bytes (0x%p, should be 0x0).", resourceFile, header.reserved);
        goto ErrorCleanup;
    }
    
    if(header.bitmapOffset != 54) {
        NSLog(@"egwAssetManager: loadSurface_BMP:fromFile:withTransforms: Failure parsing image input file '%s'. Invalid bitmap offset (%d bytes, should be 54).", resourceFile, header.bitmapOffset);
        goto ErrorCleanup;
    }
    
    if(header.headerSize != 40) {
        NSLog(@"egwAssetManager: loadSurface_BMP:fromFile:withTransforms: Failure parsing image input file '%s'. Invalid header size (%d bytes, should be 40).", resourceFile, header.headerSize);
        goto ErrorCleanup;
    }
    
    if(header.width < 1 || header.width > EGW_UINT16_MAX || header.height < 1 || header.height > EGW_UINT16_MAX) {
        NSLog(@"egwAssetManager: loadSurface_BMP:fromFile:withTransforms: Failure parsing image input file '%s'. Invalid width and height size (%dx%d pixels, should possibly be %dx%d).", resourceFile, header.width, header.height, egwClampui((EGWuint)header.width, 1, EGW_UINT16_MAX), egwClampui((EGWuint)header.width, 1, EGW_UINT16_MAX));
        goto ErrorCleanup;
    }
    
    if(header.planes != 1) {
        NSLog(@"egwAssetManager: loadSurface_BMP:fromFile:withTransforms: Failure parsing image input file '%s'. Invalid number of planes (%d, should be 1).", resourceFile, header.planes);
        goto ErrorCleanup;
    }
    
    if(header.bitsPerPixel != 24) {
        NSLog(@"egwAssetManager: loadSurface_BMP:fromFile:withTransforms: Failure parsing image input file '%s'. Parser does not support palleted image data.", resourceFile);
        goto ErrorCleanup;
    }
    
    if(header.compression != 0) {
        NSLog(@"egwAssetManager: loadSurface_BMP:fromFile:withTransforms: Failure parsing image input file '%s'. Parser does not support compressed image data.", resourceFile);
        goto ErrorCleanup;
    }
    
    surface->format = EGW_SURFACE_FRMT_R8G8B8; // Technically the surface is B8G8R8, but an implicit coversion is used during transformations
    surface->size.span.width = (EGWuint16)header.width;
    surface->size.span.height = (EGWuint16)header.height;
    surface->pitch = (EGWuint32)(((EGWuint)(surface->format & EGW_SURFACE_FRMT_EXBPP) * (EGWuint)surface->size.span.width) >> 3);
    
    // Figure out the byte padding in use
    for(packingB = 1; packingB <= 8192; packingB <<= 1) {
        if(packingB > 1)
            surface->pitch = egwRoundUpMultipleui32(surface->pitch, packingB);
        if(surface->pitch * (EGWuint32)surface->size.span.height == (EGWuint32)header.bitmapSize)
            break;
    }
    
    if(packingB > 8192) {
        NSLog(@"egwAssetManager: loadSurface_BMP:fromFile:withTransforms: Failure parsing image input file '%s'. Parser cannot determine byte packing of image data.", resourceFile);
        goto ErrorCleanup;
    }
    
    if(EGW_ENGINE_ASSETS_LOADERMSGS)
        NSLog(@"egwAssetManager: loadAsset_BMP:fromFile:withTransforms: Surface input file '%s' details: Width: %d, Height: %d, Depth: %d, Channels: %d, Type: %p, Slab size: %d.", resourceFile, surface->size.span.width, surface->size.span.height, 8, 3, surface->format, (EGWuint)surface->pitch * (EGWuint)surface->size.span.height);
    
    if((transforms & EGW_SURFACE_TRFM_EXENSURES) && ![self performSurfaceEnsurances:surface fromFile:resourceFile withTransforms:&transforms])
        goto ErrorCleanup;
    
    if(!(surface->data = (EGWbyte*)malloc((size_t)header.bitmapSize))) {
        NSLog(@"egwAssetManager: loadSurface_BMP:fromFile:withTransforms: Failure parsing image input file '%s'. Parser cannot allocate %d bytes for raw data buffer.", resourceFile, header.bitmapSize);
        goto ErrorCleanup;
    }
    
    // Read file data and close it up.
    
    fread(surface->data, sizeof(EGWbyte), header.bitmapSize, fin);
    
    fclose(fin); fin = NULL;
    
    // Perform any post-op transformations.
    
    // BMP files are always B8G8R8, so need to automatically do a RB swap unless the swap flag is high (in which case nothing is done)
    if(transforms & EGW_SURFACE_TRFM_SWAPRB)
        transforms &= ~EGW_SURFACE_TRFM_SWAPRB;
    else
        transforms |= EGW_SURFACE_TRFM_SWAPRB;
    
    // Perform pre-conversion modifications, conversions, and post-conversion modifications
    if((transforms & EGW_SURFACE_TRFM_EXDATAOPS) && ![self performSurfaceModifications:surface fromFile:resourceFile withTransforms:&transforms])
        goto ErrorCleanup;
    if((transforms & (EGW_SURFACE_TRFM_EXFORCES | EGW_SURFACE_TRFM_EXBPACKING)) && ![self performSurfaceConversions:surface fromFile:resourceFile withTransforms:&transforms])
        goto ErrorCleanup;
    if((transforms & EGW_SURFACE_TRFM_EXDATAOPS) && ![self performSurfaceModifications:surface fromFile:resourceFile withTransforms:&transforms])
        goto ErrorCleanup;
    
    return YES;
    
ErrorCleanup:
    if(surface) egwSrfcFree(surface);
    if(fin) fclose(fin);
    return NO;
}

// !!!: PNG surface loader.

- (BOOL)loadSurface_PNG:(egwSurface*)surface fromFile:(const EGWchar*)resourceFile withTransforms:(EGWuint)transforms {
    FILE* fin = NULL;
    png_structp lpngFInst = NULL;
    png_infop lpngFInfo = NULL, lpngFEInfo = NULL;
    png_uint_32 height, width, pitch;
    png_byte depth, chnls, type;
    EGWbyte** rows = NULL;
    EGWuint row;
    EGWint packingB;
    
    if(!surface) {
        NSLog(@"egwAssetManager: loadSurface_PNG:fromFile:withTransforms: Failure opening image input file '%s'. Invalid surface container object.", resourceFile);
        goto ErrorCleanup;
    } else memset((void*)surface, 0, sizeof(egwSurface));
    
    // Open file and read data, checking over consistency of file, ensurances, and filling out surface.
    
    if(!(fin = fopen((const char*)resourceFile, "rb"))) {
        NSLog(@"egwAssetManager: loadSurface_PNG:fromFile:withTransforms: Failure opening image input file '%s'. File not found or cannot be opened.", resourceFile);
        goto ErrorCleanup;
    }
    
    {   png_byte pngHeader[8];
        fread(&pngHeader[0], sizeof(png_byte), 8, fin); rewind(fin);    // Rewind so libpng doesn't need told we read 8 bytes...
        if(png_sig_cmp(&pngHeader[0], 0, 8)) {
            NSLog(@"egwAssetManager: loadSurface_PNG:fromFile:withTransforms: Failure parsing image input file '%s'. File type is not a PNG ('%c%c%c%c' tag, should be '.PNG').", resourceFile, pngHeader[0], pngHeader[1], pngHeader[2], pngHeader[3]);
            goto ErrorCleanup;
        }
    }
    
    if(!(lpngFInst = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL))) {
        NSLog(@"egwAssetManager: loadSurface_PNG:fromFile:withTransforms: Failure allocating libpng primary data structure for image input file '%s'.", resourceFile);
        goto ErrorCleanup;
    }
    
    if(!(lpngFInfo = png_create_info_struct(lpngFInst))) {
        NSLog(@"egwAssetManager: loadSurface_PNG:fromFile:withTransforms: Failure allocating libpng beginning info structure for image input file '%s'.", resourceFile);
        goto ErrorCleanup;
    }
    
    if(!(lpngFEInfo = png_create_info_struct(lpngFInst))) {
        NSLog(@"egwAssetManager: loadSurface_PNG:fromFile:withTransforms: Failure allocating libpng ending info structure for image input file '%s'.", resourceFile);
        goto ErrorCleanup;
    }
    
    // When libpng freaks out, it performs a long-jump all the way back to
    // the contents of this if statement.
    if(setjmp(png_jmpbuf(lpngFInst))) {
        // Removed png_error call here, was causing inf loop. Details: http://profusepower.dnsdojo.com/changeset/389
        NSLog(@"egwAssetManager: loadSurface_PNG:fromFile:withTransforms: Internal libpng error, see debug output.");
        goto ErrorCleanup;
    }
    
    png_init_io(lpngFInst, fin);
    
    // Read the info structure, which defines the [initial] image props. Then do
    // a slew of transformations on data to get it to context expectations.
    
    png_read_info(lpngFInst, lpngFInfo);
    width = png_get_image_width(lpngFInst, lpngFInfo);
    height = png_get_image_height(lpngFInst, lpngFInfo);
    pitch = png_get_rowbytes(lpngFInst, lpngFInfo);
    depth = png_get_bit_depth(lpngFInst, lpngFInfo);
    chnls = png_get_channels(lpngFInst, lpngFInfo);
    type = png_get_color_type(lpngFInst, lpngFInfo);
    
    if(EGW_ENGINE_ASSETS_LOADERMSGS)
        NSLog(@"egwAssetManager: loadAsset_PNG:fromFile:withTransforms: Surface input file '%s' details: Width: %d, Height: %d, Depth: %d, Channels: %d, Type: %p, Slab size: %d.", resourceFile, width, height, depth, chnls, type, pitch * height);
    
    if(type & PNG_COLOR_MASK_PALETTE) {     // Don't want to deal with palletes...
        png_set_palette_to_rgb(lpngFInst);
        type |= PNG_COLOR_MASK_COLOR;
    }
    
    if(depth == 16) {                       // Nor 16-bit data...
        png_set_strip_16(lpngFInst);
        depth = 8;
    }
    
    if(depth < 8 &&                         // Nor <8-bit data...
       (!(type & PNG_COLOR_MASK_COLOR) || (transforms & EGW_SURFACE_TRFM_FORCEGS))) {
        png_set_gray_1_2_4_to_8(lpngFInst);
        png_set_packing(lpngFInst);
    }
    
    // NOTE: libpng does transforms in steps that may not match ours (and I'm too lazy to double check), so we're limiting to just ones we know will work correctly. The following have since been removed so that our transform steps are correctly performed as documented. -jw
    
    //if((transforms & EGW_SURFACE_TRFM_FORCERGB) && !(type & PNG_COLOR_MASK_COLOR))
    //    png_set_gray_to_rgb(lpngFInst);
    
    //if((transforms & EGW_SURFACE_TRFM_FORCEGS) && (type & PNG_COLOR_MASK_COLOR))
    //    png_set_rgb_to_gray_fixed(lpngFInst, 1, -1, -1);
    
    //if((transforms & EGW_SURFACE_TRFM_INVERTGS) && (!(type & PNG_COLOR_MASK_COLOR) || transforms & EGW_SURFACE_TRFM_FORCEGS))
    //    png_set_invert_mono(lpngFInst);
    
    //if((transforms & EGW_SURFACE_TRFM_SWAPRB) && ((type & PNG_COLOR_MASK_COLOR) || (transforms & EGW_SURFACE_TRFM_FORCERGB)))
    //    png_set_bgr(lpngFInst);
    
    //if((transforms & EGW_SURFACE_TRFM_FORCENOAC) && (type & PNG_COLOR_MASK_ALPHA))
    //    png_set_strip_alpha(lpngFInst);
    
    //if((transforms & EGW_SURFACE_TRFM_FORCEAC) && !(type & PNG_COLOR_MASK_ALPHA))
    //    png_set_add_alpha(lpngFInst, 0xff, PNG_FILLER_AFTER);
    
    //if((transforms & EGW_SURFACE_TRFM_INVERTAC) && ((type & PNG_COLOR_MASK_ALPHA) || (transforms & EGW_SURFACE_TRFM_FORCEAC)))
    //    png_set_invert_alpha(lpngFInst);
    
    // Re-update the read structure with the given transformations (should now
    // tell us what will happen afterwords), and check to be sure that we will
    // be able to correctly process it.
    
    png_read_update_info(lpngFInst, lpngFInfo);
    width = png_get_image_width(lpngFInst, lpngFInfo);
    height = png_get_image_height(lpngFInst, lpngFInfo);
    pitch = png_get_rowbytes(lpngFInst, lpngFInfo);
    depth = png_get_bit_depth(lpngFInst, lpngFInfo);
    chnls = png_get_channels(lpngFInst, lpngFInfo);
    type = png_get_color_type(lpngFInst, lpngFInfo);
    
    // Just a few preliminary checks & fill-ins.
    
    if(depth != 8) {
        NSLog(@"egwAssetManager: loadSurface_PNG:fromFile:withTransforms: Failure processing bit depth of %d for image input file '%s'. Bit depth not supported.", depth, resourceFile);
        goto ErrorCleanup;
    }
    if(!(chnls >= 1 && chnls <= 4)) {
        NSLog(@"egwAssetManager: loadSurface_PNG:fromFile:withTransforms: Failure processing channel count of %d for image input file '%s'. Channel count not supported.", chnls, resourceFile);
        goto ErrorCleanup;
    }
    
    surface->format = (EGWuint16)((type & PNG_COLOR_MASK_COLOR) ? ((type & PNG_COLOR_MASK_ALPHA) ? EGW_SURFACE_FRMT_R8G8B8A8 : EGW_SURFACE_FRMT_R8G8B8) : ((type & PNG_COLOR_MASK_ALPHA) ? EGW_SURFACE_FRMT_GS8A8 : EGW_SURFACE_FRMT_GS8));
    surface->size.span.width = (EGWuint16)width;
    surface->size.span.height = (EGWuint16)height;
    surface->pitch = (EGWuint32)chnls * (EGWuint32)width;
    
    // Handle custom byte packing on load
    packingB = egwBytePackingFromSrfcTrfm(transforms, EGW_SURFACE_DFLTBPACKING);
    transforms &= ~EGW_SURFACE_TRFM_EXBPACKING;
    if(packingB > 1)
        surface->pitch = egwRoundUpMultipleui32(surface->pitch, packingB);
    
    if((transforms & EGW_SURFACE_TRFM_EXENSURES) && ![self performSurfaceEnsurances:surface fromFile:resourceFile withTransforms:&transforms])
        goto ErrorCleanup;
    
    // Allocate the surface data that will be used.
    
    if(!(rows = (EGWbyte**)malloc((EGWuint)(height * sizeof(png_bytep))))) {
        NSLog(@"egwAssetManager: loadSurface_PNG:fromFile:withTransforms: Failure allocating %d bytes for row data for image input file '%s'.", (height * sizeof(png_bytep)), resourceFile);
        goto ErrorCleanup;
    }
    if(!(surface->data = (EGWbyte*)malloc((size_t)surface->pitch * (size_t)surface->size.span.height))) {
        NSLog(@"egwAssetManager: loadSurface_PNG:fromFile:withTransforms: Failure allocating %d bytes for raw data for image input file '%s'.", ((size_t)surface->pitch * (size_t)surface->size.span.height), resourceFile);
        goto ErrorCleanup;
    }
    
    // Read the image data.
    
    {   EGWuintptr cScanline = (EGWuintptr)surface->data + ((EGWuintptr)surface->pitch * (EGWuintptr)surface->size.span.height);
        row = height;
        while(row--)
            rows[row] = (png_bytep)(cScanline -= (EGWuintptr)surface->pitch);
    }
    
    png_set_rows(lpngFInst, lpngFInfo, (png_bytepp)rows);
    
    if(!(transforms & EGW_SURFACE_TRFM_FLIPVERT)) {
        row = height;
        while(row--)
            png_read_row(lpngFInst, (png_bytep)rows[height - (row+1)], NULL);
    } else { // Flip vertical by filling backwards
        row = height;
        while(row--)
            png_read_row(lpngFInst, (png_bytep)rows[row], NULL);
        
        transforms &= ~EGW_SURFACE_TRFM_FLIPVERT;
    }
    
    // Done with the file, read the tail and close it up.
    
    png_read_end(lpngFInst, lpngFEInfo);
    
    png_destroy_read_struct(&lpngFInst, &lpngFInfo, &lpngFEInfo);
    lpngFInst = NULL; lpngFInfo = NULL; lpngFEInfo = NULL;
    
    if(rows) { free((void*)rows); rows = NULL; }
    fclose(fin); fin = NULL;
    
    // Perform any post-op transformations.
    
    // Perform pre-conversion modifications, conversions, and post-conversion modifications
    if((transforms & EGW_SURFACE_TRFM_EXDATAOPS) && ![self performSurfaceModifications:surface fromFile:resourceFile withTransforms:&transforms])
        goto ErrorCleanup;
    if((transforms & (EGW_SURFACE_TRFM_EXFORCES | EGW_SURFACE_TRFM_EXBPACKING)) && ![self performSurfaceConversions:surface fromFile:resourceFile withTransforms:&transforms])
        goto ErrorCleanup;
    if((transforms & EGW_SURFACE_TRFM_EXDATAOPS) && ![self performSurfaceModifications:surface fromFile:resourceFile withTransforms:&transforms])
        goto ErrorCleanup;
    
    return YES;
    
ErrorCleanup:
    if(lpngFInst || lpngFInfo || lpngFEInfo) png_destroy_read_struct(&lpngFInst, &lpngFInfo, &lpngFEInfo);
    if(rows) free((void*)rows);
    if(surface) egwSrfcFree(surface);
    if(fin) fclose(fin);
    return NO;
}

// !!!: PVRTC surface loader.
// TODO: PVRTC parser big-endian value flipping. -jw

- (BOOL)loadSurface_PVRTC:(egwSurface*)surface fromFile:(const EGWchar*)resourceFile withTransforms:(EGWuint)transforms {
    FILE* fin = NULL;
    egwPVRTCFileHeader header;
    
    if(!surface) {
        NSLog(@"egwAssetManager: loadSurface_PVRTC:fromFile:withTransforms: Failure opening image input file '%s'. Invalid surface container object.", resourceFile);
        goto ErrorCleanup;
    } else memset((void*)surface, 0, sizeof(egwSurface));
    
    // Open file and read data, checking over consistency of file, ensurances, and filling out surface.
    
    if(!(fin = fopen((const char*)resourceFile, "rb"))) {
        NSLog(@"egwAssetManager: loadSurface_BMP:fromFile:withTransforms: Failure opening image input file '%s'. File not found or cannot be opened.", resourceFile);
        goto ErrorCleanup;
    }
    
    fread(&header.fileType, sizeof(header.fileType), 1, fin);
    fread(&header.srfcSize, sizeof(header.srfcSize), 1, fin);
    fread(&header.srfcFormat, sizeof(header.srfcFormat), 1, fin);
    fread(&header.dataSize, sizeof(header.dataSize), 1, fin);
    
    if(strncmp((const char*)&header.fileType, "GWPVRTC1", 8) != 0) {
        NSLog(@"egwAssetManager: loadSurface_PVRTC:fromFile:withTransforms: Failure parsing image input file '%s'. File type is not a GW PVRTC rev.1 ('%c%c%c%c%c%c%c%c' tag, should be 'GWPVRTC1').", resourceFile, header.fileType[0], header.fileType[1], header.fileType[2], header.fileType[3], header.fileType[4], header.fileType[5], header.fileType[6], header.fileType[7]);
        goto ErrorCleanup;
    }
    
    surface->format = (EGWuint32)header.srfcFormat;
    surface->size.span.width = surface->size.span.height = (EGWuint16)header.srfcSize; // PVRTC always square
    surface->pitch = ((EGWuint32)surface->size.span.width * (surface->format & EGW_SURFACE_FRMT_EXBPP)) >> 3;
    
    if(EGW_ENGINE_ASSETS_LOADERMSGS)
        NSLog(@"egwAssetManager: loadAsset_PVRTC:fromFile:withTransforms: Surface input file '%s' details: Width: %d, Height: %d, Depth: %d, Channels: %d, Type: %p, Slab size: %d.", resourceFile, surface->size.span.width, surface->size.span.height, ((surface->format & EGW_SURFACE_FRMT_PVRTCRGB2) == EGW_SURFACE_FRMT_PVRTCRGB2 || (surface->format & EGW_SURFACE_FRMT_PVRTCRGBA2) == EGW_SURFACE_FRMT_PVRTCRGBA2 ? 2 : 4), (surface->format & EGW_SURFACE_FRMT_EXAC ? 4 : 3), surface->format, (EGWuint)surface->pitch * (EGWuint)surface->size.span.height);
    
    if(![self performSurfaceEnsurances:surface fromFile:resourceFile withTransforms:&transforms])
        goto ErrorCleanup;
    
    if(!(surface->data = (EGWbyte*)malloc((size_t)header.dataSize))) {
        NSLog(@"egwAssetManager: loadSurface_PVRTC:fromFile:withTransforms: Failure parsing image input file '%s'. Parser cannot allocate %d bytes for raw data buffer.", resourceFile, header.dataSize);
        goto ErrorCleanup;
    }
    
    // Read file data and close it up.
    
    fread(surface->data, sizeof(EGWbyte), header.dataSize, fin);
    
    fclose(fin); fin = NULL;
    
    // Perform any post-op transformations.
    
    // PVRTC does not support transformations of any kind due to its compressed nature
    if(transforms & (EGW_SURFACE_TRFM_EXDATAOPS | EGW_SURFACE_TRFM_EXFORCES | EGW_SURFACE_TRFM_EXBPACKING)) {
        NSLog(@"egwAssetManager: loadSurface_PVRTC:fromFile:withTransforms: Failure parsing image input file '%s'. Parser cannot do any surface modifications or conversions to compressed image data.", resourceFile);
        goto ErrorCleanup;
    }
    
    return YES;
    
ErrorCleanup:
    if(surface) egwSrfcFree(surface);
    if(fin) fclose(fin);
    return NO;
}

// !!!: GAM asset manifest loader.

- (EGWuint)loadManifest_GAM:(const EGWchar*)resourceFile {
    NSLog(@"egwAssetManager: loadManifest_GAM: Not yet implemented.");
    return 0;
}

// !!!: GAMX asset manifest loader.

// NOTE: Core parser methods are in egwGAMParser.m (to save on file size)
// NOTE: Below routines always return retained items - remember to release!
// NOTE: nodeTypes: 1: <openingtag> (including <tag/>), 3: >innersectiontext<, 14: <=' ' (ws|endl), 15: </closingtag>

id<NSObject> egwGAMXParseEntity(const EGWchar* resourceFile, xmlTextReaderPtr xmlReadHandle, EGWint* retVal, EGWuint* loadCounter, const xmlChar* entityNodeName);

- (EGWuint)loadManifest_GAMX:(const EGWchar*)resourceFile {
    xmlTextReaderPtr xmlReadHandle = NULL;
    EGWint retVal, nodeType;
    xmlChar *nodeName = NULL;
    EGWuint loadCounter = 0;
    id<NSObject> entity = nil;
    
    if(!(xmlReadHandle = xmlNewTextReaderFilename((const char*)resourceFile))) {
        NSLog(@"egwAssetManager: loadManifest_GAMX: Failure opening manifest input file '%s'.", resourceFile);
        goto LoadBreak;
    }
    
    while((retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
        
        if(nodeType == 14) continue;
        else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"gamx") == 0 && !xmlTextReaderIsEmptyElement(xmlReadHandle)) {
            if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
            
            while((retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                
                if(nodeType == 14) continue;
                else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"gamx") == 0) break;
                else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"info") == 0 && !xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                    
                    while((retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                        
                        if(nodeType == 14) continue;
                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"info") == 0) break;
                        // NOTE: Don't really care about reading any of the info at the moment -jw
                        
                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                    }
                }
                else if(nodeType == 1 && nodeName && strcasecmp((const char*)nodeName, (const char*)"assets") == 0 && !xmlTextReaderIsEmptyElement(xmlReadHandle)) {
                    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                    
                    while((retVal = xmlTextReaderRead(xmlReadHandle)) == 1) {
                        nodeType = xmlTextReaderNodeType(xmlReadHandle); nodeName = (nodeType == 1 || nodeType == 15 ? xmlTextReaderName(xmlReadHandle) : NULL);
                        
                        if(nodeType == 14) continue;
                        else if(nodeType == 15 && nodeName && strcasecmp((const char*)nodeName, (const char*)"assets") == 0) break;
                        else if(nodeType == 1 && nodeName) {
                            // NOTE: This is the main entry point of the on-demand recurser -jw
                            entity = egwGAMXParseEntity(resourceFile, xmlReadHandle, &retVal, &loadCounter, nodeName);
                            [entity release]; entity = nil; // Always returns retained, but no more need for it
                        }
                        
                        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                        if(retVal != 1) break; // retVal can be modified in sub-routines
                    }
                }
                
                if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
                if(retVal != 1) break; // retVal can be modified in sub-routines
            }
        }
        
        if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
        if(retVal != 1) break; // retVal can be modified in sub-routines
    }
    
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(retVal < 0 || retVal > 1) {
        NSLog(@"egwAssetManager: loadManifest_GAMX: Failure parsing in manifest input file '%s'. XML2Error: %d.", resourceFile, retVal);
        goto LoadBreak;
    }
    
LoadBreak:
    if(nodeName) { xmlFree(nodeName); nodeName = NULL; }
    if(xmlReadHandle) { xmlFreeTextReader(xmlReadHandle); xmlReadHandle = NULL; }
    return loadCounter;
}

- (BOOL)performAudioEnsurances:(egwAudio*)audio fromFile:(const EGWchar*)resourceFile withTransforms:(EGWuint*)transforms {
    if(*transforms & EGW_AUDIO_TRFM_EXENSURES) {
        if((*transforms & EGW_AUDIO_TRFM_ENSRLTETMS) && (audio->pitch * audio->count) > EGW_SOUND_MAXSTATIC) {
            NSLog(@"egwAssetManager: performAudioEnsurances:fromFile:withTransforms: Failure parsing sound input file '%s'. Ensurance of sound data being less than or equal to max static size failed (%d bytes, should be <= %d).", resourceFile, (audio->pitch * audio->count), EGW_SOUND_MAXSTATIC);
            return NO;
        } else *transforms &= ~EGW_AUDIO_TRFM_ENSRLTETMS;
    }
    
    return YES;
}

- (BOOL)performAudioConversions:(egwAudio*)audio fromFile:(const EGWchar*)resourceFile withTransforms:(EGWuint*)transforms {
    if(*transforms & EGW_AUDIO_TRFM_EXFORCES) {
        EGWuint newFormat = egwFormatFromAudioTrfm(*transforms, audio->format);
        
        if(newFormat != audio->format) {
            egwAudio oldAudio;
            memcpy((void*)&oldAudio, (const void*)audio, sizeof(egwAudio));
            memset((void*)audio, 0, sizeof(egwAudio));
            if(!egwAudioConvert(newFormat, &oldAudio, audio)) {
                NSLog(@"egwAssetManager: performAudioConversions:fromFile:withTransforms: Failure transforming sound input file '%s'. Parser failed conversion to forced audio format 0x%p.", resourceFile, newFormat);
                egwAudioFree(&oldAudio);
                return NO;
            } else egwAudioFree(&oldAudio);
        }
        
        *transforms &= ~EGW_AUDIO_TRFM_EXFORCES;
    }
    
    if(*transforms & EGW_AUDIO_TRFM_EXBPACKING) {
        EGWint packingB = egwAudioPacking(audio);
        EGWint newPackingB = egwBytePackingFromAudioTrfm(*transforms, packingB);
        
        if(newPackingB != packingB) {
            egwAudio oldAudio;
            memcpy((void*)&oldAudio, (const void*)audio, sizeof(egwAudio));
            memset((void*)audio, 0, sizeof(egwAudio));
            if(!egwAudioRepack(newPackingB, &oldAudio, audio)) {
                NSLog(@"egwAssetManager: performAudioConversions:fromFile:withTransforms: Failure transforming sound input file '%s'. Parser failed conversion to forced byte packing %d.", resourceFile, newPackingB);
                egwAudioFree(&oldAudio);
                return NO;
            } else egwAudioFree(&oldAudio);
        }
        
        *transforms &= ~EGW_AUDIO_TRFM_EXBPACKING;
    }
    
    return YES;
}

- (BOOL)performAudioModifications:(egwAudio*)audio fromFile:(const EGWchar*)resourceFile withTransforms:(EGWuint*)transforms {
    if(*transforms & EGW_AUDIO_TRFM_EXDATAOPS) {
        if(*transforms & EGW_AUDIO_TRFM_INVERTS) {
            if(!egwAudioInvertSig(audio)) {
                NSLog(@"egwAssetManager: performAudioModifications:fromFile:withTransforms: Failure transforming sound input file '%s'. Parser failed inverting sound signal.", resourceFile);
                return NO;
            } else *transforms &= ~EGW_AUDIO_TRFM_INVERTS;
        }
        
        if(*transforms & EGW_AUDIO_TRFM_RVRSDIR) {
            if(!egwAudioReverseDir(audio)) {
                NSLog(@"egwAssetManager: performAudioModifications:fromFile:withTransforms: Failure transforming sound input file '%s'. Parser failed reversing sound direction.", resourceFile);
                return NO;
            } else *transforms &= ~EGW_AUDIO_TRFM_RVRSDIR;
        }
        
        if(*transforms & EGW_AUDIO_TRFM_SWAPLR) {
            if(audio->format & EGW_AUDIO_FRMT_EXSTEREO) {
                if(!egwAudioSwapLR(audio)) {
                    NSLog(@"egwAssetManager: performAudioModifications:fromFile:withTransforms: Failure transforming sound input file '%s'. Parser failed left/right channels swap.", resourceFile);
                    return NO;
                } else *transforms &= ~EGW_AUDIO_TRFM_SWAPLR;
            } else if(!(*transforms & EGW_AUDIO_TRFM_FORCESTEREO))
                NSLog(@"egwAssetManager: performAudioModifications:fromFile:withTransforms: Warning while transforming sound input file '%s'. Parser cannot perform left/right channels swap on non >= stereo sound data.", resourceFile);
        }
    }
    
    return YES;
}

- (BOOL)performSurfaceEnsurances:(egwSurface*)surface fromFile:(const EGWchar*)resourceFile withTransforms:(EGWuint*)transforms {
    if(*transforms & EGW_SURFACE_TRFM_EXENSURES) {
        if((*transforms & EGW_SURFACE_TRFM_ENSRLTETMS) && (surface->pitch * surface->size.span.height) > EGW_TEXTURE_MAXSTATIC) {
            NSLog(@"egwAssetManager: performSurfaceEnsurances:fromFile:withTransforms: Failure parsing image input file '%s'. Ensurance of image data being less than or equal to max static size failed (%d bytes, should be <= %d).", resourceFile, (surface->pitch * surface->size.span.height), EGW_TEXTURE_MAXSTATIC);
            return NO;
        } else *transforms &= ~EGW_SURFACE_TRFM_ENSRLTETMS;
        
        if((*transforms & EGW_SURFACE_TRFM_ENSRPOW2) && (!egwIsPow2ui((EGWuint)surface->size.span.width) || !egwIsPow2ui((EGWuint)surface->size.span.height))) {
            NSLog(@"egwAssetManager: performSurfaceEnsurances:fromFile:withTransforms: Failure parsing image input file '%s'. Ensurance of image width and height being a power-of-2 failed (%dx%d pixels, should possibly be %dx%d).", resourceFile, surface->size.span.width, surface->size.span.height, egwRoundUpPow2ui((EGWuint)surface->size.span.width), egwRoundUpPow2ui((EGWuint)surface->size.span.height));
            return NO;
        } else *transforms &= ~EGW_SURFACE_TRFM_ENSRPOW2;
        
        if((*transforms & EGW_SURFACE_TRFM_ENSRSQR) && surface->size.span.width != surface->size.span.height) {
            NSLog(@"egwAssetManager: performSurfaceEnsurances:fromFile:withTransforms: Failure parsing image input file '%s'. Ensurance of image width and height being square failed (%dx%d pixels, should possibly be %dx%d).", resourceFile, surface->size.span.width, surface->size.span.height, egwMax2ui((EGWuint)surface->size.span.width, (EGWuint)surface->size.span.height), egwMax2ui((EGWuint)surface->size.span.width, (EGWuint)surface->size.span.height));
            return NO;
        } else *transforms &= ~EGW_SURFACE_TRFM_ENSRSQR;
    }
    
    return YES;
}

- (BOOL)performSurfaceConversions:(egwSurface*)surface fromFile:(const EGWchar*)resourceFile withTransforms:(EGWuint*)transforms {
    if(*transforms & EGW_SURFACE_TRFM_EXFORCES) {
        EGWuint newFormat = egwFormatFromSrfcTrfm(*transforms, surface->format);
        
        if(newFormat != surface->format) {
            egwSurface oldSurface;
            memcpy((void*)&oldSurface, (const void*)surface, sizeof(egwSurface));
            memset((void*)surface, 0, sizeof(egwSurface));
            if(!egwSrfcConvert(newFormat, &oldSurface, surface)) {
                NSLog(@"egwAssetManager: performSurfaceConversions:fromFile:withTransforms: Failure transforming image input file '%s'. Parser failed conversion to forced surface format 0x%p.", resourceFile, newFormat);
                egwSrfcFree(&oldSurface);
                return NO;
            } else egwSrfcFree(&oldSurface);
        }
        
        *transforms &= ~EGW_SURFACE_TRFM_EXFORCES;
    }
    
    if(*transforms & EGW_SURFACE_TRFM_EXBPACKING) {
        EGWint packingB = egwSrfcPacking(surface);
        EGWint newPackingB = egwBytePackingFromSrfcTrfm(*transforms, packingB);
        
        if(newPackingB != packingB) {
            egwSurface oldSurface;
            memcpy((void*)&oldSurface, (const void*)surface, sizeof(egwSurface));
            memset((void*)surface, 0, sizeof(egwSurface));
            if(!egwSrfcRepack(newPackingB, &oldSurface, surface)) {
                NSLog(@"egwAssetManager: performSurfaceConversions:fromFile:withTransforms: Failure transforming image input file '%s'. Parser failed conversion to forced byte packing %d.", resourceFile, newPackingB);
                egwSrfcFree(&oldSurface);
                return NO;
            } else egwSrfcFree(&oldSurface);
        }
        
        *transforms &= ~EGW_SURFACE_TRFM_EXBPACKING;
    }
    
    return YES;
}

- (BOOL)performSurfaceModifications:(egwSurface*)surface fromFile:(const EGWchar*)resourceFile withTransforms:(EGWuint*)transforms {
    if(*transforms & EGW_SURFACE_TRFM_EXDATAOPS) {
        if(*transforms & EGW_SURFACE_TRFM_RSZHALF) {
            if(!egwSrfcResizeHalf(surface)) {
                NSLog(@"egwAssetManager: performSurfaceModifications:fromFile:withTransforms: Failure transforming image input file '%s'. Parser failed resizing image by half.", resourceFile);
                return NO;
            } else *transforms &= ~EGW_SURFACE_TRFM_RSZHALF;
        }
        
        if(*transforms & EGW_SURFACE_TRFM_FLIPVERT) {
            if(!egwSrfcFlipVert(surface)) {
                NSLog(@"egwAssetManager: performSurfaceModifications:fromFile:withTransforms: Failure transforming image input file '%s'. Parser failed vertical image flip.", resourceFile);
                return NO;
            } else *transforms &= ~EGW_SURFACE_TRFM_FLIPVERT;
        }
        
        if(*transforms & EGW_SURFACE_TRFM_FLIPHORZ) {
            if(!egwSrfcFlipHorz(surface)) {
                NSLog(@"egwAssetManager: performSurfaceModifications:fromFile:withTransforms: Failure transforming image input file '%s'. Parser failed horizontal image flip.", resourceFile);
                return NO;
            } else *transforms &= ~EGW_SURFACE_TRFM_FLIPHORZ;
        }
        
        if(*transforms & EGW_SURFACE_TRFM_SWAPRB) {
            if(surface->format & EGW_SURFACE_FRMT_EXRGB) {
                if(!egwSrfcSwapRB(surface)) {
                    NSLog(@"egwAssetManager: performSurfaceModifications:fromFile:withTransforms: Failure transforming image input file '%s'. Parser failed red/blue color channel swap.", resourceFile);
                    return NO;
                } else *transforms &= ~EGW_SURFACE_TRFM_SWAPRB;
            } else if(!(*transforms & EGW_SURFACE_TRFM_FORCERGB))
                NSLog(@"egwAssetManager: performSurfaceModifications:fromFile:withTransforms: Warning while transforming image input file '%s'. Parser cannot perform red/blue color channel swap on non red/green/blue image data.", resourceFile);
        }
        
        if(*transforms & EGW_SURFACE_TRFM_INVERTGS) {
            if(surface->format & EGW_SURFACE_FRMT_EXGS) {
                if(!egwSrfcInvertGS(surface)) {
                    NSLog(@"egwAssetManager: performSurfaceModifications:fromFile:withTransforms: Failure transforming image input file '%s'. Parser failed grey-scale channel inversion.", resourceFile);
                    return NO;
                } else *transforms &= ~EGW_SURFACE_TRFM_INVERTGS;
            } else if(!(*transforms & EGW_SURFACE_TRFM_FORCEGS))
                NSLog(@"egwAssetManager: performSurfaceModifications:fromFile:withTransforms: Warning while transforming image input file '%s'. Parser cannot perform grey-scale channel inversion on non grey scale image data.", resourceFile);
        }
        
        if(*transforms & EGW_SURFACE_TRFM_INVERTAC) {
            if(surface->format & EGW_SURFACE_FRMT_EXAC) {
                if(!egwSrfcInvertAC(surface)) {
                    NSLog(@"egwAssetManager: performSurfaceModifications:fromFile:withTransforms: Failure transforming image input file '%s'. Parser failed alpha channel inversion.", resourceFile);
                    return NO;
                } else *transforms &= ~EGW_SURFACE_TRFM_INVERTAC;
            } else if(!(*transforms & EGW_SURFACE_TRFM_FORCEAC))
                NSLog(@"egwAssetManager: performSurfaceModifications:fromFile:withTransforms: Warning while transforming image input file '%s'. Parser cannot perform alpha channel inversion on non alpha channel image data.", resourceFile);
        }
        
        if(*transforms & EGW_SURFACE_TRFM_CYANTRANS) {
            if(surface->format & EGW_SURFACE_FRMT_EXAC) {
                if(!egwSrfcCyanTT(surface)) {
                    NSLog(@"egwAssetManager: performSurfaceModifications:fromFile:withTransforms: Failure transforming image input file '%s'. Parser failed cyan-to-transparent color conversion.", resourceFile);
                    return NO;
                } else *transforms &= ~EGW_SURFACE_TRFM_CYANTRANS;
            } else if(!(*transforms & EGW_SURFACE_TRFM_FORCEAC))
                NSLog(@"egwAssetManager: performSurfaceModifications:fromFile:withTransforms: Warning while transforming image input file '%s'. Parser cannot perform cyan-to-transparent color conversion on non alpha channel image data.", resourceFile);
        }
        
        if(*transforms & EGW_SURFACE_TRFM_MGNTTRANS) {
            if(surface->format & EGW_SURFACE_FRMT_EXAC) {
                if(!egwSrfcMagentaTT(surface)) {
                    NSLog(@"egwAssetManager: performSurfaceModifications:fromFile:withTransforms: Failure transforming image input file '%s'. Parser failed magenta-to-transparent color conversion.", resourceFile);
                    return NO;
                } else *transforms &= ~EGW_SURFACE_TRFM_MGNTTRANS;
            } else if(!(*transforms & EGW_SURFACE_TRFM_FORCEAC))
                NSLog(@"egwAssetManager: performSurfaceModifications:fromFile:withTransforms: Warning while transforming image input file '%s'. Parser cannot perform magenta-to-transparent color conversion on non alpha channel image data.", resourceFile);
        }
        
        if(*transforms & EGW_SURFACE_TRFM_OPCTYDILT) {
            if(surface->format & EGW_SURFACE_FRMT_EXAC) {
                if(!egwSrfcOpacityDilate(surface)) {
                    NSLog(@"egwAssetManager: performSurfaceModifications:fromFile:withTransforms: Failure transforming image input file '%s'. Parser failed opacity dilation.", resourceFile);
                    return NO;
                } else *transforms &= ~EGW_SURFACE_TRFM_OPCTYDILT;
            } else if(!(*transforms & EGW_SURFACE_TRFM_FORCEAC))
                NSLog(@"egwAssetManager: performSurfaceModifications:fromFile:withTransforms: Warning while transforming image input file '%s'. Parser cannot perform opacity dilation on non alpha channel image data.", resourceFile);
        }
    }
    
    return YES;
}

@end

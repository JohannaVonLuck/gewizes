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

/// @defgroup geWizES_sys_gfxcontext egwGfxContext
/// @ingroup geWizES_sys
/// Abstract Graphics Context.
/// @{

/// @file egwGfxContext.h
/// Abstract Graphics Context Interface.

#import "egwSysTypes.h"
#import "egwGfxContext.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPGfxContext.h"
#import "../inf/egwPTask.h"
#import "../inf/egwPCamera.h"
#import "../inf/egwPLight.h"
#import "../inf/egwPMaterial.h"
#import "../inf/egwPShader.h"
#import "../inf/egwPTexture.h"
#import "../data/egwSinglyLinkedList.h"
#import "../gfx/egwGfxTypes.h"


#define EGW_GFXCONTEXT_TXTRGENCNT   10      ///< Number of texture IDs to generate when more are needed.
#define EGW_GFXCONTEXT_BFFRGENCNT   10      ///< Number of buffer IDs to generate when more are needed.
#define EGW_GFXCONTEXT_FPSMEASURES  5.0     ///< Time period to measure FPS over.


extern void (*egwAFPGfxCntxPushLight)(id, SEL, id<egwPLight>, const egwLightJumpTable*);      ///< Active pushLight IMP function pointer (to reduce dynamic lookup).
extern void (*egwAFPGfxCntxPopLights)(id, SEL, EGWuint);            ///< Active popLights IMP function pointer (to reduce dynamic lookup).
extern void (*egwAFPGfxCntxBindLights)(id, SEL);                    ///< Active bindLights IMP function pointer (to reduce dynamic lookup).
extern void (*egwAFPGfxCntxUnbindLights)(id, SEL);                  ///< Active unbindLights IMP function pointer (to reduce dynamic lookup).
extern void (*egwAFPGfxCntxPushMaterial)(id, SEL, id<egwPMaterial>, const egwMaterialJumpTable*);///< Active pushMaterial IMP function pointer (to reduce dynamic lookup).
extern void (*egwAFPGfxCntxPopMaterials)(id, SEL, EGWuint);         ///< Active popMaterials IMP function pointer (to reduce dynamic lookup).
extern void (*egwAFPGfxCntxBindMaterials)(id, SEL);                 ///< Active bindMaterials IMP function pointer (to reduce dynamic lookup).
extern void (*egwAFPGfxCntxUnbindMaterials)(id, SEL);               ///< Active unbindMaterials IMP function pointer (to reduce dynamic lookup).
extern void (*egwAFPGfxCntxPushShader)(id, SEL, id<egwPShader>, const egwShaderJumpTable*);    ///< Active pushShader IMP function pointer (to reduce dynamic lookup).
extern void (*egwAFPGfxCntxPopShaders)(id, SEL, EGWuint);           ///< Active popShaders IMP function pointer (to reduce dynamic lookup).
extern void (*egwAFPGfxCntxBindShaders)(id, SEL);                   ///< Active bindShaders IMP function pointer (to reduce dynamic lookup).
extern void (*egwAFPGfxCntxUnbindShaders)(id, SEL);                 ///< Active unbindShaders IMP function pointer (to reduce dynamic lookup).
extern void (*egwAFPGfxCntxPushTexture)(id, SEL, id<egwPTexture>, const egwTextureJumpTable*);  ///< Active pushTexture IMP function pointer (to reduce dynamic lookup).
extern void (*egwAFPGfxCntxPopTextures)(id, SEL, EGWuint);          ///< Active popTextures IMP function pointer (to reduce dynamic lookup).
extern void (*egwAFPGfxCntxBindTextures)(id, SEL);                  ///< Active bindTextures IMP function pointer (to reduce dynamic lookup).
extern void (*egwAFPGfxCntxUnbindTextures)(id, SEL);                ///< Active unbindTextures IMP function pointer (to reduce dynamic lookup).
extern EGWuint16 (*egwAFPGfxCntxIlluminationFrame)(id, SEL);        ///< Active illuminationFrame IMP function pointer (to reduce dynamic lookup).
extern EGWuint16 (*egwAFPGfxCntxRenderingFrame)(id, SEL);           ///< Active renderingFrame IMP function pointer (to reduce dynamic lookup).
extern void (*egwAFPGfxCntxAdvanceIlluminationFrame)(id, SEL);      ///< Active advanceIlluminationFrame IMP function pointer (to reduce dynamic lookup).
extern void (*egwAFPGfxCntxAdvanceRenderingFrame)(id, SEL);         ///< Active advanceRenderingFrame IMP function pointer (to reduce dynamic lookup).
extern BOOL (*egwAFPGfxCntxBeginRender)(id, SEL);                   ///< Active beginRender IMP function pointer (to reduce dynamic lookup).
extern BOOL (*egwAFPGfxCntxInterruptRender)(id, SEL);               ///< Active interruptRender IMP function pointer (to reduce dynamic lookup).
extern BOOL (*egwAFPGfxCntxEndRender)(id, SEL);                     ///< Active endRender IMP function pointer (to reduce dynamic lookup).
extern BOOL (*egwAFPGfxCntxMakeActive)(id, SEL);                    ///< Active makeActive IMP function pointer (to reduce dynamic lookup).
extern BOOL (*egwAFPGfxCntxActive)(id, SEL);                        ///< Active isActive IMP function pointer (to reduce dynamic lookup).
extern void (*egwAFPGfxCntxPerformSubTasks)(id, SEL);               ///< Active performSubTasks IMP function pointer (to reduce dynamic lookup).
extern id<egwPCamera> (*egwAFPGfxCntxActiveCamera)(id, SEL);        ///< Active activeCamera IMP function pointer (to reduce dynamic lookup).
extern EGWuint16 (*egwAFPGfxCntxActiveCameraViewingFrame)(id, SEL); ///< Active activeCameraViewingFrame IMP function pointer (to reduce dynamic lookup).
extern void (*egwAFPGfxCntxSetActiveCamera)(id, SEL, id<egwPCamera>);///< Active setActiveCamera IMP function pointer (to reduce dynamic lookup).

/// Abstract Graphics Context.
/// Contains abstract contextual data related to the in-use graphics API.
@interface egwGfxContext : NSObject <egwPGfxContext> {
    id<egwDGfxContextEvent> _delegate;      ///< Event responder (retained).
    
    EGWuint16 _width;                       ///< Width (pixels) of context buffers.
    EGWuint16 _height;                      ///< Height (pixels) of context buffers.
    
    NSThread* _thread;                      ///< Thread which owns this context (weak).
    NSMutableArray* _tasks;                 ///< Associated tasks (retained).
    id<egwPCamera> _actvCamera;             ///< Currently active camera per pass (retained).
    EGWuint16 _actvCamVFrame;               ///< Currently active camera viewing frame.
    
    NSDate* _fTime;                         ///< Frame timer.
    EGWuint _fCount;                        ///< Frame counter.
    EGWsingle _fpsAvg;                      ///< Frames per second average.
    
    pthread_mutex_t _stLock;                ///< Sub tasks list mutex lock.
    egwSinglyLinkedList _sTasks;            ///< Sub tasks list.
    
    EGWuint16 _lFrame;                      ///< Current illumination frame.
    EGWuint16 _rFrame;                      ///< Current rendering frame.
    
    EGWsingle _aCutoff;                     ///< Alpha cutoff value to utilize (+ >=, - >).
    
    BOOL _lightsEnabled;                    ///< Tracks illumination status.
    EGWuint16 _maxLights;                   ///< Maximum # of active API lights.
    
    BOOL _materialsEnabled;                 ///< Tracks material status.
    EGWuint16 _maxMaterials;                ///< Maximum # of active API materials.
    
    BOOL _shadersEnabled;                   ///< Tracks shader status.
    EGWuint16 _maxShaders;                  ///< Maximum # of active API shaders.
    
    BOOL _texturesEnabled;                  ///< Tracks texturing status.
    EGWuint16 _maxTextures;                 ///< Maximum # of active API textures.
    
    egwSize2i _maxTexSize;                  ///< Maximum texture size.
    
    BOOL _doShutdown;                       ///< Tracks to-shutdown status.
}

/// Advance Illumination Frame Method.
/// Advances illumination frame number by one.
- (void)advanceIlluminationFrame;

/// Advance Rendering Frame Method.
/// Advances rendering frame number by one.
- (void)advanceRenderingFrame;

/// Begin Render Method,
/// Performs pre-render tasks.
/// @note This method will (usually) clear frame buffers.
/// @note This method will lock the API mutex.
/// @return YES if operation is successful, otherwise NO.
- (BOOL)beginRender;

/// Interrupt Render Method.
/// Interupts render tasks, performing make-shift post-render tasks.
/// @note This method will not swap frame buffers.
/// @note This method will unlock the API mutex.
/// @return YES if operation is successful, otherwise NO.
- (BOOL)interruptRender;

/// End Render Method.
/// Performs post-render tasks.
/// @note This method will swap frame buffers.
/// @note This method will unlock the API mutex.
/// @return YES if operation is successful, otherwise NO.
- (BOOL)endRender;


/// Resize Method.
/// Attempts to resize all contained buffers to @a width by @a height.
/// @param [in] width New buffers' width.
/// @param [in] height New buffer's height.
/// @return YES if resize successful, otherwise NO.
- (BOOL)resizeBufferWidth:(EGWuint16)width bufferHeight:(EGWuint16)height;


/// Buffer Width Accessor.
/// Returns the pixel width of contained buffers.
/// @return Buffers' width.
- (EGWuint16)bufferWidth;

/// Buffer Height Accessor.
/// Returns the pixel height of contained buffers.
/// @return Buffers' height.
- (EGWuint16)bufferHeight;

/// Frames Per Second Accessor.
/// Returns the latest measured frames per second.
/// @return Latest FPS measure.
- (EGWsingle)framesPerSecond;

@end


/// Global currently active egwGfxContext instance (weak).
extern egwGfxContext* egwAIGfxCntx;


/// @}

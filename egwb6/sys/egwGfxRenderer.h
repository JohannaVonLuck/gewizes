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

/// @defgroup geWizES_sys_gfxrenderer egwGfxRenderer
/// @ingroup geWizES_sys
/// Graphics Renderer.
/// @{

/// @file egwGfxRenderer.h
/// Graphics Renderer Interface.

#import "egwSysTypes.h"
#import "../inf/egwPSingleton.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPGfxContext.h"
#import "../inf/egwPTask.h"
#import "../inf/egwPRenderable.h"
#import "../inf/egwPCamera.h"
#import "../sys/egwEngine.h"
#import "../data/egwDataTypes.h"


#define EGW_GFXRNDRR_RNDRMODE_DFLT          0x0302  ///< Default render mode.
#define EGW_GFXRNDRR_RNDRMODE_IMMEDIATE     0x0001  ///< Use immediate rendering mode.
#define EGW_GFXRNDRR_RNDRMODE_DEFERRED      0x0002  ///< Use deferred rendering mode (i.e. sorted list).
#define EGW_GFXRNDRR_RNDRMODE_PERSISTENT    0x0100  ///< Use a persistent object list (i.e. manual removal). Note: If unused, all objects are removed after each frame and must be re-enqueued.
#define EGW_GFXRNDRR_RNDRMODE_FRAMECHECK    0x0200  ///< Use delayed object removal (i.e. frame number check).

#define EGW_GFXRNDRR_RNDRQUEUE_ALL          0x00ff  ///< All rendering queues.
#define EGW_GFXRNDRR_RNDRQUEUE_FIRSTPASS    0x0001  ///< First pass rendering queue.
#define EGW_GFXRNDRR_RNDRQUEUE_SECONDPASS   0x0002  ///< Second pass rendering queue.
#define EGW_GFXRNDRR_RNDRQUEUE_THIRDPASS    0x0004  ///< Third pass rendering queue.
#define EGW_GFXRNDRR_RNDRQUEUE_FOURTHPASS   0x0008  ///< Fourth pass rendering queue.
#define EGW_GFXRNDRR_RNDRQUEUE_FIFTHPASS    0x0010  ///< Fifth pass rendering queue.
#define EGW_GFXRNDRR_RNDRQUEUE_SIXTHPASS    0x0020  ///< Sixth pass rendering queue.
#define EGW_GFXRNDRR_RNDRQUEUE_SEVENTHPASS  0x0040  ///< Seventh pass rendering queue.
#define EGW_GFXRNDRR_RNDRQUEUE_EIGHTHPASS   0x0080  ///< Eighth pass rendering queue.

#define EGW_GFXRNDRR_RNDRQUEUE_INSERT       0x0100  ///< Insert object into queue tree structure.
#define EGW_GFXRNDRR_RNDRQUEUE_REMOVE       0x0200  ///< Remove object from queue tree structure.
#define EGW_GFXRNDRR_RNDRQUEUE_PAUSE        0x0400  ///< Pause/resume object in queue list structure.

#define EGW_GFXRNDRR_DFLTPRIORITY   0.75    ///< Default graphics renderer priority.


/// Graphics Renderer.
/// Task that manages and executes renderable object instances.
@interface egwGfxRenderer : NSObject <egwPSingleton, egwPTask> {
    egwGfxRdrParams _params;                ///< Renderer parameters (copy).
    
    pthread_mutex_t _qLock;                 ///< Render queue mutex lock.
    pthread_mutex_t _rLock;                 ///< Request queue mutex lock.
    
    egwRedBlackTree _rQueues[8];            ///< Render queues (contents retained).
    egwTaskCameraData _rCameras[8];         ///< Rendering task cameras data (contents retained).
    
    EGWuint _rReplies[8];                   ///< Render replies array (alias).
    EGWuint8 _alphaMods[8];                 ///< Alpha modifiers per queue.
    EGWuint8 _shadeMods[8];                 ///< Shading modifiers per queue.
    
    egwArray _pendingList;                  ///< Queue work item pending list for remove/resort (weak).
    egwArray _requestList;                  ///< Queue work request list for insertion/removal.
    
    id<NSObject> _lBase;                    ///< Last base tracker (retained).
    EGWuint16 _tFrame;                      ///< Rendering task frame.
    
    BOOL _amRunning;                        ///< Tracks run status.
    BOOL _doShutdown;                       ///< Tracks to-shutdown status.
    BOOL _doPreprocessing;                  ///< Tracks pre-processing status.
    BOOL _doPostprocessing;                 ///< Tracks post-processing status.
    BOOL _modChange;                        ///< Tracks modifier change status.
}

/// Designated Initializer.
/// Initializes the task with provided settings.
/// @param [in] params Parameters option structure. May be NULL for default.
/// @return Self upon success, otherwise nil.
- (id)initWithParams:(egwGfxRdrParams*)params;


/// Render Object Method.
/// Enqueue provided @a renderableObject for rendering on the next frame.
/// @note An object may only be enqueued once, but multiple enqueues will still signal start rendering reply messages (restart trick).
/// @param [in] renderableObject Renderable object instance.
- (void)renderObject:(id<egwPRenderable>)renderableObject;

/// Render Finish Method.
/// Instructs the graphics renderer that there are no more objects left to enqueue for current rendering frame.
/// @note This method is used only in immediate mode to signify end of frame.
- (void)renderFinish;

/// Pause Object Method.
/// Pauses or resumes provided @a renderableObject from/to rendering on the next frames.
/// @param [in] renderableObject Renderable object instance.
- (void)pauseObject:(id<egwPRenderable>)renderableObject;

/// Remove Object Method.
/// Releases any retained @a renderableObject instances currently queued.
/// @param [in] renderableObject Renderable object instance.
- (void)removeObject:(id<egwPRenderable>)renderableObject;

/// Rendering Camera Accessor.
/// Returns the camera object used as the rendering source for queue @a queueIdent.
/// @param [in] queueIdent Bit-wise queue identifier.
/// @return Rendering camera object.
- (id<egwPCamera>)renderingCameraForQueue:(EGWuint)queueIdent;


/// Rendering Camera Mutator.
/// Sets the @a camera object used as the rendering source for queue @a queueIdent.
/// @param [in] camera Rendering camera object (retained).
/// @param [in] queueIdent Bit-wise queue identifier.
- (void)setRenderingCamera:(id<egwPCamera>)camera forQueue:(EGWuint)queueIdent;

/// Alpha Modifier (forQueue) Mutator.
/// Sets the @a alphaMod modifier for queue @a queueIdent.
/// @param [in] alphaMod Alpha modifier [0,256] (x100).
/// @param [in] queueIdent Bit-wise queue identifier.
- (void)setAlphaModifier:(EGWuint8)alphaMod forQueue:(EGWuint)queueIdent;

/// Shading Modifier (forQueue) Mutator.
/// Sets the @a shadeMod modifier for queue @a queueIdent.
/// @param [in] shadeMod Shading modifier [0,256] (x100).
/// @param [in] queueIdent Bit-wise queue identifier.
- (void)setShadeModifier:(EGWuint8)shadeMod forQueue:(EGWuint)queueIdent;

@end


/// Global current singleton egwGfxRenderer instance (weak).
extern egwGfxRenderer* egwSIGfxRdr;

/// @}

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

/// @defgroup geWizES_sys_types egwSysTypes
/// @ingroup geWizES_sys
/// System Types.
/// @{

/// @file egwSysTypes.h
/// System Types.

#import "../inf/egwTypes.h"
#import "../inf/egwPContext.h"
#import "../inf/egwPGfxContext.h"
#import "../inf/egwPPhyContext.h"
#import "../inf/egwPSndContext.h"
#import "../gfx/egwGfxTypes.h"


// !!!: ***** Predefs *****

@class egwEngine;
@class egwAssetManager;
@class egwScreenManager;
@class egwTaskManager;
@class egwGfxContext;
@class egwGfxContextAGL;
@class egwGfxContextNSGL;
@class egwGfxContextEAGLES;
@class egwGfxRenderer;
@class egwPhyContext;
@class egwPhyContextSW;
@class egwPhyActuator;
@class egwSndContext;
@class egwSndContextAL;
@class egwSndMixer;


// !!!: ***** Defines *****

// Engine settings
#define EGW_ENGINE_MANAGERS_TIMETOWAIT      5.00    ///< Number of seconds for managers to wait for objects to return (if applicable) before giving up.
#define EGW_ENGINE_MANAGERS_TIMETODRAIN     60.0    ///< Number of seconds for managers (with dedicated threads) to wait until a pool drain is initiated.
#define EGW_ENGINE_MANAGERS_TIMETOSLEEP     0.01    ///< Number of seconds for managers (with dedicated threads) to go to sleep for if no work is on queue.
#define EGW_ENGINE_MANAGERS_ODDJOBSPINCYCLE 120     ///< Number of spin cycles to perform before attempting to handle odd jobs, such as checking for thread cancelation and possibly cleaning autorelease pools.
#define EGW_ENGINE_MANAGERS_STARTUPMSGS     NO      ///< Whether or not to display start up alert messages.
#define EGW_ENGINE_MANAGERS_SHUTDOWNMSGS    NO      ///< Whether or not to display shut down alert messages.
#define EGW_ENGINE_ASSETS_LOADERMSGS        NO      ///< Whether or not to display asset loader messages.
#define EGW_ENGINE_ASSETS_CREATIONMSGS      NO      ///< Whether or not to display asset creation messages.
#define EGW_ENGINE_ASSETS_DESTROYMSGS       NO      ///< Whether or not to display asset destroy messages.
#define EGW_ENGINE_ASSETS_ALRDYLDDMSGS      NO      ///< Whether or not to display asset already loaded messages.

// Rendering flags
#define EGW_GFXOBJ_RNDRFLG_DFLT             0x0001  ///< Default render flags.
#define EGW_GFXOBJ_RNDRFLG_FIRSTPASS        0x0001  ///< A first pass rendered object.
#define EGW_GFXOBJ_RNDRFLG_SECONDPASS       0x0002  ///< A second pass rendered object.
#define EGW_GFXOBJ_RNDRFLG_THIRDPASS        0x0004  ///< A third pass rendered object.
#define EGW_GFXOBJ_RNDRFLG_FOURTHPASS       0x0008  ///< A fourth pass rendered object.
#define EGW_GFXOBJ_RNDRFLG_FIFTHPASS        0x0010  ///< A fifth pass rendered object.
#define EGW_GFXOBJ_RNDRFLG_SIXTHPASS        0x0020  ///< A sixth pass rendered object.
#define EGW_GFXOBJ_RNDRFLG_SEVENTHPASS      0x0040  ///< A seventh pass rendered object.
#define EGW_GFXOBJ_RNDRFLG_EIGHTHPASS       0x0080  ///< An eighth pass rendered object.
#define EGW_GFXOBJ_RNDRFLG_ISOPAQUE         0x0100  ///< Object is to be force treated as opaque.
#define EGW_GFXOBJ_RNDRFLG_ISTRANSPARENT    0x0200  ///< Object is to be force treated as transparent.

// Rendering reply flags
#define EGW_GFXOBJ_RPLYFLG_DORENDERSTART    0x0100  ///< Reply flag telling object to perform initial rendering work.
#define EGW_GFXOBJ_RPLYFLY_DORENDERPASS     0x0200  ///< Reply flag telling object to perform rendering work for indicated pass.
#define EGW_GFXOBJ_RPLYFLG_DORENDERPAUSE    0x0400  ///< Reply flag telling object to perform pausing of rendering work.
#define EGW_GFXOBJ_RPLYFLG_DORENDERSTOP     0x0800  ///< Reply flag telling object to stop performing rendering work.
#define EGW_GFXOBJ_RPLYFLG_APISYNCINVLD     0x2000  ///< Reply flag telling object that its API sync validation is being overridden, and should treat it as invalidated.
#define EGW_GFXOBJ_RPLYFLG_SAMELASTBASE     0x4000  ///< Reply flag telling object that its object base was the last to have been utilized. This allows the object to potentially save time having to re-process outer routines that are object local.
#define EGW_GFXOBJ_RPLYFLG_MACHSCHNELL      0x8000  ///< Reply flag telling object that the task timeslice has been extinguished and thus to hurry up. This allows the object to potentially save time by choosing faster, albeit less accurate, functions to employ.
#define EGW_GFXOBJ_RPLYFLG_RENDERPASSMASK   0x00ff  ///< Render pass queue mask.
#define EGW_GFXOBJ_RPLYFLG_ALPHAMODMASK   0xff0000  ///< Material alpha modifier (x100) mask.
#define EGW_GFXOBJ_RPLYFLG_ALPHAMODSHFT         16  ///< Material alpha modifier (x100) shift.
#define EGW_GFXOBJ_RPLYFLG_SHADEMODMASK 0xff000000  ///< Material shade modifier (x100) mask.
#define EGW_GFXOBJ_RPLYFLG_SHADEMODSHFT         24  ///< Material shade modifier (x100) shift.

// Playback flags
#define EGW_SNDOBJ_PLAYFLG_DFLT             0x0002  ///< Default play flags.
#define EGW_SNDOBJ_PLAYFLG_LOWPRI           0x0001  ///< A low priority (ambient) sound.
#define EGW_SNDOBJ_PLAYFLG_MEDPRI           0x0002  ///< A medium priority sound.
#define EGW_SNDOBJ_PLAYFLG_HIGHPRI          0x0004  ///< A high priority sound.
#define EGW_SNDOBJ_PLAYFLG_MUSIC            0x0008  ///< A music based sound. Note: Music based sounds follow a slightly different enqueue semantic.
#define EGW_SNDOBJ_PLAYFLG_LOOPING          0x0100  ///< Sound plays as an infinite loop. Sound stays on playback queue until explicitly stopped.
#define EGW_SNDOBJ_PLAYFLG_AUTOPAUSE        0x0200  ///< Sound should auto-pause playback, thus allowing for full playback, instead of being stopped from playback when unsourced.
#define EGW_SNDOBJ_PLAYFLG_PRIORITY         0x0400  ///< Sound should always go to front of queue upon enqueue (i.e. max priority in queue).
#define EGW_SNDOBJ_PLAYFLG_CANWAIT          0x0800  ///< Sound can wait patiently on queue before being played (i.e. non-time-critical playback).
#define EGW_SNDOBJ_PLAYFLG_STRICT           0x1000  ///< Sound stays strictly on its assigned queue (i.e. does not steal playback slots from a lower queue).

// Playback reply flags
#define EGW_SNDOBJ_RPLYFLG_DOPLYBCKSTART    0x0100  ///< Reply flag telling object to perform initial playback work.
#define EGW_SNDOBJ_RPLYFLY_DOPLYBCKPASS     0x0200  ///< Reply flag telling object to perform playback work, auto-acquiring source.
#define EGW_SNDOBJ_RPLYFLG_DOPLYBCKPAUSE    0x0400  ///< Reply flag telling object to perform pausing of playback work, auto-releasing source.
#define EGW_SNDOBJ_RPLYFLG_DOPLYBCKSTOP     0x0800  ///< Reply flag telling object to stop performing playback work, auto-releasing source.
#define EGW_SNDOBJ_RPLYFLG_BUFFERLOADED     0x1000  ///< Reply flag telling streaming object that a buffer was loaded into audio hardware.
#define EGW_SNDOBJ_RPLYFLG_APISYNCINVLD     0x2000  ///< Reply flag telling object that its API sync validation is being overridden, and should treat it as invalidated.
#define EGW_SNDOBJ_RPLYFLG_SAMELASTBASE     0x4000  ///< Reply flag telling object that its object base was the last to have been utilized. This allows the object to potentially save time having to re-process outer routines that are object local.
#define EGW_SNDOBJ_RPLYFLG_MACHSCHNELL      0x8000  ///< Reply flag telling object that the task timeslice has been extinguished and thus to hurry up. This allows the object to potentially save time by choosing faster, albeit less accurate, functions to employ.
#define EGW_SNDOBJ_RPLYFLG_GAINMODMASK    0xff0000  ///< Gain modifier (x100) mask.
#define EGW_SNDOBJ_RPLYFLG_GAINMODSHFT          16  ///< Gain modifier (x100) shift.
#define EGW_SNDOBJ_RPLYFLG_PITCHMODMASK 0xff000000  ///< Pitch modifier (x100) mask.
#define EGW_SNDOBJ_RPLYFLG_PITCHMODSHFT         24  ///< Pitch modifier (x100) shift.

// Interaction flags
#define EGW_PHYOBJ_INCTFLG_DFLT             0x0004  ///< Default interaction flags.
#define EGW_PHYOBJ_INCTFLG_PREPASS          0x0001  ///< A pre-pass interaction required object.
#define EGW_PHYOBJ_INCTFLG_MAINPASS         0x0004  ///< A main pass interaction object.

// Interaction reply flags
#define EGW_PHYOBJ_RPLYFLG_DOINTRCTSTART    0x0100  ///< Reply flag telling object to perform initial interaction work.
#define EGW_PHYOBJ_RPLYFLG_DOINTRCTPASS     0x0200  ///< Reply flag telling object to perform interaction work for indicated pass.
#define EGW_PHYOBJ_RPLYFLG_DOINTRCTPAUSE    0x0400  ///< Reply flag telling object to perform pausing of interaction work.
#define EGW_PHYOBJ_RPLYFLG_DOINTRCTSTOP     0x0800  ///< Reply flag telling object to stop performing interaction work.
#define EGW_PHYOBJ_RPLYFLG_APISYNCINVLD     0x2000  ///< Reply flag telling object that its API sync validation is being overridden, and should treat it as invalidated.
#define EGW_PHYOBJ_RPLYFLG_SAMELASTBASE     0x4000  ///< Reply flag telling object that its object base was the last to have been utilized. This allows the object to potentially save time having to re-process outer routines that are object local.
#define EGW_PHYOBJ_RPLYFLG_MACHSCHNELL      0x8000  ///< Reply flag telling object that the task timeslice has been extinguished and thus to hurry up. This allows the object to potentially save time by choosing faster, albeit less accurate, functions to employ.
#define EGW_PHYOBJ_RPLYFLG_INTRCTPASSMASK   0x00ff  ///< Interaction pass queue mask.

// Viewing flags
#define EGW_CAMOBJ_VIEWFLG_DFLT             0x0000  ///< Default viewing flags.

// Illumination flags
#define EGW_LGTOBJ_ILLMFLG_DFLT             0x0000  ///< Default illumination flags.

// Texturing flags
#define EGW_TEXOBJ_TXRGFLG_DFLT             0x0000  ///< Default texturing flags.

// Staging flags
#define EGW_STGFLGS_NONE                    0x00    ///< No staging flags.
#define EGW_STGFLGS_ISINVALIDATED           0x01    ///< Stage is invalidated.
#define EGW_STGFLGS_ISUNBOUND               0x02    ///< Stage is unbounded.
#define EGW_STGFLGS_SAMELASTBASE            0x04    ///< Same last base tracking.

// Object tree flags (extends rendering, playback, interaction, viewing, and illumination flags)
#define EGW_OBJTREE_FLG_NOUMRGBVOLS     0x00010000  ///< Object does not upward merge bounding volumes.
#define EGW_OBJTREE_FLG_NOUMRGFLAGS     0x00020000  ///< Object does not upward merge flags.
#define EGW_OBJTREE_FLG_NOUMRGFRAMES    0x00040000  ///< Object does not upward merge frames.
#define EGW_OBJTREE_FLG_NOUMRGSOURCES   0x00080000  ///< Object does not upward merge sources.
#define EGW_OBJTREE_FLG_NOUMRGSYNCS     0x00100000  ///< Object does not upward merge syncs.
#define EGW_OBJTREE_FLG_EXNOUMRG        0x001f0000  ///< Used to extract upward merge usage from bitfield.

// Object extension flags (extends rendering, playback, interaction, viewing, and illumination flags)
#define EGW_OBJEXTEND_FLG_ALWAYSOTGHMG  0x01000000  ///< Object orientation is always orthogonal and homogenous.
#define EGW_OBJEXTEND_FLG_LAZYBOUNDING  0x02000000  ///< Object boundings are done in the cheapest way possible, albeit much more inaccurate.

// Binding flags (extends viewing, illumination, and texturing flags)
#define EGW_BNDOBJ_BINDFLG_DFLT             0x0000  ///< Default binding flags.
#define EGW_BNDOBJ_BINDFLG_TOGGLE           0x1000  ///< Reply flag sent back to object (on context thread) to tell object to toggle on/off its stage.
#define EGW_BNDOBJ_BINDFLG_APISYNCINVLD     0x2000  ///< Reply flag telling object that its API sync validation is being overridden, and should treat it as invalidated.
#define EGW_BNDOBJ_BINDFLG_SAMELASTBASE     0x4000  ///< Reply flag sent back to object (on context thread) to tell object that its object base was the last to have been utilized. This allows the object to potentially save time having to re-process outer routines that are object local.
#define EGW_BNDOBJ_BINDFLG_MACHSCHNELL      0x8000  ///< Reply flag send back to object (on context thread) to tell object that the task timeslice has been extinguished and thus to hurry up. This allows the object to potentially save time by choosing faster, albeit less accurate, methods to employ.

// Actuator flags
#define EGW_ACTOBJ_ACTRFLG_DFLT             0x0000  ///< Default actuator flags.
#define EGW_ACTOBJ_ACTRFLG_REVERSE          0x0001  ///< Actuator updates in reverse fashion (i.e. negated delta time values).
#define EGW_ACTOBJ_ACTRFLG_LOOPING          0x0002  ///< Actuator runs as an infite loop (when applicable, on its last state). Actuator stays on actuator queue until explicitly stopped.
#define EGW_ACTOBJ_ACTRFLG_AUTOENQDS        0x0040  ///< After actuator finishes queued states it auto-enqueues its default state, if not already current (speciality flag, not always applicable).
#define EGW_ACTOBJ_ACTRFLG_NRMLZVECS        0x0080  ///< Actuator attachments renormalize normalizable vectors (e.g. normal vectors, quaternions, etc.) if modified during update (speciality flag, not always applicable).
#define EGW_ACTOBJ_ACTRFLG_THROTTLE20       0x1000  ///< Throttle by 0.20x for each update.
#define EGW_ACTOBJ_ACTRFLG_THROTTLE25       0x2000  ///< Throttle by 0.25x for each update.
#define EGW_ACTOBJ_ACTRFLG_THROTTLE33       0x3000  ///< Throttle by 0.33x for each update.
#define EGW_ACTOBJ_ACTRFLG_THROTTLE50       0x4000  ///< Throttle by 0.50x for each update.
#define EGW_ACTOBJ_ACTRFLG_THROTTLE66       0x5000  ///< Throttle by 0.66x for each update.
#define EGW_ACTOBJ_ACTRFLG_THROTTLE75       0x6000  ///< Throttle by 0.75x for each update.
#define EGW_ACTOBJ_ACTRFLG_THROTTLE88       0x7000  ///< Throttle by 0.88x for each update.
#define EGW_ACTOBJ_ACTRFLG_THROTTLE125      0x8000  ///< Throttle by 1.25x for each update.
#define EGW_ACTOBJ_ACTRFLG_THROTTLE150      0x9000  ///< Throttle by 1.50x for each update.
#define EGW_ACTOBJ_ACTRFLG_THROTTLE200      0xa000  ///< Throttle by 2.00x for each update.
#define EGW_ACTOBJ_ACTRFLG_THROTTLE250      0xb000  ///< Throttle by 2.50x for each update.
#define EGW_ACTOBJ_ACTRFLG_THROTTLE300      0xc000  ///< Throttle by 3.00x for each update.
#define EGW_ACTOBJ_ACTRFLG_THROTTLE400      0xd000  ///< Throttle by 4.00x for each update.
#define EGW_ACTOBJ_ACTRFLG_THROTTLE500      0xe000  ///< Throttle by 5.00x for each update.
#define EGW_ACTOBJ_ACTRFLG_EXTHROTTLE       0xf000  ///< Used to extract throttling usage from bitfield.

// Actuator reply flags
#define EGW_ACTOBJ_RPLYFLG_DOUPDATESTART    0x0001  ///< Reply flag telling object to perform initial actuation work.
#define EGW_ACTOBJ_RPLYFLG_DOUPDATEPASS     0x0002  ///< Reply flag telling object to perform actuation work.
#define EGW_ACTOBJ_RPLYFLG_DOUPDATEPAUSE    0x0004  ///< Reply flag telling object to perform pausing of actuation work.
#define EGW_ACTOBJ_RPLYFLG_DOUPDATESTOP     0x0008  ///< Reply flag telling object to stop performing actuation work.
#define EGW_ACTOBJ_RPLYFLG_APISYNCINVLD     0x2000  ///< Reply flag telling object that its API sync validation is being overridden, and should treat it as invalidated.
#define EGW_ACTOBJ_RPLYFLG_SAMELASTBASE     0x4000  ///< Reply flag telling object that its object base was the last to have been utilized. This allows the object to potentially save time having to re-process outer routines that are object local.
#define EGW_ACTOBJ_RPLYFLG_MACHSCHNELL      0x8000  ///< Reply flag telling object that the task timeslice has been extinguished and thus to hurry up. This allows the object to potentially save time by choosing faster, albeit less accurate, functions to employ.

// Zero offset alignment flags
#define EGW_GFXOBJ_ZFALIGN_DFLT             0x2220  ///< Default offset alignment flags.
#define EGW_GFXOBJ_ZFALIGN_XMIN             0x1000  ///< Offset x-axis zero to minimum edge of object.
#define EGW_GFXOBJ_ZFALIGN_XCTR             0x2000  ///< Offset x-axis zero to center of object.
#define EGW_GFXOBJ_ZFALIGN_XMAX             0x4000  ///< Offset x-axis zero to maximum edge of object.
#define EGW_GFXOBJ_ZFALIGN_YMIN             0x0100  ///< Offset y-axis zero to minimum edge of object.
#define EGW_GFXOBJ_ZFALIGN_YCTR             0x0200  ///< Offset y-axis zero to center of widget.
#define EGW_GFXOBJ_ZFALIGN_YMAX             0x0400  ///< Offset y-axis zero to maximum edge of object.
#define EGW_GFXOBJ_ZFALIGN_ZMIN             0x0010  ///< Offset z-axis zero to minimum edge of object.
#define EGW_GFXOBJ_ZFALIGN_ZCTR             0x0020  ///< Offset z-axis zero to center of widget.
#define EGW_GFXOBJ_ZFALIGN_ZMAX             0x0040  ///< Offset z-axis zero to maximum edge of object.
#define EGW_GFXOBJ_ZFALIGN_XINV             0x0001  ///< Offset x-axis by inversion.
#define EGW_GFXOBJ_ZFALIGN_YINV             0x0002  ///< Offset y-axis by inversion.
#define EGW_GFXOBJ_ZFALIGN_ZINV             0x0004  ///< Offset z-axis by inversion.
#define EGW_GFXOBJ_ZFALIGN_EXX              0xf000  ///< Used to extract x-axis offset usage from bitfield.
#define EGW_GFXOBJ_ZFALIGN_EXY              0x0f00  ///< Used to extract y-axis offset usage from bitfield.
#define EGW_GFXOBJ_ZFALIGN_EXZ              0x00f0  ///< Used to extract z-axis offset usage from bitfield.
#define EGW_GFXOBJ_ZFALIGN_EXINV            0x000f  ///< Used to extract axis inversion usage from bitfield.

// Frame flags
#define EGW_FRAME_ALWAYSPASS                0x0000  ///< Special frame number that signifies always pass status.
#define EGW_FRAME_ALWAYSFAIL                0xffff  ///< Special frame number that signifies always fail status.

// Action flags
#define EGW_ACTION_START                    0x0001  ///< Item started (via run in) behavior.
#define EGW_ACTION_RESTART                  0x0002  ///< Item restarted (via interrupt) behavior.
#define EGW_ACTION_HOOK                     0x0004  ///< Item hooked behavior.
#define EGW_ACTION_VALIDATE                 0x0008  ///< Item validated behavior.
#define EGW_ACTION_PAUSE                    0x0010  ///< Item paused behavior.
#define EGW_ACTION_UNPAUSE                  0x0020  ///< Item unpaused behavior.
#define EGW_ACTION_STOP                     0x0100  ///< Item stopped (via interrupt) behavior.
#define EGW_ACTION_FINISH                   0x0200  ///< Item finished (via run out) behavior.
#define EGW_ACTION_UNHOOK                   0x0400  ///< Item unhooked behavior.
#define EGW_ACTION_INVALIDATE               0x0800  ///< Item invalidated behavior.
#define EGW_ACTION_LOOPED                   0x1000  ///< Item looped behavior.
#define EGW_ACTION_EXBEGIN                  0x000f  ///< Used to extract usage that begins behavior.
#define EGW_ACTION_EXTOGGLE                 0x00f0  ///< Used to extract usage that toggles behavior.
#define EGW_ACTION_EXEND                    0x0f00  ///< Used to extract usage that ends behavior.

// Core component types
#define EGW_CORECMP_TYPE_NONE               0x0000  ///< No core component type.
#define EGW_CORECMP_TYPE_INTERNAL           0x0001  ///< Internal core component type.
#define EGW_CORECMP_TYPE_BVOLS              0x0002  ///< Bounding volumes core component type.
#define EGW_CORECMP_TYPE_FLAGS              0x0004  ///< Flags core component type.
#define EGW_CORECMP_TYPE_FRAMES             0x0008  ///< Frames core component type.
#define EGW_CORECMP_TYPE_SOURCES            0x0010  ///< Sources core component type.
#define EGW_CORECMP_TYPE_SYNCS              0x0020  ///< Validation synchronizations core component type.
#define EGW_CORECMP_TYPE_ALL            0xffffffff  ///< All core component types.

// Core object types
#define EGW_COREOBJ_TYPE_NONE               0x0000  ///< No core object type.
#define EGW_COREOBJ_TYPE_INTERNAL           0x0001  ///< Internal core object type.
#define EGW_COREOBJ_TYPE_ACTUATOR           0x0002  ///< Actuator core object type.
#define EGW_COREOBJ_TYPE_ANIMATE            0x0004  ///< Interactable core object type.
#define EGW_COREOBJ_TYPE_AUDIO              0x0008  ///< Audible core object type.
#define EGW_COREOBJ_TYPE_CAMERA             0x0010  ///< Viewable core object type.
#define EGW_COREOBJ_TYPE_FONT               0x0020  ///< Font core object type.
#define EGW_COREOBJ_TYPE_GRAPHIC            0x0040  ///< Renderable core object type.
#define EGW_COREOBJ_TYPE_HOOKABLE           0x0080  ///< Hooked core object type.
#define EGW_COREOBJ_TYPE_INTERPOLATOR       0x0100  ///< Interpolator core object type.
#define EGW_COREOBJ_TYPE_LIGHT              0x0200  ///< Light core object type.
#define EGW_COREOBJ_TYPE_MATERIAL           0x0400  ///< Material core object type.
#define EGW_COREOBJ_TYPE_NODE               0x0800  ///< Object node core object type.
#define EGW_COREOBJ_TYPE_ORIENTABLE         0x1000  ///< Orientable core object type.
#define EGW_COREOBJ_TYPE_PROXY              0x2000  ///< Proxy core object type.
#define EGW_COREOBJ_TYPE_PHYSICAL           0x4000  ///< Physical core object type.
#define EGW_COREOBJ_TYPE_TEXTURE            0x8000  ///< Texturable core object type.
#define EGW_COREOBJ_TYPE_TIMER             0x10000  ///< Timer core object type.
#define EGW_COREOBJ_TYPE_WIDGET            0x20000  ///< Widget core object type.
#define EGW_COREOBJ_TYPE_ALL            0xffffffff  ///< All core object types.


// !!!: ***** Init Parameters *****

/// Graphics Context Parameters.
/// Contains optional parameters for context initialization.
typedef struct {
    id<egwDGfxContextEvent> delegate;       ///< Optional event responder (retained).
    EGWint8 fbCount;                        ///< Number of primary framebuffers. Valid values are 1 (single buffered) and 2 (double buffered). Default(0) is 2.
    EGWint8 fbDepth;                        ///< Bit depth of primary framebuffer(s). Valid values are 16 (RGB/565), 24 (RGB/8), and 32 (RGBA/8). Default(0) is 16.
    EGWuint16 fbWidth;                      ///< Width of primary framebuffer(s). Default(0) is auto-full-screen width (if available).
    EGWuint16 fbHeight;                     ///< Height of primary framebuffer(s). Default(0) is auto-full-screen height (if available).
    EGWint8 fbClear;                        ///< Flag indicating to clear framebuffer(s) upon startRender. Valid values are -1 (no), and 1 (yes). Default(0) is 1 with a fbClearColor of <0.5, 0.5, 0.5, 1.0>.
    egwColor4f fbClearColor;                ///< Framebuffer clearing color. Valid values are in range [0.0,1.0].
    EGWint8 fbAlphaTest;                    ///< Flag indicating that framebuffer(s) use an alpha pass cutoff value. Valid values are -1 (disabled), 1 (>=), and 2 (>). Default(0) is 1 with a fbAlphaPassValue of 0.25.
    EGWsingle fbAlphaCutoff;                ///< Alpha pass cutoff value. Valid values are in range [0,1].
    EGWint8 zbDepth;                        ///< Bit depth of primary Z-depth buffer. Valid values are -1 (unused), 16, 24, and 32. Default(0) is 16 with a fbDepthTest of 1.
    EGWint8 zbClear;                        ///< Flag indicating to clear Z-depth buffer upon startRender. Valid values are -1 (no), and 1 (yes). Default(0) is 1 with a zbClearColor of <1.0>.
    egwColor1f zbClearColor;                ///< Z-depth buffer clearing color. Valid values are in range [0.0,1.0].
    EGWint8 zbDepthTest;                    ///< Flag indiciating z-buffer depth testing. Valid values are -1 (disabled), 1 (<), and 2 (<=).
    EGWint8 sbDepth;                        ///< Bit depth of primary stencil buffer. Valid values are -1 (unused), 1, 4, and 8. Default(0) is -1.   
    EGWint8 sbClear;                        ///< Flag indicating to clear stencil buffer upon startRender. Valid values are -1 (no), and 1 (yes). Default(0) is 1 with a sbClearColor of <0>.
    egwColorGS sbClearColor;                ///< Stencil buffer clearing color. Valid values are in range [0,(2^sbDepth)-1].
    EGWint8 fbResize;                       ///< Flag indiciating framebuffer(s) resize upon view resize. Valid values are -1 (no), and 1 (yes). Default(0) is -1.
    void* contextData;                      ///< Context specific data.
} egwGfxCntxParams;

/// Graphics Renderer Parameters.
/// Contains optional parameters for task initialization.
typedef struct {
    EGWuint mode;                           ///< Bit-wise renderer mode settings (0 defaults).
    double priority;                        ///< Priority of dedicated task thread [0,1] (default: 0.5).
} egwGfxRdrParams;


/// Physics Context Parameters.
/// Contains optional parameters for context initialization.
typedef struct {
    id<egwDPhyContextEvent> delegate;       ///< Optional event responder (retained).
} egwPhyCntxParams;

/// Physical Actuator Parameters.
/// Contains optional parameters for task initialization.
typedef struct {
    EGWuint mode;                           ///< Bit-wise renderer mode settings (0 defaults).
    double priority;                        ///< Priority of dedicated task thread [0,1] (default: 0.5).
} egwPhyActParams;


/// Sound Context Parameters.
/// Contains optional parameters for context initialization.
typedef struct {
    id<egwDSndContextEvent> delegate;       ///< Optional event responder (retained).
    EGWuint32 mixerFreq;                    ///< Frequency (in Hz) that mixer should operate on. Default: 22050.
    EGWuint16 refreshIntvl;                 ///< Refresh interval frequency (in Hz) that mixer should operate on. Default: 5.
    EGWuint16 limitSources;                 ///< User defined limit to # of sources to work with. Note: May be capped by hardware limitations.
    NSString* deviceName;                   ///< Name of audio device to attach to.
    //float speedOfSound;                   ///< Speed of sound in native units.
    //EGWuint distanceModel;                ///< Distance model accuracy (0
    //AL_SPEED_OF_SOUND
    //AL_DISTANCE_MODEL
    //AL_DOPPLER_FACTOR/VELOCITY
} egwSndCntxParams;

/// Sound Mixer Parameters.
/// Contains optional parameters for task initialization.
typedef struct {
    EGWuint mode;                           ///< Bit-wise renderer mode settings (0 defaults).
    double priority;                        ///< Priority of dedicated task thread [0,1] (default: 0.5).
} egwSndMxrParams;

/// @}

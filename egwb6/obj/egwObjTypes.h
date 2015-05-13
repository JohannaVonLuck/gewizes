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

/// @defgroup geWizES_obj_types egwObjTypes
/// @ingroup geWizES_obj
/// Object Types.
/// @{

/// @file egwObjTypes.h
/// Object Types.

#import "../inf/egwTypes.h"
#import "../inf/egwPBounding.h"
#import "../math/egwMathTypes.h"
#import "../misc/egwMiscTypes.h"


// !!!: ***** Predefs *****

@class egwObjectBranch;
@class egwSwitchBranch;
@class egwTransformBranch;
@class egwDLODBranch;


// !!!: ***** Defines *****

// Message directions
#define EGW_NODEMSG_DIR_TOPARENTS           0x0001  ///< Invocate message to parents.
#define EGW_NODEMSG_DIR_TOSELF              0x0002  ///< Invocate message to self.
#define EGW_NODEMSG_DIR_TOCHILDREN          0x0004  ///< Invocate message to children.
#define EGW_NODEMSG_DIR_ORDERCSP            0x0010  ///< Invocate message in CSP order (children, self, parent).
#define EGW_NODEMSG_DIR_ORDERPSC            0x0020  ///< Invocate message in PSC order (parent, self, children).
#define EGW_NODEMSG_DIR_BREADTHUPWARDS      0x0013  ///< Invocate message "breadth-first-search upwards" (self, parent).
#define EGW_NODEMSG_DIR_DEPTHUPWARDS        0x0023  ///< Invocate message "depth-first-search upwards" (parent, self).
#define EGW_NODEMSG_DIR_BREADTHDOWNWARDS    0x0026  ///< Invocate message "breadth-first-search downwards" (self, children).
#define EGW_NODEMSG_DIR_DEPTHDOWNWARDS      0x0016  ///< Invocate message "depth-first-search downwards" (children, self).
#define EGW_NODEMSG_DIR_LINEBROADCAST       0x0007  ///< Invocate message on branch line.
#define EGW_NODEMSG_DIR_FULLBROADCAST       0x1000  ///< Invocate message to all objects in tree, starting at root.
#define EGW_NODEMSG_DIR_EXCLUDEHIDDEN       0x2000  ///< Avoids invocating message to hidden objects (e.g. switch nodes).

/// Implicit node direction used when not explicitly stated.
#define EGW_NODEMSG_DIR_DEFAULT             EGW_NODEMSG_DIR_BREADTHDOWNWARDS

/// Core component types used when merging audio components.
#define EGW_NODECMPMRG_AUDIO                (EGW_CORECMP_TYPE_SOURCES | EGW_CORECMP_TYPE_INTERNAL)
/// Core component types used when merging graphic components.
#define EGW_NODECMPMRG_GRAPHIC              (EGW_CORECMP_TYPE_BVOLS | EGW_CORECMP_TYPE_SOURCES | EGW_CORECMP_TYPE_INTERNAL)
/// Core component types used when merging animate components.
#define EGW_NODECMPMRG_ANIMATE              (EGW_CORECMP_TYPE_BVOLS | EGW_CORECMP_TYPE_SOURCES | EGW_CORECMP_TYPE_INTERNAL)
/// Core component types used when merging camera components.
#define EGW_NODECMPMRG_CAMERA               (EGW_CORECMP_TYPE_INTERNAL)
/// Core component types used when merging light components.
#define EGW_NODECMPMRG_LIGHT                (EGW_CORECMP_TYPE_INTERNAL)
/// Core component types used when merging audio, graphic, animate, camera, and/or light components.
#define EGW_NODECMPMRG_COMBINED             (EGW_NODECMPMRG_AUDIO | EGW_NODECMPMRG_GRAPHIC | EGW_NODECMPMRG_ANIMATE | EGW_NODECMPMRG_CAMERA | EGW_NODECMPMRG_LIGHT)


// !!!: ***** Structures *****

/// Core Component Set.
/// Provides a redux component set for various core types.
typedef struct {
    EGWuint16 invalidations;                ///< Tracked core component invalidations.
    id<egwPBounding> bVol;                  ///< Bounding volume (retained).
    EGWuint flags;                          ///< Flags.
    EGWuint16 frame;                        ///< Frame.
    egwVector4f source;                     ///< Source position.
    egwValidater* sync;                     ///< Validation sync (retained).
} egwCoreComponents;

/// @}

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

/// @defgroup geWizES_sys_gfxcontexteagles egwGfxContextEAGLES
/// @ingroup geWizES_sys
/// iPhone OpenGLES Graphics Context.
/// @{

/// @file egwGfxContextEAGLES.h
/// iPhone OpenGLES Graphics Context Interface.

#import "egwSysTypes.h"
#import "egwGfxContext.h"
#import "egwGfxContextAGL.h"


#if defined(EGW_BUILDMODE_IPHONE)
#define EGW_BUILDMODE_GFX_EAGLES

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>


/// iPhone OpenGLES Graphics Context.
/// Contains contextual data related to an iPhone OpenGLES graphics API.
@interface egwGfxContextEAGLES : egwGfxContextAGL {
    EAGLContext* _context;                  ///< OpenGLES/EAGL context data.
    GLuint _frameBuffer;                    ///< Main frame buffer.
    GLuint _colorBuffer;                    ///< Main color buffer.
    GLuint _depthBuffer;                    ///< Main depth buffer.
    GLuint _stencilBuffer;                  ///< Main stencil buffer.
}
@end


#else

/// iPhone OpenGLES Graphics Context (Blank).
/// Contains a placeholder to the actual class in the invalid build case.
@interface egwGfxContextEAGLES : egwGfxContextAGL {
}
@end

#endif


/// Global currently active egwGfxContextNSGL instance (weak).
extern egwGfxContextEAGLES* egwAIGfxCntxEAGLES;

/// @}

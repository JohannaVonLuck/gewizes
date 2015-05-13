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

/// @defgroup geWizES_gui_types egwGuiTypes
/// @ingroup geWizES_gui
/// GUI Types.
/// @{

/// @file egwGuiTypes.h
/// GUI Types.

#import "../inf/egwTypes.h"
#import "../inf/egwPHook.h"
#import "../math/egwMathTypes.h"


// !!!: ***** Predefs *****

@class egwButton;
@class egwImage;
@class egwImageBase;
@class egwSpritedImage;
@class egwSpritedImageBase;
//@class egwStreamedImage;
//@class egwStreamedImageBase;
@class egwLabel;
//@class egwScrolledLabel;
@class egwPager;
@class egwSlider;
@class egwSliderBase;
@class egwToggle;


// !!!: ***** Defines *****

#define EGW_WIDGET_TXCCORRECT   0.0025f     ///< Widget texture coordinate correction amount.


// !!!: ***** Structures *****

/// Static Quad Vertex Array Mesh.
/// Static single quad mesh structure (useful for the very common rectangular widgets).
typedef struct {
    egwVector3f vCoords[4];                 ///< Vertex coordinates.
    egwVector3f nCoords[4];                 ///< Normal coordiantes.
    egwVector2f tCoords[4];                 ///< Texture coordinates.
} egwSQVAMesh4f;


// !!!: ***** Event Delegate Protocols *****

/// Widget Event Delegate.
/// Defines events that a delegate object can handle.
@protocol egwDWidgetEvent <NSObject>

/// Widget Did Behavior.
/// Called when a widget object performs a behavior related to rendering and hooking.
/// @param [in] widget Widget object.
/// @param [in] action Behavioral flag setting (EGW_ACTION_*).
- (void)widget:(id<egwPWidget>)widget did:(EGWuint32)action;

@end

/// Button Event Delegate.
/// Defines events that a delegate object can handle.
@protocol egwDButtonEvent <egwDWidgetEvent>

/// Button Did Press.
/// Called when a button presses.
/// @param [in] button Button object.
- (void)buttonDidPress:(egwButton*)button;

@end

/// Pager Event Delegate.
/// Defines events that a delegate object can handle.
@protocol egwDPagerEvent <egwDWidgetEvent>

/// Pager Did Change To Page.
/// Called when a pager switches to another page.
/// @param [in] pager Pager object.
/// @param [in] page Active page index (may be 0 for none).
- (void)pagerDidChange:(egwPager*)pager toPage:(EGWuint)page;

@end

/// Slider Event Delegate.
/// Defines events that a delegate object can handle.
@protocol egwDSliderEvent <egwDWidgetEvent>

/// Slider Did Change To Offset.
/// Called when a slider changes its offset.
/// @param [in] slider Slider object.
/// @param [in] offset Slider offset [0, 1].
- (void)sliderDidChange:(egwSlider*)slider toOffset:(EGWsingle)offset;

@end

/// Toggle Event Delegate.
/// Defines events that a delegate object can handle.
@protocol egwDToggleEvent <egwDWidgetEvent>

/// Toggle Did Change To Status.
/// Called when a toggle changes its toggle status.
/// @param [in] toggle Toggle object.
/// @param [in] status Toggled status.
- (void)toggleDidChange:(egwToggle*)toggle toStatus:(BOOL)status;

@end

/// @}

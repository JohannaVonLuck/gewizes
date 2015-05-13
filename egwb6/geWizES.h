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

/// @defgroup geWizES geWizES: Engine
/// geWizES: Engine
/// @{

/// @file geWizES.h
/// Base Include File.
/// 
///        ...cWW0kkkkkkkkkkkkkkKMN;..
///         ...OMXO------------ONMx...
///          ..;NM0------------KM0'..
///          ...oWNO----------OWN;..
///.....      ...OMKO--------ONMd...     .....
///:Odc;'........cWW0--------KMN,........':lxO.
///:XNWWN0kdc;'..'KMK--------XMk...,:ldkKNWWXX.
///:OkOO0KXXNNNXKOXMNO------OWMK0KXNNNXKK0OOOO.
///:OO-------OO00KKXKO------OXXKK0OO--------OO.
///:OO--------------------------------------OO.
///:OO------------------DE------------------OO.
///:OO--------------------------------------OO.
///:OO------OOO0KKKXXO------OXXKK00OO-------OO.
///:OkOO0KXNWWWXKOXMNO------OWMK0KNWWNXXK0O-OO.
///cXNWNKOxoc;,..'KMK--------XMk...,:cdxOXNNXX.
///;xl;'.........lMWO--------0MN;.........':ox.
///.....      ...0MKk--------OXMx...      ....
///          ...oWNO----------OWN:...
///          ..:WW0------------KMK,..
///         ...0MX-------------ONMx...
///        ...;kkolllllllllllllldkx'..
/// 


// !!!: ***** Doxygen Groups *****

/// @defgroup geWizES_inf geWizES: Infrastructure
/// Infrastructure

/// @defgroup geWizES_sys geWizES: System
/// System

/// @defgroup geWizES_hwd geWizES: Window Handling
/// Window Handling

/// @defgroup geWizES_data geWizES: Datamatics Library
/// Datamatics Library

/// @defgroup geWizES_math geWizES: Mathematics Library
/// Mathematics Library

/// @defgroup geWizES_ai geWizES: AI Library
/// Artificial Intelligence Library

/// @defgroup geWizES_gfx geWizES: Graphics Library
/// Graphics Library

/// @defgroup geWizES_geo geWizES: Geometry Library
/// Geometry Library

/// @defgroup geWizES_gui geWizES: GUI Library
/// Graphical User Interface Library

/// @defgroup geWizES_net geWizES: Networking Library
/// Networking Library

/// @defgroup geWizES_obj geWizES: Object Library
/// Object Library

/// @defgroup geWizES_phy geWizES: Physics Library
/// Physics Library

/// @defgroup geWizES_snd geWizES: Sound Library
/// Sound Library

/// @defgroup geWizES_misc geWizES: Miscellaneous Library
/// Miscellaneous Library


// !!!: ***** Prefix Imports *****

#import "inf/egwTypes.h"
#import "sys/egwSysTypes.h"
#import "hwd/egwHwdTypes.h"
#import "data/egwDataTypes.h"
#import "math/egwMathTypes.h"
#import "ai/egwAiTypes.h"
#import "gfx/egwGfxTypes.h"
#import "geo/egwGeoTypes.h"
#import "gui/egwGuiTypes.h"
#import "net/egwNetTypes.h"
#import "obj/egwObjTypes.h"
#import "phy/egwPhyTypes.h"
#import "snd/egwSndTypes.h"
#import "misc/egwMiscTypes.h"

#import "inf/egwPContext.h"
#import "inf/egwPGfxContext.h"
#import "inf/egwPPhyContext.h"
#import "inf/egwPSndContext.h"
#import "inf/egwPHook.h"
#import "inf/egwPScreen.h"
#import "inf/egwPSingleton.h"
#import "inf/egwPTask.h"
#import "inf/egwPSubTask.h"
#import "inf/egwPAsset.h"
#import "inf/egwPAssetBase.h"
#import "inf/egwPCoreObject.h"
#import "inf/egwPObjNode.h"
#import "inf/egwPObjBranch.h"
#import "inf/egwPObjLeaf.h"
#import "inf/egwPInteractable.h"
#import "inf/egwPPlayable.h"
#import "inf/egwPRenderable.h"
#import "inf/egwPActioned.h"
#import "inf/egwPActuator.h"
#import "inf/egwPBounding.h"
#import "inf/egwPCamera.h"
#import "inf/egwPFont.h"
#import "inf/egwPGeometry.h"
#import "inf/egwPInterpolator.h"
#import "inf/egwPLight.h"
#import "inf/egwPMaterial.h"
#import "inf/egwPOrientated.h"
#import "inf/egwPShader.h"
#import "inf/egwPSound.h"
#import "inf/egwPStreamed.h"
#import "inf/egwPStreamer.h"
#import "inf/egwPTexture.h"
#import "inf/egwPTimed.h"
#import "inf/egwPTimer.h"
#import "inf/egwPWarned.h"
#import "inf/egwPWidget.h"

#import "sys/egwSystem.h"
#import "sys/egwEngine.h"
#import "sys/egwAssetManager.h"
#import "sys/egwScreenManager.h"
#import "sys/egwTaskManager.h"
#import "sys/egwGfxContext.h"
#import "sys/egwGfxContextAGL.h"
#import "sys/egwGfxContextNSGL.h"
#import "sys/egwGfxContextEAGLES.h"
#import "sys/egwGfxRenderer.h"
#import "sys/egwPhyContext.h"
#import "sys/egwPhyContextSW.h"
#import "sys/egwPhyActuator.h"
#import "sys/egwSndContext.h"
#import "sys/egwSndContextAL.h"
#import "sys/egwSndMixer.h"

#import "hwd/egwWindow.h"
#import "hwd/egwUIDeviceExt.h"
#import "hwd/egwUIViewSurface.h"
#import "hwd/egwNSOpenGLViewSurface.h"
#import "hwd/egwTouchDecoder.h"
#import "hwd/egwMouseDecoder.h"

#import "data/egwData.h"
#import "data/egwArray.h"
#import "data/egwCyclicArray.h"
#import "data/egwSinglyLinkedList.h"
#import "data/egwDoublyLinkedList.h"
#import "data/egwAVLTree.h"
#import "data/egwRedBlackTree.h"

#import "math/egwMath.h"
#import "math/egwVector.h"
#import "math/egwMatrix.h"
#import "math/egwQuaternion.h"

#import "ai/egwIntellect.h"
#import "ai/egwFiniteStateMachine.h"
#import "ai/egwArtificialNeuralNetwork.h"

#import "gfx/egwGraphics.h"
#import "gfx/egwBindingStacks.h"
#import "gfx/egwBoundings.h"
#import "gfx/egwCameras.h"
#import "gfx/egwFonts.h"
#import "gfx/egwLights.h"
#import "gfx/egwMaterials.h"
#import "gfx/egwRenderProxy.h"
#import "gfx/egwTexture.h"
#import "gfx/egwSpritedTexture.h"
#import "gfx/egwStreamedTexture.h"

#import "geo/egwGeometry.h"
#import "geo/egwBillboard.h"
#import "geo/egwMesh.h"
#import "geo/egwKeyFramedMesh.h"
#import "geo/egwSkeletalBonedMesh.h"
#import "geo/egwParticleSystem.h"

#import "gui/egwInterface.h"
#import "gui/egwButton.h"
#import "gui/egwImage.h"
#import "gui/egwSpritedImage.h"
#import "gui/egwStreamedImage.h"
#import "gui/egwLabel.h"
#import "gui/egwScrolledLabel.h"
#import "gui/egwPager.h"
#import "gui/egwSlider.h"
#import "gui/egwToggle.h"

#import "net/egwNetwork.h"

#import "obj/egwObject.h"
#import "obj/egwObjectBranch.h"
#import "obj/egwSwitchBranch.h"
#import "obj/egwTransformBranch.h"
#import "obj/egwDLODBranch.h"

#import "phy/egwPhysics.h"
#import "phy/egwInterpolators.h"
#import "phy/egwSpring.h"

#import "snd/egwSound.h"
#import "snd/egwPointSound.h"
#import "snd/egwStreamedPointSound.h"

#import "misc/egwMisc.h"
#import "misc/egwBoxingTypes.h"
#import "misc/egwTimer.h"
#import "misc/egwActionedTimer.h"
#import "misc/egwActionedTimersArray.h"
#import "misc/egwStreamer.h"
#import "misc/egwValidater.h"

/// @}

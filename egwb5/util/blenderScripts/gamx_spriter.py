#!BPY

"""
Name: 'GAMX Sprite Sheet Renderer'
Blender: 249
Group: 'Render'
Tooltip: 'Render current scene, on selected animations and camera, to sprite sheet along with a v1.0 GAMX asset manifest file (.gamx)'
"""
__author__ = "Johanna Wolf"
__url__ = ("http://gewizes.sourceforge.net/")
__version__ = "0.7"
__email__ = "johanna.a.wolf@gmail.com"
__bpydoc__ = """\
Description: Render current scene, on selected animations and camera, to sprite sheet along with a v1.0 GAMX asset manifest file (.gamx).
Usage: Run the script from the menu or inside Blender. 
"""

# Required modules
import sys
import math
import random       # Used to make name of temporary folder to put renders into
import os.path
import shutil       # Used for folder tree removal
import inspect      # Used for script filename identification (for .sav rename)
import pickle       # Used for settings save/load
import bpy
import Blender
from Blender import *
try:
    import Image
except:
    Blender.Draw.PupMenu("Module 'Image' was unable to load. Please consult install instructions.|Ok")
    raise

# Global settings
endl = "\n"
tab4 = "    "
start_timeoff_perc = 0.001
end_timeoff_perc = 0.01
name_prefix = ""
file_prefix = ""
anim_fps = 25.0
dir_slices = 1
sprite_width = 64
sprite_height = 64
sheet_width = 1024
sheet_height = 1024
use_sth_dir0 = False
use_spc_dirs = False
use_pow2_sclup = True
default_act = 0
last_folder = os.path.abspath(os.path.dirname(Blender.Get("filename")))

# Tries to load options from .sav file (named same as running script)
def gamx_try_load_options():
    global name_prefix
    global file_prefix
    global anim_fps
    global dir_slices
    global sprite_width
    global sprite_height
    global sheet_width
    global sheet_height
    global use_sth_dir0
    global use_spc_dirs
    global use_pow2_sclup
    global default_act
    global last_folder
    try:
        filename = os.path.splitext(os.path.abspath(inspect.getfile(inspect.currentframe())))[0] + ".sav"
        if os.path.exists(filename):
            fin = open(filename, "r")
            try:
                dict = pickle.load(fin)
            except:
                pass
            finally:
                fin.close()
            if dict["version"] == 1:
                name_prefix = dict["name_prefix"]
                file_prefix = dict["file_prefix"]
                anim_fps = dict["anim_fps"]
                dir_slices = dict["dir_slices"]
                sprite_width = dict["sprite_width"]
                sprite_height = dict["sprite_height"]
                sheet_width = dict["sheet_width"]
                sheet_height = dict["sheet_height"]
                use_sth_dir0 = dict["use_sth_dir0"]
                use_spc_dirs = dict["use_spc_dirs"]
                use_pow2_sclup = dict["use_pow2_sclup"]
                default_act = dict["default_act"]
                last_folder = dict["last_folder"]
    except:
        pass

# Tries to save options to .sav file (named same as running script)
def gamx_try_save_options():
    try:
        filename = os.path.splitext(os.path.abspath(inspect.getfile(inspect.currentframe())))[0] + ".sav"
        dict = { }
        dict["version"] = 1
        dict["name_prefix"] = name_prefix
        dict["file_prefix"] = file_prefix
        dict["anim_fps"] = anim_fps
        dict["dir_slices"] = dir_slices
        dict["sprite_width"] = sprite_width
        dict["sprite_height"] = sprite_height
        dict["sheet_width"] = sheet_width
        dict["sheet_height"] = sheet_height
        dict["use_sth_dir0"] = use_sth_dir0
        dict["use_spc_dirs"] = use_spc_dirs
        dict["use_pow2_sclup"] = use_pow2_sclup
        dict["default_act"] = default_act
        dict["last_folder"] = last_folder
        fout = open(filename, "w")
        try:
            pickle.dump(dict, fout)
        except:
            pass
        finally:
            fout.close()
    except:
        pass

# Puts value in range [0,2pi)
def gamx_radreduce(val):
    while val < 0.0 - 0.000001:
        val += 6.28318531
    while val >= 6.28318531 - 0.000001:
        val -= 6.28318531
    return val

# Puts value into deg from rad
def gamx_radtodeg(val):
    return val * 57.295780

# Rounds up to nearest power of 2
def gamx_round_up_pow2(val):
    val -= 1
    val |= val >> 1
    val |= val >> 2
    val |= val >> 4
    val |= val >> 8
    val |= val >> 16
    val += 1
    return val

# Figures out best size to use for current frame count and sizes
def gamx_opt_pow2_sprt_frmg(spriteSize, maxSize, fCount, bestSize_out):
    maxCols = maxSize[0] / spriteSize[0]
    maxRows = maxSize[1] / spriteSize[1]
    if fCount < maxCols * maxRows:
        stdUsage = fCount * (spriteSize[0] * spriteSize[1])
        currCols = maxCols
        bestCols = currCols
        currRows = (fCount + (currCols - 1)) / currCols # ceil(fCount/currCols)
        bestRows = currRows
        currLeftOver = (gamx_round_up_pow2(currCols * spriteSize[0]) * gamx_round_up_pow2(currRows * spriteSize[1])) - stdUsage
        bestLeftOver = currLeftOver
        while currCols > 1 and currRows <= maxRows:
            currCols -= 1
            currRows = (fCount + (currCols - 1)) / currCols # ceil(fCount/currCols)
            if currRows <= maxRows:
                currLeftOver = (gamx_round_up_pow2(currCols * spriteSize[0]) * gamx_round_up_pow2(currRows * spriteSize[1])) - stdUsage
                if currLeftOver < bestLeftOver or (currLeftOver == bestLeftOver and abs(currCols - currRows) <= abs(bestCols - bestRows)):
                    bestCols = currCols
                    bestRows = currRows
                    bestLeftOver = currLeftOver
        bestSize_out[0] = bestCols * spriteSize[0]
        bestSize_out[1] = bestRows * spriteSize[1]
        return bestCols * bestRows
    elif maxCols and maxRows:
        bestSize_out[0] = maxSize[0]
        bestSize_out[1] = maxSize[1]
        return maxCols * maxRows
    else: # too big for even 1 sprite
        bestSize_out[0] = 0
        bestSize_out[1] = 0
        return 0

def gamx_spriter_gui(filename):
    global name_prefix
    global file_prefix
    global anim_fps
    global dir_slices
    global sprite_width
    global sprite_height
    global sheet_width
    global sheet_height
    global use_sth_dir0
    global use_spc_dirs
    global use_pow2_sclup
    global default_act
    global last_folder
    tempsFolder = os.path.join(os.path.dirname(filename), "temp%08x/" % random.getrandbits(32))
    
    try:
        # Perform some initial setting up and checks
        try:
            scene = Blender.Scene.GetCurrent()
        except:
            scene = None
        finally:
            if scene == None:
                Blender.Draw.PupMenu("There is not a current scene selected.|Ok")
                return
        try:
            context = scene.getRenderingContext()
        except:
            context = None
        finally:
            if context == None:
                Blender.Draw.PupMenu("Cannot get the rendering context for the current scene.|Ok")
                return
        try:
            camera = scene.objects.camera # objCamera
        except:
            camera = None
        finally:
            if camera == None:
                Blender.Draw.PupMenu("There is not a camera object set for the current scene.|Ok")
                return
        try:
            armatures = [ ]
            for armature in bpy.data.armatures:
                armatureObj = None
                for obj in scene.objects:
                    if obj.data == armature:
                        armatureObj = obj
                        break
                if armatureObj != None:
                    armatures.append( [ armatureObj, armature, armatureObj.getPose() ] ) # For some reason if we don't include the pose here, bad things happen... No idea...
        except:
            armatures = None
        finally:
            if armatures == None or not len(armatures):
                Blender.Draw.PupMenu("There are no armatures existant in the current scene.|Ok")
                return
        try:
            actions = [ ]
            for action in bpy.data.actions:
                if len(action.getAllChannelIpos()) and len(action.getFrameNumbers()): # TODO: Expand action check to include linkage to armature
                    actions.append( [ action, action.getFrameNumbers()[0]+1, action.getFrameNumbers()[len(action.getFrameNumbers())-1]+1, False, True ] ) # act, sframe, eframe, default?, enabled?, enableopt (appended later)
        except:
            actions = None
        finally:
            if actions == None or not len(actions):
                Blender.Draw.PupMenu("There are no actions available for the armatures in the current scene.|Ok")
                return
        
        # Build and display the options popup block
        block = [ ]
        opt_nmprefix = Blender.Draw.Create(name_prefix)
        block.append(("Name prefix: ", opt_nmprefix, 0, 30, "Prefixes all objects. Used to identify assets in a global system."))
        opt_flprefix = Blender.Draw.Create(file_prefix)
        block.append(("File prefix: ", opt_flprefix, 0, 30, "Used to specify a particular local directory or filename offset."))
        opt_animfps = Blender.Draw.Create(anim_fps)
        block.append(("Anim. FPS: ", opt_animfps, 1.0, 120.0, "Exported frame control uses this value to convert to seconds."))
        opt_dirslices = Blender.Draw.Create(dir_slices)
        block.append(("Dir.Slice: ", opt_dirslices, 1, 32, "Controls the number of directional slices for camera readjust."))
        opt_sprwidth = Blender.Draw.Create(sprite_width)
        block.append(("Sprt.Wdt.: ", opt_sprwidth, 2, 1024, "The width of the generated sprite (must be even)."))
        opt_sprheight = Blender.Draw.Create(sprite_height)
        block.append(("Sprt.Hgt.: ", opt_sprheight, 2, 1024, "The height of the generated sprite (must be even)."))
        opt_shtwidth = Blender.Draw.Create(sheet_width)
        block.append(("Sht.Mx.Wdt.: ", opt_shtwidth, 2, 32768, "The maximum width of the sprite sheet (must be even, may not be fully utilized)."))
        opt_shtheight = Blender.Draw.Create(sheet_height)
        block.append(("Sht.Mx.Hgt.: ", opt_shtheight, 2, 32768, "The maximum height of the sprite sheet (must be even, may not be fully utilized)."))
        opt_ussthdir0 = Blender.Draw.Create(use_sth_dir0)
        block.append(("Use Sth.Dir0", opt_ussthdir0, "Use southern direction (-Y axis) as the starting point for directions (on) or not (off)."))
        opt_usspcdirs = Blender.Draw.Create(use_spc_dirs)
        block.append(("Use Spc.Dirs.", opt_usspcdirs, "Use specified directional toggling (on) or not (off). Opens secondary pop up."))
        opt_uspw2sfup = Blender.Draw.Create(use_pow2_sclup)
        block.append(("Sht.Pow2UpScl", opt_uspw2sfup, "Always upscale optimal sheet size to nearest power-of-2 (on) or not (off)."))
        block.append("Available Actions:")
        opt_dfltact = Blender.Draw.Create(default_act)
        block.append(("Dflt. Action: ", opt_dfltact, 0, len(actions), "Controls the default/rest action index, or 0 if unused."))
        for actionIndex in range(len(actions)):
            act_enable = actions[actionIndex][4]
            opt_actenable = Blender.Draw.Create(act_enable)
            actions[actionIndex].append(opt_actenable)
            block.append(("%d %s" % (actionIndex+1, actions[actionIndex][0].name), opt_actenable, "Use this action (on) or do not use this action (off) during export."))
        retVal = Blender.Draw.PupBlock("GAMX Sprite Sheet Renderer Options", block)
        
        # Reconvert options back from popup block (ugly, but this is how you do it) and save
        if retVal:
            name_prefix = "%s" % opt_nmprefix
            name_prefix = name_prefix[1:][:-1]
            file_prefix = "%s" % opt_flprefix
            file_prefix = file_prefix[1:][:-1]
            anim_fps = float("%s" % opt_animfps)
            dir_slices = int("%s" % opt_dirslices)
            sprite_width = int("%s" % opt_sprwidth)
            sprite_width = sprite_width + (sprite_width % 2)
            sprite_height = int("%s" % opt_sprheight)
            sprite_height = sprite_height + (sprite_height % 2)
            sheet_width = int("%s" % opt_shtwidth)
            sheet_width = sheet_width + (sheet_width % 2)
            sheet_height = int("%s" % opt_shtheight)
            sheet_height = sheet_height + (sheet_height % 2)
            if opt_ussthdir0 == 1:
                use_sth_dir0 = True
            else:
                use_sth_dir0 = False
            if opt_usspcdirs == 1:
                use_spc_dirs = True
            else:
                use_spc_dirs = False
            if opt_uspw2sfup == 1:
                use_pow2_sclup = True
            else:
                use_pow2_sclup = False
            default_act = int("%s" % opt_dfltact)
            last_folder = os.path.abspath(os.path.dirname(filename))
            for actionIndex in range(len(actions)-1,-1,-1): # Go backward to remove items that were deselected
                if actions[actionIndex][5] == 1:
                    actions[actionIndex][4] = True
                else:
                    actions[actionIndex][4] = False
                actions[actionIndex].pop(5)
                if not actions[actionIndex][4]:
                    actions.pop(actionIndex)
                else:
                    actions[actionIndex].pop(4)
                    if actionIndex+1 == default_act:
                        actions[actionIndex][3] = True
            gamx_try_save_options()
            
            if not len(actions):
                Blender.Draw.PupMenu("No actions were selected to export.|Ok")
                return
            
            # Do camera direction mucking
            cameraStartLocX = camera.LocX
            cameraStartLocY = camera.LocY
            cameraStartRotZ = camera.RotZ
            
            try:
                # Figure out current camera angles for auto readjustment
                cameraDistanceOut = math.sqrt((camera.LocX * camera.LocX) + (camera.LocY * camera.LocY))
                if use_sth_dir0:
                    camera.LocY = -cameraDistanceOut
                    camera.LocX = 0.0
                    camera.RotZ = 0.0
                cameraStartAngle = math.atan2(camera.LocY, camera.LocX)
                cameraStartZRotAngle = camera.RotZ
                cameraTransAngle = (2.0 * math.pi) / float(dir_slices)
                
                # Do special direction toggling
                dirToggle = [ ]
                if use_spc_dirs:
                    block = [ ]
                    opt_toggles = [ ]
                    block.append("Available Directions:")
                    for dirSliceIndex in range(dir_slices):
                        opt_toggles.append(Blender.Draw.Create(True))
                        block.append(("Dir %d @ %0.1f" % (dirSliceIndex+1, gamx_radtodeg(gamx_radreduce(cameraStartAngle + (cameraTransAngle * float(dirSliceIndex))))), opt_toggles[dirSliceIndex], "Export using this direction (on) or not (off)."))
                    retVal = Blender.Draw.PupBlock("GAMX Sprite Sheet Renderer Direction Options", block)
                    
                    if retVal:
                        dirsSelect = 0
                        for dirSliceIndex in range(dir_slices):
                            if opt_toggles[dirSliceIndex] == 1:
                                dirToggle.append(True)
                                dirsSelect += 1
                            else:
                                dirToggle.append(False)
                        if not dirsSelect:
                            camera.LocX = cameraStartLocX
                            camera.LocY = cameraStartLocY
                            camera.RotZ = cameraStartRotZ
                            Blender.Draw.PupMenu("No directions were selected to export.|Ok")
                            return
                    else:
                        camera.LocX = cameraStartLocX
                        camera.LocY = cameraStartLocY
                        camera.RotZ = cameraStartRotZ
                        return
                else:
                    for dirSliceIndex in range(dir_slices):
                        dirToggle.append(True)
                
                # Initialize the frame counter - this gets used to track the total, all together total
                # of frames used, before building up the optimally sized sprite sheet. And no you can't
                # do that before you have this number - there might be frame/sheet shifting rollovers.
                totalFrameCount = 0
                
                # Do rendering on camera slices per action
                for actionIndex in range(len(actions)):
                    # Set action as active for all armature objects - hope this is right
                    for armatureIndex in range(len(armatures)):
                        actions[actionIndex][0].setActive(armatures[armatureIndex][0])
                    
                    for dirSliceIndex in range(dir_slices):
                        if dirToggle[dirSliceIndex]:
                            cameraAngle = gamx_radreduce(cameraStartAngle + (cameraTransAngle * float(dirSliceIndex)))
                            camera.LocX = math.cos(cameraAngle) * cameraDistanceOut
                            camera.LocY = math.sin(cameraAngle) * cameraDistanceOut
                            camera.RotZ = gamx_radreduce(cameraStartZRotAngle + (cameraTransAngle * float(dirSliceIndex)))
                            
                            print "Info: GAMX_Spriter: Starting rendering work for action '%s' on direction %d of %d." % (actions[actionIndex][0].name, dirSliceIndex+1, dir_slices)
                            
                            # Update the scene and context information, then render the animation
                            scene.update(1)
                            actionDumpPath = os.path.join(tempsFolder, "%s_d%d/" % (actions[actionIndex][0].name.replace(" ", ""), dirSliceIndex+1))
                            context.renderPath = actionDumpPath
                            context.imageType = Blender.Scene.Render.PNG
                            context.sFrame = actions[actionIndex][1]
                            context.eFrame = actions[actionIndex][2]
                            context.enableRGBAColor()
                            context.alphaMode = 2
                            context.renderAnim()
                            
                            # Adding the number of frames onto the bad boy
                            totalFrameCount += ((actions[actionIndex][2] - actions[actionIndex][1])+1)
            except:
                raise
            finally:
                # Reset camera back to where it was when we started
                camera.LocX = cameraStartLocX
                camera.LocY = cameraStartLocY
                camera.RotZ = cameraStartRotZ
            
            # Start building up the sprite sheets
            sheets = [ ] # sheets framing for gamx ouput ( [ horizontalFrames verticalFrames ] )
            actionTimerFrame = 0
            actionBoundings = [ ] # action boundings for gamx output ( [ name start end default ] )
            sheetSize = [ 0, 0 ] # width, height
            sheetGrid = [ 0, 0, 0 ] # row, column, all together
            sheetLeft = [ 0, 0, 0, 0 ] # rows, columns, all together (norm), all together (non-norm)
            sheetImage = None
            sheetIndex = 0
            frameCountLeft = totalFrameCount
            frameCount = 0
            for actionIndex in range(len(actions)):
                for dirSliceIndex in range(dir_slices):
                    if dirToggle[dirSliceIndex]:
                        if dir_slices > 1:
                            actionBoundings.append(("%s_d%d" % (actions[actionIndex][0].name.replace(" ", ""), dirSliceIndex+1), (float(actionTimerFrame) / anim_fps) + (start_timeoff_perc / anim_fps), (float(actionTimerFrame + ((actions[actionIndex][2] - actions[actionIndex][1])+1)) / anim_fps) - (end_timeoff_perc / anim_fps), actions[actionIndex][3]))
                        else:
                            actionBoundings.append(("%s" % actions[actionIndex][0].name.replace(" ", ""), (float(actionTimerFrame) / anim_fps) + (start_timeoff_perc / anim_fps), (float(actionTimerFrame + ((actions[actionIndex][2] - actions[actionIndex][1])+1)) / anim_fps) - (end_timeoff_perc / anim_fps), actions[actionIndex][3]))
                        actionTimerFrame += ((actions[actionIndex][2] - actions[actionIndex][1])+1)
                        
                        actionDumpPath = os.path.join(tempsFolder, "%s_d%d/" % (actions[actionIndex][0].name.replace(" ", ""), dirSliceIndex+1))
                        
                        print "Info: GAMX_Spriter: Starting conjoining work for action '%s' on direction %d of %d (%d frame(s) left to go)." % (actions[actionIndex][0].name, dirSliceIndex+1, dir_slices, frameCountLeft + sheetLeft[2])
                        
                        for frameIndex in range(actions[actionIndex][1], actions[actionIndex][2]+1):
                            actionDumpFilename = os.path.join(actionDumpPath, "%04d.png" % frameIndex)
                            
                            # Check for space on our image sheet, creating a new one if needed
                            if not sheetImage or not sheetLeft[2]:
                                if sheetImage:
                                    sheetImage.save(os.path.join(os.path.dirname(filename), "%sSheet%d.png" % (file_prefix, sheetIndex)), "PNG")
                                    print "Info: GAMX_Spriter: Wrote sprite sheet #%d (%dx%d) with %d frame(s) (%d frame(s) left over, %d frame(s) left to go)" % (sheetIndex, sheetSize[0], sheetSize[1], sheetGrid[2], sheetLeft[3], frameCountLeft)
                                    del sheetImage
                                sheetIndex += 1
                                frameCountLeft -= gamx_opt_pow2_sprt_frmg((sprite_width, sprite_height), (sheet_width, sheet_height), frameCountLeft, sheetSize)
                                if use_pow2_sclup:
                                    sheetSize[0] = gamx_round_up_pow2(sheetSize[0])
                                    sheetSize[1] = gamx_round_up_pow2(sheetSize[1])
                                sheetImage = Image.new("RGBA", (sheetSize[0],sheetSize[1]), (0,0,0,0))
                                sheetLeft[0] = sheetSize[1] / sprite_height # rows left
                                sheetLeft[1] = sheetSize[0] / sprite_width  # cols left
                                sheetLeft[2] = sheetLeft[0] * sheetLeft[1]
                                sheetLeft[3] = sheetLeft[2]
                                if frameCountLeft < 0:
                                    sheetLeft[2] += frameCountLeft
                                    frameCountLeft = 0
                                sheetGrid[0] = 0
                                sheetGrid[1] = 0
                                sheetGrid[2] = 0
                                sheets.append((sheetLeft[1], sheetLeft[0]))
                            
                            # Load the image and copy over the part that we want
                            currImage = Image.open(actionDumpFilename)
                            extTL = ((currImage.size[0] / 2) - (sprite_width / 2), (currImage.size[1] / 2) - (sprite_height / 2))
                            pstTL = (sheetGrid[1] * sprite_width, sheetGrid[0] * sprite_height)
                            h = 0
                            while h < sprite_height:
                                w = 0
                                while w < sprite_width:
                                    extPxl = (extTL[0]+w, extTL[1]+h)
                                    if extPxl[0] >= 0 and extPxl[0] < currImage.size[0] and extPxl[1] >= 0 and extPxl[1] < currImage.size[1]:
                                        sheetImage.putpixel((pstTL[0]+w, pstTL[1]+h), currImage.getpixel(extPxl))
                                    w += 1
                                h += 1
                            del currImage
                            frameCount += 1
                            
                            # Handle looping for next frame
                            sheetLeft[2] -= 1
                            sheetLeft[3] -= 1
                            sheetLeft[1] -= 1
                            sheetGrid[1] += 1
                            sheetGrid[2] += 1
                            if not sheetLeft[1]:
                                sheetLeft[0] -= 1;
                                sheetLeft[1] = sheetSize[0] / sprite_width
                                sheetGrid[0] += 1
                                sheetGrid[1] = 0
                            print "Info: GAMX_Spriter: Conjoined frame %d into sheet (%d left to go on this sheet)." % (frameCount, sheetLeft[2])
            if sheetImage:
                sheetImage.save(os.path.join(os.path.dirname(filename), "%sSheet%d.png" % (file_prefix, sheetIndex)), "PNG")
                print "Info: GAMX_Spriter: Wrote sprite sheet #%d (%dx%d) with %d frame(s) (%d frame(s) left over)" % (sheetIndex, sheetSize[0], sheetSize[1], sheetGrid[2], sheetLeft[3])
                del sheetImage
            
            # Output the relevant gamx information
            fout = open(filename, "w")
            try:
                # Write header
                fout.write(0*tab4 + r'<?xml version="1.0" encoding = "utf-8"?>' + endl)
                fout.write(0*tab4 + r'<gamx version="1.0">' + endl)
                fout.write(1*tab4 + r'<info>' + endl)
                fout.write(2*tab4 + r'<author>' + r'</author>' + endl)
                fout.write(2*tab4 + r'<comments>' + r'</comments>' + endl)
                fout.write(2*tab4 + r'<copyright>' + r'</copyright>' + endl)
                fout.write(1*tab4 + r'</info>' + endl)
                fout.write(1*tab4 + r'<assets>' + endl)
                
                # Write sprited image asset
                fout.write(2*tab4 + r'<widget id="' + name_prefix + r'Sprite" type="sprited_image" source="internal">' + endl)
                fout.write(3*tab4 + r'<sprites type="surface_framings" count="' + "%d" % len(sheets) + r'">' + endl)
                for sheetIndex in range(len(sheets)):
                    fout.write(4*tab4 + r'<frame>' + endl)
                    fout.write(5*tab4 + r'<surface source="external">' + endl)
                    fout.write(6*tab4 + r'<url>' + "%sSheet%d.png" % (file_prefix, sheetIndex+1) + '</url>' + endl)
                    fout.write(5*tab4 + r'</surface>' + endl)
                    fout.write(5*tab4 + r'<framing>' + "%d %d" % (sheets[sheetIndex][0], sheets[sheetIndex][1]) + r'</framing>' + endl)
                    fout.write(4*tab4 + r'</frame>' + endl)
                fout.write(3*tab4 + r'</sprites>' + endl)
                fout.write(3*tab4 + r'<dimensions>' + "%d %d" % (sprite_width, sprite_height) + r'</dimensions>' + endl)
                fout.write(3*tab4 + r'<fps>' + "%0.6f" % round(anim_fps, 6) + r'</fps>' + endl)
                fout.write(3*tab4 + r'<controller>' + endl)
                fout.write(4*tab4 + r'<timer id="' + name_prefix + r'Timer" type="actioned">' + endl)
                fout.write(5*tab4 + r'<actions source="internal" type="boundings" count="' + "%d" % len(actionBoundings) + r'">' + endl)
                for bndIndex in range(len(actionBoundings)):
                    fout.write(6*tab4 + r'<bounding name="' + actionBoundings[bndIndex][0] + r'"')
                    if actionBoundings[bndIndex][3]:
                        fout.write(r' options="default"')
                    fout.write(r'>' + "%0.6f %0.6f" % (round(actionBoundings[bndIndex][1],6), round(actionBoundings[bndIndex][2],6)) + r'</bounding>' + endl)
                fout.write(5*tab4 + r'</actions>' + endl)
                fout.write(4*tab4 + r'</timer>' + endl)
                fout.write(3*tab4 + r'</controller>' + endl)
                fout.write(2*tab4 + r'</widget>' + endl)
                
                # Write footer
                fout.write(1*tab4 + r'</assets>' + endl)
                fout.write(0*tab4 + r'</gamx>' + endl)
            except:
                raise
            finally:
                fout.close()
            Blender.Draw.PupMenu("Exporting successful.%t|Ok")
    except:
        Blender.Draw.PupMenu("Failure exporting.%t|Ok")
        raise
    finally:
        if os.path.exists(tempsFolder):
            shutil.rmtree(tempsFolder, True)

if __name__ == '__main__':
    random.seed()
    gamx_try_load_options()
    ret = Blender.Draw.PupMenu("Does current frame render produce centered/textured/correct output? (Render->Render Current Frame, or F12)|Yes|No")
    if ret == 2:
        if not os.path.exists(last_folder):
            last_folder = os.path.abspath(os.path.dirname(Blender.Get("filename")))
        filename = os.path.join(last_folder, os.path.splitext(os.path.split(Blender.Get("filename"))[1])[0] + ".gamx")
        Blender.Window.FileSelector(gamx_spriter_gui, "Export Sprite Sheet GAMX", filename)
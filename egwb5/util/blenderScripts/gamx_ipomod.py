#!BPY

"""
Name: 'GAMX IPO KF Check & Auto-Fix'
Blender: 247
Group: 'Animation'
Tooltip: 'Checks IPOs for simultaneous, grouped, etc. and provides capabilities to fix broken IPOs before export to GAMX asset manifest file (.gamx)'
"""
__author__ = "Johanna Wolf"
__url__ = ("http://gewizes.sourceforge.net/")
__version__ = "0.5"
__email__ = "johanna.a.wolf@gmail.com"
__bpydoc__ = """\
Description: Checks IPOs for simultaneous, grouped, etc. and provides capabilities to fix broken IPOs before export to GAMX asset manifest file (.gamx).
Usage: Run the script from the menu or inside Blender. 
"""

import sys
import math
import os.path
import inspect      # Used for script filename identification (for .sav rename)
import pickle       # Used for settings save/load
import bpy
import Blender
from Blender import *

channels_set = [['LocX', 'LocY', 'LocZ'], ['RotX', 'RotY', 'RotZ'], ['ScaleX', 'ScaleY', 'ScaleZ'], ['QuatW', 'QuatX', 'QuatY', 'QuatZ']]
channels_dft = [[0,0,0], [0,0,0], [1,1,1], [1,0,0,0]]
channels_ilu = { 'LocX':Ipo.PO_LOCX, 'LocY':Ipo.PO_LOCY, 'LocZ':Ipo.PO_LOCZ, 'RotX':Ipo.OB_ROTX, 'RotY':Ipo.OB_ROTY, 'RotZ':Ipo.OB_ROTZ, 'ScaleX':Ipo.PO_SCALEX, 'ScaleY':Ipo.PO_SCALEY, 'ScaleZ':Ipo.PO_SCALEZ, 'QuatW':Ipo.PO_QUATW, 'QuatX':Ipo.PO_QUATX, 'QuatY':Ipo.PO_QUATY, 'QuatZ':Ipo.PO_QUATZ }

use_repeat_removal = True
use_over90_fix = True
use_additive_union = True
use_removal_intersection = False

# Tries to load options from .sav file (named same as running script)
def gamx_try_load_options():
    global use_repeat_removal
    global use_over90_fix
    global use_additive_union
    global use_removal_intersection
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
                use_repeat_removal = dict["use_repeat_removal"]
                use_over90_fix = dict["use_over90_fix"]
                use_additive_union = dict["use_additive_union"]
                use_removal_intersection = dict["use_removal_intersection"]
    except:
        pass

# Tries to save options to .sav file (named same as running script)
def gamx_try_save_options():
    try:
        filename = os.path.splitext(os.path.abspath(inspect.getfile(inspect.currentframe())))[0] + ".sav"
        dict = { }
        dict["version"] = 1
        dict["use_repeat_removal"] = use_repeat_removal
        dict["use_over90_fix"] = use_over90_fix
        dict["use_additive_union"] = use_additive_union
        dict["use_removal_intersection"] = use_removal_intersection
        fout = open(filename, "w")
        try:
            pickle.dump(dict, fout)
        except:
            pass
        finally:
            fout.close()
    except:
        pass

def gamx_fpequal(val1, val2):
    if (val2 >= val1 - 0.000001) and (val2 <= val1 + 0.000001):
        return True
    return False

def gamx_rptfix(iponame):
    fixes = 0
    ipo = bpy.data.ipos[iponame]
    for channels in channels_set:
        for channel in channels:
            if ipo.getCurve(channel) != None and len(ipo.getCurve(channel).bezierPoints) >= 3:
                for i in range(len(ipo.getCurve(channel).bezierPoints)-2,0,-1):
                    if gamx_fpequal(ipo.getCurve(channel).bezierPoints[i+1].pt[0], ipo.getCurve(channel).bezierPoints[i].pt[0]) and gamx_fpequal(ipo.getCurve(channel).bezierPoints[i].pt[0], ipo.getCurve(channel).bezierPoints[i-1].pt[0]):
                        ipo.getCurve(channel).delBezier(i)
                        fixes += 1
    return fixes

def gamx_curve_findval(curve, value, beg, end):
    low = beg
    high = end
    mid = (low + high) / 2.0
    for i in range(64): # hard coded, may need more if large scaling
        eval = curve.evaluate(mid)
        if eval < value - 0.000001: # go to higher half
            low = mid
        else: # go to lower half
            high = mid
        mid = (low + high) / 2.0
    return mid

def gamx_ovr90fix(iponame):
    fixes = 0
    ipo = bpy.data.ipos[iponame]
    for channel in channels_set[1]:
        if ipo.getCurve(channel) != None and len(ipo.getCurve(channel).bezierPoints) >= 2:
            for i in range(len(ipo.getCurve(channel).bezierPoints)-2,-1,-1):
                if abs(ipo.getCurve(channel).bezierPoints[i+1].pt[1] - ipo.getCurve(channel).bezierPoints[i].pt[1]) > 9.000001:
                    begkf = ipo.getCurve(channel).bezierPoints[i].pt[0]
                    endkf = ipo.getCurve(channel).bezierPoints[i+1].pt[0]
                    if ipo.getCurve(channel).bezierPoints[i].pt[1] <= ipo.getCurve(channel).bezierPoints[i+1].pt[1]:
                        begkd = (math.floor(ipo.getCurve(channel).bezierPoints[i].pt[1] / 9.0) + 1.0) * 9.0
                        endkd = (math.ceil(ipo.getCurve(channel).bezierPoints[i+1].pt[1] / 9.0) - 1.0) * 9.0
                    else:
                        begkd = (math.ceil(ipo.getCurve(channel).bezierPoints[i].pt[1] / 9.0) - 1.0) * 9.0
                        endkd = (math.floor(ipo.getCurve(channel).bezierPoints[i+1].pt[1] / 9.0) + 1.0) * 9.0
                    lenkfs = int(abs(endkd - begkd) / 9.0) + 1
                    addkfs = []
                    addkds = []
                    for j in range(lenkfs):
                        if ipo.getCurve(channel).bezierPoints[i].pt[1] <= ipo.getCurve(channel).bezierPoints[i+1].pt[1]:
                            lookkd = begkd + (float(j) * 9.0)
                            addkfs.append(gamx_curve_findval(ipo.getCurve(channel), lookkd, begkf, endkf))
                            addkds.append(lookkd)
                        else:
                            lookkd = begkd + (float(j) * -9.0)
                            addkfs.append(gamx_curve_findval(ipo.getCurve(channel), lookkd, endkf, begkf))
                            addkds.append(lookkd)
                    for j in range(len(addkfs)):
                        if not gamx_fpequal(addkfs[j], begkf) and not gamx_fpequal(addkfs[j], endkf): # safety
                            ipo.getCurve(channel).append((addkfs[j], addkds[j]))
                            fixes += 1
    return fixes

def gamx_addfix(iponame):
    fixes = 0
    ipo = bpy.data.ipos[iponame]
    for channels in channels_set:
        channel_def = 0
        for channel in channels:
            if ipo.getCurve(channel) != None:
                channel_def = 1
                break
        if channel_def:
            unionkfs = []
            for channel in channels: # For each value in channels, if not found in unionkfs then add, this forms the union
                if ipo.getCurve(channel) != None:
                    for i in range(len(ipo.getCurve(channel).bezierPoints)):
                        if not unionkfs.count(ipo.getCurve(channel).bezierPoints[i].pt[0]):
                            unionkfs.append(ipo.getCurve(channel).bezierPoints[i].pt[0])
            unionkfs.sort()
            if len(unionkfs):
                for channel in channels:
                    if ipo.getCurve(channel) == None:
                        ipo.addCurve(channel)
                        fixes += 1
                        for i in range(len(unionkfs)):
                            ipo.getCurve(channel).append((unionkfs[i], channels_dft[channels_set.index(channels)][channels.index(channel)]))
                            fixes += 1
                for channel in channels:
                    unionkds = []
                    for i in range(len(unionkfs)):
                        unionkds.append(ipo.getCurve(channel).evaluate(unionkfs[i]))
                    for i in range(len(unionkfs)):
                        if i >= len(ipo.getCurve(channel).bezierPoints) or not gamx_fpequal(ipo.getCurve(channel).bezierPoints[i].pt[0], unionkfs[i]):
                            ipo.getCurve(channel).append((unionkfs[i], unionkds[i]))
                            fixes += 1
    return fixes

def gamx_remfix(iponame):
    fixes = 0
    ipo = bpy.data.ipos[iponame]
    for channels in channels_set:
        channel_def = 0
        for channel in channels:
            if ipo.getCurve(channel) != None:
                channel_def = 1
                break
        if channel_def:
            for channel in channels:
                if ipo.getCurve(channel) == None:
                    channel_def = 0
                    break
            if not channel_def:
                for channel in channels:
                    if ipo.getCurve(channel) != None:
                        fixes += len(ipo.getCurve(channel).bezierPoints)
                        ipo[channels_ilu[channel]] = None
                        fixes += 1
            else:
                intersectkfs = []
                for i in range(len(ipo.getCurve(channels[0]).bezierPoints)):
                    intersectkfs.append(ipo.getCurve(channels[0]).bezierPoints[i].pt[0])
                for channel in channels: # For each value in intersectkfs, if not found in channels then remove, this forms the intersection
                    intersectkfs_temp = []
                    for val in intersectkfs:
                        intersectkfs_temp.append(val)
                    for i in range(len(intersectkfs_temp)):
                        found = 0
                        for j in range(len(ipo.getCurve(channel).bezierPoints)):
                            if intersectkfs_temp[i] == ipo.getCurve(channel).bezierPoints[j].pt[0]:
                                found = 1
                                break
                        if not found:
                            intersectkfs.remove(intersectkfs_temp[i])
                        del found
                    del intersectkfs_temp
                intersectkfs.sort()
                if len(intersectkfs):
                    for channel in channels:
                        delbezs = []
                        for i in range(len(ipo.getCurve(channel).bezierPoints)-1,-1,-1):
                            if not intersectkfs.count(ipo.getCurve(channel).bezierPoints[i].pt[0]):
                                delbezs.append(i);
                        for i in delbezs: # have to remove outside of loop, front back to front (hence reverse range above)
                            ipo.getCurve(channel).delBezier(i)
                            fixes += 1
                else:
                    for channel in channels:
                        if ipo.getCurve(channel) != None:
                            fixes += len(ipo.getCurve(channel).bezierPoints)
                            ipo[channels_ilu[channel]] = None
                            fixes += 1
    return fixes

def gamx_ipomod_gui():
    global use_repeat_removal
    global use_over90_fix
    global use_additive_union
    global use_removal_intersection
    
    broken = []
    for ipo in bpy.data.ipos:
        if ipo.getCurve('LocX') != None or ipo.getCurve('LocY') != None or ipo.getCurve('LocZ') != None or ipo.getCurve('ScaleX') != None or ipo.getCurve('ScaleY') != None or ipo.getCurve('ScaleZ') != None or ipo.getCurve('RotX') != None or ipo.getCurve('RotY') != None or ipo.getCurve('RotZ') != None or ipo.getCurve('QuatW') != None or ipo.getCurve('QuatX') != None or ipo.getCurve('QuatY') != None or ipo.getCurve('QuatZ') != None:
            errcode = ""
            if ipo.getCurve('LocX') != None or ipo.getCurve('LocY') != None or ipo.getCurve('LocZ') != None:
                if ipo.getCurve('LocX') == None or ipo.getCurve('LocY') == None or ipo.getCurve('LocZ') == None:
                    errcode += " Loc missing kf channel def (%d,%d,%d)." % (ipo.getCurve('LocX')!=None,ipo.getCurve('LocY')!=None,ipo.getCurve('LocZ')!=None)
                elif len(ipo.getCurve('LocX').bezierPoints) != len(ipo.getCurve('LocY').bezierPoints) or len(ipo.getCurve('LocY').bezierPoints) != len(ipo.getCurve('LocZ').bezierPoints) or len(ipo.getCurve('LocX').bezierPoints) != len(ipo.getCurve('LocZ').bezierPoints):
                    errcode += " Loc channel kf count mismatch (%d,%d,%d)." % (len(ipo.getCurve('LocX').bezierPoints),len(ipo.getCurve('LocY').bezierPoints),len(ipo.getCurve('LocZ').bezierPoints))
                else:
                    for i in range(len(ipo.getCurve('LocX').bezierPoints)):
                        if not gamx_fpequal(ipo.getCurve('LocX').bezierPoints[i].pt[0], ipo.getCurve('LocY').bezierPoints[i].pt[0]) or not gamx_fpequal(ipo.getCurve('LocY').bezierPoints[i].pt[0], ipo.getCurve('LocZ').bezierPoints[i].pt[0]) or not gamx_fpequal(ipo.getCurve('LocX').bezierPoints[i].pt[0], ipo.getCurve('LocZ').bezierPoints[i].pt[0]):
                            errcode += " Loc kf indicies not simultaneous."
                            break
                    for channel in channels_set[0]:
                        for i in range(len(ipo.getCurve(channel).bezierPoints)-2,0,-1):
                            if gamx_fpequal(ipo.getCurve(channel).bezierPoints[i+1].pt[0], ipo.getCurve(channel).bezierPoints[i].pt[0]) and gamx_fpequal(ipo.getCurve(channel).bezierPoints[i].pt[0], ipo.getCurve(channel).bezierPoints[i-1].pt[0]):
                                errcode += " Loc kf repeating indicies."
                                break
            if ipo.getCurve('RotX') != None or ipo.getCurve('RotY') != None or ipo.getCurve('RotZ') != None:
                if ipo.getCurve('RotX') == None or ipo.getCurve('RotY') == None or ipo.getCurve('RotZ') == None:
                    errcode += " Rot missing kf channel def (%d,%d,%d)." % (ipo.getCurve('RotX')!=None,ipo.getCurve('RotY')!=None,ipo.getCurve('RotZ')!=None)
                elif len(ipo.getCurve('RotX').bezierPoints) != len(ipo.getCurve('RotY').bezierPoints) or len(ipo.getCurve('RotY').bezierPoints) != len(ipo.getCurve('RotZ').bezierPoints) or len(ipo.getCurve('RotX').bezierPoints) != len(ipo.getCurve('RotZ').bezierPoints):
                    errcode += " Rot channel kf count mismatch (%d,%d,%d)." % (len(ipo.getCurve('RotX').bezierPoints),len(ipo.getCurve('RotY').bezierPoints),len(ipo.getCurve('RotZ').bezierPoints))
                else:
                    for i in range(len(ipo.getCurve('RotX').bezierPoints)):
                        if not gamx_fpequal(ipo.getCurve('RotX').bezierPoints[i].pt[0], ipo.getCurve('RotY').bezierPoints[i].pt[0]) or not gamx_fpequal(ipo.getCurve('RotY').bezierPoints[i].pt[0], ipo.getCurve('RotZ').bezierPoints[i].pt[0]) or not gamx_fpequal(ipo.getCurve('RotX').bezierPoints[i].pt[0], ipo.getCurve('RotZ').bezierPoints[i].pt[0]):
                            errcode += " Rot kf indicies not simultaneous."
                            break
                        if i > 0 and (abs(ipo.getCurve('RotX').bezierPoints[i].pt[1] - ipo.getCurve('RotX').bezierPoints[i-1].pt[1]) > 9.000001 or abs(ipo.getCurve('RotY').bezierPoints[i].pt[1] - ipo.getCurve('RotY').bezierPoints[i-1].pt[1]) > 9.000001 or abs(ipo.getCurve('RotZ').bezierPoints[i].pt[1] - ipo.getCurve('RotZ').bezierPoints[i-1].pt[1]) > 9.000001):
                            errcode += " Rot kf extends past 90 degree tol."
                            break
                    for channel in channels_set[1]:
                        for i in range(len(ipo.getCurve(channel).bezierPoints)-2,0,-1):
                            if gamx_fpequal(ipo.getCurve(channel).bezierPoints[i+1].pt[0], ipo.getCurve(channel).bezierPoints[i].pt[0]) and gamx_fpequal(ipo.getCurve(channel).bezierPoints[i].pt[0], ipo.getCurve(channel).bezierPoints[i-1].pt[0]):
                                errcode += " Rot kf repeating indicies."
                                break
            if ipo.getCurve('ScaleX') != None or ipo.getCurve('ScaleY') != None or ipo.getCurve('ScaleZ') != None:
                if ipo.getCurve('ScaleX') == None or ipo.getCurve('ScaleY') == None or ipo.getCurve('ScaleZ') == None:
                    errcode += " Scale missing kf channel def (%d,%d,%d)." % (ipo.getCurve('ScaleX')!=None,ipo.getCurve('ScaleY')!=None,ipo.getCurve('ScaleZ')!=None)
                elif len(ipo.getCurve('ScaleX').bezierPoints) != len(ipo.getCurve('ScaleY').bezierPoints) or len(ipo.getCurve('ScaleY').bezierPoints) != len(ipo.getCurve('ScaleZ').bezierPoints) or len(ipo.getCurve('ScaleX').bezierPoints) != len(ipo.getCurve('ScaleZ').bezierPoints):
                    errcode += " Scale channel kf count mismatch (%d,%d,%d)." % (len(ipo.getCurve('ScaleX').bezierPoints),len(ipo.getCurve('ScaleY').bezierPoints),len(ipo.getCurve('ScaleZ').bezierPoints))
                else:
                    for i in range(len(ipo.getCurve('ScaleX').bezierPoints)):
                        if not gamx_fpequal(ipo.getCurve('ScaleX').bezierPoints[i].pt[0], ipo.getCurve('ScaleY').bezierPoints[i].pt[0]) or not gamx_fpequal(ipo.getCurve('ScaleY').bezierPoints[i].pt[0], ipo.getCurve('ScaleZ').bezierPoints[i].pt[0]) or not gamx_fpequal(ipo.getCurve('ScaleX').bezierPoints[i].pt[0], ipo.getCurve('ScaleZ').bezierPoints[i].pt[0]):
                            errcode += " Scale kf indicies not simultaneous."
                            break
                    for channel in channels_set[2]:
                        for i in range(len(ipo.getCurve(channel).bezierPoints)-2,0,-1):
                            if gamx_fpequal(ipo.getCurve(channel).bezierPoints[i+1].pt[0], ipo.getCurve(channel).bezierPoints[i].pt[0]) and gamx_fpequal(ipo.getCurve(channel).bezierPoints[i].pt[0], ipo.getCurve(channel).bezierPoints[i-1].pt[0]):
                                errcode += " Scale kf repeating indicies."
                                break
            if ipo.getCurve('QuatW') != None or ipo.getCurve('QuatX') != None or ipo.getCurve('QuatY') != None or ipo.getCurve('QuatZ') != None:
                if ipo.getCurve('QuatW') == None or ipo.getCurve('QuatX') == None or ipo.getCurve('QuatY') == None or ipo.getCurve('QuatZ') == None:
                    errcode += " Quat missing kf channel def (%d,%d,%d,%d)." % (ipo.getCurve('QuatW')!=None,ipo.getCurve('QuatX')!=None,ipo.getCurve('QuatY')!=None,ipo.getCurve('QuatZ')!=None)
                elif len(ipo.getCurve('QuatW').bezierPoints) != len(ipo.getCurve('QuatX').bezierPoints) or len(ipo.getCurve('QuatX').bezierPoints) != len(ipo.getCurve('QuatY').bezierPoints) or len(ipo.getCurve('QuatW').bezierPoints) != len(ipo.getCurve('QuatY').bezierPoints) or len(ipo.getCurve('QuatY').bezierPoints) != len(ipo.getCurve('QuatZ').bezierPoints) or len(ipo.getCurve('QuatW').bezierPoints) != len(ipo.getCurve('QuatZ').bezierPoints) or len(ipo.getCurve('QuatX').bezierPoints) != len(ipo.getCurve('QuatZ').bezierPoints):
                    errcode += " Quat channel kf count mismatch (%d,%d,%d,%d)." % (len(ipo.getCurve('QuatW').bezierPoints),len(ipo.getCurve('QuatX').bezierPoints),len(ipo.getCurve('QuatY').bezierPoints),len(ipo.getCurve('QuatZ').bezierPoints))
                else:
                    for i in range(len(ipo.getCurve('QuatW').bezierPoints)):
                        if not gamx_fpequal(ipo.getCurve('QuatW').bezierPoints[i].pt[0], ipo.getCurve('QuatX').bezierPoints[i].pt[0]) or not gamx_fpequal(ipo.getCurve('QuatX').bezierPoints[i].pt[0], ipo.getCurve('QuatY').bezierPoints[i].pt[0]) or not gamx_fpequal(ipo.getCurve('QuatW').bezierPoints[i].pt[0], ipo.getCurve('QuatY').bezierPoints[i].pt[0]) or not gamx_fpequal(ipo.getCurve('QuatY').bezierPoints[i].pt[0], ipo.getCurve('QuatZ').bezierPoints[i].pt[0]) or not gamx_fpequal(ipo.getCurve('QuatW').bezierPoints[i].pt[0], ipo.getCurve('QuatZ').bezierPoints[i].pt[0]) or not gamx_fpequal(ipo.getCurve('QuatX').bezierPoints[i].pt[0], ipo.getCurve('QuatZ').bezierPoints[i].pt[0]):
                            errcode += " Quat kf indicies not simultaneous."
                            break
                    for channel in channels_set[3]:
                        for i in range(len(ipo.getCurve(channel).bezierPoints)-2,0,-1):
                            if gamx_fpequal(ipo.getCurve(channel).bezierPoints[i+1].pt[0], ipo.getCurve(channel).bezierPoints[i].pt[0]) and gamx_fpequal(ipo.getCurve(channel).bezierPoints[i].pt[0], ipo.getCurve(channel).bezierPoints[i-1].pt[0]):
                                errcode += " Quat kf repeating indicies."
                                break
            if len(errcode):
                broken.append([ipo.name, errcode])
    if len(broken):
        opt_broken = []
        opt_broken_ipos = []
        opt_broken.append("Fix Op:")
        opt_userpt = Blender.Draw.Create(use_repeat_removal)
        opt_broken.append(("Rpt | Rem", opt_userpt, "Attempts to fix by removing repeating KFs via uniquness check."))
        opt_ovr90fx = Blender.Draw.Create(use_over90_fix)
        opt_broken.append(("Ovr90 | Add", opt_ovr90fx, "Attempts to fix by adding 90 degree intervals to Rot based KFs."))
        opt_useadd = Blender.Draw.Create(use_additive_union)
        opt_broken.append(("Add | Union", opt_useadd, "Attempts to fix by adding missing KFs via set union."))
        opt_userem = Blender.Draw.Create(use_removal_intersection)
        opt_broken.append(("Rem | Intersect", opt_userem, "Attempts to fix by removing extraneous KFs via set intersection."))
        opt_broken.append("Broken IPO KFs:")
        for i in range(len(broken)):
            opt_broken_ipos.append(Blender.Draw.Create(0))
            opt_broken.append(("%s" % (broken[i][0], ), opt_broken_ipos[i], "Error(s):%s" % (broken[i][1],)))
        retVal = Blender.Draw.PupBlock("%d Broken IPOs Encountered" % (len(broken),), opt_broken)
        if retVal:
            if opt_userpt == 1:
                use_repeat_removal = True
            else:
                use_repeat_removal = False
            if opt_ovr90fx == 1:
                use_over90_fix = True
            else:
                use_over90_fix = False
            if opt_useadd == 1:
                use_additive_union = True
            else:
                use_additive_union = False
            if opt_userem == 1:
                use_removal_intersection = True
            else:
                use_removal_intersection = False
            gamx_try_save_options()
            try:
                if use_repeat_removal or use_additive_union or use_removal_intersection:
                    fixes = 0
                    if use_repeat_removal:
                        for i in range(len(broken)):
                            if opt_broken_ipos[i] == 1:
                                fixes += gamx_rptfix(broken[i][0])
                    if use_over90_fix:
                        for i in range(len(broken)):
                            if opt_broken_ipos[i] == 1:
                                fixes += gamx_ovr90fix(broken[i][0])
                    if use_additive_union:
                        for i in range(len(broken)):
                            if opt_broken_ipos[i] == 1:
                                fixes += gamx_addfix(broken[i][0])
                    if use_removal_intersection:
                        for i in range(len(broken)):
                            if opt_broken_ipos[i] == 1:
                                fixes += gamx_remfix(broken[i][0])
                    Blender.Draw.PupMenu("Made %d modifications." % (fixes,) + "%t|Ok")
                    gamx_ipomod_gui()
            except:
                Blender.Draw.PupMenu("Failure fixing.%t|Ok")
                raise
    else:
        Blender.Draw.PupMenu("No broken IPO KFs detected.%t|Ok")

if __name__ == '__main__':
    gamx_try_load_options()
    gamx_ipomod_gui()
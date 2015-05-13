#!BPY

"""
Name: 'GAMX OBJ/IPO Bind Check & Auto-Fix'
Blender: 247
Group: 'Animation'
Tooltip: 'Checks OBJ/IPO binds for correct frame 1 transform and provides capabilities to fix broken OBJ/IPOs before export to GAMX asset manifest file (.gamx)'
"""
__author__ = "Johanna Wolf"
__url__ = ("http://gewizes.sourceforge.net/")
__version__ = "0.5"
__email__ = "johanna.a.wolf@gmail.com"
__bpydoc__ = """\
Description: Checks OBJ/IPO binds for correct frame 1 transform and provides capabilities to fix broken OBJ/IPOs before export to GAMX asset manifest file (.gamx).
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

# Tries to load options from .sav file (named same as running script)
def gamx_try_load_options():
    #global xxx
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
                #xxx = dict["xxx"]
                pass
    except:
        pass

# Tries to save options to .sav file (named same as running script)
def gamx_try_save_options():
    try:
        filename = os.path.splitext(os.path.abspath(inspect.getfile(inspect.currentframe())))[0] + ".sav"
        dict = { }
        dict["version"] = 1
        #dict["xxx"] = xxx
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

def gamx_deg_to_rad(degrees):
    return round(degrees * 3.14159265 / 180.0, 6);

def gamx_rad_to_deg(radians):
    return round(radians * 180.0 / 3.14159265, 6);

def gamx_radreduce(val):
    while val < 0.0 - 0.000001:
        val += 6.28318531
    while val >= 6.28318531 - 0.000001:
        val -= 6.28318531
    return val

def gamx_assignval(obj, channel, value):
    if channel == 'LocX':
        obj.setLocation(value, obj.getLocation('localspace')[1], obj.getLocation('localspace')[2])
    elif channel == 'LocY':
        obj.setLocation(obj.getLocation('localspace')[0], value, obj.getLocation('localspace')[2])
    elif channel == 'LocZ':
        obj.setLocation(obj.getLocation('localspace')[0], obj.getLocation('localspace')[1], value)
    elif channel == 'RotX':
        obj.setEuler(gamx_radreduce(value), obj.getEuler('localspace')[1], obj.getEuler('localspace')[2])
    elif channel == 'RotY':
        obj.setEuler(obj.getEuler('localspace')[0], gamx_radreduce(value), obj.getEuler('localspace')[2])
    elif channel == 'RotZ':
        obj.setEuler(obj.getEuler('localspace')[0], obj.getEuler('localspace')[1], gamx_radreduce(value))
    elif channel == 'ScaleX':
        obj.setSize(value, obj.getSize('localspace')[1], obj.getSize('localspace')[2])
    elif channel == 'ScaleY':
        obj.setSize(obj.getSize('localspace')[0], value, obj.getSize('localspace')[2])
    elif channel == 'ScaleZ':
        obj.setSize(obj.getSize('localspace')[0], obj.getSize('localspace')[1], value)

def gamx_basfix(objname, iponame):
    fixes = 0
    obj = bpy.data.objects[objname]
    ipo = bpy.data.ipos[iponame]
    channelIndex = 0
    for channel in channels_set[0]: # LocX/LocY/LocZ test
        if ipo.getCurve(channel) != None and not gamx_fpequal(obj.getLocation('localspace')[channelIndex], ipo.getCurve(channel)[1]):
            gamx_assignval(obj, channel, ipo.getCurve(channel)[1])
            fixes += 1
        elif ipo.getCurve(channel) == None and not gamx_fpequal(obj.getLocation('localspace')[channelIndex], 0.0):
            ipo.addCurve(channel)
            ipo.getCurve(channel).append((1.0, obj.getLocation('localspace')[channelIndex]))
            ipo.getCurve(channel).interpolation = Blender.IpoCurve.InterpTypes["CONST"]
            ipo.getCurve(channel).extend = Blender.IpoCurve.ExtendTypes["CONST"]
            fixes += 1
        channelIndex += 1
    channelIndex = 0
    for channel in channels_set[1]: # RotX/RotY/RotZ test
        if ipo.getCurve(channel) != None and not gamx_fpequal(gamx_radreduce(obj.getEuler('localspace')[channelIndex]), gamx_radreduce(gamx_deg_to_rad(ipo.getCurve(channel)[1] * 10.0))):
            gamx_assignval(obj, channel, gamx_radreduce(gamx_deg_to_rad(ipo.getCurve(channel)[1] * 10.0)))
            fixes += 1
        elif ipo.getCurve(channel) == None and not gamx_fpequal(gamx_radreduce(obj.getEuler('localspace')[channelIndex]), 0.0):
            ipo.addCurve(channel)
            ipo.getCurve(channel).append((1.0, gamx_radreduce(gamx_rad_to_deg(obj.getEuler('localspace')[channelIndex])) / 10.0))
            ipo.getCurve(channel).interpolation = Blender.IpoCurve.InterpTypes["CONST"]
            ipo.getCurve(channel).extend = Blender.IpoCurve.ExtendTypes["CONST"]
            fixes += 1
        channelIndex += 1
    channelIndex = 0
    for channel in channels_set[2]: # SizeX/SizeY/SizeZ test
        if ipo.getCurve(channel) != None and not gamx_fpequal(obj.getSize('localspace')[channelIndex], ipo.getCurve(channel)[1]):
            gamx_assignval(obj, channel, ipo.getCurve(channel)[1])
            fixes += 1
        elif ipo.getCurve(channel) == None and not gamx_fpequal(obj.getSize('localspace')[channelIndex], 1.0):
            ipo.addCurve(channel)
            ipo.getCurve(channel).append((1.0, obj.getSize('localspace')[channelIndex]))
            ipo.getCurve(channel).interpolation = Blender.IpoCurve.InterpTypes["CONST"]
            ipo.getCurve(channel).extend = Blender.IpoCurve.ExtendTypes["CONST"]
            fixes += 1
        channelIndex += 1
    return fixes

def gamx_ipobind_gui():
    broken = []
    for obj in bpy.data.objects:
        if obj.ipo != None:
            ipo = obj.ipo
            if ipo.getCurve('LocX') != None or ipo.getCurve('LocY') != None or ipo.getCurve('LocZ') != None or ipo.getCurve('ScaleX') != None or ipo.getCurve('ScaleY') != None or ipo.getCurve('ScaleZ') != None or ipo.getCurve('RotX') != None or ipo.getCurve('RotY') != None or ipo.getCurve('RotZ') != None or ipo.getCurve('QuatW') != None or ipo.getCurve('QuatX') != None or ipo.getCurve('QuatY') != None or ipo.getCurve('QuatZ') != None:
                errcode = ""
                channelIndex = 0
                for channel in channels_set[0]: # LocX/LocY/LocZ test
                    if ipo.getCurve(channel) != None and not gamx_fpequal(obj.getLocation('localspace')[channelIndex], ipo.getCurve(channel)[1]):
                        errcode += " %s mismatch (%f,%f)." % (channel, obj.getLocation('localspace')[channelIndex], ipo.getCurve(channel)[1])
                    elif ipo.getCurve(channel) == None and not gamx_fpequal(obj.getLocation('localspace')[channelIndex], 0.0):
                        errcode += " %s w/o ipo (%f)." % (channel, obj.getLocation('localspace')[channelIndex])
                    channelIndex += 1
                channelIndex = 0
                for channel in channels_set[1]: # RotX/RotY/RotZ test
                    if ipo.getCurve(channel) != None and not gamx_fpequal(gamx_radreduce(obj.getEuler('localspace')[channelIndex]), gamx_radreduce(gamx_deg_to_rad(ipo.getCurve(channel)[1] * 10.0))):
                        errcode += " %s mismatch (%f,%f)." % (channel, gamx_radreduce(obj.getEuler('localspace')[channelIndex]), gamx_radreduce(gamx_deg_to_rad(ipo.getCurve(channel)[1] * 10.0)))
                    elif ipo.getCurve(channel) == None and not gamx_fpequal(gamx_radreduce(obj.getEuler('localspace')[channelIndex]), 0.0):
                        errcode += " %s w/o ipo (%f)." % (channel, gamx_radreduce(obj.getEuler('localspace')[channelIndex]))
                    channelIndex += 1
                channelIndex = 0
                for channel in channels_set[2]: # SizeX/SizeY/SizeZ test
                    if ipo.getCurve(channel) != None and not gamx_fpequal(obj.getSize('localspace')[channelIndex], ipo.getCurve(channel)[1]):
                        errcode += " %s mismatch (%f,%f)." % (channel, obj.getSize('localspace')[channelIndex], ipo.getCurve(channel)[1])
                    elif ipo.getCurve(channel) == None and not gamx_fpequal(obj.getSize('localspace')[channelIndex], 1.0):
                        errcode += " %s w/o ipo (%f)." % (channel, obj.getSize('localspace')[channelIndex])
                    channelIndex += 1
                channelIndex = 0
                
                # NOTE: QuatX/QuatW/QuatY/QuatZ not checked since it has to be converted to Euler first and I doubt any artist will use them over normal euler angles. -jw
                
                if len(errcode):
                    broken.append([obj.name, ipo.name, errcode])
    if len(broken):
        opt_broken = []
        opt_broken_ops = []
        opt_broken_ipos = []
        opt_broken.append("Broken OBJ/IPO binds:")
        for i in range(len(broken)):
            opt_broken_ipos.append(Blender.Draw.Create(0))
            opt_broken.append(("%s : %s" % (broken[i][0],broken[i][1]), opt_broken_ipos[i], "Error(s):%s" % (broken[i][2],)))
        retVal = Blender.Draw.PupBlock("%d Broken OBJ/IPO Binds Encountered" % (len(broken),), opt_broken)
        if retVal:
            gamx_try_save_options()
            try:
                fixes = 0
                for i in range(len(broken)):
                    if opt_broken_ipos[i] == 1:
                        fixes += gamx_basfix(broken[i][0], broken[i][1])
                Blender.Draw.PupMenu("Made %d modifications." % (fixes,) + "%t|Ok")
                gamx_ipobind_gui()
            except:
                Blender.Draw.PupMenu("Failure fixing.%t|Ok")
                raise
    else:
        Blender.Draw.PupMenu("No broken OBJ/IPO binds detected.%t|Ok")

if __name__ == '__main__':
    gamx_try_load_options()
    gamx_ipobind_gui()
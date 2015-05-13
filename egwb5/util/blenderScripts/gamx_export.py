#!BPY

"""
Name: 'GAMX Asset Manifest 1.0 (.gamx)...'
Blender: 247
Group: 'Export'
Tooltip: 'Export selection to v1.0 GAMX asset manifest file (.gamx)'
"""
__author__ = "Johanna Wolf"
__url__ = ("http://gewizes.sourceforge.net/")
__version__ = "0.5"
__email__ = "johanna.a.wolf@gmail.com"
__bpydoc__ = """\
Description: Exports a Blender scene into a GAMX 1.0 file.
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

endl = "\n"
tab4 = "    "
name_prefix = ""
file_prefix = ""
anim_fps = 25.0
use_no_shift_over = True
use_bilinear_over_unilinear = True
use_linear_over_cubic_cr = False
use_unique_timer = False
last_folder = os.path.abspath(os.path.dirname(Blender.Get("filename")))

# Tries to load options from .sav file (named same as running script)
def gamx_try_load_options():
    global name_prefix
    global file_prefix
    global anim_fps
    global use_no_shift_over
    global use_bilinear_over_unilinear
    global use_linear_over_cubic_cr
    global use_unique_timer
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
                use_no_shift_over = dict["use_no_shift_over"]
                use_bilinear_over_unilinear = dict["use_bilinear_over_unilinear"]
                use_linear_over_cubic_cr = dict["use_linear_over_cubic_cr"]
                use_unique_timer = dict["use_unique_timer"]
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
        dict["use_no_shift_over"] = use_no_shift_over
        dict["use_bilinear_over_unilinear"] = use_bilinear_over_unilinear
        dict["use_linear_over_cubic_cr"] = use_linear_over_cubic_cr
        dict["use_unique_timer"] = use_unique_timer
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

def gamx_name_prefix(prefix, name):
    if name[:len(name_prefix)] == name_prefix:
        name = name[len(name_prefix):]
    if name[:len(prefix)] == prefix:
        name = name[len(prefix):]
    return name_prefix + prefix + name

def gamx_namesubprefix(prefix, name):
    if name[:len(name_prefix)] == name_prefix:
        name = name[len(name_prefix):]
    if name[:len(prefix)] == prefix:
        name = name[len(prefix):]
    return prefix + name

def gamx_file_prefix(filename):
    if filename[:1] != '/':
        return file_prefix + filename
    else:
        return filename

def gamx_isnone_string(obj):
    if obj == None:
        return "None"
    return "Found"

def gamx_deg_to_rad(degrees):
    return round(degrees * 3.14159265 / 180.0, 6);

def gamx_rad_to_deg(radians):
    return round(radians * 180.0 / 3.14159265, 6);

def gamx_axis_to_quat(angles=[0,0,0]):
    angle = math.sqrt((angles[0] * angles[0]) + (angles[1] * angles[1]) + (angles[2] * angles[2]))
    if angle > 0.0:
        angles[0] /= angle
        angles[1] /= angle
        angles[2] /= angle
        angle *= 0.5
        sinHlfAng = math.sin(angle)
        quat = [0,0,0,0]
        quat[0] = math.cos(angle)
        quat[1] = angles[0] * sinHlfAng
        quat[2] = angles[1] * sinHlfAng
        quat[3] = angles[2] * sinHlfAng
        mag = math.sqrt((quat[0] * quat[0]) + (quat[1] * quat[1]) + (quat[2] * quat[2]) + (quat[3] * quat[3]))
        quat[0] = quat[0] / mag
        quat[1] = quat[1] / mag
        quat[2] = quat[2] / mag
        quat[3] = quat[3] / mag
    else:
        quat = [1,0,0,0]
    return quat

def gamx_trnspresent(pos, rot, scl):
    if (pos != None and (pos[0] != 0.0 or pos[1] != 0.0 or pos[2] != 0.0)) or (rot != None and (rot[0] != 0.0 or rot[1] != 0.0 or rot[2] != 0.0)) or (scl != None and (scl[0] != 1.0 or scl[1] != 1.0 or scl[2] != 1.0)):
        return 1
    return 0

def gamx_transform(pos, rot, scl):
    node = r''
    if (pos != None and (pos[0] != 0.0 or pos[1] != 0.0 or pos[2] != 0.0)) or (rot != None and (rot[0] != 0.0 or rot[1] != 0.0 or rot[2] != 0.0)) or (scl != None and (scl[0] != 1.0 or scl[1] != 1.0 or scl[2] != 1.0)):
        node += r'<transform'
        if rot != None and (rot[0] != 0.0 or rot[1] != 0.0 or rot[2] != 0.0):
            node += r' mode="radians"'
        if pos != None and (pos[0] != 0.0 or pos[1] != 0.0 or pos[2] != 0.0):
            node += r' position="' + "%0.6f %0.6f %0.6f" % (pos[0], pos[2], -pos[1]) + r'"'
        if rot != None and (rot[0] != 0.0 or rot[1] != 0.0 or rot[2] != 0.0):
            node += r' axis="' + "%0.6f %0.6f %0.6f" % (rot[0], rot[2], -rot[1]) + r'"'
        if scl != None and (scl[0] != 1.0 or scl[1] != 1.0 or scl[2] != 1.0):
            node += r' scale="' + "%0.6f %0.6f %0.6f" % (scl[0], scl[2], scl[1]) + r'"'
        node += r' />'
    return node

def gamx_first_scene_name():
    if len(bpy.data.scenes):
        for scn in bpy.data.scenes:
            return scn.name
    else:
        return "default"

def gamx_export_source_sditva(fout, mesh):
    fout.write(3*tab4 + r'<geometry source="internal" type="disjoint_indexed_vertex_array">' + endl)
    fout.write(4*tab4 + r'<vertices count="' + "%d" % len(mesh.verts) + r'">')
    spacer = ''
    for vert in mesh.verts:
        fout.write(spacer + "%0.6f %0.6f %0.6f" % (round(vert.co[0], 6), round(vert.co[2], 6), round(-vert.co[1], 6)))
        spacer = ', '
    fout.write(r'</vertices>' + endl)
    fout.write(4*tab4 + r'<normals count="' + "%d" % len(mesh.faces) + r'">')
    spacer = ''
    for face in mesh.faces:
        fout.write(spacer + "%0.6f %0.6f %0.6f" % (round(face.no[0], 6), round(face.no[2], 6), round(-face.no[1], 6)))
        spacer = ', '
    fout.write(r'</normals>' + endl)
    if mesh.faceUV:
        count = 0
        for face in mesh.faces:
            count += len(face.v)
        fout.write(4*tab4 + r'<texuvs count="' + "%d" % count + r'">')
        spacer = ''
        for face in mesh.faces:
            for uv in face.uv:
                fout.write(spacer + "%0.6f %0.6f" % (round(uv[0], 6), round(1.0 - uv[1], 6)))
                spacer = ', '
        fout.write(r'</texuvs>' + endl)
    count = 0
    for face in mesh.faces:
        if len(face.v) == 3:
            count += 1
        else:
            count += 2
    fout.write(4*tab4 + r'<faces count="' + "%d" % count + r'" format="triangles">')
    count = 0
    fcount = 0
    vcount = 0
    spacer = ''
    for face in mesh.faces:
        if len(face.v) == 3:
            if mesh.faceUV:
                fout.write(spacer + "%d %d %d %d %d %d %d %d %d" % (face.v[0].index, fcount, vcount+0, face.v[1].index, fcount, vcount+1, face.v[2].index, fcount, vcount+2))
                spacer = ', '
            else:
                fout.write(spacer + "%d %d %d %d %d %d" % (face.v[0].index, fcount, face.v[1].index, fcount, face.v[2].index, fcount))
                spacer = ', '
            count += 1
            vcount += 3
        else:
            if mesh.faceUV:
                fout.write(spacer + "%d %d %d %d %d %d %d %d %d" % (face.v[0].index, fcount, vcount+0, face.v[1].index, fcount, vcount+1, face.v[2].index, fcount, vcount+2))
                spacer = ', '
                fout.write(spacer + "%d %d %d %d %d %d %d %d %d" % (face.v[0].index, fcount, vcount+0, face.v[2].index, fcount, vcount+2, face.v[3].index, fcount, vcount+3))
                spacer = ', '
            else:
                fout.write(spacer + "%d %d %d %d %d %d" % (face.v[0].index, fcount, face.v[1].index, fcount, face.v[2].index, fcount))
                spacer = ', '
                fout.write(spacer + "%d %d %d %d %d %d" % (face.v[0].index, fcount, face.v[2].index, fcount, face.v[3].index, fcount))
                spacer = ', '
            count += 2
            vcount += 4
        fcount += 1
    fout.write(r'</faces>' + endl)
    fout.write(3*tab4 + r'</geometry>' + endl)

def gamx_export_node(fout, tab, obj, chds):
    tabof = tab
    wrote_localizers = 0
    if len(chds[obj.name]):
        fout.write((tab+0)*tab4 + r'<node id="' + gamx_name_prefix('node_', obj.name) + '" type="transform">' + endl)
        fout.write((tab+1)*tab4 + r'<bounding><volume type="zero" /></bounding>' + endl)
        if obj.ipo == None:
            if gamx_trnspresent(obj.getLocation('localspace'), obj.getEuler('localspace'), obj.getSize('localspace')):
                fout.write((tab+1)*tab4 + r'<offset>' + gamx_transform(obj.getLocation('localspace'), obj.getEuler('localspace'), obj.getSize('localspace')) + r'</offset>' + endl)
        else:
            fout.write((tab+1)*tab4 + r'<offset>' + endl)
            if gamx_trnspresent(obj.getLocation('localspace'), obj.getEuler('localspace'), obj.getSize('localspace')):
                fout.write((tab+2)*tab4 + gamx_transform(obj.getLocation('localspace'), obj.getEuler('localspace'), obj.getSize('localspace')) + endl)
            fout.write((tab+2)*tab4 + r'<interpolator ref="' + gamx_name_prefix('ipo_', obj.ipo.name) + r'" />' + endl)
            fout.write((tab+1)*tab4 + r'</offset>' + endl)
        wrote_localizers = 1
        fout.write((tab+1)*tab4 + r'<assets>' + endl)
        tabof = tab + 2
    if obj.type == 'Mesh':
        mesh = obj.getData(0, 1)
        mode = mesh.mode
        if mesh.faceUV:
            for face in mesh.faces:
                mode |= face.mode
        if mode & (Blender.Mesh.FaceModes["HALO"] | Blender.Mesh.FaceModes["BILLBOARD"]) or mesh.name[:3] == 'bb_': # billboard
            if mesh.users == 1 and wrote_localizers:
                fout.write((tabof+0)*tab4 + r'<billboard ref="' + gamx_name_prefix('bb_', mesh.name) + r'" />' + endl)
            else:
                fout.write((tabof+0)*tab4 + r'<billboard id="' + gamx_name_prefix('obj_', obj.name) + r'" ref="' + gamx_name_prefix('bb_', mesh.name) + r'">' + endl)
                fout.write((tabof+1)*tab4 + r'<bounding><volume type="zero" /></bounding>' + endl)
                if not wrote_localizers:
                    if obj.ipo == None:
                        if gamx_trnspresent(obj.getLocation('localspace'), obj.getEuler('localspace'), obj.getSize('localspace')):
                            fout.write((tabof+1)*tab4 + r'<offset>' + gamx_transform(obj.getLocation('localspace'), obj.getEuler('localspace'), obj.getSize('localspace')) + r'</offset>' + endl)
                    else:
                        fout.write((tabof+1)*tab4 + r'<offset>' + endl)
                        if gamx_trnspresent(obj.getLocation('localspace'), obj.getEuler('localspace'), obj.getSize('localspace')):
                            fout.write((tabof+2)*tab4 + gamx_transform(obj.getLocation('localspace'), obj.getEuler('localspace'), obj.getSize('localspace')) + endl)
                        fout.write((tabof+2)*tab4 + r'<interpolator ref="' + gamx_name_prefix('ipo_', obj.ipo.name) + r'" />' + endl)
                        fout.write((tabof+1)*tab4 + r'</offset>' + endl)
                fout.write((tabof+0)*tab4 + r'</billboard>' + endl)
        else: # mesh
            if mesh.users == 1 and wrote_localizers:
                fout.write((tabof+0)*tab4 + r'<mesh ref="' + gamx_name_prefix('mesh_', mesh.name) + r'" />' + endl)
            else:
                fout.write((tabof+0)*tab4 + r'<mesh id="' + gamx_name_prefix('obj_', obj.name) + r'" ref="' + gamx_name_prefix('mesh_', mesh.name) + r'">' + endl)
                fout.write((tabof+1)*tab4 + r'<bounding><volume type="zero" /></bounding>' + endl)
                if not wrote_localizers:
                    if obj.ipo == None:
                        if gamx_trnspresent(obj.getLocation('localspace'), obj.getEuler('localspace'), obj.getSize('localspace')):
                            fout.write((tabof+1)*tab4 + r'<offset>' + gamx_transform(obj.getLocation('localspace'), obj.getEuler('localspace'), obj.getSize('localspace')) + r'</offset>' + endl)
                    else:
                        fout.write((tabof+1)*tab4 + r'<offset>' + endl)
                        if gamx_trnspresent(obj.getLocation('localspace'), obj.getEuler('localspace'), obj.getSize('localspace')):
                            fout.write((tabof+2)*tab4 + gamx_transform(obj.getLocation('localspace'), obj.getEuler('localspace'), obj.getSize('localspace')) + endl)
                        fout.write((tabof+2)*tab4 + r'<interpolator ref="' + gamx_name_prefix('ipo_', obj.ipo.name) + r'" />' + endl)
                        fout.write((tabof+1)*tab4 + r'</offset>' + endl)
                fout.write((tabof+0)*tab4 + r'</mesh>' + endl)
    elif obj.type == 'Camera':
        pass # TODO!
        print "Info: GAMX_Export: Warning: Object type '%s' export not yet supported.\r\n" % (obj.type,)
    elif obj.type == 'Lamp':
        pass # TODO!
        print "Info: GAMX_Export: Warning: Object type '%s' export not yet supported.\r\n" % (obj.type,)
    elif obj.type == "Empty":
        pass # Ignore empties
    else:
        print "Info: GAMX_Export: Warning: Object type '%s' not supported as a leaf node.\r\n" % (obj.type,)
    if len(chds[obj.name]):
        for chd in chds[obj.name]:
            gamx_export_node(fout, tab+2, chd, chds)
        fout.write((tab+1)*tab4 + r'</assets>' + endl)
        fout.write((tab+0)*tab4 + r'</node>' + endl)

def gamx_export(filename):
    try:
        print "Info: GAMX_Export: Beginning export to '%s'.\r\n" % (filename,) + endl
        assets = 0
        fout = file(filename, "w")
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
            
            # Write interpolators
            if not use_unique_timer and len(bpy.data.ipos):
                assets += 1
                if assets > 1:
                    fout.write(endl)
                fout.write(2*tab4 + r'<timer id="' + gamx_name_prefix('tmr_', gamx_name_prefix('obj_', gamx_first_scene_name())) + r'" type="basic">' + endl)
                fout.write(2*tab4 + r'</timer>' + endl)
            for ipo in bpy.data.ipos:
                if ipo.getCurve('LocX') != None or ipo.getCurve('LocY') != None or ipo.getCurve('LocZ') != None or ipo.getCurve('ScaleX') != None or ipo.getCurve('ScaleY') != None or ipo.getCurve('ScaleZ') != None or ipo.getCurve('RotX') != None or ipo.getCurve('RotY') != None or ipo.getCurve('RotZ') != None or ipo.getCurve('QuatW') != None or ipo.getCurve('QuatX') != None or ipo.getCurve('QuatY') != None or ipo.getCurve('QuatZ') != None:
                    # IPO validation check
                    valid = 1
                    if valid and (ipo.getCurve('LocX') != None or ipo.getCurve('LocY') != None or ipo.getCurve('LocZ') != None):
                        if ipo.getCurve('LocX') == None or ipo.getCurve('LocY') == None or ipo.getCurve('LocZ') == None:
                            print "Info: GAMX_Export: Error: Ipo '%s' is missing key frame definitions of at least one LocX, LocY, or LocZ channel (X:%s Y:%s Z:%s); skipping export.\r\n" % (ipo.name,gamx_isnone_string(ipo.getCurve('LocX')),gamx_isnone_string(ipo.getCurve('LocY')),gamx_isnone_string(ipo.getCurve('LocZ')))
                            valid = 0
                        elif len(ipo.getCurve('LocX').bezierPoints) != len(ipo.getCurve('LocY').bezierPoints) or len(ipo.getCurve('LocY').bezierPoints) != len(ipo.getCurve('LocZ').bezierPoints):
                            print "Info: GAMX_Export: Error: Ipo '%s' LocX, LocY, & LocZ channels do not contain same number of key frames (X:%d Y:%d Z:%d); skipping export.\r\n" % (ipo.name,len(ipo.getCurve('LocX').bezierPoints),len(ipo.getCurve('LocY').bezierPoints),len(ipo.getCurve('LocZ').bezierPoints))
                            valid = 0
                        else:
                            for i in range(len(ipo.getCurve('LocX').bezierPoints)):
                                if ipo.getCurve('LocX').bezierPoints[i].pt[0] != ipo.getCurve('LocY').bezierPoints[i].pt[0] or ipo.getCurve('LocY').bezierPoints[i].pt[0] != ipo.getCurve('LocZ').bezierPoints[i].pt[0]:
                                    print "Info: GAMX_Export: Error: Ipo '%s' LocX, LocY, & LocZ channels are not simultaneous for all key frame indicies; skipping export.\r\n" % (ipo.name,)
                                    valid = 0
                                    break
                    if valid and (ipo.getCurve('RotX') != None or ipo.getCurve('RotY') != None or ipo.getCurve('RotZ') != None):
                        if ipo.getCurve('RotX') == None or ipo.getCurve('RotY') == None or ipo.getCurve('RotZ') == None:
                            print "Info: GAMX_Export: Error: Ipo '%s' is missing key frame definitions of at least one RotX, RotY, or RotZ channel (X:%s Y:%s Z:%s); skipping export.\r\n" % (ipo.name,gamx_isnone_string(ipo.getCurve('RotX')),gamx_isnone_string(ipo.getCurve('RotY')),gamx_isnone_string(ipo.getCurve('RotZ')))
                            valid = 0
                        elif len(ipo.getCurve('RotX').bezierPoints) != len(ipo.getCurve('RotY').bezierPoints) or len(ipo.getCurve('RotY').bezierPoints) != len(ipo.getCurve('RotZ').bezierPoints):
                            print "Info: GAMX_Export: Error: Ipo '%s' RotX, RotY, & RotZ channels do not contain same number of key frames (X:%d Y:%d Z:%d); skipping export.\r\n" % (ipo.name,len(ipo.getCurve('RotX').bezierPoints),len(ipo.getCurve('RotY').bezierPoints),len(ipo.getCurve('RotZ').bezierPoints))
                            valid = 0
                        else:
                            for i in range(len(ipo.getCurve('RotX').bezierPoints)):
                                if ipo.getCurve('RotX').bezierPoints[i].pt[0] != ipo.getCurve('RotY').bezierPoints[i].pt[0] or ipo.getCurve('RotY').bezierPoints[i].pt[0] != ipo.getCurve('RotZ').bezierPoints[i].pt[0]:
                                    print "Info: GAMX_Export: Error: Ipo '%s' RotX, RotY, & RotZ channels are not simultaneous for all key frame indicies; skipping export.\r\n" % (ipo.name,)
                                    valid = 0
                                    break
                                if i > 0 and (abs(ipo.getCurve('RotX').bezierPoints[i].pt[1] - ipo.getCurve('RotX').bezierPoints[i-1].pt[1]) > 9.000001 or abs(ipo.getCurve('RotY').bezierPoints[i].pt[1] - ipo.getCurve('RotY').bezierPoints[i-1].pt[1]) > 9.000001 or abs(ipo.getCurve('RotZ').bezierPoints[i].pt[1] - ipo.getCurve('RotZ').bezierPoints[i-1].pt[1]) > 9.000001):
                                    print "Info: GAMX_Export: Error: Ipo '%s' has at least one RotX, RotY, & RotZ channel that travels beyond the safe 90 degree key frame value extent; skipping export.\r\n" % (ipo.name,)
                                    valid = 0
                                    break
                    if valid and (ipo.getCurve('ScaleX') != None or ipo.getCurve('ScaleY') != None or ipo.getCurve('ScaleZ') != None):
                        if ipo.getCurve('ScaleX') == None or ipo.getCurve('ScaleY') == None or ipo.getCurve('ScaleZ') == None:
                            print "Info: GAMX_Export: Error: Ipo '%s' is missing key frame definitions of at least one ScaleX, ScaleY, or ScaleZ channel (X:%s Y:%s Z:%s); skipping export.\r\n" % (ipo.name,gamx_isnone_string(ipo.getCurve('ScaleX')),gamx_isnone_string(ipo.getCurve('ScaleY')),gamx_isnone_string(ipo.getCurve('ScaleZ')))
                            valid = 0
                        elif len(ipo.getCurve('ScaleX').bezierPoints) != len(ipo.getCurve('ScaleY').bezierPoints) or len(ipo.getCurve('ScaleY').bezierPoints) != len(ipo.getCurve('ScaleZ').bezierPoints):
                            print "Info: GAMX_Export: Error: Ipo '%s' ScaleX, ScaleY, & ScaleZ channels do not contain same number of key frames (X:%d Y:%d Z:%d); skipping export.\r\n" % (ipo.name,len(ipo.getCurve('ScaleX').bezierPoints),len(ipo.getCurve('ScaleY').bezierPoints),len(ipo.getCurve('ScaleZ').bezierPoints))
                            valid = 0
                        else:
                            for i in range(len(ipo.getCurve('ScaleX').bezierPoints)):
                                if ipo.getCurve('ScaleX').bezierPoints[i].pt[0] != ipo.getCurve('ScaleY').bezierPoints[i].pt[0] or ipo.getCurve('ScaleY').bezierPoints[i].pt[0] != ipo.getCurve('ScaleZ').bezierPoints[i].pt[0]:
                                    print "Info: GAMX_Export: Error: Ipo '%s' ScaleX, ScaleY, & ScaleZ channels are not simultaneous for all key frame indicies; skipping export.\r\n" % (ipo.name,)
                                    valid = 0
                                    break
                    if valid and (ipo.getCurve('QuatW') != None or ipo.getCurve('QuatX') != None or ipo.getCurve('QuatY') != None or ipo.getCurve('QuatZ') != None):
                        if ipo.getCurve('QuatW') == None or ipo.getCurve('QuatX') == None or ipo.getCurve('QuatY') == None or ipo.getCurve('QuatZ') == None:
                            print "Info: GAMX_Export: Error: Ipo '%s' is missing key frame definitions of at least one QuatW, QuatX, QuatY, or QuatZ channel (W:%s X:%s Y:%s Z:%s); skipping export.\r\n" % (ipo.name,gamx_isnone_string(ipo.getCurve('QuatW')),gamx_isnone_string(ipo.getCurve('QuatX')),gamx_isnone_string(ipo.getCurve('QuatY')),gamx_isnone_string(ipo.getCurve('QuatZ')))
                            valid = 0
                        elif len(ipo.getCurve('QuatW').bezierPoints) != len(ipo.getCurve('QuatX').bezierPoints) or len(ipo.getCurve('QuatX').bezierPoints) != len(ipo.getCurve('QuatY').bezierPoints) or len(ipo.getCurve('QuatY').bezierPoints) != len(ipo.getCurve('QuatZ').bezierPoints):
                            print "Info: GAMX_Export: Error: Ipo '%s' QuatW, QuatX, QuatY, & QuatZ channels do not contain same number of key frames (W:%d X:%d Y:%d Z:%d); skipping export.\r\n" % (ipo.name,len(ipo.getCurve('QuatW').bezierPoints),len(ipo.getCurve('QuatX').bezierPoints),len(ipo.getCurve('QuatY').bezierPoints),len(ipo.getCurve('QuatZ').bezierPoints))
                            valid = 0
                        else:
                            for i in range(len(ipo.getCurve('QuatW').bezierPoints)):
                                if ipo.getCurve('QuatW').bezierPoints[i].pt[0] != ipo.getCurve('QuatX').bezierPoints[i].pt[0] or ipo.getCurve('QuatX').bezierPoints[i].pt[0] != ipo.getCurve('QuatY').bezierPoints[i].pt[0] or ipo.getCurve('QuatY').bezierPoints[i].pt[0] != ipo.getCurve('QuatZ').bezierPoints[i].pt[0]:
                                    print "Info: GAMX_Export: Error: Ipo '%s' QuatW, QuatX, QuatY, & QuatZ channels are not simultaneous for all key frame indicies; skipping export.\r\n" % (ipo.name,)
                                    valid = 0
                                    break
                    if valid:
                        assets += 1
                        if assets > 1:
                            fout.write(endl)
                        fout.write(2*tab4 + r'<interpolator id="' + gamx_name_prefix('ipo_', ipo.name) + r'" type="orientation">' + endl)
                        fout.write(3*tab4 + r'<keyframes source="internal" type="prs_array">' + endl)
                        if ipo.getCurve('LocX') != None:
                            fout.write(4*tab4 + r'<pos_time_indicies count="' + "%d" % len(ipo.getCurve('LocX').bezierPoints) + r'">')
                            spacer = ''
                            for i in range(len(ipo.getCurve('LocX').bezierPoints)):
                                if use_no_shift_over:
                                    if ipo.getCurve('LocX').bezierPoints[i].pt[0] != 1:
                                        fout.write(spacer + "%0.6f" % (round((ipo.getCurve('LocX').bezierPoints[i].pt[0] - 0) /  anim_fps, 6),))
                                    else:
                                        fout.write(spacer + "%0.6f" % (round((ipo.getCurve('LocX').bezierPoints[i].pt[0] - 1) /  anim_fps, 6),))
                                else:
                                    fout.write(spacer + "%0.6f" % (round((ipo.getCurve('LocX').bezierPoints[i].pt[0] - 1) /  anim_fps, 6),))
                                spacer = ', '
                            fout.write(r'</pos_time_indicies>' + endl)
                            fout.write(4*tab4 + r'<pos_key_values count="' + "%d" % len(ipo.getCurve('LocX').bezierPoints) + r'">')
                            spacer = ''
                            for i in range(len(ipo.getCurve('LocX').bezierPoints)):
                                fout.write(spacer + "%0.6f %0.6f %0.6f" % (round(ipo.getCurve('LocX').bezierPoints[i].pt[1], 6), round(ipo.getCurve('LocZ').bezierPoints[i].pt[1], 6), round(-ipo.getCurve('LocY').bezierPoints[i].pt[1], 6)))
                                spacer = ', '
                            fout.write(r'</pos_key_values>' + endl)
                        if ipo.getCurve('QuatW') != None:
                            fout.write(4*tab4 + r'<rot_time_indicies count="' + "%d" % len(ipo.getCurve('QuatW').bezierPoints) + r'">')
                            spacer = ''
                            for i in range(len(ipo.getCurve('QuatW').bezierPoints)):
                                if use_no_shift_over:
                                    if ipo.getCurve('QuatW').bezierPoints[i].pt[0] != 1:
                                        fout.write(spacer + "%0.6f" % (round((ipo.getCurve('QuatW').bezierPoints[i].pt[0] - 0) / anim_fps, 6),))
                                    else:
                                        fout.write(spacer + "%0.6f" % (round((ipo.getCurve('QuatW').bezierPoints[i].pt[0] - 1) / anim_fps, 6),))
                                else:
                                    fout.write(spacer + "%0.6f" % (round((ipo.getCurve('QuatW').bezierPoints[i].pt[0] - 1) / anim_fps, 6),))
                                spacer = ', '
                            fout.write(r'</rot_time_indicies>' + endl)
                            fout.write(4*tab4 + r'<rot_key_values count="' + "%d" % len(ipo.getCurve('QuatW').bezierPoints) + r'">')
                            spacer = ''
                            for i in range(len(ipo.getCurve('QuatW').bezierPoints)):
                                fout.write(spacer + "%0.6f %0.6f %0.6f %0.6f" % (round(ipo.getCurve('QuatW').bezierPoints[i].pt[1], 6), round(ipo.getCurve('QuatX').bezierPoints[i].pt[1], 6), round(ipo.getCurve('QuatZ').bezierPoints[i].pt[1], 6), round(-ipo.getCurve('QuatY').bezierPoints[i].pt[1], 6)))
                                spacer = ', '
                            fout.write(r'</rot_key_values>' + endl)
                        elif ipo.getCurve('RotX') != None:
                            fout.write(4*tab4 + r'<rot_time_indicies count="' + "%d" % len(ipo.getCurve('RotX').bezierPoints) + r'">')
                            spacer = ''
                            for i in range(len(ipo.getCurve('RotX').bezierPoints)):
                                if use_no_shift_over:
                                    if ipo.getCurve('RotX').bezierPoints[i].pt[0] != 1:
                                        fout.write(spacer + "%0.6f" % (round((ipo.getCurve('RotX').bezierPoints[i].pt[0] - 0) / anim_fps, 6),))
                                    else:
                                        fout.write(spacer + "%0.6f" % (round((ipo.getCurve('RotX').bezierPoints[i].pt[0] - 1) / anim_fps, 6),))
                                else:
                                    fout.write(spacer + "%0.6f" % (round((ipo.getCurve('RotX').bezierPoints[i].pt[0] - 1) / anim_fps, 6),))
                                spacer = ', '
                            fout.write(r'</rot_time_indicies>' + endl)
                            fout.write(4*tab4 + r'<rot_key_values count="' + "%d" % len(ipo.getCurve('RotX').bezierPoints) + r'">')
                            spacer = ''
                            for i in range(len(ipo.getCurve('RotX').bezierPoints)):
                                quat = gamx_axis_to_quat([gamx_deg_to_rad(ipo.getCurve('RotX').bezierPoints[i].pt[1] * 10.0), gamx_deg_to_rad(ipo.getCurve('RotZ').bezierPoints[i].pt[1] * 10.0), gamx_deg_to_rad(-ipo.getCurve('RotY').bezierPoints[i].pt[1] * 10.0)])
                                fout.write(spacer + "%0.6f %0.6f %0.6f %0.6f" %  (round(quat[0], 6), round(quat[1], 6), round(quat[2], 6), round(quat[3], 6)))
                                spacer = ', '
                            fout.write(r'</rot_key_values>' + endl)
                        if ipo.getCurve('ScaleX') != None:
                            fout.write(4*tab4 + r'<scl_time_indicies count="' + "%d" % len(ipo.getCurve('ScaleX').bezierPoints) + r'">')
                            spacer = ''
                            for i in range(len(ipo.getCurve('ScaleX').bezierPoints)):
                                if use_no_shift_over:
                                    if ipo.getCurve('ScaleX').bezierPoints[i].pt[0] != 1:
                                        fout.write(spacer + "%0.6f" % (round((ipo.getCurve('ScaleX').bezierPoints[i].pt[0] - 0) / anim_fps, 6),))
                                    else:
                                        fout.write(spacer + "%0.6f" % (round((ipo.getCurve('ScaleX').bezierPoints[i].pt[0] - 1) / anim_fps, 6),))
                                else:
                                    fout.write(spacer + "%0.6f" % (round((ipo.getCurve('ScaleX').bezierPoints[i].pt[0] - 1) / anim_fps, 6),))
                                spacer = ', '
                            fout.write(r'</scl_time_indicies>' + endl)
                            fout.write(4*tab4 + r'<scl_key_values count="' + "%d" % len(ipo.getCurve('ScaleX').bezierPoints) + r'">')
                            spacer = ''
                            for i in range(len(ipo.getCurve('ScaleX').bezierPoints)):
                                fout.write(spacer + "%0.6f %0.6f %0.6f" % (round(ipo.getCurve('ScaleX').bezierPoints[i].pt[1], 6), round(ipo.getCurve('ScaleZ').bezierPoints[i].pt[1], 6), round(ipo.getCurve('ScaleY').bezierPoints[i].pt[1], 6)))
                                spacer = ', '
                            fout.write(r'</scl_key_values>' + endl)
                        fout.write(3*tab4 + r'</keyframes>' + endl)
                        fout.write(3*tab4 + r'<controller>' + endl)
                        if use_unique_timer:
                            fout.write(4*tab4 + r'<timer id="' + gamx_name_prefix('tmr_', gamx_name_prefix('ipo_', ipo.name)) + r'" type="basic">' + endl)
                            fout.write(4*tab4 + r'</timer>' + endl)
                        else:
                            fout.write(4*tab4 + r'<timer ref="' + gamx_name_prefix('tmr_', gamx_name_prefix('obj_', gamx_first_scene_name())) + r'"/>' + endl)
                        fout.write(3*tab4 + r'</controller>' + endl)
                        if ipo.getCurve('LocX') != None:
                            fout.write(3*tab4 + r'<pos_polation>')
                            mode = 0
                            for ipoc in ipo.curves:
                                if ipoc.name[:3] == "Loc":
                                    mode |= ipoc.interpolation
                            if mode & Blender.IpoCurve.InterpTypes["CONST"]:
                                fout.write(r'ipo_const ')
                            elif mode & Blender.IpoCurve.InterpTypes["LINEAR"]:
                                fout.write(r'ipo_linear ')
                            elif mode & Blender.IpoCurve.InterpTypes["BEZIER"]:
                                if use_linear_over_cubic_cr:
                                    fout.write(r'ipo_linear ') # no direct tag
                                    print "Info: GAMX_Export: Warning: BEZIER IpoCurve interpolator setting not supported; using 'linear' position interpolation.\r\n"
                                else:
                                    fout.write(r'ipo_cubiccr ') # no direct tag
                                    print "Info: GAMX_Export: Warning: BEZIER IpoCurve interpolator setting not supported; using 'cubic_cr' position interpolation.\r\n"
                            else:
                                fout.write(r'ipo_linear ') # default
                            mode = 0
                            for ipoc in ipo.curves:
                                if ipoc.name[:3] == "Loc":
                                    mode |= ipoc.extend
                            if mode & Blender.IpoCurve.ExtendTypes["CONST"]:
                                fout.write(r'epo_const')
                            elif mode & Blender.IpoCurve.ExtendTypes["EXTRAP"]:
                                fout.write(r'epo_linear')
                            elif mode & Blender.IpoCurve.ExtendTypes["CYCLIC"]:
                                fout.write(r'epo_cyclic')
                            elif mode & Blender.IpoCurve.ExtendTypes["CYCLIC_EXTRAP"]:
                                fout.write(r'epo_cyclicadd')
                            else:
                                fout.write(r'epo_const') # default
                            fout.write(r'</pos_polation>' + endl)
                        if ipo.getCurve('QuatW') != None or ipo.getCurve('RotX') != None:
                            fout.write(3*tab4 + r'<rot_polation>')
                            mode = 0
                            for ipoc in ipo.curves:
                                if ipoc.name[:3] == "Rot" or ipoc.name[:4] == "Quat":
                                    mode |= ipoc.interpolation
                            if mode & Blender.IpoCurve.InterpTypes["CONST"]:
                                fout.write(r'ipo_const ')
                            elif mode & Blender.IpoCurve.InterpTypes["LINEAR"]:
                                fout.write(r'ipo_linear ')
                            elif mode & Blender.IpoCurve.InterpTypes["BEZIER"]:
                                if use_linear_over_cubic_cr:
                                    fout.write(r'ipo_linear ') # no direct tag
                                    print "Info: GAMX_Export: Warning: BEZIER IpoCurve interpolator setting not supported; using 'linear' rotation interpolation.\r\n"
                                else:
                                    fout.write(r'ipo_cubiccr ') # no direct tag
                                    print "Info: GAMX_Export: Warning: BEZIER IpoCurve interpolator setting not supported; using 'cubic_cr' rotation interpolation.\r\n"
                            else:
                                fout.write(r'ipo_linear ') # default
                            mode = 0
                            for ipoc in ipo.curves:
                                if ipoc.name[:3] == "Rot" or ipoc.name[:4] == "Quat":
                                    mode |= ipoc.extend
                            if mode & Blender.IpoCurve.ExtendTypes["CONST"]:
                                fout.write(r'epo_const')
                            elif mode & Blender.IpoCurve.ExtendTypes["EXTRAP"]:
                                fout.write(r'epo_linear')
                            elif mode & Blender.IpoCurve.ExtendTypes["CYCLIC"]:
                                fout.write(r'epo_cyclic')
                            elif mode & Blender.IpoCurve.ExtendTypes["CYCLIC_EXTRAP"]:
                                fout.write(r'epo_cyclicadd')
                            else:
                                fout.write(r'epo_const') # default
                            fout.write(r'</rot_polation>' + endl)
                        if ipo.getCurve('ScaleX') != None:
                            fout.write(3*tab4 + r'<scl_polation>')
                            mode = 0
                            for ipoc in ipo.curves:
                                if ipoc.name[:5] == "Scale":
                                    mode |= ipoc.interpolation
                            if mode & Blender.IpoCurve.InterpTypes["CONST"]:
                                fout.write(r'ipo_const ')
                            elif mode & Blender.IpoCurve.InterpTypes["LINEAR"]:
                                fout.write(r'ipo_linear ')
                            elif mode & Blender.IpoCurve.InterpTypes["BEZIER"]:
                                if use_linear_over_cubic_cr:
                                    fout.write(r'ipo_linear ') # no direct tag
                                    print "Info: GAMX_Export: Warning: BEZIER IpoCurve interpolator setting not supported; using 'linear' scale interpolation.\r\n"
                                else:
                                    fout.write(r'ipo_cubiccr ') # no direct tag
                                    print "Info: GAMX_Export: Warning: BEZIER IpoCurve interpolator setting not supported; using 'cubic_cr' scale interpolation.\r\n"
                            else:
                                fout.write(r'ipo_linear ') # default
                            mode = 0
                            for ipoc in ipo.curves:
                                if ipoc.name[:5] == "Scale":
                                    mode |= ipoc.extend
                            if mode & Blender.IpoCurve.ExtendTypes["CONST"]:
                                fout.write(r'epo_const')
                            elif mode & Blender.IpoCurve.ExtendTypes["EXTRAP"]:
                                fout.write(r'epo_linear')
                            elif mode & Blender.IpoCurve.ExtendTypes["CYCLIC"]:
                                fout.write(r'epo_cyclic')
                            elif mode & Blender.IpoCurve.ExtendTypes["CYCLIC_EXTRAP"]:
                                fout.write(r'epo_cyclicadd')
                            else:
                                fout.write(r'epo_const') # default
                            fout.write(r'</scl_polation>' + endl)
                        fout.write(2*tab4 + r'</interpolator>' + endl)
            
            # Write materials
            for mat in bpy.data.materials:
                assets += 1
                if assets > 1:
                    fout.write(endl)
                fout.write(2*tab4 + r'<material id="' + gamx_name_prefix('mat_', mat.name) + r'" type="material">' + endl)
                R, G, B, A = round(mat.R * mat.amb, 6), round(mat.G * mat.amb, 6), round(mat.B * mat.amb, 6), round(mat.alpha, 6)
                fout.write(3*tab4 + r'<ambient>' + "%0.6f %0.6f %0.6f %0.6f" % (R,G,B,A) + r'</ambient>' + endl)
                R, G, B, A = round(mat.R, 6), round(mat.G, 6), round(mat.B, 6), round(mat.alpha, 6)
                fout.write(3*tab4 + r'<diffuse>' + "%0.6f %0.6f %0.6f %0.6f" % (R,G,B,A) + r'</diffuse>' + endl)
                R, G, B, A = round(mat.specR, 6), round(mat.specG, 6), round(mat.specB, 6), round(mat.alpha, 6)
                fout.write(3*tab4 + r'<specular>' + "%0.6f %0.6f %0.6f %0.6f" % (R,G,B,A) + r'</specular>' + endl)
                R, G, B, A = round(mat.R * mat.emit, 6), round(mat.G * mat.emit, 6), round(mat.B * mat.emit, 6), round(mat.alpha, 6)
                fout.write(3*tab4 + r'<emmisive>' + "%0.6f %0.6f %0.6f %0.6f" % (R,G,B,A) + r'</emmisive>' + endl)
                S = round((mat.hard - 1.0) / 510.0, 6) # [1,511]
                fout.write(3*tab4 + r'<shininess>' + "%0.6f" % (S,) + r'</shininess>' + endl)
                fout.write(2*tab4 + r'</material>' + endl)
            
            # Write textures
            for tex in bpy.data.textures:
                if tex.getImage() == None:
                    print "Info: GAMX_Export: Error: Texture '%s' does not have an image. Only image textures are supported.\r\n" % (tex.name,)
                else:
                    mtex = None
                    # Find corresponding MTex through materials (texture class doesn't directly link)
                    for mat in bpy.data.materials:
                        for mtex in mat.getTextures():
                            if mtex is not None and gamx_name_prefix('tex_', mtex.tex.name) == gamx_name_prefix('tex_', tex.name):
                                break # layer 2
                        else:
                            mtex = None
                        if mtex is not None: # layer 1
                            break
                    else:
                        print "Info: GAMX_Export: Error: Cannot find corresponding MTex material structure for texture '%s'.\r\n" % (tex.name,)
                        continue # MTex not found, cannot extract texture data
                    # Although MTex at this point isn't necessarily the exact correspondent, for most types it's close enough
                    assets += 1
                    if assets > 1:
                        fout.write(endl)
                    fout.write(2*tab4 + r'<texture id="' + gamx_name_prefix('tex_', tex.name) + r'" type="static">' + endl)
                    fout.write(3*tab4 + r'<surface source="external">' + endl)
                    fout.write(4*tab4 + r'<url>' + gamx_file_prefix(tex.getImage().getFilename()[2:]) + r'</url>' + endl)
                    fout.write(4*tab4 + r'<transforms>')
                    spacer = ''
                    if tex.flags & Blender.Texture.Flags["NEGALPHA"]:
                        fout.write(spacer + 'invert_ac')
                        spacer = ' '
                    if mtex.noRGB:
                        fout.write(spacer + 'force_gs')
                        spacer = ' '
                    #else: # implication of forcing rgb is not well enough implied
                    #    fout.write(spacer + 'force_rgb')
                    #    spacer = ' '
                    if tex.useAlpha or tex.imageFlags & Blender.Texture.ImageFlags["USEALPHA"]:
                        fout.write(spacer + 'force_ac')
                        spacer = ' '
                    else: # very implied that if alpha is not to be used to get rid of it
                        fout.write(spacer + 'force_no_ac')
                        spacer = ' '
                    if tex.flags & Blender.Texture.Flags["FLIPBLEND"]:
                        fout.write(spacer + 'flip_vert flip_horz')
                        spacer = ' '
                    fout.write(r'</transforms>' + endl)
                    fout.write(3*tab4 + r'</surface>' + endl)
                    fout.write(3*tab4 + r'<environment>')
                    # Figure out the environment setting, most of which don't have enough information to determine full range of options
                    if tex.normalMap or tex.imageFlags & Blender.Texture.ImageFlags["NORMALMAP"]:
                        fout.write('dot3')
                    elif mtex.blendmode == Blender.Texture.BlendModes["DARKEN"]: # no direct tag
                        fout.write('replace')
                        print "Info: GAMX_Export: Warning: DARKEN BlendModes fragmentation environment setting not supported; using 'replace' fragmentation environment.\r\n"
                    elif mtex.blendmode == Blender.Texture.BlendModes["DIVIDE"]: # no direct tag
                        fout.write('decal')
                        print "Info: GAMX_Export: Warning: DIVIDE BlendModes fragmentation environment setting not supported; using 'decal' fragmentation environment.\r\n"
                    elif mtex.blendmode == Blender.Texture.BlendModes["LIGHTEN"]: # no direct tag
                        fout.write('replace')
                        print "Info: GAMX_Export: Warning: LIGHTEN BlendModes fragmentation environment setting not supported; using 'replace' fragmentation environment.\r\n"
                    #elif mtex.blendmode == Blender.Texture.BlendModes["MIX"]:
                    #    fout.write('modulate') # x1,x2,x4 implemented in else block
                    elif mtex.blendmode == Blender.Texture.BlendModes["ADD"]:
                        fout.write('add')
                    #elif mtex.blendmode == Blender.Texture.BlendModes["MULTIPLY"]: # no direct tag
                    #    fout.write('modulate') # x1,x2,x4 implemented in else block
                    elif mtex.blendmode == Blender.Texture.BlendModes["DIFFERENCE"]: # no direct tag
                        fout.write('subtract')
                        print "Info: GAMX_Export: Warning: DIFFERENCE BlendModes fragmentation environment setting not supported; using 'subtract' fragmentation environment.\r\n"
                    elif mtex.blendmode == Blender.Texture.BlendModes["SUBTRACT"]:
                        fout.write('subtract')
                    #elif mtex.blendmode == Blender.Texture.BlendModes["SCREEN"]: # no direct tag
                    #    fout.write('modulate') # x1,x2,x4 implemented in else block
                    else:
                        if mtex.blendmode != Blender.Texture.BlendModes["MIX"]:
                            if mtex.blendmode == Blender.Texture.BlendModes["MULTIPLY"]:
                                print "Info: GAMX_Export: Warning: MULTIPLY BlendModes fragmentation environment setting not supported; using 'modulate' fragmentation environment.\r\n"
                            elif mtex.blendmode == Blender.Texture.BlendModes["SCREEN"]:
                                print "Info: GAMX_Export: Warning: SCREEN BlendModes fragmentation environment setting not supported; using 'modulate' fragmentation environment.\r\n"
                            else:
                                print "Info: GAMX_Export: Warning: UNKNOWN BlendModes fragmentation environment setting not supported; using 'modulate' fragmentation environment.\r\n"
                        if mtex.varfac == 4.0:
                            fout.write('modulate_x4')
                        elif mtex.varfac == 2.0:
                            fout.write('modulate_x2')
                        else:
                            fout.write('modulate')
                    fout.write(r'</environment>' + endl)
                    fout.write(3*tab4 + r'<filter>')
                    if tex.mipmap or tex.imageFlags & Blender.Texture.ImageFlags["MIPMAP"]:
                        if tex.interpol: # not enough information to determine full range of options
                            fout.write('trilinear')
                        else:
                            if use_bilinear_over_unilinear:
                                fout.write('bilinear')
                                print "Info: GAMX_Export: Warning: No interpolation & MIPMAP ImageFlags filter setting is ambiguous; using 'bilinear' filtering.\r\n"
                            else:
                                fout.write('unilinear')
                                print "Info: GAMX_Export: Warning: No interpolation & MIPMAP ImageFlags filter setting is ambiguous; using 'unilinear' filtering.\r\n"
                    else:
                        if tex.interpol:
                            fout.write('linear')
                        else:
                            fout.write('nearest')
                    fout.write(r'</filter>' + endl)
                    fout.write(3*tab4 + r'<swrap>')
                    if tex.getImage().clampX: # not enough information to determine full range of options
                        fout.write('clamp')
                    else:
                        fout.write('repeat')
                    fout.write(r'</swrap>' + endl)
                    fout.write(3*tab4 + r'<twrap>')
                    if tex.getImage().clampY: # not enough information to determine full range of options
                        fout.write('clamp')
                    else:
                        fout.write('repeat')
                    fout.write(r'</twrap>' + endl)
                    fout.write(2*tab4 + r'</texture>' + endl)
            
            # Write cameras
            pass # TODO!
            
            # Write lamps
            pass # TODO!
            
            # Write BBs
            for bb in bpy.data.meshes:
                mode = bb.mode
                if bb.faceUV:
                    for face in bb.faces:
                        mode |= face.mode
                if mode & (Blender.Mesh.FaceModes["HALO"] | Blender.Mesh.FaceModes["BILLBOARD"]) or bb.name[:3] == 'bb_':
                    assets += 1
                    if assets > 1:
                        fout.write(endl)
                    fout.write(2*tab4 + r'<billboard id="' + gamx_name_prefix('bb_', bb.name) + r'" type="static">' + endl)
                    gamx_export_source_sditva(fout, bb)
                    fout.write(3*tab4 + r'<bounding><volume type="zero" /></bounding>' + endl)
                    mats = []
                    for mat in bb.materials:
                        if mat != None:
                            mats.append(gamx_name_prefix('mat_', mat.name))
                    if len(mats):
                        fout.write(3*tab4 + r'<materials>' + endl)
                        for mat in mats:
                            fout.write(4*tab4 + r'<material ref="' + gamx_name_prefix('mat_', mat) + '" />' + endl)
                        fout.write(3*tab4 + r'</materials>' + endl)
                    if bb.faceUV:
                        texs = []
                        for mat in bb.materials:
                            if mat != None:
                                for tex in mat.textures:
                                    if tex != None:
                                        texs.append(gamx_name_prefix('tex_', tex.tex.name))
                        if len(texs):
                            fout.write(3*tab4 + r'<textures>' + endl)
                            for tex in texs:
                                fout.write(4*tab4 + r'<texture ref="' + gamx_name_prefix('tex_', tex) + '" />' + endl)
                            fout.write(3*tab4 + r'</textures>' + endl)
                    fout.write(2*tab4 + r'</billboard>' + endl)
            
            # Write meshes
            for mesh in bpy.data.meshes:
                mode = mesh.mode
                if mesh.faceUV:
                    for face in mesh.faces:
                        mode |= face.mode
                if (mode & ~(Blender.Mesh.FaceModes["HALO"] | Blender.Mesh.FaceModes["BILLBOARD"]) and mesh.name[:3] != 'bb_') or mesh.name[:5] == 'mesh_':
                    assets += 1
                    if assets > 1:
                        fout.write(endl)
                    fout.write(2*tab4 + r'<mesh id="' + gamx_name_prefix('mesh_', mesh.name) + r'" type="static">' + endl)
                    gamx_export_source_sditva(fout, mesh)
                    fout.write(3*tab4 + r'<bounding><volume type="zero" /></bounding>' + endl)
                    mats = []
                    for mat in mesh.materials:
                        if mat != None:
                            mats.append(gamx_name_prefix('mat_', mat.name))
                    if len(mats):
                        fout.write(3*tab4 + r'<materials>' + endl)
                        for mat in mats:
                            fout.write(4*tab4 + r'<material ref="' + gamx_name_prefix('mat_', mat) + '" />' + endl)
                        fout.write(3*tab4 + r'</materials>' + endl)
                    if mesh.faceUV:
                        texs = []
                        for mat in mesh.materials:
                            if mat != None:
                                for tex in mat.textures:
                                    if tex != None:
                                        texs.append(gamx_name_prefix('tex_', tex.tex.name))
                        if len(texs):
                            fout.write(3*tab4 + r'<textures>' + endl)
                            for tex in texs:
                                fout.write(4*tab4 + r'<texture ref="' + gamx_name_prefix('tex_', tex) + '" />' + endl)
                            fout.write(3*tab4 + r'</textures>' + endl)
                    fout.write(2*tab4 + r'</mesh>' + endl)
            
            # Write & convert scenes -> object trees
            for scn in bpy.data.scenes:
                if len(scn.objects):
                    assets += len(scn.objects)
                    if assets > 1:
                        fout.write(endl)
                    fout.write(2*tab4 + r'<node id="' + gamx_name_prefix('obj_', scn.name) + r'" type="transform">' + endl)
                    fout.write(3*tab4 + r'<bounding><volume type="zero" /></bounding>' + endl)
                    fout.write(3*tab4 + r'<assets>' + endl)
                    chds = {}
                    for obj in scn.objects:
                        chds[obj.name] = []
                    for obj in scn.objects:
                        if obj.parent != None:
                            chds[obj.parent.name].append(obj)
                    for obj in scn.objects:
                        if obj.parent == None:
                            gamx_export_node(fout, 4, obj, chds)
                    fout.write(3*tab4 + r'</assets>' + endl)
                    fout.write(2*tab4 + r'</node>' + endl)
            
            # Write footer
            fout.write(1*tab4 + r'</assets>' + endl)
            fout.write(0*tab4 + r'</gamx>' + endl)
        except:
            raise
        finally:
            fout.close()
        print "Info: GAMX_Export: Finished exporting %d items to '%s'.\r\n" % (assets, filename)
    except:
        raise

def gamx_export_gui(filename):
    global name_prefix
    global file_prefix
    global anim_fps
    global use_no_shift_over
    global use_bilinear_over_unilinear
    global use_linear_over_cubic_cr
    global use_unique_timer
    global last_folder
    try:
        block = [ ]
        opt_nmprefix = Blender.Draw.Create(name_prefix)
        block.append(("Name prefix: ", opt_nmprefix, 0, 30, "Prefixes all objects. Used to identify assets in a global system."))
        opt_flprefix = Blender.Draw.Create(file_prefix)
        block.append(("File prefix: ", opt_flprefix, 0, 30, "Used to specify a particular local directory or filename offset."))
        opt_animfps = Blender.Draw.Create(anim_fps)
        block.append(("Anim. FPS: ", opt_animfps, 1.0, 120.0, "Exported frame control uses this value to convert to seconds."))
        opt_noshiftover = Blender.Draw.Create(use_no_shift_over)
        block.append(("Anim|NoShift", opt_noshiftover, "Fudge frame 1 as frame 0 (on) instead of full -1 frame shift (off)."))
        opt_bioveruni = Blender.Draw.Create(use_bilinear_over_unilinear)
        block.append(("Texs|Bi|Uni", opt_bioveruni, "Texs /w MIPs but w/o interp can use bilinear (on) or unilinear (off) filtering."))
        opt_linovercub = Blender.Draw.Create(use_linear_over_cubic_cr)
        block.append(("IPOs|Bez->Lin", opt_linovercub, "Bezier converts to linear (on) or cubic_cr (off)."))
        opt_useunqtmr = Blender.Draw.Create(use_unique_timer)
        block.append(("TMRs|Unq|All", opt_useunqtmr, "Timers are unique per object (on) or shared across all (off)."))
        retVal = Blender.Draw.PupBlock("GAMX Export Options", block)
        
        if retVal:
            name_prefix = "%s" % opt_nmprefix
            name_prefix = name_prefix[1:][:-1]
            file_prefix = "%s" % opt_flprefix
            file_prefix = file_prefix[1:][:-1]
            anim_fps = float("%s" % opt_animfps)
            if opt_noshiftover == 1:
                use_no_shift_over = True
            else:
                use_no_shift_over = False
            if opt_bioveruni == 1:
                use_bilinear_over_unilinear = True
            else:
                use_bilinear_over_unilinear = False
            if opt_linovercub == 1:
                use_linear_over_cubic_cr = True
            else:
                use_linear_over_cubic_cr = False
            if opt_useunqtmr == 1:
                use_unique_timer = True
            else:
                use_unique_timer = False
            last_folder = os.path.abspath(os.path.dirname(filename))
            gamx_try_save_options()
            gamx_export(filename)
            Blender.Draw.PupMenu("Exporting successful.%t|Ok")
    except:
        Blender.Draw.PupMenu("Failure exporting.%t|Ok")
        raise

if __name__ == '__main__':
    gamx_try_load_options()
    if not os.path.exists(last_folder):
        last_folder = os.path.abspath(os.path.dirname(Blender.Get("filename")))
    filename = os.path.join(last_folder, os.path.splitext(os.path.split(Blender.Get("filename"))[1])[0] + ".gamx")
    Blender.Window.FileSelector(gamx_export_gui, "Export Asset Manifest GAMX", filename)
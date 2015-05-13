#!/usr/bin/env python

__author__ = "Johanna Wolf"
__url__ = ("http://gewizes.sourceforge.net/")
__version__ = "1.0"
__email__ = "johanna.a.wolf@gmail.com"
__doc__ = """\
Description: Wraps the job of calling PVRTC texturetool on image files found from path walk with extensions matching convft_list but not containing anything in ignore_list.
Usage: ./gwpvrtc_conv.py [-fdm24lpr] folder|file.
    -f: Force conversion (no date checking).
    -d: Delete file before conversion (helps ensure correctness if fail)
    -m: Generate mipmaps.
    -2: Use 2bpp PVRTC mode.
    -4: Use 4bpp PVRTC mode.
    -l: Use linear PVRTC weighting in export.	
    -p: Use perceptual PVRTC weighting in export.
    -r: Recursive operation.
"""

# Texturetool doc: http://developer.apple.com/iphone/library/qa/qa2008/qa1611.html

# geWiz PVRTC rev1 output format:
# 8 string - "GWPVRTCR1" header tag, last byte is alpha-numeric revision #
# 2 short  - Level 0 dimension (width and height values, since square image)
# 4 long   - Surface format (EGW_SURFACE_FRMT_*), always some PVRTC based format
# 4 long   - Data segment size to follow (including mips, if generated), should be filesize - 18
# to eof   - Raw PVRTC data + mips (if generated)

import sys
import math
import os
import struct

encoder_wlin = r'--channel-weighting-linear'
encoder_wprc = r'--channel-weighting-perceptual'
encoder_bpp2 = r'--bits-per-pixel-2'
encoder_bpp4 = r'--bits-per-pixel-4'

encoder_wgt = ''
encoder_bpp = ''
encoder_gmp = ''

endian_out = '<' # See struct.pack format, < little-endian, for iPhone

print_help = 0
check_date = 1
dlt_b4_wrt = 0
recursive = 0
txtr_tool = r'/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/texturetool'
dconv_path = r'/Users/johannes/Documents/Dev/iRis/res/'
convft_list = [r'.png']
ignore_list = [r'irisicon.png', r'.svn', r'.xcode', r'.DS_Store']
intmd_file = '/var/tmp/pvrtctex.raw'

def in_search_list(loc):
    for item in convft_list:
        if loc[-len(item):].lower() == item.lower():
            return 1
    return 0

def in_ignore_list(loc):
    for item in ignore_list:
        if loc.lower().find(item.lower()) != -1:
            return 1
    return 0

def colortype_string(colortype):
    # colortype corresponds to:
    # #define PNG_COLOR_MASK_PALETTE    1
    # #define PNG_COLOR_MASK_COLOR      2
    # #define PNG_COLOR_MASK_ALPHA      4
    str = ""
    if colortype & 1:
        if len(str):
            str += " | "
        str += "PNG_COLOR_MASK_PALETTE"
    if colortype & 2:
        if len(str):
            str += " | "
        str += "PNG_COLOR_MASK_COLOR"
    if colortype & 4:
        if len(str):
            str += " | "
        str += "PNG_COLOR_MASK_ALPHA"
    return str

def format_string(format):
    # surface format corresponds to:
    # #define EGW_SURFACE_FRMT_PVRTCRGB2  0x12002
    # #define EGW_SURFACE_FRMT_PVRTCRGBA2 0x12102
    # #define EGW_SURFACE_FRMT_PVRTCRGB4  0x12004
    # #define EGW_SURFACE_FRMT_PVRTCRGBA4 0x12104
    # #define EGW_SURFACE_FRMT_PGENMIPS   0x00080 (mipmaps already generated)
    # #define EGW_SURFACE_FRMT_EXAC       0x00100 (alpha channel in use)
    str = ""
    if format & 0x00080:
        if len(str):
            str += " | "
        str += "EGW_SURFACE_FRMT_PGENMIPS"
    if ((format & 0x12002) == 0x12002) and not (format & 0x00100):
        if len(str):
            str += " | "
        str += "EGW_SURFACE_FRMT_PVRTCRGB2"
    if ((format & 0x12102) == 0x12102):
        if len(str):
            str += " | "
        str += "EGW_SURFACE_FRMT_PVRTCRGBA2"
    if ((format & 0x12004) == 0x12004) and not (format & 0x00100):
        if len(str):
            str += " | "
        str += "EGW_SURFACE_FRMT_PVRTCRGB4"
    if ((format & 0x12104) == 0x12104):
        if len(str):
            str += " | "
        str += "EGW_SURFACE_FRMT_PVRTCRGBA4"
    return str

def convert_png(filename, filename_mod):
    length = 0
    fin = open(filename, 'rb')
    # Below reader is mutilated from http://the.taoofmac.com/space/Projects/PNGCanvas
    try:
        fin.read(8) # header, no check
        while 1: # exception will throw on end of file
            length = struct.unpack("!I",fin.read(4))[0] # ! for network (big endian), png always in network format
            tag = fin.read(4)
            data = fin.read(length)
            crc = struct.unpack("!i",fin.read(4))[0] # z-lib crc32, no check
            if tag == "IHDR":
                ( width, height, bitdepth, colortype, compression, filter, interlace ) = struct.unpack("!2I5B",data)
                break
    except:
        fin.close()
        raise
    else:
        fin.close()
    # colortype corresponds to:
    # #define PNG_COLOR_MASK_PALETTE    1
    # #define PNG_COLOR_MASK_COLOR      2
    # #define PNG_COLOR_MASK_ALPHA      4
    if not colortype & 2 or colortype & 1:
        raise ImportError("Colortype %d is not RGB. PVRTC may only be applied to square >4 power-of-two sized RGB(A) images." % (colortype,))
    if width != height:
        raise ImportError("Width %d and height %d do not match. PVRTC may only be applied to square >4 power-of-two sized RGB(A) images" % (width, height))
    if not width >= 4:
        raise ImportError("Width %d and height %d are not at least 4. PVRTC may only be applied to square >4 power-of-two sized RGB(A) images" % (width, height))
    if math.fmod(math.log(width) / math.log(2.0), 1.0) != 0.0:
        raise ImportError("Width %d and height %d are not powers of 2. PVRTC may only be applied to square >4 power-of-two sized RGB(A) images" % (width, height))
    # surface format corresponds to:
    # #define EGW_SURFACE_FRMT_PGENMIPS   0x0080
    # #define EGW_SURFACE_FRMT_PVRTCRGB2  0x12002
    # #define EGW_SURFACE_FRMT_PVRTCRGBA2 0x12102
    # #define EGW_SURFACE_FRMT_PVRTCRGB4  0x12004
    # #define EGW_SURFACE_FRMT_PVRTCRGBA4 0x12104
    if encoder_bpp == encoder_bpp2:
        if colortype & 4:
            format = 0x12102 # EGW_SURFACE_FRMT_PVRTCRGBA2
        else:
            format = 0x12002 # EGW_SURFACE_FRMT_PVRTCRGB2
    else:
        if colortype & 4:
            format = 0x12104 # EGW_SURFACE_FRMT_PVRTCRGBA4
        else:
            format = 0x12004 # EGW_SURFACE_FRMT_PVRTCRGB4
    if len(encoder_gmp) != 0:
        format |= 0x0080 # EGW_SURFACE_FRMT_PGENMIPS
    print "Info: GWPVRTC_Convert: '%s' properties:\r\n    WHD: %d x %d x %d\r\n    CTp: %s\r\n    FrF: %s\r\n    EcO: %s %s%s" % (os.path.basename(filename), width, height, bitdepth, colortype_string(colortype), format_string(format), encoder_wgt, encoder_bpp, encoder_gmp)
    cmd = "%s -e PVRTC %s %s%s -o %s -f Raw %s" % (txtr_tool, encoder_wgt, encoder_bpp, encoder_gmp, intmd_file, filename)
    retVal = os.system(cmd)
    if retVal != 0:
        raise RuntimeError("Failure executing command '%s': Failed return value %d." % (cmd, retVal))
    fin = open(intmd_file, 'rb')
    data = fin.read()
    fin.close()
    if not len(data):
        raise RuntimeError("Failure executing command '%s': Empty output container." % (cmd,))
    fout = open(filename_mod, 'wb')
    fout.write("GWPVRTC1") # revision 1
    fout.write(struct.pack("%sH" % (endian_out,), width))
    fout.write(struct.pack("%sL" % (endian_out,), format))
    fout.write(struct.pack("%sL" % (endian_out,), len(data)))
    fout.write(data)
    fout.close()

def walkpaths(loc):
    if os.path.exists(loc):
        if os.path.isdir(loc):
            contents = os.listdir(loc)
            for item in contents:
                if recursive and os.path.isdir(os.path.join(loc, item)):
                    walkpaths(os.path.join(loc, item))
                elif os.path.isfile(os.path.join(loc, item)):
                    walkpaths(os.path.join(loc, item))
        elif os.path.isfile(loc) and in_search_list(loc) and not in_ignore_list(loc):
            filename = os.path.realpath(loc)
            filename_mod = filename[:filename.rfind('.')] + r'.pvrtc'
            if check_date and os.path.exists(filename) and os.path.exists(filename_mod) and os.path.getmtime(filename_mod) >= os.path.getmtime(filename):
                print "Info: GWPVRTC_Convert: File '%s' is already up to date.\r\n" % (filename_mod,)
            else:
                print "Info: GWPVRTC_Convert: Beginning conversion of '%s' (%d bytes)." % (filename, os.path.getsize(filename))
                try:
                    if dlt_b4_wrt and os.path.exists(filename_mod): # delete file before writing
                        os.remove(filename_mod)
                    if loc[loc.rfind(r'.'):].lower() == r'.png':
                        convert_png(filename, filename_mod)
                    else:
                        raise NotImplementedError("File format not supported.")
                except:
                    print "Info: GWPVRTC_Convert: Failure converting '%s' due to exception: '%s'.\r\n" % (filename, sys.exc_info())
                else:
                    if os.path.exists(filename_mod) and os.path.getmtime(filename_mod) >= os.path.getmtime(filename):
                        print "Info: GWPVRTC_Convert: Successful conversion to '%s' (%d bytes).\r\n" % (filename_mod, os.path.getsize(filename_mod))
                    else:
                        print "Info: GWPVRTC_Convert: Failure converting '%s' due to improper output file.\r\n" % (filename,)

try:
    if os.path.exists(txtr_tool) and os.path.isfile(txtr_tool):
        path = dconv_path
        for arg in sys.argv:
            if arg[-3:].lower() != r'.py':
                if arg[:1] == r'-':
                    for i in range(1, len(arg)):
                        if arg[i].lower() == r'-':
                            continue
                        elif arg[i].lower() == r'f': # Forced operation (skip date check)
                            check_date = 0
                        elif arg[i].lower() == r'd': # Delete out file before write (for safety)
                            dlt_b4_wrt = 1
                        elif arg[i].lower() == r'r': # Recursively scan URL for supported file types
                            recursive = 1
                        elif arg[i].lower() == r'2': # Use 2 bpp encoding mode
                            encoder_bpp = encoder_bpp2
                        elif arg[i].lower() == r'4': # Use 4 bpp encoding mode
                            encoder_bpp = encoder_bpp4
                        elif arg[i].lower() == r'l': # Use linear approximiation encoding mode
                            encoder_wgt = encoder_wlin
                        elif arg[i].lower() == r'p': # Use perceptual approximation encoding mode
                            encoder_wgt = encoder_wprc
                        elif arg[i].lower() == r'm': # Generate pre-built mipmaps encoding mode
                            encoder_gmp = ' -m'
                        else:
                            print_help = 1
                            if not (arg[i].lower() == r'h' or arg[i].lower() == r'?'): # Print this help screen (skips conversion)
                                print "Info: GWPVRTC_Convert: Command line argument '%s' not supported.\r\n" % (arg[i],)
                            break
                elif os.path.exists(arg):
                    path = arg
        if not len(encoder_wgt):
            encoder_wgt = encoder_wlin # default, from doc
        if not len(encoder_bpp):
            encoder_bpp = encoder_bpp4 # default, from doc
        if not print_help:
            walkpaths(path)
    else:
        raise SystemError("Texture tool not found at specified location '%s'." % (txtr_tool,))
except:
    print "Info: GWPVRTC_Convert: Fatal Error: Unexpected exception: '%s'.\r\n" % (sys.exc_info(),)
    raise
if print_help:
    print "Info: GWPVRTC_Convert: Supported command line arguments:"
    print "    f : Forced operation (skip date check)"
    print "    d : Delete out file before write (for safety)"
    print "    r : Recursively scan URL for supported file types"
    print "    2 : Use 2 bpp encoding mode"
    print "    4 : Use 4 bpp encoding mode"
    print "    l : Use linear approximiation encoding mode"
    print "    p : Use perceptual approximation encoding mode"
    print "    m : Generate pre-built mipmaps encoding mode"
    print "  h/? : Print this help screen (skips conversion)\r\n"
try:
    if os.path.exists(intmd_file):
        os.remove(intmd_file)
except:
    pass
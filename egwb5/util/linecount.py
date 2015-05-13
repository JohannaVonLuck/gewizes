#!/usr/bin/env python

__author__ = "Johanna Wolf"
__url__ = ("http://gewizes.sourceforge.net/")
__version__ = "1.0"
__email__ = "johanna.a.wolf@gmail.com"
__doc__ = """\
Description: Calls wc -l on fies found from path walk with extensions matching search_list but not containing anything in ignore_list.
Usage: ./linecount.py [folder|file]*.
"""

import sys
import os

search_list = [r'.h', r'.m', r'.py', r'.gamx']
ignore_list = [r'.svn', r'build', r'.xcode', r'.DS_Store', r'GNUstep']

def in_search_list(loc):
    for item in search_list:
        if loc[-len(item):].lower() == item.lower():
            return 1
    return 0

def in_ignore_list(loc):
    for item in ignore_list:
        if loc.lower().find(item.lower()) != -1:
            return 1
    return 0

def walkpaths(loc):
    retval = ""
    if os.path.exists(loc):
        if os.path.isdir(loc):
            contents = os.listdir(loc)
            for item in contents:
                if os.path.isdir(os.path.join(loc, item)) and not in_ignore_list(loc):
                    retval += walkpaths(os.path.join(loc, item))
                elif os.path.isfile(os.path.join(loc, item)):
                    retval += walkpaths(os.path.join(loc, item))
        elif os.path.isfile(loc) and in_search_list(loc) and not in_ignore_list(loc):
            retval += " " + os.path.realpath(loc)
    return retval

items = ""
if len(sys.argv) == 1:
    items = walkpaths(".")
else:
    for arg in sys.argv:
        if arg != sys.argv[0]:
            items += walkpaths(arg)
if len(items):
    os.system("wc -l" + items)

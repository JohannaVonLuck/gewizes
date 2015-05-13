#!/usr/bin/env python

import sys
import os
import os.path
import stat

devPrefixes = ["iPhoneSimulator", "iPhoneOS"]
verSuffixes = ["4.2", "4.3", "4.3.1", "4.3.2"]
gitDepsLocation = "git://gewizes.git.sourceforge.net/gitroot/gewizes/gewizes/deps/"
gitBuildDepsDfltLocation = {
    "Desktop": "prebuilt/Desktop10.6",
    "iPhoneSimulator": "prebuilt/iPhoneSim4.2",
    "iPhoneOS": "prebuilt/iPhoneDev4.2" }
gitBuildDepsSpecLocation = {
    "Desktop10.6": "prebuilt/Desktop10.6",
    "iPhoneSimulator4.2": "prebuilt/iPhoneSim4.2",
    "iPhoneOS4.2": "prebuilt/iPhoneDev4.2" }
egwFolder = os.getcwd()
egwFolderALocation = {
    "Desktop": "build/desktop/",
    "iPhoneSimulator": "build/iphonesimulator/",
    "iPhoneOS": "build/iphoneos/" }
doFullReinstall = False

print "This setup script will direct setup to install EGW dependencies in /Developer/."
print ""
print "Some of these commands need sudo, so your system password may be prompted for."
print ""
print "This setup script should be ran from the master EGW directory. Your CWD is:"
print egwFolder

if os.path.exists(os.path.join(egwFolder, "geWizES.h")):
    print "Is this folder correct? (y/n)"
    answer = raw_input(">")

    if answer == "y" or answer == "Y":
        print "Do you want to do a full reinstall? (y/n)"
        answer = raw_input(">")
        
        if answer == "y" or answer == "Y":
            doFullReinstall = True
        
        print ""
        print "Starting..."
        print ""
        for devPrefix in devPrefixes:
            for verSuffix in verSuffixes:
                usrPath = "/Developer/Platforms/%s.platform/Developer/SDKs/%s%s.sdk/usr" % (devPrefix, devPrefix, verSuffix)
                if os.path.exists(usrPath):
                    if gitBuildDepsSpecLocation.has_key("%s%s" % (devPrefix, verSuffix)):
                        gitDepsLocSuffix = gitBuildDepsSpecLocation["%s%s" % (devPrefix, verSuffix)]
                    else:
                        gitDepsLocSuffix = gitBuildDepsDfltLocation[devPrefix]
                    gitDepsLoc = os.path.join(gitDepsLocation, gitDepsLocSuffix)
                    aLoc = os.path.join(os.path.join(egwFolder, egwFolderALocation[devPrefix]), "libegw.a")
                    print "Found %s%s in /Developer/, checking..." % (devPrefix, verSuffix)
                    
                    # Make sure the build la exists
                    if not os.path.exists(os.path.join(egwFolder, "build")):
                        print "    Making CWD/build/ folder"
                        os.system("mkdir %s" % (os.path.join(egwFolder, "build")))
                    if not os.path.exists(os.path.join(egwFolder, egwFolderALocation[devPrefix])):
                        print "    Making CWD/%s folder" % (egwFolderALocation[devPrefix])
                        os.system("mkdir %s" % (os.path.join(egwFolder, egwFolderALocation[devPrefix])))
                    if not os.path.exists(aLoc):
                        print "    Creating CWD/%s file" % (os.path.join(egwFolderALocation[devPrefix], "libegw.a"))
                        os.system("touch %s" % (aLoc));
                    
                    # Link the include/geWizES back to CWD and lib/libegw.a back to CWD/build/X/libegw.a
                    if doFullReinstall and os.path.exists(os.path.join(usrPath, "include/geWizES")):
                        os.system("sudo rm %s" % (os.path.join(usrPath, "include/geWizES")))
                    if not os.path.exists(os.path.join(usrPath, "include/geWizES")):
                        print "    Linking CWD to include/geWizES"
                        os.system("sudo ln -s %s %s" % (egwFolder, os.path.join(usrPath, "include/geWizES")))
                    if (doFullReinstall and os.path.exists(os.path.join(usrPath, "lib/libegw.a"))) or (os.path.exists(os.path.join(usrPath, "lib/libegw.a")) and not os.path.exists(os.readlink(os.path.join(usrPath, "lib/libegw.a")))):
                        os.system("sudo rm %s" % (os.path.join(usrPath, "lib/libegw.a")))
                    if not os.path.exists(os.path.join(usrPath, "lib/libegw.a")):
                        print "    Linking CWD/%s to lib/libegw.a" % (os.path.join(egwFolderALocation[devPrefix], "libegw.a"))
                        os.system("sudo ln -s %s %s" % (aLoc, os.path.join(usrPath, "lib/libegw.a")))
                    
                    # Ensure the include/ & lib/ deps are present
                    if doFullReinstall and os.path.exists(os.path.join(usrPath, "include/png.h")):
                        os.system("sudo rm %s" % (os.path.join(usrPath, "include/png.h")))
                    if doFullReinstall and os.path.exists(os.path.join(usrPath, "include/pngconf.h")):
                        os.system("sudo rm %s" % (os.path.join(usrPath, "include/pngconf.h")))
                    if doFullReinstall and os.path.exists(os.path.join(usrPath, "include/vorbis")):
                        os.system("sudo rm %s" % (os.path.join(usrPath, "include/vorbis/*")))
                        os.system("sudo rmdir %s" % (os.path.join(usrPath, "include/vorbis")))
                    if doFullReinstall and os.path.exists(os.path.join(usrPath, "include/freetype")):
                        if os.path.exists(os.path.join(usrPath, "include/freetype/cache")):
                            os.system("sudo rm %s" % (os.path.join(usrPath, "include/freetype/cache/*")))
                            os.system("sudo rmdir %s" % (os.path.join(usrPath, "include/freetype/cache")))
                        if os.path.exists(os.path.join(usrPath, "include/freetype/config")):
                            os.system("sudo rm %s" % (os.path.join(usrPath, "include/freetype/config/*")))
                            os.system("sudo rmdir %s" % (os.path.join(usrPath, "include/freetype/config")))
                        if os.path.exists(os.path.join(usrPath, "include/freetype/internal")):
                            if os.path.exists(os.path.join(usrPath, "include/freetype/internal/services")):
                                os.system("sudo rm %s" % (os.path.join(usrPath, "include/freetype/internal/services/*")))
                                os.system("sudo rmdir %s" % (os.path.join(usrPath, "include/freetype/internal/services")))
                            os.system("sudo rm %s" % (os.path.join(usrPath, "include/freetype/internal/*")))
                            os.system("sudo rmdir %s" % (os.path.join(usrPath, "include/freetype/internal")))
                        os.system("sudo rm %s" % (os.path.join(usrPath, "include/freetype/*")))
                        os.system("sudo rmdir %s" % (os.path.join(usrPath, "include/freetype")))
                    if not os.path.exists(os.path.join(usrPath, "include/png.h")) or not os.path.exists(os.path.join(usrPath, "include/pngconf.h")) or not os.path.exists(os.path.join(usrPath, "include/vorbis")) or not os.path.exists(os.path.join(usrPath, "include/freetype")):
                        print "    Exporting git deps %s to include/" % (os.path.join(gitDepsLocSuffix,"include/"))
                        os.system("sudo git archive master --remote=%s | tar -x -C %s" % (os.path.join(gitDepsLoc, "include"), os.path.join(usrPath, "include/")))
                    if doFullReinstall and os.path.exists(os.path.join(usrPath, "lib/libfreetype.a")):
                        os.system("sudo rm %s" % (os.path.join(usrPath, "lib/libfreetype.a")))
                    if doFullReinstall and os.path.exists(os.path.join(usrPath, "lib/libpng.a")):
                        os.system("sudo rm %s" % (os.path.join(usrPath, "lib/libpng.a")))
                    if doFullReinstall and os.path.exists(os.path.join(usrPath, "lib/libvorbisidec.a")):
                        os.system("sudo rm %s" % (os.path.join(usrPath, "lib/libvorbisidec.a")))
                    if not os.path.exists(os.path.join(usrPath, "lib/libfreetype.a")) or not os.path.exists(os.path.join(usrPath, "lib/libpng.a")) or not os.path.exists(os.path.join(usrPath, "lib/libvorbisidec.a")):
                        print "    Exporting git deps %s to lib/" % (os.path.join(gitDepsLocSuffix,"lib/"))
                        os.system("sudo git archive master --remote=%s | tar -x -C %s" % (os.path.join(gitDepsLoc, "lib"), os.path.join(usrPath, "lib/")))
                    
                    # Check for some various nasties, like missing include/libxml and lib/crt1.10.6.o
                    if doFullReinstall and os.path.exists(os.path.join(usrPath, "include/libxml")) and os.lstat(os.path.join(usrPath, "include/libxml"))[stat.ST_MODE] & stat.S_IFLNK == stat.S_IFLNK:
                        os.system("sudo rm %s" % (os.path.join(usrPath, "include/libxml")))
                    if os.path.exists(os.path.join(usrPath, "include/libxml2/libxml")) and not os.path.exists(os.path.join(usrPath, "include/libxml")):
                        print "    Linking include/libxml2/libxml to include/libxml"
                        os.system("sudo ln -s %s %s" % (os.path.join(usrPath, "include/libxml2/libxml"), os.path.join(usrPath, "include/libxml")))
                    if doFullReinstall and os.path.exists(os.path.join(usrPath, "lib/crt1.10.6.o")) and os.lstat(os.path.join(usrPath, "lib/crt1.10.6.o"))[stat.ST_MODE] & stat.S_IFLNK == stat.S_IFLNK:
                        os.system("sudo rm %s" % (os.path.join(usrPath, "lib/crt1.10.6.o")))
                    if os.path.exists(os.path.join(usrPath, "lib/crt1.10.5.o")) and not os.path.exists(os.path.join(usrPath, "lib/crt1.10.6.o")):
                        print "    Linking lib/crt1.10.5.o to lib/crt1.10.6.o"
                        os.system("sudo ln -s %s %s" % (os.path.join(usrPath, "lib/crt1.10.5.o"), os.path.join(usrPath, "lib/crt1.10.6.o")))
                else:
                    print "Did not find %s%s in /Developer/, skipping..." % (devPrefix, verSuffix)
    else:
        print "Then cd over to the correct folder and run this script again."
else:
    print "The script did not detect the master geWizES.h include file in this folder. Please cd over to the correct folder and run this script again."
#!/bin/bash
#
# Author:	Roland Kunkel
# Edited:	Oliver Nelson
# Date: 	8-12-14 -- RK
#		10-15-14 -- ON

# Purpose:	
#
#		To pull needed Flame builds and place them in the correct directories

# Updating:
#
#		2014-09-03 # Added OMC for old master set it to 2.1
#                          # Changed MC to point to 2.2 lastest nightly
#               2014-09-15 # Added get pull for flame.zip, this includes the full flash
#               2014-09-16 # pull for flame is breaking everything... removed for now
#               2014-09-19 # updated to pull KK builds down
#			   # correctly pulls flame image down now
#               2014-09-22 # b2g-distro was not being deleted after pull, updated to fix error
#               2014-09-23 # .config from the flame.zip is not being pulled properly, commenting out that code
#                          # changed the naming convention for flame KK builds
#               2014-09-25 # .config is now being pulled properly
#                          # I am now pulling down the sources.xml
#                          # pulling down nightly flame KK builds now
#                          # no longer pulling down regular nightly builds down
#                          # I am now pulling boot.img and replacing the borked one located in the pulled flame-kk.zip
#                          # cleaned up my varibles to reduce total number
#                          # changed file structure so that we can have an assets folder in needed_scripts for solidarity
#                          # now pulls '/mnt/builds/Needed_Scripts/flash_Gg.sh' flash script 
#               2014-09-26 # now pulls latest 2.0 KK builds
#               2014-09-26 # no longer re-naming the b2g-folder, trade off BugGUI no longer supports pulling
                           # from the directory for 1.4 prior
#		2014-10-15 # added support for pulling new 2.1 branch [b2g-34]
#		2014-10-18 # added function to reduce redundant calls
#		2014-10-19 # added framework for looping through builds [WIP]
		

### Variables
# Security 
USER='bzumwalt@qanalydocs.com'
PASS='w4tNTCGUmVyFkLfB'

# Generic
BUILDID=''
GAIA='gaia.zip'
IMAGE='flame-kk.zip'
SOURCES='sources.xml'
BOOT_IMAGE='/mnt/builds/Needed_Scripts/Assets/boot.img'
FLASH_SCRIPT='/mnt/builds/Needed_Scripts/flash_Gg.sh'

# MC_KK 2.2
MC_KK_PATH='https://pvtbuilds.mozilla.org/pvt/mozilla.org/b2gotoro/nightly/mozilla-central-flame-kk/latest/'
MC_KK_B2G='b2g-36.0a1.en-US.android-arm.tar.gz'
MC_KK_DIR='/mnt/builds/Flame/Flame_KK/2.2/Central' #'$HOME/Desktop/oliverthor/builds/2.2'

# OMC_KK 2.1
OMC_KK_PATH='https://pvtbuilds.mozilla.org/pvt/mozilla.org/b2gotoro/nightly/mozilla-aurora-flame-kk/latest/'
OMC_KK_B2G='b2g-34.0a2.en-US.android-arm.tar.gz'
OMC_KK_DIR='/mnt/builds/Flame/Flame_KK/2.1' #'$HOME/Desktop/oliverthor/builds/2.1/aurora'

# B2G-34 2.1 as of 10/10
B2G34_KK_PATH='https://pvtbuilds.mozilla.org/pvt/mozilla.org/b2gotoro/nightly/mozilla-b2g34_v2_1-flame-kk/latest/'
B2G34_KK_B2G='b2g-34.0.en-US.android-arm.tar.gz'
B2G34_KK_DIR='/mnt/builds/Flame/Flame_KK/2.1/b2g-34' #'$HOME/Desktop/oliverthor/builds/2.1/b2g-34' 

# LC_KK 2.0
LC_KK_PATH='https://pvtbuilds.mozilla.org/pvt/mozilla.org/b2gotoro/nightly/mozilla-b2g32_v2_0-flame-kk/latest/'
LC_KK_B2G='b2g-32.0.en-US.android-arm.tar.gz'
LC_KK_DIR='/mnt/builds/Flame/Flame_KK/2.0' #'$HOME/Desktop/oliverthor/builds/2.0' 

# Build Path Container
#BUILD_PATHS[0]=	$MC_KK_PATH
#BUILD_B2GS[0]= 	$MC_KK_B2G
#BUILD_DIRS[0]=	$MC_KK_DIR	

#BUILD_PATHS[1]=	$OMC_KK_PATH
#BUILD_B2GS[1]=	$OMC_KK_B2G
#BUILD_DIRS[1]=	$OMC_KK_DIR

#BUILD_PATHS[2]=	$B2G34_KK_PATH
#BUILD_B2GS[2]=	$B2G34_KK_B2G
#BUILD_DIRS[2]=	$B2G34_KK_DIR

#BUILD_PATHS[3]=	$LC_KK_PATH
#BUILD_B2GS[3]=	$LC_KK_PATH
#BUILD_DIRS[3]=	$LC_KK_DIR

### Functions
# Get file
function get_file() {
  curl --anyauth -L -u $USER:$PASS $1/$2 -o $2
}

# Get tar files 
function get_tar() {
  curl --anyauth -L -u $USER:$PASS $1/$2 -o $2
  tar -zxf $2
}

# Get zip files
function get_zip() {
  curl --anyauth -L -u $USER:$PASS $1/$2 -o $2
  unzip -q $2
}

# Pull all Build files
function assemble_build() {
 #$1 = $BUILD_KK_PATH
 #$2 = $BUILD_KK_B2G
  get_tar $1 $2
  get_zip $1 $GAIA
  get_zip $1 $IMAGE
  get_file $1 $SOURCES
  create_name
  clean_kk $2 $GAIA $IMAGE $SOURCES
}

# Create proper name
function create_name() {
  for a in BuildID; do
    BUILDID=$(grep "^ *$a" "b2g/application.ini" | sed "s,.*=,,g")
  done
}

function clean_kk() {
  echo "Cleaning..."
  DIRNAME=$(echo $BUILDID)
  mkdir $DIRNAME
  mv 'b2g' $DIRNAME
  mv 'gaia' $DIRNAME
  cp -r 'b2g-distro' $DIRNAME
  #mv $DIRNAME'/b2g-distro' $DIRNAME'/fullflash' # gg script does not support renaming the b2g-distro
  mv $4 $DIRNAME
  rm $1
  rm $2
  rm $3
  rm -rf b2g-distro/

  # replace old boot
  cp $BOOT_IMAGE $DIRNAME'/b2g-distro/out/target/product/flame'
  # add flash script
  cp $FLASH_SCRIPT $DIRNAME
}

### Main

# Timer
runTime=$(date +"%s")

# Assemble Build Loop
# get the length of the arrays
#length=${#BUILD_PATHS[@]}
# do the loop
#for ((i=0;i<1;i++)); do
	#echo ${BUILD_DIRS[i]}
	#cd ${BUILD_DIRS[i]}
	#assemble_build ${BUILD_PATH[i]} ${BUILD_B2GS[i]}
#done

# Mozilla Master Central KK
cd '/mnt/builds/Flame/Flame_KK/2.2/Central'
echo "Starting KK v2.2"
assemble_build $MC_KK_PATH $MC_KK_B2G
# check for current build in latest
# if outdated, move latest out and pull newest in


# Mozilla b2g-32 KK
cd '/mnt/builds/Flame/Flame_KK/2.0'
echo "Starting KK v2.0"
assemble_build $LC_KK_PATH $LC_KK_B2G

# Mozilla b2g-34 KK -- 2.1
cd '/mnt/builds/Flame/Flame_KK/2.1/b2g-34'
echo "Starting KK v2.1 -- b2g-34"
assemble_build $B2G34_KK_PATH $B2G34_KK_B2G


# End Timer
currTime=$(date +"%s")
diff=$(($currTime-$runTime))
TIME_ELAPSED="$(($diff / 60)) minutes and $(($diff % 60)) seconds elapsed."
echo "$(($diff / 60)) minutes and $(($diff % 60)) seconds elapsed."


#!/bin/bash
#
# Author:	Roland Kunkel
# Date: 	8-12-14

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
		

### Variables
# Security 
USER='rkunkel@qanalydocs.com'
PASS='brwVkDDfEWMdWUHu'

# Generic
BUILDID=''
GAIA='gaia.zip'
IMAGE='flame-kk.zip'
SOURCES='sources.xml'
BOOT_IMAGE='/mnt/builds/Needed_Scripts/Assets/boot.img'
FLASH_SCRIPT='/mnt/builds/Needed_Scripts/flash_Gg.sh'

# MC_KK 2.2
MC_KK_PATH='https://pvtbuilds.mozilla.org/pvt/mozilla.org/b2gotoro/nightly/mozilla-central-flame-kk/latest/'
MC_KK_B2G='b2g-35.0a1.en-US.android-arm.tar.gz'

# OMC_KK 2.1
OMC_KK_PATH='https://pvtbuilds.mozilla.org/pvt/mozilla.org/b2gotoro/nightly/mozilla-aurora-flame-kk/latest/'
OMC_KK_B2G='b2g-34.0a2.en-US.android-arm.tar.gz'

# LC_KK 2.0
LC_KK_PATH='https://pvtbuilds.mozilla.org/pvt/mozilla.org/b2gotoro/nightly/mozilla-b2g32_v2_0-flame-kk/latest/'
LC_KK_B2G='b2g-32.0.en-US.android-arm.tar.gz'

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

# Mozila Master Central KK 
cd '/mnt/builds/Flame/Flame_KK/2.2'
echo "Starting KK v2.2"
get_tar $MC_KK_PATH $MC_KK_B2G
get_zip $MC_KK_PATH $GAIA
get_zip $MC_KK_PATH $IMAGE
get_file $MC_KK_PATH $SOURCES
create_name
clean_kk $MC_KK_B2G $GAIA $IMAGE $SOURCES

# Mozila Aurora KK 
cd '/mnt/builds/Flame/Flame_KK/2.1'
echo "Starting KK v2.1"
get_tar $OMC_KK_PATH $OMC_KK_B2G
get_zip $OMC_KK_PATH $GAIA
get_zip $OMC_KK_PATH $IMAGE
get_file $OMC_KK_PATH $SOURCES
create_name
clean_kk $OMC_KK_B2G $GAIA $IMAGE $SOURCES

# Mozila b2g-32 KK 
cd '/mnt/builds/Flame/Flame_KK/2.0'
echo "Starting KK v2.0"
get_tar $LC_KK_PATH $LC_KK_B2G
get_zip $LC_KK_PATH $GAIA
get_zip $LC_KK_PATH $IMAGE
get_file $LC_KK_PATH $SOURCES
create_name
clean_kk $LC_KK_B2G $GAIA $IMAGE $SOURCES

# End Timer
currTime=$(date +"%s")
diff=$(($currTime-$runTime))
TIME_ELAPSED="$(($diff / 60)) minutes and $(($diff % 60)) seconds elapsed."
echo "$(($diff / 60)) minutes and $(($diff % 60)) seconds elapsed."


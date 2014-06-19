#!/bin/bash

DEBUG=0
DROP_DIR1=$1
DROP_DIR2=$2
SAVE_DIR=~/Desktop/gecko_gaia_split
FLAG=$3

if [ -z $FLAG ]; then
  FLAG=0
fi

####################################################################
#------------CHANGE THIS TO POINT TO LATEST FLASH FILES-------------#
LATEST_FLASH='/mnt/builds/Needed_Scripts/flash_Gg_de.sh' 
NEW_FLAGS="-dn"
# Usage:  gg '/path/to/build/dir/'

OLD_FLASH='/mnt/builds/Needed_Scripts/fullflash_gecko_ril_gaia.sh'
OLD_FLAGS="-rn"
# Usage:  gg '/path/to/build/dir/' 1
####################################################################


function Check_GG {
Debug "Check_GG"
Remount
  if [ -e $FLASH_FILE_NAME_ONLY ]; then
    echo -e "${LGREEN}$FLASH_FILE_NAME_ONLY found. No need to copy.${RESTORE}"
  else  
    if [ -e $FLASH_FILE_FULL_PATH ]; then
      echo -e "${LGREEN}Found $FLASH_FILE_NAME_ONLY in $FLASH_FILE_DIR_ONLY.${RESTORE}"
      cp $FLASH_FILE_FULL_PATH .
    else
        echo -e "${LRED}Cannot find $FLASH_FILE_NAME_ONLY! Aborting!${RESTORE}"
        exit 1
    fi  
  fi


}

function Check_Validity {
Debug "Check_Validity"

  if [ -z $DROP_DIR1 ]; then
    echo "No path specified"
    echo "Usage: bsplit /path/to/build/older_build/ /path/to/build/newer_build/"
    exit 1
  fi
  if [ -z $DROP_DIR2 ]; then
    echo "No path specified"
    echo "Usage: bsplit /path/to/build/older_build/ /path/to/build/newer_build/"
    exit 1
  fi
  if [ ! -e $DROP_DIR1 ]; then
    echo "Invalid path"
    echo "Usage: bsplit /path/to/build/older_build/ /path/to/build/newer_build/"
    exit 1
  fi
  if [ ! -e $DROP_DIR2 ]; then
    echo "Invalid path"
    echo "Usage: bsplit /path/to/build/older_build/ /path/to/build/newer_build/"
    exit 1
  fi
  
    if [ $FLAG -eq 1 ]; then
    if [ -e $OLD_FLASH ]; then
      FLASH_FILE_FULL_PATH=$OLD_FLASH
      USE_FLAGS=$OLD_FLAGS
      echo -e "${LBLUE}Using $OLD_FLASH $USE_FLAGS ${RESTORE}"
    else
      echo -e "${LRED} Invalid OLD_FLASH specified.\n$OLD_FLASH does not exist!\nEdit gg.sh to update the location.${RESTORE}"
      exit 1
    fi
  else
    if [ -e $LATEST_FLASH ]; then
      FLASH_FILE_FULL_PATH=$LATEST_FLASH
      USE_FLAGS=$NEW_FLAGS
      echo -e "${LBLUE}Using $LATEST_FLASH $USE_FLAGS ${RESTORE}"
    else
      echo -e "${LRED} Invalid LATEST_FLASH specified.\n$LATEST_FLASH does not exist!\nEdit gg.sh to update the location.${RESTORE}"
      exit 1
    fi
  fi
  FLASH_FILE_DIR_ONLY="${FLASH_FILE_FULL_PATH%/*}"
  FLASH_FILE_NAME_ONLY="${FLASH_FILE_FULL_PATH##*/}"
}

function Color_Init {
#Debug "Color_Init"
RESTORE='\033[0m'

RED='\033[00;31m'
GREEN='\033[00;32m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
PURPLE='\033[00;35m'
CYAN='\033[00;36m'

LGRAY='\033[00;37m'
LRED='\033[01;31m'
LGREEN='\033[01;32m'
LYELLOW='\033[01;33m'
LBLUE='\033[01;34m'
LPURPLE='\033[01;35m'
LCYAN='\033[01;36m'
WHITE='\033[01;37m'

#echo -e "${GREEN}Hello ${CYAN}THERE${RESTORE} "
}

function Debug {
if [ $DEBUG -eq 1 ]; then
  echo -e "DEBUG: ${LGRAY}$1${RESTORE}"
fi
}

function Check_Dir { 
Debug "Check_Dir"

  if [ -e $DROP_DIR1/b2g-distro/ ]; then
    DIR1=$DROP_DIR1/b2g-distro/
  else
    if [ -e $DROP_DIR1 ]; then
    DIR1=$DROP_DIR1
    else
      echo "bad DROP_DIR1: $DROP_DIR1"
    fi
  fi
    if [ -e $DROP_DIR2/b2g-distro/ ]; then
    DIR2=$DROP_DIR2/b2g-distro/
  else
    if [ -e $DROP_DIR2 ]; then
    DIR2=$DROP_DIR2
    else
      echo "bad DROP_DIR2: $DROP_DIR2"
    fi
  fi

}

function Check_For_Extractables {
Debug "Check_For_Extractables"
cd $DIR1

  if [ -e gaia.zip ]; then
    echo "Found gaia, extracting..."
    unzip -o -u gaia.zip &> /dev/null
  fi

  if [ -e b2g*.tar.gz ]; then
  echo "Found gecko, extracting...."
    tar -xzvf b2g*.tar.gz &> /dev/null
  fi
cd $DIR2

  if [ -e gaia.zip ]; then
    echo "Found gaia, extracting..."
    unzip -o -u gaia.zip &> /dev/null
  fi

  if [ -e b2g*.tar.gz ]; then
  echo "Found gecko, extracting...."
    tar -xzvf b2g*.tar.gz &> /dev/null
  fi
}

function Split {

OLD_GAIA_NEW_GECKO="Last_Working_Gaia_First_Broken_Gecko"
OLD_GECKO_NEW_GAIA="First_Broken_Gaia_Last_Working_Gecko"

Debug "Split"
if [ ! -e $SAVE_DIR ]; then
  mkdir $SAVE_DIR
fi

if [ ! -e $SAVE_DIR/$OLD_GAIA_NEW_GECKO/ ]; then
  mkdir $SAVE_DIR/$OLD_GAIA_NEW_GECKO/
else
  rm -r $SAVE_DIR/$OLD_GAIA_NEW_GECKO/
  mkdir $SAVE_DIR/$OLD_GAIA_NEW_GECKO/
fi

if [ ! -e $SAVE_DIR/$OLD_GECKO_NEW_GAIA/ ]; then
  mkdir $SAVE_DIR/$OLD_GECKO_NEW_GAIA/
else
  rm -r $SAVE_DIR/$OLD_GECKO_NEW_GAIA/ 
  mkdir $SAVE_DIR/$OLD_GECKO_NEW_GAIA/ 
fi


echo "Swapping gaia and gecko and making two new builds..."
cp -r $DIR1/gaia $SAVE_DIR/$OLD_GAIA_NEW_GECKO/ &
cp -r $DIR1/b2g $SAVE_DIR/$OLD_GECKO_NEW_GAIA/ &
cp -r $DIR2/gaia $SAVE_DIR/$OLD_GECKO_NEW_GAIA/ &
cp -r $DIR2/b2g $SAVE_DIR/$OLD_GAIA_NEW_GECKO/
clear
echo "Done. The builds are made and in $SAVE_DIR"
}

function Get_New_Vars {
  Debug "Get_New_Vars"
  if [ ! -e $SAVE_DIR/temp_new/ ]; then
    mkdir $SAVE_DIR/temp_new/
  else
    rm -r $SAVE_DIR/temp_new/
    mkdir $SAVE_DIR/temp_new/
  fi
  Remount
  cd $SAVE_DIR/temp_new/
  adb pull /system/b2g/webapps/settings.gaiamobile.org/application.zip &> /dev/null || adb pull /data/local/webapps/settings.gaiamobile.org/application.zip &> /dev/null ||echo "Error pulling gaia file" &&
  adb pull /system/b2g/application.ini &> /dev/null || echo "Error pulling application.ini" &&
  unzip application.zip resources/gaia_commit.txt &> /dev/null

  OLD_GAIA=$(head -n 1 resources/gaia_commit.txt)
  for d in BuildID; do
    OLD_BUILDID=$(grep "^ *$d" application.ini | sed "s,.*=,,g")      
  done
  for c in SourceStamp; do
    OLD_GECKO=$(grep "^ *$c" application.ini | sed "s,.*=,,g")
  done
}

function Get_Old_Vars {
Debug "Get_Old_Vars"
  if [ ! -e $SAVE_DIR/temp_old/ ]; then
    mkdir $SAVE_DIR/temp_old/
  else
    rm -r $SAVE_DIR/temp_old/
    mkdir $SAVE_DIR/temp_old/
  fi
  Remount
  cd $SAVE_DIR/temp_old/
  adb pull /system/b2g/webapps/settings.gaiamobile.org/application.zip &> /dev/null || adb pull /data/local/webapps/settings.gaiamobile.org/application.zip &> /dev/null ||echo "Error pulling gaia file" &&
  adb pull /system/b2g/application.ini &> /dev/null || echo "Error pulling application.ini" &&
  unzip application.zip resources/gaia_commit.txt &> /dev/null

  OLD_GAIA=$(head -n 1 resources/gaia_commit.txt)
  for d in BuildID; do
    OLD_BUILDID=$(grep "^ *$d" application.ini | sed "s,.*=,,g")      
  done
  for c in SourceStamp; do
    OLD_GECKO=$(grep "^ *$c" application.ini | sed "s,.*=,,g")
  done
}

function Remount {
  set -e &&
  echo "Waiting for device. Make sure it is plugged in and ready." &&
  adb wait-for-device &&
  adb root &&
  adb remount &&
  echo "Found device"
}

function Check_Old_Gaia_New_Gecko {
Debug "Check_Old_Gaia_New_Gecko"
  echo "Checking Old gaia with new gecko"
  cd $SAVE_DIR/$OLD_GAIA_NEW_GECKO/
  Check_GG
  chmod +x ./$FLASH_FILE_NAME_ONLY
  echo "Flashing Old_Gaia_New_Gecko to device..."
  ./$FLASH_FILE_NAME_ONLY $USE_FLAGS && clear
  local LOOP=0
  echo "You may wish to restart the device once more to avoid lingering issues."
  echo "After this, check if the issue occurs with this build and reconnect the device"
  
  while [ $LOOP -eq 0 ]; do
    echo "Does the issue occur on this build? (y/n)"
    read CHOICE
    case $CHOICE in
    "y") BAD_GECKO=1 
         LOOP=1;;
    "Y") BAD_GECKO=1 
         LOOP=1;;
    "n") BAD_GECKO=0 
         LOOP=1;;
    "N") BAD_GECKO=0 
         LOOP=1;;
    *) echo "Please enter y or n";;
    esac
  done
  read -p "Make sure the device is attached and press enter when ready"
  
  Get_Old_Vars

}

function Check_New_Gaia_Old_Gecko {
Debug "Check_New_Gaia_Old_Gecko"
  echo "Checking New gaia with old gecko"
  cd $SAVE_DIR/$OLD_GECKO_NEW_GAIA/
  Check_GG
  chmod +x ./$FLASH_FILE_NAME_ONLY
  echo "Flashing New_Gaia_Old_Gecko to device..."
  ./$FLASH_FILE_NAME_ONLY $USE_FLAGS && clear
  local LOOP=0
  while [ $LOOP -eq 0 ]; do
    echo "Does the issue occur on this build? (y/n)"
    read CHOICE
    case $CHOICE in
    "y") BAD_GAIA=1 
         LOOP=1;;
    "Y") BAD_GAIA=1 
         LOOP=1;;
    "n") BAD_GAIA=0 
         LOOP=1;;
    "N") BAD_GAIA=0 
         LOOP=1;;
    *) echo "Please enter y or n";;
    esac 
  done
  read -p "Make sure the device is attached and press enter when ready"
  Get_New_Vars
}

function Advanced {

local LOOP=0
  while [ $LOOP -eq 0 ]; do
    echo "The builds are made and in $SAVE_DIR. Would you like to flash to the first one now? (y/n)"
    read CHOICE
    case $CHOICE in
    "y") BAD_GAIA=1 
         LOOP=1;;
    "Y") BAD_GAIA=1 
         LOOP=1;;
    "n") BAD_GAIA=0 
         echo "goodbye"
         exit 0
         LOOP=1;;
    "N") echo "goodbye"
         exit 0
         LOOP=1;;
    *) echo "Please enter y or n";;
    esac 
  done

}

function Results {
  clear
  Debug "Results"
  echo "RESULTS:"
  echo "(If both gaia and gecko are bad then you might want to try restarting the device after each flash to be completely sure)"
  if [ $BAD_GAIA -eq 1 ]; then
  echo "Gaia is bad"
  echo "https://github.com/mozilla-b2g/gaia/compare/$OLD_GAIA...$NEW_GAIA"
  fi
  if [ $BAD_GECKO -eq 1 ]; then
  echo "Gecko is bad"
  echo "http://hg.mozilla.org/mozilla-central/pushloghtml?fromchange=$OLD_GECKO&tochange=$NEW_GECKO"
  fi
  echo "Older build: $OLD_BUILDID"
  echo "Newer build: $NEW_BUILDID"
}



Color_Init
Check_Validity
#Remount
Check_Dir
Check_For_Extractables
Split
#Advanced
#Check_Old_Gaia_New_Gecko
#Check_New_Gaia_Old_Gecko
#Results

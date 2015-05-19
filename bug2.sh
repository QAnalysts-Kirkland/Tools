#!/bin/bash

###################################################################
# Author: Lionel Mauritson                                        
# Email: lionel@secretzone.org 
# Contributors: Jayme Mercado, Jamie Charlton
# Last updated: 05/19/2015  by Jamie Charlton
# Previous change: Added a note that the firmware version is not
# auto detected. Minor formatting changes.
# Last changes: Added the current firmware and updated the rest of
# the script to the best of my knowledge 

###################################################################

DEBUG=0


##########################Initialize###############################

function Init_Variables { #Initialise variables 
  Debug "Init_Variables"
  DISABLE_CLEAR=0
  HIDE_EDITOR=0
  USE_DIRECTORY=0
  QUICK=0
  DEVICE=""
  VERSION_2=""
  VERSION=""
  BUILD_ID=""
  GAIA=""
  GECKO=""
  GONK="I couldnt pull the gonk.  Did you shallow Flash again?"
  DETECTED_VERSION=""
  GUESSED_DEVICE=""
  GUESSED_VERSION=""
  FIRMWARE=""
  APP_INI=""
  APP_ZIP=""
  SKIP_REPORT=0
  SKIP_UA=0
  DIR=""
  SIMPLE=0
  Color_Init
  DEF="     ${LBLUE}<${RESTORE}"
  Pick_Text_App
  Create_Temp_Directory
  
  return 0
}

function Create_Temp_Directory { #Create a temporary place to store the files we pull / extract
  Debug "Create_Temp_Directory"
  TEMP_DIR=$(mktemp -d -t revision.XXXXXX) || DIE "${LRED}could not make temp directory${RESTORE}"
  Debug "TEMP_DIR: $TEMP_DIR"
 }

function Pick_Text_App { #Check if the user has scite, if not use gedit
  Debug "Pick_Text_App"
  TEXT_APP="gedit"
  command -v scite > /dev/null 2>&1 && 
  TEXT_APP="scite" || 
  TEXT_APP="gedit"
  
  return 0
}
function get_source {
echo "Made it into get_source"
  while read line           
  do           
    parse=$(echo $line | cut -c16-27)
    if [[ $parse ==  'device-flame' ]]; then
	echo "Made it into parse"
      GONK=$(echo $line | cut -c77-116)
      #echo -e $revision
    fi
  done <'sources'
}
function Color_Init { #Sets up color variables to use later
  
  Debug "Color_Init"
  
  #Restores colors back to default
  RESTORE='\033[0m'
  
  #Regular colors (Darker)
  RED='\033[00;31m'
  GREEN='\033[00;32m'
  YELLOW='\033[00;33m'
  BLUE='\033[00;34m'
  PURPLE='\033[00;35m'
  CYAN='\033[00;36m'
  
  #Light Colors
  LGRAY='\033[00;37m'
  LRED='\033[01;31m'
  LGREEN='\033[01;32m'
  LYELLOW='\033[01;33m'
  LBLUE='\033[01;34m'
  LPURPLE='\033[01;35m'
  LCYAN='\033[01;36m'
  WHITE='\033[01;37m'
  #echo -e "${GREEN}Hello ${CYAN}THERE${RESTORE} "
  return 0 # Success
}

function Get_Args { #Get flags for defining behavior
Debug "Get_Args"
  while getopts :tvd:qvgs opt; do
    case $opt in
    t) HIDE_EDITOR=1
    ;;
    d) USE_DIRECTORY=1
       DROP_DIR=${OPTARG}
    ;;
    q) QUICK=1
       SKIP_REPORT=1
    ;;
    v) DEBUG=1
       DISABLE_CLEAR=1
    ;;
    g) SIMPLE=1 #Only show gaia and gecko and don't clear the screen
       SKIP_REPORT=1
       DISABLE_CLEAR=1
       SKIP_UA=1
    ;;
    s) SKIP_UA=1
    ;;
    *) Show_Usage
    ;;
    esac
  done
  
}

function Do_Clear {
if [ $DISABLE_CLEAR -eq 0 ]; then
  clear
fi

}

function Choose_Work_Path { #Choose whether to get files from the device or from a folder

  Debug "Choose_Work_Path"
  if [ $USE_DIRECTORY -eq 1 ]; then
    Get_Vars_From_Folder
  else
    Get_Vars_From_Device
  fi
}

function Start_ADB { #Connects to the device
  Debug "Start_ADB"

  echo "Waiting for device" &&
  adb wait-for-device &&
  adb remount &&
  echo "Found device" &&
  return 0
}

###################################################################


#####################DEBUG & ERROR HANDLING########################
function DIE { #Call this when something bad happens to give the user more info about it
  Debug "DIE"
  if [ -n "$1" ]; then
    echo -e "${LRED}ERROR: $1${RESTORE}"
  fi
  exit 1
}

function Debug { #Call this and pass it a string to display extra information if DEBUG=1
  if [ $DEBUG -eq 1 ]; then
    echo -e "DEBUG: ${LGRAY}$1${RESTORE}"
  fi
  return 0
}

function Show_Usage { #Show info when user enters something wrong
Debug "Show_Usage"
echo "Bug script - pulls device variables from a device or directory
Usage:
./bug2.sh <optional flags>
Flags:
-t       :       Don't show the bug template
-d <dir> :       Get bug variables from a directory
-q       :       Quick (Auto select defaults if possible)
-v       :       Verbose (Shows debug progress messages)
-g       :       Show only gaia and gecko at the end"
DIE
}
###################################################################


########################FILE HANDLING##############################

function Find_Build_Location { #From the build given, determine where the actual build files are
  
  Debug "Find_Build_Location"

  DIR=""

  if [ -e $DROP_DIR/b2g-distro ]; then
    DIR=$DROP_DIR/b2g-distro
  fi

  if [ -e $DROP_DIR/gaia.zip ]; then
    DIR=$DROP_DIR
  fi

  if [ -e $DROP_DIR/b2g*.tar.gz ]; then
    DIR=$DROP_DIR
  fi
  
  if [ -e $DROP_DIR/b2g ]; then
    DIR=$DROP_DIR
  fi
  
  if [ -e $DROP_DIR/gaia ]; then
    DIR=$DROP_DIR
  fi
  
  if [ -e $DROP_DIR/gaia.zip ]; then
    DIR=$DROP_DIR
  fi
  
  if [ -e $DROP_DIR/b2g*tar.gz ]; then
    DIR=$DROP_DIR
  fi
  
  if [ -e $DROP_DIR/b2g-distro/gaia ]; then
    DIR=$DROP_DIR/b2g-distro
  fi
  
  if [ -e $DROP_DIR/b2g-distro/b2g ]; then
    DIR=$DROP_DIR/b2g-distro
  fi

  if [ -z $DIR ]; then
    DIE "Unable to determine build location"
  fi
  Debug "Dir: $DIR"
  cd $DIR
  return 0

}

function Pull_ApplicationZip_From_Device { #Pull application.zip from the device
  Debug "Pull_ApplicationZip_From_Device"
  cd $TEMP_DIR
  echo "adb pull application.zip" &&
  adb pull /system/b2g/webapps/settings.gaiamobile.org/application.zip $TEMP_DIR  || 
  adb pull /data/local/webapps/settings.gaiamobile.org/application.zip $TEMP_DIR  ||
  return 1 &&
  APP_ZIP=$TEMP_DIR/application.zip
  return 0
}

function Pull_ApplicationINI_From_Device { #Pull application.ini from the device
  Debug "Pull_ApplicationINI_From_Device"
  cd $TEMP_DIR
  echo "adb pull application.ini" &&
  adb pull /system/b2g/application.ini $TEMP_DIR  &&
  APP_INI=$TEMP_DIR/application.ini
  return 1 &&
  return 0
}

function Extract_Commitfile_From_GaiaZip { #Extract commitfile.txt from gaia.zip OR search for it in the build directory
Debug "Extract_Commitfile_From_GaiaZip"
echo -e "Using GaiaZip commit file"
    if [ -e $DIR/gaia.zip ]; then
    unzip -o -u $DIR/gaia.zip gaia/profile/webapps/settings.gaiamobile.org/application.zip -d $TEMP_DIR > /dev/null
    APP_ZIP=$TEMP_DIR/gaia/profile/webapps/settings.gaiamobile.org/application.zip 
    Debug "APP_INI: $APP_ZIP"
    return 0
  else
    if [ -e $DIR/gaia/profile/webapps/settings.gaiamobile.org/application.zip ]; then
      APP_ZIP=$DIR/gaia/profile/webapps/settings.gaiamobile.org/application.zip
    else
      GAIA="Unknown"
      return 1
    fi
  fi

}

function Get_Gaia_Version_From_Commitfile { #Read the gaia version from the commitfile.txt
  Debug "Get_Gaia_Version_From_Commitfile"
  Debug "APP_ZIP: $APP_ZIP"
  if [[ -e $APP_ZIP ]]; then
    unzip -FF $APP_ZIP resources/gaia_commit.txt -d $TEMP_DIR > /dev/null
    COMMIT_FILE=$TEMP_DIR/resources/gaia_commit.txt
    Debug "ls: $(ls)"
  else
    echo -e "Can't find application.zip: $APP_ZIP. \nCheck the directory / make sure the device is connected."
    APP_ZIP=""
  fi
  
  if [ ! -e $COMMIT_FILE ]; then
    echo "Unable to detect Gaia"
    GAIA="Unknown"
    return 1
  fi
    GAIA=$(head -n 1 $COMMIT_FILE )  &&
  if [ -z "$GAIA" ]; then
    GAIA="Unknown"
  fi
  return 0
}

function Extract_ApplicationINI_From_B2GTar { #Extract application.ini from the b2g*tar.gz

Debug "Extract_ApplicationINI_From_B2GTar"

  if [ -e $DIR/b2g*tar.gz ]; then
    TAR_LOC="$DIR/$(ls | grep tar.gz)"
    Debug "TAR_LOC: $TAR_LOC"
    
    cd $TEMP_DIR
    tar --extract --file=$TAR_LOC b2g/application.ini > /dev/null || Debug "Couldn't find b2g*tar.gz."
    #tar -zxvf $DIR/b2g*.tar.gz b2g/application.ini #$TEMP_DIR || Debug "Issue extracting b2g"
    cd $DIR
    
    if [ -e $TEMP_DIR/b2g/application.ini ]; then
      APP_INI=$TEMP_DIR/b2g/application.ini 
      return 0
    else
      APP_INI=""
    fi
  else
    APP_INI=""
  fi
  
  Debug  "Checking for b2g/application.ini"
  if [[ -e $DIR/b2g/application.ini ]]; then
    APP_INI=$DIR/b2g/application.ini
    return 0
  else
    APP_INI=""
  fi
  
  if [ -z $APP_INI ]; then
    Debug "Couldn't find b2g/application.ini either"
    GECKO="Unknown"
    return 1
  fi

}

function Get_Gecko_Version_From_ApplicationINI { #Read the gecko version from application.ini
Debug "Get_Gecko_From_ApplicationINI"



  if [[ -e $APP_INI ]]; then
    for c in SourceStamp; do
      GECKO=$(grep "^ *$c" $APP_INI | sed "s,.*=,,g") #
    done  
   
    if [[ -z "$GECKO" ]]; then
      for d in SourceRepository; do
      GECKO=$(grep "^ *$d" $APP_INI | sed "s,.*=,,g") #
      done 
    fi
     
    if [[ -z "$GECKO" ]]; then
      GECKO="Unknown"
      return 1
    else
      return 0
    fi
  else
    echo "Couldn't find ${APP_INI}."
    GECKO="Unknown"
    return 1
  fi

}

function Get_BuildID_From_ApplicationINI { #Read the Build ID from application.ini

  Debug "Get_BuildID_From_ApplicationINI"
  if [[ -e $APP_INI ]]; then
    for b in BuildID; do
        BUILD_ID=$(grep "^ *$b" $APP_INI | sed "s,.*=,,g") || BUILD_ID="Unknown"
    done  
  else
    BUILD_ID="Unknown"
  fi

  if [ -z "$BUILD_ID" ]; then
    BUILD_ID="Unknown"
  fi
}

function Get_Firmware_From_Device_Name { #Determine which firmware list to choose from based on the device name
  Debug "Get_Firmware_From_Device_Name"
  Print_Progress_Info
  #DETECTED_FIRMWARE=`adb shell getprop ro.build.inner.version`
  #echo -e "${LYELLOW}Please note that firmware is NOT auto detected at this time. \nIt defaults to the latest, but that may not be correct${RESTORE}"
  case $DEVICE in
  'Buri') Choose_Buri_Firmware;;
  'Leo') Choose_Leo_Firmware;;
  'Flame') Choose_Flame_Firmware;;
  'Open_C') Choose_Open_C_Firmware;;
  'Tarako') Choose_Tarako_Firmware;;
  *) Choose_Custom_Firmware;;
  esac

}

function Get_Version_From_ApplicationINI { #Get the build version from application.ini
  Debug "Get_Version_From_ApplicationINI"
  if [[ -e $APP_INI ]]; then
  for d in Version; do
    DETECTED_VERSION=$(grep "^ *$d" $APP_INI | sed "s,.*=,,g")
  done
  else
  DETECTED_VERSION="Unknown"
  fi
}

function Get_Branch_From_Version { #Get the branch number from a given build version number
Debug "Get_Branch_From_Version"
  
  VERSION_11="18.0"
  VERSION_12="26.0"
  VERSION_13="28.0"
  VERSION_TK="28.1" #Tarako
  VERSION_14="30.0"
  VERSION_20="32.0a2"
  VERSION_20B="32.0"
  VERSION_20C="32.0a1"
  VERSION_21="33.0"
  VERSION_21B="34.0a1"
  VERSION_21C="34.0a2"
  VERSION_21D="33.0a1"
  VERSION_21E="34.0"
  VERSION_22="35.0a1"
  VERSION_22B="36.0"
  VERSION_22C="36.0a1"
  VERSION_22D="37.0a1"
  VERSION_22E="37.0a2"  
  VERSION_22F="37.0"  
  VERSION_30="38.0a1"
  VERSION_30B="39.0a1"
  VERSION_30C="40.0a1"
  VERSION_30D="41.0a1"

 
  
  #CURRENT_MASTER="3.0""
  
  KNOWN_VERSION=0
  
  if [[ $1 == *$VERSION_11 ]]; then
    GUESSED_VERSION="1.1"
    KNOWN_VERSION=1
  fi
  
  if [[ $1 == *$VERSION_12 ]]; then
    GUESSED_VERSION="1.2"
    KNOWN_VERSION=1
  fi
  
  if [[ $1 == *$VERSION_13 ]]; then
    GUESSED_VERSION="1.3"
    KNOWN_VERSION=1
  fi
  
  if [[ $1 == *$VERSION_TK ]]; then
    GUESSED_VERSION="1.3T"
    KNOWN_VERSION=1
  fi  
  
  if [[ $1 == *$VERSION_14 ]]; then
    GUESSED_VERSION="1.4"
    KNOWN_VERSION=1
  fi
  
  if [[ $1 == *$VERSION_20 ]]; then
    GUESSED_VERSION="2.0"
    KNOWN_VERSION=1
  fi
  
  if [[ $1 == *$VERSION_20B ]]; then
    GUESSED_VERSION="2.0"
    KNOWN_VERSION=1
  fi
  
  if [[ $1 == *$VERSION_20C ]]; then
    GUESSED_VERSION="2.0"
    KNOWN_VERSION=1
  fi
  
  if [[ $1 == *$VERSION_21 ]]; then
    GUESSED_VERSION="2.1"
    KNOWN_VERSION=1
  fi
  
  if [[ $1 == *$VERSION_21B ]]; then
    GUESSED_VERSION="2.1"
    KNOWN_VERSION=1
  fi
  
  if [[ $1 == *$VERSION_21C ]]; then
    GUESSED_VERSION="2.1"
    KNOWN_VERSION=1
  fi
  
  if [[ $1 == *$VERSION_21D ]]; then
    GUESSED_VERSION="2.1"
    KNOWN_VERSION=1
  fi
  
   if [[ $1 == *$VERSION_21E ]]; then
    GUESSED_VERSION="2.1"
    KNOWN_VERSION=1
  fi
  
  if [[ $1 == *$VERSION_22 ]]; then
    GUESSED_VERSION="2.2"
    KNOWN_VERSION=1
  fi
  
  if [[ $1 == *$VERSION_22B ]]; then
    GUESSED_VERSION="2.2"
    KNOWN_VERSION=1
  fi
  if [[ $1 == *$VERSION_22C ]]; then
    GUESSED_VERSION="2.2"
    KNOWN_VERSION=1
  fi
  if [[ $1 == *$VERSION_22D ]]; then
    GUESSED_VERSION="2.2"
    KNOWN_VERSION=1
  fi
  if [[ $1 == *$VERSION_22E ]]; then
    GUESSED_VERSION="2.2"
    KNOWN_VERSION=1
  fi
  if [[ $1 == *$VERSION_22F ]]; then
    GUESSED_VERSION="2.2"
    KNOWN_VERSION=1
  fi
  if [[ $1 == *$VERSION_30 ]]; then
    GUESSED_VERSION="3.0"
    KNOWN_VERSION=1
  fi
    if [[ $1 == *$VERSION_30B ]]; then
    GUESSED_VERSION="3.0"
    KNOWN_VERSION=1
  fi
    if [[ $1 == *$VERSION_30C ]]; then
    GUESSED_VERSION="3.0"
    KNOWN_VERSION=1
  fi
    if [[ $1 == *$VERSION_30D ]]; then
    GUESSED_VERSION="3.0"
    KNOWN_VERSION=1
  fi

 #if [[ $GUESSED_VERSION == $CURRENT_MASTER ]]; then
 #   GUESSED_VERSION="$GUESSED_VERSION - Master"
  #fi
  if [ $DETECTED_VERSION != "Unknown" ]; then
    if [ $KNOWN_VERSION -eq 0 ]; then
      GUESSED_VERSION="Master"
    fi
  fi

}

function Get_Device_Type { #Get the device type from the device and convert it in to what we know it as
  Debug "Get_Device_Type"
  
  DETECTED_DEVICE=`adb shell getprop ro.product.model`
  Debug "Detected Device: $DETECTED_DEVICE"
  DEVICE_BURI="msm7627a"
  DEVICE_OPEN_C="Open C"
  DEVICE_FLAME="Flame"
  DEVICE_TARAKO="sp6821a"
  DEVICE_LEO="LG-D300f"
  DEVICE_FLAME_2="flame"
  DEVICE_NEXUS4="AOSP"
  
  KNOWN_DEVICE=0
  
  if [[ $DETECTED_DEVICE == *$DEVICE_NEXUS4* ]]; then
    GUESSED_DEVICE="Nexus 4"
    KNOWN_DEVICE=1
  fi  
  if [[ $DETECTED_DEVICE == *$DEVICE_BURI* ]]; then
    GUESSED_DEVICE="Buri"
    KNOWN_DEVICE=1
  fi
  if [[ $DETECTED_DEVICE == *$DEVICE_OPEN_C* ]]; then
    GUESSED_DEVICE="Open_C"
    KNOWN_DEVICE=1
  fi  
  if [[ $DETECTED_DEVICE == *$DEVICE_FLAME* ]]; then
    GUESSED_DEVICE="Flame"
    KNOWN_DEVICE=1
  fi
  if [[ $DETECTED_DEVICE == *$DEVICE_FLAME_2* ]]; then
    GUESSED_DEVICE="Flame"
    KNOWN_DEVICE=1
  fi
  if [[ $DETECTED_DEVICE == *$DEVICE_TARAKO* ]]; then
    GUESSED_DEVICE="Tarako"
    IS_TARAKO=1
    KNOWN_DEVICE=1
  else
    IS_TARAKO=0
  fi
  
  if [[ $DETECTED_DEVICE == *$DEVICE_LEO* ]]; then
    GUESSED_DEVICE="Leo"
    KNOWN_DEVICE=1
  fi
  
  if [ $KNOWN_DEVICE -eq 0 ]; then
    GUESSED_DEVICE=$DETECTED_DEVICE
  fi
  
  Debug "Guessed Device: $GUESSED_DEVICE"
}

function Detect_Flame_Firmware {
adb wait-for-device &&
DETECTED_FIRMWARE=`adb shell getprop ro.bootloader`

FLAME_v10E_0='B1TC000110E0'
FLAME_v10F_3='B1TC300110F0'
FLAME_v10H_4='B1TC400110H0'
FLAME_v10G_2='B1TC200110G0'
FLAME_v121_2='B1TC20011210'
FLAME_v122_0='B1TC00011220'
FLAME_v123='B1TC00011230'
FLAME_v123a='L1TC00011230'
FLAME_v180='L1TC10011800'
FLAME_v184='L1TC00011840'
FLAME_v188='L1TC00011880'
FLAME_v188_1='L1TC10011880'
FLAME_v18D='L1TC000118D0'
FLAME_v18D_1='L1TC100118D0'
FLAME_v18D_nighty_v2='L1TC000118D0'

if [[ $DETECTED_FIRMWARE == *$FLAME_v10G_2* ]]; then
  DEFAULT_FIRMWARE="v10G-2"
  return 0
fi
if [[ $DETECTED_FIRMWARE == *$FLAME_v121_2* ]]; then
  DEFAULT_FIRMWARE="v121-2"
  return 0
fi
if [[ $DETECTED_FIRMWARE == *$FLAME_v122_0* ]]; then
  DEFAULT_FIRMWARE="v122"
  return 0
fi
if [[ $DETECTED_FIRMWARE == *$FLAME_v10H_4* ]]; then
  DEFAULT_FIRMWARE="v10H-4"
  return 0
fi
if [[ $DETECTED_FIRMWARE == *$FLAME_v10F_3* ]]; then
  DEFAULT_FIRMWARE="v10F-3"
  return 0
fi
if [[ $DETECTED_FIRMWARE == *$FLAME_v10E_0* ]]; then
  DEFAULT_FIRMWARE="v10E"
  return 0
fi
if [[ $DETECTED_FIRMWARE == *$FLAME_v123* ]]; then
  DEFAULT_FIRMWARE="v123"
  return 0
fi
if [[ $DETECTED_FIRMWARE == *$FLAME_v123a* ]]; then
  DEFAULT_FIRMWARE="v123"
  return 0
fi
if [[ $DETECTED_FIRMWARE == *$FLAME_v180* ]]; then
  DEFAULT_FIRMWARE="v180"
  return 0
fi
if [[ $DETECTED_FIRMWARE == *$FLAME_v184* ]]; then
  DEFAULT_FIRMWARE="v184"
  return 0
fi
if [[ $DETECTED_FIRMWARE == *$FLAME_v188* ]]; then
  DEFAULT_FIRMWARE="v188"
  return 0
fi
if [[ $DETECTED_FIRMWARE == *$FLAME_v188_1* ]]; then
  DEFAULT_FIRMWARE="v188-1"
  return 0
fi
if [[ $DETECTED_FIRMWARE == *$FLAME_v18D* ]]; then
  DEFAULT_FIRMWARE="v18D"
  return 0
fi
if [[ $DETECTED_FIRMWARE == *$FLAME_v18D_1* ]]; then
  DEFAULT_FIRMWARE="v18D-1"
  return 0
fi
if [[ $DETECTED_FIRMWARE == *$FLAME_v18D_nightly_v2* ]]; then
  DEFAULT_FIRMWARE="v18D_nightly_v2"
  return 0
fi

DEFAULT_FIRMWARE=$DETECTED_FIRMWARE

return 1
}
###################################################################


#########################GET_USER_INPUT############################
function Is_Def { #Determine if the passed firmware version is the default one, and draw a blue arrow next to if in the list if so
if [ $1 == $DEFAULT_FIRMWARE ]; then
  echo "$1 $DEF"
else
  echo "$1"
fi
}

function Choose_Buri_Firmware { #There is only 1 firmware for Buri, so we just set it here.
  Debug "Choose_Buri_Firmware"
  FIRMWARE="v1.2device.cfg"
}

function Choose_Flame_Firmware { #Ask the user which flame firmware to use, providing a default
  Debug "Choose_Flame_Firmware"
  #FLAME_FIRMWARE_1="v10E"
  #FLAME_FIRMWARE_2="v10F-3"
  #FLAME_FIRMWARE_3="v10G-2"
  #FLAME_FIRMWARE_4="v121-2"
  #FLAME_FIRMWARE_5="v122"
  #FLAME_FIRMWARE_6="v10H-4"
  #FLAME_FIRMWARE_7="v18D"
  #FlAME_FIREWARE_8="v18D_nightly_v2"
  #                   0      1        2        3        4       5       6      7            8
  FLAME_FIRMWARE=( "v123" "v122" "v121-2" "v10G-2" "v10F-3" "v10E" "v10H-4" "v18D" "v18D_nightly_v2" )
  FLAME_FIRMWARE_COUNT=${#FLAME_FIRMWARE[@]}
  
  Detect_Flame_Firmware #|| DEFAULT_FIRMWARE=$FLAME_FIRMWARE_5
  
  if [ $QUICK -eq 1 ]; then
    FIRMWARE=$DEFAULT_FIRMWARE
    return 0
  fi
  
  echo -e "Which firmware version? Defaults to ${LBLUE}$DEFAULT_FIRMWARE${RESTORE} if left blank"
  local i
  for (( i=0;i<$FLAME_FIRMWARE_COUNT; i++)); do
    echo -e "${i}) $(Is_Def ${FLAME_FIRMWARE[${i}]})"
  done
  
  #echo -e "1) $(Is_Def $FLAME_FIRMWARE_5)\n2) $(Is_Def $FLAME_FIRMWARE_4)\n3) $(Is_Def $FLAME_FIRMWARE_3)\n4) $(Is_Def $FLAME_FIRMWARE_2)\n5) $(Is_Def $FLAME_FIRMWARE_1)\n6) $(Is_Def $FLAME_FIRMWARE_6)"
  read FLAME_FIRMWARE_CHOICE
  case $FLAME_FIRMWARE_CHOICE in
    [0-$FLAME_FIRMWARE_COUNT]) FIRMWARE=${FLAME_FIRMWARE[${FLAME_FIRMWARE_CHOICE}]} #Can only handle 0-9
    ;;
    *) if [ -z $FLAME_FIRMWARE_CHOICE ]; then
          FIRMWARE=$DEFAULT_FIRMWARE   #DEFAULT GOES HERE
       else
          FIRMWARE=$FLAME_FIRMWARE_CHOICE
       fi
       ;;
  esac
}

function Choose_Open_C_Firmware { #Ask the user which open_c firmware to use, providing a default
  Debug "Choose_Open_C_Firmware"
  
  OPEN_C_FIRMWARE_1="P821A10-ENG_20140410"
  OPEN_C_FIRMWARE_2="P821A10V1.0.0B06_LOG_DL"
  DEFAULT_FIRMWARE=$OPEN_C_FIRMWARE_2
  
  if [ $QUICK -eq 1 ]; then
  FIRMWARE=$DEFAULT_FIRMWARE
  return 0
  fi
  
  echo -e "Which firmware version? Defaults to ${LBLUE}$DEFAULT_FIRMWARE${RESTORE} if left blank"
  echo -e "1) $(Is_Def $OPEN_C_FIRMWARE_2) \n2) $(Is_Def $OPEN_C_FIRMWARE_1)"
  read OPEN_C_FIRMWARE_CHOICE
  case $OPEN_C_FIRMWARE_CHOICE in
    1) FIRMWARE=$OPEN_C_FIRMWARE_2 ;;
    2) FIRMWARE=$OPEN_C_FIRMWARE_1 ;;
    *) if [ -z $OPEN_C_FIRMWARE_CHOICE ]; then
          FIRMWARE=$DEFAULT_FIRMWARE #DEFAULT GOES HERE
       else
          FIRMWARE=$OPEN_C_FIRMWARE_CHOICE
       fi
       ;;
  esac
}

function Choose_Device { #Ask the user to confirm the device name, or provide their own
  Debug "Choose_Device"
  Print_Progress_Info
  
  if [ $KNOWN_DEVICE -eq 1 ]; then
    if [ $QUICK -eq 1 ]; then
      DEVICE=$GUESSED_DEVICE
      return 0
    fi
    echo -e "Device detected as ${LBLUE}$GUESSED_DEVICE${RESTORE}"
  else
    echo -e "Unknown device detected: ${LBLUE}$GUESSED_DEVICE${RESTORE}"
  fi
    echo -e "To correct this enter another device name below."
    echo -e "Otherwise leave the line blank to use ${LBLUE}$GUESSED_DEVICE${RESTORE}."
  read D_CHOICE
  if [ -z $D_CHOICE ]; then
    DEVICE=$GUESSED_DEVICE
  else
    DEVICE=$D_CHOICE
  fi
}

function Choose_Version { #Ask the user to confirm the version, or provide their own
  Debug "Choose_Version"
  Print_Progress_Info
    if [ $KNOWN_VERSION -eq 1 ]; then
    if [ $QUICK -eq 1 ]; then
      VERSION="($GUESSED_VERSION)"
      VERSION_2="$GUESSED_VERSION"
      return 0
    fi  
    echo -e "Branch detected as ${LBLUE}$GUESSED_VERSION ($DETECTED_VERSION)${RESTORE}"
    echo -e "Leave blank to use this or enter the correct branch below."
  else
    if [ $QUICK -eq 1 ]; then
      VERSION="($GUESSED_VERSION)"
      VERSION_2="$GUESSED_VERSION"
      return 0
    fi
    echo -e "Unknown branch detected for ${LBLUE}$DETECTED_VERSION${RESTORE}"
    echo -e "Leave blank or enter the correct branch below."
  fi
  
  read V_CHOICE
  if [ -z $V_CHOICE ]; then
    VERSION="($GUESSED_VERSION)"
    VERSION_2="$GUESSED_VERSION"
  else
    VERSION="($V_CHOICE)"
    VERSION_2="$V_CHOICE"
  fi
  
  if [ $VERSION == "()" ]; then
    VERSION=""
    VERSION_2=""
  fi
}

function Choose_Tarako_Firmware {  #Ask the user which tarako firmware to use, providing a default
  
  Debug "Choose_Tarako_Firmware"
  TARAKO_FIRMWARE_1="SP6821a-Gonk-4.0-4-29"
  TARAKO_FIRMWARE_2="SP6821a-Gonk-4.0-5-12"
  DEFAULT_FIRMWARE=$TARAKO_FIRMWARE_2
  
    if [ $QUICK -eq 1 ]; then
      FIRMWARE=$DEFAULT_FIRMWARE
      return 0
    fi  
  
  echo -e "Which firmware version? Defaults to ${LBLUE}$DEFAULT_FIRMWARE${RESTORE} if left blank"
  echo -e "1) $(Is_Def $TARAKO_FIRMWARE_2)\n2) $(Is_Def $TARAKO_FIRMWARE_1)"
  read TARAKO_FIRMWARE_CHOICE
  case $TARAKO_FIRMWARE_CHOICE in
    1) FIRMWARE=$TARAKO_FIRMWARE_2 ;;
    2) FIRMWARE=$TARAKO_FIRMWARE_1 ;;
    *) if [ -z $TARAKO_FIRMWARE_CHOICE ]; then
          FIRMWARE=$DEFAULT_FIRMWARE
       else
          FIRMWARE=$TARAKO_FIRMWARE_CHOICE
       fi
       ;;
  esac
  
}

function Choose_Custom_Firmware { #We don't know which device this is, so ask for a custom firmware 
  Debug "Choose_Custom_Firmware"
  Print_Progress_Info
  echo -e "No firmware known for this device."
  echo -e "Please enter a custom firmware version or leave this line blank and continue."
  read FIRMWARE
}

function Get_User_Agent { #Remind the user to get the User Agent string.
if [ $SKIP_UA -eq 0 ]; then
  Debug "Get_User_Agent"
  
  case $GUESSED_DEVICE in
    'Flame') Get_UA
    ;;
    'Buri') Get_UA
    ;;
    'Open_C') Get_UA
    ;;
    'Tarako') Get_UA_T
    ;;
    *) Default_UA
    ;;
  esac
  if [[ -z $USER_AGENT ]]; then
    Default_UA
  fi
  
fi
}

function Default_UA {
  USER_AGENT="Please get the ${LBLUE}User Agent${RESTORE} information by going to ${LYELLOW}www.whatsmyuseragent.com on the device${RESTORE} and include it in the bug${RESTORE}"
}

function Get_UA_T {
if [[ $DETECTED_VERSION == *$VERSION_TK ]]; then
  USER_AGENT="User Agent: Mozilla/5.0 (Mobile; rv:28.1) Gecko/28.1 Firefox/28.1"
else
  Default_UA
fi
}

function Get_UA {
  UAV=${DETECTED_VERSION%.*}
  USER_AGENT="Mozilla/5.0 (Mobile; rv:$UAV.0) Gecko/$UAV.0 Firefox/$UAV.0"
}
####################################################################

############################OUTPUT##################################

function Generate_Bug_Template { #Creates the bug template and opens it for the user
  Debug "Generate_Bug_Template"
  #Print_Progress_Info
  if [ $HIDE_EDITOR -eq 1 ]; then
    return 0
  fi
  file_name=$TEMP_DIR/bugtemplate_$(date +%Y%m%d-%H%M%S).txt
  echo -e "Summary (title) Field:" >> $file_name &&
  echo -e "[Component][Location](Concise statement of the issue)" >> $file_name &&
  echo -e "\nDescription:\n(Expand upon the Summary - but not a copy of the Summary!)" >> $file_name &&
  echo -e "\n\nRepro Steps:" >> $file_name &&
  echo -e "1) Update a $DEVICE to $BUILD_ID" >> $file_name &&
  echo -e "2)\n3)\n4)\n\n" >> $file_name &&
  echo -e "Actual:\n(Describe the behavior you actually observed)" >> $file_name &&
  echo -e "\n\nExpected:\n(Describe the behavior you expected to have observed)\n\n\nNotes:\n" >> $file_name &&

  echo -e "Environmental Variables:" >> $file_name &&

  echo -e "Device: $DEVICE $VERSION_2" >> $file_name &&
  echo -e "Build ID: $BUILD_ID" >> $file_name &&
  echo -e "Gaia: $GAIA" >> $file_name &&
  echo -e "Gecko: $GECKO" >> $file_name &&
  echo -e "Gonk: $GONK" >> $file_name &&
  echo -e "Version: $DETECTED_VERSION $VERSION" >> $file_name &&
  
  #if [ $SHOWRIL -eq 1 ]; then
  #echo "RIL Version:" $(head -n 1 $TEMP_DIR/libqc_b2g_ril.version) >> $file_name 
  #fi

  echo -e "Firmware Version:" $FIRMWARE >> $file_name &&
  echo -e "User Agent: $USER_AGENT" >> $file_name &&
  echo -e "\n\nUser Impact:\n\n\nRepro frequency: (2/3, 100%, etc.)\nLink to failed test case:\nSee attached: (screenshot, video clip, logcat, etc.)" >> $file_name &&

  $TEXT_APP $file_name &
}

function Print_Progress_Info { #Print a list at the top of the screen to show the current progress
  Debug "Print_Progress_Info"
  Do_Clear
  if [ $SKIP_REPORT -eq 0 ]; then
    #Check_Unknowns
    echo -e "--------------------------------------------------"
    echo -e "Device:   ${LBLUE}$DEVICE${RESTORE}"
    echo -e "Branch:   ${LBLUE}$VERSION ${RESTORE}"
    echo -e "Version:  ${LBLUE}$DETECTED_VERSION${RESTORE}"
    echo -e "Firmware: ${LBLUE}$FIRMWARE${RESTORE}"
    echo -e "--------------------------------------------------"
  fi
}

function Print_Full_Info { #Print all the version info in the terminal (Should match what is in the bug template)
Debug "Print_Full_Info"
Do_Clear

  
if [ $SIMPLE -eq 0 ]; then
  echo -e "--------------------------------------------------"
  echo -e "Environmental Variables:"
  echo -e "Device: ${LBLUE}$DEVICE $VERSION_2${RESTORE}"
  echo -e "BuildID: ${LBLUE}$BUILD_ID${RESTORE}"
fi
  echo -e "Gaia: ${LBLUE}$GAIA${RESTORE}"
  echo -e "Gecko: ${LBLUE}$GECKO${RESTORE}"
  echo -e "Gonk: ${LBLUE}$GONK${RESTORE}"
if [ $SIMPLE -eq 0 ]; then
  echo -e "Version: ${LBLUE}$DETECTED_VERSION $VERSION ${RESTORE}"
  echo -e "${LYELLOW}Firmware Version: ${LBLUE}$FIRMWARE${RESTORE}"
  echo -e "${LYELLOW}User Agent: ${LBLUE}$USER_AGENT${RESTORE}"
  echo -e "--------------------------------------------------"
  echo -e "${LYELLOW}Please note that the Firmware Version and User Agent should be verified.${RESTORE}"
fi

}

function Print_Info_From_Directory { #Print the info we got from the build directory
  Debug "Print_Info_From_Directory"
  Do_Clear
  if [ $SIMPLE -eq 0 ]; then
    echo -e "Directory: ${LBLUE}$DROP_DIR${RESTORE}"
    echo -e "--------------------------------------------------"
    echo -e "Environmental Variables"
    echo -e "BuildID: ${LBLUE}$BUILD_ID${RESTORE}"
  fi
  echo -e "Gaia: ${LBLUE}$GAIA${RESTORE}"
  echo -e "Gecko: ${LBLUE}$GECKO${RESTORE}"
  if [ $SIMPLE -eq 0 ]; then
    echo -e "Version: ${LBLUE}$DETECTED_VERSION ($GUESSED_VERSION)${RESTORE}"
    echo -e "--------------------------------------------------"
  fi
  

}

####################################################################


##############################MAIN##################################

function Get_Vars_From_Device { #Run the commands to get variables from a device


  DIR=$TEMP_DIR
  Start_ADB
  adb pull '/system/sources.xml' sources &> /dev/null && get_source || (echo "error pulling gonk" && GONK="Cannot pull sources file. Did you Shallow Flash?")
  Pull_ApplicationZip_From_Device
  Pull_ApplicationINI_From_Device 
  Get_Device_Type
  Choose_Device
  Get_Firmware_From_Device_Name
    Main
  Get_User_Agent
  Print_Full_Info
  Generate_Bug_Template

}

function Get_Vars_From_Folder { #Run the commands to get variables from a given directory


    Find_Build_Location
    Extract_ApplicationINI_From_B2GTar
    Extract_Commitfile_From_GaiaZip
    Main
    Print_Info_From_Directory
    Get_User_Agent

}

function Main { #Run the commands common to both options above

  Get_Gaia_Version_From_Commitfile
  Get_Gecko_Version_From_ApplicationINI
  Get_BuildID_From_ApplicationINI
  Get_Version_From_ApplicationINI
  Get_Branch_From_Version $DETECTED_VERSION
  Choose_Version

}

Init_Variables &&
Get_Args "$@"
Do_Clear
Choose_Work_Path






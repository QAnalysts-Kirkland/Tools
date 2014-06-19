#!/bin/bash
# Usage:  gg '/path/to/build/dir/' <flag>
# This script allows you to stay in the top builds folder and drag
# drop the folder instead of going in and changing to the right
# directory, chmod-ing, etc.  
clear

#SET TO 1 TO SEE DEBUG OUTPUT
DEBUG=0

#------------------------DON'T TOUCH THIS--------------------------#
DROP_DIR=$1 #The first argument. Should be a build directory
FLAG=$2 #The second argument. The flag indicating the flash file to use.
RESULT="Incomplete" #Default analytic results to incomplete and change it later if the flash is successful.
REASON="Interrupted" #Default failure reason to interrupted and change it later if the flash is successful.
DEBUG_LOG="" #Initialize the debug log for analytics
#------------------------------------------------------------------#



function Get_Opts {
while getopts :d opt; do
  case $opt in
  d) ADB_DEBUG=1
  ;;
  *)
  ;;
  esac
done
}

####################################################################
#------------CHANGE THIS TO POINT TO LATEST FLASH FILES------------#
function Determine_Build { #Tell the script where to find all the flash files
  Debug "Determine_Build"
  LATEST_FLASH='/mnt/builds/Needed_Scripts/flash_Gg.sh' 
  NEW_FLAGS="-dn"

  OLD_FLASH='/mnt/builds/Needed_Scripts/fullflash_gecko_ril_gaia.sh'
  OLD_FLAGS="-rn"

  TARAKO_FLASH='/mnt/builds/Needed_Scripts/flash_tarako.sh'
  TARAKO_FLAGS=''

  DEBUG_FLASH='/mnt/builds/Needed_Scripts/flash_Gg_de.sh' 
  DEBUG_FLAGS="-dn"

  NAOKI_FLASH='/mnt/builds/Needed_Scripts/naoki_flash.sh' 
  NAOKI_FLAGS=""

  NEXUS_FLASH='/mnt/builds/Needed_Scripts/flash_Nexus_4.sh' 
  NEXUS_FLAGS=""
}
####################################################################

#---------------SYSTEM--------------------#

function Init_Vars { #Initialize some variables that can't be left blank
  Debug "Init_Vars"
  VERSION=''
  DEVICE=''
  RILTYPE=''
  RIL=''
  BID=''
  GECKO=''
  VERZ=''
  DIR=''
  FW=''
  ADB_DEBUG=0
  tempdir=""
}

function DIE { #Call this when something bad happens to give the user more info about it
  Debug "DIE"
  if [ -n "$1" ]; then
    echo -e "${LRED}ERROR: $1${RESTORE}"
    REASON="$1"
  else
    REASON="Unknown"
  fi
  RESULT="Failed"
  
  Analytics
  Cleanup
  exit 1
}

function Cleanup { #Delete the temp directory once we are done with it
  Debug "Cleanup"
  if [ -e $tempdir ]; then
    rm -r $tempdir &> /dev/null || Debug "Failed to clean up"
  fi
}

function Get_Mod_Date { #Get the date this script was last modified for analytics
  Debug "Get_Mod_Date"
  SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )
  MODDATE=$(stat -c %y ${SCRIPTPATH})
  MODDATE=${MODDATE%% *}
}

function Analytics { #Gather information about how this script was run and save it to be analyzed later
  Debug "Analytics"
  Get_Mod_Date
  H_DIR=/mnt/builds/Needed_Scripts/.analytics
  DATE="$(date +%Y%m%d_%H%M%S)"
  FILENAME="${RESULT}_${DEVICE}_${DATE}.log"
  H_FILE=$H_DIR/$FILENAME
  #H_FILE=${H_FILE}
  Debug "H_FILE: $H_FILE"
  if [ ! -e $H_DIR ]; then
    mkdir $H_DIR &> /dev/null
  fi
  if [[ -e $H_DIR ]]; then
    echo -e "Script Version: $MODDATE" >> $H_FILE
    echo -e "Result: $RESULT" >> $H_FILE
    echo -e "Reason: $REASON" >> $H_FILE
    echo -e "Environmental Variables:" >> $H_FILE
    echo -e "Device: $DEVICE" >> $H_FILE
    echo -e "BuildID: $BID" >> $H_FILE
    echo -e "Gaia: $GAIA" >> $H_FILE
    echo -e "Gecko: $GECKO" >> $H_FILE
    echo -e "Version: $VERZ" >> $H_FILE
    echo -e "Time elapsed: $TIME_ELAPSED" >> $H_FILE
    echo -e "Working directory: $DIR" >> $H_FILE
    echo -e "Flash file used: $FLASH_FILE_NAME_ONLY $USE_FLAGS" >> $H_FILE
    echo -e "\n---Debug log---$DEBUG_LOG" >> $H_FILE
  else
  Debug "Couldn't do analytics."
  fi
}

function Show_help { #Show the how to use screen
  Debug "Show_help"
  echo -e "Usage: ${LGREEN}gg ${LYELLOW}/path/to/build/dir/ ${LBLUE}<flag>${RESTORE}"
  echo -e "Flags:"
  echo -e "${LBLUE}gg${RESTORE} : Use  ${LGREEN}${LATEST_FLASH##*/} $NEW_FLAGS          ${LYELLOW}(Latest / Default)${RESTORE}"
  echo -e "${LBLUE}de${RESTORE} : Use  ${LGREEN}${DEBUG_FLASH##*/} $DEBUG_FLAGS           ${LYELLOW}(Latest with debug enabled)${RESTORE}"
  echo -e "${LBLUE}ff${RESTORE} : Use  ${LGREEN}${OLD_FLASH##*/} $OLD_FLAGS     ${LYELLOW}(For older v1.3 and below)${RESTORE}"
  echo -e "${LBLUE}tf${RESTORE} : Use  ${LGREEN}${TARAKO_FLASH##*/} $TARAKO_FLAGS        ${LYELLOW}(For Tarako devices)${RESTORE}"
  echo -e "${LBLUE}nf${RESTORE} : Use  ${LGREEN}${NAOKI_FLASH##*/} $NAOKI_FLAGS      ${LYELLOW}(Fixes 'no space' error)${RESTORE}"
  echo -e "${LBLUE}nx${RESTORE} : Use  ${LGREEN}${NEXUS_FLASH##*/} $NEXUS_FLAGS    ${LYELLOW}(For Nexus 4)${RESTORE}"
  echo -e "${LYELLOW}Do not use spaces in your path!${RESTORE}"
}

function Color_Init { #Sets up color variables to use later
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

function Debug { #Call this and pass it a string to display extra information if DEBUG=1
if [ $DEBUG -eq 1 ]; then
  echo -e "DEBUG: ${LGRAY}$1${RESTORE}"
fi
  DEBUG_LOG="$DEBUG_LOG\n$1"
}

function Start_Timer { #Start a timer to see how long this push took
  Debug "Start_Timer"
  date1=$(date +"%s")
}

function End_Timer { #End the timer and save the time taken
  Debug "End_Timer"
  date2=$(date +"%s")
  diff=$(($date2-$date1))
  TIME_ELAPSED="$(($diff / 60)) minutes and $(($diff % 60)) seconds elapsed."
  echo "$(($diff / 60)) minutes and $(($diff % 60)) seconds elapsed."
}

#---------------FLASH_CHOICES-------------#

function USE_FULLFLASH { #Check for and set the flash script to fullflash_gecko_ril_gaia.sh
  Debug "USE_FULLFLASH"
  if [ -e $OLD_FLASH ]; then
      FLASH_FILE_FULL_PATH=$OLD_FLASH
      USE_FLAGS=$OLD_FLAGS
      echo -e "${LBLUE}Using $OLD_FLASH $USE_FLAGS ${RESTORE}"
  else
    DIE "Invalid OLD_FLASH specified. $OLD_FLASH does not exist!"
  fi
}

function USE_NEXUS_FLASH { #Check for and set the flash script to flash_Nexus_4.sh
Debug "USE_NEXUS_FLASH"
if [ -e $NEXUS_FLASH ]; then
      FLASH_FILE_FULL_PATH=$NEXUS_FLASH
      USE_FLAGS=$NEXUS_FLAGS
      echo -e "${LBLUE}Using $NEXUS_FLASH $USE_FLAGS ${RESTORE}"
    else
      DIE "Invalid NEXUS_FLASH specified. $NEXUS_FLASH does not exist!"
    fi
}

function USE_FLASH_GG { #Check for and set the flash script to flash_Gg.sh
Debug "USE_FLASH_GG"
if [ -e $LATEST_FLASH ]; then
      FLASH_FILE_FULL_PATH=$LATEST_FLASH
      USE_FLAGS=$NEW_FLAGS
      echo -e "${LBLUE}Using $LATEST_FLASH $USE_FLAGS ${RESTORE}"
    else
      DIE "Invalid LATEST_FLASH specified. $LATEST_FLASH does not exist!"
    fi
}

function USE_DEBUG_FLASH { #Check for and set the flash script to flash_Gg_de.sh
Debug "USE_DEBUG_FLASH"
if [ -e $DEBUG_FLASH ]; then
      FLASH_FILE_FULL_PATH=$DEBUG_FLASH
      USE_FLAGS=$DEBUG_FLAGS
      echo -e "${LBLUE}Using $DEBUG_FLASH $DEBUG_FLAGS ${RESTORE}"
    else
      DIE "Invalid DEBUG_FLASH specified. $DEBUG_FLASH does not exist!"
    fi
}

function USE_TARAKO_FLASH { #Check for and set the flash script to flash_tarako.sh
Debug "USE_TARAKO_FLASH"
if [ -e $TARAKO_FLASH ]; then
      FLASH_FILE_FULL_PATH=$TARAKO_FLASH
      USE_FLAGS=$TARAKO_FLAGS
      echo -e "${LBLUE}Using $TARAKO_FLASH $TARAKO_FLAGS ${RESTORE}"
    else
      DIE "Invalid TARAKO_FLASH specified. $TARAKO_FLASH does not exist!"
    fi
}

function USE_NAOKI_FLASH { #Check for and set the flash script to naoki_flash.sh
Debug "USE_NAOKI_FLASH"
if [ -e $TARAKO_FLASH ]; then
      FLASH_FILE_FULL_PATH=$NAOKI_FLASH
      USE_FLAGS=$NAOKI_FLAGS
      echo -e "${LBLUE}Using $NAOKI_FLASH $NAOKI_FLAGS ${RESTORE}"
    else
      DIE "Invalid NAOKI_FLASH specified. $NAOKI_FLASH does not exist!"
    fi
}


#-----------VALIDITY_CHECKS---------------#

function Check_Validity { #Verify the validity of the dropped directory and flags
Debug "Check_Validity"

  if [ -z $DROP_DIR ]; then
    Show_help
    DIE "No path specified"
  fi

  if [ ! -e $DROP_DIR ];then
    Show_help
    DIE "Invalid path specified"
  fi
  
if [ -z $FLAG ]; then
  echo -e "${LBLUE}Defaulting to ${LATEST_FLASH##*/} ${RESTORE}"
  FLAG='gg'
  USE_FLASH_GG
else
  case $FLAG in
    'gg') USE_FLASH_GG;;
    'ff') USE_FULLFLASH;;
    'tf') USE_TARAKO_FLASH;;
    'de') USE_DEBUG_FLASH;;
    'nf') USE_NAOKI_FLASH;;
    'nx') USE_NEXUS_FLASH;;
    *) Show_help
       DIE "Unknown flag: $FLAG" ;;
  esac
fi
  FLASH_FILE_DIR_ONLY="${FLASH_FILE_FULL_PATH%/*}"
  FLASH_FILE_NAME_ONLY="${FLASH_FILE_FULL_PATH##*/}"


  
  if [ ! -e $DROP_DIR ]; then
    Show_help
    DIE "Invalid path"
  fi
}

function Check_Dir { #Search for the build files in the directory
  Debug "Check_Dir"

  if [ ! -e /mnt/builds/Needed_Scripts ]; then
    echo -e "${LYELLOW}Warning: Can't access the Needed_Scripts directory!${RESTORE}"
  fi
  
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
  
  if [ -e $DROP_DIR/b2g-distro/gaia ]; then
    DIR=$DROP_DIR/b2g-distro
  fi
  
  if [ -e $DROP_DIR/b2g-distro/b2g ]; then
    DIR=$DROP_DIR/b2g-distro
  fi
  
  if [ -e $DROP_DIR/*arako*.zip ]; then
    DIR=$DROP_DIR
  fi
  if [ -e $DROP_DIR/nexus-4.zip ]; then
    DIR=$DROP_DIR
  fi

  if [ -e $DROP_DIR/b2g-distro/*arako*.zip ]; then
    DIR=$DROP_DIR/b2g-distro
  fi

  Check_Device_Flag_Match

  if [ -z $DIR ]; then
    Show_help
    DIE "Unable to determine build location"
  fi
  Debug "Dir: $DIR"
  cd $DIR
}

function Check_Device_Tarako { #Verify things are set up correctly to flash Tarako builds
  Debug "Check_Device_Tarako"
  IS="Tarako"
  if [[ $DEVICE == *$IS* ]]; then

    if [ ! -e $DIR/*arako*.zip ]; then
      DIE "No tarako.zip found! This build will fail!"
    fi

    if [[ $FLAG != 'tf' ]]; then
      echo -e "${LYELLOW} Determined to be a tarako build. Would you like to use ${LBLUE}$TARAKO_FLASH $TARAKO_FLAGS${RESTORE}?${RESTORE}"
      echo -e "1) Yes, use the [ ${LBLUE}tf${RESTORE} ] flag (${LBLUE}$TARAKO_FLASH $NEXUS_FLAGS${RESTORE})"
      echo -e "2) No, I know what I'm doing. Use [ ${LBLUE}$FLAG${RESTORE} ]"
      read TFCHOICE
      case $TFCHOICE in
        1)  FLAG='tf'
            echo -e "Using '${LBLUE}$FLAG${RESTORE}'" 
            Check_Validity
            ;;
        *)  echo -e "Staying with [ $FLAG ]" ;;
      esac
    fi

  fi
}

function Check_Device_Nexus4 { #Verify things are set up correctly to flash Nexus 4 builds (currently not supported)
  Debug "Check_Device_Nexus4"
  IS="Nexus 4"
  if [[ $DEVICE == *$IS* ]]; then
  DIE "The Nexus 4 is not currently supported. Please do this flash manually"
  if [ -e $DROP_DIR/b2g-distro/out ]; then
  DIR=$DROP_DIR/b2g-distro/out
  fi
  if [ -e $DROP_DIR/out ]; then
    DIR=$DROP_DIR/out
  fi  
  
    if [ ! -e $DIR/nexus-4.zip ]; then
      DIE "No nexus-4.zip found! This build will fail!"
    fi
    Extract_Nexus
    if [[ $FLAG != 'nx' ]]; then
      echo -e "${LYELLOW} Determined to be a Nexus 4 build. Would you like to use ${LBLUE}$NEXUS_FLASH $NEXUS_FLAGS${RESTORE}?${RESTORE}"
      echo -e "1) Yes, use the [ ${LBLUE}nx${RESTORE} ] flag (${LBLUE}$NEXUS_FLASH $NEXUS_FLAGS${RESTORE})"
      echo -e "2) No, I know what I'm doing. Use [ ${LBLUE}$FLAG${RESTORE} ]"
      read TFCHOICE
      case $TFCHOICE in
        1)  FLAG='nx'
            echo -e "Using '${LBLUE}$FLAG${RESTORE}'" 
            Check_Validity
            ;;
        *)  echo -e "Staying with [ $FLAG ]" ;;
      esac
    fi

  fi
}

function Check_Device_Flag_Match { #Call the above functions
Debug "Check_Device_Flag_Match"
Check_Device_Tarako
Check_Device_Nexus4
}

#--------------FLASH_SETUP----------------#

function Check_For_Extractables { #Call the functions to check for and extact gaia and gecko
Debug "Check_For_Extractables"
  Extract_Gaia
  Extract_Gecko
  
  return 0
}

function Extract_Nexus { #extract files necessary to flash the nexus 4 (Not supported)
Debug "Extract_Nexus"
if [ -e $DIR/nexus-4.zip ]; then
    echo "Found nexus-4.zip, extracting..."
    unzip -o -u $DIR/nexus-4.zip 
    echo "Done extracting."
    return 0
fi
}

function Extract_Gaia { #Extract the gaia files
Debug "Extract_Gaia"
  if [ -e $DIR/gaia*.zip ]; then
    echo "Found gaia.zip, extracting..."
    unzip -o -u $DIR/gaia*.zip 
    echo "Done extracting."
    return 0
  else
    GAIA="Unknown"
    return 1
  fi
}

function Extract_Gecko { #Extract the gecko files
Debug "Extract_Gecko"
  if [ -e b2g*.tar.gz ]; then
    echo "Found tars, extracting...."
    tar -xkzvf b2g*.tar.gz 
    echo "Done extracting tars" 
    return 0
  else
    GECKO="Unknown"
    return 1
  fi
  
}

function Check_GG { #Check for and grab the correct flash file and place it in the directory
  Debug "Check_GG"
  echo "Grabbing latest $FLASH_FILE_NAME_ONLY"

  if [ $DIR == $FLASH_FILE_FULL_PATH ]; then
    DIE "Specified directory $DIR and scripts directory $FLASH_FILE_FULL_PATH are the same! Aborting!"
  fi
  
  if [ -e $FLASH_FILE_FULL_PATH ]; then #If there is a version we can copy
    echo -e "${LBLUE}Found $FLASH_FILE_NAME_ONLY in $FLASH_FILE_DIR_ONLY.${RESTORE}"
    
    if [ -e $DIR/$FLASH_FILE_NAME_ONLY ]; then #if a local version exists
        CHECK_DIFF=$(diff -q <(sort $DIR/$FLASH_FILE_NAME_ONLY | uniq) <(sort $FLASH_FILE_FULL_PATH | uniq))
        if [[ -n $CHECK_DIFF ]]; then #If differences were found
          echo -e "${LBLUE} Replacing $FLASH_FILE_NAME_ONLY with latest version in $FLASH_FILE_DIR_ONLY${RESTORE}"
          rm $DIR/$FLASH_FILE_NAME_ONLY #remove older version
          cp $FLASH_FILE_FULL_PATH $DIR/ #copy in newer version
        else
          echo -e "${LBLUE} Directory has latest $FLASH_FILE_NAME_ONLY${RESTORE}"
        fi
    else #if there is no local version
      echo -e "${LBLUE}No local flash file found. Copying over $FLASH_FILE_NAME_ONLY.${RESTORE}"
      cp $FLASH_FILE_FULL_PATH $DIR/ #copy in newer version
    fi

  else #if there is no version we can copy
    echo "${LYELLOW}$FLASH_FILE_FULL_PATH not found!${RESTORE}"
    
    #check if there is a local one to use
    if [ -e $DIR/$FLASH_FILE_NAME_ONLY ]; then
      echo "${LYELLOW}Using local version of $FLASH_FILE_NAME_ONLY${RESTORE}"
    else
    DIE "Cannot find $FLASH_FILE_NAME_ONLY! Aborting!"
    fi
  fi
}

function Flash { #Call the selected flash file
  Debug "Flash"
  #DIE "test"
  Debug "Dir: $DIR"
  chmod +x ./$FLASH_FILE_NAME_ONLY
  echo -e "Make sure device is connected..."
  adb wait-for-device
  echo -e "Flashing, please wait...."
  ./$FLASH_FILE_NAME_ONLY $USE_FLAGS  || DIE "Script failed. \nPlease make sure the device is connected, unlocked, and that adb debugging is enabled.\n You can also try 'adb remount' or 'adb reboot' and then run this script again."
  RESULT="Success"
  REASON="N.A."
}

#----------GET_BUILD_INFO------------------#

function Get_Device_Type { #Get the device type and convert it to what we know it as
  Debug "Get_Device_Type"
  DEVICE=`adb shell getprop ro.product.model` || DEVICE="Unknown"
  BURI="msm7627a"
  OPEN_C="Open C"
  FLAME="Flame"
  TARAKO="sp6821a"
  LEO="LG-D300f"
  NEXUS4="AOSP on Mako"
  
  KNOWN_DEVICE=0
  
  if [[ $DEVICE == *$NEXUS4* ]]; then
    DEVICE="Nexus 4"
    KNOWN_DEVICE=1
  fi  
  if [[ $DEVICE == *$BURI* ]]; then
    DEVICE="Buri"
    KNOWN_DEVICE=1
  fi
  if [[ $DEVICE == *$OPEN_C* ]]; then
    DEVICE="Open_C"
    KNOWN_DEVICE=1
  fi  
  if [[ $DEVICE == *$FLAME* ]]; then
    DEVICE="Flame"
    KNOWN_DEVICE=1
  fi
  if [[ $DEVICE == *$TARAKO* ]]; then
    DEVICE="Tarako"
    KNOWN_DEVICE=1
  fi
  if [[ $DEVICE == *$LEO* ]]; then
    DEVICE="Tarako"
    KNOWN_DEVICE=1
  fi
  
  if [ -z $DEVICE ]; then
    DEVICE="Unknown"
  fi
  
  if [ $KNOWN_DEVICE -eq 0 ]; then
    DEVICE="Unknown"
  fi
  
  echo -e "${LBLUE}Device detected as: $DEVICE${RESTORE}"
}

function Get_Gaia { #Get the gaia version from the directory
Debug "Get_Gaia"
  if [ -e $DIR/gaia/profile/webapps/settings.gaiamobile.org/application.zip ]; then
    unzip -FF $DIR/gaia/profile/webapps/settings.gaiamobile.org/application.zip resources/gaia_commit.txt -d $tempdir &> /dev/null &&
    commitfile=$tempdir/resources/gaia_commit.txt &&
    GAIA=$(head -n 1 $commitfile)
    
    if [ -z $GAIA ]; then
      GAIA="Unknown"
    fi
    
  else
    echo "Not able to find the gaia_commit file. This build may not contain a gaia folder."
    GAIA="Unknown"
  fi
}

function Get_Gecko { #Get the gecko version from the directory
Debug "Get_Gecko"
  if [ -e $app_ini ]; then
    for c in SourceStamp; do
      GECKO=$(grep "^ *$c" $app_ini | sed "s,.*=,,g") &> /dev/null
    done  
    
    if [ -z "$GECKO" ]; then
      for c in SourceRepository; do
      GECKO=$(grep "^ *$c" $app_ini | sed "s,.*=,,g") &> /dev/null
      done 
    fi
    
    if [ -z "$GECKO" ]; then
      GECKO="Unknown"
      return 1
    else
      return 0
    fi
  else
    echo "Couldn't find ${app_ini}."
    GECKO="Unknown"
    return 1
  fi
}

function Get_Version { #Get the build version from the directory
  VERZ=$(grep "Version=" $app_ini |  sed "/^Version= */!d; s///;q") &> /dev/null
  if [ -z $VERZ ]; then
    VERZ="Unknown"
  fi
}

function Get_Build_ID { #Get the build id from the directory
  BID=$(grep "BuildID=" $app_ini |  sed "/^BuildID= */!d; s///;q") &> /dev/null
  if [ -z $BID ]; then
    BID="Unknown"
  fi
}

function Get_Build_Info { #Get the build info using the above functions and make a temp directory to store the values in
Debug "Get_Build_Info"
  app_ini=$DIR/b2g/application.ini
  tempdir=$(mktemp -d -t revision.XXXXXX) || echo -e "${LRED}could not make temp directory${RESTORE}" 
  Get_Gaia 
  Get_Gecko
  Get_Version
  Get_Build_ID
}

function Print_Info { #Print basic info about the build we just flashed
  Debug "Print_Info"
  Get_Build_Info
  echo -e "${LBLUE}--------------------------------------------------"
  echo -e "Environmental Variables:"
  echo -e "Device: $DEVICE"
  echo -e "BuildID: $BID"
  echo -e "Gaia: $GAIA"
  echo -e "Gecko: $GECKO"
  echo -e "Version: $VERZ"
  echo -e "--------------------------------------------------${RESTORE}"

}

#-----------------------------------------#

function Main { #Call everything (Main loop)
Debug "Main"
  Color_Init
  Start_Timer
  #Init_Vars
  Determine_Build
  Check_Validity
  Get_Device_Type
  Check_Dir
  Check_For_Extractables
  Check_GG
  Flash
  echo -e "${LGREEN}done${RESTORE}"
  Print_Info
  End_Timer
  Analytics
  Cleanup
  exit 0
}
Init_Vars
Main

#!/bin/bash
DEBUG=0
clear
##########################Initialize###############################
function Init_Variables { #Initialise variables 
  Debug "Init_Variables"
  Color_Init
  Pick_Text_App
  Create_Temp_Directory
  DEF="${LBLUE}<${RESTORE}"
  HIDE_EDITOR=0
  USE_DIRECTORY=0
  QUICK=0
  DEVICE=""
  VERSION_2=""
  VERSION=""
  BUILD_ID=""
  GAIA=""
  GECKO=""
  DETECTED_VERSION=""
  GUESSED_DEVICE=""
  GUESSED_VERSION=""
  FIRMWARE=""
}

function Create_Temp_Directory { #Create a temporary place to store the files we pull / extract
  Debug "Create_Temp_Directory"
  TEMP_DIR=$(mktemp -d -t revision.XXXXXX) || DIE "${LRED}could not make temp directory${RESTORE}"
  Debug "TEMP_DIR: $TEMP_DIR"
 }

function Pick_Text_App { #Check if the user has scite, if not use gedit
  Debug "Pick_Text_App"
  TEXT_APP="gedit"
  command -v scite >/dev/null 2>&1 && 
  TEXT_APP="scite" || 
  TEXT_APP="gedit"
  
  return 0
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
  Debug "Color_Init"
  #echo -e "${GREEN}Hello ${CYAN}THERE${RESTORE} "
  return 0 # Success
}

function Get_Args { #Get flags for defining behavior
Debug "Get_Args"
  while getopts :td:q opt; do
    case $opt in
    t) HIDE_EDITOR=1
    ;;
    d) USE_DIRECTORY=1
      DROP_DIR=${OPTARG}
    ;;
    q) QUICK=1
    ;;
    v) DEBUG=1
    ;;
    *) Show_Usage
    ;;
    esac
  done
  
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

  echo "Plug in your device" &&
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
-v       :       Verbose (Shows debug progress messages)"
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
    if [[ -e $DIR/gaia*.zip ]]; then
    unzip -o -u $DIR/gaia*.zip gaia/profile/webapps/settings.gaiamobile.org/application.zip -d $TEMP_DIR 
    APP_ZIP=$TEMP_DIR/gaia/profile/webapps/settings.gaiamobile.org/application.zip 
    return 0
  else
    if [[ -e $DIR/gaia/profile/webapps/settings.gaiamobile.org/application.zip  ]]; then
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
    unzip -FF $APP_ZIP resources/gaia_commit.txt -d $TEMP_DIR # &&
    COMMIT_FILE=$TEMP_DIR/resources/gaia_commit.txt
    Debug "ls: $(ls)"
  else
    DIE "Can't find APP_ZIP: $APP_ZIP"
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
  if [[ -e $DIR/b2g*.tar.gz ]]; then
    cd $TEMP_DIR
    tar -zxvf $DIR/b2g*.tar.gz b2g/application.ini 
    cd $DIR
    APP_INI=$TEMP_DIR/b2g/application.ini 
    return 0
  else
    if [[ -e $DIR/b2g/application.ini ]]; then
      APP_INI=$DIR/b2g/application.ini
    else
      GECKO="Unknown"
      return 1
    fi
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
  for b in BuildID; do
      BUILD_ID=$(grep "^ *$b" $APP_INI | sed "s,.*=,,g")
  done  

  if [ -z "$BUILD_ID" ]; then
    BUILD_ID="Unknown"
  fi
}

function Get_Firmware_From_Device_Name { #Determine which firmware list to choose from based on the device name
  Debug "Get_Firmware_From_Device_Name"
  Print_Progress_Info
  #DETECTED_FIRMWARE=`adb shell getprop ro.build.inner.version`
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
  for d in Version; do
    DETECTED_VERSION=$(grep "^ *$d" $APP_INI | sed "s,.*=,,g")
  done
}

function Get_Branch_From_Version { #Get the branch number from a given build version number
Debug "Get_Branch_From_Version"
  
  VERSION_11="18.0"
  VERSION_12="26.0"
  VERSION_13="28.0"
  VERSION_TK="28.1"
  VERSION_14="30.0"
  VERSION_20="32."
  VERSION_21="33."
  VERSION_21B="34."
  VERSION_22="35."
  VERSION_22B="36."
  VERSION_23="37."
  
  CURRENT_MASTER="2.1"
  
  KNOWN_VERSION=0
  
  if [[ $1 == *$VERSION_11* ]]; then
    GUESSED_VERSION="1.1"
    KNOWN_VERSION=1
  fi
  
  if [[ $1 == *$VERSION_12* ]]; then
    GUESSED_VERSION="1.2"
    KNOWN_VERSION=1
  fi
  
  if [[ $1 == *$VERSION_13* ]]; then
    GUESSED_VERSION="1.3"
    KNOWN_VERSION=1
  fi
  
  if [[ $1 == *$VERSION_TK* ]]; then
    GUESSED_VERSION="1.3T"
    KNOWN_VERSION=1
  fi  
  
  if [[ $1 == *$VERSION_14* ]]; then
    GUESSED_VERSION="1.4"
    KNOWN_VERSION=1
  fi
  
  if [[ $1 == *$VERSION_20* ]]; then
    GUESSED_VERSION="2.0"
    KNOWN_VERSION=1
  fi
  
  if [[ $1 == *$VERSION_21* ]]; then
    GUESSED_VERSION="2.1"
    KNOWN_VERSION=1
  fi
  
  if [[ $1 == *$VERSION_21B* ]]; then
    GUESSED_VERSION="2.1"
    KNOWN_VERSION=1
  fi
  
  if [[ $1 == *$VERSION_22* ]]; then
    GUESSED_VERSION="2.2"
    KNOWN_VERSION=1
  fi
  
  if [[ $1 == *$VERSION_22B* ]]; then
    GUESSED_VERSION="2.2"
    KNOWN_VERSION=1
  fi
  if [[ $1 == *$VERSION_23* ]]; then
    GUESSED_VERSION="2.3"
    KNOWN_VERSION=1
  fi
  
  if [[ $GUESSED_VERSION == $CURRENT_MASTER ]]; then
    GUESSED_VERSION="$GUESSED_VERSION - Master"
  fi
  
  if [ $KNOWN_VERSION -eq 0 ]; then
    GUESSED_VERSION="Master"
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
  FLAME_FIRMWARE_1="v10E"
  FLAME_FIRMWARE_2="v10F-3"
  FLAME_FIRMWARE_3="v10G-2"
  FLAME_FIRMWARE_4="v121-2"
  
  DEFAULT_FIRMWARE=$FLAME_FIRMWARE_4
  
  if [ $QUICK -eq 1 ]; then
    FIRMWARE=$DEFAULT_FIRMWARE
    return 0
  fi
  
  echo -e "Which firmware version? Defaults to ${LBLUE}$DEFAULT_FIRMWARE${RESTORE} if left blank"
  echo -e "1) $(Is_Def $FLAME_FIRMWARE_4)\n2) $(Is_Def $FLAME_FIRMWARE_3)\n3) $(Is_Def $FLAME_FIRMWARE_2)\n4) $(Is_Def $FLAME_FIRMWARE_1)"
  read FLAME_FIRMWARE_CHOICE
  case $FLAME_FIRMWARE_CHOICE in
    1) FIRMWARE=$FLAME_FIRMWARE_4 ;;
    2) FIRMWARE=$FLAME_FIRMWARE_3 ;;
    3) FIRMWARE=$FLAME_FIRMWARE_2 ;;
    4) FIRMWARE=$FLAME_FIRMWARE_1 ;;
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

  Debug "Get_User_Agent"
  echo -e "Please get the ${LBLUE}User Agent${RESTORE} information by going to ${LYELLOW}www.whatsmyuseragent.com on the device${RESTORE} and include it in the bug${RESTORE}"
}
#--------------------------------

#--------------------------------
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
  echo -e "[B2G][Component][Location](Concise statement of the issue)" >> $file_name &&
  echo -e "\nDescription:\n(Expand upon the Summary - but not a copy of the Summary!)" >> $file_name &&
  echo -e "\n\nRepro Steps:" >> $file_name &&
  echo -e "1) Update a $DEVICE to $BUILD_ID" >> $file_name &&
  echo -e "2)\n3)\n4)\n\n" >> $file_name &&
  echo -e "Actual:\n(Describe the behavior you actually observed)" >> $file_name &&
  echo -e "\n\nExpected:\n(Describe the behavior you expected to have observed)\n" >> $file_name &&

  echo -e "Environmental Variables:" >> $file_name &&

  echo -e "Device: $DEVICE $VERSION_2" >> $file_name &&
  echo -e "Build ID: $BUILD_ID" >> $file_name &&
  echo -e "Gaia: $GAIA" >> $file_name &&
  echo -e "Gecko: $GECKO" >> $file_name &&
  echo -e "Version: $DETECTED_VERSION $VERSION" >> $file_name &&
  
  #if [ $SHOWRIL -eq 1 ]; then
  #echo "RIL Version:" $(head -n 1 $TEMP_DIR/libqc_b2g_ril.version) >> $file_name 
  #fi

  echo -e "Firmware Version:" $FIRMWARE >> $file_name &&
  echo -e "\nUser Agent: (Obtain this by going to www.whatsmyuseragent.com on the device browser)" >> $file_name &&
  echo -e "\n\nKeywords:\n\n\nNotes:\n\n\nRepro frequency: (2/3, 100%, etc.)\nLink to failed test case:\nSee attached: (screenshot, video clip, logcat, etc.)" >> $file_name &&

  $TEXT_APP $file_name &
}

function Print_Progress_Info { #Print a list at the top of the screen to show the current progress
  Debug "Print_Progress_Info"
  clear
  #Check_Unknowns
  echo -e "--------------------------------------------------"
  echo -e "Device:   ${LBLUE}$DEVICE${RESTORE}"
  echo -e "Branch:   ${LBLUE}$VERSION ${RESTORE}"
  echo -e "Version:  ${LBLUE}$DETECTED_VERSION${RESTORE}"
  echo -e "Firmware: ${LBLUE}$FIRMWARE${RESTORE}"
  echo -e "--------------------------------------------------"

}

function Print_Full_Info { #Print all the version info in the terminal (Should match what is in the bug template)
Debug "Print_Full_Info"
clear
echo -e "--------------------------------------------------"
echo -e "Environmental Variables:"
echo -e "Device: ${LBLUE}$DEVICE $VERSION_2${RESTORE}"
echo -e "BuildID: ${LBLUE}$BUILD_ID${RESTORE}"
echo -e "Gaia: ${LBLUE}$GAIA${RESTORE}"
echo -e "Gecko: ${LBLUE}$GECKO${RESTORE}"
echo -e "Version: ${LBLUE}$DETECTED_VERSION $VERSION ${RESTORE}"
echo -e "Firmware Version: ${LBLUE}$FIRMWARE${RESTORE}"
echo -e "--------------------------------------------------"
}

function Print_Info_From_Directory { #Print the info we got from the build directory
  Debug "Print_Info_From_Directory"
  clear
  echo -e "Directory: ${LBLUE}$DROP_DIR${RESTORE}"
  echo -e "--------------------------------------------------"
  echo -e "Environmental Variables"
  echo -e "BuildID: ${LBLUE}$BUILD_ID${RESTORE}"
  echo -e "Gaia: ${LBLUE}$GAIA${RESTORE}"
  echo -e "Gecko: ${LBLUE}$GECKO${RESTORE}"
  echo -e "Version: ${LBLUE}$DETECTED_VERSION ($GUESSED_VERSION)${RESTORE}"
  echo -e "--------------------------------------------------"

}

####################################################################


##############################MAIN##################################

function Get_Vars_From_Device { #Run the commands to get variables from a device
  DIR=$TEMP_DIR
  Start_ADB
  Pull_ApplicationZip_From_Device
  Pull_ApplicationINI_From_Device 
  Get_Device_Type
  Choose_Device
  Get_Firmware_From_Device_Name
    Main
  Print_Full_Info
  Get_User_Agent
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

Init_Variables
Get_Args "$@"
Choose_Work_Path



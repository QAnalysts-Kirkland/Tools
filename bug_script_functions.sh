#!/bin/bash
# Author: Roland Kunkel
# Edited: Oliver Nelson
# Date  : 8/2/2014
# 
# Updates:
#
#         2014-08-21 # We are no longer using [B2G] in titles for bug write-ups I.e updated generate_bug_template
#	  2014-09-03 # Changed master to 2.2, updated branch to include 35.0a1, updated user agents
#		     # Got rid of "recall", was causing weird glitches (master master master) when moving from Flame to Open_C
#		     # Seperated grabing the branch information into it's own function (more than 1 line of code)
#         2014-09-10 # Changed Flame firmware to ask user in cases of unknown
#                    # Provided example for comman syntax / naming conventions
#         2014-09-12 # Changed the firmware command to work with the KK base, reworked to support older firmware versions as well // flame
#         2014-09-24 # added shopt -s nocasematch to handle cases where base reports 'flame' instead of 'Flame'
#         2014-09-29 # removed support for old builds (1.4 and prior), now plays nice with GG script
#	  2014-10-20 # added support for Firmware v184 and v188

#Declare Variables
MASTER="2.2"
DEVICE=""
gDEVICE="Unknown"
BRANCH=""
gBRANCH="Unknown"
USER_AGENT=""
FIRMWARE=""
gFIRMWARE="Unknown"
file_name=""

function get_source {
  while read line           
  do           
    parse=$(echo $line | cut -c16-27)
    if [[ $parse ==  'device-flame' ]]; then
      GONK=$(echo $line | cut -c77-116)
      #echo -e $revision
    fi
  done <'sources'
}

# Helper for Pull_Device_Info
# Grabs the application.ini for future file operations
function Pull_AppIni {
  echo "adb pull application.zip" &&
  adb pull /system/b2g/application.ini &> /dev/null ||
  return 1 &&
  return 0
}
# Helper for Pull_Device_Info
# Grabs the application.zip for future file operations
function Pull_AppZip {
  echo "adb pull application.zip" &&
  adb pull /system/b2g/webapps/settings.gaiamobile.org/application.zip &> /dev/null || 
  adb pull /data/local/webapps/settings.gaiamobile.org/application.zip &> /dev/null ||
  return 1 &&
  return 0
}
# Grabs the needed Gecko and Gaia files
function Pull_Device_Info {
  echo "Pulling device information..."
  Pull_AppZip || echo "Error pulling gaia file" &&
  Pull_AppIni || echo "Error pulling application.ini" &&
  echo "unzip application.zip" &&
  unzip application.zip resources/gaia_commit.txt &> /dev/null || echo "Error extracting from zip"
}
# Populates Branch (DRY function)
function Populate_Branch {
    # Populate Branch
    case $VERSION in
        *'28.0'*) BRANCH="1.3"; USER_AGENT="Mozilla/5.0 (Mobile; rv:28.0) Gecko/28.0 Firefox/28.0";;
        *'30.0'*) BRANCH="1.4"; USER_AGENT="Mozilla/5.0 (Mobile; rv:30.0) Gecko/30.0 Firefox/30.0";;
        *'32.0'*) BRANCH="2.0"; USER_AGENT="Mozilla/5.0 (Mobile; rv:32.0) Gecko/32.0 Firefox/32.0";;
      *'33.0a1'*) BRANCH="2.1"; USER_AGENT="Mozilla/5.0 (Mobile; rv:33.0) Gecko/33.0 Firefox/33.0";;
      *'34.0a1'*) BRANCH="2.1"; USER_AGENT="Mozilla/5.0 (Mobile; rv:34.0) Gecko/34.0 Firefox/34.0";;
      *'34.0a2'*) BRANCH="2.1"; USER_AGENT="Mozilla/5.0 (Mobile; rv:34.0) Gecko/34.0 Firefox/34.0";;
        *'34.0'*) BRANCH="2.1"; USER_AGENT="Mozilla/5.0 (Mobile; rv:34.0) Gecko/34.0 Firefox/34.0";;
      *'35.0a1'*) BRANCH="2.2"; USER_AGENT="Mozilla/5.0 (Mobile; rv:35.0) Gecko/35.0 Firefox/35.0";;
      *'36.0a1'*) BRANCH="2.2"; USER_AGENT="Mozilla/5.0 (Mobile; rv:36.0) Gecko/36.0 Firefox/36.0";;
               *) BRANCH=$gBRANCH;;
    esac
}

# Grab frunction for directories
function Grab_From_Directory {
  # Start or print error message
  if [ -d "$DIRECTORY" ]; then
    #Populate BuildID
    for a in BuildID; do
      BUILDID=$(grep "^ *$a" "$DIRECTORY/b2g/application.ini" | sed "s,.*=,,g")
    done
    #Unzip gaia_commit.txt for future file operations
    unzip -o -j -q "$DIRECTORY/gaia/profile/webapps/settings.gaiamobile.org/application.zip" "resources/gaia_commit.txt" -d "$DIRECTORY" "$DIRECTORY"
    #Populated Gaia
    GAIA=$(head -n 1 "$DIRECTORY/gaia_commit.txt")
    #Populate Gecko
    for a in SourceStamp; do
      GECKO=$(grep "^ *$a" "$DIRECTORY/b2g/application.ini" | sed "s,.*=,,g")
    done
    #Populate Version
    for a in Version; do
      VERSION=$(grep "^ *$a" "$DIRECTORY/b2g/application.ini" | sed "s,.*=,,g")
    done
    # Populate Branch
    Populate_Branch
    #Print Vars 
    echo -e "\nEnvironmental Variables:"
    echo -e "-----------------------"
    echo -e "BuildID: $BUILDID"
    echo -e "Gaia: $GAIA"
    echo -e "Gecko: $GECKO"
    echo -e "Version: $VERSION"
    echo -e "-----------------------"
  else
    echo -e "ERROR: $DIRECTORY is not a valid build path..."
  fi
}
# Grab frunction for devices
function Grab_From_Device {
  #Pull Variables
  Pull_Device_Info
  # Populated Gaia
  GAIA=$(head -n 1 "./resources/gaia_commit.txt")
  # Populate BuildID
  for a in BuildID; do
    BUILDID=$(grep "^ *$a" "application.ini" | sed "s,.*=,,g")
  done
  # Populate Gecko
  for a in SourceStamp; do
    GECKO=$(grep "^ *$a" "application.ini" | sed "s,.*=,,g")
  done
  # Populate Version
  for a in Version; do
    VERSION=$(grep "^ *$a" "application.ini" | sed "s,.*=,,g")
  done
  # Populate Branch
  Populate_Branch
  # Temps to make detecting device easier
  DETECTED_DEVICE=`adb shell getprop ro.product.model`
  BURI="msm7627a"
  OPEN_C="Open C"
  FLAME="Flame"
  TARAKO="sp6821a"
  shopt -s nocasematch
  # Get FIRMWARE
  if [[ $DETECTED_DEVICE == *$FLAME* ]]; then
       DEVICE="Flame"
       set -e &&
       raw=$(adb shell getprop ro.bootloader)
       # Set Firmware
       case $raw in
         *'L1TC00011220'*) FIRMWARE="V122";;
	 *'L1TC00011230'*) FIRMWARE="V123";;
         *'L1TC10011800'*) FIRMWARE="V180";;
         *'L1TC00011840'*) FIRMWARE="V184";;
         *'L1TC00011880'*) FIRMWARE="V188";;
         *) echo "Unknown firmware, enter now: (V180)"; 
	     read FIRMWARE;;
       esac
  elif [[ $DETECTED_DEVICE == *$BURI* ]]; then
      DEVICE="Buri"
      FIRMWARE="v1.2device.cfg" # This is the latest firmware of the discontinued Buri
  elif [[ $DETECTED_DEVICE == *$OPEN_C* ]]; then
      DEVICE="Open_C"
      FIRMWARE="P821A10v1.0.0B06_LOG_DL" # This is the latest firmware of the discontinued Open_C
  elif [[ $DETECTED_DEVICE == *$TARAKO* ]]; then
      DEVICE="Tarako"
      FIRMWARE="SP6821a-Gonk-4.0-5-12" # This is the latest firmware of the discontinued Tarako
  else 
      DEVICE=$gDEVICE
      FIRMWARE=$gFIRMWARE
  fi
  # Get Memory Settings
  # Get Sources Gonk Revision // put '(' ')' around the second part of the or, or the second && with go off
  adb pull '/system/sources.xml' sources &> /dev/null && get_source || (echo "error pulling gonk" && GONK="Error: Cannot pull sources file")

  
  # Print variables
  echo -e "Environmental Variables:"
  echo -e "----------------------------------------------"
  echo -e "Device: $DEVICE $BRANCH"
  echo -e "BuildID: $BUILDID"
  echo -e "Gaia: $GAIA"
  echo -e "Gecko: $GECKO"
  echo -e "Gonk: $GONK"
  echo -e "Version: $VERSION ($BRANCH)"
  echo -e "Firmware: $FIRMWARE"
  echo -e "User Agent: $USER_AGENT"
  echo -e "----------------------------------------------"
  # Apply master?
  if [[ $BRANCH == *$MASTER* ]]; then
	BRANCH="$BRANCH Master"
  fi
}
# Generates the bug template and writes it to the file
# There should not be any operations performed, everything should be known
function Generate_Template {
  echo -e "Summary (title) Field:
[Component][Location](Concise statement of the issue) 
  
Description:
(Expand upon the Summary - but not a copy of the Summary!)
   
Repro Steps:
1) Update a $DEVICE device to BuildID: $BUILDID
2)
3)
4)
  
Actual:
(Describe the behavior you actually observed)
  
Expected: 
(Describe the behavior you expected to have observed)
  
Environmental Variables:
Device: $DEVICE $BRANCH
BuildID: $BUILDID
Gaia: $GAIA
Gecko: $GECKO
Gonk: $GONK
Version: $VERSION ($BRANCH)
Firmware: $FIRMWARE
User Agent: $USER_AGENT
  
Notes:
  
Repro frequency: (2/3, 100%, etc.)
Link to failed test case:
See attached: (screenshot, video clip, logcat, etc.)" >> $file_name
}
# Init function, set all presets and pull needed files
function Init {
  DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  cd 
  # Create temp directory to store generated bug template
  # This prevents people overwritting each other when using this file from Needed_Scripts/
  DIR=$(mktemp -d -t revision.XXXXXX) || echo "could not make temp directory"
  file_name=$DIR/bugtemplate_$(date +%Y%m%d-%H%M%S).txt
  cd $DIR # Habit safety check
}

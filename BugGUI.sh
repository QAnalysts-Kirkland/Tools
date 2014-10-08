#!/bin/bash
# Author: Roland Kunkel
# Date  : Unknown
#
# Usage: ./PATH/BugGUI.sh BUILD_DIRECTORY
#
# Note
# 
# Updates: 
#
#         2014-09-10 # Added a author header to try and keep beter track of how ofter I edit / update scripts
#                    # uncommented the wait command, fixed a bunch of user case errors
#         2014-09-29 # added support for pulling gonk, error msg is produced if unable to pull 

# This is where the functions are stored currently, the purpose of this file is to only manage the GUI portion
# of the script
. '/mnt/builds/Needed_Scripts/bug_script_functions.sh'

# Init
Init

# Determine where to pull from
if [ -z "$1" ]; then
  echo -e "Path not specified..."
  echo -e "Setting device as path..."
  DIRECTORY="DEVICE"
  # Special case for device setup 
  echo -e "Plug in your device" &&
    adb wait-for-device && #in#
    adb root && adb remount &&
    echo -e "Found device"
    # Get Variables
    Grab_From_Device
else
  echo -e "\nPath is specified..."
  echo -e "Pulling from $1"
  DIRECTORY=$1
  Grab_From_Directory
fi

# Create a preview to aid user
PREVIEW=$(echo -e "Enviromental Variables:
----------------------------------------
Device: $DEVICE $BRANCH
BuildID: $BUILDID
Gaia: $GAIA
Gecko: $GECKO
Gonk: $GONK
Version: $VERSION ($BRANCH)
Firmware: $FIRMWARE
User Agent: $USER_AGENT")

# Create GUI
GUI=$(yad --text-align center --geometry=600x590+300+150\
          --title "Mozilla Bug Creation Tool"\
          --form --columns 1\
          	--field "Device" "$DEVICE $BRANCH"\
          	--field "BuildID" "$BUILDID"\
          	--field "Gaia" "$GAIA"\
          	--field "Gecko" "$GECKO"\
                --field "Gonk" "$GONK"\
          	--field "Version" "$VERSION ($BRANCH)"\
          	--field "Firmware" "$FIRMWARE"\
          	--field "User Agent" "$USER_AGENT"\
		--field "Preview:TXT" "$PREVIEW"\
		--field "Generate Bug Template:CHK" "TRUE"
		) 

# Test if user wants to generate bug template
# Note -- This only works because there is 1 checkbox, anymore would need read input to array and parse the results by index
if echo "$GUI" | grep -q "TRUE"; then
  # Set Text Editor
  TEXT_APP=""
  command -v scite >/dev/null 2>&1 && 
    TEXT_APP="scite" || TEXT_APP="gedit"
  echo "Creating template..."
  Generate_Template
  $TEXT_APP $file_name & # & forks process and returns terminal controls
fi


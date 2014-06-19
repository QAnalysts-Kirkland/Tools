#!/bin/bash
#This script changes Facebook's 24 hour sync time to 5 minutes for testing purposes.
clear

function Setup {
  TEMP_FOLDER=~/calendar_temp

  if [ -e $TEMP_FOLDER ]; then
  rm -r $TEMP_FOLDER
  fi
  if [ ! -e $TEMP_FOLDER ]; then
  mkdir $TEMP_FOLDER
  fi
  cd $TEMP_FOLDER
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
function DoWork {
echo -e "${LYELLOW}Connect the device${RESTORE}" &&
  set -e && 
  adb wait-for-device &&
  adb root &&
  adb remount &&
  echo -e "${LBLUE}Pulling...${RESTORE}" &&
  adb pull /system/b2g/webapps/communications.gaiamobile.org/application.zip &&
  chmod +x application.zip &&
  mv application.zip application_temp.zip
  echo -e "${LBLUE}Verifying integrity...${RESTORE}" &&
  zip -FF application_temp.zip --out application.zip &> /dev/null &&
  echo -e "${LBLUE}Unzipping...${RESTORE}" &&
unzip -u application.zip contacts/config.json -d . &&
echo -e "${LBLUE}Changing the Facebook Sync period from 24 hours to 5 minutes...${RESTORE}" &&
perl -pi -e 's/"facebookSyncPeriod": 24,/"facebookSyncPeriod": 0.083,/g' contacts/config.json &&
echo -e "${LBLUE}Repacking...${RESTORE}" &&
zip -r application.zip /contacts/config.json &&
echo -e "${LBLUE}Pushing...${RESTORE}" &&
adb shell "rm /system/b2g/webapps/communications.gaiamobile.org/application.zip" &&
  adb push application.zip /system/b2g/webapps/communications.gaiamobile.org/ &&
  echo -e "${LBLUE}Cleaning up...${RESTORE}" &&
  rm -r $TEMP_FOLDER &&
  echo -e "${LGREEN}Done.${RESTORE}"
  }

Color_Init
Setup
DoWork
  
  #perl -pi -e 's/syncFrequency: 15,/syncFrequency: 5,/g' js/store/setting.js &&

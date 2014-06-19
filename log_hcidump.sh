#!/bin/bash


LOOP=0
if [ -n $1 ]; then
  TITLE="_$1"
else
  TITLE=""
fi

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

function Push_hcidump {
  echo "Pushing hcidump to device..."
if [ -e /mnt/builds/Needed_Scripts/hcidump ]; then
  adb wait-for-device &&
  adb root &&
  adb remount &&
  adb remount &&
  adb push /mnt/builds/Needed_Scripts/hcidump /system/bin &&
  adb shell chmod 777 /system/bin/hcidump || exit 1
else
  echo "Unable to find the hcidump executable in /mnt/builds/Needed_Scripts/"
  exit 1
fi

}

function Print_Info {
    LOGSIZE=$(du -hcscs ~/log | awk '{print $1}' | grep -v Use | sort -n | tail -1 )
    clear
    echo -e "Logging to ${LBLUE}$file_name${RESTORE}. ${LYELLOW}\nLog directory size: $LOGSIZE ${RESTORE}"
    echo "Press CTRL + C to end."
}

function File_Setup {
  if [ ! -d ~/log ]; then
  mkdir ~/log || exit 1
  fi
  FIRST=1
  file_name=~/log/hcidump_$(date +%Y%m%d_%H%M)$TITLE.txt
}

function Get_Time {
TIME=$(date +%Y%m%d_%H:%M:%S)
}

function Main_Loop {
  echo "Starting... Make sure device is connected."
  adb wait-for-device
  Get_Time
  echo "LOG BEGINS AT $TIME" >> $file_name &&
  echo -e "${LGREEN}LOG BEGINS AT ${RESTORE}${WHITE}$TIME${RESTORE}"
  gnome-terminal -e "tail -n 50 -f $file_name"
  while [ $LOOP -eq 0 ]; do
    adb wait-for-device
    if [ $FIRST -eq 0 ]; then
      Get_Time
      echo "---------------RESUME AT: $TIME------------------" >> $file_name
      echo -e "${LGREEN}RESUME AT: ${RESTORE}${WHITE}$TIME${RESTORE}"
    else
      FIRST=0;
    fi
    #OUTPUT="$(date +%Y%m%d_%H:%M:%S) : $(adb logcat)"
    adb shell hcidump --ascii -t >> $file_name && 
    Get_Time &&
    echo "----------------PAUSE AT: $TIME-------------------" >> $file_name &&
    echo -e "${CYAN}PAUSE AT: ${RESTORE}${WHITE}$TIME${RESTORE}"
    echo -e "${LRED}Lost connection. Retrying...${RESTORE}"
    sleep 1s
  done
}

Color_Init
Push_hcidump
File_Setup
Print_Info
Main_Loop

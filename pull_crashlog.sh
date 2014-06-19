#!/bin/bash
#Pull crash log

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

function Print_Info {
    LOGSIZE=$(du -hcscs $dir_name | awk '{print $1}' | grep -v Use | sort -n | tail -1 )
    clear
    echo -e "Logging to ${LBLUE}$dir_name${RESTORE}. ${LYELLOW}\nLog directory size: $LOGSIZE ${RESTORE}"
}

function File_Setup {
  TIME=$(date +%Y%m%d_%H:%M:%S)
  
  if [ ! -d ~/log ]; then
  mkdir ~/log || exit 1
  fi
  
  if [ ! -d ~/log/Crash_Log_$TIME ]; then
  mkdir ~/log/Crash_Log_$TIME || exit 1
  fi
  
  FIRST=1
  dir_name=~/log/Crash_Log_$TIME
}

function Start_ADB {
  set -e &&
  echo "Plug in your device" &&
  adb wait-for-device &&
  adb root &&
  adb remount &&
  echo "Found device"
}

function Pull_CrashLog {
  adb pull /data/b2g/mozilla/Crash\ Reports/ $dir_name || echo "No logs found"
  #adb pull /data/b2g/mozilla/Crash\ Reports/submitted/ $dir_name || echo "No Submitted logs"
}

function Generate_Link_Pending {
  if [ -e $dir_name/pending ]; then
    cd $dir_name/pending
    echo -e "${LYELLOW}Pending logs: (Please enable wifi on the device to activate links)${RESTORE}"
    for i in *
    do
      if test -f "$i"
      then
      lfile="$i"
      lfile=${lfile#*bp-}
      lfile=${lfile%.*}
      echo -e "${LYELLOW}https://crash-stats.mozilla.com/report/index/$lfile${RESTORE}"
      fi
    done
  fi
}

function Generate_Link_Submitted {
  if [ -e $dir_name/submitted ]; then
    cd $dir_name/submitted
    echo -e "${LBLUE}Submitted logs:${RESTORE}"
    for i in *
    do
      if test -f "$i"
      then
      lfile="$i"
      lfile=${lfile#*bp-}
      lfile=${lfile%.*}
      
      echo -e "${LBLUE}https://crash-stats.mozilla.com/report/index/$lfile${RESTORE}"
      fi
    done
  fi
}

function Generate_Links {
echo "---------------------------------------------------------------------------------"
lfile=""
  Generate_Link_Pending
  Generate_Link_Submitted
}

Color_Init
File_Setup
Print_Info
Pull_CrashLog
Generate_Links

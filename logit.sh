#!/bin/bash
###################################################################
# Author: Lionel Mauritson                                        #
# Email: lionel@secretzone.org                                    #
# Contributors:                                                   #
#                                                                 #
# Last updated: 6/18/2014                                         #
###################################################################

TITLE=""

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
  file_name=~/log/logcat_$(date +%Y%m%d_%H%M)$TITLE.txt
}

function Get_Time {
TIME=$(date +%Y%m%d_%H:%M:%S)
}

function Main_Loop {
  local LOOP=0
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
    adb logcat -v threadtime >> $file_name && 
    Get_Time &&
    echo "----------------PAUSE AT: $TIME-------------------" >> $file_name &&
    echo -e "${CYAN}PAUSE AT: ${RESTORE}${WHITE}$TIME${RESTORE}"
    echo -e "${LRED}Lost connection. Retrying...${RESTORE}"
    sleep 1s
  done
}

function Show_Usage {
echo " 
-n <title> | Add a name to the log
-c         | Clears the back log before starting"

}

function Get_Args { #Get flags for defining behavior
  while getopts :n:c opt; do
    case $opt in
    n) TITLE="_${OPTARG}"
    ;;
    c) Clear_Old_Log
    ;;
    *) Show_Usage
    ;;
    esac
  done
  
}



function Clear_Old_Log {
  echo "Clearing log"
  adb logcat -c
}


Color_Init
Get_Args "$@"
File_Setup
Print_Info
Main_Loop

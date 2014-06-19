#!/bin/bash

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

function Error {
echo $1
exit 1
}

function Main {
LOOP=1
if [ ! -d ~/log ]; then
mkdir ~/log || Error "Unable to make log directory. Do you have write permissions?"
fi

  file_name=~/log/firewatch_$(date +%Y%m%d_%H%M)$TITLE.txt
echo "Starting... Make sure device is connected."

  adb wait-for-device
  adb root
  adb remount
  echo "LOG BEGINS AT $(date +%Y%m%d_%H:%M:%S)" >> $file_name
    adb shell "
  su &
  b2g-info || return 1
  " >> $file_name || Error "An error occured. Please try again."
  gnome-terminal -e "tail -n 50 -f $file_name"
while [ $LOOP ]; do
  adb wait-for-device
  
  adb shell "b2g-info || return 1" >> $file_name || Error "An error occured and the log will now end"
  echo "----------------$(date +%Y%m%d_%H:%M:%S)-------------------" >> $file_name
  LOGSIZE=$(du -hcscs ~/log | awk '{print $1}' | grep -v Use | sort -n | tail -1 )
  clear
  echo -e "Logging to $file_name. ${LYELLOW}\nLog directory size: $LOGSIZE ${RESTORE}"
  echo "Press CTRL + C to end."
  sleep 1s
done
echo "----------------LOG ENDS AT: $(date +%Y%m%d_%H:%M:%S)-------------------" >> $file_name
}

Color_Init
Main

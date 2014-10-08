#!/bin/bash
# author:  Roland Kunkel
# date  :  09-04-2014
#
# purpose:  To make ota as simple as possible .. added prompts and limited user interaction
#
# updates:  09-04-2014 :: File was created
#           09-26-2014 :: added an if statement to aid in JB or KK ota's
#                      :: don't put $x varibles in single quotes use "" or seperate from the string

# functions

function OTA_SETUP {
  cd /mnt/builds/Needed_Scripts/B2G-flash-tool/
  sleep 1s
  ./change_channel.sh -v $1
  sleep 1s
  if [[ $BASE == *'JB'* ]]; then
    echo "doing JB"
    ./change_ota_url.sh -u 'https://aus4.mozilla.org/update/3/B2G/28.0/20140709000201/flame/en-US/'$1'/Boot2Gecko%202.0.0.0-prerelease/default/default/update.xml?force=1'
  else # KK base
    echo "doing KK"
    ./change_ota_url.sh -u 'https://aus4.mozilla.org/update/3/B2G/34.0a2/20140918232119/flame/en-US/'$1'/Boot2Gecko%202.1.0.0-prerelease%20(SDK%2019)/default/default/update.xml'
  fi
  sleep 1s
}

function TO_SETUP {
  case $TO in
    1.4) OTA_SETUP nightly-b2g30;;
    2.0) OTA_SETUP nightly-b2g32;;
    2.1) OTA_SETUP aurora;;
    2.2) OTA_SETUP nightly;;
      *) echo "Something has gone terribly wrong!";;
  esac
}

# variables
FROM=''
TO=''
BASE=''

# Main

echo -e "Plug in your device" &&
  adb wait-for-device &&
  adb root && adb remount &&
  echo -e "Found device" #in#

echo "---------- Menu ----------"
echo "     ----- Base -----
  1. JB - (v123 and prior)
  2. KK - (v165 and later)
"

while true
do
  read BASE
  case $BASE in
    1) BASE='JB'; break;;
    2) BASE='KK'; break;;
    *) echo "Invalid selection";;
  esac
done
printf "\033c"

echo "---------- Menu ----------"
echo "     ----- From -----
  1. 1.4
  2. 2.0
  3. 2.1
  4. 2.2
"
while true
do
  read FROM
  case $FROM in
    1) FROM='1.4'; break;;
    2) FROM='2.0'; break;;
    3) FROM='2.1'; break;;
    4) FROM='2.2'; break;;
    *) echo "Invalid selection";;
  esac
done
printf "\033c"

echo "---------- Menu ----------"
echo "     -----  To  -----
  1. 2.0
  2. 2.1
  3. 2.2
"

while true
do
  read TO
  case $TO in
    1) TO='2.0'; break;;
    2) TO='2.1'; break;;
    3) TO='2.2'; break;;
    *) echo "Invalid selection";;
  esac
done
printf "\033c"

echo "Performing a $BASE OTA from $FROM to $TO..."

# we assume the user has selected their correct starting Branch
case $FROM in 
  1.4) TO_SETUP;;
  2.0) TO_SETUP;;
  2.1) TO_SETUP;;
  2.2) TO_SETUP;;
    *) echo "Something has gone terribly wrong!";;
esac
  
   


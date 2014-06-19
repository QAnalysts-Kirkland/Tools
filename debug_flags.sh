#!/bin/bash
set -e

function USAGE {
  echo "-r        ril.debugging"
  echo "-m        mms.debugging"
  echo "-n        network.debugging"
  echo "-s        services.push.debug"
  exit 1
}

function Wait {
  adb remount &&
  echo "Waiting for device" &&
  adb wait-for-device &&
  PREFS_JS=$(adb shell echo -n "/data/b2g/mozilla/*.default")/prefs.js &&
  adb pull $PREFS_JS &&
  return 0
}

function Start {
  adb shell stop b2g &&
  adb push prefs.js $PREFS_JS &&
  adb shell start b2g &&
  return 0
}

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  cd $SCRIPT_DIR

  if [ -z $1 ]; then
    USAGE
  fi
  
  Wait
  

while getopts :rmns opt; do
  case $opt in
  r) echo 'user_pref("ril.debugging.enabled", true);' >> prefs.js
     echo 'user_pref("ril.debugging.enabled", true);' 
  ;;
  m) echo 'user_pref("ril.debugging.enabled", true);' >> prefs.js 
     echo 'user_pref("mms.debugging.enabled", true);' 
  ;;
  n) echo 'user_pref("network.debugging.enabled", true);' >> prefs.js
     echo 'user_pref("network.debugging.enabled", true);'
  ;;
  s) echo 'user_pref("services.push.debug",true)' >> prefs.js
     echo 'user_pref("services.push.debug",true)'
  ;;
  *) USAGE
  ;;
  esac
done

  Start


echo "done"
exit 0

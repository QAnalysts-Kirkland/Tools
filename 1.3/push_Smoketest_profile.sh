#!/bin/bash

# This script pushes the smoketest profile to the device, needs to be ran from where the profile is kept.
 
echo "checking for device"
 adb wait-for-device &&
 
 adb remount &&
echo "pushing local..."
 adb push local /data/local &&
echo "pushing b2g..."
 adb push b2g /data/b2g &&
echo "pushing misc..."
 adb push misc /data/misc &&
echo "pushing internal storage..."
 adb push sdcard0 /storage/sdcard0 &&
 adb shell stop b2g &&
 adb shell start b2g &&
echo "done."

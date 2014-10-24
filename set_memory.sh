#!/bin/bash         
 # Author: Roland Kunkel 
 # Date: 7/17/2014
 
# Notes 
# 	Calling This file: $ dir/ ./set_memory.sh
# 	Displays current memory setting to user
#
#	Menu prompts user for desired mem setting
#	512
#	273
#	0 - Exit - resets device without changing memory settings

# UPDATE 7/24/2014
 # Added option to set devices memory to 319m
 # Updated prompt, variable setting

echo "Please plug in device..."
adb wait-for-device
adb devices
adb reboot bootloader

echo "Current Memory Setting "
echo "---------------------- "
fastboot getvar mem
echo ""

Y=-1
while true; do
    case $Y in
        1* ) m=273; echo $m; echo ""; break;;
	2* ) m=319; echo $m; echo ""; break;;	
	3* ) m=512; echo $m; echo ""; break;;
	
        0* ) m=-1; break;;
        * )	echo "------ menu ------"
		echo "1: 273"
		echo "2: 319"
		echo "3: 512"
		echo "0: exit"
		echo ""
		read -p "Please select memory level: " Y
		echo "";;
    esac
done

if [[ $m -eq -1 ]]; then
  echo "Not setting memory..."
else
  fastboot oem mem $m
fi
fastboot reboot


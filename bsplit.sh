#!/bin/bash
###################################################################
# Author: Lionel Mauritson                                        #
# Email: lionel@secretzone.org                                    #
# Last updated: 6/25/2014                                         #
###################################################################

DEBUG=1
DROP_DIR1=$1
DROP_DIR2=$2
SAVE_DIR=~/Desktop/gecko_gaia_split
FLAG=$3
SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )

if [ -z $FLAG ]; then
  FLAG=0
fi

function Check_Validity {
Debug "Check_Validity"

  if [ -z $DROP_DIR1 ]; then
    echo "No path specified"
    echo "Usage: bsplit /path/to/build/older_build/ /path/to/build/newer_build/"
    exit 1
  fi
  if [ -z $DROP_DIR2 ]; then
    echo "No path specified"
    echo "Usage: bsplit /path/to/build/older_build/ /path/to/build/newer_build/"
    exit 1
  fi
  if [ ! -e $DROP_DIR1 ]; then
    echo "Invalid path"
    echo "Usage: bsplit /path/to/build/older_build/ /path/to/build/newer_build/"
    exit 1
  fi
  if [ ! -e $DROP_DIR2 ]; then
    echo "Invalid path"
    echo "Usage: bsplit /path/to/build/older_build/ /path/to/build/newer_build/"
    exit 1
  fi
  
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

function Debug {
if [ $DEBUG -eq 1 ]; then
  echo -e "DEBUG: ${LGRAY}$1${RESTORE}"
fi
}

function Check_Dir { 
Debug "Check_Dir"

  if [ -e $DROP_DIR1/b2g-distro/ ]; then
    DIR1=$DROP_DIR1/b2g-distro/
  else
    if [ -e $DROP_DIR1 ]; then
    DIR1=$DROP_DIR1
    else
      echo "bad DROP_DIR1: $DROP_DIR1"
    fi
  fi
    if [ -e $DROP_DIR2/b2g-distro/ ]; then
    DIR2=$DROP_DIR2/b2g-distro/
  else
    if [ -e $DROP_DIR2 ]; then
    DIR2=$DROP_DIR2
    else
      echo "bad DROP_DIR2: $DROP_DIR2"
    fi
  fi

}

function Check_For_Extractables {
Debug "Check_For_Extractables"
cd $DIR1

  if [ -e gaia.zip ]; then
    echo "Found gaia, extracting..."
    unzip -o -u gaia.zip &> /dev/null
  fi

  if [ -e b2g*.tar.gz ]; then
  echo "Found gecko, extracting...."
    tar -xzvf b2g*.tar.gz &> /dev/null
  fi
cd $DIR2

  if [ -e gaia.zip ]; then
    echo "Found gaia, extracting..."
    unzip -o -u gaia.zip &> /dev/null
  fi

  if [ -e b2g*.tar.gz ]; then
  echo "Found gecko, extracting...."
    tar -xzvf b2g*.tar.gz &> /dev/null
  fi
}

function Split {
Debug "Split"
OLD_GAIA_NEW_GECKO="Last_Working_Gaia_First_Broken_Gecko"
OLD_GECKO_NEW_GAIA="First_Broken_Gaia_Last_Working_Gecko"

if [ ! -e $SAVE_DIR ]; then
  mkdir $SAVE_DIR
fi

if [ ! -e $SAVE_DIR/$OLD_GAIA_NEW_GECKO/ ]; then
  mkdir $SAVE_DIR/$OLD_GAIA_NEW_GECKO/
else
  rm -r $SAVE_DIR/$OLD_GAIA_NEW_GECKO/
  mkdir $SAVE_DIR/$OLD_GAIA_NEW_GECKO/
fi

if [ ! -e $SAVE_DIR/$OLD_GECKO_NEW_GAIA/ ]; then
  mkdir $SAVE_DIR/$OLD_GECKO_NEW_GAIA/
else
  rm -r $SAVE_DIR/$OLD_GECKO_NEW_GAIA/ 
  mkdir $SAVE_DIR/$OLD_GECKO_NEW_GAIA/ 
fi


echo "Swapping gaia and gecko and making two new builds..."
cp -r $DIR1/gaia $SAVE_DIR/$OLD_GAIA_NEW_GECKO/ &&
cp -r $DIR1/b2g $SAVE_DIR/$OLD_GECKO_NEW_GAIA/ &&
cp -r $DIR2/gaia $SAVE_DIR/$OLD_GECKO_NEW_GAIA/ &&
cp -r $DIR2/b2g $SAVE_DIR/$OLD_GAIA_NEW_GECKO/
clear
echo "Done. The builds are made and in $SAVE_DIR"
}

function Show_Both_Vars {
Debug "Show_Both_Vars"
#cd $SCRIPTPATH
if [ -e $SCRIPTPATH/bug2.sh ]; then
  cd $SCRIPTPATH
  BUG_SC=$SCRIPTPATH/bug2.sh
  CMD=-qtgd
  DIR_1='/home/flash/Desktop/gecko_gaia_split/First_Broken_Gaia_Last_Working_Gecko'
  DIR_2='/home/flash/Desktop/gecko_gaia_split/Last_Working_Gaia_First_Broken_Gecko'
  GET_1=$($BUG_SC $CMD $DIR_1)
  GET_2=$($BUG_SC $CMD $DIR_2)
  
  GET_GAIA1=$(echo $GET_1 | grep gaia )
  GET_GECKO1=$(echo $GET_1 | grep gecko )
  GET_GAIA2=$(echo $GET_2 | grep gaia )
  GET_GECKO2=$(echo $GET_2 | grep gecko )
  echo -e "Last_Working_Gaia_First_Broken_Gecko\n"
  echo $GET_GAIA1
  echo $GET_GECKO1
  echo -e "First_Broken_Gaia_Last_Working_Gecko\n"
  echo $GET_GAIA2
  echo $GET_GECKO2

fi

}

Color_Init
Check_Validity
Check_Dir
Check_For_Extractables
Split
Show_Both_Vars




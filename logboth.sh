#!/bin/bash
###################################################################
# Author: Lionel Mauritson                                        #
# Email: lionel@secretzone.org                                    #
# Last updated: 6/18/2014                                         #
###################################################################

gnome-terminal -e "/mnt/builds/Needed_Scripts/firewatch.sh $1" &
gnome-terminal -e "/mnt/builds/Needed_Scripts/logit.sh -n $1"

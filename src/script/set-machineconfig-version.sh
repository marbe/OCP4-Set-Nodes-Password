#!/bin/bash
################################################################################
#                        set-machineconfig-version.sh                          #
#                                                                              #
# This script changes the ignition version in machineconfig file according to  #
# OpenShift <major.minor> version.
#                                                                              #
# Change History                                                               #
# 17/02/2021  Marco Betti   Original code.                                     #
#                                                                              #
################################################################################
################################################################################
################################################################################
#                                                                              #
#  Copyright (C) 2021 Marco Betti                                              #
#  mbetti@redhat.com
#                                                                              #
#  This program is free software; you can redistribute it and/or modify        #
#  it under the terms of the GNU General Public License as published by        #
#  the Free Software Foundation; either version 2 of the License, or           #
#  (at your option) any later version.                                         #
#                                                                              #
#  This program is distributed in the hope that it will be useful,             #
#  but WITHOUT ANY WARRANTY; without even the implied warranty of              #
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               #
#  GNU General Public License for more details.                                #
#                                                                              #
#  You should have received a copy of the GNU General Public License           #
#  along with this program; if not, write to the Free Software                 #
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA   #
#                                                                              #
################################################################################
################################################################################
################################################################################

VERSION="1.0.0"

################################################################################
# Function to display Help menu                                                # 
################################################################################
Help()
{
   # Display Help
   echo
   echo "set-machineconfig-version.sh:"
   echo "Changes the machineconfig version according to OCP version."
   echo
   echo "Syntax: ocp4-set-nodes-password.sh [-h|V] -v <major.minor>"
   echo "options:"
   echo "-h                             Print this Help."
   echo "-V                             Print software version and exit."
   echo "-v <major.minor>               OCP version 'major.minor', eg. 4.5 / 4.6 / 4.7"
   echo
}

################################################################################
# Function to ask for continue and wait answer                                 # 
################################################################################
Continue()
{
  while true; do
    read -p "Continue? [Y/n] " input
    case $input in
      [yY][eE][sS]|[yY]|'' ) break ;;
      [nN][oO]|[nN] ) exit ;;
      * ) echo "Please answer yes or no." ;;
    esac
  done
}

################################################################################
# Managing possible options                                                    #
################################################################################
node_label=''
Cluster=''
while getopts "hVv:" option; do
   case $option in
      h) # display Help
         Help
         exit ;;
      V) # print version
         echo "set-machineconfig-version.sh - Version $VERSION"
         exit ;;
      v) # set OCP version
         OCPVER=$OPTARG ;;
     \?) # incorrect option
         Help
         exit ;;
   esac
done

case $OCPVER in
  4.5) IGN_VERS=2.2.0 ;;
  4.6) IGN_VERS=3.1.0 ;;
  4.7) IGN_VERS=3.2.0 ;;
  *) echo "Wrong OCP version"
     Help
     exit ;;
esac

DIRECTORY=$(cd `dirname $0` && pwd)
for role in "single" "worker" "master" ; do
  sed -i "s/\(version: \)[a-zA-Z0-9].[a-zA-Z0-9].[a-zA-Z0-9]/\1$IGN_VERS/" $DIRECTORY/../machineconfig/$role/*.yaml
done

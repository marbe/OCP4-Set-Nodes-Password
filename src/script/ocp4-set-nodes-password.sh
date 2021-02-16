#!/bin/bash
################################################################################
#                         ocp4-set-nodes-password.sh                           #
#                                                                              #
# This script changes the 'core' user login password for each OCP4 node of the #
# provided cluster by connecting to the cluster with a bearer token it gets    #
# by calling API server with username and password read from STDIN.            #
# You have to provide <custername.base_domain> to the script as an option      #
# and, when asked by the script, username and password to connect to API       #
# server with cluster-admin role.                                              #
#                                                                              #
# Change History                                                               #
# 15/02/2021  Marco Betti   Original code.                                     #
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
   echo "ocp4-set-nodes-password.sh:"
   echo "Changes the 'core' user login password for each OCP4 node of the provided cluster."
   echo
   echo "Syntax: ocp4-set-nodes-password.sh [-h|V] [-l label] -c <clustername.basedomain>"
   echo "options:"
   echo "-h                             Print this Help."
   echo "-V                             Print software version and exit."
   echo "-l label                       Change password for nodes with this label."
   echo "-c <clustername.basedomain>    Specify the Cluster name to work on."
   echo
}

################################################################################
# Function that take exit status as first parameter and print error message    #
# as second parameter                                                          # 
################################################################################
ExitStatusCheck()
{
  if [ $1 -ne 0 ] ; then
    echo
    echo "$2" >&2
    echo
    exit 1
  fi
}

################################################################################
# Function to verify needed commands are present                               #
################################################################################
SanityCheck()
{
  needed_executable=(oc curl)
  for cmd in ${needed_executable[@]}; do
    which $cmd 2>&1 1>/dev/null
    ExitStatusCheck $? "$cmd executable not present."
  done
}

################################################################################
# Funtion to read OCP credentials, check oauth cluster endpoint availability   #
# and retrieve the access token                                                #
################################################################################
GetBearerToken()
{
  read -p 'OpenShift Username: ' uservar
  read -sp 'OpenShift Password: ' passvar
  echo
  access_token=$(curl -sIk "https://oauth-openshift.apps.$Cluster/oauth/authorize?response_type=token&client_id=openshift-challenging-client" --user $uservar:$passvar | grep -oP "access_token=\K[^&]*" || echo FAIL)

  if [ "$access_token" == "FAIL" ] ; then
    echo "Failed retrieving access token."
    exit 1
  fi
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
while getopts "hVl:c:" option; do
   case $option in
      h) # display Help
         Help
         exit ;;
      V) # print version
         echo "ocp4-set-nodes-password.sh - Version $VERSION"
         exit ;;
      l) # set node label
         node_label=$OPTARG ;;
      c) # set Cluster
         Cluster=$OPTARG ;;
     \?) # incorrect option
         Help
         exit ;;
   esac
done

SanityCheck

if [ -z "$Cluster" ] ; then
  Help
  exit
fi

################################################################################
# If we move forward, then the parameter we get is <clustername.basedomain>    #
################################################################################
echo -e "\nChanging password for OpenShift cluster: api.$Cluster\n"
Continue

################################################################################
# Check that Cluster can be reached                                            #
################################################################################
curl -sk https://oauth-openshift.apps.$Cluster/healthz 2>&1 1>/dev/null
ExitStatusCheck $? "curl to oauth-openshift.apps.$Cluster/healthz endpoint was not OK"

################################################################################
# Read new password and set it either for a specific labeled node or for all   #
################################################################################
echo
GetBearerToken
oc login --token="$access_token"
if [ -z "$node_label" ] ; then
  ocp_nodes=$(oc get nodes -o jsonpath='{.items[*].metadata.name}')
else
  ocp_nodes=$(oc get nodes -l $node_label -o jsonpath='{.items[*].metadata.name}')
fi

echo
read -sp 'NEW core password: ' core_password

for node in $ocp_nodes ; do
  echo -e "\nChanging 'core' password for node $node... "
  oc debug --request-timeout="30s" --quiet=true node/$node -- chroot /host usermod -p $(openssl passwd "$core_password") core
  if [ $? -eq 0 ] ; then
    echo "Succeded."
  else
    echo "Failed."
  fi
done

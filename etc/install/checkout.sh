#!/bin/bash
#
# Read the README file before executing this script.
#
# Checks out all source code needed for .LRN and OpenACS from CVS and copies
# the supervise run script that runs AOLServer to the server root directory.
#
# This script should be executed as root and requires the following
# environment variables to be set:
#
# config_file - where variables such as the serverroot are kept
# dotlrn - (yes or no) Indicates if dotlrn should be checked out
#
# @author Peter Marklund (peter@collaboraid.biz)

set -e
#set -x

export CVS_RSH=ssh
export script_path=$(dirname $(which $0))

cd $script_path

# Sometimes script path will be the dot so I need this workaround
export script_path=$(pwd)

source ./functions.sh

# Fetch config parameters
# NOTE: fetching parameters further down in the script will not work
# if the config_file=./install.tcl since we are cd:ing to a different dir
# below
serverroot=`get_config_param serverroot`
aolserver_user=`get_config_param aolserver_user`
aolserver_group=`get_config_param aolserver_group`
packages_list=`get_config_param packages_list`
oacs_branch=`get_config_param oacs_branch`

echo "$0: Starting checkout for server path $serverroot with config_file $config_file and dotlrn=$dotlrn"

# Move away the old sources if they exist
if [ -d ${serverroot} ]; then

  # Remove old tmp storage of sources
  server_name=$(basename ${serverroot})
  old_sources_path="/var/tmp/${server_name}"
  if [ -d ${old_sources_path} ]; then
    echo "$0: removing old server sources at ${old_sources_path}"
    rm -rf ${old_sources_path}
  fi
 
  echo "$0: Moving sources at ${serverroot} to ${old_sources_path}"
  mv ${serverroot} ${old_sources_path}
fi

# Checkout OpenACS core
mkdir -p ${serverroot}-tmp
cd ${serverroot}-tmp
if [ "$oacs_branch" == "HEAD" ]; then
    oacs_branch_switch=""
else
    oacs_branch_switch="-r $oacs_branch"
fi

echo "$0: Checking out acs-core from branch \"$oacs_branch\""
cvs -q -d :pserver:anonymous:@cvs.openacs.org:/cvsroot login
cvs -q -z3 -d :pserver:anonymous@cvs.openacs.org:/cvsroot checkout $oacs_branch_switch acs-core
mv ${serverroot}-tmp/openacs-4 ${serverroot}
rmdir ${serverroot}-tmp

cd ${serverroot}/packages

if [ -n "$packages_list" ]; then
    # Checkout additional packages (modules)
    for package in $packages_list
    do
      cvs -q -z3 -d :pserver:anonymous@cvs.openacs.org:/cvsroot checkout $oacs_branch_switch $package
    done
fi

if [ $dotlrn == "yes" ]; then
    # Checkout needed packages
    echo "$0: Checking out packages from branch $oacs_branch"
    cvs -q -z3 -d :pserver:anonymous@cvs.openacs.org:/cvsroot co $oacs_branch_switch dotlrn-all

fi

echo $(date) > ${serverroot}/www/SYSTEM/checkout-date
# Set proper privileges

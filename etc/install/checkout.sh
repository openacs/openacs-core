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

export CVS_RSH=ssh
script_path=$(dirname $(which $0))

cd $script_path

# Sometimes script path will be the dot so I need this workaround
script_path=$PWD

source functions.sh

# Fetch config parameters
serverroot=`get_config_param serverroot`
aolserver_user=`get_config_param aolserver_user`
use_timesaver_files=`get_config_param use_timesaver_files`

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
oacs_branch=`get_config_param oacs_branch`
if [ -z "$oacs_branch" ]; then
    oacs_branch="HEAD"
fi
echo "$0: Checking out acs-core from branch $oacs_branch"
cvs -q -d :pserver:anonymous:@openacs.org:/cvsroot login
cvs -q -z3 -d :pserver:anonymous@openacs.org:/cvsroot checkout -r $oacs_branch acs-core
mv ${serverroot}-tmp/openacs-4 ${serverroot}
rmdir ${serverroot}-tmp

if [ $dotlrn == "yes" ]; then
    # Checkout needed packages
    echo "$0: Checking out packages from branch $oacs_branch"
    cd ${serverroot}/packages
    cvs -q -z3 -d :pserver:anonymous@openacs.org:/cvsroot co -r $oacs_branch \
        acs-datetime acs-developer-support acs-events acs-mail-lite \
        attachments bulk-mail calendar faq file-storage forums general-comments \
        news notifications ref-timezones user-preferences survey lars-blogger weblogger-portlet \
        rss-support trackback workflow curriculum

    # Copy short reference files to save time when installing datamodel
    if parameter_true "$use_timesaver_files"; then
	echo "$0: Copying timesaver files"
	cp ${script_path}/ref-timezones-rules.sql \
	    ${serverroot}/packages/ref-timezones/sql/common
	cp ${script_path}/ref-timezones-data.sql \
	    ${serverroot}/packages/ref-timezones/sql/common
    fi

    # Checkout .LRN
    dotlrn_branch=`get_config_param dotlrn_branch`
    if [ -z "$dotlrn_branch" ]; then
        dotlrn_branch="HEAD"
    fi
    echo "$0: Checking out .LRN from branch $dotlrn_branch"
    cvs -q -d :pserver:anonymous:@dotlrn.openacs.org:/dotlrn-cvsroot login
    cvs -q -z3 -d :pserver:anonymous@dotlrn.openacs.org:/dotlrn-cvsroot \
        co -r $dotlrn_branch dotlrn-core
fi

echo $(date) > ${serverroot}/www/SYSTEM/checkout-date
# Set proper privileges

# TODO - get service name and group from config file
chown -R ${aolsever_user}.web ${serverroot}
chmod -R go+rwX ${serverroot}

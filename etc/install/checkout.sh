#!/bin/bash
#
# Read the README file before executing this script.
#
# Checks out all source code needed for OpenACS and .LRN from CVS
#
# This script should be executed as root and requires the following
# environment variables to be set:
#
# config_file - where variables such as the server_path are kept
# dotlrn - (yes or no) Indicates if dotlrn should be checked out
#
# environment variable to be set. It is based on instructions 
# at http://dotlrn.openforce.net/dotlrn/doc/dotlrn-install
#
# @author Peter Marklund (peter@collaboraid.biz)

export CVS_RSH=ssh
script_path=$(dirname $(which $0))

cd $script_path

# Sometimes script path will be the dot so I need this workaround
script_path=$PWD

source functions.sh

# Fetch config parameters
server_path=`get_config_param server_path`
start_server_command=`get_config_param start_server_command`
pre_checkout_script=`get_config_param pre_checkout_script`
post_checkout_script=`get_config_param post_checkout_script`
use_timesaver_files=`get_config_param use_timesaver_files`

echo "$0: Starting checkout for server path $server_path with config_file $config_file and dotlrn=$dotlrn"

# The idea of this script is to move away any files or changes
# to the source tree that we want to keep (for example an
# edited AOLServer config file, see README)
if [ -n "$pre_checkout_script" ]; then
    source $pre_checkout_script
fi

# Move away the old sources
if [ -d ${server_path} ]; then

  # Remove old tmp storage of sources
  server_name=$(basename ${server_path})
  old_sources_path="/tmp/${server_name}"
  if [ -d ${old_sources_path} ]; then
    echo "$0: removing old server sources at ${old_sources_path}"
    rm -rf ${old_sources_path}
  fi
 
  echo "$0: Moving sources at ${server_path} to ${old_sources_path}"
  mv ${server_path} ${old_sources_path}
fi

# Checkout OpenACS core
mkdir -p ${server_path}-tmp
cd ${server_path}-tmp
oacs_branch=`get_config_param oacs_branch`
if [ -z "$oacs_branch" ]; then
    oacs_branch="HEAD"
fi
echo "$0: Checking out acs-core from branch $oacs_branch"
cvs -q -d :pserver:anonymous:@openacs.org:/cvsroot login
cvs -q -z3 -d :pserver:anonymous@openacs.org:/cvsroot checkout -r $oacs_branch acs-core
mv ${server_path}-tmp/openacs-4 ${server_path}
rmdir ${server_path}-tmp

if [ $dotlrn == "yes" ]; then
    # Checkout needed packages
    echo "$0: Checking out packages from branch $oacs_branch"
    cd ${server_path}/packages
    cvs -q -z3 -d :pserver:anonymous@openacs.org:/cvsroot co -r $oacs_branch \
      acs-datetime acs-developer-support acs-events acs-mail-lite \
      attachments bulk-mail calendar faq file-storage forums general-comments \
      news notifications ref-timezones user-preferences

    # Copy short reference files to save time when installing datamodel
    if parameter_true "$use_timesaver_files"; then
	echo "$0: Copying timesaver files"
	cp ${script_path}/ref-timezones-rules.sql \
	    ${server_path}/packages/ref-timezones/sql/common
	cp ${script_path}/ref-timezones-data.sql \
	    ${server_path}/packages/ref-timezones/sql/common
    fi

    # Checkout .LRN
    dotlrn_branch=`get_config_param dotlrn_branch`
    if [ -z "$dotlrn_branch" ]; then
        dotlrn_branch="HEAD"
    fi
    echo "$0: Checking out .LRN from branch $dotlrn_branch"
    cvs -q -d :pserver:anonymous:@dotlrn.openforce.net:/dotlrn-cvsroot login
    cvs -q -z3 -d :pserver:anonymous@dotlrn.openforce.net:/dotlrn-cvsroot \
        co -r $dotlrn_branch dotlrn-core

    # Copy graphics files
    echo "$0: Copying graphics files"
    mkdir ${server_path}/www/graphics
    cp ${server_path}/packages/dotlrn/www/graphics/* ${server_path}/www/graphics
fi

# The idea of this script is to copy in any files (AOLServer config files,
# log files etc.) under the new source tree, and apply any patches
# that should be applied (see README).
if [ -n "$post_checkout_script" ]; then
    source $post_checkout_script
fi

# Set proper privileges
chown -R nsadmin.web ${server_path}
chmod -R 775 ${server_path}

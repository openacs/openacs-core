#!/bin/sh
#
# Relies on environment variables:
# config_file

# Make script dir current dir for convenience
script_path=$(dirname $(which $0))
cd $script_path

file_name=$1

source ./functions.sh

alert_keyword=`get_config_param alert_keyword`

installation_errors=`./check-errors-output.sh $file_name`

if echo $installation_errors | grep -q -i '[a-z]' ; then
	echo "${alert_keyword}: There are potential installation errors. The file $file_name contains the following lines that suggest errors:"
	echo "$installation_errors"    
fi

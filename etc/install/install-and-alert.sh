#!/bin/sh
#
# This script runs the dotlrn-install.sh script and sends
# an email alert if there are installation errors. The
# script is intended to be run by cron.
#
# Must be executed as root

# Make script dir current dir for convenience
script_path=$(dirname $(which $0))
cd $script_path

source functions.sh

# Get a proper environment set up
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# Clumsy argument handling, can't use shift as I'm passing
# the arguments to dotlrn-install.sh
config_file_next=0
for arg in $@;
do
    if [ "$config_file_next" == "1" ]; then
        export config_file="$arg"
        config_file_next=0
    fi

    if [ "$arg" == "--config-file" ]; then        
        config_file_next="1"
    fi
done

alert_keyword=`get_config_param alert_keyword`
send_alert_script=`get_config_param send_alert_script`
export server=`get_config_param server`

output_dir="server-output/${server}"
if [ ! -d ${output_dir} ]; then
    mkdir -p $output_dir
fi
installation_output_file="${output_dir}/installation-output"
./dotlrn-install.sh $@ &> $installation_output_file

# Get lines with alert keywords or lines with failed TclWebtest tests
error_lines=$(egrep -i "(FAILED: .+\.test)|($alert_keyword)" $installation_output_file)

if [ -n "$error_lines" ]; then
    $send_alert_script "$error_lines" > /dev/null
fi

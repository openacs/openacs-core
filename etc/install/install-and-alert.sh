#!/bin/sh
#
# This script runs the install.sh script and sends
# an email alert if there are installation errors. The
# script is intended to be run by cron.
#
# Must be executed as root

set -x

# Make script dir current dir for convenience
script_path=$(dirname $(which $0))
cd $script_path

source ./functions.sh

# Get a proper environment set up
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# Look for two-part command line arguments
# Also, we need to look for command-line setting for config file
# before we load the config file
config_val_next=0
server_next=0
export config_file="install.tcl"
server_overridden="no"
for arg in "$@"
  do
  if [ $config_val_next == "1" ]; then
      export config_file=$arg
      config_val_next=0
  fi
  if [ $server_next == "1" ]; then
      # Overrides server setting in config file
      export server=$arg
      server_next=0
      server_overridden="yes"
  fi
  if [ $arg == "--config-file" ]; then
      config_val_next=1
  fi
  if [ $arg == "--server" ]; then
      server_next=1
  fi
done

# Create a config file with overridden server name if it was
# provided on the command line
if parameter_true "$server_overridden"; then
    echo "$0: Overriding config server setting with $server"
    create_override_config_file $server $config_file
fi

alert_keyword=`get_config_param alert_keyword`
send_alert_script=`get_config_param send_alert_script`
export server=`get_config_param server`

output_dir="server-output/${server}"
if [ ! -d ${output_dir} ]; then
    mkdir -p $output_dir
fi
installation_output_file="${output_dir}/installation-output"
./install.sh $@ &> $installation_output_file

# Get lines with alert keywords or lines with failed TclWebtest tests
error_lines=$(egrep -i "(FAILED: .+\.test)|($alert_keyword)" $installation_output_file)

if [ -n "$error_lines" ]; then
    $send_alert_script "$error_lines" > /dev/null
fi

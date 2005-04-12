#!/bin/bash
# Assumes the environment variable config_file to be set

# The drop and create scripts are assumed to be in the same directory as this script
script_path=$(dirname $(which $0))

source $script_path/../functions.sh

system_user=`get_config_param system_user` 
system_user_password=`get_config_param system_user_password` 
oracle_user=`get_config_param db_name` 
oracle_password=`get_config_param oracle_password` 

cat ${script_path}/user-drop.sql | perl -pi -e "s/:oracle_user/$oracle_user/g" | \
				   sqlplus $system_user/$system_user_password

cat ${script_path}/user-create.sql | perl -pi -e "s/:oracle_user/$oracle_user/g" | \
                                     perl -pi -e "s/:oracle_password/$oracle_password/g" | \
				     sqlplus $system_user/$system_user_password 

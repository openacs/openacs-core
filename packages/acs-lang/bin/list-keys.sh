#!/bin/sh
# 
# Generate a listing of all message keys in the system to STDOUT. 
#
# @author Peter Marklund

export script_path=$(dirname $(which $0))
source ${script_path}/functions.sh

for en_us_file in $(find_en_us_files)
do
    package_key=$(echo $en_us_file | ${script_path}/mygrep '/([^./]+)[^/]+$')
    for key in $(get_catalog_keys $en_us_file)
    do
        echo "${package_key}.${key}"
    done
done

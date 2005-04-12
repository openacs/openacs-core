#!/bin/bash
#
# Usage: updateserver.sh <server_dir>
#
# Update an OpenACS and .LRN source tree without checking out new packages
# but still checking out new dirs in current packages and the www root dir.
# Does the update as the anonymous user to avoid any password issues.
#
# by Peter Marklund

server_root=$1
packages_root=${server_root}/packages
root_dirs="www etc"

cvs_args_with_dir="-f -q update -Pd"
cvs_args_no_dir="-f -q update -P"
oacs_cvs="cvs -d :pserver:anonymous@cvs.openacs.org:/cvsroot"

# CVS update in root without new dirs
echo "$0 - Updating in root dir $server_root" 
cd $server_root
$oacs_cvs $cvs_args_no_dir

# Update all packages with new dirs
echo "$0 - Updating all packages"
cd $packages_root
for dir in $(find -maxdepth 1 -type d|grep -v CVS|egrep -v '^\.$')
do 
  cd $dir
  echo "$0 - Updating package $dir"

  $oacs_cvs $cvs_args_with_dir
  cd .. 
done

# Update www root dir with new dirs
for root_dir in $root_dirs
do
  root_path="${server_root}/${root_dir}"
  echo "$0 - Updating dir $root_path"
  cd $root_path
  $oacs_cvs $cvs_args_with_dir
done

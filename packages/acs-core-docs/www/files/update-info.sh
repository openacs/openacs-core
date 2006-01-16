#!/bin/sh
# run this file from ../packages to renumber all .info version numbers
# call as bash update-info.sh <new-version> <release-date>
# this will update all version numbers to new-version
# and release dates to release-date
# it should catch any valid openacs version numbers
# for example 5.2.0
#             5.2.0a1
#             5.2.0b1
#             5.2.0d1
#---------------------------------------------------------------------
# here's what we're looking for
#---------------------------------------------------------------------
#   <version name="5.1.0d1" url="http:blahblah/acs-kernel-5.1.0d1.apm">
#      <provides url="acs-kernel" version="5.1.0d1"/>
#      <requires url="acs-kernel" version="5.0.0b4"/>
# 2006-01-08 daveb
# 
# changing requires statements is new
# all the core packages should require only core packages
# and it makes sense to require core packages of the same version
#---------------------------------------------------------------------

for dir in `find -name *.info`
  do
  perl -p -i -e "s/name=\"\d\.\d\.\d\w?\d?\"/name=\"${1}\"/" $dir
  perl -p -i -e "s/-\d\.\d\.\d\w?\d?.apm\"/-${1}.apm\"/" $dir
  perl -p -i -e "s/(provides.*version)=\"\d\.\d\.\d\w?\d?\"/\1=\"${1}\"/" $dir
  perl -p -i -e "s/(requires.*version)=\"\d\.\d\.\d\w?\d?\"/\1=\"${1}\"/" $dir
  perl -p -i -e "s/(<release-date>)\d{4}-\d{2}-\d{2}/<release-date>${2}/" $dir
done
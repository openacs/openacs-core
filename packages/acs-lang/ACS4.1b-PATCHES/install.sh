#!/bin/sh

echo $0
echo $1

if [ "$1" = "" ]; then
 echo 1>&2 "usage: $0 /path/to/your/webserver"
 exit 1
fi

WEBROOT=$1

patch -d  ${WEBROOT}/packages/acs-templating/tcl < util-procs.patch
patch -d ${WEBROOT}/packages/acs-tcl/tcl < request-processor-procs.patch
patch -d ${WEBROOT}/packages/acs-templating/tcl < tag-init.patch

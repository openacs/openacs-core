#!/bin/sh

# This shell script will recurse through the packages directory, searching
# for java/src directory trees.  It will append any of these directories to
# the java CLASSPATH in the current environment.

curdir=`pwd`

for dir in `find . -type d | grep "java\/src$"`
do
    CLASSPATH=$CLASSPATH:${curdir}`echo $dir | sed -e s/\.//`
done

# Just to be sure....

export CLASSPATH

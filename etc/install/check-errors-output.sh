#!/bin/sh

file_name=$1

# FIXME: Ignore InterMedia errors for now
egrep -i 'error' $file_name | egrep -i -v 'no error' | egrep -v -i 'ODCIINDEXCREATE|Intermedia'

exit 0

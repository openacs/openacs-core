#!/bin/sh

file_name=$1

# FIXME: Ignore InterMedia errors for now
egrep -i 'error' $file_name | egrep -i -v 'no error' | egrep -i -v 'ODCIINDEXCREATE|Intermedia' | egrep -i -v 'If not, please check your server error log'

exit 0

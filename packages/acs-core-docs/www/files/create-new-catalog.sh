#!/bin/bash
# create-new-catalog.sh
# @author:  Hector Amado   hr_amado@galileo.edu
#

# From each catalog.xml in all packages,
# e.g. acs-subsite.es_ES.ISO-8859-1 --> acs-subsite.es_GT.ISO-8859-1  
#
# USAGE:
#     Inside packages directory run ../bin/create-new-catalog.sh from new 
#                                   or
#                                   sh ../bin/create-new-catalog.sh from new
#     where from, new is the language id you copy and create
#
#     eg.   ../bin/create-new-catalog.sh es_ES es_GT


if [ $# -ne 2 ]; then
   echo ""
   echo " USAGE:   sh ../bin/create-new-catalog.sh from new "
   echo "      eg. sh ../bin/create-new-catalog.sh es_ES es_GT"
   echo ""
   exit 1

fi 

from=$1
new=$2

echo "Generating .$new. catalog files . . . "

for i in $( ls -1 );
do
    ls -1R $i | grep .$from. > /dev/null
    if [ $? -eq 0 ]; then
       cd $i/catalog
       for j in $(ls -1 );
       do
         t=${j/$from/$new}
         if [ x$t != x$j ]; then
            cp $j $t
            sed "s/$from/$new/" $t > temp.xml
            mv temp.xml $t
            echo $t
         fi
       done 
       cd ../../
    fi
done

exit 0

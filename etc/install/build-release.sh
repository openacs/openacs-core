#!/bin/bash

# if TAG=1 create the cvs tags otherwise assume they exist.
TAG=1

# What release version are we building; version format should be
# dashes rather than dots eg. OACS_VERSION=5-0-0b4

OACS_VERSION=5-0-0b4
DOTLRN_VERSION=2-0-0b4

OACS_BRANCH=oacs-5-0
DOTLRN_BRANCH=dotlrn-2-0

DOTLRN_CVSROOT=/dotlrn-cvsroot
OACS_CVSROOT=/cvsroot

#
# Nothing below here should need to change...
#
BASE=/var/tmp/release-$OACS_VERSION
mkdir $BASE
if [ ! -d $BASE ]; then 
    echo "Failed creating base dir $BASE"
    exit 1
fi

cd $BASE 

if [ $TAG -eq 1 ]; then 

    # Checkout and tag the release 
    cvs -d $OACS_CVSROOT checkout -r $OACS_BRANCH openacs-4
    cd openacs-4 
    cvs tag -F openacs-$OACS_VERSION 
    cd ../


    # Checkout and tag the dotlrn release
    mkdir dotlrn-packages
    cd dotlrn-packages
    cvs -d $DOTLRN_CVSROOT checkout -r $DOTLRN_BRANCH dotlrn-all
    for dir in *; do ( cd $dir && cvs tag -F dotlrn-$DOTLRN_VERSION ); done
    cd ../

    #
    # Should check for .sql .xql .adp .tcl .html .xml executable files and squak if found.
    #

fi



# Generate tarballs...
#

# openacs
#
mkdir tarball
cd tarball
cvs -d $OACS_CVSROOT export -r openacs-$OACS_VERSION acs-core
mv opeancs-4 openacs-${OACS_VERSION//-/.}
tar -czf ../openacs-${OACS_VERSION//-/.}.tar.gz openacs-${OACS_VERSION//-/.}
cd ..

# dotlrn
#
mkdir dotlrn-tarball
cd dotlrn-tarball
cvs -d $OACS_CVSROOT export -r openacs-$OACS_VERSION acs-core
cd  openacs-4/packages
cvs -d $OACS_CVSROOT export -r openacs-$OACS_VERSION dotlrn-prereq
cvs -d $DOTLRN_CVSROOT export -r dotlrn-$DOTLRN_VERSION dotlrn-core
cd ../..
cp -f openacs-4/packages/dotlrn/install.xml openacs-4
mv openacs-4 dotlrn-${DOTLRN_VERSION//-/.}
tar -czf ../dotlrn-${DOTLRN_VERSION//-/.}.tar.gz dotlrn-${DOTLRN_VERSION//-/.}


# Clean up after ourselves...
cd $BASE && rm -rf dotlrn-tarball tarball openacs-4 dotlrn-packages

#!/bin/bash
# should turn this into an /etc/init.d script, with commands:
#  status (prod is X, up 100 seconds; alt is Y, down)
#  promote X (automatically makes X production and demotes current prod to preprod)

E_BADARGS=65
if [ ! -n "$1" ]
then
  echo "Usage: `basename $0` Old New "
  echo "Current Old:`ls -l /web/ | grep primary`"
  echo "Current New:`ls -l /web/ | grep alternate`"
  exit $E_BADARGS
fi  
PROD=primary
ALT=alternate
BASE_DIR=/var/lib/aolserver
SVC_DIR=/var/lib/svscan
OLD=$1
NEW=$2

# basic premise: a server named foo is controlled by daemontools as $SVC_DIR/foo,
# and is actually rooted at BASE_DIR/foo
# when it is moved to production, its config.tcl is updated 
# and the BASE_DIR/PROD link is changed to point to it
# and BASE_DIR/ALT is changed to point to whatever it replaced

svc -d $SVC_DIR/$OLD
svc -d $SVC_DIR/$NEW
cd $BASE_DIR
rm $PROD
rm $ALT
cd $BASE_DIR/$NEW/etc
cvs up -r $PROD config.tcl
cd $BASE_DIR/$OLD/etc
cvs up -r $ALT config.tcl
cd $BASE_DIR
ln -s $NEW $PROD
ln -s $OLD $ALT
svc -u $SVC_DIR/$NEW
svc -u $SVC_DIR/$OLD

# show status
svstat $SVC_DIR/*

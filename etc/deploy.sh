#!/bin/bin/tclsh
# process command line arguments
foreach arg $argv {
    switch -glob -- $arg {
	--status  {set status_p true}
	--help*   {set help_p true}
	--switch* {set switch_p true}
    }
}

if { [llength $argv] = 0 } {
    set help_p true
}

if { $help_p } {
    puts stdout {Usage: deploy [--switch | --status | --help]}
    exit
}

if { $status_p } {
    set balance_txt [exec /usr/sbin/balance -c show 80]
    puts stdout $balance_txt
    exit
}

# the old bash script:
# PROD=primary
# ALT=alternate
# BASE_DIR=/var/lib/aolserver
# SVC_DIR=/var/lib/svscan
# OLD=$1
# NEW=$2

# # basic premise: a server named foo is controlled by daemontools as $SVC_DIR/foo,
# # and is actually rooted at BASE_DIR/foo
# # when it is moved to production, its config.tcl is updated 
# # and the BASE_DIR/PROD link is changed to point to it
# # and BASE_DIR/ALT is changed to point to whatever it replaced

# svc -d $SVC_DIR/$OLD
# svc -d $SVC_DIR/$NEW
# cd $BASE_DIR
# rm $PROD
# rm $ALT
# cd $BASE_DIR/$NEW/etc
# cvs up -r $PROD config.tcl
# cd $BASE_DIR/$OLD/etc
# cvs up -r $ALT config.tcl
# cd $BASE_DIR
# ln -s $NEW $PROD
# ln -s $OLD $ALT
# svc -u $SVC_DIR/$NEW
# svc -u $SVC_DIR/$OLD

# # show status
# svstat $SVC_DIR/*

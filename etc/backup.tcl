#!/usr/local/bin/tclsh8.4
# ported from: backup.sh
# $Id$
#
# full and incremental backup script in tclsh
# created 2004-08-28
# Based on a script by Daniel O'Callaghan <danny@freebsd.org>
# and modified by Gerhard Mourani <gmourani@videotron.ca>
# modified more by Joel Aufrecht in 2002
# merged with Collaboraid database backups Dec 2003
# 2004-02-10: Joel Aufrecht: added rolling delete and space check
# 2004-08-28: Torben Brosten: partially converted from bash to tclsh
# still need to convert 
# SCP, ORACLE etc 'cause I'm not using them so can't test them

# Change the variables below to fit your computer/backup
#

set COMPUTER colossus           ;# name of this computer
set BACKUPUSER service0             ;# username to own the files
set BACKUPDIR /home/service0/backup  ;# where to store the backups
set BACKUPPART /dev/hda1        ;# which partition are we backing up to
# common values: linux: /dev/hda1 freesd: /dev/ad0s1a
# (would be nice to figure BACKUPPART automatically given BACKUPDIR)
set WEBDIR /var/lib/aolserver     ;# path to OpenACS services root
set FULL_SPACE_FREE 1           ;# must be this many GB free to run full backup
                                 # if not, try incremental
set INCR_SPACE_FREE 0.1           ;# must be this many GB free to run incremental
                                 # if not, don't back up
set OTHERHOST ""
    # another server, to receive backup files
    # leave blank to skip scp exchange

set WIPE_OLD_AFTER_SCP_FULL false
    # if true, whenever a full backup file is
    # sucessfully scp'ed to OTHERHOST, wipe out all
    # similar backups except for the full backup file
    # rationale is, keep last good full + incrementals
    # on this box, keep everything on other box

set OTHERUSER remoteuser
    # the user on the recipient server
set OTHERPASS abc123
    # password

set POSTGRES_DBS "service0 service1"
    # script assumes an exact match between database
    # name and filesystem space-separated list of postgres databases
    # to be backed up to file system

set ORACLE8I_DBS ""
    # space-separated list of Oracle8i databases
    # to be backed up to file system
    # space-separated list of directories to be backed up

#---------------------------------------------------------------------
# a space-delimited list of directories to back up
# A minimal backup  
set DIRECTORIES $WEBDIR
#
# this is a fairly thorough set of data back - must run as root to work, though
#DIRECTORIES="/etc /home /root /cvsroot /var/qmail/alias /usr/local/aolserver $WEBDIR"
#---------------------------------------------------------------------

# System Program Paths
set PG_BINDIR /usr/local/pgsql/bin      ;# path to PostGreSQL binaries
set TIMEDIR $BACKUPDIR/last-full        ;# where to store time of full backup
set TAR /usr/bin/tar                        ;# name and location of tar
set CHOWN /usr/sbin/chown
set CHMOD /bin/chmod
set GZIP /usr/bin/gzip
set SCP "/usr/bin/scp -oProtocol=2"

############################################ ###########################
#
# Shouldn't need to change anything below this line 
#
#######################################################################

# multiplatform df-k from http://wiki.tcl.tk/526 (Richard Suchenwirth)
proc dfk {{dir .}} {
    switch $::tcl_platform(os) {
        FreeBSD -
        Darwin -
        Linux -
        OSF1 -
        SunOS {lindex [lindex [split [exec df -k $dir] \n] end] 3}
        HP-UX {lindex [lindex [split [exec bdf   $dir] \n] end] 3}
        {Windows NT} {
                expr [lindex [lindex [split [exec cmd /c dir /-c $dir] \n] end] 0]/1024
	    }
        default { puts "Error: don't know how to \"df -k\" on $::tcl_platform(os)"}
    }
}


# Day of the week e.g. Mon
set DOW [clock format [clock seconds] -format %a]
# Date of the Month e.g. 27
set DOM [clock format [clock seconds] -format %d]
# Date and Month e.g. 27Sep
set DM "$DOM[clock format [clock seconds] -format %b]"
# Year, Month, Date, e.g. 20020401
set DATE [clock format [clock seconds] -format %Y%m%d]

# A full backup is generated:
#   the first time the script is run,
#   On the 1st of the month
#   Every Sunday
# The rest of the time the backup includes only files that have changed
# since the last full backup
# Each backup has a date-specific filename
set TYPE ""

#---------------------------------------------------------------------
# Parse command line 
#---------------------------------------------------------------------
set arg1 [lindex $argv 0]
switch -exact -- $arg1 {
    --full {
        set TYPE "full"
    }
    -help -
    -h    -
    --h   -
    --help {
       puts "Usage: $0 --full to force full backup, or $0 to run automated.  All other variables are set in the script."
    }
}

# begin processing

if {![file exists $BACKUPDIR]} {
   file mkdir $BACKUPDIR
}
if {![file exists $TIMEDIR]} {
   file mkdir $TIMEDIR
}

if { ![file exists $TIMEDIR/$COMPUTER-full-date] } {
    set TYPE "full"
}

if {$DOM == "01" || $DOW == "Sun"} {
    set TYPE "full"
}

if {$TYPE == "full"} {
    set NEW_FLAG ""
} else {
    set TYPE "incremental"
    set fileid [open $TIMEDIR/$COMPUTER-full-date r]
    gets $fileid NOW
    close $fileid
    set NEW_FLAG "--newer-mtime=$NOW"
}

#---------------------------------------------------------------------
# Check for free space
#---------------------------------------------------------------------
# get free byte count
#free=`df | grep $BACKUPPART | awk '{print $4}`'
set free [dfk $BACKUPPART] 
# force to incremental if there isn't room for full
if {$free < [expr $FULL_SPACE_FREE * 1024]} {
    set TYPE "incremental"
    puts stderr "Warning: Not enough free space for full backup; trying incremental"
}
# abort if there isn't room for incremental
if {$free < [expr $INCR_SPACE_FREE * 1024]} {
    puts stderr "Error: Not enough free space for backup; aborting"
    exit    
}


#---------------------------------------------------------------------
# Dump databases
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# PostGreSQL
puts "Postgres backups"

set POSTGRES_DBS [split $POSTGRES_DBS]
puts "number of databases: [llength $POSTGRES_DBS]"
foreach dbname $POSTGRES_DBS {
    set dmp_file "$WEBDIR/$dbname/database-backup/$dbname-nightly-backup.dmp"
#    puts -nonewline "-> Dumping $dbname to $dmp_file ... "
    puts "pg_dump -f $dmp_file -Fp $dbname "
    puts "[expr [lindex [split [time {exec $PG_BINDIR/pg_dump -f $dmp_file -Fp $dbname}]] 0] / 1000000] seconds"
    puts "[expr [file size $dmp_file] / 1024]k"
    exec $GZIP -f $dmp_file
}

#---------------------------------------------------------------------
# Oracle
#for dbname in $ORACLE8IDBS
#do
#    dmp_file=$WEBDIR/$dbname/database-backup/$dbname-nightly-backup.dmp
#    echo -n "-> Dumping $dbname to $dmp_file ... "
#    time /usr/sbin/export-oracle $dbname $dmp_file
#    /bin/ls -lh $dmp_file | awk '{print $5}'
#    gzip -f $dmp_file
#done

#---------------------------------------------------------------------
# Make backup files from file system and transfer to remote site
# TODO: This could be parallelized
#---------------------------------------------------------------------
# we switched from bzip2 back to gzip because bzip2 takes 10 times longer
# for a 10% size advantage
set DIRECTORIES [split $DIRECTORIES]
foreach directory $DIRECTORIES {
    set directorytail [file tail $directory]
    # strip directory of slashes when using it in the backup file name
    set FULLNAME $BACKUPDIR/$DATE-$COMPUTER-$directorytail-backup-$TYPE.tar.gz
    set dirname_directory [file dirname $directory]
    cd $dirname_directory
    puts "cd $dirname_directory"

    # to use bzip2 instead of gzip, change z to j in the tar flags
    puts "tarring $directory into $FULLNAME.."
    puts "$TAR -zcpsh --file=$FULLNAME $directorytail $NEW_FLAG"
    if {[string length $NEW_FLAG] > 1} {
        exec $TAR -zcpsh --file\=$FULLNAME $directorytail $NEW_FLAG
    } else {
        exec $TAR -zcpsh --file\=$FULLNAME $directorytail
    }
# if you get a stat file error returning after tar, check permissions

    puts "setting owner $BACKUPUSER for file."
    exec $CHOWN $BACKUPUSER $FULLNAME
    puts "setting permissions for file."
    exec $CHMOD 660 $FULLNAME

# consider using http://curl.haxx.se (curl), standard on Mac os X systems
# as an alternate to ftp
# set ftp_url: $OTHERUSER:$OTHERPASS@OTHERHOST

#    if \[ -n "$OTHERHOST" \]
#      then 
      
#      scp_success=1
#      scp_success=`$SCP -q $FULLNAME $OTHERUSER@$OTHERHOST:$BACKUPDIR`
      
# if scp returns success, see if we should wipe
#      if [[ scp_success -eq 0 && $WIPE_OLD_AFTER_SCP_FULL == "true" && $TYPE = "full" ]];
#	  then

          # wipe out all similar backups except for the just-copied one
#          for file in `ls $BACKUPDIR/*-$COMPUTER-${directory//\//-}-backup-*.tgz`
#            do
#            if [ $file != $FULLNAME]
#                then
#                rm $file
#            fi
#          done
          
#      fi
#  fi
  
}

# If full backup completed successfully, record the date so that
# incremental backups are relative to the last successful full
# backup

if { $TYPE == "full" } {
    puts "updating backup log date"
    set NEWER ""
    set NOW [clock format [clock seconds] -format %Y-%m-%d]
    set fileid [open $TIMEDIR/$COMPUTER-full-date w]
    puts $fileid $NOW
    close $fileid
}

puts "Done."

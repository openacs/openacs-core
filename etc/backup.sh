#!/bin/bash
#
# $Id$
#
# full and incremental backup script
# created 07 February 2000
# Based on a script by Daniel O'Callaghan <danny@freebsd.org>
# and modified by Gerhard Mourani <gmourani@videotron.ca>
# modified more by Joel Aufrecht in 2002
# merged with Collaboraid database backups Dec 2003
# 2004-02-10: Joel Aufrecht: added rolling delete and space check
#
# Change the variables below to fit your computer/backup
#

COMPUTER=yourserver.net              # name of this computer
DBHOST=localhost                     # name of the computer running the database
BACKUPUSER=backup                    # username to own the files
BACKUPDIR=/backup/thisserver         # where to store the backups
BACKUPPART=/dev/hda1                 # which partition are we backing up to
                                     # (would be nice to figure this out automatically)
WEBDIR=/var/lib/aolserver            # path to OpenACS service root
FULL_SPACE_FREE=5                    # must be this many GB free to run full backup
                                     # if not, try incremental
INCR_SPACE_FREE=1                    # must be this many GB free to run incremental
                                     # if not, don't back up
OTHERHOST=theservice.de              # another server, to receive backup
                                     # files
                                     # leave blank to skip scp exchange

WIPE_OLD_AFTER_SCP_FULL=false        # if true, then whenever a full backup file is
                                     # sucessfully scp'ed to OTHERHOST, wipe out all
                                     # similar backups except for the full backup file
                                     # rationale is, keep last good full + incrementals
                                     # on this box, keep everything on other box

OTHERUSER=malte                      # the user on the recipient server
                                     # must have silent authentication, ie,
                                     # certificates

                                     # script assumes an exact match between database
                                     # name and filesystem
POSTGRES_DBS="service0"              # space-separated list of postgres databases
                                     # to be backed up to file system

ORACLE8I_DBS="service0"              # space-separated list of Oracle8i databases
                                     # to be backed up to file system

                                     # space-separated list of directories to be backed up

KEEP_DAYS=7                          # Number of days to keep backups in $BACKUPDIR
RSYNC="no"                           # Use RSYNC for the content-repository. Useful with large amount of content

#---------------------------------------------------------------------
# a space-delimited list of directories to back up
# A minimal backup  
DIRECTORIES="/var/lib/aolserver/service0"
#
# this is a fairly thorough set of data back - must run as root to work, though
#DIRECTORIES="/etc /home /root /cvsroot /var/qmail/alias /usr/local/aolserver $WEBDIR"
#---------------------------------------------------------------------

# System Program Paths
PG_BINDIR=/usr/bin                   # path to PostGreSQL binaries (containing pg_dump)
TIMEDIR=$BACKUPDIR/last-full         # where to store time of full backup
TAR=/bin/tar                         # name and location of tar
CHOWN=/bin/chown
CHMOD=/bin/chmod
SCP="/usr/bin/scp -oProtocol=2"

#######################################################################
#
# Shouldn't need to change anything below this line 
#
#######################################################################

DOW=`date +%a`              # Day of the week e.g. Mon
DOM=`date +%d`              # Date of the Month e.g. 27
DM=`date +%d%b`             # Date and Month e.g. 27Sep
DATE=`date +"%Y-%m-%d"`     # Year, Month, Date, e.g. 20020401

# A full backup is generated:
#   the first time the script is run,
#   On the 1st of the month
#   Every Sunday
# The rest of the time the backup includes only files that have changed
# since the last full backup
# Each backup has a date-specific filename
#

#---------------------------------------------------------------------
# Parse command line 
#---------------------------------------------------------------------

case $1 in
    --full)
        TYPE="full"
        ;;
    --help | -help | -h | --h)
        echo "Usage: $0 --full to force full backup, or $0 to run automated.  All other variables are set in the script."
        exit;;
    *)
esac

if [ ! -s $TIMEDIR/$COMPUTER-full-date ];
    then 
    TYPE="full";
fi

if [[ $DOM == "01" || $DOW == "Sun" ]];
    then
    TYPE="full";
fi

if [ $TYPE == "full" ];
    then
    NEW_FLAG=""
else
    TYPE="incremental"
    NEW_FLAG="--newer-mtime `cat $TIMEDIR/$COMPUTER-full-date`";
fi


#---------------------------------------------------------------------
# Check for free space
#---------------------------------------------------------------------
# get free byte count
free=`df | grep $BACKUPPART | awk '{print $4}'`

# force to incremental if there isn't room for full
if [ $free -lt `expr $FULL_SPACE_FREE \* 1024 \* 1024` ];
    then
    TYPE="incremental"
    echo "Not enough free space for full backup; trying incremental"
fi

# abort if there isn't room for incremental
if [ $free -lt `expr $INCR_SPACE_FREE \* 1024 \* 1024` ];
    then
    echo "Not enough free space for backup; aborting"
    exit -1
fi


mkdir -p $BACKUPDIR
mkdir -p $TIMEDIR

#---------------------------------------------------------------------
# Dump databases
#---------------------------------------------------------------------

#---------------------------------------------------------------------
# PostGreSQL
echo -e "\nPostgres"

for dbname in $POSTGRES_DBS
do
    dmp_file=$WEBDIR/$dbname/database-backup/$dbname-nightly-backup.dmp
    echo -n "-> Dumping $dbname to $dmp_file ... "
    time $PG_BINDIR/pg_dump -f $dmp_file -Fp $dbname -h $DBHOST
    /bin/ls -lh $dmp_file | awk '{print $5}'
    gzip -f $dmp_file
done

#---------------------------------------------------------------------
# Oracle
for dbname in $ORACLE8IDBS
do
    dmp_file=$WEBDIR/$dbname/database-backup/$dbname-nightly-backup.dmp
    echo -n "-> Dumping $dbname to $dmp_file ... "
    time /usr/sbin/export-oracle $dbname $dmp_file
    /bin/ls -lh $dmp_file | awk '{print $5}'
    gzip -f $dmp_file
done

#---------------------------------------------------------------------
# Make backup files from file system and transfer to remote site
# TODO: This could be parallelized
#---------------------------------------------------------------------
# we switched from bzip2 back to gzip because bzip2 takes 10 times longer
# for a 10% size advantage

for directory in $DIRECTORIES

  do

  # strip directory of slashes when using it in the backup file name
  FULLNAME=$BACKUPDIR/$DATE-$COMPUTER-${directory//\//-}-backup-$TYPE.tar.gz
  # to use bzip2 instead of gzip, change z to j in the tar flags
  cd $directory

  if [[ $RSYNC == "yes" ]];
    then
      # Exclude at least on GNU Tar is picky about using the full patch and the order exclude and directoy.
      tar -zcph --file $FULLNAME --exclude "$directory/content-repository-content-files" $NEW_FLAG $directory
  else
      tar -zcph . --file $FULLNAME $NEW_FLAG
  fi

  $CHOWN $BACKUPUSER $FULLNAME
  $CHMOD 660 $FULLNAME
  if [ -n "$OTHERHOST" ]
      then 
      
      scp_success=1
      if [[ $RSYNC == "yes" ]];
	  then
	  rsync -aq $BACKUPDIR $OTHERUSER@$OTHERHOST:$BACKUPDIR
      else
	  scp_success=`$SCP -q $FULLNAME $OTHERUSER@$OTHERHOST:$BACKUPDIR`
      fi
      
     # if scp returns success, see if we should wipe
      if [[ scp_success -eq 0 && $WIPE_OLD_AFTER_SCP_FULL == "true" && $TYPE == "full" ]];
	  then

          # wipe out all similar backups except for the just-copied one
          for file in `ls $BACKUPDIR/*-$COMPUTER-${directory//\//-}-backup-*.tgz`
            do
            if [ $file != $FULLNAME]
                then
                rm $file
            fi
          done
          
      fi
  fi
  
done

# If full backup completed successfully, record the date so that
# incremental backups are relative to the last successful full
# backup

if [ $TYPE == "full" ];
    then
    NEWER=""
    NOW=`date +%Y-%m-%d`
    echo $NOW> $TIMEDIR/$COMPUTER-full-date;
fi

# Delete old files
/usr/bin/find $BACKUPDIR -atime +$KEEP_DAYS -exec /bin/rm -f {} \;

echo "Done."

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
BACKUPARCHIVE=""                    # optional directory for latest full backup per month
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
CP="/bin/cp"

#######################################################################
#
# Shouldn't need to change anything below this line 
#
#######################################################################

# Temporary outputs are always on the destination filesystem. Published backup
# files must be replaced by rename, never overwritten (monthly names may link).
TEMPFILE=""
cleanup_backup() {
    if [ -n "$TEMPFILE" ]; then
        rm -f -- "$TEMPFILE" "$TEMPFILE.gz"
    fi
}
backup_failed() {
    echo "Backup failed: $*" >&2
    exit 1
}
trap cleanup_backup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

DOW=`date +%a`              # Day of the week e.g. Mon
DOM=`date +%d`              # Date of the Month e.g. 27
DM=`date +%d%b`             # Date and Month e.g. 27Sep
DATE=`date +"%Y-%m-%d"`     # Year, Month, day, e.g. 2002-04-01
YEAR_MONTH=`date +"%Y-%m"`  # Year, Month, e.g. 2002-04

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
       TYPE="incremental"
       ;;
esac

if [ ! -s $TIMEDIR/$COMPUTER-full-date ];
    then 
    TYPE="full";
fi

if [[ $DOM == "01" || $DOW == "Sun" ]];
    then
    TYPE="full";
fi

#---------------------------------------------------------------------
# Check for free space
#---------------------------------------------------------------------
# get free byte count
mkdir -p "$BACKUPDIR" "$TIMEDIR" || backup_failed "creating backup directories"
if [ -n "$BACKUPARCHIVE" ]; then
    mkdir -p "$BACKUPARCHIVE" || backup_failed "creating monthly archive directory"
fi
free=$(df -Pk -- "$BACKUPDIR" | awk 'END {print $4}')
[[ $free =~ ^[0-9]+$ ]] || backup_failed "checking space in $BACKUPDIR"

# force to incremental if there isn't room for full
if [ $free -lt `expr $FULL_SPACE_FREE \* 1024 \* 1024` ];
    then
    [ -s "$TIMEDIR/$COMPUTER-full-date" ] || backup_failed "not enough space for the first full backup"
    TYPE="incremental"
    echo "Not enough free space for full backup; trying incremental"
fi

# abort if there isn't room for incremental
if [ $free -lt `expr $INCR_SPACE_FREE \* 1024 \* 1024` ];
    then
    echo "Not enough free space for backup; aborting"
    exit 1
fi


# Compute this after the space check, which can switch full to incremental.
if [ "$TYPE" == "full" ]; then
    NEW_FLAG=""
else
    NEW_FLAG="--newer-mtime $(cat "$TIMEDIR/$COMPUTER-full-date")"
fi

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
    TEMPFILE=$(mktemp "${dmp_file}.tmp.XXXXXX") || backup_failed "creating dump temporary file"
    time "$PG_BINDIR/pg_dump" -f "$TEMPFILE" -Fp "$dbname" -h "$DBHOST" || backup_failed "dumping $dbname"
    /bin/ls -lh "$TEMPFILE" | awk '{print $5}'
    gzip -f "$TEMPFILE" || backup_failed "compressing $dbname"
    mv -fT -- "$TEMPFILE.gz" "${dmp_file}.gz" || backup_failed "publishing dump $dbname"
    TEMPFILE=""
done

#---------------------------------------------------------------------
# Oracle
for dbname in $ORACLE8IDBS
do
    dmp_file=$WEBDIR/$dbname/database-backup/$dbname-nightly-backup.dmp
    echo -n "-> Dumping $dbname to $dmp_file ... "
    TEMPFILE=$(mktemp "${dmp_file}.tmp.XXXXXX") || backup_failed "creating Oracle dump temporary file"
    time /usr/sbin/export-oracle "$dbname" "$TEMPFILE" || backup_failed "dumping Oracle database $dbname"
    /bin/ls -lh "$TEMPFILE" | awk '{print $5}'
    gzip -f "$TEMPFILE" || backup_failed "compressing $dbname"
    mv -fT -- "$TEMPFILE.gz" "${dmp_file}.gz" || backup_failed "publishing dump $dbname"
    TEMPFILE=""
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
  FULL_MONTH_NAME=$BACKUPARCHIVE/$YEAR_MONTH-$COMPUTER-${directory//\//-}-backup-$TYPE.tar.gz

  # to use bzip2 instead of gzip, change z to j in the tar flags
  cd "$directory" || backup_failed "opening $directory"
  TEMPFILE=$(mktemp "$BACKUPDIR/.backup.XXXXXX") || backup_failed "creating archive temporary file"
  tar_status=0

  if [[ $RSYNC == "yes" ]]; then
      # Exclude at least on GNU Tar is picky about using the full patch and the order exclude and directoy.
      tar -zcph --file "$TEMPFILE" --exclude "$directory/content-repository-content-files" $NEW_FLAG "$directory" || tar_status=$?
  else
      tar -zcph . --file "$TEMPFILE" $NEW_FLAG || tar_status=$?
  fi

  # GNU tar status 1 reports files changing during this live backup; preserve
  # the old behavior, but warn. Fatal errors must not publish a partial archive.
  if [ "$tar_status" -eq 1 ]; then
      echo "Warning: files changed while backing up $directory" >&2
  elif [ "$tar_status" -ne 0 ]; then
      backup_failed "tar returned $tar_status for $directory"
  fi
  "$CHOWN" "$BACKUPUSER" "$TEMPFILE" || backup_failed "setting archive owner"
  "$CHMOD" 660 "$TEMPFILE" || backup_failed "setting archive permissions"
  mv -fT -- "$TEMPFILE" "$FULLNAME" || backup_failed "publishing $FULLNAME"
  TEMPFILE=""


  if [ "$TYPE" == "full" ] && [ -n "$BACKUPARCHIVE" ]; then
     TEMPFILE=$(mktemp "$BACKUPARCHIVE/.backup.XXXXXX") || backup_failed "creating monthly temporary file"
     # Link when possible; copy automatically across filesystems. Keep the old
     # monthly archive intact until its replacement has completed successfully.
     if ! ln -f -- "$FULLNAME" "$TEMPFILE" 2>/dev/null; then
         "$CP" -p -- "$FULLNAME" "$TEMPFILE" || backup_failed "copying monthly archive"
     fi
     mv -fT -- "$TEMPFILE" "$FULL_MONTH_NAME" || backup_failed "publishing monthly archive"
     TEMPFILE=""
  fi

  if [ -n "$OTHERHOST" ]
      then 
      
      scp_success=1
      if [[ $RSYNC == "yes" ]];
	  then
	  rsync -aq "$BACKUPDIR" "$OTHERUSER@$OTHERHOST:$BACKUPDIR" || backup_failed "remote rsync"
          scp_success=0
      else
	  $SCP -q "$FULLNAME" "$OTHERUSER@$OTHERHOST:$BACKUPDIR" || backup_failed "remote scp"
          scp_success=0
      fi
      
     # if scp returns success, see if we should wipe
      if [[ scp_success -eq 0 && $WIPE_OLD_AFTER_SCP_FULL == "true" && $TYPE == "full" ]];
	  then

          # wipe out all similar backups except for the just-copied one
          for file in `ls $BACKUPDIR/*-$COMPUTER-${directory//\//-}-backup-*.tgz`
            do
            if [ "$file" != "$FULLNAME" ]
                then
                rm -- "$file" || backup_failed "removing transferred backup"
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
    NOW=$DATE
    TEMPFILE=$(mktemp "$TIMEDIR/.full-date.XXXXXX") || backup_failed "creating full-backup date temporary file"
    echo "$NOW" > "$TEMPFILE" || backup_failed "writing full-backup date"
    mv -fT -- "$TEMPFILE" "$TIMEDIR/$COMPUTER-full-date" || backup_failed "publishing full-backup date"
    TEMPFILE=""
fi

# Delete old files
# Expire only this script's regular backup files, based on modification time.
# Keep the current full/incremental chain even if the next full backup is late.
BASE_DATE=$(cat "$TIMEDIR/$COMPUTER-full-date") || backup_failed "reading retention baseline"
[[ $BASE_DATE =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || backup_failed "invalid retention baseline"
TEMPFILE=$(mktemp "$TIMEDIR/.retention.XXXXXX") || backup_failed "creating retention list"
/usr/bin/find "$BACKUPDIR" -maxdepth 1 -type f -mtime +"$KEEP_DAYS" -print0 > "$TEMPFILE" || backup_failed "listing expired backups"
while IFS= read -r -d '' file; do
    name=${file##*/}
    if [[ $name == ????-??-??-"$COMPUTER"-*-backup-full.tar.gz ||
          $name == ????-??-??-"$COMPUTER"-*-backup-incremental.tar.gz ]]; then
        file_date=${name:0:10}
        if [[ $file_date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ && $file_date < $BASE_DATE ]]; then
            /bin/rm -f -- "$file" || backup_failed "removing $file"
        fi
    fi
done < "$TEMPFILE"
rm -f -- "$TEMPFILE" || backup_failed "removing retention list"
TEMPFILE=""

echo "Done."

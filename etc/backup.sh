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
#
# Change the variables below to fit your computer/backup
#

COMPUTER=yourserver.net              # name of this computer
BACKUPUSER=backup                    # username to own the files
BACKUPDIR=/backup/thisserver         # where to store the backups
WEBDIR=/var/lib/aolserver            # path to OpenACS service root
PG_BINDIR=/usr/local/pgsql/bin       # path to PostGreSQL binaries
TIMEDIR=$BACKUPDIR/last-full         # where to store time of full backup
TAR=/bin/tar                         # name and location of tar
CHOWN=/bin/chown
CHMOD=/bin/chmod
SCP="/usr/bin/scp -oProtocol=2"
OTHERHOST=otherserver.net            # another server, to receive backup
                                     # files
                                     # leave blank to skip scp exchange

OTHERUSER=backup                     # the user on the recipient server
                                     # must have silent authentication, ie,
                                     # certificates

                                     # script assumes an exact match between database
                                     # name and filesystem
POSTGRES_DBS="service0"              # space-separated list of postgres databases
                                     # to be backed up to file system

ORACLE8I_DBS="service0"              # space-separated list of Oracle8i databases
                                     # to be backed up to file system

                                     # space-separated list of directories to be backed up
DIRECTORIES="/etc /home /root /cvsroot /var/qmail/alias /usr/local/aolserver /var/lib/aolserver"

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
        NEWER=""
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

if [[ $DOM = "01" || $DOW = "Sun" ]];
    then
    TYPE="full";
fi

if $TYPE == "full";
    then
    NEWER=""
    NOW=`date +%Y-%m-%d`
    echo $NOW> $TIMEDIR/$COMPUTER-full-date;
else
    TYPE="incremental"
    NEWER="--newer-mtime `cat $TIMEDIR/$COMPUTER-full-date`";
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
    time $PG_BINDIR/pg_dump -f $dmp_file -Fp $dbname
    /bin/ls -lh $dmp_file | awk '{print $5}'
    gzip $dmp_file
done

#---------------------------------------------------------------------
# Oracle
for dbname in $ORACLE8IDBS
do
    dmp_file=$WEBDIR/$dbname/database-backup/$dbname-nightly-backup.dmp
    echo -n "-> Dumping $dbname to $dmp_file ... "
    time /usr/sbin/export-oracle $dbname $dmp_file
    /bin/ls -lh $dmp_file | awk '{print $5}'
    gzip $dmp_file
done

#---------------------------------------------------------------------
# Make backup files from file system and transfer to remote site
# TODO: This could be parallelized
#---------------------------------------------------------------------

for directory in $DIRECTORIES

  do

  # strip directory of slashes when using it in the backup file name
  FULLNAME=$BACKUPDIR/$DATE-$COMPUTER-${directory//\//-}-backup-$TYPE.tar.bz2
  echo tar -jcpsh $NEWER --file $FULLNAME $directory
  $CHOWN $BACKUPUSER $FULLNAME
  $CHMOD 660 $FULLNAME
  if [[ -n $OTHERHOST ]]
      then echo $SCP $FULLNAME $OTHERUSER@$OTHERHOST:$BACKUPDIR
  fi
done

echo "Done."


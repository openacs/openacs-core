#!/usr/local/bin/perl

##########################################################
# ArsDigita Context Server
#    mbryzek@arsdigita.com
#    1/20/2000
##########################################################
# Revision History:
# 
# 04/24/2000  mbryzek  Revised documentation
##########################################################
# MOTIVATION:
# Updating Intermedia indexes sucks. Intermedia
# Context server is deprecated according to some people
# at Intermedia. And aolserver with keepalive can restart 
# itself making it very difficult to ensure that two alter 
# index statements are not running at the same time.
### 
# FUNCTION:
# This script is intended to run as a cron job on 
# each machine that is running Intermedia. We 
# recommend running it no more frequently than once
# an hour. This script generates a list of intermedia 
# indexes that are awaiting updates, and updates them.
#
# This scripts connects to the database as the ctxsys user,
# generates a list of indexes to updates, and then issues
# alter index statements on all of those indexes. All sql
# queries run and the total run time are logged in 
# /tmp/ad-context-server.log
#
# Note that this script does NOT need to be run as 
# root, but it doesn't hurt.
###
# SETUP
# 1. Install the perl DBI and Oracle DBD
#
# 2. Put the username for your service in @services
#
# 3. Set variables in USER CONFIGURATION
#    a. Make sure $username = ctxsys and $password is 
#       the current password for the ctxsys user. 
#    b. Make sure $ps_path points to ps on your box
#    c. Make sure the environment variables are correct
# 
# 4. Put script in crontab:
# 
#    # ad-context-server monitors all Intermedia indexes
#    # on the system, updating those that need it.
#    # DO NOT RUN ad-context-server.pl IN PARALLEL 
#    # WITH INTERMEDIA CONTEXT SERVER (ctxsrv) AND DO 
#    # NOT EVER ISSUE AN ALTER INDEX STATEMENT ON AN
#    # INTERMEDIA INDEX WHILE THIS IS RUNNING.
#    # Currently runs every hour on the hour
#    0 *    * * *     /usr/local/bin/ad-context-server.pl > /dev/null 2>&1
#
##########################################################

# USER CONFIGURATION

# You have to list every service's username for which you want to update
# the intermedia indexes. The oracle username must be in uppercase
my @services = qw(YOURSERVICENAME);

# connect to oracle with the context user - we need to access to the 
# view ctx_pending. You probably don't want to change $username, but 
# make sure $password is the ctxsys user's password. 
my $username = 'ctxsys';
my $password = 'ctxsucks';

# We need to run ps -p PID... where is ps?
my $ps_path = '/bin/ps';

# ORACLE ENVIRONMENT CONFIGURATION
$ENV{ORACLE_HOME} = "/ora8/m01/app/oracle/product/8.1.5";
$ENV{ORACLE_BASE} = "/ora8/m01/app/oracle";
$ENV{LD_LIBRARY_PATH} = "$ENV{ORACLE_HOME}/lib:$ENV{ORACLE_HOME}/ctx/lib:/usr/lib:/lib:/usr/openwin/lib:/usr/ucblib";
$ENV{PATH} = "$ENV{ORACLE_HOME}/bin:$ENV{ORACLE_HOME}/ctx/lib:/usr/ccs/bin:$ENV{PATH}";
$ENV{ORACLE_SID} = 'ora8';
$ENV{ORACLE_TERM} = 'vt100';
$ENV{ORAENV_ASK} = 'NO';

# END USER CONFIGURATION
# Make this local so ad_context_server_exit 
# can see the filename to clean it up
local $pid_file = '/tmp/ad-context-server.pid';

# Exit if there are no services to update
ad_context_server_exit(0) if @services == 0;

# Let's see if there is already an ad-context-server running. 
# If there is, we want to bail out since InterMedia is not too good 
# at concurrency (e.g. 2 concurrent updates lead to deadlock which 
# may corrupt the index, causing a rebuild)
if ( -e $pid_file ) {
    # The file exists... let's see if the process is still running
    open PID, $pid_file;
    my $pid = <PID>;
    close PID;
    chomp($pid);
    my $ps = `$ps_path -p $pid`;
    # Now let's see if the pid is in the output of ps
    ad_context_server_exit(0) if $ps =~ /$pid/;
}

# Print the current process id to $pid_file
open PID, ">$pid_file" || ad_context_server_exit(0);
print PID $$;
close PID;

# Let's create the sql portion of the query for service names
my $service_sql = "'";
$service_sql .= join "','", @services;
$service_sql .= "'";

# Connect to oracle
use DBI;
my $dbh = DBI->connect('dbi:Oracle:', $username, $password) || die "Couldn't connect to oracle\n";  

# Grab all index owners and names that need update. Create a temporary 
# file to source that contains the alter index statements

my $sql_query = << "eof";
select distinct pnd_index_owner||'.'||pnd_index_name 
from ctx_pending 
where pnd_index_owner in ($service_sql)
eof

my $tmp_file = '/tmp/ad-context-server.log';
open TMP, ">$tmp_file" || ad_context_server_exit(0);
print TMP "-- SQL QUERY USED TO GET INDEXES (AS USER $username):\n$sql_query\n";
my $sth = $dbh->prepare($sql_query) || die $dbh->errstr;
$sth->execute;
my $cnt = 0;
while ($index = $sth->fetchrow) {
    $cnt++;
    print TMP "alter index $index rebuild online parameters('sync memory 45M');\n";
}
# log the start time
my $time = localtime();
print TMP "-- $time: Starting intermedia updates\n";
close TMP;

# Disconnect
$sth->finish || die($dbh->errstr);
$dbh->disconnect || die $dbh->errstr;
 
# do the updates
`$ENV{ORACLE_HOME}/bin/sqlplus $username/$password < $tmp_file`;

# Write the status to the temp _file - more for logging purposes :)
$time = localtime();
open TMP, ">>$tmp_file" || ad_context_server_exit(0);
if ( $cnt > 0 ) {
    print TMP "-- $time: Finished executing the above alter statements\n";
} else {
    print TMP "-- $time: Nothing to update!\n";
}
close TMP;

ad_context_server_exit(0);


# Cleans up the pid file and exits with status 0
# References $pid_file 
sub ad_context_server_exit {
    unlink $pid_file if -e $pid_file;
    exit(0);
}


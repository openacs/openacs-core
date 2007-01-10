#!/bin/sh
#
# A simple tcl script to be run from the commandline which will output
# SQL statements suitable for pasting in srvmgrl to drop and create
# a new tablespace. 
#
# Call it without arguments to see a short usage message.
#
#
# Based on a sql script from S&R (http://www.sussdorff-roy.com),
# licensed under GPL2. Complaints to tils-oacs@tils.net please. See
# http://pinds.com/acs-tips/oracle-statements for an online version
# of this and maybe some helpful comments.
#

# the next line restarts using tclsh \
exec tclsh "$0" "$@"

if { $argc < 1 || $argc > 3 } {
    puts "Usage:

./create-tablespace.tcl service_name \[database_password\] \[oracle_data_path\]

This will output the sql statements needed to create the tablespace.
You have to copy and paste the statements into svrmgrl.

If you don't specify database_password then the service name will be
used as password.

If you don't specify oracle_data_path then the default
/ora8/m02/oradata/ora8/ will be used.

"
    exit
}

set service_name [lindex $argv 0]

if { $argc < 2 } {
    # default pwd
    set database_password "${service_name}"
} else {
    # pwd specified
    set database_password [lindex $argv 1]
}

if { $argc < 3 } {
    # default oracle_data_path
    set oracle_data_path "/ora8/m02/oradata/ora8/"
} else {
    # oracle_data_path specified. make sure it has a trailing slash.
    set oracle_data_path [lindex $argv 2]
    if { [string index $oracle_data_path end] ne "/" } {
	set oracle_data_path "${oracle_data_path}/"
    }
}

puts " \

spool create-${service_name}.log

REM * Start the instance (ORACLE_SID must be set).
REM * We expect the database to already be started.
REM *

connect internal
drop user ${service_name} cascade;
drop tablespace ${service_name} including contents;

REM * Create user and tablespace for live site
REM *
create tablespace ${service_name}
  datafile '${oracle_data_path}${service_name}01.dbf' size 50m autoextend on next 640k maxsize 2147450880 extent management local uniform size 160K;

create user ${service_name} identified by ${database_password}
  default tablespace ${service_name} 
  temporary tablespace temp 
  quota unlimited on ${service_name};

grant connect, resource, ctxapp, javasyspriv, query rewrite to ${service_name};

grant create table, select any table, create materialized view, connect, resource, ctxapp, javasyspriv, query rewrite to ${service_name};

revoke unlimited tablespace from ${service_name};

alter user ${service_name} quota unlimited on ${service_name};

REM * Allow user to use autotrace
connect ${service_name}/${database_password}
@/ora8/m01/app/oracle/product/8.1.7/rdbms/admin/utlxplan.sql

REM * All done, so close the log file and exit.
REM *
spool off
exit

"

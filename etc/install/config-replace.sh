#!/bin/sh
#
# There is some degree of duplication of parameters in the etc/install/install.tcl file
# and the etc/config.tcl file. This script will take parameter values in install.tcl
# and insert them in the config.tcl file so that the two are in sync.
#
#
# The next line restarts using tclsh. Do not remove this backslash: \
exec tclsh "$0" "$@"

set install_file_path [lindex $argv 0]

source $install_file_path

#----------------------------------------------------------------------
# Replace variables in config.tcl
#----------------------------------------------------------------------

# Left side = install.tcl, right side = config.tcl
array set __replace_with {
    server          server
    serverroot      serverroot
    httpport        server_port
    hostname        server_host
    address         server_ip
    servername      system_name
    homedir         aolserver_home
    database        database
    db_name         db_name     
    db_password     oracle_password
    db_host         pg_host
    db_port         pg_port
    db_user         pg_db_user
}

set __config_file_path "${serverroot}/etc/config.tcl"
set __fd [open $__config_file_path]
set __config_text [read $__fd]
close $__fd

set __output {}
foreach __line [split $__config_text \n] {
    if { [regexp {^(\s*)set\s+([^\s]+)\s+} $__line match __whitespace __varname] } {
        if { [info exists __replace_with($__varname)] } {
            append __output $__whitespace [list set $__varname [set $__replace_with($__varname)]] \n
            continue
        }
    }
    append __output $__line \n
}

set __new_config_file_path "${__config_file_path}.new"
set __fd [open $__new_config_file_path w]
puts $__fd $__output
close $__fd

# Rename
file delete "${__config_file_path}.bak"
file rename $__config_file_path "${__config_file_path}.bak"
file rename $__new_config_file_path $__config_file_path

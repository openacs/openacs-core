#!/bin/sh
#
# This script will attempt to request the db test page of a number of OpenACS
# servers. If a server doesn't respond then a configurable restart shell command will
# be executed. The restart command may for example send an email alert and/or log to some
# log file and then restart the server. The URLs of the servers to monitor and their
# restart commands are expected to be in a config file named keepalive-config.tcl 
# in the same directory as this script
#
# @author Peter Marklund

# the next line restarts using tclsh, the trailing slash is intentional \
exec tclsh "$0" "$@"

set script_dir [file dirname [info script]]

source $script_dir/keepalive-config.tcl

global restart_time_file
set restart_time_file $script_dir/last-restart-time

proc read_file { file_path } {
    set file_id [open $file_path r]
    set file_contents [read $file_id]
    close $file_id    

    return $file_contents
}

proc server_responds_p { server_url } {

    set script_dir [file dirname [info script]]
    set wget_file $script_dir/dbtest
    if { [file exists $wget_file] } {
        file delete -force $wget_file
    }

    if { [catch {exec wget --timeout 6 --output-document $wget_file --tries=3 ${server_url}/SYSTEM/dbtest} errmsg] } {
        #puts "wget threw error $errmsg"
    }

    if { [file exists $wget_file] } {
	set wget_file_contents [read_file $wget_file]
	
	if { [regexp -nocase {^\s*success\s*$} $wget_file_contents] } {
	    set responds_p 1
	} else {
	    set responds_p 0
	}
    } else {
	set responds_p 0
    }

    return $responds_p
}

proc waiting_for_restart_p { seconds_between_restarts } {

    global restart_time_file

    if { [file exists $restart_time_file] } {
	set last_restart_time [string trim [read_file $restart_time_file]]
	set current_time [clock seconds]
	set time_since_restart [expr $current_time - $last_restart_time]

	if { [expr $time_since_restart > $seconds_between_restarts] } {
	    return 0
	} else {
	    return 1
	}
    } else {
	# This is the first restart
        return 0
    }
}

proc record_current_time { file } {
    set fd [open $file w]
    puts $fd [clock seconds]
    close $fd
}

foreach {server_url restart_command} $servers_to_monitor {

    #puts -nonewline "Checking server at $server_url - "
    if { [server_responds_p $server_url] } {
        #puts "server responds."
    } else {
        #puts -nonewline "no response. "

	# Only restart server if we didn't recently restart it
	if { ![waiting_for_restart_p $seconds_between_restarts] } {
	    puts "Executing command \"$restart_command\" to restart server at $server_url."
	    if { [catch {eval exec $restart_command} errmsg] } {
		puts "Error executing restart_command: $errmsg"
	    }

	    # Record new restart time
	    global restart_time_file
	    record_current_time $restart_time_file
        } else {
	    puts "Server at $server_url has been restarted within last $seconds_between_restarts seconds so not restarting yet"
	}
    }
}

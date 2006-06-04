#!/bin/sh
#
# This script will attempt to request the db test page of a number of OpenACS
# servers. If a server doesn't respond then a configurable restart shell command will
# be executed. The restart command may for example send an email alert and/or log to some
# log file and then restart the server. The URLs of the servers to monitor and their
# restart commands are expected to be in a config file named keepalive-config.tcl 
# in the same directory as this script
#
# If you're having problems with this script, you should look at this thread:
# http://openacs.org/forums/message-view?message_id=260846
#
# @author Peter Marklund

# the next line restarts using tclsh, the trailing slash is intentional \
exec /usr/bin/tclsh "$0" "$@"

set script_dir [file dirname [info script]]

source $script_dir/keepalive-config.tcl

proc server_responds_p { server_url } {

    set script_dir [file dirname [info script]]
    set wget_file $script_dir/dbtest
    if { [file exists $wget_file] } {
        file delete -force $wget_file
    }

    catch {exec /usr/bin/wget -O $wget_file --tries=5 ${server_url}/SYSTEM/dbtest}

    if { [file exists $wget_file] } {
          set wget_file_id [open $wget_file r]
          set wget_file_contents [read $wget_file_id]
          close $wget_file_id
          if { [regexp {success} $wget_file_contents] } {
              set responds_p 1
          } else {
              set responds_p 0
          }
      } else {
          set responds_p 0
      }

      return $responds_p
}

foreach {server_url restart_command} $servers_to_monitor {

    if { ![server_responds_p $server_url] } {
        if { [catch {eval exec $restart_command} errmsg] } {
	    catch { exec /bin/mail -s "${server_url} did not respond to a monitoring check and could not be restarted" $mailto }
        } else {
	    catch { exec /bin/mail -s "${server_url} did not respond to a monitoring check so it was restarted" $mailto }
	}
    }
}

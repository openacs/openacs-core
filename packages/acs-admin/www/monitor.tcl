ad_page_contract {
    Show list of active connections, plus uptime status about the box.
}

set page_title "Active Connections"
set context [list $page_title]

#AG: removed the call to ns_server.  It's not thread safe!  We think
#it is crashing our server.  See NOTES section of this page for more info:
#  http://panoptic.com/wiki/aolserver/ns_server
#Happily, the same information can be derived from ns_info threads, which
#gets the information in a different way.

set threads [ns_info threads]
set connections [list]
foreach thread $threads {
    if { [lindex $thread 5] eq "ns:connthread" && [llength [lindex $thread 6]] > 0 } {
	lappend connections [lindex $thread 6]
    }
}

array set ip_p [list]

multirow create connections num ip state method url seconds bytes

foreach connection $connections {
    multirow append connections \
        [lindex $connection 0] \
        [lindex $connection 1] \
        [lindex $connection 2] \
        [lindex $connection 3] \
        [lindex $connection 4] \
        [lindex $connection 5] \
        [lindex $connection 6]

    set ip_p([lindex $connection 1]) 1
}

template::list::create \
    -name connections \
    -multirow connections \
    -elements {
        num {
            label "Conn\#"
        }
        ip {
            label "IP"
        }
        state {
            label "State"
        }
        method {
            label "Method"
        }
        url {
            label "URL"
        }
        seconds {
            label "\# Seconds"
        }
        bytes {
            label "Bytes"
        }
    }

set distinct [array size ip_p]

# run standard GNU uptime command to get load average (crude measure
# of system health).
if {[set uptime [util::which uptime]] eq ""} {
    error "'uptime' command not found on the system"
}

if {[catch { set uptime_output [exec $uptime] } errmsg]} {
   # whoops something wrong with uptime (check path)
   set uptime_output "ERROR running uptime, check path in script"
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

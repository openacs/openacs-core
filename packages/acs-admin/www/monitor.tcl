ad_page_contract {
    Show list of active connections, plus uptime status about the box.
}

set page_title "Active Connections"
set context [list $page_title]

set connections [ns_server active]

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

set distinct [llength [array names ip_p]]

# run standard Unix uptime command to get load average (crude measure of 
# system health)

if [catch { set uptime_output [exec /usr/bin/uptime] } errmsg] {
   # whoops something wrong with uptime (check path)
   set uptime_output "ERROR running uptime, check path in script"
}

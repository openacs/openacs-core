ad_page_contract {
    Performs util_memoize_flush_local on the statement parameter.

    @author Jon Salz [jsalz@mit.edu]
    @creation-date 29 Feb 2000
    @cvs-id $Id$
} { 
    statement
}

if { ![server_cluster_authorized_p [ns_conn peeraddr]] } {
    ns_returnforbidden
    return
}

util_memoize_flush_local [ns_queryget statement]

if { [server_cluster_logging_p] } {
    ns_log "Notice" "Distributed flush of [ns_queryget statement]"
}
doc_return 200 "text/plain" "Successful."

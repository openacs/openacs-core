ad_library {
    Provides methods for communicating between load-balanced servers.

    @cvs-id $Id$
    @author Jon Salz <jsalz@mit.edu>
    @creation-date 7 Mar 2000
}

ad_proc server_cluster_enabled_p {} {

    Returns true if clustering is enabled.

} {
    return [parameter::get \
                -package_id $::acs::kernel_id \
                -parameter ClusterEnabledP \
                -default 0]
}

ad_proc server_cluster_all_hosts {} {

    Returns a list of all hosts in the server cluster, possibly
    including the current host.

} {
    if { ![server_cluster_enabled_p] } {
        return {}
    }
    #
    # For now, include the CanonicalServer as well in the all_hosts
    # list, since the eases the configuration. Later, we might want to
    # have a canonical server, which is not a worker node, so it would
    # not need to receive all the cache-flush operations.
    #
    set canonicalServer [acs::cluster eval {
        :preferred_location [:qualified_location  [parameter::get -package_id $::acs::kernel_id -parameter CanonicalServer]]
    }]
    set nodes [lsort -unique [concat \
                                  $canonicalServer \
                                  [parameter::get -package_id $::acs::kernel_id -parameter ClusterPeerIP] \
                                  [parameter::get -package_id $::acs::kernel_id -parameter DynamicClusterPeers] ]]

    #ns_log notice "server_cluster_all_hosts returns <$nodes>"
    return $nodes
}

ad_proc -private ad_canonical_server_p {} {

    Returns true if this is the primary (called historically
    "canonical") server, false otherwise.

    This function is e.g. used to determine, whether scheduled
    procedures are run on the current node.

    @return boolean value
} {
    if {[server_cluster_enabled_p]} {
        return [::acs::cluster current_server_is_canonical_server]
    } else {
        error "ad_canonical_server_p is called, but the cluster is not enabled"
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

#
# Check if cluster is enabled, and if, set up the custer objects
#
ns_log notice "cluster-init: server_cluster_enabled_p: [server_cluster_enabled_p]"
if {[server_cluster_enabled_p]} {

    #
    # Check, whether the secret for intra-cluster communication is
    # properly defined. If not, then do not activate cluster mode.
    #
    if {![::acs::cluster secret_configured]} {
        ns_log error "cluster-init: cluster setup aborted:" \
            "the cluster secret is missing." \
            "Deactivated cluster mode."

        proc server_cluster_enabled_p {} { return 0 }
        return
    }

    #
    # Perform setup only once (not in every object creation in new
    # threads).
    #
    ns_log notice "cluster-init: performing cluster setup"
    ::acs::cluster setup
    ns_log notice "cluster-init: performing cluster setup DONE"

    #
    # Update the cluster info depending of the configured
    # ClusterHeartbeatInterval to detect changed cluster
    # configurations (maybe induced by missing reachability).
    # This has to happen on all cluster nodes.
    #
    ad_schedule_proc -all_servers t \
        [parameter::get \
             -package_id $::acs::kernel_id \
             -parameter ClusterHeartbeatInterval \
             -default 20s] \
        ::acs::cluster update_node_info

    #
    # Liveliness manager (running on the canonical server). It checks
    # e.g. whether dynamic nodes should be deleted from the dynamic
    # cluster nodes list automatically after some time of being not
    # reachable.
    #
    ad_schedule_proc 5s ::acs::cluster check_state


    #
    # Setup of the listening URL
    #
    set url [::acs::cluster cget -url]

    # Check, if the filter URL mirrors a site node. If so,
    # the cluster mechanism will not work, if the site node
    # requires a login. Clustering will only work if the
    # root node is freely accessible.

    set node_info [site_node::get -url $url]
    if {[dict get $node_info url] ne "/"} {
        ns_log warning "***\n*** WARNING: there appears a package mounted on" \
            "$url\n***Cluster configuration will not work" \
            "since there is a conflict with the filter with the same name! (n)"
    } else {

        #ns_register_filter trace GET $url ::acs::cluster
        ns_register_filter preauth GET $url ::acs::cluster
        #ns_register_filter postauth GET $url ::acs::cluster
        #ad_register_filter -priority 900 preauth GET $url ::acs::cluster

        ns_register_proc GET $url ::acs::cluster incoming_request
    }

    #
    # Register the nodes, which are reachable at startup time.
    #
    ::acs::cluster register_nodes -startup

    ns_atstartup {
        ns_log notice "acs::cluster starting:" \
            "running as canonical server [::acs::cluster current_server_is_canonical_server]," \
            "cluster nodes: [nsv_get cluster cluster_peer_nodes]"
    }

    #
    # Register callback for shutdown operations. When the shutdown is
    # performed at a dynamic cluster node, disconnect the node from the
    # cluster.
    #
    ns_atshutdown {
        if {[::acs::cluster current_server_is_canonical_server]} {
            ns_log notice "acs::cluster: shutdown canonical server"
        } elseif {[::acs::cluster current_server_is_dynamic_cluster_peer]} {
            ns_log notice "acs::cluster: shutdown dynamic cluster peer (perform disconnect operation)"
            acs::cluster send_disconnect_request_to_canonical_server
        } else {
            ns_log notice "acs::cluster: shutdown static cluster peer"
        }
    }
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

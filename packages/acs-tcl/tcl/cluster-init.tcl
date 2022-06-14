#
# Check if cluster is enabled, and if, set up the custer objects
#
if {[server_cluster_enabled_p]} {
    set myConfig [server_cluster_my_config]
    set cluster_do_url [::acs::Cluster eval {set :url}]

    #
    # Iterate over all servers in the cluster and add Cluster objects
    # for the ones, which are different from the current host (the
    # peer hosts).
    #
    foreach hostport [server_cluster_all_hosts] {
        set config [server_cluster_get_config $hostport]
        dict with config {
            if {$host in [dict get $myConfig host]
                && $port in [dict get $myConfig port]
            } {
                ns_log notice "Cluster: server $host $port is no cluster peer"
                continue
            }
            ns_log notice "Cluster: server $host $port is a cluster peer"
            ::acs::Cluster create CS_${host}_${port} \
                -proto $proto \
                -host $host \
                -port $port \
                -url $cluster_do_url
        }
    }

    foreach ip [parameter::get -package_id $::acs::kernel_id -parameter ClusterAuthorizedIP] {
        if {[string first * $ip] > -1} {
            ::acs::Cluster eval [subst {
                lappend :allowed_host_patterns $ip
            }]
        } else {
            ::acs::Cluster eval [subst {
                set :allowed_host($ip) 1
            }]
        }
    }

    set url [::acs::Cluster eval {set :url}]

    # Check, if the filter URL mirrors a site node. If so,
    # the cluster mechanism will not work, if the site node
    # requires a login. Clustering will only work if the
    # root node is freely accessible.

    set node_info [site_node::get -url $url]
    if {[dict get $node_info url] ne "/"} {
        ns_log notice "***\n*** WARNING: there appears a package mounted on" \
            "$url\n***Cluster configuration will not work" \
            "since there is a conflict with the filter with the same name! (n)"
    }

    #ns_register_filter trace GET $url ::acs::Cluster
    ns_register_filter preauth GET $url ::acs::Cluster
    #ad_register_filter -priority 900 preauth GET $url ::acs::Cluster
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

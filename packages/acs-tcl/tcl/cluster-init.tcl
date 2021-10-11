#
# Check if cluster is enabled, and if, set up the custer objects
#
if {[server_cluster_enabled_p]} {
    set driver_section [ns_driversection -driver nssock]
    set my_ips   [ns_config $driver_section address]
    set my_ports [ns_config -int $driver_section port]

    set cluster_do_url [::acs::Cluster eval {set :url}]

    foreach hostport [server_cluster_all_hosts] {
        set d {port 80}
        set d [dict merge $d [ns_parsehostport $hostport]]
        dict with d {
            if {$host in $my_ips && $port in $my_ports} {
                ns_log notice "Cluster: server $host $port is no cluster peer"
                continue
            }
            ns_log notice "Cluster: server $host $port is a cluster peer"
            ::acs::Cluster create CS_${host}_${port} \
                -host $host \
                -port $port \
                -url $cluster_do_url
        }
    }

    foreach ip [parameter::get -package_id [ad_acs_kernel_id] -parameter ClusterAuthorizedIP] {
        if {[string first * $ip] > -1} {
            ::acs::Cluster eval [subst {
                lappend allowed_host_patterns $ip
            }]
        } else {
            ::acs::Cluster eval [subst {
                set :allowed_host($ip) 1
            }]
        }
    }

    set url [::acs::Cluster eval {set :url}]

    #
    # TODO: The following test does not work yet, since
    # "::xo::db::sql::site_node" is not yet defined. This requires
    # more refactoring from xo* to the main infrastructure.
    #
    if {0} {
        # Check, if the filter url mirrors a site node. If so,
        # the cluster mechanism will not work, if the site node
        # requires a login. Clustering will only work if the
        # root node is freely accessible.

        array set node [site_node::get -url $url]
        if {$node(url) ne "/"} {
            ns_log notice "***\n*** WARNING: there appears a package mounted on" \
                "$url\n***Cluster configuration will not work" \
                "since there is a conflict with the filter with the same name! (n)"
        }
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

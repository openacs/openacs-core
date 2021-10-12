ad_library {
    Provides methods for communicating between load-balanced servers.

    @cvs-id $Id$
    @author Jon Salz <jsalz@mit.edu>
    @creation-date 7 Mar 2000
}

ad_proc server_cluster_enabled_p {} { Returns true if clustering is enabled. } {
    return [parameter::get \
                -package_id $::acs::kernel_id \
                -parameter ClusterEnabledP \
                -default 0]
}

ad_proc server_cluster_all_hosts {} {

    Returns a list of all hosts, possibly including this host, in the
    server cluster.

} {
    if { ![server_cluster_enabled_p] } {
        return {}
    }
    return [parameter::get -package_id $::acs::kernel_id -parameter ClusterPeerIP]
}

ad_proc server_cluster_peer_hosts {} {

    Returns a list of all hosts, excluding this host, in the server cluster.

} {
    return [lmap cluster_server [::acs::Cluster info instances] {
        util::join_location \
            -hostname [$cluster_server cget -host] \
            -port [$cluster_server cget -port]
    }]
}

ad_proc server_cluster_authorized_p { ip } {

    Can a request coming from $ip be a valid cluster request, i.e.,
    matches some value in ClusterAuthorizedIP or is 127.0.0.1?

} {
    if { ![server_cluster_enabled_p] } {
        return 0
    }

    if { $ip == "127.0.0.1" } {
        return 1
    }

    foreach glob [parameter::get -package_id $::acs::kernel_id -parameter ClusterAuthorizedIP] {
        if { [string match $glob $ip] } {
            return 1
        }
    }
    return 0
}

ad_proc -private server_cluster_my_config {} {
} {
    set driver_section [ns_driversection -driver nssock]
    set my_ips   [ns_config $driver_section address]
    set my_ports [ns_config -int $driver_section port]
    return [list host $my_ips port $my_ports]
}

ad_proc -private server_cluster_get_config {hostport} {
    Return a dict parsed from the host and port spec.
    If no port is specified, it defaults to 80

    @param hostport IP address with optional port
    @return dict containing host and port
} {
    set d {port 80}
    return [dict merge $d [ns_parsehostport $hostport]]
}


ad_proc -private ad_canonical_server_p {} {

    Returns true if this is the primary (called historically
    "canonical") server, false otherwise.

    Since the server can listen to multiple IP addresses and on
    multiple ports, all of these have to be checked.
} {
    set canonical_server [parameter::get -package_id $::acs::kernel_id -parameter CanonicalServer]
    if { $canonical_server eq "" } {
        ns_log Error "Your configuration is not correct for server clustering." \
            "Please ensure that you have the CanonicalServer parameter set correctly."
        return 1
    }

    set myConfig [server_cluster_my_config]
    set canonicalConfig [server_cluster_get_config $canonical_server]
    #
    # Both, myConfig and canonicalConfig can contain multiple IP
    # addressen and ports.
    #
    foreach my_ip [dict get $myConfig host] {
        foreach my_port [dict get $myConfig port] {
            dict with canonicalConfig {
                if {$my_ip in $host && $my_port in $port} {
                    return 1
                }
            }
        }
    }
    return 0
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

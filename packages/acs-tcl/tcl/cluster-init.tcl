#
# Check if cluster is enabled, and if, set up the custer objects
#
if {[server_cluster_enabled_p]} {
    set my_ip   [ns_config ns/server/[ns_info server]/module/nssock Address]
    set my_port [ns_config ns/server/[ns_info server]/module/nssock port]
    
    foreach host [server_cluster_all_hosts] {
	set port 80
	regexp {^(.*):(.*)} $host _ host port
	if {"$host-$port" eq "$my_ip-$my_port"}  continue
	::acs::Cluster create CS_${host}_$port -host $host -port $port
    }
    
    foreach ip [parameter::get -package_id [ad_acs_kernel_id] -parameter ClusterAuthorizedIP] {
	if {[string first * $ip] > -1} {
	    ::acs::Cluster eval [subst {
		:lappend allowed_host_patterns $ip
	    }]
	} else {
	    ::acs::Cluster eval [subst {
		set :allowed_host($ip) 1
	    }]
	}
    }
    
    set url [::acs::Cluster eval {set :url}]

    # Check, if the filter url mirrors a site node. If so,
    # the cluster mechanism will not work, if the site node
    # requires a login. Clustering will only work if the
    # root node is freely accessible.

    array set node [site_node::get -url $url] 
    if {$node(url) ne "/"} {
	ns_log notice "***\n*** WARNING: there appears a package mounted on\
       $url\n***Cluster configuration will not work\
       since there is a conflict with the AOLserver filter with the same name!\n"
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

ad_library {

    security filters for the admin pages.

    @creation-date 18 Nov 1998
    @author Allen Pulsifer (pulsifer@mediaone.net)
    @cvs-id $Id$

}

if { [ad_ssl_available_p] } {
    set admin_ssl_filters_installed_p 1

    db_foreach path_select {
	select package_id, site_node.url(node_id) as url from apm_packages p, site_nodes n
	where p.package_id = n.object_id
    } {
	ns_log Notice "Processing RestrictToSSL for $url"
	foreach pattern [ad_parameter -package_id $package_id RestrictToSSL "acs-subsite"] {
	    ad_register_filter preauth GET "$url$pattern" ad_restrict_to_https
	    ns_log Notice "URLs matching \"$url$pattern\" are restricted to SSL"
	}
    }
    
    db_release_unused_handles
}

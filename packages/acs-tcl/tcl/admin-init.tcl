ad_library {

    security filters for the admin pages.

    @creation-date 18 Nov 1998
    @author Allen Pulsifer (pulsifer@mediaone.net)
    @cvs-id $Id$

}

# This can be very time consuming on a large site and may be 
# disabled by setting RegisterRestrictToSSLFilters in the kernel params.
if { [security::https_available_p] 
     && [parameter::get -package_id [ad_acs_kernel_id] -parameter RegisterRestrictToSSLFilters -default 1]} {
    set admin_ssl_filters_installed_p 1

    db_foreach path_select {} { 
	ns_log Notice "Processing RestrictToSSL for $url"
	foreach pattern [parameter::get -package_id $package_id -parameter RestrictToSSL] {
	    ad_register_filter preauth GET "$url$pattern" ad_restrict_to_https
	    ns_log Notice "URLs matching \"$url$pattern\" are restricted to SSL"
	}
    }
    
    db_release_unused_handles
}

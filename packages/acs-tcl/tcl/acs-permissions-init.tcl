if {[info commands ns_cache_eval] ne ""} {
    #
    # Permission cache management for NaviServer.
    #
    # Some of this code will go away, when abstract cache management
    # will be introduced.
    #
    if {![info exists ::permission::cache_created]} {
	ns_log notice "acs-tcl: creating permission cache"
	ns_cache_create \
	    -expires [parameter::get -package_id [ad_acs_kernel_id] \
			  -parameter PermissionCacheTimeout \
			  -default 300] \
	    permission_cache 100000
	set permission::cache_created 1
    }
}

#
# Create a cache for keeping user_info
#
# The user_info_cache can be configured via the config file like the
# following:
#
#    ns_section ns/server/${server}/acs/acs-tcl
#         ns_param PartyInfoCacheSize          2000000
#         ns_param PartyInfoCacheTimeout          3600
#
# The timeout is responsible, how precise/recent e.g. last_visit should be.
#
ns_cache create party_info_cache \
    -size [parameter::get \
	       -package_id [apm_package_id_from_key acs-tcl] \
	       -parameter PartyInfoCacheSize \
	       -default 2000000] \
    -timeout [parameter::get \
		  -package_id [apm_package_id_from_key acs-tcl] \
		  -parameter PartyInfoCacheTimeout \
		  -default 3600]



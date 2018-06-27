#
# Create a cache for keeping party_info
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

#
# Create a cache for keeping person_info
#
# The user_info_cache can be configured via the config file like the
# following:
#
#    ns_section ns/server/${server}/acs/acs-tcl
#         ns_param PersonInfoCacheSize          2000000
#         ns_param PersonInfoCacheTimeout          3600
#
# The timeout is responsible, how precise/recent e.g. last_visit should be.
#
ns_cache create person_info_cache \
    -size [parameter::get \
	       -package_id [apm_package_id_from_key acs-tcl] \
	       -parameter PersonInfoCacheSize \
	       -default 2000000] \
    -timeout [parameter::get \
		  -package_id [apm_package_id_from_key acs-tcl] \
		  -parameter PersonInfoCacheTimeout \
		  -default 3600]


#
# Create a cache for keeping user_info
#
# The user_info_cache can be configured via the config file like the
# following:
#
#    ns_section ns/server/${server}/acs/acs-tcl
#         ns_param UserInfoCacheSize          2000000
#         ns_param UserInfoCacheTimeout          3600
#
# The timeout is responsible, how precise/recent e.g. last_visit should be.
#
ns_cache create user_info_cache \
    -size [parameter::get \
	       -package_id [apm_package_id_from_key acs-tcl] \
	       -parameter UserInfoCacheSize \
	       -default 2000000] \
    -timeout [parameter::get \
		  -package_id [apm_package_id_from_key acs-tcl] \
		  -parameter UserInfoCacheTimeout \
		  -default 3600]



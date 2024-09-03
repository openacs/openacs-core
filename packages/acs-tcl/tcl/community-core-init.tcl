#
# Create a cache for keeping party_info
#
# The user_info_cache can be configured via the config file like the
# following:
#
#    ns_section ns/server/${server}/acs/acs-tcl
#         ns_param PartyInfoCacheSize             2MB
#         ns_param PartyInfoCacheTimeout          1h
#
# The timeout is responsible, how precise/recent e.g. last_visit should be.
#
ns_cache create party_info_cache \
    -size [parameter::get_from_package_key \
               -package_key acs-tcl \
               -parameter PartyInfoCacheSize \
               -default 2MB] \
    -timeout [parameter::get_from_package_key \
                  -package_key acs-tcl \
                  -parameter PartyInfoCacheTimeout \
                  -default 1h]

#
# Create a cache for keeping person_info
#
# The user_info_cache can be configured via the config file like the
# following:
#
#    ns_section ns/server/${server}/acs/acs-tcl
#         ns_param PersonInfoCacheSize          2MB
#         ns_param PersonInfoCacheTimeout       1h
#
# The timeout is responsible, how precise/recent e.g. last_visit should be.
#
ns_cache create person_info_cache \
    -size [parameter::get_from_package_key \
               -package_key acs-tcl \
               -parameter PersonInfoCacheSize \
               -default 2MB] \
    -timeout [parameter::get_from_package_key \
                  -package_key acs-tcl \
                  -parameter PersonInfoCacheTimeout \
                  -default 1h]


#
# Create a cache for keeping user_info
#
# The user_info_cache can be configured via the config file like the
# following:
#
#    ns_section ns/server/${server}/acs/acs-tcl
#         ns_param UserInfoCacheSize          2MB
#         ns_param UserInfoCacheTimeout       1h
#
# The timeout is responsible, how precise/recent e.g. last_visit should be.
#
ns_cache create user_info_cache \
    -size [parameter::get_from_package_key \
               -package_key acs-tcl \
               -parameter UserInfoCacheSize \
               -default 2MB] \
    -timeout [parameter::get_from_package_key \
                  -package_key acs-tcl \
                  -parameter UserInfoCacheTimeout \
                  -default 1h]



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

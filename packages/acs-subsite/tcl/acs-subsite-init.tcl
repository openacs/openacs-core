ad_library {
    
    Initializes mappings of package directories to URLs.

    @cvs-id $Id$
    @author Richard Li
    @creation-date 12 August 2000

}

# /www

# rp_register_directory_map pvt acs-core-ui pvt
# rp_register_directory_map user acs-core-ui user
# rp_register_directory_map register acs-core-ui register
# rp_register_directory_map shared acs-core-ui shared
# rp_register_directory_map permissions acs-core-ui permissions

# /admin/www

# rp_register_directory_map categories acs-core-ui categories
# rp_register_directory_map content-tagging acs-core-ui content-tagging
# rp_register_directory_map orgs acs-core-ui orgs
# rp_register_directory_map users acs-core-ui users
# rp_register_directory_map subsites acs-core-ui subsites
# rp_register_directory_map object-types acs-core-ui object-types

# security filters

# ad_register_filter -sitewide preauth * "/doc/*" ad_restrict_to_administrator

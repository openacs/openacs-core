ad_page_contract {
    @author Bryan Quinn (bquinn@arsdigita.com)

    @creation-date August 15, 2000
    @cvs-id $Id$
}

set page_title [ad_conn instance_name]

db_multirow subsites subsite_admin_urls {}

db_multirow -extend { admin_url } packages installed_packages {} {
    if { [apm_package_installed_p $package_key] && [file exists "[acs_package_root_dir $package_key]/www/sitewide-admin/"] } {
        set admin_url "package/$package_key/"
    } else {
        continue
    }
} 

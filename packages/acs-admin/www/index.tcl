ad_page_contract {
    @author Bryan Quinn (bquinn@arsdigita.com)

    @creation-date August 15, 2000
    @cvs-id $Id$
}

set page_title "[ad_conn instance_name] for [ad_system_name]"

db_multirow subsites subsite_admin_urls {
    select site_node.url(node_id) || 'admin/' as admin_url, 
           instance_name
    from site_nodes s, apm_packages p
    where s.object_id = p.package_id
    and p.package_key = 'acs-subsite'
}

db_multirow -extend { admin_url } packages installed_packages {
    select package_key,
           pretty_name as pretty_name
    from apm_package_types
} {
    if { [apm_package_installed_p $package_key] && [file exists "[acs_package_root_dir $package_key]/www/sitewide-admin/"] } {
        set admin_url "package/$package_key/"
    } else {
        continue
    }
} 

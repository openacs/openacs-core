ad_page_contract {
    @author Bryan Quinn (bquinn@arsdigita.com)

    @creation-date August 15, 2000
    @cvs-id $Id$
}

set page_title [ad_conn instance_name]

db_multirow -extend { admin_url path_pretty } subsites subsite_admin_urls {} {
    set admin_url "${node_url}admin/"
    set path_pretty $instance_name
    array set node [site_node::get -node_id $node_id]
    set parent_id $node(parent_id)

    while { ![empty_string_p $parent_id] } {
        array unset node
        array set node [site_node::get -node_id $parent_id]
        set path_pretty "$node(instance_name) > $path_pretty"
        set parent_id $node(parent_id)
    }
}

multirow sort subsites path_pretty

db_multirow -extend { admin_url } packages installed_packages {} {
    if { [apm_package_installed_p $package_key] && [file exists "[acs_package_root_dir $package_key]/www/sitewide-admin/"] } {
        set admin_url "package/$package_key/"
    } else {
        continue
    }
} 

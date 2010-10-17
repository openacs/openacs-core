ad_page_contract {
    @author Bryan Quinn (bquinn@arsdigita.com)

    @creation-date August 15, 2000
    @cvs-id $Id$
}

set page_title [ad_conn instance_name]
set package_keys '[join [subsite::package_keys] ',']'
set subsite_number [db_string count_subsites {}]
if {$subsite_number > 100} {
    set too_many_subsites_p 1
} else {
    set too_many_subsites_p 0

    db_multirow -extend { admin_url path_pretty } subsites subsite_admin_urls {} {
	set admin_url "${node_url}admin/"
	set path_pretty $instance_name
	array set node [site_node::get -node_id $node_id]
	set parent_id $node(parent_id)
	
	while { $parent_id ne "" } {
	    array unset node
	    array set node [site_node::get -node_id $parent_id]
	    set path_pretty "$node(instance_name) > $path_pretty"
	    set parent_id $node(parent_id)
	}
    }
    multirow sort subsites path_pretty
}

db_multirow -extend { admin_url global_param_url } packages installed_packages {} {
    if { [apm_package_installed_p $package_key] && [file exists "[acs_package_root_dir $package_key]/www/sitewide-admin/"] } {
        set admin_url "package/$package_key/"
    } else {
        set admin_url ""
    }
    if { [catch {db_1row global_params_exist {}} errmsg] ||
         $global_params == 0 } {
         set global_param_url ""
    } else {
        set global_param_url [export_vars -base /shared/parameters {package_key {scope global}}]
    }
    if { $admin_url eq "" && $global_param_url eq "" } {
        continue
    }
} 

template::list::create \
    -name packages \
    -multirow packages \
    -elements {
        pretty_name {
            label "Package"
        }
        admin_url {
            label "Site-Wide Administration"
            link_html { title "Site-wide Administration" }
            link_url_col admin_url
            display_template {<if @packages.admin_url@ not nil>#acs-admin.Administration#</if>}
        }
        global_param_url {
            label "Global Parameters"
            link_html {title "Manage Global Parameters" }
            link_url_col global_param_url
            display_template {<if @packages.global_param_url@ not nil>#acs-admin.Parameters#</if>}
        }
    }

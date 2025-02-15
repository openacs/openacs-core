ad_include_contract {
    Show applications mounted under current subsite
}

set admin_p [permission::permission_p \
                 -object_id [ad_conn subsite_id] \
                 -privilege admin \
                 -party_id [ad_conn untrusted_user_id]]

set actions [list]
if { $admin_p } {
    set return_url [ad_return_url]
    set subsite_url [subsite::get_element -element url]
    lappend actions \
        [_ acs-subsite.Add_new_app] \
        [export_vars -base "${subsite_url}admin/applications/application-add" {
            return_url
        }]
}

list::create \
    -name applications \
    -multirow applications \
    -no_data "[_ acs-subsite.No_applications]" \
    -actions $actions \
    -elements {
        instance_name {
            label "[_ acs-subsite.Name]"
            link_url_eval {$name/}
        }
    }

set subsite_node_id [subsite::get_element -element node_id]
set user_id [ad_conn user_id]

db_multirow applications select_applications {
    select p.package_id,
           p.instance_name,
           n.node_id,
           n.name
    from   site_nodes n,
           apm_packages p,
           apm_package_types t
    where  n.parent_id = :subsite_node_id
    and    p.package_id = n.object_id
    and    t.package_key = p.package_key
    and    t.package_type = 'apm_application'
    and    acs_permission.permission_p(p.package_id, :user_id, 'read') = 't'
    order  by upper(instance_name)
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

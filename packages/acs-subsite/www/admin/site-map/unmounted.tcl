ad_page_contract {

    Display all readable unmounted packages

    @author bquinn@arsdigita.com
    @creation-date 2000-09-12
    @cvs-id $Id$

}

set page_title "Unmounted Packages"
set context [list [list "." "Site Map"] $page_title]
set user_id [ad_conn user_id]

set the_public [acs_magic_object the_public]

db_multirow -extend {instance_delete_url delete_id} packages_normal packages_normal_select {
   select package_id, instance_name as name, package_key
   from apm_packages p
   where (acs_permission.permission_p(package_id, :user_id, 'read') or
           acs_permission.permission_p(package_id, :the_public, 'read'))
   and not (select singleton_p from apm_package_types
             where package_key = p.package_key)
   and not exists (select 1
                   from site_nodes
                   where object_id = package_id)
   order by name
} {
    set instance_delete_url [export_vars -base instance-delete package_id]
    set delete_id action-delete-$package_id
    template::add_confirm_handler -id $delete_id -message "Are you sure you want to delete package $name"
}

db_multirow -extend {instance_delete_url delete_id} packages_singleton packages_singleton_select {
   select package_id, instance_name as name, package_key
   from apm_packages p
   where (acs_permission.permission_p(package_id, :user_id, 'read') or
           acs_permission.permission_p(package_id, :the_public, 'read'))
   and (select singleton_p from apm_package_types
         where package_key = p.package_key)
   and not exists (select 1
                   from site_nodes
                   where object_id = package_id)
   order by name
} {
    set instance_delete_url [export_vars -base instance-delete package_id]
    set delete_id action-delete-$package_id
    template::add_confirm_handler -id $delete_id -message "Are you sure you want to delete package $name"
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

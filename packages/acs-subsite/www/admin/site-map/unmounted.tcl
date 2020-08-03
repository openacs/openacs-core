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


db_multirow -extend {instance_delete_url delete_id} all_packages_unmounted all_packages_unmounted_select {
    select
        p.package_id, p.instance_name as name, p.package_key, apt.singleton_p
    from
    (
        select orig_object_id as package_id
        from
        acs_permission.permission_p_recursive_array(array(
            select package_id
            from apm_packages ap

            EXCEPT

            select object_id
            from site_nodes), :user_id, 'read') as u
        UNION
        select orig_object_id as package_id
        from
        acs_permission.permission_p_recursive_array(array(
            select package_id
            from apm_packages ap

            EXCEPT

            select object_id
            from site_nodes), :the_public, 'read') as p
    ) as p_ids, apm_packages p, apm_package_types apt
        where p.package_key = apt.package_key
            and p_ids.package_id = p.package_id
} {
    set instance_delete_url [export_vars -base instance-delete package_id]
    set delete_id action-delete-$package_id
    template::add_confirm_handler -id $delete_id -message "Are you sure you want to delete package $name"
}

template::multirow create packages_normal package_id name package_key instance_delete_url delete_id
template::multirow create packages_singleton package_id name package_key instance_delete_url delete_id


template::multirow foreach all_packages_unmounted {
    if {$singleton_p} {
        template::multirow append packages_singleton $package_id $name $package_key $instance_delete_url $delete_id
    } else {
        template::multirow append packages_normal $package_id $name $package_key $instance_delete_url $delete_id
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="packages_unmounted_select">
        <querytext>
            select p.package_id, 
                   acs_object.name(p.package_id) as name,
                   pt.pretty_name as package_pretty_name
            from   apm_packages p,
                   apm_package_types pt,
                   apm_package_versions v
            where  pt.package_key = p.package_key
            and    v.package_key = pt.package_key
            and    (v.installed_p = 't' or v.enabled_p = 't' or not exists (
                    select 1 from apm_package_versions v2
                    where v2.package_key = v.package_key
                      and (v2.installed_p = 't' or v2.enabled_p = 't')
                     and apm_package_version.sortable_version_name(v2.version_name) >
                         apm_package_version.sortable_version_name(v.version_name)))
            and    (
                       acs_permission.permission_p(package_id, :user_id, 'read') = 't'
                    or acs_permission.permission_p(package_id, acs.magic_object_id('the_public'), 'read') = 't'
                   )
            and    (apm_package.singleton_p(p.package_key) = 0 or v.auto_mount is not null)
            and    not exists (select 1
                               from site_nodes
                               where object_id = p.package_id)
            order by name
        </querytext>
    </fullquery>

    <fullquery name="packages_mounted_select">
        <querytext>
            select p.package_id, 
                   acs_object.name(p.package_id) as name,
                   pt.pretty_name as package_pretty_name
            from   apm_packages p,
                   apm_package_types pt
            where  pt.package_key = p.package_key
            and    (
                       acs_permission.permission_p(package_id, :user_id, 'read') = 't'
                    or acs_permission.permission_p(package_id, acs.magic_object_id('the_public'), 'read') = 't'
                   )
            and    exists (select 1
                           from site_nodes
                           where object_id = p.package_id)
            order by name
        </querytext>
    </fullquery>


    <fullquery name="packages_singleton_select">
        <querytext>
            select p.package_id, 
                   acs_object.name(p.package_id) as name,
                   pt.pretty_name as package_pretty_name
            from   apm_packages p,
                   apm_package_types pt,
                   apm_package_versions v
            where  pt.package_key = p.package_key
            and    v.package_key = pt.package_key
            and    (v.installed_p = 't' or v.enabled_p = 't' or not exists (
                    select 1 from apm_package_versions v2
                    where v2.package_key = v.package_key
                      and (v2.installed_p = 't' or v2.enabled_p = 't')
                     and apm_package_version.sortable_version_name(v2.version_name) >
                         apm_package_version.sortable_version_name(v.version_name)))
            and    (
                       acs_permission.permission_p(package_id, :user_id, 'read') = 't'
                    or acs_permission.permission_p(package_id, acs.magic_object_id('the_public'), 'read') = 't'
                   )
            and    (apm_package.singleton_p(p.package_key) = 1 and v.auto_mount is null)
            and    not exists (select 1
                               from site_nodes
                               where object_id = p.package_id)
            order by name
        </querytext>
    </fullquery>

</queryset>

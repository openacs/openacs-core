<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="packages_normal_select">
        <querytext>
            select package_id, acs_object.name(package_id) as name
            from apm_packages
            where (acs_permission.permission_p(package_id, :user_id, 'read') = 't' or
                    acs_permission.permission_p(package_id, acs.magic_object_id('the_public'), 'read') = 't')
            and apm_package.singleton_p(package_key) = 0
            and not exists (select 1
                            from site_nodes
                            where object_id = package_id)
            order by name
        </querytext>
    </fullquery>

    <fullquery name="packages_singleton_select">
        <querytext>
            select package_id, acs_object.name(package_id) as name
            from apm_packages
            where (acs_permission.permission_p(package_id, :user_id, 'read') = 't' or
                    acs_permission.permission_p(package_id, acs.magic_object_id('the_public'), 'read') = 't')
            and apm_package.singleton_p(package_key) = 1
            and not exists (select 1
                            from site_nodes
                            where object_id = package_id)
            order by name
        </querytext>
    </fullquery>

</queryset>

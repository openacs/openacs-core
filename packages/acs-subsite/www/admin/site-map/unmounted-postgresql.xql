<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="packages_normal_select">
        <querytext>
            select package_id, instance_name as name, package_key
            from apm_packages p
            where (acs_permission__permission_p(package_id, :user_id, 'read') or
                    acs_permission__permission_p(package_id, acs__magic_object_id('the_public'), 'read'))
            and not (select singleton_p from apm_package_types
                      where package_key = p.package_key)
            and not exists (select 1
                            from site_nodes
                            where object_id = package_id)
            order by name
        </querytext>
    </fullquery>

    <fullquery name="packages_singleton_select">
        <querytext>
            select package_id, instance_name as name, package_key
            from apm_packages p
            where (acs_permission__permission_p(package_id, :user_id, 'read') or
                    acs_permission__permission_p(package_id, acs__magic_object_id('the_public'), 'read'))
            and (select singleton_p from apm_package_types
                  where package_key = p.package_key)
            and not exists (select 1
                            from site_nodes
                            where object_id = package_id)
            order by name
        </querytext>
    </fullquery>

</queryset>

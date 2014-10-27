<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="packages_normal_select">
        <querytext>
            select package_id, acs_object__name(package_id) as name, package_key
            from apm_packages
            where (acs_permission__permission_p(package_id, :user_id, 'read') = 't' or
                    acs_permission__permission_p(package_id, acs__magic_object_id('the_public'), 'read') = 't')
            and apm_package__singleton_p(package_key) = 0
            and not exists (select 1
                            from site_nodes
                            where object_id = package_id)
            order by name
        </querytext>
    </fullquery>

    <fullquery name="packages_singleton_select">
        <querytext>
            select package_id, acs_object__name(package_id) as name, package_key
            from apm_packages
            where (acs_permission__permission_p(package_id, :user_id, 'read') = 't' or
                    acs_permission__permission_p(package_id, acs__magic_object_id('the_public'), 'read') = 't')
            and apm_package__singleton_p(package_key) = 1
            and not exists (select 1
                            from site_nodes
                            where object_id = package_id)
            order by name
        </querytext>
    </fullquery>

</queryset>

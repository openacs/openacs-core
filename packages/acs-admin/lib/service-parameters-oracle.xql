<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="services_select">
        <querytext>
                    select package_id,
                           ap.package_key,
                           acs_object.name(package_id) as instance_name,
                           apm_package_type.num_parameters(ap.package_key) as parameter_count
                    from apm_packages ap,
                         apm_package_types
                    where ap.package_key = apm_package_types.package_key
                    and package_type = 'apm_service'
                    and (
                            acs_permission.permission_p(package_id, :user_id, 'read') = 't'
                         or acs_permission.permission_p(package_id, acs.magic_object_id('the_public'), 'read') = 't'
                        )
                    and   ap.package_key != 'acs-subsite'
                    order by instance_name
        </querytext>
    </fullquery>

</queryset>

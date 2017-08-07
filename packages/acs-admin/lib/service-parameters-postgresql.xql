<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="services_select">
        <querytext>
                    select package_id,
                           ap.package_key,
                           -- acs_object__name(package_id) as instance_name,
			   pretty_name as instance_name,
                           apm_package_type__num_parameters(ap.package_key) as parameter_count
                    from apm_packages ap,
                         apm_package_types
                    where ap.package_key = apm_package_types.package_key
                    and package_type = 'apm_service'
                    and   (ap.package_key != 'acs-subsite')
                    order by instance_name
        </querytext>
    </fullquery>

</queryset>

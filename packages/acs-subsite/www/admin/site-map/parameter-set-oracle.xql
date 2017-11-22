<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="package_info">
        <querytext>
            select package_key,
                   acs_object.name(package_id) instance_name
            from apm_packages
            where package_id = :package_id
        </querytext>
    </fullquery>

</queryset>

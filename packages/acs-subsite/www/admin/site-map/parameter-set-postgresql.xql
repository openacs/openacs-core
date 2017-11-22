<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="package_info">
        <querytext>
            select package_key,
                   acs_object__name(package_id) as instance_name
            from apm_packages
            where package_id = :package_id
        </querytext>
    </fullquery>

</queryset>

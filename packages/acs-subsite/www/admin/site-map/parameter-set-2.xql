<?xml version="1.0"?>

<queryset>

    <fullquery name="apm_parameters_set">
        <querytext>
            select parameter_id,
                   parameter_name
            from apm_parameters
            where package_key = :package_key
        </querytext>
    </fullquery>

</queryset>

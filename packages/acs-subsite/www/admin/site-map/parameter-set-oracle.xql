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

    <fullquery name="parameter_table">
        <querytext>
            select p.parameter_id,
                   p.parameter_name,
                   p.package_key,
                   nvl(p.description, 'No Description') description,
                   v.attr_value,
                   nvl(p.section_name, 'No Section Name') section_name
            from apm_parameters p,
                 (select v.parameter_id,
                         v.attr_value
                  from apm_parameter_values v
                  where v.package_id = :package_id) v
            where p.parameter_id = v.parameter_id(+)
            and p.package_key = (select package_key from apm_packages where package_id = :package_id)
            $additional_sql
        </querytext>
    </fullquery>

</queryset>

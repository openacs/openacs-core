<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_params">      
      <querytext>

    select p.parameter_name,
           coalesce(p.description, 'No Description') as description,
           v.attr_value,
           coalesce(p.section_name, '') as section_name
    from   apm_parameters p left outer join
           (select v.parameter_id,
                   v.attr_value
            from apm_parameter_values v
            where v.package_id = :package_id
           ) v on p.parameter_id = v.parameter_id
    where  p.package_key = (select package_key from apm_packages where package_id = :package_id)
	$section_where_clause
    order  by section_name, parameter_name

      </querytext>
</fullquery>


<fullquery name="select_params_set">      
      <querytext>

        select p.parameter_name as c__parameter_name
        from   apm_parameters p left outer join
               (select v.parameter_id,
                       v.attr_value
                from apm_parameter_values v
                where v.package_id = :package_id
               ) v on p.parameter_id = v.parameter_id
        where  p.package_key = (select package_key from apm_packages where package_id = :package_id)
	$section_where_clause
      </querytext>
</fullquery>
 
</queryset>

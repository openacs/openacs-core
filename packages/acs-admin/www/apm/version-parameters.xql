<?xml version="1.0"?>
<queryset>

<fullquery name="parameter_table">
  <querytext>

    select ap.parameter_name, coalesce(ap.description, 'No Description') as description,
      ap.datatype, ap.default_value, ap.parameter_id, ap.scope,
      coalesce(ap.section_name, 'No Section') as section_name
    from apm_parameters ap
    where package_key = :package_key
      and not exists (select 1
                      from apm_parameters ap2
                      where ap.parameter_name = ap2.parameter_name
                        and ap2.package_key in ('[join $parent_package_keys ',']'))
    $sql_clauses

  </querytext>
</fullquery> 
 
</queryset>

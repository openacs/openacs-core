<?xml version="1.0"?>
<queryset>

<fullquery name="acs.acs-tcl.tcl.apm-procs.apm_parameter_register.parameter_register">
<querytext>
select apm__register_parameter (
       NULL,
       :package_key,
       :parameter_name,
       :description,
       :datatype,
       :default_value,
       :section_name,
       :min_n_values,
       :max_n_values);
</querytext>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>
</fullquery>

<fullquery name="acs.acs-tcl.tcl.apm-procs.apm_parameter_register.apm_parameter_cache_update">
<querytext>
select v.package_id, p.parameter_name, coalesce(p.default_value, v.attr_value) attr_value
from apm_parameters p, apm_parameter_values v
where p.package_key = :package_key
and p.parameter_id = v.parameter_id (+)
</querytext>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>
</fullquery>

</queryset>

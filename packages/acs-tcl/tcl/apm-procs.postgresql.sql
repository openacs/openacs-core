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
select v.package_id, p.parameter_name, coalesce(p.default_value, v.attr_value) as attr_value
from apm_parameters p LEFT JOIN apm_parameter_values v using (parameter_id)
where p.package_key = :package_key
</querytext>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>
</fullquery>

<fullquery name="acs.acs-tcl.tcl.apm-procs.apm_interface_add.interface_add">
<querytext>
select apm_package_version__add_interface(
    :interface_id,
    :version_id,
    :interface_uri,
    :interface_version
)					 
</querytext>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>
</fullquery>

<fullquery name="acs.acs-tcl.tcl.apm-procs.apm_interface_remove.interface_remove">
<querytext>
select apm_package_version__remove_interface(
             :interface_id
);
</querytext>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>
</fullquery>

</queryset>

<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name=".defs-procs.ad_parameter.ad_parameter_set">
<querytext>
select apm__set_value(
	:package_id,
	:name,
	:set)
</querytext>
</fullquery>

</queryset>

<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="attribute::add.drop_attribute">
<querytext>
select acs_attribute__drop_attribute(:object_type, :attribute_name)
</querytext>
</fullquery>

<fullquery name="attribute::add.create_attribute">
<querytext>
select acs_attribute__create_attribute (	
	'$object_type',
	'$attribute_name',
	'$datatype',
	'$pretty_name',
	'$pretty_plural',
	NULL,
	NULL,
	'$default_value',
	'$min_n_values',
	'$max_n_values',
	NULL,
	'type_specific',
	'f'
);
</querytext>
</fullquery>

<fullquery name="attribute::delete.drop_attribute">
  <querytext>
    select acs_attribute__drop_attribute(:object_type, :attribute_name, :drop_table_column_p)
  </querytext>
</fullquery>

</queryset>

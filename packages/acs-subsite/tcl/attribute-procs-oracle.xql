<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="attribute::add.drop_attribute">
<querytext>
begin acs_attribute.drop_attribute(:object_type, :attribute_name); end;
</querytext>
</fullquery>

<fullquery name="attribute::add.create_attribute">
<querytext>
declare
  attr_id     acs_attributes.attribute_id%TYPE;
begin
  attr_id := acs_attribute.create_attribute (	
	object_type => '$object_type',
	attribute_name => '$attribute_name',
	min_n_values => '$min_n_values',
	max_n_values => '$max_n_values',
	default_value => '$default_value',
	datatype => '$datatype',
	pretty_name => '$pretty_name',
	pretty_plural => '$pretty_plural'
  );
end;
</querytext>
</fullquery>


<fullquery name="attribute::delete.drop_attribute">
<querytext>
begin acs_attribute.drop_attribute(:object_type, :attribute_name, :drop_table_column_p); end;
</querytext>
</fullquery>

</queryset>

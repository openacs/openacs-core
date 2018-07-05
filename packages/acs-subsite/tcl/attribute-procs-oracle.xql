<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>
 
<fullquery name="attribute::array_for_type.select_attributes">
      <querytext>
      
	select nvl(a.column_name, a.attribute_name) as name, 
               a.pretty_name, a.attribute_id, a.datatype, 
               v.enum_value, v.pretty_name as value_pretty_name
	from acs_object_type_attributes a,
               acs_enum_values v,
               (select t.object_type, level as type_level
                  from acs_object_types t
                 start with t.object_type = :start_with
               connect by prior t.object_type = t.supertype) t 
         where a.object_type = :object_type
           and a.attribute_id = v.attribute_id(+)
           and t.object_type = a.ancestor_type $storage_clause
        order by type_level, a.sort_order
    
      </querytext>
</fullquery>

 
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

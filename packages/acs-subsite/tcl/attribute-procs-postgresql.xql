<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="attribute::array_for_type.select_attributes">      
      <querytext>

	select coalesce(a.column_name, a.attribute_name) as name, 
               a.pretty_name, a.attribute_id, a.datatype, 
               v.enum_value, v.pretty_name as value_pretty_name
	from acs_object_type_attributes a left outer join
               acs_enum_values v using (attribute_id),
               (select t.object_type, tree_level(t.tree_sortkey) - tree_level(t2.tree_sortkey) as type_level
                from acs_object_types t, acs_object_types t2
		where t2.object_type = :start_with
                  and t.tree_sortkey between t2.tree_sortkey and tree_right(t2.tree_sortkey)) t
         where a.object_type = :object_type
           and t.object_type = a.ancestor_type $storage_clause
        order by type_level, a.sort_order
    
      </querytext>
</fullquery>

 
<fullquery name="attribute::multirow.attribute_select">      
      <querytext>	

	select *
	  from ($package_object_view) dummy
	 where object_id = :object_id

      </querytext>
</fullquery>

 
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

<fullquery name="attribute::add.drop_attr_column">
<querytext>
alter table $table_name drop column $attribute_name
</querytext>
</fullquery>

<fullquery name="attribute::add.add_column">
<querytext>
alter table $table_name add $attribute_name $sql_type
</querytext>
</fullquery>

<fullquery name="attribute::delete.drop_attribute">
<querytext>
select acs_attribute__drop_attribute(:object_type, :attribute_name)
</querytext>
</fullquery>


<!-- Cannot remove a column in PG -->
<fullquery name="attribute::delete.drop_attr_column">
<querytext>
alter table $table_name rename column $column_name to __DELETED__$column_name
</querytext>
</fullquery>

</queryset>

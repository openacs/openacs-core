<?xml version="1.0"?>
<queryset>

<fullquery name="group_type::new.select_group_id_column">      
      <querytext>
      
	    select upper(id_column) from acs_object_types where object_type='group'
	
      </querytext>
</fullquery>

 
<fullquery name="group_type::new.supertype_table_column">      
      <querytext>
      
	    select t.table_name as references_table,
                   t.id_column as references_column
  	      from acs_object_types t
	     where t.object_type = :supertype
	
      </querytext>
</fullquery>


<fullquery name="group_type::new.insert_group_type">
	<querytext>
		insert into group_types (group_type) values (:group_type)
	</querytext>
</fullquery>
 
</queryset>

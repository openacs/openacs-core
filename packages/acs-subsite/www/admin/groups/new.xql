<?xml version="1.0"?>
<queryset>

<fullquery name="group_exists_p">      
      <querytext>
      
	    select count(*) from groups where group_id = :group_id
	
      </querytext>
</fullquery>

 
<fullquery name="group_info">      
      <querytext>
      
    select group_name as add_to_group_name, 
           join_policy as add_to_group_join_policy
    from groups
    where group_id = :add_to_group_id

      </querytext>
</fullquery>

 
<fullquery name="select_type_info">      
      <querytext>
      
    select t.pretty_name as group_type_pretty_name,
           t.table_name
      from acs_object_types t
     where t.object_type = :group_type

      </querytext>
</fullquery>

 
</queryset>

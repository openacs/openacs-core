<?xml version="1.0"?>
<queryset>

<fullquery name="select_pretty_name">      
      <querytext>
      FIX ME OUTER JOIN

    select t.dynamic_p,
           case when gt.group_type = null then 0 else 1 end as group_type_exists_p
      from acs_object_types t, group_types gt
     where t.object_type = :group_type
       and t.object_type = gt.group_type(+)

      </querytext>
</fullquery>

 
<fullquery name="set_default_join_policy">      
      <querytext>
      
	insert into group_types
	(group_type, default_join_policy)
	values
	(:group_type, :default_join_policy)
    
      </querytext>
</fullquery>

 
<fullquery name="update_join_policy">      
      <querytext>
      
	update group_types
	set default_join_policy = :default_join_policy
	where group_type = :group_type
    
      </querytext>
</fullquery>

 
</queryset>

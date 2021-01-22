<?xml version="1.0"?>
<queryset>

<fullquery name="group::new.package_select">      
      <querytext>
      
	    select t.package_name, lower(t.id_column) as id_column
	      from acs_object_types t
	     where t.object_type = :group_type
	
      </querytext>
</fullquery>

<fullquery name="group::get_id_not_cached.get_group_id">
      <querytext>
      
	select group_id
	from groups
	where group_name = :group_name
	
      </querytext>
</fullquery>

<fullquery name="group::get_id_not_cached.get_group_id_with_application">
      <querytext>
      
	SELECT g.group_id                                                                                    
           FROM acs_rels rels        		                                                                           
           INNER JOIN composition_rels comp ON                                                                  
           rels.rel_id = comp.rel_id                                                                            
           INNER JOIN groups g ON rels.object_id_two = g.group_id                                               
           WHERE rels.object_id_one = :application_group_id AND                                                 
           g.group_name = :group_name	
      </querytext>
</fullquery>

<fullquery name="group::get_members_not_cached.group_members_party">
      <querytext>
      
		select distinct member_id
		from group_member_map
		where group_id = :group_id
	
      </querytext>
</fullquery>

<fullquery name="group::get_members_not_cached.group_members">
      <querytext>
      
		select distinct m.member_id
		from group_member_map m, acs_objects o
		where m.group_id = :group_id
		and m.member_id = o.object_id
		and o.object_type = :type
	
      </querytext>
</fullquery>


<fullquery name="group::join_policy.select_join_policy">      
      <querytext>
      
	    select join_policy from groups where group_id = :group_id
	
      </querytext>
</fullquery>

<fullquery name="group::get_rel_segment.select_segment_id">      
      <querytext>
      
         select segment_id
           from rel_segments
          where group_id = :group_id
            and rel_type = :type
    
      </querytext>
</fullquery>

</queryset>

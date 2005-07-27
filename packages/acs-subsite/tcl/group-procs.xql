<?xml version="1.0"?>
<queryset>

<fullquery name="group::new.package_select">      
      <querytext>
      
	    select t.package_name, lower(t.id_column) as id_column
	      from acs_object_types t
	     where t.object_type = :group_type
	
      </querytext>
</fullquery>

<fullquery name="group::new.package_select">      
      <querytext>
      
	    select t.package_name, lower(t.id_column) as id_column
	      from acs_object_types t
	     where t.object_type = :group_type
	
      </querytext>
</fullquery>

<fullquery name="group::get_members_not_cached.group_members_party">
      <querytext>
      
		select member_id
		from group_member_map
		where group_id = :group_id
	
      </querytext>
</fullquery>

<fullquery name="group::get_members_not_cached.group_members_person">
      <querytext>
      
		select m.member_id
		from group_member_map m, persons p
		where m.group_id = :group_id
		and m.member_id = p.person_id
	
      </querytext>
</fullquery>

<fullquery name="group::get_members_not_cached.group_members_user">
      <querytext>
      
		select m.member_id
		from group_member_map m, users u
		where m.group_id = :group_id
		and m.member_id = u.user_id
	
      </querytext>
</fullquery>

<fullquery name="group::join_policy.select_join_policy">      
      <querytext>
      
	    select join_policy from groups where group_id = :group_id
	
      </querytext>
</fullquery>

<fullquery name="group::member_p.group_id_from_name">      
      <querytext>
	  select group_id 
          from   groups 
          where  group_name = :group_name
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

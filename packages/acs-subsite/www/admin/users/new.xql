<?xml version="1.0"?>
<queryset>

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
      
    select t.pretty_name as user_type_pretty_name,
           t.table_name
      from acs_object_types t
     where t.object_type = :user_type

      </querytext>
</fullquery>

 
<fullquery name="creation_name_query">      
      <querytext>
      
	    select p.first_names || ' ' || p.last_name 
	              || ' (' || pa.email || ')'
            from persons p, parties pa
            where p.person_id = pa.party_id and p.person_id = :creation_user
	    
      </querytext>
</fullquery>

 
</queryset>

<?xml version="1.0"?>
<queryset>

<fullquery name="select_type_info">      
      <querytext>
      
	select t.table_name 
	  from acs_object_types t
	 where t.object_type = :rel_type
    
      </querytext>
</fullquery>

 
<fullquery name="select_rel_ids">      
      <querytext>
      
	select r.rel_id
	  from acs_rels r, acs_object_party_privilege_map perm
	 where perm.object_id = r.rel_id
	  and perm.party_id = :user_id
	  and perm.privilege = 'delete'
	  and r.rel_type = :rel_type
    
      </querytext>
</fullquery>

 
<fullquery name="select_segment_id">      
      <querytext>
      
	select s.segment_id
	  from rel_segments s, acs_object_party_privilege_map perm
	 where perm.object_id = s.segment_id
 	   and perm.party_id = :user_id
	   and perm.privilege = 'delete'
	   and s.rel_type = :rel_type
    
      </querytext>
</fullquery>

 
</queryset>

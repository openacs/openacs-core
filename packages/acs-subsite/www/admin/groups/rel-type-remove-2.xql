<?xml version="1.0"?>
<queryset>

<fullquery name="select_group_id">      
      <querytext>
      
    select g.group_id, g.rel_type
      from group_rels g, acs_object_types t
     where g.rel_type = t.object_type
       and g.group_rel_id = :group_rel_id

      </querytext>
</fullquery>

 
<fullquery name="select_rel_ids">      
      <querytext>
      
	select r.rel_id 
          from acs_rels r
	 where r.rel_type = :rel_type
	   and r.object_id_one = :group_id
    
      </querytext>
</fullquery>

 
<fullquery name="select_segments">      
      <querytext>
      
	    select segment_id
	      from rel_segments 
	     where group_id = :group_id
	       and rel_type = :rel_type
	
      </querytext>
</fullquery>

 
<fullquery name="remove_relationship_type">      
      <querytext>
      
	    delete from group_rels where group_rel_id = :group_rel_id
	
      </querytext>
</fullquery>

 
</queryset>

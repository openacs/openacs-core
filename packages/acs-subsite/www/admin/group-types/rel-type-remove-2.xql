<?xml version="1.0"?>
<queryset>

<fullquery name="select_group_type">      
      <querytext>
      
	select g.group_type
	from group_type_rels g 
	where g.group_rel_type_id = :group_rel_type_id
    
      </querytext>
</fullquery>

 
<fullquery name="remove_relation">      
      <querytext>
      
	    delete from group_type_rels where group_rel_type_id = :group_rel_type_id
	
      </querytext>
</fullquery>

 
</queryset>

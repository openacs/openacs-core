<?xml version="1.0"?>
<queryset>

<fullquery name="delete_group_rel_mapping">      
      <querytext>
      
	delete from group_rels 
	 where group_rel_id = :group_rel_id
    
      </querytext>
</fullquery>

 
<fullquery name="delete_group_type_rel_mapping">      
      <querytext>
      
	delete from group_type_rels 
	 where group_type_rel_id = :group_type_rel_id
    
      </querytext>
</fullquery>

 
</queryset>

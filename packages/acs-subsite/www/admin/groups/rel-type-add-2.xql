<?xml version="1.0"?>
<queryset>

<fullquery name="select_group_type">      
      <querytext>
      
	    select o.object_type as group_type
	      from acs_objects o
	     where o.object_id = :group_id
	
      </querytext>
</fullquery>

 
</queryset>

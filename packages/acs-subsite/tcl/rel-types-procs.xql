<?xml version="1.0"?>
<queryset>

<fullquery name="new.parent_rel_type">      
      <querytext>
      
	    select table_name as references_table,
	           id_column as references_column
	      from acs_object_types
	     where object_type=:supertype
	
      </querytext>
</fullquery>

 
</queryset>

<?xml version="1.0"?>
<queryset>

<fullquery name="select_object_type">      
      <querytext>
      
	    select attr.object_type 
	      from acs_attributes attr
	     where attr.attribute_id = :attribute_id
	
      </querytext>
</fullquery>

 
</queryset>

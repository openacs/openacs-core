<?xml version="1.0"?>
<queryset>

<fullquery name="select_object_type">      
      <querytext>
      
    select a.object_type, a.pretty_name as attribute_pretty_name
      from acs_attributes a  
     where a.attribute_id = :attribute_id

      </querytext>
</fullquery>

 
</queryset>

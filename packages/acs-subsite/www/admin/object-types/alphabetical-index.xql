<?xml version="1.0"?>
<queryset>

<fullquery name="object_type_in_alphabetical_order">      
      <querytext>
      
    select object_type,
           pretty_name
      from acs_object_types
     order by lower(pretty_name)

      </querytext>
</fullquery>

 
</queryset>

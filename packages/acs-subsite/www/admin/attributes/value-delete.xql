<?xml version="1.0"?>
<queryset>

<fullquery name="select_pretty_name">      
      <querytext>
      
    select v.pretty_name
      from acs_enum_values v
     where v.attribute_id = :attribute_id
       and v.enum_value = :enum_value

      </querytext>
</fullquery>

 
</queryset>

<?xml version="1.0"?>
<queryset>

<fullquery name="number_values">      
      <querytext>
      
    select count(*) 
      from acs_enum_values v
     where v.attribute_id = :attribute_id

      </querytext>
</fullquery>

 
<fullquery name="select_current_values">      
      <querytext>
      
    select v.enum_value
      from acs_enum_values v
     where v.attribute_id = :attribute_id
     order by v.sort_order

      </querytext>
</fullquery>

 
<fullquery name="select_attr_name">      
      <querytext>
      
    select a.pretty_name as attribute_pretty_name
      from acs_attributes a
     where a.attribute_id = :attribute_id

      </querytext>
</fullquery>

 
</queryset>

<?xml version="1.0"?>
<queryset>

<fullquery name="select_pretty_name">      
      <querytext>
      
    select t.pretty_name as rel_type_pretty_name
      from acs_object_types t
     where t.object_type = :rel_type

      </querytext>
</fullquery>

 
</queryset>

<?xml version="1.0"?>
<queryset>

<fullquery name="select_pretty_name">      
      <querytext>
      
    select t.pretty_name as rel_type_pretty_name, t.table_name, t.id_column, t.dynamic_p
      from acs_object_types t
     where t.object_type = :rel_type

      </querytext>
</fullquery>

 
<fullquery name="attributes_select">      
      <querytext>
      
    select a.attribute_id, a.pretty_name
      from acs_attributes a
     where a.object_type = :rel_type

      </querytext>
</fullquery>

 
</queryset>

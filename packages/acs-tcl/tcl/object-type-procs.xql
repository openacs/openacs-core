<?xml version="1.0"?>
<queryset>

<fullquery name="acs_object_type_hierarchy.object_types">      
      <querytext>
        $sql
      </querytext>
</fullquery>

<fullquery name="acs_object_type::get_table_name_not_cached.get_table_name">
      <querytext>

        select table_name from acs_object_types
        where object_type = :object_type

      </querytext>
</fullquery>
 
</queryset>

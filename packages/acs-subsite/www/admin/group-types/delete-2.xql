<?xml version="1.0"?>
<queryset>

<fullquery name="select_type_info">      
      <querytext>
      
    select t.table_name, t.package_name
      from acs_object_types t
     where t.object_type=:group_type

      </querytext>
</fullquery>

</queryset>

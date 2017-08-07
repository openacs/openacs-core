<?xml version="1.0"?>
<queryset>

  <fullquery name="package_create.select_package_name">      
    <querytext>
      
      select t.package_name
      from acs_object_types t
      where t.object_type = :object_type
      
    </querytext>
  </fullquery>

  
  <fullquery name="package_instantiate_object.package_select">      
    <querytext>
      
      select t.package_name
      from acs_object_types t
      where t.object_type = :object_type
      
    </querytext>
  </fullquery>
  
  <fullquery name="package_instantiate_object.get_id_column">      
    <querytext>
      
      select id_column
      from acs_object_types
      where object_type = :object_type
      
    </querytext>
  </fullquery>

  
  <fullquery name="package_object_view_helper.select_type_info">      
    <querytext>

      select t.table_name, t.id_column
      from acs_object_types t
      where t.object_type = :object_type
      
    </querytext>
  </fullquery>
  
</queryset>

<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="group_and_rel_info">      
      <querytext>
      
    select acs_group.name(:group_id) as group_name,
           acs_object_type.pretty_name(:rel_type) as rel_type_pretty_name,
           acs_rel_type.role_pretty_plural(rel_types.role_two) as role_pretty_plural,
           acs_rel_type.role_pretty_name(rel_types.role_two) as role_pretty_name
      from acs_rel_types rel_types
     where rel_types.rel_type = :rel_type

      </querytext>
</fullquery>

 
</queryset>

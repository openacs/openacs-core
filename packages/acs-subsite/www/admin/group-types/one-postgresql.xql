<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="attributes_select">      
      <querytext>
    with recursive group_hierarchy as (
       select object_type, pretty_name, 1 as type_level
       from acs_object_types
       where object_type = 'group'

       union all

       select t.object_type, t.pretty_name, h.type_level + 1 as type_level
       from acs_object_types t,
            group_hierarchy h
       where t.supertype = h.object_type
    )
    select a.attribute_id,
           a.pretty_name,
           a.ancestor_type,
           t.pretty_name as ancestor_pretty_name
      from acs_object_type_attributes a,
           group_hierarchy t
     where a.object_type = :group_type
       and t.object_type = a.ancestor_type
    order by type_level
      </querytext>
</fullquery>

</queryset>

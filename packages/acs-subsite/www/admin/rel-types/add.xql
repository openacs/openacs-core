<?xml version="1.0"?>
<queryset>

<fullquery name="select_primary_relations">      
      <querytext>
      
    select o.object_type as rel_type, o.pretty_name
      from acs_object_types o
     where o.object_type in ('composition_rel','membership_rel')
       and o.object_type not in (select g.rel_type from group_type_allowed_rels g where g.group_type = :object_type)

      </querytext>
</fullquery>

 
</queryset>

<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_primary_relations">      
      <querytext>
      
    select replace(lpad(' ', (t.type_level - 1) * 4), ' ', '&nbsp;') as indent,
           t.pretty_name, t.rel_type
      from (select t.pretty_name, t.object_type as rel_type, level as type_level
              from acs_object_types t
             where t.object_type not in (select g.rel_type 
                                           from group_type_rels g 
                                          where g.group_type = :group_type)
           connect by prior t.object_type = t.supertype
             start with t.object_type in ('membership_rel', 'composition_rel')) t,
           acs_rel_types rel_type
     where t.rel_type = rel_type.rel_type
       and (rel_type.object_type_one = :group_type 
            or acs_object_type.is_subtype_p(rel_type.object_type_one, :group_type) = 't')

      </querytext>
</fullquery>

 
</queryset>

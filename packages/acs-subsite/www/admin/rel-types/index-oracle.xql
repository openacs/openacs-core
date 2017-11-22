<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_relation_types">      
      <querytext>
      
    select t.object_type as rel_type, t.pretty_name, t.indent, 
           nvl(num.number_relationships,0) as number_relationships
      from (select t.pretty_name, t.object_type, rownum as inner_rownum,
                   replace(lpad(' ', (level - 1) * 4), ' ', '&nbsp;') as indent
              from acs_object_types t
           connect by prior t.object_type = t.supertype
             start with t.object_type in ('membership_rel','composition_rel')
             order by lower(t.pretty_name)) t,
           (select r.rel_type, count(*) as number_relationships
              from acs_objects o, acs_rel_types r, 
                   app_group_distinct_rel_map m
             where r.rel_type = o.object_type
               and o.object_id = m.rel_id
               and m.package_id = :package_id
             group by r.rel_type) num
     where t.object_type = num.rel_type(+)
    order by t.inner_rownum

      </querytext>
</fullquery>

 
</queryset>

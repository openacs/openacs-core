<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_group_types">      
      <querytext>
      
    select t.object_type as group_type, t.pretty_plural, 
           nvl(num.number_groups,0) as number_groups, t.indent
      from (select t.object_type, t.pretty_plural, rownum as inner_rownum,
                   replace(lpad(' ', (level - 1) * 4), ' ', '&nbsp;') as indent
              from acs_object_types t
           connect by prior t.object_type = t.supertype
             start with t.object_type = 'group'
             order by lower(t.pretty_plural)) t, 
           (select o.object_type, count(*) number_groups
              from groups g, acs_objects o,  
                   acs_object_party_privilege_map perm,
                   application_group_element_map app_group
             where perm.object_id = g.group_id
               and perm.party_id = :user_id
               and perm.privilege = 'read'
               and o.object_id = g.group_id
               and app_group.package_id = :package_id
               and app_group.element_id = g.group_id
             group by o.object_type) num
     where t.object_type = num.object_type(+)
     order by t.inner_rownum

      </querytext>
</fullquery>

 
</queryset>

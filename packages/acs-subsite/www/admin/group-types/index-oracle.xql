<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_group_types">      
      <querytext>
    with group_types(object_type,pretty_plural,mylevel) as (
        select object_type, pretty_plural, 0 as mylevel
          from acs_object_types
         where object_type = 'group'

        union all

        select t.object_type, t.pretty_plural, s.mylevel + 1 as mylevel
          from acs_object_types t,
               group_types s
         where t.supertype = s.object_type
    )
    select t.object_type as group_type, t.pretty_plural,
	   coalesce(num.number_groups,0) as number_groups,
	   t.mylevel * 4 as indent
      from group_types t left outer join
	   (select object_type, count(group_id) as number_groups from
  	     (select distinct o.object_type, g.group_id
                from groups g, acs_objects o,
                     application_group_element_map app_group
               where acs_permission.permission_p(g.group_id, :user_id, 'read') = 't'
                 and o.object_id = g.group_id
                 and ((app_group.package_id = :package_id and app_group.element_id = g.group_id)
		 -- the or-clause below is just needed for "Registered Users" (-2)
		 -- which is an application group for e.g. a subsite,
		 -- but not mapped to it via application_group_element_map
	         or  (o.object_id = :registered_users)
	     )) counts
             group by object_type) num
             on (num.object_type = t.object_type)
     order by indent asc
      </querytext>
</fullquery>
</queryset>

# /packages/mbryzek-subsite/www/admin/groups/one.tcl

ad_page_contract {
    Display all types of groups for this subsite

    @author mbryzek@arsdigita.com

    @creation-date 2000-11-06
    @cvs-id $Id$
} {
} -properties {
    context:onevalue
    group_types:multirow
}

set doc(title) [_ acs-subsite.Group_type_administration]
set context [list [_ acs-subsite.Group_Types]]

# we may want to move the inner count to get the number of groups of
# each type to its own pl/sql function. That way, we execute the
# function once for each group type, a number much smaller than the
# number of objects in the system.

set user_id [ad_conn user_id]

set package_id [ad_conn package_id]

set registered_users [acs_magic_object registered_users]

db_multirow group_types select_group_types {
    with recursive group_types as (
        select object_type, pretty_plural, 0 as level
          from acs_object_types
         where object_type = 'group'

        union all

        select t.object_type, t.pretty_plural, s.level + 1 as level
          from acs_object_types t,
               group_types s
         where t.supertype = s.object_type
    )
    select t.object_type as group_type, t.pretty_plural,
	   coalesce(num.number_groups,0) as number_groups,
	   t.level * 4 as indent
      from group_types t left outer join
	   (select object_type, count(group_id) as number_groups from
  	     (select distinct o.object_type, g.group_id
                from groups g, acs_objects o,
                     application_group_element_map app_group
               where acs_permission.permission_p(g.group_id, :user_id, 'read')
                 and o.object_id = g.group_id
                 and ((app_group.package_id = :package_id and app_group.element_id = g.group_id)
		 -- the or-clause below is just needed for "Registered Users" (-2)
		 -- which is an application group for e.g. a subsite,
		 -- but not mapped to it via application_group_element_map
	         or  (o.object_id = :registered_users)
	     )) counts
             group by object_type) num
             using (object_type)
     order by indent asc
} {
    set indent [string repeat "&nbsp;" $indent]
}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

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

db_multirow group_types select_group_types {
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
}

ad_return_template

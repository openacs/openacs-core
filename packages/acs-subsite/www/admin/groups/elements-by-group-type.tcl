# /packages/subsite/www/admin/groups/elements-by-rel-type.tcl
#
# Datasource for elements-by-rel-type.adp 
# (meant to be included by other templates) 
#
# Shows the user a summary of components (NOT members!) of the given 
# group, provided that the the user has permission to see the component.  
# The components are summarized by their relationship to the given group.
#
# NOTE:
# There is no scope check done here to ensure that the component "belongs" to
# the subsite.  The pages that use this template already check that the
# given group_id is in scope; therefore, all of its components must be in
# scope.  And even if a developer screws up and uses this template without
# checking that the give group_id belongs to the current subsite, the user
# would only be able to see components that they have permission to see.
# Thus we take the lazy (and efficient) approach of not checking the
# scope of the components returned by this datasource.
#
# Params: group_id
#
# @author oumi@arsdigita.com
# @creation-date 2001-2-6
# @cvs-id $Id$

# Select out group types that have at least one group. Count up the
# number of groups to decide later if we display them all

set user_id [ad_conn user_id]
set package_id [ad_conn package_id]

template::multirow create group_types group_type group_type_enc type_pretty_name number_groups

# ISSUE: this doesn't check permissions when generating the number_groups.
# So a user might be told that there are 156 groups of type X, then when they
# click to zoom in, they see only 10 groups listed (because they only have
# permission on 10 groups).  I think the group-types/groups-display page 
# should tell you total number of groups, and tell you "these are the ones
# you have read privilege on", so you don't get confused.
db_foreach select_group_types {
    select /*+ ORDERED */ 
           t.object_type, t.pretty_name, count(g.group_id) as number_groups
      from groups g, acs_objects o, acs_object_types t,
           application_group_element_map app_group
     where o.object_id = g.group_id
       and o.object_type = t.object_type
       and app_group.package_id = :package_id
       and app_group.element_id = g.group_id
     group by t.object_type, t.pretty_name
     order by lower(t.pretty_name)
} {
    template::multirow append group_types $object_type [ad_urlencode $object_type] $pretty_name $number_groups
}

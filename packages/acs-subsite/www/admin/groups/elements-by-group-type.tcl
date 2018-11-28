ad_include_contract {

    /packages/subsite/www/admin/groups/elements-by-rel-type.tcl

    Datasource for elements-by-rel-type.adp
    (meant to be included by other templates)

    Shows the user a summary of components (NOT members!) of the given
    group, provided that the user has permission to see the component.
    The components are summarized by their relationship to the given
    group.

    NOTE:
    There is no scope check done here to ensure that the component "belongs" to
    the subsite.  The pages that use this template already check that the
    given group_id is in scope; therefore, all of its components must be in
    scope.  And even if a developer screws up and uses this template without
    checking that the give group_id belongs to the current subsite, the user
    would only be able to see components that they have permission to see.
    Thus we take the lazy (and efficient) approach of not checking the
    scope of the components returned by this datasource.

    @author oumi@arsdigita.com
    @creation-date 2001-2-6
    @cvs-id $Id$

    Select out group types that have at least one group. Count up the
    number of groups to decide later if we display them all

} {
    group_id:integer
}

# ISSUE: this doesn't check permissions when generating the number_groups.
# So a user might be told that there are 156 groups of type X, then when they
# click to zoom in, they see only 10 groups listed (because they only have
# permission on 10 groups).  I think the group-types/groups-display page 
# should tell you total number of groups, and tell you "these are the ones
# you have read privilege on", so you don't get confused.

db_multirow -extend {group_type_enc} group_types select_group_types {
     select t.object_type as group_type,
            t.pretty_name as type_pretty_name,
            count(g.group_id) as number_groups
     from   groups g, acs_objects o, acs_object_types t,
            application_group_element_map app_group
     where o.object_id = g.group_id
       and o.object_type = t.object_type
       and app_group.package_id = (select package_id from application_groups where group_id = :group_id)
       and app_group.element_id = g.group_id
     group by t.object_type, t.pretty_name
     order by lower(t.pretty_name)
} {
    set group_type_enc [ad_urlencode $group_type]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

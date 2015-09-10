# /packages/subsite/www/admin/groups/elements-by-rel-type.tcl
#
# Datasource for elements-by-rel-type.adp 
# (meant to be included by other templates) 
#
# Shows the user a summary of elements (components or members) of the given 
# group, provided that the the user has permission to see the element.  
# The elements are summarized by their relationship to the given group.
#
# NOTE:
# There is no scope check done here to ensure that the element "belongs" to
# the subsite.  The pages that use this template already check that the
# given group_id is in scope; therefore, all of its elements must be in
# scope.  And even if a developer screws up and uses this template without
# checking that the give group_id belongs to the current subsite, the user
# would only be able to see elements that they have permission to see.
# Thus we take the lazy (and efficient) approach of not checking the
# scope of the elements returned by this datasource.
#
# Params: group_id
#
# @author oumi@arsdigita.com
# @creation-date 2001-2-6
# @cvs-id $Id$

set user_id [ad_conn user_id]
set admin_p [permission::permission_p -object_id $group_id -privilege "admin"]
set create_p [permission::permission_p -object_id $group_id -privilege "create"]

set return_url "[ad_conn url]?[ad_conn query]"
set return_url_enc [ad_urlencode $return_url]

db_multirow -extend {elements_display_url relations_add_url} rels relations_query { 
    select g.rel_type, g.group_rel_id,
           acs_object_type.pretty_name(g.rel_type) as rel_type_pretty_name,
           s.segment_id, s.segment_name, 
           acs_rel_type.role_pretty_plural(rel_types.role_two) as role_pretty_plural,
           acs_rel_type.role_pretty_name(rel_types.role_two) as role_pretty_name,
           rels.num_rels,
           decode(valid_types.group_id, null, 0, 1) as rel_type_valid_p
      from group_rels g, 
           rel_segments s, 
           acs_rel_types rel_types,
           (select rel_type, count(*) as num_rels
              from group_component_map
             where group_id = :group_id
               and group_id = container_id
           group by rel_type
           UNION ALL
           select rel_type, count(*) as num_rels
             from group_approved_member_map
             where group_id = :group_id
               and group_id = container_id
           group by rel_type) rels,
           rc_valid_rel_types valid_types
     where g.group_id = s.group_id(+)
       and g.rel_type = s.rel_type(+)
       and g.rel_type = rels.rel_type(+)
       and g.rel_type = rel_types.rel_type
       and g.group_id = :group_id
       and g.group_id = valid_types.group_id(+)
       and g.rel_type = valid_types.rel_type(+)
     order by lower(g.rel_type)
} {
    # The role pretty names can be message catalog keys that need
    # to be localized before they are displayed
    set role_pretty_name [lang::util::localize $role_pretty_name]
    set role_pretty_plural [lang::util::localize $role_pretty_plural]    

    set elements_display_url [export_vars -base "elements-display" {group_id rel_type}]
    set relations_add_url [export_vars -base "../relations/add" {group_id rel_type {return_url $return_url}}]

}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

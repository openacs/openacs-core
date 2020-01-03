# /packages/subsite/www/admin/rel-segments/one.tcl

ad_page_contract {

    Displays information about one relational segment

    @author mbryzek@arsdigita.com
    @creation-date Mon Dec 11 14:38:26 2000
    @cvs-id $Id$

} {
    segment_id:naturalnum,notnull
} -properties {
    context:onevalue
    props:onerow
    number_elements:onevalue
    admin_p:onevalue
} -validate {
    segment_exists_p -requires {segment_id:notnull} {
        if { ![permission::permission_p -object_id $segment_id -privilege "read"] } {
            ad_complain "The segment either does not exist or you do not have permission to view it"
        }
    }
    segment_in_scope_p -requires {segment_id:notnull segment_exists_p} {
        if { ![application_group::contains_segment_p -segment_id $segment_id]} {
            ad_complain "The segment either does not exist or does not belong to this subsite."
        }
    }
}

set context [list [list "./" "Relational segments"] "One segment"]

if { ![db_0or1row select_segment_properties {
    select s.segment_id,
           s.segment_name,
           s.group_id,
           (select group_name from groups
             where group_id = s.group_id) as group_name,
           s.rel_type,
           (select pretty_name from acs_object_types
             where object_type = r.rel_type) as rel_type_pretty_name,
           (select pretty_plural from acs_rel_roles
             where role = r.role_two) as role_pretty_plural
      from rel_segments s, acs_rel_types r
     where s.segment_id = :segment_id
       and s.rel_type = r.rel_type    
} -column_array props] } {
    ad_return_error \
        "Segment does not exist" \
        "Segment $segment_id does not exist"
    ad_script_abort
}

set props(role_pretty_plural) [lang::util::localize $props(role_pretty_plural)]

set name_edit_url [export_vars -base edit { segment_id }]

# Pull out the number of elements that the current user can see. We do
# this separately to avoid the join above. This query may need to
# removed or changed to handle the permissions check more efficiently

set group_id $props(group_id)
set rel_type $props(rel_type)

set user_id [ad_conn user_id]

db_multirow constraints constraints_select {
    select c.constraint_id, c.constraint_name, c.rel_side
      from rel_constraints c
     where c.rel_segment = :segment_id
}

db_1row select_segment_info {
    select count(*) as number_elements
      from rel_segment_party_map map
    where map.segment_id = :segment_id
    and acs_permission.permission_p(map.party_id, :user_id, 'read')
}
set number_elements [util_commify_number $number_elements]

set admin_p [permission::permission_p -object_id $segment_id -privilege "admin"]

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

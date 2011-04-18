# /packages/mbryzek-subsite/www/admin/rel-segments/index.tcl

ad_page_contract {

    Shows all relational segments that the user has read permission on

    @author mbryzek@arsdigita.com
    @creation-date Mon Dec 11 12:13:02 2000
    @cvs-id $Id$

} {
} -properties {
    context:onevalue
    seg:multirow
}

set context [list [_ acs-subsite.Relational_Segments]]
set doc(title) [_ acs-subsite.Relational_Segment_administration]

set user_id [ad_conn user_id]

set package_id [ad_conn package_id]

# Select out basic information about all the segments on which the
# user has read permission

db_multirow seg select_rel_segments {
    select s.segment_id, s.segment_name, s.group_id, acs_object.name(s.group_id) as group_name, 
           s.rel_type, t.pretty_name as rel_type_pretty_name
      from acs_object_types t, 
           rel_segments s, 
           acs_object_party_privilege_map perm,
           application_group_segments ags
     where perm.object_id = s.segment_id
       and perm.party_id = :user_id
       and perm.privilege = 'read'
       and t.object_type = s.rel_type
       and s.segment_id = ags.segment_id
       and ags.package_id = :package_id
     order by lower(s.segment_name)
}

ad_return_template

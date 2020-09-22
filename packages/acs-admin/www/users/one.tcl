ad_page_contract {
    One user view by an admin
    rewritten by philg@mit.edu on October 31, 1999
    makes heavy use of procedures in /tcl/ad-user-contributions-summary.tcl
    modified by mobin January 27, 2000 5:08 am

    @cvs-id $Id$
} {
    user_id:naturalnum,notnull
}


acs_user::get -user_id $user_id -array user_info
if {[array size user_info] == 0} {
    ad_return_complaint 1 "<li>We couldn't find user #$user_id; perhaps this person was deleted?"
    ad_script_abort
}

set user_info(last_visit_pretty) [lc_time_fmt $user_info(last_visit_ansi) "%q %X"]
set user_info(creation_date_pretty) [lc_time_fmt $user_info(creation_date) "%q"]
set user_info(url) [acs_community_member_url -user_id $user_id]
set user_info(by_ip_url) [export_vars -base "complex-search" {
    { target one } { ip $user_info(creation_ip) }
}]
set ip_info_url "/acs-admin/ip-info"

if {[db_0or1row get_last_contrib {
    select object_id, title, creation_date, creation_ip from acs_objects
    where object_id = (select max(object_id) from acs_objects where creation_user = :user_id)}]} {
    set user_info(last_contrib) "[lc_time_fmt $creation_date %q] on $title ($object_id)"
    set user_info(last_contrib_ip) $creation_ip
    set user_info(last_contrib_ip_url) [export_vars -base "complex-search" { { target one } { ip $user_info(last_contrib_ip) } }]
} else {
    set user_info(last_contrib) none
    set user_info(last_contrib_ip) ""
}
set return_url [ad_return_url]

set delete_user_url [export_vars -base delete-user { user_id return_url {permanent f}}]
set delete_user_permanent_url [export_vars -base delete-user { user_id {return_url /acs-admin/users} {permanent t}}]

#
# RBM: Check if the requested user is a site-wide admin and warn the
# viewer in that case (so that a ban/deletion can be avoided).
#

set site_wide_admin_p [acs_user::site_wide_admin_p -user_id $user_id]
set warning_p 0
set ad_conn_user_id [ad_conn user_id]

#
# Define the url for switching side-wide admin privileges with a timeout of 60 seconds
#
if { $site_wide_admin_p } {
    set modify_admin_url [export_vars -base modify-admin-privileges {user_id:sign(max_age=60) {action:sign revoke}}]
    set warning_p 1
} else {
    set modify_admin_url [export_vars -base modify-admin-privileges {user_id:sign(max_age=60) {action:sign grant}}]
}


set context [list [list "./" "Users"] "One User"]

if {[db_0or1row get_item_id {
    select coalesce(title,'view this portrait') as portrait_title
    from acs_rels a, cr_items c, cr_revisions cr
    where a.object_id_two = c.item_id
         and c.live_revision = cr.revision_id
         and a.object_id_one = :user_id
         and a.rel_type = 'user_portrait_rel'}]} {
    set portrait_url [export_vars -base /shared/portrait { user_id }]
}

set user_finite_state_links [join [ad_registration_finite_state_machine_admin_links $user_info(member_state) $user_info(email_verified_p) $user_id] " | "]


# XXX Make sure to make the following into links and this looks okay

db_multirow user_contributions user_contributions {
    select at.pretty_name,
           at.pretty_plural,
           to_char(a.creation_date, 'YYYY-MM-DD HH24:MI:SS') as creation_date,
           acs_object.name(a.object_id) as object_name
      from acs_objects a, acs_object_types at
     where a.object_type = at.object_type
       and a.creation_user = :user_id
     order by pretty_name, creation_date desc, object_name
}

# cro@ncacasi.org 2002-02-20
# Boy, is this query wacked, but I think I am starting to understand
# how this groups thing works.
# Find out which groups this user belongs to where he was added to the group
# directly (e.g. his membership is not by virtue of the group being
# a component of another group).
db_multirow direct_group_membership direct_group_membership {}

# And also get the list of all groups he is a member of, direct or
# inherited.
db_multirow all_group_membership all_group_membership {
    select distinct lower(groups.group_name) as group_name
    from   groups, group_member_map gm
    where  groups.group_id = gm.group_id and gm.member_id = :user_id
   order by lower(groups.group_name)
}

if { [auth::password::can_reset_p -authority_id $user_info(authority_id)] } {
    set password_reset_url [export_vars -base "password-reset" { user_id return_url }]
    set password_update_url [export_vars -base "password-update" { user_id return_url }]
}

set portrait_manage_url [export_vars -base /user/portrait/ { user_id return_url }]


ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

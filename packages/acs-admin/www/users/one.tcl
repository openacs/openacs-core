ad_page_contract {
    One user view by an admin
    rewritten by philg@mit.edu on October 31, 1999
    makes heavy use of procedures in /tcl/ad-user-contributions-summary.tcl
    modified by mobin January 27, 2000 5:08 am
    
    @cvs-id $Id$
} {
    user_id:integer
}

with_catch errmsg {
    acs_user::get -user_id $user_id -array user_info
} {
    ad_return_complaint 1 "<li>We couldn't find user #$user_id; perhaps this person was deleted?"
    return
}
set user_info(last_visit_pretty) [lc_time_fmt $user_info(last_visit_ansi) "%q %X"]
set user_info(creation_date_pretty) [lc_time_fmt $user_info(creation_date) "%q"]
set user_info(url) [acs_community_member_url -user_id $user_id]
set user_info(by_ip_url) [export_vars -base "complex-search" { { target one } { ip $user_info(creation_ip) } }]

set return_url [ad_return_url]

set delete_user_url [export_vars -base delete-user { user_id return_url {permanent f}}]
set delete_user_permanent_url [export_vars -base delete-user { user_id return_url {permanent t}}]

#
# RBM: Check if the requested user is a site-wide admin and warn the 
# viewer in that case (so that a ban/deletion can be avoided).
#

set site_wide_admin_p [acs_user::site_wide_admin_p -user_id $user_id]
set warning_p 0
set ad_conn_user_id [ad_conn user_id]

if { $site_wide_admin_p } {
    set warning_p 1
}


set context [list [list "./" "Users"] "One User"]

if {[db_0or1row get_item_id "select live_revision as revision_id, nvl(title,'view this portrait') portrait_title
from acs_rels a, cr_items c, cr_revisions cr 
where a.object_id_two = c.item_id
and c.live_revision = cr.revision_id
and a.object_id_one = :user_id
and a.rel_type = 'user_portrait_rel'"]} {
    set portrait_url [export_vars -base /shared/portrait { user_id }]
}

set user_finite_state_links "[join [ad_registration_finite_state_machine_admin_links $user_info(member_state) $user_info(email_verified_p) $user_id] " | "]"


# XXX Make sure to make the following into links and this looks okay

db_multirow user_contributions  user_contributions "select at.pretty_name, at.pretty_plural, a.creation_date, acs_object.name(a.object_id) object_name
from acs_objects a, acs_object_types at
where a.object_type = at.object_type
and a.creation_user = :user_id
order by object_name, creation_date"

# cro@ncacasi.org 2002-02-20 
# Boy is this query wacked, but I think I am starting to understand
# how this groups thing works.
# Find out which groups this user belongs to where he was added to the group
# directly (e.g. his membership is not by virtue of the group being
# a component of another group).
db_multirow direct_group_membership direct_group_membership "
  select group_id, rel_id, party_names.party_name as group_name
    from (select /*+ ORDERED */ DISTINCT rels.rel_id, object_id_one as group_id, 
                 object_id_two
            from acs_rels rels, all_object_party_privilege_map perm
           where perm.object_id = rels.rel_id
                 and perm.privilege = 'read'
                 and rels.rel_type = 'membership_rel'
                 and rels.object_id_two = :user_id) r, 
         party_names 
   where r.group_id = party_names.party_id
order by lower(party_names.party_name)"

# And also get the list of all groups he is a member of, direct or
# inherited.
db_multirow all_group_membership all_group_membership "
  select groups.group_id, groups.group_name
     from groups, group_member_map gm
     where groups.group_id = gm.group_id and gm.member_id=:user_id
  order by lower(groups.group_name)"

if { [auth::password::can_reset_p -authority_id $user_info(authority_id)] } {
    set password_reset_url [export_vars -base "password-reset" { user_id return_url }]
    set password_update_url [export_vars -base "password-update" { user_id return_url }]
}

set portrait_manage_url [export_vars -base /user/portrait/ { user_id return_url }]


ad_return_template



# The code from below is from pre-ACS 4.0 and should be revised for entry later

# it looks like we should be doing 0or1row but actually
# we might be in an ACS installation where users_demographics
# isn't used at all

#  set contact_info [ad_user_contact_info $user_id "site_admin"]

#  if {$contact_info ne ""} {
#      append whole_page "<h3>Contact Info</h3>\n\n$contact_info\n
#  <ul>
#  <li><a href=contact-edit?[export_url_vars user_id]>Edit contact information</a>
#  </ul>"
#  } else {
#      append whole_page "<h3>Contact Info</h3>\n\n$contact_info\n
#  <ul>
#  <li><a href=contact-edit?[export_url_vars user_id]>Add contact information</a>
#  </ul>"
#  }

#  if {[db_table_exists users_demographics]} {
#      if {[db_0or1row user_demographics "select 
#      ud.*,
#      u.first_names as referring_user_first_names,
#      u.last_name as referring_user_last_name
#      from users_demographics ud, users u
#      where ud.user_id = $user_id
#      and ud.referred_by = u.user_id(+)"]} {
#  	# the table exists and there is a row for this user
#  	set demographic_items ""
#  	for {set i 0} {$i<[ns_set size $selection]} {incr i} {
#  	    set varname [ns_set key $selection $i]
#  	    set varvalue [ns_set value $selection $i]
#  	    if { $varname ne "user_id" && $varvalue ne "" } {
#  		append demographic_items "<li>$varname: $varvalue\n"
#  	    }
#  	}
#  	if {$demographic_items ne ""} {
#  	    append whole_page "<h3>Demographics</h3>\n\n<ul>$demographic_items</ul>\n"
	    
#  	}
#      }
#  }

#  if {[db_table_exists categories] && [db_table_exists users_interests]} {
#      set category_items ""
#      db_foreach users_interests "select c.category 
#      from categories c, users_interests ui 
#      where ui.user_id = $user_id
#      and c.category_id = ui.category_id" {
#  	append category_items "<LI>$category\n"
#      }

#      if {$category_items ne ""} {
#  	append whole_page "<H3>Interests</H3>\n\n<ul>\n\n$category_items\n\n</ul>"
#      }
#  }

#  # randyg is brilliant! we can recycle the same handle here because the
#  # inner argument is evaluated before the outer one. this should actually
#  # be done with the db api. 12 june 00, richardl@arsdigita.com

#  if { [im_enabled_p] && [ad_user_group_member $db [im_employee_group_id] $user_id] } {
#      # We are running an intranet enabled acs and this user is a member of the 
#      # employees group. Offer a link to the employee administration page
#      set intranet_admin_link "<li><a href=\"[im_url_stub]/employees/admin/view?[export_url_vars user_id]\">Update this user's employee information</a><p>"
#  } else {
#      set intranet_admin_link ""
#  }


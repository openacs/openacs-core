ad_page_contract {
    displays a user's portrait to the user him/herself
    offers options to replace it

    @author philg@mit.edu
    @creation-date September 26, 1999
    @cvs-id $Id$
} {
    {return_url "" }
    {user_id ""}
} -properties {
    first_names:onevalue
    last_name:onevalue
    system_name:onevalue
    export_vars:onevalue
    widthheight:onevalue
    pretty_date:onevalue
    description:onevalue
    export_edit_vars:onevalue
    subsite_url:onevalue
    return_url:onevalue
    admin_p:onevalue
    user_id:onevalue
    return_code:onevalue
}
   
set current_user_id [ad_conn user_id]
set subsite_url     [subsite::get_element -element url]
set return_url      "[subsite::get_element -element url]user/portrait/"

set return_code "no_error"
# Other possibilities:
# no_user          : Unknown user_id, not in DB.
# no_portrait      : No portrait uploaded yet for this user.
# no_portrait_info : Unable to retrieve information on portrait.

if {$user_id eq ""} {
    set user_id $current_user_id
}

if { $current_user_id == $user_id } {
    set admin_p 1
    ad_require_permission $user_id "write"
} else {
    set admin_p 0
}

set export_vars      [export_url_vars user_id]
set export_edit_vars [export_url_vars user_id return_url]

if {![db_0or1row user_info "select 
  first_names, 
  last_name 
from persons 
where person_id=:user_id"]} {
    set return_code "no_user"
    set context [list "Account Unavailable"]
    ad_return_template
    return
}


if {![db_0or1row get_item_id "select live_revision as revision_id, item_id
from acs_rels a, cr_items c
where a.object_id_two = c.item_id
and a.object_id_one = :user_id
and a.rel_type = 'user_portrait_rel'"] || $revision_id eq ""} {
    # The user doesn't have a portrait yet
    set portrait_p 0
} else {
    set portrait_p 1
}
    
if { $admin_p } {
    set doc(title) [_ acs-subsite.Your_Portrait]
} else {
    set doc(title) [_ acs-subsite.lt_Portrait_of_first_last]
}
set context [list [list [ad_pvt_home] [ad_pvt_home_name]] $doc(title)]

if {! $portrait_p } {
    set return_code "no_portrait"
    ad_return_template
    return
}

# we have revision_id now


if {[catch {db_1row get_picture_info "
select i.width, i.height, cr.title, cr.description, cr.publish_date
from images i, cr_revisions cr
where i.image_id = cr.revision_id
and image_id = :revision_id
"} errmsg]} {
    # There was an error obtaining the picture information
    set context [list "Invalid Picture"]
    set return_code "no_portrait_info"
    ad_return_template
    return
}

if {$publish_date eq ""} {
    ad_return_complaint 1 "<li>You shouldn't have gotten here; we don't have a portrait on file for you."
    return
}

if { $width ne "" && $height ne "" } {
    set widthheight "width=$width height=$height"
} else {
    set widthheight ""
}

db_release_unused_handles

set system_name [ad_system_name]
set pretty_date [lc_time_fmt $publish_date "%q"]

ad_return_template

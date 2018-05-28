ad_page_contract {
    displays a user's portrait to other users

    @creation-date 26 Sept 1999
    @cvs-id $Id$
} {
    user_id:naturalnum,notnull
} -properties {
    context:onevalue
    first_names:onevalue
    last_name:onevalue
    description:onevalue
    export_vars:onevalue
    widthheight_param:onevalue
    publish_date:onevalue
    subsite_url:onevalue
}

set subsite_url [subsite::get_element -element url]
 
if {![person::person_p -party_id $user_id]} {    
    ad_return_warning \
        "Account Unavailable" \
        "We can't find user #$user_id in the users table."
    ad_script_abort
}

set person [person::get -person_id $user_id]
set first_names [dict get $person first_names]
set last_name   [dict get $person last_name]

set item_id [acs_user::get_portrait_id \
                 -user_id $user_id]
set portrait_p [expr {$item_id != 0}]

if {!$portrait_p} {
    ad_return_complaint 1 "<li>You shouldn't have gotten here; we don't have a portrait on file for this person."
    return
}

if {![db_0or1row get_item_id {
    select i.width, i.height, cr.title, cr.description, cr.publish_date
    from cr_revisions cr, images i
    where cr.revision_id = i.image_id
      and cr.revision_id = (select live_revision from cr_items where item_id = :item_id)
}]} {
    ad_return_complaint 1 "<li>You shouldn't have gotten here; we don't have a portrait on file for this person."
    return
}

if { $width ne "" && $height ne "" } {
    set widthheight_param "width=$width height=$height"
} else {
    set widthheight_param ""
}

set doc(title) [_ acs-subsite.lt_Portrait_of_first_last]
set context [list [list [acs_community_member_url -user_id $user_id] "$first_names $last_name"] [_ acs-subsite.Portrait]]
set portrait_image_url [export_vars -base ${subsite_url}shared/portrait-bits.tcl {user_id}]
set pretty_date [lc_time_fmt $publish_date "%q"]

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

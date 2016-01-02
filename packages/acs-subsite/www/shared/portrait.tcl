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
 
if {![db_0or1row user_info {
    select first_names, last_name
    from persons
    where person_id = :user_id
}]} {
    ad_return_warning "Account Unavailable" "We can't find user #$user_id in the users table."
    return
}

if {![db_0or1row get_item_id {
    select i.width, i.height, cr.title, cr.description, cr.publish_date
    from acs_rels a, cr_items c, cr_revisions cr, images i
    where a.object_id_two = c.item_id
    and c.live_revision = cr.revision_id
    and cr.revision_id = i.image_id
    and a.object_id_one = :user_id
    and a.rel_type = 'user_portrait_rel'
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

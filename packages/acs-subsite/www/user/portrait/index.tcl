ad_page_contract {
    Displays a user's portrait to the user him/herself
    offers options to replace it

    @author philg@mit.edu
    @creation-date September 26, 1999
    @cvs-id $Id$
} {
    {return_url:localurl "" }
    {user_id:object_type(user) ""}
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
# no_portrait      : No portrait uploaded yet for this user.
# no_portrait_info : Unable to retrieve information on portrait.

if {$user_id eq ""} {
    set user_id $current_user_id
}

if { $current_user_id == $user_id } {
    #
    # When the user is myself, we will show links to administrate the
    # portrait picture. In this case we also make sure that we have
    # write permissions on our own user.
    #
    set admin_p 1
    permission::require_permission -object_id $user_id -privilege "write"
} else {
    set admin_p 0
}

set portrait_image_url [export_vars -base ${subsite_url}shared/portrait-bits.tcl {user_id}]
set export_edit_vars   [export_vars {user_id return_url}]

set person [person::get -person_id $user_id]
set first_names [dict get $person first_names]
set last_name   [dict get $person last_name]

set item_id [acs_user::get_portrait_id \
                 -user_id $user_id]
set portrait_p [expr {$item_id != 0}]
if {$portrait_p} {
    set revision_id [content::item::get_live_revision -item_id $item_id]
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


if {![db_0or1row get_picture_info {
    select i.width, i.height, cr.title, cr.description, cr.publish_date
    from images i, cr_revisions cr
    where i.image_id = cr.revision_id
    and image_id = :revision_id
}]} {
    #
    # We found no profile picture.
    #
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

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

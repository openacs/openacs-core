# /pvt/home.tcl

ad_page_contract {
    user's workspace page
    @cvs-id $Id$
} -properties {
    system_name:onevalue
    context:onevalue
    full_name:onevalue
    email:onevalue
    url:onevalue
    screen_name:onevalue
    bio:onevalue
    portrait_state:onevalue
    portrait_publish_date:onevalue
    portrait_title:onevalue
    export_user_id:onevalue
    ad_url:onevalue
    member_link:onevalue
    subsite_url:onevalue
    pvt_home_url:onevalue
}

set user_id [ad_verify_and_get_user_id]

set subsite_url  [subsite::get_element -element url]
set pvt_home_url [ad_pvt_home]

set user_exists_p [db_0or1row pvt_home_user_info {
    select first_names, last_name, email, url,
    nvl(screen_name,'&lt none set up &gt') as screen_name
    from cc_users 
    where user_id=:user_id
}]

if { $user_exists_p && [empty_string_p $screen_name] } {
    set screen_name "[_ acs-subsite.no_screen_name_message]"
}

set bio [db_string biography "
select attr_value
from acs_attribute_values
where object_id = :user_id
and attribute_id =
   (select attribute_id
    from acs_attributes
    where object_type = 'person'
    and attribute_name = 'bio')" -default ""]

if { ! $user_exists_p } {
    if {$user_id == 0} {
	ad_redirect_for_registration
        ad_script_abort
    }
    ad_return_error "Account Unavailable" "We can't find you (user #$user_id) in the users table.  Probably your account was deleted for some reason.  You can visit <a href=\"/register/logout\">the log out page</a> and then start over."
    ad_script_abort
}

if { ![empty_string_p $first_names] || ![empty_string_p $last_name] } {
    set full_name "$first_names $last_name"
} else {
    set full_name "name unknown"
}

set system_name [ad_system_name]

if [ad_parameter SolicitPortraitP "user-info" 0] {
    # we have portraits for some users 
    if ![db_0or1row get_portrait_info "
    select cr.publish_date, nvl(cr.title,'your portrait') as portrait_title
    from cr_revisions cr, cr_items ci, acs_rels a
    where cr.revision_id = ci.live_revision
    and  ci.item_id = a.object_id_two
    and a.object_id_one = :user_id
    and a.rel_type = 'user_portrait_rel'
    "] {
	set portrait_state "upload"
    } else {
        if { [empty_string_p $portrait_title] } {
            set portrait_title "[_ acs-subsite.no_portrait_title_message]"
        }

	set portrait_state "show"
	set portrait_publish_date [lc_time_fmt $publish_date "%q"]
    }
} else {
    set portrait_state "none"
}

set header [ad_header "$full_name's workspace at $system_name"]

set context [list "[ad_pvt_home_name]"]

set export_user_id [export_url_vars user_id]
set ad_url [ad_url]

set member_link [acs_community_member_link -user_id $user_id -label "${ad_url}[acs_community_member_url -user_id $user_id]"]

set interest_items ""

ad_return_template


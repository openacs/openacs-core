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

ad_maybe_redirect_for_registration

set user_id [ad_conn user_id]

acs_user::get -array user -include_bio

set page_title [ad_pvt_home_name]

set pvt_home_url [ad_pvt_home]

set subsite_url [subsite::get_element -element url]

set context [list $page_title]

set ad_url [ad_url]

set community_member_url [acs_community_member_url -user_id $user_id]

set system_name [ad_system_name]

set portrait_upload_url [export_vars -base "../user/portrait/upload" { { return_url [ad_return_url] } }]

# Can't find out whether there's a request or not
set form_request_p 1

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


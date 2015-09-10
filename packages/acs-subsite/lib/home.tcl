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
    portrait_description:onevalue
    export_user_id:onevalue
    ad_url:onevalue
    member_link:onevalue
    pvt_home_url:onevalue
}
set login_url [ad_get_login_url]
set user_id [auth::require_login -account_status closed]

acs_user::get -array user -include_bio -user_id $user_id

set account_status [ad_conn account_status]
set subsite_url [ad_conn vhost_subsite_url]

set page_title [ad_pvt_home_name]

set pvt_home_url [ad_pvt_home]

set context [list $page_title]

set fragments [callback -catch user::workspace -user_id $user_id]

set ad_url [ad_url]

set community_member_url [acs_community_member_url -user_id $user_id]

set notifications_url [lindex [site_node::get_children -node_id [subsite::get_element -element node_id] -package_key "notifications"] 0]

set system_name [ad_system_name]

set portrait_upload_url [export_vars -base "../user/portrait/upload" { { return_url [ad_return_url] } }]

if {[parameter::get -parameter SolicitPortraitP -default 0]} {
    # we have portraits for some users 
    if {![db_0or1row get_portrait_info "
    select cr.publish_date, nvl(cr.title,'your portrait') as portrait_title,
    nvl(cr.description,'no description') as portrait_description 
    from cr_revisions cr, cr_items ci, acs_rels a
    where cr.revision_id = ci.live_revision
    and  ci.item_id = a.object_id_two
    and a.object_id_one = :user_id
    and a.rel_type = 'user_portrait_rel'
    "]} {
	set portrait_state "upload"
    } else {
        if { $portrait_title eq "" } {
            set portrait_title "[_ acs-subsite.no_portrait_title_message]"
        }

	set portrait_state "show"
	set portrait_publish_date [lc_time_fmt $publish_date "%q"]
    }
} else {
    set portrait_state "none"
}


set whos_online_url "[subsite::get_element -element url]shared/whos-online"
set make_visible_url "[subsite::get_element -element url]shared/make-visible"
set make_invisible_url "[subsite::get_element -element url]shared/make-invisible"
set invisible_p [whos_online::user_invisible_p [ad_conn untrusted_user_id]]

set subsite_id [ad_conn subsite_id]
set user_info_template [parameter::get -parameter "UserInfoTemplate" -package_id $subsite_id]

if {$user_info_template eq ""} {
    set user_info_template "/packages/acs-subsite/lib/user-info"
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

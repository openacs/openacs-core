# packages/mbryzek-subsite/www/index.tcl

ad_page_contract {

  @author rhs@mit.edu
  @author mbryzek@mit.edu

  @creation-date 2000-09-18
  @cvs-id $Id$
} {
} -properties {
    context:onevalue
    subsite_name:onevalue
    subsite_url:onevalue
    nodes:multirow
    admin_p:onevalue
    user_id:onevalue
    show_members_page_link_p:onevalue
}

set main_site_p [string equal [ad_conn package_url] "/"]

# We may have to redirect to some application page
set redirect_url [parameter::get -parameter IndexRedirectUrl -default {}]
if { $redirect_url eq "" && $main_site_p } {
    set redirect_url [parameter::get_from_package_key -package_key acs-kernel -parameter IndexRedirectUrl]
}
if { $redirect_url ne "" } {
    ad_returnredirect $redirect_url
    ad_script_abort
}

# Handle IndexInternalRedirectUrl
set redirect_url [parameter::get -parameter IndexInternalRedirectUrl -default {}]
if { $redirect_url eq "" && $main_site_p } {
    set redirect_url [parameter::get_from_package_key -package_key acs-kernel -parameter IndexInternalRedirectUrl]
}
if { $redirect_url ne "" } {
    rp_internal_redirect $redirect_url
    ad_script_abort
}

set context [list]
set package_id [ad_conn package_id]
set admin_p [permission::permission_p -object_id $package_id -party_id [ad_conn untrusted_user_id] -privilege admin]

set user_id [ad_conn user_id]
set untrusted_user_id [ad_conn untrusted_user_id]

set subsite_name [ad_conn instance_name]

set subsite_url [subsite::get_element -element url]

set show_members_list_to [parameter::get -parameter "ShowMembersListTo" -default 2]
set show_members_page_link_p \
    [expr {$admin_p
           || ($user_id != 0 && $show_members_list_to ==1)
           || $show_members_list_to == 0 }]

# User's group membership

set group_id [application_group::group_id_from_package_id]
set group_join_policy [group::join_policy -group_id $group_id]

set group_member_p [group::member_p -group_id $group_id -user_id $user_id]
set group_admin_p [group::admin_p -group_id $group_id -user_id $user_id]

set can_join_p [expr {!$group_admin_p && $group_member_p == 0 && $user_id != 0 && $group_join_policy ne "closed" }]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

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
}

# We may have to redirect to some application page
set redirect_url [parameter::get -parameter IndexRedirectUrl -default {}]

if { ![empty_string_p $redirect_url] } {
    ad_returnredirect $redirect_url
    ad_script_abort
}

set context [list]
set package_id [ad_conn package_id]
set admin_p [ad_permission_p $package_id admin]

set user_id [ad_conn user_id]

set subsite_name [db_string name {
    select acs_object.name(:package_id) from dual
}]

set subsite_url [subsite::get_element -element url]

set node_id [ad_conn node_id]

db_multirow nodes site_nodes {}


# User's group membership

set group_id [application_group::group_id_from_package_id]
set group_join_policy [group::join_policy -group_id $group_id]

set group_member_p [group::member_p -group_id $group_id -user_id $user_id]
set group_admin_p [group::admin_p -group_id $group_id -user_id $user_id]

set can_join_p [expr !$group_admin_p && $group_member_p == 0 && $user_id != 0 && ![string equal $group_join_policy "closed"]]

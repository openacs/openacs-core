ad_page_contract {

    OpenACS main index page.  This is the standard page that is used to allow users
    to login to the site.  You can customize the presentation by editing index.adp.
    However, for a real web site, you will likely need to take this file as a boiler
    plate and add the necessary content and branding items.

    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date 10/10/2000
    @cvs-id $Id$

} {
    { email "" }
} -properties {
    system_name:onevalue
    form_vars:onevalue
    allow_persistent_login_p:onevalue
    remember_password:onevalue
    node:multirow
    name:onevalue
    email:onevalue
    home_url:onevalue
    home_url_name:onevalue
    acs_version:onevalue
    acs_root_dir:onevalue
    focus:onevalue
}

# DRB: vertical applications like dotLRN can set the IndexRedirectUrl parameter to force the user
# to an index page of its choice.

set redirect_url [parameter::get_from_package_key -package_key acs-kernel -parameter IndexRedirectUrl]
if { ![string equal $redirect_url ""] } {
    ad_returnredirect $redirect_url
    ad_script_abort
}

set user_id [ad_get_user_id]
if { $user_id == 0 } {
    set user_id ""
}

set focus ""
if { [empty_string_p $user_id] } {  
    set focus "login.email"
}

# One common problem with login is that people can hit the back button
# after a user logs out and relogin by using the cached password in
# the browser. We generate a unique hashed timestamp so that users
# cannot use the back button.

set time [ns_time]
set token_id [sec_get_random_cached_token_id]
set token [sec_get_token $token_id]
set hash [ns_sha1 "$time$token_id$token"]

set system_name [ad_system_name]
set return_url "/"
set form_vars [export_form_vars return_url time token_id hash]

set allow_persistent_login_p [ad_parameter -package_id [ad_acs_kernel_id] AllowPersistentLoginP security 1]
if {[ad_parameter -package_id [ad_acs_kernel_id] DefaultPersistentLoginP security 0]} {
    set remember_password "checked=\"checked\""
} else {
    set remember_password ""
}

db_multirow nodes site_nodes {}

if { ![empty_string_p $user_id]} {
    # The user is loged in.
    if {[db_0or1row user_name_select {
	select first_names || ' ' || last_name as name, email
	from persons, parties
	where person_id = :user_id
	and person_id = party_id
    }]} {
	set home_url [ad_pvt_home]
	set home_url_name [ad_pvt_home_name]	
    }
    set requires_registration_p_clause ""
}

set acs_version [ad_acs_version]

set acs_root_dir [acs_root_dir]

ad_return_template

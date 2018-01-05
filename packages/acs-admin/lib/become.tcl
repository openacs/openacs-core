ad_page_contract {

} {

} -validate {
    dotlrn_cannot_become_wide_admin {
	if { [acs_user::site_wide_admin_p -user_id $user_id] && ![acs_user::site_wide_admin_p] } {
	    ad_complain "[_ acs-admin.lt_You_dont_have_permiss]"
	}
    }
}

set return_url [ad_pvt_home]

# Get the password and user ID

if {![db_0or1row password {select password from users where user_id = :user_id}]} {
    ad_return_error "Couldn't find user $user_id" "Couldn't find user $user_id."
    return
}

# just set a session cookie
set expire_state "s"

# note here that we stuff the cookie with the password from Oracle,
# NOT what the user just typed (this is because we want log in to be
# case-sensitive but subsequent comparisons are made on ns_crypt'ed 
# values, where string toupper doesn't make sense)

ad_user_login $user_id
ad_returnredirect $return_url
ad_script_abort

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

ad_page_contract {

} {

}

set return_url [ad_pvt_home]

# Get the password and user ID

if ![db_0or1row password "select password from users where user_id=$user_id"] {
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


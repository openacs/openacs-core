ad_page_contract {
    Let's administrator become any user.

    @author mobin@mit.edu (Usman Y. Mobin)
    @creation-date 27 Jan 2000

} {
    user_id
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
#ad_returnredirect "/cookie-chain.tcl?cookie_name=[ns_urlencode ad_auth]&cookie_value=[ad_encode_id $user_id $password]&expire_state=$expire_state&final_page=[ns_urlencode $return_url]"


ad_page_contract {
    Reset a user's password.
} {
    user_id:naturalnum,notnull
    {return_url:localurl .}
}

acs_user::get -user_id $user_id -array user_info

auth::password::reset \
    -admin \
    -authority_id $user_info(authority_id) \
    -username $user_info(username)

ad_returnredirect $return_url



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

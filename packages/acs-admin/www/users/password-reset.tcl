ad_page_contract {
    Reset a user's password.
} {
    user_id:naturalnum,notnull
    {return_url:localurl .}
}

set user_info [acs_user::get_user_info -user_id $user_id]

auth::password::reset \
    -admin \
    -authority_id [dict get $user_info authority_id] \
    -username [dict get $user_info username]

ad_returnredirect $return_url
ad_script_abort


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

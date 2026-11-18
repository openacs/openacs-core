ad_page_contract {
    Confirm a pending change to the signed-in user's email address.
} {
    token:word,notnull
}

ns_set iupdate [ns_conn outputheaders] Referrer-Policy no-referrer
ns_set iupdate [ns_conn outputheaders] Cache-Control no-store
auth::require_login -account_status closed
set user_id [auth::get_user_id -account_status closed]
set page_title [_ acs-subsite.Email_change_confirm]
set context [list $page_title]

ad_form -name email_change -action email-change-confirm -export {token} \
    -csrf_protection_p 1 \
    -edit_buttons [list [list $page_title confirm]] -form {} -on_submit {
        if {[ns_conn method] ne "POST" || ![subsite::confirm_email_change $user_id $token]} {
            ad_return_complaint 1 [_ acs-subsite.Email_change_invalid]
            ad_script_abort
        }
    } -after_submit {
        auth::verify_account_status
        util_user_message -message [_ acs-subsite.Email_change_complete]
        ad_returnredirect [ad_pvt_home]
        ad_script_abort
    }

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

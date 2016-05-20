ad_page_contract {
    The page restores a user from the deleted state.
    @cvs-id $Id$
} {
    {return_url:localurl {[ad_pvt_home]}}
}

set page_title [_ acs-mail-lite.Restore_bounce]
set context [list [list [ad_pvt_home] [ad_pvt_home_name]] $page_title]

# We do require authentication, though their account will be closed
set user_id [auth::require_login]

db_dml unbounce_user "update users set email_bouncing_p = 'f' where user_id = :user_id"
# Used in a message key
set system_name [ad_system_name]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

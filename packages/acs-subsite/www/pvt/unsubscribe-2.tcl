ad_page_contract {
    Unsubscribes from the site

    @cvs-id $Id$
} {} -properties {
    system_name:onevalue
}

auth::require_login

set page_title "Account Closed"
set context [list [list [ad_pvt_home] [ad_pvt_home_name]] $page_title]

acs_user::delete -user_id [ad_conn user_id]

set system_name [ad_system_name]

set login_url [ad_get_login_url]

auth::verify_account_status

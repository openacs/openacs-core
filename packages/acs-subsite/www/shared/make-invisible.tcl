ad_page_contract {
    Make user invisible.
}

auth::require_login

whos_online::set_invisible [ad_conn user_id]

ad_returnredirect [ad_pvt_home]


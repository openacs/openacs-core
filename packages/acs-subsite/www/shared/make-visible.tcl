ad_page_contract {
    Make user visible.
}

auth::require_login

whos_online::unset_invisible [ad_conn user_id]

ad_returnredirect [ad_pvt_home]


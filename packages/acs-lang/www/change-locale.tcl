ad_page_contract {

} {
    {user_locale ""}
    site_wide_locale
    return_url
}

lang::user::set_locale $user_locale
lang::system::set_locale $site_wide_locale

ad_returnredirect $return_url

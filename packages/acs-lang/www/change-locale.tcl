ad_page_contract {

} {
    user_locale
    return_url
}

lang::user::set_locale $user_locale

ad_returnredirect $return_url

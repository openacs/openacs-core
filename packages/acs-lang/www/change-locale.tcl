ad_page_contract {

} {
    user_locale
    return_url:localurl
}

if { [catch {lang::user::set_locale $user_locale} errmsg] } {
    ns_log Error "acs-lang/www/change-locale crashed calling lang::user::set_locale with user_locale='$user_locale'\n$errmsg"
    ad_return_error [_ acs-lang.Error_changing_locale] [_ acs-lang.User_locale_not_set]
} else {
    ad_returnredirect $return_url
}
ad_script_abort

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

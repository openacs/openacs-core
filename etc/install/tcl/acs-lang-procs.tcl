# Procs to support testing OpenACS with Tclwebtest.
#
# Procs for testing the acs-lang (I18N) package
#
# @author Peter Marklund

namespace eval ::twt::acs_lang {}

ad_proc ::twt::acs_lang::load_i18n_messages {
    {-locales ""}
} {
    Enables all locales, or a given list of locales, and 
    loads all message catalogs for those locales.
} {
    if { [empty_string_p $locales] } {
        set locales [::twt::oacs_eval {db_list all_locales {select locale from ad_locales}}]
    }

    # First enable all locales
    ::twt::oacs_eval "
        foreach locale {$locales} {
            lang::system::locale_set_enabled -locale \$locale -enabled_p t
        }
    "

    # Load all catalog files for enabled locales
    ::twt::oacs_eval lang::catalog::import
}

ad_proc ::twt::acs_lang::set_locale { locale } {
    Change locale of logged in user to locale.
} {
    ::twt::log "Changing to locale $locale"

    ::twt::do_request /acs-lang
    form find locale
    field find ~n site_wide_locale
    ::twt::multiple_select_value $locale
    form submit
}

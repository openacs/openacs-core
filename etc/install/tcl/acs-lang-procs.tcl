# Procs to support testing OpenACS with Tclwebtest.
#
# Procs for testing the acs-lang (I18N) package
#
# @author Peter Marklund

namespace eval ::twt::acs_lang {}

ad_proc ::twt::acs_lang::load_i18n_messages {} {
    Enables all locales and loads all message catalogs.
} {
    # First enable all locales
    ::twt::oacs_eval {
        set all_locales [db_list all_locales {select locale from ad_locales}]
        
        foreach locale $all_locales {
            lang::system::locale_set_enabled -locale $locale -enabled_p t
        }
    }

    # Load all catalog files (also imports en_US, but never mind)
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

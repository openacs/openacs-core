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
    if { $locales eq "" } {
        set locales [::twt::oacs::eval {db_list all_locales {select locale from ad_locales}}]
    }

    # First enable all locales
    ::twt::oacs::eval "
        foreach locale {$locales} {
            lang::system::locale_set_enabled -locale \$locale -enabled_p t
        }
    "

    # Load all catalog files for enabled locales
    ::twt::oacs::eval lang::catalog::import
}

ad_proc ::twt::acs_lang::set_locale { locale } {
    Change locale of logged in user to locale.
} {
    ::twt::log "Changing to locale $locale"

    ::twt::do_request /acs-lang
    form find locale
    ::twt::multiple_select_value site_wide_locale $locale
    form submit
}

ad_proc ::twt::acs_lang::check_no_keys { } {
    Check in the current request body for occurences of #package_key.message_key#
    which might be message keys that a developer forgot to let go through a lang::util::localize
    call to be converted into text.
} {
    if { [regexp {#[a-zA-Z0-9_.-]+\.[a-zA-Z0-9_.-]+#} [response body] message_key] } {
        ::twt::log_alert "Found \"$message_key\" on page [response url] and might be a message key that needs a lang::util::localize call"
    }
}

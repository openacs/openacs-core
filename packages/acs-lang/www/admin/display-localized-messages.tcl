ad_page_contract {
    Displays the localized messages from the database for translation

    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
    @author Christian Hvid

    @creation-date 26 October 2001
    @cvs-id $Id$
} {
    locales
    translated_p
    package_key
} -properties {
}

set tab [ns_urlencode "localized-messages"]
set return_url "display-grouped-messages?tab=$tab&locales=$locales"

if { ! $translated_p } {
    set title "Edit Untranslated - $package_key"
} else {
    set title "Edit Translated - $package_key"
}

set context_bar [ad_context_bar [list $return_url Listing] $title]

set default_locale [ad_parameter DefaultLocale]
set default_locale en_US

if { ![info exists locales] } {
    set current_locale [ad_conn locale]
} else {
    set current_locale $locales
}

# Query to get all the messages that DO NOT have a translation to the
# language selected

set cat_msg_not_translated {
    select lm1.message_key, 
           lm1.message as default_message
    from   lang_messages lm1 
    where  lm1.locale = :default_locale and
           lm1.package_key = :package_key and
           not exists (
               select 1 
               from lang_messages lm2 
               where lm2.locale = :current_locale and 
               lm1.message_key = lm2.message_key and
               lm1.package_key = lm2.package_key
           )
    order by upper(lm1.message_key)
}

# Query that get all the messages that HAVE a translation to
# the language selected

set cat_msg_translated {
    select lm1.message_key,
           lm1.message as default_message,
           lm2.message as translated_message
    from   lang_messages lm1, lang_messages lm2
    where  lm1.locale = :default_locale and
           lm1.package_key = :package_key and
           lm2.locale = :current_locale and
           lm1.message_key = lm2.message_key and
           lm1.package_key = lm2.package_key
    order by upper(lm1.message_key)
}

template::multirow create missing_translation message_key locale default_message escaped_key escaped_language
template::multirow create translated_messages message_key locale default_message translated_message escaped_key escaped_language

if { ! $translated_p } {
    db_foreach select_messages_not_translated $cat_msg_not_translated {
        template::multirow append missing_translation $message_key $current_locale [ad_quotehtml $default_message] [ns_urlencode $message_key] [ns_urlencode $current_locale]
    }
} else {
    db_foreach select_messages_translated $cat_msg_translated {
        template::multirow append translated_messages $message_key $current_locale [ad_quotehtml $default_message] [ad_quotehtml $translated_message] [ns_urlencode $message_key] [ns_urlencode $current_locale]
    }
}

db_1row select_locale_lable {
    select label as locale_label from ad_locales where locale = :current_locale
}

set escaped_package_key [ns_urlencode $package_key]

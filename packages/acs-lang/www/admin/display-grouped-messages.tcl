# /packages/acs-lang/www/admin/display-grouped-messages.tcl
ad_page_contract {
    Displays packages that contain messages.

    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
    @author Christian Hvid
    @creation-date 26 October 2001
    @cvs-id $Id$
} {
    locale:optional
} -properties {
}

set return_url "index?tab=[ns_urlencode localized-messages]"
set page_title "Messages"
set context_bar [ad_context_bar $page_title]
set default_locale en_US

if { ![info exists locale] } {
    set current_locale [ad_conn locale]
} else { 
    set current_locale $locale
}

# Query to get all packages that are prepared for translation

set grouper_msg_all {
    select distinct lm1.package_key
    from   lang_messages lm1
}

# Query to get all the packages that have untranslated messages in the
# selected locale

set grouper_msg_not_translated {
    select distinct lm1.package_key
    from   lang_messages lm1
    where  lm1.locale = :default_locale
    and    not exists (
           select 1
           from lang_messages lm2
           where lm2.locale = :current_locale and
           lm1.message_key = lm2.message_key and
           lm1.package_key = lm2.package_key
    )
}

# Query that get all the messages that HAVE a translation to
# the language selected

set grouper_msg_translated {
    select distinct lm1.package_key
    from   lang_messages lm1,
           lang_messages lm2
    where  lm1.locale = :default_locale and
           lm2.locale = :current_locale and
           lm1.message_key = lm2.message_key and
           lm1.package_key = lm2.package_key
}

template::multirow create all_packages_group package_key package_key_encoded locale_encoded
template::multirow create missing_translation_group package_key package_key_encoded locale_encoded
template::multirow create translated_messages_group package_key package_key_encoded locale_encoded

db_foreach select_messages_not_translated $grouper_msg_not_translated {
    template::multirow append missing_translation_group $package_key [ns_urlencode $package_key] [ns_urlencode $current_locale]
}

db_foreach select_messages_translated $grouper_msg_translated {
    template::multirow append translated_messages_group $package_key [ns_urlencode $package_key] [ns_urlencode $current_locale]
}

db_foreach select_messages_all_packages $grouper_msg_all {
    template::multirow append all_packages_group $package_key [ns_urlencode $package_key] [ns_urlencode $current_locale]
}

db_1row select_locale_lable {
    select label as locale_label from ad_locales where locale = :current_locale }

if { $current_locale == $default_locale } {
    # This is the default locale, then allow the 'new' action
    set new_allowed_p 1
} else {
    set new_allowed_p 0
}

set message_search_url "message-search?[export_vars { locale }]"

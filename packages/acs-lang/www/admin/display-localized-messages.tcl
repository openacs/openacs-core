ad_page_contract {

    Displays the localized messages from the database for translation

    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
    @creation-date 26 October 2001
    @cvs-id $Id$
} {
    locales
    translated_p
} -properties {
}

set tab [ns_urlencode "localized-messages"]
set return_url "display-grouped-messages?tab=$tab&locales=$locales"
set context_bar [ad_context_bar [list "index?tab=$tab" "Locales & Messages"] [list $return_url Listing] "Messages"]
set default_locale [ad_parameter DefaultLocale]
set default_locale en_US

# Christian: this should be in ad_page_contract - right?

request create -params {
    locales -datatype text 
    grouper_key -datatype text 
}

if { [exists_and_not_null locales] } {
    set locale_user $locales
} else {
    set locale_user [ad_locale_locale_from_lang [ad_locale user language]]
}
#  AS - disabling, doesn't work
#  set encoding_charset [ad_locale charset $locale_user]
#  ns_setformencoding $encoding_charset
#  ns_set put [ns_conn outputheaders] "content-type" "text/html; charset=$encoding_charset"

set escaped_locale [ns_urlencode $locale_user]

# Query to get all the messages that DO NOT have a translation to the
# language selected
set cat_msg_not_translated "
select 
  key, 
  message 
from 
  lang_messages lm1 
where 
  lm1.locale = :default_locale and
  substr(lm1.key, 1, instr(lm1.key, '.') - 1) = :grouper_key and
  not exists (
    select 1 
    from lang_messages lm2 
    where lm2.locale = :locale_user and 
    lm1.key = lm2.key
  )"

# Query that get all the messages that HAVE a translation to
# the language selected
# 
set cat_msg_translated "
select
  lm1.key as key,
  lm1.message as default_message,
  lm2.message as translated_message
from
  lang_messages lm1,
  lang_messages lm2
where
  lm1.locale = :default_locale and
  substr(lm1.key, 1, instr(lm1.key, '.') - 1) = :grouper_key and
  lm2.locale = :locale_user and
  lm1.key = lm2.key"

template::multirow create missing_translation key locale message escaped_key escaped_language

template::multirow create translated_messages key locale default_message translated_message escaped_key escaped_language

if { ! $translated_p } {
    db_foreach select_messages_not_translated $cat_msg_not_translated {
        template::multirow append missing_translation $key $locale_user $message [ns_urlencode $key] [ns_urlencode $locale_user]
    }
} else {
    db_foreach select_messages_translated $cat_msg_translated {
        template::multirow append translated_messages $key $locale_user $default_message $translated_message [ns_urlencode $key] [ns_urlencode $locale_user]
    }
}

db_1row select_locale_lable {
    select label as locale_label from ad_locales where locale = :locale_user }

db_release_unused_handles

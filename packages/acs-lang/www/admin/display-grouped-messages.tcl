# /packages/gp-lang/www/gpadmin/display-grouped-messages.tcl
ad_page_contract {

    Displays the categories of messages (grouped by the key string that
    goes before the first "." in it).

    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
    @creation-date 26 October 2001
    @cvs-id $Id$
} {
    locales:optional
} -properties {
}

set return_url "index?tab=[ns_urlencode localized-messages]"
set context_bar [ad_context_bar [list $return_url "Locales & Messages"] "Listing"]
set default_locale [ad_parameter DefaultLocale]
set default_locale en_US

# We look for all the languages of the current NRO

request create -params {
    locale -datatype text -optional 
}

if { [info exists locales] } {
    set locale_user $locales
} else {
    if { [exists_and_not_null locale] } {
        set locale_user $locales
     } else {
         set locale_user [ad_locale_locale_from_lang [ad_locale user language]]
     }
}
#  AS - disabling this because it doesn't work
#  set encoding_charset [ad_locale charset $locale_user]
#  ns_setformencoding $encoding_charset
#  ns_set put [ns_conn outputheaders] "content-type" "text/html; charset=$encoding_charset"

# We query the database for all the messages for the specific locale
# translated or not but selecting only the first element in the key
# using the distinct in each reduces the number of rows that we have
# to process from within TCL. As you might already know from the docs,
# the format of the key is 'grouper.key' where grouper is some string
# that can identify a package or a specific set of templates; grouper
# cannot contain dots.

# Query to get all the messages that DO NOT have a translation to the
# language selected

set grouper_msg_not_translated "
select 
  distinct(substr(key, 1, instr(key, '.')-1)) as grouper_key
from 
  lang_messages lm1 
where 
  lm1.locale = :default_locale and 
  not exists (
    select 1 
    from lang_messages lm2 
    where lm2.locale = :locale_user and 
    lm1.key = lm2.key
  )"

# Query that get all the messages that HAVE a translation to
# the language selected
set grouper_msg_translated "
select
  distinct(substr(lm1.key, 1, instr(lm1.key, '.')-1)) as grouper_key
from
  lang_messages lm1,
  lang_messages lm2
where
  lm1.locale = :default_locale and
  lm2.locale = :locale_user and
  lm1.key = lm2.key"

template::multirow create missing_translation_group grouper_key grouper_key_encoded locale_encoded
template::multirow create translated_messages_group grouper_key grouper_key_encoded locale_encoded

db_foreach select_messages_not_translated $grouper_msg_not_translated {
    template::multirow append missing_translation_group $grouper_key [ns_urlencode $grouper_key] [ns_urlencode $locale_user]
}

db_foreach select_messages_translated $grouper_msg_translated {
    template::multirow append translated_messages_group $grouper_key [ns_urlencode $grouper_key] [ns_urlencode $locale_user]
}

db_1row select_locale_lable {
    select label as locale_label from ad_locales where locale = :locale_user }

if { $locale_user == $default_locale } {

    # This is the default locale, then allow the 'new' action
    set new_allowed_p 1

} else {

    set new_allowed_p 0

}

db_release_unused_handles

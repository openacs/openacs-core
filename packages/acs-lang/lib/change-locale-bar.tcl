# Optional parameters
# TODO:
# 1) specify exactly which locales
# 2) sort by descending popularity

set current_locale [lang::conn::locale]
set base_lang_url [site_node::get_package_url -package_key acs-lang]

if { ![exists_and_not_null return_url]} {
    # Use referer header
    set return_url [ad_return_url]
}

if { ![exists_and_not_null max_locales]} {
    set max_locales 8
}

if { ![exists_and_not_null avail_key] } {
    set avail_key "this-language"
}

# get a list of valid locales
set enabled_locale_count [db_string enabled_locale_count "
    select count(*)
      from enabled_locales el
" -default 0]

# get a list of valid locales
db_multirow -extend {l10n_label switch_url} locale_list get_locale_list "
    select el.label,
           el.locale,
           (select count(*) 
              from user_preferences
             where locale = el.locale) as user_count
      from enabled_locales el
     where (select count(*) 
              from lang_messages
             where message_key = :avail_key
               and locale = el.locale) > 0
     order by user_count desc
     limit $max_locales
" {
    set l10n_label [lang::message::lookup $locale acs-lang.${avail_key} "" "" 0]
    set switch_url [export_vars -base ${base_lang_url}change-locale {{return_p "t"} {user_locale $locale} return_url}]
}

set switchable_count [template::multirow size locale_list]
 
# display as many choices as possible, limited by availability of the localized message keys
# and parameterized limit
# If there are more locales in the system than displayable, extend the list with "Change Locale"
# in the browser's requested locale.  If that is not available, fall back to "...", NOT to the
# system default for "Change Locale".  The reason is that, after a list of language names, "..." should
# be more recognizable than a foreign word

if {$enabled_locale_count > $switchable_count && $switchable_count > 1} {
    set change_locale_url [export_vars -base $base_lang_url {return_url}]
    set browser_locale [lang::conn::browser_locale]
    set exists_p [lang::message::message_exists_p $browser_locale acs-lang.change-locale]
    if { [exists_and_not_null browser_locale] && $exists_p } {
        set change_locale_text "[lang::message::lookup $browser_locale  acs-lang.change-locale]"
    } else {
        set change_locale_text "..."
    }
    set change_locale_text 
} else {
    set change_locale_url ""
    set change_locale_text ""
}

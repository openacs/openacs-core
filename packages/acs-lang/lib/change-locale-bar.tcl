# optional inputs:
# return_url
# max_locales
# avail_key

set current_locale [lang::conn::locale]
set base_lang_url [site_node::get_package_url -package_key acs-lang]

if { ![info exists return_url] || $return_url eq "" } {
    # Use referer header
    set return_url [ad_return_url]
}

if { ![info exists max_locales] || $max_locales eq "" } {
    set max_locales 8
}

if { ![info exists avail_key] || $avail_key eq "" } {
    set avail_key "this-language"
}

# get a count of enabled locales
set enabled_locale_count [db_string enabled_locale_count "
    select count(*)
      from enabled_locales el
" -default 0]

# get a list of valid locales for switching
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
set change_locale_url ""

#######################################################################
# The text to change locales, in decreasing order of desirability
#   1) "Change Locale" in the browser's requested locale.
#   2) If there is a list of locales, "..."
#      (NOT to the system default for "Change Locale".  The reason is that, after a list of
#       language names, "..." should be more recognizable than a foreign word)
#   3) Fall back on the standard defaults for Change Locale

set browser_locale [lang::conn::browser_locale]
set localized_change_exists_p [lang::message::message_exists_p $browser_locale acs-lang.change-locale]
if { $localized_change_exists_p } {
    set change_locale_text "[lang::message::lookup $browser_locale acs-lang.change-locale]"
} else {
    set change_locale_text "[_ acs-lang.change-locale]"
}

if {$enabled_locale_count > 1 && $enabled_locale_count > $switchable_count} {
    set change_locale_url [export_vars -base ${base_lang_url} {return_url}]
}


if {$localized_change_exists_p && $switchable_count > 1 &&  $enabled_locale_count > $switchable_count} {
    set change_locale_text "..."
}



#######################################################################
# administrators' link
set acs_lang_id [apm_package_id_from_key acs-lang]
set lang_admin_p [permission::permission_p -privilege admin -object_id $acs_lang_id]
set lang_admin_url [export_vars -base ${base_lang_url}admin {return_url}]

if { $enabled_locale_count > 1 } {
    set lang_admin_text "Administer Locales"
} else {
    set lang_admin_text "Add Locales"
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

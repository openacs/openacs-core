ad_page_contract {
    Localization home
}

set instance_name [ad_conn instance_name]
set context_bar [ad_context_bar]

#
# Get user pref setting
#

set locale [ad_locale user locale]
set language [ad_locale user language]
